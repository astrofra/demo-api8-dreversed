import numpy as np
import os

# Load the files
base_path = "out"
files = {
    "bass": os.path.join(base_path, "after-nothing-riddlemak_bass.txt"),
    "drums": os.path.join(base_path, "after-nothing-riddlemak_drums.txt"),
    "other": os.path.join(base_path, "after-nothing-riddlemak_other.txt")
}

# Read and convert the data
data = {}
for key, file_path in files.items():
    with open(file_path, "r") as f:
        values = [float(line.strip()) for line in f if line.strip()]
        data[key] = values

# Function to convert to Lua table string
def to_lua_table(data_list, table_name):
    lines = [f"{table_name} = {{"]
    for i, val in enumerate(data_list):
        lines.append(f"    {val},")
    lines.append("}")
    return "\n".join(lines)

# Generate Lua files
lua_files = {}
for key in data:
    lua_content = to_lua_table(data[key], f"{key}_dynamics")
    lua_files[key] = lua_content

# Save the files
output_paths = {}
for key, content in lua_files.items():
    output_path = f"out/{key}_dynamics.lua"
    with open(output_path, "w") as f:
        f.write(content)
    output_paths[key] = output_path

output_paths
