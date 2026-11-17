"""Deterministic original procedural SFX. Code: MIT. Rendered audio: CC0."""
from pathlib import Path
import json
import numpy as np
import soundfile as sf

SR=48000
OUT=Path('outputs/scifi-audition-v4')
OUT.mkdir(parents=True,exist_ok=True)
rng=np.random.default_rng(4841)
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

# Motor: smooth acceleration and braking, no impact transient.
def motor(duration, base=140, sweep=100, gain=.2):
    q=time(duration)
    gate=np.minimum(q/.055,1)*np.minimum((duration-q)/.09,1)
    gate=np.sin(np.clip(gate,0,1)*np.pi/2)**2
    f=base+sweep*np.sin(np.pi*q/duration)
    p=2*np.pi*np.cumsum(f)/SR
    y=.75*np.sin(p+.48*np.sin(2*p))+.16*np.sin(p*3)+.08*noise(q,400,2600)
    return gain*y*(.94+.06*np.sin(2*np.pi*42*q))*gate

t=time(.95); x=np.zeros(len(t)); add(x,motor(.67))
save('01-robot-smooth-whirr',x,.125,.025)

# Hydraulic pressure builds, heavy ram lands, quieter motor returns.
t=time(2.25); x=np.zeros(len(t)); q=time(.58)
gate=np.sin(np.pi*q/.58)**.7
f=230+430*(q/.58)**1.4
p=2*np.pi*np.cumsum(f)/SR
y=(.16*np.sin(p+.35*np.sin(2*p))+.045*noise(q,700,4400))*gate
add(x,y)
q=time(.65)
y=.58*osc(44+110*np.exp(-q/.014))*env(q,.085,.0006)
y+=.32*np.tanh(noise(q,500,7500)*2.4)*env(q,.034,.0005)
for f in [153,247,403]:y+=.075*np.sin(2*np.pi*f*q)*env(q,.085)
add(x,y,.59)
add(x,motor(.77,210,-85,.14),.96)
save('02-crusher-load-chunk-retract',x,.18,.035)

# Turning uses the same motor timbre at a shorter duration.
t=time(.67); x=np.zeros(len(t)); add(x,motor(.36,170,80,.18))
save('03-robot-turn-whirr',x,.12,.02)

# Pusher: controlled pressure stroke followed by a lighter return.
t=time(1.4); x=np.zeros(len(t)); q=time(.4)
y=(.13*noise(q,400,3300)+.14*osc(130+80*np.sin(np.pi*q/.4)))*np.sin(np.pi*q/.4)**.7
add(x,y)
q=time(.2); add(x,(.17*noise(q,600,5500)+.23*osc(95+70*np.exp(-q/.012)))*env(q,.027,.001),.39)
add(x,motor(.4,180,-65,.11),.62)
save('04-pusher-pressure-stroke',x,.145,.03)

# Repair: soft resonant assembly pulses resolving into a gentle consonance.
t=time(1.35); x=np.zeros(len(t))
for start,f,g in [(0,261.63,.17),(.085,329.63,.16),(.17,392,.15)]:
    q=time(.85); p=2*np.pi*f*q
    add(x,(np.sin(p+.3*np.sin(2*p)*np.exp(-q/.03))+.1*np.sin(2*p))*env(q,.22,.008),start,g)
save('05-repair-hull-restored',x,.145,.07)

# Recharge: swelling electrical hum that settles into a stable tone.
t=time(1.45); x=np.zeros(len(t)); q=time(.95)
f=130+130*(1-np.exp(-q/.16)); p=2*np.pi*np.cumsum(f)/SR
gate=(1-np.exp(-q/.07))*np.exp(-np.maximum(q-.53,0)/.13)
y=(.18*np.sin(p+.6*np.sin(2*p))+.065*np.sin(3*p)+.025*noise(q,1200,4800))*gate
add(x,y)
save('06-recharge-power-online',x,.15,.075)

# Destruction: heavier than hull damage, with scattered fragments and failing power.
t=time(1.7); x=.43*osc(35+110*np.exp(-t/.024))*env(t,.16,.0006)
x+=.38*np.tanh(noise(t,180,7800)*2.7)*env(t,.095,.0004)
for start,g,d in [(0,.3,.02),(.04,.22,.03),(.095,.18,.023),(.19,.12,.022),(.31,.08,.02),(.44,.045,.025)]:
    q=time(.25); add(x,noise(q,1100,9000)*env(q,d,.0005),start,g)
q=time(.6); add(x,.10*osc(60+390*np.exp(-q/.13))*env(q,.17,.01),.23)
save('07-destruction-shattered-chassis',x,.22,.045)

for row in manifest:
    a,sr=sf.read(OUT/row['file'])
    assert sr==SR and a.shape[1]==2 and np.isfinite(a).all()
    assert .01<np.max(abs(a))<.9 and np.max(abs(a[-100:]))==0
print(json.dumps(manifest,indent=2))
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
(OUT/'CREDITS.txt').write_text('Shift Circuit - procedural sound design audition 4\nSound design and synthesis: Codex GPT-6 Astra Medium\nOriginal procedural synthesis; no samples or AI audio model.\nAudio: CC0 1.0 https://creativecommons.org/publicdomain/zero/1.0/\nGenerator code: MIT.\nNo installed game assets replaced.\n')
