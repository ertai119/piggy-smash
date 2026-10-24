--!strict
local UNITS: { { size: number, suffix: string } } = {
	{ size = 1e12, suffix = "T" },
	{ size = 1e9, suffix = "B" },
	{ size = 1e6, suffix = "M" },
	{ size = 1e3, suffix = "K" },
}

local Format = {}

local function commas(v: number): string
	local s = tostring(v)
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

-- 화면에 보여줄 숫자. 1만 미만은 쉼표, 그 이상은 K/M/B/T, 1000조 이상은 지수 표기.
function Format.number(n: number): string
	if n ~= n then
		return "0"
	end
	if n == math.huge or n == -math.huge then
		return "∞"
	end
	local v = math.floor(n)
	if v < 10000 then
		return commas(v)
	end
	if v >= 1e15 then
		return (string.format("%.1e", v):gsub("%+", ""))
	end
	for _, u in UNITS do
		if v >= u.size then
			return string.format("%.1f%s", v / u.size, u.suffix)
		end
	end
	return tostring(v)
end

return Format
