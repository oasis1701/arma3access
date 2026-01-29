/*
 * Function: BA_fnc_cancel
 * Cancels any currently speaking NVDA speech.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   String - "OK" on success, error code otherwise
 *
 * Example:
 *   [] call BA_fnc_cancel;
 */

"nvda_arma3_bridge" callExtension "cancel"
