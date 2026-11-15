"""Editable, narrow pit-boundary strip. Re-export without replacing custom art."""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
mod = root / 'mods/shift_circuit'
source = root / 'art/ui/sc_pit_edge.png'
if not source.exists():
    im = Image.new('RGBA', (64, 4))
    for y in range(4):
        for x in range(64):
            im.putpixel((x, y), (239, 181, 77, 255) if (x-y) % 8 < 4 else (32, 45, 53, 255))
    im.save(source)
Image.open(source).save(mod / 'textures/sc_pit_edge.png')
# 2 world units wide, .12 deep; entity origin is the strip center.
(mod / 'models/sc_pit_edge.obj').write_text('''mtllib sc_pit_edge.mtl
usemtl editable
v -10 0 -0.6
v -10 0 0.6
v 10 0 0.6
v 10 0 -0.6
vt 0 0
vt 0 1
vt 1 1
vt 1 0
vn 0 1 0
f 1/1/1 2/2/1 3/3/1
f 1/1/1 3/3/1 4/4/1
''')
(mod / 'models/sc_pit_edge.mtl').write_text('newmtl editable\nKd 1 1 1\nmap_Kd ../textures/sc_pit_edge.png\n')
# Miter the inner corners where perpendicular warning strips meet. They share
# a diagonal instead of overlapping coplanar faces. Engine X is pre-mirrored.
for corners in range(4):
    left=-10+(1.2 if corners & 1 else 0)
    right=10-(1.2 if corners & 2 else 0)
    points=[(left,-.6),(-10,.6),(10,.6),(right,-.6)]
    lines=[f'mtllib sc_pit_edge_{corners}.mtl','usemtl editable']
    lines += [f'v {-x:g} 0 {z:g}' for x,z in points]
    lines += [f'vt {(x+10)/20:g} {(z+.6)/1.2:g}' for x,z in points]
    lines += ['vn 0 -1 0','f 1/1/1 2/2/1 3/3/1','f 1/1/1 3/3/1 4/4/1']
    (mod / f'models/sc_pit_edge_{corners}.obj').write_text('\n'.join(lines)+'\n')
    (mod / f'models/sc_pit_edge_{corners}.mtl').write_text((mod / 'models/sc_pit_edge.mtl').read_text())
