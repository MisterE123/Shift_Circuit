from pathlib import Path
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().path=(root/'mods/shift_circuit').as_posix()
lua.execute("""
local R=dofile(path..'/rules.lua');local L=dofile(path..'/levels.lua')
local function setup(parts,enemy,racing)local s=L.blank(10);s.round=1;s.pickups={};local b={id='Pilot',x=4,z=4,dir=0,hp=5,energy=0,next=1,parts=parts or {},enemy=enemy,racing=racing,home={x=2,z=2,dir=0}};s.bots={b};return s,b end
local s,b=setup({range=1});R.drop(b,'Laser');R.resolve_drops(s);assert(s.pickups['4,4']=='range'and next(b.parts)==nil);s.pickups={};R.drop(b,'Laser');R.resolve_drops(s);assert(next(s.pickups)==nil,'only one drop per death')
s,b=setup();R.drop(b,'CRUSHED by crusher');R.resolve_drops(s);assert(s.pickups['4,4']=='shield','empty racer drops shield')
s,b=setup({},true,true);b.weapon='double_laser';R.drop(b,'Laser');R.resolve_drops(s);assert(s.pickups['4,4']=='double_laser','AI racer follows owned item rules')
s,b=setup({},true,false);R.drop(b,'Laser');R.resolve_drops(s);local valid=false;for _,kind in ipairs(R.powerup_pool)do if kind==s.pickups['4,4']then valid=true end end;assert(valid,'enemy rolls random powerup')
s,b=setup({range=1});s.pickups['4,4']='cell';R.drop(b,'Laser');R.resolve_drops(s);assert(s.pickups['4,4']=='cell'and s.pickups['4,5']=='range','existing pickup preserved, drop lands nearby')
s,b=setup();for _,k in ipairs({'4,4','4,5','5,4','4,3','3,4'})do s.pickups[k]='cell'end;R.drop(b,'Laser');R.resolve_drops(s);assert(#s.pending_drops==1);s.pickups['4,4']=nil;R.resolve_drops(s);assert(s.pickups['4,4']=='shield'and #s.pending_drops==0,'surrounded drop waits without destroying supplies')
s,b=setup({range=1});s.board['4,4']={kind='pit'};R.drop(b,'Fell into a pit');s.board['4,4']={kind='floor',filled=true};R.resolve_drops(s);assert(next(s.pickups)==nil and #s.drop_falls==1,'pit death loot falls even if hole subsequently filled')
s,b=setup({blueprint_archive=1,range=1});b.archive_item='range';R.drop(b,'Laser');R.resolve_drops(s);assert(s.pickups['4,4']=='blueprint_archive'and b.archived_item=='range','archive kept copy is not duplicated as loot')
s,b=setup();s.overhead['4,4']={parity=0};R.hazards(s,2);assert(s.pickups['4,4']=='shield','death drop survives its creating crusher stroke');R.hazards(s,4);assert(not s.pickups['4,4'])
print('PASS racer owned-item/fallback drops, random enemy drops, single-drop lifecycle, occupied squares, pits and archive preservation')
""")
