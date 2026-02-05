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
        // Option selected
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
