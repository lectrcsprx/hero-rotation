--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, addonTable = ...
-- HeroLib
local HL = HeroLib
local Cache = HeroCache
local Unit = HL.Unit
local Player = Unit.Player
local Target = Unit.Target
local Pet = Unit.Pet
local Spell = HL.Spell
local MultiSpell = HL.MultiSpell
local Item = HL.Item
-- HeroRotation
local HR = HeroRotation

-- Azerite Essence Setup
local AE         = HL.Enum.AzeriteEssences
local AESpellIDs = HL.Enum.AzeriteEssenceSpellIDs
local AEMajor    = HL.Spell:MajorEssence()

--- ============================ CONTENT ===========================
--- ======= APL LOCALS =======
-- luacheck: max_line_length 9999

-- Spells
if not Spell.Monk then Spell.Monk = {} end
Spell.Monk.Brewmaster = {
  AncestralCall                         = Spell(274738),
  ArcaneTorrent                         = Spell(50613),
  BagofTricks                           = Spell(312411),
  Berserking                            = Spell(26297),
  BlackoutCombo                         = Spell(196736),
  BlackoutComboBuff                     = Spell(228563),
  BlackoutStrike                        = Spell(205523),
  BlackOxBrew                           = Spell(115399),
  BloodFury                             = Spell(20572),
  BreathofFire                          = Spell(115181),
  BreathofFireDotDebuff                 = Spell(123725),
  Brews                                 = Spell(115308),
  ChiBurst                              = Spell(123986),
  ChiWave                               = Spell(115098),
  DampenHarm                            = Spell(122278),
  DampenHarmBuff                        = Spell(122278),
  ExpelHarm                             = Spell(115072),
  ExplodingKeg                          = Spell(214326),
  Fireblood                             = Spell(265221),
  FortifyingBrew                        = Spell(115203),
  FortifyingBrewBuff                    = Spell(115203),
  InvokeNiuzaotheBlackOx                = Spell(132578),
  IronskinBrew                          = Spell(115308),
  IronskinBrewBuff                      = Spell(215479),
  KegSmash                              = Spell(121253),
  LightBrewing                          = Spell(196721),
  LightsJudgment                        = Spell(255647),
  PotentKick                            = Spell(213047),
  PurifyingBrew                         = Spell(119582),
  RushingJadeWind                       = Spell(116847),
  SpearHandStrike                       = Spell(116705),
  SpecialDelivery                       = Spell(196730),
  TigerPalm                             = Spell(100780),
  -- Stagger Levels
  HeavyStagger                          = Spell(124273),
  ModerateStagger                       = Spell(124274),
  LightStagger                          = Spell(124275),
  -- Essences
  BloodoftheEnemy                       = Spell(297108),
  MemoryofLucidDreams                   = Spell(298357),
  PurifyingBlast                        = Spell(295337),
  RippleInSpace                         = Spell(302731),
  ConcentratedFlame                     = Spell(295373),
  TheUnboundForce                       = Spell(298452),
  WorldveinResonance                    = Spell(295186),
  FocusedAzeriteBeam                    = Spell(295258),
  GuardianofAzeroth                     = Spell(295840),
  SuppressingPulse                      = Spell(293031),
  RecklessForceBuff                     = Spell(302932),
  ConcentratedFlameBurn                 = Spell(295368),
  -- Trinket Effects
  RazorCoralDebuff                      = Spell(303568),
  ConductiveInkDebuff                   = Spell(302565),
  -- Misc
  PoolEnergy                            = Spell(9999000010)
};
local S = Spell.Monk.Brewmaster;
if AEMajor ~= nil then
  S.HeartEssence                          = Spell(AESpellIDs[AEMajor.ID])
end

-- Items
if not Item.Monk then Item.Monk = {} end
Item.Monk.Brewmaster = {
  PotionofUnbridledFury            = Item(169299),
  AshvanesRazorCoral               = Item(169311, {13, 14}),
  PocketsizedComputationDevice     = Item(167555, {13, 14})
};
local I = Item.Monk.Brewmaster;

-- Rotation Var
local ShouldReturn; -- Used to get the return string
local ForceOffGCD = {true, false};

-- GUI Settings
local Everyone = HR.Commons.Everyone;
local Settings = {
  General = HR.GUISettings.General,
  Commons = HR.GUISettings.APL.Monk.Commons,
  Brewmaster = HR.GUISettings.APL.Monk.Brewmaster
};

HL:RegisterForEvent(function()
  AEMajor        = HL.Spell:MajorEssence();
  S.HeartEssence = Spell(AESpellIDs[AEMajor.ID]);
end, "AZERITE_ESSENCE_ACTIVATED", "AZERITE_ESSENCE_CHANGED")

-- Array of the 3 stagger levels
local staggerDebuffs = {
  [124273] = true,
  [124274] = true,
  [124275] = true,
};

-- UnitAura function from BrewmasterTools
local function BrMUnitAura(unit, spellID, filter)
  local i, id = 0, 0
  if type(spellID) == "number" then
    while id do
      i = i + 1
      id = select(10, UnitAura(unit, i, filter))
      if spellID == id then
        return UnitAura(unit, i, filter)
      end
    end
  else
    while id do
      i = i + 1
      id = select(10, UnitAura(unit, i, filter))
      if spellID[id] then
        return UnitAura(unit, i, filter)
      end
    end
  end
end

-- GetNextTick function from BrewmasterTools
local function GetNextTick()
  return select(16,BrMUnitAura("player", staggerDebuffs, "HARMFUL")) or 0
end

-- makeTempAdder function from BrewmasterTools
local function BrMMakeTempAdder()
  local val = 0
  return function(toAdd, decayTime) --modify upvalue
    val = val + toAdd
    C_Timer.After(decayTime,function()
      val = val - toAdd
    end)
  end,
  function()  return val  end --access upvalue
end

BrMAddToPool, BrMGetNormalStagger = BrMMakeTempAdder()

local function ShouldPurify ()
  local BrewMaxCharges = 3 + (S.LightBrewing:IsAvailable() and 1 or 0);
  local NormalizedStagger = BrMGetNormalStagger();
  local NextStaggerTick = GetNextTick();
  local NStaggerPct = NextStaggerTick > 0 and NextStaggerTick/Player:MaxHealth() or 0;
  local ProgressPct = NormalizedStagger > 0 and Player:Stagger()/NormalizedStagger or 0;
  if HL.CombatTime() <= 9 then return false end;
  if S.Brews:ChargesFractional() >= BrewMaxCharges - 0.2 and Player:BuffRemains(S.IronskinBrewBuff) > 18 then return true end;
  if NStaggerPct > 0.015 and ProgressPct > 0 then
    if NStaggerPct <= 0.03 then -- Yellow (> 80%)
      return Settings.Brewmaster.Purify.Low and ProgressPct > 0.8 or false;
    elseif NStaggerPct <= 0.05 then -- Orange (> 70%)
      return Settings.Brewmaster.Purify.Medium and ProgressPct > 0.7 or false;
    elseif NStaggerPct <= 0.1 then -- Red (> 50%)
      return Settings.Brewmaster.Purify.High and ProgressPct > 0.5 or false;
    else -- Magenta
      return true;
    end
  end
end

-- compute healing available from orbs, only 
local function HealingSphereHealingAvailable()
  return 1.5 * Player:AttackPowerDamageMod() * (1 + Player:VersatilityDmgPct()/100) * S.ExpelHarm:Count()
end

--- ======= ACTION LISTS =======
local function APL()
  -- Unit Update
  HL.GetEnemies(8, true);
  Everyone.AoEToggleEnemiesUpdate();

  -- Misc
  local BrewMaxCharge = 3 + (S.LightBrewing:IsAvailable() and 1 or 0);
  local IronskinDuration = 7;
  local IsTanking = Player:IsTankingAoE(8) or Player:IsTanking(Target);
  local PassiveEssence = (Spell:MajorEssenceEnabled(AE.VisionofPerfection) or Spell:MajorEssenceEnabled(AE.ConflictandStrife) or Spell:MajorEssenceEnabled(AE.TheFormlessVoid));

  local function Defensives()
    if S.SuppressingPulse:IsCastableP() then
      if HR.Cast(S.SuppressingPulse, true) then return "suppressing pulse"; end
    end
    -- ironskin_brew,if=buff.blackout_combo.down&incoming_damage_1999ms>(health.max*0.1+stagger.last_tick_damage_4)&buff.elusive_brawler.stack<2&!buff.ironskin_brew.up
    -- ironskin_brew,if=cooldown.brews.charges_fractional>1&cooldown.black_ox_brew.remains<3
    -- Note: Extra handling of the charge management only while tanking.
    --       "- (IsTanking and 1 + (Player:BuffRemains(S.IronskinBrewBuff) <= IronskinDuration * 0.5 and 0.5 or 0) or 0)"
    if S.IronskinBrew:IsCastableP() and Player:BuffDownP(S.BlackoutComboBuff)
        and S.Brews:ChargesFractional() >= BrewMaxCharge - 0.1 - (IsTanking and 1 + (Player:BuffRemains(S.IronskinBrewBuff) <= IronskinDuration * 0.5 and 0.5 or 0) or 0)
        and Player:BuffRemains(S.IronskinBrewBuff) <= IronskinDuration * 2 then
      if HR.Cast(S.IronskinBrew, Settings.Brewmaster.OffGCDasOffGCD.IronskinBrew) then return ""; end
    end
    -- purifying_brew,if=stagger.pct>(6*(3-(cooldown.brews.charges_fractional)))&(stagger.last_tick_damage_1>((0.02+0.001*(3-cooldown.brews.charges_fractional))*stagger.last_tick_damage_30))
    if S.PurifyingBrew:IsCastableP() and ShouldPurify() then
      if HR.Cast(S.PurifyingBrew, Settings.Brewmaster.OffGCDasOffGCD.PurifyingBrew) then return ""; end
    end
    -- BlackoutCombo Stagger Pause w/ Ironskin Brew
    if S.IronskinBrew:IsCastableP() and Player:BuffP(S.BlackoutComboBuff) and Player:HealingAbsorbed() and ShouldPurify() then
      if HR.Cast(S.IronskinBrew, Settings.Brewmaster.OffGCDasOffGCD.IronskinBrew) then return ""; end
    end
  end

  --- Out of Combat
  if not Player:AffectingCombat() and Everyone.TargetIsValid() then
    -- flask
    -- food
    -- augmentation
    -- snapshot_stats
    -- potion
    if I.PotionofUnbridledFury:IsReady() and Settings.Commons.UsePotions then
      if HR.CastSuggested(I.PotionofUnbridledFury) then return ""; end
    end
    -- chi_burst
    if S.ChiBurst:IsCastableP(10) then
      if HR.Cast(S.ChiBurst) then return ""; end
    end
    -- chi_wave
    if S.ChiWave:IsCastableP(25) then
      if HR.Cast(S.ChiWave) then return ""; end
    end
  end

  --- In Combat
  if Everyone.TargetIsValid() then
    -- auto_attack
    -- Interrupts
    Everyone.Interrupt(5, S.SpearHandStrike, Settings.Commons.OffGCDasOffGCD.SpearHandStrike, false);
    -- Defensives
    if IsTanking then
      ShouldReturn = Defensives(); if ShouldReturn then return ShouldReturn; end
    end
    -- use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.down|debuff.conductive_ink_debuff.up&target.health.pct<31|target.time_to_die<20
    if I.AshvanesRazorCoral:IsEquipReady() and Settings.Commons.UseTrinkets and (Target:DebuffDownP(S.RazorCoralDebuff) or Target:DebuffP(S.ConductiveInkDebuff) and Target:HealthPercentage() < 31 or Target:TimeToDie() < 20) then
      if HR.Cast(I.AshvanesRazorCoral, nil, Settings.Commons.TrinketDisplayStyle) then return ""; end
    end
    -- use_items
    -- Manually placing PSCD here
    if Everyone.CyclotronicBlastReady() and Settings.Commons.UseTrinkets then
      if HR.Cast(I.PocketsizedComputationDevice, nil, Settings.Commons.TrinketDisplayStyle) then return ""; end
    end
    -- potion
    if I.PotionofUnbridledFury:IsReady() and Settings.Commons.UsePotions then
      if HR.CastSuggested(I.PotionofUnbridledFury) then return ""; end
    end
    if (HR.CDsON()) then
      -- blood_fury
      if S.BloodFury:IsCastableP() then
        if HR.Cast(S.BloodFury, Settings.Commons.OffGCDasOffGCD.Racials) then return ""; end
      end
      -- berserking
      if S.Berserking:IsCastableP() then
        if HR.Cast(S.Berserking, Settings.Commons.OffGCDasOffGCD.Racials) then return ""; end
      end
      -- lights_judgment
      if S.LightsJudgment:IsCastableP() then
        if HR.Cast(S.LightsJudgment, Settings.Commons.OffGCDasOffGCD.Racials) then return ""; end
      end
      -- fireblood
      if S.Fireblood:IsCastableP() then
        if HR.Cast(S.Fireblood, Settings.Commons.OffGCDasOffGCD.Racials) then return ""; end
      end
      -- ancestral_call
      if S.AncestralCall:IsCastableP() then
        if HR.Cast(S.AncestralCall, Settings.Commons.OffGCDasOffGCD.Racials) then return ""; end
      end
      -- bag_of_tricks
      if S.BagofTricks:IsCastableP() then
        if HR.Cast(S.BagofTricks, Settings.Commons.OffGCDasOffGCD.Racials) then return ""; end
      end
      -- invoke_niuzao_the_black_ox
      if S.InvokeNiuzaotheBlackOx:IsCastableP(40) and Target:TimeToDie() > 25 then
        if HR.Cast(S.InvokeNiuzaotheBlackOx, Settings.Brewmaster.OffGCDasOffGCD.InvokeNiuzaotheBlackOx) then return ""; end
      end
    end
    -- black_ox_brew,if=cooldown.brews.charges_fractional<0.5
    if S.BlackOxBrew:IsCastableP() and S.Brews:ChargesFractional() <= 0.5 then
      if HR.Cast(S.BlackOxBrew, Settings.Brewmaster.OffGCDasOffGCD.BlackOxBrew) then return ""; end
    end
    -- black_ox_brew,if=(energy+(energy.regen*cooldown.keg_smash.remains))<40&buff.blackout_combo.down&cooldown.keg_smash.up
    if S.BlackOxBrew:IsCastableP() and (Player:Energy() + (Player:EnergyRegen() * S.KegSmash:CooldownRemainsP())) < 40 and Player:BuffDownP(S.BlackoutComboBuff) and S.KegSmash:CooldownUpP() then
      if S.Brews:Charges() >= 2 and Player:StaggerPercentage() >= 1 then
        HR.Cast(S.IronskinBrew, ForceOffGCD);
        HR.Cast(S.PurifyingBrew, ForceOffGCD);
        if HR.Cast(S.BlackOxBrew) then return ""; end
      else
        if S.Brews:Charges() >= 1 then HR.Cast(S.IronskinBrew, ForceOffGCD); end
        if HR.Cast(S.BlackOxBrew, Settings.Brewmaster.OffGCDasOffGCD.BlackOxBrew) then return ""; end
      end
    end
    -- keg_smash,if=spell_targets>=2
    if S.KegSmash:IsCastableP(25) and Cache.EnemiesCount[8] >= 2 then
      if HR.Cast(S.KegSmash) then return ""; end
    end
    -- tiger_palm,if=talent.rushing_jade_wind.enabled&buff.blackout_combo.up&buff.rushing_jade_wind.up
    if S.TigerPalm:IsCastableP("Melee") and S.RushingJadeWind:IsAvailable() and Player:BuffP(S.BlackoutComboBuff) and Player:BuffP(S.RushingJadeWind) then
      if HR.Cast(S.TigerPalm) then return ""; end
    end
    -- tiger_palm,if=(talent.invoke_niuzao_the_black_ox.enabled|talent.special_delivery.enabled)&buff.blackout_combo.up
    if S.TigerPalm:IsCastableP("Melee") and (S.InvokeNiuzaotheBlackOx:IsAvailable() or S.SpecialDelivery:IsAvailable()) and Player:BuffP(S.BlackoutComboBuff) then
      if HR.Cast(S.TigerPalm) then return ""; end
    end
    -- expel_harm,if=buff.gift_of_the_ox.stack>4
    if S.ExpelHarm:IsReadyP() and (S.ExpelHarm:Count() > 4) and Player:Health() + HealingSphereHealingAvailable() < Player:MaxHealth() then
      if HR.Cast(S.ExpelHarm) then return ""; end
    end
    -- blackout_strike
    if S.BlackoutStrike:IsCastableP("Melee") then
      if HR.Cast(S.BlackoutStrike) then return ""; end
    end
    -- keg_smash
    if S.KegSmash:IsCastableP(25) then
      if HR.Cast(S.KegSmash) then return ""; end
    end
    -- concentrated_flame,if=dot.concentrated_flame.remains=0
    if S.ConcentratedFlame:IsCastableP() and (Target:DebuffDownP(S.ConcentratedFlameBurn)) then
      if HR.Cast(S.ConcentratedFlame, nil, Settings.Commons.EssenceDisplayStyle) then return ""; end
    end
    -- heart_essence,if=!essence.the_crucible_of_flame.major
    if S.HeartEssence ~= nil and not PassiveEssence and S.HeartEssence:IsCastableP() and (not Spell:MajorEssenceEnabled(AE.TheCrucibleofFlame)) then
      if HR.Cast(S.HeartEssence, nil, Settings.Commons.EssenceDisplayStyle) then return ""; end
    end
    -- expel_harm,if=buff.gift_of_the_ox.stack>=3
    if S.ExpelHarm:IsReadyP() and (S.ExpelHarm:Count() >= 3) and Player:Health() + HealingSphereHealingAvailable() < Player:MaxHealth() then
      if HR.Cast(S.ExpelHarm) then return ""; end
    end
    -- rushing_jade_wind,if=buff.rushing_jade_wind.down
    if S.RushingJadeWind:IsCastableP() and Player:BuffDownP(S.RushingJadeWind) then
      if HR.Cast(S.RushingJadeWind) then return ""; end
    end
    -- breath_of_fire,if=buff.blackout_combo.down&(buff.bloodlust.down|(buff.bloodlust.up&&dot.breath_of_fire_dot.refreshable))
    if S.BreathofFire:IsCastableP(10, true) and (Player:BuffDownP(S.BlackoutComboBuff) and (Player:HasNotHeroism() or (Player:HasHeroism() and true and Target:DebuffRefreshableCP(S.BreathofFireDotDebuff)))) then
      if HR.Cast(S.BreathofFire) then return ""; end
    end
    -- chi_burst
    if S.ChiBurst:IsCastableP(10) then
      if HR.Cast(S.ChiBurst) then return ""; end
    end
    -- chi_wave
    if S.ChiWave:IsCastableP(25) then
      if HR.Cast(S.ChiWave) then return ""; end
    end
    -- expel_harm,if=buff.gift_of_the_ox.stack>=2
    if S.ExpelHarm:IsReadyP() and (S.ExpelHarm:Count() >= 2) and Player:Health() + HealingSphereHealingAvailable() < Player:MaxHealth() then
      if HR.Cast(S.ExpelHarm) then return ""; end
    end
    -- tiger_palm,if=!talent.blackout_combo.enabled&cooldown.keg_smash.remains>gcd&(energy+(energy.regen*(cooldown.keg_smash.remains+gcd)))>=65
    if S.TigerPalm:IsCastableP("Melee") and (not S.BlackoutCombo:IsAvailable() and S.KegSmash:CooldownRemainsP() > Player:GCD() and (Player:Energy() + (Player:EnergyRegen() * (S.KegSmash:CooldownRemainsP() + Player:GCD()))) >= 65) then
      if HR.Cast(S.TigerPalm) then return ""; end
    end
    -- arcane_torrent,if=energy<31
    if HR.CDsON() and S.ArcaneTorrent:IsCastableP() and Player:Energy() < 31 then
      if HR.Cast(S.ArcaneTorrent, Settings.Brewmaster.OffGCDasOffGCD.ArcaneTorrent) then return ""; end
    end
    -- rushing_jade_wind
    if S.RushingJadeWind:IsCastableP() then
      if HR.Cast(S.RushingJadeWind) then return ""; end
    end
    -- downtime energy pooling
    if HR.Cast(S.PoolEnergy) then return "Pool Energy"; end
  end
end

HR.SetAPL(268, APL)
