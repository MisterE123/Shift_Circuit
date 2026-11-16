-- Persisted course configurations. Approval applies to an immutable saved revision.
return function(core,store,B)
 local Routes=dofile(core.get_modpath('shift_circuit')..'/course_routes.lua')
 local A={};local records=core.deserialize(store:get_string('course_configurations'))or {}
 local function clone(t)return core.deserialize(core.serialize(t))end
 local function admin(n)return core.get_player_privs(n).server==true end
 local function persist()store:set_string('course_configurations',core.serialize(records))end
 for _,v in pairs(records)do if v.enabled==false then v.approved=false end;v.enabled=v.approved==true;v.status=v.status or (v.approved and 'enabled'or 'pending')end
 local function name_key(name)return tostring(name or ''):match('^%s*(.-)%s*$'):gsub('%s+',' '):lower()end
 local function visible(n,v)return v and (v.owner==n or v.approved or admin(n))end
 local function validate(layout,choices,limit)
  if type(layout)~='table'or type(layout.items)~='table'or #layout.items==0 then return nil,'Place at least one board first'end
  local byid={};for _,v in ipairs(choices)do byid[v.id]=v end
  local result=B.new(limit)
  for _,q in ipairs(layout.items)do
   local board=byid[q.id];if not board or board.size~=q.size then return nil,'A board in this configuration is no longer available'end
   local w=q.size/10
   if (q.size~=10 and q.size~=20)or type(q.x)~='number'or type(q.z)~='number'or q.x~=math.floor(q.x)or q.z~=math.floor(q.z)or q.x<0 or q.z<0 or q.x+w>B.width or q.z+w>B.width then return nil,'Configuration does not fit the 40 x 40 course'end
   for x=q.x,q.x+w-1 do for z=q.z,q.z+w-1 do if B.at(result,x,z)then return nil,'Configuration boards overlap'end end end
   local rotation=q.rotation or 0
   if type(rotation)~='number'or rotation~=math.floor(rotation)or rotation<0 or rotation>3 then return nil,'Invalid board rotation'end
   result.items[#result.items+1]={id=q.id,size=q.size,w=w,x=q.x,z=q.z,rotation=rotation}
  end
  if not B.connected(result.items)then return nil,'Configuration contains disconnected boards'end
  return result
 end
 function A.list(n)
  local a={};for id,v in pairs(records)do if visible(n,v)then a[#a+1]={id=id,name=v.name,owner=v.owner,approved=v.approved,enabled=v.enabled,status=v.status,notes=clone(v.notes or {}),count=#v.layout.items}end end
  table.sort(a,function(x,y)if (x.owner==n)~=(y.owner==n)then return x.owner==n end;if x.name~=y.name then return x.name<y.name end;return tonumber(x.id)<tonumber(y.id)end);return a
 end
 function A.save(n,name,layout,checkpoints,choices,route,entry_id)
  name=tostring(name or ''):match('^%s*(.-)%s*$'):sub(1,48);if name==''then return nil,'Give the configuration a name'end
  local valid,err=validate(layout,choices,16);if not valid then return nil,err end
  local selected;selected,err=Routes.validate(route,valid,choices);if not selected then return nil,err end
  local id=entry_id and tostring(entry_id);if id and (not records[id]or records[id].owner~=n)then return nil,'Only the author can edit this configuration'end
  for key,v in pairs(records)do if key~=id and name_key(v.name)==name_key(name)then if not id and v.owner==n then id=key else return nil,'That name is already used in the global library. Choose a different name.'end end end
  if not id then local serial=store:get_int('course_configuration_next')+1;store:set_int('course_configuration_next',serial);id=tostring(serial)end
  local previous=records[id];if previous and (previous.approved or previous.enabled)and not admin(n)then return nil,'Enabled entries are protected. Ask an admin to disable it, or save a copy under a new name.'end;records[id]={name=name,owner=n,approved=admin(n),enabled=admin(n),status=admin(n)and 'enabled'or 'saved',notes=previous and clone(previous.notes or {})or {},layout=clone(valid),route=clone(selected),checkpoints=math.max(1,math.min(9,math.floor(tonumber(checkpoints)or 3)))};persist()
  return id,admin(n)and 'Saved and enabled for everyone.'or 'Saved for you. An admin can enable it for everyone.'
 end
 function A.load(n,id,choices,limit)
  local v=records[tostring(id)];if not visible(n,v)then return nil,'Configuration is private until enabled'end
  if not v.approved and v.owner~=n and not admin(n)then return nil,'Configuration is not enabled for public use'end
  local layout,err=validate(v.layout,choices,limit);if not layout then return nil,err end
  local route;route,err=Routes.validate(v.route,layout,choices);if not route then return nil,err end
  return {layout=layout,route=route,checkpoints=v.checkpoints,name=v.name,owner=v.owner}
 end
 function A.submit(n,id)
  local v=records[tostring(id)];if not v or v.owner~=n then return false,'Only the author can submit this configuration'end
  if v.approved or v.enabled then return false,'An admin must disable this configuration before resubmission'end
  v.status='pending';v.approved=false;v.enabled=false;persist();return true,'Submitted for review.'
 end
 function A.delete(n,id)
  id=tostring(id);local v=records[id];if not v then return false,'Configuration not found'end
  if v.owner~=n and not admin(n)then return false,'Only the author or an admin may delete this configuration'end
  if v.approved or v.enabled then return false,'Disable this configuration before deleting it'end
  records[id]=nil;persist();return true,'Configuration deleted.'
 end
 function A.approve(n,id)
  if not admin(n)then return false,'Admin permission required'end
  local v=records[tostring(id)];if not v then return false,'Configuration not found'end
  v.approved=true;v.enabled=true;v.status='enabled';persist();return true,'Configuration enabled for everyone.'
 end
 function A.inspect(n,id)if admin(n)then return clone(records[tostring(id)])end end
 function A.review(n,id,action,note)
  if not admin(n)then return false,'Admin permission required'end;local v=records[tostring(id)];if not v then return false,'Configuration not found'end
  if action=='approve'or action=='enable'then return A.approve(n,id)elseif action=='disable'or action=='reject'then v.enabled=false;v.approved=false;v.status=action=='reject'and 'rejected'or 'disabled';note=tostring(note or ''):sub(1,2000);v.notes=v.notes or {};v.notes[#v.notes+1]={reviewer=n,text=v.status..(note~=''and (': '..note)or '')}
  elseif action=='note'then note=tostring(note or ''):match('^%s*(.-)%s*$'):sub(1,2000);if note==''then return false,'Enter a note'end;v.notes=v.notes or {};v.notes[#v.notes+1]={reviewer=n,text=note}end
  persist();return true,'Review saved'
 end
 return A
end
