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

    // Announce target lost if we had one before
    if (!isNull _previousTarget) then {
        ["Target lost."] call BA_fnc_speak;
    };

    BA_aimAssistTarget = objNull;
} else {
    // Announce new or changed target
    if (_target != _previousTarget) then {
        private _type = getText (configFile >> "CfgVehicles" >> typeOf _target >> "displayName");
        private _dist = round (_soldier distance _target);
        [format ["Targeting %1, %2 meters.", _type, _dist]] call BA_fnc_speak;
    };

    // Update target reference
    BA_aimAssistTarget = _target;

    // Calculate audio parameters
    private _params = [_soldier, _target] call BA_fnc_calculateAimOffset;
    _params params ["_pan", "_pitch", "_locked"];

    // Send to DLL
    // Format: "aim_update:pan,pitch,locked"
    private _cmd = format ["aim_update:%1,%2,%3", _pan, _pitch, _locked];
    "nvda_arma3_bridge" callExtension _cmd;
};
