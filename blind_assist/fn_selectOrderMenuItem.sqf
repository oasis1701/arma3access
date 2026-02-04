/*
 * Function: BA_fnc_selectOrderMenuItem
 * Selects the current menu item and issues the order.
 *
 * Gets the selected command from BA_orderMenuItems,
 * closes the menu, and calls fn_issueOrder.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_selectOrderMenuItem;
 */

// Must have menu active
if (!BA_orderMenuActive) exitWith {};
if (count BA_orderMenuItems == 0) exitWith {};

// Get selected item
private _item = BA_orderMenuItems select BA_orderMenuIndex;
private _label = _item select 0;
private _commandType = _item select 1;

// Close menu first
BA_orderMenuActive = false;
BA_orderMenuItems = [];
BA_orderMenuIndex = 0;

// Issue the order
[_commandType, _label] call BA_fnc_issueOrder;
