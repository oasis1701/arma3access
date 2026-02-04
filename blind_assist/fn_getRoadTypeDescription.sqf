/*
 * Function: BA_fnc_getRoadTypeDescription
 * Converts road info from getRoadInfo to a human-readable description.
 *
 * Arguments:
 *   0: _roadInfo - Array from getRoadInfo command, or road object
 *
 * Return Value:
 *   String - Human-readable road description (e.g., "main road", "dirt track")
 *
 * Example:
 *   [getRoadInfo _road] call BA_fnc_getRoadTypeDescription;
 *   [_road] call BA_fnc_getRoadTypeDescription;
 */

params [
    ["_input", [], [[], objNull]]
];

// If passed a road object, get its info
private _roadInfo = if (_input isEqualType objNull) then {
    if (isNull _input) exitWith { [] };
    getRoadInfo _input
} else {
    _input
};

// Return empty string if no info
if (count _roadInfo == 0) exitWith { "" };

// getRoadInfo returns:
// [mapType, width, isPedestrian, texture, textureEnd, material, begPos, endPos, isBridge, AIpathOffset]
_roadInfo params [
    "_mapType",
    "_width",
    "_isPedestrian",
    "_texture",
    "_textureEnd",
    "_material",
    "_begPos",
    "_endPos",
    "_isBridge",
    "_aiPathOffset"
];

// Build description based on road type
private _description = switch (toUpper _mapType) do {
    case "MAIN ROAD": { "main road" };
    case "ROAD": { "road" };
    case "TRACK": { "dirt track" };
    case "TRAIL": { "footpath" };
    case "HIDE": { "path" };
    default { "road" };
};

// Add bridge indicator if applicable
if (_isBridge) then {
    _description = "bridge";
};

// Add pedestrian indicator for trails
if (_isPedestrian && {_mapType != "TRAIL"}) then {
    _description = "pedestrian " + _description;
};

_description
