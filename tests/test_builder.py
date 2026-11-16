from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
lua.execute('''
local B=dofile(modpath..'/board_builder.lua');local L=dofile(modpath..'/levels.lua');local Q=dofile(modpath..'/courses.lua');local R=dofile(modpath..'/rules.lua')
local b=B.new(4);assert(B.place(b,'small',10,0,0));assert(not B.place(b,'small',10,1,1),'corner contact is not adjacent');assert(B.place(b,'middle',20,1,0));assert(B.place(b,'large',20,1,2));assert(not B.remove(b,1,0),'cannot remove connecting board');assert(not B.place(b,'small',10,2,1),'overlap blocked');assert(not B.place(b,'large',30,5,0),'bounds blocked');assert(B.remove(b,2,3),'whole large piece returned');assert(B.place(b,'large',20,1,2));assert(B.place(b,'small',10,0,1));assert(B.place(b,'small',10,0,2),'legacy count limit ignored');assert(B.remove(b,0,2));assert(#b.items==4)
local state=Q.assemble(R,{L.blank(10),L.blank(20),L.blank(20),L.blank(10)},9,b.items);assert(state.size==40 and state.checkpoint_count==9);assert(state.board['10,2'].kind~='pit'and state.board['11,2'].kind~='pit','seams join without a pit gap');assert(state.board['1,30'].kind=='pit','unoccupied footprint remains a hole')
for _,size in ipairs({10,20})do assert(L.validate(L.blank(size)))end
assert(not L.validate(L.blank(30)),'30-square boards are no longer offered');assert(not L.validate(L.blank(15)),'new 15-square board is rejected')
local old=L.blank(11);old.version=2;old.pickups['3,3']='blink';local migrated=L.validate(old);assert(migrated.size==20 and not next(migrated.pickups)and migrated.spawners['3,3'],'legacy loose pickups become random spawners')
print('PASS shared board footprints, collision, cardinal adjacency, connectivity, limits, exact assembly and legacy migration')
''')
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
setup=(root/'tests/test_online.py').read_text().split("lua.execute('''",1)[1].split("dofile(modpath..'/online.lua')",1)[0];lua.execute(setup)
lua.execute('''
local catalog={};local L=dofile(modpath..'/levels.lua');for i=1,60 do local d=L.blank(i%2*10+10);d.title='Factory '..i;catalog[tostring(i)]={data=d,approved=true,author='Test'}end
core.get_mod_storage():set_string('level_catalog',catalog)
dofile(modpath..'/online.lua');callbacks.on_mods_loaded();flush()
local a=newplayer('Author');local b=newplayer('Builder');local c=newplayer('Watcher');flush()
local function fields(p,f)callbacks.on_player_receive_fields(p,'shift_circuit:online',f);flush()end
fields(a,{create=true});assert(a.shown:find('Allow all racers to build together'));fields(a,{create_confirm=true,board_limit='3',collaborative='false'});tick(.1);flush();tick(.1)
local room=shift_circuit.rooms[shift_circuit.member.Author];assert(room.board_limit==16 and not room.collaborative)
fields(b,{['join_'..room.id]=true});fields(c,{['watch_'..room.id]=true});fields(b,{course=true});fields(b,{piece_2=true,cell_2_0=true});assert(#room.layout.items==1,'creator-only enforced server side')
fields(a,{course=true});assert(a.shown:find('boards_scroll;vertical;.1',1,true)and a.shown:find('piece_60;'),'all boards in a content-sized scroll area')
fields(a,{search_boards=true,board_search='Factory 60',filter_10=true});assert(not a.shown:find('scroll_container[' ,1,true)and a.shown:find('Factory 60'),'search plus size filter')
assert(not a.shown:find('pieces_next'),'short filtered lists need no pagination')
fields(a,{search_boards=true,board_search='no matching title'});assert(a.shown:find('No matching boards'))
fields(a,{search_boards=true,board_search='',filter_0=true});fields(a,{piece_1=true,inspect=true});assert(a.shown:find('TILE LEGEND')and a.shown:find('sc_map_base_20.png'));inspect_form=a.shown
fields(a,{inspect_use=true});fields(a,{piece_2=true,cell_2_0=true});assert(#room.layout.items==2,'creator can build');assert(b.shown:find('2 BOARDS'),'open layout views update together')
fields(a,{build_rotate=true,cell_0_0=true});assert(room.layout.items[1].rotation==1 and b.shown:find('ROTATE'));fields(a,{build_rotate=true,cell_0_0=true});fields(a,{cell_0_0=true});fields(a,{cell_0_0=true});assert(room.layout.items[1].rotation==0);fields(a,{route_edit=true});assert(a.shown:find('sc_route_selected.png')and a.shown:find('font=bold'));fields(a,{route_back=true});fields(a,{course_back=true});fields(a,{toggle_collaboration=true});fields(a,{course=true});fields(b,{piece_2=true,cell_3_0=true});assert(#room.layout.items==3,'enabled collaboration shares same layout')
fields(c,{course=true});fields(c,{build_remove=true,cell_3_0=true});assert(#room.layout.items==3,'spectators cannot edit')
fields(a,{build_remove=true,cell_2_0=true});assert(#room.layout.items==3,'bridge removal rejected through UI');builder_form=a.shown
fields(b,{build_remove=true,cell_3_0=true});assert(#room.layout.items==2,'leaf removal frees inventory capacity');fields(b,{course_back=true});fields(a,{save_configuration=true});assert(a.shown:find('Configuration name'))
fields(a,{config_save=true,configuration_name='Shared Test Course'});assert(a.shown:find('Shared Test Course')and a.shown:find('PRIVATE'))
fields(a,{config_load_1=true});assert(#room.layout.items==2,'owner can immediately load the saved layout');fields(a,{course_back=true});fields(a,{bots0=true,launch=true});assert(room.status=='playing')
local function stateof(api)for i=1,30 do local k,v=debug.getupvalue(api.snapshot,i);if k=='S'then return v end end end
local s=stateof(room.api);local bot;for _,q in ipairs(s.bots)do if q.id=='Builder'then bot=q end end
bot.hp=3;bot.parts.range=2;local hand=copy(bot.hand);local handids=copy(bot.hand_ids);local x,z=bot.x,bot.z
callbacks.on_leaveplayer(b);clients.Builder=nil;for i=1,500 do tick(.01);if bot.ready then break end end
assert(bot.disconnected and bot.enemy and bot.racing and bot.hp==3 and bot.parts.range==2 and bot.x==x and bot.z==z,'takeover retains robot state')
assert(same(bot.hand,hand)and same(bot.hand_ids,handids)and bot.ready and #bot.program==5,'AI plans from original dealt hand')
for i=1,5 do room.api.queue('Author',i)end;room.api.commit('Author');local own;for _,q in ipairs(s.bots)do if q.id=='Author'then own=q end end;local program=copy(own.program);local ids=copy(own.program_ids)
callbacks.on_leaveplayer(a);clients.Author=nil;assert(same(own.program,program)and same(own.program_ids,ids),'execution disconnect preserves committed commands and priorities')
assert(#s.bots==2 and shift_circuit.rooms[room.id],'spectator can keep watching AI takeovers')
print('PASS room creation, optional collaboration, spectator permissions, shared updates, rejected disconnecting removal and midmatch AI takeover')
''')
# Verify editable images referenced by the new builder and editor are present.
for prefix,values in [('sc_build_piece_',range(1,4)),('sc_editor_',range(1,23))]:
 for i in values:assert (root/'mods/shift_circuit/textures'/f'{prefix}{i}.png').exists()


# Every composited symbol exists at its declared pixel size; edits change previews.
lua.execute("""
local L=dofile(modpath..'/levels.lua');local P=dofile(modpath..'/board_preview.lua');local R=dofile(modpath..'/rules.lua');local C=dofile(modpath..'/campaign.lua')
preview_samples={}
for _,size in ipairs({10,20})do for i=1,3 do preview_samples[#preview_samples+1]=P.texture(L.resize(C.setup(R,1,'race',i),size))end end
local d=L.blank(10);local before=P.texture(d);d.board['4,5']={kind='pit'};d.walls[R.edge(4,5,1)]=true;d.overhead['4,5']={kind='crusher'}
local after=P.texture(d);assert(before~=after and after:find(':24,32=sc_map_pit.png',1,true)and after:find(':31,32=sc_map_wall_v.png',1,true),'tile and edge coordinates match board data');preview_samples[#preview_samples+1]=after
""")
from PIL import Image
for value in lua.globals().preview_samples.values():
 parts=value.split(':');width,height=map(int,parts[1].split('x'))
 for part in parts[2:]:
  coords,name=part.split('=');x,y=map(int,coords.split(','));im=Image.open(root/'mods/shift_circuit/textures'/name)
  assert 0<=x<width and 0<=y<height and x+im.width<=width and y+im.height<=height,(name,coords)
print('PASS 66-board catalog search/paging, inspect legend, data-driven tile previews and exact symbol bounds')

# Persistent saves remain private until approval; owners never need approval.
lua.execute("""
local B=dofile(modpath..'/board_builder.lua');local store=core.get_mod_storage();local admin=false;core.get_player_privs=function(n)return {server=n=='Admin'and admin}end
local library=dofile(modpath..'/course_library.lua')(core,store,B);local choices={{id='a',size=10,data=dofile(modpath..'/levels.lua').blank(10)},{id='b',size=20,data=dofile(modpath..'/levels.lua').blank(20)}};local layout=B.new(4);assert(B.place(layout,'a',10,0,0));assert(B.place(layout,'b',20,1,0))
assert(B.rotate(layout,0,0));local id=assert(library.save('Owner','Morning Shift',layout,5,choices));assert(#library.list('Owner')==1 and #library.list('Other')==0);assert(library.load('Owner',id,choices,4));assert(not library.load('Other',id,choices,4),'unapproved IDs cannot bypass privacy');assert(not library.approve('Other',id));assert(library.load('Owner',id,choices,1),'legacy count limit ignored')
admin=true;assert(library.approve('Admin',id));assert(#library.list('Other')==1 and library.load('Other',id,choices,4).checkpoints==5)
local again=dofile(modpath..'/course_library.lua')(core,store,B);assert(again.load('Other',id,choices,4).layout.items[1].rotation==1,'rotation and approval survive restart')
assert(not again.save('Owner','Morning Shift',layout,3,choices),'owner cannot indirectly disable enabled config');assert(again.review('Admin',id,'disable'));assert(again.save('Owner','Morning Shift',layout,3,choices)==id);assert(not again.load('Other',id,choices,4),'editing an approved configuration revokes approval');assert(again.load('Owner',id,choices,4).checkpoints==3,'owner can still load immediately')
layout.items[1].x=3;layout.items[1].z=3;assert(not again.save('Owner','Disconnected',layout,3,choices),'invalid saved geometry rejected')
print('PASS named configurations, persistence, owner access, admin approval, private-ID protection, revision reapproval and room limits')
""")

