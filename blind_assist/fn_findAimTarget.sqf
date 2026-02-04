/*
 * Function: BA_fnc_findAimTarget
 * Finds the nearest visible enemy for aim assist targeting.
 *
 * Target acquisition rules:
 * 1. Search nearEntities within max range for Man/Car/Tank/Helicopter/Plane
 * 2. Filter to hostile side (getFriend < 0.6) and known (knowsAbout > threshold)
 * 3. Sort by distance (nearest first)
 * 4. Check line of sight - first enemy with clear LOS becomes target
 *
 * Arguments:
 *   0: Object - The soldier doing the aiming
 *
 * Return Value:
 *   Object - The target enemy, or objNull if none found
 *
 * Example:
 *   private _target = [player] call BA_fnc_findAimTarget;
 */

params [["_soldier", objNull, [objNull]]];

if (isNull _soldier || !alive _soldier) exitWith { objNull };

// Get soldier's eye position for LOS checks
private _eyePos = eyePos _soldier;
private _soldierSide = side _soldier;

// Find all potential targets within range
private _candidates = _soldier nearEntities [["Man", "Car", "Tank", "Helicopter", "Plane"], BA_aimAssistMaxRange];

// Filter and sort candidates
private _validTargets = [];

{
    private _entity = _x;

    // Skip self
    if (_entity == _soldier) then { continue };

    // Skip dead
    if (!alive _entity) then { continue };

    // Check if hostile (getFriend returns 0-1, < 0.6 means hostile)
    private _entitySide = side _entity;
    if (_soldierSide getFriend _entitySide >= 0.6) then { continue };

    // Check if soldier knows about this enemy (knowsAbout returns 0-4)
    private _knowledge = _soldier knowsAbout _entity;
    if (_knowledge < BA_aimAssistMinKnowledge) then { continue };

    // Get distance for sorting
    private _dist = _soldier distance _entity;

    // Add to candidates list with distance for sorting
    _validTargets pushBack [_dist, _entity];

} forEach _candidates;

// Sort by distance (nearest first)
_validTargets sort true;

// Find first target with clear line of sight
private _result = objNull;

{
    _x params ["_dist", "_entity"];

    // Get target center mass (slightly elevated for standing units)
    private _targetPos = if (_entity isKindOf "Man") then {
        // Aim at torso, not feet
        (getPosASL _entity) vectorAdd [0, 0, 1.2]
    } else {
        // For vehicles, aim at center
        (getPosASL _entity) vectorAdd [0, 0, ((_entity selectionPosition "") select 2) max 0.5]
    };

    // Check line of sight using lineIntersectsSurfaces
    // Returns array of intersections, empty = clear LOS
    private _intersections = lineIntersectsSurfaces [
        _eyePos,           // Start position (soldier's eyes)
        _targetPos,        // End position (target center mass)
        _soldier,          // Ignore soldier
        _entity,           // Ignore target
        true,              // Sort results
        1                  // Max results (we only care if there's ANY obstruction)
    ];

    if (count _intersections == 0) exitWith {
        // Clear line of sight - this is our target
        _result = _entity;
    };

} forEach _validTargets;

_result
