--[[
	Quiz QoL v3.0 | ไฟล์ 4/5: หน้าเมนู 🎵 เล่น / 📒 สมุด / 🎯 ทบทวน
	ต้องรันไฟล์ 1-3 เสร็จก่อน
]]
local G = (getgenv and getgenv()) or _G
local Q = G.QQ
local N = 4
local function say(msg)
	print("[QuizQoL] " .. msg)
	pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Quiz QoL", Text = msg, Duration = 8}) end)
end
if not Q then say("ต้องรันไฟล์ 1 ก่อน"); return end
if Q.stage ~= N - 1 then
	say(Q.stage < N - 1 and ("ต้องรันไฟล์ " .. (Q.stage + 1) .. " ก่อน") or ("ไฟล์ " .. N .. " รันไปแล้ว ถ้าจะเริ่มใหม่ให้รันไฟล์ 1 อีกครั้ง"))
	return
end

local function part4()
	local Svc, cfg, T, KIND, bindAcc = Q.Svc, Q.cfg, Q.T, Q.KIND, Q.bindAcc
	local lbl, mkbtn, textbox, clearBox, new, corner = Q.lbl, Q.mkbtn, Q.textbox, Q.clearBox, Q.new, Q.corner
	local getclip = getclipboard or get_clipboard
	local track, F, R, notify = Q.track, Q.F, Q.R, Q.notify
	local section, card, row, descLbl, listBox = Q.section, Q.card, Q.row, Q.descLbl, Q.listBox
	local bar, chips, buttonRow, segmented, rowIn = Q.bar, Q.chips, Q.buttonRow, Q.segmented, Q.rowIn
	local book, saveBook, shortId = Q.book, Q.saveBook, Q.shortId
	local sess, history = Q.sess, Q.history
	local updSess, record, toggleStar, selectFp = Q.updSess, Q.record, Q.toggleStar, Q.selectFp
	local startDrill, playClip, checkAns, revealAns, nextQ = Q.startDrill, Q.playClip, Q.checkAns, Q.revealAns, Q.nextQ
	local copy, exportText, importBook = Q.copy, Q.exportText, Q.importBook

	-- ============================================================
	-- หน้า: เล่น
	-- ============================================================
	Q.curPage = Q.pagePlay
	section("เพลงที่ตรวจพบ")
	do
		local f = card()
		local top = row(f, 26)
		local nowL = lbl(top, {Size = UDim2.new(1, 0, 1, 0), Text = "ยังไม่พบเสียงเพลง", Font = Enum.Font.GothamBold, TextSize = 16})
		R.now = function(t) nowL.Text = t end
		R.bar = bar(f, 8)
		local bl = lbl(f, {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = "เริ่มรอบแล้วระบบจะตรวจให้เอง", TextWrapped = true, TextSize = 13})
		R.banner = function(t, kind) bl.Text = t; bl.TextColor3 = KIND[kind] or T.text end
	end

	section("เทียบกับครั้งก่อน")
	do
		local f = card()
		local tag = lbl(f, {Size = UDim2.new(1, 0, 0, 20), Text = "รอเพลง...", Font = Enum.Font.GothamBold, TextSize = 13})
		local cols = row(f, 96)
		local function col(x, head)
			local c = new("Frame", {Size = UDim2.new(0.5, -4, 1, 0), Position = UDim2.new(x, x == 0 and 0 or 4, 0, 0), BackgroundColor3 = T.card2, BorderSizePixel = 0}, cols)
			corner(c, 8)
			lbl(c, {Size = UDim2.new(1, -16, 0, 18), Position = UDim2.fromOffset(8, 4), Text = head, TextColor3 = T.sub, TextSize = 11})
			return lbl(c, {Size = UDim2.new(1, -16, 1, -26), Position = UDim2.fromOffset(8, 22), Text = "-", TextSize = 12, TextWrapped = true,
				TextYAlignment = Enum.TextYAlignment.Top})
		end
		local nowT, prevT = col(0, "🎵 ตอนนี้"), col(0.5, "🕘 ครั้งก่อน")
		R.cmp = function(a, b, isNew)
			nowT.Text = a; prevT.Text = b
			tag.Text = isNew and "🆕 เพลงใหม่ ไม่เคยขึ้นมาก่อน" or "🔁 เคยขึ้นมาแล้ว"
			tag.TextColor3 = isNew and T.info or T.warn
		end
	end

	section("จดเพลงนี้")
	do
		local f = card()
		local tl = lbl(f, {Size = UDim2.new(1, 0, 0, 18), Text = "กำลังจดให้: -", TextColor3 = T.sub, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd})
		R.titleBox = textbox(f, "พิมพ์ชื่อตามที่เกมเฉลย แล้วกด Enter เพื่อบันทึก")
		local sug = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, f)
		new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, sug)
		local function showSug()
			clearBox(sug)
			local q = R.titleBox.Text:lower()
			if q == "" then return end
			local seen, n = {}, 0
			for _, e in pairs(book) do
				local t = type(e) == "table" and e.title or ""
				if t ~= "" and not seen[t] and t:lower() ~= q and t:lower():find(q, 1, true) then
					seen[t] = true; n = n + 1
					if n > 4 then break end
					mkbtn(sug, {Size = UDim2.new(1, 0, 0, 28), Text = "💡 " .. t, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, function()
						R.titleBox.Text = t
					end)
				end
			end
		end
		track(R.titleBox:GetPropertyChangedSignal("Text"):Connect(showSug))
		track(R.titleBox.FocusLost:Connect(function(enter) if enter then record("note") end end))
		R.noteBox = textbox(f, "โน้ตของคุณ (ไม่บังคับ) เช่น ท่อนแรกคล้ายอีกเพลง")
		local r1 = row(f, 40)
		mkbtn(r1, {Size = UDim2.new(0.5, -4, 1, 0), Text = "✔ ตอบถูก", BackgroundColor3 = T.goodBtn, TextSize = 14}, function() record("right") end)
		mkbtn(r1, {Size = UDim2.new(0.5, -4, 1, 0), Position = UDim2.new(0.5, 4, 0, 0), Text = "✘ ตอบผิด", BackgroundColor3 = T.badBtn, TextSize = 14}, function() record("wrong") end)
		local r2 = row(f, 34)
		mkbtn(r2, {Size = UDim2.new(0.5, -4, 1, 0), Text = "💾 บันทึกโน้ต/ชื่อ"}, function() record("note") end)
		local sb = mkbtn(r2, {Size = UDim2.new(0.5, -4, 1, 0), Position = UDim2.new(0.5, 4, 0, 0), Text = "☆ ติดดาว"}, toggleStar)
		if getclip then
			mkbtn(f, {Size = UDim2.new(1, 0, 0, 30), Text = "📋 วางชื่อจากคลิปบอร์ด แล้วบันทึก", TextSize = 12}, function()
				local ok, txt = pcall(getclip)
				if ok and type(txt) == "string" and txt ~= "" then
					R.titleBox.Text = txt:gsub("^%s+", ""):gsub("%s+$", ""):sub(1, 120)
					record("note")
				else notify("คลิปบอร์ดว่างหรืออ่านไม่ได้", 3) end
			end)
		end
		R.target = function(fp)
			local e = book[fp]
			tl.Text = "กำลังจดให้: " .. shortId(fp) .. ((e and e.title and e.title ~= "") and (" • " .. e.title) or "")
			sb.Text = (e and e.star) and "★ เลิกติดดาว" or "☆ ติดดาว"
		end
		R.fill = function(t, n) R.titleBox.Text = t or ""; R.noteBox.Text = n or "" end
		descLbl(f, "เพลงที่เคยตอบผิดแล้วกลับมาอีก ป้ายบนจอจะขึ้นเตือนด้วยสีเหลือง")
	end

	section("สถิติรอบนี้")
	R.sess = chips({"ถูก", "ผิด", "สตรีค 🔥"})
	do
		local f = card()
		R.accBar = bar(f, 10)
		R.accLbl = lbl(f, {Size = UDim2.new(1, 0, 0, 18), Text = "", TextColor3 = T.sub, TextSize = 12})
		mkbtn(f, {Size = UDim2.new(1, 0, 0, 30), Text = "รีเซ็ตสถิติรอบนี้", TextSize = 12}, function()
			sess.right, sess.wrong, sess.streak, sess.best = 0, 0, 0, 0
			updSess()
		end)
	end

	section("เพลงที่เจอรอบนี้ (30 ล่าสุด)")
	local histBox = listBox()
	F.refreshHist = function()
		clearBox(histBox)
		if #history == 0 then rowIn(histBox, "ยังไม่มีเพลง", "รอให้เพลงในเกมเล่นก่อน", {}); return end
		for _, h in ipairs(history) do
			local e = book[h.fp]
			local ttl = (e and e.title and e.title ~= "") and e.title or nil
			rowIn(histBox, shortId(h.fp) .. " • " .. h.len .. " วิ" .. (ttl and (" • " .. ttl) or ""),
				(h.again and "🔁 เคยขึ้นแล้ว" or "🆕 ใหม่") .. " • " .. (ttl and "มีชื่อแล้ว" or "ยังไม่ได้ตั้งชื่อ") .. " • " .. os.date("%H:%M:%S", h.t),
				{{text = "ตั้งชื่อ", w = 62, cb = function() selectFp(h.fp); notify("เลือกแล้ว พิมพ์ชื่อด้านบนแล้วกดบันทึก", 3) end}},
				ttl and ((e.wrong or 0) > (e.right or 0) and T.warn or T.good) or T.info)
		end
	end

	-- ============================================================
	-- หน้า: สมุด
	-- ============================================================
	Q.curPage = Q.pageBook
	section("ภาพรวมสมุด")
	R.bookChips = chips({"เพลงในสมุด", "ถูกรวม", "ผิดรวม"})
	section("ค้นหา / กรอง")
	do
		local f = card()
		R.search = textbox(f, "🔍 ค้นหาชื่อหรือโน้ต")
		track(R.search:GetPropertyChangedSignal("Text"):Connect(function() F.refreshBook() end))
	end
	segmented("แสดง", {{"all", "ทั้งหมด"}, {"wrong", "เคยผิด"}, {"star", "★ ดาว"}, {"noname", "ไม่มีชื่อ"}}, "filter", function() F.refreshBook() end)
	segmented("เรียงตาม", {{"recent", "ล่าสุด"}, {"wrong", "ผิดมาก"}, {"name", "ชื่อ"}}, "sort", function() F.refreshBook() end)
	section("รายการ")
	local bookBox = listBox()
	F.refreshBook = function()
		clearBox(bookBox)
		local q = (R.search and R.search.Text or ""):lower()
		local arr, tr, tw, total = {}, 0, 0, 0
		for fp, e in pairs(book) do
			if type(e) == "table" then
				total = total + 1; tr = tr + (e.right or 0); tw = tw + (e.wrong or 0)
				local ok = true
				if cfg.filter == "wrong" then ok = (e.wrong or 0) > 0
				elseif cfg.filter == "star" then ok = e.star and true or false
				elseif cfg.filter == "noname" then ok = (e.title or "") == "" end
				if ok and q ~= "" then
					ok = ((e.title or "") .. " " .. (e.note or "") .. " " .. fp):lower():find(q, 1, true) ~= nil
				end
				if ok then arr[#arr + 1] = {fp = fp, e = e} end
			end
		end
		if R.bookChips then R.bookChips[1](total); R.bookChips[2](tr); R.bookChips[3](tw) end
		table.sort(arr, function(a, b)
			local x, y
			if cfg.sort == "wrong" then x, y = a.e.wrong or 0, b.e.wrong or 0
			elseif cfg.sort == "name" then
				x, y = tostring(a.e.title or ""):lower(), tostring(b.e.title or ""):lower()
				if x ~= y then return x < y end
				return a.fp < b.fp
			else x, y = a.e.last or a.e.seen or 0, b.e.last or b.e.seen or 0 end
			if x ~= y then return x > y end
			return a.fp < b.fp
		end)
		if #arr == 0 then
			rowIn(bookBox, total == 0 and "สมุดยังว่างอยู่" or "ไม่พบรายการที่ตรงเงื่อนไข", total == 0 and "จดเพลงในแท็บ 🎵 เล่น แล้วจะแสดงตรงนี้" or "ลองเปลี่ยนตัวกรองหรือคำค้นหา", {})
			return
		end
		for i, it in ipairs(arr) do
			if i > 60 then
				lbl(bookBox, {Size = UDim2.new(1, 0, 0, 22), Text = "แสดง 60 จาก " .. #arr .. " รายการ ใช้ช่องค้นหาเพื่อกรอง", TextColor3 = T.sub, TextSize = 11})
				break
			end
			local e, fp = it.e, it.fp
			rowIn(bookBox, (e.star and "★ " or "") .. ((e.title and e.title ~= "") and e.title or "(ยังไม่ได้ระบุชื่อ)"),
				shortId(fp) .. " • ถูก " .. (e.right or 0) .. " ผิด " .. (e.wrong or 0) .. " • เจอ " .. (e.plays or 0) .. " ครั้ง",
				{
					{text = "แก้", w = 44, cb = function() selectFp(fp); F.selectTab("play"); notify("โหลดขึ้นช่องกรอกแล้ว", 3) end},
					{text = e.star and "★" or "☆", w = 38, cb = function() e.star = not e.star; saveBook(); F.refreshBook() end},
					{text = "ลบ", w = 44, color = T.badBtn, cb = function() book[fp] = nil; saveBook(); F.refreshBook(); F.refreshHist() end},
				}, (e.wrong or 0) > (e.right or 0) and T.warn or nil)
		end
	end

	section("สำรองข้อมูล / นำเข้า")
	buttonRow("คัดลอกสมุด (JSON)", "เก็บไว้เป็นไฟล์สำรอง หรือย้ายไปเครื่องอื่น", "คัดลอก", function()
		copy(Svc.HttpService:JSONEncode(book), "คัดลอกสมุดแล้ว")
	end)
	buttonRow("คัดลอกเป็นรายชื่อ", "ได้ข้อความอ่านง่าย ชื่อ | รหัส | ถูก/ผิด | โน้ต", "คัดลอก", exportText, T.btn)
	local importBox
	do
		local f = card()
		lbl(f, {Size = UDim2.new(1, 0, 0, 18), Text = "นำเข้าสมุด", Font = Enum.Font.GothamBold, TextSize = 13})
		importBox = textbox(f, "วางข้อความ JSON ที่คัดลอกไว้ตรงนี้")
		local b = mkbtn(f, {Size = UDim2.new(1, 0, 0, 32), Text = "นำเข้า (รวมกับของเดิม)"}, function()
			if importBox.Text ~= "" then importBook(importBox.Text); importBox.Text = "" end
		end)
		bindAcc(function() b.BackgroundColor3 = T.acc end)
	end
	local armed = false
	buttonRow("ล้างสมุดทั้งหมด", "กดสองครั้งภายใน 5 วินาทีเพื่อยืนยัน ข้อมูลจะหายถาวร", "ล้างสมุด", function(b)
		if armed then
			armed = false
			for k in pairs(book) do book[k] = nil end
			saveBook()
			b.Text = "ล้างสมุด"
			F.refreshBook(); F.refreshHist()
			notify("ล้างสมุดแล้ว", 3)
		else
			armed = true
			b.Text = "กดอีกครั้ง"
			task.delay(5, function() armed = false; if b.Parent then b.Text = "ล้างสมุด" end end)
		end
	end, T.badBtn)

	-- ============================================================
	-- หน้า: ทบทวน
	-- ============================================================
	Q.curPage = Q.pageDrill
	section("ทบทวนจากสมุดของคุณ")
	do
		local f = card()
		descLbl(f, "ฟังคลิปสุ่มจากเพลงที่คุณจดชื่อไว้ แล้วพิมพ์ตอบเพื่อฝึกจำ ตรวจจากชื่อที่คุณจดเองเท่านั้น แนะนำให้ฝึกตอนรอรอบหรือหลังจบเกม")
	end
	segmented("ชุดข้อสอบ", {{"all", "ทั้งหมด"}, {"wrong", "เคยผิด"}, {"star", "★ ดาว"}}, "drillSet")
	segmented("จำนวนข้อ", {{5, "5"}, {10, "10"}, {20, "20"}}, "drillN")
	do
		local f = card()
		local b = mkbtn(f, {Size = UDim2.new(1, 0, 0, 40), Text = "▶ เริ่มทบทวน", TextSize = 15}, startDrill)
		bindAcc(function() b.BackgroundColor3 = T.acc end)
	end
	do
		local f = card()
		f.Visible = false
		R.dCard = f
		R.dHead = lbl(f, {Size = UDim2.new(1, 0, 0, 22), Text = "ข้อ 1", Font = Enum.Font.GothamBold, TextSize = 15})
		R.dBar = bar(f, 8)
		local r1 = row(f, 34)
		mkbtn(r1, {Size = UDim2.new(0.5, -4, 1, 0), Text = "▶ เล่นคลิป"}, playClip)
		mkbtn(r1, {Size = UDim2.new(0.5, -4, 1, 0), Position = UDim2.new(0.5, 4, 0, 0), Text = "⏹ หยุดเสียง"}, function() F.stopPractice() end)
		R.dInput = textbox(f, "พิมพ์คำตอบของคุณ")
		local r2 = row(f, 36)
		mkbtn(r2, {Size = UDim2.new(1 / 3, -4, 1, 0), Text = "✔ ตรวจ", BackgroundColor3 = T.goodBtn}, checkAns)
		mkbtn(r2, {Size = UDim2.new(1 / 3, -4, 1, 0), Position = UDim2.new(1 / 3, 2, 0, 0), Text = "👁 เฉลย"}, revealAns)
		mkbtn(r2, {Size = UDim2.new(1 / 3, -4, 1, 0), Position = UDim2.new(2 / 3, 4, 0, 0), Text = "⏭ ถัดไป"}, nextQ)
		local rl = lbl(f, {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = "", TextWrapped = true, TextSize = 13})
		R.dResult = function(t, col) rl.Text = t; rl.TextColor3 = col or T.text end
	end

	Q.stage = 4
	notify("✅ ไฟล์ 4/5 เรียบร้อย รันไฟล์ 5 (ไฟล์สุดท้าย) แล้วเมนูจะขึ้น", 5)
end

local ok, err = xpcall(part4, function(e) return tostring(e) .. "\n" .. ((debug and debug.traceback) and debug.traceback("", 2) or "") end)
if not ok then Q.fatal(err) end
