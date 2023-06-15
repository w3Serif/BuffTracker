local BuffTracker = BuffTracker
local print,unpack,next = _G.print,_G.unpack,_G.next

local Elements = {
    AcnchorsIsInit = false,
    ["queue"] = {
        ["ID_COUNTER"] = {red = 1, green = 1, blue = 1, brown = 1},
        ["red"]   = {},
        ["green"] = {},
        ["blue"]  = {},
        ["brown"] = {}
    },
    ["anchors"] = {},
    ["icons"]   = {},
    ["callStackCounter"] = {
        ["red"] = 0, ["green"] = 0, ["blue"] = 0, ["brown"] = 0
    }
}
function Elements:getCounter(IconType)
    local counter = self["queue"]["ID_COUNTER"][IconType]
    self["queue"]["ID_COUNTER"][IconType] = counter + 1;
    return counter
end

--------------------------------------------------------------
-- FRAME - - - - - - - - - - - - - - - - - - - - - - - - - - -
--------------------------------------------------------------
function BuffTracker:initAnchors()
    local _texture = "Interface\\Icons\\Spell_Shadow_SealOfKings"
    local db = self.db.class
    local lockedAnchors = {
        ["red"]   = db.frames["anchor_red"].enabled,
        ["green"] = db.frames["anchor_green"].enabled,
        ["blue"]  = db.frames["anchor_blue"].enabled,
        ["brown"] = db.frames["anchor_brown"].enabled,
    }

    for k,v in pairs(lockedAnchors) do
        table.insert(Elements["anchors"], BuffTracker:CreateAnchor(BuffTracker.Config.anchorPrefix, k, v))
        BuffTracker:CreateIcon(k, _texture, 0, true, not v)
    end

    
    self.db.class.isShown   = true;
    self.db.class.firstRun  = false;
    Elements.AcnchorsIsInit = true;
end

function BuffTracker:ShowAnchors(pAnchor)
    local db = self.db.class
    
    if pAnchor then
        if db.isShown then
            if db.frames["anchor_"..pAnchor].enabled then
                _G[BuffTracker.Config.anchorPrefix.."_"..pAnchor]:Show();
                _G[BuffTracker.Config.iconPrefix.."_"..pAnchor.."_0"]:Show();
            else
                _G[BuffTracker.Config.anchorPrefix.."_"..pAnchor]:Hide();
                _G[BuffTracker.Config.iconPrefix.."_"..pAnchor.."_0"]:Hide();
            end
        end
    else
        if not Elements.AcnchorsIsInit then
            BuffTracker:initAnchors()
        else
            local pattern = "_(%w+)$";
            local function toggle(i, anchor)
                local AnchorFrame = _G[BuffTracker.Config.iconPrefix.."_"..anchor.."_0"]
                if db.isShown then 
                    AnchorFrame:Hide()
                    Elements["anchors"][i]:Hide() 
                else 
                    AnchorFrame:Show()
                    Elements["anchors"][i]:Show() 
                end
            end;
            
            for i=1, #Elements["anchors"] do
                local anchor = Elements["anchors"][i]:GetName():match(pattern);
                if db.frames["anchor_"..anchor].enabled then toggle(i, anchor) end
            end
            db.isShown = not db.isShown;
        end

    end

    return db.isShown;
end


function BuffTracker:SetDraggable(frame, anchorName, FramePrefixName )
    frame:EnableMouse(true)
	frame:SetMovable(true)
    self.db.class.locked = false
    local _db = self.db

    frame:RegisterForDrag("LeftButton")
    
    frame:SetScript('OnDragStart', function(self)
		if (not InCombatLockdown() and not _db.class.locked) then frame:StartMoving() end
	end)

    frame:SetScript('OnDragStop', function()
		if (not InCombatLockdown()) then
			frame:StopMovingOrSizing()
            local scale = frame:GetEffectiveScale()
            self.db.class.frames["anchor_"..anchorName].coords[1] = frame:GetLeft() * scale
            self.db.class.frames["anchor_"..anchorName].coords[2] = frame:GetTop()  * scale
        end
    end)
end


function BuffTracker:SetColor(anchorName)
    local db  = self.db.class
    local anchorData = db.frames["anchor_"..anchorName]
    local color  = anchorData.borderColor
    local prefix = BuffTracker.Config.iconPrefix.."_"..anchorName;
    local border = _G[prefix.."_0_border"]
    border:SetVertexColor(unpack(color))

    local iconsLen = Elements["queue"]["ID_COUNTER"][anchorName];
    for i=1, iconsLen do
        local iconQueueFrame = _G[prefix.."_"..i.."_border"];
        if iconQueueFrame then 
            iconQueueFrame:SetVertexColor(unpack(color))
        end
    end
end


function BuffTracker:SetSize(anchorName, size)
    local db  = self.db.class
    local anchorData = db.frames["anchor_"..anchorName]
    local pos = anchorData.coords;

    local AnchorFrame = _G["BuffTrackerAnchor_"..anchorName]
    AnchorFrame:ClearAllPoints()
    AnchorFrame:SetScale(db.frames["anchor_"..anchorName].size)

    local scale = AnchorFrame:GetEffectiveScale()
    anchorData.eScale = scale;
    AnchorFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos[1]/scale, pos[2]/scale)

    local IconFrame = _G[BuffTracker.Config.iconPrefix.."_"..anchorName.."_0"]
    IconFrame:ClearAllPoints()
    IconFrame:SetPoint("CENTER", AnchorFrame, "CENTER")
    IconFrame:SetScale(db.frames["anchor_"..anchorName].size)

    local iconsLen = Elements["queue"]["ID_COUNTER"][anchorName];
    for i=1, iconsLen do
        local iconQueueFrame = _G[BuffTracker.Config.iconPrefix.."_"..anchorName.."_"..i];
        if iconQueueFrame then 
            iconQueueFrame:SetScale(db.frames["anchor_"..anchorName].size)
        end
    end

end



function BuffTracker:CreateBorder(frame, anchor, frameName)
    local db  = self.db.class
    local frameData = db.frames["anchor_"..anchor]
    local borderName = frameName.."_border";
    local border = frame:CreateTexture(borderName, "OVERLAY")
    local bSize  = BuffTracker.Config.iconWidth * 2;
    border:SetTexture(BuffTracker.Config.borderTexture);
    border:SetWidth(bSize)
	border:SetHeight(bSize)
    border:SetPoint("CENTER", frame, "CENTER")
    border:SetBlendMode("ADD");
    border:SetVertexColor(unpack(frameData.borderColor))
    return border;
end

function BuffTracker:CreateIcon(anchorTypeName, texture, id, isConfig, enable)
    local id = id or 1;
    local db  = self.db.class
    local anchorData = db.frames["anchor_"..anchorTypeName]
    local size       = anchorData.size;
    local pos        = anchorData.coords;
    local iconFrameName  = BuffTracker.Config.iconPrefix.."_"..anchorTypeName.."_"..id;
    local anchorFrame = _G[BuffTracker.Config.anchorPrefix.."_"..anchorTypeName];
    local cachedIconFrame = Elements["icons"][iconFrameName]
    if cachedIconFrame then
        local _,relativeTo = cachedIconFrame:GetPoint();
        if not relativeTo and anchorFrame then
            cachedIconFrame:ClearAllPoints()
            cachedIconFrame:SetPoint("CENTER", anchorFrame, "CENTER")
        end
        return cachedIconFrame, iconFrameName, true 
    end

    local IconFrame = CreateFrame("Button", iconFrameName, UIParent)
    IconFrame:SetScale(size)
    IconFrame:SetWidth(BuffTracker.Config.iconWidth)
    IconFrame:SetHeight(BuffTracker.Config.iconWidth)
    IconFrame:SetFrameStrata("BACKGROUND")
    IconFrame:ClearAllPoints()
    IconFrame:SetScale(db.frames["anchor_"..anchorTypeName].size)

    if anchorFrame then
        IconFrame:SetPoint("CENTER", anchorFrame, "CENTER")
    else
        local scale = anchorData.eScale
        IconFrame:SetPoint("TOPLEFT", nil, "BOTTOMLEFT", pos[1]/scale, pos[2]/scale)
    end

    IconFrame.texture = IconFrame:CreateTexture(nil,"BACKGROUND")
    IconFrame.texture:SetAllPoints()
    IconFrame.texture:SetTexCoord(0.06, 0.96, 0.03, 0.93)
    IconFrame.texture:SetAlpha(.7)
    IconFrame.texture:SetTexture(texture)
    if isConfig then
        IconFrame.texture:SetVertexColor(unpack(anchorData.borderColor))
    end
    BuffTracker:CreateBorder(IconFrame, anchorTypeName, iconFrameName)    
    
    if enable then IconFrame:Hide() end 
    return IconFrame, iconFrameName
end


function BuffTracker:CreateAnchor(FramePrefixName, anchorName, isEnable)
    local db  = self.db.class
    local anchorData =  db.frames["anchor_"..anchorName]
    local pos  = anchorData.coords;
    local size = anchorData.size;

    self.anchor = CreateFrame("Button", FramePrefixName.."_"..anchorName, UIParent)
    self.anchor:SetScale(size)
	self.anchor:SetWidth(BuffTracker.Config.iconWidth)
	self.anchor:SetHeight(BuffTracker.Config.iconWidth)
    self.anchor:SetClampedToScreen(true)
    self.anchor:ClearAllPoints()


    local scale = self.anchor:GetEffectiveScale()
    anchorData.eScale = scale;
    self.anchor:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos[1]/scale, pos[2]/scale)
    BuffTracker:SetDraggable(self.anchor, anchorName, FramePrefixName);

    self.anchor.text = self.anchor:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    self.anchor.text:SetText(BuffTracker.Config[anchorName.."_desc"])
    self.anchor.text:SetPoint("CENTER", self.anchor, "CENTER")

    if not isEnable then
        self.anchor:Hide();
    end

    return self.anchor;
end

local function IconQueueManager(iconTypeName, texture, iconID )
    local IconFrameName, IconInstance;
    local QueueStorage = Elements["queue"]
    local iconFrameNamePrefix = BuffTracker.Config.iconPrefix.."_"..iconTypeName
    

    if not next(QueueStorage[iconTypeName]) then
        local isLink;
        local id = Elements:getCounter(iconTypeName);
        IconFrame, IconFrameName, isLink = BuffTracker:CreateIcon(iconTypeName, texture, id);
        if not isLink then Elements["icons"][IconFrameName] = IconFrame end
        IconInstance = IconFrame;
    else
        IconFrameName, IconInstance = next(QueueStorage[iconTypeName]);
        QueueStorage[iconTypeName][IconFrameName] = nil
        IconInstance.texture:SetTexture(texture)
        local anchorName = BuffTracker.Config.anchorPrefix.."_"..iconTypeName
        local anchorFrame = _G[anchorName];

        if anchorFrame then
            local _,relativeTo = IconInstance:GetPoint()
            if not relativeTo or relativeTo:GetName() ~= anchorName then
                IconInstance:ClearAllPoints()
                IconInstance:SetPoint("CENTER", anchorFrame, "CENTER")
            end
        end
    end
    

    return IconInstance, IconFrameName
end


function BuffTracker:Animate(anchorTypeName, texture)
    local QueueStorage = Elements["queue"]
    if not QueueStorage[anchorTypeName] then
        BuffTracker:Print("[Animate error] Wrong name of anchor:", anchorTypeName)
        return false
    end
    
    local db = self.db.class;
    local IconFrame, IconFrameName = IconQueueManager(anchorTypeName, texture)
    local anchorData = db.frames["anchor_"..anchorTypeName];

    local direction, distance, D = anchorData.direction, anchorData.distance, anchorData.duration
    local cache = anchorData.AnimationStages;


    if not cache.D or cache.D ~= D or anchorData.NeedRecompile then
        cache.D = D; cache.K = cache.D * 0.6; cache.trD = cache.D - cache.K;
        cache.aD3 = cache.D - cache.trD; cache.aD2 = cache.D/2; cache.aD = cache.aD2 - cache.K;
        anchorData.NeedRecompile = false
    end

    local iconAnimate = IconFrame:CreateAnimationGroup();
    local translate, alpha, alpha2, alpha3;
    local scale  =  IconFrame:GetEffectiveScale()
    local oX, oY =  IconFrame:GetLeft() * scale, IconFrame:GetTop() * scale;
    local s1 = GetTime();

    IconFrame:SetAlpha(0)
    translate = iconAnimate:CreateAnimation("Path")
        local p1 = translate:CreateControlPoint()
        local p2 = translate:CreateControlPoint() -- without that variable we got fatal error
        translate:SetCurve("SMOOTH")
        translate:SetDuration(cache.trD)
        if direction == "2" or direction == "-2" then
            p1:SetOffset(distance * direction/2, 0)
        else
            p1:SetOffset(0, distance * direction)
        end
        p1:SetOrder(2)

    alpha = iconAnimate:CreateAnimation("Alpha")
        alpha:SetChange(0);
        alpha:SetDuration(cache.aD);
        alpha:SetOrder(1);
        alpha:SetSmoothing("OUT")
    alpha2 = iconAnimate:CreateAnimation("Alpha")
        alpha2:SetChange(anchorData.opacity);
        alpha2:SetDuration(cache.aD2);
        alpha2:SetOrder(1);
    alpha3 = iconAnimate:CreateAnimation("Alpha")
        alpha3:SetChange(-1);
        alpha3:SetDuration(cache.aD3);
        alpha3:SetOrder(3);
        alpha3:SetSmoothing("OUT")

    iconAnimate:Stop();
    iconAnimate:Play();

    iconAnimate:SetScript("OnFinished", function() 
        Elements["queue"][anchorTypeName][IconFrameName] = IconFrame;
        BuffTracker.SequenceData[anchorTypeName].calls = BuffTracker.SequenceData[anchorTypeName].calls - 1;
    end)
    
    return IconFrame;
end
