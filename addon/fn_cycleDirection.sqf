/*
 * Function: BA_fnc_cycleDirection
 * Cycles the player's direction to the next cardinal compass direction.
 * Uses smooth interpolation over 0.15 seconds.
 * Only works when NOT in Observer Mode or Focus Mode.
 *
 * Hotkeys:
 *   Delete (211)    - Cycle counter-clockwise (left)
 *   Page Down (209) - Cycle clockwise (right)
 *
 * Arguments:
 *   0: _clockwise - true for clockwise (right), false for counter-clockwise (left)
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [true] call BA_fnc_cycleDirection;   // Next direction clockwise
 *   [false] call BA_fnc_cycleDirection;  // Next direction counter-clockwise
 */

params [["_clockwise", true, [true]]];

// 8 cardinal directions in order (clockwise from North)
private _directions = [0, 45, 90, 135, 180, 225, 270, 315];

// Get current player direction
private _currentDir = getDir player;

// Find closest cardinal direction
private _closestIndex = 0;
private _minDiff = 360;
{
    private _diff = abs(_currentDir - _x);
    if (_diff > 180) then { _diff = 360 - _diff };
    if (_diff < _minDiff) then {
        _minDiff = _diff;
        _closestIndex = _forEachIndex;
    };
} forEach _directions;

// Calculate target index (next direction in chosen rotation)
private _targetIndex = if (_clockwise) then {
    // Clockwise: 0 -> 1 -> 2 -> ... -> 7 -> 0
    (_closestIndex + 1) mod 8
} else {
    // Counter-clockwise: 0 -> 7 -> 6 -> ... -> 1 -> 0
    (_closestIndex + 7) mod 8
};

private _targetDir = _directions select _targetIndex;

// If already interpolating, cancel previous handler
if (BA_dirSnapEnabled && BA_dirSnapEHId != -1) then {
    removeMissionEventHandler ["EachFrame", BA_dirSnapEHId];
    BA_dirSnapEHId = -1;
};

// Set up interpolation state
BA_dirSnapStart = _currentDir;
BA_dirSnapTarget = _targetDir;
BA_dirSnapStartTime = diag_tickTime;
BA_dirSnapEnabled = true;

// Start EachFrame handler for smooth interpolation
BA_dirSnapEHId = addMissionEventHandler ["EachFrame", {
    [] call BA_fnc_updateDirectionSnap;
}];

// Announce target direction
private _dirName = [_targetDir] call BA_fnc_bearingToCompass;
[_dirName] call BA_fnc_speak;
