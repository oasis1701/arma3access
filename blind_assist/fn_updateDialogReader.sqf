/*
 * fn_updateDialogReader.sqf - Per-frame dialog reader update
 *
 * Detects focused controls in custom dialogs and announces them via NVDA.
 * Uses spatial label association to find the label text positioned to the
 * left of the focused control at the same Y position.
 *
 * Usage: [] call BA_fnc_updateDialogReader;
 */

if (!BA_dialogReaderEnabled) exitWith {};

// --- Throttle check ---
private _now = diag_tickTime;
if (_now - BA_dialogReaderLastUpdate < BA_dialogReaderUpdateInterval) exitWith {};
BA_dialogReaderLastUpdate = _now;

// --- Cooldown after dialog close ---
if (_now < BA_dialogReaderCooldown) exitWith {};

// --- Dialog open/close detection ---
private _displayCount = count allDisplays;
private _lastCount = BA_dialogReaderLastDisplayCount;
BA_dialogReaderLastDisplayCount = _displayCount;

if (_displayCount > _lastCount) then {
    // New display appeared - check if it has interactive controls before announcing
    private _topDisplay = allDisplays select (_displayCount - 1);
    private _hasControls = false;
    {
        private _type = ctrlType _x;
        // Check for interactive control types (button, edit, slider, combo, listbox, checkbox, shortcut button, xslider)
        if (_type in [1, 2, 3, 4, 5, 7, 16, 43, 77]) exitWith {
            _hasControls = true;
        };
    } forEach (allControls _topDisplay);

    if (_hasControls) then {
        [] call BA_fnc_cancel;
        ["Dialog opened"] call BA_fnc_speak;
    };

};

if (_displayCount < _lastCount) exitWith {
    // Display closed
    BA_dialogReaderLastCtrlIDC = -1;
    BA_dialogReaderLastCtrlIDD = -1;
    BA_dialogReaderLastValue = "";
    BA_dialogReaderCooldown = _now + 0.5;
    [] call BA_fnc_cancel;
    ["Dialog closed"] call BA_fnc_speak;
};

// --- Find control under mouse cursor (primary) ---
private _ignoredDisplays = [46, 49];
private _focusedCtrl = controlNull;
private _focusedDisplay = displayNull;

private _mousePos = getMousePosition;
private _mx = _mousePos select 0;
private _my = _mousePos select 1;
private _bestCtrl = controlNull;
private _bestArea = 999;
private _bestDisplay = displayNull;

{
    private _disp = _x;
    private _dispIDD = ctrlIDD _disp;
    if !(_dispIDD in _ignoredDisplays) then {
        {
            private _ct = ctrlType _x;
            if !(_ct in [0, 13, 15]) then { if (ctrlShown _x) then {
                private _pos = ctrlPosition _x;
                private _cx = _pos select 0;
                private _cy = _pos select 1;
                private _cw = _pos select 2;
                private _ch = _pos select 3;

                private _pg = ctrlParentControlsGroup _x;
                while {!isNull _pg} do {
                    private _gp = ctrlPosition _pg;
                    _cx = _cx + (_gp select 0);
                    _cy = _cy + (_gp select 1);
                    _pg = ctrlParentControlsGroup _pg;
                };

                if (_mx >= _cx && _mx <= _cx + _cw && _my >= _cy && _my <= _cy + _ch) then {
                    private _area = _cw * _ch;
                    if (_area < _bestArea) then {
                        _bestArea = _area;
                        _bestCtrl = _x;
                        _bestDisplay = _disp;
                    };
                };
            }; };
        } forEach (allControls _disp);
    };
} forEach allDisplays;

if (!isNull _bestCtrl) then {
    _focusedCtrl = _bestCtrl;
    _focusedDisplay = _bestDisplay;
};

// --- Fallback: keyboard-focused control ---
if (isNull _focusedCtrl) then {
    {
        private _displayIDD = ctrlIDD _x;
        if !(_displayIDD in _ignoredDisplays) then {
            private _fc = focusedCtrl _x;
            if (!isNull _fc && {!(ctrlType _fc in [0, 13, 15])}) then {
                _focusedCtrl = _fc;
                _focusedDisplay = _x;
            };
        };
    } forEach allDisplays;
};

// No focused or hovered control found
if (isNull _focusedCtrl) exitWith {};

// --- Extract control value by type ---
private _ctrlType = ctrlType _focusedCtrl;

// Skip non-interactive control types (static text, structured text, controls group)
if (_ctrlType in [0, 13, 15]) exitWith {};
private _value = "";
private _typeName = "";

switch (_ctrlType) do {
    case 1: {
        _typeName = "Button";
        _value = ctrlText _focusedCtrl;
    };
    case 2: {
        _typeName = "Edit box";
        _value = ctrlText _focusedCtrl;
        if (_value == "") then { _value = "empty"; };
    };
    case 3: {
        _typeName = "Slider";
        _value = str (round (sliderPosition _focusedCtrl));
    };
    case 4: {
        _typeName = "Combo box";
        private _sel = lbCurSel _focusedCtrl;
        if (_sel >= 0) then {
            _value = _focusedCtrl lbText _sel;
        } else {
            _value = "no selection";
        };
    };
    case 5: {
        _typeName = "List box";
        private _sel = lbCurSel _focusedCtrl;
        if (_sel >= 0) then {
            _value = _focusedCtrl lbText _sel;
        } else {
            _value = "no selection";
        };
    };
    case 7: {
        _typeName = "Checkbox";
        if (cbChecked _focusedCtrl) then {
            _value = "checked";
        } else {
            _value = "unchecked";
        };
    };
    case 16: {
        _typeName = "Button";
        _value = ctrlText _focusedCtrl;
    };
    case 43: {
        _typeName = "Slider";
        _value = str (round (sliderPosition _focusedCtrl));
    };
    case 77: {
        _typeName = "Checkbox";
        if (cbChecked _focusedCtrl) then {
            _value = "checked";
        } else {
            _value = "unchecked";
        };
    };
    case 102: {
        _typeName = "List";
        private _sel = lnbCurSelRow _focusedCtrl;
        if (_sel >= 0) then {
            _value = _focusedCtrl lnbText [_sel, 0];
        } else {
            _value = "no selection";
        };
    };
    default {
        _typeName = "Control";
        _value = ctrlText _focusedCtrl;
    };
};

// Include tooltip text
private _tooltip = ctrlTooltip _focusedCtrl;
if (_value == "" && _tooltip != "") then {
    _value = _tooltip;
} else {
    if (_tooltip != "" && _tooltip != _value) then {
        _value = _value + ". " + _tooltip;
    };
};

// Still empty - use generic description
if (_value == "") then {
    _value = _typeName;
    _typeName = "";
};

// --- Check if anything changed ---
private _ctrlIDC = ctrlIDC _focusedCtrl;
private _ctrlIDD = ctrlIDD _focusedDisplay;
private _ctrlChanged = (_ctrlIDC != BA_dialogReaderLastCtrlIDC) || (_ctrlIDD != BA_dialogReaderLastCtrlIDD);
private _valueChanged = !(_value isEqualTo BA_dialogReaderLastValue);

if (!_ctrlChanged && !_valueChanged) exitWith {};

// Update tracking
BA_dialogReaderLastCtrlIDC = _ctrlIDC;
BA_dialogReaderLastCtrlIDD = _ctrlIDD;
BA_dialogReaderLastValue = _value;

// --- Spatial label association ---
// Find nearest static text label to the left of focused control at same Y position
private _label = "";

private _focusPos = ctrlPosition _focusedCtrl;
private _focusX = _focusPos select 0;
private _focusY = _focusPos select 1;

// If control is inside a controls group, convert to absolute coordinates
private _parentGroup = ctrlParentControlsGroup _focusedCtrl;
while {!isNull _parentGroup} do {
    private _groupPos = ctrlPosition _parentGroup;
    _focusX = _focusX + (_groupPos select 0);
    _focusY = _focusY + (_groupPos select 1);
    _parentGroup = ctrlParentControlsGroup _parentGroup;
};

private _yTolerance = 0.025;
private _bestLabel = "";
private _bestDist = 999;

{
    private _ctrl = _x;
    // Only consider visible static text controls (type 0)
    if (ctrlType _ctrl == 0 && {ctrlText _ctrl != ""}) then {
        private _pos = ctrlPosition _ctrl;
        private _cx = _pos select 0;
        private _cy = _pos select 1;

        // Convert to absolute coordinates if inside controls group
        private _pg = ctrlParentControlsGroup _ctrl;
        while {!isNull _pg} do {
            private _gp = ctrlPosition _pg;
            _cx = _cx + (_gp select 0);
            _cy = _cy + (_gp select 1);
            _pg = ctrlParentControlsGroup _pg;
        };

        // Must be at roughly same Y position and to the LEFT
        if (abs(_cy - _focusY) < _yTolerance && _cx < _focusX) then {
            private _dist = _focusX - _cx;
            if (_dist < _bestDist) then {
                _bestDist = _dist;
                _bestLabel = ctrlText _ctrl;
            };
        };
    };
} forEach (allControls _focusedDisplay);

// --- Announce ---
[] call BA_fnc_cancel;

private _announcement = "";
if (_bestLabel != "" && _typeName != "") then {
    _announcement = format ["%1: %2, %3", _bestLabel, _value, _typeName];
} else {
    if (_bestLabel != "") then {
        _announcement = format ["%1: %2", _bestLabel, _value];
    } else {
        if (_typeName != "") then {
            _announcement = format ["%1, %2", _value, _typeName];
        } else {
            _announcement = _value;
        };
    };
};

[_announcement] call BA_fnc_speak;
