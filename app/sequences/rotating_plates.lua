hg = require("harfang")
require("physics_utils")

-- SetupRotatingPlates(scene, res, {vtx_layout = vtx_layout, materials = {gold = mat_gold}})
function SetupRotatingPlates(_scene, _res, params)
-- specific physics setup

    local _vtx_layout, _generic_material = params.vtx_layout, params.materials.gold

    local radius = 5
    local _cube_base_dimension = 0.5
    local _cube_size = hg.Vec3(_cube_base_dimension, _cube_base_dimension / 10.0, _cube_base_dimension)
    local _cube_ref
    _cube_ref = _res:AddModel('rotating_plate_ref_1', hg.CreateCubeModel(_vtx_layout, _cube_size.x, _cube_size.y, _cube_size.z))

    local rb_nodes = {}
    local object_count = 0
    for i = -radius, radius do
        for j = -radius, radius do
            object_count = object_count + 1
            if object_count == 35 or object_count == 55 then
                _generic_material = params.materials.neon
            else
                _generic_material = params.materials.gold
            end
            local x, y, z = i * _cube_base_dimension * 0.9, i + j + radius * 2.0 + 2.0, j * _cube_base_dimension * 0.9
            local _new_node, _rb = CreatePhysicCubeEx(_scene, _cube_size, hg.TranslationMat4(hg.Vec3(x, y, z)), _cube_ref, {_generic_material}, hg.RBT_Dynamic, 1)
            _rb:SetRestitution(1.0)
            table.insert(rb_nodes, _new_node)
        end
    end

    return rb_nodes
end