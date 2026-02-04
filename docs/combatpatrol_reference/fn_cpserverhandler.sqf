/*
 * Combat Patrol Server Handler
 * Extracted from: Arma 3/Addons/modules_f_mp_mark.pbo/functions/CombatPatrol/fn_cpserverhandler.sqf
 *
 * This file contains the key portions relevant to vote counting and target selection.
 * Full source available in the game files.
 */

// =============================================================================
// VOTE COUNTING
// =============================================================================

// Server counts votes from all players when timer expires:
// {
//     private _vote = _x getVariable ["BIS_CP_votedFor", -1];
//     if (_vote >= 0) then {
//         // Increment vote count for that location
//     };
// } forEach allPlayers;

// =============================================================================
// TARGET SELECTION
// =============================================================================

// After counting, server sets the winning location:
// missionNamespace setVariable ["BIS_CP_targetLocationID", _winningIndex, true];

// The targetLocationID is an INDEX into BIS_CP_locationArrFinal, NOT an object

// =============================================================================
// INSERTION POSITION CALCULATION
// =============================================================================

// Server automatically calculates insertion position based on target location
// BIS_CP_insertionPos is set server-side - clients don't need to set this

// The insertion position is typically:
// - A safe position outside the target area
// - Accessible by ground or air depending on mode
// - Away from enemy positions

// =============================================================================
// MISSION START
// =============================================================================

// Once target is selected:
// 1. BIS_CP_targetLocationID is broadcast to all clients
// 2. Insertion position is calculated
// 3. Players are spawned/transported to insertion point
// 4. Objectives are generated for the target location

// =============================================================================
// RANDOM SELECTION MODE
// =============================================================================

// If BIS_CP_preset_locationSelection == 1:
// - No voting occurs
// - Server randomly selects a location
// - BIS_CP_targetLocationID is set immediately
