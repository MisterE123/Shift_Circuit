"""Editable 1x pixel activation badges, exported at 2x for HUD use."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
root=Path(__file__).resolve().parents[1];art=root/'art/ui/schedules';art.mkdir(parents=True,exist_ok=True);tex=root/'mods/shift_circuit/textures';font=ImageFont.load_default_imagefont()
def save(im,name):
 im.save(art/(name+'.png'));im.resize((im.width*2,im.height*2),Image.Resampling.NEAREST).save(tex/(name+'.png'))
for parity in (0,1):
 for current in range(6):
  im=Image.new('RGBA',(70,28),'#0b1822e8');d=ImageDraw.Draw(im);d.rectangle((0,0,69,27),outline='#527986');d.text((3,0),'STEPS',font=font,fill='#a2c1c9')
  for step in range(1,6):
   x=3+(step-1)*13;active=step%2==parity
   d.rectangle((x,12,x+11,24),fill='#28563c'if active else '#142733',outline='#b5ffd0'if step==current else '#74e596'if active else '#284550')
   d.text((x+3,12),str(step),font=font,fill='#e4ffe9'if active else '#58717c')
  save(im,f'sc_schedule_steps_{parity}_{current}')
im=Image.new('RGBA',(94,28),'#0b1822e8');d=ImageDraw.Draw(im);d.rectangle((0,0,93,27),outline='#527986');d.text((3,0),'ROUND CHANCES',font=font,fill='#a2c1c9');save(im,'sc_schedule_rounds')
im=Image.new('RGBA',(94,28),'#0b1822e8');d=ImageDraw.Draw(im);d.rectangle((0,0,93,27),outline='#527986');d.text((3,0),'1-2 CRATES',font=font,fill='#b5ffd0');d.text((3,13),'EVERY ROUND',font=font,fill='#a2c1c9');save(im,'sc_schedule_factory_rounds')
for c in '0123456789-':
 im=Image.new('RGBA',(7,12));ImageDraw.Draw(im).text((0,0),c,font=font,fill='#b5ffd0');save(im,'sc_schedule_digit_'+('dash'if c=='-'else c))
