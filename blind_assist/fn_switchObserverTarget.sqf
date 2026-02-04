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

// Use switchCamera for all units - consistent first-person view for both infantry and vehicles
_unit switchCamera "INTERNAL";

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

// Update vehicle tracking to prevent false "Dismounted" from sync loop
BA_lastObservedVehicle = vehicle _unit;

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

// Check if unit is in a vehicle
private _inVehicle = vehicle _unit != _unit;

// Build announcement based on whether in vehicle or not
private _announcement = "";

if (_inVehicle) then {
    // --- VEHICLE CREW ANNOUNCEMENT ---
    // For units in vehicles: skip stance/movement (doesn't make sense for crew)
    private _veh = vehicle _unit;
    private _vehName = getText (configFile >> "CfgVehicles" >> typeOf _veh >> "displayName");

    // Announce: "Blufor. Alpha 1. Helicopter Pilot. John Smith. In Ghost Hawk."
    _announcement = format["%1. %2. %3.", _sideName, _groupName, _unitType];
    if (_unitName != "" && _unitName != "Error: No unit") then {
        _announcement = format["%1. %2. %3. %4.", _sideName, _groupName, _unitType, _unitName];
    };
    _announcement = _announcement + format[" In %1.", _vehName];
} else {
    // --- INFANTRY ANNOUNCEMENT ---

    // Get stance (STAND, CROUCH, PRONE)
    private _stance = stance _unit;
    private _stanceDesc = switch (_stance) do {
        case "STAND": { "Standing" };
        case "CROUCH": { "Crouched" };
        case "PRONE": { "Prone" };
        default { "" };
    };

    // Get alert level (behaviour)
    private _behaviour = behaviour _unit;
    private _alertDesc = switch (_behaviour) do {
        case "CARELESS": { "Relaxed" };
        case "SAFE": { "Safe" };
        case "AWARE": { "Aware" };
        case "COMBAT": { "Combat" };
        case "STEALTH": { "Stealth" };
        default { "" };
    };

    // Get movement status
    private _moveDesc = "";
    if (unitReady _unit) then {
        _moveDesc = "Ready";
    } else {
        if (moveToFailed _unit) then {
            _moveDesc = "Stuck";
        } else {
            _moveDesc = "Moving";
        };
    };

    // Build status string
    private _statusParts = [];
    if (_stanceDesc != "") then { _statusParts pushBack _stanceDesc; };
    if (_alertDesc != "") then { _statusParts pushBack _alertDesc; };
    if (_moveDesc != "") then { _statusParts pushBack _moveDesc; };
    private _statusStr = _statusParts joinString ". ";

    // Base announcement: "Blufor. Alpha 1. Rifleman. John Smith. Crouched. Combat. Moving."
    _announcement = format["%1. %2. %3.", _sideName, _groupName, _unitType];
    if (_unitName != "" && _unitName != "Error: No unit") then {
        _announcement = format["%1. %2. %3. %4.", _sideName, _groupName, _unitType, _unitName];
    };
    if (_statusStr != "") then {
        _announcement = _announcement + " " + _statusStr + ".";
    };

    // --- ADDITIONAL CONTEXT INFO ---
    private _contextParts = [];

    // Check if in building
    private _nearestBldg = nearestBuilding _unit;
    if (!isNull _nearestBldg && {_unit distance _nearestBldg < 5}) then {
        _contextParts pushBack "Inside building";
    };

    // Check distance from leader (only if significant)
    private _leader = leader group _unit;
    if (_unit != _leader) then {
        private _dist = round (_unit distance _leader);
        if (_dist > 20) then {
            _contextParts pushBack format["%1 meters from leader", _dist];
        };
    };

    // Check if targeting enemy
    private _target = assignedTarget _unit;
    if (!isNull _target) then {
        _contextParts pushBack "Targeting enemy";
    };

    // Add context to announcement
    if (count _contextParts > 0) then {
        _announcement = _announcement + " " + (_contextParts joinString ". ") + ".";
    };
};

[_announcement] call BA_fnc_speak;
systemChat format["Observing: %1 - %2 - %3", _sideName, _groupName, _unitType];

true
