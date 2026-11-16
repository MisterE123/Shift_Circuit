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
# Distinct silhouettes, with a shared top mounting deck at y=.81.
# Stable IDs replace earlier near-duplicate bodies without invalidating saved choices.
models={
'rivet':('Rivet','Broad knuckle-walker with oversized industrial fists.',legs()+[box(-.4,-.05,-.25,.4,.65,.25,3),box(-.25,.65,-.2,.25,.81,.2,1),box(-.65,.25,-.2,-.4,.65,.2,2),box(.4,.25,-.2,.65,.65,.2,2),box(-.7,-.4,.05,-.45,.35,.4,1),box(.45,-.4,.05,.7,.35,.4,1)]+eyes(.23,.5)),
'surveyor':('Surveyor','Tripod survey instrument with a wide binocular head.',[box(-.15,-.1,-.1,.15,.55,.1,2),box(-.5,.55,-.2,.5,.81,.25,3),box(-.55,-.5,.2,-.3,-.35,.45,0),box(.3,-.5,.2,.55,-.35,.45,0),box(-.15,-.5,-.5,.15,-.35,-.25,0),box(-.4,-.35,.1,-.15,.1,.25,2),box(.15,-.35,.1,.4,.1,.25,2),box(-.08,-.35,-.35,.08,.1,-.05,2),box(-.45,.6,.25,-.1,.75,.32,5),box(.1,.6,.25,.45,.75,.32,5),box(-.36,.63,.32,-.2,.7,.36,4),box(.2,.63,.32,.36,.7,.36,4)]),
'mantis':('Mantis','Six-legged insect chassis with raised pincer arms.',[box(-.2,-.1,-.4,.2,.3,.35,3),box(-.15,.3,-.15,.15,.81,.15,1),box(-.3,.4,.05,.3,.6,.3,4)]+[box(x-.07,-.5,z-.1,x+.07,-.3,z+.1,0)for x in (-.65,.65)for z in (-.4,0,.4)]+[box(min(x,0),-.3,z-.05,max(x,0),-.1,z+.05,2)for x in (-.65,.65)for z in (-.4,0,.4)]+[box(-.5,.3,.2,-.3,.65,.4,2),box(.3,.3,.2,.5,.65,.4,2),box(-.5,.6,.35,-.35,.8,.6,3),box(.35,.6,.35,.5,.8,.6,3)]),
'dynamo':('Dynamo','Single-wheel reactor with a ribbed barrel body.',[box(-.15,-.5,-.3,.15,-.35,.3,0),box(-.2,-.35,-.4,.2,-.05,.4,0),box(-.15,-.05,-.3,.15,.1,.3,0),box(-.35,.1,-.3,.35,.7,.3,3),box(-.2,.7,-.2,.2,.81,.2,2)]+[box(-.45,y,-.35,.45,y+.06,.35,1)for y in (.12,.3,.48,.66)]+[box(-.12,.32,.35,.12,.5,.4,4)]),
'porter':('Porter','Forklift carrier with forward prongs and a rear counterweight.',wheels()+[box(-.35,-.2,-.35,.35,.2,.25,3),box(-.35,.2,-.35,.35,.81,-.05,1),box(-.15,.55,-.05,.15,.81,.18,2),box(-.3,-.15,.25,-.15,-.05,.75,2),box(.15,-.15,.25,.3,-.05,.75,2),box(-.3,-.05,.23,-.2,.55,.33,3),box(.2,-.05,.23,.3,.55,.33,3),box(-.12,.6,.18,.12,.7,.22,4)]),
'beacon':('Beacon','Tall signal tower on four wide stabilizer feet.',[box(-.15,-.3,-.15,.15,.65,.15,3),box(-.35,.65,-.3,.35,.81,.3,4),box(-.25,.57,-.25,.25,.65,.25,1)]+[box(-.65,-.5,-.12,.65,-.3,.12,0),box(-.12,-.5,-.6,.12,-.3,.6,0)]+[box(-.2,y,-.2,.2,y+.06,.2,2)for y in (-.1,.15,.4)]),
'crate':('Crate','Walking cargo safe: a huge square shell on tiny feet.',legs()+[box(-.5,-.2,-.4,.5,.81,.4,3),box(-.42,-.08,.4,.42,.7,.44,1),box(-.33,.02,.44,.33,.6,.47,2),box(-.08,.15,.47,.08,.37,.52,0),box(-.3,.48,.47,.3,.56,.5,4),box(-.56,.1,-.25,-.5,.5,.25,1),box(.5,.1,-.25,.56,.5,.25,1)]),
'skitter':('Skitter','Wide crab chassis with side claws and four outriggers.',[box(-.4,-.05,-.3,.4,.45,.3,4),box(-.2,.45,-.15,.2,.81,.15,1),box(-.35,.2,.3,.35,.35,.35,5)]+[box(x-.1,-.5,z-.13,x+.1,-.32,z+.13,0)for x in (-.65,.65)for z in (-.4,.4)]+[box(min(x,0),-.32,z-.05,max(x,0),-.05,z+.05,2)for x in (-.65,.65)for z in (-.35,.35)]+[box(-.8,.05,-.1,-.4,.22,.1,3),box(.4,.05,-.1,.8,.22,.1,3),box(-.8,.05,.1,-.7,.3,.3,2),box(.7,.05,.1,.8,.3,.3,2)]),
'sentry':('Bastion','Stepped armored pyramid with broad twin treads.',tracks(.65)+[box(-.5,-.15,-.4,.5,.15,.4,1),box(-.4,.15,-.3,.4,.45,.3,2),box(-.3,.45,-.2,.3,.7,.2,3),box(-.2,.7,-.15,.2,.81,.15,1),box(-.06,.24,.3,.06,.4,.34,7)]),
'spindle':('Spindle','Giant central wheel held in a narrow balancing fork.',[box(-.18,-.5,-.2,.18,-.35,.2,0),box(-.18,-.35,-.4,.18,.1,.4,0),box(-.18,.1,-.2,.18,.25,.2,0),box(-.27,-.15,-.1,-.18,.65,.1,2),box(.18,-.15,-.1,.27,.65,.1,2),box(-.3,.65,-.2,.3,.81,.2,3),box(-.12,.68,.2,.12,.76,.25,4)]),
'beetle':('Beetle','Heavy domed crawler with a broad segmented shell.',tracks(.68)+[box(-.55,-.2,-.45,.55,.2,.45,4),box(-.45,.2,-.35,.45,.5,.35,4),box(-.3,.5,-.25,.3,.7,.25,4),box(-.18,.7,-.15,.18,.81,.15,1),box(-.04,-.1,-.47,.04,.65,-.35,2),box(-.36,.1,.45,-.15,.22,.5,3),box(.15,.1,.45,.36,.22,.5,3)]),
'relay':('Relay','Dish-headed receiver with a broad open antenna frame.',legs()+[box(-.12,-.05,-.1,.12,.5,.1,2),box(-.5,.3,-.1,.5,.4,.05,3),box(-.5,.4,-.1,-.4,.85,.05,3),box(.4,.4,-.1,.5,.85,.05,3),box(-.4,.85,-.1,.4,.95,.05,3),box(-.25,.45,-.13,.25,.75,-.05,1),box(-.07,.48,-.05,.07,.65,.25,4),box(-.15,.65,-.25,.15,.81,-.1,2)])}

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
 obj.write_text('mtllib '+obj.stem+'.mtl\nusemtl editable\n'+'\n'.join(lines)+'\n',newline='\n');obj.with_suffix('.mtl').write_text('newmtl editable\nKd 1 1 1\nmap_Kd ../textures/'+tex.name+'\n',newline='\n')
f=root/'mods/shift_circuit/asset_textures.lua';s=f.read_text();s=s.replace('return {','return {\n'+''.join(' ["robot_'+k+'"]="sc_surface_robot_'+k+'.png",\n'for k in models if ('["robot_'+k+'"]')not in s));f.write_text(s,newline='\n')
print('Built 12 distinct chassis with editable textures, UVs and face normals.')
