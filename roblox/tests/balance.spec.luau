return function(load, t)
	local Balance = load("Balance")
	local cfg = Balance.stageConfig
	return {
		{ "stage 1 is crowded from the start", function()
			local c = cfg(1)
			t.eq({ c.totalPigs, c.maxOnScreen, c.pigHp, c.timeLimit, c.pigSpeed, c.coinsPerPig, c.goldChance, c.spawnInterval },
				{ 20, 8, 30, 30, 40, 5, 0.08, 0.35 })
		end },
		{ "stage 10 values", function()
			local c = cfg(10)
			t.eq({ c.totalPigs, c.maxOnScreen, c.pigHp, c.timeLimit, c.pigSpeed, c.coinsPerPig }, { 56, 11, 133, 48, 67, 14 })
		end },
		{ "caps screen count, time and speed", function()
			local c = cfg(100)
			t.eq({ c.maxOnScreen, c.timeLimit, c.pigSpeed }, { 16, 60, 120 })
		end },
		{ "gets harder every stage and stays finite up to 300", function()
			for s = 2, 300 do
				local prev, c = cfg(s - 1), cfg(s)
				t.ok(c.pigHp >= prev.pigHp, `hp {s}`)
				t.ok(c.totalPigs > prev.totalPigs, `pigs {s}`)
				for _, v in { c.pigHp, c.coinsPerPig, Balance.pigHp(c, "gold"), Balance.pigCoins(c, "gold") } do
					t.ok(v == v and v < math.huge, `finite {s}`)
				end
			end
		end },
		{ "gold pigs are tougher and richer", function()
			local c = cfg(1)
			t.eq({ Balance.pigHp(c, "gold"), Balance.pigCoins(c, "gold"), Balance.pigHp(c, "normal"), Balance.pigCoins(c, "normal") }, { 150, 40, 30, 5 })
		end },
		{ "treats stage < 1 and junk as stage 1", function()
			t.eq(cfg(0).stage, 1)
			t.eq(cfg(0 / 0).stage, 1)
			t.eq(cfg(nil).stage, 1)
		end },
		{ "every stage can be cleared up to 500", function()
			for s = 1, 500 do
				local c = cfg(s)
				t.ok(c.maxOnScreen + c.timeLimit / c.spawnInterval >= c.totalPigs * 1.3, `stage {s}`)
			end
		end },
		{ "spawning speeds up but never below 0.1s", function()
			t.eq(cfg(1).spawnInterval, 0.35)
			t.ok(cfg(20).spawnInterval < cfg(10).spawnInterval)
			t.eq(cfg(500).spawnInterval, 0.1)
		end },
	}
end
