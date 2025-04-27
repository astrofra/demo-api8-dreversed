hg = require("harfang")
require("physics_utils")

function SetupOscillatingWall(_scene, _res, params)
    local _vtx_layout, _material = params.vtx_layout, params.materials.black
    local _size = 0.9
    local _model_size = hg.Vec3(0.2, 0.3, 0.2) * _size
    local _model_ref = _res:AddModel("osc_wall_cube", hg.CreateCubeModel(_vtx_layout, _model_size.x, _model_size.y, _model_size.z))

    local rb_nodes = {}
    local width, height = 12, 8
    local spacing = 0.25 * _size
    local mat_idx = 1
    local mat
    for z = -width/4, width/4 do
        for x = -width/2, width/2 do
            for y = 0, height do
                mat_idx = mat_idx + 1
                if mat_idx > 20 then
                    mat_idx = 1
                    mat = params.materials.neon
                else
                    mat = params.materials.black
                end
                local pos = hg.Vec3(x * spacing, 4 + y * spacing * 2.0, z * spacing)
                local node, rb = CreatePhysicCubeEx(_scene, _model_size, hg.TranslationMat4(pos), _model_ref, {mat}, hg.RBT_Dynamic, 1.0)
                table.insert(rb_nodes, node)
            end
        end
    end
    return rb_nodes
end

function ApplyPhysicsOscillatingWall(rb_nodes, scene, physics, ctx)
    local t = hg.time_to_sec_f(hg.GetClock())

    for i = 1, #rb_nodes do
        local node = rb_nodes[i]
        local pos = node:GetTransform():GetPos()
        local force = hg.Vec3(0, math.sin(t + i * 0.05) * 5.0, 0)
        -- force.y = force.y + 8.0
        physics:NodeAddForce(node, force)
    end

    return ctx
end
