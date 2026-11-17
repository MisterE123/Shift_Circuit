local MenuUI=dofile(core.get_modpath('shift_circuit')..'/menu_ui.lua');local core=MenuUI.wrap(core)
-- One server, isolated match sessions, owned arena slots, rooms, shared course building and queue.
local engine=core
local path=core.get_modpath('shift_circuit')
local factory=dofile(path..'/runtime.lua')
local store=core.get_mod_storage()
local Styles=dofile(path..'/robot_styles.lua');local wardrobe={}
local Audio=dofile(path..'/audio.lua')(engine,store)
local menu_visible={}
local PuzzleLibrary;local audio_open={};local setup_open={};local solo_setup
local rooms,member,queue,prefs,used={},{},{},{},{}
local reconnect={} -- Authenticated player names reserve their existing robot, not a new seat.
local Chat=dofile(path..'/room_chat.lua')(engine,member)
local next_room=0;local queue_serial=0
local owned=core.deserialize(store:get_string('arena_owned_v3')) or {}
local stats=core.deserialize(store:get_string('leaderboard')) or {}
local records=core.deserialize(store:get_string('race_records')) or {}
local show,finish,launch,leave,room_menu,Editor,Lab,course_menu,racer_finished
local Moderation
local course_open={};local build_selection={};local build_message={};local creation={}
local Routes=dofile(path..'/course_routes.lua')
local Preview=dofile(path..'/board_preview.lua')
local Course=dofile(path..'/courses.lua');local CourseRules=dofile(path..'/rules.lua')
local function oriented(data,p)return Course.rotate(CourseRules,data,p.rotation)end
local B=dofile(path..'/board_builder.lua');local L=dofile(path..'/levels.lua')
local Dashboard=dofile(path..'/dashboard_ui.lua')(engine,dofile(path..'/rules.lua'))
local Configs=dofile(path..'/course_library.lua')(engine,store,B)
-- Independent puzzles are supplied by authored submissions and installed packs.
local hub_slot=store:get_int('hub_slot_v3');local hub={x=512+hub_slot*256,y=128,z=4096}
local hub_ready=false
local function esc(s)return core.formspec_escape(tostring(s or ''))end
local function wrap(s,width)local lines={};local line='';for word in s:gmatch('%S+')do if #line+#word+1>width then lines[#lines+1]=line;line=word else line=line==''and word or line..' '..word end end;lines[#lines+1]=line;return table.concat(lines,'\n')end
local function add(a,b)return {x=a.x+b.x,y=a.y+b.y,z=a.z+b.z}end
local lobby_hints={}
local function lobby_hint(p)
 local n=p:get_player_name();local text=not member[n]and 'Press I for main menu'or '';local hint=lobby_hints[n]
 if not hint then hint={id=p:hud_add({type='text',position={x=.5,y=1},offset={x=0,y=-90},alignment={x=0,y=0},number=0xb5ffd0,text=text,z_index=10}),text=text};lobby_hints[n]=hint
 elseif hint.text~=text then p:hud_change(hint.id,'text',text);hint.text=text end
end
local lobby_slots={}
local function lobby_spawn(p)
 local n=p:get_player_name();local occupied={};for name,slot in pairs(lobby_slots)do if name~=n and not member[name]and core.get_player_by_name(name)then occupied[slot]=true end end
 local slot=0;while occupied[slot]do slot=slot+1 end;lobby_slots[n]=slot
 p:set_pos(add(hub,{x=4+(slot%8)*2.3,y=-.5,z=4+math.floor(slot/8)%8*2.3}))
end
local function lobby_robot(p)
 local n=p:get_player_name();local style=Styles.get(store,n);lobby_hint(p)
 p:set_properties({visual='mesh',mesh='sc_lobby_'..style..'.obj',textures={'sc_surface_'..style..'.png'},is_visible=true,visual_size={x=.75,y=.75,z=.75},pointable=false,nametag=n,nametag_color='#a8e6dc',eye_height=1.625})
 p:hud_set_flags({hotbar=false,healthbar=false,breathbar=false,wielditem=false})
end
local function origin(slot)return {x=512+slot*256,y=128,z=4096}end
local function names(room,all)local a={};for n in pairs(room.members)do if all or not (room.spectators and room.spectators[n])then a[#a+1]=n end end;table.sort(a,function(x,y)if x==y then return false elseif x==room.host then return true elseif y==room.host then return false else return x<y end end);return a end
local function save()store:set_string('arena_owned_v3',core.serialize(owned));store:set_string('leaderboard',core.serialize(stats))end
local function allocated(slot,callback)
 local o=origin(slot);local low=add(o,{x=-6,y=-5,z=-6});local high=add(o,{x=94,y=23,z=94})
 core.emerge_area(low,high,function(_,_,remaining)
  if remaining~=0 then return end
  if not owned[tostring(slot)] then
   for z=low.z,high.z do for y=low.y,high.y do for x=low.x,high.x do
    local n=core.get_node({x=x,y=y,z=z}).name
    if n~='air' then used[slot]=nil;callback(nil);return end
   end end end
   owned[tostring(slot)]=true;save()
  end
  callback(o)
 end)
end
local function allocate(callback,start)
 local slot=start or 1
 while used[slot] and slot<256 do slot=slot+1 end
 if slot>=256 then callback(nil);return end
 used[slot]=true;allocated(slot,function(o)if o then callback(o,slot)else allocate(callback,slot+1)end end)
end
local function background(title)
 return {'formspec_version[6]size[14,10]bgcolor[#09131fee;true]background[0,0;14,10;sc_menu_background.png]style_type[button;bgimg=sc_menu_button.png;bgimg_pressed=sc_menu_button_pressed.png;border=false]label[.7,.65;'..esc(title)..']button[12.55,.3;.75,.65;audio;]image[12.67,.36;.5,.5;sc_ui_audio.png]tooltip[audio;Audio settings]'}
end
local function button(f,x,y,w,h,key,label)f[#f+1]=('button[%s,%s;%s,%s;%s;%s]'):format(x,y,w,h,key,esc(label))end
local function deliver(name,f,form)menu_visible[name]=true;local p=core.get_player_by_name(name);if p then local text=MenuUI.decorate(table.concat(f));local r=rooms[member[name]];if not r or r.status~='playing'then p:set_inventory_formspec(text)end;core.show_formspec(name,form or 'shift_circuit:online',text)end end
local function preference(name)prefs[name]=prefs[name] or {board=1,bots=1,ai='hunter',campaign_enemies=1,race_enemies=0,racers=0,difficulty=2,racer_difficulty=2,board_count=1,checkpoints=3};return prefs[name]end
local approved_choices={}
local function course_choices(review)
 local a={}
 local ids={};if Editor then for id,v in pairs(Editor.catalog)do if v.data.map_type~='puzzle'and (review or (v.approved and v.enabled~=false))then ids[#ids+1]=id end end end;table.sort(ids,function(a,b)return tonumber(a)<tonumber(b)end)
 if Editor then for _,id in ipairs(ids)do local v=Editor.catalog[id];if v.data.map_type~='puzzle'and (review or (v.approved and v.enabled~=false))then local cached=approved_choices[id];if not cached or cached.source~=v.data then cached={source=v.data,data=L.validate(v.data)};approved_choices[id]=cached end;local d=cached.data;if d then a[#a+1]={id='level_'..id,title=d.title,size=d.size,data=d}end end end end
 return a
end
local function builder(owner)
 if not owner.layout then owner.layout=B.new();local first=course_choices()[1];if first then B.place(owner.layout,first.id,first.size,0,0)end end
 return owner.layout
end
local function course_config(r,pr)
 local owner=r.solo and pr or r;local layout=builder(owner);local byid={};for _,q in ipairs(course_choices())do byid[q.id]=q end
 local platforms,ids={},{};for _,q in ipairs(layout.items)do
  local choice=byid[q.id];if not choice then return nil,'A board is no longer available'end
  platforms[#platforms+1]=choice.data;ids[#ids+1]=q.id..'@'..q.x..','..q.z..'r'..(q.rotation or 0)
 end
 if #platforms==0 then return nil,'Place at least one board'end
 local route,err=Routes.validate(owner.route,layout,course_choices());if not route then return nil,err end
 local count=#route.checkpoints>0 and #route.checkpoints or (owner.checkpoints or 3)
 local Q=dofile(path..'/courses.lua');local state=Q.assemble(dofile(path..'/rules.lua'),platforms,count,layout.items,route)
 if state.route_error then return nil,state.route_error end
 if state.checkpoint_count==0 then return nil,'The start must reach a checkpoint candidate'end
 return platforms,count,table.concat(ids,';')..':'..count..':'..(route.start and route.start.x..','..route.start.z or 'auto')..':'..(function()local a={};for _,q in ipairs(route.checkpoints)do a[#a+1]=q.x..','..q.z end;return table.concat(a,'/')end)(),layout.items,route
end
course_menu=function(n,r)
 local owner=r or preference(n);local layout=builder(owner);local editable=not r or (not r.spectators[n]and (n==r.host or r.collaborative))
 local choices=course_choices();local selection=build_selection[n]or {index=1,page=1};build_selection[n]=selection
 local chosen=choices[selection.index]or choices[1]
 if selection.route_mode then
  local route=owner.route or {checkpoints={}};local candidates,_,default=Routes.candidates(layout,choices);local start=route.start or default
  local f=background('ROUTE / CLICK CANDIDATE TILES');f[1]=f[1]:gsub('size%[14,10%]','size[16,12]'):gsub('0,0;14,10;','0,0;16,12;')
  local byid={};for _,q in ipairs(choices)do byid[q.id]=q.data end
  f[#f+1]='box[.7,1.4;8,8;#08131c]'
  for _,q in ipairs(layout.items)do local d=byid[q.id];if d then f[#f+1]=('image[%s,%s;%s,%s;%s]'):format(.7+q.x*2,1.4+q.z*2,q.w*2,q.w*2,esc(Preview.texture(oriented(d,q))))end end
  for _,q in ipairs(candidates)do local label='';local icon='checkpoint'
   if start and q.x==start.x and q.z==start.z then label='S';icon='start'end
   for i,cp in ipairs(route.checkpoints or {})do if cp.x==q.x and cp.z==q.z then label=tostring(i)end end
   local selected=label~='';local width=selected and .34 or .27
   local x,y=.7+(q.x-.5)*.2-width/2,1.4+(q.z-.5)*.2-width/2
   local key='route_at_'..q.x..'_'..q.z
   f[#f+1]='style['..key..';font=bold;font_size=*1.15;textcolor=#ffffff]'
   local texture=selected and 'sc_route_selected.png'or '(sc_map_'..icon..'.png^sc_route_candidate.png)'
   f[#f+1]=('image_button[%s,%s;%s,%s;%s;%s;%s]tooltip[%s;%s]'):format(x,y,width,width,texture,key,label,key,selected and (label=='S'and 'Start'or 'Checkpoint '..label)or 'Available checkpoint')
  end
  button(f,9.2,1.5,6,.85,'route_start',selection.route_mode=='start'and '> CHOOSE START'or 'CHOOSE START')
  button(f,9.2,2.6,6,.85,'route_checkpoints',selection.route_mode=='checkpoints'and '> CHOOSE CHECKPOINTS'or 'CHOOSE CHECKPOINTS')
  f[#f+1]='label[9.2,4;Click candidates in race order.]label[9.2,4.6;Click a numbered flag to remove it.]label[9.2,5.2;Start and checkpoints use distinct tiles.]label[9.2,6;'..(#(route.checkpoints or {})>0 and #route.checkpoints..' checkpoints chosen'or 'Checkpoint route: automatic')..']'
  button(f,9.2,7,6,.8,'route_auto','RESET TO AUTOMATIC');f[#f+1]='label[.7,10;'..esc(build_message[n]or (editable and 'Select a mode, then click an available candidate.'or 'View only / creator controls this route.'))..']'
  button(f,.7,10.8,14.5,.75,'route_back','DONE');deliver(n,f);return
 end
 if selection.config_mode then
  local f=background(selection.config_mode=='save'and 'SAVE COURSE CONFIGURATION'or 'SAVED COURSE CONFIGURATIONS')
  if selection.config_mode=='notes'then f[#f+1]='textarea[.9,1.5;12,6.5;;Admin review notes;'..esc(selection.notes or '')..']'
  elseif selection.config_mode=='delete'then
   f[#f+1]='label[.9,2;DELETE CONFIGURATION?]label[.9,3;'..esc(selection.delete_name or '')..']label[.9,4;This permanently removes the library entry. Your current course stays.]';button(f,.9,6,5.8,.8,'config_delete_cancel','KEEP ENTRY');button(f,7,6,5.8,.8,'config_delete_confirm','DELETE ENTRY')
  elseif selection.config_mode=='save'then
   f[#f+1]='field[.9,2;12,.8;configuration_name;Configuration name;'..esc(owner.configuration_name or '')..']label[.9,3.5;Saves this board layout and checkpoint count.]label[.9,4.4;You can use your own saves immediately.]label[.9,5.1;An admin can enable your saves for everyone.]label[.9,6;Saving an edited configuration updates the same entry, including its name.]'
   button(f,.9,7,12,.8,'config_save','SAVE CONFIGURATION')
  else
   local entries=Configs.list(n);local visible={};local query=(selection.config_search or ''):lower()
   for _,q in ipairs(entries)do if (q.name..' '..q.owner):lower():find(query,1,true)then visible[#visible+1]=q end end
   f[#f+1]='field[.9,1.35;9.5,.65;config_search;Search name or author;'..esc(selection.config_search or '')..']button[10.6,1.35;2.3,.65;config_find;FIND]field_close_on_enter[config_search;false]'
   local opening,closing=MenuUI.scroll(0,2.3,12.9,5.8,'configs_scroll',#visible*1.2-.15);f[#f+1]=opening
   for j,q in ipairs(visible)do local y=(j-1)*1.2
    button(f,.9,y,9.5,.6,'config_load_'..q.id,q.name:sub(1,45))
    f[#f+1]=('label[1,%s;%s / %d boards / %s]'):format(y+.8,esc(q.owner),q.count,q.status and (q.status:upper()..(not q.approved and ' / PRIVATE'or ''))or (q.approved and 'ENABLED'or 'PRIVATE / NOT ENABLED'))
    if not q.approved and not q.enabled and (q.owner==n or engine.get_player_privs(n).server)then button(f,8.3,y+.62,2.1,.4,'config_delete_'..q.id,'DELETE')end
    if #(q.notes or {})>0 then local notes={};for _,v in ipairs(q.notes)do notes[#notes+1]=v.reviewer..': '..v.text end;f[#f+1]='tooltip[config_load_'..q.id..';'..esc(table.concat(notes,'\n\n'))..']';button(f,10.6,y+.62,2.3,.4,'config_notes_'..q.id,'NOTES')end
    if engine.get_player_privs(n).server and not q.approved then button(f,10.6,y,2.3,.6,'config_approve_'..q.id,'ENABLE')elseif q.owner==n and not q.approved and q.status~='pending'then button(f,10.6,y,2.3,.6,'config_submit_'..q.id,'SUBMIT')end
   end
   if #visible==0 then f[#f+1]='label[.9,3;No saved configurations match this search.]'end
   f[#f+1]=closing
  end
  f[#f+1]='label[.9,8.45;'..esc(build_message[n]or '')..']';button(f,.9,9,12,.65,'config_back','BACK TO DESIGNER');deliver(n,f);return
 end
 if selection.inspect then
  local f=background(chosen.title..' / '..chosen.size..' x '..chosen.size)
  f[#f+1]='image[.7,1.3;7.2,7.2;'..esc(Preview.texture(chosen.data))..']'
  f[#f+1]='label[8.4,1.5;TILE LEGEND]'
  local legend={{'start','Start'},{'checkpoint','Checkpoint candidate'},{'belt_1_0','Conveyor'},{'belt_2_0','Double conveyor'},{'pit','Pit'},{'repair','Repair pad'},{'spawner','Random supply pad'},{'crusher','Overhead crusher'},{'laser_0','Laser emitter'},{'pusher_0','Pusher'},{'rotator_1','Rotator'}}
  for i,q in ipairs(legend)do local y=1.9+(i-1)*.55;f[#f+1]=('image[8.4,%s;.4,.4;sc_map_%s.png]label[9,%s;%s]'):format(y,q[1],y+.2,q[2])end
  button(f,.7,9,5.9,.65,'inspect_back','BACK');button(f,6.9,9,6.1,.65,'inspect_use','USE THIS BOARD');deliver(n,f);return
 end
 local f=background('COURSE BUILDER / '..(#layout.items)..' BOARDS');f[1]=f[1]:gsub('size%[14,10%]','size[16,12]'):gsub('0,0;14,10;','0,0;16,12;')
 f[#f+1]='label[.7,1.2;40 x 40 MAX / EACH SLOT = 10 x 10]'
 local cell=1.45
 for z=0,B.width-1 do for x=0,B.width-1 do
  f[#f+1]=('image_button[%s,%s;1.43,1.43;sc_build_empty.png;cell_%d_%d;+]'):format(.7+x*cell,1.8+z*cell,x,z)
 end end
 local byid={};for _,q in ipairs(choices)do byid[q.id]=q end
 for i,q in ipairs(layout.items)do
  local data=byid[q.id]and byid[q.id].data
  f[#f+1]=('image_button[%s,%s;%s,%s;sc_build_piece_%d.png;cell_%d_%d;%d]tooltip[cell_%d_%d;%s / %d x %d]'):format(.7+q.x*cell,1.8+q.z*cell,q.w*cell-.02,q.w*cell-.02,q.w,q.x,q.z,i,q.x,q.z,esc(data and data.title or 'Board'),q.size,q.size)
  if data then f[#f+1]=('image_button[%s,%s;%s,%s;%s;cell_%d_%d;]'):format(.75+q.x*cell,1.85+q.z*cell,q.w*cell-.12,q.w*cell-.12,esc(Preview.texture(oriented(data,q))),q.x,q.z)end
 end
 f[#f+1]='field[7.1,1.2;5.7,.6;board_search;Search boards;'..esc(selection.search or '')..']button[13,1.2;2.3,.6;search_boards;FIND]field_close_on_enter[board_search;false]'
 for i,size in ipairs({0,10,20})do button(f,7.1+(i-1)*2.8,1.95,2.6,.55,'filter_'..size,((selection.size or 0)==size and '> 'or '')..(size==0 and 'ALL SIZES'or size..' x '..size))end
 local filtered={};for index,q in ipairs(choices)do if ((selection.size or 0)==0 or q.size==selection.size)and q.title:lower():find((selection.search or ''):lower(),1,true)then filtered[#filtered+1]={index=index,q=q}end end
 local opening,closing=MenuUI.scroll(7.1,2.85,8.2,5.9,'boards_scroll',math.max(0,#filtered*2.6-.3));f[#f+1]=opening
 for row,entry in ipairs(filtered)do local index,q=entry.index,entry.q
  local y=(row-1)*2.6;local w=q.size/10*1.15
  f[#f+1]=('image_button[0,%s;%s,%s;%s;piece_%d;]'):format(y,w,w,esc(Preview.texture(q.data)),index)
  button(f,2.6,y+.15,5.6,.75,'piece_'..index,(selection.index==index and '> 'or '')..q.title:sub(1,29))
  f[#f+1]=('label[2.6,%s;%d x %d / %d x %d slots]tooltip[piece_%d;%s]'):format(y+1.2,q.size,q.size,q.size/10,q.size/10,index,esc(q.title))
 end
 if #filtered==0 then f[#f+1]='textarea[0,.3;8,1;;;No matching boards. Create or enable boards in the Workshop.]'end
 f[#f+1]=closing
 button(f,.7,8.2,1.8,.65,'build_place',not selection.remove and not selection.rotate and '[PLACE]'or 'PLACE')
 button(f,2.65,8.2,1.8,.65,'build_rotate',selection.rotate and '[ROTATE]'or 'ROTATE')
 button(f,4.6,8.2,1.85,.65,'build_remove',selection.remove and '[REMOVE]'or 'REMOVE')
 button(f,7.1,9.2,3.9,.75,'inspect','INSPECT BOARD');button(f,11.2,9.2,4.1,.75,'route_edit','START & CHECKPOINTS')
 f[#f+1]='label[.7,9.4;'..esc(wrap(build_message[n]or 'Boards must share an edge.',38))..']label[.7,10;Choose start and checkpoint candidates.]'
 button(f,.7,10.8,4.6,.75,'saved_configurations','LOAD COURSE');button(f,5.7,10.8,4.6,.75,'save_configuration','SAVE COURSE');button(f,10.7,10.8,4.6,.75,'course_back','DONE');deliver(n,f)
end

room_menu=function(name,room)
 if course_open[name]then course_menu(name,room);return end
 if audio_open[name]then return end
 local f=background('RACE ROOM / '..room.id);local layout=builder(room);local host=name==room.host
 f[#f+1]='background9[.5,1.25;7.6,6.95;sc_ui_panel.png;false;4]background9[8.3,1.25;5.2,6.95;sc_ui_panel.png;false;4]label[.8,1.65;COURSE]'
 button(f,.8,2.05,6.95,.85,'course',#layout.items..' BOARDS / OPEN DESIGNER')
 if host then button(f,.8,3.15,6.95,.6,'toggle_collaboration',room.collaborative and '> BUILD TOGETHER'or 'ONLY CREATOR BUILDS')
 else f[#f+1]='label[.8,3.45;'..(room.collaborative and 'Everyone can build this course'or 'Course managed by '..esc(room.host))..']'end
 f[#f+1]='label[.8,4.2;AI RACERS]'
 for i=0,7 do if host then button(f,.8+i*.87,4.6,.8,.65,'bots'..i,(room.bots or 1)==i and '['..i..']'or tostring(i))end end
 if not host then f[#f+1]='label[.8,4.95;'..(room.bots or 1)..' / chosen by creator]'end
 f[#f+1]='label[.8,5.65;CHECKPOINTS]'
 for i=1,9 do if host then button(f,.8+(i-1)*.77,6.05,.7,.65,'flags_'..i,(room.checkpoints or 3)==i and '['..i..']'or tostring(i))end end
 if not host then f[#f+1]='label[.8,6.4;'..(room.checkpoints or 3)..' / chosen by creator]'end
 f[#f+1]='label[.8,7.25;Humans take priority over AI racers.]label[8.65,1.65;RACERS / '..#names(room)..' OF 8]'
 for i,n in ipairs(names(room))do f[#f+1]=('label[8.65,%s;%s%s]'):format(2.25+(i-1)*.55,esc(n),n==room.host and ' *'or '')end
 local spectators=#names(room,true)-#names(room);f[#f+1]='label[8.65,7.4;'..spectators..' spectators / * creator]'
 f[#f+1]='textarea[.8,8.35;12.4,.65;;;'..esc(build_message[name]or (host and 'Ready? Start when everyone has joined.'or 'Waiting for the creator to start.'))..']'
 button(f,.7,9.1,4,.65,'leave','LEAVE ROOM');if host then button(f,8.3,9.1,5,.65,'launch','START RACE')end
 deliver(name,f)
end
local function robot_menu(n)
 local selected=Styles.get(store,n);wardrobe[n]=wardrobe[n]or {page=1}
 local chosen=Styles.list[1];for _,q in ipairs(Styles.list)do if q.id==selected then chosen=q;break end end
 local f=background('CHOOSE YOUR ROBOT')
 f[#f+1]='background9[.6,1.35;5.05,7.35;sc_ui_panel.png;false;8]label[.95,1.75;YOUR ROBOT]'
 f[#f+1]=('animated_image[.85,2.1;4.55,4.55;selected_preview;sc_preview_%s.png;24;180;1]'):format(chosen.id)
 f[#f+1]='style_type[label;font_size=*1.15]label[.95,6.6;4.3,.5;'..esc(chosen.title)..']style_type[label;font_size=*1]'
 f[#f+1]='textarea[.95,7.25;4.3,1;;;'..esc(chosen.description)..']'
 f[#f+1]='label[6,1.55;SELECT A BODY]style_type[label;font_size=*0.8;halign=center;valign=center]'
 for i,q in ipairs(Styles.list)do local x=6+((i-1)%4)*1.85;local y=1.95+math.floor((i-1)/4)*1.7;local key='robot_'..q.id
  if selected==q.id then f[#f+1]=MenuUI.selected(key)end
  button(f,x,y,1.65,1.55,key,'')
  f[#f+1]=('animated_image[%s,%s;1.15,1.15;preview_%s;sc_preview_%s.png;24;180;1]label[%s,%s;1.55,.3;%s]tooltip[%s;%s]'):format(x+.25,y+.04,q.id,q.id,x+.05,y+1.2,esc(q.title),key,esc(q.title..' / '..q.description))
 end
 f[#f+1]='style_type[label;font_size=*1;halign=left]label[6,8.9;All bodies have the same movement and hull.]'
 button(f,.7,9.25,12.6,.55,'robot_back','DONE');deliver(n,f)
end

show=function(name)
 audio_open[name]=nil;setup_open[name]=nil;course_open[name]=nil;wardrobe[name]=nil
 local room=rooms[member[name]]
 if room then
  if room.solo_mode=='test'then Lab.open(name);return end
  if room.solo_mode=='editor'then Editor.open(name);return end
  if room.status=='finished' and room.result then finish(room,room.result);return end
  if room.status=='waiting' then room_menu(name,room);return end
  local f=background('MATCH IN PROGRESS');button(f,1,2,12,1,'resume','RETURN TO BOARD');button(f,1,4,12,1,'leave','LEAVE MATCH');if room.solo_mode=='puzzle'then button(f,1,6,12,1,'retry','RESTART PUZZLE')end;deliver(name,f);return
 end
 local f=background('SHIFT CIRCUIT');local lobby_count=0;for _,p in ipairs(core.get_connected_players())do if not member[p:get_player_name()]then lobby_count=lobby_count+1 end end;f[#f+1]='label[7.3,9.6;Lobby: '..lobby_count..' / Chat: room / Global: /g message]'
 f[1]=f[1]:gsub('label%[.7,.65;', 'label[1.55,.65;')
 f[#f+1]='image[.65,.25;.75,.75;sc_game_icon.png]box[.7,1.1;12.6,.025;#436470]'
 f[#f+1]='label[.7,1.55;SINGLEPLAYER]label[7.3,1.55;MULTIPLAYER]'
 button(f,.7,2,6,.8,'tutorial','TUTORIAL')
 button(f,.7,3.05,6,.8,'solo','PUZZLES')
 button(f,.7,4.1,6,.8,'solo_race','RACE')
 button(f,.7,5.15,6,.8,'choose_robot','CHOOSE YOUR ROBOT')
 if name=='singleplayer'then
  f[#f+1]='box[7.3,2;6,.8;#14232d]label[7.6,2.4;QUICK PLAY / UNAVAILABLE]box[7.3,3.05;6,.8;#14232d]label[7.6,3.45;CREATE ROOM / UNAVAILABLE]textarea[7.5,4.1;5.5,1.2;;;Use a named player account to play multiplayer.]'
 else
  button(f,7.3,2,6,.8,queue[name] and 'unqueue' or 'queue',queue[name] and 'CANCEL QUEUE' or 'QUICK PLAY')
  button(f,7.3,3.05,6,.8,'create','CREATE ROOM')
  local y=4.15;local any=false
  for id,r in pairs(rooms)do if not r.solo and r.api and (r.status=='waiting'or r.status=='playing'or r.status=='finished')then
   any=true;local can_join=r.status=='waiting'and #names(r)<8
   if can_join then button(f,7.3,y,3.7,.6,'join_'..id,'JOIN '..r.host)else f[#f+1]=('label[7.4,%s;%s / %d racers]'):format(y+.3,esc(r.host),#names(r))end
   button(f,11.15,y,2.15,.6,'watch_'..id,'WATCH');y=y+.75;if y>5.7 then break end
  end end
  if not any then f[#f+1]='label[7.5,4.5;No open rooms.]'end
 end
 f[#f+1]='box[.7,6.5;12.6,.025;#436470]label[.7,7;WORKSHOP & COMMUNITY]'
 button(f,.7,7.4,6,.8,'editor','WORKSHOP')
 button(f,7.3,7.4,6,.8,'scores','LEADERBOARD')
 if engine.get_player_privs(name).server then button(f,.7,8.35,6,.8,'test_lab','ADMIN / TEST LAB')end
 if name~='singleplayer'then button(f,7.3,8.35,6,.8,'browse_rooms','BROWSE ALL ROOMS')end
 deliver(name,f)
end
local room_pages={}
local function browse_rooms(n,delta)
 local entries={};for _,r in pairs(rooms)do if not r.solo and r.api and r.status~='allocating'and r.status~='loading'then entries[#entries+1]=r end end
 table.sort(entries,function(a,b)return a.id<b.id end)
 local pages=math.max(1,math.ceil(#entries/6));local page=math.max(1,math.min(pages,(room_pages[n]or 1)+(delta or 0)));room_pages[n]=page
 local f=background('MULTIPLAYER / ROOMS');f[#f+1]='label[.8,1.5;CREATOR]label[6.8,1.5;RACERS]label[8.4,1.5;STATUS]'
 local opening,closing=MenuUI.scroll(0,2,13.3,6.4,'rooms_scroll',#entries*.9-.1);f[#f+1]=opening
 for i,r in ipairs(entries)do local y=(i-1)*.9
  f[#f+1]=('box[.7,%s;12.6,.8;#142d39]label[.9,%s;%s]label[6.9,%s;%d / 8]label[8.4,%s;%s]'):format(y,y+.4,esc(r.host),y+.4,#names(r),y+.4,r.status=='waiting'and 'WAITING'or r.status=='playing'and 'RACING'or 'FINISHED')
  if r.status=='waiting'and #names(r)<8 then button(f,10,y+.08,1.45,.64,'join_'..r.id,'JOIN')end
  button(f,11.6,y+.08,1.5,.64,'watch_'..r.id,'WATCH')
 end
 f[#f+1]=closing
 if #entries==0 then f[#f+1]='label[.9,3;No rooms yet. Create one from the main menu.]'end
 button(f,.7,8.8,3,.75,'refresh','MAIN MENU');deliver(n,f)
end
local function proxy(room)
 local c=setmetatable({get_mod_storage=function()return store end},{__index=engine});room.callbacks={};room.tools={};room.entity=nil
 c.register_node=function(n,d)if not engine.registered_nodes[n]then engine.register_node(n,d)end end
 c.register_entity=function(n,d)
  room.entity=d
  if not engine.registered_entities[n]then
   local initial=d.initial_properties
   engine.register_entity(n,{initial_properties=initial,on_step=function(e,dt)if e.session_step then e.session_step(e,dt)end end})
  end
 end
 c.add_entity=function(p,n,...)
  local o=engine.add_entity(p,n,...);if o then o:get_luaentity().session_step=room.entity.on_step end;return o
 end
 c.register_tool=function(n,d)
  room.tools[n]=d
  if not engine.registered_items[n]then
   local def={};for k,v in pairs(d)do def[k]=v end
   for _,key in ipairs({'on_use','on_secondary_use','on_place','on_drop'})do if d[key]then def[key]=function(stack,player,...)
    local r=player and rooms[member[player:get_player_name()]];local action=r and r.tools[n] and r.tools[n][key]
    if action then return action(stack,player,...)end;return stack
   end end end;engine.register_tool(n,def)
  end
 end
 for _,k in ipairs({'on_joinplayer','on_leaveplayer','on_player_receive_fields','on_mods_loaded','globalstep','on_shutdown','allow_player_inventory_action'})do c['register_'..k]=function(fn)room.callbacks[k]=fn end end
 c.sound_play=function(spec,params,ephemeral)
  for n in pairs(room.members)do local scoped={};for k,v in pairs(params or {})do scoped[k]=v end;scoped.to_player=n;Audio.effect(n,spec,scoped)end
 end
 c.register_chatcommand=function()end
 c.get_player_by_name=function(n)if room.members[n]then return engine.get_player_by_name(n)end end
 local edits
 c.begin_map_edit=function()edits={}end
 c.set_node=function(p,n)
  local q=add(p,room.origin);if edits then edits[q.x..','..q.y..','..q.z]={p=q,name=n.name}else engine.set_node(q,n)end
 end
 c.end_map_edit=function()
  if not edits then return end
  if engine.get_voxel_manip and VoxelArea then
   local vm=engine.get_voxel_manip();local lo,hi=vm:read_from_map(add(room.origin,{x=-6,y=-5,z=-6}),add(room.origin,{x=94,y=23,z=94}))
   local area=VoxelArea:new({MinEdge=lo,MaxEdge=hi});local data=vm:get_data();local ids={}
   for _,e in pairs(edits)do ids[e.name]=ids[e.name] or engine.get_content_id(e.name);data[area:index(e.p.x,e.p.y,e.p.z)]=ids[e.name]end
   vm:set_data(data);vm:write_to_map(true)
  else for _,e in pairs(edits)do engine.set_node(e.p,{name=e.name})end end
  edits=nil
 end
 c.add_particlespawner=function(params)
  for n in pairs(room.members)do local p={};for k,v in pairs(params)do p[k]=v end;p.playername=n;engine.add_particlespawner(p)end
 end
 c.emerge_area=function(a,b,fn)engine.emerge_area(add(a,room.origin),add(b,room.origin),fn)end
 return c
end
-- Register shared assets/tools during mod load; this template never builds an arena.
local template={origin={x=0,y=0,z=0},members={}}
factory(proxy(template),{})
local function score_player(room,n,state)
 room.scored=room.scored or {};if room.scored[n]then return end;room.scored[n]=true
 local st=stats[n]or {wins=0,games=0};st.games=st.games+1;if state.winner==n then st.wins=st.wins+1 end;stats[n]=st;save()
end
local function finish_scores(room,state)
 if room.recorded then return end;room.recorded=true
 for n in pairs(room.participants or {})do score_player(room,n,state)end
 if state.mode~='race'then for n in pairs(room.members)do Audio.effect(n,state.winner==n and 'sc_victory'or 'sc_ui_click',{gain=.3})end end
end
racer_finished=function(room,state,b)
 if b.enemy or state.mode~='race'or room.solo_mode=='editor'or room.solo_mode=='test'then return end
 score_player(room,b.id,state)
 if room.solo and b.id==room.host and state.winner==b.id then
  local key=table.concat({state.course_key or state.board_id,state.enemy_count or 0,state.racer_count or 0,state.difficulty or 2,state.racer_difficulty or 2},':')
  records[b.id]=records[b.id]or {};local previous=records[b.id][key];room.previous_record=previous;room.record=not previous or b.finish_round<previous;room.solo_recorded=true
  if room.record then records[b.id][key]=b.finish_round;store:set_string('race_records',core.serialize(records))end
 end
 if not room.members[b.id]then return end
 local f=background('FINISHED / PLACE '..b.rank)
 f[#f+1]='label[1,2;Your finish is recorded. The other racers can continue.]label[1,3;Completed in '..b.finish_round..' rounds.]'
 button(f,1,4.3,12,1,'watch_race','STAY AND SPECTATE');if b.id~='singleplayer'then button(f,1,5.7,12,1,'find_match','FIND A NEW MATCH')end;button(f,1,7.4,12,.8,'leave','MAIN MENU')
 deliver(b.id,f);Audio.effect(b.id,b.rank==1 and 'sc_victory_race'or 'sc_victory',{gain=.4})
end
finish=function(room,state)
 if room.solo_mode=='test'then Lab.open(room.host);return end
 if room.solo_mode=='editor'then Editor.result(room.host,state);return end
 if room.solo_mode=='puzzle'then
  room.status='finished';room.result=state;local n=room.host;local won=not state.failed and state.winner==n
  if won then local key='puzzle_best:'..n..':'..room.puzzle_id;local best=store:get_int(key);if best==0 or state.round<best then store:set_int(key,state.round)end end
  local f=background(won and 'PUZZLE COMPLETE'or 'PUZZLE FAILED');f[#f+1]='label[1,2;'..esc(state.failed or ('Completed in '..state.round..' rounds'))..']';button(f,1,4,12,1,'retry','TRY AGAIN');button(f,1,6,12,1,'leave','BACK TO MENU');deliver(n,f);return
 end
 if not room.solo_recorded and not room.recorded and room.solo and state.mode=='race' and state.winner==room.host then
  local key=table.concat({state.course_key or state.board_id,state.enemy_count or 0,state.racer_count or 0,state.difficulty or 2,state.racer_difficulty or 2},':')
  records[room.host]=records[room.host] or {};local previous=records[room.host][key];room.previous_record=previous;room.record=not previous or state.round<previous
  if room.record then records[room.host][key]=state.round;store:set_string('race_records',core.serialize(records))end
 end
 room.status='finished';room.result=state;finish_scores(room,state)
 local rank={};local seen={};for _,entry in ipairs(state.finishers or {})do rank[#rank+1]={id=entry.id,rank=entry.rank,next=(state.checkpoint_count or 3)+1,hp=0};seen[entry.id]=true end;for _,b in ipairs(state.bots)do if not seen[b.id]then rank[#rank+1]=b end end
 table.sort(rank,function(a,b)if a.id==b.id then return false elseif a.rank and b.rank then return a.rank<b.rank elseif a.rank then return true elseif b.rank then return false elseif a.id==state.winner then return true elseif b.id==state.winner then return false elseif a.next~=b.next then return (a.next==99 and 0 or a.next)>(b.next==99 and 0 or b.next)elseif a.hp~=b.hp then return a.hp>b.hp else return a.id<b.id end end)
 for n in pairs(room.members)do
  local f=background(room.solo and 'MISSION RESULTS' or 'RACE RESULTS / LEADERBOARD')
  f[#f+1]='label[.9,1.6;'..esc(state.winner)..' completed the route]'
  if room.solo and state.mode~='campaign' then
   f[#f+1]='label[.9,2.5;'..(state.mode=='tutorial' and 'Tutorial complete / You are ready for a campaign or race.' or (state.winner~=room.host and 'A rival finished first / no new record' or ('Completed in '..state.round..' turns / '..(room.record and 'NEW PERSONAL RECORD' or ('Best: '..tostring(room.previous_record or state.round))))))..']'
   button(f,.9,4,12,1,'retry',state.mode=='tutorial' and 'REPLAY TUTORIAL' or 'RACE AGAIN / SAME SETTINGS')
  elseif room.solo then
   local won=state.winner==n
   f[#f+1]='label[.9,2.5;'..(won and (state.level<3 and 'Next mission unlocked.' or 'Campaign complete!') or 'The rival finished first. Try again.')..']'
   if won and state.level<3 then button(f,.9,4,12,1,'next','NEXT MISSION / '..({'Wake-up shift','Cross traffic','Lockdown'})[state.level+1])else button(f,.9,4,12,1,'retry',won and 'PLAY AGAIN' or 'RETRY MISSION')end
  else
   for i,b in ipairs(rank)do f[#f+1]=('label[1,%s;%d. %s / checkpoints %d / hull %d]'):format(2.3+i*.55,i,esc(b.id),math.min(state.checkpoint_count or 3,b.next-1),math.max(0,b.hp))end
   button(f,.9,7.4,12,.8,'rematch','BUILD NEXT COURSE')
  end
  button(f,.9,8.7,12,.75,'leave','MAIN MENU');deliver(n,f)
 end
end
local function new_room(list,solo,auto,level,solo_mode,settings)
 if not solo then for _,n in ipairs(list)do if n=='singleplayer'then return nil end end end
 if #list<1 or #list>8 then return nil end
 if solo and (not solo_mode or solo_mode=='campaign')then solo_setup(list[1],'campaign',level);return nil end
 if solo_mode=='test'and not engine.get_player_privs(list[1]).server then return nil end
 next_room=next_room+1;local r={id=next_room,host=list[1],members={},spectators={},status='allocating',solo=solo,solo_mode=solo_mode or 'campaign',level=level or 1,public=auto==true,collaborative=settings and settings.collaborative==true or false,board_limit=16,bots=preference(list[1]).bots,checkpoints=3};rooms[r.id]=r
 for _,n in ipairs(list)do r.members[n]=true;member[n]=r.id;queue[n]=nil;local f=background('PREPARING YOUR ARENA');f[#f+1]='label[1,3;Reserving an enclosed factory room...]';deliver(n,f)end
 allocate(function(o,slot)
  if not rooms[r.id]then if slot then used[slot]=nil end;return end
  if not o then for n in pairs(r.members)do member[n]=nil;show(n)end;rooms[r.id]=nil;return end
  r.origin=o;r.slot=slot
  r.api=factory(proxy(r),{origin=o,multiplayer=not r.solo,test_lab=r.solo_mode=='test',board=1,defer_board=true,time_sliced_ai=true,ai_mode=preference(r.host).ai,is_spectator=function(n)return r.spectators[n]==true end,racer_finished=function(state,b)racer_finished(r,state,b)end,menu=show,ui=function(n,pitch,cue)Audio.click(n,pitch,cue)end,finished=function(state)finish(r,state)end})
  r.callbacks.on_mods_loaded()
  r.status='loading'
 end)
 return r
end
launch=function(r)
 if r.solo_mode=='puzzle'and r.api and r.puzzle_data then r.status='playing';r.result=nil;r.api.edit_level(r.puzzle_data,true);engine.close_formspec(r.host,'shift_circuit:online');return end
 if r.solo and r.solo_mode=='campaign'then solo_setup(r.host,'campaign',r.level);return end
 if r.solo_mode=='test'and r.api then r.status='playing';Lab.begin(r);return end
 if r.solo_mode=='editor' and r.api then r.status='playing';Editor.begin(r);return end
 if not r.api or r.status=='playing' then return end
 local board=preference(r.host).board;local bots=math.min(r.bots or 1,8-#names(r))
 local pr=preference(r.host);local cfg=r.solo and {enemies=r.solo_mode=='race' and pr.race_enemies or pr.campaign_enemies,racers=r.solo_mode=='race' and pr.racers or 0,difficulty=pr.difficulty,racer_difficulty=pr.racer_difficulty,puzzle=true} or nil
 if not r.solo or r.solo_mode=='race'then cfg=cfg or {};cfg.platforms,cfg.checkpoints,cfg.course_key,cfg.layout,cfg.route=course_config(r,pr);if not cfg.platforms then build_message[r.host]=cfg.checkpoints;room_menu(r.host,r);return end end
 r.api.configure(board,r.solo and 0 or bots,r.solo and 'hunter' or 'racer',cfg)
 r.recorded=false;r.result=nil;r.auto=nil;r.scored={};r.solo_recorded=false;r.participants={};for _,n in ipairs(names(r))do r.participants[n]=true end
 if r.api.start(r.host,r.solo and r.solo_mode or 'race',r.solo and r.level or 1)then r.status='playing';for n in pairs(r.members)do engine.close_formspec(n,'shift_circuit:online')end end
end
leave=function(name,disconnect)
 queue[name]=nil;local r=rooms[member[name]];local p=engine.get_player_by_name(name)
 if r then
  local takeover=(r.status=='playing'or r.status=='finished')and r.api.takeover and r.api.takeover(name)
  if disconnect and takeover then reconnect[name]=r.id end
  if r.callbacks and r.callbacks.on_leaveplayer and p then r.callbacks.on_leaveplayer(p)end
  r.members[name]=nil;r.spectators[name]=nil;member[name]=nil
  local list=names(r,true)
  if #list==0 and not (disconnect and takeover)then if r.api then r.api.cleanup()end;if r.slot then used[r.slot]=nil end;rooms[r.id]=nil
  elseif #list==0 then r.empty_grace=300
  elseif r.host==name and #list>0 then r.host=names(r)[1]or list[1]end
 end
 if p and not disconnect then p:set_detach();lobby_spawn(p);p:set_fov(65,false,0);p:get_inventory():set_list('main',{});lobby_robot(p);show(name)end
end
Lab=dofile(path..'/test_lab.lua')(engine,function(n)return rooms[member[n]]end,function(n)leave(n)end,function(n)if Moderation then Moderation.open(n)end end)
Editor=dofile(path..'/editor.lua')(engine,store,function(n)return rooms[member[n]]end,function(n)leave(n)end)
PuzzleLibrary=dofile(path..'/puzzle_library.lua')(engine,L,store,Editor.catalog,Preview,function(n,data,id)if member[n]then leave(n)end;local r=new_room({n},true,false,1,'puzzle');if r then r.puzzle_data=data;r.puzzle_id=id end end,show,function(n,data)if member[n]then leave(n)end;local r=new_room({n},true,false,1,'editor');if r then r.import_puzzle=data end end)
Editor.export_puzzle=PuzzleLibrary.export
local BoardPacks=dofile(path..'/board_packs.lua')(engine,L,store,Editor)
Moderation=dofile(path..'/moderation.lua')(engine,Editor,Configs,Preview,Routes,course_choices,function(n)return rooms[member[n]]end,function(n)Lab.open(n)end)
core.register_on_joinplayer(function(p)
 local n=p:get_player_name();preference(n)
 local r=rooms[reconnect[n]];reconnect[n]=nil
 if r and r.api and r.api.can_reclaim(n)then
  r.empty_grace=nil;r.members[n]=true;r.spectators[n]=nil;member[n]=r.id
  r.callbacks.on_joinplayer(p);Audio.update(n,Audio.context(r,false),false);return
 end
 Audio.update(n,'menu',false);lobby_spawn(p);p:set_sky({type='plain',base_color='#101c29',clouds=false});lobby_robot(p);core.after(.3,function()if core.get_player_by_name(n)then show(n)end end)
end)
core.register_on_leaveplayer(function(p)local n=p:get_player_name();leave(n,true);Audio.leave(n);menu_visible[n]=nil;audio_open[n]=nil;lobby_hints[n]=nil end)
core.register_allow_player_inventory_action(function()return 0 end)
core.register_chatcommand('sc',{description='Open the main menu.',func=function(n)show(n);return true end})
solo_setup=function(n,mode,level)
 setup_open[n]={mode=mode,level=level or 1};local pr=preference(n);local race=mode=='race'
 local f={'formspec_version[6]size[14,10]background[0,0;14,10;sc_setup_background.png]style_type[button;bgimg=sc_menu_button.png;bgimg_pressed=sc_menu_button_pressed.png;border=false]label[.7,.55;'..(race and 'SOLO RACE' or 'FACTORY PUZZLES / MISSION '..(level or 1))..']'}
 if not race then PuzzleLibrary.open(n,'puzzles');return end
 local layout=builder(pr);local choices=course_choices();local byid={};for _,q in ipairs(choices)do byid[q.id]=q end
 local pages=math.max(1,math.ceil(#choices/3));pr.solo_board_page=math.max(1,math.min(pr.solo_board_page or 1,pages));local page=pr.solo_board_page
 f[#f+1]='label[.85,1.5;'..(#layout.items>1 and ('Mixed course / '..#layout.items..' boards. Pick one to replace it.')or 'Choose a board')..']'
 if pages>1 then button(f,9.1,1.2,1.25,.6,'solo_board_prev','<');button(f,12,1.2,1.25,.6,'solo_board_next','>');f[#f+1]='label[10.6,1.5;'..page..' / '..pages..']'end
 for j=1,3 do local i=(page-1)*3+j;local q=choices[i];if q then local x=.85+(j-1)*4.2;local selected=#layout.items==1 and layout.items[1].id==q.id
  if selected then f[#f+1]=('box[%s,1.96;1.68,1.68;#7ad8c1]'):format(x-.04)end
  f[#f+1]=('image_button[%s,2;1.6,1.6;%s;solo_board_%s;]'):format(x,esc(Preview.texture(q.data)),q.id)
  button(f,x,3.7,3.8,.55,'solo_board_'..q.id,(selected and '> 'or '')..q.title)
 end end
 if #choices==0 then f[#f+1]='label[.85,2.7;No enabled boards yet. Create a board in the Workshop.]'end
 local function choice(y,key,label,value,lo,hi)
  f[#f+1]=('label[.85,%s;%s]'):format(y+.25,label)
  for v=lo,hi do button(f,6.3+(v-lo)*(hi-lo>4 and .86 or 1.35),y,hi-lo>4 and .8 or 1.2,.65,key..'_'..v,(value==v and '['..v..']' or tostring(v)))end
 end
 choice(4.5,'enemy_count',race and 'HUNTERS' or 'ENEMIES / PATROL + HUNTERS',race and pr.race_enemies or pr.campaign_enemies,0,3)
 choice(5.4,'enemy_skill','HUNTER INTELLIGENCE',pr.difficulty,1,3)
 if race then choice(6.3,'racer_count','RACERS',pr.racers,0,7);choice(7.2,'racer_skill','RACER INTELLIGENCE',pr.racer_difficulty,1,3)
 else f[#f+1]='label[.85,6.65;Collect the mission item. Visit all three flags.]label[.85,7.3;Intelligence: 1 Easy / 2 Standard / 3 Expert]'end
 if race then button(f,9.3,.3,4,.65,'course','MIX PLATFORMS')end
 button(f,.7,8.7,4,.85,'setup_back','BACK');button(f,5,8.7,8.3,.85,'play_solo',race and 'START RACE' or 'START MISSION');deliver(n,f)
end
local function audio_menu(n)
 audio_open[n]=true;local p=Audio.settings(n);local f=background('AUDIO / YOUR PERSONAL MIX')
 f[#f+1]='label[1,2;MUSIC]label[1,4.6;SOUND EFFECTS]'
 for _,group in ipairs({{key='music',values={0,.12,.22},y=2.6,current=p.music},{key='effects',values={0,.5,1},y=5.2,current=p.effects}})do
  for i,value in ipairs(group.values)do local x=1+(i-1)*4;local key=group.key..i
   if group.current==value then f[#f+1]=MenuUI.selected(key)end
   button(f,x,group.y,3.7,1,key,'')
   f[#f+1]=('image[%s,%s;.8,.8;sc_ui_volume_%d.png]tooltip[%s;%s]'):format(x+1.45,group.y+.1,i-1,key,({'Muted','Low volume','Normal volume'})[i])
  end
 end
 button(f,1,8.7,12,.8,'audio_back','BACK');deliver(n,f)
end
core.register_on_player_receive_fields(function(p,form,f)
 -- Scroll gestures are navigation, not button activations. CHG distinguishes
 -- a scroll event from scrollbar values included with an Apply button press.
 for key,value in pairs(f)do if key:match('_scroll$')and type(value)=='string'and value:match('^CHG:')then return end end
 local n=p:get_player_name();local r=rooms[member[n]];local pr=preference(n)
 if f.quit then menu_visible[n]=nil end
 if form~='shift_circuit:loadout'and not (form==''and Dashboard.changed(f))then Audio.menu(n,f)end
 if r and r.callbacks and (form=='shift_circuit:loadout'or f.loadout or f.apply or (form==''and Dashboard.changed(f)))then r.callbacks.on_player_receive_fields(p,form,f);return end
 if form~='shift_circuit:online' and form~='' then if f.room then show(n)end;return end
 if f.quit then audio_open[n]=nil;wardrobe[n]=nil;return end
 if n=='singleplayer'then
  local multiplayer=f.queue or f.create or f.create_confirm or f.find_match
  for key in pairs(f)do if key:match('^join_%d+$')or key:match('^watch_%d+$')then multiplayer=true end end
  if multiplayer then queue[n]=nil;creation[n]=nil;show(n);return end
 end
 if not r and n~='singleplayer'and (f.browse_rooms or f.rooms_prev or f.rooms_next)then browse_rooms(n,f.rooms_prev and -1 or f.rooms_next and 1 or 0);return end
 if not r and f.choose_robot then robot_menu(n);return end
 if wardrobe[n]and not r then
  if f.robot_back then show(n);return end
  if f.robot_prev or f.robot_next then wardrobe[n].page=math.max(1,math.min(math.ceil(#Styles.list/4),wardrobe[n].page+(f.robot_next and 1 or -1)));robot_menu(n);return end
  for _,q in ipairs(Styles.list)do if f['robot_'..q.id]then store:set_string('robot_style:'..n,q.id);lobby_robot(p);robot_menu(n);return end end
  return
 end
 if creation[n]and not r then
  if f.collaborative then creation[n].collaborative=f.collaborative=='true'end
  if f.create_cancel then creation[n]=nil;show(n);return end
  if f.create_confirm then local limit=16
   local settings=creation[n];settings.limit=limit;creation[n]=nil;new_room({n},false,false,nil,nil,settings);return
  end
  if not f.create then return end
 end
 if f.course and (not r or r.status=='waiting'or r.status=='finished')then course_open[n]=true;course_menu(n,r);return end
 if course_open[n]then
  if f.course_back then course_open[n]=nil;if r then room_menu(n,r)else local setup=setup_open[n];solo_setup(n,'race',setup and setup.level or 1)end;return end
  if r and r.status~='waiting'and r.status~='finished'then return end
  local selection=build_selection[n]or {index=1,page=1};build_selection[n]=selection
  local owner=r or pr
  if f.route_edit or f.route_start then selection.route_mode='start'elseif f.route_checkpoints then selection.route_mode='checkpoints'elseif f.route_back then selection.route_mode=nil end
  local can_build=not r or (not r.spectators[n]and (n==r.host or r.collaborative))
  if can_build then
   if f.route_auto then owner.route={checkpoints={}};build_message[n]='Automatic start and route restored'end
   for key in pairs(f)do local x,z=key:match('^route_at_(%d+)_(%d+)$');if x then owner.route=owner.route or {checkpoints={}};local _,note=Routes.click(owner.route,builder(owner),course_choices(),selection.route_mode or 'start',tonumber(x),tonumber(z));build_message[n]=note end end
  end
  if f.save_configuration then selection.config_mode='save';build_message[n]=nil elseif f.saved_configurations then selection.config_mode='list';selection.config_page=1;build_message[n]=nil elseif f.config_back then selection.config_mode=nil;selection.delete_id=nil end
  if f.config_find or f.key_enter_field=='config_search'then selection.config_search=tostring(f.config_search or ''):sub(1,64);selection.config_page=1 end
  if f.config_prev then selection.config_page=math.max(1,(selection.config_page or 1)-1)elseif f.config_next then selection.config_page=(selection.config_page or 1)+1 end
  if f.config_delete_cancel then selection.delete_id=nil;selection.config_mode='list'end
  if f.config_delete_confirm then local id=selection.config_mode=='delete'and selection.delete_id;selection.delete_id=nil;selection.config_mode='list';if id then local ok,message=Configs.delete(n,id);build_message[n]=message;if ok and owner.configuration_id==id then owner.configuration_id=nil end end end
  if f.config_save then
   local id,message=Configs.save(n,f.configuration_name,builder(owner),owner.checkpoints,course_choices(),owner.route,owner.configuration_id);build_message[n]=message
   if id then owner.configuration_id=id;owner.configuration_name=tostring(f.configuration_name):sub(1,48);selection.config_mode='list' end
  end
  for key in pairs(f)do
   local deletion=key:match('^config_delete_(%d+)$');if deletion then for _,q in ipairs(Configs.list(n))do if q.id==deletion and not q.approved and not q.enabled and (q.owner==n or engine.get_player_privs(n).server)then selection.delete_id=deletion;selection.delete_name=q.name;selection.config_mode='delete'end end end
   local note_id=key:match('^config_notes_(%d+)$');if note_id then for _,q in ipairs(Configs.list(n))do if q.id==note_id then local text={};for _,v in ipairs(q.notes or {})do text[#text+1]=v.reviewer..': '..v.text end;selection.notes=table.concat(text,'\n\n');selection.config_mode='notes'end end end
   local submission=key:match('^config_submit_(%d+)$');if submission then local _,message=Configs.submit(n,submission);build_message[n]=message end
   local approve=key:match('^config_approve_(%d+)$');if approve then local _,message=Configs.approve(n,approve);build_message[n]=message end
   local id=key:match('^config_load_(%d+)$');if id then
    if not r or (not r.spectators[n]and (n==r.host or r.collaborative))then
     local saved,err=Configs.load(n,id,course_choices(),builder(owner).limit)
     if saved then owner.layout=saved.layout;owner.route=saved.route;owner.configuration_name=saved.name;owner.configuration_id=saved.owner==n and id or nil;if not r or n==r.host then owner.checkpoints=saved.checkpoints end;selection.config_mode=nil;build_message[n]='Loaded '..saved.name else build_message[n]=err end
    else build_message[n]='Only the creator may change this layout'end
   end
  end
  if f.search_boards or f.key_enter_field=='board_search'then selection.search=tostring(f.board_search or ''):sub(1,64);selection.page=1 end
  for _,size in ipairs({0,10,20})do if f['filter_'..size]then selection.size=size;selection.page=1 end end
  if f.inspect then selection.inspect=true elseif f.inspect_back or f.inspect_use then selection.inspect=nil;if f.inspect_use then selection.remove=false end end
  local choices=course_choices();for i in ipairs(choices)do if f['piece_'..i]then selection.index=i;selection.remove=false;selection.rotate=false end end
  if f.pieces_prev then selection.page=math.max(1,selection.page-1)elseif f.pieces_next then selection.page=selection.page+1 end
  if f.build_remove then selection.remove=true;selection.rotate=false elseif f.build_place then selection.remove=false;selection.rotate=false elseif f.build_rotate then selection.rotate=true;selection.remove=false;build_message[n]='Click a placed board to turn it 90 degrees.'end
  local editable=not r or (not r.spectators[n]and (r.host==n or r.collaborative))
  for key in pairs(f)do local x,z=key:match('^cell_(%d+)_(%d+)$');if x then
   if editable then local layout=builder(r or pr);local ok,message
    if selection.rotate then ok,message=B.rotate(layout,tonumber(x),tonumber(z));if ok then owner.route={checkpoints={}}end elseif selection.remove then ok,message=B.remove(layout,tonumber(x),tonumber(z))else local q=choices[selection.index];if q then ok,message=B.place(layout,q.id,q.size,tonumber(x),tonumber(z))else ok,message=false,'No enabled boards available'end end
    if ok and not Routes.validate(owner.route,layout,choices)then owner.route={checkpoints={}}end
    build_message[n]=ok and (selection.rotate and 'Board rotated. Route reset to automatic.'or selection.remove and 'Board returned to inventory.'or 'Board placed.')or message
   else build_message[n]='Only the creator may change this layout'end
  end end
  if r then for name in pairs(r.members)do if course_open[name]then course_menu(name,r)end end else course_menu(n)end;return
 end
 local setup=setup_open[n]
 if setup and not r then
  local changed=false
  if f.solo_board_prev then pr.solo_board_page=math.max(1,(pr.solo_board_page or 1)-1);changed=true elseif f.solo_board_next then pr.solo_board_page=(pr.solo_board_page or 1)+1;changed=true end
  for _,q in ipairs(course_choices())do if f['solo_board_'..q.id]then local layout=B.new();if B.place(layout,q.id,q.size,0,0)then pr.layout=layout;pr.route=nil;pr.configuration_id=nil;pr.configuration_name=nil;changed=true end;break end end
  for key,bounds in pairs({enemy_count={0,3},enemy_skill={1,3},racer_count={0,7},racer_skill={1,3}})do
   for v=bounds[1],bounds[2]do if f[key..'_'..v]then f[key]=tostring(v)end end
   if f[key]then local value=tonumber(tostring(f[key]):match(':(%d+)') or f[key]);if value then value=math.max(bounds[1],math.min(bounds[2],math.floor(value)))
    if key=='enemy_count'then pr[setup.mode=='race' and 'race_enemies' or 'campaign_enemies']=value elseif key=='enemy_skill'then pr.difficulty=value elseif key=='racer_count'then pr.racers=value else pr.racer_difficulty=value end;changed=true
   end end
  end
  if f.play_solo then setup_open[n]=nil;new_room({n},true,false,setup.level,setup.mode);return end
  if f.setup_back then setup_open[n]=nil;show(n);return end
  if changed and not f.audio then solo_setup(n,setup.mode,setup.level);return end
 end
 if f.audio then audio_menu(n);return end
 if f.audio_back then audio_open[n]=nil;show(n);return end
 for i,v in ipairs({0,.12,.22})do if f['music'..i]then Audio.set(n,'music',v);audio_menu(n);return end end
 for i,v in ipairs({0,.5,1})do if f['effects'..i]then Audio.set(n,'effects',v);audio_menu(n);return end end
 if f.find_match then leave(n);queue_serial=queue_serial+1;queue[n]=queue_serial;show(n);return end
 if f.watch_race and r then core.close_formspec(n,form);r.api.watch(n);return end
 if f.leave then leave(n);return end
 if f.resume then core.close_formspec(n,form);return end
 if f.room or f.refresh then show(n);return end
 if f.scores then
  local f2=background('SERVER LEADERBOARD');local a={};for name,v in pairs(stats)do a[#a+1]={name=name,wins=v.wins,games=v.games}end;table.sort(a,function(x,y)if x.wins~=y.wins then return x.wins>y.wins else return x.name<y.name end end)
  local opening,closing=MenuUI.scroll(1,1.7,12,6.6,'scores_scroll',#a*.55);f2[#f2+1]=opening
  for i,v in ipairs(a)do f2[#f2+1]=('label[0,%s;%d. %s / %d wins / %d games]'):format(.25+(i-1)*.55,i,esc(v.name),v.wins,v.games)end;f2[#f2+1]=closing
  button(f2,1,8.8,12,.8,'refresh','BACK');deliver(n,f2);return
 end
 if r then
  if r.spectators[n]then return end
  if f.next and r.solo and r.solo_mode=='campaign' and r.status=='finished' and r.result and r.result.winner==n then if r.api.next()then r.level=r.level+1;r.status='playing';r.recorded=false;core.close_formspec(n,form)end;return end
  if f.retry and r.solo and (r.status=='finished'or r.solo_mode=='puzzle') then launch(r);return end
  if f.rematch and not r.solo and r.status=='finished' then r.status='waiting';r.auto=nil;for name in pairs(r.members)do room_menu(name,r)end;return end
  if r.status~='waiting' and r.status~='finished' then return end

  if n==r.host then if f.toggle_collaboration then r.collaborative=not r.collaborative end;for i=0,7 do if f['bots'..i]then r.bots=i;pr.bots=i end end;for i=1,9 do if f['flags_'..i]then r.checkpoints=i end end end
  if f.launch and n==r.host then launch(r);return end
  for name in pairs(r.members)do room_menu(name,r)end;return
 end
 if f.hunter then pr.ai='hunter'elseif f.racer then pr.ai='racer'
 elseif f.test_lab and engine.get_player_privs(n).server then new_room({n},true,false,1,'test');return
 elseif f.editor then new_room({n},true,false,1,'editor');return
 elseif f.tutorial then PuzzleLibrary.open(n,'tutorial');return
 elseif f.solo or f.continue or f.solo_race then solo_setup(n,f.solo_race and 'race' or 'campaign',f.continue and math.max(1,store:get_int('progress:'..n)) or 1);return
 elseif f.create then
  creation[n]={limit=16,collaborative=false}
  local f2=background('CREATE ROOM');f2[#f2+1]='label[1,2;Build any connected course within 40 x 40 squares.]checkbox[1,4;collaborative;Allow all racers to build together;false]label[1,5;Off: only you edit the course. Spectators can always view it.]'
  button(f2,1,8.7,4,.8,'create_cancel','BACK');button(f2,5.4,8.7,7.6,.8,'create_confirm','CREATE ROOM');deliver(n,f2);return
 elseif f.queue then queue_serial=queue_serial+1;queue[n]=queue_serial
 elseif f.unqueue then queue[n]=nil
 else
  for key in pairs(f)do
   local id=tonumber(key:match('^join_(%d+)$')or key:match('^watch_(%d+)$'));local target=id and rooms[id]
   if target and not target.solo and target.api and (target.status=='waiting'or target.status=='playing'or target.status=='finished')then
    if member[n]==id then return end
    local reclaim=target.api.can_reclaim(n)
    local spectator=not reclaim and (key:match('^watch_')or target.status~='waiting'or #names(target)>=8)
    if member[n]then leave(n)end
    target.empty_grace=nil;reconnect[n]=nil
    queue[n]=nil;target.members[n]=true;member[n]=id;target.spectators[n]=spectator and true or nil
    target.callbacks.on_joinplayer(p)
    if spectator then core.close_formspec(n,form);if target.status=='playing'then target.api.watch(n)end
    else for name in pairs(target.members)do room_menu(name,target)end end;return
   end
  end
 end
 show(n)
end)
local clock=0
core.register_globalstep(function(dt)
 clock=clock+dt;Audio.tick(dt)
 local waiting={};for n in pairs(queue)do if n~='singleplayer'and core.get_player_by_name(n)and not member[n]then waiting[#waiting+1]=n end end
 table.sort(waiting,function(a,b)return queue[a]<queue[b]end)
 local public={};for _,r in pairs(rooms)do if r.public and r.status=='waiting'and not r.solo then public[#public+1]=r end end;table.sort(public,function(a,b)return a.id<b.id end)
 for _,r in ipairs(public)do local changed=false
  while #waiting>0 and #names(r)<8 do local n=table.remove(waiting,1);local pr=preference(n);queue[n]=nil;r.members[n]=true;member[n]=r.id;r.callbacks.on_joinplayer(core.get_player_by_name(n));changed=true end
  if changed then for n in pairs(r.members)do room_menu(n,r)end end
 end
 for _,r in pairs(rooms)do
  if r.empty_grace then r.empty_grace=r.empty_grace-dt end
  if not next(r.members)and ((r.empty_grace and r.empty_grace<=0)or (r.status=='finished'and not r.empty_grace))then r.api.cleanup();used[r.slot]=nil;rooms[r.id]=nil end
  if rooms[r.id]and r.callbacks and r.callbacks.globalstep then r.callbacks.globalstep(dt)end
  if r.status=='loading' and r.api.snapshot().phase=='lobby' then
   for _,n in ipairs(names(r))do local p=core.get_player_by_name(n);if p then r.callbacks.on_joinplayer(p)end end
   r.status='waiting';if not r.solo then for n in pairs(r.members)do Audio.effect(n,'sc_success',{gain=.25,pitch=1.15})end end;if r.solo then launch(r)else for n in pairs(r.members)do room_menu(n,r)end end
  end
 end
 if clock<1 then return end;clock=0
 for _,p in ipairs(core.get_connected_players())do local n=p:get_player_name();local r=rooms[member[n]];local playing=r and r.status=='playing';lobby_hint(p);local phase=playing and r.api.phase();Audio.update(n,Audio.context(r,menu_visible[n]),playing and phase~='program')end
 local q={};for n in pairs(queue)do if n~='singleplayer'and core.get_player_by_name(n) and not member[n]then q[#q+1]=n else queue[n]=nil end end;table.sort(q,function(a,b)return queue[a]<queue[b]end)
 while #q>=2 do local group={};for i=1,math.min(8,#q)do group[#group+1]=table.remove(q,1)end;new_room(group,false,true,nil,nil,{limit=16,collaborative=true})end
 for _,p in ipairs(core.get_connected_players())do if not member[p:get_player_name()] and hub_ready then local q=p:get_pos();if q.y<hub.y-4 or q.y>hub.y+26 or math.abs(q.x-(hub.x+12))>21 or math.abs(q.z-(hub.z+12))>21 then p:set_pos(add(hub,{x=12,y=2,z=12}))end end end
end)
core.register_on_mods_loaded(function() core.after(0,function()
 local function build_hub(o,slot)
  hub=o;hub_slot=slot;store:set_int('hub_slot_v3',slot)
  for z=-6,30 do for x=-6,30 do for y=-1,23 do if y==-1 or y==23 or x==-6 or x==30 or z==-6 or z==30 then core.set_node(add(hub,{x=x,y=y,z=z}),{name=((y==3 and (x+z)%5==0) or (y==-1 and x%5==0 and z%5==0)) and 'shift_circuit:light' or 'shift_circuit:beam'})end end end end
  hub_ready=true
 end
 used[hub_slot]=true
 allocated(hub_slot,function(o)
  if o then build_hub(o,hub_slot)else allocate(function(other,slot)if other then build_hub(other,slot)else core.log('error','No empty factory lobby location available.')end end)end
 end)
end) end)
core.register_on_shutdown(function()Audio.shutdown();for _,r in pairs(rooms)do if r.api then r.api.cleanup()end end;save()end)
shift_circuit={register_board_pack=BoardPacks.register,register_puzzle_pack=PuzzleLibrary.register,puzzles=PuzzleLibrary,rooms=rooms,queue=queue,member=member,show=show,new_room=new_room,leave=leave,launch=launch,hub=function()return hub,hub_ready end}
