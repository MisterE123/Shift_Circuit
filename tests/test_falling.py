from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split("ui_events={};shift_circuit=dofile",1)[0];lua.execute(source)
lua.execute('''
local add=core.add_entity;core.add_entity=function(p)local o=add(p);function o:set_observers(v)self.observers=copy(v)end;return o end
local api=dofile(modpath..'/runtime.lua')(core,{});callbacks.on_mods_loaded();flush();local a=newplayer('Alpha');flush();assert(api.start('Alpha','race',1))
local S;for i=1,30 do local k,v=debug.getupvalue(api.snapshot,i);if k=='S'then S=v;break end end
local b=S.bots[1];S.board['2,3']={kind='pit'};S.walls={};S.lasers={};S.pushers={};S.overhead={};b.x=2;b.z=2;b.dir=0;b.hand={'STEP','WAIT','WAIT','WAIT','WAIT'};b.hand_ids={1,2,3,4,5}
for i=1,5 do api.queue('Alpha',i)end;api.commit('Alpha')
local main;for _,o in ipairs(objects)do if o.p and o.e.robot then main=o;break end end;local own=main.e.owner_view;assert(own)
for i=1,80 do tick(.05);if b.down then break end end;assert(b.down and b.destroyed_by=='Fell into a pit','death applies immediately')
assert(main.e.fall and own.e.fall and own.props.visual_size.y==1,'both observer views fall at full height')
local y=own.p.y;tick(.25);assert(own.p.y<y and own.p.y> -4.5 and own.props.is_visible,'visible accelerating drop')
for i=1,8 do tick(.1)end
assert(main.e.fallen and own.e.fallen and not main.props.is_visible and not own.props.is_visible,'robot disappears below pit')
assert(a.attached.p.y>=9,'camera stays above the board')
for _,o in ipairs(objects)do if o.p and o.e.system_parent==own then assert(o.props.is_visible==false,'mounted systems disappear with fallen robot')end end
for i=1,800 do tick(.1);if S.round==2 then break end end
assert(S.round==2 and not b.down and own.props.is_visible and not own.e.fallen and not own.e.fall,'reboot restores robot and clears fall animation')
assert(own.p.y==1 and a.p.y==7,'robot and pilot return to their intended heights')
print('PASS visible pit descent, private actor parity, hidden mounts, safe follow camera and clean reboot')
''')
