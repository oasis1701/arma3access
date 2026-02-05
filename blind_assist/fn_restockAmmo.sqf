/*
 * Function: BA_fnc_restockAmmo
 * Restocks a specific magazine type to the specified count.
 *
 * Removes existing magazines of this type and adds the requested number.
 *
 * Arguments:
 *   0: STRING - Magazine class name
 *   1: NUMBER - Number of magazines to set
 *
 * Return Value:
 *   None
 *
 * Example:
 *   ["30Rnd_65x39_caseless_mag", 6] call BA_fnc_restockAmmo;
 */

params ["_magazineClass", "_count"];

// Validate parameters
if (_magazineClass == "") exitWith {
    ["No magazine type available."] call BA_fnc_speak;
};

if (_count < 1) exitWith {
    ["Invalid magazine count."] call BA_fnc_speak;
};

// Determine target unit
private _unit = if (BA_observerMode && !isNull BA_originalUnit) then {
    BA_originalUnit
} else {
    player
};

// Remove all existing magazines of this type
_unit removeMagazines _magazineClass;

// Add the requested number of magazines
for "_i" from 1 to _count do {
    _unit addMagazine _magazineClass;
};

// Get weapon name for announcement
private _magText = if (_count == 1) then { "magazine" } else { "magazines" };
[format ["Restocked %1 to %2 %3.", BA_selectedWeaponName, _count, _magText]] call BA_fnc_speak;
