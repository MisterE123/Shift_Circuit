from pathlib import Path
from PIL import Image,ImageDraw
root=Path(__file__).resolve().parents[1];t=root/'mods/shift_circuit/textures'
for total,prefix in [(90,'sc_program_timer_'),(180,'sc_program_timer_first_')]:
 for seconds in range(total+1):
  im=Image.new('RGBA',(224,24),'#0a1924ed');d=ImageDraw.Draw(im);color='#72ddbd' if seconds>20 else '#efc264' if seconds>10 else '#f17b69'
  d.rectangle((0,0,223,23),outline='#527986');d.line((2,1,221,1),fill=color)
  d.rectangle((7,14,216,20),fill='#243a46');width=round(206*seconds/total)
  if width:d.rectangle((9,16,8+width,18),fill=color)
  for x in range(43,215,35):d.line((x,15,x,19),fill='#0a1924')
  im.resize((448,48),Image.Resampling.NEAREST).save(t/f'{prefix}{seconds}.png')
