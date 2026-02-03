/*
 * config.cpp - Master configuration for Blind Assist addon
 *
 * This file makes the addon self-contained and usable with ANY mission
 * without requiring mission authors to modify their description.ext.
 *
 * When packed as a PBO and loaded via -mod, Arma 3 will:
 * 1. Register the addon via CfgPatches
 * 2. Load all functions via CfgFunctions
 * 3. Make dialogs available globally
 */

class CfgPatches {
    class BlindAssist {
        name = "Blind Assist";
        author = "BlindDev";
        url = "";
        units[] = {};
        weapons[] = {};
        requiredAddons[] = {"A3_Functions_F"};
        requiredVersion = 2.18;
    };
};

class CfgFunctions {
    #include "CfgFunctions_Addon.hpp"
};

// Dialog definitions - available globally when addon is loaded
#include "BA_FocusModeDialog.hpp"
