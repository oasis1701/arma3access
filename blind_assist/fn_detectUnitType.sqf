/*
 * Function: BA_fnc_detectUnitType
 * Detects the category of a unit for order menu purposes.
 *
 * Detection priority:
 *   1. Artillery - Has artillery scanner capability
 *   2. Static Weapon - Mounted gun emplacements
 *   3. Helicopter - Rotary wing aircraft
 *   4. Jet - Fixed wing aircraft
 *   5. Armed Vehicle - Land vehicle with weapons
 *   6. Unarmed Vehicle - Land vehicle without weapons
 *   7. Infantry - Default for soldiers
 *
 * Arguments:
 *   0: Unit to classify <OBJECT>
 *
 * Return Value:
 *   Unit type string: "artillery", "static", "helicopter", "jet", "armed_vehicle", "unarmed_vehicle", or "infantry"
 *
 * Example:
 *   private _type = [_unit] call BA_fnc_detectUnitType;
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith { "infantry" };

private _type = "infantry";

// Get the vehicle if unit is in one
private _vehicle = vehicle _unit;

// If unit is on foot, return infantry
if (_vehicle == _unit) exitWith { "infantry" };

// Check vehicle type in priority order

// 1. Artillery - check for artillery scanner capability
private _artilleryScanner = getNumber (configFile >> "CfgVehicles" >> typeOf _vehicle >> "artilleryScanner");
if (_artilleryScanner == 1) exitWith { "artillery" };

// 2. Static Weapon
if (_vehicle isKindOf "StaticWeapon") exitWith { "static" };

// 3. Helicopter
if (_vehicle isKindOf "Helicopter") exitWith { "helicopter" };

// 4. Jet/Plane
if (_vehicle isKindOf "Plane") exitWith { "jet" };

// 5/6. Land Vehicle - check if armed or unarmed
if (_vehicle isKindOf "LandVehicle") exitWith {
    private _weapons = weapons _vehicle;
    // Filter out non-combat items (like horns)
    _weapons = _weapons select {!("horn" in toLower _x)};
    if (count _weapons > 0) then {
        "armed_vehicle"
    } else {
        "unarmed_vehicle"
    };
};

// 7. Default to infantry
"infantry"
