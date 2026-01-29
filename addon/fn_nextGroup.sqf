/*
 * Function: BA_fnc_nextGroup
 * Switches to the leader of the next friendly group.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   Boolean - true if successfully switched
 *
 * Example:
 *   [] call BA_fnc_nextGroup;
 */

if (!BA_observerMode) exitWith {
    ["Not in observer mode. Press Control O first."] call BA_fnc_speak;
    false
};

// Get the side of the original player unit
private _playerSide = side BA_originalUnit;

// Get all groups on the same side with alive units
private _friendlyGroups = allGroups select {
    side _x == _playerSide &&
    {alive _x} count units _x > 0
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

// Move to next group (wrap around)
private _nextIndex = (_currentIndex + 1) mod (count _friendlyGroups);
private _nextGroup = _friendlyGroups select _nextIndex;

// Switch to that group's leader
private _leader = leader _nextGroup;
if (!alive _leader) then {
    // If leader is dead, get first alive unit
    _leader = ((units _nextGroup) select { alive _x }) select 0;
};

[_leader] call BA_fnc_switchObserverTarget
