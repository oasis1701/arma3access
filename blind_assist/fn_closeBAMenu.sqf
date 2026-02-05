/*
 * Function: BA_fnc_closeBAMenu
 * Handles back navigation in the BA Menu.
 *
 * Level 3 -> Back to Level 2
 * Level 2 -> Back to Level 1
 * Level 1 -> Close menu entirely
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_closeBAMenu;
 */

// Don't close if not active
if (!BA_menuActive) exitWith {};

switch (BA_menuLevel) do {
    case 3: {
        // Back to options menu
        BA_menuItems = [["Restock", "restock"]];
        if (!isNil "BA_selectedGLMagazine" && {BA_selectedGLMagazine != ""}) then {
            BA_menuItems pushBack ["Restock Grenade Launcher", "restock_gl"];
        };
        BA_menuLevel = 2;
        BA_menuIndex = 0;

        private _total = count BA_menuItems;
        [format ["%1. 1 of %2. Restock.", BA_selectedWeaponName, _total]] call BA_fnc_speak;
    };

    case 2: {
        // Back to weapon list
        [] call BA_fnc_openBAMenu;
    };

    case 1: {
        // Close entirely
        BA_menuActive = false;
        BA_menuLevel = 0;
        BA_menuItems = [];
        BA_menuIndex = 0;

        ["Menu closed."] call BA_fnc_speak;
    };

    default {
        // Safety fallback
        BA_menuActive = false;
        BA_menuLevel = 0;
    };
};
