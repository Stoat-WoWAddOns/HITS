local _, HITS = ...
local checks, rows = {}, {}
local panel, wordChild, wordScroll, entry, feedback, countLabel
local function label(parent, text, x, y, font, width)
    local fs = parent:CreateFontString(nil, "ARTWORK", font or "GameFontHighlight")
    fs:SetPoint("TOPLEFT", x, -y)
    fs:SetJustifyH("LEFT")
    if width then fs:SetWidth(width) end
    fs:SetText(text)
    return fs
end
local function button(parent, text, x, y, width, callback)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetPoint("TOPLEFT", x, -y); b:SetSize(width, 24); b:SetText(text)
    b:SetScript("OnClick", callback)
    return b
end
local function checkbox(parent, text, x, y, get, set)
    local b = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    b:SetPoint("TOPLEFT", x, -y); b:SetSize(26,26)
    local fs = b:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
    fs:SetPoint("LEFT",b,"RIGHT",3,0); fs:SetText(text)
    b:SetScript("OnClick",function(self) set(self:GetChecked() and true or false); HITS.Changed() end)
    checks[#checks+1] = {button=b,get=get}
    return b
end
local function setting(parent, key, text, x, y)
    return checkbox(parent,text,x,y,function() return HITS_DB[key] end,
        function(value) HITS_DB[key]=value end)
end
function HITS.RefreshCount()
    if countLabel then
        countLabel:SetText(HITS_DB.showCount and (HITS.hidden .. " messages hidden this session") or "")
    end
end
function HITS.Refresh()
    if not panel then return end
    for _, item in ipairs(checks) do item.button:SetChecked(item.get()) end
    for _, row in ipairs(rows) do row:Hide() end
    local offset = 0
    for i, word in ipairs(HITS_DB.words) do
        local index = i
        local row = rows[i]
        if not row then
            row = CreateFrame("Frame",nil,wordChild)
            row:SetWidth(530)
            row.text = label(row,"",8,7,"GameFontHighlight",425)
            row.text:SetWordWrap(true)
            row.remove = button(row,"Remove",445,3,78,function()
                HITS.RemoveWord(row.index)
                feedback:SetText("Removed.")
            end)
            local bg = row:CreateTexture(nil,"BACKGROUND")
            bg:SetAllPoints(); bg:SetColorTexture(1,1,1,0.035)
            rows[i] = row
        end
        row.index = index
        row:ClearAllPoints(); row:SetPoint("TOPLEFT",0,-offset)
        row.text:SetText(HITS.Escape(word))
        local height = math.max(32,row.text:GetStringHeight()+14)
        row:SetHeight(height); offset=offset+height+2; row:Show()
    end
    wordChild:SetHeight(math.max(160,offset))
    wordScroll:SetVerticalScroll(math.min(wordScroll:GetVerticalScroll(),math.max(0,offset-160)))
    if #HITS_DB.words == 0 then feedback:SetText("Your phrase list is empty.") end
    HITS.RefreshCount()
end
function HITS.BuildUI()
    panel = CreateFrame("Frame", "HITSSettingsPanel", UIParent)
    panel.name = "Head In The Sand"
    panel:Hide()
    local scroll = CreateFrame("ScrollFrame",nil,panel,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",8,-8); scroll:SetPoint("BOTTOMRIGHT",-30,8)
    local content = CreateFrame("Frame",nil,scroll)
    content:SetSize(590,1030); scroll:SetScrollChild(content)
    label(content,"Head In The Sand",12,12,"GameFontNormalHuge")
    label(content,"If you don't want to see it, stick your head in the sand.",12,46,"GameFontHighlightSmall",550)
    setting(content,"enabled","Enable HITS",10,72)
    label(content,"Language Filters",12,112,"GameFontNormalLarge")
    setting(content,"chinese","Hide Chinese / Han characters",10,140)
    setting(content,"korean","Hide Korean / Hangul characters",10,168)
    label(content,"Language filters apply to all player chat, including groups and whispers.\nHan characters are shared with Japanese kanji; those are also hidden.",12,202,"GameFontHighlightSmall",550)
    label(content,"Where Should HITS Look?",12,252,"GameFontNormalLarge")
    label(content,"Choose which channels receive word and phrase filtering.",12,279,"GameFontHighlightSmall")
    for i, channel in ipairs(HITS.channels) do
        local key = channel[1]
        local column = math.floor((i-1)/5)
        local y = 305+((i-1)%5)*29
        checkbox(content,channel[2],10+column*190,y,
            function() return HITS_DB.channels[key] end,
            function(value) HITS_DB.channels[key]=value end)
    end
    label(content,"Things I'd Rather Not See",12,476,"GameFontNormalLarge")
    label(content,"Any match hides the entire message. Substrings match too:\n\"anal\" also matches \"analysis\". Symbols are treated as literal text.",12,504,"GameFontHighlightSmall",550)
    wordScroll = CreateFrame("ScrollFrame",nil,content,"UIPanelScrollFrameTemplate")
    wordScroll:SetPoint("TOPLEFT",12,-550); wordScroll:SetSize(530,160)
    wordChild = CreateFrame("Frame",nil,wordScroll)
    wordChild:SetSize(530,160); wordScroll:SetScrollChild(wordChild)
    entry = CreateFrame("EditBox",nil,content,"InputBoxTemplate")
    entry:SetPoint("TOPLEFT",18,-726); entry:SetSize(426,26)
    entry:SetAutoFocus(false); entry:SetMaxLetters(255)
    entry:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    local function add()
        local ok, message = HITS.AddWord(entry:GetText())
        feedback:SetText(message)
        if ok then entry:SetText(""); entry:ClearFocus() end
    end
    entry:SetScript("OnEnterPressed",add)
    button(content,"Add",464,726,78,add)
    label(content,"Type a word or phrase above; press Enter or Add.",12,761,"GameFontHighlightSmall")
    feedback = label(content,"",12,784,"GameFontHighlightSmall",550)
    setting(content,"ignoreCase","Ignore capitalization (ASCII letters)",10,814)
    setting(content,"matchLinks","Match text inside WoW links",10,842)
    label(content,"General",12,884,"GameFontNormalLarge")
    setting(content,"showCount","Show a count of hidden messages in this panel",10,910)
    setting(content,"notices","Print a notice when settings change",10,938)
    countLabel = label(content,"",12,973,"GameFontHighlightSmall")
    StaticPopupDialogs.HITS_RESET = {
        text="Reset Head In The Sand to its defaults? Your phrase list will be replaced.",
        button1=YES,button2=NO,OnAccept=function() HITS.Reset(); feedback:SetText("Defaults restored.") end,
        timeout=0,whileDead=true,hideOnEscape=true,preferredIndex=3,
    }
    button(content,"Reset Defaults",396,978,146,function() StaticPopup_Show("HITS_RESET") end)
    panel:SetScript("OnShow",HITS.Refresh)
    if Settings and type(Settings.RegisterCanvasLayoutCategory) == "function"
        and type(Settings.RegisterAddOnCategory) == "function"
        and type(Settings.OpenToCategory) == "function" then
        local category = Settings.RegisterCanvasLayoutCategory(panel,panel.name)
        Settings.RegisterAddOnCategory(category)
        HITS.category = category
        HITS.settingsAPI = "Settings"
    elseif type(InterfaceOptions_AddCategory) == "function" then
        InterfaceOptions_AddCategory(panel)
        HITS.settingsAPI = "InterfaceOptions"
    else
        HITS.settingsAPI = "unavailable"
    end
    HITS.Refresh()
end
function HITS.OpenSettings()
    if HITS.category and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(HITS.category:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(panel)
        InterfaceOptionsFrame_OpenToCategory(panel)
    else
        HITS.Print("Open Settings > AddOns > Head In The Sand to configure.")
    end
end
