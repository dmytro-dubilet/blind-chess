"""Generate original board sounds and a short checkmate explosion. No third-party recordings.
Run from any directory; writes the bundled mono PCM WAV files.
"""
from pathlib import Path
import math
import random
import struct
import wave

OUT = Path(__file__).resolve().parents[1] / 'BlindChess' / 'Sounds'
RATE = 44100

def render(name, duration, impacts, seed, tones=()):
    rng = random.Random(seed)
    samples = []
    for i in range(round(duration * RATE)):
        t = i / RATE
        value = 0.0
        for start, gain, pitch in impacts:
            age = t - start
            if age < 0:
                continue
            # Broad attack followed by damped wood/body resonances, not a musical beep.
            attack = min(1, age / 0.0007)
            noise = rng.uniform(-1, 1) * math.exp(-age * 410) * 0.5
            body = sum(a * math.sin(2 * math.pi * f * pitch * age) * math.exp(-age * decay)
                       for f, a, decay in [(310, .4, 75), (740, .23, 110), (1610, .15, 145), (2720, .08, 220)])
            value += gain * attack * (noise + body)
        for start, frequency, gain, decay in tones:
            age = t - start
            if age >= 0:
                envelope = (1 - math.exp(-age * 300)) * math.exp(-age * decay)
                value += gain * envelope * (math.sin(2 * math.pi * frequency * age)
                                           + .18 * math.sin(2 * math.pi * frequency * 2.01 * age))
        fade = min(1, (duration - t) / .008)
        samples.append(value * fade)
    peak = max(abs(x) for x in samples)
    samples = [int(x / max(peak, 1) * 26000) for x in samples]
    OUT.mkdir(exist_ok=True)
    with wave.open(str(OUT / name), 'wb') as wav:
        wav.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        wav.writeframes(b''.join(struct.pack('<h', x) for x in samples))

render('move.wav', .115, [(0, .8, 1)], 42)
render('capture.wav', .18, [(0, .5, 1.16), (.043, .95, .78)], 73)

# Two rising, restrained taps signal check.
render('check.wav', .36, [(0, .65, 1.25), (.085, .42, 1.48)], 101,
       [(0, 660, .14, 19), (.085, 880, .18, 17)])
# A sharp blast, low pressure wave and fading debris. Band-limited noise gives
# the explosion body on phone speakers without relying on sub-bass alone.
def render_explosion():
    rng = random.Random(137)
    duration = 1.05
    samples = []
    low = mid = 0.0
    phase = 0.0
    debris = [(rng.uniform(.08, .68), rng.uniform(.025, .065)) for _ in range(18)]
    for i in range(round(duration * RATE)):
        t = i / RATE
        noise = rng.uniform(-1, 1)
        low += .035 * (noise - low)
        mid += .19 * (noise - mid)
        attack = 1 - math.exp(-t * 2800)
        crack = .7 * noise * math.exp(-t * 100)
        roar = (1.8 * low + .85 * mid) * math.exp(-t * 5.3)
        phase += 2 * math.pi * (55 + 115 * math.exp(-t * 18)) / RATE
        pressure = (.23 * math.sin(phase) + .10 * math.sin(phase * 2.07)) * math.exp(-t * 11)
        crackle = sum(gain * noise * math.exp(-(t - start) * 180)
                      for start, gain in debris if t >= start)
        fade = min(1, (duration - t) / .1)
        samples.append(attack * (crack + roar + pressure + crackle) * fade)
    peak = max(abs(x) for x in samples)
    with wave.open(str(OUT / 'mate.wav'), 'wb') as wav:
        wav.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        wav.writeframes(b''.join(struct.pack('<h', round(x / peak * 26000)) for x in samples))

render_explosion()
