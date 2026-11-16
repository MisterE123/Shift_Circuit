from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
lua.execute("""
local Cards=dofile(modpath..'/card_text.lua');local api=dofile(modpath..'/runtime.lua')(core,{})
callbacks.on_mods_loaded();flush();local p=newplayer('Pilot');flush();assert(api.start('Pilot','race',1))
local s;for i=1,30 do local k,v=debug.getupvalue(api.snapshot,i);if k=='S'then s=v end end
local b=s.bots[1];b.hand={'STEP','DASH','MOVE3','BACK','BACK2','LEFT','RIGHT','UTURN','WAIT','BLINK'};b.hand_ids={1,2,3,4,5,6,7,8,9,10};b.keep={1};b.parts.blink=1;b.blink_left=1
for i,c in ipairs(b.hand)do
 p.wield=i+1;callbacks.on_player_receive_fields(p,'shift_circuit:loadout',{apply=true})
 local description=p.inv.list[i+1].m:get_string('description')
 assert(description:find(Cards.descriptions[c],1,true)and description:find('Priority ID '..i,1,true),'inventory keeps consistent wording and priority')
 assert(tools['shift_circuit:card_'..c:lower()].description==Cards.tooltip(c),'base tool uses shared description')
 local found=false;for _,h in ipairs(p.hud)do if (h.text or ''):find(Cards.descriptions[c],1,true)then found=true end end;assert(found,'HUD uses identical command wording')
 assert(not description:find('collect along',1,true),'no obsolete mid-movement collection wording')
end
assert(p.inv.list[2].m:get_string('description'):find('RETAIN NEXT ROUND',1,true),'retained cards keep their descriptions')
print('PASS consistent tool, inventory and HUD card descriptions, retained cards and priority IDs')
""")
