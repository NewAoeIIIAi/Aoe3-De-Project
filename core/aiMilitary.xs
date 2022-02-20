//==============================================================================
/* aiMilitary.xs

   This file is intended for any military related stuffs, not limited to army
   training, researching upgrades and combat handling.

*/
//==============================================================================

//==============================================================================
// mostHatedEnemy
// Determine who we should attack, checking cvPlayerToAttack too
//==============================================================================
rule mostHatedEnemy
minInterval 60
active
{
   if (cvPlayerToAttack > 0)
   {
      debugMilitary("**** cv Changing most hated Player from " + aiGetMostHatedPlayerID() + " to " + cvPlayerToAttack);
      aiSetMostHatedPlayerID(cvPlayerToAttack);
      if (gLandUnitPicker >= 0)
      {
         kbUnitPickSetEnemyPlayerID(gLandUnitPicker, cvPlayerToAttack); // Update the unit picker.
      }
      xsDisableSelf();
      return;
   }

   static bool treatyTargetingPerformed = false;
   int arrayIndex = 0;
   int arrayIndexOfSelectedEnemy = 0;
   gNumEnemies = 0;
   bool isTreatyActive = aiTreatyActive();

   if (isTreatyActive == true && treatyTargetingPerformed == false) // We only perform the targeting once during treaty.
   {
      // Add IDs of enemies to the array.
      for (i = 1; < cNumberPlayers)
      {
         if (kbGetPlayerTeam(i) != kbGetPlayerTeam(cMyID)) // Not on our team so must be an enemy.
         {
            if (kbHasPlayerLost(i) == false)
            {
               xsArraySetInt(gArrayEnemyPlayerIDs, arrayIndex, i);
               arrayIndex = arrayIndex + 1;
               gNumEnemies = gNumEnemies + 1;
            }
         }
      }
      if (kbGetIsFFA()) // We pick a target that is adjacent to us in FFA.
      {
         if (gNumEnemies >= 3) // We only need to sort when we have more than 2 enemies, because if we only have 2 enemies we
                               // just chose either one anyway regardless of distance.
         {
            arraySortInt(gArrayEnemyPlayerIDs, 0, gNumEnemies, [](int playerA = 1, int playerB = 2) -> bool {
               return (xsArrayGetFloat(gStartingPosDistances, playerA) < xsArrayGetFloat(gStartingPosDistances, playerB));
            });
         }
         arrayIndexOfSelectedEnemy = gNumEnemies >= 2 ? aiRandInt(2) : 0;
      }
      else
      {
         arrayIndexOfSelectedEnemy = aiRandInt(gNumEnemies);
      }

      aiSetMostHatedPlayerID(xsArrayGetInt(gArrayEnemyPlayerIDs, arrayIndexOfSelectedEnemy));
      debugMilitary(
          "*** Treaty targeting randomly selected Player " + xsArrayGetInt(gArrayEnemyPlayerIDs, arrayIndexOfSelectedEnemy) +
          " to be our most hated player");

      if (gLandUnitPicker >= 0)
      {
         kbUnitPickSetEnemyPlayerID(
             gLandUnitPicker, xsArrayGetInt(gArrayEnemyPlayerIDs, arrayIndexOfSelectedEnemy)); // Update the unit picker.
      }

      treatyTargetingPerformed = true;
      return;
   }

   if (isTreatyActive == false)
   {
      // Add IDs of enemies who are still alive to the array.
      for (i = 1; < cNumberPlayers)
      {
         if (kbIsPlayerEnemy(i))
         {
            if (kbHasPlayerLost(i) == false)
            {
               xsArraySetInt(gArrayEnemyPlayerIDs, arrayIndex, i);
               arrayIndex = arrayIndex + 1;
               gNumEnemies = gNumEnemies + 1;
            }
         }
      }

      if (kbGetIsFFA()) // We pick a target that is adjacent to us in FFA.
      {
         if (gNumEnemies >= 3) // We only need to sort when we have more than 2 enemies, because if we only have 2 enemies we
                               // just chose either one anyway regardless of distance.
         {
            arraySortInt(gArrayEnemyPlayerIDs, 0, gNumEnemies, [](int playerA = 1, int playerB = 2) -> bool {
               return (xsArrayGetFloat(gStartingPosDistances, playerA) < xsArrayGetFloat(gStartingPosDistances, playerB));
            });
         }
         arrayIndexOfSelectedEnemy = gNumEnemies >= 2 ? aiRandInt(2) : 0;
      }
      else
      {
         arrayIndexOfSelectedEnemy = aiRandInt(gNumEnemies);
      }

      aiSetMostHatedPlayerID(xsArrayGetInt(gArrayEnemyPlayerIDs, arrayIndexOfSelectedEnemy));
      debugMilitary(
          "*** Randomly selected Player " + xsArrayGetInt(gArrayEnemyPlayerIDs, arrayIndexOfSelectedEnemy) +
          " to be our most hated player");

      if (gLandUnitPicker >= 0)
      {
         kbUnitPickSetEnemyPlayerID(
             gLandUnitPicker, xsArrayGetInt(gArrayEnemyPlayerIDs, arrayIndexOfSelectedEnemy)); // Update the unit picker.
      }
   }
}

//==============================================================================
// addUnitsToMilitaryPlan
//==============================================================================
void addUnitsToMilitaryPlan(int planID = -1)
{
   // TODO: don't always task the full army, leave some behind if the enemy is weak or we need more defense
   if ((gRevolutionType & cRevolutionFinland) == 0)
   {
      aiPlanAddUnitType(planID, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);
      return;
   }

   // For the finland revolution, keep some karelian jaegers around to sustain the economy
   int numberAvailableEconUnits = 0;
   int queryID = createSimpleUnitQuery(cUnitTypeLogicalTypeLandMilitary, cMyID, cUnitStateAlive);
   int numberFound = kbUnitQueryExecute(queryID);

   aiPlanAddUnitType(planID, cUnitTypeLogicalTypeLandMilitary, 0, 0, 0);

   // Add each unit type individually
   for (i = 0; < numberFound)
   {
      int unitID = kbUnitQueryGetResult(queryID, i);
      int puid = kbUnitGetProtoUnitID(unitID);
      if (puid == gEconUnit)
      {
         int unitPlanType = aiPlanGetType(kbUnitGetPlanID(unitID));
         if (unitPlanType == cPlanGather || unitPlanType == cPlanBuild)
            numberAvailableEconUnits = numberAvailableEconUnits + 1;
         continue;
      }
      aiPlanAddUnitType(planID, puid, 0, 0, 200);
   }

   // Keep at least 30 karelian jaegers around or the equivalent wood amount
   float numberEconUnits = (0.0 - xsArrayGetFloat(gResourceNeeds, cResourceWood) - 3000.0) / 100.0;
   if (numberEconUnits < 0.0)
   {
      numberEconUnits = numberAvailableEconUnits + numberEconUnits;
      if (numberEconUnits < 0.0)
         numberEconUnits = 0.0;
   }
   else
   {
      numberEconUnits = numberAvailableEconUnits;
   }
   aiPlanAddUnitType(planID, gEconUnit, 0, numberEconUnits, numberEconUnits);
}

//==============================================================================
// updateMilitaryTrainPlanBuildings
//==============================================================================
void updateMilitaryTrainPlanBuildings(int baseID = -1)
{
   static int buildingIDs = -1;
   int size = xsArrayGetSize(gArmyUnitMaintainPlans);
   int planID = -1;
   int buildingQuery = -1;
   int numberFound = 0;
   int buildingID = -1;
   int buildingPUID = -1;
   int numberBuildings = 0;

   if (buildingIDs < 0)
      buildingIDs = xsArrayCreateInt(8, -1, "Temp train buildings");

   for (i = 0; < size)
   {
      planID = xsArrayGetInt(gArmyUnitMaintainPlans, i);
      if (planID < 0)
         continue;
      if (baseID < 0)
      {
         // clear all buildings.
         aiPlanSetNumberVariableValues(planID, cTrainPlanBuildingID, 1, true);
      }
      else
      {
         // Restrict train plan to train from the base if we can.
         if (buildingQuery < 0)
         {
            buildingQuery = createSimpleUnitQuery(
                cUnitTypeLogicalTypeBuildingsNotWalls,
                cMyID,
                cUnitStateAlive,
                kbBaseGetLocation(cMyID, baseID),
                kbBaseGetDistance(cMyID, baseID));
            numberFound = kbUnitQueryExecute(buildingQuery);
         }

         numberBuildings = 0;

         for (j = 0; < numberFound)
         {
            buildingID = kbUnitQueryGetResult(buildingQuery);
            buildingPUID = kbUnitGetProtoUnitID(buildingID);
            if (kbProtoUnitCanTrain(buildingPUID, aiPlanGetVariableInt(planID, cTrainPlanUnitType, 0)) == false)
               continue;
            xsArraySetInt(buildingIDs, numberBuildings, buildingID);
            numberBuildings++;
         }

         if (numberBuildings == 0)
         {
            aiPlanSetNumberVariableValues(planID, cTrainPlanBuildingID, 1, true);
         }
         else
         {
            aiPlanSetNumberVariableValues(planID, cTrainPlanBuildingID, numberBuildings, true);
            for (j = 0; < numberBuildings)
               aiPlanSetVariableInt(planID, cTrainPlanBuildingID, j, xsArrayGetInt(buildingIDs, j));
         }
      }
   }
}

//==============================================================================
/*
   Military Manager

   Create maintain plans for military unit lines.  Control 'maintain' levels,
   buy upgrades.
*/
//==============================================================================
rule militaryManager
inactive
minInterval 28
{
   static bool firstRun = false; // Flag to indicate vars, plans are initialized
   static int unitsNotMaintained = -1;
   static int unitsNotMaintainedValue = -1;
   static int unitsNotMaintainedUpgrade = -1;
   if (firstRun == false)
   {
      // Need to initialize, if we're allowed to.
      firstRun = true;
      if (cvNumArmyUnitTypes >= 0)
         gNumArmyUnitTypes = cvNumArmyUnitTypes;
      else
         gNumArmyUnitTypes = 3;
      gLandUnitPicker = initUnitPicker("Land military units", gNumArmyUnitTypes, 1, 30, -1, -1, 1, true);

      // now the goal
      // wmj -- hard coded for now, but this should most likely ramp up as the ages progress
      aiSetMinArmySize(15);
      /*if (gMainAttackGoal >= 0)
      {
         aiPlanSetVariableInt(gMainAttackGoal, cGoalPlanUnitPickerID, 0, gLandUnitPicker);
         aiPlanSetVariableInt(gMainAttackGoal, cGoalPlanReservePlanID, 0, gLandReservePlan);
      }*/

      unitsNotMaintained = xsArrayCreateInt(3, -1, "Units not maintained");
      unitsNotMaintainedValue = xsArrayCreateFloat(3, -1, "Units not maintained value");
      unitsNotMaintainedUpgrade = xsArrayCreateInt(3, -1, "Units not maintained upgrade");
   }

   if (gLandUnitPicker != -1)
   {
      int age = kbGetAge();
      int targetPlayer = aiGetMostHatedPlayerID();

      if (agingUp() == true)
         age++;

      setUnitPickerPreference(
          gLandUnitPicker); // Update preferences in case btBiasEtc vars have changed, or cvPrimaryArmyUnit has changed.

      kbUnitPickSetMinimumPop(gLandUnitPicker, 1);
      kbUnitPickSetMaximumPop(gLandUnitPicker, aiGetMilitaryPop());

      if (cvNumArmyUnitTypes < 0)
      {
         if (age < cAge3)
            gNumArmyUnitTypes = 2;
         else
            gNumArmyUnitTypes = 3;
         kbUnitPickSetDesiredNumberUnitTypes(gLandUnitPicker, gNumArmyUnitTypes, 1, true);
      }

      //setUnitPickerCommon(gLandUnitPicker);

      // Bump up an age when we are transitioning to plan early for resources.
      kbUnitPickRun(gLandUnitPicker, age);

      int numMilitaryBuildings = xsArrayGetSize(gMilitaryBuildings);
      int planID = -1;
      int upgradePlanID = -1;
      float totalFactor = 0.0;
      int baseID = kbBaseGetMainID(cMyID);
      vector gatherPoint = kbBaseGetMilitaryGatherPoint(cMyID, baseID);
      int puid = -1;
      int buildingPUID = -1;
      int trainBuildingPUID = -1;
      int numberToMaintain = 0;
      int popCount = 0;
      int upgradeTechID = -1;
      float totalValue = 0.0;

      for (i = 0; < gNumArmyUnitTypes)
         totalFactor = totalFactor + kbUnitPickGetResultFactor(gLandUnitPicker, i);

      for (i = 0; < gNumArmyUnitTypes)
      {
         puid = kbUnitPickGetResult(gLandUnitPicker, i);
         trainBuildingPUID = -1;
         numberToMaintain = 0;
         popCount = kbGetProtoUnitPopCount(puid);

         // update maintain plan.
         planID = xsArrayGetInt(gArmyUnitMaintainPlans, i);
         if (planID >= 0 && puid != aiPlanGetVariableInt(planID, cTrainPlanUnitType, 0))
         {
            int otherPlanID = -1;

            for (j = i + 1; < gNumArmyUnitTypes)
            {
               otherPlanID = xsArrayGetInt(gArmyUnitMaintainPlans, j);
               if (otherPlanID >= 0 && puid == aiPlanGetVariableInt(otherPlanID, cTrainPlanUnitType, 0))
               {
                  xsArraySetInt(gArmyUnitMaintainPlans, j, planID);
                  break;
               }
               otherPlanID = -1;
            }

            if (otherPlanID < 0)
            {
               aiPlanDestroy(planID);
               planID = -1;
            }
            else
            {
               planID = otherPlanID;
               xsArraySetInt(gArmyUnitMaintainPlans, i, planID);
            }
         }

         if (planID < 0 && puid >= 0)
         {
            planID = aiPlanCreate("Land military " + kbGetUnitTypeName(puid) + " maintain", cPlanTrain);
            aiPlanSetMilitary(planID, true);
            // Unit type.
            aiPlanSetVariableInt(planID, cTrainPlanUnitType, 0, puid);
            aiPlanSetBaseID(planID, baseID);
            aiPlanSetVariableVector(planID, cTrainPlanGatherPoint, 0, gatherPoint);
            aiPlanSetActive(planID);
            xsArraySetInt(gArmyUnitMaintainPlans, i, planID);
            debugMilitary("*** Creating maintain plan for " + kbGetUnitTypeName(puid));
         }

         if (popCount > 0)
         {
            numberToMaintain = (kbUnitPickGetResultFactor(gLandUnitPicker, i) / totalFactor) * aiGetMilitaryPop() / popCount;
         }
         else
         {
            numberToMaintain = (kbUnitPickGetResultFactor(gLandUnitPicker, i) / totalFactor) * aiGetMilitaryPop() /
                               (kbUnitCostPerResource(puid, cResourceFood) + kbUnitCostPerResource(puid, cResourceWood) +
                                kbUnitCostPerResource(puid, cResourceGold));
         }
         aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, numberToMaintain);

         for (j = 0; < numMilitaryBuildings)
         {
            buildingPUID = xsArrayGetInt(gMilitaryBuildings, j);
            if (kbProtoUnitCanTrain(buildingPUID, puid) == true)
            {
               trainBuildingPUID = buildingPUID;
               break;
            }
         }

         // create a research plan.
         if (trainBuildingPUID >= 0 && age >= cAge3)
         {
            upgradeTechID = kbTechTreeGetCheapestUnitUpgrade(puid, trainBuildingPUID);
            if (upgradeTechID >= 0)
            {
               upgradePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, upgradeTechID);

               if (upgradePlanID < 0)
               {
                  upgradePlanID = aiPlanCreate("Research " + kbGetTechName(upgradeTechID), cPlanResearch);
                  aiPlanSetVariableInt(upgradePlanID, cResearchPlanTechID, 0, upgradeTechID);
                  aiPlanSetVariableInt(upgradePlanID, cResearchPlanBuildingTypeID, 0, trainBuildingPUID);
                  aiPlanSetActive(upgradePlanID);
                  debugMilitary("*** Creating research plan for " + kbGetTechName(upgradeTechID));
               }

               aiPlanSetParentID(upgradePlanID, planID);

               totalValue = kbUnitCostPerResource(puid, cResourceFood) + kbUnitCostPerResource(puid, cResourceWood) +
                            kbUnitCostPerResource(puid, cResourceGold);
               totalValue = totalValue * kbUnitCount(cMyID, puid, cUnitStateABQ);

               // below default priority if we do not have enough units.
               if (totalValue < 1000.0)
                  aiPlanSetDesiredResourcePriority(upgradePlanID, 45 - (5 - totalValue / 200));
               else
                  aiPlanSetDesiredResourcePriority(upgradePlanID, 50);
            }
         }

         xsArraySetInt(gArmyUnitBuildings, i, trainBuildingPUID);
      }

      // Also research upgrades for units not maintained.
      if (aiGetWorldDifficulty() >= cDifficultyModerate && age >= cAge3)
      {
         // Remove any units in the unit picker.
         for (i = 0; < 3)
         {
            puid = xsArrayGetInt(unitsNotMaintained, i);
            if (puid < 0)
               continue;
            for (j = 0; < gNumArmyUnitTypes)
            {
               if (puid == kbUnitPickGetResult(gLandUnitPicker, j))
               {
                  xsArraySetInt(unitsNotMaintained, i, -1);
                  upgradePlanID = xsArrayGetInt(unitsNotMaintainedUpgrade, i);
                  if (upgradePlanID >= 0)
                  {
                     if (aiPlanGetParentID(upgradePlanID) < 0)
                        aiPlanDestroy(upgradePlanID);
                     xsArraySetInt(unitsNotMaintainedUpgrade, i, -1);
                  }
                  puid = -1;
                  break;
               }
            }
            if (puid >= 0)
            {
               totalValue = kbUnitCostPerResource(puid, cResourceFood) + kbUnitCostPerResource(puid, cResourceWood) +
                            kbUnitCostPerResource(puid, cResourceGold);
               totalValue = totalValue * kbUnitCount(cMyID, puid, cUnitStateAlive);
               xsArraySetFloat(unitsNotMaintainedValue, i, totalValue);
            }
            else
            {
               xsArraySetFloat(unitsNotMaintainedValue, i, 0.0);
            }
         }

         int militaryQuery = createSimpleUnitQuery(cUnitTypeLogicalTypeLandMilitary, cMyID, cUnitStateAlive);
         int numberFound = kbUnitQueryExecute(militaryQuery);
         int unitID = -1;
         int militaryPUID = -1;
         float lowestTotalValue = 0.0;
         int lowestTotalValueIndex = 0;

         // Query all units, pick unit types with the highest total value.
         for (i = 0; < numberFound)
         {
            unitID = kbUnitQueryGetResult(militaryQuery, i);
            puid = kbUnitGetProtoUnitID(unitID);

            // avoid unit types in the unit picker.
            for (j = 0; < gNumArmyUnitTypes)
            {
               if (puid == kbUnitPickGetResult(gLandUnitPicker, j))
               {
                  puid = -1;
                  break;
               }
            }
            if (puid < 0)
               break;

            // ignore unit types already in the array.
            for (j = 0; < 3)
            {
               if (puid == xsArrayGetInt(unitsNotMaintained, j))
               {
                  puid = -1;
                  break;
               }
            }
            if (puid < 0)
               break;

            // pick unit type in the array with the lowest value and replace it.
            lowestTotalValue = 99999.0;
            lowestTotalValueIndex = 0;

            for (j = 0; < 3)
            {
               militaryPUID = xsArrayGetInt(unitsNotMaintained, j);
               totalValue = xsArrayGetFloat(unitsNotMaintainedValue, j);
               if (militaryPUID < 0 || lowestTotalValue > totalValue)
               {
                  lowestTotalValue = totalValue;
                  lowestTotalValueIndex = j;
                  break;
               }
            }

            totalValue = kbUnitCostPerResource(puid, cResourceFood) + kbUnitCostPerResource(puid, cResourceWood) +
                         kbUnitCostPerResource(puid, cResourceGold);
            totalValue = totalValue * kbUnitCount(cMyID, puid, cUnitStateAlive);

            if (totalValue > lowestTotalValue)
            {
               xsArraySetInt(unitsNotMaintained, lowestTotalValueIndex, puid);
               xsArraySetFloat(unitsNotMaintainedValue, lowestTotalValueIndex, totalValue);
               upgradePlanID = xsArrayGetInt(unitsNotMaintainedUpgrade, lowestTotalValueIndex);
               if (upgradePlanID >= 0)
                  aiPlanDestroy(upgradePlanID);
               xsArraySetInt(unitsNotMaintainedUpgrade, lowestTotalValueIndex, -1);
            }
         }

         // Research upgrades when available.
         for (i = 0; < 3)
         {
            puid = xsArrayGetInt(unitsNotMaintained, i);
            for (j = 0; < numMilitaryBuildings)
            {
               buildingPUID = xsArrayGetInt(gMilitaryBuildings, j);
               if (kbProtoUnitCanTrain(buildingPUID, puid) == true)
               {
                  trainBuildingPUID = buildingPUID;
                  break;
               }
            }
            if (trainBuildingPUID >= 0)
            {
               upgradeTechID = kbTechTreeGetCheapestUnitUpgrade(puid, trainBuildingPUID);
               if (upgradeTechID >= 0)
               {
                  upgradePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, upgradeTechID);

                  if (upgradePlanID < 0)
                  {
                     upgradePlanID = aiPlanCreate("Research " + kbGetTechName(upgradeTechID), cPlanResearch);
                     aiPlanSetVariableInt(upgradePlanID, cResearchPlanTechID, 0, upgradeTechID);
                     aiPlanSetVariableInt(upgradePlanID, cResearchPlanBuildingTypeID, 0, trainBuildingPUID);
                     aiPlanSetActive(upgradePlanID);
                     debugMilitary("*** Creating research plan for " + kbGetTechName(upgradeTechID));
                  }

                  totalValue = xsArrayGetFloat(unitsNotMaintainedValue, i);

                  // below default priority if we do not have enough units.
                  if (totalValue < 1000.0)
                     aiPlanSetDesiredResourcePriority(upgradePlanID, 45 - (5 - totalValue / 200));
                  else
                     aiPlanSetDesiredResourcePriority(upgradePlanID, 50);
                  xsArraySetInt(unitsNotMaintainedUpgrade, i, upgradePlanID);
               }
            }
         }
      }

      if (aiGetWorldDifficulty() >= cDifficultyModerate)
      {
         planID = aiPlanGetIDByTypeAndVariableType(cPlanCombat, cCombatPlanCombatType, cCombatPlanCombatTypeAttack);
         if (planID >= 0 && aiPlanGetVariableBool(planID, cCombatPlanAllowMoreUnitsDuringAttack, 0) == true)
            baseID = gForwardBaseID;
         else
            baseID = -1;
         updateMilitaryTrainPlanBuildings(baseID);
      }
   }
}

//==============================================================================
// delayAttackMonitor
// We're on cDifficultyEasy aka Standard difficulty.
// It means we can't attack until AFTER someone has attacked us, or until we've reached age 4.
// It can also be that the loader file has set gDelayAttacks to false for this difficulty directly.
//==============================================================================
rule delayAttackMonitor
inactive
minInterval 10
{
   if ((gDelayAttacks == false) ||
       (kbGetAge() >= cAge4) ||
       (gDefenseReflexBaseID == kbBaseGetMainID(cMyID)))
   {
      xsEnableRule("attackManager");
      xsDisableSelf();
   }
}

//==============================================================================
// attackManager
// This rule analyzes the current situation in the game and decides if we should 
// attack an enemy OR defend an ally in need.
//==============================================================================
rule attackManager
inactive
minInterval 15
{
   static int baseQuery = -1;
   static int baseEnemyQuery = -1;
   bool defendingMonopoly = false;
   bool attackingMonopoly = false;
   bool defendingKOTH = false;
   bool attackingKOTH = false;
   int currentTime = xsGetTime();
   int numberUnits = 0;
   int numberFound = 0;
   int numberEnemyFound = 0;
   int numberBases = 0;
   int baseID = -1;
   int mainBaseID = kbBaseGetMainID(cMyID);
   vector mainBaseLocation = kbBaseGetLocation(cMyID, mainBaseID);
   int mainAreaGroup = kbAreaGroupGetIDByPosition(mainBaseLocation);
   int baseAreaGroup = -1;
   vector baseLocation = cInvalidVector;
   vector location = cInvalidVector;
   float baseDistance = 0.0;
   float armyPower = 0.0;
   float buildingPower = 0.0;
   float militaryPower = 0.0;
   float enemyMilitaryPower = 0.0;
   float affordable = 0.0;
   float baseAssets = 0.0;
   float distancePenalty = 0.0;
   float score = 0.0;
   bool isEnemy = false;
   bool isKOTH = false;
   bool isTradingPost = false;
   bool shouldAttack = false;
   int availableMilitaryPop = aiGetAvailableMilitaryPop();
   int unitID = -1;
   int puid = -1;
   float unitPower = 0.0;
   int targetBaseID = -1;
   int targetPlayer = 2;
   bool targetIsEnemy = true;
   bool targetShouldAttack = false;
   float targetAffordable = 0.0;
   float targetBaseAssets = 0.0;
   float targetDistancePenalty = 0.0;
   float targetScore = 0.0;
   float maxBaseAssets = 100.0;
   int planID = -1;
   int difficulty = aiGetWorldDifficulty();
   
   if (isDefendingOrAttacking() == true)
   {
      return;
   }
   
   if (baseQuery < 0)
   {
      baseQuery = kbUnitQueryCreate("attackBaseQuery");
      kbUnitQuerySetIgnoreKnockedOutUnits(baseQuery, true);
      baseEnemyQuery = kbUnitQueryCreate("attackBaseEnemyQuery");
      kbUnitQuerySetIgnoreKnockedOutUnits(baseEnemyQuery, true);
   }

   // Don't attack under treaty or main base is under attack.
   if (aiTreatyActive() == true || gDefenseReflexBaseID == mainBaseID)
      return;

   if (gIsMonopolyRunning == true)
   {
      if (gMonopolyTeam == kbGetPlayerTeam(cMyID))
         defendingMonopoly = true; // We're defending, let's not go launching any attacks
      else
         attackingMonopoly = true; // We're attacking, focus on trade posts
   }

   if (gIsKOTHRunning == true || aiIsKOTHAllowed() == true)
   {
      if (gKOTHTeam == kbGetPlayerTeam(cMyID))
         defendingKOTH = true; // We're defending, let's not go launching any attacks
      else
         attackingKOTH = true; // We're attacking, focus on the hill
   }

   numberUnits = aiPlanGetNumberUnits(gLandReservePlan, cUnitTypeLogicalTypeLandMilitary);

   for (i = 0; < numberUnits)
   {
      unitID = aiPlanGetUnitByIndex(gLandReservePlan, i);
      puid = kbUnitGetProtoUnitID(unitID);
      armyPower = armyPower + getMilitaryUnitStrength(puid);
   }

   // Go through all players' bases and calculate values for comparison.
   for (player = 1; < cNumberPlayers)
   {
      if (player == cMyID || kbHasPlayerLost(player) == true)
         continue;

      numberBases = kbBaseGetNumber(player);
      isEnemy = kbIsPlayerEnemy(player);

      if (isEnemy == true && (cvPlayerToAttack > 0 && cvPlayerToAttack != player && kbHasPlayerLost(cvPlayerToAttack) == false))
         continue;

      for (baseIndex = 0; < numberBases)
      {
         baseID = kbBaseGetIDByIndex(player, baseIndex);
         baseLocation = kbBaseGetLocation(player, baseID);
         baseDistance = kbBaseGetDistance(player, baseID);

         kbUnitQuerySetPlayerID(baseQuery, player);
         kbUnitQuerySetState(baseQuery, cUnitStateABQ);
         kbUnitQuerySetPosition(baseQuery, baseLocation);
         kbUnitQuerySetMaximumDistance(baseQuery, baseDistance);

         kbUnitQuerySetUnitType(baseQuery, cUnitTypeHasBountyValue);
         kbUnitQueryResetResults(baseQuery);
         numberFound = kbUnitQueryExecute(baseQuery);

         buildingPower = 0.0;
         militaryPower = 0.0;
         enemyMilitaryPower = 0.0;
         baseAssets = 0.0;
         isKOTH = false;
         isTradingPost = false;
         shouldAttack = true;
/*
         if (isEnemy == true)
         {
            if (currentTime - gLastAttackMissionTime < gAttackMissionInterval)
               shouldAttack = false;
         }
         else
         {
            if (currentTime - gLastDefendMissionTime < gDefendMissionInterval)
               shouldAttack = false;
         }
*/
         for (i = 0; < numberFound)
         {
            unitID = kbUnitQueryGetResult(baseQuery, i);
            puid = kbUnitGetProtoUnitID(unitID);
            switch (puid)
            {
            case cUnitTypeypKingsHill:
            {
               baseAssets = baseAssets + 1600.0;
               isKOTH = true;
               break;
            }
            case cUnitTypeTownCenter:
            {
               baseAssets = baseAssets + 1000.0;
               break;
            }
            // buildings generating resources
            case cUnitTypeBank:
            {
               baseAssets = baseAssets + 2500.0;
               break;
            }
            case cUnitTypeFactory:
            {
               baseAssets = baseAssets + 5000.0;
               break;
            }
            case cUnitTypeypWCPorcelainTower2:
            {
               baseAssets = baseAssets + 2500.0;
               break;
            }
            case cUnitTypeypWCPorcelainTower3:
            {
               baseAssets = baseAssets + 2500.0;
               break;
            }
            case cUnitTypeypWCPorcelainTower4:
            {
               baseAssets = baseAssets + 2500.0;
               break;
            }
            case cUnitTypeypWCPorcelainTower5:
            {
               baseAssets = baseAssets + 2500.0;
               break;
            }
            case cUnitTypeypShrineJapanese:
            {
               baseAssets = baseAssets + 1000.0;
               break;
            }
            case cUnitTypeypWJToshoguShrine2:
            {
               baseAssets = baseAssets + 2500.0;
               break;
            }
            case cUnitTypeypWJToshoguShrine3:
            {
               baseAssets = baseAssets + 5000.0;
               break;
            }
            case cUnitTypeypWJToshoguShrine4:
            {
               baseAssets = baseAssets + 5000.0;
               break;
            }
            case cUnitTypeypWJToshoguShrine5:
            {
               baseAssets = baseAssets + 5000.0;
               break;
            }
            case cUnitTypedeHouseInca:
            {
               baseAssets = baseAssets + 2500.0;
               break;
            }
            case cUnitTypedeTorp:
            {
               baseAssets = baseAssets + 1000.0;
               break;
            }
            case cUnitTypedeMountainMonastery:
            {
               baseAssets = baseAssets + 2500.0;
               break;
            }
            case cUnitTypedeUniversity:
            {
               baseAssets = baseAssets + 2500.0;
               break;
            }
            // buildings automatically creating military units
            case cUnitTypeypWCSummerPalace2:
            {
               baseAssets = baseAssets + 1200.0;
               break;
            }
            case cUnitTypeypWCSummerPalace3:
            {
               baseAssets = baseAssets + 1200.0;
               break;
            }
            case cUnitTypeypWCSummerPalace4:
            {
               baseAssets = baseAssets + 1200.0;
               break;
            }
            case cUnitTypeypWCSummerPalace5:
            {
               baseAssets = baseAssets + 1200.0;
               break;
            }
            case cUnitTypeypDojo:
            {
               baseAssets = baseAssets + 1200.0;
               break;
            }
            // buildings with HC drop off point
            case cUnitTypeFortFrontier:
            {
               baseAssets = baseAssets + 800.0;
               break;
            }
            case cUnitTypeOutpost:
            {
               baseAssets = baseAssets + 800.0;
               break;
            }
            case cUnitTypeBlockhouse:
            {
               baseAssets = baseAssets + 800.0;
               break;
            }
            case cUnitTypeNoblesHut:
            {
               baseAssets = baseAssets + 800.0;
               break;
            }
            case cUnitTypeypWIAgraFort2:
            {
               baseAssets = baseAssets + 800.0;
               break;
            }
            case cUnitTypeypWIAgraFort3:
            {
               baseAssets = baseAssets + 800.0;
               break;
            }
            case cUnitTypeypWIAgraFort4:
            {
               baseAssets = baseAssets + 800.0;
               break;
            }
            case cUnitTypeypWIAgraFort5:
            {
               baseAssets = baseAssets + 800.0;
               break;
            }
            case cUnitTypeypCastle:
            {
               baseAssets = baseAssets + 800.0;
               break;
            }
            case cUnitTypeYPOutpostAsian:
            {
               baseAssets = baseAssets + 800.0;
               break;
            }
            case cUnitTypedeIncaStronghold:
            {
               baseAssets = baseAssets + 800.0;
               break;
            }
            case cUnitTypedeTower:
            {
               baseAssets = baseAssets + 800.0;
               break;
            }
            // military buildings
            case cUnitTypeBarracks:
            {
               baseAssets = baseAssets + 1000.0;
               break;
            }
            case cUnitTypeStable:
            {
               baseAssets = baseAssets + 1000.0;
               break;
            }
            case cUnitTypeArtilleryDepot:
            {
               baseAssets = baseAssets + 1000.0;
               break;
            }
            case cUnitTypeCorral:
            {
               baseAssets = baseAssets + 1000.0;
               break;
            }
            case cUnitTypeypWarAcademy:
            {
               baseAssets = baseAssets + 1000.0;
               break;
            }
            case cUnitTypeYPBarracksIndian:
            {
               baseAssets = baseAssets + 1000.0;
               break;
            }
            case cUnitTypeypCaravanserai:
            {
               baseAssets = baseAssets + 1000.0;
               break;
            }
            case cUnitTypeypBarracksJapanese:
            {
               baseAssets = baseAssets + 1000.0;
               break;
            }
            case cUnitTypeypStableJapanese:
            {
               baseAssets = baseAssets + 1000.0;
               break;
            }
            case cUnitTypedeKallanka:
            {
               baseAssets = baseAssets + 1000.0;
               break;
            }
            case cUnitTypedeWarCamp:
            {
               baseAssets = baseAssets + 1000.0;
               break;
            }
            case cUnitTypedePalace:
            {
               baseAssets = baseAssets + 2500.0;
               break;
            }
            // villagers
            case cUnitTypeSettler:
            {
               baseAssets = baseAssets + 1000.0;
               break;
            }
            case cUnitTypeSettlerWagon:
            {
               baseAssets = baseAssets + 4000.0;
               break;
            }
            case cUnitTypeCoureur:
            {
               baseAssets = baseAssets + 1500.0;
               break;
            }
            case cUnitTypeCoureurCree:
            {
               baseAssets = baseAssets + 1500.0;
               break;
            }
            case cUnitTypeSettlerNative:
            {
               baseAssets = baseAssets + 1000.0;
               break;
            }
            case cUnitTypeypSettlerAsian:
            {
               baseAssets = baseAssets + 1000.0;
               break;
            }
            case cUnitTypeypSettlerIndian:
            {
               baseAssets = baseAssets + 1000.0;
               break;
            }
            case cUnitTypeypSettlerJapanese:
            {
               baseAssets = baseAssets + 1000.0;
               break;
            }
            case cUnitTypedeSettlerAfrican:
            {
               baseAssets = baseAssets + 1000.0;
               break;
            }
            case cUnitTypeLogicalTypeLandMilitary:
            {
               baseAssets = baseAssets + 250.0;
               break;
            }
            default:
            {
               if (kbUnitIsType(unitID, cUnitTypeTradingPost) == true)
               {
                  if (kbUnitGetSubCiv(unitID) >= 0)
                     baseAssets = baseAssets + 400.0;
                  else // trade route trading post
                     baseAssets = baseAssets + 1600.0;
                  isTradingPost = true;
               }
               break;
            }
            }
         }

         // ignore base when we have no good targets to attack
         if (baseAssets == 0.0)
            continue;

         // prioritize trade monopoly and king's hill when active.
         //if ((attackingMonopoly == true || defendingMonopoly == true) && isTradingPost == false)
         //   shouldAttack = false;
         //if ((attackingKOTH == true || defendingKOTH == true) && isKOTH == false)
         //   shouldAttack = false;
	     if ((attackingKOTH == true || defendingKOTH == true) && isKOTH == false)
            shouldAttack = false;

         if (isEnemy == false)
         {
            kbUnitQuerySetPlayerRelation(baseEnemyQuery, cPlayerRelationEnemyNotGaia);
            kbUnitQuerySetState(baseEnemyQuery, cUnitStateABQ);
            kbUnitQuerySetPosition(baseEnemyQuery, baseLocation);
            kbUnitQuerySetMaximumDistance(baseEnemyQuery, baseDistance + 10.0);

            kbUnitQuerySetUnitType(baseEnemyQuery, cUnitTypeLogicalTypeLandMilitary);
            kbUnitQueryResetResults(baseEnemyQuery);
            numberEnemyFound = kbUnitQueryExecute(baseEnemyQuery);

            for (i = 0; < numberEnemyFound)
            {
               unitID = kbUnitQueryGetResult(baseQuery, i);
               puid = kbUnitGetProtoUnitID(unitID);
               enemyMilitaryPower = enemyMilitaryPower + getMilitaryUnitStrength(puid);
            }

            if (enemyMilitaryPower == 0.0)
               continue;
         }

         for (i = 0; < numberFound)
         {
            unitID = kbUnitQueryGetResult(baseQuery, i);
            puid = kbUnitGetProtoUnitID(unitID);

            switch (puid)
            {
            case cUnitTypeTownCenter:
            {
               buildingPower = buildingPower + 4.0;
               break;
            }
            case cUnitTypeFortFrontier:
            {
               buildingPower = buildingPower + 10.0;
               break;
            }
            case cUnitTypeOutpost:
            {
               buildingPower = buildingPower + 3.0;
               break;
            }
            case cUnitTypeBlockhouse:
            {
               buildingPower = buildingPower + 3.0;
               break;
            }
            case cUnitTypeNoblesHut:
            {
               buildingPower = buildingPower + 4.0;
               break;
            }
            case cUnitTypeypWIAgraFort2:
            {
               buildingPower = buildingPower + 4.0;
               break;
            }
            case cUnitTypeypWIAgraFort3:
            {
               buildingPower = buildingPower + 4.0;
               break;
            }
            case cUnitTypeypWIAgraFort4:
            {
               buildingPower = buildingPower + 4.0;
               break;
            }
            case cUnitTypeypWIAgraFort5:
            {
               buildingPower = buildingPower + 4.0;
               break;
            }
            case cUnitTypeypCastle:
            {
               buildingPower = buildingPower + 3.5;
               break;
            }
            case cUnitTypeYPOutpostAsian:
            {
               buildingPower = buildingPower + 3.0;
               break;
            }
            case cUnitTypedeIncaStronghold:
            {
               buildingPower = buildingPower + 4.0;
               break;
            }
            }

            if (kbProtoUnitIsType(cMyID, puid, cUnitTypeLogicalTypeLandMilitary) == true)
               militaryPower = militaryPower + getMilitaryUnitStrength(puid);
         }

         // avoid division by 0.
         if ((militaryPower + buildingPower) < 1.0)
         {
            militaryPower = 1.0;
            buildingPower = 0.0;
         }
		 
		 if ((kbGetAge() < cvMaxAge) || (gRevolutionType == 0))
		 {
         if (isEnemy == true)
         {
            // do we have enough power to defeat the target base?
            if (armyPower < militaryPower && availableMilitaryPop > 0)
               shouldAttack = false;
         }
         else
         {
            // is my ally really in trouble and can I handle the attack?
            if ((militaryPower + buildingPower > enemyMilitaryPower) ||
                (armyPower + militaryPower + buildingPower < enemyMilitaryPower * 0.8))
               shouldAttack = false;
         }

         // prioritize defending allies.
         if (isEnemy == true && targetIsEnemy == false)
            shouldAttack = false;
		 }

         /*if (aiGetWorldDifficulty() >= gDifficultyExpert)
         {
            // Avoid attacking until 5 minutes passed after aging up.
            if ((btRushBoom <= -0.5 && kbGetAge() < cAge4) || (btRushBoom <= 0.0 && kbGetAge() < cAge3))
            {
               if (xsGetTime() - gAgeUpTime < 300000)
                  shouldAttack = false;
            }
         }*/
		 
		 if ((kbGetAge() == cAge2) && (xsGetTime() - gAgeUpTime < 150000))
                  shouldAttack = false;

         if (baseAssets > maxBaseAssets)
         {
            maxBaseAssets = baseAssets;
            targetScore = (targetBaseAssets / maxBaseAssets) * targetAffordable * targetDistancePenalty;
         }

         if (isEnemy == true)
            affordable = armyPower / (militaryPower + buildingPower);
         else
            affordable = (armyPower + militaryPower + buildingPower) / enemyMilitaryPower;
		
		if ((kbGetAge() >= cvMaxAge) || (gRevolutionType != 0))
		 {
			 if (affordable > 0.4)
				 affordable = 1.0;
		 }

         // Adjust for distance. If < 100m, leave as is.  Over 100m to 400m, penalize 10% per 100m.
         distancePenalty = distance(mainBaseLocation, baseLocation) / 1000.0;
         if (distancePenalty > 0.4)
            distancePenalty = 0.4;
         // Increase penalty by 40% if transporting is required.
         baseAreaGroup = kbAreaGroupGetIDByPosition(baseLocation);
         if (mainAreaGroup != baseAreaGroup)
            distancePenalty = distancePenalty + 0.4;
         distancePenalty = 1.0 - distancePenalty;

         score = (baseAssets / maxBaseAssets) * affordable * distancePenalty;
         if (score > targetScore || (shouldAttack == true && targetShouldAttack == false))
         {
            targetBaseID = baseID;
            targetPlayer = player;
            targetIsEnemy = isEnemy;
            targetBaseAssets = baseAssets;
            targetAffordable = affordable;
            targetDistancePenalty = distancePenalty;
            targetScore = score;
            targetShouldAttack = shouldAttack;
         }
      }
   }

   // update target player.
   if (targetIsEnemy == true)
      aiSetMostHatedPlayerID(targetPlayer);

   if (targetBaseID < 0 || targetShouldAttack == false)
   {
      // If we got nothing, and KOTH is active, grab the KOTH location.
      if (defendingKOTH == true || attackingKOTH == true)
      {
         targetIsEnemy = attackingKOTH;
         int kothID = getUnit(cUnitTypeypKingsHill, cPlayerRelationAny, cUnitStateAlive);
         targetPlayer = kbUnitGetPlayerID(kothID);
         baseLocation = kbUnitGetPosition(kothID);
      }
      else
      {
         return;
      }
   }
   else
   {
      baseLocation = kbBaseGetLocation(targetPlayer, targetBaseID);
   }

   vector gatherPoint = kbBaseGetMilitaryGatherPoint(cMyID, mainBaseID);
   if (targetIsEnemy == true)
   {
      planID = aiPlanCreate("Attack Player " + targetPlayer + " Base " + targetBaseID, cPlanCombat);

      aiPlanSetVariableInt(planID, cCombatPlanCombatType, 0, cCombatPlanCombatTypeAttack);
      if (targetBaseID >= 0)
      {
         aiPlanSetVariableInt(planID, cCombatPlanTargetMode, 0, cCombatPlanTargetModeBase);
         aiPlanSetVariableInt(planID, cCombatPlanTargetBaseID, 0, targetBaseID);
      }
      else
      {
         aiPlanSetVariableInt(planID, cCombatPlanTargetMode, 0, cCombatPlanTargetModePoint);
      }
      aiPlanSetVariableInt(planID, cCombatPlanTargetPlayerID, 0, targetPlayer);
      aiPlanSetVariableVector(planID, cCombatPlanTargetPoint, 0, baseLocation);
      aiPlanSetVariableVector(planID, cCombatPlanGatherPoint, 0, gatherPoint);
      aiPlanSetVariableFloat(planID, cCombatPlanGatherDistance, 0, 40.0);

      /*baseAreaGroup = kbAreaGroupGetIDByPosition(baseLocation);
      if (mainAreaGroup == baseAreaGroup)
      {
         aiPlanSetVariableInt(planID, cCombatPlanAttackRoutePattern, 0, cCombatPlanAttackRoutePatternBest);
      }
      else
      {
         aiPlanSetVariableInt(planID, cCombatPlanAttackRoutePattern, 0, cCombatPlanAttackRoutePatternRandom);
      }*/
      aiPlanSetVariableInt(planID, cCombatPlanAttackRoutePattern, 0, cCombatPlanAttackRoutePatternRandom);

      // override the route when it is valid.
      int routeID = cvCreateBaseAttackRoute(targetPlayer, targetBaseID);
      if (routeID >= 0)
      {
         aiPlanSetVariableInt(planID, cCombatPlanAttackRouteID, 0, routeID);
         // aiPlanSetVariableBool(planID, cCombatPlanRefreshAttackRoute, 0, false);
      }

      if (difficulty >= cDifficultyModerate)
      {
         if (difficulty >= cDifficultyModerate)
            aiPlanSetVariableBool(planID, cCombatPlanAllowMoreUnitsDuringAttack, 0, true);
         aiPlanSetVariableInt(planID, cCombatPlanRefreshFrequency, 0, 300);
		 if ((kbGetAge() < cvMaxAge) || (gRevolutionType == 0))
         aiPlanSetVariableInt(planID, cCombatPlanDoneMode, 0, cCombatPlanDoneModeRetreat | cCombatPlanDoneModeBaseGone);
		 if ((kbGetAge() < cvMaxAge) || (gRevolutionType == 0))
		 {
         aiPlanSetVariableInt(planID, cCombatPlanRetreatMode, 0, cCombatPlanRetreatModeOutnumbered);
		 }
         updateMilitaryTrainPlanBuildings(gForwardBaseID);
      }
      else
      {
         aiPlanSetVariableInt(planID, cCombatPlanRefreshFrequency, 0, 1000);
         aiPlanSetVariableInt(planID, cCombatPlanDoneMode, 0, cCombatPlanDoneModeBaseGone);
      }
      aiPlanSetBaseID(planID, mainBaseID);
      aiPlanSetInitialPosition(planID, gatherPoint);

      addUnitsToMilitaryPlan(planID);

      aiPlanSetActive(planID);

      gLastAttackMissionTime = xsGetTime();
      debugMilitary("***** LAUNCHING ATTACK on player " + targetPlayer + " base " + targetBaseID);
   }
   else 
   {
      planID = aiPlanCreate("Defend Player " + targetPlayer + " Base " + targetBaseID, cPlanCombat);

      aiPlanSetVariableInt(planID, cCombatPlanCombatType, 0, cCombatPlanCombatTypeDefend);
      if (targetBaseID >= 0)
      {
         aiPlanSetVariableInt(planID, cCombatPlanTargetMode, 0, cCombatPlanTargetModeBase);
         aiPlanSetVariableInt(planID, cCombatPlanTargetBaseID, 0, targetBaseID);
      }
      else
      {
         aiPlanSetVariableInt(planID, cCombatPlanTargetMode, 0, cCombatPlanTargetModePoint);
      }
      aiPlanSetVariableInt(planID, cCombatPlanTargetPlayerID, 0, targetPlayer);
      aiPlanSetVariableVector(planID, cCombatPlanTargetPoint, 0, baseLocation);
      aiPlanSetVariableInt(planID, cCombatPlanRefreshFrequency, 0, difficulty >= cDifficultyModerate ? 300 : 1000);
	  if ((kbGetAge() < cvMaxAge) || (gRevolutionType == 0))
      aiPlanSetVariableInt(planID, cCombatPlanDoneMode, 0, cCombatPlanDoneModeNoTarget | cCombatPlanDoneModeRetreat);
      aiPlanSetVariableInt(planID, cCombatPlanNoTargetTimeout, 0, 1000);
	  if ((kbGetAge() < cvMaxAge) || (gRevolutionType == 0))
      aiPlanSetVariableInt(planID, cCombatPlanRetreatMode, 0, cCombatPlanRetreatModeOutnumbered);
      aiPlanSetOrphan(planID, true);

      addUnitsToMilitaryPlan(planID);

      aiPlanSetActive(planID);

      gLastDefendMissionTime = xsGetTime();
      debugMilitary("***** DEFENDING player " + targetPlayer + " base " + targetBaseID);
   }
}

int getNavalTargetPlayer() // Find an enemy player ID to attack on the water.
{
   int count = 0;
   int retVal = -1;
   static int unitQueryID = -1;

   // If we don't have the query yet, create one.
   if (unitQueryID < 0)
   {
      unitQueryID = kbUnitQueryCreate("navy target count");
      kbUnitQuerySetIgnoreKnockedOutUnits(unitQueryID, true);
      kbUnitQuerySetPlayerRelation(unitQueryID, cPlayerRelationEnemyNotGaia);
   }

   kbUnitQuerySetUnitType(unitQueryID, gFishingUnit); // Fishing boats
   kbUnitQuerySetState(unitQueryID, cUnitStateABQ);
   kbUnitQueryResetResults(unitQueryID);
   count = kbUnitQueryExecute(unitQueryID);
   // debugMilitary("Enemy fishing boats: "+ count);

   kbUnitQuerySetUnitType(unitQueryID, cUnitTypeAbstractWarShip); // Warships
   kbUnitQuerySetState(unitQueryID, cUnitStateABQ);
   count = kbUnitQueryExecute(unitQueryID); // Cumulative, don't clear it.
   // debugMilitary("Enemy fishing boats and warships: "+ count);

   kbUnitQuerySetUnitType(unitQueryID, gDockUnit); // Docks
   kbUnitQuerySetState(unitQueryID, cUnitStateABQ);
   count = kbUnitQueryExecute(unitQueryID); // Cumulative, don't clear it.
   // debugMilitary("Enemy fishing boats, warships and docks: "+ count);

   if (count > 0)
      retVal = kbUnitGetPlayerID(kbUnitQueryGetResult(unitQueryID, 0));

   debugMilitary("Enemy boat owner is player " + retVal);

   return (retVal);
}

rule waterAttackDefend
inactive
minInterval 15
{ // Broke this out separately (from navyManager) so that scenarios that start with a pre-made navy will work.
   int navyUnit = getUnit(cUnitTypeAbstractWarShip, cMyID, cUnitStateAlive);

   if (navyUnit < 0)
      return;

   if (gHaveWaterSpawnFlag == false)
      gNavyVec = kbUnitGetPosition(navyUnit);

   if (gNavyDefendPlan < 0)
   {
      gNavyDefendPlan = aiPlanCreate("Primary Water Defend", cPlanDefend);
      aiPlanAddUnitType(gNavyDefendPlan, cUnitTypeAbstractWarShip, 0, 0, 200); // Grab first caravel and any others

      aiPlanSetVariableVector(gNavyDefendPlan, cDefendPlanDefendPoint, 0, gNavyVec);
      aiPlanSetVariableFloat(gNavyDefendPlan, cDefendPlanEngageRange, 0, 100.0); // Loose
      aiPlanSetVariableBool(gNavyDefendPlan, cDefendPlanPatrol, 0, false);
      aiPlanSetVariableFloat(gNavyDefendPlan, cDefendPlanGatherDistance, 0, 40.0);
      aiPlanSetInitialPosition(gNavyDefendPlan, gNavyVec);
      aiPlanSetUnitStance(gNavyDefendPlan, cUnitStanceDefensive);
      aiPlanSetVariableInt(gNavyDefendPlan, cDefendPlanRefreshFrequency, 0, 20);
      aiPlanSetVariableInt(gNavyDefendPlan, cDefendPlanAttackTypeID, 0, cUnitTypeUnit); // Only units
      aiPlanSetDesiredPriority(gNavyDefendPlan,
                               18); // Very low priority, gather unused units, belowing fishing by default.
      aiPlanSetActive(gNavyDefendPlan);
      debugMilitary("Creating primary navy defend plan at " + gNavyVec);
   }

   int enemyQuery = createSimpleUnitQuery(cUnitTypeAbstractWarShip, cPlayerRelationEnemyNotGaia, cUnitStateAlive);
   int numberFound = 0;

   kbUnitQuerySetSeeableOnly(enemyQuery, true);
   numberFound = kbUnitQueryExecute(enemyQuery);

   if (numberFound > 0)
   {
      aiPlanAddUnitType(gNavyDefendPlan, cUnitTypeAbstractWarShip, 0, 200, 200);
      aiPlanSetDesiredPriority(gNavyDefendPlan, 21); // Above fishing when there are enemies around.
   }
   else
   {
      aiPlanAddUnitType(gNavyDefendPlan, cUnitTypeAbstractWarShip, 0, 0, 200);
      aiPlanSetDesiredPriority(gNavyDefendPlan, 18);
   }
   
   if (cvOkToAttack == true)
   {
      if (aiPlanGetNumberUnits(gNavyDefendPlan, cUnitTypeAbstractWarShip) >= 3)
      {                                  // Time to start an attack?
         if (getNavalTargetPlayer() > 0) // There's something to attack
         {
            int attackPlan = aiPlanCreate("Navy attack plan", cPlanAttack);
            aiPlanSetVariableInt(attackPlan, cAttackPlanPlayerID, 0, getNavalTargetPlayer());
            aiPlanSetNumberVariableValues(attackPlan, cAttackPlanTargetTypeID, 2, true);
            aiPlanSetVariableInt(attackPlan, cAttackPlanTargetTypeID, 0, cUnitTypeUnit);
            aiPlanSetVariableInt(attackPlan, cAttackPlanTargetTypeID, 1, gDockUnit);
            aiPlanSetVariableVector(attackPlan, cAttackPlanGatherPoint, 0, gNavyVec);
            aiPlanSetVariableFloat(attackPlan, cAttackPlanGatherDistance, 0, 30.0);
            aiPlanSetVariableInt(attackPlan, cAttackPlanRefreshFrequency, 0, 5);
            aiPlanSetDesiredPriority(attackPlan, 48); // Above defend, fishing.  Below explore.
            aiPlanAddUnitType(attackPlan, cUnitTypeAbstractWarShip, 1, 10, 200);
            // aiPlanAddUnitType(attackPlan, cUnitTypexpWarCanoe, 1, 10, 200);
            aiPlanSetInitialPosition(attackPlan, gNavyVec);
            debugMilitary("***** LAUNCHING NAVAL ATTACK, plan ID is " + attackPlan);
            aiPlanSetActive(attackPlan, true);
         }
      }
   }
   
   static int navyRepairPlan = -1;
   static int dockID = -1;
   vector dockPosition = kbUnitGetPosition(dockID);

   if (dockID < 0 || kbUnitGetPosition(dockID) == cInvalidVector)
      dockID = getUnit(gDockUnit, cMyID, cUnitStateAlive);

   if (dockID < 0)
   {
      if (navyRepairPlan >= 0)
      {
         aiPlanDestroy(navyRepairPlan);
         navyRepairPlan = -1;
      }
   }
   else
   {
      if (navyRepairPlan < 0)
      {
         navyRepairPlan = aiPlanCreate("Navy repair plan", cPlanDefend);
         aiPlanSetVariableFloat(navyRepairPlan, cDefendPlanEngageRange, 0, 10.0);
         aiPlanSetVariableBool(navyRepairPlan, cDefendPlanPatrol, 0, false);
         aiPlanSetVariableFloat(navyRepairPlan, cDefendPlanGatherDistance, 0, 10.0);
         aiPlanSetInitialPosition(navyRepairPlan, dockPosition);
         aiPlanSetUnitStance(navyRepairPlan, cUnitStanceDefensive);
         aiPlanSetVariableInt(navyRepairPlan, cDefendPlanRefreshFrequency, 0, 20);
         aiPlanSetVariableInt(navyRepairPlan, cDefendPlanAttackTypeID, 0, cUnitTypeUnit); // Only units
         aiPlanSetDesiredPriority(navyRepairPlan, 50);
         aiPlanSetActive(navyRepairPlan);
      }

      int unitID = -1;
      int bestUnitID = -1;

      numberFound = aiPlanGetNumberUnits(navyRepairPlan);
      for (i = 0; < numberFound)
      {
         unitID = aiPlanGetUnitByIndex(navyRepairPlan, i);
         if (kbUnitGetHealth(unitID) > 0.95)
         {
            aiTaskUnitMove(unitID, gNavyVec);
            continue;
         }
         bestUnitID = unitID;
         break;
      }

      if (bestUnitID < 0)
      {
         // Look for ships to repair
         float unitHitpoints = 0.0;
         int unitPlanID = -1;
         float bestUnitHitpoints = 9999.0;
         int shipQueryID = createSimpleUnitQuery(cUnitTypeAbstractWarShip, cMyID, cUnitStateAlive);
         numberFound = kbUnitQueryExecute(shipQueryID);
         for (i = 0; < numberFound)
         {
            unitID = kbUnitQueryGetResult(shipQueryID, i);
            unitPlanID = kbUnitGetPlanID(unitID);
            if (unitPlanID >= 0 && (aiPlanGetDesiredPriority(unitPlanID) > 50 || aiPlanGetType(unitPlanID) == cPlanTransport ||
                                    kbUnitGetHealth(unitID) > 0.95))
               continue;
            unitHitpoints = kbUnitGetCurrentHitpoints(unitID);
            if (unitHitpoints < bestUnitHitpoints)
            {
               bestUnitID = unitID;
               bestUnitHitpoints = unitHitpoints;
            }
         }
      }

      aiPlanSetVariableVector(navyRepairPlan, cDefendPlanDefendPoint, 0, dockPosition);
      if (bestUnitID >= 0)
      {
         aiPlanAddUnitType(navyRepairPlan, cUnitTypeAbstractWarShip, 1, 1, 1);
         aiPlanAddUnit(navyRepairPlan, bestUnitID);
      }
      else
      {
         aiPlanAddUnitType(navyRepairPlan, cUnitTypeAbstractWarShip, 0, 0, 0);
      }
   }
}

//==============================================================================
/*
   Navy Manager

   Create maintain plans for navy unit lines.  Control 'maintain' levels.
*/
//==============================================================================
rule navyManager
inactive
minInterval 30
{

   if (gNavyMap == false)
   {
      gNavyMode = cNavyModeOff;
      debugMilitary("gNavyMap was false, turning off navy manager.");
      xsDisableSelf();
      return;
   }

   if (gHaveWaterSpawnFlag == false)
   {
      debugMilitary("**** NO WATER FLAG, TURNING NAVY OFF ****");
      xsDisableSelf();
      return;
   }

   int navyEnemyPlayer = getNavalTargetPlayer();
   // If it was not full on...
   if (gNavyMode == cNavyModeOff)
   { // We're not currently training a navy...see if we should be
      // Turning it on by default, now that we have variable maintain levels
      // gNavyMode = cNavyModeActive;
      if (navyEnemyPlayer > 0)
      {
         gNavyMode = cNavyModeActive; // They have a navy.
         debugMilitary("Saw enemy naval units.");
      }

      if (cvOkToTrainNavy == false)
         gNavyMode = cNavyModeOff; // Overrides others.

      if (gNavyMode == cNavyModeActive) // We're turning it on
      {
         if (gCaravelMaintain >= 0)
            aiPlanSetActive(gCaravelMaintain, true);
         if (gGalleonMaintain >= 0)
            aiPlanSetActive(gGalleonMaintain, true);
         if (gFrigateMaintain >= 0)
            aiPlanSetActive(gFrigateMaintain, true);
         if (gMonitorMaintain >= 0)
            aiPlanSetActive(gMonitorMaintain, true);
         debugMilitary("**** TURNING NAVY ON ****");
      }
      else
         debugMilitary("No navy targets detected.");
   }

   if (gNavyMode == cNavyModeOff)
      return; // We didn't turn it on, so we're done

   // If we're here, navyMode is active.  See if we need to turn it off
   if (cvOkToTrainNavy == false)
      gNavyMode = cNavyModeOff;

   // If we don't see any naval targets or threats, turn it off.
   // Disabling this now that we added variable maintain plans.  If no enemy navy is visible, maintain a small force.
   // if (navyTargetPlayer < 0)
   //   gNavyMode = cNavyModeOff;      // No need for a navy, we don't see targets any more

   if (gNavyMode != cNavyModeActive)
   { // It's been turned off or set to explore, stop the plans
      debugMilitary("**** TURNING NAVY OFF BECAUSE WE SEE NO DOCKS OR SHIPS ****");
      if (gCaravelMaintain >= 0)
         aiPlanSetActive(gCaravelMaintain, false);
      if (gGalleonMaintain >= 0)
         aiPlanSetActive(gGalleonMaintain, false);
      if (gFrigateMaintain >= 0)
         aiPlanSetActive(gFrigateMaintain, false);
      if (gMonitorMaintain >= 0)
         aiPlanSetActive(gMonitorMaintain, false);
   }
   if (gNavyMode == cNavyModeOff)
      return;

   // If we're here, gNavyMode is active, and it should be.  Make sure we have a dock, then make sure maintain plans
   // exist.

   vector flagVec = cInvalidVector;
   int flagUnit = getUnit(cUnitTypeHomeCityWaterSpawnFlag, cMyID);
   if (flagUnit >= 0)
   {
      flagVec = kbUnitGetPosition(flagUnit);
   }
   else
   {
      int closestDock = getUnitByLocation(
          gDockUnit, cMyID, cUnitStateAlive, kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)), 500.0);
      if (closestDock >= 0)
         flagVec = kbUnitGetPosition(closestDock);
   }
   if ((gNavyVec == cInvalidVector) && (flagVec != cInvalidVector))
      gNavyVec = flagVec; // Set global vector

   if ((kbUnitCount(cMyID, gDockUnit, cUnitStateABQ) < 1) &&
       (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, gDockUnit) < 0) && (kbGetAge() >= cAge2))
   { // No dock and not making any, let's start a plan.
      createSimpleBuildPlan(gDockUnit, 1, 70, true, cMilitaryEscrowID, kbBaseGetMainID(cMyID), 1);
      return; // Nothing else to do until dock is complete
   }

   closestDock = getUnitByLocation(gDockUnit, cMyID, cUnitStateAlive, flagVec, 500.0);
   if (closestDock < 0)
      closestDock = getUnit(gDockUnit, cMyID, cUnitStateAlive);

   createWaterExplorePlan();

   if (closestDock < 0)
      return; // Don't fire up maintain plans until we have a base ID

   int baseID = kbUnitGetBaseID(closestDock);
   if (baseID < 0)
      return; // Don't fire up maintain plans until we have a base ID

   if (gWaterExploreMaintain < 0)
   {
      gWaterExploreMaintain = createSimpleMaintainPlan(gFishingUnit, 1, true, baseID, 1);
   }

   if ((gCaravelMaintain < 0) && (gNavyMode == cNavyModeActive)) // Need to init plans
   {
      if (cMyCiv == cCivXPAztec)
      {
         gCaravelMaintain = createSimpleMaintainPlan(gCaravelUnit, 10, false, baseID, 1); // xpWarCanoe
         gGalleonMaintain = createSimpleMaintainPlan(gGalleonUnit, 20, false, baseID, 1); // Canoe
         gFrigateMaintain = createSimpleMaintainPlan(gGalleonUnit, 5, false, baseID, 1);  // TlalocCanoe
      }
      else if (cMyCiv == cCivDEInca)
      {
         gCaravelMaintain = createSimpleMaintainPlan(gCaravelUnit, 8, false, baseID, 1); // deChinchaRaft
      }
      else if (civIsNative() == true)
      {
         gCaravelMaintain = createSimpleMaintainPlan(gCaravelUnit, 10, false, baseID, 1); // xpWarCanoe
         gGalleonMaintain = createSimpleMaintainPlan(gGalleonUnit, 20, false, baseID, 1); // Canoe
      }
      else if ((cMyCiv == cCivChinese) || (cMyCiv == cCivSPCChinese))
      {
         gCaravelMaintain = createSimpleMaintainPlan(gCaravelUnit, 5, false, baseID, 1); // War Junk
         gFrigateMaintain = createSimpleMaintainPlan(gFrigateUnit, 3, false, baseID, 1); // Fuchuan
         gMonitorMaintain = createSimpleMaintainPlan(gMonitorUnit, 2, false, baseID, 1);
      }
      else if (civIsAfrican() == true)
      {
         gCaravelMaintain = createSimpleMaintainPlan(gCaravelUnit, 5, false, baseID, 1); // Battle Canoe
         gFrigateMaintain = createSimpleMaintainPlan(gFrigateUnit, 2, false, baseID, 1); // Dhow/Xebec
         gMonitorMaintain = createSimpleMaintainPlan(gMonitorUnit, 2, false, baseID, 1); // Cannon Boat
      }
      else
      {
         gCaravelMaintain = createSimpleMaintainPlan(gCaravelUnit, 5, false, baseID, 1);
         gGalleonMaintain = createSimpleMaintainPlan(gGalleonUnit, 3, false, baseID, 1);
         gFrigateMaintain = createSimpleMaintainPlan(gFrigateUnit, 3, false, baseID, 1);
         gMonitorMaintain = createSimpleMaintainPlan(gMonitorUnit, 2, false, baseID, 1);
      }
      debugMilitary("**** ACTIVATING NAVAL TRAIN PLANS ****");
   }

   int numberCaravels = 0;
   int numberGalleons = 0;
   int numberFrigates = 0;
   int numberMonitors = 0;

   // Train some navy when we want to defend fishing boats or boom.
   if (gStartOnDifferentIslands == true || gTimeToFish == true || (btRushBoom <= 0.0 && kbGetAge() >= cAge3))
   {
      int navyQuery = -1;
      int navySize = 0;
      float netNavyValue = 0.0;
      int unitID = -1;
      int puid = -1;

      navyQuery = createSimpleUnitQuery(cUnitTypeAbstractWarShip, navyEnemyPlayer, cUnitStateAlive);
      navySize = kbUnitQueryExecute(navyQuery);

      for (i = 0; < navySize)
      {
         unitID = kbUnitQueryGetResult(navyQuery, i);
         puid = kbUnitGetProtoUnitID(unitID);
         netNavyValue = netNavyValue +
                        (kbUnitCostPerResource(puid, cResourceWood) + kbUnitCostPerResource(puid, cResourceGold));
      }

      navyQuery = createSimpleUnitQuery(cUnitTypeAbstractWarShip, cMyID, cUnitStateABQ);
      navySize = kbUnitQueryExecute(navyQuery);

      int caravelLimit = 0;
      int galleonLimit = 0;
      int frigateLimit = 0;
      int monitorLimit = 0;

      caravelLimit = kbGetBuildLimit(cMyID, gCaravelUnit);
      if (cMyCiv == cCivXPAztec || cMyCiv == cCivXPIroquois || cMyCiv == cCivXPSioux)
         galleonLimit = kbGetBuildLimit(cMyID, gGalleonUnit);
      if (cMyCiv != cCivXPIroquois && cMyCiv != cCivXPSioux && cMyCiv != cCivDEInca && kbGetAge() >= cAge3)
         frigateLimit = kbGetBuildLimit(cMyID, gFrigateUnit);
      if (civIsNative() == false && kbGetAge() >= cAge4)
         monitorLimit = kbGetBuildLimit(cMyID, gMonitorUnit);

      for (i = 0; < navySize)
      {
         unitID = kbUnitQueryGetResult(navyQuery, i);
         puid = kbUnitGetProtoUnitID(unitID);
         netNavyValue = netNavyValue -
                        (kbUnitCostPerResource(puid, cResourceWood) + kbUnitCostPerResource(puid, cResourceGold));

         switch (puid)
         {
         case gCaravelUnit:
         {
            numberCaravels = numberCaravels + 1;
            break;
         }
         case gGalleonUnit:
         {
            numberGalleons = numberGalleons + 1;
            break;
         }
         case gFrigateUnit:
         {
            numberFrigates = numberFrigates + 1;
            break;
         }
         case gMonitorUnit:
         {
            numberMonitors = numberMonitors + 1;
            break;
         }
         }
      }

      // 1 more caravel or equivalent amount of war ships than enemy.
      netNavyValue = netNavyValue + 400.0;
      debugMilitary("Navy enemy player is " + navyEnemyPlayer + ", net navy value is " + netNavyValue);

      int caravelValue = kbUnitCostPerResource(gCaravelUnit, cResourceWood) +
                         kbUnitCostPerResource(gCaravelUnit, cResourceGold);
      int galleonValue = kbUnitCostPerResource(gGalleonUnit, cResourceWood) +
                         kbUnitCostPerResource(gGalleonUnit, cResourceGold);
      // African dhows/xebecs cost influence
      int frigateValue = kbUnitCostPerResource(gFrigateUnit, cResourceWood) +
                         kbUnitCostPerResource(gFrigateUnit, cResourceGold) +
                         kbUnitCostPerResource(gFrigateUnit, cResourceInfluence);
      int monitorValue = kbUnitCostPerResource(gMonitorUnit, cResourceWood) +
                         kbUnitCostPerResource(gMonitorUnit, cResourceGold);

      // Prioritize ships in the following order - frigate, caravel, monitor, galleon
      while (netNavyValue > 0.0)
      {
         if (numberFrigates < frigateLimit)
         {
            numberFrigates = numberFrigates + 1;
            netNavyValue = netNavyValue - frigateValue;
            continue;
         }
         if (numberCaravels < caravelLimit)
         {
            numberCaravels = numberCaravels + 1;
            netNavyValue = netNavyValue - caravelValue;
            continue;
         }
         if (numberMonitors < monitorLimit)
         {
            numberMonitors = numberMonitors + 1;
            netNavyValue = netNavyValue - monitorValue;
            continue;
         }
         if (numberGalleons < galleonLimit)
         {
            numberGalleons = numberGalleons + 1;
            netNavyValue = netNavyValue - galleonValue;
            continue;
         }
         break;
      }
   }

   if (gCaravelMaintain >= 0)
      aiPlanSetVariableInt(gCaravelMaintain, cTrainPlanNumberToMaintain, 0, numberCaravels);
   if (gGalleonMaintain >= 0)
      aiPlanSetVariableInt(gGalleonMaintain, cTrainPlanNumberToMaintain, 0, numberGalleons);
   if (gMonitorMaintain >= 0)
      aiPlanSetVariableInt(gMonitorMaintain, cTrainPlanNumberToMaintain, 0, numberMonitors);
   if (gFrigateMaintain >= 0)
      aiPlanSetVariableInt(gFrigateMaintain, cTrainPlanNumberToMaintain, 0, numberFrigates);
}

/*
void setUnitPickerCommon(int upID = -1)
{
   int targetPlayer = aiGetMostHatedPlayerID();

   kbUnitPickSetPreferenceWeight(upID, 1.0);
   if (gSPC == false)
   {
      kbUnitPickSetCombatEfficiencyWeight(upID,
                                          2.0); // Changed from 1.0 to dilute the power of the preference weight.
      // Late in game, less focus on taking down buildings.
      if (xsGetTime() < 900000 || kbUnitCount(targetPlayer, cUnitTypeBuilding, cUnitStateAlive | cUnitStateBuilding) >= 70)
         kbUnitPickSetBuildingCombatEfficiencyWeight(upID, 0.5);
      else
         kbUnitPickSetBuildingCombatEfficiencyWeight(upID, 0.0);
   }
   else
   {
      kbUnitPickSetCombatEfficiencyWeight(upID, 1.0); // Leave it at 1.0 to avoid messing up SPC balance
      kbUnitPickSetBuildingCombatEfficiencyWeight(upID, 0.25);
   }
   kbUnitPickSetCostWeight(upID, 0.0);

   // Default to land units.
   kbUnitPickSetEnemyPlayerID(upID, targetPlayer);
   kbUnitPickSetAttackUnitType(upID, cUnitTypeLogicalTypeLandMilitary);

   // Set the default target types and weights, for use until we've seen enough actual units.
   kbUnitPickAddCombatEfficiencyType(upID, cUnitTypeLogicalTypeLandMilitary, 1.0);

   kbUnitPickAddBuildingCombatEfficiencyType(upID, cUnitTypeMilitaryBuilding, 1.0);
   kbUnitPickAddBuildingCombatEfficiencyType(upID, cUnitTypeAbstractTownCenter, 1.0);
}
*/

void setUnitPickerDisabledUnits(int upID = -1)
{
   kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractNativeWarrior, 0.0);

   if (cMyCiv == cCivFrench)
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeCoureur,
                                    0.0); // Avoid coureurs, they mess up econ/mil calcs.

   if (civIsNative() == true)
      kbUnitPickSetPreferenceFactor(
          upID,
          cUnitTypexpWarrior,
          0.0); // Never pick xpWarrior or xpDogSoldier, available via dance only
   if (cMyCiv == cCivXPSioux)
      kbUnitPickSetPreferenceFactor(upID, cUnitTypexpDogSoldier, 0.0);
   if (cMyCiv == cCivXPAztec)
   {
      kbUnitPickSetPreferenceFactor(upID, cUnitTypexpMedicineManAztec, 0.0);
      kbUnitPickSetPreferenceFactor(upID, cUnitTypexpSkullKnight, 0.0);
   }
   kbUnitPickSetPreferenceFactor(upID, cUnitTypeypMercFlailiphant, 0.0);
   /*kbUnitPickSetPreferenceFactor(upID, cUnitTypeypMercIronTroop, 0.0);
   kbUnitPickSetPreferenceFactor(upID, cUnitTypeypMercYojimbo, 0.0);*/

   if ((cMyCiv == cCivIndians) || (cMyCiv == cCivSPCIndians))
   {
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeypSowarMansabdar, 0.0);
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeypRajputMansabdar, 0.0);
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeypSepoyMansabdar, 0.0);
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeypUrumiMansabdar, 0.0);
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeypZamburakMansabdar, 0.0);
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeypNatMercGurkhaJemadar, 0.0);
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeypMercFlailiphantMansabdar, 0.0);
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeypHowdahMansabdar, 0.0);
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeypMahoutMansabdar, 0.0);
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeypSiegeElephantMansabdar, 0.0);
   }

   if (cMyCiv == cCivDEInca)
      kbUnitPickSetPreferenceFactor(upID, cUnitTypedeChasqui, 0.0);

   if (civIsAfrican() == true)
   {
      // Exclude units costing influence
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeMercenary, 0.0);
      kbUnitPickSetPreferenceFactor(upID, cUnitTypedeBowmanLevy, 0.0);
      kbUnitPickSetPreferenceFactor(upID, cUnitTypedeSpearmanLevy, 0.0);
      kbUnitPickSetPreferenceFactor(upID, cUnitTypedeGunnerLevy, 0.0);
      kbUnitPickSetPreferenceFactor(upID, cUnitTypedeMaigadi, 0.0);
      kbUnitPickSetPreferenceFactor(upID, cUnitTypedeSebastopolMortar, 0.0);
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeFalconet, 0.0);
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeOrganGun, 0.0);
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeCulverin, 0.0);
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeMortar, 0.0);
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeypMahout, 0.0);
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeypHowdah, 0.0);
   }

   if (civIsAsian() == true && upID == gLandUnitPicker)
   {
      // Remove consulate units.
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractConsulateSiegeFortress, 0.0);
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractConsulateSiegeIndustrial, 0.0);
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractConsulateUnit, 0.0);
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractConsulateUnitColonial, 0.0);
   }
}


void setStandardArmyPreference() 
{ 
   //kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypexpColonialMilitia, 0.5);
   kbUnitPickSetPreferenceFactor(gLandUnitPicker, gLandPrimaryArmyUnit, 0.5);
   kbUnitPickSetPreferenceFactor(gLandUnitPicker, gLandSecondaryArmyUnit, 0.3);
   kbUnitPickSetPreferenceFactor(gLandUnitPicker, gLandTertiaryArmyUnit, 0.2);
   //kbUnitPickSetPreferenceFactor(gLandUnitPicker, gAbstractArtilleryUnit, 0.1);
   //if (kbGetAge() >= cAge4)
   //{
   ////kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeAbstractNativeWarrior, 0.5); 
   //}   
}

/* setUnitPickerPreference()

   Updates the unit picker biases, arbitrates between the potentially conflicting sources.

   Priority order is:

      1)  If control is from a trigger, that wins.  The unit line specified in gCommandUnitLine gets a +.8, all others
   +.2 2)  If control is ally command, ditto.  (Can only be one unit due to UI limits. 3)  If we're not under command,
   but cvPrimaryArmyUnit (and optionally cvSecondaryArmyUnit) are set, they rule. If just primary, it gets .8 to .2 for
   other classes. If primary and secondary, they get 1.0 and 0.5, others get 0.0. 4)  If not under command and no cv's
   are set, we go with the btBiasCav, btBiasInf and btBiasArt line settings.

*/

void setUnitPickerPreference(int upID = -1)
{
   // Add the main unit lines
   if (upID < 0)
      return;

   int enemyPlayerID = aiGetMostHatedPlayerID();

   // Check for commanded unit preferences.
   if ((gUnitPickSource == cOpportunitySourceTrigger) || (gUnitPickSource == cOpportunitySourceAllyRequest))
   { // We have an ally or trigger command, so bias everything for that one unit
      if (cvPrimaryArmyUnit < 0)
         return; // This should never happen, it should be set when the unitPickSource is set.

      kbUnitPickResetAll(upID);

      kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractInfantry, 0.2); // Range 0.0 to 1.0
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractArtillery, 0.2);
      kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractCavalry, 0.2);
      if (cMyCiv == cCivXPAztec)
         kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractLightInfantry, 0.2);
      if (cMyCiv == cCivDEEthiopians || cMyCiv == cCivDEInca)
         kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractCoyoteMan, 0.2);

      setUnitPickerDisabledUnits(upID);

      kbUnitPickSetPreferenceFactor(upID, cvPrimaryArmyUnit, 0.8);

      kbUnitPickRemovePreferenceFactor(upID, cUnitTypeAbstractBannerArmy);

      return;
   }

   // Check for cv settings
   if (cvPrimaryArmyUnit >= 0)
   {
      kbUnitPickResetAll(upID);

      // See if 1 or 2 lines set.  If 1, score 0.8 vs. 0.2.  If 2, score 1.0, 0.5 and 0.0.
      if (cvSecondaryArmyUnit < 0)
      {
         kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractInfantry, 0.2); // Range 0.0 to 1.0
         kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractArtillery, 0.2);
         kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractCavalry, 0.2);
         if (cMyCiv == cCivXPAztec)
            kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractLightInfantry, 0.2);
         if (cMyCiv == cCivDEEthiopians || cMyCiv == cCivDEInca)
            kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractCoyoteMan, 0.2);

         setUnitPickerDisabledUnits(upID);

         kbUnitPickSetPreferenceFactor(upID, cvPrimaryArmyUnit, 0.8);
         kbUnitPickRemovePreferenceFactor(upID, cUnitTypeAbstractBannerArmy);
      }
      else
      {
         kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractInfantry, 0.0); // Range 0.0 to 1.0
         kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractArtillery, 0.0);
         kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractCavalry, 0.0);
         if (cMyCiv == cCivXPAztec)
            kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractLightInfantry, 0.0);
         if (cMyCiv == cCivDEEthiopians || cMyCiv == cCivDEInca)
            kbUnitPickSetPreferenceFactor(upID, cUnitTypeAbstractCoyoteMan, 0.0);

         setUnitPickerDisabledUnits(upID);

         kbUnitPickSetPreferenceFactor(upID, cvPrimaryArmyUnit, 1.0);
         kbUnitPickSetPreferenceFactor(upID, cvSecondaryArmyUnit, 0.5);
         if (cvTertiaryArmyUnit >= 0)
         {
            kbUnitPickSetPreferenceFactor(upID, cvTertiaryArmyUnit, 0.5);
         }

         kbUnitPickRemovePreferenceFactor(upID, cUnitTypeAbstractBannerArmy);
      }
      return;
   }

   static bool counterUnitMode = false;
   int unitPreferenceRandomizer = aiRandInt(10); // 0-9
   //int heavycav = (kbUnitCount(enemyToCounter, cUnitTypeAbstractHeavyCavalry, cUnitStateAlive) + kbUnitCount(enemyToCounter, AbstractCoyoteMan, cUnitStateAlive))
   //kbUnitCount(enemyToCounter, cUnitTypeAbstractHeavyCavalry, cUnitStateAlive) = (kbUnitCount(enemyToCounter, cUnitTypeAbstractHeavyCavalry, cUnitStateAlive) + kbUnitCount(enemyToCounter, AbstractCoyoteMan, cUnitStateAlive))
   float enemyToCounter = aiGetMostHatedPlayerID();
   //float enemyToCounter = cPlayerRelationEnemyNotGaia;
   //float heavycav = (kbUnitCount(enemyToCounter, cUnitTypeAbstractHeavyCavalry, cUnitStateAlive) + kbUnitCount(enemyToCounter, cUnitTypeAbstractCoyoteMan, cUnitStateAlive))
   float lightInfantryCount = kbUnitCount(enemyToCounter, cUnitTypeAbstractHeavyInfantry, cUnitStateAlive) +
                              kbUnitCount(enemyToCounter, cUnitTypeAbstractLightCavalry, cUnitStateAlive); 
   float heavyCavalryCount =  kbUnitCount(enemyToCounter, cUnitTypeAbstractRangedInfantry, cUnitStateAlive) - 
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractMusketeer, cUnitStateAlive)+ 
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractArtillery, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractLancer, cUnitStateAlive);
   float heavyInfantryCount = kbUnitCount(enemyToCounter, cUnitTypeAbstractCavalry, cUnitStateAlive) - 
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractLancer, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractLightInfantry, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractHeavyCavalry, cUnitStateAlive);
   float lightCavalryCount =  kbUnitCount(enemyToCounter, cUnitTypeAbstractHeavyCavalry, cUnitStateAlive) + 
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractLancer, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractArtillery, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractLightInfantry, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeCuirassier, cUnitStateAlive);
   float artilleryCount = 	  kbUnitCount(enemyToCounter, cUnitTypeAbstractInfantry, cUnitStateAlive);/* - 
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractArtillery, cUnitStateAlive) -
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractHeavyCavalry, cUnitStateAlive);*/
   float coreUnitCount = 	  kbUnitCount(enemyToCounter, cUnitTypeLogicalTypeLandMilitary, cUnitStateAlive);
   float totalEnemyCount =    lightInfantryCount + heavyCavalryCount + heavyInfantryCount + lightCavalryCount + artilleryCount;
   float MahoutCount =  	  kbUnitCount(enemyToCounter, cUnitTypeAbstractRangedInfantry, cUnitStateAlive) - 
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractMusketeer, cUnitStateAlive)+ 
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractArtillery, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractLancer, cUnitStateAlive);
   float HowdahCount =  	  kbUnitCount(enemyToCounter, cUnitTypeAbstractHeavyCavalry, cUnitStateAlive)+ 
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractLancer, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractArtillery, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractLightInfantry, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeCuirassier, cUnitStateAlive); 
   float LancerCount =  	  kbUnitCount(enemyToCounter, cUnitTypeAbstractArtillery, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractInfantry, cUnitStateAlive);
   float SiegeTrooperCount =  kbUnitCount(enemyToCounter, cUnitTypeAbstractInfantry, cUnitStateAlive);
   float AbusGunCount = 	  kbUnitCount(enemyToCounter, cUnitTypeAbstractInfantry, cUnitStateAlive);
   float JanissaryCount = 	  kbUnitCount(enemyToCounter, cUnitTypeAbstractHeavyInfantry, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractLightInfantry, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractCavalry, cUnitStateAlive);
   float OttoHussarCount =    kbUnitCount(enemyToCounter, cUnitTypeAbstractRangedInfantry, cUnitStateAlive) - 
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractMusketeer, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractHeavyCavalry, cUnitStateAlive)+ 
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractLancer, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractArtillery, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeCuirassier, cUnitStateAlive);
   float CuirassierCount =    kbUnitCount(enemyToCounter, cUnitTypeAbstractRangedInfantry, cUnitStateAlive) - 
							  kbUnitCount(enemyToCounter, cUnitTypeWarWagon, cUnitStateAlive) - 
							  kbUnitCount(enemyToCounter, cUnitTypeDopplesoldner, cUnitStateAlive) - 
							  kbUnitCount(enemyToCounter, cUnitTypeypKensei, cUnitStateAlive) - 
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractHowdah, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractCavalry, cUnitStateAlive)+ 
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractLancer, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractArtillery, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeCuirassier, cUnitStateAlive);
   float SamuraiCount = 	  kbUnitCount(enemyToCounter, cUnitTypeAbstractHandInfantry, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractHeavyCavalry, cUnitStateAlive) -
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractRangedInfantry, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractLightInfantry, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeCuirassier, cUnitStateAlive);
   float EspadaCount = 	  	  kbUnitCount(enemyToCounter, cUnitTypeAbstractCavalry, cUnitStateAlive) -
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractRangedInfantry, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractLightInfantry, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeCuirassier, cUnitStateAlive);
   float JaguarKnightCount =  kbUnitCount(enemyToCounter, cUnitTypeAbstractHeavyInfantry, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractHeavyCavalry, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractLightInfantry, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeCuirassier, cUnitStateAlive);
   float RifleRiderCount = 	  kbUnitCount(enemyToCounter, cUnitTypeAbstractHeavyInfantry, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractHeavyCavalry, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractArtillery, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractLightInfantry, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeCuirassier, cUnitStateAlive);
   float TercioCount = 	  	  kbUnitCount(enemyToCounter, cUnitTypeAbstractHeavyCavalry, cUnitStateAlive) -
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractRangedInfantry, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractLightInfantry, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeCuirassier, cUnitStateAlive);
   float SiegeCount = 	  	  kbUnitCount(enemyToCounter, cUnitTypeTownCenter, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeFortFrontier, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypedeIncaStronghold, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypedeKallanka, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeCWallGate, cUnitStateAlive);
   float CounterArtCount = 	  kbUnitCount(enemyToCounter, cUnitTypeAbstractArtillery, cUnitStateAlive) -
							  kbUnitCount(enemyToCounter, gAbstractCounterArtilleryUnit, cUnitStateAlive);
   float AssassinCount = 	  kbUnitCount(enemyToCounter, cUnitTypeMercenary, cUnitStateAlive);
   float BolasCount = 	  	  kbUnitCount(enemyToCounter, cUnitTypeAbstractCavalry, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractLightInfantry, cUnitStateAlive); /*-
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractInfantry, cUnitStateAlive);*/
   float ArrowKnightCount =   kbUnitCount(enemyToCounter, cUnitTypeAbstractArtillery, cUnitStateAlive); 
   float MantletCount =   	  kbUnitCount(enemyToCounter, cUnitTypeRanged, cUnitStateAlive); 
   float BowRiderCount = 	  kbUnitCount(enemyToCounter, cUnitTypeAbstractHeavyCavalry, cUnitStateAlive) + 
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractLancer, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractArtillery, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractLightInfantry, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeAbstractLightCavalry, cUnitStateAlive) +
							  kbUnitCount(enemyToCounter, cUnitTypeCuirassier, cUnitStateAlive);
   if (totalEnemyCount > 5)
   {  
      counterUnitMode = true;
      /* We see one of this player's units for the first time...let's do some analysis on it
         Setup the military unit preferences.  These are just various strategies of unit
         combos and what-not that are more or less setup to coincide with the bonuses
         and mainline units of each civ.  We start with a random choice.  If we have
         an enemy unit type to preference against, we override that random choice.
         0:  Counter infantry (i.e. enemyToCounter == cUnitTypeAbstractInfantry).
         1:  Counter artillery (i.e. enemyToCounter == cUnitTypeAbstractArtillery).
         2:  Counter cavalry (i.e. enemyToCounter == cUnitTypeAbstractCavalry).
      */
      // Calculate enemy's basic unit ratio and favor appropriate counters
      float lightInfantryFactor = lightInfantryCount * 2 / totalEnemyCount;
      float heavyInfantryFactor = heavyInfantryCount * 2 / totalEnemyCount;
      float JanissaryFactor = JanissaryCount * 2 / totalEnemyCount;
      float coreUnitFactor = coreUnitCount * 2 / totalEnemyCount;
      float TercioFactor = TercioCount * 2 / totalEnemyCount;
      float ArrowKnightFactor = ArrowKnightCount * 2 / totalEnemyCount;
      float JaguarKnightFactor = JaguarKnightCount * 2 / totalEnemyCount;
      float EspadaFactor = EspadaCount * 2 / totalEnemyCount;
      float BolasFactor = BolasCount * 1.5 / totalEnemyCount;
      float CuirassierFactor = CuirassierCount * 2 / totalEnemyCount;
      float MantletFactor = MantletCount * 1.5 / totalEnemyCount;
      float lightCavalryFactor = lightCavalryCount * 2 / totalEnemyCount;
      float heavyCavalryFactor = heavyCavalryCount * 2 / totalEnemyCount;
      float MahoutFactor = MahoutCount * 2 / totalEnemyCount;
      float HowdahFactor = HowdahCount * 2 / totalEnemyCount;
      float LancerFactor = LancerCount * 2 / totalEnemyCount;
      float SiegeTrooperFactor = SiegeTrooperCount * 1.5 / totalEnemyCount;
      float AbusGunFactor = AbusGunCount * 1.5 / totalEnemyCount;
      float SamuraiFactor = SamuraiCount * 2 / totalEnemyCount;
      float RifleRiderFactor = RifleRiderCount * 2 / totalEnemyCount;
      float OttoHussarFactor = OttoHussarCount * 2 / totalEnemyCount;
      float SiegeFactor = SiegeCount * .5 / totalEnemyCount;
      float CounterArtFactor = CounterArtCount * .2 / totalEnemyCount;
      float artilleryFactor = artilleryCount * 0.5 / totalEnemyCount;
      float AssassinFactor = AssassinCount * 2 / totalEnemyCount;
      float ShinobiFactor = lightInfantryCount * 2 / totalEnemyCount;
      float MercTercioFactor = TercioCount * 2 / totalEnemyCount;
      float MercAssassinFactor = AssassinCount * 2 / totalEnemyCount;
      float MerclightInfantryFactor = lightInfantryCount * 2 / totalEnemyCount;
      float MercJanissaryFactor = JanissaryCount * 2 / totalEnemyCount;
      float MercCuirassierFactor = CuirassierCount * 2 / totalEnemyCount;
      float MerclightCavalryFactor = lightCavalryCount * 2 / totalEnemyCount;
      float MercheavyCavalryFactor = heavyCavalryCount * 2 / totalEnemyCount;
      float MercLancerFactor = LancerCount * 2 / totalEnemyCount;
      float MercSamuraiFactor = SamuraiCount * 2 / totalEnemyCount;
      float MercartilleryFactor = artilleryCount * 0.5 / totalEnemyCount;
      float BowRiderFactor = BowRiderCount * 2 / totalEnemyCount;
	  static int lastprompttime = 0;
	  static int lastprompttimecav = 0;
	  static int lastprompttimeart = 0;
	  /*
	  if ((xsGetTime() - lastprompttime) > 240000)
	  {
       if ( ((lightInfantryFactor >= 1.0) || (heavyInfantryFactor >= 1.0) || (JanissaryFactor >= 1.0) || (TercioFactor >= 1.0)) && (kbUnitCount(cMyID, cUnitTypeAbstractInfantry, cUnitStateABQ) > 9) )
	    {
	      sendStatement(cPlayerRelationAlly, cAICommPromptToAllyConfirmInf); 
	      lastprompttime = xsGetTime();
	    }
	  }
	  if ((xsGetTime() - lastprompttimecav) > 240000)
	  {
      if ( ((lightCavalryFactor >= 1.0) || (LancerFactor >= 1.0) || (heavyCavalryFactor >= 1.0)) && (kbUnitCount(cMyID, cUnitTypeAbstractCavalry, cUnitStateABQ) > 9) )
	    {
	      sendStatement(cPlayerRelationAlly, cAICommPromptToAllyConfirmCav); 
	      lastprompttimecav = xsGetTime();
	    }
	  }
	  if ((xsGetTime() - lastprompttimeart) > 240000)
	  {
      if ( (artilleryFactor >= 1.0) && (kbUnitCount(cMyID, cUnitTypeAbstractArtillery, cUnitStateABQ) > 1) )
	    {
         sendStatement(cPlayerRelationAlly, cAICommPromptToAllyConfirmArt);
	     lastprompttimeart = xsGetTime();
	    }
	  }
	 */
	 int age1 = 5;
	 int age2 = 5;
	 int age3 = 5;
	 int age4 = 5;
	 int age5 = 5;
	 int limit = 5;
     int age = kbGetAge();
	 switch (age)
   {
   case cAge1:
   {
      limit = age1;
      break;
   }
   case cAge2:
   {
      limit = age2;
      break;
   }
   case cAge3:
   {
      limit = age3;
      break;
   }
   case cAge4:
   {
      limit = age4;
      break;
   }
   case cAge5:
   {
      limit = age5;
      break;
   }
   }
	  if ((xsGetTime() - lastprompttime) > 240000)
	    {
	 //if ((kbUnitCount(cMyID, cUnitTypeAbstractInfantry, cUnitStateABQ) > limit) && ((lightInfantryFactor >= 1.0) 
	//	 || (heavyInfantryFactor >= 1.0) || (JanissaryFactor >= 1.0) || (TercioFactor >= 1.0)))
	 if ((kbUnitCount(cMyID, cUnitTypeAbstractInfantry, cUnitStateABQ) > limit))
         sendStatement(cPlayerRelationAlly, cAICommPromptToAllyConfirmInf);
	      lastprompttime = xsGetTime();
	    }
	  if ((xsGetTime() - lastprompttimecav) > 240000)
	    {
     //if (((kbUnitCount(cMyID, cUnitTypeAbstractCavalry, cUnitStateABQ)+(kbUnitCount(cMyID, cUnitTypeAbstractLightInfantry, cUnitStateABQ)) > limit) && ((lightCavalryFactor >= 1.0) 
	//	 || (LancerFactor >= 1.0) || (heavyCavalryFactor >= 1.0))))
     if ((kbUnitCount(cMyID, cUnitTypeAbstractCavalry, cUnitStateABQ)+(kbUnitCount(cMyID, cUnitTypeAbstractLightInfantry, cUnitStateABQ)) > limit))
         sendStatement(cPlayerRelationAlly, cAICommPromptToAllyConfirmCav); 
	      lastprompttimecav = xsGetTime();
	    }
	  if ((xsGetTime() - lastprompttimeart) > 240000)
	    {
      if (kbUnitCount(cMyID, cUnitTypeAbstractArtillery, cUnitStateABQ) > 1)
         sendStatement(cPlayerRelationAlly, cAICommPromptToAllyConfirmArt); 
	     lastprompttimeart = xsGetTime();
	    }
	  if ((xsGetTime() - lastprompttimeart) > 240000)
	    {
      if (kbUnitCount(cMyID, cUnitTypeAbstractSiegeTrooper, cUnitStateABQ) > 5)
         sendStatement(cPlayerRelationAlly, cAICommPromptToAllyConfirmArt); 
	     lastprompttimeart = xsGetTime();
	    }
      switch(kbGetCiv())
      { 
          case cCivXPIroquois:
          {
             if (kbGetAge() > cAge2)
			 {
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypexpMusketWarrior, lightInfantryFactor); 
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypexpMusketRider, lightCavalryFactor); 
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypexpMantlet, MantletFactor);   
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypexpHorseman, heavyCavalryFactor*0);  
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypexpAenna, lightInfantryFactor*0); 
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypexpTomahawk, heavyInfantryFactor*0);  
			 }
			 else
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypexpTomahawk, heavyInfantryFactor);    
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypexpAenna, lightInfantryFactor);
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypexpHorseman, heavyCavalryFactor); 
			 }
             break;
          }
          case cCivXPSioux:
          {
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypexpAxeRider, heavyCavalryFactor); 
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypexpBowRider, BowRiderFactor); 
             //if (kbGetAge() > cAge2)  
			 //{
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypexpRifleRider, RifleRiderFactor);
             //kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypexpBowRider, lightInfantryFactor*0); 
			 //}
			 //else
			 //{
             //kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypexpBowRider, lightInfantryFactor); 
			 //}
             break;
          }
          case cCivXPAztec:
          {                                      
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypexpCoyoteMan, heavyCavalryFactor);
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypexpMacehualtin, lightInfantryFactor);
             if (kbGetAge() > cAge2)
			 {
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypexpEagleKnight, lightCavalryFactor*2);  
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypexpEagleKnight, coreUnitFactor);  
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypexpPumaMan, heavyInfantryFactor*0);  
			 }
			 else
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypexpPumaMan, heavyInfantryFactor);  
			 }
             break;
          }
          case cCivChinese:
          {
             if (kbGetAge() > cAge2)
			 {
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypImperialArmy, lightInfantryFactor);
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypImperialArmy, heavyCavalryFactor);
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypForbiddenArmy, heavyCavalryFactor*2);
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypTerritorialArmy, lightInfantryFactor);
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypTerritorialArmy, heavyInfantryFactor);
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypBlackFlagArmy, heavyInfantryFactor);
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypBlackFlagArmy, heavyCavalryFactor); 
			 }
			 else
			 {
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypStandardArmy, lightInfantryFactor);
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypStandardArmy, MahoutFactor);
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypMingArmy, SamuraiFactor);
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypMingArmy, lightCavalryFactor);
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypOldHanArmy, lightInfantryFactor);
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypOldHanArmy, heavyInfantryFactor);
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypMongolianArmy, lightCavalryFactor); 
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypMongolianArmy, heavyCavalryFactor); 
			 }
			 if (kbUnitCount(cMyID, cUnitTypeypFlameThrower, cUnitStateABQ) < 5)
			 {
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypFlameThrower, SiegeTrooperFactor); 
			 }			 
			 else
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypFlameThrower, SiegeTrooperFactor*0);
			 //kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeAbstractConsulateUnit, 0.0); 
             break;
          }
          case cCivJapanese:
          {
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypAshigaru, heavyInfantryFactor);
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypYumi, lightInfantryFactor);    
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypNaginataRider, heavyCavalryFactor);
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypConsulateRonin, heavyCavalryFactor);   
			 //kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeAbstractConsulateUnit, 0.0); 
             break;
          }
          case cCivIndians:
          {                
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypSowar, heavyCavalryFactor); 
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypZamburak, lightCavalryFactor); 
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypNatMercGurkha, lightInfantryFactor);  
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypSepoy, heavyInfantryFactor);
			 //kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeAbstractConsulateUnit, 0.0); 
             if (kbGetAge() > cAge2)
			 {
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypMahout, MahoutFactor); 
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypHowdah, HowdahFactor); 
			 }   
             break;
          }
          case cCivBritish:
          { 
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMusketeer, heavyInfantryFactor);
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeHussar, heavyCavalryFactor);                  
			 if (kbGetAge() > cAge2)
			 {             
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeDragoon, lightCavalryFactor); 
			 //if (kbUnitCount(cMyID, gAbstractArtilleryUnit, cUnitStateABQ+cUnitStateAlive) < 7)
			 if (kbUnitCount(cMyID, gAbstractArtilleryUnit, cUnitStateABQ) < 7)
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, gAbstractArtilleryUnit, artilleryFactor);
		     else
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, gAbstractArtilleryUnit, artilleryFactor*0);
             }
			 if (((kbGetAge() > cAge3) && (kbTechGetStatus(cTechHCImprovedLongbows) == cTechStatusActive)) || (kbGetAge() < cAge3))
			 {             
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeLongbowman, lightInfantryFactor); 
             }
			 else
			 {
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeLongbowman, lightInfantryFactor*0); 
			 }
             break;
          }
          case cCivFrench:
          {
             if (kbGetAge() > cAge2)
			 {  
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeCuirassier, CuirassierFactor);   
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeSkirmisher, lightInfantryFactor);
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMusketeer, lightInfantryFactor*0);   
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeHussar, heavyCavalryFactor*0); 
			 }
			 else
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMusketeer, lightInfantryFactor);   
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeHussar, heavyCavalryFactor);
			 }
			 if ((kbGetAge() == cAge3) || (kbGetAge() == cAge4))
			 {
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeDragoon, lightCavalryFactor);  
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMusketeer, heavyInfantryFactor); 
			 }	
			 else
			 {
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeDragoon, lightCavalryFactor*0);  
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMusketeer, heavyInfantryFactor*0); 
			 }
             break;
           }
           case cCivDutch:
           {  
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeSkirmisher, lightInfantryFactor);    
			 if (kbGetAge() > cAge2)
			 {
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeRuyter, lightCavalryFactor*2);          
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeHussar, OttoHussarFactor*0);           
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeHussar, heavyCavalryFactor);
			 if (kbUnitCount(cMyID, gAbstractArtilleryUnit, cUnitStateABQ) < 7)
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, gAbstractArtilleryUnit, artilleryFactor);
		     else
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, gAbstractArtilleryUnit, artilleryFactor*0);
			 }
			 else
			 {          
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeHussar, OttoHussarFactor); 
			 }
             break;   
           }
           case cCivSpanish:
           {
			 if (kbGetAge() < cAge4)
			 {  
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMusketeer, lightInfantryFactor);  
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypePikeman, TercioFactor);
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeRodelero, EspadaFactor);  
			 }
			 else
			 {  
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMusketeer, lightInfantryFactor*0);  
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypePikeman, TercioFactor*0);
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeRodelero, EspadaFactor*0);  
			 }
             if (kbGetAge() > cAge3)
			 {  
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeSkirmisher, lightInfantryFactor); 
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMusketeer, heavyInfantryFactor);
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeDragoon, lightCavalryFactor);  
			 }
             if (kbGetAge() > cAge2)
			 {  
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeHussar, heavyCavalryFactor*0);
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeLancer, LancerFactor);
			 }
			 else
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeHussar, heavyCavalryFactor);
			 }
              break;
           }
           case cCivGermans:
           {         
             if (kbGetAge() < cAge3)
			 {  
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeCrossbowman, lightInfantryFactor);    
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeUhlan, OttoHussarFactor);  
			 }
			 else
			 {  
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeCrossbowman, lightInfantryFactor*0);    
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeUhlan, OttoHussarFactor*0);    
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeUhlan, heavyCavalryFactor);  
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeSkirmisher, lightInfantryFactor); 
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeWarWagon, lightCavalryFactor); 
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeDopplesoldner, SamuraiFactor); 
			 }
             break;
           }
           case cCivRussians:
           {
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeCossack, OttoHussarFactor);                
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMusketeer, heavyInfantryFactor);
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeStrelet, lightInfantryFactor);  
			 break;
           }
           case cCivPortuguese:
           {
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMusketeer, heavyInfantryFactor);     
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeHussar, heavyCavalryFactor);  
             if (kbGetAge() < cAge3)
			 {  
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMusketeer, lightInfantryFactor);      
			 }
			 else
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMusketeer, lightInfantryFactor*0);    
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeCacadore, lightInfantryFactor);        
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeDragoon, lightCavalryFactor);  
			 if (kbUnitCount(cMyID, gAbstractArtilleryUnit, cUnitStateABQ) < 7)
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, gAbstractArtilleryUnit, artilleryFactor);
		     else
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, gAbstractArtilleryUnit, artilleryFactor*0);
			 }			 
			 break;                
           }
           case cCivOttomans:
           {
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeJanissary, JanissaryFactor); 
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeHussar, OttoHussarFactor);  
			 if (kbGetAge() > cAge2)
			 {
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeAbusGun, AbusGunFactor);
			 }
			 else
			 {
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeAbusGun, AbusGunFactor*0);
			 if (kbUnitCount(cMyID, gAbstractArtilleryUnit, cUnitStateABQ) < 7)
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, gAbstractArtilleryUnit, artilleryFactor);
		     else
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, gAbstractArtilleryUnit, artilleryFactor*0);
			 }   
             break;       
           }
		   case cCivDESwedish:
           {         
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeCarolean, JanissaryFactor); 
			 if (kbUnitCount(cMyID, cUnitTypedeLeatherCannon, cUnitStateABQ) < 10)
			 {
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeLeatherCannon, artilleryFactor);
			 }
			 else
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeLeatherCannon, artilleryFactor*0);
             if (kbGetAge() < cAge3)
			 {  
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeHussar, heavyCavalryFactor); 
			 }
			 else
			 {
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeFinnishRider, heavyCavalryFactor); 
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeHussar, heavyCavalryFactor*0); 
			 }
             break;
           }
		   case cCivDEInca:
           {         
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeJungleBowman, lightInfantryFactor); 
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeIncaRunner, heavyCavalryFactor);
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeChasqui, 0.0);
             if ((kbGetAge() > cAge2) || (kbTechGetStatus(cTechDEHCEarlyKallanka) == cTechStatusActive))
			 {      
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeIncaSpearman, heavyInfantryFactor*0);  
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeIncaSpearman, TercioFactor); 
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeBolasWarrior, BolasFactor); 
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeSlinger, SiegeTrooperFactor); 
			 }
			 else
			 {
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeIncaSpearman, heavyInfantryFactor);  
			 }
             break;
           }
		   case cCivDEAmericans:
           {         
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeRegular, heavyInfantryFactor); 
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeHussar, heavyCavalryFactor);  
			 if (kbTechGetStatus(cTechDEHCLegionHungarian) == cTechStatusActive)
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeLegionMagyarHussar, heavyCavalryFactor*2);
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeStateMilitia, lightInfantryFactor);  
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeAbstractOutlaw, 0.1);  
             if (kbGetAge() < cAge3)
			 {/*      
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeStateMilitia, lightInfantryFactor);  
			 }
			 else
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeStateMilitia, lightInfantryFactor*0);  
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeRifleman, lightInfantryFactor); 
			 */
             //kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeUSCavalry, lightCavalryFactor);  
			 }
             break;
           }
		   case cCivDEMexicans:
           {         
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeSoldado, heavyInfantryFactor); 
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeChinaco, OttoHussarFactor);  
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeEmboscador, lightInfantryFactor);  
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeAbstractOutlaw, 0.1);  
             if (kbGetAge() < cAge3)
			 {      
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeInsurgente, lightCavalryFactor);  
			 }
			 else
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeInsurgente, lightCavalryFactor*0);  
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeDragoon, lightCavalryFactor); 
			 }
             //kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeUSCavalry, lightCavalryFactor);  
             break;
           }
		   case cCivDEEthiopians:
           {         
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeGascenya, heavyInfantryFactor); 
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeNeftenya, lightInfantryFactor);  
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeJavelinRider, lightCavalryFactor);  
			if (kbGetAge() < cAge3)
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeShotelWarrior, heavyCavalryFactor); 
			 else
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeShotelWarrior, heavyCavalryFactor*0);
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeOromoWarrior, heavyCavalryFactor*0.25);
			 }			 
             break;
           }
		   case cCivDEHausa:
           {         
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeFulaWarrior, lightInfantryFactor);  
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeJavelinRider, lightCavalryFactor);  
			if (kbGetAge() < cAge3)
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeRaider, heavyCavalryFactor); 
			 else
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeRaider, heavyCavalryFactor*0);
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeLifidi, heavyCavalryFactor);
			 }			 
             break;
           }
       } 
	   if (civIsNative() == false)
	   {
	   if ((kbGetAge() < cAge5) || (civIsAfrican() == true) || ((kbGetAge() == cAge5) && (kbTechGetStatus(cTechDEPoliticianMercContractor) == cTechStatusActive)) || ((kbGetAge() == cAge5) && (kbTechGetStatus(cTechDEPoliticianFederalNewYork) == cTechStatusActive)))
		{
			 /*if ((kbGetAge() >= cAge3) && (kbUnitCount(cMyID, gAbstractCounterArtilleryUnit, cUnitStateABQ) < 3)
			 && (kbUnitCount(cMyID, gAbstractCounterArtilleryUnit, cUnitStateAlive) < 3))
			 {
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, gAbstractCounterArtilleryUnit, CounterArtFactor);
			 }*/	
	     // if (civIsNative() == false)
		// {
			/*if (civIsEuropean() == true)
			{
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, gAbstractAssassinUnit, AssassinFactor);
			}*/
			 /*if (kbTechGetStatus(cTechSaloonNinja) == cTechStatusActive)
			 {
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMercNinja, MercAssassinFactor * 1.625);
			 }*/
			 if (kbTechGetStatus(cTechSaloonMameluke) == cTechStatusActive)
			 {
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMercMameluke, MercCuirassierFactor * 2.0);
			 }
			 if (kbTechGetStatus(cTechDESaloonSudaneseRider) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeMercSudaneseRider, MercCuirassierFactor * 1.0);
             }
			 if (kbTechGetStatus(cTechDESaloonCannoneer) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeMercCannoneer, MerclightInfantryFactor * 2);
             }
			 if (kbTechGetStatus(cTechDESaloonAskari) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeMercAskari, MercJanissaryFactor * 1.625);
             }
			 if (kbTechGetStatus(cTechDESaloonAmazon) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeMercAmazon, MerclightInfantryFactor * 1.625);
             }
			 if (kbTechGetStatus(cTechDESaloonZenata) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeMercZenata, MerclightCavalryFactor * 1.625);
             }
			 if (kbTechGetStatus(cTechDESaloonGatlingCamel) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeMercGatlingCamel, MercLancerFactor * 2.5);
             }
			 if (kbTechGetStatus(cTechDESaloonKanuri) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeMercKanuri, MerclightCavalryFactor * 1.625);
             }
			 if (kbTechGetStatus(cTechSaloonHackapell) == cTechStatusActive)
			 {
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMercHackapell, MercheavyCavalryFactor * 1.625);
             }
			 if (kbTechGetStatus(cTechdeSaloonHarquebusier) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeMercHarquebusier, MercheavyCavalryFactor * 1.625);
             }
			 if (kbTechGetStatus(cTechSaloonStradiot) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMercStradiot, MercheavyCavalryFactor * 0.5);
             }
			 if (kbTechGetStatus(cTechypSaloonJat) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypMercJatLancer, MercLancerFactor * 0.5);
             }
			 if (kbTechGetStatus(cTechSaloonElmeti) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMercElmeti, MercLancerFactor * 1.625);
             }
			 if (kbTechGetStatus(cTechSaloonManchu) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMercManchu, MerclightCavalryFactor * 1.625);
             }
			 if (kbTechGetStatus(cTechypSaloonYojimbo) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypMercYojimbo, MerclightCavalryFactor * 1.625);
             }
			 if (kbTechGetStatus(cTechSaloonBlackRider) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMercBlackRider, MerclightCavalryFactor * 1.625);
             }
			 if (kbTechGetStatus(cTechSaloonHighlander) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMercHighlander, MercJanissaryFactor * 1.625);
             }
			 if (kbTechGetStatus(cTechSaloonFusilier) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMercFusilier, MercJanissaryFactor * 1.625);
             }
			 if (kbTechGetStatus(cTechSaloonCorsair) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMercBarbaryCorsair, MercTercioFactor * 0.5);
             }
			 if (kbTechGetStatus(cTechSaloonSwissPikeman) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMercSwissPikeman, MercTercioFactor * 1.625);
             }
			 if (kbTechGetStatus(cTechSaloonLandsknecht) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMercLandsknecht, MercTercioFactor * 1.625);
             }
			 //if (kbTechGetStatus(cTechypSaloonArsonist) == cTechStatusActive)
			 //{
			 //kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypMercArsonist, MerclightInfantryFactor * 1.625);
             //}
			 if (kbTechGetStatus(cTechypSaloonIronTroop) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeypMercIronTroop, MerclightInfantryFactor * 1.625);
             }
			 if (kbTechGetStatus(cTechSaloonJaeger) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMercJaeger, ShinobiFactor * 1.625);
             }
			 if (kbTechGetStatus(cTechSaloonGreatCannon) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMercGreatCannon, MercartilleryFactor * 1.625);
             }
			 if (kbTechGetStatus(cTechSaloonRonin) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMercRonin, MercSamuraiFactor * 1.625);
			 }
			}
			else
			kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMercenary, 0.0);
	        if ((civIsAfrican() == false) && ((kbUnitCount(cMyID, cUnitTypeMercenary, cUnitStateAlive) + (kbUnitCount(cMyID, cUnitTypeMercenary, cUnitStateAlive)) < 11)))
			kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMercenary, 0.0);
		}
			 if (gRevolutionType != 0)
			 {
			 if (kbTechGetStatus(cTechDEHCREVHajduks) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeSaloonOutlawRifleman, MerclightInfantryFactor * 1.0);
			 }
			 if (kbTechGetStatus(cTechDEHCREVChinacos) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeSaloonOutlawRifleman, MerclightInfantryFactor * 1.0);
			 }
			 if (kbTechGetStatus(cTechDEHCREVCharros) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeREVVaquero, MerclightCavalryFactor * 1.0);
			 }
			 if (kbTechGetStatus(cTechDEHCREVGranaderos) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeREVGranadero, coreUnitFactor * 1.0);
			 }
			 if (kbTechGetStatus(cTechDEREVMagyarHussarAlt) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeHussar, coreUnitFactor * 1.0);
			 }
			 if (kbTechGetStatus(cTechDERevolutionChile) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeHussar, coreUnitFactor * 1.0);
			 }
			 if (kbTechGetStatus(cTechDERevolutionHaiti) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeSaloonPirate, coreUnitFactor * 1.0);
			 }
			 if (kbTechGetStatus(cTechDERevolutionColombia) == cTechStatusActive)
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeMusketeer, MercJanissaryFactor * 1.0);
			 }
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeREVLlanero, MercLancerFactor * 1.0);
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeREVJagunco, RifleRiderFactor * 1.0);
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeREVGaucho,  MerclightCavalryFactor * 1.0);
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeREVBarbaryWarrior, MercTercioFactor * 1.0);
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeREVBarbaryMarksman, MerclightInfantryFactor * 1.0);
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeREVJavaSpearman, MercTercioFactor * 1.0);
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeREVCetbang, MercartilleryFactor * 1.0);
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypexpGatlingGun, MercartilleryFactor * 1.0);
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeNizam, coreUnitFactor * 1.5);
			 //kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypedeNizam, MercJanissaryFactor * 1.5);
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypexpColonialMilitia, MercJanissaryFactor * 1.0);
			}
			 /*
			 if (civIsEuropean() == true)
			 {
			 if ((kbGetAge() >= cAge2) && ((kbUnitCount(cMyID, gAbstractArtilleryUnit, cUnitStateAlive) + (kbUnitCount(cMyID, gAbstractArtilleryUnit, cUnitStateAlive)) < 5)))
			 {  
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, gAbstractArtilleryUnit, artilleryFactor); 
			 }
			 else
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeFalconet, artilleryFactor*0); 
             if ((kbGetAge() >= cAge4) && ((kbUnitCount(cMyID, cUnitTypexpHorseArtillery, cUnitStateAlive) + (kbUnitCount(cMyID, cUnitTypexpHorseArtillery, cUnitStateAlive)) < 5)))
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypexpHorseArtillery, artilleryFactor); 
			 }
			 else
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypexpHorseArtillery, artilleryFactor*0); 
			 }
			 if ((kbGetAge() >= cAge3) && ((kbUnitCount(cMyID, gSiegeWeaponUnit, cUnitStateAlive) + (kbUnitCount(cMyID, gSiegeWeaponUnit, cUnitStateAlive)) < 5)))
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, gSiegeWeaponUnit, SiegeFactor * 1);
			 else
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, gSiegeWeaponUnit, SiegeFactor * 0);
			 */
			  /*
             if ((kbGetAge() > cAge1) && (kbUnitCount(cMyID, cUnitTypeAbstractPet, cUnitStateAlive) >= kbGetBuildLimit(cMyID, cUnitTypeAbstractPet)))
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeAbstractPet, 1.0);
			 }
			 else
			 {
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeAbstractPet, 0.0);
			 }
			 */
			if (gSPC == true) 
           {
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeAbstractHeavyInfantry, heavyInfantryFactor);
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeAbstractHeavyCavalry, heavyCavalryFactor);   
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeAbstractLancer, LancerFactor);               
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeAbstractLightCavalry, lightCavalryFactor); 
             kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeAbstractRangedInfantry, lightInfantryFactor); 
			 kbUnitPickSetPreferenceFactor(gLandUnitPicker, cUnitTypeLogicalTypeLandMilitary, coreUnitFactor*.25); 
           }
	return;     
    }
    if (counterUnitMode == false)
    {   
       // No commands active. Go with our default biases...
       setStandardArmyPreference();
       //if (civIsAsian() == true)
       //{ 
          // Set preferences for consulate units
          //setConsulateArmyPreference();
       //}      
   }
}
//==============================================================================
// initUnitPicker
//==============================================================================
int initUnitPicker(string name = "BUG", int numberTypes = 1, int minUnits = 10, int maxUnits = 20, int minPop = -1,
                   int maxPop = -1, int numberBuildings = 1, bool guessEnemyUnitType = false)
{
   // Create it.
   int upID = kbUnitPickCreate(name);
   if (upID < 0)
      return (-1);
   // Default init.
   kbUnitPickResetAll(upID);
   kbUnitPickSetPreferenceWeight(upID, 1.0);
   if (gSPC == false)
   {
      kbUnitPickSetCombatEfficiencyWeight(upID, 1.0); // Changed from 1.0 to dilute the power of the preference weight.
      kbUnitPickSetBuildingCombatEfficiencyWeight(upID, 0.0);
   }
   else
   {
      kbUnitPickSetCombatEfficiencyWeight(upID, 1.0); // Leave it at 1.0 to avoid messing up SPC balance
      kbUnitPickSetBuildingCombatEfficiencyWeight(upID, 0.0);
   }
   kbUnitPickSetCostWeight(upID, 0.0);
   // Desired number units types, buildings.
   kbUnitPickSetDesiredNumberUnitTypes(upID, numberTypes, numberBuildings, true);
   // Min/Max units and Min/Max pop.
   kbUnitPickSetMinimumNumberUnits(upID, minUnits); // Sets "need" level on attack plans
   kbUnitPickSetMaximumNumberUnits(upID,
                                   maxUnits); // Sets "max" level on attack plans, sets "numberToMaintain" on train
                                              // plans for primary unit, half that for secondary, 1/4 for tertiary, etc.
   kbUnitPickSetMinimumPop(upID, minPop);     // Not sure what this does...
   kbUnitPickSetMaximumPop(upID,
                           maxPop); // If set, overrides maxNumberUnits for how many of the primary unit to maintain.
   // Default to land units.
   kbUnitPickSetEnemyPlayerID(upID, aiGetMostHatedPlayerID());
   kbUnitPickSetAttackUnitType(upID, cUnitTypeLogicalTypeLandMilitary);
   kbUnitPickSetGoalCombatEfficiencyType(upID, cUnitTypeLogicalTypeLandMilitary);
   // Set the default target types and weights, for use until we've seen enough actual units.
   // kbUnitPickAddCombatEfficiencyType(upID, cUnitTypeLogicalTypeLandMilitary, 1.0);
   kbUnitPickAddCombatEfficiencyType(upID, cUnitTypeSettler,
                                     0.2); // We need to build units that can kill settlers efficiently.
   kbUnitPickAddCombatEfficiencyType(upID, cUnitTypeHussar, 0.0);      // Major component
   kbUnitPickAddCombatEfficiencyType(upID, cUnitTypeMusketeer, 0.0);   // Bigger component
   kbUnitPickAddCombatEfficiencyType(upID, cUnitTypePikeman, 0.0);     // Minor component
   kbUnitPickAddCombatEfficiencyType(upID, cUnitTypeCrossbowman, 0.0); // Minor component
   kbUnitPickAddBuildingCombatEfficiencyType(upID, cUnitTypeMilitaryBuilding, 0.0);
   kbUnitPickAddBuildingCombatEfficiencyType(upID, cUnitTypeAbstractTownCenter, 0.0);
   setUnitPickerPreference(upID); // Set generic preferences for this civ
   // Done.
   return (upID);
}
int getMatchTarget()    // Find an enemy player buildingID to attack.
{
   int count = 0;
   int retVal = -1;
   static int unitQueryID = -1;
   //If we don't have the query yet, create one.
   if (unitQueryID < 0)
   {
      unitQueryID=kbUnitQueryCreate("navy target count");
      kbUnitQuerySetIgnoreKnockedOutUnits(unitQueryID, true);
      kbUnitQuerySetPlayerRelation(unitQueryID, aiGetMostHatedPlayerID());
   }     
   kbUnitQuerySetUnitType(unitQueryID, cUnitTypeBuilding);
   kbUnitQuerySetState(unitQueryID, cUnitStateABQ);
   kbUnitQueryResetResults(unitQueryID);
   count = kbUnitQueryExecute(unitQueryID); 
   //aiEcho("Enemy building: "+ count);
   if (count > 0)
   {
      retVal = kbUnitGetPlayerID(kbUnitQueryGetResult(unitQueryID,0));
   }
   return(retVal);
}
rule siegeWeaponMonitor
inactive
mininterval 60
{
   if (aiTreatyActive() == true)
   {
      aiEcho("delayed because treaty is active.");
      return;
   }
     bool homeBaseUnderAttack = false;
	  if (gDefenseReflexBaseID == kbBaseGetMainID(cMyID))
      homeBaseUnderAttack = true;
   static int mortarPlan = -1;    
   static int ypHandMortarPlan = -1;
   static int ypMorutaruPlan = -1;
   static int ypSiegeElephantPlan = -1;
   static int ArrowKnightPlan = -1;
   static int HauracaPlan = -1;
   static int xpRamPlan = -1;   
   static int gAbstractArtilleryUnitPlan1 = -1;  
   static int gAbstractArtilleryUnitPlan2 = -1;  
   static int gAbstractArtilleryUnitPlan3 = -1;  
      if ((kbGetCiv() != cCivIndians) && (cMyCiv != cCivDEInca) && (cMyCiv != cCivXPSioux))
    { 
   if ((kbGetAge() == cAge3) && (cMyCiv != cCivXPIroquois)) //&& (xsArrayGetFloat(gResourceNeeds, cResourceGold) < +800.0))
   {    
      if (gAbstractArtilleryUnitPlan1 < 0)
      {  gAbstractArtilleryUnitPlan1 = createSimpleMaintainPlan(gAbstractArtilleryUnit, 2, true, kbBaseGetMainID(cMyID), 2);  }
      else
      {  aiPlanSetVariableInt(gAbstractArtilleryUnitPlan1, cTrainPlanNumberToMaintain, 0, 2); }
    }
	else
	{
	aiPlanDestroy(gAbstractArtilleryUnitPlan1);
	}
	if (kbGetAge() == cAge4)
   {    
      if (gAbstractArtilleryUnitPlan2 < 0)
      {  gAbstractArtilleryUnitPlan2 = createSimpleMaintainPlan(gAbstractArtilleryUnit, 3, true, kbBaseGetMainID(cMyID), 3);  }
      else
      {  aiPlanSetVariableInt(gAbstractArtilleryUnitPlan2, cTrainPlanNumberToMaintain, 0, 3); }
    }
	else
	{
	aiPlanDestroy(gAbstractArtilleryUnitPlan2);
	}
	if (kbGetAge() > cAge4) //&& (xsArrayGetFloat(gResourceNeeds, cResourceGold) < +800.0))
   {    
      if (gAbstractArtilleryUnitPlan3 < 0)
      {  gAbstractArtilleryUnitPlan3 = createSimpleMaintainPlan(gAbstractArtilleryUnit, 5, true, kbBaseGetMainID(cMyID), 5);  }
      else
      {  aiPlanSetVariableInt(gAbstractArtilleryUnitPlan3, cTrainPlanNumberToMaintain, 0, 5); }
    }
	}
   if ((kbGetAge() > cAge3) && (homeBaseUnderAttack == false)) //&& (xsArrayGetFloat(gResourceNeeds, cResourceGold) < +800.0))
  {
   if (civIsNative() == true)
    {     
		if (cMyCiv == cCivXPIroquois)
		{
      if (xpRamPlan < 0)
      {  xpRamPlan = createSimpleMaintainPlan(cUnitTypexpRam, 5, true, kbBaseGetMainID(cMyID), 5);  }
      else
      {  aiPlanSetVariableInt(xpRamPlan, cTrainPlanNumberToMaintain, 0, 5); }
		}
		if (cMyCiv == cCivXPAztec)
		{
      if (ArrowKnightPlan < 0)
      {  ArrowKnightPlan = createSimpleMaintainPlan(cUnitTypexpArrowKnight, 5, true, kbBaseGetMainID(cMyID), 5);  }
      else
      {  aiPlanSetVariableInt(ArrowKnightPlan, cTrainPlanNumberToMaintain, 0, 5); }
		}
		if (cMyCiv == cCivDEInca)
		{
      if (HauracaPlan < 0)
      {  HauracaPlan = createSimpleMaintainPlan(cUnitTypedeSlinger, 5, true, kbBaseGetMainID(cMyID), 5);  }
      else
      {  aiPlanSetVariableInt(HauracaPlan, cTrainPlanNumberToMaintain, 0, 5); }
		}
	}
   if (civIsEuropean() == true)
    {
      if (mortarPlan < 0)
      {  mortarPlan = createSimpleMaintainPlan(cUnitTypeMortar, 2, true, kbBaseGetMainID(cMyID), 2);  }
      else
      {  aiPlanSetVariableInt(mortarPlan, cTrainPlanNumberToMaintain, 0, 2); }
    }
	if (civIsNative() == true)
    {
      if (mortarPlan < 0)
      {  mortarPlan = createSimpleMaintainPlan(cUnitTypedeMercCapturedMortar, 2, true, kbBaseGetMainID(cMyID), 2);  }
      else
      {  aiPlanSetVariableInt(mortarPlan, cTrainPlanNumberToMaintain, 0, 2); }
    }
   if (civIsAsian() == true)
    {
      if ( (kbGetCiv() == cCivChinese) || (kbGetCiv() == cCivSPCChinese) )
      {
         if (ypHandMortarPlan < 0)
         {  ypHandMortarPlan = createSimpleMaintainPlan(cUnitTypeypHandMortar, 10, true, kbBaseGetMainID(cMyID), 10);  }
         else
         {  aiPlanSetVariableInt(ypHandMortarPlan, cTrainPlanNumberToMaintain, 0, 10); }
      }
      if (((kbGetCiv() == cCivSPCJapanese)||(kbGetCiv() == cCivJapanese)||(kbGetCiv() == cCivSPCJapaneseEnemy)))
      {  
         if (ypMorutaruPlan < 0)
         {  ypMorutaruPlan = createSimpleMaintainPlan(cUnitTypeypMorutaru, 2, true, kbBaseGetMainID(cMyID), 2);  }
         else
         {  aiPlanSetVariableInt(ypMorutaruPlan, cTrainPlanNumberToMaintain, 0, 2); }
      }
      if ( (kbGetCiv() == cCivIndians) || (kbGetCiv() == cCivSPCIndians) )
      {
         if (ypSiegeElephantPlan < 0)
         {  ypSiegeElephantPlan = createSimpleMaintainPlan(cUnitTypeypSiegeElephant, 2, true, kbBaseGetMainID(cMyID), 2);  }
         else
         {  aiPlanSetVariableInt(ypSiegeElephantPlan, cTrainPlanNumberToMaintain, 0, 2); }
      }           
    }
  }
   if (homeBaseUnderAttack == true)
  {
	  aiPlanDestroy(xpRamPlan);
	  aiPlanDestroy(ArrowKnightPlan);
	  aiPlanDestroy(HauracaPlan);
	  aiPlanDestroy(mortarPlan);
	  aiPlanDestroy(ypHandMortarPlan);
	  aiPlanDestroy(ypMorutaruPlan);
	  aiPlanDestroy(ypSiegeElephantPlan);
  }
  return;
}
rule siegeWeaponManager
active
mininterval 10
{     
   if (aiTreatyActive() == true)
   {
      aiEcho("delayed because treaty is active.");
      return;
   }
   if (kbUnitCount(cMyID, gSiegeWeaponUnit, cUnitStateAlive) < 1)
   {
   xsSetRuleMinIntervalSelf(60);
      return;
   }
   else
   {
   xsSetRuleMinIntervalSelf(5);
   }
   /*
   static int gAbstractArtilleryUnitPlan = -1;   
   static int gSiegeWeaponUnitPlan = -1;   
   if ((kbGetAge() >= cAge4) && (kbGetCiv() != cCivIndians) && (cMyCiv != cCivXPAztec) && (cMyCiv != cCivXPSioux))
   {     
      if (gAbstractArtilleryUnitPlan < 0)
      {  gAbstractArtilleryUnitPlan = createSimpleMaintainPlan(gAbstractArtilleryUnit, 2, true, kbBaseGetMainID(cMyID), 2);  }
      else
      {  aiPlanSetVariableInt(gAbstractArtilleryUnitPlan, cTrainPlanNumberToMaintain, 0, 2); }
   }
   if ((kbGetAge() >= cAge4) && (kbGetCiv() != cCivIndians) && (cMyCiv != cCivXPAztec) && (cMyCiv != cCivXPSioux))
   {     
      if (gSiegeWeaponUnitPlan < 0)
      {  gSiegeWeaponUnitPlan = createSimpleMaintainPlan(gSiegeWeaponUnit, 2, true, kbBaseGetMainID(cMyID), 2);  }
      else
      {  aiPlanSetVariableInt(gSiegeWeaponUnitPlan, cTrainPlanNumberToMaintain, 0, 2); }
   }
   */
   vector siegeWeaponVec = cInvalidVector;
   int siegeWeaponUnit = getUnit(gSiegeWeaponUnit, cMyID, cUnitStateAlive);   
   if (siegeWeaponUnit >= 0)
      siegeWeaponVec = kbUnitGetPosition(siegeWeaponUnit);
   else
      siegeWeaponVec = kbBaseGetMilitaryGatherPoint(cMyID, kbBaseGetMainID(cMyID));  
   int numUnit = kbUnitCount(cMyID, gSiegeWeaponUnit, cUnitStateAlive);
   if (kbUnitCount(cMyID, gSiegeWeaponUnit, cUnitStateAlive) > 0) 
   { 
      if (getMatchTarget() >= 0)  // There's something to attack :)
      {
         int attackPlan = aiPlanCreate("Mortar Attack plan", cPlanAttack);
         aiPlanSetVariableInt(attackPlan, cAttackPlanPlayerID, 0, getMatchTarget());
         aiPlanSetNumberVariableValues(attackPlan, cAttackPlanTargetTypeID, 14, true);
         aiPlanSetVariableInt(attackPlan, cAttackPlanTargetTypeID, 0, cUnitTypeypShrineJapanese);
         aiPlanSetVariableInt(attackPlan, cAttackPlanTargetTypeID, 1, cUnitTypedeTorp);
         aiPlanSetVariableInt(attackPlan, cAttackPlanTargetTypeID, 2, cUnitTypedeTorpGeneric);
         aiPlanSetVariableInt(attackPlan, cAttackPlanTargetTypeID, 3, cUnitTypeTradingPost);
         aiPlanSetVariableInt(attackPlan, cAttackPlanTargetTypeID, 4, cUnitTypeFortFrontier);
         aiPlanSetVariableInt(attackPlan, cAttackPlanTargetTypeID, 5, gTowerUnit);
         aiPlanSetVariableInt(attackPlan, cAttackPlanTargetTypeID, 6, gMilitaryBuildings);
         aiPlanSetVariableInt(attackPlan, cAttackPlanTargetTypeID, 7, cUnitTypeTownCenter);
         aiPlanSetVariableInt(attackPlan, cAttackPlanTargetTypeID, 8, cUnitTypeFactory);    
         aiPlanSetVariableInt(attackPlan, cAttackPlanTargetTypeID, 9, cUnitTypeAbstractWonder);    
         aiPlanSetVariableInt(attackPlan, cAttackPlanTargetTypeID, 10, cUnitTypeBank);
         aiPlanSetVariableInt(attackPlan, cAttackPlanTargetTypeID, 11, cUnitTypedeHouseInca);
         aiPlanSetVariableInt(attackPlan, cAttackPlanTargetTypeID, 12, cUnitTypeLogicalTypeBuildingsNotWalls);
         //aiPlanSetVariableInt(attackPlan, cAttackPlanTargetTypeID, 13, gWallnonp);
         aiPlanSetVariableVector(attackPlan, cAttackPlanGatherPoint, 0, siegeWeaponVec);
         aiPlanSetVariableFloat(attackPlan, cAttackPlanGatherDistance, 0, 100.0);
         aiPlanSetVariableInt(attackPlan, cAttackPlanRefreshFrequency, 0, 1);
         aiPlanSetDesiredPriority(attackPlan, 99);          
         aiPlanAddUnitType(attackPlan, gSiegeWeaponUnit, numUnit, numUnit, numUnit);
         aiPlanSetUnitStance(attackPlan, cUnitStanceAggressive);
         aiPlanSetInitialPosition(attackPlan, siegeWeaponVec);
         aiEcho("***** ATTACK, plan ID is +attackPlan *****"); 
         aiPlanSetActive(attackPlan, true);
      }
   }
}
//==============================================================================
/*
   nativeMonitor

   Make and update maintain plans for native warriors
   since they don't show up often
*/
//==============================================================================
rule nativeMonitor
inactive
minInterval 30
{
   static int nativeUPID = -1;
   static int nativeMaintainPlans = -1;
   static int nativeBuildingIDs = -1;

   if (nativeUPID < 0)
   {
      // Create it.
      nativeUPID = kbUnitPickCreate("Native Warrior");
      if (nativeUPID < 0)
         return;

      nativeMaintainPlans = xsArrayCreateInt(3, -1, "Native warrior maintain plans");
      nativeBuildingIDs = xsArrayCreateInt(3, -1, "Native warrior buildings");
   }

   int trainUnitID = -1;
   int planID = -1;
   int numberToMaintain = 0;
   int militaryPopPercentage = btBiasNative * 10 + 10;
   int buildLimit = 0;
   int upgradeTechID = -1;
   int upgradePlanID = -1;
   float totalValue = 0.0;
   int trainBuildingID = -2;
   int mainBaseID = kbBaseGetMainID(cMyID);
   vector mainBaseLocation = kbBaseGetLocation(cMyID, mainBaseID);
   float mainBaseDist = kbBaseGetDistance(cMyID, mainBaseID);
   int age = kbGetAge();

   // Default init.
   kbUnitPickResetAll(nativeUPID);
   kbUnitPickSetPreferenceWeight(nativeUPID, 1.0);
   kbUnitPickSetCombatEfficiencyWeight(nativeUPID, 0.0);
   kbUnitPickSetBuildingCombatEfficiencyWeight(nativeUPID, 0.0);
   kbUnitPickSetCostWeight(nativeUPID, 0.0);
   // Desired number units types, buildings.
   kbUnitPickSetDesiredNumberUnitTypes(nativeUPID, 3, 1, true);
   kbUnitPickSetEnemyPlayerID(nativeUPID, aiGetMostHatedPlayerID());
   kbUnitPickSetPreferenceFactor(nativeUPID, cUnitTypeAbstractNativeWarrior, 1.0);
   kbUnitPickRun(nativeUPID);

   int numberPlans = xsArrayGetSize(nativeMaintainPlans);
   int numberUnitTypes = kbUnitPickGetNumberResults(nativeUPID);

   if (numberUnitTypes > numberPlans)
   {
      xsArrayResizeInt(nativeMaintainPlans, numberUnitTypes);
      for (i = numberPlans; < numberUnitTypes)
         xsArraySetInt(nativeMaintainPlans, i, -1);
   }

   for (i = 0; < numberUnitTypes)
   {
      trainUnitID = kbUnitPickGetResult(nativeUPID, i);
      planID = xsArrayGetInt(nativeMaintainPlans, i);
      buildLimit = kbGetBuildLimit(cMyID, trainUnitID);
      if (buildLimit == 0)
         trainUnitID = -1;

      if (planID >= 0 && trainUnitID != aiPlanGetVariableInt(planID, cTrainPlanUnitType, 0))
      {
         aiPlanDestroy(planID);
         planID = -1;
      }

      if (trainUnitID < 0)
         continue;

      if (planID < 0)
      {
         planID = createSimpleMaintainPlan(trainUnitID, 0, false, mainBaseID, 1);
         xsArraySetInt(nativeMaintainPlans, i, planID);
      }

      if (age <= cAge4)
      {
         // resource equivalent to 0-20% of our military pop
         numberToMaintain = (aiGetMilitaryPop() * militaryPopPercentage) / (kbUnitCostPerResource(trainUnitID, cResourceGold) +
                                                                            kbUnitCostPerResource(trainUnitID, cResourceWood) +
                                                                            kbUnitCostPerResource(trainUnitID, cResourceFood));
      }
      else
      {
         numberToMaintain = buildLimit;
      }

      aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, numberToMaintain);

      // Train from main base whenever possible.
      if (numberToMaintain > 0)
      {
         if (trainBuildingID == -2)
         {
            trainBuildingID = getUnitByLocation(cUnitTypeNativeEmbassy, cMyID, cUnitStateAlive, mainBaseLocation, mainBaseDist);
            if (trainBuildingID < 0 && civIsAfrican() == true)
               trainBuildingID = getUnitByLocation(cUnitTypedePalace, cMyID, cUnitStateAlive, mainBaseLocation, mainBaseDist);
         }
         aiPlanSetVariableInt(planID, cTrainPlanBuildingID, 0, trainBuildingID);
      }
      else
      {
         aiPlanSetVariableInt(planID, cTrainPlanBuildingID, 0, -1);
      }

      // create a research plan.
      if (age >= cAge3)
      {
         upgradeTechID = kbTechTreeGetCheapestUnitUpgrade(trainUnitID, cUnitTypeTradingPost);
         if (upgradeTechID >= 0)
         {
            upgradePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, upgradeTechID);

            if (upgradePlanID < 0)
            {
               upgradePlanID = aiPlanCreate("Research " + kbGetTechName(upgradeTechID), cPlanResearch);
               aiPlanSetVariableInt(upgradePlanID, cResearchPlanTechID, 0, upgradeTechID);
               aiPlanSetVariableInt(upgradePlanID, cResearchPlanBuildingTypeID, 0, cUnitTypeTradingPost);
               aiPlanSetActive(upgradePlanID);
               debugMilitary("*** Creating research plan for " + kbGetTechName(upgradeTechID));
            }

            aiPlanSetParentID(upgradePlanID, planID);

            totalValue = kbUnitCostPerResource(trainUnitID, cResourceFood) + kbUnitCostPerResource(trainUnitID, cResourceWood) +
                         kbUnitCostPerResource(trainUnitID, cResourceGold) +
                         kbUnitCostPerResource(trainUnitID, cResourceInfluence);
            totalValue = totalValue * kbUnitCount(cMyID, trainUnitID, cUnitStateABQ);

            // below default priority if we do not have enough units.
            if (totalValue < 800.0)
               aiPlanSetDesiredResourcePriority(upgradePlanID, 45 - (5 - totalValue / 200));
            else
               aiPlanSetDesiredResourcePriority(upgradePlanID, 50);
         }
      }
   }

   for (i = numberUnitTypes; < numberPlans)
   {
      planID = xsArrayGetInt(nativeMaintainPlans, i);
      if (planID >= 0)
      {
         aiPlanDestroy(planID);
         xsArraySetInt(nativeMaintainPlans, i, -1);
      }
   }
}

//==============================================================================
// calculateDefenseEngageRange
//
// Calculates the max engage range without enemy buildings nearby.
//==============================================================================
float calculateDefenseReflexEngageRange(vector location = cInvalidVector, float range = 0.0, float minRange = 0.0)
{
   int enemyBuildingQuery = createSimpleUnitQuery(
       cUnitTypeBuilding, cPlayerRelationEnemyNotGaia, cUnitStateABQ, location, range);
   kbUnitQuerySetAscendingSort(enemyBuildingQuery, true);
   int numberFound = kbUnitQueryExecute(enemyBuildingQuery);
   if (numberFound == 0)
   {
      // no buildings nearby, we're good.
      return (range);
   }

   int enemyBuildingID = kbUnitQueryGetResult(enemyBuildingQuery, 0);
   float dist = distance(kbUnitGetPosition(enemyBuildingID), location);
   if (dist < minRange)
   {
      debugMilitary("******** WARNING! Defend location too close to enemy buildings, distance=" + dist);
      return (minRange);
   }

   debugMilitary("******** Defend plan engage range changed to " + dist);

   return (dist - minRange);
}

//==============================================================================
/*
   moveDefenseReflex(vector, radius, baseID)

   Move the defend and reserve plans to the specified location
   Sets the gLandDefendPlan0 to a high pop count, so it steals units from the reserve plan,
   which will signal the AI to not start new attacks as no reserves are available.
*/
//==============================================================================
void moveDefenseReflex(vector location = cInvalidVector, float radius = -1.0, int baseID = -1)
{
   if (radius < 0.0)
      radius = cvDefenseReflexRadiusActive;
   if (location != cInvalidVector)
   {
      float desiredRadius = radius;

      radius = calculateDefenseReflexEngageRange(location, radius, 15.0);

      if (baseID < 0 || radius < desiredRadius)
      {
         aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanTargetMode, 0, cCombatPlanTargetModePoint);
         aiPlanSetVariableVector(gLandDefendPlan0, cCombatPlanTargetPoint, 0, location);
         aiPlanSetVariableFloat(gLandDefendPlan0, cCombatPlanTargetEngageRange, 0, radius);
      }
      else
      {
         aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanTargetMode, 0, cCombatPlanTargetModeBase);
         aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanTargetPlayerID, 0, cMyID);
         aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanTargetBaseID, 0, baseID);
         aiPlanSetVariableVector(gLandDefendPlan0, cCombatPlanTargetPoint, 0, location);
      }

      aiPlanSetVariableFloat(gLandDefendPlan0, cCombatPlanGatherDistance, 0, radius - 10.0);
      aiPlanAddUnitType(gLandDefendPlan0, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);
      // We should prioritize defending over gathering when under attack
      if ((gRevolutionType & cRevolutionFinland) == cRevolutionFinland)
         aiPlanAddUnitType(gLandDefendPlan0, gEconUnit, 0, 200, 200);

      if (baseID < 0)
      {
         radius = calculateDefenseReflexEngageRange(location, radius, 15.0);
         aiPlanSetVariableInt(gLandReservePlan, cCombatPlanTargetMode, 0, cCombatPlanTargetModePoint);
         aiPlanSetVariableVector(gLandReservePlan, cCombatPlanTargetPoint, 0, location);
         aiPlanSetVariableFloat(gLandReservePlan, cCombatPlanTargetEngageRange, 0, radius);
      }
      else
      {
         aiPlanSetVariableInt(gLandReservePlan, cCombatPlanTargetMode, 0, cCombatPlanTargetModeBase);
         aiPlanSetVariableInt(gLandReservePlan, cCombatPlanTargetPlayerID, 0, cMyID);
         aiPlanSetVariableInt(gLandReservePlan, cCombatPlanTargetBaseID, 0, baseID);
         aiPlanSetVariableVector(gLandReservePlan, cCombatPlanTargetPoint, 0, location);
      }

      aiPlanSetVariableFloat(gLandReservePlan, cCombatPlanGatherDistance, 0, radius - 10.0);
      aiPlanAddUnitType(gLandReservePlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, 1);

      gDefenseReflex = true;
      gDefenseReflexBaseID = baseID;
      gDefenseReflexLocation = location;
      gDefenseReflexTimeout = xsGetTime() + aiRandInt(1) * 1000;
      gDefenseReflexPaused = false;
   }
   debugMilitary("******** Defense reflex moved to base " + baseID + " with radius " + radius + " and location " + location);
}

//==============================================================================
/*
   pauseDefenseReflex()

   The base (gDefenseReflexBaseID) is still under attack, but we don't have enough
   forces to engage.  Retreat to main base, set a small radius, and wait until we
   have enough troops to re-engage through a moveDefenseReflex() call.
   Sets gLandDefendPlan0 to high troop count to keep reserve plan empty.
   Leaves the base ID and location untouched, even though units will gather at home.
*/
//==============================================================================
void pauseDefenseReflex(void)
{
   vector loc = kbBaseGetMilitaryGatherPoint(cMyID, kbBaseGetMainID(cMyID));
   if (gForwardBaseState != cForwardBaseStateNone && gForwardBaseShouldDefend == true)
      loc = gForwardBaseLocation;

   float radius = calculateDefenseReflexEngageRange(loc, cvDefenseReflexRadiusPassive, 15.0);

   aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanTargetMode, 0, cCombatPlanTargetModePoint);
   aiPlanSetVariableVector(gLandDefendPlan0, cCombatPlanTargetPoint, 0, loc);
   aiPlanSetVariableFloat(gLandDefendPlan0, cCombatPlanTargetEngageRange, 0, radius);
   aiPlanSetVariableFloat(gLandDefendPlan0, cCombatPlanGatherDistance, 0, radius - 10.0);

   aiPlanSetVariableInt(gLandReservePlan, cCombatPlanTargetMode, 0, cCombatPlanTargetModePoint);
   aiPlanSetVariableVector(gLandReservePlan, cCombatPlanTargetPoint, 0, loc);
   aiPlanSetVariableFloat(gLandReservePlan, cCombatPlanTargetEngageRange, 0, radius);
   aiPlanSetVariableFloat(gLandReservePlan, cCombatPlanGatherDistance, 0, radius - 10.0);

   aiPlanAddUnitType(gLandDefendPlan0, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200);
   // We should prioritize defending over gathering when under attack
   if ((gRevolutionType & cRevolutionFinland) == cRevolutionFinland)
      aiPlanAddUnitType(gLandDefendPlan0, gEconUnit, 0, 200, 200);
   aiPlanAddUnitType(gLandReservePlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, 1);

   gDefenseReflexPaused = true;

   debugMilitary("******** Defense reflex paused.");
}

//==============================================================================
/*
   endDefenseReflex()

   Move the defend and reserve plans to their default positions
*/
//==============================================================================
void endDefenseReflex(void)
{
   vector resLoc = kbBaseGetMilitaryGatherPoint(cMyID, kbBaseGetMainID(cMyID));
   int defBaseID = kbBaseGetMainID(cMyID);
   vector defLoc = kbBaseGetLocation(cMyID, defBaseID);

   if (gForwardBaseState != cForwardBaseStateNone && gForwardBaseShouldDefend == true)
   {
      resLoc = gForwardBaseLocation;
      defLoc = gForwardBaseLocation;
      defBaseID = gForwardBaseID;
   }
   float radius = calculateDefenseReflexEngageRange(defLoc, cvDefenseReflexRadiusActive, 15.0);

   radius = calculateDefenseReflexEngageRange(defLoc, radius, 15.0);

   if (radius < cvDefenseReflexRadiusActive)
   {
      aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanTargetMode, 0, cCombatPlanTargetModePoint);
      aiPlanSetVariableVector(gLandDefendPlan0, cCombatPlanTargetPoint, 0, defLoc);
      aiPlanSetVariableFloat(gLandDefendPlan0, cCombatPlanTargetEngageRange, 0, radius);
   }
   else
   {
      aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanTargetMode, 0, cCombatPlanTargetModeBase);
      aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanTargetPlayerID, 0, cMyID);
      aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanTargetBaseID, 0, defBaseID);
      aiPlanSetVariableVector(gLandDefendPlan0, cCombatPlanTargetPoint, 0, defLoc);
   }
   aiPlanAddUnitType(
       gLandDefendPlan0,
       cUnitTypeLogicalTypeLandMilitary,
       0,
       0,
       1); // Defend plan will use 1 unit to defend against stray snipers, etc.
   // Move units back to gathering when possible
   if ((gRevolutionType & cRevolutionFinland) == cRevolutionFinland)
      aiPlanAddUnitType(gLandDefendPlan0, gEconUnit, 0, 0, 1);

   radius = calculateDefenseReflexEngageRange(resLoc, cvDefenseReflexRadiusPassive, 15.0);

   aiPlanSetVariableInt(gLandReservePlan, cCombatPlanTargetMode, 0, cCombatPlanTargetModePoint);
   aiPlanSetVariableVector(gLandReservePlan, cCombatPlanTargetPoint, 0, resLoc);
   aiPlanSetVariableFloat(gLandReservePlan, cCombatPlanTargetEngageRange, 0, radius);
   aiPlanSetVariableFloat(gLandReservePlan, cCombatPlanGatherDistance, 0, radius - 10.0);
   aiPlanAddUnitType(gLandReservePlan, cUnitTypeLogicalTypeLandMilitary, 0, 0, 200); // All unused troops

   debugMilitary("******** Defense reflex terminated for base " + gDefenseReflexBaseID + " at location " + gDefenseReflexLocation);
   debugMilitary("******** Returning to " + resLoc);
   debugMilitary(" Forward base ID is " + gForwardBaseID + ", location is " + gForwardBaseLocation);

   gDefenseReflex = false;
   gDefenseReflexPaused = false;
   gDefenseReflexBaseID = -1;
   gDefenseReflexLocation = cInvalidVector;
   gDefenseReflexTimeout = 0;
}

rule endDefenseReflexDelay // Use this instead of calling endDefenseReflex in the createMainBase function, so that the
                           // new BaseID will be available.
    inactive minInterval 1
{
   xsDisableSelf();
   endDefenseReflex();
}

//==============================================================================
/* Defend0

   Create a defend plan, protect the main base.
*/
//==============================================================================
rule defend0
inactive
group startup
minInterval 13
{
   if (gLandDefendPlan0 < 0)
   {
      int mainBaseID = kbBaseGetMainID(cMyID);
      vector mainBaseLocation = kbBaseGetLocation(cMyID, mainBaseID);
      vector targetPoint = kbBaseGetMilitaryGatherPoint(cMyID, mainBaseID);
      int targetMode = cCombatPlanTargetModeBase;
      int difficulty = aiGetWorldDifficulty();

      gLandDefendPlan0 = aiPlanCreate("Primary Land Defend", cPlanCombat);
      aiPlanAddUnitType(gLandDefendPlan0, cUnitTypeLogicalTypeLandMilitary, 0, 0, 1); // Small, until defense reflex
      aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanCombatType, 0, cCombatPlanCombatTypeDefend);
      aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanTargetMode, 0, targetMode);
      aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanTargetPlayerID, 0, cMyID);
      aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanTargetBaseID, 0, mainBaseID);
      aiPlanSetVariableVector(gLandDefendPlan0, cCombatPlanTargetPoint, 0, targetPoint);
      aiPlanSetVariableFloat(gLandDefendPlan0, cCombatPlanGatherDistance, 0, 20.0);
      aiPlanSetInitialPosition(gLandDefendPlan0, mainBaseLocation);
      if (difficulty >= cDifficultyModerate)
      {
         aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanRefreshFrequency, 0, 300);
		 if ((kbGetAge() < cvMaxAge) || (gRevolutionType == 0))
         aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanRetreatMode, 0, cCombatPlanRetreatModeOutnumbered);
      }
      else
      {
         aiPlanSetVariableInt(gLandDefendPlan0, cCombatPlanRefreshFrequency, 0, 1000);
      }
      aiPlanSetDesiredPriority(gLandDefendPlan0, 10); // Very low priority, don't steal from attack plans
      aiPlanSetActive(gLandDefendPlan0);
      debugMilitary("Creating primary land defend plan");

      gLandReservePlan = aiPlanCreate("Land Reserve Units", cPlanCombat);
      aiPlanAddUnitType(
          gLandReservePlan,
          cUnitTypeLogicalTypeLandMilitary,
          0,
          5,
          200); // All mil units, high MAX value to suck up all excess
      aiPlanSetVariableInt(gLandReservePlan, cCombatPlanCombatType, 0, cCombatPlanCombatTypeDefend);
      if (targetPoint == cInvalidVector)
      {
         int aiStartID = getUnit(cUnitTypeAIStart, cMyID);
         if (aiStartID >= 0)
         {
            targetPoint = kbUnitGetPosition(aiStartID);
            targetMode = cCombatPlanTargetModePoint;
         }
      }
      if (targetPoint == cInvalidVector)
         targetPoint = mainBaseLocation;
      aiPlanSetVariableInt(gLandReservePlan, cCombatPlanTargetMode, 0, targetMode);
      if (targetMode == cCombatPlanTargetModeBase)
      {
         aiPlanSetVariableInt(gLandReservePlan, cCombatPlanTargetPlayerID, 0, cMyID);
         aiPlanSetVariableInt(gLandReservePlan, cCombatPlanTargetBaseID, 0, mainBaseID);
      }
      else
      {
         aiPlanSetVariableFloat(gLandReservePlan, cCombatPlanTargetEngageRange, 0, 60.0);
      }
      aiPlanSetVariableVector(gLandReservePlan, cCombatPlanTargetPoint, 0, targetPoint);
      aiPlanSetVariableFloat(gLandReservePlan, cCombatPlanGatherDistance, 0, 20.0);
      aiPlanSetInitialPosition(gLandReservePlan, mainBaseLocation);
      if (difficulty >= cDifficultyModerate)
      {
         aiPlanSetVariableInt(gLandReservePlan, cCombatPlanRefreshFrequency, 0, 300);
		 if ((kbGetAge() < cvMaxAge) || (gRevolutionType == 0))
         aiPlanSetVariableInt(gLandReservePlan, cCombatPlanRetreatMode, 0, cCombatPlanRetreatModeOutnumbered);
      }
      else
      {
         aiPlanSetVariableInt(gLandReservePlan, cCombatPlanRefreshFrequency, 0, 1000);
      }
      aiPlanSetDesiredPriority(gLandReservePlan, 5); // Very very low priority, gather unused units.
      aiPlanSetActive(gLandReservePlan);
      // if (gMainAttackGoal >= 0)
      //	aiPlanSetVariableInt(gMainAttackGoal, cGoalPlanReservePlanID, 0, gLandReservePlan);
      debugMilitary("Creating reserve plan");
      xsEnableRule("endDefenseReflexDelay"); // Reset to relaxed stances after plans have a second to be created.
      xsDisableSelf();
   }
}

//==============================================================================
/* rule defenseReflex

   Monitor each VP site that we own, plus our main base.  Move and reconfigure
   the defense and reserve plans as needed.

   At rest, the defend plan has only one unit, is centered on the main base, and
   is used to send one unit after trivial invasions, typically a scouting unit.
   The reserve plan has a much larger MAX number, so it gets all the remaining units.
   It is centered on the military gather point with a conservative radius, to avoid
   engaging units far in front of the main base.

   When defending a base in a defense reflex, the defend plan gets a high MAX number
   so that it takes units from the reserve plan.  The low unit count in reserve
   acts as a signal to not launch new attacks, as troops aren't available.  The
   defend plan and reserve plan are relocated to the endangered base, with an aggressive
   engage radius.

   The search, active engage and passive engage radii are set by global
   control variables, cvDefenseReflexRadiusActive, cvDefenseReflexRadiusPassive, and
   cvDefenseReflexSearchRadius.

   Once in a defense reflex, the AI stays in it until that base is cleared, unless
   it's defending a non-main base, and the main base requires defense.  In that case,
   the defense reflex moves back to the main base.

   pauseDefenseReflex() can only be used when already in a defense reflex.  So valid
   state transitions are:

   none to defending       // start reflex with moveDefenseReflex(), sets all the base/location globals.
   defending to paused     // use pauseDefenseReflex(), takes no parms, uses vars set in prior moveDefenseReflex call.
   defending to end        // use endDefenseReflex(), clears global vars
   paused to end           // use endDefenseReflex(), clears global vars
   paused to defending     // use moveDefenseReflex(), set global vars again.

*/
//==============================================================================
//

rule defenseReflex
inactive
minInterval 10
group startup
{

   int armySize = aiPlanGetNumberUnits(gLandDefendPlan0, cUnitTypeLogicalTypeLandMilitary) +
                  aiPlanGetNumberUnits(gLandReservePlan, cUnitTypeLogicalTypeLandMilitary);
   int enemyArmySize = -1;
   static int lastHelpTime = -60000;
   static int lastHelpBaseID = -1;
   int i = 0;
   int unitID = -1;
   int protoUnitID = -1;
   bool panic = false; // Indicates need for call for help
   int planID = -1;
   int mainBaseID = kbBaseGetMainID(cMyID);

   static int enemyArmyQuery = -1;
   if (enemyArmyQuery < 0)
   { // Initialize the queryID
      enemyArmyQuery = kbUnitQueryCreate("Enemy army query");
      kbUnitQuerySetIgnoreKnockedOutUnits(enemyArmyQuery, true);
      kbUnitQuerySetPlayerRelation(enemyArmyQuery, cPlayerRelationEnemyNotGaia);
      kbUnitQuerySetUnitType(enemyArmyQuery, cUnitTypeLogicalTypeLandMilitary);
      kbUnitQuerySetState(enemyArmyQuery, cUnitStateAlive);
      kbUnitQuerySetSeeableOnly(enemyArmyQuery, true); // Ignore units we think are under fog
   }

   if ((gRevolutionType & cRevolutionFinland) == cRevolutionFinland)
   {
      int numberPlans = aiPlanGetActiveCount();
      for (i = 0; < numberPlans)
      {
         planID = aiPlanGetIDByActiveIndex(i);
         if (aiPlanGetType(planID) != cPlanGather)
            continue;
         armySize = armySize + aiPlanGetNumberUnits(planID, gEconUnit);
      }
   }

   // Check main base first
   kbUnitQuerySetPosition(enemyArmyQuery, kbBaseGetLocation(cMyID, mainBaseID));
   kbUnitQuerySetMaximumDistance(enemyArmyQuery, cvDefenseReflexSearchRadius);
   kbUnitQuerySetSeeableOnly(enemyArmyQuery, true);
   kbUnitQuerySetState(enemyArmyQuery, cUnitStateAlive);
   kbUnitQueryResetResults(enemyArmyQuery);
   enemyArmySize = kbUnitQueryExecute(enemyArmyQuery);
   // Bump up by 1 to just avoid running into this when the enemy explorer and its companion get in our base...
   if (enemyArmySize >= 3)
   { // Main base is under attack
      debugMilitary("******** Main base (" + mainBaseID + ") under attack.");
      debugMilitary("******** Enemy count " + enemyArmySize + ", my army count " + armySize);
      if (gDefenseReflexBaseID == mainBaseID)
      { // We're already in a defense reflex for the main base
         if (((armySize * 3.0) < enemyArmySize) &&
             (enemyArmySize > 6.0)) // Army at least 3x my size and more than 6 units total.
         {                          // Too big to handle
            if ((gDefenseReflexPaused == false) && (kbUnitCount(cMyID, cUnitTypeMinuteman, cUnitStateAlive) < 1) &&
                (kbUnitCount(cMyID, cUnitTypeypIrregular, cUnitStateAlive) < 1) &&
                (kbUnitCount(cMyID, cUnitTypeypPeasant, cUnitStateAlive) < 1) &&
                (kbUnitCount(cMyID, cUnitTypexpWarrior, cUnitStateAlive) < 2))
            { // We weren't paused and don't have emergency soldiers with decaying health, do it
               pauseDefenseReflex();
            }
            // Consider a call for help
            panic = true;
            if (((xsGetTime() - lastHelpTime) < 300000) &&
                (lastHelpBaseID == gDefenseReflexBaseID)) // We called for help in the last five minutes, and it was this base
               panic = false;
            if (((xsGetTime() - lastHelpTime) < 60000) &&
                (lastHelpBaseID != gDefenseReflexBaseID)) // We called for help anywhere in the last minute
               panic = false;

            if (panic == true)
            {
               sendStatement(
                   cPlayerRelationAlly, cAICommPromptToAllyINeedHelpMyBase, kbBaseGetLocation(cMyID, gDefenseReflexBaseID));
               debugMilitary("     I'm calling for help.");
               lastHelpTime = xsGetTime();
            }

            // Call back our attack if any.
            planID = aiPlanGetIDByTypeAndVariableType(cPlanCombat, cCombatPlanCombatType, cCombatPlanCombatTypeAttack);
            if (planID >= 0)
               aiPlanDestroy(planID);
         }
         else
         {                                    // Size is OK to handle, shouldn't be in paused mode.
            if (gDefenseReflexPaused == true) // Need to turn it active
            {
               moveDefenseReflex(kbBaseGetLocation(cMyID, mainBaseID), cvDefenseReflexRadiusActive, mainBaseID);
            }
         }
      }
      else // Defense reflex wasn't set to main base.
      {    // Need to set the defense reflex to home base...doesn't matter if it was inactive or guarding another base,
           // home base trumps all.
         moveDefenseReflex(kbBaseGetLocation(cMyID, mainBaseID), cvDefenseReflexRadiusActive, mainBaseID);
         // This is a new defense reflex in the main base.  Consider making a chat about it.
         int enemyPlayerID = kbUnitGetPlayerID(kbUnitQueryGetResult(enemyArmyQuery, 0));
         if ((enemyPlayerID > 0) && (kbGetAge() > cAge1))
         { // Consider sending a chat as long as we're out of age 1.
            int enemyPlayerUnitCount = getUnitCountByLocation(
                cUnitTypeLogicalTypeLandMilitary,
                enemyPlayerID,
                cUnitStateAlive,
                kbBaseGetLocation(cMyID, gDefenseReflexBaseID),
                50.0);
            if ((enemyPlayerUnitCount > (2 * gGoodArmyPop)) && (enemyPlayerUnitCount > (3 * armySize)))
            { // Enemy army is big, and we're badly outnumbered
               sendStatement(
                   enemyPlayerID,
                   cAICommPromptToEnemyISpotHisArmyMyBaseOverrun,
                   kbBaseGetLocation(cMyID, gDefenseReflexBaseID));
               debugMilitary("Sending OVERRUN prompt to player " + enemyPlayerID + ", he has " + enemyPlayerUnitCount + " units.");
               debugMilitary("I have " + armySize + " units, and " + gGoodArmyPop + " is a good army size.");
               return;
            }
            if (enemyPlayerUnitCount > (2 * gGoodArmyPop))
            { // Big army, but I'm still in the fight
               sendStatement(
                   enemyPlayerID, cAICommPromptToEnemyISpotHisArmyMyBaseLarge, kbBaseGetLocation(cMyID, gDefenseReflexBaseID));
               debugMilitary("Sending LARGE ARMY prompt to player " + enemyPlayerID + ", he has " + enemyPlayerUnitCount + " units.");
               debugMilitary("I have " + armySize + " units, and " + gGoodArmyPop + " is a good army size.");
               return;
            }
            if (enemyPlayerUnitCount > gGoodArmyPop)
            {
               // Moderate size
               sendStatement(
                   enemyPlayerID, cAICommPromptToEnemyISpotHisArmyMyBaseMedium, kbBaseGetLocation(cMyID, gDefenseReflexBaseID));
               debugMilitary("Sending MEDIUM ARMY prompt to player " + enemyPlayerID + ", he has " + enemyPlayerUnitCount + " units.");
               debugMilitary("I have " + armySize + " units, and " + gGoodArmyPop + " is a good army size.");
               return;
            }
            if ((enemyPlayerUnitCount < gGoodArmyPop) && (enemyPlayerUnitCount < armySize))
            { // Small, and under control
               sendStatement(
                   enemyPlayerID, cAICommPromptToEnemyISpotHisArmyMyBaseSmall, kbBaseGetLocation(cMyID, gDefenseReflexBaseID));
               debugMilitary("Sending SMALL ARMY prompt to player " + enemyPlayerID + ", he has " + enemyPlayerUnitCount + " units.");
               debugMilitary("I have " + armySize + " units, and " + gGoodArmyPop + " is a good army size.");
               return;
            }
         }
      }
      return; // Do not check other bases
   }

   // If we're this far, the main base is OK.  If we're in a defense reflex, see if we should stay in it, or change from
   // passive to active.

   if (gDefenseReflex == true) // Currently in a defense mode, let's see if it should remain
   {
      kbUnitQuerySetPosition(enemyArmyQuery, gDefenseReflexLocation);
      kbUnitQuerySetMaximumDistance(enemyArmyQuery, cvDefenseReflexSearchRadius);
      kbUnitQuerySetSeeableOnly(enemyArmyQuery, true);
      kbUnitQuerySetState(enemyArmyQuery, cUnitStateAlive);
      kbUnitQueryResetResults(enemyArmyQuery);
      enemyArmySize = kbUnitQueryExecute(enemyArmyQuery);
      debugMilitary("******** Defense reflex in base " + gDefenseReflexBaseID + " at " + gDefenseReflexLocation);
      debugMilitary("******** Enemy unit count: " + enemyArmySize + ", my unit count (defend+reserve) = " + armySize);
      for (i = 0; < enemyArmySize)
      {
         unitID = kbUnitQueryGetResult(enemyArmyQuery, i);
         protoUnitID = kbUnitGetProtoUnitID(unitID);
         if (i < 2)
            debugMilitary("    " + unitID + " " + kbGetProtoUnitName(protoUnitID) + " " + kbUnitGetPosition(unitID));
      }

      if (enemyArmySize < 2)
      { // Abort, no enemies, or just one scouting unit
         if (xsGetTime() >= gDefenseReflexTimeout || armySize >= gGoodArmyPop ||
             (gRevolutionType & cRevolutionFinland) == cRevolutionFinland)
         { // Wait for a random period before moving to the forward base.
            debugMilitary("******** Ending defense reflex, no enemies remain.");
            endDefenseReflex();
         }
         return;
      }

      if (baseBuildingCount(gDefenseReflexBaseID, cPlayerRelationAlly, cUnitStateAlive) <= 0)
      { // Abort, no alive ally buildings
         debugMilitary("******** Ending defense reflex, base " + gDefenseReflexBaseID + " has no buildings.");
         endDefenseReflex();
         return;
      }

      if (kbBaseGetOwner(gDefenseReflexBaseID) <= 0)
      { // Abort, base doesn't exist
         debugMilitary("******** Ending defense reflex, base " + gDefenseReflexBaseID + " doesn't exist.");
         endDefenseReflex();
         return;
      }

      // The defense reflex for this base should remain in effect.
      // Check whether to start/end paused mode.
      int unitsNeeded = gGoodArmyPop;        // At least a credible army to fight them
      if (unitsNeeded > (enemyArmySize / 2)) // Or half their force, whichever is less.
         unitsNeeded = enemyArmySize / 2;
      bool shouldPause = false;
      if (((armySize < unitsNeeded) && ((armySize * 3.0) < enemyArmySize)) &&
          (kbUnitCount(cMyID, cUnitTypeMinuteman, cUnitStateAlive) < 1) &&
          (kbUnitCount(cMyID, cUnitTypeypIrregular, cUnitStateAlive) < 1) &&
          (kbUnitCount(cMyID, cUnitTypeypPeasant, cUnitStateAlive) < 1) &&
          (kbUnitCount(cMyID, cUnitTypexpWarrior, cUnitStateAlive) < 2))
         shouldPause = true; // We should pause if not paused, or stay paused if we are

      if (gDefenseReflexPaused == false)
      { // Not currently paused, do it
         if (shouldPause == true)
         {
            pauseDefenseReflex();
            debugMilitary("******** Enemy count " + enemyArmySize + ", my army count " + armySize);
         }
      }
      else
      { // Currently paused...should we remain paused, or go active?
         if (shouldPause == false)
         {
            moveDefenseReflex(gDefenseReflexLocation, cvDefenseReflexRadiusActive, gDefenseReflexBaseID); // Activate it
            debugMilitary("******** Enemy count " + enemyArmySize + ", my army count " + armySize);
         }
      }
      if (shouldPause == true)
      { // Consider a call for help
         panic = true;
         if (((xsGetTime() - lastHelpTime) < 300000) &&
             (lastHelpBaseID == gDefenseReflexBaseID)) // We called for help in the last five minutes, and it was this base
            panic = false;
         if (((xsGetTime() - lastHelpTime) < 60000) &&
             (lastHelpBaseID != gDefenseReflexBaseID)) // We called for help anywhere in the last minute
            panic = false;

         if (panic == true)
         {
            sendStatement(
                cPlayerRelationAlly, cAICommPromptToAllyINeedHelpMyBase, kbBaseGetLocation(cMyID, gDefenseReflexBaseID));
            debugMilitary("     I'm calling for help.");
            lastHelpTime = xsGetTime();
         }

         // Call back our attack if any.
         // TODO: Not main base, maybe not always worth defending?
         planID = aiPlanGetIDByTypeAndVariableType(cPlanCombat, cCombatPlanCombatType, cCombatPlanCombatTypeAttack);
         if (planID >= 0)
            aiPlanDestroy(planID);
      }
      return; // Done...we're staying in defense mode for this base, and have paused or gone active as needed.
   }

   // Not in a defense reflex, see if one is needed

   // Check other bases
   int baseCount = -1;
   int baseIndex = -1;
   int baseID = -1;
   vector baseLoc = cInvalidVector;
   /*int defendBaseID = aiPlanGetVariableInt(gLandDefendPlan0, cCombatPlanTargetBaseID, 0);

   if (defendBaseID < 0)
      defendBaseID = aiPlanGetVariableInt(gLandReservePlan, cCombatPlanTargetBaseID, 0);

   vector defendLoc = kbBaseGetLocation(cMyID, defendBaseID);
   int defendAreaGroup = kbAreaGroupGetIDByPosition(defendLoc);
   int baseAreaGroup = -1;*/

   baseCount = kbBaseGetNumber(cMyID);
   unitsNeeded = gGoodArmyPop / 2;
   if (baseCount > 0)
   {
      for (baseIndex = 0; < baseCount)
      {
         baseID = kbBaseGetIDByIndex(cMyID, baseIndex);
         if (baseID == kbBaseGetMainID(cMyID))
            continue; // Already checked main at top of function

         if (baseBuildingCount(baseID, cPlayerRelationAlly, cUnitStateAlive) <= 0)
         {
            debugMilitary("Base " + baseID + " has no alive buildings.");
            continue; // Skip bases that have no buildings
         }

         // Check for overrun base
         baseLoc = kbBaseGetLocation(cMyID, baseID);
         kbUnitQuerySetPosition(enemyArmyQuery, baseLoc);
         kbUnitQuerySetMaximumDistance(enemyArmyQuery, cvDefenseReflexSearchRadius);
         kbUnitQuerySetSeeableOnly(enemyArmyQuery, true);
         kbUnitQuerySetState(enemyArmyQuery, cUnitStateAlive);
         kbUnitQueryResetResults(enemyArmyQuery);
         enemyArmySize = kbUnitQueryExecute(enemyArmyQuery);
         // Do I need to call for help?

         if ((enemyArmySize >= 2))
         { // More than just a scout...set defense reflex for this base
            moveDefenseReflex(baseLoc, cvDefenseReflexRadiusActive, baseID);

            debugMilitary("******** Enemy count is " + enemyArmySize + ", my army size is " + armySize);

            if ((enemyArmySize > (armySize * 2.0)) && (enemyArmySize > 6)) // Double my size, get help...
            {
               panic = true;
               if (((xsGetTime() - lastHelpTime) < 300000) &&
                   (lastHelpBaseID == baseID)) // We called for help in the last five minutes, and it was this base
                  panic = false;
               if (((xsGetTime() - lastHelpTime) < 60000) &&
                   (lastHelpBaseID != baseID)) // We called for help anywhere in the last minute
                  panic = false;

               if (panic == true)
               {
                  // Don't kill other missions, this isn't the main base.  Just call for help.
                  sendStatement(cPlayerRelationAlly, cAICommPromptToAllyINeedHelpMyBase, kbBaseGetLocation(cMyID, baseID));
                  debugMilitary("     I'm calling for help.");
                  lastHelpTime = xsGetTime();
               }
            }
            else
            {
               moveDefenseReflex(baseLoc, cvDefenseReflexRadiusActive, baseID);
            }
            return; // If we're in trouble in any base, ignore the others.
         }
      } // For baseIndex...
   }
}

//==============================================================================
// useLevy
//==============================================================================
rule useLevy
inactive
minInterval 10
{
   // Check to see if town is being overrun.  If so, generate a plan
   // to 'research' levy.  If plan is active but enemies disappear,
   // destroy it.  Once research is complete, end this rule.

   static int levyPlan = -1;
   vector mainBaseVec = cInvalidVector;
   int techID = -1;

   if (cMyCiv != cCivDEAmericans)
      techID = cTechLevy;
   else
      techID = cTechDEUSLevy;

   mainBaseVec = kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID));

   int towncenterID = getUnitByLocation(cUnitTypeTownCenter, cMyID, cUnitStateAlive, mainBaseVec, 40.0);

   if ((towncenterID < 0) || (kbBuildingTechGetStatus(techID, towncenterID) != cTechStatusObtainable))
   {
      if (levyPlan >= 0)
      {
         debugMilitary("   ** Destroying levy plan.");
         aiPlanDestroy(levyPlan);
         levyPlan = -1;
      }
      return;
   }

   int enemyCount = getUnitCountByLocation(
       cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia, cUnitStateAlive, mainBaseVec, 40.0);
   int allyCount = getUnitCountByLocation(
       cUnitTypeLogicalTypeLandMilitary, cPlayerRelationAlly, cUnitStateAlive, mainBaseVec, 40.0);

   if (levyPlan < 0)
   { // Create a new plan.
      if (enemyCount >= (allyCount + 5))
      { // We're behind by 5 or more
         if (kbBuildingTechGetStatus(techID, towncenterID) == cTechStatusObtainable)
            levyPlan = createSimpleResearchPlanSpecificBuilding(
                techID, towncenterID, cMilitaryEscrowID, 99); // Extreme priority
         if (levyPlan >= 0)
         {
            debugMilitary(
                "***** Starting a levy plan, there are " + enemyCount + " enemy units in my base against " + allyCount +
                " friendlies.");
            aiPlanSetDesiredResourcePriority(levyPlan, 85);
         }
      }
   }
   else // Plan exists, make sure it's still needed.
   {
      if ((enemyCount > (allyCount + 2)) && (aiPlanGetState(levyPlan) >= 0))
      { // Do nothing
         debugMilitary("   ** Still waiting for levy.");
      }
      else
      {
         debugMilitary("   ** Destroying levy plan.");
         aiPlanDestroy(levyPlan);
         levyPlan = -1;
      }
   }
}

//==============================================================================
// useAsianLevy
//==============================================================================
rule useAsianLevy
inactive
minInterval 10
{
   // Check to see if town is being overrun.  If so, generate a plan
   // to 'research' levy.  If plan is active but enemies disappear,
   // destroy it.  Once research is complete, end this rule.

   static int levyPlan = -1;
   vector mainBaseVec = cInvalidVector;

   mainBaseVec = kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID));

   int towncenterID = getUnitByLocation(cUnitTypeTownCenter, cMyID, cUnitStateAlive, mainBaseVec, 40.0);

   int levy1 = cTechypAssemble;
   int levy2 = cTechypMuster;
   if ((cMyCiv == cCivIndians) || (cMyCiv == cCivSPCIndians))
   {
      levy1 = cTechypAssembleIndians;
      levy2 = cTechypMusterIndians;
   }

   if ((towncenterID < 0) || ((kbBuildingTechGetStatus(levy1, towncenterID) != cTechStatusObtainable) &&
                              (kbBuildingTechGetStatus(levy2, towncenterID) != cTechStatusObtainable)))
   {
      if (levyPlan >= 0)
      {
         debugMilitary("   ** Destroying levy plan.");
         aiPlanDestroy(levyPlan);
         levyPlan = -1;
      }
      return;
   }

   int enemyCount = getUnitCountByLocation(
       cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia, cUnitStateAlive, mainBaseVec, 40.0);
   int enemyCavalryCount = getUnitCountByLocation(
                               cUnitTypeAbstractCavalry, cPlayerRelationEnemyNotGaia, cUnitStateAlive, mainBaseVec, 40.0) +
                           getUnitCountByLocation(
                               cUnitTypeAbstractCoyoteMan, cPlayerRelationEnemyNotGaia, cUnitStateAlive, mainBaseVec, 40.0);
   int allyCount = getUnitCountByLocation(
       cUnitTypeLogicalTypeLandMilitary, cPlayerRelationAlly, cUnitStateAlive, mainBaseVec, 40.0);

   if (levyPlan < 0)
   { // Create a new plan.
      if (enemyCount >= (allyCount + 5))
      { // We're behind by 5 or more
         if (kbBuildingTechGetStatus(levy1, towncenterID) == cTechStatusObtainable && (enemyCavalryCount * 2 >= enemyCount))
            levyPlan = createSimpleResearchPlanSpecificBuilding(levy1, towncenterID, cMilitaryEscrowID, 99); // Extreme priority
         else if (kbBuildingTechGetStatus(levy2, towncenterID) == cTechStatusObtainable)
            levyPlan = createSimpleResearchPlanSpecificBuilding(levy2, towncenterID, cMilitaryEscrowID, 99); // Extreme priority
         if (levyPlan >= 0)
         {
            debugMilitary(
                "***** Starting a levy plan, there are " + enemyCount + " enemy units in my base against " + allyCount +
                " friendlies.");
            aiPlanSetDesiredResourcePriority(levyPlan, 85);
         }
      }
   }
   else // Plan exists, make sure it's still needed.
   {
      if ((enemyCount > (allyCount + 2)) && (aiPlanGetState(levyPlan) >= 0))
      { // Do nothing
         debugMilitary("   ** Still waiting for levy.");
      }
      else
      {
         debugMilitary("   ** Destroying levy plan.");
         aiPlanDestroy(levyPlan);
         levyPlan = -1;
      }
   }
}

//==============================================================================
// consulateLevy
//==============================================================================
rule consulateLevy
inactive
minInterval 10
{
   // Check to see if town is being overrun. If so, generate a plan to research
   // Ottoman levy at the consulate.  If plan is active but enemies disappear,
   // destroy it.  Once research is complete, end this rule.

   int levyPlan = -1;
   vector mainBaseVec = cInvalidVector;

   mainBaseVec = kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID));

   if (kbTechGetStatus(cTechypConsulateOttomansSettlerCombat) == cTechStatusActive)
   {
      xsDisableSelf();
      return;
   }

   int enemyCount = getUnitCountByLocation(
       cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia, cUnitStateAlive, mainBaseVec, 40.0);
   int allyCount = getUnitCountByLocation(
       cUnitTypeLogicalTypeLandMilitary, cPlayerRelationAlly, cUnitStateAlive, mainBaseVec, 40.0);

   if (levyPlan < 0) // No plan, see if we need one.
   {
      if ((enemyCount >= (allyCount + 5)) && (kbTechGetStatus(cTechypConsulateOttomansSettlerCombat) == cTechStatusObtainable))
      { // We're behind by 5 or more
         debugMilitary(
             "***** Starting consulate levy plan, there are " + enemyCount + " enemy units in my base against " + allyCount +
             " friendlies.");
         levyPlan = createSimpleResearchPlan(
             cTechypConsulateOttomansSettlerCombat, cUnitTypeypConsulate, cMilitaryEscrowID, 99); // Extreme priority
         aiPlanSetDesiredResourcePriority(levyPlan, 85);
      }
   }
   else // Plan exists, make sure it's still needed
   {
      if ((enemyCount > (allyCount + 2)) && (aiPlanGetState(levyPlan) >= 0))
      { // Do nothing
         debugMilitary("   ** Still waiting for consulate levy.");
      }
      else
      {
         debugMilitary("   ** Destroying consulate levy plan.");
         aiPlanDestroy(levyPlan);
         levyPlan = -1;
      }
   }
}

//==============================================================================
// useAfricanLevy
//==============================================================================
rule useAfricanLevy
inactive
minInterval 10
{
   static int levyMaintainPlan = -1;
   static float spearmanCost = -1.0;
   static float bowmanCost = -1.0;
   static float gunnerCost = -1.0;
   if (spearmanCost == -1.0) // First run.
   {
      spearmanCost = kbUnitCostPerResource(cUnitTypedeSpearmanLevy, cResourceInfluence);
      bowmanCost = kbUnitCostPerResource(cUnitTypedeBowmanLevy, cResourceInfluence);
      gunnerCost = kbUnitCostPerResource(cUnitTypedeGunnerLevy, cResourceInfluence);
   }
   int age = kbGetAge();
   int tcID = -1;
   int palaceID = -1;
   vector mainBaseVec = kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID));
   int houseID = getUnitByLocation(gHouseUnit, cMyID, cUnitStateAlive, mainBaseVec, 40.0);
   float currentInfluenceAmount = kbResourceGet(cResourceInfluence);
   if (cMyCiv == cCivDEHausa)
   {
      if (xsArrayGetBool(gAfricanAlliancesAgedUpWith, cAllianceSonghaiIndex) == true)
      { // We've aged up with Songhai so we can use the Songhai Raid ability to defend ourselves.
         tcID = getUnitByLocation(cUnitTypeTownCenter, cMyID, cUnitStateAlive, mainBaseVec, 40.0);
      }
   }

   if ((mainBaseVec == cInvalidVector) || ((houseID < 0) && (tcID < 0)) || (currentInfluenceAmount < spearmanCost))
   {
      if (levyMaintainPlan >= 0)
      {
         aiPlanDestroy(levyMaintainPlan);
         levyMaintainPlan = -1;
      }
      return;
   }

   if (age >= cAge3) // Palaces can be used for Gunners which are locked behind the Fortress Age.
   {
      palaceID = getUnitByLocation(cUnitTypedePalace, cMyID, cUnitStateAlive, mainBaseVec, 40.0);
   }

   int enemyCount = getUnitCountByLocation(
       cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia, cUnitStateAlive, mainBaseVec, 40.0);
   int enemyCavalryCount = getUnitCountByLocation(
                               cUnitTypeAbstractCavalry, cPlayerRelationEnemyNotGaia, cUnitStateAlive, mainBaseVec, 40.0) +
                           getUnitCountByLocation(
                               cUnitTypeAbstractCoyoteMan, cPlayerRelationEnemyNotGaia, cUnitStateAlive, mainBaseVec, 40.0);
   int allyCount = getUnitCountByLocation(
       cUnitTypeLogicalTypeLandMilitary, cPlayerRelationAlly, cUnitStateAlive, mainBaseVec, 40.0);

   int amountBehind = enemyCount - allyCount;
   if (amountBehind - 5 >= 0)
   { // We're behind by 5 or more thus we need to get some levies.
      if (cMyCiv == cCivDEHausa)
      {
         if ((currentInfluenceAmount > 1000.0) && (tcID >= 0))
         {
            createSimpleResearchPlanSpecificBuilding(cTechDEAllegianceSonghaiLevyRaiders, tcID, cMilitaryEscrowID, 99);
            currentInfluenceAmount -= kbTechCostPerResource(cTechDEAllegianceSonghaiLevyRaiders, cResourceInfluence);
         }
      }

      int levyPUID = -1;
      int numberToMaintain = 0;
      if (enemyCavalryCount * 2 >= enemyCount)
      { // Counter a force consisting of mainly Cavalry with Spearman.
         levyPUID = cUnitTypedeSpearmanLevy;
         numberToMaintain = currentInfluenceAmount / spearmanCost;
      }
      else if ((age >= cAge3) && (palaceID >= 0))
      {
         levyPUID = cUnitTypedeGunnerLevy;
         numberToMaintain = currentInfluenceAmount / gunnerCost;
      }
      else
      {
         levyPUID = cUnitTypedeBowmanLevy;
         numberToMaintain = currentInfluenceAmount / bowmanCost;
      }

      // Don't overtrain when we have a lot of Influence.
      if (numberToMaintain > 6)
      {
         numberToMaintain = 6;
      }

      debugMilitary("We have to use levies and decided we should make " + numberToMaintain + " " + kbGetProtoUnitName(levyPUID));
      // If we don't have a plan make one otherwise adjust how many to maintain for the existing plan.
      if (levyMaintainPlan < 0)
      {
         levyMaintainPlan = createSimpleMaintainPlan(levyPUID, numberToMaintain, false, kbBaseGetMainID(cMyID), 1);
         aiPlanSetDesiredResourcePriority(levyMaintainPlan, 99);
      }
      else
      {
         aiPlanSetVariableInt(levyMaintainPlan, cTrainPlanUnitType, 0, levyPUID);
         aiPlanSetVariableInt(levyMaintainPlan, cTrainPlanNumberToMaintain, 0, numberToMaintain);
      }
   }
   else if (levyMaintainPlan >= 0)
   {
      aiPlanDestroy(levyMaintainPlan);
      levyMaintainPlan = -1;
   }
}

//==============================================================================
// useWarParties
//==============================================================================
rule useWarParties
inactive
minInterval 10
{
   // Check to see if town is being overrun. If so, generate a plan to research
   // available war party.  If plan is active but enemies disappear, destroy it.
   static int partyPlan = -1;
   vector mainBaseVec = cInvalidVector;

   mainBaseVec = kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID));
   int enemyCount = getUnitCountByLocation(
       cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia, cUnitStateAlive, mainBaseVec, 40.0);
   int allyCount = getUnitCountByLocation(
       cUnitTypeLogicalTypeLandMilitary, cPlayerRelationAlly, cUnitStateAlive, mainBaseVec, 40.0);

   //if (partyPlan < 0) // No plan, see if we need one.
   //{
      if ((((partyPlan < 0) && (aiTreatyActive() == true) == false) && (xsGetTime() - gAgeUpTime > 125000)) || (enemyCount >= (allyCount + 5))) // No plan, see if we need one.
   {
      //if (enemyCount >= (allyCount + 5)) // We're behind by 5 or more
      //{
         aiEcho(
             "***** Starting a WarParty plan, there are " + enemyCount + " enemy units in my base against " + allyCount +
             " friendlies.");
         if (cMyCiv == cCivXPAztec)
         {
            if ((kbTechGetStatus(cTechBigAztecScoutingParty) == cTechStatusObtainable) &&
                (kbUnitCount(cMyID, cUnitTypeTownCenter, cUnitStateAlive) >= 1) && (kbGetAge() >= cAge2))
               partyPlan = createSimpleResearchPlanSpecificBuilding(
                   cTechBigAztecScoutingParty,
                   getUnitByLocation(cUnitTypeTownCenter, cMyID, cUnitStateAlive, mainBaseVec, 40.0),
                   cMilitaryEscrowID,
                   99); // Extreme priority
            else if (
                (kbTechGetStatus(cTechBigAztecRaidingParty) == cTechStatusObtainable) &&
                (kbUnitCount(cMyID, cUnitTypeTownCenter, cUnitStateAlive) >= 1) && (kbGetAge() >= cAge2))
               partyPlan = createSimpleResearchPlanSpecificBuilding(
                   cTechBigAztecRaidingParty,
                   getUnitByLocation(cUnitTypeTownCenter, cMyID, cUnitStateAlive, mainBaseVec, 40.0),
                   cMilitaryEscrowID,
                   99); // Extreme priority
            else if (
                (kbTechGetStatus(cTechBigAztecWarParty) == cTechStatusObtainable) &&
                (kbUnitCount(cMyID, cUnitTypeTownCenter, cUnitStateAlive) >= 1) && (kbGetAge() >= cAge2))
               partyPlan = createSimpleResearchPlanSpecificBuilding(
                   cTechBigAztecWarParty,
                   getUnitByLocation(cUnitTypeTownCenter, cMyID, cUnitStateAlive, mainBaseVec, 40.0),
                   cMilitaryEscrowID,
                   99); // Extreme priority
         }
         else if (cMyCiv == cCivXPIroquois)
         {
            if ((kbTechGetStatus(cTechBigIroquoisScoutingParty) == cTechStatusObtainable) &&
                (kbUnitCount(cMyID, cUnitTypeTownCenter, cUnitStateAlive) >= 1) && (kbGetAge() >= cAge2))
               partyPlan = createSimpleResearchPlanSpecificBuilding(
                   cTechBigIroquoisScoutingParty,
                   getUnitByLocation(cUnitTypeTownCenter, cMyID, cUnitStateAlive, mainBaseVec, 40.0),
                   cMilitaryEscrowID,
                   99); // Extreme priority
            else if (
                (kbTechGetStatus(cTechBigIroquoisRaidingParty) == cTechStatusObtainable) &&
                (kbUnitCount(cMyID, cUnitTypeTownCenter, cUnitStateAlive) >= 1) && (kbGetAge() >= cAge2))
               partyPlan = createSimpleResearchPlanSpecificBuilding(
                   cTechBigIroquoisRaidingParty,
                   getUnitByLocation(cUnitTypeTownCenter, cMyID, cUnitStateAlive, mainBaseVec, 40.0),
                   cMilitaryEscrowID,
                   99); // Extreme priority
            else if (
                (kbTechGetStatus(cTechBigIroquoisWarParty) == cTechStatusObtainable) &&
                (kbUnitCount(cMyID, cUnitTypeTownCenter, cUnitStateAlive) >= 1) && (kbGetAge() >= cAge2))
               partyPlan = createSimpleResearchPlanSpecificBuilding(
                   cTechBigIroquoisWarParty,
                   getUnitByLocation(cUnitTypeTownCenter, cMyID, cUnitStateAlive, mainBaseVec, 40.0),
                   cMilitaryEscrowID,
                   99); // Extreme priority
         }
         else if (cMyCiv == cCivXPSioux)
         {
            if ((xsGetTime() > 30 * 60 * 1000) && (kbTechGetStatus(cTechBigSiouxDogSoldiers) == cTechStatusObtainable) &&
                (kbUnitCount(cMyID, cUnitTypeTownCenter, cUnitStateAlive) >= 1) &&
                (kbGetAge() >= cAge2)) // Use only after at least 18 minutes of game time (i.e. 6 units)
               partyPlan = createSimpleResearchPlanSpecificBuilding(
                   cTechBigSiouxDogSoldiers,
                   getUnitByLocation(cUnitTypeTownCenter, cMyID, cUnitStateAlive, mainBaseVec, 40.0),
                   cMilitaryEscrowID,
                   99); // Extreme priority
         }
         else if (cMyCiv == cCivDEInca)
         {
            if ((kbTechGetStatus(cTechdeBigIncaScoutingParty) == cTechStatusObtainable) &&
                (kbUnitCount(cMyID, cUnitTypeTownCenter, cUnitStateAlive) >= 1) && (kbGetAge() >= cAge2))
               partyPlan = createSimpleResearchPlanSpecificBuilding(
                   cTechdeBigIncaScoutingParty,
                   getUnitByLocation(cUnitTypeTownCenter, cMyID, cUnitStateAlive, mainBaseVec, 40.0),
                   cMilitaryEscrowID,
                   99); // Extreme priority
            else if (
                (kbTechGetStatus(cTechdeBigIncaRaidingParty) == cTechStatusObtainable) &&
                (kbUnitCount(cMyID, cUnitTypeTownCenter, cUnitStateAlive) >= 1) && (kbGetAge() >= cAge2))
               partyPlan = createSimpleResearchPlanSpecificBuilding(
                   cTechdeBigIncaRaidingParty,
                   getUnitByLocation(cUnitTypeTownCenter, cMyID, cUnitStateAlive, mainBaseVec, 40.0),
                   cMilitaryEscrowID,
                   99); // Extreme priority
            else if (
                (kbTechGetStatus(cTechdeBigIncaWarParty) == cTechStatusObtainable) &&
                (kbUnitCount(cMyID, cUnitTypeTownCenter, cUnitStateAlive) >= 1) && (kbGetAge() >= cAge2))
               partyPlan = createSimpleResearchPlanSpecificBuilding(
                   cTechdeBigIncaWarParty,
                   getUnitByLocation(cUnitTypeTownCenter, cMyID, cUnitStateAlive, mainBaseVec, 40.0),
                   cMilitaryEscrowID,
                   99); // Extreme priority
         }
      //}
   }
   /*else // Plan exists, make sure it's still needed
   {
      if ((enemyCount >= (allyCount + 2)) && (aiPlanGetState(partyPlan) >= 0))
      { // Do nothing
         aiEcho("   ** Still waiting for WarParty.");
         aiPlanSetDesiredResourcePriority(partyPlan, 85);
      }
      else
      {
         aiEcho("   ** Cancelling WarParty.");
         aiPlanDestroy(partyPlan);
         partyPlan = -1;
      }
   }*/
}

//==============================================================================
// healerMonitor
//==============================================================================
rule healerMonitor
inactive
minInterval 30
{
   int priestCount = kbUnitCount(cMyID, cUnitTypePriest, cUnitStateAlive);
   int priestessCount = kbUnitCount(cMyID, cUnitTypedePriestess, cUnitStateAlive);
   int missionaryCount = kbUnitCount(cMyID, cUnitTypeMissionary, cUnitStateAlive);
   int surgeonCount = kbUnitCount(cMyID, cUnitTypeSurgeon, cUnitStateAlive);
   int imamCount = kbUnitCount(cMyID, cUnitTypeImam, cUnitStateAlive);
   int natMedicineManCount = kbUnitCount(cMyID, cUnitTypeNatMedicineMan, cUnitStateAlive);
   int xpMedicineManCount = kbUnitCount(cMyID, cUnitTypexpMedicineMan, cUnitStateAlive);
   int xpMedicineManAztecCount = kbUnitCount(cMyID, cUnitTypexpMedicineManAztec, cUnitStateAlive);
   int griotCount = kbUnitCount(cMyID, cUnitTypedeGriot, cUnitStateAlive);
   int abunCount = kbUnitCount(cMyID, cUnitTypedeAbun, cUnitStateAlive);
   int mainBaseID = kbBaseGetMainID(cMyID);

   if (gHealerPlan < 0)
   {
      gHealerPlan = aiPlanCreate("Healer Control Plan", cPlanCombat);

      aiPlanSetVariableInt(gHealerPlan, cCombatPlanCombatType, 0, cCombatPlanCombatTypeDefend);
      aiPlanSetVariableInt(gHealerPlan, cCombatPlanTargetMode, 0, cCombatPlanTargetModeBase);
      aiPlanSetVariableVector(gHealerPlan, cCombatPlanTargetPoint, 0, kbBaseGetMilitaryGatherPoint(cMyID, mainBaseID));
      aiPlanSetVariableInt(gHealerPlan, cCombatPlanTargetPlayerID, 0, cMyID);
      aiPlanSetVariableInt(gHealerPlan, cCombatPlanTargetBaseID, 0, mainBaseID);
      aiPlanSetVariableFloat(gHealerPlan, cCombatPlanGatherDistance, 0, 10.0);
      aiPlanSetInitialPosition(gHealerPlan, kbBaseGetLocation(cMyID, mainBaseID));
      aiPlanSetUnitStance(gHealerPlan, cUnitStanceDefensive);
      aiPlanSetVariableInt(gHealerPlan, cCombatPlanRefreshFrequency, 0, 1000);
      aiPlanSetDesiredPriority(
          gHealerPlan,
          51); // Just higher priority than attack and defend plans, but lower than native research and gather plans.
      aiPlanSetActive(gHealerPlan);
      debugMilitary("Creating healer plan");
   }

   // Set units required to 0 to allow gather plans to steal from us.
   aiPlanAddUnitType(gHealerPlan, cUnitTypePriest, 0, priestCount, priestCount);
   aiPlanAddUnitType(gHealerPlan, cUnitTypeMissionary, 0, missionaryCount, missionaryCount);
   aiPlanAddUnitType(gHealerPlan, cUnitTypeSurgeon, 0, surgeonCount, surgeonCount);
   aiPlanAddUnitType(gHealerPlan, cUnitTypeImam, 0, imamCount, imamCount);
   aiPlanAddUnitType(gHealerPlan, cUnitTypeNatMedicineMan, 0, natMedicineManCount, natMedicineManCount);
   aiPlanAddUnitType(gHealerPlan, cUnitTypexpMedicineMan, 0, xpMedicineManCount, xpMedicineManCount);
   aiPlanAddUnitType(gHealerPlan, cUnitTypexpMedicineManAztec, 0, xpMedicineManAztecCount, xpMedicineManAztecCount);
   aiPlanAddUnitType(gHealerPlan, cUnitTypedePriestess, 0, priestessCount, priestessCount);
   aiPlanAddUnitType(gHealerPlan, cUnitTypedeGriot, 0, griotCount, griotCount);
   aiPlanAddUnitType(gHealerPlan, cUnitTypedeAbun, 0, abunCount, abunCount);
   // debugMilitary("Updating healer plan");
}

rule rescueExplorer
inactive
minInterval 120
{
   static int rescuePlan = -1;

   // Destroy old rescue plan (if any).
   if (rescuePlan >= 0)
   {
      aiPlanDestroy(rescuePlan);
      rescuePlan = -1;
      debugMilitary("Killing old rescue plan");
   }
   
   // Let the ransom rule take care of this if we have enough coin.
   if (kbResourceGet(cResourceGold) >= 1300)
   {
      debugMilitary("Ransom explorer instead of attempting to rescue");
      return;
   }

   int fallenExplorerID = aiGetFallenExplorerID();
   // We need a fallen Explorer for all of this to make sense right.
   if (fallenExplorerID < 0)
   {
      return;
   }
   
   // Only try to rescue an Explorer that can actually be revived.
   if (kbUnitGetHealth(fallenExplorerID) < 0.3)
   {
      debugMilitary("Explorer too weak to be rescued");
      return;
   }

   // Decide on which unit type to use for rescue attempt.
   int scoutType = findBestScoutType();
   
   // Get position of fallen explorer and send scout unit there.
   vector fallenExplorerLocation = kbUnitGetPosition(fallenExplorerID);
   rescuePlan = aiPlanCreate("Rescue Explorer", cPlanExplore);
   if (rescuePlan >= 0)
   {
      aiPlanAddUnitType(rescuePlan, scoutType, 1, 1, 1);
      aiPlanAddWaypoint(rescuePlan, fallenExplorerLocation);
      aiPlanSetVariableBool(rescuePlan, cExplorePlanDoLoops, 0, false);
      aiPlanSetVariableBool(rescuePlan, cExplorePlanAvoidingAttackedAreas, 0, false);
      aiPlanSetVariableInt(rescuePlan, cExplorePlanNumberOfLoops, 0, -1);
      aiPlanSetRequiresAllNeedUnits(rescuePlan, true);
      aiPlanSetDesiredPriority(rescuePlan, 42);
      aiPlanSetActive(rescuePlan);
      debugMilitary("Trying to rescue explorer");
   }
}

rule ransomExplorer
inactive
minInterval 120
{
   int fallenExplorerID = aiGetFallenExplorerID();
   // Use only when we have enough coin in the bank.
   if ((fallenExplorerID < 0) || (kbResourceGet(cResourceGold) < 1300))
   {
      return;
   }

   aiRansomExplorer(fallenExplorerID, cMilitaryEscrowID, getUnit(cUnitTypeTownCenter, cMyID, cUnitStateAlive));
   debugMilitary("Ransoming explorer");
}

rule monopolyManager
minInterval 21
inactive
group tcComplete
{
   if (aiTreatyActive() == true)
   {
      debugMilitary("    Monopoly delayed because treaty is active.");
      return;
   }
   
   if (kbUnitCount(cMyID, cUnitTypeTradingPost, cUnitStateAlive) < 1)
      return; // Not allowed to research without a building...

   if (aiReadyForTradeMonopoly() == true)
   {
      debugMilitary("      Trade monopoly is available.");
      if (kbResourceGet(cResourceGold) >= kbTechCostPerResource(cTechTradeMonopoly, cResourceGold) &&
          kbResourceGet(cResourceFood) >= kbTechCostPerResource(cTechTradeMonopoly, cResourceFood) &&
          kbResourceGet(cResourceWood) >= kbTechCostPerResource(cTechTradeMonopoly, cResourceWood))
      {
         debugMilitary("    Attempting trade monopoly");
         if (aiDoTradeMonopoly() == true)
            kbEscrowAllocateCurrentResources();
      }
      else
      {
         debugMilitary("    ....but I can't afford it.");
      }
   }
}

void KOTHVictoryStartHandler(int teamID = -1)
{
   // Sanity check, idk if needed at all.
   if (teamID < 0)
   {
      return;
   }   
   debugMilitary("King of the Hill timer started by team: " + teamID);

   gIsKOTHRunning = true;
   gKOTHTeam = teamID;
}

void KOTHVictoryEndHandler(int teamID = -1)
{
   gIsKOTHRunning = false;
   gKOTHTeam = -1;
   
   debugMilitary("Team: " + teamID + " have not completed the King of the Hill timer");
}

/*
rule summerPalaceTacticMonitor
inactive
mininterval 1
{
   // Check for the Summer Palace, if we don't find one we've lost it and we can disable this Rule.
   int summerPalaceID = getUnit(gSummerPalacePUID);
   if (summerPalaceID < 0)
   {
      xsDisableSelf();
      return;
   }
   
   for (i = 0; < 3)
   {
      int armyPUID = kbUnitPickGetResult(gLandUnitPicker, i);
      switch (armyPUID)
      {
      case cUnitTypeypTerritorialArmy:
      {
         aiUnitSetTactic(summerPalaceID, cTacticTerritorialArmy);
         xsSetRuleMinIntervalSelf(196);
         return;
      }
      case cUnitTypeypForbiddenArmy:
      {
         aiUnitSetTactic(summerPalaceID, cTacticForbiddenArmy);
         xsSetRuleMinIntervalSelf(295);
         return;
      }
      case cUnitTypeypImperialArmy:
      {
         aiUnitSetTactic(summerPalaceID, cTacticImperialArmy);
         xsSetRuleMinIntervalSelf(256);
         return;
      }
      case cUnitTypeypOldHanArmy:
      {
         aiUnitSetTactic(summerPalaceID, cTacticOldHanArmy);
         xsSetRuleMinIntervalSelf(154);
         return;
      }
      case cUnitTypeypStandardArmy:
      {
         aiUnitSetTactic(summerPalaceID, cTacticStandardArmy);
         xsSetRuleMinIntervalSelf(152);
         return;
      }
      case cUnitTypeypMingArmy:
      {
         aiUnitSetTactic(summerPalaceID, cTacticMingArmy); 
         xsSetRuleMinIntervalSelf(159);
         return;
      }
      }
   }
   
   // We didn't find any suitable armies in our unit picker, default to Standard Army.
   aiUnitSetTactic(summerPalaceID, cTacticStandardArmy);
   xsSetRuleMinIntervalSelf(152);
}
*/

rule mansabdarMonitor
inactive
minInterval 30
{
   static int mansabdarRajputPlan = -1;
   static int mansabdarSepoyPlan = -1;
   static int mansabdarGurkhaPlan = -1;
   static int mansabdarSowarPlan = -1;
   static int mansabdarZamburakPlan = -1;
   static int mansabdarFlailElephantPlan = -1;
   static int mansabdarMahoutPlan = -1;
   static int mansabdarHowdahPlan = -1;
   static int mansabdarSiegeElephantPlan = -1;

   // Check for the Charminar Gate, if we don't find one we've lost it and we can disable this Rule.
   int charminarGateID = getUnit(gCharminarGatePUID);
   if (charminarGateID < 0)
   {
      aiPlanDestroy(mansabdarRajputPlan);
      aiPlanDestroy(mansabdarSepoyPlan);
      aiPlanDestroy(mansabdarGurkhaPlan);
      aiPlanDestroy(mansabdarSowarPlan);
      aiPlanDestroy(mansabdarZamburakPlan);
      aiPlanDestroy(mansabdarFlailElephantPlan);
      aiPlanDestroy(mansabdarMahoutPlan);
      aiPlanDestroy(mansabdarHowdahPlan);
      aiPlanDestroy(mansabdarSiegeElephantPlan);
      xsDisableSelf();
      return;
   }

   int numRajputs = -1;
   int numSepoys = -1;
   int numGurkhas = -1;
   int numSowars = -1;
   int numZamburaks = -1;
   int numFlailElephants = -1;
   int numMahouts = -1;
   int numHowdahs = -1;
   int numSiegeElephants = -1;

   // Check number of rajputs, maintain mansabdar rajput as long as there are at least 10
   numRajputs = kbUnitCount(cMyID, cUnitTypeypRajput, cUnitStateAlive);
   if (numRajputs >= 10)
   {
      // Create/update maintain plan
      if (mansabdarRajputPlan < 0)
      {
         mansabdarRajputPlan = createSimpleMaintainPlan(cUnitTypeypRajputMansabdar, 1, false, kbBaseGetMainID(cMyID), 1);
      }
      else
      {
         aiPlanSetVariableInt(mansabdarRajputPlan, cTrainPlanNumberToMaintain, 0, 1);
      }
   }
   else
   {
      // Update maintain plan, provided it exists
      if (mansabdarRajputPlan >= 0)
      {
         aiPlanSetVariableInt(mansabdarRajputPlan, cTrainPlanNumberToMaintain, 0, 0);
      }
   }
   // Check number of sepoys, maintain mansabdar sepoy as long as there are at least 10
   numSepoys = kbUnitCount(cMyID, cUnitTypeypSepoy, cUnitStateAlive);
   if (numSepoys >= 10)
   {
      // Create/update maintain plan
      if (mansabdarSepoyPlan < 0)
      {
         mansabdarSepoyPlan = createSimpleMaintainPlan(cUnitTypeypSepoyMansabdar, 1, false, kbBaseGetMainID(cMyID), 1);
      }
      else
      {
         aiPlanSetVariableInt(mansabdarSepoyPlan, cTrainPlanNumberToMaintain, 0, 1);
      }
   }
   else
   {
      // Update maintain plan, provided it exists
      if (mansabdarSepoyPlan >= 0)
      {
         aiPlanSetVariableInt(mansabdarSepoyPlan, cTrainPlanNumberToMaintain, 0, 0);
      }
   }
   // Check number of gurkhas, maintain mansabdar gurkha as long as there are at least 10
   numGurkhas = kbUnitCount(cMyID, cUnitTypeypNatMercGurkha, cUnitStateAlive);
   if (numGurkhas >= 10)
   {
      // Create/update maintain plan
      if (mansabdarGurkhaPlan < 0)
      {
         mansabdarGurkhaPlan = createSimpleMaintainPlan(cUnitTypeypNatMercGurkhaJemadar, 1, false, kbBaseGetMainID(cMyID), 1);
      }
      else
      {
         aiPlanSetVariableInt(mansabdarGurkhaPlan, cTrainPlanNumberToMaintain, 0, 1);
      }
   }
   else
   {
      // Update maintain plan, provided it exists
      if (mansabdarGurkhaPlan >= 0)
      {
         aiPlanSetVariableInt(mansabdarGurkhaPlan, cTrainPlanNumberToMaintain, 0, 0);
      }
   }
   // Check number of sowars, maintain mansabdar sowar as long as there are at least 7
   numSowars = kbUnitCount(cMyID, cUnitTypeypSowar, cUnitStateAlive);
   if (numSowars >= 7)
   {
      // Create/update maintain plan
      if (mansabdarSowarPlan < 0)
      {
         mansabdarSowarPlan = createSimpleMaintainPlan(cUnitTypeypSowarMansabdar, 1, false, kbBaseGetMainID(cMyID), 1);
      }
      else
      {
         aiPlanSetVariableInt(mansabdarSowarPlan, cTrainPlanNumberToMaintain, 0, 1);
      }
   }
   else
   {
      // Update maintain plan, provided it exists
      if (mansabdarSowarPlan >= 0)
      {
         aiPlanSetVariableInt(mansabdarSowarPlan, cTrainPlanNumberToMaintain, 0, 0);
      }
   }
   // Check number of zamburaks, maintain mansabdar zamburak as long as there are at least 10
   numZamburaks = kbUnitCount(cMyID, cUnitTypeypZamburak, cUnitStateAlive);
   if (numZamburaks >= 10)
   {
      // Create/update maintain plan
      if (mansabdarZamburakPlan < 0)
      {
         mansabdarZamburakPlan = createSimpleMaintainPlan(cUnitTypeypZamburakMansabdar, 1, false, kbBaseGetMainID(cMyID), 1);
      }
      else
      {
         aiPlanSetVariableInt(mansabdarZamburakPlan, cTrainPlanNumberToMaintain, 0, 1);
      }
   }
   else
   {
      // Update maintain plan, provided it exists
      if (mansabdarZamburakPlan >= 0)
      {
         aiPlanSetVariableInt(mansabdarZamburakPlan, cTrainPlanNumberToMaintain, 0, 0);
      }
   }
   // Check number of flail elephants, maintain mansabdar flail elephant as long as there are at least 6
   numFlailElephants = kbUnitCount(cMyID, cUnitTypeypMercFlailiphant, cUnitStateAlive);
   if (numFlailElephants >= 6)
   {
      // Create/update maintain plan
      if (mansabdarFlailElephantPlan < 0)
      {
         mansabdarFlailElephantPlan = createSimpleMaintainPlan(
             cUnitTypeypMercFlailiphantMansabdar, 1, false, kbBaseGetMainID(cMyID), 1);
      }
      else
      {
         aiPlanSetVariableInt(mansabdarFlailElephantPlan, cTrainPlanNumberToMaintain, 0, 1);
      }
   }
   else
   {
      // Update maintain plan, provided it exists
      if (mansabdarFlailElephantPlan >= 0)
      {
         aiPlanSetVariableInt(mansabdarFlailElephantPlan, cTrainPlanNumberToMaintain, 0, 0);
      }
   }
   // Check number of mahouts, maintain mansabdar mahout as long as there are at least 3
   numMahouts = kbUnitCount(cMyID, cUnitTypeypMahout, cUnitStateAlive);
   if (numMahouts >= 3)
   {
      // Create/update maintain plan
      if (mansabdarMahoutPlan < 0)
      {
         mansabdarMahoutPlan = createSimpleMaintainPlan(cUnitTypeypMahoutMansabdar, 1, false, kbBaseGetMainID(cMyID), 1);
      }
      else
      {
         aiPlanSetVariableInt(mansabdarMahoutPlan, cTrainPlanNumberToMaintain, 0, 1);
      }
   }
   else
   {
      // Update maintain plan, provided it exists
      if (mansabdarMahoutPlan >= 0)
      {
         aiPlanSetVariableInt(mansabdarMahoutPlan, cTrainPlanNumberToMaintain, 0, 0);
      }
   }
   // Check number of howdahs, maintain mansabdar howdah as long as there are at least 3
   numHowdahs = kbUnitCount(cMyID, cUnitTypeypHowdah, cUnitStateAlive);
   if (numHowdahs >= 3)
   {
      // Create/update maintain plan
      if (mansabdarHowdahPlan < 0)
      {
         mansabdarHowdahPlan = createSimpleMaintainPlan(cUnitTypeypHowdahMansabdar, 1, false, kbBaseGetMainID(cMyID), 1);
      }
      else
      {
         aiPlanSetVariableInt(mansabdarHowdahPlan, cTrainPlanNumberToMaintain, 0, 1);
      }
   }
   else
   {
      // Update maintain plan, provided it exists
      if (mansabdarHowdahPlan >= 0)
      {
         aiPlanSetVariableInt(mansabdarHowdahPlan, cTrainPlanNumberToMaintain, 0, 0);
      }
   }
   // Check number of siege elephants, maintain mansabdar siege elephant as long as there are at least 3
   numSiegeElephants = kbUnitCount(cMyID, cUnitTypeypSiegeElephant, cUnitStateAlive);
   if (numSiegeElephants >= 3)
   {
      // Create/update maintain plan
      if (mansabdarSiegeElephantPlan < 0)
      {
         mansabdarSiegeElephantPlan = createSimpleMaintainPlan(
             cUnitTypeypSiegeElephantMansabdar, 1, false, kbBaseGetMainID(cMyID), 1);
      }
      else
      {
         aiPlanSetVariableInt(mansabdarSiegeElephantPlan, cTrainPlanNumberToMaintain, 0, 1);
      }
   }
   else
   {
      // Update maintain plan, provided it exists
      if (mansabdarSiegeElephantPlan >= 0)
      {
         aiPlanSetVariableInt(mansabdarSiegeElephantPlan, cTrainPlanNumberToMaintain, 0, 0);
      }
   }
}

rule daimyoMonitor
inactive
minInterval 30
{
   static int daimyo1Plan = -1;
   static int daimyo2Plan = -1;
   static int daimyo3Plan = -1;
   static int shogunPlan = -1;

   int theShogunateID = getUnit(gTheShogunatePUID);
   // Check for The Shogunate, if we don't find one we've lost it and we can disable this Rule.
   if (theShogunateID < 0)
   {
      aiPlanDestroy(daimyo1Plan);
      aiPlanDestroy(daimyo2Plan);
      aiPlanDestroy(daimyo3Plan);
      aiPlanDestroy(shogunPlan);
      xsDisableSelf();
      return;
   }
   
   int mainBaseID = kbBaseGetMainID(cMyID);
   int numberToMaintain = 0;

   if ((daimyo1Plan < 0) && (kbTechGetStatus(cTechYPHCShipDaimyoAizu) == cTechStatusActive))
   {
      daimyo1Plan = createSimpleMaintainPlan(cUnitTypeypDaimyoKiyomasa, 1, false, mainBaseID, 1);
   }
   if (daimyo2Plan < 0)
   {
      daimyo2Plan = createSimpleMaintainPlan(cUnitTypeypDaimyoMasamune, 1, false, mainBaseID, 1);
   }
   if ((daimyo3Plan < 0) && (kbTechGetStatus(cTechYPHCShipDaimyoSatsuma) == cTechStatusActive))
   {
      daimyo3Plan = createSimpleMaintainPlan(cUnitTypeypDaimyoMototada, 1, false, mainBaseID, 1);
   }
   if ((shogunPlan < 0) && (kbTechGetStatus(cTechYPHCShipShogunate) == cTechStatusActive))
   {
      shogunPlan = createSimpleMaintainPlan(cUnitTypeypShogunTokugawa, 1, false, mainBaseID, 1);
   }

   if (aiGetMilitaryPop() >= 15)
   {
      numberToMaintain = 1;
   }

   // 1 Daimyo and 1 Shogun.
   if (daimyo1Plan >= 0)
   {
      aiPlanSetVariableInt(daimyo1Plan, cTrainPlanNumberToMaintain, 0, numberToMaintain);
   }
   if (daimyo2Plan >= 0)
   {
      if (daimyo1Plan < 0)
      {
         aiPlanSetVariableInt(daimyo2Plan, cTrainPlanNumberToMaintain, 0, numberToMaintain);
      }
      else
      {
         aiPlanSetVariableInt(daimyo2Plan, cTrainPlanNumberToMaintain, 0, 0);
      }
   }
   if (daimyo3Plan >= 0)
   {
      if ((daimyo1Plan < 0) && (daimyo2Plan < 0))
      {
         aiPlanSetVariableInt(daimyo3Plan, cTrainPlanNumberToMaintain, 0, numberToMaintain);
      }
      else
      {
         aiPlanSetVariableInt(daimyo3Plan, cTrainPlanNumberToMaintain, 0, 0);
      }
   }

   if (shogunPlan >= 0)
   {
      aiPlanSetVariableInt(shogunPlan, cTrainPlanNumberToMaintain, 0, numberToMaintain);
   }
}

//==============================================================================
/* Influence Manager
//
// Train units and research techs with influence resource.
*/
//==============================================================================
rule influenceManager
inactive
minInterval 45
{
   // Maintain plans
   static int influenceUPID = -1;
   static int influenceMaintainPlans = -1;

   if (kbGetAge() >= cAge3 && kbTechGetStatus(cTechDEImportedCannons) == cTechStatusObtainable)
   {
      if (aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechDEImportedCannons) >= 0)
         return;
      createSimpleResearchPlan(cTechDEImportedCannons, cUnitTypedePalace, cEconomyEscrowID, 50);
      return;
   }

   if (influenceUPID < 0)
   {
      // Create it.
      influenceUPID = kbUnitPickCreate("Influence military units");
      if (influenceUPID < 0)
         return;

      influenceMaintainPlans = xsArrayCreateInt(3, -1, "Influence maintain plans");
   }

   int numberResults = 0;
   int i = 0;
   int trainUnitID = -1;
   int planID = -1;
   int numberToMaintain = 0;
   int popCount = 0;
   int buildLimit = 0;
   float totalFactor = 0.0;
   float unitCost = 0.0;

   // Default init.
   kbUnitPickResetAll(influenceUPID);

   // Desired number units types, buildings.
   kbUnitPickSetDesiredNumberUnitTypes(influenceUPID, 2, 1, true);

   setUnitPickerCommon(influenceUPID);

   kbUnitPickSetMinimumCounterModePop(influenceUPID, 15);
   kbUnitPickSetPreferenceFactor(influenceUPID, cUnitTypeMercenary, 1.0);
   kbUnitPickSetPreferenceFactor(influenceUPID, cUnitTypeAbstractNativeWarrior, 1.0);
   kbUnitPickSetPreferenceFactor(influenceUPID, cUnitTypedeMaigadi, 1.0);
   kbUnitPickSetPreferenceFactor(influenceUPID, cUnitTypedeSebastopolMortar, 1.0);
   kbUnitPickSetPreferenceFactor(influenceUPID, cUnitTypeFalconet, 1.0);
   kbUnitPickSetPreferenceFactor(influenceUPID, cUnitTypeOrganGun, 1.0);
   kbUnitPickSetPreferenceFactor(influenceUPID, cUnitTypeCulverin, 1.0);
   kbUnitPickSetPreferenceFactor(influenceUPID, cUnitTypeMortar, 1.0);
   kbUnitPickSetPreferenceFactor(influenceUPID, cUnitTypeypMahout, 1.0);
   kbUnitPickSetPreferenceFactor(influenceUPID, cUnitTypeypHowdah, 1.0);
   kbUnitPickRun(influenceUPID);

   for (i = 0; < 2)
      totalFactor = totalFactor + kbUnitPickGetResultFactor(influenceUPID, i);

   float influenceAmount = kbResourceGet(cResourceInfluence);

   for (i = 0; < 2)
   {
      trainUnitID = kbUnitPickGetResult(influenceUPID, i);
      planID = xsArrayGetInt(influenceMaintainPlans, i);

      if (planID >= 0)
      {
         if (trainUnitID != aiPlanGetVariableInt(planID, cTrainPlanUnitType, 0))
         {
            aiPlanDestroy(planID);
            planID = -1;
         }
      }
      if (trainUnitID < 0)
         continue;

      // if we do not have enough influence for this unit, don't plan training anymore.
      if (influenceAmount > 0.0)
      {
         popCount = kbGetProtoUnitPopCount(trainUnitID);
         unitCost = kbUnitCostPerResource(trainUnitID, cResourceInfluence);
         // hardcoded to at most half of our military pop.
         if (popCount > 0)
         {
            numberToMaintain = 0.5 * (kbUnitPickGetResultFactor(influenceUPID, i) / totalFactor) * aiGetMilitaryPop() /
                               popCount;
         }
         else
         {
            numberToMaintain = 0.5 * (kbUnitPickGetResultFactor(influenceUPID, i) / totalFactor) * aiGetMilitaryPop() /
                               (unitCost * 0.01);
         }
         buildLimit = kbGetBuildLimit(cMyID, trainUnitID);
         if (buildLimit > 0 && numberToMaintain > buildLimit)
            numberToMaintain = buildLimit;
         influenceAmount = influenceAmount - ((numberToMaintain - kbUnitCount(cMyID, trainUnitID, cUnitStateABQ)) * unitCost);
      }
      else
      {
         numberToMaintain = 0;
      }

      if (planID >= 0)
      {
         aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, numberToMaintain);
      }
      else
      {
         planID = createSimpleMaintainPlan(trainUnitID, numberToMaintain, false, kbBaseGetMainID(cMyID), 1);
         aiPlanSetDesiredResourcePriority(planID, 45 - i); // below research plans
         xsArraySetInt(influenceMaintainPlans, i, planID);
      }
   }
}

/*
!!!!!THIS BLOCK COMMENT HAS ALL THE CODE BELONGING TO THE DEPRECATED MISSION/OPPORTUNITY SYSTEMS!!!!!


extern int gMostRecentAllyOpportunityID =
    -1; // Which opportunity (if any) was created by an ally?  (Only one at a time allowed.)
extern int gMostRecentTriggerOpportunityID =
    -1; // Which opportunity (if any) was created by a trigger?  (Only one at a time allowed.)

extern int gLastClaimMissionTime = -1;
extern int gClaimMissionInterval = 600000; // 10 minutes.  This variable indicates how long it takes for claim opportunities to
                                           // score their maximum. Typically, a new one will launch before this time.

//==============================================================================
   createOpportunity(type, targetType, targetID, targetPlayerID, source)

   A wrapper function for aiCreateOpportunity(), to permit centralized tracking
   of the most recently created ally-generated and trigger-generated
   opportunities.  This info is needed so that a cancel command can
   efficiently deactivate the previous (and possibly current) opportunity before
   creating the new one.

//==============================================================================
int createOpportunity(int type = -1, int targetType = -1, int targetID = -1, int targetPlayerID = -1, int source = -1)
{
   int oppID = aiCreateOpportunity(type, targetType, targetID, targetPlayerID, source);
   if (source == cOpportunitySourceAllyRequest)
      gMostRecentAllyOpportunityID = oppID; // Remember which ally opp we're doing
   else if (source == cOpportunitySourceTrigger)
      gMostRecentTriggerOpportunityID = oppID;

   return (oppID);
}

//==============================================================================
// createSimpleAttackGoal
//==============================================================================
int createSimpleAttackGoal(
    string name = "BUG", int attackPlayerID = -1, int unitPickerID = -1, int repeat = -1, int minAge = -1, int maxAge = -1,
    int baseID = -1, bool allowRetreat = false)
{
   debugMilitary("CreateSimpleAttackGoal:  Name=" + name + ", AttackPlayerID=" + attackPlayerID + ".");
   debugMilitary("  UnitPickerID=" + unitPickerID + ", Repeat=" + repeat + ", baseID=" + baseID + ".");
   debugMilitary("  MinAge=" + minAge + ", maxAge=" + maxAge + ", allowRetreat=" + allowRetreat + ".");

   // Create the goal.
   int goalID = aiPlanCreate(name, cPlanGoal);
   if (goalID < 0)
      return (-1);

   // Priority.
   aiPlanSetDesiredPriority(goalID, 90);
   // Attack player ID.
   if (attackPlayerID >= 0)
      aiPlanSetVariableInt(goalID, cGoalPlanAttackPlayerID, 0, attackPlayerID);
   else
      aiPlanSetVariableBool(goalID, cGoalPlanAutoUpdateAttackPlayerID, 0, true);
   // Base.
   if (baseID >= 0)
      aiPlanSetBaseID(goalID, baseID);
   else
      aiPlanSetVariableBool(goalID, cGoalPlanAutoUpdateBase, 0, true);
   // Attack.
   aiPlanSetAttack(goalID, true);
   aiPlanSetVariableInt(goalID, cGoalPlanGoalType, 0, cGoalPlanGoalTypeAttack);
   aiPlanSetVariableInt(goalID, cGoalPlanAttackStartFrequency, 0, 5);

   // Military.
   aiPlanSetMilitary(goalID, true);
   aiPlanSetEscrowID(goalID, cMilitaryEscrowID);
   // Ages.
   aiPlanSetVariableInt(goalID, cGoalPlanMinAge, 0, minAge);
   aiPlanSetVariableInt(goalID, cGoalPlanMaxAge, 0, maxAge);
   // Repeat.
   aiPlanSetVariableInt(goalID, cGoalPlanRepeat, 0, repeat);
   // Unit Picker.
   aiPlanSetVariableInt(goalID, cGoalPlanUnitPickerID, 0, unitPickerID);
   // Retreat.
   aiPlanSetVariableBool(goalID, cGoalPlanAllowRetreat, 0, allowRetreat);
   // Handle maps where the enemy player is usually on a diff island.
   if (gStartOnDifferentIslands == true)
   {
      aiPlanSetVariableBool(goalID, cGoalPlanSetAreaGroups, 0, true);
      aiPlanSetVariableInt(goalID, cGoalPlanAttackRoutePatternType, 0, cAttackPlanAttackRoutePatternRandom);
   }
   // Done.
   return (goalID);
}

//==============================================================================
// initGatherGoal()
//==============================================================================
int initGatherGoal()
{
   /* Create the gather goal, return its handle.  The gather goal stores the key data for controlling
      gatherer distribution.

   int planID = aiPlanCreate("GatherGoals", cPlanGatherGoal);

   if (planID >= 0)
   {
      // Overall percentages.
      aiPlanSetDesiredPriority(planID, 90);
      // Set the RGP weights.  Script in charge.
      aiSetResourceGathererPercentageWeight(cRGPScript, 0.5); // Portion driven by forecast
      aiSetResourceGathererPercentageWeight(cRGPCost, 0.5);   // Portion driven by exchange rates

      // Set the gather goal to reflect those settings (Gather goal values are informational only to simplify
      // debugging.) Set the gather goal to reflect those settings (Gather goal values are informational only to
      // simplify debugging.)
      aiPlanSetVariableFloat(planID, cGatherGoalPlanScriptRPGPct, 0, 1.0);
      aiPlanSetVariableFloat(planID, cGatherGoalPlanCostRPGPct, 0, 1.0);

      aiPlanSetNumberVariableValues(planID, cGatherGoalPlanGathererPct, cNumResourceTypes, true);
      // Set initial gatherer assignments.
      aiPlanSetVariableFloat(planID, cGatherGoalPlanGathererPct, cResourceGold, 0.0);
      aiPlanSetVariableFloat(planID, cGatherGoalPlanGathererPct, cResourceWood, 0.2);
      aiPlanSetVariableFloat(planID, cGatherGoalPlanGathererPct, cResourceFood, 0.8);
      /*
            if (cMyCiv == cCivFrench)
            {
               aiPlanSetVariableFloat(planID, cGatherGoalPlanGathererPct, cResourceWood, 0.6);
               aiPlanSetVariableFloat(planID, cGatherGoalPlanGathererPct, cResourceFood, 0.4);
            }

      // Standard resource breakdown setup, all easy at the start.
      aiPlanSetNumberVariableValues(planID, cGatherGoalPlanNumFoodPlans, 5, true);
      if ((cMyCiv != cCivJapanese) && (cMyCiv != cCivSPCJapanese) && (cMyCiv != cCivSPCJapaneseEnemy))
      {
         aiPlanSetVariableInt(planID, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeHunt, 1);
      }
      else
      {
         aiPlanSetVariableInt(planID, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeEasy, 1);
      }
      aiPlanSetVariableInt(planID, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeHerdable, 0);
      aiPlanSetVariableInt(planID, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeHunt, 0);
      aiPlanSetVariableInt(planID, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeHuntAggressive, 0);
      aiPlanSetVariableInt(planID, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeFarm, 0);
      aiPlanSetVariableInt(planID, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeFish, 0);
      aiPlanSetVariableInt(planID, cGatherGoalPlanNumWoodPlans, cAIResourceSubTypeEasy, 1);
      aiPlanSetVariableInt(planID, cGatherGoalPlanNumGoldPlans, cAIResourceSubTypeEasy, 1);

      // Cost weights...set the convenience copies in the gather goal first, then the real ones next.
      aiPlanSetNumberVariableValues(planID, cGatherGoalPlanResourceCostWeight, cNumResourceTypes, true);
      aiPlanSetVariableFloat(planID, cGatherGoalPlanResourceCostWeight, cResourceGold, 1.0); // Gold is the standard
      aiPlanSetVariableFloat(
          planID,
          cGatherGoalPlanResourceCostWeight,
          cResourceWood,
          1.2); // Start at 1.2, since wood is harder to collect
      aiPlanSetVariableFloat(planID, cGatherGoalPlanResourceCostWeight, cResourceFood,
                             1.0); // Premium for food, or 1.0?

      // Setup AI Cost weights.  This makes it actually work, the calls above just set the convenience copy in the
      // gather goal.
      kbSetAICostWeight(cResourceFood, aiPlanGetVariableFloat(planID, cGatherGoalPlanResourceCostWeight, cResourceFood));
      kbSetAICostWeight(cResourceWood, aiPlanGetVariableFloat(planID, cGatherGoalPlanResourceCostWeight, cResourceWood));
      kbSetAICostWeight(cResourceGold, aiPlanGetVariableFloat(planID, cGatherGoalPlanResourceCostWeight, cResourceGold));

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
      int numFoodEasyPlans = aiPlanGetVariableInt(planID, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeEasy);
      int numFoodHuntPlans = aiPlanGetVariableInt(planID, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeHunt);
      int numFoodHerdablePlans = aiPlanGetVariableInt(planID, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeHerdable);
      int numFoodHuntAggressivePlans = aiPlanGetVariableInt(
          planID, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeHuntAggressive);
      int numFishPlans = aiPlanGetVariableInt(planID, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeFish);
      int numFarmPlans = aiPlanGetVariableInt(planID, cGatherGoalPlanNumFoodPlans, cAIResourceSubTypeFarm);
      int numWoodPlans = aiPlanGetVariableInt(planID, cGatherGoalPlanNumWoodPlans, cAIResourceSubTypeEasy);
      int numGoldPlans = aiPlanGetVariableInt(planID, cGatherGoalPlanNumGoldPlans, cAIResourceSubTypeEasy);

      if ((kbBaseGetMainID(cMyID) >= 0)) // Don't bother if we don't have a main base
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
                   kbBaseGetMainID(cMyID)); // All on easy hunting food at start
               aiSetResourceBreakdown(
                   cResourceFood,
                   cAIResourceSubTypeHunt,
                   numFoodHuntPlans,
                   49,
                   1.0,
                   kbBaseGetMainID(cMyID)); // All on easy hunting food at start
            }
            else
            {
               aiSetResourceBreakdown(
                   cResourceFood,
                   cAIResourceSubTypeEasy,
                   numFoodEasyPlans,
                   49,
                   1.0,
                   kbBaseGetMainID(cMyID)); // All on easy food at start
            }
            /*if ((cMyCiv != cCivIndians) && (cMyCiv != cCivSPCIndians) && (cMyCiv != cCivJapanese) && (cMyCiv !=
            cCivSPCJapanese) && (cMyCiv != cCivSPCJapaneseEnemy))
            {
               aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeHerdable, numFoodHerdablePlans, 24, 1.0,
            kbBaseGetMainID(cMyID));
            }
            aiSetResourceBreakdown(
                cResourceFood, cAIResourceSubTypeHerdable, numFoodHerdablePlans, 24, 0.0, kbBaseGetMainID(cMyID));
            aiSetResourceBreakdown(
                cResourceFood, cAIResourceSubTypeHuntAggressive, numFoodHuntAggressivePlans, 49, 0.0, kbBaseGetMainID(cMyID));
            aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeFish, numFishPlans, 49, 0.0, kbBaseGetMainID(cMyID));
            aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeFarm, numFarmPlans, 51, 0.0, kbBaseGetMainID(cMyID));
            // if ((cMyCiv == cCivJapanese) || (cMyCiv == cCivSPCJapanese) || (cMyCiv == cCivSPCJapaneseEnemy))
            //{
            //   aiSetResourceBreakdown(cResourceFood, cAIResourceSubTypeFarm, numFarmPlans, 51, 1.0,
            //   kbBaseGetMainID(cMyID));
            //}
         }
         if (cvOkToGatherWood == true)
            aiSetResourceBreakdown(cResourceWood, cAIResourceSubTypeEasy, numWoodPlans, 50, 1.0, kbBaseGetMainID(cMyID));
         if (cvOkToGatherGold == true)
            aiSetResourceBreakdown(cResourceGold, cAIResourceSubTypeEasy, numGoldPlans, 55, 1.0, kbBaseGetMainID(cMyID));
      }
   }
   return (planID);
}

//==============================================================================
/*
   selectCaptain

   Updates the global gIAmCaptain bool.  Also sets the gCaptainPlayerNumber int.
   Algorithm is brain-dead simple.
   I am captain if I am the lowest-numbered AI player on a team with no
   human players.  Otherwise, I am not captain.


//==============================================================================
rule selectCaptain
inactive
minInterval 30
{
   int player = -1;
   bool amCaptain = false;     // Unless proven otherwise
   bool humanTeammate = false; // Set true if/when a human teammate is found
   int captainsNumber = -1;    // Set when we find a captain

   for (player = 1; < cNumberPlayers)
   {
      if (kbHasPlayerLost(player) == false)
      {
         if (kbIsPlayerAlly(player) == true)
         {
            // if this player is human, that's the captainsNumber
            if ((kbIsPlayerHuman(player) == true) && (kbHasPlayerLost(player) == false) && (humanTeammate == false))
            {
               amCaptain = false; // AI player is definitely not human
               captainsNumber = player;
               humanTeammate = true;
            }
            else
            { // This is an AI player or a human player other than the first.  If it's not me and has a lower number and
              // there's no human yet, he's captain.
               if ((kbIsPlayerHuman(player) == false) && (kbHasPlayerLost(player) == false) && (humanTeammate == false))
               {
                  if ((player <= cMyID) && (captainsNumber < 0)) // He's <= me and there's no captain yet
                  {
                     captainsNumber = player;
                     if (player == cMyID)
                        amCaptain = true; // I'm the captain...unless human player is found later.
                  }
               }
            }
         }
      }
   } // End for(player) loop.
   if ((captainsNumber != gCaptainPlayerNumber) || (gIAmCaptain != amCaptain))
   { // Something changed
      debugMilitary("***  Old captain was " + gCaptainPlayerNumber + ", new captain is " + captainsNumber);
      gCaptainPlayerNumber = captainsNumber;
      gIAmCaptain = amCaptain;
   }
}


extern int gMissionToCancel =
    -1; // Function returns # of units available, sets global var so commhandler can kill the mission if needed.
int unitCountFromCancelledMission(int oppSource = cOpportunitySourceAllyRequest)
{
   int retVal = 0; // Number of military units available
   gMissionToCancel = -1;

   if (oppSource == cOpportunitySourceTrigger)
      return (0); // DO NOT mess with scenario triggers

   int planCount = aiPlanGetNumber(cPlanMission, cPlanStateWorking, true);
   int plan = -1;
   int childPlan = -1;
   int oppID = -1;
   int pri = -1;

   debugMilitary(planCount + " missions found");
   for (i = 0; < planCount)
   {
      plan = aiPlanGetIDByIndex(cPlanMission, cPlanStateWorking, true, i);
      if (plan < 0)
         continue;
      childPlan = aiPlanGetVariableInt(plan, cMissionPlanPlanID, 0);
      oppID = aiPlanGetVariableInt(plan, cMissionPlanOpportunityID, 0);
      debugMilitary("  Examining mission " + plan);
      debugMilitary("    Child plan is " + childPlan);
      debugMilitary("    Opp ID is " + oppID);
      pri = aiGetOpportunitySourceType(oppID);
      debugMilitary("    Opp priority is " + pri + ", incoming command is " + oppSource);
      if ((pri > cOpportunitySourceAutoGenerated) &&
          (pri <= oppSource)) // This isn't an auto-generated opp, and the incoming command has sufficient rank.
      {
         debugMilitary("  This is valid to cancel.");
         gMissionToCancel = plan; // Store this so commHandler can kill it.
         debugMilitary("    Child plan has " + aiPlanGetNumberUnits(childPlan, cUnitTypeLogicalTypeLandMilitary) + " units.");
         retVal = aiPlanGetNumberUnits(childPlan, cUnitTypeLogicalTypeLandMilitary);
      }
      else
      {
         debugMilitary("Cannot cancel mission " + plan);
         retVal = 0;
      }
   }
   return (retVal);
}

//==============================================================================
//==============================================================================
//==============================================================================
//==============================================================================
//==============================================================================
// Opportunities and Missions
//==============================================================================
//==============================================================================
//==============================================================================
//==============================================================================
//==============================================================================
void missionStartHandler(int missionID = -1)
{ // Track times for mission starts, so we can tell how long its been since
   // we had a mission of a given type.
   if (missionID < 0)
      return;

   int oppID = aiPlanGetVariableInt(missionID, cMissionPlanOpportunityID, 0);
   int oppType = aiGetOpportunityType(oppID);

   aiPlanSetVariableInt(missionID, cMissionPlanStartTime, 0, xsGetTime()); // Set the start time in ms.

   switch (oppType)
   {
   case cOpportunityTypeDestroy:
   {
      gLastAttackMissionTime = xsGetTime();
      debugMilitary("-------- ATTACK MISSION ACTIVATION: Mission " + missionID + ", Opp " + oppID);
      break;
   }
   case cOpportunityTypeDefend:
   {
      gLastDefendMissionTime = xsGetTime();
      debugMilitary("-------- DEFEND MISSION ACTIVATION: Mission " + missionID + ", Opp " + oppID);
      break;
   }
   case cOpportunityTypeClaim:
   {
      gLastClaimMissionTime = xsGetTime();
      debugMilitary("-------- CLAIM MISSION ACTIVATION: Mission " + missionID + ", Opp " + oppID);
      break;
   }
   default:
   {
      debugMilitary("-------- UNKNOWN MISSION ACTIVATION: Mission " + missionID + ", Opp " + oppID);
      break;
   }
   }
}

// Handlers for mission start/end
   aiSetHandler("missionStartHandler", cXSMissionStartHandler);
   aiSetHandler("missionEndHandler", cXSMissionEndHandler);

void missionEndHandler(int missionID = -1)
{
   debugMilitary(
       "-------- MISSION TERMINATION:  Mission " + missionID + ", Opp " +
       aiGetOpportunityType(aiPlanGetVariableInt(missionID, cMissionPlanOpportunityID, 0)));
}

// Get a class rating, 0.0 to 1.0, for this type of opportunity.
// Scores zero when an opportunity of this type was just launched.
// Scores 1.0 when it has been 'gXXXMissionInterval' time since the last one.
float getClassRating(int oppType = -1, int target = -1)
{
   float retVal = 1.0;
   float timeElapsed = 0.0;
   int targetType = -1;

   switch (oppType)
   {
   case cOpportunityTypeDestroy:
   {
      timeElapsed = xsGetTime() - gLastAttackMissionTime;
      retVal = 1.0 * (timeElapsed / gAttackMissionInterval);
      break;
   }
   case cOpportunityTypeDefend:
   {
      timeElapsed = xsGetTime() - gLastDefendMissionTime;
      retVal = 1.0 * (timeElapsed / gDefendMissionInterval);
      break;
   }
   case cOpportunityTypeClaim:
   {
      timeElapsed = xsGetTime() - gLastClaimMissionTime;
      if (kbVPSiteGetType(target) == cVPTrade)
      {
         if (btBiasTrade > 0.0)
         {
            timeElapsed = timeElapsed *
                          (1.0 +
                           btBiasTrade); // Multiply by at least one, up to 2, i.e. btBiasTrade of 1.0 will double elapsed time.
         }
         else
            timeElapsed = timeElapsed /
                          ((-1.0 * btBiasTrade) + 1.0); // Divide by 1.00 up to 2.00, i.e. cut it in half if btBiasTrade = -1.0
         retVal = 1.0 * (timeElapsed / gClaimMissionInterval);
      }
      else // VPNative
      {
         if (btBiasNative > 0.0)
            timeElapsed =
                timeElapsed *
                (1.0 + btBiasNative); // Multiply by at least one, up to 2, i.e. btBiasNative of 1.0 will double elapsed time.
         else
            timeElapsed = timeElapsed / ((-1.0 * btBiasNative) +
                                         1.0); // Divide by 1.00 up to 2.00, i.e. cut it in half if btBiasNative = -1.0
         retVal = 1.0 * (timeElapsed / gClaimMissionInterval);
      }
      break;
   }
   }
   if (retVal > 1.0)
      retVal = 1.0;
   if (retVal < 0.0)
      retVal = 0.0;
   return (retVal);
}

//==============================================================================
/* getActiveMissionCount(int missionType)

   Returns the number of active missions that match the optional type.  If no types
   is given, returns the total number of missions.

//==============================================================================
/*int getActiveMissionCount(int missionType=-1)
{
   int retVal = 0;

   int missionCount = 0;
   int missionIndex = 0;
   int missionID = -1;

   for (missionIndex = 0; < aiPlanGetNumber(cPlanMission, -1, true))    // Step through all mission plans.  -1 means any
state is OK.
   {
      missionID = aiPlanGetIDByIndex(cPlanMission, -1, true, missionIndex);
      if ( (missionType == -1) || (aiPlanGetVariableInt(missionID, cMissionPlanType, 0) == missionType) )   // No type
specified, or type matches retVal = retVal + 1;
   }

   return(retVal);
}



// Calculate an approximate rating for enemy strength in/near this base.
float getBaseEnemyStrength(int baseID = -1)
{
   float retVal = 0.0;
   int owner = kbBaseGetOwner(baseID);
   static int allyBaseQuery = -1;

   if (allyBaseQuery < 0)
   {
      allyBaseQuery = kbUnitQueryCreate("Ally Base query");
      kbUnitQuerySetIgnoreKnockedOutUnits(allyBaseQuery, true);
      kbUnitQuerySetPlayerRelation(allyBaseQuery, cPlayerRelationEnemyNotGaia);
      kbUnitQuerySetState(allyBaseQuery, cUnitStateABQ);
      kbUnitQuerySetUnitType(allyBaseQuery, cUnitTypeLogicalTypeLandMilitary);
   }

   if (baseID < 0)
      return (-1.0);

   if (owner <= 0)
      return (-1.0);

   int numberFound = 0;
   int unitID = -1;
   int puid = -1;

   if (kbIsPlayerEnemy(owner) == true)
   { // Enemy base, add up military factors normally
      int baseQuery = createSimpleUnitQuery(
          cUnitTypeHasBountyValue,
          cPlayerRelationEnemyNotGaia,
          cUnitStateAlive,
          kbBaseGetLocation(cMyID, baseID),
          kbBaseGetDistance(cMyID, baseID));
      numberFound = kbUnitQueryExecute(baseQuery);
      for (i = 0; < numberFound)
      {
         unitID = kbUnitQueryGetResult(baseQuery, i);
         puid = kbUnitGetProtoUnitID(unitID);
         switch (puid)
         {
         case cUnitTypeFortFrontier:
         {
            retVal = retVal + 10.0;
            break;
         }
         case cUnitTypeTownCenter:
         {
            retVal = retVal + 3.0;
            break;
         }
         case cUnitTypeOutpost:
         {
            retVal = retVal + 3.0;
            break;
         }
         case cUnitTypeBlockhouse:
         {
            retVal = retVal + 3.0;
            break;
         }
         case cUnitTypeNoblesHut:
         {
            retVal = retVal + 5.0;
            break;
         }
         case cUnitTypeypWIAgraFort2:
         {
            retVal = retVal + 5.0;
            break;
         }
         case cUnitTypeypWIAgraFort3:
         {
            retVal = retVal + 5.0;
            break;
         }
         case cUnitTypeypWIAgraFort4:
         {
            retVal = retVal + 5.0;
            break;
         }
         case cUnitTypeypWIAgraFort5:
         {
            retVal = retVal + 5.0;
            break;
         }
         case cUnitTypeypCastle:
         {
            retVal = retVal + 4.0;
            break;
         }
         case cUnitTypeYPOutpostAsian:
         {
            retVal = retVal + 3.0;
            break;
         }
         case cUnitTypedeIncaStronghold:
         {
            retVal = retVal + 5.0;
            break;
         }
         default:
         {
            if (kbProtoUnitIsType(cMyID, puid, cUnitTypeLogicalTypeLandMilitary) == true)
               retVal = retVal + getMilitaryUnitStrength(puid);
            break;
         }
         }
      }
   }
   else
   { // Ally base, we're considering defending.  Count enemy units present
      kbUnitQuerySetUnitType(allyBaseQuery, cUnitTypeLogicalTypeLandMilitary);
      kbUnitQuerySetPosition(allyBaseQuery, kbBaseGetLocation(owner, baseID));
      kbUnitQuerySetMaximumDistance(allyBaseQuery, 50.0);
      kbUnitQueryResetResults(allyBaseQuery);
      numberFound = kbUnitQueryExecute(allyBaseQuery);
      for (i = 0; < numberFound)
      {
         unitID = kbUnitQueryGetResult(allyBaseQuery, i);
         puid = kbUnitGetProtoUnitID(unitID);
         if (kbProtoUnitIsType(cMyID, puid, cUnitTypeLogicalTypeLandMilitary) == true)
            retVal = retVal + getMilitaryUnitStrength(puid);
      }
   }
   if (retVal < 1.0)
      retVal = 1.0; // Return at least 1.
   return (retVal);
}

// Calculate an approximate strength rating for the enemy units/buildings near this point.
float getPointEnemyStrength(vector loc = cInvalidVector)
{
   float retVal = 0.0;
   static int enemyPointQuery = -1;

   if (enemyPointQuery < 0)
   {
      enemyPointQuery = kbUnitQueryCreate("Enemy Point query");
      kbUnitQuerySetIgnoreKnockedOutUnits(enemyPointQuery, true);
      kbUnitQuerySetPlayerRelation(enemyPointQuery, cPlayerRelationEnemyNotGaia);
      kbUnitQuerySetState(enemyPointQuery, cUnitStateABQ);
      kbUnitQuerySetUnitType(enemyPointQuery, cUnitTypeHasBountyValue);
   }

   kbUnitQuerySetUnitType(enemyPointQuery, cUnitTypeHasBountyValue);
   kbUnitQuerySetPosition(enemyPointQuery, loc);
   kbUnitQuerySetMaximumDistance(enemyPointQuery, 50.0);
   kbUnitQueryResetResults(enemyPointQuery);
   int numberFound = kbUnitQueryExecute(enemyPointQuery);

   for (i = 0; < numberFound)
   {
      int unitID = kbUnitQueryGetResult(enemyPointQuery, i);
      int puid = kbUnitGetProtoUnitID(unitID);
      switch (puid)
      {
      case cUnitTypeFortFrontier:
      {
         retVal = retVal + 10.0;
         break;
      }
      case cUnitTypeTownCenter:
      {
         retVal = retVal + 3.0;
         break;
      }
      case cUnitTypeOutpost:
      {
         retVal = retVal + 3.0;
         break;
      }
      case cUnitTypeBlockhouse:
      {
         retVal = retVal + 3.0;
         break;
      }
      case cUnitTypeNoblesHut:
      {
         retVal = retVal + 5.0;
         break;
      }
      case cUnitTypeypWIAgraFort2:
      {
         retVal = retVal + 5.0;
         break;
      }
      case cUnitTypeypWIAgraFort3:
      {
         retVal = retVal + 5.0;
         break;
      }
      case cUnitTypeypWIAgraFort4:
      {
         retVal = retVal + 5.0;
         break;
      }
      case cUnitTypeypWIAgraFort5:
      {
         retVal = retVal + 5.0;
         break;
      }
      case cUnitTypeypCastle:
      {
         retVal = retVal + 4.0;
         break;
      }
      case cUnitTypeYPOutpostAsian:
      {
         retVal = retVal + 3.0;
         break;
      }
      case cUnitTypedeIncaStronghold:
      {
         retVal = retVal + 5.0;
         break;
      }
      default:
      {
         if (kbProtoUnitIsType(cMyID, puid, cUnitTypeLogicalTypeLandMilitary) == true)
            retVal = retVal + getMilitaryUnitStrength(puid);
         break;
      }
      }
   }

   if (retVal < 1.0)
      retVal = 1.0; // Return at least 1.
   return (retVal);
}

// Calculate an approximate strength rating for the allied units/buildings near this point.
float getPointAllyStrength(vector loc = cInvalidVector)
{
   float retVal = 0.0;
   static int allyPointQuery = -1;

   if (allyPointQuery < 0)
   {
      allyPointQuery = kbUnitQueryCreate("Ally Point query 2");
      kbUnitQuerySetIgnoreKnockedOutUnits(allyPointQuery, true);
      kbUnitQuerySetPlayerRelation(allyPointQuery, cPlayerRelationAlly);
      kbUnitQuerySetState(allyPointQuery, cUnitStateABQ);
      kbUnitQuerySetUnitType(allyPointQuery, cUnitTypeLogicalTypeLandMilitary);
   }

   kbUnitQuerySetUnitType(allyPointQuery, cUnitTypeLogicalTypeLandMilitary);
   kbUnitQuerySetPosition(allyPointQuery, loc);
   kbUnitQuerySetMaximumDistance(allyPointQuery, 50.0);
   kbUnitQueryResetResults(allyPointQuery);
   int numberFound = kbUnitQueryExecute(allyPointQuery);

   for (i = 0; < numberFound)
   {
      int unitID = kbUnitQueryGetResult(allyPointQuery, i);
      int puid = kbUnitGetProtoUnitID(unitID);
      switch (puid)
      {
      case cUnitTypeFortFrontier:
      {
         retVal = retVal + 10.0;
         break;
      }
      case cUnitTypeTownCenter:
      {
         retVal = retVal + 3.0;
         break;
      }
      case cUnitTypeOutpost:
      {
         retVal = retVal + 3.0;
         break;
      }
      case cUnitTypeBlockhouse:
      {
         retVal = retVal + 3.0;
         break;
      }
      case cUnitTypeNoblesHut:
      {
         retVal = retVal + 5.0;
         break;
      }
      case cUnitTypeypWIAgraFort2:
      {
         retVal = retVal + 5.0;
         break;
      }
      case cUnitTypeypWIAgraFort3:
      {
         retVal = retVal + 5.0;
         break;
      }
      case cUnitTypeypWIAgraFort4:
      {
         retVal = retVal + 5.0;
         break;
      }
      case cUnitTypeypWIAgraFort5:
      {
         retVal = retVal + 5.0;
         break;
      }
      case cUnitTypeypCastle:
      {
         retVal = retVal + 4.0;
         break;
      }
      case cUnitTypeYPOutpostAsian:
      {
         retVal = retVal + 3.0;
         break;
      }
      case cUnitTypedeIncaStronghold:
      {
         retVal = retVal + 5.0;
         break;
      }
      default:
      {
         if (kbProtoUnitIsType(cMyID, puid, cUnitTypeLogicalTypeLandMilitary) == true)
            retVal = retVal + getMilitaryUnitStrength(puid);
         break;
      }
      }
   }

   if (retVal < 1.0)
      retVal = 1.0; // Return at least 1.
   return (retVal);
}

// Calculate an approximate value for this base.
float getBaseValue(int baseID = -1)
{
   float retVal = 0.0;
   int owner = kbBaseGetOwner(baseID);
   int relation = -1;

   if (baseID < 0)
      return (-1.0);

   if (owner <= 0)
      return (-1.0);

   if (kbIsPlayerAlly(owner) == true)
      relation = cPlayerRelationAlly;
   else
      relation = cPlayerRelationEnemyNotGaia;

   retVal = retVal + (200.0 * kbBaseGetNumberUnits(owner, baseID, relation, cUnitTypeLogicalTypeBuildingsNotWalls));
   retVal = retVal + (1000.0 * kbBaseGetNumberUnits(owner, baseID, relation, cUnitTypeTownCenter)); // 1000 points extra per TC
   retVal = retVal + (600.0 * kbBaseGetNumberUnits(
                                  owner,
                                  baseID,
                                  relation,
                                  cUnitTypePlantation)); // 600 points extra per plantation
   retVal = retVal + (2000.0 * kbBaseGetNumberUnits(
                                   owner,
                                   baseID,
                                   relation,
                                   cUnitTypeFortFrontier)); // 2000 points extra per fort
   retVal = retVal + (150.0 * kbBaseGetNumberUnits(
                                  owner,
                                  baseID,
                                  relation,
                                  cUnitTypeLogicalTypeLandMilitary));                           // 150 points per soldier
   retVal = retVal + (200.0 * kbBaseGetNumberUnits(owner, baseID, relation, cUnitTypeSettler)); // 200 points per settler
   retVal = retVal + (200.0 * kbBaseGetNumberUnits(owner, baseID, relation, cUnitTypeCoureur)); // 200 points per coureur
   retVal = retVal + (200.0 * kbBaseGetNumberUnits(
                                  owner,
                                  baseID,
                                  relation,
                                  cUnitTypeCoureurCree)); // 200 points per cree coureur
   retVal = retVal + (200.0 * kbBaseGetNumberUnits(
                                  owner,
                                  baseID,
                                  relation,
                                  cUnitTypeSettlerNative)); // 200 points per native settler
   retVal = retVal + (200.0 * kbBaseGetNumberUnits(
                                  owner,
                                  baseID,
                                  relation,
                                  cUnitTypeypSettlerAsian)); // 200 points per Asian settler
   retVal = retVal + (200.0 * kbBaseGetNumberUnits(
                                  owner,
                                  baseID,
                                  relation,
                                  cUnitTypeypSettlerIndian)); // 200 points per Indian settler
   retVal = retVal + (200.0 * kbBaseGetNumberUnits(
                                  owner,
                                  baseID,
                                  relation,
                                  cUnitTypeypSettlerJapanese)); // 200 points per Japanese settler
   retVal = retVal + (200.0 * kbBaseGetNumberUnits(
                                  owner,
                                  baseID,
                                  relation,
                                  cUnitTypeSettlerWagon)); // 300 points per settler wagon
   retVal = retVal + (1000.0 * kbBaseGetNumberUnits(
                                   owner,
                                   baseID,
                                   relation,
                                   cUnitTypeTradingPost));                                      // 1000 points per trading post
   retVal = retVal + (800.0 * kbBaseGetNumberUnits(owner, baseID, relation, cUnitTypeFactory)); // 800 points extra per factory
   retVal = retVal + (300.0 * kbBaseGetNumberUnits(owner, baseID, relation, cUnitTypeBank));    // 300 points extra per bank
   retVal = retVal + (200.0 * kbBaseGetNumberUnits(owner, baseID, relation, cUnitTypeMill));    // 200 points extra per mill
   retVal = retVal + (200.0 * kbBaseGetNumberUnits(owner, baseID, relation, cUnitTypeFarm));    // 200 points extra per farm
   retVal = retVal + (200.0 * kbBaseGetNumberUnits(
                                  owner,
                                  baseID,
                                  relation,
                                  cUnitTypeypRicePaddy)); // 200 points extra per rice paddy

   if (retVal < 1.0)
      retVal = 1.0; // Return at least 1.
   return (retVal);
}

// Calculate an approximate value for the playerRelation units/buildings near this point.
// I.e. if playerRelation is enemy, calculate strength of enemy units and buildings.
float getPointValue(vector loc = cInvalidVector, int relation = cPlayerRelationEnemyNotGaia)
{
   float retVal = 0.0;
   static int allyQuery = -1;
   static int enemyQuery = -1;
   int queryID = -1; // Use either enemy or ally query as needed.

   if (allyQuery < 0)
   {
      allyQuery = kbUnitQueryCreate("Ally point value query");
      kbUnitQuerySetIgnoreKnockedOutUnits(allyQuery, true);
      kbUnitQuerySetPlayerRelation(allyQuery, cPlayerRelationAlly);
      kbUnitQuerySetState(allyQuery, cUnitStateABQ);
   }

   if (enemyQuery < 0)
   {
      enemyQuery = kbUnitQueryCreate("Enemy point value query");
      kbUnitQuerySetIgnoreKnockedOutUnits(enemyQuery, true);
      kbUnitQuerySetPlayerRelation(enemyQuery, cPlayerRelationEnemyNotGaia);
      kbUnitQuerySetSeeableOnly(enemyQuery, true);
      kbUnitQuerySetState(enemyQuery, cUnitStateAlive);
   }

   if ((relation == cPlayerRelationEnemy) || (relation == cPlayerRelationEnemyNotGaia))
      queryID = enemyQuery;
   else
      queryID = allyQuery;

   kbUnitQueryResetResults(queryID);
   kbUnitQuerySetUnitType(queryID, cUnitTypeLogicalTypeBuildingsNotWalls);
   kbUnitQueryResetResults(queryID);
   retVal = 200.0 * kbUnitQueryExecute(queryID); // 200 points per building

   kbUnitQuerySetUnitType(queryID, cUnitTypeTownCenter);
   kbUnitQueryResetResults(queryID);
   retVal = retVal + 1000.0 * kbUnitQueryExecute(queryID); // Extra 1000 per TC

   kbUnitQuerySetUnitType(queryID, cUnitTypeTradingPost);
   kbUnitQueryResetResults(queryID);
   retVal = retVal + 1000.0 * kbUnitQueryExecute(queryID); // Extra 1000 per trading post

   kbUnitQuerySetUnitType(queryID, cUnitTypeFactory);
   kbUnitQueryResetResults(queryID);
   retVal = retVal + 800.0 * kbUnitQueryExecute(queryID); // Extra 800 per factory

   kbUnitQuerySetUnitType(queryID, cUnitTypePlantation);
   kbUnitQueryResetResults(queryID);
   retVal = retVal + 600.0 * kbUnitQueryExecute(queryID); // Extra 600 per plantation

   kbUnitQuerySetUnitType(queryID, cUnitTypeBank);
   kbUnitQueryResetResults(queryID);
   retVal = retVal + 300.0 * kbUnitQueryExecute(queryID); // Extra 300 per bank

   kbUnitQuerySetUnitType(queryID, cUnitTypeMill);
   kbUnitQueryResetResults(queryID);
   retVal = retVal + 200.0 * kbUnitQueryExecute(queryID); // Extra 200 per mill

   kbUnitQuerySetUnitType(queryID, cUnitTypeFarm);
   kbUnitQueryResetResults(queryID);
   retVal = retVal + 200.0 * kbUnitQueryExecute(queryID); // Extra 200 per farm

   kbUnitQuerySetUnitType(queryID, cUnitTypeypRicePaddy);
   kbUnitQueryResetResults(queryID);
   retVal = retVal + 200.0 * kbUnitQueryExecute(queryID); // Extra 200 per rice paddy

   kbUnitQuerySetUnitType(queryID, cUnitTypeSPCXPMiningCamp);
   kbUnitQueryResetResults(queryID);
   retVal = retVal + 1000.0 * kbUnitQueryExecute(queryID); // Extra 1000 per SPC mining camp for XPack scenario

   kbUnitQuerySetUnitType(queryID, cUnitTypeUnit);
   kbUnitQueryResetResults(queryID);
   retVal = retVal + 200.0 * kbUnitQueryExecute(queryID); // 200 per unit.

   if (retVal < 1.0)
      retVal = 1.0;

   return (retVal);
}

float getPlanStrength(int planID = -1)
{
   float retVal = 0.0;
   int numberUnits = aiPlanGetNumberUnits(planID);

   for (i = 0; < numberUnits)
   {
      int unitID = aiPlanGetUnitByIndex(planID, i);
      int puid = kbUnitGetProtoUnitID(unitID);
      switch (puid)
      {
      case cUnitTypeFortFrontier:
      {
         retVal = retVal + 10.0;
         break;
      }
      case cUnitTypeTownCenter:
      {
         retVal = retVal + 3.0;
         break;
      }
      case cUnitTypeOutpost:
      {
         retVal = retVal + 3.0;
         break;
      }
      case cUnitTypeBlockhouse:
      {
         retVal = retVal + 3.0;
         break;
      }
      case cUnitTypeNoblesHut:
      {
         retVal = retVal + 5.0;
         break;
      }
      case cUnitTypeypWIAgraFort2:
      {
         retVal = retVal + 5.0;
         break;
      }
      case cUnitTypeypWIAgraFort3:
      {
         retVal = retVal + 5.0;
         break;
      }
      case cUnitTypeypWIAgraFort4:
      {
         retVal = retVal + 5.0;
         break;
      }
      case cUnitTypeypWIAgraFort5:
      {
         retVal = retVal + 5.0;
         break;
      }
      case cUnitTypeypCastle:
      {
         retVal = retVal + 4.0;
         break;
      }
      case cUnitTypeYPOutpostAsian:
      {
         retVal = retVal + 3.0;
         break;
      }
      case cUnitTypedeIncaStronghold:
      {
         retVal = retVal + 5.0;
         break;
      }
      default:
      {
         if (kbProtoUnitIsType(cMyID, puid, cUnitTypeLogicalTypeLandMilitary) == true)
            retVal = retVal + getMilitaryUnitStrength(puid);
         break;
      }
      }
   }

   if (retVal < 1.0)
      retVal = 1.0; // Return at least 1.
   return (retVal);
}

float getUnitListStrength(int unitList = -1)
{
   float retVal = 0.0;
   int numberUnits = xsArrayGetSize(unitList);

   for (i = 0; < numberUnits)
   {
      int unitID = xsArrayGetInt(unitList, i);
      switch (kbUnitGetProtoUnitID(unitID))
      {
      case cUnitTypeFortFrontier:
      {
         retVal = retVal + 10.0;
         break;
      }
      case cUnitTypeTownCenter:
      {
         retVal = retVal + 3.0;
         break;
      }
      case cUnitTypeOutpost:
      {
         retVal = retVal + 3.0;
         break;
      }
      case cUnitTypeBlockhouse:
      {
         retVal = retVal + 3.0;
         break;
      }
      case cUnitTypeNoblesHut:
      {
         retVal = retVal + 5.0;
         break;
      }
      case cUnitTypeypWIAgraFort2:
      {
         retVal = retVal + 5.0;
         break;
      }
      case cUnitTypeypWIAgraFort3:
      {
         retVal = retVal + 5.0;
         break;
      }
      case cUnitTypeypWIAgraFort4:
      {
         retVal = retVal + 5.0;
         break;
      }
      case cUnitTypeypWIAgraFort5:
      {
         retVal = retVal + 5.0;
         break;
      }
      case cUnitTypeypCastle:
      {
         retVal = retVal + 4.0;
         break;
      }
      case cUnitTypeYPOutpostAsian:
      {
         retVal = retVal + 3.0;
         break;
      }
      case cUnitTypedeIncaStronghold:
      {
         retVal = retVal + 5.0;
         break;
      }
      default:
      {
         int puid = kbUnitGetProtoUnitID(unitID);
         if (kbProtoUnitIsType(cMyID, puid, cUnitTypeLogicalTypeLandMilitary) == true)
            retVal = retVal + getMilitaryUnitStrength(puid);
         break;
      }
      }
   }

   if (retVal < 1.0)
      retVal = 1.0; // Return at least 1.
   return (retVal);
}

float getUnitListValue(int unitList = -1)
{
   float retVal = 0.0;
   int numberUnits = xsArrayGetSize(unitList);

   for (i = 0; < numberUnits)
   {
      int unitID = xsArrayGetInt(unitList, i);
      switch (kbUnitGetProtoUnitID(unitID))
      {
      case cUnitTypeTownCenter:
      {
         retVal = retVal + 1200.0;
         break;
      }
      case cUnitTypeTradingPost:
      {
         retVal = retVal + 1200.0;
         break;
      }
      case cUnitTypeFactory:
      {
         retVal = retVal + 1000.0;
         break;
      }
      case cUnitTypePlantation:
      {
         retVal = retVal + 800.0;
         break;
      }
      case cUnitTypeBank:
      {
         retVal = retVal + 500.0;
         break;
      }
      case cUnitTypeMill:
      {
         retVal = retVal + 400.0;
         break;
      }
      case cUnitTypeypRicePaddy:
      {
         retVal = retVal + 400.0;
         break;
      }
      case cUnitTypeSPCXPMiningCamp:
      {
         retVal = retVal + 1200.0;
         break;
      }
      default:
      {
         if (kbUnitIsType(unitID, cUnitTypeLogicalTypeBuildingsNotWalls) == true)
            retVal = retVal + 200.0;
         else if (kbUnitIsType(unitID, cUnitTypeUnit) == true)
            retVal = retVal + 200.0;
         break;
      }
      }
   }

   return (retVal);
}

// Set the ScoreOppHandler
// aiSetHandler("scoreOpportunity", cXSScoreOppHandler);
//==============================================================================
// Called for each opportunity that needs to be scored.
//==============================================================================
void scoreOpportunity(int oppID = -1)
{
   /*

   Sets all the scoring components for the opportunity, and a final score.  The scoring
   components and their meanings are:

   int PERMISSION  What level of permission is needed to do this?
      cOpportunitySourceAutoGenerated is the lowest...go ahead and do it.
      cOpportunitySourceAllyRequest...the AI may not do it on its own, i.e. it may be against the rules for this
   difficulty. cOpportunitySourceTrigger...even ally requests are denied, as when prevented by control variables, but a
   trigger (gaia request) may do it. cOpportunitySourceTrigger+1...not allowed at all.

   float AFFORDABLE  Do I have what it takes to do this?  This includes appropriate army sizes, resources to pay for
   things (like trading posts) and required units like explorers.  0.80 indicates a neutral, good-to-go position.  1.0
   means overstock, i.e. an army of 20 would be good, and I have 35 units available.  0.5 means extreme shortfall, like
   the minimum you could possibly imagine.  0.0 means you simply can't do it, like no units at all.  Budget issues like
   amount of wood should never score below 0.5, scores below 0.5 mean deep, profound problems.

   int SOURCE  Who asked for this mission?  Uses the cOpportunitySource... constants above.

   float CLASS  How much do we want to do this type of mission?   Based on personality, how long it's been since the
   last mission of this type, etc. 0.8 is a neutral, "this is a good mission" rating.  1.0 is extremely good, I really,
   really want to do this next.  0.5 is a poor score.  0.0 means I just flat can't do it.  This class score will creep
   up over time for most classes, to make sure they get done once in a while.

   float INSTANCE  How good is this particular target?  Includes asset value (is it important to attack or defend this?)
   and distance.  Defense values are incorporated in the AFFORDABLE calculation above.  0.0 is no value, this target
   can't be attacked.  0.8 is a good solid target.  1.0 is a dream target.

   float TOTAL  Incorporates AFFORDABLE, CLASS and INSTANCE by multiplying them together, so a zero in any one sets
   total to zero.  Source is added as an int IF AND ONLY IF SOURCE >= PERMISSION.  If SOURCE < PERMISSION, the total is
   set to -1.  Otherwise, all ally source opportunities will outrank all self generated opportunities, and all
   trigger-generated opportunities will outrank both of those.  Since AFFORDABLE, CLASS and INSTANCE all aim for 0.8 as
   a good, solid par value, a total score of .5 is rougly "pretty good".  A score of 1.0 is nearly impossible and should
   be quite rare...a high-value target, weakly defended, while I have a huge army and the target is close to me and we
   haven't done one of those for a long, long time.

   Total of 0.0 is an opportunity that should not be serviced.  >0 up to 1 indicates a self-generated opportunity, with
   0.5 being decent, 1.0 a dream, and 0.2 kind of marginal.  Ally commands are in the range 1.0 to 2.0 (unless illegal),
   and triggers score 2.0 to 3.0.

   // Interim values for the scoring components:
   int permission = 0;
   float instance = 0.0;
   float classRating = 0.0;
   float total = 0.0;
   float affordable = 0.0;
   float score = 0.0;

   // Info about this opportunity
   int source = aiGetOpportunitySourceType(oppID);
   if (source < 0)
      source = cOpportunitySourceAutoGenerated;
   if (source > cOpportunitySourceTrigger)
      source = cOpportunitySourceTrigger;
   int target = aiGetOpportunityTargetID(oppID);
   int targetType = aiGetOpportunityTargetType(oppID);
   int oppType = aiGetOpportunityType(oppID);
   int targetPlayer = aiGetOpportunityTargetPlayerID(oppID);
   vector location = aiGetOpportunityLocation(oppID);
   float radius = aiGetOpportunityRadius(oppID);
   if (radius < 40.0)
      radius = 40.0;
   int baseOwner = -1;
   float baseEnemyPower = 0.0; // Used to measure troop and building strength.  Units roughly equal to unit count of army.
   float baseAllyPower = 0.0;  // Strength of allied buildings and units, roughly equal to unit count.
   float netEnemyPower = 0.0;  // Basically enemy minus ally, but the ally effect can, at most, cut 80% of enemy strength
   float baseAssets = 0.0;     // Rough estimate of base value, in aiCost.
   float affordRatio = 0.0;
   bool errorFound = false; // Set true if we can't do a good score.  Ends up setting score to -1.

   // Variables for available number of units and plan to kill if any
   float armySizeAuto = 0.0;      // For source cOpportunitySourceAutoGenerated
   float armySizeAlly = 0.0;      // For ally-generated commands, how many units could we scrounge up?
   int missionToKillAlly = -1;    // Mission to cancel in order to provide the armySizeAlly number of units.
   float armySizeTrigger = 0.0;   // For trigger-generated commands, how many units could we scrounge up?
   int missionToKillTrigger = -1; // Mission to cancel in order to provide the armySizeTrigger number of units.
   float armySize = 0.0;          // The actual army size we'll use for calcs, depending on how big the target is.
   float missionToKill = -1;      // The actual mission to kill based on the army size we've selected.

   float oppDistance = 0.0;   // Distance to target location or base.
   bool sameAreaGroup = true; // Set false if opp is on another areagroup.

   bool defendingMonopoly = false;
   bool attackingMonopoly = false;
   int tradePostID = -1; // Set to trade post ID if this is a base target, and a trade post is nearby.

   bool defendingKOTH = false;
   bool attackingKOTH = false;
   int KOTHID = -1; // Set to the hill ID if this is a base target, and the hill is nearby.

   if (gIsMonopolyRunning == true)
   {
      if (gMonopolyTeam == kbGetPlayerTeam(cMyID))
         defendingMonopoly = true; // We're defending, let's not go launching any attacks
      else
         attackingMonopoly = true; // We're attacking, focus on trade posts
   }

   if (gIsKOTHRunning == true)
   {
      if (gKOTHTeam == kbGetPlayerTeam(cMyID))
         defendingKOTH = true; // We're defending, let's not go launching any attacks
      else
         attackingKOTH = true; // We're attacking, focus on the hill
   }

   //-- get the total strength of units in our reserve.
   armySizeAuto = getPlanStrength(gLandReservePlan);
   armySizeAlly = armySizeAuto;
   armySizeTrigger = armySizeAlly;

   //   debugMilitary(" ");
   //   debugMilitary("Scoring opportunity "+oppID+", targetID "+target+", location "+location);

   // Get target info
   switch (targetType)
   {
   case cOpportunityTargetTypeBase:
   {
      location = kbBaseGetLocation(kbBaseGetOwner(target), target);
      tradePostID = getUnitByLocation(cUnitTypeTradingPost, kbBaseGetOwner(target), cUnitStateAlive, location, 40.0);
      KOTHID = getUnitByLocation(cUnitTypeypKingsHill, kbBaseGetOwner(target), cUnitStateAlive, location, 40.0);
      radius = 50.0;
      baseOwner = kbBaseGetOwner(target);
      baseEnemyPower = getBaseEnemyStrength(target); // Calculate "defenses" as enemy units present
      baseAllyPower = getPointAllyStrength(kbBaseGetLocation(kbBaseGetOwner(target), target));
      if ((baseEnemyPower * 0.8) > baseAllyPower)
         netEnemyPower = baseEnemyPower - baseAllyPower; // Ally power is less than 80% of enemy
      else
         netEnemyPower = baseEnemyPower * 0.2; // Ally power is more then 80%, but leave a token enemy rating anyway.

      baseAssets = getBaseValue(target); //  Rough value of target
      if ((gIsMonopolyRunning == true) && (tradePostID >= 0))
         baseAssets = baseAssets + 10000; // Huge bump if this is a trade post (enemy or ally) and a monopoly is running
      if ((gIsKOTHRunning == true) && (KOTHID >= 0))
         baseAssets = baseAssets + 10000; // Huge bump if this is the hill (enemy or ally) and a timer is running
      break;
   }
   case cOpportunityTargetTypePointRadius:
   {
      baseEnemyPower = getPointEnemyStrength(location);
      baseAllyPower = getPointAllyStrength(location);
      if ((baseEnemyPower * 0.8) > baseAllyPower)
         netEnemyPower = baseEnemyPower - baseAllyPower; // Ally power is less than 80% of enemy
      else
         netEnemyPower = baseEnemyPower * 0.2; // Ally power is more then 80%, but leave a token enemy rating anyway.

      baseAssets = getPointValue(location); //  Rough value of target
      break;
   }
   case cOpportunityTargetTypeVPSite: // This is only for CLAIM missions.  A VP site that is owned will be a
                                      // defend or destroy opportunity.
   {
      location = kbVPSiteGetLocation(target);
      radius = 50.0;

      baseEnemyPower = getPointEnemyStrength(location);
      baseAllyPower = getPointAllyStrength(location);
      if ((baseEnemyPower * 0.8) > baseAllyPower)
         netEnemyPower = baseEnemyPower - baseAllyPower; // Ally power is less than 80% of enemy
      else
         netEnemyPower = baseEnemyPower * 0.2; // Ally power is more then 80%, but leave a token enemy rating anyway.

      baseAssets = 1000.0; // Arbitrary...consider a claimable VP Site as worth 1000 resources.
      break;
   }
   }

   if (netEnemyPower < 1.0)
      netEnemyPower = 1.0; // Avoid div 0

   oppDistance = distance(location, kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)));
   if (oppDistance <= 0.0)
      oppDistance = 1.0;
   if (kbAreaGroupGetIDByPosition(location) != kbAreaGroupGetIDByPosition(kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID))))
      sameAreaGroup = false;

   // Figure which armySize to use.  This currently is a placeholder, we may not need to mess with it.
   armySize = armySizeAuto; // Default

   //   debugMilitary("    EnemyPower "+baseEnemyPower+", AllyPower "+baseAllyPower+", NetEnemyPower "+netEnemyPower);
   //   debugMilitary("    BaseAssets "+baseAssets+", myArmySize "+armySize);

   switch (oppType)
   {
   case cOpportunityTypeDestroy:
   {
      // Check permissions required.
      if (cvOkToAttack == false)
         permission = cOpportunitySourceTrigger; // Only triggers can make us attack.

      if (gDelayAttacks == true)
         permission = cOpportunitySourceTrigger; // Only triggers can override this difficulty setting.

      // Check affordability

      if (netEnemyPower < 0.0)
      {
         errorFound = true;
         affordable = 0.0;
      }
      else
      {
         // Set affordability.  Roughly armySize / baseEnemyPower, but broken into ranges.
         // 0.0 is no-can-do, i.e. no troops.  0.8 is "good", i.e.0 armySize is double baseEnemyPower.
         // Above a 2.0 ratio, to 5.0, scale this into the 0.8 to 1.0 range.
         // Above 5.0, score it 1.0
         affordRatio = armySize / netEnemyPower;
         if (kbGetAge() < cAge3)
         {
            if (affordRatio < 2.0)
               affordable = affordRatio / 2.5; // 0 -> 0.0,  2.0 -> 0.8
            else
               affordable = 0.8 + ((affordRatio - 2.0) / 15.0); // 1.0 -> 0.8 and 5.0 -> 1.0
         }
         else if (kbGetAge() == cAge3)
         {
            if (affordRatio < 1.5)
               affordable = affordRatio / 1.875; // 0 -> 0.0,  1.5 -> 0.8
            else
               affordable = 0.8 + ((affordRatio - 1.5) / 7.5); // 1.0 -> 0.8 and 3.0 -> 1.0
         }
         else
         {
            if (affordRatio < 1.0)
               affordable = affordRatio / 1.25; // 0 -> 0.0,  1.0 -> 0.8
            else
               affordable = 0.8 + ((affordRatio - 1.0) / 5.0); // 1.0 -> 0.8 and 2.0 -> 1.0
         }

         // Also consider other factors than military ratio
         if (affordable < 1.0)
         {
            // we maxed out our military pop
            if (armySize >= aiGetMilitaryPop() && (xsGetTime() - gLastAttackMissionTime) >= gAttackMissionInterval)
               affordable = 1.0;
         }

         // if (affordable > 1.0)
         //	affordable = 1.0;
      } // Affordability is done

      // Check target value, calculate INSTANCE score.
      if (baseAssets < 0.0)
      {
         errorFound = true;
      }
      // Clip base value to range of 100 to 10K for scoring
      if (baseAssets < 100.0)
         baseAssets = 100.0;
      if (baseAssets > 10000.0)
         baseAssets = 10000.0;
      // Start with an "instance" score of 0 to .8 for bases under 2K value.
      instance = (0.8 * baseAssets) / 2000.0;
      // Over 2000, adjust so 2K = 0.8, 30K = 1.0
      if (baseAssets > 2000.0)
         instance = 0.8 + ((0.2 * (baseAssets - 2000.0)) / 8000.0);

      // Instance is now 0..1, adjust for distance. If < 100m, leave as is.  Over 100m to 400m, penalize 10% per 100m.
      float penalty = 0.0;
      if (oppDistance > 100.0)
         penalty = (0.1 * (oppDistance - 100.0)) / 100.0;
      if (penalty > 0.6)
         penalty = 0.6;
      if ((attackingKOTH == false) || (KOTHID < 0)) // We're not trying to take the hill.
         instance = instance * (1.0 - penalty);     // Apply distance penalty, INSTANCE score is done.
      if (sameAreaGroup == false)
         instance = instance / 2.0;
      if (targetType == cOpportunityTargetTypeBase)
         if (kbHasPlayerLost(baseOwner) == true)
            instance = -1.0;
      // Illegal if it's over water, i.e. a lone dock
      if (kbAreaGetType(kbAreaGetIDByPosition(location)) == cAreaTypeWater)
         instance = -1.0;

      // Check for weak target blocks, which means the content designer is telling us that this target needs its
      // instance score bumped up
      int weakBlockCount = 0;
      int strongBlockCount = 0;
      if (targetType == cOpportunityTargetTypeBase)
      {
         weakBlockCount = getUnitCountByLocation(
             cUnitTypeAITargetBlockWeak, cMyID, cUnitStateAlive, kbBaseGetLocation(baseOwner, target), 40.0);
         strongBlockCount = getUnitCountByLocation(
             cUnitTypeAITargetBlockStrong, cMyID, cUnitStateAlive, kbBaseGetLocation(baseOwner, target), 40.0);
      }
      if ((targetType == cOpportunityTargetTypeBase) && (weakBlockCount > 0) && (instance >= 0.0))
      { // We have a valid instance score, and there is at least one weak block in the area.  For each weak block, move
        // the instance score halfway to 1.0.
         while (weakBlockCount > 0)
         {
            instance = instance + ((1.0 - instance) / 2.0); // halfway up to 1.0
            weakBlockCount--;
         }
      }

      classRating = getClassRating(cOpportunityTypeDestroy); // 0 to 1.0 depending on how long it's been.
      if ((gIsMonopolyRunning == true) && (tradePostID < 0)) // Monopoly, and this is not a trade post site
         classRating = 0.0;

      if (defendingMonopoly == true)
         classRating = 0.0; // If defending, don't attack other targets

      if ((attackingMonopoly == true) && (tradePostID >= 0)) // We're attacking, and this is an enemy trade post...go get it
         classRating = 1.0;

      if ((gIsKOTHRunning == true) && (KOTHID < 0)) // KOTH, and this is the hill
         classRating = 0.0;

      if (defendingKOTH == true)
         classRating = 0.0; // If defending, don't attack other targets

      if ((attackingKOTH == true) && (KOTHID >= 0)) // We're attacking, and this is an enemy hill...go get it
         classRating = 1.0;

      if ((gRevolutionType & cRevolutionMilitary) == cRevolutionMilitary) // We just revolted, launch an attack
         classRating = 1.0;

      if ((targetType == cOpportunityTargetTypeBase) && (strongBlockCount > 0) && (classRating >= 0.0))
      { // We have a valid instance score, and there is at least one strong block in the area.  For each weak block,
        // move the classRating score halfway to 1.0.
         while (strongBlockCount > 0)
         {
            classRating = classRating + ((1.0 - classRating) / 2.0); // halfway up to 1.0
            strongBlockCount--;
         }
      }

      if (aiTreatyActive() == true)
         classRating = 0.0; // Do not attack anything if under treaty

      if ((classRating >= 0.8) && (affordable < 0.5) && (armySize > 0.0) &&
          (((cvMaxAge > -1) && (kbGetAge() >= cvMaxAge)) || (kbGetAge() >= cAge5)))
      { // Adjust affordability if we're maxed out on army/resources or need to go for the hill.
         float totalResources = kbResourceGet(cResourceFood) + kbResourceGet(cResourceWood) + kbResourceGet(cResourceGold);
         if (((attackingKOTH == true) && (KOTHID >= 0)) || (totalResources >= 10000.0) || ((kbGetPopCap() - kbGetPop()) < 10) ||
             (armySize >= aiGetMilitaryPop()))
            if (armySize < 30.0)
               affordable = 0.5;
            else
               affordable = 0.8;
      }
      break;
   }
   case cOpportunityTypeClaim:
   {
      // Check permissions required.
      if ((cvOkToClaimTrade == false) && (kbVPSiteGetType(target) == cVPTrade))
         permission = cOpportunitySourceTrigger; // Only triggers can let us override this.
      if ((cvOkToAllyNatives == false) && (kbVPSiteGetType(target) == cVPNative))
         permission = cOpportunitySourceTrigger; // Only triggers can let us override this.
      if (gDelayAttacks == true) // Taking trade sites and natives is sort of aggressive, turn it off on easy/sandbox.
         permission = cOpportunitySourceTrigger; // Only triggers can override this difficulty setting.

      // Check affordability.  50-50 weight on military affordability and econ affordability
      float milAfford = 0.0;
      float econAfford = 0.0;
      affordRatio = armySize / netEnemyPower;
      if (kbGetAge() < cAge3)
      {
         if (affordRatio < 2.0)
            milAfford = affordRatio / 2.5; // 0 -> 0.0,  2.0 -> 0.8
         else
            milAfford = 0.8 + ((affordRatio - 2.0) / 15.0); // 1.0 -> 0.8 and 5.0 -> 1.0
      }
      else if (kbGetAge() == cAge3)
      {
         if (affordRatio < 1.5)
            milAfford = affordRatio / 1.875; // 0 -> 0.0,  1.5 -> 0.8
         else
            milAfford = 0.8 + ((affordRatio - 1.5) / 7.5); // 1.0 -> 0.8 and 3.0 -> 1.0
      }
      else
      {
         if (affordRatio < 1.0)
            milAfford = affordRatio / 1.25; // 0 -> 0.0,  1.0 -> 0.8
         else
            milAfford = 0.8 + ((affordRatio - 1.0) / 5.0); // 1.0 -> 0.8 and 2.0 -> 1.0
      }
      if (milAfford > 1.0)
         milAfford = 1.0;
      affordRatio = kbResourceGet(cResourceWood) / (1.0 + kbUnitCostPerResource(cUnitTypeTradingPost, cResourceWood));
      if (affordRatio < 1.0)
         econAfford = affordRatio;
      else
         econAfford = 1.0;
      if (econAfford > 1.0)
         econAfford = 1.0;
      if (econAfford < 0.0)
         econAfford = 0.0;
      affordable = (econAfford + milAfford) / 2.0; // Simple average

      // Instance
      instance = 0.8; // Same for all, unless I prefer to do one type over other (personality)
      penalty = 0.0;
      if (oppDistance > 100.0)
         penalty = (0.1 * (oppDistance - 100.0)) / 100.0;
      if (penalty > 0.6)
         penalty = 0.6;
      instance = instance * (1.0 - penalty); // Apply distance penalty, INSTANCE score is done.
      if (sameAreaGroup == false)
         instance = instance / 2.0;
      classRating = getClassRating(cOpportunityTypeClaim, target); // 0 to 1.0 depending on how long it's been.
      break;
   }
   case cOpportunityTypeRaid:
   {
      break;
   }
   case cOpportunityTypeDefend:
   {

      // Check affordability

      if (netEnemyPower < 0.0)
      {
         errorFound = true;
         affordable = 0.0;
      }
      else
      {
         // Set affordability.  Roughly armySize / netEnemyPower, but broken into ranges.
         // Very different than attack calculations.  Score high affordability if the ally is really
         // in trouble, especially if my army is large.  Basically...does he need help?  Can I help?
         if (baseAllyPower < 1.0)
            baseAllyPower = 1.0;
         float enemyRatio = baseEnemyPower / baseAllyPower;
         float enemySurplus = baseEnemyPower - baseAllyPower;
         if (enemyRatio < 0.5) // Enemy very weak, not a good opp.
         {
            affordRatio = enemyRatio; // Low score, 0 to .5
            if (enemyRatio < 0.2)
               affordRatio = 0.0;
         }
         else
            affordRatio = 0.5 + ((enemyRatio - 0.5) / 5.0); // ratio 0.5 scores 0.5, ratio 3.0 scores 1.0
         if ((affordRatio * 10.0) > enemySurplus)
            affordRatio = enemySurplus / 10.0; // Cap the afford ratio at 1/10 the enemy surplus, i.e. don't respond if
                                               // he's just outnumbered 6:5 or something trivial.
         if (enemySurplus < 0)
            affordRatio = 0.0;
         if (affordRatio > 1.0)
            affordRatio = 1.0;
         // AffordRatio now represents how badly I'm needed...now, can I make a difference
         if (armySize < enemySurplus)                              // I'm gonna get my butt handed to me
            affordRatio = affordRatio * (armySize / enemySurplus); // If I'm outnumbered 3:1, divide by 3.
         // otherwise, leave it alone.

         affordable = affordRatio;
      } // Affordability is done

      // Check target value, calculate INSTANCE score.
      if (baseAssets < 0.0)
      {
         errorFound = true;
      }
      // Clip base value to range of 100 to 30K for scoring
      if (baseAssets < 100.0)
         baseAssets = 100.0;
      if (baseAssets > 30000.0)
         baseAssets = 30000.0;
      // Start with an "instance" score of 0 to .8 for bases under 2K value.
      instance = (0.8 * baseAssets) / 1000.0;
      // Over 1000, adjust so 1K = 0.8, 30K = 1.0
      if (baseAssets > 1000.0)
         instance = 0.8 + ((0.2 * (baseAssets - 1000.0)) / 29000.0);

      // Instance is now 0..1, adjust for distance. If < 200m, leave as is.  Over 200m to 400m, penalize 10% per 100m.
      penalty = 0.0;
      if (oppDistance > 200.0)
         penalty = (0.1 * (oppDistance - 200.0)) / 100.0;
      if (penalty > 0.6)
         penalty = 0.6;
      instance = instance * (1.0 - penalty); // Apply distance penalty, INSTANCE score is done.
      if (sameAreaGroup == false)
         instance = 0.0;
      if (targetType == cOpportunityTargetTypeBase)
         if (kbHasPlayerLost(baseOwner) == true)
            instance = -1.0;

      if ((defendingMonopoly == true) && (tradePostID >= 0) && (instance > 0.0))
         instance = instance +
                    ((1.0 - instance) / 1.2); // Bump it almost up to 1.0 if we're defending monopoly and this is a trade site.
      if ((defendingKOTH == true) && (KOTHID >= 0) && (instance > 0.0))
         instance = instance + ((1.0 - instance) / 1.2);    // Bump it almost up to 1.0 if we're defending the hill
      classRating = getClassRating(cOpportunityTypeDefend); // 0 to 1.0 depending on how long it's been.
      if ((defendingMonopoly == true) && (tradePostID >= 0))
         classRating = 1.0; // No time delay for 2nd defend mission if we're defending trading posts during monopoly.
      if (attackingMonopoly == true)
         classRating = 0.0; // Don't defend anything if we should be attacking a monopoly!
      if ((defendingKOTH == true) && (KOTHID >= 0))
         classRating = 1.0; // No time delay for 2nd defend mission if we're defending the hill.
      if (attackingKOTH == true)
         classRating = 0.0; // Don't defend anything if we should be attacking the hill!
      break;
   }
   case cOpportunityTypeRescueExplorer
   {
      break;
   }
   default:
   {
      debugMilitary("ERROR ERROR ERROR ERROR");
      debugMilitary("scoreOpportunity() failed on opportunity " + oppID);
      debugMilitary("Opportunity Type is " + oppType + " (invalid)");
      break;
   }
   }

   score = classRating * instance * affordable;
   //   debugMilitary("    Class "+classRating+", Instance "+instance+", affordable "+affordable);
   //   debugMilitary("    Final Score: "+score);

   if (score > 1.0)
      score = 1.0;
   if (score < 0.0)
      score = 0.0;

   score = score + source; // Add 1 if from ally, 2 if from trigger.

   if (permission > source)
      score = -1.0;
   if (errorFound == true)
      score = -1.0;
   if (cvOkToSelectMissions == false)
      score = -1.0;
   aiSetOpportunityScore(oppID, permission, affordable, classRating, instance, score);
}

If we ever put back the Dojos for the AI the rule below should be completely remade.

rule dojoTacticMonitor
inactive
minInterval 10
{
   int randomizer = -1;
   static int dojoTactic1 = -1;
   static int dojoTactic2 = -1;

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
         aiUnitSetTactic(kbUnitQueryGetResult(dojoQueryID, 0), dojoTactic1);
      }
      else if (numberFound == 2)
      {
         aiUnitSetTactic(kbUnitQueryGetResult(dojoQueryID, 0), dojoTactic1);
         aiUnitSetTactic(kbUnitQueryGetResult(dojoQueryID, 1), dojoTactic2);
         xsDisableSelf();
      }
   }
}
*/