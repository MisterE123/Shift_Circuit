from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
lua.execute('''
local R=dofile(modpath..'/rules.lua');local G=dofile(modpath..'/geometry.lua');local L=dofile(modpath..'/levels.lua')
for dir=0,3 do for power=1,3 do local s=L.blank(10);local q={x=5,z=5,dir=dir,power=power};s.lasers={q};s.round=1;s.walls={};local d=R.dirs[dir+1]
 assert(R.blocked(s,5,5,(dir+2)%4));assert(R.blocked(s,5-d.x,5-d.z,dir));assert(not R.blocked(s,5,5,dir))
 local b={id='target',x=5,z=5,dir=0,hp=5,shield=0};s.bots={b};R.lasers(s);assert(b.hp==5-power,'emitter fires into its own usable square')
 local x,z=R.laser_source(q);for i=1,power do local p,length=G.beam(x,z,dir,power,i,2,false);assert(math.abs((p.x-(x*2+.5))*d.x+(p.z-(z*2+.5))*d.z-.1875)<.00001)end
 s.bots={};local length,_,wall=R.trace(s,5-d.x,5-d.z,dir,4);assert(wall and length==.5,'back of emitter blocks rays')
end end
print('PASS wall emitters in all directions: passable square, solid edge, own-square hit, aligned barrels and stopped incoming rays')
''')
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
setup=(root/'tests/test_online.py').read_text().split("lua.execute('''",1)[1].split("local a=newplayer('Alpha')",1)[0];lua.execute(setup)
lua.execute('''
local a=newplayer('ModelPilot');flush();local function fields(f)callbacks.on_player_receive_fields(a,'shift_circuit:online',f);flush()end
fields({refresh=true});assert(a.shown:find('CHOOSE YOUR ROBOT'));fields({choose_robot=true});local _,count=a.shown:gsub('animated_image%[','');assert(count==4)
local Styles=dofile(modpath..'/robot_styles.lua');assert(#Styles.list==16);local seen={}
for page=1,4 do
 assert(a.shown:find(page..' OF 4'));local _,count=a.shown:gsub('animated_image%[','');assert(count==4,'four full-size previews per page')
 for i=(page-1)*4+1,page*4 do local q=Styles.list[i];assert(not seen[q.id]and a.shown:find('preview_'..q.id,1,true));seen[q.id]=true;fields({['robot_'..q.id]=true});assert(core.get_mod_storage():get_string('robot_style:ModelPilot')==q.id)end
 if page<4 then fields({robot_next=true})end
end
fields({robot_next=true});assert(a.shown:find('4 OF 4'));fields({robot_back=true});fields({choose_robot=true});assert(a.shown:find('4 OF 4'),'reopens at selected model')
for _=1,4 do fields({robot_prev=true})end;assert(a.shown:find('1 OF 4'))
for _=1,3 do fields({robot_next=true})end;fields({robot_robot_relay=true});assert(core.get_mod_storage():get_string('robot_style:ModelPilot')=='robot_relay');fields({robot_back=true});fields({solo_race=true});fields({play_solo=true});tick(.1);flush();tick(.1)
local r=shift_circuit.rooms[shift_circuit.member.ModelPilot];local b;for _,q in ipairs(r.api.snapshot().state.bots)do if q.id=='ModelPilot'then b=q end end;assert(b.robot_style=='robot_relay')
local found=false;for _,o in ipairs(objects)do if o.p and o.e.robot and o.props.mesh=='sc_robot_relay.obj'then found=true end end;assert(found,'selected mesh spawned')
local offline=newplayer('singleplayer');flush();callbacks.on_player_receive_fields(offline,'shift_circuit:online',{refresh=true});flush();assert(not offline.shown:find(';queue;')and not offline.shown:find(';create;')and offline.shown:find('UNAVAILABLE'))
for _,f in ipairs({{queue=true},{create=true},{create_confirm=true},{join_1=true},{watch_1=true},{find_match=true}})do callbacks.on_player_receive_fields(offline,'shift_circuit:online',f);flush();assert(not shift_circuit.member.singleplayer and not shift_circuit.queue.singleplayer)end
assert(not shift_circuit.new_room({'singleplayer'},false,false));callbacks.on_player_receive_fields(offline,'shift_circuit:online',{tutorial=true});flush();tick(.1);assert(shift_circuit.member.singleplayer,'solo modes still work')
print('PASS restricted multiplayer for singleplayer; 16 models, four menu pages, persistent selection, stored cosmetic selection and selected in-game model')
''')
styles=lua.execute("return dofile(modpath..'/robot_styles.lua').list")
assert len({(root/'mods/shift_circuit/models'/('sc_'+v['id']+'.obj')).read_bytes() for _,v in styles.items()})==16
for _,v in styles.items():
 n=v['id']
 assert (root/'mods/shift_circuit/models'/('sc_'+n+'.obj')).exists()
 assert (root/'mods/shift_circuit/textures'/('sc_surface_'+n+'.png')).exists()

from PIL import Image
for _,v in styles.items():
 im=Image.open(root/'mods/shift_circuit/textures'/('sc_preview_'+v['id']+'.png'))
 assert im.size==(128,128*24)
 for i in range(24):assert im.crop((0,i*128,128,(i+1)*128)).getbbox() is not None
 assert im.crop((0,0,128,128)).tobytes()!=im.crop((0,128*6,128,128*7)).tobytes()
