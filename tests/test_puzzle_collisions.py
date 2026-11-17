from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.globals().rules_path=(root/'mods/shift_circuit/rules.lua').as_posix()
lua.execute('''
local R=dofile(rules_path)
local a={id='a',x=2,z=2,dir=1,hp=5,parts={},home={x=2,z=2,dir=1}}
local b={id='b',x=3,z=2,dir=1,hp=5,parts={}}
local s={mode='puzzle',round=1,size=5,bots={a,b},board={},walls={},crates={},pickups={}}
for x=1,5 do for z=1,5 do s.board[x..','..z]={kind='floor'}end end
R.ghosts(s);assert(not a.ghost and not b.ghost)
assert(R.at(s,3,2,a)==b,'opening puzzle round must collide')
assert(R.move(s,a,1)and a.x==3 and b.x==4,'puzzle pushes must work on round one')
a.ghost=true;b.ghost=true;R.ghosts(s);assert(not a.ghost and not b.ghost,'clear stale puzzle ghost state')
a.down=true;a.x=1;b.x=2;b.z=2;s.round=2;R.respawn(s)
assert(not a.down and not a.ghost and not b.ghost)
assert(a.x~=b.x or a.z~=b.z,'occupied puzzle reboot must use a free square')
s.mode='race';s.puzzle=nil;s.round=1;R.ghosts(s);assert(a.ghost and b.ghost,'race ghost opening unchanged')
s.puzzle={};R.ghosts(s);assert(not a.ghost and not b.ghost,'puzzle configuration also disables ghosts')
print('PASS puzzle collisions, pushes, stale flags, occupied reboot and unchanged race opening')
''')
