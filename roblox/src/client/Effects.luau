-- 타격감 연출: 망치, 충격 별, 번쩍임, 피해 숫자, 조각, 동전, 번개, 흔들림.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Anim = require(script.Parent.Anim)
local Art = require(script.Parent.Art)
local CameraRig = require(script.Parent.CameraRig)

local C = Config.COLORS
local E = Anim.ease
local MAX_COINS = 60
local MAX_SHARDS = 80

local Effects = {}

local fx = Instance.new("Folder")
fx.Name = "PiggyFx"
fx.Parent = workspace

local flyingCoins: { { part: BasePart, finish: () -> () } } = {}
local shardCount = 0

local function fxPart(shape: Enum.PartType, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Art.newPart(fx, shape, size, cf, color, material)
	p.CastShadow = false
	return p
end

-- 캐릭터 어깨(grip)에서 망치를 머리 위로 들었다가 앞(look)으로 내려꽂는다.
-- downAngle: 다 내려쳤을 때 손잡이가 수평에서 아래로 기운 각(라디안, 음수).
function Effects.swingHammer(grip: Vector3, look: Vector3, downAngle: number, duration: number, scale: number)
	local h = Art.hammer(scale)
	h.model.Parent = fx
	local base = CFrame.lookAt(grip, grip + look)
	local function pose(angle: number)
		Art.poseHammer(h, base * CFrame.Angles(angle, 0, 0))
	end
	local up = math.rad(115)
	pose(up)
	Anim.run(duration, function(t)
		pose(up + (downAngle - up) * E.quadIn(t))
	end, function()
		local parts = h.model:GetDescendants()
		Anim.run(0.1, function(t)
			pose(downAngle + math.rad(10) * t)
			for _, p in parts do
				if p:IsA("BasePart") then
					p.Transparency = t
				end
			end
		end, function()
			h.model:Destroy()
		end, 0.05)
	end)
end

-- 망치가 떨어진 자리의 노란 충격 별
function Effects.impactBurst(at: Vector3, big: boolean, scale: number)
	local d = 3.6 * scale * (if big then 1.25 else 0.9)
	local center = CFrame.new(at + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, math.random() * math.pi, 0)
	local disc = fxPart(Enum.PartType.Cylinder, Vector3.new(0.1, d, d), center * Art.UPRIGHT, C.burst, Enum.Material.Neon)
	local spikes = {}
	for i = 1, 6 do
		local a = i * math.pi / 3
		table.insert(spikes, { a = a, part = fxPart(Enum.PartType.Block, Vector3.new(0.35 * d, 0.1, 0.12 * d), center, C.white, Enum.Material.Neon) })
	end
	Anim.run(0.16, function(t)
		local s = 0.6 + 0.7 * E.quadOut(t)
		disc.Size = Vector3.new(0.1, d * s, d * s)
		disc.Transparency = t
		for _, sp in spikes do
			local rot = center * CFrame.Angles(0, sp.a, 0)
			sp.part.CFrame = rot * CFrame.new(d * 0.45 * s, 0.05, 0)
			sp.part.Transparency = t
		end
	end, function()
		disc:Destroy()
		for _, sp in spikes do
			sp.part:Destroy()
		end
	end)
end

function Effects.damageNumber(at: Vector3, dmg: number, crit: boolean)
	local att = Instance.new("Attachment")
	att.WorldPosition = at + Vector3.new((math.random() - 0.5) * 1.6, 2.5, 0)
	att.Parent = workspace.Terrain
	local gui = Instance.new("BillboardGui")
	gui.AlwaysOnTop = true
	gui.Size = UDim2.fromOffset(180, 60)
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.Text = if crit then `CRIT {dmg}` else `-{dmg}`
	label.TextColor3 = if crit then C.gold else C.white
	label.TextSize = if crit then 40 else 26
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = if crit then 4 else 3
	stroke.Parent = label
	label.Parent = gui
	gui.Parent = att
	local start = att.WorldPosition
	local size = label.TextSize
	Anim.run(0.5, function(t)
		att.WorldPosition = start + Vector3.new(0, 3.5 * E.cubicOut(t), 0)
		label.TextTransparency = t
		stroke.Transparency = t
		if crit then
			label.TextSize = size * (0.5 + 0.5 * E.backOut(math.min(1, t / 0.28)))
		end
	end, function()
		att:Destroy()
	end)
end

-- 저금통이 조각으로 흩어진다(손으로 계산한 포물선)
function Effects.breakPig(at: Vector3, gold: boolean, r: number)
	local color = if gold then C.gold else C.pig
	local n = 7
	for i = 1, n do
		if shardCount >= MAX_SHARDS then
			break
		end
		shardCount += 1
		local size = r * (if gold then 0.55 else 0.45) * (0.7 + math.random() * 0.6)
		local shard = fxPart(Enum.PartType.Wedge, Vector3.new(size, size * 0.6, size), CFrame.new(at), color, if gold then Enum.Material.Foil else nil)
		local a = math.pi * 2 * i / n + math.random() * 0.6
		local speed = (5 + math.random() * 5) * r / 2
		local vel = Vector3.new(math.cos(a) * speed, 9 + math.random() * 6, math.sin(a) * speed)
		local spin = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 30
		local p0 = at + Vector3.new(0, r, 0)
		local life = 0.6
		Anim.run(life, function(t)
			local s = t * life
			local pos = p0 + vel * s + Vector3.new(0, -40, 0) * (s * s / 2)
			if pos.Y < at.Y then
				pos = Vector3.new(pos.X, at.Y, pos.Z)
			end
			shard.CFrame = CFrame.new(pos) * CFrame.Angles(spin.X * s, spin.Y * s, spin.Z * s)
			shard.Transparency = E.quadIn(t)
		end, function()
			shardCount -= 1
			shard:Destroy()
		end)
	end
end

-- 동전이 튀어 오른 뒤 HUD 동전 카운터로 날아간다. 각 동전이 도착하면 onArrive(그 동전 값). 값의 합 = total.
function Effects.coinBurst(at: Vector3, visualCount: number, total: number, target: () -> Vector3, onArrive: (number) -> ())
	local n = math.max(1, visualCount)
	local each = total // n
	for i = 1, n do
		local value = if i == n then total - each * (n - 1) else each
		while #flyingCoins >= MAX_COINS do
			flyingCoins[1].finish()
		end
		local coin = Art.coin(1.1)
		coin.Parent = fx
		local done = false
		local stopFly: (() -> ())? = nil
		local entry
		local function finish()
			if done then
				return
			end
			done = true
			local idx = table.find(flyingCoins, entry)
			if idx then
				table.remove(flyingCoins, idx)
			end
			coin:Destroy()
			onArrive(value)
			if stopFly then
				stopFly()
			end
		end
		entry = { part = coin, finish = finish }
		table.insert(flyingCoins, entry)

		local a = math.random() * math.pi * 2
		local d = 2.5 + math.random() * 4
		local p0 = at + Vector3.new(0, 1.5, 0)
		local p1 = p0 + Vector3.new(math.cos(a) * d, 3 + math.random() * 2, math.sin(a) * d)
		local spin = math.random() * 10
		stopFly = Anim.run(0.3, function(t)
			if done then
				return
			end
			coin.CFrame = CFrame.new(p0:Lerp(p1, E.cubicOut(t))) * CFrame.Angles(0, spin * t, math.pi / 2)
		end, function()
			if done then
				return
			end
			stopFly = Anim.run(0.5, function(t)
				if done then
					return
				end
				local k = E.cubicIn(t)
				coin.CFrame = CFrame.new(p1:Lerp(target(), k)) * CFrame.Angles(0, spin + 8 * t, math.pi / 2)
				coin.Size = Vector3.new(0.22, 1.1, 1.1) * (1 - 0.6 * k)
			end, finish, 0.05 + i * 0.018)
		end)
	end
end

-- 저금통 사이 지그재그 번개
function Effects.lightning(from: Vector3, to: Vector3)
	local lift = Vector3.new(0, 1.5, 0)
	local a, b = from + lift, to + lift
	local dir = b - a
	local side = if dir.Magnitude > 0 then dir:Cross(Vector3.yAxis).Unit else Vector3.xAxis
	local pts = { a }
	local segs = 6
	for i = 1, segs - 1 do
		table.insert(pts, a + dir * (i / segs) + side * ((math.random() - 0.5) * 2.4))
	end
	table.insert(pts, b)
	local parts = {}
	for i = 1, #pts - 1 do
		local p, q = pts[i], pts[i + 1]
		local len = (q - p).Magnitude
		local cf = CFrame.lookAt((p + q) / 2, q)
		table.insert(parts, fxPart(Enum.PartType.Block, Vector3.new(0.35, 0.35, len), cf, C.bolt, Enum.Material.Neon))
		table.insert(parts, fxPart(Enum.PartType.Block, Vector3.new(0.14, 0.14, len), cf, C.white, Enum.Material.Neon))
	end
	Anim.run(0.2, function(t)
		for _, p in parts do
			p.Transparency = E.quadIn(t)
		end
	end, function()
		for _, p in parts do
			p:Destroy()
		end
	end)
end

function Effects.shake(seconds: number, power: number)
	CameraRig.shake(seconds, power)
end

-- 판이 끝나면 남은 연출을 정리한다(날아가던 동전은 바로 도착 처리)
function Effects.reset()
	while #flyingCoins > 0 do
		flyingCoins[1].finish()
	end
end

return Effects
