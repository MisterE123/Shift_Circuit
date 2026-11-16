from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().path=(root/'mods/shift_circuit').as_posix()
lua.execute("""
local B=dofile(path..'/schedule_badges.lua')
local n=B.next_rounds({first=2,every=3,phase=1},4);assert(n[1]==6 and n[2]==9 and n[3]==12)
n=B.next_rounds({rounds={2,5,9}},5);assert(n[1]==5 and n[2]==9 and n[3]==nil)
n=B.next_rounds({first=2,every=3,rounds={2,3,6}},2);assert(n[1]==2 and n[2]==3 and n[3]==5,'explicit and repeating schedules form one ordered set')
assert(B.texture({parity=1},1,3)=='sc_schedule_steps_1_3.png')
assert(B.texture({parity=0},1,0)=='sc_schedule_steps_0_0.png')
local t=B.texture({spawner={rounds={2}}},3,0);assert(t:find('digit_dash',1,true),'expired schedule has no future rounds')
local object={get_pos=function()return {x=0,y=0,z=0}end,get_luaentity=function()return {schedule_badge={parity=0,height=3}}end}
assert(#B.nearby({object},{x=15,y=0,z=0})==0)
local nearby=B.nearby({object},{x=5,y=0,z=0});assert(#nearby==1 and nearby[1].pos.y==3)
print('PASS activation badge parity, step highlighting, repeating/explicit schedules, phase offsets, expiry and range')
""")
for parity in (0,1):
 for step in range(6):assert (root/'mods/shift_circuit/textures'/f'sc_schedule_steps_{parity}_{step}.png').exists()
