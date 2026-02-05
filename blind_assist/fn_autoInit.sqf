/*
 * fn_autoInit.sqf - Automatically initialize Blind Assist when mission starts
 *
 * This function runs via postInit (CfgFunctions) so it executes automatically
 * in ANY mission when the addon is loaded - no mission editing required.
 */

// Only run on player's machine (not dedicated server)
if (!hasInterface) exitWith {};

// Wait for player to exist
waitUntil {!isNull player};

// Small delay to ensure mission is fully loaded
sleep 1;

// Initialize all Blind Assist systems
[] call BA_fnc_initObserverMode;
[] call BA_fnc_initOrderMenu;
[] call BA_fnc_initGroupMenu;
[] call BA_fnc_initLandmarksMenu;
[] call BA_fnc_initScanner;
[] call BA_fnc_initAimAssist;
[] call BA_fnc_initTerrainRadar;
[] call BA_fnc_initDirectionSnap;
[] call BA_fnc_initPlayerNav;
[] call BA_fnc_initEnemyDetection;
[] call BA_fnc_initChatReader;

// Register handler for save game loads
// postInit doesn't run when loading saves, so we need this event handler
addMissionEventHandler ["Loaded", {
    // Re-initialize when a save is loaded
    [] spawn {
        sleep 0.5;
        [] call BA_fnc_initObserverMode;
        [] call BA_fnc_initOrderMenu;
        [] call BA_fnc_initGroupMenu;
        [] call BA_fnc_initLandmarksMenu;
        [] call BA_fnc_initScanner;
        [] call BA_fnc_initAimAssist;
        [] call BA_fnc_initTerrainRadar;
        [] call BA_fnc_initDirectionSnap;
        [] call BA_fnc_initPlayerNav;
        [] call BA_fnc_initEnemyDetection;
        [] call BA_fnc_initChatReader;
        ["Blind Assist loaded."] call BA_fnc_speak;
    };
}];

// Announce ready
["Blind Assist loaded."] call BA_fnc_speak;
