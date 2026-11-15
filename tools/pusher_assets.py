"""Rebuild only the low-profile pusher and its telescoping rod."""
from pathlib import Path
from PIL import Image
import math
root=Path(__file__).resolve().parents[1];M=root/'mods/shift_circuit/models';T=root/'mods/shift_circuit/textures'
s=(root/'tools/refine_assets.py').read_text();ns={'M':M};exec(s[s.index('def mesh('):s.index('robot=[')],ns)
for line in s.splitlines():
 if line.startswith(("mesh('sc_pusher.obj'","mesh('sc_pushram.obj'","mesh('sc_pushrod.obj'")):exec(line,ns)
for name in ['pusher','pushram','pushrod']:
 tex=T/('sc_surface_'+name+'.png')
 if not tex.exists():Image.open(T/'sc_materials.png').save(tex)
 obj=M/('sc_'+name+'.obj');verts=[];lines=[];normal=0
 for line in obj.read_text().splitlines():
  if line.startswith('v '):verts.append(tuple(map(float,line.split()[1:])))
  if line.startswith('f '):
   a,b,c=[verts[int(t.split('/')[0])-1]for t in line.split()[1:]];u=[b[i]-a[i]for i in range(3)];v=[c[i]-a[i]for i in range(3)];n=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]];length=math.sqrt(sum(x*x for x in n));normal+=1;lines.append('vn '+' '.join(str(x/length)for x in n));line='f '+' '.join(t+'/'+str(normal)for t in line.split()[1:])
  lines.append(line)
 obj.write_text('mtllib '+obj.stem+'.mtl\nusemtl editable\n'+'\n'.join(lines)+'\n');obj.with_suffix('.mtl').write_text('newmtl editable\nKd 1 1 1\nmap_Kd ../textures/'+tex.name+'\n')
f=root/'mods/shift_circuit/asset_textures.lua';s=f.read_text()
if '["pushrod"]'not in s:s=s.replace('return {','return {\n ["pushrod"]="sc_surface_pushrod.png",')
f.write_text(s)
