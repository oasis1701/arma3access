/*
 * Function: BA_fnc_getNearbyUnits
 * Counts friendly and known enemy units near a position.
 * Returns counts AND direction/distance to nearest units for navigation.
 * Uses side-wide intelligence (knowsAbout) for enemy detection.
 *
 * Arguments:
 *   0: _pos - Position to check (default: BA_cursorPos)
 *   1: _friendlyRadius - Radius for friendly detection (default: 200)
 *   2: _enemyRadius - Radius for enemy detection (default: 500)
 *
 * Return Value:
 *   Array - [
 *     [friendlyCount, nearestFriendlyDist, nearestFriendlyDir],
 *     [enemyCount, nearestEnemyDist, nearestEnemyDir]
 *   ]
 *   Direction is compass string like "north", "northeast", etc.
 *   Distance is -1 if no units found.
 *
 * Example:
 *   private _units = [BA_cursorPos, 200, 500] call BA_fnc_getNearbyUnits;
 *   // Returns [[3, 45, "north"], [2, 120, "east"]]
 */

params [
    ["_pos", [], [[]]],
    ["_friendlyRadius", 200, [0]],
    ["_enemyRadius", 500, [0]]
];

// Use cursor position if none provided
if (count _pos == 0) then {
    _pos = BA_cursorPos;
};

// Helper function to convert bearing to compass direction
private _bearingToCompass = {
    params ["_bearing"];
    switch (true) do {
        case (_bearing >= 337.5 || _bearing < 22.5): { "north" };
        case (_bearing >= 22.5 && _bearing < 67.5): { "northeast" };
        case (_bearing >= 67.5 && _bearing < 112.5): { "east" };
        case (_bearing >= 112.5 && _bearing < 157.5): { "southeast" };
        case (_bearing >= 157.5 && _bearing < 202.5): { "south" };
        case (_bearing >= 202.5 && _bearing < 247.5): { "southwest" };
        case (_bearing >= 247.5 && _bearing < 292.5): { "west" };
        case (_bearing >= 292.5 && _bearing < 337.5): { "northwest" };
        default { "unknown" };
    }
};

// Need observed unit to determine player's side
if (isNull BA_observedUnit) exitWith { [[0, -1, ""], [0, -1, ""]] };

private _playerSide = side BA_observedUnit;

// Get all units within the larger radius
private _allUnits = _pos nearEntities [["Man"], _enemyRadius];

// Filter out dead units and the observed unit itself
_allUnits = _allUnits select { alive _x && _x != BA_observedUnit };

// Find friendlies within friendly radius
private _friendlies = _allUnits select {
    (side _x == _playerSide || (side _x) getFriend _playerSide >= 0.6) &&
    (_x distance _pos) <= _friendlyRadius
};
private _friendlyCount = count _friendlies;

// Find nearest friendly
private _nearestFriendlyDist = -1;
private _nearestFriendlyDir = "";
if (_friendlyCount > 0) then {
    // Sort by distance and get nearest
    _friendlies = [_friendlies, [], { _x distance _pos }, "ASCEND"] call BIS_fnc_sortBy;
    private _nearest = _friendlies select 0;
    _nearestFriendlyDist = round (_nearest distance _pos);
    private _bearing = _pos getDir _nearest;
    _nearestFriendlyDir = [_bearing] call _bearingToCompass;
};

// Find known enemies within enemy radius
private _enemies = _allUnits select {
    private _unitSide = side _x;
    (_playerSide getFriend _unitSide) < 0.6
};

// Filter to only enemies we know about
private _knownEnemies = _enemies select {
    (_playerSide knowsAbout _x) > 0
};
private _knownEnemyCount = count _knownEnemies;

// Find nearest known enemy
private _nearestEnemyDist = -1;
private _nearestEnemyDir = "";
if (_knownEnemyCount > 0) then {
    _knownEnemies = [_knownEnemies, [], { _x distance _pos }, "ASCEND"] call BIS_fnc_sortBy;
    private _nearest = _knownEnemies select 0;
    _nearestEnemyDist = round (_nearest distance _pos);
    private _bearing = _pos getDir _nearest;
    _nearestEnemyDir = [_bearing] call _bearingToCompass;
};

[
    [_friendlyCount, _nearestFriendlyDist, _nearestFriendlyDir],
    [_knownEnemyCount, _nearestEnemyDist, _nearestEnemyDir]
]
