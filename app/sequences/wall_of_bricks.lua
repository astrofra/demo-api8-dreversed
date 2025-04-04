hg = require("harfang")
require("physics_utils")

function SetupWallOfBricks(_scene, _res, _pipeline_info, _vtx_layout, _materials)
    -- -- specific physics setup
    local rb_nodes = {}
    local rb_nodes_neon = {}

    local _flags = hg.LSSF_Nodes | hg.LSSF_Physics
    hg.LoadSceneFromAssets("sequences/wall_of_bricks.scn", _scene, _res, _pipeline_info, _flags)

    -- automatically grab the physics nodes
    local _nodes = _scene:GetNodes()
    local i
    for i = 0, _nodes:size() - 1 do
        local _node = _nodes:at(i)
        table.insert(rb_nodes, _node)
    end

    local width = 2
    local _center = hg.Vec3(0, width * 3.0 * 0.1, 0)

    for ll = 1, 3 do
        local _cube_size = 0.1 / ll
        local _model_size = hg.Vec3(_cube_size, _cube_size, _cube_size)
        local _model_ref = _res:AddModel('neon_wall_of_bricks_cube_' .. tostring(ll) , hg.CreateCubeModel(_vtx_layout,_cube_size, _cube_size, _cube_size))

        for j = -width, width do
            for i = -width, width do
                for k = -width, width do
                    local _pos = hg.Vec3(i * _cube_size, k  * _cube_size, j * _cube_size) + _center
                    local _new_node, _new_rb = CreatePhysicCubeEx(_scene, _model_size, hg.TranslationMat4(_pos), _model_ref, {_materials.neon}, hg.RBT_Dynamic, 1.0)
                    table.insert(rb_nodes, _new_node)
                    table.insert(rb_nodes_neon, _new_node)
                end
            end
        end
    end
    
    return rb_nodes, {rb_nodes_neon = rb_nodes_neon, center = _center}
end

function ApplyPhysicsWallOfBricks(rb_nodes, scene, physics, ctx)

    for i=1, #ctx.rb_nodes_neon do
        local _node = ctx.rb_nodes_neon[i]
        local _dir = (_node:GetTransform():GetPos() - ctx.center) * 20.0 + (i / #ctx.rb_nodes_neon) * 5.0
        physics:NodeAddImpulse(_node, _dir)
    end

    return ctx
end