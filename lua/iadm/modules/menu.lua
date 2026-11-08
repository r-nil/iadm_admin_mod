-- AI was used to make this.
-- However, not 100% of the code are vibecoded.

MODULE.ID = "menu"
MODULE.Name = "Menu"
MODULE.Description = "In-game menu for browsing and running IADM commands."
MODULE.Required = false

return MODULE, function(MODULE)
    if SERVER then return end

    local COL_BG = Color(30, 32, 38)
    local COL_PANEL = Color(43, 46, 55)
    local COL_PANEL_HOVER = Color(56, 60, 71)
    local COL_ACCENT = IADM_ECHOCOLOR_PREFIX

    local argtypes = {
        [IADM_ARGTYPE_PLR] = "player",
        [IADM_ARGTYPE_PLRS] = "players",
        [IADM_ARGTYPE_ENT] = "entity",
        [IADM_ARGTYPE_ENTS] = "entities",
        [IADM_ARGTYPE_TIME] = "time",
        [IADM_ARGTYPE_STR] = "text",
        [IADM_ARGTYPE_NUM] = "number",
        [IADM_ARGTYPE_BOOL] = "true/false",
    }

    local frame
    local searchEntry
    local commandList
    local detailScroll
    local executeButton

    local selectedID
    local selectedArgs = {}

    local function getArgHint(arg)
        return arg.hint or argtypes[arg.type] or "value"
    end

    local function getUsage(id, ctbl)
        local parts = {}

        for _, arg in ipairs(ctbl.Args) do
            parts[#parts + 1] = string.format(arg.optional and "[%s]" or "<%s>", getArgHint(arg))
        end

        return IADM:GetPrefix() .. id .. (#parts > 0 and " " .. table.concat(parts, " ") or "")
    end

    local function getAvailableCommands()
        local pl = LocalPlayer()
        local tbl = {}

        for id, ctbl in pairs(IADM.Commands) do
            local ok, canUse = pcall(IADM.CanUseCommand, IADM, pl, id)

            if not ctbl.HideInMenu and ok and canUse then
                tbl[#tbl + 1] = {id = id, ctbl = ctbl}
            end
        end

        table.sort(tbl, function(a, b)
            return string.lower(a.ctbl.Name or a.id) < string.lower(b.ctbl.Name or b.id)
        end)

        return tbl
    end

    local function getArgumentValue(count)
        local entry = selectedArgs[count]
        local value = entry and entry.get and entry.get() or ""

        return tostring(value or "")
    end

    local function executeSelected()
        if not selectedID then return end

        local ctbl = IADM.Commands[selectedID]
        if not ctbl then return end

        local args = {}

        for count, arg in ipairs(ctbl.Args) do
            local value = getArgumentValue(count)

            if value == "" and arg.default ~= nil then
                value = tostring(arg.default)
            end

            if value == "" and arg.default == nil and not arg.optional then
                IADM:Message(LocalPlayer(), true, IADM_ECHOCOLOR_ERROR, "Argument #", IADM_ECHOCOLOR_ERROR_ARGVAR, count, IADM_ECHOCOLOR_ERROR, " is required!")
                surface.PlaySound("buttons/button11.wav")
                return
            end

            args[count] = value
        end

        -- Remove trailing empty arguments, but keep gaps so argument positions stay correct.
        for i = #args, 1, -1 do
            if args[i] == "" then
                args[i] = nil
            else
                break
            end
        end

        RunConsoleCommand("iadm", selectedID, unpack(args))
    end

    local function addLabel(parent, text, font, color)
        local label = vgui.Create("DLabel", parent)
        label:Dock(TOP)
        label:DockMargin(6, 3, 6, 3)
        label:SetFont(font or "BudgetLabel")
        label:SetTextColor(color or color_white)
        label:SetText(text)
        label:SetWrap(true)
        label:SetAutoStretchVertical(true)

        return label
    end

    local function addArgumentRow(parent, count, arg, ctbl)
        local row = vgui.Create("DPanel", parent)
        row:Dock(TOP)
        row:DockMargin(6, 3, 6, 3)
        row:SetTall(54)
        row.Paint = function(_, w, h)
            draw.RoundedBox(4, 0, 0, w, h, COL_PANEL)
        end

        local label = vgui.Create("DLabel", row)
        label:Dock(TOP)
        label:DockMargin(6, 4, 6, 0)
        label:SetFont("BudgetLabel")
        label:SetText(string.format("Argument #%d - %s%s", count, arg.hint or argtypes[arg.type] or "value", arg.optional and " (optional)" or ""))
        label:SetTextColor(IADM_ECHOCOLOR_ARG1)

        if arg.type == IADM_ARGTYPE_PLR or arg.type == IADM_ARGTYPE_PLRS then
            local multi = arg.type == IADM_ARGTYPE_PLRS
            local players = player.GetAll()

            table.sort(players, function(a, b)
                return string.lower(a:Nick()) < string.lower(b:Nick())
            end)

            local listHeight = math.Clamp(26 + #players * 17, 64, 170)
            row:SetTall(34 + listHeight)

            local list = vgui.Create("DListView", row)
            list:Dock(FILL)
            list:DockMargin(6, 2, 6, 6)
            list:AddColumn(multi and "Players (Ctrl+click to select multiple)" or "Player")
            list:SetMultiSelect(multi)
            list:SetTooltip(multi and "Hold Ctrl while clicking to select multiple players." or "Select a single player.")

            local function addPlayerLine(text, value)
                local line = list:AddLine(text)
                line:SetSortValue(1, value)
            end

            local function getLineValue(line)
                local value = line:GetSortValue(1)
                if value == nil then value = line:GetColumnText(1) end
                return value
            end

            addPlayerLine("Self (^)", "^")
            addPlayerLine("Aim target (@)", "@")

            for _, ply in ipairs(players) do
                local canTarget = true

                if ctbl then
                    local ok, result = pcall(IADM.CmdCanTarget, IADM, LocalPlayer(), ply, ctbl, arg)
                    if ok and result == false then canTarget = false end
                end

                if canTarget then
                    addPlayerLine(ply:Nick(), ply:Nick())
                end
            end

            selectedArgs[count] = {
                get = function()
                    local selected = list:GetSelected() or {}

                    if multi then
                        local values = {}

                        for _, line in ipairs(selected) do
                            values[#values + 1] = getLineValue(line)
                        end

                        return table.concat(values, ",")
                    end

                    return selected[1] and getLineValue(selected[1]) or ""
                end
            }

            return
        end

        if arg.type == IADM_ARGTYPE_BOOL then
            local combo = vgui.Create("DComboBox", row)
            combo:Dock(BOTTOM)
            combo:DockMargin(6, 2, 6, 6)
            combo:SetTall(24)

            if arg.optional then
                combo:AddChoice("(not set)", "")
            end
            combo:AddChoice("true", "true")
            combo:AddChoice("false", "false")

            if arg.optional and arg.default == nil then
                combo:ChooseOption("(not set)", 1)
            else
                local default = arg.default ~= nil and tostring(arg.default) or "false"
                local index = default == "true" and (arg.optional and 2 or 1) or (arg.optional and 3 or 2)
                combo:ChooseOption(default, index)
            end

            selectedArgs[count] = {
                get = function()
                    local _, value = combo:GetSelected()
                    return value or ""
                end
            }

            return
        end

        local entry = vgui.Create("DTextEntry", row)
        entry:Dock(BOTTOM)
        entry:DockMargin(6, 2, 6, 6)
        entry:SetTall(24)
        entry:SetTooltip(string.format("Type: %s%s\nLeave empty to skip optional arguments.", argtypes[arg.type] or "value", arg.optional and " (optional)" or ""))

        if arg.default ~= nil then
            entry:SetText(tostring(arg.default))
        end

        selectedArgs[count] = {
            get = function()
                return entry:GetValue()
            end
        }
    end

    local function showCommand(id)
        selectedID = id
        selectedArgs = {}
        detailScroll:Clear()

        local ctbl = IADM.Commands[id]
        if not ctbl then
            addLabel(detailScroll, "Select a command from the list.", "BudgetLabel", IADM_ECHOCOLOR_TEXT)
            if executeButton then executeButton:SetEnabled(false) end
            return
        end

        addLabel(detailScroll, ctbl.Name and (ctbl.Name .. " (" .. id .. ")") or id, "BudgetLabel", COL_ACCENT)
        addLabel(detailScroll, ctbl.Desc or "No description available.", "BudgetLabel", color_white)
        addLabel(detailScroll, "Usage: " .. getUsage(id, ctbl), "BudgetLabel", IADM_ECHOCOLOR_ARG2)

        if ctbl.Dangerous then
            addLabel(detailScroll, "Dangerous command. Only allow this command to members you trust and if it's necessary.", "BudgetLabel", IADM_ECHOCOLOR_WARN)
        end

        if #ctbl.Args > 0 then
            addLabel(detailScroll, "Arguments", "BudgetLabel", IADM_ECHOCOLOR_ARG1)

            for count, arg in ipairs(ctbl.Args) do
                addArgumentRow(detailScroll, count, arg, ctbl)
            end
        end

        if executeButton then executeButton:SetEnabled(true) end
    end

    local function populate(filter)
        commandList:Clear()
        filter = string.lower(filter or "")

        local available = getAvailableCommands()
        local added = 0
        local selectedStillListed = false

        for _, entry in ipairs(available) do
            local ctbl = entry.ctbl
            local name = ctbl.Name or entry.id
            local desc = ctbl.Desc or ""

            local matches = filter == ""
                or string.find(string.lower(name), filter, 1, true)
                or string.find(entry.id, filter, 1, true)
                or string.find(string.lower(desc), filter, 1, true)

            if matches then
                added = added + 1
                if selectedID == entry.id then selectedStillListed = true end

                local button = vgui.Create("DButton", commandList)
                button:Dock(TOP)
                button:DockMargin(4, 2, 4, 2)
                button:SetTall(36)
                button:SetText(name .. " (" .. entry.id .. ")")
                button:SetFont("BudgetLabel")
                button:SetContentAlignment(TEXT_ALIGN_LEFT)
                button.CmdID = entry.id
                button:SetTextColor(color_white)
                button.Paint = function(self, w, h)
                    local col = COL_PANEL
                    if selectedID == self.CmdID then
                        col = COL_ACCENT
                    elseif self:IsHovered() then
                        col = COL_PANEL_HOVER
                    end

                    draw.RoundedBox(4, 0, 0, w, h, col)
                end
                button.DoClick = function()
                    showCommand(entry.id)
                end
            end
        end

        if added == 0 then
            local label = vgui.Create("DLabel", commandList)
            label:Dock(TOP)
            label:DockMargin(6, 6, 6, 6)
            label:SetText(filter == "" and "No commands available." or "No commands match your search.")
            label:SetTextColor(IADM_ECHOCOLOR_TEXT)
            label:SetWrap(true)
            label:SetAutoStretchVertical(true)
        end

        if selectedID and not selectedStillListed then
            selectedID = nil
            showCommand(nil)
        end
    end

    local function createFrame()
        frame = vgui.Create("DFrame")
        frame:SetSize(820, 560)
        frame:Center()
        frame:SetTitle("IADM Admin Menu")
        frame:SetDraggable(true)
        frame:SetSizable(true)
        frame:SetMinWidth(640)
        frame:SetMinHeight(400)
        frame:MakePopup()
        frame:SetKeyboardInputEnabled(false)
        frame.OnRemove = function()
            frame = nil
            searchEntry = nil
            commandList = nil
            detailScroll = nil
            executeButton = nil
            selectedID = nil
            selectedArgs = {}
        end

        local topBar = vgui.Create("DPanel", frame)
        topBar:Dock(TOP)
        topBar:SetTall(38)
        topBar:DockMargin(6, 6, 6, 0)
        topBar.Paint = function(_, w, h)
            draw.RoundedBox(4, 0, 0, w, h, COL_BG)
        end

        searchEntry = vgui.Create("DTextEntry", topBar)
        searchEntry:Dock(LEFT)
        searchEntry:SetWide(280)
        searchEntry:DockMargin(4, 4, 4, 4)
        searchEntry:SetText("")
        searchEntry:SetTooltip("Search commands by name, id or description.")
        searchEntry.OnValueChange = function(_, value)
            populate(value)
        end

        local refreshButton = vgui.Create("DButton", topBar)
        refreshButton:Dock(RIGHT)
        refreshButton:SetWide(100)
        refreshButton:DockMargin(4, 4, 4, 4)
        refreshButton:SetText("Refresh")
        refreshButton.DoClick = function()
            populate(searchEntry:GetValue())
        end

        local hint = vgui.Create("DLabel", topBar)
        hint:Dock(FILL)
        hint:DockMargin(6, 0, 6, 0)
        hint:SetText("Type to filter the command list.")
        hint:SetTextColor(IADM_ECHOCOLOR_TEXT)

        commandList = vgui.Create("DScrollPanel", frame)
        commandList:Dock(LEFT)
        commandList:SetWide(280)
        commandList:DockMargin(6, 6, 0, 6)
        commandList.Paint = function(_, w, h)
            draw.RoundedBox(4, 0, 0, w, h, COL_BG)
        end

        local detailPanel = vgui.Create("DPanel", frame)
        detailPanel:Dock(FILL)
        detailPanel:DockMargin(6, 6, 6, 6)
        detailPanel.Paint = function(_, w, h)
            draw.RoundedBox(4, 0, 0, w, h, COL_BG)
        end

        executeButton = vgui.Create("DButton", detailPanel)
        executeButton:Dock(BOTTOM)
        executeButton:SetTall(34)
        executeButton:DockMargin(6, 0, 6, 6)
        executeButton:SetText("Execute selected command")
        executeButton:SetFont("BudgetLabel")
        executeButton:SetTextColor(color_white)
        executeButton:SetEnabled(false)
        executeButton.DoClick = executeSelected

        detailScroll = vgui.Create("DScrollPanel", detailPanel)
        detailScroll:Dock(FILL)
        detailScroll:DockMargin(2, 6, 2, 0)

        showCommand(nil)
        populate("")
    end

    function IADM:OpenMenu()
        if not IsValid(frame) then
            createFrame()
        else
            frame:SetVisible(true)
            frame:MakePopup()
            populate(searchEntry and searchEntry:GetValue() or "")
        end
    end

    function IADM:CloseMenu()
        if IsValid(frame) then
            frame:Close()
        end
    end

    function IADM:ToggleMenu()
        if IsValid(frame) and frame:IsVisible() then
            self:CloseMenu()
        else
            self:OpenMenu()
        end
    end
end
