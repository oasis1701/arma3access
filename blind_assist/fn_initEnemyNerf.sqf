/*
 * fn_initEnemyNerf.sqf - Initialize passive enemy skill nerf
 *
 * Automatically reduces aiming skill of enemies that detect the player.
 * Blind players can't see or dodge incoming fire, so this gives them
 * more survivability by making aware enemies less accurate.
 *
 * Always active - no toggle needed.
 */

// Track already-nerfed enemies to avoid redundant setSkill calls
BA_nerfedEnemies = [];

// Clean up old handler if re-initializing (save game load safety)
if (!isNil "BA_enemyNerfEHId" && {BA_enemyNerfEHId >= 0}) then {
    removeMissionEventHandler ["EachFrame", BA_enemyNerfEHId];
};

// Handler ID for cleanup
BA_enemyNerfEHId = -1;

// Throttle settings (1Hz = every 1 second)
BA_lastEnemyNerfTime = 0;
BA_enemyNerfInterval = 1;

// Register the EachFrame handler (always active)
BA_enemyNerfEHId = addMissionEventHandler ["EachFrame", {
    [] call BA_fnc_updateEnemyNerf;
}];
