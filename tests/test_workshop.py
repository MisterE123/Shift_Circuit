from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().path=(root/'mods/shift_circuit').as_posix()
lua.execute("""
local R=dofile(path..'/rules.lua');local C=dofile(path..'/campaign.lua');local L=dofile(path..'/levels.lua')
local d=L.blank();assert(L.validate(d));for k,t in pairs(d.board)do if t.kind=='checkpoint'then d.board[k]={kind='floor'}end end;assert(not L.validate(d));d=L.blank();d.lasers={{x=1,z=1,dir=8,power=1}};assert(not L.validate(d));d=L.blank();d.overhead='bad';assert(not L.validate(d))
local s=R.arena();s.walls={};s.overhead={};s.pickups={};for k in pairs(s.board)do s.board[k]={kind='floor'}end
local a={id='a',x=2,z=2,dir=1,hp=5,home={x=2,z=2,dir=0},program={}};local b={id='b',x=2,z=2,dir=1,hp=5,program={}};s.bots={a,b}
R.command(s,a,'MOVE3');assert(a.x==5);R.command(s,a,'BACK2');assert(a.x==3 and a.dir==1);R.command(s,a,'UTURN');assert(a.dir==3)
s.walls[R.edge(4,2,1)]=true;a.dir=1;R.command(s,a,'MOVE3');assert(a.x==4,'move 3 stops at wall');s.walls={}
s.board['6,2']={kind='pit'};R.command(s,a,'MOVE3');assert(a.down and a.x==6,'move 3 stops at pit')
a.down=nil;a.hp=5;s.board['6,2']={kind='floor'};R.shared_start(s,{x=2,z=2,dir=1});assert(a.ghost and b.ghost)
b.x=3;local len,target=R.trace(s,2,2,1,5,a);assert(target==nil,'ghost weapons skip ghosts');b.x=2
R.command(s,a,'STEP');assert(a.x==3 and b.x==2 and not a.ghost and not b.ghost,'no push; both become solid when separated')
R.shared_start(s,{x=2,z=2,dir=0});R.ghosts(s,true);assert(not a.ghost and not b.ghost and (a.x~=b.x or a.z~=b.z),'round end separates stacked robots')
local bag={};local robot={draw_bonus=3};for seed=1,1000 do math.randomseed(seed);C.deal(robot);for _,card in ipairs(robot.hand)do bag[card]=(bag[card]or 0)+1 end end
assert(bag.STEP>bag.DASH and bag.DASH>bag.MOVE3 and bag.BACK>bag.BACK2 and bag.LEFT>bag.UTURN,'weighted bag')
print('PASS new commands, wall/pit stops, ghost start/separation/weapons/expiry, weighted cards, portable validation')
""")
# Exercise the actual editor fields and server permission checks without a GUI.
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r\'\'\'",1)[1].split("ui_events={};shift_circuit=dofile",1)[0]
lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix();lua.execute(source)
lua.execute("""
local store=core.get_mod_storage();core.deserialize=function(v)return type(v)=='table'and copy(v)or nil end
local admin=false;core.get_player_privs=function()return {server=admin}end
local current='editor';local room={solo_mode='editor',host='Author',api={phase=function()return current end,edit_level=function(data,play)room_data=copy(data);current=play and 'program'or 'editor'end}}
local e=dofile(modpath..'/editor.lua')(core,store,function(n)if n=='Author'then return room end end,function()end)
local p={get_player_name=function()return 'Author'end};clients.Author={};e.begin(room)
local function fields(f,form)callbacks.on_player_receive_fields(p,form or 'shift_circuit:editor',f)end
fields({b14=true});e.paint('Author',4,4);assert(room_data.overhead['4,4']and room_data.board['4,4'].kind=='floor','independent crusher layer')
fields({undo=true});assert(not room_data.overhead['4,4']);fields({publish=true});assert(next(e.catalog)==nil,'non-admin cannot approve')
fields({submit=true});assert(e.catalog['1']and not e.catalog['1'].approved,'player submission pending')
admin=true;fields({publish=true});assert(e.catalog['2'].approved,'admin saves approved')
fields({test=true});assert(current=='program','playtest enters programming');fields({resume=true});assert(current=='editor','return restores draft')
assert(e.draft('Author').data.board['8,3'].kind=='checkpoint','playtest never changes draft')
fields({group_2=true,b5=true,dir_0=true});editor_form=clients.Author.shown;e.paint('Author',4,4)
local before=copy(e.draft('Author').data.board['4,4']);assert(before.kind=='belt'and before.entry~=nil)
for i=1,4 do assert(e.rotate('Author',4,4));local t=e.draft('Author').data.board['4,4'];assert(t.dir==i%4 and t.entry==(before.entry+i)%4)end
assert(same(before,e.draft('Author').data.board['4,4']),'four rotations restore curved conveyor')
fields({size_20=true});assert(e.draft('Author').data.size==10 and e.draft('Author').locked,'size locked after editing')
assert(not clients.Author.shown:find('JAMMER')and not clients.Author.shown:find('SHIELD'),'no loose powerup brushes')
room.origin={x=0,y=0,z=0};function p:get_pos()return {x=8.5,y=10,z=8.5}end;function p:get_look_dir()return {x=0,y=-1,z=0}end
fields({b5=true});for dir=0,3 do p.get_look_horizontal=function()return -dir*math.pi/2+.1 end;tools['shift_circuit:editor_brush'].on_use({},p);local t=e.draft('Author').data.board['4,4'];assert(t.dir==dir and t.entry==(dir+1)%4,'placement follows snapped view direction')end
print('PASS camera-directed placement in all four directions')
print('PASS fixed editor sizes, placed curved-conveyor rotation, undo, and spawner-only palette')
print('PASS editor layers, undo, draft preservation, submit, admin authorization and playtest lifecycle')
""")
