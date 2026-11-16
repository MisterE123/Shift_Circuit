from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().path=(root/'mods/shift_circuit').as_posix()
lua.execute(r'''local R=dofile(path..'/rules.lua');local L=dofile(path..'/levels.lua');local C=dofile(path..'/campaign.lua')
local function scene(weapon,power)
 local s=L.blank(10);s.round=2;s.shots={};s.walls={}
 local a={id='a',x=5,z=3,dir=0,hp=5,energy=power,weapon=weapon,parts={}}
 local b={id='b',x=5,z=5,dir=0,hp=5,energy=0,parts={},program={'WAIT','STEP','RIGHT','STEP','STEP'}}
 s.bots={a,b};return s,a,b
end
local s,a,b=scene('triple_laser',1);R.robot_weapons(s,1);assert(b.hp==2 and a.energy==0 and #s.shots==2)
R.robot_weapons(s,2);assert(a.weapon=='green_laser'and a.parts.triple_laser==1 and b.hp==1)
s,a,b=scene('emp_generator',2);R.robot_weapons(s,1);assert(a.energy==0 and b.emp_round==2 and b.hp==5)
for _,c in ipairs({'STEP','RIGHT','DASH','WAIT'})do R.command(s,b,c)end;assert(b.x==5 and b.z==5 and b.dir==0)
b.scripted=true;b.kind='patroller';R.command(s,b,'STEP');assert(b.z==5);b.scripted=nil
s.round=3;R.command(s,b,'STEP');assert(b.z==6)
s,a,b=scene('emp_generator',2);s.walls[R.edge(5,4,0)]=true;R.robot_weapons(s,1);assert(not b.emp_round)
s,a,b=scene('emp_generator',2);a.ghost=true;R.robot_weapons(s,1);assert(not b.emp_round and a.energy==2)
s,a,b=scene('emp_generator',2);b.ghost=true;R.robot_weapons(s,1);assert(b.emp_round==2)
s,a,b=scene('emp_generator',2);s.round=1;R.robot_weapons(s,1);assert(not b.emp_round and a.energy==2)
s,a,b=scene('emp_generator',1);a.parts.double_laser=1;R.robot_weapons(s,1);assert(a.weapon=='double_laser'and b.hp==3 and a.energy==1)
s,a,b=scene('emp_generator',2);s.crates={{crate=true,id='box',x=5,z=4,hp=3}};R.robot_weapons(s,1);assert(not b.emp_round)
a.parts={blueprint_archive=1,range=1};a.weapon='triple_laser';local choices=R.archive_choices(a);R.drop(a,'test');assert(a.archived_item and #choices==3)
a={hp=5,energy=0,parts={blueprint_archive=1,range=1},archive_item='range'};R.drop(a,'test');assert(a.archived_item=='range')
s,a,b=scene('green_laser',0);a.parts.hard_disk=1;a.hand={'WAIT','STEP'};a.keep={1};s.bots={a};C.deal_round(s);assert(a.hand[1]=='WAIT'and a.retained_count==1)
local U=dofile(path..'/menu_ui.lua');local text='This is a long tooltip with several useful words that should wrap cleanly without losing its meaning.'
local f=U.wrap_tooltips('tooltip[test;'..text..']tooltip[1,2;3,4;'..text..';#000;#fff]');assert(f:find('\n',1,true));assert(f:find(';#000;#fff]',1,true));assert(U.wrap_tooltips('tooltip[a;Escaped \\] bracket and \\; separator]')=='tooltip[a;Escaped \\] bracket and \\; separator]')
print('PASS triple cost/fallback, EMP round lock/walls/crates/ghosts, archive random, Wait retention, tooltip wrapping')
''')
