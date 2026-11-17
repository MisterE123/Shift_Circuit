## Submission requirements and route limits

Submission, Save Enabled, export and admin enabling require at least two checkpoint candidates and a reachable route. One candidate is the start, so two candidates provide one checkpoint. Automatic routing uses as many reachable candidates as are available, up to the requested count; it never duplicates candidates to fill a shortage. For four checkpoints, provide at least five reachable candidates across the assembled course.

## Wall emitters and public availability

Laser brushes place a thin emitter wall behind the selected square, facing in the placement direction. The square remains available for other floor machinery and robots; the wall edge blocks crossing. A beam begins at the emitter and can hit a robot in its own square.

Enable is admin approval: enabled boards/configurations are publicly available. Disable removes public availability. Authors can still select their own saved configurations. There is no separate approval toggle.

## Route candidates and submission review

Place checkpoint candidate tiles in the workshop; there is no separate Start brush. A race start occupies one candidate, with the others available for checkpoints. In the course designer, START & CHECKPOINTS lets authorized builders click the start and checkpoints in route order. Reset Automatic returns to generated routing. Saved configurations include the selected route.

Admins can open REVIEW SUBMISSIONS in the Test Lab to inspect boards and configurations, playtest, approve, enable/disable and leave notes. Board authors load their submission and choose REVIEW NOTES; configuration authors use NOTES in Saved Configurations.

# Factory Workshop

Open **Workshop / Build Levels**. Choose a 10x10 or 20x20 board. The gameplay HUD is hidden while editing and restored for playtests. The square-icon palette groups tools into Floor, Conveyors, Machines, and Route & Supply. Choose a brush, then select Build. Placement snaps to the nearest cardinal direction you are looking. Use K to enter flight mode.

Tool 1 paints. Tool 2 rotates an existing piece clockwise; curved conveyors rotate both their entry and exit. Lasers, pushers and the start marker also rotate. Right-click either tool to open the palette. Left/Right Rotator brushes choose the rotation effect rather than a facing.

Walls toggle the selected tile edge. Crushers occupy the overhead layer and preserve machinery beneath. Erase Layers removes walls, machines and spawners without erasing the floor. Powerups are supplied by random spawners, not individual pickup brushes. Spawner Schedule accepts either explicit rounds or a first round and repeat interval, a phase offset within that interval, and a 0–100% spawn chance (default 50%). A pad rolls once per due round, including round one only when its schedule allows it. Explicit round lists ignore the phase offset.

Place checkpoint candidates, not numbered flags. The race algorithm selects and numbers reachable candidates. Keep some boundary tiles open so adjoining boards can be traversed; assembly does not remove walls or fill pits. The first placed board supplies the course start.

Each player has one autosaved Draft, listed separately in the library. Choose 10x10 or 20x20 before editing. Painting or rotating locks size, including after reconnecting; Undo does not unlock it. Reset Draft asks for confirmation, clears the draft and unlocks sizing. Library boards open as read-only previews without changing the draft. Replace Draft With This Board also requires confirmation. Undo restores painting and rotation within the current draft. Playtest validates the draft and starts normal gameplay. Return to the workshop and select Build to resume editing the unmodified draft.

## Approval and export

Submit saves a pending level. Players can inspect their own submissions and approved levels. Admins with the server privilege can review submissions and Save Approved. Approved boards appear in the course inventory.

Export JSON writes an approved snapshot to `shift_circuit_levels/level_<id>.json` under the world directory. Copy it into the game's `mods/shift_circuit/levels/` directory to bundle it. Filenames import once; use a new filename for a revision.

Version 3 level data uses fixed board sizes, tile layers, start, checkpoint candidates, walls, overhead machines and random spawners. Older 5–15 square levels migrate to the next supported size without cropping. Legacy loose pickups become random spawners. Level files contain data only.

## Race course designer

A 10x10 board occupies one slot; a 20x20 board occupies 2x2 slots. The designer has a 4x4 grid: at most 40x40 game squares. Boards must share an edge. Overlaps, out-of-bounds placement and removal that would disconnect the remaining course are rejected.

Search board names, filter by size, or page through the inventory. Two entries per page leave room for larger previews. Inspect shows an enlarged tile-icon preview and legend. Both previews are generated from the board data and use editable PNG icons.

The creator sets a board limit when opening the room and may enable collaborative editing. Otherwise only the creator can modify the layout. Spectators can view it. The creator chooses checkpoint and AI counts and starts the race. There is no voting or automatic launch timer during course construction.

**Save Configuration** stores a named layout and checkpoint count. Your own configurations are available immediately in Saved Configurations. Other players see them only after admin approval. Admins can see pending saves and approve them in that list. Saving the same name replaces your own version and resets approval unless you are an admin. Loading respects the current room's board limit and editing permissions. Saved configurations use this server's board catalog.


## Exporting race boards and puzzles as mods

Admins have an EXPORT AS MOD button for both map types. Export writes a new
folder under the game's mod-data directory, `shift_circuit/exports/`, containing
mod.conf, init.lua, LICENSE.txt and boards.json or puzzles.json. Copy the whole
folder into the game's mods directory to bundle it, or install it as a mod with
Shift Circuit enabled. Normal players cannot export mods.

Race packs register through shift_circuit.register_board_pack(modname,
'boards.json'). They import validated maps into the server library, enabled by
default. Import IDs are stable: restarts do not overwrite library edits or
re-enable disabled/deleted boards. A new export receives a new mod name.
Conflicting display names are given numeric suffixes rather than merged.
Generated packs may use the shift_circuit_boards_ and shift_circuit_puzzles_
prefixes; permission to use these game namespaces is granted for these packs.
