local B={}
function B.next_rounds(sp,round)
 local values={};local seen={}
 local function add(n)if n>=round and not seen[n]then values[#values+1]=n;seen[n]=true end end
 for _,n in ipairs(sp.rounds or {})do add(n)end
 if sp.every then local first=(sp.first or 1)+(sp.phase or 0);local n=first+math.max(0,math.ceil((round-first)/sp.every))*sp.every;for i=0,2 do add(n+i*sp.every)end end
 table.sort(values);return {values[1],values[2],values[3]}
end
function B.texture(q,round,step)
 if q.factory then return 'sc_schedule_factory_rounds.png'end
 if q.parity~=nil then return 'sc_schedule_steps_'..q.parity..'_'..(step or 0)..'.png'end
 local result='[combine:188x56:0,0='..(q.factory and 'sc_schedule_factory_rounds.png'or 'sc_schedule_rounds.png');local next=B.next_rounds(q.spawner,round)
 for i=1,3 do local label=tostring(next[i]or '-');local x=(i-1)*60+9
  for j=1,#label do local c=label:sub(j,j);result=result..':'..(x+(j-1)*14)..',26=sc_schedule_digit_'..(c=='-'and 'dash'or c)..'.png'end
 end
 return result
end
function B.nearby(objects,eye)
 local found={}
 for _,o in ipairs(objects)do local p=o:get_pos();local e=p and o:get_luaentity();local q=e and e.schedule_badge
  if q then local distance=(p.x-eye.x)^2+(p.y-eye.y)^2+(p.z-eye.z)^2
   if distance<=196 then found[#found+1]={schedule=q,distance=distance,pos={x=p.x,y=p.y+(q.height or 1.2),z=p.z}}end
  end
 end
 table.sort(found,function(a,b)return a.distance<b.distance end);return found
end
return B
