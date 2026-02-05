/*
 * Function: BA_fnc_getWeaponMagazineInfo
 * Gets the compatible magazine class and current count for a weapon.
 *
 * Arguments:
 *   0: OBJECT - The unit to check
 *   1: STRING - The weapon class name
 *
 * Return Value:
 *   ARRAY - [magazineClass, currentCount]
 *           magazineClass is "" if no compatible magazine found
 *
 * Example:
 *   [player, primaryWeapon player] call BA_fnc_getWeaponMagazineInfo;
 *   // Returns: ["30Rnd_65x39_caseless_mag", 6]
 */

params ["_unit", "_weaponClass"];

diag_log format ["BA_DEBUG: getWeaponMagazineInfo called for weapon %1", _weaponClass];

// Get list of compatible magazines for this weapon
private _compatibleMags = getArray (configFile >> "CfgWeapons" >> _weaponClass >> "magazines");
diag_log format ["BA_DEBUG: Compatible mags = %1", _compatibleMags];

if (count _compatibleMags == 0) exitWith {
    ["", 0]
};

// Get all magazines the unit is carrying
private _unitMags = magazines _unit;

// Count how many of each compatible magazine type the unit has
private _bestMag = "";
private _bestCount = 0;

{
    private _magClass = _x;
    private _count = {_x == _magClass} count _unitMags;

    // Use the first compatible mag we find, or the one with highest count
    if (_count > 0 && (_bestMag == "" || _count > _bestCount)) then {
        _bestMag = _magClass;
        _bestCount = _count;
    };

    // If we haven't found any yet, store the first compatible as default
    if (_bestMag == "" && _forEachIndex == 0) then {
        _bestMag = _magClass;
    };
} forEach _compatibleMags;

// If no mags found in inventory, use first compatible type
if (_bestMag == "") then {
    _bestMag = _compatibleMags select 0;
};

[_bestMag, _bestCount]
