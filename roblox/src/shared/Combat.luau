--!strict
-- 터치(클릭) 한 번의 피해 계산과 연타 간격 제한. 화면·월드와 무관한 순수 규칙.
local Upgrades = require(script.Parent.Upgrades)

export type Target = {
	id: number,
	x: number,
	y: number,
	radius: number, -- 월드 거리(스터드 등). unit 을 곱한 뒤의 값
	hp: number,
}

export type HitKind = "direct" | "area" | "chain"
export type Hit = { id: number, damage: number, kind: HitKind, crit: boolean }
export type ChainLink = { from: number, to: number }
export type TapResult = { hits: { Hit }, chain: { ChainLink }, crit: boolean }

local function dist(ax: number, ay: number, bx: number, by: number): number
	local dx, dy = ax - bx, ay - by
	return math.sqrt(dx * dx + dy * dy)
end

local Combat = {}

-- 대상의 hp는 바꾸지 않는다. 순서: 직접 → 범위(대상 배열 순) → 번개(튄 순서).
-- unit: 스킬 수치(픽셀)를 월드 거리로 바꾸는 배율.
function Combat.resolveTap(
	tap: { x: number, y: number },
	targets: { Target },
	stats: Upgrades.HammerStats,
	unit: number,
	rng: () -> number
): TapResult
	local crit = stats.critChance > 0 and rng() < stats.critChance
	local mult = if crit then stats.critMultiplier else 1
	local function dmg(ratio: number): number
		return math.max(1, math.floor(stats.damage * ratio * mult + 0.5))
	end
	local hits: { Hit } = {}
	local chain: { ChainLink } = {}

	-- 망치 머리(원)가 저금통 원에 닿으면 직접 타격. 여럿이면 중심이 가장 가까운 것.
	local head = stats.headRadius * unit
	local direct: Target? = nil
	local best = math.huge
	for _, t in targets do
		local d = dist(tap.x, tap.y, t.x, t.y)
		if d <= t.radius + head and d < best then
			best = d
			direct = t
		end
	end
	if direct then
		table.insert(hits, { id = direct.id, damage = dmg(1), kind = "direct", crit = crit })
	end

	if stats.areaRadius > 0 then
		local r = stats.areaRadius * unit
		for _, t in targets do
			if t ~= direct and dist(tap.x, tap.y, t.x, t.y) <= r + t.radius then
				table.insert(hits, { id = t.id, damage = dmg(stats.areaRatio), kind = "area", crit = crit })
			end
		end
	end

	if direct and stats.chainJumps > 0 then
		local range = stats.chainRange * unit
		local struck = { [direct.id] = true }
		local from: Target = direct
		for _ = 1, stats.chainJumps do
			local nextT: Target? = nil
			local nearest = math.huge
			for _, t in targets do
				if not struck[t.id] then
					local d = dist(from.x, from.y, t.x, t.y)
					if d <= range and d < nearest then
						nearest = d
						nextT = t
					end
				end
			end
			if not nextT then
				break
			end
			struck[nextT.id] = true
			table.insert(chain, { from = from.id, to = nextT.id })
			table.insert(hits, { id = nextT.id, damage = dmg(stats.chainRatio), kind = "chain", crit = crit })
			from = nextT
		end
	end

	return { hits = hits, chain = chain, crit = crit }
end

-- 연타 간격 제한. 간격 안의 터치는 무시하고 쌓지 않는다.
local SwingGate = {}
SwingGate.__index = SwingGate

export type SwingGate = typeof(setmetatable({} :: { minIntervalMs: number, last: number }, SwingGate))

function SwingGate.new(minIntervalMs: number): SwingGate
	return setmetatable({ minIntervalMs = minIntervalMs, last = -math.huge }, SwingGate)
end

function SwingGate.setInterval(self: SwingGate, ms: number)
	self.minIntervalMs = ms
end

function SwingGate.trySwing(self: SwingGate, nowMs: number): boolean
	if nowMs - self.last < self.minIntervalMs then
		return false
	end
	self.last = nowMs
	return true
end

Combat.SwingGate = SwingGate

return Combat
