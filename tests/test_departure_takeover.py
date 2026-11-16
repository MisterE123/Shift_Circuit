from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
setup=(root/'tests/test_online.py').read_text().split("lua.execute('''",1)[1].split("dofile(modpath..'/online.lua')",1)[0];lua.execute(setup)
lua.execute(r"""
async={};core.handle_async=function(work,done,s,id,path)async[#async+1]={done=done,s=s,id=id}end
local function finish_jobs()local jobs=async;async={};for _,j in ipairs(jobs)do j.done({'WAIT','WAIT','WAIT','WAIT','WAIT'})end end
local add=core.add_entity;core.add_entity=function(p)local o=add(p);function o:set_observers(v)self.observers=copy(v)end;return o end
dofile(modpath..'/online.lua');callbacks.on_mods_loaded();flush()
local a=newplayer('Alpha');local b=newplayer('Beta');local c=newplayer('Viewer');flush()
local function fields(p,f)callbacks.on_player_receive_fields(p,'shift_circuit:online',f);flush()end
fields(a,{create=true});fields(a,{create_confirm=true});tick(.1);flush();tick(.1)
local r=shift_circuit.rooms[shift_circuit.member.Alpha]
fields(b,{['join_'..r.id]=true});fields(c,{['watch_'..r.id]=true});fields(a,{bots0=true,launch=true})
local s;for i=1,30 do local k,v=debug.getupvalue(r.api.snapshot,i);if k=='S'then s=v end end
local function robot(n)for _,q in ipairs(s.bots)do if q.id==n then return q end end end
local own=robot('Alpha');own.hp=3;own.parts.range=2;own.next=2;own.hand={'WAIT','WAIT','WAIT','WAIT','WAIT','STEP'};own.hand_ids={1,2,3,4,5,6};own.program={};own.selected={};own.program_ids={};own.ready=false
r.api.queue('Alpha',6);local before=copy(own)
callbacks.on_leaveplayer(a);clients.Alpha=nil
assert(own.enemy and own.disconnected and own.difficulty==1 and r.host=='Beta','easy AI takes over host seat')
local stranger=newplayer('Stranger');flush();fields(stranger,{['join_'..r.id]=true});assert(r.spectators.Stranger and own.disconnected and #s.bots==2,'another account cannot claim reserved robot');fields(stranger,{leave=true})
assert(same(own.hand,before.hand)and own.hp==3 and own.parts.range==2 and own.next==2,'state and finite hand preserved')
a=newplayer('Alpha');flush()
assert(shift_circuit.member.Alpha==r.id and not r.spectators.Alpha and robot('Alpha')==own and #s.bots==2,'automatic reconnect reclaims exact robot')
assert(not own.enemy and not own.disconnected and same(own.program,before.program)and same(own.selected,before.selected),'partial program preserved before AI finishes')
finish_jobs();assert(same(own.program,before.program)and not own.ready,'stale worker cannot overwrite human program')
assert(a.inv.list[1].name=='shift_circuit:commit'and not a.attached,'planning HUD and tools restored')
assert(a.p.x==r.origin.x+own.x*2+.5 and a.p.z==r.origin.z+own.z*2+.5,'rejoin view starts over own robot')
fields(a,{leave=true});assert(own.enemy and own.difficulty==1,'voluntary departure also replaced')
finish_jobs();assert(own.ready and #own.program==5,'replacement finishes a legal program')
fields(a,{['join_'..r.id]=true});assert(not own.enemy and own.ready and not r.spectators.Alpha,'manual rejoin preserves AI committed program')
local beta=robot('Beta');beta.hand={'WAIT','WAIT','WAIT','WAIT','WAIT'};beta.hand_ids={7,8,9,10,11};for i=1,5 do r.api.queue('Beta',i)end;r.api.commit('Beta')
assert(r.api.phase()=='direction_reading')
local phases={direction_reading=true,direction=true,reading=true,commands=true,express=true,belts=true,pushers=true,rotators=true,weapons=true,lasers=true,presses=true}
local checked={}
for i=1,1200 do
 local phase=r.api.phase()
 if phases[phase]and not checked[phase]then
  local program=copy(own.program);local ids=copy(own.program_ids);local x,z,dir=own.x,own.z,own.dir
  callbacks.on_leaveplayer(a);clients.Alpha=nil;a=newplayer('Alpha');flush()
  assert(robot('Alpha')==own and not own.enemy and own.x==x and own.z==z and own.dir==dir,'execution reconnect preserves robot pose')
  assert(same(own.program,program)and same(own.program_ids,ids)and a.attached,'execution cards and follow camera preserved: '..phase)
  checked[phase]=true
 end
 tick(.05);finish_jobs();if s.round==2 then break end
end
assert(s.round==2 and not a.attached and not own.enemy,'round boundary returns human to planning')
assert(checked.direction_reading and checked.direction and checked.commands and checked.presses,'covered direction and execution phases')
own.finished=true;own.rank=1;callbacks.on_leaveplayer(a);clients.Alpha=nil;a=newplayer('Alpha');flush();assert(own.finished and own.rank==1 and not own.enemy and #s.bots==2,'finished racer can reclaim result without spawning another robot');own.finished=nil;own.rank=nil
-- A down robot stays down on reconnect; no free respawn, repair or loadout reset.
own.down=true;own.hp=0;local home=copy(own.home);callbacks.on_leaveplayer(a);clients.Alpha=nil;a=newplayer('Alpha');flush();assert(own.down and own.hp==0 and same(own.home,home))
-- Last-person network loss reserves an arena briefly; voluntary exits release it.
fields(c,{leave=true});fields(b,{leave=true});callbacks.on_leaveplayer(a);clients.Alpha=nil
assert(r.empty_grace==300 and shift_circuit.rooms[r.id],'empty room retained for reconnect')
assert(r.api.phase()=='planning_ai','all-human departure waits for replacement planner')
a=newplayer('Alpha');flush();assert(r.api.phase()=='program'and not own.ready,'rejoining while planner is pending restores human planning');finish_jobs();assert(not own.ready,'canceled last-human planner cannot auto-commit')
assert(not r.empty_grace and shift_circuit.member.Alpha==r.id,'last player can return')
callbacks.on_leaveplayer(a);clients.Alpha=nil;tick(301);assert(not shift_circuit.rooms[r.id],'abandoned room and arena released after grace period')
a=newplayer('Alpha');flush();assert(not shift_circuit.member.Alpha,'expired reservation safely returns to lobby')
print('PASS low-skill takeover, host transfer, partial/committed cards, stale AI jobs, all execution phases, camera/HUD restoration, down robot, empty-room reconnect and expiry')
""")
