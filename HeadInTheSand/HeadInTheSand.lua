local addonName, HITS = ...
HITS.channels = {
    {"general", "General", true}, {"trade", "Trade (incl. Local)", true},
    {"services", "Trade (Services)", true}, {"localDefense", "LocalDefense", true},
    {"say", "Say", true}, {"yell", "Yell", true},
    {"party", "Party", false}, {"raid", "Raid / Raid Warning", false},
    {"instance", "Instance", false}, {"guild", "Guild", false},
    {"officer", "Officer", false}, {"whisper", "Whispers", false},
    {"bnWhisper", "Battle.net Whispers", false}, {"emote", "Emotes", false},
    {"other", "Other / Custom Channels", false},
}
local eventChannels = {
    CHAT_MSG_SAY="say", CHAT_MSG_YELL="yell", CHAT_MSG_PARTY="party",
    CHAT_MSG_PARTY_LEADER="party", CHAT_MSG_RAID="raid", CHAT_MSG_RAID_LEADER="raid",
    CHAT_MSG_RAID_WARNING="raid", CHAT_MSG_INSTANCE_CHAT="instance",
    CHAT_MSG_INSTANCE_CHAT_LEADER="instance", CHAT_MSG_GUILD="guild", CHAT_MSG_OFFICER="officer",
    CHAT_MSG_WHISPER="whisper", CHAT_MSG_WHISPER_INFORM="whisper",
    CHAT_MSG_BN_WHISPER="bnWhisper", CHAT_MSG_BN_WHISPER_INFORM="bnWhisper",
    CHAT_MSG_EMOTE="emote", CHAT_MSG_TEXT_EMOTE="emote", CHAT_MSG_COMMUNITIES_CHANNEL="other",
}
function HITS.Print(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cffdfbe79HITS:|r " .. text)
end
function HITS.Escape(text) return (text:gsub("|", "||")) end
local function trim(text) return (text:match("^%s*(.-)%s*$")) end
function HITS.Initialize()
    if type(HITS_DB) ~= "table" then HITS_DB = {} end
    local defaults = {enabled=true, chinese=true, korean=true, ignoreCase=true,
        matchLinks=true, showCount=false, notices=false}
    for key, value in pairs(defaults) do
        if type(HITS_DB[key]) ~= "boolean" then HITS_DB[key] = value end
    end
    if type(HITS_DB.channels) ~= "table" then HITS_DB.channels = {} end
    for _, entry in ipairs(HITS.channels) do
        if type(HITS_DB.channels[entry[1]]) ~= "boolean" then
            HITS_DB.channels[entry[1]] = entry[3]
        end
    end
    if type(HITS_DB.words) ~= "table" then HITS_DB.words = {"anal", "thunderfury"} end
    local clean, seen = {}, {}
    for _, word in ipairs(HITS_DB.words) do
        if type(word) == "string" then
            word = trim(word)
            if word ~= "" and not seen[word] then
                clean[#clean+1], seen[word] = word, true
            end
        end
    end
    HITS_DB.words = clean
    HITS_DB.version = 1
    HITS.hidden = HITS.hidden or 0
end
function HITS.Changed()
    if HITS.Refresh then HITS.Refresh() end
    if HITS_DB.notices then HITS.Print("Settings saved.") end
end
function HITS.AddWord(word)
    word = trim(word or "")
    if word == "" then return false, "Enter a word or phrase first." end
    for _, existing in ipairs(HITS_DB.words) do
        if existing == word or (HITS_DB.ignoreCase and existing:lower() == word:lower()) then
            return false, "That word or phrase is already listed."
        end
    end
    HITS_DB.words[#HITS_DB.words+1] = word
    HITS.Changed()
    return true, "Added: " .. HITS.Escape(word)
end
function HITS.RemoveWord(index)
    table.remove(HITS_DB.words, index)
    HITS.Changed()
end
function HITS.Reset()
    HITS_DB = nil
    HITS.Initialize()
    HITS.Changed()
end
-- Decode validated UTF-8. Invalid bytes are skipped individually, so a bad
-- sequence cannot conceal a valid blocked character later in the message.
local function nextCodepoint(text, i)
    local a,b,c,d = text:byte(i,i+3)
    local function continuation(v) return v and v >= 128 and v <= 191 end
    if a < 128 then return a, i+1 end
    if a >= 194 and a <= 223 and continuation(b) then
        return (a-192)*64+b-128, i+2
    end
    if a >= 224 and a <= 239 and continuation(b) and continuation(c)
        and not (a == 224 and b < 160) and not (a == 237 and b >= 160) then
        return (a-224)*4096+(b-128)*64+c-128, i+3
    end
    if a >= 240 and a <= 244 and continuation(b) and continuation(c) and continuation(d)
        and not (a == 240 and b < 144) and not (a == 244 and b > 143) then
        return (a-240)*262144+(b-128)*4096+(c-128)*64+d-128, i+4
    end
    return nil, i+1
end
local hanRanges = {{0x3400,0x4DBF},{0x4E00,0x9FFF},{0xF900,0xFAFF},
    {0x20000,0x2A6DF},{0x2A700,0x2B73F},{0x2B740,0x2B81F},{0x2B820,0x2CEAF},
    {0x2CEB0,0x2EBEF},{0x2EBF0,0x2EE5F},{0x2F800,0x2FA1F},
    {0x30000,0x3134F},{0x31350,0x323AF},{0x323B0,0x3347F}}
local hangulRanges = {{0x1100,0x11FF},{0x3130,0x318F},{0xA960,0xA97F},
    {0xAC00,0xD7AF},{0xD7B0,0xD7FF},{0xFFA0,0xFFDC}}
local function inRanges(cp, ranges)
    for _, range in ipairs(ranges) do
        if cp >= range[1] and cp <= range[2] then return true end
    end
    return false
end
function HITS.ContainsLanguage(text)
    local i = 1
    while i <= #text do
        local cp; cp, i = nextCodepoint(text, i)
        if cp and ((HITS_DB.chinese and inRanges(cp, hanRanges))
            or (HITS_DB.korean and inRanges(cp, hangulRanges))) then return true end
    end
    return false
end
function HITS.VisibleText(text, includeLinks)
    -- Inspect displayed link labels, never hidden link IDs or texture paths.
    text = text:gsub("|H.-|h(.-)|h", function(label)
        return includeLinks and label or " "
    end)
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    text = text:gsub("|T.-|t", " "):gsub("|A.-|a", " ")
    return text
end
function HITS.ContainsWord(text)
    text = HITS.VisibleText(text, HITS_DB.matchLinks)
    if HITS_DB.ignoreCase then text = text:lower() end
    for _, word in ipairs(HITS_DB.words) do
        if HITS_DB.ignoreCase then word = word:lower() end
        if text:find(word, 1, true) then return true end
    end
    return false
end
function HITS.ChannelKey(event, zoneID, name)
    if event ~= "CHAT_MSG_CHANNEL" then return eventChannels[event] end
    -- Static ChatChannels IDs, never the user's mutable /1, /2 numbers.
    local static = {[1]="general", [2]="trade", [22]="localDefense", [42]="services"}
    if static[zoneID] then return static[zoneID] end
    -- Localized names are obtained from Blizzard globals when available.
    name = type(name) == "string" and name:lower() or ""
    local names = {
        {"services", _G.TRADE_SERVICES, "trade (services)"},
        {"trade", _G.TRADE_LOCAL, "trade (local)"},
        {"general", _G.GENERAL, "general"}, {"trade", _G.TRADE, "trade"},
        {"localDefense", _G.LOCAL_DEFENSE, "localdefense"},
    }
    for _, entry in ipairs(names) do
        for n=2,3 do
            local candidate = entry[n]
            if type(candidate) == "string" and candidate ~= "" then
                candidate = candidate:lower()
                if name == candidate or name:sub(1,#candidate+3) == candidate .. " - " then
                    return entry[1]
                end
            end
        end
    end
    return "other"
end
local seen, queue = {}, {}
local function countHidden(event, lineID)
    -- The same event is filtered once for each chat window. Count it once.
    if type(lineID) == "number" and lineID > 0 then
        local key = event .. ":" .. lineID
        if seen[key] then return end
        seen[key] = true
        queue[#queue+1] = key
        if #queue > 256 then seen[table.remove(queue,1)] = nil end
    end
    HITS.hidden = HITS.hidden + 1
    if HITS.RefreshCount then HITS.RefreshCount() end
end
function HITS.Filter(_, event, message, author, ...)
    if not HITS_DB or not HITS_DB.enabled then return false end
    -- Some client contexts can restrict chat strings. Leave unreadable values alone.
    if issecretvalue and issecretvalue(message) then return false end
    if type(message) ~= "string" then return false end
    local zoneID, name, lineID = select(5,...), select(7,...), select(9,...)
    if issecretvalue then
        if issecretvalue(zoneID) then zoneID = nil end
        if issecretvalue(name) then name = nil end
        if issecretvalue(lineID) then lineID = nil end
    end
    local key = HITS.ChannelKey(event, zoneID, name)
    local blocked = HITS.ContainsLanguage(HITS.VisibleText(message, true))
        or (key and HITS_DB.channels[key] and HITS.ContainsWord(message))
    if blocked then countHidden(event,lineID); return true end
    return false
end
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, _, loadedName)
    if loadedName ~= addonName then return end
    HITS.Initialize()
    HITS.BuildUI()
    -- Forever shares Mainline's project ID. Select APIs by capability,
    -- never infer a Classic UI from Forever's five-digit interface number.
    local register
    if ChatFrameUtil and type(ChatFrameUtil.AddMessageEventFilter) == "function" then
        register = ChatFrameUtil.AddMessageEventFilter
        HITS.filterAPI = "ChatFrameUtil.AddMessageEventFilter"
    elseif type(ChatFrame_AddMessageEventFilter) == "function" then
        register = ChatFrame_AddMessageEventFilter
        HITS.filterAPI = "ChatFrame_AddMessageEventFilter"
    else
        HITS.filterAPI = "unavailable"
    end
    if register then
        local function add(event)
            if type(securecallfunction) == "function" then
                securecallfunction(register, event, HITS.Filter)
            else
                register(event, HITS.Filter)
            end
        end
        add("CHAT_MSG_CHANNEL")
        for event in pairs(eventChannels) do add(event) end
    else
        HITS.Print("Chat filter API unavailable in this client. HITS is not filtering chat.")
    end
    SLASH_HEADINTHESAND1, SLASH_HEADINTHESAND2 = "/hits", "/headinthesand"
    SlashCmdList.HEADINTHESAND = function(msg)
        msg = trim(msg or ""):lower()
        if msg == "status" then
            HITS.Print((HITS_DB.enabled and "Enabled" or "Paused") .. "; " .. #HITS_DB.words
                .. " phrases; " .. HITS.hidden .. " hidden this session.")
        elseif msg == "debug" then
            local version, build, _, interface
            if type(GetBuildInfo) == "function" then
                version, build, _, interface = GetBuildInfo()
            end
            HITS.Print("v1.0.1; client " .. tostring(version or "unknown")
                .. "; build " .. tostring(build or "unknown")
                .. "; interface " .. tostring(interface or "unknown")
                .. "; filter API: " .. HITS.filterAPI
                .. "; settings: " .. tostring(HITS.settingsAPI or "unavailable"))
        elseif msg == "help" then
            HITS.Print("/hits opens settings. /hits status shows the session count. /hits debug shows client compatibility.")
        else HITS.OpenSettings() end
    end
    self:UnregisterEvent("ADDON_LOADED")
end)
