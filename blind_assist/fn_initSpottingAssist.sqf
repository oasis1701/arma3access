/*
 * fn_initSpottingAssist.sqf - Initialize spotting assist for solo player
 *
 * Solo players have no AI group members to populate nearTargets.
 * This system scans the soldier's forward-facing cone, checks LOS,
 * and reveals visible enemies so aim assist and enemy detection work.
 *
 * Always active - no toggle needed.
 */

// Spotting parameters
BA_spottingInterval = 0.5;  // 2Hz
BA_spottingRange = 800;
BA_spottingFOV = 120;       // degrees - 60 each side of facing direction

// Clean up old handler if re-initializing (save game load safety)
if (!isNil "BA_spottingEHId" && {BA_spottingEHId >= 0}) then {
    removeMissionEventHandler ["EachFrame", BA_spottingEHId];
};

BA_spottingEHId = -1;
BA_lastSpottingTime = 0;

// Register the EachFrame handler (always active)
BA_spottingEHId = addMissionEventHandler ["EachFrame", {
    [] call BA_fnc_updateSpottingAssist;
}];
