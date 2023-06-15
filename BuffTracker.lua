BuffTracker = LibStub("AceAddon-3.0"):NewAddon("BuffTracker","AceEvent-3.0","AceConsole-3.0");

local print,unpack,strsplit,next,pairs,tonumber, select = _G.print,_G.unpack,_G.strsplit,_G.next,_G.pairs,_G.tonumber,_G.select
local table_wipe, table_insert,table_remove = _G.table.wipe,_G.table.insert,_G.table.remove
local UnitName, GetSpellInfo, UnitIsGhost, GetTime, UnitAura, IsInInstance, UnitBuff = _G.UnitName, _G.GetSpellInfo, _G.UnitIsGhost, _G.GetTime, _G.UnitAura, _G.IsInInstance, _G.UnitBuff

local PlayerName = UnitName("player")
local isDeadUpdateStop = false
local instanceType = nil
local BuffListOnPlayer = {}


function BuffTracker:contains(table, element)
	for i, value in pairs(table) do
		if (value == element) then return true, i end
	end
	return false
end

function BuffTracker:Print(...) print("|cFFED8E41[BuffTracker]:|r", ...) end

local defaults = {
    class = {
        firstRun = true,
        disabled = false,
        locked   = false,
        isShown  = false,
        throttle = 0.3,
        AuraList = {},
        frames = {
            anchor_green = {
                enabled         = false,
                coords          = {591.99983975689, 322.61874416364},
                size            = 0.5,
                direction       = 1,                             
                distance        = 90,
                duration        = 1.5,
                eScale          = nil,
                ignoreAuaras    = true,
                ignoreStacks    = true,
                borderColor     = {0.2235294117647059, 0.7843137254901961,  0.054901960784313725},
                AnimationStages = {},
                IgnoredSpellID  = {},
                NeedRecompile   = false,
                opacity         = 0.75,
                showLog         = true
            },
            anchor_blue  = {
                enabled         = true,
                coords          = {726.86671938963, 322.06168122088},
                size            = 0.5,
                direction       = 1, 
                distance        = 120,
                duration        = 2.5,
                eScale          = nil,
                ignoreAuaras    = true,
                ignoreStacks    = false,
                borderColor     = {0.0, 0.4392156862745098, 0.8666666666666667},
                AnimationStages = {}, 
                IgnoredSpellID  = {},
                NeedRecompile   = false,
                opacity         = 0.75,
                showLog         = true
            },
            anchor_red   = {
                enabled         = true,
                coords          = {659.73350588294, 293.63768952566},
                size            = 0.5,
                direction       = -1,
                distance        = 150,
                duration        = 2,
                eScale          = nil,
                ignoreAuaras    = true,
                ignoreStacks    = true,
                borderColor     = {0.8862745098039215, 0.20392156862745098, 0.03529411764705882},
                AnimationStages = {},
                IgnoredSpellID  = { 48156, 57399, 57073 },
                NeedRecompile = false,
                opacity       = 0.75,
                showLog       = true
            },
             anchor_brown   = {
                enabled         = true,
                coords          = {659.73350588294, 293.63768952566},
                size            = 0.5,
                direction       = -1,
                distance        = 150,
                duration        = 2,
                eScale          = nil,
                ignoreAuaras    = true,
                ignoreStacks    = true,
                borderColor     = {0.5137254901960784, 0.2392156862745098, 0.04705882352941176},
                AnimationStages = {},
                IgnoredSpellID  = {},
                NeedRecompile = false,
                opacity       = 0.75,
                showLog       = true
            },
        },
    }
}


BuffTracker.Config = {
    iconWidth     = 64;
    backdrop      = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,},
    frameColor    = {0,0,0,.6},
    borderTexture = "Interface\\AddOns\\BuffTracker\\media\\UI-ActionButton-Border.blp",
    anchorPrefix  = "BuffTrackerAnchor",
    iconPrefix    = "BuffTrackerIcon",
    ["red_desc"]    =  "Removed\nfrom\nplayer",
    ["green_desc"]  =  "Applied\non\nplayer",
    ["blue_desc"]   =  "Removed\nby\nplayer",
    ["brown_desc"]  =  "Removed\ndebuff from\nplayer",

}

BuffTracker.SequenceData = {
    stateObserver = CreateFrame("Button", "BuffTrackerStateObserver", UIParent),
    ["red"]    = {lastCall = nil,calls = 0,queueList = {}},
    ["green"]  = {lastCall = nil,calls = 0,queueList = {}},
    ["blue"]   = {lastCall = nil,calls = 0,queueList = {}},
    ["brown"]  = {lastCall = nil,calls = 0,queueList = {}},
}




function BuffTracker:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("BuffTrackerDB", defaults, true)
    BuffTracker:Print("INIT")
    self:SetupOptions()
end


function BuffTracker:OnEnable()
    local db = self.db.class;
    if db.firstRun or db.isShown then
        BuffTracker:initAnchors()
        db.firstRun  = false;
    end
    
    self:RegisterEvent("PLAYER_DEAD")
    self:RegisterEvent("PLAYER_UNGHOST")
    self:RegisterEvent("PLAYER_ALIVE")
    if db.frames["anchor_red"].enabled or db.frames["anchor_green"].enabled or db.frames["anchor_brown"].enabled then
        self:RegisterEvent("COMBAT_LOG_EVENT")
    end
    if db.frames["anchor_blue"].enabled then
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end

    self:RegisterChatCommand("BTR","CMD_BUFF_TRACKER");
    self:RegisterChatCommand("BUFFTRACKER","CMD_BUFF_TRACKER");
    
end



--------------------------------------------------------------
-- DIALOG - - - - - - - - - - - - - - - - - - - - - - - - - - 
--------------------------------------------------------------
function BuffTracker:CMD_BUFF_TRACKER(arg)
    local args, i = {}, 1;
    for s in arg:gmatch("%S+") do args[i] = s; i = i + 1; end;

    if args[1] == "test" then
        if not args[2] then
            BuffTracker:SequenceBroker("red", "Interface\\Icons\\Spell_Holy_InnerFire") 
        else
            BuffTracker:SequenceBroker(args[2], "Interface\\Icons\\Spell_Holy_InnerFire")
        end
    elseif args[1] == "show" then
        BuffTracker:ShowAnchors()
    elseif not args[1] then
        BuffTracker:ShowOptions()
    end
end

-------------------------------------------------------------
-- EVENTS - - - - - - - - - - - - - - - - - - - - - - - - - -
-------------------------------------------------------------
function BuffTracker:ZONE_CHANGED_NEW_AREA()
    local itype = select(2, IsInInstance())
    if itype == "arena" then
		instanceType = itype
	elseif itype ~= "arena" and instanceType == "arena" then
		instanceType = nil
	end
end


function BuffTracker:COMBAT_LOG_EVENT_UNFILTERED(...)
    if isDeadUpdateStop then return end
    local eventName,_,subEventName,_,SourceUName,_,_,destUName,_,SourceSpellID,SourceSpellNameL,_,DestSpellID, DestSpellNameOutL,_,buffType  = ...
    if subEventName:match("DISPEL") and not subEventName:match("FAILED") then
        if SourceUName == PlayerName and destUName ~= PlayerName then
            local name,_,texture = GetSpellInfo(DestSpellID)
            if self.db.class.frames.anchor_blue.showLog then
                local logInfo = "BUFF PURGED:"
                BuffTracker:Print(logInfo, DestSpellID, name)
            end
            BuffTracker:SequenceBroker("blue", texture)
        end
    end
end

function BuffTracker:AuraSearch(spellName)
    local AuraList = self.db.class.AuraList
    local aura,_,_,_,_,_,expTime,_,_,_,spellID = UnitAura("player", spellName)
    if expTime == 0 then
        if not BuffTracker:contains(AuraList, aura) then
            table_insert(AuraList, aura)
            return
        end
    end
end

function BuffTracker:COMBAT_LOG_EVENT(...)
    if isDeadUpdateStop then return end
    local source,_,eventType,_,sourceName,_,_,destName,_,spellID,spellName,_,arg1, debffName, _, auraType = ...;
    if not spellID then return end;
    local eventTypesMap = {
        ["APPLIED"] = "green",
        ["REMOVED"] = "red",
        ["DISPEL"]  = "brown",
    }
    local db = self.db.class
    for k,v in pairs(eventTypesMap) do
        local e = eventType:match(k)
        
        if e then 
            local isDispel = e == "DISPEL";
            if isDispel then
                if eventType:match("FAILED") then return end
                spellID   = arg1
                spellName = debffName
            else
                auraType = arg1;
            end

            local anchorData = db.frames["anchor_"..eventTypesMap[e]];
            if anchorData.ignoreAuaras then
                if e == "APPLIED" then BuffTracker:AuraSearch(spellName) end
            end

            if anchorData.enabled and auraType == "BUFF" then
                if BuffTracker:contains(anchorData.IgnoredSpellID, spellID) then return end;
                if destName == PlayerName then
                    local _,_,texture = GetSpellInfo(spellID)
                    if anchorData.ignoreAuaras then
                        if BuffTracker:contains(db.AuraList, spellName) then return end;
                    end

                    if anchorData.showLog then
                        local logInfo = nil
                        if     
                                   eventTypesMap[e] == "red"   then  logInfo = "BUFF OUT:"
                            elseif eventTypesMap[e] == "green" then  logInfo = "BUFF APPLIED:"
                            elseif eventTypesMap[e] == "brown" then  logInfo = "DEBUFF REMOVED:"
                        end
                        BuffTracker:Print(logInfo,spellID, spellName)
                    end

                    local isContais, pos = BuffTracker:contains(BuffListOnPlayer, spellName)

                    if  e == "APPLIED" then
                        if not isContais then
                            table_insert(BuffListOnPlayer, spellName)
                        else
                            if anchorData.ignoreStacks then
                                return
                            end

                        end
                
                    elseif e == "REMOVED" then
                        local _,_,_,stacks = UnitBuff("player", spellName)
                        if not (type(stacks) == "number" and stacks > 1) then 
                            local el = table_remove(BuffListOnPlayer, pos)
                        end
                    elseif e == "DISPEL" then
                        --
                    end


                    BuffTracker:SequenceBroker(eventTypesMap[e], texture)
                end


            end
        end
    end

end

function BuffTracker:PLAYER_DEAD()    isDeadUpdateStop = true end
function BuffTracker:PLAYER_UNGHOST() isDeadUpdateStop = false end
function BuffTracker:PLAYER_ALIVE()   BuffTracker:CheckIfPlayerIsGhost(); end
function BuffTracker:CheckIfPlayerIsGhost()
    if UnitIsGhost("player") then
		isDeadUpdateStop = true;
	else
		isDeadUpdateStop = false;
    end
end


function BuffTracker:SequenceBroker(anchorTypeName, texture)
    local SQD = BuffTracker.SequenceData[anchorTypeName]
    local db = self.db.class;

    if not SQD.lastCall then
        SQD.lastCall = GetTime()
        SQD.calls    = SQD.calls + 1
        BuffTracker:Animate(anchorTypeName, texture)
    else
        local currentCall = GetTime()
        local diffTime = currentCall - SQD.lastCall
        if diffTime > db.throttle then
            SQD.lastCall   = currentCall
            SQD.calls      = SQD.calls + 1
            BuffTracker:Animate(anchorTypeName, texture)
        else
            local queueData = {anchorTypeName, texture, currentCall}
            table_insert(SQD.queueList, queueData);
            BuffTracker.SequenceData.stateObserver:SetScript("OnUpdate", function()
                local currentCall = GetTime()
                local diffTime    = currentCall - SQD.lastCall
                
                if diffTime > db.throttle then
                
                    if #SQD.queueList >= 1 and SQD.queueList[1][2] and not isDeadUpdateStop then
                        SQD.lastCall  = currentCall
                        SQD.calls     = SQD.calls + 1
                        BuffTracker:Animate(SQD.queueList[1][1], SQD.queueList[1][2])
                        table_remove(SQD.queueList, 1)
                    else
                        table_wipe(SQD.queueList)
                        SQD.calls = 0
                        BuffTracker.SequenceData.stateObserver:SetScript("OnUpdate", nil)
                    end

                end
            end)
        end  

    end
end