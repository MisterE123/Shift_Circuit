from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().path=(root/'mods/shift_circuit').as_posix()
lua.execute("""
local R=dofile(path..'/rules.lua');local L=dofile(path..'/levels.lua');local Q=dofile(path..'/courses.lua')
for _,size in ipairs({10,20})do local d=L.blank(size);assert(L.validate(d));local count=0;for _ in pairs(d.board)do count=count+1 end;assert(count==size*size)end
local data={L.blank(20),L.blank(10),L.blank(20),L.blank(10)};local s=Q.assemble(R,data,7)
assert(s.size==41 and #s.platforms==4 and s.checkpoint_count==7,'mixed-size course and chosen checkpoint count')
local numbers={};for key,t in pairs(s.board)do if t.kind=='station'then assert(not numbers[t.number]);numbers[t.number]=true end end
for i=1,7 do assert(numbers[i],'contiguous checkpoint numbering')end
assert(data[1].board['18,3'].kind=='checkpoint','template never mutated')
local single=Q.assemble(R,{L.blank(10)},9);assert(single.checkpoint_count==3,'requested count capped by candidates')
local d=L.blank(10);for k,t in pairs(d.board)do if t.kind=='checkpoint'then d.board[k]={kind='floor'}end end;d.board['6,6']={kind='checkpoint'};for dir=0,3 do d.walls[R.edge(6,6,dir)]=true end
assert(Q.number(R,d,3)==0,'unreachable candidates excluded')
local b={id='A',x=2,z=2,hp=2,max_hp=5,dir=0,home={x=2,z=2,dir=0},next=1};s.bots={b};s.pickups['2,2']='repair';R.collect(s,b);assert(b.hp==4 and not s.pickups['2,2'],'pickup restores two immediately')
s.board['2,2']={kind='repair'};R.hazards(s,1);assert(b.hp==4,'pad does not heal each register');R.repairs(s);assert(b.hp==5,'repair clamps to max')
b.hp=0;b.down=true;R.repairs(s);assert(b.hp==0,'pad cannot revive destroyed robot')
b.down=nil;b.hp=2;b.x=3;R.repairs(s);assert(b.hp==2,'must end round on repair pad')
s.checkpoint_count=7;b.next=7;s.board['3,2']={kind='station',number=7};R.hazards(s,5);assert(s.winner=='A','variable-length route wins correctly')
print('PASS sizes 10/20, mixed courses, reachable candidate numbering, repair timing/cap/destruction, seven-checkpoint victory')
""")
