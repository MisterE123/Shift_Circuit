"""Editable pixel icons: watching eye, winding spring, charging arrows."""
from pathlib import Path
from PIL import Image, ImageDraw
root = Path(__file__).resolve().parents[1]
for active, color in [('watch', '#75d8c4'), ('wind', '#f4c465'), ('charge', '#ff8268')]:
    path = root / 'mods/shift_circuit/textures' / f'sc_ram_cycle_{active}.png'
    if path.exists():
        continue
    im = Image.new('RGBA', (46, 16)); d = ImageDraw.Draw(im)
    for i, state in enumerate(['watch', 'wind', 'charge']):
        x = i * 16; ink = color if state == active else '#597481'
        d.rectangle((x, 0, x+13, 15), fill='#0b1723', outline=ink)
        if state == 'watch':
            d.line([(x+2,7),(x+5,4),(x+8,4),(x+11,7),(x+8,10),(x+5,10),(x+2,7)],fill=ink)
            d.rectangle((x+6,6,x+7,8),fill=ink)
        elif state == 'wind':
            d.line([(x+3,3),(x+10,3),(x+3,6),(x+10,8),(x+3,11),(x+10,11)],fill=ink,width=1)
        else:
            for shift in [0,5]:
                d.line([(x+3+shift,4),(x+6+shift,7),(x+3+shift,10)],fill=ink,width=2)
        if state == active:
            d.rectangle((x+3,13,x+10,14),fill=ink)
    im.save(path)
