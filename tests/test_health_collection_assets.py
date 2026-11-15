from pathlib import Path
from lupa import LuaRuntime
import math
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True)
lua.globals().R=lua.execute((root/'mods/shift_circuit/rules.lua').read_text())
lua.execute('''
local function state()
 local s=R.arena();s.walls={};s.overhead={};s.pickups={};s.bots={};for z=1,11 do for x=1,11 do s.board[R.key(x,z)]={kind='floor'}end end;return s
end
local function bot(s)local b={id='p',x=2,z=2,dir=1,hp=R.hull_max,max_hp=R.hull_max,energy=3,shield=0,home={x=2,z=2}};s.bots={b};return b end
local s=state();local b=bot(s);for i=1,4 do R.hit(b,'Fixed laser');assert(not b.down and b.hp==5-i)end;R.hit(b,'Fixed laser');assert(b.down and b.hp==0);R.respawn(s);assert(b.hp==5 and not b.down)
s=state();b=bot(s);s.pickups['3,2']='shield';s.pickups['4,2']='blink';R.command(s,b,'DASH');assert(b.shield==0 and not b.blink and not s.collections,'movement itself never collects');R.collect_phase(s);assert(b.blink and b.shield==0 and s.pickups['3,2']=='shield'and #s.collections==1,'only final square collects')
s=state();b=bot(s);b.blink=true;s.pickups['3,2']='shield';s.pickups['4,2']='cell';R.command(s,b,'BLINK');assert(b.energy==2 and not s.collections);R.collect_phase(s);assert(b.energy==5 and s.pickups['3,2']=='shield' and #s.collections==1)
s=state();b=bot(s);s.board['2,2']={kind='belt',dir=1};s.pickups['3,2']='cache';R.belts(s,false);assert(not b.draw_bonus);R.collect_phase(s);assert(b.draw_bonus==1)
s=state();b=bot(s);s.pushers={{x=2,z=2,dir=1,parity=1}};s.pickups['3,2']='range';R.pushers(s,1);assert(not b.range);R.collect_phase(s);assert(b.range==7)
s=state();b=bot(s);s.pickups['3,2']='shield';s.board['4,2']={kind='pit'};R.command(s,b,'DASH');R.collect_phase(s);assert(b.down and s.pickups['3,2']=='shield'and not s.collections,'no intermediate pickup before falling')
s=state();b=bot(s);b.program={'STEP'};b.program_ids={100};local q={id='q',x=4,z=2,dir=3,hp=5,program={'STEP'},program_ids={10}};s.bots={b,q};s.pickups['3,2']='shield';R.programs(s,1);assert(b.x==2 and q.x==3 and b.shield==0 and q.shield==1,'collect after all priority moves and pushes resolve')
s=state();b=bot(s);b.shield=3;s.overhead[R.key(b.x,b.z)]={kind='crusher'};R.hazards(s,1);assert(not b.down and b.hp==5);R.hazards(s,2);assert(b.down and b.hp==0 and b.destroyed_by=='CRUSHED by crusher','active crusher destroys through shields');R.respawn(s);assert(b.hp==5 and not b.down)
print('PASS five hull, full reboot, phase-end collection, skipped intermediate squares, pushes and falls')
''')
models=root/'mods/shift_circuit/models'
for p in models.glob('*.obj'):
    normals=[];uv=[]
    for l in p.read_text().splitlines():
        if l.startswith('vn '):
            n=tuple(map(float,l.split()[1:]));assert abs(sum(v*v for v in n)-1)<1e-5;normals.append(n)
        elif l.startswith('vt '):uv.append(tuple(map(float,l.split()[1:])))
        elif l.startswith('f '):
            parts=[t.split('/') for t in l.split()[1:]];assert all(len(t)==3 and int(t[2])<=len(normals) for t in parts)
            a,b,c=[uv[int(t[1])-1] for t in parts[:3]];assert abs((b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0]))>1e-8,p.name
    assert normals
    assert (p.with_suffix('.mtl')).exists()
print('PASS all OBJ face normals and editable nondegenerate UVs')
for name in ['pickup','move','laser','impact','crusher','destroy']:
    p=root/'mods/shift_circuit/sounds'/('sc_'+name+'.ogg');assert p.read_bytes()[:4]==b'OggS'
print('PASS six packaged Ogg sound assets')
