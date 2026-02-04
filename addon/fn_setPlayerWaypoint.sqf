/*
 * Function: BA_fnc_setPlayerWaypoint
 * Sets a navigation waypoint at the current cursor position.
 *
 * Clears any existing navigation, creates a local marker at the destination,
 * announces the initial distance, and initiates pathfinding.
 *
 * Hotkey: Y key (DIK 21)
 *
 * Arguments:
 *   None (uses BA_cursorPos for destination)
 *
 * Return Value:
 *   Boolean - true if waypoint was set successfully
 *
 * Example:
 *   [] call BA_fnc_setPlayerWaypoint;
 */

// Get the soldier (BA_originalUnit in observer mode, player otherwise)
private _soldier = if (BA_observerMode && {!isNull BA_originalUnit}) then {
    BA_originalUnit
} else {
    player
};

if (isNull _soldier || !alive _soldier) exitWith {
    ["Cannot set waypoint: no soldier."] call BA_fnc_speak;
    false
};

// Check if cursor is active and has a valid position
if (!BA_cursorActive || count BA_cursorPos < 2) exitWith {
    ["Cannot set waypoint: no cursor position."] call BA_fnc_speak;
    false
};

// Clear existing navigation if active
if (BA_playerNavEnabled) then {
    [] call BA_fnc_clearPlayerWaypoint;
};

// Set up navigation state
BA_playerNavEnabled = true;
BA_playerNavDestination = +BA_cursorPos;  // Copy the position
BA_playerNavLastDistAnnounced = -1;
BA_playerNavLastRecalcTime = 0;
BA_playerNavPathIndex = 0;
BA_playerNavPath = [];

// Create local marker at destination (only visible to this player)
BA_playerNavMarker = format ["BA_navWaypoint_%1", round random 99999];
createMarkerLocal [BA_playerNavMarker, BA_playerNavDestination];
BA_playerNavMarker setMarkerTypeLocal "mil_objective";
BA_playerNavMarker setMarkerColorLocal "ColorYellow";
BA_playerNavMarker setMarkerTextLocal "Waypoint";

// Calculate initial distance and announce
private _distance = (getPos _soldier) distance2D BA_playerNavDestination;
private _distRounded = round _distance;

["Waypoint set. " + (str _distRounded) + " meters."] call BA_fnc_speak;

// Initialize last announced threshold based on current distance
// Find the lowest threshold that is still below current distance
{
    if (_distance > _x) exitWith {
        BA_playerNavLastDistAnnounced = _x;
    };
} forEach BA_playerNavThresholds;

diag_log format ["Blind Assist: Waypoint set at %1, distance %2m", BA_playerNavDestination, _distRounded];

// Start pathfinding (async - will start beacon and update loop on completion)
[_soldier, BA_playerNavDestination] call BA_fnc_calculateNavPath;

true
