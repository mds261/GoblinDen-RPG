import numpy as np, wave, json
from pathlib import Path
RATE=22050
OUT=Path(__file__).resolve().parents[1]/'assets'/'audio';OUT.mkdir(parents=True,exist_ok=True)
rng=np.random.default_rng(86213)
metrics={}
def write(name,data,peak=.68):
 data=np.asarray(data,dtype=np.float64)
 data-=data.mean(axis=0)
 data*=peak/max(float(np.max(np.abs(data))),1e-9)
 pcm=np.round(np.clip(data,-.98,.98)*32767).astype('<i2')
 with wave.open(str(OUT/(name+'.wav')),'wb') as w:
  w.setnchannels(1 if data.ndim==1 else data.shape[1]);w.setsampwidth(2);w.setframerate(RATE);w.writeframes(pcm.tobytes())
 metrics[name]={'duration':len(data)/RATE,'peak':float(np.max(np.abs(data))),'rms':float(np.sqrt(np.mean(data*data))),'loop_boundary_delta':float(np.max(np.abs(data[-1]-data[0])))}
 return data

def freq(m):return 440*2**((m-69)/12)
def env(t,d,a=.02,r=.15):return np.minimum(1,t/max(a,.001))*np.minimum(1,np.maximum(0,d-t)/max(r,.001))
def tone(m,d,kind='harp',amp=1):
 t=np.arange(int(d*RATE))/RATE;f=freq(m)
 if kind=='harp':
  y=sum(np.sin(2*np.pi*f*k*t+.02*k)*np.exp(-t*(2.2+k*.8))/(k**1.8) for k in range(1,7));e=env(t,d,.007,.20)
 elif kind=='flute':
  phase=2*np.pi*np.cumsum(f*(1+.002*np.sin(2*np.pi*5.1*t)))/RATE
  breath=np.convolve(rng.normal(0,1,len(t)),np.ones(19)/19,'same')
  y=np.sin(phase)+.16*np.sin(2*phase)+.04*np.sin(3*phase)+.025*breath;e=env(t,d,.12,.25)
 elif kind=='pad':
  y=sum(np.sin(2*np.pi*f*(k+.0007*np.sin(t*.7))*t)/k**2.0 for k in range(1,5));e=env(t,d,.6,.9)*(.92+.08*np.sin(2*np.pi*.3*t))
 elif kind=='bell':
  y=np.sin(2*np.pi*f*t)*np.exp(-t*2)+.35*np.sin(2*np.pi*f*2.002*t)*np.exp(-t*4)+.08*np.sin(2*np.pi*f*4.1*t)*np.exp(-t*6);e=env(t,d,.004,.25)
 return y*e*amp

def track(name,mode):
 beat=60/(76 if mode=='haven' else 72);bar=beat*4;bars=24;n=int(round(bars*bar*RATE));mix=np.zeros((n,2))
 def add(note,start,pan=0):
  idx=(np.arange(len(note))+int(round(start*RATE)))%n
  np.add.at(mix[:,0],idx,note*np.sqrt((1-pan)/2));np.add.at(mix[:,1],idx,note*np.sqrt((1+pan)/2))
 chords=([(50,57,62,65),(46,53,58,62),(53,60,65,69),(48,55,60,64),(50,57,62,65),(43,50,58,62),(45,52,61,64),(50,57,62,65)] if mode!='woodland' else [(50,57,62,65),(55,62,67,71),(48,55,60,64),(53,60,65,69),(50,57,62,65),(55,62,67,71),(45,52,57,64),(50,57,62,65)])
 melodies=[[74,77,76,74],[69,72,74,None],[77,79,81,77],[76,74,72,None],[74,77,81,79],[77,74,72,70],[73,76,69,None],[74,None,69,None]]
 for b in range(bars):
  chord=chords[b%8];start=b*bar;cycle=b//8
  for i,m in enumerate(chord):
   add(tone(m-12 if i==0 else m,bar+1.5,'pad',.10 if mode=='dungeon' else .075),start-.2,(i-1.5)*.32)
  order=[0,2,1,3,1,2,0,1]
  if mode!='dungeon':
   for j in range(8):
    add(tone(chord[order[j]]+12,beat*1.4,'harp',.16 if mode=='haven' else .125),start+j*beat*.5,(-1 if j%2 else 1)*.32)
   # Airy woodwind melody with breathing space and varied second/third phrases.
   if b%8 not in [3,7]:
    for j,m in enumerate(melodies[b%8]):
     if m is not None and not (cycle==1 and j==3):
      add(tone(m+(12 if cycle==2 and mode=='woodland' and j==0 else 0),beat*.82,'flute',.14 if mode=='woodland' else .105),start+(j+.12)*beat,.12)
   if b%4==0:add(tone(chord[2]+12,bar*.9,'bell',.08),start,-.4)
  else:
   for j in [0,3,5]:add(tone(chord[j%4],beat*2,'harp',.11),start+j*beat*.5,(-1 if j%2 else 1)*.25)
   if b%2==0:add(tone(chord[2]+12,bar*.9,'bell',.07),start+beat*2,.35)
   if b%4==2:add(tone(chord[3]+12,bar*.75,'flute',.04),start+beat,.1)
  # Restrained hand-drum pulse rather than a loud combat beat.
  if mode!='haven':
   for pulse in [0,2]:
    t=np.arange(int(.25*RATE))/RATE;y=np.sin(2*np.pi*(65*t+5*(1-np.exp(-t*30))))*np.exp(-t*23)*env(t,.25,.006,.03)
    add(y*.065,start+pulse*beat,-.15)
 # Circular delays make reverb tails wrap smoothly across the musical loop.
 wet=mix.copy()
 for delay,amount in [(.137,.12),(.293,.10),(.431,.075),(.677,.04)]:wet+=np.roll(mix[:,::-1],int(delay*RATE),axis=0)*amount
 write(name,np.tanh(wet*1.15),.62)

import sys
if '--effects-only' in sys.argv and (OUT/'audio-metrics.json').exists():
 metrics.update({k:v for k,v in json.loads((OUT/'audio-metrics.json').read_text()).items() if k.startswith('music_')})
if '--effects-only' not in sys.argv:
 track('music_haven','haven');track('music_woodland','woodland');track('music_descent','dungeon')
# Effects use different envelopes and spectra so they remain identifiable in a mix.
def noise(t,smooth=1):
 x=rng.normal(0,1,len(t))
 return np.convolve(x,np.ones(smooth)/smooth,'same') if smooth>1 else x
for name in ['hit','hurt','swing','dodge','interact','bow','magic','loot','coin','potion','death','level_up','stairs','boss','step_stone','step_grass']:
 d={'hit':.21,'hurt':.32,'swing':.28,'dodge':.30,'interact':.25,'bow':.28,'magic':.65,'loot':.43,'coin':.38,'potion':.65,'death':.65,'level_up':1.7,'stairs':.52,'boss':1.0,'step_stone':.12,'step_grass':.14}[name]
 t=np.arange(int(d*RATE))/RATE;N=noise(t);soft=noise(t,9)
 if name=='hit':y=(.65*soft*np.exp(-t*37)+.34*np.sin(2*np.pi*(105*t+3*(1-np.exp(-25*t))))*np.exp(-t*23))
 elif name=='hurt':y=.5*soft*np.exp(-t*22)+.4*np.sin(2*np.pi*(64*t+2*(1-np.exp(-18*t))))*np.exp(-t*12)
 elif name in ['swing','dodge']:y=noise(t,15)*np.sin(np.pi*t/d)**2*(.8 if name=='swing' else 1)*np.exp(-t*3)
 elif name=='bow':y=.32*noise(t,11)*np.exp(-t*35)+.24*np.sin(2*np.pi*190*t)*np.exp(-t*23)
 elif name=='magic':y=(.40*noise(t,23)+.045*np.sin(2*np.pi*196*t)+.025*np.sin(2*np.pi*294*t))*np.sin(np.pi*t/d)**2*np.exp(-t*4)
 elif name in ['loot','coin','interact']:
  base={'loot':440,'coin':587,'interact':330}[name]
  y=sum(np.sin(2*np.pi*base*ratio*t)*np.exp(-t*decay)*amp for ratio,decay,amp in [(1,24,.30),(1.51,32,.08),(2.01,42,.025)])+.025*noise(t,17)*np.exp(-t*55)
 elif name=='potion':y=.35*noise(t,29)*np.sin(np.pi*t/d)**2*np.exp(-t*4)+.045*np.sin(2*np.pi*(135*t+2*t*t))*np.exp(-t*10)
 elif name=='death':y=.5*noise(t,14)*np.exp(-t*6)+.24*np.sin(2*np.pi*(90*t-42*t*t))*np.exp(-t*5)
 elif name=='stairs':y=.5*noise(t,13)*np.exp(-t*9)+.18*np.sin(2*np.pi*73*t)*np.exp(-t*9)
 elif name=='boss':y=.4*noise(t,25)+.35*np.sin(2*np.pi*48*t)+.12*np.sin(2*np.pi*71*t)
 elif name=='step_stone':y=.5*noise(t,3)*np.exp(-t*60)+.25*np.sin(2*np.pi*160*t)*np.exp(-t*48)
 elif name=='step_grass':y=noise(t,7)*np.exp(-t*30)
 else:
  y=np.zeros(len(t))
  for j,m in enumerate([62,65,69,74]):
   sig=tone(m,1.1,'harp',.3);at=int(j*.16*RATE);end=min(len(y),at+len(sig));y[at:end]+=sig[:end-at]
 # Gentle attacks and band-limited noise avoid clicks and brittle high hiss.
 y=np.convolve(y,np.hanning(13)/np.hanning(13).sum(),'same')*env(t,d,.012,.065)
 write(name,y,.38 if name in ['interact','coin','loot','magic','potion','level_up'] else (.42 if name.startswith('step') else .52))
(OUT/'audio-metrics.json').write_text(json.dumps(metrics,indent=2))
