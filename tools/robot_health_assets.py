"""Generate editable pixel health bars without overwriting existing artwork."""
from pathlib import Path
from PIL import Image,ImageDraw
root=Path(__file__).resolve().parents[1];textures=root/'mods/shift_circuit/textures'
for maximum in range(1,10):
 for hp in range(maximum+1):
  path=textures/f'sc_robot_health_{maximum}_{hp}.png'
  if path.exists():continue
  im=Image.new('RGBA',(46,10));d=ImageDraw.Draw(im)
  d.rectangle((0,1,45,8),fill='#0b1723',outline='#9acfc5')
  color='#66d7af' if hp/maximum>.5 else '#efc56e' if hp/maximum>.25 else '#ef806e'
  for i in range(maximum):
   x=3+i*40//maximum;right=3+(i+1)*40//maximum-2
   d.rectangle((x,3,right,6),fill=color if i<hp else '#293e49')
  im.save(path)
