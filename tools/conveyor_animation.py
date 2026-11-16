"""Bake a single skinned conveyor tread. Reuses the editable conveyor atlas.
No Blender dependency: B3D has 12 rigid slat bones with position/scale keys.
End slats clip to the tile boundary; a one-pitch loop has identical endpoints.
"""
from pathlib import Path
import math, struct
ROOT=Path(__file__).resolve().parents[1]
MODELS=ROOT/'mods/shift_circuit/models'
def pack(fmt,*values): return struct.pack('<'+fmt,*values)
def chunk(tag,data): return tag.encode()+pack('i',len(data))+data
def string(s): return s.encode()+b'\0'
def node(name,body): return chunk('NODE',string(name)+pack('10f',0,0,0,1,1,1,1,0,0,0)+body)
# Convert OBJ coordinates/UVs to the engine's B3D convention; preserve its shading.
positions=[];uv=[];normals=[];vertices=[];triangles=[]
for line in (MODELS/'sc_slat.obj').read_text().splitlines():
 bits=line.split()
 if not bits:continue
 if bits[0]=='v':positions.append(tuple(map(float,bits[1:])))
 elif bits[0]=='vt':uv.append(tuple(map(float,bits[1:])))
 elif bits[0]=='vn':normals.append(tuple(map(float,bits[1:])))
 elif bits[0]=='f':
  tri=[]
  for ref in bits[1:]:
   vi,ti,ni=map(int,ref.split('/'));x,y,z=positions[vi-1];nx,ny,nz=normals[ni-1];u,v=uv[ti-1]
   tri.append(len(vertices));vertices.append((-x,y,z,-nx,ny,nz,u,1-v))
  triangles.append(tuple(tri))
count=len(vertices);all_vertices=[];all_triangles=[];bones=[]
for row in range(12):
 offset=len(all_vertices);all_vertices.extend(vertices);all_triangles.extend(tuple(offset+i for i in t)for t in triangles)
 keys=pack('i',3)
 for frame in range(25):
  center=-12+row*2+frame/24*2
  low=max(-10,min(10,center-.6));high=max(-10,min(10,center+.6))
  keys+=pack('i6f',frame+1,0,0,(low+high)/2,1,1,max(0,(high-low)/1.2))
 weights=b''.join(pack('if',offset+i,1)for i in range(count))
 bones.append(node('slat_'+str(row),chunk('BONE',weights)+chunk('KEYS',keys)))
verts=chunk('VRTS',pack('3i',1,1,2)+b''.join(pack('8f',*v)for v in all_vertices))
tris=chunk('TRIS',pack('i',0)+b''.join(pack('3i',*t)for t in all_triangles))
mesh=chunk('MESH',pack('i',0)+verts+tris)
tex=chunk('TEXS',string('sc_surface_conveyor.png')+pack('2i5f',1,2,0,0,1,1,0))
brush=chunk('BRUS',pack('i',1)+string('editable conveyor')+pack('5f3i',1,1,1,1,0,1,0,0))
anim=chunk('ANIM',pack('2if',0,25,24))
(MODELS/'sc_tread_straight.b3d').write_bytes(chunk('BB3D',pack('i',1)+tex+brush+node('tread',mesh+anim+b''.join(bones))))
print('Generated client-animated straight tread:',len(all_vertices),'vertices, 12 bones, 25 keys per bone')
