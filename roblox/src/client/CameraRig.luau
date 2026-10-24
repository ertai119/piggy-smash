-- 경기장을 내려다보는 고정 카메라. 화면 비율이 바뀌면 경기장이 꽉 차게 거리를 다시 잡는다.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local CameraRig = {}

local FOV = 40
local PITCH = math.rad(68) -- 수평에서 내려다보는 각도
local MARGIN = 3 -- 경기장 바깥 여유(스터드)
local HUD_SHARE = 0.2 -- 화면 위쪽 HUD가 차지하는 비율

local camera = workspace.CurrentCamera
local base = CFrame.new()
local shakeUntil = 0
local shakePower = 0

local function fit()
	local vp = camera.ViewportSize
	local aspect = if vp.Y > 0 then vp.X / vp.Y else 16 / 9
	local halfV = math.tan(math.rad(FOV) / 2)
	local halfW = Config.ARENA_SIZE.X / 2 + MARGIN
	local halfD = Config.ARENA_SIZE.Y / 2 + MARGIN
	-- 기울어진 만큼 세로로 덜 보이는 것을 대충 보정하고, HUD 자리만큼 세로를 더 남긴다
	local needV = halfD * math.sin(PITCH) / halfV / (1 - HUD_SHARE)
	local needH = halfW / (halfV * aspect)
	local dist = math.max(needV, needH)
	local target = Config.ARENA_ORIGIN
	-- HUD 몫만큼 시선을 살짝 위(먼 쪽)로 올려 경기장이 아래쪽에 오게 한다
	local shift = dist * halfV * HUD_SHARE / math.sin(PITCH)
	local look = target + Vector3.new(0, 0, -shift)
	local eye = look + Vector3.new(0, math.sin(PITCH), math.cos(PITCH)) * dist
	base = CFrame.lookAt(eye, look)
end

function CameraRig.start()
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = FOV
	fit()
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	RunService:BindToRenderStep("PiggyCamera", Enum.RenderPriority.Camera.Value + 1, function()
		camera.CameraType = Enum.CameraType.Scriptable
		local cf = base
		local now = os.clock()
		if now < shakeUntil then
			local p = shakePower
			cf = cf * CFrame.new((math.random() - 0.5) * p, (math.random() - 0.5) * p, 0)
		end
		camera.CFrame = cf
	end)
end

-- power: 흔들림 폭(스터드)
function CameraRig.shake(seconds: number, power: number)
	local now = os.clock()
	shakePower = if now < shakeUntil then math.max(shakePower, power) else power
	shakeUntil = math.max(shakeUntil, now + seconds)
end

-- 화면 좌표(GUI 기준) → 경기장 바닥 높이 h 평면 위 점
function CameraRig.screenToFloor(x: number, y: number, h: number): Vector3?
	local ray = camera:ScreenPointToRay(x, y)
	local planeY = Config.ARENA_ORIGIN.Y + h
	if math.abs(ray.Direction.Y) < 1e-4 then
		return nil
	end
	local t = (planeY - ray.Origin.Y) / ray.Direction.Y
	if t <= 0 then
		return nil
	end
	return ray.Origin + ray.Direction * t
end

-- 화면 좌표(GUI 기준)에서 카메라 앞으로 depth 만큼 떨어진 점(동전이 HUD로 날아갈 때)
function CameraRig.screenToNear(x: number, y: number, depth: number): Vector3
	local ray = camera:ScreenPointToRay(x, y)
	return ray.Origin + ray.Direction * depth
end

return CameraRig
