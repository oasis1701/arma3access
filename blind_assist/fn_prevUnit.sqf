/*
 * Function: BA_fnc_prevUnit
 * Switches to the previous unit in the current group.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   Boolean - true if successfully switched
 *
 * Example:
 *   [] call BA_fnc_prevUnit;
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

// Move to previous unit (wrap around)
private _prevIndex = (_currentIndex - 1 + count _units) mod (count _units);
private _prevUnit = _units select _prevIndex;

[_prevUnit] call BA_fnc_switchObserverTarget
