from pathlib import Path
from PIL import Image,ImageDraw
root=Path(__file__).resolve().parents[1]
art=root/'art/ui/menu';art.mkdir(parents=True,exist_ok=True)
textures=root/'mods/shift_circuit/textures'
for name,fill,edge,light in [('frame','#0b1822','#365361','#90c6ca'),('panel','#10232e','#284550','#4c7180'),('button','#1a3542','#4b7280','#a0d8d1'),('hover','#244c58','#8dcfc5','#d1f5df'),('pressed','#132e39','#5ca89f','#8dcfc5'),('selected','#214b32','#74e596','#b5ffd0'),('selected_hover','#2c6541','#92ffb5','#d6ffe4'),('selected_pressed','#183c27','#74e596','#b5ffd0'),('primary','#53462d','#dfb866','#ffe0a0'),('danger','#482d35','#b16d6b','#f4b095')]:
 im=Image.new('RGBA',(32,32),fill);d=ImageDraw.Draw(im)
 d.rectangle((0,0,31,31),outline='#07111a');d.rectangle((1,1,30,30),outline=edge)
 if name.startswith('selected'):d.rectangle((2,2,29,29),outline=edge)
 d.line((3,2,28,2),fill=light);d.line((2,3,2,28),fill=edge)
 for x,y in [(3,3),(27,3),(3,27),(27,27)]:d.rectangle((x,y,x+1,y+1),fill=light)
 im.save(art/(name+'.png'));im.save(textures/('sc_ui_'+name+'.png'))

# Square pixel icons. Only flat colors occupy nine-slice stretch bands.
for level in range(3):
 im=Image.new('RGBA',(32,32));d=ImageDraw.Draw(im)
 d.polygon([(5,13),(10,13),(17,7),(17,25),(10,19),(5,19)],fill='#b8e7d9')
 if level==0:d.line((21,12,28,20),fill='#ef9b7e',width=2);d.line((28,12,21,20),fill='#ef9b7e',width=2)
 else:
  d.line((21,12,24,14,24,18,21,21),fill='#8ae8a5',width=2)
  if level==2:d.line((25,7,29,11,30,16,29,21,25,25),fill='#8ae8a5',width=2)
 im.save(art/f'volume_{level}.png');im.save(textures/f'sc_ui_volume_{level}.png')
im=Image.new('RGBA',(32,32));d=ImageDraw.Draw(im)
for x,h in [(6,10),(14,22),(22,16)]:d.rectangle((x,27-h,x+3,27),fill='#b8e7d9');d.rectangle((x-2,25-h,x+5,28-h),fill='#efc46b')
im.save(art/'audio.png');im.save(textures/'sc_ui_audio.png')
