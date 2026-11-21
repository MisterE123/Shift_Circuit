from pathlib import Path
from lupa import LuaRuntime

root = Path(__file__).resolve().parents[1]
lua = LuaRuntime(unpack_returned_tuples=True)
lua.globals().modpath = (root / "mods/shift_circuit").as_posix()
source = (root / "tests/test_controller.py").read_text().split("lua.execute(r" + "'" * 3, 1)[1].split("ui_events={};shift_circuit=dofile", 1)[0]
lua.execute(source)
lua.execute("""
local add=core.add_entity
core.add_entity=function(p)
 local o=add(p)
 function o:get_luaentity()if self.p then return self.e end end
 return o
end
local api=dofile(modpath..'/runtime.lua')(core,{})
callbacks.on_mods_loaded();flush()
local a=newplayer('Alpha');flush()
assert(api.start('Alpha','race',1))
for i=1,5 do api.queue('Alpha',i)end
api.commit('Alpha')
local first=assert(a.attached)
first:remove()
local orbit=tools['shift_circuit:orbit']
orbit.on_use(ItemStack('shift_circuit:orbit'),a)
assert(a.attached~=first and a.attached:get_luaentity(),'removed orbit anchor replaced')
orbit.on_secondary_use(ItemStack('shift_circuit:orbit'),a)
tick(.1)
assert(a.attached:get_luaentity().orbit_target==0,'replacement anchor preserves orbit input')
""")
print("PASS stale orbit anchor recovers on next orbit input")

setup = (root / "tests/test_online.py").read_text().split("lua.execute(" + "'" * 3, 1)[1].split("local testboard=", 1)[0]
lua.execute(setup)
lua.execute("""
dofile(modpath..'/online.lua')
local definition=core.registered_entities['shift_circuit:visual']
assert(definition.initial_properties.static_save==false)
local orphan=core.add_entity({x=0,y=0,z=0})
definition.on_step(orphan.e,.1)
assert(not orphan:get_pos(),'a restored visual with no owning room is removed')
local live=core.add_entity({x=0,y=0,z=0})
local stepped=false
live.e.session_step=function(e,dt)assert(e==live.e and dt==.1);stepped=true end
definition.on_step(live.e,.1)
assert(stepped and live:get_pos(),'room-owned visuals are left intact')
""")
print("PASS orphan visuals are removed without touching live room entities")
