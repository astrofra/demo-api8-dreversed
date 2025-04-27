import os
import soundfile as sf

# Dossier contenant les fichiers audio .ogg
audio_folder = "../../assets/audio"
# Fichier de sortie Lua
output_lua_file = "../../audio/audio_data.lua"

# Dictionnaire pour stocker les métadonnées
audio_data = {}

# Parcours des fichiers .ogg
for filename in os.listdir(audio_folder):
    if filename.lower().endswith(".ogg"):
        full_path = os.path.join(audio_folder, filename)
        try:
            # Lire les infos du fichier
            f = sf.SoundFile(full_path)
            duration = len(f) / f.samplerate
            audio_data[filename] = duration
            print(f"{filename} : {duration:.2f} sec")
        except Exception as e:
            print(f"Erreur sur {filename} : {e}")

# Écriture dans un fichier Lua
with open(output_lua_file, 'w') as lua_file:
    lua_file.write("audio_metadata = {\n")
    for filename, duration in audio_data.items():
        lua_file.write(f"\t['{filename}'] = {{ duration = {duration:.3f} }},\n")
    lua_file.write("}\n")

print("✔ audio_data.lua généré :", output_lua_file)
