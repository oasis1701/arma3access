/*
 * Function: BA_fnc_initGroupMenu
 * Initializes the group selection menu state variables.
 *
 * This menu allows selecting a group for orders WITHOUT
 * switching the camera view or cursor position.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_initGroupMenu;
 */

// Group menu state variables
BA_groupMenuActive = false;
BA_groupMenuItems = [];      // Array of group references
BA_groupMenuIndex = 0;
BA_selectedOrderGroup = grpNull;  // The group selected for orders

systemChat "Blind Assist: Group Menu initialized.";
