from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True)
lua.globals().path=(root/'mods/shift_circuit').as_posix()
lua.execute("""
local R=dofile(path..'/rules.lua');local C=dofile(path..'/campaign.lua')
local function clone(t)if type(t)~='table'then return t end;local r={};for k,v in pairs(t)do r[k]=clone(v)end;return r end
local jobs={};local core={serialize=clone,deserialize=clone,handle_async=function(fn,cb,s,id,p)jobs[#jobs+1]={fn=fn,cb=cb,s=s,id=id,p=p}end}
local planner=dofile(path..'/planning.lua')(core,path,R,C,true)
local s=C.setup(R,1,'race',1);s.ai_count=2;s.ai_mode='racer';C.enemies(s)
for _,b in ipairs(s.bots)do C.deal(b)end
s.bots[#s.bots+1]={id='human',hand={'SECRET'},program={'SECRET'},selected={1},last_program={'STEP'},x=2,z=2,dir=0,hp=5,next=1}
local done=0;planner.start(s,function()done=done+1 end)
assert(#jobs==2 and not planner.ready() and done==0,'jobs queued at deal, no blocking search')
for _,j in ipairs(jobs)do for _,b in ipairs(j.s.bots)do assert(#b.program==0);if b.id~=j.id then assert(b.hand==nil)end end end
local stale=jobs[1];planner.cancel();stale.cb({'WAIT','WAIT','WAIT','WAIT','WAIT'});assert(done==0,'stale result ignored')
jobs={};planner.start(s,function()done=done+1 end)
dofile(path..'/async_worker.lua')
for _,j in ipairs(jobs)do local program=j.fn(j.s,j.id,j.p);assert(#program==5);j.cb(program)end
assert(planner.ready() and done==1)
local function legal(b)local counts={};for _,c in ipairs(b.hand)do counts[c]=(counts[c]or 0)+1 end;assert(#b.program==5);for _,c in ipairs(b.program)do counts[c]=(counts[c]or 0)-1;assert(counts[c]>=0)end end
for _,b in ipairs(s.bots)do if b.enemy then legal(b)end end
jobs={};planner.start(s,function()done=done+1 end);for _,j in ipairs(jobs)do j.cb({'BLINK','BLINK','BLINK','BLINK','BLINK'})end
for _,b in ipairs(s.bots)do if b.enemy then legal(b)end end
assert(done==2,'invalid worker output falls back to actual hand')
local b=s.bots[1];b.home={x=2,z=2,dir=3};b.dir=1;b.down=true;R.respawn(s);assert(b.dir==3 and b.hp==5,'checkpoint direction and full hull restored')
print('PASS deal-time workers, private-hand isolation, cancellation, result validation, legal fallback, checkpoint direction')
""")
