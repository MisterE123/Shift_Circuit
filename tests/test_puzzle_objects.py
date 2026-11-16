from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
lua.execute('''
R=dofile(modpath..'/rules.lua');L=dofile(modpath..'/levels.lua');Q=dofile(modpath..'/courses.lua')
function board()local s=L.blank(10);s.round=2;s.register=1;s.bots={};R.init_objects(s);return s end
function robot(s,x,z)local b={id='r'..#s.bots,x=x,z=z,dir=1,hp=5,parts={},next=1,energy=5,program={'WAIT'}};s.bots[#s.bots+1]=b;return b end
local s=board();s.crates['3,3']={kind='loot',item='repair'};R.init_objects(s);local c=s.crates['3,3'];local b=robot(s,5,3)
for i=1,2 do R.fire(s,1,3,1,3,9);assert(c.hp==3-i and b.hp==5)end
R.fire(s,1,3,1,1,9);assert(c.down and s.pickups['3,3']=='repair'and b.hp==5);R.fire(s,1,3,1,1,9);assert(b.hp==4)
s=board();s.crates['3,3']={kind='steel'};s.board['4,3']={kind='pit'};R.init_objects(s);c=s.crates['3,3'];b=robot(s,2,3);R.fire(s,1,3,1,3,9);assert(not c.down);assert(R.move(s,b,1));assert(c.filled and R.tile(s,4,3).kind=='floor'and b.x==3)
s=board();s.crates['3,3']={kind='steel'};s.board['3,3']={kind='belt',dir=1,speed=2};s.board['4,3']={kind='belt',dir=1,speed=1};R.init_objects(s);c=s.crates['3,3'];R.belts(s);assert(c.x==5);s.overhead['5,3']={};R.hazards(s,2);assert(c.kind=='loot'and c.hp==3 and not c.down)
s=board();s.board['3,3']={kind='plate'};s.board['4,3']={kind='trapdoor',open=false};b=robot(s,3,3);local victim=robot(s,4,3);R.plates(s);assert(s.board['4,3'].open and victim.down);R.plates(s);assert(s.board['4,3'].open);s.register=2;R.plates(s);assert(not s.board['4,3'].open)
s=board();s.board['3,3']={kind='plate'};s.board['5,3']={kind='plate'};s.board['4,3']={kind='trapdoor'};robot(s,3,3);robot(s,5,3);R.plates(s);assert(not s.board['4,3'].open)
s=board();b=robot(s,2,3);b.parts.battering_ram=1;victim=robot(s,3,3);assert(R.move(s,b,1)and victim.hp==3);s.walls[R.edge(4,3,1)]=true;assert(not R.move(s,b,1)and victim.hp==3)
s=board();s.enemies['3,3']={kind='ram_bot',dir=1};R.init_objects(s);b=s.bots[1];victim=robot(s,5,3);R.command(s,b,'WAIT');assert(b.winding and b.x==3);R.command(s,b,'WAIT');assert(not b.winding and b.x==6 and victim.x==7)
s=board();s.enemies['3,3']={kind='patroller',dir=1};s.board['4,3']={kind='pit'};R.init_objects(s);b=s.bots[1];R.command(s,b,'WAIT');assert(b.x==3 and b.dir==3);R.command(s,b,'WAIT');assert(b.x==2);R.drop(b,'test');R.respawn(s);assert(b.down,'destroyed obstacles do not respawn')
local data=L.blank(10);data.crates['3,3']={kind='steel'};data.enemies['4,4']={kind='sentry',dir=2};data.board['5,5']={kind='trapdoor',open=true};data.board['5,6']={kind='plate'};local clean,err=L.validate(data);assert(clean,err);assert(clean.crates['3,3']and clean.enemies['4,4']and clean.board['5,5'].open);local large=L.resize(clean,20);assert(large.crates['3,3']);local course=Q.layout(R,{clean,clean},3,{{x=0,z=0},{x=1,z=0}});assert(course.crates['13,3']and course.enemies['14,4']);R.init_objects(course);assert(course.crates['13,3'].x==13)
print('PASS crate shots/rays, steel conversion, pushes, filling holes, conveyors, plate timing/parity, ram damage, predictable enemies, persistence and course offsets')
''')

source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0]
lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix();lua.execute(source)
lua.execute("""
local store=core.get_mod_storage();core.deserialize=function(v)return type(v)=='table'and copy(v)or nil end
local room={solo_mode='editor',host='Author',api={phase=function()return 'editor'end,edit_level=function(d)drawn=copy(d)end}}
local E=dofile(modpath..'/editor.lua')(core,store,function()return room end,function()end);clients.Author={};E.begin(room)
local player={get_player_name=function()return 'Author'end}
for i=23,30 do callbacks.on_player_receive_fields(player,'shift_circuit:editor',{['b'..i]=true});assert(E.paint('Author',i-21,5,1))end
assert(drawn.crates['2,5'].kind=='loot'and drawn.crates['3,5'].kind=='steel');assert(drawn.board['4,5'].kind=='plate'and drawn.board['6,5'].open)
assert(drawn.enemies['7,5'].kind=='sentry'and drawn.enemies['8,5'].kind=='patroller'and drawn.enemies['9,5'].kind=='ram_bot');assert(E.rotate('Author',9,5));assert(drawn.enemies['9,5'].dir==2)
local L=dofile(modpath..'/levels.lua');assert(L.validate(drawn));assert(store:get_string('draft:Author').enemies['9,5'].dir==2)
callbacks.on_player_receive_fields(player,'shift_circuit:editor',{factory_steel=true})
for i,pattern in ipairs({'one','opposite','corner','three','four'})do callbacks.on_player_receive_fields(player,'shift_circuit:editor',{['b'..(31+i)]=true});assert(E.paint('Author',i+1,7,2));assert(drawn.board[(i+1)..',7'].pattern==pattern and drawn.board[(i+1)..',7'].crate_kind=='steel')end
assert(E.rotate('Author',2,7));assert(drawn.board['2,7'].dir==3);assert(L.validate(drawn));assert(store:get_string('draft:Author').board['2,7'].kind=='factory')
print('PASS all eight Workshop brushes, enemy rotation, draft persistence and validation')
""")
