/*
 * Function: BA_fnc_getBearingDistance
 * Gets bearing and distance from the observed unit to the cursor position.
 *
 * Arguments:
 *   0: _pos - Target position (default: BA_cursorPos)
 *
 * Return Value:
 *   String - Bearing and distance (e.g., "320 meters northeast")
 *
 * Example:
 *   private _info = [BA_cursorPos] call BA_fnc_getBearingDistance;
 */

params [
    ["_pos", [], [[]]]
];

// Use cursor position if none provided
if (count _pos == 0) then {
    _pos = BA_cursorPos;
};

// Need observed unit as reference point
if (isNull BA_observedUnit) exitWith { "Unknown bearing" };

private _unitPos = getPos BA_observedUnit;

// Calculate distance
private _distance = round (_unitPos distance2D _pos);

// If at same position, return early
if (_distance < 1) exitWith { "At observed unit" };

// Calculate bearing from unit to cursor
private _bearing = _unitPos getDir _pos;
_bearing = round _bearing;

// Convert bearing to compass direction
private _compassDir = switch (true) do {
    case (_bearing >= 337.5 || _bearing < 22.5): { "north" };
    case (_bearing >= 22.5 && _bearing < 67.5): { "northeast" };
    case (_bearing >= 67.5 && _bearing < 112.5): { "east" };
    case (_bearing >= 112.5 && _bearing < 157.5): { "southeast" };
    case (_bearing >= 157.5 && _bearing < 202.5): { "south" };
    case (_bearing >= 202.5 && _bearing < 247.5): { "southwest" };
    case (_bearing >= 247.5 && _bearing < 292.5): { "west" };
    case (_bearing >= 292.5 && _bearing < 337.5): { "northwest" };
    default { "unknown direction" };
};

format["%1 meters %2 of observed unit", _distance, _compassDir]
