hg = require("harfang")
require("physics_utils")

function SetupVerticalNeonChaos(_scene, _res, _vtx_layout, _materials)
    -- specific physics setup
    local _model_size = hg.Vec3(0.05, 3.0, 0.05)
    local _model_ref = _res:AddModel('vertical_neon_red', hg.CreateCubeModel(_vtx_layout, _model_size.x, _model_size.y, _model_size.z))
    local _grid_size = 5
    local _padding_factor = 0.25
    local _drop_height = 3
    local _y_offset = 0.0
    local _pos, _rot

    local rb_nodes = {}
    for i = -_grid_size, _grid_size do
        for j  = -_grid_size, _grid_size do
            local _phase0, _phase1 = math.sin((i + j) * 2.0 * math.pi / (_grid_size * 2)), math.cos((i + j) * 2.0 * math.pi / (_grid_size * 2))
            _pos = hg.Vec3(i * _padding_factor, _drop_height + _y_offset, j * _padding_factor)
            _rot = hg.Vec3(_phase0 * math.pi * 0.2, 0.0, _phase1 * math.pi * 0.1)
            if hg.Dist(_pos * hg.Vec3(1, 0, 1), hg.Vec3(0, 0, 0)) < _grid_size * _padding_factor then
                local _new_node, _ = CreatePhysicCubeEx(_scene, _model_size, hg.TransformationMat4(_pos, _rot), _model_ref, {_materials.neon}, hg.RBT_Dynamic, 1)
                table.insert(rb_nodes, _new_node)
                _y_offset = _y_offset + 0.25
            end
        end
    end

    _cube_size = 1.0
    _model_size = hg.Vec3(_cube_size, _cube_size, _cube_size)
    _model_ref = _res:AddModel('golden_cube', hg.CreateCubeModel(_vtx_layout,_cube_size, _cube_size, _cube_size))
    _pos.y = _pos.y + 10.0

    local _new_node, _ = CreatePhysicCubeEx(_scene, _model_size, hg.TranslationMat4(_pos * hg.Vec3(0,1,0)), _model_ref, {_materials.gold}, hg.RBT_Dynamic, 40)
    table.insert(rb_nodes, _new_node)

    return rb_nodes
end