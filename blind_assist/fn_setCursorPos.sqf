/*
 * Function: BA_fnc_setCursorPos
 * Sets the cursor to an absolute position.
 *
 * Arguments:
 *   0: _pos - Position to set cursor to [x, y] or [x, y, z]
 *   1: _announce - Whether to announce the new position (default: false)
 *
 * Return Value:
 *   Boolean - true if position was set
 *
 * Example:
 *   [getPos player, true] call BA_fnc_setCursorPos;
 */

params [
    ["_pos", [0, 0, 0], [[]]],
    ["_announce", false, [false]]
];

// Validate position
if (count _pos < 2) exitWith { false };

// Get terrain height at position for Z coordinate
private _x = _pos select 0;
private _y = _pos select 1;
private _z = getTerrainHeightASL [_x, _y];

// Clamp to map boundaries
private _mapSize = worldSize;
_x = 0 max _x min _mapSize;
_y = 0 max _y min _mapSize;

// Set cursor position
BA_cursorPos = [_x, _y, _z];

// Announce if requested
if (_announce) then {
    [] call BA_fnc_announceCursorBrief;
};

true
