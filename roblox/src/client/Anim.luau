-- 짧은 연출용 시간 함수. fn(t) 를 0→1 로 매 프레임 부르고, 끝나면 done().
local RunService = game:GetService("RunService")

local Anim = {}

Anim.ease = {
	linear = function(t: number)
		return t
	end,
	quadIn = function(t: number)
		return t * t
	end,
	quadOut = function(t: number)
		return 1 - (1 - t) * (1 - t)
	end,
	cubicIn = function(t: number)
		return t * t * t
	end,
	cubicOut = function(t: number)
		return 1 - (1 - t) ^ 3
	end,
	backOut = function(t: number)
		local c1, c3 = 1.70158, 2.70158
		return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
	end,
}

function Anim.run(duration: number, fn: (number) -> (), done: (() -> ())?, delay: number?): () -> ()
	local elapsed = -(delay or 0)
	local conn: RBXScriptConnection
	local finished = false
	local function stop(callDone: boolean)
		if finished then
			return
		end
		finished = true
		conn:Disconnect()
		if callDone and done then
			done()
		end
	end
	conn = RunService.RenderStepped:Connect(function(dt)
		elapsed += dt
		if elapsed < 0 then
			return
		end
		local t = if duration <= 0 then 1 else math.min(1, elapsed / duration)
		fn(t)
		if t >= 1 then
			stop(true)
		end
	end)
	-- 돌려준 함수를 부르면 곧바로 끝낸다(done 도 부른다)
	return function()
		stop(true)
	end
end

function Anim.after(seconds: number, fn: () -> ())
	task.delay(seconds, fn)
end

return Anim
