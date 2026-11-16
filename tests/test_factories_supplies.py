from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().path=(root/'mods/shift_circuit').as_posix()
lua.execute("""
local R=dofile(path..'/rules.lua');local L=dofile(path..'/levels.lua')
local function state()local s=L.blank(10);s.bots={};s.round=1;s.pickups={};R.init_objects(s);return s end
local s=state();s.board['3,3']={kind='belt',dir=1,speed=2};s.board['4,3']={kind='belt',dir=0,speed=1};s.pickups['3,3']='cell';R.belts(s,true);assert(s.pickups['4,3']=='cell');R.belts(s,false);assert(s.pickups['4,4']=='cell','express feeds curved stream')
s.pickups={['3,3']='cell',['4,3']='shield'};s.board['4,3']={kind='belt',dir=1,speed=1};R.belts(s,false);assert(s.pickups['4,3']=='cell'and s.pickups['5,3']=='shield','line advances without overwriting')
s.pickups={['3,3']='cell',['5,3']='shield'};s.board['5,3']={kind='belt',dir=3,speed=1};R.belts(s,false);assert(s.pickups['3,3']=='cell'and s.pickups['5,3']=='shield','merging streams wait')
s.pickups={['3,3']='cell'};s.walls[R.edge(3,3,1)]=true;R.belts(s,false);assert(s.pickups['3,3']);s.walls={};s.board['4,3']={kind='pit'};R.belts(s,false);assert(next(s.pickups)==nil and s.board['4,3'].kind=='pit','supplies fall without filling holes')
s=state();s.pushers={{x=3,z=3,dir=1,parity=1}};s.pickups['3,3']='repair';R.pushers(s,2);assert(s.pickups['3,3']);R.pushers(s,1);assert(s.pickups['4,3']=='repair')
s.pickups={['3,3']='cell',['4,3']='shield',['5,3']='repair'};s.walls[R.edge(5,3,1)]=true;R.pushers(s,3);assert(s.pickups['3,3']=='cell'and s.pickups['4,3']=='shield'and s.pickups['5,3']=='repair','blocked powerup chain stays intact')
s.walls={};s.board['6,3']={kind='pit'};R.pushers(s,5);assert(s.pickups['4,3']=='cell'and s.pickups['5,3']=='shield'and not s.pickups['6,3'],'pusher moves powerup chain and last item falls')
s.pickups={['3,3']='cell',['4,3']='shield',['5,3']='repair'};s.board['3,3']={kind='belt',dir=1,speed=1};R.belts(s,false);assert(s.pickups['4,3']=='cell'and s.pickups['5,3']=='shield'and not s.pickups['3,3'],'conveyor pushes off-belt supply chain')
s.pickups={['4,3']='repair'}
local b={id='Pilot',x=3,z=3,dir=1,hp=5,energy=3,next=1,parts={}};s.bots={b};R.move(s,b,1);assert(s.pickups['4,3']=='repair','racers do not push pickups')
s=state();s.crates['3,3']={kind='steel',item='cell'};s.overhead['3,3']={parity=0};R.init_objects(s);local c=s.crates['3,3'];R.hazards(s,2);assert(c.kind=='loot'and c.hp==3 and not s.pickups['3,3']);R.hazards(s,4);assert(c.destroyed and s.pickups['3,3']=='cell','new contents survive same crusher stroke');R.hazards(s,2);assert(not s.pickups['3,3'],'next crush destroys pickup')
s=state();s.board['3,3']={kind='plate'};s.board['3,4']={kind='trapdoor',open=false};s.pickups['3,4']='cell';s.bots={{id='Pilot',x=3,z=3}};s.register=1;R.plates(s);assert(not s.pickups['3,4'],'opening trapdoor drops pickup')
for pattern,offsets in pairs(R.factory_patterns)do for dir=0,3 do
 s=state();s.board['5,5']={kind='factory',dir=dir,pattern=pattern,crate_kind='steel'};assert(L.validate(s));R.factories(s,1,function()return 2 end);local count=0
 for _,o in pairs(s.crates)do count=count+1;assert(o.kind=='steel'and not o.down)end;assert(count==2)
 for i=1,math.min(2,#offsets)do local d=R.dirs[(dir+offsets[i])%4+1];assert(R.at(s,5+d.x,5+d.z).crate)end
 R.factories(s,1);R.factories(s,2);local again=0;for _ in pairs(s.crates)do again=again+1 end;assert(again==count,'one production batch per round')
end end
s=state();s.board['3,3']={kind='factory',dir=1,pattern='one',crate_kind='loot'};s.crates['4,3']={kind='steel'};s.crates['5,3']={kind='loot'};R.init_objects(s)
s.walls[R.edge(5,3,1)]=true;R.factories(s,1);assert(s.board['3,3'].jammed[1]and s.crates['4,3'].x==4 and s.crates['5,3'].x==5,'blocked chain jams atomically')
s.round=2;s.walls={};s.bots={{id='Pilot',x=6,z=3,hp=5}};R.factories(s,2);assert(s.board['3,3'].jammed[1]and s.bots[1].x==6,'factory cannot push a racer')
s.round=3;s.bots={};s.board['6,3']={kind='pit'};R.factories(s,3,function()return 1 end);assert(not next(s.board['3,3'].jammed)and s.board['6,3'].filled and s.crates['4,3'].x==5 and R.at(s,4,3).kind=='loot','retry pushes whole chain and fills hole')
local len,target,wall=R.trace(s,3,1,0,8);assert(wall and not target and len==1.5,'factory is a solid ray blocker')
assert(R.blocked(s,2,3,1));local b={id='Pilot',x=2,z=3,dir=1,hp=5,parts={blink=1},blink=true,blink_left=1,energy=2};assert(not R.move(s,b,1))
assert(R.factory_due({schedule={rounds={99}}},2),'legacy schedules no longer delay production')
s.board['3,3'].pattern='bad';assert(not L.validate(s),'invalid factory cannot be imported')
print('PASS conveyed/pushed supplies, collision-safe lines/merges, pits/trapdoors, staged crushing, 20 factory orientations, atomic jams/retries and factory walls')
""")
