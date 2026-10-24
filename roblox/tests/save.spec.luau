return function(load, t)
	local S = load("SaveData")
	local function with(over)
		local d = S.default()
		for k, v in over do
			d[k] = v
		end
		return d
	end
	return {
		{ "defaults for missing data", function()
			t.eq(S.sanitize(nil), S.default())
			t.eq(S.sanitize("nope"), S.default())
		end },
		{ "keeps valid data", function()
			local d = with({ stage = 7, coins = 3410, muted = true })
			d.levels.chain = 2
			t.eq(S.sanitize(d), d)
		end },
		{ "drops wrong types field by field", function()
			t.eq(S.sanitize({ stage = -3, coins = "lots", levels = { power = 0, chain = 2.5 }, muted = 1 }), S.default())
			local s = S.sanitize({ stage = 4, coins = 0 / 0 })
			t.eq({ s.stage, s.coins }, { 4, 0 })
			t.eq(S.sanitize({ coins = math.huge }).coins, 0)
		end },
		{ "buySkill spends coins without mutating", function()
			local d = with({ coins = 25 })
			local after = S.buySkill(d, "power")
			t.eq({ after.coins, after.levels.power, d.levels.power }, { 5, 2, 1 })
			t.ok(S.buySkill(after, "power") == after)
		end },
		{ "applyResult adds coins and advances on clear", function()
			local d = with({ stage = 3, coins = 100 })
			local c = S.applyResult(d, { stage = 3, cleared = true, coinsEarned = 50 })
			t.eq({ c.stage, c.coins }, { 4, 150 })
			local f = S.applyResult(d, { stage = 3, cleared = false, coinsEarned = 20 })
			t.eq({ f.stage, f.coins }, { 3, 120 })
			t.eq(S.applyResult(with({ stage = 5 }), { stage = 2, cleared = true, coinsEarned = 0 }).stage, 5)
		end },
	}
end
