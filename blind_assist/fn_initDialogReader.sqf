/*
 * fn_initDialogReader.sqf - Initialize dialog reader for NVDA accessibility
 *
 * Monitors focused controls in custom mission dialogs and announces them
 * via NVDA with spatial label association (reads nearby label text).
 *
 * Usage: [] call BA_fnc_initDialogReader;
 */

// State variables
BA_dialogReaderLastCtrlIDC = -1;
BA_dialogReaderLastCtrlIDD = -1;
BA_dialogReaderLastValue = "";
BA_dialogReaderLastDisplayCount = count allDisplays;
BA_dialogReaderCooldown = 0;

// Throttle to 10Hz
BA_dialogReaderLastUpdate = 0;
BA_dialogReaderUpdateInterval = 0.1;

// Remove existing handler if re-initializing
if (!isNil "BA_dialogReaderEHId" && {BA_dialogReaderEHId >= 0}) then {
    removeMissionEventHandler ["EachFrame", BA_dialogReaderEHId];
};

BA_dialogReaderEHId = addMissionEventHandler ["EachFrame", {
    [] call BA_fnc_updateDialogReader;
}];
