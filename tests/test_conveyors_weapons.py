from pathlib import Path
from lupa import LuaRuntime
lua=LuaRuntime(unpack_returned_tuples=True)
lua.globals().R=lua.execute((Path(__file__).resolve().parents[1]/'mods/shift_circuit/rules.lua').read_text())
lua.execute('''
local function b(id,x,z,dir)return {id=id,x=x,z=z,dir=dir or 1,hp=1,energy=0,damage=0,shield=0}end
local function board()local s={board={},walls={},bots={},round=2};for x=1,8 do for z=1,8 do s.board[R.key(x,z)]={kind='floor'}end end;return s end
local n=0;local function test(name,f)f();n=n+1;print('PASS '..name)end
test('double conveyor takes two steps and follows destination direction',function()local s=board();local p=b('p',2,2);s.bots={p};s.board['2,2']={kind='belt',speed=2,dir=1};s.board['3,2']={kind='belt',dir=0};R.belts(s);assert(p.x==3 and p.z==3)end)
test('double conveyor stops after reaching plain floor',function()local s=board();local p=b('p',2,2);s.bots={p};s.board['2,2']={kind='belt',speed=2,dir=1};R.belts(s);assert(p.x==3)end)
test('normal onto express does not gain a retroactive step',function()local s=board();local p=b('p',2,2);s.bots={p};s.board['2,2']={kind='belt',dir=1};s.board['3,2']={kind='belt',speed=2,dir=1};R.belts(s);assert(p.x==3)end)
test('second express step obeys thin wall',function()local s=board();local p=b('p',2,2);s.bots={p};s.board['2,2']={kind='belt',speed=2,dir=1};s.board['3,2']={kind='belt',speed=2,dir=1};s.walls[R.edge(3,2,1)]=true;R.belts(s);assert(p.x==3)end)
test('express pit drop only once',function()local s=board();local p=b('p',2,2);s.bots={p};s.board['2,2']={kind='belt',speed=2,dir=1};s.board['3,2']={kind='pit'};R.belts(s);assert(p.down and p.damage==1)end)
test('opening round suppresses every robot weapon through all registers',function()
 for kind in pairs(R.weapons)do local s=board();s.round=1;local p,q=b('p',2,2,1),b('q',4,2,3);p.hp=5;q.hp=5;p.weapon=kind;p.energy=9;q.energy=9;q.enemy=true;s.bots={p,q}
 for slot=1,5 do R.robot_weapons(s,slot);assert(#s.shots==0 and p.energy==9 and q.energy==9 and p.hp==5 and q.hp==5 and not p.remote_round)end
 s.round=2;R.robot_weapons(s,1);assert(#s.shots==2,'weapons activate in round two')
 end
 local s=board();s.round=1;s.size=8;s.lasers={{x=2,z=2,dir=1,power=1}};local q=b('q',4,2,3);q.hp=5;s.bots={q};R.lasers(s);assert(q.hp==4,'fixed lasers still run in first round')
end)
test('automatic mutual shots are simultaneous and free',function()local s=board();local p,q=b('p',2,2,1),b('q',4,2,3);s.bots={p,q};R.robot_weapons(s);assert(p.down and q.down and #s.shots==2 and p.energy==0 and q.energy==0)end)
test('disabled robots do not shoot',function()local s=board();local p,q=b('p',2,2,1),b('q',4,2,3);p.down=true;s.bots={p,q};R.robot_weapons(s);assert(#s.shots==1 and not q.down)end)
test('automatic weapons respect range and shields',function()local s=board();local p,q=b('p',1,2,1),b('q',7,2,1);p.range=7;q.shield=1;s.bots={p,q};R.robot_weapons(s);assert(not q.down and q.shield==0)end)
test('preview trace does not damage or append shots',function()local s=board();local p=b('p',3,2);s.bots={p};local length,target=R.trace(s,1,2,1,8);assert(length==1.75 and target==p and p.hp==1 and not s.shots)end)
print(n..' conveyor/automatic weapon tests passed')
''')
