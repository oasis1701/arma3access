/*
 * NVDA-Arma 3 Bridge DLL
 *
 * This DLL bridges Arma 3's callExtension system to NVDA screen reader.
 * It allows SQF scripts to make NVDA speak text, send braille messages,
 * and check if NVDA is running.
 *
 * Build with Visual Studio 2022 Developer Command Prompt:
 *   cl /LD /EHsc /Fe:nvda_arma3_bridge_x64.dll nvda_arma3_bridge.cpp nvdaControllerClient.lib
 *
 * Usage in Arma 3 SQF:
 *   "nvda_arma3_bridge" callExtension "speak:Hello world"
 *   "nvda_arma3_bridge" callExtension "cancel"
 *   "nvda_arma3_bridge" callExtension "braille:Message"
 *   "nvda_arma3_bridge" callExtension "test"
 */

#define UNICODE
#define _UNICODE

#include <windows.h>
#include <string>
#include <cstring>

// NVDA Controller Client header
#include "nvdaController.h"

// Arma 3 extension entry points
extern "C" {
    __declspec(dllexport) void __stdcall RVExtensionVersion(char *output, int outputSize);
    __declspec(dllexport) void __stdcall RVExtension(char *output, int outputSize, const char *function);
    __declspec(dllexport) int __stdcall RVExtensionArgs(char *output, int outputSize, const char *function, const char **args, int argsCnt);
}

// DLL version string
static const char* VERSION = "1.0.0";

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
        case DLL_THREAD_ATTACH:
        case DLL_THREAD_DETACH:
        case DLL_PROCESS_DETACH:
            break;
    }
    return TRUE;
}
