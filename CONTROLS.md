## Local player name

The built-in player name `singleplayer` is reserved for local solo play in this game. Multiplayer controls are unavailable for that name; connect with a named player account to use multiplayer. Tutorial, campaign, solo race, workshop and admin test scenes remain available.

## Robot selection and opening round

Choose Your Robot in the main menu offers 16 models across four pages. Use Previous and Next to browse large 3D previews. The choice is saved and used in subsequent matches; all bodies have identical gameplay stats.

Robot weapons do not fire during round 1, including AI weapons. They activate from round 2. Fixed arena lasers remain active. The bottom-left phase panel numbers and colors the eight phases, with a white outline around the current phase.

# Shift Circuit / playable build 0.11.1



The real 3D board is the only gameplay view. Programming uses the hotbar and HUD; there is no separate 2D board or modal programming form.



## Start and move



The **Control Room opens automatically** when you connect. No match board exists until somebody creates a game.



- **Tutorial** opens a short, safe checkpoint course.

- **Campaign** opens puzzle missions with a required collectible and checkpoints; configure enemy count and intelligence. **Continue Campaign** resumes your unlocked mission.

- **Solo Race** lets you choose a board, Hunter count, Racer count, and separate intelligence settings. Winning records count rounds and are compared only against the same board and opponent settings.

- **Quick Play** joins the public queue. Two to eight queued players form a room and build its course before the creator starts.

- **Create Multiplayer Room** opens a room friends can join from the room list. The host starts after voting.

- The creator chooses AI racers and may enable shared course editing. At match end, the leaderboard offers another course-building stage.

- **Server Leaderboard** shows persistent wins and games played. **Leave Match** returns to the main menu.



A single server runs these games concurrently. Each session has its own enclosed arena, robot state, and timer. A vacated location may be reused; occupied locations and unrelated terrain are not overwritten.



During a match, I opens the unified robot dashboard: status bars, one loaded weapon, relative aiming, spare weapons, and equipment cards. Hover over parts for their rules, stacking and costs. Apply changes before committing. Match Menu opens the Control Room. Point your crosshair at a nearby object, within nine world units, to see its name and a short description on the HUD.



**Use K to enter flight mode.** Press **Z** (the Zoom binding) to jump to a view above your robot. Your private **YOUR ROBOT** pixel marker follows it. During execution, the camera already follows your robot. WASD moves; the mouse looks. Space ascends and Shift descends in flight. Open the lobby with I or `/sc`.



## Program a round



1. Select a card with the mouse wheel or number keys. Slots beyond 9 are accessible with the wheel.

2. **Left-click** to append the selected card to the five-slot program at the top of the screen.

3. **Right-click** removes the last queued card and makes that card available again. With the Commit tool selected, **Shift + right-click** clears the sequence.

4. Select the **COMMIT tool in hotbar slot 1**, then **left-click**. Its border turns gold when all five cards are queued and shows a lock after committing. Execution starts once all seated pilots commit. E is no longer bound to committing.



With two or more seated players, each planning stage has a **60-second countdown**. The HUD warns that empty slots will be filled randomly, with an urgent warning in the final 10 seconds. At the deadline, unused cards from your dealt hand fill any empty slots without repeating a card. Your existing choices stay in order, and the program commits automatically. Everyone committing early starts execution immediately. Solo play has no countdown.



The slots after Commit represent distinct dealt cards. Duplicate command types may be dealt, but the same physical card cannot be selected twice. Cards that are already queued are darkened. Commit does not consume a card or count toward your hand allowance.



Player stats use visual HUD gauges: robot = hull, lightning = energy, shield = protection, stacked cards = hand allowance, warning triangle = next-draw penalty, flag = completed stations. The two module indicators show phase-jump and extended weapon range. Open **I** for exact values, your weapon and equipment, and hover descriptions.



## Inspection and execution cameras



During planning and lobby inspection, machinery demonstrates its behavior without changing the game state. Conveyors run at half their normal speed; press and pusher strokes use half travel; rotators and hovering pickups run more slowly. Fixed lasers and robot weapons show clipped preview beams with half-brightness color and glow. Preview rays never damage robots, spend energy, consume pickups, or advance the turn.



After everyone commits, each player follows their own robot with an execution camera. The hotbar switches to Orbit Left and Orbit Right: select 1 or 2 and click to turn the camera smoothly by 45 degrees. Commands execute in Priority ID order within each register. At round end, your flight view returns above your robot. Spectators without a robot return to their saved view. Free-flight movement is not continuously corrected.



| Card | Effect |

| --- | --- |

| STEP | Advance one tile |

| DASH | Advance two tiles, resolving each step |

| MOVE 3 | Advance three tiles, resolving each step |

| BACK | Reverse one tile without changing facing |

| BACK 2 | Reverse two tiles without changing facing |

| U-TURN | Rotate 180 degrees |

| LEFT / RIGHT | Rotate a quarter-turn |

| WAIT | Remain in place |

| BLINK | Jump two tiles to a safe unoccupied landing; costs one energy and requires the phase module |



Player robots start with **five hull points**, displayed as five HUD segments. Each unshielded damage point removes one hull; reboot restores all five. Pits still destroy a robot immediately.



**Dash drives through two squares:** walls block it, robots can be pushed, pits remain dangerous, and both squares can contain collectibles. **Blink jumps directly to the second square:** it bypasses the middle square and barriers, requires an empty safe landing, and spends one energy.



Your one loaded weapon fires automatically once per programmed pulse. Green and Double Lasers are free; Tractor and Repulsor cost 1 power, Remote Control costs 3 and fires once per round. Machines alive at the start of the weapons phase all fire, so opposing robots can destroy each other in the same phase. Energy is used for BLINK. An ability with insufficient energy has no effect. An invalid blink landing costs no energy. Phase movement skips intermediate pits and barriers; its landing must be safe.



## Allowance, pickups, and penalties



Each round uses a shared weighted deck with unique Priority IDs. Blink equipment guarantees one Blink card in the normal allowance, usable once per round. See SYSTEMS.md for the complete weights. Automatic firing needs no command card.



**Hand size = clamp(9 + cache upgrades âˆ’ temporary disruption, 5, 12).** All players still program five actions.



| Collectible / event | Effect |

| --- | --- |

| CACHE | Persistent +1 card per draw, up to +3 |

| JAMMER | âˆ’2 cards on the next draw only |

| Falling or destruction | âˆ’1 card on the next draw |

| SHIELD | Absorb one damage point; capacity three |

| CELL | Restore three energy; capacity nine |

| Blink equipment | One guaranteed Blink card and one jump each round |

| Extended Range equipment | Always active; adds three squares per copy to base range four |



Disruption stacks to four, is applied when the next hand is dealt, then clears. Bonuses and penalties never reduce the hand below five. Pickups are shared and consumed once; the first robot reaching one gets it. Collection occurs after the whole movement phase finishes. Only the final occupied square counts; items crossed along the way stay on the board. The item then rises and shrinks away. Conveyor substeps, pushers and weapon displacement also collect at their phase boundaries. One energy regenerates per round. A reboot restores at least two energy.



## Board and machinery



Each logical square has one mesh with one continuous texture. Thin edge walls block crossings and beams in both directions, while leaving both adjacent squares occupiable.



Every pulse resolves in this order:



**Read card â†’ robot commands â†’ double conveyors' extra step â†’ all conveyors' shared step â†’ pushers â†’ rotators â†’ automatic robot weapons â†’ fixed lasers â†’ presses â†’ pickups and service stations.**



Commands execute highest Priority ID first within each register. Belt conflicts use a deterministic order that rotates each round. Robots can push chains; an edge wall blocks the entire push. A machine displaced by an earlier belt push does not ride its original belt again.



- Conveyor assemblies have individual moving slat entities. Double conveyors have gold double-chevron markers and slats moving twice as fast as normal conveyors. They move in the express substep first; then all occupied conveyors move in the shared substep. The destination belt determines direction for that second step. Landing on plain floor ends the ride. A normal belt feeding a double belt does not grant a retroactive extra step. Walls, pushing, and pits are checked on every step.

- **Crushers** occupy an independent overhead layer. Their raised frames, telescoping pistons, and moving rams can sit over a conveyor or rotator without replacing that floor mechanism. On pulses 2 and 4 they destroy a robot caught beneath them, bypassing shields. Inspection motion is harmless. Overhead frames do not block horizontal gameplay beams.

- Pushers extend on their configured odd or even pulses and obey edge walls.

- Rotators smoothly animate a clockwise or counterclockwise quarter-turn.

- **Left Rotators** and **Right Rotators** are labeled by direction. Turning conveyors instead carry robots through a curved track and turn their facing as they enter the bend. Their slats follow a quarter-circle with tangent-aligned rotation; wedge-shaped corner slats avoid overlapping faces.

- Fixed emitters have one, two, or three barrels and deal that many damage points. A shield absorbs one point; remaining damage hits the hull.

- Beams are translucent stretched mesh entities with visible parallel rays and impact sparks. Their origins match each barrel's position and spacing. Their length is computed from the same wall/robot checks that resolve damage, stopping at the first obstruction. Robots behind the first target are protected even if that target is destroyed.

- Automatic robot weapons use the same hit resolver, with teal beams distinct from the fixed emitters' orange-red beams. Enemy drones plan movements and turns, then fire automatically too.



Visit service stations 1, 2, and 3 in order. A disabled pilot skips the rest of the round and returns near their last station on an unoccupied safe tile. Destroyed enemy drones stay destroyed for the mission.



## Campaign and multiplayer



The campaign has three escalating missions on variants of the factory: one drone, two patrol drones, then a three-drone lockdown with an armored foreman. The route objective is shared in cooperation: a pilot completing the route wins the mission for the team. Friendly fire is enabled.



Mission completion saves unlocked missions and installed modules per player in the world's mod storage. **Next Mission** carries modules forward. Selecting an unlocked later mission restores the saved modules. Starting mission 1 is a fresh equipment run. Mid-round state is not saved; a world restart begins in the lobby.



To host, use Luanti's **Host Server** option for this game, or run a dedicated server with a Shift Circuit world. Other clients connect using Luanti's normal multiplayer screen. No external account or service is required. The lobby host chooses the mode. Everyone else joins a seat and programs their own private hand. Late arrivals wait until the next programming phase. Leaving a seat or disconnecting removes that robot and cannot hold up readiness; reconnecting gets a fresh seat, not the old robot state. If the host leaves, another connected player becomes host.



## Current limits



This is a playable development build. AI predicts from previous-round public movement and simulates machinery, weapons, and hazards with a finite hand; it cannot read private queued commands. Hunter AI seeks damage, while Racer AI balances checkpoint progress against attacks that delay competitors. Players and AI use five hull and the same shield, pickup, damage, and reboot rules. Match balance is still early. Matchmaking and the Workshop editor are included; mid-match save/rejoin restoration is not implemented. The rules currently use a flat board; the HUD does not duplicate its geometry, so a future multi-level board will remain visible directly. Pixel-art assets use nearest-neighbor textures, but a perspective 3D camera does not guarantee screen-pixel-perfect alignment.





## Audio



Use **AUDIO** in the Control Room or match menu to choose music Off / Low / Normal and effects Off / Soft / Normal. These preferences are saved per player. The lobby and match have separate restrained techno tracks; transitions fade, and music becomes quieter during execution. Menu refreshes do not restart a track.



Short cues distinguish card selection, undo, Commit, invalid/full programs, movement, turns, waiting, blocked moves, Blink, conveyors, pushers, shield absorption, hull damage, destruction, reboot, pickups, checkpoints, match results, queue matching, and the final five planning seconds. Inspection machines do not repeatedly play gameplay effects. Sound and music remain private to your session/player.



## Opponents and reboot



Hunters and Racers draw from the same deck with the same allowance, bonuses, and penalties as human pilots. They begin planning in background workers when the hand is dealt, alongside human programming. They can use public board state and previous-round movement, but cannot see another pilot's hand or queued program. Intelligence changes search breadth and motion prediction, not health or card luck. Racers value both progress and tactical attacks that help them win.



Campaign Patrols are predictable obstacles: their inspection description shows their repeating five-step pattern. They do not pretend to be competing card-playing pilots.



Reboot restores five hull and the facing saved at the last checkpoint (or start). A start marker and checkpoint direction marker make that destination visible. Damage, shield hits, Blink, pickups, destruction and reboot have distinct brief particle cues. The top command dock shows each register being read.



## Goals, repairs, and shared squares



The pixel-art **NEXT GOAL** dock names the required mission pickup or next checkpoint (including the route's total). A personal gold marker points at its actual location. Collection and checkpoint completion advance it automatically. Destruction replaces it with the saved reboot location.



A **repair pickup restores 2 hull immediately**. A **repair pad restores 2 hull at the end of the five-card round**, provided the robot is alive and still on that square. Both cap at maximum hull; neither revives a destroyed robot.



Races start all robots on one shared square. A reboot also uses its saved square even when occupied. Robots sharing it enter ghost mode. Your own robot appears full-size on the tile; opponents float around it at half size, with larger translucent pointers ending at the tile center. Ghost robots do not fire or show their robot lasers. Machinery still applies. Ghosting ends upon separation or at round end; any robots still stacked then spread to nearby free floor.



## Card balance



Each hand is drawn without replacement from the same 30-card bag for humans, Hunters, and Racers:



| Command | Copies | Share of base bag |

| --- | ---: | ---: |

| Step | 7 | 23.3% |

| Dash | 4 | 13.3% |

| Move 3 | 2 | 6.7% |

| Back | 3 | 10% |

| Back 2 | 1 | 3.3% |

| Left | 4 | 13.3% |

| Right | 4 | 13.3% |

| U-turn | 2 | 6.7% |

| Wait | 3 | 10% |



While you hold Blink charges, you receive one Blink card per round. A successful jump consumes one charge; extra charges remain for later rounds. Precise movement and quarter-turns are common; long travel and specialized reversal are scarce. Long moves still stop at walls and resolve intermediate pits, pushes, and pickups.



## Mixed courses and workshop



Solo Race offers **Mix Platforms**, and multiplayer rooms offer the shared board inventory. Place 10x10 or 20x20 boards inside the 40x40 course grid. Search and inspect tile-icon previews, then save named configurations. Yours are available immediately; other players need admin approval to use them. See EDITOR.md for the full course designer controls.



Choose **Workshop / Build Levels** from the main menu. See [EDITOR.md](EDITOR.md) for building, submissions, approval, exporting, and bundling levels.



A room holds **at most eight racers total**. Humans take priority over the requested AI count: five humans permit three bots, and eight humans permit none. Bot votes offer 0–7; the room shows the actual count after reserving human seats. Public matchmaking also adds queued humans to open building rooms before allocating bots.



The racer HUD shows checkpoint progress and readiness, sorted with finishers first and then by checkpoints passed. Your row is highlighted. Spawners roll random positive pickups on their scheduled rounds; occupied pads keep the existing pickup.

Workshop: orient new pieces by looking in the desired direction; tool 2 rotates placed pieces. Race HUD panels stay hidden while building. In the dashboard, weapon, aim and equipment changes save immediately. Missing hull reduces the next hand by one card per damage point, never below five.
