/*
 * Function: BA_fnc_updateDirectionSnap
 * Per-frame update for smooth direction interpolation.
 * Called by EachFrame handler during direction snap.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_updateDirectionSnap;
 */

// Check if interpolation is active
if (!BA_dirSnapEnabled) exitWith {};

// Calculate elapsed time and progress (0.0 to 1.0)
private _elapsed = diag_tickTime - BA_dirSnapStartTime;
private _progress = _elapsed / BA_dirSnapDuration;

// Clamp progress to 0-1 range
if (_progress > 1) then { _progress = 1 };

// Calculate shortest angle difference (handles wraparound)
private _diff = BA_dirSnapTarget - BA_dirSnapStart;
if (_diff > 180) then { _diff = _diff - 360 };
if (_diff < -180) then { _diff = _diff + 360 };

// Smoothstep interpolation (eases in and out for natural feel)
private _smooth = _progress * _progress * (3 - 2 * _progress);

// Calculate interpolated direction
private _currentDir = BA_dirSnapStart + (_diff * _smooth);

// Normalize to 0-360 range
if (_currentDir < 0) then { _currentDir = _currentDir + 360 };
if (_currentDir >= 360) then { _currentDir = _currentDir - 360 };

// Apply direction and level view
player setDir _currentDir;
// setVectorDir with Z=0 forces view to horizon (no pitch up/down)
player setVectorDir [sin _currentDir, cos _currentDir, 0];

// Check if interpolation is complete
if (_progress >= 1) then {
    // Set exact final direction
    player setDir BA_dirSnapTarget;
    player setVectorDir [sin BA_dirSnapTarget, cos BA_dirSnapTarget, 0];

    // Clean up
    BA_dirSnapEnabled = false;
    if (BA_dirSnapEHId != -1) then {
        removeMissionEventHandler ["EachFrame", BA_dirSnapEHId];
        BA_dirSnapEHId = -1;
    };
};
