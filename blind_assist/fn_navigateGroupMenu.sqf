/*
 * Function: BA_fnc_navigateGroupMenu
 * Navigates up or down in the group selection menu.
 *
 * Arguments:
 *   0: Direction <NUMBER> - 1 for down/next, -1 for up/previous
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [1] call BA_fnc_navigateGroupMenu;   // Down/next
 *   [-1] call BA_fnc_navigateGroupMenu;  // Up/previous
 */

params [["_direction", 1, [0]]];

if (!BA_groupMenuActive) exitWith {};

private _count = count BA_groupMenuItems;
if (_count == 0) exitWith {};

// Update index with wraparound
BA_groupMenuIndex = (BA_groupMenuIndex + _direction + _count) mod _count;

// Get current group info
private _currentGroup = BA_groupMenuItems select BA_groupMenuIndex;
private _groupInfo = [_currentGroup] call BA_fnc_getGroupDescription;

// Announce position and group
private _announcement = format["%1 of %2. %3.", BA_groupMenuIndex + 1, _count, _groupInfo];

[_announcement] call BA_fnc_speak;
