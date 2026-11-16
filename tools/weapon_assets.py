"""Editable overhead manipulator and brake meshes. Preserve user-painted atlases."""
from pathlib import Path
import ast,math,shutil
from PIL import Image,ImageDraw
R=Path(__file__).resolve().parents[1];M=R/'mods/shift_circuit/models';T=R/'mods/shift_circuit/textures'
s=(R/'tools/refine_assets.py').read_text();tree=ast.parse(s);fn=next(n for n in tree.body if isinstance(n,ast.FunctionDef)and n.name=='mesh');exec(compile(ast.Module(body=[fn],type_ignores=[]),str(R/'tools/refine_assets.py'),'exec'))
models={}
triple=[(-.53,0,-.3,.53,.2,.15,1),(-.42,.2,-.2,.42,.27,.1,3)]
for x in [-.375,0,.375]:
 triple += [(x-.105,.05,.1,x+.105,.19,.48,0),(x-.07,.08,.48,x+.07,.16,.53,4)]
emp=[(-.36,0,-.3,.36,.22,.2,1),(-.28,.22,-.22,.28,.3,.05,3),(-.25,.04,.2,.25,.2,.4,0)]
for z in [.22,.34,.46]:emp += [(-.3,.02,z,.3,.05,z+.025,2),(-.3,.19,z,.3,.22,z+.025,2),(-.3,.05,z,-.27,.19,z+.025,2),(.27,.05,z,.3,.19,z+.025,2)]
emp += [(-.07,.08,.4,.07,.16,.53,4)]
for kind,boxes in [('triple_laser',triple),('emp_generator',emp)]:
 models['mount_'+kind]=boxes
 models['pickup_'+kind]=[(a,b-.15,c-.1,d,e-.15,f-.1,col)for a,b,c,d,e,f,col in boxes]
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

for kind in ['triple_laser','emp_generator']:
 im=Image.new('RGBA',(32,32),(0,0,0,0));d=ImageDraw.Draw(im)
 d.rectangle((3,19,28,28),fill='#405768');d.rectangle((6,24,25,27),fill='#e6b95c')
 if kind=='triple_laser':
  for x in [7,16,25]:d.rectangle((x-2,3,x+2,20),fill='#47cfbd');d.rectangle((x-3,16,x+3,22),fill='#a2c1c9')
 else:
  for y in [5,11,17]:d.rectangle((5,y,26,y+3),outline='#72aaff',width=2)
  d.line((16,2,12,10,19,10,15,21),fill='#eaf6ff',width=2)
 im.save(R/('art/ui/sc_part_'+kind+'.png'));im.resize((64,64),Image.Resampling.NEAREST).save(T/('sc_part_'+kind+'.png'))
print('Generated Triple Laser and EMP editable meshes and icons')
