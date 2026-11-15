from pathlib import Path
import re
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().path=(root/'mods/shift_circuit').as_posix()
lua.execute(r'''
R=dofile(path..'/rules.lua');C=dofile(path..'/campaign.lua')
local core={formspec_escape=function(s)return (tostring(s):gsub('([%[%];,\\])','\\%1'))end}
U=dofile(path..'/dashboard_ui.lua')(core,R)
b={id='pilot',dir=0,hp=5,energy=9,next=1,allowance=9,parts={}}
for k in pairs(R.part_items)do b.parts[k]=2 end;b.parts.blink=2;b.parts.range=3;b.parts.cache=2
assert(R.loadout(b,'double_laser',3));dashboard=U.formspec(b,'program')
assert(not dashboard:find('PRIMARY')and not dashboard:find('SECONDARY')and not dashboard:find('MODULES'))
assert(dashboard:find('Front,Back,Left,Right')and dashboard:find('Extended Range'))
assert(not dashboard:find('enable_range')and not dashboard:find('enable_blink')and dashboard:find('enable_electroshield'))
local old={dir=0,primary='double_laser',secondary='tractor_beam',blink=true,range=7,draw_bonus=2,parts={}}
R.normalize(old);R.normalize(old);assert(old.weapon=='double_laser'and old.secondary==nil and old.parts.tractor_beam==1 and old.parts.range==1 and old.parts.blink==1 and old.parts.cache==2)
for dir=0,3 do for offset=0,3 do b.dir=dir;assert(R.loadout(b,'double_laser',offset));assert(R.aim(b)==(dir+offset)%4)end end
local s=R.arena();s.bots={b};b.x=2;b.z=2;b.dir=0;b.energy=9;s.pickups={['2,2']='range'};R.collect(s,b);assert(b.parts.range==4 and b.range==16)
for z=1,s.size do for x=1,s.size do s.board[R.key(x,z)]={kind='floor'}end end;s.walls={};s.overhead={};s.shots={}
b.blink=true;b.keep={};C.deal_round(s);local count=0;for i,c in ipairs(b.hand)do if c=='BLINK'then count=count+1;b.keep={i}end end;assert(count==1 and b.blink_left==1)
R.command(s,b,'BLINK');assert(b.z==4 and b.blink_left==0);R.command(s,b,'BLINK');assert(b.z==4,'second use denied')
C.deal_round(s);count=0;for _,c in ipairs(b.hand)do if c=='BLINK'then count=count+1 end end;assert(count==1 and b.blink_left==1,'exactly one refreshed card even when retained')
s.round=2;s.shots={};R.robot_weapons(s,1);assert(#s.shots==1 and s.shots[1].mount=='weapon','one loaded weapon produces one shot event')
assert(not U.apply(b,{weapon='999',aim='2',enable_range='false'})or b.parts.range==4)
print('PASS one weapon, old-save migration, relative aim, stacked passive range, guaranteed single-use Blink and integrated dashboard')
''')
form=lua.globals().dashboard
for kind,body in re.findall(r'(\w+)\[((?:\\.|[^\]])*)\]',form):
    args=re.split(r'(?<!\\);',body)
    if kind=='label':
        assert len(args)==2, (kind,args)
        assert len(args[0].split(','))==2
        tuple(map(float,args[0].split(',')))
    if kind=='tooltip': assert len(args)==3
for name in re.findall(r'sc_[a-zA-Z0-9_]+\.png',form): assert (root/'mods/shift_circuit/textures'/name).exists(),name
assert form.count('tooltip[')>=15,'equipment, spare weapons and loaded weapon have hover details'
assert (root/'mods/shift_circuit/textures/sc_stat_route_0_0.png').exists()
assert 'loadout; queue'not in (root/'mods/shift_circuit/test_lab.lua').read_text()
print('PASS formspec label geometry, hover descriptions and referenced textures including zero-checkpoint scene')
