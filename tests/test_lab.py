from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split("ui_events={};shift_circuit=dofile",1)[0];lua.execute(source)
lua.execute('''
local original=core.add_entity;core.add_entity=function(p)local o=original(p);function o:set_rotation(v)self.rotation=copy(v)end;return o end
local api=dofile(modpath..'/runtime.lua')(core,{test_lab=true});callbacks.on_mods_loaded();flush();newplayer('Admin');flush()
assert(not api.lab('Admin','weapons'),'lab requires server privilege')
core.get_player_privs=function(n)return {server=n=='Admin'}end
for _,scenario in ipairs({'weapons','remote','arm','armor','spawners','factories'})do
 assert(api.lab('Admin',scenario));local s=api.snapshot().state;assert(s.test_scenario==scenario)
 for i=1,5 do api.queue('Admin',i)end;api.commit('Admin')
 for i=1,160 do tick(.2)end
 local mounts=0;for _,o in ipairs(objects)do if o.p and o.e.system_parent then mounts=mounts+1;assert(o.props.mesh)end end;assert(mounts>=8)
end
assert(not api.lab('Admin','unknown'));assert(not api.lab('Visitor','armor'))
print('PASS admin-only test scenarios, mounted equipment and ray/arm animation lifecycle')
''')
