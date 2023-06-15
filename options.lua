local BuffTracker = BuffTracker
if not BuffTracker then return end

local unpack = _G.unpack

local currentAnchorEditing = "red"

local function wrapColorString(str, rgbcolor)
    local before, after = "|cff", "|r";
    for i, v in ipairs(rgbcolor) do
        before = before..string.format("%02x", rgbcolor[i] * 256)
    end
    before = before..str..after

    return before;
end
local wcs = wrapColorString;


function BuffTracker:SetupOptions()
    local db = self.db.class
    local curentFrameDB = db.frames["anchor_"..currentAnchorEditing]
    local cred, cblue, cgreen, cbrown = db.frames.anchor_red.borderColor, db.frames.anchor_blue.borderColor, db.frames.anchor_green.borderColor, db.frames.anchor_brown.borderColor

    self.options = {
        type = "group",
        name = "BuffTracker v1.0",
        childGroups = 'tab',
        args = {
            main = {
                type = "group",
                name = "Anchor and icon settings",
                order = 1,
                args = {
                    subtitle = {
                        name = "|cCCCCCCCCAddon by Nobrain from Sirus.su|r",
                        type = "description",
                        width = "full",
                        order = 1,
                    },
                    marginb = {
                        name = " ",
                        type = "description",
                        width = "full",
                        order = 1.1,
                    },
                    showAnchors = {
                        name = 'Show anchors',
                        type = 'toggle',
                        desc = 'Show / Hide anchors for positioning',
                        order = 1.2,
                        set = function() return BuffTracker:ShowAnchors() end,
                        get = function() return db.isShown end
                    },
                    typeHeader = {
                        name  = '',
                        order = 2,
                        type  = "header",
                    },
                    selectFrame = {
                        name   = "Select anchor to edit:",
                        type   = "select",
                        order  = 3,
                        desc   = wcs("[Red] ",cred).."Removed buff from player\n"..wcs("[Blue] ",cblue).."Removed by player\n"..wcs("[Green] ",cgreen).."Applied on player\n"..wcs("[Brown] ",cbrown).."Removed debuff from player",
                        width  = "1.8",
                        values = function()
                            return {
                                ["red"]   = wcs("[Red]   ",cred).."Removed buff from player",
                                ["blue"]  = wcs("[Blue]  ",cblue).."Removed by player",
                                ["green"] = wcs("[Green] ",cgreen).."Applied on player",
                                ["brown"] = wcs("[Brown] ",cbrown).."Removed debuff from player",
                            }
                        end,
                        get = function() return currentAnchorEditing end,
                        set = function(info, val)
                            currentAnchorEditing = val
                            curentFrameDB = db.frames["anchor_"..currentAnchorEditing]
                        end
                    },
                    isEnabled = {
                        name  = 'Enable frame',
                        type  = 'toggle',
                        desc  = 'Enable / Disable anchor',
                        order = 4,
                        set   = function(i, val)
                            curentFrameDB.enabled = val 
                            return BuffTracker:ShowAnchors(currentAnchorEditing)
                        end,
                        get   = function() 
                            return curentFrameDB.enabled
                        end
                    },
                    testFrame = {
                        name = "Test animation",
                        type = "execute",
                        order= 6,
                        disabled = function() return not curentFrameDB.enabled end,
                        func = function()
                            if curentFrameDB.enabled then
                                BuffTracker:SequenceBroker(currentAnchorEditing, "Interface\\Icons\\Spell_Holy_InnerFire")
                            end
                        end
                    }, 
                    margin = {
                        name = " ",
                        type = "description",
                        width = "full",
                        order = 7,
                    },
                    anchorSettings = {
                        name        = "Anchor settings:",
                        inline      = true,
                        type        = "group",
                        childGroups = 'tab',
                        disabled    = function() return not curentFrameDB.enabled end,
                        order       = 8,
                        args        = {
                            anchorDirection = {
                                name = "Animation direction",
                                desc = "Choose direction of animation",
                                type = "select",
                                order = 2,
                                values = function()
                                    return {
                                        ["1"]  = "Up",
                                        ["-1"] = "Down",
                                        ["2"]  = "Right",
                                        ["-2"] = "Left",
                                    }
                                end,
                                set = function(i,val) 
                                    curentFrameDB.direction = val
                                    curentFrameDB.NeedRecompile = true 
                                end,
                                get = function() 
                                    return tostring(curentFrameDB.direction) 
                                end,
                            },
                            margin1 = {
                                name = "",
                                type = "description",
                                width = "half",
                                order = 3.1,
                            },
                            borderColor = {
                                name = "Border color",
                                type = "color",
                                width = "half",
                                order = 3.2,
                                disabled = function()
                                    return true
                                end,
                                set = function(info,nr,ng,nb) 
                                    curentFrameDB.borderColor = { nr, ng, nb }
                                    BuffTracker:SetColor(currentAnchorEditing)
                                end,
                                get = function() return unpack(curentFrameDB.borderColor) end
                            },
                            iconOpacity = {
                                name = "Animated Icon opacity:",
                                type = "range",
                                min = 0,
                                max = 100,
                                step = 5,
                                order = 3,
                                get = function()
                                    return curentFrameDB.opacity * 100
                                end,
                                set = function(i,val)
                                    curentFrameDB.opacity = val / 100
                                end
                            },
                            anchorSize = {
                                name = "Icon size",
                                type = "range",
                                min = 0.25,
                                max = 5,
                                step = 0.25,
                                order = 4,
                                get = function()
                                    return curentFrameDB.size 
                                end,
                                set = function(i,val)
                                    curentFrameDB.size = val
                                    BuffTracker:SetSize(currentAnchorEditing,val)
                                end
                            },
                            anchorDuration = {
                                name = "Animation duration",
                                type = "range",
                                min = 0.5,
                                max = 10,
                                order = 5,
                                step = 0.25,
                                get = function()
                                    return curentFrameDB.duration 
                                end,
                                set = function(i,val)
                                    curentFrameDB.duration = val
                                    curentFrameDB.NeedRecompile = true
                                end
                            },
                            acnhorDistance = {
                                name = "Distance",
                                type = "range",
                                min = 5,
                                max = 1000,
                                order = 6,
                                step = 5,
                                get = function()
                                    return curentFrameDB.distance 
                                end,
                                set = function(i,val)
                                    curentFrameDB.distance = val
                                    curentFrameDB.NeedRecompile = true
                                end
                            }
                        }
                    },
                    margin2 = {
                        name = " ",
                        type = "description",
                        width = "full",
                        order = 9,
                    },
                    spellSettings = {
                        name        = "Spell settings:",
                        inline      = true,
                        type        = "group",
                        childGroups = 'tab',
                        order       = 10,
                        disabled    = function() return not curentFrameDB.enabled end,
                        args        = {
                            ignoreAuaras = {
                                name = 'Ignore auras',
                                type = 'toggle',
                                desc = 'Ignore auras which is can not be purged from you.',
                                order = 1,
                                hidden = function()
                                    return currentAnchorEditing == "brown"
                                end,
                                get = function()
                                    return curentFrameDB.ignoreAuaras
                                end,
                                set = function(i,val)
                                    curentFrameDB.ignoreAuaras = val
                                end
                            },
                            ignoreStacks = {
                                name = 'Ignore stacks',
                                type = 'toggle',
                                desc = 'Ignore stacks that can be increase or decrease and spawn icons with that.',
                                order = 2,
                                hidden = function()
                                    return currentAnchorEditing == "blue" or currentAnchorEditing == "brown"
                                end,
                                get = function()
                                    return curentFrameDB.ignoreStacks
                                end,
                                set = function(i,val)
                                    curentFrameDB.ignoreStacks = val
                                end
                            },
                            ignoreSpellID = {
                                name = 'Ignore spell ID',
                                type = 'input',
                                desc = 'Type spell ID\'s which is separates by commas',
                                width = 'full',
                                order = 3,
                                get = function()
                                    return string.join(", ",tostringall(unpack(curentFrameDB.IgnoredSpellID)))
                                end,
                                set = function(i,val)
                                    local tbl = {}
                                    for d in val:gmatch("(%d+)") do
                                        if not BuffTracker:contains(tbl, tonumber(d)) then
                                            table.insert(tbl, tonumber(d))
                                        end
                                    end
                                    curentFrameDB.IgnoredSpellID = tbl;
                                end
                            },
                            showLog = {
                                name  = 'Show logs in chat',
                                type  = 'toggle',
                                desc  = 'Output info about detected spell in chat. Recived info can be used to ignore some spells by ID, for instance',
                                order = 2,
                                set   = function(i, val) 
                                    curentFrameDB.showLog = not curentFrameDB.showLog
                                end,
                                get   = function() 
                                    return curentFrameDB.showLog
                                end
                            },
                        }
                    },
                }
            },
            createNew = {
                type = "group",
                name = "Add new icon",
                order = 2,
                args = {
                    empty = {
                        name = "Work in progress. That feature has not been released yet",
                        type = "description",
                    }
                }
            }
          
        }
    }


    local db = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("BuffTracker", self.options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("BuffTracker", "BuffTracker")
end

function BuffTracker:ShowOptions()
    InterfaceOptionsFrame_OpenToCategory("BuffTracker")
end