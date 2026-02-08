/*
 * Function: BA_fnc_initSquadMenu
 * Initializes the Squad Member Menu state variables.
 *
 * The squad menu appears in focus mode after selecting an order,
 * letting the player pick which squad member receives the command.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_initSquadMenu;
 */

BA_squadMenuActive = false;
BA_squadMenuItems = [];       // Array of unit objects
BA_squadMenuDescs = [];       // Array of description strings (parallel to items)
BA_squadMenuIndex = 0;
BA_pendingSquadUnit = objNull;   // Stashed unit for order execution

systemChat "Blind Assist: Squad Menu system initialized.";
