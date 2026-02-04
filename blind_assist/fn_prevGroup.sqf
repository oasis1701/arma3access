/*
 * Function: BA_fnc_prevGroup
 * Switches to the leader of the previous friendly group.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   Boolean - true if successfully switched
 *
 * Example:
 *   [] call BA_fnc_prevGroup;
 */

if (!BA_observerMode) exitWith {
    ["Not in observer mode. Press Control O first."] call BA_fnc_speak;
    false
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
    ["No friendly groups available."] call BA_fnc_speak;
    false
};

if (count _friendlyGroups == 1) exitWith {
    ["Only one friendly group."] call BA_fnc_speak;
    false
};

// Find current group index
private _currentIndex = _friendlyGroups find BA_currentGroup;
if (_currentIndex == -1) then { _currentIndex = 0; };

// Move to previous group (wrap around)
private _prevIndex = (_currentIndex - 1 + count _friendlyGroups) mod (count _friendlyGroups);
private _prevGroup = _friendlyGroups select _prevIndex;

// Switch to that group's leader
private _leader = leader _prevGroup;
if (!alive _leader) then {
    // If leader is dead, get first alive unit
    _leader = ((units _prevGroup) select { alive _x }) select 0;
};

[_leader] call BA_fnc_switchObserverTarget
