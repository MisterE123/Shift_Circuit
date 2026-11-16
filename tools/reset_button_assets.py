"""Editable overhead manipulator and brake meshes. Preserve user-painted atlases."""
from pathlib import Path
import ast,math,shutil
from PIL import Image,ImageDraw
R=Path(__file__).resolve().parents[1];M=R/'mods/shift_circuit/models';T=R/'mods/shift_circuit/textures'
s=(R/'tools/refine_assets.py').read_text();tree=ast.parse(s);fn=next(n for n in tree.body if isinstance(n,ast.FunctionDef)and n.name=='mesh');exec(compile(ast.Module(body=[fn],type_ignores=[]),str(R/'tools/refine_assets.py'),'exec'))
models={'pickup_reset_button':[(-.35,-.25,-.35,.35,-.1,.35,0),(-.3,-.1,-.3,.3,.05,.3,2),(-.24,.05,-.24,.24,.24,.24,7),(-.12,.24,-.12,.12,.26,.12,6)]}
for name,boxes in models.items():
 mesh('sc_'+name+'.obj',boxes);p=M/('sc_'+name+'.obj');verts=[];lines=[];normal=0
 for line in p.read_text().splitlines():
  if line.startswith('v '):verts.append(tuple(map(float,line.split()[1:])))
  if line.startswith('f '):
   ids=[int(t.split('/')[0])-1 for t in line.split()[1:]];a,b,c=[verts[i]for i in ids[:3]];u=[b[i]-a[i]for i in range(3)];v=[c[i]-a[i]for i in range(3)];n=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]];length=math.sqrt(sum(x*x for x in n));normal+=1;lines.append('vn '+' '.join(str(x/length)for x in n));line='f '+' '.join(t+'/'+str(normal)for t in line.split()[1:])
  lines.append(line)
 p.write_text('mtllib '+p.stem+'.mtl\nusemtl editable\n'+'\n'.join(lines)+'\n',newline='\n')
 tex='sc_surface_'+name+'.png'
 if not (T/tex).exists():shutil.copyfile(T/'sc_materials.png',T/tex)
 p.with_suffix('.mtl').write_text('newmtl editable\nKd 1 1 1\nmap_Kd ../textures/'+tex+'\n',newline='\n')
p=R/'mods/shift_circuit/asset_textures.lua';s=p.read_text()
for name in models:
 if '["'+name+'"]' not in s:s=s.replace('return {','return {\n ["'+name+'"]="sc_surface_'+name+'.png",')
p.write_text(s,newline='\n')
im=Image.new('RGBA',(32,32),(0,0,0,0));d=ImageDraw.Draw(im)
d.rectangle((3,15,28,28),fill='#405768');d.rectangle((5,13,26,24),fill='#a2c1c9');d.rectangle((8,6,23,19),fill='#b75843');d.line((11,9,20,9,20,15,13,15),fill='#ecf8ed',width=2);d.polygon([(10,15),(14,12),(14,18)],fill='#ecf8ed')
im.save(R/'art/ui/sc_part_reset_button.png');im.resize((64,64),Image.Resampling.NEAREST).save(T/'sc_part_reset_button.png')
