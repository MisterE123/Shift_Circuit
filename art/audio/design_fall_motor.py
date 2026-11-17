"""Deterministic original procedural SFX. Code: MIT. Rendered audio: CC0."""
from pathlib import Path
import json
import numpy as np
import soundfile as sf

SR=48000
OUT=Path('outputs/fall-audition-motor')
OUT.mkdir(parents=True,exist_ok=True)
rng=np.random.default_rng(8135)
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

# Wheel slip follows the initial .25s slide. Drop begins at .18s.
# The motor remains audible after visual disappearance at 1s, receding to 2.5s.
t=time(2.5);x=np.zeros(len(t))
q=time(.30);f=155+65*np.sin(np.minimum(1,q/.16)*np.pi/2)
p=2*np.pi*np.cumsum(f)/SR
wheel=(np.sin(p)+.22*np.sin(2*p)+.065*np.sin(4*p))
add(x,.10*wheel*(1-np.exp(-q/.018))*np.exp(-np.maximum(q-.12,0)/.065))
q=time(2.32);a=q/2.32;f=175-100*(1-np.exp(-q/.60))
p=2*np.pi*np.cumsum(f)/SR
# Gear sidebands and soft pump vibration give the tone a mechanical body.
y=.15*np.sin(p)+.04*np.sin(2*p)+.018*np.sin(p*3)
y+=.022*np.sin(p*(1+.018*np.sin(2*np.pi*3*q)))
y+=.010*noise(q,160,1900)*(.6+.4*np.sin(2*np.pi*24*q)**2)
distance=(1-np.exp(-q/.035))*np.exp(-q/ .56)*(1-a)**1.2
add(x,y*distance,.18)
save('01-fall-receding-motors',x,.13,.025)
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2))
(OUT/'CREDITS.txt').write_text('Original procedural synthesis: Codex GPT-6 Astra Medium. Audio CC0; recipe MIT. Preview only. Wheel slip 0-.3s; drop starts .18s; motor fades beyond visual disappearance at 1s to silence at 2.5s.\n')
