/*
 * Function: BA_fnc_openSquadMenu
 * Opens the squad member selection menu.
 *
 * Shows alive squad members (excluding player) with name, role,
 * vehicle status, distance, and direction.
 *
 * Arguments:
 *   None (uses BA_pendingOrderType/Label set by selectOrderMenuItem)
 *
 * Return Value:
 *   Boolean - true if menu opened successfully
 *
 * Example:
 *   [] call BA_fnc_openSquadMenu;
 */

// Get the player's group
private _group = group player;
private _allUnits = (units _group) - [player];

// Filter to alive units only
private _aliveUnits = _allUnits select { alive _x };

if (count _aliveUnits == 0) exitWith {
    ["No squad members available"] call BA_fnc_speak;
    false
};

// Build description for each unit
private _descriptions = [];
{
    private _unit = _x;
    private _desc = [_unit] call BA_fnc_getSquadMemberDesc;
    _descriptions pushBack _desc;
} forEach _aliveUnits;

// Set menu state - prepend "Order All" as first item
BA_squadMenuItems = [objNull] + _aliveUnits;
BA_squadMenuDescs = ["Order All, command entire squad"] + _descriptions;
BA_squadMenuIndex = 0;
BA_squadMenuActive = true;

// Announce
private _count = count BA_squadMenuItems;
private _firstDesc = BA_squadMenuDescs select 0;
private _message = format["Select squad member. 1 of %1. %2. Up Down to navigate, Enter to select, Escape to cancel.", _count, _firstDesc];
[_message] call BA_fnc_speak;

true
