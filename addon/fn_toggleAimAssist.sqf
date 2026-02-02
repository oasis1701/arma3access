/*
 * Function: BA_fnc_toggleAimAssist
 * Toggles the aim assist audio system on/off.
 *
 * When enabled, a continuous tone provides aiming guidance:
 * - Stereo panning (left/right ear) indicates turn direction
 * - Pitch (Hz) indicates look up/down direction
 * - Tone changes from sine to square wave when locked on target
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   Boolean - true if aim assist is now enabled, false if disabled
 *
 * Example:
 *   [] call BA_fnc_toggleAimAssist;
 */

// Initialize if needed
if (isNil "BA_aimAssistEnabled") then {
    [] call BA_fnc_initAimAssist;
};

if (BA_aimAssistEnabled) then {
    // Disable aim assist
    BA_aimAssistEnabled = false;

    // Stop the audio tone
    "nvda_arma3_bridge" callExtension "aim_stop";

    // Remove the per-frame update handler
    if (BA_aimAssistEHId >= 0) then {
        removeMissionEventHandler ["EachFrame", BA_aimAssistEHId];
        BA_aimAssistEHId = -1;
    };

    // Clear target
    BA_aimAssistTarget = objNull;

    ["Aim assist disabled."] call BA_fnc_speak;
    diag_log "Blind Assist: Aim assist disabled";

    false
} else {
    // Enable aim assist
    BA_aimAssistEnabled = true;

    // Start the audio system (starts muted)
    private _result = "nvda_arma3_bridge" callExtension "aim_start";

    if (_result == "OK") then {
        // Add per-frame update handler
        BA_aimAssistEHId = addMissionEventHandler ["EachFrame", {
            [] call BA_fnc_updateAimAssist;
        }];

        ["Aim assist enabled."] call BA_fnc_speak;
        diag_log "Blind Assist: Aim assist enabled";

        true
    } else {
        // Audio init failed
        BA_aimAssistEnabled = false;
        ["Aim assist audio failed to initialize."] call BA_fnc_speak;
        diag_log format ["Blind Assist: Aim assist audio init failed: %1", _result];

        false
    };
};
