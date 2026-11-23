"""Generate synthetic procedural audio assets for Dhaka Deadline.
Includes engine loops, tire roll, tire screech, horns, impact, traffic engines, and city ambience.
All sounds are mathematically synthesized; no external audio recordings or paid assets are used.
"""
from pathlib import Path
import math
import struct
import wave
import random

root = Path(__file__).resolve().parents[1] / 'assets' / 'audio'
root.mkdir(parents=True, exist_ok=True)
rate = 44100

def write_wav(filename: str, samples: list, sample_rate: int = rate):
    filepath = root / filename
    with wave.open(str(filepath), 'wb') as wav:
        wav.setparams((1, 2, sample_rate, 0, 'NONE', 'not compressed'))
        raw = bytearray()
        for s in samples:
            val = max(-32767, min(32767, round(s * 32767)))
            raw.extend(struct.pack('<h', val))
        wav.writeframes(raw)
    print(f"Generated {filename}: {len(samples)} samples ({len(samples)/sample_rate:.2f}s)")

# Seed for reproducible synthesis
rng = random.Random(42)

# 1. Player Engine Sound: 1.0s seamless loop, 30 Hz fundamental (15 Hz camshaft)
# Exactly 30 integer cycles ensures seamless periodic continuity at boundaries
engine_duration = 1.0
engine_samples = []
N_eng = round(engine_duration * rate)
for i in range(N_eng):
    t = i / rate
    # Firing pulses at 30 Hz (idle 900 RPM 4-cyl), harmonics at 60, 90, 120, 150, 180, 240, 300, 360 Hz
    f0 = 30.0
    cam = math.sin(t * math.tau * 15.0) # Camshaft alternate cylinder pulse
    p1 = math.sin(t * math.tau * f0) * 0.32
    p2 = math.sin(t * math.tau * f0 * 2) * 0.22
    p3 = math.sin(t * math.tau * f0 * 3) * 0.14
    p4 = math.sin(t * math.tau * f0 * 4) * 0.10
    p5 = math.sin(t * math.tau * f0 * 5) * 0.07
    p6 = math.sin(t * math.tau * f0 * 6) * 0.05
    p8 = math.sin(t * math.tau * f0 * 8) * 0.03
    # Intake rasp & combustion rumble
    rumble = (p1 + p2 + p3 + p4 + p5 + p6 + p8) * (0.82 + 0.18 * cam)
    # Subtle cylinder compression pop
    pop = math.sin(t * math.tau * f0 * 2) ** 3 * 0.08
    val = (rumble + pop) * 0.85
    engine_samples.append(val)
write_wav('engine.wav', engine_samples)

# 2. Tire Roll Sound: 1.0s seamless asphalt rolling texture
roll_samples = []
N_roll = round(1.0 * rate)
# Filtered noise texture: brownian walk + low-pass filter
noise_state = 0.0
raw_noise = []
for i in range(N_roll):
    white = rng.uniform(-1.0, 1.0)
    noise_state = noise_state * 0.92 + white * 0.08
    raw_noise.append(noise_state)
# Seamless crossfade at loop boundary (first/last 2000 samples)
fade_len = 2000
for i in range(N_roll):
    val = raw_noise[i]
    if i < fade_len:
        factor = i / fade_len
        val = raw_noise[i] * factor + raw_noise[N_roll - fade_len + i] * (1.0 - factor)
    elif i >= N_roll - fade_len:
        factor = (N_roll - 1 - i) / fade_len
        val = raw_noise[i] * factor + raw_noise[i - (N_roll - fade_len)] * (1.0 - factor)
    # Add subtle low-frequency chassis road rumble
    t = i / rate
    road_vibe = math.sin(t * math.tau * 78.0) * 0.04 + math.sin(t * math.tau * 132.0) * 0.02
    roll_samples.append((val * 0.8 + road_vibe) * 0.45)
write_wav('tire_roll.wav', roll_samples)

# 3. Tire Skid / Screech Sound: 1.0s seamless loop of rubber friction squeal
skid_samples = []
N_skid = round(1.0 * rate)
for i in range(N_skid):
    t = i / rate
    # Frequency modulated squeal around 920 Hz and 1380 Hz
    mod = math.sin(t * math.tau * 37.0) * 45.0
    s1 = math.sin(t * math.tau * (920.0 + mod)) * 0.28
    s2 = math.sin(t * math.tau * (1380.0 + mod * 0.7)) * 0.18
    s3 = math.sin(t * math.tau * (1840.0 - mod * 0.5)) * 0.09
    # Add high-frequency friction hiss
    hiss = rng.uniform(-0.12, 0.12)
    skid_samples.append((s1 + s2 + s3 + hiss) * 0.65)
# Crossfade boundary
for i in range(fade_len):
    factor = i / fade_len
    skid_samples[i] = skid_samples[i] * factor + skid_samples[N_skid - fade_len + i] * (1.0 - factor)
for i in range(N_skid - fade_len, N_skid):
    factor = (N_skid - 1 - i) / fade_len
    skid_samples[i] = skid_samples[i] * factor + skid_samples[i - (N_skid - fade_len)] * (1.0 - factor)
write_wav('tire_skid.wav', skid_samples)

# 4. Player Horn: 0.65s dual-tone car horn (415 Hz and 495 Hz with harmonic richness)
horn_duration = 0.65
horn_samples = []
N_horn = round(horn_duration * rate)
for i in range(N_horn):
    t = i / rate
    # Envelope: 20ms attack, smooth sustain, 45ms release
    env = min(1.0, t / 0.02, (horn_duration - t) / 0.045)
    f1, f2 = 415.0, 495.0
    h = (math.sin(t * math.tau * f1) * 0.4 +
         math.sin(t * math.tau * f1 * 2) * 0.15 +
         math.sin(t * math.tau * f1 * 3) * 0.08 +
         math.sin(t * math.tau * f2) * 0.35 +
         math.sin(t * math.tau * f2 * 2) * 0.12 +
         math.sin(t * math.tau * f2 * 3) * 0.06)
    horn_samples.append(h * env * 0.55)
write_wav('horn.wav', horn_samples)

# 5. Collision Impact: 0.4s punchy thud with body crunch
impact_duration = 0.40
impact_samples = []
N_imp = round(impact_duration * rate)
for i in range(N_imp):
    t = i / rate
    # Low-end shockwave decaying at exp(-t*18)
    decay_sub = math.exp(-t * 22.0)
    sub = math.sin(t * math.tau * 68.0) * decay_sub * 0.65
    sub += math.sin(t * math.tau * 110.0) * math.exp(-t * 30.0) * 0.35
    # Crunch noise decaying rapidly
    crunch = rng.uniform(-1.0, 1.0) * math.exp(-t * 40.0) * 0.35
    impact_samples.append(sub + crunch)
write_wav('impact.wav', impact_samples)

# 6. Traffic CNG Engine: 1.0s seamless loop, 45 Hz 200cc single cylinder putter
cng_samples = []
N_cng = round(1.0 * rate)
for i in range(N_cng):
    t = i / rate
    f0 = 45.0
    # Sharp exhaust pop
    phase = (t * f0) % 1.0
    pop = math.exp(-phase * 14.0) * 0.5 - 0.1
    # Metallic ringing body resonance
    ring = math.sin(t * math.tau * 360.0) * 0.12 + math.sin(t * math.tau * 540.0) * 0.08
    val = (pop + ring) * 0.6
    cng_samples.append(val)
# Crossfade boundary
for i in range(fade_len):
    factor = i / fade_len
    cng_samples[i] = cng_samples[i] * factor + cng_samples[N_cng - fade_len + i] * (1.0 - factor)
for i in range(N_cng - fade_len, N_cng):
    factor = (N_cng - 1 - i) / fade_len
    cng_samples[i] = cng_samples[i] * factor + cng_samples[i - (N_cng - fade_len)] * (1.0 - factor)
write_wav('traffic_cng.wav', cng_samples)

# 7. Traffic Bus Engine: 1.0s seamless loop, 25 Hz heavy diesel rumble
bus_samples = []
N_bus = round(1.0 * rate)
for i in range(N_bus):
    t = i / rate
    f0 = 25.0
    chug = (math.sin(t * math.tau * f0) * 0.4 +
            math.sin(t * math.tau * f0 * 2) * 0.28 +
            math.sin(t * math.tau * f0 * 3) * 0.18 +
            math.sin(t * math.tau * f0 * 4) * 0.12 +
            math.sin(t * math.tau * f0 * 6) * 0.08)
    # Diesel knock pulse
    phase = (t * f0) % 1.0
    knock = math.exp(-phase * 8.0) * 0.22 - 0.05
    turbo = math.sin(t * math.tau * 850.0) * 0.03 # subtle turbo whine
    bus_samples.append((chug + knock + turbo) * 0.65)
for i in range(fade_len):
    factor = i / fade_len
    bus_samples[i] = bus_samples[i] * factor + bus_samples[N_bus - fade_len + i] * (1.0 - factor)
for i in range(N_bus - fade_len, N_bus):
    factor = (N_bus - 1 - i) / fade_len
    bus_samples[i] = bus_samples[i] * factor + bus_samples[i - (N_bus - fade_len)] * (1.0 - factor)
write_wav('traffic_bus.wav', bus_samples)

# 8. Traffic Horn: 0.35s short staccato chirp (640 Hz + 820 Hz)
tr_horn_duration = 0.35
tr_horn_samples = []
N_tr_horn = round(tr_horn_duration * rate)
for i in range(N_tr_horn):
    t = i / rate
    env = min(1.0, t / 0.012, (tr_horn_duration - t) / 0.03)
    tone = (math.sin(t * math.tau * 640.0) * 0.45 +
            math.sin(t * math.tau * 820.0) * 0.35 +
            math.sin(t * math.tau * 1280.0) * 0.12)
    tr_horn_samples.append(tone * env * 0.45)
write_wav('traffic_horn.wav', tr_horn_samples)

# 9. Ambient City Soundscape: 3.0s seamless wide city bed
amb_duration = 3.0
amb_samples = []
N_amb = round(amb_duration * rate)
# Filtered low noise bed
amb_state = 0.0
raw_amb = []
for i in range(N_amb):
    w = rng.uniform(-1.0, 1.0)
    amb_state = amb_state * 0.96 + w * 0.04
    raw_amb.append(amb_state)
for i in range(N_amb):
    t = i / rate
    low_drone = math.sin(t * math.tau * 52.0) * 0.06 + math.sin(t * math.tau * 88.0) * 0.03
    val = raw_amb[i] * 0.5 + low_drone
    amb_samples.append(val * 0.35)
for i in range(fade_len * 2):
    fl = fade_len * 2
    factor = i / fl
    amb_samples[i] = amb_samples[i] * factor + amb_samples[N_amb - fl + i] * (1.0 - factor)
for i in range(N_amb - fade_len * 2, N_amb):
    fl = fade_len * 2
    factor = (N_amb - 1 - i) / fl
    amb_samples[i] = amb_samples[i] * factor + amb_samples[i - (N_amb - fl)] * (1.0 - factor)
write_wav('ambience.wav', amb_samples)

# 10. Radio / Dispatch Chime: 0.18s two-tone alert chirp (880 Hz -> 1320 Hz)
chime_duration = 0.18
chime_samples = []
N_chime = round(chime_duration * rate)
for i in range(N_chime):
    t = i / rate
    if t < 0.07:
        # First chirp: 880 Hz with quick envelope
        env = math.sin(t / 0.07 * math.pi) * 0.4
        val = math.sin(t * math.tau * 880.0) * env
    else:
        # Second chirp: 1320 Hz with exponential decay
        t2 = t - 0.07
        env = math.exp(-t2 * 25.0) * 0.45
        val = (math.sin(t2 * math.tau * 1320.0) + 0.2 * math.sin(t2 * math.tau * 2640.0)) * env
    chime_samples.append(val)
write_wav('radio_chime.wav', chime_samples)

# 11. Monsoon Rainfall Loop: 2.0s seamless loop of tropical downpour
rain_duration = 2.0
rain_samples = []
N_rain = round(rain_duration * rate)
rain_noise_state = 0.0
raw_rain = []
for i in range(N_rain):
    w = rng.uniform(-1.0, 1.0)
    rain_noise_state = rain_noise_state * 0.88 + w * 0.12
    droplet = rng.uniform(-0.15, 0.15) if rng.random() < 0.04 else 0.0
    raw_rain.append(rain_noise_state * 0.45 + droplet)

for i in range(N_rain):
    t = i / rate
    thunder = (math.sin(t * math.tau * 38.0) * 0.04 +
               math.sin(t * math.tau * 62.0) * 0.025)
    val = raw_rain[i] + thunder
    rain_samples.append(val * 0.55)

fade_len_rain = 3000
for i in range(fade_len_rain):
    factor = i / fade_len_rain
    rain_samples[i] = rain_samples[i] * factor + rain_samples[N_rain - fade_len_rain + i] * (1.0 - factor)
for i in range(N_rain - fade_len_rain, N_rain):
    factor = (N_rain - 1 - i) / fade_len_rain
    rain_samples[i] = rain_samples[i] * factor + rain_samples[i - (N_rain - fade_len_rain)] * (1.0 - factor)
write_wav('rain_loop.wav', rain_samples)

# 12. Windshield Wiper Sweep: 0.55s mechanical servo swipe with rubber blade friction
wiper_duration = 0.55
wiper_samples = []
N_wiper = round(wiper_duration * rate)
for i in range(N_wiper):
    t = i / rate
    env = math.sin(t / wiper_duration * math.pi) ** 1.8
    sweep_pitch = 140.0 + math.sin(t / wiper_duration * math.pi) * 100.0
    motor = math.sin(t * math.tau * sweep_pitch) * 0.25
    rubber = rng.uniform(-0.18, 0.18) * (0.5 + 0.5 * math.sin(t * math.tau * 420.0))
    val = (motor + rubber) * env * 0.5
    wiper_samples.append(val)
write_wav('wiper_sweep.wav', wiper_samples)

# 13. Tire Water Spray / Puddle Splash: 0.35s hydrodynamic displacement sound
splash_duration = 0.35
splash_samples = []
N_splash = round(splash_duration * rate)
for i in range(N_splash):
    t = i / rate
    env = math.exp(-t * 14.0) - math.exp(-t * 60.0)
    sub = math.sin(t * math.tau * max(40.0, 120.0 - t * 160.0)) * 0.35
    spray = rng.uniform(-0.4, 0.4) * math.exp(-t * 16.0)
    val = (sub + spray) * env * 0.7
    splash_samples.append(val)
write_wav('water_splash.wav', splash_samples)

# 14. Rickshaw Bell (টুং টুং!): 0.8s double metal chime sequence
bell_duration = 0.8
bell_samples = []
N_bell = round(bell_duration * rate)
strike_times = [0.04, 0.22] # Dual strike "tung tung"
for i in range(N_bell):
    t = i / rate
    sample_val = 0.0
    for st in strike_times:
        if t >= st:
            dt = t - st
            env = math.exp(-dt * 15.0)
            transient = math.exp(-dt * 85.0) * 0.4
            # Brass bell modal frequencies
            f0 = 2150.0
            f1 = 3420.0
            f2 = 4610.0
            f3 = 6450.0
            chime = (math.sin(dt * math.tau * f0) * 0.45 +
                     math.sin(dt * math.tau * f1) * 0.28 +
                     math.sin(dt * math.tau * f2) * 0.16 +
                     math.sin(dt * math.tau * f3) * 0.08)
            ping = math.sin(dt * math.tau * 7800.0) * transient
            sample_val += (chime * env + ping) * 0.55
    bell_samples.append(sample_val)
write_wav('rickshaw_bell.wav', bell_samples)

# 15. Bus Conductor Route Call (ফার্মগেট! ডাইরেক্ট!): 1.4s vocal formant projection
conductor_duration = 1.4
conductor_samples = []
N_conductor = round(conductor_duration * rate)
for i in range(N_conductor):
    t = i / rate
    # Two vocal bursts: [0.08 to 0.55] ("Farmgate!") and [0.72 to 1.25] ("Direct!")
    env = 0.0
    pitch = 175.0
    if 0.08 <= t <= 0.55:
        sub_t = t - 0.08
        env = max(0.0, math.sin(sub_t / 0.47 * math.pi)) ** 1.5
        pitch = 170.0 + math.sin(sub_t / 0.47 * math.pi) * 35.0
    elif 0.72 <= t <= 1.25:
        sub_t = t - 0.72
        env = max(0.0, math.sin(sub_t / 0.53 * math.pi)) ** 1.3
        pitch = 185.0 + math.sin(sub_t / 0.53 * math.pi) * 20.0 - sub_t * 25.0
    
    # Vocal cord pulse with formant resonators
    pulse = math.sin(t * math.tau * pitch) + 0.5 * math.sin(t * math.tau * pitch * 2)
    f1 = math.sin(t * math.tau * 680.0) * 0.35 # Vowel formant F1
    f2 = math.sin(t * math.tau * 1350.0) * 0.25 # Formant F2
    f3 = math.sin(t * math.tau * 2450.0) * 0.15 # Formant F3
    rasp = rng.uniform(-0.1, 0.1) * env # Vocal friction
    val = (pulse * 0.4 + f1 + f2 + f3 + rasp) * env * 0.45
    conductor_samples.append(float(val))
write_wav('conductor_call.wav', conductor_samples)

# 16. Tong er Dokan Tea Stall Foley (টং এর চায়ের কেতলি): 1.2s seamless loop
tea_duration = 1.2
tea_samples = []
N_tea = round(tea_duration * rate)
tea_noise_state = 0.0
raw_tea = []
for i in range(N_tea):
    w = rng.uniform(-1.0, 1.0)
    tea_noise_state = tea_noise_state * 0.78 + w * 0.22 # Bandpass steam texture
    raw_tea.append(tea_noise_state)

for i in range(N_tea):
    t = i / rate
    # Steam hiss and water boiling bubble
    steam = raw_tea[i] * 0.18 * (0.85 + 0.15 * math.sin(t * math.tau * 7.5))
    bubble = math.sin(t * math.tau * (145.0 + math.sin(t * math.tau * 18.0) * 30.0)) * 0.08
    # Subtle spoon clink against glass at t=0.38 and t=0.88
    clink = 0.0
    for ct in [0.38, 0.88]:
        if ct <= t < ct + 0.12:
            dt = t - ct
            clink += math.sin(dt * math.tau * 3650.0) * math.exp(-dt * 35.0) * 0.12
    val = steam + bubble + clink
    tea_samples.append(float(val * 0.6))

fade_len_tea = 2000
for i in range(fade_len_tea):
    factor = i / fade_len_tea
    tea_samples[i] = tea_samples[i] * factor + tea_samples[N_tea - fade_len_tea + i] * (1.0 - factor)
for i in range(N_tea - fade_len_tea, N_tea):
    factor = (N_tea - 1 - i) / fade_len_tea
    tea_samples[i] = tea_samples[i] * factor + tea_samples[i - (N_tea - fade_len_tea)] * (1.0 - factor)
write_wav('tea_stall.wav', tea_samples)

# 17. Fruit / Coconut Hawker Call (তাজা ডাব! ফল!): 1.1s melodic street call
hawker_duration = 1.1
hawker_samples = []
N_hawker = round(hawker_duration * rate)
for i in range(N_hawker):
    t = i / rate
    env = 0.0
    pitch = 220.0
    if 0.06 <= t <= 0.48:
        sub_t = t - 0.06
        env = max(0.0, math.sin(sub_t / 0.42 * math.pi)) ** 1.4
        pitch = 225.0 + math.sin(sub_t / 0.42 * math.pi) * 30.0
    elif 0.58 <= t <= 1.02:
        sub_t = t - 0.58
        env = max(0.0, math.sin(sub_t / 0.44 * math.pi)) ** 1.3
        pitch = 245.0 - (sub_t / 0.44) * 45.0 # Melodic falling cadence
    pulse = math.sin(t * math.tau * pitch) * 0.35
    f1 = math.sin(t * math.tau * 720.0) * 0.30
    f2 = math.sin(t * math.tau * 1480.0) * 0.20
    val = (pulse + f1 + f2) * env * 0.45
    hawker_samples.append(float(val))
write_wav('hawker_call.wav', hawker_samples)

# 18. DMP Police Siren: 1.2s seamless loop wailing siren (650 Hz to 1250 Hz dual-tone)
siren_duration = 1.2
siren_samples = []
N_siren = round(siren_duration * rate)
for i in range(N_siren):
    t = i / rate
    # Fast wail cycle 2.0 Hz
    mod = math.sin(t * math.tau * 2.0)
    freq1 = 750.0 + mod * 400.0
    freq2 = 1100.0 + mod * 350.0
    tone1 = math.sin(t * math.tau * freq1) * 0.42
    tone2 = math.sin(t * math.tau * freq2) * 0.28
    tone_sq = math.copysign(1.0, math.sin(t * math.tau * freq1)) * 0.12 # Slight square-wave buzz
    val = (tone1 + tone2 + tone_sq) * 0.55
    siren_samples.append(float(val))

fade_len_siren = 1000
for i in range(fade_len_siren):
    factor = i / fade_len_siren
    siren_samples[i] = siren_samples[i] * factor + siren_samples[N_siren - fade_len_siren + i] * (1.0 - factor)
for i in range(N_siren - fade_len_siren, N_siren):
    factor = (N_siren - 1 - i) / fade_len_siren
    siren_samples[i] = siren_samples[i] * factor + siren_samples[i - (N_siren - fade_len_siren)] * (1.0 - factor)
write_wav('police_siren.wav', siren_samples)

# 19. Metal Barrier Scrape & Sparks: 0.8s abrasive scraping screech against concrete
scrape_duration = 0.8
scrape_samples = []
N_scrape = round(scrape_duration * rate)
scrape_noise_state = 0.0
for i in range(N_scrape):
    t = i / rate
    w = rng.uniform(-1.0, 1.0)
    scrape_noise_state = scrape_noise_state * 0.65 + w * 0.35
    screech = math.sin(t * math.tau * (2400.0 + math.sin(t * math.tau * 85.0) * 800.0)) * 0.25
    grit = scrape_noise_state * 0.35
    spark_snap = (rng.uniform(-1.0, 1.0) ** 5) * 0.20
    val = (screech + grit + spark_snap) * 0.65
    scrape_samples.append(float(val))

fade_len_scrape = 1000
for i in range(fade_len_scrape):
    factor = i / fade_len_scrape
    scrape_samples[i] = scrape_samples[i] * factor + scrape_samples[N_scrape - fade_len_scrape + i] * (1.0 - factor)
for i in range(N_scrape - fade_len_scrape, N_scrape):
    factor = (N_scrape - 1 - i) / fade_len_scrape
    scrape_samples[i] = scrape_samples[i] * factor + scrape_samples[i - (N_scrape - fade_len_scrape)] * (1.0 - factor)
write_wav('metal_scrape.wav', scrape_samples)

# 20. Radiator Steam Hiss: 1.0s continuous boiling engine steam leak
steam_duration = 1.0
steam_samples = []
N_steam = round(steam_duration * rate)
steam_noise = 0.0
for i in range(N_steam):
    t = i / rate
    w = rng.uniform(-1.0, 1.0)
    steam_noise = steam_noise * 0.82 + w * 0.18
    whistle = math.sin(t * math.tau * 3200.0) * 0.08 * (0.8 + 0.2 * math.sin(t * math.tau * 12.0))
    val = (steam_noise * 0.35 + whistle) * 0.60
    steam_samples.append(float(val))

fade_len_steam = 1000
for i in range(fade_len_steam):
    factor = i / fade_len_steam
    steam_samples[i] = steam_samples[i] * factor + steam_samples[N_steam - fade_len_steam + i] * (1.0 - factor)
for i in range(N_steam - fade_len_steam, N_steam):
    factor = (N_steam - 1 - i) / fade_len_steam
    steam_samples[i] = steam_samples[i] * factor + steam_samples[i - (N_steam - fade_len_steam)] * (1.0 - factor)
write_wav('radiator_steam.wav', steam_samples)

print('All synthetic audio assets generated successfully.')
