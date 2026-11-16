from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
lua.execute('''
local R=dofile(modpath..'/rules.lua');local G=dofile(modpath..'/geometry.lua');G.arm=dofile(modpath..'/arm_pose.lua')
local function spawn(mesh,p,props)
 local o=core.add_entity(p);o:set_properties(props or {})
 function o:set_attach(parent,bone,pos,rot,visible)self.parent=parent;self.offset=copy(pos);self.relative=copy(rot);self.attach_calls=(self.attach_calls or 0)+1;assert(visible)end
 function o:set_pos()error('attached mount must not receive independent position packets')end
 function o:move_to()error('attached mount must not interpolate independently')end
 return o
end
local V=dofile(modpath..'/systems_visual.lua')(R,G,spawn)
for _,scale in ipairs({1,.5})do
 local actor=core.add_entity({x=0,y=1,z=0});actor.e.display_scale=scale
 local b={id='A',dir=0,hp=5,parts={turret_gearbox=1,thermal_camera=1,mechanical_arm=1},aim_offset=0};V.sync(b,actor)
 local w=actor.e.mounts.weapon;assert(w.parent==actor and math.abs(w.offset.y-10.5*scale)<.001)
 local calls=w.attach_calls
 for i=1,20 do actor:set_pos({x=i,y=1,z=i});actor:set_yaw(i*.1);V.step(w.e,.05);assert(w.relative.y==0,'forward weapon inherits body rotation without extra smoothing')end
 assert(w.attach_calls==calls,'body motion sends no mount transforms')
 local arm_slots={'arm_a','arm_b','claw','finger_left','finger_right'}
 for _,slot in ipairs(arm_slots)do
  local part=actor.e.mounts[slot];assert(part.parent==actor);local count=part.attach_calls
  for i=1,12 do actor:set_pos({x=i*2,y=3,z=i});actor:set_yaw(i*.4);V.step(part.e,.05)end
  assert(part.attach_calls==count,'folded arm moves and turns with parent without new transforms')
 end
 local target={x=actor.p.x+2,y=actor.p.y+.45,z=actor.p.z-1};V.reach(actor,target);V.tick_actor(actor.e,.52)
 for _,slot in ipairs(arm_slots)do V.step(actor.e.mounts[slot].e,.05)end
 local tip=actor.e.mounts.claw.offset;local yaw=actor:get_yaw()
 local wx=actor.p.x+(math.cos(yaw)*tip.x-math.sin(yaw)*tip.z)/10
 local wz=actor.p.z+(math.sin(yaw)*tip.x+math.cos(yaw)*tip.z)/10
 assert(math.abs(wx-target.x)<.001 and math.abs(wz-target.z)<.001 and math.abs(actor.p.y+tip.y/10-target.y)<.001,'attached claw reaches world target at ghost/full scale')
 V.tick_actor(actor.e,.8);for _,slot in ipairs(arm_slots)do V.step(actor.e.mounts[slot].e,.05)end
 b.aim_offset=1;V.step(w.e,.05);assert(math.abs(w.relative.y-54)<.001,'independent relative aim interpolates')
 for i=1,30 do V.step(w.e,.05)end;assert(math.abs(w.relative.y-90)<.001)
 V.fire(actor,'weapon');V.step(w.e,.05);assert(w.offset.z<.5*scale,'recoil remains parent-relative')
 b.down=true;V.sync(b,actor);assert(not next(actor.e.mounts));b.down=false;V.sync(b,actor);assert(actor.e.mounts.weapon.parent==actor)
end
print('PASS parent-attached mounts, shared movement/rotation, relative aiming, recoil, ghost scale and respawn')
''')
