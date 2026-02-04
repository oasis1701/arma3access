# Warlords Function Reference

Extracted from `functions_f_warlords.pbo` (Arma 3 v2.18)

**71 functions total:** 61 SQF scripts + 10 FSM state machines

This is the official Bohemia Interactive Warlords source code for reference when developing Blind Assist Warlords support.

## File Types
- **SQF** - Standard Arma script files (readable text)
- **FSM** - Finite State Machine files (XML-based state diagrams)

## Key Variables Discovered

### Voting
- `player getVariable "BIS_WL_selectedSector"` - Player's voted sector (ModuleWLSector_F object)
- `BIS_WL_currentSelection` - Current selection state ("voting", "voted", etc.)
- `BIS_WL_leadingSector_{SIDE}` - Current leading sector for a side
- `BIS_WL_selectionTime_{SIDE}` - Selection timeout for a side
- `BIS_WL_currentSector_{SIDE}` - Current attack target for a side

### Sectors
- `BIS_WL_sectors` - Array of all sector objects
- `BIS_WL_sectorsArrayFriendly` - Sectors accessible to player's side
- Sector object class: `ModuleWLSector_F`
- Sector variables: `bis_wl_sectortext`, `bis_wl_sectorside`, `bis_wl_value`, `BIS_WL_pointer`

## Functions by Category

### Initialization
- `fn_wlinit.sqf` - Main Warlords initialization
- `fn_wlclientinit.sqf` - Client-side initialization
- `fn_wlvarsinit.sqf` - Variable initialization
- `fn_wlsectorscommoninit.sqf` - Sector common init
- `fn_wlsectorinit.sqf` - Individual sector init
- `fn_wlsectorssetup.sqf` - Sectors setup

### Voting & Sector Selection
- `fn_wlsectorselectionstart.sqf` - **Voting phase start** (key file!)
- `fn_wlsectorselectionend.sqf` - Voting phase end
- `fn_wlmostvotedsector.sqf` - **Count votes** (key file!)
- `fn_wlvotingbarhandle.sqf` - Voting bar UI
- `fn_wlrequestvotingreset.sqf` - Reset voting
- `fn_wlsectorselectionhandle.fsm` - Selection handling state machine (FSM)
- `fn_wlsectorselectionhandleserver.fsm` - Server-side selection handling (FSM)

### Sectors
- `fn_wlsectorupdate.sqf` - Sector state update
- `fn_wlsectoriconupdate.sqf` - Sector icon update
- `fn_wlsectorlisting.sqf` - List sectors
- `fn_wlsectorpopulate.sqf` - Populate sector with units
- `fn_wlinsectorarea.sqf` - Check if in sector area
- `fn_wlseizingbarhandle.sqf` - Seizing progress bar
- `fn_wlcalculatesectorconnections.sqf` - Sector connections
- `fn_wlsectorhandle.fsm` - Sector handling state machine (FSM)
- `fn_wlsectorhandleserver.fsm` - Server-side sector handling (FSM)
- `fn_wlsectorscanhandle.fsm` - Sector scan handling (FSM)
- `fn_wlsectortaskhandle.fsm` - Sector task handling (FSM)
- `fn_wlsectorfundspayoff.fsm` - Sector funds payoff (FSM)

### Purchasing & Assets
- `fn_wlpurchasemenu.sqf` - Purchase menu
- `fn_wlrequestpurchase.sqf` - Request purchase
- `fn_wldroppurchase.sqf` - Drop purchased item
- `fn_wlparseassetlist.sqf` - Parse asset list
- `fn_wlsubroutine_purchasemenu*.sqf` - Purchase menu subroutines

### Transport & Delivery
- `fn_wlaircraftarrival.sqf` - Aircraft arrival
- `fn_wlnavalarrival.sqf` - Naval arrival
- `fn_wlairdrop.sqf` - Airdrop
- `fn_wlrequestfasttravel.sqf` - Fast travel

### AI
- `fn_wlaisectorscan.sqf` - AI sector scanning
- `fn_wlaipathsegmentation.sqf` - AI path planning
- `fn_wlsendresponseteam.sqf` - Send response team
- `fn_wlaicore.fsm` - AI core state machine (FSM)
- `fn_wlaipurchases.fsm` - AI purchases state machine (FSM)
- `fn_wlgarrisonretreat.fsm` - Garrison retreat state machine (FSM)

### Economy
- `fn_wlcalculateincome.sqf` - Calculate income
- `fn_wlfundsinfo.sqf` - Funds info
- `fn_wlrequestfundstransfer.sqf` - Transfer funds
- `fn_wlreputation.sqf` - Reputation system

### Player Tracking
- `fn_wlplayerstracking.sqf` - Client-side tracking
- `fn_wlplayerstrackingserver.sqf` - Server-side tracking

### UI & Display
- `fn_wlosd.sqf` - On-screen display
- `fn_wlshowinfo.sqf` - Show info
- `fn_wloutlineicons.sqf` - Outline icons
- `fn_wlsmoothtext.sqf` - Smooth text animation
- `fn_wlsoundmsg.sqf` - Sound messages

### Arsenal & Loadouts
- `fn_wlopenarsenal.sqf` - Open arsenal
- `fn_wlarsenalfilter.sqf` - Arsenal filter
- `fn_wlloadoutapply.sqf` - Apply loadout
- `fn_wlloadoutgrab.sqf` - Grab loadout

### Misc
- `fn_wldebug.sqf` - Debug logging
- `fn_wldefencesetup.sqf` - Defence setup
- `fn_wlrecalculateservices.sqf` - Recalculate services
- `fn_wlremovalhandle.sqf` - Handle removals
- `fn_wlsidetofaction.sqf` - Side to faction
- `fn_wlsyncedtime.sqf` - Synced time
- `fn_wlsynctime.sqf` - Sync time
- `fn_wlupdateao.sqf` - Update area of operations
- `fn_wlvehiclehandle.sqf` - Vehicle handling
- `fn_wlrandomposrect.sqf` - Random position in rectangle
- `fn_wlrequestsectorscan.sqf` - Request sector scan

## Usage Notes

These files are for **reference only** - do not modify them.

When adding Warlords features to Blind Assist:
1. Find the relevant function in this folder
2. Study how it reads/writes variables
3. Use the same variable names and patterns in your code

---

## Extracting Additional Resources (For Claude)

If you need additional Warlords resources, here's how to extract them:

### Available PBOs
Located in `$ARMA3_DIR/Addons/`:
- `functions_f_warlords.pbo` - **Already extracted** (scripts)
- `data_f_warlords.pbo` - Textures, sounds, UI layouts
- `dubbing_f_warlords.pbo` - Voice lines
- `language_f_warlords.pbo` - String tables / localization
- `missions_f_warlords.pbo` - Mission templates
- `modules_f_warlords.pbo` - Config files (config.bin)

### Extraction Command
Use BankRev from Arma 3 Tools:
```bash
"F:\Steam\steamapps\common\Arma 3 Tools\BankRev\BankRev.exe" -f "OUTPUT_FOLDER" "PATH_TO_PBO"
```

Example:
```bash
"F:\Steam\steamapps\common\Arma 3 Tools\BankRev\BankRev.exe" -f "C:\Users\rhadi\AppData\Local\Temp\claude\warlords_extract" "F:\Steam\steamapps\common\Arma 3\Addons\language_f_warlords.pbo"
```

### Note
- Read `local.env` to get correct `ARMA3_DIR` path
- FSM files are XML-based state machine definitions
- config.bin files are binarized configs (harder to read)
