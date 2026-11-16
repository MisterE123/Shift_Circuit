from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().path=(root/'mods/shift_circuit').as_posix()
lua.execute("""
local W=dofile(path..'/world_tag_order.lua')
local tags={{id=7,pos={x=12,y=0,z=0}},{id=3,pos={x=2,y=0,z=0}},{id=9,pos={x=6,y=0,z=0}}}
W.sort(tags,{x=0,y=0,z=0});assert(tags[1].id==3 and tags[1].z>tags[2].z and tags[2].z>tags[3].z)
for _,q in ipairs(tags)do assert(q.z<W.owner and W.owner<0,'owner remains above tags and below interface')end
W.sort(tags,{x=15,y=0,z=0});assert(tags[1].id==7,'ordering changes with viewer position')
print('PASS shared distance ordering for world tags, owner priority, and interface precedence')
""")
