/*
 * Dialog: BA_FocusModeDialog
 * Transparent overlay dialog that blocks engine-level inputs during Focus Mode.
 *
 * Purpose:
 *   When Focus Mode is active, we need to block engine actions like flashlight toggle (L),
 *   reload (R), and soldier turning (arrows). Display 46's KeyDown handler can't block these.
 *   A dialog overlay automatically blocks all soldier inputs while keeping the simulation running.
 *
 * IDD: 9100
 */

class BA_FocusModeDialog {
    idd = 9100;
    movingEnable = false;
    enableSimulation = true;
    onLoad = "";
    onUnload = "BA_focusMode = false; BA_cursorActive = false;";

    class ControlsBackground {
        class Background {
            idc = -1;
            type = 0;
            style = 0;
            x = safeZoneX;
            y = safeZoneY;
            w = safeZoneW;
            h = safeZoneH;
            colorBackground[] = {0, 0, 0, 0};
            colorText[] = {1, 1, 1, 1};
            text = "";
            font = "RobotoCondensed";
            sizeEx = 0.02;
        };
    };

    class Controls {};
};
