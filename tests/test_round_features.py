from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
lua.execute('''
local R=dofile(modpath..'/rules.lua');local H=dofile(modpath..'/race_hud.lua');local L=dofile(modpath..'/levels.lua')
local s={round=1,pickups={},spawners={['2,2']={item='repair',chance=100,first=1,every=1}}};local calls=0
local function rng(n)calls=calls+1;return (calls-1)%n+1 end
local seen={};for round=1,#R.powerup_pool do s.round=round;s.pickups={};R.spawn_pickups(s,rng);local item=s.pickups['2,2'];seen[item]=true;R.spawn_pickups(s,rng);assert(calls==round,'no second roll during one round')end
assert(seen.double_laser and seen.mechanical_arm and seen.repair and not seen.jammer,'positive randomized supplies include weapons and equipment')
s.round=s.round+1;local held=s.pickups['2,2'];R.spawn_pickups(s,rng);assert(s.pickups['2,2']==held and calls==#R.powerup_pool,'occupied pads do not reroll')
local d=L.blank();d.spawners={['2,2']={item='repair',chance=100,rounds={1,3}}};local valid=L.validate(d);assert(valid.spawners['2,2'].item=='random','legacy fixed pads migrate')
local race={checkpoint_count=5,finishers={{id='Departed',rank=1,human=true}},bots={{id='Alpha',next=2,ready=true},{id='Beta',next=4,ready=false},{id='Racer',enemy=true,racing=true,next=3,ready=true},{id='Hunter',enemy=true,next=99}}}
local rows=H.rows(race,'program');assert(#rows==4 and rows[1].id=='Departed'and rows[1].status=='finished');assert(rows[2].id=='Beta'and rows[2].checkpoint==3 and rows[2].status=='planning');assert(rows[3].id=='Racer'and rows[3].status=='ready');assert(rows[4].id=='Alpha')
assert(H.rows(race,'commands')[2].status=='executing');race.bots[2].down=true;assert(H.rows(race,'commands')[2].status=='down')
print('PASS random scheduled supplies, occupied-pad protection, legacy migration and checkpoint-sorted racer statuses')
''')
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split("ui_events={};shift_circuit=dofile",1)[0];lua.execute(source)
lua.execute('''
local api=dofile(modpath..'/runtime.lua')(core,{});callbacks.on_mods_loaded();flush();local a=newplayer('Alpha');flush();assert(api.start('Alpha','race',1))
local S;for i=1,30 do local k,v=debug.getupvalue(api.snapshot,i);if k=='S'then S=v;break end end
S.round=2;dofile(modpath..'/rules.lua').ghosts(S,true);local b=S.bots[1];b.parts.turret_gearbox=1;b.hand={'WAIT','WAIT','WAIT','WAIT','WAIT'};b.hand_ids={1,2,3,4,5};callbacks.on_player_receive_fields(a,'shift_circuit:loadout',{apply=true})
local gear;for _,o in ipairs(objects)do if o.p and o.e.system_slot=='turret_gearbox'then gear=o end end;assert(gear);tick(.1);local yaw=gear.yaw;tick(.2);assert(gear.yaw==yaw and gear.props.visual_size.x==.55 and gear.p.y==1.88,'gearbox is compact, lower and stationary')
for i=1,5 do api.queue('Alpha',i)end;api.commit('Alpha');assert(a.hotbar==1 and a.inv.list[1].name=='shift_circuit:orbit'and #a.inv.list==1)
local anchor=a.attached;local start=anchor:get_pos();local program=copy(b.program)
tools['shift_circuit:orbit'].on_secondary_use(a.inv.list[1],a);tick(.1);local mid=anchor:get_pos();assert(mid.x>start.x and mid.x<start.x+8 and same(program,b.program),'smooth camera orbit leaves program untouched')
tools['shift_circuit:orbit'].on_use(a.inv.list[1],a);for i=1,8 do tick(.1)end;assert(math.abs(anchor.p.x-start.x)<.1,'opposite tool returns orbit')
for _,h in ipairs(a.hud)do if h.type=='image'and h.text:find('sc_racer_',1,true)then assert(h.text~='sc_racer_planning.png','execution status is current')end end
local expected={reading=1,commands=1,express=2,belts=3,pushers=4,rotators=5,weapons=6,lasers=7,presses=8};local seen={}
for i=1,250 do
 local phase=api.phase();local n=expected[phase]
 if n then
  local found=false;for _,h in ipairs(a.hud)do if h.text=='sc_phase_order_'..n..'.png'then found=true;assert(h.position.x==0 and h.position.y==1,'phase strip is bottom-left')end end
  assert(found,'current phase highlighted: '..phase);seen[n]=true
 end
 tick(.1)
end
for i=1,8 do assert(seen[i],'phase exercised '..i)end
print('PASS all eight phase highlights in execution order')
print('PASS single execution-only two-button orbit tool, smooth independent camera, unchanged program and lowered static gearbox')
''')

lua.execute("""
local R=dofile(modpath..'/rules.lua');local L=dofile(modpath..'/levels.lua')
local s={round=1,pickups={},spawners={['2,2']={first=1,every=3,phase=1,chance=50}}};local rolls=0
local function rng(n)rolls=rolls+1;return n==100 and 90 or 1 end
R.spawn_pickups(s,rng);assert(rolls==0 and not next(s.pickups),'off-phase pads start empty')
s.round=2;R.spawn_pickups(s,rng);assert(rolls==1 and not next(s.pickups),'due pad can miss its roll');R.spawn_pickups(s,function()error('must not reroll a failed spawn in same round')end)
s.round=5;R.spawn_pickups(s,function(n)return 1 end);assert(s.pickups['2,2']=='repair','next phased activation may spawn');s.round=8;R.spawn_pickups(s,function()error('occupied pad must not roll')end)
local d=L.blank();d.spawners={['2,2']={first=1,every=3,phase=3,chance=50}};assert(not L.validate(d),'phase must fit interval');d.spawners['2,2'].phase=2;d.spawners['2,2'].chance=101;assert(not L.validate(d));d.spawners['2,2'].chance=0;assert(L.validate(d))
s={round=1,pickups={},spawners={['2,2']={rounds={1},chance=0}}};R.spawn_pickups(s,function()error('disabled chance must not roll')end);assert(not next(s.pickups))
print('PASS phased supply timing, failed-roll cooldown, chance extremes, occupied pads and editor validation')
""")
