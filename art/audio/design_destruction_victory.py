"""Deterministic original procedural SFX. Code: MIT. Rendered audio: CC0."""
from pathlib import Path
import json
import numpy as np
import soundfile as sf

SR=48000
OUT=Path('outputs/destruction-victory-audition')
OUT.mkdir(parents=True,exist_ok=True)
rng=np.random.default_rng(7813)
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

def metal(t,decay=.1):
    x=np.zeros(len(t))
    for f,g in [(173,.22),(287,.17),(493,.11),(827,.07),(1511,.035)]:
        x+=g*np.sin(2*np.pi*f*t)*env(t,decay,.0006)
    return x

def impact(t):
    return .5*osc(43+120*np.exp(-t/.012))*env(t,.11,.0005)+.32*np.tanh(2*noise(t,190,7100))*env(t,.042,.0004)

# Crushing: buckling steel, deep impact, small scattered pieces.
t=time(1.65);x=impact(t)+metal(t,.105)
for start,g in [(.045,.65),(.105,.48),(.19,.28),(.32,.17),(.50,.085),(.72,.04)]:
    q=time(.28);add(x,g*(metal(q,.045)+.22*noise(q,550,6500)*env(q,.016,.0005)),start)
q=time(.35);add(x,.12*noise(q,100,1800)*env(q,.08,.001),.08)
save('01-destruction-crushed-chassis',x,.24,.065)

# Electrical failure: violent arcs, interrupted power and a collapsing motor.
t=time(1.65);x=.65*impact(t)
for start,d,g in [(0,.11,.36),(.10,.15,.27),(.24,.20,.21),(.43,.26,.13),(.70,.18,.065)]:
    q=time(d);f=145+760*np.exp(-q/.026);phase=2*np.pi*np.cumsum(f)/SR
    buzz=np.tanh(3*np.sin(phase+2.5*np.sin(phase*1.47)))
    y=(buzz*.45+noise(q,900,6800)*.45)*(np.sin(2*np.pi*43*q)>-.25)*env(q,d*.3,.001)
    add(x,y,start,g)
q=time(.8);add(x,.12*osc(42+240*np.exp(-q/.16))*env(q,.22,.012),.14)
save('02-destruction-electrical-burnout',x,.23,.055)

# Reactor rupture: pressure pop and a broad low-frequency energy collapse.
t=time(2.0);x=.70*impact(t)+.48*noise(t,35,950)*env(t,.23,.001)
x+=.17*noise(t,650,5100)*env(t,.13,.0007)
q=time(.95);add(x,.12*osc(31+87*np.exp(-q/.19))*env(q,.32,.01),.07)
for start,g in [(.14,.2),(.27,.13),(.48,.07)]:
    q=time(.26);add(x,g*(metal(q,.07)+noise(q,1400,6200)*env(q,.025)),start)
save('03-destruction-reactor-rupture',x,.25,.09)

# Mechanical breakup: snapping drivetrain, heavy separated parts, final power loss.
t=time(1.8);x=.70*impact(t)+.6*metal(t,.08)
for start,g,f in [(.10,.6,82),(.23,.42,63),(.39,.28,119),(.60,.16,154),(.85,.075,211)]:
    q=time(.30);y=.35*osc(f+45*np.exp(-q/.009))*env(q,.055,.001)+metal(q,.055)+.16*noise(q,500,6300)*env(q,.015,.0005)
    add(x,y,start,g)
q=time(.45);add(x,.045*np.tanh(2*osc(60+150*np.exp(-q/.1)))*env(q,.12,.01),.65)
save('04-destruction-drivetrain-breakup',x,.24,.06)

# Warm sci-fi chords: no chirpy arpeggios. Filtered harmonics and a soft attack.
def chord(freqs,d,decay,attack=.014):
    t=time(d);x=np.zeros(len(t))
    for i,f in enumerate(freqs):
        p=2*np.pi*f*t
        x+=(np.sin(p)+.16*np.sin(2*p)+.045*np.sin(3*p))*env(t,decay,attack)/len(freqs)
        x+=.07*np.sin(2*np.pi*(f*1.003)*t)*env(t,decay,attack)/len(freqs)
    return x
x=chord([130.813,261.626,329.628,391.995],1.9,.52)
save('05-victory-clean-win-chord',x,.20,.13)
x=np.zeros(len(time(2.8)))
add(x,chord([146.832,220,293.665,369.994],.8,.28),0,.56)
add(x,chord([130.813,261.626,329.628,391.995,523.251],2.3,.73,.018),.43,1)
q=time(.25);add(x,.15*osc(48+35*np.exp(-q/.02))*env(q,.07),.43)
save('06-victory-race-finish',x,.22,.16)
x=chord([130.813,195.998,329.628,440],2.3,.70,.026)
q=time(.8);add(x,.025*noise(q,1200,4800)*env(q,.16,.025),0)
save('07-victory-puzzle-resolved',x,.19,.16)
for row in manifest:
    a,sr=sf.read(OUT/row['file'])
    assert sr==SR and np.isfinite(a).all() and .02<abs(a).max()<.95
    assert abs(a[-100:]).max()==0
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2))
(OUT/'CREDITS.txt').write_text('Original procedural synthesis by Codex GPT-6 Astra Medium. Audio CC0 1.0; recipe MIT. Preview only; no game assets replaced. No external samples or audio generation model.\n')
print(json.dumps(manifest,indent=2))
