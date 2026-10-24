--!strict
-- 한 스테이지의 진행 상태. 화면과 무관한 규칙만 담는다.
local Balance = require(script.Parent.Balance)

export type RunStatus = "playing" | "cleared" | "failed"
export type SpawnRequest = { kind: Balance.PigKind, hp: number }

local StageRun = {}
StageRun.__index = StageRun

-- 큰 프레임 간격(창 전환 직후 등)이 타이머를 뭉텅이로 깎지 않게 자르는 상한(초)
StageRun.MAX_DT = 0.25
-- 이 시간(초) 동안 아무것도 못 맞히면 콤보가 끊긴다
StageRun.COMBO_WINDOW = 1.5

type Fields = {
	cfg: Balance.StageConfig,
	rng: () -> number,
	timeLeft: number,
	status: RunStatus,
	spawned: number,
	broken: number,
	alive: number,
	coinsEarned: number,
	goldBroken: number,
	combo: number,
	bestCombo: number,
	spawnTimer: number,
	sinceHit: number,
}
export type StageRun = typeof(setmetatable({} :: Fields, StageRun))

function StageRun.new(cfg: Balance.StageConfig, rng: () -> number): StageRun
	return setmetatable({
		cfg = cfg,
		rng = rng,
		timeLeft = cfg.timeLimit,
		status = "playing" :: RunStatus,
		spawned = 0,
		broken = 0,
		alive = 0,
		coinsEarned = 0,
		goldBroken = 0,
		combo = 0,
		bestCombo = 0,
		spawnTimer = 0,
		sinceHit = 0,
	}, StageRun)
end

function StageRun.remaining(self: StageRun): number
	return self.cfg.totalPigs - self.broken
end

local function spawn(self: StageRun): SpawnRequest
	local kind: Balance.PigKind = if self.rng() < self.cfg.goldChance then "gold" else "normal"
	self.spawned += 1
	self.alive += 1
	return { kind = kind, hp = Balance.pigHp(self.cfg, kind) }
end

function StageRun.start(self: StageRun): { SpawnRequest }
	local out = {}
	for _ = 1, math.min(self.cfg.maxOnScreen, self.cfg.totalPigs) do
		table.insert(out, spawn(self))
	end
	return out
end

function StageRun.update(self: StageRun, dt: number): { SpawnRequest }
	if self.status ~= "playing" then
		return {}
	end
	local step = math.min(math.max(dt, 0), StageRun.MAX_DT)

	self.sinceHit += step
	if self.sinceHit >= StageRun.COMBO_WINDOW then
		self.combo = 0
	end

	local out = {}
	if self.alive < self.cfg.maxOnScreen and self.spawned < self.cfg.totalPigs then
		self.spawnTimer += step
		if self.spawnTimer >= self.cfg.spawnInterval then
			self.spawnTimer -= self.cfg.spawnInterval
			table.insert(out, spawn(self))
		end
	else
		self.spawnTimer = 0
	end

	self.timeLeft -= step
	if self.timeLeft <= 0 then
		self.timeLeft = 0
		self.status = "failed"
	end
	return out
end

-- 한 번의 터치로 무언가를 맞혔을 때 한 번 부른다
function StageRun.registerHit(self: StageRun)
	self.combo += 1
	self.sinceHit = 0
	if self.combo > self.bestCombo then
		self.bestCombo = self.combo
	end
end

-- 받은 동전을 돌려준다. 판이 끝난 뒤에는 0.
function StageRun.pigBroken(self: StageRun, kind: Balance.PigKind): number
	if self.status ~= "playing" then
		return 0
	end
	local coins = Balance.pigCoins(self.cfg, kind)
	self.broken += 1
	self.alive = math.max(0, self.alive - 1)
	self.coinsEarned += coins
	if kind == "gold" then
		self.goldBroken += 1
	end
	if self.broken >= self.cfg.totalPigs then
		self.status = "cleared"
	end
	return coins
end

return StageRun
