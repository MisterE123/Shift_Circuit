from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().path=(root/'mods/shift_circuit').as_posix()
lua.execute("""
local R=dofile(path..'/rules.lua');local B=dofile(path..'/command_batches.lua')(R)
local s={size=20,board={},bots={},walls={},crates={},round=2}
for z=1,20 do for x=1,20 do s.board[x..','..z]={kind='floor'}end end
local function bot(id,x,z,dir,command)
 local b={id=id,x=x,z=z,dir=dir,enemy=true,program={command or 'STEP'},hp=5,home={x=x,z=z},parts={}}
 s.bots[#s.bots+1]=b;return b
end
local a=bot('A',2,2,0);local b=bot('B',6,2,0);local c=bot('C',10,2,0)
local batch,left=B.take(s,s.bots,1);assert(#batch==3 and #left==0,'independent enemies use one update')
s.bots={};a=bot('A',2,2,1);b=bot('B',4,2,3);c=bot('C',10,2,0)
local batch,left=B.take(s,s.bots,1);assert(#batch==2 and batch[1]==a and batch[2]==c and left[1]==b,'shared destination preserves priority; unrelated enemy bypasses waiting conflict')
R.command(s,a,'STEP');R.command(s,c,'STEP');local next,left=B.take(s,left,1);assert(next[1]==b and #left==0)
s.bots={};a=bot('A',2,2,1,'MOVE3');b=bot('B',3,2,0);c=bot('C',6,2,0)
local batch,left=B.take(s,s.bots,1);assert(#batch==1 and #left==2,'multi-square pushes reserve complete swept chain')
s.bots={};a=bot('A',2,2,0);a.enemy=false;b=bot('B',6,2,0)
local batch,left=B.take(s,s.bots,1);assert(#batch==1 and left[1]==b,'human animation remains in priority order')
s.bots={};a=bot('A',2,2,1);a.scripted=true;a.kind='ram_bot';b=bot('B',4,2,0)
local batch,left=B.take(s,s.bots,1);assert(#batch==1 and left[1]==b,'ram-bot sight checks cannot be overtaken by their target')
print('PASS simultaneous independent enemies, priority conflict waves, pushed chains, human ordering and scripted perception')
""")
