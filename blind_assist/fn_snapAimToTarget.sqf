/*
 * Function: BA_fnc_snapAimToTarget
 * Locks horizontal aim to the current aim assist target.
 *
 * Press T to lock horizontal aim to target.
 * Press T again to release.
 *
 * Note: Vertical aim control is not possible due to Arma 3 engine limitations.
 * Script-based vertical aim requires tilting the player model, causing
 * leg clipping, floating, and multiplayer jitter issues.
 *
 * Hotkey: T (requires aim assist enabled with valid target)
 */

// Initialize state if needed
if (isNil "BA_snapAimActive") then { BA_snapAimActive = false };

// If already tracking, toggle off
if (BA_snapAimActive) exitWith {
    onEachFrame {};
    BA_snapAimActive = false;
    BA_snapTarget = objNull;
    ["Aim released."] call BA_fnc_speak;
    true
};

// --- Validation ---

if (!BA_aimAssistEnabled) exitWith {
    ["Aim assist not active."] call BA_fnc_speak;
    false
};

if (isNull BA_aimAssistTarget || !alive BA_aimAssistTarget) exitWith {
    ["No target."] call BA_fnc_speak;
    false
};

if (BA_observerMode) exitWith {
    ["Snap aim only in manual mode."] call BA_fnc_speak;
    false
};

if (!alive player) exitWith {
    ["Soldier not available."] call BA_fnc_speak;
    false
};

if (vehicle player != player) exitWith {
    ["Cannot snap aim in vehicle."] call BA_fnc_speak;
    false
};

// --- Setup ---

BA_snapTarget = BA_aimAssistTarget;
BA_snapAimActive = true;

private _distance = round (player distance BA_snapTarget);
private _type = if (BA_snapTarget isKindOf "Man") then { "infantry" }
    else { if (BA_snapTarget isKindOf "Air") then { "aircraft" }
    else { if (BA_snapTarget isKindOf "Tank") then { "armor" }
    else { "vehicle" } } };

// Set up horizontal tracking
onEachFrame {
    // Safety checks
    if (isNil "BA_snapTarget" || {isNull BA_snapTarget} || {!alive BA_snapTarget} || {!alive player}) exitWith {
        onEachFrame {};
        BA_snapAimActive = false;
        BA_snapTarget = objNull;
        ["Target lost."] call BA_fnc_speak;
    };

    if (vehicle player != player) exitWith {
        onEachFrame {};
        BA_snapAimActive = false;
        BA_snapTarget = objNull;
    };

    if (!BA_snapAimActive) exitWith {
        onEachFrame {};
    };

    // Calculate direction to target (horizontal only)
    private _playerPos = getPos player;
    private _targetPos = getPos BA_snapTarget;

    // Get horizontal direction (azimuth) from player to target
    private _dir = _playerPos getDir _targetPos;

    // Apply horizontal direction only
    player setDir _dir;
};

[format ["Tracking %1, %2 meters.", _type, _distance]] call BA_fnc_speak;

true
