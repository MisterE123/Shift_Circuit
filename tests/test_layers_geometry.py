from pathlib import Path
from PIL import Image
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True)
for n,file in [('R','rules.lua'),('G','geometry.lua'),('C','campaign.lua'),('I','inspection.lua')]:lua.globals()[n]=lua.execute((root/'mods/shift_circuit'/file).read_text())
lua.execute('''
local n=0;local function test(name,f)f();n=n+1;print('PASS '..name)end
local function close(a,b)return math.abs(a-b)<.00001 end
local function bot(x,z)return {id='p',x=x,z=z,dir=1,hp=1,shield=0,damage=0,next=1}end
test('crusher coexists with conveyor',function()local s=R.arena();assert(s.overhead['6,4'] and s.board['6,4'].kind=='belt');local b=bot(6,4);s.bots={b};R.hazards(s,1);assert(not b.down);R.hazards(s,2);assert(b.down)end)
test('crusher coexists with rotator',function()local s=C.setup(R,2,'campaign');assert(s.overhead['5,8'] and s.board['5,8'].kind=='rotator');local b=bot(5,8);s.bots={b};R.rotators(s);assert(b.dir==2);R.hazards(s,2);assert(b.down)end)
test('overhead layer does not block horizontal beams',function()local s=R.arena();s.walls={};s.bots={};assert(R.trace(s,4,4,1,5)==5)end)
test('mesh yaw matches logical directions',function()for dir=0,3 do local d=R.dirs[dir+1];assert(close(-math.sin(G.yaw(dir)),d.x) and close(math.cos(G.yaw(dir)),d.z))end end)
test('all emitter barrels and beam endpoints match',function()for dir=0,3 do for power=1,3 do for i=1,power do
 local p,l=G.beam(5,5,dir,power,i,3,false);local d=R.dirs[dir+1];local side=(i-(power+1)/2)*.375
 assert(close(p.y,1) and close(l,6-.1875));assert(close(p.x+d.x*l,10.5+d.x*6+d.z*side));assert(close(p.z+d.z*l,10.5+d.z*6-d.x*side))
end end end end)
test('curved belt endpoints and tangent align',function()for dir=0,3 do for _,turn in ipairs({1,3})do local entry=(dir+turn)%4;local t={dir=dir,entry=entry};local a,ya=G.belt(t,0);local b,yb=G.belt(t,1);assert(close(a.x,-R.dirs[entry+1].x)and close(a.z,-R.dirs[entry+1].z));assert(close(b.x,R.dirs[dir+1].x)and close(b.z,R.dirs[dir+1].z));assert(close(-math.sin(ya),R.dirs[entry+1].x) and close(-math.sin(yb),R.dirs[dir+1].x))end end end)
test('turning conveyor rotates transported robot',function()local s=R.arena();s.walls={};local b=bot(7,4);s.bots={b};R.belts(s,false);assert(b.x==8 and b.z==4 and b.dir==0)end)
test('pointed HUD stops at an occluding node',function()local e={hint='Left Rotator\\nRotates left.'};local obj={get_luaentity=function()return e end,set_properties=function()end};I.describe(obj,'Left Rotator','Quarter turn.');local p={get_pos=function()return {x=0,y=0,z=0}end,get_properties=function()return {eye_height=1.625}end,get_look_dir=function()return {x=0,y=0,z=1}end};local c={raycast=function(a,b)assert(b.z==9);local done=false;return function()if not done then done=true;return {type='object',ref=obj}end end end};assert(I.pointed(c,p,9):find('Left Rotator'));c.raycast=function()local done=false;return function()if not done then done=true;return {type='node'}end end end;assert(I.pointed(c,p,9)=='')end)
print(n..' layer/geometry tests passed')
''')
models=root/'mods/shift_circuit/models';textures=root/'mods/shift_circuit/textures'
for name in ['sc_edge_wall.obj','sc_rotator.obj']:
    verts=[];faces=[]
    for line in (models/name).read_text().splitlines():
        if line.startswith('v '):verts.append(tuple(map(float,line.split()[1:])))
        if line.startswith('f '):faces.append(tuple(sorted(verts[int(a.split('/')[0])-1] for a in line.split()[1:])))
    assert len(faces)==len(set(faces)),f'duplicate triangles in {name}'
im=Image.open(textures/'sc_beam_alpha.png');assert 0<im.getextrema()[3][0]<255
# Luanti imports OBJ by mirroring X: west edge must map to u=0, east to u=1.
vs=[];uv=[]
for line in (models/'sc_tile.obj').read_text().splitlines():
    if line.startswith('v '):vs.append(tuple(map(float,line.split()[1:])))
    if line.startswith('vt '):uv.append(tuple(map(float,line.split()[1:])))
assert -vs[0][0]<-vs[1][0] and uv[0][0]<uv[1][0]
print('PASS mesh duplicate-face, beam alpha, and unmirrored checkpoint UV checks')

# Regression checks for the redesigned geometry and movement instructions.
def vertices(name):
    return [tuple(map(float,line.split()[1:])) for line in (models/name).read_text().splitlines() if line.startswith('v ')]
frame=vertices('sc_press_frame.obj')
assert min(v[1] for v in frame)==-5 and max(v[1] for v in frame)>45
powerups=['cell','shield','cache','blink','range','jammer']
assert len({(models/f'sc_pickup_{k}.obj').read_bytes() for k in powerups})==6
for kind in ['right','left']:
    for f in range(24):
        v=vertices(f'sc_tread_curve_{kind}_{f}.obj')
        assert v and all(-10.00001<=p[0]<=10.00001 and -10.00001<=p[2]<=10.00001 for p in v)
arrow=vertices('sc_arrow_forward.obj')
assert (0.0,-1.9,6.5) in arrow # Arrow tip points along +Z, matching increasing belt travel.
runtime=(root/'mods/shift_circuit/runtime.lua').read_text()
assert 'Use K to enter flight mode' in runtime
for unwanted in ['Native flight','FREE FLIGHT','WALK THE FACTORY','LOBBY & CAMERA']:
    assert unwanted not in runtime
print('PASS floor-supported crusher, six unique collectibles, clipped tread frames, geometric arrow direction, flight wording')

lua.execute('''
-- Check the actual client transform: updateNodePos negates entity rotation;
-- setPitchYawRoll maps local +Z to (sin(-yaw), cos(-yaw)).
local function close(a,b)return math.abs(a-b)<.00001 end
for dir=0,3 do
 local yaw=G.yaw(dir);local d=R.dirs[dir+1]
 assert(close(math.sin(-yaw),d.x) and close(math.cos(-yaw),d.z))
 for _,turn in ipairs({1,3})do
  local t={dir=dir,entry=(dir+turn)%4};local sign=turn==1 and 1 or -1
  local x,z=-sign,0;local angle=-yaw
  local wx=x*math.cos(angle)+z*math.sin(angle);local wz=-x*math.sin(angle)+z*math.cos(angle)
  local entry=R.dirs[t.entry+1];assert(close(wx,-entry.x)and close(wz,-entry.z),'corner opening follows upstream belt')
 end
end
local s=C.setup(R,1,'race');local b={id='p',x=2,z=4,dir=0,next=1,hp=1,energy=3,shield=0};s.bots={b}
R.collect(s,b);assert(b.blink and not b.down,'blink collectible is harmless')
b.x=2;b.z=5;R.lasers(s);assert(b.down and b.destroyed_by=='Fixed laser')
b.down=false;b.hp=1;b.x=6;b.z=4;R.hazards(s,2);assert(b.down and b.destroyed_by=='CRUSHED by crusher')
b.down=false;b.hp=1;b.x=5;b.z=5;R.move(s,b,0);assert(b.down and b.destroyed_by=='Fell into a pit')
print('PASS client rotation matrix, corner stream alignment, harmless Blink pickup, destruction causes')
''')
