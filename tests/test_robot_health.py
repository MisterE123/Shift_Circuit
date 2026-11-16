from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
lua.execute('''
local add=core.add_entity;core.add_entity=function(...)local o=add(...);o.set_observers=function(self,names)self.observers=copy(names)end;o.get_observers=function(self)return copy(self.observers)end;return o end
local api=dofile(modpath..'/runtime.lua')(core);callbacks.on_mods_loaded();flush();newplayer('Pilot');newplayer('Other');flush();api.start('Pilot','race',1)
local s;for i=1,30 do local k,v=debug.getupvalue(api.snapshot,i);if k=='S'then s=v end end
local b;for _,q in ipairs(s.bots)do if q.id=='Pilot'then b=q end end
local bars={};for _,o in ipairs(objects)do if o.p and o.e.health_bot and o.e.health_bot.id=='Pilot'then bars[#bars+1]=o end end
assert(#bars==2,'main and owner models each have one bar')
local own,other;for _,o in ipairs(bars)do if o.observers.Pilot then own=o else other=o end end
assert(own and other and not own.observers.Other and other.observers.Other,'matching observer filters prevent duplicates')
assert(other.p.y>own.p.y,'opponent ghost bar floats above the owner bar')
b.hp=2;tick(.1);assert(own.props.textures[1]=='sc_robot_health_5_2.png'and other.props.textures[1]=='sc_robot_health_5_2.png')
local actor=own.e.health_actor;actor:set_pos({x=30,y=5,z=20});callbacks.entity.on_step(own.e,.1);assert(own.p.x==30 and own.p.z==20 and math.abs(own.p.y-6.95)<.001,'bar tracks rendered position')
b.down=true;callbacks.entity.on_step(own.e,.1);assert(own.props.textures[1]=='sc_robot_health_5_0.png');b.down=false;b.hp=5;callbacks.entity.on_step(own.e,.1);assert(own.props.textures[1]=='sc_robot_health_5_5.png')
-- Ram Bot cycle shares the floating HUD and changes without losing hull status.
b.scripted=true;b.kind='ram_bot';b.winding=nil;b.last_action=nil
callbacks.entity.on_step(own.e,.1);assert(own.props.textures[1]:find('sc_ram_cycle_watch.png',1,true))
b.winding=true;callbacks.entity.on_step(own.e,.1);assert(own.props.textures[1]:find('sc_ram_cycle_wind.png',1,true))
b.winding=false;b.last_action='CHARGE';b.hp=2;callbacks.entity.on_step(own.e,.1);assert(own.props.textures[1]:find('sc_ram_cycle_charge.png',1,true)and own.props.textures[1]:find('sc_robot_health_5_2.png',1,true))
b.last_action='WAIT';callbacks.entity.on_step(own.e,.1);assert(own.props.textures[1]:find('sc_ram_cycle_watch.png',1,true))
b.down=true;callbacks.entity.on_step(own.e,.1);assert(own.props.textures[1]=='sc_robot_health_5_0.png','destroyed bots have no active cycle');b.down=false
actor.e.fallen=true;callbacks.entity.on_step(own.e,.1);assert(not own.props.is_visible);actor.e.fallen=nil;b.finished=true;callbacks.entity.on_step(own.e,.1);assert(not own.props.is_visible)
actor:remove();callbacks.entity.on_step(own.e,.1);assert(not own.p,'orphan bar removed')
print('PASS floating health updates, movement tracking, private ghost views, empty/destroyed bars, completion hiding and orphan cleanup')
''')
from PIL import Image
for maximum in (3,5):
 for hp in range(maximum+1):
  with Image.open(root/f'mods/shift_circuit/textures/sc_robot_health_{maximum}_{hp}.png')as im:assert im.size==(46,10)and im.mode=='RGBA'
