--!strict
-- 스테이지 난이도와 경제 곡선. 밸런스 조정은 이 파일의 상수만 바꾼다.
-- 웹판 src/logic/balance.ts 와 같은 수치. 거리·속도는 "픽셀" 단위이며 Config.STUDS_PER_PX 로 스터드로 바꾼다.

export type PigKind = "normal" | "gold"

export type StageConfig = {
	stage: number,
	totalPigs: number,
	maxOnScreen: number,
	pigHp: number,
	timeLimit: number, -- 초
	pigSpeed: number, -- 픽셀/초
	coinsPerPig: number,
	goldChance: number,
	goldHpMult: number,
	goldCoinMult: number,
	spawnInterval: number, -- 초
}

local PIGS_BASE = 20
local PIGS_PER_STAGE = 4
local SCREEN_BASE = 8
local SCREEN_EVERY = 3
local SCREEN_MAX = 16
local HP_BASE = 30
local HP_GROWTH = 1.18
local TIME_BASE = 30
local TIME_PER_STAGE = 2
local TIME_MAX = 60
local SPEED_BASE = 40
local SPEED_PER_STAGE = 3
local SPEED_MAX = 120
local COINS_BASE = 5
local COINS_GROWTH = 1.12
local GOLD_CHANCE = 0.08
local GOLD_HP_MULT = 5
local GOLD_COIN_MULT = 8
local SPAWN_INTERVAL = 0.35
local SPAWN_SHRINK = 0.96
local SPAWN_MIN = 0.1
-- 모든 저금통이 나오는 데 걸리는 시간의 이 배수만큼은 제한 시간을 보장한다(높은 스테이지도 깰 수 있게)
local TIME_SPAWN_MARGIN = 1.5

local function round(v: number): number
	return math.floor(v + 0.5)
end

local function round3(v: number): number
	return round(v * 1000) / 1000
end

local Balance = {}

function Balance.stageConfig(stage: number?): StageConfig
	local f = math.floor(tonumber(stage) or 1)
	local s = if f ~= f then 1 else math.max(1, f) -- NaN이면 1
	local n = s - 1
	local totalPigs = PIGS_BASE + PIGS_PER_STAGE * n
	local maxOnScreen = math.min(SCREEN_BASE + n // SCREEN_EVERY, SCREEN_MAX)
	local spawnInterval = math.max(SPAWN_MIN, round3(SPAWN_INTERVAL * SPAWN_SHRINK ^ n))
	local spawnTime = math.ceil(round3((totalPigs - maxOnScreen) * spawnInterval * TIME_SPAWN_MARGIN))
	return {
		stage = s,
		totalPigs = totalPigs,
		maxOnScreen = maxOnScreen,
		pigHp = round(HP_BASE * HP_GROWTH ^ n),
		timeLimit = math.max(math.min(TIME_BASE + TIME_PER_STAGE * n, TIME_MAX), spawnTime),
		pigSpeed = math.min(SPEED_BASE + SPEED_PER_STAGE * n, SPEED_MAX),
		coinsPerPig = round(COINS_BASE * COINS_GROWTH ^ n),
		goldChance = GOLD_CHANCE,
		goldHpMult = GOLD_HP_MULT,
		goldCoinMult = GOLD_COIN_MULT,
		spawnInterval = spawnInterval,
	}
end

function Balance.pigHp(cfg: StageConfig, kind: PigKind): number
	return if kind == "gold" then cfg.pigHp * cfg.goldHpMult else cfg.pigHp
end

function Balance.pigCoins(cfg: StageConfig, kind: PigKind): number
	return if kind == "gold" then cfg.coinsPerPig * cfg.goldCoinMult else cfg.coinsPerPig
end

return Balance
