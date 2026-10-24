return function(load, t)
	local Combat = load("Combat")
	local U = load("Upgrades")
	local base = U.hammerStats(U.START_LEVELS)
	local function T(id, x, y)
		return { id = id, x = x, y = y, radius = 20, hp = 30 }
	end
	local function with(over)
		local s = table.clone(base)
		for k, v in over do
			s[k] = v
		end
		return s
	end
	local never = function()
		return 0.99
	end
	local always = function()
		return 0
	end
	local tap = Combat.resolveTap
	local function ids(r)
		local out = {}
		for _, h in r.hits do
			table.insert(out, h.id)
		end
		return out
	end
	return {
		{ "hits the target closest to the tap", function()
			local r = tap({ x = 15, y = 0 }, { T(1, 0, 0), T(2, 25, 0) }, base, 1, never)
			t.eq(r.hits, { { id = 2, damage = 10, kind = "direct", crit = false } })
		end },
		{ "hammer head reaches past the edge, further when bigger", function()
			local ts = { T(1, 0, 0) }
			t.eq(ids(tap({ x = 30, y = 0 }, ts, base, 1, never)), { 1 })
			t.eq(ids(tap({ x = 40, y = 0 }, ts, base, 1, never)), {})
			local big = with({ headRadius = 24 })
			t.eq(ids(tap({ x = 40, y = 0 }, ts, big, 1, never)), { 1 })
			t.eq(ids(tap({ x = 40, y = 0 }, ts, big, 0.5, never)), {})
		end },
		{ "crit multiplies all damage", function()
			local r = tap({ x = 0, y = 0 }, { T(1, 0, 0), T(2, 50, 0) }, with({ critChance = 0.1, areaRadius = 60 }), 1, always)
			t.eq(r.crit, true)
			t.eq(r.hits, {
				{ id = 1, damage = 30, kind = "direct", crit = true },
				{ id = 2, damage = 15, kind = "area", crit = true },
			})
		end },
		{ "area scales with unit and applies on a miss", function()
			local s = with({ areaRadius = 40 })
			t.eq(tap({ x = 0, y = 0 }, { T(1, 55, 0) }, s, 1, never).hits, { { id = 1, damage = 5, kind = "area", crit = false } })
			t.eq(tap({ x = 0, y = 0 }, { T(1, 55, 0) }, s, 0.5, never).hits, {})
		end },
		{ "chain jumps to nearest unhit targets in range", function()
			local r = tap({ x = 0, y = 0 }, { T(1, 0, 0), T(2, 100, 0), T(3, 200, 0), T(4, 500, 0) }, with({ chainJumps = 2 }), 1, never)
			t.eq(r.chain, { { from = 1, to = 2 }, { from = 2, to = 3 } })
			t.eq({ r.hits[2].id, r.hits[2].damage, r.hits[3].id, r.hits[3].damage }, { 2, 6, 3, 6 })
		end },
		{ "no chain on a miss", function()
			t.eq(tap({ x = 300, y = 300 }, { T(1, 0, 0) }, with({ chainJumps = 3 }), 1, never).chain, {})
		end },
		{ "SwingGate ignores taps inside the interval", function()
			local g = Combat.SwingGate.new(200)
			t.eq({ g:trySwing(1000), g:trySwing(1050), g:trySwing(1100), g:trySwing(1200), g:trySwing(1201) },
				{ true, false, false, true, false })
			local g2 = Combat.SwingGate.new(200)
			g2:trySwing(0)
			g2:setInterval(80)
			t.eq(g2:trySwing(80), true)
		end },
	}
end
