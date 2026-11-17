from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().path=(root/'mods/shift_circuit').as_posix()
lua.execute("""
local R=dofile(path..'/rules.lua');local L=dofile(path..'/levels.lua')
local function check(x,z,dir,explicit,filled,kind)
 local s=L.blank(10);s.bots={};s.walls={};s.crates={};local d=R.dirs[dir+1];local tx,tz=x+d.x,z+d.z;local key=R.key(tx,tz)
 if explicit then s.board[key]={kind='pit'}else s.board[key]=nil end
 s.crates[R.key(x,z)]={kind=kind};R.init_objects(s);local c=R.at(s,x,z);assert(c and c.crate)
 assert(R.move(s,c,dir));assert(c.down,'crate is consumed by pit')
 if filled then assert(s.board[key].kind=='floor'and s.board[key].filled)
 else assert(not s.board[key]or s.board[key].kind=='pit','perimeter stays open');assert(not s.geometry_serial,'no new outside geometry')end
end
for _,kind in ipairs({'loot','steel'})do
 for _,explicit in ipairs({false,true})do
  check(1,5,3,explicit,false,kind);check(10,5,1,explicit,false,kind)
  check(5,1,2,explicit,false,kind);check(5,10,0,explicit,false,kind)
 end
 check(4,5,1,true,true,kind) -- authored interior pit / gap between platforms
 check(2,5,3,true,true,kind) -- last playable tile remains usable; moat is beyond it
end
print('PASS loot/steel crates vanish at all four outer edges, explicit outside pits cannot extend the board, and interior gaps remain fillable')
""")
