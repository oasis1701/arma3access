/*
 * Function: BA_fnc_findAimTarget
 * Finds the nearest visible enemy for aim assist targeting.
 *
 * Target acquisition rules:
 * 1. If _currentTarget is provided and still valid, check only that target (stickiness)
 * 2. Otherwise search nearEntities within max range for Man/Car/Tank/Helicopter/Plane
 * 3. Filter to hostile side (getFriend < 0.6) and known (knowsAbout > threshold)
 * 4. Sort by distance (nearest first)
 * 5. Skeleton-based multi-ray LOS for infantry (head/shoulders/center/feet), single ray for vehicles
 * 6. First enemy with clear LOS becomes target
 *
 * Arguments:
 *   0: Object - The soldier doing the aiming
 *   1: Object - (Optional) Current target for stickiness check (default objNull)
 *
 * Return Value:
 *   Array - [target, hasLOS] where target is objNull if none found
 *
 * Example:
 *   private _result = [player] call BA_fnc_findAimTarget;
 *   _result params ["_target", "_hasLOS"];
 *
 *   // Sticky check:
 *   private _result = [player, BA_aimAssistTarget] call BA_fnc_findAimTarget;
 */

params [["_soldier", objNull, [objNull]], ["_currentTarget", objNull, [objNull]]];

if (isNull _soldier || !alive _soldier) exitWith { [objNull, false] };

// Get soldier's eye position for LOS checks
private _eyePos = eyePos _soldier;
private _soldierSide = side _soldier;

// --- Helper: multi-ray LOS check ---
// Returns true if any ray from _eyePos to _entity has clear LOS
private _fnc_checkLOS = {
    params ["_eyePos", "_entity", "_soldier"];

    if (_entity isKindOf "Man") then {
        // Infantry: check 5 rays using skeleton positions (adapts to stance)
        private _headPos = _entity selectionPosition "head";
        private _footPos = _entity selectionPosition "leftfoot";
        private _leftShoulderPos = _entity selectionPosition "leftshoulder";
        private _rightShoulderPos = _entity selectionPosition "rightshoulder";

        private _rays = if !(
            _headPos isEqualTo [0,0,0]
            || _footPos isEqualTo [0,0,0]
            || _leftShoulderPos isEqualTo [0,0,0]
            || _rightShoulderPos isEqualTo [0,0,0]
        ) then {
            // Skeleton selections available - build rays from real positions
            private _centerZ = ((_headPos select 2) + (_footPos select 2)) / 2;
            [
                AGLToASL (_entity modelToWorldVisual _headPos),            // Head
                AGLToASL (_entity modelToWorldVisual _leftShoulderPos),    // Left shoulder
                AGLToASL (_entity modelToWorldVisual _rightShoulderPos),   // Right shoulder
                AGLToASL (_entity modelToWorldVisual [0, 0, _centerZ]),    // Center mass
                AGLToASL (_entity modelToWorldVisual _footPos)             // Feet
            ]
        } else {
            // Fallback: model lacks skeleton selections, use hardcoded offsets
            private _basePos = getPosASL _entity;
            [
                _basePos vectorAdd [0, 0, 1.7],
                _basePos vectorAdd [0, 0, 1.2],
                _basePos vectorAdd [0, 0, 0.5]
            ]
        };

        private _hasLOS = false;
        {
            private _intersections = lineIntersectsSurfaces [
                _eyePos, _x, _soldier, _entity, true, 1
            ];
            if (count _intersections == 0) exitWith {
                _hasLOS = true;
            };
        } forEach _rays;

        _hasLOS
    } else {
        // Vehicles: single center-point ray
        private _targetPos = (getPosASL _entity) vectorAdd [0, 0, ((_entity selectionPosition "") select 2) max 0.5];
        private _intersections = lineIntersectsSurfaces [
            _eyePos, _targetPos, _soldier, _entity, true, 1
        ];
        count _intersections == 0
    };
};

// --- Sticky target check ---
// If we have a current target, check if it's still valid before doing a full scan
if (!isNull _currentTarget) then {
    if (alive _currentTarget
        && {_soldierSide getFriend (side _currentTarget) < 0.6}
        && {_soldier knowsAbout _currentTarget >= BA_aimAssistMinKnowledge}
        && {_soldier distance _currentTarget <= BA_aimAssistMaxRange}
    ) exitWith {
        // Target still valid - check LOS with multi-ray
        private _hasLOS = [_eyePos, _currentTarget, _soldier] call _fnc_checkLOS;
        [_currentTarget, _hasLOS]
    };
    // Current target invalid - fall through to full scan
};

// --- Full scan ---
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
private _result = [objNull, false];

{
    _x params ["_dist", "_entity"];

    private _hasLOS = [_eyePos, _entity, _soldier] call _fnc_checkLOS;

    if (_hasLOS) exitWith {
        _result = [_entity, true];
    };

} forEach _validTargets;

_result
