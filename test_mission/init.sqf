/*
 * Test Mission init.sqf
 * Tests the NVDA-Arma 3 Bridge and Observer Mode
 *
 * Copy this to your mission folder and run the mission to test.
 * Or use the debug console to run individual commands.
 */

// Wait for mission to fully load
sleep 1;

// Test 1: Check if NVDA is running
private _nvdaStatus = "nvda_arma3_bridge" callExtension "test";
systemChat format["NVDA Status: %1", _nvdaStatus];

if (_nvdaStatus == "OK") then {
    // Test 2: Speak a welcome message
    systemChat "Speaking welcome message...";
    "nvda_arma3_bridge" callExtension "speak:Welcome to Arma 3 Blind Assist, Loading, please wait.";

    // Initialize all Blind Assist systems
    [] call BA_fnc_autoInit;

    // Initialize Dev Sandbox (spawns assets, speaks ready message)
    [] call BA_fnc_initDevSandbox;

} else {
    systemChat "ERROR: NVDA is not running! Please start NVDA and reload the mission.";
};

// Hint for manual testing
hint "Blind Assist Loaded\n\nObserver Mode Hotkeys:\nCtrl+O = Toggle Observer Mode\nTab = Next unit in group\nShift+Tab = Previous unit in group\nCtrl+Tab = Next group\nCtrl+Shift+Tab = Previous group\nO = Open Orders Menu\nG = Select Group for Orders\n\nUse Debug Console for manual tests.";
