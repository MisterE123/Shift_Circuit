"""Editable blue starting-direction cards and the six-slot opening HUD."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
r=Path(__file__).resolve().parents[1];src=r/'art/ui';tex=r/'mods/shift_circuit/textures'
font=ImageFont.load_default_imagefont()
def save(im,name):
 im.save(src/(name+'.png'));im.resize((im.width*2,im.height*2),Image.Resampling.NEAREST).save(tex/(name+'.png'))
def plate(w,h):
 im=Image.new('RGBA',(w,h),'#0b1723');d=ImageDraw.Draw(im);d.rectangle((1,1,w-2,h-2),outline='#426271');d.line((3,2,w-4,2),fill='#9acfc5');return im,d
for choice,source in [('FORWARD','STEP'),('LEFT','LEFT'),('RIGHT','RIGHT'),('UTURN','UTURN')]:
 im,d=plate(32,32);d.rectangle((2,2,29,29),fill='#102b48',outline='#629fe5')
 glyph=Image.open(src/('sc_card_'+source+'.png')).convert('RGBA')
 for y in range(4,21):
  for x in range(4,25):
   cr,cg,cb,ca=glyph.getpixel((x,y))
   if ca and max(cr,cg,cb)>140:im.putpixel((x,y),(133,202,255,255))
 if choice=='FORWARD':d.rectangle((23,4,28,20),fill='#102b48')
 d.text((4,21),'FACE',font=font,fill='#a3d7ff');save(im,'sc_direction_'+choice)
im,d=plate(32,32);d.rectangle((2,2,29,29),outline='#629fe5');d.text((4,11),'AUTO',font=font,fill='#629fe5');save(im,'sc_direction_empty')
im,d=plate(262,64);d.text((12,1),'$ START FACING + 5 REGISTERS',font=font,fill='#9acfc5');d.rectangle((17,13,55,49),outline='#629fe5');save(im,'sc_register_terminal_start')
for active in (False,True):
 im=Image.new('RGBA',(32,10));d=ImageDraw.Draw(im);d.text((4,0),'FACE',font=font,fill='#a3d7ff'if active else '#629fe5');save(im,'sc_register_start'+('_active'if active else ''))
 im=Image.new('RGBA',(32,10));d=ImageDraw.Draw(im);d.text((13,0),'6',font=font,fill='#efc56e'if active else '#9acfc5')
 if active:d.polygon([(2,3),(7,5),(2,7)],fill='#efc56e');d.polygon([(29,3),(24,5),(29,7)],fill='#efc56e')
 save(im,'sc_register_6'+('_active'if active else ''))
