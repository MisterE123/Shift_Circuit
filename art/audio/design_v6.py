"""Deterministic original procedural SFX. Code: MIT. Rendered audio: CC0."""
from pathlib import Path
import json
import numpy as np
import soundfile as sf

SR=48000
OUT=Path('outputs/scifi-audition-v6')
OUT.mkdir(parents=True,exist_ok=True)
rng=np.random.default_rng(6602)
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

# Belt motor, rubber friction and regularly spaced roller contacts.
t=time(1.05); gate=np.minimum(1,t/.045)*np.minimum(1,(1.05-t)/.12)
pulse=(.55+.45*np.cos(2*np.pi*19*t)**8)
x=(.065*noise(t,130,2200)*pulse+.018*noise(t,2300,4800))
x+=.035*np.tanh(2.2*np.sin(2*np.pi*94*t))+.018*np.sin(2*np.pi*188*t)
save('01-conveyor-rollers',x*gate,.14,.025)
# Pressurized oil pump builds for .16 seconds before a .55 second stroke.
t=time(.71); gate=np.minimum(1,t/.035)*np.minimum(1,(.71-t)/.045)
pump=.5+.5*np.sin(2*np.pi*31*t)**6
x=.12*noise(t,80,1700)*pump+.045*noise(t,1700,6200)
x+=.055*np.tanh(2.8*np.sin(2*np.pi*115*t))
x*=gate*(.45+.55*np.minimum(1,t/.16))
q=time(.10);add(x,.18*noise(q,700,6500)*env(q,.025),.16)
save('02-pusher-hydraulic-extension',x,.23,.025)
# End stop is triggered by reaching the endpoint, not a guessed delay.
t=time(.23)
x=.28*noise(t,140,5600)*env(t,.018,.0004)
x+=.36*osc(48+85*np.exp(-t/.012))*env(t,.065,.0005)
for f,g in [(183,.12),(347,.09),(791,.045)]:x+=g*np.sin(2*np.pi*f*t)*env(t,.04,.0005)
save('03-pusher-end-stop',x,.25,.035)
t=time(.50);gate=np.sin(np.pi*t/.50)**.5
x=(.09*noise(t,100,2100)*(.6+.4*np.sin(2*np.pi*27*t)**4)+.035*noise(t,2100,5400))
x+=.035*np.tanh(2*np.sin(2*np.pi*103*t))
save('04-pusher-hydraulic-return',x*gate,.17,.025)
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2))
