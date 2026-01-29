/*
 * Function: BA_fnc_selectGroupMenuItem
 * Selects the current group in the menu for receiving orders.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_selectGroupMenuItem;
 */

if (!BA_groupMenuActive) exitWith {};

private _count = count BA_groupMenuItems;
if (_count == 0 || BA_groupMenuIndex >= _count) exitWith {
    ["No group to select."] call BA_fnc_speak;
    BA_groupMenuActive = false;
};

// Get selected group
private _selectedGroup = BA_groupMenuItems select BA_groupMenuIndex;

// Validate group still has alive units
private _aliveUnits = {alive _x} count units _selectedGroup;
if (_aliveUnits == 0) exitWith {
    ["Selected group has no alive units."] call BA_fnc_speak;
    BA_groupMenuActive = false;
};

// Set as order target
BA_selectedOrderGroup = _selectedGroup;

// Close menu
BA_groupMenuActive = false;
BA_groupMenuItems = [];

// Announce selection
private _groupId = groupId _selectedGroup;
private _leaderName = name leader _selectedGroup;
if (_leaderName == "" || _leaderName == "Error: No unit") then {
    _leaderName = getText (configFile >> "CfgVehicles" >> typeOf leader _selectedGroup >> "displayName");
};

private _announcement = format["%1, %2, selected for orders.", _groupId, _leaderName];
[_announcement] call BA_fnc_speak;

systemChat format["Orders will go to: %1", _groupId];
