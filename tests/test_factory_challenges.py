"""Check shipped pack registration, connector alignment and Counterflow's solution."""
from pathlib import Path
import json
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.globals().modpath=(root/'mods/shift_circuit').as_posix()
lua.globals().gamepath=root.as_posix()
def convert(v):
    if isinstance(v,dict):return lua.table_from({k:convert(x)for k,x in v.items()})
    if isinstance(v,list):return lua.table_from([convert(x)for x in v])
    return v
lua.globals().decode_json=lambda raw:convert(json.loads(raw))
source=(root/'tests/test_controller.py').read_text().split("lua.execute(r'''",1)[1].split('ui_events={};shift_circuit=dofile',1)[0]
lua.execute(source)
setup=(root/'tests/test_online.py').read_text().split("lua.execute('''",1)[1].split('local smallboard=',1)[0]
lua.execute(setup)
lua.execute('''
core.parse_json=decode_json
core.get_game_info=function()return {path=gamepath}end
core.get_modpath=function(n)if n=='shift_circuit_factory_challenges'then return gamepath..'/mods/'..n end;return modpath end
core.get_current_modname=function()return 'shift_circuit_factory_challenges'end
dofile(modpath..'/online.lua')
dofile(gamepath..'/mods/shift_circuit_factory_challenges/init.lua')
callbacks.on_mods_loaded();flush()
local entries=shift_circuit.puzzles.entries('Student')
assert(#entries==13 and entries[1].data.title=='Counterflow' and not entries[1].tutorial)
local titles={};for _,e in ipairs(entries)do titles[e.data.title]=true end
assert(titles['Heavy Traffic']and titles['Watchtower Ring']and titles['Cargo Umbrella'])
assert(not titles['Piston Transfer']and not titles['Behind Glass']and not titles['Last Shot'])
local d=entries[1].data
assert(d.puzzle.limit==2 and d.puzzle.no_reboot and #d.puzzle.checkpoints==2)
assert(#d.puzzle.hands['1']==7 and #d.puzzle.hands['2']==7,'fixed hands include two distractors')
local R=dofile(modpath..'/rules.lua')
local b={id='Test',x=d.start.x,z=d.start.z,dir=d.start.dir,hp=5,max_hp=5,energy=9,parts={},next=1,weapon='green_laser'}
local s={size=d.size,round=1,mode='puzzle',puzzle=d.puzzle,board=copy(d.board),overhead=copy(d.overhead),walls=d.walls,pickups={},spawners={},crates={},enemies={},lasers={},pushers={},bots={b},checkpoint_count=2}
for i,k in ipairs(d.puzzle.checkpoints)do s.board[k]={kind='station',number=i}end
local plan={'STEP','DASH','BACK2','MOVE3','LEFT','DASH','LEFT','MOVE3','RIGHT','STEP'}
for i,c in ipairs(plan)do
 local slot=(i-1)%5+1;s.round=math.floor((i-1)/5)+1;s.register=slot
 R.command(s,b,c);R.collect_phase(s);R.arms(s);R.belts(s,true);R.collect_phase(s);R.belts(s,false);R.collect_phase(s)
 R.pushers(s,slot);R.plates(s);R.collect_phase(s);R.rotators(s);R.robot_weapons(s,slot);R.collect_phase(s);R.lasers(s);R.hazards(s,slot);R.register_repairs(s)
 assert(not b.down,'Counterflow solution destroyed at '..i)
end
assert(b.finished,'Counterflow must finish by round two')
''')
pack=json.loads((root/'mods/shift_circuit_factory_challenges/boards.json').read_text())
assert {e['data']['title']for e in pack['boards']}=={'Split Shift','Press Exchange','Freight Circuit','Braided Current','Signal Junction','Piston Market','Sluice Yard','Gyro Crossing','Inner Lane','Cross Dock','Service Detour','Transfer Station','Turbine Hall','Cargo Weave','Pressure Network'}
boards={e['data']['title']:e['data']for e in pack['boards']}
assert sum(t['kind']=='checkpoint'for t in boards['Split Shift']['board'].values())==3
large=boards['Freight Circuit']['board']
for title in ['Split Shift','Press Exchange']:
    small=boards[title]['board']
    for offset in [0,10]:
        for k in [5,6]:
            for sk,bk in [(f'1,{k}',f'20,{k+offset}'),(f'10,{k}',f'1,{k+offset}'),(f'{k},1',f'{k+offset},20'),(f'{k},10',f'{k+offset},1')]:
                assert small[sk]['kind']!='pit' and large[bk]['kind']!='pit'
assert not any(e['data']['title']in ['Corner Cargo','Clockwork Latch']for e in pack['boards'])
print('PASS actual pack load, Counterflow solution/settings, race roster, reduced flags, all small/large-board connectors')

# Factories feed belts directly, leaving all checkpoint candidates connected.
turbine=boards['Turbine Hall']
assert turbine['board']['2,15']['crate_kind']=='steel'
assert turbine['board']['19,5']['crate_kind']=='loot'
for key in ['3,15','18,5']:assert turbine['board'][key]['kind']=='belt'
lua.globals().turbine=convert(turbine)
lua.execute("""
local R=dofile(modpath..'/rules.lua')
local s={size=20,round=1,board=copy(turbine.board),walls=turbine.walls,bots={},crates={},pickups={}}
R.factories(s,1,function()return 1 end)
local count=0;local before={}
for id,c in pairs(s.crates)do count=count+1;before[id]=c.x..','..c.z end
assert(count==2,'Both factories must emit a crate')
R.belts(s,true);R.belts(s,false)
for id,c in pairs(s.crates)do assert(before[id]~=c.x..','..c.z,'Factory cargo must travel on its belt')end
""")
for title,d in boards.items():
    safe={tuple(map(int,k.split(',')))for k,t in d['board'].items()if t['kind']not in ['pit','factory','trapdoor']}
    flags={tuple(map(int,k.split(',')))for k,t in d['board'].items()if t['kind']=='checkpoint'}
    visited=set();todo=[next(iter(flags))]
    edge=lua.execute("return dofile(modpath..'/rules.lua').edge")
    while todo:
        x,z=todo.pop()
        if(x,z)in visited:continue
        visited.add((x,z))
        for direction,(dx,dz)in enumerate([(0,1),(1,0),(0,-1),(-1,0)]):
            dest=(x+dx,z+dz)
            if dest in safe and dest not in visited and not d['walls'].get(edge(x,z,direction)):todo.append(dest)
    assert flags<=visited,(title,'disconnected checkpoints')
print('PASS Turbine Hall factory output, conveyor transport, and race checkpoint connectivity')
