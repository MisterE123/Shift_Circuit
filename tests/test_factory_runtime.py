from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
lua.execute("""
local api=dofile(modpath..'/runtime.lua')(core,{});callbacks.on_mods_loaded();flush();newplayer('Pilot');flush()
local L=dofile(modpath..'/levels.lua');local R=dofile(modpath..'/rules.lua');local d=L.blank(10)
d.board['3,4']={kind='belt',dir=1,speed=1};d.pickups={['3,4']='cell',['4,4']='shield'}
d.board['3,7']={kind='factory',pattern='one',crate_kind='steel',dir=1};d.walls[R.edge(4,7,1)]=true
d.crates['8,8']={kind='loot',item='repair'};d.overhead['8,8']={kind='crusher',parity=1}
api.edit_level(d,true)
local cell,shield,factory;for _,o in ipairs(objects)do if o.p then if o.props.mesh=='sc_pickup_cell.obj'then cell=o elseif o.props.mesh=='sc_pickup_shield.obj'then shield=o elseif o.props.mesh=='sc_factory_one.obj'then factory=o end end end
assert(cell and shield and factory and factory.e.lamps[1],'factory mesh and facing indicator created')
local s;for i=1,30 do local k,v=debug.getupvalue(api.snapshot,i);if k=='S'then s=v end end
local b=s.bots[1];b.hand={'WAIT','WAIT','WAIT','WAIT','WAIT'};for i=1,5 do api.queue('Pilot',i)end;api.commit('Pilot')
for i=1,100 do tick(.05);if api.phase()=='belts'then break end end
assert(cell.e.pickup_motion and shield.e.pickup_motion,'conveyor chain animates both original entities')
local old=cell.p.x;tick(.15);assert(cell.p.x>old and cell.p.x<8.5,'pickup interpolates rather than teleporting')
for i=1,200 do tick(.05);if api.phase()=='pushers'and s.register==1 then break end end
local crate=R.at(s,4,7);assert(crate and crate.crate and crate.spawn_from,'factory emits a crate')
local emerging=false;for _,o in ipairs(objects)do if o.p and o.props.mesh=='sc_crate_steel.obj'and o.e.target and o.e.target.x==8.5 then emerging=true;assert(o.p.x<o.e.target.x,'crate visibly emerges from mouth')end end;assert(emerging)
for i=1,200 do tick(.05);if api.phase()=='presses'and s.register==1 then break end end;assert(s.pickups['8,8']=='repair')
for i=1,400 do tick(.05);if api.phase()=='pushers'and s.register==2 then break end end
assert(s.board['3,7'].output_serial==1,'factory has only one production batch per round');assert(factory.e.schedule_badge==nil,'factories have no floating production badge')
for i=1,400 do tick(.05);if api.phase()=='presses'and s.register==3 then break end end;assert(not s.pickups['8,8'])
for _,o in ipairs(objects)do if o.p then assert(not (o.props.mesh=='sc_pickup_repair.obj'and o.e.hover),'crushed powerup visual removed')end end
print('PASS animated powerup chain, factory mouth emergence, directional jam lamps and staged crusher pickup lifecycle')
""")
