-- 기본 3인칭 카메라를 그대로 쓰고, 타격 흔들림만 얹는다(캐릭터 Humanoid.CameraOffset).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CameraRig = {}

local shakeUntil = 0
local shakePower = 0
local shaking = false

local function humanoid(): Humanoid?
	local character = Players.LocalPlayer.Character
	return if character then character:FindFirstChildOfClass("Humanoid") else nil
end

function CameraRig.start()
	RunService:BindToRenderStep("PiggyShake", Enum.RenderPriority.Camera.Value - 1, function()
		local h = humanoid()
		if not h then
			return
		end
		if os.clock() < shakeUntil then
			local p = shakePower
			h.CameraOffset = Vector3.new((math.random() - 0.5) * p, (math.random() - 0.5) * p, (math.random() - 0.5) * p)
			shaking = true
		elseif shaking then
			h.CameraOffset = Vector3.zero
			shaking = false
		end
	end)
end

-- power: 흔들림 폭(스터드)
function CameraRig.shake(seconds: number, power: number)
	local now = os.clock()
	shakePower = if now < shakeUntil then math.max(shakePower, power) else power
	shakeUntil = math.max(shakeUntil, now + seconds)
end

-- 화면 좌표(GUI 기준)에서 카메라 앞으로 depth 만큼 떨어진 점(동전이 HUD로 날아갈 때)
function CameraRig.screenToNear(x: number, y: number, depth: number): Vector3
	local ray = workspace.CurrentCamera:ScreenPointToRay(x, y)
	return ray.Origin + ray.Direction * depth
end

return CameraRig
