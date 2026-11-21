-- Loaded in each isolated Luanti worker. No live world or player APIs.
function shift_circuit_plan(packet, id, path)
 local ok, result=pcall(function()
  local snapshot=core.deserialize(packet,true)
  local R=dofile(path..'/rules.lua');local C=dofile(path..'/campaign.lua')
  for _,b in ipairs(snapshot.bots)do if b.id==id then return core.serialize(C.plan(R,snapshot,b))end end
 end)
 return ok and result or ''
end
