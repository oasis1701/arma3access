/*
 * Function: BA_fnc_selectIntersectionMenuItem
 * Selects the current road in the intersection menu and starts following it.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   Boolean - true if road selected successfully
 *
 * Example:
 *   [] call BA_fnc_selectIntersectionMenuItem;
 */

if (!BA_intersectionMenuActive) exitWith { false };

private _count = count BA_intersectionMenuItems;
if (_count == 0 || BA_intersectionMenuIndex >= _count) exitWith {
    [] call BA_fnc_closeIntersectionMenu;
    false
};

// Get selected item
private _item = BA_intersectionMenuItems select BA_intersectionMenuIndex;
_item params ["_road", "_dir", "_type", "_len", "_dest"];

// Switch to selected road
BA_currentRoad = _road;
BA_lastRoadInfo = getRoadInfo _road;
BA_atRoadEnd = false;

// Close menu
BA_intersectionMenuActive = false;
BA_intersectionMenuItems = [];
BA_intersectionMenuIndex = 0;

// Announce selection
private _announcement = format ["Selected %1 onto %2.", toLower _dir, _type];
[_announcement] call BA_fnc_speak;

// Auto-refresh scanner
[] call BA_fnc_scanObjects;

true
