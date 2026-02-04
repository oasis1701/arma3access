/*
 * Function: BA_fnc_getSlopeInfo
 * Gets the slope description at a position by sampling nearby terrain.
 *
 * Arguments:
 *   0: _pos - Position to check (default: BA_cursorPos)
 *
 * Return Value:
 *   String - Slope description ("Flat", "Gentle slope", "Steep slope", "Cliff")
 *
 * Example:
 *   private _slope = [BA_cursorPos] call BA_fnc_getSlopeInfo;
 */

params [
    ["_pos", [], [[]]]
];

// Use cursor position if none provided
if (count _pos == 0) then {
    _pos = BA_cursorPos;
};

private _x = _pos select 0;
private _y = _pos select 1;

// Sample terrain height at 4 points (5m in each cardinal direction)
private _sampleDist = 5;
private _centerHeight = getTerrainHeightASL [_x, _y];
private _northHeight = getTerrainHeightASL [_x, _y + _sampleDist];
private _southHeight = getTerrainHeightASL [_x, _y - _sampleDist];
private _eastHeight = getTerrainHeightASL [_x + _sampleDist, _y];
private _westHeight = getTerrainHeightASL [_x - _sampleDist, _y];

// Calculate height differences from center
private _diffs = [
    abs(_northHeight - _centerHeight),
    abs(_southHeight - _centerHeight),
    abs(_eastHeight - _centerHeight),
    abs(_westHeight - _centerHeight)
];

// Get maximum difference
private _maxDiff = selectMax _diffs;

// Categorize slope based on max height difference over 5m distance
// 0-2m difference = Flat (0-22 degree slope)
// 2-5m difference = Gentle slope (22-45 degree slope)
// 5-10m difference = Steep slope (45-63 degree slope)
// 10m+ difference = Cliff (63+ degree slope)

if (_maxDiff < 2) exitWith { "Flat" };
if (_maxDiff < 5) exitWith { "Gentle slope" };
if (_maxDiff < 10) exitWith { "Steep slope" };
"Cliff"
