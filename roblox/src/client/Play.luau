-- 한 판: 마당에 저금통이 돌아다니고, 내 캐릭터가 망치를 들고 다니며 클릭/터치로 내려친다.
-- 판은 이 플레이어 화면에서만 돈다(저금통은 다른 사람에게 안 보인다). 결과는 서버가 검증한다.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Balance = require(Shared.Balance)
local Combat = require(Shared.Combat)
local Config = require(Shared.Config)
local StageRun = require(Shared.StageRun)
local HammerTool = require(Shared.HammerTool)
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
-- 내려칠 때 이 거리(스터드, 망치 크기 배율 곱하기 전) 안의 가장 가까운 저금통 쪽으로 몸을 돌린다
local AIM_EXTRA = 6
-- 저금통이 내 캐릭터 바로 옆에서 태어나지 않게 하는 거리
local SPAWN_CLEAR = 10
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
	r: number, -- 판정 반지름(스터드)
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

	local function rootPart(): BasePart?
		local character = Players.LocalPlayer.Character
		return if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	end

	local function spawnPig(req: StageRun.SpawnRequest, popIn: boolean)
		local r = radiusOf(req.kind)
		local speed = cfg.pigSpeed * U * rand(0.75, 1.25)
		local dir = rand(0, math.pi * 2)
		local art = Art.pig(req.kind, r * Config.PIG_ART_RATIO)
		local root = rootPart()
		local x, z = 0, 0
		for _ = 1, 6 do
			x, z = rand(-halfW + r, halfW - r), rand(-halfD + r, halfD - r)
			if not root or Vector2.new(o.X + x - root.Position.X, o.Z + z - root.Position.Z).Magnitude > SPAWN_CLEAR * hammerSize then
				break
			end
		end
		local pig: Pig = {
			id = nextId,
			kind = req.kind,
			hp = req.hp,
			maxHp = req.hp,
			x = x,
			z = z,
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
			local pos = worldOf(p) + Vector3.new(0, math.abs(math.sin(now * 12 + p.id)) * 0.1 * p.r, 0)
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
			Effects.breakPig(at, gold, p.r * Config.PIG_ART_RATIO)
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
					Effects.damageNumber(at + Vector3.new(0, (if p then p.r else 3) * Config.PIG_ART_RATIO * 1.6, 0), h.damage, h.crit)
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

	-- 내려칠 망치 위치를 캐릭터 기준으로 잡는다. 가까운 저금통이 있으면 그쪽으로 몸을 돌린다.
	type Aim = { grip: Vector3, look: Vector3, down: number, foot: Vector3 }
	local function aim(character: Model): Aim?
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or humanoid.Health <= 0 then
			return nil
		end
		local s = hammerSize
		local len = HammerTool.LENGTH * s
		local flat = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
		local look = if flat.Magnitude > 1e-3 then flat.Unit else Vector3.new(0, 0, -1)

		local best, bestDist = nil, len + stats.headRadius * U + AIM_EXTRA * s
		for _, p in pigs do
			local d = Vector2.new(o.X + p.x - root.Position.X, o.Z + p.z - root.Position.Z).Magnitude - p.r
			if d < bestDist then
				best, bestDist = p, d
			end
		end
		if best then
			local to = Vector3.new(o.X + best.x - root.Position.X, 0, o.Z + best.z - root.Position.Z)
			if to.Magnitude > 1e-3 then
				look = to.Unit
				root.CFrame = CFrame.lookAt(root.Position, root.Position + look)
			end
		end

		local right = look:Cross(Vector3.yAxis)
		local groundY = root.Position.Y - humanoid.HipHeight - root.Size.Y / 2
		local grip = root.Position + Vector3.yAxis * (1.2 * s) + right * (0.9 * s)
		local down = math.asin(math.clamp((groundY + 0.9 * s - grip.Y) / len, -1, 1))
		local foot = Vector3.new(grip.X, groundY, grip.Z) + look * (len * math.cos(down))
		return { grip = grip, look = look, down = down, foot = foot }
	end

	-- 휘두르는 동안 손에 든 망치는 숨기고(내 화면에서만) 연출용 망치를 보여 준다
	local hideToken = 0
	local function hideHeld(tool: Tool, seconds: number)
		hideToken += 1
		local token = hideToken
		for _, p in tool:GetDescendants() do
			if p:IsA("BasePart") then
				p.LocalTransparencyModifier = 1
			end
		end
		-- 기본 Animate 스크립트가 이 값을 보고 팔 휘두르는 동작을 한다
		local anim = Instance.new("StringValue")
		anim.Name = "toolanim"
		anim.Value = "Slash"
		anim.Parent = tool
		task.delay(seconds, function()
			-- 연타 중이면 마지막 휘두르기가 끝날 때 다시 보인다
			if token ~= hideToken then
				return
			end
			for _, p in tool:GetDescendants() do
				if p:IsA("BasePart") then
					p.LocalTransparencyModifier = 0
				end
			end
		end)
	end

	local function onSwing(tool: Tool)
		local character = tool.Parent
		if ending or not character or not character:IsA("Model") or not gate:trySwing(os.clock() * 1000) then
			return
		end
		local a = aim(character)
		if not a then
			return
		end
		local tx = math.clamp(a.foot.X - o.X, -halfW, halfW)
		local tz = math.clamp(a.foot.Z - o.Z, -halfD, halfD)
		local impact = Vector3.new(a.foot.X, o.Y, a.foot.Z)
		hideHeld(tool, swingTime + 0.15)
		Effects.swingHammer(a.grip, a.look, a.down, swingTime, hammerSize)
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

	-- 망치(Tool)는 서버가 쥐여 주고, 강화·리스폰 때 새로 바뀐다. 새 망치가 생길 때마다 연결한다.
	local hooked: { [Tool]: boolean } = {}
	local function hookTool(child: Instance)
		if child:IsA("Tool") and child.Name == HammerTool.NAME and not hooked[child] then
			hooked[child] = true
			table.insert(conns, child.Activated:Connect(function()
				onSwing(child)
			end))
		end
	end
	local function hookCharacter(character: Model)
		for _, child in character:GetChildren() do
			hookTool(child)
		end
		table.insert(conns, character.ChildAdded:Connect(hookTool))
	end
	if Players.LocalPlayer.Character then
		hookCharacter(Players.LocalPlayer.Character)
	end
	table.insert(conns, Players.LocalPlayer.CharacterAdded:Connect(hookCharacter))

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
