## Pickup timing

Robots collect only after the movement phase is complete, from their final squares. All command moves and pushes resolve before pickups are awarded; passing across a pickup does not collect it. Conveyor substeps, pusher movement and weapon displacement use the same end-of-phase timing. The Mechanical Arm remains a separate animated reach action after commands.

## Thermal Camera

Collecting a Thermal Camera selects Automatic aim. With the camera enabled, the weapon retargets before every weapon phase to the nearest visible opponent in range along a row or column. Walls and intervening robots block sight; ghosts and teammates are excluded. Equal distances use a stable cardinal order. No target means Front. The sensor and weapon visibly turn. You can choose Front instead, disable the camera, or use manual relative directions with an Aim Gearbox. Automatic aiming costs no extra power; the weapon keeps its normal cost.

## Equipment loss and recovery (0.16)

Destruction removes collected weapons and equipment. Reboot supplies the default Green Laser. A Blueprint Archive lets you choose one owned item in the dashboard dropdown; one copy returns on respawn. The archive is also lost unless you choose to preserve the archive itself. Holographic Memory still determines the reboot position when it triggers.

Blink charges are consumed on successful jumps, at most one per round. Failed landings retain the charge.

Admins: open the Test Lab and choose REVIEW SUBMISSIONS to inspect boards or configurations, approve, enable/disable, playtest, or leave notes. Authors can read notes in their respective libraries. Private configurations remain available to their authors before approval; configurations not enabled publicly remain usable by their authors.

Course Designer: choose START & CHECKPOINTS, select the appropriate placement mode, then click candidate tiles. Checkpoints follow click order; click one again to remove it. Reset Automatic restores generated routing. Shared rooms use the same route for all builders.

# Cards, robot systems, and test scenes

Press **Z** (default Zoom binding) to jump to a view above your robot. A private pixel-art **YOUR ROBOT** marker identifies it. During execution, the hotbar contains Orbit Left and Orbit Right. Select tool 1 or 2 and click to smoothly rotate the camera 45 degrees. After the round, your flight view returns above your robot. Spectators without a robot return to their previous view.

## Priority and movement

Each round builds one weighted deck for all humans and adaptive opponents. Each physical card receives a unique Priority ID before the deck is shuffled and dealt. Higher IDs execute first **within the current register**; register 1 still precedes register 2. The active robot and ID appear on the HUD. Separate pixel labels below the command registers show their priorities; the selected hand card's priority appears in the HUD detail line. Card icons remain unobstructed. Identical movements can have different priorities.

Each actor's move and push chain animate before the next actor acts. Machinery and weapons follow the completed register. Predictable patrol enemies use scripted commands with priority zero, after dealt cards. Remote Control changes the target's unexecuted commands, preserving that target's original card IDs.

The weighted deck retains Step 7, Dash 4, Move 3 twice, Back 3, Back 2 once, Left 4, Right 4, U-turn twice, and Wait 3 per participating robot. Blink equipment guarantees exactly one Blink card per round. It occupies one place in the normal hand and cannot be retained with a Hard Disk. Draw allowances remain 5â€“12. Hard Disk reservations consume part of the normal allowance and receive fresh IDs each round.

## Loadout

Open **I â†’ LOADOUT** during programming, before committing. Install primary and secondary weapons from collected parts. Green Laser is the default primary. All collected equipment can coexist; there is no equipment-slot cap. Point at a robot to inspect its installed systems. Mounts, aimed turrets, ray effects, and the reaching arm are visible in the world.

| System | Effect | Power |
| --- | --- | --- |
| Green Laser | One damage per hit | Free |
| Double Laser | Two damage per hit | Free |
| Tractor Beam | Pulls target one square toward the source; obeys walls | 1 |
| Repulsor Beam | Pushes target one square; can push a chain or into a pit | 1 |
| Remote Control | Copies the attacker's remaining commands into the target's unexecuted registers | 3; once per round |

Shots occur automatically every register when affordable. Ghost robots do not fire. Beam tools and Remote Control cost power. Only one weapon fires. Standard shields block non-damaging beam effects as well as laser damage. Electroshield currently absorbs damage, not remote-control or displacement effects.

| Equipment | Behavior |
| --- | --- |
| Blink | One guaranteed card and one successful jump each round. The used hand card disappears. Consumes one collected charge on success. Additional charges allow use in later rounds. Costs 1 power. |
| Extended Range | Passive and non-toggleable. Each copy adds 3 squares to the base range of 4. |
| Command Cache | Passive equipment. Each copy adds one card to the hand, up to +3. |
| Mechanical Arm | Each copy grabs one orthogonally adjacent pickup per register, across walls, up to four. Also visits the next adjacent checkpoint. Animated links and claw reach the item; it floats up and shrinks on collection. Toggleable. |
| Aim Gearbox | Enables Front, Back, Left and Right aiming of the loaded weapon. The aim turns with the robot; it is not a compass direction. |
| Hard Disk | Select a movement card and press E to retain it next round. One reservation per disk; press E again to unmark. |
| Holographic Memory | Consumes one copy on destruction and reboots on that square with that facing at round end. Pit falls still reboot at the checkpoint and do not consume it. Toggleable. |
| Gyro Stabilizer | Enable for the coming round to ignore conveyor and rotator turns. Programmed turns still work. Resets off when the next hand is dealt. |
| Electroshield | Automatically spends 1 power to absorb each incoming damage point while enabled. Ordinary shield charges are used first. |
| Titanium Hull | Consumes one copy to survive a crusher strike without hull damage. The broken plating produces fragments. Toggleable. |

Power begins at 4, caps at 9, regenerates 1 each round, and Cell pickups restore 3. Blink costs 1. Reboot guarantees at least 2 power.

## Supply pads and races

The Workshop has a **Spawner Setup** button. Choose either a first round plus interval, or explicit round numbers. Each due, empty pad rolls a random weapon, equipment item, or supply. Repair, shield and power cells are more common; Jammer maluses and the free default laser are excluded. Older fixed-item pads also roll randomly. Select the spawner brush and paint a floor square. A pad never overwrites an uncollected item. Pads and schedules travel with exported levels and assembled courses.

Finishing a race records the result without stopping unfinished racers. Finishers can spectate, queue again, or return to the menu. Public room lists offer Watch, including full or active matches. Spectators do not consume the eight racer seats or edit the course. When all racers finish, the room shows its final leaderboard.

Only humans and AI racers use the shared start. Hunters use distinct safe floor locations, avoid crushers and direct laser lanes, and need several exits. Hunters select targets within six squares of their post (Manhattan distance), otherwise planning a local patrol. Both modes use their dealt hand. Their plan is a prediction for the round, not a guarantee against unexpected player actions.

The right-side racer HUD places finishers first by finishing order, then remaining racers by checkpoints passed. CP0 means the start. PLAN, READY, RUN, DOWN and DONE show each racer’s state; your own row is highlighted. Hunters and spectators are excluded. Finished racers remain listed after leaving.

The Aim Gearbox is a small, stationary fitting beneath the weapon. Equipment-panel scrolling is silent.

## Admin testing

Accounts with Luanti's `server` privilege see **ADMIN / TEST LAB** in the main menu. The lab creates its own enclosed room and offers ray/wall targets, Remote Control, arm collection across walls, crusher armor/memory, and scheduled supplies. Refill restores hull, power, and parts during programming. Access checks also apply on the server; hiding the button is not the only restriction.

## Ideas retained for later

Not implemented: Torque Beam, EMP, Register Shredder, Mine Layer, Capacitor Cannon, Traction Cleats, Buffer Battery, Recovery Winch, and Signal Firewall. Salvage Magnet is explicitly deferred, including harvesting wrecks and its checkpoint reach. Mortar was rejected and is excluded.

Possible acquisition paths to evaluate: board pickups and scheduled pads (implemented), campaign objective rewards, limited-use supply crates, and between-mission selection. No paid progression is implemented.



Pit falls animate over one second: a short entry slide, accelerating drop, then hidden until reboot. The camera stays above the board. The bottom-left phase strip follows the actual execution phase and returns to its neutral state during programming.

Course designer: 10x10 and 20x20 pieces, 40x40 maximum footprint, optional collaboration, saved configurations and immediate owner access. On logout, a racer becomes AI without receiving a fresh hand. See EDITOR.md and SERVER.md.

Hull and hand size: each point of missing hull removes one card at the next deal. The calculation is 9 + Command Cache bonus - missing hull - disruption, clamped to 5–12. Repair before the deal restores choices. Already-dealt programs are unchanged. Dashboard weapon, aim and equipment selections save immediately during uncommitted planning. Without Aim Gearbox, the fire-direction selector is locked to Front. Fixed board lasers use the full course boundary; robot weapons retain their equipment-defined range.
