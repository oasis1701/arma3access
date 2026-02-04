# Combat Patrol Reference

This folder contains extracted source code from Arma 3's Combat Patrol game mode for reference.

These files are used to understand how Combat Patrol's voting system works, enabling Blind Assist to integrate with it properly.

## Key Variables

| Variable | Type | Description |
|----------|------|-------------|
| `BIS_CP_locationArrFinal` | Array | Available target locations: `[[x,y], "Name", sizeMultiplier]` |
| `BIS_CP_targetLocationID` | Number | Index of selected target (-1 during voting) |
| `BIS_CP_votedFor` | Player Variable | Index of location player voted for |
| `BIS_CP_voting_countdown_end` | Number | `daytime` value when voting ends |
| `BIS_CP_votingTimer` | Number | Voting duration in seconds (default: 15) |
| `BIS_CP_preset_locationSelection` | Number | 1 = random selection (no voting) |

## How Voting Works

1. `fn_cpinit.sqf` populates `BIS_CP_locationArrFinal` with available locations
2. Players set `BIS_CP_votedFor` variable to cast votes
3. First vote triggers the countdown timer
4. `fn_cpserverhandler.sqf` counts votes and sets `BIS_CP_targetLocationID`
5. Server auto-calculates insertion position based on winner

## Files

- `fn_cpinit.sqf` - Client initialization, voting UI, location array setup
- `fn_cpserverhandler.sqf` - Server-side vote counting and mission start

## Source Location

Original files are in:
`Arma 3/Addons/modules_f_mp_mark.pbo/functions/CombatPatrol/`
