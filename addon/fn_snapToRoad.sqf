/*
 * Function: BA_fnc_snapToRoad
 * Finds nearest road in a direction and snaps cursor to it.
 * Used when road mode is enabled but cursor is not on a road.
 *
 * Arguments:
 *   0: _direction - Compass direction to search ("North", "South", "East", "West")
 *
 * Return Value:
 *   Boolean - true if successfully snapped to a road
 *
 * Example:
 *   ["North"] call BA_fnc_snapToRoad;
 */

params [
    ["_direction", "", [""]]
];

// Must be in observer mode with cursor active
if (!BA_observerMode || !BA_cursorActive) exitWith { false };

private _searchRadius = 200; // meters
private _cursorPos2D = [BA_cursorPos select 0, BA_cursorPos select 1];

// Find all roads within search radius
private _nearbyRoads = _cursorPos2D nearRoads _searchRadius;

if (count _nearbyRoads == 0) exitWith {
    ["No road within range."] call BA_fnc_speak;
    false
};

// Calculate direction vector for filtering
private _dirVector = switch (_direction) do {
    case "North": { [0, 1] };
    case "South": { [0, -1] };
    case "East":  { [1, 0] };
    case "West":  { [-1, 0] };
    default { [0, 0] };
};

// Filter roads by direction and find closest
private _bestRoad = objNull;
private _bestDist = 999999;
private _bestPos = [];

{
    private _road = _x;
    private _roadInfo = getRoadInfo _road;
    if (count _roadInfo == 0) then { continue };

    _roadInfo params ["", "", "", "", "", "", "_begPos", "_endPos"];

    // Road center position
    private _roadCenter = [
        ((_begPos select 0) + (_endPos select 0)) / 2,
        ((_begPos select 1) + (_endPos select 1)) / 2
    ];

    // Vector from cursor to road
    private _toRoad = [
        (_roadCenter select 0) - (_cursorPos2D select 0),
        (_roadCenter select 1) - (_cursorPos2D select 1)
    ];

    // Normalize
    private _dist = sqrt ((_toRoad select 0)^2 + (_toRoad select 1)^2);
    if (_dist < 1) then { _dist = 1 };

    private _toRoadNorm = [
        (_toRoad select 0) / _dist,
        (_toRoad select 1) / _dist
    ];

    // Dot product to check if road is in requested direction
    private _dot = (_toRoadNorm select 0) * (_dirVector select 0) + (_toRoadNorm select 1) * (_dirVector select 1);

    // Only consider roads in the requested direction (dot > 0.3 gives ~70 degree cone)
    if (_dot > 0.3 && _dist < _bestDist) then {
        _bestRoad = _road;
        _bestDist = _dist;
        _bestPos = _roadCenter;
    };
} forEach _nearbyRoads;

// If no road found in direction, try any nearby road
if (isNull _bestRoad) then {
    {
        private _road = _x;
        private _roadInfo = getRoadInfo _road;
        if (count _roadInfo == 0) then { continue };

        _roadInfo params ["", "", "", "", "", "", "_begPos", "_endPos"];

        private _roadCenter = [
            ((_begPos select 0) + (_endPos select 0)) / 2,
            ((_begPos select 1) + (_endPos select 1)) / 2
        ];

        private _dist = _cursorPos2D distance2D _roadCenter;

        if (_dist < _bestDist) then {
            _bestRoad = _road;
            _bestDist = _dist;
            _bestPos = _roadCenter;
        };
    } forEach _nearbyRoads;
};

if (isNull _bestRoad) exitWith {
    ["No road within range."] call BA_fnc_speak;
    false
};

// Get road info for announcement
private _roadInfo = getRoadInfo _bestRoad;
private _roadType = [_roadInfo] call BA_fnc_getRoadTypeDescription;

// Get road direction (bearing from begPos to endPos)
_roadInfo params ["", "", "", "", "", "", "_begPos", "_endPos"];
private _roadBearing = _begPos getDir _endPos;

// Determine which direction cursor will face based on arrow key pressed
private _cursorBearing = switch (_direction) do {
    case "North": { 0 };
    case "East":  { 90 };
    case "South": { 180 };
    case "West":  { 270 };
    default { 0 };
};

// Decide road direction based on which endpoint is closer to intended direction
private _bearingDiff = abs (_roadBearing - _cursorBearing);
if (_bearingDiff > 180) then { _bearingDiff = 360 - _bearingDiff };

// If cursor bearing is closer to road bearing, go toward endPos (direction 0)
// Otherwise go toward begPos (direction 1)
BA_roadDirection = if (_bearingDiff <= 90) then { 0 } else { 1 };

// Calculate heading text
private _headingBearing = if (BA_roadDirection == 0) then { _roadBearing } else { (_roadBearing + 180) mod 360 };
private _headingCompass = [_headingBearing] call BA_fnc_bearingToCompass;

// Calculate jump distance and direction before moving cursor
private _jumpDist = _cursorPos2D distance2D _bestPos;
private _jumpBearing = _cursorPos2D getDir _bestPos;
private _jumpDir = [_jumpBearing] call BA_fnc_bearingToCompass;

// Snap cursor to road center
private _z = getTerrainHeightASL _bestPos;
BA_cursorPos = [_bestPos select 0, _bestPos select 1, _z];
BA_currentRoad = _bestRoad;
BA_lastRoadInfo = _roadInfo;

// Clear any dead end state
BA_atRoadEnd = false;

// Announce snap with jump distance: "Snapped to main road, 45 meters east. Heading northeast."
private _announcement = format ["Snapped to %1, %2 meters %3. Heading %4.",
    _roadType, round _jumpDist, toLower _jumpDir, toLower _headingCompass];
[_announcement] call BA_fnc_speak;

// Auto-refresh scanner
[] call BA_fnc_scanObjects;

true
