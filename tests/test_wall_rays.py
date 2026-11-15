from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().path=(root/'mods/shift_circuit').as_posix()
lua.execute("""
local R=dofile(path..'/rules.lua');local C=dofile(path..'/campaign.lua');local Q=dofile(path..'/courses.lua')
local checks=0
local function verify(s)
 for key,solid in pairs(s.walls)do if solid then local w=R.wall(key)
  for _,direction in ipairs(w.axis=='E'and {1,3}or {0,2})do local d=R.dirs[direction+1]
   for power=1,3 do for distance=1,5 do
    local x=w.x-d.x*(distance-.5);local z=w.z-d.z*(distance-.5)
    local b={id='victim',x=w.x+d.x*.5,z=w.z+d.z*.5,hp=5,shield=0};s.bots={b}
    local _,target,blocked=R.trace(s,x,z,direction,12);assert(not target and blocked,'wall stops ray before target')
    R.fire(s,x,z,direction,power,12);assert(b.hp==5 and not b.down,'single/double/triple cannot damage through wall')
    local shot=s.shots[#s.shots];assert(shot.wall and shot.range<=distance-.5,'visual endpoint stops at wall')
    checks=checks+1
   end end
  end
 end end
end
for board=1,3 do verify(C.setup(R,1,'race',board))end
verify(Q.assemble(R,{C.setup(R,1,'race',1),C.setup(R,1,'race',2),C.setup(R,1,'race',3)},7))
print('PASS '..checks..' thin-wall ray/damage cases, both directions, all laser powers, translated mixed boards')
""")
