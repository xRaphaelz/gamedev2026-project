"""สังเคราะห์เสียงประกอบและเพลงทั้งหมดของเกม (ไม่ใช้ไฟล์เสียงจากที่อื่น)
รัน: python3 tools/audio/make_audio.py   (ต้องมี numpy และ ffmpeg สำหรับแปลงเพลงเป็น .ogg)
"""
import os
import subprocess
import wave

import numpy as np
from scipy.signal import lfilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SFX = os.path.join(ROOT, "assets", "audio", "sfx")
MUS = os.path.join(ROOT, "assets", "audio", "music")
SR = 44100
rng = np.random.default_rng(3)


def t_(dur):
    return np.arange(int(SR * dur)) / SR


def env(n, a=0.005, d=0.2, curve=4.0):
    """envelope: attack เชิงเส้น + decay แบบ exponential"""
    t = np.arange(n) / SR
    e = np.exp(-t / max(d, 1e-4) * (curve / 4.0))
    na = max(1, int(a * SR))
    e[:na] *= np.linspace(0, 1, na)
    return e


def noise(n):
    return rng.uniform(-1, 1, n)


def lowpass(x, cutoff):
    # one-pole low-pass
    a = np.exp(-2 * np.pi * cutoff / SR)
    return lfilter([1 - a], [1, -a], x)


def highpass(x, cutoff):
    return x - lowpass(x, cutoff)


def note_hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def save_wav(path, x, sr=SR):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    x = np.asarray(x, dtype=np.float64)
    peak = np.max(np.abs(x)) or 1.0
    x = x / peak * 0.89
    data = (x * 32767).astype(np.int16)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(data.tobytes())


def save_ogg(path, x, stereo_width=0.0):
    tmp = path.replace(".ogg", ".tmp.wav")
    save_wav(tmp, x)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", "4", path], check=True)
    os.remove(tmp)


# ---------------- เครื่องดนตรี ----------------

def ranat(freq, dur=0.45, amp=1.0):
    """ระนาด: ไม้ตี มี partial ไม่ฮาร์โมนิก เสียงสั้น"""
    t = t_(dur)
    n = len(t)
    x = (np.sin(2 * np.pi * freq * t) * env(n, 0.002, 0.18)
         + 0.5 * np.sin(2 * np.pi * freq * 3.93 * t) * env(n, 0.001, 0.05)
         + 0.25 * np.sin(2 * np.pi * freq * 9.2 * t) * env(n, 0.001, 0.02))
    x += 0.15 * noise(n) * env(n, 0.0005, 0.006)
    return x * amp


def khaen(freq, dur, amp=1.0):
    """แคน: เสียงลิ้นโลหะ ใช้ sawtooth กรองนุ่ม + vibrato"""
    t = t_(dur)
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5.2 * t)
    ph = np.cumsum(freq * vib / SR)
    saw = 2 * (ph % 1.0) - 1
    x = lowpass(saw, 1800) + 0.3 * np.sin(2 * np.pi * ph)
    e = np.minimum(1, t / 0.08) * np.minimum(1, (dur - t) / 0.15)
    return x * e * amp


def bass(freq, dur=0.4, amp=1.0):
    t = t_(dur)
    x = np.sin(2 * np.pi * freq * t) + 0.3 * np.sin(2 * np.pi * freq * 2 * t)
    return x * env(len(t), 0.004, 0.25) * amp


def ching(open_=True, amp=1.0):
    """ฉิ่ง: โลหะเสียงแหลม (open = ฉิ่ง ยาว / closed = ฉับ สั้น)"""
    dur = 0.6 if open_ else 0.08
    t = t_(dur)
    n = len(t)
    x = sum(np.sin(2 * np.pi * f * t) for f in (3150, 4720, 6830, 8120)) / 4
    x = x * env(n, 0.001, 0.35 if open_ else 0.03) + 0.4 * highpass(noise(n), 5000) * env(n, 0.001, 0.02)
    return x * amp


def drum(amp=1.0, pitch=110):
    t = t_(0.35)
    f = pitch * (1 + 1.5 * np.exp(-t * 30))
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * env(len(t), 0.001, 0.15)
    x += 0.2 * lowpass(noise(len(t)), 1500) * env(len(t), 0.001, 0.02)
    return x * amp


def mix_into(buf, x, at):
    i = int(at * SR)
    j = min(len(buf), i + len(x))
    if i < len(buf):
        buf[i:j] += x[: j - i]


# ---------------- เสียงประกอบ ----------------

def make_sfx():
    n = int(SR * 0.3)
    # ตำ: เสียงทุ้มกระแทก + ไม้กระทบดินเผา
    t = t_(0.3)
    thud = np.sin(2 * np.pi * np.cumsum(70 + 120 * np.exp(-t * 40)) / SR) * env(len(t), 0.001, 0.08)
    knock = lowpass(noise(len(t)), 2500) * env(len(t), 0.0005, 0.015)
    save_wav(f"{SFX}/pound.wav", thud + 0.6 * knock)
    # หั่น: มีดกระทบเขียง
    t = t_(0.15)
    chop = highpass(noise(len(t)), 1500) * env(len(t), 0.0005, 0.012) + 0.5 * np.sin(2 * np.pi * 520 * t) * env(len(t), 0.001, 0.03)
    save_wav(f"{SFX}/chop.wav", chop)
    # หยิบ: ป๊อป
    t = t_(0.09)
    save_wav(f"{SFX}/pickup.wav", np.sin(2 * np.pi * np.cumsum(np.linspace(450, 950, len(t))) / SR) * env(len(t), 0.002, 0.04))
    # วาง: เคาะไม้
    t = t_(0.12)
    save_wav(f"{SFX}/place.wav", np.sin(2 * np.pi * 260 * t) * env(len(t), 0.001, 0.03) + 0.4 * lowpass(noise(len(t)), 3000) * env(len(t), 0.0005, 0.01))
    # จาน: กระเบื้องกระทบ
    t = t_(0.4)
    clink = sum(np.sin(2 * np.pi * f * t) * env(len(t), 0.0005, d) for f, d in ((2150, 0.12), (3390, 0.08), (5070, 0.05)))
    save_wav(f"{SFX}/plate.wav", clink)
    # เสิร์ฟ: กระดิ่ง
    t = t_(1.0)
    bell = sum(a * np.sin(2 * np.pi * 1320 * r * t) * env(len(t), 0.001, d) for r, a, d in ((1, 1, 0.5), (2.76, 0.5, 0.25), (5.4, 0.25, 0.12)))
    save_wav(f"{SFX}/serve.wav", bell)
    # ออเดอร์เข้า: ระนาด 2 โน้ต
    b = np.zeros(int(SR * 0.6))
    mix_into(b, ranat(note_hz(79)), 0)
    mix_into(b, ranat(note_hz(84)), 0.11)
    save_wav(f"{SFX}/order.wav", b)
    # ลูกค้าดีใจ: ไล่โน้ตขึ้น
    b = np.zeros(int(SR * 0.7))
    for i, m in enumerate((72, 76, 79, 84)):
        mix_into(b, ranat(note_hz(m), 0.3), i * 0.07)
    save_wav(f"{SFX}/happy.wav", b)
    # ลูกค้าโกรธ: เสียงบัซต่ำไล่ลง
    t = t_(0.5)
    f = np.linspace(220, 140, len(t))
    ph = np.cumsum(f) / SR
    save_wav(f"{SFX}/angry.wav", lowpass(np.sign(np.sin(2 * np.pi * ph)), 1200) * env(len(t), 0.01, 0.35))
    # ผิด: บ๊อง
    t = t_(0.35)
    save_wav(f"{SFX}/wrong.wav", (np.sin(2 * np.pi * 180 * t) + np.sin(2 * np.pi * 190 * t)) * env(len(t), 0.002, 0.2))
    # ทิ้งขยะ: ฟู่
    t = t_(0.35)
    sweep = lowpass(noise(len(t)), 900) * np.sin(np.pi * np.linspace(0, 1, len(t)))
    save_wav(f"{SFX}/trash.wav", sweep)
    # นาฬิกา
    t = t_(0.05)
    save_wav(f"{SFX}/tick.wav", np.sin(2 * np.pi * 1800 * t) * env(len(t), 0.0005, 0.01))
    # UI
    t = t_(0.06)
    save_wav(f"{SFX}/click.wav", np.sin(2 * np.pi * 900 * t) * env(len(t), 0.001, 0.02) + 0.3 * noise(len(t)) * env(len(t), 0.0005, 0.004))
    t = t_(0.04)
    save_wav(f"{SFX}/hover.wav", np.sin(2 * np.pi * 1400 * t) * env(len(t), 0.001, 0.012) * 0.4)
    # ดาว / ทำเสร็จ: ประกาย
    b = np.zeros(int(SR * 0.6))
    for i, m in enumerate((88, 91, 96)):
        mix_into(b, ranat(note_hz(m), 0.35, 0.7), i * 0.05)
    save_wav(f"{SFX}/star.wav", b)
    # จิงเกิลชนะ / แพ้
    b = np.zeros(int(SR * 2.2))
    for i, m in enumerate((72, 74, 76, 79, 81, 84)):
        mix_into(b, ranat(note_hz(m)), i * 0.12)
    mix_into(b, ching(True), 0.72)
    for m in (72, 76, 79, 84):
        mix_into(b, ranat(note_hz(m), 1.2, 0.6), 0.75)
    save_wav(f"{SFX}/win.wav", b)
    b = np.zeros(int(SR * 2.0))
    for i, m in enumerate((76, 74, 72, 69, 67)):
        mix_into(b, ranat(note_hz(m), 0.6), i * 0.22)
    mix_into(b, khaen(note_hz(55), 1.0, 0.5), 0.9)
    save_wav(f"{SFX}/lose.wav", b)
    # เดิน
    t = t_(0.08)
    save_wav(f"{SFX}/step.wav", lowpass(noise(len(t)), 900) * env(len(t), 0.001, 0.02))
    print("sfx done")


# ---------------- เพลง ----------------

PENTA = [0, 2, 4, 7, 9]  # สเกลเพนทาโทนิก (โด เร มี ซอล ลา)


def penta(degree, root=60):
    o, d = divmod(degree, 5)
    return root + 12 * o + PENTA[d]


def song(bpm, bars, melody_fn, root=60, drums=True, khaen_drone=False, minor=False):
    beat = 60.0 / bpm
    total = bars * 4 * beat
    b = np.zeros(int(SR * (total + 1.5)))
    r = np.random.default_rng(42)
    for bar in range(bars):
        t0 = bar * 4 * beat
        # เบส: สลับ โด-ซอล (หรือ ลา-มี แบบไมเนอร์)
        bass_notes = (root - 24 + (9 if minor else 0), root - 24 + (4 if minor else 7))
        for k in range(4):
            mix_into(b, bass(note_hz(bass_notes[k % 2]), beat * 0.9, 0.55), t0 + k * beat)
        if drums:
            for k in range(4):
                mix_into(b, ching(k % 2 == 1, 0.18), t0 + k * beat + (0 if k % 2 else beat * 0.5))
                if k in (0, 2):
                    mix_into(b, drum(0.5, 100), t0 + k * beat)
                if k == 3 and bar % 2:
                    mix_into(b, drum(0.35, 150), t0 + k * beat + beat * 0.5)
        if khaen_drone and bar % 2 == 0:
            for m in ((root - 12, root - 5) if not minor else (root - 3, root + 4)):
                mix_into(b, khaen(note_hz(m), beat * 8, 0.12), t0)
        for (step, deg, length) in melody_fn(bar, r):
            mix_into(b, ranat(note_hz(penta(deg, root)), min(0.6, length * beat + 0.2), 0.5), t0 + step * beat / 2)
    # ตัดหางให้วนต่อกันได้ (ใส่หางเสียงกลับไปต้นเพลง)
    loop = b[: int(SR * total)].copy()
    tail = b[int(SR * total):]
    loop[: len(tail)] += tail
    return loop


def game_melody(bar, r):
    # ท่อนซ้ำ 4 ห้อง + แปรผันเล็กน้อย
    motifs = [
        [(0, 5, 1), (1, 6, 1), (2, 7, 1), (3, 6, 1), (4, 5, 2), (6, 3, 1), (7, 4, 1)],
        [(0, 3, 1), (1, 4, 1), (2, 5, 2), (4, 4, 1), (5, 3, 1), (6, 2, 2)],
        [(0, 5, 1), (1, 7, 1), (2, 8, 1), (3, 7, 1), (4, 6, 1), (5, 5, 1), (6, 6, 2)],
        [(0, 4, 1), (1, 3, 1), (2, 2, 1), (3, 1, 1), (4, 0, 4)],
    ]
    m = list(motifs[bar % 4])
    if bar >= 8 and bar % 4 != 3:
        m = [(s, d + 2, l) for s, d, l in m]
    # ระนาดตีคู่สิบหก (ลูกเล่น) บางจังหวะ
    if r.random() < 0.5:
        m.append((7, m[-1][1] + 1, 0.5))
    return m


def menu_melody(bar, r):
    motifs = [
        [(0, 7, 2), (2, 6, 1), (3, 5, 1), (4, 6, 4)],
        [(0, 5, 2), (2, 4, 1), (3, 3, 1), (4, 4, 4)],
        [(0, 5, 1), (1, 6, 1), (2, 7, 2), (4, 8, 2), (6, 7, 2)],
        [(0, 6, 2), (2, 5, 2), (4, 5, 4)],
    ]
    return motifs[bar % 4]


def sad_melody(bar, r):
    motifs = [
        [(0, 7, 3), (3, 6, 1), (4, 5, 4)],
        [(0, 4, 3), (3, 3, 1), (4, 2, 4)],
        [(0, 5, 2), (2, 4, 2), (4, 3, 4)],
        [(0, 2, 2), (2, 1, 2), (4, 0, 4)],
    ]
    return motifs[bar % 4]


def make_music():
    os.makedirs(MUS, exist_ok=True)
    save_ogg(f"{MUS}/game.ogg", song(132, 16, game_melody, 62, drums=True, khaen_drone=True))
    save_ogg(f"{MUS}/menu.ogg", song(100, 8, menu_melody, 60, drums=True, khaen_drone=True))
    save_ogg(f"{MUS}/happy.ogg", song(118, 8, game_melody, 60, drums=True))
    save_ogg(f"{MUS}/calm.ogg", song(84, 8, menu_melody, 60, drums=False, khaen_drone=True))
    save_ogg(f"{MUS}/sad.ogg", song(70, 8, sad_melody, 57, drums=False, khaen_drone=True, minor=True))
    print("music done")


if __name__ == "__main__":
    make_sfx()
    make_music()
