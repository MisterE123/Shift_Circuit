from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().path=(root/'mods/shift_circuit').as_posix()
lua.execute("""
local L=dofile(path..'/nearby_labels.lua')
local function obj(x,text,range,owner)
 local e={nearby_label={text=text,range=range,owner=owner}}
 return {get_pos=function()return {x=x,y=0,z=0}end,get_luaentity=function()return e end},e
end
local a=obj(3,'Ram Bot',8);local b=obj(9,'Sentry',8);local c=obj(14,'Racer',16);local own=obj(1,'Pilot',16,'Pilot');local gone,e=obj(2,'Power Cell',8);e.collecting={}
local list=L.choose({a,b,c,own,gone},{x=0,y=0,z=0},'Pilot')
assert(#list==2 and list[1].text=='Ram Bot'and list[2].text=='Racer')
list=L.choose({a,b,c},{x=20,y=0,z=0},'Other')
assert(#list==1 and list[1].text=='Racer','range is evaluated separately for each viewer')
local racers={};for i=1,8 do local o,e=obj(100+i,'Racer '..i,16);e.nearby_label.persistent=true;racers[i]=o end
local list=L.choose(racers,{x=0,y=0,z=0},'Pilot',true);assert(#list==8,'all racers visible beyond range and nearby six-label limit')
assert(#L.choose(racers,{x=0,y=0,z=0},'Pilot')==0,'racers do not consume nearby label slots')
print('PASS nearby labels: distance, nearest-first order, owner exclusion, collection hiding and independent viewers')
""")
