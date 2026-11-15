from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().path=(root/'mods/shift_circuit').as_posix()
lua.execute("""
local G=dofile(path..'/goals.lua')
local s={checkpoint_count=5,objective_collect='cell',pickups={['3,3']='cell'},board={['8,4']={kind='station',number=1},['9,8']={kind='station',number=2}}}
local b={x=2,z=2,next=1,home={x=1,z=1},collected_counts={}}
local goal=G.current(s,b,'program');assert(goal.texture=='sc_goal_collect_cell.png'and goal.x==3 and goal.z==3)
b.collected_counts.cell=1;goal=G.current(s,b,'program');assert(goal.texture=='sc_goal_flag_1_5.png'and goal.x==8 and goal.z==4)
b.next=2;goal=G.current(s,b,'program');assert(goal.texture=='sc_goal_flag_2_5.png'and goal.x==9)
b.down=true;goal=G.current(s,b,'program');assert(goal.texture=='sc_goal_reboot.png'and goal.x==1)
assert(G.current(s,b,'finished').texture=='sc_goal_complete.png')
print('PASS goal priority, collection/checkpoint advancement, variable route length, reboot and completion')
""")
for count in range(1,10):
 for n in range(1,count+1):assert (root/'mods/shift_circuit/textures'/f'sc_goal_flag_{n}_{count}.png').exists()
