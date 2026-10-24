--!strict
-- 서버가 클라이언트의 판 결과를 믿을 수 있는 범위로 깎는다.
-- 판은 각 플레이어 화면에서만 돌기 때문에, 서버는 "그 시간 안에 이만큼 깰 수 있었나"만 확인한다.
local Balance = require(script.Parent.Balance)

local RunCheck = {}

-- 네트워크 지연 등으로 허용하는 오차(초)
RunCheck.LATENCY_SLACK = 3
-- 금 저금통 수 상한: 기대값의 이 배수 + GOLD_EXTRA (정상 플레이에서 넘을 일이 사실상 없다)
local GOLD_FACTOR = 3
local GOLD_EXTRA = 2

export type Claim = { normalBroken: unknown, goldBroken: unknown }
export type Settled = { cleared: boolean, normalBroken: number, goldBroken: number, coinsEarned: number }

local function count(v: unknown): number
	if type(v) ~= "number" or v ~= v or v == math.huge then
		return 0
	end
	return math.max(0, math.floor(v))
end

-- elapsed: 서버가 잰, 판 시작 요청부터 결과 보고까지의 시간(초)
function RunCheck.settle(cfg: Balance.StageConfig, elapsed: number, claim: Claim): Settled
	local gold = count(claim.goldBroken)
	local normal = count(claim.normalBroken)

	-- 처음 화면을 채운 수 + 그 뒤로 spawnInterval마다 하나씩. 이보다 많이 깰 수는 없다.
	local spawnable = cfg.maxOnScreen + math.floor(math.max(0, elapsed + RunCheck.LATENCY_SLACK) / cfg.spawnInterval)
	local cap = math.min(cfg.totalPigs, spawnable)

	local total = math.min(normal + gold, cap)
	gold = math.min(gold, total, math.ceil(total * cfg.goldChance * GOLD_FACTOR) + GOLD_EXTRA)
	normal = total - gold

	local cleared = total >= cfg.totalPigs and elapsed <= cfg.timeLimit + RunCheck.LATENCY_SLACK
	return {
		cleared = cleared,
		normalBroken = normal,
		goldBroken = gold,
		coinsEarned = normal * Balance.pigCoins(cfg, "normal") + gold * Balance.pigCoins(cfg, "gold"),
	}
end

return RunCheck
