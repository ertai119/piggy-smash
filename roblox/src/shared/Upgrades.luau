--!strict
-- 망치 스킬: 효과, 비용, 강화 화면 문구. 밸런스 조정은 이 파일의 상수만 바꾼다.

export type SkillId = "power" | "speed" | "area" | "crit" | "chain"
-- 0 = 잠김
export type SkillLevels = { power: number, speed: number, area: number, crit: number, chain: number }

export type HammerStats = {
	damage: number,
	minIntervalMs: number,
	areaRadius: number, -- 픽셀. 잠김이면 0
	areaRatio: number,
	critChance: number,
	critMultiplier: number,
	chainJumps: number,
	chainRange: number,
	chainRatio: number,
	headRadius: number, -- 망치 머리가 닿는 반지름(픽셀). 망치 크기만큼 커진다.
}

local Upgrades = {}

Upgrades.SKILL_ORDER = { "power", "speed", "area", "crit", "chain" } :: { SkillId }

Upgrades.SKILL_INFO = {
	power = { label = "파워", icon = "💥" },
	speed = { label = "연타 속도", icon = "⚡" },
	area = { label = "범위 공격", icon = "🌀" },
	crit = { label = "크리티컬", icon = "🎯" },
	chain = { label = "연쇄 번개", icon = "🔗" },
}

Upgrades.START_LEVELS = table.freeze({ power = 1, speed = 1, area = 0, crit = 0, chain = 0 }) :: SkillLevels

local AREA_RATIO = 0.5
local CRIT_MULTIPLIER = 3
local CHAIN_RANGE = 140
local CHAIN_RATIO = 0.6
-- 기본 망치(1배)의 머리 크기
local HEAD_RADIUS = 12
local HAMMER_GROWTH = 0.15
local HAMMER_MAX_SCALE = 2

local function round(v: number): number
	return math.floor(v + 0.5)
end

local function damageAt(l: number): number
	return round(10 * 1.25 ^ (l - 1))
end
local function intervalAt(l: number): number
	return math.max(80, round(200 * 0.92 ^ (l - 1)))
end
local function areaRadiusAt(l: number): number
	return if l > 0 then 30 + 12 * l else 0
end
local function critChanceAt(l: number): number
	return if l > 0 then math.min(0.5, 0.05 + 0.03 * (l - 1)) else 0
end
local function chainJumpsAt(l: number): number
	return if l > 0 then l + 1 else 0
end

-- { 해금 비용(잠김일 때), 레벨 1→2 기본 비용, 증가율 }
local COSTS: { [SkillId]: { number } } = {
	power = { 0, 20, 1.35 },
	speed = { 0, 25, 1.4 },
	area = { 300, 150, 1.4 },
	crit = { 500, 200, 1.4 },
	chain = { 1500, 400, 1.45 },
}

-- 범위 공격 레벨에 따른 망치 크기 배율. 그림과 머리 판정(headRadius)이 함께 커진다.
function Upgrades.hammerScale(areaLevel: number): number
	return math.min(HAMMER_MAX_SCALE, 1 + HAMMER_GROWTH * math.max(0, areaLevel))
end

function Upgrades.hammerStats(levels: SkillLevels): HammerStats
	return {
		damage = damageAt(math.max(1, levels.power)),
		minIntervalMs = intervalAt(math.max(1, levels.speed)),
		areaRadius = areaRadiusAt(levels.area),
		areaRatio = AREA_RATIO,
		critChance = critChanceAt(levels.crit),
		critMultiplier = CRIT_MULTIPLIER,
		chainJumps = chainJumpsAt(levels.chain),
		chainRange = CHAIN_RANGE,
		chainRatio = CHAIN_RATIO,
		headRadius = HEAD_RADIUS * Upgrades.hammerScale(levels.area),
	}
end

-- 지금 레벨에서 다음 레벨로 가는 비용. level 0이면 해금 비용.
function Upgrades.nextCost(skill: SkillId, level: number): number
	local c = COSTS[skill]
	if level <= 0 then
		return c[1]
	end
	return round(c[2] * c[3] ^ (level - 1))
end

function Upgrades.canBuy(coins: number, skill: SkillId, level: number): boolean
	return coins >= Upgrades.nextCost(skill, level)
end

local function effectText(skill: SkillId, level: number): string
	if skill == "power" then
		return `-{damageAt(level)}`
	elseif skill == "speed" then
		return string.format("초당 %.1f회", 1000 / intervalAt(level))
	elseif skill == "area" then
		return `반경 {areaRadiusAt(level)}`
	elseif skill == "crit" then
		return `{round(critChanceAt(level) * 100)}%`
	else
		return `{chainJumpsAt(level)}회`
	end
end

function Upgrades.describeUpgrade(skill: SkillId, level: number): { now: string, next: string }
	return {
		now = if level <= 0 then "잠김" else effectText(skill, level),
		next = effectText(skill, level + 1),
	}
end

function Upgrades.isSkill(v: unknown): boolean
	return type(v) == "string" and COSTS[v :: SkillId] ~= nil
end

return Upgrades
