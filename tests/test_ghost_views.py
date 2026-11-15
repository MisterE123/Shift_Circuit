from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r\'\'\'",1)[1].split("ui_events={};shift_circuit=dofile",1)[0];lua.execute(source)
lua.execute("""
math.atan2=math.atan2 or function(y,x)return math.atan(y,x)end
local add=core.add_entity;core.add_entity=function(p)local o=add(p);function o:set_observers(v)self.observers=copy(v)end;function o:set_rotation(v)self.rotation=copy(v)end;return o end
local api=dofile(modpath..'/runtime.lua')(core,{});callbacks.on_mods_loaded();flush();local a=newplayer('Alpha');local b=newplayer('Beta');flush();assert(api.start('Alpha','race',1));tick(.4)
local found=0
for _,o in ipairs(objects)do if o.p and o.e.robot then
 local e=o.e;assert(e.owner_view and e.ghost_marker,'owner view and opponent pointer')
 local name=e.owner_view.observers.Alpha and 'Alpha'or 'Beta';local other=name=='Alpha'and 'Beta'or 'Alpha'
 assert(not o.observers[name]and o.observers[other]and not e.owner_view.observers[other],'per-player object visibility')
 assert(e.owner_view.props.visual_size.x==1 and o.props.visual_size.x==.5,'owner full size, opponent small')
 assert(e.destination.y==4.0,'floating robots clear the full-size owner and its head equipment')
 assert(e.owner_view.p.x==4.5 and e.owner_view.p.z==4.5,'owner stays centered on tile')
 assert(e.ghost_marker.p.x==4.5 and e.ghost_marker.p.z==4.5 and e.ghost_marker.p.y==3.0,'cone tip is centered above the owner robot')
 assert(e.ghost_marker.props.visual_size.x==.8 and e.ghost_marker.props.visual_size.y==.8,'cone width reduced without changing endpoint')
 assert(o.p.y==4.0 and not e.motion,'body enters raised ghost pose without lagging behind equipment')
 local mount=e.mounts.weapon;assert(mount and math.abs(mount.p.y-(o.p.y+.525))<.00001,'weapon follows scaled ghost head')
 local rot=e.ghost_marker.rotation;local length=e.ghost_marker.props.visual_size.z
 local dx=math.sin(-rot.y)*math.cos(rot.x)*length;local dz=math.cos(-rot.y)*math.cos(rot.x)*length
 assert(math.abs(4.5+dx-e.destination.x)<.00001 and math.abs(4.5+dz-e.destination.z)<.00001,'cone points from center toward floating opponent')
 found=found+1
end end
assert(found==2)
for _,h in ipairs(a.hud)do if h.text=='sc_your_robot.png'then assert(h.z_index==32767,'owner marker draws above other HUD and world labels')end end
for _,o in ipairs(objects)do if o.p and o.props.nametag then assert(not o.props.nametag:find('_',1,true),'readable nametags')end end
for _,o in ipairs(objects)do if o.p and o.e.preview_tint then assert(o.e.preview_tint~='#327464','no ghost robot preview laser')end end
callbacks.on_leaveplayer(a)
for _,o in ipairs(objects)do if o.p and o.observers then assert(not (o.observers.Alpha and not o.observers.Beta),'removed departing private objects')end end
print('PASS private full-size owner views, floating opponents, centered cones, hidden ghost lasers, departure cleanup')
""")
