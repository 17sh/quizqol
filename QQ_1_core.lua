--[[
	Quiz QoL v3.0 | ไฟล์ 1/5: แกนหลัก (การตั้งค่า ธีม ตัวช่วยสร้าง UI)
	วิธีใช้: รันไฟล์ 1 → 2 → 3 → 4 → 5 ตามลำดับ ทีละไฟล์
	รอให้ขึ้นข้อความ "เรียบร้อย" ก่อนรันไฟล์ถัดไป เมนูจะโผล่หลังไฟล์ที่ 5 รันเสร็จ
	หลักการ: ข้อมูลทั้งหมดมาจากที่คุณจดเอง ไม่อ่านคำเฉลยและไม่ยุ่งกับระบบตอบของเกม
]]
local VERSION = "3.0"
local G = (getgenv and getgenv()) or _G

local Svc = setmetatable({}, {__index = function(t, k)
	local ok, v = pcall(function() return game:GetService(k) end)
	if ok and v then rawset(t, k, v); return v end
	return nil
end})
local LP = Svc.Players.LocalPlayer
local setclip = setclipboard or toclipboard or set_clipboard

local function notify(msg, dur)
	print("[QuizQoL] " .. tostring(msg))
	pcall(function()
		Svc.StarterGui:SetCore("SendNotification", {Title = "Quiz QoL", Text = tostring(msg):sub(1, 200), Duration = dur or 5})
	end)
end

local function mountGui(g)
	for _, get in ipairs({
		function() return LP:WaitForChild("PlayerGui", 5) end,
		function() return gethui and gethui() end,
		function() return Svc.CoreGui end,
	}) do
		local okp, parent = pcall(get)
		if okp and parent then
			local okSet = pcall(function() g.Parent = parent end)
			if okSet and g.Parent then return true end
		end
	end
	return false
end

-- ถ้าสคริปพัง จะมีกล่องแดงขึ้นบนจอบอกสาเหตุ (แตะเพื่อปิด) ส่งข้อความนี้มาให้ผมได้เลย
local function fatal(err)
	notify("โหลดไม่สำเร็จ: " .. tostring(err), 15)
	pcall(function()
		local g = Instance.new("ScreenGui")
		g.Name = "QUIZQOL_ERR"; g.ResetOnSpawn = false; g.DisplayOrder = 3000
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, -40, 0, 0); b.AutomaticSize = Enum.AutomaticSize.Y; b.Position = UDim2.fromOffset(20, 20)
		b.BackgroundColor3 = Color3.fromRGB(70, 12, 24); b.TextColor3 = Color3.new(1, 1, 1); b.TextWrapped = true
		b.TextSize = 14; b.Font = Enum.Font.Code; b.AutoButtonColor = false
		b.Text = "Quiz QoL error:\n" .. tostring(err):sub(1, 700) .. "\n\n(แตะเพื่อปิด)"
		b.Parent = g
		b.MouseButton1Click:Connect(function() g:Destroy() end)
		mountGui(g)
	end)
end

notify("กำลังโหลด Quiz QoL v" .. VERSION .. " (ไฟล์ 1/5) ...", 2)

local function part1()
	if G.QUIZQOL_UNLOAD then pcall(G.QUIZQOL_UNLOAD) end
	math.randomseed(os.time())

	-- ตารางกลางที่ไฟล์ 2-5 ใช้ร่วมกัน
	local Q = {
		VERSION = VERSION, G = G, Svc = Svc, LP = LP, setclip = setclip,
		notify = notify, mountGui = mountGui, fatal = fatal,
		alive = true, conns = {}, cleanups = {}, stage = 0,
	}
	G.QQ = Q
	local noop = function() end
	function Q.track(c) Q.conns[#Q.conns + 1] = c; return c end
	function Q.onCleanup(f) Q.cleanups[#Q.cleanups + 1] = f end
	Q.noop = noop
	Q.F = setmetatable({}, {__index = function() return noop end}) -- ฟังก์ชันที่ผูกทีหลัง (ถ้ายังไม่มีจะไม่ทำอะไร)
	Q.R = {now = noop, bar = noop, target = noop, fill = noop, banner = noop}

	-- ===== ตั้งค่า (บันทึกลงไฟล์) =====
	local CFG_FILE = "QuizQoL_config.json"
	local canFile = (writefile and readfile and isfile) and true or false
	Q.BOOK_FILE = "QuizMemory.json"
	Q.canFile = canFile
	local defaults = {accent = "pink", scale = 1, antiAfk = true, autoRejoin = false, hud = true, hudSize = 15, hudHide = 0,
		joinAlert = false, minLen = 5, sort = "recent", filter = "all", drillSet = "all", drillN = 10}
	local cfg = {}
	for k, v in pairs(defaults) do cfg[k] = v end
	if canFile then
		pcall(function()
			if isfile(CFG_FILE) then
				local d = Svc.HttpService:JSONDecode(readfile(CFG_FILE))
				if type(d) == "table" then for k, v in pairs(d) do cfg[k] = v end end
			end
		end)
	end
	local function saveCfg()
		if canFile then pcall(function() writefile(CFG_FILE, Svc.HttpService:JSONEncode(cfg)) end) end
	end
	local function clampNum(v, d, lo, hi) if type(v) ~= "number" then return d end return math.clamp(v, lo, hi) end
	cfg.scale = clampNum(cfg.scale, 1, 0.6, 1.4)
	cfg.hudSize = clampNum(cfg.hudSize, 15, 11, 26)
	cfg.hudHide = clampNum(cfg.hudHide, 0, 0, 60)
	cfg.minLen = clampNum(cfg.minLen, 5, 1, 60)
	cfg.drillN = clampNum(cfg.drillN, 10, 5, 20)

	-- ===== ธีม =====
	local T = {
		bg = Color3.fromRGB(14, 13, 22), card = Color3.fromRGB(25, 24, 38), card2 = Color3.fromRGB(36, 35, 54), btn = Color3.fromRGB(52, 50, 76),
		text = Color3.new(1, 1, 1), sub = Color3.fromRGB(160, 156, 185), good = Color3.fromRGB(74, 222, 128), bad = Color3.fromRGB(248, 113, 113),
		goodBtn = Color3.fromRGB(30, 130, 80), badBtn = Color3.fromRGB(185, 60, 66), warn = Color3.fromRGB(251, 191, 36),
		info = Color3.fromRGB(96, 165, 250), acc = Color3.fromRGB(236, 72, 153),
	}
	local ACCENTS = {
		{"pink", Color3.fromRGB(236, 72, 153)}, {"blue", Color3.fromRGB(59, 130, 246)}, {"green", Color3.fromRGB(34, 197, 94)},
		{"purple", Color3.fromRGB(168, 85, 247)}, {"orange", Color3.fromRGB(249, 115, 22)}, {"cyan", Color3.fromRGB(6, 182, 212)},
	}
	for _, a in ipairs(ACCENTS) do if a[1] == cfg.accent then T.acc = a[2] end end
	local painters = {}
	local function bindAcc(fn) painters[#painters + 1] = fn; pcall(fn) end
	local function setAccent(name)
		for _, a in ipairs(ACCENTS) do if a[1] == name then T.acc = a[2]; cfg.accent = name end end
		for _, fn in ipairs(painters) do pcall(fn) end
		saveCfg()
	end
	local KIND = {new = T.info, known = T.good, warn = T.warn}

	-- ===== ตัวช่วยสร้าง UI =====
	local order = {}
	local function new(c, p, par)
		local o = Instance.new(c)
		for k, v in pairs(p or {}) do o[k] = v end
		if par then
			if not (p and p.LayoutOrder) and o:IsA("GuiObject") then
				order[par] = (order[par] or 0) + 1
				o.LayoutOrder = order[par]
			end
			o.Parent = par
		end
		return o
	end
	local function corner(o, r) return new("UICorner", {CornerRadius = UDim.new(0, r or 8)}, o) end
	local function pad(o, t, r, b, l)
		return new("UIPadding", {PaddingTop = UDim.new(0, t), PaddingRight = UDim.new(0, r), PaddingBottom = UDim.new(0, b), PaddingLeft = UDim.new(0, l)}, o)
	end
	local function lbl(par, p)
		local d = {BackgroundTransparency = 1, TextColor3 = T.text, Font = Enum.Font.GothamMedium, TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0}
		for k, v in pairs(p or {}) do d[k] = v end
		return new("TextLabel", d, par)
	end
	local function mkbtn(par, p, cb)
		local d = {BackgroundColor3 = T.btn, TextColor3 = T.text, Font = Enum.Font.GothamBold, TextSize = 13, BorderSizePixel = 0}
		for k, v in pairs(p or {}) do d[k] = v end
		local b = new("TextButton", d, par)
		corner(b, 8)
		if cb then b.MouseButton1Click:Connect(function() task.spawn(cb, b) end) end
		return b
	end
	local function textbox(par, placeholder)
		local b = new("TextBox", {Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = T.card2, TextColor3 = T.text, PlaceholderColor3 = T.sub,
			PlaceholderText = placeholder or "", Font = Enum.Font.GothamMedium, TextSize = 13, Text = "", ClearTextOnFocus = false,
			TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0}, par)
		corner(b, 8); pad(b, 0, 10, 0, 10)
		return b
	end
	local function tween(o, props, t)
		pcall(function() Svc.TweenService:Create(o, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad), props):Play() end)
	end
	local function clearBox(f) for _, c in ipairs(f:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end end

	-- ส่งออกให้ไฟล์ถัดไป
	Q.cfg, Q.saveCfg, Q.defaults = cfg, saveCfg, defaults
	Q.T, Q.ACCENTS, Q.KIND = T, ACCENTS, KIND
	Q.bindAcc, Q.setAccent = bindAcc, setAccent
	Q.new, Q.corner, Q.pad, Q.lbl, Q.mkbtn = new, corner, pad, lbl, mkbtn
	Q.textbox, Q.tween, Q.clearBox = textbox, tween, clearBox

	Q.stage = 1
	notify("✅ ไฟล์ 1/5 เรียบร้อย รันไฟล์ 2 ต่อได้เลย", 5)
end

local ok, err = xpcall(part1, function(e) return tostring(e) .. "\n" .. ((debug and debug.traceback) and debug.traceback("", 2) or "") end)
if not ok then fatal(err) end
