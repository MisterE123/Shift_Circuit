# Shift Circuit



Playable Luanti 5.18+ factory-programming game, development build 0.17.6. Original artwork, models, maps, text, and working title; sound effects generated with ElevenLabs.



See [CONTROLS.md](CONTROLS.md) for gameplay, movement, the HUD controller, hand allowance, upgrades, weapons, campaign saves, and multiplayer hosting. See [ASSET_EDITING.md](ASSET_EDITING.md) for editable model textures and normals. See [CHANGELOG.md](CHANGELOG.md) for changes and verification.



See [SYSTEMS.md](SYSTEMS.md) for Priority IDs, loadouts, collectible equipment, supply pads, spectators, hunter patrols, and admin test scenes.

## Run



The working project is installed at `C:/Users/gbrru/AppData/Roaming/Minetest/games/shift_circuit`. Open the normal Luanti desktop shortcut, select Shift Circuit, and create a world. Restart a running world after code changes. The original Codex outputs/shift_circuit location links to this installed directory.



To install elsewhere, extract the `shift_circuit` directory from the ZIP into your Luanti `games` directory. Restart Luanti, select Shift Circuit, create a new world, and play. The Control Room offers a short tutorial, puzzle campaigns, configurable solo races, public matchmaking, and multiplayer rooms. Room creators choose the AI count and can enable collaborative course building. For multiplayer, use Luanti's Host Server option or a dedicated server. Other players use the normal multiplayer connection screen.



See [EDITOR.md](EDITOR.md) for the Workshop and portable levels. See [SERVER.md](SERVER.md) for the arena lifecycle and hosting setup.



## Source



- `mods/shift_circuit/rules.lua`: deterministic movement, edge walls, weapons, machinery, pickups, and objectives.

- `mods/shift_circuit/campaign.lua`: mission layouts, enemy plans, shuffled decks, and hand modifiers.

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



