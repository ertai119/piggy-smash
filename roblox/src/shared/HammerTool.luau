--!strict
-- 캐릭터 손에 쥐는 망치 도구. 서버가 만들어 캐릭터에게 쥐여 준다(다른 사람에게도 보인다).
-- 손잡이는 Handle 의 Z축을 따라 놓이고, 손은 -Z 쪽 끝을 잡고, 머리는 +Z 쪽 끝에 달린다.
local Config = require(script.Parent.Config)

local C = Config.COLORS
local HammerTool = {}

HammerTool.NAME = "Hammer"
-- 손잡이 길이(스터드, 배율 1). 휘두르는 연출용 망치도 같은 길이를 쓴다.
HammerTool.LENGTH = 5

local function part(parent: Instance, shape: Enum.PartType, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Shape = shape
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function weld(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = a
end

-- scale: 망치 크기 배율(Upgrades.hammerScale). 캐릭터도 같은 배율로 커진다.
function HammerTool.build(scale: number): Tool
	local tool = Instance.new("Tool")
	tool.Name = HammerTool.NAME
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = "클릭/터치로 내려치기"

	local len = HammerTool.LENGTH * scale
	local handle = part(tool, Enum.PartType.Block, Vector3.new(0.45 * scale, 0.45 * scale, len), CFrame.new(), C.hammerHandle, Enum.Material.Wood)
	handle.Name = "Handle"

	-- 머리: 원기둥 축(X)이 손잡이와 직각
	local headCf = CFrame.new(0, 0, len / 2)
	local head = part(tool, Enum.PartType.Cylinder, Vector3.new(2.4, 1.5, 1.5) * scale, headCf, C.hammerHead, Enum.Material.Metal)
	head.Name = "Head"
	weld(handle, head)
	for _, side in { -1, 1 } do
		local band = part(tool, Enum.PartType.Cylinder, Vector3.new(0.25, 1.65, 1.65) * scale, headCf * CFrame.new(side * 0.9 * scale, 0, 0), C.black, Enum.Material.SmoothPlastic)
		band.Name = "Band"
		weld(handle, band)
	end

	-- 손은 손잡이 끝 근처를 잡는다
	tool.Grip = CFrame.new(0, 0, -(len / 2 - 0.4 * scale))
	return tool
end

return HammerTool
