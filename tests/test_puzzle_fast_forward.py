from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
lua.execute('''
local api=dofile(modpath..'/runtime.lua')(core);callbacks.on_mods_loaded();flush();local player=newplayer('Pilot');flush()
local L=dofile(modpath..'/levels.lua');local d=L.blank(10);d.map_type='puzzle';d.board['2,3']={kind='pit'};d.enemies['8,8']={kind='patroller',dir=1};d.crates['5,5']={kind='steel'};d.overhead['5,5']={kind='crusher',parity=1}
d.puzzle={checkpoints={'8,3'},targets={},hands={['1']={'STEP','WAIT','WAIT','WAIT','WAIT'}},equipment={}};d=assert(L.validate_submission(d))
local function state()for i=1,30 do local k,v=debug.getupvalue(api.snapshot,i);if k=='S'then return v end end end
local function run(fast)
 api.edit_level(d,true);local s=state();if not fast then s.mode='race'end
 for i=1,5 do api.queue('Pilot',i)end;api.commit('Pilot')
 local elapsed=0;local phases={};local notice=false
 for i=1,2000 do tick(.05);elapsed=elapsed+.05;local snap=api.snapshot();phases[snap.slot..':'..snap.phase]=true
  for _,h in ipairs(player.hud)do if h.text and h.text:find('FAST FORWARD',1,true)then notice=true end end
  if snap.state.round==2 and snap.phase=='program'then break end
 end
 assert(s.round==2 and not s.bots[1].down,'normal end-of-round reboot still occurs')
 for register=1,5 do for _,phase in ipairs({'reading','commands','express','belts','pushers','rotators','weapons','lasers','presses'})do assert(phases[register..':'..phase],'phase not skipped: '..register..':'..phase)end end
 assert(notice==fast,'only destroyed puzzle players get fast-forward')
 local enemy=s.bots[2];return elapsed,{x=enemy.x,z=enemy.z,dir=enemy.dir,crate=copy(s.crates['5,5'])}
end
local normal,expected=run(false);local fast,actual=run(true);assert(fast<normal*.4,'destroyed round resolves substantially faster');assert(same(expected,actual),'hazards and enemy behavior are unchanged')
-- Retry and a living player run at normal card-reading speed again.
api.edit_level(d,true);for i=1,5 do api.queue('Pilot',i)end;api.commit('Pilot');tick(.1);assert(api.snapshot().phase=='direction_reading','retry restores normal speed')
local terminal=copy(d);terminal.puzzle.no_reboot=true;api.edit_level(terminal,true);for i=1,5 do api.queue('Pilot',i)end;api.commit('Pilot');for i=1,300 do tick(.05);if api.snapshot().phase=='finished'then break end end;assert(api.snapshot().state.failed=='Robot destroyed','no-reboot failure preserved')
print(('PASS puzzle destruction fast-forward %.2fs vs %.2fs, all phases retained, identical outcomes, normal reboot/retry timing and no-reboot failure'):format(fast,normal))
''')
