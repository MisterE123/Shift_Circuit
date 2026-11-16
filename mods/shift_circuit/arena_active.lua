-- Arena visuals are transient entities: keep their mapblocks active while the room exists.
return function(core)
 local held={};local api={}
 function api.release()
  if core.forceload_free_block then for _,p in pairs(held)do core.forceload_free_block(p,true)end end
  held={}
 end
 function api.acquire(origin,size)
  if not core.forceload_block then return end
  local n=core.MAP_BLOCKSIZE or 16
  for z=math.floor((origin.z-6)/n),math.floor((origin.z+size*2+8)/n)do
   for x=math.floor((origin.x-6)/n),math.floor((origin.x+size*2+8)/n)do
    for y=math.floor((origin.y-6)/n),math.floor((origin.y+26)/n)do
     local key=x..','..y..','..z
     if not held[key]then local p={x=x*n,y=y*n,z=z*n}
      -- Explicit per-call limit: no persistent server setting changes. Room bounds
      -- constrain the allocation, and cleanup releases every transient reference.
      if core.forceload_block(p,true,-1)then held[key]=p end
     end
    end
   end
  end
 end
 return api
end
