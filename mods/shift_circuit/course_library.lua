-- Persisted course configurations. Approval applies to an immutable saved revision.
return function(core,store,B)
 local Routes=dofile(core.get_modpath('shift_circuit')..'/course_routes.lua')
 local A={};local records=core.deserialize(store:get_string('course_configurations'))or {}
 local function clone(t)return core.deserialize(core.serialize(t))end
 local function admin(n)return core.get_player_privs(n).server==true end
 local function persist()store:set_string('course_configurations',core.serialize(records))end
 for _,v in pairs(records)do if v.enabled==false then v.approved=false end;v.enabled=v.approved==true end
 local function visible(n,v)return v and (v.owner==n or v.approved or admin(n))end
 local function validate(layout,choices,limit)
  if type(layout)~='table'or type(layout.items)~='table'or #layout.items==0 then return nil,'Place at least one board first'end
  if #layout.items>limit then return nil,'This configuration exceeds the room board limit'end
  local byid={};for _,v in ipairs(choices)do byid[v.id]=v end
  local result=B.new(limit)
  for _,q in ipairs(layout.items)do
   local board=byid[q.id];if not board or board.size~=q.size then return nil,'A board in this configuration is no longer available'end
   local w=q.size/10
   if (q.size~=10 and q.size~=20)or type(q.x)~='number'or type(q.z)~='number'or q.x~=math.floor(q.x)or q.z~=math.floor(q.z)or q.x<0 or q.z<0 or q.x+w>B.width or q.z+w>B.width then return nil,'Configuration does not fit the 40 x 40 course'end
   for x=q.x,q.x+w-1 do for z=q.z,q.z+w-1 do if B.at(result,x,z)then return nil,'Configuration boards overlap'end end end
   result.items[#result.items+1]={id=q.id,size=q.size,w=w,x=q.x,z=q.z}
  end
  if not B.connected(result.items)then return nil,'Configuration contains disconnected boards'end
  return result
 end
 function A.list(n)
  local a={};for id,v in pairs(records)do if visible(n,v)then a[#a+1]={id=id,name=v.name,owner=v.owner,approved=v.approved,enabled=v.enabled,notes=clone(v.notes or {}),count=#v.layout.items}end end
  table.sort(a,function(x,y)if (x.owner==n)~=(y.owner==n)then return x.owner==n end;if x.name~=y.name then return x.name<y.name end;return tonumber(x.id)<tonumber(y.id)end);return a
 end
 function A.save(n,name,layout,checkpoints,choices,route)
  name=tostring(name or ''):match('^%s*(.-)%s*$'):sub(1,48);if name==''then return nil,'Give the configuration a name'end
  local valid,err=validate(layout,choices,16);if not valid then return nil,err end
  local selected;selected,err=Routes.validate(route,valid,choices);if not selected then return nil,err end
  local id;for key,v in pairs(records)do if v.owner==n and v.name==name then id=key;break end end
  if not id then local serial=store:get_int('course_configuration_next')+1;store:set_int('course_configuration_next',serial);id=tostring(serial)end
  local previous=records[id];records[id]={name=name,owner=n,approved=admin(n),enabled=admin(n),notes=previous and clone(previous.notes or {})or {},layout=clone(valid),route=clone(selected),checkpoints=math.max(1,math.min(9,math.floor(tonumber(checkpoints)or 3)))};persist()
  return id,admin(n)and 'Saved and enabled for everyone.'or 'Saved for you. An admin can enable it for everyone.'
 end
 function A.load(n,id,choices,limit)
  local v=records[tostring(id)];if not visible(n,v)then return nil,'Configuration is private until enabled'end
  if not v.approved and v.owner~=n and not admin(n)then return nil,'Configuration is not enabled for public use'end
  local layout,err=validate(v.layout,choices,limit);if not layout then return nil,err end
  local route;route,err=Routes.validate(v.route,layout,choices);if not route then return nil,err end
  return {layout=layout,route=route,checkpoints=v.checkpoints,name=v.name,owner=v.owner}
 end
 function A.approve(n,id)
  if not admin(n)then return false,'Admin permission required'end
  local v=records[tostring(id)];if not v then return false,'Configuration not found'end
  v.approved=true;v.enabled=true;persist();return true,'Configuration enabled for everyone.'
 end
 function A.inspect(n,id)if admin(n)then return clone(records[tostring(id)])end end
 function A.review(n,id,action,note)
  if not admin(n)then return false,'Admin permission required'end;local v=records[tostring(id)];if not v then return false,'Configuration not found'end
  if action=='approve'or action=='enable'then return A.approve(n,id)elseif action=='disable'then v.enabled=false;v.approved=false
  elseif action=='note'then note=tostring(note or ''):match('^%s*(.-)%s*$'):sub(1,2000);if note==''then return false,'Enter a note'end;v.notes=v.notes or {};v.notes[#v.notes+1]={reviewer=n,text=note}end
  persist();return true,'Review saved'
 end
 return A
end
