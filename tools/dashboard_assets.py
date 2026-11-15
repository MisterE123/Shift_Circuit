"""Editable 1x dashboard panels; preserves hand-edited source PNGs."""
from pathlib import Path
from PIL import Image, ImageDraw
root=Path(__file__).resolve().parents[1];src=root/'art/ui';out=root/'mods/shift_circuit/textures'
def export(name,im):
 p=src/(name+'.png')
 if not p.exists(): im.save(p)
 im=Image.open(p);im.resize((im.width*2,im.height*2),Image.Resampling.NEAREST).save(out/p.name)
def panel(w,h,accent='#8bdbcc'):
 im=Image.new('RGBA',(w,h),'#10232f');d=ImageDraw.Draw(im)
 d.rectangle((0,0,w-1,h-1),outline='#426574');d.line((2,1,w-3,1),fill=accent)
 for x in (2,w-4):
  for y in (3,h-5):d.rectangle((x,y,x+1,y+1),fill='#668693')
 d.line((3,h-3,w-4,h-3),fill='#07141f');return im
im=Image.new('RGBA',(320,226),'#091620');d=ImageDraw.Draw(im)
for y in range(20,222,8):
 for x in range(8,316,8):d.point((x,y),fill='#1a303c')
d.rectangle((1,1,318,224),outline='#496879');d.line((8,16,311,16),fill='#4b756f')
for x in range(5,315,8):d.rectangle((x,222,x+3,223),fill='#a2814d')
export('sc_dashboard_bg',im)
export('sc_dashboard_stat',panel(70,25))
export('sc_dashboard_weapon',panel(100,132,'#e7bb69'))
export('sc_dashboard_equipment',panel(87,33))
im=Image.new('RGBA',(112,64));d=ImageDraw.Draw(im)
d.rectangle((33,18,78,49),fill='#18323f',outline='#517481');d.rectangle((40,7,71,25),fill='#294651',outline='#89cbbf')
d.rectangle((48,14,63,17),fill='#97e0ce');d.rectangle((29,30,34,51),fill='#56727f');d.rectangle((77,30,82,51),fill='#56727f')
for x in (33,68):d.rectangle((x,50,x+10,58),fill='#334d59')
for x,y in ((15,13),(89,21),(19,46)):
 d.rectangle((x,y,x+8,y+8),outline='#caa55e');d.line((x+4,y+2,x+4,y+6),fill='#caa55e');d.line((x+2,y+4,x+6,y+4),fill='#caa55e')
export('sc_dashboard_empty',im)
for kind,maximum in [('hull',5),('energy',9),('shield',3),('hand',12)]:
 for value in range(maximum+1):
  im=Image.new('RGBA',(64,5),'#091620');d=ImageDraw.Draw(im)
  for i in range(maximum):
   x=1+i*62//maximum;end=1+(i+1)*62//maximum-2
   color=('#efc56e'if kind=='hand'else '#97dfcf')if i<value else '#294652'
   if kind=='hull'and value<=2 and i<value:color='#ed967d'
   d.rectangle((x,1,max(x,end),3),fill=color)
  export('sc_dashboard_'+kind+'_'+str(value),im)
