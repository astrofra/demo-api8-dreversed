hg = require("harfang")
require("physics_utils")

-- SetupRotatingPlates(scene, res, {vtx_layout = vtx_layout, materials = {gold = mat_gold}})
function SetupFlocks(_scene, _res, params)
-- specific physics setup

    local _vtx_layout, _generic_material = params.vtx_layout, params.materials.silver

    local radius = 15
    local _cube_base_dimension = 0.15
    local _cube_size = hg.Vec3(_cube_base_dimension, _cube_base_dimension / 10.0, _cube_base_dimension)
    local _cube_ref
    _cube_ref = _res:AddModel('flocks_ref_1', hg.CreateCubeModel(_vtx_layout, _cube_size.x, _cube_size.y, _cube_size.z))

    local rb_nodes = {}
    local object_count = 0
    for i = -radius, radius do
        for j = -radius, radius do
            object_count = object_count + 1
            if math.fmod(object_count, 5) == 0 then
                _generic_material = params.materials.silver
            else
                _generic_material = params.materials.neon
            end
            local x, y, z = i * _cube_base_dimension * 0.9, ((i + j) / (radius * 2.0)) + radius * 0.3, j * _cube_base_dimension * 0.9
            local _new_node, _rb = CreatePhysicCubeEx(_scene, _cube_size, hg.TranslationMat4(hg.Vec3(x, y, z)), _cube_ref, {_generic_material}, hg.RBT_Dynamic, 0.15)
            _rb:SetRestitution(5.0)
            table.insert(rb_nodes, _new_node)
        end
    end

    return rb_nodes
end

function ApplyPhysicsFlocks(rb_nodes, physics)
    local idx
    local list_len = #rb_nodes
    local _intensity = 0.1
    for i = 1, list_len do
        local _torque = hg.Vec3(math.sin(i * math.pi / list_len) * _intensity, 0.0, math.cos(i * math.pi / list_len) * _intensity)
        physics:NodeAddTorqueImpulse(rb_nodes[i], _torque)
    end
end