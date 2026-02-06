/*
 * fn_updateStanceMonitor.sqf - Per-frame stance change detection
 *
 * Called from EachFrame handler, throttled to 4Hz.
 * Announces "Standing", "Crouched", or "Prone" when stance changes.
 *
 * Usage: [] call BA_fnc_updateStanceMonitor;
 */

// Throttle to 4Hz
private _now = diag_tickTime;
if (_now - BA_lastStanceCheckTime < BA_stanceCheckInterval) exitWith {};
BA_lastStanceCheckTime = _now;

// Get the relevant unit
private _unit = if (BA_observerMode) then { BA_originalUnit } else { player };

// Safety checks
if (isNull _unit || {!alive _unit}) exitWith {};

// Get current stance
private _stance = stance _unit;

// Skip undefined (vehicle, swimming, dead states)
if (_stance == "UNDEFINED") exitWith {};

// No change
if (_stance == BA_lastStance) exitWith {};

// Skip first check (don't announce initial stance)
if (BA_lastStance == "") exitWith {
    BA_lastStance = _stance;
};

// Map to speech text
private _text = switch (_stance) do {
    case "STAND": { "Standing" };
    case "CROUCH": { "Crouched" };
    case "PRONE": { "Prone" };
    default { "" };
};

if (_text != "") then {
    [_text] call BA_fnc_speak;
};

BA_lastStance = _stance;
