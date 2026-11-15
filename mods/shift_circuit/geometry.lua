-- Engine-space geometry shared by beam rendering and conveyor animation.
local G={}
local atan2=math.atan2 or math.atan
local dirs={{x=0,z=1},{x=1,z=0},{x=0,z=-1},{x=-1,z=0}}
-- Client updateNodePos negates ObjectRef rotation before applying its matrix.
function G.yaw(dir) return -dir*math.pi/2 end
-- The rod is anchored inside the housing and ends inside the moving plate.
function G.pusher_rod(base,ram,dir)
 local d=dirs[dir+1];local travel=(ram.x-base.x)*d.x+(ram.z-base.z)*d.z
 return {x=base.x-d.x*.69,y=base.y-.24,z=base.z-d.z*.69},math.max(.01,.20+travel)
end
-- One short mesh on the solid side of each floor/pit boundary. No tile UV
-- rotation or full-square overlays: the position is the actual shared edge.
function G.pit_edges(s,R)
 local edges={}
 for z=1,s.size do for x=1,s.size do if R.tile(s,x,z).kind~='pit' then
  for i,d in ipairs(dirs)do if R.tile(s,x+d.x,z+d.z).kind=='pit' then
   local left=R.tile(s,x-d.z,z+d.x).kind=='pit'
   local right=R.tile(s,x+d.z,z-d.x).kind=='pit'
   edges[#edges+1]={x=x*2+.5+d.x*.94,y=.535,z=z*2+.5+d.z*.94,dir=i-1,corners=(left and 1 or 0)+(right and 2 or 0)}
  end end
 end end end
 return edges
end
function G.beam(x,z,dir,power,index,distance,robot,mount,kind,body_dir)
 local d=dirs[dir+1];local side=(index-(power+1)/2)*.375
 local ox,oz=d.z*side,-d.x*side;local y=1;local muzzle=.1875
 if robot then
  local body=dirs[(body_dir or dir)+1];local mountside=0
  ox=ox+body.z*mountside+body.x*.05;oz=oz-body.x*mountside+body.z*.05
  muzzle=({remote_control=.4,tractor_beam=.42,repulsor_beam=.38})[kind]or .53
  y=({remote_control=2.21,tractor_beam=2.17,repulsor_beam=2.185,double_laser=2.17})[kind]or 2.15
 end
 ox=ox+d.x*muzzle;oz=oz+d.z*muzzle
 return {x=x*2+.5+ox,y=y,z=z*2+.5+oz},math.max(0,distance*2-ox*d.x-oz*d.z)
end
function G.belt(t,u)
 local out=dirs[t.dir+1]
 if not t.entry or t.entry==t.dir then return {x=out.x*(u*2-1),z=out.z*(u*2-1)},G.yaw(t.dir) end
 local incoming=dirs[t.entry+1];local a=u*math.pi/2
 local x=-incoming.x*(1-math.sin(a))+out.x*(1-math.cos(a));local z=-incoming.z*(1-math.sin(a))+out.z*(1-math.cos(a))
 local dx=incoming.x*math.cos(a)+out.x*math.sin(a);local dz=incoming.z*math.cos(a)+out.z*math.sin(a)
 return {x=x,z=z},-atan2(dx,dz)
end
return G
