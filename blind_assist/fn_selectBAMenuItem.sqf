/*
 * Function: BA_fnc_selectBAMenuItem
 * Handles selection in the BA Menu, transitioning between levels.
 *
 * Level 1 (Weapons) -> Level 2 (Options)
 * Level 2 (Options) -> Level 3 (Mag Count)
 * Level 3 (Mag Count) -> Execute and return to Level 1
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_selectBAMenuItem;
 */

// Don't select if menu not active
if (!BA_menuActive) exitWith {};

private _count = count BA_menuItems;
if (_count == 0) exitWith {
    [] call BA_fnc_closeBAMenu;
};

switch (BA_menuLevel) do {
    case 1: {
        // Settings tab — toggle the selected setting
        if (BA_menuTab == 1) exitWith {
            private _item = BA_menuItems select BA_menuIndex;
            private _action = _item select 2;

            if (_action == "aimHorizGuidance") then {
                BA_aimHorizGuidanceEnabled = !BA_aimHorizGuidanceEnabled;
                private _state = if (BA_aimHorizGuidanceEnabled) then {"On"} else {"Off"};

                // Sync to DLL
                if (BA_aimHorizGuidanceEnabled) then {
                    "nvda_arma3_bridge" callExtension "aim_horiz_on";
                } else {
                    "nvda_arma3_bridge" callExtension "aim_horiz_off";
                };

                // Update menu item display
                _item set [0, format ["Aim Assist Horizontal tone: %1", _state]];
                BA_menuItems set [BA_menuIndex, _item];

                [format ["Aim Assist Horizontal tone: %1.", _state]] call BA_fnc_speak;
            };

            if (_action == "dialogReader") then {
                BA_dialogReaderEnabled = !BA_dialogReaderEnabled;
                private _state = if (BA_dialogReaderEnabled) then {"On"} else {"Off"};
                _item set [0, format ["Custom dialog accessibility: %1", _state]];
                BA_menuItems set [BA_menuIndex, _item];
                [format ["Custom dialog accessibility: %1.", _state]] call BA_fnc_speak;
            };
        };

        // Interactions tab — handle interaction actions
        if (BA_menuTab == 2) exitWith {
            private _item = BA_menuItems select BA_menuIndex;
            private _action = _item select 1;

            private _unit = if (BA_observerMode && !isNull BA_originalUnit) then {
                BA_originalUnit
            } else {
                player
            };

            switch (_action) do {
                case "exit_vehicle": {
                    _unit action ["Eject", vehicle _unit];
                    BA_menuActive = false;
                    BA_menuLevel = 0;
                    BA_menuItems = [];
                    BA_menuIndex = 0;
                    ["Exiting vehicle."] call BA_fnc_speak;
                };

                case "heal_self": {
                    _unit action ["HealSelf", _unit];
                    BA_menuActive = false;
                    BA_menuLevel = 0;
                    BA_menuItems = [];
                    BA_menuIndex = 0;
                    ["Healing."] call BA_fnc_speak;
                };

                case "enter_vehicle": {
                    // Build sub-menu of nearby vehicles
                    private _pos = getPos _unit;
                    private _nearVehicles = nearestObjects [_pos, ["Car", "Tank", "Air", "Ship"], 10];
                    _nearVehicles = _nearVehicles select { alive _x && _x != _unit };

                    if (count _nearVehicles == 0) exitWith {
                        ["No vehicles nearby."] call BA_fnc_speak;
                    };

                    BA_interactionType = "enter_vehicle";
                    BA_menuItems = [];

                    {
                        private _veh = _x;
                        private _vehName = getText (configFile >> "CfgVehicles" >> typeOf _veh >> "displayName");
                        if (_vehName == "") then { _vehName = typeOf _veh; };

                        // Occupancy: count crew vs max seats
                        private _crewCount = count crew _veh;
                        private _maxSeats = getNumber (configFile >> "CfgVehicles" >> typeOf _veh >> "transportSoldier") + (count allTurrets [_veh, true]);
                        // Add driver seat
                        _maxSeats = _maxSeats + 1;

                        private _dist = round (_unit distance _veh);
                        private _label = format ["%1, %2 of %3, %4 meters", _vehName, _crewCount, _maxSeats, _dist];

                        BA_menuItems pushBack [_label, _veh, "", 0, "vehicle"];
                    } forEach _nearVehicles;

                    BA_menuLevel = 2;
                    BA_menuIndex = 0;

                    private _total = count BA_menuItems;
                    private _firstItem = BA_menuItems select 0;
                    private _itemsText = if (_total == 1) then { "vehicle" } else { "vehicles" };
                    [format ["Nearby %1. 1 of %2. %3.", _itemsText, _total, _firstItem select 0]] call BA_fnc_speak;
                };
            };
        };

        // Item selected -> Check type before showing options
        private _item = BA_menuItems select BA_menuIndex;
        private _type = _item select 4;

        if (_type == "weapon") then {
            // Weapon selected -> Show options
            BA_selectedWeaponName = _item select 0;
            BA_selectedWeapon = _item select 1;
            BA_selectedPrimaryMagazine = _item select 2;
            BA_selectedMagazine = _item select 2;

            // Check if weapon has GL data (array length > 5)
            if (count _item > 5) then {
                BA_selectedGLMagazine = _item select 5;
            } else {
                BA_selectedGLMagazine = "";
            };

            // Build options menu dynamically
            BA_menuItems = [["Restock", "restock"]];
            if (BA_selectedGLMagazine != "") then {
                BA_menuItems pushBack ["Restock Grenade Launcher", "restock_gl"];
            };
            BA_menuLevel = 2;
            BA_menuIndex = 0;

            // Announce
            private _total = count BA_menuItems;
            [format ["%1. 1 of %2. Restock.", BA_selectedWeaponName, _total]] call BA_fnc_speak;
        } else {
            // Non-weapon items have no options
            ["No options for this item."] call BA_fnc_speak;
        };
    };

    case 2: {
        // Interactions tab Level 2 — vehicle selection
        if (BA_menuTab == 2) exitWith {
            private _item = BA_menuItems select BA_menuIndex;

            if (BA_interactionType == "enter_vehicle") then {
                private _veh = _item select 1;

                // Validate vehicle still exists and is alive
                if (isNull _veh || !alive _veh) exitWith {
                    ["Vehicle no longer available."] call BA_fnc_speak;
                };

                // Check for free seats
                private _crewCount = count crew _veh;
                private _maxSeats = getNumber (configFile >> "CfgVehicles" >> typeOf _veh >> "transportSoldier") + (count allTurrets [_veh, true]) + 1;

                if (_crewCount >= _maxSeats) exitWith {
                    ["Vehicle is full."] call BA_fnc_speak;
                };

                private _vehName = getText (configFile >> "CfgVehicles" >> typeOf _veh >> "displayName");
                if (_vehName == "") then { _vehName = typeOf _veh; };

                private _unit = if (BA_observerMode && !isNull BA_originalUnit) then {
                    BA_originalUnit
                } else {
                    player
                };

                _unit action ["GetInCargo", _veh];

                BA_menuActive = false;
                BA_menuLevel = 0;
                BA_menuItems = [];
                BA_menuIndex = 0;
                BA_interactionType = "";

                [format ["Boarding %1.", _vehName]] call BA_fnc_speak;
            };
        };

        // Option selected (Inventory tab)
        private _item = BA_menuItems select BA_menuIndex;
        private _action = _item select 1;

        if (_action == "restock" || _action == "restock_gl") then {
            // Set the correct magazine based on action
            if (_action == "restock_gl") then {
                BA_selectedMagazine = BA_selectedGLMagazine;
            } else {
                BA_selectedMagazine = BA_selectedPrimaryMagazine;
            };

            // Show magazine count selection
            BA_menuItems = [
                ["1", 1],
                ["2", 2],
                ["4", 4],
                ["6", 6],
                ["8", 8],
                ["10", 10]
            ];
            BA_menuLevel = 3;
            BA_menuIndex = 0;

            // Announce: "Set magazines. 1 of 6. 1."
            ["Set magazines. 1 of 6. 1."] call BA_fnc_speak;
        };
    };

    case 3: {
        // Mag count selected -> Execute restock
        private _item = BA_menuItems select BA_menuIndex;
        private _count = _item select 1;

        // Execute restock
        [BA_selectedMagazine, _count] call BA_fnc_restockAmmo;

        // Close menu
        BA_menuActive = false;
        BA_menuLevel = 0;
        BA_menuItems = [];
        BA_menuIndex = 0;
    };
};
