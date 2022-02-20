//==============================================================================
/* aiCore.xs

   This file includes all other files in the core folder, and will be included
   by aiMain.xs.

   This file also contains functions and rules that don't belong to other files.

*/
//==============================================================================

//==============================================================================
// Function forward declarations.
//==============================================================================
// Used in loader file to override default values, called at start of main()
mutable void preInit(void) {}

// Used in loader file to override initialization decisions, called at end of main()
mutable void postInit(void) {}

// Utilities.
mutable vector getStartingLocation(void) { return (kbGetPlayerStartingPosition(cMyID)); }

// Buildings.
mutable void selectTowerBuildPlanPosition(int buildPlan = -1, int baseID = -1) {}
mutable void selectShrineBuildPlanPosition(int planID = -1, int baseID = -1) {}
mutable void selectTorpBuildPlanPosition(int planID = -1, int baseID = -1) {}
mutable void selectTCBuildPlanPosition(int buildPlan = -1, int baseID = -1) {}
mutable bool selectTribalMarketplaceBuildPlanPosition(int buildPlan = -1, int baseID = -1) { return (false); }
mutable bool selectFieldBuildPlanPosition(int planID = -1, int baseID = -1) { return (false); }
mutable void selectMountainMonasteryBuildPlanPosition(int planID = -1, int baseID = -1) {}
mutable void selectGranaryBuildPlanPosition(int planID = -1, int baseID = -1) {}
mutable void selectClosestBuildPlanPosition(int planID = -1, int baseID = -1) {}
mutable bool selectBuildPlanPosition(int planID = -1, int puid = -1, int baseID = -1) { return (false); }
mutable bool addBuilderToPlan(int planID = -1, int puid = -1, int numberBuilders = 1) { return (false); }

// Economy.
mutable void econMaster(int mode = -1, int value = -1) {}

// Military.
mutable int initUnitPicker(
    string name = "BUG", int numberTypes = 1, int minUnits = 10, int maxUnits = 20, int minPop = -1, int maxPop = -1,
    int numberBuildings = 1, bool guessEnemyUnitType = false)
{
   return (-1);
}
mutable void setUnitPickerCommon(int upID = -1) {}
mutable void setUnitPickerPreference(int upID = -1) {}
mutable void endDefenseReflex(void) {}
mutable void addUnitsToMilitaryPlan(int planID = -1) {}
mutable float getMilitaryUnitStrength(int puid = -1) { return (0.0); }

// Home City cards.
mutable void shipGrantedHandler(int parm = -1) {}

// Chats.
mutable void sendStatement(int playerIDorRelation = -1, int commPromptID = -1, vector vec = cInvalidVector) {}

// Setup.
mutable void deathMatchStartupBegin(void) {}
mutable void economyModeMatchStartupBegin(void) {}
mutable void initCeylonNomadStart(void) {}
mutable void init(void) {}

// Core.
mutable void updateSettlersAndPopManager() {}
mutable void transportShipmentArrive(int techID = -1) {}
mutable void revoltedHandler(int techID = -1) {}

//==============================================================================
// Includes.
//==============================================================================
include "core\aiGlobals.xs";
include "core\aiUtilities.xs";
include "core\aiBuildings.xs";
include "core\aiTechs.xs";
include "core\aiExploration.xs";
include "core\aiEconomy.xs";
include "core\aiMilitary.xs";
include "core\aiHCCards.xs";
include "core\aiChats.xs";
include "core\aiSetup.xs";

//==============================================================================
// updateSettlerCounts
// Set the Settler maintain plan using the gTargetSettlerCounts array.
//==============================================================================
void updateSettlerCounts(void)
{
   int age = kbGetAge();
   bool autoSpawningSettlers = ((cMyCiv == cCivOttomans) && (gRevolutionType == 0)) ||
                               (kbTechGetStatus(cTechDEHCFedGoldRush) == cTechStatusActive);
   int wantedSettlersThisAge = xsArrayGetInt(gTargetSettlerCounts, age);

   // If we're capped at the current age train our full complement of Settlers.
   // This is only here for if cvMaxAge is set to the Commerce Age basically.
   if (age == cvMaxAge)
   {
      wantedSettlersThisAge = xsArrayGetInt(gTargetSettlerCounts, cAge5);
   }

   if (autoSpawningSettlers == true)
   {
      debugCore("Economy" + kbGetProtoUnitName(gEconUnit) + "Maintain plan is set to 0 since we're automatically spawning");
      debugCore("We will stop spawning at " + wantedSettlersThisAge + " " + kbGetProtoUnitName(gEconUnit));
      // We need to null out the settler maintain plan for auto spawning civs.
      aiPlanSetVariableInt(gSettlerMaintainPlan, cTrainPlanNumberToMaintain, 0, 0);
   }
   else
   {
      debugCore(
          "Adjusting Economy" + kbGetProtoUnitName(gEconUnit) + "Maintain plan to: " + wantedSettlersThisAge + " " +
          kbGetProtoUnitName(gEconUnit));
      aiPlanSetVariableInt(gSettlerMaintainPlan, cTrainPlanNumberToMaintain, 0, wantedSettlersThisAge);
   }
   aiSetEconomyPop(wantedSettlersThisAge);

   if (kbUnitCount(cMyID, gEconUnit, cUnitStateAlive) >= (wantedSettlersThisAge * 0.8))
   {
      aiPlanSetDesiredResourcePriority(gSettlerMaintainPlan, 50);
   }
   else
   {
      aiPlanSetDesiredResourcePriority(gSettlerMaintainPlan, 70);
   }
}

//==============================================================================
// accountForOutlawsMilitaryPop
// Outlaws take a lot of pop space and this can be an issue.
// Let's say we have 40 military pop which normally gives us about 20 units.
// But if we made Outlaws that gives us about 10 units which is too few.
// So in this rule we increase our military population if we have Outlaws to account for this.
//==============================================================================
rule accountForOutlawsMilitaryPop
inactive
minInterval 30
{
   int militaryPopLimit = aiGetMilitaryPop();
   // We've reached maximum military pop so we can't increase it.
   if (gMaxPop - xsArrayGetInt(gTargetSettlerCounts, cAge5) == militaryPopLimit)
   {
      debugCore("DISABLING Rule: 'accountForOutlawsMilitaryPop' because we've maxed out on military population");
      xsDisableSelf();
      return;
   }

   int outlawQuery = createSimpleUnitQuery(cUnitTypeAbstractOutlaw, cMyID, cUnitStateAlive);
   int numberFound = kbUnitQueryExecute(outlawQuery);
   // Compensate for the additional pop Outlaws used.
   if (numberFound > 0)
   {
      int puid = -1;
      int unitID = -1;
      float totalAdditionalPop = 0.0;
      float additionalPop = 0.0;
      float buildBounty = 0.0;
      float puidPopCount = 0.0;

      for (i = 0; < numberFound)
      {
         unitID = kbUnitQueryGetResult(outlawQuery, i);
         puid = kbUnitGetProtoUnitID(unitID);
         buildBounty = kbProtoUnitGetBuildBounty(puid);
         puidPopCount = kbGetProtoUnitPopCount(puid);
         additionalPop = puidPopCount - (buildBounty / 10.0);
         if (additionalPop > 0.0) // Don't do anything if negative because we would just lower our max army pop for no reason.
         {
            totalAdditionalPop += additionalPop;
         }
      }
      int newMilitaryPopLimit = militaryPopLimit + totalAdditionalPop;
      if (((cvMaxArmyPop > -1) && (newMilitaryPopLimit > cvMaxArmyPop)) || (aiGetEconomyPop() + newMilitaryPopLimit > gMaxPop))
      {
         return;
      }

      aiSetMilitaryPop(newMilitaryPopLimit);
      debugCore(
          "Adjusting our military pop limit from " + militaryPopLimit + " to " + newMilitaryPopLimit + " because of the " +
          numberFound + " Outlaws found");
   }
   else
   {
      debugCore("No Outlaws found to take into account");
   }
}

//==============================================================================
// setMilPopLimit
// Calculates how many military population we want in the current age.
//==============================================================================
void setMilPopLimit(int age1 = 10, int age2 = 150, int age3 = 150, int age4 = 150, int age5 = 150)
{
   int age = kbGetAge();
   // We use treatyCheckStartMakingArmy to call setMilPopLimit when it's time to make army.
   // We start making army in treaty 10 minutes before the treaty ends.
   if (aiTreatyGetEnd() > xsGetTime() + 10 * 60 * 1000)
   {
      aiSetMilitaryPop(0);
      debugCore("Treaty is not yet 10 minutes away from being over so our military population is set to 0");
      return;
   }

   int militaryPopLimit = -1;
   if (age == cvMaxAge)
   {
      age = cAge5; // If we're at the highest allowed age, go for our full mil pop.
   }               // This is done so if we're capped at an age we can at least go full out.
   switch (age)
   {
   case cAge1:
   {
      militaryPopLimit = age1;
      break;
   }
   case cAge2:
   {
      militaryPopLimit = age2;
      break;
   }
   case cAge3:
   {
      militaryPopLimit = age3;
      break;
   }
   case cAge4:
   {
      militaryPopLimit = age4;
      break;
   }
   case cAge5:
   {
      militaryPopLimit = age5;
      break;
   }
   }

   if ((cvMaxArmyPop > -1) && (militaryPopLimit > cvMaxArmyPop))
   // Our calculated militaryPopLimit is higher than our cvMaxArmyPop which is not allowed to happen.
   {
      militaryPopLimit = cvMaxArmyPop;
      debugCore("CV We've decided that: " + militaryPopLimit + " should be our military population for now");
   }
   else
   {
      debugCore("We've decided that: " + militaryPopLimit + " should be our military population for now");
   }
   aiSetMilitaryPop(militaryPopLimit);
}

//==============================================================================
// popManager
// Set population limits based on age, difficulty and control variable settings.
//==============================================================================
void popManager(bool revoltedMilitary = false, bool revoltedEconomic = false)
{
   int age = kbGetAge();
   int maxMil = -1;

   debugCore("gMaxPop: " + gMaxPop);
   // Easy, Typically 20 econ, 20 mil
   // Standard, Typically 35 econ, 35 mil.
   // Moderate, Typically 60 econ, 60 mil.
   // Hard / Hardest / Extreme Typically 99 econ, 101 mil.
   if (revoltedMilitary == true)
   {
      maxMil = gMaxPop;
      debugCore("We've revolted with a military revolt, use our full gMaxPop for military now");
   }
   else if (revoltedEconomic == true)
   { // We assume that all revolts are done in Industrial so we take cAge5, if we let MX revolt we need to look at this again
      maxMil = gMaxPop - xsArrayGetInt(gTargetSettlerCounts, cAge5);
      debugCore(
          "We've revolted with an Economic revolt, using gTargetSettlerCounts cAge5 to determine our maxMil: " +
          xsArrayGetInt(gTargetSettlerCounts, cAge5));
   }
   else if (age == cvMaxAge)
   { // Make sure everybody gets their full military potential in the last age using their real wanted Settler counts.
      maxMil = gMaxPop - xsArrayGetInt(gTargetSettlerCounts, cAge5);
      debugCore(
          "We're in the maximum age, using gTargetSettlerCounts cAge5 to determine our maxMil: " +
          xsArrayGetInt(gTargetSettlerCounts, cAge5));
   }
   else
   {
      maxMil = gMaxPop - xsArrayGetInt(gTargetSettlerCountsDefault, age);
      debugCore(
          "We're not in the maximum age, using gTargetSettlerCountsDefault at index 'current age' to determine our maxMil: " +
          xsArrayGetInt(gTargetSettlerCountsDefault, age));
   }

   debugCore("Maximum potential Military: " + maxMil + ", this may be reduced because of Age restrictions");

   // Limit the amount of military units we train if we haven't reached the minimum age we want.
   // If the max age was set below Industrial the function setMilPopLimit will take care of it and assign us the our full
   // military potential anyway.
   if (cDifficultyCurrent >= gDifficultyExpert)
   {
      if (btRushBoom <= -0.5) // Fast Industrial which means lower army pop in Commerce / Fortress.
      {
         setMilPopLimit(maxMil / 6, maxMil / 6, maxMil / 6, maxMil, maxMil);
      }
      else if (btRushBoom <= 0.0) // Fast Fortress which means lower army pop in Commerce.
      {
         setMilPopLimit(maxMil / 6, maxMil / 6, maxMil / 2, maxMil, maxMil);
      }
      else // Stay longer in Commerce so higher army pop there.
      {
         setMilPopLimit(maxMil / 6, maxMil / 2, maxMil / 2, maxMil, maxMil);
      }
   }
   else
   {
      setMilPopLimit(
          maxMil / 6,
          maxMil / 3,
          maxMil / 2,
          maxMil,
          maxMil); // On lower difficulties we just ignore the bt settings altogether.
   }
   
   if (gAgeUpPriority > 60)
	 {
		 maxMil = 50;
         setMilPopLimit(0, maxMil, maxMil, maxMil, maxMil); 
	 }
	 else
	 {
     maxMil = gMaxPop-50;
	 setMilPopLimit(0, maxMil, maxMil, maxMil, maxMil); 
	 }
	 if ((gRevolutionType & cRevolutionMilitary) != 0)
	 {
	  maxMil = gMaxPop;
	 setMilPopLimit(0, maxMil, maxMil, maxMil, maxMil); 
	 }

   gGoodArmyPop = aiGetMilitaryPop() / 3; // Just used for some chats.
}

//==============================================================================
// updateSettlersAndPopManager
// Something happened in the game that forces us to update our Settler logic, like age ups.
// In this func we analyse the state of the game and based on that decide how to update everything.
//==============================================================================
void updateSettlersAndPopManager()
{
   // Handle the revolutions first then regular play.
   if ((gRevolutionType & cRevolutionMilitary) != 0)
   {
      popManager(true); // Tell the pop manager we don't need Settlers anymore and go full military.
                        // Our Settler maintain plan is already nulled out at this point.
      return;
   }
   if ((gRevolutionType & cRevolutionEconomic) != 0)
   { // We have revolted with an economic revolution or we sent a card to enable Settlers again, restore our Settler maintain
     // stuff.
      for (i = cAge1; <= cvMaxAge)
      {
         xsArraySetInt(gTargetSettlerCounts, i, xsArrayGetInt(gTargetSettlerCountsDefault, i));
      }
      // We have restored our array back to our default values but if our newly obtained gEconUnit has a lower bl than we saved
      // in our default array we need to adapt. For example the Dutch have >50 in their default array in cAge5 while their now
      // obtained Settler will have a 50 BL again. Also let's take our cvMaxCivPop into account here again because the array we
      // just took our values from hasn't been adjusted with those (intended).
      int buildLimit = kbGetBuildLimit(cMyID, gEconUnit);
      for (i = cAge1; <= cvMaxAge)
      {
         if (cvMaxCivPop > -1)
         {
            if (xsArrayGetInt(gTargetSettlerCounts, i) > cvMaxCivPop)
            {
               xsArraySetInt(gTargetSettlerCounts, i, cvMaxCivPop);
            }
         }
         if (xsArrayGetInt(gTargetSettlerCounts, i) > buildLimit)
         {
            xsArraySetInt(gTargetSettlerCounts, i, buildLimit);
         }
      }
      updateSettlerCounts();
      popManager(false, true);
      return;
   }

   // On easy we never increase the amount of Settlers we want so don't need to update it either.
   if (cDifficultyCurrent != cDifficultySandbox)
   {
      updateSettlerCounts();
   }
   popManager();
}

//==============================================================================
// treatyCheckStartMakingArmy
// We need to call popManager once when the treaty is 10 minutes away from being over so we can set a valid military pop.
// The minInterval number set here is not used but is overwritten in townCenterComplete.
//==============================================================================
rule treatyCheckStartMakingArmy
inactive
minInterval 30
{
   popManager();
   xsDisableSelf();
}

//==============================================================================
// toggleSpawning
// Used in toggleAutomaticSettlerSpawning to actually toggle the spawning.
//==============================================================================

void toggleSpawning(bool shouldSpawn = false)
{
   int queryID = createSimpleUnitQuery(cUnitTypeTownCenter);
   int numberResults = kbUnitQueryExecute(queryID);
   int townCenterID = -1;
   int numActions = -1;
   if (numberResults < 0)
   {
      return;
   }

   for (i = 0; < numberResults)
   {
      townCenterID = kbUnitQueryGetResult(queryID, i);
      numActions = kbUnitGetNumberActions(townCenterID);
      for (j = 0; < numActions)
      {
         if (kbUnitGetActionTypeByIndex(townCenterID, j) == cActionTypeMaintain)
         {
            if (kbUnitGetActionPausedByIndex(townCenterID, j) == true) // Paused.
            {
               // We want to spawn and this Town Center is not spawning so toggle it.
               if (shouldSpawn == true)
               {
                  aiTaskUnitCancel(townCenterID, kbUnitGetActionIDByIndex(townCenterID, j));
               }
            }
            else // Unpaused.
            {
               if (shouldSpawn == false)
               {
                  // We don't want to spawn and this Town Center is spawning so toggle it.
                  aiTaskUnitCancel(townCenterID, kbUnitGetActionIDByIndex(townCenterID, j));
               }
            }
         }
      }
   }
}

//==============================================================================
// toggleAutomaticSettlerSpawning
// The mechanic where Town Centers automatically spawn Settlers completely ignores aiSetEconomyPop().
// Thus Ottomans and USA with Gold Rush card completely ignore the Settler limits sets for them and just keep spawning.
// This rule keeps checking if we're at our maximum allowed Settlers and
// depending on the result turns the spawning off / on.
//==============================================================================
rule toggleAutomaticSettlerSpawning
inactive
minInterval 30
{
   int wantedExtraSettlers = getSettlerShortfall();
   // We want more economic units than we have now, turn spawning on.
   if (wantedExtraSettlers > 0)
   {
      debugCore("We want more economic units than we have, turn spawning on");
      toggleSpawning(true);
   }
   // We want as much or less economic units than we have now, turn spawning off.
   else if (wantedExtraSettlers <= 0)
   {
      debugCore("We want as much or less economic units than we have, turn spawning offf");
      toggleSpawning(false);
   }
}

//==============================================================================
// transportShipmentArrive()
//==============================================================================
void transportShipmentArrive(int techID = -1)
{
   debugCore("We've received a shipment with the name: " + kbGetTechName(techID));
   switch (techID)
   {
   case cTechDEHCREVDhimma:
   case cTechDEHCREVCitizenship:
   case cTechDEHCREVCitizenshipOutpost:
   case cTechDEHCREVMinasGerais:
   case cTechDEHCREVSalitrera:
   case cTechDEHCREVAcehExports:
   {
      cvOkToGatherFood = true;
      cvOkToGatherWood = true;
      cvOkToGatherGold = true;
      gRevolutionType = cRevolutionEconomic;
      gEconUnit = cUnitTypeSettler;
      if (gFishingBoatMaintainPlan > 0)
      {
         xsEnableRule("fishManager");
      }
      updateSettlersAndPopManager();
      break;
   }
   case cTechDEHCREVNothernWilderness:
   {
      cvOkToGatherFood = true;
      cvOkToGatherGold = true;
      break;
   }
   case cTechHCBanks1:
   case cTechHCBanks2: // These cards increases our Settler build limit by 5.
   {
      for (i = cAge1; <= cvMaxAge)
      {
         xsArraySetInt(gTargetSettlerCounts, i, xsArrayGetInt(gTargetSettlerCounts, i) + 5);
      }
      updateSettlersAndPopManager();
      break;
   }
   case cTechDEHCFedGoldRush: // USA Federal card that turns their Settler spawning into the Ottoman mechanic.
   {
      updateSettlersAndPopManager();
      // It only makes sense to enable this spawning tracker if we're not allowed to reach the build limit of our gEconUnit.
      int comparisonDifficulty = gSPC == true ? cDifficultyExpert : cDifficultyHard;
      if ((cDifficultyCurrent < comparisonDifficulty) || (cvMaxCivPop > -1))
      {
         debugCore(
            "Turning on Rule 'toggleAutomaticSettlerSpawning' because we sent the Gold Rush card" +
            " and still have build limits to take into account");
         xsEnableRule("toggleAutomaticSettlerSpawning");
      }
      break;
   }
   case cTechHCGermantownFarmers:
   {
      createSimpleMaintainPlan(
         cUnitTypeSettlerWagon, kbGetBuildLimit(cMyID, cUnitTypeSettlerWagon), true, kbBaseGetMainID(cMyID), 1);
      break;
   }
   case cTechHCXPNewWaysSioux:    // Lakota New Ways card.
   case cTechHCXPNewWaysIroquois: // Haudenosaunee New Ways card.
   {
      xsEnableRule("arsenalUpgradeMonitor");
      break;
   }
   case cTechHCAdvancedArsenalGerman:
   case cTechHCAdvancedArsenal:
   {
      xsEnableRule("advancedArsenalUpgradeMonitor");
      xsEnableRule("ArsenalUpgradeMonitor"); // In case we get this card in Age2 we need to enable this rule now since otherwise
      break;                                 // it won't be enabled until Age 3.
   }
   case cTechHCUnlockFactory:
   case cTechHCRobberBarons:
   case cTechHCUnlockFactoryGerman:
   case cTechHCRobberBaronsGerman:
   case cTechHCXPIndustrialRevolution:
   case cTechHCXPIndustrialRevolutionGerman:
   case cTechDEHCREVUnlockFactory:
   case cTechDEHCREVIndustrialRevolution:
   case cTechDEHCREVRobberBarons:
   case cTechDEHCFedNewHampshireManufacturing:
   case cTechDEHCPorfiriato:
   case cTechDEHCREVMXRobberBarons2:
   case cTechDEHCREVMXUnlockFactory:
   case cTechDEHCREVMXCaliforniaRobberBarons:
   case cTechypConsulateRussianFactoryWagon:
   {
      if (cDifficultyCurrent >= cDifficultyEasy)
      {
         if (xsIsRuleEnabled("factoryUpgradeMonitor") == false)
         {
            xsEnableRule("factoryUpgradeMonitor");
         }
         if (xsIsRuleEnabled("factoryTacticMonitor") == false)
         {
            xsEnableRule("factoryTacticMonitor");
         }
      }
      break;
   }
   case cTechDEHCFedBearFlagRevolt:
   {
      // US HC card which is a revolt but doesn't disable train villagers.
      revoltedHandler(techID);
      break;
   }
   case cTechHCUnlockFort:
   case cTechHCUnlockFortGerman:
   case cTechHCUnlockFortVauban:
   case cTechHCREVShipFortWagon:
   case cTechHCXPUnlockFort2:
   case cTechHCXPUnlockFort2German:
   case cTechDEHCREVShipFortWagonOutpost:
   case cTechDEHCKalmarCastle:
   case cTechDEHCImmigrantsRussian:
   case cTechDEHCFedPutnamEngineering:
   case cTechDEHCFedMXTriasFortifications:
   case cTechDEHCChapultepecCastle:
   case cTechDEHCREVMXShipFortWagon2:
   case cTechypConsulateRussianFortWagon:
   {
      forwardBaseManager(); // Make sure our Fort Wagons are handled.
      break;
   }
   }
}

//==============================================================================
/* Native Dance Monitor

   Manage the number of natives dancing, and the 'tactic' they're dancing for.

const int cTacticFertilityDance=12;   Faster training
const int cTacticGiftDance=13;         Faster XP trickle
const int cTacticCityDance=14;
const int cTacticWaterDance=15;       Increases navy HP/attack
const int cTacticAlarmDance=16;        Town defense...
const int cTacticFounderDance=17;      xpBuilder units - Iroquois
const int cTacticMorningWarsDance=18;
const int cTacticEarthMotherDance=19;
const int cTacticHealingDance=20;
const int cTacticFireDance=21;
const int cTacticWarDanceSong=22;
const int cTacticGarlandWarDance=23;
const int cTacticWarChiefDance=24;    new war chief
const int cTacticHolyDance=25;

*/
//==============================================================================
rule danceMonitor
inactive
group tcComplete
minInterval 20
{
   if (civIsNative() == false)
   {
      xsDisableSelf();
      return;
   }
   static int lastTactic = -1;
   static int lastTacticTime = 0;
   static int danceTactics = -1;
   static int lastVillagerTime = 0;
   int time = xsGetTime();
   if (danceTactics < 0)
   {
      // Setup dance tactics we want to use.
      switch (cMyCiv)
      {
      case cCivXPAztec:
      {
         danceTactics = xsArrayCreateInt(6, -1, "Dance tactics");
         // Shared
         xsArraySetInt(danceTactics, 0, cTacticFertilityDance);
         xsArraySetInt(danceTactics, 1, cTacticGiftDance);
         xsArraySetInt(danceTactics, 2, cTacticAlarmDance);
         xsArraySetInt(danceTactics, 3, cTacticWarDance);
         xsArraySetInt(danceTactics, 4, cTacticWarChiefDanceAztec);
         xsArraySetInt(danceTactics, 5, cTacticHolyDanceAztec);
         //xsArraySetInt(danceTactics, 6, cTacticGarlandWarDance);
         break;
      }
      case cCivXPIroquois:
      {
         danceTactics = xsArrayCreateInt(5, -1, "Dance tactics");
         // Shared
         xsArraySetInt(danceTactics, 0, cTacticFertilityDance);
         xsArraySetInt(danceTactics, 1, cTacticGiftDance);
         xsArraySetInt(danceTactics, 2, cTacticAlarmDance);
         xsArraySetInt(danceTactics, 3, cTacticWarDance);
         xsArraySetInt(danceTactics, 4, cTacticWarChiefDance);
         break;
      }
      case cCivXPSioux:
      {
         danceTactics = xsArrayCreateInt(6, -1, "Dance tactics");
         // Shared
         xsArraySetInt(danceTactics, 0, cTacticFertilityDance);
         xsArraySetInt(danceTactics, 1, cTacticGiftDance);
         xsArraySetInt(danceTactics, 2, cTacticAlarmDance);
         xsArraySetInt(danceTactics, 3, cTacticWarDance);
         xsArraySetInt(danceTactics, 4, cTacticWarChiefDanceSioux);
         xsArraySetInt(danceTactics, 5, cTacticWarDanceSong);
         break;
      }
      case cCivDEInca:
      {
         danceTactics = xsArrayCreateInt(6, -1, "Dance tactics");
         // Shared
         xsArraySetInt(danceTactics, 0, cTacticFertilityDance);
         xsArraySetInt(danceTactics, 1, cTacticGiftDance);
         xsArraySetInt(danceTactics, 2, cTacticAlarmDance);
         xsArraySetInt(danceTactics, 3, cTacticWarDance);
         xsArraySetInt(danceTactics, 4, cTacticdeWarChiefDanceInca);
         xsArraySetInt(danceTactics, 5, cTacticdeMoonDance);
         break;
      }
      }
   }
   if (gNativeDancePlan < 0)
   {
      gNativeDancePlan = createNativeResearchPlan(cTacticNormal, 85, 1, 1, 1);
      lastTactic = cTacticNormal;
      lastTacticTime = time;
   }
   int numWarPriests = 0;
   int limitWarPriests = 0;
   int numPriestesses = 0;
   int numLlamas = 0;
   int numEconUnits = 0;
   int totalBonusDancers = 0;
   int mainBaseID = kbBaseGetMainID(cMyID);
   // If not in defense reflex use up to 25 available warrior priests as dancers
   //if (gDefenseReflexBaseID != mainBaseID)
   //{
      // War priest
      numWarPriests = kbUnitCount(cMyID, cUnitTypexpMedicineManAztec, cUnitStateAlive);
      // Don't defend with warrior priests when there are no villagers dancing as we can produce warriors from the plaza.
      //if (gDefenseReflexBaseID != mainBaseID || (numWarPriests > 0 && aiPlanGetNumberUnits(gNativeDancePlan, gEconUnit) == 0))
      //{
         if (cMyCiv == cCivXPAztec)
         {
            limitWarPriests = kbGetBuildLimit(cMyID, cUnitTypexpMedicineManAztec);
            if (limitWarPriests < numWarPriests)
               limitWarPriests = numWarPriests;
         }
         else
         {
            limitWarPriests = numWarPriests;
         }
         totalBonusDancers = numWarPriests;
         if (totalBonusDancers > 25)
            totalBonusDancers = 25;
      //}
   //}
   // Priestess
   if (totalBonusDancers < 25)
   {
      numPriestesses = kbUnitCount(cMyID, cUnitTypedePriestess, cUnitStateAlive);
      if ((totalBonusDancers + numPriestesses) > 25)
      {
         numPriestesses = 25 - totalBonusDancers;
         totalBonusDancers = 25;
      }
      else
      {
         totalBonusDancers = totalBonusDancers + numPriestesses;
      }
   }
   // Llama
   if (cMyCiv == cCivDEInca && totalBonusDancers < 25)
   {
      numLlamas = kbUnitCount(cMyID, cUnitTypeLlama, cUnitStateAlive);
      if ((totalBonusDancers + numLlamas) > 25)
      {
         numLlamas = 25 - totalBonusDancers;
         totalBonusDancers = 25;
      }
      else
      {
         totalBonusDancers = totalBonusDancers + numLlamas;
      }
   }
   aiPlanAddUnitType(gNativeDancePlan, cUnitTypexpMedicineManAztec, numWarPriests, numWarPriests, limitWarPriests);
   aiPlanAddUnitType(gNativeDancePlan, cUnitTypedePriestess, numPriestesses, numPriestesses, numPriestesses);
   if (cMyCiv == cCivDEInca)
      aiPlanAddUnitType(gNativeDancePlan, cUnitTypeLlama, numLlamas, numLlamas, numLlamas);
   int numDanceTactics = xsArrayGetSize(danceTactics);
   int tacticID = -1;
   int tacticPriority = 0;
   int bestTacticID = -1;
   int bestTacticPriority = 0;
   int planID = -1;
   const int cMinDancePriorityVillager = 3;
   int maxMilitaryPop = 0;
   float militaryPercentage = 0.0;
   int numPlazas = kbUnitCount(cMyID, cUnitTypeCommunityPlaza, cUnitStateAlive);
   bool warriorLimitReached =
       kbUnitCount(cMyID, cUnitTypexpWarrior, cUnitStateAlive) >= kbGetBuildLimit(cMyID, cUnitTypexpWarrior);
   // Go through all tactics and find the best one.
   for (i = 0; < numDanceTactics)
   {
      tacticID = xsArrayGetInt(danceTactics, i);
      tacticPriority = 0;
      switch (tacticID)
      {
      case cTacticFertilityDance: // Speed up unit production.
      {
         if (kbUnitCount(cMyID, gEconUnit, cUnitStateAlive) > 60 && (aiGetAvailableMilitaryPop() >= 50) &&
             ((kbGetPopCap() - kbGetPop()) >= 50))
            tacticPriority = 94;
         break;
      }
      case cTacticGiftDance: // Generates XP.
      {
         // Defaults to gift dance.
         tacticPriority = cMinDancePriorityVillager - 2;
         break;
      }
      /*case cTacticAlarmDance: // Spawn warriors.
      {
         if (numPlazas > 0 && gDefenseReflexBaseID == mainBaseID && warriorLimitReached == false)
            tacticPriority = 99;
         break;
      }*/
      case cTacticWarDance: // Increase attack.
      {
         //planID = aiPlanGetIDByTypeAndVariableType(cPlanAttack, cAttackPlanBaseAttackMode, cAttackPlanBaseAttackModeExplicit);
         //planID = aiPlanGetIDByTypeAndVariableType(cPlanAttack);
         /*if (numPlazas > 0 && ((planID >= 0 && aiPlanGetState(planID) == cPlanStateAttack) ||
                               (gDefenseReflexBaseID == mainBaseID && warriorLimitReached == true &&
                                kbGetPopulationSlotsByUnitTypeID(cMyID, cUnitTypeLogicalTypeLandMilitary) >=
                                    (0.3 * aiGetMilitaryPop()))))*/
		    if ((numPlazas > 0) && ((kbGetMaxPop()-kbGetPop()) <= 40))
            tacticPriority = 98;
		else
            tacticPriority = 10;
         break;
      }
      case cTacticWarChiefDanceAztec: // Rescue Aztec warchief.
      {
         if (aiGetFallenExplorerID() >= 0)
            tacticPriority = 11;//cMinDancePriorityVillager - 1;
         break;
      }
      case cTacticWarChiefDance: // Rescue Iroquois warchief.
      {
         if (aiGetFallenExplorerID() >= 0)
            tacticPriority = 11;//cMinDancePriorityVillager - 1;
         break;
      }
      case cTacticWarChiefDanceSioux: // Rescue Sioux warchief.
      {
         if (aiGetFallenExplorerID() >= 0)
            tacticPriority = 11;//cMinDancePriorityVillager - 1;
         break;
      }
      case cTacticdeWarChiefDanceInca: // Rescue Inca warchief.
      {
         if (aiGetFallenExplorerID() >= 0)
            tacticPriority = 11;//cMinDancePriorityVillager - 1;
         break;
      }
      case cTacticHolyDanceAztec: // Spawn warrior priests.
      {
         if (kbUnitCount(cMyID, cUnitTypexpMedicineManAztec, cUnitStateAlive) <
             kbGetBuildLimit(cMyID, cUnitTypexpMedicineManAztec))
         {
            if (totalBonusDancers > 1 || (xsArrayGetFloat(gResourceNeeds, cResourceFood) <= -1000.0 &&
                                          xsArrayGetFloat(gResourceNeeds, cResourceWood) <= -1000.0 &&
                                          xsArrayGetFloat(gResourceNeeds, cResourceGold) <= -1000.0))
               // We spent at least 30 seconds into spawning this unit, avoid switching.
               if (lastTactic == cTacticHolyDanceAztec && (time - lastTacticTime) >= 30000 &&
                   (time - lastTacticTime) < 90000)
                  tacticPriority = 99;
               else
                  tacticPriority = 96;
         }
         break;
      }/*
      case cTacticGarlandWarDance: // Spawn skull knights.
      {
         if ((numPlazas > 0) && (kbGetAge() >= cAge4) && (aiGetAvailableMilitaryPop() >= 10) &&
             ((kbGetPopCap() - kbGetPop()) >= 10))
         {
            // We spent at least 30 seconds into spawning this unit, avoid switching.
            if (lastTactic == cTacticGarlandWarDance && (time - lastTacticTime) >= 30000 &&
                (time - lastTacticTime) < 90000)
               tacticPriority = 99;
            else
               tacticPriority = 95;
         }
         break;
      }
      case cTacticWarDanceSong: // Spawn dog soldiers.
      {
         if ((numPlazas > 0) && (kbGetAge() >= cAge4) && (aiGetAvailableMilitaryPop() >= 10) &&
             ((kbGetPopCap() - kbGetPop()) >= 10))
         {
            // We spent at least 30 seconds into spawning this unit, avoid switching.
            if (lastTactic == cTacticWarDanceSong && (time - lastTacticTime) >= 30000 &&
                (time - lastTacticTime) < 90000)
               tacticPriority = 99;
            else
               tacticPriority = 95;
         }
         break;
      }
      case cTacticdeMoonDance: // Wood trickle.
      {
         // When we run out of wood.
         if ((gDisableWoods == true && time > 120000 && xsArrayGetInt(gResourceNeeds, cResourceWood) > 0.0) ||
             // Don't switch for at least 60 seconds.
             (lastTactic == cTacticdeMoonDance && (time - lastTacticTime) < 60000))
            tacticPriority = 97;
         break;
      }*/
      }
      if (bestTacticPriority < tacticPriority)
      {
         bestTacticID = tacticID;
         bestTacticPriority = tacticPriority;
      }
   }
   if (bestTacticPriority < cMinDancePriorityVillager && totalBonusDancers < 2)
   {
      aiPlanAddUnitType(gNativeDancePlan, gEconUnit, 0, 0, 0);
      return;
   }
   // Build community plaza if there isn't one.
   if (numPlazas < 1)
   {
      planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeCommunityPlaza);
      if (planID < 0)
         planID = createSimpleBuildPlan(cUnitTypeCommunityPlaza, 1, 92, false, cEconomyEscrowID, mainBaseID, 1);
      aiPlanSetDesiredResourcePriority(planID, 60);
      aiPlanAddUnitType(gNativeDancePlan, gEconUnit, 0, 0, 0);
      aiEcho("Starting a new community plaza build plan.");
      return;
   }
   if (bestTacticPriority >= cMinDancePriorityVillager && (time - lastVillagerTime) >= 60000)
   {
      numEconUnits = ((kbUnitCount(cMyID, gEconUnit, cUnitStateAlive) * 0.10) - totalBonusDancers);// 10;
	  if (numEconUnits > 25)
            numEconUnits = 25;
         if (numEconUnits < 0)
            numEconUnits = 0;
      switch (bestTacticID)
      {
      case cTacticWarDance:
      {
         // Scale by military pop.
         maxMilitaryPop = gMaxPop - aiGetEconomyPop();
         if (maxMilitaryPop > 0)
            militaryPercentage =
                kbGetPopulationSlotsByUnitTypeID(cMyID, cUnitTypeLogicalTypeLandMilitary) / maxMilitaryPop;
         numEconUnits = ((kbUnitCount(cMyID, gEconUnit, cUnitStateAlive) * 0.26) - totalBonusDancers);
         if (numEconUnits > 25)
            numEconUnits = 25;
         if (numEconUnits < 0)
            numEconUnits = 0;
         aiPlanAddUnitType(gNativeDancePlan, gEconUnit, numEconUnits, numEconUnits * 2, numEconUnits * 2);
         break;
      }
      case cTacticdeMoonDance:
      {
         // Need more dancers as we are out of wood.
         numEconUnits = numEconUnits * 2 - totalBonusDancers;
         if (numEconUnits > 25)
            numEconUnits = 25;
         if (numEconUnits < 0)
            numEconUnits = 0;
         aiPlanAddUnitType(gNativeDancePlan, gEconUnit, numEconUnits, numEconUnits * 2, numEconUnits * 2);
         break;
      }
      default:
      {
         // Add a number of dancers equivalent to 1/10 of settler pop, rounded down
         // Make sure no more than 25 units are assigned in total
         numEconUnits = ((kbUnitCount(cMyID, gEconUnit, cUnitStateAlive) * 0.10) - totalBonusDancers);
         if (numEconUnits > 25)
            numEconUnits = 25;
         if (numEconUnits < 0)
            numEconUnits = 0;
         aiPlanAddUnitType(gNativeDancePlan, gEconUnit, numEconUnits / 2, numEconUnits, numEconUnits * 2);
         break;
      }
      }
      lastVillagerTime = time;
   }
   aiPlanSetVariableInt(gNativeDancePlan, cNativeResearchPlanTacticID, 0, bestTacticID);
   lastTactic = bestTacticID;
   lastTacticTime = time;
}

//==============================================================================
void gameOverHandler(int nothing = 0)
{
   bool iWon = false;
   if (kbHasPlayerLost(cMyID) == false)
      iWon = true;

   debugCore("Game is over.");
   debugCore("Have I lost returns " + kbHasPlayerLost(cMyID));
   if (iWon == false)
      debugCore("I lost.");
   else
      debugCore("I won.");

   for (pid = 1; < cNumberPlayers)
   {
      //-- Skip ourself.
      if (pid == cMyID)
         continue;

      //-- get player name
      string playerName = kbGetPlayerName(pid);
      debugCore("PlayerName: " + playerName);

      //-- Does a record exist?
      int playerHistoryID = aiPersonalityGetPlayerHistoryIndex(playerName);
      if (playerHistoryID == -1)
      {
         debugCore("PlayerName: Never played against");
         //-- Lets make a new player history.
         playerHistoryID = aiPersonalityCreatePlayerHistory(playerName);
      }

      /* Store the following user vars:
            heBeatMeLastTime
            iBeatHimLastTime
            iCarriedHimLastTime
            heCarriedMeLastTime
            iWonLastGame
      */
      if (iWon == true)
      { // I won
         aiPersonalitySetPlayerUserVar(playerHistoryID, "iWonLastGame", 1.0);
         if (kbIsPlayerEnemy(pid) == true)
         {
            aiPersonalitySetPlayerUserVar(playerHistoryID, "iBeatHimLastTime", 1.0);
            aiPersonalitySetPlayerUserVar(playerHistoryID, "heBeatMeLastTime", 0.0);
            debugCore("This player was my enemy.");
         }
      }
      else
      { // I lost
         aiPersonalitySetPlayerUserVar(playerHistoryID, "iWonLastGame", 0.0);
         if (kbIsPlayerEnemy(pid) == true)
         {
            aiPersonalitySetPlayerUserVar(playerHistoryID, "iBeatHimLastTime", 0.0);
            aiPersonalitySetPlayerUserVar(playerHistoryID, "heBeatMeLastTime", 1.0);
            debugCore("This player was my enemy.");
         }
      }
      if (kbIsPlayerAlly(pid) == true)
      { // Was my ally
         if (aiGetScore(cMyID) > (2 * aiGetScore(pid)))
         { // I outscored him badly
            aiPersonalitySetPlayerUserVar(playerHistoryID, "iCarriedHimLastTime", 1.0);
            debugCore("I carried my ally.");
         }
         else
            aiPersonalitySetPlayerUserVar(playerHistoryID, "iCarriedHimLastTime", 0.0);
         if (aiGetScore(pid) > (2 * aiGetScore(cMyID)))
         { // My ally carried me.
            debugCore("My ally carried me.");
            aiPersonalitySetPlayerUserVar(playerHistoryID, "heCarriedMeLastTime", 1.0);
         }
         else
            aiPersonalitySetPlayerUserVar(playerHistoryID, "heCarriedMeLastTime", 0.0);
      }
      else
      {
         aiPersonalitySetPlayerUserVar(playerHistoryID, "iCarriedHimLastTime", 0.0);
         aiPersonalitySetPlayerUserVar(playerHistoryID, "heCarriedMeLastTime", 0.0);
      }
   }
}

//==============================================================================
// ShouldIResign
//==============================================================================
rule ShouldIResign
minInterval 7
inactive
{
   static bool hadHumanAlly = false;

   // Don't resign if you have a human ally that's still in the game
   int i = 0;
   bool humanAlly = false; // Set true if we have a surviving human ally.
   int humanAllyID = -1;
   bool complained = false;     // Set flag true if I've already whined to my ally.
   bool wasHumanInGame = false; // Set true if any human players were in the game
   bool isHumanInGame = false;  // Set true if a human survives.  If one existed but none survive, resign.

   // Look for humans
   for (i = 1; <= cNumberPlayers)
   {
      if (kbIsPlayerHuman(i) == true)
      {
         wasHumanInGame = true;
         if (kbHasPlayerLost(i) == false)
            isHumanInGame = true;
      }
      if ((kbIsPlayerAlly(i) == true) && (kbHasPlayerLost(i) == false) && (kbIsPlayerHuman(i) == true))
      {
         humanAlly = true;    // Don't return just yet, let's see if we should chat.
         hadHumanAlly = true; // Set flag to indicate that we once had a human ally.
         humanAllyID = i;     // Player ID of lowest-numbered surviving human ally.
      }
   }

   // We do not have to resign when all of our human allies quit, there's still a chance...
   //   if ( (wasHumanInGame == true) && (isHumanInGame == false) )
   /*if ((hadHumanAlly == true) && (humanAlly == false)) // Resign if my human allies have quit.
   {
      //aiResign(); // If there are no humans left, and this wasn't a bot battle from the start, quit.
      debugCore("Resigning because I had a human ally, and he's gone...");
      aiResign(); // I had a human ally or allies, but do not any more.  Our team loses.
      return;  // Probably not necessary, but whatever...
   }
   // Check for MP with human allies gone.  This trumps the OkToResign setting, below.
   if ((aiIsMultiplayer() == true) && (hadHumanAlly == true) && (humanAlly == false))
   {  // In a multiplayer game...we had a human ally earlier, but none remain.  Resign immediately
      debugCore("Resign because my human ally is no longer in the game.");
      aiResign();    // Don't ask, just quit.
      xsEnableRule("resignRetry");
      xsDisableSelf();
      return;
   }*/

   // Don't resign too soon.
   if (xsGetTime() < 600000) // 600K = 10 min
      return;

   // Don't resign if we have over 30 active pop slots.
   if (kbGetPop() >= 30)
      return;

   // Resign if the known enemy pop is > 10x mine

   int enemyPopTotal = 0.0;
   int enemyCount = 0;
   int myPopTotal = 0.0;

   for (i = 1; < cNumberPlayers)
   {
      if (kbHasPlayerLost(i) == false)
      {
         if (i == cMyID)
            myPopTotal = myPopTotal + kbUnitCount(i, cUnitTypeUnit, cUnitStateAlive);
         if ((kbIsPlayerEnemy(i) == true) && (kbHasPlayerLost(i) == false))
         {
            enemyPopTotal = enemyPopTotal + kbUnitCount(i, cUnitTypeUnit, cUnitStateAlive);
            enemyCount = enemyCount + 1;
         }
      }
   }

   if (enemyCount < 1)
      enemyCount = 1; // Avoid div 0

   float enemyRatio = (enemyPopTotal / enemyCount) / myPopTotal;

   if (enemyRatio > 10) // My pop is 1/10 the average known pop of enemies
   {
      if (humanAlly == false)
      {
         debugCore("Resign at 10:1 pop: EP Total(" + enemyPopTotal + "), MP Total(" + myPopTotal + ")");
         aiAttemptResign(cAICommPromptToEnemyMayIResign);
         xsEnableRule("resignRetry");
         xsDisableSelf();
         return;
      }
      if ((humanAlly == true) && (complained == false))
      { // Whine to your partner
         sendStatement(humanAllyID, cAICommPromptToAllyImReadyToQuit);
         xsEnableRule("resignRetry");
         xsDisableSelf();
         complained = true;
      }
   }
   if ((enemyRatio > 4) && (kbUnitCount(cMyID, cUnitTypeTownCenter, cUnitStateAlive) <
                            1)) // My pop is 1/4 the average known pop of enemies, and I have no TC
   {
      if (humanAlly == false)
      {
         debugCore("Resign with no 4:1 pop and no TC: EP Total(" + enemyPopTotal + "), MP Total(" + myPopTotal + ")");
         aiAttemptResign(cAICommPromptToEnemyMayIResign);
         xsEnableRule("resignRetry");
         xsDisableSelf();
         return;
      }
   }
}

rule resignRetry
inactive
minInterval 240
{
   xsEnableRule("ShouldIResign");
   xsDisableSelf();
}

//==============================================================================
// resignHandler
// We've asked the human player if we could resign, here we handle his answer (result).
//==============================================================================
void resignHandler(int result = -1)
{
   debugCore("***************** Resign handler running with result " + result);
   if (result == 0)
   {
      xsEnableRule("resignRetry");
      return;
   }
   debugCore("Human player accepted our resign request, we now kill ourselves");

   aiResign();
}

//==============================================================================
/* rule abilityManager

   Use abilities when appropriate.
*/
//==============================================================================
rule abilityManager
inactive
minInterval 12
{
   vector myBaseLocation = kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID));
   int closestBaseID = kbFindClosestBase(cPlayerRelationEnemy, myBaseLocation);
   vector targetLocation = cInvalidVector;
   
   // Inspiration.
   if (cMyCiv == cCivIndians)
   {
      // Check if we have a Tower of Victory.
      int towerOfVictoryID = getUnit(gTowerOfVictoryPUID, cMyID, cUnitStateAlive);
      
      if (towerOfVictoryID >= 0)
      {
         // Check if the ability is off cooldown.
         if (aiCanUseAbility(towerOfVictoryID, cProtoPowerypPowerAttackBlessing) == true)
         {
            int firstAttackPlanID = aiPlanGetIDByTypeAndVariableType(cPlanCombat, cCombatPlanCombatType, 
            cCombatPlanCombatTypeAttack); 
            // Go through all the relevant plans and see if any of them are in combat.
            if ((aiPlanGetVariableBool(firstAttackPlanID, cCombatPlanInCombat, 0) == true) ||
                (aiPlanGetVariableBool(gLandDefendPlan0, cCombatPlanInCombat, 0) == true) ||
                (aiPlanGetVariableBool(gLandReservePlan, cCombatPlanInCombat, 0) == true))
            {
               aiTaskUnitSpecialPower(towerOfVictoryID, cProtoPowerypPowerAttackBlessing, -1, cInvalidVector);
            }
         }
      }
   }
   // Cease Fire.
   if (cMyCiv == cCivIndians)
   {
      // Check if we have a Taj Mahal.
      int tajMahalID = getUnit(gTajMahalPUID, cMyID, cUnitStateAlive);

      if (tajMahalID >= 0)
      {
         // Check if the ability is off cooldown.
         if (aiCanUseAbility(tajMahalID, cProtoPowerypPowerCeaseFire) == true)
         {
            // Check if we're under attack.
            if (gDefenseReflexBaseID == kbBaseGetMainID(cMyID))
            {
               aiTaskUnitSpecialPower(tajMahalID, cProtoPowerypPowerCeaseFire, -1, cInvalidVector);
            }
         }
      }
   }
   // Transcendence.
   if (cMyCiv == cCivChinese)
   {
      // Check if we have a Temple of Heaven.
      int templeOfHeavenID = getUnit(gTempleOfHeavenPUID, cMyID, cUnitStateAlive);
      
      if (templeOfHeavenID >= 0)
      {
         // Check if the ability is off cooldown.
         if (aiCanUseAbility(templeOfHeavenID, cProtoPowerypPowerGoodFortune) == true)
         {
            // Check if our land military is missing 50% of their HP or more.
            float armyMaxHP = getPlayerArmyHPs(cMyID, false);
            float armyCurrentHP = getPlayerArmyHPs(cMyID, true);
            float hpRatio = armyCurrentHP / armyMaxHP;
            if (hpRatio < 0.5)
            {
               aiTaskUnitSpecialPower(templeOfHeavenID, cProtoPowerypPowerGoodFortune, -1, cInvalidVector);
            }
         }
      }
   }
   // Informers.
   if (cMyCiv == cCivJapanese)
   {
      // Check if we have a Great Buddha.
      int greatBuddhaID = getUnit(gGreatBuddhaPUID, cMyID, cUnitStateAlive);
 
      if (greatBuddhaID >= 0)
      {
         // Check if the ability is off cooldown.
         if (aiCanUseAbility(greatBuddhaID, cProtoPowerypPowerInformers) == true)
         {
            aiTaskUnitSpecialPower(greatBuddhaID, cProtoPowerypPowerInformers, -1, cInvalidVector);
         }
      }
   }
   // Spyglass.
   if (cMyCiv == cCivPortuguese)
   {
      int explorerIDSpyglass = getUnit(cUnitTypeExplorer, cMyID, cUnitStateAlive);
      
      if (explorerIDSpyglass >= 0)
      {
         // Check if the ability is off cooldown.
         if (aiCanUseAbility(explorerIDSpyglass, cProtoPowerPowerLOS) == true)
         {
            if (closestBaseID == -1)
            { // If not yet visible, search for the enemy on the mirror position of my base.
               targetLocation = guessEnemyLocation();
            }
            if ((targetLocation == cInvalidVector) || 
                (kbLocationVisible(targetLocation) == true) || 
                (closestBaseID != -1))
            { // Otherwise reveal the closest enemy base for new information.
               targetLocation = kbBaseGetLocation(kbBaseGetOwner(closestBaseID), closestBaseID);
            }
            if (targetLocation != cInvalidVector)
            {
               aiTaskUnitSpecialPower(explorerIDSpyglass, cProtoPowerPowerLOS, -1, targetLocation);
            }
         }
      }
   }
   // Hot Air Balloon.
   if (civIsEuropean() == true)
   {
      int explorerIDBalloon = getUnit(cUnitTypeExplorer, cMyID, cUnitStateAlive);
      
      if (explorerIDBalloon >= 0)
      {
         if (aiCanUseAbility(explorerIDBalloon, cProtoPowerPowerBalloon) == true)
         {
            if (closestBaseID == -1)
            { // If not yet visible, search for the enemy on the mirror position of my base.
               targetLocation = guessEnemyLocation();
            }
            if ((targetLocation == cInvalidVector) || (kbLocationVisible(targetLocation) == true) || (closestBaseID != -1))
            { // Otherwise reveal the closest enemy base for new information.
               targetLocation = kbBaseGetLocation(kbBaseGetOwner(closestBaseID), closestBaseID);
            }
            if (targetLocation != cInvalidVector)
            {
               aiTaskUnitSpecialPower(explorerIDBalloon, cProtoPowerPowerBalloon, -1, targetLocation);
               int balloonExplore = aiPlanCreate("Balloon Explore", cPlanExplore);
               aiPlanSetDesiredPriority(balloonExplore, 75);
               aiPlanAddUnitType(balloonExplore, cUnitTypeHotAirBalloon, 0, 1, 1);
               aiPlanSetEscrowID(balloonExplore, cEconomyEscrowID);
               aiPlanSetBaseID(balloonExplore, kbBaseGetMainID(cMyID));
               aiPlanSetVariableBool(balloonExplore, cExplorePlanDoLoops, 0, false);
               aiPlanSetActive(balloonExplore);
            }
         }
      }
   }
   /* Combat plans can already use abilities and the bombard logic below is quite bad.
   // Long-range Bombardment Attack
   if (civIsNative() == false)
   {
      int monitorID = getUnit(gMonitorUnit, cMyID, cUnitStateAlive);
      if (monitorID >= 0)
      {
         // Check if the ability is off cooldown.
         if (aiCanUseAbility(monitorID, cProtoPowerPowerLongRange) == true)
         {
            vector monitorLocation = kbUnitGetPosition(monitorID);
            int targetIDmonitor = getUnitByLocation(
               cUnitTypeBuilding, cPlayerRelationEnemyNotGaia, cUnitStateAlive, monitorLocation, 100.0);
            if (targetIDmonitor != -1)
            {
               aiTaskUnitSpecialPower(monitorID, cProtoPowerPowerLongRange, targetIDmonitor, cInvalidVector);
            }
         }
      
   }
   */
   /* This upgrade is currently not being researched by the AI thus this logic below is unneeded.
   // Heal
   if ((cMyCiv == cCivXPIroquois) && (kbTechGetStatus(cTechBigFirepitSecretSociety) == cTechStatusActive))
   {
      int warchiefIDHeal = -1;
      warchiefIDHeal = getUnit(cUnitTypexpIroquoisWarChief, cMyID, cUnitStateAlive);
      if ((warchiefIDHeal >= 0) && aiCanUseAbility(warchiefIDHeal, cProtoPowerPowerHeal) == true &&
          (kbUnitGetHealth(warchiefIDHeal) < 0.8))
      {
         vector warchiefLocation = kbUnitGetPosition(warchiefIDHeal);
         aiTaskUnitSpecialPower(warchiefIDHeal, cProtoPowerPowerHeal, -1, warchiefLocation);
      }
   }
   */
   // Minor native Somali Lighthouse ability.
   if (isMinorNativePresent(cCivSomali) == true)
   {
      if (kbTechGetStatus(cTechDENatSomaliLighthouses) == cTechStatusActive)
      {
         int tradingPostID = checkAliveSuitableTradingPost(cCivSomali);
         if (tradingPostID > -1)
         { // Must target this ability on itself.
            aiTaskUnitSpecialPower(tradingPostID, cProtoPowerdeNatSomaliLighthouse, tradingPostID, cInvalidVector);
         }
      }
   }
}

rule transportMonitor
inactive
minInterval 10
{
   if (aiPlanGetIDByIndex(cPlanTransport, -1, true, 0) >= 0)
      return;

   // find idle units away from our base
   int baseAreaGroupID = kbAreaGroupGetIDByPosition(kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)));
   int areaGroupID = -1;
   int unitQueryID = createSimpleUnitQuery(cUnitTypeLogicalTypeGarrisonInShips, cMyID, cUnitStateAlive);
   int numberFound = kbUnitQueryExecute(unitQueryID);
   int unitID = -1;
   int planID = -1;
   vector position = cInvalidVector;
   bool transportRequired = false;
   for (i = 0; < numberFound)
   {
      unitID = kbUnitQueryGetResult(unitQueryID, i);
      // avoid transporting island explore scout back to our base
      if (unitID == gIslandExploreTransportScoutID)
         continue;
      position = kbUnitGetPosition(unitID);
      areaGroupID = kbAreaGroupGetIDByPosition(position);
      if (areaGroupID == baseAreaGroupID)
         continue;
      if (kbAreaGroupGetType(areaGroupID) == cAreaGroupTypeWater)
      {
         // if units are inside a water area(likely on a shore), make sure it does not border our main base area group
         int areaID = kbAreaGetIDByPosition(position);
         int numberBorders = kbAreaGetNumberBorderAreas(areaID);
         bool inMainBase = false;
         for (j = 0; < numberBorders)
         {
            if (kbAreaGroupGetIDByPosition(kbAreaGetCenter(kbAreaGetBorderAreaID(areaID, j))) == baseAreaGroupID)
            {
               inMainBase = true;
               break;
            }
         }
         if (inMainBase == true)
            continue;
      }
      planID = kbUnitGetPlanID(unitID);
      if (planID >= 0 && aiPlanGetDesiredPriority(planID) >= 25)
         continue;
      transportRequired = true;
      debugCore("Tranporting " + kbGetUnitTypeName(kbUnitGetProtoUnitID(unitID)) + " and its nearby units back to main base.");
      break;
   }

   if (transportRequired == false)
      return;

   // once we started transporting, make sure no one can steal units from us
   int transportPlanID = createTransportPlan(position, kbBaseGetMilitaryGatherPoint(cMyID, kbBaseGetMainID(cMyID)), 100, false);

   if (transportPlanID < 0)
      return;

   unitQueryID = createSimpleUnitQuery(cUnitTypeLogicalTypeGarrisonInShips, cMyID, cUnitStateAlive, position, 30.0);
   numberFound = kbUnitQueryExecute(unitQueryID);
   aiPlanAddUnitType(transportPlanID, cUnitTypeLogicalTypeGarrisonInShips, numberFound, numberFound, numberFound);
   for (i = 0; < numberFound)
   {
      unitID = kbUnitQueryGetResult(unitQueryID, i);
      if (aiPlanAddUnit(transportPlanID, unitID) == false)
      {
         aiPlanDestroy(transportPlanID);
         return;
      }
   }
   aiPlanSetNoMoreUnits(transportPlanID, true);
}

//==============================================================================
// revoltedHandler()
//==============================================================================
void revoltedHandler(int techID = -1)
{
   xsDisableRule("ageUpgradeMonitor"); // If we implement Mexican revolutions this needs to be changed.
   xsDisableRule("age5Monitor");
   debugCore("We revolted with " + kbGetTechName(techID));

   if (cMyCiv == cCivOttomans)
   {
      debugCore("DISABLING Rule: 'toggleAutomaticSettlerSpawning' because we revolted so it no longer applies to us");
      xsDisableRule("toggleAutomaticSettlerSpawning");
   }

   if ((techID == cTechDERevolutionSouthAfrica) || (techID == cTechDERevolutionCanadaBritish) ||
       (techID == cTechDERevolutionCanadaFrench))
   {
      gRevolutionType = cRevolutionEconomic;
      // Delete the Trek Wagons we get from this revolution since we don't use them.
      if (techID == cTechDERevolutionSouthAfrica)
      {
         int trekWagonQueryID = createSimpleUnitQuery(cUnitTypedeREVStarTrekWagon, cMyID, cUnitStateAlive);
         int numberFound = kbUnitQueryExecute(trekWagonQueryID);
         for (i = 0; < numberFound)
         {
            aiTaskUnitDelete(kbUnitQueryGetResult(trekWagonQueryID, i));
         }
      }
   }
   else
   {
      gRevolutionType = cRevolutionMilitary;
   }

   if (gRevolutionType == cRevolutionMilitary)
   {
      int numPlans = aiPlanGetActiveCount();
      int planID = -1;

      if (techID == cTechDERevolutionFinland)
      {
         gRevolutionType = gRevolutionType | cRevolutionEconomic | cRevolutionFinland;
         cvOkToGatherWood = true;
         cvOkToGatherFood = false;
         cvOkToGatherGold = false;
         gEconUnit = cUnitTypeSkirmisher;
         aiPlanSetVariableInt(gSettlerMaintainPlan, cTrainPlanUnitType, 0, gEconUnit);
         // Skirmisher does not count as villager, inform the AI we can use it as villager.
         aiAddGathererType(gEconUnit);
         gTowerUnit = cUnitTypeBlockhouse;
         gTimeToFarm = false;
         gTimeForPlantations = false;
         updateResourceDistribution();
      }
      else if (techID == cTechDEHCFedBearFlagRevolt)
      {
         // US HC card revolt, just proceed with destroying plans.
         // Unset revolution flag, we aren't disabling things.
         gRevolutionType = 0;
      }
      else
      { // Set all Settler related stuff to 0 but leave the default array to potentially restore everything. If cards arrive
        // that re-enable economy we handle that in transportShipmentArrive.
         aiPlanSetVariableInt(gSettlerMaintainPlan, cTrainPlanNumberToMaintain, 0, 0);
         for (i = cAge1; <= cvMaxAge)
         {
            xsArraySetInt(gTargetSettlerCounts, i, 0);
         }
      }

      // Destroy all build and gather plans when our settlers transformed into military units.
      // This will also destroy the plans for the Finnish revolution while their Jaegers can still build/gather.
      // But they have new/changed options so better be safe and start over.
      for (i = 0; < numPlans)
      {
         planID = aiPlanGetIDByActiveIndex(i);
         switch (aiPlanGetType(planID))
         {
         case cPlanBuild:
         {
            // Avoid destroying plans when it is built by wagons.
            if ((aiPlanGetNumberUnits(planID, cUnitTypeAbstractWagon) == 0) &&
                ((aiPlanGetState(planID) != cPlanStateBuild) || (gRevolutionType & cRevolutionFinland) == 0))
            {
               aiPlanDestroy(planID);
            }
            break;
         }
         case cPlanGather:
         {
            aiPlanDestroy(planID);
            break;
         }
         }
      }

      // Disable resource gathering because we have no units anymore which can do that.
      if ((gRevolutionType & cRevolutionFinland) == 0)
      {
         cvOkToGatherFood = false;
         cvOkToGatherWood = false;
         cvOkToGatherGold = false;
      }
      // Military revolts can't train Fishing Boats so null out the maintain plan and disable the manager.
      // Enable it all again in transportShipmentArrive when appropriate.
      if (gFishingBoatMaintainPlan > 0 && techID != cTechDEHCFedBearFlagRevolt)
      {
         xsDisableRule("fishManager");
         aiPlanSetVariableInt(gFishingBoatMaintainPlan, cTrainPlanNumberToMaintain, 0, 0);
      }
   }
   updateSettlersAndPopManager();
}

//==============================================================================
// ageTransitionManager
//
// Run military and building manager early to update resources we need.
//==============================================================================
rule ageTransitionManager
inactive
minInterval 1
{
   static int counter = 0;

   switch (counter)
   {
   case 0:
   {
      if ((xsIsRuleEnabled("militaryManager") == false) &&
          (cvOkToTrainArmy == true))
      {
         xsEnableRule("militaryManager");
         militaryManager(); // Call instantly to get started.
      }
      break;
   }
   case 1:
   {
      if (cvOkToBuild == true)
      {
         buildingMonitor();
      }
      break;
   }
   case 2:
   {
      updateResourceDistribution(true);
      break;
   }
   }

   counter++;
   if (counter >= 3)
   {
      xsDisableSelf();
      counter = 0;
   }
}

//==============================================================================
// ageUpHandler
//==============================================================================
void ageUpHandler(int playerID = -1)
{
   debugCore("ageUpHandler is called, player " + playerID + " aged up!");
   int age = kbGetAgeForPlayer(playerID);
   bool firstToAge = true; // Set true if this player is the first to reach that age, false otherwise
   bool lastToAge = true;  // Set true if this player is the last to reach this age, false otherwise
   int slowestPlayer = -1;
   int lowestAge = 100000;
   int lowestCount = 0; // How many players are still in the lowest age?
   static bool foundFirstInFortress = false;
   static bool foundFirstInIndustrial = false;
   static bool foundFirstInImperial = false;

   if (playerID == cMyID)
      aiPopulatePoliticianList(); // Update the list of possible age-up choices we have now.
   // debugCore("AGE HANDLER:  Player "+playerID+" is now in age "+age);

   for (index = 1; < cNumberPlayers)
   {
      if (index != playerID)
      {
         switch (age)
         {
         case cAge3:
         {
            if (foundFirstInFortress == false)
            {
               foundFirstInFortress = true;
            }
            else
            {
               firstToAge = false;
            }
            break;
         }
         case cAge4:
         {
            if (foundFirstInIndustrial == false)
            {
               foundFirstInIndustrial = true;
            }
            else
            {
               firstToAge = false;
            }
            break;
         }
         case cAge5:
         {
            if (foundFirstInImperial == false)
            {
               foundFirstInImperial = true;
            }
            else
            {
               firstToAge = false;
            }
            break;
         }
         }
         if (kbGetAgeForPlayer(index) < age)
            lastToAge = false; // Someone is still behind playerID.
      }
      if (kbGetAgeForPlayer(index) < lowestAge)
      {
         lowestAge = kbGetAgeForPlayer(index);
         slowestPlayer = index;
         lowestCount = 1;
      }
      else
      {
         if (kbGetAgeForPlayer(index) == lowestAge)
            lowestCount = lowestCount + 1;
      }
   }
   if (firstToAge == true)
   {
      switch (age)
      {
      case cAge3:
      {
         xsArraySetInt(gFirstAgeTime, cAge3, xsGetTime());
         debugCore("Time the first player reached the Fortress Age: " + xsArrayGetInt(gFirstAgeTime, cAge3));
      }
      case cAge4:
      {
         xsArraySetInt(gFirstAgeTime, cAge4, xsGetTime());
         debugCore("Time the first player reached the Industrial Age: " + xsArrayGetInt(gFirstAgeTime, cAge4));
      }
      case cAge5:
      {
         xsArraySetInt(gFirstAgeTime, cAge5, xsGetTime());
         debugCore("Time the first player reached the Imperial Age: " + xsArrayGetInt(gFirstAgeTime, cAge5));
      }
      }
   }

   if ((firstToAge == true) && (age == cAge2))
   { // This player was first to age 2
      if ((kbIsPlayerAlly(playerID) == true) && (playerID != cMyID))
         sendStatement(playerID, cAICommPromptToAllyHeReachesAge2First);
      if ((kbIsPlayerEnemy(playerID) == true))
         sendStatement(playerID, cAICommPromptToEnemyHeReachesAge2First);
      return ();
   }
   if ((lastToAge == true) && (age == cAge2))
   { // This player was last to age 2
      if ((kbIsPlayerAlly(playerID) == true) && (playerID != cMyID))
         sendStatement(playerID, cAICommPromptToAllyHeReachesAge2Last);
      if ((kbIsPlayerEnemy(playerID) == true))
         sendStatement(playerID, cAICommPromptToEnemyHeReachesAge2Last);
      return ();
   }

   // Check to see if there is a lone player that is behind everyone else
   if ((lowestCount == 1) && (slowestPlayer != cMyID))
   {
      // This player is slowest, nobody else is still in that age, and it's not me,
      // so set the globals and activate the rule...unless it's already active.
      // This will cause a chat to fire later (currently 120 sec mininterval) if
      // this player is still lagging technologically.
      if (gLateInAgePlayerID < 0)
      {
         if (xsIsRuleEnabled("lateInAge") == false)
         {
            gLateInAgePlayerID = slowestPlayer;
            gLateInAgeAge = lowestAge;
            xsEnableRule("lateInAge");
            return ();
         }
      }
   }

   // Check to see if ally advanced before me
   if ((kbIsPlayerAlly(playerID) == true) && (age > kbGetAgeForPlayer(cMyID)))
   {
      sendStatement(playerID, cAICommPromptToAllyHeAdvancesAhead);
      return ();
   }

   // Check to see if ally advanced before me
   if ((kbIsPlayerEnemy(playerID) == true) && (age > kbGetAgeForPlayer(cMyID)))
   {
      sendStatement(playerID, cAICommPromptToEnemyHeAdvancesAhead);
      return ();
   }
}

//==============================================================================
// ageUpEventHandler()
//==============================================================================
void ageUpEventHandler(int planID = -1)
{
   int state = aiPlanGetState(planID);
   // We save the last known Wonder we were going to construct in this variable.
   // The age up plan might be updated some times but when the plan goes into cPlanStateBuild
   // this handler is also called and the variable set.
   // And now the age up plan can not be changed anymore so what we have saved is valid.
   static int buildingPUID = -1;

   if (state == -1)
   {
      // Also make sure this building exists, because invalid state could also mean the plan failed.
      if (civIsAsian() == true && getUnit(buildingPUID, cMyID, cUnitStateAlive) >= 0)
      {
         if ((cMyCiv == cCivChinese) || (cMyCiv == cCivSPCChinese))
         {
            switch (buildingPUID)
            {
            case cUnitTypeypWCWhitePagoda2:
            case cUnitTypeypWCWhitePagoda3:
            case cUnitTypeypWCWhitePagoda4:
            case cUnitTypeypWCWhitePagoda5:
            {
               gWhitePagodaPUID = buildingPUID;
               debugCore("Wonder I built: " + kbGetProtoUnitName(gWhitePagodaPUID));
               break;
            }
            case cUnitTypeypWCSummerPalace2:
            case cUnitTypeypWCSummerPalace3:
            case cUnitTypeypWCSummerPalace4:
            case cUnitTypeypWCSummerPalace5:
            {
               gSummerPalacePUID = buildingPUID;
               xsEnableRule("summerPalaceTacticMonitor");
               debugCore("Wonder I built: " + kbGetProtoUnitName(gSummerPalacePUID));
               break;
            }
            case cUnitTypeypWCConfucianAcademy2:
            case cUnitTypeypWCConfucianAcademy3:
            case cUnitTypeypWCConfucianAcademy4:
            case cUnitTypeypWCConfucianAcademy5:
            {
               gConfucianAcademyPUID = buildingPUID;
               debugCore("Wonder I built: " + kbGetProtoUnitName(gConfucianAcademyPUID));
               break;
            }
            case cUnitTypeypWCTempleOfHeaven2:
            case cUnitTypeypWCTempleOfHeaven3:
            case cUnitTypeypWCTempleOfHeaven4:
            case cUnitTypeypWCTempleOfHeaven5:
            {
               gTempleOfHeavenPUID = buildingPUID;
               debugCore("Wonder I built: " + kbGetProtoUnitName(gTempleOfHeavenPUID));
               break;
            }
            case cUnitTypeypWCPorcelainTower2:
            case cUnitTypeypWCPorcelainTower3:
            case cUnitTypeypWCPorcelainTower4:
            case cUnitTypeypWCPorcelainTower5:
            {
               gPorcelainTowerPUID = buildingPUID;
               xsEnableRule("porcelainTowerTacticMonitor");
               debugCore("Wonder I built: " + kbGetProtoUnitName(gPorcelainTowerPUID));
               break;
            }
            }
         }
         else if ((cMyCiv == cCivIndians) || (cMyCiv == cCivSPCIndians))
         {
            switch (buildingPUID)
            {
            case cUnitTypeypWIAgraFort2:
            case cUnitTypeypWIAgraFort3:
            case cUnitTypeypWIAgraFort4:
            case cUnitTypeypWIAgraFort5:
            {
               gAgraFortPUID = buildingPUID;
               xsEnableRule("agraFortUpgradeMonitor");
               debugCore("Wonder I built: " + kbGetProtoUnitName(gAgraFortPUID));
               break;
            }
            case cUnitTypeypWICharminarGate2:
            case cUnitTypeypWICharminarGate3:
            case cUnitTypeypWICharminarGate4:
            case cUnitTypeypWICharminarGate5:
            {
               gCharminarGatePUID = buildingPUID;
               xsEnableRule("mansabdarMonitor");
               debugCore("Wonder I built: " + kbGetProtoUnitName(gCharminarGatePUID));
               break;
            }
            case cUnitTypeypWIKarniMata2:
            case cUnitTypeypWIKarniMata3:
            case cUnitTypeypWIKarniMata4:
            case cUnitTypeypWIKarniMata5:
            {
               gKarniMataPUID = buildingPUID;
               debugCore("Wonder I built: " + kbGetProtoUnitName(gKarniMataPUID));
               break;
            }
            case cUnitTypeypWITajMahal2:
            case cUnitTypeypWITajMahal3:
            case cUnitTypeypWITajMahal4:
            case cUnitTypeypWITajMahal5:
            {
               gTajMahalPUID = buildingPUID;
               debugCore("Wonder I built: " + kbGetProtoUnitName(gTajMahalPUID));
               break;
            }
            case cUnitTypeypWITowerOfVictory2:
            case cUnitTypeypWITowerOfVictory3:
            case cUnitTypeypWITowerOfVictory4:
            case cUnitTypeypWITowerOfVictory5:
            {
               gTowerOfVictoryPUID = buildingPUID;
               debugCore("Wonder I built: " + kbGetProtoUnitName(gTowerOfVictoryPUID));
               break;
            }
            }
         }
         else // We're Japanese.
         {
            switch (buildingPUID)
            {
            case cUnitTypeypWJGiantBuddha2:
            case cUnitTypeypWJGiantBuddha3:
            case cUnitTypeypWJGiantBuddha4:
            case cUnitTypeypWJGiantBuddha5:
            {
               gGreatBuddhaPUID = buildingPUID;
               debugCore("Wonder I built: " + kbGetProtoUnitName(gGreatBuddhaPUID));
               break;
            }
            case cUnitTypeypWJGoldenPavillion2:
            case cUnitTypeypWJGoldenPavillion3:
            case cUnitTypeypWJGoldenPavillion4:
            case cUnitTypeypWJGoldenPavillion5:
            {
               gGoldenPavilionPUID = buildingPUID;
               // The default tactic of the Golden Pavilion is good otherwise (ranged damage).
               /*if (cDifficultyCurrent < gDifficultyExpert)
               {
                  int goldenPavilionID = getUnit(gGoldenPavilionPUID, cMyID, cUnitStateAlive);
                  // It's nearly impossible that this fails of course.
                  if (goldenPavilionID >= 0)
                  {
                     aiUnitSetTactic(goldenPavilionID, cTacticUnitHitpoints);
                  }
               }*/
               xsEnableRule("advancedArsenalUpgradeMonitor");
               debugCore("Wonder I built: " + kbGetProtoUnitName(gGoldenPavilionPUID));
               break;
            }
            case cUnitTypeypWJShogunate2:
            case cUnitTypeypWJShogunate3:
            case cUnitTypeypWJShogunate4:
            case cUnitTypeypWJShogunate5:
            {
               gTheShogunatePUID = buildingPUID;
               xsEnableRule("daimyoMonitor");
               debugCore("Wonder I built: " + kbGetProtoUnitName(gTheShogunatePUID));
               break;
            }
            case cUnitTypeypWJToriiGates2:
            case cUnitTypeypWJToriiGates3:
            case cUnitTypeypWJToriiGates4:
            case cUnitTypeypWJToriiGates5:
            {
               gToriiGatesPUID = buildingPUID;
               debugCore("Wonder I built: " + kbGetProtoUnitName(gToriiGatesPUID));
               break;
            }
            case cUnitTypeypWJToshoguShrine2:
            case cUnitTypeypWJToshoguShrine3:
            case cUnitTypeypWJToshoguShrine4:
            case cUnitTypeypWJToshoguShrine5:
            {
               gToshoguShrinePUID = buildingPUID;
               debugCore("Wonder I built: " + kbGetProtoUnitName(gToshoguShrinePUID));
               break;
            }
            }
         }
      }

      gAgeUpResearchPlan = -1;
   }
   else if (civIsAsian() == true)
   {
      buildingPUID = aiPlanGetVariableInt(planID, cBuildPlanBuildingTypeID, 0);
      debugCore("What we are planning to construct this Wonder : " + kbGetProtoUnitName(buildingPUID));
   }

   // Force an update of resource distribution to prepare for stuffs after aging up.
   if (cDifficultyCurrent <= cDifficultyHard)
   {
      return;
   }
   if (state == cPlanStateResearch || state == cPlanStateBuild)
   {
      if (xsIsRuleEnabled("ageTransitionManager") == false)
      {
         xsEnableRule("ageTransitionManager");
         ageTransitionManager();
      }
   }
}

//==============================================================================
// updateChosenAfricanAlliances
//==============================================================================
void updateChosenAfricanAlliances()
{
   switch (kbGetAge())
   {
   case cAge2:
   {
      if (cMyCiv == cCivDEHausa)
      {
         if (kbTechGetStatus(cTechDEAllegianceBerber2) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAllianceBerbersIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceBerbersIndex, false);
         }
         else if (kbTechGetStatus(cTechDEAllegianceHausa2) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAllianceHausaIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceHausaIndex, false);
         }
         else if (kbTechGetStatus(cTechDEAllegianceSonghai2) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAllianceSonghaiIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceSonghaiIndex, false);
         }
         break;
      }
      else
      {
         if (kbTechGetStatus(cTechDEAllegianceSomali2) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAllianceSomalisIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceSomalisIndex, false);
         }
         else if (kbTechGetStatus(cTechDEAllegiancePortuguese2) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAlliancePortugueseIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAlliancePortugueseIndex, false);
            xsEnableRule("arsenalUpgradeMonitor");
         }
         else if (kbTechGetStatus(cTechDEAllegianceSudanese2) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAllianceSudaneseIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceSudaneseIndex, false);
         }
         break;
      }
   }
   case cAge3:
   {
      if (cMyCiv == cCivDEHausa)
      {
         if (kbTechGetStatus(cTechDEAllegianceBerber3) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAllianceBerbersIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceBerbersIndex, false);
         }
         else if (kbTechGetStatus(cTechDEAllegianceHausa3) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAllianceHausaIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceHausaIndex, false);
         }
         else if (kbTechGetStatus(cTechDEAllegianceSonghai3) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAllianceSonghaiIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceSonghaiIndex, false);
         }
         else if (kbTechGetStatus(cTechDEAllegianceAkan3) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAllianceAkanIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceAkanIndex, false);
         }
         break;
      }
      else
      {
         if (kbTechGetStatus(cTechDEAllegianceSomali3) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAllianceSomalisIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceSomalisIndex, false);
         }
         else if (kbTechGetStatus(cTechDEAllegiancePortuguese3) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAlliancePortugueseIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAlliancePortugueseIndex, false);
            xsEnableRule("arsenalUpgradeMonitor");
         }
         else if (kbTechGetStatus(cTechDEAllegianceSudanese3) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAllianceSudaneseIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceSudaneseIndex, false);
         }
         else if (kbTechGetStatus(cTechDEAllegianceJesuit3) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAllianceJesuitIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceJesuitIndex, false);
            xsEnableRule("churchUpgradeMonitor");
         }
         break;
      }
   }
   case cAge4:
   {
      if (cMyCiv == cCivDEHausa)
      {
         if (kbTechGetStatus(cTechDEAllegianceBerber4) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAllianceBerbersIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceBerbersIndex, false);
         }
         else if (kbTechGetStatus(cTechDEAllegianceHausa4) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAllianceHausaIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceHausaIndex, false);
         }
         else if (kbTechGetStatus(cTechDEAllegianceSonghai4) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAllianceSonghaiIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceSonghaiIndex, false);
         }
         else if (kbTechGetStatus(cTechDEAllegianceAkan4) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAllianceAkanIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceAkanIndex, false);
         }
         break;
      }
      else
      {
         if (kbTechGetStatus(cTechDEAllegianceSomali4) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAllianceSomalisIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceSomalisIndex, false);
         }
         else if (kbTechGetStatus(cTechDEAllegiancePortuguese4) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAlliancePortugueseIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAlliancePortugueseIndex, false);
            xsEnableRule("arsenalUpgradeMonitor");
         }
         else if (kbTechGetStatus(cTechDEAllegianceSudanese4) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAllianceSudaneseIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceSudaneseIndex, false);
         }
         else if (kbTechGetStatus(cTechDEAllegianceJesuit4) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAllianceJesuitIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceJesuitIndex, false);
            xsEnableRule("churchUpgradeMonitor");
         }
         else if (kbTechGetStatus(cTechDEAllegianceOromo4) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAllianceOromoIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceOromoIndex, false);
         }
         break;
      }
   }
   case cAge5:
   {
      if (cMyCiv == cCivDEHausa)
      {
         if (kbTechGetStatus(cTechDEAllegianceBerber5) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAllianceBerbersIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceBerbersIndex, false);
         }
         else if (kbTechGetStatus(cTechDEAllegianceHausa5) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAllianceHausaIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceHausaIndex, false);
         }
         else if (kbTechGetStatus(cTechDEAllegianceSonghai5) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAllianceSonghaiIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceSonghaiIndex, false);
         }
         else if (kbTechGetStatus(cTechDEAllegianceAkan5) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAllianceAkanIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceAkanIndex, false);
         }
         else if (kbTechGetStatus(cTechDEAllegianceBritish5) == cTechStatusActive) // We don't get any upgrades from the British
                                                                                   // so don't set the bool to false.
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAllianceBritishIndex, true);
            xsEnableRule("arsenalUpgradeMonitor");
         }
         break;
      }
      else if (cMyCiv == cCivDEEthiopians)
      {
         if (kbTechGetStatus(cTechDEAllegianceSomali5) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAllianceSomalisIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceSomalisIndex, false);
         }
         else if (kbTechGetStatus(cTechDEAllegiancePortuguese5) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAlliancePortugueseIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAlliancePortugueseIndex, false);
            xsEnableRule("arsenalUpgradeMonitor");
         }
         else if (kbTechGetStatus(cTechDEAllegianceSudanese5) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAllianceSudaneseIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceSudaneseIndex, false);
         }
         else if (kbTechGetStatus(cTechDEAllegianceJesuit5) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAllianceJesuitIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceJesuitIndex, false);
            xsEnableRule("churchUpgradeMonitor");
         }
         else if (kbTechGetStatus(cTechDEAllegianceOromo5) == cTechStatusActive)
         {
            xsArraySetBool(gAfricanAlliancesAgedUpWith, cAllianceOromoIndex, true);
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceOromoIndex, false);
         }
         break;
      }
   }
   }
}

//==============================================================================
// rule age2Monitor
/*
   Watch for us reaching age 2.
*/
//==============================================================================
rule age2Monitor
inactive
group tcComplete
minInterval 5
{
   if (kbGetAge() >= cAge2) // We're in age 2
   {
      debugCore("");
      debugCore("*** We're in age 2!!!");
      gAgeUpTime = xsGetTime();
      gAgeUpPlanTime = 0;

      // These numbers belonged to the now deprecated eco system
      // They're just used by other eco plans not being the main gathering.
      kbSetTargetSelectorFactor(cTSFactorDistance, -40.0);
      kbSetTargetSelectorFactor(cTSFactorPoint, 10.0);
      kbSetTargetSelectorFactor(cTSFactorTimeToDone, 0.0);
      kbSetTargetSelectorFactor(cTSFactorBase, 100.0);
      kbSetTargetSelectorFactor(cTSFactorDanger, -40.0);
      
      updateSettlersAndPopManager();
      updateWantedTowers();

      if ((xsIsRuleEnabled("militaryManager") == false) &&
          (cvOkToTrainArmy == true))
      {
         xsEnableRule("militaryManager");
         xsEnableRule("accountForOutlawsMilitaryPop");
         militaryManager(); // Call instantly to get started.
      }
      
      if (xsIsRuleEnabled("navyManager") == false)
      {
         xsEnableRule("navyManager");
      }
      
      if (cvOkToAttack == true)
      {
         if ((cDifficultyCurrent == cDifficultyEasy) &&
             (gDelayAttacks == true))
         {
            xsEnableRule("delayAttackMonitor"); // Wait until I am attacked or we've reached Age4, then let slip the hounds of war.
         }
         else if (cDifficultyCurrent != cDifficultySandbox) // We never attack on Easy.
         {
            xsEnableRule("mostHatedEnemy"); // Picks a target for us to attack.
            mostHatedEnemy(); // Instantly get a target so our managers have something to work with.
            xsEnableRule("attackManager"); // Land attacking / defending allies.
            xsEnableRule("waterAttackDefend"); // Water attacking / defending allies.
         }
      }
      
      if (gIslandMap == true)
      {
         xsEnableRule("transportMonitor");
      }
      
      setupNativeUpgrades();

      if (getGaiaUnitCount(cUnitTypeSocketCree) > 0)
         xsEnableRule("maintainCreeCoureurs");

      if (getGaiaUnitCount(cUnitTypedeSocketBerbers) > 0)
         xsEnableRule("maintainBerberNomads");

      if (civIsEuropean() == true)
      {
         xsEnableRule("ransomExplorer");
      }
      
      // Africans handle their native warriors inside of influenceManager.
      if ((civIsAfrican() == false) &&
          (cvOkToTrainArmy == true))
      {
         xsEnableRule("nativeMonitor");
      }

      if (gNumberTradeRoutes > 0)
      {
         xsEnableRule("tradeRouteUpgradeMonitor");
         if (cDifficultyCurrent >= cDifficultyEasy)
         {
            xsEnableRule("tradeRouteTacticMonitor");
         }
      }

      // Don't activate the big button monitors on easy(sandbox) since we won't have enough Villagers to pass the initial check.

      if ((cMyCiv == cCivXPAztec) && (cDifficultyCurrent >= cDifficultyEasy))
         xsEnableRule("bigButtonAztecMonitor");

      if ((cMyCiv == cCivXPSioux) && (cDifficultyCurrent >= cDifficultyEasy))
         xsEnableRule("bigButtonLakotaMonitor");

      if ((cMyCiv == cCivXPIroquois) && (cDifficultyCurrent >= cDifficultyEasy))
         xsEnableRule("bigButtonHaudenosauneeMonitor");

      xsEnableRule("settlerUpgradeMonitor");

      if (cMyCiv == cCivDESwedish)
      {
         xsEnableRule("arsenalUpgradeMonitor");
         xsEnableRule("advancedArsenalUpgradeMonitor");
      }
      if (civIsAsian() == true && cvOkToBuildConsulate == true)
      {
         xsEnableRule("consulateMonitor");
      }

      // Enable training units and researching techs with influence resource.
      if (civIsAfrican() == true)
      {
         if (cvOkToTrainArmy == true)
         {
            xsEnableRule("influenceManager");
         }
         xsEnableRule("allianceUpgradeMonitor");
         updateChosenAfricanAlliances();
      }

      // Allow Abuns to gather from Mountain Monasteries and switch the MM tactic to 50% Influence/Coin.
      if (cMyCiv == cCivDEEthiopians)
      {
         aiAddGathererType(cUnitTypedeAbun);
         xsEnableRule("setMountainMonasteryTactic");
      }

      if (cDifficultyCurrent >= gDifficultyExpert)
      {
         // Avoid planning for age upgrades until 10 minutes passed after aging up.
         if (btRushBoom > 0.0 && kbGetAge() == cAge2)
            gAgeUpPlanTime = xsGetTime() + 10 * 60 * 1000;
      }

      if (gLastAttackMissionTime < 0)
         gLastAttackMissionTime = xsGetTime() -
                                  180000; // Pretend they all fired 3 minutes ago, even if that's a negative number.
      if (gLastDefendMissionTime < 0)
         gLastDefendMissionTime = xsGetTime() -
                                  300000; // Actually, start defense ratings at 100% charge, i.e. 5 minutes since last one.

      // Use Caravels to fish.
      aiAddGathererType(cUnitTypeAbstractFishingBoat);
      updateResourceDistribution(true);
      setUnitPickerPreference(gLandUnitPicker);
      findEnemyBase(); // Create a one-off explore plan to probe the likely enemy base location.

      if (cvOkToFortify == true)
      {
         xsEnableRule("towerManager");
      }
      
      xsEnableRule("rescueExplorer");
      xsEnableRule("islandExploreMonitor");
      xsEnableRule("settlerUpgradeMonitor");
      xsEnableRule("healerMonitor");
      xsEnableRule("age3Monitor");
	  
	  if (civIsAfrican() != true)
      xsEnableRule("siegeWeaponMonitor");
	  if (cMyCiv == cCivDEAmericans)
	xsEnableRule("churchUpgradeMonitorAmerican");  
      xsEnableRule("minorTribeTechMonitor");
      xsEnableRule("minorAsianTribeTechMonitor");
      // Enable summer palace tactic monitor for Chinese
      if (cMyCiv == cCivChinese)
         xsEnableRule("summerPalaceTacticMonitor");
      // Enable dojo tactic monitor for Japanese
      if (cMyCiv == cCivJapanese)
         xsEnableRule("dojoTacticMonitor");
      // Enable unique church upgrades
      if (civIsEuropean() == true)
         xsEnableRule("royalDecreeMonitor");
      // Enable mansabdar maintain plans for Indians
      if (cMyCiv == cCivIndians)
         xsEnableRule("mansabdarMonitor");
      // Enable daimyo maintain plans for Japanese
      if (cMyCiv == cCivJapanese)
         xsEnableRule("daimyoMonitor");
	 
      xsDisableSelf();
      debugCore("*** End of age2Monitor rule");
      debugCore("");
   }
}

//==============================================================================
// rule age3Monitor
/*
   Watch for us reaching age 3.
*/
//==============================================================================
rule age3Monitor
inactive
minInterval 10
{
   if (kbGetAge() >= cAge3)
   {
      debugCore("");
      debugCore("*** We're in age 3!!!");
      gAgeUpTime = xsGetTime();
      gAgeUpPlanTime = 0;

      updateSettlersAndPopManager();
      updateWantedTowers();

      if (cMyCiv == cCivOttomans)
      {
         // It only makes sense to keep this spawning tracker enabled if we're not allowed to reach the build limit of our
         // gEconUnit.
         int comparisonDifficulty = gSPC == true ? cDifficultyExpert : cDifficultyHard;
         if ((cDifficultyCurrent >= comparisonDifficulty) && (cvMaxCivPop == -1))
         {
            debugCore(
                "DISABLING Rule: 'toggleAutomaticSettlerSpawning' because we're allowed to reach the build limit of gEconUnit");
            xsDisableRule("toggleAutomaticSettlerSpawning");
         }
      }

      // Enable the Tower upgrade monitor for everybody apart from Lakota, they only use the War Hut monitor.
      if (cMyCiv != cCivXPSioux)
      {
         xsEnableRule("towerUpgradeMonitor");
      }

      // Enable the rule to upgrade the War Huts, this is done separately from the other Towers.
      if ((cMyCiv == cCivXPSioux) || (cMyCiv == cCivXPAztec))
      {
         xsEnableRule("warHutUpgradeMonitor");
      }

      // Switch from war hut to nobles hut.
      if (cMyCiv == cCivXPAztec)
         gTowerUnit = cUnitTypeNoblesHut;

      if (cMyCiv == cCivDEInca)
      {
         // The Stronghold can be considered as both a Tower and a Fort, if we're allowed to make one enable it.
         if ((cvOkToBuildForts == true) || (cvOkToFortify == true)) 
         {
            xsEnableRule("strongholdConstructionMonitor");
         }
         xsEnableRule("strongholdUpgradeMonitor");
         if (cDifficultyCurrent >= cDifficultyEasy)
         {
            xsEnableRule("bigButtonIncaMonitor");
            xsEnableRule("KanchaTacticMonitor");
         }
      }

      // Enable Arsenal upgrades for Europeans and Japanese (Dutch Consulate Arsenal).
      if ((civIsEuropean() == true) ||
          ((cMyCiv == cCivJapanese) || (cMyCiv == cCivSPCJapanese) || (cMyCiv == cCivSPCJapaneseEnemy)))
      {
         xsEnableRule("arsenalUpgradeMonitor");
      }
      
      if ((civIsEuropean() == true) || (cMyCiv == cCivChinese) || (cMyCiv == cCivDEInca) 
		  || (cMyCiv == cCivDEMexicans) || (cMyCiv == cCivDEAmericans))
      {
         if ((cvOkToBuild == true) && 
             (cvOkToBuildForts == true) &&
             (cDifficultyCurrent >= cDifficultyModerate))
         {
            xsEnableRule("forwardBaseManager");
         }
      }

      // Enable the baseline Church (Cathedral) upgrade monitor.
      if (cMyCiv == cCivDEMexicans)
      {
         xsEnableRule("churchUpgradeMonitor");
      }

      // Enable Monastery upgrades.
      if (civIsAsian() == true)
      {
         xsEnableRule("monasteryUpgradeMonitor");
      }

      // Enable navy upgrades
      xsEnableRule("navyUpgradeMonitor");

      if (civIsAfrican() == true)
      {
         updateChosenAfricanAlliances();
      }

      xsEnableRule("age4Monitor");
      xsDisableSelf();
      debugCore("*** End of age3Monitor rule");
      debugCore("");
   }
}

//==============================================================================
// rule age4Monitor
/*
   Watch for us reaching age 4.
*/
//==============================================================================
rule age4Monitor
inactive
minInterval 10
{
   if (kbGetAge() >= cAge4)
   {
      debugCore("");
      debugCore("*** We're in age 4!!!");
      gAgeUpTime = xsGetTime();
      gAgeUpPlanTime = 0;

      updateSettlersAndPopManager();
      updateWantedTowers();

      // Enable the baseline Church upgrade monitor.
      if ((civIsEuropean() == true) && (cMyCiv != cCivDEMexicans))
      {
         xsEnableRule("churchUpgradeMonitor");
      }
      
      if (cvOkToExplore == true)
      {
         xsEnableRule("balloonMonitor");
      }
      
      // Enable sacred field handling for Indians
      if (cMyCiv == cCivIndians)
      {
         xsEnableRule("sacredFieldMonitor");
      }

      if (cMyCiv == cCivDEInca)
      {
         xsEnableRule("tamboUpgradeMonitor");
      }

      if (cDifficultyCurrent >= cDifficultyModerate)
      { 
         // Enable shrine upgrade for Japanese.
         if ((cMyCiv == cCivJapanese) || (cMyCiv == cCivSPCJapanese) || (cMyCiv == cCivSPCJapaneseEnemy))
         {
            xsEnableRule("shrineUpgradeMonitor");
         }
      }

      if (civIsAfrican() == true)
      {
         updateChosenAfricanAlliances();
      }
	  
	  
	  if ((civIsEuropean() == true) || (cMyCiv == cCivDEMexicans) || (cMyCiv == cCivDEAmericans))
		{
			gAbstractArtilleryUnit = cUnitTypexpHorseArtillery;
		}
		
	  //xsEnableRule("delayWalls");

      xsEnableRule("age5Monitor");
      xsDisableSelf();
      debugCore("*** End of age4Monitor rule");
      debugCore("");
   }
}

//==============================================================================
// rule age5Monitor
/*
   Watch for us reaching age 5.
*/
//==============================================================================
rule age5Monitor
inactive
minInterval 10
{
   if (kbGetAge() >= cAge5)
   {
      debugCore("");
      debugCore("*** We're in age 5!!!");
      gAgeUpTime = xsGetTime();
      gAgeUpPlanTime = 0;

      updateSettlersAndPopManager();
      updateWantedTowers();

      if (civIsEuropean() == true)
      {
         xsEnableRule("capitolConstructionMonitor");
      }

      if (civIsAfrican() == true)
      {
         updateChosenAfricanAlliances();
      }
	  
	     if (gSPC == false)
		{
      xsEnableRule("autoFeedLowestAlly");
		}
      gAgeUpPriority = 0;

      xsDisableSelf();
      debugCore("*** End of age5Monitor rule");
      debugCore("");
   }
}

//==============================================================================
/* BHG regicide monitor

   Pop the regent in the castle

*/
//==============================================================================
rule regicideMonitor
inactive
minInterval 10
{
   // if the castle is up, put the guy in it

   if (kbUnitCount(cMyID, cUnitTypeypCastleRegicide, cUnitStateAlive) > 0)
   {
      // gotta find the castle
      static int castleQueryID = -1;
      // If we don't have the query yet, create one.
      if (castleQueryID < 0)
      {
         castleQueryID = kbUnitQueryCreate("castleGetUnitQuery");
         kbUnitQuerySetIgnoreKnockedOutUnits(castleQueryID, true);
      }
      // Define a query to get all matching units
      if (castleQueryID != -1)
      {
         kbUnitQuerySetPlayerRelation(castleQueryID, -1);
         kbUnitQuerySetPlayerID(castleQueryID, cMyID);
         kbUnitQuerySetUnitType(castleQueryID, cUnitTypeypCastleRegicide);
         kbUnitQuerySetState(castleQueryID, cUnitStateAlive);
      }
      else
      {
         return;
      }

      // gotta find the regent
      static int regentQueryID = -1;
      // If we don't have the query yet, create one.
      if (regentQueryID < 0)
      {
         regentQueryID = kbUnitQueryCreate("regentGetUnitQuery");
         kbUnitQuerySetIgnoreKnockedOutUnits(regentQueryID, true);
      }
      // Define a query to get all matching units
      if (regentQueryID != -1)
      {
         kbUnitQuerySetPlayerRelation(regentQueryID, -1);
         kbUnitQuerySetPlayerID(regentQueryID, cMyID);
         kbUnitQuerySetUnitType(regentQueryID, cUnitTypeypDaimyoRegicide);
         kbUnitQuerySetState(regentQueryID, cUnitStateAlive);
      }
      else
      {
         return;
      }

      kbUnitQueryResetResults(castleQueryID);
      kbUnitQueryResetResults(regentQueryID);

      kbUnitQueryExecute(castleQueryID);
      kbUnitQueryExecute(regentQueryID);

      int index = 0;

      aiTaskUnitWork(kbUnitQueryGetResult(regentQueryID, index), kbUnitQueryGetResult(castleQueryID, index));
   }
   else
   {
      xsDisableSelf();
   }
}

rule brigadeMonitors
inactive
mininterval 10
{
   // Quit if there is no consulate
   if (kbUnitCount(cMyID, cUnitTypeypConsulate, cUnitStateAlive) < 1)
   {
      return;
   }
   // Research brigade technologies
   // Unavailable ones are simply ignored
   int brigadePlanID = -1;
   // British brigade
   if (kbTechGetStatus(cTechypConsulateBritishBrigade) == cTechStatusObtainable)
   {
      brigadePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechypConsulateBritishBrigade);
      if (brigadePlanID >= 0)
         aiPlanDestroy(brigadePlanID);
      createSimpleResearchPlan(cTechypConsulateBritishBrigade, getUnit(cUnitTypeypConsulate), cMilitaryEscrowID, 50);
      return;
   }
   // Dutch brigade
   if (kbTechGetStatus(cTechypConsulateDutchBrigade) == cTechStatusObtainable)
   {
      brigadePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechypConsulateDutchBrigade);
      if (brigadePlanID >= 0)
         aiPlanDestroy(brigadePlanID);
      createSimpleResearchPlan(cTechypConsulateDutchBrigade, getUnit(cUnitTypeypConsulate), cMilitaryEscrowID, 50);
      return;
   }
   // French brigade
   if (kbTechGetStatus(cTechypConsulateFrenchBrigade) == cTechStatusObtainable)
   {
      brigadePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechypConsulateFrenchBrigade);
      if (brigadePlanID >= 0)
         aiPlanDestroy(brigadePlanID);
      createSimpleResearchPlan(cTechypConsulateFrenchBrigade, getUnit(cUnitTypeypConsulate), cMilitaryEscrowID, 50);
      return;
   }
   // German brigade
   if (kbTechGetStatus(cTechypConsulateGermansBrigade) == cTechStatusObtainable)
   {
      brigadePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechypConsulateGermansBrigade);
      if (brigadePlanID >= 0)
         aiPlanDestroy(brigadePlanID);
      createSimpleResearchPlan(cTechypConsulateGermansBrigade, getUnit(cUnitTypeypConsulate), cMilitaryEscrowID, 50);
      return;
   }
   // Ottoman brigade
   if (kbTechGetStatus(cTechypConsulateOttomansBrigade) == cTechStatusObtainable)
   {
      brigadePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechypConsulateOttomansBrigade);
      if (brigadePlanID >= 0)
         aiPlanDestroy(brigadePlanID);
      createSimpleResearchPlan(cTechypConsulateOttomansBrigade, getUnit(cUnitTypeypConsulate), cMilitaryEscrowID, 50);
      return;
   }
   // Portuguese brigade
   if (kbTechGetStatus(cTechypConsulatePortugueseBrigade) == cTechStatusObtainable)
   {
      brigadePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechypConsulatePortugueseBrigade);
      if (brigadePlanID >= 0)
         aiPlanDestroy(brigadePlanID);
      createSimpleResearchPlan(cTechypConsulatePortugueseBrigade, getUnit(cUnitTypeypConsulate), cMilitaryEscrowID, 50);
      return;
   }
   // Russian brigade
   if (kbTechGetStatus(cTechypConsulateRussianBrigade) == cTechStatusObtainable)
   {
      brigadePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechypConsulateRussianBrigade);
      if (brigadePlanID >= 0)
         aiPlanDestroy(brigadePlanID);
      createSimpleResearchPlan(cTechypConsulateRussianBrigade, getUnit(cUnitTypeypConsulate), cMilitaryEscrowID, 50);
      return;
   }
   // Spanish brigade
   if (kbTechGetStatus(cTechypConsulateSpanishBrigade) == cTechStatusObtainable)
   {
      brigadePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechypConsulateSpanishBrigade);
      if (brigadePlanID >= 0)
         aiPlanDestroy(brigadePlanID);
      createSimpleResearchPlan(cTechypConsulateSpanishBrigade, getUnit(cUnitTypeypConsulate), cMilitaryEscrowID, 50);
      return;
   }
}
rule capitolUpgradeMonitor
inactive
minInterval 40
{
   int upgradePlanID = -1;
   // Disable rule for native or Asian civs
   if (civIsEuropean() == false)
   {
      xsDisableSelf();
      return;
   }
   // Disable rule once all upgrades are available
   if ((kbTechGetStatus(cTechImpKnighthood) == cTechStatusActive) &&
       (kbTechGetStatus(cTechImpPeerage) == cTechStatusActive) &&
       (kbTechGetStatus(cTechImpLargeScaleAgriculture) == cTechStatusActive) &&
       (kbTechGetStatus(cTechImpDeforestation) == cTechStatusActive) &&
       (kbTechGetStatus(cTechImpExcessiveTaxation) == cTechStatusActive) &&
       (kbTechGetStatus(cTechImpImmigrants) == cTechStatusActive) &&
       (kbTechGetStatus(cTechImpLegendaryNatives) == cTechStatusActive))
   {
      xsDisableSelf();
      return;
   }
   // Get upgrades one at a time as they become available
   if (kbTechGetStatus(cTechImpKnighthood) == cTechStatusObtainable)
   {
      upgradePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechImpKnighthood);
      if (upgradePlanID >= 0)
         aiPlanDestroy(upgradePlanID);
      createSimpleResearchPlan(cTechImpKnighthood, getUnit(cUnitTypeCapitol), cMilitaryEscrowID, 50);
      return;
   }
   if (kbTechGetStatus(cTechImpPeerage) == cTechStatusObtainable)
   {
      upgradePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechImpPeerage);
      if (upgradePlanID >= 0)
         aiPlanDestroy(upgradePlanID);
      createSimpleResearchPlan(cTechImpPeerage, getUnit(cUnitTypeCapitol), cMilitaryEscrowID, 50);
      return;
   }
   if (kbTechGetStatus(cTechImpLargeScaleAgriculture) == cTechStatusObtainable)
   {
      upgradePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechImpLargeScaleAgriculture);
      if (upgradePlanID >= 0)
         aiPlanDestroy(upgradePlanID);
      createSimpleResearchPlan(cTechImpLargeScaleAgriculture, getUnit(cUnitTypeCapitol), cEconomyEscrowID, 50);
      return;
   }
   if (kbTechGetStatus(cTechImpDeforestation) == cTechStatusObtainable)
   {
      upgradePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechImpDeforestation);
      if (upgradePlanID >= 0)
         aiPlanDestroy(upgradePlanID);
      createSimpleResearchPlan(cTechImpDeforestation, getUnit(cUnitTypeCapitol), cEconomyEscrowID, 50);
      return;
   }
   if (kbTechGetStatus(cTechImpExcessiveTaxation) == cTechStatusObtainable)
   {
      upgradePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechImpExcessiveTaxation);
      if (upgradePlanID >= 0)
         aiPlanDestroy(upgradePlanID);
      createSimpleResearchPlan(cTechImpExcessiveTaxation, getUnit(cUnitTypeCapitol), cEconomyEscrowID, 50);
      return;
   }
   if (kbTechGetStatus(cTechImpImmigrants) == cTechStatusObtainable)
   {
      upgradePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechImpImmigrants);
      if (upgradePlanID >= 0)
         aiPlanDestroy(upgradePlanID);
      createSimpleResearchPlan(cTechImpImmigrants, getUnit(cUnitTypeCapitol), cEconomyEscrowID, 50);
      return;
   }
   if (kbTechGetStatus(cTechImpLegendaryNatives) == cTechStatusObtainable)
   {
      upgradePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechImpLegendaryNatives);
      if (upgradePlanID >= 0)
         aiPlanDestroy(upgradePlanID);
      createSimpleResearchPlan(cTechImpLegendaryNatives, getUnit(cUnitTypeCapitol), cMilitaryEscrowID, 50);
      return;
   }
}
rule autoFeedLowestAlly
inactive
mininterval 10
{  
	float goldAmount = 0.0;
	float woodAmount = 0.0;
	float foodAmount = 0.0;
	goldAmount = kbResourceGet(cResourceGold);
	woodAmount = kbResourceGet(cResourceWood);
	foodAmount = kbResourceGet(cResourceFood);
   //int lowestAgeAlly = cAge5;
   int totalScoreAlly = 0;
   int averageScoreAlly = 0;
   int player = 1;
   for (player=0; < cNumberPlayers)
   {
      if (kbIsPlayerAlly(player) == true)
      {
	 totalScoreAlly = totalScoreAlly + aiGetScore(player);
	 //if (kbGetAgeForPlayer(player) < lowestAgeAlly)
	  //lowestAgeAlly = kbGetAgeForPlayer(player); 
      }
   }
   averageScoreAlly = totalScoreAlly / (getAllyCount() + 1);
for (player=0; < cNumberPlayers)
   {
      if (player == cMyID)
	continue;      
      if (kbIsPlayerAlly(player) == true)
      {
         //if ((kbGetPopCap() - kbGetPop() < 20) && 
           if ((aiGetScore(player) < averageScoreAlly * 0.8) && 
              (kbHasPlayerLost(player) == false) ) 
	 {
            if (goldAmount > 12000)
            {
           aiTribute(player, cResourceFood, 4000);
               //sendStatement(cPlayerRelationAlly, cAICommPromptToAllyITributedFood);
            }
            if (woodAmount > 12000)
            {
	       aiTribute(player, cResourceWood, 4000);
               //sendStatement(cPlayerRelationAlly, cAICommPromptToAllyITributedWood);
            }
            if (goldAmount > 12000)
            {
	       aiTribute(player, cResourceGold, 4000);
               //sendStatement(cPlayerRelationAlly, cAICommPromptToAllyITributedCoin);
            }
	 }
      }
   }
} 
rule ShrineGoatMonitor						   
inactive
minInterval 15
{
   static int cowPlan = -1;
   int numHerdables = 0;
   int numCows = 0;
   // Quit if there is no sacred field around or we're in age1 without excess food
   if (kbResourceGet(cResourceFood) < 4000)
   {
      return;
   }
   // Check number of captured herdables, add sacred cows as necessary to bring total number to 10
   numHerdables = kbUnitCount(cMyID, cUnitTypeypGoat, cUnitStateAlive);
   numCows = (30 - numHerdables);
   if (numCows > 0)
   {
      // Create/update maintain plan
      if (cowPlan < 0)
      {
         cowPlan = createSimpleMaintainPlan(cUnitTypeypGoat, numCows, true, kbBaseGetMainID(cMyID), 1);
      }
      else
      {
         aiPlanSetVariableInt(cowPlan, cTrainPlanNumberToMaintain, 0, numCows);
      }
   }
}

bool agingUpTo(int nextAge = -1)
{
   bool retVal = false;
   if ((kbGetAge() + 1 == nextAge) && ((aiPlanGetState(gAgeUpResearchPlan) == cPlanStateResearch) || (aiPlanGetState(gAgeUpResearchPlan) == cPlanStateBuild)))
      retVal = true;
   return(retVal);
}

bool agingUpToOrAbove(int Age = -1)
{
   bool retVal = false;
   if ((kbGetAge() == Age - 1) && ((aiPlanGetState(gAgeUpResearchPlan) == cPlanStateResearch) || (aiPlanGetState(gAgeUpResearchPlan) == cPlanStateBuild)))
      retVal = true;
   if (kbGetAge() >= Age)
      retVal = true;
   return(retVal);
}

void sendChatToAllies(string text = "")
{
   int player = -1;
   for (player = 0; < cNumberPlayers)
   {
      if ((player != cMyID) && (kbIsPlayerAlly(player) == true))
         aiChat(player, text);
   }
}

rule sendChatToMyAllies
inactive
group tcComplete
mininterval 10
{
	if (gSPC == true)
	{
	xsDisableSelf();
	return;
	}
    static bool agingUpTo2ChatSent = false;
    static bool agingUpTo3ChatSent = false;
    static bool agingUpTo4ChatSent = false;
    static bool agingUpTo5ChatSent = false;
    if (agingUpTo2ChatSent == false)
    {
       if (agingUpTo(cAge2) == true)
       {
	   sendChatToAllies("Aging up to Colonial soon");          
	   econMaster();
	   xsEnableRule("age2Monitor");
	   agingUpTo2ChatSent = true;
       }       
    }
    if (agingUpTo3ChatSent == false)
    {
       if (agingUpTo(cAge3) == true)
       { 
	  sendChatToAllies("Aging up to Fortress soon");        
	  econMaster();
	  xsEnableRule("age3Monitor");
	  agingUpTo3ChatSent = true;
       }
     }
     if (agingUpTo4ChatSent == false)
     {
	if (agingUpTo(cAge4) == true) 
	{
	   sendChatToAllies("Aging up to Industrial soon");
	   econMaster();
	   xsEnableRule("age4Monitor");
	   agingUpTo4ChatSent = true;
	}
     }
     if (agingUpTo5ChatSent == false)
     {
	if (agingUpTo(cAge5) == true)
	{ 
	   sendChatToAllies("Aging up to Imperial soon");
	   econMaster();           
	   xsEnableRule("age5Monitor");
	   agingUpTo5ChatSent = true;
	}
    }
    static bool strategyChatSent = false;
    if (strategyChatSent == false)
    {
       if (xsGetTime() > 10000)
       {
	  strategyChatSent = true;
	  if (kbGetAge() >= cAge1)
	  {
	     if (gInitialStrategy == 0)
		sendChatToAllies("Target Strategy: FI");
	     if (gInitialStrategy == 1)
		sendChatToAllies("Target Strategy: Rush");
             if (gInitialStrategy == 2)	
                sendChatToAllies("Target Strategy: FF");
             if (gInitialStrategy == 3)
                sendChatToAllies("Target Strategy: Turtle");
          }
       }
    }
    static int lastTribSentTime = 0;
	/*
	int age = kbGetAge();
	if (age == cvMaxAge)
       xsDisableSelf();
       return;
    /////////Tell allies your military combination/////////
    int gLandUnit = kbUnitPickGetResult(gLandUnitPicker, 0);
    string namePrimary = kbGetUnitTypeName(gLandUnit);
    if (kbUnitPickGetResult(gLandUnitPicker, 0) < 1)
    namePrimary = kbGetUnitTypeName(gLandPrimaryArmyUnit);		
       if ( ((xsGetTime() - lastTribSentTime) > 240000) && (kbUnitCount(cMyID, cUnitTypeLogicalTypeLandMilitary, cUnitStateAlive) > 1) && (gSPC == false) && (xsGetTime() > 5*60*1000) && (kbUnitPickGetResult(gLandUnitPicker, 0) < 1))
       {
          sendChatToAllies("Primary Army Unit: "+namePrimary+"");
          lastTribSentTime = xsGetTime();
       }
	   */
    /////////////////////////////////////////////////////////
}