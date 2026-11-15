from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split("ui_events={};shift_circuit=dofile",1)[0];lua.execute(source)
lua.execute('''
local add=core.add_entity;core.add_entity=function(p)local o=add(p);function o:set_observers(v)self.observers=copy(v)end;return o end
local api=dofile(modpath..'/runtime.lua')(core,{});callbacks.on_mods_loaded();flush();local a=newplayer('Alpha');local b=newplayer('Beta');flush();assert(api.start('Alpha','race',1))
for _,position in ipairs({{x=-5.1,y=3,z=8},{x=30,y=3,z=8},{x=8,y=23,z=8},{x=8,y=-5,z=8}})do a.p=position;local before=a.teleports;tick(.1);assert(a.teleports==before,'touching enclosure does not teleport player')end
a.p={x=-10,y=3,z=8};local before=a.teleports;tick(.1);assert(a.teleports==before+1,'escape recovery only beyond wall margin')
a.controls.zoom=true;local before=a.teleports;tick(.2);assert(a.teleports==before+1 and a.p.x==4.5 and a.p.z==4.5 and a.p.y==7,'Z jumps to a safe view above the robot')
tick(.2);assert(a.teleports==before+1,'holding Z does not stream position corrections');a.controls.zoom=false
local marker;for _,h in ipairs(a.hud)do if h.text=='sc_your_robot.png'then marker=h end end;assert(marker and marker.type=='image_waypoint'and marker.world_pos.x==4.5,'owner-only robot waypoint')
local S;for i=1,30 do local k,v=debug.getupvalue(api.snapshot,i);if k=='S'then S=v;break end end;assert(S)
S.board={};for z=1,11 do for x=1,11 do S.board[x..','..z]={kind='floor'}end end;S.walls={};S.overhead={};S.lasers={};S.pushers={};S.pickups={}
for i,bot in ipairs(S.bots)do bot.x=4;bot.z=4+i;bot.dir=0;bot.ghost=nil;bot.hand={'STEP','WAIT','WAIT','WAIT','WAIT'};bot.hand_ids={i==1 and 10 or 90,20+i,30+i,40+i,50+i};for j=1,5 do api.queue(bot.id,j)end end
for _,stack in ipairs(a.inv.list)do assert(not stack:get_meta():get_string('inventory_image'):find('sc_priority_',1,true),'priority never covers hotbar art')end
local labels=0;for _,h in ipairs(a.hud)do if h.type=='image'and h.text:find('sc_priority_',1,true)then labels=labels+1;assert(h.offset.y>=130 and not h.text:find('sc_card_',1,true),'priority is a separate HUD label below the card')end end;assert(labels==5)
api.commit('Alpha');api.commit('Beta');tick(.46)
assert(S.executing=='Beta' and S.bots[2].z==7 and S.bots[1].z==5,'highest ID moves first; lower priority has not moved')
tick(.56);assert(S.executing=='Alpha'and S.bots[1].z==6,'second robot moves only after first animation interval')
assert(api.snapshot().slot==1,'register order is preserved')
print('PASS per-register descending Priority IDs and separated robot animation intervals')
''')
