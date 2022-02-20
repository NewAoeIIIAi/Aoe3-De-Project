//==============================================================================
/* aiEconomy.xs

   This file is intended for economy related stuffs, such as gatherer
   management and resource building construction.

*/
//==============================================================================

//==============================================================================
// getNumberPlanGatherers
//==============================================================================
int getNumberPlanGatherers(int resource = cResourceGold, int subType = cAIResourceSubTypeEasy)
{
   int numPlans = aiPlanGetActiveCount();
   int count = 0;

   for (i = 0; < numPlans)
   {
      int planID = aiPlanGetIDByActiveIndex(i);
      if (aiPlanGetType(planID) != cPlanGather)
         continue;
      if (aiPlanGetVariableInt(planID, cGatherPlanResourceType, 0) != resource ||
          aiPlanGetVariableInt(planID, cGatherPlanResourceSubType, 0) != subType)
         continue;
      count = count + aiPlanGetNumberWantedUnits(planID);
   }

   return (count);
}

rule crateMonitor
inactive
group tcComplete
minInterval 5
{
   static int cratePlanID = -1;
   int totalNumCrates = -1;
   int closeNumCrates = -1;
   int gatherersWanted = -1;
   int planPriority = 89;
   vector mainBaseVec = cInvalidVector;

   // If we have a main base, count the number of crates in it.
   if (kbBaseGetMainID(cMyID) < 0)
      return;

   // Count available crates.
   totalNumCrates = kbUnitCount(cMyID, cUnitTypeAbstractResourceCrate, cUnitStateAlive) +
                    kbUnitCount(0, cUnitTypeAbstractResourceCrate, cUnitStateAlive);

   mainBaseVec = kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID));
   // Focus on crates in our main base.
   if ((mainBaseVec != cInvalidVector) && (totalNumCrates >= 1))
      closeNumCrates = getUnitCountByLocation(cUnitTypeAbstractResourceCrate, cMyID, cUnitStateAlive, mainBaseVec, 20.0) +
                       getUnitCountByLocation(cUnitTypeAbstractResourceCrate, 0, cUnitStateAlive, mainBaseVec, 20.0);

   if (closeNumCrates <= 0)
   {
      gatherersWanted = 1; // One gatherer if the crates are not close to our base.
      planPriority = 84;   // Lower priority as well.
   }
   else
   {
      totalNumCrates = closeNumCrates;
      gatherersWanted = (totalNumCrates + 3) / 3; // One gatherer plus one for each three crates, capped at five.
      if (gatherersWanted > 5)
         gatherersWanted = 5;
   }

   if (totalNumCrates <= 0)
      gatherersWanted = 0;

   if (aiPlanGetState(cratePlanID) == -1)
   {
      debugEconomy("Crate gather plan " + cratePlanID + " is invalid.");
      aiPlanDestroy(cratePlanID);
      cratePlanID = -1;
   }

   if (cratePlanID < 0)
   { // Initialize the plan
      cratePlanID = aiPlanCreate("Main Base Crate", cPlanGather);
      aiPlanSetBaseID(cratePlanID, kbBaseGetMainID(cMyID));
      aiPlanSetVariableInt(cratePlanID, cGatherPlanResourceUnitTypeFilter, 0, cUnitTypeAbstractResourceCrate);
      aiPlanSetVariableInt(cratePlanID, cGatherPlanResourceType, 0, cAllResources);
      // aiPlanSetVariableInt(cratePlanID, cGatherPlanFindNewResourceTimeOut, 0, 20000);
      aiPlanAddUnitType(cratePlanID, gEconUnit, gatherersWanted, gatherersWanted, gatherersWanted);
      aiPlanSetDesiredPriority(cratePlanID, planPriority);
      aiPlanSetActive(cratePlanID);
      debugEconomy("Activated crate gather plan " + cratePlanID);
   }

   if (cMyCiv != cCivGermans)
   {
      aiPlanAddUnitType(cratePlanID, gEconUnit, gatherersWanted, gatherersWanted, gatherersWanted);
   }
   else
   {
      if (kbUnitCount(cMyID, gEconUnit, cUnitStateAlive) > 0)
      {
         aiPlanAddUnitType(cratePlanID, gEconUnit, gatherersWanted, gatherersWanted, gatherersWanted);
         aiPlanAddUnitType(cratePlanID, cUnitTypeSettlerWagon, 0, 0, 0);
      }
      else
      {
         aiPlanAddUnitType(cratePlanID, gEconUnit, 0, 0, 0);
         aiPlanAddUnitType(
             cratePlanID,
             cUnitTypeSettlerWagon,
             (gatherersWanted + 1) / 2,
             (gatherersWanted + 1) / 2,
             (gatherersWanted + 1) / 2);
      }
   }
}

float getCorrectedResourcePercentage(int resource = cResourceFood)
{
   // Restore resource percentage with wood when we disabled wood gathering.
   if (gDisableWoods == true)
   {
      float percentOnGold = aiGetResourcePercentage(cResourceGold);
      float percentOnWood = percentOnGold * gGoldPercentageToBuyForWood / aiGetMarketBuyCost(cResourceWood) * 100.0;
      float percentOnFood = aiGetResourcePercentage(cResourceFood);

      percentOnGold = percentOnGold * (1.0 - gGoldPercentageToBuyForWood);

      float percentOnResource = 0.0;
      float total = percentOnGold + percentOnWood + percentOnFood;

      if (resource == cResourceGold)
         percentOnResource = percentOnGold / total;
      else if (resource == cResourceWood)
         percentOnResource = percentOnWood / total;
      else
         percentOnResource = percentOnFood / total;

      return (percentOnResource);
   }

   return (aiGetResourcePercentage(resource));
}

float getValidResourceAmount(int resource = cResourceFood, float maxDistance = 80.0, bool searchAllAreaGroups = false)
{
   int mainBaseID = kbBaseGetMainID(cMyID);

   if (mainBaseID < 0)
      return (0.0);

   //int numGatherers = kbUnitCount(cMyID, gEconUnit, cUnitStateAlive) +
   //                   kbUnitCount(cMyID, cUnitTypeSettlerWagon, cUnitStateAlive);
   int numberBases = kbBaseGetNumber(cMyID);
   int baseID = -1;
   int resourceAmount = 0;
   //float percentOnResource = getCorrectedResourcePercentage(resource);
   //int numResourceGatherers = percentOnResource * numGatherers;

   switch (resource)
   {
   case cResourceFood:
   {
      static int startingHuntAmount = -1;
      if (startingHuntAmount < 0)
      {
         if ((cMyCiv != cCivJapanese) && (cMyCiv != cCivSPCJapanese) && (cMyCiv != cCivSPCJapaneseEnemy))
         {
            startingHuntAmount = kbGetAmountValidResources(
                mainBaseID, cResourceFood, cAIResourceSubTypeHunt, maxDistance, searchAllAreaGroups);
         }
         else
         {
            startingHuntAmount = 0;
         }
      }

      for (i = 0; < numberBases)
      {
         baseID = kbBaseGetIDByIndex(cMyID, i);
         if (kbBaseGetSettlement(cMyID, baseID) == false)
            continue;
         if ((cMyCiv != cCivJapanese) && (cMyCiv != cCivSPCJapanese) && (cMyCiv != cCivSPCJapaneseEnemy))
            resourceAmount = resourceAmount +
                             kbGetAmountValidResources(
                                 baseID, cResourceFood, cAIResourceSubTypeHunt, maxDistance, searchAllAreaGroups);
         // dont count fruits unless we're Japanese, they're too slow compared to huntables
         if (startingHuntAmount == 0 || gCountBerries == true)
            resourceAmount = resourceAmount +
                             kbGetAmountValidResources(
                                 baseID, cResourceFood, cAIResourceSubTypeEasy, maxDistance, searchAllAreaGroups);
      }

      /*if (civIsAsian() == true || civIsAfrican() == true)
         numFarms = gNumberFoodPaddies;
      else
         numFarms = kbUnitCount(cMyID, gFarmUnit, cUnitStateAlive);

      numResourceGatherers = numResourceGatherers - numFarms * cMaxSettlersPerFarm;*/
      break;
   }
   case cResourceWood:
   {
      for (i = 0; < numberBases)
      {
         baseID = kbBaseGetIDByIndex(cMyID, i);
         if (kbBaseGetSettlement(cMyID, baseID) == false)
            continue;
         resourceAmount = resourceAmount + kbGetAmountValidResources(
                                               baseID, cResourceWood, cAIResourceSubTypeEasy, maxDistance, searchAllAreaGroups);
      }
      break;
   }
   case cResourceGold:
   {
      if (cMyCiv != cCivXPIroquois && cMyCiv != cCivXPSioux)
      {
         for (i = 0; < numberBases)
         {
            baseID = kbBaseGetIDByIndex(cMyID, i);
            if (kbBaseGetSettlement(cMyID, baseID) == false)
               continue;
            resourceAmount = resourceAmount +
                             kbGetAmountValidResources(
                                 baseID, cResourceGold, cAIResourceSubTypeEasy, maxDistance, searchAllAreaGroups);
         }
      }
      else
      {
         static int mineQuery = -1;
         vector location = cInvalidVector;
         int mineCount = 0;
         int mineID = -1;
         // For natives we just go through each mine and count total resources
         if (mineQuery < 0)
         {
            mineQuery = kbUnitQueryCreate("Mine query for resource check");
            kbUnitQuerySetPlayerID(mineQuery, 0);
            kbUnitQuerySetUnitType(mineQuery, cUnitTypeAbstractMine);
            kbUnitQuerySetAscendingSort(mineQuery, true); // Ascending distance from initial location
         }

         kbUnitQuerySetMaximumDistance(mineQuery, maxDistance);

         for (i = 0; < numberBases)
         {
            baseID = kbBaseGetIDByIndex(cMyID, i);
            if (kbBaseGetSettlement(cMyID, baseID) == false)
               continue;
            location = kbBaseGetLocation(cMyID, baseID);
            kbUnitQuerySetPosition(mineQuery, location);
            kbUnitQueryResetResults(mineQuery);
            mineCount = kbUnitQueryExecute(mineQuery);
            for (j = 0; < mineCount)
            {
               mineID = kbUnitQueryGetResult(mineQuery, j);
               if (searchAllAreaGroups == false)
               {
                  if (kbAreaGroupGetIDByPosition(kbUnitGetPosition(mineID)) !=
                      kbAreaGroupGetIDByPosition(kbBaseGetLocation(cMyID, mainBaseID)))
                     continue;
               }
               resourceAmount = resourceAmount + kbUnitGetResourceAmount(mineID, cResourceGold);
            }
         }
      }

      /*if (civIsAsian() == true || civIsAfrican() == true)
         numFarms = gNumberGoldPaddies;
      else
         numFarms = kbUnitCount(cMyID, gPlantationUnit, cUnitStateAlive);

      numResourceGatherers = numResourceGatherers - numFarms * cMaxSettlersPerPlantation;*/
      break;
   }
   }

   return (resourceAmount);
}



class ValidResourceInfo
{
   float amount = 0.0;
   int numEstimatedGatherers = 0;
   int amountPerGatherer = 0;
};

ValidResourceInfo getValidResourceInfo(int resource = cResourceFood, float maxDistance = 80.0, bool searchAllAreaGroups = false)
{
   ValidResourceInfo result;
   int numGatherers = kbUnitCount(cMyID, gEconUnit, cUnitStateAlive) +
                      kbUnitCount(cMyID, cUnitTypeSettlerWagon, cUnitStateAlive);
   float percentOnResource = getCorrectedResourcePercentage(resource);

   result.amount = getValidResourceAmount(resource, maxDistance, searchAllAreaGroups);
   result.numEstimatedGatherers = percentOnResource * numGatherers;
   if (result.numEstimatedGatherers > 0)
      result.amountPerGatherer = result.amount / result.numEstimatedGatherers;
   else
      result.amountPerGatherer = result.amount;

   return(result);
}

//==============================================================================
// handleExcessResources
/*
   When we can satisfy all our plans resource requirements, do something to keep resource balanced.
*/
//==============================================================================
bool handleExcessResources()
{
   float goldAmount = kbResourceGet(cResourceGold);
   float woodAmount = kbResourceGet(cResourceWood);
   float foodAmount = kbResourceGet(cResourceFood);
   int age = kbGetAge();
   bool inAgeTransition = agingUp();

   if (inAgeTransition == true)
      age++;

   if (age == cAge1 && gAgeUpResearchPlan < 0)
   {
      xsArraySetFloat(gExtraResourceNeeds, cResourceGold, 0.0);
      xsArraySetFloat(gExtraResourceNeeds, cResourceWood, 0.0);
      xsArraySetFloat(gExtraResourceNeeds, cResourceFood, 800.0);

      return (true);
   }
   else if (age == cAge2 && inAgeTransition == true)
   {
      int ageUpPolitician = -1;
      int flags = 0;
      float goldValue = 0.0;
      float woodValue = 0.0;
      float foodValue = 0.0;

      if (aiPlanGetType(gAgeUpResearchPlan) == cPlanBuild)
      {
         ageUpPolitician = aiPlanGetVariableInt(gAgeUpResearchPlan, cBuildPlanBuildingTypeID, 0);
         ageUpPolitician = kbProtoUnitGetAssociatedTech(ageUpPolitician);
      }
      else
      {
         ageUpPolitician = aiPlanGetVariableInt(gAgeUpResearchPlan, cResearchPlanTechID, 0);
      }

      flags = kbTechGetHCCardFlags(ageUpPolitician);
      goldValue = kbTechGetHCCardValuePerResource(ageUpPolitician, cResourceGold);
      woodValue = kbTechGetHCCardValuePerResource(ageUpPolitician, cResourceWood);
      foodValue = kbTechGetHCCardValuePerResource(ageUpPolitician, cResourceFood);

      if (btRushBoom > 0.0)
      {
         // Any politician delivering gold and wood
         if ((goldValue >= 100.0 && woodValue < 100.0 && foodValue < 100.0) ||
             (goldValue < 100.0 && woodValue >= 100.0 && foodValue < 100.0))
         {
            xsArraySetFloat(gExtraResourceNeeds, cResourceGold, 0.0);
            xsArraySetFloat(gExtraResourceNeeds, cResourceWood, 0.0);
            xsArraySetFloat(gExtraResourceNeeds, cResourceFood, 600.0);
         }
         else // For everything else, gather wood to prepare for immediate building construction after aging up.
         {
            xsArraySetFloat(gExtraResourceNeeds, cResourceGold, 0.0);
            xsArraySetFloat(gExtraResourceNeeds, cResourceWood, 400.0);
            xsArraySetFloat(gExtraResourceNeeds, cResourceFood, 0.0);
         }
      }
      else
      {
         // keep gathering food for FF.
         xsArraySetFloat(gExtraResourceNeeds, cResourceGold, 0.0);
         xsArraySetFloat(gExtraResourceNeeds, cResourceWood, 0.0);
         xsArraySetFloat(gExtraResourceNeeds, cResourceFood, 800.0);
      }

      return (true);
   }
   else if (age < cAge4 && gAgeUpResearchPlan < 0)
   {
      // start gathering resources for age up.
      float ageUpGoldNeeded = 1000.0;
      float ageUpFoodNeeded = 1200.0;

      if (age == cAge3)
      {
         ageUpGoldNeeded = 1200.0;
         ageUpFoodNeeded = 2000.0;
      }

      if (goldAmount < ageUpGoldNeeded)
         xsArraySetFloat(gExtraResourceNeeds, cResourceGold, goldAmount - ageUpGoldNeeded);
      xsArraySetFloat(gExtraResourceNeeds, cResourceWood, 0.0);
      if (foodAmount < ageUpFoodNeeded)
         xsArraySetFloat(gExtraResourceNeeds, cResourceFood, foodAmount - ageUpFoodNeeded);
      // We have excess resources, so start planning for age upgrades.
      gAgeUpPlanTime = 0;
      return (true);
   }

   /*if (cvOkToTrainArmy == true)
   {
      // grab the total resource cost of military maintain plans.
      float armyGoldNeeded = 0.0 - goldAmount;
      float armyWoodNeeded = 0.0 - woodAmount;
      float armyFoodNeeded = 0.0 - foodAmount;
      int numberMaintainPlans = xsArrayGetSize(gArmyUnitMaintainPlans);

      // Add more until if we have a resource amount exceeding 1000.
      while (true)
      {
         for (i = 0; < numberMaintainPlans)
         {
            int maintainPlanID = xsArrayGetInt(gArmyUnitMaintainPlans, i);
            if (maintainPlanID < 0)
               continue;
            int numberToMaintain = aiPlanGetVariableInt(maintainPlanID, cTrainPlanNumberToMaintain, 0);
            int maintainPUID = aiPlanGetVariableInt(maintainPlanID, cTrainPlanUnitType, 0);

            armyGoldNeeded = armyGoldNeeded + kbUnitCostPerResource(maintainPUID, cResourceGold) * numberToMaintain;
            armyWoodNeeded = armyWoodNeeded + kbUnitCostPerResource(maintainPUID, cResourceWood) * numberToMaintain;
            armyFoodNeeded = armyFoodNeeded + kbUnitCostPerResource(maintainPUID, cResourceFood) * numberToMaintain;
         }

         if (armyGoldNeeded >= 1000.0 || armyWoodNeeded >= 1000.0 || armyFoodNeeded >= 1000.0)
            break;
         // Avoiding an infinite loop when there are no plans/nothing to train/units cost nothing.
         if (armyGoldNeeded <= 0.0 - goldAmount && armyWoodNeeded <= 0.0 - woodAmount &&
             armyFoodNeeded <= 0.0 - foodAmount)
            break;
      }

      if (armyGoldNeeded < 0.0)
         armyGoldNeeded = 0.0;
      if (armyWoodNeeded < 0.0)
         armyWoodNeeded = 0.0;
      if (armyFoodNeeded < 0.0)
         armyFoodNeeded = 0.0;

      if (armyGoldNeeded > 0.0 || armyWoodNeeded > 0.0 || armyFoodNeeded > 0.0)
      {
         xsArraySetFloat(gExtraResourceNeeds, cResourceGold, armyGoldNeeded);
         xsArraySetFloat(gExtraResourceNeeds, cResourceWood, armyWoodNeeded);
         xsArraySetFloat(gExtraResourceNeeds, cResourceFood, armyFoodNeeded);

         return (true);
      }
   }*/

   debugEconomy("***** WARNING: UNHANDLED EXCESS RESOURCES. *****");

   return (false);
}

//==============================================================================
// updateResourceDistribution
/*
   Predict our resource needs based on plan costs and resource crates we are going
   to ship.
*/
//==============================================================================
void updateResourceDistribution(bool force = false)
{
   float planGoldNeeded = 0.0;
   float planWoodNeeded = 0.0;
   float planFoodNeeded = 0.0;
   float totalPlanGoldNeeded = 0.0;
   float totalPlanWoodNeeded = 0.0;
   float totalPlanFoodNeeded = 0.0;
   float goldAmount = 0.0;
   float woodAmount = 0.0;
   float foodAmount = 0.0;
   float goldNeeded = 0.0;
   float woodNeeded = 0.0;
   float foodNeeded = 0.0;
   float totalNeeded = 0.0;
   int planID = -1;
   int trainUnitType = -1;
   int trainCount = 0;
   int numPlans = aiPlanGetActiveCount();
   int planType = -1;
   bool reserveForVillagers = false;
   bool reserveForFishingBoats = false;
   float goldReservedRate = 0.0;
   float woodReservedRate = 0.0;
   float foodReservedRate = 0.0;
   float goldPercentage = 0.0;
   float woodPercentage = 0.0;
   float foodPercentage = 0.0;
   float lastGoldPercentage = aiGetResourcePercentage(cResourceGold);
   float lastWoodPercentage = aiGetResourcePercentage(cResourceWood);
   float lastFoodPercentage = aiGetResourcePercentage(cResourceFood);
   int planPri = 50;
   int highestPri = 50;
   int highestPriPlanID = -1;
   static int lastHighestPriPlanID = -1;
   float highestPriPlanGoldNeeded = 0.0;
   float highestPriPlanWoodNeeded = 0.0;
   float highestPriPlanFoodNeeded = 0.0;
   int numberSendingCards = aiHCGetNumberSendingCards();
   int cardIndex = -1;
   int cardFlags = 0;
   int crateQuery = createSimpleUnitQuery(cUnitTypeAbstractResourceCrate, cMyID, cUnitStateAlive);
   int numberCrates = kbUnitQueryExecute(crateQuery);
   int crateID = -1;
   float handicap = kbGetPlayerHandicap(cMyID);
   float cost = 0.0;
   float trainPoints = 0.0;
   int numberBuildingsWanted = 0;
   static int lastChangeTime = 0;
   int time = xsGetTime();

   aiSetResourceGathererPercentageWeight(cRGPScript, 1.0);
   aiSetResourceGathererPercentageWeight(cRGPCost, 0.0);
   debugEconomy("updateResourceDistribution(): number plans=" + numPlans);
   for (i = 0; < numPlans)
   {
      planID = aiPlanGetIDByActiveIndex(i);
      planType = aiPlanGetType(planID);
      planPri = aiPlanGetDesiredResourcePriority(planID);
      if (planType == cPlanTrain)
      {
         trainUnitType = aiPlanGetVariableInt(planID, cTrainPlanUnitType, 0);
         trainCount = aiPlanGetVariableInt(planID, cTrainPlanNumberToMaintain, 0);
         if (trainUnitType == gEconUnit)
         {
            // Ottomans train villager automatically
            if ((cMyCiv != cCivOttomans || (gRevolutionType & cRevolutionEconomic) == cRevolutionEconomic) &&
                kbUnitCount(cMyID, gEconUnit, cUnitStateABQ) < trainCount && kbGetPop() < kbGetPopCap())
            {
               // reserve gather rate so we always have villager training at each town center
               reserveForVillagers = true;
            }
            continue;
         }
         if (trainUnitType == gFishingUnit)
         {
            if ((gRevolutionType == 0 || (gRevolutionType & cRevolutionEconomic) == cRevolutionEconomic) &&
                kbUnitCount(cMyID, gFishingUnit, cUnitStateABQ) < trainCount && kbGetPop() < kbGetPopCap())
            {
               reserveForFishingBoats = true;
            }
            continue;
         }
      }
      if (planType == cPlanTrain || planType == cPlanBuild || planType == cPlanBuildWall || planType == cPlanResearch ||
          planType == cPlanRepair)
      {
         planGoldNeeded = aiPlanGetFutureNeedsCostPerResource(planID, cResourceGold);
         planWoodNeeded = aiPlanGetFutureNeedsCostPerResource(planID, cResourceWood);
         planFoodNeeded = aiPlanGetFutureNeedsCostPerResource(planID, cResourceFood);
         totalPlanGoldNeeded = totalPlanGoldNeeded + planGoldNeeded;
         totalPlanWoodNeeded = totalPlanWoodNeeded + planWoodNeeded;
         totalPlanFoodNeeded = totalPlanFoodNeeded + planFoodNeeded;
         if (planPri > highestPri)
         {
            highestPri = planPri;
            highestPriPlanID = planID;
            highestPriPlanGoldNeeded = planGoldNeeded;
            highestPriPlanWoodNeeded = planWoodNeeded;
            highestPriPlanFoodNeeded = planFoodNeeded;
         }
         debugEconomy(
            "updateResourceDistribution(): name=" + aiPlanGetName(planID) + ", needed=(" + planGoldNeeded + ", " +
            planWoodNeeded + ", " + planFoodNeeded + ")");
      }
   }

   // Additional build plan demands because we only queue up 1 building of each type at a time.
   if (cvOkToBuild == true)
   {
      // House
      numberBuildingsWanted = ((5 + 15 * kbGetAge()) - (kbGetPopCap() - kbGetPop()) - 1) / kbProtoUnitGetPopCap(gHouseUnit);
      if (numberBuildingsWanted > 0)
      {
         planWoodNeeded = numberBuildingsWanted * kbUnitCostPerResource(gHouseUnit, cResourceWood);
         totalPlanWoodNeeded = totalPlanWoodNeeded + planWoodNeeded;
         debugEconomy(
            "updateResourceDistribution(): additional houses=" + numberBuildingsWanted + ", needed=(0.0, " +
            planWoodNeeded + ", 0.0)");
      }

      // Mill
      /*if (gTimeToFarm == true)
      {
         if (civIsAsian() == true || civIsAfrican() == true || cMyCiv == cCivDEMexicans)
            numberBuildingsWanted =
                ((aiGetNumberDesiredGatherers(cResourceFood) + cMaxSettlersPerFarm - 1) / cMaxSettlersPerFarm) -
                (gNumberFoodPaddies + gNumberQueuedFoodPaddies);
         else
            numberBuildingsWanted = ((aiGetNumberDesiredGatherers(cResourceFood) - 1) / cMaxSettlersPerFarm) -
                                    kbUnitCount(cMyID, gFarmUnit, cUnitStateABQ);
         if (numberBuildingsWanted > 0)
         {
            planWoodNeeded = numberBuildingsWanted * kbUnitCostPerResource(gFarmUnit, cResourceWood);
            totalPlanWoodNeeded = totalPlanWoodNeeded + planWoodNeeded;
            debugEconomy("updateResourceDistribution(): additional mills=" + numberBuildingsWanted + ", needed=(0.0, " +
                   planWoodNeeded + ", 0.0)");
         }
      }

      // Plantation
      if (gTimeForPlantations == true)
      {
         if (civIsAsian() == true || civIsAfrican() == true || cMyCiv == cCivDEMexicans)
            numberBuildingsWanted = ((aiGetNumberDesiredGatherers(cResourceGold) + cMaxSettlersPerPlantation - 1) /
                                     cMaxSettlersPerPlantation) -
                                    (gNumberGoldPaddies + gNumberQueuedGoldPaddies);
         else
            numberBuildingsWanted = ((aiGetNumberDesiredGatherers(cResourceGold) - 1) / cMaxSettlersPerPlantation) -
                                    kbUnitCount(cMyID, gPlantationUnit, cUnitStateABQ);
         if (numberBuildingsWanted > 0)
         {
            planWoodNeeded = numberBuildingsWanted * kbUnitCostPerResource(gPlantationUnit, cResourceWood);
            totalPlanWoodNeeded = totalPlanWoodNeeded + planWoodNeeded;
            debugEconomy("updateResourceDistribution(): additional plantations=" + numberBuildingsWanted + ", needed=(0.0, " +
                   planWoodNeeded + ", 0.0)");
         }
      }*/
   }

   goldAmount = kbResourceGet(cResourceGold);
   woodAmount = kbResourceGet(cResourceWood);
   foodAmount = kbResourceGet(cResourceFood);

   // Add resource amount of sending cards from HC.
   for (i = 0; < numberSendingCards)
   {
      cardIndex = aiHCGetSendingCardIndex(i);
      cardFlags = aiHCDeckGetCardFlags(gDefaultDeck, cardIndex);
      if ((cardFlags & cHCCardFlagResourceCrate) == cHCCardFlagResourceCrate)
      {
         goldAmount = goldAmount + aiHCDeckGetCardValuePerResource(gDefaultDeck, cardIndex, cResourceGold) * handicap;
         woodAmount = woodAmount + aiHCDeckGetCardValuePerResource(gDefaultDeck, cardIndex, cResourceWood) * handicap;
         foodAmount = foodAmount + aiHCDeckGetCardValuePerResource(gDefaultDeck, cardIndex, cResourceFood) * handicap;
      }
   }

   // Add resource amount of crates we have now.
   for (i = 0; < numberCrates)
   {
      crateID = kbUnitQueryGetResult(crateQuery, i);
      goldAmount = goldAmount + kbUnitGetResourceAmount(crateID, cResourceGold) * handicap;
      woodAmount = woodAmount + kbUnitGetResourceAmount(crateID, cResourceWood) * handicap;
      foodAmount = foodAmount + kbUnitGetResourceAmount(crateID, cResourceFood) * handicap;
   }

   debugEconomy(
      "updateResourceDistribution(): total=(" + totalPlanGoldNeeded + ", " + totalPlanWoodNeeded + ", " +
      totalPlanFoodNeeded + "), amount=(" + goldAmount + ", " + woodAmount + ", " + foodAmount + ")");

   // If we don't have enough resources for our highest priority plan, limit other plans' resource needs to prioritize
   // the plan first
   float actualGoldRate = aiGetActualGatherRate(cResourceGold);
   float actualWoodRate = aiGetActualGatherRate(cResourceWood);
   float actualFoodRate = aiGetActualGatherRate(cResourceFood);
   bool ignoreChange = false;

   if (highestPriPlanID == lastHighestPriPlanID)
   {
      if (goldAmount < highestPriPlanGoldNeeded || woodAmount < highestPriPlanWoodNeeded ||
          foodAmount < highestPriPlanFoodNeeded)
      {
         if (time - lastChangeTime < 60000)
         {
            debugEconomy(
               "updateResourceDistribution(): Ignoring resource distribution change until we have enough resources for " +
               aiPlanGetName(planID));
            ignoreChange = true;
         }
         // If one minute passed, make sure we have gatherers on the resource we need.
         else if (
             (goldAmount >= highestPriPlanGoldNeeded || actualGoldRate > 0.0) &&
             (woodAmount >= highestPriPlanWoodNeeded || actualWoodRate > 0.0) &&
             (foodAmount >= highestPriPlanFoodNeeded || actualFoodRate > 0.0))
         {
            debugEconomy(
               "updateResourceDistribution(): Ignoring resource distribution change until we have enough resources for " +
               aiPlanGetName(planID));
            ignoreChange = true;
         }
         else
         {
            // Reset last highest pri plan so we won't be blocked by change time threshold checks.
            lastHighestPriPlanID = -1;
         }
      }
   }

   if (((goldAmount + actualGoldRate * 60.0) < highestPriPlanGoldNeeded ||
        (woodAmount + actualWoodRate * 60.0) < highestPriPlanWoodNeeded ||
        (foodAmount + actualFoodRate * 60.0) < highestPriPlanFoodNeeded) &&
       ignoreChange == false)
   {
      float ratio = kbUnitCount(cMyID, gEconUnit, cUnitStateAlive) +
                    2 * kbUnitCount(cMyID, cUnitTypeSettlerWagon, cUnitStateAlive);
      ratio = ratio * handicap;

      // 1 minute income of the most needed resource gather rate
      ratio = ratio * 60.0;
      if (goldAmount < highestPriPlanGoldNeeded)
      {
         if (cMyCiv == cCivXPIroquois || cMyCiv == cCivXPSioux)
         {
            if (gTimeForPlantations == true)
               ratio = ratio * kbProtoUnitGetGatherRate(gEconUnit, gPlantationUnit) * 0.5;
            else
               ratio = ratio * kbProtoUnitGetGatherRate(gEconUnit, cUnitTypedeFurTrade) * 0.5;
         }
         else
         {
            if (gTimeForPlantations == true)
               ratio = ratio * kbProtoUnitGetGatherRate(gEconUnit, gPlantationUnit, cResourceGold) * 0.5;
            else
               ratio = ratio * kbProtoUnitGetGatherRate(gEconUnit, cUnitTypeAbstractMine) * 0.5;
         }
      }
      else if (woodAmount < highestPriPlanWoodNeeded)
      {
         ratio = ratio * kbProtoUnitGetGatherRate(gEconUnit, cUnitTypeTree);
      }
      else
      {
         if (cMyCiv == cCivJapanese || cMyCiv == cCivSPCJapanese || cMyCiv == cCivSPCJapaneseEnemy)
         {
            if (gTimeToFarm == true)
               ratio = ratio * kbProtoUnitGetGatherRate(gEconUnit, gFarmUnit, cResourceFood) * 0.5;
            else
               ratio = ratio * kbProtoUnitGetGatherRate(gEconUnit, cUnitTypeypBerryBuilding) * 0.5;
         }
         else
         {
            if (gTimeToFarm == true)
               ratio = ratio * kbProtoUnitGetGatherRate(gEconUnit, gFarmUnit, cResourceFood) * 0.5;
            else
               ratio = ratio * kbProtoUnitGetGatherRate(gEconUnit, cUnitTypeHuntable) * 0.5;
         }
      }
      ratio = ratio * kbGetPlayerHandicap(cMyID);
      ratio = ratio / (totalPlanGoldNeeded + totalPlanWoodNeeded + totalPlanFoodNeeded);

      totalPlanGoldNeeded = highestPriPlanGoldNeeded + ratio * (totalPlanGoldNeeded - highestPriPlanGoldNeeded);
      totalPlanWoodNeeded = highestPriPlanWoodNeeded + ratio * (totalPlanWoodNeeded - highestPriPlanWoodNeeded);
      totalPlanFoodNeeded = highestPriPlanFoodNeeded + ratio * (totalPlanFoodNeeded - highestPriPlanFoodNeeded);
      debugEconomy("Prioritizing resource gathering for plan " + aiPlanGetName(highestPriPlanID));
   }
   else
   {
      highestPriPlanID = -1;
   }

   goldNeeded = totalPlanGoldNeeded - goldAmount;
   woodNeeded = totalPlanWoodNeeded - woodAmount;
   foodNeeded = totalPlanFoodNeeded - foodAmount;

   debugEconomy("Resource needed, gold=" + goldNeeded + ", wood=" + woodNeeded + ", food=" + foodNeeded);

   xsArraySetFloat(gResourceNeeds, cResourceGold, goldNeeded);
   xsArraySetFloat(gResourceNeeds, cResourceWood, woodNeeded);
   xsArraySetFloat(gResourceNeeds, cResourceFood, foodNeeded);

   if (reserveForVillagers == true)
   {
      // reserve gather rate so we always have villager training at each town center
      if (gRevolutionType == 0 || (gRevolutionType & cRevolutionEconomic) == cRevolutionEconomic)
      {
         trainPoints = kbUnitGetTrainPoints(gEconUnit);

         cost = kbUnitCostPerResource(gEconUnit, cResourceFood);

         if (cMyCiv == cCivRussians)
            cost = cost * 3.0;
         if (cost > 0.0)
         {
            if (foodNeeded > -2.0 * cost)
               foodReservedRate = foodReservedRate + (cost / trainPoints);
            else if (foodNeeded > -1.0 * cost)
               foodReservedRate = foodReservedRate + (foodNeeded + cost) / (0.0 - cost) * (cost / trainPoints);
         }
         else
         {
            cost = kbUnitCostPerResource(gEconUnit, cResourceWood);
            if (cost > 0.0)
            {
               if (woodNeeded > -2.0 * cost)
                  woodReservedRate = woodReservedRate + (cost / trainPoints);
               else if (woodNeeded > -1.0 * cost)
                  woodReservedRate = woodReservedRate + (woodNeeded + cost) / (0.0 - cost) * (cost / trainPoints);
            }
            else
            {
               cost = kbUnitCostPerResource(gEconUnit, cResourceGold);
               if (cost > 0.0)
               {
                  if (goldNeeded > -2.0 * cost)
                     goldReservedRate = goldReservedRate + (cost / trainPoints);
                  else if (goldNeeded > -1.0 * cost)
                     goldReservedRate = goldReservedRate + (goldNeeded + cost) / (0.0 - cost) * (cost / trainPoints);
               }
            }
         }
      }
   }
   if (reserveForFishingBoats == true)
   {
      trainPoints = kbUnitGetTrainPoints(gFishingUnit);
      cost = kbUnitCostPerResource(gFishingUnit, cResourceWood);
      if (woodNeeded > -2.0 * cost)
         woodReservedRate = woodReservedRate + (cost / trainPoints);
      else if (woodNeeded > -1.0 * cost)
         woodReservedRate = woodReservedRate + (woodNeeded + cost) / (0.0 - cost) * (cost / trainPoints);
   }

   if (gDisableWoods == true)
      woodReservedRate = 0.0;

   aiSetReservedGatherRate(cResourceGold, goldReservedRate);
   aiSetReservedGatherRate(cResourceWood, woodReservedRate);
   aiSetReservedGatherRate(cResourceFood, foodReservedRate);

   if (goldNeeded < 0.0)
      goldNeeded = 0.0;
   if (woodNeeded < 0.0)
      woodNeeded = 0.0;
   if (foodNeeded < 0.0)
      foodNeeded = 0.0;

   if (cvOkToGatherGold == false)
   {
      goldNeeded = 0.0;
      totalPlanGoldNeeded = 0.0;
   }
   if (cvOkToGatherWood == false)
   {
      woodNeeded = 0.0;
      totalPlanWoodNeeded = 0.0;
   }
   if (cvOkToGatherFood == false)
   {
      foodNeeded = 0.0;
      totalPlanFoodNeeded = 0.0;
   }

   totalNeeded = goldNeeded + woodNeeded + foodNeeded;
   gExcessResources = false;

   // We have enough resource for our plans
   if (totalNeeded <= 0.0)
   {
      if (totalNeeded == 0.0)
      {
         bool excessResources = handleExcessResources();

         if (excessResources == true)
         {
            goldNeeded = xsArrayGetFloat(gResourceNeeds, cResourceGold) + xsArrayGetFloat(gExtraResourceNeeds, cResourceGold);
            woodNeeded = xsArrayGetFloat(gResourceNeeds, cResourceWood) + xsArrayGetFloat(gExtraResourceNeeds, cResourceWood);
            foodNeeded = xsArrayGetFloat(gResourceNeeds, cResourceFood) + xsArrayGetFloat(gExtraResourceNeeds, cResourceFood);

            // Do we at least have 1 resource not enough in stock?
            if (goldNeeded > 0.0 || woodNeeded > 0.0 || foodNeeded > 0.0)
            {
               if (goldNeeded > 0.0)
                  goldNeeded = 0.0;
               if (woodNeeded > 0.0)
                  woodNeeded = 0.0;
               if (foodNeeded > 0.0)
                  foodNeeded = 0.0;

               totalNeeded = goldNeeded + woodNeeded + foodNeeded;
               debugEconomy("Extra resource needed, gold=" + goldNeeded + ", wood=" + woodNeeded + ", food=" + foodNeeded);

               excessResources = false;
            }
         }

         if (excessResources == true)
         {
            // We have excess resources, don't move around until we have resources in demand.
            gExcessResources = true;
            ignoreChange = true;
         }
      }
   }

   // adjust gold needed to buy wood with gold if we disabled wood gathering.
   if (gDisableWoods == true)
   {
      // amount of gold needed to buy for wood.
      woodNeeded = woodNeeded * aiGetMarketBuyCost(cResourceWood) / 100.0;
      if ((goldNeeded + woodNeeded) > 0.0)
         gGoldPercentageToBuyForWood = woodNeeded / (goldNeeded + woodNeeded);
      else
         gGoldPercentageToBuyForWood = 0.0;
      goldNeeded = goldNeeded + woodNeeded;
      woodNeeded = 0.0;
   }
   else
   {
      gGoldPercentageToBuyForWood = 0.0;
   }

   if (totalNeeded > 0.0)
   {
      goldPercentage = goldNeeded / totalNeeded;
      woodPercentage = woodNeeded / totalNeeded;
      foodPercentage = foodNeeded / totalNeeded;
   }
   else
   {
      goldPercentage = 0.334;
      woodPercentage = 0.333;
      foodPercentage = 0.333;
   }

   float goldError = goldPercentage - lastGoldPercentage;
   float woodError = woodPercentage - lastWoodPercentage;
   float foodError = foodPercentage - lastFoodPercentage;

   // sum of resource percentage errors over the past few runs, if we are over gathering certain resources
   // these values will surely become larger otherwise it should not increase overtime when our resource percentages are ideal.
   static float goldIntegral = 0.0;
   static float woodIntegral = 0.0;
   static float foodIntegral = 0.0;

   goldIntegral += goldError;
   woodIntegral += woodError;
   foodIntegral += foodError;

   debugEconomy(
       "updateResourceDistribution(): resource percentage error=(" + goldError + ", " + woodError + ", " + foodError + ")");
   debugEconomy(
       "updateResourceDistribution(): resource percentage integral=(" + goldIntegral + ", " + woodIntegral + ", " +
       foodIntegral + ")");

   // TODO: other possible ways to reduce resource percentage changes, such as not changing military production unit types too
   // often.
   if (ignoreChange == false)
   {
      float absError = abs(goldError) + abs(woodError) + abs(foodError);
      float absIntegral = abs(goldIntegral) + abs(woodIntegral) + abs(foodIntegral);

      int changeTimeThreshold = 30;

      // When we need more resource types, it usually indicates our distribution is more stable, thus we could increase the time
      // threshold for changing.
      if (goldPercentage > 0.0)
         changeTimeThreshold += 30;
      if (woodPercentage > 0.0)
         changeTimeThreshold += 30;
      if (foodPercentage > 0.0)
         changeTimeThreshold += 30;
      if (changeTimeThreshold < 120)
         changeTimeThreshold = 60;

      // Let's not move around in a minute unless there are urgent plans.
      if (time - lastChangeTime < changeTimeThreshold * 1000 &&
          (highestPriPlanID < 0 || highestPriPlanID == lastHighestPriPlanID) && absIntegral < 8.0)
      {
         debugEconomy("updateResourceDistribution(): Avoid changing resource distribution too soon");
         ignoreChange = true;
      }
      // Avoid tasking villagers around if we are on low demand.
      // TODO: villagers still move around too frequently, especially when resources are far from each other.
      else if (
          (actualGoldRate * changeTimeThreshold >= goldNeeded) && (actualWoodRate * changeTimeThreshold >= woodNeeded) &&
          (actualFoodRate * changeTimeThreshold >= foodNeeded))
      {
         debugEconomy("updateResourceDistribution(): Ignoring resource distribution change due to low demand");
         ignoreChange = true;
      }
      // Avoid ignoring change when we need a certain resource, but previously not.
      // When we are over gathering a certain resource also ignore this check.
      else if (
          (absError < 0.5 && absIntegral < 8.0) && (goldPercentage == 0.0 || lastGoldPercentage > 0.0) &&
          (woodPercentage == 0.0 || lastWoodPercentage > 0.0) && (foodPercentage == 0.0 || lastFoodPercentage > 0.0))
      {
         debugEconomy(
            "updateResourceDistribution(): Ignoring small resource distribution change, absolute error =" + absError +
            ", integral=" + absIntegral);
         ignoreChange = true;
      }
   }

   // Update gather plan priorities, make sure the most needed resource has the highest priority
   if ((gRevolutionType & cRevolutionFinland) == 0)
   {
      if (goldPercentage > woodPercentage && goldPercentage > foodPercentage)
      {
         if (woodPercentage > foodPercentage)
         { // gold > wood > food
            if (gPrioritizeFarms == true)
            {
               gGatherPlanPriorityHunt = 79;
               gGatherPlanPriorityBerry = 78;
               gGatherPlanPriorityMill = 80;
            }
            else
            {
               gGatherPlanPriorityHunt = 80;
               gGatherPlanPriorityBerry = 79;
               gGatherPlanPriorityMill = 78;
            }
            gGatherPlanPriorityWood = 81;
            if (gPrioritizeEstates == true)
            {
               gGatherPlanPriorityMine = 82;
               gGatherPlanPriorityEstate = 83;
            }
            else
            {
               gGatherPlanPriorityMine = 83;
               gGatherPlanPriorityEstate = 82;
            }
            gGatherPlanPriorityFish = 19;
            gGatherPlanPriorityWhale = 20;
         }
         else
         { // gold > food > wood
            if (gPrioritizeFarms == true)
            {
               gGatherPlanPriorityHunt = 80;
               gGatherPlanPriorityBerry = 79;
               gGatherPlanPriorityMill = 81;
            }
            else
            {
               gGatherPlanPriorityHunt = 81;
               gGatherPlanPriorityBerry = 80;
               gGatherPlanPriorityMill = 79;
            }
            gGatherPlanPriorityWood = 78;
            if (gPrioritizeEstates == true)
            {
               gGatherPlanPriorityMine = 82;
               gGatherPlanPriorityEstate = 83;
            }
            else
            {
               gGatherPlanPriorityMine = 83;
               gGatherPlanPriorityEstate = 82;
            }
            gGatherPlanPriorityFish = 19;
            gGatherPlanPriorityWhale = 20;
         }
      }
      else if (woodPercentage > foodPercentage)
      {
         if (goldPercentage > foodPercentage)
         { // wood > gold > food
            if (gPrioritizeFarms == true)
            {
               gGatherPlanPriorityHunt = 79;
               gGatherPlanPriorityBerry = 78;
               gGatherPlanPriorityMill = 80;
            }
            else
            {
               gGatherPlanPriorityHunt = 80;
               gGatherPlanPriorityBerry = 79;
               gGatherPlanPriorityMill = 78;
            }
            gGatherPlanPriorityWood = 83;
            if (gPrioritizeEstates == true)
            {
               gGatherPlanPriorityMine = 81;
               gGatherPlanPriorityEstate = 82;
            }
            else
            {
               gGatherPlanPriorityMine = 82;
               gGatherPlanPriorityEstate = 81;
            }
            gGatherPlanPriorityFish = 19;
            gGatherPlanPriorityWhale = 20;
         }
         else
         { // wood > food > gold
            if (gPrioritizeFarms == true)
            {
               gGatherPlanPriorityHunt = 81;
               gGatherPlanPriorityBerry = 80;
               gGatherPlanPriorityMill = 82;
            }
            else
            {
               gGatherPlanPriorityHunt = 82;
               gGatherPlanPriorityBerry = 81;
               gGatherPlanPriorityMill = 80;
            }
            gGatherPlanPriorityWood = 83;
            if (gPrioritizeEstates == true)
            {
               gGatherPlanPriorityMine = 78;
               gGatherPlanPriorityEstate = 79;
            }
            else
            {
               gGatherPlanPriorityMine = 79;
               gGatherPlanPriorityEstate = 78;
            }
            gGatherPlanPriorityFish = 20;
            gGatherPlanPriorityWhale = 19;
         }
      }
      else
      {
         if (goldPercentage > woodPercentage)
         { // food > gold > wood
            if (gPrioritizeFarms == true)
            {
               gGatherPlanPriorityHunt = 82;
               gGatherPlanPriorityBerry = 81;
               gGatherPlanPriorityMill = 83;
            }
            else
            {
               gGatherPlanPriorityHunt = 83;
               gGatherPlanPriorityBerry = 82;
               gGatherPlanPriorityMill = 81;
            }
            gGatherPlanPriorityWood = 78;
            if (gPrioritizeEstates == true)
            {
               gGatherPlanPriorityMine = 79;
               gGatherPlanPriorityEstate = 80;
            }
            else
            {
               gGatherPlanPriorityMine = 80;
               gGatherPlanPriorityEstate = 79;
            }
            gGatherPlanPriorityFish = 20;
            gGatherPlanPriorityWhale = 19;
         }
         else
         { // food > wood > gold
            if (gPrioritizeFarms == true)
            {
               gGatherPlanPriorityHunt = 82;
               gGatherPlanPriorityBerry = 81;
               gGatherPlanPriorityMill = 83;
            }
            else
            {
               gGatherPlanPriorityHunt = 83;
               gGatherPlanPriorityBerry = 82;
               gGatherPlanPriorityMill = 81;
            }
            gGatherPlanPriorityWood = 80;
            if (gPrioritizeEstates == true)
            {
               gGatherPlanPriorityMine = 78;
               gGatherPlanPriorityEstate = 79;
            }
            else
            {
               gGatherPlanPriorityMine = 79;
               gGatherPlanPriorityEstate = 78;
            }
            gGatherPlanPriorityFish = 20;
            gGatherPlanPriorityWhale = 19;
         }
      }
   }
   else
   {
      // For Finland revolution, gather plans need to be below defend plan, but higher than reserve plan.
      if (goldPercentage > woodPercentage && goldPercentage > foodPercentage)
      {
         if (woodPercentage > foodPercentage)
         { // gold > wood > food
            gGatherPlanPriorityHunt = 7;
            gGatherPlanPriorityBerry = 6;
            gGatherPlanPriorityMill = 0;
            gGatherPlanPriorityWood = 8;
            gGatherPlanPriorityMine = 9;
            gGatherPlanPriorityEstate = 0;
            gGatherPlanPriorityFish = 19;
            gGatherPlanPriorityWhale = 20;
         }
         else
         { // gold > food > wood
            gGatherPlanPriorityHunt = 8;
            gGatherPlanPriorityBerry = 7;
            gGatherPlanPriorityMill = 0;
            gGatherPlanPriorityWood = 6;
            gGatherPlanPriorityMine = 9;
            gGatherPlanPriorityEstate = 0;
            gGatherPlanPriorityFish = 19;
            gGatherPlanPriorityWhale = 20;
         }
      }
      else if (woodPercentage > foodPercentage)
      {
         if (goldPercentage > foodPercentage)
         { // wood > gold > food
            gGatherPlanPriorityHunt = 7;
            gGatherPlanPriorityBerry = 6;
            gGatherPlanPriorityMill = 0;
            gGatherPlanPriorityWood = 9;
            gGatherPlanPriorityMine = 8;
            gGatherPlanPriorityEstate = 0;
            gGatherPlanPriorityFish = 19;
            gGatherPlanPriorityWhale = 20;
         }
         else
         { // wood > food > gold
            gGatherPlanPriorityHunt = 8;
            gGatherPlanPriorityBerry = 7;
            gGatherPlanPriorityMill = 0;
            gGatherPlanPriorityWood = 9;
            gGatherPlanPriorityMine = 6;
            gGatherPlanPriorityEstate = 0;
            gGatherPlanPriorityFish = 20;
            gGatherPlanPriorityWhale = 19;
         }
      }
      else
      {
         if (goldPercentage > woodPercentage)
         { // food > gold > wood
            gGatherPlanPriorityHunt = 9;
            gGatherPlanPriorityBerry = 8;
            gGatherPlanPriorityMill = 0;
            gGatherPlanPriorityWood = 6;
            gGatherPlanPriorityMine = 7;
            gGatherPlanPriorityEstate = 0;
            gGatherPlanPriorityFish = 20;
            gGatherPlanPriorityWhale = 19;
         }
         else
         { // food > wood > gold
            gGatherPlanPriorityHunt = 9;
            gGatherPlanPriorityBerry = 8;
            gGatherPlanPriorityMill = 0;
            gGatherPlanPriorityWood = 7;
            gGatherPlanPriorityMine = 6;
            gGatherPlanPriorityEstate = 0;
            gGatherPlanPriorityFish = 20;
            gGatherPlanPriorityWhale = 19;
         }
      }
   }

   if (ignoreChange == false || force == true)
   {
      aiSetResourcePercentage(cResourceGold, false, goldPercentage);
      aiSetResourcePercentage(cResourceWood, false, woodPercentage);
      aiSetResourcePercentage(cResourceFood, false, foodPercentage);
      aiNormalizeResourcePercentages(); // Set them to 1.0 total, just in case these don't add up.*/

      debugEconomy(
         "updateResourceDistribution(): resource percentage=(" + goldPercentage + ", " + woodPercentage + ", " +
         foodPercentage + ")");
      debugEconomy("updateResourceDistribution(): resource needed=(" + goldNeeded + ", " + woodNeeded + ", " + foodNeeded + ")");

      xsArraySetInt(gAdjustBreakdownAttempts, cResourceGold, xsArrayGetInt(gAdjustBreakdownAttempts, cResourceGold) + 1);
      xsArraySetInt(gAdjustBreakdownAttempts, cResourceWood, xsArrayGetInt(gAdjustBreakdownAttempts, cResourceWood) + 1);
      xsArraySetInt(gAdjustBreakdownAttempts, cResourceFood, xsArrayGetInt(gAdjustBreakdownAttempts, cResourceFood) + 1);

      goldIntegral = 0.0;
      woodIntegral = 0.0;
      foodIntegral = 0.0;

      lastChangeTime = time;
   }

   lastHighestPriPlanID = highestPriPlanID;
}

//==============================================================================
// rule resourceManager
/*
   Watch the resource balance, buy/sell imbalanced resources as needed

   In initial build phase (first 5 houses?) sell all food, buy wood with
   any gold.  Later, look for imbalances.
*/
//==============================================================================
rule resourceManager
inactive
minInterval 10
group startup
{
   bool goAgain = false;         // Set this flag if we do a buy or sell and want to quickly evaluate
   static bool fastMode = false; // Set this flag if we enter high-speed mode, clear it on leaving
   static int lastTributeRequestTime = 0;

   if (aiResourceIsLocked(cResourceGold) == true)
   {
      debugEconomy("Gold is locked.");
      if (fastMode == true)
      {
         // We need to slow down.
         xsSetRuleMinIntervalSelf(10);
         debugEconomy("Resource manager going to slow mode.");
         fastMode = false;
      }
      return;
   }

   if (((xsGetTime() - lastTributeRequestTime) > 300000) &&
       ((xsGetTime() - gLastTribSentTime) > 120000)) // Don't request too often, and don't request right after sending.
   {                                                 // See if we have a critical shortage of anything
      float totalResources = kbResourceGet(cResourceFood) + kbResourceGet(cResourceWood) + kbResourceGet(cResourceGold);
      if ((totalResources > 1000.0) && (kbGetAge() > cAge1))
      { // Don't request tribute if we're short on everything, just for imbalances.  And skip age 1, since we'll have
        // zero gold and mucho food.
         if (kbResourceGet(cResourceFood) < (totalResources / 10.0))
         {
            sendStatement(cPlayerRelationAlly, cAICommPromptToAllyRequestFood);
            lastTributeRequestTime = xsGetTime();
         }
         if (kbResourceGet(cResourceGold) < (totalResources / 10.0))
         {
            sendStatement(cPlayerRelationAlly, cAICommPromptToAllyRequestCoin);
            lastTributeRequestTime = xsGetTime();
         }
         if (kbResourceGet(cResourceWood) < (totalResources / 10.0))
         {
            sendStatement(cPlayerRelationAlly, cAICommPromptToAllyRequestWood);
            lastTributeRequestTime = xsGetTime();
         }
      }
   }

   // Normal imbalance rules apply
   if ((kbUnitCount(cMyID, gMarketUnit, cUnitStateAlive) > 0) && (aiResourceIsLocked(cResourceGold) == false))
   {
      if (xsArrayGetFloat(gResourceNeeds, cResourceFood) < -1000.0 && xsArrayGetFloat(gResourceNeeds, cResourceGold) > 100.0 &&
          aiResourceIsLocked(cResourceFood) == false)
      {
         aiSellResourceOnMarket(cResourceFood);
         xsArraySetFloat(gResourceNeeds, cResourceFood, xsArrayGetFloat(gResourceNeeds, cResourceFood) + 100.0);
         xsArraySetFloat(
             gResourceNeeds,
             cResourceGold,
             xsArrayGetFloat(gResourceNeeds, cResourceGold) - aiGetMarketSellCost(cResourceFood));
         debugEconomy("Selling 100 food.");
         goAgain = true;
      }
      if (xsArrayGetFloat(gResourceNeeds, cResourceWood) < -1000.0 && xsArrayGetFloat(gResourceNeeds, cResourceGold) > 100.0 &&
          aiResourceIsLocked(cResourceWood) == false)
      {
         aiSellResourceOnMarket(cResourceWood);
         xsArraySetFloat(gResourceNeeds, cResourceWood, xsArrayGetFloat(gResourceNeeds, cResourceWood) + 100.0);
         xsArraySetFloat(
             gResourceNeeds,
             cResourceGold,
             xsArrayGetFloat(gResourceNeeds, cResourceGold) - aiGetMarketSellCost(cResourceWood));
         debugEconomy("Selling 100 food.");
         goAgain = true;
      }

      if (xsArrayGetFloat(gResourceNeeds, cResourceGold) < -1000.0)
      {
         if (xsArrayGetFloat(gResourceNeeds, cResourceFood) > 100.0 && aiResourceIsLocked(cResourceFood) == false)
         {
            aiBuyResourceOnMarket(cResourceFood);
            xsArraySetFloat(gResourceNeeds, cResourceGold, xsArrayGetFloat(gResourceNeeds, cResourceGold) + 100.0);
            xsArraySetFloat(
                gResourceNeeds,
                cResourceFood,
                xsArrayGetFloat(gResourceNeeds, cResourceFood) - aiGetMarketBuyCost(cResourceFood));
            debugEconomy("Buying 100 food.");
            goAgain = true;
         }
         else if (xsArrayGetFloat(gResourceNeeds, cResourceWood) > 100.0 && aiResourceIsLocked(cResourceWood) == false)
         {
            aiBuyResourceOnMarket(cResourceWood);
            xsArraySetFloat(gResourceNeeds, cResourceGold, xsArrayGetFloat(gResourceNeeds, cResourceGold) + 100.0);
            xsArraySetFloat(
                gResourceNeeds,
                cResourceWood,
                xsArrayGetFloat(gResourceNeeds, cResourceWood) - aiGetMarketBuyCost(cResourceWood));
            debugEconomy("Buying 100 wood.");
            goAgain = true;
         }
      }
   }

   // Buy wood with gold if disabled wood gathering.
   if (gDisableWoods == true && aiResourceIsLocked(cResourceWood) == false)
   {
      static float lastTotalGoldAmount = 0.0;
      float totalGoldAmount = kbTotalResourceGet(cResourceGold);

      if ((totalGoldAmount - lastTotalGoldAmount) * gGoldPercentageToBuyForWood >= aiGetMarketBuyCost(cResourceWood))
      {
         aiBuyResourceOnMarket(cResourceWood);
         lastTotalGoldAmount = totalGoldAmount;
         debugEconomy("Buying 100 wood.");
         goAgain = true;
      }
   }

   if ((goAgain == true) && (fastMode == false))
   {
      // We need to set fast mode
      xsSetRuleMinIntervalSelf(1);
      debugEconomy("Going to fast mode.");
      fastMode = true;
   }
   if ((goAgain == false) && (fastMode == true))
   {
      // We need to slow down.
      xsSetRuleMinIntervalSelf(10);
      debugEconomy("Resource manager going to slow mode.");
      fastMode = false;
   }
}

//==============================================================================
// rule startFishing
//==============================================================================
rule startFishing
inactive
minInterval 15
{
   //  Check to see if we have spotted a fish reasonably close to our water spawn flag.
   if (gHaveWaterSpawnFlag == true)
   {
      static int fishQuery = -1;
      int fish = -1;
      int fishAreaGroup = -1;
      int flagAreaGroup = -1;

      flagAreaGroup = kbAreaGroupGetIDByPosition(gWaterSpawnFlagPosition);

      if (fishQuery < 0)
      {
         fishQuery = kbUnitQueryCreate("fish query");
         kbUnitQuerySetIgnoreKnockedOutUnits(fishQuery, true);
         kbUnitQuerySetPlayerID(fishQuery, 0);
         kbUnitQuerySetUnitType(fishQuery, cUnitTypeAbstractFish);
         kbUnitQuerySetState(fishQuery, cUnitStateAny);
         kbUnitQuerySetPosition(fishQuery, gWaterSpawnFlagPosition);
         kbUnitQuerySetMaximumDistance(fishQuery, 100.0);
         kbUnitQuerySetAscendingSort(fishQuery, true);
      }
      kbUnitQueryResetResults(fishQuery);
      if (kbUnitQueryExecute(fishQuery) > 0)
         fish = kbUnitQueryGetResult(fishQuery, 0); // Get the nearest fish.
      if (fish >= 0)
         fishAreaGroup = kbAreaGroupGetIDByPosition(kbUnitGetPosition(fish));
      if ((fish >= 0) && (fishAreaGroup == flagAreaGroup))
         debugEconomy("Found fish # " + fish + " at " + kbUnitGetPosition(fish));
      else
      {
         debugEconomy("No fish found near " + gWaterSpawnFlagPosition);
         return; // No fish near enough, keep looking
      }
   } // else, no flag, so just go ahead.

   if (fish < 0)
      fish = getUnit(cUnitTypeAbstractFish, 0, cUnitStateAny); // need to have one fish visible

   if (fish < 0)
      return;

   debugEconomy("*** Creating maintain plan for fishing boats.");
   // We make a plan to maintain 0 fishing boats, fishManager actually decide when we really start fishing.
   gFishingBoatMaintainPlan = createSimpleMaintainPlan(gFishingUnit, 0, true, kbBaseGetMainID(cMyID), 1);

   createWaterExplorePlan();
   xsEnableRule("fishManager");
   xsDisableSelf();
}

//==============================================================================
// rule fishManager
//
// Updates fishing boat maintain plan
//==============================================================================
rule fishManager
inactive
minInterval 30
{
   if (gTimeToFish == false)
   {
      // Don't fish until age2 transition.
      if (kbGetAge() < cAge2 && agingUp() == false)
         return;
      static int randomizer = -1;
      if (randomizer < 0)
         randomizer = aiRandInt(10);
      if (btRushBoom <= 0.0 && randomizer < 3)
         gTimeToFish = true;
      else
         return;
   }

   if (kbUnitCount(cMyID, gDockUnit, cUnitStateAlive) < 1)
   {
      aiPlanSetVariableInt(gFishingBoatMaintainPlan, cTrainPlanNumberToMaintain, 0, 0);
      return;
   }

   static float maxDistance = 80.0;
   const int cMaxFishingBoats = 30;
   int numberFishingBoats = kbUnitCount(cMyID, gFishingUnit, cUnitStateABQ);
   int numberFoodFishingBoats = kbGetAmountValidResourcesByLocation(
                                    gNavyVec, cResourceFood, cAIResourceSubTypeFish, maxDistance) /
                                400.0;
   int numberGoldFishingBoats = getUnitCountByLocation(cUnitTypeAbstractWhale, 0, cUnitStateAny, gNavyVec, maxDistance) * 4;

   if (numberFishingBoats > numberFoodFishingBoats || numberFishingBoats > numberGoldFishingBoats)
   {
      maxDistance = maxDistance + 30.0;
      return;
   }

   if (numberFishingBoats < numberFoodFishingBoats)
      numberFishingBoats = numberFoodFishingBoats;
   if (numberFishingBoats < numberGoldFishingBoats)
      numberFishingBoats = numberGoldFishingBoats;
   if (numberFishingBoats > cMaxFishingBoats)
      numberFishingBoats = cMaxFishingBoats;

   int fishingBoatQuery = createSimpleUnitQuery(gFishingUnit, cMyID, cUnitStateAlive);
   kbUnitQuerySetActionType(fishingBoatQuery, cActionTypeIdle);
   int numberFound = kbUnitQueryExecute(fishingBoatQuery);

   if (numberFound > 1)
      numberFishingBoats = 0;

   if ((gStartOnDifferentIslands == true) && (numberFishingBoats < 1))
   {
      numberFishingBoats = 1; // Train at least 1 Fishing Boat on these maps to explore.
   }

   aiPlanSetVariableInt(gFishingBoatMaintainPlan, cTrainPlanNumberToMaintain, 0, numberFishingBoats);
   aiPlanSetDesiredResourcePriority(gFishingBoatMaintainPlan, 70);
}

//==============================================================================
// addMillBuildPlan
//==============================================================================
void addMillBuildPlan(void)
{
   int numberToBuild = 1;

   if (gFarmUnit == cUnitTypedeField)
      numberToBuild = 4;

   if (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, gFarmUnit) >= 0)
      return;

   if (gFarmFoodTactic >= 0)
   {
      // We have enough Rice Paddies / Fields.
      if (kbUnitCount(cMyID, gEconUnit, cUnitStateABQ) < 
       (kbUnitCount(cMyID, gFarmUnit, cUnitStateABQ) - 1) * cMaxSettlersPerFarm)
         return;
   }
   else
   {
      // We have enough Mills.
      if (kbUnitCount(cMyID, gEconUnit, cUnitStateABQ) <
       kbUnitCount(cMyID, gFarmUnit, cUnitStateABQ) * cMaxSettlersPerFarm)
         return;
   }

   createSimpleBuildPlan(gFarmUnit, numberToBuild, 70, true, cEconomyEscrowID, kbBaseGetMainID(cMyID), 1);
}

//==============================================================================
// addPlantationBuildPlan
//==============================================================================
void addPlantationBuildPlan(void)
{
   int numberToBuild = 1;

   if (gPlantationUnit == cUnitTypedeField)
      numberToBuild = 4;

   if (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, gPlantationUnit) >= 0)
      return;

   if (gFarmGoldTactic >= 0)
   {
      // we have enough rice paddies
      if (kbUnitCount(cMyID, gEconUnit, cUnitStateABQ) <
          (kbUnitCount(cMyID, gPlantationUnit, cUnitStateABQ) - 1) * cMaxSettlersPerPlantation)
         return;
   }
   else
   {
      // we have enough plantations
      if (kbUnitCount(cMyID, gEconUnit, cUnitStateABQ) <
          kbUnitCount(cMyID, gPlantationUnit, cUnitStateABQ) * cMaxSettlersPerPlantation)
         return;
   }

   createSimpleBuildPlan(gPlantationUnit, numberToBuild, 70, true, cEconomyEscrowID, kbBaseGetMainID(cMyID), 1);
}

//==============================================================================
// addTribalMarketplaceBuildPlan
//==============================================================================
void addTribalMarketplaceBuildPlan(void)
{
   if (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypedeFurTrade) >= 0)
      return;

   int buildPlanID = createSimpleBuildPlan(cUnitTypedeFurTrade, 1, 70, true, cEconomyEscrowID, kbBaseGetMainID(cMyID), 1);
   aiPlanSetDesiredResourcePriority(buildPlanID,
                                    60); // above average but below villager production.
}

//==============================================================================
// removeMillBuildPlan
//==============================================================================
void removeMillBuildPlan(void)
{
   int numberToBuild = 1;

   if (gFarmUnit == cUnitTypedeField)
      numberToBuild = 4;

   if (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, gFarmUnit) >= 0)
      return;

   int planID = -1;
   int numPlans = 0;

   if (numberToBuild == 1)
   {
      planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, gFarmUnit);
      if (planID >= 0 && aiPlanGetState(planID) != cPlanStateBuild)
         aiPlanDestroy(planID);
   }
   else
   {
      numPlans = aiPlanGetActiveCount();
      for (i = 0; < numPlans)
      {
         planID = aiPlanGetIDByActiveIndex(i);
         if (aiPlanGetType(planID) != cPlanBuild || aiPlanGetState(planID) == cPlanStateBuild)
            continue;
         if (aiPlanGetVariableInt(planID, cBuildPlanBuildingTypeID, 0) != gFarmUnit)
            continue;
         aiPlanDestroy(planID);
      }
   }
}

//==============================================================================
// removePlantationBuildPlan
//==============================================================================
void removePlantationBuildPlan(void)
{
   int numberToBuild = 1;

   if (gPlantationUnit == cUnitTypedeField)
      numberToBuild = 4;

   if (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, gPlantationUnit) >= 0)
      return;

   int planID = -1;
   int numPlans = 0;

   if (numberToBuild == 1)
   {
      planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, gPlantationUnit);
      if (planID >= 0 && aiPlanGetState(planID) != cPlanStateBuild)
         aiPlanDestroy(planID);
   }
   else
   {
      numPlans = aiPlanGetActiveCount();
      for (i = 0; < numPlans)
      {
         planID = aiPlanGetIDByActiveIndex(i);
         if (aiPlanGetType(planID) != cPlanBuild || aiPlanGetState(planID) == cPlanStateBuild)
            continue;
         if (aiPlanGetVariableInt(planID, cBuildPlanBuildingTypeID, 0) != gPlantationUnit)
            continue;
         aiPlanDestroy(planID);
      }
   }
}

//==============================================================================
// updateFoodBreakdown
//==============================================================================
void updateFoodBreakdown()
{
   if (cvOkToGatherFood == false)
   {
      gGatherPlanNumHuntPlans = 0;
      gGatherPlanNumBerryPlans = 0;
      gGatherPlanNumMillPlans = 0;
      gGatherPlanNumFishPlans = 0;
      return;
   }

   // Return when we run out of attempts
   // We still need to update when there are idle villagers to assign them to new gather plans.
   int attempts = xsArrayGetInt(gAdjustBreakdownAttempts, cResourceFood);
   if (attempts <= 0)
   {
      if (getNumberIdleVillagers(true) < 3)
         return;
   }
   else
   {
      xsArraySetInt(gAdjustBreakdownAttempts, cResourceFood, attempts - 1);
   }

   int numberMills = 0;

   if (gFarmFoodTactic >= 0)
   {
      // We only make sure the tactic is correct for fully built farms.
      numberMills = kbUnitCount(cMyID, gFarmUnit, cUnitStateBuilding) + 
       getUnitCountByTactic(gFarmUnit, cMyID, cUnitStateAlive, gFarmFoodTactic);
   }
   else
   {
      numberMills = kbUnitCount(cMyID, gFarmUnit, cUnitStateABQ);
   }

   // Get an estimate for the number of food gatherers.
   // Figure out how many mill plans that should be, and how many villagers will be farming.
   // Look at how many hunt plans we'd have, and see if that's a reasonable number.

   int numFarmGatherers = getNumberPlanGatherers(cResourceFood, cAIResourceSubTypeFarm);
   int numHuntBerryGatherers = getNumberPlanGatherers(cResourceFood, cAIResourceSubTypeHunt) +
                               getNumberPlanGatherers(cResourceFood, cAIResourceSubTypeEasy);
   float foodPercentage = aiGetResourcePercentage(cResourceFood);
   float actualFoodPercentage = aiGetActualResourcePercentage(cResourceFood);
   // Can we max out the farms?
   if ((foodPercentage > 0.0 || actualFoodPercentage > 0.0) &&
       (numFarmGatherers >= (numberMills * cMaxSettlersPerFarm) ||
        (numFarmGatherers >= (numberMills * cMaxSettlersPerFarm - 3) && numHuntBerryGatherers > 0)))
   {
      if (gTimeToFarm == true)
         addMillBuildPlan(); // If we don't have enough mills, and we need to farm, and we're not building one, build
                             // one.
   }
   else
   {
      // We can't fill the farms
      if (foodPercentage == 0.0)
         removeMillBuildPlan();
   }

   // Anything greater than 0 means we allow gatherers on the associated resource breakdown.
   gGatherPlanNumHuntPlans = 1;
   gGatherPlanNumBerryPlans = 1;
   gGatherPlanNumMillPlans = 1;
   if (kbUnitCount(cMyID, cUnitTypeAbstractFishingBoat, cUnitStateABQ) > 0)
      gGatherPlanNumFishPlans = 1;
   else
      gGatherPlanNumFishPlans = 0;
}

//==============================================================================
// updateWoodBreakdown
//==============================================================================
void updateWoodBreakdown()
{
   if ((cvOkToGatherWood == false) || (gDisableWoods == true))
   {
      gGatherPlanNumWoodPlans = 0;
      return;
   }

   // Don't create resource breakdowns for invalid bases.
   int mainBaseID = kbBaseGetMainID(cMyID);
   if (mainBaseID < 0)
      return;

   // Return when we run out of attempts
   // We still need to update when there are idle villagers to assign them to new gather plans.
   int attempts = xsArrayGetInt(gAdjustBreakdownAttempts, cResourceWood);
   int numberIdleVillagers = getNumberIdleVillagers(false);
   if (attempts <= 0)
   {
      if (numberIdleVillagers < 3)
         return;
   }
   else
   {
      xsArraySetInt(gAdjustBreakdownAttempts, cResourceWood, attempts - 1);
   }

   // Anything greater than 0 means we allow gatherers on the associated resource breakdown.
   gGatherPlanNumWoodPlans = 1;
}

//==============================================================================
// updateGoldBreakdown
//==============================================================================
void updateGoldBreakdown()
{
   if (cvOkToGatherGold == false)
   {
      gGatherPlanNumMinePlans = 0;
      gGatherPlanNumEstatePlans = 0;
      gGatherPlanNumWhalePlans = 0;
      return;
   }

   // Don't create resource breakdowns for invalid bases.
   int mainBaseID = kbBaseGetMainID(cMyID);
   if (mainBaseID < 0)
      return;

   // Return when we run out of attempts
   // We still need to update when there are idle villagers to assign them to new gather plans.
   int attempts = xsArrayGetInt(gAdjustBreakdownAttempts, cResourceGold);
   if (attempts <= 0)
   {
      if (getNumberIdleVillagers(false) < 3)
         return;
   }
   else
   {
      xsArraySetInt(gAdjustBreakdownAttempts, cResourceGold, attempts - 1);
   }

   int numberPlants = 0;
   int numGoldGatherers = aiGetNumberDesiredGatherers(cResourceGold);
   int numPlantGatherers = getNumberPlanGatherers(cResourceGold, cAIResourceSubTypeFarm);
   int numMineGatherers = getNumberPlanGatherers(cResourceGold, cAIResourceSubTypeEasy);
   // We didn't supply enough plans to get the desired resource percentage.
   float goldPercentage = aiGetResourcePercentage(cResourceGold);
   float actualGoldPercentage = aiGetActualResourcePercentage(cResourceGold);

   if (gFarmGoldTactic >= 0)
   {
      // We only make sure the tactic is correct for fully built farms.
      numberPlants = kbUnitCount(cMyID, gPlantationUnit, cUnitStateBuilding) +
       getUnitCountByTactic(gPlantationUnit, cMyID, cUnitStateAlive, gFarmGoldTactic);
   }
   else
   {
      numberPlants = kbUnitCount(cMyID, gPlantationUnit, cUnitStateABQ);
   }

   if ((goldPercentage > 0.0 || actualGoldPercentage > 0.0) &&
       (numPlantGatherers >= (numberPlants * cMaxSettlersPerPlantation) ||
        (numPlantGatherers >= (numberPlants * cMaxSettlersPerPlantation - 3) &&
         numMineGatherers > 0))) // Can we max out the farms?
   {
      if (gTimeForPlantations == true)
         addPlantationBuildPlan(); // If we don't have enough plantations, and we need to farm, and we're not building
                                   // one, build one.
   }
   else
   { // We can't fill the farms
      if (goldPercentage == 0.0)
         removePlantationBuildPlan();
   }

   if (cMyCiv == cCivXPIroquois || cMyCiv == cCivXPSioux)
   {
      int numTribalMarketplace = kbUnitCount(cMyID, cUnitTypedeFurTrade, cUnitStateABQ);
      const int cMaxSettlersPerTribalMarketplace = 10;
      if ((goldPercentage > 0.0 || actualGoldPercentage > 0.0) &&
          (numTribalMarketplace == 0 || numMineGatherers >= (numTribalMarketplace * cMaxSettlersPerTribalMarketplace - 5)))
      {
         addTribalMarketplaceBuildPlan();
      }
   }

   // Anything greater than 0 means we allow gatherers on the associated resource breakdown.
   gGatherPlanNumMinePlans = 1;
   gGatherPlanNumEstatePlans = 1;
   if (kbUnitCount(cMyID, cUnitTypeAbstractFishingBoat, cUnitStateABQ) > 0)
      gGatherPlanNumWhalePlans = 1;
   else
      gGatherPlanNumWhalePlans = 0;
}

rule updateResourceBreakdowns
inactive
group tcComplete
minInterval 29
{
   static int executionCount = 0;
   int mainBaseID = kbBaseGetMainID(cMyID);

   switch (executionCount)
   {
   case 0:
   {
      updateFoodBreakdown();
      xsSetRuleMinIntervalSelf(1);
      break;
   }
   case 1:
   {
      updateWoodBreakdown();
      break;
   }
   case 2:
   {
      updateGoldBreakdown();
      xsSetRuleMinIntervalSelf(29);

      // Update resource breakdowns in one go to reduce chance villagers move around in a short timespan.
      if (mainBaseID >= 0)
      {
         // food
         aiSetResourceBreakdown(
             cResourceFood, cAIResourceSubTypeEasy, gGatherPlanNumBerryPlans, gGatherPlanPriorityBerry, 1.0, mainBaseID);
         aiSetResourceBreakdown(
             cResourceFood, cAIResourceSubTypeHunt, gGatherPlanNumHuntPlans, gGatherPlanPriorityHunt, 1.0, mainBaseID);
         aiSetResourceBreakdown(
             cResourceFood, cAIResourceSubTypeFarm, gGatherPlanNumMillPlans, gGatherPlanPriorityMill, 1.0, mainBaseID, 999.0);
         aiSetResourceBreakdown(
             cResourceFood, cAIResourceSubTypeFish, gGatherPlanNumFishPlans, gGatherPlanPriorityFish, 1.0, mainBaseID, 999.0);

         // wood
         aiSetResourceBreakdown(
             cResourceWood, cAIResourceSubTypeEasy, gGatherPlanNumWoodPlans, gGatherPlanPriorityWood, 1.0, mainBaseID);

         // gold
         aiSetResourceBreakdown(
             cResourceGold, cAIResourceSubTypeEasy, gGatherPlanNumMinePlans, gGatherPlanPriorityMine, 1.0, mainBaseID);
         aiSetResourceBreakdown(
             cResourceGold,
             cAIResourceSubTypeFarm,
             gGatherPlanNumEstatePlans,
             gGatherPlanPriorityEstate,
             1.0,
             mainBaseID,
             999.0);
         aiSetResourceBreakdown(
             cResourceGold, cAIResourceSubTypeFish, gGatherPlanNumWhalePlans, gGatherPlanPriorityWhale, 1.0, mainBaseID, 999.0);
      }
      break;
   }
   }

   executionCount = (executionCount + 1) % 3;
}

//==============================================================================
// initResourceBreakdowns()
//==============================================================================
void initResourceBreakdowns()
{
   // Set initial gatherer percentages.
   aiSetResourcePercentage(cResourceFood, false, 1.0);
   aiSetResourcePercentage(cResourceWood, false, 0.0);
   aiSetResourcePercentage(cResourceGold, false, 0.0);

   if (cMyCiv == cCivDutch)
   {
      aiSetResourcePercentage(cResourceFood, false, 0.0);
      aiSetResourcePercentage(cResourceGold, false, 1.0);
   }
   else if (cMyCiv == cCivIndians)
   {
      aiSetResourcePercentage(cResourceFood, false, 0.0);
      aiSetResourcePercentage(cResourceWood, false, 1.0);
   }

   // Set up the initial resource breakdowns.
   int mainBaseID = kbBaseGetMainID(cMyID);
   bool hasFishingBoats = kbUnitCount(cMyID, cUnitTypeAbstractFishingBoat, cUnitStateAlive) > 0;

   if (mainBaseID >= 0) // Don't bother if we don't have a main base
   {
      if (cvOkToGatherFood == true)
      {
         if ((cMyCiv != cCivJapanese) && (cMyCiv != cCivSPCJapanese) && (cMyCiv != cCivSPCJapaneseEnemy))
         {
            aiSetResourceBreakdown(
                cResourceFood,
                cAIResourceSubTypeEasy,
                0,
                49,
                1.0,
                mainBaseID); // All on easy hunting food at start
            aiSetResourceBreakdown(
                cResourceFood,
                cAIResourceSubTypeHunt,
                1,
                49,
                1.0,
                mainBaseID); // All on easy hunting food at start
         }
         else
         {
            aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeEasy, 1, 49, 1.0,
                                   mainBaseID); // All on easy food at start
            aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeHunt, 0, 49, 1.0, mainBaseID);
         }
         aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeHerdable, 0, 24, 0.0, mainBaseID);
         aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeHuntAggressive, 0, 49, 0.0, mainBaseID);
         if (hasFishingBoats == true)
            aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeFish, 1, 49, 0.0, mainBaseID);
         else
            aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeFish, 0, 49, 0.0, mainBaseID);
         aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeFarm, 0, 51, 0.0, mainBaseID);
      }
      if (cvOkToGatherWood == true)
         aiSetResourceBreakdown(cResourceWood, cAIResourceSubTypeEasy, 1, 50, 1.0, mainBaseID);
      if (cvOkToGatherGold == true)
      {
         aiSetResourceBreakdown(cResourceGold, cAIResourceSubTypeEasy, 1, 55, 1.0, mainBaseID);
         if (hasFishingBoats == true)
            aiSetResourceBreakdown(cResourceGold, cAIResourceSubTypeFish, 1, 49, 0.0, mainBaseID);
         else
            aiSetResourceBreakdown(cResourceGold, cAIResourceSubTypeFish, 0, 49, 0.0, mainBaseID);
      }
   }
   
   // Create a crate gather plan fast so we can deal with the initial crates.
   if (civIsAfrican() == false)
   {
      crateMonitor();
   }
}

//==============================================================================
// initResourceBreakdownsDelay
//
// Delay resource breakdowns until cherry orchard is built
//==============================================================================
rule initResourceBreakdownsDelay
inactive
highFrequency
{
   if (kbUnitCount(cMyID, cUnitTypeypBerryBuilding, cUnitStateAlive) < 1)
      return;
   initResourceBreakdowns();
   xsDisableSelf();
}

rule earlySlaughterMonitor
inactive
minInterval 1
{
   if (cvOkToGatherFood == false)
      return;

   int cattleID = -1;

   if (cattleID < 0)
   {
      vector loc = kbUnitGetPosition(getUnit(cUnitTypeTownCenter));
      cattleID = getUnitByLocation(cUnitTypedeAutoSangaCattle, cPlayerRelationAny, cUnitStateAny, loc, 10.0);
      if (cattleID < 0)
         cattleID = getUnitByLocation(cUnitTypedeAutoZebuCattle, cPlayerRelationAny, cUnitStateAny, loc, 10.0);
   }

   static int planID = -1;

   if (planID < 0)
   {
      planID = aiPlanCreate("Early cattle slaughter plan", cPlanReserve);
      aiPlanAddUnitType(planID, gEconUnit, 5, 5, 5);
      aiPlanSetDesiredPriority(planID, 95);
      aiPlanSetActive(planID);
   }

   if (cattleID < 0 || kbUnitGetPosition(cattleID) == cInvalidVector)
   {
      aiPlanDestroy(planID);
      xsDisableSelf();
   }
   else
   {
      for (i = 0; < 5)
      {
         int workerUnitID = aiPlanGetUnitByIndex(planID, i);
         aiTaskUnitWork(workerUnitID, cattleID);
      }
   }
}

void updateResources()
{
   int mainBaseID = kbBaseGetMainID(cMyID);
   float maxDistance = kbBaseGetMaximumResourceDistance(cMyID, mainBaseID);
   vector mainBaseLocation = kbBaseGetLocation(cMyID, mainBaseID);
   float newMaxDistance = 0.0;
   static bool searchAllAreaGroups = false;
   static int lastBlacklistResourceTime = 0;
   int numResources = kbResourceGetNumber();

   if (mainBaseID < 0)
      return;
   // when we are gathering natural resources over this distance, start farming.
   const float cFarmNaturalResourceDistance = 50.0;
   // max distance to gather natural resources.
   const float cMaxNaturalResourceDistance = 80.0;
   int time = xsGetTime();
   int numberFarms = 0;
   int numberPlants = 0;
   const int cCanExceedMaxDistanceFood = 1;
   const int cCanExceedMaxDistanceWood = 2;
   const int cCanExceedMaxDistanceGold = 4;
   int canExceedMaxDistance = 0;
   int unitID = -1;
   vector location = cInvalidVector;
   int baseID = -1;

   if (time <= 5000)
      return;

   ValidResourceInfo foodInfo = getValidResourceInfo(cResourceFood, maxDistance, searchAllAreaGroups);
   ValidResourceInfo woodInfo = getValidResourceInfo(cResourceWood, maxDistance, searchAllAreaGroups);
   ValidResourceInfo goldInfo = getValidResourceInfo(cResourceGold, maxDistance, searchAllAreaGroups);

   // debugEconomy("       Resources:   Food " + foodAmount + ", Wood " + woodAmount + ", Gold " + goldAmount);
   debugEconomy("    Per gatherer:   Food " + foodInfo.amountPerGatherer + ", Wood " + woodInfo.amountPerGatherer + ", Gold " + goldInfo.amountPerGatherer);
   debugEconomy("    Estimated gatherers:   Food " + foodInfo.numEstimatedGatherers + ", Wood " + woodInfo.numEstimatedGatherers + ", Gold " + goldInfo.numEstimatedGatherers);
   debugEconomy("    Resource Amount:   Food " + foodInfo.amount + ", Wood " + woodInfo.amount + ", Gold " + goldInfo.amount);

   gLowOnResources = false;
   gDisableWoods = false;

   if (time > 120000)
   {
      if ((foodInfo.amountPerGatherer < cMinResourcePerGatherer) ||
          (woodInfo.amountPerGatherer < cMinResourcePerGatherer) ||
          (goldInfo.amountPerGatherer < cMinResourcePerGatherer))
      {
         if (searchAllAreaGroups == true)
            gLowOnResources = true;
         else if (gIslandMap == true)
         {
            // starting from next time, considering resources on other islands.
            searchAllAreaGroups = true;
            return;
         }

         // When we run out of resources, but have no farms to gather from, allow exceeding max resource distance.
         if (maxDistance >= cMaxNaturalResourceDistance)
         {
            if (foodInfo.amountPerGatherer < (cMinResourcePerGatherer / 2))
            {
               if (gTimeToFarm == true)
                  numberFarms = kbUnitCount(cMyID, gFarmUnit, cUnitStateAlive);
               if (numberFarms == 0)
                  canExceedMaxDistance |= cCanExceedMaxDistanceFood;
            }
            if (woodInfo.amountPerGatherer < (cMinResourcePerGatherer / 2))
            {
               gDisableWoods =
                   (((gRevolutionType & cRevolutionFinland) == 0) && (kbUnitCount(cMyID, gMarketUnit, cUnitStateAlive) > 0));
               if (gDisableWoods == false)
                  canExceedMaxDistance |= cCanExceedMaxDistanceWood;
            }
            if (goldInfo.amountPerGatherer < (cMinResourcePerGatherer / 2))
            {
               if (gTimeForPlantations == true)
                  numberPlants = kbUnitCount(cMyID, gPlantationUnit, cUnitStateAlive);
               if (numberPlants == 0)
                  canExceedMaxDistance |= cCanExceedMaxDistanceGold;
            }
         }

         // Increase max distance.
         newMaxDistance = maxDistance + 15.0;
         if ((canExceedMaxDistance != 0) && (newMaxDistance > cMaxNaturalResourceDistance))
            newMaxDistance = cMaxNaturalResourceDistance;
         kbBaseSetMaximumResourceDistance(cMyID, mainBaseID, newMaxDistance);
      }
   }

   // After 10 minutes into the game, check for resources to blacklist every 60 seconds.
   if ((time > 600000) && (time - lastBlacklistResourceTime >= 60000))
   {
      int resourceID = -1;
      int resourceType = -1;
      int resourceSubType = -1;
      bool blacklisted = false;

      // go through all resources, blacklist any too close to enemy bases.
      for (i = 0; < numResources)
      {
         resourceID = kbResourceGetIDByIndex(i);
         resourceType = kbResourceGetType(resourceID);
         resourceSubType = kbResourceGetSubType(resourceID);

         // Allow all fish and whales on the map for now.
         if (resourceSubType == cAIResourceSubTypeFarm || resourceSubType == cAIResourceSubTypeFish)
            continue;

         blacklisted = false;

         bool checkDistanceToEnemy = true;

         // If we have no resources to gather, don't blacklist.
         // TODO: this check does not work when once we have access to resources previoulsy blacklisted.
         switch (resourceType)
         {
         case cResourceFood:
         {
            if ((canExceedMaxDistance & cCanExceedMaxDistanceFood) != 0 && foodInfo.amountPerGatherer == 0 &&
                (resourceSubType == cAIResourceSubTypeHunt || resourceSubType == cAIResourceSubTypeEasy))
               checkDistanceToEnemy = false;
            break;
         }
         case cResourceWood:
         {
            if ((canExceedMaxDistance & cCanExceedMaxDistanceWood) != 0 && woodInfo.amountPerGatherer == 0 &&
                resourceSubType == cAIResourceSubTypeEasy)
               checkDistanceToEnemy = false;
            break;
         }
         case cResourceGold:
         {
            if ((canExceedMaxDistance & cCanExceedMaxDistanceGold) != 0 && goldInfo.amountPerGatherer == 0 &&
                resourceSubType == cAIResourceSubTypeEasy)
               checkDistanceToEnemy = false;
            break;
         }
         }

         if (checkDistanceToEnemy == true)
         {
            unitID = kbResourceGetUnit(resourceID, 0);
            if (unitID >= 0)
            {
               location = kbUnitGetPosition(unitID);
               baseID = kbFindClosestBase(cPlayerRelationEnemy, location);
               // Closer to enemy base than our main base?
               if (distance(location, mainBaseLocation) > distance(location, kbBaseGetLocation(kbBaseGetOwner(baseID), baseID)))
               {
                  blacklisted = true;
                  debugEconomy("Blacklisting resource " + resourceID + " at " + location);
               }
            }
         }

         kbResourceSetBlacklisted(resourceID, blacklisted);
      }
      lastBlacklistResourceTime = time;
   }

   // We ran out of resources pretty early, find a new base
   /*if (gLowOnResources == true)
      {
      if (xsIsRuleEnabled("findNewBase") == false)
         xsEnableRule("findNewBase");
   }*/

   if ((gTimeToFarm == false) && (time > 120000) &&
       (foodInfo.amountPerGatherer < cMinResourcePerGatherer || maxDistance >= cFarmNaturalResourceDistance) &&
       (gRevolutionType & cRevolutionFinland) == 0)
   {
      // Check within farming distance again as max distance can be increased by other resources running out.
      ValidResourceInfo farmInfo = getValidResourceInfo(cResourceFood, cFarmNaturalResourceDistance, searchAllAreaGroups);
      if (farmInfo.amountPerGatherer < cMinResourcePerGatherer && foodInfo.amountPerGatherer < cMinResourcePerGatherer * 2)
      {
         if ((gCountBerries == false) /*&& (time < 10 * 60 * 1000)*/)
         {
            // Count berries if we decided to farm early.
            gCountBerries = true;
            debugEconomy("We are running out of food resource, berries will now be counted for natural resources remaining.");
            // Call this again to grab the info with berries considered.
            farmInfo = getValidResourceInfo(cResourceFood, cFarmNaturalResourceDistance, searchAllAreaGroups);
         }
         
         if ((gCountBerries == true) && (farmInfo.amountPerGatherer < cMinResourcePerGatherer))
         {
            gTimeToFarm = true;
            debugEconomy("It's time to start farming, maxDistance="+maxDistance+
               ", natural_resource_amount="+farmInfo.amount+", estimated_gatherers="+
               farmInfo.numEstimatedGatherers+", amount_per_gatherer="+farmInfo.amountPerGatherer+
               ", food_per_gatherer="+foodInfo.amountPerGatherer);
         }
      }
   }
   else if ((gTimeToFarm == true) && (gPrioritizeFarms == false))
   {
      // We are in the transition phase, only prioritize farms when amount per gatherer starts running really low.
      if (foodInfo.amountPerGatherer < (cMinResourcePerGatherer / 4))
      {
         gPrioritizeFarms = true;
         debugEconomy("We are almost running out of food, switching to farming completely, natural_resource_amount="+foodInfo.amount+", estimated_gatherers="+
          foodInfo.numEstimatedGatherers+", amount_per_gatherer="+foodInfo.amountPerGatherer);
      }
   }

   if ((gTimeForPlantations == false) &&
       (goldInfo.amountPerGatherer < cMinResourcePerGatherer || maxDistance >= cFarmNaturalResourceDistance) &&
       (gRevolutionType & cRevolutionFinland) == 0 && (civIsAsian() == true || civIsAfrican() == true || kbGetAge() >= cAge3))
   {
      // Check within farming distance again as max distance can be increased by other resources running out.
      ValidResourceInfo estateInfo = getValidResourceInfo(cResourceGold, cFarmNaturalResourceDistance, searchAllAreaGroups);
      if (estateInfo.amountPerGatherer < cMinResourcePerGatherer && goldInfo.amountPerGatherer < cMinResourcePerGatherer * 2)
      {
         gTimeForPlantations = true;
         debugEconomy("It's time to start using estates, maxDistance="+maxDistance+
            ", natural_resource_amount="+estateInfo.amount+", estimated_gatherers="+
            estateInfo.numEstimatedGatherers+", amount_per_gatherer="+estateInfo.amountPerGatherer+
            ", gold_per_gatherer="+goldInfo.amountPerGatherer);
      }
   }
   else if ((gTimeForPlantations == true) && (gPrioritizeEstates == false))
   {
      // We are in the transition phase, only prioritize estates when amount per gatherer starts running really low.
      if (goldInfo.amountPerGatherer < (cMinResourcePerGatherer / 4))
      {
         gPrioritizeEstates = true;
         debugEconomy("We are almost running out of gold, switching to farming completely, natural_resource_amount="+goldInfo.amount+", estimated_gatherers="+
          goldInfo.numEstimatedGatherers+", amount_per_gatherer="+goldInfo.amountPerGatherer);
      }
   }

   if ((gTimeToFish == false) && (gGoodFishingMap == true) && (time > 5000) &&
       (foodInfo.amountPerGatherer < 1.5 * cMinResourcePerGatherer || goldInfo.amountPerGatherer < 1.5 * cMinResourcePerGatherer) &&
       (gRevolutionType & cRevolutionFinland) == 0)
   {
      gTimeToFish = true;
      debugEconomy("It's time to start fishing, maxDistance="+maxDistance);
      debugEconomy("food_natural_resource_amount="+foodInfo.amount+", food_estimated_gatherers="+
       foodInfo.numEstimatedGatherers+", food_amount_per_gatherer="+foodInfo.amountPerGatherer);
      debugEconomy("gold_natural_resource_amount="+goldInfo.amount+", gold_estimated_gatherers="+
       goldInfo.numEstimatedGatherers+", gold_amount_per_gatherer="+goldInfo.amountPerGatherer);
   }
}

//==============================================================================
/*
   econMaster(int mode, int value)

   Performs top-level economic analysis and direction.   Generally called
   by the econMasterRule, it can be called directly for special-event processing.
   EconMasterRule calls it with default parameters, directing it to do a full
   reanalysis.
*/
//==============================================================================
void econMaster(int mode = -1, int value = -1)
{
   static int lastUpdateTime = 0;
   int time = xsGetTime();

   // These functions can be called less frequently than updateResourceDistribution().
   if (time - lastUpdateTime >= 30000)
   {
      // Monitor main base supply of food and gold, activate farming and plantations when resources run low
      updateResources();

      lastUpdateTime = time;
   }

   // Maintain list of possible future econ bases, prioritize them
   // updateEconSiteList(); // TODO

   // Evaluate active base status...are all bases still usable?  Adjust if not.
   // evaluateBases();        // TODO

   // Update forecasts for economic and military expenses.  Set resource
   // exchange rates.
   // updateForecasts();

   // Set desired gatherer ratios.  Spread them out per base, set per-base
   // resource breakdowns.
   // updateGatherers();

   updateResourceDistribution();
}

//==============================================================================
// rule econMasterRule
/*
   This rule calls the econMaster() function on a regular basis.  The
   function is separate so that it may be called with a parameter for
   unscheduled processing based on unexpected events.
*/
//==============================================================================
rule econMasterRule
inactive
group startup
minInterval 10
{
   econMaster();
}

rule slaughterMonitor
inactive
minInterval 15
{
   if (cvOkToGatherFood == false)
      return;

   static int slaughterPlanID = -1;
   int numCattle = -1;
   int gatherersWanted = -1;
   vector mainBaseVec = cInvalidVector;
   int time = xsGetTime();

   // Don't slaughter cattle early on.
   if (((time < 900000) &&
        ((time < 500000) || ((gTimeToFarm == false) && (kbUnitCount(cMyID, cUnitTypeFarm, cUnitStateAlive) <= 0) &&
                             (kbUnitCount(cMyID, cUnitTypeLivestockPen, cUnitStateAlive) <= 0) &&
                             (kbUnitCount(cMyID, cUnitTypeypVillage, cUnitStateAlive) <= 0)))) &&
       (civIsAfrican() == false || time > 300000))
      return;

   // If we have a main base, count the number of herdables in it
   if (kbBaseGetMainID(cMyID) < 0)
      return;

   mainBaseVec = kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID));
   numCattle = getUnitCountByLocation(cUnitTypeHerdable, cPlayerRelationAny, cUnitStateAny, mainBaseVec, 60.0);

   if (numCattle <= 0)
      gatherersWanted = 0;
   else
      gatherersWanted = 2;

   if (aiPlanGetState(slaughterPlanID) == -1)
   {
      debugEconomy("Cattle gather plan " + slaughterPlanID + " is invalid.");
      aiPlanDestroy(slaughterPlanID);
      slaughterPlanID = -1;
   }

   if (slaughterPlanID < 0)
   { // Initialize the plan
      slaughterPlanID = aiPlanCreate("Cattle slaughter", cPlanGather);
      aiPlanSetBaseID(slaughterPlanID, kbBaseGetMainID(cMyID));
      aiPlanSetVariableInt(slaughterPlanID, cGatherPlanResourceUnitTypeFilter, 0, cUnitTypeHerdable);
      aiPlanSetVariableInt(slaughterPlanID, cGatherPlanResourceType, 0, cAllResources);
      aiPlanAddUnitType(
          slaughterPlanID,
          gEconUnit,
          gatherersWanted,
          gatherersWanted,
          2 * gatherersWanted); // 2-4 gatherers if there is cattle
      aiPlanSetDesiredPriority(slaughterPlanID, 86);
      aiPlanSetActive(slaughterPlanID);
      debugEconomy("Activated cattle slaughter plan " + slaughterPlanID);
   }
   else
   {
      aiPlanAddUnitType(
          slaughterPlanID,
          gEconUnit,
          gatherersWanted,
          gatherersWanted,
          2 * gatherersWanted); // 2-4 gatherers if there is cattle
   }
}

rule reInitGatherers
inactive
group tcComplete
minInterval 11
{
   econMaster();
   updateFoodBreakdown(); // Reinit each gatherer breakdown in case initial pass didn't yet have proper "actual"
                          // assignments.
   updateWoodBreakdown();
   updateGoldBreakdown();
   xsDisableSelf();
}

rule herdMonitor
inactive
group startup
minInterval 20
{
   // Activated when a livestock pen is being built.  Wait for completion, and then
   // move the herd plan to the livestock pen.
   if (civIsNative() == true)
   {
      if (kbUnitCount(cMyID, cUnitTypeFarm, cUnitStateAlive) > 0)
      {
         aiPlanSetVariableInt(gHerdPlanID, cHerdPlanBuildingTypeID, 0, cUnitTypeFarm);
         aiPlanSetVariableBool(gHerdPlanID, cHerdPlanUseMultipleBuildings, 0, true);
         return;
      }
   }
   else if (cMyCiv == cCivDEMexicans)
   {
      if (kbUnitCount(cMyID, cUnitTypedeHacienda, cUnitStateAlive) > 0)
      {
         aiPlanSetVariableInt(gHerdPlanID, cHerdPlanBuildingTypeID, 0, cUnitTypedeHacienda);
         aiPlanSetVariableBool(gHerdPlanID, cHerdPlanUseMultipleBuildings, 0, true);
         return;
      }
   }
   else
   {
      if (cMyCiv == cCivJapanese || cMyCiv == cCivSPCJapanese || cMyCiv == cCivSPCJapaneseEnemy)
      {
         if (kbUnitCount(cMyID, cUnitTypeAbstractShrine, cUnitStateAlive) > 0)
         {
            aiPlanSetVariableInt(gHerdPlanID, cHerdPlanBuildingTypeID, 0, cUnitTypeAbstractShrine);
            aiPlanSetVariableBool(gHerdPlanID, cHerdPlanUseMultipleBuildings, 0, true);
            return;
         }
      }
      else
      {
         if (kbUnitCount(cMyID, gLivestockPenUnit, cUnitStateAlive) > 0)
         {
            aiPlanSetVariableInt(gHerdPlanID, cHerdPlanBuildingTypeID, 0, gLivestockPenUnit);
            aiPlanSetVariableBool(gHerdPlanID, cHerdPlanUseMultipleBuildings, 0, true);
            return;
         }
      }
   }

   // Gather at TC as fallback.
   int tcID = getUnit(cUnitTypeTownCenter);
   aiPlanSetVariableInt(gHerdPlanID, cHerdPlanBuildingTypeID, 0, cUnitTypeTownCenter);
   if (aiPlanGetVariableInt(gHerdPlanID, cHerdPlanBuildingID, 0) != tcID)
      aiPlanSetVariableInt(gHerdPlanID, cHerdPlanBuildingID, 0, tcID);
   aiPlanSetVariableBool(gHerdPlanID, cHerdPlanUseMultipleBuildings, 0, false);
}

rule backHerdMonitor
inactive
priority 100
minInterval 10
{
   if (cvOkToGatherFood == false)
      return;

   static int planID = -1;
   static int herdResourceID = -1;
   static int herdUnitID = -1;
   static vector herdUnitPosition = cInvalidVector;
   static float herdUnitHitpoints = 0.0;

   if (gTimeToFarm == true)
   {
      if (planID > 0)
         aiPlanDestroy(planID);
      xsDisableSelf();
      return;
   }

   if (planID < 0)
   {
      planID = aiPlanCreate("Backherd plan", cPlanReserve);
      aiPlanAddUnitType(planID, gEconUnit, 1, 1, 1);
      aiPlanSetDesiredPriority(planID, 95);
   }

   int workerUnitID = aiPlanGetUnitByIndex(planID, 0);

   if (workerUnitID < 0)
      return;

   int numberResources = 0;
   int resourceID = -1;
   int numberUnits = 0;
   int unitID = -1;
   vector position = cInvalidVector;
   float hitpoints = 0.0;
   int mainBaseID = kbBaseGetMainID(cMyID);
   float dist = 0.0;
   float maxDist = kbBaseGetMaximumResourceDistance(cMyID, mainBaseID);
   int baseID = -1;
   int baseOwner = -1;
   vector mainBaseLocation = cInvalidVector;

   // We herd towards our first Granary when we're an African civ (if we have one).
   if (civIsAfrican() == true)
   {
      int granaryID = getUnit(cUnitTypedeGranary, cMyID, cUnitStateABQ);
      if (granaryID != -1)
         mainBaseLocation = kbUnitGetPosition(granaryID);
      else
      {
         aiPlanDestroy(planID);
         planID = -1;
         return;
      }
   }
   else
      mainBaseLocation = kbBaseGetLocation(cMyID, mainBaseID);

   if (herdResourceID < 0)
   {
      int compareAmount = aiGetNumberGatherers(cUnitTypeAbstractVillager, cResourceFood, cAIResourceSubTypeHunt) > 15 ? 2 : 1;
      ValidResourceInfo info = getValidResourceInfo(cResourceFood, 30.0, false);
      if (info.amountPerGatherer >= compareAmount * cMinResourcePerGatherer)
      {
         aiPlanDestroy(planID);
         planID = -1;
         return;
      }

      numberResources = kbResourceGetNumber();
      for (i = 0; < numberResources)
      {
         resourceID = kbResourceGetIDByIndex(i);
         if (kbResourceGetType(resourceID) != cResourceFood || kbResourceGetSubType(resourceID) != cAIResourceSubTypeHunt)
            continue;
         unitID = kbResourceGetUnit(resourceID, 0);
         if (unitID < 0)
            continue;
         position = kbUnitGetPosition(unitID);
         dist = distance(position, mainBaseLocation);
         if (dist < 30.0 || dist >= maxDist)
            continue;
         baseID = kbFindClosestBase(cPlayerRelationAlly, position);
         // dont herd ally's hunts.
         if (baseID >= 0)
         {
            baseOwner = kbBaseGetOwner(baseID);
            if (baseOwner != cMyID)
            {
               dist = distance(position, kbBaseGetLocation(baseOwner, baseID));
               if (dist < 30.0)
                  continue;
            }
         }
         numberUnits = kbResourceGetNumberUnits(resourceID);
         for (j = 0; < numberUnits)
         {
            unitID = kbResourceGetUnit(resourceID, j);
            hitpoints = kbUnitGetCurrentHitpoints(unitID);
            if (unitID < 0 || hitpoints <= 10.0)
            {
               unitID = -1;
               continue;
            }
            break;
         }
         if (unitID < 0)
            continue;
         herdResourceID = resourceID;
         aiPlanSetActive(planID, true);
         xsSetRuleMinIntervalSelf(1);
         xsSetRuleMaxIntervalSelf(1);
         break;
      }
   }

   if (herdResourceID < 0)
   {
      aiPlanDestroy(planID);
      planID = -1;
      return;
   }

   if (herdUnitID < 0)
   {
      unitID = kbResourceGetUnit(herdResourceID, 0);
      position = kbUnitGetPosition(unitID);
      if (distance(position, mainBaseLocation) < 15.0)
      {
         herdResourceID = -1;
         return;
      }
      numberUnits = kbResourceGetNumberUnits(herdResourceID);
      for (i = 0; < numberUnits)
      {
         unitID = kbResourceGetUnit(herdResourceID, i);
         hitpoints = kbUnitGetCurrentHitpoints(unitID);
         if (unitID < 0 || hitpoints <= 10.0)
            continue;

         herdUnitID = unitID;
         herdUnitPosition = kbUnitGetPosition(unitID);
         herdUnitHitpoints = hitpoints;

         aiTaskUnitMove(
             workerUnitID,
             herdUnitPosition + (xsVectorNormalize(herdUnitPosition - mainBaseLocation) * aiRandFloat(16.0, 20.0)));
         aiTaskUnitWork(workerUnitID, herdUnitID, true);
         return;
      }
      herdResourceID = -1;
      return;
   }

   if (herdUnitID < 0)
   {
      herdResourceID = -1;
      xsSetRuleMinIntervalSelf(10);
      xsSetRuleMaxIntervalSelf(20);
      return;
   }

   position = kbUnitGetPosition(herdUnitID);
   if (position != herdUnitPosition)
   {
      herdUnitPosition = position;
      aiTaskUnitMove(
          workerUnitID, herdUnitPosition + (xsVectorNormalize(herdUnitPosition - mainBaseLocation) * aiRandFloat(16.0, 20.0)));
      aiTaskUnitWork(workerUnitID, herdUnitID, true);
      return;
   }

   hitpoints = kbUnitGetCurrentHitpoints(herdUnitID);
   if (hitpoints < herdUnitHitpoints)
   {
      aiTaskUnitMove(workerUnitID, kbUnitGetPosition(workerUnitID));
      herdUnitID = -1;
      herdUnitHitpoints = 0.0;
      return;
   }
}

rule maintainCreeCoureurs
inactive
minInterval 30
{
   static int creePlan = -1;
   int limit = 0;

   if (kbUnitCount(0, cUnitTypeSocketCree, cUnitStateAny) == 0)
      return;

   // Check build limit
   limit = kbGetBuildLimit(cMyID, cUnitTypeCoureurCree);

   if (kbUnitCount(cMyID, cUnitTypeTradingPost, cUnitStateAlive) < 1)
      limit = 0;

   // Create/update maintain plan
   if ((creePlan < 0) && (limit >= 1))
   {
      creePlan = createSimpleMaintainPlan(cUnitTypeCoureurCree, limit, true, kbBaseGetMainID(cMyID), 1);
   }
   else
   {
      aiPlanSetVariableInt(creePlan, cTrainPlanNumberToMaintain, 0, limit);
   }
}

rule maintainBerberNomads
inactive
minInterval 30
{
   static int nomadPlan = -1;
   int limit = 0;

   // Berber Nomads are bad at anything but natural resources, so don't bother with them if we've ran out of those.
   if ((gTimeForPlantations == true) && (gTimeToFarm == true))
   {
      if (nomadPlan > 0)
         aiPlanDestroy(nomadPlan);
      xsDisableSelf();
   }

   if ((cMyCiv != cCivDEHausa) || (kbTechGetStatus(cTechDEAllegianceBerberUnlockShadow) != cTechStatusActive) &&
                                      (kbUnitCount(0, cUnitTypedeSocketBerbers, cUnitStateAny) == 0))
      return;

   // Check build limit.
   limit = kbGetBuildLimit(cMyID, cUnitTypedeNatNomad);

   if ((kbUnitCount(cMyID, cUnitTypeTradingPost, cUnitStateAlive) < 1) &&
       (kbTechGetStatus(cTechDEAllegianceBerberUnlockShadow) != cTechStatusActive))
      limit = 0;

   // Create/update maintain plan.
   if ((nomadPlan < 0) && (limit >= 1))
   {
      nomadPlan = createSimpleMaintainPlan(cUnitTypedeNatNomad, limit, true, kbBaseGetMainID(cMyID), 1);
   }
   else
   {
      aiPlanSetVariableInt(nomadPlan, cUnitTypedeNatNomad, 0, limit);
   }
}

//==============================================================================
// monitorFeeding
// This rule gets activated by the commHandler when a player requests we feed him resources.
// We can only feed resources to one player at a time, so if 2 humans ask us to feed 
// we will only feed the last player who requested it.
// This monitor doesn't send any AI chats because they can get quite spammy in here.
//==============================================================================
rule monitorFeeding
inactive
minInterval 60
{
   // Ignore already eliminated players and reset the global.
   if (kbHasPlayerLost(gFeedGoldTo) == true)
   {
      gFeedGoldTo = 0;
   }
   if (kbHasPlayerLost(gFeedWoodTo) == true)
   {
      gFeedWoodTo = 0;
   }
   if (kbHasPlayerLost(gFeedFoodTo) == true)
   {
      gFeedFoodTo = 0;
   }
   
   // We have no active feeds anymore so disable.
   if ((gFeedGoldTo < 1) && (gFeedWoodTo < 1) && (gFeedFoodTo < 1))
   {
      xsDisableSelf();
   }

   if (gFeedGoldTo > 0)
   {
      if (handleTributeRequest(cResourceGold, gFeedGoldTo) == false)
      {
         debugEconomy("We don't have enough spare Gold to feed player: " + gFeedGoldTo);
      }
   }
   if (gFeedWoodTo > 0)
   {
      if (handleTributeRequest(cResourceWood, gFeedWoodTo) == false)
      {
         debugEconomy("We don't have enough spare Wood to feed player: " + gFeedWoodTo);
      }
   }
   if (gFeedFoodTo > 0)
   {
      if (handleTributeRequest(cResourceFood, gFeedFoodTo) == false)
      {
         debugEconomy("We don't have enough spare Food to feed player: " + gFeedFoodTo);
      }
   }
}

//==============================================================================
/* The 4 Monitors below handle all buildings in the game that can be toggled to 
   generate different resources.
   tradeRouteTacticMonitor, factoryTacticMonitor, porcelainTowerTacticMonitor, shrineTacticMonitor
*/
//==============================================================================

rule tradeRouteTacticMonitor
inactive
minInterval 60
{
   int numberTradingPostsOnRoute = 0;
   int tradingPostID = -1;
   int tradingPostTactic = -1;
   const int crateTypeInfluence = 3;

   for (routeIndex = 0; < gNumberTradeRoutes)
   {
      numberTradingPostsOnRoute = kbTradeRouteGetNumberTradingPosts(routeIndex);
      for (tradingPostIndex = 0; < numberTradingPostsOnRoute)
      {
         tradingPostID = kbTradeRouteGetTradingPostID(routeIndex, tradingPostIndex);
         if (kbUnitGetPlayerID(tradingPostID) == cMyID)
         {
            // Check if the TR is capable of generating resources.
            if ((kbBuildingTechGetStatus(
                     xsArrayGetInt(gTradeRouteUpgrades, cTradeRouteFirstUpgrade + (routeIndex * 2)), tradingPostID) ==
                 cTechStatusActive) ||
                (xsArrayGetInt(gTradeRouteIndexAndType, routeIndex) == cTradeRouteCapturableAfrica) ||
                (xsArrayGetInt(gTradeRouteIndexAndType, routeIndex) == cTradeRouteCapturableAsia))
            {
               if (tradingPostTactic == -1) // If we didn't calculate a tactic yet do so, this carries over for all routes/tps.
               {
                  // Get which resource type should be generated.
                  tradingPostTactic = getMostNeededResource();
                  // 20% Chance for African civs to just set it to Influence when we're below 500 Influence.
                  // Don't do this when we absolutely need wood though.
                  if ((civIsAfrican() == true) && (gGoldPercentageToBuyForWood <= 0.0))
                  {
                     if ((aiRandInt(5) < 1) &&
                         (kbResourceGet(cResourceInfluence) < 500)) 
                     {
                        tradingPostTactic = crateTypeInfluence;
                     }
                  }
                  debugEconomy("Setting all Trading Posts to collect: " +
                     kbGetProtoUnitName(xsArrayGetInt(gTradeRouteCrates, tradingPostTactic + (routeIndex * 4))));
                  aiSetTradingPostUnitType(
                     tradingPostID, xsArrayGetInt(gTradeRouteCrates, tradingPostTactic + (routeIndex * 4)));
               }
               else
               {
                  aiSetTradingPostUnitType(
                     tradingPostID, xsArrayGetInt(gTradeRouteCrates, tradingPostTactic + (routeIndex * 4)));
               }
            }
            else
            {
               break; // This route doesn't have the first upgrade active yet so continue on to the next route.
            }
         }
      }
   }
}

rule factoryTacticMonitor
inactive
mininterval 10
{
   // Define a query to get all matching units
   int factoryQueryID=-1;
   factoryQueryID=kbUnitQueryCreate("factoryGetUnitQuery");
   kbUnitQuerySetIgnoreKnockedOutUnits(factoryQueryID, true);
   if (factoryQueryID != -1)
   {
      kbUnitQuerySetPlayerRelation(factoryQueryID, -1);
      kbUnitQuerySetPlayerID(factoryQueryID, cMyID);
      kbUnitQuerySetUnitType(factoryQueryID, cUnitTypeFactory);
      kbUnitQuerySetState(factoryQueryID, cUnitStateAlive);
      kbUnitQueryResetResults(factoryQueryID);
   }
   int numberFound=kbUnitQueryExecute(factoryQueryID);
   // wait until a factory is found.
   if (numberFound < 1)
     return;
   int index = 0;
   float percentOnFood = aiGetResourceGathererPercentage(cResourceFood, cRGPActual);
   float percentOnWood = aiGetResourceGathererPercentage(cResourceWood, cRGPActual);
   float percentOnGold = aiGetResourceGathererPercentage(cResourceGold, cRGPActual);
   float totalResources = kbResourceGet(cResourceFood) + kbResourceGet(cResourceWood) + kbResourceGet(cResourceGold);
   for (index = 0; < numberFound) 
   {
       if ((kbResourceGet(cResourceFood) < (totalResources / 10.0)) || (kbResourceGet(cResourceFood) < 4000))
          aiUnitSetTactic(kbUnitQueryGetResult(factoryQueryID, index), cTacticFood);
		else
       if ((kbResourceGet(cResourceGold) < (totalResources / 10.0)) || (kbResourceGet(cResourceGold) < 4000))
          aiUnitSetTactic(kbUnitQueryGetResult(factoryQueryID, index), cTacticNormal);
		else
       if ((kbResourceGet(cResourceWood) < (totalResources / 10.0)) || (kbResourceGet(cResourceWood) < 2000))
          aiUnitSetTactic(kbUnitQueryGetResult(factoryQueryID, index), cTacticWood);
		else
			if (kbUnitCount(cMyID, cUnitTypeAbstractArtillery, cUnitStateABQ) < 12)
	      aiUnitSetTactic(kbUnitQueryGetResult(factoryQueryID, index), cTacticCannon);
	  else
          aiUnitSetTactic(kbUnitQueryGetResult(factoryQueryID, index), cTacticWood);
   }
}
rule KanchaTacticMonitor
inactive
mininterval 10
{
      if (kbTechGetStatus(cTechDEHCAutarky) != cTechStatusActive)
	  return;
   // Define a query to get all matching units
   int KanchaQueryID=-1;
   KanchaQueryID=kbUnitQueryCreate("KanchaGetUnitQuery");
   kbUnitQuerySetIgnoreKnockedOutUnits(KanchaQueryID, true);
   if (KanchaQueryID != -1)
   {
      kbUnitQuerySetPlayerRelation(KanchaQueryID, -1);
      kbUnitQuerySetPlayerID(KanchaQueryID, cMyID);
      kbUnitQuerySetUnitType(KanchaQueryID, cUnitTypedeHouseInca);
      kbUnitQuerySetState(KanchaQueryID, cUnitStateAlive);
      kbUnitQueryResetResults(KanchaQueryID);
   }
   int numberFound=kbUnitQueryExecute(KanchaQueryID);
   // wait until a factory is found.
   if (numberFound < 1)
     return;
   int index = 0;
   float percentOnFood = aiGetResourceGathererPercentage(cResourceFood, cRGPActual);
   float percentOnWood = aiGetResourceGathererPercentage(cResourceWood, cRGPActual);
   float percentOnGold = aiGetResourceGathererPercentage(cResourceGold, cRGPActual);
   float totalResources = kbResourceGet(cResourceFood) + kbResourceGet(cResourceWood) + kbResourceGet(cResourceGold);
   if ((kbResourceGet(cResourceFood) < (totalResources / 10.0)) || (kbResourceGet(cResourceFood) < 1000))
   aiUnitSetTactic(kbUnitQueryGetResult(KanchaQueryID, index), cTacticKanchaFood);
   else
   aiUnitSetTactic(kbUnitQueryGetResult(KanchaQueryID, index), cTacticKanchaWood);
}
rule porcelainTowerTacticMonitor
inactive
group tcComplete
mininterval 60
{
   // Disable rule for anybody but Chinese
   if (cMyCiv != cCivChinese)
   {
      xsDisableSelf();
      return;
   }
   int porcelainTowerType = -1;
   static int resourceType = -1;
   // Check for porcelain tower
   if (kbUnitCount(cMyID, cUnitTypeypWCPorcelainTower2, cUnitStateAlive) > 0)
   {
      porcelainTowerType = cUnitTypeypWCPorcelainTower2;
   }
   else if (kbUnitCount(cMyID, cUnitTypeypWCPorcelainTower3, cUnitStateAlive) > 0)
   {
      porcelainTowerType = cUnitTypeypWCPorcelainTower3;
   }
   else if (kbUnitCount(cMyID, cUnitTypeypWCPorcelainTower4, cUnitStateAlive) > 0)
   {
      porcelainTowerType = cUnitTypeypWCPorcelainTower4;
   }
   else if (kbUnitCount(cMyID, cUnitTypeypWCPorcelainTower5, cUnitStateAlive) > 0)
   {
      porcelainTowerType = cUnitTypeypWCPorcelainTower5;
   }
   if (porcelainTowerType > 0)
   {
      int porcelainTowerQueryID = -1;
      porcelainTowerQueryID = kbUnitQueryCreate("porcelainTowerQueryID");
      kbUnitQuerySetIgnoreKnockedOutUnits(porcelainTowerQueryID, true);
      if (porcelainTowerQueryID != -1)
      {
         kbUnitQuerySetPlayerRelation(porcelainTowerQueryID, -1);
         kbUnitQuerySetPlayerID(porcelainTowerQueryID, cMyID);
         kbUnitQuerySetUnitType(porcelainTowerQueryID, porcelainTowerType);
         kbUnitQuerySetState(porcelainTowerQueryID, cUnitStateAlive);
         kbUnitQueryResetResults(porcelainTowerQueryID);
         int numberFound = kbUnitQueryExecute(porcelainTowerQueryID);
         if (numberFound > 0)
         {
            // Default to all, adjust as appropriate.
            int porcelainTowerTactic = cTacticWonderRainbow;
            // Focus on food before Age 3, any non-excess resource afterwards (focus on wood and gold).
            if (kbGetAge() < cAge3)
            {
               porcelainTowerTactic = cTacticWonderFood;
            }
            else if (kbResourceGet(cResourceGold) < 2000)
            {
               porcelainTowerTactic = cTacticWonderCoin;
            }
            else if (kbResourceGet(cResourceWood) < 2000)
            {
               porcelainTowerTactic = cTacticWonderWood;
            }
            else if (kbResourceGet(cResourceFood) < 2000)
            {
               porcelainTowerTactic = cTacticWonderFood;
            }
            float totalResources =
                kbResourceGet(cResourceFood) + kbResourceGet(cResourceWood) + kbResourceGet(cResourceGold);
            // Check for resource imbalances, except when we're short on everything.
            if (totalResources >= 900.0)
            {
               if (kbResourceGet(cResourceFood) < (totalResources / 9.0))
               {
                  porcelainTowerTactic = cTacticWonderFood;
               }
               if (kbResourceGet(cResourceGold) < (totalResources / 9.0))
               {
                  porcelainTowerTactic = cTacticWonderCoin;
               }
               if (kbResourceGet(cResourceWood) < (totalResources / 9.0))
               {
                  porcelainTowerTactic = cTacticWonderWood;
               }
            }
            aiUnitSetTactic(kbUnitQueryGetResult(porcelainTowerQueryID, 0), porcelainTowerTactic);
         }
      }
   }
}
rule summerPalaceTacticMonitor
inactive
mininterval 180
{
   // Disable rule for anybody but Chinese
   if (cMyCiv != cCivChinese)
   {
      xsDisableSelf();
      return;
   }
   // In Age 2, stay with standard army (default)
   if (kbGetAge() < cAge3)
   {
      return;
   }
   int summerPalaceType = -1;
   int randomizer = -1;
   // Check for summer palace
   if (kbUnitCount(cMyID, cUnitTypeypWCSummerPalace2, cUnitStateAlive) > 0)
   {
      summerPalaceType = cUnitTypeypWCSummerPalace2;
   }
   else if (kbUnitCount(cMyID, cUnitTypeypWCSummerPalace3, cUnitStateAlive) > 0)
   {
      summerPalaceType = cUnitTypeypWCSummerPalace3;
   }
   else if (kbUnitCount(cMyID, cUnitTypeypWCSummerPalace4, cUnitStateAlive) > 0)
   {
      summerPalaceType = cUnitTypeypWCSummerPalace4;
   }
   else if (kbUnitCount(cMyID, cUnitTypeypWCSummerPalace5, cUnitStateAlive) > 0)
   {
      summerPalaceType = cUnitTypeypWCSummerPalace5;
   }
   if (summerPalaceType > 0)
   {
      int summerPalaceQueryID = -1;
      summerPalaceQueryID = kbUnitQueryCreate("summerPalaceQueryID");
      kbUnitQuerySetIgnoreKnockedOutUnits(summerPalaceQueryID, true);
      if (summerPalaceQueryID != -1)
      {
         kbUnitQuerySetPlayerRelation(summerPalaceQueryID, -1);
         kbUnitQuerySetPlayerID(summerPalaceQueryID, cMyID);
         kbUnitQuerySetUnitType(summerPalaceQueryID, summerPalaceType);
         kbUnitQuerySetState(summerPalaceQueryID, cUnitStateAlive);
         kbUnitQueryResetResults(summerPalaceQueryID);
         int numberFound = kbUnitQueryExecute(summerPalaceQueryID);
         // In Age 3 and above, spawn either territorial, forbidden or imperial army
         if (numberFound > 0)
         {
            aiUnitSetTactic(kbUnitQueryGetResult(summerPalaceQueryID, 0), cTacticForbiddenArmy);
			/*
            randomizer = aiRandInt(3);
            switch (randomizer)
            {
            case 0:
            {
               aiUnitSetTactic(kbUnitQueryGetResult(summerPalaceQueryID, 0), cTacticTerritorialArmy);
               break;
            }
            case 1:
            {
               aiUnitSetTactic(kbUnitQueryGetResult(summerPalaceQueryID, 0), cTacticForbiddenArmy);
               break;
            }
            default:
            {
               aiUnitSetTactic(kbUnitQueryGetResult(summerPalaceQueryID, 0), cTacticImperialArmy);
               break;
            }
            }
			*/
            // Disable rule once a new tactic has been set
            xsDisableSelf();
         }
      }
   }
}
rule goldenPavillionTacticMonitor
inactive
group tcComplete
mininterval 180
{
   // Disable rule for anybody but Japanese
   if (kbGetCiv() != cCivJapanese)
   {
      xsDisableSelf();
      return;
   }
   static bool goldenPavillionBuilt = false;
   static bool goldenPavillionBuiltConfirm = false;
   int goldenPavillionType = -1;
   // Check for golden pavillion
   if (kbUnitCount(cMyID, cUnitTypeypWJGoldenPavillion2, cUnitStateAlive) > 0)
   {
      goldenPavillionType = cUnitTypeypWJGoldenPavillion2;
   }
   else if (kbUnitCount(cMyID, cUnitTypeypWJGoldenPavillion3, cUnitStateAlive) > 0)
   {
      goldenPavillionType = cUnitTypeypWJGoldenPavillion3;
   }
   else if (kbUnitCount(cMyID, cUnitTypeypWJGoldenPavillion4, cUnitStateAlive) > 0)
   {
      goldenPavillionType = cUnitTypeypWJGoldenPavillion4;
   }
   else if (kbUnitCount(cMyID, cUnitTypeypWJGoldenPavillion5, cUnitStateAlive) > 0)
   {
      goldenPavillionType = cUnitTypeypWJGoldenPavillion5;
   }
   if (goldenPavillionType < 0)
   {
      if (goldenPavillionBuilt == false) // not built yet.
	 return;
      else // built and lost 
      {
 	 xsDisableSelf();
	 return;
      }
   }
   //when we're here, Golden Pavillion wonder has been built and still exists(goldenPavillionType >= 0).
   if (goldenPavillionBuiltConfirm == false)
   {
      goldenPavillionBuilt = true;
      goldenPavillionBuiltConfirm = true;
   }
   aiUnitSetTactic(goldenPavillionType, cTacticRangeDamage);
   /*
   static int enemyPointQuery = -1;
   enemyPointQuery = createSimpleQuery(cPlayerRelationEnemyNotGaia, cUnitTypeLogicalTypeLandMilitary, cUnitStateABQ);
   kbUnitQueryResetResults(enemyPointQuery);
   int enemyCount = kbUnitQueryExecute(enemyPointQuery);
   if (enemyCount < 5) //don't bother if little enemy found.
      return;
   int enemyPointID = 0;
   vector enemyPointVector = cInvalidVector;
   int enemyPointCount = 0;
   int selfPointCount = 0;
   int selfRangedUnitCount = 0;
   int selfHandUnitCount = 0;
   bool rangedUnitDominating = false;
   int i = 0;
   for (i=0; <enemyCount)
   {
	enemyPointID = kbUnitQueryGetResult(enemyPointQuery, i);
	enemyPointVector = kbUnitGetPosition(enemyPointID);
	enemyPointCount = getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia, cUnitStateAlive, enemyPointVector, 30.0);
	selfPointCount = getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, cMyID, cUnitStateAlive, enemyPointVector, 30.0);
	selfRangedUnitCount = getUnitCountByLocation(cUnitTypeAbstractRangedInfantry, cMyID, cUnitStateAlive, enemyPointVector, 30.0) + getUnitCountByLocation(cUnitTypeAbstractRangedCavalry, cMyID, cUnitStateAlive, enemyPointVector, 30.0);
	selfHandUnitCount = selfPointCount - selfRangedUnitCount;	   
	if ((enemyPointCount >= 5) && (selfRangedUnitCount > 10)&&(selfRangedUnitCount > selfHandUnitCount*2))
	{
	   rangedUnitDominating = true;
	   break;
	}
   }
   if (rangedUnitDominating == true)
      aiUnitSetTactic(goldenPavillionType, cTacticRangeDamage);
   else
      aiUnitSetTactic(goldenPavillionType, cTacticUnitHitpoints);
  */
}
rule dojoTacticMonitor
inactive
minInterval 10
{
   int randomizer = -1;
   static int dojoTactic1 = -1;
   static int dojoTactic2 = -1;
/*
   switch (kbUnitPickGetResult(gLandUnitPicker, 0))
   {
   case cUnitTypeypYumi:
   {
      randomizer = aiRandInt(3);
      if (randomizer < 2)
      {
         dojoTactic1 = cTacticSamurai;
      }
      else
      {
         dojoTactic1 = cTacticAshigaru;
      }
      break;
   }
   case cUnitTypeypAshigaru:
   {
      randomizer = aiRandInt(10);
      if (randomizer < 7)
      {
         dojoTactic1 = cTacticNaginataRider;
      }
      else
      {
         dojoTactic1 = cTacticYumi;
      }
      break;
   }
   case cUnitTypeypKensei:
   {
      randomizer = aiRandInt(10);
      if (randomizer < 7)
      {
         dojoTactic1 = cTacticNaginataRider;
      }
      else
      {
         dojoTactic1 = cTacticYumi;
      }
      break;
   }
   case cUnitTypeypNaginataRider:
   {
      randomizer = aiRandInt(3);
      if (randomizer < 2)
      {
         dojoTactic1 = cTacticSamurai;
      }
      else
      {
         dojoTactic1 = cTacticAshigaru;
      }
      break;
   }
   case cUnitTypeypYabusame:
   {
      randomizer = aiRandInt(10);
      if (randomizer < 7)
      {
         dojoTactic1 = cTacticNaginataRider;
      }
      else
      {
         dojoTactic1 = cTacticYumi;
      }
      break;
   }
   default:
   {
      // Mercenary units? Go for randomize unit generation
      randomizer = aiRandInt(20);
      if (randomizer < 3)
      {
         dojoTactic1 = cTacticYumi;
      }
      else if (randomizer < 7)
      {
         dojoTactic1 = cTacticAshigaru;
      }
      else if (randomizer < 14)
      {
         dojoTactic1 = cTacticSamurai;
      }
      else if (randomizer < 19)
      {
         dojoTactic1 = cTacticNaginataRider;
      }
      else
      {
         dojoTactic1 = cTacticYabusame;
      }
      break;
   }
   }
   // Randomize unit generation option for second dojo
   switch (kbUnitPickGetResult(gLandUnitPicker, 1))
   {
   case cUnitTypeypYumi:
   {
      randomizer = aiRandInt(3);
      if (randomizer < 2)
      {
         dojoTactic2 = cTacticSamurai;
      }
      else
      {
         dojoTactic2 = cTacticAshigaru;
      }
      break;
   }
   case cUnitTypeypAshigaru:
   {
      randomizer = aiRandInt(10);
      if (randomizer < 7)
      {
         dojoTactic2 = cTacticNaginataRider;
      }
      else
      {
         dojoTactic2 = cTacticYumi;
      }
      break;
   }
   case cUnitTypeypKensei:
   {
      randomizer = aiRandInt(10);
      if (randomizer < 7)
      {
         dojoTactic2 = cTacticNaginataRider;
      }
      else
      {
         dojoTactic2 = cTacticYumi;
      }
      break;
   }
   case cUnitTypeypNaginataRider:
   {
      randomizer = aiRandInt(3);
      if (randomizer < 2)
      {
         dojoTactic2 = cTacticSamurai;
      }
      else
      {
         dojoTactic2 = cTacticAshigaru;
      }
      break;
   }
   case cUnitTypeypYabusame:
   {
      randomizer = aiRandInt(10);
      if (randomizer < 7)
      {
         dojoTactic2 = cTacticNaginataRider;
      }
      else
      {
         dojoTactic2 = cTacticYumi;
      }
      break;
   }
   default:
   {
      // Mercenary units? Go for randomize unit generation
      randomizer = aiRandInt(20);
      if (randomizer < 3)
      {
         dojoTactic2 = cTacticYumi;
      }
      else if (randomizer < 7)
      {
         dojoTactic2 = cTacticAshigaru;
      }
      else if (randomizer < 14)
      {
         dojoTactic2 = cTacticSamurai;
      }
      else if (randomizer < 19)
      {
         dojoTactic2 = cTacticNaginataRider;
      }
      else
      {
         dojoTactic2 = cTacticYabusame;
      }
      break;
   }
   }
   */
   dojoTactic1 = cTacticYumi;
   dojoTactic2 = cTacticYumi;
   // Define a query to get all matching units
   int dojoQueryID = -1;
   dojoQueryID = kbUnitQueryCreate("dojoGetUnitQuery");
   kbUnitQuerySetIgnoreKnockedOutUnits(dojoQueryID, true);
   if (dojoQueryID != -1)
   {
      kbUnitQuerySetPlayerRelation(dojoQueryID, -1);
      kbUnitQuerySetPlayerID(dojoQueryID, cMyID);
      kbUnitQuerySetUnitType(dojoQueryID, cUnitTypeypDojo);
      kbUnitQuerySetState(dojoQueryID, cUnitStateAlive);
      kbUnitQueryResetResults(dojoQueryID);
      int numberFound = kbUnitQueryExecute(dojoQueryID);
      if (numberFound == 1)
      {
         //aiUnitSetTactic(kbUnitQueryGetResult(dojoQueryID, 0), dojoTactic1);
         aiUnitSetTactic(kbUnitQueryGetResult(dojoQueryID, 0), cTacticYumi);
      }
      else if (numberFound == 2)
      {
         //aiUnitSetTactic(kbUnitQueryGetResult(dojoQueryID, 0), dojoTactic1);
         //aiUnitSetTactic(kbUnitQueryGetResult(dojoQueryID, 1), dojoTactic2);
         aiUnitSetTactic(kbUnitQueryGetResult(dojoQueryID, 0), cTacticYumi);
         aiUnitSetTactic(kbUnitQueryGetResult(dojoQueryID, 1), cTacticYumi);
         xsDisableSelf();
      }
   }
}

rule shrineTacticMonitor
inactive
minInterval 60
{
   int shrineQueryID = createSimpleUnitQuery(cUnitTypeypShrineJapanese, cMyID, cUnitStateAlive);
   int numberFound = kbUnitQueryExecute(shrineQueryID);
   
   if (numberFound > 0)
   {
      int shrineTactic = -1;
      
      switch (getMostNeededResource())
      {
      case cResourceGold:
      {
         shrineTactic = cTacticShrineCoin;
         break;
      }
      case cResourceWood:
      {
         shrineTactic = cTacticShrineWood;
         break;
      }
      default: // Food.
      {
         shrineTactic = cTacticShrineFood;
         break;
      }
      }
      
      // Shrines share their tactic so setting 1 also sets the others + a potential Toshogu Shrine.
      aiUnitSetTactic(kbUnitQueryGetResult(shrineQueryID, 0), shrineTactic);
      debugEconomy("Setting all Shrines to collect: " + shrineTactic);
   }
}

rule sacredFieldMonitor
inactive
minInterval 60
{

   static int cowPlan = -1;
   int numHerdables = 0;
   int numCows = 0;

   // Build a sacred field if there is none and we're either in age2, have herdables or excess wood
   if ((kbUnitCount(cMyID, cUnitTypeypSacredField, cUnitStateAlive) < 1) &&
           ((kbGetAge() >= cAge2) || (kbUnitCount(cMyID, cUnitTypeHerdable, cUnitStateAlive) +
                                          kbUnitCount(cMyID, cUnitTypeypSacredCow, cUnitStateAlive) >
                                      0)) ||
       (kbResourceGet(cResourceWood) > 650))
   { // Make sure we're not at the limit yet or are already trying to build one
      if ((kbGetBuildLimit(cMyID, cUnitTypeypSacredField) > kbUnitCount(cMyID, cUnitTypeypSacredField, cUnitStateAlive)) &&
          (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeypSacredField) < 0))
      {
         createSimpleBuildPlan(cUnitTypeypSacredField, 1, 50, true, cEconomyEscrowID, kbBaseGetMainID(cMyID), 1);
         return;
      }
   }

   // Quit if there is no sacred field around or we're in age1 without excess food
   if ((kbUnitCount(cMyID, cUnitTypeypSacredField, cUnitStateAlive) < 1) && (kbGetAge() == cAge1) &&
       (kbResourceGet(cResourceFood) < 925))
   {
      return;
   }

   // Check number of captured herdables, add sacred cows as necessary to bring total number to 10
   numHerdables = kbUnitCount(cMyID, cUnitTypeHerdable, cUnitStateAlive) -
                  kbUnitCount(cMyID, cUnitTypeypSacredCow, cUnitStateAlive);
   if (numHerdables < 0)
      numHerdables = 0;
   numCows = 10 - numHerdables;
   if (numCows > 0)
   {
      // Create/update maintain plan
      if (cowPlan < 0)
      {
         cowPlan = createSimpleMaintainPlan(cUnitTypeypSacredCow, numCows, true, kbBaseGetMainID(cMyID), 1);
      }
      else
      {
         aiPlanSetVariableInt(cowPlan, cTrainPlanNumberToMaintain, 0, numCows);
      }
   }

   if (numHerdables > 0)
   {
      int upgradePlanID = -1;

      // Get XP upgrade
      if (kbTechGetStatus(cTechypLivestockHoliness) == cTechStatusObtainable)
      {
         if (aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechypLivestockHoliness) >= 0)
            return;
         createSimpleResearchPlan(cTechypLivestockHoliness, cUnitTypeypSacredField, cMilitaryEscrowID, 50);
         return;
      }
   }
}

//==============================================================================
/* Livestock market monitor
//
// Manages selling livestock.
*/
//==============================================================================
rule livestockMarketMonitor
inactive
minInterval 20
{
   if (kbUnitCount(cMyID, cUnitTypedeLivestockMarket, cUnitStateAlive) == 0)
      return;

   static int herdableQuery = -1;
   static bool sellEarlyForWood = false;

   if (herdableQuery < 0)
   {
      herdableQuery = kbUnitQueryCreate("Herdable query for livestock selling");
      kbUnitQuerySetPlayerID(herdableQuery, cMyID);
      kbUnitQuerySetUnitType(herdableQuery, cUnitTypeHerdable);
      kbUnitQuerySetState(herdableQuery, cUnitStateAlive);
      if (gSPC == false && xsIsRuleEnabled("houseMonitor") == false)
         sellEarlyForWood = true;
   }

   kbUnitQueryResetResults(herdableQuery);

   int herdableCount = kbUnitQueryExecute(herdableQuery);
   int herdableID = -1;
   int bestHerdableID = -1;
   float bestAmount = 0.0;
   float amount = 0.0;
   int sellingResource = cResourceWood;

   if (sellEarlyForWood == false)
   {
      float maxRate = aiLivestockGetMaximumRate();
      if (xsArrayGetFloat(gResourceNeeds, cResourceGold) > xsArrayGetFloat(gResourceNeeds, cResourceWood))
         sellingResource = cResourceGold;
      if (aiLivestockGetExchangeRate(sellingResource) < maxRate)
         return;
   }
   else
   {
      if (xsGetTime() < 60000)
         return;
   }

   for (i = 0; < herdableCount)
   {
      herdableID = kbUnitQueryGetResult(herdableQuery, i);
      amount = kbUnitGetResourceAmount(herdableID, cResourceFood);
      if (bestAmount < amount)
      {
         bestHerdableID = herdableID;
         bestAmount = amount;
      }
   }

   // Just sell when we reached maximum exchange rate and the herdable's carry capacity.
   if (sellEarlyForWood == false)
   {
      if (bestAmount < kbUnitGetCarryCapacity(bestHerdableID, cResourceFood))
         return;
   }

   aiLivestockSell(sellingResource, bestHerdableID);

   if (sellEarlyForWood == true)
   {
      xsEnableRule("houseMonitor");
      houseMonitor();
      sellEarlyForWood = false;
   }
}

//==============================================================================
// setMountainMonasteryTactic
//==============================================================================
rule setMountainMonasteryTactic
inactive
minInterval 5
{
   int unitID = getUnit(cUnitTypedeMountainMonastery);
   if (unitID < 0)
      return;
   aiUnitSetTactic(unitID, cTacticMonasteryInfluence50);
   debugEconomy("Setting Mountain Monasteries to gather 50 percent Influence/Coin");
   xsDisableSelf();
}

//==============================================================================
// haciendaMonitor
//
// Grab idle haciendas and put them on cow or villager production.
//==============================================================================
rule haciendaMonitor
inactive
minInterval 20
{
   static int idleHaciendas = -1;

   if (idleHaciendas < 0)
   {
      idleHaciendas = xsArrayCreateBool(10, false, "Idle haciendas");
   }

   int haciendaQuery = createSimpleUnitQuery(cUnitTypedeHacienda, cMyID, cUnitStateAlive);
   int numberFound = kbUnitQueryExecute(haciendaQuery);

   if (numberFound == 0)
      return;

   int numFarmPlans = aiPlanGetNumberByTypeAndVariableType(
       cPlanGather, cGatherPlanResourceSubType, cAIResourceSubTypeFarm, true);
   int planID = -1;
   int unitID = -1;

   for (i = 0; < numberFound)
      xsArraySetBool(idleHaciendas, i, true);

   for (i = 0; < numFarmPlans)
   {
      planID = aiPlanGetIDByTypeAndVariableType(cPlanGather, cGatherPlanResourceSubType, cAIResourceSubTypeFarm, true, i);

      // Make sure there are no villagers assigned.
      if (aiPlanGetNumberNeededUnits(planID) == 0 && aiPlanGetNumberWantedUnits(planID) == 0 &&
          aiPlanGetNumberMaxUnits(planID) == 0)
         continue;

      unitID = kbResourceGetUnit(aiPlanGetVariableInt(planID, cGatherPlanKBResourceID, 0), 0);

      for (j = 0; < numberFound)
      {
         if (unitID == kbUnitQueryGetResult(haciendaQuery, j))
         {
            xsArraySetBool(idleHaciendas, j, false);
            break;
         }
      }
   }

   int numberVillagersWanted = 0;
   int tacticID = -1;
   int age = kbGetAge();
   if (age >= cAge3)
   {
      numberVillagersWanted = getSettlerShortfall();
      if (kbGetPopCap() - kbGetPop() <= 0)
         numberVillagersWanted = 0;
   }

   for (i = 0; < numberFound)
   {
      if (xsArrayGetBool(idleHaciendas, i) == false)
         continue;
      if (numberVillagersWanted > 0)
      {
         tacticID = cTacticHaciendaSettler;
         numberVillagersWanted--;
      }
      else
      {
         tacticID = cTacticHaciendaCow;
      }
      aiUnitSetTactic(kbUnitQueryGetResult(haciendaQuery, i), tacticID);
   }
}