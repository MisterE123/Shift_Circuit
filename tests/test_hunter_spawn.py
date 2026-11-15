from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True)
lua.globals().path=(root/'mods/shift_circuit').as_posix()
lua.execute('''
local R=dofile(path..'/rules.lua');local C=dofile(path..'/campaign.lua');local L=dofile(path..'/levels.lua')
for _,size in ipairs({5,7,11,15})do
 local s=L.blank(size);s.round=1;s.mode='race';s.bots={{id='human',x=2,z=2,dir=0,hp=5,next=1}};s.enemy_count=3;s.racer_count=2;s.overhead['3,3']={kind='crusher'}
 C.enemies(s,R);R.shared_start(s,s.start);local sites={};local n=0
 for _,b in ipairs(s.bots)do if b.enemy and not b.racing then n=n+1
  assert(not b.ghost and not (b.x==s.start.x and b.z==s.start.z),'hunters stay off shared start')
  assert(R.tile(s,b.x,b.z).kind=='floor'and not s.overhead[R.key(b.x,b.z)])
  assert(not sites[R.key(b.x,b.z)]);sites[R.key(b.x,b.z)]=true
  assert(b.hunt_radius==6)
 else assert(b.x==s.start.x and b.z==s.start.z and b.ghost)end end
 assert(n>0)
end
local s=L.blank(15);s.round=1;s.mode='race';s.bots={{id='human',x=2,z=2,dir=0,hp=5,next=1,program={}}};s.enemy_count=1;s.racer_count=0
C.enemies(s,R);local hunter=s.bots[2];hunter.hunt_radius=2;hunter.difficulty=1;C.deal_round(s)
assert(math.abs(hunter.x-2)+math.abs(hunter.z-2)>2)
local program=C.plan(R,s,hunter);assert(#program==5);hunter.program=program
for i=1,5 do R.command(s,hunter,program[i])end
assert(math.abs(hunter.x-hunter.home.x)+math.abs(hunter.z-hunter.home.z)<=5,'out-of-range patrol remains near its post')
print('PASS suitable hunter spawns across board sizes, racer-only shared starts, local patrol planning')
''')
