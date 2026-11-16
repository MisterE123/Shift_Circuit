from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().path=(root/'mods/shift_circuit').as_posix()
lua.execute('''
local R=dofile(path..'/rules.lua');local C=dofile(path..'/campaign.lua');local L=dofile(path..'/levels.lua')
local s=L.blank(11);s.round=2;s.shots={};s.bots={};s.pickups={};s.checkpoint_count=3
local a={id='A',x=5,z=3,dir=0,hp=5,energy=9,shield=0,range=7,parts={},home={x=2,z=2,dir=1},next=1,program={'WAIT','LEFT','DASH','RIGHT','STEP'}}
local b={id='B',x=5,z=6,dir=2,hp=5,energy=0,shield=0,range=4,weapon='remote_control',parts={},home={x=3,z=2,dir=0},next=1,program={'WAIT','WAIT','WAIT','WAIT','WAIT'}};s.bots={a,b}
a.parts.remote_control=1;assert(R.loadout(a,'remote_control',0));R.robot_weapons(s,1)
assert(b.hp==5 and b.program[1]=='WAIT'and b.program[2]=='LEFT'and b.program[3]=='DASH'and a.energy==8)
R.robot_weapons(s,2);assert(a.energy==8,'remote only fires once per round')
a.parts.tractor_beam=1;assert(R.loadout(a,'tractor_beam',0));b.hp=5;b.z=6;R.robot_weapons(s,3);assert(b.z==5,'tractor pulls')
a.parts.repulsor_beam=1;assert(R.loadout(a,'repulsor_beam',0));b.hp=5;b.z=6;R.robot_weapons(s,4);assert(b.z==7,'repulsor pushes')
s.walls[R.edge(5,4,0)]=true;b.z=6;b.hp=5;R.robot_weapons(s,5);assert(b.hp==5 and b.z==6,'loaded weapon stops at thin walls')
assert(not R.loadout(a,'repulsor_beam',1));a.parts.turret_gearbox=1;assert(R.loadout(a,'repulsor_beam',1));assert(R.aim(a,'secondary')==1)
a.parts.mechanical_arm=1;a.x=5;a.z=5;a.energy=0;s.pickups['6,5']='cell';s.walls[R.edge(5,5,1)]=true;s.board['5,6']={kind='station',number=1};R.arms(s)
assert(a.energy==9 and not s.pickups['6,5']and a.next==2 and #s.reaches==2,'animated arm collects and visits adjacent checkpoint over walls')
a.parts.electroshield=1;a.energy=1;a.hp=5;R.hit(a,'test');assert(a.hp==5 and a.energy==0 and a.electro_serial==1);R.hit(a,'test');assert(a.hp==4)
a.parts.titanium_hull=1;a.parts.holographic_memory=1;s.overhead['5,5']={kind='crusher'};R.hazards(s,2);assert(not a.down and a.parts.titanium_hull==0 and a.hp==4)
R.hazards(s,4);assert(a.down and (a.parts.holographic_memory or 0)==0);R.respawn(s);assert(a.x==5 and a.z==5 and a.hp==5,'hologram reboots on death square once')
a.parts.gyro_stabilizer=1;a.enabled={gyro_stabilizer=true};s.board['5,5']={kind='rotator',turn=1};local dir=a.dir;R.rotators(s);assert(a.dir==dir);R.command(s,a,'RIGHT');assert(a.dir==(dir+1)%4)
s.round=1;s.spawners={['8,8']={item='repair',chance=100,rounds={1,3}},['9,8']={item='cell',chance=100,first=2,every=2}};R.spawn_pickups(s,function()return 1 end);assert(s.pickups['8,8']=='repair'and not s.pickups['9,8']);s.pickups['8,8']=nil;R.spawn_pickups(s);assert(not s.pickups['8,8']);s.round=2;R.spawn_pickups(s,function()return 5 end);assert(s.pickups['9,8']=='cell');s.round=3;R.spawn_pickups(s,function()return 1 end);assert(s.pickups['8,8']=='repair')
a.finished=nil;b.finished=nil;s.finishers=nil;s.winner=nil;R.finish(s,a,3);assert(not R.race_complete(s));R.finish(s,b,4);assert(R.race_complete(s)and a.rank==1 and b.rank==2)
print('PASS loadout ownership, remote commands/cost, beam displacement/walls, gearbox, arm/checkpoints, electroshield, titanium, hologram, gyro, spawners and race continuation')
''')


