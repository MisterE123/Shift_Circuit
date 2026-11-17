from pathlib import Path
import numpy as np
import soundfile as sf

SR = 48000
OUT = Path('outputs/scifi-audition-v2')
BASE = Path('outputs/chiptone-audition')
rng = np.random.default_rng(731)

def time(d): return np.arange(round(d*SR))/SR
def env(t, decay, attack=.002): return (1-np.exp(-t/attack))*np.exp(-t/decay)
def osc(freq): return np.sin(2*np.pi*np.cumsum(freq)/SR)
def noise(t, lo, hi):
    x=rng.normal(size=len(t)); f=np.fft.rfftfreq(len(t),1/SR)
    mask=(1-np.exp(-(f/max(lo,1))**4))*np.exp(-(f/hi)**4)
    y=np.fft.irfft(np.fft.rfft(x)*mask,n=len(t))
    return y/(np.std(y)+1e-8)
def add(dst, src, start=0, gain=1):
    i=round(start*SR); n=min(len(src),len(dst)-i)
    if n>0: dst[i:i+n]+=src[:n]*gain
def chip(name, rate=1):
    x,sr=sf.read(BASE/name)
    if x.ndim>1:x=x.mean(axis=1)
    return np.interp(np.arange(0,len(x),sr/SR*rate),np.arange(len(x)),x)
def finish(name,x,tail=.2,level=.16):
    # Dry center remains clear; quiet, filtered reflections give width.
    stereo=np.stack([x.copy(),x.copy()],axis=1)
    for delay,gain in [(0.029,.11),(.047,.08),(.079,.06),(.113,.035)]:
        for c in range(2):
            shift=round((delay+c*.007)*SR)
            stereo[shift:,c]+=x[:-shift]*gain
    stereo=np.tanh(stereo*1.15)
    active=np.sqrt(np.mean(stereo**2,axis=1))>.008
    rms=np.sqrt(np.mean(stereo[active]**2)) if active.any() else 1
    stereo*=min(level/max(rms,1e-8),.88/max(np.max(abs(stereo)),1e-8))
    n=min(round(.002*SR),len(x)); stereo[:n]*=np.linspace(0,1,n)[:,None]
    n=round(.08*SR); stereo[-n:]*=np.linspace(1,0,n)[:,None]
    stereo=np.pad(stereo,((0,round(tail*SR)),(0,0)))
    assert np.isfinite(stereo).all() and np.max(abs(stereo))<1
    sf.write(OUT/(name+'.wav'),stereo,SR,subtype='PCM_24')
    print(name,round(len(stereo)/SR,2),'s; peak',round(float(np.max(abs(stereo))),3))

# Laser: abrupt charge release, falling FM buzz, sputtering electric tail.
t=time(.78); f=190+1850*np.exp(-t/0.052)
carrier=2*np.pi*np.cumsum(f)/SR
mod=osc(f*2.13)
x=.43*np.sin(carrier+3.1*np.exp(-t/.095)*mod)*env(t,.075,.0007)
x+=.19*noise(t,1800,8500)*env(t,.045,.0003)
x+=.12*noise(t,400,4700)*(0.3+.7*np.sin(2*np.pi*93*t)**8)*env(t,.13)
add(x,chip('01-laser.wav',1.7),gain=.35)
finish('01-laser-electric-snap',x,level=.19)

# Pickup: low landing accent followed by overlapping, consonant metallic tones.
t=time(1.45); x=.18*osc(85+80*np.exp(-t/.018))*env(t,.08)
for start,f,g in [(0,330,.25),(.055,440,.23),(.105,554.365,.20),(.16,660,.23)]:
    q=time(1.1); p=2*np.pi*f*q
    tone=(np.sin(p+1.1*np.exp(-q/.035)*np.sin(p*2))+.18*np.sin(p*3.01))*env(q,.26,.004)
    add(x,tone,start,g)
add(x,chip('02-pickup.wav',.62),gain=.12)
finish('02-pickup-energy-cache',x,level=.17)

# Card lock: physical click, compact low body, tiny bright confirmation interval.
t=time(.46); x=.25*noise(t,1100,6500)*env(t,.009,.0003)
x+=.32*osc(190+250*np.exp(-t/.009))*env(t,.024,.0005)
for start,f in [(0,740),(.025,1108.73)]:
    q=time(.2); add(x,np.sin(2*np.pi*f*q)*env(q,.025,.001),start,.13)
add(x,chip('03-card-selection.wav',1.5),gain=.12)
finish('03-card-magnetic-lock',x,tail=.1,level=.14)

# Damage: broadband crack over a sub impact and dissonant ringing chassis.
t=time(1.0); x=.65*osc(48+115*np.exp(-t/.018))*env(t,.105,.0006)
x+=.35*noise(t,450,9500)*env(t,.038,.0004)
for f,g in [(217,.17),(363,.13),(587,.10),(947,.07)]:
    x+=g*np.sin(2*np.pi*f*t+1.9*np.sin(2*np.pi*f*1.43*t)*np.exp(-t/.08))*env(t,.13)
add(x,chip('04-impact.wav',.7),gain=.6)
finish('04-damage-chassis-crack',x,level=.23)

# Checkpoint: a grounded resolving chord, no high arcade arpeggio.
t=time(2.0); x=.12*osc(65+70*np.exp(-t/.03))*env(t,.13)
for start,notes in [(0,[164.81,246.94]),(.18,[220,277.18,329.63])]:
    q=time(1.65)
    for f in notes:
        p=2*np.pi*f*q
        tone=(np.sin(p)+.20*np.sin(2*p)+.07*np.sin(3*p))*env(q,.42,.012)
        add(x,tone,start,.19)
add(x,chip('05-checkpoint.wav',.42),gain=.045)
finish('05-checkpoint-system-secured',x,level=.17)

(OUT/'CREDITS.txt').write_text('Shift Circuit SFX audition v2\n\nOriginal ChipTone-generated clips layered with custom procedural synthesis, FM, filtered noise, envelopes, and stereo reflections.\nChipTone: Tom Vian / SFB Games, https://sfbgames.itch.io/chiptone\nSound design and processing: Codex GPT-6 Astra Medium\nAll generated audio in this audition set: CC0 1.0\nhttps://creativecommons.org/publicdomain/zero/1.0/\nNo installed game sounds changed.\n',encoding='utf-8')
