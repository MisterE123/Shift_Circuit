from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
lua.execute("""
local R=dofile(modpath..'/rules.lua');local C=dofile(modpath..'/campaign.lua')
for choice,offset in pairs(R.start_directions)do for facing=0,3 do
 local b={x=3,z=3,dir=facing,start_direction=choice,home={x=3,z=3,dir=facing}};local s={round=1}
 R.start_facing(s,b);assert(b.dir==(facing+offset)%4 and b.x==3 and b.z==3 and s.round==1 and b.home.dir==b.dir)
 local dir=b.dir;R.start_facing(s,b);assert(b.dir==dir,'orientation applies once')
end end
local api=dofile(modpath..'/runtime.lua')(core,{});callbacks.on_mods_loaded();flush();local a=newplayer('Alpha');local p=newplayer('Beta');flush();assert(api.start('Alpha','race',1))
local s;for i=1,30 do local k,v=debug.getupvalue(api.snapshot,i);if k=='S'then s=v end end
s.walls={};s.overhead={};s.lasers={};s.pushers={};s.pickups={};s.spawners={}
for x=1,s.size do for z=1,s.size do s.board[R.key(x,z)]={kind='floor'}end end
for _,b in ipairs(s.bots)do
 assert(#b.hand==b.allowance and b.allowance==9,'free direction cards do not change the normal draw')
 b.x=5;b.z=5;b.dir=0;b.hp=2;b.hand={'STEP','WAIT','WAIT','WAIT','WAIT'};b.hand_ids={10,20,30,40,50}
 for i=1,5 do api.queue(b.id,i)end
end
local b=s.bots[1];assert(#b.program==5)
assert(#a.inv.list==10 and a.hotbar==10,'commit, five regular cards and four blue cards')
tools['shift_circuit:direction_right'].on_use(nil,a);assert(b.start_direction=='RIGHT'and b.dir==0 and #b.program==5)
tools['shift_circuit:direction_right'].on_secondary_use(nil,a);assert(not b.start_direction,'blue undo leaves regular program intact')
tools['shift_circuit:direction_left'].on_use(nil,a);assert(b.start_direction=='LEFT'and #b.selected==5)
local blue,green
for _,h in ipairs(a.hud)do if h.text=='sc_direction_LEFT.png'and h.offset.x==-190 then blue=h end;if h.text=='sc_card_STEP.png'and h.offset.x==-114 then green=h end end
assert(blue and green,'blue first slot, normal cards begin in the second slot')
api.commit('Alpha');api.commit('Beta');assert(api.phase()=='direction_reading'and s.bots[2].start_direction=='FORWARD','empty direction defaults to Forward')
tick(.46);assert(api.phase()=='direction'and b.dir==3 and b.hp==2 and b.x==5 and b.z==5 and s.round==1 and not s.register,'blue card only sets facing')
tick(.66);assert(api.phase()=='reading'and api.snapshot().slot==1,'five normal registers follow')
tick(.46);assert(b.x==4 or s.bots[2].z==6,'normal movement begins after the facing prelude')
for i=1,1200 do tick(.05);if s.round==2 then break end end
assert(s.round==2,'opening round contains the normal five-register cycle')
for _,stack in ipairs(a.inv.list)do assert(not stack.name:find('direction_',1,true),'blue cards removed next round')end
local dir=b.dir;tools['shift_circuit:direction_right'].on_use(nil,a);assert(not b.start_direction and b.dir==dir,'blue tools cannot be used in later rounds')
local state={size=10,round=1,board={},bots={},walls={}}
for x=1,10 do for z=1,10 do state.board[R.key(x,z)]={kind='floor'}end end
state.board['7,5']={kind='station',number=1}
local ai={id='AI',enemy=true,racing=true,x=5,z=5,dir=0,hp=5,energy=4,next=1,hand={'STEP','STEP','STEP','STEP','STEP'}};state.bots={ai}
local plan=C.plan(R,state,ai);assert(plan.start_direction=='RIGHT'and #plan==5 and ai.dir==0,'AI plans a starting facing without spending a normal card or mutating the live bot')
print('PASS free blue cards, first-only slot, replace/undo/default, orientation-only execution, five normal registers, later-round rejection and AI facing choice')
""")
