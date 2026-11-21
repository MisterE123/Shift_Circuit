-- Plans start at deal time, concurrently with human programming.
return function(core,path,R,C,background)
 local epoch,pending,jobs=0,0,{}
 local api={}
 function api.cancel()epoch=epoch+1;pending=0;jobs={} end
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
     if other.id~=b.id then other.hand=nil;other.hand_ids=nil;other.start_direction=nil end;other.program_ids={}
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
   if state.round==1 then b.start_direction=valid and R.start_directions[program.start_direction]and program.start_direction or 'FORWARD'end
   b.program={};b.selected={};b.ready=false
   if valid then b.program_ids={};local used={};for i,card in ipairs(program)do b.program[i]=card;local best;for j,c in ipairs(b.hand)do if c==card and not used[j]and (not best or ((b.hand_ids or {})[j]or 0)>((b.hand_ids or {})[best]or 0))then best=j end end;used[best]=true;b.selected[i]=best;b.program_ids[i]=(b.hand_ids or {})[best]end;b.ready=true
   else C.autofill(b)end -- Failure still obeys the dealt hand, never grants cards.
   pending=pending-1;if pending==0 then complete()end
  end
  if pending==0 then complete();return end
  local function queue_local(request)
   jobs[#jobs+1]={bot=request.bot,accept=accept,thread=coroutine.create(function()
    return C.plan(R,request.snapshot,request.bot,coroutine.yield)
   end)}
  end
  if background then
   for _,request in ipairs(requests)do
    local b=request.bot
    local submitted=false
    if core.handle_async then
     -- Send strings rather than the nested snapshot through Luanti's packed-Lua bridge.
     submitted=pcall(function()
      local payload=core.serialize(request.snapshot)
      core.handle_async(function(packet,id,modpath)return shift_circuit_plan(packet,id,modpath)end,
       function(result)
        if generation~=epoch then return end
        local ok,program=pcall(core.deserialize,result,true)
        accept(b,ok and program or nil)
       end,payload,b.id,path)
     end)
     if not submitted and core.log then core.log('warning','[Shift Circuit] AI worker submission failed; using time-sliced planning')end
    end
    if not submitted then queue_local(request)end
   end
  else
   for _,request in ipairs(requests)do accept(request.bot,C.plan(R,request.snapshot,request.bot))end
  end
 end
 function api.tick()
  local started=core.get_us_time and core.get_us_time()or 0
  for _=1,8 do
   local job=jobs[1];if not job then return end
   local ok,result=coroutine.resume(job.thread)
   if not ok or coroutine.status(job.thread)=='dead'then
    table.remove(jobs,1)
    if not ok and core.log then core.log('warning','[Shift Circuit] Time-sliced AI planning failed; filling from dealt hand')end
    job.accept(job.bot,ok and result or nil)
   end
   if core.get_us_time and core.get_us_time()-started>=2500 then break end
  end
 end
 return api
end
