return function(R,G,spawn,Net)
 Net=Net or {properties=function(o,p)o:set_properties(p)end,move=function(o,p)if o.move_to then o:move_to(p,true)else o:set_pos(p)end end}
 local Arm=G.arm
 local V={};local atan2=math.atan2 or math.atan
 local equipment={'battering_ram','thermal_camera','mechanical_arm','turret_gearbox','hard_disk','holographic_memory','gyro_stabilizer','electroshield','titanium_hull','electromagnetic_brake'}
 local names={electromagnetic_brake='Electromagnetic Brake',battering_ram='Battering Ram',thermal_camera='Thermal Camera',blueprint_archive='Blueprint Archive',mechanical_arm='Mechanical Arm',turret_gearbox='Aim Gearbox',hard_disk='Hard Disk',holographic_memory='Holographic Memory',gyro_stabilizer='Gyro Stabilizer',electroshield='Electroshield',titanium_hull='Titanium Hull'}
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
  if b.down or b.finished then for slot,o in pairs(a.mounts)do o:remove();a.mounts[slot]=nil end;a.arm_motion=nil;a.reach_queue=nil;return end
  R.normalize(b);local desired={weapon=(not b.scripted or b.kind=='sentry')and b.weapon or nil}
  for _,kind in ipairs(equipment)do if b.parts and (b.parts[kind]or 0)>0 then desired[kind]=kind end end
  for slot,kind in pairs(desired)do
   local o=a.mounts[slot]
   if not o then o=spawn('mount_'..kind,actor:get_pos(),{pointable=false});a.mounts[slot]=o end
   if o then local e=o:get_luaentity();e.system_parent=actor;e.system_slot=slot;e.system_kind=kind;Net.properties(o,{mesh='sc_mount_'..kind..'.obj',use_texture_alpha=true,textures={'sc_surface_mount_'..kind..'.png'..(b.ghost and '^[opacity:150'or '')}})
    if actor.get_observers and o.set_observers then o:set_observers(actor:get_observers())end
   end
  end
  for slot,o in pairs(a.mounts)do if not desired[slot]and not (desired.mechanical_arm and (slot=='arm_a'or slot=='arm_b'or slot=='claw'or slot=='finger_left'or slot=='finger_right'))then o:remove();a.mounts[slot]=nil end end
  if desired.mechanical_arm then for _,slot in ipairs({'arm_a','arm_b','claw','finger_left','finger_right'})do
   if not a.mounts[slot]then local o=spawn(slot=='claw'and 'arm_claw'or (slot:find('finger',1,true)and 'arm_finger'or 'arm_link'),actor:get_pos(),{pointable=false,is_visible=false});a.mounts[slot]=o;local e=o:get_luaentity();e.system_parent=actor;e.system_slot=slot;e.system_kind=slot end
   local o=a.mounts[slot];Net.properties(o,{use_texture_alpha=true,textures={(slot=='claw'and 'sc_surface_arm_claw.png'or (slot:find('finger',1,true)and 'sc_surface_arm_finger.png'or 'sc_surface_arm_link.png'))..(b.ghost and '^[opacity:150'or '')}});if actor.get_observers and o.set_observers then o:set_observers(actor:get_observers())end
  end end
  for _,o in pairs(a.mounts)do V.step(o:get_luaentity(),0)end
 end
 function V.reach(actor,target)
  if not actor then return end;local e=actor:get_luaentity();e.reach_queue=e.reach_queue or {};e.reach_queue[#e.reach_queue+1]=target
 end
 function V.fire(actor,slot)
  local e=actor and actor:get_luaentity();local o=e and e.mounts and e.mounts[slot];if o then o:get_luaentity().flash=.4 end
 end
 function V.tick_actor(e,dt)
  if not e.arm_motion and e.reach_queue and #e.reach_queue>0 then e.arm_motion={target=table.remove(e.reach_queue,1),elapsed=0}end
  if e.arm_motion then e.arm_motion.elapsed=e.arm_motion.elapsed+dt;if e.arm_motion.elapsed>=Arm.duration then e.arm_motion=nil end end
 end
 local function attach_piece(o,actor,p,rotation)
  local e=o:get_luaentity();local pose={p.x*10,p.y*10,p.z*10,-rotation.x*180/math.pi,-rotation.y*180/math.pi}
  local old=e.arm_pose;local changed=not old
  if old then for i=1,5 do if math.abs(old[i]-pose[i])>.0001 then changed=true end end end
  if changed then o:set_attach(actor,'',{x=pose[1],y=pose[2],z=pose[3]},{x=pose[4],y=pose[5],z=0},true);e.arm_pose=pose end
 end
 local function link(o,a,b,scale,actor)
  local dx,dy,dz=b.x-a.x,b.y-a.y,b.z-a.z;local h=math.sqrt(dx*dx+dz*dz);local length=math.sqrt(h*h+dy*dy)
  local rotation={x=atan2(dy,h),y=-atan2(dx,dz),z=0}
  if actor then attach_piece(o,actor,a,rotation)else o:set_rotation(rotation);Net.move(o,a,0)end
  Net.properties(o,{is_visible=length>.01,visual_size={x=scale,y=scale,z=length}})
 end
 function V.step(e,dt)
  local actor=e.system_parent;local p=actor and actor:get_pos();if not p then e.object:remove();return end
  local a=actor:get_luaentity();local b=a.system_bot;local scale=a.display_scale or 1
  if not b or b.down or b.finished or a.fallen then Net.properties(e.object,{is_visible=false});return end
  local slot=e.system_slot;e.clock=(e.clock or 0)+dt;e.flash=math.max(0,(e.flash or 0)-dt)
  if slot=='arm_a'or slot=='arm_b'or slot=='claw'or slot=='finger_left'or slot=='finger_right'then
   local attached=e.object.set_attach~=nil;local origin,yaw,motion=p,actor:get_yaw(),a.arm_motion
   if attached then
    -- Solve the articulated arm in robot-local space, so every piece shares
    -- the client's interpolated body pose. Only the reach target is world-fixed.
    if motion then
     local dx,dz=motion.target.x-p.x,motion.target.z-p.z
     motion={elapsed=motion.elapsed,target={x=math.cos(yaw)*dx+math.sin(yaw)*dz,y=motion.target.y-p.y,z=-math.sin(yaw)*dx+math.cos(yaw)*dz}}
    end
    origin={x=0,y=0,z=0};yaw=0
   end
   local root,elbow,tip,spread=Arm.pose(origin,yaw,scale,motion)
   if slot=='arm_a'then link(e.object,root,elbow,scale,attached and actor)
   elseif slot=='arm_b'then link(e.object,elbow,tip,scale,attached and actor)
   else
    local side=slot=='finger_left'and -spread or (slot=='finger_right'and spread or 0)
    local location={x=tip.x+math.cos(yaw)*side,y=tip.y,z=tip.z+math.sin(yaw)*side}
    if attached then attach_piece(e.object,actor,location,{x=0,y=0})else e.object:set_yaw(yaw);Net.move(e.object,location,0)end
    Net.properties(e.object,{is_visible=true,visual_size={x=scale,y=scale,z=scale}})
   end;return
  end
  local body=actor:get_yaw();local side,back,height=0,0,1.05
  if slot=='weapon'then side=0;back=.05
  elseif slot=='battering_ram'then height=-.12;back=.58;if e.ram_serial~=b.ram_serial then e.ram_serial=b.ram_serial;e.flash=.4 end
  elseif slot=='turret_gearbox'then height=.88
  elseif slot=='mechanical_arm'then height=1.48;back=-.18
  elseif slot=='electromagnetic_brake'then height=-.32;back=-.35;if e.brake_serial~=b.brake_serial then e.brake_serial=b.brake_serial;e.flash=.4 end elseif slot=='hard_disk'then side=-.4;back=-.16
  elseif slot=='thermal_camera'then side=.3;back=.3;height=.98
  elseif slot=='holographic_memory'then back=-.35 elseif slot=='gyro_stabilizer'then height=.91
  elseif slot=='electroshield'then side=.32;back=-.35 elseif slot=='titanium_hull'then side=-.32;back=-.35 end
  if e.flash>0 then back=back-.1*math.sin(e.flash/.4*math.pi)end
  -- Body motion belongs to the parent. Only independent aiming is eased.
  local relative=0
  if slot=='weapon'or slot=='thermal_camera'then
   local target=G.yaw((R.aim(b)-b.dir)%4);local old=e.aim_relative or target
   local delta=(target-old+math.pi)%(2*math.pi)-math.pi
   e.aim_relative=old+delta*math.min(1,dt*12);relative=e.aim_relative
  elseif slot=='gyro_stabilizer'then relative=e.clock*.7 end
  local enabled=(slot=='mechanical_arm'or slot=='thermal_camera'or slot=='titanium_hull')or not (b.enabled and b.enabled[slot]==false);if slot=='gyro_stabilizer'then enabled=R.gyro(b)end
  local size=scale*(slot=='turret_gearbox'and .55 or 1)
  if e.object.set_attach then
   local pose={side*scale*10,height*scale*10,back*scale*10,-relative*180/math.pi}
   local old=e.mount_pose;local changed=not old
   if old then for i=1,4 do if math.abs(old[i]-pose[i])>.0001 then changed=true end end end
   if changed then
    e.object:set_attach(actor,'',{x=pose[1],y=pose[2],z=pose[3]},{x=0,y=pose[4],z=0},true)
    e.mount_pose=pose
   end
  else
   -- Lightweight test adapters without the engine attachment API.
   local dx=math.cos(body)*side-math.sin(body)*back;local dz=math.sin(body)*side+math.cos(body)*back
   Net.move(e.object,{x=p.x+dx*scale,y=p.y+height*scale,z=p.z+dz*scale},0)
   e.object:set_yaw(body+relative)
  end
  Net.properties(e.object,{is_visible=true,visual_size={x=size,y=size,z=size},glow=e.flash>0 and 12 or (enabled and 3 or 0)})

 end
 return V
end
