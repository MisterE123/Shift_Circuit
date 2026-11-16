from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
lua.execute("""
local R=dofile(modpath..'/rules.lua');local api=dofile(modpath..'/runtime.lua')(core,{})
callbacks.on_mods_loaded();flush();newplayer('Pilot');flush();assert(api.start('Pilot','race',1))
local s;for i=1,30 do local k,v=debug.getupvalue(api.snapshot,i);if k=='S'then s=v end end
s.round=1;s.lasers={{x=2,z=3,dir=1,power=1}};s.walls={[R.edge(7,3,1)]=true};s.crates={};s.overhead={}
for x=1,s.size do for z=1,s.size do s.board[R.key(x,z)]={kind='floor'}end end
local player=s.bots[1];player.x=4;player.z=3;player.hp=5;player.shield=0;player.parts={}
s.bots={player,{id='Racer',enemy=true,racing=true,x=5,z=3,hp=5}}
local function length()for i=1,8 do tick(.05)end;for _,o in ipairs(objects)do if o.p and o.e.preview_tint=='#804232'then return o.e.preview_length end end end
assert(length()==6,'planning preview traverses player and AI racer to the wall')
assert(player.hp==5 and #s.bots==2,'preview never changes actual occupants or health')
R.lasers(s);assert(player.hp==4,'actual laser still hits the player')
s.crates={box={id='box',crate=true,kind='steel',x=6,z=3}}
assert(length()==4.25,'crates still block the preview')
s.crates={};s.bots[2].racing=false
assert(length()==3.25,'non-racing enemies still block the preview')
print('PASS planning board lasers ignore human/AI racers, respect walls/crates/enemies, and retain execution damage')
""")
