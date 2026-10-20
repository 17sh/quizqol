--[[
	Quiz QoL v3.0 | ไฟล์ 3/5: สมุด ตัวตรวจจับเสียง ป้ายบนจอ โหมดทบทวน และเครื่องมือ
	ต้องรันไฟล์ 1 และ 2 เสร็จก่อน
]]
local G = (getgenv and getgenv()) or _G
local Q = G.QQ
local N = 3
local function say(msg)
	print("[QuizQoL] " .. msg)
	pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Quiz QoL", Text = msg, Duration = 8}) end)
end
if not Q then say("ต้องรันไฟล์ 1 ก่อน"); return end
if Q.stage ~= N - 1 then
	say(Q.stage < N - 1 and ("ต้องรันไฟล์ " .. (Q.stage + 1) .. " ก่อน") or ("ไฟล์ " .. N .. " รันไปแล้ว ถ้าจะเริ่มใหม่ให้รันไฟล์ 1 อีกครั้ง"))
	return
end

local function part3()
	local Svc, LP, cfg, T, KIND = Q.Svc, Q.LP, Q.cfg, Q.T, Q.KIND
	local new, corner, pad = Q.new, Q.corner, Q.pad
	local track, F, R, notify, setclip = Q.track, Q.F, Q.R, Q.notify, Q.setclip
	local canFile, BOOK_FILE, gui, makeDrag = Q.canFile, Q.BOOK_FILE, Q.gui, Q.makeDrag

	-- ===== สมุด (ข้อมูล) =====
	local book = {}
	if canFile then
		pcall(function()
			if isfile(BOOK_FILE) then
				local d = Svc.HttpService:JSONDecode(readfile(BOOK_FILE))
				if type(d) == "table" then for k, v in pairs(d) do book[k] = v end end
			end
		end)
	end
	local function saveBook()
		if canFile then pcall(function() writefile(BOOK_FILE, Svc.HttpService:JSONEncode(book)) end) end
	end
	local function newEntry() return {right = 0, wrong = 0, plays = 1, title = "", note = ""} end

	-- ===== ตัวตรวจจับเสียง (จำจากรหัสเสียง ไม่อ่านชื่อ/เฉลยจากเกม) =====
	local IGNORE = "QQ_PRACTICE"
	local soundSet = {}
	Q.pinPath = nil
	local function trackSound(d) if d:IsA("Sound") and d.Name ~= IGNORE then soundSet[d] = true end end
	local function scanRoot(rt)
		if not rt then return end
		task.spawn(function()
			local n = 0
			for _, d in ipairs(rt:GetDescendants()) do
				trackSound(d); n = n + 1
				if n % 400 == 0 then task.wait() end
			end
		end)
		track(rt.DescendantAdded:Connect(trackSound))
		track(rt.DescendantRemoving:Connect(function(d) soundSet[d] = nil end))
	end
	scanRoot(workspace)
	scanRoot(Svc.SoundService)
	scanRoot(LP:FindFirstChildOfClass("PlayerGui"))

	local function fpOf(s)
		local id = tostring(s.SoundId or ""):match("(%d+)")
		if id then return "sid" .. id end
		return nil
	end
	local function shortId(fp)
		local id = tostring(fp):gsub("sid", "")
		return "#" .. id:sub(-6)
	end
	local function pickSound()
		local best, bl
		for s in pairs(soundSet) do
			if s.Parent and s.IsPlaying and s.TimeLength >= cfg.minLen and s.Volume > 0 and fpOf(s) then
				if Q.pinPath then
					if s:GetFullName() == Q.pinPath then return s end
				elseif not bl or s.TimeLength < bl then
					best, bl = s, s.TimeLength
				end
			end
		end
		if Q.pinPath then return nil end
		return best
	end

	-- ===== ป้ายบนจอ (ลากย้ายได้) =====
	local hud = new("Frame", {Size = UDim2.fromOffset(330, 0), AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.fromOffset(12, 110),
		BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.25, Visible = false, Active = true, BorderSizePixel = 0}, gui)
	corner(hud, 12)
	pad(hud, 8, 12, 8, 12)
	local hudStroke = new("UIStroke", {Thickness = 1.5, Transparency = 0.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = T.acc}, hud)
	local hudLbl = new("TextLabel", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, TextWrapped = true,
		TextSize = cfg.hudSize, Font = Enum.Font.GothamBold, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left, Text = ""}, hud)
	makeDrag(hud, hud)
	local hudTok = 0
	F.applyHud = function()
		hud.Visible = cfg.hud and hudLbl.Text ~= ""
		hudLbl.TextSize = cfg.hudSize
	end
	local function setBanner(textStr, kind)
		hudLbl.Text = textStr
		hudStroke.Color = KIND[kind] or T.acc
		R.banner(textStr, kind)
		hudTok = hudTok + 1
		local tok = hudTok
		F.applyHud()
		if cfg.hudHide > 0 then
			task.delay(cfg.hudHide, function() if tok == hudTok then hud.Visible = false end end)
		end
	end

	-- ===== ตรรกะสมุด =====
	local sess = {right = 0, wrong = 0, streak = 0, best = 0}
	local history, target = {}, nil

	local function describe(e)
		local line = "📒 เคยเจอแล้ว • ถูก " .. (e.right or 0) .. " ผิด " .. (e.wrong or 0) .. " • เจอ " .. (e.plays or 0) .. " ครั้ง"
		line = line .. "\nที่จดไว้: " .. ((e.title and e.title ~= "") and e.title or "(ยังไม่ได้ระบุชื่อ)")
		if e.note and e.note ~= "" then line = line .. "\nโน้ต: " .. e.note end
		if (e.wrong or 0) > (e.right or 0) then line = "⚠ เพลงที่เคยพลาดบ่อย\n" .. line end
		return line
	end
	local function updSess()
		if not R.sess then return end
		R.sess[1](sess.right); R.sess[2](sess.wrong); R.sess[3](sess.streak)
		local tot = sess.right + sess.wrong
		local pc = tot > 0 and math.floor(sess.right / tot * 100 + 0.5) or 0
		R.accBar(tot > 0 and sess.right / tot or 0, T.good)
		R.accLbl.Text = "แม่นยำ " .. pc .. "% • สตรีคสูงสุด " .. sess.best .. " • จดไปแล้ว " .. tot .. " ข้อ"
	end
	local function onSong(fp, s)
		F.stopPractice()
		local e = book[fp]
		local h1 = history[1]
		if not (h1 and h1.fp == fp and os.time() - h1.t < 3) then
			table.insert(history, 1, {fp = fp, len = math.floor(s.TimeLength), t = os.time()})
			while #history > 30 do table.remove(history) end
		end
		target = fp
		R.target(fp)
		if e then
			e.plays = (e.plays or 0) + 1
			saveBook()
			setBanner(describe(e), ((e.wrong or 0) > (e.right or 0)) and "warn" or "known")
			R.fill(e.title or "", e.note or "")
			notify("📒 เจอเพลงนี้ในสมุดแล้ว", 3)
		else
			setBanner("🆕 เพลงใหม่ ยังไม่มีบันทึก หลังจบรอบให้พิมพ์ชื่อที่ถูกต้อง แล้วกดบันทึก", "new")
			R.fill("", "")
		end
		F.refreshHist()
	end
	local function record(kind)
		local fp = target
		if not fp then notify("ยังไม่มีเพลงให้จด รอให้เพลงเล่นก่อน", 3); return end
		local e = book[fp] or newEntry()
		local t, n = R.titleBox.Text, R.noteBox.Text
		if kind == "note" then e.title = t; e.note = n
		else
			if t ~= "" then e.title = t end
			if n ~= "" then e.note = n end
		end
		if kind == "right" then
			e.right = (e.right or 0) + 1
			sess.right = sess.right + 1; sess.streak = sess.streak + 1; sess.best = math.max(sess.best, sess.streak)
		elseif kind == "wrong" then
			e.wrong = (e.wrong or 0) + 1
			sess.wrong = sess.wrong + 1; sess.streak = 0
		end
		e.last = os.time()
		book[fp] = e
		saveBook()
		R.target(fp)
		updSess()
		setBanner(describe(e), ((e.wrong or 0) > (e.right or 0)) and "warn" or "known")
		if kind == "wrong" and (e.title or "") == "" then notify("บันทึกว่าตอบผิดแล้ว แนะนำให้พิมพ์ชื่อที่ถูกด้วย", 4)
		elseif kind == "right" and sess.streak >= 3 then notify("บันทึกแล้ว ✔ สตรีค " .. sess.streak .. " 🔥", 3)
		else notify("บันทึกแล้ว", 2) end
		F.refreshBook(); F.refreshHist()
	end
	local function toggleStar()
		local fp = target
		if not fp then notify("ยังไม่มีเพลงให้ติดดาว", 3); return end
		local e = book[fp] or newEntry()
		if book[fp] == nil then e.title = R.titleBox.Text; e.note = R.noteBox.Text end
		e.star = not e.star
		e.last = os.time()
		book[fp] = e
		saveBook(); R.target(fp); F.refreshBook(); F.refreshHist()
	end
	local function selectFp(fp)
		target = fp
		R.target(fp)
		local e = book[fp]
		R.fill(e and e.title or "", e and e.note or "")
	end

	-- ===== โหมดทบทวน (ฝึกจากสมุดของคุณเอง) =====
	local P = {snd = nil, q = {}, i = 0, right = 0, wrong = 0, cur = nil, answered = false, missed = {}, active = false}
	F.stopPractice = function()
		if P.snd then
			local s = P.snd
			P.snd = nil
			pcall(function() s:Stop(); s:Destroy() end)
		end
	end
	local function ulen(s) return utf8.len(s) or #s end
	local function normalize(s)
		s = tostring(s or ""):lower()
		s = s:gsub("[%s%p]", "")
		return s
	end
	local function matches(ans, ttl)
		local a, t = normalize(ans), normalize(ttl)
		if a == "" or t == "" then return false end
		if a == t then return true end
		if ulen(a) >= 3 and t:find(a, 1, true) then return true end
		if ulen(t) >= 3 and a:find(t, 1, true) then return true end
		return false
	end
	local function playClip()
		F.stopPractice()
		if not P.cur then return end
		local id = tostring(P.cur):gsub("sid", "")
		task.spawn(function()
			local snd = new("Sound", {Name = IGNORE, SoundId = "rbxassetid://" .. id, Volume = 1}, gui)
			P.snd = snd
			local t = 0
			while Q.alive and P.snd == snd and not snd.IsLoaded and t < 6 do task.wait(0.1); t = t + 0.1 end
			if P.snd ~= snd then return end
			if snd.TimeLength > 14 then pcall(function() snd.TimePosition = math.random() * (snd.TimeLength - 14) end) end
			snd:Play()
			task.wait(14)
			if P.snd == snd then F.stopPractice() end
		end)
	end
	local function buildQueue()
		local arr = {}
		for fp, e in pairs(book) do
			if type(e) == "table" and e.title and e.title ~= "" then
				local ok = true
				if cfg.drillSet == "wrong" then ok = (e.wrong or 0) > 0
				elseif cfg.drillSet == "star" then ok = e.star and true or false end
				if ok then arr[#arr + 1] = fp end
			end
		end
		for i = #arr, 2, -1 do local j = math.random(i); arr[i], arr[j] = arr[j], arr[i] end
		while #arr > cfg.drillN do table.remove(arr) end
		return arr
	end
	local function showQ()
		P.cur = P.q[P.i]
		P.answered = false
		R.dHead.Text = "ข้อ " .. P.i .. " / " .. #P.q
		R.dBar((P.i - 1) / #P.q)
		R.dInput.Text = ""
		R.dResult("▶ กดเล่นคลิป แล้วพิมพ์ชื่อเพลง/อนิเมะที่คุณคิดว่าใช่", T.sub)
	end
	local function finishDrill()
		F.stopPractice()
		P.active = false
		local tot = P.right + P.wrong
		local pc = tot > 0 and math.floor(P.right / tot * 100 + 0.5) or 0
		for _, fp in ipairs(P.missed) do if book[fp] then book[fp].star = true end end
		saveBook()
		F.refreshBook()
		R.dHead.Text = "จบแล้ว 🎉"
		R.dBar(1, T.good)
		R.dResult("ได้ " .. P.right .. " / " .. tot .. " (" .. pc .. "%)" .. (#P.missed > 0 and ("\nข้อที่พลาด " .. #P.missed .. " ข้อ ถูกติดดาว ★ ให้แล้ว ไปฝึกซ้ำได้ที่ชุด ★ ดาว") or "\nเยี่ยมมาก ไม่พลาดเลย!"), T.text)
	end
	local function startDrill()
		local q = buildQueue()
		if #q == 0 then
			notify("ยังไม่มีเพลงที่จดชื่อไว้ในชุดนี้ จดชื่อเพลงในแท็บ 🎵 เล่น ก่อน", 5)
			return
		end
		P.q, P.i, P.right, P.wrong, P.missed, P.active = q, 1, 0, 0, {}, true
		R.dCard.Visible = true
		showQ()
	end
	local function checkAns()
		if not P.active or not P.cur or P.answered then return end
		local e = book[P.cur]
		if not e then return end
		P.answered = true
		if matches(R.dInput.Text, e.title) then
			P.right = P.right + 1; e.dr = (e.dr or 0) + 1
			R.dResult("✔ ถูกต้อง! " .. e.title, T.good)
		else
			P.wrong = P.wrong + 1; e.dw = (e.dw or 0) + 1
			P.missed[#P.missed + 1] = P.cur
			R.dResult("✘ ยังไม่ใช่ • เฉลย: " .. e.title, T.bad)
		end
		saveBook()
		F.stopPractice()
	end
	local function revealAns()
		if not P.active or not P.cur then return end
		local e = book[P.cur]
		if not e then return end
		if not P.answered then
			P.answered = true
			P.wrong = P.wrong + 1; e.dw = (e.dw or 0) + 1
			P.missed[#P.missed + 1] = P.cur
			saveBook()
		end
		R.dResult("👁 เฉลย: " .. e.title .. ((e.note and e.note ~= "") and ("\nโน้ต: " .. e.note) or ""), T.warn)
	end
	local function nextQ()
		if not P.active then return end
		if not P.answered then
			P.wrong = P.wrong + 1
			P.missed[#P.missed + 1] = P.cur
		end
		F.stopPractice()
		P.i = P.i + 1
		if P.i > #P.q then finishDrill() else showQ() end
	end

	-- ===== เครื่องมือ =====
	local function copy(txt, okMsg)
		if setclip then
			local ok = pcall(setclip, txt)
			notify(ok and (okMsg or "คัดลอกแล้ว") or "คัดลอกไม่สำเร็จ", 3)
		else
			notify("executor นี้ไม่รองรับการคัดลอก", 4)
		end
	end
	local function exportText()
		local lines = {}
		for fp, e in pairs(book) do
			if type(e) == "table" then
				lines[#lines + 1] = ((e.title and e.title ~= "") and e.title or "(ไม่มีชื่อ)") .. " | " .. shortId(fp) .. " | ถูก " .. (e.right or 0) .. " ผิด " .. (e.wrong or 0)
					.. ((e.note and e.note ~= "") and (" | " .. e.note) or "")
			end
		end
		table.sort(lines)
		copy(table.concat(lines, "\n"), "คัดลอกรายชื่อแล้ว (" .. #lines .. " เพลง)")
	end
	local function importBook(raw)
		local ok, d = pcall(function() return Svc.HttpService:JSONDecode(raw) end)
		if not ok or type(d) ~= "table" then notify("ข้อมูลที่วางไม่ใช่ JSON ของสมุด", 4); return end
		local n = 0
		for fp, e in pairs(d) do
			if type(fp) == "string" and fp:match("^sid%d+$") and type(e) == "table" then
				local cur = book[fp]
				if cur then
					cur.right = math.max(cur.right or 0, e.right or 0); cur.wrong = math.max(cur.wrong or 0, e.wrong or 0)
					cur.plays = math.max(cur.plays or 0, e.plays or 0)
					if (cur.title or "") == "" then cur.title = e.title or "" end
					if (cur.note or "") == "" then cur.note = e.note or "" end
					cur.star = cur.star or e.star
				else
					book[fp] = e
				end
				n = n + 1
			end
		end
		saveBook(); F.refreshBook()
		notify("นำเข้าแล้ว " .. n .. " เพลง", 4)
	end
	local rejoining = false
	local function rejoin()
		if rejoining then return end
		rejoining = true
		notify("กำลังกลับเข้าเกม...", 3)
		pcall(function() Svc.TeleportService:Teleport(game.PlaceId, LP) end)
		task.delay(10, function() rejoining = false end)
	end
	local function serverHop()
		notify("กำลังหาเซิร์ฟเวอร์ใหม่...", 3)
		local ok, res = pcall(function()
			return Svc.HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"))
		end)
		if not ok or type(res) ~= "table" or type(res.data) ~= "table" then
			notify("ดึงรายชื่อเซิร์ฟเวอร์ไม่ได้ (executor อาจไม่รองรับ หรือเกมนี้เป็นห้องส่วนตัว)", 6)
			return
		end
		local pool = {}
		for _, sv in ipairs(res.data) do
			if sv.id ~= game.JobId and sv.playing and sv.maxPlayers and sv.playing < sv.maxPlayers and sv.playing >= 2 then pool[#pool + 1] = sv end
		end
		if #pool == 0 then
			for _, sv in ipairs(res.data) do
				if sv.id ~= game.JobId and sv.playing and sv.maxPlayers and sv.playing < sv.maxPlayers then pool[#pool + 1] = sv end
			end
		end
		if #pool == 0 then notify("ไม่พบเซิร์ฟเวอร์อื่น", 4); return end
		local pick = pool[math.random(#pool)]
		notify("กำลังย้าย (" .. pick.playing .. "/" .. pick.maxPlayers .. " คน)", 4)
		pcall(function() Svc.TeleportService:TeleportToPlaceInstance(game.PlaceId, pick.id, LP) end)
	end

	-- ส่งออกให้ไฟล์ถัดไป
	Q.book, Q.saveBook, Q.soundSet = book, saveBook, soundSet
	Q.fpOf, Q.shortId, Q.pickSound = fpOf, shortId, pickSound
	Q.sess, Q.history = sess, history
	Q.updSess, Q.onSong, Q.record, Q.toggleStar, Q.selectFp = updSess, onSong, record, toggleStar, selectFp
	Q.startDrill, Q.playClip, Q.checkAns, Q.revealAns, Q.nextQ = startDrill, playClip, checkAns, revealAns, nextQ
	Q.copy, Q.exportText, Q.importBook = copy, exportText, importBook
	Q.rejoin, Q.serverHop = rejoin, serverHop

	Q.stage = 3
	notify("✅ ไฟล์ 3/5 เรียบร้อย รันไฟล์ 4 ต่อได้เลย", 5)
end

local ok, err = xpcall(part3, function(e) return tostring(e) .. "\n" .. ((debug and debug.traceback) and debug.traceback("", 2) or "") end)
if not ok then Q.fatal(err) end
