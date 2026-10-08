"""เพลงประจำด่าน: เร้าใจขึ้นทีละบท + ชั้นเสริมตอนคอมโบสูง + เพลงช่วง 30 วิสุดท้าย
ใช้เครื่องดนตรีสังเคราะห์จาก music2.py
  level1  lofi สนุก 95 BPM
  level2  lofi-funk 110 BPM กลองเต็ม เบสเดิน
  level3  ลูกทุ่ง/หมอลำผสม 125 BPM พิณ แคน ฉิ่ง
  <level>_hype  ชั้นเสริม (เพอร์คัชชัน + อาร์เปจโจ) ความยาวเท่าเพลงหลัก เล่นซ้อนพร้อมกันได้
  rush    145 BPM เร่งเร้า ใช้ใน 30 วิสุดท้ายของทุกด่าน
รัน: python3 tools/audio/music_levels.py
"""
import os
import subprocess
import sys
import wave

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from music2 import (MAJ, MUS, SR, Track, bass, chord, ching, clap, epiano, hat, hz, khaen, kick, lp, marimba,
                    pluck, reverb, shaker, snare)

MINOR_PENTA = [0, 3, 5, 7, 10]


def tick(amp=1.0):
    """เสียงติ๊กนาฬิกา (ไม้เคาะสั้น ๆ)"""
    t = np.arange(int(0.05 * SR)) / SR
    x = np.sin(2 * np.pi * 2400 * t) * np.exp(-t * 160) + 0.4 * np.sin(2 * np.pi * 3700 * t) * np.exp(-t * 220)
    return x * amp


def mix_out(track, path, wet=0.2, ref_peak=None):
    """เหมือน music2.render แต่กำหนดระดับอ้างอิงได้ (ชั้นเสริมจะได้ดังพอดีกับเพลงหลัก)"""
    L = reverb(track.L, wet)
    R = reverb(track.R, wet, 1.07)
    n = track.length
    for ch in (L, R):
        tail = ch[n:].copy()
        ch[: len(tail)] += tail
    L, R = L[:n], R[:n]
    peak = ref_peak or max(np.max(np.abs(L)), np.max(np.abs(R))) or 1
    L, R = np.tanh(L / peak * 1.1) * 0.9, np.tanh(R / peak * 1.1) * 0.9
    data = (np.stack([L, R], axis=1) * 32767).astype(np.int16)
    tmp = path + ".wav"
    with wave.open(tmp, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", "5", path], check=True)
    os.remove(tmp)
    print("wrote", path, f"{n / SR:.1f}s")
    return peak


def raw_peak(track, wet=0.2):
    L = reverb(track.L, wet)
    return max(np.max(np.abs(L[: track.length])), 1e-6)


# ---------------- บท 1: lofi สนุก ----------------

def level1(layer=False, bpm=95, bars=16, key=62):
    beat = 60 / bpm
    T = Track(bars * 4 * beat)
    prog = [(0, "maj7"), (9, "min7"), (2, "min7"), (7, "dom7")]
    mel = [[4, None, 5, 7, 9, None, 7, None], [5, None, 4, 2, 4, None, 2, 0],
           [2, 4, 5, None, 7, 5, 4, 2], [4, None, 2, None, 0, None, None, None]]
    for bar in range(bars):
        t0 = bar * 4 * beat
        r, kind = prog[bar % 4]
        ch = chord(key - 12 + r, kind)
        if not layer:
            for i, m in enumerate(ch):
                T.add(epiano(hz(m), 2 * beat, 0.2), t0 + i * 0.015, -0.2 + 0.15 * i)
                T.add(epiano(hz(m), 2 * beat, 0.16), t0 + 2 * beat + 0.5 * beat + i * 0.015, -0.2 + 0.15 * i)
            for off, n in ((0, 0), (1.5, 0), (2, 2), (3, 1)):
                T.add(bass(hz(ch[min(n, len(ch) - 1)] - 12), beat * 0.6, 0.55), t0 + off * beat, 0)
            T.add(kick(0.65), t0, 0)
            T.add(kick(0.5), t0 + 1.5 * beat, 0)
            T.add(kick(0.55), t0 + 2.5 * beat, 0)
            T.add(snare(0.4, True), t0 + beat, 0)
            T.add(snare(0.4, True), t0 + 3 * beat, 0)
            for k in range(8):
                T.add(hat(0.09 if k % 2 == 0 else 0.06), t0 + k * beat / 2 + (0.06 * beat if k % 2 else 0), 0.3)
            if bar >= 4:
                for k, deg in enumerate(mel[bar % 4]):
                    if deg is None:
                        continue
                    o, d = divmod(deg, 7)
                    T.add(pluck(hz(key + 12 * o + MAJ[d] + 12), 0.7, 0.4, 0.996, 0.38), t0 + k * beat / 2, 0.3)
        else:
            # ชั้นเสริม: เชคเกอร์ 16 ส่วน + มาริมบาอาร์เปจโจ + ปรบมือ
            for k in range(16):
                T.add(shaker(0.09 if k % 4 == 2 else 0.05), t0 + k * beat / 4, 0.45)
            for k in range(8):
                m = ch[k % len(ch)] + 24
                T.add(marimba(hz(m), 0.35, 0.28), t0 + k * beat / 2 + beat / 4, -0.35)
            T.add(clap(0.3), t0 + beat, 0.15)
            T.add(clap(0.3), t0 + 3 * beat, 0.15)
    return T


# ---------------- บท 2: lofi-funk ----------------

def level2(layer=False, bpm=110, bars=16, key=57):
    beat = 60 / bpm
    T = Track(bars * 4 * beat)
    prog = [(0, "min7"), (5, "min7"), (10, "dom7"), (3, "maj7")]
    mel = [[7, None, 7, 5, 3, None, 0, None], [3, 5, None, 7, 8, None, 7, 5],
           [7, None, 10, 8, 7, 5, 3, None], [5, 3, 2, None, 0, None, None, None]]
    for bar in range(bars):
        t0 = bar * 4 * beat
        r, kind = prog[bar % 4]
        ch = chord(key - 12 + r, kind)
        if not layer:
            # คอร์ดสับจังหวะ (สแตป) เปียโนไฟฟ้า
            for off in (0, 0.75, 1.5, 2.5, 3.25):
                for i, m in enumerate(ch):
                    T.add(epiano(hz(m), beat * 0.4, 0.16), t0 + off * beat + i * 0.01, -0.25 + 0.15 * i)
            # เบสเดินเขบ็ต 8
            walk = [0, 0, 12, 0, 7, 0, 10, 12]
            for k, iv in enumerate(walk):
                T.add(bass(hz(ch[0] - 12 + iv), beat * 0.42, 0.6), t0 + k * beat / 2, 0)
            # กลองเต็ม: เบสดรัมทุกจังหวะ + สแนร์ + ไฮแฮต 16
            for k in range(4):
                T.add(kick(0.7), t0 + k * beat, 0)
            T.add(snare(0.5), t0 + beat, 0.05)
            T.add(snare(0.5), t0 + 3 * beat, 0.05)
            for k in range(16):
                T.add(hat(0.08 if k % 2 == 0 else 0.045), t0 + k * beat / 4, 0.35)
            if bar % 4 == 3:
                T.add(hat(0.12, open_=True), t0 + 3.5 * beat, 0.35)
            for k, deg in enumerate(mel[bar % 4]):
                if deg is None:
                    continue
                T.add(marimba(hz(key + 12 + deg), 0.5, 0.42), t0 + k * beat / 2, 0.25)
        else:
            for k in range(16):
                T.add(shaker(0.1 if k % 2 else 0.06), t0 + k * beat / 4, 0.5)
            T.add(clap(0.4), t0 + beat, -0.1)
            T.add(clap(0.4), t0 + 3 * beat, -0.1)
            # อาร์เปจโจพิณเร็ว
            for k in range(16):
                m = ch[k % len(ch)] + 24 + (12 if k % 8 >= 6 else 0)
                T.add(pluck(hz(m), 0.25, 0.8, 0.99, 0.2), t0 + k * beat / 4, -0.4)
    return T


# ---------------- บท 3: ลูกทุ่ง/หมอลำผสม ----------------

def level3(layer=False, bpm=125, bars=16, key=57):
    beat = 60 / bpm
    T = Track(bars * 4 * beat)
    riffs = [[0, 2, 3, 2, 0, 2, 4, 3], [4, 3, 2, 3, 4, 5, 4, 2], [0, 2, 3, 4, 5, 4, 3, 2], [3, 2, 0, -1, 0, None, 0, None]]
    for bar in range(bars):
        t0 = bar * 4 * beat
        if not layer:
            if bar % 2 == 0:
                for m, g in ((key, 0.1), (key + 7, 0.08), (key + 12, 0.06)):
                    T.add(khaen(hz(m), 8 * beat, g), t0, 0.3)
            for k in range(8):
                n = key - 24 if k % 2 == 0 else key - 17
                T.add(bass(hz(n + (12 if k == 7 else 0)), beat * 0.35, 0.6), t0 + k * beat / 2, 0)
            for k in range(4):
                T.add(kick(0.75), t0 + k * beat, 0)
                T.add(ching(0.13, open_=(k % 2 == 0)), t0 + k * beat + beat / 2, -0.4)
            T.add(clap(0.42), t0 + beat, 0.2)
            T.add(clap(0.42), t0 + 3 * beat, 0.2)
            for k in range(8):
                T.add(hat(0.07), t0 + k * beat / 2 + beat / 4, 0.5)
            riff = riffs[bar % 4]
            for k, deg in enumerate(riff):
                if deg is None:
                    continue
                o, d = divmod(deg, 5)
                m = key + 12 + 12 * o + MINOR_PENTA[d]
                T.add(pluck(hz(m), 0.45, 0.85, 0.994, 0.45), t0 + k * beat / 2, -0.2)
                if k % 2 == 1:
                    T.add(pluck(hz(m), 0.3, 0.85, 0.99, 0.2), t0 + k * beat / 2 + beat / 4, -0.2)
        else:
            # ชั้นเสริม: แคนเป่าลายสั้น + ฉิ่งถี่ + เชคเกอร์
            for k in range(8):
                T.add(ching(0.08, open_=False), t0 + k * beat / 2, -0.45)
            for k in range(16):
                T.add(shaker(0.08 if k % 2 else 0.05), t0 + k * beat / 4, 0.45)
            lick = [[7, 5, 7, 10], [12, 10, 7, 5], [7, 10, 12, 15], [12, 10, 7, None]][bar % 4]
            for k, iv in enumerate(lick):
                if iv is None:
                    continue
                T.add(khaen(hz(key + iv), beat * 0.9, 0.12), t0 + k * beat, 0.1)
    return T


# ---------------- 30 วิสุดท้าย ----------------

def rush(bpm=145, bars=8, key=57):
    beat = 60 / bpm
    T = Track(bars * 4 * beat)
    riff = [0, 3, 5, 3, 7, 5, 3, 5, 0, 3, 5, 7, 10, 7, 5, 3]
    for bar in range(bars):
        t0 = bar * 4 * beat
        for k in range(4):
            T.add(kick(0.8), t0 + k * beat, 0)
            T.add(tick(0.35), t0 + k * beat, 0.6)
        T.add(snare(0.55), t0 + beat, 0)
        T.add(snare(0.55), t0 + 3 * beat, 0)
        if bar % 2 == 1:
            for k in range(4):
                T.add(snare(0.3, True), t0 + 3 * beat + k * beat / 4, 0)
        for k in range(16):
            T.add(hat(0.09 if k % 2 == 0 else 0.05), t0 + k * beat / 4, 0.35)
        for k in range(8):
            T.add(bass(hz(key - 24 + (7 if k % 4 == 3 else 0)), beat * 0.35, 0.65), t0 + k * beat / 2, 0)
        for k, iv in enumerate(riff):
            T.add(pluck(hz(key + 12 + iv + (12 if bar % 4 == 3 else 0)), 0.22, 0.9, 0.99, 0.3), t0 + k * beat / 4, -0.25)
        if bar % 2 == 0:
            T.add(khaen(hz(key + 12), 8 * beat, 0.08), t0, 0.3)
    return T


def build():
    os.makedirs(MUS, exist_ok=True)
    only = sys.argv[1:]  # เลือกทำบางเพลงได้ เช่น level2
    # ชั้นเสริมอ้างอิงระดับเพลงหลัก x ค่านี้ (น้อย = ชั้นเสริมดังขึ้น) จูนให้ทุกบทดังใกล้กัน
    layer_ref = {"level1": 0.9, "level2": 0.3, "level3": 0.75}
    for name, f in (("level1", level1), ("level2", level2), ("level3", level3)):
        if only and name not in only:
            continue
        base = f()
        peak = mix_out(base, f"{MUS}/{name}.ogg")
        mix_out(f(layer=True), f"{MUS}/{name}_hype.ogg", ref_peak=peak * layer_ref[name])
    if only and "rush" not in only:
        return
    mix_out(rush(), f"{MUS}/rush.ogg")


if __name__ == "__main__":
    build()
