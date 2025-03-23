import trimesh
import numpy as np
import os

print(os.getcwd())

# load mesh
obj_path = '../../../works/models/xi_jinping/xi_jinping.obj'
obj_name = obj_path.split('/')[-1].split('.')[0]
base = os.path.dirname(__file__)
path = os.path.abspath(os.path.join(base, obj_path))
lua_name = obj_name + '.lua'

print("> Loading : " +path )

if not os.path.isfile(path):
    raise FileNotFoundError(f"!> OBJ not found: {path}")

# Loading
mesh = trimesh.load(path, force='mesh')

print("> Mesh loaded...")

# Voxelisation
voxel_size = 0.07
min_bound, max_bound = mesh.bounds
dims = ((max_bound - min_bound) / voxel_size).astype(int)

# 3D grid
x = np.linspace(min_bound[0], max_bound[0], dims[0])
y = np.linspace(min_bound[1], max_bound[1], dims[1])
z = np.linspace(min_bound[2], max_bound[2], dims[2])
grid = np.stack(np.meshgrid(x, y, z, indexing='ij'), axis=-1).reshape(-1, 3)

print("> Meshgrid done...")

# Inclusion test
inside = mesh.contains(grid)
voxels = grid[inside]

print("> Inclusion test done...")

# Conversion
grid_indices = ((voxels - min_bound) / voxel_size).astype(int)

print("> Conversion done, now writing the Lua file...")

# Export to Lua
with open(os.path.join('app', 'voxels', lua_name), "w") as f:
    f.write("local voxels = {\n")
    for v in grid_indices:
        f.write(f"  {{x={v[0]}, y={v[1]}, z={v[2]}}},\n")
    f.write("}\n\n")
    f.write("return voxels\n")

print("> Generated a voxel of : " + str(len(grid_indices)) + " points for mesh '" + obj_name + ".lua'")
