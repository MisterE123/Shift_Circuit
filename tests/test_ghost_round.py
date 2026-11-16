from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True)
lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
lua.execute("""
local R=dofile(modpath..'/rules.lua')
local function bot(id,x,z)return {id=id,x=x,z=z,dir=1,hp=5,parts={battering_ram=1},home={x=x,z=z},program={'STEP','STEP','STEP','STEP','STEP'}}end
local s={size=20,round=1,bots={},board={},walls={},overhead={}}
for z=1,20 do for x=1,20 do s.board[R.key(x,z)]={kind='floor'}end end
local a,b=bot('A',2,2),bot('B',3,2);s.bots={a,b};b.program={'WAIT','WAIT','WAIT','WAIT','WAIT'}
for slot=1,5 do R.programs(s,slot);assert(b.x==3 and b.hp==5,'no opening-round pushing or ram damage');assert(a.ghost and b.ghost,'ghosting lasts every register even after separation')end
assert(a.x==7)
s.round=2;R.ghosts(s,true);assert(not a.ghost and not b.ghost,'separated robots solidify at round two')
a.x=2;assert(R.move(s,a,1));assert(b.x==4 and b.hp==3,'normal pushing and ram damage return')
a.x=5;b.x=5;a.z=5;b.z=5;R.ghosts(s)
for round=2,5 do s.round=round;R.ghosts(s,true);assert(a.ghost and b.ghost and a.x==5 and b.x==5,'overlap never expires or teleports')end
local c=bot('C',4,5);s.bots[3]=c;assert(R.move(s,c,1));assert(a.x==5 and b.x==5 and c.x==5 and c.ghost,'solid robot cannot push ghosts; joining their square also ghosts it')
assert(R.move(s,a,1));assert(a.ghost and b.ghost and c.ghost,'separation does not solidify mid-register');R.ghosts(s,true);assert(not a.ghost and b.ghost and c.ghost,'only the separated robot becomes solid at register end')
a.x=6;a.z=5;assert(R.move(s,b,1));assert(a.x==6 and b.x==6 and a.ghost and b.ghost and c.ghost,'ghost cannot push a solid robot')
assert(R.move(s,b,1));assert(a.ghost and b.ghost,'no early solidification');R.ghosts(s,true);assert(not a.ghost and not b.ghost and not c.ghost,'divergent paths restore collision after the register')
s.round=1;a.x=2;a.z=2;b.x=8;b.z=8;c.down=true
s.walls[R.edge(2,2,1)]=true;assert(not R.move(s,a,1),'ghosts still obey walls');s.walls={}
s.board['3,2']={kind='pit'};assert(R.move(s,a,1)and a.down and not a.ghost,'ghosts still fall')
b.down=true;b.home={x=8,z=8};R.respawn(s);assert(b.ghost,'first-round reboot retains full-round ghosting')
print('PASS whole opening round, no pushing or ram damage, later overlap persistence, symmetric ghost collision, divergence, walls, pits and reboot')
""")
