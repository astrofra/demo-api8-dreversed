hg = require("harfang")
require("physics_utils")

-- SetupRotatingPlates(scene, res, {vtx_layout = vtx_layout, materials = {gold = mat_gold}})
function SetupTornado(_scene, _res, params)
-- specific physics setup

    local _vtx_layout, _generic_material = params.vtx_layout, params.materials.chrome

    local radius = 10
    local _cube_base_dimension = 0.15
    local _cube_size = hg.Vec3(_cube_base_dimension, _cube_base_dimension / 10.0, _cube_base_dimension)
    local _cube_ref
    _cube_ref = _res:AddModel('tornado_ref_1', hg.CreateCubeModel(_vtx_layout, _cube_size.x, _cube_size.y, _cube_size.z))

    local rb_nodes = {}
    local object_count = 0
    for i = -radius, radius do
        for j = -radius, radius do
            object_count = object_count + 1
            if math.fmod(object_count, 25) == 1 then
                _generic_material = params.materials.neon
            else
                _generic_material = params.materials.chrome
            end
            local x, y, z = i * _cube_base_dimension * 0.9, ((i + math.fmod(j * i + j + i, radius * 2.0)) / (radius)) + radius * 0.1, j * _cube_base_dimension * 0.9
            local _new_node, _rb = CreatePhysicCubeEx(_scene, _cube_size * 2.0, hg.TranslationMat4(hg.Vec3(x, y, z)), _cube_ref, {_generic_material}, hg.RBT_Dynamic, 0.15)
            _rb:SetRestitution(1.0)
            table.insert(rb_nodes, _new_node)
        end
    end

    return rb_nodes
end

function ApplyPhysicsTornado(rb_nodes,  scene, physics, ctx)

    local center = hg.Vec3(0, 2.0, 0)
    local multiplier = hg.Vec3(2.5, 1.0, 2.5)
    local node

    for i = 1, #rb_nodes do
        node = rb_nodes[i]
        local pos = node:GetTransform():GetPos()
        local vel = physics:NodeGetLinearVelocity(node)
        local randomized_center = center
        randomized_center.y = randomized_center.y + math.sin(i / #rb_nodes * math.pi * 5.534235) * 0.025
        local dir_to_center = randomized_center - pos
        physics:NodeAddForce(node, (dir_to_center - vel) * multiplier)
    end

    return ctx
end

