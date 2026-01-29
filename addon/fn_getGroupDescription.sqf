/*
 * Function: BA_fnc_getGroupDescription
 * Returns a descriptive string for a group (callsign, leader name, unit count).
 *
 * Format: "Alpha 1-1, Sergeant Miller, 4 infantry"
 *
 * Arguments:
 *   0: Group <GROUP>
 *
 * Return Value:
 *   String - Group description
 *
 * Example:
 *   private _desc = [_group] call BA_fnc_getGroupDescription;
 */

params [["_group", grpNull, [grpNull]]];

if (isNull _group) exitWith { "Unknown group" };

// Get group callsign
private _callsign = groupId _group;
if (_callsign == "") then { _callsign = "Unknown callsign"; };

// Get leader name
private _leader = leader _group;
private _leaderName = "";
if (!isNull _leader && alive _leader) then {
    _leaderName = name _leader;
    // Fall back to unit type if no name
    if (_leaderName == "" || _leaderName == "Error: No unit") then {
        _leaderName = getText (configFile >> "CfgVehicles" >> typeOf _leader >> "displayName");
    };
} else {
    _leaderName = "No leader";
};

// Count alive units
private _aliveCount = {alive _x} count units _group;

// Determine unit type description
private _typeDesc = "units";
if (_aliveCount > 0) then {
    // Check if group is in vehicles
    private _inVehicle = false;
    private _vehicleType = "";
    {
        if (vehicle _x != _x) exitWith {
            _inVehicle = true;
            _vehicleType = getText (configFile >> "CfgVehicles" >> typeOf vehicle _x >> "displayName");
        };
    } forEach units _group;

    if (_inVehicle && _vehicleType != "") then {
        _typeDesc = _vehicleType;
    } else {
        _typeDesc = "infantry";
    };
};

// Build description
format["%1, %2, %3 %4", _callsign, _leaderName, _aliveCount, _typeDesc]
