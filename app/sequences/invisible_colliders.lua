hg = require("harfang")
require("physics_utils")

function SetupInvisibleColliders(_scene, _res, params)
-- specific physics setup

    local _vtx_layout, _generic_material = params.vtx_layout, params.materials.gold

    local collider_size = 0.35
    local collider_size_vec = hg.Vec3(collider_size, collider_size, collider_size)
    local radius = 25
    local _sphere_size = 0.05
    local _nil_ref, _sphere_ref
    _nil_ref = _res:AddModel('invisible_colliders_ref_0', hg.CreateSphereModel(_vtx_layout, collider_size, 32, 32))
    _sphere_ref = _res:AddModel('invisible_colliders_ref_1', hg.CreateSphereModel(_vtx_layout, _sphere_size, 8, 8))

    local rb_nodes = {}

    local positions = {
        hg.Vec3(0, 2, 0),
        hg.Vec3(2, 1, 0),
        hg.Vec3(-2, 1.5, 0),
        hg.Vec3(0, 0.5, -2),
        hg.Vec3(0, 1.25, 2),
        hg.Vec3(2, 0.6, 1),
        hg.Vec3(-2, 1.2, -1),
        hg.Vec3(-1, 0.35, -2),
        hg.Vec3(1, 1.05, 2),
        hg.Vec3(3, 0.76, 1.5),
        hg.Vec3(-2, 1.12, -3),
        hg.Vec3(-1.5, 0.45, -3),
        hg.Vec3(2, 1.45, 3),
        hg.Vec3(2, 3, 1),
        hg.Vec3(-2, 2.5, 1),
        hg.Vec3(-1, 1.5, -2),
        hg.Vec3(-1, 3.25, 2),
    }
    
    for _, pos in ipairs(positions) do
        local _n, _c = CreatePhysicSphereEx(
            _scene,
            collider_size_vec,
            hg.TranslationMat4(pos),
            _nil_ref,
            {params.materials.chrome},
            hg.RBT_Dynamic,
            1
        )
        _c:SetLinearDamping(5.0)
        table.insert(rb_nodes, _n)
    end    

    local yy = 0.0
    for ii = -radius, radius do
        for jj = -radius, radius do
            local x, y, z = ii * _sphere_size * 3.0, _sphere_size / 2, jj * _sphere_size * 3.0
            local d = hg.Dist(hg.Vec3(x, 0, z), hg.Vec3(0,0,0))
            local h = map(d, 0.0, radius * _sphere_size, 2.0, 0.0)
            local i = (math.sin(d * 5.0) + 1.0) * _sphere_size * h * 30.0
            i = i + 10.0
            if math.random() > 0.95 then
                _generic_material = params.materials.neon
            else
            if math.fmod((ii + jj + radius) * ii, 2) <= 1 then
                if math.fmod((ii + jj + radius) * ii, 5) <= 1 then
                    _generic_material = params.materials.silver
                else
                    _generic_material = params.materials.chrome
                end
            else
                _generic_material = params.materials.black
            end
            end
            if d < radius * _sphere_size * 3.0 then
                local _new_node, _rb = CreatePhysicCubeEx(_scene, hg.Vec3(_sphere_size, _sphere_size, _sphere_size), hg.TranslationMat4(hg.Vec3(x, y + i + yy + math.random(), z)), _sphere_ref, {_generic_material}, hg.RBT_Dynamic, 1)
                _rb:SetRestitution(1.0)
                table.insert(rb_nodes, _new_node)
            end
            yy = yy + (_sphere_size * 0.05)
        end
    end

    return rb_nodes
end