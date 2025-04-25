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
require("sequences/repulsion_core")
require("sequences/oscillating_wall")
require("sequences/attraction_core")
require("audio/bass_dynamics")
require("audio/drums_dynamics")
require("audio/audio_data")

local virtual_res_x, virtual_res_y = 1280, 720
local res_x, res_y = 1280, 720 -- math.floor(1920 * 0.6), math.floor(1080 * 0.6) -- 1920, 1080
local enable_replay = true
local enable_rotation = true

function GetAudioDynamics(dynamics_table, clock, total_duration)
    local idx = math.floor((clock * #dynamics_table) / total_duration) + 1
    idx = math.min(idx, #dynamics_table)
    return clamp(dynamics_table[idx], 0.0, 1.0)
end

function display_shadow_text(view_id, font_name, text_str, font_prg, text_pos, text_uniform_values, text_uniform_values_black, text_render_state, h_align)
    h_align = h_align or hg.DTHA_Left
    hg.DrawText(view_id, font_name, text_str, font_prg, 'u_tex', 0, hg.Mat4.Identity,
        text_pos +  hg.Vec3(2, 2, 0) * (res_y / virtual_res_y), h_align, hg.DTVA_Center, text_uniform_values_black, {}, text_render_state)

    hg.DrawText(view_id, font_name, text_str, font_prg, 'u_tex', 0, hg.Mat4.Identity,
        text_pos, h_align, hg.DTVA_Center, text_uniform_values, {}, text_render_state)    
end

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
hg.RenderReset(res_x, res_y, hg.RF_VSync) -- | hg.RF_MSAA4X | hg.RF_MaxAnisotropy)

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

-- fonts
local font_timer = hg.LoadFontFromAssets('fonts/spacemono-regular.ttf', math.floor(48 * (res_y / virtual_res_y)))
local font_sequence_name = hg.LoadFontFromAssets('fonts/cirrus_cumulus.ttf', math.floor(96 * (res_y / virtual_res_y)))
local font_prg = hg.LoadProgramFromAssets('core/shader/font')
local text_uniform_values = {hg.MakeUniformSetValue('u_color', hg.Vec4(1, 1, 1))}
local text_uniform_values_red = {hg.MakeUniformSetValue('u_color', hg.Vec4(0.9, 0.2, 0.0))}
local text_uniform_values_black = {hg.MakeUniformSetValue('u_color', hg.Vec4(0.1, 0.1, 0.1))}
local text_render_state = hg.ComputeRenderState(hg.BM_Alpha, hg.DT_Always, hg.FC_Disabled)

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

-- demo soundtrack
local demo_soundtrack_sound = hg.LoadOGGSoundAsset("audio/after-nothing-riddlemak.ogg")
local demo_soundtrack_ref = nil

-- blank scene
-- local couchot_intro_speech_ref = hg.LoadOGGSoundAsset("audio/intro-couchot-bw.ogg")
local intro_scene = hg.Scene()
hg.LoadSceneFromAssets("sequences/intro_seq.scn", intro_scene, res, hg.GetForwardPipelineInfo())
local intro_camera = intro_scene:GetNode("Camera")
intro_scene:SetCurrentCamera(intro_camera)

-- title screen
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local initial_cam_pos = nil -- _cam:GetTransform():GetPos()
local title_cam_timing = nil
local _rb_nodes, _camera_tv, _ctx = SetupTitleScene(_scene, res, pipeline_info, vtx_layout, {gold = mat_gold})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "title_screen", apply_physics = ApplyPhysicsTitleScreen, ctx = _ctx, record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, camera_tv = _camera_tv, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
table.insert(mapping_sequences, {clock = {0.0, 5.0}, time_remap = {#sequences, 1.0, 0.25}})
table.insert(mapping_sequences, {clock = {5.0, 10.0}, time_remap = {#sequences, 0.25, 0.8}})

-- wall of bricks
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes, _ctx = SetupWallOfBricks(_scene, res, pipeline_info, vtx_layout, {neon = mat_neon_red, chrome = mat_chrome, black = mat_black})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
ApplyPhysicsWallOfBricks(_rb_nodes, _scene, _physics, _ctx)
table.insert(sequences, {name = "wall_of_bricks", record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
table.insert(mapping_sequences, {clock = {10.0, 15.0}, time_remap = {#sequences, 0.0, 1.0}})
table.insert(mapping_sequences, {clock = {15.0, 20.0}, time_remap = {#sequences, 1.0, 0.0}})

-- tornado
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes = SetupTornado(_scene, res, {vtx_layout = vtx_layout, materials = {chrome = mat_chrome, neon = mat_neon_red, black = mat_black}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "tornado", apply_physics = ApplyPhysicsTornado, ctx = {}, record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
table.insert(mapping_sequences, {clock = {20.0, 30.0}, time_remap = {#sequences, 0.1, 0.9}})

-- rotating plates
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes = SetupRotatingPlates(_scene, res, {vtx_layout = vtx_layout, materials = {gold = mat_gold, neon = mat_neon_red, black = mat_black}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "rotating_plates", record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
table.insert(mapping_sequences, {clock = {30.0, 40.0}, time_remap = {#sequences, 0.2, 0.8}})

-- wave grid
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes = SetupWaveGrid(_scene, res, {vtx_layout = vtx_layout, materials = {gold = mat_gold, neon = mat_neon_red, black = mat_black}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "wave_grid", record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
table.insert(mapping_sequences, {clock = {40.0, 50.0}, time_remap = {#sequences, 0.2, 0.8}})

-- Simple cubes
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes = SetupSimpleCubeStack(_scene, res, {model_size = cube_size, model_ref = cube_ref, materials = {grey = mat_grey}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "simple_cubes", record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
table.insert(mapping_sequences, {clock = {50.0, 60.0}, time_remap = {#sequences, 0.1, 0.9}})

-- flocks
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes = SetupFlocks(_scene, res, {vtx_layout = vtx_layout, materials = {silver = mat_silver, neon = mat_neon_red, black = mat_black}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
ApplyPhysicsFlocks(_rb_nodes, _physics)
table.insert(sequences, {name = "flocks", record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
table.insert(mapping_sequences, {clock = {60.0, 70.0}, time_remap = {#sequences, 0.2, 0.9}})

-- Voxel
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes = SetupXiVoxel(_scene, res, {vtx_layout = vtx_layout, materials = {gold = mat_gold}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "voxel", record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
table.insert(mapping_sequences, {clock = {70.0, 80.0}, time_remap = {#sequences, 0.1, 0.9}})

-- Neons
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes = SetupVerticalNeonChaos(_scene, res, {vtx_layout = vtx_layout, materials = {neon = mat_neon_red, gold = mat_gold}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "neons", record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
table.insert(mapping_sequences, {clock = {80.0, 90.0}, time_remap = {#sequences, 0.1, 0.9}})

-- GPT 3
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes, _ctx = SetupOscillatingWall(_scene, res, {vtx_layout = vtx_layout, materials = {neon = mat_neon_red, black = mat_black}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "oscillating_wall", apply_physics = ApplyPhysicsOscillatingWall, ctx = {}, record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
table.insert(mapping_sequences, {clock = {90.0, 100.0}, time_remap = {#sequences, 0.0, 1.0}})

-- GPT 4
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes, _ctx = SetupRepulsionCore(_scene, res, {vtx_layout = vtx_layout, materials = {silver = mat_silver}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "repulsion_core", apply_physics = ApplyPhysicsRepulsionCore, ctx = {}, record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
table.insert(mapping_sequences, {clock = {100.0, 110.0}, time_remap = {#sequences, 0.0, 1.0}})

-- GPT 4-ish
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes, _ctx = SetupAttractionCore(_scene, res, {vtx_layout = vtx_layout, materials = {gold = mat_gold}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "attraction_core", apply_physics = ApplyPhysicsAttractionCore, ctx = {}, record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
table.insert(mapping_sequences, {clock = {110.0, 120.0}, time_remap = {#sequences, 0.3, 0.0}})

-- last dummy sequence
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes, _ctx = {}, {}
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "dummy", ctx = {}, record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
local _last_clock = mapping_sequences[#mapping_sequences].clock[2]
table.insert(mapping_sequences, {clock = {_last_clock, _last_clock + 10.0}, time_remap = {#sequences, 0.0, 1.0}})

-- Prepare the time remapping table for the whole demo
local presampling_framerate = 60.0
local demo_duration = mapping_sequences[#mapping_sequences].clock[2]
local replay_time_table = {}
for i = 0, math.floor(demo_duration * presampling_framerate) do
    local _clock = i / presampling_framerate
    local _new_frame = {}
    -- search for the proper sequence
    for j = 1, #mapping_sequences do
        if _clock >= mapping_sequences[j].clock[1] and _clock < mapping_sequences[j].clock[2] then
            _new_frame.sequence_idx =  mapping_sequences[j].time_remap[1]
            _new_frame.remap_from = {mapping_sequences[j].clock[1], mapping_sequences[j].clock[2]}
            _new_frame.remap_to = {mapping_sequences[j].time_remap[2], mapping_sequences[j].time_remap[3]}
            break
        end
    end
    table.insert(replay_time_table, _new_frame)
end

-- cleanup sequence names
for i = 1, #sequences do
    local _str = string.gsub(sequences[i].name, "_", " ")
    -- _str = string.upper(string.sub(_str, 1, 1)) .. string.sub(_str, 2)
    sequences[i].display_name = _str
end

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

local sim_seq_idx = 1 -- index of the simulation sequence
local rep_seq_idx = 0 -- index of the replay sequence

local simulation_start_clock = hg.GetClock()
local demo_start_clock = simulation_start_clock
local demo_clock_f = nil
local replay_clock_f =  nil
local rotation_speed_factor = 0.0

collectgarbage("stop") -- avoid nasty drops all along the demo

-- start music
-- local music_player_ref = hg.StreamOGGAssetStereo("audio/after-nothing-riddlemak.ogg", hg.StereoSourceState(1, hg.SR_Loop))

if enable_replay then
    intro_scene:PlayAnim(intro_scene:GetSceneAnim("intro"))
end

-- tv_player_ref = hg.StreamOGGAssetStereo("audio/crt-tv-powering-up.ogg", hg.StereoSourceState(1, hg.SR_Once))

while not keyboard:Down(hg.K_Escape) and hg.IsWindowOpen(win) and sim_seq_idx <= #sequences do
    keyboard:Update()

    local frame_clock = hg.GetClock()
    demo_clock_f = hg.time_to_sec_f(frame_clock - demo_start_clock)
    replay_clock_f =  demo_clock_f - 10.0
    dt = hg.TickClock()

    local greyscale = 0.0 -- math.sin(replay_clock_f * math.pi)
    local hilight = GetAudioDynamics(drums_dynamics, math.max(0.0, replay_clock_f), audio_metadata['after-nothing-riddlemak.ogg'].duration) -- math.cos(frame_clock_f * math.pi / 4)
    local compress = GetAudioDynamics(bass_dynamics, math.max(0.0, replay_clock_f), audio_metadata['after-nothing-riddlemak.ogg'].duration) -- math.cos(frame_clock_f * math.pi * 2)
    local ambient_control = hg.Color(greyscale, hilight, compress, 0.0)

    -- SIMULATION
    -- process & record simulation (realtime)
    local sim_scene, sim_camera, sim_camera_root, sim_rb_nodes, sim_physics, physics_step, dt_frame_step, record
    local rep_seq, sim_seq
    
    if sim_seq_idx <= #sequences then
        sim_seq = sequences[sim_seq_idx]
        sim_scene, sim_camera, sim_camera_root, sim_rb_nodes, sim_physics, physics_step, dt_frame_step, record = sim_seq.scene, sim_seq.camera, sim_seq.camera_root, sim_seq.nodes, sim_seq.physics, sim_seq.physics_step, sim_seq.dt_frame_step, sim_seq.record
        -- sim_scene:SetCurrentCamera(sim_camera)
    end

    if enable_rotation and sim_seq_idx > 1 then
        rotation_speed_factor = math.min(1.0, rotation_speed_factor + hg.time_to_sec_f(dt) * 0.1)
        camera_root_rot.y = camera_root_rot.y - math.pi * hg.time_to_sec_f(dt) * 0.15 * EaseInOutQuick(rotation_speed_factor)
    end
    sim_camera_root:GetTransform():SetRot(camera_root_rot)

    -- Update the physics simulation
    if sim_seq then
        hg.SceneUpdateSystems(sim_scene, clocks, dt_frame_step, sim_physics, physics_step, 3)
        if sim_seq.apply_physics then
            sim_seq.ctx = sim_seq.apply_physics(sim_rb_nodes, sim_scene, sim_physics, sim_seq.ctx)
        end

        -- record the physics simulation
        local node_idx
        local frame_nodes = {}
        for node_idx = 1, #sim_rb_nodes do
            table.insert(frame_nodes, sim_rb_nodes[node_idx]:GetTransform():GetWorld())
        end

        table.insert(sequences[sim_seq_idx].record, {t = frame_clock, frame_nodes = frame_nodes})
    end
    -- END SIMULATION

    -- REPLAY
    -- replay previous sequence
    local rep_scene, rep_camera, rep_camera_root, rep_rb_nodes, rep_physics, rep_physics_step, rep_dt_frame_step, rep_record
    local time_remap_index = math.floor((replay_clock_f * #replay_time_table) / demo_duration) + 1
    -- tostring(time_remap_index) .. ":" .. replay_time_table[time_remap_index].sequence_idx .. ":" .. string.format("%2.2f", replay_time_table[time_remap_index].remap_from)

    if sim_seq_idx > 1 then
        -- play music
        if demo_soundtrack_ref == nil then
            demo_soundtrack_ref = hg.PlayStereo(demo_soundtrack_sound, hg.StereoSourceState(1, hg.SR_Once))
        end

        rep_seq_idx = replay_time_table[time_remap_index].sequence_idx
        rep_record = sequences[rep_seq_idx].record
        rep_rb_nodes = sequences[rep_seq_idx].nodes
        rep_scene = sequences[rep_seq_idx].scene
        rep_camera = sequences[rep_seq_idx].camera
        rep_camera_root = sequences[rep_seq_idx].camera_root

        -- record_frame = map(replay_time_table[time_remap_index].remap_from, 0.0, 10.0, replay_time_table[time_remap_index].remap_to[1], replay_time_table[time_remap_index].remap_to[2])
        record_frame = map(replay_clock_f, replay_time_table[time_remap_index].remap_from[1], replay_time_table[time_remap_index].remap_from[2], replay_time_table[time_remap_index].remap_to[1], replay_time_table[time_remap_index].remap_to[2])
        local record_frame_f = record_frame * #rep_record
        local record_frame_int = math.max(1, math.floor(record_frame_f))
        local lerp_coef = record_frame_f - record_frame_int
        local _mat
        local next_record_frame = clamp(record_frame_int + 1, 1, #rep_record)
        if enable_replay then
            for node_idx = 1, #rep_rb_nodes do
                _mat = hg.LerpAsOrthonormalBase(rep_record[record_frame_int].frame_nodes[node_idx], rep_record[next_record_frame].frame_nodes[node_idx], lerp_coef)
                rep_rb_nodes[node_idx]:GetTransform():SetWorld(_mat)
            end

            rep_camera_root:GetTransform():SetRot(camera_root_rot)

            sequences[rep_seq_idx].scene:Update(dt)
        end
    else
        intro_scene:Update(dt)
    end
    -- END REPLAY
    
    -- rendering
    local view_id = 0
    local pass_id

    -- the trick is that we always render the PREVIOUS sim_scene
    if enable_replay then
        if sim_seq_idx > 1 then
            rep_scene:SetCurrentCamera(rep_camera)
            rep_scene.environment.ambient = ambient_control
            view_id, pass_id = hg.SubmitSceneToPipeline(view_id, rep_scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res, pipeline_aaa, pipeline_aaa_config, frame)
        else
            intro_scene:SetCurrentCamera(intro_camera)
            intro_scene.environment.ambient = ambient_control
            view_id, pass_id = hg.SubmitSceneToPipeline(view_id, intro_scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res, pipeline_aaa, pipeline_aaa_config, frame)
        end
    else
        sim_scene:SetCurrentCamera(sim_camera)
        sim_scene.environment.ambient = ambient_control
        view_id, pass_id = hg.SubmitSceneToPipeline(view_id, sim_scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res, pipeline_aaa, pipeline_aaa_config, frame)
    end

    -- Debug sim_physics display
    -- display_physics_debug(view_id, sequences[sim_seq_idx].camera, res_x, res_y, vtx_line_layout, line_shader, sequences[sim_seq_idx].physics)

    -- collectgarbage()

    -- DEBUG INFOS
    -- write sequence name
    view_id = view_id + 1
    hg.SetView2D(view_id, 0, 0, res_x, res_y, -1, 1, hg.CF_Depth, hg.Color.White, 1, 0)

    if enable_replay == false then
        local _seq_name = sim_seq.display_name
        local _text_pos = hg.Vec3(res_x * 0.05, res_y * 0.9, 0)
        display_shadow_text(view_id, font_sequence_name, _seq_name, font_prg, _text_pos, text_uniform_values, text_uniform_values_black, text_render_state) 
    end

    -- Timecode
    local _str_clock = format_time(demo_clock_f)
    _text_pos = hg.Vec3(res_x * (1.0 - 0.05), res_y * 0.9, 0)

    local timer_uniform_values = text_uniform_values_red
    if sim_seq_idx > 1 then
        timer_uniform_values = text_uniform_values
    end
    display_shadow_text(view_id, font_timer, _str_clock, font_prg, _text_pos, timer_uniform_values, text_uniform_values_black, text_render_state, hg.DTHA_Right)

    -- Raw clocks
    local _str_clock = string.format("%3.5f", demo_clock_f) .. " / " .. string.format("%3.5f", demo_clock_f - (sim_seq_idx - 1.0) * 10.0)
    _text_pos = hg.Vec3(res_x * (1.0 - 0.05), res_y * 0.95, 0)
    display_shadow_text(view_id, font_timer, _str_clock, font_prg, _text_pos, text_uniform_values, text_uniform_values_black, text_render_state, hg.DTHA_Right)


    -- Time remap (time code)
    if sim_seq_idx > 1 then
        local _str_clock = "Time remap: " .. tostring(time_remap_index) .. ":" .. replay_time_table[time_remap_index].sequence_idx .. ":" .. string.format("%2.3f", record_frame)
        _text_pos = hg.Vec3(res_x * (1.0 - 0.05), res_y * (1.0 - 0.925), 0)
        display_shadow_text(view_id, font_timer, _str_clock, font_prg, _text_pos, text_uniform_values, text_uniform_values_black, text_render_state, hg.DTHA_Right)
    end
    -- END DEBUG INFOS

    frame = hg.Frame()
    hg.UpdateWindow(win)

    if frame_clock - simulation_start_clock > hg.time_from_sec_f(simulation_duration_sec) then
        -- disable rigid bodies for all the nodes of this sequence
        local node_idx
        local frame_nodes = {}
        local rb_nodes = sequences[sim_seq_idx].nodes
        local _physics = sequences[sim_seq_idx].physics
        for node_idx = 1, #rb_nodes do
            _physics:NodeDestroyPhysics(rb_nodes[node_idx])
        end

        -- next sequence
        sim_seq_idx = sim_seq_idx + 1
        -- rep_seq_idx = rep_seq_idx + 1

        -- sequence timer
        simulation_start_clock = frame_clock
    end
end

hg.RenderShutdown()
hg.DestroyWindow(win)

hg.WindowSystemShutdown()
hg.InputShutdown()