from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r\'\'\'",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
lua.execute("""
local L=dofile(modpath..'/levels.lua');local store=core.get_mod_storage()
core.get_player_privs=function(n)return {server=n=='Admin'}end
core.get_mod_data_path=function()return '/mod_data/shift_circuit'end
core.mkdir=function()end;core.get_dir_list=function()return {}end;core.write_json=copy
local writes={};core.safe_file_write=function(p,data)writes[p]=copy(data);return true end
local exporter=dofile(modpath..'/puzzle_library.lua')(core,L,store,{}, {},function()end,function()end)
local board=L.blank(10);board.title='Authored Race'
assert(not exporter.export('Player',{{data=board}},board.title),'admin-only')
assert(exporter.export('Admin',{{data=board}},board.title))
local manifest,init,folder
for p,v in pairs(writes)do if p:match('/boards.json$')then manifest=v;folder=p:gsub('/boards.json$','')elseif p:match('/init.lua$')then init=v end end
assert(manifest and #manifest.boards==1 and init:find('register_board_pack',1,true))
assert(folder:find('/exports/shift_circuit_boards_',1,true)and writes[folder..'/LICENSE.txt']:find('Permission is hereby granted',1,true))
local E={catalog={}};E.persist=function()store:set_string('level_catalog',copy(E.catalog))end
E.reconcile_names=function()end
local packs=dofile(modpath..'/board_packs.lua')(core,L,store,E)
local old=io.open;io.open=function()return {read=function()return '{}'end,close=function()end}end;core.parse_json=function()return copy(manifest)end
assert(packs.register('shift_circuit_boards_test','boards.json'));assert(E.catalog['1'].approved and E.catalog['1'].data.title=='Authored Race')
E.catalog['1'].data.title='Local edit';E.catalog['1'].approved=false;E.catalog['1'].enabled=false
assert(packs.register('shift_circuit_boards_test','boards.json'));assert(E.catalog['1'].data.title=='Local edit'and not E.catalog['1'].approved and not E.catalog['2'],'no overwrite or duplicate on restart')
E.catalog['1']=nil;assert(packs.register('shift_circuit_boards_test','boards.json'));assert(next(E.catalog)==nil,'deletion remains deleted')
assert(not packs.register('shift_circuit_boards_test','../boards.json'))
manifest.boards[2]=copy(manifest.boards[1]);assert(not packs.register('new_pack','boards.json')and next(E.catalog)==nil,'invalid pack rejected atomically')
manifest.boards[2]=nil
E.catalog['7']={data=copy(manifest.boards[1].data),author='Original author',approved=false,enabled=false}
assert(packs.register('bundled_same','boards.json'));assert(E.catalog['7'].author=='Original author'and not E.catalog['7'].enabled and not E.catalog['2'],'matching existing board is preserved without copies')
manifest.boards[1].data.board={};assert(not packs.register('new_pack','boards.json'))
io.open=old
print('PASS race mod export/license/admin gate, manifest registration, restart idempotence, preservation of edits/disabled/deleted boards, atomic validation and path checks')
""")
