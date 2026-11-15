"""Original procedural pixel art and grid-aligned OBJ assets. Requires Pillow."""
from pathlib import Path
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[1]
T=ROOT/'mods/shift_circuit/textures'; T.mkdir(parents=True,exist_ok=True)
M=ROOT/'mods/shift_circuit/models'; M.mkdir(parents=True,exist_ok=True)
def plate(name,base,edge):
    im=Image.new('RGB',(16,16),base); d=ImageDraw.Draw(im)
    d.rectangle((0,0,15,15),outline=edge); d.line((1,1,14,1),fill='#72828a')
    for x,y in [(2,2),(13,2),(2,13),(13,13)]: d.point((x,y),fill='#b4c0bc')
    im.save(T/name); return im
plate('sc_floor.png','#283c4c','#142331')
plate('sc_wall.png','#566777','#223343')
plate('sc_button.png','#244151','#4b7d89')
im=plate('sc_press.png','#d69848','#302b2b'); d=ImageDraw.Draw(im)
for i in range(-16,32,8): d.polygon([(i,0),(i+3,0),(i+19,15),(i+16,15)],fill='#252e37')
im.save(T/'sc_press.png')
digits={1:['010','110','010','010','111'],2:['110','001','010','100','111'],3:['110','001','010','001','110']}
for n,rows in digits.items():
    im=plate(f'sc_station{n}.png','#397c78','#a2edc9'); d=ImageDraw.Draw(im)
    for y,row in enumerate(rows):
        for x,v in enumerate(row):
            if v=='1': d.rectangle((5+x*2,3+y*2,6+x*2,4+y*2),fill='#fff1b8')
    im.save(T/f'sc_station{n}.png')
sheet=Image.new('RGB',(16,16*8))
for f in range(8):
    im=Image.new('RGB',(16,16),'#254d53'); d=ImageDraw.Draw(im)
    for y in range(16):
        if (y+f*2)%8<2: d.line((2,y,13,y),fill='#548c87')
    d.rectangle((0,0,1,15),fill='#b4b39c'); d.rectangle((14,0,15,15),fill='#b4b39c')
    d.polygon([(7,3),(3,8),(6,8),(6,12),(9,12),(9,8),(12,8)],fill='#b5f3cc')
    sheet.paste(im,(0,f*16))
sheet.save(T/'sc_belt.png')
im=Image.new('RGB',(16,16),'#c9d4cf'); d=ImageDraw.Draw(im)
d.rectangle((0,0,15,15),outline='#374957'); d.rectangle((2,5,13,9),fill='#182a39')
d.rectangle((4,6,5,7),fill='#fff4b2'); d.rectangle((10,6,11,7),fill='#fff4b2')
d.line((4,12,11,12),fill='#647d85'); im.save(T/'sc_robot.png')
def mesh(name,boxes):
    lines=['# Original Shift Circuit geometry; positions quantized to 1/16 tile.', 'vt 0 0','vt 1 0','vt 1 1','vt 0 1']; count=0
    for x0,y0,z0,x1,y1,z1 in boxes:
        verts=[(x0,y0,z0),(x1,y0,z0),(x1,y1,z0),(x0,y1,z0),(x0,y0,z1),(x1,y0,z1),(x1,y1,z1),(x0,y1,z1)]
        lines += ['v %s %s %s'%tuple(c*10 for c in v) for v in verts]
        for face in [(4,3,2,1),(5,6,7,8),(1,2,6,5),(8,7,3,4),(1,5,8,4),(6,2,3,7)]:
            lines.append('f '+' '.join(f'{count+v}/{i+1}' for i,v in enumerate(face)))
        count+=8
    (M/name).write_text('\n'.join(lines)+'\n')
mesh('sc_robot.obj',[(-.375,-.25,-.375,.375,.375,.375),(-.25,.375,-.25,.25,.75,.25),(-.5,-.5,-.375,-.25,-.25,.375),(.25,-.5,-.375,.5,-.25,.375),(-.125,.75,-.125,.125,1,.125),(-.1875,.4375,.25,.1875,.625,.375)])
mesh('sc_ram.obj',[(-.875,-.25,-.875,.875,.125,.875),(-.125,.125,-.125,.125,1.125,.125)])
mesh('sc_press_frame.obj',[(-1,-.5,-1,-.75,2.5,-.75),(.75,-.5,-1,1,2.5,-.75),(-1,2.25,-1,1,2.5,1)])
# Reference contact sheet: this is source-art documentation, not an in-game screenshot.
files=sorted(T.glob('*.png')); out=Image.new('RGB',(len(files)*128,160),'#101c2b'); d=ImageDraw.Draw(out)
for i,p in enumerate(files):
    im=Image.open(p).crop((0,0,16,16)).resize((112,112),Image.Resampling.NEAREST)
    out.paste(im,(i*128+8,8)); d.text((i*128+5,130),p.stem.replace('sc_',''),fill='white')
out.save(ROOT/'asset_palette.png')
print('Generated',len(files),'textures and 3 original meshes.')
import runpy
runpy.run_path(str(ROOT/'tools/refine_assets.py'))
runpy.run_path(str(ROOT/'tools/hud_assets.py'))

runpy.run_path(str(ROOT/'tools/menu_assets.py'))
