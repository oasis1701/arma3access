/*
 * Function: BA_fnc_getSquadMemberDesc
 * Gets a formatted description of a squad member for the squad menu.
 *
 * Format: "Name, Role, vehicle status, distance direction"
 * Examples:
 *   "Sergeant Miller, Squad Leader, on foot, 15 meters north"
 *   "Corporal Jones, Rifleman, in Hunter HMG as gunner, 30 meters east"
 *
 * Arguments:
 *   0: Unit object <OBJECT>
 *
 * Return Value:
 *   String - formatted description
 *
 * Example:
 *   [_unit] call BA_fnc_getSquadMemberDesc;
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith { "Unknown" };

// Name
private _name = name _unit;

// Role (same logic as fn_announceUnitStatus)
private _role = "";
private _isLeader = _unit == leader group _unit;
private _hasMedikit = "Medikit" in items _unit;
private _hasToolkit = "ToolKit" in items _unit;
private _hasLauncher = secondaryWeapon _unit != "";
if (_isLeader) then { _role = "Squad Leader" }
else { if (_hasMedikit) then { _role = "Medic" }
else { if (_hasToolkit) then { _role = "Engineer" }
else { if (_hasLauncher) then { _role = "AT Specialist" }
else { _role = "Rifleman" } } } };

// Vehicle status
private _vehicleStatus = "";
if (vehicle _unit == _unit) then {
    _vehicleStatus = "on foot";
} else {
    private _veh = vehicle _unit;
    private _vehName = getText (configFile >> "CfgVehicles" >> typeOf _veh >> "displayName");
    if (_vehName == "") then { _vehName = typeOf _veh };

    // Get seat by checking actual vehicle positions
    private _seatName = "passenger";
    if (_unit == driver _veh) then { _seatName = "driver" }
    else { if (_unit == gunner _veh) then { _seatName = "gunner" }
    else { if (_unit == commander _veh) then { _seatName = "commander" } } };

    _vehicleStatus = format["in %1 as %2", _vehName, _seatName];
};

// Distance and direction from player
private _dist = round (player distance _unit);
private _bearing = player getDir _unit;
private _dir = [_bearing] call BA_fnc_bearingToCompass;

format["%1, %2, %3, %4 meters %5", _name, _role, _vehicleStatus, _dist, _dir]
