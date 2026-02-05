/*
 * NVDA-Arma 3 Bridge DLL
 *
 * This DLL bridges Arma 3's callExtension system to NVDA screen reader
 * and provides real-time two-tone audio feedback for precision aiming assistance.
 *
 * Two-Tone Precision System:
 *   - Primary tone: Stereo-panned sine wave (300-800 Hz) for coarse aiming
 *     Pulses based on vertical error (slow=far, fast=close, steady=centered)
 *   - Secondary tone: Triangle wave (500-560 Hz) with 4100 Hz LPF for fine horizontal
 *     Activates when roughly facing target, frequency sweeps from 500 Hz (edge) to 560 Hz (center)
 *   - Both tones steady = dead center = FIRE!
 *
 * Build with Visual Studio 2022 Developer Command Prompt:
 *   cl /LD /EHsc /O2 /Fe:nvda_arma3_bridge_x64.dll nvda_arma3_bridge.cpp nvdaControllerClient.lib
 *
 * Usage in Arma 3 SQF:
 *   "nvda_arma3_bridge" callExtension "speak:Hello world"
 *   "nvda_arma3_bridge" callExtension "cancel"
 *   "nvda_arma3_bridge" callExtension "braille:Message"
 *   "nvda_arma3_bridge" callExtension "test"
 *   "nvda_arma3_bridge" callExtension "aim_start"
 *   "nvda_arma3_bridge" callExtension "aim_update:-0.5,600,0.2,0.5"  // pan,pitch,vertErr,horizErr
 *   "nvda_arma3_bridge" callExtension "aim_stop"
 */

#define UNICODE
#define _UNICODE

// Define miniaudio implementation in this file
#define MINIAUDIO_IMPLEMENTATION
#define MA_NO_DECODING
#define MA_NO_ENCODING
#define MA_NO_GENERATION
#define MA_NO_RESOURCE_MANAGER
#define MA_NO_NODE_GRAPH
#define MA_NO_ENGINE

#include <windows.h>
#include <string>
#include <cstring>
#include <cmath>
#include <atomic>

// NVDA Controller Client header
#include "nvdaController.h"

// miniaudio for real-time audio synthesis
#include "miniaudio.h"

// Arma 3 extension entry points
extern "C" {
    __declspec(dllexport) void __stdcall RVExtensionVersion(char *output, int outputSize);
    __declspec(dllexport) void __stdcall RVExtension(char *output, int outputSize, const char *function);
    __declspec(dllexport) int __stdcall RVExtensionArgs(char *output, int outputSize, const char *function, const char **args, int argsCnt);
}

// DLL version string
static const char* VERSION = "1.5.0";

// ============================================================================
// Audio Synthesis State (for aim assist)
// ============================================================================

// Audio parameters (atomic for thread-safe access from audio callback)
static std::atomic<float> g_aimPan(0.0f);           // -1.0 (left) to +1.0 (right)
static std::atomic<float> g_aimPitch(550.0f);       // Frequency in Hz (300-800)
static std::atomic<float> g_aimVertError(1.0f);     // Vertical error 0-1 (0 = centered)
static std::atomic<float> g_aimHorizError(1.0f);    // Horizontal error 0-1 (0 = centered)
static std::atomic<float> g_aimVertThreshold(0.02f);  // Adaptive vertical threshold
static std::atomic<float> g_aimHorizThreshold(0.005f); // Adaptive horizontal threshold
static std::atomic<bool> g_aimActive(false);        // Whether aim assist is active
static std::atomic<bool> g_aimMuted(false);         // Mute when no target

// Vertical lock blip state
static std::atomic<bool> g_aimBlipPending(false);   // Flag to trigger blip
static double g_blipPhase = 0.0;                    // Blip oscillator phase
static float g_blipEnvelope = 0.0f;                 // Blip envelope level
static int g_blipEnvState = 0;                      // 0=idle, 1=attack, 2=sustain, 3=release
static int g_blipSustainSamples = 0;                // Remaining sustain samples

// Vertical unlock blip state
static std::atomic<bool> g_aimUnlockBlipPending(false);
static double g_unlockBlipPhase = 0.0;
static float g_unlockBlipEnvelope = 0.0f;
static int g_unlockBlipEnvState = 0;
static int g_unlockBlipSustainSamples = 0;

// ============================================================================
// Terrain Radar Audio State
// ============================================================================

// Radar active flag
static std::atomic<bool> g_radarActive(false);

// Ring buffer for pending beeps (producer: command handler, consumer: audio callback)
struct RadarBeep {
    float pan;
    float volume;
    int material;
};
static const int RADAR_QUEUE_SIZE = 64;  // Power of 2 for efficient modulo
static RadarBeep g_radarQueue[RADAR_QUEUE_SIZE];
static std::atomic<int> g_radarQueueHead(0);  // Next write position (command handler)
static std::atomic<int> g_radarQueueTail(0);  // Next read position (audio callback)

// Currently playing beep parameters (consumed from queue)
static float g_radarPlayingPan = 0.0f;
static float g_radarPlayingVol = 0.5f;
static int g_radarPlayingMat = 0;

// Radar beep state (non-atomic, only accessed in audio callback)
static double g_radarPhase = 0.0;           // Beep oscillator phase
static float g_radarEnvelope = 0.0f;        // Current envelope level
static int g_radarEnvState = 0;             // 0=idle, 1=attack, 2=sustain, 3=release
static int g_radarSustainSamples = 0;       // Samples remaining in sustain

// Radar material frequencies (Hz)
static const float RADAR_FREQ_GRASS = 200.0f;
static const float RADAR_FREQ_CONCRETE = 400.0f;
static const float RADAR_FREQ_WOOD = 300.0f;
static const float RADAR_FREQ_METAL = 600.0f;
static const float RADAR_FREQ_WATER = 150.0f;
static const float RADAR_FREQ_MAN = 800.0f;
static const float RADAR_FREQ_GLASS = 700.0f;
static const float RADAR_FREQ_DEFAULT = 350.0f;

// Radar envelope timing (in samples at 44100 Hz)
static const int RADAR_ATTACK_SAMPLES = 88;    // 2ms attack
static const int RADAR_SUSTAIN_SAMPLES = 882;  // 20ms sustain
static const int RADAR_RELEASE_SAMPLES = 132;  // 3ms release

// Radar volume
static const float RADAR_BASE_VOLUME = 0.015f;  // Base volume for radar beeps

// ============================================================================
// Navigation Beacon Audio State
// ============================================================================

// Beacon active flag and pan parameter
static std::atomic<bool> g_beaconActive(false);
static std::atomic<float> g_beaconPan(0.0f);     // -1.0 (left) to +1.0 (right)

// Beacon oscillator state (non-atomic, only accessed in audio callback)
static double g_beaconPhase = 0.0;               // Oscillator phase
static double g_beaconPulsePhase = 0.0;          // Pulse envelope phase
static float g_beaconLpfState = 0.0f;            // Low pass filter state
static float g_beaconEnvelopeState = 0.0f;       // Smooth envelope level (0-1)

// Beacon audio constants
static const float BEACON_FREQ_MIN = 400.0f;      // Frequency when off center
static const float BEACON_FREQ_MAX = 460.0f;      // Frequency when centered
static const float BEACON_VOLUME = 0.012f;        // 2x louder beacon
static const float BEACON_LPF_CUTOFF = 4000.0f;   // Low pass filter cutoff Hz
static const float BEACON_MIN_PULSE_RATE = 2.0f;  // Hz when far off center
static const float BEACON_MAX_PULSE_RATE = 15.0f; // Hz when near center
static const float BEACON_CENTER_THRESHOLD = 0.05f; // abs(pan) below this = steady tone
static const float BEACON_ATTACK_MS = 5.0f;       // Envelope attack (hearing safety)
static const float BEACON_RELEASE_MS = 5.0f;      // Envelope release (hearing safety)

// Audio device state
static ma_device g_audioDevice;
static bool g_audioInitialized = false;
static double g_phase = 0.0;           // Primary tone phase
static double g_pulsePhase = 0.0;      // Primary tone pulse envelope phase
static double g_clickPhase = 0.0;      // Secondary click tone phase
static double g_clickPulsePhase = 0.0; // Secondary click pulse envelope phase
static float g_clickLpfState = 0.0f;   // Low pass filter state for click tone
static float g_clickEnvelopeState = 0.0f;  // Current envelope level (0-1) for smooth attack/release
static float g_primaryEnvelopeState = 0.0f;  // Current envelope level for primary tone

// Audio constants
static const int SAMPLE_RATE = 44100;
static const float BASE_VOLUME = 0.01f;  // Quiet but audible

// Shutdown flag for clean exit
static std::atomic<bool> g_shuttingDown(false);

// Constants for two-tone audio
static const float CLICK_FREQ_MIN = 500.0f;     // Frequency at activation threshold
static const float CLICK_FREQ_MAX = 560.0f;     // Frequency at center (pan = 0)
static const float CLICK_VOLUME = 0.008f;       // Secondary tone volume (slightly quieter)
static const float CLICK_LPF_CUTOFF = 4100.0f;  // Low pass filter cutoff frequency
static const float CLICK_ATTACK_MS = 5.0f;      // Attack time in milliseconds
static const float CLICK_RELEASE_MS = 5.0f;     // Release time in milliseconds
static const float PRIMARY_ATTACK_MS = 5.0f;    // Attack time for primary tone
static const float PRIMARY_RELEASE_MS = 5.0f;   // Release time for primary tone
static const float MIN_PULSE_RATE = 2.0f;       // Slowest pulse rate (Hz) at max error
static const float MAX_PULSE_RATE = 15.0f;      // Fastest pulse rate (Hz) at min error
static const float HORIZ_ACTIVATE_THRESHOLD = 0.2f; // Secondary tone activates when abs(pan) < this (close to target)
static const float VERT_ACTIVATE_THRESHOLD = 0.4f;  // vertError above this = slow clicks (edge of useful range)
static const double PI = 3.14159265358979323846;
// Note: VERT_CENTER_THRESHOLD and HORIZ_CENTER_THRESHOLD are now adaptive (passed from SQF)

// Vertical lock blip constants
static const float BLIP_FREQ = 800.0f;              // 800 Hz for lock
static const float UNLOCK_BLIP_FREQ = 500.0f;       // 500 Hz for unlock
static const int BLIP_ATTACK_SAMPLES = 44;          // ~1ms attack
static const int BLIP_SUSTAIN_SAMPLES = 882;        // 20ms sustain
static const int BLIP_RELEASE_SAMPLES = 88;         // ~2ms release
static const float BLIP_VOLUME = 0.30f;             // Loud blip (4x increase for gunfight audibility)

// Audio callback - generates two-tone precision feedback in real-time
void audio_callback(ma_device* pDevice, void* pOutput, const void* pInput, ma_uint32 frameCount) {
    (void)pInput;
    (void)pDevice;

    float* output = (float*)pOutput;

    // FAST EXIT if shutting down - zero output and return immediately
    if (g_shuttingDown.load()) {
        memset(output, 0, frameCount * 2 * sizeof(float));
        return;
    }

    // Read current parameters atomically
    float pan = g_aimPan.load();
    float freq = g_aimPitch.load();
    float vertError = g_aimVertError.load();
    float horizError = g_aimHorizError.load();
    float vertThreshold = g_aimVertThreshold.load();    // Adaptive threshold from SQF
    float horizThreshold = g_aimHorizThreshold.load();  // Adaptive threshold from SQF
    bool active = g_aimActive.load();
    bool muted = g_aimMuted.load();

    // Calculate per-channel gains for primary tone stereo panning
    // Pan: -1 = full left, 0 = center, +1 = full right
    float leftGain = (pan <= 0.0f) ? 1.0f : (1.0f - pan);
    float rightGain = (pan >= 0.0f) ? 1.0f : (1.0f + pan);

    // Calculate primary tone pulse rate based on vertical error
    // At dead center (vertError < threshold): continuous tone (pulseRate = 0)
    // Near target: fast clicks, far from target: slow clicks
    // Full dynamic range spread across useful aiming area [vertThreshold, VERT_ACTIVATE_THRESHOLD]
    float primaryPulseRate = 0.0f;
    if (vertError >= vertThreshold) {
        // Map vertError from [vertThreshold, VERT_ACTIVATE_THRESHOLD] to [MAX_PULSE_RATE, MIN_PULSE_RATE]
        // Near target = fast clicks, far = slow clicks
        float t = (vertError - vertThreshold) / (VERT_ACTIVATE_THRESHOLD - vertThreshold);
        t = (t < 0.0f) ? 0.0f : (t > 1.0f) ? 1.0f : t;  // Clamp to [0,1]
        primaryPulseRate = MAX_PULSE_RATE + t * (MIN_PULSE_RATE - MAX_PULSE_RATE);
    }
    // When vertError < vertThreshold (on target), pulseRate stays 0 = continuous smooth tone

    // Calculate secondary click pulse rate based on pan magnitude (distance from center)
    // Only active when roughly facing target (abs(pan) < 0.2)
    // Clicks speed up as you approach target, then go smooth when on target
    float panMagnitude = fabsf(pan);
    bool secondaryActive = (panMagnitude < HORIZ_ACTIVATE_THRESHOLD);
    float secondaryPulseRate = 0.0f;
    if (secondaryActive && panMagnitude >= horizThreshold) {
        // Map pan from [horizThreshold, HORIZ_ACTIVATE_THRESHOLD] to [MAX_PULSE_RATE, MIN_PULSE_RATE]
        // Near target = fast clicks, near edge of activation = slow clicks
        float t = (panMagnitude - horizThreshold) / (HORIZ_ACTIVATE_THRESHOLD - horizThreshold);
        t = (t < 0.0f) ? 0.0f : (t > 1.0f) ? 1.0f : t;  // Clamp to [0,1]
        secondaryPulseRate = MAX_PULSE_RATE + t * (MIN_PULSE_RATE - MAX_PULSE_RATE);
    }
    // When panMagnitude < horizThreshold (on target), pulseRate stays 0 = continuous smooth tone

    // Calculate click frequency: sweep from 500 Hz (at threshold) to 560 Hz (at center)
    // Uses HORIZ_ACTIVATE_THRESHOLD so it auto-scales if threshold changes
    float clickFreq = CLICK_FREQ_MAX;  // Default to center frequency
    if (secondaryActive) {
        // Map pan from [0, threshold] to frequency [560, 500]
        float t = panMagnitude / HORIZ_ACTIVATE_THRESHOLD;  // 0 at center, 1 at threshold
        clickFreq = CLICK_FREQ_MAX + t * (CLICK_FREQ_MIN - CLICK_FREQ_MAX);
    }

    // Low pass filter coefficient for click tone (one-pole filter)
    static const float clickLpfAlpha = 1.0f - expf(-2.0f * (float)PI * CLICK_LPF_CUTOFF / SAMPLE_RATE);

    // Attack/release coefficients for smooth envelope transitions
    static const float samplesPerMs = SAMPLE_RATE / 1000.0f;
    static const float clickAttackCoef = 1.0f / (CLICK_ATTACK_MS * samplesPerMs);
    static const float clickReleaseCoef = 1.0f / (CLICK_RELEASE_MS * samplesPerMs);
    static const float primaryAttackCoef = 1.0f / (PRIMARY_ATTACK_MS * samplesPerMs);
    static const float primaryReleaseCoef = 1.0f / (PRIMARY_RELEASE_MS * samplesPerMs);

    // Phase increments per sample
    double primaryPhaseInc = (2.0 * PI * freq) / SAMPLE_RATE;
    double primaryPulseInc = (2.0 * PI * primaryPulseRate) / SAMPLE_RATE;
    double clickPhaseInc = (2.0 * PI * clickFreq) / SAMPLE_RATE;
    double clickPulseInc = (2.0 * PI * secondaryPulseRate) / SAMPLE_RATE;

    for (ma_uint32 i = 0; i < frameCount; i++) {
        float leftSample = 0.0f;
        float rightSample = 0.0f;

        if (active && !muted) {
            // ================================================================
            // Primary tone (vertical precision) - panned stereo sine wave
            // ================================================================
            float primarySample = (float)sin(g_phase) * BASE_VOLUME;

            // Apply pulse envelope with smooth attack/release ramps
            float targetPrimaryEnvelope = 1.0f;  // Default: full on (continuous tone)
            if (primaryPulseRate > 0.0f) {
                targetPrimaryEnvelope = (sin(g_pulsePhase) > 0.0f) ? 1.0f : 0.0f;
            }

            // Smooth envelope transition
            if (g_primaryEnvelopeState < targetPrimaryEnvelope) {
                g_primaryEnvelopeState += primaryAttackCoef;
                if (g_primaryEnvelopeState > targetPrimaryEnvelope) g_primaryEnvelopeState = targetPrimaryEnvelope;
            } else if (g_primaryEnvelopeState > targetPrimaryEnvelope) {
                g_primaryEnvelopeState -= primaryReleaseCoef;
                if (g_primaryEnvelopeState < targetPrimaryEnvelope) g_primaryEnvelopeState = targetPrimaryEnvelope;
            }

            primarySample *= g_primaryEnvelopeState;

            // Apply stereo panning to primary tone
            leftSample += primarySample * leftGain;
            rightSample += primarySample * rightGain;

            // ================================================================
            // Secondary tone (horizontal precision) - mono click in L or R ear
            // Triangle wave with low pass filter, frequency sweeps 500-560 Hz
            // ================================================================
            if (secondaryActive) {
                // Triangle wave: map phase [0, 2*PI] to triangle [-1, +1]
                float normalizedPhase = (float)(g_clickPhase / (2.0 * PI));  // 0 to 1
                float triangleValue = 4.0f * fabsf(normalizedPhase - 0.5f) - 1.0f;  // Triangle wave
                float clickSample = triangleValue * CLICK_VOLUME;

                // Apply one-pole low pass filter (4100 Hz cutoff)
                g_clickLpfState += clickLpfAlpha * (clickSample - g_clickLpfState);
                clickSample = g_clickLpfState;

                // Apply pulse envelope with smooth attack/release ramps
                float targetEnvelope = 1.0f;  // Default: full on (continuous tone)
                if (secondaryPulseRate > 0.0f) {
                    // Pulsing mode: target is 1 when sin > 0, else 0
                    targetEnvelope = (sin(g_clickPulsePhase) > 0.0f) ? 1.0f : 0.0f;
                }

                // Smooth envelope transition using attack/release
                if (g_clickEnvelopeState < targetEnvelope) {
                    g_clickEnvelopeState += clickAttackCoef;
                    if (g_clickEnvelopeState > targetEnvelope) g_clickEnvelopeState = targetEnvelope;
                } else if (g_clickEnvelopeState > targetEnvelope) {
                    g_clickEnvelopeState -= clickReleaseCoef;
                    if (g_clickEnvelopeState < targetEnvelope) g_clickEnvelopeState = targetEnvelope;
                }

                clickSample *= g_clickEnvelopeState;

                // Pan click based on target direction, or center when on target
                if (panMagnitude < horizThreshold) {
                    // On target - play in both ears (centered)
                    leftSample += clickSample;
                    rightSample += clickSample;
                } else if (pan < 0.0f) {
                    // Target is to the left - click in left ear
                    leftSample += clickSample;
                } else {
                    // Target is to the right - click in right ear
                    rightSample += clickSample;
                }
            }
        }

        // ================================================================
        // Vertical lock blip (one-shot notification)
        // ================================================================
        if (active) {
            // Check for pending blip and start envelope if idle
            if (g_aimBlipPending.load() && g_blipEnvState == 0) {
                g_blipEnvState = 1;
                g_blipEnvelope = 0.0f;
                g_blipPhase = 0.0;
                g_blipSustainSamples = BLIP_SUSTAIN_SAMPLES;
                g_aimBlipPending.store(false);
            }

            if (g_blipEnvState > 0) {
                // Generate sine wave at 800 Hz
                float blipSample = (float)sin(g_blipPhase) * BLIP_VOLUME;

                // Advance phase
                double blipPhaseInc = (2.0 * PI * BLIP_FREQ) / SAMPLE_RATE;
                g_blipPhase += blipPhaseInc;
                if (g_blipPhase >= 2.0 * PI) g_blipPhase -= 2.0 * PI;

                // Update envelope state machine
                switch (g_blipEnvState) {
                    case 1:  // Attack
                        g_blipEnvelope += 1.0f / BLIP_ATTACK_SAMPLES;
                        if (g_blipEnvelope >= 1.0f) {
                            g_blipEnvelope = 1.0f;
                            g_blipEnvState = 2;
                        }
                        break;
                    case 2:  // Sustain
                        g_blipSustainSamples--;
                        if (g_blipSustainSamples <= 0) {
                            g_blipEnvState = 3;
                        }
                        break;
                    case 3:  // Release
                        g_blipEnvelope -= 1.0f / BLIP_RELEASE_SAMPLES;
                        if (g_blipEnvelope <= 0.0f) {
                            g_blipEnvelope = 0.0f;
                            g_blipEnvState = 0;  // Done
                        }
                        break;
                }

                // Apply envelope and add to both channels (mono)
                blipSample *= g_blipEnvelope;
                leftSample += blipSample;
                rightSample += blipSample;
            }

            // ================================================================
            // Vertical unlock blip (one-shot notification at 500 Hz)
            // ================================================================
            if (g_aimUnlockBlipPending.load() && g_unlockBlipEnvState == 0) {
                g_unlockBlipEnvState = 1;
                g_unlockBlipEnvelope = 0.0f;
                g_unlockBlipPhase = 0.0;
                g_unlockBlipSustainSamples = BLIP_SUSTAIN_SAMPLES;
                g_aimUnlockBlipPending.store(false);
            }

            if (g_unlockBlipEnvState > 0) {
                // Generate sine wave at 500 Hz
                float unlockBlipSample = (float)sin(g_unlockBlipPhase) * BLIP_VOLUME;

                // Advance phase
                double unlockBlipPhaseInc = (2.0 * PI * UNLOCK_BLIP_FREQ) / SAMPLE_RATE;
                g_unlockBlipPhase += unlockBlipPhaseInc;
                if (g_unlockBlipPhase >= 2.0 * PI) g_unlockBlipPhase -= 2.0 * PI;

                // Update envelope state machine
                switch (g_unlockBlipEnvState) {
                    case 1:  // Attack
                        g_unlockBlipEnvelope += 1.0f / BLIP_ATTACK_SAMPLES;
                        if (g_unlockBlipEnvelope >= 1.0f) {
                            g_unlockBlipEnvelope = 1.0f;
                            g_unlockBlipEnvState = 2;
                        }
                        break;
                    case 2:  // Sustain
                        g_unlockBlipSustainSamples--;
                        if (g_unlockBlipSustainSamples <= 0) {
                            g_unlockBlipEnvState = 3;
                        }
                        break;
                    case 3:  // Release
                        g_unlockBlipEnvelope -= 1.0f / BLIP_RELEASE_SAMPLES;
                        if (g_unlockBlipEnvelope <= 0.0f) {
                            g_unlockBlipEnvelope = 0.0f;
                            g_unlockBlipEnvState = 0;  // Done
                        }
                        break;
                }

                // Apply envelope and add to both channels (mono)
                unlockBlipSample *= g_unlockBlipEnvelope;
                leftSample += unlockBlipSample;
                rightSample += unlockBlipSample;
            }
        }

        // ================================================================
        // Terrain Radar audio (mutually exclusive with aim assist)
        // ================================================================
        if (g_radarActive.load() && !active) {
            // Check for pending beeps in queue (only when idle)
            if (g_radarEnvState == 0) {
                int tail = g_radarQueueTail.load(std::memory_order_relaxed);
                int head = g_radarQueueHead.load(std::memory_order_acquire);

                if (tail != head) {
                    // Consume beep from queue
                    g_radarPlayingPan = g_radarQueue[tail].pan;
                    g_radarPlayingVol = g_radarQueue[tail].volume;
                    g_radarPlayingMat = g_radarQueue[tail].material;

                    // Advance tail
                    g_radarQueueTail.store((tail + 1) % RADAR_QUEUE_SIZE, std::memory_order_release);

                    // Start envelope
                    g_radarEnvState = 1;  // Start attack phase
                    g_radarEnvelope = 0.0f;
                    g_radarPhase = 0.0;
                    g_radarSustainSamples = RADAR_SUSTAIN_SAMPLES;
                }
            }

            // Process envelope state machine
            if (g_radarEnvState > 0) {
                // Use playing parameters (consumed from queue at beep start)
                float radarPan = g_radarPlayingPan;
                float radarVol = g_radarPlayingVol;
                int radarMat = g_radarPlayingMat;

                // Select frequency based on material
                float radarFreq;
                switch (radarMat) {
                    case 1: radarFreq = RADAR_FREQ_GRASS; break;
                    case 2: radarFreq = RADAR_FREQ_CONCRETE; break;
                    case 3: radarFreq = RADAR_FREQ_WOOD; break;
                    case 4: radarFreq = RADAR_FREQ_METAL; break;
                    case 5: radarFreq = RADAR_FREQ_WATER; break;
                    case 6: radarFreq = RADAR_FREQ_MAN; break;
                    case 7: radarFreq = RADAR_FREQ_GLASS; break;
                    default: radarFreq = RADAR_FREQ_DEFAULT; break;
                }

                // Generate waveform based on material
                float radarSample = 0.0f;
                double radarPhaseInc = (2.0 * PI * radarFreq) / SAMPLE_RATE;

                switch (radarMat) {
                    case 1:  // grass - sine (soft)
                        radarSample = (float)sin(g_radarPhase);
                        break;
                    case 2:  // concrete - square (harsh)
                        radarSample = (sin(g_radarPhase) > 0.0) ? 1.0f : -1.0f;
                        break;
                    case 3:  // wood - triangle (organic)
                        {
                            float normPhase = (float)(g_radarPhase / (2.0 * PI));
                            radarSample = 4.0f * fabsf(normPhase - 0.5f) - 1.0f;
                        }
                        break;
                    case 4:  // metal - sawtooth (buzzy)
                        radarSample = (float)(2.0 * (g_radarPhase / (2.0 * PI)) - 1.0);
                        break;
                    case 5:  // water - filtered noise approximation (low sine with harmonics)
                        radarSample = (float)(sin(g_radarPhase) * 0.7 + sin(g_radarPhase * 2.3) * 0.3);
                        break;
                    case 6:  // man - pulse (25% duty cycle, distinct alert)
                        radarSample = (g_radarPhase < PI * 0.5) ? 1.0f : -0.3f;
                        break;
                    case 7:  // glass - sine + harmonic (bright)
                        radarSample = (float)(sin(g_radarPhase) * 0.8 + sin(g_radarPhase * 2.0) * 0.2);
                        break;
                    default:  // default - sine
                        radarSample = (float)sin(g_radarPhase);
                        break;
                }

                // Update envelope
                switch (g_radarEnvState) {
                    case 1:  // Attack
                        g_radarEnvelope += 1.0f / RADAR_ATTACK_SAMPLES;
                        if (g_radarEnvelope >= 1.0f) {
                            g_radarEnvelope = 1.0f;
                            g_radarEnvState = 2;  // Move to sustain
                        }
                        break;
                    case 2:  // Sustain
                        g_radarSustainSamples--;
                        if (g_radarSustainSamples <= 0) {
                            g_radarEnvState = 3;  // Move to release
                        }
                        break;
                    case 3:  // Release
                        g_radarEnvelope -= 1.0f / RADAR_RELEASE_SAMPLES;
                        if (g_radarEnvelope <= 0.0f) {
                            g_radarEnvelope = 0.0f;
                            g_radarEnvState = 0;  // Done
                        }
                        break;
                }

                // Apply volume and envelope
                radarSample *= g_radarEnvelope * radarVol * RADAR_BASE_VOLUME;

                // Apply stereo panning
                float radarLeftGain = (radarPan <= 0.0f) ? 1.0f : (1.0f - radarPan);
                float radarRightGain = (radarPan >= 0.0f) ? 1.0f : (1.0f + radarPan);

                leftSample += radarSample * radarLeftGain;
                rightSample += radarSample * radarRightGain;

                // Advance radar phase
                g_radarPhase += radarPhaseInc;
                if (g_radarPhase >= 2.0 * PI) g_radarPhase -= 2.0 * PI;
            }
        }

        // ================================================================
        // Navigation Beacon audio (mutually exclusive with aim assist)
        // Triangle wave with frequency sweep, pulsing, and LPF
        // ================================================================
        if (g_beaconActive.load() && !active) {
            float beaconPan = g_beaconPan.load();

            // Calculate pan magnitude and centeredness (0 = far, 1 = centered)
            float panMagnitude = fabsf(beaconPan);
            float centeredness = 1.0f - (panMagnitude / 0.2f);  // 0.2 = max useful range
            centeredness = (centeredness < 0.0f) ? 0.0f : (centeredness > 1.0f) ? 1.0f : centeredness;

            // Frequency sweep: 400 Hz (off center) to 460 Hz (centered)
            float beaconFreq = BEACON_FREQ_MIN + centeredness * (BEACON_FREQ_MAX - BEACON_FREQ_MIN);

            // Advance oscillator phase with current frequency
            double beaconPhaseInc = (2.0 * PI * beaconFreq) / SAMPLE_RATE;
            g_beaconPhase += beaconPhaseInc;
            if (g_beaconPhase >= 2.0 * PI) g_beaconPhase -= 2.0 * PI;

            // Generate triangle wave: map phase [0, 2*PI] to triangle [-1, +1]
            float normalizedPhase = (float)(g_beaconPhase / (2.0 * PI));  // 0 to 1
            float triangleSample = 4.0f * fabsf(normalizedPhase - 0.5f) - 1.0f;

            // Apply one-pole low pass filter (4000 Hz cutoff)
            static const float beaconLpfAlpha = 1.0f - expf(-2.0f * (float)PI * BEACON_LPF_CUTOFF / SAMPLE_RATE);
            g_beaconLpfState += beaconLpfAlpha * (triangleSample - g_beaconLpfState);

            // Calculate pulse rate based on pan magnitude
            float beaconPulseRate = 0.0f;  // 0 = continuous
            if (panMagnitude >= BEACON_CENTER_THRESHOLD) {
                // Map pan [0.05, 0.2+] to pulse rate [15 Hz, 2 Hz]
                float t = (panMagnitude - BEACON_CENTER_THRESHOLD) / (0.2f - BEACON_CENTER_THRESHOLD);
                t = (t < 0.0f) ? 0.0f : (t > 1.0f) ? 1.0f : t;
                beaconPulseRate = BEACON_MAX_PULSE_RATE + t * (BEACON_MIN_PULSE_RATE - BEACON_MAX_PULSE_RATE);
            }

            // Calculate pulse envelope (square wave envelope for on/off)
            float targetEnvelope = 1.0f;
            if (beaconPulseRate > 0.0f) {
                double beaconPulseInc = (2.0 * PI * beaconPulseRate) / SAMPLE_RATE;
                g_beaconPulsePhase += beaconPulseInc;
                if (g_beaconPulsePhase >= 2.0 * PI) g_beaconPulsePhase -= 2.0 * PI;
                targetEnvelope = (sin(g_beaconPulsePhase) > 0.0) ? 1.0f : 0.0f;
            } else {
                g_beaconPulsePhase = 0.0;  // Reset when continuous
            }

            // Smooth attack/release envelope (5ms each for hearing safety)
            static const float beaconSamplesPerMs = SAMPLE_RATE / 1000.0f;
            static const float beaconAttackCoef = 1.0f / (BEACON_ATTACK_MS * beaconSamplesPerMs);
            static const float beaconReleaseCoef = 1.0f / (BEACON_RELEASE_MS * beaconSamplesPerMs);

            if (g_beaconEnvelopeState < targetEnvelope) {
                g_beaconEnvelopeState += beaconAttackCoef;
                if (g_beaconEnvelopeState > targetEnvelope) g_beaconEnvelopeState = targetEnvelope;
            } else if (g_beaconEnvelopeState > targetEnvelope) {
                g_beaconEnvelopeState -= beaconReleaseCoef;
                if (g_beaconEnvelopeState < targetEnvelope) g_beaconEnvelopeState = targetEnvelope;
            }

            // Final sample with volume and envelope
            float beaconSample = g_beaconLpfState * BEACON_VOLUME * g_beaconEnvelopeState;

            // Apply stereo panning - widen by 2x for more dramatic separation
            float widePan = beaconPan * 2.0f;
            if (widePan > 1.0f) widePan = 1.0f;
            if (widePan < -1.0f) widePan = -1.0f;
            float beaconLeftGain = (widePan <= 0.0f) ? 1.0f : (1.0f - widePan);
            float beaconRightGain = (widePan >= 0.0f) ? 1.0f : (1.0f + widePan);

            leftSample += beaconSample * beaconLeftGain;
            rightSample += beaconSample * beaconRightGain;
        }

        // Output stereo
        *output++ = leftSample;
        *output++ = rightSample;

        // Advance phases
        g_phase += primaryPhaseInc;
        if (g_phase >= 2.0 * PI) g_phase -= 2.0 * PI;

        if (primaryPulseRate > 0.0f) {
            g_pulsePhase += primaryPulseInc;
            if (g_pulsePhase >= 2.0 * PI) g_pulsePhase -= 2.0 * PI;
        } else {
            g_pulsePhase = 0.0;  // Reset when continuous
        }

        g_clickPhase += clickPhaseInc;
        if (g_clickPhase >= 2.0 * PI) g_clickPhase -= 2.0 * PI;

        if (secondaryPulseRate > 0.0f) {
            g_clickPulsePhase += clickPulseInc;
            if (g_clickPulsePhase >= 2.0 * PI) g_clickPulsePhase -= 2.0 * PI;
        } else {
            g_clickPulsePhase = 0.0;  // Reset when continuous
        }
    }
}

// Initialize audio device
bool init_audio() {
    if (g_audioInitialized) {
        return true;
    }

    ma_device_config config = ma_device_config_init(ma_device_type_playback);
    config.playback.format = ma_format_f32;
    config.playback.channels = 2;  // Stereo for panning
    config.sampleRate = SAMPLE_RATE;
    config.dataCallback = audio_callback;
    config.pUserData = nullptr;

    if (ma_device_init(nullptr, &config, &g_audioDevice) != MA_SUCCESS) {
        return false;
    }

    if (ma_device_start(&g_audioDevice) != MA_SUCCESS) {
        ma_device_uninit(&g_audioDevice);
        return false;
    }

    g_audioInitialized = true;
    return true;
}

// Shutdown audio device
void shutdown_audio() {
    if (g_audioInitialized) {
        g_shuttingDown.store(true);
        g_aimActive.store(false);
        g_aimMuted.store(true);

        // Just stop the device, don't uninitialize
        // Let the OS clean up on process exit to avoid deadlock
        ma_device_stop(&g_audioDevice);

        // DON'T call ma_device_uninit() - it can deadlock during shutdown
        // g_audioInitialized stays true but that's fine, process is exiting
    }
}

// ============================================================================
// String Utilities
// ============================================================================

// Convert UTF-8 string to wide string (UTF-16)
std::wstring utf8_to_wstring(const std::string& str) {
    if (str.empty()) return std::wstring();

    int size_needed = MultiByteToWideChar(CP_UTF8, 0, str.c_str(), (int)str.length(), NULL, 0);
    if (size_needed <= 0) return std::wstring();

    std::wstring result(size_needed, 0);
    MultiByteToWideChar(CP_UTF8, 0, str.c_str(), (int)str.length(), &result[0], size_needed);
    return result;
}

// Safe string copy to output buffer
void safe_output(char* output, int outputSize, const char* str) {
    if (output && outputSize > 0 && str) {
        strncpy_s(output, outputSize, str, _TRUNCATE);
    }
}

// Parse float from string
float parse_float(const char* str, float defaultVal) {
    if (!str || !*str) return defaultVal;
    char* endptr;
    float val = strtof(str, &endptr);
    return (endptr != str) ? val : defaultVal;
}

// Parse int from string
int parse_int(const char* str, int defaultVal) {
    if (!str || !*str) return defaultVal;
    char* endptr;
    long val = strtol(str, &endptr, 10);
    return (endptr != str) ? (int)val : defaultVal;
}

// ============================================================================
// Arma 3 Extension Entry Points
// ============================================================================

// Return the extension version
void __stdcall RVExtensionVersion(char *output, int outputSize) {
    safe_output(output, outputSize, VERSION);
}

// Main extension entry point (single argument as string)
void __stdcall RVExtension(char *output, int outputSize, const char *function) {
    if (!function || !output || outputSize <= 0) {
        return;
    }

    std::string cmd(function);

    // Command: test - Check if NVDA is running
    if (cmd == "test") {
        error_status_t result = nvdaController_testIfRunning();
        if (result == 0) {
            safe_output(output, outputSize, "OK");
        } else {
            safe_output(output, outputSize, "NVDA_NOT_RUNNING");
        }
        return;
    }

    // Command: speak:text - Make NVDA speak text
    if (cmd.rfind("speak:", 0) == 0) {
        std::string text = cmd.substr(6);
        if (!text.empty()) {
            std::wstring wtext = utf8_to_wstring(text);
            error_status_t result = nvdaController_speakText(wtext.c_str());
            if (result == 0) {
                safe_output(output, outputSize, "OK");
            } else {
                safe_output(output, outputSize, "NVDA_ERROR");
            }
        } else {
            safe_output(output, outputSize, "EMPTY_TEXT");
        }
        return;
    }

    // Command: cancel - Stop current speech
    if (cmd == "cancel") {
        error_status_t result = nvdaController_cancelSpeech();
        if (result == 0) {
            safe_output(output, outputSize, "OK");
        } else {
            safe_output(output, outputSize, "NVDA_ERROR");
        }
        return;
    }

    // Command: braille:text - Send message to braille display
    if (cmd.rfind("braille:", 0) == 0) {
        std::string text = cmd.substr(8);
        if (!text.empty()) {
            std::wstring wtext = utf8_to_wstring(text);
            error_status_t result = nvdaController_brailleMessage(wtext.c_str());
            if (result == 0) {
                safe_output(output, outputSize, "OK");
            } else {
                safe_output(output, outputSize, "NVDA_ERROR");
            }
        } else {
            safe_output(output, outputSize, "EMPTY_TEXT");
        }
        return;
    }

    // ========================================================================
    // Aim Assist Audio Commands
    // ========================================================================

    // Command: aim_start - Initialize audio and start (silent) tone
    if (cmd == "aim_start") {
        if (init_audio()) {
            g_aimPan.store(0.0f);
            g_aimPitch.store(550.0f);
            g_aimVertError.store(1.0f);   // Start at max error
            g_aimHorizError.store(1.0f);  // Start at max error
            g_aimMuted.store(true);       // Start muted until we have a target
            g_aimActive.store(true);
            safe_output(output, outputSize, "OK");
        } else {
            safe_output(output, outputSize, "AUDIO_INIT_FAILED");
        }
        return;
    }

    // Command: aim_update:pan,pitch,vertError,horizError,vertThreshold,horizThreshold
    // pan: -1.0 to 1.0 (left to right)
    // pitch: frequency in Hz (typically 300-800, 550 = vertically centered)
    // vertError: 0.0 to 1.0 (0 = dead center vertically)
    // horizError: 0.0 to 1.0 (0 = dead center horizontally)
    // vertThreshold: adaptive threshold based on target angular size
    // horizThreshold: adaptive threshold based on target angular size
    // Special: pitch of -1 means mute (no target)
    if (cmd.rfind("aim_update:", 0) == 0) {
        std::string params = cmd.substr(11);

        // Parse comma-separated values: pan,pitch,vertError,horizError,vertThreshold,horizThreshold
        float pan = 0.0f;
        float pitch = 550.0f;
        float vertError = 1.0f;
        float horizError = 1.0f;
        float vertThreshold = 0.02f;   // Default fallback
        float horizThreshold = 0.005f; // Default fallback

        size_t pos1 = params.find(',');
        if (pos1 != std::string::npos) {
            pan = parse_float(params.substr(0, pos1).c_str(), 0.0f);

            size_t pos2 = params.find(',', pos1 + 1);
            if (pos2 != std::string::npos) {
                pitch = parse_float(params.substr(pos1 + 1, pos2 - pos1 - 1).c_str(), 550.0f);

                size_t pos3 = params.find(',', pos2 + 1);
                if (pos3 != std::string::npos) {
                    vertError = parse_float(params.substr(pos2 + 1, pos3 - pos2 - 1).c_str(), 1.0f);

                    size_t pos4 = params.find(',', pos3 + 1);
                    if (pos4 != std::string::npos) {
                        horizError = parse_float(params.substr(pos3 + 1, pos4 - pos3 - 1).c_str(), 1.0f);

                        size_t pos5 = params.find(',', pos4 + 1);
                        if (pos5 != std::string::npos) {
                            vertThreshold = parse_float(params.substr(pos4 + 1, pos5 - pos4 - 1).c_str(), 0.02f);
                            horizThreshold = parse_float(params.substr(pos5 + 1).c_str(), 0.005f);
                        } else {
                            vertThreshold = parse_float(params.substr(pos4 + 1).c_str(), 0.02f);
                        }
                    } else {
                        horizError = parse_float(params.substr(pos3 + 1).c_str(), 1.0f);
                    }
                } else {
                    vertError = parse_float(params.substr(pos2 + 1).c_str(), 1.0f);
                }
            } else {
                pitch = parse_float(params.substr(pos1 + 1).c_str(), 550.0f);
            }
        }

        // Check for mute signal (pitch == -1)
        if (pitch < 0) {
            g_aimMuted.store(true);
        } else {
            g_aimMuted.store(false);

            // Clamp values to valid ranges
            pan = (pan < -1.0f) ? -1.0f : (pan > 1.0f) ? 1.0f : pan;
            pitch = (pitch < 100.0f) ? 100.0f : (pitch > 2000.0f) ? 2000.0f : pitch;
            vertError = (vertError < 0.0f) ? 0.0f : (vertError > 1.0f) ? 1.0f : vertError;
            horizError = (horizError < 0.0f) ? 0.0f : (horizError > 1.0f) ? 1.0f : horizError;
            vertThreshold = (vertThreshold < 0.001f) ? 0.001f : (vertThreshold > 0.5f) ? 0.5f : vertThreshold;
            horizThreshold = (horizThreshold < 0.001f) ? 0.001f : (horizThreshold > 0.5f) ? 0.5f : horizThreshold;

            g_aimPan.store(pan);
            g_aimPitch.store(pitch);
            g_aimVertError.store(vertError);
            g_aimHorizError.store(horizError);
            g_aimVertThreshold.store(vertThreshold);
            g_aimHorizThreshold.store(horizThreshold);
        }

        safe_output(output, outputSize, "OK");
        return;
    }

    // Command: aim_blip - Play a one-shot vertical lock blip (800 Hz)
    if (cmd == "aim_blip") {
        g_aimBlipPending.store(true);
        safe_output(output, outputSize, "OK");
        return;
    }

    // Command: aim_unlock_blip - Play a one-shot vertical unlock blip (500 Hz)
    if (cmd == "aim_unlock_blip") {
        g_aimUnlockBlipPending.store(true);
        safe_output(output, outputSize, "OK");
        return;
    }

    // Command: aim_stop - Stop the tone and disable aim assist
    if (cmd == "aim_stop") {
        g_aimActive.store(false);
        g_aimMuted.store(true);
        safe_output(output, outputSize, "OK");
        return;
    }

    // ========================================================================
    // Terrain Radar Audio Commands
    // ========================================================================

    // Command: radar_start - Initialize audio for terrain radar
    if (cmd == "radar_start") {
        if (init_audio()) {
            // Reset queue
            g_radarQueueHead.store(0);
            g_radarQueueTail.store(0);
            // Reset playback state
            g_radarPlayingPan = 0.0f;
            g_radarPlayingVol = 0.5f;
            g_radarPlayingMat = 0;
            g_radarEnvState = 0;
            g_radarEnvelope = 0.0f;
            g_radarActive.store(true);
            safe_output(output, outputSize, "OK");
        } else {
            safe_output(output, outputSize, "AUDIO_INIT_FAILED");
        }
        return;
    }

    // Command: radar_beep:pan,distance,material
    // pan: -1.0 to 1.0 (left to right stereo position)
    // distance: meters to target (used for volume calculation)
    // material: grass, concrete, wood, metal, water, man, glass, default, none
    if (cmd.rfind("radar_beep:", 0) == 0) {
        std::string params = cmd.substr(11);

        // Parse comma-separated values: pan,distance,material
        float pan = 0.0f;
        float distance = 50.0f;
        std::string material = "default";

        size_t pos1 = params.find(',');
        if (pos1 != std::string::npos) {
            pan = parse_float(params.substr(0, pos1).c_str(), 0.0f);

            size_t pos2 = params.find(',', pos1 + 1);
            if (pos2 != std::string::npos) {
                distance = parse_float(params.substr(pos1 + 1, pos2 - pos1 - 1).c_str(), 50.0f);
                material = params.substr(pos2 + 1);
            } else {
                distance = parse_float(params.substr(pos1 + 1).c_str(), 50.0f);
            }
        }

        // Clamp pan
        pan = (pan < -1.0f) ? -1.0f : (pan > 1.0f) ? 1.0f : pan;

        // Calculate volume using logarithmic distance falloff
        // Volume is loud at 0.5m, very quiet at 100m
        float loudDist = 0.5f;
        float quietDist = 100.0f;
        float clampedDist = (distance < loudDist) ? loudDist : (distance > quietDist) ? quietDist : distance;
        float logRange = logf(quietDist) - logf(loudDist);  // ~5.3
        float volume = 1.0f - (logf(clampedDist) - logf(loudDist)) / logRange;
        volume = (volume < 0.02f) ? 0.02f : volume;  // Floor at 2% for audibility

        // Map material string to code
        // 0=default, 1=grass, 2=concrete, 3=wood, 4=metal, 5=water, 6=man, 7=glass, -1=none (silent)
        int matCode = 0;
        if (material == "grass" || material == "soil" || material == "sand" || material == "dirt") {
            matCode = 1;
        } else if (material == "concrete" || material == "asphalt" || material == "rock" || material == "stone") {
            matCode = 2;
        } else if (material == "wood" || material == "wood_planks") {
            matCode = 3;
        } else if (material == "metal" || material == "metal_plate") {
            matCode = 4;
        } else if (material == "water") {
            matCode = 5;
        } else if (material == "man") {
            matCode = 6;
        } else if (material == "glass") {
            matCode = 7;
        } else if (material == "none") {
            matCode = -1;  // Silent - no beep
        }

        // Only queue beep if not "none" and radar is active
        if (matCode >= 0 && g_radarActive.load()) {
            // Add beep to queue
            int head = g_radarQueueHead.load(std::memory_order_relaxed);
            int nextHead = (head + 1) % RADAR_QUEUE_SIZE;

            // Store beep parameters in queue
            g_radarQueue[head].pan = pan;
            g_radarQueue[head].volume = volume;
            g_radarQueue[head].material = matCode;

            // Publish the new head (makes beep visible to audio callback)
            g_radarQueueHead.store(nextHead, std::memory_order_release);
        }

        safe_output(output, outputSize, "OK");
        return;
    }

    // Command: radar_stop - Stop terrain radar audio
    if (cmd == "radar_stop") {
        g_radarActive.store(false);
        // Clear queue
        g_radarQueueHead.store(0);
        g_radarQueueTail.store(0);
        g_radarEnvState = 0;
        g_radarEnvelope = 0.0f;
        safe_output(output, outputSize, "OK");
        return;
    }

    // ========================================================================
    // Navigation Beacon Audio Commands
    // ========================================================================

    // Command: beacon_start - Initialize audio and start beacon
    if (cmd == "beacon_start") {
        if (init_audio()) {
            g_beaconPan.store(0.0f);
            g_beaconPhase = 0.0;
            g_beaconPulsePhase = 0.0;
            g_beaconLpfState = 0.0f;
            g_beaconEnvelopeState = 0.0f;
            g_beaconActive.store(true);
            safe_output(output, outputSize, "OK");
        } else {
            safe_output(output, outputSize, "AUDIO_INIT_FAILED");
        }
        return;
    }

    // Command: beacon_update:pan - Update beacon pan value
    // pan: -1.0 (left) to +1.0 (right)
    if (cmd.rfind("beacon_update:", 0) == 0) {
        std::string params = cmd.substr(14);
        float pan = parse_float(params.c_str(), 0.0f);

        // Clamp pan to valid range
        pan = (pan < -1.0f) ? -1.0f : (pan > 1.0f) ? 1.0f : pan;

        g_beaconPan.store(pan);
        safe_output(output, outputSize, "OK");
        return;
    }

    // Command: beacon_stop - Stop navigation beacon
    if (cmd == "beacon_stop") {
        g_beaconActive.store(false);
        g_beaconEnvelopeState = 0.0f;
        safe_output(output, outputSize, "OK");
        return;
    }

    // Unknown command
    safe_output(output, outputSize, "UNKNOWN_COMMAND");
}

// Extended entry point with array arguments (for future use)
int __stdcall RVExtensionArgs(char *output, int outputSize, const char *function, const char **args, int argsCnt) {
    // For now, just delegate to the simple version
    // In the future, this could handle commands with multiple arguments

    if (!function || !output || outputSize <= 0) {
        return 0;
    }

    std::string cmd(function);

    // Command: speak with array args - speak all arguments concatenated
    if (cmd == "speak" && argsCnt > 0) {
        std::string fullText;
        for (int i = 0; i < argsCnt; i++) {
            if (args[i]) {
                if (!fullText.empty()) fullText += " ";
                fullText += args[i];
            }
        }
        if (!fullText.empty()) {
            std::wstring wtext = utf8_to_wstring(fullText);
            error_status_t result = nvdaController_speakText(wtext.c_str());
            if (result == 0) {
                safe_output(output, outputSize, "OK");
            } else {
                safe_output(output, outputSize, "NVDA_ERROR");
            }
        } else {
            safe_output(output, outputSize, "EMPTY_TEXT");
        }
        return 0;
    }

    // Fall back to simple version for other commands
    RVExtension(output, outputSize, function);
    return 0;
}

// DLL entry point
BOOL APIENTRY DllMain(HMODULE hModule, DWORD reason, LPVOID lpReserved) {
    switch (reason) {
        case DLL_PROCESS_ATTACH:
            break;
        case DLL_THREAD_ATTACH:
        case DLL_THREAD_DETACH:
            break;
        case DLL_PROCESS_DETACH:
            // Clean up audio on DLL unload
            shutdown_audio();
            break;
    }
    return TRUE;
}
