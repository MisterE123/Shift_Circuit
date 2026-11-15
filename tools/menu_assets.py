"""Editable, original pixel-art menu backgrounds, buttons, and achievement badges."""
from pathlib import Path
from PIL import Image,ImageDraw
T=Path(__file__).resolve().parents[1]/'mods/shift_circuit/textures'
im=Image.new('RGB',(560,400),'#102330');d=ImageDraw.Draw(im)
# Factory skyline at top, recessed content panels, riveted brass frame.
for x in range(0,560,40):
    h=20+(x//40%3)*9;d.rectangle((x,0,x+30,h),fill='#243e4b');d.rectangle((x+5,5,x+10,h-5),fill='#35616a')
for x in (14,286):
    d.rectangle((x,47,x+260,309),fill='#0c1c28',outline='#395461',width=2)
    d.line((x+3,49,x+257,49),fill='#66a398',width=2)
for x in range(8,555,24):d.rectangle((x,390,x+10,395),fill='#c49b52')
d.rectangle((2,2,557,397),outline='#527080',width=2)
for x,y in [(6,6),(550,6),(6,390),(550,390)]:d.rectangle((x,y,x+3,y+3),fill='#b6c9c7')
im.save(T/'sc_menu_background.png')
for pressed in (False,True):
    im=Image.new('RGBA',(192,40),'#1b3b48');d=ImageDraw.Draw(im)
    d.rectangle((1,1,190,38),outline='#6ea99f' if not pressed else '#e0b760',width=2)
    d.line((4,3,187,3),fill='#a3c9bf' if not pressed else '#8b7042');d.line((4,36,187,36),fill='#091822')
    d.rectangle((5,8,8,31),fill='#d0a85b');d.rectangle((183,8,186,31),fill='#d0a85b')
    im.save(T/('sc_menu_button_pressed.png' if pressed else 'sc_menu_button.png'))
for n in range(1,4):
    im=Image.new('RGBA',(48,48));d=ImageDraw.Draw(im)
    d.polygon([(24,1),(43,12),(43,35),(24,47),(5,35),(5,12)],fill='#1c5957',outline='#e8bd67',width=3)
    d.line((12,25,21,34,37,16),fill='#a7f0d6',width=4)
    d.rectangle((19,4,29,15),fill='#14363c');d.text((21,4),str(n),fill='#ffe3a2')
    im.save(T/f'sc_checkpoint_{n}.png')
print('Generated pixel-art menu and checkpoint badges.')

# Terminal dock reaches the screen's top edge and surrounds five live card slots.
im=Image.new('RGBA',(448,128),'#091b25ed');d=ImageDraw.Draw(im)
d.line((0,0,0,118,12,127,435,127,447,118,447,0),fill='#64aa98',width=2)
d.line((10,22,437,22),fill='#2d655f');d.text((13,7),'$ COMMAND REGISTERS _',fill='#a4dfbf')
for x in range(12,437,8):d.point((x,122),fill='#456e65')
im.save(T/'sc_register_terminal.png')
im=Image.new('RGBA',(32,32));d=ImageDraw.Draw(im);d.rectangle((1,1,30,30),outline='#7ce3cc',width=2)
d.text((2,3),'START',fill='#e6cf83');d.line((16,14,16,24),fill='#7ce3cc',width=3);d.polygon([(9,22),(16,29),(23,22)],fill='#7ce3cc');im.save(T/'sc_start_marker.png')
for name,color in [('spark','#ffbc75'),('shield','#7fe5ff'),('phase','#c3a7ff'),('mote','#8ce7bd'),('dust','#b0a394')]:
 im=Image.new('RGBA',(8,8));d=ImageDraw.Draw(im)
 if name=='shield':d.polygon([(4,0),(7,2),(6,6),(4,7),(1,6),(0,2)],outline=color)
 elif name=='spark':d.line((1,6,6,1),fill=color,width=2);d.point((5,1),fill='white')
 elif name=='dust':d.ellipse((1,1,6,6),fill=(176,163,148,100))
 else:d.rectangle((3,1,4,6),fill=color);d.rectangle((1,3,6,4),fill=color)
 im.save(T/f'sc_fx_{name}.png')
