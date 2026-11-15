"""Second-pass original art: material-aware geometry and quiet industrial surfaces."""
from pathlib import Path
from PIL import Image, ImageDraw
R=Path(__file__).resolve().parents[1]; T=R/'mods/shift_circuit/textures'; M=R/'mods/shift_circuit/models'
colors=['#23303b','#405768','#a2c1c9','#e6b95c','#47cfbd','#101c29','#ecf8ed','#b75843']
atlas=Image.new('RGB',(128,16)); d=ImageDraw.Draw(atlas)
for i,c in enumerate(colors):
    d.rectangle((i*16,0,i*16+15,15),fill=c)
    d.line((i*16,0,i*16+15,0),fill=tuple(min(255,v+20) for v in tuple(bytes.fromhex(c[1:]))))
    if i in [0,1,2]:
        d.line((i*16+2,13,i*16+13,13),fill=tuple(max(0,v-13) for v in tuple(bytes.fromhex(c[1:]))))
atlas.save(T/'sc_materials.png')
def mesh(name,boxes):
    # Emit only union boundary faces. Shared/intersecting cuboid surfaces cannot
    # z-fight, even when several colored parts occupy the same plane.
    axes=[sorted({b[j] for b in boxes}|{b[j+3] for b in boxes}) for j in range(3)]
    xs,ys,zs=axes; cells={}
    for i in range(len(xs)-1):
        for j in range(len(ys)-1):
            for k in range(len(zs)-1):
                center=((xs[i]+xs[i+1])/2,(ys[j]+ys[j+1])/2,(zs[k]+zs[k+1])/2)
                for b in boxes:
                    if all(b[n]<center[n]<b[n+3] for n in range(3)):cells[i,j,k]=b[6]
    lines=['# Union surface; engine X precompensated for Luanti OBJ import.'];n=0
    for (i,j,k),c in cells.items():
        x,y,z=xs[i],ys[j],zs[k];X,Y,Z=xs[i+1],ys[j+1],zs[k+1]
        sides=[((-1,0,0),[(x,y,z),(x,y,Z),(x,Y,Z),(x,Y,z)]),((1,0,0),[(X,y,Z),(X,y,z),(X,Y,z),(X,Y,Z)]),((0,-1,0),[(x,y,z),(X,y,z),(X,y,Z),(x,y,Z)]),((0,1,0),[(x,Y,Z),(X,Y,Z),(X,Y,z),(x,Y,z)]),((0,0,-1),[(x,Y,z),(X,Y,z),(X,y,z),(x,y,z)]),((0,0,1),[(x,y,Z),(X,y,Z),(X,Y,Z),(x,Y,Z)])]
        for delta,verts in sides:
            if (i+delta[0],j+delta[1],k+delta[2]) in cells:continue
            lines += [f'v {-v[0]*10:g} {v[1]*10:g} {v[2]*10:g}' for v in verts]
            u0,u1=(c*16+.5)/128,(c*16+15.5)/128
            lines += [f'vt {u0} .03',f'vt {u1} .03',f'vt {u1} .97',f'vt {u0} .97']
            for face in [(3,2,1),(4,3,1)]:lines.append('f '+' '.join(f'{n+a}/{n+a}' for a in face))
            n+=4
    (M/name).write_text('\n'.join(lines)+'\n')
robot=[(-.5,-.5,-.5,-.25,-.1875,.5,0),(.25,-.5,-.5,.5,-.1875,.5,0),(-.375,-.25,-.375,.375,.375,.375,3),(-.3125,.375,-.25,.3125,.8125,.3125,2),(-.25,.5,.3125,.25,.6875,.375,5),(-.1875,.5625,.375,-.0625,.625,.40625,4),(.0625,.5625,.375,.1875,.625,.40625,4),(-.4375,-.0625,.375,.4375,.0625,.4375,1),(-.625,0,-.1875,-.375,.25,.1875,1),(.375,0,-.1875,.625,.25,.1875,1),(.125,.8125,-.125,.1875,1.0625,-.0625,0),(.0625,1.0625,-.1875,.25,1.1875,0,4)]
for x in [-.52,.27]:
    for z in [-.375,-.125,.125,.375]: robot.append((x,-.4375,z,x+.25,-.25,z+.0625,1))
robot += [(-.125,.0625,.375,.125,.1875,.5,0)]
mesh('sc_robot.obj',robot)
frame=[]
for x in [-.9375,.75]:
    frame += [(x,-.5,-.75,x+.1875,2.125,-.5,1),(x-.0625,-.5,-.8125,x+.25,-.25,-.4375,3),(x+.03125,-.125,-.78125,x+.15625,1.875,-.75,2)]
frame += [(-1,1.875,-.875,1,2.25,.75,1),(-.875,1.9375,.75,.875,2.1875,.8125,3),(-.375,2.25,-.3125,.375,2.5625,.1875,0),(-.625,2.25,-.3125,-.4375,2.4375,0,4)]
mesh('sc_press_frame.obj',frame)
mesh('sc_ram.obj',[(-.75,-.25,-.6875,.75,.125,.6875,1),(-.8125,-.3125,-.75,.8125,-.1875,.75,3),(-.625,.125,-.5625,-.4375,.625,-.375,0),(.4375,.125,-.5625,.625,.625,-.375,0)])
mesh('sc_piston.obj',[(-.125,0,-.125,.125,1,.125,2)])
rails=[(-.9375,-.5,-1,-.75,-.3125,1,1),(.75,-.5,-1,.9375,-.3125,1,1)]
for z in [-.75,-.25,.25,.75]: rails += [(-.9375,-.3125,z,-.75,-.25,z+.125,2),(.75,-.3125,z,.9375,-.25,z+.125,2)]
mesh('sc_belt_rails.obj',rails)
mesh('sc_station_ring.obj',[(-.9375,-.5,-.9375,-.8125,-.375,.9375,4),(.8125,-.5,-.9375,.9375,-.375,.9375,4),(-.8125,-.5,-.9375,.8125,-.375,-.8125,4),(-.8125,-.5,.8125,.8125,-.375,.9375,4)])
# A two-node tile has one broad panel, not four competing mini-panels.
def split(im,name):
    for z in range(2):
        for x in range(2): im.crop((x*16,z*16,x*16+16,z*16+16)).save(T/f'sc_{name}{x}{z}.png')
floor=Image.new('RGB',(32,32),'#344754'); d=ImageDraw.Draw(floor)
d.rectangle((0,0,31,31),outline='#172934'); d.line((1,1,30,1),fill='#536977')
for x,y in [(3,3),(28,3),(3,28),(28,28)]: d.rectangle((x,y,x+1,y+1),fill='#71818a')
d.line((10,28,21,28),fill='#40535f'); split(floor,'deck');floor.save(T/'sc_tile_deck.png')
for n in range(1,4):
    im=Image.new('RGB',(32,32),'#24595c'); d=ImageDraw.Draw(im)
    d.rectangle((1,1,30,30),outline='#4fcbbc',width=2);d.rectangle((5,5,26,26),outline='#347779')
    rows={1:['010','110','010','010','111'],2:['110','001','010','100','111'],3:['110','001','010','001','110']}[n]
    for y,row in enumerate(rows):
        for x,v in enumerate(row):
            if v=='1':d.rectangle((12+x*3,9+y*3,14+x*3,11+y*3),fill='#e8f1cd')
    split(im,'dock'+str(n));im.save(T/f'sc_tile_dock{n}.png')
for name,c in [('apron','#24333f'),('beam','#1b2933'),('light','#8ae9d2'),('pit','#141e2a')]:
    im=Image.new('RGB',(16,16),c);d=ImageDraw.Draw(im)
    if name=='apron':
        for y in range(2,16,4):d.line((2,y,13,y),fill='#314451')
    if name=='beam':d.rectangle((0,0,15,15),outline='#344754')
    im.save(T/f'sc_{name}.png')
im=Image.new('RGB',(64,32),'#213b49');d=ImageDraw.Draw(im);d.line((0,0,63,0),fill='#496876');d.line((0,31,63,31),fill='#142b36');im.save(T/'sc_button.png')
# Purpose-drawn monochrome glyphs for the controller.
for name in ['STEP','DASH','BACK','LEFT','RIGHT','WAIT']:
    im=Image.new('RGBA',(32,32));d=ImageDraw.Draw(im);c='#a7e8da'
    if name in ['STEP','DASH','BACK']:
        d.polygon([(16,4),(5,15),(11,15),(11,27),(21,27),(21,15),(27,15)],fill=c)
        if name=='DASH':d.line((8,3,16,0,24,3),fill='#efbd6d',width=3)
        if name=='BACK':im=im.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
    elif name=='WAIT':d.rectangle((7,6,12,26),fill=c);d.rectangle((20,6,25,26),fill=c)
    else:
        d.line((24,26,24,12,10,12),fill=c,width=6);d.polygon([(3,12),(14,3),(14,21)],fill=c)
        if name=='RIGHT':im=im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    im.save(T/f'sc_cmd_{name}.png')
print('Refined models, deck panels, service pads, and controller glyphs.')
mesh('sc_edge_wall.obj',[(-1,-.5,-.0625,1,1.25,.0625,1),(-1,1.25,-.0625,1,1.375,.0625,3),(-1,-.5,-.125,-.875,1.375,.125,2),(.875,-.5,-.125,1,1.375,.125,2)])
mesh('sc_pickup.obj',[(-.25,-.25,-.25,.25,.25,.25,4),(-.3125,-.3125,-.3125,.3125,-.1875,.3125,2),(-.3125,.1875,-.3125,.3125,.3125,.3125,2)])
for dx in range(2):
    for dz in range(2):
        sheet=Image.new('RGB',(16,128))
        for f in range(8):
            im=Image.new('RGB',(32,32),'#18383e');d=ImageDraw.Draw(im)
            for y in range(32):
                if (y+f*2)%8<2:d.line((3,y,28,y),fill='#345f63')
            d.rectangle((0,0,2,31),fill='#73848b');d.rectangle((29,0,31,31),fill='#73848b')
            d.polygon([(16,6),(8,15),(13,15),(13,25),(19,25),(19,15),(24,15)],fill='#81c7b7')
            sheet.paste(im.crop((dx*16,dz*16,dx*16+16,dz*16+16)),(0,f*16))
        sheet.save(T/f'sc_transfer{dx}{dz}.png')
for name in ['STEP','DASH','BACK','LEFT','RIGHT','WAIT','PULSE','BLINK']:
    if not (T/f'sc_cmd_{name}.png').exists():
        im=Image.new('RGBA',(32,32));d=ImageDraw.Draw(im)
        if name=='PULSE': d.ellipse((5,5,27,27),outline='#f7bc70',width=3);d.line((16,0,16,32),fill='#f7bc70',width=2);d.line((0,16,32,16),fill='#f7bc70',width=2)
        else:d.polygon([(17,1),(5,18),(14,18),(12,31),(28,12),(19,12)],fill='#b9a0ef')
        im.save(T/f'sc_cmd_{name}.png')
    card=Image.new('RGBA',(64,64),'#19333fff');d=ImageDraw.Draw(card)
    d.rectangle((0,0,63,63),outline='#45616d',width=2);d.line((4,3,59,3),fill='#64c8b8',width=2)
    icon=Image.open(T/f'sc_cmd_{name}.png');card.alpha_composite(icon,(16,8))
    d.text((7,47),name,fill='#e8eee5');card.save(T/f'sc_card_{name}.png')
im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im);d.rectangle((1,1,62,62),outline='#f1c56d',width=3);im.save(T/'sc_hotbar_selected.png')
im=Image.new('RGBA',(768,72),'#0b1824dd');im.save(T/'sc_hotbar.png')
mesh('sc_slat.obj',[(-.75,-.4375,-.06,.75,-.3125,.06,1),(-.625,-.3125,-.04,.625,-.28125,.04,2)])
mesh('sc_rotator.obj',[(-.8125,-.47,-.8125,.8125,-.3125,.8125,1),(-.375,-.3125,-.0625,.375,-.25,.0625,4),(-.625,-.3125,-.25,-.4375,-.25,.25,3),(.4375,-.3125,-.25,.625,-.25,.25,3)])
mesh('sc_pusher.obj',[(-.75,-.5,-.9,.75,-.34,-.58,1),(-.75,-.13,-.9,.75,-.02,-.58,3),(-.75,-.34,-.9,-.12,-.13,-.58,1),(.12,-.34,-.9,.75,-.13,-.58,1)])
mesh('sc_pushram.obj',[(-.625,-.44,-.53,.625,-.06,-.39,3),(-.55,-.38,-.39,.55,-.12,-.37,1)])
mesh('sc_pushrod.obj',[(-.065,-.065,0,.065,.065,1,2)])
for power in [1,2,3]:
    boxes=[(-.98,-.5,-.1,.98,.48,.08,1),(-.98,.48,-.12,.98,.61,.1,3)]
    for i in range(power):
        x=(i-(power-1)/2)*.375;boxes.extend([(x-.13,-.13,.08,x+.13,.13,.16,0),(x-.094,-.094,.16,x+.094,.094,.1875,7)])
    mesh(f'sc_laser{power}.obj',boxes)
mesh('sc_beam.obj',[(-.035,-.035,0,.035,.035,1,6)])
# Single mesh and one full UV map per playable square; physics nodes stay invisible.
(M/'sc_tile.obj').write_text('v 10 -5 -10\nv -10 -5 -10\nv -10 -5 10\nv 10 -5 10\nvt 0 0\nvt 1 0\nvt 1 1\nvt 0 1\nf 1/1 2/2 3/3\nf 1/1 3/3 4/4\n')

im=Image.new('RGBA',(64,64),'#142935e8');d=ImageDraw.Draw(im);d.rectangle((1,1,62,62),outline='#34515f',width=2);d.line((23,32,41,32),fill='#5c7a85',width=2);im.save(T/'sc_emptycard.png')
im=Image.new('RGBA',(512,256),'#091722c9');im.save(T/'sc_hud_panel.png')

# Translucent, flat-color beams: no opaque atlas pixels.
Image.new('RGBA',(16,16),(255,255,255,105)).save(T/'sc_beam_alpha.png')
mesh('sc_beam.obj',[(-.025,-.025,0,.025,.025,1,6)])
# Curved rails are ribbons parallel to a quadratic conveyor centerline.
import math
def curved_model(name,entry):
    # Local exit is +Z. Entry is +X (right turn in local space) or -X.
    lines=[];n=0
    for side in [-1,1]:
        for i in range(24):
            verts=[]
            for u,w in [(i/24,.80),((i+1)/24,.80),((i+1)/24,.94),(i/24,.94)]:
                a=u*math.pi/2;x=-entry*(1-math.sin(a));z=1-math.cos(a);dx=entry*math.cos(a);dz=math.sin(a);length=1
                x+=side*w*dz/length;z-=side*w*dx/length
                verts.append((x,-.30,z))
            lines += [f'v {-x*10:g} {y*10:g} {z*10:g}' for x,y,z in verts]
            lines += ['vt .13 .1','vt .24 .1','vt .24 .9','vt .13 .9']
            for f in [(3,2,1),(4,3,1)]:lines.append('f '+' '.join(f'{n+a}/{n+a}' for a in f))
            n+=4
    (M/name).write_text('\n'.join(lines)+'\n')
curved_model('sc_curve_right.obj',1);curved_model('sc_curve_left.obj',-1)
def curved_slat(name,sign):
    vertices=[]
    for y in [-.4375,-.3125]:
        for radius,angle in [(.25,-3),(1.75,-3),(1.75,3),(.25,3)]:
            a=math.radians(angle);vertices.append((sign*(radius*math.cos(a)-1),y,radius*math.sin(a)))
    lines=[f'v {-x*10:g} {y*10:g} {z*10:g}' for x,y,z in vertices]
    lines+=['vt .255 .03','vt .37 .03','vt .37 .97','vt .255 .97']
    for face in [(1,2,3,4),(8,7,6,5),(1,5,6,2),(2,6,7,3),(3,7,8,4),(4,8,5,1)]:
        f=face if sign<0 else tuple(reversed(face))
        for a,b,c in [(0,1,2),(0,2,3)]:lines.append(f'f {f[a]}/1 {f[b]}/2 {f[c]}/3')
    (M/name).write_text('\n'.join(lines)+'\n')
curved_slat('sc_slat_curve_right.obj',1);curved_slat('sc_slat_curve_left.obj',-1)

# Floor-supported gantry: feet are on the deck; only the working head is overhead.
frame=[]
for x in [-.97,.79]:
    for z in [-.94,.76]:
        frame.extend([(x,-.5,z,x+.18,4.0,z+.18,1),(x-.025,-.5,z-.025,x+.205,-.28,z+.205,3),(x+.055,-.25,z+.055,x+.125,3.8,z+.125,2)])
frame += [(-1,3.875,-.96,1,4.25,.96,1),(-.88,3.94,.96,.88,4.17,.99,3),(-.38,4.25,-.32,.38,4.56,.32,0)]
mesh('sc_press_frame.obj',frame)
# Collectibles have distinct silhouettes as well as accent colors.
mesh('sc_pickup_cell.obj',[(-.25,-.35,-.2,.25,.3,.2,4),(-.13,.3,-.1,.13,.43,.1,2),(-.29,-.35,-.24,.29,-.24,.24,1),(-.08,-.15,.2,.08,.15,.24,6)])
mesh('sc_pickup_shield.obj',[(-.37,-.12,-.12,.37,.32,.12,2),(-.28,-.29,-.12,.28,-.12,.12,2),(-.13,-.43,-.12,.13,-.29,.12,2),(-.25,-.08,.12,.25,.23,.18,4),(-.12,-.22,.12,.12,-.08,.18,4)])
mesh('sc_pickup_cache.obj',[(-.38,-.3,-.25,.38,-.16,.25,3),(-.31,-.1,-.25,.31,.04,.25,2),(-.24,.1,-.25,.24,.24,.25,4),(-.17,.3,-.25,.17,.44,.25,2)])
mesh('sc_pickup_blink.obj',[(-.42,-.35,-.1,-.26,.35,.1,4),(.26,-.35,-.1,.42,.35,.1,4),(-.26,.26,-.1,.26,.42,.1,2),(-.26,-.42,-.1,.26,-.26,.1,2),(-.09,-.09,-.09,.09,.09,.09,6)])
mesh('sc_pickup_range.obj',[(-.12,-.3,-.4,.12,-.12,.36,1),(-.28,-.12,-.34,.28,.16,.22,2),(-.16,-.04,.22,.16,.09,.46,3),(-.06,.16,-.23,.06,.3,.08,4)])
mesh('sc_pickup_repair.obj',[(-.32,-.26,-.22,.32,.26,.22,1),(-.23,.26,-.08,-.13,.39,.08,2),(.13,.26,-.08,.23,.39,.08,2),(-.23,.36,-.08,.23,.43,.08,2),(-.07,-.18,.22,.07,.18,.26,4),(-.2,-.06,.22,.2,.06,.26,4)])
mesh('sc_pickup_jammer.obj',[(-.25,-.25,-.25,.25,.25,.25,7),(-.08,.25,-.08,.08,.45,.08,0),(-.08,-.45,-.08,.08,-.25,.08,0),(-.45,-.08,-.08,-.25,.08,.08,0),(.25,-.08,-.08,.45,.08,.08,0),(-.08,-.08,.25,.08,.08,.45,0),(-.08,-.08,-.45,.08,.08,-.25,0)])

def polygons(name,faces,color=2):
    lines=[];n=0
    for item in faces:
        verts,c=item[:2] if isinstance(item,tuple) and isinstance(item[1],int) else (item,color)
        down=isinstance(item,tuple) and len(item)==3 and item[2]
        if all(abs(v[1]-verts[0][1])<1e-8 for v in verts):
            ax,az=verts[1][0]-verts[0][0],verts[1][2]-verts[0][2];bx,bz=verts[2][0]-verts[0][0],verts[2][2]-verts[0][2]
            if (az*bx-ax*bz<0) != bool(down):verts=list(reversed(verts))
        lines += [f'v {-x*10:.6f} {y*10:.6f} {z*10:.6f}' for x,y,z in verts]
        # Full swatch UV area, never a single sampled pixel.
        uv=[(0,0),(1,0),(1,1),(0,1)] if len(verts)==4 else [(0,0),(1,0),(.5,1)]
        lines += [f'vt {(c*16+.5+u*15)/128} {.03+v*.94}' for u,v in uv]
        for i in range(1,len(verts)-1):lines.append(f'f {n+1}/{n+1} {n+i+2}/{n+i+2} {n+i+1}/{n+i+1}')
        n+=len(verts)
    (M/name).write_text('\n'.join(lines)+'\n')


def sector(sign,a,b,r0=.25,r1=1.75,y=-.30):
    return [(sign*(-1+r*math.sin(t)),y,1-r*math.cos(t)) for r,t in [(r0,a),(r1,a),(r1,b),(r0,b)]]
# One contiguous animated tread per corner, clipped exactly at entry and exit.
# Baked coordinates eliminate the mismatched moving wedge/pivot combination.
for sign,kind in [(1,'right'),(-1,'left')]:
    for f in range(24):
        faces=[]
        for i in range(-1,11):
            a=max(0,(i+f/24)*math.pi/20);b=min(math.pi/2,(i+f/24+.72)*math.pi/20)
            if b>a:
                top=sector(sign,a,b,y=-.3125);bottom=sector(sign,a,b,y=-.4375)
                faces.append((top,1));faces.append((bottom,1,True))
                for j in range(4):
                    k=(j+1)%4;side=[bottom[j],bottom[k],top[k],top[j]]
                    center=tuple(sum(v[k] for v in top)/4 for k in range(3))
                    u=[side[1][k]-side[0][k] for k in range(3)];v=[side[2][k]-side[0][k] for k in range(3)]
                    normal=(u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0])
                    if sum(normal[k]*(sum(w[k] for w in side)/4-center[k]) for k in (0,2))<0:side.reverse()
                    faces.append((side,1))
                if b-a>.02:faces.append((sector(sign,a+.01,b-.01,.375,1.625,-.28125),2))
        polygons(f'sc_tread_curve_{kind}_{f}.obj',faces)
    # Smooth narrow arc with a tangent-aligned triangular head; no disconnected elbow.
    faces=[sector(sign,i*math.pi/80,(i+1)*math.pi/80,.91,1.09,-.19) for i in range(7,32)]
    a=32*math.pi/80;cx=sign*(-1+math.sin(a));cz=1-math.cos(a)
    dx=sign*math.cos(a);dz=math.sin(a);nx=dz;nz=-dx
    faces.append([(cx+nx*.25,-.19,cz+nz*.25),(cx+dx*.38,-.19,cz+dz*.38),(cx-nx*.25,-.19,cz-nz*.25)])
    polygons(f'sc_arrow_curve_{kind}.obj',faces,3)
# Raised arrow geometry points toward local +Z, independent of image UV flips.
arrow=[(-.12,-.19,-.60),(.12,-.19,-.60),(.12,-.19,.13),(.42,-.19,.13),(0,-.19,.65),(-.42,-.19,.13),(-.12,-.19,.13)]
# Concave silhouette explicitly triangulated as shaft plus triangle.
faces=[[arrow[0],arrow[1],arrow[2],arrow[6]],[arrow[3],arrow[4],arrow[5]]]
polygons('sc_arrow_forward.obj',faces,4)
polygons('sc_arrow_double.obj',faces+[[(-.32,-.19,-.64),(0,-.19,-.32),(.32,-.19,-.64)]],3)

# Curved rails share the straight rail section and pale regularly spaced fittings.
for sign,kind in [(1,'right'),(-1,'left')]:
    faces=[]
    for r0,r1 in [(.0625,.25),(1.75,1.9375)]:
        for i in range(24):
            a=i*math.pi/48;b=(i+1)*math.pi/48
            top=sector(sign,a,b,r0,r1,-.3125);bottom=sector(sign,a,b,r0,r1,-.5)
            faces.append((top,1));faces.append((bottom,1,True))
            for j in ([1,3]+([0] if i==0 else [])+([2] if i==23 else [])):
                k=(j+1)%4;side=[bottom[j],bottom[k],top[k],top[j]]
                center=tuple(sum(v[k] for v in top)/4 for k in range(3))
                u=[side[1][k]-side[0][k] for k in range(3)];v=[side[2][k]-side[0][k] for k in range(3)]
                normal=(u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0])
                if sum(normal[k]*(sum(w[k] for w in side)/4-center[k]) for k in (0,2))<0:side.reverse()
                faces.append((side,1))
        for i in range(6):
            a=(i+.2)*math.pi/12;b=(i+.65)*math.pi/12
            faces.append((sector(sign,a,b,r0,r1,-.25),2))
    polygons(f'sc_curve_{kind}.obj',faces)

# Hunter: broad armored shoulders, four outriggers, low red sensor visor and forward cannon.
hunter=[(-.42,-.22,-.38,.42,.34,.34,1),(-.3,.34,-.22,.3,.63,.25,0),(-.28,.42,.25,.28,.53,.29,7),(-.14,.05,.34,.14,.23,.5,0),(-.1,.09,.5,.1,.19,.53,7),(-.56,.03,-.3,-.36,.39,.3,3),(.36,.03,-.3,.56,.39,.3,3),(-.12,.63,-.12,.12,.79,.12,7)]
for x in [-.65,.4]:
 for z in [-.5,.28]:hunter.extend([(x,-.5,z,x+.25,-.22,z+.24,0),(x,-.25,z+.03,x+.25,-.17,z+.21,2)])
mesh('sc_hunter.obj',hunter)

# Modular head systems: all retain independent editable texture atlases.
modules={
 'thermal_camera':[(-.18,0,-.16,.18,.07,.16,1),(-.12,.07,-.1,.12,.13,.1,3),(-.21,.13,-.12,.21,.29,.15,1),(-.16,.17,.15,-.04,.25,.22,7),(.04,.17,.15,.16,.25,.22,4)],
 'blueprint_archive':[(-.2,0,-.18,.2,.06,.18,1),(-.16,.06,-.14,.16,.3,.14,4),(-.12,.1,-.151,.12,.26,-.14,2),(-.09,.14,-.16,.09,.22,-.15,5),(-.22,.3,-.18,.22,.35,.18,3)],
 'green_laser':[(-.16,0,-.18,.16,.12,.16,1),(-.07,.04,.1,.07,.16,.5,0),(-.06,.06,.49,.06,.14,.53,4)],
 'double_laser':[(-.22,0,-.18,.22,.14,.18,1),(-.2475,.06,.12,-.1275,.18,.5,0),(.1275,.06,.12,.2475,.18,.5,0),(-.2375,.08,.49,-.1375,.16,.53,4),(.1375,.08,.49,.2375,.16,.53,4)],
 'remote_control':[(-.17,0,-.18,.17,.15,.12,7),(-.21,.06,.12,-.13,.24,.4,2),(.13,.06,.12,.21,.24,.4,2),(-.06,.09,.1,.06,.23,.3,6)],
 'tractor_beam':[(-.18,0,-.18,.18,.14,.1,1),(-.23,.02,.08,-.12,.22,.42,4),(.12,.02,.08,.23,.22,.42,4),(-.12,.02,.05,.12,.22,.14,2)],
 'repulsor_beam':[(-.16,0,-.18,.16,.14,.16,1),(-.25,.02,.18,.25,.25,.28,3),(-.19,.08,.28,.19,.19,.38,6)],
 'mechanical_arm':[(-.16,0,-.14,.16,.12,.14,1),(-.1,.12,-.09,.1,.28,.09,3),(-.06,.25,-.06,.06,.4,.2,2)],
 'turret_gearbox':[(-.22,0,-.22,.22,.09,.22,3),(-.12,.09,-.12,.12,.16,.12,1),(-.28,.02,-.06,.28,.08,.06,2),(-.06,.02,-.28,.06,.08,.28,2)],
 'hard_disk':[(-.18,0,-.23,.18,.08,.23,2),(-.16,.09,-.21,.16,.15,.21,1),(-.12,.15,-.12,.12,.2,.12,0),(-.12,.12,.21,-.04,.16,.24,4)],
 'holographic_memory':[(-.16,0,-.16,.16,.08,.16,1),(-.1,.12,-.1,.1,.32,.1,6),(-.04,.32,-.04,.04,.4,.04,4)],
 'electroshield':[(-.18,0,-.18,.18,.09,.18,1),(-.12,.09,-.12,.12,.24,.12,4),(-.05,.24,-.05,.05,.36,.05,6)],
 'titanium_hull':[(-.2,0,-.2,.2,.12,.2,2),(-.16,.12,-.16,.16,.19,.16,1),(-.12,.19,-.12,.12,.27,.12,2)],
 'gyro_stabilizer':[(-.24,0,-.24,.24,.06,-.17,4),(-.24,0,.17,.24,.06,.24,4),(-.24,0,-.17,-.17,.06,.17,4),(.17,0,-.17,.24,.06,.17,4),(-.08,.06,-.08,.08,.15,.08,3)],
}
for name,boxes in modules.items():
 mesh('sc_mount_'+name+'.obj',boxes)
 mesh('sc_pickup_'+name+'.obj',[(a*1.5,b*1.5-.25,c*1.5,d*1.5,e*1.5-.25,f*1.5,mat)for a,b,c,d,e,f,mat in boxes])
mesh('sc_arm_link.obj',[(-.045,-.045,0,.045,.045,1,2)])
mesh('sc_arm_claw.obj',[(-.18,-.06,-.04,.18,.06,.04,3),(-.18,-.18,-.04,-.1,.06,.12,2),(.1,-.18,-.04,.18,.06,.12,2)])
mesh('sc_ray_ring.obj',[(-.25,-.25,-.02,.25,-.19,.02,4),(-.25,.19,-.02,.25,.25,.02,4),(-.25,-.19,-.02,-.19,.19,.02,4),(.19,-.19,-.02,.25,.19,.02,4)])
mesh('sc_ray_packet.obj',[(-.07,-.07,-.07,.07,.07,.07,6)])
mesh('sc_spawner.obj',[(-.7,-.5,-.7,.7,-.39,.7,1),(-.58,-.39,-.58,.58,-.34,.58,0),(-.67,-.39,-.67,-.5,-.27,-.5,4),(.5,-.39,-.67,.67,-.27,-.5,4),(-.67,-.39,.5,-.5,-.27,.67,4),(.5,-.39,.5,.67,-.27,.67,4)])
# Each asset family owns an editable PNG atlas. Existing custom PNGs survive builds.
import shutil
mapping={}
for obj in sorted(M.glob('*.obj')):
    stem=obj.stem[3:]
    family=('conveyor' if stem.startswith(('slat','tread_','curve_','belt_')) else
            'conveyor_arrows' if stem.startswith('arrow_') else stem)
    tex='sc_surface_'+family+'.png';mapping[stem]=tex
    if not (T/tex).exists():shutil.copyfile(T/'sc_materials.png',T/tex)
    # Flat face normals preserve the intended hard-edged pixel-model shading.
    verts=[];lines=[];normal=0
    for line in obj.read_text().splitlines():
        if line.startswith(('vn ','mtllib ','usemtl ')):continue
        if line.startswith('v '):verts.append(tuple(map(float,line.split()[1:])))
        if line.startswith('f '):
            ids=[int(t.split('/')[0])-1 for t in line.split()[1:]];a,b,c=[verts[i] for i in ids[:3]]
            u=[b[i]-a[i] for i in range(3)];v=[c[i]-a[i] for i in range(3)]
            cross=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]];length=math.sqrt(sum(x*x for x in cross))
            if length<1e-10:continue
            normal+=1;lines.append('vn '+' '.join(f'{x/length:.7f}' for x in cross))
            line='f '+' '.join('/'.join(t.split('/')[:2])+f'/{normal}' for t in line.split()[1:])
        lines.append(line)
    obj.write_text(f'mtllib {obj.stem}.mtl\nusemtl editable\n'+'\n'.join(lines)+'\n')
    (M/(obj.stem+'.mtl')).write_text(f'newmtl editable\nKd 1 1 1\nmap_Kd ../textures/{tex}\n')
(R/'mods/shift_circuit/asset_textures.lua').write_text('return {\n'+''.join(f' ["{k}"]="{v}",\n' for k,v in mapping.items())+'}\n')
