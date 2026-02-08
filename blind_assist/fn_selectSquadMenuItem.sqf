/*
 * Function: BA_fnc_selectSquadMenuItem
 * Selects the current squad member and opens the order menu for them.
 *
 * Stashes the selected unit in BA_pendingSquadUnit, then opens the
 * order menu with type detection based on that unit's situation.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_selectSquadMenuItem;
 */

if (!BA_squadMenuActive) exitWith {};
if (count BA_squadMenuItems == 0) exitWith {};

// Get selected unit
private _unit = BA_squadMenuItems select BA_squadMenuIndex;

// Close squad menu
BA_squadMenuActive = false;
BA_squadMenuItems = [];
BA_squadMenuDescs = [];
BA_squadMenuIndex = 0;

// Validate unit is still alive
if (!alive _unit) exitWith {
    [format["%1 is dead", name _unit]] call BA_fnc_speak;
};

// Stash unit for the order menu to use
BA_pendingSquadUnit = _unit;

// Open order menu - it will detect type from BA_pendingSquadUnit
[] call BA_fnc_openOrderMenu;
