from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
lua.execute("""
local api=dofile(modpath..'/runtime.lua')(core,{});callbacks.on_mods_loaded();flush();local p=newplayer('Pilot');flush();assert(api.start('Pilot','race',1))
local s;for i=1,30 do local k,v=debug.getupvalue(api.snapshot,i);if k=='S'then s=v end end
local R=dofile(modpath..'/rules.lua');local b=s.bots[1];s.lasers={};s.overhead={};s.pushers={};s.bots={b};s.board[R.key(b.x,b.z)]={kind='repair'}
b.hp=1;b.max_hp=8;b.energy=0;b.hand={'WAIT','WAIT','WAIT','WAIT','WAIT'};b.hand_ids={1,2,3,4,5}
for i=1,5 do api.queue('Pilot',i)end;api.commit('Pilot')
for i=1,300 do tick(.05);if api.phase()=='presses'then break end end
assert(b.hp==1,'no early healing before register completes')
for i=1,80 do tick(.05);if api.phase()=='reading'then break end end
assert(b.hp==2 and b.energy==0,'first register heals exactly one and does not recharge')
for i=1,1500 do tick(.05);if s.round==2 then break end end
assert(s.round==2 and b.hp==8 and b.energy==9,'round completion fully restores even a larger hull')
b.hp=1;b.energy=0;b.down=true;R.register_repairs(s);R.repairs(s);assert(b.hp==1 and b.energy==0,'cannot revive destroyed robots')
b.down=nil;b.finished=true;R.register_repairs(s);R.repairs(s);assert(b.hp==1 and b.energy==0,'finished racers excluded')
b.finished=nil;s.board[R.key(b.x,b.z)]={kind='floor'};R.register_repairs(s);R.repairs(s);assert(b.hp==1 and b.energy==0,'only medkit square occupants benefit')
print('PASS medkit register-end timing, +1 healing, full round-end hull/power, custom hull maximum and destroyed/finished/off-pad exclusions')
""")
