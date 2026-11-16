from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
lua.execute('''
local R=dofile(modpath..'/rules.lua');local G=dofile(modpath..'/geometry.lua');G.arm=dofile(modpath..'/arm_pose.lua');local N=dofile(modpath..'/network_updates.lua')
local function spawn(mesh,p,props)local o=core.add_entity(p);o:set_properties(props or {});o.mesh=mesh;function o:set_observers(v)self.observers=v end;return o end
local V=dofile(modpath..'/systems_visual.lua')(R,G,spawn,N)
for _,scale in ipairs({1,.5})do for dir=0,3 do
 local actor=core.add_entity({x=40,y=1,z=80});actor:set_yaw(G.yaw(dir));actor.e.display_scale=scale
 function actor:get_observers()return {Owner=true}end
 local b={id='Test',dir=dir,hp=5,parts={mechanical_arm=1,electromagnetic_brake=1},enabled={mechanical_arm=false,electromagnetic_brake=false}}
 V.sync(b,actor)
 for _,slot in ipairs({'mechanical_arm','arm_a','arm_b','claw','finger_left','finger_right','electromagnetic_brake'})do
  local o=actor.e.mounts[slot];assert(o and o.props.is_visible and o.observers.Owner,'installed part visible and observer-scoped immediately: '..slot)
 end
 assert(actor.e.mounts.arm_a.p.y>=actor.p.y+1.69*scale,'arm shoulder is above other equipment')
 actor:set_pos({x=60,y=1,z=90});for _,o in pairs(actor.e.mounts)do V.step(o.e,0)end
 assert(math.abs(actor.e.mounts.claw.p.x-60)<1 and math.abs(actor.e.mounts.claw.p.z-90)<1,'idle arm follows robot before first use')
 local target={x=62,y=1.45,z=90};V.reach(actor,target);local grip=actor.e.mounts.claw;local previous=copy(grip.p);local reached=false
 for i=1,65 do
  V.tick_actor(actor.e,.02);for _,o in pairs(actor.e.mounts)do V.step(o.e,.02)end
  local dx,dy,dz=grip.p.x-previous.x,grip.p.y-previous.y,grip.p.z-previous.z
  assert(math.sqrt(dx*dx+dy*dy+dz*dz)<.45,'smooth reach and return without teleport from original spawn')
  if actor.e.arm_motion and actor.e.arm_motion.elapsed>.46 and actor.e.arm_motion.elapsed<.62 then assert(math.abs(grip.p.x-target.x)<.001 and math.abs(grip.p.y-target.y)<.001);reached=true end
  previous=copy(grip.p)
 end
 assert(reached and not actor.e.arm_motion and grip.props.is_visible,'grasp target then return to visible folded pose')
 b.down=true;V.sync(b,actor);assert(not next(actor.e.mounts),'destroyed robot removes arm and brake')
 b.down=false;V.sync(b,actor);assert(actor.e.mounts.claw.props.is_visible,'respawn rebuilds visible resting arm')
end end
print('PASS visible folded arm/brake, installation above equipment, all facings/scales, smooth reach/grasp/retract, relocation and destruction/respawn')
''')
