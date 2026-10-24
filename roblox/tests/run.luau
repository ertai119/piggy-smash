-- 공유 로직 테스트. 로블록스 없이 Lune 으로 돌린다: `lune run tests/run`
-- 모듈의 `require(script.Parent.X)` 를 흉내 내려고 직접 불러온다.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")

local SHARED = "src/shared"
local cache = {}

local function loadModule(name: string)
	if cache[name] ~= nil then
		return cache[name]
	end
	local path = `{SHARED}/{name}.luau`
	local parent = setmetatable({}, {
		__index = function(_, child)
			return { __module = child }
		end,
	})
	local env = {
		script = { Parent = parent },
		require = function(ref)
			if type(ref) == "table" and ref.__module then
				return loadModule(ref.__module)
			end
			return require(ref)
		end,
	}
	local chunk = luau.load(fs.readFile(path), { debugName = path, environment = env })
	local result = chunk()
	cache[name] = result
	return result
end

local function deepEqual(a: any, b: any): boolean
	if type(a) ~= type(b) then
		return false
	end
	if type(a) ~= "table" then
		return a == b
	end
	for k, v in a do
		if not deepEqual(v, b[k]) then
			return false
		end
	end
	for k in b do
		if a[k] == nil then
			return false
		end
	end
	return true
end

local function show(v: any): string
	if type(v) ~= "table" then
		return tostring(v)
	end
	local keys = {}
	for k in v do
		table.insert(keys, k)
	end
	table.sort(keys, function(x, y)
		return tostring(x) < tostring(y)
	end)
	local parts = {}
	for _, k in keys do
		table.insert(parts, `{k}={show(v[k])}`)
	end
	return "{" .. table.concat(parts, ", ") .. "}"
end

local t = {}
function t.eq(actual: any, expected: any, msg: string?)
	if not deepEqual(actual, expected) then
		error(`{msg or "eq"}: expected {show(expected)}, got {show(actual)}`, 2)
	end
end
function t.near(actual: number, expected: number, msg: string?)
	if math.abs(actual - expected) > 1e-6 then
		error(`{msg or "near"}: expected ≈{expected}, got {actual}`, 2)
	end
end
function t.ok(cond: any, msg: string?)
	if not cond then
		error(msg or "expected truthy", 2)
	end
end
function t.fails(fn: () -> (), msg: string?)
	if pcall(fn) then
		error(msg or "expected error", 2)
	end
end

local passed, failed = 0, 0
local specs = {}
for _, file in fs.readDir("tests") do
	if file:match("%.spec%.luau$") then
		table.insert(specs, file)
	end
end
table.sort(specs)

for _, file in specs do
	local chunk = luau.load(fs.readFile(`tests/{file}`), { debugName = file })
	local cases = chunk()(loadModule, t)
	for _, case in cases do
		local ok, err = pcall(case[2])
		if ok then
			passed += 1
		else
			failed += 1
			print(`✗ {file} › {case[1]}\n    {err}`)
		end
	end
end

print(`{passed} passed, {failed} failed`)
process.exit(if failed > 0 then 1 else 0)
