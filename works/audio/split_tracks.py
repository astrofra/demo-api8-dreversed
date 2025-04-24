import sys
import os
import numpy as np
import librosa
import soundfile as sf
from scipy.signal import butter, lfilter

def butter_filter(data, sr, cutoff, btype='low', order=5):
    nyq = 0.5 * sr
    normal_cutoff = cutoff / nyq
    b, a = butter(order, normal_cutoff, btype=btype, analog=False)
    return lfilter(b, a, data)

def extract_bass_and_drums(input_path, output_dir):
    y, sr = librosa.load(input_path, sr=None, mono=True)
    print(f"Loaded {input_path} ({len(y)} samples at {sr} Hz)")

    # Basse = passe-bas ~150Hz
    bass = butter_filter(y, sr, cutoff=150, btype='low')

    # Percussions = passe-haut ~2000Hz
    drums = butter_filter(y, sr, cutoff=2000, btype='high')

    # Normalisation
    bass /= np.max(np.abs(bass))
    drums /= np.max(np.abs(drums))

    # Sauvegarde
    os.makedirs(output_dir, exist_ok=True)
    base_name = os.path.splitext(os.path.basename(input_path))[0]

    bass_path = os.path.join(output_dir, f"{base_name}_bass.wav")
    drums_path = os.path.join(output_dir, f"{base_name}_drums.wav")

    sf.write(bass_path, bass, sr)
    sf.write(drums_path, drums, sr)

    print(f"✔ Bass saved to: {bass_path}")
    print(f"✔ Drums saved to: {drums_path}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python split_bass_and_drums.py input.wav")
        sys.exit(1)

    input_file = sys.argv[1]
    output_dir = "output_filtered"
    extract_bass_and_drums(input_file, output_dir)
