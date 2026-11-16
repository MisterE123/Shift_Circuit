from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0];lua.execute(source)
setup=(root/'tests/test_online.py').read_text().split("lua.execute('''",1)[1].split('local smallboard=',1)[0];lua.execute(setup)
lua.execute('''
local L=dofile(modpath..'/levels.lua');local R=dofile(modpath..'/rules.lua');local C=dofile(modpath..'/campaign.lua')
local d=L.blank(10);d.title='One step';d.map_type='puzzle';d.board['3,2']={kind='checkpoint'};d.puzzle={checkpoints={'3,2'},targets={},hands={['1']={'STEP','WAIT','WAIT','WAIT','WAIT'}},equipment={battering_ram=1},weapon='double_laser',hull=4,power=3,limit=1};d.start.dir=1
assert(L.validate_submission(d))
local stale=copy(d);stale.board['2,8']={kind='pit'};stale.puzzle.checkpoints={'2,8','3,2'};stale.puzzle.targets={'crate:9,9'};local unchanged=copy(stale.board)
local valid,reason=L.validate_submission(stale);assert(not valid and reason:find('2,8',1,true),'strict import validation identifies missing checkpoint')
local removed=L.reconcile_puzzle(stale);assert(#removed==2 and #stale.puzzle.checkpoints==1 and stale.puzzle.checkpoints[1]=='3,2'and #stale.puzzle.targets==0);assert(same(stale.board,unchanged)and stale.start.x==d.start.x,'reconciliation preserves the map and start');assert(L.validate_submission(stale));assert(#L.reconcile_puzzle(stale)==0,'reconciliation is idempotent')
local bad=copy(d);bad.puzzle.hands['1']={'STEP'};assert(not L.validate_submission(bad));bad=copy(d);bad.puzzle.targets={'crate:6,6'};assert(not L.validate_submission(bad));bad=copy(d);bad.puzzle.equipment.evil=1;assert(not L.validate_submission(bad))
local handlers={};core.register_on_player_receive_fields=function(fn)handlers[#handlers+1]=fn;callbacks.on_player_receive_fields=fn end
local store=core.get_mod_storage();store:set_string('level_catalog',{['1']={data=d,author='Author',approved=true}})
local writes={};core.mkdir=function()return true end;core.safe_file_write=function(path,data)writes[path]=data;return true end;core.write_json=copy;core.get_worldpath=function()return '/world'end;core.get_mod_data_path=function()return '/mod_data/shift_circuit'end
core.get_player_privs=function(n)return {server=n=='Admin'}end
dofile(modpath..'/online.lua');callbacks.on_mods_loaded();flush()
local a=newplayer('Author');local admin=newplayer('Admin');flush()
local function fields(p,form,f)for _,fn in ipairs(handlers)do fn(p,form,f)end;flush()end
fields(a,'shift_circuit:online',{solo=true});assert(a.shown:find('One step'));fields(a,'shift_circuit:puzzles',{play_1=true});tick(.1);flush();tick(.1)
local function completions()local count=0;for _,call in ipairs(sounds)do if call.name=='sc_puzzle_complete'then assert(call.params.to_player=='Author' and not call.params.pos,'personal non-positional completion sound');count=count+1 end end;return count end
local room=shift_circuit.rooms[shift_circuit.member.Author];assert(room and room.solo_mode=='puzzle');local snap=room.api.snapshot();assert(snap.state.mode=='puzzle');local b=snap.state.bots[1];assert(b.hp==4 and b.energy==3 and b.weapon=='double_laser'and b.parts.battering_ram==1);assert(#b.hand==5 and b.hand[1]=='STEP')
for i=1,5 do room.api.queue('Author',i)end;room.api.commit('Author');for i=1,250 do tick(.2)end
assert(room.status=='finished'and room.result.winner=='Author'and a.shown:find('PUZZLE COMPLETE'));assert(store:get_int('puzzle_best:Author:level:1')==1);assert(completions()==1,'one completion sound despite repeated finished ticks')
fields(a,'shift_circuit:online',{retry=true});assert(room.api.snapshot().state.round==1 and room.api.snapshot().state.bots[1].hp==4)
-- Completion on the final allowed register wins before timeout.
local last=copy(d);last.puzzle.hands['1']={'WAIT','WAIT','WAIT','WAIT','STEP'};room.api.edit_level(last,true);room.status='playing';for i=1,5 do room.api.queue('Author',i)end;room.api.commit('Author');for i=1,250 do tick(.2)end;assert(room.result.winner=='Author'and not room.result.failed);assert(completions()==2,'retry can celebrate again')
-- Make an unreachable objective with a one-round deadline, execute five WAITs.
local fail=copy(d);fail.puzzle.hands['1']={'WAIT','WAIT','WAIT','WAIT','WAIT'};room.api.edit_level(fail,true);room.status='playing'
for i=1,5 do room.api.queue('Author',i)end;room.api.commit('Author');for i=1,250 do tick(.2)end
assert(room.status=='finished'and room.result.failed=='Round limit reached'and a.shown:find('PUZZLE FAILED'));assert(completions()==2,'failure must not play completion')
-- Target-only victory requires actual destruction, never filling a hole.
local target=copy(d);target.puzzle.checkpoints={};target.puzzle.targets={'crate:4,2'};target.crates['4,2']={kind='loot',item='repair'};assert(L.validate_submission(target));room.api.edit_level(target,true)
local live;for i=1,30 do local k,v=debug.getupvalue(room.api.snapshot,i);if k=='S'then live=v end end
local crate=live.crates['4,2'];assert(not R.puzzle_targets_done(live));R.crate_hit(live,crate,3);assert(R.puzzle_targets_done(live));R.hazards(live,1);assert(live.winner=='Author')
local ok,msg=shift_circuit.puzzles.export('Author',{{data=d}},'Bad');assert(not ok);ok,msg=shift_circuit.puzzles.export('Admin',{{data=d},{data=target}},'My ordered pack');assert(ok,msg)
local manifest;for path,data in pairs(writes)do assert(path:find('/mod_data/shift_circuit/exports/',1,true)==1,'exports go to mod data, not the world'); if path:find('puzzles.json',1,true)then manifest=data end end;assert(manifest and #manifest.puzzles==2 and manifest.puzzles[1].data.title=='One step')
-- Race builder cannot select enabled puzzles.
fields(admin,'shift_circuit:online',{solo_race=true});fields(admin,'shift_circuit:online',{course=true});assert(admin.shown:find('No matching boards'))
fields(admin,'shift_circuit:online',{course_back=true});fields(admin,'shift_circuit:online',{setup_back=true});fields(admin,'shift_circuit:online',{editor=true});tick(.1);flush();tick(.1)
fields(admin,'shift_circuit:editor',{type_puzzle=true});assert(admin.shown:find('OBJECTIVES'));puzzle_objectives_form=admin.shown;fields(admin,'shift_circuit:puzzle_settings',{mode_checkpoint=true});fields(admin,'shift_circuit:puzzle_settings',{at_8_3=true});fields(admin,'shift_circuit:puzzle_settings',{tab_2=true});puzzle_robot_form=admin.shown;fields(admin,'shift_circuit:puzzle_settings',{hull='3',power='2',more_battering_ram=true});fields(admin,'shift_circuit:puzzle_settings',{tab_3=true});puzzle_cards_form=admin.shown;for i=1,5 do fields(admin,'shift_circuit:puzzle_settings',{card_STEP=true})end;fields(admin,'shift_circuit:puzzle_settings',{tab_4=true});puzzle_details_form=admin.shown;fields(admin,'shift_circuit:puzzle_settings',{limit='5',description='Test puzzle',hint='Try turning right before moving.',back=true})
local draft=store:get_string('draft:Admin');assert(draft.map_type=='puzzle'and draft.puzzle.checkpoints[1]=='8,3'and draft.puzzle.hull==3 and #draft.puzzle.hands['1']==5 and draft.puzzle.limit==5 and draft.puzzle.hint=='Try turning right before moving.')
fields(admin,'shift_circuit:editor',{submit=true});assert(store:get_int('level_next')==2);assert(store:get_string('level_catalog')['2'].data.map_type=='puzzle')
puzzle_test_fields=fields;puzzle_test_admin=admin
print('PASS puzzle settings UI/autosave, validation, scripted hands, fresh loadout, victory/timeout, retry, target-only rules, progress, race exclusion and admin mod export')
''')

# Pack provenance/order are derived from installation paths, not manifest claims.
import tempfile
with tempfile.TemporaryDirectory(prefix='shift_circuit_packs_') as folder:
 base=Path(folder);builtin=base/'game/mods/builtin_pack';external=base/'external_pack'
 for directory in (builtin,external):directory.mkdir(parents=True);(directory/'puzzles.json').write_text('{}')
 lua.globals().fixture_game=(base/'game').as_posix();lua.globals().fixture_builtin=builtin.as_posix();lua.globals().fixture_external=external.as_posix()
 lua.execute("""
 local L=dofile(modpath..'/levels.lua');local d=L.blank();d.map_type='puzzle';d.puzzle={checkpoints={'8,3'},targets={}};local original=core.get_modpath
 core.get_modpath=function(n)if n=='builtin_pack'then return fixture_builtin elseif n=='external_pack'then return fixture_external else return original(n)end end
 core.get_game_info=function()return {path=fixture_game}end
 local manifest={version=1,title='Fixture',builtin=true,puzzles={{id='second_name',data=d},{id='first_name',data=d}}};core.parse_json=function()return copy(manifest)end
 assert(shift_circuit.register_puzzle_pack('external_pack','puzzles.json'));assert(shift_circuit.register_puzzle_pack('builtin_pack','puzzles.json'));local entries=shift_circuit.puzzles.entries('Visitor');assert(entries[1].builtin and entries[1].id=='pack:builtin_pack:second_name'and entries[2].id=='pack:builtin_pack:first_name'and not entries[3].builtin)
 assert(not shift_circuit.register_puzzle_pack('external_pack','../puzzles.json'));manifest.puzzles[2].id='second_name';assert(not shift_circuit.register_puzzle_pack('external_pack','puzzles.json'));assert(#shift_circuit.puzzles.packs.external_pack.entries==2,'invalid reload leaves existing pack intact')
 core.get_modpath=original
 shift_circuit.leave('Admin');shift_circuit.puzzles.open('Admin');assert(not puzzle_test_admin.shown:find('COPY TO WORKSHOP')and not puzzle_test_admin.shown:find('EXPORT SELECTED')and not puzzle_test_admin.shown:find('Pack name'))
 print('PASS imported pack validation, source-based built-in priority, explicit manifest order, invalid reload isolation and filename restriction')
 """)
