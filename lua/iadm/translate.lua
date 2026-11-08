IADM.Languages = IADM.Languages or {}
IADM.SelectableLanguages = IADM.SelectableLanguages or {}

local gmod_language = GetConVar("gmod_language")
IADM.DefaultLanguage = "en"
IADM.CurrentLanguage = gmod_language and gmod_language:GetString() or IADM.DefaultLanguage
local langs = IADM.Languages

-- meta table for languages
local m = {}
local meta = {}
meta.__index = m

function m:AddNewLine(id, translated)
    IADM:AddNewLine(self, id, translated)
end
meta.AddNewLine = m.AddNewLine

function IADM:CreateNewLanguage(id, name)
    local tbl = {}
    self.Languages[id] = tbl
    self.SelectableLanguages[id] = name
    tbl = setmetatable(tbl, meta)

    return tbl
end

function IADM:GetExistingOrCreateNewLanguage(id, name)
    if self.Languages[id] then return self.Languages[id] end

    return self:CreateNewLanguage(id, name)
end

local function OnAlreadyExists(id, lang)
    IADM:MessageWPrefix(nil, false, IADM_ECHOCOLOR_WARN, "[WARN] ", IADM_ECHOCOLOR_ARG1, id, IADM_ECHOCOLOR_TEXT, " already exists in ", IADM_ECHOCOLOR_ARG2, lang or "language", IADM_ECHOCOLOR_TEXT, "!")
end

function IADM:AddNewLine(lang, id, translated)
    if not translated then translated = id end

    if istable(lang) then
        if lang[id] then OnAlreadyExists(id) end
        lang[id] = translated
    else
        if lang[id] then OnAlreadyExists(id, lang) end
        langs[lang][id] = translated
    end
end


function IADM:GetTranslatedText(pl, id, ...)
    local lang
    local args = {...}

    -- Also allow calling this without a player argument: IADM:GetTranslatedText("text")
    if type(pl) == "string" and id == nil then
        id = pl
        pl = nil
    end

    if SERVER and IsValid(pl) then
        lang = langs[pl.IADM_CurrentLanguage] or langs[self.CurrentLanguage] or langs[self.DefaultLanguage]
    else
        lang = langs[self.CurrentLanguage] or langs[self.DefaultLanguage]
    end

    local text = (lang and lang[id]) or id
    if type(text) ~= "string" then return "" end

    if #args > 0 then
        local ok, formatted = pcall(string.format, text, unpack(args))
        return ok and formatted or text
    end

    return text
end
