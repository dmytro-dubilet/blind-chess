"""Generate original, short wooden-piece sounds. No third-party recordings.
Run from any directory; writes the two bundled mono PCM WAV files.
"""
from pathlib import Path
import math
import random
import struct
import wave

OUT = Path(__file__).resolve().parents[1] / 'BlindChess' / 'Sounds'
RATE = 44100

def render(name, duration, impacts, seed):
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
