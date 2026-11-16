-- Assemble data-only square platforms and number reachable checkpoint candidates.
local Q={}
local function copy(t)if type(t)~='table'then return t end;local r={};for k,v in pairs(t)do r[k]=copy(v)end;return r end
-- Rotate a complete authored board without changing its source data.
function Q.rotate(R,data,turns)
 local d=copy(data)
 for _=1,(turns or 0)%4 do
  local size=d.size
  local function point(x,z)return z,size+1-x end
  local function facing(v)
   if type(v)~='table'then return v end
   local q=copy(v)
   if q.dir~=nil then q.dir=(q.dir+1)%4 end
   if q.entry~=nil then q.entry=(q.entry+1)%4 end
   return q
  end
  for _,layer in ipairs({'board','overhead','pickups','spawners','crates','enemies'})do
   local out={}
   for key,v in pairs(d[layer]or {})do
    local x,z=key:match('^(%-?%d+),(%-?%d+)$');x,z=point(tonumber(x),tonumber(z))
    out[R.key(x,z)]=facing(v)
   end
   d[layer]=out
  end
  local walls={}
  for key,v in pairs(d.walls or {})do
   local x,z,axis=key:match('^(%-?%d+),(%-?%d+),([NE])$');x,z=point(tonumber(x),tonumber(z))
   walls[R.edge(x,z,axis=='N'and 1 or 2)]=v
  end
  d.walls=walls
  for _,layer in ipairs({'lasers','pushers'})do
   for i,v in ipairs(d[layer]or {})do local q=facing(v);q.x,q.z=point(v.x,v.z);d[layer][i]=q end
  end
  if d.start then local q=facing(d.start);q.x,q.z=point(q.x,q.z);d.start=q end
 end
 return d
end
function Q.number(R,s,count,route)
 local candidates={};local available={};s.route_error=nil
 for key,t in pairs(s.board)do if t.kind=='checkpoint'or t.kind=='station'then candidates[#candidates+1]=key;available[key]=true;s.board[key]={kind='save'}end end
 table.sort(candidates)
 local start=route and route.start or s.start
 if not start or not available[R.key(start.x,start.z)]then
  if route and route.start then s.route_error='Start must occupy an available checkpoint candidate';s.checkpoint_count=0;return 0 end
  local key=candidates[1];if key then local x,z=key:match('(%d+),(%d+)');start={x=tonumber(x),z=tonumber(z),dir=0}end
 end
 if not start then s.checkpoint_count=0;return 0 end
 s.start={x=start.x,z=start.z,dir=start.dir or 0};available[R.key(start.x,start.z)]=nil;s.board[R.key(start.x,start.z)]={kind='floor'}
 local from=s.start;local chosen=0;local manual=route and route.checkpoints and #route.checkpoints>0
 for i=1,(manual and #route.checkpoints or math.min(count or 3,#candidates-1))do
  local queue={{x=from.x,z=from.z}};local distances={[R.key(from.x,from.z)]=0};local head=1
  while queue[head]do local at=queue[head];head=head+1;for dir,d in ipairs(R.dirs)do local x,z=at.x+d.x,at.z+d.z;local k=R.key(x,z)
   if not distances[k]and R.tile(s,x,z).kind~='pit'and not R.blocked(s,at.x,at.z,dir-1)then distances[k]=distances[R.key(at.x,at.z)]+1;queue[#queue+1]={x=x,z=z}end
  end end
  local best,dist
  if manual then local q=route.checkpoints[i];best=R.key(q.x,q.z);if not available[best]or not distances[best]then s.route_error='Checkpoint '..i..' is unavailable or unreachable';break end
  else for _,key in ipairs(candidates)do local d=distances[key];if available[key]and d and (not dist or d>dist)then best=key;dist=d end end end
  if not best then break end
  available[best]=nil;chosen=chosen+1;s.board[best]={kind='station',number=chosen};local x,z=best:match('(%d+),(%d+)');from={x=tonumber(x),z=tonumber(z)}
 end
 s.checkpoint_count=chosen;return chosen
end
function Q.assemble(R,platforms,count,layout,route)
 if layout then return Q.layout(R,platforms,count,layout,route)end
 local largest=5;for _,d in ipairs(platforms)do largest=math.max(largest,d.size or 11)end
 local columns=#platforms>1 and 2 or 1;local rows=math.ceil(#platforms/columns);local side=math.max(columns,rows)*(largest+1)-1
 local s={size=side,round=1,level=1,mode='race',board={},bots={},walls={},overhead={},pickups={},spawners={},lasers={},pushers={},crates={},enemies={},platform_count=#platforms,platforms={}}
 for z=1,side do for x=1,side do s.board[R.key(x,z)]={kind='pit'}end end
 local centers={}
 for i,d in ipairs(platforms)do
  local size=d.size or 11;local ox=(i-1)%columns*(largest+1)+math.floor((largest-size)/2);local oz=math.floor((i-1)/columns)*(largest+1)+math.floor((largest-size)/2)
  centers[i]={x=ox+math.ceil(size/2),z=oz+math.ceil(size/2)};s.platforms[i]={x=ox+1,z=oz+1,size=size,title=d.title}
  for key,t in pairs(d.board)do local x,z=key:match('(%d+),(%d+)');if tonumber(x)<=size and tonumber(z)<=size then s.board[R.key(tonumber(x)+ox,tonumber(z)+oz)]=copy(t)end end
  for key in pairs(d.walls or {})do local x,z,axis=key:match('(%-?%d+),(%-?%d+),([NE])');s.walls[(tonumber(x)+ox)..','..(tonumber(z)+oz)..','..axis]=true end
  for _,layer in ipairs({'overhead','pickups','spawners','crates','enemies'})do for key,v in pairs(d[layer]or {})do local x,z=key:match('(%d+),(%d+)');s[layer][R.key(tonumber(x)+ox,tonumber(z)+oz)]=copy(v)end end
  for _,layer in ipairs({'lasers','pushers'})do for _,v in ipairs(d[layer]or {})do local q=copy(v);q.x=q.x+ox;q.z=q.z+oz;s[layer][#s[layer]+1]=q end end
  if i==1 then local start=d.start or {x=2,z=2,dir=0};s.start={x=start.x+ox,z=start.z+oz,dir=start.dir or 0}end
 end
 -- Bridge between safe boundary squares; never carve through platform interiors.
 for i=2,#centers do
  local previous=i%2==0 and i-1 or i-2;local a=s.platforms[previous];local b=s.platforms[i];local horizontal=i%2==0
  local first=horizontal and math.max(a.z,b.z)or math.max(a.x,b.x)
  local last=horizontal and math.min(a.z+a.size-1,b.z+b.size-1)or math.min(a.x+a.size-1,b.x+b.size-1)
  local best,distance
  for line=first,last do
   local ax,az=horizontal and a.x+a.size-1 or line,horizontal and line or a.z+a.size-1
   local bx,bz=horizontal and b.x or line,horizontal and line or b.z
   local delta=math.abs(line-(first+last)/2)
   if R.tile(s,ax,az).kind~='pit'and R.tile(s,bx,bz).kind~='pit'and (not distance or delta<distance)then best={ax,az,bx,bz};distance=delta end
  end
  if best then
   local x,z,tx,tz=best[1],best[2],best[3],best[4];local dir=horizontal and 1 or 0
   while x~=tx or z~=tz do s.walls[R.edge(x,z,dir)]=nil;if horizontal then x=x+1 else z=z+1 end
    if x~=tx or z~=tz then s.board[R.key(x,z)]={kind='floor'}end
   end
  end
 end
 Q.number(R,s,count);return s
end
-- Placed platforms meet directly, without invented connecting bridges.
function Q.layout(R,platforms,count,layout,route)
 local side=10;local minx,minz=60,60
 for _,q in ipairs(layout)do minx=math.min(minx,q.x*10);minz=math.min(minz,q.z*10)end
 for i,q in ipairs(layout)do side=math.max(side,q.x*10-minx+platforms[i].size,q.z*10-minz+platforms[i].size)end
 local s={size=side,round=1,level=1,mode='race',board={},bots={},walls={},overhead={},pickups={},spawners={},lasers={},pushers={},crates={},enemies={},platform_count=#platforms,platforms={}}
 for z=1,side do for x=1,side do s.board[R.key(x,z)]={kind='pit'}end end
 for i,d in ipairs(platforms)do
  d=Q.rotate(R,d,layout[i].rotation)
  local ox,oz=layout[i].x*10-minx,layout[i].z*10-minz;s.platforms[i]={x=ox+1,z=oz+1,size=d.size,title=d.title}
  for k,t in pairs(d.board)do local x,z=k:match('^(%d+),(%d+)$');s.board[R.key(tonumber(x)+ox,tonumber(z)+oz)]=copy(t)end
  for k,v in pairs(d.walls or {})do local x,z,axis=k:match('^(%-?%d+),(%-?%d+),([NE])$');s.walls[(tonumber(x)+ox)..','..(tonumber(z)+oz)..','..axis]=v end
  for _,layer in ipairs({'overhead','spawners','crates','enemies'})do for k,v in pairs(d[layer]or {})do local x,z=k:match('^(%d+),(%d+)$');s[layer][R.key(tonumber(x)+ox,tonumber(z)+oz)]=copy(v)end end
  for _,layer in ipairs({'lasers','pushers'})do for _,v in ipairs(d[layer]or {})do local q=copy(v);q.x=q.x+ox;q.z=q.z+oz;s[layer][#s[layer]+1]=q end end
  if i==1 then s.start=copy(d.start);s.start.x=s.start.x+ox;s.start.z=s.start.z+oz end
 end
 local selected
 if route then selected={checkpoints={}};if route.start then selected.start={x=route.start.x-minx,z=route.start.z-minz,dir=route.start.dir or 0}end
  for _,q in ipairs(route.checkpoints or {})do selected.checkpoints[#selected.checkpoints+1]={x=q.x-minx,z=q.z-minz}end
 end
 Q.number(R,s,count,selected);return s
end
return Q
