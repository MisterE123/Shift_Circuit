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
m.update('A','menu',false);assert(#calls==1 and calls[1].p.to_player=='A' and calls[1].p.loop and not calls[1].e)
m.update('A','menu',false);assert(#calls==1,'refresh does not restart track')
m.update('A','game',false);assert(#calls==2 and fades[2].g==0,'crossfade old track')
m.update('A','game',true);assert(#calls==2 and fades[#fades].g<.12*.65,'execution ducks music')
m.update('B','menu',false);assert(calls[#calls].p.to_player=='B','player isolation')
m.tick(2);assert(stopped[1],'old track is cleaned up')
m.set('A','music',0);m.update('A','game',false);assert(fades[#fades].g==0)
m.set('A','effects',0);local n=#calls;m.effect('A','sc_laser',{});assert(#calls==n,'effects mute')
m.set('A','effects',.5);m.effect('A','sc_laser',{gain=.4});assert(calls[#calls].p.gain==.2)
m.click('A');local count=#calls;m.click('A');assert(#calls==count,'click debounce')
m.leave('A');assert(m.settings('A').music==0 and m.settings('A').effects==.5,'settings persist')
m.shutdown();assert(stopped[3],'disconnect/shutdown stops loops')
print('PASS personal music loops, crossfade, ducking, mute, gain, debounce, persistence, cleanup')
''')
for name in ['music_menu','music_game','ui_click','blink','shield','turn','success']:
 p=root/'mods/shift_circuit/sounds'/('sc_'+name+'.ogg');data,rate=sf.read(p)
 assert np.isfinite(data).all() and np.max(np.abs(data))>.02 and np.max(np.abs(data))<1
 if name.startswith('music'):
  assert len(data)/rate>40 and data.ndim==2
  assert np.max(np.abs(data[0]-data[-1]))<.15,'loop discontinuity'
 else:assert len(data)/rate<=1.3
print('PASS decoded music/effects, duration, levels, and loop boundaries')
