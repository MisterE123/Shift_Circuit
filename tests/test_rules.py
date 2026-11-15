"""Run with Python + lupa. Exercise the actual Lua rules, not a translated copy."""
from pathlib import Path
from lupa import LuaRuntime
lua=LuaRuntime(unpack_returned_tuples=True)
lua.globals().R=lua.execute((Path(__file__).resolve().parents[1]/'mods/shift_circuit/rules.lua').read_text())
lua.execute('''
local function bot(id,x,z) return {id=id,x=x,z=z,dir=1,next=1,damage=0,home={x=x,z=z},program={}} end
local function fixture() local s=R.arena(); s.board={}; for x=1,11 do for z=1,11 do s.board[R.key(x,z)]={kind='floor'} end end; return s end
local n=0
local function test(name,fn) fn(); n=n+1; print('PASS '..name) end
test('push chain',function() local s=fixture(); local a,b,c=bot('a',2,2),bot('b',3,2),bot('c',4,2); s.bots={a,b,c}; assert(R.move(s,a,1)); assert(a.x==3 and b.x==4 and c.x==5) end)
test('blocked chain is atomic',function() local s=fixture(); local a,b=bot('a',2,2),bot('b',3,2); s.bots={a,b}; s.board['4,2']={kind='wall'}; assert(not R.move(s,a,1)); assert(a.x==2 and b.x==3) end)
test('pit and dash stop',function() local s=fixture(); local a=bot('a',2,2); s.bots={a}; s.board['3,2']={kind='pit'}; R.command(s,a,'DASH'); assert(a.down and a.x==3 and a.damage==1) end)
test('turn and reverse',function() local s=fixture(); local a=bot('a',3,3); s.bots={a}; R.command(s,a,'LEFT'); assert(a.dir==0); R.command(s,a,'BACK'); assert(a.z==2); R.command(s,a,'RIGHT'); assert(a.dir==1) end)
test('belts move once',function() local s=fixture(); local a,b=bot('a',2,2),bot('b',3,2); s.bots={a,b}; s.board['2,2']={kind='belt',dir=1}; s.board['3,2']={kind='belt',dir=1}; R.belts(s); assert(a.x==3 and b.x==4) end)
test('press active only on even pulses',function() local s=fixture(); local a=bot('a',2,2); s.bots={a}; s.board['2,2']={kind='press'}; R.hazards(s,1); assert(not a.down); R.hazards(s,2); assert(a.down) end)
test('ordered stations and victory',function() local s=fixture(); local a=bot('a',2,2); s.bots={a}; s.board['2,2']={kind='station',number=2}; R.hazards(s,1); assert(a.next==1); for i=1,3 do s.board['2,2'].number=i; R.hazards(s,1) end; assert(s.winner=='a' and a.next==4) end)
test('respawn ghosts an occupied checkpoint',function() local s=fixture(); local a,b=bot('a',2,2),bot('b',2,2); s.bots={a,b}; a.down=true; R.respawn(s); assert(not a.down and a.x==b.x and a.z==b.z and a.ghost and b.ghost) end)
test('priority rotates with round',function() local s=fixture(); s.bots={bot('a',2,2),bot('b',3,2)}; assert(R.order(s)[1].id=='a'); s.round=2; assert(R.order(s)[1].id=='b') end)
test('off-board movement drops robot',function() local s=fixture(); local a=bot('a',11,2); s.bots={a}; R.move(s,a,1); assert(a.down) end)
print(n..' rules tests passed')
''')
for p in (Path(__file__).resolve().parents[1]/'mods').rglob('*.lua'):
    lua.execute('assert(load(...))',p.read_text())
print('All Lua files parse.')
