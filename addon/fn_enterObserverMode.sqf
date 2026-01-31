/*
 * Function: BA_fnc_enterObserverMode
 * Enters observer mode - AI takes control of the player's soldier.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   Boolean - true if successfully entered observer mode
 *
 * Example:
 *   [] call BA_fnc_enterObserverMode;
 */

// Don't enter if already in observer mode
if (BA_observerMode) exitWith {
    ["Already in observer mode."] call BA_fnc_speak;
    false
};

// Store reference to original player unit
BA_originalUnit = player;
BA_observedUnit = player;
BA_currentGroup = group player;
BA_currentUnitIndex = (units BA_currentGroup) find player;

// Get side name
private _side = side BA_originalUnit;
private _sideName = switch (_side) do {
    case west: { "Blufor" };
    case east: { "Opfor" };
    case independent: { "Independent" };
    case civilian: { "Civilian" };
    default { "Unknown" };
};

// Get group name
private _groupName = groupId BA_currentGroup;

// Get unit type for announcement
private _unitType = getText (configFile >> "CfgVehicles" >> typeOf BA_originalUnit >> "displayName");
if (_unitType == "") then { _unitType = "Soldier"; };

// Create a temporary group on the player's side for the ghost
private _playerSide = side BA_originalUnit;
BA_ghostGroup = createGroup [_playerSide, true]; // true = delete when empty

// Create invisible ghost unit (hidden soldier for correct side)
// Using soldier class ensures side player returns correct side
private _ghostPos = getPosASL BA_originalUnit;
private _ghostClass = switch (_playerSide) do {
    case west: { "B_Soldier_unarmed_F" };
    case east: { "O_Soldier_unarmed_F" };
    case independent: { "I_Soldier_unarmed_F" };
    default { "C_man_1" };
};
BA_ghostUnit = BA_ghostGroup createUnit [_ghostClass, ASLToATL _ghostPos, [], 0, "NONE"];
BA_ghostUnit hideObjectGlobal true;       // Completely invisible
BA_ghostUnit allowDamage false;           // Cannot be damaged
// NOTE: Do NOT use setCaptive - it changes side to CIV
BA_ghostUnit disableAI "ALL";             // No AI behavior
BA_ghostUnit enableSimulation false;      // No physics/collision

BA_ghostUnit setPosASL _ghostPos;

// Copy all variables from original unit to ghost BEFORE selectPlayer
// This ensures player getVariable works immediately after entering observer mode
private _allVars = allVariables BA_originalUnit;
{
    private _value = BA_originalUnit getVariable _x;
    BA_ghostUnit setVariable [_x, _value];
} forEach _allVars;

// Switch player control to ghost - original unit becomes AI-controlled
selectPlayer BA_ghostUnit;

// Initialize edge case monitoring flags
BA_warnedIncapacitated = false;
BA_warnedCaptive = false;
BA_lastObservedVehicle = vehicle BA_observedUnit;

// Start sync loop to keep ghost at original unit and sync variables
BA_ghostSyncHandle = [] spawn {
    while {BA_observerMode} do {
        if (!isNull BA_originalUnit && alive BA_originalUnit && !isNull BA_ghostUnit) then {
            // Position ghost at original unit (so distance/area checks work)
            BA_ghostUnit setPosASL (getPosASL BA_originalUnit);

            // Sync variables: original unit -> ghost (so player getVariable works)
            // Note: Must check isNil because getVariable can return nil, making local var undefined
            private _origVars = allVariables BA_originalUnit;
            {
                private _varName = _x;
                if (!isNil {BA_originalUnit getVariable _varName}) then {
                    BA_ghostUnit setVariable [_varName, BA_originalUnit getVariable _varName];
                };
            } forEach _origVars;

            // Sync variables: ghost -> original unit (in case scripts SET on player)
            private _ghostVars = allVariables BA_ghostUnit;
            {
                private _varName = _x;
                if (!isNil {BA_ghostUnit getVariable _varName}) then {
                    BA_originalUnit setVariable [_varName, BA_ghostUnit getVariable _varName];
                };
            } forEach _ghostVars;

            // === Edge Case Monitoring ===

            // Check soldier's life state (unconsciousness from explosions, ACE3 medical, etc.)
            private _state = lifeState BA_originalUnit;
            if (_state == "INCAPACITATED" && !BA_warnedIncapacitated) then {
                ["Warning. Soldier is unconscious."] call BA_fnc_speak;
                BA_warnedIncapacitated = true;
            };
            if (_state != "INCAPACITATED") then {
                BA_warnedIncapacitated = false;
            };

            // Check if soldier is captive (handcuffed by ACE3/Antistasi/etc.)
            if (captive BA_originalUnit && !BA_warnedCaptive) then {
                ["Warning. Soldier is captive. Cannot issue orders."] call BA_fnc_speak;
                BA_warnedCaptive = true;
            };
            if (!captive BA_originalUnit) then {
                BA_warnedCaptive = false;
            };
        };

        // Check if observed unit changed vehicles (ejection, dismount)
        if (!isNull BA_observedUnit && alive BA_observedUnit) then {
            private _currentVehicle = vehicle BA_observedUnit;
            if (!isNil "BA_lastObservedVehicle" && {_currentVehicle != BA_lastObservedVehicle}) then {
                private _nowInVehicle = _currentVehicle != BA_observedUnit;
                private _wasInVehicle = BA_lastObservedVehicle != BA_observedUnit;

                // Just use switchCamera for all cases - keeps audio consistent
                BA_observedUnit switchCamera "INTERNAL";

                if (_nowInVehicle && !_wasInVehicle) then {
                    private _vehName = getText (configFile >> "CfgVehicles" >> typeOf _currentVehicle >> "displayName");
                    [format["Now in %1.", _vehName]] call BA_fnc_speak;
                } else {
                    if (!_nowInVehicle && _wasInVehicle) then {
                        ["Dismounted."] call BA_fnc_speak;
                    } else {
                        // Changed from one vehicle to another
                        private _vehName = getText (configFile >> "CfgVehicles" >> typeOf _currentVehicle >> "displayName");
                        [format["Now in %1.", _vehName]] call BA_fnc_speak;
                    };
                };
            };
            BA_lastObservedVehicle = _currentVehicle;
        };

        sleep 0.5;
    };
};

// Use switchCamera for consistent first-person view (works for both infantry and vehicles)
BA_observerCamera = objNull; // Not using custom camera anymore
BA_originalUnit switchCamera "INTERNAL";

// Add killed event handler to detect if soldier dies while observing
BA_observerKilledEH = BA_originalUnit addEventHandler ["Killed", {
    params ["_unit", "_killer"];

    if (BA_observerMode) then {
        ["Your soldier has been killed."] call BA_fnc_speak;

        // Exit observer mode immediately so player becomes the dead soldier
        // This triggers Arma's native respawn/death systems (respawn menu, tickets, etc.)
        [] spawn {
            sleep 0.5; // Brief delay for speech to start
            [] call BA_fnc_exitObserverMode;
        };
    };
}];

// Set state
BA_observerMode = true;

// Initialize cursor at player's position
BA_cursorPos = getPos BA_observedUnit;
BA_cursorActive = true;

// Announce to player: Side. Group. Unit type. AI has control.
[format["%1. %2. %3. AI has control.", _sideName, _groupName, _unitType]] call BA_fnc_speak;
systemChat format["Observer Mode: %1 - %2 - %3 - AI has control", _sideName, _groupName, _unitType];

true
