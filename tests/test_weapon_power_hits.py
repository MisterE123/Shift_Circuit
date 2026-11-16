from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().path=(root/'mods/shift_circuit').as_posix()
lua.execute('''
local R=dofile(path..'/rules.lua');local L=dofile(path..'/levels.lua')
for _,kind in ipairs({'triple_laser','emp_generator','remote_control','PULSE'})do
 for _,mode in ipairs({'empty','range','wall','robot','shield','crate'})do
  local s=L.blank(10);s.round=2;s.walls={};s.shots={}
  local a={id='a',x=5,z=3,dir=0,hp=5,energy=9,weapon=kind=='PULSE'and 'green_laser'or kind,parts={}}
  local b={id='b',x=5,z=5,dir=0,hp=5,energy=0,parts={},ghost=true,shield=mode=='shield'and 3 or 0}
  s.bots={a,b};if mode=='empty'then b.x=6 elseif mode=='range'then b.z=9 elseif mode=='wall'then s.walls[R.edge(5,4,0)]=true elseif mode=='crate'then s.crates={{id='c',crate=true,kind='loot',x=5,z=4,hp=3}}end
  local cost=kind=='PULSE'and 1 or R.weapons[kind].cost
  if kind=='PULSE'then R.command(s,a,'PULSE')else R.robot_weapons(s,1)end
  local hit=mode=='robot'or mode=='shield'or mode=='crate'
  assert(a.energy==9-(hit and cost or 0),kind..' / '..mode..' wrong energy')
  assert(#s.shots==1,'misses still display a ray')
 end
end
print('PASS powered weapons and Pulse charge only on robot/crate hits, including shielded targets; misses, range and walls cost nothing')
''')
