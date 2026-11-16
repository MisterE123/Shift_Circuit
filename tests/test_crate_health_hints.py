from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
lua.execute('''
local api=dofile(modpath..'/runtime.lua')(core);callbacks.on_mods_loaded();flush();local player=newplayer('Pilot');flush()
local R=dofile(modpath..'/rules.lua');local L=dofile(modpath..'/levels.lua');local d=L.blank(10);d.map_type='puzzle';d.puzzle={hint='Use a turn card to face the checkpoint, then move forward.',checkpoints={'8,3'},hands={['1']={'WAIT','WAIT','WAIT','WAIT','WAIT'}}};d.crates['4,4']={kind='loot'};d.crates['5,4']={kind='steel'};d.overhead['5,4']={kind='crusher',parity=1};d=assert(L.validate_submission(d));assert(d.puzzle.hint:find('turn card'));assert(L.resize(d,20).puzzle.hint==d.puzzle.hint)
api.edit_level(d,true);local s;for i=1,30 do local k,v=debug.getupvalue(api.snapshot,i);if k=='S'then s=v end end
local hint,background;for _,h in ipairs(player.hud)do if h.text and h.text:find('Use a turn card',1,true)then hint=h end;if h.text=='sc_puzzle_hint.png'then background=h end end;assert(hint and background,'optional hint shown during play');assert(background.position.x==1 and background.position.y==1 and background.alignment.x==-1 and background.alignment.y==-1,'hint panel anchors to bottom right')
local lootbar;for _,o in ipairs(objects)do if o.p and o.e.health_bot and o.e.health_bot.crate then assert(o.e.health_bot.kind=='loot');lootbar=o end end;assert(lootbar and lootbar.props.textures[1]=='sc_crate_health_3.png')
local c=s.crates['4,4'];R.crate_hit(s,c);tick(.1);assert(lootbar.props.textures[1]=='sc_crate_health_2.png');R.crate_hit(s,c);tick(.1);assert(lootbar.props.textures[1]=='sc_crate_health_1.png')
local actor=lootbar.e.health_actor;actor:set_pos({x=20,y=1,z=16});callbacks.entity.on_step(lootbar.e,.1);assert(lootbar.p.x==20 and lootbar.p.z==16 and math.abs(lootbar.p.y-2.05)<.001)
R.crate_hit(s,c);tick(.1);assert(not lootbar.props.is_visible,'broken crate bar hidden')
for i=1,5 do api.queue('Pilot',i)end;api.commit('Pilot');for i=1,180 do tick(.1);if api.snapshot().phase=='presses'then break end end
local steelbar;for _,o in ipairs(objects)do if o.p and o.e.health_bot==s.crates['5,4']then steelbar=o end end;assert(steelbar and steelbar.props.textures[1]=='sc_crate_health_3.png','converted steel crate gains a fresh health bar')
api.edit_level(d,false);assert(hint.text==''and background.text=='','builder HUD stays clear')
d.puzzle.hint='';api.edit_level(d,true);assert(hint.text==''and background.text=='','empty optional hint has no panel')
print('PASS loot health 3/2/1, moving crate bars, destruction hiding, steel conversion, puzzle hint persistence/play HUD and builder/empty-hint hiding')
''')
