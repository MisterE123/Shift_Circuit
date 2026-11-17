from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r\'\'\'",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
lua.execute("""
local L=dofile(modpath..'/levels.lua');local store=core.get_mod_storage()
local original=L.blank(10);original.title='LoopDLoop';local unwanted=copy(original);unwanted.title='LoopDLoop copy'
store:set_string('level_catalog',{['2']={author='MisterE',data=original,approved=true},['16']={author='MisterE',data=unwanted,approved=true}})
store:set_string('draft:MisterE',copy(unwanted));store:set_string('draft_meta:MisterE',{entry_id='16',locked=true})
local E=dofile(modpath..'/editor.lua')(core,store,function()end,function()end)
assert(E.catalog['2']and not E.catalog['16'],'remove only unwanted copy')
assert(store:get_string('retired_loopdloop_copy_backup')['16'].data.title=='LoopDLoop copy','recoverable backup')
assert(store:get_string('draft:MisterE').title=='LoopDLoop copy','draft preserved')
assert(not E.draft('MisterE').entry_id,'draft no longer points at deleted library entry')
E.catalog['17']={author='MisterE',data=copy(unwanted),approved=false};E.persist()
local again=dofile(modpath..'/editor.lua')(core,store,function()end,function()end)
assert(again.catalog['17'],'one-time cleanup does not prohibit future copies')
print('PASS duplicate retirement, original preservation, recoverable backup, draft preservation and one-time migration')
""")
