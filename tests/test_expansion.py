from pathlib import Path
from lupa import LuaRuntime
lua=LuaRuntime(unpack_returned_tuples=True)
root=Path(__file__).resolve().parents[1]
for name,file in [('R','rules.lua'),('C','campaign.lua')]: lua.globals()[name]=lua.execute((root/'mods/shift_circuit'/file).read_text())
lua.execute('''
local function b(id,x,z) return {id=id,x=x,z=z,dir=1,next=1,hp=1,energy=5,damage=0,shield=0,program={},home={x=x,z=z}} end
local function s() local a=R.arena();a.round=2;a.board={};a.walls={};for x=1,11 do for z=1,11 do a.board[R.key(x,z)]={kind='floor'} end end;return a end
local n=0;local function test(name,f) f();n=n+1;print('PASS '..name) end
test('edge walls symmetric without blocking tile occupancy',function() local a=s();local p=b('p',2,2);a.bots={p};a.walls[R.edge(2,2,1)]=true;assert(not R.move(a,p,1));assert(R.move(a,p,0));p.x=3;p.z=2;assert(not R.move(a,p,3));assert(R.tile(a,2,2).kind=='floor') end)
test('ray clips at thin wall',function() local a=s();a.walls[R.edge(3,2,1)]=true;R.fire(a,1,2,1,1,8);assert(a.shots[1].range==2.5) end)
test('ray stops at first robot surface',function() local a=s();local p,q=b('p',3,2),b('q',5,2);a.bots={p,q};R.fire(a,1,2,1,1,8);assert(p.down and not q.down and a.shots[1].range==1.75) end)
test('triple beam consumes shields then hull',function() local a=s();local p=b('p',3,2);p.shield=2;a.bots={p};R.fire(a,1,2,1,3,8);assert(p.down and p.shield==0) end)
test('double beam blocked by wall',function() local a=s();local p=b('p',3,2);a.bots={p};a.walls[R.edge(2,2,1)]=true;R.fire(a,1,2,1,2,8);assert(not p.down) end)
test('pulse spends energy and hits',function() local a=s();local p,q=b('p',2,2),b('q',4,2);a.bots={p,q};R.command(a,p,'PULSE');assert(q.down and p.energy==4) end)
test('empty battery cannot fire',function() local a=s();local p,q=b('p',2,2),b('q',4,2);p.energy=0;a.bots={p,q};R.command(a,p,'PULSE');assert(not q.down) end)
test('blink unlock and safe landing',function() local a=s();local p=b('p',2,2);a.bots={p};R.command(a,p,'BLINK');assert(p.x==2);p.blink=true;a.board['3,2']={kind='pit'};R.command(a,p,'BLINK');assert(p.x==4 and p.energy==4) end)
test('pusher obeys parity and edge barriers',function() local a=s();local p=b('p',2,2);a.bots={p};a.pushers={{x=2,z=2,dir=1,parity=1}};R.pushers(a,2);assert(p.x==2);a.walls[R.edge(2,2,1)]=true;R.pushers(a,1);assert(p.x==2);a.walls={};R.pushers(a,1);assert(p.x==3) end)
test('rotators turn in both directions',function() local a=s();local p=b('p',2,2);a.bots={p};a.board['2,2']={kind='rotator',turn=1};R.rotators(a);assert(p.dir==2);a.board['2,2'].turn=3;R.rotators(a);assert(p.dir==1) end)
test('finite shuffled hand and modifier clamps',function() local p=b('p',2,2);p.hp=5;C.deal(p);assert(#p.hand==9);p.draw_bonus=3;C.deal(p);assert(#p.hand==12);p.draw_bonus=0;p.disruption=4;C.deal(p);assert(#p.hand==5 and p.last_penalty==4 and p.disruption==0);C.deal(p);assert(#p.hand==9) end)
test('upgrade and malus collection once',function() local a=s();local p=b('p',2,2);p.hp=5;a.bots={p};a.pickups={['2,2']='cache'};R.collect(a,p);assert(p.draw_bonus==1 and not a.pickups['2,2']);R.collect(a,p);assert(p.draw_bonus==1);a.pickups['2,2']='jammer';R.collect(a,p);C.deal(p);assert(#p.hand==8) end)
test('reboot penalty applies to next draw',function() local p=b('p',2,2);local a=s();a.bots={p};R.drop(p);R.respawn(a);C.deal(p);assert(#p.hand==8);C.deal(p);assert(#p.hand==9) end)
test('modules extend the draw pool',function() local p=b('p',2,2);p.hp=5;p.blink=true;p.draw_bonus=3;C.deal(p,function() return 1 end);local found=false;for _,c in ipairs(p.hand) do if c=='BLINK' then found=true end end;assert(#p.hand==12);local total=0;for i=1,50 do C.deal(p);for _,c in ipairs(p.hand) do if c=='BLINK' then total=total+1 end end end;assert(total>0) end)
test('campaign enemies use player hull and reboot',function() for level=1,3 do local a=C.setup(R,level,'campaign');C.enemies(a);assert(#a.bots==level);local e=a.bots[1];e.down=true;R.respawn(a);assert(not e.down and e.hp==5 and e.max_hp==5) end end)
test('enemy plan always five legal commands',function() local a=C.setup(R,3,'campaign');a.bots={b('p',2,2)};C.enemies(a);for _,e in ipairs(a.bots) do if e.enemy then local program=C.plan(R,a,e);assert(#program==5) end end end)
print(n..' expansion tests passed')
''')
