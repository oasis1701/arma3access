/*
 * Function: BA_fnc_nextUnit
 * Switches to the next unit in the current group.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   Boolean - true if successfully switched
 *
 * Example:
 *   [] call BA_fnc_nextUnit;
 */

if (!BA_observerMode) exitWith {
    ["Not in observer mode. Press Control O first."] call BA_fnc_speak;
    false
};

// Get alive units in current group
private _units = (units BA_currentGroup) select { alive _x };

if (count _units == 0) exitWith {
    ["No alive units in group."] call BA_fnc_speak;
    false
};

if (count _units == 1) exitWith {
    ["Only one unit in group."] call BA_fnc_speak;
    false
};

// Find current unit in the alive list
private _currentIndex = _units find BA_observedUnit;
if (_currentIndex == -1) then { _currentIndex = 0; };

// Move to next unit (wrap around)
private _nextIndex = (_currentIndex + 1) mod (count _units);
private _nextUnit = _units select _nextIndex;

[_nextUnit] call BA_fnc_switchObserverTarget
