-- Portable, data-only level format. Imported files never execute Lua.
local L={version=3}
local function integer(n,lo,hi)return type(n)=='number' and n==math.floor(n) and n>=lo and n<=hi end
function L.validate_submission(d)
 local count=0;for _,t in pairs(type(d)=='table'and type(d.board)=='table'and d.board or {})do if type(t)=='table'and (t.kind=='checkpoint'or t.kind=='station')then count=count+1 end end
 if count<2 then return nil,'Place at least 2 checkpoint candidates: one start and one checkpoint'end
 return L.validate(d)
end
function L.validate(d)
 if type(d)~='table' or (d.version~=1 and d.version~=2 and d.version~=3) or type(d.board)~='table' then return nil,'Unsupported level format' end
 for _,key in ipairs({'walls','overhead','pickups','lasers','pushers','spawners'})do if d[key]~=nil and type(d[key])~='table'then return nil,'Invalid layer: '..key end end
 if d.start~=nil and type(d.start)~='table'then return nil,'Invalid start' end
 local size=d.size or 11;if not integer(size,5,30)or (d.version==3 and size~=10 and size~=20)then return nil,'Choose a 10 or 20 square platform' end
 local out={version=3,size=size,title=tostring(d.title or 'Untitled'):sub(1,48),board={},walls={},overhead={},pickups={},spawners={},lasers={},pushers={}}
 local start=d.start or {};local flags={}
 for z=1,size do for x=1,size do local k=x..','..z;local t=d.board[k]
  if type(t)~='table'then return nil,'Every platform square needs a tile' end
  local q={kind=t.kind}
  if t.kind=='belt'then
   if not integer(t.dir,0,3)or not integer(t.speed,1,2)then return nil,'Invalid conveyor' end;q.dir=t.dir;q.speed=t.speed
   if t.entry~=nil then if not integer(t.entry,0,3)or (t.entry-t.dir)%2~=1 then return nil,'Conveyor bends must turn 90 degrees' end;q.entry=t.entry end
  elseif t.kind=='rotator'then if t.turn~=1 and t.turn~=3 then return nil,'Invalid rotator' end;q.turn=t.turn
  elseif t.kind=='station'or t.kind=='checkpoint'then q.kind='checkpoint';flags[#flags+1]={x=x,z=z,dir=0}
  elseif t.kind~='floor' and t.kind~='pit' and t.kind~='repair'then return nil,'Unknown tile' end
  out.board[k]=q
  if d.overhead and d.overhead[k]then out.overhead[k]={kind='crusher'}end
  local item=d.pickups and d.pickups[k];if item then if not ({thermal_camera=true,blueprint_archive=true,electroshield=true,titanium_hull=true,gyro_stabilizer=true,hard_disk=true,holographic_memory=true,green_laser=true,double_laser=true,remote_control=true,tractor_beam=true,repulsor_beam=true,mechanical_arm=true,turret_gearbox=true,repair=true,shield=true,cell=true,blink=true,range=true,cache=true,jammer=true})[item]then return nil,'Unknown pickup' end;out.pickups[k]=item end
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
  if not out.board[key]or out.board[key].kind=='pit'or type(q)~='table'then return nil,'Spawner requires a safe square'end
  if q.item and not ({random=true,thermal_camera=true,blueprint_archive=true,electroshield=true,titanium_hull=true,gyro_stabilizer=true,hard_disk=true,holographic_memory=true,green_laser=true,double_laser=true,remote_control=true,tractor_beam=true,repulsor_beam=true,mechanical_arm=true,turret_gearbox=true,repair=true,shield=true,cell=true,blink=true,range=true,cache=true,jammer=true})[q.item]then return nil,'Unknown spawner item'end
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
 return out
end
function L.blank(size)
 size=size or 10
 local d={version=3,size=size,title='My Factory',start={x=2,z=2,dir=0},board={},walls={},overhead={},pickups={},spawners={},lasers={},pushers={}}
 for z=1,size do for x=1,size do d.board[x..','..z]={kind='floor'}end end
 d.board['2,2']={kind='checkpoint'};d.board[(size-2)..',3']={kind='checkpoint'};d.board[(size-2)..','..(size-2)]={kind='checkpoint'};d.board['2,'..(size-2)]={kind='checkpoint'};return d
end
function L.resize(old,size)
 local function copy(t)if type(t)~='table'then return t end;local r={};for k,v in pairs(t)do r[k]=copy(v)end;return r end
 local d=L.blank(size);d.title=old.title;d.start=copy(old.start or {x=2,z=2,dir=0});d.start.x=math.min(size,d.start.x);d.start.z=math.min(size,d.start.z)
 for z=1,size do for x=1,size do local k=x..','..z;d.board[k]=copy((old.board or {})[k]or {kind='floor'});if d.board[k].kind=='station'then d.board[k]={kind='checkpoint'}end
  for _,layer in ipairs({'overhead','spawners'})do d[layer][k]=copy((old[layer]or {})[k])end
  if (old.pickups or {})[k]and d.board[k].kind~='pit'and not d.spawners[k]then d.spawners[k]={item='random',first=1,every=3,phase=(x+2*z)%3,chance=50}end
 end end
 for k,v in pairs(old.walls or {})do local x,z=k:match('^(%-?%d+),(%-?%d+)');if x and tonumber(x)<=size and tonumber(z)<=size then d.walls[k]=v end end
 for _,layer in ipairs({'lasers','pushers'})do for _,original in ipairs(old[layer]or {})do local q=copy(original);if not old.version and layer=='lasers'then if q.x==0 then q.x=1 elseif q.x==(old.size or 11)+1 then q.x=size end;if q.z==0 then q.z=1 elseif q.z==(old.size or 11)+1 then q.z=size end end;if q.x>=1 and q.z>=1 and q.x<=size and q.z<=size then d[layer][#d[layer]+1]=copy(q)end end end
 local t=d.board[d.start.x..','..d.start.z];if not t or t.kind~='checkpoint'then for z=1,size do for x=1,size do if d.board[x..','..z].kind=='checkpoint'then d.start={x=x,z=z,dir=0};return d end end end end
 return d
end
return L
