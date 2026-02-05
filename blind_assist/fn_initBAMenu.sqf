/*
 * Function: BA_fnc_initBAMenu
 * Initializes the BA Menu system state variables.
 *
 * The BA Menu provides an inventory browser for restocking ammunition.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_initBAMenu;
 */

// Menu state
BA_menuActive = false;
BA_menuLevel = 0;        // 0=closed, 1=weapons, 2=options, 3=mag count
BA_menuItems = [];
BA_menuIndex = 0;

// Selected weapon info (preserved across levels)
BA_selectedWeapon = "";
BA_selectedWeaponName = "";
BA_selectedMagazine = "";
