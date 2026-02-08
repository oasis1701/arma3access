/*
 * Function: BA_fnc_selectOrderMenuItem
 * Selects the current menu item and issues the order.
 *
 * Gets the selected command from BA_orderMenuItems,
 * closes the menu, and calls fn_issueOrder.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_selectOrderMenuItem;
 */

// Must have menu active
if (!BA_orderMenuActive) exitWith {};
if (count BA_orderMenuItems == 0) exitWith {};

// Get selected item
private _item = BA_orderMenuItems select BA_orderMenuIndex;
private _label = _item select 0;
private _commandType = _item select 1;

// --- Vehicle sub-menu: player selected a vehicle from the list ---
if (!isNil "BA_orderSubMenu" && {BA_orderSubMenu == "enter_vehicle"}) exitWith {
    private _veh = _commandType; // index 1 is the vehicle object
    if (isNull _veh || {!alive _veh}) exitWith {
        [format["Vehicle no longer available. %1 of %2.", BA_orderMenuIndex + 1, count BA_orderMenuItems]] call BA_fnc_speak;
    };
    // Check for free cargo seats
    private _freeCargo = _veh emptyPositions "cargo";
    if (_freeCargo == 0) exitWith {
        [format["Vehicle is full. %1 of %2.", BA_orderMenuIndex + 1, count BA_orderMenuItems]] call BA_fnc_speak;
    };
    // Order all on-foot squad members to board
    private _group = group player;
    {
        if (_x != player && alive _x && vehicle _x == _x) then {
            _x moveInAny _veh;
        };
    } forEach units _group;
    // Close menu
    BA_orderMenuActive = false;
    BA_orderMenuItems = [];
    BA_orderMenuIndex = 0;
    BA_orderSubMenu = "";
    // Get short vehicle name for announcement
    private _vehName = getText (configFile >> "CfgVehicles" >> typeOf _veh >> "displayName");
    [format["Squad boarding %1.", _vehName]] call BA_fnc_speak;
};

// --- "Enter Vehicle" command: scan nearby vehicles and open sub-menu ---
if (_commandType == "enter_vehicle") exitWith {
    private _nearVehicles = nearestObjects [getPos player, ["Car","Tank","Air","Ship"], 50];
    _nearVehicles = _nearVehicles select {alive _x && _x != vehicle player};
    if (count _nearVehicles == 0) exitWith {
        BA_orderMenuActive = false;
        BA_orderMenuItems = [];
        BA_orderMenuIndex = 0;
        ["No vehicles nearby."] call BA_fnc_speak;
    };
    // Build vehicle menu items
    private _vehItems = [];
    {
        private _vehName = getText (configFile >> "CfgVehicles" >> typeOf _x >> "displayName");
        private _crew = count crew _x;
        private _maxCrew = getNumber (configFile >> "CfgVehicles" >> typeOf _x >> "transportSoldier") + (count allTurrets [_x, true]);
        private _dist = player distance _x;
        private _label = format["%1, %2 of %3, %4 meters", _vehName, _crew, _maxCrew, round _dist];
        _vehItems pushBack [_label, _x];
    } forEach _nearVehicles;
    // Replace menu with vehicle list
    BA_orderMenuItems = _vehItems;
    BA_orderMenuIndex = 0;
    BA_orderSubMenu = "enter_vehicle";
    private _firstLabel = (_vehItems select 0) select 0;
    [format["Nearby vehicles. 1 of %1. %2.", count _vehItems, _firstLabel]] call BA_fnc_speak;
};

// Close menu first
BA_orderMenuActive = false;
BA_orderMenuItems = [];
BA_orderMenuIndex = 0;

// In focus mode, issue order to stashed squad unit
if (BA_focusMode) exitWith {
    private _targetUnit = if (!isNil "BA_pendingSquadUnit") then { BA_pendingSquadUnit } else { objNull };
    BA_pendingSquadUnit = objNull;
    [_commandType, _label, _targetUnit] call BA_fnc_issueOrder;
};

// Observer mode: issue the order directly
[_commandType, _label] call BA_fnc_issueOrder;
