"""Deterministic original procedural SFX. Code: MIT. Rendered audio: CC0."""
from pathlib import Path
import json
import numpy as np
import soundfile as sf

SR=48000
OUT=Path('outputs/scifi-audition-v5')
OUT.mkdir(parents=True,exist_ok=True)
rng=np.random.default_rng(5591)
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

# Crusher: pulsing hydraulic pump, steel plate collision and geared return.
# Mechanical textures dominate; no clean rising sci-fi oscillator sweep.
def resonance(t, modes, decay):
    x=np.zeros(len(t))
    for f,g in modes:
        x+=g*np.sin(2*np.pi*f*t+rng.uniform(-.2,.2))*env(t,decay,.0005)
    return x
t=time(2.35); x=np.zeros(len(t)); q=time(.63)
gate=np.sin(np.pi*q/.63)**.55
pump=(.35+.65*np.sin(2*np.pi*24*q)**4)
y=(.12*noise(q,100,1600)*pump+.035*noise(q,1700,4400))*gate
y+=.035*np.tanh(3*np.sin(2*np.pi*96*q))*(.6+.4*pump)*gate
add(x,y)
for start in [.06,.15,.25,.36,.48]:
    q=time(.075)
    add(x,noise(q,800,3800)*env(q,.008,.0004),start,.045)
q=time(.65)
hit=.38*noise(q,180,6500)*env(q,.022,.0003)
hit+=.45*osc(45+70*np.exp(-q/.01))*env(q,.075,.0006)
hit+=resonance(q,[(173,.18),(291,.14),(487,.12),(821,.065),(1427,.035)],.085)
add(x,hit,.64)
q=time(.22)
add(x,noise(q,900,6000)*env(q,.012,.0003),.68,.12)
q=time(.75); gate=np.sin(np.pi*q/.75)**.6
gears=(.5+.5*np.sin(2*np.pi*37*q)**6)
y=(.105*noise(q,250,2800)*gears+.035*noise(q,2500,6500))*gate
y+=.045*np.tanh(2*np.sin(2*np.pi*145*q))*gate
add(x,y,.98)
q=time(.15)
add(x,resonance(q,[(267,.09),(433,.07),(779,.04)],.026),1.73)
save('01-crusher-pump-steel-gears',x,.19,.025)

# Shared tactile UI vocabulary: brief contact noise and damped pitched body.
def contact(duration=.12, pitch=450, strength=1):
    q=time(duration)
    y=.16*noise(q,1300,6500)*env(q,.005,.0003)
    y+=.2*osc(pitch+100*np.exp(-q/.004))*env(q,.017,.0005)
    return strength*y

t=time(.28); x=np.zeros(len(t)); add(x,contact(pitch=480))
save('02-menu-click',x,.105,.015)

t=time(.38); x=np.zeros(len(t)); add(x,contact(pitch=430),g=.65)
q=time(.2); add(x,.15*osc(230+280*np.exp(-q/.018))*env(q,.035,.001),.015)
save('03-menu-back',x,.105,.02)

t=time(.61); x=np.zeros(len(t)); add(x,contact(pitch=500),g=.7)
q=time(.4)
for f,g in [(330,.13),(440,.11),(554.365,.08)]:
    add(x,g*np.sin(2*np.pi*f*q)*env(q,.075,.003),.025)
save('04-menu-confirm',x,.12,.045)

t=time(.55); x=np.zeros(len(t)); q=time(.15)
for start in [0,.105]:
    pulse=(.15*np.sin(2*np.pi*196*q)+.065*np.sin(2*np.pi*207*q))
    pulse+=.035*noise(q,650,2400)
    add(x,pulse*env(q,.029,.003),start)
save('05-menu-unavailable',x,.115,.015)

t=time(.36); x=np.zeros(len(t)); add(x,contact(pitch=520),g=.65)
q=time(.18)
for start,f in [(0,440),(.04,660)]:
    add(x,.12*np.sin(2*np.pi*f*q)*env(q,.028,.001),start)
save('06-toggle-on',x,.105,.02)

t=time(.36); x=np.zeros(len(t)); add(x,contact(pitch=390),g=.65)
q=time(.18)
for start,f in [(0,660),(.04,440)]:
    add(x,.12*np.sin(2*np.pi*f*q)*env(q,.028,.001),start)
save('07-toggle-off',x,.105,.02)

for row in manifest:
    a,sr=sf.read(OUT/row['file'])
    assert sr==SR and a.shape[1]==2 and np.isfinite(a).all()
    assert .01<np.max(abs(a))<.9 and np.max(abs(a[-100:]))==0
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps(manifest,indent=2))
(OUT/'CREDITS.txt').write_text('Shift Circuit - procedural sound design audition 5\nSound design and synthesis: Codex GPT-6 Astra Medium\nOriginal procedural synthesis; no external samples or AI audio model.\nAudio: CC0 1.0 https://creativecommons.org/publicdomain/zero/1.0/\nGenerator code: MIT.\nUI hover and scrolling intentionally silent. No installed game assets replaced.\n')
