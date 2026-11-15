-- Plans start at deal time, concurrently with human programming.
return function(core,path,R,C,background)
 local epoch,pending,job=0,0,nil
 local api={}
 function api.cancel()epoch=epoch+1;pending=0;job=nil end
 function api.ready()return pending==0 end
 function api.start(state,complete)
  api.cancel();local generation=epoch
  local requests={}
  for _,b in ipairs(state.bots)do if b.enemy and not b.finished and not b.ready then
   if b.pattern then b.program=C.plan(R,state,b);b.ready=true
   else
    -- Each opponent gets only its own hand and public previous-round motion.
    local snapshot=core.deserialize(core.serialize(state))
    for _,other in ipairs(snapshot.bots)do
     other.program={};other.selected={};other.ready=false
     if other.id~=b.id then other.hand=nil;other.hand_ids=nil end;other.program_ids={}
    end
    requests[#requests+1]={bot=b,snapshot=snapshot}
   end
  end end
  pending=#requests
  local function accept(b,program)
   if generation~=epoch then return end
   local remaining={};for _,card in ipairs(b.hand)do remaining[card]=(remaining[card]or 0)+1 end
   local valid=type(program)=='table' and #program==5
   if valid then for _,card in ipairs(program)do
    if type(card)~='string' or (remaining[card]or 0)==0 then valid=false;break end
    remaining[card]=remaining[card]-1
   end end
   b.program={};b.selected={};b.ready=false
   if valid then b.program_ids={};local used={};for i,card in ipairs(program)do b.program[i]=card;local best;for j,c in ipairs(b.hand)do if c==card and not used[j]and (not best or ((b.hand_ids or {})[j]or 0)>((b.hand_ids or {})[best]or 0))then best=j end end;used[best]=true;b.selected[i]=best;b.program_ids[i]=(b.hand_ids or {})[best]end;b.ready=true
   else C.autofill(b)end -- Failure still obeys the dealt hand, never grants cards.
   pending=pending-1;if pending==0 then complete()end
  end
  if pending==0 then complete();return end
  if background and core.handle_async then
   for _,request in ipairs(requests)do
    local b=request.bot
    core.handle_async(function(snapshot,id,modpath)return shift_circuit_plan(snapshot,id,modpath)end,
     function(result)accept(b,result)end,request.snapshot,b.id,path)
   end
  elseif background then
   job=coroutine.create(function()
    for _,request in ipairs(requests)do accept(request.bot,C.plan(R,request.snapshot,request.bot,coroutine.yield))end
   end)
  else
   for _,request in ipairs(requests)do accept(request.bot,C.plan(R,request.snapshot,request.bot))end
  end
 end
 function api.tick()
  if not job then return end
  local started=core.get_us_time and core.get_us_time()or 0
  for _=1,8 do
   local ok,err=coroutine.resume(job);if not ok then error(err)end
   if coroutine.status(job)=='dead'then job=nil;break end
   if core.get_us_time and core.get_us_time()-started>=2500 then break end
  end
 end
 return api
end
