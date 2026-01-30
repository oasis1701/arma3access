/*
 * fn_announceNearbyAsset.sqf
 * Announce details of a nearby friendly asset when player approaches
 *
 * Parameters:
 * 0: OBJECT - The asset (unit or vehicle) to announce
 *
 * Usage: [_asset] call BA_fnc_announceNearbyAsset;
 */

params [["_asset", objNull, [objNull]]];

if (isNull _asset) exitWith {};

private _msg = "";

// Check if it's a vehicle
if (_asset isKindOf "LandVehicle" || _asset isKindOf "Air" || _asset isKindOf "StaticWeapon") then {
    // Vehicle announcement
    private _assetType = _asset getVariable ["BA_assetType", ""];

    if (_assetType == "") then {
        // Try to determine type from vehicle class
        _assetType = switch (true) do {
            case (_asset isKindOf "Helicopter"): { getText (configFile >> "CfgVehicles" >> typeOf _asset >> "displayName") };
            case (_asset isKindOf "Plane"): { getText (configFile >> "CfgVehicles" >> typeOf _asset >> "displayName") };
            case (_asset isKindOf "Tank"): { getText (configFile >> "CfgVehicles" >> typeOf _asset >> "displayName") };
            case (_asset isKindOf "Car"): { getText (configFile >> "CfgVehicles" >> typeOf _asset >> "displayName") };
            case (_asset isKindOf "StaticWeapon"): { getText (configFile >> "CfgVehicles" >> typeOf _asset >> "displayName") };
            default { "Vehicle" };
        };
    };

    // Get crew count
    private _crewCount = count crew _asset;
    private _status = if (canMove _asset && fuel _asset > 0) then { "ready" } else { "disabled" };

    if (_crewCount > 0) then {
        _msg = format["%1 - %2 of %3, %4", _assetType, _crewCount, count fullCrew [_asset, "", true], _status];
    } else {
        _msg = format["%1 - empty, %2", _assetType, _status];
    };
} else {
    // Infantry unit announcement
    private _assetType = _asset getVariable ["BA_assetType", ""];

    if (_assetType != "") then {
        // Get unit count from group
        private _grp = group _asset;
        private _aliveCount = count (units _grp select {alive _x});
        _msg = format["%1 - %2 units", _assetType, _aliveCount];
    } else {
        // Single unit or unknown
        private _unitType = getText (configFile >> "CfgVehicles" >> typeOf _asset >> "displayName");
        _msg = format["%1", _unitType];
    };
};

// Speak the announcement
[_msg] call BA_fnc_speak;
systemChat _msg;

_msg
