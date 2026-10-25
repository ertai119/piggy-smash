--!strict
-- 서버: 진행 저장, 강화 구매, 판 결과 검증, 캐릭터에게 망치 쥐여 주기.
-- 판 자체(저금통·타격)는 각 클라이언트에서 돈다.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Balance = require(Shared.Balance)
local Net = require(Shared.Net)
local RunCheck = require(Shared.RunCheck)
local SaveData = require(Shared.SaveData)
local Upgrades = require(Shared.Upgrades)

local Arena = require(script.Parent.Arena)
local Character = require(script.Parent.Character)
local SaveStore = require(script.Parent.SaveStore)

local AUTOSAVE_SECONDS = 60

type ActiveRun = { stage: number, startedAt: number }
local runs: { [Player]: ActiveRun } = {}

Arena.build()

local function onCharacter(player: Player, character: Model)
	-- 기록을 불러온 뒤에야 망치 크기를 안다
	local data = SaveStore.waitFor(player)
	if not data or player.Character ~= character then
		return
	end
	character:WaitForChild("HumanoidRootPart", 10)
	Character.equip(player, data.levels.area)
end

local function onPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)
	if player.Character then
		task.spawn(onCharacter, player, player.Character)
	end
	SaveStore.load(player)
end

Players.PlayerAdded:Connect(onPlayer)
for _, p in Players:GetPlayers() do
	task.spawn(onPlayer, p)
end
Players.PlayerRemoving:Connect(function(player)
	runs[player] = nil
	Character.forget(player)
	SaveStore.release(player)
end)
game:BindToClose(SaveStore.flushAll)

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_SECONDS)
		for _, p in Players:GetPlayers() do
			task.spawn(SaveStore.flush, p)
		end
	end
end)

Net.get("GetSave").OnServerInvoke = function(player)
	return SaveStore.waitFor(player)
end

-- 스테이지 선택은 없다: 항상 저장된 스테이지를 한다
Net.get("StartStage").OnServerInvoke = function(player)
	local data = SaveStore.get(player)
	if not data then
		return nil
	end
	runs[player] = { stage = data.stage, startedAt = os.clock() }
	return data.stage
end

Net.get("FinishStage").OnServerInvoke = function(player, claim: unknown)
	local run = runs[player]
	local data = SaveStore.get(player)
	if not run or not data or type(claim) ~= "table" then
		return nil
	end
	runs[player] = nil
	local cfg = Balance.stageConfig(run.stage)
	local settled = RunCheck.settle(cfg, os.clock() - run.startedAt, claim :: RunCheck.Claim)
	local next = SaveData.applyResult(data, { stage = run.stage, cleared = settled.cleared, coinsEarned = settled.coinsEarned })
	SaveStore.set(player, next)
	task.spawn(SaveStore.flush, player)
	return {
		save = next,
		stage = run.stage,
		cleared = settled.cleared,
		coinsEarned = settled.coinsEarned,
		goldBroken = settled.goldBroken,
	}
end

-- 강화는 판과 판 사이에서만
Net.get("BuySkill").OnServerInvoke = function(player, skill: unknown)
	local data = SaveStore.get(player)
	if not data or runs[player] or not Upgrades.isSkill(skill) then
		return data
	end
	local next = SaveData.buySkill(data, skill :: Upgrades.SkillId)
	if next ~= data then
		SaveStore.set(player, next)
		if skill == "area" then
			-- 망치가 커지면 캐릭터도 함께 커진다
			task.spawn(Character.equip, player, next.levels.area)
		end
	end
	return next
end

Net.get("SetMuted").OnServerInvoke = function(player, muted: unknown)
	local data = SaveStore.get(player)
	if data and type(muted) == "boolean" then
		SaveStore.set(player, SaveData.withMuted(data, muted))
	end
	return SaveStore.get(player)
end
