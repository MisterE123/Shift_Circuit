"""Replay approved puzzle programs against normalized shipped level data."""
from pathlib import Path
from collections import Counter
import json
from lupa import LuaRuntime
root=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.globals().PROOF_RULES_PATH=(root/'mods/shift_circuit/rules.lua').as_posix()
E=lua.execute((root/'tests/fixtures/puzzle_replay.lua').read_text());R=E['R']
L=lua.execute('return dofile(...)',(root/'mods/shift_circuit/levels.lua').as_posix())
def lu(v):
    if isinstance(v,dict):return lua.table_from({k:lu(x)for k,x in v.items()})
    if isinstance(v,list):return lua.table_from([lu(x)for x in v])
    return v
levels=json.loads((root/'mods/shift_circuit_factory_challenges/puzzles.json').read_text())['puzzles']
proofs=json.loads((root/'tests/fixtures/reviewed_puzzle_solutions.json').read_text())
for entry in levels:
    if entry['data']['title']not in proofs:continue
    proof=proofs[entry['data']['title']]
    for seed in [1,42,100]:
        d=L.validate_submission(lu(entry['data']));assert not isinstance(d,tuple)
        p=d['puzzle'];start=d['start'];b=lu(dict(id='Player',x=start['x'],z=start['z'],dir=start['dir'],hp=p['hull'],max_hp=5,energy=p['power'],next=1,weapon=p['weapon']))
        b['home']=E.clone(start);b['parts']=E.clone(p['equipment'])
        s=lu(dict(mode='puzzle',round=1,register=1,size=d['size'],checkpoint_count=len(p['checkpoints']),goals=[]))
        for k in ['board','walls','overhead','crates','enemies','lasers','pushers','spawners','pickups']:s[k]=E.clone(d[k])
        s['puzzle']=E.clone(p);s['bots']=lua.table_from([b])
        for i,k in p['checkpoints'].items():s['board'][k]=lu(dict(kind='station',number=i))
        R.init_objects(s);R.normalize(b)
        for i,command in enumerate(proof['plan'],1):
            round_id=(i-1)//5+1
            if(i-1)%5==0:hand=Counter(v for _,v in p['hands'][str(round_id)].items())
            assert hand[command]>0;hand[command]-=1
            cfg=lu(proof['settings'][round_id-1])if(i-1)%5==0 else None
            s=E.step(s,command,i,cfg,seed);assert s is not None,(d['title'],seed,i)
        assert s['bots'][1]['finished']and round_id<=p['limit'],d['title']
    print('PASS shipped winning solution:',entry['data']['title'])
