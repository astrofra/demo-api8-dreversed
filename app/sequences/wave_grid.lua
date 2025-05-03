hg = require("harfang")
require("physics_utils")

-- SetupWaveGrid(scene, res, {vtx_layout = vtx_layout, materials = {gold = mat_gold}})
function SetupWaveGrid(_scene, _res, params)
-- specific physics setup

    local _vtx_layout, _generic_material = params.vtx_layout, params.materials.gold

    local radius = 20
    local _cube_size = 0.1
    local _cube_ref
    _cube_ref = _res:AddModel('sphere_wave_grid_ref_1', hg.CreateSphereModel(_vtx_layout, _cube_size, 8, 8))

    local rb_nodes = {}
    for i = -radius, radius do
        for j = -radius, radius do
            local x, y, z = i * _cube_size, _cube_size / 2, j * _cube_size
            local d = hg.Dist(hg.Vec3(x, 0, z), hg.Vec3(0,0,0))
            local h = map(d, 0.0, radius * _cube_size, 2.0, 0.0)
            local k = (math.sin(d * 5.0) + 1.0) * _cube_size * h * 10.0
            k = k + 3.0
            if math.fmod((k + j + radius) * k, 2) <= 1 then
                if math.fmod((k + j + radius) * k, 5) <= 1 then
                    _generic_material = params.materials.neon
                else
                    _generic_material = params.materials.black
                end
            else
                _generic_material = params.materials.gold
            end
            if d < radius * _cube_size then
                local _new_node, _rb = CreatePhysicCubeEx(_scene, hg.Vec3(_cube_size, _cube_size, _cube_size), hg.TranslationMat4(hg.Vec3(x, y + k, z)), _cube_ref, {_generic_material}, hg.RBT_Dynamic, 1)
                _rb:SetRestitution(1.0)
                table.insert(rb_nodes, _new_node)
            end
        end
    end

    return rb_nodes
end