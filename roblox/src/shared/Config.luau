--!strict
-- 로블록스판에서만 쓰는 값: 월드 크기, 색, 효과음. 게임 수치는 Balance/Upgrades.

local Config = {}

-- 웹판 수치(픽셀)를 스터드로. 캐릭터(키 약 5스터드)에 맞춰 저금통과 망치 판정이 넉넉하도록.
Config.STUDS_PER_PX = 0.15

-- 캐릭터와 저금통이 돌아다니는 마당. 가로(X) × 세로(Z) 스터드. ORIGIN은 바닥 윗면 가운데.
Config.ARENA_ORIGIN = Vector3.new(0, 0, 0)
Config.ARENA_SIZE = Vector2.new(96, 68)
Config.WALL_HEIGHT = 8

-- 저금통 그림 크기 = 판정 반지름 × 이 값(판정을 그림보다 조금 넉넉하게)
Config.PIG_ART_RATIO = 0.75

-- 저금통 반지름(픽셀). 웹판 layout.ts 와 같다.
Config.PIG_RADIUS = 21
Config.PIG_RADIUS_GOLD = 25

Config.COLORS = {
	sky = Color3.fromRGB(41, 121, 255),
	floor = Color3.fromRGB(100, 181, 246),
	floorLine = Color3.fromRGB(66, 165, 245),
	wall = Color3.fromRGB(13, 27, 62),
	pig = Color3.fromRGB(255, 143, 177),
	pigDark = Color3.fromRGB(240, 98, 146),
	gold = Color3.fromRGB(255, 202, 40),
	goldDark = Color3.fromRGB(255, 160, 0),
	coin = Color3.fromRGB(255, 202, 40),
	hammerHead = Color3.fromRGB(120, 144, 156),
	hammerHandle = Color3.fromRGB(141, 85, 36),
	burst = Color3.fromRGB(255, 235, 59),
	grass = Color3.fromRGB(124, 179, 66),
	bolt = Color3.fromRGB(128, 222, 234),
	panel = Color3.fromRGB(13, 27, 62),
	pink = Color3.fromRGB(255, 79, 139),
	green = Color3.fromRGB(118, 255, 3),
	orange = Color3.fromRGB(255, 112, 67),
	white = Color3.new(1, 1, 1),
	black = Color3.new(0, 0, 0),
}

-- 효과음. 로블록스에 기본으로 들어 있는 소리를 쓴다.
-- 크리에이터 스토어에서 마음에 드는 소리를 찾으면 "rbxassetid://숫자" 로 바꾸면 된다.
Config.SOUNDS = {
	swing = { id = "rbxasset://sounds/swordlunge.wav", volume = 0.35, speed = 1.4 },
	hit = { id = "rbxasset://sounds/swordslash.wav", volume = 0.5, speed = 1.8 },
	crit = { id = "rbxasset://sounds/swordslash.wav", volume = 0.8, speed = 1.1 },
	["break"] = { id = "rbxasset://sounds/glassbreak.wav", volume = 0.6, speed = 1 },
	coin = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.25, speed = 1.6 },
	zap = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.4, speed = 0.7 },
	click = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.3, speed = 1.2 },
}

return Config
