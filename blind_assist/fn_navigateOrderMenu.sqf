/*
 * Function: BA_fnc_navigateOrderMenu
 * Navigates up or down in the order menu with wraparound.
 *
 * Arguments:
 *   0: Direction - "up" or "down" <STRING>
 *
 * Return Value:
 *   None
 *
 * Example:
 *   ["down"] call BA_fnc_navigateOrderMenu;
 */

params [["_direction", "down", [""]]];

// Must have menu active
if (!BA_orderMenuActive) exitWith {};
if (count BA_orderMenuItems == 0) exitWith {};

private _count = count BA_orderMenuItems;

// Navigate with wraparound
if (_direction == "up") then {
    BA_orderMenuIndex = BA_orderMenuIndex - 1;
    if (BA_orderMenuIndex < 0) then {
        BA_orderMenuIndex = _count - 1;
    };
} else {
    BA_orderMenuIndex = BA_orderMenuIndex + 1;
    if (BA_orderMenuIndex >= _count) then {
        BA_orderMenuIndex = 0;
    };
};

// Announce current item (1-based for user)
private _item = BA_orderMenuItems select BA_orderMenuIndex;
private _label = _item select 0;
private _message = format["%1. %2", BA_orderMenuIndex + 1, _label];

[_message] call BA_fnc_speak;
