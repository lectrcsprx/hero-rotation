--- Localize Vars
-- Addon
local addonName, addonTable = ...;
-- HeroLib
local HL = HeroLib;
local Cache = HeroCache;
local Unit = HL.Unit;
local Player = Unit.Player;
local Target = Unit.Target;
local Spell = HL.Spell;
local MultiSpell = HL.MultiSpell;
local Item = HL.Item;
-- HeroRotation
local HR = HeroRotation;
-- Lua
local pairs = pairs;
local mathfloor = math.floor;

--- APL Local Vars
-- Commons
local Everyone = HR.Commons.Everyone;
local Rogue = HR.Commons.Rogue;
-- Azerite Essence Setup
local AE         = HL.Enum.AzeriteEssences;
local AESpellIDs = HL.Enum.AzeriteEssenceSpellIDs;
-- Spells
if not Spell.Rogue then Spell.Rogue = {}; end
Spell.Rogue.Assassination = {
  -- Racials
  AncestralCall         = Spell(274738),
  ArcanePulse           = Spell(260364),
  ArcaneTorrent         = Spell(25046),
  BagofTricks           = Spell(312411),
  Berserking            = Spell(26297),
  BloodFury             = Spell(20572),
  Fireblood             = Spell(265221),
  LightsJudgment        = Spell(255647),
  Shadowmeld            = Spell(58984),
  -- Abilities
  Envenom               = Spell(32645),
  FanofKnives           = Spell(51723),
  Garrote               = Spell(703),
  KidneyShot            = Spell(408),
  Mutilate              = Spell(1329),
  PoisonedKnife         = Spell(185565),
  Rupture               = Spell(1943),
  Stealth               = Spell(1784),
  Stealth2              = Spell(115191), -- w/ Subterfuge Talent
  Vanish                = Spell(1856),
  VanishBuff            = Spell(11327),
  Vendetta              = Spell(79140),
  -- Talents
  Blindside             = Spell(111240),
  BlindsideBuff         = Spell(121153),
  CrimsonTempest        = Spell(121411),
  DeeperStratagem       = Spell(193531),
  Exsanguinate          = Spell(200806),
  HiddenBladesBuff      = Spell(270070),
  InternalBleeding      = Spell(154953),
  MarkedforDeath        = Spell(137619),
  MasterAssassin        = Spell(255989),
  Nightstalker          = Spell(14062),
  Subterfuge            = Spell(108208),
  SubterfugeBuff        = Spell(115192),
  ToxicBlade            = Spell(245388),
  ToxicBladeDebuff      = Spell(245389),
  VenomRush             = Spell(152152),
  -- Azerite Traits
  DoubleDose            = Spell(273007),
  EchoingBlades         = Spell(287649),
  ShroudedSuffocation   = Spell(278666),
  ScentOfBlood          = Spell(277679),
  TwistTheKnife         = Spell(273488),
  -- Essences
  BloodoftheEnemy       = Spell(297108),
  MemoryofLucidDreams   = Spell(298357),
  PurifyingBlast        = Spell(295337),
  RippleInSpace         = Spell(302731),
  ConcentratedFlame     = Spell(295373),
  TheUnboundForce       = Spell(298452),
  WorldveinResonance    = Spell(295186),
  FocusedAzeriteBeam    = Spell(295258),
  GuardianofAzeroth     = Spell(295840),
  ReapingFlames         = Spell(310690),
  BloodoftheEnemyDebuff = Spell(297108),
  RecklessForceBuff     = Spell(302932),
  RecklessForceCounter  = Spell(302917),
  LifebloodBuff         = Spell(295137),
  LucidDreamsBuff       = MultiSpell(298357, 299372, 299374),
  ConcentratedFlameBurn = Spell(295368),
  -- Defensive
  CrimsonVial           = Spell(185311),
  Feint                 = Spell(1966),
  -- Utility
  Blind                 = Spell(2094),
  Kick                  = Spell(1766),
  -- Poisons
  CripplingPoison       = Spell(3408),
  DeadlyPoison          = Spell(2823),
  DeadlyPoisonDebuff    = Spell(2818),
  WoundPoison           = Spell(8679),
  WoundPoisonDebuff     = Spell(8680),
  -- Misc
  TheDreadlordsDeceit   = Spell(208693),
  VigorTrinketBuff      = Spell(287916),
  RazorCoralDebuff      = Spell(303568),
  PoolEnergy            = Spell(9999000010)
};
local S = Spell.Rogue.Assassination;
-- Items
if not Item.Rogue then Item.Rogue = {}; end
Item.Rogue.Assassination = {
  -- Trinkets
  GalecallersBoon       = Item(159614, {13, 14}),
  LustrousGoldenPlumage = Item(159617, {13, 14}),
  ComputationDevice     = Item(167555, {13, 14}),
  VigorTrinket          = Item(165572, {13, 14}),
  FontOfPower           = Item(169314, {13, 14}),
  RazorCoral            = Item(169311, {13, 14}),
};
local I = Item.Rogue.Assassination;

-- Create table to exclude above trinkets from On Use function
local OnUseExcludes = {
  I.GalecallersBoon:ID(),
  I.LustrousGoldenPlumage:ID(),
  I.ComputationDevice:ID(),
  I.VigorTrinket:ID(),
  I.FontOfPower:ID(),
  I.RazorCoral:ID()
}

-- Spells Damage
S.Envenom:RegisterDamage(
  -- Envenom DMG Formula:
  --  AP * CP * Env_APCoef * Aura_M * ToxicB_M * DS_M * Mastery_M * Versa_M
  function ()
    return
      -- Attack Power
      Player:AttackPowerDamageMod() *
      -- Combo Points
      Rogue.CPSpend() *
      -- Envenom AP Coef
      0.16 *
      -- Aura Multiplier (SpellID: 137037)
      1.27 *
      -- Toxic Blade Multiplier
      (Target:DebuffP(S.ToxicBladeDebuff) and 1.3 or 1) *
      -- Deeper Stratagem Multiplier
      (S.DeeperStratagem:IsAvailable() and 1.05 or 1) *
      -- Mastery Finisher Multiplier
      (1 + Player:MasteryPct()/100) *
      -- Versatility Damage Multiplier
      (1 + Player:VersatilityDmgPct()/100);
  end
);
S.Mutilate:RegisterDamage(
  function ()
    return
      -- Attack Power (MH Factor + OH Factor)
      (Player:AttackPowerDamageMod() + Player:AttackPowerDamageMod(true)) *
      -- Mutilate Coefficient
      0.35 *
      -- Aura Multiplier (SpellID: 137037)
      1.27 *
      -- Versatility Damage Multiplier
      (1 + Player:VersatilityDmgPct()/100);
  end
);
local function NighstalkerMultiplier ()
  return S.Nightstalker:IsAvailable() and Player:IsStealthed(true, false) and 1.5 or 1;
end
local function SubterfugeGarroteMultiplier ()
  return S.Subterfuge:IsAvailable() and Player:IsStealthed(true, false) and 2 or 1;
end
S.Garrote:RegisterPMultiplier(
  {NighstalkerMultiplier},
  {SubterfugeGarroteMultiplier}
);
S.Rupture:RegisterPMultiplier(
  {NighstalkerMultiplier}
);

-- Rotation Var
local ShouldReturn; -- Used to get the return string
local BleedTickTime, ExsanguinatedBleedTickTime = 2 / Player:SpellHaste(), 1 / Player:SpellHaste();
local Stealth;
local RuptureThreshold, RuptureDMGThreshold, RuptureDurationThreshold, GarroteDMGThreshold, CrimsonTempestThreshold;
local ComboPoints, ComboPointsDeficit, Energy_Regen_Combined, PoisonedBleeds;
local PriorityRotation;

-- GUI Settings
local Settings = {
  General = HR.GUISettings.General,
  Commons = HR.GUISettings.APL.Rogue.Commons,
  Assassination = HR.GUISettings.APL.Rogue.Assassination
};

local function num(val)
  if val then return 1 else return 0 end
end

-- Check if the Priority Rotation variable should be set
local function UsePriorityRotation()
  if Cache.EnemiesCount[10] < 2 then
    return false
  end
  if Settings.Assassination.UsePriorityRotation == "Always" then
    return true
  end
  if Settings.Assassination.UsePriorityRotation == "On Bosses" and Target:IsInBossList() then
    return true
  end
  -- Zul Mythic
  if Player:InstanceDifficulty() == 16 and Target:NPCID() == 138967 then
    return true
  end
  return false
end

-- Handle CastLeftNameplate Suggestions for DoT Spells
local function SuggestCycleDoT(DoTSpell, DoTEvaluation, DoTMinTTD)
  -- Prefer melee cycle units
  local BestUnit, BestUnitTTD = nil, DoTMinTTD;
  local TargetGUID = Target:GUID();
  for _, CycleUnit in pairs(Cache.Enemies["Melee"]) do
    if CycleUnit:GUID() ~= TargetGUID and Everyone.UnitIsCycleValid(CycleUnit, BestUnitTTD, -CycleUnit:DebuffRemainsP(DoTSpell))
    and DoTEvaluation(CycleUnit) then
      BestUnit, BestUnitTTD = CycleUnit, CycleUnit:TimeToDie();
    end
  end
  if BestUnit then
    HR.CastLeftNameplate(BestUnit, DoTSpell);
  -- Check ranged units next, if the RangedMultiDoT option is enabled
  elseif Settings.Assassination.RangedMultiDoT then
    BestUnit, BestUnitTTD = nil, DoTMinTTD;
    for _, CycleUnit in pairs(Cache.Enemies[10]) do
      if CycleUnit:GUID() ~= TargetGUID and Everyone.UnitIsCycleValid(CycleUnit, BestUnitTTD, -CycleUnit:DebuffRemainsP(DoTSpell))
      and DoTEvaluation(CycleUnit) then
        BestUnit, BestUnitTTD = CycleUnit, CycleUnit:TimeToDie();
      end
    end
    if BestUnit then
      HR.CastLeftNameplate(BestUnit, DoTSpell);
    end
  end
end

-- Target If handler
-- Mode is "min", "max", or "first"
-- ModeEval the target_if condition (function with a target as param)
-- IfEval the condition on the resulting target (function with a target as param)
local function CheckTargetIfTarget(Mode, ModeEvaluation, IfEvaluation)
  -- First mode: Only check target if necessary
  local TargetsModeValue = ModeEvaluation(Target);
  if Mode == "first" and TargetsModeValue ~= 0 then
    return Target;
  end

  local BestUnit, BestValue = nil, 0;
  local function RunTargetIfCycler(Range)
    for _, CycleUnit in pairs(Cache.Enemies[Range]) do
      local ValueForUnit = ModeEvaluation(CycleUnit);
      if not BestUnit and Mode == "first" then
        if ValueForUnit ~= 0 then
          BestUnit, BestValue = CycleUnit, ValueForUnit;
        end
      elseif Mode == "min" then
        if not BestUnit or ValueForUnit < BestValue then
          BestUnit, BestValue = CycleUnit, ValueForUnit;
        end
      elseif Mode == "max" then
        if not BestUnit or ValueForUnit > BestValue then
          BestUnit, BestValue = CycleUnit, ValueForUnit;
        end
      end
      -- Same mode value, prefer longer TTD
      if BestUnit and ValueForUnit == BestValue and CycleUnit:TimeToDie() > BestUnit:TimeToDie() then
        BestUnit, BestValue = CycleUnit, ValueForUnit;
      end
    end
  end

  -- Prefer melee cycle units over ranged
  RunTargetIfCycler("Melee");
  if Settings.Assassination.RangedMultiDoT then
    RunTargetIfCycler(10);
  end
  -- Prefer current target if equal mode value results to prevent "flickering"
  if BestUnit and BestValue == TargetsModeValue and IfEvaluation(Target) then
    return Target;
  end
  if BestUnit and IfEvaluation(BestUnit) then
    return BestUnit;
  end
  return nil
end

-- Master Assassin Remains Check
local MasterAssassinBuff, NominalDuration = Spell(256735), 3;
local function MasterAssassinRemains ()
  if Player:BuffRemains(MasterAssassinBuff) < 0 then
    return Player:GCDRemains() + NominalDuration;
  else
    return Player:BuffRemainsP(MasterAssassinBuff);
  end
end

-- Fake ss_buffed (wonky without Subterfuge but why would you, eh?)
local function SSBuffed(TargetUnit)
  return S.ShroudedSuffocation:AzeriteEnabled() and TargetUnit:PMultiplier(S.Garrote) > 1;
end

-- non_ss_buffed_targets
local function NonSSBuffedTargets()
  local count = 0;
  for _, CycleUnit in pairs(Cache.Enemies[10]) do
    if not CycleUnit:DebuffP(S.Garrote) or not SSBuffed(CycleUnit) then
      count = count + 1;
    end
  end
  return count;
end

-- ss_buffed_targets_above_pandemic
local function SSBuffedTargetsAbovePandemic()
  local count = 0;
  for _, CycleUnit in pairs(Cache.Enemies[10]) do
    if CycleUnit:DebuffRemainsP(S.Garrote) > 5.4 and SSBuffed(CycleUnit) then
      count = count + 1;
    end
  end
  return count;
end

local MythicDungeon;
do
  local SappedSoulSpells = {
    {S.Kick, "Cast Kick (Sapped Soul)", function () return Target:IsInRange("Melee"); end},
    {S.Feint, "Cast Feint (Sapped Soul)", function () return true; end},
    {S.CrimsonVial, "Cast Crimson Vial (Sapped Soul)", function () return true; end}
  };
  MythicDungeon = function ()
    -- Sapped Soul
    if HL.MythicDungeon() == "Sapped Soul" then
      for i = 1, #SappedSoulSpells do
        local SappedSoulSpell = SappedSoulSpells[i];
        if SappedSoulSpell[1]:IsCastable() and SappedSoulSpell[3]() then
          HR.ChangePulseTimer(1);
          HR.Cast(SappedSoulSpell[1]);
          return SappedSoulSpell[2];
        end
      end
    end
    return false;
  end
end
local function TrainingScenario ()
  if Target:CastName() == "Unstable Explosion" and Target:CastPercentage() > 60-10*ComboPoints then
    -- Kidney Shot
    if S.KidneyShot:IsCastable("Melee") and ComboPoints > 0 then
      if HR.Cast(S.KidneyShot) then return "Cast Kidney Shot (Unstable Explosion)"; end
    end
  end
  return false;
end
local Interrupts = {
  {S.Blind, "Cast Blind (Interrupt)", function () return true; end},
  {S.KidneyShot, "Cast Kidney Shot (Interrupt)", function () return ComboPoints > 0; end}
}

-- APL Action Lists (and Variables)
-- # Essences
local function Essences ()
  -- actions.essences+=/blood_of_the_enemy,if=debuff.vendetta.up&(exsanguinated.garrote|debuff.toxic_blade.up&combo_points.deficit<=1|debuff.vendetta.remains<=10)|fight_remains<=10
  if S.BloodoftheEnemy:IsCastableP() and (Target:DebuffP(S.Vendetta) and (HL.Exsanguinated(Target, S.Garrote)
    or (Target:DebuffP(S.ToxicBladeDebuff) and Player:ComboPointsDeficit() <= 1) or Target:DebuffRemainsP(S.Vendetta) <= 10)
    or HL.BossFilteredFightRemains("<=", 10)) then
    if HR.Cast(S.BloodoftheEnemy, nil, Settings.Commons.EssenceDisplayStyle) then return "Cast BloodoftheEnemy"; end
  end
  -- concentrated_flame,if=energy.time_to_max>1&!debuff.vendetta.up&(!dot.concentrated_flame_burn.ticking&!action.concentrated_flame.in_flight|full_recharge_time<gcd.max)
  if S.ConcentratedFlame:IsCastableP() and Player:EnergyTimeToMaxPredicted() > 1 and not Target:DebuffP(S.Vendetta) and (not Target:DebuffP(S.ConcentratedFlameBurn)
    and not Player:PrevGCD(1, S.ConcentratedFlame) or S.ConcentratedFlame:FullRechargeTime() < Player:GCD() + Player:GCDRemains()) then
    if HR.Cast(S.ConcentratedFlame, nil, Settings.Commons.EssenceDisplayStyle) then return "Cast ConcentratedFlame"; end
  end
  if S.GuardianofAzeroth:IsCastableP() then
    -- guardian_of_azeroth,if=cooldown.vendetta.remains<3|debuff.vendetta.up|fight_remains<30
    if S.Vendetta:CooldownRemainsP() < 3 or Target:DebuffP(S.Vendetta) or HL.BossFilteredFightRemains("<", 30) then
      if HR.Cast(S.GuardianofAzeroth, nil, Settings.Commons.EssenceDisplayStyle) then return "Cast GuardianofAzeroth Synced"; end
    elseif not HL.BossFightRemainsIsNotValid() then
      local BossFightRemains = HL.BossFightRemains()
      -- guardian_of_azeroth,if=floor((fight_remains-30)%cooldown)>floor((fight_remains-30-cooldown.vendetta.remains)%cooldown)
      if mathfloor(BossFightRemains - 30 / 180) > mathfloor((BossFightRemains - 30 - S.Vendetta:CooldownRemainsP()) / 180) then
        if HR.Cast(S.GuardianofAzeroth, nil, Settings.Commons.EssenceDisplayStyle) then return "Cast GuardianofAzeroth Desynced"; end
      end
    end
  end
  -- focused_azerite_beam,if=spell_targets.fan_of_knives>=2|raid_event.adds.in>60&energy<70|fight_remains<10
  if S.FocusedAzeriteBeam:IsCastableP() and (Player:EnergyPredicted() < 70 or HL.BossFilteredFightRemains("<", 10)) then
    if HR.Cast(S.FocusedAzeriteBeam, nil, Settings.Commons.EssenceDisplayStyle) then return "Cast FocusedAzeriteBeam"; end
  end
  -- purifying_blast,if=spell_targets.fan_of_knives>=2|raid_event.adds.in>60|fight_remains<10
  if S.PurifyingBlast:IsCastableP() then
    if HR.Cast(S.PurifyingBlast, nil, Settings.Commons.EssenceDisplayStyle) then return "Cast PurifyingBlast"; end
  end
  -- actions.essences+=/the_unbound_force,if=buff.reckless_force.up|buff.reckless_force_counter.stack<10
  if S.TheUnboundForce:IsCastableP() and (Player:BuffP(S.RecklessForceBuff) or Player:BuffStackP(S.RecklessForceCounter) < 10) then
    if HR.Cast(S.TheUnboundForce, nil, Settings.Commons.EssenceDisplayStyle) then return "Cast TheUnboundForce"; end
  end
  -- ripple_in_space
  if S.RippleInSpace:IsCastableP() then
    if HR.Cast(S.RippleInSpace, nil, Settings.Commons.EssenceDisplayStyle) then return "Cast RippleInSpace"; end
  end
  -- worldvein_resonance
  if S.WorldveinResonance:IsCastableP() then
    if HR.Cast(S.WorldveinResonance, nil, Settings.Commons.EssenceDisplayStyle) then return "Cast WorldveinResonance"; end
  end
  -- memory_of_lucid_dreams,if=energy<50&!cooldown.vendetta.up
  if S.MemoryofLucidDreams:IsCastableP() and Player:EnergyPredicted() < 50 and not S.Vendetta:CooldownUpP() then
    if HR.Cast(S.MemoryofLucidDreams, nil, Settings.Commons.EssenceDisplayStyle) then return "Cast MemoryofLucidDreams"; end
  end
  -- reaping_flames,if=target.health.pct>80|target.health.pct<=20|target.time_to_pct_20>30
  ShouldReturn = Everyone.ReapingFlamesCast(Settings.Commons.EssenceDisplayStyle);
  if ShouldReturn then return ShouldReturn; end

  return false;
end

local function Trinkets ()
  -- use_item,name=galecallers_boon,if=(debuff.vendetta.up|(!talent.exsanguinate.enabled&cooldown.vendetta.remains>45|talent.exsanguinate.enabled&(cooldown.exsanguinate.remains<6|cooldown.exsanguinate.remains>20&fight_remains>65)))&!exsanguinated.rupture
  if I.GalecallersBoon:IsEquipped() and I.GalecallersBoon:IsReady() then
    if (Target:DebuffP(S.Vendetta) or (not S.Exsanguinate:IsAvailable() and S.Vendetta:CooldownRemains() > 45
      or S.Exsanguinate:IsAvailable() and (S.Exsanguinate:CooldownRemainsP() < 6 or S.Exsanguinate:CooldownRemainsP() > 20 and HL.FilteredFightRemains(10, ">", 65, true))))
      and not HL.Exsanguinated(Target, S.Rupture) then
      if HR.Cast(I.GalecallersBoon, nil, Settings.Commons.TrinketDisplayStyle) then return "Cast Galecallers Boon"; end
    end
  end
  -- use_item,name=lustrous_golden_plumage,if=debuff.vendetta.up
  if I.LustrousGoldenPlumage:IsEquipped() and I.LustrousGoldenPlumage:IsReady() and Target:Debuff(S.Vendetta) then
    if HR.Cast(I.LustrousGoldenPlumage, nil, Settings.Commons.TrinketDisplayStyle) then return "Cast Golden Plumage"; end
  end
  -- if=master_assassin_remains=0&!debuff.vendetta.up&!debuff.toxic_blade.up&buff.memory_of_lucid_dreams.down&energy<80&dot.rupture.remains>4
  if I.ComputationDevice:IsEquipped() and I.ComputationDevice:IsReady() and MasterAssassinRemains() <= 0 and not Target:DebuffP(S.Vendetta)
    and not Target:DebuffP(S.ToxicBladeDebuff) and not Player:BuffP(S.LucidDreamsBuff) and Player:EnergyPredicted() < 80 and Target:DebuffRemainsP(S.Rupture) > 4 then
    if HR.Cast(I.ComputationDevice, nil, Settings.Commons.TrinketDisplayStyle) then return "Cast Computation Device"; end
  end
  if I.RazorCoral:IsEquipped() and I.RazorCoral:IsReady() then
    -- use_item,name=ashvanes_razor_coral,if=(!talent.exsanguinate.enabled|!talent.subterfuge.enabled)&debuff.vendetta.remains>10-4*equipped.azsharas_font_of_power
    if (not S.Exsanguinate:IsAvailable() or not S.Subterfuge:IsAvailable()) and Target:DebuffRemainsP(S.Vendetta) > 10 - 4 * num(I.FontOfPower:IsEquipped()) then
      if HR.Cast(I.RazorCoral, nil, Settings.Commons.TrinketDisplayStyle) then return "Razor Coral Default Sync"; end
    end
    -- use_item,name=ashvanes_razor_coral,if=(talent.exsanguinate.enabled&talent.subterfuge.enabled)&debuff.vendetta.up&(exsanguinated.garrote|azerite.shrouded_suffocation.enabled&dot.garrote.pmultiplier>1)
    if (S.Exsanguinate:IsAvailable() and S.Subterfuge:IsAvailable()) and Target:DebuffRemainsP(S.Vendetta) > 10
      and (HL.Exsanguinated(Target, S.Garrote) or S.ShroudedSuffocation:AzeriteEnabled() and Target:PMultiplier(S.Garrote) > 1) then
      if HR.Cast(I.RazorCoral, nil, Settings.Commons.TrinketDisplayStyle) then return "Razor Coral Exsanguinate Sync"; end
    end
  end
  -- V.I.G.O.R. trinket, emulate SimC default behavior to use at max stacks
  if I.VigorTrinket:IsEquipped() and I.VigorTrinket:IsReady() and Player:BuffStack(S.VigorTrinketBuff) == 6 then
    if HR.Cast(I.VigorTrinket, nil, Settings.Commons.TrinketDisplayStyle) then return "Cast Vigor Trinket"; end
  end
  -- use_items
  local TrinketToUse = HL.UseTrinkets(OnUseExcludes)
  if TrinketToUse then
    if HR.Cast(TrinketToUse, nil, Settings.Commons.TrinketDisplayStyle) then return "Generic use_items for " .. TrinketToUse:Name(); end
  end

  return false
end

local function Racials ()
  -- actions.cds+=/blood_fury,if=debuff.vendetta.up
  if S.BloodFury:IsCastable() then
    if HR.Cast(S.BloodFury, Settings.Commons.OffGCDasOffGCD.Racials) then return "Cast Blood Fury"; end
  end
  -- actions.cds+=/berserking,if=debuff.vendetta.up
  if S.Berserking:IsCastable() then
    if HR.Cast(S.Berserking, Settings.Commons.OffGCDasOffGCD.Racials) then return "Cast Berserking"; end
  end
  -- actions.cds+=/fireblood,if=debuff.vendetta.up
  if S.Fireblood:IsCastable() then
    if HR.Cast(S.Fireblood, Settings.Commons.OffGCDasOffGCD.Racials) then return "Cast Fireblood"; end
  end
  -- actions.cds+=/ancestral_call,if=debuff.vendetta.up
  if S.AncestralCall:IsCastable() then
    if HR.Cast(S.AncestralCall, Settings.Commons.OffGCDasOffGCD.Racials) then return "Cast Ancestral Call"; end
  end

  return false
end

-- # Cooldowns
local function CDs ()
  -- Special Font of Power Handling
  if Settings.Commons.UseTrinkets then
    -- use_item,name=azsharas_font_of_power,if=!stealthed.all&master_assassin_remains=0&(cooldown.vendetta.remains<?cooldown.toxic_blade.remains)<10+10*equipped.ashvanes_razor_coral&!debuff.vendetta.up&!debuff.toxic_blade.up
    if I.FontOfPower:IsEquipped() and I.FontOfPower:IsReady() and not Player:IsStealthedP(true, true) and MasterAssassinRemains() <= 0
      and math.max(S.Vendetta:CooldownRemainsP(), S.ToxicBlade:CooldownRemainsP() * num(I.RazorCoral:IsEquipped())) < 10 + 10 * num(I.RazorCoral:IsEquipped())
      and not Target:DebuffP(S.Vendetta) and not Target:DebuffP(S.ToxicBladeDebuff) then
      if HR.Cast(I.FontOfPower, nil, Settings.Commons.TrinketDisplayStyle) then return "Use Font of Power"; end
    end
    if I.RazorCoral:IsEquipped() and I.RazorCoral:IsReady() then
      -- use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.down|fight_remains<20
      if S.RazorCoralDebuff:ActiveCount() == 0 or HL.BossFilteredFightRemains("<", 20) then
        if HR.Cast(I.RazorCoral, nil, Settings.Commons.TrinketDisplayStyle) then return "Cast Razor Coral"; end
      end
    end
  end

  if Target:IsInRange("Melee") then
    -- actions.cds+=/call_action_list,name=essences,if=!stealthed.all&dot.rupture.ticking&master_assassin_remains=0
    if HR.CDsON() and not Player:IsStealthedP(true, true) and Target:DebuffP(S.Rupture) and MasterAssassinRemains() <= 0 then
      ShouldReturn = Essences();
      if ShouldReturn then return ShouldReturn; end
    end

    -- actions.cds+=/marked_for_death,target_if=min:target.time_to_die,if=target.time_to_die<combo_points.deficit*1.5|(raid_event.adds.in>40&combo_points.deficit>=cp_max_spend)
    if S.MarkedforDeath:IsCastableP() then
      if Target:FilteredTimeToDie("<", Player:ComboPointsDeficit() * 1.5) then
        if HR.Cast(S.MarkedforDeath, Settings.Commons.OffGCDasOffGCD.MarkedforDeath) then return "Cast Marked for Death"; end
      end
      if ComboPointsDeficit >= Rogue.CPMaxSpend() then
        HR.CastSuggested(S.MarkedforDeath);
      end
    end

    if HR.CDsON() then
      -- actions.cds+=/vendetta,if=!stealthed.rogue&dot.rupture.ticking&!debuff.vendetta.up&variable.vendetta_subterfuge_condition&variable.vendetta_nightstalker_condition&variable.vendetta_font_condition
      if S.Vendetta:IsCastableP() and not Player:IsStealthedP(true, false) and Target:DebuffP(S.Rupture) and not Target:DebuffP(S.Vendetta) then
        -- actions.cds+=/variable,name=vendetta_subterfuge_condition,value=!talent.subterfuge.enabled|!azerite.shrouded_suffocation.enabled|dot.garrote.pmultiplier>1&(spell_targets.fan_of_knives<6|!cooldown.vanish.up)
        local SubterfugeCondition = (not S.Subterfuge:IsAvailable() or not S.ShroudedSuffocation:AzeriteEnabled() or Target:PMultiplier(S.Garrote) > 1
          and (Cache.EnemiesCount[10] < 6 or not S.Vanish:CooldownUpP()))
        -- actions.cds+=/variable,name=vendetta_nightstalker_condition,value=!talent.nightstalker.enabled|!talent.exsanguinate.enabled|cooldown.exsanguinate.remains<5-2*talent.deeper_stratagem.enabled
        local NightstalkerCondition = (not S.Nightstalker:IsAvailable() or not S.Exsanguinate:IsAvailable()
          or S.Exsanguinate:CooldownRemainsP() < 5 - 2 * num(S.DeeperStratagem:IsAvailable()))
        -- actions.cds+=/variable,name=vendetta_font_condition,value=!equipped.azsharas_font_of_power|azerite.shrouded_suffocation.enabled|debuff.razor_coral_debuff.down|trinket.ashvanes_razor_coral.cooldown.remains<10&(cooldown.toxic_blade.remains<1|debuff.toxic_blade.up)
        local FontCondition = (not Settings.Commons.UseTrinkets or not I.FontOfPower:IsEquipped() or S.ShroudedSuffocation:AzeriteEnabled()
          or S.RazorCoralDebuff:ActiveCount() == 0 or I.RazorCoral:CooldownRemains() < 10 and (S.ToxicBlade:CooldownRemainsP() < 1 or Target:DebuffP(S.ToxicBladeDebuff)))
        if SubterfugeCondition and NightstalkerCondition and FontCondition then
          if HR.Cast(S.Vendetta, Settings.Assassination.GCDasOffGCD.Vendetta) then return "Cast Vendetta"; end
        end
      end
      if S.Vanish:IsCastableP() and not Player:IsTanking(Target) then
        local VanishSuggested = false;
        if S.Nightstalker:IsAvailable() then
          -- actions.cds+=/vanish,if=talent.exsanguinate.enabled&talent.nightstalker.enabled&combo_points>=cp_max_spend&cooldown.exsanguinate.remains<1
          if not VanishSuggested and S.Exsanguinate:IsAvailable() and ComboPoints >= Rogue.CPMaxSpend() and S.Exsanguinate:CooldownRemainsP() < 1 then
            if HR.Cast(S.Vanish, Settings.Commons.OffGCDasOffGCD.Vanish) then return "Cast Vanish (Exsanguinate)"; end
            VanishSuggested = true;
          end
          -- actions.cds+=/vanish,if=talent.nightstalker.enabled&!talent.exsanguinate.enabled&combo_points>=cp_max_spend&(debuff.vendetta.up|essence.vision_of_perfection.enabled)
          if not VanishSuggested and not S.Exsanguinate:IsAvailable() and ComboPoints >= Rogue.CPMaxSpend()
            and (Target:Debuff(S.Vendetta) or Spell:EssenceEnabled(AE.VisionofPerfection)) then
            if HR.Cast(S.Vanish, Settings.Commons.OffGCDasOffGCD.Vanish) then return "Cast Vanish (Nightstalker)"; end
            VanishSuggested = true;
          end
        end
        -- actions.cds+=/variable,name=ss_vanish_condition,value=azerite.shrouded_suffocation.enabled&(non_ss_buffed_targets>=1|spell_targets.fan_of_knives=3)&(ss_buffed_targets_above_pandemic=0|spell_targets.fan_of_knives>=6)
        local VarSSVanishCondition = S.ShroudedSuffocation:AzeriteEnabled() and (NonSSBuffedTargets() >= 1 or Cache.EnemiesCount[10] == 3)
          and (SSBuffedTargetsAbovePandemic() == 0 or Cache.EnemiesCount[10] >= 6);
        -- actions.cds+=/vanish,if=talent.subterfuge.enabled&!stealthed.rogue&cooldown.garrote.up&(variable.ss_vanish_condition|!azerite.shrouded_suffocation.enabled&(dot.garrote.refreshable|debuff.vendetta.up&dot.garrote.pmultiplier<=1))&combo_points.deficit>=((1+2*azerite.shrouded_suffocation.enabled)*spell_targets.fan_of_knives)>?4&raid_event.adds.in>12
        if not VanishSuggested and S.Subterfuge:IsAvailable() and not Player:IsStealthedP(true, false) and S.Garrote:CooldownUpP()
          and (VarSSVanishCondition or not S.ShroudedSuffocation:AzeriteEnabled()
            and (Target:DebuffRefreshableP(S.Garrote, 5.4) or Target:DebuffP(S.Vendetta) and Target:PMultiplier(S.Garrote) <= 1))
          and ComboPointsDeficit >= math.min((1 + 2 * num(S.ShroudedSuffocation:AzeriteEnabled())) * Cache.EnemiesCount[10], 4) then
          -- actions.cds+=/pool_resource,for_next=1,extra_amount=45
          if not Settings.Assassination.NoPooling and Player:EnergyPredicted() < 45 then
            if HR.Cast(S.PoolEnergy) then return "Pool for Vanish (Subterfuge)"; end
          end
          if HR.Cast(S.Vanish, Settings.Commons.OffGCDasOffGCD.Vanish) then return "Cast Vanish (Subterfuge)"; end
          VanishSuggested = true;
        end
        -- actions.cds+=/vanish,if=talent.master_assassin.enabled&!stealthed.all&master_assassin_remains<=0&!dot.rupture.refreshable&dot.garrote.remains>3&debuff.vendetta.up&(!talent.toxic_blade.enabled|debuff.toxic_blade.up)&(!essence.blood_of_the_enemy.major|debuff.blood_of_the_enemy.up)
        if not VanishSuggested and S.MasterAssassin:IsAvailable() and not Player:IsStealthedP(true, false) and MasterAssassinRemains() <= 0
          and not Target:DebuffRefreshableP(S.Rupture, RuptureThreshold) and Target:DebuffRemainsP(S.Garrote) > 3
          and (Target:DebuffP(S.Vendetta) and (not S.ToxicBlade:IsAvailable() or Target:DebuffP(S.ToxicBladeDebuff))
          and (not Spell:MajorEssenceEnabled(AE.BloodoftheEnemy) or Target:DebuffP(S.BloodoftheEnemyDebuff))
            or Spell:EssenceEnabled(AE.VisionofPerfection)) then
          if HR.Cast(S.Vanish, Settings.Commons.OffGCDasOffGCD.Vanish) then return "Cast Vanish (Master Assassin)"; end
        end
      end
      -- actions.cds+=/shadowmeld,if=!stealthed.all&azerite.shrouded_suffocation.enabled&dot.garrote.refreshable&dot.garrote.pmultiplier<=1&combo_points.deficit>=1
      if HR.CDsON() and S.Shadowmeld:IsCastable() and not Player:IsStealthedP(true, true) and S.ShroudedSuffocation:AzeriteEnabled() and Target:DebuffRefreshableP(S.Garrote, 5.4) and Target:PMultiplier(S.Garrote) <= 1 and Player:ComboPointsDeficit() >= 1 then
        if HR.Cast(S.Shadowmeld, Settings.Commons.OffGCDasOffGCD.Racials) then return "Cast Shadowmeld"; end
      end
      if S.Exsanguinate:IsCastableP() then
        -- actions.cds+=/exsanguinate,if=!stealthed.rogue&(!dot.garrote.refreshable&dot.rupture.remains>4+4*cp_max_spend|dot.rupture.remains*0.5>target.time_to_die)&target.time_to_die>4
        if not Player:IsStealthedP(true, false) and (not Target:DebuffRefreshableP(S.Garrote, 5.4) and Target:DebuffRemainsP(S.Rupture) > 4+4*Rogue.CPMaxSpend()
          or Target:FilteredTimeToDie("<", Target:DebuffRemainsP(S.Rupture)*0.5)) and (Target:FilteredTimeToDie(">", 4) or Target:TimeToDieIsNotValid())
          and Rogue.CanDoTUnit(Target, RuptureDMGThreshold) then
          if HR.Cast(S.Exsanguinate) then return "Cast Exsanguinate"; end
        end
      end
      -- actions.cds+=/toxic_blade,if=dot.rupture.ticking&(!equipped.azsharas_font_of_power|cooldown.vendetta.remains>10)
      if S.ToxicBlade:IsCastableP("Melee") and Target:DebuffP(S.Rupture)
        and (not Settings.Commons.UseTrinkets or not I.FontOfPower:IsEquipped() or S.Vendetta:CooldownRemainsP() > 10) then
        if HR.Cast(S.ToxicBlade) then ShouldReturn = "Cast Toxic Blade"; end
      end
    end

    -- actions.cds=potion,if=buff.bloodlust.react|target.time_to_die<=60|debuff.vendetta.up&cooldown.vanish.remains<5

    -- Trinkets
    if Settings.Commons.UseTrinkets and (not ShouldReturn or Settings.Commons.TrinketDisplayStyle ~= "Main Icon") then
      if ShouldReturn then
        Trinkets()
      else
        ShouldReturn = Trinkets()
      end
    end

    -- Racials
    if HR.CDsON() and Target:DebuffP(S.Vendetta) and (not ShouldReturn or Settings.Commons.OffGCDasOffGCD.Racials) then
      if ShouldReturn then
        Racials()
      else
        ShouldReturn = Racials()
      end
    end
  end

  return ShouldReturn;
end

-- # Stealthed
local function Stealthed ()
  -- actions.stealthed=rupture,if=talent.nightstalker.enabled&combo_points>=4&target.time_to_die-remains>6
  if S.Rupture:IsReadyP("Melee") and S.Nightstalker:IsAvailable() and ComboPoints >= 4
    and (Target:FilteredTimeToDie(">", 6, -Target:DebuffRemainsP(S.Rupture)) or Target:TimeToDieIsNotValid()) then
    if HR.Cast(S.Rupture) then return "Cast Rupture (Nightstalker)"; end
  end
  if S.Garrote:IsCastableP("Melee") and S.Subterfuge:IsAvailable() then
    -- actions.stealthed+=/pool_resource,for_next=1
    -- actions.stealthed+=/garrote,if=azerite.shrouded_suffocation.enabled&buff.subterfuge.up&buff.subterfuge.remains<1.3&!ss_buffed
    -- Not implemented because this is special for simc and we can have a shifting main target in reality where simc checks only a fix target on all normal abilities.
    -- actions.stealthed+=/pool_resource,for_next=1
    -- actions.stealthed+=/garrote,target_if=min:remains,if=talent.subterfuge.enabled&(remains<12|pmultiplier<=1)&target.time_to_die-remains>2
    local function GarroteTargetIfFunc(TargetUnit)
      return TargetUnit:DebuffRemainsP(S.Garrote);
    end
    local function GarroteIfFunc(TargetUnit)
      return (TargetUnit:DebuffRemainsP(S.Garrote) < 12 or TargetUnit:PMultiplier(S.Garrote) <= 1)
        and (TargetUnit:FilteredTimeToDie(">", 2, -TargetUnit:DebuffRemainsP(S.Garrote)) or TargetUnit:TimeToDieIsNotValid())
        and Rogue.CanDoTUnit(TargetUnit, GarroteDMGThreshold);
    end
    if HR.AoEON() then
      local TargetIfUnit = CheckTargetIfTarget("min", GarroteTargetIfFunc, GarroteIfFunc);
      if TargetIfUnit and TargetIfUnit:GUID() ~= Target:GUID() then
        HR.CastLeftNameplate(TargetIfUnit, S.Garrote);
      end
    end
    if GarroteIfFunc(Target) then
      if HR.CastPooling(S.Garrote) then return "Cast Garrote (Subterfuge)"; end
    end
  end
  -- actions.stealthed+=/rupture,if=talent.subterfuge.enabled&azerite.shrouded_suffocation.enabled&!dot.rupture.ticking&variable.single_target
  if S.Rupture:IsReadyP("Melee") and S.Subterfuge:IsAvailable() and ComboPoints > 0 and S.ShroudedSuffocation:AzeriteEnabled()
    and not Target:DebuffP(S.Rupture) and Cache.EnemiesCount[10] < 2 then
    if HR.Cast(S.Rupture) then return "Cast Rupture (Shrouded Suffocation)"; end
  end
  if S.Garrote:IsCastableP("Melee") and S.Subterfuge:IsAvailable() then
    -- actions.stealthed+=/pool_resource,for_next=1
    -- actions.stealthed+=/garrote,target_if=min:remains,if=talent.subterfuge.enabled&azerite.shrouded_suffocation.enabled&(active_enemies>1|!talent.exsanguinate.enabled)&target.time_to_die>remains&(remains<18|!ss_buffed)
    local function GarroteTargetIfFunc(TargetUnit)
      return TargetUnit:DebuffRemainsP(S.Garrote);
    end
    local function GarroteIfFunc(TargetUnit)
      return S.ShroudedSuffocation:AzeriteEnabled()
        and (Cache.EnemiesCount[10] > 1 or not S.Exsanguinate:IsAvailable())
        and (TargetUnit:FilteredTimeToDie(">", 0, -TargetUnit:DebuffRemainsP(S.Garrote)) or TargetUnit:TimeToDieIsNotValid())
        and (TargetUnit:DebuffRemainsP(S.Garrote) < 18 or not SSBuffed(TargetUnit))
        and Rogue.CanDoTUnit(TargetUnit, GarroteDMGThreshold);
    end
    if HR.AoEON() then
      local TargetIfUnit = CheckTargetIfTarget("min", GarroteTargetIfFunc, GarroteIfFunc);
      if TargetIfUnit and TargetIfUnit:GUID() ~= Target:GUID() then
        HR.CastLeftNameplate(TargetIfUnit, S.Garrote);
      end
    end
    if GarroteIfFunc(Target) then
      if HR.CastPooling(S.Garrote) then return "Cast Garrote (Shrouded Suffocation)"; end
    end
    -- actions.stealthed+=/pool_resource,for_next=1
    -- actions.stealthed+=/garrote,if=talent.subterfuge.enabled&talent.exsanguinate.enabled&active_enemies=1&buff.subterfuge.remains<1.3
    if S.Exsanguinate:IsAvailable() and Cache.EnemiesCount[10] == 1 and Player:BuffRemainsP(S.SubterfugeBuff) < 1.3 then
      if HR.CastPooling(S.Garrote) then return "Pool for Garrote (Exsanguinate Refresh)"; end
    end
  end
end

-- # Damage over time abilities
local function Dot ()
  local SkipCycleGarrote, SkipCycleRupture, SkipRupture
  if PriorityRotation and Cache.EnemiesCount[10] > 3 then
    -- actions.dot=variable,name=skip_cycle_garrote,value=priority_rotation&spell_targets.fan_of_knives>3&(dot.garrote.remains<cooldown.garrote.duration|poisoned_bleeds>5)
    SkipCycleGarrote = Target:DebuffRemainsP(S.Garrote) < 6 or PoisonedBleeds > 5
    -- actions.dot+=/variable,name=skip_cycle_rupture,value=priority_rotation&spell_targets.fan_of_knives>3&(debuff.toxic_blade.up|(poisoned_bleeds>5&!azerite.scent_of_blood.enabled))
    SkipCycleRupture = Target:DebuffP(S.ToxicBladeDebuff) or (PoisonedBleeds > 5 and not S.ScentOfBlood:AzeriteEnabled())
  end
  -- actions.dot+=/variable,name=skip_rupture,value=debuff.vendetta.up&(debuff.toxic_blade.up|master_assassin_remains>0)&dot.rupture.remains>2
  SkipRupture = Target:DebuffP(S.Vendetta) and (Target:DebuffP(S.ToxicBladeDebuff) or MasterAssassinRemains() > 0) and Target:DebuffRemainsP(S.Rupture) > 2

  if HR.CDsON() and S.Exsanguinate:IsAvailable() then
    -- actions.dot+=/pool_resource,for_next=1
    -- actions.dot+=/garrote,if=talent.exsanguinate.enabled&!exsanguinated.garrote&dot.garrote.pmultiplier<=1&cooldown.exsanguinate.remains<2&spell_targets.fan_of_knives=1&raid_event.adds.in>6&dot.garrote.remains*0.5<target.time_to_die
    if S.Garrote:IsCastableP("Melee") and Cache.EnemiesCount[10] == 1 and S.Exsanguinate:CooldownRemainsP() < 2 and not HL.Exsanguinated(Target, S.Garrote)
      and Target:PMultiplier(S.Garrote) <= 1 and Target:FilteredTimeToDie(">", Target:DebuffRemainsP(S.Garrote)*0.5) then
      if HR.CastPooling(S.Garrote) then return "Cast Garrote (Pre-Exsanguinate)"; end
    end
    -- actions.dot+=/rupture,if=talent.exsanguinate.enabled&!dot.garrote.refreshable&(combo_points>=cp_max_spend&cooldown.exsanguinate.remains<1&dot.rupture.remains*0.5<target.time_to_die)
    if S.Rupture:IsReadyP("Melee") and ComboPoints > 0 and not Target:DebuffRefreshableP(S.Garrote, 5.4)
      and (ComboPoints >= Rogue.CPMaxSpend() and S.Exsanguinate:CooldownRemainsP() < 1 and Target:FilteredTimeToDie(">", Target:DebuffRemainsP(S.Rupture)*0.5)) then
      if HR.Cast(S.Rupture) then return "Cast Rupture (Pre-Exsanguinate)"; end
    end
  end
  -- actions.dot+=/pool_resource,for_next=1
  -- actions.dot+=/garrote,if=refreshable&combo_points.deficit>=1+3*(azerite.shrouded_suffocation.enabled&cooldown.vanish.up)&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&(!exsanguinated|remains<=tick_time*2&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&!ss_buffed&(target.time_to_die-remains)>4&(master_assassin_remains=0|!ticking&azerite.shrouded_suffocation.enabled)
  -- actions.dot+=/pool_resource,for_next=1
  -- actions.dot+=/garrote,cycle_targets=1,if=!variable.skip_cycle_garrote&target!=self.target&refreshable&combo_points.deficit>=1+3*(azerite.shrouded_suffocation.enabled&cooldown.vanish.up)&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&(!exsanguinated|remains<=tick_time*2&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&!ss_buffed&(target.time_to_die-remains)>12&(master_assassin_remains=0|!ticking&azerite.shrouded_suffocation.enabled)
  local EmpoweredDotRefresh = Cache.EnemiesCount[10] >= 3 + num(S.ShroudedSuffocation:AzeriteEnabled())
  if S.Garrote:IsCastableP() and (ComboPointsDeficit >= 1 + 3 * num(S.ShroudedSuffocation:AzeriteEnabled() and S.Vanish:CooldownUpP())) then
    local function Evaluate_Garrote_Target(TargetUnit)
      return TargetUnit:DebuffRefreshableP(S.Garrote, 5.4)
        and (TargetUnit:PMultiplier(S.Garrote) <= 1 or TargetUnit:DebuffRemainsP(S.Garrote)
          <= (HL.Exsanguinated(TargetUnit, S.Garrote) and ExsanguinatedBleedTickTime or BleedTickTime) and EmpoweredDotRefresh)
        and (not HL.Exsanguinated(TargetUnit, S.Garrote) or TargetUnit:DebuffRemainsP(S.Garrote) <= 1.5 and EmpoweredDotRefresh)
        and not SSBuffed(TargetUnit)
        and (MasterAssassinRemains() <= 0 or not Target:DebuffP(S.Garrote) and S.ShroudedSuffocation:AzeriteEnabled())
        and Rogue.CanDoTUnit(TargetUnit, GarroteDMGThreshold);
    end
    if Target:IsInRange("Melee") and Evaluate_Garrote_Target(Target)
      and (Target:FilteredTimeToDie(">", 4, -Target:DebuffRemainsP(S.Garrote)) or Target:TimeToDieIsNotValid()) then
      if HR.CastPooling(S.Garrote) then return "Pool for Garrote (ST)"; end
    end
    if HR.AoEON() and not SkipCycleGarrote then
      SuggestCycleDoT(S.Garrote, Evaluate_Garrote_Target, 12);
    end
  end
  -- actions.dot+=/crimson_tempest,target_if=min:remains,if=spell_targets>3&remains<2+(spell_targets>=5)&combo_points>=4
  if HR.AoEON() and S.CrimsonTempest:IsReadyP() and ComboPoints >= 4 and Cache.EnemiesCount[10] > 3 then
    for _, CycleUnit in pairs(Cache.Enemies[10]) do
      -- Note: The APL does not do this due to target_if mechanics, just to determine if any targets are low on duration of the AoE Bleed
      if CycleUnit:DebuffRemainsP(S.CrimsonTempest) < 2 + num(Cache.EnemiesCount[10] >= 5) then
        if HR.Cast(S.CrimsonTempest) then return "Cast Crimson Tempest (AoE 4+)"; end
      end
    end
  end
  -- actions.dot+=/rupture,if=!variable.skip_rupture&(combo_points>=4&refreshable|!ticking&(time>10|combo_points>=2))&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&(!exsanguinated|remains<=tick_time*2&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&target.time_to_die-remains>4
  -- actions.dot+=/rupture,cycle_targets=1,if=!variable.skip_cycle_rupture&!variable.skip_rupture&target!=self.target&combo_points>=4&refreshable&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&(!exsanguinated|remains<=tick_time*2&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&target.time_to_die-remains>4+(poisoned_bleeds>2)*6
  if not SkipRupture and S.Rupture:IsReadyP() then
    local function Evaluate_Rupture_Target(TargetUnit)
      return TargetUnit:DebuffRefreshableP(S.Rupture, RuptureThreshold)
        and (TargetUnit:PMultiplier(S.Rupture) <= 1 or TargetUnit:DebuffRemainsP(S.Rupture)
          <= (HL.Exsanguinated(TargetUnit, S.Rupture) and ExsanguinatedBleedTickTime or BleedTickTime) and EmpoweredDotRefresh)
        and (not HL.Exsanguinated(TargetUnit, S.Rupture) or TargetUnit:DebuffRemainsP(S.Rupture) <= ExsanguinatedBleedTickTime*2 and EmpoweredDotRefresh)
        and Rogue.CanDoTUnit(TargetUnit, RuptureDMGThreshold);
    end
    if Target:IsInRange("Melee") and (ComboPoints >= 4 and Target:DebuffRefreshableP(S.Rupture, RuptureThreshold)
      or (not Target:DebuffP(S.Rupture) and (HL.CombatTime() > 10 or (ComboPoints >= 2)))) and Evaluate_Rupture_Target(Target)
      and (Target:FilteredTimeToDie(">", 4, -Target:DebuffRemainsP(S.Rupture)) or Target:TimeToDieIsNotValid()) then
      if HR.Cast(S.Rupture) then return "Cast Rupture (Refresh)"; end
    end
    if HR.AoEON() and not SkipCycleRupture and ComboPoints >= 4 then
      SuggestCycleDoT(S.Rupture, Evaluate_Rupture_Target, RuptureDurationThreshold);
    end
  end
  if S.CrimsonTempest:IsReadyP() then
    -- actions.dot+=/crimson_tempest,target_if=min:remains,if=spell_targets>1&remains<2+(spell_targets>=5)&combo_points>=4
    -- Add the <4 check because this line evaluation is mutually exclusive to the one above at spell_targets>3
    if HR.AoEON() and ComboPoints >= 4 and Cache.EnemiesCount[10] > 1 and Cache.EnemiesCount[10] < 4 then
      for _, CycleUnit in pairs(Cache.Enemies[10]) do
        -- Note: The APL does not do this due to target_if mechanics, just to determine if any targets are low on duration of the AoE Bleed
        if CycleUnit:DebuffRemainsP(S.CrimsonTempest) < 2 + num(Cache.EnemiesCount[10] >= 5) then
          if HR.Cast(S.CrimsonTempest) then return "Cast Crimson Tempest (AoE 2-3)"; end
        end
      end
    end
    -- actions.dot+=/crimson_tempest,if=spell_targets=1&combo_points>=(cp_max_spend-1)&refreshable&!exsanguinated&!debuff.toxic_blade.up&master_assassin_remains=0&!azerite.twist_the_knife.enabled&target.time_to_die-remains>4
    if Target:IsInRange("Melee") and Cache.EnemiesCount[10] == 1 and ComboPoints >= (Rogue.CPMaxSpend() - 1) and Target:DebuffRefreshableP(S.CrimsonTempest, CrimsonTempestThreshold)
      and not HL.Exsanguinated(Target, S.CrimsonTempest) and not Target:DebuffP(S.ToxicBladeDebuff) and MasterAssassinRemains() <= 0 and not S.TwistTheKnife:AzeriteEnabled()
      and (Target:FilteredTimeToDie(">", 4, -Target:DebuffRemainsP(S.CrimsonTempest)) or Target:TimeToDieIsNotValid())
      and Rogue.CanDoTUnit(Target, RuptureDMGThreshold) then
      if HR.Cast(S.CrimsonTempest) then return "Cast Crimson Tempest (ST)"; end
    end
    -- actions.dot+=/crimson_tempest,if=spell_targets>(7-buff.envenom.up)&combo_points>=4+talent.deeper_stratagem.enabled&!debuff.vendetta.up&!debuff.toxic_blade.up&energy.deficit<=25+variable.energy_regen_combined&(!talent.exsanguinate.enabled|cooldown.exsanguinate.remains>2)
    if HR.AoEON() and ComboPoints >= 4 + num(S.DeeperStratagem:IsAvailable()) and Cache.EnemiesCount[10] > 7 - num(Player:BuffP(S.Envenom))
      and not Target:DebuffP(S.Vendetta) and not Target:DebuffP(S.ToxicBladeDebuff) and Player:EnergyDeficitPredicted() <= 25 + Energy_Regen_Combined
      and (not S.Exsanguinate:IsAvailable() or S.Exsanguinate:CooldownRemainsP() > 2 or not HR.CDsON()) then
      if HR.Cast(S.CrimsonTempest) then return "Cast Crimson Tempest (Replace Envenom)"; end
    end
  end

  return false;
end

-- # Direct damage abilities
local function Direct ()
  -- actions.direct=envenom,if=combo_points>=4+talent.deeper_stratagem.enabled&(debuff.vendetta.up|debuff.toxic_blade.up|energy.deficit<=25+variable.energy_regen_combined|spell_targets.fan_of_knives>=2)&(!talent.exsanguinate.enabled|cooldown.exsanguinate.remains>2|target.time_to_die<4)
  if S.Envenom:IsReadyP("Melee") and ComboPoints >= 4 + (S.DeeperStratagem:IsAvailable() and 1 or 0)
    and (Target:DebuffP(S.Vendetta) or Target:DebuffP(S.ToxicBladeDebuff) or Player:EnergyDeficitPredicted() <= 25 + Energy_Regen_Combined
      or Cache.EnemiesCount[10] >= 2 or Settings.Assassination.NoPooling) and (not S.Exsanguinate:IsAvailable() or S.Exsanguinate:CooldownRemainsP() > 2
        or not HR.CDsON() or Target:FilteredTimeToDie("<", 4) or not Rogue.CanDoTUnit(Target, RuptureDMGThreshold)) then
    if HR.Cast(S.Envenom) then return "Cast Envenom"; end
  end

  -------------------------------------------------------------------
  -------------------------------------------------------------------
  -- actions.direct+=/variable,name=use_filler,value=combo_points.deficit>1|energy.deficit<=25+variable.energy_regen_combined|spell_targets.fan_of_knives>=2
  -- This is used in all following fillers, so we just return false if not true and won't consider these.
  if not (ComboPointsDeficit > 1 or Player:EnergyDeficitPredicted() <= 25 + Energy_Regen_Combined or Cache.EnemiesCount[10] >= 2) then
    return false;
  end
  -------------------------------------------------------------------
  -------------------------------------------------------------------

  if S.FanofKnives:IsCastable(10, true) then
    -- actions.direct+=/fan_of_knives,if=variable.use_filler&azerite.echoing_blades.enabled&spell_targets.fan_of_knives>=2+(debuff.vendetta.up*(1+(azerite.echoing_blades.rank=1)))
    if S.EchoingBlades:AzeriteEnabled() and Cache.EnemiesCount[10] >= 2 + (num(Target:DebuffP(S.Vendetta)) * (1 + num(S.EchoingBlades:AzeriteRank() == 1))) then
      if HR.Cast(S.FanofKnives) then return "Cast Fan of Knives (Echoing Blades)"; end
    end
    -- actions.direct+=/fan_of_knives,if=variable.use_filler&(buff.hidden_blades.stack>=19|(!priority_rotation&spell_targets.fan_of_knives>=4+(azerite.double_dose.rank>2)+stealthed.rogue))
    if HR.AoEON() and (Player:BuffStack(S.HiddenBladesBuff) >= 19 or Player:BuffStack(S.TheDreadlordsDeceit) >= 29
      or not PriorityRotation and Cache.EnemiesCount[10] >= 4 + num(Player:IsStealthedP(true, false)) + num(S.DoubleDose:AzeriteRank() > 2)) then
      if HR.Cast(S.FanofKnives) then return "Cast Fan of Knives"; end
    end
    -- actions.direct+=/fan_of_knives,target_if=!dot.deadly_poison_dot.ticking,if=variable.use_filler&spell_targets.fan_of_knives>=3
    if HR.AoEON() and Player:BuffP(S.DeadlyPoison) and Cache.EnemiesCount[10] >= 3 then
      for _, CycleUnit in pairs(Cache.Enemies[10]) do
        -- Note: The APL does not do this due to target_if mechanics, but since we are cycling we should check to see if the unit has a bleed
        if (CycleUnit:DebuffP(S.Garrote) or CycleUnit:DebuffP(S.Rupture)) and not CycleUnit:DebuffP(S.DeadlyPoisonDebuff) then
          if HR.CastPooling(S.FanofKnives) then return "Cast Fan of Knives (DP Refresh)"; end
        end
      end
    end
  end
  -- actions.direct+=/blindside,if=variable.use_filler&(buff.blindside.up|!talent.venom_rush.enabled&!azerite.double_dose.enabled)
  if S.Blindside:IsCastable("Melee") and (Player:BuffP(S.BlindsideBuff) or (not S.VenomRush:IsAvailable() and not S.DoubleDose:AzeriteEnabled() and Target:HealthPercentage() < 30)) then
    if HR.CastPooling(S.Blindside) then return "Cast Blindside"; end
  end
  -- actions.direct+=/mutilate,target_if=!dot.deadly_poison_dot.ticking,if=variable.use_filler&spell_targets.fan_of_knives=2
  if S.Mutilate:IsCastable("Melee") and Cache.EnemiesCount[10] == 2 then
    local TargetGUID = Target:GUID();
    for _, CycleUnit in pairs(Cache.Enemies["Melee"]) do
      -- Note: The APL does not do this due to target_if mechanics, but since we are cycling we should check to see if the unit has a bleed
      if CycleUnit:GUID() ~= TargetGUID and (CycleUnit:DebuffP(S.Garrote) or CycleUnit:DebuffP(S.Rupture)) and not CycleUnit:DebuffP(S.DeadlyPoisonDebuff) then
        HR.CastLeftNameplate(CycleUnit, S.Mutilate);
        break;
      end
    end
  end
  -- actions.direct+=/mutilate,if=variable.use_filler
  if S.Mutilate:IsCastable("Melee") then
    if HR.CastPooling(S.Mutilate) then return "Cast Mutilate"; end
  end

  return false;
end

-- APL Main
local function APL ()
  -- Spell ID Changes check
  Stealth = S.Subterfuge:IsAvailable() and S.Stealth2 or S.Stealth; -- w/ or w/o Subterfuge Talent

  -- Unit Update
  HL.GetEnemies(50); -- Used for Rogue.PoisonedBleeds()
  HL.GetEnemies(30); -- Used for Poisoned Knife Poison refresh
  HL.GetEnemies(10, true); -- Fan of Knives
  HL.GetEnemies("Melee"); -- Melee
  Everyone.AoEToggleEnemiesUpdate();

  -- Compute Cache
  ComboPoints = Player:ComboPoints();
  ComboPointsDeficit = Player:ComboPointsMax() - ComboPoints;
  RuptureThreshold = (4 + ComboPoints * 4) * 0.3;
  CrimsonTempestThreshold = (2 + ComboPoints * 2) * 0.3;
  RuptureDMGThreshold = S.Envenom:Damage()*Settings.Assassination.EnvenomDMGOffset; -- Used to check if Rupture is worth to be casted since it's a finisher.
  GarroteDMGThreshold = S.Mutilate:Damage()*Settings.Assassination.MutilateDMGOffset; -- Used as TTD Not Valid fallback since it's a generator.
  PriorityRotation = UsePriorityRotation();

  -- Defensives
  -- Crimson Vial
  ShouldReturn = Rogue.CrimsonVial(S.CrimsonVial);
  if ShouldReturn then return ShouldReturn; end
  -- Feint
  ShouldReturn = Rogue.Feint(S.Feint);
  if ShouldReturn then return ShouldReturn; end

  -- Poisons
  local PoisonRefreshTime = Player:AffectingCombat() and Settings.Assassination.PoisonRefreshCombat*60 or Settings.Assassination.PoisonRefresh*60;
  -- Lethal Poison
  if Player:BuffRemainsP(S.DeadlyPoison) <= PoisonRefreshTime
    and Player:BuffRemainsP(S.WoundPoison) <= PoisonRefreshTime then
    HR.CastSuggested(S.DeadlyPoison);
  end
  -- Non-Lethal Poison
  if Player:BuffRemainsP(S.CripplingPoison) <= PoisonRefreshTime then
    HR.CastSuggested(S.CripplingPoison);
  end

  -- Out of Combat
  if not Player:AffectingCombat() then
    -- Stealth
    if not Player:Buff(S.VanishBuff) then
      ShouldReturn = Rogue.Stealth(Stealth);
      if ShouldReturn then return ShouldReturn; end
    end
    -- Flask
    -- Food
    -- Rune
    -- PrePot w/ Bossmod Countdown
    -- Opener
    if Everyone.TargetIsValid() then
      -- Precombat CDs
      if HR.CDsON() then
        if S.MarkedforDeath:IsCastableP() and Player:ComboPointsDeficit() >= Rogue.CPMaxSpend() and Everyone.TargetIsValid() then
          if HR.Cast(S.MarkedforDeath, Settings.Commons.OffGCDasOffGCD.MarkedforDeath) then return "Cast Marked for Death (OOC)"; end
        end
        -- actions.precombat+=/use_item,name=azsharas_font_of_power
        if Settings.Commons.UseTrinkets and I.FontOfPower:IsEquipped() and I.FontOfPower:IsReady() then
          if HR.Cast(I.FontOfPower, nil, Settings.Commons.TrinketDisplayStyle) then return "Use Font of Power (OOC)"; end
        end
        -- actions.precombat+=/guardian_of_azeroth,if=talent.exsanguinate.enabled
        if S.GuardianofAzeroth:IsCastableP() and S.Exsanguinate:IsAvailable() then
          if HR.Cast(S.GuardianofAzeroth, nil, Settings.Commons.EssenceDisplayStyle) then return "Cast GuardianofAzeroth (OOC)"; end
        end
      end
    end
  end

  -- In Combat
  -- MfD Sniping
  Rogue.MfDSniping(S.MarkedforDeath);
  if Everyone.TargetIsValid() then
    -- Mythic Dungeon
    ShouldReturn = MythicDungeon();
    if ShouldReturn then return ShouldReturn; end
    -- Training Scenario
    ShouldReturn = TrainingScenario();
    if ShouldReturn then return ShouldReturn; end

    -- Interrupts
    Everyone.Interrupt(5, S.Kick, Settings.Commons.OffGCDasOffGCD.Kick, Interrupts);

    -- actions=variable,name=energy_regen_combined,value=energy.regen+poisoned_bleeds*7%(2*spell_haste)
    PoisonedBleeds = Rogue.PoisonedBleeds()
    Energy_Regen_Combined = Player:EnergyRegen() + PoisonedBleeds * 7 / (2 * Player:SpellHaste());
    RuptureDurationThreshold = 4 + num(PoisonedBleeds > 2) * 6

    -- actions+=/call_action_list,name=stealthed,if=stealthed.rogue
    if Player:IsStealthedP(true, false) then
      ShouldReturn = Stealthed();
      if ShouldReturn then return ShouldReturn .. " (Stealthed)"; end
    end
    -- actions+=/call_action_list,name=cds,if=(!talent.master_assassin.enabled|dot.garrote.ticking)
    if not S.MasterAssassin:IsAvailable() or Target:DebuffP(S.Garrote) then
      ShouldReturn = CDs();
      if ShouldReturn then return ShouldReturn; end
    end
    -- actions+=/call_action_list,name=dot
    ShouldReturn = Dot();
    if ShouldReturn then return ShouldReturn; end
    -- actions+=/call_action_list,name=direct
    ShouldReturn = Direct();
    if ShouldReturn then return ShouldReturn; end
    -- Racials
    if HR.CDsON() then
      -- actions+=/arcane_torrent,if=energy.deficit>=15+variable.energy_regen_combined
      if S.ArcaneTorrent:IsCastableP("Melee") and Player:EnergyDeficitPredicted() > 15 + Energy_Regen_Combined then
        if HR.Cast(S.ArcaneTorrent, Settings.Commons.GCDasOffGCD.Racials) then return "Cast Arcane Torrent"; end
      end
      -- actions+=/arcane_pulse
      if S.ArcanePulse:IsCastableP("Melee") then
        if HR.Cast(S.ArcanePulse, Settings.Commons.GCDasOffGCD.Racials) then return "Cast Arcane Pulse"; end
      end
      -- actions+=/lights_judgment
      if S.LightsJudgment:IsCastableP("Melee") then
        if HR.Cast(S.LightsJudgment, Settings.Commons.GCDasOffGCD.Racials) then return "Cast Lights Judgment"; end
      end
      -- actions+=/bag_of_tricks
      if S.BagofTricks:IsCastableP("Melee") then
        if HR.Cast(S.BagofTricks, Settings.Commons.GCDasOffGCD.Racials) then return "Cast Bag of Tricks"; end
      end
    end
    -- Poisoned Knife Out of Range [EnergyCap] or [PoisonRefresh]
    if S.PoisonedKnife:IsCastable(30) and not Player:IsStealthedP(true, true)
      and ((not Target:IsInRange(10) and Player:EnergyTimeToMax() <= Player:GCD()*1.2)
        or (not Target:IsInRange("Melee") and Target:DebuffRefreshableP(S.DeadlyPoisonDebuff, 4))) then
      if HR.Cast(S.PoisonedKnife) then return "Cast Poisoned Knife"; end
    end
    -- Trick to take in consideration the Recovery Setting
    if S.Mutilate:IsCastable("Melee") then
      if HR.Cast(S.PoolEnergy) then return "Normal Pooling"; end
    end
  end
end

local function Init ()
  S.RazorCoralDebuff:RegisterAuraTracking();
end

HR.SetAPL(259, APL, Init);

-- Last Update: 2020-06-10

-- # Executed before combat begins. Accepts non-harmful actions only.
-- actions.precombat=flask
-- actions.precombat+=/augmentation
-- actions.precombat+=/food
-- # Snapshot raid buffed stats before combat begins and pre-potting is done.
-- actions.precombat+=/snapshot_stats
-- actions.precombat+=/potion
-- actions.precombat+=/marked_for_death,precombat_seconds=5,if=raid_event.adds.in>15
-- actions.precombat+=/apply_poison
-- actions.precombat+=/stealth
-- actions.precombat+=/use_item,name=azsharas_font_of_power
-- actions.precombat+=/guardian_of_azeroth,if=talent.exsanguinate.enabled

-- # Executed every time the actor is available.
-- # Restealth if possible (no vulnerable enemies in combat)
-- actions=stealth
-- actions+=/variable,name=energy_regen_combined,value=energy.regen+poisoned_bleeds*7%(2*spell_haste)
-- actions+=/variable,name=single_target,value=spell_targets.fan_of_knives<2
-- actions+=/call_action_list,name=stealthed,if=stealthed.rogue
-- actions+=/call_action_list,name=cds,if=(!talent.master_assassin.enabled|dot.garrote.ticking)
-- actions+=/call_action_list,name=dot
-- actions+=/call_action_list,name=direct
-- actions+=/arcane_torrent,if=energy.deficit>=15+variable.energy_regen_combined
-- actions+=/arcane_pulse
-- actions+=/lights_judgment
-- actions+=/bag_of_tricks

-- # Cooldowns
-- actions.cds=use_item,name=azsharas_font_of_power,if=!stealthed.all&master_assassin_remains=0&(cooldown.vendetta.remains<?(cooldown.toxic_blade.remains*equipped.ashvanes_razor_coral))<10+10*equipped.ashvanes_razor_coral&!debuff.vendetta.up&!debuff.toxic_blade.up
-- actions.cds+=/call_action_list,name=essences,if=!stealthed.all&dot.rupture.ticking&master_assassin_remains=0
-- # If adds are up, snipe the one with lowest TTD. Use when dying faster than CP deficit or without any CP.
-- actions.cds+=/marked_for_death,target_if=min:target.time_to_die,if=raid_event.adds.up&(target.time_to_die<combo_points.deficit*1.5|combo_points.deficit>=cp_max_spend)
-- # If no adds will die within the next 30s, use MfD on boss without any CP.
-- actions.cds+=/marked_for_death,if=raid_event.adds.in>30-raid_event.adds.duration&combo_points.deficit>=cp_max_spend
-- # Vendetta logical conditionals based on current spec
-- actions.cds+=/variable,name=vendetta_subterfuge_condition,value=!talent.subterfuge.enabled|!azerite.shrouded_suffocation.enabled|dot.garrote.pmultiplier>1&(spell_targets.fan_of_knives<6|!cooldown.vanish.up)
-- actions.cds+=/variable,name=vendetta_nightstalker_condition,value=!talent.nightstalker.enabled|!talent.exsanguinate.enabled|cooldown.exsanguinate.remains<5-2*talent.deeper_stratagem.enabled
-- actions.cds+=/variable,name=variable,name=vendetta_font_condition,value=!equipped.azsharas_font_of_power|azerite.shrouded_suffocation.enabled|debuff.razor_coral_debuff.down|trinket.ashvanes_razor_coral.cooldown.remains<10&(cooldown.toxic_blade.remains<1|debuff.toxic_blade.up)
-- actions.cds+=/vendetta,if=!stealthed.rogue&dot.rupture.ticking&!debuff.vendetta.up&variable.vendetta_subterfuge_condition&variable.vendetta_nightstalker_condition&variable.vendetta_font_condition
-- # Vanish with Exsg + Nightstalker: Maximum CP and Exsg ready for next GCD
-- actions.cds+=/vanish,if=talent.exsanguinate.enabled&talent.nightstalker.enabled&combo_points>=cp_max_spend&cooldown.exsanguinate.remains<1
-- # Vanish with Nightstalker + No Exsg: Maximum CP and Vendetta up (unless using VoP)
-- actions.cds+=/vanish,if=talent.nightstalker.enabled&!talent.exsanguinate.enabled&combo_points>=cp_max_spend&(debuff.vendetta.up|essence.vision_of_perfection.enabled)
-- # See full comment on https://github.com/Ravenholdt-TC/Rogue/wiki/Assassination-APL-Research.
-- actions.cds+=/variable,name=ss_vanish_condition,value=azerite.shrouded_suffocation.enabled&(non_ss_buffed_targets>=1|spell_targets.fan_of_knives=3)&(ss_buffed_targets_above_pandemic=0|spell_targets.fan_of_knives>=6)
-- actions.cds+=/pool_resource,for_next=1,extra_amount=45
-- actions.cds+=/vanish,if=talent.subterfuge.enabled&!stealthed.rogue&cooldown.garrote.up&(variable.ss_vanish_condition|!azerite.shrouded_suffocation.enabled&(dot.garrote.refreshable|debuff.vendetta.up&dot.garrote.pmultiplier<=1))&combo_points.deficit>=((1+2*azerite.shrouded_suffocation.enabled)*spell_targets.fan_of_knives)>?4&raid_event.adds.in>12
-- # Vanish with Master Assasin: No stealth and no active MA buff, Rupture not in refresh range, during Vendetta+TB+BotE (unless using VoP)
-- actions.cds+=/vanish,if=talent.master_assassin.enabled&!stealthed.all&master_assassin_remains<=0&!dot.rupture.refreshable&dot.garrote.remains>3&(debuff.vendetta.up&(!talent.toxic_blade.enabled|debuff.toxic_blade.up)&(!essence.blood_of_the_enemy.major|debuff.blood_of_the_enemy.up)|essence.vision_of_perfection.enabled)
-- # Shadowmeld for Shrouded Suffocation
-- actions.cds+=/shadowmeld,if=!stealthed.all&azerite.shrouded_suffocation.enabled&dot.garrote.refreshable&dot.garrote.pmultiplier<=1&combo_points.deficit>=1
-- # Exsanguinate when not stealthed and both Rupture and Garrote are up for long enough.
-- actions.cds+=/exsanguinate,if=!stealthed.rogue&(!dot.garrote.refreshable&dot.rupture.remains>4+4*cp_max_spend|dot.rupture.remains*0.5>target.time_to_die)&target.time_to_die>4
-- actions.cds+=/toxic_blade,if=dot.rupture.ticking&(!equipped.azsharas_font_of_power|cooldown.vendetta.remains>10)
-- actions.cds+=/potion,if=buff.bloodlust.react|debuff.vendetta.up
-- actions.cds+=/blood_fury,if=debuff.vendetta.up
-- actions.cds+=/berserking,if=debuff.vendetta.up
-- actions.cds+=/fireblood,if=debuff.vendetta.up
-- actions.cds+=/ancestral_call,if=debuff.vendetta.up
-- actions.cds+=/use_item,name=galecallers_boon,if=(debuff.vendetta.up|(!talent.exsanguinate.enabled&cooldown.vendetta.remains>45|talent.exsanguinate.enabled&(cooldown.exsanguinate.remains<6|cooldown.exsanguinate.remains>20&fight_remains>65)))&!exsanguinated.rupture
-- actions.cds+=/use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.down|fight_remains<20
-- actions.cds+=/use_item,name=ashvanes_razor_coral,if=(!talent.exsanguinate.enabled|!talent.subterfuge.enabled)&debuff.vendetta.remains>10-4*equipped.azsharas_font_of_power
-- actions.cds+=/use_item,name=ashvanes_razor_coral,if=(talent.exsanguinate.enabled&talent.subterfuge.enabled)&debuff.vendetta.up&(exsanguinated.garrote|azerite.shrouded_suffocation.enabled&dot.garrote.pmultiplier>1)
-- actions.cds+=/use_item,effect_name=cyclotronic_blast,if=master_assassin_remains=0&!debuff.vendetta.up&!debuff.toxic_blade.up&buff.memory_of_lucid_dreams.down&energy<80&dot.rupture.remains>4
-- actions.cds+=/use_item,name=lurkers_insidious_gift,if=debuff.vendetta.up
-- actions.cds+=/use_item,name=lustrous_golden_plumage,if=debuff.vendetta.up
-- actions.cds+=/use_item,effect_name=gladiators_medallion,if=debuff.vendetta.up
-- actions.cds+=/use_item,effect_name=gladiators_badge,if=debuff.vendetta.up
-- # Default fallback for usable items: Use on cooldown.
-- actions.cds+=/use_items

-- # Direct damage abilities
-- # Envenom at 4+ (5+ with DS) CP. Immediately on 2+ targets, with Vendetta, or with TB; otherwise wait for some energy. Also wait if Exsg combo is coming up.
-- actions.direct=envenom,if=combo_points>=4+talent.deeper_stratagem.enabled&(debuff.vendetta.up|debuff.toxic_blade.up|energy.deficit<=25+variable.energy_regen_combined|!variable.single_target)&(!talent.exsanguinate.enabled|cooldown.exsanguinate.remains>2|target.time_to_die<4)
-- actions.direct+=/variable,name=use_filler,value=combo_points.deficit>1|energy.deficit<=25+variable.energy_regen_combined|!variable.single_target
-- # With Echoing Blades, Fan of Knives at 2+ targets, or 3-4+ targets when Vendetta is up
-- actions.direct+=/fan_of_knives,if=variable.use_filler&azerite.echoing_blades.enabled&spell_targets.fan_of_knives>=2+(debuff.vendetta.up*(1+(azerite.echoing_blades.rank=1)))
-- # Fan of Knives at 19+ stacks of Hidden Blades or against 4+ (5+ with Double Dose) targets.
-- actions.direct+=/fan_of_knives,if=variable.use_filler&(buff.hidden_blades.stack>=19|(!priority_rotation&spell_targets.fan_of_knives>=4+(azerite.double_dose.rank>2)+stealthed.rogue))
-- # Fan of Knives to apply Deadly Poison if inactive on any target at 3 targets.
-- actions.direct+=/fan_of_knives,target_if=!dot.deadly_poison_dot.ticking,if=variable.use_filler&spell_targets.fan_of_knives>=3
-- actions.direct+=/blindside,if=variable.use_filler&(buff.blindside.up|!talent.venom_rush.enabled&!azerite.double_dose.enabled)
-- # Tab-Mutilate to apply Deadly Poison at 2 targets
-- actions.direct+=/mutilate,target_if=!dot.deadly_poison_dot.ticking,if=variable.use_filler&spell_targets.fan_of_knives=2
-- actions.direct+=/mutilate,if=variable.use_filler

-- # Damage over time abilities
-- # Limit Garrotes on non-primrary targets for the priority rotation if 5+ bleeds are already up
-- actions.dot=variable,name=skip_cycle_garrote,value=priority_rotation&spell_targets.fan_of_knives>3&(dot.garrote.remains<cooldown.garrote.duration|poisoned_bleeds>5)
-- # Limit Ruptures on non-primrary targets for the priority rotation if 5+ bleeds are already up
-- actions.dot+=/variable,name=skip_cycle_rupture,value=priority_rotation&spell_targets.fan_of_knives>3&(debuff.toxic_blade.up|(poisoned_bleeds>5&!azerite.scent_of_blood.enabled))
-- # Limit Ruptures if Vendetta+Toxic Blade/Master Assassin is up and we have 2+ seconds left on the Rupture DoT
-- actions.dot+=/variable,name=skip_rupture,value=debuff.vendetta.up&(debuff.toxic_blade.up|master_assassin_remains>0)&dot.rupture.remains>2
-- # Special Garrote and Rupture setup prior to Exsanguinate cast
-- actions.dot+=/garrote,if=talent.exsanguinate.enabled&!exsanguinated.garrote&dot.garrote.pmultiplier<=1&cooldown.exsanguinate.remains<2&spell_targets.fan_of_knives=1&raid_event.adds.in>6&dot.garrote.remains*0.5<target.time_to_die
-- actions.dot+=/rupture,if=talent.exsanguinate.enabled&!dot.garrote.refreshable&(combo_points>=cp_max_spend&cooldown.exsanguinate.remains<1&dot.rupture.remains*0.5<target.time_to_die)
-- # Garrote upkeep, also tries to use it as a special generator for the last CP before a finisher
-- actions.dot+=/pool_resource,for_next=1
-- actions.dot+=/garrote,if=refreshable&combo_points.deficit>=1+3*(azerite.shrouded_suffocation.enabled&cooldown.vanish.up)&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&(!exsanguinated|remains<=tick_time*2&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&!ss_buffed&(target.time_to_die-remains)>4&(master_assassin_remains=0|!ticking&azerite.shrouded_suffocation.enabled)
-- actions.dot+=/pool_resource,for_next=1
-- actions.dot+=/garrote,cycle_targets=1,if=!variable.skip_cycle_garrote&target!=self.target&refreshable&combo_points.deficit>=1+3*(azerite.shrouded_suffocation.enabled&cooldown.vanish.up)&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&(!exsanguinated|remains<=tick_time*2&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&!ss_buffed&(target.time_to_die-remains)>12&(master_assassin_remains=0|!ticking&azerite.shrouded_suffocation.enabled)
-- # Crimson Tempest on multiple targets at 4+ CP when running out in 2s (up to 4 targets) or 3s (5+ targets)
-- actions.dot+=/crimson_tempest,if=spell_targets>=2&remains<2+(spell_targets>=5)&combo_points>=4
-- # Keep up Rupture at 4+ on all targets (when living long enough and not snapshot)
-- actions.dot+=/rupture,if=!variable.skip_rupture&(combo_points>=4&refreshable|!ticking&(time>10|combo_points>=2))&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&(!exsanguinated|remains<=tick_time*2&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&target.time_to_die-remains>4
-- actions.dot+=/rupture,cycle_targets=1,if=!variable.skip_cycle_rupture&!variable.skip_rupture&target!=self.target&combo_points>=4&refreshable&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&(!exsanguinated|remains<=tick_time*2&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&target.time_to_die-remains>4
-- # Crimson Tempest on ST if in pandemic and it will do less damage than Envenom due to TB/MA/TtK
-- actions.dot+=/crimson_tempest,if=spell_targets=1&combo_points>=(cp_max_spend-1)&refreshable&!exsanguinated&!debuff.toxic_blade.up&master_assassin_remains=0&!azerite.twist_the_knife.enabled&target.time_to_die-remains>4

-- # Essences
-- actions.essences=concentrated_flame,if=energy.time_to_max>1&!debuff.vendetta.up&(!dot.concentrated_flame_burn.ticking&!action.concentrated_flame.in_flight|full_recharge_time<gcd.max)
-- # Always use Blood with Vendetta up. Hold for Exsanguinate. Use with TB up before a finisher as long as it runs for 10s during Vendetta.
-- actions.essences+=/blood_of_the_enemy,if=debuff.vendetta.up&(exsanguinated.garrote|debuff.toxic_blade.up&combo_points.deficit<=1|debuff.vendetta.remains<=10)|fight_remains<=10
-- # Attempt to align Guardian with Vendetta as long as it won't result in losing a full-value cast over the remaining duration of the fight
-- actions.essences+=/guardian_of_azeroth,if=cooldown.vendetta.remains<3|debuff.vendetta.up|fight_remains<30
-- actions.essences+=/guardian_of_azeroth,if=floor((fight_remains-30)%cooldown)>floor((fight_remains-30-cooldown.vendetta.remains)%cooldown)
-- actions.essences+=/focused_azerite_beam,if=spell_targets.fan_of_knives>=2|raid_event.adds.in>60&energy<70|fight_remains<10
-- actions.essences+=/purifying_blast,if=spell_targets.fan_of_knives>=2|raid_event.adds.in>60|fight_remains<10
-- actions.essences+=/the_unbound_force,if=buff.reckless_force.up|buff.reckless_force_counter.stack<10
-- actions.essences+=/ripple_in_space
-- actions.essences+=/worldvein_resonance
-- actions.essences+=/memory_of_lucid_dreams,if=energy<50&!cooldown.vendetta.up
-- # Hold Reaping Flames for execute range or kill buffs, if possible. Always try to get the lowest cooldown based on available enemies.
-- actions.essences+=/cycling_variable,name=reaping_delay,op=min,if=essence.breath_of_the_dying.major,value=target.time_to_die
-- actions.essences+=/reaping_flames,target_if=target.time_to_die<1.5|((target.health.pct>80|target.health.pct<=20)&(active_enemies=1|variable.reaping_delay>29))|(target.time_to_pct_20>30&(active_enemies=1|variable.reaping_delay>44))

-- # Stealthed Actions
-- # Nighstalker on 1T: Snapshot Rupture
-- actions.stealthed=rupture,if=talent.nightstalker.enabled&combo_points>=4&target.time_to_die-remains>6
-- # Subterfuge + Shrouded Suffocation: Ensure we use one global to apply Garrote to the main target if it is not snapshot yet, so all other main target abilities profit.
-- actions.stealthed+=/pool_resource,for_next=1
-- actions.stealthed+=/garrote,if=azerite.shrouded_suffocation.enabled&buff.subterfuge.up&buff.subterfuge.remains<1.3&!ss_buffed
-- # Subterfuge: Apply or Refresh with buffed Garrotes
-- actions.stealthed+=/pool_resource,for_next=1
-- actions.stealthed+=/garrote,target_if=min:remains,if=talent.subterfuge.enabled&(remains<12|pmultiplier<=1)&target.time_to_die-remains>2
-- # Subterfuge + Shrouded Suffocation in ST: Apply early Rupture that will be refreshed for pandemic
-- actions.stealthed+=/rupture,if=talent.subterfuge.enabled&azerite.shrouded_suffocation.enabled&!dot.rupture.ticking&variable.single_target
-- # Subterfuge w/ Shrouded Suffocation: Reapply for bonus CP and/or extended snapshot duration.
-- actions.stealthed+=/pool_resource,for_next=1
-- actions.stealthed+=/garrote,target_if=min:remains,if=talent.subterfuge.enabled&azerite.shrouded_suffocation.enabled&(active_enemies>1|!talent.exsanguinate.enabled)&target.time_to_die>remains&(remains<18|!ss_buffed)
-- # Subterfuge + Exsg on 1T: Refresh Garrote at the end of stealth to get max duration before Exsanguinate
-- actions.stealthed+=/pool_resource,for_next=1
-- actions.stealthed+=/garrote,if=talent.subterfuge.enabled&talent.exsanguinate.enabled&active_enemies=1&buff.subterfuge.remains<1.3

