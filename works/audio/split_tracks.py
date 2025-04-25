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

def extract_bass_drums_other(input_path, output_dir):
    y, sr = librosa.load(input_path, sr=None, mono=True)
    print(f"Loaded {input_path} ({len(y)} samples at {sr} Hz)")

    bass = butter_filter(y, sr, cutoff=150, btype='low')

    drums = butter_filter(y, sr, cutoff=2000, btype='high')

    other = y - bass - drums

    bass /= np.max(np.abs(bass) + 1e-8)
    drums /= np.max(np.abs(drums) + 1e-8)
    other /= np.max(np.abs(other) + 1e-8)

    os.makedirs(output_dir, exist_ok=True)
    base_name = os.path.splitext(os.path.basename(input_path))[0]

    sf.write(os.path.join(output_dir, f"{base_name}_bass.wav"), bass, sr)
    sf.write(os.path.join(output_dir, f"{base_name}_drums.wav"), drums, sr)
    sf.write(os.path.join(output_dir, f"{base_name}_other.wav"), other, sr)

    print("✔ All components exported successfully.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python split_bass_drums_other.py input.wav")
        sys.exit(1)

    input_file = sys.argv[1]
    output_dir = "output_filtered"
    extract_bass_drums_other(input_file, output_dir)
