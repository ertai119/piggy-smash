--!strict
-- 캐릭터에게 망치를 쥐여 주고, 망치 크기(범위 공격 레벨)만큼 캐릭터도 함께 키운다.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HammerTool = require(Shared.HammerTool)
local Upgrades = require(Shared.Upgrades)

local Character = {}

-- 같은 캐릭터에 두 번 겹쳐 하지 않도록 플레이어마다 순번을 둔다
local versions: { [Player]: number } = {}

function Character.equip(player: Player, areaLevel: number)
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	local version = (versions[player] or 0) + 1
	versions[player] = version
	local scale = Upgrades.hammerScale(areaLevel)

	-- 망치를 먼저 내려놓고 캐릭터 크기를 바꾼 뒤, 그 크기에 맞는 망치를 새로 쥐여 준다
	humanoid:UnequipTools()
	local holders: { Instance? } = { character, player:FindFirstChildOfClass("Backpack") }
	for _, holder in holders do
		if holder then
			for _, child in holder:GetChildren() do
				if child:IsA("Tool") and child.Name == HammerTool.NAME then
					child:Destroy()
				end
			end
		end
	end
	if math.abs(character:GetScale() - scale) > 1e-3 then
		character:ScaleTo(scale)
	end
	if versions[player] ~= version or player.Character ~= character then
		return
	end
	local tool = HammerTool.build(scale)
	tool.Parent = character
end

function Character.forget(player: Player)
	versions[player] = nil
end

return Character
