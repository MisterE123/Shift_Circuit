return function(core,store,room_for,leave)
 local MenuUI=dofile(core.get_modpath('shift_circuit')..'/menu_ui.lua');core=MenuUI.wrap(core)
 local path=core.get_modpath('shift_circuit');local L=dofile(path..'/levels.lua');local R=dofile(path..'/rules.lua');local Q=dofile(path..'/courses.lua')
 local PuzzleUI
 local data_path=core.get_mod_data_path and core.get_mod_data_path()
 local E={};local drafts={};local messages={}
 local catalog=core.deserialize(store:get_string('level_catalog'))or {}
 -- One-time retirement of the unwanted authored duplicate, not its original.
 if store:get_string('retired_loopdloop_copy_v1')~='done'then
  local removed={}
  for id,v in pairs(catalog)do
   if v.author=='MisterE'and v.data and v.data.title=='LoopDLoop copy'then removed[id]=v;catalog[id]=nil end
  end
  if next(removed)then
   store:set_string('retired_loopdloop_copy_backup',core.serialize(removed))
   store:set_string('level_catalog',core.serialize(catalog))
  end
  store:set_string('retired_loopdloop_copy_v1','done')
 end
 -- Retire only the bundled generated board; never alter player drafts or copies.
 local retired=core.deserialize(store:get_string('retired_generated_boards'))or {};local changed=false
 for id,v in pairs(catalog)do if v.author=='Shift Circuit'and v.data and v.data.title=='Service Yard'then retired[id]=v;catalog[id]=nil;changed=true end end
 if changed then store:set_string('retired_generated_boards',core.serialize(retired));store:set_string('level_catalog',core.serialize(catalog))end
 for _,v in pairs(catalog)do if v.enabled==false then v.approved=false end;v.enabled=v.approved==true;v.status=v.status or (v.approved and 'enabled'or 'pending')end
 local function clone(t)return core.deserialize(core.serialize(t))end
 local function admin(n)return core.get_player_privs(n).server==true end
 local function name_key(name)return tostring(name or ''):match('^%s*(.-)%s*$'):gsub('%s+',' '):lower()end
 local function unused_name(name)local base=tostring(name):sub(1,35)..' copy';local title=base;local i=1;while true do local used=false;for _,v in pairs(catalog)do if name_key(v.data.title)==name_key(title)then used=true;break end end;if not used then return title end;i=i+1;title=base..' '..i end end
 local function status(v)return ({saved='SAVED / PRIVATE',pending='PENDING REVIEW',rejected='REJECTED',revised='EDITED / NOT SUBMITTED',enabled='ENABLED',disabled='DISABLED'})[v.status]or (v.approved and 'ENABLED'or 'PENDING REVIEW')end
 local function deletable(n,v)return v and not v.approved and not v.enabled and (v.author==n or admin(n))end
 local function equal(a,b)if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end;for k,v in pairs(a)do if not equal(v,b[k])then return false end end;for k in pairs(b)do if a[k]==nil then return false end end;return true end
 local function persist()store:set_string('level_catalog',core.serialize(catalog))end
 -- Reconcile legacy names without merging entries or changing their stable IDs.
 local function reconcile_names()
  local ids,reserved,seen={},{},{};local renamed=false
  for id,v in pairs(catalog)do ids[#ids+1]=id;reserved[name_key(v.data.title)]=true end
  table.sort(ids,function(a,b)local x,y=tonumber(a),tonumber(b);if x and y then return x<y end;return tostring(a)<tostring(b)end)
  for _,id in ipairs(ids)do local v=catalog[id];local old=v.data.title;local key=name_key(old)
   if seen[key]then
    local base=tostring(old):match('^%s*(.-)%s*$'):gsub('%s+',' ');local i=2;local title
    repeat local suffix=' ('..i..')';title=base:sub(1,48-#suffix)..suffix;i=i+1 until not reserved[name_key(title)]
    v.data.title=title;reserved[name_key(title)]=true;v.notes=v.notes or {};v.notes[#v.notes+1]={reviewer='Library',text='Renamed duplicate arena "'..old..'" to "'..title..'". Contents and approval unchanged.'}
    local meta=core.deserialize(store:get_string('draft_meta:'..v.author))or {};local work=core.deserialize(store:get_string('draft:'..v.author))
    if tostring(meta.entry_id)==tostring(id)and work and work.title==old then work.title=title;store:set_string('draft:'..v.author,core.serialize(work))end
    renamed=true
   else seen[key]=id end
  end
  if renamed then persist()end
 end
 reconcile_names()
 local brushes={'floor','pit','belt','double belt','bend left','bend right','double bend left','double bend right','left rotator','right rotator','checkpoint','repair pad','wall','crusher even','laser 1','laser 2','laser 3','pusher odd','pusher even','start','erase overlay','spawner','loot crate','steel crate','pressure plate','trapdoor closed','trapdoor open','sentry','patroller','ram bot','crusher odd','factory one','factory opposite','factory corner','factory three','factory four'}
 local groups={{title='FLOOR',ids={1,2,9,10,12}},{title='BELTS',ids={3,4,5,6,7,8}},{title='MACHINES',ids={13,14,31,15,16,17,18,19}},{title='ROUTE',ids={11,22,21}},{title='OBJECTS',ids={23,24,25,26,27,28,29,30}},{title='FACTORIES',ids={32,33,34,35,36}}}
 local short={['factory one']='1 outlet',['factory opposite']='2 opposite',['factory corner']='2 adjacent',['factory three']='3 outlets',['factory four']='4 outlets',['double belt']='2x belt',['double bend left']='2x left bend',['double bend right']='2x right bend',['erase overlay']='Erase layers',['left rotator']='Left rotator',['right rotator']='Right rotator'}
 local hints={
  ['floor']='Safe floor for robots and pushable crates.',
  ['pit']='An open hole. Robots fall and reboot; pushed crates fill the hole.',
  ['belt']='Moves robots, crates and powerups one square in the arrow direction each register.',
  ['double belt']='Moves robots, crates and powerups during both conveyor steps: up to two squares each register.',
  ['bend left']='A single-speed conveyor bending left. Carries robots around the bend and turns their facing.',
  ['bend right']='A single-speed conveyor bending right. Carries robots around the bend and turns their facing.',
  ['double bend left']='A left-bending conveyor active during both conveyor steps. Also turns carried robots.',
  ['double bend right']='A right-bending conveyor active during both conveyor steps. Also turns carried robots.',
  ['left rotator']='Turns a robot on this square 90 degrees left after pushers finish.',
  ['right rotator']='Turns a robot on this square 90 degrees right after pushers finish.',
  ['checkpoint']='A candidate for the start or a checkpoint. Choose its role and order in course or puzzle settings.',
  ['repair pad']='End a register here: restore 1 hull. End the five-register round here: fully restore hull and power.',
  ['wall']='A thin wall along a square edge. Blocks movement and rays across that edge; leaves the square usable. Facing chooses the edge.',
  ['crusher even']='Crushes on registers 2 and 4. Sits above the floor, so conveyors and rotators can remain underneath. Converts steel crates into loot crates.',
  ['crusher odd']='Crushes on registers 1, 3 and 5. Sits above the floor, so conveyors and rotators can remain underneath. Converts steel crates into loot crates.',
  ['laser 1']='A thin wall emitter firing one damaging beam during the laser phase. Walls, crates and robots stop the ray.',
  ['laser 2']='A thin wall emitter firing two damaging beams during the laser phase. Walls, crates and robots stop the rays.',
  ['laser 3']='A thin wall emitter firing three damaging beams during the laser phase. Walls, crates and robots stop the rays.',
  ['pusher odd']='Pushes robots, crates and powerups one square on registers 1, 3 and 5. Facing sets the push direction.',
  ['pusher even']='Pushes robots, crates and powerups one square on registers 2 and 4. Facing sets the push direction.',
  ['start']='The shared start and initial reboot direction. Select a checkpoint candidate in course or puzzle settings.',
  ['erase overlay']='Removes walls, machines, spawners, crates and enemies from this square. Keeps its floor tile.',
  ['spawner']='Rolls for a random powerup on scheduled rounds. Configure its interval, phase and chance with Spawner Schedule.',
  ['loot crate']='Blocks rays and breaks after 3 damaging shots, revealing an item on its square. Pushable and conveyor-driven; fills a hole when pushed into it.',
  ['steel crate']='Blocks rays and cannot be shot apart. Pushable and conveyor-driven; fills holes. A crusher turns it into a loot crate.',
  ['pressure plate']='After commands, conveyors and pushers finish, an occupied plate toggles orthogonally adjacent trapdoors. Checks once each register, even if the occupant stays put.',
  ['trapdoor closed']='Starts as solid floor. An adjacent occupied pressure plate toggles it open or closed. Opening beneath a robot makes it fall.',
  ['trapdoor open']='Starts as a hole. An adjacent occupied pressure plate toggles it closed or open. A crate entering the hole fills it permanently.',
  ['sentry']='A stationary enemy with 3 hull. Turns clockwise each register, then fires during the weapon phase. Weapons are inactive in round 1. Does not respawn.',
  ['patroller']='An enemy with 3 hull that moves forward each register. Turns around when blocked or facing a pit. Has no weapon and does not respawn.',
  ['ram bot']='An enemy with 3 hull. Seeing a robot ahead makes it wind up, then charge up to 3 squares next register, pushing obstacles. Has no laser and does not respawn.'
 }
 for _,pattern in ipairs({'one','opposite','corner','three','four'})do hints['factory '..pattern]='Produces one or two crates total every round during pushers. Pushes crate chains; robots or walls jam the outlet. Select loot or steel. Facing rotates all outlets.'end
 local function draft(n)
  if not drafts[n]then drafts[n]={locked=(core.deserialize(store:get_string('draft_meta:'..n))or {locked=store:get_string('draft:'..n)~=''}).locked==true,data=core.deserialize(store:get_string('draft:'..n))or L.blank(),brush='floor',dir=0,undo={},group=1}end;local d=drafts[n];if not d.meta_loaded then local meta=core.deserialize(store:get_string('draft_meta:'..n))or {};d.entry_id=meta.entry_id;d.factory_schedule=meta.factory_schedule;d.factory_kind=meta.factory_kind;d.meta_loaded=true;if d.entry_id and not catalog[d.entry_id]then d.entry_id=nil end end;if d.data.version~=3 then d.data=L.resize(d.data,(d.data.size or 11)<=10 and 10 or ((d.data.size or 11)<=20 and 20 or 30))end;drafts[n].data.spawners=drafts[n].data.spawners or {};local removed=L.reconcile_puzzle(d.data);if #removed>0 then messages[n]='Removed erased objectives: '..table.concat(removed,', ');store:set_string('draft:'..n,core.serialize(d.data))end;return drafts[n]
 end
 local function save_draft(n)local d=draft(n);store:set_string('draft:'..n,core.serialize(d.data));store:set_string('draft_meta:'..n,core.serialize({locked=d.locked==true,entry_id=d.entry_id,factory_schedule=d.factory_schedule,factory_kind=d.factory_kind}))end
 local function draw(n)
  local r=room_for(n);if not r or r.solo_mode~='editor'then return end
  local d=draft(n);if d.view then r.api.edit_level(clone(d.view.data),false);return end
  local data=d.data;data.version=3;data.size=data.size or 10;for _,tile in pairs(data.board)do if tile.kind=='station'then tile.kind='checkpoint';tile.number=nil end end
  r.api.edit_level(data,false);save_draft(n)
 end
 function E.open(n)
  local r=room_for(n);if not r or r.solo_mode~='editor'then return end
  local d=draft(n);local esc=core.formspec_escape
  if not d.view and d.entry_id and catalog[d.entry_id]then local notes={};for _,q in ipairs(catalog[d.entry_id].notes or {})do notes[#notes+1]=q.reviewer..': '..q.text end;d.review_notes=table.concat(notes,'\n\n')end
  if d.view then
   core.show_formspec(n,'shift_circuit:editor','formspec_version[6]size[14,7]background[0,0;14,7;sc_setup_background.png]label[.7,.6;LIBRARY PREVIEW / READ ONLY]label[.7,1.6;'..esc(d.view.data.title..' / '..status(catalog[d.view.id]or {}))..']label[.7,2.3;Your draft is preserved.]button[.7,3.2;6,.8;return_draft;RETURN TO MY DRAFT]button[7,3.2;6,.8;use_as_draft;EDIT A COPY]button[.7,4.4;6,.8;test;PLAYTEST SAVED BOARD]button[7,4.4;6,.8;library;LIBRARY]button[.7,5.6;6,.8;review_notes;REVIEW NOTES]button[7,5.6;6,.8;resume;VIEW BOARD]'..((catalog[d.view.id]and catalog[d.view.id].author==n)and 'button[7,2.3;6,.65;edit_entry;EDIT LIBRARY ENTRY]'or '')..(deletable(n,catalog[d.view.id])and 'button[.7,6.45;6,.5;delete_entry;DELETE ENTRY]'or '')..'tooltip[edit_entry;Replace your draft with this entry. Saving updates this same library entry.]');return
  end
  local f={'formspec_version[6]size[14,11]background[0,0;14,11;sc_setup_background.png]style_type[button;bgimg=sc_menu_button.png;bgimg_pressed=sc_menu_button_pressed.png;border=false]',
   'label[.6,.5;FACTORY WORKSHOP / '..esc(d.entry_id and ('LIBRARY #'..d.entry_id..' / '..status(catalog[d.entry_id]or {}))or 'DRAFT')..']field[.7,1.1;8,.65;title;Board name;'..esc(d.data.title)..']button[8.9,1.1;2,.65;rename;RENAME]button[11.1,1.1;2.2,.65;library;LIBRARY]'}
  for i,size in ipairs({10,20})do local x=.7+(i-1)*2.1;if d.locked then f[#f+1]=('box[%s,2;2,.65;#14232d]label[%s,2.32;%s%d x %d]'):format(x,x+.15,d.data.size==size and '> 'or '',size,size)else f[#f+1]=('button[%s,2;2,.65;size_%d;%s%d x %d]'):format(x,size,d.data.size==size and '> 'or '',size,size)end end
  f[#f+1]='button[5,2;2.1,.65;reset_draft;RESET DRAFT]'
  f[#f+1]='label[7.3,2.35;'..(d.locked and 'Size locked / Reset draft to change'or 'Choose size before editing')..']'
  for i,g in ipairs(groups)do f[#f+1]=('button[%s,3;2.02,.65;group_%d;%s%s]'):format(.7+(i-1)*2.1,i,(d.group or 1)==i and '> 'or '',g.title)end
  f[#f+1]='style_type[label;font_size=*0.8;valign=top]'
  for j,i in ipairs(groups[d.group or 1].ids)do
   local x=.7+(j-1)%4*2.05;local y=4+math.floor((j-1)/4)*1.6
   if d.brush==brushes[i]then f[#f+1]=('box[%s,%s;1.17,1.17;#74e596]'):format(x-.06,y-.06)end
   local caption=(short[brushes[i]]or brushes[i]):upper();local lines={caption};local line='';for word in hints[brushes[i]]:gmatch('%S+')do if #line+#word+1>58 then lines[#lines+1]=line;line=word else line=line==''and word or line..' '..word end end;lines[#lines+1]=line;local hint=esc(table.concat(lines,'\n'))
   f[#f+1]=('image_button[%s,%s;1.05,1.05;sc_editor_%d.png;b%d;]label[%s,%s;1.85,.5;%s]tooltip[%s,%s;1.95,1.48;%s]'):format(x,y,i,i,x,y+1.08,esc(caption:gsub(' ', '\n',1)),x,y,hint)
  end
  f[#f+1]='style_type[label;font_size=*1;valign=center]'
  f[#f+1]='textarea[9.1,4;3.8,.65;;;'..esc((short[d.brush]or d.brush):upper())..']'
  f[#f+1]='label[9.1,4.75;PLACEMENT FOLLOWS VIEW]label[9.1,5.35;Face the desired direction.]label[9.1,5.85;Snaps to the nearest axis.]'
  if d.group==6 then f[#f]=f[#f]:gsub('label%[9.1,5.85;Snaps to the nearest axis.%]','')end
  if d.group==6 then f[#f+1]='label[9.1,5.95;1-2 crates / every round]';f[#f+1]='button[9.1,6.3;1.8,.65;factory_loot;'..((d.factory_kind or 'loot')=='loot'and '> 'or '')..'LOOT]button[11.05,6.3;1.8,.65;factory_steel;'..(d.factory_kind=='steel'and '> 'or '')..'STEEL]'else f[#f+1]='button[9.1,6.3;3.8,.65;spawner_setup;SPAWNER TIMING]'end
  f[#f+1]='button[.7,7.3;3,.65;type_race;'..(d.data.map_type~='puzzle'and '> 'or '')..'RACE BOARD]button[3.9,7.3;3,.65;type_puzzle;'..(d.data.map_type=='puzzle'and '> 'or '')..'PUZZLE]'
  if d.data.map_type=='puzzle'then f[#f+1]='button[7.1,7.3;3,.65;puzzle_settings;PUZZLE SETTINGS]'end
  if admin(n)then f[#f+1]='button[10.3,7.3;3,.65;export_puzzle;EXPORT AS MOD]'end
  f[#f+1]='button[.7,8.25;2.2,.75;undo;UNDO]button[3,8.25;2.2,.75;test;TEST]button[5.3,8.25;3.8,.75;save_library;SAVE TO LIBRARY]'..(admin(n)and 'button[9.3,8.25;1.9,.75;publish;ENABLE]button[11.4,8.25;1.9,.75;disable_entry;DISABLE]'or 'button[9.3,8.25;4,.75;submit;REQUEST REVIEW]')
  if admin(n)then f[#f+1]='button[.7,9.2;3,.65;export;EXPORT JSON]'end
  if d.review_notes and d.review_notes~=''then f[#f+1]='button[7.1,9.2;3,.65;review_notes;REVIEW NOTES]'end
  if deletable(n,catalog[d.entry_id])then f[#f+1]='button[3.9,9.2;3,.65;delete_entry;DELETE ENTRY]'end
  f[#f+1]='button[10.3,9.2;3,.65;exit;LEAVE EDITOR]label[.7,10.3;'..esc(messages[n]or 'Draft autosaved / Place start/checkpoint candidates.')..']'
  core.show_formspec(n,'shift_circuit:editor',table.concat(f))
 end
 function E.begin(r)
  local n=r.host;local d=draft(n);d.view=nil;d.pending=nil;draw(n);E.open(n)
  if r.import_puzzle then d.pending={kind='import',data=clone(r.import_puzzle)};r.import_puzzle=nil;core.show_formspec(n,'shift_circuit:draft_confirm','formspec_version[6]size[12,6]label[.7,.8;COPY INSTALLED PUZZLE INTO YOUR DRAFT?]label[.7,2;This replaces your current draft. Installed content stays unchanged.]button[.7,4;5,.8;cancel;KEEP MY DRAFT]button[6.3,4;5,.8;confirm;REPLACE DRAFT]')end
 end
 local function archive(n,approved,export,save_only)
  local d=draft(n);local data,err
  if save_only then data=clone(d.data)else data,err=L.validate_submission(d.data);if data and data.map_type~='puzzle'and Q.number(R,clone(data),9)==0 then data=nil;err='No checkpoint candidate is reachable from the start'end end
  if not data then messages[n]=err;return end
  if approved and not admin(n)then messages[n]='Admin permission required';return end
  local id=d.entry_id;local previous=id and catalog[id]
  data.title=tostring(data.title or ''):match('^%s*(.-)%s*$'):gsub('%s+',' '):sub(1,48)
  if data.title==''then messages[n]='Give this entry a name before saving';return end
  for key,v in pairs(catalog)do if key~=id and name_key(v.data.title)==name_key(data.title)then messages[n]='That name is already used in the global library. Choose a different name.';return end end
  if previous and previous.author~=n then messages[n]='Only the author can update this entry';return end
  if not previous then repeat id=tostring(store:get_int('level_next')+1);store:set_int('level_next',tonumber(id))until not catalog[id] end
  local changed=not previous or not equal(previous.data,data)
  if previous and (previous.approved or previous.enabled)and not admin(n)and (changed or not save_only)then messages[n]='Enabled entries are protected. Ask an admin to disable it, or edit a copy.';return end
  local v=previous or {author=n,notes={},revision=0};catalog[id]=v
  if changed then v.data=data;v.revision=(v.revision or 0)+1;v.approved=false;v.enabled=false;v.status=previous and 'revised'or 'saved' end
  if not save_only then v.approved=approved==true;v.enabled=v.approved;v.status=approved and 'enabled'or 'pending';v.submitted_revision=v.revision end
  d.entry_id=id;persist();save_draft(n)
  messages[n]=(save_only and 'Saved to library #'or approved and 'Saved enabled level #'or 'Submitted for review #')..id..' / '..status(v)
  if export then
   if not data_path then messages[n]='Saved, but mod data folder is unavailable';return end
   local dir=data_path..'/levels';core.mkdir(dir);local filename='level_'..id..'.json';local existing={};for _,entry in ipairs(core.get_dir_list and core.get_dir_list(dir,false)or {})do existing[entry]=true end;local suffix=1
   while existing[filename]do filename='level_'..id..'_'..suffix..'.json';suffix=suffix+1 end
   local ok=core.safe_file_write(dir..'/'..filename,core.write_json(data,true))
   messages[n]=ok and ('Exported '..dir..'/'..filename)or 'Saved, but export failed'
  end
  return id
 end
 local function confirm_draft(n,kind,id)
  local d=draft(n);d.pending={kind=kind,id=id};core.show_formspec(n,'shift_circuit:draft_confirm','formspec_version[6]size[12,6]background[0,0;12,6;sc_setup_background.png]label[.7,.7;REPLACE YOUR DRAFT?]textarea[.7,1.5;10.6,2;;;You have one draft. '..(kind=='reset'and 'Resetting clears it and unlocks board size.'or 'This saved board will replace your current draft.')..' This cannot be undone. Submitted boards are unchanged.]button[.7,4.5;5,.8;cancel;KEEP MY DRAFT]button[6.3,4.5;5,.8;confirm;YES / REPLACE DRAFT]')
 end
 local function library(n)
  local f={'formspec_version[6]size[14,11]background[0,0;14,11;sc_setup_background.png]label[.7,.6;LEVEL LIBRARY / YOUR SAVES AND PUBLIC BOARDS]'}
  local ids={};for id,v in pairs(catalog)do if v.approved or v.author==n or admin(n)then ids[#ids+1]=id end end;table.sort(ids,function(a,b)return tonumber(a)<tonumber(b)end)
  local d=draft(n);local page=d.page or 1;local pages=math.max(1,math.ceil(#ids/8));page=math.min(page,pages);d.page=page
  f[#f+1]='button[.7,1.3;12.5,.65;return_draft;'..core.formspec_escape('DRAFT / '..d.data.title..' / Your autosaved work')..']'
  local opening,closing=MenuUI.scroll(.7,2.2,12.5,6.8,'library_scroll',#ids*.85-.2);f[#f+1]=opening
  for j,id in ipairs(ids)do local v=catalog[id];f[#f+1]=('button[0,%s;12.5,.65;load_%s;%s / %s / %s]'):format((j-1)*.85,id,core.formspec_escape((v.data.map_type=='puzzle'and '[PUZZLE] 'or '[RACE] ')..v.data.title),core.formspec_escape(v.author),status(v))end
  f[#f+1]=closing..'button[.7,9.5;12.5,.7;back;WORKSHOP]';core.show_formspec(n,'shift_circuit:levels',table.concat(f))
 end
 local function pointed(p)
  local n=p:get_player_name();local r=room_for(n);if not r or r.solo_mode~='editor'or r.api.phase()~='editor'then return end
  local eye=p:get_pos();local look=p:get_look_dir();if look.y>=-.01 then return end
  local t=(r.origin.y+.5-eye.y-1.625)/look.y;if t<0 or t>120 then return end
  local x=math.floor((eye.x+look.x*t-r.origin.x+.5)/2);local z=math.floor((eye.z+look.z*t-r.origin.z+.5)/2)
  if x>=1 and x<=draft(n).data.size and z>=1 and z<=draft(n).data.size then return n,x,z end
 end
 for _,tool in ipairs({'brush','rotate'})do
  core.register_tool('shift_circuit:editor_'..tool,{description=tool=='brush'and 'PAINT / Right-click: palette'or 'ROTATE / Click a placed piece to turn it clockwise',inventory_image=tool=='brush'and 'sc_editor_brush.png'or 'sc_editor_rotate.png',on_use=function(stack,p)
   local n,x,z=pointed(p);if n then if tool=='rotate'then E.rotate(n,x,z)else E.paint(n,x,z,math.floor(-p:get_look_horizontal()/(math.pi/2)+.5)%4)end end;return stack
  end,on_secondary_use=function(stack,p)E.open(p:get_player_name());return stack end,on_place=function(stack,p)E.open(p:get_player_name());return stack end,on_drop=function(stack)return stack end})
 end
 function E.rotate(n,x,z)
  local r=room_for(n);if not r or r.solo_mode~='editor'or r.api.phase()~='editor'then return false end
  local d=draft(n);if d.view then return false end;local a=d.data;local t=a.board[x..','..z];if not t then return false end
  local before=clone(a);local changed=false
  if t.kind=='factory'then t.dir=(t.dir+1)%4;changed=true end
  if t.kind=='belt'then t.dir=(t.dir+1)%4;if t.entry~=nil then t.entry=(t.entry+1)%4 end;changed=true end
  for _,layer in ipairs({'lasers','pushers'})do for _,q in ipairs(a[layer])do if q.x==x and q.z==z then q.dir=(q.dir+1)%4;changed=true end end end
  local enemy=(a.enemies or {})[x..','..z];if enemy then enemy.dir=(enemy.dir+1)%4;changed=true end
  if a.start.x==x and a.start.z==z then a.start.dir=(a.start.dir+1)%4;changed=true end
  if changed then d.locked=true;d.undo[#d.undo+1]=before;if #d.undo>30 then table.remove(d.undo,1)end;draw(n)end;return changed
 end
 function E.paint(n,x,z,direction)
  local r=room_for(n);if not r or r.solo_mode~='editor'or r.api.phase()~='editor'then return false end
  if x~=math.floor(x)or z~=math.floor(z)or x<1 or x>(draft(n).data.size or 11) or z<1 or z>(draft(n).data.size or 11) then return false end
  local d=draft(n);if d.view then return false end;d.locked=true;if direction~=nil then d.dir=direction end;local a=d.data;a.crates=a.crates or {};a.enemies=a.enemies or {};local b=d.brush;local k=x..','..z
  d.undo[#d.undo+1]=clone(a);if #d.undo>30 then table.remove(d.undo,1)end
  if b:match('^factory ')then a.board[k]={kind='factory',pattern=b:sub(9),dir=d.dir,crate_kind=d.factory_kind or 'loot'};a.crates[k]=nil;a.enemies[k]=nil;a.spawners[k]=nil;a.pickups[k]=nil
  elseif b=='floor'or b=='pit'then a.board[k]={kind=b}
  elseif b:find('belt',1,true)or b:find('bend',1,true)then a.board[k]={kind='belt',dir=d.dir,speed=b:find('double',1,true)and 2 or 1,entry=b:find('left',1,true)and (d.dir+1)%4 or (b:find('right',1,true)and (d.dir+3)%4 or nil)}
  elseif b:find('rotator',1,true)then a.board[k]={kind='rotator',turn=b=='left rotator'and 3 or 1}
  elseif b=='checkpoint'then a.board[k]={kind='checkpoint'}
  elseif b=='repair pad'then a.board[k]={kind='repair'}  elseif b=='start'then a.start={x=x,z=z,dir=d.dir}
  elseif b=='wall'then local edge=R.edge(x,z,d.dir);a.walls[edge]=not a.walls[edge]or nil
  elseif b=='crusher even'or b=='crusher odd'then local parity=b=='crusher odd'and 1 or 0;local old=a.overhead[k];if old and (type(old)=='table'and (old.parity or 0)or 0)==parity then a.overhead[k]=nil else a.overhead[k]={kind='crusher',parity=parity}end
  elseif b=='spawner'then a.spawners[k]=clone(d.spawner or {item='random',first=1,every=3,phase=(x+2*z)%3,chance=50})
  elseif b=='loot crate'or b=='steel crate'then a.crates[k]={kind=b=='loot crate'and 'loot'or 'steel'};a.enemies[k]=nil
  elseif b=='pressure plate'then a.board[k]={kind='plate'}
  elseif b=='trapdoor closed'or b=='trapdoor open'then a.board[k]={kind='trapdoor',open=b=='trapdoor open'}
  elseif b=='sentry'or b=='patroller'or b=='ram bot'then a.enemies[k]={kind=b=='ram bot'and 'ram_bot'or b,dir=d.dir};a.crates[k]=nil
  elseif b=='erase overlay'then a.crates[k]=nil;a.enemies[k]=nil; a.spawners[k]=nil;a.overhead[k]=nil;a.pickups[k]=nil;for dir=0,3 do a.walls[R.edge(x,z,dir)]=nil end;for _,kind in ipairs({'lasers','pushers'})do for i=#a[kind],1,-1 do if a[kind][i].x==x and a[kind][i].z==z then table.remove(a[kind],i)end end end
  elseif b:find('laser',1,true)or b:find('pusher',1,true)then local kind=b:find('laser',1,true)and 'lasers'or 'pushers';for i=#a[kind],1,-1 do if a[kind][i].x==x and a[kind][i].z==z then table.remove(a[kind],i)end end;a[kind][#a[kind]+1]={x=x,z=z,dir=d.dir,power=tonumber(b:match('%d')),parity=b=='pusher odd'and 1 or 0}
  end
  draw(n);return true
 end
 core.register_on_player_receive_fields(function(p,form,f)
  if form~='shift_circuit:editor'and form~='shift_circuit:levels'and form~='shift_circuit:spawner'and form~='shift_circuit:draft_confirm'and form~='shift_circuit:puzzle_settings'and form~='shift_circuit:delete_level'then return end
  local n=p:get_player_name();local r=room_for(n);if not r or r.solo_mode~='editor'then return end;local d=draft(n)
  if form=='shift_circuit:delete_level'then
   local id=d.delete_id;d.delete_id=nil
   if f.confirm and id then local ok,message=E.delete(n,id);messages[n]=message;if ok then draw(n)end end
   E.open(n);return
  end
  if f.factory_loot or f.factory_steel then d.factory_kind=f.factory_steel and 'steel'or 'loot';E.open(n);return end
  if f.delete_entry then
   local id=d.view and d.view.id or d.entry_id;local v=catalog[id]
   if deletable(n,v)then d.delete_id=id;core.show_formspec(n,'shift_circuit:delete_level','formspec_version[6]size[12,5]label[.7,.7;DELETE LIBRARY ENTRY?]textarea[.7,1.4;10.6,1.6;;;'..core.formspec_escape(v.data.title..' will be permanently removed. Your draft is kept.')..']button[.7,3.5;5,.8;cancel;KEEP ENTRY]button[6.3,3.5;5,.8;confirm;DELETE ENTRY]')else messages[n]='Only your own disabled entries can be deleted';E.open(n)end;return
  end
  if form=='shift_circuit:draft_confirm'then
   local pending=d.pending;d.pending=nil
   if f.confirm and pending then
    local v=pending.id and catalog[pending.id]
    if pending.kind=='import'or pending.kind=='reset'or (v and (v.approved or v.author==n or admin(n)))then
     d.data=pending.kind=='reset'and L.blank(d.data.size)or clone(pending.kind=='import'and pending.data or v.data);d.locked=pending.kind~='reset';d.view=nil;d.undo={};d.review_notes=nil;d.entry_id=pending.kind=='edit'and pending.id or nil;d.meta_loaded=true;if pending.kind=='load'or pending.kind=='import'then d.data.title=unused_name(d.data.title)end;messages[n]='Draft autosaved';draw(n)
    end
   end
   E.open(n);return
  end
  if f.return_draft then d.view=nil;d.pending=nil;draw(n);E.open(n);return end
  if f.reset_draft then confirm_draft(n,'reset');return end
  if d.view and form~='shift_circuit:levels'then
   if f.edit_entry and catalog[d.view.id]and catalog[d.view.id].author==n then confirm_draft(n,'edit',d.view.id);return end
   if f.use_as_draft then confirm_draft(n,'load',d.view.id);return end
   if f.library then library(n);return end
   if f.test then local data,err=L.validate_submission(d.view.data);if data and (data.map_type=='puzzle'or Q.number(R,clone(data),9)>0) then r.api.edit_level(data,true);core.close_formspec(n,form)else messages[n]=err or 'No reachable route';E.open(n)end;return end
   if f.resume then draw(n);core.close_formspec(n,form);return end
   if not f.review_notes and not f.exit then if not f.quit then E.open(n)end;return end
  end
  if form=='shift_circuit:puzzle_settings'then if not d.view and d.data.map_type=='puzzle'then PuzzleUI.handle(n,f)end;return end
  if f.type_race then d.data.map_type='race';save_draft(n)end
  if f.type_puzzle then d.data.map_type='puzzle';PuzzleUI.open(n);save_draft(n);return end
  if f.puzzle_settings and d.data.map_type=='puzzle'then PuzzleUI.open(n);return end
  if f.export_puzzle then if not admin(n)then messages[n]='Admin permission required';E.open(n);return end;if E.export_puzzle then local _,message=E.export_puzzle(n,{{data=d.data}},d.data.title);messages[n]=message end;E.open(n);return end
  if f.spawner_setup then
   core.show_formspec(n,'shift_circuit:spawner','formspec_version[6]size[11,8]background[0,0;11,8;sc_setup_background.png]label[.6,.5;POWERUP SPAWNER]label[.7,1.5;Rolls a random weapon, equipment or supply each spawn.]field[.7,2.4;4.5,.8;first;First round;1]field[5.5,2.4;4.5,.8;every;Every N rounds;3]field[.7,3.6;9.5,.8;rounds;Or explicit rounds (comma separated);]field[.7,4.8;4.5,.8;phase;Phase offset (0 to interval-1);0]field[5.5,4.8;4.5,.8;chance;Chance per due round (%);50]label[.7,6;Explicit rounds ignore the phase offset.]button[.7,6.8;9.5,.7;save_spawner;USE SPAWNER BRUSH]');return
  end
  if form=='shift_circuit:spawner'then
   if f.save_spawner then
    local config={item='random',first=tonumber(f.first),every=tonumber(f.every),phase=tonumber(f.phase or '0')or -1,chance=tonumber(f.chance or '50')or -1}
    if f.rounds and f.rounds:match('%S')then config={item=config.item,rounds={},phase=0,chance=config.chance};for value in f.rounds:gmatch('[^,]+')do config.rounds[#config.rounds+1]=tonumber(value)or -1 end end
    local candidate=L.blank();candidate.spawners={['2,2']=config};local valid,err=L.validate(candidate)
    if valid then d.spawner=config;d.brush='spawner';messages[n]='Spawner ready / '..config.item;if r.api.phase()~='editor'then draw(n)else save_draft(n)end;core.close_formspec(n,form);return else messages[n]=err end
   end;E.open(n);return
  end
  if f.review_notes then core.show_formspec(n,'shift_circuit:editor','formspec_version[6]size[12,8]textarea[.6,.6;10.8,6;;Admin review notes;'..core.formspec_escape(d.review_notes or 'No review notes.')..']button[.6,7;10.8,.7;back;BACK]');return end
  if f.exit then leave(n);return end
  if form=='shift_circuit:levels'then
   if f.back then E.open(n);return end
   if f.next then d.page=(d.page or 1)+1 elseif f.prev then d.page=math.max(1,(d.page or 1)-1)end
   for key in pairs(f)do local id=key:match('^load_(%d+)$');local v=id and catalog[id];if v and (v.approved or v.author==n or admin(n))then d.view={id=id,data=clone(v.data)};local notes={};for _,q in ipairs(v.notes or {})do notes[#notes+1]=q.reviewer..': '..q.text end;d.review_notes=table.concat(notes,'\n\n');messages[n]=#notes>0 and 'Admin notes available / REVIEW NOTES'or nil;draw(n);E.open(n);return end end
   if not f.quit then library(n)end;return
  end
  if f.rename then d.data.title=tostring(f.title or d.data.title):sub(1,48);if d.entry_id then archive(n,false,false,true)else save_draft(n)end end
  local selected_brush=false;for i,b in ipairs(brushes)do if b~='start'and f['b'..i]then d.brush=b;selected_brush=true end end
  for i in ipairs(groups)do if f['group_'..i]then d.group=i end end
  for dir=0,3 do if f['dir_'..dir]then d.dir=dir end end
  for _,size in ipairs({10,20})do if not d.locked and f['size_'..size]and size~=d.data.size then d.undo={};d.data=L.resize(d.data,size);draw(n)end end
  if f.rotate then d.dir=(d.dir+1)%4 end
  if f.undo and #d.undo>0 then d.data=table.remove(d.undo);draw(n)end
  if (f.save_library or f.submit or f.publish or f.export or f.disable_entry)and f.title then d.data.title=tostring(f.title):sub(1,48)end
  if f.disable_entry then if admin(n)then local id=archive(n,false,false,true);if id then local _,message=E.review(n,id,'disable');messages[n]=message..' / DISABLED'end else messages[n]='Admin permission required'end
  elseif f.save_library then archive(n,false,false,true)elseif f.submit then archive(n,admin(n),false)elseif f.publish then archive(n,true,false)elseif f.export then archive(n,true,true)end
  if f.library then library(n);return end
  if f.test then local data,err=L.validate_submission(d.data);if data and data.map_type~='puzzle'and Q.number(R,clone(data),9)==0 then data=nil;err='No checkpoint candidate is reachable from the start'end;if data then r.api.edit_level(data,true);core.close_formspec(n,form);return else messages[n]=err end end
  if selected_brush then if r.api.phase()~='editor'then draw(n)else save_draft(n)end;core.close_formspec(n,form);return end
  if f.resume then draw(n);core.close_formspec(n,form);return end
  if not f.quit then E.open(n)end
 end)
 -- Ship exported JSON in levels/ to make it available on every new server.
 if core.get_dir_list and core.parse_json then
  for _,file in ipairs(core.get_dir_list(path..'/levels',false))do if file:match('%.json$')then local f=io.open(path..'/levels/'..file,'r');if f then local data=L.validate_submission(core.parse_json(f:read('*a')));f:close();local key='bundled:'..file
   if data and not store:get_string(key):find('loaded',1,true)then local id=store:get_int('level_next')+1;while catalog[tostring(id)]do id=id+1 end;store:set_int('level_next',id);catalog[tostring(id)]={data=data,author='Shift Circuit',approved=true};store:set_string(key,'loaded')end
  end end end;reconcile_names();persist()
 end
 function E.delete(n,id)
  id=tostring(id);local v=catalog[id]
  if not v then return false,'Entry not found'end
  if not deletable(n,v)then return false,'Only the author or an admin may delete an entry, and it must be disabled'end
  catalog[id]=nil;persist()
  for name,d in pairs(drafts)do if d.entry_id==id then d.entry_id=nil;save_draft(name)end;if d.view and d.view.id==id then d.view=nil end end
  return true,'Library entry deleted. Your draft was kept.'
 end
 function E.review(n,id,action,note)
  if not admin(n)then return false,'Admin permission required'end;local v=catalog[tostring(id)];if not v then return false,'Board not found'end
  if action=='approve'or action=='enable'then local valid,err=L.validate_submission(v.data);if not valid then return false,err end;if valid.map_type~='puzzle'and Q.number(R,clone(valid),9)==0 then return false,'No checkpoint is reachable from the start'end;v.approved=true;v.enabled=true;v.status='enabled' elseif action=='disable'or action=='reject'then v.enabled=false;v.approved=false;v.status=action=='reject'and 'rejected'or 'disabled';note=tostring(note or ''):match('^%s*(.-)%s*$'):sub(1,2000);v.notes=v.notes or {};v.notes[#v.notes+1]={reviewer=n,text=(action=='reject'and 'Rejected' or 'Disabled')..(note~=''and (': '..note)or '')}
  elseif action=='note'then note=tostring(note or ''):match('^%s*(.-)%s*$'):sub(1,2000);if note==''then return false,'Enter a note'end;v.notes=v.notes or {};v.notes[#v.notes+1]={reviewer=n,text=note}else return false,'Unknown review action'end
  persist();return true,'Review saved'
 end
 PuzzleUI=dofile(path..'/puzzle_editor.lua')(core,L,draft,save_draft,draw,E.open)
 function E.result(n,state)messages[n]=state.failed and ('PLAYTEST FAILED / '..state.failed)or 'PLAYTEST COMPLETE';E.open(n)end
 E.reconcile_names=reconcile_names;E.persist=persist;E.status=status;E.draft=draft;E.catalog=catalog;return E
end
