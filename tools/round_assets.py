"""Editable racer HUD rows and execution camera tools."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
root=Path(__file__).resolve().parents[1];src=root/'art/ui';out=root/'mods/shift_circuit/textures';font=ImageFont.load_default_imagefont()
def save(name,im):
 path=src/(name+'.png')
 if not path.exists():im.save(path)
 im=Image.open(path);im.resize((im.width*2,im.height*2),Image.Resampling.NEAREST).save(out/path.name)
def panel(w,h,edge='#426574'):
 im=Image.new('RGBA',(w,h),'#0e2530');d=ImageDraw.Draw(im);d.rectangle((0,0,w-1,h-1),outline=edge);return im,d
im,d=panel(128,12);d.text((5,1),'RACERS / CP = PASSED',font=font,fill='#a5ddcd');save('sc_racer_header',im)
for own in (False,True):
 im,d=panel(128,14,'#d3ae65'if own else '#355361');save('sc_racer_row'+('_self'if own else ''),im)
for key,label,color in [('planning','PLAN','#edc77c'),('ready','READY','#99e6c4'),('executing','RUN','#9bc5ef'),('down','DOWN','#ee9c8a'),('finished','DONE','#edcf84')]:
 im,d=panel(32,10);d.text((1,0),label,font=font,fill=color);save('sc_racer_'+key,im)
for n in range(10):
 im,d=panel(24,10);d.text((2,0),'CP'+str(n),font=font,fill='#a5ddcd');save('sc_racer_cp_'+str(n),im)
for n in range(1,9):
 im,d=panel(24,10);d.text((6,0),'#'+str(n),font=font,fill='#edcf84');save('sc_racer_place_'+str(n),im)
for direction in ('left','right'):
 im,d=panel(32,32,'#83c5b7');d.arc((4,3,27,22),20,315,fill='#efc56e',width=2)
 if direction=='left':d.polygon([(4,6),(11,5),(7,12)],fill='#efc56e')
 else:d.polygon([(28,17),(22,22),(21,15)],fill='#efc56e')
 d.rectangle((11,9,21,17),fill='#6faeb6');d.rectangle((14,11,18,15),fill='#10232f');d.text((1 if direction=='right'else 4,23),direction.upper(),font=font,fill='#b5dfd3');save('sc_orbit_'+direction,im)
def phase_icon(index,color):
 im=Image.new('RGBA',(14,14));d=ImageDraw.Draw(im)
 if index==1:
  d.rectangle((1,1,9,10),outline=color);d.rectangle((4,3,12,13),fill='#14303c',outline=color);d.polygon([(6,9),(8,6),(10,9),(9,9),(9,11),(7,11),(7,9)],fill=color)
 elif index in (2,3):
  for y in (2,5,8,11):d.line((1,y,12,y),fill='#547584')
  for y in ((2,7)if index==2 else (5,)):
   d.polygon([(4,y+3),(7,y),(10,y+3),(8,y+3),(8,y+5),(6,y+5),(6,y+3)],fill=color)
 elif index==4:
  d.rectangle((1,3,3,11),fill=color);d.rectangle((4,6,8,8),fill=color);d.line((9,3,9,11),fill=color);d.polygon([(10,5),(13,7),(10,9)],fill=color)
 elif index==5:
  d.arc((2,2,11,11),40,310,fill=color,width=2);d.polygon([(9,0),(13,4),(8,5)],fill=color)
 elif index==6:
  d.rectangle((1,7,9,12),outline=color);d.rectangle((3,3,7,6),fill=color);d.line((7,4,13,4),fill=color);d.line((10,2,12,2),fill=color)
 elif index==7:
  d.rectangle((1,3,5,10),fill=color);d.line((6,6,13,6),fill=color);d.line((11,4,13,8),fill=color);d.line((11,8,13,4),fill=color)
 else:
  d.line((1,12,1,1,12,1,12,12),fill=color,width=2);d.line((6,2,6,6),fill=color,width=2);d.rectangle((3,6,10,8),fill=color);d.line((3,12,10,12),fill=color)
 return im
for active in range(9):
 im,d=panel(88,44);d.text((2,0),'REGISTER ORDER',font=font,fill='#a5ddcd')
 for i in range(1,9):
  col=(i-1)%4;row=(i-1)//4;x=4+col*21;y=11+row*16
  if i==active:d.rectangle((x-1,y-1,x+14,y+14),outline='#efc56e',fill='#41504a')
  im.alpha_composite(phase_icon(i,'#efc56e'if i==active else ('#91bdb2'if active and i<active else '#527887')),(x,y))
  if col<3:d.polygon([(x+16,y+5),(x+19,y+7),(x+16,y+9)],fill='#527887')
 # Row two continues left-to-right; a small return arrow denotes continuation.
 d.line((85,23,85,25,2,25,2,29),fill='#426574');d.polygon([(1,28),(3,28),(2,30)],fill='#91bdb2')
 save('sc_phase_order_'+str(active),im)
