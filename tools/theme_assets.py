"""Editable hard-pixel UI. Author at 1x, export at integer 2x; no antialiasing."""
from pathlib import Path
import json, math
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[1];T=ROOT/'mods/shift_circuit/textures';M=ROOT/'mods/shift_circuit/models'
SRC=ROOT/'art/ui';SRC.mkdir(parents=True,exist_ok=True)
palette={'dark':'#0b1723','panel':'#19313e','edge':'#426271','light':'#9acfc5','gold':'#efc56e','red':'#e98c83'}
pf=SRC/'palette.json'
if pf.exists():palette.update(json.loads(pf.read_text()))
else:pf.write_text(json.dumps(palette,indent=2))
P=palette;FONT=ImageFont.load_default_imagefont()
def text(d,xy,s,c=None):d.text(xy,s,font=FONT,fill=c or P['light'])
def save(im,name,scale=2):
 im.save(SRC/(name+'.png'));im.resize((im.width*scale,im.height*scale),Image.Resampling.NEAREST).save(T/(name+'.png'))
def plate(w,h):
 im=Image.new('RGBA',(w,h),P['dark']);d=ImageDraw.Draw(im);d.rectangle((1,1,w-2,h-2),outline=P['edge']);d.line((3,2,w-4,2),fill=P['light']);d.line((3,h-3,w-4,h-3),fill='#050e16');return im,d
for glyph in '0123456789P':
 im=Image.new('RGBA',(6,8),P['dark']);d=ImageDraw.Draw(im);text(d,(0,-2),glyph,P['gold']);save(im,'sc_priority_'+glyph.lower())
im=Image.new('RGBA',(72,18));d=ImageDraw.Draw(im)
d.rectangle((0,0,71,12),fill=P['dark'],outline=P['light']);text(d,(6,1),'YOUR ROBOT')
d.polygon([(31,13),(41,13),(36,17)],fill=P['light']);save(im,'sc_your_robot')
im,d=plate(224,64);text(d,(12,1),'$ PROGRAM / 5 REGISTERS')
for x in range(6,219,4):d.rectangle((x,59,x+1,60),fill=P['edge'])
for x in (3,218):d.rectangle((x,6,x+2,9),fill=P['gold'])
save(im,'sc_register_terminal')
commands={'STEP':('MOVE',1),'DASH':('MOVE',2),'MOVE3':('MOVE',3),'BACK':('BACK',1),'BACK2':('BACK',2),'LEFT':('LEFT',0),'RIGHT':('RIGHT',0),'UTURN':('UTURN',0),'WAIT':('WAIT',0),'PULSE':('FIRE',0),'BLINK':('BLINK',0)}
for key,(label,num) in commands.items():
 im,d=plate(32,32);c=P['gold'] if key in ['MOVE3','BACK2','UTURN']else P['light']
 if num:
  if label=='MOVE':d.polygon([(15,5),(7,13),(12,13),(12,20),(18,20),(18,13),(23,13)],fill=c)
  else:d.polygon([(12,5),(18,5),(18,12),(23,12),(15,20),(7,12),(12,12)],fill=c)
  text(d,(23,8),str(num),P['gold'])
 elif key in ['LEFT','RIGHT','UTURN']:
  d.rectangle((10,7,23,10),fill=c);d.rectangle((20,9,23,19),fill=c)
  if key=='UTURN':d.rectangle((8,8,11,15),fill=c);d.polygon([(5,14),(14,14),(10,20)],fill=c)
  else:d.polygon([(5,9),(13,3),(13,15)],fill=c)
  if key=='RIGHT':im=im.transpose(Image.Transpose.FLIP_LEFT_RIGHT);d=ImageDraw.Draw(im)
 elif key=='WAIT':d.rectangle((10,7,13,19),fill=c);d.rectangle((18,7,21,19),fill=c)
 elif key=='BLINK':d.rectangle((7,7,11,19),outline=c);d.rectangle((20,7,24,19),fill=c);d.line((13,13,18,13),fill=P['gold'])
 else:d.line((7,13,24,13),fill=c,width=3);d.rectangle((20,7,22,19),outline=P['gold'])
 text(d,((32-len(label)*6)//2,21),label,c);save(im,'sc_card_'+key)
 im.crop((0,0,32,32)).save(T/('sc_cmd_'+key+'.png'))
im,d=plate(32,32);d.line((12,15,19,15),fill=P['edge']);save(im,'sc_emptycard')
for n in range(1,6):
 for active in (False,True):
  im=Image.new('RGBA',(32,10));d=ImageDraw.Draw(im);text(d,(13,0),str(n),P['gold'] if active else P['light'])
  if active:d.polygon([(2,3),(7,5),(2,7)],fill=P['gold']);d.polygon([(29,3),(24,5),(29,7)],fill=P['gold'])
  save(im,'sc_register_'+str(n)+('_active'if active else ''))
for pressed in (False,True):
 im,d=plate(96,20);d.rectangle((3,4,5,15),fill=P['gold'] if pressed else P['light']);d.rectangle((90,4,92,15),fill=P['gold']);save(im,'sc_menu_button'+('_pressed' if pressed else ''))
im,d=plate(280,200)
for x in range(4,276,8):d.rectangle((x,193,x+3,195),fill=P['gold'])
for x in range(4,276,24):d.rectangle((x,5,x+10,13),fill=P['panel']);d.rectangle((x+2,7,x+4,9),fill=P['edge'])
save(im,'sc_setup_background');save(im,'sc_menu_background')
for i in range(1,4):
 im,d=plate(96,52)
 for z in range(7):
  for x in range(11):
   xx,yy=5+x*8,4+z*6;d.rectangle((xx,yy,xx+6,yy+4),fill=P['panel'])
   if (x+z*i)%7==0:d.line((xx,yy,xx+6,yy),fill=P['gold'])
   if (x+i*z)%11==0:d.rectangle((xx+1,yy+1,xx+5,yy+3),fill=P['light'])
 save(im,'sc_board_preview_'+str(i))
for kind,count,label in [('energy',9,'POWER'),('shield',3,'SHIELD'),('hull',5,'HULL'),('hand',12,'CARDS'),('jam',4,'JAM'),('route',3,'FLAGS')]:
 for value in range(count+1):
  im,d=plate(106,20);text(d,(4,0),label,P['red']if kind=='jam'else P['light'])
  width=min(15,92//count-2)
  for j in range(count):d.rectangle((5+j*(width+2),12,5+j*(width+2)+width,16),fill=(P['gold']if kind=='hand'else P['light'])if j<value else P['panel'])
  save(im,'sc_stat_'+kind+'_'+str(value))
for bits in range(4):
 im,d=plate(106,20);text(d,(4,0),'EQUIPMENT')
 text(d,(4,9),'BLINK',P['light']if bits&1 else P['edge']);text(d,(57,9),'RANGE',P['gold']if bits&2 else P['edge']);save(im,'sc_stat_modules_'+str(bits))
im,d=plate(120,154);save(im,'sc_hud_stats');im,d=plate(400,48);save(im,'sc_hud_controls')
im,d=plate(32,32);d.rectangle((8,5,23,12),fill=P['gold']);d.line((15,12,15,25),fill=P['light'],width=3);save(im,'sc_editor_brush')
im=Image.new('RGBA',(16,16),(154,207,197,180));im.save(T/'sc_ghost.png')
im=Image.new('RGBA',(32,32));d=ImageDraw.Draw(im)
for x in range(0,32,8):d.polygon([(x,0),(x+4,0),(x+8,4),(x+4,4)],fill=P['gold'])
d.line((0,5,31,5),fill='#17232f');save(im,'sc_edge_warning',1)
# Closed downward square cone, explicit normals and editable UVs.
vertices=[(-3,-3,10),(3,-3,10),(3,3,10),(-3,3,10),(0,0,0)]
faces=[(1,2,5),(2,3,5),(3,4,5),(4,1,5),(4,3,2),(4,2,1)]
lines=['# Ghost location pointer; UV mapped sc_ghost.png','mtllib sc_ghost_cone.mtl','usemtl ghost']+['v %s %s %s'%v for v in vertices]+['vt 0 0','vt 1 0','vt .5 1']
for face in faces:
 a,b,c=[vertices[j-1]for j in face];u=[b[j]-a[j]for j in range(3)];v=[c[j]-a[j]for j in range(3)];n=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]];length=math.sqrt(sum(q*q for q in n));lines.append('vn '+' '.join(str(q/length)for q in n))
for i,f in enumerate(faces):lines.append('f '+' '.join(f'{v}/{j+1}/{i+1}'for j,v in enumerate(f)))
(M/'sc_ghost_cone.obj').write_text('\n'.join(lines)+'\n')
print('Exported editable 1x pixel sources and nearest-neighbor runtime textures')

(M/'sc_ghost_cone.mtl').write_text('newmtl ghost\nKd 1 1 1\nmap_Kd ../textures/sc_ghost.png\n')

# Launch pad: chunky mechanical corners and an unambiguous forward chevron.
im=Image.new('RGBA',(32,32));d=ImageDraw.Draw(im)
for x,y,xx,yy in [(2,2,9,4),(2,2,4,9),(22,2,29,4),(27,2,29,9),(2,27,9,29),(2,22,4,29),(22,27,29,29),(27,22,29,29)]:d.rectangle((x,y,xx,yy),fill=P['light'])
d.polygon([(16,7),(24,17),(19,17),(19,24),(12,24),(12,17),(7,17)],fill=P['gold'])
d.line((12,26,19,26),fill=P['edge'],width=2)
save(im,'sc_start_marker',1)
for number in range(10):
 im=Image.new('RGBA',(32,32),'#173e43');d=ImageDraw.Draw(im);d.rectangle((1,1,30,30),outline=P['light'],width=2);d.rectangle((4,4,27,27),outline='#32676b')
 glyph=Image.new('RGBA',(8,11));gd=ImageDraw.Draw(glyph);text(gd,(1,0),'?' if number==0 else str(number),P['gold']);glyph=glyph.resize((16,22),Image.Resampling.NEAREST);im.alpha_composite(glyph,(8,5));save(im,'sc_tile_dock'+str(number),1)
 badge=im.resize((48,48),Image.Resampling.NEAREST);badge.save(T/('sc_checkpoint_'+str(number)+'.png'))
im,d=plate(106,20);text(d,(4,0),'FLAGS');text(d,(4,10),'NONE IN THIS SCENE');save(im,'sc_stat_route_0_0')
for count in range(1,10):
 for value in range(count+1):
  im,d=plate(106,20);text(d,(4,0),'FLAGS');width=min(15,92//count-2)
  for j in range(count):d.rectangle((5+j*(width+2),12,5+j*(width+2)+width,16),fill=P['gold']if j<value else P['panel'])
  save(im,'sc_stat_route_'+str(count)+'_'+str(value))
im=Image.new('RGBA',(32,32),'#183e39');d=ImageDraw.Draw(im);d.rectangle((1,1,30,30),outline=P['light'],width=2);d.rectangle((12,7,19,24),fill='#a5efb3');d.rectangle((7,12,24,19),fill='#a5efb3');save(im,'sc_tile_repair',1)
im=Image.new('RGBA',(8,8));d=ImageDraw.Draw(im);d.rectangle((3,1,4,6),fill='#a5efb3');d.rectangle((1,3,6,4),fill='#a5efb3');save(im,'sc_fx_repair',1)

Image.new('RGB',(16,16),'#24333f').save(T/'sc_apron.png')

# Dedicated goal dock and personal world-space target marker.
def goal(name,headline,detail):
 im,d=plate(128,52);text(d,(7,3),'NEXT GOAL',P['gold']);d.line((7,15,120,15),fill=P['edge']);text(d,(7,20),headline);text(d,(7,35),detail,P['gold']);save(im,'sc_goal_'+name)
for count in range(1,10):
 for n in range(1,count+1):goal('flag_'+str(n)+'_'+str(count),'CHECKPOINT '+str(n)+' / '+str(count),'REACH THE MARKER')
for item in ['cell','blink','range','repair','shield','cache','jammer']:goal('collect_'+item,'COLLECT '+item.upper(),'THEN FINISH ROUTE')
for name,title,detail in [('start','START A GAME','OPEN THE MAIN MENU'),('reboot','REBOOT PENDING','AFTER THIS ROUND'),('complete','ROUTE COMPLETE','OPEN THE RESULTS'),('observe','WATCH THE RACE','FOLLOW THE ROBOTS'),('editor','BUILD YOUR FACTORY','RIGHT CLICK: TOOLS')]:goal(name,title,detail)
im=Image.new('RGBA',(16,20));d=ImageDraw.Draw(im);d.rectangle((2,1,13,13),outline=P['gold'],width=2);d.line((7,4,7,11),fill=P['light']);d.polygon([(8,4),(12,4),(10,7),(8,7)],fill=P['light']);d.polygon([(4,16),(11,16),(8,19)],fill=P['gold']);save(im,'sc_goal_marker')

for name,label,color in [('electroshield','ESHLD','#7bd2f0'),('titanium_hull','TITAN',P['light']),('none','EMPTY',P['edge']),('green_laser','LASER',P['light']),('double_laser','DOUBLE',P['gold']),('remote_control','REMOTE','#b9a3f0'),('tractor_beam','PULL','#7bd2f0'),('repulsor_beam','PUSH','#ef9f63'),('mechanical_arm','ARM',P['gold']),('turret_gearbox','AIM',P['light']),('hard_disk','DISK',P['gold']),('holographic_memory','HOLO','#b9a3f0'),('gyro_stabilizer','GYRO',P['light'])]:
 im,d=plate(32,32)
 if name=='double_laser':d.rectangle((8,6,12,19),fill=color);d.rectangle((19,6,23,19),fill=color)
 elif name in ['tractor_beam','repulsor_beam']:d.polygon([(6,7),(12,13),(6,19)],outline=color);d.polygon([(25,7),(19,13),(25,19)],outline=color)
 elif name=='remote_control':d.rectangle((8,6,23,19),outline=color,width=2);d.line((11,16,16,10,21,16),fill=color,width=2)
 elif name=='mechanical_arm':d.line((8,19,8,7,20,7,20,16),fill=color,width=3);d.line((16,18,20,15,24,18),fill=color,width=2)
 elif name=='hard_disk':d.rectangle((8,5,23,20),outline=color,width=2);d.rectangle((11,6,19,11),fill=color)
 elif name=='holographic_memory':d.polygon([(16,4),(25,12),(16,21),(7,12)],outline=color,width=2)
 else:d.rectangle((9,6,22,19),outline=color,width=2);d.rectangle((13,10,18,15),fill=color)
 text(d,((32-len(label)*6)//2,22),label,color);save(im,'sc_part_'+name)
im=Image.new('RGBA',(32,32));d=ImageDraw.Draw(im);d.rectangle((22,2,29,10),fill=P['gold']);d.rectangle((24,3,27,6),fill=P['dark']);save(im,'sc_kept')
im=Image.new('RGBA',(32,32));d=ImageDraw.Draw(im);d.rectangle((1,1,30,30),outline='#b9a3f0',width=2);save(im,'sc_remote_overlay')

im=Image.new('RGBA',(8,8));d=ImageDraw.Draw(im);d.polygon([(1,1),(6,2),(4,7)],fill='#b7cbd2');save(im,'sc_fx_metal',1)

