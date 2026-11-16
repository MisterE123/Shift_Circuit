from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().path=(root/'mods/shift_circuit').as_posix()
lua.execute("""
local U=dofile(path..'/menu_ui.lua')
for _,size in ipairs({'12,5','12,6','14,7','14,10','14,11','16,11.3','16,12'})do
 local f='formspec_version[6]size['..size..']background[0,0;'..size..';sc_setup_background.png]button[1,2;4,.8;launch;START RACE]button[1,3;4,.8;delete_entry;DELETE ENTRY]button[1,4;4,.8;tab_1;> OBJECTIVES]'
 local out=U.decorate(f);assert(out:find('sc_ui_frame.png',1,true)and not out:find('sc_setup_background.png',1,true))
 assert(out:find('style[launch;bgimg=sc_ui_primary.png]',1,true))
 assert(out:find('style[delete_entry;bgimg=sc_ui_danger.png]',1,true))
 assert(out:find('style[tab_1;bgimg=sc_ui_selected.png]',1,true))
 assert(U.decorate(out)==out,'themed inventory and popup forms do not duplicate chrome')
end
local delivered;local engine={show_formspec=function(n,k,f)delivered=f end};local themed=U.wrap(engine)
themed.show_formspec('Pilot','shift_circuit:test','size[12,6]label[1,1;TEST]')
assert(delivered:find('sc_ui_frame.png',1,true));assert(U.wrap(themed)==themed)
assert(engine._sc_menu_theme==nil,'other mods are not globally restyled')
print('PASS shared menu theme sizes, semantic button colors, idempotence and scoped formspec wrapping')
""")
for name in ['frame','panel','button','hover','pressed','selected','primary','danger']:
 assert (root/'art/ui/menu'/f'{name}.png').exists()
 assert (root/'mods/shift_circuit/textures'/f'sc_ui_{name}.png').exists()

# Corner artwork must not cross the nine-slice stretch bands.
from PIL import Image
for name in ['frame','panel','button','selected','selected_hover','selected_pressed']:
 im=Image.open(root/'art/ui/menu'/f'{name}.png')
 for y in range(32): assert len({im.getpixel((x,y)) for x in range(8,24)})==1
 for x in range(32): assert len({im.getpixel((x,y)) for y in range(8,24)})==1
lua.execute(r"""
local U=dofile(path..'/menu_ui.lua')
local a,b=U.scroll(0,0,8,6,'test_scroll',18.4)
assert(a:find('max=124;',1,true)and b=='scroll_container_end[]')
local a,b=U.scroll(0,0,8,6,'test_scroll',2)
assert(a=='container[0,0]'and b=='container_end[]')
local out=U.decorate('size[14,10]field[1,2;4,.7;name;Name;]button[1,3;1,.6;n;\\[2\\]]')
assert(out:find('style[n;bgimg=sc_ui_selected.png]',1,true))
assert(out:find('border=true;textcolor=#eff9f5',1,true))
local callback;local calls=0;local engine={show_formspec=function()end,register_on_player_receive_fields=function(fn)callback=fn end}
local wrapped=U.wrap(engine);wrapped.register_on_player_receive_fields(function()calls=calls+1 end)
callback({get_player_name=function()return 'Tester'end},'form',{test_scroll='CHG:12'})
assert(calls==0,'scrolling must not activate buttons or sounds')
""")
