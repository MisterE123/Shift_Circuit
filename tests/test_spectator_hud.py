from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r\'\'\'",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
lua.execute("""
local api=dofile(modpath..'/runtime.lua')(core,{is_spectator=function(n)return n=='Watcher'end})
callbacks.on_mods_loaded();flush();local a=newplayer('Alpha');local b=newplayer('Beta');local g=newplayer('Gamma');local w=newplayer('Watcher');flush();assert(api.start('Alpha','race',1));tick(.2)
local S;for i=1,30 do local k,v=debug.getupvalue(api.snapshot,i);if k=='S'then S=v end end
local alpha,beta;for _,q in ipairs(S.bots)do if q.id=='Alpha'then alpha=q elseif q.id=='Beta'then beta=q end end
assert(alpha and beta and api.watch('Watcher'));assert(api.watching('Watcher')=='Alpha')
assert(w.attached and w.inv.list[2].name=='shift_circuit:spectate_switch')
assert(not api.watch('Alpha')and not api.watch_next('Alpha',1),'active player cannot spectate')
local before=copy(alpha.program);tools['shift_circuit:spectate_switch'].on_use(ItemStack(''),a);assert(not api.watching('Alpha')and same(before,alpha.program))
assert(api.watch_next('Watcher',1)and api.watching('Watcher')=='Beta')
beta.hp=2;beta.energy=3;beta.program={'RIGHT','WAIT'};beta.program_ids={731,732};tick(.2)
local function has(p,text)for _,h in ipairs(p.hud)do if h.text==text then return true end end end
assert(has(w,'sc_stat_hull_2.png')and has(w,'sc_stat_energy_3.png'),'watched gauges')
assert(not has(w,'sc_your_robot.png'),'no false ownership marker')
local hasname=false;for _,h in ipairs(w.hud)do if type(h.text)=='string'and h.text:find('WATCHING Beta',1,true)then hasname=true end end;assert(hasname,'watched identity')
local watched_entity=w.attached.e.follow_object
assert(watched_entity.e.robot,'follows real robot')
local original=copy(beta.program);api.queue('Watcher',1);api.commit('Watcher');assert(same(original,beta.program),'spectator cannot program watched robot')
callbacks.on_player_receive_fields(w,'shift_circuit:loadout',{enable_gyro_stabilizer='true'});assert(same(original,beta.program))
beta.finished=true;tick(.2);assert(api.watching('Watcher')~='Beta','finished targets skipped automatically')
alpha.finished=true;assert(api.watch('Alpha'),'finished player may spectate');assert(a.inv.list[2].name=='shift_circuit:spectate_switch')
local target=api.watching('Alpha');assert(target and target~='Alpha')
-- A removed/replaced target actor is rebound instead of following a dead object.
local old=a.attached.e.follow_object;old:remove();old.get_luaentity=function()return nil end;tick(.2);assert(a.attached.e.follow_object:get_pos(),'respawn/recreated entity rebound')
local gamma;for _,q in ipairs(S.bots)do if q.id=='Gamma'then gamma=q end end
gamma.hand={'WAIT','WAIT','WAIT','WAIT','WAIT'};gamma.selected={};gamma.program={};gamma.ready=false
for i=1,5 do api.queue('Gamma',i)end;api.commit('Gamma')
for i=1,600 do tick(.1);if S.round==2 then break end end
assert(S.round==2 and w.attached and api.watching('Watcher')=='Gamma','spectator stays attached across round boundary')
assert(w.inv.list[2].name=='shift_circuit:spectate_switch','switch tool remains during planning')
for _,q in ipairs(S.bots)do q.finished=true end;tick(.2);assert(not api.watching('Watcher')and not w.attached,'empty match releases camera')
print('PASS spectator target switching, watched HUD, ownership, active-player restrictions, read-only input, finished targets, actor recovery and empty match')
""")

