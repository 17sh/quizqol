--[[
	Quiz QoL v3.0 | ไฟล์ 2/5: หน้าต่างหลัก แท็บ และชิ้นส่วน UI
	ต้องรันไฟล์ 1 เสร็จก่อน
]]
local G = (getgenv and getgenv()) or _G
local Q = G.QQ
local N = 2
local function say(msg)
	print("[QuizQoL] " .. msg)
	pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Quiz QoL", Text = msg, Duration = 8}) end)
end
if not Q then say("ต้องรันไฟล์ 1 ก่อน"); return end
if Q.stage ~= N - 1 then
	say(Q.stage < N - 1 and ("ต้องรันไฟล์ " .. (Q.stage + 1) .. " ก่อน") or ("ไฟล์ " .. N .. " รันไปแล้ว ถ้าจะเริ่มใหม่ให้รันไฟล์ 1 อีกครั้ง"))
	return
end

local function part2()
	local Svc, LP, cfg, saveCfg, T, bindAcc = Q.Svc, Q.LP, Q.cfg, Q.saveCfg, Q.T, Q.bindAcc
	local new, corner, pad, lbl, mkbtn, tween = Q.new, Q.corner, Q.pad, Q.lbl, Q.mkbtn, Q.tween
	local track, F, R, notify, mountGui = Q.track, Q.F, Q.R, Q.notify, Q.mountGui

	-- ===== หน้าต่างหลัก (ซ่อนไว้จนกว่าไฟล์ 5 จะรันเสร็จ) =====
	local BASEW, BASEH = 470, 570
	local gui = new("ScreenGui", {Name = "QUIZQOL", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 2500,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = false})
	pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
	pcall(function() local o = LP.PlayerGui:FindFirstChild("QUIZQOL"); if o then o:Destroy() end end)
	if not mountGui(gui) then notify("ติดตั้งหน้าจอไม่สำเร็จ (ไม่พบที่วาง UI)", 10); return end

	local function calcScale()
		local sz = gui.AbsoluteSize
		local base = math.min(1, (sz.Y - 20) / BASEH, (sz.X - 20) / BASEW)
		return math.max(0.5, base * cfg.scale)
	end
	local win = new("Frame", {BackgroundColor3 = T.bg, BorderSizePixel = 0, ClipsDescendants = true, Active = true}, gui)
	corner(win, 16)
	local winStroke = new("UIStroke", {Thickness = 1.5, Transparency = 0.45}, win)
	bindAcc(function() winStroke.Color = T.acc end)
	local root = new("Frame", {Size = UDim2.fromOffset(BASEW, BASEH), BackgroundTransparency = 1}, win)
	local uiscale = new("UIScale", {}, root)
	local function layoutWin()
		local s = calcScale()
		uiscale.Scale = s
		win.Size = UDim2.fromOffset(math.floor(BASEW * s), math.floor(BASEH * s))
	end
	layoutWin()
	win.Position = UDim2.new(1, -(win.Size.X.Offset + 14), 0.5, -math.floor(win.Size.Y.Offset / 2))
	track(gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutWin))

	local strip = new("Frame", {Size = UDim2.new(1, -32, 0, 3), Position = UDim2.fromOffset(16, 0), BorderSizePixel = 0, BackgroundColor3 = T.acc}, root)
	corner(strip, 2)
	local grad = new("UIGradient", {}, strip)
	bindAcc(function() grad.Color = ColorSequence.new(T.acc, T.acc:Lerp(Color3.new(1, 1, 1), 0.45)) end)

	-- ส่วนหัว (ลากหน้าต่างได้จากตรงนี้)
	local head = new("Frame", {Size = UDim2.new(1, -100, 0, 58), BackgroundTransparency = 1, Active = true}, root)
	lbl(head, {Size = UDim2.new(1, -16, 0, 26), Position = UDim2.fromOffset(16, 10), Text = "🎵 Quiz QoL", Font = Enum.Font.GothamBold, TextSize = 19})
	R.status = lbl(head, {Size = UDim2.new(1, -16, 0, 16), Position = UDim2.fromOffset(16, 36), Text = "กำลังเริ่ม...", TextColor3 = T.sub, TextSize = 11})
	local function topBtn(txt, x, col, cb)
		return mkbtn(root, {Size = UDim2.fromOffset(34, 30), Position = UDim2.new(1, x, 0, 12), Text = txt, BackgroundColor3 = col, TextSize = 14}, cb)
	end

	local minimized = false
	local orb = new("TextButton", {Size = UDim2.fromOffset(50, 50), Position = UDim2.new(1, -70, 0, 80), Text = "🎵", TextSize = 24,
		TextColor3 = T.text, Visible = false, AutoButtonColor = false, BorderSizePixel = 0, Active = true}, gui)
	corner(orb, 25)
	new("UIStroke", {Color = T.text, Transparency = 0.7, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, orb)
	bindAcc(function() orb.BackgroundColor3 = T.acc end)
	local function setMin(v) minimized = v; win.Visible = not v; orb.Visible = v end

	local function unload()
		Q.alive = false
		for _, c in ipairs(Q.conns) do pcall(function() c:Disconnect() end) end
		for _, f in ipairs(Q.cleanups) do pcall(f) end
		F.stopPractice()
		pcall(function() gui:Destroy() end)
		if G.QUIZQOL_UNLOAD == unload then G.QUIZQOL_UNLOAD = nil end
		if G.QQ == Q then G.QQ = nil end
	end
	G.QUIZQOL_UNLOAD = unload
	topBtn("–", -86, T.btn, function() setMin(true) end)
	topBtn("✕", -46, T.badBtn, unload)

	local function makeDrag(handle, target, onTap)
		local dragging, startIn, startPos, moved = false, nil, nil, 0
		local function isPress(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
		track(handle.InputBegan:Connect(function(i)
			if isPress(i) then dragging = true; startIn = i.Position; startPos = target.Position; moved = 0 end
		end))
		track(Svc.UserInputService.InputChanged:Connect(function(i)
			if dragging and startIn and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				local d = i.Position - startIn
				moved = math.max(moved, math.abs(d.X) + math.abs(d.Y))
				target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end))
		track(Svc.UserInputService.InputEnded:Connect(function(i)
			if dragging and isPress(i) then
				dragging = false
				if onTap and moved < 8 then onTap() end
			end
		end))
	end
	makeDrag(head, win)
	makeDrag(orb, orb, function() setMin(false) end)
	track(Svc.UserInputService.InputBegan:Connect(function(i, gp)
		if not gp and i.KeyCode == Enum.KeyCode.RightShift then setMin(not minimized) end
	end))

	-- ===== แท็บและหน้า =====
	local pages, tabBtns, curTab = {}, {}, "play"
	local tabBar = new("Frame", {Size = UDim2.new(1, -24, 0, 36), Position = UDim2.fromOffset(12, 60), BackgroundColor3 = T.card}, root)
	corner(tabBar, 12)
	local function selectTab(id)
		curTab = id
		for k, p in pairs(pages) do p.Visible = (k == id) end
		for k, b in pairs(tabBtns) do b.BackgroundColor3 = (k == id) and T.acc or T.card end
	end
	bindAcc(function() selectTab(curTab) end)
	F.selectTab = selectTab
	local function addPage(id, label, idx, n)
		local b = new("TextButton", {Size = UDim2.new(1 / n, -6, 1, -6), Position = UDim2.new((idx - 1) / n, 3, 0, 3), BackgroundColor3 = T.card,
			AutoButtonColor = false, Text = label, TextColor3 = T.text, Font = Enum.Font.GothamBold, TextSize = 12, BorderSizePixel = 0}, tabBar)
		corner(b, 10)
		local p = new("ScrollingFrame", {Size = UDim2.new(1, -20, 1, -108), Position = UDim2.fromOffset(10, 102), BackgroundTransparency = 1,
			BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false,
			ScrollingDirection = Enum.ScrollingDirection.Y}, root)
		new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, p)
		new("Frame", {Size = UDim2.new(1, 0, 0, 10), BackgroundTransparency = 1, LayoutOrder = 1000000}, p)
		pages[id], tabBtns[id] = p, b
		b.MouseButton1Click:Connect(function() selectTab(id) end)
		return p
	end
	local pagePlay = addPage("play", "🎵 เล่น", 1, 4)
	local pageBook = addPage("book", "📒 สมุด", 2, 4)
	local pageDrill = addPage("drill", "🎯 ทบทวน", 3, 4)
	local pageSet = addPage("set", "⚙ ตั้งค่า", 4, 4)
	selectTab("play")

	-- ===== ชิ้นส่วน UI (วางลงหน้าที่อยู่ใน Q.curPage) =====
	local function section(txt)
		local l = lbl(Q.curPage, {Size = UDim2.new(1, -6, 0, 20), Text = txt, Font = Enum.Font.GothamBold, TextSize = 12})
		bindAcc(function() l.TextColor3 = T.acc end)
	end
	local function card()
		local f = new("Frame", {Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.card}, Q.curPage)
		corner(f, 12)
		pad(f, 10, 12, 10, 12)
		new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, f)
		return f
	end
	local function row(f, h) return new("Frame", {Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1}, f) end
	local function descLbl(f, desc)
		return lbl(f, {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = desc, TextColor3 = T.sub, TextSize = 11, TextWrapped = true})
	end
	local function listBox()
		local f = new("Frame", {Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, Q.curPage)
		new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, f)
		return f
	end
	local function bar(par, h)
		local b = new("Frame", {Size = UDim2.new(1, 0, 0, h or 8), BackgroundColor3 = T.btn, BorderSizePixel = 0}, par)
		corner(b, 4)
		local fill = new("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = T.acc, BorderSizePixel = 0}, b)
		corner(fill, 4)
		bindAcc(function() fill.BackgroundColor3 = T.acc end)
		return function(p, col)
			fill.Size = UDim2.new(math.clamp(p or 0, 0, 1), 0, 1, 0)
			fill.BackgroundColor3 = col or T.acc
		end
	end
	local function chips(labels)
		local f = new("Frame", {Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, Q.curPage)
		new("UIGridLayout", {CellSize = UDim2.new(1 / 3, -6, 0, 54), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder}, f)
		local setters = {}
		for i, name in ipairs(labels) do
			local c = new("Frame", {BackgroundColor3 = T.card, BorderSizePixel = 0}, f)
			corner(c, 12)
			local v = lbl(c, {Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 6), Text = "-", Font = Enum.Font.GothamBold, TextSize = 18,
				TextXAlignment = Enum.TextXAlignment.Center})
			bindAcc(function() v.TextColor3 = T.acc end)
			lbl(c, {Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 34), Text = name, TextColor3 = T.sub, TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Center})
			setters[i] = function(t) v.Text = tostring(t) end
		end
		return setters
	end
	local function toggleRow(titleText, desc, key, default, cb)
		local f = card()
		local top = row(f, 26)
		lbl(top, {Size = UDim2.new(1, -60, 1, 0), Text = titleText, Font = Enum.Font.GothamBold, TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd})
		local sw = new("TextButton", {Size = UDim2.fromOffset(46, 26), Position = UDim2.new(1, -46, 0.5, -13), AutoButtonColor = false, Text = "",
			BorderSizePixel = 0}, top)
		corner(sw, 13)
		local knob = new("Frame", {Size = UDim2.fromOffset(20, 20), BackgroundColor3 = T.text, BorderSizePixel = 0}, sw)
		corner(knob, 10)
		local state = default
		if key and type(cfg[key]) == "boolean" then state = cfg[key] end
		local function paint(animate)
			local pos = state and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
			local col = state and T.acc or T.btn
			if animate then tween(knob, {Position = pos}); tween(sw, {BackgroundColor3 = col})
			else knob.Position = pos; sw.BackgroundColor3 = col end
		end
		sw.MouseButton1Click:Connect(function()
			state = not state
			if key then cfg[key] = state; saveCfg() end
			paint(true)
			if cb then task.spawn(cb, state) end
		end)
		bindAcc(function() paint(false) end)
		if desc then descLbl(f, desc) end
	end
	local function stepperRow(titleText, desc, key, min, max, step, default, cb, fmt)
		local f = card()
		local top = row(f, 28)
		lbl(top, {Size = UDim2.new(1, -140, 1, 0), Text = titleText, Font = Enum.Font.GothamBold, TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd})
		local val = (key and type(cfg[key]) == "number") and cfg[key] or default
		local function show() return fmt and fmt(val) or tostring(val) end
		local vl = lbl(top, {Size = UDim2.fromOffset(62, 28), Position = UDim2.new(1, -94, 0, 0), Text = show(), Font = Enum.Font.GothamBold, TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Center})
		bindAcc(function() vl.TextColor3 = T.acc end)
		local function mk(txt, x, d)
			mkbtn(top, {Size = UDim2.fromOffset(30, 28), Position = UDim2.new(1, x, 0, 0), Text = txt, TextSize = 16}, function()
				val = math.clamp(math.floor((val + d * step) * 100 + 0.5) / 100, min, max)
				vl.Text = show()
				if key then cfg[key] = val; saveCfg() end
				if cb then cb(val) end
			end)
		end
		mk("−", -126, -1); mk("+", -30, 1)
		if desc then descLbl(f, desc) end
	end
	local function buttonRow(titleText, desc, label, cb, col)
		local f = card()
		local top = row(f, 30)
		lbl(top, {Size = UDim2.new(1, -135, 1, 0), Text = titleText, Font = Enum.Font.GothamBold, TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd})
		local b = mkbtn(top, {Size = UDim2.fromOffset(122, 30), Position = UDim2.new(1, -122, 0, 0), Text = label, BackgroundColor3 = col or T.acc}, cb)
		if not col then bindAcc(function() b.BackgroundColor3 = T.acc end) end
		if desc then descLbl(f, desc) end
		return b
	end
	local function segmented(titleText, options, key, cb)
		local f = card()
		lbl(f, {Size = UDim2.new(1, 0, 0, 18), Text = titleText, Font = Enum.Font.GothamBold, TextSize = 13})
		local rf = row(f, 32)
		local btns, n = {}, #options
		local function paint()
			for i, o in ipairs(options) do btns[i].BackgroundColor3 = (cfg[key] == o[1]) and T.acc or T.btn end
		end
		for i, o in ipairs(options) do
			btns[i] = mkbtn(rf, {Size = UDim2.new(1 / n, -6, 1, 0), Position = UDim2.new((i - 1) / n, 3, 0, 0), Text = o[2], TextSize = 12}, function()
				cfg[key] = o[1]; saveCfg(); paint()
				if cb then cb(o[1]) end
			end)
		end
		bindAcc(paint)
	end
	local function rowIn(parent, line1, line2, btns, tint)
		local r = new("Frame", {Size = UDim2.new(1, 0, 0, 54), BackgroundColor3 = T.card, BorderSizePixel = 0}, parent)
		corner(r, 10)
		if tint then new("Frame", {Size = UDim2.new(0, 3, 1, -16), Position = UDim2.fromOffset(0, 8), BackgroundColor3 = tint, BorderSizePixel = 0}, r) end
		local w = 8
		for _, bd in ipairs(btns) do w = w + (bd.w or 54) + 6 end
		lbl(r, {Size = UDim2.new(1, -w - 16, 0, 22), Position = UDim2.fromOffset(12, 6), Text = line1, Font = Enum.Font.GothamBold, TextSize = 13,
			TextTruncate = Enum.TextTruncate.AtEnd})
		lbl(r, {Size = UDim2.new(1, -w - 16, 0, 18), Position = UDim2.fromOffset(12, 29), Text = line2 or "", TextColor3 = T.sub, TextSize = 11,
			TextTruncate = Enum.TextTruncate.AtEnd})
		local x = -8
		for i = #btns, 1, -1 do
			local bd = btns[i]
			local bw = bd.w or 54
			mkbtn(r, {Size = UDim2.fromOffset(bw, 30), Position = UDim2.new(1, x - bw, 0.5, -15), Text = bd.text, BackgroundColor3 = bd.color or T.btn,
				TextSize = 12}, bd.cb)
			x = x - bw - 6
		end
	end

	-- ส่งออกให้ไฟล์ถัดไป
	Q.gui, Q.win, Q.root = gui, win, root
	Q.layoutWin, Q.makeDrag = layoutWin, makeDrag
	Q.pagePlay, Q.pageBook, Q.pageDrill, Q.pageSet = pagePlay, pageBook, pageDrill, pageSet
	Q.section, Q.card, Q.row, Q.descLbl, Q.listBox = section, card, row, descLbl, listBox
	Q.bar, Q.chips, Q.toggleRow, Q.stepperRow = bar, chips, toggleRow, stepperRow
	Q.buttonRow, Q.segmented, Q.rowIn = buttonRow, segmented, rowIn

	Q.stage = 2
	notify("✅ ไฟล์ 2/5 เรียบร้อย รันไฟล์ 3 ต่อได้เลย", 5)
end

local ok, err = xpcall(part2, function(e) return tostring(e) .. "\n" .. ((debug and debug.traceback) and debug.traceback("", 2) or "") end)
if not ok then Q.fatal(err) end
