/*
 * Function: BA_fnc_clearPlayerWaypoint
 * Clears the active navigation waypoint and stops all guidance.
 *
 * Stops the audio beacon, removes the EachFrame handler,
 * deletes the waypoint marker, and resets state variables.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_clearPlayerWaypoint;
 */

// Skip if navigation not active
if (!BA_playerNavEnabled) exitWith {};

// Remove the EachFrame handler
if (BA_playerNavEHId >= 0) then {
    removeMissionEventHandler ["EachFrame", BA_playerNavEHId];
    BA_playerNavEHId = -1;
};

// Stop the audio beacon
"nvda_arma3_bridge" callExtension "beacon_stop";

// Delete the waypoint marker
if (BA_playerNavMarker != "") then {
    deleteMarkerLocal BA_playerNavMarker;
    BA_playerNavMarker = "";
};

// Reset state
BA_playerNavEnabled = false;
BA_playerNavDestination = [];
BA_playerNavPath = [];
BA_playerNavPathIndex = 0;
BA_playerNavLastDistAnnounced = -1;
BA_playerNavLastRecalcTime = 0;

diag_log "Blind Assist: Player waypoint cleared.";
