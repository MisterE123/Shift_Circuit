"""Original seamless synth music auditions. Code MIT; rendered audio CC0."""
from pathlib import Path
import numpy as np
import soundfile as sf
import json
SR=32000
OUT=Path('outputs/music-synth-audition-focus');OUT.mkdir(parents=True,exist_ok=True)
rng=np.random.default_rng(94123)
def hz(n):return 440*2**((n-69)/12)
def tone(note,d,kind):
 t=np.arange(round(d*SR))/SR;f=hz(note);p=2*np.pi*f*t
 if kind=='pad':
  attack=np.sin(np.minimum(1,t/.48)*np.pi/2)**2
  release=np.sin(np.minimum(1,(d-t)/.85)*np.pi/2)**2
  a=attack*release
  # Rounded organ-like body, slow chorus, restrained upper harmonics.
  y=(.78*np.sin(p)+.13*np.sin(p*2)+.025*np.sin(p*3)
     +.16*np.sin(2*np.pi*(f*.999)*t)+.16*np.sin(2*np.pi*(f*1.001)*t))*a
 elif kind=='bass':
  a=(1-np.exp(-t/.008))*np.exp(-t/.23)*np.minimum(1,(d-t)/.025)
  y=(np.sin(p)+.24*np.sin(p*2)+.08*np.sin(p*3))*a
 else:
  a=(1-np.exp(-t/(.035 if kind=='pluck'else .07)))*np.exp(-t/(.32 if kind=='pluck'else .65))*np.minimum(1,(d-t)/.10)
  y=(np.sin(p)+.055*np.sin(p*2))*a
 return y

def drums(kind):
 d={'kick':.32,'hat':.10,'snare':.2,'tick':.07}[kind];t=np.arange(round(d*SR))/SR
 n=rng.normal(size=len(t));n=np.convolve(n,np.ones(4)/4,mode='same')
 if kind=='kick':
  f=48+100*np.exp(-t/.017);y=np.sin(2*np.pi*np.cumsum(f)/SR)*np.exp(-t/.075)
 elif kind=='snare':y=(n*.5+np.sin(2*np.pi*182*t)*.18)*np.exp(-t/.033)
 else:y=(n-np.roll(n,2))*np.exp(-t/(.013 if kind=='hat'else .008))*.5
 return y*np.minimum(1,t/.001)*np.minimum(1,(d-t)/.01)

def render(name,bpm,style):
 beat=60/bpm;bar=4*beat;length=96*bar;N=round(length*SR);mix=np.zeros((N,2),np.float32)
 def put(y,start,g=.1,pan=0):
  i=round(start*SR)%N;v=(y*g).astype(np.float32)
  gains=[np.sqrt((1-pan)/2),np.sqrt((1+pan)/2)]
  end=min(len(v),N-i)
  for c in range(2):
   mix[i:i+end,c]+=v[:end]*gains[c]
   if end<len(v):mix[:len(v)-end,c]+=v[end:]*gains[c]
 def echo(y,start,g,pan):
  put(y,start,g,pan);put(y,start+beat*.75,g*.22,-pan);put(y,start+beat*1.5,g*.09,pan)
 # Each track has its own harmony, rhythm and instrument balance.
 progressions={
 'menu':[(45,[0,7,12,15]),(41,[0,7,12,16]),(48,[0,7,12,16]),(43,[0,7,12,16]),(45,[0,7,12,15]),(41,[0,7,12,16]),(38,[0,7,12,15]),(43,[0,7,12,16])],
 'lobby':[(48,[0,7,12,16]),(45,[0,7,12,15]),(41,[0,7,12,16]),(43,[0,7,12,16])],
 'race':[(40,[0,7,12,15]),(36,[0,7,12,16]),(43,[0,7,12,16]),(38,[0,7,12,15])],
 'puzzle':[(45,[0,7,12,15]),(38,[0,7,12,15]),(41,[0,7,12,16]),(48,[0,7,12,16]),(45,[0,7,12,15]),(43,[0,7,12,16]),(41,[0,7,12,16]),(40,[0,7,12,15])]}
 prog=progressions[style];kit={k:drums(k)for k in ['kick','hat','snare','tick']}
 for b in range(96):
  root,ch=prog[(b//4)%len(prog)];start=b*bar;section=(b//8)%6
  if b%4==0:
   for j,n in enumerate(ch):put(tone(root+n,bar*4+.85,'pad'),start,.062 if style!='race'else .045,(j-1.5)*.32)
  if style=='race':
   kicks=[0,2] if section not in [2,5] else [0];bass=[.5,2.5];notes=[0,7,12,10,7,14,12,7];spacing=.5
  elif style=='menu':
   kicks=[0] if b%2==0 else [];bass=[0,2.75] if section==3 else [0];notes=[0,7,14,10,7,12,14,7];spacing=.5
  elif style=='lobby':
   kicks=[0] if b%2==0 else [];bass=[0];notes=[0,7,11,14];spacing=1
  else:
   kicks=[0] if b%2==0 else [];bass=[0];notes=[0,14,7,10];spacing=1
  for q in kicks:put(kit['kick'],start+q*beat,.068 if style=='race'else .035)
  for j,q in enumerate(bass):put(tone(root+(12 if j==2 and b%4==3 else 0),.65,'bass'),start+q*beat,.075 if style=='race'else .055)
  if style=='race' and section not in [2,5]:
   # A muted pulse rather than a dance beat; no snare backbeat.
   for j in [1,3,5,7]:put(kit['hat'],start+j*.5*beat,.013,(-1)**j*.25)
  elif style=='lobby' and b%4==3:put(kit['tick'],start+2.5*beat,.010,.3)
  # Muted motifs leave room for game sounds; alternate phrases and sparse sections.
  for j,n in enumerate(notes):
   if section in [2,5]:continue
   if style=='race':
    if j%2 or b%4==3:continue
   elif b%4 not in [1,3] or (j+b)%3!=0:continue
   actual=ch[(j+b//4)%len(ch)]
   note=root+12+actual
   echo(tone(note,.85,'pluck'),start+j*spacing*beat,.018 if style=='race'else .014,(-1)**j*.48)
  if b%16==11 and style!='race':
   echo(tone(root+12+ch[(b//8)%len(ch)],1.8,'bell'),start+beat*1.5,.018,.2)
 # Circular reflections preserve tails crossing the exact loop boundary.
 mix+=np.roll(mix,round(beat*.75*SR),axis=0)[:,::-1]*.10
 mix+=np.roll(mix,round(beat*1.5*SR),axis=0)[:,::-1]*.05
 peak=float(abs(mix).max());mix*=min(.70/peak,.105/float(np.sqrt(np.mean(mix**2))))
 path=OUT/(name+'.ogg')
 print('Encoding '+name,flush=True)
 with sf.SoundFile(path,'w',samplerate=SR,channels=2,format='OGG',subtype='VORBIS') as out:
  for offset in range(0,N,16384):out.write(mix[offset:offset+16384])
 decoded,rate=sf.read(path);seam=float(abs(decoded[0]-decoded[-1]).max())
 assert np.isfinite(decoded).all() and abs(decoded).max()<.9 and seam<.025,(name,seam)
 result=dict(file=path.name,seconds=round(N/SR,3),bpm=bpm,bars=96,loop_seam=seam,peak=float(abs(decoded).max()))
 print(result,flush=True);return result
rows=[render('01-menu-neon-circuit',92,'menu'),render('02-lobby-idle-machines',88,'lobby'),render('03-race-current-flow',104,'race'),render('04-puzzle-quiet-logic',80,'puzzle')]
(OUT/'manifest.json').write_text(json.dumps(rows,indent=2))
(OUT/'CREDITS.txt').write_text('Music composition and procedural synthesis: Codex GPT-6 Astra Medium. Original oscillators and noise; no external recordings. Audio CC0 1.0, recipe MIT. Preview only. Focus revision: 96 bars, slow harmonic rhythm, restrained percussion, sparse motifs and recurring melody-free passages. Lower open triads, soft organ/chorus pads, rounded motifs. Circular note tails and delay; no fade-to-silence loop boundary.\n')
