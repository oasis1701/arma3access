/*
 * Function: BA_fnc_announceCursorDetailed
 * Announces detailed cursor position info including objects and units.
 *
 * Arguments:
 *   None (uses BA_cursorPos)
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_announceCursorDetailed;
 *   // Speaks: "Grid 0 4 5, 0 7 2. Grass. 45 meters. Gentle slope.
 *   //          2 buildings, 1 vehicle nearby. 3 friendlies within 200 meters.
 *   //          2 known enemies. 320 meters northeast of observed unit."
 */

// Must be in observer mode or focus mode
if (!BA_observerMode && !BA_focusMode) exitWith {
    ["Not in observer or focus mode."] call BA_fnc_speak;
};

// Get basic info
private _terrain = [BA_cursorPos] call BA_fnc_getTerrainInfo;
private _altitude = [BA_cursorPos] call BA_fnc_getAltitudeInfo;
private _slope = [BA_cursorPos] call BA_fnc_getSlopeInfo;
private _grid = [BA_cursorPos] call BA_fnc_getGridInfo;

// Get nearby objects
private _objects = [BA_cursorPos, 50] call BA_fnc_getNearbyObjects;
_objects params ["_buildings", "_vehicles", "_trees"];

// Get nearby units (now returns direction info too)
private _units = [BA_cursorPos, 200, 500] call BA_fnc_getNearbyUnits;
_units params ["_friendlyInfo", "_enemyInfo"];
_friendlyInfo params ["_friendlyCount", "_nearestFriendlyDist", "_nearestFriendlyDir"];
_enemyInfo params ["_enemyCount", "_nearestEnemyDist", "_nearestEnemyDir"];

// Get bearing and distance from observed unit
private _bearingDist = [BA_cursorPos] call BA_fnc_getBearingDistance;

// Build announcement parts
private _parts = [];

// Basic info (terrain, altitude, slope first)
_parts pushBack format["%1. %2. %3.", _terrain, _altitude, _slope];

// Objects (only mention if present)
private _objectParts = [];
if (_buildings > 0) then {
    _objectParts pushBack format["%1 %2", _buildings, if (_buildings == 1) then {"building"} else {"buildings"}];
};
if (_vehicles > 0) then {
    _objectParts pushBack format["%1 %2", _vehicles, if (_vehicles == 1) then {"vehicle"} else {"vehicles"}];
};

if (count _objectParts > 0) then {
    _parts pushBack ((_objectParts joinString ", ") + " nearby.");
};

// Friendlies with direction to nearest
if (_friendlyCount > 0) then {
    _parts pushBack format["%1 %2. Nearest %3 meters %4.",
        _friendlyCount,
        if (_friendlyCount == 1) then {"friendly"} else {"friendlies"},
        _nearestFriendlyDist,
        _nearestFriendlyDir
    ];
} else {
    _parts pushBack "No friendlies nearby.";
};

// Enemies with direction to nearest
if (_enemyCount > 0) then {
    _parts pushBack format["%1 known %2. Nearest %3 meters %4.",
        _enemyCount,
        if (_enemyCount == 1) then {"enemy"} else {"enemies"},
        _nearestEnemyDist,
        _nearestEnemyDir
    ];
} else {
    _parts pushBack "No known enemies.";
};

// Bearing and distance from unit
_parts pushBack _bearingDist;

// Grid reference (last)
_parts pushBack _grid;

// Join all parts and speak
private _announcement = _parts joinString " ";
[_announcement] call BA_fnc_speak;

// Also log to system chat for debugging
systemChat format["Cursor: %1", _announcement];
