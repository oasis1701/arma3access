/*
 * Function: BA_fnc_initDirectionSnap
 * Initializes the direction snap system for smooth compass direction cycling.
 *
 * State Variables:
 *   BA_dirSnapEnabled    - Is interpolation currently in progress?
 *   BA_dirSnapTarget     - Target direction (degrees)
 *   BA_dirSnapStart      - Start direction (degrees)
 *   BA_dirSnapStartTime  - Start time of interpolation
 *   BA_dirSnapDuration   - Duration in seconds (0.15 for snappy feel)
 *   BA_dirSnapEHId       - EachFrame handler ID
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_initDirectionSnap;
 */

// Initialize state variables
BA_dirSnapEnabled = false;        // Is interpolation in progress?
BA_dirSnapTarget = 0;             // Target direction (degrees)
BA_dirSnapStart = 0;              // Start direction (degrees)
BA_dirSnapStartTime = 0;          // Start time of interpolation
BA_dirSnapDuration = 0.15;        // Duration in seconds (fast and snappy)
BA_dirSnapEHId = -1;              // EachFrame handler ID

// Log initialization
diag_log "Blind Assist: Direction snap system initialized.";
