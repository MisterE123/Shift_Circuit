from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
lua.execute('''
local L=dofile(modpath..'/levels.lua');local Q=dofile(modpath..'/courses.lua');local R=dofile(modpath..'/rules.lua');local store=core.get_mod_storage();core.deserialize=function(v)return type(v)=='table'and copy(v)or nil end
local admin=false;core.get_player_privs=function()return {server=admin}end
local room={solo_mode='editor',host='Author',api={phase=function()return 'editor'end,edit_level=function(d,play)shown_board=copy(d)end}}
local function make()return dofile(modpath..'/editor.lua')(core,store,function(n)if n=='Author'then return room end end,function()end)end
local e=make();local player={get_player_name=function()return 'Author'end};clients.Author={};local function fields(f,form)callbacks.on_player_receive_fields(player,form or 'shift_circuit:editor',f)end
e.begin(room);assert(not e.draft('Author').locked);fields({size_20=true});assert(e.draft('Author').data.size==20)
fields({b2=true});e.paint('Author',4,4);fields({rename=true,title='Work in progress'});local original=copy(e.draft('Author').data);assert(e.draft('Author').locked)
fields({size_10=true});assert(e.draft('Author').data.size==20);assert(not clients.Author.shown:find(';size_10;'))
local saved=L.blank(10);saved.title='Saved Board';e.catalog['1']={data=saved,author='Author',approved=false}
fields({library=true});assert(clients.Author.shown:find('DRAFT / Work in progress'));fields({load_1=true},'shift_circuit:levels');assert(shown_board.size==10 and same(e.draft('Author').data,original));assert(same(store:get_string('draft:Author'),original));assert(not e.paint('Author',5,5));assert(not e.rotate('Author',2,2))
fields({return_draft=true});assert(same(shown_board,original));fields({library=true});fields({load_1=true},'shift_circuit:levels');fields({use_as_draft=true});assert(same(e.draft('Author').data,original));fields({cancel=true},'shift_circuit:draft_confirm');assert(same(e.draft('Author').data,original))
-- A restart while viewing a saved board restores the sole persistent draft.
e=make();e.begin(room);assert(same(e.draft('Author').data,original)and e.draft('Author').locked and not e.draft('Author').view)
fields({reset_draft=true});fields({cancel=true},'shift_circuit:draft_confirm');assert(same(e.draft('Author').data,original));fields({confirm=true},'shift_circuit:draft_confirm');assert(same(e.draft('Author').data,original),'unsolicited confirmation cannot reset')
fields({reset_draft=true});fields({confirm=true},'shift_circuit:draft_confirm');assert(not e.draft('Author').locked and e.draft('Author').data.board['4,4'].kind=='floor'and #e.draft('Author').undo==0)
fields({size_10=true});assert(e.draft('Author').data.size==10);e=make();e.begin(room);assert(not e.draft('Author').locked,'unlocked state persists')
e.catalog['1']={data=saved,author='Author',approved=false};fields({library=true});fields({load_1=true},'shift_circuit:levels');fields({use_as_draft=true});fields({confirm=true},'shift_circuit:draft_confirm');assert(e.draft('Author').data.title=='Saved Board copy'and e.draft('Author').locked)
local d=e.draft('Author').data;for k,t in pairs(d.board)do if t.kind=='checkpoint'then d.board[k]={kind='floor'}end end;d.board['2,2']={kind='checkpoint'}
fields({submit=true});assert(store:get_int('level_next')==0 and clients.Author.shown:find('at least 2'))
admin=true;fields({publish=true});assert(store:get_int('level_next')==0);e.catalog['bad']={data=copy(d),author='Author'};assert(not e.review('Author','bad','enable'))
d.title='Repaired board';d.board['8,8']={kind='checkpoint'};assert(L.validate_submission(d));local assembled=copy(d);assert(Q.number(R,assembled,4)==1 and assembled.checkpoint_count==1,'two candidates provide one start and one checkpoint')
fields({submit=true});assert(store:get_int('level_next')==2);assert(e.review('Author','2','enable'))
print('PASS one persistent draft, protected library previews, replacement/reset confirmation, durable size locks, two-candidate submission and enable checks, checkpoint shortage cap')
''')
