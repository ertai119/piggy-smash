--!strict
-- 캐릭터와 저금통이 돌아다니는 마당. 모든 플레이어가 같은 마당에 서지만 저금통은 각자 화면에만 있다.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Arena = {}

local function part(props: { [string]: any }, parent: Instance): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = true
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

function Arena.build(): Model
	local existing = workspace:FindFirstChild("PiggyArena")
	if existing then
		existing:Destroy()
	end
	local C = Config.COLORS
	local o = Config.ARENA_ORIGIN
	local w, d = Config.ARENA_SIZE.X, Config.ARENA_SIZE.Y
	local model = Instance.new("Model")
	model.Name = "PiggyArena"

	-- 바깥 잔디(마당 밖으로 떨어지지 않게 넉넉히)
	part({
		Name = "Grass",
		Size = Vector3.new(w * 4, 2, d * 4),
		Position = o + Vector3.new(0, -1.05, 0),
		Color = C.grass,
		Material = Enum.Material.Grass,
	}, model)

	-- 마당 바닥: 체크무늬 타일
	local tile = 8
	for ix = 0, math.ceil(w / tile) - 1 do
		for iz = 0, math.ceil(d / tile) - 1 do
			local tw = math.min(tile, w - ix * tile)
			local td = math.min(tile, d - iz * tile)
			part({
				Name = "Floor",
				Size = Vector3.new(tw, 1, td),
				Position = o + Vector3.new(-w / 2 + ix * tile + tw / 2, -0.5, -d / 2 + iz * tile + td / 2),
				Color = if (ix + iz) % 2 == 0 then C.floor else C.floorLine,
				Material = Enum.Material.SmoothPlastic,
			}, model)
		end
	end

	-- 울타리(캐릭터도 저금통도 못 나간다)
	local t = 2
	local h = Config.WALL_HEIGHT
	local walls = {
		{ Vector3.new(w + t * 2, h, t), Vector3.new(0, h / 2, -d / 2 - t / 2) },
		{ Vector3.new(w + t * 2, h, t), Vector3.new(0, h / 2, d / 2 + t / 2) },
		{ Vector3.new(t, h, d), Vector3.new(-w / 2 - t / 2, h / 2, 0) },
		{ Vector3.new(t, h, d), Vector3.new(w / 2 + t / 2, h / 2, 0) },
	}
	for _, wall in walls do
		part({ Name = "Wall", Size = wall[1], Position = o + wall[2], Color = C.wall, Material = Enum.Material.SmoothPlastic }, model)
	end

	-- 마당 가운데에서 태어난다(발판은 안 보이게)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.CanQuery = false
	spawn.Transparency = 1
	spawn.Size = Vector3.new(6, 0.2, 6)
	spawn.Position = o + Vector3.new(0, 0.1, 0)
	spawn.Neutral = true
	spawn.Duration = 0
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end
	spawn.Parent = model

	model.Parent = workspace
	return model
end

return Arena
