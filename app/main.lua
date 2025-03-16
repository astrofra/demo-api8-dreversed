hg = require("harfang")

function CreatePhysicCubeEx(scene, size, mtx, model_ref, materials, rb_type, mass)
	local node = hg.CreateObject(scene, mtx, model_ref, materials)
	node:SetName("Physic Cube")
	local rb = scene:CreateRigidBody()
	rb:SetType(rb_type)
	node:SetRigidBody(rb)
    -- create custom cube collision
	local col = scene:CreateCollision()
	col:SetType(hg.CT_Cube)
	col:SetSize(size)
	col:SetMass(mass)
    -- set cube as collision shape
	node:SetCollision(0, col)
	return node, rb
end

hg.AddAssetsFolder('assets_compiled')

-- main window
hg.InputInit()
hg.WindowSystemInit()

local res_x, res_y = 1280, 720
local win = hg.RenderInit('Physics Test', res_x, res_y, hg.RF_VSync | hg.RF_MSAA4X)

local pipeline = hg.CreateForwardPipeline(2048)
local res = hg.PipelineResources()

-- physics debug
local vtx_line_layout = hg.VertexLayoutPosFloatColorUInt8()
local line_shader = hg.LoadProgramFromAssets("shaders/pos_rgb")

-- create material
local pbr_shader = hg.LoadPipelineProgramRefFromAssets('core/shader/pbr.hps', res, hg.GetForwardPipelineInfo())
local mat_grey = hg.CreateMaterial(pbr_shader, 'uBaseOpacityColor', hg.Vec4(1, 1, 1), 'uOcclusionRoughnessMetalnessColor', hg.Vec4(1, 0.5, 0.05))

-- create models
local vtx_layout = hg.VertexLayoutPosFloatNormUInt8()

-- cube
local cube_size =  hg.Vec3(1, 1, 1)
local cube_ref = res:AddModel('cube', hg.CreateCubeModel(vtx_layout, cube_size.x, cube_size.y, cube_size.z))

-- ground
local ground_size = hg.Vec3(50, 0.05, 50)
local ground_ref = res:AddModel('ground', hg.CreateCubeModel(vtx_layout, ground_size.x, ground_size.y, ground_size.z))

-- setup the scene
local scene = hg.Scene()

local cam_mat = hg.TransformationMat4(hg.Vec3(0, 6, -15.5) * 2.0, hg.Vec3(hg.Deg(15), 0, 0))
local cam = hg.CreateCamera(scene, cam_mat, 0.01, 1000, hg.Deg(30))
local view_matrix = hg.InverseFast(cam_mat)
local c = cam:GetCamera()
local projection_matrix = hg.ComputePerspectiveProjectionMatrix(c:GetZNear(), c:GetZFar(), hg.FovToZoomFactor(c:GetFov()), hg.Vec2(res_x / res_y, 1))

scene:SetCurrentCamera(cam)	

local lgt = hg.CreateLinearLight(scene, hg.TransformationMat4(hg.Vec3(0, 0, 0), hg.Vec3(hg.Deg(30), hg.Deg(30), 0)), hg.Color(1, 1, 1), hg.Color(1, 1, 1), 10, hg.LST_Map, 0.001, hg.Vec4(20, 34, 55, 70))

-- chair_node, _ = hg.CreateInstanceFromAssets(scene, hg.TranslationMat4(hg.Vec3(0, 1, 0)), "chair/chair.scn", res, hg.GetForwardPipelineInfo())

for i = 1, 200 do
    hg.CreateInstanceFromAssets(scene, hg.TranslationMat4(hg.Vec3(0, 1 + i * 5, 0)), "chair/chair.scn", res, hg.GetForwardPipelineInfo())
end

local floor, rb_floor = CreatePhysicCubeEx(scene, ground_size, hg.TranslationMat4(hg.Vec3(0, -0.005, 0)), ground_ref, {mat_grey}, hg.RBT_Static, 0)
rb_floor:SetRestitution(1)

-- scene physics
local physics = hg.SceneBullet3Physics()
physics:SceneCreatePhysicsFromAssets(scene)
local physics_step = hg.time_from_sec_f(1 / 60)
local dt_frame_step = hg.time_from_sec_f(1 / 60)

local clocks = hg.SceneClocks()

-- description
hg.SetLogLevel(hg.LL_Normal)
print(">>> Description:\n>>> Drop vertically 200 chairs, made of 6 collision boxes each")

-- main loop
local keyboard = hg.Keyboard()

while not keyboard:Down(hg.K_Escape) and hg.IsWindowOpen(win) do
    keyboard:Update()

    -- physics:NodeWake(chair_node)
    local view_id = 0
    local pass_id
    hg.SceneUpdateSystems(scene, clocks, dt_frame_step, physics, physics_step, 3)
    view_id, pass_id = hg.SubmitSceneToPipeline(view_id, scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res)

    -- -- Debug physics display
    -- hg.SetViewClear(view_id, 0, 0, 1.0, 0)
    -- hg.SetViewRect(view_id, 0, 0, res_x, res_y)
    -- hg.SetViewTransform(view_id, view_matrix, projection_matrix)
    -- rs = hg.ComputeRenderState(hg.BM_Opaque, hg.DT_Disabled, hg.FC_Disabled)
    -- physics:RenderCollision(view_id, vtx_line_layout, line_shader, rs, 0)

    hg.Frame()
    hg.UpdateWindow(win)
end

scene:Clear()
scene:GarbageCollect()

hg.RenderShutdown()
hg.DestroyWindow(win)

hg.WindowSystemShutdown()
hg.InputShutdown()