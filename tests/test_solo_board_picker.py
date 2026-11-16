from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r\'\'\'",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
setup=(root/'tests/test_online.py').read_text().split("lua.execute(\'\'\'",1)[1].split('local smallboard=',1)[0];lua.execute(setup)
lua.execute("""
local L=dofile(modpath..'/levels.lua');local catalog={};for i=1,4 do local d=L.blank(10);d.title='Pick '..i;catalog[tostring(i)]={data=d,author='Admin',approved=true}end
core.get_mod_storage():set_string('level_catalog',catalog)
dofile(modpath..'/online.lua');callbacks.on_mods_loaded();flush();local p=newplayer('Picker');flush()
local function fields(f)callbacks.on_player_receive_fields(p,'shift_circuit:online',f);flush()end
fields({solo_race=true});assert(p.shown:find('solo_board_level_1')and p.shown:find('solo_board_level_3')and not p.shown:find('solo_board_level_4'))
fields({solo_board_next=true});assert(p.shown:find('solo_board_level_4')and p.shown:find('2 / 2'))
fields({solo_board_level_4=true});assert(p.shown:find('> Pick 4'))
fields({play_solo=true});tick(.1);flush();tick(.1)
local room=shift_circuit.rooms[shift_circuit.member.Picker];local state=room.api.snapshot().state
assert(state.mode=='race'and state.course_key:find('level_4@0,0',1,true)and not state.course_key:find('level_1',1,true),'selected board actually launches')
print('PASS solo board picker: paged previews, selection highlight and selected single-board race launch')
""")
