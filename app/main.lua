hg = require("harfang")
require("utils")
require("physics_utils")
require("sequences/wall_of_bricks")

require("sequences/tornado")
require("sequences/spiral_tornado")
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
require("sequences/invisible_colliders")

require("audio/bass_dynamics")
require("audio/drums_dynamics")
require("audio/audio_data")

-- greetings
-- DrFlopine, NuSan, Stil

virtual_res_x, virtual_res_y = 1280, 720
res_x, res_y = 1280, 720 -- math.floor(1920 * 0.6), math.floor(1080 * 0.6) -- 1920, 1080
enable_replay = true
enable_rotation = true
enable_aaa = true

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

pipeline = hg.CreateForwardPipeline(2048)
res = hg.PipelineResources()
pipeline_info = hg.GetForwardPipelineInfo()
pipeline_aaa_config = hg.ForwardPipelineAAAConfig()
pipeline_aaa = hg.CreateForwardPipelineAAAFromAssets("core", pipeline_aaa_config, hg.BR_Half, hg.BR_Half)

pipeline_aaa_config.motion_blur = 2.0
pipeline_aaa_config.sample_count = 1
pipeline_aaa_config.z_thickness = 0.25
pipeline_aaa_config.exposure = 1.2
pipeline_aaa_config.gamma = 1.8
pipeline_aaa_config.bloom_intensity	= 0.2500
pipeline_aaa_config.bloom_threshold	= 0.5200

-- fonts
font_timer = hg.LoadFontFromAssets('fonts/spacemono-regular.ttf', math.floor(48 * (res_y / virtual_res_y)))
font_sequence_name = hg.LoadFontFromAssets('fonts/cirrus_cumulus.ttf', math.floor(96 * (res_y / virtual_res_y)))
font_prg = hg.LoadProgramFromAssets('core/shader/font')
text_uniform_values = {hg.MakeUniformSetValue('u_color', hg.Vec4(1, 1, 1))}
text_uniform_values_red = {hg.MakeUniformSetValue('u_color', hg.Vec4(0.9, 0.2, 0.0))}
text_uniform_values_black = {hg.MakeUniformSetValue('u_color', hg.Vec4(0.1, 0.1, 0.1))}
text_render_state = hg.ComputeRenderState(hg.BM_Alpha, hg.DT_Always, hg.FC_Disabled)

-- physics debug
vtx_line_layout = hg.VertexLayoutPosFloatColorUInt8()
line_shader = hg.LoadProgramFromAssets("shaders/pos_rgb")

-- create material
pbr_shader = hg.LoadPipelineProgramRefFromAssets('core/shader/pbr.hps', res, hg.GetForwardPipelineInfo())

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

local mat_piano_black = hg.CreateMaterial(pbr_shader, 'uBaseOpacityColor', hg.Vec4(1.75, 1.75, 1.75), 'uOcclusionRoughnessMetalnessColor', hg.Vec4(1, 0.05, 0.95))
hg.SetMaterialValue(mat_piano_black, 'uSelfColor', hg.Vec4(0, 0, 0))

-- create models
local vtx_layout = hg.VertexLayoutPosFloatNormUInt8()

-- cube
local cube_size =  hg.Vec3(0.5, 0.5, 0.5)
local cube_ref = res:AddModel('cube', hg.CreateCubeModel(vtx_layout, cube_size.x, cube_size.y, cube_size.z))

local camera_root_rot = hg.Vec3(0,0,0) -- hg.Vec3(0,hg.DegreeToRadian(20.0),0)
local camera_offset = hg.Vec3(0, 5.0, 0.0)

-- setup each sequence separately
sequences = {}
mapping_sequences = {
}

seq_idx = {
    title_screen = 1,
    rotating_plates = 2,
    wave_grid = 3,
    wall_of_bricks = 4,
    neons = 5,
    simple_cubes = 6,
    oscillating_wall = 7,
    invisible_colliders = 8,
    tornado = 9,
    repulsion_core = 10,
    attraction_core = 11,
    voxel = 12,
    flocks = 13,
    spiral_tornado = 14
}

-- demo soundtrack
local crt_power_sound = hg.LoadOGGSoundAsset("audio/crt-tv-powering-up.ogg")
local crt_power_ref = nil
local couchot_intro_speech_sound = hg.LoadOGGSoundAsset("audio/intro-couchot-bw.ogg")
local couchot_intro_speech_ref = nil
local demo_soundtrack_sound = hg.LoadOGGSoundAsset("audio/after-nothing-riddlemak.ogg")
local demo_soundtrack_ref = nil

-- blank scene
-- local couchot_intro_speech_ref = hg.LoadOGGSoundAsset("audio/intro-couchot-bw.ogg")
local intro_scene = hg.Scene()
hg.LoadSceneFromAssets("sequences/intro_seq.scn", intro_scene, res, hg.GetForwardPipelineInfo())
local intro_camera = intro_scene:GetNode("Camera")
intro_scene:SetCurrentCamera(intro_camera)

local _last_clock

-- title screen
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local initial_cam_pos = nil -- _cam:GetTransform():GetPos()
local title_cam_timing = nil
local _rb_nodes, _camera_tv, _ctx = SetupTitleScene(_scene, res, pipeline_info, vtx_layout, {gold = mat_gold})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "title_screen", apply_physics = ApplyPhysicsTitleScreen, ctx = _ctx, record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, camera_tv = _camera_tv, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})

table.insert(mapping_sequences, {frame = {0.0, 110}, time_remap = {seq_idx.title_screen, 0.814, 0.630}})
table.insert(mapping_sequences, {frame = {110, 219}, time_remap = {seq_idx.title_screen, 0.814, 0.632}})
table.insert(mapping_sequences, {frame = {219, 326}, time_remap = {seq_idx.title_screen, 0.702, 0.487}})
table.insert(mapping_sequences, {frame = {326, 448}, time_remap = {seq_idx.title_screen, 0.507, 0.263}})
table.insert(mapping_sequences, {frame = {448, 462}, time_remap = {seq_idx.title_screen, 0.310, 0.285}})
table.insert(mapping_sequences, {frame = {462, 475}, time_remap = {seq_idx.title_screen, 0.306, 0.283}})
table.insert(mapping_sequences, {frame = {475, 488}, time_remap = {seq_idx.title_screen, 0.305, 0.280}})
table.insert(mapping_sequences, {frame = {488, 501}, time_remap = {seq_idx.title_screen, 0.298, 0.273}})
table.insert(mapping_sequences, {frame = {501, 543}, time_remap = {seq_idx.title_screen, 0.296, 0.244}})
table.insert(mapping_sequences, {frame = {543, 651}, time_remap = {seq_idx.title_screen, 0.244, 0.311}})

-- rotating plates
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes = SetupRotatingPlates(_scene, res, {vtx_layout = vtx_layout, materials = {gold = mat_gold, neon = mat_neon_red, black = mat_black}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "rotating_plates", record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
-- table.insert(mapping_sequences, {clock = {_last_clock, _last_clock + 10.0}, time_remap = {#sequences, 0.2, 0.8}})
table.insert(mapping_sequences, {frame = {651, 868}, time_remap = {seq_idx.rotating_plates, 0.620, 0.157}})
table.insert(mapping_sequences, {frame = {868, 1193}, time_remap = {seq_idx.rotating_plates, 0.157, 0.698}})

-- wave grid
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes = SetupWaveGrid(_scene, res, {vtx_layout = vtx_layout, materials = {gold = mat_gold, neon = mat_neon_red, black = mat_black}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "wave_grid", record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
-- table.insert(mapping_sequences, {clock = {_last_clock, _last_clock + 10.0}, time_remap = {#sequences, 0.2, 0.8}})
table.insert(mapping_sequences, {frame = {1193, 1274}, time_remap = {seq_idx.wave_grid, 0.459, 0.361}})
table.insert(mapping_sequences, {frame = {1274, 1287}, time_remap = {seq_idx.wave_grid, 0.376, 0.356}})
table.insert(mapping_sequences, {frame = {1287, 1353}, time_remap = {seq_idx.wave_grid, 0.371, 0.264}})
table.insert(mapping_sequences, {frame = {1353, 1410}, time_remap = {seq_idx.wave_grid, 0.264, 0.355}})
table.insert(mapping_sequences, {frame = {1410, 1462}, time_remap = {seq_idx.wave_grid, 0.351, 0.226}})
table.insert(mapping_sequences, {frame = {1462, 1621}, time_remap = {seq_idx.wave_grid, 0.226, 0.615}})
table.insert(mapping_sequences, {frame = {1621, 1841}, time_remap = {seq_idx.wave_grid, 0.615, 0.228}})

-- wall of bricks
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes, _ctx = SetupWallOfBricks(_scene, res, pipeline_info, vtx_layout, {neon = mat_neon_red, chrome = mat_chrome, black = mat_black})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
ApplyPhysicsWallOfBricks(_rb_nodes, _scene, _physics, _ctx)
table.insert(sequences, {name = "wall_of_bricks", record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
-- table.insert(mapping_sequences, {clock = {_last_clock, _last_clock + 5.0}, time_remap = {#sequences, 0.0, 1.0}})
-- table.insert(mapping_sequences, {clock = {_last_clock + 5.0, _last_clock + 10.0}, time_remap = {#sequences, 1.0, 0.0}})
table.insert(mapping_sequences, {frame = {1841, 2162}, time_remap = {seq_idx.wall_of_bricks, 0.506, 0.029}})
table.insert(mapping_sequences, {frame = {2162, 2599}, time_remap = {seq_idx.wall_of_bricks, 0.016, 0.716}})

-- Neons
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes = SetupVerticalNeonChaos(_scene, res, {vtx_layout = vtx_layout, materials = {neon = mat_neon_red, gold = mat_gold}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "neons", record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
-- table.insert(mapping_sequences, {clock = {_last_clock, _last_clock + 10.0}, time_remap = {#sequences, 0.1, 0.9}})
table.insert(mapping_sequences, {frame = {2599, 2762}, time_remap = {seq_idx.neons, 0.501, 0.772}})
table.insert(mapping_sequences, {frame = {2762, 3016}, time_remap = {seq_idx.neons, 0.772, 0.349}})
table.insert(mapping_sequences, {frame = {3016, 3341}, time_remap = {seq_idx.neons, 0.349, 0.760}})
table.insert(mapping_sequences, {frame = {3341, 3436}, time_remap = {seq_idx.neons, 0.706, 0.827}})
table.insert(mapping_sequences, {frame = {3436, 3455}, time_remap = {seq_idx.neons, 0.803, 0.827}})
table.insert(mapping_sequences, {frame = {3455, 3465}, time_remap = {seq_idx.neons, 0.790, 0.802}})
table.insert(mapping_sequences, {frame = {3465, 3469}, time_remap = {seq_idx.neons, 0.777, 0.782}})

-- Simple cubes
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes = SetupSimpleCubeStack(_scene, res, {model_size = cube_size, model_ref = cube_ref, materials = {grey = mat_grey}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "simple_cubes", record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
-- table.insert(mapping_sequences, {clock = {_last_clock, _last_clock + 10.0}, time_remap = {#sequences, 0.1, 0.9}})
table.insert(mapping_sequences, {frame = {3469, 3983}, time_remap = {seq_idx.simple_cubes, 0.149, 1.0}})
table.insert(mapping_sequences, {frame = {3983, 4331}, time_remap = {seq_idx.simple_cubes, 1.0, 0.415}})

-- oscillating_wall
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes, _ctx = SetupOscillatingWall(_scene, res, {vtx_layout = vtx_layout, materials = {neon = mat_neon_red, black = mat_black}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "oscillating_wall", apply_physics = ApplyPhysicsOscillatingWall, ctx = {}, record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
-- table.insert(mapping_sequences, {clock = {_last_clock, _last_clock + 10.0}, time_remap = {#sequences, 0.0, 1.0}})
table.insert(mapping_sequences, {frame = {4331, 4437}, time_remap = {seq_idx.oscillating_wall, 0.152, 0.328}})
table.insert(mapping_sequences, {frame = {4437, 4491}, time_remap = {seq_idx.oscillating_wall, 0.330, 0.241}})
table.insert(mapping_sequences, {frame = {4491, 4544}, time_remap = {seq_idx.oscillating_wall, 0.418, 0.331}})
table.insert(mapping_sequences, {frame = {4544, 4597}, time_remap = {seq_idx.oscillating_wall, 0.331, 0.418}})
table.insert(mapping_sequences, {frame = {4597, 4707}, time_remap = {seq_idx.oscillating_wall, 0.420, 0.603}})
table.insert(mapping_sequences, {frame = {4707, 4764}, time_remap = {seq_idx.oscillating_wall, 0.420, 0.648}})
table.insert(mapping_sequences, {frame = {4764, 4815}, time_remap = {seq_idx.oscillating_wall, 0.699, 0.615}})
table.insert(mapping_sequences, {frame = {4815, 4924}, time_remap = {seq_idx.oscillating_wall, 0.663, 0.481}})
table.insert(mapping_sequences, {frame = {4924, 4977}, time_remap = {seq_idx.oscillating_wall, 0.532, 0.443}})
table.insert(mapping_sequences, {frame = {4977, 5072}, time_remap = {seq_idx.oscillating_wall, 0.408, 0.316}})

-- (in)visible colliders
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes = SetupInvisibleColliders(_scene, res, {vtx_layout = vtx_layout, materials = {neon = mat_neon_red, silver = mat_silver, chrome = mat_chrome, black = mat_piano_black}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "invisible_colliders", record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
-- table.insert(mapping_sequences, {clock = {_last_clock, _last_clock + 10.0}, time_remap = {#sequences, 1.0, 0.0}})
table.insert(mapping_sequences, {frame = {5072, 5626}, time_remap = {seq_idx.invisible_colliders, 0.0, 1.0}}) -- temp

-- tornado
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes = SetupTornado(_scene, res, {vtx_layout = vtx_layout, materials = {chrome = mat_chrome, neon = mat_neon_red, black = mat_black}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "tornado", apply_physics = ApplyPhysicsTornado, ctx = {}, record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
table.insert(mapping_sequences, {frame = {5626, 6005}, time_remap = {seq_idx.tornado, 0.802, 0.227}})
table.insert(mapping_sequences, {frame = {6005, 6062}, time_remap = {seq_idx.tornado, 0.209, 0.125}})
table.insert(mapping_sequences, {frame = {6062, 6100}, time_remap = {seq_idx.tornado, 0.134, 0.189}})
table.insert(mapping_sequences, {frame = {6100, 6276}, time_remap = {seq_idx.tornado, 0.199, 0.463}})

-- Repulsion core
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes, _ctx = SetupRepulsionCore(_scene, res, {vtx_layout = vtx_layout, materials = {silver = mat_silver, black = mat_piano_black, neon = mat_neon_red}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "repulsion_core", apply_physics = ApplyPhysicsRepulsionCore, ctx = {}, record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
table.insert(mapping_sequences, {frame = {6276, 6322}, time_remap = {seq_idx.repulsion_core, 0.592, 0.669}})
table.insert(mapping_sequences, {frame = {6322, 6654}, time_remap = {seq_idx.repulsion_core, 0.669, 0.118}})

-- Attraction core
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes, _ctx = SetupAttractionCore(_scene, res, {vtx_layout = vtx_layout, materials = {silver = mat_silver, black = mat_piano_black, neon = mat_neon_red}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "attraction_core", apply_physics = ApplyPhysicsAttractionCore, ctx = {}, record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
table.insert(mapping_sequences, {frame = {6654, 6815}, time_remap = {seq_idx.attraction_core, 0.013, 0.282}})
table.insert(mapping_sequences, {frame = {6815, 7128}, time_remap = {seq_idx.tornado, 0.862, 0.339}})

-- Voxel
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes = SetupXiVoxel(_scene, res, {vtx_layout = vtx_layout, materials = {gold = mat_gold}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "voxel", record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
table.insert(mapping_sequences, {frame = {7128, 7235}, time_remap = {seq_idx.voxel, 0.167, 0.431}})
table.insert(mapping_sequences, {frame = {7235, 7249}, time_remap = {seq_idx.voxel, 0.405, 0.439}})
table.insert(mapping_sequences, {frame = {7249, 7364}, time_remap = {seq_idx.voxel, 0.416, 0.702}})
table.insert(mapping_sequences, {frame = {7364, 7464}, time_remap = {seq_idx.voxel, 0.754, 0.507}})

-- flocks
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes = SetupFlocks(_scene, res, {vtx_layout = vtx_layout, materials = {silver = mat_silver, neon = mat_neon_red, black = mat_black}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
ApplyPhysicsFlocks(_rb_nodes, _physics)
table.insert(sequences, {name = "flocks", record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
table.insert(mapping_sequences, {frame = {7464, 7682}, time_remap = {seq_idx.flocks, 0.312, 0.048}})
table.insert(mapping_sequences, {frame = {7682, 7776}, time_remap = {seq_idx.flocks, 0.125, 0.238}})

-- spiral tornado
local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
local _rb_nodes = SetupSpiralTornado(_scene, res, {vtx_layout = vtx_layout, materials = {chrome = mat_chrome, neon = mat_neon_red, black = mat_black}})
local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
table.insert(sequences, {name = "spiral_tornado", apply_physics = ApplyPhysicsSpiralTornado, ctx = {}, record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
table.insert(mapping_sequences, {frame = {7776, 7871}, time_remap = {seq_idx.spiral_tornado, 0.489, 0.147}})
table.insert(mapping_sequences, {frame = {7871, 8286}, time_remap = {seq_idx.spiral_tornado, 0.143, 0.993}})

if enable_replay then
    -- last dummy sequence
    _last_clock = mapping_sequences[#mapping_sequences].frame[2] / 60.0
    local _scene, _cam, _camera_root = SetupBackgroundEnvironment(res, pipeline_info)
    local _rb_nodes, _ctx = {}, {}
    local _physics, _physics_step, _dt_frame_step = SetupScenePhysics(_scene)
    table.insert(sequences, {name = "dummy", ctx = {}, record = {}, scene = _scene, camera = _cam, camera_root = _camera_root, nodes = _rb_nodes, physics = _physics, physics_step = _physics_step, dt_frame_step = _dt_frame_step})
    table.insert(mapping_sequences, {clock = {_last_clock, _last_clock + 10.0}, time_remap = {#sequences, 0.0, 1.0}})
end

-- Prepare the time remapping table for the whole demo
local presampling_framerate = 59.94 -- 60.0
local demo_duration = mapping_sequences[#mapping_sequences].clock[2]
local replay_time_table = {}
for i = 0, math.floor(demo_duration * presampling_framerate) do
    local _clock = i / presampling_framerate
    local _new_frame = {}
    -- search for the proper sequence
    for j = 1, #mapping_sequences do
        if mapping_sequences[j].clock == nil then
            mapping_sequences[j].clock = {mapping_sequences[j].frame[1] / presampling_framerate, mapping_sequences[j].frame[2] / presampling_framerate}
        end
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

collectgarbage("stop") -- avoid nasty drops all along the demo

local sequence_start_clock = hg.GetClock()

if enable_replay then
    intro_scene:PlayAnim(intro_scene:GetSceneAnim("intro"))
    crt_power_ref = hg.PlayStereo(crt_power_sound, hg.StereoSourceState(1, hg.SR_Once))

    while not keyboard:Down(hg.K_Escape) and hg.IsWindowOpen(win) and hg.GetClock() - sequence_start_clock < hg.time_from_sec_f(10.0) do
        keyboard:Update()
        dt = hg.TickClock()

        intro_scene:Update(dt)

        -- rendering
        local view_id = 0
        local pass_id
        if enable_aaa then
            view_id, pass_id = hg.SubmitSceneToPipeline(view_id, intro_scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res, pipeline_aaa, pipeline_aaa_config, frame)
        else
            view_id, pass_id = hg.SubmitSceneToPipeline(view_id, intro_scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res)
        end
 
        frame = hg.Frame()
        hg.UpdateWindow(win)
    end
end

local sim_seq_idx = 1 -- index of the simulation sequence
local rep_seq_idx = 0 -- index of the replay sequence

local simulation_start_clock = hg.GetClock()
local demo_start_clock = simulation_start_clock
local demo_clock_f = nil
local replay_clock_f =  nil
local rotation_speed_factor = 0.0

-- Couchot speech
couchot_intro_speech_ref = hg.PlayStereo(couchot_intro_speech_sound, hg.StereoSourceState(1, hg.SR_Once))

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
            if enable_aaa then
                view_id, pass_id = hg.SubmitSceneToPipeline(view_id, rep_scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res, pipeline_aaa, pipeline_aaa_config, frame)
            else
                view_id, pass_id = hg.SubmitSceneToPipeline(view_id, rep_scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res)
            end
        else
            intro_scene:SetCurrentCamera(intro_camera)
            intro_scene.environment.ambient = ambient_control
            if enable_aaa then
                view_id, pass_id = hg.SubmitSceneToPipeline(view_id, intro_scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res, pipeline_aaa, pipeline_aaa_config, frame)
            else
                view_id, pass_id = hg.SubmitSceneToPipeline(view_id, intro_scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res)
            end
        end
    else
        sim_scene:SetCurrentCamera(sim_camera)
        sim_scene.environment.ambient = ambient_control
        if enable_aaa then
            view_id, pass_id = hg.SubmitSceneToPipeline(view_id, sim_scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res, pipeline_aaa, pipeline_aaa_config, frame)
        else
            view_id, pass_id = hg.SubmitSceneToPipeline(view_id, sim_scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res)
        end
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
    local _seq_clock_f = demo_clock_f - (sim_seq_idx - 1.0) * 10.0
    local _seq_clock_normalized = _seq_clock_f / 10.0
    local _str_clock = string.format("%3.5f", demo_clock_f) .. " / " .. string.format("%3.5f", _seq_clock_f) .. string.format(" (%2.3f)", _seq_clock_normalized)
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