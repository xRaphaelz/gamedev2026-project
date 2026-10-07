"""เพลงประกอบรุ่นใหม่: เครื่องดนตรีสังเคราะห์ที่นุ่มขึ้น (สายดีด Karplus-Strong, มาริมบา, เปียโนไฟฟ้า, แคน)
+ reverb + สเตอริโอ  มี 3 สไตล์:  cozy (เกมทำอาหารน่ารัก), molam (หมอลำ/ลูกทุ่งสนุก), lofi (ชิล)
รัน: python3 tools/audio/music2.py preview  -> ทำไฟล์ตัวอย่างสไตล์ละ 1 เพลง
     python3 tools/audio/music2.py set cozy -> ทำชุดเพลงทั้งเกม (menu/game/calm/happy/sad) ด้วยสไตล์ที่เลือก
"""
import os
import subprocess
import sys
import wave

import numpy as np
from scipy.signal import lfilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
MUS = os.path.join(ROOT, "assets", "audio", "music")
SR = 44100
rng = np.random.default_rng(11)


def hz(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def tt(d):
    return np.arange(int(SR * d)) / SR


def adsr(n, a=0.005, d=0.1, s=0.6, r=0.1, hold=None):
    t = np.arange(n) / SR
    hold = (n / SR - r) if hold is None else hold
    e = np.where(t < a, t / max(a, 1e-4), 0.0)
    dec = (t >= a) & (t < a + d)
    e[dec] = 1 - (1 - s) * (t[dec] - a) / d
    e[(t >= a + d) & (t < hold)] = s
    rel = t >= hold
    e[rel] = s * np.maximum(0, 1 - (t[rel] - hold) / max(r, 1e-4))
    return e


def lp(x, fc):
    a = np.exp(-2 * np.pi * fc / SR)
    return lfilter([1 - a], [1, -a], x)


# ---------------- เครื่องดนตรี ----------------

def pluck(f, dur, bright=0.6, decay=0.996, amp=1.0):
    """สายดีด (อูคูเลเล่/พิณ) แบบ Karplus-Strong"""
    n = int(SR * dur)
    N = max(2, int(SR / f))
    exc = np.zeros(n)
    burst = rng.uniform(-1, 1, N)
    burst = lp(burst, 1500 + 6000 * bright)
    exc[:N] = burst
    a = np.zeros(N + 2)
    a[0] = 1
    a[N] = -0.5 * decay
    a[N + 1] = -0.5 * decay
    y = lfilter([1.0], a, exc)
    fade = np.minimum(1, (n - np.arange(n)) / (0.03 * SR))
    return y * fade * amp


def marimba(f, dur=0.6, amp=1.0):
    t = tt(dur)
    n = len(t)
    x = np.sin(2 * np.pi * f * t) * np.exp(-t * 6) + 0.25 * np.sin(2 * np.pi * f * 4 * t) * np.exp(-t * 25)
    x += 0.08 * np.sin(2 * np.pi * f * 9.9 * t) * np.exp(-t * 60)
    x[: int(0.002 * SR)] *= np.linspace(0, 1, int(0.002 * SR))
    return x * amp


def epiano(f, dur, amp=1.0):
    """เปียโนไฟฟ้า (FM แบบ Rhodes)"""
    t = tt(dur)
    idx = 1.2 * np.exp(-t * 4)
    mod = np.sin(2 * np.pi * f * t) * idx
    x = np.sin(2 * np.pi * f * t + mod) + 0.15 * np.sin(2 * np.pi * f * 14 * t) * np.exp(-t * 30)
    return x * adsr(len(t), 0.004, 0.6, 0.35, 0.25) * amp


def khaen(f, dur, amp=1.0):
    """แคน: เสียงลิ้นหลายฮาร์โมนิก + สั่นเบา ๆ"""
    t = tt(dur)
    vib = 1 + 0.003 * np.sin(2 * np.pi * 5.5 * t)
    ph = 2 * np.pi * np.cumsum(f * vib) / SR
    x = sum((1.0 / k) * (0.7 if k % 2 == 0 else 1.0) * np.sin(k * ph) for k in range(1, 9))
    x *= 1 + 0.12 * np.sin(2 * np.pi * 6 * t)
    return lp(x, 2600) * adsr(len(t), 0.06, 0.1, 0.85, 0.12) * amp


def bass(f, dur, amp=1.0):
    t = tt(dur)
    x = np.sin(2 * np.pi * f * t) + 0.25 * np.sin(2 * np.pi * 2 * f * t)
    x = np.tanh(1.5 * x)
    return x * adsr(len(t), 0.005, 0.15, 0.6, 0.06) * amp


def kick(amp=1.0):
    t = tt(0.35)
    f = 50 + 110 * np.exp(-t * 35)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 9) * amp


def snare(amp=1.0, soft=False):
    t = tt(0.25)
    nz = rng.uniform(-1, 1, len(t))
    nz = nz - lp(nz, 1200)
    x = nz * np.exp(-t * (28 if soft else 20)) + 0.4 * np.sin(2 * np.pi * 190 * t) * np.exp(-t * 25)
    return x * amp


def hat(amp=1.0, open_=False):
    t = tt(0.25 if open_ else 0.06)
    nz = rng.uniform(-1, 1, len(t))
    nz = nz - lp(nz, 7000)
    return nz * np.exp(-t * (12 if open_ else 80)) * amp


def shaker(amp=1.0):
    t = tt(0.09)
    nz = rng.uniform(-1, 1, len(t))
    nz = nz - lp(nz, 5000)
    return nz * np.sin(np.pi * np.linspace(0, 1, len(t))) * amp


def ching(amp=1.0, open_=True):
    t = tt(0.7 if open_ else 0.1)
    x = sum(np.sin(2 * np.pi * f * t) for f in (2960, 4470, 6100)) / 3
    return x * np.exp(-t * (5 if open_ else 50)) * amp


def clap(amp=1.0):
    t = tt(0.2)
    nz = rng.uniform(-1, 1, len(t))
    nz = lp(nz - lp(nz, 900), 4000)
    env = np.zeros(len(t))
    for off in (0, 0.01, 0.02):
        i = int(off * SR)
        env[i:] += np.exp(-(t[: len(t) - i]) * 40)
    return nz * env * 0.6 * amp


# ---------------- มิกซ์ ----------------

class Track:
    def __init__(self, seconds):
        self.L = np.zeros(int(SR * (seconds + 3)))
        self.R = np.zeros_like(self.L)
        self.length = int(SR * seconds)

    def add(self, x, at, pan=0.0, gain=1.0):
        i = int(at * SR)
        j = min(len(self.L), i + len(x))
        if i >= len(self.L):
            return
        l = np.cos((pan + 1) * np.pi / 4) * gain
        r = np.sin((pan + 1) * np.pi / 4) * gain
        self.L[i:j] += x[: j - i] * l
        self.R[i:j] += x[: j - i] * r


def reverb(x, wet=0.25, size=1.0):
    out = np.zeros_like(x)
    for d, g in ((1557, 0.84), (1617, 0.83), (1491, 0.85), (1422, 0.86)):
        D = int(d * size)
        a = np.zeros(D + 1)
        a[0] = 1
        a[D] = -g
        out += lfilter([1], a, x) * 0.25
    for d, g in ((225, 0.5), (556, 0.5)):
        b = np.zeros(d + 1)
        b[0] = -g
        b[d] = 1
        a = np.zeros(d + 1)
        a[0] = 1
        a[d] = -g
        out = lfilter(b, a, out)
    return x * (1 - wet) + lp(out, 5000) * wet


def render(track, path, wet=0.22):
    L = reverb(track.L, wet)
    R = reverb(track.R, wet, 1.07)
    # ทบหางเพลงกลับไปต้นเพลงให้วนต่อเนียน
    n = track.length
    for ch in (L, R):
        tail = ch[n:].copy()
        ch[: len(tail)] += tail
    L, R = L[:n], R[:n]
    peak = max(np.max(np.abs(L)), np.max(np.abs(R))) or 1
    L, R = np.tanh(L / peak * 1.1) * 0.9, np.tanh(R / peak * 1.1) * 0.9
    data = (np.stack([L, R], axis=1) * 32767).astype(np.int16)
    tmp = path + ".wav"
    with wave.open(tmp, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    if path.endswith(".mp3"):
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-b:a", "192k", path], check=True)
    else:
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", "5", path], check=True)
    os.remove(tmp)
    print("wrote", path)


# ---------------- ทฤษฎีเพลงเล็ก ๆ ----------------

MAJ = [0, 2, 4, 5, 7, 9, 11]
PENTA = [0, 2, 4, 7, 9]


def chord(root_midi, kind="maj"):
    iv = {"maj": [0, 4, 7], "min": [0, 3, 7], "maj7": [0, 4, 7, 11], "min7": [0, 3, 7, 10], "dom7": [0, 4, 7, 10]}[kind]
    return [root_midi + i for i in iv]


# ---------------- สไตล์ 1: cozy (เกมทำอาหารน่ารัก) ----------------

def cozy(bpm=124, bars=16, key=60, mood="game"):
    beat = 60 / bpm
    T = Track(bars * 4 * beat)
    prog = [(0, "maj"), (9, "min"), (5, "maj"), (7, "maj")]  # I vi IV V
    if mood == "sad":
        prog = [(9, "min"), (5, "maj"), (0, "maj"), (7, "maj")]
    # ทำนอง 2 ท่อน (A/B) เขียนเป็นตัวเลขขั้นสเกลเมเจอร์ (None = เว้น)
    A = [[4, None, 4, 5, 4, 2, 0, None], [2, None, 2, 4, 2, 0, -3, None], [3, None, 3, 4, 5, 4, 3, 2], [4, None, 6, 5, 4, None, None, None]]
    B = [[7, 6, 5, 4, 5, None, 4, 2], [0, 2, 4, None, 2, 0, -1, None], [3, 4, 5, 3, 7, 5, 4, 3], [4, 3, 2, 1, 0, None, None, None]]
    for bar in range(bars):
        t0 = bar * 4 * beat
        r, kind = prog[bar % 4]
        ch = chord(key - 12 + r, kind)
        # เบสเด้ง
        for k, off in enumerate((0, 1.5, 2, 3)):
            n = ch[0] - 12 if k != 2 else ch[2] - 12
            T.add(bass(hz(n), beat * 0.45, 0.55), t0 + off * beat, 0.0)
        # อูคูเลเล่ตีคอร์ด (จังหวะ ด-ด-ขึ้น-ลง)
        for off, vol in ((0, 0.7), (1, 0.45), (1.5, 0.35), (2, 0.6), (3, 0.45), (3.5, 0.35)):
            for i, m in enumerate(ch + [ch[0] + 12]):
                T.add(pluck(hz(m + 12), 0.5, 0.25, 0.994, vol * 0.16), t0 + off * beat + i * 0.012, -0.35)
        # กลองเบา ๆ
        if mood != "calm":
            T.add(kick(0.55), t0, 0)
            T.add(kick(0.45), t0 + 2 * beat, 0)
            T.add(snare(0.25, True), t0 + beat, 0.1)
            T.add(snare(0.25, True), t0 + 3 * beat, 0.1)
            for k in range(8):
                T.add(shaker(0.06 if k % 2 else 0.035), t0 + k * beat / 2, 0.4)
        # ทำนองมาริมบา
        phrase = (A if (bar // 4) % 2 == 0 else B)[bar % 4]
        for k, deg in enumerate(phrase):
            if deg is None:
                continue
            o, d = divmod(deg, 7)
            m = key + 12 + 12 * o + MAJ[d]
            T.add(marimba(hz(m), 0.6, 0.5), t0 + k * beat / 2, 0.25)
    return T


# ---------------- สไตล์ 2: molam (หมอลำ/ลูกทุ่งสนุก) ----------------

def molam(bpm=138, bars=16, key=57, mood="game"):
    beat = 60 / bpm
    T = Track(bars * 4 * beat)
    minor = [0, 3, 5, 7, 10]  # เพนทาโทนิกไมเนอร์ (ลายแคนแนวสุดสะแนน)
    riffs = [[0, 2, 3, 2, 0, 2, 4, 3], [4, 3, 2, 3, 4, 5, 4, 2], [0, 2, 3, 4, 5, 4, 3, 2], [3, 2, 0, -1, 0, None, 0, None]]
    for bar in range(bars):
        t0 = bar * 4 * beat
        # แคนเสียงประสาน (โดรน)
        if bar % 2 == 0:
            for m, g in ((key, 0.12), (key + 7, 0.1), (key + 12, 0.07)):
                T.add(khaen(hz(m), 8 * beat, g), t0, 0.3)
        # เบสสลับ
        for k in range(4):
            n = key - 24 if k % 2 == 0 else key - 17
            T.add(bass(hz(n), beat * 0.4, 0.6), t0 + k * beat, 0)
        # กลอง + ฉิ่งฉับ
        if mood != "calm":
            for k in range(4):
                T.add(kick(0.6), t0 + k * beat, 0)
                T.add(ching(0.12, open_=(k % 2 == 0)), t0 + k * beat + beat / 2, -0.4)
            T.add(clap(0.35), t0 + beat, 0.2)
            T.add(clap(0.35), t0 + 3 * beat, 0.2)
            for k in range(8):
                T.add(hat(0.06), t0 + k * beat / 2 + beat / 4, 0.5)
        # พิณ (สายดีด) เล่นลาย
        riff = riffs[bar % 4]
        for k, deg in enumerate(riff):
            if deg is None:
                continue
            o, d = divmod(deg, 5)
            m = key + 12 + 12 * o + minor[d]
            T.add(pluck(hz(m), 0.45, 0.85, 0.994, 0.45), t0 + k * beat / 2, -0.2)
            if k % 2 == 1:
                T.add(pluck(hz(m), 0.3, 0.85, 0.99, 0.2), t0 + k * beat / 2 + beat / 4, -0.2)
    return T


# ---------------- สไตล์ 3: lofi (ชิล) ----------------

def lofi(bpm=84, bars=8, key=62, mood="game"):
    beat = 60 / bpm
    T = Track(bars * 4 * beat)
    prog = [(0, "maj7"), (9, "min7"), (2, "min7"), (7, "dom7")]
    if mood == "sad":
        prog = [(9, "min7"), (5, "maj7"), (2, "min7"), (4, "min7")]
    mel = [[7, None, 9, 7, 4, None, None, None], [5, None, 4, 2, 0, None, 2, None],
           [4, None, 5, 4, 2, 4, 5, None], [7, 6, 4, None, 2, None, None, None]]
    for bar in range(bars):
        t0 = bar * 4 * beat
        r, kind = prog[bar % 4]
        ch = chord(key - 12 + r, kind)
        for i, m in enumerate(ch):
            T.add(epiano(hz(m), 4 * beat, 0.22), t0 + i * 0.02, -0.2 + 0.15 * i)
        T.add(bass(hz(ch[0] - 12), beat * 1.8, 0.5), t0, 0)
        T.add(bass(hz(ch[0] - 12), beat * 1.2, 0.4), t0 + 2.5 * beat, 0)
        if mood != "calm":
            # กลองสวิง
            T.add(kick(0.6), t0, 0)
            T.add(kick(0.45), t0 + 2.6 * beat, 0)
            T.add(snare(0.35, True), t0 + beat, 0)
            T.add(snare(0.35, True), t0 + 3 * beat, 0)
            for k in range(8):
                sw = 0.08 * beat if k % 2 else 0
                T.add(hat(0.07 if k % 2 else 0.1), t0 + k * beat / 2 + sw, 0.3)
        for k, deg in enumerate(mel[bar % 4]):
            if deg is None:
                continue
            o, d = divmod(deg, 7)
            m = key + 12 * o + MAJ[d]
            T.add(pluck(hz(m + 12), 0.9, 0.35, 0.997, 0.35), t0 + k * beat / 2, 0.3)
    # เสียงแผ่นเสียงเบา ๆ
    n = len(T.L)
    crackle = (rng.random(n) > 0.9993) * rng.uniform(-0.3, 0.3, n)
    T.L += lp(crackle, 3000) * 0.5
    T.R += lp(np.roll(crackle, 300), 3000) * 0.5
    return T


STYLES = {"cozy": cozy, "molam": molam, "lofi": lofi}


def build_set(style):
    f = STYLES[style]
    os.makedirs(MUS, exist_ok=True)
    render(f(mood="game"), f"{MUS}/game.ogg")
    render(f(bpm=None or {"cozy": 104, "molam": 116, "lofi": 76}[style], mood="game"), f"{MUS}/menu.ogg")
    render(f(bpm={"cozy": 96, "molam": 100, "lofi": 70}[style], mood="calm"), f"{MUS}/calm.ogg", 0.3)
    render(f(bpm={"cozy": 136, "molam": 150, "lofi": 92}[style], mood="game"), f"{MUS}/happy.ogg")
    render(f(bpm={"cozy": 80, "molam": 84, "lofi": 64}[style], mood="sad"), f"{MUS}/sad.ogg", 0.35)


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "preview"
    if cmd == "preview":
        out = sys.argv[2] if len(sys.argv) > 2 else "."
        for name, f in STYLES.items():
            render(f(), os.path.join(out, f"music_option_{name}.mp3"))
    elif cmd == "set":
        build_set(sys.argv[2])
