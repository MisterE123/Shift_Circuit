return function(core, options)
options=options or {}
local origin=options.origin or {x=0,y=0,z=0}
local function world(p) return {x=p.x+origin.x,y=p.y+origin.y,z=p.z+origin.z} end
local path=core.get_modpath('shift_circuit')
local RaceHUD=dofile(path..'/race_hud.lua');local Goal=dofile(path..'/goals.lua');local Q=dofile(path..'/courses.lua');local R=dofile(path..'/rules.lua');local C=dofile(path..'/campaign.lua');local store=core.get_mod_storage()
local Loadout=dofile(path..'/dashboard_ui.lua')(core,R)
local P=dofile(path..'/particles.lua')(core);local A=dofile(path..'/asset_textures.lua');local G=dofile(path..'/geometry.lua');local I=dofile(path..'/inspection.lua')
local S=C.setup(R,1,'campaign',options.board); local phase='loading';local slot,timer=0,0
local players,robots,props,belts,presses,pushers,rotors,pickups={},{},{},{},{},{},{},{}
local Systems;local visual;local spawn_pickup;local planning_left;local host;local duration=.85;local start_match,menu,refresh,build,refresh_menu,follow_camera,restore_cameras
local command_queue,command_index={},0
local phase_times={reading=.45,commands=.55,express=1.05,belts=1.05,pushers=1.05,rotators=.8,weapons=.65,lasers=.65,presses=.75}
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
local Styles=dofile(path..'/robot_styles.lua')
local function robot_texture(b,down)
 local base='sc_surface_'..Styles.model(b)..'.png'
 return base..(down and '^[multiply:#694e4b' or (b.racing and '^[multiply:#8cbcff' or (b.enemy and '^[multiply:#ef8c85' or '')))
end
local function humans(include_finished) local a={};for _,b in ipairs(S.bots) do if not b.enemy and (include_finished or not b.finished) then a[#a+1]=b end end;return a end
local function node(n,def) def.diggable=false;def.groups={unbreakable=1};core.register_node('shift_circuit:'..n,def) end
for _,n in ipairs({'apron','beam','pit','light'}) do node(n,{description=n,tiles={'sc_'..n..'.png'},light_source=n=='light' and 12 or 0}) end
node('collider',{description='Tile support',light_source=12,drawtype='airlike',pointable=false,walkable=true,paramtype='light',sunlight_propagates=true})
for _,kind in ipairs({'deck','dock1','dock2','dock3'}) do for dx=0,1 do for dz=0,1 do
  node(kind..dx..dz,{description='Factory surface',tiles={'sc_'..kind..dx..dz..'.png','sc_beam.png','sc_beam.png'},light_source=kind~='deck' and 4 or 0})
end end end
core.register_entity('shift_circuit:visual',{
 initial_properties={physical=false,pointable=false,visual='mesh',mesh='sc_robot.obj',textures={'sc_materials.png'},static_save=false,glow=0},
 on_step=function(self,dt)
   if self.ray_wave then local w=self.ray_wave;w.elapsed=w.elapsed+dt;local t=(w.elapsed/.65+w.offset)%1;if w.kind=='tractor_beam'then t=1-t end;self.object:set_pos({x=w.origin.x+w.dir.x*w.length*t,y=w.origin.y,z=w.origin.z+w.dir.z*w.length*t});local size=w.kind=='remote_control'and .7 or (.6+.6*t);self.object:set_properties({visual_size={x=size,y=size,z=size}})end
   if self.system_parent then Systems.step(self,dt);return end
   if self.system_actor then Systems.tick_actor(self,dt)end
   if self.life then self.life=self.life-dt;if self.life<=0 then self.object:remove();return end end
   if self.fall then
    local f=self.fall;f.elapsed=math.min(1,f.elapsed+dt);local slide=math.min(1,f.elapsed/.25);slide=slide*slide*(3-2*slide)
    local drop=math.max(0,(f.elapsed-.18)/.82)
    self.object:set_pos({x=f.from.x+(f.to.x-f.from.x)*slide,y=f.from.y+(f.to.y-f.from.y)*slide-5.5*drop*drop,z=f.from.z+(f.to.z-f.from.z)*slide})
    self.object:set_yaw(f.yaw+.35*drop)
    if f.elapsed>=1 then self.fall=nil;self.fallen=true;self.object:set_properties({is_visible=false,pointable=false})end
    return
   elseif self.fallen then return end
   if self.achievement then
     self.achievement=self.achievement+dt;local t=self.achievement/1.3
     if t>=1 then self.object:remove();return end
     self.object:set_pos({x=self.origin.x,y=self.origin.y+1+t*1.5,z=self.origin.z});self.object:set_properties({visual_size={x=.8*(1-t*.65),y=.8*(1-t*.65)}});return
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
     self.object:set_pos({x=c.origin.x,y=c.origin.y+t*1.3,z=c.origin.z});self.object:set_properties({visual_size={x=scale,y=scale,z=scale}})
     if t>=1 then self.object:remove() end;return
   end
   if self.hydraulic then
     local p=self.hydraulic:get_pos();if p then self.object:set_pos({x=p.x,y=p.y+.125,z=p.z});self.object:set_properties({visual_size={x=1,y=math.max(.1,origin.y+4.875-p.y-.125),z=1}}) end
   elseif self.follow_object then
     local p=self.follow_object:get_pos()
     if p then
      local actor=self.follow_object:get_luaentity();if actor and (actor.fall or actor.fallen)then p.y=origin.y+1 end
      local angle=self.orbit_angle or 0;local delta=((self.orbit_target or angle)-angle+math.pi)%(math.pi*2)-math.pi
      if math.abs(delta)>.001 then angle=angle+delta*math.min(1,dt*9);self.orbit_angle=angle end
      local location,radius=orbit_position(p,angle);self.object:move_to(location,true)
      local viewer=self.orbit_owner and core.get_player_by_name(self.orbit_owner)
      if viewer and math.abs(delta)>.001 then viewer:set_look_horizontal(angle);viewer:set_look_vertical(math.atan(8/radius))end
     end
   elseif self.belt and (inspecting() or phase=='belts' or (phase=='express' and self.speed==2)) then
     self.travel=(self.travel+dt/duration*(self.speed or 1)*(inspecting() and .5 or 1))%1
     if self.curve_model then
       local frame=math.floor((self.travel*10)%1*24);if frame~=self.frame then self.frame=frame;self.object:set_properties({mesh='sc_tread_'..self.curve_model..'_'..frame..'.obj'}) end
     else
       local q,yaw=G.belt(self.track,self.travel)
       self.object:set_pos({x=self.origin.x+q.x,y=self.origin.y,z=self.origin.z+q.z});self.object:set_yaw(yaw)
     end
   elseif self.hover then self.clock=(self.clock or 0)+dt*(inspecting() and .5 or 1);local p=vector.new(self.origin);p.y=p.y+math.sin(self.clock*2)*.12;self.object:set_pos(p);self.object:set_yaw(self.clock*.7)
   elseif self.motion then
     local m=self.motion;m.elapsed=math.min(m.total,m.elapsed+dt);local t=m.elapsed/m.total;t=t*t*(3-2*t)
     self.object:set_pos(vector.add(m.from,vector.multiply(vector.subtract(m.to,m.from),t)));if m.elapsed>=m.total then self.motion=nil end
   elseif self.target then self.object:set_pos(vector.add(self.object:get_pos(),vector.multiply(vector.subtract(self.target,self.object:get_pos()),math.min(1,dt*9)))) end
   if self.pusher_rod then local anchor,length=G.pusher_rod(self.pusher_base,self.object:get_pos(),self.pusher_dir);self.pusher_rod:set_pos(anchor);self.pusher_rod:set_properties({visual_size={x=1,y=1,z=length}})end
   if self.yaw then local a=self.object:get_yaw();local diff=(self.yaw-a+math.pi)%(math.pi*2)-math.pi;self.object:set_yaw(a+diff*math.min(1,dt*(self.robot and 3 or 10))) end
 end,
})
visual=function(mesh,p,extra)
 local o=core.add_entity(p,'shift_circuit:visual');if not o then return end
 o:set_properties({mesh='sc_'..mesh..'.obj',textures={A[mesh] or 'sc_materials.png'}});if extra then o:set_properties(extra) end;props[#props+1]=o;return o
end
Systems=dofile(path..'/systems_visual.lua')(R,G,visual)
local function clear_preview() for _,o in ipairs(preview_beams) do if o:get_pos() then o:remove() end end;preview_beams={};preview_refresh=0 end
local function cleanup() home_markers={};clear_preview();for _,o in ipairs(props) do if o:get_pos() then o:remove() end end;props={};robots={};belts={};presses={};pushers={};rotors={};pickups={} end
local function inspect_animation(dt)
 preview_clock=preview_clock+dt;preview_refresh=preview_refresh+dt
 local stroke=(1-math.cos(preview_clock*math.pi/duration))*.25
 for _,p in ipairs(presses) do p.o:get_luaentity().target=pos(p.x,p.z,4.3-stroke*3.3) end
 for _,p in ipairs(pushers) do local d=R.dirs[p.q.dir+1];p.o:get_luaentity().target=vector.add(pos(p.q.x,p.q.z),{x=d.x*.9*stroke,y=0,z=d.z*.9*stroke}) end
 for _,r in ipairs(rotors) do r.o:get_luaentity().yaw=r.angle+preview_clock*(r.turn==3 and 1 or -1)*math.pi/(4*duration) end
 if preview_refresh>=.3 or #preview_beams==0 then
   preview_refresh=0;local rays={};local index=0
   for _,q in ipairs(S.lasers or {}) do local x,z=R.laser_source(q);rays[#rays+1]={x=x,z=z,dir=q.dir,power=q.power,range=R.fixed_laser_range(S,q)}end
   for _,b in ipairs(S.bots)do if (S.round or 1)>1 and not b.down and not b.ghost and not b.finished then R.normalize(b);for _,mount in ipairs({'weapon'})do local kind=b.weapon;if kind then rays[#rays+1]={x=b.x,z=b.z,dir=R.aim(b,mount),power=R.weapons[kind].power or 1,range=b.range or 4,owner=b,kind=kind,mount=mount}end end end end
   for _,q in ipairs(rays) do
     local length,_,wall=R.trace(S,q.x,q.z,q.dir,q.range or R.fixed_laser_range(S,q),q.owner);local d=R.dirs[q.dir+1]
     for i=1,q.power do
       local p,beam_length=G.beam(q.x,q.z,q.dir,q.power,i,length,q.owner~=nil,q.mount,q.kind,q.owner and q.owner.dir);if wall then beam_length=math.max(0,beam_length-.065)end;p=world(p)
       -- Preview entities are managed separately: no damage, shots, particles,
       -- or unbounded append to the scene's persistent object list.
       index=index+1;local o=preview_beams[index]
       if not o then o=core.add_entity(p,'shift_circuit:visual');preview_beams[index]=o end
       if o then
         local tint=q.owner and (({remote_control='#625078',tractor_beam='#356b80',repulsor_beam='#805932'})[q.kind]or '#327464')or '#804232';local e=o:get_luaentity()
         if e.preview_length~=length or e.preview_tint~=tint then o:set_properties({mesh='sc_beam.obj',visual_size={x=1,y=1,z=beam_length},glow=7,use_texture_alpha=true,backface_culling=true,textures={'sc_beam_alpha.png^[multiply:'..tint}});e.preview_length=length;e.preview_tint=tint end
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
   sound('laser',pos(s.x,s.z),s.weapon and .25 or .4,s.weapon and 1.15 or 1)
   local d=R.dirs[s.dir+1];local power=s.power or 1
   for i=1,power do
     local p,beam_length=G.beam(s.x,s.z,s.dir,power,i,s.range,s.weapon==true,s.mount,s.kind,s.body_dir);if s.wall then beam_length=math.max(0,beam_length-.065)end;p=world(p)
     local o=visual('beam',p,{visual_size={x=1,y=1,z=beam_length},glow=14,use_texture_alpha=true,backface_culling=true,textures={'sc_beam_alpha.png^[multiply:'..(s.weapon and (({remote_control='#be9cf5',tractor_beam='#66d9ff',repulsor_beam='#ffb466'})[s.kind]or '#64e8c8')or '#ff8464')}})
     o:set_yaw(G.yaw(s.dir));o:get_luaentity().life=.65
     local tip={x=p.x+d.x*beam_length,y=p.y,z=p.z+d.z*beam_length}
     if s.hit then P.emit(({remote_control='control',tractor_beam='pull',repulsor_beam='push'})[s.kind]or 'impact',tip)end
     if s.kind and not R.weapons[s.kind].power then
      for j=0,3 do local wave=visual(s.kind=='remote_control'and 'ray_packet'or 'ray_ring',p,{pointable=false,glow=10,use_texture_alpha=true,textures={'sc_beam_alpha.png^[multiply:'..(({remote_control='#be9cf5',tractor_beam='#66d9ff',repulsor_beam='#ffb466'})[s.kind])}});wave:set_yaw(G.yaw(s.dir));wave:get_luaentity().life=.65;wave:get_luaentity().ray_wave={origin=p,dir=d,length=beam_length,kind=s.kind,offset=j/4,elapsed=0}end
     end
   end
 end
 S.shots={}
end
local function sync_fall(b,o)
 if not o then return end;local e=o:get_luaentity()
 if b.down and b.destroyed_by=='Fell into a pit'then
  if not e.fall and not e.fallen then e.fall={from=o:get_pos(),to=pos(b.x,b.z,1),elapsed=0,yaw=o:get_yaw()}end
  e.motion=nil;e.target=nil;e.yaw=nil
  local scale=e.display_scale or 1;o:set_properties({is_visible=not e.fallen,pointable=false,nametag='',textures={robot_texture(b,false)},visual_size={x=scale,y=scale,z=scale}})
 elseif e.fall or e.fallen then
  e.fall=nil;e.fallen=nil;e.motion=nil;e.target=nil;e.destination=e.destination or pos(b.x,b.z,1);o:set_pos(e.destination)
  local scale=e.display_scale or 1;o:set_properties({is_visible=not b.finished,pointable=true,visual_size={x=scale,y=scale,z=scale},textures={robot_texture(b,false)}})
 end
end
local function sync()
 if spawn_pickup then for key,kind in pairs(S.pickups or {})do if not pickups[key]then spawn_pickup(key,kind)end end end
 for _,event in ipairs(S.spawn_events or {})do local x,z=event.key:match('(%d+),(%d+)');P.emit('pickup',pos(tonumber(x),tonumber(z)));sound('pickup',pos(tonumber(x),tonumber(z)),.18,.75)end;S.spawn_events={}
 R.ghosts(S)
 for _,b in ipairs(S.bots) do
   local o=robots[b.id]
   if o then
     local e=o:get_luaentity();local dest=pos(b.x,b.z,b.down and .7 or 1)
     if b.ghost then
      local group={};for _,other in ipairs(S.bots)do if other.ghost and other.x==b.x and other.z==b.z then group[#group+1]=other.id end end;table.sort(group)
      local index=1;for i,id in ipairs(group)do if id==b.id then index=i end end
      local angle=(index-1)*2*math.pi/#group;dest.x=dest.x+math.cos(angle)*.9;dest.z=dest.z+math.sin(angle)*.9;dest.y=dest.y+3.0
      if not e.ghost_marker then e.ghost_marker=visual('ghost_cone',pos(b.x,b.z,1.05),{textures={'sc_ghost.png'},glow=5,pointable=false,use_texture_alpha=true})end
      local tip=pos(b.x,b.z,3.0);local dx,dz=dest.x-tip.x,dest.z-tip.z;local dy=dest.y-.25-tip.y;local horizontal=math.sqrt(dx*dx+dz*dz)
      e.ghost_marker:set_pos(tip);e.ghost_marker:set_properties({visual_size={x=.8,y=.8,z=math.sqrt(horizontal*horizontal+dy*dy)}})
      if e.ghost_marker.set_rotation then e.ghost_marker:set_rotation({x=math.atan2(dy,horizontal),y=-math.atan2(dx,dz),z=0})end

     elseif e.ghost_marker then e.ghost_marker:remove();e.ghost_marker=nil end
     if o.set_observers then
      local observers={};for name in pairs(players)do if name~=b.id then observers[name]=true end end
      o:set_observers(observers);if e.ghost_marker then e.ghost_marker:set_observers(observers)end
      if players[b.id]then
       local ownpos=pos(b.x,b.z,b.down and .7 or 1)
       if not e.owner_view then e.owner_view=visual(Styles.model(b),ownpos,{textures={robot_texture(b,b.down)},nametag=''});e.owner_view:set_observers({[b.id]=true});e.owner_view:get_luaentity().destination=ownpos end
       local own=e.owner_view;local oe=own:get_luaentity()
       if oe.destination.x~=ownpos.x or oe.destination.z~=ownpos.z or oe.destination.y~=ownpos.y then oe.motion={from=own:get_pos(),to=ownpos,elapsed=0,total=math.max(.35,phase_time()-.15)};oe.destination=ownpos end
       oe.yaw=G.yaw(b.dir);own:set_properties({textures={robot_texture(b,b.down)},visual_size={x=1,y=b.down and .3 or 1,z=1}})
      end
     end
     e.display_scale=b.ghost and .5 or 1
     if e.ghost~=not not b.ghost then if b.ghost then o:set_pos(dest);e.destination=vector.new(dest);e.motion=nil;e.target=nil end;e.ghost=not not b.ghost;o:set_properties({visual_size=b.ghost and {x=.5,y=.5,z=.5}or{x=1,y=b.down and .3 or 1,z=1}})end
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
     if e.last_dir and e.last_dir~=b.dir and phase~='commands' then sound('turn',dest,.18,.9)end;e.last_dir=b.dir
     if e.last_shield and (b.shield or 0)<e.last_shield then sound('shield',dest,.4);P.emit('shield',dest)end;e.last_shield=b.shield or 0
     if e.electro_serial~=(b.electro_serial or 0)then if e.electro_serial then P.emit('shield',dest);sound('shield',dest,.4)end;e.electro_serial=b.electro_serial or 0 end
     if e.titanium_serial~=(b.titanium_serial or 0)then if e.titanium_serial then P.emit('armor',dest);sound('impact',dest,.55,.6)end;e.titanium_serial=b.titanium_serial or 0 end
     if e.last_hp and b.hp>e.last_hp then P.emit('repair',dest);sound('pickup',dest,.35,1.2)end
     if e.last_hp and b.hp<e.last_hp and not b.down then sound('impact',dest,.55);P.emit('damage',dest) end;e.last_hp=b.hp
     if e.last_checkpoint and b.next>e.last_checkpoint then
       if home_markers[b.id]then home_markers[b.id]:remove()end
       local markpos=pos(b.home.x,b.home.z,.72);markpos.x=markpos.x+.62
       local marker=visual('arrow_forward',markpos,{visual_size={x=.4,y=1,z=.4},glow=5,backface_culling=false});marker:set_yaw(G.yaw(b.home.dir or 0));home_markers[b.id]=marker
       I.describe(marker,'Reboot direction','Saved facing direction at this checkpoint.',{-.3,-.21,-.3,.3,-.17,.3})
       local badge=visual('tile',o:get_pos(),{visual='sprite',textures={'sc_checkpoint_'..math.min(S.checkpoint_count or 3,b.next-1)..'.png'},visual_size={x=.8,y=.8},glow=10})
       badge:get_luaentity().achievement=.001;badge:get_luaentity().origin=o:get_pos();sound('success',o:get_pos(),.35,1.2);P.emit('checkpoint',o:get_pos())
     end;e.last_checkpoint=b.next
     e.yaw=G.yaw(b.dir)
     if e.was_down~=not not b.down then
       if e.was_down and not b.down then sound('blink',dest,.3,.85);P.emit('reboot',dest)end
       e.was_down=not not b.down
       o:set_properties({is_visible=true,visual_size=b.ghost and {x=.5,y=.5,z=.5} or {x=1,y=b.down and .3 or 1,z=1},textures={robot_texture(b,b.down)},nametag=b.id..(b.down and ' / DESTROYED' or ''),nametag_color=b.down and '#ff7755' or '#94e3cf'})
       if b.down then
         sound('destroy',dest,.65,b.destroyed_by=='Fell into a pit' and .65 or (b.destroyed_by=='CRUSHED by crusher' and .8 or 1))
         P.emit(b.destroyed_by=='Fell into a pit'and 'fall'or (b.destroyed_by=='CRUSHED by crusher' and 'crush' or 'destroy'),dest)
       end
     end
   end
   if o then Systems.sync(b,o);o:get_luaentity().hint=(b.enemy and 'Robot: 'or 'Pilot: ')..b.id..'\n'..Systems.hint(b);local own=o:get_luaentity().owner_view;if own then own:get_luaentity().display_scale=1;Systems.sync(b,own);own:get_luaentity().hint=o:get_luaentity().hint;own:set_properties({pointable=true,selectionbox={-.65,-.5,-.5,.65,1.7,.5}})end end
   if o then sync_fall(b,o);sync_fall(b,o:get_luaentity().owner_view)end
   if o and b.finished then o:set_properties({is_visible=false});local e=o:get_luaentity();if e.owner_view then e.owner_view:set_properties({is_visible=false})end end
   if b.collected then if players[b.id] then players[b.id].notice='COLLECTED / '..b.collected:upper() end;b.collected=nil end
 end
 local reach_delays={}
 for _,reach in ipairs(S.reaches or {})do local actor=robots[reach.robot];local target=pos(reach.x,reach.z,1.45)
  local e=actor and actor:get_luaentity();reach_delays[reach.robot..':'..R.key(reach.x,reach.z)]=.3+(e and #(e.reach_queue or {})or 0)*.6
  Systems.reach(actor,target);if actor and actor:get_luaentity().owner_view then Systems.reach(actor:get_luaentity().owner_view,target)end;if reach.checkpoint then P.emit('checkpoint',target)end
 end;S.reaches={}
 for _,c in ipairs(S.collections or {}) do local o=pickups[c.key];if o then o:get_luaentity().collecting={origin=o:get_pos(),robot=robots[c.robot],delay=c.arm and (reach_delays[c.robot..':'..c.key]or .3)or 0};o:set_properties({pointable=false,nametag=''});pickups[c.key]=nil end end;S.collections={}
 shots()
end
local function camera(p,mode)
 local v=players[p:get_player_name()];v.camera=mode
 -- Native client prediction owns locomotion. Never stream set_pos corrections.
 local privs=core.get_player_privs(p:get_player_name());privs.fly=mode=='fly' or nil;core.set_player_privs(p:get_player_name(),privs)
 p:set_physics_override({speed=1.2,jump=1,gravity=1})
 if mode=='walk' then p:set_pos(world({x=12,y=1,z=-2}));p:set_look_horizontal(0);p:set_look_vertical(.12)
 else p:set_pos(world({x=12.5,y=18,z=-4}));p:set_look_horizontal(0);p:set_look_vertical(.8);v.notice='Use K to enter flight mode' end
end
follow_camera=function(p)
 local name=p:get_player_name();local v=players[name];if not v or v.return_view then return end
 local target=not (bot(name)and bot(name).finished)and robots[name]or nil;if target and target:get_luaentity().owner_view then target=target:get_luaentity().owner_view end;if not target then local h=humans()[1];if not h then for _,candidate in ipairs(S.bots)do if not candidate.finished then h=candidate;break end end end;target=h and robots[h.id] end
 if not target then return end
 v.return_view={pos=vector.new(p:get_pos()),yaw=p:get_look_horizontal(),pitch=p:get_look_vertical(),fov=p:get_fov()}
 local angle=v.orbit_angle or 0;local location,radius=orbit_position(target:get_pos(),angle)
 local o=visual('robot',location,{is_visible=false})
 local e=o:get_luaentity();e.follow_object=target;e.orbit_owner=name;e.orbit_angle=angle;e.orbit_target=angle;v.follow=o
 p:set_attach(o,'',{x=0,y=0,z=0},{x=0,y=0,z=0});p:set_look_horizontal(angle);p:set_look_vertical(math.atan(8/radius));p:set_fov(60,false,.35)
end
restore_cameras=function(above_robot)
 for name,v in pairs(players) do
   local p=core.get_player_by_name(name);local saved=v.return_view
   if saved and p then p:set_detach();local b=bot(name);if above_robot and b then p:set_pos(pos(b.x,b.z,7));p:set_look_vertical(math.pi/2)else p:set_pos(saved.pos);p:set_look_horizontal(saved.yaw);p:set_look_vertical(saved.pitch)end;p:set_fov(saved.fov or 65,false,.35)end
   if v.follow and v.follow:get_pos() then v.follow:remove() end
   v.return_view=nil;v.follow=nil
 end
end
local card_names={MOVE3='MOVE 3',BACK2='BACK 2',UTURN='U-TURN'}
local function inventory(p,b)
 local inv=p:get_inventory();inv:set_size('main',13);local a={}
 if phase=='editor'then inv:set_list('main',{'shift_circuit:editor_brush','shift_circuit:editor_rotate'});p:hud_set_hotbar_itemcount(2);return end
 local v=players[p:get_player_name()];if v and v.follow and not inspecting()then inv:set_list('main',{ItemStack('shift_circuit:orbit_left'),ItemStack('shift_circuit:orbit_right')});p:hud_set_hotbar_itemcount(2);return end
 local commit=ItemStack('shift_circuit:commit');local state=b and b.ready and 'locked' or (b and phase=='program' and #(b.program or {})==5 and 'ready' or 'disabled')
 commit:get_meta():set_string('inventory_image','sc_commit_'..state..'.png')
 commit:get_meta():set_string('description',state=='ready' and 'COMMIT / Left-click to run your program' or (state=='locked' and 'COMMITTED / Waiting for execution' or 'COMMIT / Queue five cards first'))
 if phase=='lobby' then commit=ItemStack('shift_circuit:start');commit:get_meta():set_string('description','START GAME / Left-click to open the start menu') end
 a[1]=commit
 if b then for i,c in ipairs(b.hand or {}) do
   local used=false;for _,h in ipairs(b.selected or {}) do if h==i then used=true end end
   local stack=ItemStack('shift_circuit:card_'..c:lower());local m=stack:get_meta();m:set_int('index',i);m:set_string('inventory_image',card_image(c,(b.hand_ids or {})[i]))
   m:set_string('description',(card_names[c]or c)..' / Priority ID '..((b.hand_ids or {})[i]or 0)..(c=='DASH' and ' / Drive through 2 squares; push and collect along the path' or (c=='BLINK' and ' / Jump 2 squares; skip the middle; safe empty landing; 1 energy' or ''))..(used and ' / QUEUED' or ' / Left-click to queue'))
   if used then m:set_string('inventory_image',card_image(c,(b.hand_ids or {})[i])..'^[multiply:#48535d')end
   for _,kept in ipairs(b.keep or {})do if kept==i then m:set_string('inventory_image',card_image(c,(b.hand_ids or {})[i])..'^sc_kept.png');m:set_string('description',(card_names[c]or c)..' / RETAIN NEXT ROUND')end end
   a[i+1]=(c=='BLINK'and b.blink_left==0)and ItemStack('')or stack
 end end
 inv:set_list('main',a);p:hud_set_hotbar_itemcount(1+(b and math.max(5,#(b.hand or {})) or 9))
end
local help={MOVE3='Advance 3 squares / walls stop movement; pits are dangerous',BACK2='Reverse 2 squares / keep your facing',UTURN='Turn around 180 degrees',STEP='Advance 1 tile',DASH='Drive 2 squares / push robots / collect along the path',BACK='Reverse 1 tile',LEFT='Turn left',RIGHT='Turn right',WAIT='Hold position',PULSE='Fire 1 beam / costs 1 energy',BLINK='Jump 2 squares / skip the middle / safe empty landing / 1 energy'}
local function update_hud(name)
 local p=core.get_player_by_name(name);local v=players[name];if not p or not v then return end;local b=bot(name)
 if phase=='editor'then
  if not v.editor_hidden then for _,id in ipairs(v.hud_ids)do p:hud_change(id,'text','')end;v.editor_hidden=true end
  return
 elseif v.editor_hidden then
  for id,text in pairs(v.hud_texts)do p:hud_change(id,'text',text)end;v.editor_hidden=nil
 end
 local phase_icon=({reading=1,commands=1,express=2,belts=3,pushers=4,rotators=5,weapons=6,lasers=7,presses=8})[phase]or 0
 p:hud_change(v.phase_order,'text',(phase=='editor'or phase=='lobby'or phase=='loading')and ''or 'sc_phase_order_'..phase_icon..'.png')
 local owner_actor=robots[name];local owner_view=owner_actor and owner_actor:get_luaentity().owner_view
 local own_position=(owner_view or owner_actor)and (owner_view or owner_actor):get_pos()
 p:hud_change(v.own_marker,'text',b and not b.finished and own_position and 'sc_your_robot.png'or '')
 if own_position then p:hud_change(v.own_marker,'world_pos',b and b.down and pos(b.x,b.z,2.9)or {x=own_position.x,y=own_position.y+1.9,z=own_position.z})end
 local rows=RaceHUD.rows(S,phase);local visible=phase~='editor'and phase~='lobby'and phase~='loading'
 p:hud_change(v.racer_header,'text',visible and #rows>0 and 'sc_racer_header.png'or '')
 for i=1,8 do local row=visible and rows[i];local h=v.racers[i]
  p:hud_change(h.bg,'text',row and (row.id==name and 'sc_racer_row_self.png'or 'sc_racer_row.png')or '')
  p:hud_change(h.name,'text',row and ((row.id==name and 'YOU / 'or (row.human and ''or 'AI / '))..row.id:sub(1,row.id==name and 11 or 13))or '')
  p:hud_change(h.name,'number',row and row.id==name and 0xefc56e or (row and row.human and 0xade1d5 or 0x9fbbea))
  p:hud_change(h.progress,'text',row and ('sc_racer_'..(row.rank and 'place_'..row.rank or 'cp_'..row.checkpoint)..'.png')or '')
  p:hud_change(h.status,'text',row and 'sc_racer_'..row.status..'.png'or '')
 end
 local goal=Goal.current(S,b,phase);p:hud_change(v.goal,'text',goal.texture)
 p:hud_change(v.goal_marker,'text',goal.x and 'sc_goal_marker.png' or '')
 if goal.x then p:hud_change(v.goal_marker,'world_pos',pos(goal.x,goal.z,2.7))end
 local title=phase=='lobby' and 'READY TO PLAY / Select START GAME and left-click' or (phase=='program' and 'PROGRAM / Queue five cards, then use COMMIT' or (phase=='finished' and 'ROUTE COMPLETE / I for the next mission' or ('PULSE '..slot..' / '..(phase=='presses' and 'CRUSHERS' or (phase=='planning_ai' and 'OPPONENTS PROGRAMMING' or phase:upper())))))
 if phase=='commands'and S.executing then local acting=bot(S.executing);title=title..' / '..S.executing..' / Priority ID '..R.priority(acting,slot)end
 if phase=='program' and planning_left then title=title..' / '..math.ceil(planning_left)..'s' end
 p:hud_change(v.title,'number',phase=='program' and planning_left and planning_left<=10 and 0xff947b or 0x94e3cf)
 p:hud_change(v.title,'text','SHIFT CIRCUIT   /   '..(S.mode=='campaign' and C.missions[S.level].title or (S.mode=='tutorial' and 'TUTORIAL / '..(({'Drive to flag 1','Turn right; collect the shield','Turn left; reach flag 3'})[b and b.next or 1] or 'Complete') or 'RACE / ROUND '..S.round))..'\n'..title..(S.objective_collect and ('\n'..S.objective) or ''))
 local values={energy=b and b.energy or 0,shield=b and b.shield or 0,hull=b and not b.down and math.max(0,b.hp or 0) or 0,hand=b and b.allowance or 0,jam=b and b.disruption or 0,route=b and math.min(S.checkpoint_count or 3,b.next-1) or 0,modules=(b and (b.blink_left or 0)>0 and 1 or 0)+(b and (b.range or 4)>4 and 2 or 0)}
 for kind,id in pairs(v.gauges) do p:hud_change(id,'text','sc_stat_'..(kind=='route' and ('route_'..(S.checkpoint_count or 3))or kind)..'_'..values[kind]..'.png') end
 p:hud_change(v.controls,'text',inspecting() and 'Use K to enter flight mode / Z: go to your robot / I: inventory\nWheel: select / E: retain / Left-click: queue or COMMIT / Right-click: undo' or 'EXECUTION CAMERA / Following your robot\n1 or 2: select orbit tool / Click: rotate / Round ends above your robot')
 for i=1,5 do
   local c=b and b.program[i];p:hud_change(v.slots[i],'text',c and card_image(c,R.priority(b,i)) or 'sc_emptycard.png')
   local reading=phase=='reading' and i==slot
   local progress=math.min(1,timer/phase_time())
   local scale=1
   p:hud_change(v.slots[i],'scale',{x=scale,y=scale})
   p:hud_change(v.slots[i],'offset',{x=(i-3)*76,y=30+(reading and (2+2*math.floor(3*math.sin(progress*math.pi))) or 0)})
   if b and b.remote_slots and b.remote_slots[i]and c then p:hud_change(v.slots[i],'text',card_image(c,R.priority(b,i))..'^sc_remote_overlay.png')end
   if i==slot and not inspecting() and c then p:hud_change(v.slots[i],'text',card_image(c,R.priority(b,i))..'^sc_hotbar_selected.png') end
   p:hud_change(v.labels[i],'text','sc_register_'..i..(phase~='program' and phase~='lobby' and i==slot and '_active' or '')..'.png')
   p:hud_change(v.priorities[i],'text',c and priority_label(R.priority(b,i))or '')
 end
 p:hud_change(v.pointed,'text',I.pointed(core,p,9))
 local c=b and b.hand and b.hand[p:get_wield_index()-1]
 p:hud_change(v.destruction,'text',b and b.down and ('ROBOT DESTROYED / '..(b.destroyed_by or 'Damage')..'\nRebooting after this round') or '')
 local notice=(b and b.remote_from and ('REMOTE CONTROL / Program copied from '..b.remote_from))or v.notice or '';if phase=='program' and planning_left then notice=(planning_left<=10 and 'TIME RUNNING OUT / ' or '')..'Empty slots will be filled randomly from your remaining cards.' end
 p:hud_change(v.detail,'text',(v.follow and not inspecting())and ('ORBIT '..(p:get_wield_index()==2 and 'RIGHT'or 'LEFT')..' / Left-click to rotate around your robot')or notice..'\n'..(p:get_wield_index()==1 and (phase=='lobby' and 'START GAME / Left-click to choose a campaign or race' or 'COMMIT / Left-click to lock in your five-card program') or (c and (card_names[c]or c)..' / Priority ID '..((b.hand_ids or {})[p:get_wield_index()-1]or 0)..' / '..help[c] or 'Select a command card')))
end
refresh=function() for name in pairs(players) do local p=core.get_player_by_name(name);if p then inventory(p,bot(name));update_hud(name);if refresh_menu then refresh_menu(p) end end end end
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
 for _,p in ipairs(presses) do p.o:get_luaentity().target=pos(p.x,p.z,4.3) end
 for _,p in ipairs(pushers) do p.o:get_luaentity().target=pos(p.q.x,p.q.z) end
 for _,r in ipairs(rotors) do r.o:get_luaentity().yaw=r.angle end
 planning_left=nil;phase='reading';slot=1;timer=0
 for _,b in ipairs(humans()) do b.last_program={};for i,c in ipairs(b.program) do b.last_program[i]=c end end
 for name in pairs(players) do local p=core.get_player_by_name(name);if p then follow_camera(p) end end
 sync();refresh()
end
local function edit(p,action,index)
 local name=p:get_player_name();local b=bot(name);local v=players[name]
 if not b or b.finished or phase~='program' or b.ready then return end
 if action=='queue' then
   if not b.hand[index] then return end
   if #b.selected>=5 then v.notice='Program is full / undo a card first';if options.ui then options.ui(name,.65)end;update_hud(name);return end
   for _,i in ipairs(b.selected) do if i==index then v.notice='This card is already queued';if options.ui then options.ui(name,.65)end;update_hud(name);return end end
   b.selected[#b.selected+1]=index;b.program[#b.program+1]=b.hand[index];b.program_ids=b.program_ids or {};b.program_ids[#b.program]=(b.hand_ids or {})[index]
 elseif action=='undo' then table.remove(b.selected);table.remove(b.program);table.remove(b.program_ids or {})
 elseif action=='clear' then b.selected={};b.program={};b.program_ids={}
 elseif action=='commit' then
   if #b.program<5 then v.notice='Choose five cards before committing';if options.ui then options.ui(name,.65)end;update_hud(name);return end
   b.ready=true
 end
 if options.ui then options.ui(name,action=='commit' and 1.25 or (action=='undo' and .85 or 1))end
 v.notice='';refresh();if all_ready() then begin() end
end
for _,c in ipairs({'STEP','DASH','MOVE3','BACK','BACK2','LEFT','RIGHT','UTURN','WAIT','PULSE','BLINK'}) do
 core.register_tool('shift_circuit:card_'..c:lower(),{description=(card_names[c]or c)..(c=='DASH' and ' / Drive through two squares; pushes robots and collects along the path. Walls block; pits are dangerous.' or (c=='BLINK' and ' / Jump two squares, skipping the first. Safe empty landing required; costs one energy.' or '')),inventory_image='sc_card_'..c..'.png',stack_max=1,
 on_use=function(stack,p) edit(p,'queue',stack:get_meta():get_int('index')) end,
 on_secondary_use=function(stack,p) edit(p,'undo') end,
 on_place=function(stack,p) edit(p,'undo') end,
 on_drop=function(stack) return stack end})
end
core.register_tool('shift_circuit:commit',{description='COMMIT / Queue five cards, select this tool, then left-click',inventory_image='sc_commit_disabled.png',stack_max=1,
 on_use=function(_,p) edit(p,'commit') end,
 on_secondary_use=function(_,p) edit(p,p:get_player_control().sneak and 'clear' or 'undo') end,
 on_place=function(_,p) edit(p,p:get_player_control().sneak and 'clear' or 'undo') end,
 on_drop=function(stack) return stack end})
for _,choice in ipairs({{'left',-1},{'right',1}})do
 local direction=choice[2];local function orbit(stack,p)
  local v=players[p:get_player_name()];if v and v.follow and not inspecting()then
   local e=v.follow:get_luaentity();e.orbit_target=(e.orbit_target or 0)+direction*math.pi/4;v.orbit_angle=e.orbit_target
  end;return stack
 end
 core.register_tool('shift_circuit:orbit_'..choice[1],{description='ORBIT '..choice[1]:upper()..' / Left-click to rotate your execution camera',inventory_image='sc_orbit_'..choice[1]..'.png',on_use=orbit,on_secondary_use=orbit,on_place=orbit,on_drop=function(stack)return stack end})
end
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
local function spawn_robot(b)
 local o=visual(Styles.model(b),pos(b.x,b.z),{nametag=b.id,nametag_color=b.enemy and '#ff8d7b' or '#94e3cf'})
 o:get_luaentity().robot=true;o:get_luaentity().last_hp=b.hp;o:get_luaentity().last_shield=b.shield or 0;o:get_luaentity().last_dir=b.dir;o:get_luaentity().last_checkpoint=b.next;o:get_luaentity().destination=pos(b.x,b.z);o:set_yaw(G.yaw(b.dir))
 I.describe(o,b.enemy and (b.kind=='hunter' and 'Hunter' or (b.racing and 'Race opponent' or 'Patrol')) or 'Robot: '..b.id,b.pattern and ('Repeats: '..table.concat(b.pattern,' / ')) or 'Plans from a dealt hand. Fires after rotators.',{-.65,-.5,-.5,.65,1.2,.5})
 o:set_properties({textures={robot_texture(b,false)}});robots[b.id]=o
end
spawn_pickup=function(key,kind)
   local x,z=key:match('(%d+),(%d+)');local o=visual('pickup_'..kind,pos(tonumber(x),tonumber(z),1.4),{nametag=Systems.item_name(kind),nametag_color=kind=='jammer' and '#ef859f' or '#96e5cd',glow=4})
   if kind=='jammer' then o:set_properties({textures={'sc_surface_pickup_jammer.png^[multiply:#f28cbe'}}) end
   I.describe(o,Systems.item_name(kind),({hard_disk='Press E to keep one movement card per disk for the next round.',holographic_memory='Consumed to reboot at your destruction square once, except pit falls.',gyro_stabilizer='Enable each round to ignore forced rotation.',electroshield='Absorbs incoming damage for one power per hit while enabled.',titanium_hull='Survives one crusher strike, then breaks.',green_laser='Default weapon / one loaded weapon at a time.',double_laser='Two damage beams. Install during planning.',remote_control='Copies remaining commands to a target. Install during planning.',tractor_beam='Pulls a robot one square.',repulsor_beam='Pushes a robot one square.',mechanical_arm='Collects an adjacent pickup each register, across walls.',turret_gearbox='Aim your weapon front, back, left or right.',repair='Restores 2 hull immediately, up to maximum.',shield='Absorbs one hit.',cell='Restores three energy.',thermal_camera='Automatic aim tracks the nearest visible enemy during weapon phases.',blueprint_archive='Choose one item in your dashboard to keep on respawn.',blink='One successful jump consumes one Blink. At most one per round.',range='Passive equipment / +3 weapon range per copy.',cache='Adds one card to future hands.',jammer='Warning: removes two cards from the next hand.'})[kind],{-.48,-.48,-.48,.48,.48,.48});o:get_luaentity().hover=true;o:get_luaentity().origin=pos(tonumber(x),tonumber(z),1.4);pickups[key]=o
 end
local built_extent
build=function()
 cleanup();if core.begin_map_edit then core.begin_map_edit()end
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
   if x<0 or x>S.size*2+3 or z<0 or z>S.size*2+3 then core.set_node({x=x,y=0,z=z},{name='shift_circuit:apron'}) end
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
   if t.kind~='pit' then
     for dx=0,1 do for dz=0,1 do core.set_node({x=x*2+dx,y=0,z=z*2+dz},{name='shift_circuit:collider'}) end end
     local tile=visual('tile',pos(x,z),{textures={'sc_tile_'..(t.kind=='station' and 'dock'..t.number or (t.kind=='checkpoint' and 'dock0' or (t.kind=='repair' and 'repair' or 'deck')))..'.png'},backface_culling=false})
     I.describe(tile,t.kind=='station' and ('Checkpoint '..t.number) or 'Factory tile',t.kind=='station' and 'Visit checkpoints in numerical order.' or 'One square of the programming grid.',{-1,-.52,-1,1,-.48,1})
     if t.kind=='repair'then I.describe(tile,'Repair Pad','Restores 2 hull when you finish the five-card round here.',{-1,-.52,-1,1,-.48,1})
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
       for i=0,9 do
         local slat=visual(curved and ('slat_'..model) or 'slat',pos(x,z),{backface_culling=false});local e=slat:get_luaentity();e.belt=true;e.speed=t.speed or 1;e.travel=i/10;e.origin=pos(x,z);e.track=t
         local q,yaw=G.belt(t,e.travel);slat:set_pos({x=e.origin.x+q.x,y=e.origin.y,z=e.origin.z+q.z});slat:set_yaw(yaw)
       end
       end
       local arrow=visual(curved and ('arrow_'..model) or (t.speed==2 and 'arrow_double' or 'arrow_forward'),pos(x,z),{glow=4,backface_culling=false,textures={curved and t.speed~=2 and 'sc_surface_conveyor_arrows_green.png' or 'sc_surface_conveyor_arrows.png'}});arrow:set_yaw(G.yaw(t.dir))
     elseif t.kind=='station' then visual('station_ring',pos(x,z))
     elseif t.kind=='rotator' then local o=visual('rotator',pos(x,z),{nametag=t.turn==3 and 'Left Rotator' or 'Right Rotator',nametag_color='#94cfbd'});I.describe(o,t.turn==3 and 'Left Rotator' or 'Right Rotator','Rotates robots 90 degrees each pulse.',{-.82,-.47,-.82,.82,-.24,.82});rotors[#rotors+1]={o=o,turn=t.turn,angle=0} end
   end
 end end
 for key in pairs(S.overhead or {}) do
   local x,z=key:match('(%d+),(%d+)');x=tonumber(x);z=tonumber(z)
   local frame=visual('press_frame',pos(x,z,1),{nametag='Crusher / 2 + 4',nametag_color='#dfbc77'})
   I.describe(frame,'Crusher','Steps 2 + 4: destroys robots underneath, even through shields. Preview is harmless.',{-1,-.5,-.95,1,4.6,.95})
   local ram=visual('ram',pos(x,z,4.3));I.describe(ram,'Crusher','Steps 2 + 4: lethal crushing strike. Inspection motion is harmless.',{-.82,-.32,-.75,.82,.13,.75})
   local piston=visual('piston',pos(x,z,4.425));piston:get_luaentity().hydraulic=ram
   presses[#presses+1]={o=ram,x=x,z=z}
 end
 for key,solid in pairs(S.walls)do if solid then local w=R.wall(key);if w then local o=visual('edge_wall',pos(w.x,w.z));if w.axis=='E'then o:set_yaw(math.pi/2)end;I.describe(o,'Edge Wall','Blocks movement and beams across this edge.',{-1,-.5,-.13,1,1.39,.13})end end end
 for _,q in ipairs(S.pushers) do local o=visual('pusher',pos(q.x,q.z),{nametag=q.parity==1 and 'PUSH / 1 + 3 + 5' or 'PUSH / 2 + 4',nametag_color='#dfbc77'});o:set_yaw(G.yaw(q.dir));local ram=visual('pushram',pos(q.x,q.z));ram:set_yaw(G.yaw(q.dir));local rodpos,rodlength=G.pusher_rod(pos(q.x,q.z),ram:get_pos(),q.dir);local rod=visual('pushrod',rodpos,{visual_size={x=1,y=1,z=rodlength},pointable=false});rod:set_yaw(G.yaw(q.dir));local re=ram:get_luaentity();re.pusher_rod=rod;re.pusher_base=pos(q.x,q.z);re.pusher_dir=q.dir;I.describe(o,'Pusher',q.parity==1 and 'Pushes on pulses 1, 3 and 5.' or 'Pushes on pulses 2 and 4.',{-.75,-.5,-.9,.75,-.02,-.58});I.describe(ram,'Pusher ram','Pushes robots one tile.',{-.63,-.44,-.53,.63,-.06,-.37});pushers[#pushers+1]={o=ram,q=q} end
 for _,q in ipairs(S.lasers) do local x,z=R.laser_source(q);local o=visual('laser'..q.power,pos(x,z));o:set_yaw(G.yaw(q.dir));I.describe(o,({'Single Laser','Double Laser','Triple Laser'})[q.power],'Thin wall emitter. Fires into this square until a wall or robot.',{-.98,-.5,-.12,.98,.625,.19}) end
 for key,spawner in pairs(S.spawners or {})do local x,z=key:match('(%d+),(%d+)');local schedule=spawner.every and ('Every '..spawner.every..' rounds / from '..(spawner.first or 1))or ('Rounds '..table.concat(spawner.rounds or {},', '));local o=visual('spawner',pos(tonumber(x),tonumber(z)),{glow=3});I.describe(o,'Random Powerup Spawner',schedule..' / Phase '..(spawner.phase or 0)..' / '..(spawner.chance or 50)..'% chance. Occupied pads keep their pickup.',{-.7,-.5,-.7,.7,-.25,.7})end
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
 C.enemies(S,R);R.spawn_pickups(S);C.deal_round(S);if mode=='tutorial'then for _,b in ipairs(S.bots)do if not b.enemy then b.hand={'STEP','STEP','STEP','STEP','LEFT','LEFT','RIGHT','RIGHT','WAIT'}end end end;if mode=='race'then R.shared_start(S,S.start or {x=2,z=2,dir=0})end;phase='program';planning_left=#humans()>=2 and 60 or nil;slot=0;plan_round();build();sync();refresh()
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
 p:set_inventory_formspec(table.concat(f));core.show_formspec(name,'shift_circuit:lobby',table.concat(f))
end
refresh_menu=function(p)
 local b=bot(p:get_player_name());p:set_inventory_formspec(Loadout.formspec(b,phase,nil,S.test_mode and 'Test your equipment'or Goal.current(S,b,phase).label))
end
core.register_on_player_receive_fields(function(p,form,f)
 if form=='shift_circuit:loadout'or ((form==''or f.apply)and Loadout.changed(f))then
  if f.room then menu(p:get_player_name());return end
  local b=bot(p:get_player_name());local note
  if b and Loadout.changed(f)and not f.quit then
   if phase=='program'and not b.ready then local ok;ok,note=Loadout.apply(b,f);if ok then sync();refresh()end
   else note='Loadout is locked'end
   if form=='shift_circuit:loadout'then Loadout.show(p,b,phase,note)else p:set_inventory_formspec(Loadout.formspec(b,phase,note))end
  end;return
 end
 if form~='' and form~='shift_circuit:lobby' then return end
 local name=p:get_player_name();local v=players[name];if not v then return end
 if f.loadout then Loadout.show(p,bot(name),phase);return end
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
 local v={joined=not (options.is_spectator and options.is_spectator(name))and #humans()<8,camera='fly',slots={},labels={},priorities={},gauges={}};players[name]=v
 v.hud_ids={};v.hud_texts={};local function hud(d) local id=p:hud_add(d);v.hud_ids[#v.hud_ids+1]=id;v.hud_texts[id]=d.text or '';return id end
 v.phase_order=hud({type='image',position={x=0,y=1},offset={x=16,y=-16},alignment={x=1,y=-1},scale={x=1,y=1},text=''})
 hud({type='image',position={x=0,y=.19},alignment={x=1,y=1},offset={x=16,y=0},scale={x=1,y=1},text='sc_hud_stats.png'})
 hud({type='image',position={x=.5,y=1},alignment={x=0,y=-1},offset={x=0,y=-108},scale={x=1,y=1},text='sc_hud_controls.png'})
 hud({type='image',position={x=.5,y=0},alignment={x=0,y=1},scale={x=1,y=1},text='sc_register_terminal.png'})
 v.goal=hud({type='image',position={x=1,y=0},offset={x=-16,y=16},alignment={x=-1,y=1},scale={x=1,y=1},text='sc_goal_start.png'})
 v.racer_header=hud({type='image',position={x=1,y=0},offset={x=-16,y=132},alignment={x=-1,y=1},scale={x=1,y=1},text=''})
 v.racers={};for i=1,8 do local y=156+(i-1)*28;v.racers[i]={
  bg=hud({type='image',position={x=1,y=0},offset={x=-16,y=y},alignment={x=-1,y=1},scale={x=1,y=1},text=''}),
  name=hud({type='text',position={x=1,y=0},offset={x=-264,y=y+13},alignment={x=1,y=0},size={x=.8,y=.8},number=0xade1d5,text=''}),
  progress=hud({type='image',position={x=1,y=0},offset={x=-86,y=y+4},alignment={x=-1,y=1},scale={x=1,y=1},text=''}),
  status=hud({type='image',position={x=1,y=0},offset={x=-20,y=y+4},alignment={x=-1,y=1},scale={x=1,y=1},text=''})}
 end
 v.goal_marker=hud({type='image_waypoint',world_pos=pos(2,2,2.7),scale={x=1,y=1},text='',alignment={x=0,y=0}})
 v.own_marker=hud({type='image_waypoint',z_index=32767,world_pos=pos(2,2,2.9),scale={x=1,y=1},text='',alignment={x=0,y=-1}})
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
 p:set_properties({visual_size={x=0,y=0},pointable=false,zoom_fov=0});p:set_sky({type='plain',base_color='#101c29',clouds=false});p:set_sun({visible=false});p:set_moon({visible=false});p:set_stars({visible=false})
 p:set_fov(65,false,0);p:hud_set_flags({hotbar=true,healthbar=false,crosshair=true,wielditem=false,breathbar=false,minimap=false})
 p:hud_set_hotbar_image('sc_hotbar.png');p:hud_set_hotbar_selected_image('sc_hotbar_selected.png');camera(p,'fly');refresh_menu(p)
 if v.joined and (phase=='program' or phase=='lobby') then local b=add_pilot(name,#humans()+1);spawn_robot(b);if phase=='program'then plan_round()end end
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
 if phase=='program'and #humans()==0 and all_ready()then begin()end
 if phase=='program' then
   if #humans()>=2 then
     planning_left=math.max(0,(planning_left or 60)-dt)
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
     if held and not v.keep_key and phase=='program'then
      local b=bot(name);local index=p:get_wield_index()-1
      if b and not b.ready and b.hand[index]and b.hand[index]~='WAIT'and b.hand[index]~='BLINK'then
       b.keep=b.keep or {};local removed=false;for i,k in ipairs(b.keep)do if k==index then table.remove(b.keep,i);removed=true;break end end
       local capacity=b.parts and b.parts.hard_disk or 0
       if not removed and #b.keep<capacity then b.keep[#b.keep+1]=index;v.notice='HARD DISK / Card retained for next round'
       elseif removed then v.notice='HARD DISK / Card released'
       else v.notice=capacity==0 and 'Collect a Hard Disk to retain cards'or 'Hard Disk storage is full'end
       inventory(p,b);update_hud(name)
      end
     end;v.keep_key=held
     if hudclock>.15 then update_hud(name) end
   end
 end
 if hudclock>.15 then hudclock=0 end
 planner.tick()
 if phase=='planning_ai'then return end
 if inspecting() then inspect_animation(dt);return end
 if phase=='loading' then return end
 timer=timer+dt;if timer<phase_time() then return end;timer=0
 if phase=='reading' then
  S.register=slot;command_queue=R.program_order(S,slot);command_index=1;phase='commands'
  local b=command_queue[command_index];if b then S.executing=b.id;R.command(S,b,b.program[slot]or 'WAIT');R.ghosts(S)end
 elseif phase=='commands' then
  command_index=command_index+1;local b=command_queue[command_index]
  if b then S.executing=b.id;R.command(S,b,b.program[slot]or 'WAIT');R.ghosts(S)
  else S.executing=nil;R.collect_phase(S);R.arms(S);R.belts(S,true);phase='express';sound('move',pos(6,6),.12,.75)end
 elseif phase=='express' then R.collect_phase(S);R.belts(S,false);phase='belts';sound('move',pos(6,6),.12,.75)
 elseif phase=='belts' then
   R.collect_phase(S);R.pushers(S,slot);phase='pushers';for _,p in ipairs(pushers) do if slot%2==p.q.parity then sound('crusher',pos(p.q.x,p.q.z),.2,1.25);local d=R.dirs[p.q.dir+1];p.o:get_luaentity().target=vector.add(pos(p.q.x,p.q.z),{x=d.x*.9,y=0,z=d.z*.9}) end end
 elseif phase=='pushers' then
   R.collect_phase(S)
   for _,p in ipairs(pushers) do p.o:get_luaentity().target=pos(p.q.x,p.q.z) end
   R.rotators(S);phase='rotators';for _,r in ipairs(rotors) do r.angle=r.angle+(r.turn==3 and 1 or -1)*math.pi/2;r.o:get_luaentity().yaw=r.angle end
 elseif phase=='rotators' then R.robot_weapons(S,slot);phase='weapons'
 elseif phase=='weapons' then R.collect_phase(S);R.lasers(S);phase='lasers'
 elseif phase=='lasers' then
   R.hazards(S,slot);phase='presses';if slot%2==0 then for _,p in ipairs(presses) do sound('crusher',pos(p.x,p.z),.4) end end;for _,p in ipairs(presses) do p.o:get_luaentity().target=pos(p.x,p.z,slot%2==0 and 1 or 4.3) end
 elseif phase=='presses' then
   for _,p in ipairs(presses) do p.o:get_luaentity().target=pos(p.x,p.z,4.3) end
   if S.winner and (S.mode~='race'or R.race_complete(S))then
     phase='finished';restore_cameras(true)
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
     R.repairs(S);R.ghosts(S,true);R.respawn(S);S.round=S.round+1;R.spawn_pickups(S);phase='program';planning_left=nil;restore_cameras(true)
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
 planner.cancel();restore_cameras()
 S={size=data.size or 11,round=1,level=1,mode='race',board={},bots={},shots={},start=data.start}
 for _,key in ipairs({'board','walls','overhead','pickups','lasers','pushers','spawners','start'})do S[key]=core.deserialize(core.serialize(data[key]or {}))end
 if play then
  Q.number(R,S,math.min(3,9))
  for name,v in pairs(players)do if v.joined then local b=add_pilot(name,1);b.x,b.z,b.dir=S.start.x,S.start.z,S.start.dir;b.home={x=b.x,z=b.z,dir=b.dir}end end
  phase='program';R.spawn_pickups(S);C.deal_round(S);plan_round()
 else phase='editor'end
 slot=0;planning_left=nil;build();sync();refresh()
end
api.watch=function(name)local p=core.get_player_by_name(name);local v=players[name];if p and v then if v.follow then v.follow:remove();v.follow=nil end;p:set_detach();v.return_view=nil;follow_camera(p)end end
api.lab=function(name,scenario)
 if not options.test_lab or not core.get_player_privs(name).server then return false end
 if not players[name]then return false end
 local allowed={weapons=true,remote=true,arm=true,armor=true,spawners=true}
 if not allowed[scenario]then return false end
 local data=dofile(path..'/levels.lua').blank(11);data.start={x=5,z=3,dir=0};data.pickups={};data.spawners={};data.board['9,9']={kind='checkpoint'}
 if scenario=='arm'then
  data.start={x=5,z=5,dir=0};data.board['5,6']={kind='checkpoint'};data.pickups['6,5']='cell';data.pickups['4,5']='shield'
  for dir=0,3 do data.walls[R.edge(5,5,dir)]=true end
 elseif scenario=='armor'then data.overhead['5,3']={kind='crusher'}
 elseif scenario=='spawners'then data.spawners={['5,4']={item='repair',rounds={1,2,5}},['6,3']={item='double_laser',first=1,every=2}}
 else data.walls[R.edge(7,5,0)]=true;data.lasers={{x=7,z=3,dir=0,power=3}}end
 api.edit_level(data,true);S.test_scenario=scenario;S.test_mode=true
 local b=bot(name);b.parts={blink=1,range=1,cache=1};for kind in pairs(R.part_items)do b.parts[kind]=2 end
 b.energy=9;b.enabled={holographic_memory=true,electroshield=scenario~='armor'};b.parts.titanium_hull=1;b.parts.mechanical_arm=1
 R.loadout(b,scenario=='remote'and 'remote_control'or 'repulsor_beam',0)
 if scenario=='weapons'or scenario=='remote'then
  S.bots[#S.bots+1]={id='TEST TARGET',enemy=true,kind='hunter',x=5,z=6,dir=2,hp=5,max_hp=5,energy=9,shield=0,next=99,home={x=5,z=6,dir=2},pattern={'WAIT','LEFT','RIGHT','WAIT','WAIT'},program={}}
 end
 C.deal_round(S);b.hand={'WAIT','WAIT','WAIT','WAIT','WAIT','STEP','LEFT','RIGHT','BACK'};plan_round();build();sync();refresh();return true
end
api.lab_refill=function(name)
 if not options.test_lab or not core.get_player_privs(name).server or phase~='program'then return false end
 local b=bot(name);if not b then return false end;b.hp=5;b.energy=9;for kind in pairs(R.part_items)do b.parts[kind]=math.max(2,b.parts[kind]or 0)end;sync();refresh();return true
end
api.takeover=function(name)
 local b=bot(name);if not b or b.finished or S.mode~='race'then return false end
 b.enemy=true;b.racing=true;b.kind='racer';b.disconnected=true;b.difficulty=S.racer_difficulty or 2
 -- Preserve committed commands and execution in progress; plan from this hand if uncommitted.
 if (phase=='program'or phase=='planning_ai')and not b.ready then plan_round()end
 return true
end
api.phase=function()return phase end
api.configure=function(board,ai_count,ai_mode,solo_config) options.board=board;options.ai_count=ai_count;options.ai_mode=ai_mode;options.solo_config=solo_config end
api.cleanup=function() planner.cancel();restore_cameras();cleanup() end
api.next=function() if phase=="finished" and S.mode=="campaign" and S.level<3 then start_match("campaign",S.level+1,true);return true end return false end
return api
end







