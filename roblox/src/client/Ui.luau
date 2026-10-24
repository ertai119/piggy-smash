-- 화면: 시작, 플레이 HUD, 결과, 강화. 시안 C처럼 진한 남색 판, 굵은 검은 테두리, 큰 글씨.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Format = require(Shared.Format)
local Upgrades = require(Shared.Upgrades)
local Anim = require(script.Parent.Anim)
local Sound = require(script.Parent.Sound)

local C = Config.COLORS
local FONT = Enum.Font.FredokaOne
-- 결과 화면 버튼을 잠깐 잠가 마지막 연타가 버튼을 누르지 않게 한다
local BUTTON_LOCK = 0.6

local Ui = {}

local gui: ScreenGui
local scaler: UIScale
local screens: { [string]: GuiObject } = {}

-- ---------- 작은 부품 ----------

local function corner(parent: Instance, px: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, px)
	c.Parent = parent
end

local function stroke(parent: Instance, px: number, color: Color3?)
	local s = Instance.new("UIStroke")
	s.Thickness = px
	s.Color = color or C.black
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function textStroke(parent: Instance, px: number)
	local s = Instance.new("UIStroke")
	s.Thickness = px
	s.Color = C.black
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Parent = parent
end

local function label(parent: Instance, text: string, size: number, color: Color3?): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = FONT
	l.Text = text
	l.TextSize = size
	l.TextColor3 = color or C.white
	l.Size = UDim2.new(1, 0, 0, size + 8)
	textStroke(l, math.max(2, size / 8))
	l.Parent = parent
	return l
end

local function panel(parent: Instance, size: UDim2, color: Color3?): Frame
	local f = Instance.new("Frame")
	f.Size = size
	f.BackgroundColor3 = color or C.panel
	f.BorderSizePixel = 0
	corner(f, 14)
	stroke(f, 3)
	f.Parent = parent
	return f
end

local function button(parent: Instance, text: string, color: Color3, size: UDim2, onClick: () -> ()): TextButton
	local b = Instance.new("TextButton")
	b.Size = size
	b.BackgroundColor3 = color
	b.AutoButtonColor = true
	b.Font = FONT
	b.Text = text
	b.TextSize = 24
	b.TextColor3 = C.white
	b.BorderSizePixel = 0
	corner(b, 12)
	stroke(b, 3)
	textStroke(b, 2.5)
	b.Parent = parent
	b.Activated:Connect(function()
		if b:GetAttribute("Disabled") then
			return
		end
		Sound.play("click")
		onClick()
	end)
	return b
end

local function setEnabled(b: TextButton, on: boolean, color: Color3)
	b:SetAttribute("Disabled", not on)
	b.AutoButtonColor = on
	b.BackgroundColor3 = if on then color else Color3.fromRGB(96, 110, 140)
	b.TextTransparency = if on then 0 else 0.35
end

local function column(parent: Instance, gap: number)
	local l = Instance.new("UIListLayout")
	l.FillDirection = Enum.FillDirection.Vertical
	l.HorizontalAlignment = Enum.HorizontalAlignment.Center
	l.VerticalAlignment = Enum.VerticalAlignment.Center
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Padding = UDim.new(0, gap)
	l.Parent = parent
end

local function center(f: GuiObject)
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(0.5, 0.5)
end

local function screen(name: string): Frame
	local old = screens[name]
	if old then
		old:Destroy()
	end
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundTransparency = 1
	f.Parent = gui
	screens[name] = f
	return f
end

local function dim(parent: Instance)
	local d = Instance.new("Frame")
	d.Size = UDim2.fromScale(1, 1)
	d.BackgroundColor3 = Color3.fromRGB(5, 10, 30)
	d.BackgroundTransparency = 0.35
	d.BorderSizePixel = 0
	d.Active = true -- 뒤 경기장으로 클릭이 새지 않게
	d.Parent = parent
end

-- ---------- 공통 ----------

function Ui.init()
	local player = Players.LocalPlayer
	gui = Instance.new("ScreenGui")
	gui.Name = "PiggySmashUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	scaler = Instance.new("UIScale")
	scaler.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")

	-- 세로 600px 기준으로 키우거나 줄인다(가로 폰, 태블릿, PC 모두)
	local camera = workspace.CurrentCamera
	local function rescale()
		local vp = camera.ViewportSize
		scaler.Scale = math.clamp(math.min(vp.Y / 600, vp.X / 560), 0.55, 1.6)
	end
	rescale()
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
end

function Ui.hide(name: string)
	local f = screens[name]
	if f then
		f:Destroy()
		screens[name] = nil
	end
end

function Ui.hideAll()
	for name in screens do
		Ui.hide(name)
	end
end

-- ---------- 시작 화면 ----------

function Ui.showTitle(onStart: () -> ())
	local s = screen("Title")
	dim(s)
	local box = Instance.new("Frame")
	box.BackgroundTransparency = 1
	box.Size = UDim2.fromOffset(460, 360)
	center(box)
	box.Parent = s
	column(box, 14)
	label(box, "🐷🔨", 64).LayoutOrder = 1
	local title = label(box, "저금통 부수기", 56, C.gold)
	title.LayoutOrder = 2
	label(box, "저금통을 내리쳐 동전을 모으고 망치를 강화하자!", 18).LayoutOrder = 3
	local b = button(box, "시작", C.pink, UDim2.fromOffset(220, 64), onStart)
	b.TextSize = 32
	b.LayoutOrder = 4
end

-- ---------- 플레이 HUD ----------

export type Hud = {
	update: (state: { stage: number, timeLeft: number, coins: number, remaining: number, total: number, broken: number }) -> (),
	coinScreenPos: () -> Vector2,
	bumpCoin: () -> (),
	setMuted: (boolean) -> (),
}

function Ui.showHud(onMute: () -> ()): Hud
	local s = screen("Hud")
	local bar = Instance.new("Frame")
	bar.BackgroundTransparency = 1
	bar.AnchorPoint = Vector2.new(0.5, 0)
	bar.Position = UDim2.new(0.5, 0, 0, 6)
	bar.Size = UDim2.fromOffset(500, 96)
	bar.Parent = s

	local widths = { 150, 130, 200 }
	local xs = { 0, 160, 300 }
	local boxes = {}
	for i = 1, 3 do
		local b = panel(bar, UDim2.fromOffset(widths[i], 42))
		b.Position = UDim2.fromOffset(xs[i], 0)
		boxes[i] = b
	end
	local stageL = label(boxes[1], "", 22)
	stageL.Size = UDim2.fromScale(1, 1)
	local timeL = label(boxes[2], "", 24)
	timeL.Size = UDim2.fromScale(1, 1)

	local coinIcon = Instance.new("Frame")
	coinIcon.Size = UDim2.fromOffset(26, 26)
	coinIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	coinIcon.Position = UDim2.new(0, 24, 0.5, 0)
	coinIcon.BackgroundColor3 = C.coin
	corner(coinIcon, 13)
	stroke(coinIcon, 2.5)
	local coinScale = Instance.new("UIScale")
	coinScale.Parent = coinIcon
	coinIcon.Parent = boxes[3]
	local coinL = label(boxes[3], "", 24, C.gold)
	coinL.Size = UDim2.new(1, -44, 1, 0)
	coinL.Position = UDim2.fromOffset(40, 0)

	-- 진행 바와 남은 수
	local track = panel(bar, UDim2.fromOffset(440, 14))
	track.Position = UDim2.fromOffset(0, 50)
	corner(track, 7)
	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = C.pink
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	corner(fill, 7)
	fill.Parent = track
	local remainL = label(bar, "", 16)
	remainL.Position = UDim2.fromOffset(0, 68)
	remainL.Size = UDim2.fromOffset(440, 22)

	local mute = Instance.new("TextButton")
	mute.Size = UDim2.fromOffset(48, 40)
	mute.Position = UDim2.fromOffset(452, 48)
	mute.BackgroundColor3 = C.panel
	mute.Font = FONT
	mute.TextSize = 24
	mute.Text = ""
	corner(mute, 10)
	stroke(mute, 3)
	mute.Parent = bar
	mute.Activated:Connect(onMute)

	local bumping: (() -> ())? = nil
	return {
		update = function(st)
			stageL.Text = `STAGE {st.stage}`
			timeL.Text = `⏱ {math.ceil(st.timeLeft)}`
			timeL.TextColor3 = if st.timeLeft <= 5 then C.orange else C.white
			coinL.Text = Format.number(st.coins)
			remainL.Text = `남은 저금통 {st.remaining} / {st.total}`
			fill.Size = UDim2.fromScale(if st.total > 0 then st.broken / st.total else 0, 1)
		end,
		coinScreenPos = function()
			return coinIcon.AbsolutePosition + coinIcon.AbsoluteSize / 2
		end,
		bumpCoin = function()
			if bumping then
				bumping()
			end
			bumping = Anim.run(0.15, function(t)
				coinScale.Scale = 1 + 0.35 * (1 - t)
			end)
		end,
		setMuted = function(m)
			mute.Text = if m then "🔇" else "🔊"
		end,
	}
end

-- ---------- 결과 화면 ----------

export type ResultData = {
	stage: number,
	cleared: boolean,
	coinsEarned: number,
	goldBroken: number,
	bestCombo: number,
	remaining: number,
}

function Ui.showResult(r: ResultData, onUpgrade: () -> (), onNext: () -> ())
	local s = screen("Result")
	dim(s)
	local p = panel(s, UDim2.fromOffset(420, 430))
	center(p)
	column(p, 10)
	label(p, `STAGE {r.stage}`, 22).LayoutOrder = 1
	label(p, if r.cleared then "클리어!" else "실패...", 52, if r.cleared then C.gold else C.orange).LayoutOrder = 2
	if not r.cleared then
		label(p, `남은 저금통 {r.remaining}개`, 18).LayoutOrder = 3
	end
	local rows = {
		{ "얻은 동전", `+{Format.number(r.coinsEarned)}`, C.gold },
		{ "깬 금 저금통", tostring(r.goldBroken), C.white },
		{ "최고 콤보", tostring(r.bestCombo), C.white },
	}
	for i, row in rows do
		local f = Instance.new("Frame")
		f.BackgroundTransparency = 1
		f.Size = UDim2.fromOffset(320, 32)
		f.LayoutOrder = 3 + i
		f.Parent = p
		local a = label(f, row[1], 22)
		a.TextXAlignment = Enum.TextXAlignment.Left
		a.Size = UDim2.fromScale(1, 1)
		local b = label(f, row[2], 24, row[3])
		b.TextXAlignment = Enum.TextXAlignment.Right
		b.Size = UDim2.fromScale(1, 1)
	end
	local up = button(p, "강화하러 가기", Color3.fromRGB(41, 182, 246), UDim2.fromOffset(300, 54), onUpgrade)
	up.LayoutOrder = 10
	local nextColor = if r.cleared then C.pink else Color3.fromRGB(255, 152, 0)
	local nx = button(p, if r.cleared then "다음 스테이지" else "다시 도전", nextColor, UDim2.fromOffset(300, 54), onNext)
	nx.LayoutOrder = 11
	setEnabled(up, false, Color3.fromRGB(41, 182, 246))
	setEnabled(nx, false, nextColor)
	task.delay(BUTTON_LOCK, function()
		setEnabled(up, true, Color3.fromRGB(41, 182, 246))
		setEnabled(nx, true, nextColor)
	end)
end

-- ---------- 강화 화면 ----------

-- onBuy 는 서버에 물어보고 새 저장 데이터를 돌려준다(그동안 버튼은 잠긴다)
function Ui.showUpgrade(save: any, onBuy: (string) -> any, onStart: () -> ())
	local s = screen("Upgrade")
	dim(s)
	local p = panel(s, UDim2.fromOffset(520, 560))
	center(p)
	column(p, 8)

	local head = Instance.new("Frame")
	head.BackgroundTransparency = 1
	head.Size = UDim2.fromOffset(480, 44)
	head.LayoutOrder = 0
	head.Parent = p
	local title = label(head, "망치 강화", 32)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Size = UDim2.fromScale(1, 1)
	local coinsL = label(head, "", 28, C.gold)
	coinsL.TextXAlignment = Enum.TextXAlignment.Right
	coinsL.Size = UDim2.fromScale(1, 1)

	local rows = {}
	local busy = false
	local current = save
	local render: () -> ()

	for i, id in Upgrades.SKILL_ORDER do
		local info = Upgrades.SKILL_INFO[id]
		local row = panel(p, UDim2.fromOffset(480, 72), Color3.fromRGB(26, 44, 92))
		row.LayoutOrder = i
		local name = label(row, `{info.icon} {info.label}`, 22)
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Position = UDim2.fromOffset(14, 6)
		name.Size = UDim2.fromOffset(250, 28)
		local effect = label(row, "", 17, Color3.fromRGB(179, 229, 252))
		effect.TextXAlignment = Enum.TextXAlignment.Left
		effect.Position = UDim2.fromOffset(14, 38)
		effect.Size = UDim2.fromOffset(280, 24)
		local buy: TextButton
		buy = button(row, "", C.pink, UDim2.fromOffset(150, 52), function()
			if busy then
				return
			end
			busy = true
			local nextSave = onBuy(id)
			busy = false
			if nextSave then
				current = nextSave
			end
			render()
		end)
		buy.AnchorPoint = Vector2.new(1, 0.5)
		buy.Position = UDim2.new(1, -10, 0.5, 0)
		buy.TextSize = 20
		rows[id] = { name = name, effect = effect, buy = buy }
	end

	render = function()
		coinsL.Text = `🪙 {Format.number(current.coins)}`
		for _, id in Upgrades.SKILL_ORDER do
			local r = rows[id]
			local level = current.levels[id]
			local info = Upgrades.SKILL_INFO[id]
			local d = Upgrades.describeUpgrade(id, level)
			local cost = Upgrades.nextCost(id, level)
			r.name.Text = if level > 0 then `{info.icon} {info.label}  Lv.{level}` else `{info.icon} {info.label}`
			r.effect.Text = `{d.now} → {d.next}`
			r.buy.Text = if level > 0 then `🪙 {Format.number(cost)}` else `해금 🪙 {Format.number(cost)}`
			local color = if level > 0 then C.pink else Color3.fromRGB(171, 71, 188)
			setEnabled(r.buy, Upgrades.canBuy(current.coins, id, level), color)
		end
	end
	render()

	local start = button(p, `STAGE {save.stage} 시작`, Color3.fromRGB(67, 160, 71), UDim2.fromOffset(300, 56), onStart)
	start.LayoutOrder = 10
	start.TextSize = 28
end

return Ui
