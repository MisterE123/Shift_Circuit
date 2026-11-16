from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True)
lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
lua.execute("""
local Q=dofile(modpath..'/courses.lua');local R=dofile(modpath..'/rules.lua');local L=dofile(modpath..'/levels.lua')
local B=dofile(modpath..'/board_builder.lua');local T=dofile(modpath..'/course_routes.lua')
local function same(a,b)if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end;for k,v in pairs(a)do if not same(v,b[k])then return false end end;for k in pairs(b)do if a[k]==nil then return false end end;return true end
for _,size in ipairs({10,20})do
 local d=L.blank(size);d.board['3,4']={kind='belt',dir=0,entry=3,speed=2}
 d.board['4,5']={kind='factory',dir=2,pattern='adjacent',crate_kind='steel'}
 d.walls={};for dir=0,3 do d.walls[R.edge(3,4,dir)]=true end
 d.enemies={['3,4']={kind='patroller',dir=3}};d.crates={['5,6']={kind='steel'}}
 d.overhead={['3,4']={kind='crusher',parity=1}};d.spawners={['3,4']={first=2,every=3}}
 d.lasers={{x=0,z=4,dir=1,count=3}};d.pushers={{x=3,z=4,dir=2,parity=0}}
 local rotated=Q.rotate(R,d,1);local x,z=4,size-2
 assert(rotated.board[R.key(x,z)].dir==1 and rotated.board[R.key(x,z)].entry==0)
 assert(rotated.enemies[R.key(x,z)].dir==0 and rotated.overhead[R.key(x,z)].parity==1)
 assert(rotated.crates[R.key(6,size-4)].kind=='steel'and rotated.spawners[R.key(x,z)].first==2)
 for dir=0,3 do assert(rotated.walls[R.edge(x,z,dir)])end
 assert(rotated.lasers[1].x==4 and rotated.lasers[1].z==size+1 and rotated.lasers[1].dir==2)
 assert(rotated.pushers[1].dir==3 and rotated.board[R.key(5,size-3)].dir==3)
 assert(d.board['3,4'].dir==0,'source never mutated')
 assert(same(Q.rotate(R,rotated,3),Q.rotate(R,d,0)),'four rotations restore every layer')
 local layout=B.new(1);assert(B.place(layout,'test',size,0,0));assert(B.rotate(layout,0,0))
 local candidates=T.candidates(layout,{{id='test',data=d}})
 for _,p in ipairs(candidates)do assert(rotated.board[R.key(p.x,p.z)].kind=='checkpoint','route markers track rotation')end
 local s=Q.layout(R,{d},1,layout.items)
 assert(s.board[R.key(x,z)].dir==1 and s.walls[R.edge(x,z,1)],'runtime assembly uses rotated data')
end
local layout=B.new(1)
for z=0,3 do for x=0,3 do assert(B.place(layout,'test',10,x,z))end end
assert(#layout.items==16,'entire 40x40 area usable regardless of former count cap')
assert(not B.place(layout,'test',10,4,0),'40x40 boundary enforced')
print('PASS four-way board rotation, all directional layers and boundary walls, preview route coordinates, source immutability, full 40x40 capacity')
""")
