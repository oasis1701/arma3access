/*
 * Function: BA_fnc_initPlayerNav
 * Initializes state variables and configuration for player waypoint navigation.
 *
 * The navigation system allows blind players to:
 * - Place a waypoint at the cursor position (Y key)
 * - Receive audio beacon guidance with stereo panning
 * - Get distance announcements as they approach
 * - Automatic path recalculation when straying off course
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_initPlayerNav;
 */

// Navigation state
BA_playerNavEnabled = false;          // Is navigation active?
BA_playerNavDestination = [];         // Final destination [x, y, z]
BA_playerNavPath = [];                // Array of path points from calculatePath
BA_playerNavPathIndex = 0;            // Current target point in path
BA_playerNavEHId = -1;                // EachFrame handler ID
BA_playerNavLastDistAnnounced = -1;   // Last distance threshold announced
BA_playerNavLastRecalcTime = 0;       // Time of last path recalculation
BA_playerNavMarker = "";              // Local marker name for waypoint

// Configuration
BA_playerNavArrivalRadius = 3;        // Meters: close enough to destination
BA_playerNavBreadcrumbRadius = 5;     // Meters: advance to next path point
BA_playerNavDeviationThreshold = 15;  // Meters: trigger path recalculation
BA_playerNavRecalcCooldown = 5;       // Seconds between recalculations
BA_playerNavUpdateInterval = 0.1;     // 10Hz update rate
BA_playerNavLastUpdateTime = 0;       // Last update timestamp
