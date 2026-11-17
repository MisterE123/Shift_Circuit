# ContentDB submission preparation

## Package fields

- Type: Game
- Technical name: `shift_circuit` (confirm availability during submission)
- Title: Shift Circuit
- Short description: Program your robot through factory puzzles and turn-based races.
- Maintenance status: Work in Progress
- Code license: MIT
- Media license: CC0-1.0
- Minimum Luanti version: 5.18.0
- Source: https://github.com/MisterE123/Shift_Circuit
- Tags to select where available: puzzle, strategy, multiplayer
- AI disclosure: significant generated content; complete the site's AI disclosure fields.

## Long description

Program five commands, then watch your robot execute them on a moving factory floor.
Plan around conveyors, pushers, lasers, crushers, crates and other robots. Dealt
cards and priority numbers make every round a new planning problem.

Learn the controls through two authored tutorial puzzles. Build race boards and
independent puzzles in the Workshop, or join races with up to eight human and AI
racers. Course layouts combine 10-by-10 and 20-by-20 boards within a 40-by-40 area.
Finished players and spectator-only entrants can follow other robots.

The Workshop includes saved drafts, a server library, admin review, and admin
export of puzzles and race boards as installable data mods. Exported maps can be
bundled with the game or installed on another server.

This is a work in progress. Multiplayer matches do not survive a server restart.
Newly authored arenas stored in a server's library are not automatically bundled
with a release. The release notes should list the boards actually included.

## AI disclosure text

Significant code and asset-generation scripts were produced with Codex GPT-6
Astra Medium under human direction and review. This includes original models,
textures, interface artwork, sound design and music composition. Music and most
sound effects are rendered by editable procedural synthesizers, not by an audio
generation model. The title banner was created using OpenAI image generation.
The game design, authored tutorial/arena layouts, testing and review include
human contributions. CC0 ChipTone layers are credited separately. No ElevenLabs
recordings are included in the current release.

## Screenshots

Use `art/Screenshots/Game.png` and `screenshot.png` as actual gameplay
screenshots. The approved title banner may accompany them, but is not a gameplay
screenshot. Do not upload the rejected generated factory illustration. Ensure the
pictured authored arenas are included in the release or explain that they are
examples built with the included editor.

## Release procedure

1. Confirm the intended race boards to bundle; export each as a mod and install
   it under the game's `mods/` directory. Test a fresh world with the final set.
2. Run the regression suite and a clean-world Luanti smoke test.
3. Commit and push the reviewed source to the source repository before creating
   a ContentDB release from that revision. Do not upload a revision missing the
   local fixes.
4. Run `python tools/package_release.py` for a clean submission archive. It
   excludes Git, worlds, caches and local credentials. Editable sources and
   license notices remain included.
5. Fill the AI disclosure, WIP status and minimum engine version; upload actual
   screenshots. Confirm technical-name availability in ContentDB.

No ContentDB upload or publication is performed by these preparation steps.

## Preparation validation (2026-11-16)

All automated regression files passed. A separate Luanti 5.18 fresh-world server
started with mod security enabled, loaded the renamed tutorial pack, validated
and imported a race-board test pack twice without duplication, and shut down
cleanly. The test pack is not included in the release.

Current release includes two tutorial puzzles and seven authored race boards: LoopDLoop, OneWay, Parking Lot, Decrepit Assembly Line, The Spawn, Extractor Floor, Birthing Floor. LoopDLoop copy is excluded. No private world/library database is packaged.
