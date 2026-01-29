/*
 * Function: BA_fnc_moveCursor
 * Moves the cursor in a cardinal direction by a specified distance.
 * Announces the movement and new position.
 *
 * Arguments:
 *   0: _direction - "North", "South", "East", or "West"
 *   1: _distance - Distance in meters
 *
 * Return Value:
 *   Boolean - true if cursor was moved
 *
 * Example:
 *   ["North", 100] call BA_fnc_moveCursor;
 */

params [
    ["_direction", "", [""]],
    ["_distance", 0, [0]]
];

// Must be in observer mode with active cursor
if (!BA_observerMode || !BA_cursorActive) exitWith {
    ["Cursor not active."] call BA_fnc_speak;
    false
};

// Validate direction
if !(_direction in ["North", "South", "East", "West"]) exitWith {
    false
};

// Calculate offset based on direction
// In Arma 3: +X = East, +Y = North
private _offset = switch (_direction) do {
    case "North": { [0, _distance] };
    case "South": { [0, -_distance] };
    case "East":  { [_distance, 0] };
    case "West":  { [-_distance, 0] };
    default { [0, 0] };
};

// Calculate new position
private _newX = (BA_cursorPos select 0) + (_offset select 0);
private _newY = (BA_cursorPos select 1) + (_offset select 1);

// Clamp to map boundaries
private _mapSize = worldSize;
private _clampedX = 0 max _newX min _mapSize;
private _clampedY = 0 max _newY min _mapSize;

// Check if we hit a boundary
private _hitBoundary = (_newX != _clampedX) || (_newY != _clampedY);

// Get terrain height at new position
private _z = getTerrainHeightASL [_clampedX, _clampedY];

// Update cursor position
BA_cursorPos = [_clampedX, _clampedY, _z];

// Announce position info (terrain, altitude, grid)
[] call BA_fnc_announceCursorBrief;

// Warn if hit boundary
if (_hitBoundary) then {
    ["Map boundary."] call BA_fnc_speak;
};

true
