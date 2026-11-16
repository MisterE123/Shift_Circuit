-- Portable, data-only level format. Imported files never execute Lua.
local L={version=3}
local function integer(n,lo,hi)return type(n)=='number' and n==math.floor(n) and n>=lo and n<=hi end
function L.factory_schedule(q)
 if q==nil then return {first=1,every=3,phase=0,rounds={}}end
 if type(q)~='table'then return nil,'Invalid factory schedule'end
 local out={rounds={},phase=q.phase or 0}
 if not integer(out.phase,0,99)then return nil,'Invalid factory phase'end
 if q.every~=nil then
  if not integer(q.every,1,100)or not integer(q.first or 1,1,999)or out.phase>=q.every then return nil,'Invalid factory repeat interval or phase'end
  out.every=q.every;out.first=q.first or 1
 end
 if q.rounds~=nil and type(q.rounds)~='table'then return nil,'Invalid factory round list'end
 if #(q.rounds or {})>32 then return nil,'Too many factory rounds'end
 for _,n in ipairs(q.rounds or {})do if not integer(n,1,999)then return nil,'Factory rounds must be 1 to 999'end;out.rounds[#out.rounds+1]=n end
 if not out.every and #out.rounds==0 then return nil,'Set factory rounds or a repeat interval'end
 return out
end
-- Workshop edits may remove objective tiles. Prune only references to missing
-- objects; imported/submitted maps still use strict validation below.
function L.reconcile_puzzle(d)
 local removed={};local p=d.map_type=='puzzle'and d.puzzle
 if type(p)~='table'then return removed end
 if type(p.checkpoints)=='table'then for i=#p.checkpoints,1,-1 do local key=p.checkpoints[i];local t=(d.board or {})[key]
  if not t or (t.kind~='checkpoint'and t.kind~='station')then table.remove(p.checkpoints,i);removed[#removed+1]='checkpoint ('..tostring(key)..')'end
 end end
 if type(p.targets)=='table'then for i=#p.targets,1,-1 do local id=p.targets[i];local kind,key=tostring(id):match('^(%a+):(%d+,%d+)$')
  if (kind=='crate'and not (d.crates or {})[key])or (kind=='obstacle'and not (d.enemies or {})[key])then table.remove(p.targets,i);removed[#removed+1]='target ('..key..')'end
 end end
 return removed
end
function L.validate_submission(d)
 local count=0;for _,t in pairs(type(d)=='table'and type(d.board)=='table'and d.board or {})do if type(t)=='table'and (t.kind=='checkpoint'or t.kind=='station')then count=count+1 end end
 if d and d.map_type=='puzzle'then local out,err=L.validate(d);if not out then return nil,err end;if #out.puzzle.checkpoints+#out.puzzle.targets==0 then return nil,'Choose at least one puzzle objective'end;return out end
 if count<2 then return nil,'Place at least 2 checkpoint candidates: one start and one checkpoint'end
 return L.validate(d)
end
function L.validate(d)
 if type(d)~='table' or (d.version~=1 and d.version~=2 and d.version~=3) or type(d.board)~='table' then return nil,'Unsupported level format' end
 for _,key in ipairs({'walls','overhead','pickups','lasers','pushers','spawners','crates','enemies'})do if d[key]~=nil and type(d[key])~='table'then return nil,'Invalid layer: '..key end end
 if d.start~=nil and type(d.start)~='table'then return nil,'Invalid start' end
 local size=d.size or 11;if not integer(size,5,30)or (d.version==3 and size~=10 and size~=20)then return nil,'Choose a 10 or 20 square platform' end
 local out={version=3,size=size,title=tostring(d.title or 'Untitled'):sub(1,48),board={},walls={},overhead={},pickups={},spawners={},lasers={},pushers={},crates={},enemies={}}
 out.map_type=d.map_type=='puzzle'and 'puzzle'or 'race'
 local start=d.start or {};local flags={}
 for z=1,size do for x=1,size do local k=x..','..z;local t=d.board[k]
  if type(t)~='table'then return nil,'Every platform square needs a tile' end
  local q={kind=t.kind}
  if t.kind=='belt'then
   if not integer(t.dir,0,3)or not integer(t.speed,1,2)then return nil,'Invalid conveyor' end;q.dir=t.dir;q.speed=t.speed
   if t.entry~=nil then if not integer(t.entry,0,3)or (t.entry-t.dir)%2~=1 then return nil,'Conveyor bends must turn 90 degrees' end;q.entry=t.entry end
  elseif t.kind=='factory'then
   if not integer(t.dir,0,3)or not ({one=true,opposite=true,corner=true,three=true,four=true})[t.pattern]or (t.crate_kind~='loot'and t.crate_kind~='steel')then return nil,'Invalid crate factory'end
   q.dir=t.dir;q.pattern=t.pattern;q.crate_kind=t.crate_kind;local schedule,err=L.factory_schedule(t.schedule);if not schedule then return nil,err end;q.schedule=schedule
  elseif t.kind=='rotator'then if t.turn~=1 and t.turn~=3 then return nil,'Invalid rotator' end;q.turn=t.turn
  elseif t.kind=='station'or t.kind=='checkpoint'then q.kind='checkpoint';flags[#flags+1]={x=x,z=z,dir=0}
  elseif t.kind=='trapdoor'then q.open=t.open==true
  elseif t.kind=='plate'then
  elseif t.kind~='floor' and t.kind~='pit' and t.kind~='repair'then return nil,'Unknown tile' end
  out.board[k]=q
  if d.overhead and d.overhead[k]then local q=d.overhead[k];local parity=type(q)=='table'and q.parity or 0;parity=parity or 0;if not integer(parity,0,1)then return nil,'Crusher registers must be odd or even'end;out.overhead[k]={kind='crusher',parity=parity}end
  local item=d.pickups and d.pickups[k];if item then if not ({battering_ram=true,thermal_camera=true,blueprint_archive=true,electroshield=true,reset_button=true,electromagnetic_brake=true,titanium_hull=true,gyro_stabilizer=true,hard_disk=true,holographic_memory=true,green_laser=true,double_laser=true,triple_laser=true,emp_generator=true,remote_control=true,tractor_beam=true,repulsor_beam=true,mechanical_arm=true,turret_gearbox=true,repair=true,shield=true,cell=true,blink=true,range=true,cache=true,jammer=true})[item]then return nil,'Unknown pickup' end;out.pickups[k]=item end
 end end
 for _,layer in ipairs({'crates','enemies'})do for key,q in pairs(d[layer]or {})do
  if not out.board[key]or type(q)~='table'or out.board[key].kind=='pit'or out.board[key].kind=='factory'or (out.board[key].kind=='trapdoor'and out.board[key].open)then return nil,'Objects require a safe square'end
  if layer=='crates'then
   if q.kind~='loot'and q.kind~='steel'then return nil,'Unknown crate'end
   if q.item and not ({repair=true,shield=true,cell=true,blink=true,range=true,cache=true,battering_ram=true,double_laser=true,triple_laser=true,emp_generator=true,remote_control=true,tractor_beam=true,repulsor_beam=true,mechanical_arm=true,turret_gearbox=true,hard_disk=true,holographic_memory=true,gyro_stabilizer=true,electroshield=true,reset_button=true,electromagnetic_brake=true,titanium_hull=true,blueprint_archive=true,thermal_camera=true})[q.item]then return nil,'Unknown crate contents'end
   out.crates[key]={kind=q.kind,item=q.item}
  else
   if q.kind~='sentry'and q.kind~='patroller'and q.kind~='ram_bot'then return nil,'Unknown predictable enemy'end
   if not integer(q.dir,0,3)then return nil,'Invalid enemy facing'end
   if d.crates and d.crates[key]then return nil,'Crate and enemy cannot share a square'end
   out.enemies[key]={kind=q.kind,dir=q.dir}
  end
 end end
 if #flags==0 then return nil,'Place at least one checkpoint candidate' end
 local t=out.board[tostring(start.x)..','..tostring(start.z)];if not t or t.kind~='checkpoint'then start=flags[1]end;out.start={x=start.x,z=start.z,dir=integer(start.dir,0,3)and start.dir or 0}
 for k,v in pairs(d.walls or {})do
  local x,z,axis=tostring(k):match('^(%-?%d+),(%-?%d+),([NE])$');x=tonumber(x);z=tonumber(z)
  if not x or not integer(x,0,size)or not integer(z,0,size)then return nil,'Invalid wall edge' end
  if v then out.walls[k]=true end
 end
 for _,kind in ipairs({'lasers','pushers'})do
  local list=d[kind]or {};if type(list)~='table'or #list>size*size then return nil,'Too many machines' end
  for _,q in ipairs(list)do
   if type(q)~='table'or not integer(q.x,1,size)or not integer(q.z,1,size)or not integer(q.dir,0,3)then return nil,'Invalid machine location' end
   local n={x=q.x,z=q.z,dir=q.dir}
   if kind=='lasers'then if not integer(q.power,1,3)then return nil,'Invalid laser power' end;n.power=q.power
   else if not integer(q.parity,0,1)then return nil,'Invalid pusher steps' end;n.parity=q.parity end
   out[kind][#out[kind]+1]=n
  end
 end
 for key,q in pairs(d.spawners or {})do
  if not out.board[key]or (out.board[key].kind=='pit'or out.board[key].kind=='factory')or type(q)~='table'then return nil,'Spawner requires a safe square'end
  if q.item and not ({random=true,battering_ram=true,thermal_camera=true,blueprint_archive=true,electroshield=true,reset_button=true,electromagnetic_brake=true,titanium_hull=true,gyro_stabilizer=true,hard_disk=true,holographic_memory=true,green_laser=true,double_laser=true,triple_laser=true,emp_generator=true,remote_control=true,tractor_beam=true,repulsor_beam=true,mechanical_arm=true,turret_gearbox=true,repair=true,shield=true,cell=true,blink=true,range=true,cache=true,jammer=true})[q.item]then return nil,'Unknown spawner item'end
  local sp={item='random',rounds={},chance=q.chance or 50,phase=q.phase or 0}
  if not integer(sp.chance,0,100)or not integer(sp.phase,0,99)then return nil,'Chance must be 0 to 100 and phase a whole number'end
  if q.every and sp.phase>=q.every then return nil,'Phase must be smaller than the round interval'end
  if q.every~=nil then if not integer(q.every,1,100)or not integer(q.first or 1,1,999)then return nil,'Invalid repeating schedule'end;sp.every=q.every;sp.first=q.first or 1 end
  if q.rounds~=nil and type(q.rounds)~='table'then return nil,'Invalid round list'end
  if #(q.rounds or {})>32 then return nil,'Too many scheduled rounds'end
  for _,round in ipairs(q.rounds or {})do if not integer(round,1,999)then return nil,'Round numbers must be 1 to 999'end;sp.rounds[#sp.rounds+1]=round end
  if not sp.every and #sp.rounds==0 then return nil,'Set spawner rounds or an interval'end
  out.spawners[key]=sp
 end
 if size~=10 and size~=20 then out=L.resize(out,size<=10 and 10 or 20)end
 -- Legacy loose supplies become scheduled random supplies.
 for key in pairs(out.pickups)do if out.board[key].kind~='pit'and not out.spawners[key]then local x,z=key:match('(%d+),(%d+)');out.spawners[key]={item='random',first=1,every=3,phase=(tonumber(x)+2*tonumber(z))%3,chance=50}end end;out.pickups={}
 if out.map_type=='puzzle'then local q,err=L.puzzle(d.puzzle,out);if not q then return nil,err end;out.puzzle=q end
 return out
end
function L.puzzle(q,d)
 q=q or {};if (d.crates or {})[d.start.x..','..d.start.z]or (d.enemies or {})[d.start.x..','..d.start.z]then return nil,'Start square must be clear of crates and enemies'end;if type(q)~='table'then return nil,'Invalid puzzle settings'end
 local p={hint=tostring(q.hint or ''):sub(1,180),description=tostring(q.description or ''):sub(1,500),checkpoints={},targets={},hands={},equipment={},hull=q.hull or 5,power=q.power or 4,weapon=q.weapon or 'green_laser',limit=q.limit or 0,no_reboot=q.no_reboot==true,order=q.order or 1}
 if not integer(p.hull,1,5)or not integer(p.power,0,9)or not integer(p.limit,0,999)or not integer(p.order,1,9999)then return nil,'Hull 1-5 / power 0-9 / limit 0-999 / order 1-9999'end
 if not ({green_laser=true,double_laser=true,triple_laser=true,emp_generator=true,remote_control=true,tractor_beam=true,repulsor_beam=true})[p.weapon]then return nil,'Invalid starting weapon'end
 for _,key in ipairs({'checkpoints','targets','hands','equipment'})do if q[key]~=nil and type(q[key])~='table'then return nil,'Invalid puzzle '..key end end
 local seen={};for _,key in ipairs(q.checkpoints or {})do
  if type(key)~='string'or not d.board[key]or d.board[key].kind~='checkpoint'then return nil,'Checkpoint ('..tostring(key)..') is no longer a checkpoint tile. Update Puzzle Settings / Objectives.'end
  if seen[key]then return nil,'Checkpoint ('..key..') is selected twice. Update Puzzle Settings / Objectives.'end
  if key==d.start.x..','..d.start.z then return nil,'Checkpoint ('..key..') is also the start. Choose a different checkpoint in Puzzle Settings / Objectives.'end
  seen[key]=true;p.checkpoints[#p.checkpoints+1]=key
 end
 if #p.checkpoints>9 then return nil,'At most 9 checkpoints'end
 seen={};for _,id in ipairs(q.targets or {})do
  if type(id)~='string'then return nil,'Invalid target'end;local kind,key=id:match('^(%a+):(%d+,%d+)$')
  if seen[id]or not ((kind=='crate'and d.crates[key])or (kind=='obstacle'and d.enemies[key]))then return nil,'A selected target is missing from the map'end
  seen[id]=true;p.targets[#p.targets+1]=id
 end
 local allowed={battering_ram=true,thermal_camera=true,blueprint_archive=true,electroshield=true,reset_button=true,electromagnetic_brake=true,titanium_hull=true,gyro_stabilizer=true,hard_disk=true,holographic_memory=true,mechanical_arm=true,turret_gearbox=true,blink=true,range=true,cache=true}
 for k,v in pairs(q.equipment or {})do if not allowed[k]or not integer(v,0,9)then return nil,'Invalid starting equipment'end;if v>0 then p.equipment[k]=v end end
 for round,hand in pairs(q.hands or {})do local n=tonumber(round);if not integer(n,1,999)or type(hand)~='table'or #hand<5 or #hand>12 then return nil,'Explicit hands need 5-12 cards on rounds 1-999'end
  local a={};for _,card in ipairs(hand)do if not ({STEP=true,DASH=true,MOVE3=true,BACK=true,BACK2=true,LEFT=true,RIGHT=true,UTURN=true,WAIT=true})[card]then return nil,'Invalid scripted card'end;a[#a+1]=card end;p.hands[tostring(n)]=a
 end
 return p
end
function L.blank(size)
 size=size or 10
 local d={version=3,size=size,title='My Factory',start={x=2,z=2,dir=0},board={},walls={},overhead={},pickups={},spawners={},lasers={},pushers={},crates={},enemies={}}
 for z=1,size do for x=1,size do d.board[x..','..z]={kind='floor'}end end
 d.board['2,2']={kind='checkpoint'};d.board[(size-2)..',3']={kind='checkpoint'};d.board[(size-2)..','..(size-2)]={kind='checkpoint'};d.board['2,'..(size-2)]={kind='checkpoint'};return d
end
function L.resize(old,size)
 local function copy(t)if type(t)~='table'then return t end;local r={};for k,v in pairs(t)do r[k]=copy(v)end;return r end
 local d=L.blank(size);d.title=old.title;d.map_type=old.map_type;d.puzzle=copy(old.puzzle);d.start=copy(old.start or {x=2,z=2,dir=0});d.start.x=math.min(size,d.start.x);d.start.z=math.min(size,d.start.z)
 for z=1,size do for x=1,size do local k=x..','..z;d.board[k]=copy((old.board or {})[k]or {kind='floor'});if d.board[k].kind=='station'then d.board[k]={kind='checkpoint'}end
  for _,layer in ipairs({'overhead','spawners','crates','enemies'})do d[layer][k]=copy((old[layer]or {})[k])end
  if (old.pickups or {})[k]and d.board[k].kind~='pit'and not d.spawners[k]then d.spawners[k]={item='random',first=1,every=3,phase=(x+2*z)%3,chance=50}end
 end end
 for k,v in pairs(old.walls or {})do local x,z=k:match('^(%-?%d+),(%-?%d+)');if x and tonumber(x)<=size and tonumber(z)<=size then d.walls[k]=v end end
 for _,layer in ipairs({'lasers','pushers'})do for _,original in ipairs(old[layer]or {})do local q=copy(original);if not old.version and layer=='lasers'then if q.x==0 then q.x=1 elseif q.x==(old.size or 11)+1 then q.x=size end;if q.z==0 then q.z=1 elseif q.z==(old.size or 11)+1 then q.z=size end end;if q.x>=1 and q.z>=1 and q.x<=size and q.z<=size then d[layer][#d[layer]+1]=copy(q)end end end
 local t=d.board[d.start.x..','..d.start.z];if not t or t.kind~='checkpoint'then for z=1,size do for x=1,size do if d.board[x..','..z].kind=='checkpoint'then d.start={x=x,z=z,dir=0};return d end end end end
 return d
end
return L
