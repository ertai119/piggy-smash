return function(load, t)
	local F = load("Format").number
	return {
		{ "commas below 10,000", function()
			t.eq({ F(0), F(1240), F(9999), F(100), F(1000) }, { "0", "1,240", "9,999", "100", "1,000" })
		end },
		{ "abbreviates large numbers", function()
			t.eq({ F(12345), F(4560000), F(7800000000), F(2.5e12) }, { "12.3K", "4.6M", "7.8B", "2.5T" })
		end },
		{ "exponent beyond trillions, never NaN", function()
			t.eq({ F(3.2e16), F(math.huge), F(0 / 0) }, { "3.2e16", "∞", "0" })
		end },
		{ "floors fractions", function()
			t.eq(F(12.9), "12")
		end },
	}
end
