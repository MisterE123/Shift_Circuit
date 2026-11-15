"""Original selectable robot chassis. Existing per-model texture edits are preserved."""
from pathlib import Path
from PIL import Image,ImageDraw
import math
root=Path(__file__).resolve().parents[1];M=root/'mods/shift_circuit/models';T=root/'mods/shift_circuit/textures'
s=(root/'tools/refine_assets.py').read_text();ns={'M':M};exec(s[s.index('def mesh('):s.index('robot=[')],ns)
def box(x,y,z,X,Y,Z,c):return (x,y,z,X,Y,Z,c)
def tracks(width=.5):
 a=[]
 for sign in (-1,1):
  x=sign*(width-.12);a.append(box(x-.12,-.5,-.42,x+.12,-.13,.42,0))
  for z in (-.32,-.12,.08,.28):a.append(box(x-.125,-.43,z,x+.125,-.24,z+.07,1))
 return a
def legs(wide=False):
 a=[]
 for x in (-.28,.28):
  a += [box(x-.16,-.5,-.18,x+.16,-.35,.36,1),box(x-.065,-.35,-.06,x+.065,-.04,.11,2)]
 return a
def wheels():
 a=[]
 for x in (-.4,.4):
  for z in (-.29,.29):a += [box(x-.14,-.46,z-.13,x+.14,-.18,z+.13,0),box(x-.15,-.4,z-.07,x+.15,-.24,z+.07,2)]
 return a
def eyes(width=.23,y=.59):return [box(-width,y-.09,.251,width,y+.09,.29,5),box(-width+.04,y-.025,.29,width-.04,y+.025,.31,4)]
models={
'rivet':('Rivet','Rugged walker with riveted shoulder plates.',legs()+[box(-.32,-.08,-.25,.32,.35,.25,3),box(-.28,.35,-.23,.28,.81,.25,1),box(-.58,.08,-.15,-.32,.38,.15,2),box(.32,.08,-.15,.58,.38,.15,2)]+eyes()),
'surveyor':('Surveyor','Wide optical bar on four compact wheels.',wheels()+[box(-.32,-.17,-.28,.32,.25,.28,1),box(-.1,.25,-.08,.1,.48,.08,2),box(-.48,.48,-.16,.48,.81,.25,3),box(-.44,.55,.25,-.06,.73,.29,5),box(.06,.55,.25,.44,.73,.29,5),box(-.38,.6,.29,-.12,.67,.31,4),box(.12,.6,.29,.38,.67,.31,4)]),
'mantis':('Mantis','Long-legged chassis with folded side arms.',legs()+[box(-.2,.02,-.18,.2,.43,.18,4),box(-.3,.43,-.2,.3,.81,.25,1),box(-.53,.25,-.08,-.3,.34,.12,2),box(-.53,-.05,.04,-.45,.34,.18,3),box(.3,.25,-.08,.53,.34,.12,2),box(.45,-.05,.04,.53,.34,.18,3)]+eyes(.24,.63)),
'dynamo':('Dynamo','Tracked generator with stacked cooling fins.',tracks(.57)+[box(-.34,-.18,-.33,.34,.55,.3,3),box(-.21,.55,-.19,.21,.81,.25,2)]+[box(-.4,y,-.36,.4,y+.05,.34,1)for y in (-.08,.08,.24,.4)]+eyes(.15,.68)),
'porter':('Porter','Small wheeled cab with a tall cargo pack.',wheels()+[box(-.3,-.17,-.24,.3,.33,.27,3),box(-.38,.05,-.44,.38,.75,-.26,1),box(-.24,.33,-.13,.24,.81,.25,2),box(-.47,.05,-.1,-.3,.3,.23,1),box(.3,.05,-.1,.47,.3,.23,1)]+eyes(.18,.62)),
'beacon':('Beacon','Light tower with a single broad track base.',[box(-.48,-.5,-.36,.48,-.15,.36,0),box(-.32,-.15,-.26,.32,.14,.26,1),box(-.17,.14,-.17,.17,.63,.17,3),box(-.33,.63,-.25,.33,.81,.25,4),box(-.38,.55,-.28,.38,.63,.28,2),box(-.11,.2,.17,.11,.48,.2,5)]),
'crate':('Crate','Boxy utility robot with reinforced corners.',tracks(.58)+[box(-.42,-.2,-.34,.42,.68,.3,3),box(-.26,.68,-.2,.26,.81,.2,1),box(-.44,-.1,-.35,-.34,.7,.32,2),box(.34,-.1,-.35,.44,.7,.32,2),box(-.26,.43,.3,.26,.59,.34,5),box(-.17,.48,.34,.17,.53,.35,4),box(-.22,.03,.3,.22,.23,.34,1)]),
'skitter':('Skitter','Four splayed feet around a squat sensor body.',[box(-.34,-.06,-.28,.34,.41,.28,4),box(-.28,.41,-.2,.28,.81,.25,1)]+[box(x-.09,-.5,z-.12,x+.09,-.35,z+.12,1)for x in (-.5,.5)for z in (-.36,.36)]+[box(min(x,0),-.35,z-.055,max(x,0),-.07,z+.055,2)for x in (-.5,.5)for z in (-.3,.3)]+eyes()),
'sentry':('Sentry','Armored walker with a narrow central eye.',legs()+[box(-.4,-.07,-.3,.4,.4,.3,1),box(-.34,.4,-.25,.34,.81,.25,2),box(-.49,.16,-.23,-.4,.46,.23,3),box(.4,.16,-.23,.49,.46,.23,3),box(-.09,.49,.25,.09,.72,.29,5),box(-.04,.55,.29,.04,.66,.31,7)]),
'spindle':('Spindle','Tall narrow frame over twin broad wheels.',[box(-.53,-.5,-.28,-.28,-.04,.28,0),box(.28,-.5,-.28,.53,-.04,.28,0),box(-.2,-.21,-.18,.2,.47,.18,2),box(-.33,.47,-.21,.33,.81,.25,3),box(-.26,.04,-.22,.26,.17,.22,1)]+eyes(.26,.63)),
'beetle':('Beetle','Low tracked shell with bright paired eyes.',tracks(.61)+[box(-.44,-.15,-.37,.44,.31,.32,4),box(-.34,.31,-.3,.34,.62,.28,4),box(-.24,.62,-.2,.24,.81,.2,1),box(-.3,.35,.28,-.08,.52,.32,5),box(.08,.35,.28,.3,.52,.32,5),box(-.24,.4,.32,-.13,.46,.34,3),box(.13,.4,.32,.24,.46,.34,3)]),
'relay':('Relay','Communications walker with side antenna fins.',legs()+[box(-.25,-.07,-.22,.25,.37,.25,1),box(-.32,.37,-.23,.32,.81,.25,3),box(-.45,.38,-.12,-.38,.94,.04,2),box(.38,.38,-.12,.45,.94,.04,2),box(-.49,.86,-.15,-.34,.94,.08,4),box(.34,.86,-.15,.49,.94,.08,4)]+eyes(.25,.59))}
palettes=['#de956b','#83b6df','#92c58e','#e2b651','#91a7c8','#75cbbc','#caa080','#b098d0','#c5ccd7','#e1a1b5','#76baa3','#97b6e5']
for index,(key,(title,description,boxes)) in enumerate(models.items()):
 boxes=[tuple(round(v,6)for v in b)for b in boxes]
 name='robot_'+key;ns['mesh']('sc_'+name+'.obj',boxes);tex=T/('sc_surface_'+name+'.png')
 if not tex.exists():
  im=Image.open(T/'sc_materials.png').convert('RGB');d=ImageDraw.Draw(im)
  for material in (3,4):
   color=palettes[index];d.rectangle((material*16,0,material*16+15,15),fill=color);d.line((material*16+2,13,material*16+13,13),fill='#405768')
  im.save(tex)
 obj=M/('sc_'+name+'.obj');verts=[];lines=[];normal=0
 for line in obj.read_text().splitlines():
  if line.startswith('v '):verts.append(tuple(map(float,line.split()[1:])))
  if line.startswith('f '):
   a,b,c=[verts[int(t.split('/')[0])-1]for t in line.split()[1:]];u=[b[i]-a[i]for i in range(3)];v=[c[i]-a[i]for i in range(3)];n=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]];length=math.sqrt(sum(x*x for x in n));normal+=1;lines.append('vn '+' '.join(str(x/length)for x in n));line='f '+' '.join(t+'/'+str(normal)for t in line.split()[1:])
  lines.append(line)
 obj.write_text('mtllib '+obj.stem+'.mtl\nusemtl editable\n'+'\n'.join(lines)+'\n');obj.with_suffix('.mtl').write_text('newmtl editable\nKd 1 1 1\nmap_Kd ../textures/'+tex.name+'\n')
f=root/'mods/shift_circuit/asset_textures.lua';s=f.read_text();s=s.replace('return {','return {\n'+''.join(' ["robot_'+k+'"]="sc_surface_robot_'+k+'.png",\n'for k in models if ('["robot_'+k+'"]')not in s));f.write_text(s)
print('Built 12 distinct chassis with editable textures, UVs and face normals.')
