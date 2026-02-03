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
static const char* VERSION = "1.3.0";

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

// Audio device state
static ma_device g_audioDevice;
static bool g_audioInitialized = false;
static double g_phase = 0.0;           // Primary tone phase
static double g_pulsePhase = 0.0;      // Primary tone pulse envelope phase
static double g_clickPhase = 0.0;      // Secondary click tone phase
static double g_clickPulsePhase = 0.0; // Secondary click pulse envelope phase
static float g_clickLpfState = 0.0f;   // Low pass filter state for click tone

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
static const float MIN_PULSE_RATE = 2.0f;       // Slowest pulse rate (Hz) at max error
static const float MAX_PULSE_RATE = 15.0f;      // Fastest pulse rate (Hz) at min error
static const float HORIZ_ACTIVATE_THRESHOLD = 0.2f; // Secondary tone activates when abs(pan) < this (close to target)
static const double PI = 3.14159265358979323846;
// Note: VERT_CENTER_THRESHOLD and HORIZ_CENTER_THRESHOLD are now adaptive (passed from SQF)

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
    // At max error: slow pulse (2 Hz)
    // At min error: fast pulse (15 Hz)
    // Threshold is adaptive based on target angular size
    float primaryPulseRate = 0.0f;
    if (vertError >= vertThreshold) {
        // Linear interpolation: high error = slow, low error = fast
        primaryPulseRate = MIN_PULSE_RATE + (1.0f - vertError) * (MAX_PULSE_RATE - MIN_PULSE_RATE);
    }

    // Calculate secondary click pulse rate based on horizontal error
    // Only active when roughly facing target (abs(pan) < 1.0)
    // Threshold is adaptive based on target angular size
    bool secondaryActive = (fabsf(pan) < HORIZ_ACTIVATE_THRESHOLD);
    float secondaryPulseRate = 0.0f;
    if (secondaryActive && horizError >= horizThreshold) {
        secondaryPulseRate = MIN_PULSE_RATE + (1.0f - horizError) * (MAX_PULSE_RATE - MIN_PULSE_RATE);
    }

    // Calculate click frequency: sweep from 500 Hz (at threshold) to 560 Hz (at center)
    // Uses HORIZ_ACTIVATE_THRESHOLD so it auto-scales if threshold changes
    float clickFreq = CLICK_FREQ_MAX;  // Default to center frequency
    if (secondaryActive) {
        float panMagnitude = fabsf(pan);
        // Map pan from [0, threshold] to frequency [560, 500]
        float t = panMagnitude / HORIZ_ACTIVATE_THRESHOLD;  // 0 at center, 1 at threshold
        clickFreq = CLICK_FREQ_MAX + t * (CLICK_FREQ_MIN - CLICK_FREQ_MAX);
    }

    // Low pass filter coefficient for click tone (one-pole filter)
    static const float clickLpfAlpha = 1.0f - expf(-2.0f * (float)PI * CLICK_LPF_CUTOFF / SAMPLE_RATE);

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

            // Apply pulse envelope if not at dead center
            if (primaryPulseRate > 0.0f) {
                // Square wave envelope: on when sin > 0, off when sin < 0
                float envelope = (sin(g_pulsePhase) > 0.0f) ? 1.0f : 0.0f;
                primarySample *= envelope;
            }
            // else: continuous tone (no envelope)

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

                // Apply pulse envelope if not at dead center
                if (secondaryPulseRate > 0.0f) {
                    float clickEnvelope = (sin(g_clickPulsePhase) > 0.0f) ? 1.0f : 0.0f;
                    clickSample *= clickEnvelope;
                }
                // else: continuous tone (no envelope)

                // Pan click based on target direction, or center when at dead center
                if (horizError < horizThreshold) {
                    // Dead center - play in both ears (centered)
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

    // Command: aim_stop - Stop the tone and disable aim assist
    if (cmd == "aim_stop") {
        g_aimActive.store(false);
        g_aimMuted.store(true);
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
