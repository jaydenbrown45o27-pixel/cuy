-- =========================================================
-- Lyzn Hub — Crystal-themed UI + Luarmor key auth
-- =========================================================
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Lucide icons
local Lucide
pcall(function()
	Lucide = loadstring(game:HttpGet("https://github.com/latte-soft/lucide-roblox/releases/latest/download/lucide-roblox.luau"))()
end)
local function lucideProps(name)
	if not Lucide then return nil end
	local ok, asset = pcall(function() return Lucide.GetAsset(name) end)
	if not ok or not asset then return nil end
	return { Image = asset.Url or asset.Id, ImageRectOffset = asset.ImageRectPosition or asset.ImageRectOffset, ImageRectSize = asset.ImageRectSize }
end

local Cfg = {
	WinSize = Vector2.new(800, 580),
	TopH = 56,
	SidebarW = 190,
	ProfileH = 84,
	CrystalLogo = "rbxassetid://78492884826986",
	ScriptId = "cc39c2c657dcac097bac251bc38de8b2",

	-- Colors sampled from the screenshot
	Bg = Color3.fromRGB(15, 15, 20),           -- deep black with slight blue tint
	Panel = Color3.fromRGB(22, 22, 30),        -- row / card
	PanelHi = Color3.fromRGB(30, 30, 40),
	Row = Color3.fromRGB(26, 26, 34),
	TabBar = Color3.fromRGB(18, 18, 24),
	Stroke = Color3.fromRGB(40, 40, 52),
	StrokeSoft = Color3.fromRGB(32, 32, 44),

	Accent = Color3.fromRGB(255, 255, 255),    -- toggles/sliders fill WHITE
	AccentDim = Color3.fromRGB(200, 200, 210),
	Text = Color3.fromRGB(245, 245, 250),
	TextDim = Color3.fromRGB(160, 160, 175),
	TextFaint = Color3.fromRGB(105, 105, 120),

	FontTitle = Enum.Font.Bangers,
	FontBold = Enum.Font.Bangers,
	FontMed = Enum.Font.Bangers,
	FontReg = Enum.Font.Bangers,

	Tween = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Fade = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	MinScale = 0.4,
	ScaleBase = Vector2.new(880, 660),
	ToggleKey = Enum.KeyCode.LeftControl,
}

local function New(cls, props, kids)
	local o = Instance.new(cls)
	for k, v in pairs(props or {}) do if k ~= "Parent" then o[k] = v end end
	if kids then for _, c in ipairs(kids) do c.Parent = o end end
	if props and props.Parent then o.Parent = props.Parent end
	return o
end
local function corner(p, r) return New("UICorner", { CornerRadius = r or UDim.new(0, 10), Parent = p }) end
local function stroke(p, c, t) return New("UIStroke", { Color = c or Cfg.Stroke, Thickness = t or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = p }) end
local function padding(p, t, b, l, r) return New("UIPadding", { PaddingTop = UDim.new(0, t or 0), PaddingBottom = UDim.new(0, b or t or 0), PaddingLeft = UDim.new(0, l or t or 0), PaddingRight = UDim.new(0, r or t or 0), Parent = p }) end

-- =========================================================
-- Luarmor key auth
-- =========================================================
local function getExecutorName()
	local ok, n = pcall(function() return identifyexecutor() end)
	if ok and typeof(n) == "string" and n ~= "" then return n end
	ok, n = pcall(function() return getexecutorname() end)
	if ok and typeof(n) == "string" and n ~= "" then return n end
	return "Unknown"
end
local KeyCheckUrl = "https://sdkapi-public.luarmor.net/library.lua"
local function fetchSecondsLeft()
	if typeof(LuarmorExpiry) == "number" then
		if LuarmorExpiry <= 0 or LuarmorExpiry < 1000000000 then return math.huge end
		return LuarmorExpiry - os.time()
	end
	local key = (typeof(script_key) == "string" and script_key ~= "" and script_key)
	         or (typeof(LuarmorKey)  == "string" and LuarmorKey  ~= "" and LuarmorKey)
	         or nil
	if not key then return nil end
	local ld, api = pcall(function() return loadstring(game:HttpGet(KeyCheckUrl))() end)
	if not ld or typeof(api) ~= "table" then return nil end
	api.script_id = Cfg.ScriptId
	local ok, st = pcall(api.check_key, key)
	if not ok or typeof(st) ~= "table" or st.code ~= "KEY_VALID" then return nil end
	local e = tonumber(st.data and st.data.auth_expire)
	if not e then return nil end
	if e <= 0 then return math.huge end
	return e - os.time()
end
local function formatSecondsLeft(s)
	if typeof(s) ~= "number" or s ~= s then return "—" end
	if s == math.huge then return "Lifetime" end
	if s <= 0 then return "Expired" end
	local d = math.floor(s/86400); local h = math.floor((s%86400)/3600); local m = math.floor((s%3600)/60)
	if d > 0 then return string.format("%dd %dh left", d, h) end
	if h > 0 then return string.format("%dh %dm left", h, m) end
	return string.format("%dm left", math.max(m, 1))
end

local function protectGui(gui)
	local ok = pcall(function()
		if syn and syn.protect_gui then syn.protect_gui(gui); gui.Parent = game:GetService("CoreGui")
		elseif gethui then gui.Parent = gethui()
		else gui.Parent = game:GetService("CoreGui") end
	end)
	if not ok then gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end
end

-- =========================================================
-- Library
-- =========================================================
local Library = {}; Library.__index = Library

function Library:CreateWindow(opts)
	opts = opts or {}
	local screen = New("ScreenGui", { Name = "\0Crystal\0", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true, DisplayOrder = 999 })
	protectGui(screen)

	local root = New("CanvasGroup", {
		Parent = screen, Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(Cfg.WinSize.X, Cfg.WinSize.Y),
		BackgroundColor3 = Cfg.Bg, GroupTransparency = 1, ClipsDescendants = true,
	})
	corner(root, UDim.new(0, 14)); stroke(root, Cfg.StrokeSoft, 1)

	-- =====================================================
	-- Background: subtle rotated crystal shapes + gradient
	-- =====================================================
	local bg = New("Frame", { Parent = root, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Cfg.Bg, BorderSizePixel = 0, ZIndex = 0 })
	-- Vertical gradient
	New("UIGradient", {
		Parent = bg, Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 22, 30)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 14)),
		}),
	})

	-- Rotated crystal shapes (diamonds) scattered behind everything
	local shapes = {
		{ x = 0.85, y = 0.25, size = 220, rot = 25, alpha = 0.94 },
		{ x = 0.15, y = 0.85, size = 260, rot = -20, alpha = 0.95 },
		{ x = 0.9,  y = 0.75, size = 180, rot = 35, alpha = 0.94 },
		{ x = 0.05, y = 0.15, size = 160, rot = 40, alpha = 0.96 },
		{ x = 0.55, y = 0.55, size = 200, rot = -15, alpha = 0.96 },
	}
	for _, s in ipairs(shapes) do
		local d = New("Frame", {
			Parent = bg, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(s.x, s.y), Size = UDim2.fromOffset(s.size, s.size),
			Rotation = s.rot, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = s.alpha, BorderSizePixel = 0, ZIndex = 0,
		})
		corner(d, UDim.new(0, 24))
		stroke(d, Color3.fromRGB(255, 255, 255), 1).Transparency = 0.9
	end

	-- Faint diagonal line pattern top-right
	for i = 1, 8 do
		local line = New("Frame", {
			Parent = bg, AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -20 * i, 0, -30), Size = UDim2.new(0, 1, 0, 90),
			Rotation = 30, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.95, BorderSizePixel = 0, ZIndex = 0,
		})
	end

	local uiScale = New("UIScale", { Parent = root, Scale = 1 })
	local cam = workspace.CurrentCamera
	local function updScale()
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local raw = math.min(vp.X / Cfg.ScaleBase.X, vp.Y / Cfg.ScaleBase.Y)
		-- Mobile: keep floor higher so text stays readable
		local isMobile = vp.X < 900 or vp.Y < 600
		local floor = isMobile and 0.45 or Cfg.MinScale
		uiScale.Scale = math.clamp(raw, floor, 1)
	end
	updScale(); if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(updScale) end

	-- ================================================
	-- TOPBAR
	-- ================================================
	local topbar = New("Frame", { Parent = root, Size = UDim2.new(1, 0, 0, Cfg.TopH), BackgroundTransparency = 1 })

	-- Logo — crystal image, no background, bigger
	local mark = New("CanvasGroup", {
		Parent = topbar, AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.5, 0), Size = UDim2.fromOffset(46, 46),
		BackgroundTransparency = 1, ClipsDescendants = true,
	})
	corner(mark, UDim.new(0, 10))
	New("ImageLabel", {
		Parent = mark, Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1, Image = Cfg.CrystalLogo,
		ScaleType = Enum.ScaleType.Stretch,
	})

	-- Centered title with subtle side dashes
	local titleWrap = New("Frame", {
		Parent = topbar, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 340, 0, 30),
		BackgroundTransparency = 1,
	})
	New("Frame", { Parent = titleWrap, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(24, 1), BackgroundColor3 = Cfg.Stroke, BorderSizePixel = 0 })
	New("Frame", { Parent = titleWrap, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(24, 1), BackgroundColor3 = Cfg.Stroke, BorderSizePixel = 0 })
	New("TextLabel", {
		Parent = titleWrap, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -60, 1, 0),
		BackgroundTransparency = 1, Font = Cfg.FontTitle,
		Text = string.upper(opts.Title or "Lyzn Hub"),
		TextColor3 = Cfg.Text, TextSize = 24,
	})

	-- Minimize button top-right
	local minBtn = New("TextButton", {
		Parent = topbar, AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(30, 30),
		BackgroundColor3 = Cfg.Panel, BorderSizePixel = 0,
		AutoButtonColor = false, Text = "",
	})
	corner(minBtn, UDim.new(0, 7)); stroke(minBtn, Cfg.Stroke, 1)
	New("Frame", {
		Parent = minBtn, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromOffset(12, 2),
		BackgroundColor3 = Cfg.TextDim, BorderSizePixel = 0,
	})
	minBtn.MouseEnter:Connect(function() TweenService:Create(minBtn, Cfg.Tween, { BackgroundColor3 = Cfg.PanelHi }):Play() end)
	minBtn.MouseLeave:Connect(function() TweenService:Create(minBtn, Cfg.Tween, { BackgroundColor3 = Cfg.Panel }):Play() end)

	-- Bottom border with gradient fade
	local topDiv = New("Frame", {
		Parent = topbar, Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Cfg.Text, BorderSizePixel = 0,
	})
	New("UIGradient", { Parent = topDiv, Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.85),
		NumberSequenceKeypoint.new(1, 1),
	})})

	-- ================================================
	-- SIDEBAR (tab list + profile card at bottom) — same nebula theme as the profile
	-- ================================================
	local sidebar = New("Frame", {
		Parent = root, Position = UDim2.new(0, 0, 0, Cfg.TopH),
		Size = UDim2.new(0, Cfg.SidebarW, 1, -Cfg.TopH),
		BackgroundColor3 = Color3.fromRGB(14, 12, 22), BorderSizePixel = 0,
		ClipsDescendants = true,
	})
	-- Nebula gradient (matches profile card)
	New("UIGradient", {
		Parent = sidebar, Rotation = 135,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 20, 40)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(24, 12, 26)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 8, 18)),
		}),
	})
	-- Star layer behind everything (drifting)
	do
		local rng = Random.new()
		for i = 1, 40 do
			local sz = rng:NextNumber(0.8, 1.8)
			local base = rng:NextNumber(0.4, 0.8)
			local x0 = rng:NextNumber(0.02, 0.98)
			local y0 = rng:NextNumber(0.02, 0.98)
			local s = New("Frame", {
				Parent = sidebar, AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(x0, y0), Size = UDim2.fromOffset(sz, sz),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = base, BorderSizePixel = 0, ZIndex = 0,
			})
			corner(s, UDim.new(1, 0))
			TweenService:Create(s, TweenInfo.new(rng:NextNumber(1.5, 3.2), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, rng:NextNumber(0, 2)), { BackgroundTransparency = math.min(1, base + 0.35) }):Play()
			local dy = rng:NextNumber(-3, 3) / 100
			TweenService:Create(s, TweenInfo.new(rng:NextNumber(6, 12), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, rng:NextNumber(0, 3)), { Position = UDim2.fromScale(x0, y0 + dy) }):Play()
		end
	end
	-- Right border
	New("Frame", { Parent = sidebar, Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = Color3.fromRGB(80, 30, 50), BorderSizePixel = 0, ZIndex = 5 })
	-- Top glow band (accent-tinted, matches profile card feel)
	local topGlow = New("Frame", {
		Parent = sidebar, AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(1.4, 0, 0, 50),
		BackgroundColor3 = Color3.fromRGB(180, 40, 80), BorderSizePixel = 0, ZIndex = 0,
	})
	New("UIGradient", { Parent = topGlow, Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.75), NumberSequenceKeypoint.new(1, 1) }) })

	local tabList = New("ScrollingFrame", {
		Parent = sidebar, Size = UDim2.new(1, 0, 1, -(Cfg.ProfileH + 16)),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 0, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 2,
	})
	padding(tabList, 10, 10, 10, 10)
	New("UIListLayout", { Parent = tabList, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder })

	-- Profile card (bottom of sidebar) — nebula bg, avatar, name, online status
	do
		local LP = Players.LocalPlayer
		local uid = LP and LP.UserId or 1
		local un = LP and LP.Name or "Player"
		local disp = (LP and LP.DisplayName ~= "" and LP.DisplayName) or un

		local card = New("TextButton", {
			Parent = sidebar, AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 8, 1, -8), Size = UDim2.new(1, -16, 0, Cfg.ProfileH),
			BackgroundColor3 = Color3.fromRGB(14, 12, 22), AutoButtonColor = false, Text = "",
			BorderSizePixel = 0, ClipsDescendants = true,
		})
		corner(card, UDim.new(0, 12)); stroke(card, Color3.fromRGB(80, 30, 50), 1)

		-- Nebula gradient
		New("UIGradient", {
			Parent = card, Rotation = 135,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 25, 45)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(30, 15, 30)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 10, 22)),
			}),
		})

		-- Twinkling stars behind
		do
			local rng = Random.new()
			for i = 1, 14 do
				local sz = rng:NextNumber(1, 1.8)
				local base = rng:NextNumber(0.35, 0.7)
				local s = New("Frame", {
					Parent = card, AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(rng:NextNumber(0.05, 0.95), rng:NextNumber(0.05, 0.95)),
					Size = UDim2.fromOffset(sz, sz), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = base, BorderSizePixel = 0,
				})
				corner(s, UDim.new(1, 0))
				TweenService:Create(s, TweenInfo.new(rng:NextNumber(1.4, 3), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, rng:NextNumber(0, 2)), { BackgroundTransparency = math.min(1, base + 0.35) }):Play()
			end
		end

		-- Avatar with double-ring
		local avatarGlow = New("Frame", {
			Parent = card, AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(54, 54),
			BackgroundColor3 = Cfg.Accent, BackgroundTransparency = 0.85, BorderSizePixel = 0,
		})
		corner(avatarGlow, UDim.new(1, 0))
		local avatar = New("ImageLabel", {
			Parent = card, AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 14, 0.5, 0), Size = UDim2.fromOffset(46, 46),
			BackgroundColor3 = Cfg.Bg, BorderSizePixel = 0, Image = "",
		})
		corner(avatar, UDim.new(1, 0)); stroke(avatar, Cfg.Text, 1.5)
		task.spawn(function()
			local ok, ct = pcall(function() return Players:GetUserThumbnailAsync(uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48) end)
			avatar.Image = ok and ct or ("rbxthumb://type=AvatarHeadShot&id=" .. uid .. "&w=48&h=48")
		end)

		-- Name
		New("TextLabel", {
			Parent = card, Position = UDim2.fromOffset(72, 12),
			Size = UDim2.new(1, -80, 0, 18),
			BackgroundTransparency = 1, Font = Cfg.FontBold, Text = string.upper(disp),
			TextColor3 = Cfg.Text, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		-- Executor
		New("TextLabel", {
			Parent = card, Position = UDim2.fromOffset(72, 32),
			Size = UDim2.new(1, -80, 0, 14),
			BackgroundTransparency = 1, Font = Cfg.FontMed, Text = getExecutorName(),
			TextColor3 = Cfg.TextDim, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		-- Expiry row: green dot + countdown
		local statusWrap = New("Frame", { Parent = card, Position = UDim2.fromOffset(72, 52), Size = UDim2.new(1, -80, 0, 14), BackgroundTransparency = 1 })
		local dot = New("Frame", { Parent = statusWrap, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(7, 7), BackgroundColor3 = Color3.fromRGB(80, 220, 130), BorderSizePixel = 0 })
		corner(dot, UDim.new(1, 0))
		TweenService:Create(dot, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { BackgroundTransparency = 0.5 }):Play()
		local expiryLbl = New("TextLabel", {
			Parent = statusWrap, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -12, 1, 0),
			BackgroundTransparency = 1, Font = Cfg.FontMed, Text = "Checking key…",
			TextColor3 = Color3.fromRGB(120, 220, 160), TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
		})
		task.spawn(function()
			local sl = fetchSecondsLeft()
			local mA = os.clock()
			expiryLbl.Text = formatSecondsLeft(sl)
			if typeof(sl) ~= "number" or sl == math.huge then return end
			while expiryLbl.Parent do
				local r = sl - (os.clock() - mA)
				expiryLbl.Text = formatSecondsLeft(r)
				if r <= 0 then expiryLbl.TextColor3 = Cfg.TextFaint; break end
				task.wait(r > 3600 and 30 or 1)
			end
		end)

		-- Click → copy profile link
		card.MouseButton1Click:Connect(function()
			pcall(function()
				local link = "https://www.roblox.com/users/" .. uid .. "/profile"
				if setclipboard then setclipboard(link) end
				local StarterGui = game:GetService("StarterGui")
				StarterGui:SetCore("SendNotification", { Title = "Profile copied", Text = link, Duration = 4 })
			end)
		end)
	end

	-- ================================================
	-- CONTENT (right of sidebar)
	-- ================================================
	local content = New("Frame", {
		Parent = root, Position = UDim2.new(0, Cfg.SidebarW, 0, Cfg.TopH),
		Size = UDim2.new(1, -Cfg.SidebarW, 1, -Cfg.TopH),
		BackgroundTransparency = 1,
	})
	padding(content, 14, 14, 14, 14)

	-- Smooth drag
	local function bindDrag(frame, handle)
		local dragging, dragStart, startPos, target = false
		local rc, ec
		local function stop()
			if rc then rc:Disconnect(); rc = nil end
			if ec then ec:Disconnect(); ec = nil end
			if dragging then dragging = false; if target then frame.Position = target end end
		end
		handle.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging = true; dragStart = i.Position; startPos = frame.Position; target = startPos
				rc = RunService.RenderStepped:Connect(function()
					local c = frame.Position
					frame.Position = UDim2.new(target.X.Scale, c.X.Offset + (target.X.Offset - c.X.Offset) * 0.3, target.Y.Scale, c.Y.Offset + (target.Y.Offset - c.Y.Offset) * 0.3)
				end)
				ec = i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then stop() end end)
			end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				local d = i.Position - dragStart
				target = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end)
		UserInputService.InputEnded:Connect(function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then stop() end
		end)
	end
	bindDrag(root, topbar)

	-- Minimize-to-crystal pill (bottom-left, draggable, tap opens)
	local minPill = New("ImageButton", {
		Parent = screen, Position = UDim2.fromOffset(24, 200),
		Size = UDim2.fromOffset(56, 56),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		AutoButtonColor = false, Image = Cfg.CrystalLogo,
		ScaleType = Enum.ScaleType.Stretch,
		Selectable = false, Modal = false, Active = true,
		Visible = false, ZIndex = 200,
	})
	corner(minPill, UDim.new(0, 12))

	local shown = true
	local function setShown(s)
		shown = s
		if s then
			root.Visible = true; minPill.Visible = false
			TweenService:Create(root, Cfg.Fade, { GroupTransparency = 0 }):Play()
		else
			local f = TweenService:Create(root, Cfg.Fade, { GroupTransparency = 1 }); f:Play()
			f.Completed:Once(function() if not shown then root.Visible = false; minPill.Visible = true end end)
		end
	end
	minBtn.MouseButton1Click:Connect(function() setShown(false) end)

	-- Drag on minimize pill + tap to open
	do
		local dragging, dragStart, startPos, target, moved
		local rc, ec
		local function stop()
			if rc then rc:Disconnect(); rc = nil end
			if ec then ec:Disconnect(); ec = nil end
			if dragging then dragging = false; if target then minPill.Position = target end end
		end
		minPill.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging = true; moved = false; dragStart = i.Position; startPos = minPill.Position; target = startPos
				rc = RunService.RenderStepped:Connect(function()
					local c = minPill.Position
					minPill.Position = UDim2.new(target.X.Scale, c.X.Offset + (target.X.Offset - c.X.Offset) * 0.3, target.Y.Scale, c.Y.Offset + (target.Y.Offset - c.Y.Offset) * 0.3)
				end)
				ec = i.Changed:Connect(function()
					if i.UserInputState == Enum.UserInputState.End then
						if not moved then setShown(true) end
						stop()
					end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				local d = i.Position - dragStart
				if math.abs(d.X) + math.abs(d.Y) > 5 then moved = true end
				target = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end)
		UserInputService.InputEnded:Connect(function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
				if not moved then setShown(true) end
				stop()
			end
		end)
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Cfg.ToggleKey then setShown(not shown) end
	end)
	task.spawn(function() task.wait(0.1); TweenService:Create(root, Cfg.Fade, { GroupTransparency = 0 }):Play() end)

	local w = setmetatable({ Screen = screen, Root = root, TabList = tabList, Content = content, Tabs = {}, Current = nil }, { __index = Library.Window })
	return w
end

-- =========================================================
-- Tabs — pill with dot indicator on the left (dot = active state)
-- =========================================================
Library.Window = {}
-- Auto-map tab names to Lucide icons
local TabIconMap = {
	main = "home", home = "home", general = "home",
	combat = "swords", fight = "swords", pvp = "swords", kill = "swords",
	player = "user", players = "users", character = "user", char = "user",
	movement = "footprints", move = "footprints", walk = "footprints",
	settings = "settings", config = "settings", options = "settings",
	visuals = "eye", visual = "eye", esp = "eye", render = "eye",
	misc = "box", other = "box", extra = "box",
	world = "globe", server = "server", game = "gamepad-2",
	teleport = "map-pin", tp = "map-pin", location = "map-pin",
	farm = "sprout", auto = "zap", automation = "zap",
	shop = "shopping-cart", store = "shopping-cart",
	inventory = "package", items = "package", inv = "package",
	stats = "bar-chart-3", info = "info",
	credits = "heart", credit = "heart", about = "info",
	throwing = "send", throw = "send",
	catching = "hand", catch = "hand",
	defense = "shield", defence = "shield", block = "shield",
	physics = "atom", magnet = "magnet", magnets = "magnet",
	pull = "move", teleport_vector = "move",
	util = "wrench", utilities = "wrench", tools = "wrench",
	script = "file-code", scripts = "file-code",
	fun = "sparkles", troll = "sparkles",
	admin = "shield-check", dev = "code", developer = "code",
}
local function guessIcon(n)
	local key = string.lower(n or "")
	key = key:gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", "")
	if TabIconMap[key] then return TabIconMap[key] end
	for word in string.gmatch(key, "[%w]+") do
		if TabIconMap[word] then return TabIconMap[word] end
	end
	return "circle"
end

function Library.Window:CreateTab(name, iconName)
	local btn = New("TextButton", {
		Name = name, Parent = self.TabList,
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundColor3 = Cfg.Panel, BackgroundTransparency = 1,
		AutoButtonColor = false, Text = "",
	})
	corner(btn, UDim.new(0, 8))

	local iconHolder = New("Frame", {
		Parent = btn, AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1,
	})
	local icon
	local resolved = iconName or guessIcon(name)
	local props = resolved and lucideProps(resolved)
	-- try guess as last resort if user-supplied name isn't a real Lucide
	if (not props or not props.Image or props.Image == "") and iconName then
		props = lucideProps(guessIcon(name))
	end
	-- final fallback to "circle"
	if not props or not props.Image or props.Image == "" then
		props = lucideProps("circle")
	end
	if props and props.Image and props.Image ~= "" then
		icon = New("ImageLabel", {
			Parent = iconHolder, Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1, ImageColor3 = Cfg.TextDim,
			Image = props.Image,
		})
		if props.ImageRectOffset then icon.ImageRectOffset = props.ImageRectOffset end
		if props.ImageRectSize then icon.ImageRectSize = props.ImageRectSize end
	else
		-- Lucide failed to load entirely — use a small dot instead of the letter tile
		icon = New("Frame", {
			Parent = iconHolder, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(6, 6),
			BackgroundColor3 = Cfg.TextDim, BorderSizePixel = 0,
		})
		corner(icon, UDim.new(1, 0))
	end

	local lbl = New("TextLabel", {
		Parent = btn, Position = UDim2.fromOffset(40, 0), Size = UDim2.new(1, -46, 1, 0),
		BackgroundTransparency = 1, Font = Cfg.FontBold, Text = string.upper(name),
		TextColor3 = Cfg.TextDim, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left,
	})

	-- Left accent bar for active tab
	local activeBar = New("Frame", {
		Parent = btn, AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, -2, 0.5, 0), Size = UDim2.fromOffset(3, 26),
		BackgroundColor3 = Cfg.Accent, BorderSizePixel = 0, Visible = false,
	})
	corner(activeBar, UDim.new(1, 0))

	local page = New("ScrollingFrame", {
		Parent = self.Content, Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 0, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false,
	})
	-- Two columns
	local left = New("Frame", { Parent = page, Size = UDim2.new(0.5, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
	local right = New("Frame", { Parent = page, Position = UDim2.new(0.5, 6, 0, 0), Size = UDim2.new(0.5, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
	New("UIListLayout", { Parent = left, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
	New("UIListLayout", { Parent = right, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })

	local tab = setmetatable({ Window = self, Btn = btn, Label = lbl, Icon = icon, ActiveBar = activeBar, Page = page, Left = left, Right = right }, { __index = Library.Tab })
	btn.MouseButton1Click:Connect(function() self:SelectTab(tab) end)
	table.insert(self.Tabs, tab)
	if not self.Current then self:SelectTab(tab) end
	return tab
end

function Library.Window:SelectTab(tab)
	for _, t in ipairs(self.Tabs) do
		local active = t == tab
		t.Page.Visible = active
		t.ActiveBar.Visible = active
		TweenService:Create(t.Btn, Cfg.Tween, { BackgroundTransparency = active and 0 or 1, BackgroundColor3 = active and Cfg.Panel or Cfg.Panel }):Play()
		TweenService:Create(t.Label, Cfg.Tween, { TextColor3 = active and Cfg.Text or Cfg.TextDim }):Play()
		if t.Icon:IsA("ImageLabel") then
			TweenService:Create(t.Icon, Cfg.Tween, { ImageColor3 = active and Cfg.Text or Cfg.TextDim }):Play()
		else
			TweenService:Create(t.Icon, Cfg.Tween, { TextColor3 = active and Cfg.Text or Cfg.TextDim }):Play()
		end
	end
	self.Current = tab
end

-- =========================================================
-- Sections (header with dot + uppercase title, then rows)
-- =========================================================
Library.Tab = {}
function Library.Tab:CreateSection(title, side)
	local col = (side == "Right") and self.Right or self.Left

	-- Outer card (groupbox)
	local card = New("Frame", {
		Parent = col, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Cfg.PanelDark or Color3.fromRGB(20, 18, 26),
		BorderSizePixel = 0,
	})
	corner(card, UDim.new(0, 12))
	stroke(card, Cfg.StrokeSoft, 1)
	padding(card, 10, 12, 12, 12)

	-- Header row
	local header = New("Frame", { Parent = card, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, LayoutOrder = -1 })
	local hDot = New("Frame", {
		Parent = header, AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.fromOffset(4, 4),
		BackgroundColor3 = Cfg.TextDim, BorderSizePixel = 0,
	})
	corner(hDot, UDim.new(1, 0))
	New("TextLabel", {
		Parent = header, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -12, 1, 0),
		BackgroundTransparency = 1, Font = Cfg.FontBold,
		Text = string.upper(title), TextColor3 = Cfg.TextDim,
		TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
	})

	-- Divider under header
	New("Frame", {
		Parent = card, Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Cfg.StrokeSoft, BorderSizePixel = 0,
		BackgroundTransparency = 0.4, LayoutOrder = 0,
	})

	-- Inner wrap that rows go into
	local wrap = New("Frame", {
		Parent = card, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		LayoutOrder = 1,
	})
	New("UIListLayout", { Parent = wrap, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })

	-- Card's own vertical stack (header, divider, wrap)
	New("UIListLayout", { Parent = card, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })

	return setmetatable({ Wrap = wrap, Card = card }, { __index = Library.Section })
end

-- =========================================================
-- Row helpers
-- =========================================================
Library.Section = {}
local function makeRow(sec, h)
	local r = New("Frame", {
		Parent = sec.Wrap, Size = UDim2.new(1, 0, 0, h or 44),
		BackgroundColor3 = Cfg.Panel, BorderSizePixel = 0,
	})
	corner(r, UDim.new(0, 10)); stroke(r, Cfg.StrokeSoft, 1)
	padding(r, 0, 0, 14, 14)
	return r
end

function Library.Section:AddToggle(o)
	local r = makeRow(self, 44)
	New("TextLabel", {
		Parent = r, Size = UDim2.new(1, -56, 1, 0), BackgroundTransparency = 1,
		Font = Cfg.FontBold, Text = string.upper(o.Text or "Toggle"),
		TextColor3 = Cfg.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local state = o.Default == true

	-- Track — same nebula theme as profile card
	local track = New("TextButton", {
		Parent = r, AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(42, 22),
		BackgroundColor3 = Color3.fromRGB(14, 12, 22), BorderSizePixel = 0,
		AutoButtonColor = false, Text = "", ClipsDescendants = true,
	})
	corner(track, UDim.new(1, 0))
	local trackStroke = stroke(track, Color3.fromRGB(80, 30, 50), 1)

	-- Nebula gradient fill (only visible when ON)
	local trackGrad = New("UIGradient", {
		Parent = track, Rotation = 135,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 25, 45)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(30, 15, 30)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 10, 22)),
		}),
	})

	local knob = New("Frame", {
		Parent = track, AnchorPoint = Vector2.new(0, 0.5),
		Position = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = state and Color3.fromRGB(255, 255, 255) or Cfg.TextDim,
		BorderSizePixel = 0,
	})
	corner(knob, UDim.new(1, 0))

	local ob = { State = state }
	local function render()
		local on = ob.State
		TweenService:Create(track, Cfg.Tween, {
			BackgroundColor3 = on and Color3.fromRGB(140, 30, 50) or Color3.fromRGB(14, 12, 22),
		}):Play()
		TweenService:Create(trackStroke, Cfg.Tween, {
			Color = on and Color3.fromRGB(200, 60, 90) or Color3.fromRGB(80, 30, 50),
		}):Play()
		TweenService:Create(knob, Cfg.Tween, {
			Position = on and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
			BackgroundColor3 = on and Color3.fromRGB(255, 255, 255) or Cfg.TextDim,
		}):Play()
	end
	render()

	function ob:Set(v) ob.State = v and true or false; render(); if o.Callback then task.spawn(o.Callback, ob.State) end end
	track.MouseButton1Click:Connect(function() ob:Set(not ob.State) end)
	if state and o.Callback then task.spawn(o.Callback, true) end
	return ob
end

function Library.Section:AddSlider(o)
	local min, max = o.Min or 0, o.Max or 100
	local dec = o.Decimals or 1
	local val = math.clamp(o.Default or min, min, max)
	local function round(n) local m = 10^dec; return math.floor(n*m+0.5)/m end

	local r = makeRow(self, 52)
	local topRow = New("Frame", { Parent = r, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1 })
	New("TextLabel", {
		Parent = topRow, Size = UDim2.new(1, -64, 1, 0), BackgroundTransparency = 1,
		Font = Cfg.FontBold, Text = string.upper(o.Text or "Slider"),
		TextColor3 = Cfg.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local valLbl = New("TextLabel", {
		Parent = topRow, AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(60, 20),
		BackgroundTransparency = 1, Font = Cfg.FontBold,
		Text = tostring(round(val)), TextColor3 = Cfg.Text,
		TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right,
	})
	local track = New("Frame", {
		Parent = r, AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, -6), Size = UDim2.new(1, 0, 0, 3),
		BackgroundColor3 = Cfg.Bg, BorderSizePixel = 0,
	})
	corner(track, UDim.new(1, 0))
	local fill = New("Frame", { Parent = track, Size = UDim2.fromScale((val - min) / (max - min), 1), BackgroundColor3 = Cfg.Accent, BorderSizePixel = 0 })
	corner(fill, UDim.new(1, 0))
	local knob = New("Frame", {
		Parent = track, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new((val - min) / (max - min), 0, 0.5, 0),
		Size = UDim2.fromOffset(10, 10), BackgroundColor3 = Cfg.Accent, BorderSizePixel = 0, ZIndex = 2,
	})
	corner(knob, UDim.new(1, 0))

	local ob = { Value = val }
	local function apply(a, fire)
		a = math.clamp(a, 0, 1); ob.Value = round(min + (max - min) * a)
		local t = (ob.Value - min) / (max - min)
		fill.Size = UDim2.fromScale(t, 1); knob.Position = UDim2.new(t, 0, 0.5, 0)
		valLbl.Text = tostring(ob.Value)
		if fire and o.Callback then task.spawn(o.Callback, ob.Value) end
	end
	function ob:Set(v) apply((math.clamp(v, min, max) - min) / (max - min), true) end
	local d = false
	local function upd(i) apply((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, true) end
	track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then d = true; upd(i) end end)
	UserInputService.InputChanged:Connect(function(i) if d and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then upd(i) end end)
	UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then d = false end end)
	return ob
end

function Library.Section:AddDropdown(o)
	local list = o.List or {}
	local selected = o.Default or list[1] or "None"

	local r = makeRow(self, 44)
	New("TextLabel", {
		Parent = r, Size = UDim2.new(1, -110, 1, 0), BackgroundTransparency = 1,
		Font = Cfg.FontBold, Text = string.upper(o.Text or "Dropdown"),
		TextColor3 = Cfg.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local valLbl = New("TextButton", {
		Parent = r, AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -18, 0.5, 0), Size = UDim2.fromOffset(90, 24),
		BackgroundTransparency = 1, AutoButtonColor = false,
		Font = Cfg.FontBold, Text = string.upper(tostring(selected)),
		TextColor3 = Cfg.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right,
	})
	local chev = New("TextLabel", {
		Parent = r, AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(14, 20),
		BackgroundTransparency = 1, Font = Cfg.FontBold, Text = "V",
		TextColor3 = Cfg.Text, TextSize = 12,
	})

	local menu = New("Frame", { Parent = self.Wrap, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Cfg.Panel, Visible = false, BorderSizePixel = 0 })
	corner(menu, UDim.new(0, 10)); stroke(menu, Cfg.StrokeSoft, 1); padding(menu, 4)
	New("UIListLayout", { Parent = menu, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder })

	local ob = { Value = selected }; local open = false
	local function setOpen(s) open = s; menu.Visible = s end
	local function sel(it) ob.Value = it; valLbl.Text = string.upper(tostring(it)); setOpen(false); if o.Callback then task.spawn(o.Callback, it) end end
	for _, it in ipairs(list) do
		local ib = New("TextButton", { Parent = menu, Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = Cfg.Panel, BackgroundTransparency = 1, AutoButtonColor = false, Font = Cfg.FontBold, Text = string.upper(tostring(it)), TextColor3 = Cfg.TextDim, TextSize = 13 })
		corner(ib, UDim.new(0, 5))
		ib.MouseEnter:Connect(function() TweenService:Create(ib, Cfg.Tween, { BackgroundTransparency = 0, BackgroundColor3 = Cfg.PanelHi, TextColor3 = Cfg.Text }):Play() end)
		ib.MouseLeave:Connect(function() TweenService:Create(ib, Cfg.Tween, { BackgroundTransparency = 1, TextColor3 = Cfg.TextDim }):Play() end)
		ib.MouseButton1Click:Connect(function() sel(it) end)
	end
	valLbl.MouseButton1Click:Connect(function() setOpen(not open) end)
	function ob:Set(it) sel(it) end
	return ob
end

-- =========================================================
-- DEMO — mirrors the Lyzn Hub reference
function Library.Section:AddButton(o)
	local r = makeRow(self, 32)
	local b = New("TextButton", {
		Parent = r, Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Cfg.Panel, BorderSizePixel = 0, AutoButtonColor = false,
		Font = Cfg.FontBold, Text = string.upper(o.Text or "Button"),
		TextColor3 = Cfg.Text, TextSize = 14,
	})
	corner(b, UDim.new(0, 8)); stroke(b, Cfg.StrokeSoft, 1)
	New("UIGradient", { Parent = b, Rotation = 135,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 20, 40)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 15, 26)),
		})})
	b.MouseEnter:Connect(function() TweenService:Create(b, Cfg.Tween, { BackgroundColor3 = Color3.fromRGB(140, 30, 50) }):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(b, Cfg.Tween, { BackgroundColor3 = Cfg.Panel }):Play() end)
	b.MouseButton1Click:Connect(function() if o.Callback then task.spawn(o.Callback) end end)
	return b
end

function Library.Section:AddLabel(t)
	local r = makeRow(self, 20)
	local lbl = New("TextLabel", {
		Parent = r, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		Font = Cfg.FontMed, Text = t, TextColor3 = Cfg.TextDim,
		TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
	})
	return { Set = function(_, v) lbl.Text = v end }
end

function Library.Section:AddKeybind(o)
	local r = makeRow(self, Cfg.RowHeight or 30)
	New("TextLabel", {
		Parent = r, Size = UDim2.new(1, -80, 1, 0), BackgroundTransparency = 1,
		Font = Cfg.FontBold, Text = string.upper(o.Text or "Keybind"),
		TextColor3 = Cfg.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
	})
	local cur = o.Default
	local btn = New("TextButton", {
		Parent = r, AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(74, 24),
		BackgroundColor3 = Color3.fromRGB(14, 12, 22), BorderSizePixel = 0,
		AutoButtonColor = false, Font = Cfg.FontBold,
		Text = cur and cur.Name or "NONE",
		TextColor3 = Cfg.TextDim, TextSize = 12,
	})
	corner(btn, UDim.new(0, 6)); stroke(btn, Color3.fromRGB(80, 30, 50), 1)
	local ob = { Key = cur }; local listening = false; local cn
	btn.MouseButton1Click:Connect(function()
		if listening then return end
		listening = true; btn.Text = "..."; btn.TextColor3 = Cfg.Accent
		cn = UserInputService.InputBegan:Connect(function(input, processed)
			if processed then return end
			listening = false; cn:Disconnect(); cn = nil
			if input.KeyCode == Enum.KeyCode.Escape then ob.Key = nil; btn.Text = "NONE"
			elseif input.UserInputType == Enum.UserInputType.Keyboard then ob.Key = input.KeyCode; btn.Text = input.KeyCode.Name end
			btn.TextColor3 = Cfg.TextDim
			if o.Callback then task.spawn(o.Callback, ob.Key) end
		end)
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or listening or not ob.Key then return end
		if input.KeyCode == ob.Key and o.OnPress then task.spawn(o.OnPress) end
	end)
	function ob:Set(k) ob.Key = k; btn.Text = k and k.Name or "NONE" end
	return ob
end


-- ===== Converted by gemini (gemini-flash-lite-latest) =====

shared._lyzn_stop = true
task.wait(0.2)
if shared._lyzn_cleanup then shared._lyzn_cleanup() end
shared._lyzn_stop = false

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer
local conns = {}

local Net = require(ReplicatedStorage.Modules.Packages.Net)

local CFG = {
    silent_aim = false,
    aim_target = "Head",
    aim_fov = 200,
    aim_show_fov = false,
    skeleton_esp = false,
    skeleton_color = Color3.fromRGB(140,100,255),
    box_esp = false,
    box_color = Color3.fromRGB(255,255,255),
    name_esp = false,
    health_esp = false,
    auto_farm_drops = false,
    infinite_energy = false,
    auto_rob_houses = false,
    auto_ham_palace = false,
    auto_farm_numz = false,
    infinite_ammo = false,
    noclip = false,
}

local Window = Library:CreateWindow({ Title = "Lyzn Hub", SubTitle = "Vice City 2" })
local lyznScreen = Window.Screen

local notifC = Instance.new("Frame", lyznScreen)
notifC.Position = UDim2.new(1, -20, 0, 20); notifC.AnchorPoint = Vector2.new(1, 0)
notifC.Size = UDim2.new(0, 280, 1, 0); notifC.BackgroundTransparency = 1; notifC.ZIndex = 100
Instance.new("UIListLayout", notifC).Padding = UDim.new(0, 5)

local function notify(msg, ntype)
    local color = (ntype == "success" and Color3.fromRGB(100, 255, 100)) or (ntype == "warning" and Color3.fromRGB(255, 100, 100)) or Cfg.Accent
    local f = Instance.new("Frame"); f.Size = UDim2.new(0, 0, 0, 30); f.BackgroundColor3 = Cfg.Panel; f.BorderSizePixel = 0
    f.ClipsDescendants = true; f.ZIndex = 100; f.Parent = notifC
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    local bar = Instance.new("Frame", f); bar.Size = UDim2.new(0, 3, 1, 0); bar.BackgroundColor3 = color; bar.BorderSizePixel = 0
    local lbl = Instance.new("TextLabel", f); lbl.Text = msg; lbl.TextColor3 = Cfg.Text; lbl.Font = Cfg.FontBold
    lbl.TextSize = 12; lbl.Size = UDim2.new(1, -14, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 101
    TweenService:Create(f, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Size = UDim2.new(0, 260, 0, 35) }):Play()
    task.delay(3, function() TweenService:Create(f, TweenInfo.new(0.5), { Size = UDim2.new(0, 0, 0, 0) }):Play(); task.wait(0.5); f:Destroy() end)
end

local espDrawings = {}
local fovCircle = nil
shared._lyzn_cleanup = function()
    shared._lyzn_stop = true
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    conns = {}
    for _, v in pairs(espDrawings) do
        if type(v) == "table" then for _, d in pairs(v) do pcall(function() d:Remove() end) end
        else pcall(function() v:Remove() end) end
    end
    espDrawings = {}
    if fovCircle then pcall(function() fovCircle:Remove() end); fovCircle = nil end
    pcall(function() lyznScreen:Destroy() end)
    shared._lyzn_aim_active = false
end

local netFolder = ReplicatedStorage.Modules.Packages._Index["sleitnick_net@0.2.0"].net

local function fireRemote(name, a1, a2, a3)
    pcall(function()
        local re = netFolder:FindFirstChild("RE/" .. name)
        if re then re:FireServer(a1, a2, a3) end
    end)
end

shared._lyzn_cfg = CFG

local function getClosestPlayer()
    local cfg = shared._lyzn_cfg
    local closest, closestDist = nil, cfg.aim_fov
    local chars = workspace:FindFirstChild("Characters")
    if not chars then return nil end
    local myChar = chars:FindFirstChild(LP.Name)
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
    for _, char in ipairs(chars:GetChildren()) do
        if char.Name ~= LP.Name then
            local hum = char:FindFirstChild("Humanoid")
            local targetPart = char:FindFirstChild(cfg.aim_target) or char:FindFirstChild("Head")
            if hum and hum.Health > 0 and targetPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist < closestDist then closestDist = dist; closest = char end
                end
            end
        end
    end
    return closest
end

shared._lyzn_aim_active = false
pcall(function()
    if shared._lyzn_old_nc then hookmetamethod(game, "__namecall", shared._lyzn_old_nc) end
    local oldNc
    oldNc = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if shared._lyzn_aim_active and method == "FireServer" and tostring(self) == "RE/Gun" then
            local args = { ... }
            if type(args[1]) == "string" and args[1] == "Replicate" and type(args[3]) == "table" then
                local target = getClosestPlayer()
                if target then
                    local cfg = shared._lyzn_cfg
                    local hitPart = target:FindFirstChild(cfg.aim_target) or target:FindFirstChild("Head")
                    if hitPart then
                        args[3].Hit = hitPart; args[3].Position = hitPart.Position
                        return oldNc(self, unpack(args))
                    end
                end
            end
        end
        return oldNc(self, ...)
    end))
    shared._lyzn_old_nc = oldNc; shared._lyzn_hooked = true
end)

local boneConnections = {
    { "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
    { "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
    { "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
    { "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
    { "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
}

local function createESPForChar(char)
    if char.Name == LP.Name then return end
    local key = char.Name
    if espDrawings[key] then for _, d in pairs(espDrawings[key]) do pcall(function() d:Remove() end) end end
    local data = {}
    for i = 1, #boneConnections do
        local line = Drawing.new("Line"); line.Thickness = 1.5; line.Color = CFG.skeleton_color; line.Transparency = 1; line.Visible = false
        data["bone" .. i] = line
    end
    local box = Drawing.new("Square"); box.Thickness = 1.5; box.Color = CFG.box_color; box.Filled = false; box.Visible = false; data.box = box
    local nameTag = Drawing.new("Text"); nameTag.Size = 14; nameTag.Color = Color3.new(1, 1, 1); nameTag.Center = true; nameTag.Outline = true; nameTag.Visible = false; nameTag.Text = char.Name; data.name = nameTag
    local healthBar = Drawing.new("Line"); healthBar.Thickness = 2; healthBar.Color = Color3.fromRGB(0, 255, 0); healthBar.Visible = false; data.health = healthBar
    local healthBg = Drawing.new("Line"); healthBg.Thickness = 2; healthBg.Color = Color3.fromRGB(60, 60, 60); healthBg.Visible = false; data.healthBg = healthBg
    espDrawings[key] = data
end

local function updateESP()
    local chars = workspace:FindFirstChild("Characters")
    if not chars then return end
    for _, char in ipairs(chars:GetChildren()) do
        if char.Name == LP.Name then continue end
        local key = char.Name
        if not espDrawings[key] then createESPForChar(char) end
        local data = espDrawings[key]; if not data then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart"); local hum = char:FindFirstChild("Humanoid"); local head = char:FindFirstChild("Head")
        if not hrp or not hum or hum.Health <= 0 then for _, d in pairs(data) do pcall(function() d.Visible = false end) end; continue end
        local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then for _, d in pairs(data) do pcall(function() d.Visible = false end) end; continue end
        for i, bone in ipairs(boneConnections) do
            local line = data["bone" .. i]
            if CFG.skeleton_esp then
                local p1 = char:FindFirstChild(bone[1]); local p2 = char:FindFirstChild(bone[2])
                if p1 and p2 then
                    local s1, v1 = Camera:WorldToViewportPoint(p1.Position); local s2, v2 = Camera:WorldToViewportPoint(p2.Position)
                    if v1 and v2 then line.From = Vector2.new(s1.X, s1.Y); line.To = Vector2.new(s2.X, s2.Y); line.Color = CFG.skeleton_color; line.Visible = true
                    else line.Visible = false end
                else line.Visible = false end
            else line.Visible = false end
        end
        if CFG.box_esp and head then
            local topPos = Camera:WorldToViewportPoint((head.CFrame * CFrame.new(0, 1.5, 0)).Position)
            local botPos = Camera:WorldToViewportPoint((hrp.CFrame * CFrame.new(0, -3, 0)).Position)
            if topPos.Z > 0 and botPos.Z > 0 then
                local h = math.abs(botPos.Y - topPos.Y); local w = h * 0.55
                data.box.Size = Vector2.new(w, h); data.box.Position = Vector2.new(topPos.X - w / 2, topPos.Y); data.box.Color = CFG.box_color; data.box.Visible = true
            else data.box.Visible = false end
        else data.box.Visible = false end
        if CFG.name_esp and head then
            local hp = Camera:WorldToViewportPoint((head.CFrame * CFrame.new(0, 2.5, 0)).Position)
            if hp.Z > 0 then data.name.Position = Vector2.new(hp.X, hp.Y); data.name.Visible = true
            else data.name.Visible = false end
        else data.name.Visible = false end
        if CFG.health_esp and head then
            local topPos = Camera:WorldToViewportPoint((head.CFrame * CFrame.new(0, 1.5, 0)).Position)
            local botPos = Camera:WorldToViewportPoint((hrp.CFrame * CFrame.new(0, -3, 0)).Position)
            if topPos.Z > 0 and botPos.Z > 0 then
                local h = math.abs(botPos.Y - topPos.Y); local w = h * 0.55; local x = topPos.X - w / 2 - 5
                local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                data.healthBg.From = Vector2.new(x, botPos.Y); data.healthBg.To = Vector2.new(x, topPos.Y); data.healthBg.Visible = true
                data.health.From = Vector2.new(x, botPos.Y); data.health.To = Vector2.new(x, botPos.Y - h * pct)
                data.health.Color = Color3.fromRGB(255 * (1 - pct), 255 * pct, 0); data.health.Visible = true
            else data.healthBg.Visible = false; data.health.Visible = false end
        else data.healthBg.Visible = false; data.health.Visible = false end
    end
    for key, data in pairs(espDrawings) do
        if not chars:FindFirstChild(key) then for _, d in pairs(data) do pcall(function() d:Remove() end) end; espDrawings[key] = nil end
    end
end

fovCircle = Drawing.new("Circle"); fovCircle.Thickness = 1; fovCircle.Color = Color3.fromRGB(255, 255, 255); fovCircle.Filled = false; fovCircle.Transparency = 0.5; fovCircle.Visible = false

table.insert(conns, RunService.RenderStepped:Connect(function()
    if shared._lyzn_stop then return end
    pcall(updateESP)
    if CFG.aim_show_fov and CFG.silent_aim then
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2); fovCircle.Radius = CFG.aim_fov; fovCircle.Visible = true
    else fovCircle.Visible = false end
    shared._lyzn_aim_active = CFG.silent_aim
end))

local MovementCtrl = nil
pcall(function() MovementCtrl = require(game:GetService("ReplicatedStorage").Modules.Client.Controllers.MovementController) end)
local energyFill = nil
pcall(function() energyFill = LP:WaitForChild("PlayerGui"):WaitForChild("HUD"):WaitForChild("Status"):WaitForChild("Energy"):WaitForChild("BG").OuterBar.Bar.Fill end)

table.insert(conns, RunService.RenderStepped:Connect(function()
    if shared._lyzn_stop then return end
    if CFG.infinite_energy and MovementCtrl then
        MovementCtrl.Stamina = 999
        if energyFill then pcall(function() energyFill.UIGradient.Offset = Vector2.new(0, 0) end) end
    end
end))

task.spawn(function()
    while not shared._lyzn_stop do
        if CFG.infinite_ammo then
            pcall(function()
                local char = LP.Character; if not char then return end
                local tool = char:FindFirstChildWhichIsA("Tool")
                if tool and tool:HasTag("Gun") then tool:SetAttribute("Ammo", 999) end
            end)
        end
        task.wait(0.1)
    end
end)

table.insert(conns, RunService.Stepped:Connect(function()
    if shared._lyzn_stop then return end
    if CFG.noclip then
        pcall(function()
            local char = LP.Character
            if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
        end)
    end
end))

local function safeTeleport(targetPos)
    local chars = workspace:FindFirstChild("Characters")
    local myC = chars and chars:FindFirstChild(LP.Name)
    local hrp = myC and myC:FindFirstChild("HumanoidRootPart")
    if not hrp then notify("No character", "warning"); return end
    pcall(function() LP:RequestStreamAroundAsync(targetPos, 5) end)
    task.wait(0.1)
    local targetCF = CFrame.new(targetPos)
    hrp.CFrame = targetCF; hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0); hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    local holdConn; local holdStart = tick()
    holdConn = RunService.Heartbeat:Connect(function()
        if tick() - holdStart > 1.2 then holdConn:Disconnect(); return end
        if hrp and hrp.Parent then hrp.CFrame = targetCF; hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end
    end)
    table.insert(conns, holdConn)
end

local function firePrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    pcall(function() fireproximityprompt(prompt) end)
end

local function getHRP()
    local chars = workspace:FindFirstChild("Characters")
    local myC = chars and chars:FindFirstChild(LP.Name)
    return myC and myC:FindFirstChild("HumanoidRootPart")
end

local function desyncTP(pos)
    local hrp = getHRP()
    if hrp then hrp.CFrame = CFrame.new(pos) end
end

local function instantFirePrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    local oldHold = prompt.HoldDuration; local oldDist = prompt.MaxActivationDistance
    prompt.MaxActivationDistance = 9999
    pcall(function() setproximitypromptduration(prompt, 0) end)
    prompt.HoldDuration = 0; task.wait(0.1)
    pcall(function() fireproximityprompt(prompt) end); task.wait(0.3)
    pcall(function() setproximitypromptduration(prompt, oldHold) end)
    prompt.HoldDuration = oldHold; prompt.MaxActivationDistance = oldDist
end

task.spawn(function()
    while not shared._lyzn_stop do
        if CFG.auto_farm_drops then
            pcall(function()
                local hrp = getHRP(); if not hrp then return end
                local chars = workspace:FindFirstChild("Characters")
                if chars then
                    for _, char in chars:GetChildren() do
                        if shared._lyzn_stop or not CFG.auto_farm_drops then break end
                        if char.Name ~= LP.Name then
                            local lootP = char:FindFirstChild("LootPrompt")
                            if lootP and lootP:IsA("ProximityPrompt") and lootP.Enabled then
                                local targetHRP = char:FindFirstChild("HumanoidRootPart")
                                if targetHRP then desyncTP(targetHRP.Position); task.wait(0.2); instantFirePrompt(lootP); task.wait(0.5) end
                            end
                        end
                    end
                end
                local drops = workspace:FindFirstChild("DroppedItems")
                if drops then
                    for _, item in drops:GetChildren() do
                        if shared._lyzn_stop or not CFG.auto_farm_drops then break end
                        local pos
                        if item:IsA("BasePart") then pos = item.Position
                        elseif item:IsA("Model") then local p = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart"); if p then pos = p.Position end end
                        if pos then desyncTP(pos + Vector3.new(0, 3, 0)); task.wait(0.3) end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

local robSavedPos = nil

local function teleportTo(pos)
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local startPos = hrp.Position
    local dist = (pos - startPos).Magnitude
    local stepSize = 20
    local steps = math.max(math.ceil(dist / stepSize), 1)
    for i = 1, steps do
        if shared._lyzn_stop or not CFG.auto_rob_houses then return false end
        local char2 = LP.Character
        local hrp2 = char2 and char2:FindFirstChild("HumanoidRootPart")
        if not hrp2 then return false end
        hrp2.CFrame = CFrame.new(startPos:Lerp(pos, i / steps))
        RunService.Heartbeat:Wait()
    end
    return true
end

local function robFireProximityPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    local oldDist = prompt.MaxActivationDistance
    local oldHold = prompt.HoldDuration
    local oldEnabled = prompt.Enabled
    local oldStyle = prompt.Style
    prompt.MaxActivationDistance = 9999
    prompt.HoldDuration = 0
    prompt.Enabled = true
    if oldStyle == Enum.ProximityPromptStyle.Custom then
        prompt.Style = Enum.ProximityPromptStyle.Default
    end
    task.wait(0.3)
    pcall(fireproximityprompt, prompt)
    task.wait(0.3)
    pcall(fireproximityprompt, prompt)
    task.wait(0.5)
    pcall(function()
        prompt.MaxActivationDistance = oldDist
        prompt.HoldDuration = oldHold
        prompt.Enabled = oldEnabled
        prompt.Style = oldStyle
    end)
end

local function equipDrill()
    local char = LP.Character
    if not char then return false end
    if char:FindFirstChild("Drill") then return true end
    local bp = LP:FindFirstChild("Backpack")
    if bp and bp:FindFirstChild("Drill") then
        local drill = bp:FindFirstChild("Drill")
        drill.Parent = char
        task.wait(0.5)
        return true
    end
    return false
end

local function unequipDrill()
    local char = LP.Character
    if not char then return end
    local drill = char:FindFirstChild("Drill")
    if drill then
        local bp = LP:FindFirstChild("Backpack")
        if bp then drill.Parent = bp end
    end
    task.wait(0.3)
end

local badPromptActions = {
    ["Apply"] = true, ["Job"] = true, ["Work"] = true, ["Buy Apartment"] = true,
    ["Lock"] = true, ["Unlock"] = true, ["Ham"] = true, ["Order"] = true,
    ["Sell Items"] = true, ["Buy"] = true, ["Purchase"] = true, ["Talk"] = true, ["Interact"] = true,
}

local function randomDelay(minSec, maxSec)
    task.wait(minSec + math.random() * (maxSec - minSec))
end
local function randomOffset(pos, range)
    return pos + Vector3.new(math.random(-range, range), 0, math.random(-range, range))
end

task.spawn(function()
    local pawnPos = Vector3.new(-1150, 6, 654)
    local hardwarePos = Vector3.new(108, 6, -1921)
    local robbedHouses = {}
    while true do
        if shared._lyzn_stop then return end
        if CFG.auto_rob_houses then
            local hrpStart = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if hrpStart then robSavedPos = hrpStart.Position end
            local housesFolder = workspace:FindFirstChild("HouseRobberies")
            local houses = housesFolder and housesFolder:FindFirstChild("Houses")
            local locs = housesFolder and housesFolder:FindFirstChild("Locs")
            if houses then
                for _, house in ipairs(houses:GetChildren()) do
                    if not CFG.auto_rob_houses or shared._lyzn_stop then break end
                    pcall(function()
                        local robPrompt = house:FindFirstChild("RobPrompt")
                        local enterPrompt = house:FindFirstChild("Enter")
                        if not robPrompt or not house:IsA("BasePart") then return end
                        if house:GetAttribute("Cooldown") == true then return end
                        if robbedHouses[house.Name] then return end
                        local canEnter = enterPrompt and enterPrompt.Enabled
                        local needsDrill = robPrompt.Enabled and not canEnter
                        if not needsDrill and not canEnter then return end
                        if canEnter and not needsDrill then
                            notify("Entering " .. house.Name .. " (already open)", "success")
                        end
                        if needsDrill then
                            local bp = LP:FindFirstChild("Backpack")
                            local char = LP.Character
                            local hasDrill = (bp and bp:FindFirstChild("Drill")) or (char and char:FindFirstChild("Drill"))
                            if not hasDrill then
                                fireRemote("Hardware", "Purchase", {category = "Tools", name = "Drill"})
                                task.wait(2)
                            end
                            equipDrill()
                            randomDelay(2, 4)
                            local char = LP.Character
                            local hrp = char and char:FindFirstChild("HumanoidRootPart")
                            if not hrp then return end
                            local drillOffsets = {
                                Vector3.new(3, 1, 3), Vector3.new(-3, 1, -3),
                                Vector3.new(0, 1, 4), Vector3.new(0, 1, -4),
                            }
                            local drilled = false
                            for di = 1, #drillOffsets do
                                hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                                if not hrp then break end
                                hrp.CFrame = CFrame.new(randomOffset(house.Position + drillOffsets[di], 1))
                                randomDelay(1.5, 3)
                                robFireProximityPrompt(robPrompt)
                                randomDelay(2, 4)
                                enterPrompt = house:FindFirstChild("Enter")
                                if not robPrompt.Enabled or (enterPrompt and enterPrompt.Enabled) then
                                    drilled = true; break
                                end
                            end
                            if not drilled then
                                notify("Drill failed on " .. house.Name .. ", skipping", "warning")
                                robbedHouses[house.Name] = true; return
                            end
                        end
                        local char = LP.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if not hrp then return end
                        local waited = 0
                        while waited < 10 do
                            enterPrompt = house:FindFirstChild("Enter")
                            if enterPrompt and enterPrompt.Enabled then break end
                            task.wait(0.5); waited = waited + 0.5
                        end
                        if not enterPrompt or not enterPrompt.Enabled then
                            notify("Can't enter " .. house.Name .. ", skipping", "warning")
                            robbedHouses[house.Name] = true; return
                        end
                        local wasNoClip = CFG.noclip
                        unequipDrill()
                        randomDelay(1, 3)
                        local entered = false
                        local enterOffsets = {
                            Vector3.new(3, 1, 3), Vector3.new(-3, 1, -3),
                            Vector3.new(3, 1, -3), Vector3.new(-3, 1, 3),
                        }
                        for enterAttempt = 1, 4 do
                            if not CFG.auto_rob_houses or shared._lyzn_stop then break end
                            local freshHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                            if not freshHrp then break end
                            freshHrp.CFrame = CFrame.new(randomOffset(house.Position + enterOffsets[enterAttempt], 2))
                            randomDelay(2, 4)
                            enterPrompt = house:FindFirstChild("Enter")
                            if not enterPrompt or not enterPrompt.Enabled then
                                randomDelay(1, 2); enterPrompt = house:FindFirstChild("Enter")
                            end
                            if enterPrompt and enterPrompt.Enabled then
                                robFireProximityPrompt(enterPrompt)
                                randomDelay(3, 5)
                                freshHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                                if freshHrp and freshHrp.Position.Y < 0 then entered = true; break end
                            end
                        end
                        if not entered then
                            notify("Failed to enter " .. house.Name .. ", skipping", "warning")
                            robbedHouses[house.Name] = true; CFG.noclip = wasNoClip; return
                        end
                        local hrp2 = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                        if hrp2 then hrp2.AssemblyLinearVelocity = Vector3.zero; hrp2.AssemblyAngularVelocity = Vector3.zero end
                        task.wait(1.5)
                        pcall(function()
                            local failedItems = {}
                            local ITEM_TP_DELAY = 0.15
                            local FIRE_DELAY = 0.25
                            local UNEQUIP_WAIT = 0.2

                            for attempt = 1, 12 do
                                if not CFG.auto_rob_houses or shared._lyzn_stop then break end
                                local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                                if not hrp then break end

                                local char = LP.Character
                                if char then
                                    local tool = char:FindFirstChildWhichIsA("Tool")
                                    if tool then
                                        tool.Parent = LP.Backpack
                                        task.wait(UNEQUIP_WAIT)
                                    end
                                end

                                local items = {}
                                for _, obj in ipairs(workspace:GetDescendants()) do
                                    if obj:IsA("ProximityPrompt") and obj.Name == "Grab"
                                       and obj.Enabled and obj.Parent and obj.Parent:IsA("BasePart")
                                       and obj.Parent.Position.Y < 0
                                       and not failedItems[obj] then
                                        table.insert(items, obj)
                                    end
                                end

                                if #items == 0 then
                                    if attempt <= 3 then task.wait(0.4) else break end
                                else
                                    local myPos = hrp.Position
                                    table.sort(items, function(a, b)
                                        return (a.Parent.Position - myPos).Magnitude < (b.Parent.Position - myPos).Magnitude
                                    end)

                                    for _, obj in ipairs(items) do
                                        if not CFG.auto_rob_houses or shared._lyzn_stop then break end

                                        local charCheck = LP.Character
                                        if charCheck then
                                            local heldTool = charCheck:FindFirstChildWhichIsA("Tool")
                                            if heldTool then
                                                heldTool.Parent = LP.Backpack
                                                task.wait(UNEQUIP_WAIT)
                                            end
                                        end

                                        local hrpNow = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                                        if not hrpNow then break end
                                        pcall(function()
                                            hrpNow.CFrame = CFrame.new(obj.Parent.Position + Vector3.new(0, 2, 0))
                                            hrpNow.AssemblyLinearVelocity = Vector3.zero
                                            task.wait(ITEM_TP_DELAY)
                                            local oldDist = obj.MaxActivationDistance
                                            local oldHold = obj.HoldDuration
                                            obj.MaxActivationDistance = 9999
                                            obj.HoldDuration = 0
                                            pcall(setproximitypromptduration, obj, 0)
                                            pcall(fireproximityprompt, obj)
                                            task.wait(FIRE_DELAY)
                                            if obj.Enabled then
                                                pcall(fireproximityprompt, obj)
                                                task.wait(FIRE_DELAY)
                                                if obj.Enabled then failedItems[obj] = true end
                                            end
                                            pcall(function()
                                                obj.MaxActivationDistance = oldDist
                                                obj.HoldDuration = oldHold
                                                pcall(setproximitypromptduration, obj, oldHold)
                                            end)
                                        end)
                                    end
                                end
                            end
                        end)
                        CFG.noclip = wasNoClip
                        if CFG.auto_rob_houses and not shared._lyzn_stop then
                            pcall(function()
                                local char2 = LP.Character
                                if char2 then
                                    local tool = char2:FindFirstChildWhichIsA("Tool")
                                    if tool then tool.Parent = LP.Backpack; task.wait(0.2) end
                                end
                                local rooms = workspace:FindFirstChild("HouseRobberies") and workspace.HouseRobberies:FindFirstChild("Rooms")
                                if rooms then
                                    for _, room in ipairs(rooms:GetChildren()) do
                                        local leavePart = room:FindFirstChild("Leave")
                                        if leavePart then
                                            local leavePrompt = leavePart:FindFirstChildWhichIsA("ProximityPrompt")
                                            if leavePrompt and leavePrompt.Enabled then
                                                local hrpExit = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                                                if hrpExit then
                                                    hrpExit.CFrame = CFrame.new(leavePart.Position + Vector3.new(0, 1, 0))
                                                    task.wait(0.4)
                                                    robFireProximityPrompt(leavePrompt)
                                                    task.wait(1.5)
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end

                                local hrpSell = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                                if not hrpSell then return end
                                local sellCF = CFrame.new(pawnPos)
                                hrpSell.CFrame = sellCF
                                hrpSell.AssemblyLinearVelocity = Vector3.zero
                                hrpSell.AssemblyAngularVelocity = Vector3.zero
                                local holdStart = tick()
                                while tick() - holdStart < 1.0 do
                                    local h = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                                    if h then
                                        h.CFrame = sellCF
                                        h.AssemblyLinearVelocity = Vector3.zero
                                    end
                                    task.wait(0.1)
                                end

                                local pawnPrompt = nil
                                local npcFolder = workspace:FindFirstChild("NPC")
                                if npcFolder then
                                    local pawnNPC = npcFolder:FindFirstChild("Pawn Npc")
                                    if pawnNPC then
                                        for _, d in ipairs(pawnNPC:GetDescendants()) do
                                            if d:IsA("ProximityPrompt") then pawnPrompt = d; break end
                                        end
                                    end
                                end
                                if not pawnPrompt then
                                    notify("Pawn prompt not found", "warning")
                                    return
                                end

                                local skipItems = {Fists = true, Phone = true, Drill = true, BookBag = true, Bookbag = true}
                                local bp = LP:FindFirstChild("Backpack")
                                if bp then
                                    for sellPass = 1, 2 do
                                        local toSell = {}
                                        for _, item in ipairs(bp:GetChildren()) do
                                            if item:IsA("Tool") and not skipItems[item.Name] and not item:HasTag("Gun") then
                                                table.insert(toSell, item)
                                            end
                                        end
                                        if #toSell == 0 then break end
                                        for _, item in ipairs(toSell) do
                                            if not CFG.auto_rob_houses or shared._lyzn_stop then break end
                                            pcall(function()
                                                local hrpNow = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                                                if hrpNow then
                                                    hrpNow.CFrame = sellCF
                                                    hrpNow.AssemblyLinearVelocity = Vector3.zero
                                                end
                                                task.wait(0.15)
                                                item.Parent = LP.Character
                                                task.wait(0.25)
                                                robFireProximityPrompt(pawnPrompt)
                                                task.wait(0.35)
                                                if item.Parent == LP.Character then
                                                    robFireProximityPrompt(pawnPrompt)
                                                    task.wait(0.35)
                                                    if item.Parent == LP.Character then
                                                        item.Parent = LP.Backpack
                                                    end
                                                end
                                            end)
                                        end
                                    end
                                end
                                task.wait(0.3)
                            end)
                        end
                        robbedHouses[house.Name] = true
                        randomDelay(5, 10)
                    end)
                end
            end
            notify("Rob cycle complete, waiting 30s", "success")
            task.wait(30); robbedHouses = {}
        else
            task.wait(0.5)
        end
    end
end)

local JOB_BOARD_LOCATIONS = { ["Ham Palace"] = Vector3.new(-1506, 6, -903), ["Fastfood Worker"] = Vector3.new(-856, 4, -1551) }

local function ensureJob(jobName)
    local currentJob = LP:GetAttribute("Job")
    if currentJob == jobName then return true end
    local boardPos = JOB_BOARD_LOCATIONS[jobName]
    if not boardPos then notify("Unknown job: " .. jobName, "warning"); return false end
    pcall(function() LP:RequestStreamAroundAsync(boardPos, 5) end); task.wait(0.5)
    local hrp = getHRP(); if hrp then hrp.CFrame = CFrame.new(boardPos) end; task.wait(1)
    if currentJob and currentJob ~= jobName then
        local jb = workspace:FindFirstChild("JobBoard")
        if jb then
            local oldPos = JOB_BOARD_LOCATIONS[currentJob]
            if oldPos then pcall(function() LP:RequestStreamAroundAsync(oldPos, 5) end); task.wait(0.5); hrp = getHRP(); if hrp then hrp.CFrame = CFrame.new(oldPos) end; task.wait(1) end
            local old = jb:FindFirstChild(currentJob)
            if old then local p = old:FindFirstChildWhichIsA("ProximityPrompt", true); if p then firePrompt(p); task.wait(1) end end
            pcall(function() LP:RequestStreamAroundAsync(boardPos, 5) end); task.wait(0.5); hrp = getHRP(); if hrp then hrp.CFrame = CFrame.new(boardPos) end; task.wait(1)
        end
    end
    local jb = workspace:FindFirstChild("JobBoard")
    if jb then
        local jobModel = jb:FindFirstChild(jobName)
        if jobModel then
            local p = jobModel:FindFirstChildWhichIsA("ProximityPrompt", true)
            if p then firePrompt(p); task.wait(1); if LP:GetAttribute("Job") == jobName then notify("Started job: " .. jobName, "success"); return true end end
        end
    end
    notify("Could not start " .. jobName .. " job", "warning"); return false
end

local HAM_STEPS = {
    { name = "TakeOrder", pos = Vector3.new(-1493, 4, -906), wait = 1.5 },
    { name = "GrabBread", pos = Vector3.new(-1494, 4, -922), wait = 1.5 },
    { name = "Oven", pos = Vector3.new(-1481, 4, -921), wait = 3 },
    { name = "SellOrder", pos = Vector3.new(-1487, 4, -906), wait = 1.5 },
}

task.spawn(function()
    while not shared._lyzn_stop do
        if CFG.auto_ham_palace then
            if not ensureJob("Ham Palace") then CFG.auto_ham_palace = false
            else
                for _, step in ipairs(HAM_STEPS) do
                    if shared._lyzn_stop or not CFG.auto_ham_palace then break end
                    local hrp = getHRP(); if not hrp then break end
                    hrp.CFrame = CFrame.new(step.pos); task.wait(0.3)
                    local prompts = workspace.JobAssets:FindFirstChild("Ham Palace")
                    if prompts then prompts = prompts:FindFirstChild("Prompts")
                        if prompts then local part = prompts:FindFirstChild(step.name)
                            if part then local prox = part:FindFirstChildWhichIsA("ProximityPrompt"); if prox then firePrompt(prox) end end
                        end
                    end
                    task.wait(step.wait)
                end
            end
        end
        task.wait(0.5)
    end
end)

local STORES = {
    { name = "Gun Store", pos = Vector3.new(-1249, 8, -1054) },
    { name = "Blackmarket", pos = Vector3.new(-1001, 7, 167) },
    { name = "Clothing Store", pos = Vector3.new(-1461, 7, -1766) },
    { name = "Female Clothing", pos = Vector3.new(-316, 8, -703) },
    { name = "Shoe Store", pos = Vector3.new(175, 8, 139) },
    { name = "Car Dealership", pos = Vector3.new(-230, 8, -428) },
    { name = "Jewellery Store", pos = Vector3.new(-296, 8, 626) },
    { name = "Pawn Shop", pos = Vector3.new(-1160, 8, 624) },
    { name = "Hardware Store", pos = Vector3.new(90, 7, -1908) },
    { name = "Ham Palace", pos = Vector3.new(-1474, 8, -854) },
    { name = "Convenience Store", pos = Vector3.new(102, 10, -321) },
    { name = "Deli", pos = Vector3.new(-984, 10, -671) },
    { name = "RoMazon", pos = Vector3.new(241, 8, -353) },
    { name = "Barber", pos = Vector3.new(-1461, 7, -65) },
    { name = "Tattoo Artist", pos = Vector3.new(-1091, 9, -536) },
    { name = "Studio", pos = Vector3.new(-70, 8, 2094) },
    { name = "Culder Apartments", pos = Vector3.new(-1667, 8, -299) },
}

local shopItems = {
    { cat = "Guns", items = {
        { name = "G17", price = 1500, remote = "GunShop", args = { category = "Gun", name = "G17" } },
        { name = "G43X Beam", price = 3000, remote = "GunShop", args = { category = "Gun", name = "G43X Beam" } },
        { name = "G22 DB", price = 3200, remote = "GunShop", args = { category = "Gun", name = "G22 DB" } },
        { name = "Springfield Hellcat", price = 3500, remote = "GunShop", args = { category = "Gun", name = "Springfield Hellcat" } },
        { name = "G19 Clear EXT", price = 4300, remote = "GunShop", args = { category = "Gun", name = "G19 Clear EXT" } },
        { name = "Tec-9", price = 4599, remote = "GunShop", args = { category = "Gun", name = "Tec-9" } },
        { name = "Draco", price = 5600, remote = "GunShop", args = { category = "Gun", name = "Draco" } },
        { name = "ARPistol", price = 7300, remote = "GunShop", args = { category = "Gun", name = "ARPistol" } },
        { name = "Draco Drum", price = 10000, remote = "GunShop", args = { category = "Gun", name = "Draco Drum" } },
    } },
    { cat = "Ammo", items = {
        { name = "9mm Mag", price = 100, remote = "GunShop", args = { category = "Ammo", name = "9mm Mag" } },
        { name = "9mm Extended", price = 120, remote = "GunShop", args = { category = "Ammo", name = "9mm Extended" } },
        { name = "5.56 Mag", price = 100, remote = "GunShop", args = { category = "Ammo", name = "5.56 Mag" } },
        { name = "7.62 Mag", price = 100, remote = "GunShop", args = { category = "Ammo", name = "7.62 Mag" } },
        { name = "Drum Mag", price = 150, remote = "GunShop", args = { category = "Ammo", name = "Drum Mag" } },
    } },
    { cat = "Tools", items = {
        { name = "Drill", price = 150, remote = "Hardware", args = { category = "Tools", name = "Drill" } },
    } },
}

local combatTab = Window:CreateTab("Combat", "crosshair")
local aimSec = combatTab:CreateSection("Silent Aim", "Left")
aimSec:AddToggle({ Text = "Enabled", Default = false, Callback = function(v) CFG.silent_aim = v; notify(v and "Silent Aim ON" or "Silent Aim OFF", v and "success" or "warning") end })
aimSec:AddToggle({ Text = "Show FOV", Default = false, Callback = function(v) CFG.aim_show_fov = v end })
aimSec:AddSlider({ Text = "FOV Radius", Min = 50, Max = 500, Default = 200, Decimals = 0, Callback = function(v) CFG.aim_fov = v end })
aimSec:AddDropdown({ Text = "Target", List = { "Head", "UpperTorso", "HumanoidRootPart" }, Default = "Head", Callback = function(v) CFG.aim_target = v end })

local combatRightSec = combatTab:CreateSection("Combat", "Right")
combatRightSec:AddToggle({ Text = "Infinite Ammo", Default = false, Callback = function(v) CFG.infinite_ammo = v; notify(v and "Inf Ammo ON" or "Inf Ammo OFF", v and "success" or "warning") end })
combatRightSec:AddToggle({ Text = "No Clip", Default = false, Callback = function(v) CFG.noclip = v; notify(v and "No Clip ON" or "No Clip OFF", v and "success" or "warning") end })

local visualsTab = Window:CreateTab("Visuals", "eye")
local espSec = visualsTab:CreateSection("ESP", "Left")
espSec:AddToggle({ Text = "Skeleton ESP", Default = false, Callback = function(v) CFG.skeleton_esp = v; notify(v and "Skeleton ON" or "Skeleton OFF", v and "success" or "warning") end })
espSec:AddToggle({ Text = "Box ESP", Default = false, Callback = function(v) CFG.box_esp = v end })
espSec:AddToggle({ Text = "Name ESP", Default = false, Callback = function(v) CFG.name_esp = v end })
espSec:AddToggle({ Text = "Health Bar", Default = false, Callback = function(v) CFG.health_esp = v end })

local colorSec = visualsTab:CreateSection("Quick Colors", "Right")
local colorPresets = {
    { "Purple", Color3.fromRGB(140, 100, 255) }, { "Red", Color3.fromRGB(255, 50, 50) },
    { "Cyan", Color3.fromRGB(0, 255, 255) }, { "Green", Color3.fromRGB(50, 255, 50) },
    { "Pink", Color3.fromRGB(255, 100, 200) }, { "Orange", Color3.fromRGB(255, 165, 0) },
    { "White", Color3.fromRGB(255, 255, 255) }, { "Yellow", Color3.fromRGB(255, 255, 50) },
}
for _, preset in ipairs(colorPresets) do
    colorSec:AddButton({ Text = preset[1], Callback = function() CFG.skeleton_color = preset[2]; CFG.box_color = preset[2]; notify("Color: " .. preset[1], "success") end })
end

local tpTab = Window:CreateTab("Teleport", "map-pin")
local tpLeft = tpTab:CreateSection("Stores", "Left")
local tpRight = tpTab:CreateSection("More Stores", "Right")
for i, store in ipairs(STORES) do
    local sec = i <= 9 and tpLeft or tpRight
    sec:AddButton({ Text = store.name, Callback = function() safeTeleport(store.pos); notify("TP: " .. store.name, "success") end })
end

local farmTab = Window:CreateTab("Farm", "pickaxe")
local playerSec = farmTab:CreateSection("Player", "Left")
playerSec:AddToggle({ Text = "Infinite Energy", Default = false, Callback = function(v) CFG.infinite_energy = v; notify(v and "Inf Energy ON" or "Inf Energy OFF", v and "success" or "warning") end })

local lootSec = farmTab:CreateSection("Loot", "Left")
lootSec:AddToggle({ Text = "Auto Collect Drops", Default = false, Callback = function(v) CFG.auto_farm_drops = v; notify(v and "Auto Collect ON" or "Auto Collect OFF", v and "success" or "warning") end })
lootSec:AddButton({ Text = "Loot All Players", Callback = function()
    local chars = workspace:FindFirstChild("Characters"); local hrp = getHRP()
    if not chars or not hrp then notify("No character", "warning"); return end
    local count = 0
    for _, char in chars:GetChildren() do
        if char.Name ~= LP.Name then
            local lootP = char:FindFirstChild("LootPrompt")
            if lootP and lootP:IsA("ProximityPrompt") and lootP.Enabled then
                local tHRP = char:FindFirstChild("HumanoidRootPart")
                if tHRP then desyncTP(tHRP.Position); task.wait(0.2); instantFirePrompt(lootP); count = count + 1; task.wait(0.3) end
            end
        end
    end
    if count > 0 then notify("Looted " .. count .. " players", "success") else notify("No lootable players", "warning") end
end })

local jobsSec = farmTab:CreateSection("Jobs", "Right")
jobsSec:AddToggle({ Text = "Auto Rob Houses", Default = false, Callback = function(v)
    CFG.auto_rob_houses = v
    if v then CFG.auto_ham_palace = false end
    if not v and robSavedPos then
        task.defer(function() local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if hrp then hrp.CFrame = CFrame.new(robSavedPos) end; notify("Returned to start position", "success") end)
    end
    notify(v and "Auto Rob ON" or "Auto Rob OFF", v and "success" or "warning")
end })
jobsSec:AddToggle({ Text = "Auto Ham Palace", Default = false, Callback = function(v)
    CFG.auto_ham_palace = v
    if v then CFG.auto_rob_houses = false end
    notify(v and "Ham Palace Farm ON" or "Ham Palace OFF", v and "success" or "warning")
end })
jobsSec:AddToggle({ Text = "Auto Farm Numz", Default = false, Callback = function(v)
    CFG.auto_farm_numz = v
    if v then CFG.auto_rob_houses = false; CFG.auto_ham_palace = false end
    notify(v and "Numz Farm ON" or "Numz Farm OFF", v and "success" or "warning")
end })

local shopTab = Window:CreateTab("Shop", "shopping-bag")
for _, sectionData in ipairs(shopItems) do
    local side = sectionData.cat == "Guns" and "Left" or "Right"
    local sec = shopTab:CreateSection(sectionData.cat, side)
    for _, item in ipairs(sectionData.items) do
        sec:AddButton({ Text = item.name .. "  $" .. item.price, Callback = function()
            fireRemote(item.remote, "Purchase", item.args); notify("Bought " .. item.name, "success")
        end })
    end
end

task.spawn(function()
    local NUMZ_NAMES = { ["Grape Numz"] = true, ["Strawberry Numz"] = true, ["Blue Raspberry Numz"] = true, ["Pink Lemonade Numz"] = true }
    local MAX_COOKERS = 3
    local PABLO_POS = Vector3.new(-1012, 6, -671)
    local COOKING_POS = Vector3.new(433.2, 6.67, 235.6)
    local Net = require(ReplicatedStorage.Modules.Packages.Net)
    local NumzRE = Net:RemoteEvent("Numz")
    local NumzRF = Net:RemoteFunction("NumzFunction")
    local ConvRE = Net:RemoteEvent("Convenience")

    local sellDone = false
    NumzRE.OnClientEvent:Connect(function(msg) if msg == "End" then sellDone = true end end)

    local STAGES = {
        { keywords = {"pour water", "add water", "water"}, tool = "Water Gallon", waitAfter = 0.9 },
        { keywords = {"pour flavor", "add flavor", "flavor", "packet"}, tool = "Flavor Packet", waitAfter = 0.9 },
        { keywords = {"boil"}, tool = nil, waitAfter = 1.0 },
        { keywords = {"cut", "process"}, tool = nil, waitAfter = 1.5 },
    }

    local function safeTP(pos)
        local hrp = getHRP(); if hrp then hrp.CFrame = CFrame.new(pos) end
    end

    local function countTool(name)
        local n = 0
        local bp = LP:FindFirstChild("Backpack")
        local char = LP.Character
        if bp then for _, t in ipairs(bp:GetChildren()) do if t.Name == name then n = n + 1 end end end
        if char then for _, t in ipairs(char:GetChildren()) do if t.Name == name then n = n + 1 end end end
        return n
    end

    local function equipTool(name)
        local char = LP.Character; if not char then return nil end
        local eq = char:FindFirstChild(name)
        if eq then return eq end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum:UnequipTools() end
        local bp = LP:FindFirstChild("Backpack")
        local tool = bp and bp:FindFirstChild(name)
        if not tool then return nil end
        pcall(function() tool.Parent = char end)
        task.wait(0.15)
        return char:FindFirstChild(name)
    end

    local function findAllNumzTools()
        local out = {}
        local bp = LP:FindFirstChild("Backpack")
        local char = LP.Character
        if bp then for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") and NUMZ_NAMES[t.Name] then table.insert(out, t) end end end
        if char then for _, t in ipairs(char:GetChildren()) do if t:IsA("Tool") and NUMZ_NAMES[t.Name] then table.insert(out, t) end end end
        return out
    end

    local function buyPabloItem(itemName)
        pcall(function() ConvRE:FireServer("PurchasePablo", { name = itemName, category = "Items" }) end)
    end

    local function getOwnedCookerParts()
        local myName = LP.Name
        local seen = {}
        local out = {}
        local ca = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("CookingArea")
        if not ca then return out end
        for _, obj in ipairs(ca:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.ObjectText and obj.ObjectText:find(myName, 1, true) then
                local p = obj.Parent
                if p and p:IsA("BasePart") and not seen[p] then
                    seen[p] = true
                    table.insert(out, p)
                end
            end
        end
        return out
    end

    local function nextStageForCooker(part)
        if not part then return nil end
        for stageIdx, stage in ipairs(STAGES) do
            for _, obj in ipairs(part:GetChildren()) do
                if obj:IsA("ProximityPrompt") and obj.Enabled then
                    local at = obj.ActionText:lower()
                    for _, kw in ipairs(stage.keywords) do
                        if at:find(kw, 1, true) then
                            return stage, obj
                        end
                    end
                end
            end
        end
        return nil
    end

    local function findFreeClaim()
        local best, bestD = nil, math.huge
        local ca = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("CookingArea")
        if not ca then return nil end
        local hrp = getHRP()
        for _, obj in ipairs(ca:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Enabled and obj.ActionText == "Claim Cooker" then
                if obj.Parent and obj.Parent:IsA("BasePart") and hrp then
                    local d = (obj.Parent.Position - hrp.Position).Magnitude
                    if d < bestD then best = obj; bestD = d end
                end
            end
        end
        return best
    end

    local function firePrompt(prompt)
        if not prompt then return end
        local oldHold = prompt.HoldDuration
        prompt.HoldDuration = 0
        pcall(function() fireproximityprompt(prompt) end)
        prompt.HoldDuration = oldHold
    end

    local function findBuyerPrompt(buyer)
        if not buyer then return nil end
        for _, obj in ipairs(buyer:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Enabled then
                return obj
            end
        end
        return nil
    end

    local function sellRoutine()
        if #findAllNumzTools() == 0 then return end

        local safetyCap = 60
        while safetyCap > 0 and CFG.auto_farm_numz do
            safetyCap = safetyCap - 1

            local tools = findAllNumzTools()
            if #tools == 0 then break end
            local tool = tools[1]
            if not tool or not tool.Parent then task.wait() continue end

            local buyerInfo
            pcall(function() buyerInfo = NumzRF:InvokeServer("TrackBuyer") end)
            if not buyerInfo or not buyerInfo.Buyer then task.wait(1.2); break end
            local buyer = buyerInfo.Buyer
            local buyerHRP = buyer:FindFirstChild("HumanoidRootPart")
            if not buyerHRP then task.wait(0.4); continue end

            safeTP(buyerHRP.Position + Vector3.new(0, 3, 0)); task.wait(0.5)
            if not tool.Parent then continue end
            pcall(function() tool.Parent = LP.Character end); task.wait(0.25)

            local prompt
            local waited = 0
            while waited < 1.2 and not prompt and CFG.auto_farm_numz do
                prompt = findBuyerPrompt(buyer)
                if prompt then break end
                task.wait(0.15); waited = waited + 0.15
            end

            if prompt then
                sellDone = false
                local oldHold = prompt.HoldDuration
                pcall(function() prompt.HoldDuration = 0 end)
                for i = 1, 4 do
                    if sellDone or not CFG.auto_farm_numz then break end
                    if not tool.Parent then break end
                    pcall(function() fireproximityprompt(prompt) end)
                    task.wait(0.3)
                end
                pcall(function() prompt.HoldDuration = oldHold end)
            end

            task.wait(0.5)
        end
    end

    while not shared._lyzn_stop do
        if not CFG.auto_farm_numz then task.wait(0.5) continue end

        if #findAllNumzTools() > 0 then
            sellRoutine()
            task.wait(0.6)
            continue
        end

        local owned = getOwnedCookerParts()
        if #owned < MAX_COOKERS then
            safeTP(COOKING_POS); task.wait(0.6)
            local claimTries = 0
            while #owned < MAX_COOKERS and CFG.auto_farm_numz and claimTries < 6 do
                local claim = findFreeClaim()
                if not claim then break end
                safeTP(claim.Parent.Position + Vector3.new(0, 3, 0)); task.wait(0.35)
                firePrompt(claim); task.wait(0.9)
                owned = getOwnedCookerParts()
                claimTries = claimTries + 1
            end
            if #owned == 0 then task.wait(2); continue end
        end

        local didWork = false
        local needBuy = { ["Water Gallon"] = 0, ["Flavor Packet"] = 0 }

        for _, cooker in ipairs(owned) do
            if not CFG.auto_farm_numz then break end
            local stage, prompt = nextStageForCooker(cooker)
            if not stage then continue end
            if stage.tool and countTool(stage.tool) <= 0 then
                needBuy[stage.tool] = (needBuy[stage.tool] or 0) + 1
                continue
            end
            safeTP(cooker.Position + Vector3.new(0, 3, 0)); task.wait(0.25)
            if stage.tool then equipTool(stage.tool); task.wait(0.15) end
            firePrompt(prompt)
            task.wait(stage.waitAfter)
            didWork = true
        end

        local totalNeeded = (needBuy["Water Gallon"] or 0) + (needBuy["Flavor Packet"] or 0)
        if totalNeeded > 0 and CFG.auto_farm_numz then
            safeTP(PABLO_POS); task.wait(0.6)
            for i = 1, (needBuy["Water Gallon"] or 0) do
                if not CFG.auto_farm_numz then break end
                buyPabloItem("Water Gallon"); task.wait(1.1)
            end
            for i = 1, (needBuy["Flavor Packet"] or 0) do
                if not CFG.auto_farm_numz then break end
                buyPabloItem("Flavor Packet"); task.wait(1.1)
            end
            didWork = true
        end

        if not didWork then task.wait(6) end
    end
end)

table.insert(conns, UserInputService.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.End then shared._lyzn_cleanup() end
end))

notify("Lyzn Hub Loaded", "success")
notify("Vice City 2", "success")
print("[Lyzn] Vice City 2 loaded")