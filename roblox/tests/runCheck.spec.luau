return function(load, t)
	local RunCheck = load("RunCheck")
	local Balance = load("Balance")
	local c1 = Balance.stageConfig(1) -- 20마리, 화면 8, 0.35초 간격, 30초
	return {
		{ "honest clear is accepted", function()
			local r = RunCheck.settle(c1, 12, { normalBroken = 18, goldBroken = 2 })
			t.eq(r, { cleared = true, normalBroken = 18, goldBroken = 2, coinsEarned = 18 * 5 + 2 * 40 })
		end },
		{ "honest fail keeps coins", function()
			local r = RunCheck.settle(c1, 30.5, { normalBroken = 11, goldBroken = 1 })
			t.eq(r, { cleared = false, normalBroken = 11, goldBroken = 1, coinsEarned = 11 * 5 + 40 })
		end },
		{ "cannot break more pigs than could have spawned", function()
			local r = RunCheck.settle(c1, 0, { normalBroken = 20, goldBroken = 0 })
			t.eq(r.cleared, false)
			t.eq(r.normalBroken, 8 + math.floor(RunCheck.LATENCY_SLACK / 0.35))
		end },
		{ "caps totals and impossible gold counts", function()
			local r = RunCheck.settle(c1, 20, { normalBroken = 0, goldBroken = 999 })
			t.eq(r.normalBroken + r.goldBroken, 20)
			t.ok(r.goldBroken <= 7, `gold {r.goldBroken}`)
		end },
		{ "too slow is not a clear", function()
			t.eq(RunCheck.settle(c1, 40, { normalBroken = 20, goldBroken = 0 }).cleared, false)
		end },
		{ "junk claims count as zero", function()
			local r = RunCheck.settle(c1, 10, { normalBroken = "x", goldBroken = -5 })
			t.eq(r, { cleared = false, normalBroken = 0, goldBroken = 0, coinsEarned = 0 })
			t.eq(RunCheck.settle(c1, 10, { normalBroken = 0 / 0, goldBroken = math.huge }).coinsEarned, 0)
		end },
	}
end
