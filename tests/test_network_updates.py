from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1]
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0]
def measure(cached):
 lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix();lua.execute(source)
 if not cached:
  lua.execute("local real=dofile;dofile=function(p)local m=real(p);if p:find('network_updates.lua',1,true)then m.hud=function(player,cache,id,key,value)player:hud_change(id,key,value)end;m.properties=function(o,v)o:set_properties(v)end end;return m end")
 lua.execute('''
 local api=dofile(modpath..'/runtime.lua')(core);callbacks.on_mods_loaded();flush();local p=newplayer('Pilot');flush()
 local L=dofile(modpath..'/levels.lua');local d=L.blank(10);d.map_type='puzzle';d.puzzle={checkpoints={'8,3'},equipment={turret_gearbox=1},hands={['1']={'STEP','WAIT','WAIT','WAIT','WAIT'}}};d=assert(L.validate_submission(d));api.edit_level(d,true)
 for i=1,20 do tick(.05)end
 hud_packets=0;property_packets=0
 local original=p.hud_change;p.hud_change=function(self,...)hud_packets=hud_packets+1;return original(self,...)end
 for _,o in ipairs(objects)do local set=o.set_properties;o.set_properties=function(self,...)property_packets=property_packets+1;return set(self,...)end end
 for i=1,100 do tick(.05)end
 idle_hud=hud_packets;idle_properties=property_packets
 api.queue('Pilot',1);assert(hud_packets>idle_hud,'card selection sends its HUD change immediately, without waiting for a tick')
 ''')
 return lua.globals().idle_hud,lua.globals().idle_properties
before=measure(False);after=measure(True)
assert after[0]<before[0]*.1 and after[1]<before[1]*.1,(before,after)
print('PASS 5-second idle outbound calls HUD/properties:',before,'->',after,'; immediate card feedback preserved')


# Interpolation requests preserve their continuous flag; wrapped loops snap.
lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().path=(root/'mods/shift_circuit/network_updates.lua').as_posix()
lua.execute("""
local N=dofile(path);local moves,snaps=0,0;local o={p={x=0,y=0,z=0}}
function o:get_pos()return self.p end
function o:move_to(p,continuous)assert(continuous);moves=moves+1;self.p=p end
function o:set_pos(p)snaps=snaps+1;self.p=p end
N.move(o,{x=.1,y=0,z=0});N.move(o,{x=.1,y=0,z=0});assert(moves==1 and snaps==0)
N.move(o,{x=2,y=0,z=0},.5);assert(snaps==1,'loop wrap must not slide across the tile')
N.move(o,{x=2.1,y=0,z=0},.5);assert(moves==2)
print('PASS continuous client interpolation, stationary suppression and intentional loop-wrap snaps')
""")
