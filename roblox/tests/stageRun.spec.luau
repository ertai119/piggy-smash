return function(load, t)
	local StageRun = load("StageRun")
	local Balance = load("Balance")
	local noGold = function()
		return 0.99
	end
	local function small(over)
		local c = table.clone(Balance.stageConfig(1))
		c.totalPigs, c.maxOnScreen = 3, 2
		for k, v in over or {} do
			c[k] = v
		end
		return c
	end
	return {
		{ "fills the screen on start", function()
			local r = StageRun.new(Balance.stageConfig(1), noGold)
			t.eq(#r:start(), 8)
			t.eq(r.alive, 8)
		end },
		{ "tops up one pig per spawnInterval", function()
			local r = StageRun.new(small(), noGold)
			r:start()
			r:pigBroken("normal")
			t.eq(#r:update(0.2), 0)
			t.eq(r:update(0.2), { { kind = "normal", hp = 30 } })
			t.eq(r.spawned, 3)
			r:pigBroken("normal")
			t.eq(#r:update(1), 0)
		end },
		{ "rolls gold pigs", function()
			local r = StageRun.new(Balance.stageConfig(1), function()
				return 0.01
			end)
			t.eq(r:start()[1], { kind = "gold", hp = 150 })
		end },
		{ "clears when every pig is broken", function()
			local r = StageRun.new(small({ timeLimit = 1 }), noGold)
			r:start()
			r:update(0.2)
			r:update(0.2)
			r:pigBroken("normal")
			r:pigBroken("normal")
			r:update(0.25)
			r:update(0.25)
			r:update(0.08)
			r:pigBroken("gold")
			r:update(0.25)
			t.eq(r.status, "cleared")
			t.eq(r.coinsEarned, 50)
			t.eq(r.goldBroken, 1)
			t.eq(r:remaining(), 0)
		end },
		{ "fails when time runs out", function()
			local r = StageRun.new(small({ timeLimit = 0.3 }), noGold)
			r:start()
			r:update(0.25)
			r:update(0.25)
			t.eq(r.status, "failed")
			t.eq(r.timeLeft, 0)
			t.eq(r:pigBroken("normal"), 0)
		end },
		{ "clamps large frame delta", function()
			local r = StageRun.new(Balance.stageConfig(1), noGold)
			r:start()
			r:update(30)
			t.near(r.timeLeft, 30 - StageRun.MAX_DT)
			t.eq(r.status, "playing")
		end },
		{ "combo resets after 1.5s without hits", function()
			local r = StageRun.new(Balance.stageConfig(1), noGold)
			r:start()
			r:registerHit()
			r:update(0.2)
			r:registerHit()
			r:registerHit()
			t.eq(r.combo, 3)
			for _ = 1, 7 do
				r:update(0.25)
			end
			t.eq(r.combo, 0)
			t.eq(r.bestCombo, 3)
		end },
	}
end
