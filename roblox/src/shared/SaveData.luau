--!strict
-- 저장 데이터의 모양과 규칙. DataStore 입출력은 서버(SaveStore)가 맡고, 여기는 순수 함수만.
local Upgrades = require(script.Parent.Upgrades)

export type SaveData = {
	version: number,
	stage: number,
	coins: number,
	levels: Upgrades.SkillLevels,
	muted: boolean,
}

local SaveData = {}

SaveData.VERSION = 1

function SaveData.default(): SaveData
	local l = Upgrades.START_LEVELS
	return {
		version = SaveData.VERSION,
		stage = 1,
		coins = 0,
		levels = { power = l.power, speed = l.speed, area = l.area, crit = l.crit, chain = l.chain },
		muted = false,
	}
end

local function isCount(v: unknown): boolean
	return type(v) == "number" and v == v and v >= 0 and v == math.floor(v) and v ~= math.huge
end

-- 어떤 값이 와도 throw하지 않는다. 잘못된 필드만 기본값으로.
function SaveData.sanitize(raw: unknown): SaveData
	local save = SaveData.default()
	if type(raw) ~= "table" then
		return save
	end
	local d = raw :: { [string]: any }
	if isCount(d.stage) and d.stage >= 1 then
		save.stage = d.stage
	end
	if isCount(d.coins) then
		save.coins = d.coins
	end
	if type(d.muted) == "boolean" then
		save.muted = d.muted
	end
	if type(d.levels) == "table" then
		local levels = save.levels :: any
		for _, id in Upgrades.SKILL_ORDER do
			local v = d.levels[id]
			if isCount(v) and v >= (Upgrades.START_LEVELS :: any)[id] then
				levels[id] = v
			end
		end
	end
	return save
end

local function copy(data: SaveData): SaveData
	local l = data.levels
	return {
		version = data.version,
		stage = data.stage,
		coins = data.coins,
		levels = { power = l.power, speed = l.speed, area = l.area, crit = l.crit, chain = l.chain },
		muted = data.muted,
	}
end

-- 살 수 있으면 새 테이블을, 못 사면 받은 테이블을 그대로 돌려준다.
function SaveData.buySkill(data: SaveData, skill: Upgrades.SkillId): SaveData
	local level = (data.levels :: any)[skill] :: number
	if not Upgrades.canBuy(data.coins, skill, level) then
		return data
	end
	local out = copy(data)
	out.coins -= Upgrades.nextCost(skill, level);
	(out.levels :: any)[skill] = level + 1
	return out
end

-- 판이 끝났을 때 저장에 반영한다. 동전은 성공·실패와 관계없이 더하고, 클리어면 다음 스테이지로.
function SaveData.applyResult(data: SaveData, result: { stage: number, cleared: boolean, coinsEarned: number }): SaveData
	local out = copy(data)
	out.coins += result.coinsEarned
	if result.cleared then
		out.stage = math.max(data.stage, result.stage + 1)
	end
	return out
end

function SaveData.withMuted(data: SaveData, muted: boolean): SaveData
	local out = copy(data)
	out.muted = muted
	return out
end

return SaveData
