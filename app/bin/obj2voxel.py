import trimesh
import numpy as np

# Chargement du mesh
mesh = trimesh.load('model.obj')

# Paramètres de voxelisation
voxel_size = 0.05
min_bound, max_bound = mesh.bounds
dims = ((max_bound - min_bound) / voxel_size).astype(int)

# Grille 3D
x = np.linspace(min_bound[0], max_bound[0], dims[0])
y = np.linspace(min_bound[1], max_bound[1], dims[1])
z = np.linspace(min_bound[2], max_bound[2], dims[2])
grid = np.stack(np.meshgrid(x, y, z, indexing='ij'), axis=-1).reshape(-1, 3)

# Test d'inclusion
inside = mesh.contains(grid)
voxels = grid[inside]

# Conversion en indices de grille entiers (si nécessaire pour aligner)
grid_indices = ((voxels - min_bound) / voxel_size).astype(int)

# Export vers fichier texte format Lua
with open("voxel_data.lua", "w") as f:
    f.write("voxels = {\n")
    for v in grid_indices:
        f.write(f"  {{x={v[0]}, y={v[1]}, z={v[2]}}},\n")
    f.write("}\n")
