-- 한 판: 저금통이 돌아다니고, 클릭/터치하면 망치가 내려친다.
-- 판은 이 플레이어 화면에서만 돈다(저금통은 다른 사람에게 안 보인다). 결과는 서버가 검증한다.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Balance = require(Shared.Balance)
local Combat = require(Shared.Combat)
local Config = require(Shared.Config)
local StageRun = require(Shared.StageRun)
local Upgrades = require(Shared.Upgrades)
local Anim = require(script.Parent.Anim)
local Art = require(script.Parent.Art)
local CameraRig = require(script.Parent.CameraRig)
local Effects = require(script.Parent.Effects)
local Sound = require(script.Parent.Sound)

local U = Config.STUDS_PER_PX
local C = Config.COLORS
local END_DELAY = 0.6
local HP_LOW = 0.3
-- 탭을 이 높이(스터드)의 평면에 맞춰 읽는다: 저금통 몸통 높이쯤이라 비스듬한 카메라에서도 보이는 곳을 맞힌다
local TAP_HEIGHT = 2
-- 동전이 HUD로 날아갈 때 카메라 앞 거리
local COIN_DEPTH = 8

local Play = {}

export type Outcome = {
	cleared: boolean,
	normalBroken: number,
	goldBroken: number,
	bestCombo: number,
	remaining: number,
}

type Pig = {
	id: number,
	kind: Balance.PigKind,
	hp: number,
	maxHp: number,
	x: number,
	z: number,
	vx: number,
	vz: number,
	r: number,
	art: Art.PigArt,
	-- 0이 아니면 크기 연출 중: 등장(pop)과 맞았을 때 찌그러짐(squash)
	pop: number,
	squash: number,
	scaled: boolean,
}

local function rand(lo: number, hi: number): number
	return lo + math.random() * (hi - lo)
end

local function radiusOf(kind: Balance.PigKind): number
	return (if kind == "gold" then Config.PIG_RADIUS_GOLD else Config.PIG_RADIUS) * U
end

-- hud: Ui.showHud 가 돌려준 것. save: 판 시작 때의 저장 데이터. 판이 끝날 때까지 기다렸다가 결과를 돌려준다.
function Play.run(stage: number, save: any, hud: any): Outcome
	local cfg = Balance.stageConfig(stage)
	local run = StageRun.new(cfg, math.random)
	local stats = Upgrades.hammerStats(save.levels)
	local hammerSize = Upgrades.hammerScale(save.levels.area)
	local gate = Combat.SwingGate.new(stats.minIntervalMs)
	local swingTime = math.min(110, stats.minIntervalMs * 0.6) / 1000

	local o = Config.ARENA_ORIGIN
	local halfW, halfD = Config.ARENA_SIZE.X / 2, Config.ARENA_SIZE.Y / 2

	local folder = Instance.new("Folder")
	folder.Name = "MyPigs"
	folder.Parent = workspace

	local pigs: { [number]: Pig } = {}
	local nextId = 1
	local shownCoins = 0
	-- 방금 깨진 저금통 위치(같은 터치의 숫자·번개 연출용)
	local lastBroken: { [number]: Vector3 } = {}
	local ending = false
	local finished = Instance.new("BindableEvent")
	local conns: { RBXScriptConnection } = {}

	local function worldOf(p: Pig): Vector3
		return Vector3.new(o.X + p.x, o.Y, o.Z + p.z)
	end

	local function spawnPig(req: StageRun.SpawnRequest, popIn: boolean)
		local r = radiusOf(req.kind)
		local speed = cfg.pigSpeed * U * rand(0.75, 1.25)
		local dir = rand(0, math.pi * 2)
		local art = Art.pig(req.kind, r)
		local pig: Pig = {
			id = nextId,
			kind = req.kind,
			hp = req.hp,
			maxHp = req.hp,
			x = rand(-halfW + r, halfW - r),
			z = rand(-halfD + r, halfD - r),
			vx = math.cos(dir) * speed,
			vz = math.sin(dir) * speed,
			r = r,
			art = art,
			pop = if popIn then 1 else 0,
			squash = 0,
			scaled = false,
		}
		nextId += 1
		art.model:PivotTo(CFrame.new(worldOf(pig)))
		art.model.Parent = folder
		pigs[pig.id] = pig
	end

	local function movePigs(dt: number, now: number)
		for _, p in pigs do
			p.x += p.vx * dt
			p.z += p.vz * dt
			if p.x < -halfW + p.r or p.x > halfW - p.r then
				p.vx = -p.vx
			end
			if p.z < -halfD + p.r or p.z > halfD - p.r then
				p.vz = -p.vz
			end
			p.x = math.clamp(p.x, -halfW + p.r, halfW - p.r)
			p.z = math.clamp(p.z, -halfD + p.r, halfD - p.r)

			-- 걷는 느낌: 살짝 뒤뚱거림
			local pos = worldOf(p) + Vector3.new(0, math.abs(math.sin(now * 12 + p.id)) * 0.15 * p.r, 0)
			local cf = CFrame.lookAt(pos, pos + Vector3.new(p.vx, 0, p.vz)) * CFrame.Angles(0, 0, math.sin(now * 10 + p.id) * math.rad(5))
			p.art.model:PivotTo(cf)

			-- 등장할 때 톡 튀어나오고, 맞으면 찌그러졌다 돌아온다
			if p.pop > 0 or p.squash > 0 then
				p.pop = math.max(0, p.pop - dt / 0.22)
				p.squash = math.max(0, p.squash - dt / 0.12)
				local s = Anim.ease.backOut(1 - p.pop) * (1 + 0.15 * math.sin(p.squash * math.pi))
				p.art.model:ScaleTo(math.max(0.05, s))
				p.scaled = true
			elseif p.scaled then
				p.art.model:ScaleTo(1)
				p.scaled = false
			end

			local ratio = math.max(0, p.hp / p.maxHp)
			local fill = p.art.hpFill
			fill.Size = UDim2.fromScale(ratio, 1)
			fill.BackgroundColor3 = if ratio <= HP_LOW then C.orange else C.green
		end
	end

	local function coinTarget(): Vector3
		local pos = hud.coinScreenPos()
		return CameraRig.screenToNear(pos.X, pos.Y, COIN_DEPTH)
	end

	local function breakPig(p: Pig)
		pigs[p.id] = nil
		local coins = run:pigBroken(p.kind)
		local at = worldOf(p)
		lastBroken[p.id] = at
		local gold = p.kind == "gold"
		task.delay(swingTime * 0.8, function()
			p.art.model:Destroy()
			Effects.breakPig(at, gold, p.r)
			Sound.play("break")
			Effects.shake(0.1, if gold then 0.35 else 0.18)
			local visual = if gold then math.random(14, 18) else math.random(4, 6)
			Effects.coinBurst(at, visual, coins, coinTarget, function(value)
				shownCoins += value
				hud.bumpCoin()
				Sound.play("coin")
			end)
		end)
	end

	local function showHits(result: Combat.TapResult, impact: Vector3)
		task.delay(swingTime * 0.8, function()
			Effects.impactBurst(impact, result.crit, hammerSize)
			for _, h in result.hits do
				local p = pigs[h.id]
				local at = if p then worldOf(p) else lastBroken[h.id]
				if p then
					Art.flash(p.art, true)
					p.squash = 1
					task.delay(0.07, function()
						if p.art.model.Parent then
							Art.flash(p.art, false)
						end
					end)
				end
				if at then
					Effects.damageNumber(at + Vector3.new(0, p and p.r or 2, 0), h.damage, h.crit)
				end
			end
			for _, c in result.chain do
				local a = if pigs[c.from] then worldOf(pigs[c.from]) else lastBroken[c.from]
				local b = if pigs[c.to] then worldOf(pigs[c.to]) else lastBroken[c.to]
				if a and b then
					Effects.lightning(a, b)
				end
			end
			if #result.chain > 0 then
				Sound.play("zap")
			end
			if result.crit then
				Sound.play("crit")
				Effects.shake(0.16, 0.5)
			else
				Sound.play("hit")
			end
		end)
	end

	local function onTap(screen: Vector2)
		if ending or not gate:trySwing(os.clock() * 1000) then
			return
		end
		local world = CameraRig.screenToFloor(screen.X, screen.Y, TAP_HEIGHT)
		if not world then
			return
		end
		local tx = math.clamp(world.X - o.X, -halfW, halfW)
		local tz = math.clamp(world.Z - o.Z, -halfD, halfD)
		local impact = Vector3.new(o.X + tx, o.Y, o.Z + tz)
		Effects.swingHammer(impact, swingTime, hammerSize)
		Sound.play("swing")

		local targets = {}
		for _, p in pigs do
			table.insert(targets, { id = p.id, x = p.x, y = p.z, radius = p.r, hp = p.hp })
		end
		-- 범위·번개 순서가 매번 같도록 id 순으로
		table.sort(targets, function(a, b)
			return a.id < b.id
		end)
		local result = Combat.resolveTap({ x = tx, y = tz }, targets, stats, U, math.random)
		if #result.hits > 0 then
			run:registerHit()
		end
		for _, h in result.hits do
			local p = pigs[h.id]
			if p then
				p.hp -= h.damage
			end
		end
		showHits(result, impact)
		for _, h in result.hits do
			local p = pigs[h.id]
			if p and p.hp <= 0 then
				breakPig(p)
			end
		end
	end

	table.insert(conns, UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
			onTap(Vector2.new(input.Position.X, input.Position.Y))
		end
	end))

	for _, req in run:start() do
		spawnPig(req, false)
	end

	table.insert(conns, RunService.Heartbeat:Connect(function(dt)
		if ending then
			return
		end
		for _, req in run:update(dt) do
			spawnPig(req, true)
		end
		movePigs(math.min(dt, 0.1), os.clock())
		hud.update({
			stage = cfg.stage,
			timeLeft = run.timeLeft,
			coins = save.coins + shownCoins,
			remaining = run:remaining(),
			total = cfg.totalPigs,
			broken = run.broken,
		})
		if run.status ~= "playing" then
			ending = true
			task.delay(END_DELAY, function()
				finished:Fire()
			end)
		end
	end))

	finished.Event:Wait()
	for _, c in conns do
		c:Disconnect()
	end
	Effects.reset()
	folder:Destroy()
	finished:Destroy()

	return {
		cleared = run.status == "cleared",
		normalBroken = run.broken - run.goldBroken,
		goldBroken = run.goldBroken,
		bestCombo = run.bestCombo,
		remaining = run:remaining(),
	}
end

return Play
