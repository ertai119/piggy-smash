--!strict
local UNITS = { { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }

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
		if v >= u[1] then
			return string.format("%.1f%s", v / u[1], u[2])
		end
	end
	return tostring(v)
end

return Format
