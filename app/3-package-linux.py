import os
import subprocess
import shutil
import tarfile

input_bin_path = "bin"
input_lua_path = "hg_lua-ubuntu-x64"
input_assets_path = "assets_compiled"
input_start_bat = "start-demo.sh"
input_nfo = "dreversed.nfo"
input_shot = "screenshot.png"
# input_start_bat_2 = "start-demo-low-specs.bat"

additional_dirs = ["audio", "sequences", "voxels"]
output_path = "../dreversed_resistance-2025-linux"
output_lua_path = "engine"

try:
    os.mkdir(output_path)
except:
    print(output_path + " already exists!")

try:
    os.mkdir(os.path.join(output_path, output_lua_path))
except:
    print(os.path.join(output_path, output_lua_path) + " already exists!")

# copy lua & harfang binaries
try:
    shutil.rmtree(os.path.join(output_path, output_lua_path), ignore_errors=False, onerror=None)
except:
    print("nothing to cleanup")
shutil.copytree(os.path.join(input_bin_path, input_lua_path), os.path.join(output_path, output_lua_path))

for _to_del in ["assimp_converter", "fbx_converter", "gltf_exporter", "gltf_importer", "assetc"]:
    shutil.rmtree(os.path.join(output_path, output_lua_path, "harfang", _to_del), ignore_errors=False, onerror=None)

# copy lua files
files = os.listdir()
for _file in files:
    if _file.endswith(".lua"):
        # cmd_line = [os.path.join(input_bin_path, input_lua_path, "luac"), "-s", "-o", os.path.join(output_path, _file), _file]
        # print(cmd_line)
        # result = subprocess.run(cmd_line, stdout=subprocess.PIPE)
        if _file.find("package") <= 0:
            shutil.copy(_file, os.path.join(output_path, output_lua_path, _file))

for d in additional_dirs:
    src_dir = os.path.join(d)
    dest_dir = os.path.join(output_path, output_lua_path, d)
    if os.path.exists(dest_dir):
        shutil.rmtree(dest_dir, ignore_errors=True)
    shutil.copytree(src_dir, dest_dir)

# copy assets
try:
    shutil.rmtree(os.path.join(output_path, input_assets_path), ignore_errors=False, onerror=None)
except:
    print("nothing to cleanup")
shutil.copytree(input_assets_path, os.path.join(output_path, input_assets_path))

# start.bat
try:
    os.remove(os.path.join(output_path, input_start_bat))
except:
    print("nothing to cleanup")
shutil.copy(input_start_bat, os.path.join(output_path, input_start_bat))

# .nfo
try:
    os.remove(os.path.join(output_path, input_nfo))
except:
    print("nothing to cleanup")
shutil.copy(input_nfo, os.path.join(output_path, input_nfo))

# screenshot
try:
    os.remove(os.path.join(output_path, input_shot))
except:
    print("nothing to cleanup")
shutil.copy(input_shot, os.path.join(output_path, input_shot))

# final tar.gz release
archive_name = output_path + ".tar.gz"
with tarfile.open(archive_name, "w:gz") as tar:
    tar.add(output_path, arcname=os.path.basename(output_path))

print("Archive created:", archive_name)

