return function(R,G,spawn)
 local V={};local atan2=math.atan2 or math.atan
 local equipment={'thermal_camera','mechanical_arm','turret_gearbox','hard_disk','holographic_memory','gyro_stabilizer','electroshield','titanium_hull'}
 local names={thermal_camera='Thermal Camera',blueprint_archive='Blueprint Archive',mechanical_arm='Mechanical Arm',turret_gearbox='Aim Gearbox',hard_disk='Hard Disk',holographic_memory='Holographic Memory',gyro_stabilizer='Gyro Stabilizer',electroshield='Electroshield',titanium_hull='Titanium Hull'}
 function V.item_name(kind)
  return names[kind]or (R.weapons[kind]and R.weapons[kind].title)or ({repair='Hull Repair',shield='Shield',cell='Power Cell',blink='Blink',range='Extended Range',cache='Command Cache',jammer='Jammer'})[kind]or kind:gsub('_',' ')
 end
 function V.hint(b)
  R.normalize(b);local lines={'Weapon: '..R.weapons[b.weapon].title,'Aim: '..({'Front','Right','Back','Left','Automatic'})[(b.aim_offset or 0)+1],'Range: '..b.range..' squares'}
  if b.blink then lines[#lines+1]='Blink: '..((b.blink_left or 0)>0 and 'ready'or 'used this round')end
  for _,kind in ipairs(equipment)do local count=b.parts and b.parts[kind]or 0;if count>0 then local enabled=kind=='gyro_stabilizer'and R.gyro(b)or (kind~='gyro_stabilizer'and not (b.enabled and b.enabled[kind]==false));lines[#lines+1]=names[kind]..' x'..count..(enabled and ''or ' / OFF')end end
  return table.concat(lines,'\n')
 end
 function V.sync(b,actor)
  local a=actor:get_luaentity();a.system_actor=true;a.system_bot=b;a.mounts=a.mounts or {}
  R.normalize(b);local desired={weapon=b.weapon}
  for _,kind in ipairs(equipment)do if b.parts and (b.parts[kind]or 0)>0 then desired[kind]=kind end end
  for slot,kind in pairs(desired)do
   local o=a.mounts[slot]
   if not o then o=spawn('mount_'..kind,actor:get_pos(),{pointable=false});a.mounts[slot]=o end
   if o then local e=o:get_luaentity();e.system_parent=actor;e.system_slot=slot;e.system_kind=kind;o:set_properties({mesh='sc_mount_'..kind..'.obj',textures={'sc_surface_mount_'..kind..'.png'}})
    if actor.get_observers and o.set_observers then o:set_observers(actor:get_observers())end
   end
  end
  for slot,o in pairs(a.mounts)do if not desired[slot]and not (desired.mechanical_arm and (slot=='arm_a'or slot=='arm_b'or slot=='claw'))then o:remove();a.mounts[slot]=nil end end
  if desired.mechanical_arm then for _,slot in ipairs({'arm_a','arm_b','claw'})do
   if not a.mounts[slot]then local o=spawn(slot=='claw'and 'arm_claw'or 'arm_link',actor:get_pos(),{pointable=false,is_visible=false});a.mounts[slot]=o;local e=o:get_luaentity();e.system_parent=actor;e.system_slot=slot;e.system_kind=slot end
   local o=a.mounts[slot];if actor.get_observers and o.set_observers then o:set_observers(actor:get_observers())end
  end end
 end
 function V.reach(actor,target)
  if not actor then return end;local e=actor:get_luaentity();e.reach_queue=e.reach_queue or {};e.reach_queue[#e.reach_queue+1]=target
 end
 function V.fire(actor,slot)
  local e=actor and actor:get_luaentity();local o=e and e.mounts and e.mounts[slot];if o then o:get_luaentity().flash=.4 end
 end
 function V.tick_actor(e,dt)
  if not e.arm_motion and e.reach_queue and #e.reach_queue>0 then e.arm_motion={target=table.remove(e.reach_queue,1),elapsed=0}end
  if e.arm_motion then e.arm_motion.elapsed=e.arm_motion.elapsed+dt;if e.arm_motion.elapsed>.6 then e.arm_motion=nil end end
 end
 local function link(o,a,b,scale)
  local dx,dy,dz=b.x-a.x,b.y-a.y,b.z-a.z;local h=math.sqrt(dx*dx+dz*dz);local length=math.sqrt(h*h+dy*dy)
  o:set_pos(a);o:set_properties({is_visible=length>.01,visual_size={x=scale,y=scale,z=length}})
  o:set_rotation({x=atan2(dy,h),y=-atan2(dx,dz),z=0})
 end
 function V.step(e,dt)
  local actor=e.system_parent;local p=actor and actor:get_pos();if not p then e.object:remove();return end
  local a=actor:get_luaentity();local b=a.system_bot;local scale=a.display_scale or 1
  if not b or b.finished or a.fallen then e.object:set_properties({is_visible=false});return end
  local slot=e.system_slot;e.clock=(e.clock or 0)+dt;e.flash=math.max(0,(e.flash or 0)-dt)
  if slot=='arm_a'or slot=='arm_b'or slot=='claw'then
   local motion=a.arm_motion;if not motion then e.object:set_properties({is_visible=false});return end
   local t=math.sin(math.min(1,motion.elapsed/.6)*math.pi);local root={x=p.x,y=p.y+1.1*scale,z=p.z};local dest=motion.target
   local tip={x=root.x+(dest.x-root.x)*t,y=root.y+(dest.y-root.y)*t,z=root.z+(dest.z-root.z)*t}
   local elbow={x=(root.x+tip.x)*.5,y=root.y+1.1*t,z=(root.z+tip.z)*.5}
   if slot=='arm_a'then link(e.object,root,elbow,scale)elseif slot=='arm_b'then link(e.object,elbow,tip,scale)else e.object:set_pos(tip);e.object:set_properties({is_visible=true,visual_size={x=scale,y=scale,z=scale}})end;return
  end
  local body=actor:get_yaw();local side,back,height=0,0,1.05
  if slot=='weapon'then side=0;back=.05
  elseif slot=='turret_gearbox'then height=.88
  elseif slot=='mechanical_arm'then side=.4;back=-.16 elseif slot=='hard_disk'then side=-.4;back=-.16
  elseif slot=='thermal_camera'then side=.3;back=.3;height=.98
  elseif slot=='holographic_memory'then back=-.35 elseif slot=='gyro_stabilizer'then height=.91
  elseif slot=='electroshield'then side=.32;back=-.35 elseif slot=='titanium_hull'then side=-.32;back=-.35 end
  if e.flash>0 then back=back-.1*math.sin(e.flash/.4*math.pi)end
  local dx=math.cos(body)*side-math.sin(body)*back;local dz=math.sin(body)*side+math.cos(body)*back
  e.object:set_pos({x=p.x+dx*scale,y=p.y+height*scale,z=p.z+dz*scale})
  local yaw=slot=='weapon'and (body+G.yaw((R.aim(b)-b.dir)%4))or body
  if slot=='gyro_stabilizer'then yaw=yaw+e.clock*.7 end
  local enabled=not (b.enabled and b.enabled[slot]==false);if slot=='gyro_stabilizer'then enabled=R.gyro(b)end
  local size=scale*(slot=='turret_gearbox'and .55 or 1)
  if slot=='weapon'or slot=='thermal_camera'then if slot=='thermal_camera'then yaw=body+G.yaw((R.aim(b)-b.dir)%4)end;local old=e.aim_yaw or yaw;local delta=(yaw-old+math.pi)%(2*math.pi)-math.pi; e.aim_yaw=old+delta*math.min(1,dt*12);yaw=e.aim_yaw end
  e.object:set_yaw(yaw);e.object:set_properties({is_visible=true,visual_size={x=size,y=size,z=size},glow=e.flash>0 and 12 or (enabled and 3 or 0)})
 end
 return V
end
