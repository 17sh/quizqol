--[[
	Quiz QoL v3.0 | ไฟล์ 5/5: หน้าตั้งค่า วงจรเบื้องหลัง และเปิดเมนู
	ต้องรันไฟล์ 1-4 เสร็จก่อน รันไฟล์นี้เสร็จแล้วเมนูจะขึ้นบนจอ
]]
local G = (getgenv and getgenv()) or _G
local Q = G.QQ
local N = 5
local function say(msg)
	print("[QuizQoL] " .. msg)
	pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Quiz QoL", Text = msg, Duration = 8}) end)
end
if not Q then say("ต้องรันไฟล์ 1 ก่อน"); return end
if Q.stage ~= N - 1 then
	say(Q.stage < N - 1 and ("ต้องรันไฟล์ " .. (Q.stage + 1) .. " ก่อน") or ("ไฟล์ " .. N .. " รันไปแล้ว ถ้าจะเริ่มใหม่ให้รันไฟล์ 1 อีกครั้ง"))
	return
end

local function part5()
	local Svc, LP, cfg, T, ACCENTS, bindAcc, setAccent = Q.Svc, Q.LP, Q.cfg, Q.T, Q.ACCENTS, Q.bindAcc, Q.setAccent
	local new, corner, lbl, mkbtn, clearBox = Q.new, Q.corner, Q.lbl, Q.mkbtn, Q.clearBox
	local track, onCleanup, F, R, notify = Q.track, Q.onCleanup, Q.F, Q.R, Q.notify
	local section, card, row, descLbl, listBox = Q.section, Q.card, Q.row, Q.descLbl, Q.listBox
	local chips, toggleRow, stepperRow, buttonRow, rowIn = Q.chips, Q.toggleRow, Q.stepperRow, Q.buttonRow, Q.rowIn
	local book, soundSet = Q.book, Q.soundSet
	local fpOf, shortId, pickSound, onSong = Q.fpOf, Q.shortId, Q.pickSound, Q.onSong
	local copy, rejoin, serverHop = Q.copy, Q.rejoin, Q.serverHop
	local VERSION, canFile, defaults, saveCfg, layoutWin = Q.VERSION, Q.canFile, Q.defaults, Q.saveCfg, Q.layoutWin

	-- ============================================================
	-- หน้า: ตั้งค่า
	-- ============================================================
	Q.curPage = Q.pageSet
	section("สถานะเครื่อง")
	R.sys = chips({"FPS", "Ping", "ผู้เล่นในห้อง", "หน่วยความจำ", "เวลาที่เล่นมา", "เพลงในสมุด"})

	section("กันหลุดและกันเตะ")
	toggleRow("Anti-AFK", "กันถูกเตะเมื่อไม่ได้แตะจอนาน เปิดค้างไว้ได้เลยตอนรอในล็อบบี้", "antiAfk", true)
	track(LP.Idled:Connect(function()
		if cfg.antiAfk then pcall(function() local VU = Svc.VirtualUser; VU:CaptureController(); VU:ClickButton2(Vector2.new()) end) end
	end))
	toggleRow("รีจอยน์อัตโนมัติเมื่อหลุด", "ถ้าถูกเตะหรือสัญญาณหลุด ระบบจะพากลับเข้าเกมนี้ให้เอง", "autoRejoin", false)
	pcall(function()
		track(Svc.GuiService.ErrorMessageChanged:Connect(function(msg)
			if cfg.autoRejoin and msg and msg ~= "" then task.wait(2); rejoin() end
		end))
	end)
	task.spawn(function()
		pcall(function()
			local po = Svc.CoreGui:WaitForChild("RobloxPromptGui", 10):WaitForChild("promptOverlay", 10)
			track(po.ChildAdded:Connect(function(c)
				if cfg.autoRejoin and c.Name == "ErrorPrompt" then task.wait(2); rejoin() end
			end))
		end)
	end)

	section("ประหยัดเครื่อง")
	local r3d = false
	toggleRow("ปิดการแสดงผล 3D", "ประหยัดแบตและลดความร้อน หน้าจอเกมจะดำ อย่าเปิดตอนแข่ง", nil, false, function(v)
		r3d = v
		pcall(function() Svc.RunService:Set3dRenderingEnabled(not v) end)
	end)
	onCleanup(function() if r3d then pcall(function() Svc.RunService:Set3dRenderingEnabled(true) end) end end)
	if setfpscap then
		stepperRow("จำกัด FPS", "ลดแล้วเครื่องเย็นลง (0 = ไม่จำกัด) แนะนำ 30-60", nil, 0, 120, 10, 0, function(v) pcall(setfpscap, v) end)
		onCleanup(function() pcall(setfpscap, 0) end)
	end
	toggleRow("ปิดเอฟเฟกต์ในฉาก", "ปิดพาร์ติเคิล เทรล แสงวิบวับ ช่วยให้ลื่นขึ้น (กลับมาเมื่อรีจอยน์)", nil, false, function(v)
		if not v then return end
		task.spawn(function()
			local n = 0
			for _, d in ipairs(workspace:GetDescendants()) do
				if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") then
					pcall(function() d.Enabled = false end)
				end
				n = n + 1
				if n % 300 == 0 then task.wait() end
			end
			notify("ปิดเอฟเฟกต์แล้ว", 3)
		end)
	end)
	local gfx = {q = nil, shadow = nil}
	toggleRow("กราฟิกต่ำสุด", "ลดคุณภาพภาพให้เบาที่สุด ปิดแล้วจะคืนค่าเดิม", nil, false, function(v)
		pcall(function()
			local r = settings().Rendering
			if v then gfx.q = gfx.q or r.QualityLevel; r.QualityLevel = Enum.QualityLevel.Level01
			elseif gfx.q then r.QualityLevel = gfx.q end
		end)
	end)
	toggleRow("ปิดเงาในฉาก", "ลดภาระการเรนเดอร์ ปิดแล้วจะคืนค่าเดิม", nil, false, function(v)
		pcall(function()
			local l = Svc.Lighting
			if v then if gfx.shadow == nil then gfx.shadow = l.GlobalShadows end; l.GlobalShadows = false
			elseif gfx.shadow ~= nil then l.GlobalShadows = gfx.shadow end
		end)
	end)
	onCleanup(function()
		pcall(function() if gfx.q then settings().Rendering.QualityLevel = gfx.q end end)
		pcall(function() if gfx.shadow ~= nil then Svc.Lighting.GlobalShadows = gfx.shadow end end)
	end)

	section("เซิร์ฟเวอร์")
	buttonRow("กลับเข้าเซิร์ฟเวอร์ใหม่", "รีจอยน์เกมนี้ (จะออกจากห้องที่อยู่ตอนนี้)", "รีจอยน์", rejoin, T.btn)
	buttonRow("ย้ายเซิร์ฟเวอร์", "ย้ายไปห้องอื่นที่มีผู้เล่น ใช้ไม่ได้กับห้องส่วนตัว", "ย้ายห้อง", serverHop)
	buttonRow("คัดลอก Job ID", "รหัสห้องปัจจุบัน ส่งให้เพื่อนหรือเก็บไว้", "คัดลอก", function() copy(tostring(game.JobId), "คัดลอก Job ID แล้ว") end, T.btn)

	section("หน้าตา")
	do
		local f = card()
		lbl(f, {Size = UDim2.new(1, 0, 0, 18), Text = "สีธีม", Font = Enum.Font.GothamBold, TextSize = 14})
		local rf = row(f, 36)
		for i, a in ipairs(ACCENTS) do
			local b = new("TextButton", {Size = UDim2.fromOffset(34, 34), Position = UDim2.new((i - 1) / #ACCENTS, 0, 0, 0), BackgroundColor3 = a[2],
				Text = "", BorderSizePixel = 0}, rf)
			corner(b, 17)
			local st = new("UIStroke", {Color = T.text, Thickness = 2, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, b)
			bindAcc(function() st.Transparency = (cfg.accent == a[1]) and 0 or 1 end)
			b.MouseButton1Click:Connect(function() setAccent(a[1]) end)
		end
	end
	stepperRow("ขนาดหน้าต่าง", "ปรับให้พอดีกับจอ (0.6x - 1.4x)", "scale", 0.6, 1.4, 0.1, 1, function() layoutWin() end, function(v) return string.format("%.1fx", v) end)
	local menuHidden = false
	toggleRow("ซ่อนเมนู Roblox", "ซ่อนปุ่มแชทและเมนูมุมบนให้จอโล่ง ปิดเพื่อเอากลับมา (ถ้าต้องออกเกมให้ปิดก่อน)", nil, false, function(v)
		menuHidden = v
		pcall(function() Svc.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, not v) end)
	end)
	onCleanup(function() if menuHidden then pcall(function() Svc.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end) end end)
	toggleRow("แจ้งเมื่อมีผู้เล่นเข้า/ออก", "เด้งข้อความชื่อผู้เล่นที่เข้าหรือออกห้อง", "joinAlert", false)
	track(Svc.Players.PlayerAdded:Connect(function(p) if cfg.joinAlert then notify(p.Name .. " เข้าห้อง", 3) end end))
	track(Svc.Players.PlayerRemoving:Connect(function(p) if cfg.joinAlert then notify(p.Name .. " ออกจากห้อง", 3) end end))

	section("ป้ายสรุปบนจอ")
	toggleRow("แสดงป้ายบนจอ", "ป้ายเล็กสรุปจากสมุดของคุณ ลากย้ายตำแหน่งได้ด้วยนิ้ว", "hud", true, function() F.applyHud() end)
	stepperRow("ขนาดตัวอักษรป้าย", nil, "hudSize", 11, 26, 1, 15, function() F.applyHud() end)
	stepperRow("ซ่อนป้ายอัตโนมัติ", "ซ่อนป้ายหลังขึ้นมาครบกี่วินาที (0 = ไม่ซ่อน)", "hudHide", 0, 60, 5, 0, nil, function(v) return v == 0 and "ไม่ซ่อน" or (v .. " วิ") end)

	section("ตัวตรวจจับเสียง")
	stepperRow("ความยาวเสียงขั้นต่ำ", "นับเฉพาะเสียงที่ยาวกว่านี้ (วินาที) ถ้าตรวจพลาดลองปรับ", "minLen", 1, 60, 1, 5, nil, function(v) return v .. " วิ" end)
	local pinLbl
	buttonRow("ล็อกเสียงที่ตรวจพบ", "ตรวจเฉพาะเสียงตัวนี้ ช่วยเมื่อมีเพลงพื้นหลังมารบกวน", "ล็อก", function()
		Q.pinPath = nil
		local s = pickSound()
		if s then Q.pinPath = s:GetFullName(); pinLbl.Text = "ล็อกอยู่: " .. s.Name; notify("ล็อกเสียงนี้แล้ว", 3)
		else notify("ยังไม่มีเสียงให้ล็อก รอให้เพลงเล่นก่อน", 3) end
	end)
	buttonRow("ปลดล็อกเสียง", nil, "ปลดล็อก", function() Q.pinPath = nil; pinLbl.Text = "ไม่ได้ล็อก (เลือกเสียงที่สั้นที่สุดอัตโนมัติ)"; notify("ปลดล็อกแล้ว", 3) end, T.btn)
	do
		local f = card()
		pinLbl = lbl(f, {Size = UDim2.new(1, 0, 0, 18), Text = "ไม่ได้ล็อก (เลือกเสียงที่สั้นที่สุดอัตโนมัติ)", TextColor3 = T.sub, TextSize = 12,
			TextTruncate = Enum.TextTruncate.AtEnd})
	end
	local sndBox
	buttonRow("ดูเสียงที่กำลังเล่น", "ใช้ตรวจว่าตัวตรวจจับเห็นเสียงอะไรบ้าง", "รีเฟรช", function()
		clearBox(sndBox)
		local n = 0
		for s in pairs(soundSet) do
			if s.Parent and s.IsPlaying then
				n = n + 1
				if n > 8 then break end
				local id = fpOf(s)
				rowIn(sndBox, s.Name .. " • " .. math.floor(s.TimeLength) .. " วิ • vol " .. string.format("%.1f", s.Volume),
					(id and shortId(id) or "-") .. " • " .. s:GetFullName(), {})
			end
		end
		if n == 0 then rowIn(sndBox, "ไม่มีเสียงที่เล่นอยู่", "", {}) end
	end, T.btn)
	sndBox = listBox()

	section("เกี่ยวกับ")
	do
		local f = card()
		lbl(f, {Size = UDim2.new(1, 0, 0, 20), Text = "Quiz QoL v" .. VERSION, Font = Enum.Font.GothamBold, TextSize = 14})
		descLbl(f, "สมุดจำเพลงส่วนตัว ข้อมูลมาจากที่คุณจดเองเท่านั้น • กดปุ่ม – เพื่อย่อเป็นไอคอน 🎵 (ลากย้ายได้) • บนคอมกด Right Shift เพื่อย่อ/ขยาย"
			.. (canFile and "" or "\n⚠ executor นี้บันทึกไฟล์ไม่ได้ สมุดและการตั้งค่าจะหายเมื่อปิดเกม"))
		mkbtn(f, {Size = UDim2.new(1, 0, 0, 30), Text = "รีเซ็ตการตั้งค่า (ไม่แตะสมุด)", TextSize = 12}, function()
			for k, v in pairs(defaults) do cfg[k] = v end
			saveCfg()
			notify("รีเซ็ตแล้ว รันสคริปใหม่เพื่อใช้ค่าเริ่มต้น", 5)
		end)
	end

	-- ============================================================
	-- วงจรทำงานเบื้องหลัง
	-- ============================================================
	local t0, frames, accDt = os.clock(), 0, 0
	track(Svc.RunService.RenderStepped:Connect(function(dt) frames = frames + 1; accDt = accDt + dt end))
	task.spawn(function()
		while Q.alive do
			task.wait(1)
			pcall(function()
				local fps = accDt > 0 and math.floor(frames / accDt + 0.5) or 0
				frames, accDt = 0, 0
				local ping, mem = 0, 0
				pcall(function() ping = math.floor(Svc.Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
				pcall(function() mem = math.floor(Svc.Stats:GetTotalMemoryUsageMb()) end)
				local np = #Svc.Players:GetPlayers()
				R.status.Text = "FPS " .. fps .. "  •  " .. ping .. " ms  •  " .. np .. " คน"
				local s = math.floor(os.clock() - t0)
				local cnt = 0
				for _ in pairs(book) do cnt = cnt + 1 end
				R.sys[1](fps); R.sys[2](ping .. " ms"); R.sys[3](np); R.sys[4](mem .. " MB")
				R.sys[5](string.format("%d:%02d:%02d", math.floor(s / 3600), math.floor(s % 3600 / 60), s % 60))
				R.sys[6](cnt)
			end)
		end
	end)
	local lastFp, lastPos = nil, 0
	task.spawn(function()
		while Q.alive do
			task.wait(0.4)
			pcall(function()
				local s = pickSound()
				if not s then
					lastFp = nil
					R.now("ยังไม่พบเสียงเพลง"); R.bar(0)
					return
				end
				local fp, pos, len = fpOf(s), s.TimePosition, s.TimeLength
				local isNew = (fp ~= lastFp) or (pos + 2 < lastPos)
				lastFp, lastPos = fp, pos
				R.now(shortId(fp) .. " • " .. math.floor(len) .. " วิ")
				R.bar(len > 0 and pos / len or 0)
				if isNew then onSong(fp, s) end
			end)
		end
	end)
	-- ถ้าเกมลบ UI ของเรา จะวางกลับให้เอง
	task.spawn(function()
		while Q.alive do
			task.wait(2)
			if not Q.gui.Parent then Q.mountGui(Q.gui) end
		end
	end)

	-- ===== เปิดเมนู =====
	F.refreshHist(); F.refreshBook(); Q.updSess(); F.applyHud()
	Q.gui.Enabled = true
	Q.stage = 5
	notify("พร้อมใช้งาน 🎵 กดปุ่ม – เพื่อย่อเป็นไอคอน", 4)
end

local ok, err = xpcall(part5, function(e) return tostring(e) .. "\n" .. ((debug and debug.traceback) and debug.traceback("", 2) or "") end)
if not ok then Q.fatal(err) end
