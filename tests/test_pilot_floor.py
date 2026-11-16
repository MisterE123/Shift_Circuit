from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split("ui_events={};shift_circuit=dofile",1)[0]
lua.execute(source)
lua.execute("""
local placed={}
core.set_node=function(p,n)placed[p.x..','..p.y..','..p.z]=n.name end
local api=dofile(modpath..'/runtime.lua')(core,{})
callbacks.on_mods_loaded();flush();newplayer('Pilot');flush()
local L=dofile(modpath..'/levels.lua');local R=dofile(modpath..'/rules.lua')
local d=L.blank(10)
d.board['3,3']={kind='pit'}
d.board['4,3']={kind='trapdoor',open=true}
d.board['5,3']={kind='trapdoor',open=false}
api.edit_level(d,true)
local support=nodes['shift_circuit:collider']
assert(support.walkable and support.drawtype=='airlike' and support.pointable==false,'invisible, non-targetable pilot support')
for _,x in ipairs({0,3,4,5,11})do
 for dx=0,1 do for dz=0,1 do
  assert(placed[(x*2+dx)..',0,'..(6+dz)]=='shift_circuit:collider','support spans pits, trapdoors and perimeter moat')
 end end
end
local s;for i=1,30 do local k,v=debug.getupvalue(api.snapshot,i);if k=='S'then s=v end end
local b=s.bots[1];b.x=3;b.z=2;b.dir=0
R.move(s,b,0)
assert(b.down and b.destroyed_by=='Fell into a pit','pilot support does not protect robots')
print('PASS invisible pilot floor over holes, open/closed trapdoors and moat; robots still fall')
""")
