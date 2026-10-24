--!strict
-- 서버·클라이언트가 함께 쓰는 원격 호출 이름. 서버가 만들고 클라이언트는 기다린다.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = {}

Net.FUNCTIONS = { "GetSave", "StartStage", "FinishStage", "BuySkill", "SetMuted" }

local FOLDER = "PiggySmashRemotes"

local function folder(): Folder
	if RunService:IsServer() then
		local f = ReplicatedStorage:FindFirstChild(FOLDER) :: Folder?
		if not f then
			local created = Instance.new("Folder")
			created.Name = FOLDER
			created.Parent = ReplicatedStorage
			f = created
		end
		return f :: Folder
	end
	return ReplicatedStorage:WaitForChild(FOLDER) :: Folder
end

function Net.get(name: string): RemoteFunction
	local f = folder()
	if RunService:IsServer() then
		local rf = f:FindFirstChild(name) :: RemoteFunction?
		if not rf then
			local created = Instance.new("RemoteFunction")
			created.Name = name
			created.Parent = f
			rf = created
		end
		return rf :: RemoteFunction
	end
	return f:WaitForChild(name) :: RemoteFunction
end

return Net
