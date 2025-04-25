hg = require("harfang")
require("physics_utils")

-- SetupSpiralTornado(scene, res, {vtx_layout = vtx_layout, materials = {gold = mat_gold}})
function SetupSpiralTornado(_scene, _res, params)
-- specific physics setup

    local _vtx_layout, _generic_material = params.vtx_layout, params.materials.chrome

    local radius = 8
    local _cube_base_dimension = 0.15
    local _cube_size = hg.Vec3(_cube_base_dimension, _cube_base_dimension / 2.0, _cube_base_dimension)
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
            local _new_node, _rb = CreatePhysicCubeEx(_scene, _cube_size * 2.0, hg.TranslationMat4(hg.Vec3(x, y, z)), _cube_ref, {_generic_material}, hg.RBT_Dynamic, 0.75)
            _rb:SetRestitution(1.0)
            table.insert(rb_nodes, _new_node)
        end
    end

    return rb_nodes
end

function ApplyPhysicsSpiralTornado(rb_nodes, scene, physics, ctx)
    local center = hg.Vec3(0, 2.0, 0)
    local base_multiplier = 10.0
    local spiral_intensity = 2.5
    local vertical_speed_factor = 0.6
    local radial_damping = 0.6
    local node

    for i = 1, #rb_nodes do
        node = rb_nodes[i]
        local pos = node:GetTransform():GetPos()
        local vel = physics:NodeGetLinearVelocity(node)

        local dir_to_center = center - pos
        local dist_to_center = hg.Len(dir_to_center)
        local dir_norm = hg.Normalize(dir_to_center)

        local toward_center_force = (dir_to_center - vel * radial_damping) * base_multiplier

        local tangent = hg.Vec3(-dir_norm.z, 0, dir_norm.x)
        local spiral_force = tangent * (spiral_intensity * (0.5 + pos.y * vertical_speed_factor))

        local total_force = toward_center_force + spiral_force

        physics:NodeAddForce(node, total_force)
    end

    return ctx
end



