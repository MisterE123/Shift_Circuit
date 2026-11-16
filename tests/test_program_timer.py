from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1]
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0]
lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix();lua.execute(source)
lua.execute("""
local api=dofile(modpath..'/runtime.lua')(core,{multiplayer=true});callbacks.on_mods_loaded();flush();local p=newplayer('Pilot');flush();api.start('Pilot','race',1)
local function shown(texture)for _,h in ipairs(p.hud)do if h.text==texture then return true end end;return false end
assert(api.snapshot().planning_left==180 and shown('sc_program_timer_first_180.png'),'first round starts with three minutes')
for i=1,1605 do tick(.1)end;assert(shown('sc_program_timer_first_20.png'),'bar shrinks to amber threshold')
for i=1,100 do tick(.1)end;assert(shown('sc_program_timer_first_10.png'));assert(shown('AUTO-FILL IN 0:10'),'red countdown explains consequence')
for i=1,100 do tick(.1)end;assert(api.snapshot().phase~='program'and #api.snapshot().state.bots[1].program==5,'deadline fills and starts program')
for _,h in ipairs(p.hud)do assert(not tostring(h.text):find('sc_program_timer_',1,true),'bar hidden during execution')end
for i=1,1000 do if api.snapshot().phase=='program'then break end;tick(.1)end
assert(api.snapshot().state.round==2 and api.snapshot().phase=='program','next programming round begins')
tick(.2);assert(api.snapshot().planning_left<=90 and api.snapshot().planning_left>89,'later rounds return to 90 seconds')
assert(shown('sc_program_timer_90.png'),'later rounds use their full 90-second bar')
print('PASS double first-round time, then 90-second multiplayer timer, amber/red thresholds, automatic fill and execution hiding with one remaining human')
""")
