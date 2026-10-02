local passed = 0
local mode = (arg and arg[1]) or "legacy"
local modernCalls, legacyCalls, secureCalls = 0, 0, 0
local function check(value, description)
    assert(value,description); passed=passed+1
end
local frames,filters,messages = {},{},{}
local methods = {}
function methods:SetScript(event,fn) self.scripts[event]=fn end
function methods:GetScript(event) return self.scripts[event] end
function methods:CreateFontString() return CreateFrame('FontString') end
function methods:CreateTexture() return CreateFrame('Texture') end
function methods:SetText(text) self.text=text end
function methods:GetText() return self.text or '' end
function methods:GetStringHeight() return 14 end
function methods:SetChecked(value) self.checked=value end
function methods:GetChecked() return self.checked end
function methods:SetVerticalScroll(v) self.scroll=v end
function methods:GetVerticalScroll() return self.scroll or 0 end
function methods:Show() self.shown=true; if self.scripts.OnShow then self.scripts.OnShow(self) end end
function methods:Hide() self.shown=false end
function CreateFrame(kind,name,parent,template)
    local f = setmetatable({kind=kind,name=name,parent=parent,template=template,scripts={},scroll=0,text="",checked=false},
        {__index=function(_,key) return methods[key] or function() end end})
    frames[#frames+1]=f
    return f
end
UIParent={}; YES='Yes'; NO='No'; StaticPopupDialogs={}; SlashCmdList={}
DEFAULT_CHAT_FRAME={AddMessage=function(_,msg) messages[#messages+1]=msg end}
ChatFrame_AddMessageEventFilter=function(event,filter)
    legacyCalls=legacyCalls+1; filters[event]=filter
end
if mode == "modern" then
    ChatFrameUtil={AddMessageEventFilter=function(event,filter)
        modernCalls=modernCalls+1; filters[event]=filter
    end}
    securecallfunction=function(fn,...) secureCalls=secureCalls+1; return fn(...) end
elseif mode == "missing_filters" then
    ChatFrame_AddMessageEventFilter=nil
end
GetBuildInfo=function() return "1.60.1","70124","Oct 2026",16001 end
Settings={RegisterCanvasLayoutCategory=function(panel,name)
    return {GetID=function() return 99 end}
end,RegisterAddOnCategory=function() end,OpenToCategory=function(id) Settings.last=id end}
local legacyOpened
if mode == "legacy_settings" or mode == "partial_settings" then
    if mode == "legacy_settings" then Settings=nil
    else Settings.RegisterAddOnCategory=nil end
    InterfaceOptions_AddCategory=function(panel) end
    InterfaceOptionsFrame_OpenToCategory=function(panel) legacyOpened=panel.name end
end
function StaticPopup_Show(id) StaticPopupDialogs[id].OnAccept() end
local H={}
assert(loadfile('HeadInTheSand/HeadInTheSand.lua'))('HeadInTheSand',H)
assert(loadfile('HeadInTheSand/HeadInTheSand_UI.lua'))('HeadInTheSand',H)
frames[1].scripts.OnEvent(frames[1],'ADDON_LOADED','OtherAddon')
check(HITS_DB==nil,'unrelated load ignored')
frames[1].scripts.OnEvent(frames[1],'ADDON_LOADED','HeadInTheSand')
check(HITS_DB.chinese and HITS_DB.korean,'language defaults')
check(#HITS_DB.words==2 and not HITS_DB.channels.guild,'defaults initialized')
if mode == "missing_filters" then
    check(H.filterAPI == "unavailable" and next(filters)==nil,'missing API reported')
else
    check(filters.CHAT_MSG_CHANNEL and filters.CHAT_MSG_BN_WHISPER,'events registered')
end
if mode == "modern" then
    check(modernCalls>0 and legacyCalls==0,'modern API preferred when both exist')
    check(secureCalls==modernCalls,'registration uses secure dispatcher')
end
SlashCmdList.HEADINTHESAND('')
if mode == "legacy_settings" or mode == "partial_settings" then
    check(legacyOpened=='Head In The Sand','legacy/partial Settings falls back')
else
    check(Settings.last==99,'slash opens Settings')
end
local messageCount=#messages
SlashCmdList.HEADINTHESAND('status'); check(#messages==messageCount+1,'status prints')
SlashCmdList.HEADINTHESAND('debug')
check(messages[#messages]:find('16001',1,true),'debug includes actual Forever interface')
check(messages[#messages]:find(H.filterAPI,1,true),'debug identifies selected chat API')
local function filter(text,event,id,line)
    return H.Filter({},event or 'CHAT_MSG_CHANNEL',text,'Author',
        'Common','channel','', '', id or 2, 8, id == 46 and 'Trade (Local) - City' or 'Name', 0, line or 100)
end
check(not filter('hello adventurer'),'ordinary English allowed')
check(filter('ANAL joke'),'case-insensitive block')
check(filter('analysis'),'documented substring match')
check(not filter('anal','CHAT_MSG_GUILD'),'unchecked guild word passes')
check(filter('中文','CHAT_MSG_GUILD'),'Han globally blocked')
check(filter('안녕하세요','CHAT_MSG_PARTY'),'Hangul globally blocked')
check(filter('ᄀ'),'Jamo blocked')
check(filter('ꥠ'),'extended Jamo blocked')
check(filter('𠀀'),'supplementary Han blocked')
check(filter(string.char(255)..'中文'),'malformed prefix cannot hide Han')
check(not filter(string.char(192,128,237,160,128)),'invalid UTF8 not decoded as valid')
HITS_DB.chinese=false; check(not filter('中文'),'Chinese toggle honored')
check(filter('한'),'Korean independently enabled')
HITS_DB.korean=false; check(not filter('한'),'Korean toggle honored')
local link='Did someone say |cffff8000|Hitem:19019:0:0|h[Thunderfury, Blessed Blade]|h|r?'
check(filter(link),'item label blocked')
HITS_DB.matchLinks=false; check(not filter(link),'link-label exclusion works')
check(filter('anal '..link),'surrounding text still blocked')
HITS_DB.matchLinks=true
check(not filter('|Hitem:anal:0|h[Ordinary Sword]|h'),'hidden IDs ignored')
check(filter('a|cffff0000na|rl'),'color markup stripped')
check(H.AddWord(' a.b% '),'literal word added and trimmed')
check(filter('a.b%'),'literal symbols match')
check(not filter('axb%'),'pattern wildcard not used')
check(not H.AddWord('A.B%'),'case-insensitive duplicate rejected')
HITS_DB.ignoreCase=false
check(not filter('ANAL'),'case-sensitive enabled')
HITS_DB.ignoreCase=true
check(H.ChannelKey('CHAT_MSG_CHANNEL',42,'Whatever')=='services','static Services ID')
check(H.ChannelKey('CHAT_MSG_CHANNEL',22,'Whatever')=='localDefense','static defense ID')
check(H.ChannelKey('CHAT_MSG_CHANNEL',0,'Trade (Services)')=='services','Services fallback')
check(H.ChannelKey('CHAT_MSG_CHANNEL',0,'General - City')=='general','General fallback')
check(H.ChannelKey('CHAT_MSG_CHANNEL',0,'MyCustom')=='other','custom classified')
check(H.ChannelKey('CHAT_MSG_CHANNEL',46,'Trade (Local) - City')=='trade','Forever Trade Local routed')
TRADE_LOCAL='Commerce (Local)'
check(H.ChannelKey('CHAT_MSG_CHANNEL',46,'Commerce (Local) - Ville')=='trade','localized Trade Local routed')
TRADE_LOCAL=nil
check(filter('anal','CHAT_MSG_CHANNEL',46),'Forever public trade filtering enabled')
HITS_DB.channels.trade=false
check(not filter('anal','CHAT_MSG_CHANNEL',46),'Trade checkbox controls local trade')
HITS_DB.channels.trade=true
HITS_DB.channels.trade=false; check(not filter('anal'),'trade disabled independent of /number')
HITS_DB.channels.trade=true
local before=H.hidden
filter('anal',nil,2,555); filter('anal',nil,2,555)
check(H.hidden==before+1,'multiple chat windows counted once')
HITS_DB.enabled=false; check(not filter('anal'),'master pause')
HITS_DB.enabled=true
issecretvalue=function(value) return value=='secret' end
check(not filter('secret'),'secret message passed through'); issecretvalue=nil
HITS_DB.words={}; H.Initialize(); check(#HITS_DB.words==0,'empty saved list stays empty')
HITS_DB.channels.guild=true; H.Initialize(); check(HITS_DB.channels.guild,'saved setting preserved')
-- Exercise actual UI control callbacks, not just core helpers.
local function findButton(text)
    for _,f in ipairs(frames) do if f.text==text and f.kind=='Button' then return f end end
end
local edit
for _,f in ipairs(frames) do if f.kind=='EditBox' then edit=f end end
edit:SetText('wts boost'); edit.scripts.OnEnterPressed(edit)
check(HITS_DB.words[1]=='wts boost' and edit:GetText()=='','UI Enter adds phrase')
local remove=findButton('Remove'); remove.scripts.OnClick(remove)
check(#HITS_DB.words==0,'UI Remove updates DB')
HITS_DB.words={'keep'}
local reset=findButton('Reset Defaults'); reset.scripts.OnClick(reset)
check(#HITS_DB.words==2 and HITS_DB.chinese and not HITS_DB.channels.guild,'UI confirmed reset')
local n=0
for _,f in ipairs(frames) do
    if f.kind=='CheckButton' then
        f:SetChecked(false); f.scripts.OnClick(f); n=n+1
    end
end
check(n==22,'all checkbox handlers execute')
check(not HITS_DB.enabled and not HITS_DB.chinese and not HITS_DB.matchLinks,'checkboxes bind to DB')
HITS_DB.words={'',5,' phrase ','phrase'}; H.Initialize()
check(#HITS_DB.words==1 and HITS_DB.words[1]=='phrase','invalid saved entries sanitized')
print('PASS ['..mode..']: '..passed..' assertions; all UI checkbox handlers and slash entry tested.')
