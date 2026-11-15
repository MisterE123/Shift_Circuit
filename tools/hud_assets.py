"""Original icon-and-pip HUD, with no numeric stat text."""
from pathlib import Path
from PIL import Image,ImageDraw
T=Path(__file__).resolve().parents[1]/'mods/shift_circuit/textures'
ink='#a9e7d7'; muted='#304854'; gold='#efc575'; red='#e78b9f'
def icon(d,kind,x=8,y=6,c=ink):
    if kind=='energy':d.polygon([(x+17,y),(x+5,y+15),(x+13,y+15),(x+10,y+28),(x+26,y+10),(x+17,y+10)],fill=c)
    elif kind=='shield':d.polygon([(x+3,y+3),(x+15,y),(x+27,y+3),(x+25,y+18),(x+15,y+28),(x+5,y+18)],outline=c,width=3)
    elif kind=='hull':d.rectangle((x+3,y+4,x+27,y+24),outline=c,width=3);d.rectangle((x+7,y+9,x+23,y+14),fill=c);d.line((x+15,y,x+15,y+4),fill=c,width=3)
    elif kind=='hand':
        for i in range(3):d.rectangle((x+i*6,y+6-i*2,x+17+i*6,y+27-i*2),outline=c,width=2)
    elif kind=='jam':d.polygon([(x+15,y),(x+29,y+26),(x+1,y+26)],outline=c,width=2);d.line((x+15,y+8,x+15,y+16),fill=c,width=3);d.rectangle((x+14,y+20,x+16,y+22),fill=c)
    elif kind=='route':d.line((x+5,y+28,x+5,y+1),fill=c,width=3);d.polygon([(x+7,y+2),(x+26,y+2),(x+19,y+10),(x+7,y+10)],fill=c)
for kind,maximum in [('energy',9),('shield',3),('hull',5),('hand',12),('jam',4),('route',3)]:
    for value in range(maximum+1):
        im=Image.new('RGBA',(212,40),'#0b1d29dd');d=ImageDraw.Draw(im);accent=red if kind=='jam' else (gold if kind in ['hand','route'] else ink);icon(d,kind,c=accent)
        width=min(40,144//maximum-3)
        for i in range(maximum):
            x=49+i*(width+3);d.rounded_rectangle((x,12,x+width,28),radius=2,fill=accent if i<value else muted)
        im.save(T/f'sc_stat_{kind}_{value}.png')
for bits in range(4):
    im=Image.new('RGBA',(212,40),'#0b1d29dd');d=ImageDraw.Draw(im)
    for i,name in enumerate(['BLINK','PULSE']):
        iconim=Image.open(T/f'sc_cmd_{name}.png').convert('RGBA')
        if not bits&(1<<i):iconim.putalpha(iconim.getchannel('A').point(lambda v:v//4))
        im.alpha_composite(iconim,(10+i*100,4))
        d.rectangle((48+i*100,16,75+i*100,24),fill=ink if bits&(1<<i) else muted)
    im.save(T/f'sc_stat_modules_{bits}.png')
for state in ['disabled','ready','locked']:
    im=Image.new('RGBA',(64,64),'#19333fff');d=ImageDraw.Draw(im);c=gold if state=='ready' else (ink if state=='locked' else '#68808a')
    d.rectangle((1,1,62,62),outline=c,width=3)
    if state=='locked':d.rectangle((20,21,44,39),fill=c);d.arc((24,9,40,29),180,360,fill=c,width=3)
    else:d.polygon([(24,10),(24,38),(44,24)],fill=c)
    d.text((8,47),'COMMIT',fill=c);im.save(T/f'sc_commit_{state}.png')
im=Image.new('RGBA',(32,32));d=ImageDraw.Draw(im)
for y in [2,15]:d.polygon([(16,y),(4,y+12),(11,y+12),(16,y+7),(21,y+12),(28,y+12)],fill=gold)
im.save(T/'sc_double_arrow.png')
print('Generated visual HUD gauges, commit tool, and double conveyor marker.')
im=Image.open(T/'sc_commit_ready.png').copy();d=ImageDraw.Draw(im);d.rectangle((4,43,60,60),fill='#19333f');d.text((16,47),'START',fill=gold);im.save(T/'sc_start.png')
im=Image.new('RGBA',(32,32));d=ImageDraw.Draw(im)
d.arc((2,3,29,30),180,270,fill=gold,width=6);d.polygon([(16,0),(8,11),(24,11)],fill=gold);im.save(T/'sc_curve_arrow.png')
