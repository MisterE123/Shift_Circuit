from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
lua.execute('''
local api=dofile(modpath..'/runtime.lua')(core);callbacks.on_mods_loaded();flush();newplayer('Pilot');flush()
local d=dofile(modpath..'/levels.lua').blank(10);d.enemies={['3,4']={kind='sentry',dir=0},['5,4']={kind='patroller',dir=0},['7,4']={kind='ram_bot',dir=0}};api.edit_level(d,true)
local s;for i=1,30 do local k,v=debug.getupvalue(api.snapshot,i);if k=='S'then s=v end end;s.round=2;dofile(modpath..'/rules.lua').ghosts(s,true);s.bots[1].down=true
for i=1,8 do tick(.1)end
local beams,mounts=0,0;for _,o in ipairs(objects)do if o.p then
 if o.props.mesh=='sc_beam.obj'and o.props.glow==7 then beams=beams+1 end
 if o.e.system_slot=='weapon'and o.e.system_parent and o.e.system_parent:get_luaentity().system_bot.scripted then mounts=mounts+1;assert(o.e.system_parent:get_luaentity().system_bot.kind=='sentry')end
end end
assert(beams==1 and mounts==1,'only the sentry has a mounted weapon and inspection beam')
local R=dofile(modpath..'/rules.lua');s.shots={};R.robot_weapons(s,1);assert(#s.shots==1 and s.shots[1].owner=='obstacle:3,4','execution agrees with inspection')
local sentry,actor,mount;for _,o in ipairs(objects)do if o.p and o.e.system_slot=='weapon'and o.e.system_parent then local a=o.e.system_parent;local b=a:get_luaentity().system_bot;if b.kind=='sentry'then sentry=b;actor=a;mount=o end end end
R.drop(sentry,'Robot weapon');tick(.05);assert(not mount.p or mount.props.is_visible==false,'sentry weapon hides immediately on destruction')
local V=dofile(modpath..'/systems_visual.lua')(R,dofile(modpath..'/geometry.lua'),function()error('destroyed sentry must not spawn equipment')end)
V.sync(sentry,actor);assert(not mount.p and next(actor:get_luaentity().mounts)==nil,'destroyed sentry mounts are removed')
V.sync(sentry,actor);assert(next(actor:get_luaentity().mounts)==nil,'later sync does not recreate floating laser')
print('PASS Patroller and Ram Bot have no preview beam or weapon mount; Sentry retains both and execution matches')
''')
