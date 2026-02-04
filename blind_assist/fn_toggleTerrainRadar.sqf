/*
 * Function: BA_fnc_toggleTerrainRadar
 * Toggles the terrain radar audio system on/off.
 *
 * The terrain radar scans a 90-degree arc in front of the player and produces
 * spatial audio beeps indicating obstacles and terrain. It is mutually exclusive
 * with aim assist - only one can be active at a time.
 *
 * Toggle: Ctrl+W (when observer mode is OFF)
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   Boolean - true if terrain radar is now enabled, false if disabled
 *
 * Example:
 *   [] call BA_fnc_toggleTerrainRadar;
 */

// Initialize if needed
if (isNil "BA_terrainRadarEnabled") then {
    [] call BA_fnc_initTerrainRadar;
};

if (BA_terrainRadarEnabled) then {
    // Disable terrain radar
    BA_terrainRadarEnabled = false;

    // Stop the audio
    "nvda_arma3_bridge" callExtension "radar_stop";

    // Remove the per-frame update handler
    if (BA_terrainRadarEHId >= 0) then {
        removeMissionEventHandler ["EachFrame", BA_terrainRadarEHId];
        BA_terrainRadarEHId = -1;
    };

    // Reset state
    BA_terrainRadarSweepStart = 0;
    BA_terrainRadarLastSample = -1;

    ["Terrain radar disabled."] call BA_fnc_speak;
    diag_log "Blind Assist: Terrain radar disabled";

    false
} else {
    // Check for mutual exclusion with aim assist
    if (!isNil "BA_aimAssistEnabled" && {BA_aimAssistEnabled}) then {
        ["Disable aim assist first."] call BA_fnc_speak;
        false
    } else {
        // Enable terrain radar
        BA_terrainRadarEnabled = true;

        // Start the audio system
        private _result = "nvda_arma3_bridge" callExtension "radar_start";

        if (_result == "OK") then {
            // Initialize sweep state
            BA_terrainRadarSweepStart = diag_tickTime;
            BA_terrainRadarLastSample = -1;

            // Add per-frame update handler
            BA_terrainRadarEHId = addMissionEventHandler ["EachFrame", {
                [] call BA_fnc_updateTerrainRadar;
            }];

            ["Terrain radar enabled."] call BA_fnc_speak;
            diag_log "Blind Assist: Terrain radar enabled";

            true
        } else {
            // Audio init failed
            BA_terrainRadarEnabled = false;
            ["Terrain radar audio failed to initialize."] call BA_fnc_speak;
            diag_log format ["Blind Assist: Terrain radar audio init failed: %1", _result];

            false
        };
    };
};
