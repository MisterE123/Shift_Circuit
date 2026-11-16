from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
r=Path(__file__).resolve().parents[1];a=r/'art/ui/command_palette';a.mkdir(parents=True,exist_ok=True)
for count in range(6,19):
 w=count*28+8;im=Image.new('RGBA',(w,46),'#0b1822ed');d=ImageDraw.Draw(im)
 d.rectangle((0,0,w-1,45),outline='#527986');d.line((3,1,w-4,1),fill='#a0d8d1');d.line((3,13,w-4,13),fill='#284550')
 d.text((6,1),'Command Palette >_',font=ImageFont.load_default_imagefont(),fill='#b5ffd0')
 for x in (2,w-4):d.rectangle((x,42,x+1,43),fill='#efc56e')
 im.save(a/f'{count}.png');im.resize((w*2,92),Image.Resampling.NEAREST).save(r/'mods/shift_circuit/textures'/f'sc_command_palette_{count}.png')
