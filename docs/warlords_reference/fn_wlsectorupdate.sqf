/*
WARLORDS-SPECIFIC FUNCTION

Author: Josef Zemánek

Description: Sector update after its owner changed.
*/

private ["_side", "_sector", "_sideOld"];

_sector = _this # 0;
_sideOld = _this # 1;

_side = _sector getVariable "BIS_WL_sectorSide";

((_sector getVariable "BIS_WL_sectorMrkrs") # 0) setMarkerColorLocal (["colorOPFOR", "colorBLUFOR", "colorIndependent"] # (BIS_WL_sidesPool find (_sector getVariable "BIS_WL_sectorSide")));

{
	_x setMarkerColorLocal (["colorOPFOR", "colorBLUFOR", "colorIndependent"] # (BIS_WL_sidesPool find _side));
} forEach (_sector getVariable "BIS_WL_sectorLockMrkrs");

[_sector, "default"] call BIS_fnc_WLSectorIconUpdate;

BIS_WL_recalculateIncome = TRUE;
call BIS_fnc_WLrecalculateServices;

if (_side == side group player) then {
	[toUpper format [localize "STR_A3_WL_popup_sector_seized", _sector getVariable "Name", _side call BIS_fnc_WLSideToFaction]] spawn BIS_fnc_WLSmoothText;
	if !(_sector in [BIS_WL_base_EAST, BIS_WL_base_WEST]) then {
		"Seized" call BIS_fnc_WLSoundMsg;
	};
	[_sector, "seize", "succeed"] call BIS_fnc_WLSectorTaskHandle;
} else {
	if (_sideOld == side group player) then {
		[toUpper format [localize "STR_A3_WL_popup_sector_seized", _sector getVariable "Name", _side call BIS_fnc_WLSideToFaction]] spawn BIS_fnc_WLSmoothText;
		if !(_sector in [BIS_WL_base_EAST, BIS_WL_base_WEST]) then {
			"Lost" call BIS_fnc_WLSoundMsg;
		};
	} else {
		[toUpper format [localize "STR_A3_WL_popup_sector_seized", _sector getVariable "Name", _side call BIS_fnc_WLSideToFaction]] spawn BIS_fnc_WLSmoothText;
		if !(_sector in [BIS_WL_base_EAST, BIS_WL_base_WEST]) then {
			"Enemy_advancing" call BIS_fnc_WLSoundMsg;
		};
	};
};