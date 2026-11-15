return function(core,store,room_for,leave)
 local path=core.get_modpath('shift_circuit');local L=dofile(path..'/levels.lua');local R=dofile(path..'/rules.lua');local Q=dofile(path..'/courses.lua')
 local E={};local drafts={};local messages={}
 local catalog=core.deserialize(store:get_string('level_catalog'))or {}
 -- Retire only the bundled generated board; never alter player drafts or copies.
 local retired=core.deserialize(store:get_string('retired_generated_boards'))or {};local changed=false
 for id,v in pairs(catalog)do if v.author=='Shift Circuit'and v.data and v.data.title=='Service Yard'then retired[id]=v;catalog[id]=nil;changed=true end end
 if changed then store:set_string('retired_generated_boards',core.serialize(retired));store:set_string('level_catalog',core.serialize(catalog))end
 for _,v in pairs(catalog)do if v.enabled==false then v.approved=false end;v.enabled=v.approved==true end
 local function clone(t)return core.deserialize(core.serialize(t))end
 local function admin(n)return core.get_player_privs(n).server==true end
 local function persist()store:set_string('level_catalog',core.serialize(catalog))end
 local brushes={'floor','pit','belt','double belt','bend left','bend right','double bend left','double bend right','left rotator','right rotator','checkpoint','repair pad','wall','crusher','laser 1','laser 2','laser 3','pusher odd','pusher even','start','erase overlay','spawner'}
 local groups={{title='FLOOR',ids={1,2,9,10,12}},{title='CONVEYORS',ids={3,4,5,6,7,8}},{title='MACHINES',ids={13,14,15,16,17,18,19}},{title='ROUTE & SUPPLY',ids={11,22,21}}}
 local short={['double belt']='2x belt',['double bend left']='2x left bend',['double bend right']='2x right bend',['erase overlay']='Erase layers',['left rotator']='Left rotator',['right rotator']='Right rotator'}
 local hints={['floor']='Safe floor for robot movement.',['pit']='Robots fall and reboot.',['wall']='Thin edge wall. Direction chooses the edge.',['crusher']='Overhead crusher. Keeps the tile below.',['checkpoint']='A possible checkpoint. Race setup assigns its number.',['start']='Shared start and initial reboot direction.',['spawner']='Random supplies on your chosen round schedule.',['erase overlay']='Remove walls, machines and spawners. Keep the floor.'}
 local function draft(n)
  if not drafts[n]then drafts[n]={locked=(core.deserialize(store:get_string('draft_meta:'..n))or {locked=store:get_string('draft:'..n)~=''}).locked==true,data=core.deserialize(store:get_string('draft:'..n))or L.blank(),brush='floor',dir=0,undo={},group=1}end;local d=drafts[n];if d.data.version~=3 then d.data=L.resize(d.data,(d.data.size or 11)<=10 and 10 or ((d.data.size or 11)<=20 and 20 or 30))end;drafts[n].data.spawners=drafts[n].data.spawners or {};return drafts[n]
 end
 local function save_draft(n)local d=draft(n);store:set_string('draft:'..n,core.serialize(d.data));store:set_string('draft_meta:'..n,core.serialize({locked=d.locked==true}))end
 local function draw(n)
  local r=room_for(n);if not r or r.solo_mode~='editor'then return end
  local d=draft(n);if d.view then r.api.edit_level(clone(d.view.data),false);return end
  local data=d.data;data.version=3;data.size=data.size or 10;for _,tile in pairs(data.board)do if tile.kind=='station'then tile.kind='checkpoint';tile.number=nil end end
  r.api.edit_level(data,false);save_draft(n)
 end
 function E.open(n)
  local r=room_for(n);if not r or r.solo_mode~='editor'then return end
  local d=draft(n);local esc=core.formspec_escape
  if d.view then
   core.show_formspec(n,'shift_circuit:editor','formspec_version[6]size[14,7]background[0,0;14,7;sc_setup_background.png]label[.7,.6;LIBRARY PREVIEW / READ ONLY]label[.7,1.6;'..esc(d.view.data.title)..']label[.7,2.3;Your draft is preserved. Painting is disabled in this preview.]button[.7,3.2;6,.8;return_draft;RETURN TO MY DRAFT]button[7,3.2;6,.8;use_as_draft;REPLACE DRAFT WITH THIS BOARD]button[.7,4.4;6,.8;test;PLAYTEST SAVED BOARD]button[7,4.4;6,.8;library;LIBRARY]button[.7,5.6;6,.8;review_notes;REVIEW NOTES]button[7,5.6;6,.8;resume;VIEW BOARD]');return
  end
  local f={'formspec_version[6]size[14,11]background[0,0;14,11;sc_setup_background.png]style_type[button;bgimg=sc_menu_button.png;bgimg_pressed=sc_menu_button_pressed.png;border=false]',
   'label[.6,.5;FACTORY WORKSHOP / DRAFT]field[.7,1.1;8,.65;title;Board name;'..esc(d.data.title)..']button[8.9,1.1;2,.65;rename;RENAME]button[11.1,1.1;2.2,.65;library;LIBRARY]'}
  for i,size in ipairs({10,20})do local x=.7+(i-1)*2.1;if d.locked then f[#f+1]=('box[%s,2;2,.65;#14232d]label[%s,2.32;%s%d x %d]'):format(x,x+.15,d.data.size==size and '> 'or '',size,size)else f[#f+1]=('button[%s,2;2,.65;size_%d;%s%d x %d]'):format(x,size,d.data.size==size and '> 'or '',size,size)end end
  f[#f+1]='button[5,2;2.1,.65;reset_draft;RESET DRAFT]'
  f[#f+1]='label[7.3,2.35;'..(d.locked and 'Size locked / Reset draft to change'or 'Choose size before editing')..']'
  for i,g in ipairs(groups)do f[#f+1]=('button[%s,3;3.05,.65;group_%d;%s%s]'):format(.7+(i-1)*3.2,i,(d.group or 1)==i and '> 'or '',g.title)end
  for j,i in ipairs(groups[d.group or 1].ids)do
   local x=.7+(j-1)%4*2.05;local y=4+math.floor((j-1)/4)*1.4
   f[#f+1]=('image_button[%s,%s;1.05,1.05;sc_editor_%d.png;b%d;]tooltip[b%d;%s]label[%s,%s;%s]'):format(x,y,i,i,i,esc(hints[brushes[i]]or brushes[i]),x,y+1.18,esc((short[brushes[i]]or brushes[i]):upper()))
  end
  f[#f+1]='label[9.1,4.1;'..esc((short[d.brush]or d.brush):upper())..']'
  f[#f+1]='label[9.1,4.75;PLACEMENT FOLLOWS VIEW]label[9.1,5.35;Face the desired direction.]label[9.1,5.85;Snaps to the nearest axis.]'
  f[#f+1]='button[9.1,6.3;3.8,.65;spawner_setup;SPAWNER SCHEDULE]'
  f[#f+1]='label[.7,7.25;1: Paint / 2: Rotate placed piece / Right-click: Palette]label[.7,7.7;Curved conveyors rotate both their entrance and exit.]'
  f[#f+1]='button[.7,8.25;3,.75;resume;BUILD]button[3.9,8.25;3,.75;undo;UNDO]button[7.1,8.25;3,.75;test;PLAYTEST]button[10.3,8.25;3,.75;submit;SUBMIT]'
  if admin(n)then f[#f+1]='button[.7,9.2;3,.65;publish;SAVE ENABLED]button[3.9,9.2;3,.65;export;EXPORT JSON]'end
  if d.review_notes and d.review_notes~=''then f[#f+1]='button[7.1,9.2;3,.65;review_notes;REVIEW NOTES]'end
  f[#f+1]='button[10.3,9.2;3,.65;exit;LEAVE EDITOR]label[.7,10.3;'..esc(messages[n]or 'Draft autosaved / Place start/checkpoint candidates.')..']'
  core.show_formspec(n,'shift_circuit:editor',table.concat(f))
 end
 function E.begin(r)
  local n=r.host;local d=draft(n);d.view=nil;d.pending=nil;draw(n);E.open(n)
 end
 local function archive(n,approved,export)
  local data,err=L.validate_submission(draft(n).data);if data and Q.number(R,clone(data),9)==0 then data=nil;err='No checkpoint candidate is reachable from the start'end;if not data then messages[n]=err;return end
  if approved and not admin(n)then messages[n]='Admin permission required';return end
  local id=store:get_int('level_next')+1;store:set_int('level_next',id)
  catalog[tostring(id)]={data=data,author=n,approved=approved==true};persist()
  messages[n]=(approved and 'Saved enabled level #' or 'Submitted for review #')..id
  if export then
   local dir=core.get_worldpath()..'/shift_circuit_levels';core.mkdir(dir)
   local ok=core.safe_file_write(dir..'/level_'..id..'.json',core.write_json(data,true))
   messages[n]=ok and ('Exported shift_circuit_levels/level_'..id..'.json')or 'Saved, but export failed'
  end
 end
 local function confirm_draft(n,kind,id)
  local d=draft(n);d.pending={kind=kind,id=id};core.show_formspec(n,'shift_circuit:draft_confirm','formspec_version[6]size[12,6]background[0,0;12,6;sc_setup_background.png]label[.7,.7;REPLACE YOUR DRAFT?]textarea[.7,1.5;10.6,2;;;You have one draft. '..(kind=='reset'and 'Resetting clears it and unlocks board size.'or 'This saved board will replace your current draft.')..' This cannot be undone. Submitted boards are unchanged.]button[.7,4.5;5,.8;cancel;KEEP MY DRAFT]button[6.3,4.5;5,.8;confirm;YES / REPLACE DRAFT]')
 end
 local function library(n)
  local f={'formspec_version[6]size[14,11]background[0,0;14,11;sc_setup_background.png]label[.7,.6;LEVEL LIBRARY / ENABLED AND YOUR SUBMISSIONS]'}
  local ids={};for id,v in pairs(catalog)do if v.approved or v.author==n or admin(n)then ids[#ids+1]=id end end;table.sort(ids,function(a,b)return tonumber(a)<tonumber(b)end)
  local d=draft(n);local page=d.page or 1;local pages=math.max(1,math.ceil(#ids/8));page=math.min(page,pages);d.page=page
  f[#f+1]='button[.7,1.3;12.5,.65;return_draft;'..core.formspec_escape('DRAFT / '..d.data.title..' / Your autosaved work')..']'
  for j=1,8 do local id=ids[(page-1)*8+j];if id then local v=catalog[id];f[#f+1]=('button[.7,%s;12.5,.65;load_%s;%s / %s / %s]'):format(2.2+(j-1)*.85,id,core.formspec_escape(v.data.title),core.formspec_escape(v.author),v.approved and 'ENABLED'or 'NOT ENABLED')end end
  f[#f+1]='button[.7,9.5;3,.7;prev;PREVIOUS]button[4,9.5;3,.7;next;NEXT]button[10,9.5;3,.7;back;PALETTE]';core.show_formspec(n,'shift_circuit:levels',table.concat(f))
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
  if t.kind=='belt'then t.dir=(t.dir+1)%4;if t.entry~=nil then t.entry=(t.entry+1)%4 end;changed=true end
  for _,layer in ipairs({'lasers','pushers'})do for _,q in ipairs(a[layer])do if q.x==x and q.z==z then q.dir=(q.dir+1)%4;changed=true end end end
  if a.start.x==x and a.start.z==z then a.start.dir=(a.start.dir+1)%4;changed=true end
  if changed then d.locked=true;d.undo[#d.undo+1]=before;if #d.undo>30 then table.remove(d.undo,1)end;draw(n)end;return changed
 end
 function E.paint(n,x,z,direction)
  local r=room_for(n);if not r or r.solo_mode~='editor'or r.api.phase()~='editor'then return false end
  if x~=math.floor(x)or z~=math.floor(z)or x<1 or x>(draft(n).data.size or 11) or z<1 or z>(draft(n).data.size or 11) then return false end
  local d=draft(n);if d.view then return false end;d.locked=true;if direction~=nil then d.dir=direction end;local a=d.data;local b=d.brush;local k=x..','..z
  d.undo[#d.undo+1]=clone(a);if #d.undo>30 then table.remove(d.undo,1)end
  if b=='floor'or b=='pit'then a.board[k]={kind=b}
  elseif b:find('belt',1,true)or b:find('bend',1,true)then a.board[k]={kind='belt',dir=d.dir,speed=b:find('double',1,true)and 2 or 1,entry=b:find('left',1,true)and (d.dir+1)%4 or (b:find('right',1,true)and (d.dir+3)%4 or nil)}
  elseif b:find('rotator',1,true)then a.board[k]={kind='rotator',turn=b=='left rotator'and 3 or 1}
  elseif b=='checkpoint'then a.board[k]={kind='checkpoint'}
  elseif b=='repair pad'then a.board[k]={kind='repair'}  elseif b=='start'then a.start={x=x,z=z,dir=d.dir}
  elseif b=='wall'then local edge=R.edge(x,z,d.dir);a.walls[edge]=not a.walls[edge]or nil
  elseif b=='crusher'then a.overhead[k]=not a.overhead[k]and {kind='crusher'}or nil
  elseif b=='spawner'then a.spawners[k]=clone(d.spawner or {item='random',first=1,every=3,phase=(x+2*z)%3,chance=50})
  elseif b=='erase overlay'then a.spawners[k]=nil;a.overhead[k]=nil;a.pickups[k]=nil;for dir=0,3 do a.walls[R.edge(x,z,dir)]=nil end;for _,kind in ipairs({'lasers','pushers'})do for i=#a[kind],1,-1 do if a[kind][i].x==x and a[kind][i].z==z then table.remove(a[kind],i)end end end
  elseif b:find('laser',1,true)or b:find('pusher',1,true)then local kind=b:find('laser',1,true)and 'lasers'or 'pushers';for i=#a[kind],1,-1 do if a[kind][i].x==x and a[kind][i].z==z then table.remove(a[kind],i)end end;a[kind][#a[kind]+1]={x=x,z=z,dir=d.dir,power=tonumber(b:match('%d')),parity=b=='pusher odd'and 1 or 0}
  end
  draw(n);return true
 end
 core.register_on_player_receive_fields(function(p,form,f)
  if form~='shift_circuit:editor'and form~='shift_circuit:levels'and form~='shift_circuit:spawner'and form~='shift_circuit:draft_confirm'then return end
  local n=p:get_player_name();local r=room_for(n);if not r or r.solo_mode~='editor'then return end;local d=draft(n)
  if form=='shift_circuit:draft_confirm'then
   local pending=d.pending;d.pending=nil
   if f.confirm and pending then
    local v=pending.id and catalog[pending.id]
    if pending.kind=='reset'or (v and (v.approved or v.author==n or admin(n)))then
     d.data=pending.kind=='reset'and L.blank(d.data.size)or clone(v.data);d.locked=pending.kind~='reset';d.view=nil;d.undo={};d.review_notes=nil;messages[n]='Draft autosaved';draw(n)
    end
   end
   E.open(n);return
  end
  if f.return_draft then d.view=nil;d.pending=nil;draw(n);E.open(n);return end
  if f.reset_draft then confirm_draft(n,'reset');return end
  if d.view and form~='shift_circuit:levels'then
   if f.use_as_draft then confirm_draft(n,'load',d.view.id);return end
   if f.library then library(n);return end
   if f.test then local data,err=L.validate_submission(d.view.data);if data and Q.number(R,clone(data),9)>0 then r.api.edit_level(data,true);core.close_formspec(n,form)else messages[n]=err or 'No reachable route';E.open(n)end;return end
   if f.resume then draw(n);core.close_formspec(n,form);return end
   if not f.review_notes and not f.exit then if not f.quit then E.open(n)end;return end
  end
  if f.spawner_setup then
   core.show_formspec(n,'shift_circuit:spawner','formspec_version[6]size[11,8]background[0,0;11,8;sc_setup_background.png]label[.6,.5;POWERUP SPAWNER]label[.7,1.5;Rolls a random weapon, equipment or supply each spawn.]field[.7,2.4;4.5,.8;first;First round;1]field[5.5,2.4;4.5,.8;every;Every N rounds;3]field[.7,3.6;9.5,.8;rounds;Or explicit rounds (comma separated);]field[.7,4.8;4.5,.8;phase;Phase offset (0 to interval-1);0]field[5.5,4.8;4.5,.8;chance;Chance per due round (%);50]label[.7,6;Explicit rounds ignore the phase offset.]button[.7,6.8;9.5,.7;save_spawner;USE SPAWNER BRUSH]');return
  end
  if form=='shift_circuit:spawner'then
   if f.save_spawner then
    local config={item='random',first=tonumber(f.first),every=tonumber(f.every),phase=tonumber(f.phase or '0')or -1,chance=tonumber(f.chance or '50')or -1}
    if f.rounds and f.rounds:match('%S')then config={item=config.item,rounds={},phase=0,chance=config.chance};for value in f.rounds:gmatch('[^,]+')do config.rounds[#config.rounds+1]=tonumber(value)or -1 end end
    local candidate=L.blank();candidate.spawners={['2,2']=config};local valid,err=L.validate(candidate)
    if valid then d.spawner=config;d.brush='spawner';messages[n]='Spawner ready / '..config.item else messages[n]=err end
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
  if f.rename then d.data.title=tostring(f.title or d.data.title):sub(1,48);save_draft(n)end
  for i,b in ipairs(brushes)do if b~='start'and f['b'..i]then d.brush=b end end
  for i in ipairs(groups)do if f['group_'..i]then d.group=i end end
  for dir=0,3 do if f['dir_'..dir]then d.dir=dir end end
  for _,size in ipairs({10,20})do if not d.locked and f['size_'..size]and size~=d.data.size then d.undo={};d.data=L.resize(d.data,size);draw(n)end end
  if f.rotate then d.dir=(d.dir+1)%4 end
  if f.undo and #d.undo>0 then d.data=table.remove(d.undo);draw(n)end
  if f.submit then archive(n,false,false)elseif f.publish then archive(n,true,false)elseif f.export then archive(n,true,true)end
  if f.library then library(n);return end
  if f.test then local data,err=L.validate_submission(d.data);if data and Q.number(R,clone(data),9)==0 then data=nil;err='No checkpoint candidate is reachable from the start'end;if data then r.api.edit_level(data,true);core.close_formspec(n,form);return else messages[n]=err end end
  if f.resume then draw(n);core.close_formspec(n,form);return end
  if not f.quit then E.open(n)end
 end)
 -- Ship exported JSON in levels/ to make it available on every new server.
 if core.get_dir_list and core.parse_json then
  for _,file in ipairs(core.get_dir_list(path..'/levels',false))do if file:match('%.json$')then local f=io.open(path..'/levels/'..file,'r');if f then local data=L.validate_submission(core.parse_json(f:read('*a')));f:close();local key='bundled:'..file
   if data and not store:get_string(key):find('loaded',1,true)then local id=store:get_int('level_next')+1;store:set_int('level_next',id);catalog[tostring(id)]={data=data,author='Shift Circuit',approved=true};store:set_string(key,'loaded')end
  end end end;persist()
 end
 function E.review(n,id,action,note)
  if not admin(n)then return false,'Admin permission required'end;local v=catalog[tostring(id)];if not v then return false,'Board not found'end
  if action=='approve'or action=='enable'then local valid,err=L.validate_submission(v.data);if not valid then return false,err end;if Q.number(R,clone(valid),9)==0 then return false,'No checkpoint is reachable from the start'end;v.approved=true;v.enabled=true elseif action=='disable'then v.enabled=false;v.approved=false
  elseif action=='note'then note=tostring(note or ''):match('^%s*(.-)%s*$'):sub(1,2000);if note==''then return false,'Enter a note'end;v.notes=v.notes or {};v.notes[#v.notes+1]={reviewer=n,text=note}end
  persist();return true,'Review saved'
 end
 E.draft=draft;E.catalog=catalog;return E
end
