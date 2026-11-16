from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
lua.execute("""
local add=core.add_entity;core.add_entity=function(p)local o=add(p);function o:set_observers(v)self.observers=copy(v)end;return o end
local api=dofile(modpath..'/runtime.lua')(core,{is_spectator=function(n)return n=='Viewer'end});callbacks.on_mods_loaded();flush();local a=newplayer('Alpha');local b=newplayer('Beta');flush();assert(api.start('Alpha','race',1))
local s;for i=1,30 do local k,v=debug.getupvalue(api.snapshot,i);if k=='S'then s=v end end
local R=dofile(modpath..'/rules.lua');s.walls={};s.overhead={};s.lasers={};s.pushers={};s.crates={}
for z=1,s.size do for x=1,s.size do s.board[R.key(x,z)]={kind='floor'}end end
local alpha,beta=s.bots[1],s.bots[2];alpha.x=3;alpha.z=3;beta.x=5;beta.z=3
callbacks.on_player_receive_fields(a,'shift_circuit:loadout',{apply=true})
local function notice(p)for _,h in ipairs(p.hud)do if h.text=='Ghost mode: inter-bot collision disabled'then return true end end;return false end
assert(notice(a)and notice(b),'ghost HUD visible for each pilot')
for _,o in ipairs(objects)do if o.p and o.e.robot then
 assert(o.props.use_texture_alpha and o.props.textures[1]:find('opacity:150',1,true),'opponent model translucent')
 assert(o.e.display_scale==1 and o.e.destination.y==1,'independent ghost stays full size on its tile')
 local own=o.e.owner_view;assert(own and own.props.use_texture_alpha and own.props.textures[1]:find('opacity:150',1,true),'owner sees translucent model too')
 assert(o.e.mounts.weapon.props.textures[1]:find('opacity:150',1,true),'weapon is translucent too')
end end
local viewer=newplayer('Viewer');flush();beta.x=alpha.x
callbacks.on_player_receive_fields(a,'shift_circuit:loadout',{apply=true})
for _,name in ipairs({'Alpha','Beta','Viewer'})do
 local full,small=0,0
 for _,o in ipairs(objects)do if o.p and o.e.robot then
  if o.observers and o.observers[name]then if o.e.display_scale==1 then full=full+1 else small=small+1 end end
  local own=o.e.owner_view;if own and own.observers[name]then full=full+1;assert(own.e.destination.y==1,'grounded model stays on square')end
 end end
 assert(full==1 and small==1,'exactly one full-size robot for group members and outside spectators: '..name)
end
beta.x=5;callbacks.on_player_receive_fields(a,'shift_circuit:loadout',{apply=true})
for _,o in ipairs(objects)do if o.p and o.e.robot and o.e.owner_view then assert(not o.e.owner_view.observers.Viewer,'representative view removed when group splits')end end
s.round=2;beta.x=3;R.ghosts(s,true)
for i,bot in ipairs(s.bots)do bot.dir=1;bot.hand={i==1 and 'STEP'or 'WAIT','WAIT','WAIT','WAIT','WAIT'};bot.hand_ids={90-i,20+i,30+i,40+i,50+i};for j=1,5 do api.queue(bot.id,j)end end
api.commit('Alpha');api.commit('Beta')
for i=1,300 do tick(.05);if api.phase()=='presses'then break end end
assert(api.phase()=='presses'and alpha.x~=beta.x and alpha.ghost and beta.ghost and notice(a),'ghost persists through final hazard animation')
for i=1,60 do tick(.05);if api.phase()=='reading'then break end end
assert(api.phase()=='reading'and not alpha.ghost and not beta.ghost and not notice(a)and not notice(b),'register completion clears collision grace and HUD')
for _,o in ipairs(objects)do if o.p and o.e.robot then assert(not o.props.textures[1]:find('opacity:',1,true)and not o.e.owner_view.props.textures[1]:find('opacity:',1,true),'solid body textures restored')end end
print('PASS ghost body/equipment transparency, full-size independent ghosts, per-player HUD, and register-boundary opacity/collision restoration')
""")
