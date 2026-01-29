/*
 * Function: BA_fnc_switchObserverTarget
 * Switches the observer camera to a different unit.
 *
 * Arguments:
 *   0: _unit - Unit to observe
 *
 * Return Value:
 *   Boolean - true if successfully switched
 *
 * Example:
 *   [_someUnit] call BA_fnc_switchObserverTarget;
 */

params [["_unit", objNull, [objNull]]];

// Validate unit
if (isNull _unit || !alive _unit) exitWith {
    ["Unit not available."] call BA_fnc_speak;
    false
};

// Must be in observer mode
if (!BA_observerMode) exitWith {
    ["Not in observer mode."] call BA_fnc_speak;
    false
};

// Detach camera from current target
detach BA_observerCamera;

// Attach camera to new unit's head
BA_observerCamera attachTo [_unit, [0, 0.1, 0.1], "head"];

// Update tracked unit
BA_observedUnit = _unit;
BA_currentGroup = group _unit;
BA_currentUnitIndex = (units BA_currentGroup) find _unit;

// Reset selected order group when camera switches (orders default to new observed group)
BA_selectedOrderGroup = grpNull;

// Clear road state since cursor is leaving the road
BA_currentRoad = objNull;
BA_atRoadEnd = false;
BA_lastTravelDirection = "";

// Snap cursor to new unit's position
BA_cursorPos = getPos _unit;

// Get side name
private _side = side _unit;
private _sideName = switch (_side) do {
    case west: { "Blufor" };
    case east: { "Opfor" };
    case independent: { "Independent" };
    case civilian: { "Civilian" };
    default { "Unknown" };
};

// Get group name/callsign
private _groupName = groupId BA_currentGroup;

// Get unit type
private _unitType = getText (configFile >> "CfgVehicles" >> typeOf _unit >> "displayName");
if (_unitType == "") then { _unitType = "Soldier"; };

// Get unit's name if available
private _unitName = name _unit;

// Announce: "Blufor. Alpha 1. Rifleman. John Smith."
private _announcement = format["%1. %2. %3.", _sideName, _groupName, _unitType];
if (_unitName != "" && _unitName != "Error: No unit") then {
    _announcement = format["%1. %2. %3. %4.", _sideName, _groupName, _unitType, _unitName];
};

[_announcement] call BA_fnc_speak;
systemChat format["Observing: %1 - %2 - %3", _sideName, _groupName, _unitType];

true
