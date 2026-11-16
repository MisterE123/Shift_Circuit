## 0.19.1 - Workshop hints and robot health

- Added descriptive, wrapped hover text over Workshop icons and labels.
- Added floating pixel health bars to all robots, with damage colors, smooth movement following and observer-matched ghost views.

## 0.19.0 - Standalone puzzle authoring and packs

- Added Workshop Puzzle type, click-selected objectives, starting loadout/facing, per-round card editor, turn limits and destruction failure option.
- Added puzzle playtests, fresh retries, target HUDs, completion records, main-menu browser and existing approval workflow integration.
- Added admin single/multi-puzzle mod export, validated manifests, built-in-first ordering and protected copying from installed packs.
- Fixed inspection beams incorrectly appearing on non-firing Patrollers and Ram Bots.
- Fixed inspection beams incorrectly appearing on non-firing Patrollers and Ram Bots.

## 0.18.0 - Pushable crates and predictable map obstacles

- Added loot/steel crates, pressure plates, animated trapdoors, three predictable enemies and visibly mounted Battering Ram equipment.
- Added Workshop brushes, rotation, persistence, portable validation and course-preview icons.
- Documented the revised standalone Puzzle editor and ordered mod export design; that editor is not implemented in this release.

## 0.17.6 - Authored arenas only

- Removed generated Assembly Line, Crossroads and Reactor Hall choices and bundled Service Yard. Existing bundled Service Yard records are retired with a storage backup; player copies, drafts and configurations are preserved.
- Campaign selection is empty pending author-selected missions. Race layouts use enabled authored boards and handle an empty catalog. Tutorial and isolated test fixtures remain available.

## 0.17.5 — Protected drafts and board validation

- Each player keeps one persistent Draft with a dedicated library entry and visible workshop label.
- Library selections open read-only previews. Returning to Draft restores the untouched draft, even after restarting the editor. Replacing it from a saved board requires explicit confirmation.
- Reset Draft requires confirmation, clears undo history and unlocks size selection. Painting/rotation lock size persistently; resizing is rejected server-side after that point.
- Submission, enabling and export require at least two checkpoint candidates. Existing one-candidate submissions cannot be enabled. Reachability checks remain enforced.
- Automatic routes still cap at available reachable candidates after reserving one for the start.

## 0.17.4 — Flat connected pushers

- Redesigns the pusher housing to 0.48 nodes tall and the moving plate to 0.38 nodes tall.
- Removes the translating fixed-length shaft. A separate rod stays anchored inside the housing and changes length to meet the animated plate, during both preview and execution.
- Keeps existing editable housing/plate textures and adds an independent sc_surface_pushrod.png texture.
- Tests check connection across the full stroke in all directions, actual entity extension/retraction callbacks, mesh height, UVs and normals.

## 0.17.3 — Collect after movement

- Movement no longer grants pickups immediately. After all command moves and pushes finish, surviving robots collect only from their final squares, in register priority order.
- Conveyor substeps, pushers and weapon displacement collect at their respective phase boundaries after movement animation. Mechanical Arm retains its separate reach action.
- AI planning uses the same phase-end collection rules. Items crossed during Dash, Move 3 or reverse movement stay on the board; falling before the phase ends grants no pickup.
- Regression coverage includes Blink, conveyors, pushers, intermediate items, falls and being pushed off an item by a later command.

## 0.17.2 — Visible robot previews and local-player menu

- Replaces blank native model widgets with 24-frame turntable images rendered from the actual meshes and UV-mapped textures. The root cause of the client widget failure remains unconfirmed; the selection menu no longer relies on that widget.
- All 16 preview sheets are checked for visible content in every frame and distinct rotation frames. Regenerate after model/texture edits with tools/robot_previews.py.
- Player name singleplayer sees disabled multiplayer controls. Queue, room creation, join, watch, and find-match requests are rejected server-side; direct room creation and matchmaking also exclude this name. Solo modes remain available.
- Automated regression checks and headless engine smoke checks run; live client visual confirmation is still pending.

## 0.17.1 — Sixteen selectable robots

- Adds Rivet, Surveyor, Mantis, Dynamo, Porter, Beacon, Crate, Skitter, Sentry, Spindle, Beetle and Relay, each with a distinct mesh and editable texture.
- Four selection pages retain large rotating previews. Selection persists, and reopening the menu returns to the selected body's page.
- All 16 bodies share the same gameplay stats and equipment mounting convention.
- Checked all pages, selections, mesh uniqueness, textures, normals and in-game spawn through automated tests; inspected an offline roster render.

## 0.17.0 — Clearer phases, wall lasers and robot selection

- Phase-order HUD uses distinct colors, numbered steps, readable labels and a white active border. Editable pixel art remains in art/ui.
- Single-speed turning conveyor arrows are green; double-speed arrows stay yellow.
- Laser emitters are thin edge walls. Their squares remain usable, the emitter edge blocks movement and incoming rays, and outgoing beams hit robots occupying the emitter square. Applies to single/double/triple emitters and all orientations.
- Main menu Choose Your Robot offers Courier, Scout, Loader and Walker with rotating 3D previews and persistent player selection. Models are cosmetic and have individual editable textures.
- Admin approval and enabling are one state: Enable publishes a submission, Disable removes public access. Authors retain access to their own saved configurations.
- Robot weapons and their inspection beams are inactive throughout round 1. All weapons activate from round 2; fixed board lasers keep their normal schedule.
- Verification: 29 regression scripts and native engine smoke checks. Live client visuals remain unverified; pixel HUD and model geometry were inspected with offline renders.

## 0.16.0 — Routes, review and recoverable equipment

- Thermal Camera: collectible animated sensor, Automatic aim, nearest clear cardinal target selected each weapon phase, toggleable and supported by AI.

- Start uses a checkpoint candidate. The course designer supports clicking a start and ordered checkpoints, with shared editing permissions and saved routes.
- Admin test lab submission review: searchable boards/configurations, previews, test-room playtesting, approval, enable/disable and persistent submitter notes.
- Blink consumes one charge after a successful jump. One jump maximum per round; blocked landings preserve the charge.
- Destruction clears collected equipment and weapons, returning the default green laser. Blueprint Archive restores one selected item copy on respawn; the archive itself is lost unless selected.
- Weapon types appear once in the loadout, without duplicate spare counts.
- Verification: 28 regression scripts and native engine smoke tests; dashboard checked with a rendered preview. Live client visual testing remains pending.
- Missing hull reduces next-round card allowance to a minimum of five; fixed lasers reach across 40-square courses.
- Automatic dashboard changes, gearbox aim locking, editor HUD suppression, square workshop icons, view-directed placement and full enclosure cleanup on resize.

# 0.15.2 / Hull, lasers and workshop usability

- Each missing hull point removes one card from the next deal, with a five-card minimum after upgrades and disruption. Applies equally to players and adaptive AI.
- Fixed lasers and their previews reach the full course boundary, including 40x40 courses, stopping at walls or robots. Robot weapon range remains equipment-dependent.
- Dashboard changes save immediately. Fire direction is visibly locked without Aim Gearbox; loadout controls lock after commit and during execution.
- The workshop hides the gameplay HUD, uses square icons, and snaps placement orientation to the viewing direction. Playtests restore the gameplay HUD.
- Resizing clears old upper enclosure walls and removes the old outer shell when shrinking.

# 0.15.1 / Ghost alignment and supply timing

- Raised the ghost robot ring and snap bodies into their ghost pose immediately, keeping head equipment aligned. Cones are narrower and converge above the owner's robot rather than at floor level.
- YOUR ROBOT uses the highest HUD drawing priority. Powerup nametags use readable names without underscores.
- Spawners roll only on their due round/phase, with a default 50% chance. Failed rolls cannot retry in the same round, and occupied pads do not reroll. Converted loose-pickup pads use staggered phases. The editor exposes phase and spawn chance.

# 0.15 / Shared course designer and workshop

- Fixed 10x10 and 20x20 board pieces in a 40x40 maximum course grid. Creator-selected board limits, optional collaboration, adjacent placement, and connected-removal checks replace voting.
- Searchable, paginated board inventory with large tile-icon previews generated from saved board data and a detailed Inspect view.
- Named saved course configurations: immediate owner access, admin approval for public access, and reapproval after edits.
- Disconnecting racers retain their robot and become AI, using their existing dealt hand and preserving committed commands.
- Grouped editor palette, fixed size controls, spawners instead of loose pickup brushes, and a Rotate tool for placed conveyors and machines.
- Larger isolated arena allocation region; existing arena banks are left untouched.
- Verified with 25 automated test scripts, rendered designer/editor/inspect previews, and a native 40x40 server smoke test with seven worker-planned racers. Native startup reported a brief 1.18-second maximum lag peak; live multi-client visuals remain unverified.

# 0.14 / Round cameras and racer HUD

- Scheduled spawners roll random positive supplies, equipment and weapons without replacing occupied pickups.
- Two execution hotbar tools orbit the camera smoothly. Round completion returns the flight view above the robot.
- Racer HUD sorts by finishing order and checkpoints passed, with readiness, execution, reboot and finished indicators.
- Aim Gearbox is smaller, lower and no longer spins. Equipment scrolling is silent.
- Robots slide into pits, accelerate downward and disappear below the floor before rebooting; mounted equipment follows them.
- Editable pixel-art bottom-left phase strip highlights commands, express conveyors, conveyors, pushers, rotators, weapons, lasers and crushers.
- All 24 automated test scripts pass, including falling/reboot behavior and all eight phase highlights.

# 0.13 / Unified robot dashboard

- One loaded weapon, relative Front/Back/Left/Right aiming, and migration of old secondary weapons into spares.
- Integrated equipment cards, spare weapon icons, detailed hover descriptions, and editable pixel-art dashboard panels.
- Blink guarantees one card and one successful jump per round. Extended Range is passive and stacks +3 squares per copy.
- Fixed malformed test-room and multiplayer labels and the missing zero-checkpoint HUD texture.
- Verified with 22 automated test scripts, a rendered layout preview, and native server smoke checks. A live-client visual review was not performed.

# 0.12 / Priority cards and robot systems

- Shared numbered deck, pixel Priority ID badges, descending priority within each register, and sequential move/push animation.
- Z locates your robot; a private pixel-art YOUR ROBOT waypoint follows its movement.
- Pit borders are narrow entities generated at actual solid/pit edges. Ghost opponents float higher. Player recovery checks sit beyond the enclosure.
- Hunters spawn at safe distributed posts and hunt within a local radius, patrolling otherwise. Only racers share the start.
- Collectible head-mounted equipment, primary/secondary loadouts, independent secondary aim, distinct ray effects, scheduled supply pads, arm reaches, disk retention, memory reboot, gyro toggle, Electroshield and consumable Titanium Hull.
- Continuing races, recorded finishes, full/ongoing-match spectators, and private admin test scenarios.
- Editable textures and pixel sources; Workshop spawner scheduling and new part brushes. Salvage remains deferred.

Verification: 21 automated test scripts passed. Native Luanti smoke checks cover isolated arenas, seven background planners, unique card IDs, equipment mounts, and admin scenarios. No live client visual review was performed for this build.

# 0.11.1 / Eight racers, humans first



- Increased room, queue, and controller seating to eight humans, with a hard cap of eight total robots.

- Expanded AI votes and solo Racer selection to 0â€“7. Bots use only seats left after humans; combined solo opponents also obey the cap.

- Public voting rooms accept incoming queued humans before launch. Room labels and the roster fit eight seats.

- Verified eight humans/no bots, five humans/three bots, one human/seven bots, rejection of a ninth human, and public queue filling. Full regression suite passed.



# 0.11 / Workshop, mixed courses, pixel UI, and shared-square ghosts



- Added weighted U-turn, Move 3, and Back 2 cards to the shared human/AI deck. AI ranks survival above progress and prefers later survival if death cannot be avoided.

- Added shared-start and shared-reboot ghosts. Per-player observers keep your own robot full-size on the square while opponents float. Larger cones point to the actual square center. Ghost robot lasers are hidden and disabled.

- Added an integrated 5x5â€“15x15 editor, independent overlay brushes, autosaved drafts, undo, playtest, player submissions, admin approval, and portable JSON export/import. Checkpoints are candidate locations, numbered at course assembly.

- Races mix one to four platforms; multiplayer votes select platform pool/count and requested checkpoint count. Bridges preserve platform interiors. Approved custom levels join the pool.

- Added two-hull repair pickups and end-of-round repair pads. New pickup model, launch pad art, pit borders, hazard edges, and a consistent two-node floor/apron grid.

- Rebuilt key HUD/menu assets as editable hard-pixel PNGs. A dedicated Next Goal dock and private world marker point to the next required item/checkpoint or reboot location.

- Wall rendering and ray clipping now share wall-segment geometry; beam endpoints stop at the wall face. Last laser provenance is retained in robot state to help diagnose reports.



Validation: full rule/controller/session/asset/audio suite; 36 edge-start AI cases; 1,200 thin-wall tests across directions, powers and translated courses; private observer views/cone placement; ghost reboot; variable platform sizes; repair timing; voting; editor permissions and lifecycle. Native headless Luanti checked large mixed courses, background workers, editor playtest/export and arena isolation. The specific reported through-wall incident was not reproduced, and in-client visual review remains pending.



# 0.10 / Concurrent planning and solo play



- Hunter/Racer planning runs in Luanti workers from deal time, concurrently with human card selection. Each job has its own board snapshot and hand. Main-thread validation rejects unavailable cards; match cleanup invalidates old results. Engines without the worker API use bounded coroutine slices.

- Added tutorial, campaign collectible objectives, solo race configuration, separate opponent intelligence/count controls, and comparable persistent turn records. Campaign Patrols repeat inspectable patterns.

- Added an original Hunter model with editable texture, a terminal-style command dock at the top, start markers, checkpoint direction markers, and event-specific particles.

- Reboot restores saved checkpoint facing. Board construction batches node changes and avoids building an unused arena before match start.



Validation: rule/controller/session/geometry/audio suites; worker privacy, finite-hand validation, cancellation and fallback tests; real headless Luanti worker completion during the human programming phase; isolated enclosed arena builds. Visual playtesting of this build remains pending.



# 0.9 / Music, responsive audio, and lethal crushers



- Added two ElevenLabs techno tracks, edited into restrained stereo loops. Personal music fades between lobby/match contexts and ducks during execution.

- Added persistent music/effects controls and per-player loop cleanup. Menu refreshes do not restart music; inspection remains quiet.

- Added menu and programming clicks, differentiated selection/undo/Commit/rejection, turns, Blink, shields, checkpoint/results, queue matching, countdown, blocked movement, reboot, and machinery cues. ElevenLabs assets and their generation IDs are recorded in sound_sources.json.

- Corrected crusher consequences: active strikes on steps 2 and 4 destroy robots through shields, with a CRUSHED cause message. Harmless preview animation does not damage robots.



Validation: music handle lifecycle, crossfade/ducking, volume persistence, effect isolation, card sound hooks, decoded audio levels and loop boundaries, lethal crusher regressions, existing controller/session/rule suites, and native server startup. In-client listening and mix review remains pending.



# 0.8 / Online sessions, voting, opponents, and presentation



- One server now hosts private solo campaigns and multiplayer races concurrently. Match arenas spawn on demand in independently owned slots; empty slots are reusable and unowned terrain is skipped. Solid floor, walls, and ceiling enclose each arena and the shared hub.

- Added a pixel-art Control Room, open multiplayer rooms, FIFO public queue, host-start rooms, board and AI-count voting, and timed queue/rematch voting windows. Three board layouts and 0â€“4 AI racers are available.

- Added automatic solo results/next-mission screens, multiplayer result rankings, and a persistent server wins leaderboard.

- AI now uses five hull, shared shield/pickup/damage/reboot rules, finite dealt cards, and multi-step simulation. Hunter AI predicts previous-round human motion to attack; Racer AI scores route progress and tactical damage without reading private cards.

- Added floating checkpoint badges and crusher activation-step nametags. Closed curved belt sides/undersides/end caps and replaced the arrow elbow with a tangent-aligned head.

- Sounds are scoped to the session's players; player HUDs, attachment cameras, entities, and claims are cleaned up when a room empties.



Validation: existing rules/controller/asset checks, AI privacy and finite-hand checks, simultaneous-session integration, protected-terrain allocation, queue/voting/rematch/results lifecycle, and a real Luanti headless server smoke test. Actual multi-client visual/load testing remains pending.



# 0.7 / Hull, immediate pickups, sound, and editable assets



- Player hull increased to five, including reboot; HUD and inventory show remaining hull.

- Item effects apply on entry from commands, intermediate Dash steps, Blink landings, conveyor movement, and pushes. Floating/shrinking pickup animation starts when the rendered robot reaches the square.

- Clarified Dash and Blink in inventory card descriptions, HUD, and controls.

- Added six ElevenLabs-generated positional sound effects: movement, pickup, laser, impact, crusher, destruction. No sound plays for harmless inspection beams.

- Curved conveyors now share raised slats, pale tread highlights, and rail fittings with straight conveyors.

- All OBJ models have explicit recalculated flat normals and nondegenerate UVs. Added editable per-asset/family PNGs, MTL references, and asset editing instructions.



Validation includes five-hull damage/reboot, immediate collection and protection, Dash versus Blink pickup behavior, animation/sound hooks, every model's normals/UVs, audio file format, existing rule/controller suites, and native server smoke. In-client visual and listening review remains pending.



# 0.6 / Direction, motion, and destruction feedback



- Corrected the shared yaw conversion using the actual Luanti client transform, which negates entity rotation before applying its matrix. Fixes visible robot turns, cardinal belt arrows, corner orientation, and beam facing together.

- Moved Blink pickup off the fixed-laser firing lane. Verified collecting Blink itself does not damage a robot.

- Added destruction causes (fixed laser, robot weapon, crusher, pit), a prominent destruction/reboot message, marked wrecks, and sparks.

- Replaced rapid robot position smoothing with timed eased movement. Shortened other execution phases and increased inspection machinery animation speed while preserving half-intensity preview behavior.

- Added regressions for the client rotation matrix, both corner openings in every orientation, destruction causes, and timed robot travel.



Engine reference: [Luanti client entity transforms](https://github.com/luanti-org/luanti/blob/5.18.0/src/client/content_cao.cpp#L972). Automated checks pass; in-client visual verification remains pending.



# 0.5 / Conveyor rebuild, collectibles, and planning deadline



- Replaced corner conveyor wedges with a continuous animated curved tread, clipped at each opening.

- Replaced conveyor arrow textures with geometry pointing in the same direction as tread movement.

- Redesigned crusher gantries with four floor-supported columns and an elevated working head; floor mechanisms still coexist underneath.

- Added six distinct collectible meshes: battery, shield, card cache, phase ring, weapon module, and spiked jammer.

- Removed camera buttons and camera chat switches. Flight hint: "Use K to enter flight mode".

- Added a 60-second planning deadline for two or more seated players, a persistent autofill warning, and an urgent final-ten-second warning. Empty slots draw randomly from unused dealt cards; selected cards and their order are preserved. Solo play remains untimed.



Validation: rules suites, runtime/controller integration, deadline regressions, geometry audits, and native headless smoke test pass. Models inspected with an offline preview; in-game visual verification remains pending.



# 0.4 / Readability, layers, and geometry corrections



- Added an automatic Play menu with prominent Start Campaign / Start Multiplayer Race buttons and a lobby Start Game tool.

- Replaced the inventory text block with visual stat cards, module tiles, compact roster, and hover tooltips.

- Added a pointed-object HUD description using a nine-unit raycast and fitted selection boxes.

- Separated crushers into an overhead rules/rendering layer, including a crusher over a conveyor and a crusher over a rotator. Added telescoping pistons.

- Corrected mesh yaw to match logical directions. Corrected OBJ X mirroring so checkpoint numbers read normally.

- Matched beam origins, height, and spacing to the emitter barrels; subtracted muzzle length from rendered beam length to preserve collision endpoints.

- Added alpha-blended beam textures and enlarged conveyor arrows.

- Rebuilt wall and rotator models from cuboid union surfaces, removing coincident internal/exterior faces.

- Added curved conveyors that turn transported robots, curved rails, and tangent-aligned wedge slats with non-overlapping gaps.

- Renamed visible mechanisms to Crusher, Left Rotator, and Right Rotator.



Validation: 43 rules/geometry tests pass, plus controller integration checks and mesh/texture audits. The real Luanti headless smoke test passes. These rendering corrections have not yet received an in-client visual playtest. Coordinate conventions were checked against the [Luanti OBJ specification](https://docs.luanti.org/for-creators/models/obj-spec/).



# 0.3 / Visual controls and execution presentation



- Replaced text player stats with seven icon/pip HUD gauges; moved exact values and roster into inventory.

- Added a dedicated hotbar Commit tool with disabled, ready, and locked appearances. Removed the E shortcut.

- Added harmless half-intensity inspection animations, including clipped dim previews for fixed and robot weapons.

- Added gold-marked double conveyors with two separately resolved movement steps.

- Made robot weapons automatic, free, and simultaneous during each pulse; removed firing cards from the dealt deck.

- Slowed execution to 1.5-second phases and added a distinct animated card-reading phase.

- Added independent robot-following spectator cameras and restoration of each viewer's original position, angle, and field of view.



Validation: 35 rule tests pass, plus a simulated-engine controller test covering inspection isolation, visual gauges, Commit readiness, removed E binding, card animation, separate spectator cameras, and exact view restoration through a complete round. A real headless Luanti 5.18 smoke test verifies entity previews and Commit registration. This pass was not visually playtested through desktop automation.



# 0.2 / Factory and controller rebuild



- Replaced the modal programming console and board diagram with hotbar cards and a five-slot HUD around the live 3D board.

- Added native walking/free flight; removed per-tick camera teleports that caused vibration during movement and turning.

- Added a host-controlled multiplayer lobby and three solo/cooperative campaign missions with enemy planners.

- Added shuffled finite command hands, single-use card selection, persistent hand bonuses, and temporary next-draw penalties.

- Added shields, energy cells, phase modules, range modules, cache upgrades, and jammer pickups.

- Added single/double/triple lasers, robot pulse weapons, timed pushers, and quarter-turn rotators.

- Added shared beam collision queries, stretched beam entities, and impact sparks.

- Rebuilt robots, presses, conveyors, and edge walls with original material-mapped geometry.

- Replaced four-node top surfaces with single full-tile visual meshes over invisible collision supports.

- Added moving conveyor slats, synchronized press/pusher motion, and animated rotator/robot turns.

- Saved mission unlocks and completed-mission modules per player.



Verification: 10 original rule tests and 16 expansion tests pass. Two real local Luanti clients passed finite-hand and readiness checks, a full multiplayer round with redeal, enemy planning, and a full cooperative campaign round. The test server reported a ~2.1-second peak during the synchronous arena rebuild. Native camera locomotion replaces the jitter-producing loop; final subjective camera smoothness has not been rechecked through automated UI control after the user stopped Computer Use.




### Menu clarity and grouped enemy movement
- Corrected nine-slice borders; selected buttons use green outlined states and editable fields have visible backgrounds.
- Content-sized scrolling replaces pages in course boards, saved courses, robot previews, puzzle lists, workshop library, room browser, reviews and leaderboard. Scroll gestures preserve position without action sounds.
- Audio controls use editable pixel speaker icons and hover descriptions; workshop captions wrap inside their cells.
- Floating goal flags are green, twice as large and raised above the board.
- Independent enemy commands animate together; overlapping paths, pushed chains and scripted sight checks retain priority order in separate movement updates.

- Multiplayer programming grants 180 seconds in round one and 90 seconds thereafter; each countdown has a proportional HUD bar with warnings at 20 and 10 seconds.

### Pickup rewards and board readability
- Repair and power-cell pickups fully restore their respective resource; shields provide three charges. Range upgrades add five squares each; caches add two cards each, capped at three bonus cards.
- Remote Control costs one power; tractor and repulsor beams have no power cost. Battering Ram pushes deal two damage.
- One camera orbit tool: left-click left, right-click right.
- Nearby names are per-viewer and limited to the nearest six: enemies, machines and supplies within 8 nodes, racers within 16, jam warnings within 10. Full descriptions remain available on pointing. World labels stay below interface panels.
- Free-flight movement is 25% faster (speed multiplier 1.2 to 1.5).

### Robot showroom and distinct chassis
- Robot selection now has a large selected-body preview and a fixed 4-by-4 gallery, with immediate saving and green selection outlines. Removed overflowing scrolling background panels.
- Replaced twelve similar chassis with distinct knuckle-walker, tripod, insect, single-wheel, forklift, tower, cargo-safe, crab, pyramid, balancing-wheel, shell and dish-receiver shapes. Existing selection IDs and editable textures are preserved; lobby bodies and rotating previews regenerated.
- Extended the Workshop palette panel to contain second-row captions.

- Floating pixel activation badges: crushers/pushers show their five-step schedule and current register; powerup spawners show the next three scheduled round chances. Per-viewer visibility is limited to six nearby badges within 14 nodes. Editable source images are in art/ui/schedules.

- Factories now have editable and exportable round schedules, defaulting to every three rounds from round one. Each outlet attempts once per due round; jams retry only when next due. Floating round badges and the Workshop Factory Timing form share the schedule.

- Revised factories to produce one or two crates total every round, rotating across clear outlets. Removed the factory timing control; legacy schedule fields no longer delay production. Factory badges now read 1–2 CRATES / EVERY ROUND.
- Redrew the checkpoint waypoint as a shaded green flag silhouette with a small downward pointer; removed the chunky square frame and reduced pixel enlargement.

- Lobby HUD now prompts Press I for main menu. Programming hotbar has an editable pixel-art Command Palette >_ surround sized to the available hand. Added bottom padding beneath the Workshop & Community buttons.

## Match reconnects and ghost presentation

- Leaving an active race now hands the same robot to a low-intelligence AI, including menu departures. Network reconnects reclaim the robot automatically; joining its room again also restores control. Committed programs, dealt hands, health, equipment and progress remain intact. Pending AI results cannot overwrite a returning player's program.
- Reconnecting pilots get their controls and HUD back, with a view above their robot during planning or its follow camera during execution. Empty disconnected rooms allow a five-minute reconnect window before releasing the arena.
- Each overlapping ghost group shows one full-size robot per viewer: their own when in the group, otherwise a stable representative. Others float at reduced size.
- Non-ghost robots can hit ghosts with weapons, including automatic aim and beam effects. Ghost robots still cannot fire, and walls still block shots.

## Shared respawn visual alignment

- Ghost cones keep their pointed tip above the occupied square and follow the visible floating robot with their broad end. Rotation is applied before sending the position update, including changes with a stationary tip.
- Rebooting clears leftover fall/conveyor movement, restores exact saved facing and resets both public and private robot views to their intended positions.
- Regression coverage includes round-three shared respawns, all-axis cone endpoints, stationary-tip rotation publication and moving ghost groups.

## Straight conveyor entity and network reduction

- Replaced ten independently moved slat entities with one client-animated B3D tread. Straight conveyors now use four entities including floor, rails and arrow, down from thirteen. Turning conveyors remain at four.
- Straight tread loops run on clients, with speed updates only at phase/rate changes. Normal and double conveyors retain half-speed inspection and pause outside their execution phases.
- Clipped end slats prevent geometry extending into neighboring tiles; loop endpoints match. The existing sc_surface_conveyor.png texture remains editable.
- Added a 100-conveyor regression fixture proving 400 entities rather than 1,300, with no ongoing tread movement/property updates during steady animation.

## Arena entity lifetime and respawn recovery

- Active arenas temporarily keep their bounded map area loaded, including distant machinery, respawn squares and falling robots. All references are released on room cleanup/rebuild; no persistent server setting is changed.
- Inspection and execution skip missing machine visuals instead of crashing. Invalid preview beams and robot models are recreated, and living respawned robots explicitly regain visibility.
- Added regression coverage for removed machine entities, lost public/private robot models, respawn visibility and balanced arena loading/release.

## Dashboard layout and scrolling

- Replaced dashboard card backgrounds with clipped nine-slice images so equipment panels stay inside the scroll area instead of spilling across the menu and board.
- Equipment now uses full-width rows with icons, names and concise descriptions on the left, and toggles, archive selection or passive status aligned on the right.
- Preserved immediate saving, hover details and locked loadout behavior. Added exact scroll-length and panel-clipping regression checks.

## Visible mechanical arm, brake and equipment semantics

- Installed arms now remain visible above other head equipment with a folded rest pose, articulated links and opening gripper fingers. Initial placement and following are applied before visibility, avoiding travel from stale spawn locations. Reach, grip and retraction are eased and pickup timing follows the grip.
- Expanded the admin mechanical-arm scene with three supplies, an adjacent checkpoint across a wall, replenishing spawners and movement lanes.
- Added collectible Electromagnetic Brake with editable pickup/icon/mounted assets. Enabled brakes block robot push chains, pushers and tractor/repulsor displacement; they do not stop commands or conveyors. Installed brakes remain visible while disabled.
- Arm, Thermal Camera and Titanium Hull are passive; obsolete disable flags are ignored. Thermal Camera unlocks Automatic aim without forcing a change to the selected direction.
- Unique equipment and duplicate weapon types no longer stack. Redundant pickups remain for other robots, and arms skip them. Extra arms, disks, range, Blink and titanium reserves keep useful stacking; Cache stops at two copies. Holographic Memory is unique because destruction discards unused equipment.

## Powered weapons and equipment fixes

- Triple Laser: three damage for one power per shot, with three visible barrels and beams.
- EMP Generator: two power per shot; the first robot hit skips its remaining commands in that round. Walls and crates block it. Commands resume next round; board machinery and automatic weapons still operate. Existing special-weapon shield protection applies.
- Insufficient weapon power automatically loads an affordable owned laser, or the free Green Laser, preserving the original weapon in inventory.
- Blueprint Archive defaults to random eligible-item preservation; specific selections remain available.
- Hard Disk can reserve Wait. Long menu tooltips wrap at word boundaries.

## Mounted weapon movement

- Weapon and equipment mounts now attach directly to their robot, sharing client movement and body rotation instead of receiving independent position updates.
- Only relative turret aiming is smoothed; forward-facing weapons no longer lag behind body turns. Recoil, ghost sizing, visibility and respawn are retained.

## Reset Button

- New collectible consumable with an editable red-button pickup model and icon, random drops/spawns and puzzle starting-loadout support.
- RESET HAND in the planning dashboard redraws movement cards from the round deck, clearing the queued program and Hard Disk reservations while keeping blue direction and Blink. Each use consumes one copy; fixed puzzle hands, committed programs and execution cannot be reset.

## Articulated arm following

- Attached both arm links, the claw and its fingers to the robot. Reach poses are solved relative to the robot while pickup targets remain world-fixed. Folded arm pieces no longer receive separate world-position updates during robot movement or turning.
- Verified attached movement, target reach at full and ghost scale, existing reach/retract animation, destruction/respawn and admin lab lifecycle.
