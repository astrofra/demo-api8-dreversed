hg = require("harfang")
require("physics_utils")

-- SetupSimpleCubeStack(scene, res, {model_size = cube_size, model_ref = cube_ref, materials = {mat_grey}})
function SetupSimpleCubeStack(_scene, res, params)
-- specific physics setup
    local _cube_size, _cube_ref, _generic_material = params.model_size, params.model_ref, params.materials.grey

    print(">>> Description:\n>>> Drop vertically 200 chairs, made of 6 collision boxes each")
    -- chair_node, _ = hg.CreateInstanceFromAssets(_scene, hg.TranslationMat4(hg.Vec3(0, 1, 0)), "common/chair/chair.scn", res, hg.GetForwardPipelineInfo())

    local rb_nodes = {}
    for i = 1, 200 do
        -- local _new_node, _ = hg.CreateInstanceFromAssets(_scene, hg.TranslationMat4(hg.Vec3(0, 1 + i * 5, 0)), "common/chair/chair.scn", res, hg.GetForwardPipelineInfo())
        local _new_node, _ = CreatePhysicCubeEx(_scene, _cube_size, hg.TranslationMat4(hg.Vec3(0, 1 + i * 5, 0)), _cube_ref, {_generic_material}, hg.RBT_Dynamic, 1)
        table.insert(rb_nodes, _new_node)
    end

    return rb_nodes
end