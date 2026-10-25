-- 저금통·망치·동전 모양. 시안 C "선명한 캐주얼": 진한 색, 둥글둥글.
-- 모든 모델은 바닥 중심이 기준점(Pivot)이고, 앞(코)이 -Z 방향이다.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local HammerTool = require(ReplicatedStorage.Shared.HammerTool)

local C = Config.COLORS
local Art = {}

local function newPart(parent: Instance, shape: Enum.PartType, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Shape = shape
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function ellipsoid(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = newPart(parent, Enum.PartType.Block, size, cf, color, material)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

-- 원기둥 축을 Y(세로)로 세운 CFrame
local UPRIGHT = CFrame.Angles(0, 0, math.pi / 2)
-- 원기둥 축을 Z(앞뒤)로 눕힌 CFrame
local FORWARD = CFrame.Angles(0, math.pi / 2, 0)

export type PigArt = {
	model: Model,
	paint: { { part: BasePart, color: Color3 } },
	hpFill: Frame,
	hpGui: BillboardGui,
}

-- r: 반지름(스터드)
function Art.pig(kind: string, r: number): PigArt
	local gold = kind == "gold"
	local body = if gold then C.gold else C.pig
	local dark = if gold then C.goldDark else C.pigDark
	local mat = if gold then Enum.Material.Foil else Enum.Material.SmoothPlastic
	local model = Instance.new("Model")
	model.Name = if gold then "GoldPig" else "Pig"

	local root = newPart(model, Enum.PartType.Block, Vector3.new(0.2, 0.2, 0.2), CFrame.new(), C.black)
	root.Name = "Root"
	root.Transparency = 1
	model.PrimaryPart = root

	local paint = {}
	local function add(p: BasePart)
		table.insert(paint, { part = p, color = p.Color })
	end

	add(ellipsoid(model, Vector3.new(1.7 * r, 1.6 * r, 2 * r), CFrame.new(0, 1.15 * r, 0), body, mat))
	add(newPart(model, Enum.PartType.Cylinder, Vector3.new(0.35 * r, 0.75 * r, 0.75 * r), CFrame.new(0, 1.05 * r, -0.95 * r) * FORWARD, dark, mat))
	for _, sx in { -1, 1 } do
		-- 콧구멍, 눈, 귀
		newPart(model, Enum.PartType.Ball, Vector3.one * 0.14 * r, CFrame.new(sx * 0.15 * r, 1.05 * r, -1.13 * r), C.black)
		newPart(model, Enum.PartType.Ball, Vector3.one * 0.24 * r, CFrame.new(sx * 0.36 * r, 1.45 * r, -0.78 * r), C.black)
		newPart(model, Enum.PartType.Ball, Vector3.one * 0.09 * r, CFrame.new(sx * 0.33 * r, 1.5 * r, -0.88 * r), C.white)
		add(newPart(model, Enum.PartType.Wedge, Vector3.new(0.3 * r, 0.42 * r, 0.32 * r), CFrame.new(sx * 0.45 * r, 1.9 * r, -0.35 * r), dark, mat))
		-- 다리
		for _, sz in { -1, 1 } do
			add(newPart(model, Enum.PartType.Cylinder, Vector3.new(0.45 * r, 0.38 * r, 0.38 * r), CFrame.new(sx * 0.45 * r, 0.22 * r, sz * 0.5 * r) * UPRIGHT, dark, mat))
		end
	end
	-- 동전 넣는 구멍, 꼬리
	newPart(model, Enum.PartType.Block, Vector3.new(0.12 * r, 0.06 * r, 0.6 * r), CFrame.new(0, 1.95 * r, 0.05 * r), C.black)
	add(newPart(model, Enum.PartType.Ball, Vector3.one * 0.25 * r, CFrame.new(0, 1.3 * r, 1.02 * r), dark, mat))

	if gold then
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkle.Color = ColorSequence.new(Color3.fromRGB(255, 249, 196))
		sparkle.LightEmission = 1
		sparkle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
		sparkle.Lifetime = NumberRange.new(0.4, 0.8)
		sparkle.Rate = 6
		sparkle.Speed = NumberRange.new(1, 2)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.Parent = root
	end

	-- 머리 위 체력 바(크기 단위: 스터드)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Hp"
	gui.Adornee = root
	gui.AlwaysOnTop = true
	gui.Size = UDim2.fromScale(1.8 * r, 0.28 * r)
	gui.StudsOffset = Vector3.new(0, 2.5 * r, 0)
	gui.LightInfluence = 0
	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.fromRGB(51, 51, 51)
	back.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = back
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5
	stroke.Parent = back
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = C.green
	fill.BorderSizePixel = 0
	corner:Clone().Parent = fill
	fill.Parent = back
	back.Parent = gui
	gui.Parent = root

	return { model = model, paint = paint, hpFill = fill, hpGui = gui }
end

-- 맞은 순간 하얗게
function Art.flash(art: PigArt, on: boolean)
	for _, p in art.paint do
		p.part.Color = if on then C.white else p.color
	end
end

export type HammerArt = { model: Model, handle: Part, head: Part, bands: { Part }, length: number, scale: number }

-- 휘두르는 연출용 망치(손에 든 HammerTool 과 같은 크기). 손잡이 끝(잡는 곳)이 기준점, 머리가 -Z 쪽 끝에 붙는다.
function Art.hammer(scale: number): HammerArt
	local model = Instance.new("Model")
	model.Name = "SwingHammer"
	local len = HammerTool.LENGTH * scale
	local handle = newPart(model, Enum.PartType.Cylinder, Vector3.new(len, 0.45 * scale, 0.45 * scale), CFrame.new(), C.hammerHandle, Enum.Material.Wood)
	local head = newPart(model, Enum.PartType.Cylinder, Vector3.new(2.4, 1.5, 1.5) * scale, CFrame.new(), C.hammerHead, Enum.Material.Metal)
	local bands = {}
	for _ = 1, 2 do
		table.insert(bands, newPart(model, Enum.PartType.Cylinder, Vector3.new(0.25, 1.65, 1.65) * scale, CFrame.new(), C.black))
	end
	return { model = model, handle = handle, head = head, bands = bands, length = len, scale = scale }
end

-- grip: 손잡이 끝 CFrame. 손잡이는 grip의 -Z로 뻗고, 머리 원기둥은 grip의 Y축을 따라 선다.
function Art.poseHammer(h: HammerArt, grip: CFrame)
	h.handle.CFrame = grip * CFrame.new(0, 0, -h.length / 2) * FORWARD
	local headCf = grip * CFrame.new(0, 0, -h.length) * UPRIGHT
	h.head.CFrame = headCf
	h.bands[1].CFrame = headCf * CFrame.new(-0.9 * h.scale, 0, 0)
	h.bands[2].CFrame = headCf * CFrame.new(0.9 * h.scale, 0, 0)
end

function Art.coin(size: number): Part
	local p = newPart(workspace, Enum.PartType.Cylinder, Vector3.new(0.2 * size, size, size), CFrame.new(), C.coin, Enum.Material.Metal)
	p.Name = "Coin"
	p.CastShadow = false
	return p
end

Art.newPart = newPart
Art.UPRIGHT = UPRIGHT

return Art
