/*
 * Function: BA_fnc_updateAimAssist
 * Per-frame update loop for aim assist audio feedback.
 *
 * This is called from an EachFrame event handler.
 * It throttles updates to 20Hz (50ms intervals) for performance.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_updateAimAssist;
 */

// Skip if not enabled
if (!BA_aimAssistEnabled) exitWith {};

// Throttle updates to 20Hz
private _now = diag_tickTime;
if (_now - BA_aimAssistLastUpdate < BA_aimAssistUpdateInterval) exitWith {};
BA_aimAssistLastUpdate = _now;

// Determine which unit is "the soldier" for aiming
// In observer mode: use BA_originalUnit (the AI-controlled soldier)
// In manual mode: use player
private _soldier = if (BA_observerMode) then {
    BA_originalUnit
} else {
    player
};

// Validate soldier
if (isNull _soldier || !alive _soldier) exitWith {
    // Soldier dead/invalid - mute
    "nvda_arma3_bridge" callExtension "aim_update:0,-1,0";
};

// Store previous target for state change detection
private _previousTarget = BA_aimAssistTarget;

// Find target (refresh every frame to track movement and new enemies)
private _target = [_soldier] call BA_fnc_findAimTarget;

if (isNull _target) then {
    // No valid target - mute the tone
    "nvda_arma3_bridge" callExtension "aim_update:0,-1,0";

    // Announce based on what happened to the target
    if (!isNull _previousTarget) then {
        if (BA_aimAssistTargetDeathType == "player") then {
            ["Target killed."] call BA_fnc_speak;
        } else {
            if (BA_aimAssistTargetDeathType == "other") then {
                ["Target down."] call BA_fnc_speak;
            } else {
                ["Target lost."] call BA_fnc_speak;
            };
        };
    };

    // Remove event handlers when target is lost
    if (!isNull BA_aimAssistHitTarget) then {
        if (BA_aimAssistHitEH >= 0) then {
            BA_aimAssistHitTarget removeEventHandler ["Hit", BA_aimAssistHitEH];
            BA_aimAssistHitEH = -1;
        };
        if (BA_aimAssistKilledEH >= 0) then {
            BA_aimAssistHitTarget removeEventHandler ["Killed", BA_aimAssistKilledEH];
            BA_aimAssistKilledEH = -1;
        };
        BA_aimAssistHitTarget = objNull;
    };

    // Reset state
    BA_aimAssistTarget = objNull;
    BA_aimAssistTargetDeathType = "";
} else {
    // Announce new or changed target
    if (_target != _previousTarget) then {
        private _type = getText (configFile >> "CfgVehicles" >> typeOf _target >> "displayName");
        private _dist = round (_soldier distance _target);
        [format ["Targeting %1, %2 meters.", _type, _dist]] call BA_fnc_speak;
    };

    // Update target reference
    BA_aimAssistTarget = _target;

    // Ensure hit tracking variables are initialized (in case mission was reloaded)
    if (isNil "BA_aimAssistHitTarget") then { BA_aimAssistHitTarget = objNull; };
    if (isNil "BA_aimAssistHitEH") then { BA_aimAssistHitEH = -1; };
    if (isNil "BA_aimAssistKilledEH") then { BA_aimAssistKilledEH = -1; };
    if (isNil "BA_aimAssistTargetDeathType") then { BA_aimAssistTargetDeathType = ""; };

    // Manage hit and killed detection event handlers
    if (_target != BA_aimAssistHitTarget) then {
        // Remove old handlers
        if (!isNull BA_aimAssistHitTarget) then {
            if (BA_aimAssistHitEH >= 0) then {
                BA_aimAssistHitTarget removeEventHandler ["Hit", BA_aimAssistHitEH];
                BA_aimAssistHitEH = -1;
            };
            if (BA_aimAssistKilledEH >= 0) then {
                BA_aimAssistHitTarget removeEventHandler ["Killed", BA_aimAssistKilledEH];
                BA_aimAssistKilledEH = -1;
            };
        };

        // Reset death type for new target
        BA_aimAssistTargetDeathType = "";

        // Add hit handler to new target
        BA_aimAssistHitEH = _target addEventHandler ["Hit", {
            params ["_unit", "_source", "_damage", "_instigator"];
            private _shooter = if (BA_observerMode) then { BA_originalUnit } else { player };
            if (_instigator == _shooter || _source == _shooter) then {
                ["hit"] call BA_fnc_speak;
            };
        }];

        // Add killed handler to detect how target died
        BA_aimAssistKilledEH = _target addEventHandler ["Killed", {
            params ["_unit", "_killer", "_instigator", "_useEffects"];
            private _shooter = if (BA_observerMode) then { BA_originalUnit } else { player };
            if (_instigator == _shooter || _killer == _shooter) then {
                BA_aimAssistTargetDeathType = "player";
            } else {
                BA_aimAssistTargetDeathType = "other";
            };
        }];

        BA_aimAssistHitTarget = _target;
    };

    // Calculate audio parameters
    private _params = [_soldier, _target] call BA_fnc_calculateAimOffset;
    _params params ["_pan", "_pitch", "_locked"];

    // Send to DLL
    // Format: "aim_update:pan,pitch,locked"
    private _cmd = format ["aim_update:%1,%2,%3", _pan, _pitch, _locked];
    "nvda_arma3_bridge" callExtension _cmd;
};
