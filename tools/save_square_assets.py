from pathlib import Path
from PIL import Image,ImageDraw
root=Path(__file__).resolve().parents[1];mod=root/'mods/shift_circuit'
# Unnumbered floppy-disk emblem distinguishes reboot saves from route checkpoints.
im=Image.new('RGBA',(32,32),'#102c37');d=ImageDraw.Draw(im);d.rectangle((1,1,30,30),outline='#83b8d9',width=2);d.rectangle((4,4,27,27),outline='#365c72');d.polygon([(10,8),(21,8),(24,11),(24,24),(8,24),(8,8)],fill='#a8d9eb');d.rectangle((12,8,20,14),fill='#24485a');d.rectangle((17,9,19,12),fill='#89bad1');d.rectangle((11,18,21,23),fill='#24485a');d.line((13,20,19,20),fill='#a8d9eb')
im.save(root/'art/ui/sc_save_square.png');im.resize((64,64),Image.Resampling.NEAREST).save(mod/'textures/sc_tile_save.png')
im.resize((48,48),Image.Resampling.NEAREST).save(mod/'textures/sc_save_achievement.png')
