from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
lua.execute("""
local add=core.add_entity;core.add_entity=function(p)local o=add(p);function o:set_observers(v)self.observers=copy(v)end;return o end
local api=dofile(modpath..'/runtime.lua')(core,{});callbacks.on_mods_loaded();flush();newplayer('Alpha');newplayer('Beta');flush();assert(api.start('Alpha','race',1))
local s;for i=1,30 do local k,v=debug.getupvalue(api.snapshot,i);if k=='S'then s=v end end
for _,b in ipairs(s.bots)do b.save_serial=1 end
for i=1,5 do api.queue('Alpha',i);api.queue('Beta',i)end;api.commit('Alpha');api.commit('Beta');tick(.4)
local count=0
for _,o in ipairs(objects)do if o.p and o.e.private_owner then
 count=count+1;local n=0;for name in pairs(o.observers or {})do assert(name=='Alpha'or name=='Beta');n=n+1 end
 assert(o.observers[o.e.private_owner],'owner can see their arrow');assert(n==1,'each reboot arrow has exactly one permitted viewer')
end end
assert(count==2,'both players receive private reboot arrows')
local private={};for _,o in ipairs(objects)do if o.p and o.e.private_owner then private[o.e.private_owner]=o end end
local I=dofile(modpath..'/inspection.lua')
core.raycast=function()local hits={private.Beta,private.Alpha};local i=0;return function()i=i+1;if hits[i]then return {type='object',ref=hits[i]}end end end
assert(I.pointed(core,clients.Alpha,10)==private.Alpha.e.hint,'inspection skips another player private arrow')
print('PASS saved-direction arrows restricted to their owning player')
""")

