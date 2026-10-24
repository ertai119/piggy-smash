--!strict
-- 저금통이 돌아다니는 바닥과 벽. 모든 플레이어가 같은 바닥을 보지만 저금통은 각자 화면에만 있다.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Arena = {}

local function part(props: { [string]: any }, parent: Instance): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
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

	-- 바닥: 체크무늬 타일
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

	-- 벽(굵은 검은 테두리 느낌)
	local t = 1.5
	local h = Config.WALL_HEIGHT
	local walls = {
		{ Vector3.new(w + t * 2, h, t), Vector3.new(0, h / 2 - 1, -d / 2 - t / 2) },
		{ Vector3.new(w + t * 2, h, t), Vector3.new(0, h / 2 - 1, d / 2 + t / 2) },
		{ Vector3.new(t, h, d), Vector3.new(-w / 2 - t / 2, h / 2 - 1, 0) },
		{ Vector3.new(t, h, d), Vector3.new(w / 2 + t / 2, h / 2 - 1, 0) },
	}
	for _, wall in walls do
		part({ Name = "Wall", Size = wall[1], Position = o + wall[2], Color = C.wall, Material = Enum.Material.SmoothPlastic }, model)
	end

	-- 바깥 바다(파란 그라데이션 배경 대신)
	part({
		Name = "Backdrop",
		Size = Vector3.new(w * 6, 1, d * 6),
		Position = o + Vector3.new(0, -6, 0),
		Color = C.sky,
		Material = Enum.Material.SmoothPlastic,
	}, model)

	model.Parent = workspace
	return model
end

return Arena
