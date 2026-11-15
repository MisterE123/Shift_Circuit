from pathlib import Path
from lupa import LuaRuntime
from PIL import Image
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
lua.execute('''
local R=dofile(modpath..'/rules.lua');local C=dofile(modpath..'/campaign.lua')
for hp=1,5 do for _,enemy in ipairs({false,true})do local b={id='test',hp=hp,max_hp=5,enemy=enemy,parts={}};C.deal(b);assert(#b.hand==hp+4 and b.allowance==hp+4,'hull loss reduces human and AI hands equally')end end
local b={id='test',hp=1,max_hp=5,parts={cache=2,blink=1,hard_disk=8},disruption=4};C.deal(b);assert(#b.hand==5 and b.hull_penalty==4 and b.last_penalty==4,'bonuses and penalties retain five-card floor');b.keep={1,2,3,4,5};b.hp=5;C.deal(b);assert(#b.hand==11 and b.hull_penalty==0,'repair restores allowance next deal')
for power=1,3 do for dir=0,3 do
 local s={size=40,board={},walls={},bots={},round=1};local d=R.dirs[dir+1];local x,z=dir==1 and 1 or(dir==3 and 40 or 20),dir==0 and 1 or(dir==2 and 40 or 20)
 local q={x=x,z=z,dir=dir,power=power};s.lasers={q};R.lasers(s);assert(s.shots[1].range==40,'full board boundary in every direction')
 local victim={id='victim',x=x+d.x*39,z=z+d.z*39,hp=5,shield=0};s.bots={victim};R.lasers(s);assert(victim.hp==5-power,'far-edge robot takes correct laser damage')
 victim.hp=5;s.walls[R.edge(x+d.x*25,z+d.z*25,dir)]=true;R.lasers(s);assert(victim.hp==5 and s.shots[#s.shots].wall and s.shots[#s.shots].range==26,'distant thin wall blocks fixed lasers')
end end
print('PASS hull-sized hands, five-card minimum, repairs, upgrades, and 40x40 lasers in four directions at all powers')
''')
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
lua.execute('''
local nodes={};core.set_node=function(p,n)nodes[p.x..','..p.y..','..p.z]=n.name end
local api=dofile(modpath..'/runtime.lua')(core,{});callbacks.on_mods_loaded();flush();local p=newplayer('Pilot');flush();local L=dofile(modpath..'/levels.lua')
api.edit_level(L.blank(10),false);tick(.2)
for _,h in ipairs(p.hud)do assert(h.text=='','no gameplay HUD in workshop')end
assert(p.hotbar==2 and p.inv.list[2]=='shift_circuit:editor_rotate','editor tools remain accessible')
assert(nodes['28,12,12']~='air','small enclosure exists')
api.edit_level(L.blank(20),false);assert(nodes['28,12,12']=='air','upper old wall removed on expansion');assert(nodes['48,12,12']~='air')
api.edit_level(L.blank(10),false);assert(nodes['48,12,12']=='air'and nodes['48,23,12']=='air','old outer wall and ceiling removed on shrink')
local data=L.blank(40);data.lasers={{x=1,z=20,dir=1,power=3}};api.edit_level(data,true);tick(.4)
local beams=0;for _,o in ipairs(objects)do if o.p and o.e.preview_tint=='#804232'then beams=beams+1;assert(o.e.preview_length==40 and o.props.visual_size.z>78,'preview reaches far boundary')end end;assert(beams==3)
local panel=false;for _,h in ipairs(p.hud)do if h.text=='sc_register_terminal.png'then panel=true end end;assert(panel,'playtest restores static gameplay HUD')
local s;for i=1,30 do local key,v=debug.getupvalue(api.snapshot,i);if key=='S'then s=v;break end end;local b=s.bots[1];b.parts.double_laser=1;b.parts.electroshield=1
callbacks.on_player_receive_fields(p,'',{weapon='2'});assert(b.weapon=='double_laser','inventory weapon selection applies immediately')
assert(not p.form:find(';aim;')and p.form:find('Front / LOCKED')and not p.form:find('APPLY CHANGES'),'gearbox absent: no direction dropdown or Apply button')
callbacks.on_player_receive_fields(p,'',{aim='2'});assert(b.aim_offset==0,'forged aiming without gearbox rejected')
b.parts.turret_gearbox=1;callbacks.on_player_receive_fields(p,'shift_circuit:loadout',{aim='3'});assert(b.aim_offset==3 and p.shown:find(';aim;'),'relative Left selection applies immediately')
callbacks.on_player_receive_fields(p,'',{enable_electroshield='false'});assert(b.enabled.electroshield==false,'toggle saves immediately')
for i=1,5 do api.queue('Pilot',i)end;api.commit('Pilot');local weapon=b.weapon;callbacks.on_player_receive_fields(p,'',{weapon='1'});assert(b.weapon==weapon,'execution rejects loadout changes')
print('PASS full-length preview, clean editor HUD, resizing enclosure cleanup, immediate loadout controls and gearbox UI lock')
''')
for i in range(1,23):
 assert Image.open(root/'art/ui'/f'sc_editor_{i}.png').size==(40,40)
 assert Image.open(root/'mods/shift_circuit/textures'/f'sc_editor_{i}.png').size==(80,80)
print('PASS square workshop source icons and exported textures')

