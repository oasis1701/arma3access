/*
 * Function: BA_fnc_openLookoutMenu
 * Opens the lookout menu with 3 search radius options.
 * Closes conflicting menus (landmarks, BA menu).
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_openLookoutMenu;
 */

// Close conflicting menus
if (BA_landmarksMenuActive) then {
    [] call BA_fnc_closeLandmarksMenu;
};
if (BA_menuActive) then {
    [] call BA_fnc_closeBAMenu;
};

// Populate menu items: [label, radius]
BA_lookoutMenuItems = [
    ["Find lookout 30 meters", 30],
    ["Find lookout 50 meters", 50],
    ["Find lookout 100 meters", 100],
    ["Find lookout 400 meters", 400]
];
BA_lookoutMenuIndex = 0;
BA_lookoutMenuActive = true;

// Announce
private _item = BA_lookoutMenuItems select 0;
private _count = count BA_lookoutMenuItems;
[format ["Lookout menu. 1 of %1. %2.", _count, _item select 0]] call BA_fnc_speak;
