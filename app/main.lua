hg = require("harfang")
require("physics_utils")
require("sequences/title_scene")
require("sequences/simple_cube_stack")
require("sequences/vertical_neon_chaos")
require("sequences/xi_voxel")

hg.AddAssetsFolder('assets_compiled')

-- main window
hg.InputInit()
hg.WindowSystemInit()

local res_x, res_y = 1280, 720
local win = hg.RenderInit('Physics Test', res_x, res_y, hg.RF_VSync | hg.RF_MSAA4X)

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

-- setup the scene
local scene = hg.Scene()

hg.LoadSceneFromAssets("main_stage.scn", scene, res, pipeline_info)
local cam = scene:GetNode("Camera")
local view_matrix = hg.InverseFast(cam:GetTransform():GetWorld())
local c = cam:GetCamera()
local projection_matrix = hg.ComputePerspectiveProjectionMatrix(c:GetZNear(), c:GetZFar(), hg.FovToZoomFactor(c:GetFov()), hg.Vec2(res_x / res_y, 1))
scene:SetCurrentCamera(cam)

local camera_root = scene:GetNode("camera_root")
local camera_root_rot = camera_root:GetTransform():GetRot()

--- call setup here
-- local rb_nodes = SetupSimpleCubeStack(scene, cube_size, cube_ref, mat_grey)
-- local rb_nodes = SetupXiVoxel(scene, res, vtx_layout, mat_gold)
-- local rb_nodes = SetupVerticalNeonChaos(scene, res, vtx_layout, {neon = mat_neon_red, gold = mat_gold})
local rb_nodes = SetupTitleScene(scene, res, pipeline_info)

-- enable scene physics
local physics = hg.SceneBullet3Physics()
physics:SceneCreatePhysicsFromAssets(scene)
local physics_step = hg.time_from_sec_f(1 / 120)
local dt_frame_step = hg.time_from_sec_f(1 / 120)

local clocks = hg.SceneClocks()

-- description
hg.SetLogLevel(hg.LL_Normal)

-- main loop
local keyboard = hg.Keyboard()

local records = {}
local state = "record"
local record_frame = 1
local replay_direction

local frame = 0
local dt = hg.time_from_sec_f(1.0/60.0)

while not keyboard:Down(hg.K_Escape) and hg.IsWindowOpen(win) do
    keyboard:Update()

    dt = hg.TickClock()
    camera_root_rot.y = camera_root_rot.y - math.pi * hg.time_to_sec_f(dt) * 0.15
    camera_root:GetTransform():SetRot(camera_root_rot)

    hg.SceneUpdateSystems(scene, clocks, dt_frame_step, physics, physics_step, 3)
 
    -- physics:NodeWake(chair_node)
    local view_id = 0
    local pass_id

    if state == "record" then
        local node_idx
        local frame_nodes = {}
        for node_idx = 1, #rb_nodes do
            table.insert(frame_nodes, rb_nodes[node_idx]:GetTransform():GetWorld())
        end

        hg.TickClock()
        local current_clock = hg.GetClock()
        table.insert(records, {t = current_clock, frame_nodes = frame_nodes})

        if current_clock > hg.time_from_sec_f(10.0) then
            state = "replay"
            replay_direction = -1
            record_frame = #records
        end
    elseif state == "replay" then
        for node_idx = 1, #rb_nodes do
            physics:NodeTeleport(rb_nodes[node_idx], records[record_frame].frame_nodes[node_idx])
            physics:NodeResetWorld(rb_nodes[node_idx], records[record_frame].frame_nodes[node_idx])
        end

        record_frame = record_frame + replay_direction
        if replay_direction < 0 and record_frame < 1 then
            record_frame = 1
            replay_direction = 1
        elseif replay_direction > 0 and record_frame > #records then
            record_frame = #records
            replay_direction = -1
        end
    end

    -- rendering
    view_id, pass_id = hg.SubmitSceneToPipeline(view_id, scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res, pipeline_aaa, pipeline_aaa_config, frame)

    -- -- Debug physics display
    -- hg.SetViewClear(view_id, 0, 0, 1.0, 0)
    -- hg.SetViewRect(view_id, 0, 0, res_x, res_y)
    -- view_matrix = hg.InverseFast(cam:GetTransform():GetWorld())
    -- c = cam:GetCamera()
    -- projection_matrix = hg.ComputePerspectiveProjectionMatrix(c:GetZNear(), c:GetZFar(), hg.FovToZoomFactor(c:GetFov()), hg.Vec2(res_x / res_y, 1))
    -- hg.SetViewTransform(view_id, view_matrix, projection_matrix)
    -- rs = hg.ComputeRenderState(hg.BM_Opaque, hg.DT_Disabled, hg.FC_Disabled)
    -- physics:RenderCollision(view_id, vtx_line_layout, line_shader, rs, 0)

    frame = hg.Frame()
    hg.UpdateWindow(win)
end

scene:Clear()
scene:GarbageCollect()

hg.RenderShutdown()
hg.DestroyWindow(win)

hg.WindowSystemShutdown()
hg.InputShutdown()