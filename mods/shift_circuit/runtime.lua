return function(core, options)
 local MenuUI=dofile(core.get_modpath('shift_circuit')..'/menu_ui.lua');core=MenuUI.wrap(core)
options=options or {}
local origin=options.origin or {x=0,y=0,z=0}
local function world(p) return {x=p.x+origin.x,y=p.y+origin.y,z=p.z+origin.z} end
local path=core.get_modpath('shift_circuit')
local Net=dofile(path..'/network_updates.lua')
local Active=dofile(path..'/arena_active.lua')(core)
local RaceHUD=dofile(path..'/race_hud.lua');local Goal=dofile(path..'/goals.lua');local Q=dofile(path..'/courses.lua');local R=dofile(path..'/rules.lua');local C=dofile(path..'/campaign.lua');local store=core.get_mod_storage()
local Loadout=dofile(path..'/dashboard_ui.lua')(core,R)
local P=dofile(path..'/particles.lua')(core);local A=dofile(path..'/asset_textures.lua');local G=dofile(path..'/geometry.lua');local I=dofile(path..'/inspection.lua')
local S=C.setup(R,1,'campaign',options.board); local phase='loading';local slot,timer=0,0
local players,robots,props,belts,presses,pushers,rotors,pickups={},{},{},{},{},{},{},{}
local Systems;local Health;local visual;local spawn_robot;local spawn_pickup;local planning_left;local host;local duration=.85;local start_match,menu,refresh,build,refresh_menu,follow_camera,restore_cameras
local command_queue={}
local Batches=dofile(path..'/command_batches.lua')(R)
local function command_batch()
 local batch;batch,command_queue=Batches.take(S,command_queue,slot)
 S.executing=batch[1]and batch[1].id;S.executing_count=#batch
 for _,b in ipairs(batch)do R.command(S,b,b.program[slot]or 'WAIT');R.ghosts(S)end
 return #batch>0
end
local phase_times={direction_reading=.45,direction=.65,reading=.45,commands=.55,express=1.05,belts=1.05,pushers=1.05,rotators=.8,weapons=.65,lasers=.65,presses=.75}
local execution_speed,destruction_pause=1,0
local PROGRAM_SECONDS=90
local function programming_seconds()return PROGRAM_SECONDS*((S.round or 1)==1 and 2 or 1)end
local function destroyed_puzzle_player()
 if S.mode~='puzzle'or not phase_times[phase]then return false end
 local destroyed=false;for _,b in ipairs(S.bots)do if not b.enemy and not b.finished then if not b.down then return false end;destroyed=true end end;return destroyed
end
local function card_image(command)
 return 'sc_card_'..command..'.png'
end
local function priority_label(id)
 if not id or id<=0 then return ''end
 local digits=string.format('%03d',id);local label='[combine:48x16:0,0=sc_priority_p.png'
 for i=1,#digits do label=label..':'..(i*12)..',0=sc_priority_'..digits:sub(i,i)..'.png'end
 return label
end
local function phase_time() return phase_times[phase] or .65 end
local home_markers={}
local preview_beams={};local preview_clock,preview_refresh=0,0
local function inspecting() return phase=='editor' or phase=='program' or phase=='lobby' or phase=='finished' end
local colors={'#5ee2cc','#f2bc63','#bba1f2','#8cbcff'}
local function pos(x,z,y) return world({x=x*2+.5,y=y or 1,z=z*2+.5}) end
local function orbit_position(p,angle)
 local dx,dz=math.sin(angle),-math.cos(angle);local radius=8
 for _,a in ipairs({{p.x,dx,origin.x-5,origin.x+S.size*2+7},{p.z,dz,origin.z-5,origin.z+S.size*2+7}})do
  if a[2]>.001 then radius=math.min(radius,(a[4]-a[1])/a[2])elseif a[2]<-.001 then radius=math.min(radius,(a[3]-a[1])/a[2])end
 end
 radius=math.max(.5,radius);return {x=p.x+dx*radius,y=p.y+8,z=p.z+dz*radius},radius
end
local function sound(kind,p,gain,pitch) if core.sound_play then core.sound_play('sc_'..kind,{pos=p,gain=gain or .45,pitch=pitch or 1,max_hear_distance=35},true) end end
local function bot(name) for _,b in ipairs(S.bots) do if b.id==name then return b end end end
local function spectating(name)
 local b=bot(name)
 return (options.is_spectator and options.is_spectator(name))or (b and b.finished)or false
end
local function watched_bot(name)
 if not spectating(name)then return bot(name)end
 local v=players[name];if not v then return end
 local b=v.watched and bot(v.watched)
 if b and not b.finished then return b end
 for _,q in ipairs(S.bots)do if not q.finished and not q.enemy then v.watched=q.id;return q end end
 for _,q in ipairs(S.bots)do if not q.finished then v.watched=q.id;return q end end
 v.watched=nil
end
local Styles=dofile(path..'/robot_styles.lua')
local NearbyLabels=dofile(path..'/nearby_labels.lua')
local WorldTagOrder=dofile(path..'/world_tag_order.lua')
local ScheduleBadges=dofile(path..'/schedule_badges.lua')
local function robot_texture(b,down)
 local base='sc_surface_'..Styles.model(b)..'.png'
 return base..(down and '^[multiply:#694e4b' or (b.racing and '^[multiply:#8cbcff' or (b.enemy and '^[multiply:#ef8c85' or '')))..(b.ghost and not down and '^[opacity:150'or '')
end
local function humans(include_finished) local a={};for _,b in ipairs(S.bots) do if not b.enemy and (include_finished or not b.finished) then a[#a+1]=b end end;return a end
local function timed_program()return options.multiplayer or #humans()>=2 end
local function node(n,def) def.diggable=false;def.groups={unbreakable=1};core.register_node('shift_circuit:'..n,def) end
for _,n in ipairs({'apron','beam','pit','light'}) do node(n,{description=n,tiles={'sc_'..n..'.png'},light_source=n=='light' and 12 or 0}) end
node('collider',{description='Tile support',light_source=12,drawtype='airlike',pointable=false,walkable=true,paramtype='light',sunlight_propagates=true})
for _,kind in ipairs({'deck','dock1','dock2','dock3'}) do for dx=0,1 do for dz=0,1 do
  node(kind..dx..dz,{description='Factory surface',tiles={'sc_'..kind..dx..dz..'.png','sc_beam.png','sc_beam.png'},light_source=kind~='deck' and 4 or 0})
end end end
core.register_entity('shift_circuit:visual',{
 initial_properties={physical=false,pointable=false,visual='mesh',mesh='sc_robot.obj',textures={'sc_materials.png'},static_save=false,glow=0},
 on_step=function(self,dt)
   if self.health_actor then Health.step(self);return end
   if self.ghost_actor then
    local actor=self.ghost_actor;local base=actor:get_pos()
    if not base then self.object:remove();return end
    local tip=self.ghost_tip;local dx,dy,dz=base.x-tip.x,base.y-.25-tip.y,base.z-tip.z
    local length=math.sqrt(dx*dx+dy*dy+dz*dz)
    local rotation={x=math.atan2(dy,math.sqrt(dx*dx+dz*dz)),y=-math.atan2(dx,dz),z=0}
    local rotated=not Net.equal(self.ghost_rotation,rotation)
    if rotated then self.object:set_rotation(rotation);self.ghost_rotation=rotation end
    Net.properties(self.object,{visual_size={x=.8,y=.8,z=math.max(.01,length)}})
    -- Publish the new rotation with the positional update, including a fixed tip.
    -- Sending position first can leave a stationary marker at its old rotation.
    if rotated then self.object:set_pos(tip)else Net.move(self.object,tip,0)end
    return
   end
   if not self.fall then dt=dt*execution_speed end
   if self.hatch then local h=self.hatch;h.amount=h.amount+(h.goal-h.amount)*math.min(1,dt*7);Net.properties(self.object,{visual_size={x=1,y=1,z=math.max(.03,1-h.amount)}});Net.move(self.object,{x=h.origin.x,y=h.origin.y-h.amount*.45,z=h.origin.z-h.amount*.92})end
   if self.ray_wave then local w=self.ray_wave;w.elapsed=w.elapsed+dt;local t=(w.elapsed/.65+w.offset)%1;if w.kind=='tractor_beam'then t=1-t end;self.object:set_pos({x=w.origin.x+w.dir.x*w.length*t,y=w.origin.y,z=w.origin.z+w.dir.z*w.length*t});local size=w.kind=='remote_control'and .7 or (.6+.6*t);Net.properties(self.object,{visual_size={x=size,y=size,z=size}})end
   if self.system_parent then Systems.step(self,dt);return end
   if self.system_actor then Systems.tick_actor(self,dt)end
   if self.life then self.life=self.life-dt;if self.life<=0 then self.object:remove();return end end
   if self.fall then
    local f=self.fall;f.elapsed=math.min(1,f.elapsed+dt);local slide=math.min(1,f.elapsed/.25);slide=slide*slide*(3-2*slide)
    local drop=math.max(0,(f.elapsed-.18)/.82)
    Net.move(self.object,{x=f.from.x+(f.to.x-f.from.x)*slide,y=f.from.y+(f.to.y-f.from.y)*slide-5.5*drop*drop,z=f.from.z+(f.to.z-f.from.z)*slide})
    self.object:set_yaw(f.yaw+.35*drop)
    if f.elapsed>=1 then self.fall=nil;self.fallen=true;Net.properties(self.object,{is_visible=false,pointable=false})end
    return
   elseif self.fallen then return end
   if self.achievement then
     self.achievement=self.achievement+dt;local t=self.achievement/1.3
     if t>=1 then self.object:remove();return end
     Net.move(self.object,{x=self.origin.x,y=self.origin.y+1+t*1.5,z=self.origin.z});Net.properties(self.object,{visual_size={x=.8*(1-t*.65),y=.8*(1-t*.65)}});return
   end
   if self.collecting then
     local c=self.collecting
     if (c.delay or 0)>0 then c.delay=c.delay-dt;return end
     if not c.started then
       local rp=c.robot and c.robot:get_pos();local moving=c.robot and c.robot:get_luaentity().motion
       if rp and moving and ((rp.x-c.origin.x)^2+(rp.z-c.origin.z)^2)>1.3 then return end
       c.started=true;c.elapsed=0;sound('pickup',c.origin,.55);P.emit('pickup',c.origin)
     end
     c.elapsed=c.elapsed+dt;local t=math.min(1,c.elapsed/.65);local scale=math.max(.01,1-t)
     Net.move(self.object,{x=c.origin.x,y=c.origin.y+t*1.3,z=c.origin.z});Net.properties(self.object,{visual_size={x=scale,y=scale,z=scale}})
     if t>=1 then self.object:remove() end;return
   end
   if self.follow_object then
     local p=self.follow_object:get_pos()
     if p then
      local actor=self.follow_object:get_luaentity();if actor and (actor.fall or actor.fallen)then p.y=origin.y+1 end
      local angle=self.orbit_angle or 0;local delta=((self.orbit_target or angle)-angle+math.pi)%(math.pi*2)-math.pi
      if math.abs(delta)>.001 then angle=angle+delta*math.min(1,dt*9);self.orbit_angle=angle end
      local location,radius=orbit_position(p,angle);self.object:move_to(location,true)
      local viewer=self.orbit_owner and core.get_player_by_name(self.orbit_owner)
      if viewer and math.abs(delta)>.001 then viewer:set_look_horizontal(angle);viewer:set_look_vertical(math.atan(8/radius))end
     end
   elseif self.client_tread then
     local active=inspecting() or phase=='belts' or (phase=='express' and self.speed==2)
     local rate=active and 24*10/duration*(self.speed or 1)*(inspecting() and .5 or 1)*execution_speed or 0
     if rate~=self.tread_rate then self.object:set_animation_frame_speed(rate);self.tread_rate=rate end
     if active then self.travel=(self.travel+dt/duration*(self.speed or 1)*(inspecting() and .5 or 1))%1 end
   elseif self.belt and (inspecting() or phase=='belts' or (phase=='express' and self.speed==2)) then
     self.travel=(self.travel+dt/duration*(self.speed or 1)*(inspecting() and .5 or 1))%1
     if self.curve_model then
       local frame=math.floor((self.travel*10)%1*24);if frame~=self.frame then self.frame=frame;Net.properties(self.object,{mesh='sc_tread_'..self.curve_model..'_'..frame..'.obj'}) end
     else
       local q,yaw=G.belt(self.track,self.travel)
       Net.move(self.object,{x=self.origin.x+q.x,y=self.origin.y,z=self.origin.z+q.z},.5);self.object:set_yaw(yaw)
     end
   elseif self.hover then
     if self.pickup_motion then local m=self.pickup_motion;m.elapsed=math.min(m.total,m.elapsed+dt);local a=m.elapsed/m.total;a=a*a*(3-2*a);self.origin=vector.add(m.from,vector.multiply(vector.subtract(m.to,m.from),a));if m.elapsed>=m.total then self.pickup_motion=nil end end
     self.clock=(self.clock or 0)+dt*(inspecting() and .5 or 1);local p=vector.new(self.origin);p.y=p.y+math.sin(self.clock*2)*.12;Net.move(self.object,p);self.object:set_yaw(self.clock*.7)
   elseif self.hydraulic_motion then
     local m=self.hydraulic_motion;m.elapsed=math.min(m.delay+m.total,m.elapsed+dt)
     local a=math.max(0,(m.elapsed-m.delay)/m.total);a=a*a*(3-2*a)
     Net.move(self.object,vector.add(m.from,vector.multiply(vector.subtract(m.to,m.from),a)),0)
     if m.elapsed>=m.delay+m.total then
       self.hydraulic_motion=nil
       if m.impact then sound('pusher_stop',m.to,.42,execution_speed)end
     end
   elseif self.motion then
     local m=self.motion;m.elapsed=math.min(m.total,m.elapsed+dt);local t=m.elapsed/m.total;t=t*t*(3-2*t)
     Net.move(self.object,vector.add(m.from,vector.multiply(vector.subtract(m.to,m.from),t)));if m.elapsed>=m.total then self.motion=nil end
   elseif self.target then
     local nextpos=vector.add(self.object:get_pos(),vector.multiply(vector.subtract(self.target,self.object:get_pos()),math.min(1,dt*9)))
     -- Size updates are immediate on clients. Keep linked plates and rods on
     -- the same eased pose, rather than interpolating the plate a second time.
     if self.pusher_rod or self.hydraulic_rod then Net.move(self.object,nextpos,0)else Net.move(self.object,nextpos)end
   end
   if self.pusher_rod then local anchor,length=G.pusher_rod(self.pusher_base,self.object:get_pos(),self.pusher_dir);Net.move(self.pusher_rod,anchor,0);Net.properties(self.pusher_rod,{visual_size={x=1,y=1,z=length}})end
   if self.hydraulic_rod then local anchor,length=G.crusher_rod(self.object:get_pos(),self.hydraulic_ceiling);Net.move(self.hydraulic_rod,anchor,0);Net.properties(self.hydraulic_rod,{visual_size={x=1,y=length,z=1}})end
   if self.conveyor_turn then
    local turn=self.conveyor_turn;turn.elapsed=math.min(turn.total,turn.elapsed+dt)
    self.object:set_yaw(G.conveyor_yaw(turn.from,turn.to,turn.elapsed/turn.total))
    if turn.sound and turn.elapsed/turn.total>=.35 then sound('turn',self.object:get_pos(),.18,.9);turn.sound=nil end
    if turn.elapsed>=turn.total then self.conveyor_turn=nil end
   elseif self.yaw then local a=self.object:get_yaw();local diff=(self.yaw-a+math.pi)%(math.pi*2)-math.pi;self.object:set_yaw(a+diff*math.min(1,dt*(self.robot and 3 or 10))) end
 end,
})

visual=function(mesh,p,extra)
 local o=core.add_entity(p,'shift_circuit:visual');if not o then return end
 Net.properties(o,{mesh='sc_'..mesh..'.obj',textures={A[mesh] or 'sc_materials.png'}});if extra then if extra.nametag and extra.nametag~=''then o:get_luaentity().nearby_label={text=extra.nametag,range=8,color=tonumber((extra.nametag_color or '#94e3cf'):sub(2),16)};extra.nametag=''end;Net.properties(o,extra) end;props[#props+1]=o;return o
end
G.arm=dofile(path..'/arm_pose.lua')
Systems=dofile(path..'/systems_visual.lua')(R,G,visual,Net)
Health=dofile(path..'/robot_health.lua')(visual,Net)
local function clear_preview() for _,o in ipairs(preview_beams) do if o:get_pos() then o:remove() end end;preview_beams={};preview_refresh=0 end
local element_objects={};local edge_version=0
local function cleanup() Active.release();element_objects={};edge_version=0;home_markers={};clear_preview();for _,o in ipairs(props) do if o:get_pos() then o:remove() end end;props={};robots={};belts={};presses={};pushers={};rotors={};pickups={} end
-- Fixed stroke durations keep plate, rod and hydraulic audio on the same clock.
local function piston_stroke(object,target,extending)
 local e=object and object:get_luaentity();local from=object and object:get_pos()
 if not e or not from then return end
 e.target=nil;e.motion=nil
 e.hydraulic_motion={from=from,to=target,elapsed=0,delay=extending and .16 or 0,total=extending and .55 or .50,impact=extending}
 sound(extending and 'pusher' or 'pusher_return',from,extending and .48 or .3,execution_speed)
end
local function conveyor_sound(express)
 -- One emitter per small belt cluster avoids overlapping a sound per tile.
 local groups={}
 for z=1,S.size do for x=1,S.size do local t=R.tile(S,x,z)
  if t.kind=='belt'and(not express or t.speed==2)then
   local key=math.floor((x-1)/6)..':'..math.floor((z-1)/6)
   local g=groups[key]or{x=0,z=0,n=0};groups[key]=g;g.x=g.x+x;g.z=g.z+z;g.n=g.n+1
  end
 end end
 for _,g in pairs(groups)do sound('conveyor',pos(g.x/g.n,g.z/g.n),.13,execution_speed)end
end
local function machine_pose(object,field,value)local e=object and object:get_luaentity();if e then e[field]=value end end
local function inspect_animation(dt)
 preview_clock=preview_clock+dt;preview_refresh=preview_refresh+dt
 local stroke=(1-math.cos(preview_clock*math.pi/duration))*.25
 for _,p in ipairs(presses) do local e=p.o:get_luaentity();if e then e.target=pos(p.x,p.z,4.3-stroke*3.3)end end
 for _,p in ipairs(pushers) do local e=p.o:get_luaentity();local d=R.dirs[p.q.dir+1];if e and d then e.target=vector.add(pos(p.q.x,p.q.z),{x=d.x*.9*stroke,y=0,z=d.z*.9*stroke})end end
 for _,r in ipairs(rotors) do local e=r.o:get_luaentity();if e then e.yaw=r.angle+preview_clock*(r.turn==3 and 1 or -1)*math.pi/(4*duration)end end
 if preview_refresh>=.3 or #preview_beams==0 then
   preview_refresh=0;local rays={};local index=0
   local board_preview=S
   if phase=='program'then
    -- Show the board hazard's path without temporary racer occupancy hiding it.
    board_preview={};for k,v in pairs(S)do board_preview[k]=v end;board_preview.bots={}
    for _,b in ipairs(S.bots)do if b.enemy and not b.racing then board_preview.bots[#board_preview.bots+1]=b end end
   end
   for _,q in ipairs(S.lasers or {}) do local x,z=R.laser_source(q);rays[#rays+1]={x=x,z=z,dir=q.dir,power=q.power,range=R.fixed_laser_range(S,q)}end
   for _,b in ipairs(S.bots)do if (S.round or 1)>1 and not b.down and not b.ghost and not b.finished and (not b.scripted or b.kind=='sentry')then R.normalize(b);for _,mount in ipairs({'weapon'})do local kind=b.weapon;if kind then rays[#rays+1]={x=b.x,z=b.z,dir=R.aim(b,mount),power=R.weapons[kind].power or 1,range=b.range or 4,owner=b,kind=kind,mount=mount}end end end end
   for _,q in ipairs(rays) do
     local length,_,wall=R.trace(q.owner and S or board_preview,q.x,q.z,q.dir,q.range or R.fixed_laser_range(S,q),q.owner);local d=R.dirs[q.dir+1]
     for i=1,q.power do
       local p,beam_length=G.beam(q.x,q.z,q.dir,q.power,i,length,q.owner~=nil,q.mount,q.kind,q.owner and q.owner.dir);if wall then beam_length=math.max(0,beam_length-.065)end;p=world(p)
       -- Preview entities are managed separately: no damage, shots, particles,
       -- or unbounded append to the scene's persistent object list.
       index=index+1;local o=preview_beams[index]
       if not o or not o:get_luaentity()then o=core.add_entity(p,'shift_circuit:visual');preview_beams[index]=o end
       if o then
         local tint=q.owner and (({emp_generator='#425e88',remote_control='#625078',tractor_beam='#356b80',repulsor_beam='#805932'})[q.kind]or '#327464')or '#804232';local e=o:get_luaentity()
         if e.preview_length~=length or e.preview_tint~=tint then Net.properties(o,{mesh='sc_beam.obj',visual_size={x=1,y=1,z=beam_length},glow=7,use_texture_alpha=true,backface_culling=true,textures={'sc_beam_alpha.png^[multiply:'..tint}});e.preview_length=length;e.preview_tint=tint end
         o:set_pos(p);o:set_yaw(G.yaw(q.dir))
       end
     end
   end
   for i=#preview_beams,index+1,-1 do preview_beams[i]:remove();preview_beams[i]=nil end
 end
end
local function shots()
 for _,s in ipairs(S.shots or {}) do
   if s.owner then local actor=robots[s.owner];Systems.fire(actor,s.mount);if actor and actor:get_luaentity().owner_view then Systems.fire(actor:get_luaentity().owner_view,s.mount)end end
   sound('laser',pos(s.x,s.z),s.weapon and .25 or .4,s.kind=='emp_generator'and .65 or s.weapon and 1.15 or 1)
   local d=R.dirs[s.dir+1];local power=s.power or 1
   for i=1,power do
     local p,beam_length=G.beam(s.x,s.z,s.dir,power,i,s.range,s.weapon==true,s.mount,s.kind,s.body_dir);if s.wall then beam_length=math.max(0,beam_length-.065)end;p=world(p)
     local o=visual('beam',p,{visual_size={x=1,y=1,z=beam_length},glow=14,use_texture_alpha=true,backface_culling=true,textures={'sc_beam_alpha.png^[multiply:'..(s.weapon and (({emp_generator='#72aaff',remote_control='#be9cf5',tractor_beam='#66d9ff',repulsor_beam='#ffb466'})[s.kind]or '#64e8c8')or '#ff8464')}})
     o:set_yaw(G.yaw(s.dir));o:get_luaentity().life=.65
     local tip={x=p.x+d.x*beam_length,y=p.y,z=p.z+d.z*beam_length}
     if s.hit then P.emit(({emp_generator='control',remote_control='control',tractor_beam='pull',repulsor_beam='push'})[s.kind]or 'impact',tip)end
     if s.kind and not R.weapons[s.kind].power then
      for j=0,3 do local wave=visual(s.kind=='remote_control'and 'ray_packet'or 'ray_ring',p,{pointable=false,glow=10,use_texture_alpha=true,textures={'sc_beam_alpha.png^[multiply:'..(({emp_generator='#72aaff',remote_control='#be9cf5',tractor_beam='#66d9ff',repulsor_beam='#ffb466'})[s.kind])}});wave:set_yaw(G.yaw(s.dir));wave:get_luaentity().life=.65;wave:get_luaentity().ray_wave={origin=p,dir=d,length=beam_length,kind=s.kind,offset=j/4,elapsed=0}end
     end
   end
 end
 S.shots={}
end
local function sync_fall(b,o)
 if not o then return end;local e=o:get_luaentity()
 local rebooted=e.pose_down and not b.down;e.pose_down=not not b.down
 if b.down then e.conveyor_turn=nil end
 if rebooted then
  e.fall=nil;e.fallen=nil;e.motion=nil;e.target=nil;e.conveyor_turn=nil
  e.yaw=G.yaw(b.dir);o:set_yaw(e.yaw)
  if o.set_velocity then o:set_velocity({x=0,y=0,z=0})end
  if o.set_acceleration then o:set_acceleration({x=0,y=0,z=0})end
  o:set_pos(e.destination or pos(b.x,b.z,1))
  local scale=e.display_scale or 1
  Net.properties(o,{is_visible=not b.finished,pointable=true,visual_size={x=scale,y=scale,z=scale},textures={robot_texture(b,false)}})
 end
 if b.down and b.destroyed_by=='Fell into a pit'then
  if not e.fall and not e.fallen then e.fall={from=o:get_pos(),to=pos(b.x,b.z,1),elapsed=0,yaw=o:get_yaw()}end
  e.motion=nil;e.target=nil;e.yaw=nil
  local scale=e.display_scale or 1;Net.properties(o,{is_visible=not e.fallen,pointable=false,nametag='',textures={robot_texture(b,false)},visual_size={x=scale,y=scale,z=scale}})
 elseif e.fall or e.fallen then
  e.fall=nil;e.fallen=nil;e.motion=nil;e.target=nil;e.destination=e.destination or pos(b.x,b.z,1);o:set_pos(e.destination)
  local scale=e.display_scale or 1;Net.properties(o,{is_visible=not b.finished,pointable=true,visual_size={x=scale,y=scale,z=scale},textures={robot_texture(b,false)}})
 end
 if not b.down then Net.properties(o,{is_visible=not b.finished})end
end
local function sync_elements()
 if edge_version~=(S.geometry_serial or 0)then
  edge_version=S.geometry_serial or 0;local keep={};for _,o in ipairs(props)do if o:get_pos()then if o:get_luaentity().pit_edge then o:remove()else keep[#keep+1]=o end end end;props=keep
  for _,edge in ipairs(G.pit_edges(S,R))do local o=visual('pit_edge_'..edge.corners,world(edge),{textures={'sc_pit_edge.png'},backface_culling=false});o:set_yaw(G.yaw(edge.dir));o:get_luaentity().pit_edge=true end
 end
 for _,id in ipairs(S.factory_events or {})do local c=S.crates[id];if c then element_objects['crate:'..id]=visual('crate_'..c.kind,pos(c.spawn_from.x,c.spawn_from.z));sound('pusher',pos(c.spawn_from.x,c.spawn_from.z),.2)end end;S.factory_events={}
 for key,t in pairs(S.board)do if t.kind=='factory'then
  local x,z=key:match('^(%d+),(%d+)$');x,z=tonumber(x),tonumber(z);local id='factory:'..key;local o=element_objects[id]
  if not o then o=visual('factory_'..t.pattern,pos(x,z),{textures={'sc_surface_factory_'..t.crate_kind..'.png'}});o:set_yaw(G.yaw(t.dir));element_objects[id]=o;o:get_luaentity().lamps={}
   for _,offset in ipairs(R.factory_patterns[t.pattern])do local dir=(t.dir+offset)%4;local d=R.dirs[dir+1];local p=pos(x,z,2.12);p.x=p.x+d.x*.83;p.z=p.z+d.z*.83;local lamp=visual('factory_lamp',p);lamp:set_yaw(G.yaw(dir));o:get_luaentity().lamps[dir]=lamp end
  end
  local jammed=t.jammed and next(t.jammed)~=nil;local title=(t.crate_kind=='steel'and 'Steel Crate Factory'or 'Loot Crate Factory')
  o:get_luaentity().nearby_label={text=jammed and 'JAMMED'or '',range=10,color=0xf18574};Net.properties(o,{nametag=''})
  I.describe(o,title,(jammed and 'Blocked outlets jammed. 'or '')..'Every round during pushers: produces one or two crates total across clear outlets. Pushes crate chains; robots and walls block output.',{-.92,-.5,-.92,.92,1.1,.92})
  for dir,lamp in pairs(o:get_luaentity().lamps)do local blocked=t.jammed and t.jammed[dir];Net.properties(lamp,{textures={'sc_surface_factory_loot.png^[colorize:'..(blocked and '#ef6655'or '#71dec0')..':200'},glow=blocked and 8 or phase=='pushers'and slot==1 and R.factory_due(t,S.round or 1)and 12 or 3})end
 end end
 for key,c in pairs(S.crates or {})do
  local id='crate:'..key;local o=element_objects[id]
  if not c.down then
   if not o then o=visual('crate_'..c.kind,pos(c.x,c.z));element_objects[id]=o end
   Net.properties(o,{mesh='sc_crate_'..c.kind..'.obj',textures={A['crate_'..c.kind]},glow=0});o:get_luaentity().target=pos(c.x,c.z)
   I.describe(o,c.kind=='steel'and 'Steel Crate'or 'Loot Crate',c.kind=='steel'and 'Blocks rays. Push into a pit to fill it. Crushing converts it to loot.'or ((c.hp or 3)..' shots remaining / Hidden contents / Pushable'),{-.75,-.5,-.75,.75,.75,.75})
   if c.kind=='loot'then Health.sync(c,o)end
   if o:get_luaentity().crate_hit~=c.hit_serial then o:get_luaentity().crate_hit=c.hit_serial;Net.properties(o,{glow=12});P.emit('impact',pos(c.x,c.z));sound('impact',pos(c.x,c.z),.25)end
  elseif o then if o:get_luaentity().health_bar then Health.step(o:get_luaentity().health_bar:get_luaentity())end;P.emit(c.filled and 'fall'or 'destroy',pos(c.x,c.z));o:get_luaentity().life=.35;o:get_luaentity().target=pos(c.x,c.z,c.filled and -1 or 1);Net.properties(o,{pointable=false,visual_size={x=.6,y=.6,z=.6}});element_objects[id]=nil end
 end
 for key,t in pairs(S.board)do if t.kind=='trapdoor'or t.kind=='plate'or t.filled then
  local x,z=key:match('^(%d+),(%d+)$');x,z=tonumber(x),tonumber(z);local id='tile:'..key;local o=element_objects[id]
  local model=t.filled and 'tile'or t.kind
  if not o then o=visual(model,pos(x,z),{textures={t.filled and 'sc_tile_deck.png'or A[model]}});element_objects[id]=o end
  if t.filled then Net.properties(o,{mesh='sc_tile.obj',textures={'sc_tile_deck.png'},visual_size={x=1,y=1,z=1}});o:get_luaentity().hatch=nil;o:set_pos(pos(x,z))
  elseif t.kind=='trapdoor'then local e=o:get_luaentity();e.hatch=e.hatch or {origin=pos(x,z),amount=t.open and 1 or 0};local goal=t.open and 1 or 0;if e.hatch.goal~=nil and e.hatch.goal~=goal then P.emit('control',pos(x,z));sound('pusher',pos(x,z),.15)end;e.hatch.goal=goal;I.describe(o,'Trapdoor',t.open and 'OPEN / Pit. Adjacent occupied plates toggle after movement.'or 'CLOSED / Safe floor. Adjacent occupied plates toggle after movement.',{-1,-.5,-1,1,-.25,1})
  else o:get_luaentity().target=pos(x,z,t.pressed and .94 or 1);I.describe(o,'Pressure Plate','After all movement: toggles adjacent trapdoors once per register.',{-.85,-.5,-.85,.85,-.25,.85})end
  -- Trapdoors change robot rules and visuals, never the pilot's invisible floor.
 end end
end
local function sync()
 R.resolve_drops(S)
 sync_elements()
 for _,event in ipairs(S.spawn_events or {})do local x,z=event.key:match('(%d+),(%d+)');P.emit('pickup',pos(tonumber(x),tonumber(z)));sound('pickup',pos(tonumber(x),tonumber(z)),.18,.75)end;S.spawn_events={}
 R.ghosts(S)
 for _,b in ipairs(S.bots) do
   local o=robots[b.id]
   if o and not o:get_luaentity()and not b.finished then spawn_robot(b);o=robots[b.id]end
   if o and not o:get_luaentity()then o=nil end
   if o then
     local e=o:get_luaentity()
     if e.owner_view and not e.owner_view:get_luaentity()then e.owner_view=nil end
     if e.ghost_marker and not e.ghost_marker:get_luaentity()then e.ghost_marker=nil end
     local dest=pos(b.x,b.z,b.down and .7 or 1)
     Net.properties(o,{textures={robot_texture(b,b.down)},use_texture_alpha=true})
     local group={};for _,other in ipairs(S.bots)do if other.ghost and other.x==b.x and other.z==b.z then group[#group+1]=other.id end end;table.sort(group)
     local floating=b.ghost and #group>1
     if floating then
      local index=1;for i,id in ipairs(group)do if id==b.id then index=i end end
      local angle=(index-1)*2*math.pi/#group;dest.x=dest.x+math.cos(angle)*.9;dest.z=dest.z+math.sin(angle)*.9;dest.y=dest.y+3.0
      if not e.ghost_marker then e.ghost_marker=visual('ghost_cone',pos(b.x,b.z,1.05),{textures={'sc_ghost.png'},glow=5,pointable=false,use_texture_alpha=true})end
      local marker=e.ghost_marker:get_luaentity()
      marker.ghost_actor=o;marker.ghost_tip=pos(b.x,b.z,3.0)


     elseif e.ghost_marker then e.ghost_marker:remove();e.ghost_marker=nil end
     if o.set_observers then
      local observers,ground={},{ };for name in pairs(players)do
       local viewer=bot(name);local in_group=viewer and viewer.ghost and viewer.x==b.x and viewer.z==b.z
       local grounded=name==b.id or (floating and group[1]==b.id and not in_group)
       if grounded then ground[name]=true else observers[name]=true end
      end
      o:set_observers(observers);if e.ghost_marker then e.ghost_marker:set_observers(observers)end
      if next(ground)then
       local ownpos=pos(b.x,b.z,b.down and .7 or 1)
       if not e.owner_view then e.owner_view=visual(Styles.model(b),ownpos,{textures={robot_texture(b,b.down)},nametag=''});e.owner_view:set_observers({[b.id]=true});e.owner_view:get_luaentity().destination=ownpos end
       local own=e.owner_view;own:set_observers(ground);local oe=own:get_luaentity()
       if oe.destination.x~=ownpos.x or oe.destination.z~=ownpos.z or oe.destination.y~=ownpos.y then oe.motion={from=own:get_pos(),to=ownpos,elapsed=0,total=math.max(.35,phase_time()-.15)};oe.destination=ownpos end
       oe.yaw=G.yaw(b.dir);Net.properties(own,{use_texture_alpha=true,textures={robot_texture(b,b.down)},visual_size={x=1,y=b.down and .3 or 1,z=1}})
      elseif e.owner_view then e.owner_view:remove();e.owner_view=nil end
     end
     e.display_scale=floating and .5 or 1
     if e.floating~=not not floating then if floating then o:set_pos(dest);e.destination=vector.new(dest);e.motion=nil;e.target=nil end;e.floating=not not floating;Net.properties(o,{visual_size=floating and {x=.5,y=.5,z=.5}or{x=1,y=b.down and .3 or 1,z=1}})end
     if not e.destination or e.destination.x~=dest.x or e.destination.y~=dest.y or e.destination.z~=dest.z then
       if e.destination and not b.down then sound(b.last_action=='BLINK' and phase=='commands' and 'blink' or 'move',o:get_pos(),.25,b.last_action=='DASH' and 1.1 or (b.last_action=='BACK' and .9 or 1)) end
       if b.last_action=='BLINK' and phase=='commands' then P.emit('blink',o:get_pos());P.emit('blink',dest)end
       e.destination=dest;e.motion={from=o:get_pos(),to=dest,elapsed=0,total=math.max(.35,phase_time()-.15)};e.target=nil
     end
     if e.action_serial~=b.action_serial and b.action_serial then
       e.action_serial=b.action_serial
       if b.last_action=='LEFT' or b.last_action=='RIGHT' or b.last_action=='UTURN' then sound('turn',dest,.25)
       elseif b.last_action=='WAIT' then sound('ui_click',dest,.09,.8)
       elseif (b.last_action=='STEP' or b.last_action=='DASH' or b.last_action=='MOVE3' or b.last_action=='BACK2' or b.last_action=='BACK' or b.last_action=='BLINK') and not e.motion then sound('impact',dest,.18,.8)end
     end
     local belt_turn=(phase=='express'or phase=='belts')and e.last_dir and e.last_dir~=b.dir
     if belt_turn then
      local function turn(actor,play_sound)
       if not actor then return end;local ae=actor:get_luaentity()
       ae.conveyor_turn={from=actor:get_yaw(),to=G.yaw(b.dir),elapsed=0,total=ae.motion and ae.motion.total or math.max(.35,phase_time()-.15),sound=play_sound}
      end
      turn(o,true);turn(e.owner_view,false)
     elseif e.last_dir and e.last_dir~=b.dir and phase~='commands'then sound('turn',dest,.18,.9)end;e.last_dir=b.dir
     if e.last_shield and (b.shield or 0)<e.last_shield then sound('shield',dest,.4);P.emit('shield',dest)end;e.last_shield=b.shield or 0
     if e.electro_serial~=(b.electro_serial or 0)then if e.electro_serial then P.emit('shield',dest);sound('shield',dest,.4)end;e.electro_serial=b.electro_serial or 0 end
     if e.titanium_serial~=(b.titanium_serial or 0)then if e.titanium_serial then P.emit('armor',dest);sound('impact',dest,.55,.6)end;e.titanium_serial=b.titanium_serial or 0 end
     if e.last_hp and b.hp>e.last_hp then P.emit('repair',dest);sound('repair',dest,.4)end
     if e.last_hp and b.hp<e.last_hp and not b.down then sound('impact',dest,.55);P.emit('damage',dest) end;e.last_hp=b.hp
     if e.last_energy and b.energy and b.energy>e.last_energy and not b.down then sound('recharge',dest,.3)end;e.last_energy=b.energy
     local saved=(b.save_serial or 0)~=(e.last_save_serial or 0)
     if saved or (e.last_checkpoint and b.next>e.last_checkpoint)then
       if home_markers[b.id]then home_markers[b.id]:remove()end
       local markpos=pos(b.home.x,b.home.z,.72);markpos.x=markpos.x+.62
       local marker=visual('arrow_forward',markpos,{visual_size={x=.4,y=1,z=.4},glow=5,backface_culling=false});marker:get_luaentity().private_owner=b.id;marker:set_yaw(G.yaw(b.home.dir or 0));if marker.set_observers then marker:set_observers({[b.id]=true})else marker:set_properties({is_visible=false})end;home_markers[b.id]=marker
       I.describe(marker,'Reboot direction','Saved facing direction at this checkpoint.',{-.3,-.21,-.3,.3,-.17,.3})
       local badge=visual('tile',o:get_pos(),{visual='sprite',textures={saved and 'sc_save_achievement.png'or ('sc_checkpoint_'..math.min(S.checkpoint_count or 3,b.next-1)..'.png')},visual_size={x=.8,y=.8},glow=10})
       badge:get_luaentity().achievement=.001;badge:get_luaentity().origin=o:get_pos();sound('success',o:get_pos(),.4);P.emit('checkpoint',o:get_pos())
     end;e.last_checkpoint=b.next;e.last_save_serial=b.save_serial or 0
     e.yaw=G.yaw(b.dir)
     if e.was_down~=not not b.down then
       if e.was_down and not b.down then sound('blink',dest,.3,.85);P.emit('reboot',dest)end
       e.was_down=not not b.down
       Net.properties(o,{is_visible=true,visual_size=floating and {x=.5,y=.5,z=.5} or {x=1,y=b.down and .3 or 1,z=1},textures={robot_texture(b,b.down)},nametag='',nametag_color=b.down and '#ff7755' or '#94e3cf'})
       if b.down then
         local cue=b.destroyed_by=='CRUSHED by crusher'and 'destroy_crush'or b.destroyed_by=='Fell into a pit'and 'fall'or ({'destroy','destroy_electric','destroy_breakup'})[math.random(3)]
         sound(cue,dest,.55)
         P.emit(b.destroyed_by=='Fell into a pit'and 'fall'or (b.destroyed_by=='CRUSHED by crusher' and 'crush' or 'destroy'),dest)
       end
     end
   end
   if o then o:get_luaentity().nearby_label={text=b.scripted and (b.down and ''or (({sentry='Sentry',patroller='Patroller',ram_bot='Ram Bot'})[b.kind]or 'Enemy')..(b.winding and ' / CHARGING NEXT'or ''))or (b.down and ''or b.id),owner=b.id,persistent=not b.enemy or b.racing==true,range=b.scripted and 8 or 16,height=b.ghost and 1.1 or 2,color=b.winding and 0xefc264 or 0x94e3cf};Systems.sync(b,o);local cycle,cycle_hint=Health.cycle(b);o:get_luaentity().hint=b.scripted and (({sentry='Sentry / Turn clockwise, then fire.',patroller='Patroller / Forward, turn around if blocked or at a pit.',ram_bot='Ram Bot / Wind up on sight, charge 3 next register.'})[b.kind]..(cycle_hint and '\nCycle: '..cycle_hint or '')..'\nHull: '..b.hp..' / 3')or ((b.enemy and 'Robot: 'or 'Pilot: ')..b.id..'\n'..Systems.hint(b));if b.scripted then Net.properties(o,{glow=b.winding and 10 or 0})end;local own=o:get_luaentity().owner_view;if own then own:get_luaentity().display_scale=1;Systems.sync(b,own);own:get_luaentity().hint=o:get_luaentity().hint;Net.properties(own,{pointable=true,selectionbox={-.65,-.5,-.5,.65,1.7,.5}})end end
   if o then sync_fall(b,o);sync_fall(b,o:get_luaentity().owner_view)end
   if o and b.finished then Net.properties(o,{is_visible=false});local e=o:get_luaentity();if e.owner_view then Net.properties(e.owner_view,{is_visible=false})end end
   if o then Health.sync(b,o);Health.sync(b,o:get_luaentity().owner_view)end
   if b.collected then if players[b.id] then players[b.id].notice='COLLECTED / '..b.collected:upper() end;b.collected=nil end
 end
 local reach_delays={}
 for _,reach in ipairs(S.reaches or {})do local actor=robots[reach.robot];local target=pos(reach.x,reach.z,1.45)
  local e=actor and actor:get_luaentity();reach_delays[reach.robot..':'..R.key(reach.x,reach.z)]=G.arm.grasp+(e and #(e.reach_queue or {})or 0)*G.arm.duration
  Systems.reach(actor,target);if actor and actor:get_luaentity().owner_view then Systems.reach(actor:get_luaentity().owner_view,target)end;if reach.checkpoint then P.emit('checkpoint',target)end
 end;S.reaches={}
 for _,c in ipairs(S.collections or {}) do local o=pickups[c.key];if o then o:get_luaentity().collecting={origin=o:get_pos(),robot=robots[c.robot],delay=c.arm and (reach_delays[c.robot..':'..c.key]or .3)or 0};Net.properties(o,{pointable=false,nametag=''});pickups[c.key]=nil end end;S.collections={}
 -- Move existing entities before creating new pickups, preserving their identity across tiles.
 for _,batch in ipairs(S.pickup_moves or {})do
  local moving={};for i,q in ipairs(batch)do moving[i]=pickups[q.from];pickups[q.from]=nil end
  for i,q in ipairs(batch)do local o=moving[i];if o then local e=o:get_luaentity();if q.fall then
   e.hover=nil;e.motion={from=o:get_pos(),to=pos(q.x,q.z,-2),elapsed=0,total=.65};e.life=.7;Net.properties(o,{pointable=false,nametag=''});P.emit('fall',pos(q.x,q.z))
   else e.pickup_motion={from=vector.new(e.origin),to=pos(q.x,q.z,1.4),elapsed=0,total=.75};pickups[q.to]=o end
  end end
 end;S.pickup_moves={}
 for _,q in ipairs(S.pickup_losses or {})do local o=pickups[q.key];if o then local e=o:get_luaentity();local location=o:get_pos();e.hover=nil;Net.properties(o,{pointable=false,nametag=''})
  if q.cause=='fall'then e.motion={from=location,to={x=location.x,y=origin.y-2,z=location.z},elapsed=0,total=.65};e.life=.7;P.emit('fall',location)
  else P.emit('destroy',location);o:remove();sound('impact',location,.2)end;pickups[q.key]=nil
 end end;S.pickup_losses={}
 for _,drop in ipairs(S.drop_falls or {})do local key=R.key(drop.x,drop.z);local old=pickups[key];spawn_pickup(key,drop.kind);local o=pickups[key];pickups[key]=old;local e=o:get_luaentity();e.hover=nil;e.motion={from=o:get_pos(),to=pos(drop.x,drop.z,-2),elapsed=0,total=.65};e.life=.7;Net.properties(o,{pointable=false,nametag=''})end;S.drop_falls={}
 if spawn_pickup then for key,kind in pairs(S.pickups or {})do if not pickups[key]then spawn_pickup(key,kind)end end end
 shots()
end
local function camera(p,mode)
 local v=players[p:get_player_name()];v.camera=mode
 -- Native client prediction owns locomotion. Never stream set_pos corrections.
 local privs=core.get_player_privs(p:get_player_name());privs.fly=mode=='fly' or nil;core.set_player_privs(p:get_player_name(),privs)
 p:set_physics_override({speed=1.5,jump=1,gravity=1})
 if mode=='walk' then p:set_pos(world({x=12,y=1,z=-2}));p:set_look_horizontal(0);p:set_look_vertical(.12)
 else p:set_pos(world({x=12.5,y=18,z=-4}));p:set_look_horizontal(0);p:set_look_vertical(.8);v.notice='Use K to enter flight mode' end
end
follow_camera=function(p)
 local name=p:get_player_name();local v=players[name];if not v then return end
 local watched=watched_bot(name);if not watched and not spectating(name)then watched=humans()[1]end;local target=watched and robots[watched.id]
 if target and watched.id==name and target:get_luaentity().owner_view then target=target:get_luaentity().owner_view end
 if not target or not target:get_pos()then
  if spectating(name)and v.follow then p:set_detach();v.follow:remove();v.follow=nil;if v.return_view then p:set_fov(v.return_view.fov or 65,false,.35)end;v.return_view=nil end
  return
 end
 if v.follow and v.follow:get_pos()then v.follow:get_luaentity().follow_object=target;return end
 v.return_view={pos=vector.new(p:get_pos()),yaw=p:get_look_horizontal(),pitch=p:get_look_vertical(),fov=p:get_fov()}
 local angle=v.orbit_angle or 0;local location,radius=orbit_position(target:get_pos(),angle)
 local o=visual('robot',location,{is_visible=false})
 local e=o:get_luaentity();e.follow_object=target;e.orbit_owner=name;e.orbit_angle=angle;e.orbit_target=angle;v.follow=o
 p:set_attach(o,'',{x=0,y=0,z=0},{x=0,y=0,z=0});p:set_look_horizontal(angle);p:set_look_vertical(math.atan(8/radius));p:set_fov(60,false,.35)
end
restore_cameras=function(above_robot)
 for name,v in pairs(players) do
   if not (above_robot and spectating(name))then
   local p=core.get_player_by_name(name);local saved=v.return_view
   if saved and p then p:set_detach();local b=bot(name);if above_robot and b then p:set_pos(pos(b.x,b.z,7));p:set_look_vertical(math.pi/2)else p:set_pos(saved.pos);p:set_look_horizontal(saved.yaw);p:set_look_vertical(saved.pitch)end;p:set_fov(saved.fov or 65,false,.35)end
   if v.follow and v.follow:get_pos() then v.follow:remove() end
   v.return_view=nil;v.follow=nil
   end
 end
end
local Cards=dofile(path..'/card_text.lua');local card_names=Cards.names;local help=Cards.descriptions
local direction_cards={'FORWARD','LEFT','RIGHT','UTURN'}
local direction_help={FORWARD='Keep your starting facing.',LEFT='Face left from your starting direction.',RIGHT='Face right from your starting direction.',UTURN='Face backward from your starting direction.'}
local function direction_name(choice)return 'BLUE '..(choice=='UTURN'and 'U-TURN'or choice)end
local function inventory(p,b)
 local inv=p:get_inventory();inv:set_size('main',math.max(13,1+(b and #(b.hand or {})or 9)+(S.round==1 and 4 or 0)));local a={}
 if phase=='editor'then inv:set_list('main',{'shift_circuit:editor_brush','shift_circuit:editor_rotate'});p:hud_set_hotbar_itemcount(2);return end
 if spectating(p:get_player_name())then inv:set_list('main',{ItemStack('shift_circuit:orbit'),ItemStack('shift_circuit:spectate_switch')});p:hud_set_hotbar_itemcount(2);return end
 local v=players[p:get_player_name()];if v and v.follow and not inspecting()then inv:set_list('main',{ItemStack('shift_circuit:orbit')});p:hud_set_hotbar_itemcount(1);return end
 local commit=ItemStack('shift_circuit:commit');local state=b and b.ready and 'locked' or (b and phase=='program' and #(b.program or {})==5 and 'ready' or 'disabled')
 commit:get_meta():set_string('inventory_image','sc_commit_'..state..'.png')
 commit:get_meta():set_string('description',state=='ready' and 'COMMIT / Left-click to run your program' or (state=='locked' and 'COMMITTED / Waiting for execution' or 'COMMIT / Queue five cards first'))
 if phase=='lobby' then commit=ItemStack('shift_circuit:start');commit:get_meta():set_string('description','START GAME / Left-click to open the start menu') end
 a[1]=commit
 if b then for i,c in ipairs(b.hand or {}) do
   local used=false;for _,h in ipairs(b.selected or {}) do if h==i then used=true end end
   local stack=ItemStack('shift_circuit:card_'..c:lower());local m=stack:get_meta();m:set_int('index',i);m:set_string('inventory_image',card_image(c,(b.hand_ids or {})[i]))
   local description=Cards.tooltip(c)..'\nPriority ID '..((b.hand_ids or {})[i]or 0)..(used and ' / QUEUED' or ' / Left-click to queue')
   m:set_string('description',description)
   if used then m:set_string('inventory_image',card_image(c,(b.hand_ids or {})[i])..'^[multiply:#48535d')end
   for _,kept in ipairs(b.keep or {})do if kept==i then m:set_string('inventory_image',card_image(c,(b.hand_ids or {})[i])..'^sc_kept.png');m:set_string('description',description..' / RETAIN NEXT ROUND')end end
   a[i+1]=(c=='BLINK'and b.blink_left==0)and ItemStack('')or stack
 end end
 if b and S.round==1 then for _,choice in ipairs(direction_cards)do
  local stack=ItemStack('shift_circuit:direction_'..choice:lower());local m=stack:get_meta()
  m:set_string('description',direction_name(choice)..' / '..direction_help[choice]..'\nStarting-direction register only. No movement or board effects.'..(b.start_direction==choice and '\nSELECTED'or ''))
  m:set_string('inventory_image','sc_direction_'..choice..'.png'..(b.start_direction==choice and '^sc_hotbar_selected.png'or ''))
  a[#a+1]=stack
 end end
 inv:set_list('main',a);p:hud_set_hotbar_itemcount(1+(b and math.max(5,#(b.hand or {})) or 9)+(b and S.round==1 and 4 or 0))
end
local function update_hud(name)
 local p=core.get_player_by_name(name);local v=players[name];if not p or not v then return end;local spectator=spectating(name);local b=watched_bot(name)
 v.hud_sent=v.hud_sent or {};local function hud(id,field,value)Net.hud(p,v.hud_sent,id,field,value)end
 if phase=='editor'then
  if not v.editor_hidden then for _,id in ipairs(v.hud_ids)do hud(id,'text','')end;v.editor_hidden=true end
  return
 elseif v.editor_hidden then
  for id,text in pairs(v.hud_texts)do hud(id,'text',text)end;v.editor_hidden=nil
 end
 local ghost=b and b.ghost and not b.down and not b.finished and phase~='lobby'and phase~='loading'and phase~='finished'
 hud(v.ghost_status,'text',ghost and 'Ghost mode: inter-bot collision disabled'or '')
 hud(v.ghost_status_bg,'text',ghost and 'sc_ghost_status.png'or '')
 local palette_count=b and math.min(18,1+math.max(5,#(b.hand or {}))+(S.round==1 and 4 or 0))or 10
 hud(v.command_palette,'text',phase=='program'and b and not spectator and ('sc_command_palette_'..palette_count..'.png')or '')
 local hint=S.puzzle and S.puzzle.hint or '';if phase=='lobby'or phase=='loading'or phase=='finished'then hint=''end
 if v.hint_source~=hint then v.hint_source=hint;local lines={};local line='';for token in hint:gmatch('%S+')do local word=token;while #word>46 do if line~=''then lines[#lines+1]=line;line=''end;lines[#lines+1]=word:sub(1,46);word=word:sub(47)end;if #line+#word+1>46 then lines[#lines+1]=line;line=word else line=line==''and word or line..' '..word end end;if line~=''then lines[#lines+1]=line end;v.hint_display=table.concat(lines,'\n')end
 hud(v.puzzle_hint_bg,'text',v.hint_display~=''and 'sc_puzzle_hint.png'or '');hud(v.puzzle_hint,'text',v.hint_display)
 local remaining=phase=='program'and planning_left;local seconds=remaining and math.max(0,math.min(programming_seconds(),math.ceil(remaining)))
 hud(v.program_timer,'text',seconds and (((S.round or 1)==1 and 'sc_program_timer_first_'or 'sc_program_timer_')..seconds..'.png')or '')
 hud(v.program_countdown,'text',seconds and ((seconds<=10 and 'AUTO-FILL IN 'or 'PROGRAM / ')..string.format('%d:%02d',math.floor(seconds/60),seconds%60))or '')
 hud(v.program_countdown,'number',seconds and seconds<=10 and 0xffad97 or 0xd9eee5)
 local phase_icon=({direction_reading=1,direction=1,reading=1,commands=1,express=2,belts=3,pushers=4,rotators=5,weapons=6,lasers=7,presses=8})[phase]or 0
 hud(v.phase_order,'text',(phase=='editor'or phase=='lobby'or phase=='loading')and ''or 'sc_phase_order_'..phase_icon..'.png')
 local owner_actor=robots[name];local owner_view=owner_actor and owner_actor:get_luaentity().owner_view
 local own_position=(owner_view or owner_actor)and (owner_view or owner_actor):get_pos()
 hud(v.own_marker,'text',not spectator and b and not b.finished and own_position and 'sc_your_robot.png'or '')
 if own_position then hud(v.own_marker,'world_pos',b and b.down and pos(b.x,b.z,2.9)or {x=own_position.x,y=own_position.y+1.9,z=own_position.z})end
 local rows=RaceHUD.rows(S,phase);local visible=phase~='editor'and phase~='lobby'and phase~='loading'
 hud(v.racer_header,'text',visible and #rows>0 and 'sc_racer_header.png'or '')
 for i=1,8 do local row=visible and rows[i];local h=v.racers[i]
  hud(h.bg,'text',row and (row.id==name and 'sc_racer_row_self.png'or 'sc_racer_row.png')or '')
  hud(h.name,'text',row and ((row.id==name and 'YOU / 'or (row.human and ''or 'AI / '))..row.id:sub(1,row.id==name and 11 or 13))or '')
  hud(h.name,'number',row and row.id==name and 0xefc56e or (row and row.human and 0xade1d5 or 0x9fbbea))
  hud(h.progress,'text',row and ('sc_racer_'..(row.rank and 'place_'..row.rank or 'cp_'..row.checkpoint)..'.png')or '')
  hud(h.status,'text',row and 'sc_racer_'..row.status..'.png'or '')
 end
 local goal=Goal.current(S,b,phase);hud(v.goal,'text',goal.texture)
 hud(v.goal_marker,'text',goal.x and 'sc_goal_marker.png' or '')
 if goal.x then hud(v.goal_marker,'world_pos',pos(goal.x,goal.z,5.2))end
 local direction_phase=phase=='direction_reading'or phase=='direction'
 local title=phase=='lobby' and 'READY TO PLAY / Select START GAME and left-click' or (phase=='program' and 'PROGRAM / Queue five cards, then use COMMIT' or (phase=='finished' and 'ROUTE COMPLETE / I for the next mission' or ('PULSE '..slot..' / '..(phase=='presses' and 'CRUSHERS' or (phase=='planning_ai' and 'OPPONENTS PROGRAMMING' or phase:upper())))))
 if spectator and phase=='program'then title='PLANNING / '..(b and (b.ready and 'READY'or 'Choosing commands')or 'No robots remaining')end
 if direction_phase then title='STARTING DIRECTION / Blue register'end
 if execution_speed>1 then title='FAST FORWARD / Reboot pending'end
 if phase=='commands'and S.executing then local acting=bot(S.executing);title=title..((S.executing_count or 1)>1 and (' / '..S.executing_count..' enemies moving')or (' / '..S.executing..' / Priority ID '..R.priority(acting,slot)))end
 if phase=='program' and planning_left then title=title..' / '..math.ceil(planning_left)..'s' end
 hud(v.title,'number',phase=='program' and planning_left and planning_left<=10 and 0xff947b or 0x94e3cf)
 hud(v.title,'text','SHIFT CIRCUIT   /   '..(S.mode=='campaign' and C.missions[S.level].title or (S.mode=='tutorial' and 'TUTORIAL / '..(({'Drive to flag 1','Turn right; collect the shield','Turn left; reach flag 3'})[b and b.next or 1] or 'Complete') or (S.mode=='puzzle'and 'PUZZLE / ROUND 'or 'RACE / ROUND ')..S.round))..'\n'..title..(S.puzzle and ('\nPUZZLE / Round '..S.round..(S.puzzle.limit>0 and (' of '..S.puzzle.limit)or ''))or '')..(S.objective_collect and ('\n'..S.objective) or ''))
 local values={energy=b and b.energy or 0,shield=b and b.shield or 0,hull=b and not b.down and math.max(0,b.hp or 0) or 0,hand=b and b.allowance or 0,jam=b and b.disruption or 0,route=b and math.min(S.checkpoint_count or 3,b.next-1) or 0,modules=(b and (b.blink_left or 0)>0 and 1 or 0)+(b and (b.range or 4)>4 and 2 or 0)}
 for kind,id in pairs(v.gauges) do hud(id,'text','sc_stat_'..(kind=='route' and ('route_'..(S.checkpoint_count or 3))or kind)..'_'..values[kind]..'.png') end
 hud(v.controls,'text',inspecting() and 'Use K to enter flight mode / Z: go to your robot / I: inventory\nWheel: select / E: retain / Left-click: queue or COMMIT / Right-click: undo' or 'EXECUTION CAMERA / Following your robot\nLeft-click: orbit left / Right-click: orbit right / Round ends above your robot')
 if spectator then hud(v.controls,'text','SPECTATING / '..(b and b.id or 'No robots remaining')..'\n1: orbit / 2: switch robot / Left-click: previous / Right-click: next / I: menu')end
 local opening=S.round==1
 hud(v.register_terminal,'text',opening and 'sc_register_terminal_start.png'or 'sc_register_terminal.png')
 local blue=b and b.start_direction
 hud(v.direction_slot,'text',opening and (blue and ('sc_direction_'..blue..'.png')or 'sc_direction_empty.png')..(direction_phase and '^sc_hotbar_selected.png'or '')or '')
 hud(v.direction_label,'text',opening and (direction_phase and 'sc_register_start_active.png'or 'sc_register_start.png')or '')
 hud(v.direction_slot,'offset',{x=-190,y=30+(phase=='direction_reading'and 4 or 0)})
 for i=1,5 do
   local c=b and b.program and b.program[i];local texture=c and card_image(c,R.priority(b,i))or 'sc_emptycard.png'
   local reading=phase=='reading' and i==slot
   local progress=math.min(1,timer/phase_time())
   local scale=1
   hud(v.slots[i],'scale',{x=scale,y=scale})
   hud(v.slots[i],'offset',{x=(i-3)*76+(opening and 38 or 0),y=30+(reading and (2+2*math.floor(3*math.sin(progress*math.pi))) or 0)})
   if b and b.remote_slots and b.remote_slots[i]and c then texture=texture..'^sc_remote_overlay.png'end
   if i==slot and not inspecting() and c then texture=texture..'^sc_hotbar_selected.png' end
   hud(v.slots[i],'text',texture)
   hud(v.labels[i],'offset',{x=(i-3)*76+(opening and 38 or 0),y=102})
   hud(v.priorities[i],'offset',{x=(i-3)*76+(opening and 38 or 0),y=130})
   hud(v.labels[i],'text','sc_register_'..i..(phase~='program' and phase~='lobby' and i==slot and '_active' or '')..'.png')
   hud(v.priorities[i],'text',c and priority_label(R.priority(b,i))or '')
 end
 local eye=p:get_pos();eye={x=eye.x,y=eye.y+1.625,z=eye.z};local world_tags={}
 if goal.x then world_tags[#world_tags+1]={id=v.goal_marker,pos=pos(goal.x,goal.z,5.2)}end
 local nearby=phase~='editor'and NearbyLabels.choose(props,eye,name)or {}
 for i,id in ipairs(v.nearby_labels)do local q=nearby[i];hud(id,'name',q and q.text or '');if q then hud(id,'world_pos',q.pos);hud(id,'number',q.color);world_tags[#world_tags+1]={id=id,pos=q.pos}end end
 local racer_names=phase~='editor'and NearbyLabels.choose(props,eye,name,true)or {}
 for i,id in ipairs(v.racer_names)do local q=racer_names[i];hud(id,'name',q and q.text or '');if q then hud(id,'world_pos',q.pos);hud(id,'number',q.color);world_tags[#world_tags+1]={id=id,pos=q.pos}end end
 local badges=ScheduleBadges.nearby(props,eye)
 for i,id in ipairs(v.schedule_badges)do local q=badges[i];hud(id,'text',q and ScheduleBadges.texture(q.schedule,S.round or 1,phase~='program'and phase~='editor'and slot or 0)or '');if q then hud(id,'world_pos',q.pos);local size=q.schedule.parity~=nil and 1 or .5;hud(id,'scale',{x=size,y=size});world_tags[#world_tags+1]={id=id,pos=q.pos}end end
 for _,q in ipairs(WorldTagOrder.sort(world_tags,eye))do hud(q.id,'z_index',q.z)end
 hud(v.own_marker,'z_index',WorldTagOrder.owner)
 hud(v.pointed,'text',I.pointed(core,p,9))
 hud(v.destruction,'text',b and b.down and ('ROBOT DESTROYED / '..(b.destroyed_by or 'Damage')..'\nRebooting after this round') or '')
 if spectator then hud(v.detail,'text',b and ('WATCHING '..b.id..' / '..(b.down and 'Reboot pending'or b.ready and 'Program ready'or 'Planning'))or 'No robots remaining');return end
 local c=b and b.hand and b.hand[p:get_wield_index()-1]
 local blue_choice=b and S.round==1 and direction_cards[p:get_wield_index()-1-#(b.hand or {})]
 local notice=(b and b.emp_round==S.round and 'EMP DISABLED / Remaining commands skipped this round')or (b and b.remote_from and ('REMOTE CONTROL / Program copied from '..b.remote_from))or v.notice or '';if phase=='program' and planning_left then notice=(planning_left<=10 and 'TIME RUNNING OUT / ' or '')..'Empty slots will be filled randomly from your remaining cards.' end
 hud(v.detail,'text',(v.follow and not inspecting())and 'ORBIT / Left-click: rotate left / Right-click: rotate right'or notice..'\n'..(p:get_wield_index()==1 and (phase=='lobby' and 'START GAME / Left-click to choose a campaign or race' or 'COMMIT / Left-click to lock in your five-card program') or (blue_choice and (direction_name(blue_choice)..' / '..direction_help[blue_choice]..' / Starting register only')or c and (card_names[c]or c)..' / Priority ID '..((b.hand_ids or {})[p:get_wield_index()-1]or 0)..' / '..help[c] or 'Select a command card')))
end
refresh=function() for name in pairs(players) do local p=core.get_player_by_name(name);if p then if spectating(name)then follow_camera(p)end;inventory(p,bot(name));update_hud(name);if refresh_menu then refresh_menu(p) end end end end
local function all_ready() local n=0;for _,b in ipairs(humans()) do n=n+1;if not b.ready then return false end end;if n>0 then return true end;for _,b in ipairs(S.bots)do if b.enemy and not b.finished then return true end end;return false end
local planner=dofile(path..'/planning.lua')(core,path,R,C,options.time_sliced_ai)
local begin
local function plan_round()
 for _,b in ipairs(S.bots)do if b.enemy and not b.finished then R.ai_loadout(b,S.round)end end
 planner.start(S,function()if phase=='planning_ai' then begin()end end)
end
begin=function()
 if not planner.ready()then planning_left=nil;phase='planning_ai';refresh();return end
 clear_preview();preview_clock=0
 for _,p in ipairs(presses) do if phase=='presses'and slot%2==(p.parity or 0)then sound('crusher_return',pos(p.x,p.z),.3)end;machine_pose(p.o,'target',pos(p.x,p.z,4.3)) end
 for _,p in ipairs(pushers) do machine_pose(p.o,'target',pos(p.q.x,p.q.z)) end
 for _,r in ipairs(rotors) do machine_pose(r.o,'yaw',r.angle) end
 for _,b in ipairs(S.bots)do if S.round==1 then b.start_direction=b.start_direction or 'FORWARD'end end
 planning_left=nil;phase=S.round==1 and 'direction_reading'or 'reading';slot=1;timer=0
 for _,b in ipairs(humans()) do b.last_program={};for i,c in ipairs(b.program) do b.last_program[i]=c end end
 for name in pairs(players) do local p=core.get_player_by_name(name);if p then follow_camera(p) end end
 sync();refresh()
end
local function edit(p,action,index)
 local name=p:get_player_name();local b=bot(name);local v=players[name]
 if spectating(name)or not b or b.finished or phase~='program' or b.ready then return end
 if action=='direction'then
   if S.round~=1 or R.start_directions[index]==nil then return end
   b.start_direction=index
 elseif action=='direction_clear'then
   if S.round~=1 then return end;b.start_direction=nil
 elseif action=='queue' then
   if not b.hand[index] then return end
   if #b.selected>=5 then v.notice='Program is full / undo a card first';if options.ui then options.ui(name,1,'ui_error')end;update_hud(name);return end
   for _,i in ipairs(b.selected) do if i==index then v.notice='This card is already queued';if options.ui then options.ui(name,1,'ui_error')end;update_hud(name);return end end
   b.selected[#b.selected+1]=index;b.program[#b.program+1]=b.hand[index];b.program_ids=b.program_ids or {};b.program_ids[#b.program]=(b.hand_ids or {})[index]
 elseif action=='undo' then table.remove(b.selected);table.remove(b.program);table.remove(b.program_ids or {})
 elseif action=='clear' then b.selected={};b.program={};b.program_ids={};if S.round==1 then b.start_direction=nil end
 elseif action=='commit' then
   if #b.program<5 then v.notice='Choose five cards before committing';if options.ui then options.ui(name,1,'ui_error')end;update_hud(name);return end
   if S.round==1 then b.start_direction=b.start_direction or 'FORWARD'end
   b.ready=true
 end
 if options.ui then options.ui(name,1,action=='commit'and 'commit'or ((action=='undo'or action=='clear'or action=='direction_clear')and 'ui_back'or 'card_select'))end
 v.notice='';refresh();if all_ready() then begin() end
end
for _,c in ipairs({'STEP','DASH','MOVE3','BACK','BACK2','LEFT','RIGHT','UTURN','WAIT','PULSE','BLINK'}) do
 core.register_tool('shift_circuit:card_'..c:lower(),{description=Cards.tooltip(c),inventory_image='sc_card_'..c..'.png',stack_max=1,
 on_use=function(stack,p) edit(p,'queue',stack:get_meta():get_int('index')) end,
 on_secondary_use=function(stack,p) edit(p,'undo') end,
 on_place=function(stack,p) edit(p,'undo') end,
 on_drop=function(stack) return stack end})
end
for _,choice in ipairs(direction_cards)do
 core.register_tool('shift_circuit:direction_'..choice:lower(),{description=direction_name(choice)..' / '..direction_help[choice],inventory_image='sc_direction_'..choice..'.png',stack_max=1,
 on_use=function(_,p)edit(p,'direction',choice)end,
 on_secondary_use=function(_,p)edit(p,'direction_clear')end,
 on_place=function(_,p)edit(p,'direction_clear')end,on_drop=function(stack)return stack end})
end
core.register_tool('shift_circuit:commit',{description='COMMIT / Queue five cards, select this tool, then left-click',inventory_image='sc_commit_disabled.png',stack_max=1,
 on_use=function(_,p) edit(p,'commit') end,
 on_secondary_use=function(_,p) edit(p,p:get_player_control().sneak and 'clear' or 'undo') end,
 on_place=function(_,p) edit(p,p:get_player_control().sneak and 'clear' or 'undo') end,
 on_drop=function(stack) return stack end})
local function orbit(direction)
 return function(stack,p)
  local v=players[p:get_player_name()];if v and v.follow and (spectating(p:get_player_name())or not inspecting())then
   local e=v.follow:get_luaentity();e.orbit_target=(e.orbit_target or 0)+direction*math.pi/4;v.orbit_angle=e.orbit_target
  end;return stack
 end
end
local function switch_watched(name,direction)
 if not spectating(name)then return false end
 local v=players[name];local p=core.get_player_by_name(name);if not v or not p then return false end
 local current=watched_bot(name);local choices={};local index=1
 for _,b in ipairs(S.bots)do if not b.finished then choices[#choices+1]=b;if current and current.id==b.id then index=#choices end end end
 if #choices==0 then return false end
 v.watched=choices[(index-1+(direction<0 and -1 or 1))%#choices+1].id
 follow_camera(p);refresh();return true
end
local function spectate_tool(direction)return function(stack,p)switch_watched(p:get_player_name(),direction);return stack end end
core.register_tool('shift_circuit:spectate_switch',{description='WATCH ROBOT / Left-click: previous / Right-click: next',inventory_image='sc_direction_RIGHT.png',on_use=spectate_tool(-1),on_secondary_use=spectate_tool(1),on_place=spectate_tool(1),on_drop=function(stack)return stack end})
core.register_tool('shift_circuit:orbit',{description='ORBIT / Left-click: left / Right-click: right',inventory_image='sc_orbit.png',on_use=orbit(-1),on_secondary_use=orbit(1),on_place=orbit(1),on_drop=function(stack)return stack end})
core.register_tool('shift_circuit:start',{description='START GAME',inventory_image='sc_start.png',on_use=function(_,p) menu(p:get_player_name()) end,on_drop=function(stack)return stack end})
core.register_allow_player_inventory_action(function() return 0 end)
local function add_pilot(name,seat,old)
 -- A human seat takes precedence over an AI seat, including round-boundary joins.
 if #S.bots>=8 then for i=#S.bots,1,-1 do local other=S.bots[i];if other.enemy then
  local o=robots[other.id];if o then local e=o:get_luaentity();if e.ghost_marker then e.ghost_marker:remove()end;o:remove();robots[other.id]=nil end
  table.remove(S.bots,i);planner.cancel();break
 end end end
 local b={robot_style=Styles.get(store,name),archive_item=old and old.archive_item,parts=old and old.parts or {},weapon=old and (old.weapon or old.primary)or 'green_laser',secondary=old and old.secondary,equipment=old and old.equipment,aim_offset=old and old.aim_offset or 0,enabled=old and old.enabled or {},id=name,x=seat+1,z=2,dir=0,next=1,damage=0,hp=R.hull_max,max_hp=R.hull_max,energy=4,shield=0,range=old and old.range or 4,blink=old and old.blink or false,draw_bonus=old and old.draw_bonus or 0,home={x=seat+1,z=2,dir=0},program={}}
 if S.start then b.x,b.z,b.dir=S.start.x,S.start.z,S.start.dir;b.home={x=b.x,z=b.z,dir=b.dir}end
 if R.at(S,b.x,b.z) then b.down=true end
 R.normalize(b);S.bots[#S.bots+1]=b;if b.down then R.respawn(S) end;C.deal(b);if S.mode=='tutorial'then b.hand={'STEP','STEP','STEP','STEP','LEFT','LEFT','RIGHT','RIGHT','WAIT'}end;return b
end
spawn_robot=function(b)
 local o=visual(Styles.model(b),pos(b.x,b.z),{nametag=b.id,nametag_color=b.enemy and '#ff8d7b' or '#94e3cf'})
 o:get_luaentity().robot=true;o:get_luaentity().last_hp=b.hp;o:get_luaentity().last_shield=b.shield or 0;o:get_luaentity().last_dir=b.dir;o:get_luaentity().last_checkpoint=b.next;o:get_luaentity().destination=pos(b.x,b.z);o:set_yaw(G.yaw(b.dir))
 I.describe(o,b.scripted and ({sentry='Sentry',patroller='Patroller',ram_bot='Ram Bot'})[b.kind]or b.enemy and (b.kind=='hunter' and 'Hunter' or (b.racing and 'Race opponent' or 'Patrol')) or 'Robot: '..b.id,b.scripted and ({sentry='Turns clockwise each register, then fires during weapons.',patroller='Moves forward. Turns around at an obstruction or pit.',ram_bot='Sees a robot ahead: winds up, then charges 3 squares next register.'})[b.kind]or b.pattern and ('Repeats: '..table.concat(b.pattern,' / ')) or 'Plans from a dealt hand. Fires after rotators.',{-.65,-.5,-.5,.65,1.2,.5})
 Net.properties(o,{textures={robot_texture(b,false)}});robots[b.id]=o
end
spawn_pickup=function(key,kind)
   local x,z=key:match('(%d+),(%d+)');local o=visual('pickup_'..kind,pos(tonumber(x),tonumber(z),1.4),{nametag=Systems.item_name(kind),nametag_color=kind=='jammer' and '#ef859f' or '#96e5cd',glow=4})
   if kind=='jammer' then Net.properties(o,{textures={'sc_surface_pickup_jammer.png^[multiply:#f28cbe'}}) end
   I.describe(o,Systems.item_name(kind),({reset_button='Use during planning to redraw your hand and clear your program. Consumed on use.',electromagnetic_brake='Blocks robot pushes, pushers and tractor/repulsor beams while enabled. Commands and conveyors still move you. No power cost.',battering_ram='Successful pushes deal 2 hull damage to the first robot pushed.',hard_disk='Press E to keep one movement card per disk for the next round.',holographic_memory='Consumed to reboot at your destruction square once, except pit falls.',gyro_stabilizer='Enable each round to ignore forced rotation.',electroshield='Absorbs incoming damage for one power per hit while enabled.',titanium_hull='Survives one crusher strike, then breaks.',green_laser='Default weapon / one loaded weapon at a time.',double_laser='Two damage beams. Install during planning.',triple_laser='Three damage beams. Costs 1 power per hit.',emp_generator='Costs 2 power on a target hit. Disables the targetÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢s remaining commands this round.',remote_control='Copies remaining commands to a target. Install during planning.',tractor_beam='Pulls a robot one square.',repulsor_beam='Pushes a robot one square.',mechanical_arm='Collects an adjacent pickup each register, across walls.',turret_gearbox='Aim your weapon front, back, left or right.',repair='Fully restores hull when collected.',shield='Grants three shield charges (maximum three).',cell='Fully recharges power to nine.',thermal_camera='Automatic aim tracks the nearest visible enemy during weapon phases.',blueprint_archive='Choose one item in your dashboard to keep on respawn.',blink='One successful jump consumes one Blink. At most one per round.',range='Passive equipment / +5 weapon range per copy.',cache='Adds two cards to future hands, up to three bonus cards.',jammer='Warning: removes two cards from the next hand.'})[kind],{-.48,-.48,-.48,.48,.48,.48});o:get_luaentity().hover=true;o:get_luaentity().origin=pos(tonumber(x),tonumber(z),1.4);pickups[key]=o
 end
local built_extent
build=function()
 Styles.assign_racers(S.bots)
 cleanup();Active.acquire(origin,S.size);if core.begin_map_edit then core.begin_map_edit()end
 local extent=S.size*2+8
 local clear_height=built_extent~=extent and 22 or 5
 if built_extent and built_extent>extent then
  for z=-6,built_extent do for x=-6,built_extent do if x>extent or z>extent then for y=-5,23 do core.set_node({x=x,y=y,z=z},{name='air'})end end end end
 end
 built_extent=extent
 for z=-6,extent do for x=-6,extent do
   core.set_node({x=x,y=-5,z=z},{name='shift_circuit:beam'});core.set_node({x=x,y=23,z=z},{name='shift_circuit:beam'})
   if x==-6 or x==extent or z==-6 or z==extent then for y=-4,22 do core.set_node({x=x,y=y,z=z},{name=(y%6==0 and (x+z)%5==0) and 'shift_circuit:light' or 'shift_circuit:beam'}) end end
 end end
 for z=-5,extent-1 do for x=-5,extent-1 do
   for y=-4,clear_height do core.set_node({x=x,y=y,z=z},{name='air'}) end
   -- Pilots can walk across holes and the perimeter moat. Robots and loose
   -- objects use board rules, not node collision, so they still fall normally.
   local apron=x<0 or x>S.size*2+3 or z<0 or z>S.size*2+3
   core.set_node({x=x,y=0,z=z},{name=apron and 'shift_circuit:apron'or 'shift_circuit:collider'})
   core.set_node({x=x,y=-4,z=z},{name='shift_circuit:pit'})
   if x==-5 or x==extent-1 or z==-5 or z==extent-1 then
     for y=1,3 do core.set_node({x=x,y=y,z=z},{name='shift_circuit:beam'}) end
     if x%4==0 or z%4==0 then core.set_node({x=x,y=3,z=z},{name='shift_circuit:light'}) end
   end
   if (x==-1 or x==S.size*2+4) and z%3==0 or (z==-1 or z==S.size*2+4) and x%3==0 then core.set_node({x=x,y=0,z=z},{name='shift_circuit:light'}) end
 end end
 for z=-2,S.size+3 do for x=-2,S.size+3 do
  if x<0 or x>S.size+1 or z<0 or z>S.size+1 then visual('tile',pos(x,z,1.008),{textures={'sc_tile_deck.png^[multiply:#8297a0'},backface_culling=false})end
 end end
 for z=1,S.size do for x=1,S.size do
   local t=R.tile(S,x,z)
   if t.kind~='pit' and t.kind~='trapdoor'then
     local tile=visual('tile',pos(x,z),{textures={'sc_tile_'..(t.kind=='station' and 'dock'..t.number or (t.kind=='save'and 'save'or t.kind=='checkpoint' and 'dock0' or (t.kind=='repair' and 'repair' or 'deck')))..'.png'},backface_culling=false})
     I.describe(tile,t.kind=='station' and ('Checkpoint '..t.number) or 'Factory tile',t.kind=='station' and 'Visit checkpoints in numerical order.' or 'One square of the programming grid.',{-1,-.52,-1,1,-.48,1})
     if t.kind=='repair'then I.describe(tile,'Repair Pad','End a register here: +1 hull. End the five-register round here: full hull and power.',{-1,-.52,-1,1,-.48,1})
     elseif t.kind=='save'then I.describe(tile,'Save Square','Saves reboot location and facing at register end. End the round here for +2 hull and +3 power. Does not advance the route.',{-1,-.52,-1,1,-.48,1})
     elseif t.kind=='checkpoint'then I.describe(tile,'Checkpoint Candidate','The course builder chooses and numbers these locations.',{-1,-.52,-1,1,-.48,1})
     elseif t.kind=='belt' then
       local curved=t.entry and t.entry~=t.dir
       local model=curved and (((t.entry-t.dir)%4==1) and 'curve_right' or 'curve_left') or 'belt_rails'
       local o=visual(model,pos(x,z),{backface_culling=false});o:set_yaw(G.yaw(t.dir))
       local title=(t.speed==2 and 'Double ' or '')..(curved and 'Turning Conveyor' or 'Conveyor')
       I.describe(tile,title,curved and 'Carries and turns robots along the bend.' or (t.speed==2 and 'Two conveyor steps per pulse.' or 'One conveyor step per pulse.'),{-1,-.52,-1,1,-.18,1})
       if curved then
         local tread=visual('tread_'..model..'_0',pos(x,z),{backface_culling=false});tread:set_yaw(G.yaw(t.dir));local e=tread:get_luaentity();e.belt=true;e.speed=t.speed or 1;e.travel=0;e.curve_model=model
       else
         local tread=visual('tread_straight',pos(x,z),{mesh='sc_tread_straight.b3d',textures={'sc_surface_conveyor.png'},backface_culling=false})
         tread:set_yaw(G.yaw(t.dir));local e=tread:get_luaentity();e.belt=true;e.speed=t.speed or 1;e.travel=0;e.client_tread=true
         tread:set_animation({x=0,y=24},0,0,true)

       end
       local arrow=visual(curved and ('arrow_'..model) or (t.speed==2 and 'arrow_double' or 'arrow_forward'),pos(x,z),{glow=4,backface_culling=false,textures={curved and t.speed~=2 and 'sc_surface_conveyor_arrows_green.png' or 'sc_surface_conveyor_arrows.png'}});arrow:set_yaw(G.yaw(t.dir))
     elseif t.kind=='station' then visual('station_ring',pos(x,z))
     elseif t.kind=='rotator' then local o=visual('rotator',pos(x,z),{nametag=t.turn==3 and 'Left Rotator'or 'Right Rotator'});I.describe(o,t.turn==3 and 'Left Rotator' or 'Right Rotator','Rotates robots 90 degrees each pulse.',{-.82,-.47,-.82,.82,-.24,.82});rotors[#rotors+1]={o=o,turn=t.turn,angle=0} end
   end
 end end
 for key,q in pairs(S.overhead or {}) do
   local parity=type(q)=='table'and (q.parity or 0)or 0;local title=parity==1 and 'Crusher Odd'or 'Crusher Even';local steps=parity==1 and '1 + 3 + 5'or '2 + 4'
   local x,z=key:match('(%d+),(%d+)');x=tonumber(x);z=tonumber(z)
   local frame=visual('press_frame',pos(x,z,1),{nametag=title,nametag_color='#dfbc77'})
   I.describe(frame,title,'Registers '..steps..': destroys robots underneath, even through shields. Preview is harmless.',{-1,-.5,-.95,1,4.6,.95})
   local ram=visual('ram',pos(x,z,4.3));I.describe(ram,title,'Registers '..steps..': lethal crushing strike. Inspection motion is harmless.',{-.82,-.32,-.75,.82,.13,.75})
   local anchor,length=G.crusher_rod(ram:get_pos(),origin.y+5.0)
   local piston=visual('piston',anchor,{visual_size={x=1,y=length,z=1},pointable=false});ram:get_luaentity().hydraulic_rod=piston;ram:get_luaentity().hydraulic_ceiling=origin.y+5.0
   frame:get_luaentity().schedule_badge={parity=parity,height=3.5}
   presses[#presses+1]={o=ram,x=x,z=z,parity=parity}
 end
 for key,solid in pairs(S.walls)do if solid then local w=R.wall(key);if w then local o=visual('edge_wall',pos(w.x,w.z));if w.axis=='E'then o:set_yaw(math.pi/2)end;I.describe(o,'Edge Wall','Blocks movement and beams across this edge.',{-1,-.5,-.13,1,1.39,.13})end end end
 for _,q in ipairs(S.pushers) do local o=visual('pusher',pos(q.x,q.z),{nametag='Pusher',nametag_color='#dfbc77'});o:set_yaw(G.yaw(q.dir));local ram=visual('pushram',pos(q.x,q.z));ram:set_yaw(G.yaw(q.dir));local rodpos,rodlength=G.pusher_rod(pos(q.x,q.z),ram:get_pos(),q.dir);local rod=visual('pushrod',rodpos,{visual_size={x=1,y=1,z=rodlength},pointable=false});rod:set_yaw(G.yaw(q.dir));local re=ram:get_luaentity();re.pusher_rod=rod;re.pusher_base=pos(q.x,q.z);re.pusher_dir=q.dir;I.describe(o,'Pusher',q.parity==1 and 'Pushes on pulses 1, 3 and 5.' or 'Pushes on pulses 2 and 4.',{-.75,-.5,-.9,.75,-.02,-.58});I.describe(ram,'Pusher ram','Pushes robots, crates and powerups one tile.',{-.63,-.44,-.53,.63,-.06,-.37});o:get_luaentity().schedule_badge={parity=q.parity or 0,height=1.2};pushers[#pushers+1]={o=ram,q=q} end
 for _,q in ipairs(S.lasers) do local x,z=R.laser_source(q);local o=visual('laser'..q.power,pos(x,z));o:set_yaw(G.yaw(q.dir));I.describe(o,({'Single Laser','Double Laser','Triple Laser'})[q.power],'Thin wall emitter. Fires into this square until a wall or robot.',{-.98,-.5,-.12,.98,.625,.19}) end
 for key,spawner in pairs(S.spawners or {})do local x,z=key:match('(%d+),(%d+)');local schedule=spawner.every and ('Every '..spawner.every..' rounds / from '..(spawner.first or 1))or ('Rounds '..table.concat(spawner.rounds or {},', '));local o=visual('spawner',pos(tonumber(x),tonumber(z)),{glow=3});o:get_luaentity().schedule_badge={spawner=spawner,height=1.2};I.describe(o,'Random Powerup Spawner',schedule..' / Phase '..(spawner.phase or 0)..' / '..(spawner.chance or 50)..'% chance. Occupied pads keep their pickup.',{-.7,-.5,-.7,.7,-.25,.7})end
 for key,kind in pairs(S.pickups)do spawn_pickup(key,kind)end
 for _,b in ipairs(S.bots) do
   if not b.enemy and not S.start then local marker=visual('tile',pos(b.home.x,b.home.z,1.025),{textures={'sc_start_marker.png'},use_texture_alpha=true,backface_culling=false,glow=5});marker:set_yaw(G.yaw(b.home.dir or 0));I.describe(marker,'Start / Reboot marker','Initial checkpoint. Reboot restores its facing direction.',{-1,-.51,-1,1,-.48,1})end
   spawn_robot(b)
 end
 for _,edge in ipairs(G.pit_edges(S,R))do
  local warning=visual('pit_edge_'..edge.corners,world(edge),{textures={'sc_pit_edge.png'},backface_culling=false})
  warning:set_yaw(G.yaw(edge.dir));warning:get_luaentity().pit_edge=true
 end
 if S.start and phase~='editor'then local marker=visual('tile',pos(S.start.x,S.start.z,1.025),{textures={'sc_start_marker.png'},use_texture_alpha=true,backface_culling=false,glow=5});marker:set_yaw(G.yaw(S.start.dir))end
 if core.end_map_edit then core.end_map_edit()end
end
start_match=function(mode,level,carry)
 execution_speed=1;destruction_pause=0
 planner.cancel()
 restore_cameras()
 local old={};for _,b in ipairs(humans(true)) do old[b.id]=b end
 local names={};for name,v in pairs(players) do if v.joined then names[#names+1]=name end end;table.sort(names)
 if #names==0 then return end
 S=C.setup(R,level,mode,options.board);S.ai_mode=options.ai_mode or 'hunter';S.ai_count=options.ai_count or 0
 local cfg=options.solo_config or {};if mode=='race' and cfg.platforms then S=Q.assemble(R,cfg.platforms,cfg.checkpoints or 3,cfg.layout,cfg.route);S.board_id=options.board or 1;S.course_key=cfg.course_key;S.ai_mode=options.ai_mode or 'racer';S.ai_count=options.ai_count or 0 end;S.enemy_count=cfg.enemies;S.racer_count=cfg.racers;S.difficulty=cfg.difficulty or 2;S.racer_difficulty=cfg.racer_difficulty or 2;S.campaign_puzzle=mode=='campaign' and cfg.puzzle~=false
 if S.campaign_puzzle then S.objective_collect=({'cell','blink','range'})[level];S.objective='Collect '..S.objective_collect:upper()..' and visit all three checkpoints.'end
 for i,name in ipairs(names) do if i<=8 then
   local saved=mode=='campaign' and level>1 and core.deserialize(store:get_string('modules:'..name)) or nil
   add_pilot(name,i,(carry and old[name]) or saved)
 end end
 C.enemies(S,R);R.init_objects(S);R.spawn_pickups(S);C.deal_round(S);if mode=='tutorial'then for _,b in ipairs(S.bots)do if not b.enemy then b.hand={'STEP','STEP','STEP','STEP','LEFT','LEFT','RIGHT','RIGHT','WAIT'}end end end;if mode=='race'then R.shared_start(S,S.start or {x=2,z=2,dir=0})end;phase='program';planning_left=timed_program()and programming_seconds() or nil;slot=0;plan_round();build();sync();refresh()
 for name in pairs(players) do core.close_formspec(name,'shift_circuit:lobby') end
end
menu=function(name)
 if options.menu then options.menu(name);return end
 local p=core.get_player_by_name(name);if not p then return end
 local unlocked=math.max(1,store:get_int('progress:'..name));local v=players[name]
 local f={'formspec_version[6]size[12,9]bgcolor[#0b1824ee;true]box[0,0;12,9;#102330ff]style_type[button;bgimg=sc_button.png;border=false]label[.6,.5;SHIFT CIRCUIT / PLAY]'}
 local function add(t)f[#f+1]=t end
 add('label[.6,1.05;Host: '..core.formspec_escape(host or '')..' / Up to eight racers]')
 if name==host then
   add('style[mission1;bgcolor=#58b99c]button[.6,1.6;5.2,1.1;mission1;START CAMPAIGN]button[6.2,1.6;5.2,1.1;race;START MULTIPLAYER RACE]')
   for i=2,3 do local y=3+(i-2)*.9
     if i<=unlocked then add(('button[.6,%f;10.8,.7;mission%d;CONTINUE / %s]'):format(y,i,C.missions[i].title))
     else add(('label[.8,%f;MISSION %d / Complete the previous mission to unlock]'):format(y+.3,i)) end
   end
   if phase=='finished' and S.mode=='campaign' and S.level<3 then add('button[.6,4.8;10.8,.7;next;NEXT MISSION / KEEP UPGRADES]') end
 else add('label[.8,2.1;Waiting for the host to choose a game.]button[.6,3;10.8,.9;join;'..(v.joined and 'LEAVE SEAT' or 'JOIN GAME')..']') end
 add('label[.6,5.85;Choose five cards / Arrange your program / Use COMMIT]')
 add('label[.6,6.8;Use K to enter flight mode]button[8,6.4;3.4,.8;join;'..(v.joined and 'LEAVE SEAT' or 'JOIN GAME')..']')
 add('button_exit[8,8;3.4,.65;close;INSPECT THE BOARD]')
 p:set_inventory_formspec(MenuUI.decorate(table.concat(f)));core.show_formspec(name,'shift_circuit:lobby',table.concat(f))
end
refresh_menu=function(p)
 local name=p:get_player_name();local b=watched_bot(name);p:set_inventory_formspec(Loadout.formspec(b,spectating(name)and 'spectate'or phase,nil,S.test_mode and 'Test your equipment'or Goal.current(S,b,phase).label))
end
core.register_on_player_receive_fields(function(p,form,f)
 if form=='shift_circuit:loadout'or ((form==''or f.apply)and Loadout.changed(f))then
  if f.room then menu(p:get_player_name());return end
  if spectating(p:get_player_name())then return end
  local b=bot(p:get_player_name());local note
  if b and Loadout.changed(f)and not f.quit then
   if phase=='program'and not b.ready then local ok;if f.use_reset then ok,note=C.reset_hand(S,b);if ok then sound('pickup',p:get_pos(),.25,1.2)end else ok,note=Loadout.apply(b,f)end;if ok then if options.ui then local cue='ui_click';for k,value in pairs(f)do if k:match('^enable_')then cue=value=='true'and 'ui_on'or 'ui_off'end end;options.ui(p:get_player_name(),1,cue)end;sync();refresh()elseif options.ui then options.ui(p:get_player_name(),1,'ui_error')end
   else note='Loadout is locked';if options.ui then options.ui(p:get_player_name(),1,'ui_error')end end
   if form=='shift_circuit:loadout'then Loadout.show(p,b,phase,note)else p:set_inventory_formspec(Loadout.formspec(b,phase,note))end
  end;return
 end
 if form~='' and form~='shift_circuit:lobby' then return end
 local name=p:get_player_name();local v=players[name];if not v then return end
 if f.loadout then Loadout.show(p,watched_bot(name),spectating(name)and 'spectate'or phase);return end
 if f.room then menu(name);return end
 if f.results and options.finished then options.finished(S);return end
 if f.join then
   if v.joined then
     v.joined=false;local retained=bot(name)and bot(name).disconnected
 if not retained then for i,b in ipairs(S.bots) do if b.id==name then table.remove(S.bots,i);break end end end
     if robots[name] then local e=robots[name]:get_luaentity();if e.owner_view then e.owner_view:remove();e.owner_view=nil end;if not retained then if e.ghost_marker then e.ghost_marker:remove()end;robots[name]:remove();robots[name]=nil elseif robots[name].set_observers then robots[name]:set_observers(nil)end end
   elseif #humans()<8 and not (options.is_spectator and options.is_spectator(name))then v.joined=true
     if phase=='program' or phase=='lobby' then local b=add_pilot(name,#humans()+1);spawn_robot(b);if phase=='program'then plan_round()end else v.notice='Seat queued for next round' end
   else v.notice='All eight seats are occupied' end
   refresh();menu(name)
 end
 if name==host and phase~='loading' then
   if f.race then start_match('race',1,false) end
   for i=1,3 do if f['mission'..i] and i<=math.max(1,store:get_int('progress:'..name)) then start_match('campaign',i,false) end end
   if f.next and phase=='finished' and S.mode=='campaign' and S.level<3 then start_match('campaign',S.level+1,true) end
 end
 if phase=='program' and all_ready() then begin() end
 refresh_menu(p)
end)
core.register_on_joinplayer(function(p)
 local name=p:get_player_name();host=host or name
 local returning=bot(name);local reclaimed=returning and returning.disconnected and not (options.is_spectator and options.is_spectator(name))
 if reclaimed then planner.cancel();if phase=='planning_ai'and not returning.ready then phase='program';planning_left=programming_seconds()end;returning.enemy=false;returning.disconnected=nil;returning.racing=nil;returning.kind=nil;returning.difficulty=nil end
 local v={joined=not (options.is_spectator and options.is_spectator(name))and #humans()<8,camera='fly',slots={},labels={},priorities={},gauges={}};players[name]=v
 v.hud_ids={};v.hud_texts={};local function hud(d) local id=p:hud_add(d);v.hud_ids[#v.hud_ids+1]=id;v.hud_texts[id]=d.text or '';return id end
 v.command_palette=hud({type='image',position={x=.5,y=1},offset={x=0,y=-4},alignment={x=0,y=-1},scale={x=1,y=1},text='',z_index=-10})
 v.ghost_status_bg=hud({type='image',position={x=.5,y=0},alignment={x=0,y=1},offset={x=0,y=196},scale={x=1,y=1},text='',z_index=0})
 v.ghost_status=hud({type='text',position={x=.5,y=0},alignment={x=0,y=0},offset={x=0,y=212},number=0xb5ffd0,text='',z_index=1})
 v.phase_order=hud({type='image',position={x=0,y=1},offset={x=16,y=-16},alignment={x=1,y=-1},scale={x=1,y=1},text=''})
 hud({type='image',position={x=0,y=.19},alignment={x=1,y=1},offset={x=16,y=0},scale={x=1,y=1},text='sc_hud_stats.png'})
 hud({type='image',position={x=.5,y=1},alignment={x=0,y=-1},offset={x=0,y=-108},scale={x=1,y=1},text='sc_hud_controls.png'})
 v.register_terminal=hud({type='image',position={x=.5,y=0},alignment={x=0,y=1},scale={x=1,y=1},text='sc_register_terminal.png'})
 v.direction_slot=hud({type='image',position={x=.5,y=0},offset={x=-190,y=30},alignment={x=0,y=1},scale={x=1,y=1},text=''})
 v.direction_label=hud({type='image',position={x=.5,y=0},offset={x=-190,y=102},alignment={x=0,y=1},scale={x=1,y=1},text=''})
 v.program_timer=hud({type='image',position={x=.5,y=0},alignment={x=0,y=1},offset={x=0,y=156},scale={x=1,y=1},text=''})
 v.program_countdown=hud({type='text',position={x=.5,y=0},alignment={x=0,y=0},offset={x=0,y=172},number=0xd9eee5,text=''})
 v.puzzle_hint_bg=hud({type='image',position={x=1,y=1},offset={x=-16,y=-16},alignment={x=-1,y=-1},scale={x=1,y=1},text=''})
 v.puzzle_hint=hud({type='text',position={x=1,y=1},offset={x=-448,y=-115},alignment={x=1,y=1},number=0xc8e4de,size={x=.9,y=.9},text=''})
 v.goal=hud({type='image',position={x=1,y=0},offset={x=-16,y=16},alignment={x=-1,y=1},scale={x=1,y=1},text='sc_goal_start.png'})
 v.racer_header=hud({type='image',position={x=1,y=0},offset={x=-16,y=132},alignment={x=-1,y=1},scale={x=1,y=1},text=''})
 v.racers={};for i=1,8 do local y=156+(i-1)*28;v.racers[i]={
  bg=hud({type='image',position={x=1,y=0},offset={x=-16,y=y},alignment={x=-1,y=1},scale={x=1,y=1},text=''}),
  name=hud({type='text',position={x=1,y=0},offset={x=-264,y=y+13},alignment={x=1,y=0},size={x=.8,y=.8},number=0xade1d5,text=''}),
  progress=hud({type='image',position={x=1,y=0},offset={x=-86,y=y+4},alignment={x=-1,y=1},scale={x=1,y=1},text=''}),
  status=hud({type='image',position={x=1,y=0},offset={x=-20,y=y+4},alignment={x=-1,y=1},scale={x=1,y=1},text=''})}
 end
 v.goal_marker=hud({type='image_waypoint',world_pos=pos(2,2,5.2),scale={x=1,y=1},z_index=-280,text='',alignment={x=0,y=0}})
 -- Above world nametags (-300), below the hotbar and interface panels (0).
 v.schedule_badges={};for i=1,6 do v.schedule_badges[i]=hud({type='image_waypoint',z_index=-290,text='',world_pos=pos(2,2),scale={x=1,y=1},alignment={x=0,y=-1}})end
 v.racer_names={};for i=1,8 do v.racer_names[i]=hud({type='waypoint',z_index=-300,name='',text='',precision=0,world_pos=pos(2,2),number=0x94e3cf,alignment={x=0,y=-1}})end
 v.nearby_labels={};for i=1,6 do v.nearby_labels[i]=hud({type='waypoint',z_index=-300,name='',text='',precision=0,world_pos=pos(2,2),number=0x94e3cf,alignment={x=0,y=-1}})end
 v.own_marker=hud({type='image_waypoint',z_index=-250,world_pos=pos(2,2,2.9),scale={x=1,y=1},text='',alignment={x=0,y=-1}})
 v.title=hud({type='text',position={x=.03,y=1},offset={x=0,y=-215},alignment={x=1,y=-1},number=0xb5e4d9,text='',size={x=1,y=1}})
 for i,kind in ipairs({'hull','energy','shield','hand','jam','route','modules'}) do v.gauges[kind]=hud({type='image',position={x=0,y=.2},offset={x=22,y=(i-1)*42},alignment={x=1,y=1},scale={x=1,y=1},text='sc_stat_'..kind..'_0.png'}) end
 v.controls=hud({type='text',position={x=.5,y=1},offset={x=0,y=-112},alignment={x=0,y=-1},number=0xadc4cd,text=''})
 v.pointed=hud({type='text',position={x=.5,y=.57},alignment={x=0,y=1},number=0xd8f3e8,text=''})
 v.destruction=hud({type='text',position={x=.5,y=.36},alignment={x=0,y=0},number=0xff7755,text='',size={x=1.5,y=1.5}})
 v.detail=hud({type='text',position={x=.5,y=1},offset={x=0,y=-155},alignment={x=0,y=-1},number=0xf0c67b,text=''})
 for i=1,5 do
   v.slots[i]=hud({type='image',position={x=.5,y=0},offset={x=(i-3)*76,y=30},alignment={x=0,y=1},scale={x=1,y=1},text='sc_emptycard.png'})
   v.labels[i]=hud({type='image',position={x=.5,y=0},offset={x=(i-3)*76,y=102},alignment={x=0,y=1},scale={x=1,y=1},text='sc_register_'..i..'.png'})
   v.priorities[i]=hud({type='image',position={x=.5,y=0},offset={x=(i-3)*76,y=130},alignment={x=0,y=1},scale={x=1,y=1},text=''})
 end
 p:set_properties({is_visible=false,visual_size={x=0,y=0,z=0},pointable=false,nametag='',nametag_color='#00000000',zoom_fov=0});p:set_sky({type='plain',base_color='#101c29',clouds=false});p:set_sun({visible=false});p:set_moon({visible=false});p:set_stars({visible=false})
 p:set_fov(65,false,0);p:hud_set_flags({hotbar=true,healthbar=false,crosshair=true,wielditem=false,breathbar=false,minimap=false})
 p:hud_set_hotbar_image('sc_hotbar.png');p:hud_set_hotbar_selected_image('sc_hotbar_selected.png');camera(p,'fly');refresh_menu(p)
 if reclaimed then
  p:set_pos(pos(returning.x,returning.z,7));p:set_look_vertical(math.pi/2)
  sync();refresh();if phase=='program'or phase=='planning_ai'then plan_round()end
 elseif v.joined and (phase=='program' or phase=='lobby') then local b=add_pilot(name,#humans()+1);spawn_robot(b);if phase=='program'then plan_round()end end
 core.after(.5,function() local joined=core.get_player_by_name(name);if joined then sync();if not inspecting() and phase~='loading' then follow_camera(joined) end;refresh();if phase=='lobby' and not players[name].welcomed then players[name].welcomed=true;menu(name) end end end)
end)
core.register_on_leaveplayer(function(p)
 local name=p:get_player_name();local v=players[name];if v and p.hud_remove then for _,id in ipairs(v.hud_ids or {}) do p:hud_remove(id) end end;if v and v.follow then p:set_detach();v.follow:remove() end;players[name]=nil
 local retained=bot(name)and bot(name).disconnected
 if not retained then for i,b in ipairs(S.bots) do if b.id==name then table.remove(S.bots,i);break end end end
 if robots[name] then local e=robots[name]:get_luaentity();if e.owner_view then e.owner_view:remove();e.owner_view=nil end;if not retained then if e.ghost_marker then e.ghost_marker:remove()end;robots[name]:remove();robots[name]=nil elseif robots[name].set_observers then robots[name]:set_observers(nil)end end
 if host==name then host=nil;for n in pairs(players) do host=n;break end end
 if #S.bots==0 then restore_cameras();phase='lobby' elseif phase=='program' and all_ready() then begin() end
 sync();refresh()
end)
core.register_chatcommand('sc',{params='',description='Open the lobby.',func=function(name,param)
 local p=core.get_player_by_name(name);if not p then return false end
 menu(name);return true
end})
core.register_on_mods_loaded(function() core.after(0,function()
 core.set_timeofday(.5);core.emerge_area({x=-16,y=-16,z=-16},{x=32,y=32,z=32},function(_,_,left) if left==0 then core.after(0,function() if not options.defer_board then build()end;phase='lobby';for n,v in pairs(players) do if v.joined and not bot(n) and #humans()<8 then spawn_robot(add_pilot(n,#humans()+1)) end end;refresh();for n,v in pairs(players) do if not v.welcomed then v.welcomed=true;menu(n) end end end) end end)
end) end)
local hudclock=0;local countdown_cue
core.register_globalstep(function(dt)
 if phase~='loading'and phase~='lobby'then for _,b in ipairs(S.bots)do local o=robots[b.id];local e=o and o:get_luaentity();if not b.finished and o and (not e or (e.owner_view and not e.owner_view:get_luaentity()))then sync();break end end end
 if phase=='program'and #humans()==0 and all_ready()then begin()end
 if phase=='program' then
   if timed_program()then
     planning_left=math.max(0,(planning_left or programming_seconds())-dt)
     local second=math.ceil(planning_left);if second<=5 and second>0 and second~=countdown_cue then for _,b in ipairs(humans())do if not b.ready and options.ui then options.ui(b.id,1.4)end end end;countdown_cue=second
     if planning_left<=.00001 then
       for _,b in ipairs(humans()) do C.autofill(b) end
       begin();return
     end
   else planning_left=nil;countdown_cue=nil end
 end
 hudclock=hudclock+dt
 for name,v in pairs(players) do
   local p=core.get_player_by_name(name)
   if p then
     -- Recovery bounds sit three nodes beyond the enclosure, not on its walls.
     local pp=p:get_pos();if not v.return_view and (pp.y<origin.y-8 or pp.y>origin.y+26 or pp.x<origin.x-9 or pp.x>origin.x+S.size*2+11 or pp.z<origin.z-9 or pp.z>origin.z+S.size*2+11) then camera(p,v.camera) end
     local controls=p:get_player_control();local locate=controls.zoom
     if locate and not v.locate_key and not v.return_view then
      local b=bot(name);if b and not b.finished then
       p:set_pos(pos(b.x,b.z,7));p:set_look_vertical(math.pi/2);v.notice='YOUR ROBOT / Marked below';update_hud(name)
      end
     end;v.locate_key=locate
     local held=controls.aux1
     if held and not v.keep_key and phase=='program'and not spectating(name)then
      local b=bot(name);local index=p:get_wield_index()-1
      if b and not b.ready and b.hand[index]and b.hand[index]~='BLINK'then
       b.keep=b.keep or {};local removed=false;for i,k in ipairs(b.keep)do if k==index then table.remove(b.keep,i);removed=true;break end end
       local capacity=b.parts and b.parts.hard_disk or 0
       if not removed and #b.keep<capacity then b.keep[#b.keep+1]=index;v.notice='HARD DISK / Card retained for next round'
       elseif removed then v.notice='HARD DISK / Card released'
       else v.notice=capacity==0 and 'Collect a Hard Disk to retain cards'or 'Hard Disk storage is full'end
       inventory(p,b);update_hud(name)
      end
     end;v.keep_key=held
     if hudclock>.15 then if spectating(name)then follow_camera(p)end;update_hud(name) end
   end
 end
 if hudclock>.15 then hudclock=0 end
 planner.tick()
 if phase=='planning_ai'then execution_speed=1;destruction_pause=0;return end
 if inspecting()then execution_speed=1;destruction_pause=0 end
 if inspecting() then inspect_animation(dt);return end
 if phase=='loading' then return end
 if destroyed_puzzle_player()then destruction_pause=destruction_pause+dt;execution_speed=destruction_pause>=.7 and 6 or 1 else execution_speed=1;destruction_pause=0 end
 timer=timer+dt*execution_speed;if timer<phase_time() then return end;timer=0
 if phase=='direction_reading'then
  for _,b in ipairs(S.bots)do R.start_facing(S,b)end;phase='direction'
 elseif phase=='direction'then phase='reading'
 elseif phase=='reading' then
  S.register=slot;command_queue=R.program_order(S,slot);phase='commands';command_batch()
 elseif phase=='commands' then
  if not command_batch()then S.executing=nil;R.collect_phase(S);R.arms(S);R.belts(S,true);phase='express';conveyor_sound(true)end
 elseif phase=='express' then R.collect_phase(S);R.belts(S,false);phase='belts';conveyor_sound(false)
 elseif phase=='belts' then
   R.collect_phase(S);R.pushers(S,slot);phase='pushers';for _,p in ipairs(pushers) do if slot%2==p.q.parity then local d=R.dirs[p.q.dir+1];piston_stroke(p.o,vector.add(pos(p.q.x,p.q.z),{x=d.x*.9,y=0,z=d.z*.9}),true) end end
 elseif phase=='pushers' then
   R.plates(S);R.collect_phase(S)
   for _,p in ipairs(pushers) do if slot%2==p.q.parity then piston_stroke(p.o,pos(p.q.x,p.q.z),false)end end
   R.rotators(S);phase='rotators';for _,r in ipairs(rotors) do r.angle=r.angle+(r.turn==3 and 1 or -1)*math.pi/2;machine_pose(r.o,'yaw',r.angle) end
 elseif phase=='rotators' then R.robot_weapons(S,slot);phase='weapons'
 elseif phase=='weapons' then R.collect_phase(S);R.lasers(S);phase='lasers'
 elseif phase=='lasers' then
   R.hazards(S,slot);phase='presses';for _,p in ipairs(presses)do local active=slot%2==(p.parity or 0);if active then sound('crusher',pos(p.x,p.z),.4)end;machine_pose(p.o,'target',pos(p.x,p.z,active and 1 or 4.3))end
 elseif phase=='presses' then
   R.register_repairs(S);R.ghosts(S,true)
   for _,p in ipairs(presses) do if phase=='presses'and slot%2==(p.parity or 0)then sound('crusher_return',pos(p.x,p.z),.3)end;machine_pose(p.o,'target',pos(p.x,p.z,4.3)) end
   if S.puzzle and not S.winner then for _,b in ipairs(humans())do if S.puzzle.no_reboot and b.down then S.failed='Robot destroyed'end end;if not S.failed and slot==5 and S.puzzle.limit>0 and S.round>=S.puzzle.limit then S.failed='Round limit reached'end end
   if S.failed then execution_speed=1;destruction_pause=0;phase='finished';restore_cameras(true);if options.finished then options.finished(S)end
   elseif S.winner and (S.mode~='race'or R.race_complete(S))then
     execution_speed=1;destruction_pause=0;phase='finished';restore_cameras(true)
     if S.mode=='puzzle' and core.sound_play then for _,b in ipairs(humans(true))do core.sound_play('sc_puzzle_complete',{to_player=b.id,gain=.4},true)end end
     for _,b in ipairs(humans(true)) do
       if S.mode=='campaign' and bot(S.winner) and not bot(S.winner).enemy then
         store:set_int('progress:'..b.id,math.max(store:get_int('progress:'..b.id),math.min(3,S.level+1)))
         store:set_string('modules:'..b.id,core.serialize({range=b.range,blink=b.blink,draw_bonus=b.draw_bonus,parts=b.parts,archive_item=b.archive_item,weapon=b.weapon,aim_offset=b.aim_offset,enabled=b.enabled}))
       end
       players[b.id].notice=S.winner..' completed the route!'
     end
     if options.finished then options.finished(S) else for n in pairs(players) do menu(n) end end
   elseif slot<5 then slot=slot+1;phase='reading';for n in pairs(players)do if options.ui then options.ui(n,.95)end end
   else
     execution_speed=1;destruction_pause=0;R.repairs(S);R.respawn(S);S.round=S.round+1;R.ghosts(S,true);R.spawn_pickups(S);phase='program';planning_left=nil;restore_cameras(true)
     for name,v in pairs(players) do if v.joined and not bot(name) and #humans()<8 then spawn_robot(add_pilot(name,#humans()+1)) end end
     C.deal_round(S);for _,b in ipairs(S.bots) do b.energy=math.min(9,(b.energy or 0)+1);if S.mode=='tutorial' and not b.enemy then b.hand={'STEP','STEP','STEP','STEP','LEFT','LEFT','RIGHT','RIGHT','WAIT'}end end
     plan_round()
   end
 end
 for _,id in ipairs(S.finish_events or {})do local b=bot(id);if b and options.racer_finished then options.racer_finished(S,b)end end;S.finish_events={}
 sync();refresh()
end)
core.register_on_shutdown(cleanup)
-- Server-side extension API. Human input still passes through the same validators.
local api={
 snapshot=function() return {state=core.deserialize(core.serialize(S)),phase=phase,slot=slot,host=host,planning_left=planning_left} end,
 queue=function(name,index) local p=core.get_player_by_name(name);if p then edit(p,'queue',index) end end,
 commit=function(name) local p=core.get_player_by_name(name);if p then edit(p,'commit') end end,
 undo=function(name) local p=core.get_player_by_name(name);if p then edit(p,'undo') end end,
 start=function(name,mode,level)
   if name~=host or not players[name] or phase=='loading' then return false end
   if mode~='race' and mode~='campaign' and mode~='tutorial' then return false end
   level=math.floor(tonumber(level) or 1)
   if level<1 or (mode=='campaign' and level>math.max(1,store:get_int('progress:'..name))) or level>3 then return false end
   start_match(mode,level,false);return true
 end,
}



api.edit_level=function(data,play)
 execution_speed=1;destruction_pause=0
 planner.cancel();restore_cameras()
 S={size=data.size or 11,round=1,level=1,mode='race',board={},bots={},shots={},start=data.start}
 for _,key in ipairs({'board','walls','overhead','pickups','lasers','pushers','spawners','crates','enemies','start'})do S[key]=core.deserialize(core.serialize(data[key]or {}))end
 if play then
  if data.map_type=='puzzle'then S.mode='puzzle';S.puzzle=core.deserialize(core.serialize(data.puzzle));S.checkpoint_count=#S.puzzle.checkpoints;for _,t in pairs(S.board)do if t.kind=='checkpoint'then t.kind='save'end end;if S.start then S.board[R.key(S.start.x,S.start.z)]={kind='floor'}end;for i,key in ipairs(S.puzzle.checkpoints)do S.board[key]={kind='station',number=i}end
  else Q.number(R,S,math.min(3,9))end
  for name,v in pairs(players)do if v.joined then local b=add_pilot(name,1);b.x,b.z,b.dir=S.start.x,S.start.z,S.start.dir;b.home={x=b.x,z=b.z,dir=b.dir};if S.puzzle then b.hp=S.puzzle.hull;b.max_hp=R.hull_max;b.energy=S.puzzle.power;b.parts=core.deserialize(core.serialize(S.puzzle.equipment));b.weapon=S.puzzle.weapon;R.normalize(b)end end end
  R.init_objects(S);phase='program';R.spawn_pickups(S);C.deal_round(S);plan_round()
 else R.init_objects(S);phase='editor'end
 slot=0;planning_left=nil;build();sync();refresh()
end
api.watch=function(name)
 if not spectating(name)then return false end
 local p=core.get_player_by_name(name);if not p or not players[name]then return false end
 follow_camera(p);refresh();return true
end
api.watch_next=switch_watched
api.watching=function(name)local b=watched_bot(name);return spectating(name)and b and b.id or nil end

api.lab=function(name,scenario)
 if not options.test_lab or not core.get_player_privs(name).server then return false end
 if not players[name]then return false end
 local allowed={weapons=true,remote=true,arm=true,armor=true,spawners=true,factories=true}
 if not allowed[scenario]then return false end
 local data=dofile(path..'/levels.lua').blank(11);data.start={x=5,z=3,dir=0};data.pickups={};data.spawners={};data.board['9,9']={kind='checkpoint'}
 if scenario=='arm'then
  data.start={x=5,z=5,dir=0};data.board['5,6']={kind='checkpoint'};data.pickups['6,5']='cell';data.pickups['4,5']='shield';data.pickups['5,4']='repair'
  data.walls[R.edge(5,5,0)]=true;data.walls[R.edge(5,5,3)]=true
  for _,key in ipairs({'6,5','4,5','5,4'})do data.spawners[key]={first=2,every=1,chance=100}end
 elseif scenario=='armor'then data.overhead['5,3']={kind='crusher'}
 elseif scenario=='factories'then
  data.board['3,5']={kind='factory',dir=1,pattern='one',crate_kind='steel'};data.board['4,5']={kind='belt',dir=1,speed=1};data.overhead['5,5']={kind='crusher',parity=1};data.walls[R.edge(5,5,1)]=true
  data.board['3,8']={kind='factory',dir=1,pattern='opposite',crate_kind='loot'};data.board['2,8']={kind='belt',dir=3,speed=1};data.board['1,8']={kind='pit'}
  data.pickups['4,7']='cell';data.pickups['5,7']='shield';data.pushers={{x=4,z=7,dir=1,parity=1}};data.board['6,7']={kind='belt',dir=1,speed=1};data.board['7,7']={kind='pit'}
 elseif scenario=='spawners'then data.spawners={['5,4']={item='repair',rounds={1,2,5}},['6,3']={item='double_laser',first=1,every=2}}
 else data.walls[R.edge(7,5,0)]=true;data.lasers={{x=7,z=3,dir=0,power=3}}end
 api.edit_level(data,true);S.test_scenario=scenario;S.test_mode=true
 local b=bot(name);b.parts={blink=1,range=1,cache=1};for kind in pairs(R.part_items)do b.parts[kind]=2 end
 b.energy=9;b.enabled={holographic_memory=true,electroshield=scenario~='armor'};b.parts.titanium_hull=1;b.parts.mechanical_arm=scenario=='arm'and 3 or 1
 R.loadout(b,scenario=='remote'and 'remote_control'or 'repulsor_beam',0)
 if scenario=='weapons'or scenario=='remote'then
  S.bots[#S.bots+1]={id='TEST TARGET',enemy=true,kind='hunter',x=5,z=6,dir=2,hp=5,max_hp=5,energy=9,shield=0,next=99,home={x=5,z=6,dir=2},pattern={'WAIT','LEFT','RIGHT','WAIT','WAIT'},program={}}
 end
 C.deal_round(S);b.hand={'WAIT','WAIT','WAIT','WAIT','WAIT','STEP','LEFT','RIGHT','BACK'};plan_round();build();sync();if scenario=='arm'and players[name]then players[name].notice='ARM TEST / Wait to collect nearby supplies and reach the flag over the wall. Move east or south to test the folded mount.'end;refresh();return true
end
api.lab_refill=function(name)
 if not options.test_lab or not core.get_player_privs(name).server or phase~='program'then return false end
 local b=bot(name);if not b then return false end;b.hp=5;b.energy=9;for kind in pairs(R.part_items)do b.parts[kind]=math.max(2,b.parts[kind]or 0)end;sync();refresh();return true
end
api.takeover=function(name)
 local b=bot(name);if not b or b.enemy or S.mode~='race'then return false end
 b.enemy=true;b.racing=true;b.kind='racer';b.disconnected=true;b.difficulty=1
 -- Preserve committed commands and execution in progress; plan from this hand if uncommitted.
 if (phase=='program'or phase=='planning_ai')and not b.ready then plan_round()end
 return true
end
api.can_reclaim=function(name)local b=bot(name);return b and b.disconnected==true or false end
api.phase=function()return phase end
api.configure=function(board,ai_count,ai_mode,solo_config) options.board=board;options.ai_count=ai_count;options.ai_mode=ai_mode;options.solo_config=solo_config end
api.cleanup=function() planner.cancel();restore_cameras();cleanup() end
api.next=function() if phase=="finished" and S.mode=="campaign" and S.level<3 then start_match("campaign",S.level+1,true);return true end return false end
return api
end
