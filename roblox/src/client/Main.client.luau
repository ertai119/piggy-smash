-- 클라이언트 흐름: 시작 → 플레이 → 결과 → (강화) → 플레이 ...
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local CameraRig = require(script.Parent.CameraRig)
local Play = require(script.Parent.Play)
local Sound = require(script.Parent.Sound)
local Ui = require(script.Parent.Ui)

local remotes = {
	getSave = Net.get("GetSave"),
	startStage = Net.get("StartStage"),
	finishStage = Net.get("FinishStage"),
	buySkill = Net.get("BuySkill"),
	setMuted = Net.get("SetMuted"),
}

for _, t in { Enum.CoreGuiType.PlayerList, Enum.CoreGuiType.Backpack, Enum.CoreGuiType.Health } do
	pcall(StarterGui.SetCoreGuiEnabled, StarterGui, t, false)
end

Ui.init()
CameraRig.start()

local save = nil
while not save do
	save = remotes.getSave:InvokeServer()
	if not save then
		task.wait(1)
	end
end
Sound.setMuted(save.muted)

local playStage, showUpgrade

local function toggleMute(hud)
	local muted = not Sound.isMuted()
	Sound.setMuted(muted)
	hud.setMuted(muted)
	task.spawn(function()
		local next = remotes.setMuted:InvokeServer(muted)
		if next then
			save = next
		end
	end)
end

function playStage()
	Ui.hideAll()
	local stage = remotes.startStage:InvokeServer()
	if not stage then
		-- 서버가 아직 기록을 못 불러왔다: 잠깐 뒤 다시
		task.wait(1)
		return playStage()
	end
	local hud
	hud = Ui.showHud(function()
		toggleMute(hud)
	end)
	hud.setMuted(Sound.isMuted())

	local outcome = Play.run(stage, save, hud)
	local result = remotes.finishStage:InvokeServer({
		normalBroken = outcome.normalBroken,
		goldBroken = outcome.goldBroken,
	})
	if result then
		save = result.save
	end
	Ui.hide("Hud")
	Ui.showResult({
		stage = stage,
		-- 서버 판정을 따른다(통신이 끊겼으면 화면 판정)
		cleared = if result then result.cleared else outcome.cleared,
		coinsEarned = if result then result.coinsEarned else 0,
		goldBroken = if result then result.goldBroken else outcome.goldBroken,
		bestCombo = outcome.bestCombo,
		remaining = outcome.remaining,
	}, showUpgrade, playStage)
end

function showUpgrade()
	Ui.hideAll()
	Ui.showUpgrade(save, function(skill)
		local next = remotes.buySkill:InvokeServer(skill)
		if next then
			save = next
		end
		return save
	end, playStage)
end

Ui.showTitle(playStage)
