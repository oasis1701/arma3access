/*
 * Function: BA_fnc_closeOrderMenu
 * Closes the order menu without issuing a command.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_closeOrderMenu;
 */

// Clear menu state
BA_orderMenuActive = false;
BA_orderMenuItems = [];
BA_orderMenuIndex = 0;

["Orders cancelled"] call BA_fnc_speak;
