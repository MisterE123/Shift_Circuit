local T={}
function T.candidates(layout,choices)
 local byid={};for _,q in ipairs(choices)do byid[q.id]=q.data end
 local points,lookup={},{};local default
 for _,p in ipairs(layout.items)do local d=byid[p.id];if d then
  for z=1,d.size do for x=1,d.size do local t=d.board[x..','..z]
   if t and (t.kind=='checkpoint'or t.kind=='station')then local q={x=p.x*10+x,z=p.z*10+z};points[#points+1]=q;lookup[q.x..','..q.z]=q
    if not default then default=q end
   end
  end end
  if not default then default=nil end
 end end
 local first=layout.items[1];local d=first and byid[first.id]
 if d and d.start then local key=(first.x*10+d.start.x)..','..(first.z*10+d.start.z);default=lookup[key]or default end
 return points,lookup,default
end
function T.validate(route,layout,choices)
 if not route then return {checkpoints={}}end
 if type(route)~='table'or (route.checkpoints~=nil and type(route.checkpoints)~='table')then return nil,'Invalid route'end
 local _,lookup,default=T.candidates(layout,choices);local out={checkpoints={}};local used={}
 local start=route.start or default
 if start then
  local key=tostring(start.x)..','..tostring(start.z);if not lookup[key]then return nil,'Start candidate is no longer on this course'end
  used[key]=true;if route.start then out.start={x=start.x,z=start.z,dir=0}end
 end
 if #(route.checkpoints or {})>9 then return nil,'Choose at most nine checkpoints'end
 for _,q in ipairs(route.checkpoints or {})do
  local key=tostring(q.x)..','..tostring(q.z);if not lookup[key]or used[key]then return nil,'Choose distinct checkpoint candidates apart from the start'end
  used[key]=true;out.checkpoints[#out.checkpoints+1]={x=q.x,z=q.z}
 end
 return out
end
function T.click(route,layout,choices,mode,x,z)
 local _,lookup,default=T.candidates(layout,choices);local key=x..','..z
 if not lookup[key]then return false,'Click a checkpoint candidate'end
 route.checkpoints=route.checkpoints or {}
 if mode=='start'then
  route.start={x=x,z=z,dir=0};for i=#route.checkpoints,1,-1 do local q=route.checkpoints[i];if q.x==x and q.z==z then table.remove(route.checkpoints,i)end end
  return true,'Start selected'
 end
 local start=route.start or default;if start and start.x==x and start.z==z then return false,'Choose a different candidate from the start'end
 for i,q in ipairs(route.checkpoints)do if q.x==x and q.z==z then table.remove(route.checkpoints,i);return true,'Checkpoint removed; route renumbered'end end
 if #route.checkpoints>=9 then return false,'Nine checkpoints maximum'end
 route.checkpoints[#route.checkpoints+1]={x=x,z=z};return true,'Checkpoint '..#route.checkpoints..' selected'
end
return T
