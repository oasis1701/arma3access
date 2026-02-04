/*
 * Function: BA_fnc_announceIntersection
 * Announces ALL available directions at an intersection.
 * Includes where you came from, straight ahead, and all side roads.
 *
 * Arguments:
 *   0: _road - Current road object
 *   1: _position - Intersection position
 *   2: _currentDirection - Current travel direction (0 or 1) - unused but kept for compatibility
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [_road, _intersectionPos, 0] call BA_fnc_announceIntersection;
 */

params [
    ["_road", objNull, [objNull]],
    ["_position", [], [[]]],
    ["_currentDirection", 0, [0]]
];

if (isNull _road) exitWith {};
if (count _position < 2) exitWith {};

// Find ALL roads at intersection using multi-method detection
// nearRoads finds by CENTER point, so we need larger radius
private _nearbyRoads = _position nearRoads 50;

// Collect ALL road directions at this intersection
// Format: [[bearing, "direction"], ...]
private _allDirections = [];

{
    private _connRoad = _x;

    private _connInfo = getRoadInfo _connRoad;
    if (count _connInfo == 0) then { continue };

    _connInfo params ["", "", "", "", "", "", "_connBeg", "_connEnd"];

    // Which endpoint is at the intersection?
    private _begDist = _position distance2D _connBeg;
    private _endDist = _position distance2D _connEnd;

    // Skip roads that don't touch the intersection (within 15m tolerance)
    if (_begDist > 15 && _endDist > 15) then { continue };

    // Calculate bearing of road (away from intersection)
    private _roadBearing = if (_begDist < _endDist) then {
        _connBeg getDir _connEnd
    } else {
        _connEnd getDir _connBeg
    };

    // Convert bearing to compass direction
    private _compassDir = [_roadBearing] call BA_fnc_bearingToCompass;

    // Store bearing and direction for sorting
    _allDirections pushBack [_roadBearing, toLower _compassDir];
} forEach _nearbyRoads;

// Sort by bearing for logical order (N first, then clockwise)
_allDirections sort true;

// Extract just the compass directions
private _sortedDirs = _allDirections apply { _x select 1 };

// Remove duplicates (in case multiple roads go same direction)
private _uniqueDirs = [];
{
    if !(_x in _uniqueDirs) then {
        _uniqueDirs pushBack _x;
    };
} forEach _sortedDirs;

// Build announcement
if (count _uniqueDirs > 0) then {
    private _roadsText = _uniqueDirs joinString ", ";
    private _announcement = format ["Intersection. Roads %1.", _roadsText];
    [_announcement] call BA_fnc_speak;
} else {
    ["Intersection."] call BA_fnc_speak;
};
