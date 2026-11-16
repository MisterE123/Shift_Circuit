-- A texture composed from the level data, never a separately maintained screenshot.
local P={}
function P.texture(d)
 local size=d.size;local parts={'[combine:'..(size*8)..'x'..(size*8)..':0,0=sc_map_base_'..size..'.png'}
 local function icon(x,z,name)
  if x>=1 and z>=1 and x<=size and z<=size then parts[#parts+1]=':'..((x-1)*8)..','..((z-1)*8)..'=sc_map_'..name..'.png'end
 end
 for z=1,size do for x=1,size do local k=x..','..z;local t=d.board[k]or {kind='pit'}
  if t.kind=='belt'then icon(x,z,(t.entry~=nil and 'bend_'..((t.dir-t.entry)%4==1 and 'right_'or 'left_')or 'belt_')..(t.speed or 1)..'_'..(t.dir or 0))
  elseif t.kind=='factory'then icon(x,z,'factory_'..t.pattern..'_'..t.dir)
  elseif t.kind=='rotator'then icon(x,z,'rotator_'..t.turn)
  elseif t.kind=='checkpoint'or t.kind=='station'then icon(x,z,'checkpoint')
  elseif t.kind=='pit'or t.kind=='repair'then icon(x,z,t.kind)end
  if t.kind=='plate'then icon(x,z,'plate')elseif t.kind=='trapdoor'then icon(x,z,t.open and 'trap_open'or 'trap_closed')end
  if (d.crates or {})[k]then icon(x,z,'crate_'..d.crates[k].kind)end
  if (d.enemies or {})[k]then icon(x,z,'enemy_'..d.enemies[k].kind)end
  if (d.overhead or {})[k]then local q=d.overhead[k];icon(x,z,type(q)=='table'and q.parity==1 and 'crusher_odd'or 'crusher')end
  if (d.spawners or {})[k]then icon(x,z,'spawner')end
 end end
 for _,layer in ipairs({'lasers','pushers'})do for _,q in ipairs(d[layer]or {})do icon(q.x,q.z,(layer=='lasers'and 'laser_'or 'pusher_')..q.dir)end end
 local edges={};for k in pairs(d.walls or {})do edges[#edges+1]=k end;table.sort(edges)
 for _,k in ipairs(edges)do local x,z,axis=k:match('^(%-?%d+),(%-?%d+),([NE])$');x=tonumber(x);z=tonumber(z)
  if axis=='N'and x>=1 and x<=size and z>=0 and z<=size then parts[#parts+1]=':'..((x-1)*8)..','..math.max(0,math.min(size*8-1,z*8-1))..'=sc_map_wall_h.png'
  elseif axis=='E'and z>=1 and z<=size and x>=0 and x<=size then parts[#parts+1]=':'..math.max(0,math.min(size*8-1,x*8-1))..','..((z-1)*8)..'=sc_map_wall_v.png'end
 end

 return table.concat(parts)
end
return P
