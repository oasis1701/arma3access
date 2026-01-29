/*
 * Function: BA_fnc_bearingToCompass
 * Converts a bearing in degrees to a compass direction.
 *
 * Arguments:
 *   0: _bearing - Bearing in degrees (0-360)
 *
 * Return Value:
 *   String - Compass direction (north, northeast, east, etc.)
 *
 * Example:
 *   [45] call BA_fnc_bearingToCompass;
 *   // Returns: "northeast"
 */

params [["_bearing", 0, [0]]];

// Normalize bearing to 0-360
_bearing = _bearing mod 360;
if (_bearing < 0) then { _bearing = _bearing + 360 };

// Convert to compass direction (8 cardinal/intercardinal directions)
switch (true) do {
    case (_bearing >= 337.5 || _bearing < 22.5): { "north" };
    case (_bearing >= 22.5 && _bearing < 67.5): { "northeast" };
    case (_bearing >= 67.5 && _bearing < 112.5): { "east" };
    case (_bearing >= 112.5 && _bearing < 157.5): { "southeast" };
    case (_bearing >= 157.5 && _bearing < 202.5): { "south" };
    case (_bearing >= 202.5 && _bearing < 247.5): { "southwest" };
    case (_bearing >= 247.5 && _bearing < 292.5): { "west" };
    case (_bearing >= 292.5 && _bearing < 337.5): { "northwest" };
    default { "north" };
}
