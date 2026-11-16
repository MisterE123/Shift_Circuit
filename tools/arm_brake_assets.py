"""Editable overhead manipulator and brake meshes. Preserve user-painted atlases."""
from pathlib import Path
import ast,math,shutil
from PIL import Image,ImageDraw
R=Path(__file__).resolve().parents[1];M=R/'mods/shift_circuit/models';T=R/'mods/shift_circuit/textures'
s=(R/'tools/refine_assets.py').read_text();tree=ast.parse(s);fn=next(n for n in tree.body if isinstance(n,ast.FunctionDef)and n.name=='mesh');exec(compile(ast.Module(body=[fn],type_ignores=[]),str(R/'tools/refine_assets.py'),'exec'))
models={
 'mount_mechanical_arm':[(-.24,0,-.22,.24,.08,.22,1),(-.13,.08,-.13,.13,.2,.13,3),(-.2,.19,-.16,.2,.27,.16,2),(-.08,.23,-.18,.08,.28,-.16,4)],
 'arm_link':[(-.075,-.075,0,.075,.075,1,1),(-.045,.076,.16,.045,.1,.84,2),(-.12,-.1,0,.12,.1,.12,3),(-.12,-.1,.88,.12,.1,1,3)],
 'arm_claw':[(-.24,-.07,-.12,.24,.07,.12,1),(-.08,.07,-.08,.08,.15,.08,3),(-.12,-.08,.12,.12,.03,.15,4)],
 'arm_finger':[(-.04,-.23,-.035,.04,-.04,.035,2),(-.055,-.26,-.055,.055,-.21,.055,0)],
 'mount_electromagnetic_brake':[(-.55,0,-.16,.55,.1,.16,1),(-.55,-.14,-.16,-.36,0,.16,2),(.36,-.14,-.16,.55,0,.16,2),(-.32,.1,-.12,.32,.17,.12,3),(-.22,.17,-.1,.22,.19,.1,4)],
 'pickup_electromagnetic_brake':[(-.35,-.3,-.13,-.16,.3,.13,2),(.16,-.3,-.13,.35,.3,.13,2),(-.16,.1,-.13,.16,.3,.13,3),(-.35,-.36,-.13,-.16,-.25,.13,4),(.16,-.36,-.13,.35,-.25,.13,4)]}
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
im=Image.new('RGBA',(32,32),(0,0,0,0));d=ImageDraw.Draw(im);d.rectangle((5,4,11,25),fill='#a2c1c9');d.rectangle((21,4,27,25),fill='#a2c1c9');d.rectangle((11,4,21,11),fill='#e6b95c');d.rectangle((5,23,11,28),fill='#47cfbd');d.rectangle((21,23,27,28),fill='#47cfbd');d.line((13,19,19,19),fill='#47cfbd',width=2)
(R/'art/ui').mkdir(exist_ok=True);im.save(R/'art/ui/sc_part_electromagnetic_brake.png');im.resize((64,64),Image.Resampling.NEAREST).save(T/'sc_part_electromagnetic_brake.png')
print('Generated articulated overhead arm, fingers, visible brake and editable icon')
