/*
 * Function: BA_fnc_openGroupMenu
 * Opens the group selection menu for selecting which group receives orders.
 *
 * Does NOT move camera or cursor - only selects group for commands.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   Boolean - true if menu opened successfully
 *
 * Example:
 *   [] call BA_fnc_openGroupMenu;
 */

if (!BA_observerMode) exitWith {
    ["Not in observer mode."] call BA_fnc_speak;
    false
};

// Close order menu if open (menus are mutually exclusive)
if (BA_orderMenuActive) then {
    [] call BA_fnc_closeOrderMenu;
};

// Get the side of the original player unit
private _playerSide = side BA_originalUnit;

// Get all groups on the same side with alive units (excluding ghost group)
private _friendlyGroups = allGroups select {
    side _x == _playerSide &&
    {alive _x} count units _x > 0 &&
    {isNil "BA_ghostGroup" || {_x != BA_ghostGroup}}
};

if (count _friendlyGroups == 0) exitWith {
    ["No groups available."] call BA_fnc_speak;
    false
};

// Store groups for navigation
BA_groupMenuItems = _friendlyGroups;

// Pre-select observed unit's group if available
private _observedGroup = group BA_observedUnit;
private _preSelectIndex = _friendlyGroups find _observedGroup;
if (_preSelectIndex == -1) then { _preSelectIndex = 0; };
BA_groupMenuIndex = _preSelectIndex;

// Activate menu
BA_groupMenuActive = true;

// Build announcement with current group info
private _currentGroup = BA_groupMenuItems select BA_groupMenuIndex;
private _groupInfo = [_currentGroup] call BA_fnc_getGroupDescription;
private _total = count BA_groupMenuItems;

private _announcement = format["Group selection. %1 of %2. %3. Arrows to navigate, Enter to select, Escape to cancel.",
    BA_groupMenuIndex + 1, _total, _groupInfo];

[_announcement] call BA_fnc_speak;

systemChat format["Group Menu opened - %1 groups available", _total];

true
