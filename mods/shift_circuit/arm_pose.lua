local A={duration=1.2,grasp=.52}
local function mix(a,b,t)return {x=a.x+(b.x-a.x)*t,y=a.y+(b.y-a.y)*t,z=a.z+(b.z-a.z)*t}end
local function ease(t)t=math.max(0,math.min(1,t));return t*t*(3-2*t)end
function A.pose(p,yaw,scale,motion)
 local forward={x=-math.sin(yaw),z=math.cos(yaw)}
 local root={x=p.x-forward.x*.18*scale,y=p.y+1.7*scale,z=p.z-forward.z*.18*scale}
 local rest={x=root.x+forward.x*.45*scale,y=root.y+.18*scale,z=root.z+forward.z*.45*scale}
 local amount,open=0,.15
 if motion then local t=motion.elapsed
  amount=t<.45 and ease(t/.45)or (t<.65 and 1 or 1-ease((t-.65)/.55))
  open=t<.45 and .15+.07*amount or (t<.62 and .22-.16*ease((t-.45)/.17)or .06+.09*ease((t-.95)/.25))
 end
 local tip=mix(rest,motion and motion.target or rest,amount)
 tip.y=tip.y+math.sin(amount*math.pi)*.25*scale
 local dx,dy,dz=tip.x-root.x,tip.y-root.y,tip.z-root.z
 local distance=math.sqrt(dx*dx+dy*dy+dz*dz);local ux,uy,uz=dx/distance,dy/distance,dz/distance
 local px,py,pz=-ux*uy,1-uy*uy,-uz*uy;local plen=math.sqrt(px*px+py*py+pz*pz)
 if plen<.001 then px,py,pz=math.cos(yaw),0,math.sin(yaw);plen=1 end
 local length=math.max(1.25*scale,distance*.5+.02*scale)
 local bend=math.sqrt(math.max(0,length*length-distance*distance*.25))
 local elbow={x=(root.x+tip.x)*.5+px/plen*bend,y=(root.y+tip.y)*.5+py/plen*bend,z=(root.z+tip.z)*.5+pz/plen*bend}
 return root,elbow,tip,open*scale
end
return A
