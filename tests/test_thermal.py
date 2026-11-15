from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().path=(root/'mods/shift_circuit').as_posix()
lua.execute('''
local R=dofile(path..'/rules.lua');local L=dofile(path..'/levels.lua');local s=L.blank(10);s.round=2;s.walls={};s.shots={}
local a={id='a',x=5,z=5,dir=0,hp=5,energy=9,parts={thermal_camera=1},aim_offset=4};local b={id='b',x=5,z=8,dir=0,hp=5,energy=0,parts={}};local c={id='c',x=7,z=5,dir=0,hp=5,energy=0,parts={}};s.bots={a,b,c}
R.normalize(a);R.thermal_aim(s,a);assert(R.aim(a)==1,'nearest cardinal target')
s.walls[R.edge(5,5,1)]=true;R.thermal_aim(s,a);assert(R.aim(a)==0,'wall blocks closer target')
b.x=4;R.thermal_aim(s,a);assert(a.thermal_dir==nil and R.aim(a)==0,'diagonal targets unavailable')
s.walls={};a.enabled={thermal_camera=false};R.thermal_aim(s,a);assert(R.aim(a)==0)
a.enabled.thermal_camera=true;R.robot_weapons(s,1);assert(c.hp==4 and a.thermal_dir==1)
c.x=5;c.z=3;R.robot_weapons(s,2);assert(c.hp==3 and a.thermal_dir==2,'retarget during round')
c.ghost=true;R.thermal_aim(s,a);assert(a.thermal_dir==nil)
c.ghost=false;c.team='same';a.team='same';R.thermal_aim(s,a);assert(a.thermal_dir==nil)
a.team=nil;c.team=nil;c.z=10;R.thermal_aim(s,a);assert(a.thermal_dir==nil,'range enforced')
local U=dofile(path..'/dashboard_ui.lua')({formspec_escape=tostring},R);local f=U.formspec(a,'program');assert(f:find('Front,Automatic')and not f:find('Front,Back'))
assert(U.apply(a,{aim='2'}));assert(a.aim_offset==4);assert(not R.loadout({parts={},dir=0},'green_laser',4))
a.parts.turret_gearbox=1;assert(U.formspec(a,'program'):find('Front,Back,Left,Right,Automatic'))
print('PASS Thermal Camera nearest target, walls, diagonals, range, ghosts, teams, toggling, per-phase retarget and aim UI ownership')
''')
