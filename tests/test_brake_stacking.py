from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().path=(root/'mods/shift_circuit').as_posix()
lua.execute('''
local R=dofile(path..'/rules.lua');local s={round=2,size=10,board={},walls={},pickups={},bots={}}
for x=1,10 do for z=1,10 do s.board[R.key(x,z)]={kind='floor'}end end
local a={id='A',x=3,z=3,dir=1,hp=5,parts={},energy=9};local b={id='B',x=4,z=3,dir=1,hp=5,parts={electromagnetic_brake=1},energy=0};s.bots={a,b}
assert(not R.move(s,a,1)and a.x==3 and b.x==4,'brake blocks robot push chain atomically')
s.pushers={{x=4,z=3,dir=1,parity=0}};R.pushers(s,2);assert(b.x==4,'brake resists pusher')
for _,weapon in ipairs({'tractor_beam','repulsor_beam'})do a.weapon=weapon;R.robot_weapons(s,1);assert(b.x==4,weapon..' blocked')end
assert(b.brake_serial>=3,'blocked movement exposes visual cue')
b.enabled={electromagnetic_brake=false};assert(R.move(s,a,1)and b.x==5,'disabled brake allows pushing')
b.enabled.electromagnetic_brake=true;assert(R.move(s,b,1)and b.x==6,'own command movement allowed')
s.board['6,3']={kind='belt',dir=1,speed=1};R.belts(s);assert(b.x==7,'conveyors still carry braked robots')
local u={id='U',x=2,z=2,hp=5,dir=0,parts={},enabled={mechanical_arm=false,thermal_camera=false,titanium_hull=false}}
for kind in pairs(R.unique_parts)do u.parts[kind]=7 end;u.parts.mechanical_arm=3;u.parts.hard_disk=2;u.parts.range=4;u.parts.titanium_hull=3;u.parts.cache=8
R.normalize(u);assert(u.parts.mechanical_arm==3 and u.parts.hard_disk==2 and u.parts.range==4 and u.parts.titanium_hull==3 and u.parts.cache==2)
for kind in pairs(R.unique_parts)do assert(u.parts[kind]<=1,kind..' cannot stack')end
s.bots={u};s.pickups['2,2']='thermal_camera';assert(not R.collect(s,u)and s.pickups['2,2']=='thermal_camera','useless duplicate remains available to other robots')
s.pickups={['3,2']='thermal_camera',['2,3']='cell'};u.energy=0;R.arms(s);assert(s.pickups['3,2']=='thermal_camera'and not s.pickups['2,3']and u.energy==9,'passive arms skip redundant equipment without wasting reaches')
assert(u.enabled.mechanical_arm==nil and u.enabled.thermal_camera==nil and u.enabled.titanium_hull==nil,'legacy toggles removed for passive equipment')
print('PASS brake pushes/pushers/beams, disable, own motion, conveyors, unique equipment, useful stacks and passive arm collection')
''')
