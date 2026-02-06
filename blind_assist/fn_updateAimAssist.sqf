/*
 * Function: BA_fnc_updateAimAssist
 * Per-frame update loop for aim assist audio feedback.
 *
 * This is called from an EachFrame event handler.
 * It throttles updates to 20Hz (50ms intervals) for performance.
 *
 * Uses a grace period state machine to avoid flicker:
 * - Target valid + LOS:     Track normally, reset grace timer
 * - Target valid + no LOS:  Grace period (1.5s) - keep tracking silently
 * - Target invalid:          Immediate loss (no grace)
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

// Find target with stickiness (pass current target so it checks that first)
private _findResult = [_soldier, BA_aimAssistTarget] call BA_fnc_findAimTarget;
_findResult params ["_target", "_hasLOS"];

// --- Grace period state machine ---

if (!isNull _target) then {
    // We have a valid target (alive, hostile, in range, known)

    if (_hasLOS) then {
        // LOS is clear - reset grace, track normally
        BA_aimAssistGraceStart = -1;
        BA_aimAssistHasLOS = true;
    } else {
        // No LOS but target is still valid - enter/continue grace period
        if (BA_aimAssistHasLOS) then {
            // Just lost LOS - start grace timer
            BA_aimAssistGraceStart = _now;
            BA_aimAssistHasLOS = false;
        };

        // Check if grace period has expired
        if (BA_aimAssistGraceStart > 0 && {_now - BA_aimAssistGraceStart >= BA_aimAssistGraceDuration}) then {
            // Grace expired - declare target lost
            _target = objNull;
            _hasLOS = false;
        };
        // Otherwise grace is still active - continue tracking (below)
    };
} else {
    // Target invalid (dead, out of range, friendly, unknown) - immediate loss
    BA_aimAssistGraceStart = -1;
    BA_aimAssistHasLOS = true;
};

// --- Handle target state ---

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
    BA_aimAssistWasVertLocked = false;
    BA_aimAssistGraceStart = -1;
    BA_aimAssistHasLOS = true;
} else {
    // Announce new or changed target (only when we have LOS for initial acquisition)
    if (_target != _previousTarget) then {
        private _type = getText (configFile >> "CfgVehicles" >> typeOf _target >> "displayName");
        private _dist = round (_soldier distance _target);
        [format ["Targeting %1, %2 meters.", _type, _dist]] call BA_fnc_speak;

        // Auto-snap if auto-lock mode is enabled (only in manual mode, not observer)
        if (!isNil "BA_autoLockEnabled" && {BA_autoLockEnabled} && {!BA_observerMode}) then {
            // Store target for tracking
            BA_snapTarget = _target;

            // Set up continuous horizontal tracking
            onEachFrame {
                // Safety checks
                if (isNil "BA_snapTarget" || {isNull BA_snapTarget} || {!alive BA_snapTarget} || {!alive player}) exitWith {
                    onEachFrame {};
                    BA_snapTarget = objNull;
                };

                if (vehicle player != player) exitWith {
                    onEachFrame {};
                    BA_snapTarget = objNull;
                };

                // Stop if auto-lock disabled
                if (isNil "BA_autoLockEnabled" || {!BA_autoLockEnabled}) exitWith {
                    onEachFrame {};
                };

                // Calculate and apply horizontal direction
                private _playerPos = getPos player;
                private _targetPos = getPos BA_snapTarget;
                player setDir (_playerPos getDir _targetPos);
            };
        };

        // Reset lock state for new target
        BA_aimAssistWasVertLocked = false;
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
    _params params ["_pan", "_pitch", "_vertError", "_horizError", "_vertThreshold", "_horizThreshold"];

    // Detect vertical lock transitions and play blips
    private _vertLocked = _vertError < _vertThreshold;
    if (_vertLocked && !BA_aimAssistWasVertLocked) then {
        "nvda_arma3_bridge" callExtension "aim_blip";         // Lock: 800 Hz
    };
    if (!_vertLocked && BA_aimAssistWasVertLocked) then {
        "nvda_arma3_bridge" callExtension "aim_unlock_blip";  // Unlock: 500 Hz
    };
    BA_aimAssistWasVertLocked = _vertLocked;

    // Send to DLL
    // Format: "aim_update:pan,pitch,vertError,horizError,vertThreshold,horizThreshold"
    private _cmd = format ["aim_update:%1,%2,%3,%4,%5,%6", _pan, _pitch, _vertError, _horizError, _vertThreshold, _horizThreshold];
    "nvda_arma3_bridge" callExtension _cmd;
};
