hg = require("harfang")
require("utils")
require("physics_utils")
require("sequences/title_scene")
require("sequences/simple_cube_stack")
require("sequences/vertical_neon_chaos")
require("sequences/xi_voxel")

local ENABLE_PHYSICS_DEBUG_DISPLAY = false

function SetupBackgroundEnvironment(_res, _pipeline_info)
    local scene = hg.Scene()

    hg.LoadSceneFromAssets("main_stage.scn", scene, _res, _pipeline_info)
    local cam = scene:GetNode("Camera")
    -- local view_matrix = hg.InverseFast(cam:GetTransform():GetWorld())
    -- local c = cam:GetCamera()
    -- local projection_matrix = hg.ComputePerspectiveProjectionMatrix(c:GetZNear(), c:GetZFar(), hg.FovToZoomFactor(c:GetFov()), hg.Vec2(res_x / res_y, 1))
    scene:SetCurrentCamera(cam)
    
    local camera_root = scene:GetNode("camera_root")

    return scene, cam, camera_root
end

function SetupScenePhysics(_scene, freq)
    -- enable scene physics
    freq = freq or 120.0
    local physics = hg.SceneBullet3Physics()
    physics:SceneCreatePhysicsFromAssets(_scene)
    local physics_step = hg.time_from_sec_f(1.0 / freq)
    local dt_frame_step = hg.time_from_sec_f(1.0 / freq)

    return physics, physics_step, dt_frame_step
end

hg.AddAssetsFolder('assets_compiled')

-- main window
hg.InputInit()
hg.WindowSystemInit()

local res_x, res_y = 1280, 720
local win = hg.RenderInit('Dreversed', res_x, res_y, hg.RF_VSync | hg.RF_MSAA4X)

local pipeline = hg.CreateForwardPipeline(2048)
local res = hg.PipelineResources()
local pipeline_info = hg.GetForwardPipelineInfo()

local pipeline_aaa_config = hg.ForwardPipelineAAAConfig()
local pipeline_aaa = hg.CreateForwardPipelineAAAFromAssets("core", pipeline_aaa_config, hg.BR_Equal, hg.BR_Equal)

pipeline_aaa_config.motion_blur = 2.0
pipeline_aaa_config.sample_count = 1
pipeline_aaa_config.z_thickness = 0.25
pipeline_aaa_config.exposure = 1.2
pipeline_aaa_config.gamma = 1.8
pipeline_aaa_config.bloom_intensity	= 0.2500
pipeline_aaa_config.bloom_threshold	= 0.5200
-- pipeline_aaa_config.dof_focus_point = 3.85 -- Distance to the focus point (in meters)
-- pipeline_aaa_config.dof_focus_length = 20.0 -- Depth of field (in meters); smaller values result in a narrower focused area.

-- physics debug
local vtx_line_layout = hg.VertexLayoutPosFloatColorUInt8()
local line_shader = hg.LoadProgramFromAssets("shaders/pos_rgb")

-- create material
local pbr_shader = hg.LoadPipelineProgramRefFromAssets('core/shader/pbr.hps', res, hg.GetForwardPipelineInfo())

local mat_grey = hg.CreateMaterial(pbr_shader, 'uBaseOpacityColor', hg.Vec4(1, 1, 1), 'uOcclusionRoughnessMetalnessColor', hg.Vec4(1, 0.5, 0.05))
hg.SetMaterialValue(mat_grey, 'uSelfColor', hg.Vec4(0, 0, 0))

local mat_neon_red = hg.CreateMaterial(pbr_shader, 'uBaseOpacityColor', hg.Vec4(1, 0.1, 0.1), 'uSelfColor', hg.Vec4(15.0, 0.2, 0.01))
hg.SetMaterialValue(mat_neon_red, 'uOcclusionRoughnessMetalnessColor', hg.Vec4(1, 0.5, 0.05))

local mat_gold = hg.CreateMaterial(pbr_shader, 'uBaseOpacityColor', hg.Vec4(1, 0.9, 0.0), 'uOcclusionRoughnessMetalnessColor', hg.Vec4(1, 0.35, 0.75))
hg.SetMaterialValue(mat_gold, 'uSelfColor', hg.Vec4(0, 0, 0))

-- create models
local vtx_layout = hg.VertexLayoutPosFloatNormUInt8()

-- cube
local cube_size =  hg.Vec3(0.5, 0.5, 0.5)
local cube_ref = res:AddModel('cube', hg.CreateCubeModel(vtx_layout, cube_size.x, cube_size.y, cube_size.z))

local camera_root_rot = hg.Vec3(0,0,0)

-- setup each sequence separately
local sequences = {}

-- blank scene
local _scene = hg.Scene()
local _cam = hg.CreateCamera(_scene, hg.TranslationMat4(hg.Vec3(0,0,0)), 0.1, 100.0)
local _camera_root = _scene:CreateNode()
_camera_root:SetName("camera_root")
_camera_root:SetTransform(_scene:CreateTransform())
-- local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes = {}
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})


-- title screen
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes = SetupTitleScene(_scene, res, pipeline_info, vtx_layout, {gold = mat_gold})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})

-- Simple cubes
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes = SetupSimpleCubeStack(_scene, res, {model_size = cube_size, model_ref = cube_ref, materials = {grey = mat_grey}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})

-- Voxel
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes = SetupXiVoxel(_scene, res, {vtx_layout = vtx_layout, materials = {gold = mat_gold}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})

-- Neons
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes = SetupVerticalNeonChaos(_scene, res, {vtx_layout = vtx_layout, materials = {neon = mat_neon_red, gold = mat_gold}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})

local clocks = hg.SceneClocks()
local sequence_duration_sec = 10.0

-- main loop
local keyboard = hg.Keyboard()

local records = {}
local state = "record"
local record_frame
local replay_direction

local frame = 0
local dt = hg.time_from_sec_f(1.0/60.0)

local ps, cs = 1, 2 -- previous sequence, current sequence

local sequence_start_clock = hg.GetClock()

while not keyboard:Down(hg.K_Escape) and hg.IsWindowOpen(win) do
    keyboard:Update()

    local frame_clock = hg.GetClock()

    if frame_clock - sequence_start_clock > hg.time_from_sec_f(sequence_duration_sec) then
        cs = cs + 1
        ps = cs - 1
        sequence_start_clock = frame_clock
    end

    local p_scene, p_cam, p_camera_root, p_rb_nodes, p_physics, p_physics_step, p_dt_frame_step, p_record
    local scene, cam, camera_root, rb_nodes, physics, physics_step, dt_frame_step, record
    local _ps, _cs

    _ps = sequences[ps]
    p_scene, p_cam, p_camera_root, p_rb_nodes, p_physics, p_physics_step, p_dt_frame_step, p_record = _ps.scene, _ps.camera, _ps.camera_root, _ps.nodes, _ps.physics, _ps.physics_step, _ps.dt_frame_step, _ps.record
    
    if cs <= #sequences then
        _cs = sequences[cs]
        scene, cam, camera_root, rb_nodes, physics, physics_step, dt_frame_step, record = _cs.scene, _cs.camera, _cs.camera_root, _cs.nodes, _cs.physics, _cs.physics_step, _cs.dt_frame_step, _cs.record
    end

    p_scene:SetCurrentCamera(p_cam)

    dt = hg.TickClock()
    camera_root_rot.y = camera_root_rot.y - math.pi * hg.time_to_sec_f(dt) * 0.15
    p_camera_root:GetTransform():SetRot(camera_root_rot)

    hg.SceneUpdateSystems(p_scene, clocks, p_dt_frame_step, p_physics, p_physics_step, 3)
    if _cs then 
        hg.SceneUpdateSystems(scene, clocks, dt_frame_step, physics, physics_step, 3)

        -- record current sequence
        local node_idx
        local frame_nodes = {}
        for node_idx = 1, #rb_nodes do
            table.insert(frame_nodes, rb_nodes[node_idx]:GetTransform():GetWorld())
        end

        table.insert(sequences[cs].record, {t = frame_clock, frame_nodes = frame_nodes})
    end

    local view_id = 0
    local pass_id

    -- replay previous sequence
    local previous_record = sequences[ps].record
    local previous_nodes = sequences[ps].nodes
    local previous_scene = sequences[ps].scene
    local previous_physics = sequences[ps].physics
    local previous_dt_frame_step = sequences[ps].dt_frame_step
    local previous_physics_step = sequences[ps].physics_step
    record_frame = map(hg.time_to_sec_f(frame_clock - sequence_start_clock), 0.0, sequence_duration_sec, 1.0, 0.0)
    record_frame = math.max(1, math.floor(record_frame * #previous_record))
    for node_idx = 1, #previous_nodes do
        previous_physics:NodeTeleport(previous_nodes[node_idx], previous_record[record_frame].frame_nodes[node_idx])
        previous_physics:NodeResetWorld(previous_nodes[node_idx], previous_record[record_frame].frame_nodes[node_idx])
    end
    
    -- rendering
    -- the trick is that we always render the PREVIOUS scene
    view_id, pass_id = hg.SubmitSceneToPipeline(view_id, p_scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res, pipeline_aaa, pipeline_aaa_config, frame)

    -- Debug physics display
    if ENABLE_PHYSICS_DEBUG_DISPLAY then
        hg.SetViewClear(view_id, 0, 0, 1.0, 0)
        hg.SetViewRect(view_id, 0, 0, res_x, res_y)
        view_matrix = hg.InverseFast(cam:GetTransform():GetWorld())
        c = cam:GetCamera()
        projection_matrix = hg.ComputePerspectiveProjectionMatrix(c:GetZNear(), c:GetZFar(), hg.FovToZoomFactor(c:GetFov()), hg.Vec2(res_x / res_y, 1))
        hg.SetViewTransform(view_id, view_matrix, projection_matrix)
        rs = hg.ComputeRenderState(hg.BM_Opaque, hg.DT_Disabled, hg.FC_Disabled)
        physics:RenderCollision(view_id, vtx_line_layout, line_shader, rs, 0)
    end

    frame = hg.Frame()
    hg.UpdateWindow(win)
end

scene:Clear()
scene:GarbageCollect()

hg.RenderShutdown()
hg.DestroyWindow(win)

hg.WindowSystemShutdown()
hg.InputShutdown()