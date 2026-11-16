from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().path=(root/'mods/shift_circuit').as_posix()
lua.execute('''
local R=dofile(path..'/rules.lua');local L=dofile(path..'/levels.lua');local Q=dofile(path..'/courses.lua')
local s=L.blank(10);local start=s.start;local keys={};for k,t in pairs(s.board)do if t.kind=='checkpoint'and k~=R.key(start.x,start.z)then keys[#keys+1]=k end end;table.sort(keys)
local x,z=keys[1]:match('(%d+),(%d+)');Q.number(R,s,1,{start=start,checkpoints={{x=tonumber(x),z=tonumber(z)}}});assert(s.board[keys[1]].kind=='station'and s.checkpoint_count==1);assert(s.board[R.key(start.x,start.z)].kind=='floor')
local sx,sz=keys[2]:match('(%d+),(%d+)');sx,sz=tonumber(sx),tonumber(sz);assert(s.board[keys[2]].kind=='save')
local b={id='Pilot',x=sx,z=sz,dir=2,hp=5,energy=4,next=1,parts={},home={x=start.x,z=start.z,dir=0}};s.bots={b};s.round=1;s.shots={}
R.checkpoint(s,b,sx,sz);assert(b.home.x==sx and b.home.z==sz and b.home.dir==2 and b.next==1 and not s.winner and b.save_serial==1)
R.checkpoint(s,b,sx,sz);assert(b.save_serial==1,'no repeated achievement for unchanged save')
b.dir=3;R.checkpoint(s,b,sx,sz);assert(b.home.dir==3 and b.save_serial==2)
R.drop(b,'Laser');R.respawn(s);assert(not b.down and b.x==sx and b.z==sz and b.dir==3,'reboot restores saved square/facing')
b.down=true;b.home={x=start.x,z=start.z,dir=0};R.checkpoint(s,b,sx,sz);assert(b.home.x==start.x,'destroyed robots cannot save')
b.down=nil;b.hp=1;b.energy=2
R.checkpoint(s,b,sx,sz);assert(b.hp==1 and b.energy==2,'saving during a register does not heal or recharge')
R.repairs(s);assert(b.hp==3 and b.energy==5,'round end save restores two hull and three power')
b.max_hp=6;b.hp=5;b.energy=8;R.repairs(s);assert(b.hp==6 and b.energy==9,'restoration respects hull and power caps')
b.hp=1;b.energy=0;b.down=true;R.repairs(s);assert(b.hp==1 and b.energy==0,'destroyed robots cannot restore')
b.down=nil;b.finished=true;R.repairs(s);assert(b.hp==1 and b.energy==0,'finished racers cannot restore')
b.finished=nil;b.x=start.x;b.z=start.z;R.repairs(s);assert(b.hp==1 and b.energy==0,'must end round on save square')
print('PASS unused candidate conversion, start/route preservation, save-only progress, one-shot feedback, facing updates and reboot')
''')
