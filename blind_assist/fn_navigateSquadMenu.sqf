/*
 * Function: BA_fnc_navigateSquadMenu
 * Navigates up or down in the squad member menu with wraparound.
 *
 * Arguments:
 *   0: Direction - "up" or "down" <STRING>
 *
 * Return Value:
 *   None
 *
 * Example:
 *   ["down"] call BA_fnc_navigateSquadMenu;
 */

params [["_direction", "down", [""]]];

if (!BA_squadMenuActive) exitWith {};
if (count BA_squadMenuItems == 0) exitWith {};

private _count = count BA_squadMenuItems;

// Navigate with wraparound
if (_direction == "up") then {
    BA_squadMenuIndex = BA_squadMenuIndex - 1;
    if (BA_squadMenuIndex < 0) then {
        BA_squadMenuIndex = _count - 1;
    };
} else {
    BA_squadMenuIndex = BA_squadMenuIndex + 1;
    if (BA_squadMenuIndex >= _count) then {
        BA_squadMenuIndex = 0;
    };
};

// Announce current item
private _desc = BA_squadMenuDescs select BA_squadMenuIndex;
private _message = format["%1 of %2. %3", BA_squadMenuIndex + 1, _count, _desc];
[_message] call BA_fnc_speak;
