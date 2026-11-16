from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
lua.execute('''
local R=dofile(modpath..'/rules.lua');local L=dofile(modpath..'/levels.lua');local Q=dofile(modpath..'/courses.lua')
for parity=0,1 do for slot=1,5 do
 local s=L.blank(10);s.round=2;s.overhead['4,4']={kind='crusher',parity=parity};s.overhead['5,4']={kind='crusher',parity=parity};s.bots={{id='robot',x=4,z=4,dir=0,hp=5,parts={},next=1}};s.crates['5,4']={kind='steel'};R.init_objects(s);R.hazards(s,slot)
 assert((s.bots[1].down==true)==(slot%2==parity));assert((s.crates['5,4'].kind=='loot')==(slot%2==parity),'crate conversion follows crusher schedule')
end end
local d=L.blank(10);d.overhead['4,4']={kind='crusher',parity=1};d.overhead['5,4']={kind='crusher'};local valid,err=L.validate(d);assert(valid,err);assert(valid.overhead['4,4'].parity==1 and valid.overhead['5,4'].parity==0)
assert(L.resize(valid,20).overhead['4,4'].parity==1);local course=Q.layout(R,{valid,valid},3,{{x=0,z=0},{x=1,z=0}});assert(course.overhead['14,4'].parity==1)
d.overhead['4,4'].parity=2;assert(not L.validate(d))
print('PASS odd/even crusher register timing for robots and crates, legacy even defaults, validation, resize and assembled courses')
''')
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix();lua.execute(source)
lua.execute('''
local api=dofile(modpath..'/runtime.lua')(core);callbacks.on_mods_loaded();flush();newplayer('Pilot');flush();local d=dofile(modpath..'/levels.lua').blank(10);d.overhead['4,4']={kind='crusher',parity=1};d.overhead['5,4']={kind='crusher'};api.edit_level(d,true)
local odd,even;for _,o in ipairs(objects)do if o.p and o.props.mesh=='sc_ram.obj'then if o.e.hint:find('Crusher Odd',1,true)then odd=o elseif o.e.hint:find('Crusher Even',1,true)then even=o end end end;assert(odd and even)
for i=1,5 do api.queue('Pilot',i)end;api.commit('Pilot');local seen={}
for i=1,900 do tick(.05);local snap=api.snapshot();if snap.phase=='presses'then local slot=snap.slot;seen[slot]=true;assert(odd.e.target.y==(slot%2==1 and 1 or 4.3));assert(even.e.target.y==(slot%2==0 and 1 or 4.3))end;if snap.state.round>1 then break end end
for i=1,5 do assert(seen[i],'all crusher register animations checked')end
print('PASS crusher labels and actual execution animations match odd/even rules on all five registers')
''')
