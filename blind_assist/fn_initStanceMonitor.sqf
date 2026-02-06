/*
 * fn_initStanceMonitor.sqf - Initialize stance change announcements
 *
 * Monitors the player's stance and announces changes via NVDA.
 * Works in both direct control and observer mode.
 *
 * Usage: [] call BA_fnc_initStanceMonitor;
 */

// Track previous stance (empty = first check, skip announcement)
BA_lastStance = "";

// Throttle to 4Hz
BA_lastStanceCheckTime = 0;
BA_stanceCheckInterval = 0.25;

// Remove existing handler if re-initializing
if (!isNil "BA_stanceMonitorEHId") then {
    removeMissionEventHandler ["EachFrame", BA_stanceMonitorEHId];
};

BA_stanceMonitorEHId = addMissionEventHandler ["EachFrame", {
    [] call BA_fnc_updateStanceMonitor;
}];
