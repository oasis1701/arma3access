/*
 * Function: BA_fnc_navigateLookoutMenu
 * Navigate up/down in the lookout menu with wraparound.
 *
 * Arguments:
 *   0: STRING - "up" or "down"
 *
 * Return Value:
 *   None
 *
 * Example:
 *   ["up"] call BA_fnc_navigateLookoutMenu;
 *   ["down"] call BA_fnc_navigateLookoutMenu;
 */

params ["_direction"];

if (!BA_lookoutMenuActive) exitWith {};

private _count = count BA_lookoutMenuItems;
if (_count == 0) exitWith {};

if (_direction == "up") then {
    BA_lookoutMenuIndex = BA_lookoutMenuIndex - 1;
    if (BA_lookoutMenuIndex < 0) then {
        BA_lookoutMenuIndex = _count - 1;
    };
} else {
    BA_lookoutMenuIndex = BA_lookoutMenuIndex + 1;
    if (BA_lookoutMenuIndex >= _count) then {
        BA_lookoutMenuIndex = 0;
    };
};

private _item = BA_lookoutMenuItems select BA_lookoutMenuIndex;
[format ["%1 of %2. %3.", BA_lookoutMenuIndex + 1, _count, _item select 0]] call BA_fnc_speak;
