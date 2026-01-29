/*
 * Function: BA_fnc_closeIntersectionMenu
 * Closes the intersection menu without selecting a road.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_closeIntersectionMenu;
 */

if (!BA_intersectionMenuActive) exitWith {};

BA_intersectionMenuActive = false;
BA_intersectionMenuItems = [];
BA_intersectionMenuIndex = 0;

["Cancelled."] call BA_fnc_speak;
