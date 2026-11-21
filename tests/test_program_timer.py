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

# Submit the settings through the multiplayer room creator.
lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
lua.execute(source)
setup=(root/'tests/test_online.py').read_text().split("lua.execute('''",1)[1].split("dofile(modpath..'/online.lua')",1)[0]
lua.execute(setup)
lua.execute('''
dofile(modpath..'/online.lua');callbacks.on_mods_loaded();flush()
local function fields(p,f)callbacks.on_player_receive_fields(p,'shift_circuit:online',f);flush()end
local timed=newplayer('Timed');local untimed=newplayer('Untimed');flush()
fields(timed,{create=true})
assert(timed.shown:find('Enable round time limit;true',1,true) and timed.shown:find('Seconds per round;90',1,true))
fields(timed,{create_confirm=true,timer_seconds='0'})
assert(not shift_circuit.member.Timed and timed.shown:find('Enter a whole number'))
fields(timed,{create_confirm=true,timer_seconds='120'})
fields(untimed,{create=true});fields(untimed,{timer_enabled='false'})
fields(untimed,{create_confirm=true,timer_seconds=''})
tick(.1);flush();tick(.1)
local rooms=shift_circuit.rooms
local timed_room=rooms[shift_circuit.member.Timed];local untimed_room=rooms[shift_circuit.member.Untimed]
assert(timed_room.round_time==120 and untimed_room.round_time==false)
fields(timed,{bots0=true,launch=true});fields(untimed,{bots0=true,launch=true})
assert(timed_room.api.snapshot().planning_left==240)
tick(241)
assert(timed_room.api.phase()~='program','custom timer auto-fills')
assert(untimed_room.api.phase()=='program' and not untimed_room.api.snapshot().planning_left,'disabled timer waits for a commit')
print('PASS room creation timer settings, validation, custom timeout and untimed planning')
''')
