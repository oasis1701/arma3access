/*
 * Function: BA_fnc_getNearbyObjects
 * Counts buildings, vehicles, and trees near a position.
 *
 * Arguments:
 *   0: _pos - Position to check (default: BA_cursorPos)
 *   1: _radius - Search radius in meters (default: 50)
 *
 * Return Value:
 *   Array - [buildings, vehicles, trees] counts
 *
 * Example:
 *   private _counts = [BA_cursorPos, 50] call BA_fnc_getNearbyObjects;
 *   // Returns [2, 1, 15]
 */

params [
    ["_pos", [], [[]]],
    ["_radius", 50, [0]]
];

// Use cursor position if none provided
if (count _pos == 0) then {
    _pos = BA_cursorPos;
};

// Count buildings (House class and subclasses)
private _buildings = nearestObjects [_pos, ["House", "Building"], _radius];
private _buildingCount = count _buildings;

// Count vehicles (all vehicle types except men)
private _vehicles = nearestObjects [_pos, ["Car", "Tank", "Air", "Ship", "StaticWeapon"], _radius];
private _vehicleCount = count _vehicles;

// Count trees (using nearestTerrainObjects for vegetation)
private _trees = nearestTerrainObjects [_pos, ["TREE", "SMALL TREE", "BUSH"], _radius];
private _treeCount = count _trees;

[_buildingCount, _vehicleCount, _treeCount]
