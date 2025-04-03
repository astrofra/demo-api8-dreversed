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

function ApplyPhysicsTornado(rb_nodes, physics)

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

    -- local center = hg.Vec3(0, 0, 0)
    -- local min_radius = 2.0
    -- local max_radius = 2.5
    -- local intensity = 1.0
    -- local twist_speed = 4.0
    -- local updraft = 3.0
    -- local correction_gain = 5.0 -- force radiale de recentrage

    -- for i = 1, #rb_nodes do
    --     local node = rb_nodes[i]
    --     local pos = node:GetTransform():GetPos()
    --     local to_center = center - pos
    --     local dist = hg.Len(to_center)
    --     local dir_to_center = hg.Normalize(to_center)

    --     -- Tangente horizontale = rotation autour du centre
    --     local tangent = hg.Vec3(-dir_to_center.z, 0, dir_to_center.x) * twist_speed
    --     local upward = hg.Vec3(0, updraft, 0)

    --     local force = tangent + upward

    --     -- Correction radiale si en dehors de la bande
    --     if dist < min_radius or dist > max_radius then
    --         local correction_dir = dir_to_center
    --         if (dist > min_radius) then 
    --             correction_dir = -dir_to_center
    --         end 
    --         local radial_correction = correction_dir * correction_gain * math.abs(dist - ((min_radius + max_radius) / 2))
    --         force = force + radial_correction
    --     end

    --     -- Compensation de la vitesse radiale
    --     local vel = physics:NodeGetLinearVelocity(node)
    --     local radial_vel = hg.Dot(vel, dir_to_center)
    --     local damping_force = dir_to_center * radial_vel * 0.1 -- freine la dérive radiale
    --     damping_force.y = 0.0

    --     force = force + damping_force

    --     physics:NodeAddForce(node, force * intensity)
    -- end
end

