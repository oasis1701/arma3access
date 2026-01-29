/*
 * Function: BA_fnc_toggleRoadMode
 * Toggles road exploration mode on/off.
 * When enabled, arrow keys snap to and follow roads instead of free movement.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   Boolean - new state of road mode
 *
 * Example:
 *   [] call BA_fnc_toggleRoadMode;
 */

// Must be in observer mode
if (!BA_observerMode) exitWith {
    ["Observer mode required."] call BA_fnc_speak;
    false
};

// Toggle the mode
BA_roadModeEnabled = !BA_roadModeEnabled;

// Reset road tracking when toggling
if (BA_roadModeEnabled) then {
    // Entering road mode
    BA_currentRoad = objNull;
    BA_roadDirection = 0;
    BA_lastRoadInfo = [];

    ["Road mode on."] call BA_fnc_speak;
} else {
    // Exiting road mode
    BA_currentRoad = objNull;
    BA_roadDirection = 0;
    BA_lastRoadInfo = [];

    ["Road mode off."] call BA_fnc_speak;
};

BA_roadModeEnabled
