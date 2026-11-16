# Shift Circuit



Playable Luanti 5.18+ factory-programming game, development build 0.19.1. Original artwork, models, maps, text, and working title; CC0 sound effects by Kenney and Algate music by James Gargette (cinameng).



See [CONTROLS.md](CONTROLS.md) for gameplay, movement, the HUD controller, hand allowance, upgrades, weapons, puzzle progress, and multiplayer hosting. See [ASSET_EDITING.md](ASSET_EDITING.md) for editable model textures and normals. See [CHANGELOG.md](CHANGELOG.md) for changes and verification.



See [SYSTEMS.md](SYSTEMS.md) for Priority IDs, loadouts, collectible equipment, supply pads, spectators, hunter patrols, and admin test scenes.

## Run



Install the game in Luanti's user games directory (on Windows, `%APPDATA%/Minetest/games/shift_circuit`). Open Luanti, select Shift Circuit, and create a world. Restart a running world after code changes.



To install elsewhere, extract the `shift_circuit` directory from the ZIP into your Luanti `games` directory. Restart Luanti, select Shift Circuit, create a new world, and play. The Control Room offers a short tutorial, independent puzzles, configurable solo races, public matchmaking, and multiplayer rooms. Room creators choose the AI count and can enable collaborative course building. For multiplayer, use Luanti's Host Server option or a dedicated server. Other players use the normal multiplayer connection screen.



See [EDITOR.md](EDITOR.md) for the Workshop and portable levels. See [SERVER.md](SERVER.md) for the arena lifecycle and hosting setup.



## Source



- `mods/shift_circuit/rules.lua`: deterministic movement, edge walls, weapons, machinery, pickups, and objectives.

- `mods/shift_circuit/campaign.lua`: legacy test layouts, enemy plans, shuffled decks, and hand modifiers.

- `mods/shift_circuit/planning.lua` and `async_worker.lua`: isolated background planning, started when hands are dealt, with finite-hand validation and stale-result rejection.

- `mods/shift_circuit/particles.lua`: short, event-specific visual feedback.

- `mods/shift_circuit/online.lua`: server lobby, FIFO queue, rooms, shared course building, leaderboard, protected location allocation, and per-session dispatch.

- `mods/shift_circuit/runtime.lua`: HUD/hotbar controller, multiplayer lifecycle, persistence, flight and execution views, entity animation, and scene construction.

- `tools/build_assets.py` and `tools/refine_assets.py`: reproducible original pixel textures and material-mapped OBJ geometry. The first script invokes the second automatically.

- `tests/test_*.py`: execute the actual Lua rules and the controller against a simulated engine API using Python + lupa.



```text

python -m pip install pillow lupa

python tools/build_assets.py

python tests/test_rules.py

python tests/test_expansion.py

python tests/test_conveyors_weapons.py

python tests/test_controller.py

python tests/test_layers_geometry.py

```



No runtime Python dependencies: the Luanti package includes the generated assets. Blender is optional; OBJ files can be imported for editing. Use nearest-neighbor textures by disabling bilinear and trilinear filters in the client.



The working title has not undergone trademark clearance. No source-game art, card text, maps, logos, audio, or other assets are included. Public release and licensing decisions remain with the project owner.



Engine references: [game packaging](https://api.luanti.org/games/), [Lua API](https://api.luanti.org/), and [model support](https://docs.luanti.org/for-creators/models/).





## Workshop objects (0.18.0)
The OBJECTS palette places loot crates, steel crates, pressure plates, initially open/closed trapdoors, Sentries, Patrollers and Ram Bots. Enemy facing follows placement direction and can be rotated with the rotate tool. These layers survive drafts, JSON export, resizing and assembled race courses; previews include their icons.

Loot crates block rays and break after three damaging weapon shots (a double/triple beam volley counts as one shot), leaving one hidden item on the tile. Steel crates cannot be shot apart; crushers convert them into fresh loot crates. Both crate types can be pushed or conveyed; entering a pit consumes the crate and fills that square. Crushing a loot crate breaks it. Hazard edge markers update when holes change.

After commands, both conveyor steps and pushers finish, occupied pressure plates toggle orthogonally adjacent trapdoors once per register. Remaining on a plate triggers it again next register. Two simultaneous toggles cancel. Robots fall immediately when their trapdoor opens; a crate fills the opened hole. Tractor/repulsor displacement occurs later in the weapons phase and is observed at the next plate check.

Predictable enemies have three hull and do not respawn. Sentries rotate clockwise every register and fire during weapons (weapons remain disabled in round one). Patrollers advance, turning around when blocked or facing a pit. Ram Bots wind up upon seeing a robot in their forward ray, then charge up to three squares next register. They do not use AI planning or dealt hands. Battering Ram equipment adds one hull damage on a successful direct robot push, has a visible front mount, and does not stack its damage.

Each new model has an editable sc_surface_* PNG atlas. tools/puzzle_assets.py rebuilds these models without overwriting existing texture edits.

## Puzzle editor (0.19.0)

Open Workshop, choose **Puzzle**, then **Puzzle Settings**. Race boards and puzzles share the normal map tools, including crates, plates, trapdoors and predictable enemy placement. Puzzle maps are excluded from race course assembly.

- **Objectives:** click checkpoint candidates to choose the start and ordered route. Click crates or enemies to mark destruction targets. Click a selected objective again to remove it. All selected objectives are required. A target-only puzzle is allowed; it still needs a checkpoint candidate for the start. Destroying a crate counts; consuming it to fill a hole does not.
- **Robot:** choose starting hull (1-5), power, weapon, equipment quantities and facing. Each attempt restores the authored state. Normal reboot rules apply unless disabled in Details. Starting hull is current health; maximum hull remains five.
- **Cards:** select a round and click card icons to build its explicit 5-12-card hand. Click cards in that hand to remove them. Choose Random Hand to restore regular draws for that round. Unspecified rounds use normal draw rules. Explicit hands override draw penalties and retained cards for that round; they use movement cards, not Blink. Every dealt card receives a unique priority ID.
- **Details:** description, optional round limit (zero means unlimited), export/list order, and optional failure on destruction. A round is five registers. Success on the final allowed register takes precedence over timeout.

Settings autosave into the single protected draft. Enter or Back commits edited text fields. Playtest and submission reject incomplete hands, missing targets, occupied starts and invalid settings. Puzzle submission uses the same admin enable/disable and review-note workflow as race boards. Merely marking a draft as Puzzle does not submit it or enable it.

The main menu **Puzzles** browser shows installed packs, enabled submissions and your own submissions, with previews and personal best round counts. Retry resets the entire board, enemies, pickups, loadout and round number. Random rounds/spawners reroll on retry; only explicitly authored hands and fixed crate contents are predetermined. Restart is also available from the in-match menu. Puzzle targets have dedicated HUD goal markers.

### Admin export and installation

**Export as Mod** in the Workshop exports the current validated puzzle. To export several, open the Puzzles browser, check their Export boxes, enter a pack name, and select **Export Selected as Mod**. The current listing order becomes the explicit manifest order. Set server puzzles' Pack Order in Details before submission to control their order.

Puzzle mod exports are created in Luanti's shared `mod_data/shift_circuit/exports/sc_puzzles_<name>_<number>/` directory, independently of the current world. Standalone board JSON exports use `mod_data/shift_circuit/levels/`. The export message shows the full destination path. Existing export names are skipped to avoid overwriting earlier exports from other worlds. Each contains `mod.conf`, `init.lua`, and `puzzles.json`. Copy the entire exported directory into `shift_circuit/mods/` to bundle it with the game; alternatively install it as an ordinary mod and enable it for the world. Restart the server after installation. No manually edited Lua is needed.

The version-1 JSON manifest contains a title and ordered `puzzles` array, whose entries have a stable local `id` and full validated map `data`. Generated init.lua calls `shift_circuit.register_puzzle_pack(core.get_current_modname(), 'puzzles.json')`. Pack contents are data only and are validated on loading. Installed packs are read-only; Copy to Workshop offers a protected draft replacement confirmation.

Built-in packs (physically under the game's mods directory) sort before external packs, then server submissions. Packs are grouped by mod name; puzzle order inside each pack follows the manifest. External manifests cannot claim built-in priority. Completion records are stored separately by player and puzzle ID and are not included in exports.

## Floating robot health

Every robot has a camera-facing pixel health bar, including map enemies. Green, amber and red segments indicate remaining hull. Bars follow the displayed model and share its observer filters, so ghost opponents float with their bars while the owner sees one bar over their grounded robot. Fallen and finished robots hide their bars; destroyed robots show an empty bar until hidden or rebooted. Edit `textures/sc_robot_health_<maximum>_<health>.png` to theme them. `tools/robot_health_assets.py` generates missing textures without overwriting edits.

Crusher Even activates on registers 2 and 4; Crusher Odd activates on 1, 3 and 5. Both are in the Workshop Machines palette. Existing crushers remain even. Robot damage, crate conversion, sounds and ram animation all follow the selected schedule.

Loot crates show a floating three-segment health bar, including after steel crates are crushed into loot. Edit `sc_crate_health_0.png` through `sc_crate_health_3.png` to theme it. Puzzle Settings > Details includes an optional 180-character HUD hint. During play it appears in a pixel panel at the bottom right; it is hidden while building and when blank. The hint is saved in puzzle data and included in mod exports. Edit `sc_puzzle_hint.png` to theme the panel.

Puzzle execution fast-forwards at 6x after a 0.7-second destruction pause, resolving every remaining phase before normal-speed reboot and planning. Successful puzzles play a dedicated Kenney confirmation cue once, including workshop playtests; it respects the effects volume setting. Replace `mods/shift_circuit/sounds/sc_puzzle_complete.ogg` to customize it.

Ram Bots show an editable pixel cycle strip beneath their floating health bar: watching eye (green), wind-up spring (amber), and charge arrows (red). Point at the bot for its next action. Artwork: `textures/sc_ram_cycle_watch.png`, `sc_ram_cycle_wind.png`, and `sc_ram_cycle_charge.png`.

Workshop library workflow: Save to Library stores unfinished work privately; Submit for Review validates and queues it. Edit Library Entry retains its ID and review history, including on rename. Edit a Copy preserves the source and suggests an unused name. Names are globally unique within the board library (race boards and puzzles together), ignoring case and extra spaces; course configuration names are likewise global. Non-admin authors must ask an admin to disable enabled entries before changing their saved revision; they can instead edit a copy. Authors see Saved, Pending Review, Rejected, Edited, Enabled, or Disabled statuses and admin notes, and can resubmit. Admins have direct Enable/Disable controls instead of Submit, and all JSON/mod export options are admin-only.

Authors may permanently delete their own globally disabled library entries after confirmation; admins can delete any disabled entry. Enabled entries must be disabled by an admin first. Ownership and enabled status are rechecked when deletion is confirmed. Workshop drafts and currently assembled courses are kept. These rules also cover course configurations; non-admin saves and resubmissions cannot indirectly disable enabled content.

Legacy duplicate arena names are reconciled when the library loads: the oldest entry keeps its name and later duplicates receive unused numbered suffixes. Case and extra spaces count as duplicates. Existing numbered names are reserved. IDs, map contents, approval, review notes, and saved course references are preserved; a note records each rename. Linked drafts using the old title are updated, and subsequent loads do not rename entries again.

The built-in tutorial is supplied by `mods/sc_tutorial`, using the authored exports in this order: 01 Welcome To the Floor, then 02 Crate Job. The main-menu Tutorial button opens these independent puzzle lessons. Their original maps, hands, hints, objectives, and reboot settings are preserved. The source export folders are not modified.

Puzzle and tutorial selection screens contain only play/navigation and lesson information. Copy-to-workshop and export controls are removed from these screens; admins still export puzzles from the Workshop.

Tutorial lessons appear only in Tutorial. The Puzzles play menu shows installed non-tutorial packs and enabled server puzzles, excluding disabled/private entries even for admins and authors. Private work remains in the Workshop library.

Luanti game selection now has a custom editable pixel robot icon and the Algate techno menu arrangement in `menu/theme.ogg`. The in-game main menu groups solo/multiplayer play above Workshop/community tools, with robot choice beneath the solo modes.

Network updates: HUD values and entity appearance properties are sent only when they change. Card-selection feedback remains immediate; register overlays are composed before sending to avoid repeatedly resetting the highlighted texture. Position/animation updates continue normally.

Animated robots, equipment, floating health bars, pickups, and machinery use continuous client-interpolated movement for remote players. Respawns and other deliberate relocations still snap; looping conveyor treads interpolate their motion but snap at the hidden loop reset. Rule timing is unchanged.

Multiplayer programming lasts 90 seconds, shown by a prominent pixel countdown bar below the registers. It turns amber at 20 seconds and red at 10 with an auto-fill warning. The deadline remains active if only one human remains; singleplayer stays untimed.

Unused checkpoint candidates become blue save squares when a route is selected. Ending a register on one saves the robot's reboot position and facing without advancing its checkpoint progress; a floating disk icon confirms the save. The start and numbered checkpoints keep their existing roles.

Ending a round on a save square restores 2 hull and 3 power, capped at maximum hull and 9 power. This is in addition to the usual 1 power round regeneration. Passing through or ending an earlier register there does not restore resources; destroyed and finished robots do not benefit.

Chat defaults to the current room, including spectators; players outside a room share Lobby chat. `/g message`, `/global message`, and `/all message` broadcast to every room. The standard shout privilege still applies. Joining or leaving a room changes chat scope immediately.

Lobby visitors appear as their selected robot with their player name, at separate spawn locations. The default hand remains hidden; during a match the pilot remains invisible so the board robot is the only avatar. Changing your cosmetic selection updates the lobby appearance immediately.

All in-game menus now share nine-sliced pixel frames and button states: teal selection, gold primary actions, and red destructive actions. Room setup separates course settings from the roster; the room browser pages through all available rooms. Workshop palette, robot/puzzle cards, dashboard equipment, and navigation spacing are revised.

Loose powerups ride normal, double and turning conveyors and active pushers. Machinery pushes a line of powerups onto ordinary floor too; blocked chains stay intact, merging streams wait, and racers never shove loose supplies. Walls, factories and crates block supplies. Powerups fall through pits and opened trapdoors without filling them.

Workshop / Factories provides 1 outlet, 2 opposite, 2 adjacent, 3 outlets and 4 outlets, with Loot or Steel output. Placement follows view direction; Rotate turns all outlets. Each factory produces a random total of one or two crates per round during the first pusher phase. Available outlets are used in rotating order; a single clear outlet can output both crates. Legacy factory schedules no longer delay production. Crate chains are pushed atomically; a wall, another factory or a robot jams that outlet. Clear outlets continue working. Jam lamps turn red and blocked outlets retry next round. Factory blocks stop movement and rays. Generated crates emerge visibly from the dark mouths. Admin Test Lab / Factories offers a ready-made test scene.

Each crusher stroke advances only one stage: steel crate -> loot crate -> random powerup -> destroyed. New loot survives the stroke that creates it. Both kinds of crate still fill holes. Factories, crate types, directions and outlet shapes persist in board/puzzle saves and exports and appear in generated previews.

Destroyed human and AI racers drop one owned collectible (including a loaded non-default weapon), or a shield if they have none. Non-racing enemies drop one random powerup. A Blueprint Archive's preserved copy is excluded from the drop. Pit-death loot falls away. Existing supplies are never overwritten: a drop uses its death square or an accessible adjacent square, waiting if all are occupied. Drops can then travel through the same conveyor/pusher system.

Menu collections scroll to their actual content length. Audio speaker icons offer mute, low and normal levels, with the selected level outlined green. Enemy commands with independent movement paths animate together; conflicting commands retain their Priority ID order.

## Credits and asset licensing

Code, 3D models, animations and textures: **Codex GPT-6 Astra Medium**. Sound effects: **Kenney**. Music: **James Gargette (cinameng), Algate**. See [credits](CREDITS.md). Visual assets and all current audio are **CC0-1.0**, with author attribution preserved. See [asset licensing](LICENSE-ASSETS.md).
