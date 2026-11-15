from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True)
for n,f in [('R','rules.lua'),('C','campaign.lua')]:lua.globals()[n]=lua.execute((root/'mods/shift_circuit'/f).read_text())
lua.execute('''
local function clone(t)if type(t)~='table'then return t end;local r={};for k,v in pairs(t)do r[k]=clone(v)end;return r end
local s=R.arena();s.walls={};s.overhead={};s.lasers={};s.pushers={};s.pickups={}
for k in pairs(s.board)do s.board[k]={kind='floor'}end
s.board['4,2']={kind='station',number=1};s.board['6,2']={kind='station',number=2};s.board['8,2']={kind='station',number=3}
local b={id='AI',enemy=true,racing=true,x=2,z=2,dir=1,next=1,hp=5,max_hp=5,energy=4,range=4,hand={'STEP','STEP','DASH','DASH','RIGHT','LEFT','WAIT','BACK','WAIT'}}
local p={id='P',x=9,z=9,dir=0,next=1,hp=5,energy=4,range=4,program={'LEFT','LEFT','LEFT','LEFT','LEFT'}};s.bots={b,p}
local a=C.plan(R,s,b);assert(#a==5 and (a[1]=='STEP' or a[1]=='DASH'),'racer makes checkpoint progress')
local counts={};for _,c in ipairs(b.hand)do counts[c]=(counts[c]or 0)+1 end;for _,c in ipairs(a)do counts[c]=counts[c]-1;assert(counts[c]>=0,'AI uses its finite hand')end
p.program={'DASH','DASH','DASH','DASH','DASH'};local a2=C.plan(R,s,b);assert(table.concat(a)==table.concat(a2),'AI does not read hidden player cards')
b.racing=false;p.x=4;p.z=2;p.last_program={'WAIT','WAIT','WAIT','WAIT','WAIT'};local h=C.plan(R,s,b);assert(#h==5,'hunter prediction plan')
local c=C.setup(R,1,'race',2);c.ai_count=3;c.ai_mode='racer';C.enemies(c);assert(#c.bots==3);for _,e in ipairs(c.bots)do assert(e.hp==5 and e.max_hp==5 and e.racing and e.next==1)end
print('PASS AI finite-hand planning, checkpoint progress, private-card isolation, prediction, and shared hull')
''')
