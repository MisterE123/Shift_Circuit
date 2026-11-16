"""Original 64px robot/circuit badge, matching the editable game pixel art."""
from pathlib import Path
from PIL import Image, ImageDraw
root=Path(__file__).resolve().parents[1]
art=root/'art/ui'; menu=root/'menu'
art.mkdir(parents=True,exist_ok=True);menu.mkdir(exist_ok=True)
im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im)
d.polygon([(10,1),(53,1),(62,10),(62,53),(53,62),(10,62),(1,53),(1,10)],fill='#0b1925')
d.line([(10,3),(53,3),(60,10),(60,53),(53,60),(10,60),(3,53),(3,10),(10,3)],fill='#527986',width=2)
# Program-flow circuit around the robot, with a clear directional arrow.
d.line([(12,40),(8,40),(8,13),(43,13)],fill='#78ddc4',width=3)
d.polygon([(43,8),(51,13),(43,18)],fill='#78ddc4')
d.line([(52,25),(56,25),(56,51),(23,51)],fill='#efbf65',width=3)
d.polygon([(23,46),(15,51),(23,56)],fill='#efbf65')
# Broad tread silhouette, brass chassis, pale sensor head.
for x in (16,40):
    d.rectangle((x,33,x+8,46),fill='#070e17')
    d.rectangle((x+1,34,x+6,44),fill='#294352')
    for y in (35,39,43):d.line((x+1,y,x+6,y),fill='#577482')
d.rectangle((24,29,39,44),fill='#b17f38')
d.rectangle((24,29,38,40),fill='#e5b95f')
d.line((24,29,38,29),fill='#ffe0a0')
d.rectangle((22,20,41,31),fill='#617f8c')
d.rectangle((22,19,39,29),fill='#acc8c9')
d.line((22,19,39,19),fill='#e0eee1')
d.rectangle((24,23,37,27),fill='#112c37')
d.rectangle((26,24,35,25),fill='#7ff0cc')
d.rectangle((30,15,32,18),fill='#789aa7')
d.rectangle((29,14,33,15),fill='#e9c46b')
for x,y in [(9,8),(54,8),(9,55),(54,55)]:d.rectangle((x,y,x+1,y+1),fill='#9bbbc0')
im.save(art/'sc_game_icon.png')
icon=im.resize((128,128),Image.Resampling.NEAREST)
icon.save(menu/'icon.png')
icon.save(root/'mods/shift_circuit/textures/sc_game_icon.png')
print('Wrote editable 64px source and 128px game icon')
