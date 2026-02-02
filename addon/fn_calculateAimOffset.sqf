/*
 * Function: BA_fnc_calculateAimOffset
 * Calculates the audio parameters (pan, pitch, locked) for aim assist.
 *
 * Algorithm:
 * 1. Get soldier's weapon direction
 * 2. Get direction to target center mass
 * 3. Check if target is behind (dot product < 0) -> mute
 * 4. Calculate horizontal offset -> pan (-1 to +1)
 * 5. Calculate vertical offset -> pitch (300-800 Hz)
 * 6. Check if locked (angular error < threshold)
 *
 * Arguments:
 *   0: Object - The soldier doing the aiming
 *   1: Object - The target enemy
 *
 * Return Value:
 *   Array - [pan, pitch, locked] or [-1, -1, 0] if should mute
 *
 * Example:
 *   private _params = [player, _enemy] call BA_fnc_calculateAimOffset;
 */

params [["_soldier", objNull, [objNull]], ["_target", objNull, [objNull]]];

// Return mute signal if invalid inputs
if (isNull _soldier || isNull _target || !alive _soldier || !alive _target) exitWith {
    [0, -1, 0]  // pitch -1 = mute signal
};

// Get soldier's current aim direction (weapon direction)
private _weapon = currentWeapon _soldier;
private _aimDir = if (_weapon != "") then {
    _soldier weaponDirection _weapon
} else {
    // No weapon - use facing direction
    vectorDir _soldier
};

// Normalize aim direction (should already be, but be safe)
private _aimDirNorm = vectorNormalized _aimDir;

// Get target position (center mass)
private _eyePos = eyePos _soldier;
private _targetPos = if (_target isKindOf "Man") then {
    (getPosASL _target) vectorAdd [0, 0, 1.2]  // Torso height
} else {
    getPosASL _target  // Vehicle center
};

// Vector from soldier to target
private _toTarget = _targetPos vectorDiff _eyePos;
private _toTargetNorm = vectorNormalized _toTarget;
private _distance = vectorMagnitude _toTarget;

// CRITICAL: Check if target is behind using dot product
// dot < 0 means target is more than 90 degrees away (behind)
private _dotProduct = _aimDirNorm vectorDotProduct _toTargetNorm;

if (_dotProduct < 0) exitWith {
    // Target is behind the soldier - mute to prevent confusing left/right flip
    [0, -1, 0]
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
// Calculate lock status
// ============================================================================
// Total angular error between aim and target

// Full 3D dot product gives cosine of angle
// _dotProduct already calculated above

// Angle in degrees
private _angleError = acos (_dotProduct min 1);  // Clamp to handle floating point errors

// Adjust lock threshold based on target size at distance
// Larger targets (vehicles) or closer targets have larger apparent size
private _targetSize = if (_target isKindOf "Man") then { 1.8 } else {
    // Estimate vehicle size from bounding box
    private _bb = boundingBoxReal _target;
    private _dims = (_bb select 1) vectorDiff (_bb select 0);
    ((_dims select 0) max (_dims select 1) max (_dims select 2)) * 0.5
};

// Angular size of target in degrees: atan(size / distance)
private _targetAngularSize = atan (_targetSize / (_distance max 1));

// Lock threshold: base angle or target angular size, whichever is larger
private _lockThreshold = BA_aimAssistLockAngle max _targetAngularSize;

// Locked if within threshold
private _locked = if (_angleError <= _lockThreshold) then { 1 } else { 0 };

// Return parameters
[_pan, _pitch, _locked]
