/*
 * NVDA-Arma 3 Bridge DLL
 *
 * This DLL bridges Arma 3's callExtension system to NVDA screen reader
 * and provides real-time audio feedback for aiming assistance.
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
 *   "nvda_arma3_bridge" callExtension "aim_update:-0.5,600,0"
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
static const char* VERSION = "1.1.0";

// ============================================================================
// Audio Synthesis State (for aim assist)
// ============================================================================

// Audio parameters (atomic for thread-safe access from audio callback)
static std::atomic<float> g_aimPan(0.0f);       // -1.0 (left) to +1.0 (right)
static std::atomic<float> g_aimPitch(550.0f);   // Frequency in Hz (300-800)
static std::atomic<int> g_aimLocked(0);         // 0 = sine wave, 1 = square wave
static std::atomic<bool> g_aimActive(false);    // Whether aim assist is active
static std::atomic<bool> g_aimMuted(false);     // Mute when no target

// Audio device state
static ma_device g_audioDevice;
static bool g_audioInitialized = false;
static double g_phase = 0.0;

// Audio constants
static const int SAMPLE_RATE = 44100;
static const float BASE_VOLUME = 0.01f;  // Quiet but audible

// Shutdown flag for clean exit
static std::atomic<bool> g_shuttingDown(false);

// Audio callback - generates the tone in real-time
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
    int locked = g_aimLocked.load();
    bool active = g_aimActive.load();
    bool muted = g_aimMuted.load();

    // Calculate per-channel gains for stereo panning
    // Pan: -1 = full left, 0 = center, +1 = full right
    float leftGain = (pan <= 0.0f) ? 1.0f : (1.0f - pan);
    float rightGain = (pan >= 0.0f) ? 1.0f : (1.0f + pan);

    // Phase increment per sample
    double phaseInc = (2.0 * 3.14159265358979323846 * freq) / SAMPLE_RATE;

    for (ma_uint32 i = 0; i < frameCount; i++) {
        float sample = 0.0f;

        if (active && !muted) {
            if (locked) {
                // Rounded square wave for "locked on target" - tanh smooths the sharp edges
                float sharpness = 3.0f;
                sample = (float)(tanh(sin(g_phase) * sharpness) / tanh(sharpness) * BASE_VOLUME);
            } else {
                // Sine wave for "tracking"
                sample = (float)(sin(g_phase) * BASE_VOLUME);
            }
        }

        // Output stereo with panning
        *output++ = sample * leftGain;  // Left channel
        *output++ = sample * rightGain; // Right channel

        // Advance phase
        g_phase += phaseInc;
        if (g_phase >= 2.0 * 3.14159265358979323846) {
            g_phase -= 2.0 * 3.14159265358979323846;
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
            g_aimLocked.store(0);
            g_aimMuted.store(true);  // Start muted until we have a target
            g_aimActive.store(true);
            safe_output(output, outputSize, "OK");
        } else {
            safe_output(output, outputSize, "AUDIO_INIT_FAILED");
        }
        return;
    }

    // Command: aim_update:pan,pitch,locked - Update audio parameters
    // pan: -1.0 to 1.0 (left to right)
    // pitch: frequency in Hz (typically 300-800)
    // locked: 0 or 1 (sine wave vs square wave)
    // Special: pitch of -1 means mute (no target)
    if (cmd.rfind("aim_update:", 0) == 0) {
        std::string params = cmd.substr(11);

        // Parse comma-separated values: pan,pitch,locked
        float pan = 0.0f;
        float pitch = 550.0f;
        int locked = 0;

        size_t pos1 = params.find(',');
        if (pos1 != std::string::npos) {
            pan = parse_float(params.substr(0, pos1).c_str(), 0.0f);

            size_t pos2 = params.find(',', pos1 + 1);
            if (pos2 != std::string::npos) {
                pitch = parse_float(params.substr(pos1 + 1, pos2 - pos1 - 1).c_str(), 550.0f);
                locked = parse_int(params.substr(pos2 + 1).c_str(), 0);
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
            locked = (locked != 0) ? 1 : 0;

            g_aimPan.store(pan);
            g_aimPitch.store(pitch);
            g_aimLocked.store(locked);
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
