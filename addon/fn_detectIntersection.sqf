/*
 * Function: BA_fnc_detectIntersection
 * Checks if a position on a road is at an intersection.
 * An intersection is where more than 2 road segments meet (including current road).
 *
 * Arguments:
 *   0: _road - Road object to check from
 *   1: _position - Position to check (usually an endpoint)
 *
 * Return Value:
 *   Boolean - true if position is at an intersection
 *
 * Example:
 *   [_road, _endPos] call BA_fnc_detectIntersection;
 */

params [
    ["_road", objNull, [objNull]],
    ["_position", [], [[]]]
];

if (isNull _road) exitWith { false };
if (count _position < 2) exitWith { false };

// Multi-method road detection for consistent intersection detection
// nearRoads finds roads by CENTER point, not endpoints, so we need larger radius

// Method 1: Check for road directly at position
private _roadAtPosition = roadAt _position;

// Method 2: Use Arma's road graph with extended search
private _graphConnected = roadsConnectedTo [_road, true];

// Method 3: Find roads within large radius (road segments can be 40m+ long)
private _nearbyRoads = _position nearRoads 50;

// Combine all found roads (remove duplicates)
private _allRoads = [];

if (!isNull _roadAtPosition) then {
    _allRoads pushBackUnique _roadAtPosition;
};

{
    _allRoads pushBackUnique _x;
} forEach _graphConnected;

{
    _allRoads pushBackUnique _x;
} forEach _nearbyRoads;

// Count unique roads at this position (excluding current road)
private _roadsAtPosition = 0;

{
    private _connRoad = _x;
    if (_connRoad isEqualTo _road) then { continue };

    private _connInfo = getRoadInfo _connRoad;
    if (count _connInfo == 0) then { continue };

    _connInfo params ["", "", "", "", "", "", "_connBeg", "_connEnd"];

    // Check if either endpoint of connected road is near our position
    private _begDist = _position distance2D _connBeg;
    private _endDist = _position distance2D _connEnd;

    // Road endpoints are close to our position (within 15m tolerance)
    if (_begDist < 15 || _endDist < 15) then {
        _roadsAtPosition = _roadsAtPosition + 1;
    };
} forEach _allRoads;

// Intersection = 2 or more other roads meeting at this point
// (our road + 2 others = 3-way intersection minimum)
_roadsAtPosition >= 2
