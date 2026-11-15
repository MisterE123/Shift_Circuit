from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().path=(root/'mods/shift_circuit').as_posix()
lua.execute("""
local R=dofile(path..'/rules.lua');local C=dofile(path..'/campaign.lua')
for difficulty=1,3 do for dir=0,3 do for _,xy in ipairs({{1,1},{2,2},{11,11}})do
 local s=R.arena();s.walls={};s.overhead={};s.pushers={};s.lasers={};s.pickups={};for k in pairs(s.board)do s.board[k]={kind='floor'}end
 s.board['6,6']={kind='station',number=1};s.board['8,8']={kind='station',number=2};s.board['3,8']={kind='station',number=3}
 local b={id='RACER',enemy=true,racing=true,difficulty=difficulty,x=xy[1],z=xy[2],dir=dir,hp=5,energy=4,range=4,next=1,hand={'BACK2','MOVE3','MOVE3','BACK','LEFT','RIGHT','WAIT','UTURN','STEP'}};s.bots={b}
 b.program=C.plan(R,s,b);R.command(s,b,b.program[1]);assert(not b.down,'edge start must choose a safe first command')
end end end
-- If survival becomes impossible later, do not choose an earlier avoidable death.
local s=R.arena();s.bots={};s.walls={};s.overhead={};s.lasers={};s.pushers={};s.pickups={}
for k in pairs(s.board)do s.board[k]={kind='floor'}end
local b={id='R',enemy=true,racing=true,difficulty=3,x=1,z=1,dir=2,hp=5,energy=4,next=1,hand={'MOVE3','STEP','LEFT','RIGHT','UTURN','WAIT','BACK2','DASH','BACK'}};s.bots={b}
b.program=C.plan(R,s,b);for slot=1,5 do R.programs(s,slot);assert(not b.down,'safe five-card course exists')end
print('PASS 36 edge/direction/difficulty plans and full-round edge survival')
""")
