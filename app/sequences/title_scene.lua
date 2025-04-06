hg = require("harfang")
require("physics_utils")

function SetupTitleScene(_scene, _res, _pipeline_info, _vtx_layout, _materials)
    -- -- specific physics setup
    local _flags = hg.LSSF_Nodes | hg.LSSF_Physics
    hg.LoadSceneFromAssets("sequences/title_tv.scn", _scene, _res, _pipeline_info, _flags)

    local camera_tv = _scene:GetNodeEx("physics_tv_vintage/CameraTV")

    -- automatically grab the physics nodes
    local rb_nodes = {}
    local _nodes = _scene:GetNodes()
    local i
    for i = 0, _nodes:size() - 1 do
        local _node = _nodes:at(i)
        if _node:HasInstance() == true and string.sub(_node:GetName(), 1, 8) == 'physics_' then
            local _new_node = _node:GetInstanceSceneView():GetNode(_scene, "root")
            table.insert(rb_nodes, _new_node)
        end
    end

    -- add golden cubes (why not ?)
    local _model_size = hg.Vec3(0.1, 0.1, 0.1)
    local _model_ref_1 = _res:AddModel('title_golden_cubes_1', hg.CreateCubeModel(_vtx_layout, _model_size.x, _model_size.y, _model_size.z))
    local _model_ref_2 = _res:AddModel('title_golden_cubes_2', hg.CreateCubeModel(_vtx_layout, _model_size.x / 2, _model_size.y / 2, _model_size.z / 2))
    local _grid_size = 7
    local _padding_factor = 0.35
    local _drop_height = 20
    local _y_offset = 0.0
    local _pos, _rot

    for i = -_grid_size, _grid_size do
        for j  = -_grid_size, _grid_size do
            local _phase0, _phase1 = math.sin((i + j) * 2.0 * math.pi / (_grid_size * 2)), math.cos((i + j) * 2.0 * math.pi / (_grid_size * 2))
            _pos = hg.Vec3(i * _padding_factor, _drop_height + _y_offset, j * _padding_factor)
            _pos.x = _pos.x + _phase0
            _pos.z = _pos.z + _phase1
            _rot = hg.Vec3(_phase0 * math.pi * 0.2, (_phase0 + _phase1) * 0.5, _phase1 * math.pi * 0.1)
            if hg.Dist(_pos * hg.Vec3(1, 0, 1), hg.Vec3(0, 0, 0)) < _grid_size * _padding_factor then
                local _new_node
                if (i + j) % 2 == 0 then
                    _new_node, _ = CreatePhysicCubeEx(_scene, _model_size, hg.TransformationMat4(_pos, _rot), _model_ref_1, {_materials.gold}, hg.RBT_Dynamic, 0.25)
                else
                    _new_node, _ = CreatePhysicCubeEx(_scene, _model_size * 0.5, hg.TransformationMat4(_pos, _rot), _model_ref_2, {_materials.gold}, hg.RBT_Dynamic, 0.25 / 2)
                end
                table.insert(rb_nodes, _new_node)
                _y_offset = _y_offset + 0.35
            end
        end
    end
    
    return rb_nodes, camera_tv
end 