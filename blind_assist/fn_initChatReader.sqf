/*
 * Function: BA_fnc_initChatReader
 * Initializes the chat reader for NVDA announcements.
 *
 * Listens for Side Chat (1) and Command Chat (2) messages and
 * automatically speaks them via NVDA.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_initChatReader;
 */

// Remove existing handler if present (prevents duplicates on save/load)
if (!isNil "BA_chatReaderEHId") then {
    removeMissionEventHandler ["HandleChatMessage", BA_chatReaderEHId];
};

// Channels: 0=Global, 1=Side, 2=Command, 3=Group, 4=Vehicle, 5=Direct
BA_chatReaderChannels = [1, 2];  // Side and Command

BA_chatReaderEHId = addMissionEventHandler ["HandleChatMessage", {
    params ["_channel", "_owner", "_from", "_text", "_person", "_name"];

    if (_channel in BA_chatReaderChannels) then {
        private _speakerName = if (_name == "") then { "Command" } else { _name };
        private _message = format ["Radio: %1 says, %2", _speakerName, _text];
        [_message] call BA_fnc_speak;
    };

    false  // Don't suppress visual display
}];

diag_log "Blind Assist: Chat Reader initialized";
