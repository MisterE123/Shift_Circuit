"""Editable pixel atlases and union meshes for map puzzle objects."""
from pathlib import Path
from PIL import Image,ImageDraw
import math
root=Path(__file__).resolve().parents[1];M=root/'mods/shift_circuit/models';T=root/'mods/shift_circuit/textures'
s=(root/'tools/refine_assets.py').read_text();ns={'M':M};exec(s[s.index('def mesh('):s.index('robot=[')],ns)
boxes={
'crate_loot':[(-.65,-.5,-.65,.65,.65,.65,3),(-.7,-.45,-.7,-.5,.7,.7,1),(.5,-.45,-.7,.7,.7,.7,1),(-.5,.5,-.7,.5,.7,.7,1),(-.18,-.1,.65,.18,.25,.73,4)],
'crate_steel':[(-.68,-.5,-.68,.68,.7,.68,1),(-.73,-.3,-.73,-.48,.5,.73,2),(.48,-.3,-.73,.73,.5,.73,2),(-.48,.5,-.73,.48,.73,.73,2)],
'plate':[(-.8,-.48,-.8,.8,-.37,.8,1),(-.65,-.37,-.65,.65,-.29,.65,3),(-.35,-.29,-.35,.35,-.27,.35,4)],
'trapdoor':[(-.97,-.5,-.97,.97,-.38,.97,1),(-.82,-.38,-.82,-.08,-.34,.82,3),(.08,-.38,-.82,.82,-.34,.82,3)],
'mount_battering_ram':[(-.6,-.14,-.12,.6,.14,.12,2),(-.45,-.09,.12,-.25,.09,.25,3),(.25,-.09,.12,.45,.09,.25,3)],
'pickup_battering_ram':[(-.35,-.1,-.12,.35,.1,.12,2),(-.3,-.06,.12,-.15,.06,.23,3),(.15,-.06,.12,.3,.06,.23,3)],
'enemy_sentry':[(-.55,-.5,-.55,.55,-.28,.55,1),(-.22,-.28,-.22,.22,.45,.22,2),(-.4,.25,-.3,.4,.8,.35,7),(-.18,.4,.35,.18,.57,.72,0)],
'enemy_patroller':[(-.6,-.5,-.5,-.3,-.1,.5,0),(.3,-.5,-.5,.6,-.1,.5,0),(-.35,-.25,-.35,.35,.55,.35,7),(-.3,.25,.35,.3,.4,.42,4)],
'enemy_ram_bot':[(-.6,-.5,-.55,-.3,-.1,.55,0),(.3,-.5,-.55,.6,-.1,.55,0),(-.4,-.3,-.4,.4,.55,.4,7),(-.7,-.3,.4,.7,.15,.68,2),(-.2,.3,.4,.2,.48,.46,3)]}
for name,b in boxes.items():
 ns['mesh']('sc_'+name+'.obj',b)
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
for name in boxes:
 if '["'+name+'"]'not in s:s=s.replace('return {','return {\n ["'+name+'"]="sc_surface_'+name+'.png",')
f.write_text(s)
for i,name in enumerate(['loot','steel','plate','closed','open','sentry','patroller','ram'],23):
 f=T/f'sc_editor_{i}.png'
 if f.exists():continue
 im=Image.new('RGBA',(32,32),'#142630');d=ImageDraw.Draw(im);d.rectangle((2,2,29,29),outline='#7095a0',width=2)
 if i in (23,24):
  d.rectangle((7,7,24,25),fill='#dfb75f'if i==23 else '#8eabb8');d.line((11,7,11,25),fill='#344c5a',width=3);d.line((21,7,21,25),fill='#344c5a',width=3)
 elif i<28:
  d.rectangle((6,10,25,24),fill='#dfb75f');d.rectangle((9,12,22,22),fill='#12202c'if i==27 else '#62ccb8');d.line((16,12,16,22),fill='#344c5a',width=2)
 else:
  d.rectangle((8,10,23,23),fill='#b75843');d.rectangle((5,19,8,26),fill='#8eabb8');d.rectangle((23,19,26,26),fill='#8eabb8');d.rectangle((11,13,20,15),fill='#62ccb8')
 im.save(f)
