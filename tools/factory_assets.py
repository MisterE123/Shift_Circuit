"""Original factory blocks, dark output mouths, editable atlases and map icons."""
from pathlib import Path
from PIL import Image,ImageDraw
import math
root=Path(__file__).resolve().parents[1];M=root/'mods/shift_circuit/models';T=root/'mods/shift_circuit/textures'
source=(root/'tools/refine_assets.py').read_text();ns={'M':M};exec(source[source.index('def mesh('):source.index('robot=[')],ns)
patterns={'one':[0],'opposite':[0,2],'corner':[0,1],'three':[0,1,3],'four':[0,1,2,3]}
def write(name,boxes):
 ns['mesh']('sc_'+name+'.obj',boxes);p=M/('sc_'+name+'.obj');verts=[];lines=[];normal=0
 for line in p.read_text().splitlines():
  if line.startswith('v '):verts.append(tuple(map(float,line.split()[1:])))
  if line.startswith('f '):
   a,b,c=[verts[int(v.split('/')[0])-1]for v in line.split()[1:]];u=[b[i]-a[i]for i in range(3)];v=[c[i]-a[i]for i in range(3)];n=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]];length=math.sqrt(sum(a*a for a in n));normal+=1;lines.append('vn '+' '.join(str(a/length)for a in n));line='f '+' '.join(v+'/'+str(normal)for v in line.split()[1:])
  lines.append(line)
 p.write_text('mtllib '+p.stem+'.mtl\nusemtl editable\n'+'\n'.join(lines)+'\n');p.with_suffix('.mtl').write_text('newmtl editable\nKd 1 1 1\nmap_Kd ../textures/sc_surface_factory_loot.png\n')
for pattern,openings in patterns.items():
 boxes=[(-.92,-.5,-.92,.92,-.42,.92,1),(-.92,.85,-.92,.92,1.05,.92,1),(-.56,-.4,-.56,.56,.84,.56,5),(-.5,1.05,-.5,.5,1.1,.5,3)]
 for x in [-.92,.76]:
  for z in [-.92,.76]:boxes.append((x,-.42,z,x+.16,.85,z+.16,2))
 for direction in range(4):
  if direction in openings:continue
  if direction==0:boxes.append((-.76,-.42,.76,.76,.85,.92,1))
  if direction==1:boxes.append((.76,-.42,-.76,.92,.85,.76,1))
  if direction==2:boxes.append((-.76,-.42,-.92,.76,.85,-.76,1))
  if direction==3:boxes.append((-.92,-.42,-.76,-.76,.85,.76,1))
 write('factory_'+pattern,boxes)
write('factory_lamp',[(-.13,-.045,-.06,.13,.045,.06,4)])
for kind,color in [('loot','#e8bd60'),('steel','#b6c9d3')]:
 im=Image.open(T/'sc_materials.png').convert('RGB');d=ImageDraw.Draw(im);d.rectangle((48,0,63,15),fill=color);d.rectangle((80,0,95,15),fill='#03080c');d.line((81,14,94,14),fill='#0b141b');im.save(T/('sc_surface_factory_'+kind+'.png'))
for index,(pattern,outlets)in enumerate(patterns.items(),32):
 im=Image.new('RGBA',(32,32),'#142630');d=ImageDraw.Draw(im);d.rectangle((2,2,29,29),outline='#7095a0',width=2);d.rectangle((7,7,24,24),fill='#809ca7');d.rectangle((11,11,20,20),fill='#e8bd60')
 for direction in outlets:
  box=[(12,22,19,26),(22,12,26,19),(12,5,19,9),(5,12,9,19)][direction];d.rectangle(box,fill='#03080c')
 im.save(T/f'sc_editor_{index}.png')
 for direction in range(4):
  small=Image.new('RGBA',(8,8),'#142630');q=ImageDraw.Draw(small);q.rectangle((1,1,6,6),fill='#809ca7');q.rectangle((3,3,4,4),fill='#e8bd60')
  for offset in outlets:q.rectangle([(3,6,4,7),(6,3,7,4),(3,0,4,1),(0,3,1,4)][(direction+offset)%4],fill='#03080c')
  small.save(T/f'sc_map_factory_{pattern}_{direction}.png')
p=root/'mods/shift_circuit/asset_textures.lua';s=p.read_text()
for name in ['factory_'+k for k in patterns]+['factory_lamp']:
 if '["'+name+'"]'not in s:s=s.replace('return {','return {\n ["'+name+'"]="sc_surface_factory_loot.png",')
p.write_text(s,newline="\n")
