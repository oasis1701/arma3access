/*
 * Function: BA_fnc_initAimAssist
 * Initializes the aim assist audio system state variables.
 *
 * This should be called once at mission start (from initObserverMode).
 * The aim assist provides audio feedback for aiming:
 * - Stereo panning indicates horizontal offset (left/right)
 * - Pitch indicates vertical offset (up/down)
 * - Square wave indicates locked on target
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_initAimAssist;
 */

// State variables
BA_aimAssistEnabled = false;       // Whether aim assist is currently active
BA_aimAssistTarget = objNull;      // Current target being tracked
BA_aimAssistLastUpdate = 0;        // Last update time for throttling
BA_aimAssistUpdateInterval = 0.05; // Update every 50ms (20Hz)
BA_aimAssistEHId = -1;             // EachFrame event handler ID

// Hit detection
BA_aimAssistHitTarget = objNull;   // Target with hit EH attached
BA_aimAssistHitEH = -1;            // Hit event handler ID

// Lock state tracking (for blip sound)
BA_aimAssistWasVertLocked = false; // Previous vertical lock state

// Horizontal guidance (secondary click tone)
BA_aimHorizGuidanceEnabled = false;  // Horizontal click tone off by default

// Configuration
BA_aimAssistMaxRange = 500;        // Maximum target acquisition range (meters)
BA_aimAssistLockAngle = 1.0;       // Degrees of error for "locked" - testing camera direction
BA_aimAssistMinKnowledge = 0.5;    // Minimum knowsAbout value for valid target

// Log initialization
diag_log "Blind Assist: Aim Assist system initialized";
