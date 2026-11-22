import math, wave, struct, random
from pathlib import Path
random.seed(101)
p=Path(__file__).resolve().parent.parent/'assets'
SR=22050

def write(name,samples,loop=False):
    peak=max(1e-9,max(abs(x) for x in samples))
    with wave.open(str(p/(name+'.wav')),'wb') as w:
        w.setnchannels(1);w.setsampwidth(2);w.setframerate(SR)
        w.writeframes(struct.pack('<'+'h'*len(samples),*(int(max(-1,min(1,x/peak*.78))*32767) for x in samples)))
    if loop:
        (p/(name+'.wav.import')).write_text('[remap]\nimporter="wav"\ntype="AudioStreamWAV"\n\n[deps]\nsource_file="res://assets/'+name+'.wav"\n\n[params]\nforce/8_bit=false\nforce/mono=false\nforce/max_rate=false\nedit/trim=false\nedit/normalize=false\nedit/loop_mode=2\nedit/loop_begin=0\nedit/loop_end=-1\ncompress/mode=0\n')

def synth(name,duration,fn):
    samples=[];last=0
    for i in range(int(duration*SR)):
        t=i/SR;n=random.uniform(-1,1);last=last*.75+n*.25
        samples.append(fn(t,n,last))
    write(name,samples)

synth('ak',.25,lambda t,n,l:(l*1.2*math.exp(-t*35)+math.sin(2*math.pi*(100*t-100*t*t))*math.exp(-t*23)+n*.25*math.exp(-t*130)))
synth('shotgun',.5,lambda t,n,l:(l*2*math.exp(-t*16)+math.sin(2*math.pi*65*t)*math.exp(-t*16)+n*.35*math.exp(-t*60)))
synth('hit',.09,lambda t,n,l:math.sin(2*math.pi*1500*t)*math.exp(-t*60)*.5+n*math.exp(-t*100)*.3)
synth('hurt',.25,lambda t,n,l:math.sin(2*math.pi*(420*t-400*t*t))*math.exp(-t*13)*.5+l*.2*math.exp(-t*20))
synth('switch',.12,lambda t,n,l:n*math.exp(-t*70)+math.sin(2*math.pi*650*t)*math.exp(-t*50)*.25)
synth('reload',1.25,lambda t,n,l:sum(n*math.exp(-(t-k)*70)*.7 for k in [0,.33,.82,1.08] if 0<=t-k<.12))
synth('step',.12,lambda t,n,l:l*math.exp(-t*40)+math.sin(2*math.pi*85*t)*math.exp(-t*45)*.3)
synth('break',.5,lambda t,n,l:l*math.exp(-t*14)+math.sin(2*math.pi*(900*t-700*t*t))*math.exp(-t*12)*.3)
synth('bolt',.22,lambda t,n,l:math.sin(2*math.pi*(700*t-800*t*t))*math.exp(-t*22))
for name,notes in [('pickup',[659.25,830.61,987.77]),('win',[523.25,659.25,783.99,1046.5])]:
    synth(name,len(notes)*.18+.6,lambda t,n,l,notes=notes:sum(math.sin(2*math.pi*f*(t-j*.18))*math.exp(-(t-j*.18)*5)*.4 for j,f in enumerate(notes) if t>=j*.18))
# Original 8-bar ambient electronic loop, 100 BPM, A minor -> F -> C -> G.
beat=.6;duration=32*beat;N=int(duration*SR);out=[0.0]*N
chords=[[45,52,57,60,64],[41,48,53,57,60],[48,55,60,64,67],[43,50,55,59,62]]
def freq(m):return 440*2**((m-69)/12)
def add(start,dur,fn,gain):
    j=int(start*SR)
    for i in range(min(int(dur*SR),N-j)):
        t=i/SR;out[j+i]+=fn(t)*gain
for bar in range(8):
    chord=chords[(bar//2)%4]
    for note in chord[1:]:
        f=freq(note)
        add(bar*4*beat,4*beat,lambda t,f=f:(math.sin(2*math.pi*f*t)+.3*math.sin(2*math.pi*(f*1.003)*t))*math.sin(math.pi*t/(4*beat))**2,.045)
    for b in range(4):
        start=(bar*4+b)*beat
        f=freq(chord[0]-12)
        add(start,.48,lambda t,f=f:math.sin(2*math.pi*f*t)*min(1,t*30)*math.exp(-t*6),.15)
        if b%2==0:
            add(start,.26,lambda t:math.sin(2*math.pi*(48*t+7*(1-math.exp(-t*40))))*math.exp(-t*18),.20)
        else:
            add(start,.12,lambda t:random.uniform(-1,1)*math.exp(-t*40),.035)
    for k in range(8):
        f=freq(chord[1+k%4]+12)
        add(bar*4*beat+k*beat/2,.46,lambda t,f=f:math.sin(2*math.pi*f*t)*min(1,t*80)*math.exp(-t*11),.10)
        # synchronized echo
        add(bar*4*beat+k*beat/2+.225,.38,lambda t,f=f:math.sin(2*math.pi*f*t)*min(1,t*80)*math.exp(-t*13),.025)
write('orbital_drift',out,True)
print('Created original loop and 11 SFX')
