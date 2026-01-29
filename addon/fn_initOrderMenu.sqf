/*
 * Function: BA_fnc_initOrderMenu
 * Initializes the Order Menu system state variables.
 *
 * Call this at mission start after initObserverMode.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_initOrderMenu;
 */

// Order menu state variables
BA_orderMenuActive = false;      // Is menu currently open?
BA_orderMenuItems = [];          // Array of [label, commandType] pairs
BA_orderMenuIndex = 0;           // Current selection (0-based)
BA_orderMenuUnitType = "";       // Detected unit category

// Debug mode - set to true to see debug messages in systemChat
BA_debugMode = false;

// Log initialization
systemChat "Blind Assist: Order Menu system initialized. Press O in observer mode to open orders.";
if (BA_debugMode) then {
    systemChat "DEBUG MODE ON - Set BA_debugMode = false to disable";
};
