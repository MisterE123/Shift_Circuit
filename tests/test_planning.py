from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True)
lua.globals().path=(root/'mods/shift_circuit').as_posix()
lua.execute("""
local R=dofile(path..'/rules.lua');local C=dofile(path..'/campaign.lua')
local function clone(t)if type(t)~='table'then return t end;local r={};for k,v in pairs(t)do r[k]=clone(v)end;return r end
local jobs={};local packets={}
local function serialize(t)local k=tostring(#packets+1);packets[#packets+1]=clone(t);return k end
local function deserialize(k)assert(type(k)=='string');return clone(packets[tonumber(k) or 0])end
local reject
core={serialize=serialize,deserialize=deserialize,handle_async=function(fn,cb,s,id,p)
 assert(type(s)=='string','only a string snapshot crosses the bridge')
 if reject and reject==id then error("invalid key to 'next'")end
 jobs[#jobs+1]={fn=fn,cb=cb,s=s,id=id,p=p}
end}
local planner=dofile(path..'/planning.lua')(core,path,R,C,true)
local s=C.setup(R,1,'race',1);s.ai_count=2;s.ai_mode='racer';C.enemies(s)
for _,b in ipairs(s.bots)do C.deal(b)end
s.bots[#s.bots+1]={id='human',hand={'SECRET'},program={'SECRET'},selected={1},last_program={'STEP'},x=2,z=2,dir=0,hp=5,next=1}
local done=0;planner.start(s,function()done=done+1 end)
assert(#jobs==2 and not planner.ready() and done==0,'jobs queued at deal, no blocking search')
for _,j in ipairs(jobs)do for _,b in ipairs(deserialize(j.s).bots)do assert(#b.program==0);if b.id~=j.id then assert(b.hand==nil)end end end
local stale=jobs[1];planner.cancel();stale.cb(serialize({'WAIT','WAIT','WAIT','WAIT','WAIT'}));assert(done==0,'stale result ignored')
jobs={};planner.start(s,function()done=done+1 end)
dofile(path..'/async_worker.lua')
for _,j in ipairs(jobs)do local program=j.fn(j.s,j.id,j.p);assert(type(program)=='string' and #deserialize(program)==5);j.cb(program)end
assert(planner.ready() and done==1)
local function legal(b)local counts={};for _,c in ipairs(b.hand)do counts[c]=(counts[c]or 0)+1 end;assert(#b.program==5);for _,c in ipairs(b.program)do counts[c]=(counts[c]or 0)-1;assert(counts[c]>=0)end end
for _,b in ipairs(s.bots)do if b.enemy then legal(b)end end
jobs={};planner.start(s,function()done=done+1 end);for _,j in ipairs(jobs)do j.cb(serialize({'BLINK','BLINK','BLINK','BLINK','BLINK'}))end
for _,b in ipairs(s.bots)do if b.enemy then legal(b)end end
assert(done==2,'invalid worker output falls back to actual hand')
local function reset()for _,b in ipairs(s.bots)do b.ready=false end;jobs={}end
reset();reject=s.bots[1].id
planner.start(s,function()done=done+1 end)
assert(#jobs==1 and not planner.ready(),'dispatch failure queues only the affected robot locally')
jobs[1].cb('invalid packet')
assert(done==2,'failed dispatch remains pending until local plan completes')
for _=1,500 do planner.tick();if planner.ready() then break end end
assert(planner.ready() and done==3,'mixed local and remote requests complete exactly once')
for _,b in ipairs(s.bots)do if b.enemy then legal(b)end end
reset();local plan=C.plan;C.plan=function()error('local planner failed')end
planner.start(s,function()done=done+1 end)
jobs[1].cb('invalid packet');planner.tick();C.plan=plan
assert(planner.ready() and done==4,'local planner errors fill a legal hand instead of escaping the step')
for _,b in ipairs(s.bots)do if b.enemy then legal(b)end end
local b=s.bots[1];b.home={x=2,z=2,dir=3};b.dir=1;b.down=true;R.respawn(s);assert(b.dir==3 and b.hp==5,'checkpoint direction and full hull restored')
print('PASS deal-time workers, private-hand isolation, cancellation, result validation, legal fallback, checkpoint direction')
""")
