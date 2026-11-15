local I={}
function I.describe(o,title,detail,box)
 if not o then return end
 o:get_luaentity().hint=title..'\n'..detail
 o:set_properties({pointable=true,selectionbox=box or {-.6,-.5,-.6,.6,.8,.6},rotate_selectionbox=true})
end
function I.pointed(core,p,range)
 local eye=p:get_pos();local properties=p:get_properties()
 eye={x=eye.x,y=eye.y+(properties.eye_height or 1.625),z=eye.z}
 local d=p:get_look_dir();local finish={x=eye.x+d.x*range,y=eye.y+d.y*range,z=eye.z+d.z*range}
 for hit in core.raycast(eye,finish,true,false) do
   if hit.type=='object' and hit.ref~=p then local e=hit.ref:get_luaentity();if e and e.hint then return e.hint end
   elseif hit.type=='node' then return '' end
 end
 return ''
end
return I
