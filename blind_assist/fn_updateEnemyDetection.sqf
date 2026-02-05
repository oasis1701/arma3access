/*
 * fn_updateEnemyDetection.sqf - Per-frame enemy detection update
 *
 * Called every frame, but throttled to 2Hz for performance.
 * Detects newly spotted enemies and announces them via NVDA.
 * Uses nearTargets - only detects enemies the soldier is aware of.
 */

// Throttle to 2Hz (every 0.5 seconds)
if (time - BA_lastEnemyDetectionTime < BA_enemyDetectionInterval) exitWith {};
BA_lastEnemyDetectionTime = time;

// Get the unit to check awareness for (same pattern as Alt+5)
private _unit = if (BA_observerMode) then { BA_observedUnit } else { player };

// Safety check
if (isNull _unit || !alive _unit) exitWith {};

// Get all targets the unit is aware of within 2000m
// nearTargets returns: [perceivedPosition, type, side, subjectiveCost, object, positionAccuracy]
private _allTargets = _unit nearTargets 2000;

// Filter for enemies (subjectiveCost > 0 means enemy threat)
private _enemies = _allTargets select { (_x select 3) > 0 };

// Get all currently detected enemy objects
private _currentEnemyObjects = _enemies apply { _x select 4 };

// Sync tracking list to only include enemies currently in awareness
// This removes enemies who left awareness, allowing re-announcement when they return
BA_detectedEnemies = BA_detectedEnemies select {
    alive _x && {_x in _currentEnemyObjects}
};

// Filter out already-tracked enemies (only announce truly new detections)
private _newEnemies = _enemies select {
    private _enemyObj = _x select 4;
    !isNull _enemyObj && {!(_enemyObj in BA_detectedEnemies)}
};

// Exit if no new enemies
if (count _newEnemies == 0) exitWith {};

// Sort by distance (closest first)
_newEnemies = [_newEnemies, [], {
    _unit distance (_x select 0)
}, "ASCEND"] call BIS_fnc_sortBy;

// Announce each new enemy
{
    private _perceivedPos = _x select 0;
    private _perceivedType = _x select 1;
    private _enemyObj = _x select 4;

    // Calculate distance
    private _distance = round (_unit distance _perceivedPos);

    // Get display name from config
    private _typeName = getText (configFile >> "CfgVehicles" >> _perceivedType >> "displayName");
    if (_typeName == "") then { _typeName = "Unknown" };

    // Calculate bearing and convert to compass direction
    private _bearing = _unit getDir _perceivedPos;
    private _direction = [_bearing] call BA_fnc_bearingToCompass;

    // Announce: "50 meters, Rifleman, northeast"
    [format ["%1 meters, %2, %3", _distance, _typeName, _direction]] call BA_fnc_speak;

    // Track to avoid repeat announcements
    BA_detectedEnemies pushBack _enemyObj;

} forEach _newEnemies;
