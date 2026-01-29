/*
 * Function: BA_fnc_announceMovement
 * Announces cursor movement direction and distance.
 *
 * Arguments:
 *   0: _direction - Direction moved ("North", "South", "East", "West")
 *   1: _distance - Distance in meters
 *
 * Return Value:
 *   None
 *
 * Example:
 *   ["North", 100] call BA_fnc_announceMovement;
 *   // Speaks: "North, 100 meters"
 */

params [
    ["_direction", "", [""]],
    ["_distance", 0, [0]]
];

private _announcement = format["%1, %2 meters.", _direction, _distance];

[_announcement] call BA_fnc_speak;
