return function(core,Editor,Configs,Preview,Routes,choices,room_for,back)
 local M={};local views={};local path=core.get_modpath('shift_circuit')
 local function admin(n)return core.get_player_privs(n).server==true end
 local function esc(s)return core.formspec_escape(tostring(s or ''))end
 local function records(n,kind)
  local entries={}
  if kind=='boards'then for id,v in pairs(Editor.catalog)do entries[#entries+1]={id=id,name=v.data.title,owner=v.author,approved=v.approved,enabled=v.enabled,notes=v.notes,data=v.data}end
  else for _,q in ipairs(Configs.list(n))do local v=Configs.inspect(n,q.id);v.id=q.id;entries[#entries+1]=v end end
  table.sort(entries,function(a,b)if not not a.approved~=not not b.approved then return not a.approved end;return tonumber(a.id)<tonumber(b.id)end);return entries
 end
 local function button(f,x,y,w,key,label)f[#f+1]=('button[%s,%s;%s,.7;%s;%s]'):format(x,y,w,key,esc(label))end
 function M.open(n)
  local room=room_for(n);if not admin(n)or not room or room.solo_mode~='test'then return end
  local v=views[n]or {kind='boards',page=1,search=''};views[n]=v
  local entries=records(n,v.kind);local selected
  for _,q in ipairs(entries)do if q.id==v.id then selected=q end end
  local f={'formspec_version[6]size[16,12]background[0,0;16,12;sc_setup_background.png]style_type[button;bgimg=sc_menu_button.png;bgimg_pressed=sc_menu_button_pressed.png;border=false]label[.7,.5;ADMIN / SUBMISSION REVIEW]'}
  if selected then
   f[#f+1]='label[.7,1.15;'..esc(selected.name..' / '..selected.owner)..']'
   if selected.data then f[#f+1]='image[.7,1.6;7,7;'..esc(Preview.texture(selected.data))..']'
   else
    local byid={};for _,q in ipairs(choices(true))do byid[q.id]=q.data end
    f[#f+1]='box[.7,1.6;7,7;#08131c]'
    for _,q in ipairs(selected.layout.items)do local d=byid[q.id];if d then f[#f+1]=('image[%s,%s;%s,%s;%s]'):format(.7+q.x*1.75,1.6+q.z*1.75,q.w*1.75,q.w*1.75,esc(Preview.texture(d)))end end
    local _,_,default=Routes.candidates(selected.layout,choices(true));local route=selected.route or {};local start=route.start or default
    if start then f[#f+1]=('image[%s,%s;.2,.2;sc_map_start.png]'):format(.7+(start.x-1)*.175,1.6+(start.z-1)*.175)end
    for i,q in ipairs(route.checkpoints or {})do f[#f+1]=('label[%s,%s;%d]'):format(.7+(q.x-.5)*.175,1.6+(q.z-.5)*.175,i)end
   end
   f[#f+1]='label[8.3,1.8;'..(selected.approved and 'ENABLED FOR EVERYONE'or 'NOT ENABLED FOR PUBLIC USE')..']'
   button(f,8.3,2.3,3.2,'enable','ENABLE');button(f,11.8,2.3,3.2,'disable','DISABLE')
   local notes={};for _,q in ipairs(selected.notes or {})do notes[#notes+1]=q.reviewer..': '..q.text end
   f[#f+1]='textarea[8.3,3.4;6.7,2.8;;Review history;'..esc(table.concat(notes,'\n\n'))..']textarea[8.3,6.4;6.7,2.2;note;Note to submitter;]'
   button(f,8.3,8.7,6.7,'save_note','SAVE NOTE FOR SUBMITTER');button(f,.7,9.1,7,'playtest','PLAYTEST IN THIS TEST ROOM')
   f[#f+1]='label[.7,10.2;'..esc(v.message or 'Notes are visible in the submitter\'s board or configuration library.')..']';button(f,.7,10.9,14.3,'list','BACK TO SUBMISSIONS')
  else
   button(f,.7,1.2,4,'boards',v.kind=='boards'and '> BOARDS'or 'BOARDS');button(f,5,1.2,4,'configs',v.kind=='configs'and '> CONFIGURATIONS'or 'CONFIGURATIONS');button(f,9.3,1.2,6,'pending',v.pending and 'NOT ENABLED ONLY'or 'ALL SUBMISSIONS')
   f[#f+1]='field[.7,2.4;11.5,.7;search;Search title or submitter;'..esc(v.search)..']';button(f,12.5,2.4,2.8,'find','FIND')
   local filtered={};for _,q in ipairs(entries)do if (not v.pending or not q.approved)and (q.name..' '..q.owner):lower():find(v.search:lower(),1,true)then filtered[#filtered+1]=q end end
   local pages=math.max(1,math.ceil(#filtered/6));v.page=math.min(v.page,pages)
   for i=1,6 do local q=filtered[(v.page-1)*6+i];if q then button(f,.7,3.5+(i-1)*.9,14.6,'inspect_'..q.id,q.name..' / '..q.owner..' / '..(q.approved and 'Enabled'or 'Not enabled'))end end
   button(f,.7,9.4,4,'prev','PREVIOUS');button(f,11.3,9.4,4,'next','NEXT');f[#f+1]='label[6.9,9.7;'..v.page..' / '..pages..']';button(f,.7,10.7,14.6,'back','BACK TO TEST LAB')
  end
  core.show_formspec(n,'shift_circuit:moderation',table.concat(f))
 end
 core.register_on_player_receive_fields(function(p,form,f)
  if form~='shift_circuit:moderation'then return end
  local n=p:get_player_name();local r=room_for(n);if not admin(n)or not r or r.solo_mode~='test'then return end
  local v=views[n];if not v then return end
  if f.back then back(n);return end
  if f.boards or f.configs then v.kind=f.boards and 'boards'or 'configs';v.id=nil;v.page=1 end
  if f.pending then v.pending=not v.pending;v.page=1 end
  if f.find then v.search=tostring(f.search or ''):sub(1,64);v.page=1 end
  if f.prev then v.page=math.max(1,v.page-1)elseif f.next then v.page=v.page+1 end
  if f.list then v.id=nil;v.message=nil end
  for key in pairs(f)do local id=key:match('^inspect_(%d+)$');if id then v.id=id;v.message=nil end end
  if v.id then
   for _,action in ipairs({'approve','enable','disable','save_note'})do if f[action]then
    local fn=v.kind=='boards'and Editor.review or Configs.review;local _,message=fn(n,v.id,action=='save_note'and 'note'or action,f.note);v.message=message
   end end
   if f.playtest then
    local selected;for _,q in ipairs(records(n,v.kind))do if q.id==v.id then selected=q end end
    if selected then local cfg={platforms={},layout={},checkpoints=selected.checkpoints or 3,route=selected.route}
     if selected.data then cfg.platforms={selected.data};cfg.layout={{x=0,z=0}}
     else local byid={};for _,q in ipairs(choices(true))do byid[q.id]=q.data end;for _,q in ipairs(selected.layout.items)do if not byid[q.id]then v.message='A required board is missing';M.open(n);return end;cfg.platforms[#cfg.platforms+1]=byid[q.id];cfg.layout[#cfg.layout+1]=q end end
     local R=dofile(path..'/rules.lua');local Q=dofile(path..'/courses.lua');local state=Q.assemble(R,cfg.platforms,cfg.checkpoints,cfg.layout,cfg.route)
     if state.route_error or (state.checkpoint_count or 0)<1 then v.message=state.route_error or 'Add a reachable checkpoint besides the start';M.open(n);return end
     r.api.configure(1,0,'racer',cfg);r.api.start(n,'race',1);core.close_formspec(n,form);return
    end
   end
  end
  if not f.quit then M.open(n)end
 end)
 return M
end
