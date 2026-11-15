from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
lua.execute(r'''
local R=dofile(modpath..'/rules.lua');local C=dofile(modpath..'/campaign.lua');local G=dofile(modpath..'/geometry.lua')
local s={size=7,round=1,board={},walls={},bots={},pickups={}}
for z=1,7 do for x=1,7 do s.board[R.key(x,z)]={kind='floor'}end end
s.board['4,4']={kind='pit'}
local edges=G.pit_edges(s,R);assert(#edges==32,'28 outside edges + four internal pit edges')
for _,e in ipairs(edges)do
 local d=R.dirs[e.dir+1];local x=(e.x-.5-d.x*.94)/2;local z=(e.z-.5-d.z*.94)/2
 assert(math.abs(x-math.floor(x+.5))<1e-8 and math.abs(z-math.floor(z+.5))<1e-8)
 x=math.floor(x+.5);z=math.floor(z+.5)
 assert(R.tile(s,x,z).kind~='pit' and R.tile(s,x+d.x,z+d.z).kind=='pit')
 assert(e.y>.5 and e.y<.55,'above floor without overlay z-fighting')
end
for i=1,8 do s.bots[i]={id='R'..i,hp=5,x=2,z=2,dir=0,parts={hard_disk=1},blink=i==1,draw_bonus=i==2 and 3 or 0,disruption=i==3 and 4 or 0}end
math.randomseed(741);C.deal_round(s)
local ids={};for _,b in ipairs(s.bots)do assert(#b.hand==b.allowance);for i,c in ipairs(b.hand)do
 assert(b.hand_ids[i]>0 and not ids[b.hand_ids[i]],'every physical card has a unique ID');ids[b.hand_ids[i]]=true
 assert(c~='BLINK'or b.blink)
end;C.autofill(b);assert(#b.program==5);for i,index in ipairs(b.selected)do assert(b.program_ids[i]==b.hand_ids[index])end end
local first=s.bots[1];first.keep={1};local retained=first.hand[1];C.deal_round(s);if retained~='WAIT'then assert(first.hand[1]==retained)end
-- Same move, head-on: higher priority pushes first, independent of robot ID/list order.
local a={id='A',x=2,z=2,dir=1,hp=5,program={'STEP'},program_ids={10}}
local b={id='Z',x=3,z=2,dir=3,hp=5,program={'STEP'},program_ids={90}}
s.bots={a,b};assert(R.program_order(s,1)[1]==b);R.programs(s,1)
assert(a.x==2 and b.x==3,'low priority moves after the high-priority push')
a.x=2;b.x=3;a.program_ids[1]=100;R.programs(s,1)
assert(a.x==2 and b.x==3)
print('PASS shared deck IDs, allowances, module eligibility, retained cards, priority ordering and actual pit boundaries')
''')
