/*
 * Function: BA_fnc_snapAimToTarget
 * Toggles auto-lock mode for aim assist.
 *
 * When auto-lock is ON:
 * - As soon as aim assist acquires a target, horizontal aim auto-snaps to it
 * - Continues tracking as target moves
 * - If target lost and new target acquired, snaps to new target
 *
 * When auto-lock is OFF:
 * - Normal aim assist (audio only, no auto-snap)
 *
 * Note: Vertical aim control not possible due to Arma 3 engine limitations.
 *
 * Hotkey: T
 */

// Initialize if needed
if (isNil "BA_autoLockEnabled") then { BA_autoLockEnabled = false };

// Toggle auto-lock mode
BA_autoLockEnabled = !BA_autoLockEnabled;

if (BA_autoLockEnabled) then {
    ["Target lock on."] call BA_fnc_speak;
} else {
    ["Target lock off."] call BA_fnc_speak;
    // Stop any active tracking
    onEachFrame {};
};

true
