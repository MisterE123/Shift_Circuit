-- Pure deterministic rules, deliberately independent of the engine.
local R = {}
R.hull_max=5
R.commands = {'STEP','DASH','MOVE3','BACK','BACK2','LEFT','RIGHT','UTURN','WAIT'}
R.weapons={green_laser={title='Green Laser',power=1,cost=0},double_laser={title='Double Laser',power=2,cost=0},remote_control={title='Remote Control',cost=3},tractor_beam={title='Tractor Beam',cost=1},repulsor_beam={title='Repulsor Beam',cost=1}}
R.part_items={thermal_camera=true,blueprint_archive=true,electroshield=true,titanium_hull=true,gyro_stabilizer=true,hard_disk=true,holographic_memory=true,green_laser=true,double_laser=true,remote_control=true,tractor_beam=true,repulsor_beam=true,mechanical_arm=true,turret_gearbox=true}
-- Migrate older saves without losing their spare weapon or module upgrades.
function R.normalize(b)
 b.parts=b.parts or {}
 if b.blink and not b.parts.blink then b.parts.blink=1;b.blink_left=1 end
 if (b.range or 4)>4 and not b.parts.range then b.parts.range=math.max(1,math.floor((b.range-4)/3))end
 if (b.draw_bonus or 0)>0 and not b.parts.cache then b.parts.cache=b.draw_bonus end
 b.blink=(b.parts.blink or 0)>0;b.range=4+3*(b.parts.range or 0);b.draw_bonus=math.min(3,b.parts.cache or 0)
 if b.blink_left==nil then b.blink_left=b.blink and 1 or 0 end
 b.weapon=b.weapon or b.primary or 'green_laser';b.aim_offset=b.aim_offset or 0
 if b.secondary then b.parts[b.secondary]=(b.parts[b.secondary]or 0)+1 end
 if b.equipment=='mechanical_arm'then b.parts.mechanical_arm=(b.parts.mechanical_arm or 0)+1 end
 b.primary=nil;b.secondary=nil;b.secondary_aim=nil;b.equipment=nil
end
function R.loadout(b,weapon,aim)
 R.normalize(b)
 if not R.weapons[weapon]then return false,'Unknown weapon'end
 aim=tonumber(aim)or 0;if aim~=math.floor(aim)or aim<0 or aim>4 then return false,'Invalid aim'end
 if aim==4 and (b.parts.thermal_camera or 0)<1 then return false,'Collect a Thermal Camera for automatic aiming'end
 if aim~=0 and aim~=4 and (b.parts.turret_gearbox or 0)<1 then return false,'Collect an Aim Gearbox to aim away from the front'end
 local parts={};for k,v in pairs(b.parts)do parts[k]=v end
 if b.weapon~='green_laser'then parts[b.weapon]=(parts[b.weapon]or 0)+1 end
 if weapon~='green_laser'then if (parts[weapon]or 0)<1 then return false,'Collect this weapon first'end;parts[weapon]=parts[weapon]-1 end
 b.parts=parts;b.weapon=weapon;b.aim_offset=aim;return true
end
function R.aim(b)
 if b.aim_offset==4 then return ((b.parts or {}).thermal_camera or 0)>0 and not (b.enabled and b.enabled.thermal_camera==false)and (b.thermal_dir or b.dir)or b.dir end
 return (b.dir+(((b.parts or {}).turret_gearbox or 0)>0 and (b.aim_offset or 0)or 0))%4
end
function R.ai_loadout(b,round)
 R.normalize(b);if b.loadout_round==round then return end;b.loadout_round=round
 local available={green_laser=true,[b.weapon]=true};for k,v in pairs(b.parts)do if R.weapons[k]and v>0 then available[k]=true end end
 local choices={};for k in pairs(available)do choices[#choices+1]=k end;table.sort(choices)
 R.loadout(b,choices[math.random(#choices)],(b.parts.thermal_camera or 0)>0 and 4 or (b.parts.turret_gearbox or 0)>0 and math.random(0,3)or 0)
end
R.powerup_pool={'repair','repair','shield','shield','cell','cell','blink','range','cache','double_laser','remote_control','tractor_beam','repulsor_beam','mechanical_arm','turret_gearbox','hard_disk','holographic_memory','gyro_stabilizer','electroshield','titanium_hull','blueprint_archive','thermal_camera'}
function R.spawn_pickups(s,random)
 random=random or math.random
 s.pickups=s.pickups or {};s.spawn_events=s.spawn_events or {}
 local keys={};for key in pairs(s.spawners or {})do keys[#keys+1]=key end;table.sort(keys)
 for _,key in ipairs(keys)do local spawner=s.spawners[key]
  local due=false;for _,round in ipairs(spawner.rounds or {})do if s.round==round then due=true end end
  local first=(spawner.first or 1)+(spawner.phase or 0)
  if spawner.every and s.round>=first and (s.round-first)%spawner.every==0 then due=true end
  if due and spawner.last_round~=s.round then
   spawner.last_round=s.round
   local chance=spawner.chance or 50
   if not s.pickups[key]and (chance>=100 or (chance>0 and random(100)<=chance))then local item=R.powerup_pool[random(#R.powerup_pool)];s.pickups[key]=item;s.spawn_events[#s.spawn_events+1]={key=key,item=item}end
  end
 end
end
R.dirs = {{x=0,z=1},{x=1,z=0},{x=0,z=-1},{x=-1,z=0}}
function R.key(x,z) return x..','..z end
function R.edge(x,z,dir)
  if dir==0 then return x..','..z..',N' elseif dir==1 then return x..','..z..',E'
  elseif dir==2 then return x..','..(z-1)..',N' else return (x-1)..','..z..',E' end
end
function R.blocked(s,x,z,dir)
 local edge=R.edge(x,z,dir);if s.walls and s.walls[edge]then return true end
 for _,q in ipairs(s.lasers or {})do if R.edge(q.x,q.z,(q.dir+2)%4)==edge then return true end end
 return false
end
function R.laser_source(q)local d=R.dirs[q.dir+1];return q.x-d.x*.5,q.z-d.z*.5 end
function R.tile(s,x,z) return s.board[R.key(x,z)] or {kind='pit'} end
function R.at(s,x,z,except)
  for _,b in ipairs(s.bots) do if b ~= except and not (except and except.ghost and b.ghost) and not b.down and not b.finished and b.x==x and b.z==z then return b end end
end
function R.archive_choices(b)
 R.normalize(b);local list={};local seen={}
 for k,v in pairs(b.parts)do if v>0 and k~='green_laser' then seen[k]=true end end
 if b.weapon~='green_laser'then seen[b.weapon]=true end
 for k in pairs(seen)do list[#list+1]=k end;table.sort(list);return list
end
function R.drop(b,cause)
  if b.down or b.finished then return end
  R.normalize(b)
  local keep=b.archive_item
  b.archived_item=nil
  if (b.parts.blueprint_archive or 0)>0 and keep and ((b.parts[keep]or 0)>0 or b.weapon==keep)then b.archived_item=keep end
  if cause~='Fell into a pit'and not (b.enabled and b.enabled.holographic_memory==false)and b.parts and (b.parts.holographic_memory or 0)>0 then b.parts.holographic_memory=b.parts.holographic_memory-1;b.holo_reboot={x=b.x,z=b.z,dir=b.dir}end
  b.parts={};b.weapon='green_laser';b.aim_offset=0;b.enabled={};b.keep={};b.keep_ids={}
  b.blink=false;b.blink_left=0;b.range=4;b.draw_bonus=0;b.shield=0;b.archive_item=nil;b.thermal_dir=nil
  b.hp=0; b.down=true; b.destroyed_by=cause or "Damage"; b.damage=(b.damage or 0)+1
  b.disruption=math.min(4,(b.disruption or 0)+1)
end
function R.hit(b,cause)
  if (b.shield or 0)>0 then b.shield=b.shield-1;return end
  if b.parts and (b.parts.electroshield or 0)>0 and not (b.enabled and b.enabled.electroshield==false)and (b.energy or 0)>0 then b.energy=b.energy-1;b.electro_serial=(b.electro_serial or 0)+1;return end
  b.hp=(b.hp or 1)-1
  if b.hp<=0 then R.drop(b,cause) end
end
-- These segments are also used to place visible wall models.
function R.wall(key)
 local x,z,axis=key:match('^(%-?%d+),(%-?%d+),([NE])$');if not x then return end
 x=tonumber(x);z=tonumber(z)
 return {x=x+(axis=='E'and .5 or 0),z=z+(axis=='N'and .5 or 0),axis=axis}
end
function R.wall_ray(s,x,z,dir,range)
 local d=R.dirs[dir+1];local nearest
 local walls={};for k,v in pairs(s.walls or {})do walls[k]=v end;for _,q in ipairs(s.lasers or {})do walls[R.edge(q.x,q.z,(q.dir+2)%4)]=true end
 for key,solid in pairs(walls)do if solid then local w=R.wall(key);local distance
  if w and w.axis=='E'and d.x~=0 and math.abs(z-w.z)<=.5 then distance=(w.x-x)/d.x
  elseif w and w.axis=='N'and d.z~=0 and math.abs(x-w.x)<=.5 then distance=(w.z-z)/d.z end
  if distance and distance>0 and distance<=range and (not nearest or distance<nearest)then nearest=distance end
 end end
 return nearest
end
function R.trace(s,x,z,dir,range,owner)
 local d=R.dirs[dir+1];local wall=R.wall_ray(s,x,z,dir,range)
 local coordinate=d.x~=0 and x or z;local first=coordinate%1==.5 and .5 or 1
 for i=first,range,1 do
  if wall and wall<i then return wall,nil,true end
  local nx,nz=math.floor(x+d.x*i+.5),math.floor(z+d.z*i+.5)
  if R.tile(s,nx,nz).kind=='wall'then return i-.5,nil,true end
  local target=R.at(s,nx,nz,owner)
  if target then return i-.25,target,false end
 end
 return wall or range,nil,wall~=nil
end
function R.fire(s,x,z,dir,power,range,owner)
  if owner and owner.ghost then return end
  local length,target,wall=R.trace(s,x,z,dir,range,owner)
  if target then target.last_laser={source=owner and owner.id or 'Fixed laser',x=x,z=z,dir=dir,round=s.round};for _=1,power do if not target.down then R.hit(target,owner and "Robot weapon" or "Fixed laser") end end end
  s.shots=s.shots or {};s.shots[#s.shots+1]={x=x,z=z,dir=dir,range=length,power=power,wall=wall,hit=target~=nil or length<range}
end
function R.collect(s,b,x,z,arm)
      x=x or b.x;z=z or b.z;local k=R.key(x,z); local pickup=s.pickups and s.pickups[k]
      if pickup and not b.down and not b.finished then
        if R.part_items[pickup]then b.parts=b.parts or {};b.parts[pickup]=(b.parts[pickup]or 0)+1;if pickup=='thermal_camera'then b.aim_offset=4 end
        elseif pickup=='repair' then b.hp=math.min(b.max_hp or R.hull_max,(b.hp or 0)+2)
        elseif pickup=='shield' then b.shield=math.min(3,(b.shield or 0)+1)
        elseif pickup=='cell' then b.energy=math.min(9,(b.energy or 0)+3)
        elseif pickup=='blink' then R.normalize(b);b.parts.blink=(b.parts.blink or 0)+1;b.blink=true;if b.parts.blink==1 then b.blink_left=1 end
        elseif pickup=='range' then R.normalize(b);b.parts.range=(b.parts.range or 0)+1;b.range=4+3*b.parts.range
        elseif pickup=='cache' then R.normalize(b);b.parts.cache=(b.parts.cache or 0)+1;b.draw_bonus=math.min(3,b.parts.cache)
        elseif pickup=='jammer' then b.disruption=math.min(4,(b.disruption or 0)+2) end
        s.pickups[k]=nil; b.collected=pickup;b.collected_counts=b.collected_counts or {};b.collected_counts[pickup]=(b.collected_counts[pickup] or 0)+1
        s.collections=s.collections or {};s.collections[#s.collections+1]={key=k,kind=pickup,robot=b.id,x=x,z=z,arm=arm}
      end
end
function R.move(s,b,dir,seen)
  if b.down or b.finished then return false end
  seen=seen or {}; if seen[b.id] then return false end; seen[b.id]=true
  local d=R.dirs[dir+1]; local x,z=b.x+d.x,b.z+d.z
  if R.blocked(s,b.x,b.z,dir) then return false end
  local t=R.tile(s,x,z); if t.kind=='wall' then return false end
  local other=R.at(s,x,z,b)
  if other and not R.move(s,other,dir,seen) then return false end
  b.x,b.z=x,z
  if t.kind=='pit' then R.drop(b,'Fell into a pit') end
  R.ghosts(s)
  return true
end
function R.command(s,b,c)
  R.normalize(b)
  if b.down or b.finished then return end
  b.action_serial=(b.action_serial or 0)+1;b.last_action=c
  if c=='PULSE' and (s.round or 1)>1 and not b.ghost and (b.energy or 0)>0 then
    b.energy=b.energy-1
    R.fire(s,b.x,b.z,b.dir,1,b.range or 4,b)
  elseif c=='BLINK' and b.blink and (b.blink_left or 0)>0 and (b.energy or 0)>0 then
    local d=R.dirs[b.dir+1]; local x,z=b.x+d.x*2,b.z+d.z*2; local t=R.tile(s,x,z)
    if t.kind~='wall' and t.kind~='pit' and not R.at(s,x,z,b) then b.x,b.z=x,z; b.energy=b.energy-1;b.blink_left=0;b.parts.blink=math.max(0,(b.parts.blink or 0)-1);b.blink=b.parts.blink>0;R.ghosts(s) end
  elseif c=='LEFT' then b.dir=(b.dir+3)%4
  elseif c=='RIGHT' then b.dir=(b.dir+1)%4
  elseif c=='UTURN' then b.dir=(b.dir+2)%4
  elseif c=='BACK' or c=='BACK2' then for _=1,c=='BACK2' and 2 or 1 do if not R.move(s,b,(b.dir+2)%4)then break end end
  elseif c=='STEP' or c=='DASH' or c=='MOVE3' then
    for _=1,c=='MOVE3' and 3 or (c=='DASH' and 2 or 1) do if not R.move(s,b,b.dir) then break end end
  end
end
function R.order(s)
  local a={}; local n=#s.bots
  for i=1,n do a[i]=s.bots[((i+s.round-2)%n)+1] end
  return a
end
-- Ghosting is a shared-start grace period, never a general invulnerability powerup.
function R.ghosts(s,expire)
 for _,b in ipairs(s.bots)do if b.ghost then
  local shared=false;for _,other in ipairs(s.bots)do if other~=b and not other.down and other.x==b.x and other.z==b.z then shared=true end end
  if not shared or b.down then b.ghost=nil end
 end end
 if expire then
  local used={}
  for _,b in ipairs(R.order(s))do if not b.down then
   local k=R.key(b.x,b.z)
   if used[k]then
    local best,dist
    for z=1,s.size do for x=1,s.size do local t=R.tile(s,x,z);local d=math.abs(x-b.x)+math.abs(z-b.z)
     if not used[R.key(x,z)] and not R.at(s,x,z) and (t.kind=='floor' or t.kind=='station') and (not dist or d<dist)then best={x=x,z=z};dist=d end
    end end
    if best then b.x,b.z=best.x,best.z end
   end
   used[R.key(b.x,b.z)]=true;b.ghost=nil
  end end
 end
end
function R.shared_start(s,start)
 s.start={x=start.x,z=start.z,dir=start.dir or 0}
 local count=0;for _,b in ipairs(s.bots)do if not b.enemy or b.racing then count=count+1 end end
 for _,b in ipairs(s.bots)do if not b.enemy or b.racing then b.x,b.z,b.dir=start.x,start.z,start.dir or 0;b.home={x=b.x,z=b.z,dir=b.dir};b.ghost=count>1 end end
end
function R.priority(b,slot)
 return (b.program_ids or {})[slot]or ((b.hand_ids or {})[(b.selected or {})[slot]])or 0
end
function R.program_order(s,slot)
 local order={};for _,b in ipairs(s.bots)do if not b.down and not b.finished then order[#order+1]=b end end
 table.sort(order,function(a,b)local x,y=R.priority(a,slot),R.priority(b,slot);if x~=y then return x>y end;return a.id<b.id end)
 return order
end
function R.collect_phase(s)
 for _,b in ipairs(R.program_order(s,s.register or 1))do R.collect(s,b)end
end
function R.programs(s,slot)
  s.register=slot;for _,b in ipairs(R.program_order(s,slot)) do R.command(s,b,b.program[slot] or 'WAIT');R.ghosts(s) end;R.collect_phase(s);R.arms(s)
end
function R.belts(s,express)
  -- Express-only substep first, then the shared substep. Read the destination belt
  -- afresh, allowing a two-speed belt to feed a turn or a normal-speed belt.
  if express==nil then R.belts(s,true);R.collect_phase(s);R.belts(s,false);R.collect_phase(s);return end
  local intents={}
  for _,b in ipairs(R.order(s)) do
    local t=R.tile(s,b.x,b.z)
    if not b.down and not b.finished and t.kind=='belt' and (not express or t.speed==2) then intents[#intents+1]={bot=b,dir=t.dir,x=b.x,z=b.z} end
  end
  for _,i in ipairs(intents) do
    if i.bot.x==i.x and i.bot.z==i.z then
      if R.move(s,i.bot,i.dir) and not i.bot.down then
        local dest=R.tile(s,i.bot.x,i.bot.z)
        if dest.kind=='belt' and dest.entry and not R.gyro(i.bot)then i.bot.dir=(i.bot.dir+dest.dir-i.dir)%4 end
      end
    end
  end
end
function R.finish(s,b,slot)
 if b.finished then return end
 b.finished=true;b.finish_round=s.round;b.finish_register=slot;b.ready=true
 s.finishers=s.finishers or {};s.finishers[#s.finishers+1]={id=b.id,rank=#s.finishers+1,round=s.round,register=slot,human=not b.enemy};b.rank=#s.finishers
 s.winner=s.winner or b.id;s.finish_events=s.finish_events or {};s.finish_events[#s.finish_events+1]=b.id
end
function R.race_complete(s)
 for _,b in ipairs(s.bots)do if (not b.enemy or b.racing)and not b.finished then return false end end
 return true
end
function R.gyro(b)return b.parts and (b.parts.gyro_stabilizer or 0)>0 and b.enabled and b.enabled.gyro_stabilizer==true end
function R.checkpoint(s,b,x,z,remote)
 local t=R.tile(s,x,z)
 if not b.down and not b.finished and (not b.enemy or b.racing)and t.kind=='station'and t.number==b.next then
  b.next=b.next+1;b.home={x=x,z=z,dir=b.dir}
  if remote then s.reaches=s.reaches or {};s.reaches[#s.reaches+1]={robot=b.id,x=x,z=z,checkpoint=true}end
 end
 if not b.down and not b.finished and b.next and b.next>(s.checkpoint_count or 3)and b.next<99 and (not s.objective_collect or (b.collected_counts and b.collected_counts[s.objective_collect]))then R.finish(s,b,s.register or 1)end
end
function R.hazards(s,slot)
 s.register=slot
 for _,b in ipairs(s.bots)do if not b.down and not b.finished then
  local t=R.tile(s,b.x,b.z)
  if ((s.overhead and s.overhead[R.key(b.x,b.z)])or t.kind=='press')and slot%2==0 then
   if b.parts and (b.parts.titanium_hull or 0)>0 and not (b.enabled and b.enabled.titanium_hull==false)then b.parts.titanium_hull=b.parts.titanium_hull-1;b.titanium_serial=(b.titanium_serial or 0)+1
   else R.drop(b,'CRUSHED by crusher')end
  end
  R.checkpoint(s,b,b.x,b.z)
 end end
end
function R.pushers(s,slot)
  for _,p in ipairs(s.pushers or {}) do
    if slot%2==p.parity then local b=R.at(s,p.x,p.z);if b then R.move(s,b,p.dir) end end
  end
end
function R.rotators(s)
  for _,b in ipairs(s.bots) do local t=R.tile(s,b.x,b.z);if not b.down and not b.finished and t.kind=='rotator' and not R.gyro(b)then b.dir=(b.dir+(t.turn or 1))%4 end end
end
function R.fixed_laser_range(s,p)
 local edge=(s.size or 11)+.5
 local x,z=R.laser_source(p)
 return math.max(0,({edge-z,edge-x,z-.5,x-.5})[p.dir+1])
end
function R.lasers(s)
  for _,p in ipairs(s.lasers or {}) do local x,z=R.laser_source(p);R.fire(s,x,z,p.dir,p.power,R.fixed_laser_range(s,p)) end
end
function R.thermal_aim(s,b)
 b.thermal_dir=nil
 if b.aim_offset~=4 or (b.parts.thermal_camera or 0)<1 or (b.enabled and b.enabled.thermal_camera==false)then return end
 local nearest,selected
 for dir=0,3 do local _,target=R.trace(s,b.x,b.z,dir,b.range or 4,b)
  if target and not target.ghost and not (b.team and target.team==b.team) and not (b.enemy and target.enemy and not b.racing and not target.racing)then
   local distance=math.abs(target.x-b.x)+math.abs(target.z-b.z)
   if not nearest or distance<nearest then nearest=distance;selected=dir end
  end
 end
 b.thermal_dir=selected
end
function R.robot_weapons(s,slot)
 if (s.round or 1)<=1 then s.shots=s.shots or {};return end
 slot=slot or s.register or 1
 local effects={};s.shots=s.shots or {}
 for _,b in ipairs(R.order(s))do if not b.down and not b.ghost and not b.finished then
  R.normalize(b);R.thermal_aim(s,b);for _,mount in ipairs({'weapon'})do local kind=b.weapon;local weapon=R.weapons[kind]
   if weapon then local cost=weapon.cost
    if (b.energy or 0)>=cost and (kind~='remote_control'or b.remote_round~=s.round)then
     b.energy=(b.energy or 0)-cost;if kind=='remote_control'then b.remote_round=s.round end
     local dir=R.aim(b,mount);local length,target,wall=R.trace(s,b.x,b.z,dir,b.range or 4,b)
     s.shots[#s.shots+1]={x=b.x,z=b.z,dir=dir,range=length,power=weapon.power or 1,weapon=true,kind=kind,mount=mount,body_dir=b.dir,owner=b.id,wall=wall,hit=target~=nil or wall}
     if target then
      local commands={};for i=slot+1,5 do commands[i]=(b.program or {})[i]end
      effects[#effects+1]={target=target,owner=b,dir=dir,kind=kind,power=weapon.power,commands=commands}
     end
    end
   end
  end
 end end
 for _,e in ipairs(effects)do local target=e.target;if not target.down and not target.finished then
  target.last_laser={source=e.owner.id,x=e.owner.x,z=e.owner.z,dir=e.dir,round=s.round,weapon=e.kind}
  if e.power then for _=1,e.power do if not target.down then R.hit(target,'Robot weapon')end end
  elseif (target.shield or 0)>0 then target.shield=target.shield-1
  elseif e.kind=='remote_control'then target.program=target.program or {};target.remote_from=e.owner.id;target.remote_slots={};for i=slot+1,5 do target.program[i]=e.commands[i];target.remote_slots[i]=true end
  elseif e.kind=='repulsor_beam'then R.move(s,target,e.dir)
  elseif e.kind=='tractor_beam'and math.abs(target.x-e.owner.x)+math.abs(target.z-e.owner.z)>1 then R.move(s,target,(e.dir+2)%4)end
 end end
end
function R.arms(s)
 for _,b in ipairs(R.order(s))do if not b.down and not b.finished then
  local grabs=(b.enabled and b.enabled.mechanical_arm==false)and 0 or math.min(4,(b.parts and b.parts.mechanical_arm or 0)+(b.equipment=='mechanical_arm'and 1 or 0))
  for _,d in ipairs(R.dirs)do local x,z=b.x+d.x,b.z+d.z;if grabs>0 and s.pickups and s.pickups[R.key(x,z)]then R.collect(s,b,x,z,true);s.reaches=s.reaches or {};s.reaches[#s.reaches+1]={robot=b.id,x=x,z=z};grabs=grabs-1 end end
  if not (b.enabled and b.enabled.mechanical_arm==false)and ((b.parts and b.parts.mechanical_arm or 0)>0 or b.equipment=='mechanical_arm')then for _,d in ipairs(R.dirs)do local t=R.tile(s,b.x+d.x,b.z+d.z);if t.kind=='station'and t.number==b.next then R.checkpoint(s,b,b.x+d.x,b.z+d.z,true);break end end end
 end end
end
function R.repairs(s)
 for _,b in ipairs(s.bots)do if not b.down and not b.finished and R.tile(s,b.x,b.z).kind=='repair'then b.hp=math.min(b.max_hp or R.hull_max,(b.hp or 0)+2)end end
end
function R.respawn(s)
  for _,b in ipairs(R.order(s)) do
    if b.down and not b.finished then
      -- Restore the saved square even when occupied; sharing grants ghost grace.
      local best,dist;local home=b.holo_reboot or b.home
      for z=1,s.size do for x=1,s.size do
        local t=R.tile(s,x,z); local d=math.abs(x-home.x)+math.abs(z-home.z)
        if (t.kind=='floor' or t.kind=='station' or t.kind=='repair' or (b.holo_reboot and t.kind~='pit'and t.kind~='wall')) and (not dist or d<dist) then
          best={x=x,z=z}; dist=d
        end
      end end
      if best then b.x,b.z,b.down=best.x,best.z,false; b.destroyed_by=nil;b.dir=home.dir or 0;b.holo_reboot=nil;if b.archived_item then local item=b.archived_item;if R.weapons[item]then b.weapon=item else b.parts[item]=1 end;b.archived_item=nil;R.normalize(b)end; b.max_hp=b.max_hp or R.hull_max; b.hp=b.max_hp; b.energy=math.max(2,b.energy or 0) end
    end
  end
 for _,b in ipairs(s.bots)do if not b.down then
  for _,other in ipairs(s.bots)do if other~=b and not other.down and other.x==b.x and other.z==b.z then b.ghost=true;other.ghost=true end end
 end end
 R.ghosts(s)
end
function R.arena()
  local s={size=11,board={},bots={},round=1,walls={},overhead={}}
  for z=1,11 do for x=1,11 do s.board[R.key(x,z)]={kind='floor'} end end
  local function set(x,z,t) s.board[R.key(x,z)]=t end
  for x=3,8 do set(x,4,{kind='belt',dir=1}) end
  for z=5,8 do set(8,z,{kind='belt',dir=0}) end
  for x=4,7 do set(x,8,{kind='belt',dir=3}) end
  for _,p in ipairs({{5,6},{6,6},{7,2},{3,9}}) do set(p[1],p[2],{kind='pit'}) end
  for _,p in ipairs({{4,6,1},{7,6,0},{9,6,1},{6,3,0},{2,7,1}}) do s.walls[R.edge(p[1],p[2],p[3])]=true end
  for _,p in ipairs({{6,4},{8,7},{4,8}}) do s.overhead[R.key(p[1],p[2])]={kind='crusher'} end
  set(8,4,{kind='belt',entry=1,dir=0,speed=2})
  set(8,8,{kind='belt',entry=0,dir=3})
  set(9,3,{kind='station',number=1}); set(9,9,{kind='station',number=2}); set(2,9,{kind='station',number=3})
  return s
end
return R
