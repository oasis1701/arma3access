/*
 * Function: BA_fnc_closeGroupMenu
 * Closes the group selection menu without making a selection.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_closeGroupMenu;
 */

if (!BA_groupMenuActive) exitWith {};

BA_groupMenuActive = false;
BA_groupMenuItems = [];
BA_groupMenuIndex = 0;

["Group selection cancelled."] call BA_fnc_speak;

systemChat "Group Menu closed";
