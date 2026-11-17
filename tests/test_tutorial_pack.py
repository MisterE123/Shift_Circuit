from pathlib import Path
import json
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
lua.globals().gamepath=root.as_posix()
def to_lua(value):
    if isinstance(value,dict):return lua.table_from({k:to_lua(v) for k,v in value.items() if v is not None})
    if isinstance(value,list):return lua.table_from([to_lua(v) for v in value])
    return value
lua.globals().decode_json=lambda raw:to_lua(json.loads(raw))
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
setup=(root/'tests/test_online.py').read_text().split("lua.execute('''",1)[1].split('local smallboard=',1)[0];lua.execute(setup)
lua.execute('''
local handlers={};core.register_on_player_receive_fields=function(fn)handlers[#handlers+1]=fn end
core.parse_json=decode_json;core.get_game_info=function()return {path=gamepath}end
core.get_modpath=function(n)if n=='shift_circuit_tutorial'then return gamepath..'/mods/shift_circuit_tutorial'end;return modpath end
core.get_current_modname=function()return 'shift_circuit_tutorial'end
local L=dofile(modpath..'/levels.lua');local hidden=L.blank(10);hidden.map_type='puzzle';hidden.puzzle={checkpoints={'8,3'}};hidden.title='Disabled workshop copy'
core.get_mod_storage():set_string('level_catalog',{['1']={data=hidden,author='Student',approved=false,enabled=false}})
core.get_player_privs=function()return {server=true}end
dofile(modpath..'/online.lua');dofile(gamepath..'/mods/shift_circuit_tutorial/init.lua');callbacks.on_mods_loaded();flush()
local entries=shift_circuit.puzzles.entries('Student','tutorial');assert(#entries==2)
assert(entries[1].data.title=='01 Welcome To the Floor'and entries[2].data.title=='02 Crate Job')
assert(entries[1].builtin and entries[1].tutorial and entries[2].tutorial)
assert(entries[1].data.puzzle.no_reboot and #entries[1].data.puzzle.hands['1']==6)
assert(entries[2].data.puzzle.hint=='Push the Crate to make a bridge')
assert(#shift_circuit.puzzles.entries('Student')==0,'tutorials and disabled entries are excluded even for admin/owner')
local p=newplayer('Student');flush()
local function fields(form,f)for _,fn in ipairs(handlers)do fn(p,form,f)end;flush()end
fields('shift_circuit:online',{tutorial=true});assert(p.shown:find('TUTORIAL]')and p.shown:find('01 Welcome To the Floor')and p.shown:find('02 Crate Job'))
assert(not p.shown:find('Built-in packs first'))
-- Reopening puzzles after dismissing tutorial must reset the menu filter.
fields('shift_circuit:puzzles',{quit=true});fields('shift_circuit:online',{solo=true});assert(p.shown:find('No puzzles yet')and not p.shown:find('01 Welcome To the Floor')and not p.shown:find('Disabled workshop copy'))
fields('shift_circuit:online',{tutorial=true})
fields('shift_circuit:puzzles',{play_1=true});tick(.1);flush();tick(.1)
local room=shift_circuit.rooms[shift_circuit.member.Student];local s=room.api.snapshot().state
assert(s.mode=='puzzle'and s.puzzle.no_reboot and #s.bots[1].hand==6 and s.puzzle.hint=='Reach the checkpoint without falling.')
shift_circuit.leave('Student');fields('shift_circuit:online',{tutorial=true});fields('shift_circuit:puzzles',{play_2=true});tick(.1);flush();tick(.1)
room=shift_circuit.rooms[shift_circuit.member.Student];s=room.api.snapshot().state;assert(s.mode=='puzzle'and s.puzzle.hint=='Push the Crate to make a bridge'and s.checkpoint_count==2)
print('PASS actual tutorial mod registration, authored order/settings, built-in priority, menu navigation, and both lessons launch as puzzles')
''')
