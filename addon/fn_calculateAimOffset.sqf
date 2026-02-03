/*
 * Function: BA_fnc_calculateAimOffset
 * Calculates the audio parameters for two-tone precision aim assist.
 *
 * Algorithm:
 * 1. Get soldier's weapon direction
 * 2. Get direction to target center mass
 * 3. Check if target is behind (dot product < 0) -> mute
 * 4. Calculate horizontal offset -> pan (-1 to +1)
 * 5. Calculate vertical offset -> pitch (300-800 Hz, 550 = centered)
 * 6. Calculate vertical error (0-1, 0 = centered) for pulse rate
 * 7. Calculate horizontal error (0-1, 0 = centered) for click rate
 *
 * Arguments:
 *   0: Object - The soldier doing the aiming
 *   1: Object - The target enemy
 *
 * Return Value:
 *   Array - [pan, pitch, vertError, horizError, vertThreshold, horizThreshold]
 *   Thresholds are adaptive based on target angular size at distance
 *
 * Example:
 *   private _params = [player, _enemy] call BA_fnc_calculateAimOffset;
 */

params [["_soldier", objNull, [objNull]], ["_target", objNull, [objNull]]];

// Return mute signal if invalid inputs
if (isNull _soldier || isNull _target || !alive _soldier || !alive _target) exitWith {
    [0, -1, 1, 1, 0.02, 0.005]  // pitch -1 = mute signal, max errors, default thresholds
};

// Get aim direction - use weapon barrel direction (where bullet actually goes)
private _weapon = currentWeapon _soldier;
private _aimDir = if (_weapon != "") then {
    _soldier weaponDirection _weapon
} else {
    vectorDir _soldier
};

// Normalize aim direction (should already be, but be safe)
private _aimDirNorm = vectorNormalized _aimDir;

// Get origin point (eye position)
private _eyePos = eyePos _soldier;
private _targetPos = if (_target isKindOf "Man") then {
    // Calculate vertical center of body (between head and feet)
    // This ensures the threshold extends equally to head and feet
    private _headPos = _target selectionPosition "head";
    private _footPos = _target selectionPosition "leftfoot";

    if !(_headPos isEqualTo [0,0,0] || _footPos isEqualTo [0,0,0]) then {
        // Center point between head and feet in model space
        private _centerZ = ((_headPos select 2) + (_footPos select 2)) / 2;
        private _centerPos = [0, 0, _centerZ];
        AGLToASL (_target modelToWorldVisual _centerPos)
    } else {
        // Fallback to spine3 if selections don't exist
        private _spinePos = _target selectionPosition "spine3";
        if (_spinePos isEqualTo [0,0,0]) then {
            (getPosASL _target) vectorAdd [0, 0, 0.9]
        } else {
            AGLToASL (_target modelToWorldVisual _spinePos)
        }
    }
} else {
    getPosASL _target  // Vehicle center
};

// Vector from soldier to target
private _toTarget = _targetPos vectorDiff _eyePos;
private _toTargetNorm = vectorNormalized _toTarget;
private _distance = vectorMagnitude _toTarget;

// Calculate target's angular size for adaptive thresholds
// Use realistic hit radii, not bounding box (which includes gear/backpacks)
private _horizRadius = 0.0;
private _vertRadius = 0.0;

if (_target isKindOf "Man") then {
    // Infantry: calculate actual body coverage from skeleton positions

    // Horizontal: calculate from actual shoulder width
    private _leftShoulder = _target selectionPosition "leftshoulder";
    private _rightShoulder = _target selectionPosition "rightshoulder";

    if !(_leftShoulder isEqualTo [0,0,0] || _rightShoulder isEqualTo [0,0,0]) then {
        // Calculate actual shoulder width
        private _shoulderWidth = vectorMagnitude (_rightShoulder vectorDiff _leftShoulder);
        _horizRadius = _shoulderWidth / 2;
    } else {
        // Fallback
        _horizRadius = 0.2;
    };

    // Vertical: half the body height (since we target the center)
    private _headPos = _target selectionPosition "head";
    private _footPos = _target selectionPosition "leftfoot";

    if !(_headPos isEqualTo [0,0,0] || _footPos isEqualTo [0,0,0]) then {
        // Half the body height = radius from center to head/feet
        private _bodyHeight = abs((_headPos select 2) - (_footPos select 2));
        _vertRadius = _bodyHeight / 2;
    } else {
        // Fallback if selections don't exist on this model
        _vertRadius = 0.9;
    };
} else {
    // Vehicles: use bounding box but scaled down (60% to account for non-hittable parts)
    private _bb = boundingBoxReal _target;
    private _dims = (_bb select 1) vectorDiff (_bb select 0);
    _horizRadius = (((_dims select 0) max (_dims select 1)) / 2) * 0.6;
    _vertRadius = ((_dims select 2) / 2) * 0.6;
};

// Convert to threshold values that match how errors are calculated
// horizError = sin(angle), so: horizThreshold = sin(atan(radius/dist)) = radius/sqrt(dist²+radius²)
// vertError = elevDiff/45, so: vertThreshold = atan(radius/dist)/45
private _distSq = _distance * _distance;
private _horizThreshold = _horizRadius / sqrt(_distSq + _horizRadius * _horizRadius);
private _vertThreshold = (atan (_vertRadius / (_distance max 1))) / 45;

// Minimum thresholds (for very far targets)
_horizThreshold = _horizThreshold max 0.003;
_vertThreshold = _vertThreshold max 0.005;

// CRITICAL: Check if target is behind using dot product
// dot < 0 means target is more than 90 degrees away (behind)
private _dotProduct = _aimDirNorm vectorDotProduct _toTargetNorm;

if (_dotProduct < 0) exitWith {
    // Target is behind the soldier - mute to prevent confusing left/right flip
    [0, -1, 1, 1, 0.02, 0.005]  // pitch -1 = mute signal, max errors, default thresholds
};

// ============================================================================
// Calculate horizontal offset (pan)
// ============================================================================
// Use cross product projected to XY plane to determine left/right
// Cross product gives perpendicular vector; its Z component tells us the rotation direction

// Get XY components only for horizontal calculation
private _aimXY = [_aimDirNorm select 0, _aimDirNorm select 1, 0];
private _targetXY = [_toTargetNorm select 0, _toTargetNorm select 1, 0];

// Normalize XY vectors
_aimXY = vectorNormalized _aimXY;
_targetXY = vectorNormalized _targetXY;

// Cross product Z component: positive = target is to the right, negative = to the left
private _crossZ = ((_aimXY select 0) * (_targetXY select 1)) - ((_aimXY select 1) * (_targetXY select 0));

// Dot product in XY plane gives angle magnitude (1 = aligned, 0 = 90 degrees)
private _dotXY = _aimXY vectorDotProduct _targetXY;

// Convert to pan value: -1 (full left) to +1 (full right)
// Use arcsin of cross product for angle, scaled to -1..1 range
// crossZ is already in -1..1 range (sine of angle)
// Negate so enemy on right = sound in right ear
private _pan = -_crossZ;

// Clamp pan
_pan = (_pan max -1) min 1;

// ============================================================================
// Calculate vertical offset (pitch frequency)
// ============================================================================
// Compare elevation angles of aim direction vs target direction

// Elevation angle of aim direction (radians)
private _aimElevation = asin (_aimDirNorm select 2);  // Returns degrees

// Elevation angle to target
private _targetElevation = asin (_toTargetNorm select 2);

// Difference: positive = aim is above target (too high), negative = aim is below target (too low)
// Aim too high = high pitch (lower your aim), aim too low = low pitch (raise your aim)
private _elevDiff = _aimElevation - _targetElevation;

// Map to pitch: 550 Hz = level, +250 for 45 degrees up, -250 for 45 degrees down
// Range: 300 Hz (target far below) to 800 Hz (target far above)
private _pitch = 550 + (_elevDiff / 45 * 250);

// Clamp pitch to valid range
_pitch = (_pitch max 300) min 800;

// ============================================================================
// Calculate error values for two-tone precision feedback
// ============================================================================

// Vertical error: how far pitch is from center (550 Hz)
// Range: 0 (dead center) to 1 (max error at 300 or 800 Hz)
private _vertError = (abs (_pitch - 550)) / 250;
_vertError = (_vertError max 0) min 1;

// Horizontal error: how far pan is from center (0)
// Range: 0 (dead center) to 1 (max error at -1 or +1)
private _horizError = abs _pan;
_horizError = (_horizError max 0) min 1;

// Return parameters with adaptive thresholds
[_pan, _pitch, _vertError, _horizError, _vertThreshold, _horizThreshold]
