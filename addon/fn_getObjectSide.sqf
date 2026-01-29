/*
 * Function: BA_fnc_getObjectSide
 * Returns a human-readable side description based on object's relation to player.
 *
 * Arguments:
 *   0: _object - Object to check side for
 *
 * Return Value:
 *   String - "friendly", "enemy", "neutral", "civilian", or "empty"
 *
 * Example:
 *   [_unit] call BA_fnc_getObjectSide;
 *   // Returns: "enemy"
 */

params [["_object", objNull, [objNull]]];

if (isNull _object) exitWith { "unknown" };

// For vehicles, check if empty first
if (_object isKindOf "AllVehicles" && !(_object isKindOf "Man")) then {
    if (count crew _object == 0) exitWith { "empty" };
};

// Get the side of the object
private _objectSide = side _object;

// Handle objects with no side (civilian objects, etc.)
if (_objectSide == sideUnknown || _objectSide == sideEmpty) exitWith {
    // Check if it's a vehicle
    if (_object isKindOf "AllVehicles" && !(_object isKindOf "Man")) exitWith { "empty" };
    "unknown"
};

// Get player's side for comparison
private _playerSide = side player;

// Compare sides
if (_objectSide == civilian) exitWith { "civilian" };

if (_objectSide == _playerSide) exitWith { "friendly" };

// Check if enemy (opposing sides)
private _isFriendly = [_playerSide, _objectSide] call BIS_fnc_sideIsFriendly;
if (_isFriendly) exitWith { "friendly" };

// If not friendly and not same side, it's an enemy
"enemy"
