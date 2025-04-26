hg = require("harfang")
require("physics_utils")

function SetupRepulsionCore(_scene, _res, params)
    local _vtx_layout = params.vtx_layout
    local _model_size = hg.Vec3(0.15, 0.15, 0.15)
    local _model_ref = _res:AddModel("core_cube", hg.CreateCubeModel(_vtx_layout, _model_size.x / 2, _model_size.y / 2, _model_size.z / 2))

    local rb_nodes = {}
    local count = 250
    local _generic_material
    for i = 1, count do
        local theta = math.random() * math.pi * 2
        local phi = math.acos(2 * math.random() - 1)
        local r = 2.0 + math.random() * 3.0
        local pos = hg.Vec3(
            r * math.sin(phi) * math.cos(theta),
            r * math.cos(phi),
            r * math.sin(phi) * math.sin(theta)
        )
        local rot = hg.Vec3(
            r * math.sin(phi) * math.cos(theta) * math.pi,
            r * math.cos(phi) * math.pi,
            r * math.sin(phi) * math.sin(theta) * math.pi
        )
        if math.fmod(i, 25) == 1 then
            _generic_material = params.materials.silver
        else
            _generic_material = params.materials.black
        end
        local node, _ = CreatePhysicCubeEx(_scene, _model_size, hg.TransformationMat4(pos, rot), _model_ref, {_generic_material}, hg.RBT_Dynamic, 1.0)
        table.insert(rb_nodes, node)
    end
    return rb_nodes
end

function ApplyPhysicsRepulsionCore(rb_nodes, scene, physics, ctx)
    local core = hg.Vec3(0, 1.5, 0)
    local t = hg.time_to_sec_f(hg.GetClock())
    local freq = 3.5
    local pivot = hg.Vec3(0,0,0)

    for i = 1, #rb_nodes do
        local node = rb_nodes[i]
        local pos = node:GetTransform():GetPos()
        local dir = hg.Normalize(pos - core)
        local strength = math.sin(freq * t + i * 0.15)
        local force = dir * strength * 20.0
        if ctx.pivot then
            local to_pivot = ctx.pivot - pos
            force = hg.Lerp(force, to_pivot, 0.1)
        end
        force.y = force.y + 9.8 * (2.0 + math.cos(freq * t + i * 0.075)) * 0.5
        physics:NodeAddForce(node, force)

        pivot = pivot + pos
    end
    pivot = pivot * (1.0 / 250.0)
    ctx.pivot = pivot
    return ctx
end
