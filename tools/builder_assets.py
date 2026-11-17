from pathlib import Path
from PIL import Image,ImageDraw
r=Path(__file__).resolve().parents[1];src=r/'art/ui';dest=r/'mods/shift_circuit/textures'
def save(name,im):
 p=src/(name+'.png')
 if not p.exists(): im.save(p)
 im=Image.open(p);im.resize((im.width*(1 if name.startswith('sc_map_')else 2),im.height*(1 if name.startswith('sc_map_')else 2)),Image.Resampling.NEAREST).save(dest/p.name)
for size in range(4):
 w=max(1,size)*16;im=Image.new('RGBA',(w,w),'#102934');d=ImageDraw.Draw(im)
 for x in range(0,w,16):
  for y in range(0,w,16):
   d.rectangle((x,y,x+15,y+15),outline='#395765');d.rectangle((x+2,y+2,x+13,y+13),outline='#73a69e'if size else '#243f4b')
 if size:d.rectangle((0,0,w-1,w-1),outline=['','#8bcec1','#ddbd76','#8bacdd'][size],width=2)
 save('sc_build_piece_'+str(size) if size else 'sc_build_empty',im)
im=Image.new('RGBA',(32,32),'#102934');d=ImageDraw.Draw(im);d.arc((5,5,26,26),30,310,fill='#efc56e',width=3);d.polygon([(24,2),(29,10),(20,10)],fill='#efc56e');save('sc_editor_rotate',im)

# Eight-pixel map symbols: composable over the floor, including layered machinery.
for size in (10,20,30):
 im=Image.new('RGBA',(size*8,size*8),'#203844');d=ImageDraw.Draw(im)
 for n in range(size):d.line((n*8,0,n*8,size*8),fill='#142c36');d.line((0,n*8,size*8,n*8),fill='#142c36')
 save('sc_map_base_'+str(size),im)
for kind in ('pit','repair','checkpoint','start','crusher','spawner','rotator_1','rotator_3'):
 im=Image.new('RGBA',(8,8));d=ImageDraw.Draw(im)
 if kind=='pit':d.rectangle((0,0,7,7),fill='#000000')
 elif kind=='repair':d.rectangle((3,1,4,6),fill='#9ce2bd');d.rectangle((1,3,6,4),fill='#9ce2bd')
 elif kind=='checkpoint':d.line((2,1,2,6),fill='#eee7b6');d.rectangle((3,1,6,3),fill='#edc56e')
 elif kind=='start':d.rectangle((1,1,6,6),outline='#86e1cc');d.rectangle((3,3,4,4),fill='#86e1cc')
 elif kind=='crusher':d.line((0,1,0,0,7,0,7,1),fill='#ed9d76');d.rectangle((2,0,5,2),fill='#ed9d76')
 elif kind=='spawner':d.polygon([(4,2),(6,4),(4,6),(2,4)],fill='#b89ced');d.point((4,1),fill='#eee7b6')
 else:
  d.arc((1,1,6,6),30,310,fill='#edc56e');d.polygon([(5,0),(7,2),(4,2)],fill='#edc56e')
  if kind=='rotator_3':im=im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
 save('sc_map_'+kind,im)
for kind in ('belt','bend_left','bend_right','laser','pusher'):
 for speed in ((1,2)if kind.startswith(('belt','bend'))else (1,)):
  im=Image.new('RGBA',(8,8));d=ImageDraw.Draw(im);c='#edc56e'if speed==2 else '#86e1cc'
  if kind=='belt':d.line((3,1,3,5),fill=c,width=2);d.polygon([(1,4),(6,4),(4,7)],fill=c)
  elif kind.startswith('bend'):
   d.line((0,2,4,2,4,5),fill=c,width=2);d.polygon([(2,4),(6,4),(4,7)],fill=c)
   if kind=='bend_right':im=im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
  elif kind=='laser':d.rectangle((2,1,5,3),fill='#f08d78');d.line((3,4,3,7),fill='#f08d78')
  else:d.rectangle((1,1,6,2),fill='#edc56e');d.line((3,3,3,6),fill='#edc56e');d.line((1,6,6,6),fill='#edc56e')
  for direction in range(4):
   rotated=im.rotate(direction*90,resample=Image.Resampling.NEAREST)
   save('sc_map_'+kind+('_'+str(speed)if kind.startswith(('belt','bend'))else '')+'_'+str(direction),rotated)
save('sc_map_wall_h',Image.new('RGBA',(8,1),'#edc56e'));save('sc_map_wall_v',Image.new('RGBA',(1,8),'#edc56e'))

# Square workshop buttons share the map symbol vocabulary without stretching.
icons=['floor','pit','belt_1_0','belt_2_0','bend_left_1_0','bend_right_1_0','bend_left_2_0','bend_right_2_0','rotator_3','rotator_1','checkpoint','repair','wall_h','crusher','laser_0','laser_0','laser_0','pusher_0','pusher_0','start','erase','spawner']
for i,kind in enumerate(icons,1):
 im=Image.new('RGBA',(40,40),'#16333f');d=ImageDraw.Draw(im);d.rectangle((0,0,39,39),outline='#527887',width=2)
 if kind=='floor':symbol=Image.open(src/'sc_map_base_10.png').crop((0,0,8,8))
 elif kind=='erase':
  symbol=Image.new('RGBA',(8,8));sd=ImageDraw.Draw(symbol);sd.line((1,1,6,6),fill='#efc56e',width=2);sd.line((1,6,6,1),fill='#efc56e',width=2)
 elif kind=='wall_h':
  symbol=Image.new('RGBA',(8,8));sd=ImageDraw.Draw(symbol);sd.rectangle((1,2,6,6),fill='#527887');sd.line((1,2,6,2),fill='#efc56e')
 else:symbol=Image.open(src/('sc_map_'+kind+'.png')).convert('RGBA')
 im.alpha_composite(symbol.resize((24,24),Image.Resampling.NEAREST),(8,8))
 if i in (16,17):
  for dot in range(i-14):d.rectangle((9+dot*8,34,12+dot*8,36),fill='#efc56e')
 name='sc_editor_'+str(i);path=src/(name+'.png')
 if path.exists()and Image.open(path).size!=(40,40):im.save(path)
 save(name,im)
