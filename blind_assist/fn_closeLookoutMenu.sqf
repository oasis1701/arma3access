/*
 * Function: BA_fnc_closeLookoutMenu
 * Closes the lookout menu and resets state.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_closeLookoutMenu;
 */

BA_lookoutMenuActive = false;
BA_lookoutMenuIndex = 0;
BA_lookoutMenuItems = [];

["Lookout cancelled."] call BA_fnc_speak;
