hg = require("harfang")
require("utils")
require("physics_utils")
require("sequences/wall_of_bricks")
require("sequences/tornado")
require("sequences/flocks")
require("sequences/rotating_plates")
require("sequences/wave_grid")
require("sequences/title_scene")
require("sequences/simple_cube_stack")
require("sequences/vertical_neon_chaos")
require("sequences/xi_voxel")

local res_x, res_y = 1280, 720 -- 1920, 1080

function display_physics_debug(view_id, cam, res_x, res_y, vtx_line_layout, line_shader, physics)
    hg.SetViewClear(view_id, 0, 0, 1.0, 0)
    hg.SetViewRect(view_id, 0, 0, res_x, res_y)
    local view_matrix = hg.InverseFast(cam:GetTransform():GetWorld())
    local c = cam:GetCamera()
    local projection_matrix = hg.ComputePerspectiveProjectionMatrix(c:GetZNear(), c:GetZFar(), hg.FovToZoomFactor(c:GetFov()), hg.Vec2(res_x / res_y, 1))
    hg.SetViewTransform(view_id, view_matrix, projection_matrix)
    local rs = hg.ComputeRenderState(hg.BM_Opaque, hg.DT_Disabled, hg.FC_Disabled)
    physics:RenderCollision(view_id, vtx_line_layout, line_shader, rs, 0)
end

function SetupBackgroundEnvironment(_res, _pipeline_info)
    local scene = hg.Scene()

    hg.LoadSceneFromAssets("main_stage.scn", scene, _res, _pipeline_info)
    local cam = scene:GetNode("Camera")
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
hg.AudioInit()
hg.WindowSystemInit()

-- local win = hg.RenderInit('Dreversed', res_x, res_y, hg.RF_VSync | hg.RF_MSAA4X)
win = hg.NewWindow("Dreversed^Resistance(2025)", res_x, res_y, 32, hg.WV_Undecorated) --, hg.WV_Fullscreen)
hg.RenderInit(win) --, hg.RT_OpenGL)
hg.RenderReset(res_x, res_y, hg.RF_VSync | hg.RF_MSAA4X | hg.RF_MaxAnisotropy)

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

local mat_silver = hg.CreateMaterial(pbr_shader, 'uBaseOpacityColor', hg.Vec4(1.0, 1.0, 1.0), 'uOcclusionRoughnessMetalnessColor', hg.Vec4(1, 0.55, 0.75))
hg.SetMaterialValue(mat_silver, 'uSelfColor', hg.Vec4(0, 0, 0))

local mat_chrome = hg.CreateMaterial(pbr_shader, 'uBaseOpacityColor', hg.Vec4(1.0, 1.0, 1.0), 'uOcclusionRoughnessMetalnessColor', hg.Vec4(1, 0.15, 0.75))
hg.SetMaterialValue(mat_chrome, 'uSelfColor', hg.Vec4(0, 0, 0))

local mat_black = hg.CreateMaterial(pbr_shader, 'uBaseOpacityColor', hg.Vec4(0.2, 0.2, 0.2), 'uOcclusionRoughnessMetalnessColor', hg.Vec4(1, 0.45, 0.85))
hg.SetMaterialValue(mat_black, 'uSelfColor', hg.Vec4(0, 0, 0))

-- create models
local vtx_layout = hg.VertexLayoutPosFloatNormUInt8()

-- cube
local cube_size =  hg.Vec3(0.5, 0.5, 0.5)
local cube_ref = res:AddModel('cube', hg.CreateCubeModel(vtx_layout, cube_size.x, cube_size.y, cube_size.z))

local camera_root_rot = hg.Vec3(0,0,0) -- hg.Vec3(0,hg.DegreeToRadian(20.0),0)
local camera_offset = hg.Vec3(0, 5.0, 0.0)

-- setup each sequence separately
local sequences = {}
local mapping_sequences = {    
}

-- -- blank scene
-- local couchot_intro_speech_ref = hg.LoadOGGSoundAsset("audio/intro-couchot-bw.ogg")
-- local _scene = hg.Scene()
-- hg.LoadSceneFromAssets("sequences/intro_seq.scn", _scene, res, hg.GetForwardPipelineInfo())
-- local _cam = _scene:GetNode("Camera")
-- _scene:SetCurrentCamera(_cam)
-- local _rb_nodes = {}
-- table.insert(sequences, {name = "blank", record = {}, scene = _scene, camera = _cam, camera_root = nil, nodes = _rb_nodes, physics = nil, physics_step = nil, dt_frame_step = nil})

-- title screen
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local initial_cam_pos = nil -- _cam:GetTransform():GetPos()
local title_cam_timing = nil
local _rb_nodes, _camera_tv, _ctx = SetupTitleScene(_scene, res, pipeline_info, vtx_layout, {gold = mat_gold})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "title_screen", apply_physics = ApplyPhysicsTitleScreen, ctx = _ctx, record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, camera_tv = _camera_tv, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
mapping_sequences.title_screen = {0.0, 0.8}

-- wall of bricks
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes, _ctx = SetupWallOfBricks(_scene, res, pipeline_info, vtx_layout, {neon = mat_neon_red, chrome = mat_chrome, black = mat_black})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
ApplyPhysicsWallOfBricks(_rb_nodes, _scene, _physics, _ctx)
table.insert(sequences, {name = "wall_of_bricks", record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
mapping_sequences.wall_of_bricks = {0.4, 1.0}

-- tornado
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes = SetupTornado(_scene, res, {vtx_layout = vtx_layout, materials = {chrome = mat_chrome, neon = mat_neon_red, black = mat_black}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "tornado", apply_physics = ApplyPhysicsTornado, ctx = {}, record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
mapping_sequences.tornado = {0.1, 0.9}

-- rotating plates
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes = SetupRotatingPlates(_scene, res, {vtx_layout = vtx_layout, materials = {gold = mat_gold, neon = mat_neon_red, black = mat_black}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "rotating_plates", record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
mapping_sequences.rotating_plates = {0.2, 0.8}

-- wave grid
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes = SetupWaveGrid(_scene, res, {vtx_layout = vtx_layout, materials = {gold = mat_gold, neon = mat_neon_red, black = mat_black}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "wave_grid", record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
mapping_sequences._dt_frame_step = {0.2, 0.8}

-- Simple cubes
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes = SetupSimpleCubeStack(_scene, res, {model_size = cube_size, model_ref = cube_ref, materials = {grey = mat_grey}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "simple_cubes", record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
mapping_sequences.simple_cubes = {0.1, 0.9}

-- flocks
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes = SetupFlocks(_scene, res, {vtx_layout = vtx_layout, materials = {silver = mat_silver, neon = mat_neon_red, black = mat_black}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
ApplyPhysicsFlocks(_rb_nodes, _physics)
table.insert(sequences, {name = "flocks", record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
mapping_sequences.flocks = {0.2, 0.9}

-- Voxel
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes = SetupXiVoxel(_scene, res, {vtx_layout = vtx_layout, materials = {gold = mat_gold}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "voxel", record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
mapping_sequences.voxel = {0.1, 0.9}

-- Neons
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes = SetupVerticalNeonChaos(_scene, res, {vtx_layout = vtx_layout, materials = {neon = mat_neon_red, gold = mat_gold}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "neons", record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
mapping_sequences.neons = {0.1, 0.9}

local clocks = hg.SceneClocks()
local simulation_duration_sec = 10.0

-- main loop
local keyboard = hg.Keyboard()

local records = {}
local state = "record"
local record_frame
local replay_direction

local frame = 0
local dt = hg.time_from_sec_f(1.0/60.0)

local sim_seq_idx = 1

local simulation_start_clock = hg.GetClock()
local rotation_speed_factor = 0.0

collectgarbage("stop") -- avoid nasty drops all along the demo

-- start music
local music_player_ref = nil -- hg.StreamOGGAssetStereo("audio/after-nothing-riddlemak.ogg", hg.StereoSourceState(1, hg.SR_Loop))

simulation_start_clock = hg.GetClock()

while not keyboard:Down(hg.K_Escape) and hg.IsWindowOpen(win) and sim_seq_idx <= #sequences do
    keyboard:Update()

    local frame_clock = hg.GetClock()
    dt = hg.TickClock()

    local sim_scene, sim_camera, sim_camera_root, sim_rb_nodes, sim_physics, physics_step, dt_frame_step, record
    local rep_seq, sim_seq
    
    if sim_seq_idx <= #sequences then
        sim_seq = sequences[sim_seq_idx]
        sim_scene, sim_camera, sim_camera_root, sim_rb_nodes, sim_physics, physics_step, dt_frame_step, record = sim_seq.scene, sim_seq.camera, sim_seq.camera_root, sim_seq.nodes, sim_seq.physics, sim_seq.physics_step, sim_seq.dt_frame_step, sim_seq.record
        sim_scene:SetCurrentCamera(sim_camera)
    end

    rotation_speed_factor = math.min(1.0, rotation_speed_factor + hg.time_to_sec_f(dt) * 0.1)
    camera_root_rot.y = camera_root_rot.y - math.pi * hg.time_to_sec_f(dt) * 0.15 * EaseInOutQuick(rotation_speed_factor)
    sim_camera_root:GetTransform():SetRot(camera_root_rot)

    -- Update the sim_physics simulation
    if sim_seq then
        hg.SceneUpdateSystems(sim_scene, clocks, dt_frame_step, sim_physics, physics_step, 3)
        if sim_seq.apply_physics then
            sim_seq.ctx = sim_seq.apply_physics(sim_rb_nodes, sim_scene, sim_physics, sim_seq.ctx)
        end
        -- record current sequence
        local node_idx
        local frame_nodes = {}
        for node_idx = 1, #sim_rb_nodes do
            table.insert(frame_nodes, sim_rb_nodes[node_idx]:GetTransform():GetWorld())
        end

        table.insert(sequences[sim_seq_idx].record, {t = frame_clock, frame_nodes = frame_nodes})
    end
    
    -- rendering
    local view_id = 0
    local pass_id

    -- the trick is that we always render the PREVIOUS sim_scene
    -- view_id, pass_id = hg.SubmitSceneToPipeline(view_id, p_scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res, pipeline_aaa, pipeline_aaa_config, frame)
    view_id, pass_id = hg.SubmitSceneToPipeline(view_id, sim_scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res, pipeline_aaa, pipeline_aaa_config, frame)

    -- Debug sim_physics display
    -- display_physics_debug(view_id, sequences[sim_seq_idx].camera, res_x, res_y, vtx_line_layout, line_shader, sequences[sim_seq_idx].sim_physics)

    -- collectgarbage()

    frame = hg.Frame()
    hg.UpdateWindow(win)

    if frame_clock - simulation_start_clock > hg.time_from_sec_f(simulation_duration_sec) then
        -- next sequence
        sim_seq_idx = sim_seq_idx + 1

        -- sequence timer
        simulation_start_clock = frame_clock
    end
end

hg.RenderShutdown()
hg.DestroyWindow(win)

hg.WindowSystemShutdown()
hg.InputShutdown()