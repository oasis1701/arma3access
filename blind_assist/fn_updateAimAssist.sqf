/*
 * Function: BA_fnc_updateAimAssist
 * Per-frame update loop for aim assist audio feedback.
 *
 * This is called from an EachFrame event handler.
 * It throttles updates to 20Hz (50ms intervals) for performance.
 *
 * Persistent target lock state machine:
 * - TRACKING:   LOS clear, audio playing
 * - GRACE:      LOS just lost (<1s), audio continues (anti-flicker)
 * - HIDDEN:     LOS lost >1s, audio muted, "Target hidden" announced
 * - NO_TARGET:  scanning for new targets
 *
 * Target is only released when:
 * 1. Target is killed (announce "Target killed"/"Target down")
 * 2. Target leaves range or becomes unknown (announce "Target lost")
 * 3. Player presses Tab (handled in fn_initObserverMode.sqf)
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
private _soldierSide = side _soldier;

// --- Determine target and LOS ---

private _target = objNull;
private _hasLOS = false;

if (!isNull BA_aimAssistTarget) then {
    // We have a locked target — check if it's still valid (alive, hostile, in range, known)
    private _t = BA_aimAssistTarget;
    if (alive _t
        && {_soldierSide getFriend (side _t) < 0.6}
        && {_soldier knowsAbout _t >= BA_aimAssistMinKnowledge}
        && {_soldier distance _t <= BA_aimAssistMaxRange}
    ) then {
        // Target still valid — keep it locked, check LOS via findAimTarget's stickiness
        private _findResult = [_soldier, _t] call BA_fnc_findAimTarget;
        _findResult params ["_foundTarget", "_foundLOS"];
        // findAimTarget returns the same target with LOS status when sticky check passes
        _target = _t;
        _hasLOS = _foundLOS;
    };
    // If target is invalid (dead/out of range/unknown), _target stays objNull → release below
} else {
    // No locked target — do a full scan for new targets
    private _findResult = [_soldier] call BA_fnc_findAimTarget;
    _findResult params ["_foundTarget", "_foundLOS"];
    _target = _foundTarget;
    _hasLOS = _foundLOS;
};

// --- Persistent target lock state machine ---

if (!isNull _target) then {
    // Target is valid (alive, hostile, in range, known)

    if (_hasLOS) then {
        // --- LOS clear: TRACKING state ---

        if (BA_aimAssistTargetHidden) then {
            // Returning from HIDDEN → announce re-acquisition
            private _type = getText (configFile >> "CfgVehicles" >> typeOf _target >> "displayName");
            private _dist = round (_soldier distance _target);
            [format ["Targeting %1, %2 meters.", _type, _dist]] call BA_fnc_speak;
            BA_aimAssistTargetHidden = false;
        };
        BA_aimAssistGraceStart = -1;  // Reset grace timer

        // Announce new target (first acquisition from NO_TARGET)
        if (_target != _previousTarget) then {
            private _type = getText (configFile >> "CfgVehicles" >> typeOf _target >> "displayName");
            private _dist = round (_soldier distance _target);
            [format ["Targeting %1, %2 meters.", _type, _dist]] call BA_fnc_speak;

            // Auto-snap if auto-lock mode is enabled (only in manual mode, not observer)
            if (!isNil "BA_autoLockEnabled" && {BA_autoLockEnabled} && {!BA_observerMode}) then {
                BA_snapTarget = _target;

                onEachFrame {
                    if (isNil "BA_snapTarget" || {isNull BA_snapTarget} || {!alive BA_snapTarget} || {!alive player}) exitWith {
                        onEachFrame {};
                        BA_snapTarget = objNull;
                    };

                    if (vehicle player != player) exitWith {
                        onEachFrame {};
                        BA_snapTarget = objNull;
                    };

                    if (isNil "BA_autoLockEnabled" || {!BA_autoLockEnabled}) exitWith {
                        onEachFrame {};
                    };

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

        // Calculate audio parameters and send to DLL
        private _params = [_soldier, _target] call BA_fnc_calculateAimOffset;
        _params params ["_pan", "_pitch", "_vertError", "_horizError", "_vertThreshold", "_horizThreshold"];

        // Detect vertical lock transitions and play blips
        private _vertLocked = _vertError < _vertThreshold;
        if (_vertLocked && !BA_aimAssistWasVertLocked) then {
            "nvda_arma3_bridge" callExtension "aim_blip";
        };
        if (!_vertLocked && BA_aimAssistWasVertLocked) then {
            "nvda_arma3_bridge" callExtension "aim_unlock_blip";
        };
        BA_aimAssistWasVertLocked = _vertLocked;

        private _cmd = format ["aim_update:%1,%2,%3,%4,%5,%6", _pan, _pitch, _vertError, _horizError, _vertThreshold, _horizThreshold];
        "nvda_arma3_bridge" callExtension _cmd;

    } else {
        // --- No LOS: GRACE or HIDDEN state ---

        if (!BA_aimAssistTargetHidden) then {
            // Not yet declared hidden — in GRACE period
            if (BA_aimAssistGraceStart < 0) then {
                // Just lost LOS — start grace timer
                BA_aimAssistGraceStart = _now;
            };

            if (BA_aimAssistGraceStart > 0 && {_now - BA_aimAssistGraceStart >= BA_aimAssistGraceDuration}) then {
                // Grace expired → transition to HIDDEN
                ["Target hidden."] call BA_fnc_speak;
                BA_aimAssistTargetHidden = true;
                BA_aimAssistWasVertLocked = false;
            };
        };

        if (BA_aimAssistTargetHidden) then {
            // HIDDEN state — mute audio
            "nvda_arma3_bridge" callExtension "aim_update:0,-1,0";
        } else {
            // GRACE state — keep playing audio (calculate aim params as normal)
            BA_aimAssistTarget = _target;

            private _params = [_soldier, _target] call BA_fnc_calculateAimOffset;
            _params params ["_pan", "_pitch", "_vertError", "_horizError", "_vertThreshold", "_horizThreshold"];

            private _vertLocked = _vertError < _vertThreshold;
            if (_vertLocked && !BA_aimAssistWasVertLocked) then {
                "nvda_arma3_bridge" callExtension "aim_blip";
            };
            if (!_vertLocked && BA_aimAssistWasVertLocked) then {
                "nvda_arma3_bridge" callExtension "aim_unlock_blip";
            };
            BA_aimAssistWasVertLocked = _vertLocked;

            private _cmd = format ["aim_update:%1,%2,%3,%4,%5,%6", _pan, _pitch, _vertError, _horizError, _vertThreshold, _horizThreshold];
            "nvda_arma3_bridge" callExtension _cmd;
        };
    };
} else {
    // --- NO_TARGET state: target invalid (dead, out of range, unknown) ---

    // Mute audio
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

    // Remove event handlers
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

    // Reset state — next frame will do a fresh scan
    BA_aimAssistTarget = objNull;
    BA_aimAssistTargetDeathType = "";
    BA_aimAssistWasVertLocked = false;
    BA_aimAssistGraceStart = -1;
    BA_aimAssistTargetHidden = false;
};
