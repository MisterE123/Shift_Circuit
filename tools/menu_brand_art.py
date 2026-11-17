"""Native Shift Circuit menu art. MIT code; original artwork CC0.
Uses existing game textures and robot previews; no generated illustration.
"""
from pathlib import Path
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1];T=ROOT/'mods/shift_circuit/textures';A=ROOT/'art/menu';M=ROOT/'menu'
A.mkdir(parents=True,exist_ok=True)
P={'dark':'#0b1923','panel':'#162a35','line':'#253e49','mint':'#9edcca','gold':'#eac064','steel':'#6e929c'}
# Editable bitmap lettering: intentionally flat, no bevels/glows/rivets.
font={'S':['11111','10000','10000','11111','00001','00001','11111'],'H':['10001','10001','10001','11111','10001','10001','10001'],'I':['111','010','010','010','010','010','111'],'F':['11111','10000','10000','11110','10000','10000','10000'],'T':['11111','00100','00100','00100','00100','00100','00100'],'C':['11111','10000','10000','10000','10000','10000','11111'],'R':['11110','10001','10001','11110','10100','10010','10001'],'U':['10001','10001','10001','10001','10001','10001','11111']}
def word(im,txt,x,y,k,color):
 d=ImageDraw.Draw(im)
 for c in txt:
  if c==' ':x+=4*k;continue
  rows=font[c]
  for j,row in enumerate(rows):
   for i,b in enumerate(row):
    if b=='1':d.rectangle((x+i*k,y+j*k,x+(i+1)*k-1,y+(j+1)*k-1),fill=color)
  x+=(len(rows[0])+1)*k
 return x
banner=Image.new('RGBA',(354,64));d=ImageDraw.Draw(banner)
# Match the game's original icon and colour split, without a decorative plaque.
icon=Image.open(ROOT/'art/ui/sc_game_icon.png').convert('RGBA').resize((48,48),Image.Resampling.NEAREST);banner.alpha_composite(icon,(2,8))
x=word(banner,'SHIFT',65,18,4,P['mint']);word(banner,'CIRCUIT',x+12,18,4,P['gold'])
banner.save(A/'banner-simple.png')
if (A/'banner-approved.png').exists():
 import shutil
 shutil.copyfile(A/'banner-approved.png',M/'header.png')
 banner=Image.open(A/'banner-approved.png').convert('RGBA')
 banner.thumbnail((520,130),Image.Resampling.LANCZOS)
else:
 banner.resize((1062,192),Image.Resampling.NEAREST).save(M/'header.png')
bg=Image.new('RGBA',(640,360),P['dark']);d=ImageDraw.Draw(bg)
# Low contrast circuit traces confined to the margins, no busy art under menus.
for side in [0,1]:
 x=18 if side==0 else 621
 d.line([(x,0),(x,55),(x+(10 if side==0 else -10),65),(x+(10 if side==0 else -10),248)],fill=P['line'],width=1)
 for y in [74,152,230]:d.rectangle((x-2,y-2,x+2,y+2),fill=P['steel'])
# A readable small board route made from the same deck texture as the actual game.
deck=Image.open(T/'sc_tile_deck.png').convert('RGBA').resize((32,32),Image.Resampling.NEAREST)
for row in range(2):
 for col in range(18):bg.alpha_composite(deck,(32+col*32,278+row*32))
d=ImageDraw.Draw(bg)
for col in range(2,16):
 x=32+col*32;y=279
 d.rectangle((x,y,x+31,y+29),fill='#152b37')
 for q in range(3,28,4):d.line((x+2,y+q,x+29,y+q),fill='#658791',width=2)
 d.line((x+2,y,x+29,y),fill='#90adb3');d.line((x+2,y+30,x+29,y+30),fill='#90adb3')
 if col%2==0:
  d.polygon([(x+8,y+11),(x+18,y+11),(x+18,y+7),(x+25,y+15),(x+18,y+23),(x+18,y+19),(x+8,y+19)],fill=P['mint'])
# Real in-game robot geometry, already rendered to editable sprite sheets.
for model,x,frame in [('robot_loader',36,22),('robot_beetle',532,3)]:
 sheet=Image.open(T/('sc_preview_'+model+'.png')).convert('RGBA')
 robot=sheet.crop((0,frame*128,128,(frame+1)*128)).resize((88,88),Image.Resampling.NEAREST)
 bg.alpha_composite(robot,(x,233))
# A simple green route destination, borrowed from checkpoint imagery.
checkpoint=Image.open(T/'sc_tile_dock1.png').convert('RGBA').resize((32,32),Image.Resampling.NEAREST);bg.alpha_composite(checkpoint,(544,278))
bg.convert('RGB').save(A/'background.png');bg.convert('RGB').resize((1920,1080),Image.Resampling.NEAREST).save(M/'background.png')
# Standalone shareable banner; title source remains transparent for Luanti.
wide=Image.new('RGBA',(640,160),P['dark']);wide.alpha_composite(banner,((640-banner.width)//2,35));wide.save(A/'banner-wide.png')
preview=bg.copy();preview.alpha_composite(banner,((640-banner.width)//2,22));preview.resize((1280,720),Image.Resampling.NEAREST).save(A/'preview.png')
print('Created editable native menu artwork and Luanti background/header')
