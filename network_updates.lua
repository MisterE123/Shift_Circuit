-- Avoid queueing reliable packets for values that have not changed.
local N={}
function N.equal(a,b)
 if type(a)~=type(b)then return false end
 if type(a)~='table'then return a==b end
 for k,v in pairs(a)do if not N.equal(v,b[k])then return false end end
 for k in pairs(b)do if a[k]==nil then return false end end
 return true
end
function N.copy(v)
 if type(v)~='table'then return v end
 local t={};for k,x in pairs(v)do t[k]=N.copy(x)end;return t
end
function N.properties(object,values)
 local entity=object:get_luaentity()
 if not entity then object:set_properties(values);return end
 local cache=entity.network_properties or {};entity.network_properties=cache
 local changed={};local dirty=false
 for key,value in pairs(values)do if not N.equal(cache[key],value)then cache[key]=N.copy(value);changed[key]=value;dirty=true end end
 if dirty then object:set_properties(changed)end
end
function N.hud(player,cache,id,field,value)
 local previous=cache[id]or {};cache[id]=previous
 if N.equal(previous[field],value)then return end
 previous[field]=N.copy(value);player:hud_change(id,field,value)
end
return N
