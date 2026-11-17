from pathlib import Path
from lupa import LuaRuntime
import soundfile as sf,numpy as np
root=Path(__file__).resolve().parents[1];lua=LuaRuntime(unpack_returned_tuples=True);lua.globals().path=str(root/'mods/shift_circuit/audio.lua').replace('\\','/')
lua.execute('''
local saved={};local calls={};local fades={};local stopped={};local handle=0
local c={serialize=function(t)local r={};for k,v in pairs(t)do r[k]=v end;return r end,deserialize=function(t)return t end,
 sound_play=function(n,p,e)handle=handle+1;calls[#calls+1]={name=n,p=p,e=e,h=handle};return handle end,
 sound_fade=function(h,s,g)fades[#fades+1]={h=h,g=g}end,sound_stop=function(h)stopped[h]=true end}
local store={get_string=function(_,k)return saved[k]end,set_string=function(_,k,v)saved[k]=v end}
local m=dofile(path)(c,store)
assert(m.context(nil,true)=='menu'and m.context(nil,false)=='lobby')
assert(m.context({status='waiting'},false)=='lobby')
assert(m.context({status='playing',solo=false},true)=='race','match menus preserve music')
assert(m.context({status='playing',solo=true,solo_mode='race'},false)=='race')
assert(m.context({status='playing',solo=true,solo_mode='puzzle'},false)=='puzzle')
assert(m.context({status='playing',solo=true,solo_mode='editor'},false)=='puzzle')
m.update('A','menu',false);assert(#calls==1 and calls[1].p.to_player=='A' and calls[1].p.loop and not calls[1].e)
m.update('A','menu',false);assert(#calls==1,'refresh does not restart track')
m.update('A','race',false);assert(#calls==2 and fades[2].g==0,'crossfade old track')
m.update('A','race',true);assert(#calls==2 and fades[#fades].g<.12*.65,'execution ducks music')
m.update('B','menu',false);assert(calls[#calls].p.to_player=='B','player isolation')
m.tick(2);assert(stopped[1],'old track is cleaned up')
m.set('A','music',0);m.update('A','race',false);assert(fades[#fades].g==0)
m.set('A','effects',0);local n=#calls;m.effect('A','sc_laser',{});assert(#calls==n,'effects mute')
m.set('A','effects',.5);m.effect('A','sc_laser',{gain=.4});assert(calls[#calls].p.gain==.2)
m.click('A');local count=#calls;m.click('A');assert(#calls==count,'click debounce')
assert(m.menu_cue({equipment_scroll='CHG:20'})==nil,'scroll silent')
assert(m.menu_cue({board_name='Typing a name'})==nil,'typing silent')
assert(m.menu_cue({setup_back='true'})=='ui_back')
assert(m.menu_cue({save='true'})=='ui_confirm')
assert(m.menu_cue({enable_electroshield='false'})=='ui_off')
assert(m.menu_cue({enable_electroshield='true'})=='ui_on')
m.tick(.1);m.click('A',1,'card_select');assert(calls[#calls].name=='sc_card_select')
m.tick(.1);m.click('A',1,'commit');assert(calls[#calls].name=='sc_commit')
m.tick(.1);m.menu('A',{confirm='true'});assert(calls[#calls].name=='sc_ui_confirm')
local before=#calls;m.tick(.1);m.menu('A',{equipment_scroll='CHG:20'});assert(#calls==before)
m.leave('A');assert(m.settings('A').music==0 and m.settings('A').effects==.5,'settings persist')
m.update('C','lobby',false);assert(calls[#calls].name=='sc_music_lobby')
m.update('C','puzzle',true);assert(calls[#calls].name=='sc_music_puzzle')
m.shutdown();assert(stopped[3],'disconnect/shutdown stops loops')
print('PASS personal music loops, crossfade, ducking, mute, gain, debounce, persistence, cleanup')
''')
for name in ['music_menu','music_lobby','music_race','music_puzzle','fall','ui_click','blink','shield','turn','success','puzzle_complete']:
 p=root/'mods/shift_circuit/sounds'/('sc_'+name+'.ogg');data,rate=sf.read(p)
 assert np.isfinite(data).all() and np.max(np.abs(data))>.02 and np.max(np.abs(data))<1
 if name.startswith('music'):
  assert len(data)/rate>=220 and data.ndim==2
  assert np.max(np.abs(data[0]-data[-1]))<.015,'loop discontinuity'
  phrase=rate*30
  assert np.sqrt(np.mean((data[:phrase]-data[phrase:2*phrase])**2))>.005,'arrangement should evolve'
 else:assert len(data)/rate<=2.6
print('PASS decoded music/effects, duration, levels, and loop boundaries')

# Every shipped audio file must have verified provenance, including the launcher theme.
import json,hashlib
sources=json.loads((root/'sound_sources.json').read_text())
files={p.relative_to(root).as_posix() for p in root.rglob('*') if p.suffix.lower() in {'.ogg','.wav','.mp3','.flac'}}
assert files=={entry['file'] for entry in sources}
for entry in sources:
 assert entry['license']=='CC0-1.0' and entry['author'] in {'Kenney','James Gargette (cinameng)','Codex GPT-6 Astra Medium','Codex GPT-6 Astra Medium / ChipTone (Tom Vian, SFB Games)'}
 assert hashlib.sha256((root/entry['file']).read_bytes()).hexdigest()==entry['sha256']
 for source in entry.get('sources',[]):assert source['source_url'].startswith(('https://kenney.nl/assets/','https://opengameart.org/content/algate','https://sfbgames.itch.io/chiptone','https://creativecommons.org/publicdomain/zero/1.0/'))
for file in files:
 data,rate=sf.read(root/file);assert len(data)>0 and np.isfinite(data).all() and .02<np.max(np.abs(data))<1
 if 'music_' not in file and file!='menu/theme.ogg':assert data.ndim==1,'positional effects must be mono'
print('PASS complete CC0 audio provenance, credited authors, file hashes, no untracked audio and playable levels')
