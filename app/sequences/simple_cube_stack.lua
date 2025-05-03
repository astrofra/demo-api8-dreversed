hg = require("harfang")
require("physics_utils")

-- SetupSimpleCubeStack(scene, res, {model_size = cube_size, model_ref = cube_ref, materials = {mat_grey}})

local grtz = {
    "grtz_analogue.scn",
    "grtz_desire.scn",
    "grtz_drflopine.scn",
    "grtz_dbug.scn",
    "grtz_gargaj.scn",
    "grtz_flush.scn",
    "grtz_mankind.scn",
    "grtz_nusan.scn",
    "grtz_mooz.scn",
    "grtz_norecess.scn"
}

function SetupSimpleCubeStack(_scene, res, pipeline_info, params)
-- specific physics setup
    local _cube_size, _cube_ref, _generic_material = params.model_size, params.model_ref, params.materials.grey

    local rb_nodes = {}
    for i = 1, 200 do
        local _new_node, _ = CreatePhysicCubeEx(_scene, _cube_size, hg.TranslationMat4(hg.Vec3(0, 1 + i * 5, 0)), _cube_ref, {_generic_material}, hg.RBT_Dynamic, 1)
        if i <= #grtz * 3 then
            local j = math.fmod(i - 1, #grtz) + 1
            local _greets, _ = hg.CreateInstanceFromAssets(_scene, hg.TranslationMat4(hg.Vec3(0, 0, 0)), "props/greets/" .. grtz[j], res, pipeline_info)
            _greets:GetTransform():SetParent(_new_node)
            _greets:GetTransform():SetRot(hg.Vec3(0, hg.DegreeToRadian(i * -15.0), 0))
        end
        table.insert(rb_nodes, _new_node)
    end

    return rb_nodes
end