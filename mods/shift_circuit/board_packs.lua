-- Race packs import validated snapshots into the shared board library once.
-- Keeping the import marker preserves subsequent admin edits, disabling or deletion.
return function(core,L,store,E)
 local P={}
 local function equal(a,b)
  if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end
  for k,v in pairs(a)do if not equal(v,b[k])then return false end end
  for k in pairs(b)do if a[k]==nil then return false end end;return true
 end
 function P.register(modname,file)
  if file~='boards.json'then return false,'Expected boards.json'end
  local path=core.get_modpath(modname);if not path then return false,'Unknown mod'end
  local f=io.open(path..'/'..file,'rb');if not f then return false,'Missing manifest'end
  local raw=f:read(2000001);f:close();if #raw>2000000 then return false,'Board pack too large'end
  local ok,data=pcall(core.parse_json,raw)
  if not ok or type(data)~='table'or data.version~=1 or type(data.boards)~='table'or #data.boards<1 or #data.boards>100 then return false,'Invalid board pack'end
  local validated,seen={},{}
  for _,entry in ipairs(data.boards)do
   if type(entry)~='table'or type(entry.id)~='string'or not entry.id:match('^[a-z0-9_]+$')or seen[entry.id]then return false,'Invalid or duplicate board ID'end
   seen[entry.id]=true
   local valid,d,err=pcall(L.validate_submission,entry.data)
   if not valid or not d or d.map_type=='puzzle'then return false,err or 'Invalid race board'end
   validated[#validated+1]={id=entry.id,data=d}
  end
  for _,entry in ipairs(validated)do
   local marker='board_pack:'..modname..':'..entry.id
   if store:get_string(marker)==''then
    -- Installing a bundled copy must not duplicate the author's existing map.
    local existing
    for id,v in pairs(E.catalog)do
     if v.data.title==entry.data.title then local ok,d=pcall(L.validate_submission,v.data);if ok and d and equal(d,entry.data)then existing=id;break end end
    end
    if existing then store:set_string(marker,tostring(existing))else
    local id=store:get_int('level_next')+1;while E.catalog[tostring(id)]do id=id+1 end
    store:set_int('level_next',id)
    E.catalog[tostring(id)]={data=entry.data,author=modname,approved=true,enabled=true,status='enabled',pack_source=marker}
    E.reconcile_names();E.persist();store:set_string(marker,tostring(id))
    end
   end
  end
  return true
 end
 return P
end
