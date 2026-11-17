"""Deterministic original procedural SFX. Code: MIT. Rendered audio: CC0."""
from pathlib import Path
import json
import numpy as np
import soundfile as sf

SR=48000
OUT=Path('outputs/scifi-audition-v3')
OUT.mkdir(parents=True,exist_ok=True)
rng=np.random.default_rng(3917)
manifest=[]
def time(d): return np.arange(round(d*SR))/SR
def env(t,d,a=.002): return (1-np.exp(-t/a))*np.exp(-t/d)
def osc(f): return np.sin(2*np.pi*np.cumsum(f)/SR)
def noise(t,lo=400,hi=8000):
    f=np.fft.rfftfreq(len(t),1/SR)
    w=(1-np.exp(-(f/max(lo,1))**4))*np.exp(-(f/hi)**4)
    x=np.fft.irfft(np.fft.rfft(rng.normal(size=len(t)))*w,n=len(t))
    return x/(np.std(x)+1e-9)
def add(x,y,start=0,g=1):
    i=round(start*SR); n=min(len(y),len(x)-i)
    if n>0:x[i:i+n]+=y[:n]*g
def save(name,x,level=.18,space=.07):
    x-=np.mean(x)
    stereo=np.stack([x.copy(),x.copy()],axis=1)
    for c in range(2):
        for delay,g in [(.031+c*.009,space),(.071-c*.005,space*.5)]:
            n=round(delay*SR); stereo[n:,c]+=x[:-n]*g
    stereo=np.tanh(stereo*1.1)
    active=np.max(abs(stereo),axis=1)>.01
    rms=np.sqrt(np.mean(stereo[active]**2))
    stereo*=min(level/max(rms,1e-9),.86/max(np.max(abs(stereo)),1e-9))
    stereo[:48]*=np.linspace(0,1,48)[:,None]
    stereo[-2400:]*=np.linspace(1,0,2400)[:,None]
    stereo=np.pad(stereo,((0,4800),(0,0)))
    sf.write(OUT/(name+'.wav'),stereo,SR,subtype='PCM_24')
    manifest.append(dict(file=name+'.wav',seconds=round(len(stereo)/SR,3),peak=round(float(np.max(abs(stereo))),4)))

# Layered brittle fractures with a low impact; intentionally little pitched ringing.
t=time(.85); x=.45*osc(55+145*np.exp(-t/.014))*env(t,.075,.0005)
for start,d,g in [(0,.028,.65),(.013,.022,.46),(.034,.035,.43),(.071,.025,.28),(.115,.045,.17),(.186,.035,.08)]:
    q=time(.27); n=noise(q,650,10000)
    grit=np.tanh(n*2.8)*.7+np.round(n*3)/12
    add(x,grit*env(q,d,.0004),start,g)
x+=.09*noise(t,100,1100)*env(t,.14)
save('01-damage-fractured-metal',x,.22,.025)

# Only the resolving chord: no thump, sparkle, old clip, or arpeggiator.
t=time(1.8); x=np.zeros(len(t))
for start,notes in [(0,[164.81,246.94]),(.18,[220,277.18,329.63])]:
    q=time(1.6)
    for f in notes:
        p=2*np.pi*f*q
        add(x,(np.sin(p)+.2*np.sin(2*p)+.07*np.sin(3*p))*env(q,.42,.012),start,.19)
save('02-checkpoint-chord-only',x,.17,.07)

# Commit: two decisive contact clicks followed by a short warm confirmation.
t=time(.85); x=np.zeros(len(t))
for start,f,g in [(0,180,.35),(.065,240,.28)]:
    q=time(.18); y=osc(f+100*np.exp(-q/.008))*env(q,.025,.0007)
    y+=.4*noise(q,1200,6500)*env(q,.008,.0003)
    add(x,y,start,g)
q=time(.62)
for f in [330,440,554.365]:add(x,np.sin(2*np.pi*f*q)*env(q,.12,.007),.09,.13)
save('03-commit-program-locked',x,.17)

# Shield: resonant glass-like shell struck by a small electric burst.
t=time(1.0); x=.14*noise(t,1600,9000)*env(t,.019,.0005)
for f,g in [(260,.22),(522,.17),(790,.09),(1315,.045)]:
    p=2*np.pi*f*t
    x+=g*np.sin(p+.8*np.exp(-t/.05)*np.sin(p*1.41))*env(t,.19,.001)
x+=.1*osc(90+100*np.exp(-t/.025))*env(t,.09)
save('04-shield-energy-shell',x,.18,.11)

# Blink: short intake closes into silence, followed by a spatial arrival pulse.
t=time(1.1); x=np.zeros(len(t)); q=time(.22)
rise=np.sin(np.pi*q/.22)**2
add(x,(.18*noise(q,900,8000)+.13*osc(240+1800*(q/.22)**2))*rise)
q=time(.65); y=.28*osc(160+1000*np.exp(-q/.025))*env(q,.07,.0007)
y+=.16*noise(q,700,6500)*env(q,.052,.0004)
for f in [220,330]:y+=.08*np.sin(2*np.pi*f*q)*env(q,.14)
add(x,y,.27)
save('05-blink-phase-jump',x,.18,.16)

# Servo: motor movement with a quiet toothed modulation and a firm end stop.
t=time(.95); x=np.zeros(len(t)); q=time(.57)
gate=np.sin(np.pi*np.minimum(q/.57,1))**.65
f=115+95*np.sin(np.pi*q/.57)
p=2*np.pi*np.cumsum(f)/SR
y=(.19*np.sin(p+1.2*np.sin(p*2))+.04*noise(q,350,3000))*(.8+.2*np.sin(2*np.pi*38*q))*gate
add(x,y)
q=time(.2); add(x,(.2*noise(q,500,6500)+.22*osc(100+60*np.exp(-q/.008)))*env(q,.025,.0004),.57)
save('06-servo-move-and-lock',x,.135,.03)

# Crusher: brief pneumatic descent, dense collision, debris settling.
t=time(1.35); x=np.zeros(len(t)); q=time(.27)
add(x,.14*noise(q,250,4200)*np.sin(np.pi*q/.27)**1.2)
q=time(.8); y=.6*osc(38+100*np.exp(-q/.018))*env(q,.13,.0005)
y+=.5*np.tanh(noise(q,400,8000)*2)*env(q,.06,.0004)
for f in [137,231,389]:y+=.09*np.sin(2*np.pi*f*q)*env(q,.12)
add(x,y,.24)
for start,g in [(.36,.18),(.43,.12),(.54,.065)]:
    q=time(.2); add(x,noise(q,1400,7500)*env(q,.015,.0005),start,g)
save('07-crusher-heavy-press',x,.22,.05)

for row in manifest:
    a,sr=sf.read(OUT/row['file'])
    assert sr==SR and a.shape[1]==2 and np.isfinite(a).all()
    assert .01<np.max(abs(a))<.9 and np.max(abs(a[-100:]))==0
print(json.dumps(manifest,indent=2))
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
(OUT/'CREDITS.txt').write_text('Shift Circuit - procedural sound design audition 3\nSound design and synthesis: Codex GPT-6 Astra Medium\nAll audio in this batch is original procedural synthesis, with no samples or AI audio model.\nAudio dedicated to CC0 1.0: https://creativecommons.org/publicdomain/zero/1.0/\nGenerator code: MIT.\nNo installed game assets replaced.\n')
