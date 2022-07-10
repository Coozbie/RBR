local DreamTSLib = _G.DreamTS or require("DreamTS")

---@type SDK_SDK
local SDK = DreamTSLib.TargetSelectorSdk.SDK

---@type SDK_AIHeroClient
local myHero = SDK.Player

if myHero:GetCharacterName() ~= "Sivir" then return end

local Sivir = {}

local update_data = {
    Robur = {
        ScriptName = "CXSivir",
        ScriptVersion = "1.0",
        Repo = "https://raw.githubusercontent.com/Coozbie/RBR/main/"
    }
}

SDK.Common.AutoUpdate(update_data)

local DreamTS = DreamTSLib.TargetSelectorSdk
local Vector = SDK.Libs.Vector
local HealthPred = Libs.HealthPred
local DamageLib = Libs.DamageLib

---@param objects SDK_GameObject[]
---@return SDK_AIHeroClient[]
local function GetHerosFromObjects(objects)
    local res = {}
    for i, obj in ipairs(objects) do
        res[i] = obj:AsHero()
    end
    return res
end

local enemies = GetHerosFromObjects(SDK.ObjectManager:GetEnemyHeroes())

local TargetedSpell = {
    ["Headbutt"]                    = {charName = "Alistar"     , slot = "W" , delay = 0   , speed = 2000       , isMissile = false},   -- seems speed base on distance, no idea with the forumla
    ["Frostbite"]                   = {charName = "Anivia"      , slot = "E" , delay = 0.25, speed = 1600       , isMissile = true },
    ["AnnieQ"]                      = {charName = "Annie"       , slot = "Q" , delay = 0.25, speed = 1400       , isMissile = true },
    ["BrandE"]                      = {charName = "Brand"       , slot = "E" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["BrandR"]                      = {charName = "Brand"       , slot = "R" , delay = 0.25, speed = 1000       , isMissile = true },   -- to be comfirm brand R delay 0.25 or 0.5
    ["CassiopeiaE"]                 = {charName = "Cassiopeia"  , slot = "E" , delay = 0.15, speed = 2500       , isMissile = true },   -- delay to be comfirm
    ["CamilleR"]                    = {charName = "Camille"     , slot = "R" , delay = 0.5 , speed = math.huge  , isMissile = false},   -- delay to be comfirm
    ["Feast"]                       = {charName = "Chogath"     , slot = "R" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["DariusExecute"]               = {charName = "Darius"      , slot = "R" , delay = 0.25, speed = math.huge  , isMissile = false},    -- delay to be comfirm
    ["EliseHumanQ"]                 = {charName = "Elise"       , slot = "Q1", delay = 0.25, speed = 2200       , isMissile = true },
    ["EliseSpiderQCast"]            = {charName = "Elise"       , slot = "Q2", delay = 0.25, speed = math.huge  , isMissile = false},
    ["Terrify"]                     = {charName = "FiddleSticks", slot = "Q" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["FiddlesticksDarkWind"]        = {charName = "FiddleSticks", slot = "E" , delay = 0.25, speed = 1100       , isMissile = true },
    ["GangplankQProceed"]           = {charName = "Gangplank"   , slot = "Q" , delay = 0.25, speed = 2600       , isMissile = true },
    ["GarenR"]                      = {charName = "Garen"       , slot = "R" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["SowTheWind"]                  = {charName = "Janna"       , slot = "W" , delay = 0.25, speed = 1600       , isMissile = true },
    ["JarvanIVCataclysm"]           = {charName = "JarvanIV"    , slot = "R" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["JaxLeapStrike"]               = {charName = "Jax"         , slot = "Q" , delay = 0   , speed = 1700       , isMissile = false}, -- seems speed base on distance, lazy to find the forumla , maybe fixed delay
    ["JayceToTheSkies"]             = {charName = "Jayce"       , slot = "Q2", delay = 0.25, speed = math.huge  , isMissile = false}, -- seems speed base on distance, lazy to find the forumla , maybe fixed delay
    ["JayceThunderingBlow"]         = {charName = "Jayce"       , slot = "E2", delay = 0.25, speed = math.huge  , isMissile = false},
    ["KatarinaQ"]                   = {charName = "Katarina"    , slot = "Q" , delay = 0.25, speed = 1600       , isMissile = true },
    ["KatarinaE"]                   = {charName = "Katarina"    , slot = "E" , delay = 0.1 , speed = math.huge  , isMissile = false}, -- delay to be comfirm
    ["NullLance"]                   = {charName = "Kassadin"    , slot = "Q" , delay = 0.25, speed = 1400       , isMissile = true },
    ["KhazixQ"]                     = {charName = "Khazix"      , slot = "Q1", delay = 0.25, speed = math.huge  , isMissile = false},
    ["KhazixQLong"]                 = {charName = "Khazix"      , slot = "Q2", delay = 0.25, speed = math.huge  , isMissile = false},
    ["BlindMonkRKick"]              = {charName = "LeeSin"      , slot = "R" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["LeblancQ"]                    = {charName = "Leblanc"     , slot = "Q" , delay = 0.25, speed = 2000       , isMissile = true },
    ["LeblancRQ"]                   = {charName = "Leblanc"     , slot = "RQ", delay = 0.25, speed = 2000       , isMissile = true },
    ["LissandraREnemy"]             = {charName = "Lissandra"   , slot = "R" , delay = 0.5 , speed = math.huge  , isMissile = false},
    ["LucianQ"]                     = {charName = "Lucian"      , slot = "Q" , delay = 0.25, speed = math.huge  , isMissile = false}, --  delay = 0.4 − 0.25 (based on level)
    ["LuluWTwo"]                    = {charName = "Lulu"        , slot = "W" , delay = 0.25, speed = 2250       , isMissile = true },
    ["LuluE"]                       = {charName = "Lulu"        , slot = "E" , delay = 0   , speed = math.huge  , isMissile = false},
    ["SeismicShard"]                = {charName = "Malphite"    , slot = "Q" , delay = 0.25, speed = 1200       , isMissile = true },
    ["MalzaharE"]                   = {charName = "Malzahar"    , slot = "E" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["MalzaharR"]                   = {charName = "Malzahar"    , slot = "R" , delay = 0   , speed = math.huge  , isMissile = false},
    ["MissFortuneRicochetShot"]     = {charName = "MissFortune" , slot = "Q" , delay = 0.25, speed = 1400       , isMissile = true },  -- too lazy to calculate the speed forumla
    ["NasusW"]                      = {charName = "Nasus"       , slot = "W" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["NautilusGrandLine"]           = {charName = "Nautilus"    , slot = "R" , delay = 0.5 , speed = 1400       , isMissile = true },  -- delay to be comfirm
    ["NocturneParanoia2"]           = {charName = "Nocturne"    , slot = "R" , delay = 0   , speed = 1800       , isMissile = false},  --seems that you will never detect it.
    ["OlafRecklessStrike"]          = {charName = "Olaf"        , slot = "E" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["PoppyE"]                      = {charName = "Poppy"       , slot = "E" , delay = 0   , speed = 1800       , isMissile = false},
    ["RekSaiE"]                     = {charName = "RekSai"      , slot = "E" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["RekSaiR"]                     = {charName = "RekSai"      , slot = "R" , delay = 1.5 , speed = math.huge  , isMissile = false},
    ["PuncturingTaunt"]             = {charName = "Rammus"      , slot = "E" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["RyzeW"]                       = {charName = "Ryze"        , slot = "W" , delay = 0.25, speed = math.huge  , isMissile = false},
    ["RyzeE"]                       = {charName = "Ryze"        , slot = "E" , delay = 0.25, speed = 3500       , isMissile = true },
    ["SyndraR"]                     = {charName = "Syndra"      , slot = "R" , delay = 0.25, speed = 1400       , isMissile = true },
    ["TwoShivPoison"]               = {charName = "Shaco"       , slot = "E" , delay = 0.25, speed = 1500       , isMissile = true },
    ["BlindingDart"]                = {charName = "Teemo"       , slot = "Q" , delay = 0.25, speed = 1500       , isMissile = true },
    ["TristanaR"]                   = {charName = "Tristana"    , slot = "R" , delay = 0.25, speed = 2000       , isMissile = true },
    ["ViR"]                         = {charName = "Vi"          , slot = "R" , delay = 0.25, speed = 800        , isMissile = false},
    ["VayneCondemn"]                = {charName = "Vayne"       , slot = "E" , delay = 0.25, speed = 2200       , isMissile = true },
    ["VeigarR"]                     = {charName = "Veigar"      , slot = "R" , delay = 0.25, speed = 500        , isMissile = true },
    ["VladimirQ"]                   = {charName = "Vladimir"    , slot = "Q" , delay = 0.25, speed = math.huge  , isMissile = false},        -- speed to be comfirm
    ["XinZhaoE"]                    = {charName = "XinZhao"     , slot = "E" , delay = 0   , speed = 3000       , isMissile = false},
    ["TimeWarp"]                    = {charName = "Zilean"      , slot = "E" , delay = 0   , speed = math.huge  , isMissile = false},
    ["MordekaiserR"]                = {charName = "Mordekaiser" , slot = "R" , delay = 0.5 , speed = math.huge  , isMissile = false},
    ["QuinnE"]                      = {charName = "Quinn"       , slot = "E" , delay = 0   , speed = 2500       , isMissile = false},
    ["NamiW"]                       = {charName = "Nami"        , slot = "W" , delay = 0.25, speed = 2000       , isMissile = true },
    ["ViktorPowerTransfer"]         = {charName = "Viktor"      , slot = "Q" , delay = 0.25, speed = 2000       , isMissile = true },      -- too lazy to calculate the speed forumla
    ["BlueCardPreAttack"]           = {charName = "TwistedFate" , slot = "W" , delay = 0   , speed = 1500       , isMissile = true },
    ["RedCardPreAttack"]            = {charName = "TwistedFate" , slot = "W" , delay = 0   , speed = 1500       , isMissile = true },
    ["GoldCardPreAttack"]           = {charName = "TwistedFate" , slot = "W" , delay = 0   , speed = 1500       , isMissile = true },
}

function Sivir:__init()
    self.q = {
        type = "linear",
        speed = 1450,
        range = 1150,
        delay = 0.25,
        width = 180,
        collision = {
            ["Wall"] = true,
            ["Hero"] = false,
            ["Minion"] = false
        }
    }
    self:Menu()
    self.QlvlDmg = {[1] = 0.7, [2] = 0.85, [3] = 1, [4] = 1.15, [5] = 1.3}
    self.TS =
        DreamTS(
        self.menu:GetLocalChild("dreamTs"),
        {
            Damage = DreamTS.Damages.AD
        }
    )
    SDK.EventManager:RegisterCallback(SDK.Enums.Events.OnTick, function() self:OnTick() end)
    SDK.EventManager:RegisterCallback(SDK.Enums.Events.OnDraw, function() self:OnDraw() end)
    SDK.EventManager:RegisterCallback(SDK.Enums.Events.OnProcessSpell, function(unit, spell) self:OnProcessSpell(unit, spell) end)
    SDK.EventManager:RegisterCallback(SDK.Enums.Events.OnBuffGain, function(obj, buff) self:OnBuffUpdate(obj, buff) end)
    _G.CoreEx.EventManager.RegisterCallback(_G.CoreEx.Enums.Events.OnPostAttack, function(target) self:OnExecuteCastFrame(SDK.Types.AIBaseClient(target)) end)
end

function Sivir:Menu()
    self.menu = SDK.Libs.Menu("cxsivir", "Cyrex Sivir")

    self.menu
    :AddLabel("Cyrex Sivir Settings", true)
    :AddSubMenu("dreamTs", "Target Selector")

    self.menu
    :AddSubMenu("combo", "Combo Settings")
        :AddLabel("Q Settings", true)
        :AddCheckbox("q", "Use Q", true)
        :AddLabel("W Settings", true)
        :AddCheckbox("w", "Use W", true)
        :AddLabel("E Settings", true)
        :AddCheckbox("e", "Use E", true)
        :AddSlider("wDelay", "Xs before spell hit", {min = 0, max = 0.75, default = 0.1, step = 0.01})
        :AddSubMenu("blockSpell", "Auto E Block Spell")
                
    local block_sub_menu = self.menu:GetLocalChild("combo.blockSpell")

    for i, enemy in ipairs(enemies) do
        for k, spell in pairs(TargetedSpell) do
            if enemy:GetCharacterName() == spell.charName then
                block_sub_menu:AddCheckbox(k, enemy:GetCharacterName() .." ["..spell.slot.."] | "..k, true)
            end
        end
    end

    self.menu
    :AddSubMenu("harass", "Harass Settings")
        :AddLabel("xd", "Q Settings", true, true)
        :AddCheckbox("q", "Use Q", true)
        :GetParent()
    :AddSubMenu("lc", "Lane Clear")
        :AddCheckbox("q", "Use Q (Fast Clear)", true)
        :AddSlider("qx", "Min Minions:", {min = 0, max = 8, default = 3, step = 1})
        :AddSlider("qm", "Min Mana Percent:", {min = 0, max = 100, default = 10, step = 5})
        :GetParent()
    :AddSubMenu("jg", "Jungle Clear")
        :AddCheckbox("q", "Use Q", true)
        :GetParent()
    :AddSubMenu("auto", "Automatic Settings")
        :AddLabel("Killsteal Settings", true)
        :AddCheckbox("uqks", "Use Q in Killsteal", true)
        :GetParent()
    :AddSubMenu("draws", "Draw")
        :AddCheckbox("q", "Q", true)
        :GetParent()
    :AddLabel("Version: " .. update_data.Robur.ScriptVersion .. "", true)
    :AddLabel("Author: Coozbie")

    self.menu:Render()
end

local color_white = SDK.Libs.Color.GetD3DColor(255,7,141,237)

function Sivir:OnDraw()
    if not myHero:IsOnScreen() then
        return
    end

    if self.menu:GetLocal("draws.q") and myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) then
        SDK.Renderer:DrawCircle3D(myHero:GetPosition(), self.q.range, color_white)
    end    
end

local delayedActions, delayedActionsExecuter = {}, nil
function Sivir:DelayAction(func, delay, args) --delay in seconds
    if not delayedActionsExecuter then
        function delayedActionsExecuter()
            for t, funcs in pairs(delayedActions) do
                if t <= os.clock() then
                    for i = 1, #funcs do
                        local f = funcs[i]
                        if f and f.func then
                            f.func(unpack(f.args or {}))
                        end
                    end
                    delayedActions[t] = nil
                end
            end
        end
        SDK.EventManager:RegisterCallback(SDK.Enums.Events.OnTick, delayedActionsExecuter)
    end
    local t = os.clock() + (delay or 0)
    if delayedActions[t] then
        delayedActions[t][#delayedActions[t] + 1] = {func = func, args = args}
    else
        delayedActions[t] = {{func = func, args = args}}
    end
end

function Sivir:GetPercentHealth(obj)
    obj = obj or myHero
    return obj:GetHealthPercent()
end

function Sivir:GetTotalAP(obj)
  local obj = obj or myHero
  return obj:GetTotalAP()
end

function Sivir:MoveToMouse()
    SDK.Input:MoveTo(SDK.Renderer:GetMousePos3D())
end

function Sivir:TotalAD(obj)
    obj = obj or myHero
    return obj:GetTotalAD()
end

---@param obj SDK_AIBaseClient | nil
function Sivir:GetBonusAD(obj)
  obj = obj or myHero
  return obj:GetFlatPhysicalDamageMod()
end

function Sivir:GetDistanceSqr(p1, p2)
    p2 = p2 or myHero:GetPosition()
    local dx = p1.x - p2.x
    local dz = p1.z - p2.z
    return dx*dx + dz*dz
end

function Sivir:ValidTarget(object, distance) 
    return object and object:IsValid() and object:IsEnemy() and object:IsVisible() and not object:GetBuff('SionPassiveZombie') and not object:GetBuff('FioraW') and object:IsAlive() and not object:IsInvulnerable() and (not distance or  object:GetPosition():DistanceSqr(myHero:GetPosition()) <= distance * distance)
end

function Sivir:GetAARange(target)
    return myHero:GetAttackRange() + myHero:GetBoundingRadius() + (target and target:GetBoundingRadius() or 0)
end

function Sivir:qDmg(target)
    if myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) then
        local qDamage = (20 + (15 * myHero:GetSpell(SDK.Enums.SpellSlot.Q):GetLevel()) + (self:TotalAD() * 1) + (self.QlvlDmg[myHero:GetSpell(SDK.Enums.SpellSlot.Q):GetLevel()] * self:TotalAD()))
        return self.TS.CalcDmg(myHero, target:AsAI(), qDamage, 0, 0)
    end
end

function Sivir:OnProcessSpell(unit, spell)
    if unit:IsMe() and spell:GetTarget() and spell:GetTarget():IsMe() then return end
    if myHero:CanUseSpell(SDK.Enums.SpellSlot.E) and self.menu:GetLocal("combo.e") then
        for k, v in pairs(TargetedSpell) do
            if k == spell:GetName() and self.menu:GetLocal("combo.blockSpell." .. k) then
                local dt = unit:GetPosition():Distance(myHero:GetPosition())
                local hitTime = v.delay + dt/v.speed
                self:DelayAction(function() SDK.Input:Cast(SDK.Enums.SpellSlot.E, myHero) end, hitTime - self.menu:GetLocal("combo.wDelay") )
            end
        end
    end
end

function Sivir:OnExecuteCastFrame(target)
    if self.menu:GetLocal("combo.w") and myHero:CanUseSpell(SDK.Enums.SpellSlot.W) and (_G.Libs.Orbwalker.GetMode() == "Combo" or _G.Libs.Orbwalker.GetMode() == "Harass") then
        if target and self:ValidTarget(target) and target:GetPosition():DistanceSqr(myHero:GetPosition()) < self:GetAARange(target)^2 then
            SDK.Input:Cast(SDK.Enums.SpellSlot.W, myHero)
        end
    end
end

function Sivir:CastQ(pred)
    if pred.rates["slow"] then
        SDK.Input:Cast(SDK.Enums.SpellSlot.Q, pred.castPosition)
        pred:Draw()
        return true
    end
end

function Sivir:OnBuffUpdate(obj, buff)
    if myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) then
        if obj:IsValid() and obj:IsEnemy() and obj:IsAlive() and obj.IsHero and buff then
            if buff:GetType() == SDK.Enums.BuffType.Charm and buff:GetType() == SDK.Enums.BuffType.Snare and buff:GetType() == SDK.Enums.BuffType.Taunt and buff:GetType() == SDK.Enums.BuffType.Stun and obj:GetPosition():DistanceSqr(myHero:GetPosition()) < (1100 * 1100) then
                SDK.Input:Cast(SDK.Enums.SpellSlot.Q, obj:GetPosition())
            end
        end
    end
end

local immunityList = {
    "MorganaE",
    "itemmagekillerveil",
    "bansheesveil",
    "sivire",
}
function Sivir:IsImmuneMagic(target)
    for index = 1, #immunityList do
        local immunity = immunityList[index]
        local buff = target:GetBuff(immunity)
        if buff and buff:IsValid() then
            return true
        end
    end
    return false
end

function Sivir:DoingDodge()    
    if self:IsImmuneMagic(myHero) then return end
    if _G.DreamEvade.IsPositionSafe(myHero:GetPosition(), 0) then return end
    local Spells = _G.DreamEvade.ActiveSpells
    for index = 1, #Spells do
        local Spell = Spells[index]
        if myHero:CanUseSpell(SDK.Enums.SpellSlot.E) and ((Spell:IsCC() and Spell:IsOhShit() and Spell:IsActive()) or (Spell:GetDangerLevel() >= 4 and Spell:IsOhShit())) then
            SDK.Input:Cast(SDK.Enums.SpellSlot.E, myHero)
            return
        end
    end
end

function Sivir:LaneClear()
    if self.menu:GetLocal("lc.q") then
        local minionsInERange = _G.CoreEx.ObjectManager.GetNearby("enemy", "minions")
        local minionsPositions = {}
        local myPos = myHero:GetPosition()
        for _, minion in ipairs(minionsInERange) do
            if minion.Position:DistanceSqr(myHero:GetPosition()) < (self.q.range * self.q.range) then
                table.insert(minionsPositions, minion.Position)
            end
        end
        local bestPos, numberOfHits = _G.CoreEx.Geometry.BestCoveringRectangle(minionsPositions, myPos, self.q.width * 2)
        if _G.Libs.Orbwalker.IsFastClearEnabled() then
            if numberOfHits >= self.menu:GetLocal("lc.qx") then
                if Player.ManaPercent * 100 >= self.menu:GetLocal("lc.qm") then
                    if SDK.Input:Cast(SDK.Enums.SpellSlot.Q, bestPos) then
                        return
                    end
                end
            end
        end
    end
end

function Sivir:JungleClear()
    local Jungle = _G.CoreEx.ObjectManager.GetNearby("neutral", "minions")
    for iJGLQ, objJGLQ in ipairs (Jungle) do
        local minion = objJGLQ.AsMinion
        if minion and minion.MaxHealth > 6 and minion.Position:DistanceSqr(myHero:GetPosition()) < (600 * 600) and _G.Libs.TargetSelector():IsValidTarget(minion) then
            if myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) and self.menu:GetLocal("jg.q") then
                SDK.Input:Cast(SDK.Enums.SpellSlot.Q, minion.Position)
            end
        end
    end
end


function Sivir:OnTick()
    local ComboMode = _G.Libs.Orbwalker.GetMode() == "Combo"
    local HarassMode = _G.Libs.Orbwalker.GetMode() == "Harass"
    local WaveclearMode = _G.Libs.Orbwalker.GetMode() == "Waveclear"

    if myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) then
        local q_targets, q_preds = self.TS:GetTargets(self.q, myHero:GetPosition())
        local q_ks, q_ks_pred = self.TS:GetTargets(self.q, myHero:GetPosition(), function(enemy) return self:qDmg(enemy) >= enemy:GetHealth() end)

        if (ComboMode and self.menu:GetLocal("combo.q")) or (HarassMode and self.menu:GetLocal("harass.q")) then
            local target = q_targets[1]
            if target then
                local pred = q_preds[target:GetNetworkId()]
                if pred and self:CastQ(pred) then
                    return
                end
            end
        end
        if self.menu:GetLocal("auto.uqks") then
            local target = q_ks[1]
            if target then
                local pred = q_ks_pred[target:GetNetworkId()]
                if pred and self:CastQ(pred) then
                    return
                end
            end
        end
        if WaveclearMode then
            self:LaneClear()
        end
    end
    if self.menu:GetLocal("combo.e") and rawget(_G, "DreamEvade") and _G.DreamEvade.IsEvadeEnabled() then
        self:DoingDodge()
    end
    if WaveclearMode then self:JungleClear() end
end

local get_d3d_color = SDK.Libs.Color.GetD3DColor
function Sivir:Hex(a, r, g, b)
    return get_d3d_color(a, r, g, b)
end

function Sivir:GetTargetNormal(dist, all)
    local res = self.TS:update(function(unit) return _G.Prediction.SDK.IsValidTarget(unit, dist) end)
    if all then
        return res
    else
        if res and res[1] then
            return res[1]
        end
    end
end

if myHero:GetCharacterName() == "Sivir" then
    Sivir:__init()
end