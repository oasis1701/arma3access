/*
 * Function: BA_fnc_navigateIntersectionMenu
 * Navigates up/down in the intersection menu.
 *
 * Arguments:
 *   0: _delta - Direction to move: 1 for down/next, -1 for up/previous
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [1] call BA_fnc_navigateIntersectionMenu;  // Next item
 *   [-1] call BA_fnc_navigateIntersectionMenu; // Previous item
 */

params [
    ["_delta", 1, [0]]
];

if (!BA_intersectionMenuActive) exitWith {};

private _count = count BA_intersectionMenuItems;
if (_count == 0) exitWith {};

// Update index with wrapping
BA_intersectionMenuIndex = BA_intersectionMenuIndex + _delta;
if (BA_intersectionMenuIndex < 0) then {
    BA_intersectionMenuIndex = _count - 1;
};
if (BA_intersectionMenuIndex >= _count) then {
    BA_intersectionMenuIndex = 0;
};

// Get current item and announce
private _item = BA_intersectionMenuItems select BA_intersectionMenuIndex;
_item params ["_road", "_dir", "_type", "_len", "_dest"];

private _announcement = format ["%1: %2, %3, %4 meters, %5.",
    BA_intersectionMenuIndex + 1, _dir, _type, _len, _dest];
[_announcement] call BA_fnc_speak;
