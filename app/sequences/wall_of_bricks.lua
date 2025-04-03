hg = require("harfang")
require("physics_utils")

function SetupWallOfBricks(_scene, _res, _pipeline_info, _vtx_layout, _materials)
    -- -- specific physics setup
    local _flags = hg.LSSF_Nodes | hg.LSSF_Physics
    hg.LoadSceneFromAssets("sequences/wall_of_bricks.scn", _scene, _res, _pipeline_info, _flags)

    -- automatically grab the physics nodes
    local rb_nodes = {}
    local _nodes = _scene:GetNodes()
    local i
    for i = 0, _nodes:size() - 1 do
        local _node = _nodes:at(i)
        -- if _node:HasInstance() == true and string.sub(_node:GetName(), 1, 8) == 'physics_' then
            -- local _new_node = _node:GetInstanceSceneView():GetNode(_scene, "root")
            table.insert(rb_nodes, _node)
        -- end
    end

    local _cube_size = 1.0
    local _model_size = hg.Vec3(_cube_size, _cube_size, _cube_size)
    local _model_ref = _res:AddModel('neon_wall_of_bricks_cube', hg.CreateCubeModel(_vtx_layout,_cube_size, _cube_size, _cube_size))

    local _new_node, _new_rb = CreatePhysicCubeEx(_scene, _model_size, hg.TranslationMat4(hg.Vec3(0,_cube_size / 2.0,0)), _model_ref, {_materials.neon}, hg.RBT_Dynamic, 5.0)
    local _idx = table.insert(rb_nodes, _new_node)
    
    return rb_nodes, {cube = _new_node, cube_rb = _new_rb, cube_idx = _idx}
end

function ApplyPhysicsWallOfBricks(rb_nodes, scene, physics, ctx)
    if ctx.cube then
        if ctx.start_clock == nil then
            ctx.start_clock = hg.GetClock()
        elseif hg.GetClock() - ctx.start_clock > hg.time_from_sec_f(1.0) then
            physics:NodeDestroyPhysics(ctx.cube)
            scene:DestroyNode(ctx.cube)
            ctx.cube = nil
            table.remove(rb_nodes, ctx.cube_idx)
        end
    end
    return ctx
end