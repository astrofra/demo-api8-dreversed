hg = require("harfang")
require("physics_utils")

function SetupTitleScene(_scene, _res, _pipeline_info)
    -- specific physics setup
    -- LSSF_Nodes
    -- LSSF_Scene
    -- LSSF_Anims
    -- LSSF_KeyValues
    -- LSSF_Physics
    -- LSSF_Scripts
    -- LSSF_All
    -- LSSF_QueueTextureLoads
    -- LSSF_FreezeMatrixToTransformOnSave
    -- LSSF_QueueModelLoads
    -- LSSF_DoNotChangeCurrentCameraIfValid
    local _flags = hg.LSSF_Nodes | hg.LSSF_Physics
    hg.LoadSceneFromAssets("sequences/title_tv.scn", _scene, _res, _pipeline_info, _flags)

    rb_nodes = {}
    
    return rb_nodes
end 