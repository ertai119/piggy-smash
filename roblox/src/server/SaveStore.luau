--!strict
-- 플레이어 진행 상황을 DataStore에 읽고 쓴다.
-- 읽기에 실패하면 그 세션은 기본값으로 놀되 저장하지 않는다(진짜 기록을 덮어쓰지 않으려고).
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SaveData = require(ReplicatedStorage.Shared.SaveData)

local STORE_NAME = "PiggySmash_v1"
local RETRIES = 3

type Session = { data: SaveData.SaveData, canSave: boolean, dirty: boolean }

local SaveStore = {}

local store: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("[PiggySmash] DataStore를 쓸 수 없어 저장하지 않습니다:", result)
	end
end

local sessions: { [Player]: Session } = {}

local function keyFor(player: Player): string
	return "u_" .. player.UserId
end

local function withRetry<T>(fn: () -> T): (boolean, T | string)
	local lastErr: any = nil
	for attempt = 1, RETRIES do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastErr = result
		task.wait(attempt)
	end
	return false, tostring(lastErr)
end

function SaveStore.load(player: Player)
	local data = SaveData.default()
	local canSave = false
	local s = store
	if s then
		local ok, result = withRetry(function()
			return s:GetAsync(keyFor(player))
		end)
		if ok then
			data = SaveData.sanitize(result)
			canSave = true
		else
			warn(`[PiggySmash] {player.Name} 기록을 못 읽었습니다. 이번 접속은 저장하지 않습니다: {result}`)
		end
	end
	if player.Parent then
		sessions[player] = { data = data, canSave = canSave, dirty = false }
	end
end

-- 불러오기가 끝날 때까지 기다린다. 끝내 안 되면 nil.
function SaveStore.waitFor(player: Player, timeout: number?): SaveData.SaveData?
	local deadline = os.clock() + (timeout or 20)
	while not sessions[player] and player.Parent and os.clock() < deadline do
		task.wait(0.1)
	end
	local s = sessions[player]
	return if s then s.data else nil
end

function SaveStore.get(player: Player): SaveData.SaveData?
	local s = sessions[player]
	return if s then s.data else nil
end

function SaveStore.set(player: Player, data: SaveData.SaveData)
	local s = sessions[player]
	if s then
		s.data = data
		s.dirty = true
	end
end

function SaveStore.flush(player: Player)
	local sess = sessions[player]
	local s = store
	if not sess or not sess.canSave or not sess.dirty or not s then
		return
	end
	local data = sess.data
	sess.dirty = false
	local ok, err = withRetry(function()
		return s:UpdateAsync(keyFor(player), function()
			return data
		end)
	end)
	if not ok then
		sess.dirty = true
		warn(`[PiggySmash] {player.Name} 저장 실패: {err}`)
	end
end

function SaveStore.release(player: Player)
	SaveStore.flush(player)
	sessions[player] = nil
end

function SaveStore.flushAll()
	local threads = {}
	for player in sessions do
		table.insert(threads, task.spawn(SaveStore.flush, player))
	end
	-- BindToClose 안에서 부르므로 저장이 끝날 때까지 잠깐 기다린다
	local deadline = os.clock() + 20
	while os.clock() < deadline do
		local busy = false
		for _, t in threads do
			if coroutine.status(t) ~= "dead" then
				busy = true
			end
		end
		if not busy then
			break
		end
		task.wait(0.2)
	end
end

return SaveStore
