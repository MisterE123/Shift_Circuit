from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
lua.execute('''
core.deserialize=function(v)return type(v)=='table'and copy(v)or nil end
local store=core.get_mod_storage();local L=dofile(modpath..'/levels.lua');local catalog={}
for i,title in ipairs({'Factory',' factory ','FACTORY','Factory (2)',string.rep('A',48),string.rep('a',48)})do
 local d=L.blank(10);d.title=title;d.board['4,4']={kind=i%2==0 and 'pit'or 'floor'}
 catalog[tostring(i)]={data=d,author='User'..i,approved=i%2==0,notes={{reviewer='Admin',text='Original review'}}}
end
store:set_string('level_catalog',copy(catalog));store:set_string('draft:User2',copy(catalog['2'].data));store:set_string('draft_meta:User2',{entry_id='2',locked=true})
store:set_string('course_configurations',{route={layout={items={{id='level_2'}}}}})
local function load()return dofile(modpath..'/editor.lua')(core,store,function()end,function()end)end
local e=load();assert(e.catalog['1'].data.title=='Factory');assert(e.catalog['4'].data.title=='Factory (2)')
assert(e.catalog['2'].data.title=='factory (3)'and e.catalog['3'].data.title=='FACTORY (4)')
local names={};for id,v in pairs(e.catalog)do local key=v.data.title:lower();assert(not names[key]);names[key]=true;assert(#v.data.title<=48)
 assert(v.approved==catalog[id].approved and v.author==catalog[id].author);assert(same(v.data.board,catalog[id].data.board));assert(v.notes[1].text=='Original review')
end
assert(#e.catalog['2'].notes==2);assert(store:get_string('draft:User2').title=='factory (3)')
assert(store:get_string('course_configurations').route.layout.items[1].id=='level_2')
local snapshot=copy(e.catalog);e=load();assert(same(e.catalog,snapshot),'migration is idempotent and does not repeat notes')
print('PASS legacy arena duplicates: deterministic unique names, existing suffix reservation, length limit, linked drafts, stable IDs/content/approval/references, and repeatable migration')
''')
