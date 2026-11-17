# Editable sound recipes

Audio: CC0 1.0. Recipe code: MIT. Sound design: Codex GPT-6 Astra Medium.
The v2 recipe also layers ChipTone sounds (Tom Vian / SFB Games, CC0).
`chiptone_bases.json` preserves those WAVs as base64 data, keyed by filename.
To reproduce auditions, decode these into `outputs/chiptone-audition/`, then run
the desired recipe from a working directory with an `outputs/` directory.
Create `outputs/scifi-audition-v2/` before running the v2 recipe.
Dependencies: numpy and soundfile. No network, samples from external libraries,
or audio AI model is required. The later recipes generate all audio mathematically.

Installed mappings, source hashes and machine-stroke cuts are in
`sound_sources.json`. Crusher and pusher retractions are separate files so the
return sound follows the actual return phase. Music now uses the approved original focus arrangements. The approved destruction and
victory recipes now also provide puzzle completion audio.

The v6 recipe supplies conveyor rollers and hydraulic pusher extension, end-stop,
and return. Extension has a 0.16s pressure build and 0.55s travel; return is 0.50s.
End-stop audio is emitted on reaching the endpoint. Fast execution scales audio pitch
and movement together. Conveyor sounds are grouped spatially during belt phases.

`design_music_focus.py` produces four 96-bar seamless stereo loops for menu, lobby, race and puzzle. The menu track also supplies the launcher theme. `design_fall_motor.py` produces the receding pit-fall motor effect.
