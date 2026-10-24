return function(load, t)
	local U = load("Upgrades")
	local function levels(over)
		local l = { power = 1, speed = 1, area = 0, crit = 0, chain = 0 }
		for k, v in over or {} do
			l[k] = v
		end
		return l
	end
	return {
		{ "starting hammer", function()
			t.eq(U.hammerStats(U.START_LEVELS), {
				damage = 10, minIntervalMs = 200, areaRadius = 0, areaRatio = 0.5,
				critChance = 0, critMultiplier = 3, chainJumps = 0, chainRange = 140, chainRatio = 0.6,
				headRadius = 12,
			})
		end },
		{ "levels raise stats", function()
			local s = U.hammerStats({ power = 5, speed = 30, area = 2, crit = 3, chain = 1 })
			t.eq({ s.damage, s.minIntervalMs, s.areaRadius, s.chainJumps }, { 24, 80, 54, 2 })
			t.near(s.critChance, 0.11)
		end },
		{ "crit chance caps at 50%", function()
			t.eq(U.hammerStats(levels({ crit = 99 })).critChance, 0.5)
		end },
		{ "unlock and level costs", function()
			t.eq({ U.nextCost("power", 1), U.nextCost("power", 2), U.nextCost("area", 0), U.nextCost("crit", 0), U.nextCost("chain", 0), U.nextCost("chain", 1) },
				{ 20, 27, 300, 500, 1500, 400 })
			t.eq(U.canBuy(19, "power", 1), false)
			t.eq(U.canBuy(20, "power", 1), true)
			for _, k in U.SKILL_ORDER do
				t.ok(U.nextCost(k, 200) < math.huge)
			end
		end },
		{ "describeUpgrade shows before and after", function()
			t.eq(U.describeUpgrade("power", 1), { now = "-10", next = "-13" })
			t.eq(U.describeUpgrade("speed", 1), { now = "초당 5.0회", next = "초당 5.4회" })
			t.eq(U.describeUpgrade("area", 0), { now = "잠김", next = "반경 42" })
			t.eq(U.describeUpgrade("chain", 0), { now = "잠김", next = "2회" })
			t.eq(U.describeUpgrade("crit", 1).now, "5%")
		end },
		{ "hammer grows 15% per area level and caps at 2x", function()
			t.eq(U.hammerScale(0), 1)
			t.near(U.hammerScale(1), 1.15)
			t.near(U.hammerScale(3), 1.45)
			t.eq(U.hammerScale(7), 2)
			t.eq(U.hammerScale(50), 2)
			t.near(U.hammerStats(levels({ area = 1 })).headRadius, 13.8)
			t.eq(U.hammerStats(levels({ area = 7 })).headRadius, 24)
		end },
		{ "isSkill rejects junk", function()
			t.ok(U.isSkill("chain"))
			t.ok(not U.isSkill("gold"))
			t.ok(not U.isSkill(5))
			t.ok(not U.isSkill(nil))
		end },
	}
end
