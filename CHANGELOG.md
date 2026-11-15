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



