# Hosting Shift Circuit

One Luanti server hosts both private solo sessions and multiplayer rooms. Install in the games directory and use Host Server or `luanti --server --world <world-directory>`. Players connect through Luanti's normal multiplayer screen.

Rooms hold eight racers total. The creator selects 0–7 AI racers, capped after human seats are reserved. The FIFO queue groups 2–8 players and fills waiting public rooms before creating another. Room construction has no voting or automatic launch deadline: the creator starts when the course is ready.

Room creation includes a 1–16 board limit and optional collaborative editing. The creator can also toggle collaboration in the waiting room. All layouts are limited to a 40x40 footprint. Spectators cannot edit. Named course saves persist, are immediately usable by their owner, and need admin approval before other players can load them. Editing a published configuration revokes approval for that revision.

## Isolation and lifecycle

Each room owns its rules, HUDs, cameras, entities and board. Enclosed arenas use a new allocation bank around x=512, y=128, z=4096, separated by 256 nodes. Unowned candidate volumes are checked for unrelated terrain before being claimed. Only previously owned, currently unclaimed locations may be reused. Old arena banks are left untouched.

Disconnecting racers become AI with their current health, equipment, position, dealt cards and priorities. Committed programs and execution already in progress are preserved. AI plans the remaining uncommitted round from the same hand. Connected spectators may keep watching. A race can continue with only AI after its last participant disconnects; an empty finished room is released. Explicitly leaving through the menu still removes that participant. In-progress matches do not survive a server restart.

Host control passes to another racer when possible, otherwise a remaining spectator. Spectators joining an ongoing or full room do not use racer seats. A finisher may watch or leave while others continue. The final leaderboard appears when all racers finish.

Camera orbit tools operate during execution; the flight camera returns above the player's robot after a round. Sounds are sent only to players in the same session. World ownership, campaign progress, records, drafts, approved boards and saved configurations persist in mod storage.

## Verification

Automated checks cover isolation, safe allocation, human seat priority, shared editing permissions, course connectivity, saved-configuration access/approval, disconnect takeover and UI state. Native headless smoke checks exercise enclosed generation, custom boards, exports and async AI planning. Rendered UI previews are also checked. Live multi-client visual testing and sustained server load testing remain separate work.
