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
private _altitude = -1;  // -1 means not an aircraft
if (_aliveCount > 0) then {
    // Check if group is in vehicles
    private _inVehicle = false;
    private _vehicleType = "";
    private _vehicle = objNull;
    {
        if (vehicle _x != _x) exitWith {
            _inVehicle = true;
            _vehicle = vehicle _x;
            _vehicleType = getText (configFile >> "CfgVehicles" >> typeOf _vehicle >> "displayName");
        };
    } forEach units _group;

    if (_inVehicle && _vehicleType != "") then {
        _typeDesc = _vehicleType;
        // Check if it's an air vehicle (helicopter, plane, or UAV)
        if (_vehicle isKindOf "Air") then {
            _altitude = round ((getPosATL _vehicle) select 2);
        };
    } else {
        _typeDesc = "infantry";
    };
};

// Count stragglers (units far from leader or stuck)
private _stragglers = 0;
private _aliveUnits = units _group select { alive _x };
{
    if (_x != _leader) then {
        private _distFromLeader = _x distance _leader;
        // Straggler if: >50m from leader OR moveToFailed
        if (_distFromLeader > 50 || moveToFailed _x) then {
            _stragglers = _stragglers + 1;
        };
    };
} forEach _aliveUnits;

// Build final description
private _baseDesc = format["%1, %2, %3 %4", _callsign, _leaderName, _aliveCount, _typeDesc];

// Add altitude for aircraft
if (_altitude >= 0) then {
    _baseDesc = _baseDesc + format[", %1 meters", _altitude];
};

if (_stragglers > 0) then {
    _baseDesc = _baseDesc + format[", %1 straggler%2", _stragglers, if (_stragglers > 1) then {"s"} else {""}];
};
_baseDesc
