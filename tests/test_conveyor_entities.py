from pathlib import Path
import struct
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1]
# Read the actual exported B3D, not the generator's in-memory values.
data=(root/'mods/shift_circuit/models/sc_tread_straight.b3d').read_bytes()
keys=[];weights=[];vertices=[];triangles=[]
def chunks(data):
 pos=0
 while pos<len(data):
  tag=data[pos:pos+4];length=struct.unpack_from('<i',data,pos+4)[0];body=data[pos+8:pos+8+length];assert len(body)==length
  yield tag,body;pos+=length+8
 assert pos==len(data)
def visit(data):
 for tag,b in chunks(data):
  if tag==b'BB3D':visit(b[4:])
  elif tag==b'NODE':visit(b[b.index(0)+41:])
  elif tag==b'MESH':visit(b[4:])
  elif tag==b'VRTS':
   assert struct.unpack_from('<3i',b)==(1,1,2)
   vertices.extend(struct.iter_unpack('<8f',b[12:]))
  elif tag==b'TRIS':triangles.extend(struct.iter_unpack('<3i',b[4:]))
  elif tag==b'BONE':weights.append(list(struct.iter_unpack('<if',b)))
  elif tag==b'KEYS':
   assert struct.unpack_from('<i',b)[0]==3
   keys.append(list(struct.iter_unpack('<i6f',b[4:])))
visit(data)
assert len(keys)==len(weights)==12 and all(len(k)==25 for k in keys)
assert sorted(i for bone in weights for i,w in bone)==list(range(len(vertices)))
assert all(0<=v<len(vertices) for tri in triangles for v in tri)
shapes=[]
for f in range(25):
 shape=[]
 for bone,poses in zip(weights,keys):
  frame,x,y,z,sx,sy,sz=poses[f];assert frame==f+1
  if sz<1e-6:continue
  points=[(vertices[i][0]*sx+x,vertices[i][1]*sy+y,vertices[i][2]*sz+z)for i,w in bone]
  assert all(-10.00001<=p[2]<=10.00001 for p in points),'treads cannot cross tile edge'
  shape.extend(tuple(round(v,4)for v in p)for p in points)
 shapes.append(sorted(shape))
assert shapes[0]==shapes[-1],'loop endpoints must have identical geometry'
assert keys[5][12][3]>keys[5][0][3],'motion follows local +Z arrow'
lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
lua.execute("""
local api=dofile(modpath..'/runtime.lua')(core,{});callbacks.on_mods_loaded();flush();local a=newplayer('Alpha');flush()
local L=dofile(modpath..'/levels.lua');local d=L.blank(10)
for z=1,10 do for x=1,10 do d.board[x..','..z]={kind='belt',dir=(x+z)%4,speed=x%2+1}end end
d.walls={};d.lasers={};d.pushers={};d.overhead={};d.spawners={};d.crates={};d.enemies={};api.edit_level(d,false)
local treads={};local tilecount=0
for _,o in ipairs(objects)do if o.p then
 if o.e.client_tread then treads[#treads+1]=o;assert(o.animation.loop and o.animation.range.y==24)end
 if o.props.mesh=='sc_slat.obj'then error('individual moving slat entity remains')end
 if o.p.x>=2.5 and o.p.x<=20.5 and o.p.z>=2.5 and o.p.z<=20.5 then tilecount=tilecount+1 end
end end
assert(#treads==100 and tilecount==400,'100 straight tiles use 400 entities, previously 1300')
tick(.1)
for _,o in ipairs(treads)do
 local expected=24*10/.85*o.e.speed*.5;assert(math.abs(o.animation.speed-expected)<.001,'normal/double inspection animation rate')
 o.sent=0;local props=o.set_properties;o.set_properties=function(self,v)self.sent=self.sent+1;props(self,v)end
 local move=o.set_pos;o.set_pos=function(self,v)self.sent=self.sent+1;move(self,v)end
 o.start_updates=o.animation_updates
end
for i=1,100 do tick(.05)end
for _,o in ipairs(treads)do assert(o.sent==0 and o.animation_updates==o.start_updates,'steady conveyor animation sends no entity updates')end
-- Verify phase transitions update speed, rather than continuously restarting animation.
api.edit_level(d,true)
for i=1,5 do api.queue('Alpha',i)end;api.commit('Alpha');tick(.01)
for _,o in ipairs(objects)do if o.p and o.e.client_tread then assert(o.animation.speed==0,'treads pause outside conveyor phase')end end
local seen={}
for i=1,600 do
 local before=api.phase();tick(.03);local phase=api.phase()
 if before==phase and (phase=='express'or phase=='belts')then
  for _,o in ipairs(objects)do if o.p and o.e.client_tread then
   local expected=(phase=='belts'or o.e.speed==2)and 24*10/.85*o.e.speed or 0
   assert(math.abs(o.animation.speed-expected)<.001,'phase and speed agree')
  end end
  seen[phase]=true
 end
 if seen.express and seen.belts then break end
end
assert(seen.express and seen.belts,'normal and double movement phases covered')
print('PASS 100-conveyor entity budget: 1300 -> 400; zero steady tread updates; native looping animation and half-speed/double-speed rates')
""")
print('PASS B3D structure, full skin weights, triangle references, exact loop, forward travel and clipped tile edges')
