/*
 * fn_initEnemyDetection.sqf - Initialize automatic enemy detection announcements
 *
 * Automatically announces newly detected enemies with distance, type, and direction.
 * Uses Arma's nearTargets command - only announces enemies the soldier is aware of.
 * Always active in both player mode and observer mode.
 *
 * Format: "50 meters, Rifleman, northeast"
 */

// Track announced enemies to avoid repeat announcements
BA_detectedEnemies = [];

// Handler ID for cleanup
BA_enemyDetectionEHId = -1;

// Throttle settings (2Hz = every 0.5 seconds)
BA_lastEnemyDetectionTime = 0;
BA_enemyDetectionInterval = 0.5;

// Register the EachFrame handler (always active)
BA_enemyDetectionEHId = addMissionEventHandler ["EachFrame", {
    [] call BA_fnc_updateEnemyDetection;
}];
