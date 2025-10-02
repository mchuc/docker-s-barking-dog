# Copyright 2025 Marcin Chuć
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os, numpy as np, librosa, soundfile as sf

IN_DIR = "../sounds/originals"
OUT_DIR = "../sounds/optimized"
os.makedirs(OUT_DIR, exist_ok=True)

SR = 22050          # wspólna częstotliwość próbkowania
F0_REF_FILE = "dog-bark-type-03-293293.mp3"   # <<--- tu wpisujesz nazwę pliku wzorcowego

def estimate_f0(y, sr):
    f0, _, _ = librosa.pyin(y, fmin=70, fmax=600, frame_length=2048, sr=sr)
    f0 = f0[~np.isnan(f0)]
    return float(np.median(f0)) if f0.size else None

# 1) wczytaj wszystkie pliki mp3
files = [f for f in os.listdir(IN_DIR) if f.lower().endswith(".mp3")]
records = []
for name in files:
    y, sr = librosa.load(os.path.join(IN_DIR, name), sr=SR, mono=True)
    y, _ = librosa.effects.trim(y, top_db=40)
    f0 = estimate_f0(y, SR)
    records.append((name, y, f0))

# 2) znajdź F0 wzorcowego
ref = next((r for r in records if r[0] == F0_REF_FILE), None)
if not ref or not ref[2]:
    raise ValueError(f"Nie udało się wyznaczyć F0 dla pliku wzorcowego {F0_REF_FILE}")
f0_target = ref[2]
print(f"Wzorzec: {F0_REF_FILE}, F0 ≈ {f0_target:.1f} Hz")

# 3) pitch-shift pozostałych plików
for name, y, f0 in records:
    if name == F0_REF_FILE:
        y_out = y  # wzorzec zostaje bez zmian
    elif not f0:
        y_out = y  # brak detekcji — zapis bez zmian
    else:
        n_steps = 12.0 * np.log2(f0_target / f0)
        try:
            import pyrubberband as rb
            y_out = rb.pitch_shift(y, SR, n_steps=n_steps, rbargs={"formant": True})
        except Exception:
            y_out = librosa.effects.pitch_shift(y, SR, n_steps=n_steps)

    # normalizacja głośności
    peak = np.max(np.abs(y_out)) + 1e-9
    y_out = y_out * (0.89 / peak)

    base = os.path.splitext(name)[0]
    sf.write(os.path.join(OUT_DIR, f"{base}_aligned.wav"), y_out, SR, subtype="PCM_16")

print("Gotowe: wszystkie pliki dostrojone do wysokości wzorca.")
