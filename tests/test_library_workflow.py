from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0]
lua.execute(source)
lua.execute('''
local store=core.get_mod_storage();core.deserialize=function(v)return type(v)=='table'and copy(v)or nil end
core.get_player_privs=function(n)return {server=n=='Admin'}end
local room={solo_mode='editor',host='Author',api={phase=function()return 'editor'end,edit_level=function()end}}
local function create()return dofile(modpath..'/editor.lua')(core,store,function()return room end,function()end)end
local e=create();clients.Author={};clients.Other={};clients.Admin={}
local function fields(n,f,form)callbacks.on_player_receive_fields({get_player_name=function()return n end},form or 'shift_circuit:editor',f)end
local function count()local n=0;for _ in pairs(e.catalog)do n=n+1 end;return n end
e.begin(room);assert(clients.Author.shown:find('SAVE TO LIBRARY'));assert(not clients.Author.shown:find('EXPORT JSON')and not clients.Author.shown:find('EXPORT AS MOD'))
fields('Author',{save_library=true,title='First Puzzle'});local id=e.draft('Author').entry_id;assert(id and count()==1 and e.catalog[id].status=='saved')
fields('Author',{submit=true});assert(count()==1 and e.catalog[id].status=='pending')
assert(not e.review('Other',id,'enable'));assert(e.review('Admin',id,'reject','Move the checkpoint.'))
fields('Author',{library=true});assert(clients.Author.shown:find('REJECTED'))
fields('Author',{['load_'..id]=true},'shift_circuit:levels');fields('Author',{edit_entry=true});fields('Author',{confirm=true},'shift_circuit:draft_confirm')
assert(e.draft('Author').entry_id==id);fields('Author',{rename=true,title='Repaired Puzzle'});assert(count()==1 and e.catalog[id].data.title=='Repaired Puzzle'and e.catalog[id].status=='revised'and #e.catalog[id].notes==1)
assert(clients.Author.shown:find('REVIEW NOTES'));fields('Author',{review_notes=true});assert(clients.Author.shown:find('Move the checkpoint.'))
fields('Author',{submit=true});assert(e.catalog[id].status=='pending');assert(e.review('Admin',id,'enable'));fields('Author',{save_library=true});assert(e.catalog[id].approved,'unchanged save preserves approval')
fields('Author',{b2=true});e.paint('Author',4,4);fields('Author',{save_library=true});assert(e.catalog[id].approved,'non-admin edits cannot disable enabled entry');assert(e.review('Admin',id,'disable'));fields('Author',{save_library=true});assert(not e.catalog[id].approved and e.catalog[id].status=='revised','edited content is private until explicit resubmission')
e=create();e.begin(room);assert(e.draft('Author').entry_id==id,'editing identity survives restart');fields('Author',{rename=true,title='Final Puzzle'});assert(count()==1 and e.catalog[id].data.title=='Final Puzzle')
-- Global names are reserved even by private entries and ignore case/spacing.
room.host='Other';e.begin(room);fields('Other',{save_library=true,title='  FINAL   puzzle '});assert(count()==1 and clients.Other.shown:find('already used'))
fields('Other',{save_library=true,title='Other Map'});local other=e.draft('Other').entry_id;assert(count()==2)
room.host='Author';e.begin(room);fields('Author',{rename=true,title='other map'});assert(e.catalog[id].data.title=='Final Puzzle'and count()==2,'conflicting rename cannot overwrite anything')
fields('Author',{rename=true,title='Final Puzzle'});assert(e.review('Admin',id,'enable'))
-- Copying preserves the source and offers an unused name; editing a public foreign entry is forbidden.
room.host='Other';e.begin(room);fields('Other',{['load_'..id]=true},'shift_circuit:levels');assert(not clients.Other.shown:find(';edit_entry;'))
fields('Other',{edit_entry=true});assert(not e.draft('Other').pending)
fields('Other',{use_as_draft=true});fields('Other',{confirm=true},'shift_circuit:draft_confirm');assert(not e.draft('Other').entry_id and e.draft('Other').data.title=='Final Puzzle copy')
fields('Other',{save_library=true});assert(count()==3 and e.catalog[id].data.title=='Final Puzzle'and e.catalog[id].approved)
local copy_id=e.draft('Other').entry_id;fields('Other',{rename=true,title='My Copy'});assert(count()==3 and e.catalog[copy_id].data.title=='My Copy')
-- Saving unfinished work is allowed, but submission still validates the map.
fields('Other',{reset_draft=true});fields('Other',{confirm=true},'shift_circuit:draft_confirm')
local d=e.draft('Other').data;for k,t in pairs(d.board)do if t.kind=='checkpoint'then d.board[k]={kind='floor'}end end
fields('Other',{save_library=true,title='Unfinished'});local incomplete=e.draft('Other').entry_id;assert(incomplete and e.catalog[incomplete].status=='saved')
fields('Other',{submit=true});assert(e.catalog[incomplete].status=='saved')
local before=count();fields('Other',{export=true});assert(count()==before and not e.catalog[incomplete].approved,'forged JSON export cannot publish')
room.host='Admin';e.begin(room);fields('Admin',{type_puzzle=true});fields('Admin',{back=true},'shift_circuit:puzzle_settings');e.open('Admin')
assert(clients.Admin.shown:find(';publish;ENABLE]')and clients.Admin.shown:find(';disable_entry;DISABLE]')and not clients.Admin.shown:find(';submit;'))
assert(clients.Admin.shown:find('EXPORT JSON')and clients.Admin.shown:find('EXPORT AS MOD'))
-- Use a valid race board to verify direct enable/disable of the same saved entry.
e.draft('Admin').data=dofile(modpath..'/levels.lua').blank();fields('Admin',{publish=true,title='Admin Board'});local aid=e.draft('Admin').entry_id;assert(e.catalog[aid].approved and e.catalog[aid].status=='enabled')
fields('Admin',{disable_entry=true});assert(not e.catalog[aid].approved and e.catalog[aid].status=='disabled');fields('Admin',{publish=true});assert(e.catalog[aid].approved)
room.host='Other';e.begin(room);fields('Other',{disable_entry=true});assert(e.catalog[aid].approved,'forged disable cannot affect another author')
local calls=0;e.export_puzzle=function()calls=calls+1 end;fields('Other',{export_puzzle=true});assert(calls==0,'non-admin mod export is blocked before callback')
-- Deletion rechecks ownership and enabled state, including changes after confirmation opens.
assert(not e.delete('Other',aid));assert(not e.delete('Admin',aid),'enabled entries require disable first')
room.host='Author';e.begin(room);fields('Author',{['load_'..id]=true},'shift_circuit:levels');assert(not clients.Author.shown:find(';delete_entry;'))
assert(e.review('Admin',id,'disable'));fields('Author',{delete_entry=true});assert(clients.Author.shown:find('DELETE LIBRARY ENTRY'))
fields('Author',{cancel=true},'shift_circuit:delete_level');assert(e.catalog[id]);fields('Author',{confirm=true},'shift_circuit:delete_level');assert(e.catalog[id],'unsolicited confirm is ignored')
fields('Author',{delete_entry=true});assert(e.review('Admin',id,'enable'));fields('Author',{confirm=true},'shift_circuit:delete_level');assert(e.catalog[id],'enabled after dialog opened cannot be deleted')
assert(e.review('Admin',id,'disable'));fields('Author',{delete_entry=true});local kept=copy(e.draft('Author').data);fields('Author',{confirm=true},'shift_circuit:delete_level');assert(not e.catalog[id]and same(kept,e.draft('Author').data)and not e.draft('Author').entry_id)
assert(not e.delete('Author',other),'another authors private entry cannot be deleted');assert(e.delete('Admin',other),'admin may delete disabled entries')
e=create();e.begin(room);assert(not e.catalog[id]and not e.draft('Author').entry_id,'deletion persists across restart')
print('PASS save/edit/copy/rename stable IDs, restart persistence, global names, rejected notes, resubmit, approval invalidation, private access and admin-only export')
''')
