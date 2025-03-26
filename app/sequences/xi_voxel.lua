hg = require("harfang")
require("physics_utils")
local xi_voxels = require("voxels/xi_jinping")

function SetupXiVoxel(_scene, _res, _vtx_layout, _generic_material)
-- specific physics setup

    local _cube_size = 0.15
    local _cube_ref = {}
    _cube_ref[1] = _res:AddModel('cube_xi_1', hg.CreateCubeModel(_vtx_layout, _cube_size, _cube_size, _cube_size))
    _cube_ref[2] = _res:AddModel('cube_xi_2', hg.CreateCubeModel(_vtx_layout, _cube_size * 2, _cube_size * 2, _cube_size * 2))
    _cube_ref[4] = _res:AddModel('cube_xi_4', hg.CreateCubeModel(_vtx_layout, _cube_size * 4, _cube_size * 4, _cube_size * 4))

    local rb_nodes = {}
    for i = 1, #xi_voxels do
        local _voxel_size = xi_voxels[i].size
        if _voxel_size == nil then
            _voxel_size = 1
        end
        _cube_size = 0.15 * _voxel_size
        local x, y, z = xi_voxels[i].x * _cube_size - 1.0, xi_voxels[i].y * _cube_size, xi_voxels[i].z * _cube_size - 1.0
        local _new_node, _ = CreatePhysicCubeEx(_scene, hg.Vec3(_cube_size, _cube_size, _cube_size), hg.TranslationMat4(hg.Vec3(x, y, z)), _cube_ref[_voxel_size], {_generic_material}, hg.RBT_Dynamic, 1)
        table.insert(rb_nodes, _new_node)
    end

    return rb_nodes
end