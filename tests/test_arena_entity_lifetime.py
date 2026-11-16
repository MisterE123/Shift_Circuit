from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
lua.execute("""
local held={};local acquires,frees=0,0
core.forceload_block=function(p,transient,limit)assert(transient and limit==-1);local k=p.x..','..p.y..','..p.z;held[k]=(held[k]or 0)+1;acquires=acquires+1;return true end
core.forceload_free_block=function(p,transient)assert(transient);local k=p.x..','..p.y..','..p.z;assert(held[k]and held[k]>0);held[k]=held[k]-1;if held[k]==0 then held[k]=nil end;frees=frees+1 end
local keeper=dofile(modpath..'/arena_active.lua')(core)
keeper.acquire({x=0,y=128,z=0},40);local total=acquires;assert(total==147,'bounded largest arena coverage')
keeper.acquire({x=0,y=128,z=0},40);assert(acquires==total,'no leaked duplicate references')
assert(held['80,128,80']and held['0,112,0'],'far robots and falling robots stay loaded')
keeper.release();assert(not next(held)and frees==total,'all transient blocks released')
local add=core.add_entity;core.add_entity=function(p)local o=add(p);function o:get_luaentity()if self.p then return self.e end end;function o:set_observers(v)self.observers=copy(v)end;return o end
local api=dofile(modpath..'/runtime.lua')(core,{});callbacks.on_mods_loaded();flush();local a=newplayer('Alpha');flush();api.start('Alpha','race',1)
local removed=0;local deadmain
for _,o in ipairs(objects)do if o.p then
 if o.props.mesh=='sc_ram.obj'or o.props.mesh=='sc_pusher_ram.obj'or o.props.mesh=='sc_rotator.obj'then o:remove();removed=removed+1 end
 if o.e.robot and not deadmain then deadmain=o end
end end
assert(removed>=2,'inspection machine references deliberately invalidated');tick(.4)
-- Trigger a sync after losing the public and private robot objects.
deadmain.e.owner_view:remove();deadmain:remove();tick(.1)
local replacement
for _,o in ipairs(objects)do if o.p and o.e.robot then replacement=o end end
assert(replacement and replacement~=deadmain and replacement.e.owner_view and replacement.e.owner_view:get_luaentity(),'lost public and private robot views recreated')
local s;for i=1,30 do local k,v=debug.getupvalue(api.snapshot,i);if k=='S'then s=v end end
local private=replacement.e.owner_view;private:remove();tick(.1);assert(replacement.e.owner_view~=private and replacement.e.owner_view:get_luaentity(),'lost private view alone is recovered without user input')
local b=s.bots[1];b.down=true;b.destroyed_by='Fell into a pit';callbacks.on_player_receive_fields(a,'shift_circuit:loadout',{apply=true});tick(1.1)
assert(not replacement.e.owner_view.props.is_visible)
local R=dofile(modpath..'/rules.lua');R.respawn(s);callbacks.on_player_receive_fields(a,'shift_circuit:loadout',{apply=true})
assert(replacement.props.is_visible and replacement.e.owner_view.props.is_visible,'respawn restores visibility in both views')
for i=1,5 do api.queue('Alpha',i)end;api.commit('Alpha');for i=1,300 do tick(.05)end
api.cleanup();assert(not next(held)and acquires==frees,'room cleanup releases arena including rebuilt board references')
print('PASS bounded transient arena loading, release/rebuild, removed-machine inspection, missing robot recovery and respawn visibility')
""")
