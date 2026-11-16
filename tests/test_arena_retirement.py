from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
setup=(root/'tests/test_online.py').read_text().split("lua.execute('''",1)[1].split('local testboard=',1)[0];lua.execute(setup)
lua.execute('''
local store=core.get_mod_storage();local L=dofile(modpath..'/levels.lua');local data=L.blank(10);data.title='Service Yard'
store:set_string('level_catalog',{['1']={author='Shift Circuit',data=copy(data),approved=true},['2']={author='Author',data=copy(data),approved=false}})
store:set_string('draft:Author',copy(data));store:set_string('course_catalog',{sentinel=true})
local e=dofile(modpath..'/editor.lua')(core,store,function()end,function()end)
assert(not e.catalog['1']and e.catalog['2']);assert(store:get_string('retired_generated_boards')['1']);assert(same(store:get_string('draft:Author'),data));assert(store:get_string('course_catalog').sentinel)
e=dofile(modpath..'/editor.lua')(core,store,function()end,function()end);assert(not e.catalog['1']and e.catalog['2'],'migration is repeatable')
dofile(modpath..'/online.lua');callbacks.on_mods_loaded();flush();local a=newplayer('Author');flush()
local function fields(f)callbacks.on_player_receive_fields(a,'shift_circuit:online',f);flush()end
fields({solo=true});assert(a.shown:find('No puzzles yet'));fields({play_solo=true});assert(not shift_circuit.member.Author)
fields({setup_back=true});fields({solo_race=true});assert(a.shown:find('No enabled boards'));fields({course=true});fields({cell_0_0=true});assert(a.shown:find('No enabled boards available'));assert(not a.shown:find('Assembly Line')and not a.shown:find('Reactor Hall'))
print('PASS generated imports retired, player copies/drafts/configs preserved, repeatable migration, empty catalog and campaign handled')
''')
assert not (root/'mods/shift_circuit/levels/service_yard.json').exists()
