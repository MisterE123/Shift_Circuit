from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().path=(root/'mods/shift_circuit').as_posix()
lua.execute('''
local R=dofile(path..'/rules.lua');local C=dofile(path..'/campaign.lua');local U=dofile(path..'/dashboard_ui.lua')({get_modpath=function()return path end,formspec_escape=tostring},R)
local a={id='a',hp=5,dir=0,parts={reset_button=2,blink=1,hard_disk=1}};local b={id='b',hp=5,dir=0,parts={}};local s={round=1,bots={a,b}}
C.deal_round(s);a.start_direction='LEFT';a.selected={2};a.program={a.hand[2]};a.program_ids={a.hand_ids[2]};a.keep={3}
local original={};for _,id in ipairs(a.hand_ids)do original[id]=true end;local other=table.concat(b.hand_ids,',');local blink=a.hand_ids[1];local count=#a.hand
assert(U.changed({use_reset=true}));assert(U.formspec(a,'program'):find('use_reset;RESET HAND',1,true))
assert(C.reset_hand(s,a));assert(a.parts.reset_button==1 and #a.hand==count and #a.program==0 and #a.selected==0 and #a.keep==0)
assert(a.hand[1]=='BLINK'and a.hand_ids[1]==blink and a.start_direction=='LEFT');assert(table.concat(b.hand_ids,',')==other)
for i=2,#a.hand do assert(not original[a.hand_ids[i]],'fresh IDs from round deck')end
local seen={};for _,bot in ipairs(s.bots)do for _,id in ipairs(bot.hand_ids)do assert(not seen[id]);seen[id]=true end end
for _,card in ipairs(s.draw_pile)do assert(not seen[card.id]);seen[card.id]=true end
s.puzzle={hands={['1']={'WAIT'}}};assert(not C.reset_hand(s,a)and a.parts.reset_button==1);s.puzzle=nil
a.ready=true;assert(not C.reset_hand(s,a));a.ready=false
assert(C.reset_hand(s,a)and a.parts.reset_button==0);assert(not C.reset_hand(s,a))
a.parts.reset_button=1;s.draw_pile={};assert(not C.reset_hand(s,a)and a.parts.reset_button==1)
print('PASS Reset Button redraw, consumption, program/reservation clearing, direction/Blink preservation, unique IDs, other hands unchanged and guards')
''')

lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
lua.execute('''
local api=dofile(modpath..'/runtime.lua')(core,{test_lab=true});callbacks.on_mods_loaded();flush();newplayer('Admin');flush()
core.get_player_privs=function()return {server=true}end
assert(api.lab('Admin','weapons'));local before=api.snapshot().state;local b
for _,v in ipairs(before.bots)do if v.id=='Admin'then b=v end end
assert(b.parts.reset_button==2)
api.queue('Admin',1);callbacks.on_player_receive_fields(clients.Admin,'shift_circuit:loadout',{use_reset=true})
local after=api.snapshot().state;for _,v in ipairs(after.bots)do if v.id=='Admin'then assert(v.parts.reset_button==1 and #v.program==0)end end
print('PASS dashboard Reset Button runtime event consumes item and refreshes program')
''')
