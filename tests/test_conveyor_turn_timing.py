from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
lua.execute("""
local G=dofile(modpath..'/geometry.lua')
for dir=0,3 do for _,turn in ipairs({1,3})do
 local from,to=G.yaw(dir),G.yaw((dir+turn)%4)
 assert(G.conveyor_yaw(from,to,.3)==from,'do not rotate while approaching bend')
 local middle=G.conveyor_yaw(from,to,.7);assert(math.abs(middle-from)>0 and math.abs(middle-from)<math.pi/2)
 assert(math.abs((G.conveyor_yaw(from,to,1)-to+math.pi)%(math.pi*2)-math.pi)<1e-8)
end end
local add=core.add_entity;core.add_entity=function(p)local o=add(p);function o:set_observers(v)self.observers=copy(v)end;return o end
local api=dofile(modpath..'/runtime.lua')(core,{});callbacks.on_mods_loaded();flush();local p=newplayer('Pilot');flush();assert(api.start('Pilot','race',1))
local s;for i=1,30 do local k,v=debug.getupvalue(api.snapshot,i);if k=='S'then s=v end end
s.walls={};s.lasers={};s.overhead={};s.pushers={};s.pickups={}
for x=1,s.size do for z=1,s.size do s.board[x..','..z]={kind='floor'}end end
s.board['2,2']={kind='belt',dir=1,speed=1};s.board['3,2']={kind='belt',dir=0,entry=1,speed=1}
local b=s.bots[1];b.x=2;b.z=2;b.dir=1;b.hand={'WAIT','WAIT','WAIT','WAIT','WAIT'};b.hand_ids={1,2,3,4,5}
callbacks.on_player_receive_fields(p,'shift_circuit:loadout',{apply=true})
local actor;for _,o in ipairs(objects)do if o.p and o.e.robot then actor=o end end
actor:set_yaw(G.yaw(1));actor.e.owner_view:set_yaw(G.yaw(1))
for i=1,5 do api.queue('Pilot',i)end;api.commit('Pilot')
for i=1,500 do tick(.01);if api.phase()=='belts'then break end end
assert(api.phase()=='belts'and b.dir==0 and actor.e.conveyor_turn and actor.e.owner_view.e.conveyor_turn)
local x=actor.p.x;tick(.2);assert(actor.p.x>x and math.abs(actor.yaw-G.yaw(1))<1e-8,'robot travels toward bend before changing facing')
tick(.3);assert(actor.yaw>G.yaw(1)and actor.yaw<0 and math.abs(actor.yaw-actor.e.owner_view.yaw)<1e-8,'both views turn together during arrival')
tick(.4);assert(math.abs(actor.yaw)<1e-8 and not actor.e.conveyor_turn,'facing completes with the conveyor movement')
print('PASS conveyor turning delayed until bend approach, smooth short-arc arrival and synchronized owner/opponent views')
""")
