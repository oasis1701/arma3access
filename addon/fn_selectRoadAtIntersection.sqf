/*
 * Function: BA_fnc_selectRoadAtIntersection
 * Selects a road at an intersection based on compass direction.
 * Used with Shift+Arrow keys to turn onto intersecting roads.
 *
 * Arguments:
 *   0: _direction - Compass direction to turn ("North", "South", "East", "West")
 *
 * Return Value:
 *   Boolean - true if successfully turned onto a road
 *
 * Example:
 *   ["East"] call BA_fnc_selectRoadAtIntersection;
 */

params [
    ["_direction", "", [""]]
];

// Must be in observer mode with road mode enabled and on a road
if (!BA_observerMode || !BA_cursorActive || !BA_roadModeEnabled) exitWith { false };

if (isNull BA_currentRoad) exitWith {
    ["Not on a road."] call BA_fnc_speak;
    false
};

// Get cursor position
private _cursorPos2D = [BA_cursorPos select 0, BA_cursorPos select 1];

// Convert direction to target bearing
private _targetBearing = switch (_direction) do {
    case "North": { 0 };
    case "East":  { 90 };
    case "South": { 180 };
    case "West":  { 270 };
    default { -1 };
};

if (_targetBearing < 0) exitWith { false };

// Find nearest intersection point on current road
private _roadInfo = getRoadInfo BA_currentRoad;
if (count _roadInfo == 0) exitWith { false };

_roadInfo params ["", "", "", "", "", "", "_begPos", "_endPos"];

// Determine which endpoint is closer (that's likely the intersection)
private _begDist = _cursorPos2D distance2D _begPos;
private _endDist = _cursorPos2D distance2D _endPos;
private _intersectionPos = if (_begDist < _endDist) then { _begPos } else { _endPos };

// Only allow turning if we're near an intersection point (within 20m)
private _distToIntersection = _cursorPos2D distance2D _intersectionPos;
if (_distToIntersection > 20) exitWith {
    ["No intersection nearby."] call BA_fnc_speak;
    false
};

// Find ALL roads at intersection using multi-method detection
// nearRoads finds by CENTER point, so we need larger radius
private _nearbyRoads = _intersectionPos nearRoads 50;

if (count _nearbyRoads == 0) exitWith {
    ["No roads to turn onto."] call BA_fnc_speak;
    false
};

// Find road closest to desired direction
private _bestRoad = objNull;
private _bestAngleDiff = 180;
private _bestDirection = 0;

{
    private _connRoad = _x;
    // Skip the current road
    if (_connRoad isEqualTo BA_currentRoad) then { continue };

    private _connInfo = getRoadInfo _connRoad;
    if (count _connInfo == 0) then { continue };

    _connInfo params ["", "", "", "", "", "", "_connBeg", "_connEnd"];

    // Check if this road connects at our intersection (within 15m tolerance)
    private _begDist = _intersectionPos distance2D _connBeg;
    private _endDist = _intersectionPos distance2D _connEnd;

    if (_begDist > 15 && _endDist > 15) then { continue };

    // Calculate bearing away from intersection
    private _roadBearing = if (_begDist < _endDist) then {
        _connBeg getDir _connEnd
    } else {
        _connEnd getDir _connBeg
    };

    // Check how close this bearing is to target
    private _angleDiff = abs (_roadBearing - _targetBearing);
    if (_angleDiff > 180) then { _angleDiff = 360 - _angleDiff };

    // Accept roads within 45 degrees of target direction
    if (_angleDiff < _bestAngleDiff && _angleDiff < 45) then {
        _bestRoad = _connRoad;
        _bestAngleDiff = _angleDiff;
        // Determine direction on new road
        _bestDirection = if (_begDist < _endDist) then { 0 } else { 1 };
    };
} forEach _nearbyRoads;

if (isNull _bestRoad) exitWith {
    [format ["No road %1.", toLower _direction]] call BA_fnc_speak;
    false
};

// Switch to new road
BA_currentRoad = _bestRoad;
BA_roadDirection = _bestDirection;
BA_lastRoadInfo = getRoadInfo BA_currentRoad;

// Move cursor to intersection
private _z = getTerrainHeightASL _intersectionPos;
BA_cursorPos = [_intersectionPos select 0, _intersectionPos select 1, _z];

// Announce turn
private _roadType = [BA_lastRoadInfo] call BA_fnc_getRoadTypeDescription;
private _compass = [_targetBearing] call BA_fnc_bearingToCompass;
[format ["Turned %1 onto %2.", toLower _compass, _roadType]] call BA_fnc_speak;

// Auto-refresh scanner
[] call BA_fnc_scanObjects;

true
