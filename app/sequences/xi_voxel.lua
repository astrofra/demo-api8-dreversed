hg = require("harfang")
require("physics_utils")
local xi_voxels = require("voxels/xi_jinping")

function SetupXiVoxel(_scene, _res, _vtx_layout, _generic_material)
-- specific physics setup

    local _cube_size = 0.5
    local _cube_ref = _res:AddModel('cube_xi', hg.CreateCubeModel(_vtx_layout, _cube_size, _cube_size, _cube_size))

    local rb_nodes = {}
    for i = 1, #xi_voxels do
        local x, y, z = xi_voxels[i].z * _cube_size, xi_voxels[i].y * _cube_size, xi_voxels[i].x * _cube_size
        local _new_node, _ = CreatePhysicCubeEx(_scene, hg.Vec3(_cube_size, _cube_size, _cube_size), hg.TranslationMat4(hg.Vec3(x, y, z)), _cube_ref, {_generic_material}, hg.RBT_Static, 1)
        table.insert(rb_nodes, _new_node)
    end

    return rb_nodes
end