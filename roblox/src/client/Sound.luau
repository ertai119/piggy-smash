-- 효과음. 같은 소리를 겹쳐 낼 수 있도록 소리마다 몇 개씩 돌려 쓴다.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage.Shared.Config)

local POOL = 4

local Sound = {}

local muted = false
local pools: { [string]: { Sound } } = {}
local cursor: { [string]: number } = {}

local folder = Instance.new("Folder")
folder.Name = "PiggySounds"
folder.Parent = SoundService

for name, def in Config.SOUNDS do
	local list = {}
	for i = 1, POOL do
		local s = Instance.new("Sound")
		s.Name = `{name}{i}`
		s.SoundId = def.id
		s.Volume = def.volume
		s.PlaybackSpeed = def.speed
		s.Parent = folder
		table.insert(list, s)
	end
	pools[name] = list
	cursor[name] = 1
end

function Sound.play(name: string)
	local list = pools[name]
	if muted or not list then
		return
	end
	local i = cursor[name]
	cursor[name] = i % #list + 1
	local s = list[i]
	-- 매번 살짝 다른 높이로 내면 연타가 덜 단조롭다
	s.PlaybackSpeed = Config.SOUNDS[name].speed * (0.92 + math.random() * 0.16)
	s.TimePosition = 0
	s:Play()
end

function Sound.setMuted(v: boolean)
	muted = v
end

function Sound.isMuted(): boolean
	return muted
end

return Sound
