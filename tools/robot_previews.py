"""Rasterize actual textured robot geometry into portable rotating menu previews."""
from pathlib import Path
import math,re
import numpy as np
from PIL import Image
root=Path(__file__).resolve().parents[1];models=root/'mods/shift_circuit/models';tex=root/'mods/shift_circuit/textures'
ids=re.findall(r"id=['\"]([^'\"]+)", (root/'mods/shift_circuit/robot_styles.lua').read_text())
W=128;frames=24
for name in ids:
 verts=[];uv=[];norm=[];faces=[]
 for line in (models/('sc_'+name+'.obj')).read_text().splitlines():
  a=line.split()
  if not a:continue
  if a[0]=='v':verts.append([float(x)/10 for x in a[1:]])
  elif a[0]=='vt':uv.append(list(map(float,a[1:])))
  elif a[0]=='vn':norm.append(list(map(float,a[1:])))
  elif a[0]=='f':faces.append([[int(x)-1 for x in t.split('/')]for t in a[1:]])
 v=np.array(verts);uv=np.array(uv);faces=np.array(faces);center=(v.max(axis=0)+v.min(axis=0))/2;v-=center
 triangles=v[faces[:,:,0]];tuv=uv[faces[:,:,1]];normals=np.array(norm)[faces[:,0,2]]
 texture=np.array(Image.open(tex/('sc_surface_'+name+'.png')).convert('RGBA'));sheet=Image.new('RGBA',(W,W*frames))
 for frame in range(frames):
  yaw=frame*2*math.pi/frames+.55;right=np.array([math.cos(yaw),0,-math.sin(yaw)]);depth=np.array([math.sin(yaw)*.94,.342,math.cos(yaw)*.94]);up=np.cross(depth,right)
  pos=np.stack([triangles@right*60+64,64-triangles@up*60,triangles@depth],axis=2)
  canvas=np.zeros((W,W,4),dtype=np.uint8);zbuf=np.full((W,W),-np.inf)
  for i,t in enumerate(pos):
   if normals[i]@depth<=0:continue
   lo=np.maximum(0,np.floor(t[:,:2].min(axis=0)).astype(int));hi=np.minimum(W-1,np.ceil(t[:,:2].max(axis=0)).astype(int))
   if (hi<lo).any():continue
   X,Y=np.meshgrid(np.arange(lo[0],hi[0]+1)+.5,np.arange(lo[1],hi[1]+1)+.5)
   a,b,c=t;den=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1])
   if abs(den)<1e-8:continue
   w0=((b[1]-c[1])*(X-c[0])+(c[0]-b[0])*(Y-c[1]))/den;w1=((c[1]-a[1])*(X-c[0])+(a[0]-c[0])*(Y-c[1]))/den;w2=1-w0-w1
   z=w0*a[2]+w1*b[2]+w2*c[2];region=zbuf[lo[1]:hi[1]+1,lo[0]:hi[0]+1];mask=(w0>=-1e-6)&(w1>=-1e-6)&(w2>=-1e-6)&(z>region)
   if not mask.any():continue
   u=w0*tuv[i,0,0]+w1*tuv[i,1,0]+w2*tuv[i,2,0];vv=w0*tuv[i,0,1]+w1*tuv[i,1,1]+w2*tuv[i,2,1]
   pixels=texture[np.clip(((1-vv)*texture.shape[0]).astype(int),0,texture.shape[0]-1),np.clip((u*texture.shape[1]).astype(int),0,texture.shape[1]-1)].copy()
   light=.68+.32*max(0,normals[i]@np.array([-.3,.8,.52]));pixels[:,:,:3]=(pixels[:,:,:3]*light).astype(np.uint8)
   dst=canvas[lo[1]:hi[1]+1,lo[0]:hi[0]+1];dst[mask]=pixels[mask];region[mask]=z[mask]
  sheet.paste(Image.fromarray(canvas),(0,frame*W))
 sheet.save(tex/('sc_preview_'+name+'.png'))
 print(name,flush=True)
