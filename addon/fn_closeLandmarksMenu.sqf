/*
 * Function: BA_fnc_closeLandmarksMenu
 * Closes the landmarks menu without selecting anything.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [] call BA_fnc_closeLandmarksMenu;
 */

if (!BA_landmarksMenuActive) exitWith {};

// Reset state
BA_landmarksMenuActive = false;
BA_landmarksCategoryIndex = 0;
BA_landmarksItemIndex = [0, 0, 0, 0, 0];
BA_landmarksItems = [[], [], [], [], []];

["Landmarks cancelled."] call BA_fnc_speak;
