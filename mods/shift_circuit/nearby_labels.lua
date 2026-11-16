-- Per-viewer, distance-limited labels. Only nearby names are shown; full details remain available on inspection.
local L={}
function L.choose(objects,eye,viewer,persistent)
 local nearby={}
 for _,o in ipairs(objects)do local p=o:get_pos();local e=p and o:get_luaentity();local q=e and e.nearby_label
  if q and (q.persistent==true)==(persistent==true)and q.text~=''and q.owner~=viewer and not e.collecting and not e.life and not e.fallen then
   local dx,dy,dz=p.x-eye.x,p.y-eye.y,p.z-eye.z;local distance=dx*dx+dy*dy+dz*dz
   if q.persistent or distance<=q.range*q.range then nearby[#nearby+1]={text=q.text,color=q.color or 0x94e3cf,distance=distance,pos={x=p.x,y=p.y+(q.height or 1),z=p.z}}end
  end
 end
 table.sort(nearby,function(a,b)if a.distance~=b.distance then return a.distance<b.distance end;return a.text<b.text end)
 return nearby
end
return L
