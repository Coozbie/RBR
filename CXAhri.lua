local DreamTSLib = _G.DreamTS or require("DreamTS")

local SDK = DreamTSLib.TargetSelectorSdk.SDK

---@type SDK_AIHeroClient
local myHero = SDK.Player

if myHero:GetCharacterName() ~= "Ahri" then return end

local Ahri = {}
local version = 2.2

local DreamTS = DreamTSLib.TargetSelectorSdk
local Vector = SDK.Libs.Vector

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

function Ahri:__init()
    self.q = {
        type = "linear",
        speed = 2500,
        range = 870,
        delay = 0.25,
        width = 60,
        LastObjectVector = nil,
        LastObjectVectorTime = 0,
        IsReturning = false,
        CatchPosition = nil,
        Target = nil,
        LastCastTime = 0,
        Object = nil,
        collision = {
            ["Wall"] = true,
            ["Hero"] = false,
            ["Minion"] = false
        }
    }
    self.e = {
        type = "linear",
        speed = 1550,
        range = 925,
        delay = 0.25,
        width = 120,
        collision = {
            ["Wall"] = true,
            ["Hero"] = true,
            ["Minion"] = true
        }
    }
    self.efline = {
        type = "linear",
        speed = 1600,
        range = 820,
        delay = 0.3,
        width = 80,
        castRate = "instant",
    }
    self:Menu()
    self.RHaveBuff = false
    self.RLastCastTime = 0
    self.RFirstCastTime = 0
    self.Emiss = nil
    self.TS =
        DreamTS(
        self.menu:GetLocalChild("dreamTs"),
        {
            Damage = DreamTS.Damages.AP
        }
    )
    SDK.EventManager:RegisterCallback(SDK.Enums.Events.OnTick, function() self:OnTick() end)
    SDK.EventManager:RegisterCallback(SDK.Enums.Events.OnDraw, function() self:OnDraw() end)
    SDK.EventManager:RegisterCallback(SDK.Enums.Events.OnBuffGain, function(obj, buff) self:OnBuffUpdate(obj, buff) end)
    SDK.EventManager:RegisterCallback(SDK.Enums.Events.OnCreateObject, function(obj) self:OnCreateObject(obj) end)
    SDK.EventManager:RegisterCallback(SDK.Enums.Events.OnDeleteObject, function(obj) self:OnDeleteObject(obj) end)
    self.fontSize = 25
    self.font1Size = 12
end

function Ahri:Menu()
    self.menu = SDK.Libs.Menu("cxahri", "Cyrex Ahri")

    self.menu
    :AddLabel("Cyrex Ahri Settings", true)
    :AddSubMenu("dreamTs", "Target Selector")

    self.menu
    :AddSubMenu("Key", "Key Settings")
        :AddKeybind("e", "Start Combo With E", string.byte("K"))
        :GetParent()
    :AddSubMenu("combo", "Combo Settings")
        :AddLabel("Q Settings", true)
        :AddCheckbox("q", "Use Q", true)
        :AddLabel("W Settings", true)
        :AddCheckbox("w", "Use W", true)
        :AddCheckbox("wc", "Cast Only if Enemy is Charmed?", false)
        :AddSlider("wr", "Min. W Range To Cast", {min = 300, max = 700, default = 600, step = 50})
        :AddLabel("E Settings", true)
        :AddCheckbox("e", "Use E", true)
        :AddLabel("R Settings", true)
        :AddCheckbox("r", "Use R [Mouse & Beta]", false)
        :GetParent()
    :AddSubMenu("harass", "Harass Settings")
        :AddCheckbox("q", "Use Q", true)
        :AddCheckbox("w", "Use W", true)
        :AddCheckbox("e", "Use E", true)
        :AddSlider("mana", "Min Mana Percent:", {min = 0, max = 100, default = 10, step = 5})

    :AddSubMenu("antigap", "Anti Gapclose")
        self.antiGapHeros = {}
        for _, enemy in ipairs(enemies) do
            --:AddCheckbox(enemy.CharName, enemy.CharName, true)
            self.antiGapHeros[enemy:GetNetworkId()] = true
        end

    self.menu
    :AddSubMenu("draws", "Draw")
        :AddCheckbox("q", "Q", true)
        :AddCheckbox("w", "W", true)
        :AddCheckbox("e", "E", true)
        :GetParent()
    :AddLabel("Version: " .. version .. "", true)
    :AddLabel("Author: Coozbie", true)

    self.menu:Render()
end

function Ahri:OnDraw()
    if self.menu:GetLocal("draws.q") and myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) and myHero:IsOnScreen() then
        SDK.Renderer:DrawCircle3D(myHero:GetPosition(), self.q.range, self:Hex(255,255,255,255))
    end
    if self.menu:GetLocal("draws.w") and myHero:CanUseSpell(SDK.Enums.SpellSlot.W) and myHero:IsOnScreen() then
        SDK.Renderer:DrawCircle3D(myHero:GetPosition(), self.menu:GetLocal("combo.wr"), self:Hex(255,255,255,255))
    end
    if self.menu:GetLocal("draws.e") and myHero:CanUseSpell(SDK.Enums.SpellSlot.E) and myHero:IsOnScreen() then
        SDK.Renderer:DrawCircle3D(myHero:GetPosition(), self.e.range, self:Hex(255,255,255,255))
    end

end

local delayedActions, delayedActionsExecuter = {}, nil
function Ahri:DelayAction(func, delay, args) --delay in seconds
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


local ITEM_SLOTS =
{
    SDK.Enums.SpellSlot.Item1,
    SDK.Enums.SpellSlot.Item2,
    SDK.Enums.SpellSlot.Item3,
    SDK.Enums.SpellSlot.Item4,
    SDK.Enums.SpellSlot.Item5,
    SDK.Enums.SpellSlot.Item6,
    SDK.Enums.SpellSlot.Trinket,
}

function Ahri:GetItem(name)
    for i, slot in ipairs(ITEM_SLOTS) do
        if myHero:GetSpellState(slot) == 0 then
            if myHero:GetSpell(slot):GetName() == name then
                return slot
            end
        end
    end
end

function Ahri:CastEF(target)
    local ef = self:GetItem("6656Cast")
    if ef and target and target.IsAI then
        local pred = _G.Prediction.SDK.GetPrediction(target, self.efline, myHero:GetPosition())
        if pred and pred.castPosition then
            SDK.Input:Cast(ef, pred.castPosition)
        end
    end
end

function Ahri:OnBuffUpdate(obj, buff)
    if obj:IsValid() and obj:IsEnemy() and obj:IsAlive() and obj.IsHero and buff then
        if buff.IsCC and obj:GetPosition():DistanceSqr(myHero:GetPosition()) < (800 * 800) then
            self:DelayAction(function() self:CastEF(obj) end, buff:GetDurationLeft() - 0.6)
        end
    end
end

function Ahri:OnCreateObject(obj)
    if obj:IsValid() then
        if obj:GetName():lower():find("ahriseducemissile") then
            self.Emiss = obj
        end
    end
end

function Ahri:OnDeleteObject(obj)
    if obj:IsValid() then
        if obj:GetName():lower():find("ahriseducemissile") then
            self.Emiss = nil
        end
    end
end

function Ahri:GetPercentHealth(obj)
    obj = obj or myHero
    return obj:GetHealthPercent()
end

function Ahri:CastQ(pred)
    if pred.rates["slow"] then
        SDK.Input:Cast(SDK.Enums.SpellSlot.Q, pred.castPosition)
        pred:Draw()
        return true
    end
end

function Ahri:CastE(pred)
    if pred.rates["slow"] then
        SDK.Input:Cast(SDK.Enums.SpellSlot.E, pred.castPosition)
        pred:Draw()
        return true
    end
end

function Ahri:CastEver(pred)
    local ef = self:GetItem("6656Cast")
    if ef and pred.rates["slow"] then
        SDK.Input:Cast(ef, pred.castPosition)
        pred:Draw()
        return true
    end
end

function Ahri:CastR()
    if myHero:CanUseSpell(SDK.Enums.SpellSlot.R) and self.menu:GetLocal("combo.r") then
        SDK.Input:Cast(SDK.Enums.SpellSlot.R, SDK.Renderer:GetMousePos3D())
    end
end

function Ahri:OnTick()

    local ComboMode = _G.Libs.Orbwalker.GetMode() == "Combo"
    local HarassMode = _G.Libs.Orbwalker.GetMode() == "Harass"

    if myHero:CanUseSpell(SDK.Enums.SpellSlot.E) then

        -- Hybrid mode -> less cast priority but peel close targets if needed
        local e_targets, e_preds = self.TS:GetTargets(self.e, myHero:GetPosition())

        for i = 1, #e_targets do
            local unit = e_targets[i]
            local pred = e_preds[unit:GetNetworkId()]
            if pred then
                if pred.targetDashing and self:CastE(pred) then --and self.antiGapHeros[unit:GetNetworkId()] and self.menu:GetLocal("antigap." .. unit:GetCharacterName()) and self:CastE(pred) then
                    return
                end
                if pred.isInterrupt and self:CastE(pred) then
                    return
                end
            end
        end

        if (ComboMode and self.menu:GetLocal("combo.e")) or (HarassMode and self.menu:GetLocal("harass.e")) then
            local target = e_targets[1]
            if target then
                local pred = e_preds[target:GetNetworkId()]

                if pred and self:CastE(pred) then
                    return
                end
            end
        end

        if ComboMode and self.menu:GetLocal("Key.e") then
            return
        end
    end

    if myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) then
        local q_targets, q_preds = self.TS:GetTargets(self.q, myHero:GetPosition())

        if (ComboMode and self.menu:GetLocal("combo.q")) or (HarassMode and self.menu:GetLocal("harass.q")) then
            local target = q_targets[1]
            if target then
                local pred = q_preds[target:GetNetworkId()]
                if pred and self:CastQ(pred) then
                    return
                end
            end
        end
    end

    if myHero:CanUseSpell(SDK.Enums.SpellSlot.W) then
        local target = self:GetTargetNormal(self.menu:GetLocal("combo.wr"))

        if target then
            if (ComboMode and self.menu:GetLocal("combo.w")) or (HarassMode and self.menu:GetLocal("harass.w")) then 
                if target:GetPosition():Distance(myHero:GetPosition()) <= (self.menu:GetLocal("combo.wr")) then
                    if self.menu:GetLocal("combo.wc") and target:HasBuffOfType("Charm") then 
                        SDK.Input:Cast(SDK.Enums.SpellSlot.W, myHero)
                    elseif not self.menu:GetLocal("combo.wc") or self:GetPercentHealth(target) < 40 then
                        SDK.Input:Cast(SDK.Enums.SpellSlot.W, myHero)
                    elseif not self.menu:GetLocal("combo.wc") and not myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) and not myHero:CanUseSpell(SDK.Enums.SpellSlot.E) then
                        SDK.Input:Cast(SDK.Enums.SpellSlot.W, myHero)
                    end
                end
            end
        end
    end
    if not myHero:CanUseSpell(SDK.Enums.SpellSlot.E) and not self.Emiss then
        local ef = self:GetItem("6656Cast")
        local ef_targets, ef_preds = self.TS:GetTargets(self.efline, myHero:GetPosition())
        if (ComboMode and ef) then
            print("XD")
            local target = ef_targets[1]
            if target and not target:HasBuffOfType("Charm") then
                local pred = ef_preds[target:GetNetworkId()]
                if pred and self:CastEver(pred) then
                    return
                end
            end
        end
    end
end

local get_d3d_color = SDK.Libs.Color.GetD3DColor
function Ahri:Hex(a, r, g, b)
    return get_d3d_color(a, r, g, b)
end

-- For targetted abilities (aka Ahri W)
function Ahri:GetTargetNormal(dist, all)
    local res = self.TS:update(function(unit) return _G.Prediction.SDK.IsValidTarget(unit, dist) end)
    if all then
        return res
    else
        if res and res[1] then
            return res[1]
        end
    end
end

if myHero:GetCharacterName() == "Ahri" then
    Ahri:__init()
end
