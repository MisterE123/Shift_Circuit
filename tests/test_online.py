from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=str(root/'mods/shift_circuit').replace('\\','/')
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split("ui_events={};shift_circuit=dofile",1)[0]
lua.execute(source)
lua.execute('''
core.registered_nodes={};core.registered_entities={};core.registered_items={};placements={}
core.register_node=function(n,d)core.registered_nodes[n]=d end
core.register_entity=function(n,d)core.registered_entities[n]=d;callbacks.entity=d end
core.register_tool=function(n,d)core.registered_items[n]=d;tools[n]=d end
core.set_node=function(p,n)placements[p.x..','..p.y..','..p.z]=n.name end
core.get_node=function(p)return {name=placements[p.x..','..p.y..','..p.z] or 'air'}end
core.deserialize=function(v)return type(v)=='table' and copy(v) or nil end
core.get_connected_players=function()local a={};for _,p in pairs(clients)do a[#a+1]=p end;return a end
core.log=function()end
local oldplayer=newplayer
function newplayer(n)local p=oldplayer(n);p.hud_remove=function(self,id)self.hud[id]=false end;return p end

local smallboard=dofile(modpath..'/levels.lua').blank(10);smallboard.title='Small test arena'
local testboard=dofile(modpath..'/levels.lua').blank(20);testboard.title='Test authored arena';core.get_mod_storage():set_string('level_catalog',{['1']={data=testboard,author='Test',approved=true},['2']={data=smallboard,author='Test',approved=true}})
dofile(modpath..'/online.lua');callbacks.on_mods_loaded();flush()
assert(next(shift_circuit.rooms)==nil,'server starts with no match boards')
placements['768,128,4096']='foreign:protected'
local a=newplayer('Alpha');local b=newplayer('Beta');local c=newplayer('Gamma');local d=newplayer('Delta');flush()
local function fields(p,f)callbacks.on_player_receive_fields(p,'shift_circuit:online',f);flush();if f.create then callbacks.on_player_receive_fields(p,'shift_circuit:online',{create_confirm=true,board_limit='4'});flush()end end
fields(a,{solo_race=true});fields(a,{play_solo=true});fields(b,{solo_race=true});fields(b,{play_solo=true});tick(.1);flush();tick(.1)
local ar=shift_circuit.rooms[shift_circuit.member.Alpha];local br=shift_circuit.rooms[shift_circuit.member.Beta]
assert(ar.slot~=1 and placements['768,128,4096']=='foreign:protected','allocator preserves unowned terrain')
assert(ar and br and ar~=br and ar.origin.x~=br.origin.x,'two isolated solo sessions')
assert(ar.api.snapshot().phase=='program' and br.api.snapshot().phase=='program')
local live;for i=1,30 do local key,v=debug.getupvalue(ar.api.snapshot,i);if key=='S'then live=v;break end end
live.bots[1].parts.turret_gearbox=1;callbacks.on_player_receive_fields(a,'',{aim='3'});assert(live.bots[1].aim_offset==3,'inventory changes route through room and save immediately')
tick(.3);local sound_count=#sounds;local form_before=a.form
callbacks.on_player_receive_fields(a,'',{equipment_scroll='CHG:20',weapon='1',aim='1'})
assert(#sounds==sound_count and a.form==form_before,'equipment scrolling is silent and does not rebuild the form')
assert(a.p.x~=b.p.x,'players moved to their own arenas')
for _,r in ipairs({ar,br})do
 local o=r.origin;assert(placements[(o.x-6)..','..(o.y+10)..','..o.z]=='shift_circuit:beam','enclosed wall')
 assert(placements[o.x..','..(o.y+23)..','..o.z]=='shift_circuit:beam','enclosed ceiling')
end
fields(c,{queue=true});fields(d,{queue=true});tick(1);flush();tick(.1);flush();tick(.1)
local cr=shift_circuit.rooms[shift_circuit.member.Gamma];assert(cr and cr==shift_circuit.rooms[shift_circuit.member.Delta] and cr~=ar,'queue forms an independent room')
fields(c,{bots2=true});fields(c,{launch=true})
local cs=cr.api.snapshot();assert(cs.phase=='program' and cs.state.platforms[1].size==20,'shared board layout launched')
local ais=0;for _,bot in ipairs(cs.state.bots)do if bot.enemy then ais=ais+1;assert(bot.hp==5 and bot.racing)end end;assert(ais==2,'creator racer count')
local before=br.api.snapshot();ar.api.queue('Alpha',1);assert(same(before,br.api.snapshot()),'editing one program cannot affect another session')
-- Force a result through the real phase loop, without adding a production mutation API.
local function stateof(api)for i=1,20 do local k,v=debug.getupvalue(api.snapshot,i);if k=='S'then return v end end end
local ast=stateof(ar.api);ast.winner='Alpha'
for i=1,5 do ar.api.queue('Alpha',i)end;ar.api.commit('Alpha');for _,b in ipairs(ast.bots)do b.finished=true end
for i=1,200 do tick(.2)end
assert(ar.status=='finished' and a.shown:find('PERSONAL RECORD'),'solo race completion opens result')
local cst=stateof(cr.api);cst.winner='Gamma'
for _,n in ipairs({'Gamma','Delta'})do for i=1,5 do cr.api.queue(n,i)end;cr.api.commit(n)end
for _,b in ipairs(cst.bots)do b.finished=true end
for i=1,200 do tick(.2)end
assert(cr.status=='finished' and c.shown:find('LEADERBOARD'),'multiplayer result leaderboard')
fields(c,{rematch=true});fields(c,{bots0=true});fields(c,{launch=true})
assert(cr.status=='playing' and cr.api.snapshot().state.ai_count==0,'creator bot setting applies to rematch')
local oldslot=ar.slot;fields(a,{leave=true});assert(not shift_circuit.rooms[ar.id] and br.api.snapshot().phase=='program','leave frees only own arena')
fields(a,{create=true});tick(.1);flush();tick(.1);local reused=shift_circuit.rooms[shift_circuit.member.Alpha];assert(reused.slot==oldslot,'unclaimed owned slot reused')
fields(a,{leave=true});fields(b,{leave=true});fields(c,{leave=true});fields(d,{leave=true});assert(next(shift_circuit.rooms)==nil,'all empty sessions released')
fields(a,{tutorial=true});tick(.1);flush();tick(.1)
local training=shift_circuit.rooms[shift_circuit.member.Alpha];local ts=training.api.snapshot().state
assert(ts.mode=='tutorial' and #ts.bots==1 and #ts.lasers==0 and next(ts.overhead)==nil,'short safe tutorial')
fields(a,{leave=true});fields(a,{solo_race=true});assert(a.shown:find('HUNTER INTELLIGENCE')and a.shown:find('RACER INTELLIGENCE'),'separate intelligence choices')
fields(a,{enemy_count='CHG:2',enemy_skill='CHG:3',racer_count='CHG:2',racer_skill='CHG:1'});fields(a,{play_solo=true});tick(.1);flush();tick(.1)
local race=shift_circuit.rooms[shift_circuit.member.Alpha];local rs=race.api.snapshot().state;assert(rs.mode=='race' and #rs.bots==5)
for _,robot in ipairs(rs.bots)do if robot.enemy then assert(robot.difficulty==(robot.racing and 1 or 3)and #robot.hand>=5,'sliders change planning skill, all adaptive bots deal hands')end end
stateof(race.api).winner='Alpha';for i=1,5 do race.api.queue('Alpha',i)end;race.api.commit('Alpha')
for _,b in ipairs(stateof(race.api).bots)do b.finished=true end
for i=1,250 do tick(.2)end
assert(race.status=='finished'and a.shown:find('PERSONAL RECORD'),'solo race stores turn record')
fields(a,{refresh=true});assert(a.shown:find('PERSONAL RECORD'),'record result remains stable when reopened')
fields(a,{leave=true})
fields(a,{leave=true});fields(a,{solo_race=true});fields(a,{course=true});fields(a,{piece_2=true,cell_2_0=true});fields(a,{course_back=true});fields(a,{play_solo=true});tick(.1);flush();tick(.1)
local mixed=shift_circuit.rooms[shift_circuit.member.Alpha].api.snapshot().state
assert(mixed.platform_count==2 and mixed.size==30,'solo manually assembled mixed-size course')
fields(a,{leave=true});fields(a,{create=true});tick(.1);flush();tick(.1);fields(a,{course=true});fields(a,{piece_2=true,cell_2_0=true});fields(a,{course_back=true});fields(a,{flags_5=true,launch=true})
local built=shift_circuit.rooms[shift_circuit.member.Alpha].api.snapshot().state;assert(built.platform_count==2 and built.checkpoint_count==5,'multiplayer shared course and creator checkpoint setting')
-- Eight total seats, with bot requests clamped after admitting humans.
local crowd={};for i=1,9 do crowd[i]=newplayer('Seat'..i)end;flush();fields(crowd[1],{create=true});tick(.1);flush();tick(.1)
local seats=shift_circuit.rooms[shift_circuit.member.Seat1]
for i=2,9 do fields(crowd[i],{['join_'..seats.id]=true})end
assert(shift_circuit.member.Seat9==seats.id and seats.spectators.Seat9,'ninth human joins as spectator')
for i=1,8 do fields(crowd[i],{bots7=true})end;fields(crowd[1],{launch=true})
local roster=seats.api.snapshot().state.bots;assert(#roster==8);for _,b in ipairs(roster)do assert(not b.enemy,'eight humans displace every requested bot')end
for i=6,8 do fields(crowd[i],{leave=true})end;seats.status='waiting';fields(crowd[1],{launch=true})
roster=seats.api.snapshot().state.bots;local ai=0;for _,b in ipairs(roster)do if b.enemy then ai=ai+1 end end;assert(#roster==8 and ai==3,'five humans plus three bots')
for i=2,5 do fields(crowd[i],{leave=true})end;seats.status='waiting';fields(crowd[1],{launch=true})
roster=seats.api.snapshot().state.bots;assert(#roster==8 and seats.api.snapshot().state.racer_count==7,'one human plus seven bots')
fields(crowd[1],{leave=true})
-- A human arriving during public building uses a seat before bots are spawned.
fields(crowd[1],{queue=true});fields(crowd[2],{queue=true});tick(1);flush();tick(.1)
local queued=shift_circuit.rooms[shift_circuit.member.Seat1];fields(crowd[1],{bots7=true});fields(crowd[2],{bots7=true})
fields(crowd[3],{queue=true});tick(.1);assert(shift_circuit.member.Seat3==queued.id,'queued human fills existing public room')
fields(crowd[3],{bots7=true});fields(crowd[1],{launch=true});roster=queued.api.snapshot().state.bots;ai=0;for _,b in ipairs(roster)do if b.enemy then ai=ai+1 end end;assert(#roster==8 and ai==5,'public human preference at launch')
print('PASS eight-seat cap, human priority, seven-bot solo capacity, ninth-human spectating, and public queue filling')
print('PASS online: on-demand solo/multiplayer isolation, queue, shared building, AI count, enclosed geometry, safe reuse, cleanup')
''')

