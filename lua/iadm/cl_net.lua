net.Receive("iadm_printmsg", function(len)
    local prefix = net.ReadBit() == 1
    local printtochat = net.ReadBit() == 1
    local tbl = IADM_NET_READTABLE()

	for i,str in ipairs(tbl) do
		if !isbool(str) and !isnumber(str) and
		(IsColor(str) or IsValid(str)) then continue end
		tbl[i] = tostring(str)
	end

    if printtochat then
        if prefix then
            chat.AddText(IADM_ECHOCOLOR_PREFIX, "[IADM] ", color_white, unpack(tbl))
        else
            chat.AddText(unpack(tbl))
        end
    else
		for i,str in ipairs(tbl) do
			if IsValid(str) then
				tbl[i] = str:Nick()
			end
		end

        if prefix then
            MsgC(IADM_ECHOCOLOR_PREFIX, "[IADM] ", color_white)
        end
        MsgC(unpack(tbl))
        MsgN() -- DO NOT DELETE - this line is required cuz adding "\n" after MsgC unpacked varargs fucks it up
    end
end)

net.Receive("iadm_playerusecmd", function(len)
    local ply = net.ReadEntity()
    local str = net.ReadString()
    local tbl = IADM_NET_READTABLE()

    str = string.Replace(str, "#A#", ply:Nick())
    -- str = string.Replace(str, "#T#", ply:Nick())
    -- str = string.Replace(str, "#B#", ply:Nick())

    IADM:MessageWPrefix(LocalPlayer(), true, str)
end)

net.Receive("iadm_csay", function()
    local tbl = IADM_NET_READTABLE()
    local start = SysTime()

    local t = {}
    local c = 1
    local next = false

    local whole_string = ""
    for i=1,#tbl do
        if not t[c] then t[c] = {} end

        local v = tbl[i]

        if IsColor(v) then
            if next then
                c = c + 1
                next = false
            end
            if IsColor(t[c][#t]) then
                t[c][#t] = v
            else
                table.insert(t[c], v)
            end
        else
            if isstring(t[c][#t]) then
                t[c][#t] = t[c][#t]..tostring(v)
            else
                table.insert(t[c], tostring(v))
            end
            whole_string = whole_string..tostring(v)
            next = true
        end
    end


    local a = 0
    LocalPlayer():EmitSound("buttons/button17.wav", 0, 100, 0.15)
    local y_start = ScrH()/3-50
    local y_end = ScrH()/3
    local y = y_start
    local duration = 10

    hook.Add("PostDrawHUD", "IADM.Csay", function()
        if start+duration < SysTime() then
            hook.Remove("PostDrawHUD", "IADM.Csay")
        end

        cam.Start2D()
        a = math.Approach(a, 255, (255-(a*0.2))*FrameTime())

        local font = "Trebuchet24"
        surface.SetFont(font)
        local x1,y1 = surface.GetTextSize(whole_string)
        for _,v in pairs(t) do
            local txt = IsColor(v[1]) and v[2] or v[1]
            local x2,y2 = surface.GetTextSize(txt)

            local x = ScrW()/2-x1/2

            local col = IsColor(v[1]) and v[1] or color_white:Copy()
            col.a = a-math.max(0, 255*(SysTime()+1 - start-duration))
            draw.SimpleText(txt, font, x, y, col, TEXT_ALIGN_LEFT)
        end

        y = math.Approach(y, y_end, (y_end-y)*FrameTime()*5)
    	cam.End2D()
    end)
end)

net.Receive("iadm_syncdata", function(len)
    local pl = LocalPlayer()
    local datatype = net.ReadString()
    local args = IADM_NET_READTABLE()

    for _,tbl in ipairs(IADM.RegisteredSyncData) do
        if tbl.id == datatype then
            tbl.Func(tbl, pl, args)
            break
        end
    end
end)
