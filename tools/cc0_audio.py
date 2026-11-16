"""Build the CC0 audio set from downloaded Kenney packs and Algate.
Usage: python tools/cc0_audio.py SOURCE_DIRECTORY
SOURCE_DIRECTORY contains sci-fi/Audio, interface/Audio, impact/Audio,
and algate/Algate/wav extracted from the credited original downloads.
Requires numpy and soundfile. No network or generation service required.
"""
from pathlib import Path
import sys,json,hashlib,shutil
import numpy as np
import soundfile as sf
R=Path(__file__).resolve().parents[1];SRC=Path(sys.argv[1]);OUT=R/'mods/shift_circuit/sounds';RATE=44100
urls={'sci-fi':'https://kenney.nl/assets/sci-fi-sounds','interface':'https://kenney.nl/assets/interface-sounds','impact':'https://kenney.nl/assets/impact-sounds','algate':'https://opengameart.org/content/algate'}
records=[];used=[]
def read(pack,name,pitch=1):
 p=SRC/pack/('Algate/wav'if pack=='algate'else 'Audio')/name
 d,sr=sf.read(p,always_2d=True);used.append({'pack':pack,'file':name,'source_url':urls[pack],'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
 if sr!=RATE or pitch!=1:
  old=np.arange(len(d));new=np.arange(0,len(d),sr/RATE*pitch);d=np.stack([np.interp(new,old,d[:,c])for c in range(d.shape[1])],axis=1)
 return d

def effect(pack,name,limit=1.2,pitch=1):
 d=read(pack,name,pitch).mean(axis=1)[:int(limit*RATE)]
 # Short attack and release prevent clicks, with enough tail for the transient.
 a=min(int(.004*RATE),len(d)//2);b=min(int(.055*RATE),len(d)//2)
 d[:a]*=np.linspace(0,1,a);d[-b:]*=np.linspace(1,0,b)
 return d

def save(name,d,notes):
 peak=np.max(np.abs(d));rms=np.sqrt(np.mean(d*d));target=.11 if name.startswith('music')else .16
 d=d*min(target/max(rms,1e-9),.82/max(peak,1e-9))
 p=OUT/('sc_'+name+'.ogg')
 with sf.SoundFile(p,'w',samplerate=RATE,channels=1 if d.ndim==1 else d.shape[1],format='OGG',subtype='VORBIS') as out:
  for start in range(0,len(d),4096):out.write(d[start:start+4096])
 records.append({'name':name,'author':'James Gargette (cinameng)'if name.startswith('music')else 'Kenney','license':'CC0-1.0','license_url':'https://creativecommons.org/publicdomain/zero/1.0/','sources':list(used),'processing':notes,'file':p.relative_to(R).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()});used.clear()

mapping={
 'ui_click':('interface','click_001.ogg',.2,1),
 'pickup':('interface','maximize_001.ogg',.5,1),
 'success':('interface','confirmation_001.ogg',.5,1),
 'puzzle_complete':('interface','confirmation_002.ogg',1.1,.85),
 'laser':('sci-fi','laserSmall_000.ogg',.5,1),
 'shield':('sci-fi','forceField_000.ogg',1.1,1),
 'blink':('sci-fi','forceField_003.ogg',1.15,1.15),
 'move':('sci-fi','engineCircular_000.ogg',.65,1),
 'turn':('sci-fi','engineCircular_001.ogg',.35,1.3),
 'impact':('impact','impactMetal_medium_001.ogg',.7,1),
 'destroy':('sci-fi','explosionCrunch_000.ogg',1.2,.9),
 'crusher':('sci-fi','doorClose_000.ogg',1.1,.75)}
for name,(pack,file,limit,pitch)in mapping.items():save(name,effect(pack,file,limit,pitch),f'Mono; trimmed to at most {limit}s; pitch ratio {pitch}; short edge fades and level normalization.')
def arrangement(mode):
 # Aligned stems retain the original 32-beat grid; no shortened crossfades
 # or per-phrase fades. Slow circular envelopes vary instrumentation.
 full,low,air,bass=[read('algate',f) for f in ['algate.wav','algate_low.wav','algate_no_kick.wav','algate_bass.wav']]
 phrase=len(full);cycles=12 if mode=='menu'else 16;n=phrase*cycles
 # Difference stems prevent doubling shared bass and drum content.
 stems=[bass,air-bass,low-air,full-low]
 anchors=([(.8,.55,.35,.1),(.9,.8,.65,.3),(1,1,.9,.65),(.8,.8,.55,.3),(.9,.65,.45,.15),(1,1,.8,.8),(.85,.8,.55,.4)] if mode=='menu'else
          [(.9,.55,.08,.05),(.8,.8,.15,.15),(.9,.65,.04,.25),(.75,.45,0,.1),(.85,.85,.12,.35),(.9,.6,.05,.1),(.8,.7,.08,.2)])
 d=np.zeros((n,2));t=np.arange(n,dtype=np.float64)/n*len(anchors);idx=np.floor(t).astype(int);f=(1-np.cos((t-idx)*np.pi))*.5
 for j,stem in enumerate(stems):
  points=np.array([q[j] for q in anchors]);gain=points[idx]*(1-f)+points[(idx+1)%len(points)]*f
  # Bridge the last few samples into the next phrase without a silent fade.
  stem=stem.copy();edge=96;u=np.linspace(0,1,edge)[:,None];stem[-edge:]=stem[-edge:]*(1-u)+stem[0]*u
  d+=np.tile(stem,(cycles,1))*gain[:,None]
 # Beat-synchronous circular reflections soften the dry short-loop character.
 beat=phrase/32
 for delay,gain in [(3,.11),(5,.065),(8,.035)]:
  d+=np.roll(np.tile(air,(cycles,1)),round(beat*delay),axis=0)[:,::-1]*gain
 # The complete arrangement loops, including its ambience tails.
 edge=128;u=np.linspace(0,1,edge)[:,None];d[-edge:]=d[-edge:]*(1-u)+d[0]*u
 return d
for mode in ['menu','game']:
 save('music_'+mode,arrangement(mode),'Continuous beat-aligned Algate stem arrangement: '+('12'if mode=='menu'else '16')+' phrases, circular instrumentation envelopes, quiet beat-synchronous stereo reflections, no phrase fades or gaps, periodic end seam. CC0 adaptation.')
shutil.copyfile(OUT/'sc_music_menu.ogg',R/'menu/theme.ogg')
records.append({'name':'game_selection_theme','author':'James Gargette (cinameng)','license':'CC0-1.0','source_url':urls['algate'],'derived_from':'music_menu','file':'menu/theme.ogg','sha256':hashlib.sha256((R/'menu/theme.ogg').read_bytes()).hexdigest()})
(R/'sound_sources.json').write_text(json.dumps(records,indent=2)+'\n',encoding='utf-8')
print('Replaced all 14 sound events and game-selection music with credited CC0 audio')
