/*
 * Function: BA_fnc_openBAMenu
 * Opens the BA Menu with tabs: Inventory (weapons/items) and Settings.
 *
 * Available in both Observer Mode and Focus Mode.
 * Hotkey: N
 * Left/Right arrows switch between tabs.
 *
 * Arguments:
 *   0: BOOL - (Optional) Force rebuild items for current tab (used by tab switching)
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_openBAMenu;
 *   [true] call BA_fnc_openBAMenu;  // Force rebuild (tab switch)
 */

params [["_forceRebuild", false, [false]]];

diag_log format ["BA_DEBUG: fn_openBAMenu called, forceRebuild=%1, tab=%2", _forceRebuild, BA_menuTab];

// Don't open if already active at level 1 (allow reopening from other levels)
// But allow force rebuild (used by tab switching)
if (!_forceRebuild && BA_menuActive && BA_menuLevel == 1) exitWith {
    diag_log "BA_DEBUG: Menu already active at level 1, exiting";
};

// Track whether this is a fresh open or a tab switch
private _isFreshOpen = !BA_menuActive || BA_menuLevel != 1;

// Close other menus if open
if (!isNil "BA_landmarksMenuActive" && {BA_landmarksMenuActive}) then { [] call BA_fnc_closeLandmarksMenu; };
if (!isNil "BA_orderMenuActive" && {BA_orderMenuActive}) then { [] call BA_fnc_closeOrderMenu; };
if (!isNil "BA_groupMenuActive" && {BA_groupMenuActive}) then { [] call BA_fnc_closeGroupMenu; };
if (!isNil "BA_intersectionMenuActive" && {BA_intersectionMenuActive}) then { [] call BA_fnc_closeIntersectionMenu; };

// Build items based on current tab
BA_menuItems = [];

switch (BA_menuTab) do {
    // ================================================================
    // Tab 0: Inventory
    // ================================================================
    case 0: {
        // Determine target unit
        private _unit = if (BA_observerMode && !isNull BA_originalUnit) then {
            BA_originalUnit
        } else {
            player
        };

        diag_log format ["BA_DEBUG: Building weapon list for unit %1", _unit];

        // Helper: detect secondary muzzle (GL) via config and return its magazine info
        private _fnc_getSecondaryMuzzleInfo = {
            params ["_unit", "_weaponClass"];
            private _result = [];

            private _muzzles = getArray (configFile >> "CfgWeapons" >> _weaponClass >> "muzzles");
            diag_log format ["BA_DEBUG: _fnc_getSecondaryMuzzleInfo for %1: muzzles=%2", _weaponClass, _muzzles];

            if (count _muzzles > 1) then {
                private _glMuzzle = "";
                {
                    if (_x != "this" && _x != (_muzzles select 0)) exitWith {
                        _glMuzzle = _x;
                    };
                } forEach _muzzles;

                if (_glMuzzle == "") then {
                    if (count _muzzles > 1) then { _glMuzzle = _muzzles select 1; };
                };

                if (_glMuzzle != "") then {
                    private _glMags = compatibleMagazines [_weaponClass, _glMuzzle];
                    diag_log format ["BA_DEBUG: GL muzzle=%1, compatible mags=%2", _glMuzzle, _glMags];

                    if (count _glMags > 0) then {
                        private _unitMags = magazines _unit;
                        private _bestMag = _glMags select 0;
                        private _bestCount = 0;
                        {
                            private _magClass = _x;
                            private _c = 0;
                            { if (_x == _magClass) then { _c = _c + 1; }; } forEach _unitMags;
                            if (_c > _bestCount) then { _bestMag = _magClass; _bestCount = _c; };
                        } forEach _glMags;

                        _result = [_bestMag, _bestCount];
                        diag_log format ["BA_DEBUG: GL detected on %1: mag=%2, count=%3", _weaponClass, _bestMag, _bestCount];
                    };
                };
            };

            _result
        };

        // === WEAPONS ===
        private _primary = primaryWeapon _unit;
        diag_log format ["BA_DEBUG: Primary weapon = %1", _primary];
        if (_primary != "") then {
            diag_log "BA_DEBUG: Calling getWeaponMagazineInfo for primary";
            private _info = [_unit, _primary] call BA_fnc_getWeaponMagazineInfo;
            diag_log format ["BA_DEBUG: getWeaponMagazineInfo returned %1", _info];
            _info params ["_magClass", "_count"];
            private _name = getText (configFile >> "CfgWeapons" >> _primary >> "displayName");
            diag_log format ["BA_DEBUG: Primary %1 (%2), %3 mags", _name, _magClass, _count];
            private _entry = [_name, _primary, _magClass, _count, "weapon"];
            private _glInfo = [_unit, _primary] call _fnc_getSecondaryMuzzleInfo;
            if (count _glInfo > 0) then {
                _entry pushBack (_glInfo select 0);
                _entry pushBack (_glInfo select 1);
            };
            BA_menuItems pushBack _entry;
        };

        // Secondary weapon (launcher)
        private _secondary = secondaryWeapon _unit;
        if (_secondary != "") then {
            private _info = [_unit, _secondary] call BA_fnc_getWeaponMagazineInfo;
            _info params ["_magClass", "_count"];
            private _name = getText (configFile >> "CfgWeapons" >> _secondary >> "displayName");
            private _entry = [_name, _secondary, _magClass, _count, "weapon"];
            private _glInfo = [_unit, _secondary] call _fnc_getSecondaryMuzzleInfo;
            if (count _glInfo > 0) then {
                _entry pushBack (_glInfo select 0);
                _entry pushBack (_glInfo select 1);
            };
            BA_menuItems pushBack _entry;
        };

        // Handgun
        private _handgun = handgunWeapon _unit;
        if (_handgun != "") then {
            private _info = [_unit, _handgun] call BA_fnc_getWeaponMagazineInfo;
            _info params ["_magClass", "_count"];
            private _name = getText (configFile >> "CfgWeapons" >> _handgun >> "displayName");
            private _entry = [_name, _handgun, _magClass, _count, "weapon"];
            private _glInfo = [_unit, _handgun] call _fnc_getSecondaryMuzzleInfo;
            if (count _glInfo > 0) then {
                _entry pushBack (_glInfo select 0);
                _entry pushBack (_glInfo select 1);
            };
            BA_menuItems pushBack _entry;
        };

        // === AMMUNITION ===
        private _unitMags = magazines _unit;
        private _magCounts = createHashMap;
        { _magCounts set [_x, (_magCounts getOrDefault [_x, 0]) + 1]; } forEach _unitMags;

        {
            private _class = _x;
            private _magCount = _y;
            private _magName = getText (configFile >> "CfgMagazines" >> _class >> "displayName");
            if (_magName == "") then { _magName = _class; };

            private _countText = if (_magCount > 1) then { format [" x%1", _magCount] } else { "" };
            BA_menuItems pushBack [_magName + _countText, _class, "", _magCount, "item"];
        } forEach _magCounts;

        // === INVENTORY ITEMS ===
        private _allItems = (uniformItems _unit) + (vestItems _unit) + (backpackItems _unit);

        diag_log format ["BA_DEBUG: uniformItems = %1", uniformItems _unit];
        diag_log format ["BA_DEBUG: vestItems = %1", vestItems _unit];
        diag_log format ["BA_DEBUG: backpackItems = %1", backpackItems _unit];
        diag_log format ["BA_DEBUG: _allItems (combined) = %1", _allItems];

        private _magazines = magazines _unit;
        _allItems = _allItems select { !(_x in _magazines) };

        diag_log format ["BA_DEBUG: magazines to filter = %1", _magazines];
        diag_log format ["BA_DEBUG: _allItems after filter = %1", _allItems];

        private _itemCounts = createHashMap;
        { _itemCounts set [_x, (_itemCounts getOrDefault [_x, 0]) + 1]; } forEach _allItems;

        diag_log format ["BA_DEBUG: _itemCounts hashmap = %1", _itemCounts];

        {
            private _class = _x;
            private _itemCount = _y;
            private _itemName = getText (configFile >> "CfgWeapons" >> _class >> "displayName");
            if (_itemName == "") then { _itemName = getText (configFile >> "CfgMagazines" >> _class >> "displayName"); };
            if (_itemName == "") then { _itemName = _class; };

            private _countText = if (_itemCount > 1) then { format [" x%1", _itemCount] } else { "" };
            BA_menuItems pushBack [_itemName + _countText, _class, "", _itemCount, "item"];
        } forEach _itemCounts;

        // === ASSIGNED ITEMS ===
        diag_log format ["BA_DEBUG: assignedItems = %1", assignedItems _unit];
        {
            if (_x != "") then {
                private _itemName = getText (configFile >> "CfgWeapons" >> _x >> "displayName");
                if (_itemName == "") then { _itemName = _x; };
                BA_menuItems pushBack [_itemName, _x, "", 1, "assigned"];
            };
        } forEach (assignedItems _unit);

        // === EQUIPMENT WORN ===
        diag_log format ["BA_DEBUG: uniform = %1", uniform _unit];
        diag_log format ["BA_DEBUG: vest = %1", vest _unit];
        diag_log format ["BA_DEBUG: backpack = %1", backpack _unit];
        diag_log format ["BA_DEBUG: headgear = %1", headgear _unit];
        diag_log format ["BA_DEBUG: goggles = %1", goggles _unit];

        private _uniformClass = uniform _unit;
        if (_uniformClass != "") then {
            private _itemName = getText (configFile >> "CfgWeapons" >> _uniformClass >> "displayName");
            if (_itemName == "") then { _itemName = _uniformClass; };
            BA_menuItems pushBack [_itemName, _uniformClass, "", 1, "equipment"];
        };

        private _vestClass = vest _unit;
        if (_vestClass != "") then {
            private _itemName = getText (configFile >> "CfgWeapons" >> _vestClass >> "displayName");
            if (_itemName == "") then { _itemName = _vestClass; };
            BA_menuItems pushBack [_itemName, _vestClass, "", 1, "equipment"];
        };

        private _backpackClass = backpack _unit;
        if (_backpackClass != "") then {
            private _itemName = getText (configFile >> "CfgVehicles" >> _backpackClass >> "displayName");
            if (_itemName == "") then { _itemName = _backpackClass; };
            BA_menuItems pushBack [_itemName, _backpackClass, "", 1, "equipment"];
        };

        private _headgearClass = headgear _unit;
        if (_headgearClass != "") then {
            private _itemName = getText (configFile >> "CfgWeapons" >> _headgearClass >> "displayName");
            if (_itemName == "") then { _itemName = _headgearClass; };
            BA_menuItems pushBack [_itemName, _headgearClass, "", 1, "equipment"];
        };

        private _gogglesClass = goggles _unit;
        if (_gogglesClass != "") then {
            private _itemName = getText (configFile >> "CfgGlasses" >> _gogglesClass >> "displayName");
            if (_itemName == "") then { _itemName = _gogglesClass; };
            BA_menuItems pushBack [_itemName, _gogglesClass, "", 1, "equipment"];
        };

        // === PLAYER STATUS (must always be the last menu item) ===
        private _playerName = name _unit;

        private _role = roleDescription _unit;
        if (_role == "") then {
            _role = getText (configFile >> "CfgVehicles" >> typeOf _unit >> "displayName");
        };
        if (_role == "") then { _role = "Unknown role"; };

        private _sideStr = switch (side _unit) do {
            case west: { "BLUFOR" };
            case east: { "OPFOR" };
            case resistance: { "Independent" };
            case civilian: { "Civilian" };
            default { str side _unit };
        };

        private _factionName = getText (configFile >> "CfgFactionClasses" >> faction _unit >> "displayName");
        if (_factionName == "") then { _factionName = faction _unit; };

        private _vehicleStatus = "";
        if (vehicle _unit != _unit) then {
            private _veh = vehicle _unit;
            private _vehName = getText (configFile >> "CfgVehicles" >> typeOf _veh >> "displayName");
            if (_vehName == "") then { _vehName = typeOf _veh; };
            private _vehRole = assignedVehicleRole _unit;
            private _roleName = if (count _vehRole > 0) then { _vehRole select 0 } else { "passenger" };
            _vehicleStatus = format ["in %1 as %2", _vehName, _roleName];
        } else {
            _vehicleStatus = "on foot";
        };

        private _statusText = format ["%1, %2, %3 %4, %5", _playerName, _role, _sideStr, _factionName, _vehicleStatus];
        BA_menuItems pushBack [_statusText, "", "", 0, "item"];
    };

    // ================================================================
    // Tab 1: Settings
    // ================================================================
    case 1: {
        private _horizState = if (BA_aimHorizGuidanceEnabled) then {"On"} else {"Off"};
        private _dialogState = if (BA_dialogReaderEnabled) then {"On"} else {"Off"};
        BA_menuItems = [
            [format ["Aim Assist Horizontal tone: %1", _horizState], "toggle", "aimHorizGuidance"],
            [format ["Custom dialog accessibility: %1", _dialogState], "toggle", "dialogReader"]
        ];
    };

    // ================================================================
    // Tab 2: Interactions
    // ================================================================
    case 2: {
        private _unit = if (BA_observerMode && !isNull BA_originalUnit) then {
            BA_originalUnit
        } else {
            player
        };

        private _inVehicle = vehicle _unit != _unit;

        if (_inVehicle) then {
            // In vehicle: show Exit Vehicle
            BA_menuItems pushBack ["Exit Vehicle", "exit_vehicle", "", 0, "interaction"];
        } else {
            // On foot: show Enter Vehicle
            BA_menuItems pushBack ["Enter Vehicle", "enter_vehicle", "", 0, "interaction"];
        };

        // Heal Self: only when damaged and has FirstAidKit
        if (damage _unit > 0 && {"FirstAidKit" in (items _unit)}) then {
            BA_menuItems pushBack ["Heal Self", "heal_self", "", 0, "interaction"];
        };
    };
};

diag_log format ["BA_DEBUG: Final BA_menuItems count = %1", count BA_menuItems];
diag_log format ["BA_DEBUG: BA_menuItems = %1", BA_menuItems];

// Check if we have any items
if (count BA_menuItems == 0) exitWith {
    ["No items found."] call BA_fnc_speak;
    BA_menuActive = false;
    BA_menuLevel = 0;
};

// Set menu state
BA_menuActive = true;
BA_menuLevel = 1;

// Restore per-tab remembered index (clamped to valid range)
BA_menuIndex = BA_menuTabIndex select BA_menuTab;
if (BA_menuIndex >= count BA_menuItems) then { BA_menuIndex = 0; };

// Announce
private _total = count BA_menuItems;
private _item = BA_menuItems select BA_menuIndex;
private _tabName = BA_menuTabNames select BA_menuTab;
private _pos = BA_menuIndex + 1;

if (_isFreshOpen) then {
    // Fresh open: "BA Menu. [Tab] tab. [pos] of [total]. [item]."
    private _name = _item select 0;
    private _type = if (BA_menuTab == 1) then { "setting" } else { _item select 4 };

    private _announcement = if (_type == "weapon") then {
        private _count = _item select 3;
        private _magText = if (_count == 1) then { "magazine" } else { "magazines" };
        format ["BA Menu. %1 tab. %2 of %3. %4, %5 %6.", _tabName, _pos, _total, _name, _count, _magText]
    } else {
        format ["BA Menu. %1 tab. %2 of %3. %4.", _tabName, _pos, _total, _name]
    };
    [_announcement] call BA_fnc_speak;
} else {
    // Tab switch: "[Tab] tab, [total] items. [pos]. [item]."
    private _name = _item select 0;
    private _type = if (BA_menuTab == 1) then { "setting" } else { _item select 4 };
    private _itemsText = if (_total == 1) then { "item" } else { "items" };

    private _announcement = if (_type == "weapon") then {
        private _count = _item select 3;
        private _magText = if (_count == 1) then { "magazine" } else { "magazines" };
        format ["%1 tab, %2 %3. %4. %5, %6 %7.", _tabName, _total, _itemsText, _pos, _name, _count, _magText]
    } else {
        format ["%1 tab, %2 %3. %4. %5.", _tabName, _total, _itemsText, _pos, _name]
    };
    [_announcement] call BA_fnc_speak;
};
