/*
 * fn_updateSpottingAssist.sqf - Per-frame spotting assist update
 *
 * Called every frame, throttled to 2Hz.
 * Scans the soldier's forward cone for hostile units, checks LOS,
 * and reveals them so nearTargets/aim assist/enemy detection work.
 */

// Throttle to 2Hz
if (time - BA_lastSpottingTime < BA_spottingInterval) exitWith {};
BA_lastSpottingTime = time;

// Get the acting unit (observer mode or direct control)
private _unit = if (BA_observerMode) then { BA_originalUnit } else { player };

// Safety check
if (isNull _unit || !alive _unit) exitWith {};

private _unitSide = side _unit;
private _unitDir = getDir _unit;
private _eyePos = eyePos _unit;
private _halfFOV = BA_spottingFOV / 2;

// Spatial scan - all potential entities in range
private _entities = _unit nearEntities [["Man", "Car", "Tank", "Helicopter", "Plane"], BA_spottingRange];

{
    private _entity = _x;

    // Skip self
    if (_entity == _unit) then { continue };

    // Skip dead
    if (!alive _entity) then { continue };

    // Hostile filter (getFriend < 0.6 = enemy)
    if (_unitSide getFriend (side _entity) >= 0.6) then { continue };

    // Skip already known (no need to re-reveal)
    if (_unit knowsAbout _entity >= 1.5) then { continue };

    // Forward-facing cone filter
    private _dirToEntity = _unit getDir _entity;
    private _angleDiff = _dirToEntity - _unitDir;
    // Normalize to -180..180
    if (_angleDiff > 180) then { _angleDiff = _angleDiff - 360 };
    if (_angleDiff < -180) then { _angleDiff = _angleDiff + 360 };
    if (abs _angleDiff > _halfFOV) then { continue };

    // Multi-ray LOS check
    private _hasLOS = false;

    if (_entity isKindOf "Man") then {
        // Infantry: 5-ray skeleton check
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
            private _centerZ = ((_headPos select 2) + (_footPos select 2)) / 2;
            [
                AGLToASL (_entity modelToWorldVisual _headPos),
                AGLToASL (_entity modelToWorldVisual _leftShoulderPos),
                AGLToASL (_entity modelToWorldVisual _rightShoulderPos),
                AGLToASL (_entity modelToWorldVisual [0, 0, _centerZ]),
                AGLToASL (_entity modelToWorldVisual _footPos)
            ]
        } else {
            // Fallback hardcoded offsets
            private _basePos = getPosASL _entity;
            [
                _basePos vectorAdd [0, 0, 1.7],
                _basePos vectorAdd [0, 0, 1.2],
                _basePos vectorAdd [0, 0, 0.5]
            ]
        };

        {
            private _intersections = lineIntersectsSurfaces [
                _eyePos, _x, _unit, _entity, true, 1
            ];
            if (count _intersections == 0) exitWith {
                _hasLOS = true;
            };
        } forEach _rays;
    } else {
        // Vehicles: single center-point ray
        private _targetPos = (getPosASL _entity) vectorAdd [0, 0, ((_entity selectionPosition "") select 2) max 0.5];
        private _intersections = lineIntersectsSurfaces [
            _eyePos, _targetPos, _unit, _entity, true, 1
        ];
        _hasLOS = count _intersections == 0;
    };

    // Reveal to player's unit
    if (_hasLOS) then {
        _unit reveal [_entity, 1.5];
    };

} forEach _entities;
