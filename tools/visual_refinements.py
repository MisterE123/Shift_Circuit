from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import math
root=Path(__file__).resolve().parents[1];M=root/'mods/shift_circuit/models';T=root/'mods/shift_circuit/textures';A=root/'art/ui'
s=(root/'tools/refine_assets.py').read_text();ns={'M':M};exec(s[s.index('def mesh('):s.index('robot=[')],ns)
models={
'robot_scout':[(-.42,-.5,-.4,-.22,-.18,.4,0),(.22,-.5,-.4,.42,-.18,.4,0),(-.25,-.23,-.23,.25,.35,.26,4),(-.38,.35,-.22,.38,.81,.24,1),(-.32,.51,.24,.32,.68,.29,5),(-.24,.55,.29,.24,.61,.3,4),(-.09,.81,-.08,.09,1.05,.08,1)],
'robot_loader':[(-.61,-.5,-.5,-.29,-.1,.5,0),(.29,-.5,-.5,.61,-.1,.5,0),(-.42,-.2,-.33,.42,.36,.33,3),(-.31,.36,-.24,.31,.81,.26,2),(-.24,.52,.26,.24,.64,.3,5),(-.6,.03,-.19,-.42,.37,.2,1),(.42,.03,-.19,.6,.37,.2,1),(-.2,-.1,.33,.2,.14,.42,1)],
'robot_walker':[(-.45,-.5,-.22,-.08,-.34,.38,1),(.08,-.5,-.22,.45,-.34,.38,1),(-.32,-.34,-.1,-.17,-.08,.15,2),(.17,-.34,-.1,.32,-.08,.15,2),(-.32,-.08,-.25,.32,.38,.25,4),(-.25,.38,-.22,.25,.81,.24,2),(-.2,.49,.24,.2,.66,.3,5),(-.1,.53,.3,.1,.6,.31,3),(-.48,.04,-.07,-.32,.28,.09,1),(.32,.04,-.07,.48,.28,.09,1)]}
for power in (1,2,3):
 boxes=[(-.98,-.5,-.1,.98,.48,.08,1),(-.98,.48,-.12,.98,.61,.1,3)]
 for i in range(power):
  x=(i-(power-1)/2)*.375;boxes += [(x-.13,-.13,.08,x+.13,.13,.16,0),(x-.094,-.094,.16,x+.094,.094,.1875,7)]
 models['laser'+str(power)]=boxes
for name,boxes in models.items():
 ns['mesh']('sc_'+name+'.obj',boxes)
 tex=T/('sc_surface_'+name+'.png')
 if not tex.exists():Image.open(T/'sc_materials.png').save(tex)
 obj=M/('sc_'+name+'.obj');verts=[];lines=[];normal=0
 for line in obj.read_text().splitlines():
  if line.startswith('v '):verts.append(tuple(map(float,line.split()[1:])))
  if line.startswith('f '):
   a,b,c=[verts[int(t.split('/')[0])-1]for t in line.split()[1:]];u=[b[i]-a[i]for i in range(3)];v=[c[i]-a[i]for i in range(3)];n=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]];l=math.sqrt(sum(x*x for x in n));normal+=1;lines.append('vn '+' '.join(str(x/l)for x in n));line='f '+' '.join(t+'/'+str(normal)for t in line.split()[1:])
  lines.append(line)
 obj.write_text('mtllib '+obj.stem+'.mtl\nusemtl editable\n'+'\n'.join(lines)+'\n');obj.with_suffix('.mtl').write_text('newmtl editable\nKd 1 1 1\nmap_Kd ../textures/'+tex.name+'\n')
f=root/'mods/shift_circuit/asset_textures.lua';s=f.read_text();s=s.replace('return {','return {\n'+''.join(' ["'+k+'"]="sc_surface_'+k+'.png",\n'for k in models if k.startswith('robot_') and ('["'+k+'"]') not in s));f.write_text(s)
im=Image.open(T/'sc_surface_conveyor_arrows.png').convert('RGBA');pix=im.load()
for y in range(im.height):
 for x in range(im.width):
  r,g,b,a=pix[x,y]
  if r>g and g>b*1.15:pix[x,y]=(71,207,189,a)
im.save(T/'sc_surface_conveyor_arrows_green.png')
# Extract only the existing icon drawing function; leave all other hand-edited art intact.
s=(root/'tools/round_assets.py').read_text();ctx={'Image':Image,'ImageDraw':ImageDraw};exec(s[s.index('def phase_icon'):s.index('for active in range(9):')],ctx)
font=ImageFont.load_default_imagefont();colors=['#9acfff','#efc56e','#58dcb0','#f19c6e','#c4a0ef','#82e9df','#f27c7c','#e8b28b'];labels=['CARDS','2X BELT','BELT','PUSH','ROTATE','WEAPON','LASER','CRUSH']
for active in range(9):
 im=Image.new('RGBA',(220,79),'#0b1c28');d=ImageDraw.Draw(im);d.rectangle((0,0,219,78),outline='#527887');d.text((5,2),'PHASE ORDER',font=font,fill='#bdeadd')
 for i in range(8):
  x=4+i%4*54;y=16+i//4*29;color=colors[i]
  d.rectangle((x,y,x+51,y+26),outline=color,fill='#294651'if active==i+1 else '#102633')
  if active==i+1:d.rectangle((x+1,y+1,x+50,y+25),outline='#ffffff');d.polygon([(x+2,y+2),(x+7,y+5),(x+2,y+8)],fill='#ffffff')
  im.alpha_composite(ctx['phase_icon'](i+1,color),(x+14,y+1));d.text((x+2,y+2),str(i+1),font=font,fill=color);d.text((x+5,y+16),labels[i],font=font,fill=color)
 im.save(A/('sc_phase_order_'+str(active)+'.png'));im.resize((440,158),Image.Resampling.NEAREST).save(T/('sc_phase_order_'+str(active)+'.png'))
