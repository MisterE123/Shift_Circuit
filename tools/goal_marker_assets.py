"""Original editable checkpoint waypoint, with a clear flag silhouette."""
from pathlib import Path
from PIL import Image,ImageDraw
r=Path(__file__).resolve().parents[1]
im=Image.new('RGBA',(32,36));d=ImageDraw.Draw(im)
# Dark silhouette makes the flag legible against both bright floors and dark walls.
d.polygon([(6,1),(28,1),(28,8),(24,13),(28,17),(28,20),(10,20),(10,28),(4,28),(4,1)],fill='#091821')
d.rectangle((6,3,8,26),fill='#c6ffe0');d.rectangle((9,3,10,18),fill='#31845a')
d.polygon([(10,3),(25,3),(25,7),(21,12),(25,17),(10,17)],fill='#70e6a1')
d.line([(11,4),(24,4)],fill='#c6ffe0');d.line([(11,16),(24,16)],fill='#339663')
d.rectangle((4,27,11,28),fill='#091821');d.rectangle((5,26,10,26),fill='#70e6a1')
d.polygon([(10,29),(22,29),(16,35)],fill='#091821');d.polygon([(12,30),(20,30),(16,34)],fill='#70e6a1')
im.save(r/'art/ui/sc_goal_marker.png');im.resize((64,72),Image.Resampling.NEAREST).save(r/'mods/shift_circuit/textures/sc_goal_marker.png')
