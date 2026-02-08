/*
 * Function: BA_fnc_closeSquadMenu
 * Closes the squad member menu without issuing a command.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_closeSquadMenu;
 */

BA_squadMenuActive = false;
BA_squadMenuItems = [];
BA_squadMenuDescs = [];
BA_squadMenuIndex = 0;
BA_pendingSquadUnit = objNull;

["Orders cancelled"] call BA_fnc_speak;
