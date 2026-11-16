from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True)
lua.globals().path=(root/'mods/shift_circuit').as_posix()
lua.execute("""
local R=dofile(path..'/rules.lua')
for kind in pairs(R.weapons)do for _,mode in ipairs({'both','attacker'})do
 local a={id='A',x=2,z=2,dir=1,hp=5,energy=9,weapon=kind,parts={},program={'STEP','LEFT','DASH','RIGHT','STEP'},ghost=mode~='target'}
 local b={id='B',x=4,z=2,dir=1,hp=5,energy=0,shield=2,weapon='remote_control',parts={},program={'WAIT','WAIT','WAIT','WAIT','WAIT'},ghost=mode~='attacker'}
 local s={round=2,size=10,bots={a,b},board={},walls={}}
 for x=1,10 do for z=1,10 do s.board[R.key(x,z)]={kind='floor'}end end
 R.robot_weapons(s,1)
 assert(b.hp==5 and b.shield==2 and b.x==4 and b.z==2 and b.program[2]=='WAIT'and not b.remote_from,kind..' cannot affect ghosts')
 if a.ghost then assert(a.energy==9,'ghosts do not spend power');for _,shot in ipairs(s.shots)do assert(shot.owner~=a.id,'ghosts do not fire')end end
 R.fire(s,2,2,1,2,8,a);assert(b.hp==5 and b.shield==2,'direct robot rays obey ghost immunity')
end end
-- A solid robot can hit ghosts; targeting must not reuse movement collision filtering.
for kind in pairs(R.weapons)do
 local a={id='A',x=2,z=2,dir=1,hp=5,energy=9,weapon=kind,parts={},program={'WAIT','LEFT','DASH','RIGHT','STEP'}}
 local b={id='B',x=4,z=2,dir=1,hp=5,energy=0,weapon='green_laser',parts={},program={'WAIT','WAIT','WAIT','WAIT','WAIT'},ghost=true}
 local s={round=2,size=10,bots={a,b},board={},walls={}}
 for x=1,10 do for z=1,10 do s.board[R.key(x,z)]={kind='floor'}end end
 R.robot_weapons(s,1)
 assert(#s.shots==1 and s.shots[1].hit,kind..' targets ghost')
 if R.weapons[kind].power then assert(b.hp<5,kind..' damages ghost')
 elseif kind=='remote_control'then assert(b.remote_from=='A'and b.program[2]=='LEFT','remote affects unexecuted ghost registers')
 elseif kind=='tractor_beam'then assert(b.x==3,'tractor moves ghost')
 elseif kind=='repulsor_beam'then assert(b.x==5,'repulsor moves ghost')end
end
local a={id='A',x=2,z=2,dir=0,hp=5,parts={thermal_camera=1},aim_offset=4,range=5};local b={id='B',x=4,z=2,hp=5,ghost=true}
local s={round=2,size=10,bots={a,b},board={},walls={}}
R.thermal_aim(s,a);assert(a.thermal_dir==1,'thermal aim can acquire a ghost')
R.fire(s,2,2,1,2,8,a);assert(b.hp==3,'direct ray damages ghost')
s.walls[R.edge(2,2,1)]=true;R.fire(s,2,2,1,2,8,a);assert(b.hp==3,'walls still block ghost targets')
-- Fixed board hazards remain dangerous, unlike robot weapons.
local b={id='B',x=4,z=2,hp=5,ghost=true};local s={round=2,size=10,bots={b},board={},walls={}}
R.fire(s,2,2,1,1,8,nil);assert(b.hp==4,'fixed lasers still affect ghosts')
print('PASS ghosts cannot fire; solid robots can damage, move, remotely control and auto-aim at ghosts; walls still block rays')
""")
