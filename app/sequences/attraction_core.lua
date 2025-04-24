hg = require("harfang")
require("physics_utils")

local count = 350
local radius = 2.0
local loops = 5.0

function SetupAttractionCore(_scene, _res, params)
    local _vtx_layout, _material = params.vtx_layout, params.materials.gold
    local _models = {}
    for i = 1, 4 do
        local _master_size = i / 8.0
        local _size = hg.Vec3(_master_size, _master_size, _master_size)
        _models[i] = {
            size = _size,
            ref = _res:AddModel("core_cube_" .. tostring(i), hg.CreateCubeModel(_vtx_layout, _size.x / 2, _size.y / 2, _size.z / 2))
        }
    end

    local rb_nodes = {}

    local idx = 1
    for i = 1, count do
        local pos = hg.Vec3(radius * math.cos(i * loops * math.pi / count), map(i, 1, count, 0.25, 5.0), radius * math.sin(i * loops * math.pi / count))
        local rot = hg.Vec3(0,0,0)
        idx = idx + 3
        if idx > #_models then
            idx = 1
        end
        local node, _ = CreatePhysicCubeEx(_scene, _models[idx].size, hg.TransformationMat4(pos, rot), _models[idx].ref, {_material}, hg.RBT_Dynamic, 1.0)
        table.insert(rb_nodes, node)
    end
    return rb_nodes
end

function ApplyPhysicsAttractionCore(rb_nodes, scene, physics, ctx)
    local core = hg.Vec3(0, 1.5, 0)
    local t = hg.time_to_sec_f(hg.GetClock())
    local freq = 3.5
    local pivot = hg.Vec3(0,0,0)

    for i = 1, #rb_nodes do
        local node = rb_nodes[i]
        local pos = node:GetTransform():GetPos()
        local dir = hg.Vec3(0,0,0)
        if i < #rb_nodes then
            dir = hg.Normalize(rb_nodes[i + 1]:GetTransform():GetPos() - pos) * 2.0
        -- else
        --     dir = hg.Normalize(pos - core)
        end

        dir = dir + hg.Normalize(pos - core) * -2.5

        local force = dir * 2.0
        force.y = force.y + 9.8 * (2.0 + math.cos(freq * t + i * 0.075)) * 0.55

        -- to center
        local to_center = pos * hg.Vec3(1.0, 0.0, 1.0)
        local len = clamp(hg.Len(to_center) / radius, 0.0, 1.0)
        len = len * len
        to_center = (hg.Normalize(to_center) * len * -2.5)
        force = force + to_center

        physics:NodeAddForce(node, force)

        pivot = pivot + pos
    end
    pivot = pivot * (1.0 / 250.0)
    ctx.pivot = pivot
    return ctx
end
