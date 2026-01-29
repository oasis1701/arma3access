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
    "nvda_arma3_bridge" callExtension "speak:Welcome to Arma 3 Blind Assist. NVDA bridge is working.";

    sleep 3;

    // Test 3: Speak player position
    private _pos = getPos player;
    private _grid = mapGridPosition player;
    private _message = format["You are at grid %1. Elevation %2 meters.", _grid, round (_pos select 2)];
    systemChat format["Speaking: %1", _message];
    "nvda_arma3_bridge" callExtension format["speak:%1", _message];

    sleep 2;

    // Initialize Observer Mode system
    [] call BA_fnc_initObserverMode;

    // Initialize Order Menu system
    [] call BA_fnc_initOrderMenu;

    // Initialize Group Menu system
    [] call BA_fnc_initGroupMenu;

    "nvda_arma3_bridge" callExtension "speak:Press Control O to toggle observer mode. Use Tab to cycle units. Control Tab to cycle groups. Press O to open orders menu. Press G to select a group for orders.";

    systemChat "Observer Mode initialized - Ctrl+O toggle, Tab cycle units, Ctrl+Tab cycle groups, O for orders, G for group selection";

} else {
    systemChat "ERROR: NVDA is not running! Please start NVDA and reload the mission.";
};

// Hint for manual testing
hint "Blind Assist Loaded\n\nObserver Mode Hotkeys:\nCtrl+O = Toggle Observer Mode\nTab = Next unit in group\nShift+Tab = Previous unit in group\nCtrl+Tab = Next group\nCtrl+Shift+Tab = Previous group\nO = Open Orders Menu\nG = Select Group for Orders\n\nUse Debug Console for manual tests.";
