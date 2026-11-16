from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
lua.execute('''
local G=dofile(modpath..'/geometry.lua');local R=dofile(modpath..'/rules.lua');local base={x=12.5,y=9,z=6.5}
for dir=0,3 do local d=R.dirs[dir+1];for i=0,100 do local travel=.9*i/100;local ram={x=base.x+d.x*travel,y=base.y,z=base.z+d.z*travel};local anchor,length=G.pusher_rod(base,ram,dir)
 local rear=(anchor.x-base.x)*d.x+(anchor.z-base.z)*d.z;local tip=rear+length
 assert(rear>-.9 and rear<-.58,'rod always embedded inside housing');assert(tip>travel-.53 and tip<travel-.39,'rod tip always embedded inside plate');assert(math.abs(anchor.y-(base.y-.24))<1e-8)
end end
print('PASS piston connection throughout full stroke, reverse stroke and all four directions')
''')
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
lua.execute('''
local api=dofile(modpath..'/runtime.lua')(core,{});callbacks.on_mods_loaded();flush();local p=newplayer('Pilot');flush();assert(api.start('Pilot','race',1));tick(.1)
local count=0;for _,o in ipairs(objects)do local e=o.e;if o.p and e.pusher_rod then
 count=count+1;local base=copy(e.pusher_base);local d=({{x=0,z=1},{x=1,z=0},{x=0,z=-1},{x=-1,z=0}})[e.pusher_dir+1]
 e.target={x=base.x+d.x*.9,y=base.y,z=base.z+d.z*.9}
 for _=1,20 do callbacks.entity.on_step(e,.02);local distance=(o.p.x-base.x)*d.x+(o.p.z-base.z)*d.z;assert(math.abs(e.pusher_rod.props.visual_size.z-(.20+distance))<1e-8)end
 e.target=base;for _=1,20 do callbacks.entity.on_step(e,.02);local distance=(o.p.x-base.x)*d.x+(o.p.z-base.z)*d.z;assert(math.abs(e.pusher_rod.props.visual_size.z-(.20+distance))<1e-8)end
end end;assert(count>0)
print('PASS live entity updates maintain piston connection during extension and retraction')
''')
for name in ['pusher','pushram']:
 vertices=[list(map(float,line.split()[1:]))for line in (root/'mods/shift_circuit/models'/('sc_'+name+'.obj')).read_text().splitlines()if line.startswith('v ')]
 assert max(v[1]for v in vertices)-min(v[1]for v in vertices)<=4.8+1e-8
print('PASS pusher and plate remain under half a node tall')

# Live machine poses must not mix client-interpolated positions and immediate scales.
lua.execute("""
local G=dofile(modpath..'/geometry.lua');local checked=0
for _,o in ipairs(objects)do local e=o.e;if o.p and (e.pusher_rod or e.hydraulic_rod)then
 checked=checked+1
 local oldmove=o.move_to;o.move_to=function()error('machine plate must share the rod update timing')end
 if e.pusher_rod then
  local rod=e.pusher_rod;rod.move_to=function()error('rod cannot independently interpolate')end
  for _,travel in ipairs({0,.45,.9,.45,0})do
   local base=e.pusher_base;local dir=({{x=0,z=1},{x=1,z=0},{x=0,z=-1},{x=-1,z=0}})[e.pusher_dir+1]
   e.target={x=base.x+dir.x*travel,y=base.y,z=base.z+dir.z*travel}
   for i=1,20 do callbacks.entity.on_step(e,.05);local anchor,length=G.pusher_rod(base,o.p,e.pusher_dir);assert(same(rod.p,anchor)and math.abs(rod.props.visual_size.z-length)<1e-8)end
  end
 else
  local rod=e.hydraulic_rod;rod.move_to=function()error('crusher rod cannot independently interpolate')end
  for _,height in ipairs({4.3,2.65,1,2.65,4.3})do
   e.target={x=o.p.x,y=height,z=o.p.z}
   for i=1,20 do callbacks.entity.on_step(e,.05)
    assert(rod.p.y>o.p.y-.25 and rod.p.y<o.p.y+.125,'rod bottom recessed within platen')
    assert(math.abs(rod.p.y+rod.props.visual_size.y-e.hydraulic_ceiling)<1e-8,'rod top stays embedded in gantry')
   end
  end
 end
 o.move_to=oldmove
end end
assert(checked>0)
print('PASS synchronized machine poses, recessed crusher ends and no independent rod/plate interpolation')
""")
