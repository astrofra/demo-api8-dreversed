hg = require("harfang")
require("physics_utils")

function SetupTitleScene(_scene, _res, _pipeline_info)
    -- specific physics setup
    local _flags = hg.LSSF_Nodes | hg.LSSF_Physics
    hg.LoadSceneFromAssets("sequences/title_tv.scn", _scene, _res, _pipeline_info, _flags)

    -- automatically grab the physics nodes
    local rb_nodes = {}
    local _nodes = _scene:GetNodes()
    local i
    for i = 0, _nodes:size() - 1 do
        local _node = _nodes:at(i)
        if _node:HasInstance() == true then
            local _new_node = _node:GetInstanceSceneView():GetNode(_scene, "root")
            table.insert(rb_nodes, _new_node)
        end
    end
    
    return rb_nodes
end 