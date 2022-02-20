//==============================================================================
/* aiBuildings.xs

   This file is intended for any base building logic, including choosing
   appropriate builders(wagons) for construction.

*/
//==============================================================================

//==============================================================================
/* House monitor
   Build extra houses if we need them.
*/
//==============================================================================
rule houseMonitor
inactive
minInterval 3
{
   if (needMoreHouses() == false)
   {
      return;
   }
   
   int buildPlanID = -1;
   
   if ((cMyCiv != cCivChinese) && (cMyCiv != cCivSPCChinese))
   {
      if (kbGetBuildLimit(cMyID, gHouseUnit) <= kbUnitCount(cMyID, gHouseUnit, cUnitStateABQ) + 
            aiPlanGetNumberByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, gHouseUnit, true))
      {
         return; // We're at our limit we can't build more.
      }
   
      buildPlanID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, gHouseUnit);
   
      if (buildPlanID < 0)
      {                                                         
         buildPlanID = createSimpleBuildPlan(gHouseUnit, 1, 95, true, cEconomyEscrowID, kbBaseGetMainID(cMyID), 1);
         aiPlanSetDesiredResourcePriority(buildPlanID, 65);
      }
   }
   else // We're Chinese and we must get some population upgrades which become the best choice after we have 4 Villages.
   {
      int villageCount = kbUnitCount(cMyID, cUnitTypeypVillage, cUnitStateAlive);
      int upgradePlanID = -1;
      buildPlanID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, gHouseUnit);
   
      if (villageCount < 4)
      {
         if (buildPlanID < 0)
         {                                                         
            buildPlanID = createSimpleBuildPlan(gHouseUnit, 1, 95, true, cEconomyEscrowID, kbBaseGetMainID(cMyID), 1);
            aiPlanSetDesiredResourcePriority(buildPlanID, 65);
         }
      }
      else if (((researchSimpleTech(cTechypVillagePopCapIncrease, cUnitTypeypVillage, -1, 65) == true) &&
                (researchSimpleTech(cTechypVillagePopCapIncrease2, cUnitTypeypVillage, -1, 65) == true) &&
                (researchSimpleTech(cTechypVillagePopCapIncrease3, cUnitTypeypVillage, -1, 65) == true) &&
                (researchSimpleTech(cTechypVillagePopCapIncrease4, cUnitTypeypVillage, -1, 65) == true)) == false)
      {
         return;
      }
      else // We have 4 or more Villages.
      {
         if (kbGetBuildLimit(cMyID, gHouseUnit) <= kbUnitCount(cMyID, gHouseUnit, cUnitStateABQ) + 
            aiPlanGetNumberByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, gHouseUnit, true))
         {
            return; // We're at our limit so we can't build more.
         }
         if (buildPlanID < 0)
         {                                                         
            buildPlanID = createSimpleBuildPlan(gHouseUnit, 1, 95, true, cEconomyEscrowID, kbBaseGetMainID(cMyID), 1);
            aiPlanSetDesiredResourcePriority(buildPlanID, 65);
         }
      }
   }
}

//==============================================================================
/* extraHouseMonitor
   Swedish / Inca - build more Torps / Kancha Houses to gain extra resource income.
   British - build more Manors to spawn a Villager for each Manor built.
   Chinese - build more Villages to spawn more Villagers with Northern Refugees card.
*/
//==============================================================================
rule extraHouseMonitor
inactive
minInterval 3
{
   if ((agingUp() == true) || (kbGetAge() > cAge1))
   {
      xsDisableSelf();
      return;
   }
   
   if (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeTradingPost) >= 0)
   {
      return; // Maybe our Trading Post build plan will fail because somebody else will take the socket so don't disable.
   }
   
   int houseBuildPlanID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, gHouseUnit);

   if ((houseBuildPlanID < 0) &&
       (kbCanAffordUnit(gHouseUnit, cEconomyEscrowID) == true))// We don't want to disturb our economy for these
   {                                                           // so only built them when we have enough resources.
      houseBuildPlanID = createSimpleBuildPlan(gHouseUnit, 1, 95, true, cEconomyEscrowID, kbBaseGetMainID(cMyID), 1);
      aiPlanSetDesiredResourcePriority(houseBuildPlanID, 65);
   }
}

//==============================================================================
// buildingPlacementFailedHandler()
//==============================================================================
void buildingPlacementFailedHandler(int baseID = -1, int puid = -1)
{
   if (puid == gDockUnit)
      return;
   if (puid == cUnitTypedeTorp && cMyCiv == cCivDESwedish)
   {
      int last = xsArrayGetSize(gTorpPositionsToAvoid);
      xsArrayResizeVector(gTorpPositionsToAvoid, last + 1);
      xsArraySetVector(gTorpPositionsToAvoid, last - 1, gTorpPosition);
      houseMonitor();
      return;
   }
   if (puid == cUnitTypedeField)
   {
      int numberFullGranaries = xsArrayGetSize(gFullGranaries);
      for (i = 0; < numberFullGranaries)
      {
         int granaryID = xsArrayGetInt(gFullGranaries, i);
         if (granaryID == gFieldGranaryID)
            break;
         if (granaryID >= 0 && kbUnitGetPlayerID(granaryID) == cMyID)
            continue;
         xsArraySetInt(gFullGranaries, i, gFieldGranaryID);
         break;
      }
   }
   if (baseID < 0)
   {
      // assuming main base
      baseID = kbBaseGetMainID(cMyID);
   }

   static int basesToAvoid = -1;
   static int lastExpansionTime = 0;
   bool expand = true;

   if (basesToAvoid < 0)
      basesToAvoid = xsArrayCreateInt(5, -1, "Bases to avoid expanding");

   for (i = 0; < 5)
   {
      if (xsArrayGetInt(basesToAvoid, i) == baseID)
      {
         expand = false;
         break;
      }
   }

   float newDistance = 0.0;
   if (expand == true)
   {
      vector baseLocation = kbBaseGetLocation(cMyID, baseID);
      int baseAreaGroup = kbAreaGroupGetIDByPosition(baseLocation);
      int numberAreas = kbAreaGetNumber();
      newDistance = kbBaseGetDistance(cMyID, baseID) + 10.0;
      // make sure new areas we cover are in the same area group
      for (i = 0; < numberAreas)
      {
         vector location = kbAreaGetCenter(i);
         if (distance(location, baseLocation) > newDistance)
            continue;
         if (kbAreaGroupGetIDByPosition(location) == baseAreaGroup)
            continue;
         for (j = 0; < 5)
         {
            if (xsArrayGetInt(basesToAvoid, j) == -1)
            {
               xsArraySetInt(basesToAvoid, baseID);
               break;
            }
         }
         expand = false;
         break;
      }
   }

   if (expand == false)
   {
      /*if (xsIsRuleEnabled("findNewBase") == false)
      {
         xsEnableRule("findNewBase");
         debugBuildings("Started searching for a new base location because of not enough build space.");
      }
      int mainBaseID = kbBaseGetMainID(cMyID);
      if (baseID == mainBaseID && kbBaseGetSettlement(cMyID, baseID) == true)
      {
         // find a new base to set as main
         int numberBases = kbBaseGetNumber(cMyID);
         for (i = 0; < numberBases)
         {
             int newBaseID = kbBaseGetIDByIndex(cMyID, i);
             if (newBaseID == mainBaseID)
                continue;
             if (kbBaseGetSettlement(cMyID, newBaseID) == false)
                continue;
             kbBaseSetMain(cMyID, newBaseID, true);
             kbBaseSetMain(cMyID, mainBaseID, false);
             debugBuildings("Setting base "+newBaseID+" to main.");
             break;
         }
      }*/
      return;
   }

   int time = xsGetTime();
   if ((time - lastExpansionTime) > 1 * 60 * 1000)
   {
      debugBuildings("Expanding base " + baseID + " to " + newDistance);
      kbBaseSetPositionAndDistance(cMyID, baseID, baseLocation, newDistance);
      lastExpansionTime = time;
   }
}

//==============================================================================
// selectClosestBuildPlanPosition
//
// Find the closest location to the unit to build.
//==============================================================================
void selectClosestBuildPlanPosition(int planID = -1, int baseID = -1)
{
   aiPlanSetVariableBool(planID, cBuildPlanInfluenceAtBuilderPosition, 0, true);
   aiPlanSetVariableFloat(planID, cBuildPlanInfluenceBuilderPositionValue, 0, 100.0);    // 100m range.
   aiPlanSetVariableFloat(planID, cBuildPlanInfluenceBuilderPositionDistance, 0, 200.0); // 200 points max
   aiPlanSetVariableInt(planID, cBuildPlanInfluenceBuilderPositionFalloff, 0,
                        cBPIFalloffLinear); // Linear slope falloff
   // Base ID.
   aiPlanSetBaseID(planID, baseID);
}

//==============================================================================
// selectShrineBuildPlanPosition
//==============================================================================
void selectShrineBuildPlanPosition(int planID = -1, int baseID = -1)
{
   static int huntableQuery = -1;

   if (huntableQuery < 0)
   {
      huntableQuery = kbUnitQueryCreate("Huntable query for shrine placement");
      kbUnitQuerySetPlayerID(huntableQuery, 0);
      kbUnitQuerySetUnitType(huntableQuery, cUnitTypeHuntable);
      kbUnitQuerySetMaximumDistance(huntableQuery, 400.0);
      kbUnitQuerySetAscendingSort(huntableQuery, true);
   }
   kbUnitQuerySetPosition(huntableQuery, kbBaseGetLocation(cMyID, baseID));
   kbUnitQueryResetResults(huntableQuery);
   int huntableCount = kbUnitQueryExecute(huntableQuery);
   int huntableID = -1;
   vector location = cInvalidVector;
   int huntableAreaGroup = -1;
   int mainAreaGroup = kbAreaGroupGetIDByPosition(kbBaseGetLocation(cMyID, baseID));
   bool goodPlaceFound = false;

   debugBuildings("**** Starting Shrine placement search, found " + huntableCount + " huntables.");
   for (i = 0; < huntableCount)
   {
      huntableID = kbUnitQueryGetResult(huntableQuery, i);
      location = kbUnitGetPosition(huntableID);
      huntableAreaGroup = kbAreaGroupGetIDByPosition(location);

      // Where should I build?
      if ((huntableAreaGroup == mainAreaGroup) &&
          (getUnitCountByLocation(cUnitTypeHuntable, 0, cUnitStateAlive, location, 15.0) >=
           (4 * (getUnitCountByLocation(cUnitTypeAbstractShrine, cPlayerRelationAny, cUnitStateABQ, location, 30.0) + 1)) -
               1) &&
          (getUnitCountByLocation(cUnitTypeTownCenter, cPlayerRelationAlly, cUnitStateAlive, location, 50.0) > 0))
      {
         debugBuildings("    Found good place to build a shrine at " + location);
         goodPlaceFound = true;
         break;
      }
   }

   if (goodPlaceFound == true)
   {
      aiPlanSetVariableVector(planID, cBuildPlanCenterPosition, 0, location);
      aiPlanSetVariableFloat(planID, cBuildPlanCenterPositionDistance, 0, 30.0);
      aiPlanSetVariableVector(planID, cBuildPlanInfluencePosition, 0, location);              // Influence toward position
      aiPlanSetVariableFloat(planID, cBuildPlanInfluencePositionDistance, 0, 100.0);          // 100m range.
      aiPlanSetVariableFloat(planID, cBuildPlanInfluencePositionValue, 0, 200.0);             // 200 points max
      aiPlanSetVariableInt(planID, cBuildPlanInfluencePositionFalloff, 0, cBPIFalloffLinear); // Linear slope falloff
   }
   else
   {
      selectClosestBuildPlanPosition(planID, baseID);
   }
}

//==============================================================================
// selectTorpBuildPlanPosition
//==============================================================================
void selectTorpBuildPlanPosition(int planID = -1, int baseID = -1)
{
   static int resourceQuery = -1;
   static int torpQuery = -1;

   if (resourceQuery < 0)
   {
      resourceQuery = kbUnitQueryCreate("Resource query for torp placement");
      kbUnitQuerySetPlayerID(resourceQuery, 0);
      kbUnitQuerySetPosition(resourceQuery, kbBaseGetLocation(cMyID, baseID));
      kbUnitQuerySetMaximumDistance(resourceQuery, 200);
      kbUnitQuerySetAscendingSort(resourceQuery, true);

      torpQuery = kbUnitQueryCreate("Torp query for torp placement");
      kbUnitQuerySetPlayerRelation(torpQuery, cPlayerRelationAny);
      kbUnitQuerySetUnitType(torpQuery, cUnitTypedeTorp);
   }

   int numberFound = 0;
   int numberTorps = kbUnitQueryExecute(torpQuery);
   vector position = cInvalidVector;
   int numberPositionsToAvoid = xsArrayGetSize(gTorpPositionsToAvoid);
   bool goodPlaceFound = false;
   bool isMine = false;
   int unitID = -1;
   int amount = 0;
   int resourceType = cResourceGold;
   int torpID = -1;
   vector positionToAvoid = cInvalidVector;

   // Search for mines first.
   kbUnitQuerySetUnitType(resourceQuery, cUnitTypeAbstractMine);
   numberFound = kbUnitQueryExecute(resourceQuery);

   for (i = 0; < numberFound)
   {
      unitID = kbUnitQueryGetResult(resourceQuery, i);
      position = kbUnitGetPosition(unitID);
      for (j = 0; < numberPositionsToAvoid - 1)
      {
         positionToAvoid = xsArrayGetVector(gTorpPositionsToAvoid, numberPositionsToAvoid - j - 1);
         if (position == positionToAvoid)
         {
            position = cInvalidVector;
            break;
         }
      }
      if (position == cInvalidVector)
         continue;
      amount = kbUnitGetResourceAmount(unitID, cResourceGold);
      for (j = 0; < numberTorps)
      {
         torpID = kbUnitQueryGetResult(torpQuery, j);
         if (distance(kbUnitGetPosition(torpID), position) >= 24.0)
            continue;
         amount = amount - 500;
      }
      if (amount < 500)
         continue;
      debugBuildings("Found good location to build torp at " + position + " ,resource " + resourceType);
      goodPlaceFound = true;
      isMine = true;
      break;
   }

   if (goodPlaceFound == false)
   {
      kbUnitQuerySetUnitType(resourceQuery, cUnitTypeResource);
      numberFound = kbUnitQueryExecute(resourceQuery);

      for (i = 0; < numberFound)
      {
         unitID = kbUnitQueryGetResult(resourceQuery, i);
         // ignore movable resources
         if (kbUnitIsType(unitID, cUnitTypeUnit) == true && kbUnitGetCurrentHitpoints(unitID) > 0.0)
            continue;
         if (kbUnitIsType(unitID, cUnitTypeAbstractMine) == true)
            continue;
         resourceType = cResourceFood;
         if (kbUnitIsType(unitID, cUnitTypeTree) == true)
            resourceType = cResourceWood;
         position = kbUnitGetPosition(unitID);
         for (j = 0; < numberPositionsToAvoid - 1)
         {
            positionToAvoid = xsArrayGetVector(gTorpPositionsToAvoid, numberPositionsToAvoid - j - 1);
            if (position == positionToAvoid)
            {
               position = cInvalidVector;
               break;
            }
         }
         if (position == cInvalidVector)
            continue;
         amount = kbGetAmountValidResourcesByLocation(position, resourceType, cAIResourceSubTypeEasy, 6.0);
         for (j = 0; < numberTorps)
         {
            torpID = kbUnitQueryGetResult(torpQuery, j);
            if (distance(kbUnitGetPosition(torpID), position) >= 20.0)
               continue;
            amount = amount - 500;
         }
         if (amount < 500)
            continue;
         debugBuildings("Found good location to build torp at " + position + " ,resource " + resourceType);
         goodPlaceFound = true;
         break;
      }
   }

   if (goodPlaceFound == true)
   {
      aiPlanSetVariableVector(planID, cBuildPlanCenterPosition, 0, position);
      if (isMine == true)
      {
         aiPlanSetVariableFloat(planID, cBuildPlanCenterPositionDistance, 0, 7.99);
         aiPlanSetVariableFloat(planID, cBuildPlanCenterPositionStep, 0, 0.25);
      }
      else
      {
         aiPlanSetVariableFloat(planID, cBuildPlanCenterPositionDistance, 0, 5.99);
      }
      aiPlanSetVariableVector(planID, cBuildPlanInfluencePosition, 0, position);              // Influence toward position
      aiPlanSetVariableFloat(planID, cBuildPlanInfluencePositionDistance, 0, 100.0);          // 100m range.
      aiPlanSetVariableFloat(planID, cBuildPlanInfluencePositionValue, 0, 200.0);             // 200 points max
      aiPlanSetVariableInt(planID, cBuildPlanInfluencePositionFalloff, 0, cBPIFalloffLinear); // Linear slope falloff
      gTorpPosition = position;
   }
   else
   {
      selectClosestBuildPlanPosition(planID, baseID);
   }
}

//==============================================================================
// selectTribalMarketplaceBuildPlanPosition
//==============================================================================
bool selectTribalMarketplaceBuildPlanPosition(int planID = -1, int baseID = -1)
{
   static int mineQuery = -1;

   if (mineQuery < 0)
   {
      mineQuery = kbUnitQueryCreate("Mine query for Tribal Marketplace placement");
      kbUnitQuerySetPlayerID(mineQuery, 0);
      kbUnitQuerySetUnitType(mineQuery, cUnitTypeAbstractMine);
      kbUnitQuerySetMaximumDistance(mineQuery, 200.0);
      kbUnitQuerySetAscendingSort(mineQuery, true);
   }
   kbUnitQuerySetPosition(mineQuery, kbBaseGetLocation(cMyID, baseID));
   kbUnitQueryResetResults(mineQuery);
   int mineCount = kbUnitQueryExecute(mineQuery);
   int mineID = -1;
   vector location = cInvalidVector;
   bool goodPlaceFound = false;

   debugBuildings("Starting Tribal Marketplace placement search, found " + mineCount + " mines.");
   for (i = 0; < mineCount)
   {
      mineID = kbUnitQueryGetResult(mineQuery, i);
      location = kbUnitGetPosition(mineID);
      // Where should I build?
      if (getUnitCountByLocation(cUnitTypedeFurTrade, cPlayerRelationAny, cUnitStateABQ, location, 15.0) > 0)
         continue;
      goodPlaceFound = true;
      break;
   }

   if (goodPlaceFound == true)
   {
      aiPlanSetVariableVector(planID, cBuildPlanCenterPosition, 0, location);
      aiPlanSetVariableFloat(planID, cBuildPlanCenterPositionDistance, 0, 30.0);
      aiPlanSetVariableVector(planID, cBuildPlanInfluencePosition, 0, location);              // Influence toward position
      aiPlanSetVariableFloat(planID, cBuildPlanInfluencePositionDistance, 0, 100.0);          // 100m range.
      aiPlanSetVariableFloat(planID, cBuildPlanInfluencePositionValue, 0, 200.0);             // 200 points max
      aiPlanSetVariableInt(planID, cBuildPlanInfluencePositionFalloff, 0, cBPIFalloffLinear); // Linear slope falloff

      aiPlanSetVariableInt(planID, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypedeFurTrade);
      aiPlanSetVariableFloat(planID, cBuildPlanInfluenceUnitDistance, 0, 10.0);
      aiPlanSetVariableFloat(planID, cBuildPlanInfluenceUnitValue, 0, -20.0);
      aiPlanSetVariableInt(planID, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffLinear);
      return (true);
   }

   return (false);
}

//==============================================================================
// selectFieldBuildPlanPosition
//==============================================================================
bool selectFieldBuildPlanPosition(int planID = -1, int baseID = -1)
{
   static int granaryQuery = -1;

   if (granaryQuery < 0)
   {
      granaryQuery = kbUnitQueryCreate("Granary query for field placement");
      kbUnitQuerySetPlayerID(granaryQuery, cMyID);
      kbUnitQuerySetUnitType(granaryQuery, cUnitTypedeGranary);
      kbUnitQuerySetMaximumDistance(granaryQuery, 200.0);
      kbUnitQuerySetAscendingSort(granaryQuery, true);
   }
   kbUnitQuerySetPosition(granaryQuery, kbBaseGetLocation(cMyID, baseID));
   kbUnitQueryResetResults(granaryQuery);
   int granaryCount = kbUnitQueryExecute(granaryQuery);
   int granaryID = -1;
   vector location = cInvalidVector;
   bool goodPlaceFound = false;
   int size = xsArrayGetSize(gFullGranaries);
   debugBuildings("**** Starting Field placement search, found " + granaryCount + " granaries.");
   for (i = 0; < granaryCount)
   {
      granaryID = kbUnitQueryGetResult(granaryQuery, i);
      location = kbUnitGetPosition(granaryID);
      // Where should I build?
      if (getUnitCountByLocation(cUnitTypedeField, cMyID, cUnitStateABQ, location, 10.0) >= 8)
         continue;
      bool full = false;
      for (j = 0; < size)
      {
         if (granaryID == xsArrayGetInt(gFullGranaries, j))
         {
            full = true;
            break;
         }
      }
      if (full == true)
         continue;
      goodPlaceFound = true;
      break;
   }

   if (goodPlaceFound == true)
   {
      aiPlanSetVariableVector(planID, cBuildPlanCenterPosition, 0, location);
      aiPlanSetVariableFloat(planID, cBuildPlanCenterPositionDistance, 0, 10.0);
      aiPlanSetVariableFloat(planID, cBuildPlanCenterPositionStep, 0, 0.25);

      aiPlanSetVariableVector(planID, cBuildPlanInfluencePosition, 0, location);              // Influence toward position
      aiPlanSetVariableFloat(planID, cBuildPlanInfluencePositionDistance, 0, 100.0);          // 100m range.
      aiPlanSetVariableFloat(planID, cBuildPlanInfluencePositionValue, 0, 200.0);             // 200 points max
      aiPlanSetVariableInt(planID, cBuildPlanInfluencePositionFalloff, 0, cBPIFalloffLinear); // Linear slope falloff
      gFieldGranaryID = granaryID;
   }
   else
   {
      // Build another granary before building a field.
      planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypedeGranary);
      if (planID < 0)
      {
         planID = createSimpleBuildPlan(cUnitTypedeGranary, 1, 70, false, cEconomyEscrowID, kbBaseGetMainID(cMyID), 1);
         aiPlanSetDesiredResourcePriority(planID, 60);
      }
      return (false);
   }
   
   return (true);
}

//==============================================================================
// selectMountainMonasteryBuildPlanPosition
//==============================================================================
void selectMountainMonasteryBuildPlanPosition(int planID = -1, int baseID = -1)
{
   static int mineQuery = -1;
   float maxDistance = kbBaseGetMaximumResourceDistance(cMyID, baseID);

   if (mineQuery < 0)
   {
      mineQuery = kbUnitQueryCreate("Mine query for mountain monastery placement");
      kbUnitQuerySetPlayerID(mineQuery, 0);
      kbUnitQuerySetUnitType(mineQuery, cUnitTypeAbstractMine);
      kbUnitQuerySetMaximumDistance(mineQuery, 200);
      kbUnitQuerySetAscendingSort(mineQuery, true);
   }
   kbUnitQuerySetPosition(mineQuery, kbBaseGetLocation(cMyID, baseID));
   kbUnitQueryResetResults(mineQuery);
   int mineCount = kbUnitQueryExecute(mineQuery);
   int mineID = -1;
   vector location = cInvalidVector;
   bool goodPlaceFound = false;

   debugBuildings("**** Starting mountain monastery placement search, found " + mineCount + " mines.");
   for (i = 0; < mineCount)
   {
      mineID = kbUnitQueryGetResult(mineQuery, i);
      location = kbUnitGetPosition(mineID);
      // Where should I build?
      if (getUnitCountByLocation(cUnitTypedeMountainMonastery, cPlayerRelationAny, cUnitStateABQ, location, 5.0) > 0)
         continue;
      goodPlaceFound = true;
      break;
   }

   if (goodPlaceFound == true)
   {
      aiPlanSetVariableInt(planID, cBuildPlanSocketID, 0, mineID);
   }
   else
   {
      // Base ID.
      aiPlanSetBaseID(planID, baseID);
   }
}

//==============================================================================
// selectGranaryBuildPlanPosition
// Build the first Granary close to the starting Town Center and in the direction of the starting hunt.
// Build subsequent Granaries or if we can't find Hunt anymore just in the base.
//==============================================================================
void selectGranaryBuildPlanPosition(int planID = -1, int baseID = -1)
{
   // This is enough to place the Granary in the base if we already have a Granary or the Hunt check fails.
   aiPlanSetBaseID(planID, baseID);

   if (kbUnitCount(cMyID, cUnitTypedeGranary, cUnitStateABQ) < 1) 
   // Only use this logic for the first Granary (or if we lose all).
   {
      vector townCenterLocation = getStartingLocation();
      int huntableUnitID = -1;
      vector huntLocation = cInvalidVector;
      vector placeGranaryHere = cInvalidVector;

      huntableUnitID = getClosestUnitByLocation(cUnitTypeHuntable, cCivNature, cUnitStateAlive, townCenterLocation, 50.0);
      if (huntableUnitID != -1) // If we find something within 50 range let's base our Granary position of that otherwise just
                                // randomly in our base again.
      {
         huntLocation = kbUnitGetPosition(huntableUnitID);
         placeGranaryHere = townCenterLocation + (xsVectorNormalize(huntLocation - townCenterLocation)) * 5.0;

         aiPlanSetVariableVector(planID, cBuildPlanCenterPosition, 0, placeGranaryHere);
         aiPlanSetVariableFloat(planID, cBuildPlanCenterPositionDistance, 0, 30.0);
         aiPlanSetVariableVector(planID, cBuildPlanInfluencePosition, 0, placeGranaryHere);      // Influence toward position
         aiPlanSetVariableFloat(planID, cBuildPlanInfluencePositionDistance, 0, 100.0);          // 100m range.
         aiPlanSetVariableFloat(planID, cBuildPlanInfluencePositionValue, 0, 200.0);             // 200 points max
         aiPlanSetVariableInt(planID, cBuildPlanInfluencePositionFalloff, 0, cBPIFalloffLinear); // Linear slope falloff

         aiPlanSetVariableInt(planID, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypedeGranary);
         aiPlanSetVariableFloat(planID, cBuildPlanInfluenceUnitDistance, 0, 30.0);
         aiPlanSetVariableFloat(planID, cBuildPlanInfluenceUnitValue, 0, -20.0);
         aiPlanSetVariableInt(planID, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffLinear);
         debugBuildings("Granary build plan created by looking at Hunt positions, loc: " + placeGranaryHere);
      }
      else
         debugBuildings("Granary build plan created but couldn't find Hunt");
   }
   else
   {
      debugBuildings("Granary build plan created for another Granary");
   }

   // If the Granary is meant for Hunt we want less spacing so it can be closer to the Hunt if it's a Granary for Fields we want
   // more spacing to have room for the actual Fields.
   aiPlanSetVariableFloat(planID, cBuildPlanBuildingBufferSpace, 0, huntableUnitID >= 0 ? 5.0 : 15.0);
}

void selectTCBuildPlanPosition(int buildPlan = -1, int baseID = -1)
{
   // We need to figure out where to put the new TC.  Start with the current main base as an anchor.
   // From that, check all gold mines within 100 meters and on the same area group.  For each, see if there
   // is a TC nearby, if not, do it.
   // If all gold mines fail, use the main base location and let it sort it out in the build plan, i.e. TCs repel, gold
   // attracts, etc.
   static int mineQuery = -1;
   if (mineQuery < 0)
   {
      mineQuery = kbUnitQueryCreate("Mine query for TC placement");
      kbUnitQuerySetPlayerID(mineQuery, 0);
      kbUnitQuerySetUnitType(mineQuery, cUnitTypeMine);
      kbUnitQuerySetMaximumDistance(mineQuery, 200.0);
      kbUnitQuerySetAscendingSort(mineQuery, true); // Ascending distance from initial location
   }
   kbUnitQuerySetPosition(mineQuery, kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)));
   kbUnitQueryResetResults(mineQuery);
   int mineCount = kbUnitQueryExecute(mineQuery);
   int i = 0;
   int mineID = -1;
   vector loc = cInvalidVector;
   int mineAreaGroup = -1;
   int mainAreaGroup = kbAreaGroupGetIDByPosition(kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)));
   bool found = false;
   debugBuildings("**** Starting TC placement search, found " + mineCount + " mines.");
   for (i = 0; < mineCount)
   { // Check each mine for a nearby TC, i.e. w/in 30 meters.
      mineID = kbUnitQueryGetResult(mineQuery, i);
      loc = kbUnitGetPosition(mineID);
      mineAreaGroup = kbAreaGroupGetIDByPosition(loc);
      if ((getUnitByLocation(cUnitTypeTownCenter, cPlayerRelationAny, cUnitStateABQ, loc, 30.0) < 0) &&
          // Not worth building a TC when there are too few tiles (ex. ceylon starting island.)
          (mineAreaGroup == mainAreaGroup && getAreaGroupNumberTiles(mineAreaGroup) >= 2000))
      {
         debugBuildings("    Found good mine at " + loc);
         found = true;
         break;
      }
      else
      {
         debugBuildings("    Ignoring mine at " + loc);
      }
   }
   // This time don't limit our area group and search for all resources.
   if (found == false)
   {
      int numResources = kbResourceGetNumber();
      int resourceID = -1;
      int resourceQuery = -1;
      int numberFound = 0;
      float resourceAmount = 0.0;
      int unitID = -1;

      for (i = 0; < numResources)
      {
         resourceID = kbResourceGetIDByIndex(i);
         if (kbResourceGetSubType(resourceID) == cAIResourceSubTypeFish)
            continue;
         mineID = kbResourceGetUnit(resourceID, 0);
         if (mineID < 0)
            continue;
         loc = kbUnitGetPosition(mineID);
         mineAreaGroup = kbAreaGroupGetIDByPosition(loc);
         if ((getUnitByLocation(cUnitTypeTownCenter, cPlayerRelationAny, cUnitStateABQ, loc, 30.0) > 0) ||
            // Not worth building a TC when there are too few tiles (ex. ceylon starting island.)
            (getAreaGroupNumberTiles(mineAreaGroup) < 2000))
            continue;
         resourceQuery = createSimpleUnitQuery(cUnitTypeResource, 0, cUnitStateAny, loc, 30.0);
         numberFound = kbUnitQueryExecute(resourceQuery);
         resourceAmount = 0.0;
         for (j = 0; < numberFound)
         {
            unitID = kbUnitQueryGetResult(resourceQuery, j);
            resourceAmount = resourceAmount + kbUnitGetResourceAmount(unitID, cResourceFood)
                           + kbUnitGetResourceAmount(unitID, cResourceWood)
                           + kbUnitGetResourceAmount(unitID, cResourceGold);
            if (resourceAmount >= 0.0)
               break;
         }
         if (resourceAmount >= 0.0)
         {
            debugBuildings("    Found good resource location at " + loc);
            found = true;
            xsEnableRule("findNewBase");
            break;
         }
         else
         {
            debugBuildings("    Ignoring resource location at " + loc);
         }
      }
   }

   // If we found a mine without a nearby TC, use that mine's location.  If not, use the main base.
   if (found == false)
      loc = kbBaseGetLocation(cMyID, baseID);
   // If we have no main base (usually nomad start), and cannot find a mine for placement, just build at the covered
   // wagon position.
   if (loc == cInvalidVector && aiPlanGetNumberNeededUnits(buildPlan, cUnitTypeCoveredWagon) > 0)
      loc = kbUnitGetPosition(getUnit(cUnitTypeCoveredWagon));

   gTCSearchVector = loc;

   // Instead of base ID or areas, use a center position and falloff.
   aiPlanSetVariableVector(buildPlan, cBuildPlanCenterPosition, 0, loc);
   aiPlanSetVariableFloat(buildPlan, cBuildPlanCenterPositionDistance, 0, 50.00);
   // Add position influences for trees, gold, TCs.
   aiPlanSetNumberVariableValues(buildPlan, cBuildPlanInfluenceUnitTypeID, 4, true);
   aiPlanSetNumberVariableValues(buildPlan, cBuildPlanInfluenceUnitDistance, 4, true);
   aiPlanSetNumberVariableValues(buildPlan, cBuildPlanInfluenceUnitValue, 4, true);
   aiPlanSetNumberVariableValues(buildPlan, cBuildPlanInfluenceUnitFalloff, 4, true);
   aiPlanSetVariableInt(buildPlan, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypeWood);
   aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluenceUnitDistance, 0, 30.0);           // 30m range.
   aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluenceUnitValue, 0, 10.0);              // 10 points per tree
   aiPlanSetVariableInt(buildPlan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffLinear); // Linear slope falloff
   aiPlanSetVariableInt(buildPlan, cBuildPlanInfluenceUnitTypeID, 1, cUnitTypeMine);
   aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluenceUnitDistance, 1,
                          40.0);                                                          // 40 meter range for gold
   aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluenceUnitValue, 1, 300.0);             // 300 points each
   aiPlanSetVariableInt(buildPlan, cBuildPlanInfluenceUnitFalloff, 1, cBPIFalloffLinear); // Linear slope falloff
   aiPlanSetVariableInt(buildPlan, cBuildPlanInfluenceUnitTypeID, 2, cUnitTypeMine);
   aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluenceUnitDistance, 2,
                          10.0);                                               // 10 meter inhibition to keep some space
   aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluenceUnitValue, 2, -300.0); // -300 points each
   aiPlanSetVariableInt(buildPlan, cBuildPlanInfluenceUnitFalloff, 2, cBPIFalloffNone); // Cliff falloff
   aiPlanSetVariableInt(buildPlan, cBuildPlanInfluenceUnitTypeID, 3, cUnitTypeTownCenter);
   aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluenceUnitDistance, 3, 40.0);         // 40 meter inhibition around TCs.
   aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluenceUnitValue, 3, -500.0);          // -500 points each
   aiPlanSetVariableInt(buildPlan, cBuildPlanInfluenceUnitFalloff, 3, cBPIFalloffNone); // Cliff falloff
   // Weight it to prefer the general starting neighborhood
   aiPlanSetVariableVector(buildPlan, cBuildPlanInfluencePosition, 0, loc);          // Position influence for landing position
   aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluencePositionDistance, 0, 100.0); // 100m range.
   aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluencePositionValue, 0, 300.0);    // 300 points max
   aiPlanSetVariableInt(buildPlan, cBuildPlanInfluencePositionFalloff, 0, cBPIFalloffLinear); // Linear slope falloff

   aiPlanSetActive(buildPlan);
   if (cvOkToTaunt == true)
   {
      aiPlanSetEventHandler(buildPlan, cPlanEventStateChange, "tcPlacedEventHandler");
   }
   gTCBuildPlanID = buildPlan; // Save in a global var so the rule can access it.
}

//==============================================================================
/* selectTowerBuildPlanPosition
   Placement algorithm is brain-dead simple.  Check a point that is mid-edge or a
   corner of a square around the base center.  Look for a nearby tower.  If none,
   do a tight build plan.  If there is one, try again.    If no luck, try a build
   plan that just avoids other towers.
*/
//==============================================================================

void selectTowerBuildPlanPosition(int buildPlan = -1, int baseID = -1)
{
   int towerBL = kbGetBuildLimit(cMyID, gTowerUnit);
   int numAttempts = 3 * towerBL / 2;
   vector testVec = cInvalidVector;
   static vector baseVec = cInvalidVector;
   static vector startingVec = cInvalidVector;
   int numTestVecs = 5 * towerBL / 4;
   float towerAngle = (2.0 * PI) / numTestVecs;
   float spacingDistance = 24 * sin((PI - towerAngle) / 2.0) /
                           sin(towerAngle); // Mid- and corner-spots on a square with 'radius'
                                            // spacingDistance, i.e. each side is 2 * spacingDistance.
   float exclusionRadius = spacingDistance / 2.0;
   vector StartBase = kbBaseGetLocation(cMyID, baseID);	

   static int towerSearch = -1;
   bool success = false;

   if ((startingVec == cInvalidVector) || (baseVec != kbBaseGetLocation(cMyID, baseID))) // Base changed
   {
      baseVec = kbBaseGetLocation(cMyID, baseID); // Start with base location
      startingVec = baseVec;
      startingVec = xsVectorSetX(startingVec, xsVectorGetX(startingVec) + spacingDistance);
      startingVec = rotateByReferencePoint(baseVec, startingVec - baseVec, aiRandInt(360) / (180.0 / PI));
   }

   for (attempt = 0; < numAttempts)
   {
      testVec = rotateByReferencePoint(baseVec, startingVec - baseVec, towerAngle * aiRandInt(numTestVecs));
      debugBuildings("Testing tower location " + testVec);
      if (towerSearch < 0)
      { // init
         towerSearch = kbUnitQueryCreate("Tower placement search");
         kbUnitQuerySetPlayerRelation(towerSearch, cPlayerRelationAny);
         kbUnitQuerySetUnitType(towerSearch, gTowerUnit);
         kbUnitQuerySetState(towerSearch, cUnitStateABQ);
      }
      kbUnitQuerySetPosition(towerSearch, testVec);
      //kbUnitQuerySetMaximumDistance(towerSearch, exclusionRadius);
      kbUnitQueryResetResults(towerSearch);
      if (kbUnitQueryExecute(towerSearch) < 1)
      { // Site is clear, use it
         if (kbAreaGroupGetIDByPosition(testVec) == kbAreaGroupGetIDByPosition(kbBaseGetLocation(cMyID, baseID)))
         { // Make sure it's in the same areagroup.
            success = true;
            break;
         }
      }
   }

   // We have found a location (success == true) or we need to just do a brute force placement around the TC.
   if (success == false)
      testVec = kbBaseGetLocation(cMyID, baseID);

   // Instead of base ID or areas, use a center position and falloff.
   aiPlanSetVariableVector(buildPlan, cBuildPlanCenterPosition, 0, testVec);
   if (success == true)
      aiPlanSetVariableFloat(buildPlan, cBuildPlanCenterPositionDistance, 0, exclusionRadius);
   else
      aiPlanSetVariableFloat(buildPlan, cBuildPlanCenterPositionDistance, 0, 50.0);

   // Add position influences for trees, gold, TCs.
   aiPlanSetNumberVariableValues(buildPlan, cBuildPlanInfluenceUnitTypeID, 8, true);
   aiPlanSetNumberVariableValues(buildPlan, cBuildPlanInfluenceUnitDistance, 8, true);
   aiPlanSetNumberVariableValues(buildPlan, cBuildPlanInfluenceUnitValue, 8, true);
   aiPlanSetNumberVariableValues(buildPlan, cBuildPlanInfluenceUnitFalloff, 8, true);
   aiPlanSetVariableInt(buildPlan, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypeWood);
   aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluenceUnitDistance, 0, 20.0);     // 30m range.
   aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluenceUnitValue, 0, 10.0);        // 10 points per tree
   aiPlanSetVariableInt(buildPlan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffLinear);  // Linear slope falloff
   aiPlanSetVariableInt(buildPlan, cBuildPlanInfluenceUnitTypeID, 1, cUnitTypeMine);
   aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluenceUnitDistance, 1,  20.0);              // 40 meter range for gold
   aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluenceUnitValue, 1, 400.0);                // 300 points each
   aiPlanSetVariableInt(buildPlan, cBuildPlanInfluenceUnitFalloff, 1, cBPIFalloffLinear);  // Linear slope falloff
   aiPlanSetVariableInt(buildPlan, cBuildPlanInfluenceUnitTypeID, 2, cUnitTypeMine);
   aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluenceUnitDistance, 2, 10.0);              // 10 meter inhibition to keep some space
   aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluenceUnitValue, 2, -600.0);                // -300 points each
   aiPlanSetVariableInt(buildPlan, cBuildPlanInfluenceUnitFalloff, 2, cBPIFalloffNone);      // Cliff falloff
   aiPlanSetVariableInt(buildPlan, cBuildPlanInfluenceUnitTypeID, 3, cUnitTypeHuntable);
   aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluenceUnitDistance, 3, 20.0);     // 30m range.
   aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluenceUnitValue, 3, 25.0);        // 10 points per tree
   aiPlanSetVariableInt(buildPlan, cBuildPlanInfluenceUnitFalloff, 3, cBPIFalloffLinear);
   aiPlanSetVariableInt(buildPlan, cBuildPlanInfluenceUnitTypeID, 4, cUnitTypeDock);
   aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluenceUnitDistance, 4, 20.0);              // 40 meter inhibition around TCs.
   aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluenceUnitValue, 4, 300.0);                // -500 points each
   aiPlanSetVariableInt(buildPlan, cBuildPlanInfluenceUnitFalloff, 4, cBPIFalloffLinear);      // Cliff falloff
   aiPlanSetVariableInt(buildPlan, cBuildPlanInfluenceUnitTypeID, 5, gTowerUnit);
   aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluenceUnitDistance, 5, 20.0);              // 40 meter inhibition around TCs.
   aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluenceUnitValue, 5, -600.0);                // -500 points each
   aiPlanSetVariableInt(buildPlan, cBuildPlanInfluenceUnitFalloff, 5, cBPIFalloffNone);      // Cliff falloff
   aiPlanSetVariableInt(buildPlan, cBuildPlanInfluenceUnitTypeID, 6, cUnitTypeTownCenter);
   aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluenceUnitDistance, 6, 20.0);              // 40 meter inhibition around TCs.
   aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluenceUnitValue, 6, -600.0);                // -500 points each
   aiPlanSetVariableInt(buildPlan, cBuildPlanInfluenceUnitFalloff, 6, cBPIFalloffNone);      // Cliff falloff
	   // Weight it to prefer the general starting neighborhood
      if (kbGetAge() == cAge1)
      aiPlanSetVariableVector(buildPlan, cBuildPlanInfluencePosition, 1, StartBase); // Position influence for landing position
      aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluencePositionDistance, 1, 50.0);          // 100m range.
      aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluencePositionValue, 1, 50.0);             // 300 points max
      aiPlanSetVariableInt(buildPlan, cBuildPlanInfluencePositionFalloff, 1, cBPIFalloffLinear); // Linear slope falloff
	   // Weight it to prefer the general starting neighborhood
      if (kbGetAge() == cAge2)
      aiPlanSetVariableVector(buildPlan, cBuildPlanInfluencePosition, 2, StartBase); // Position influence for landing position
      aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluencePositionDistance, 2, 100.0);          // 100m range.
      aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluencePositionValue, 2, 50.0);             // 300 points max
      aiPlanSetVariableInt(buildPlan, cBuildPlanInfluencePositionFalloff, 2, cBPIFalloffLinear); // Linear slope falloff
      if (kbGetAge() > cAge2)
      aiPlanSetVariableVector(buildPlan, cBuildPlanInfluencePosition, 2, StartBase); // Position influence for landing position
      aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluencePositionDistance, 2, 150.0);          // 100m range.
      aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluencePositionValue, 2, 50.0);             // 300 points max
      aiPlanSetVariableInt(buildPlan, cBuildPlanInfluencePositionFalloff, 2, cBPIFalloffLinear); // Linear slope falloff
   // Weight it to stay very close to center point.
   aiPlanSetVariableVector(buildPlan, cBuildPlanInfluencePosition, 0,
                           testVec); // Position influence for landing position
   aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluencePositionDistance, 0, exclusionRadius); // 100m range.
   aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluencePositionValue, 0, 10.0);               // 10 points for center
   aiPlanSetVariableInt(buildPlan, cBuildPlanInfluencePositionFalloff, 0, cBPIFalloffLinear);  // Linear slope falloff

   debugBuildings("Building plan (" + buildPlan + ") for tower at location " + testVec);
}

//==============================================================================
// selectBuildPlanPosition
//==============================================================================
bool selectBuildPlanPosition(int planID = -1, int puid = -1, int baseID = -1)
{
   bool result = true;

   // Position.
   switch (puid)
   {
   case cUnitTypeypShrineJapanese:
   case cUnitTypeypWJToshoguShrine2:
   case cUnitTypeypWJToshoguShrine3:
   case cUnitTypeypWJToshoguShrine4:
   case cUnitTypeypWJToshoguShrine5:
   {
      selectShrineBuildPlanPosition(planID, baseID);
      break;
   }
   case cUnitTypedeTorp:
   {
      selectTorpBuildPlanPosition(planID, baseID);
      break;
   }
   case cUnitTypedeHouseAfrican:
   case cUnitTypeHouse:
   case cUnitTypeypVillage:
   case cUnitTypeypHouseIndian:
   case cUnitTypeManor:
   case cUnitTypeHouseEast:
   case cUnitTypeHouseMed:
   case cUnitTypeLonghouse:
   case cUnitTypeHouseAztec:
   case cUnitTypedeHouseInca:
   {
      selectClosestBuildPlanPosition(planID, baseID);
      break;
   }
   case cUnitTypeOutpost:
   case cUnitTypeWarHut:
   case cUnitTypeNoblesHut:
   case cUnitTypedeIncaStronghold:
   case cUnitTypedeTower:
   case cUnitTypeBlockhouse:
   case cUnitTypeypCastle:
   case cUnitTypeYPOutpostAsian:
   {
      selectTowerBuildPlanPosition(planID, baseID);
      break;
   }
   case cUnitTypeDock:
   case cUnitTypeYPDockAsian:
   case cUnitTypedePort:
   {
      aiPlanSetVariableVector(
          planID, cBuildPlanDockPlacementPoint, 0, kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID))); // One point at main base
      aiPlanSetVariableVector(planID, cBuildPlanDockPlacementPoint, 1, gNavyVec);                     // One point at water flag
      break;
   }
   case cUnitTypeBank:
   case cUnitTypeMarket:
   case cUnitTypeypTradeMarketAsian:
   case cUnitTypedeLivestockMarket:
   {
      // Usually we need to defend with Banks, thus placing Banks with high HP at front is a good choice.
      aiPlanSetVariableInt(planID, cBuildPlanLocationPreference, 0, cBuildingPlacementPreferenceFront);
      // Base ID.
      aiPlanSetBaseID(planID, baseID);
      break;
   }
   case cUnitTypeTownCenter:
   {
      selectTCBuildPlanPosition(planID, baseID);
      break;
   }
   case cUnitTypedeFurTrade:
   {
      result = selectTribalMarketplaceBuildPlanPosition(planID, baseID);
      break;
   }
   case cUnitTypedeField:
   {
      // returns false when we couldn't find a granary to build nearby, destroy the plan and wait for the granary
      // to be built.
      result = selectFieldBuildPlanPosition(planID, baseID);
      break;
   }
   case cUnitTypedeMountainMonastery:
   {
      selectMountainMonasteryBuildPlanPosition(planID, baseID);
      break;
   }
   case cUnitTypedeGranary:
   {
      selectGranaryBuildPlanPosition(planID, baseID);
      break;
   }
   case cUnitTypeFactory:
   case cUnitTypeypDojo:
   {
      aiPlanSetVariableInt(planID, cBuildPlanLocationPreference, 0, cBuildingPlacementPreferenceBack);
      // Base ID.
      aiPlanSetBaseID(planID, baseID);
      break;
   }
   default:
   {
      int numMilitaryBuildings = xsArrayGetSize(gMilitaryBuildings);
      for (i = 0; < numMilitaryBuildings)
      {
         if (puid != xsArrayGetInt(gMilitaryBuildings, i))
            continue;
         // This is a military building, randomize placement.
         aiPlanSetVariableInt(planID, cBuildPlanLocationPreference, 0, aiRandInt(4));
         break;
      }
      // Base ID.
      aiPlanSetBaseID(planID, baseID);
      break;
   }
   }

   return (result);
}

//==============================================================================
// findWagonToBuild
//==============================================================================
int findWagonToBuild(int puid = -1)
{
   debugBuildings("Looking for a Wagon to build: " + kbGetProtoUnitName(puid));

   if (kbProtoUnitAvailable(puid) ==
       false) // Safeguard against assigning Wagons to build plans for buildings in the next age because that will glitch out.
   {
      debugBuildings(kbGetProtoUnitName(puid) + " isn't available in our age yet, don't assign a Wagon to it or it will bug out");
      return (-1);
   }

   static int wagonQueryID = -1;
   int numberFound = 0;

   // If we don't have the query yet, create one.
   if (wagonQueryID < 0)
      wagonQueryID = kbUnitQueryCreate("findWagonToBuild Unit Query");

   // Define a query to get all matching units.
   if (wagonQueryID != -1)
   {
      kbUnitQueryResetResults(wagonQueryID);
      kbUnitQuerySetPlayerID(wagonQueryID, cMyID);
      kbUnitQuerySetUnitType(wagonQueryID, cUnitTypeAbstractWagon);
      kbUnitQuerySetState(wagonQueryID, cUnitStateAlive);
   }
   else
      return (-1);

   numberFound = kbUnitQueryExecute(wagonQueryID);
   debugBuildings("We've found " + numberFound + " Wagons alive");

   for (i = 0; < numberFound)
   {
      int wagonID = kbUnitQueryGetResult(wagonQueryID, i);
      if (kbUnitGetPlanID(wagonID) >= 0)
      {
         continue; // Wagon already has a plan so don't mess with it.
      }
      int wagonUnitType = kbUnitGetProtoUnitID(wagonID);
      if ((wagonUnitType == cUnitTypedeHomesteadWagon) && (puid == gHouseUnit))
      {
         continue; // We don't want this wagon to be wasted on houses.
      }
      if (kbProtoUnitCanTrain(wagonUnitType, puid) == true)
      {
         debugBuildings(
            "findWagonToBuild has found " + kbGetProtoUnitName(wagonUnitType) + " with ID: " + wagonID +
            " to build: " + kbGetProtoUnitName(puid));
         return (wagonUnitType);
      }
   }

   debugBuildings("We couldn't find a Wagon to build: " + kbGetProtoUnitName(puid));
   return (-1);
}

//==============================================================================
// addBuilderToPlan
//==============================================================================
bool addBuilderToPlan(int planID = -1, int puid = -1, int numberBuilders = 1)
{
	//if ((gRevolutionType & cRevolutionMilitary) == cRevolutionMilitary && (gRevolutionType & cRevolutionFinland) == 0)
    //  return (false);
      int heroQuery = createSimpleUnitQuery(cUnitTypeHero, cMyID, cUnitStateAlive);
      int numberFound = 0;
   int builderType = findWagonToBuild(puid);
   if (builderType >= 0)
   {
      aiPlanAddUnitType(planID, builderType, 1, 1, 1);
      return (true);
   }
   if (puid == cUnitTypeTownCenter)
   {
      // US hero cannot build town centers.
      if (cMyCiv != cCivDEAmericans)
         numberFound = kbUnitQueryExecute(heroQuery);
      if (numberBuilders > 1)
      {
         if (numberFound > 0)
         {
            aiPlanAddUnitType(planID, cUnitTypeHero, 1, 1, 1);
            numberBuilders = numberBuilders - 1;
         }
         if (numberBuilders > 0)
            aiPlanAddUnitType(planID, gEconUnit, numberBuilders, numberBuilders, numberBuilders);
      }
      else
      {
         numberBuilders = round(kbProtoUnitGetBuildPoints(puid) / 30.0);
         if (numberFound > 0)
         {
            aiPlanAddUnitType(planID, cUnitTypeHero, 1, 1, 1);
            numberBuilders = numberBuilders - 1;
         }
         if (numberBuilders > 0)
            aiPlanAddUnitType(planID, gEconUnit, 1, numberBuilders, numberBuilders);
      }
   }
   else
   if (puid == cUnitTypeYPLivestockPenAsian)
   {
      if ((kbUnitCount(cMyID, cUnitTypedeLivestockPenWagonJapanese, cUnitStateAlive) < 1) 
		  && (kbUnitCount(cMyID, cUnitTypeYPLivestockPenAsian, cUnitStateABQ) < 1))
      {
         aiPlanAddUnitType(planID, gEconUnit, 1, 1, 1);
	  }
   }
   else
   if (puid == cUnitTypeFortFrontier)
   {
      if (kbUnitCount(cMyID, cUnitTypeFortWagon, cUnitStateAlive) > 0)
            aiPlanAddUnitType(planID, cUnitTypeFortWagon, 1, 1, 1);
		else
	  if ((cMyCiv == cCivDEAmericans) && (kbGetAge() >= cAge3))
            aiPlanAddUnitType(planID, cUnitTypedeGeneral, 1, 1, 1);
		else
	  if (kbTechGetStatus(cTechHCXPNationalRedoubt) == cTechStatusActive)
         aiPlanAddUnitType(planID, cUnitTypeMusketeer, 8, 8, 8);
	 else
	  if ((kbTechGetStatus(cTechHCXPUnlockFort2) == cTechStatusActive) || 
      (kbTechGetStatus(cTechHCXPUnlockFort2German) == cTechStatusActive))
         aiPlanAddUnitType(planID, cUnitTypeExplorer, 1, 1, 1);
   }
   else
   if (puid == cUnitTypedeIncaStronghold)
   {
      if (kbUnitCount(cMyID, cUnitTypedeIncaStrongholdTravois, cUnitStateAlive) > 0)
            aiPlanAddUnitType(planID, cUnitTypedeIncaStrongholdTravois, 1, 1, 1);
		else
            aiPlanAddUnitType(planID, cUnitTypedeIncaWarChief, 1, 1, 1);
   }
   else
	   if ((puid == cUnitTypeTradingPost) && (gSPC == false))
   {
      // US hero cannot build town centers.
         numberFound = kbUnitQueryExecute(heroQuery);
         if (numberFound > 0)
         {
            aiPlanAddUnitType(planID, cUnitTypeHero, 1, 1, 1);
         }
      else
      {
		  if ((gRevolutionType & cRevolutionMilitary) == cRevolutionMilitary && (gRevolutionType & cRevolutionFinland) == 0)
      return (false);
  else
            aiPlanAddUnitType(planID, gEconUnit, 1, numberBuilders, numberBuilders);
      }
   }
	else
   if (puid == cUnitTypeypShrineJapanese)
   {
   static int monkQuery = -1;
	if (monkQuery < 0)
   {
      monkQuery = kbUnitQueryCreate("Monk query for shrine placement");
      kbUnitQuerySetPlayerID(monkQuery, cMyID);
      kbUnitQuerySetUnitType(monkQuery, cUnitTypeAbstractJapaneseMonk);
      kbUnitQuerySetIgnoreKnockedOutUnits(monkQuery, true);
   }
   kbUnitQueryResetResults(monkQuery);
   int numberMonks = kbUnitQueryExecute(monkQuery);
         if (numberMonks > 0)// && (xsGetTime() >= 8 * 60 * 1000))
		 {
            aiPlanAddUnitType(planID, cUnitTypeAbstractJapaneseMonk, 1, 1, 1);
		 }
         else
		 {
            aiPlanAddUnitType(planID, gEconUnit, 1, 1, 1);
		 }
    }
   else
	   if ((gRevolutionType & cRevolutionMilitary) == cRevolutionMilitary && (gRevolutionType & cRevolutionFinland) == 0)
      return (false);
  else
   {
      if ((cMyCiv == cCivGermans) && (kbUnitCount(cMyID, cUnitTypeSettlerWagon, cUnitStateAlive) > 0))
      {
         builderType = cUnitTypeSettlerWagon;
         numberBuilders = (numberBuilders + 1) / 2;
      }
      else
         builderType = gEconUnit;
   }
      if (numberBuilders > 1)
      {
         aiPlanAddUnitType(planID, builderType, numberBuilders, numberBuilders, numberBuilders);
      }
      else if (puid == cUnitTypedeField)
      {
         // just allocate 1 villager at max for fields.
         aiPlanAddUnitType(planID, builderType, 1, 1, 1);
      }
      else
      {
         numberBuilders = round(kbProtoUnitGetBuildPoints(puid) / 30.0);
         aiPlanAddUnitType(planID, builderType, 1, numberBuilders, numberBuilders);
      }
   return (true);
}

vector selectForwardBaseLocation(void)
{
   vector retVal = cInvalidVector;
   vector mainBaseVec = kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID));
   vector v = cInvalidVector; // Scratch variable for intermediate calcs.

   debugBuildings("Selecting forward base location.");
   float distanceMultiplier =
       0.5; // Will be used to determine how far out we should put the fort on the line from our base to enemy TC.
   float dist = 0.0;
   int enemyPlayer = aiGetMostHatedPlayerID();

   int enemyTC = getUnitByLocation(cUnitTypeTownCenter, enemyPlayer, cUnitStateABQ, mainBaseVec, 500.0);
   float radius = 0.0;
   vector vec = cInvalidVector;
   vector bestLoc = cInvalidVector;
   float bestDist = 0.0;
   int enemyBuildingQuery = createSimpleUnitQuery(cUnitTypeBuilding, cPlayerRelationEnemyNotGaia, cUnitStateABQ);
   int numberFound = kbUnitQueryExecute(enemyBuildingQuery);

   if (enemyTC < 0)
   {
      v = guessEnemyLocation(enemyPlayer);
      radius = 100.0;
      if (getUnitCountByLocation(cUnitTypeLogicalTypeBuildingsNotWalls, enemyPlayer, cUnitStateAlive, v, radius) == 0)
         return (cInvalidVector);
   }
   else // enemy TC found
   {
      v = kbUnitGetPosition(enemyTC); // Vector from main base to enemy TC
      radius = 50.0 + kbBaseGetDistance(enemyPlayer, kbUnitGetBaseID(enemyTC));
   }

   // find the best location within 90 degrees.
   vec = xsVectorNormalize(mainBaseVec - v) * radius;
   for (i = 0; < 4)
   {
      vector tempLoc = rotateByReferencePoint(v, vec, aiRandFloat(0.0 - PI * 0.25, PI * 0.25));
      float maxDist = 1000.0;
      int areaID = kbAreaGetIDByPosition(tempLoc);
      // ensure we are inside the map.
      if (areaID < 0)
         continue;
      if (kbAreaGetNumberTiles(areaID) == kbAreaGetNumberBlackTiles(areaID))
         continue;
      for (j = 0; < numberFound)
      {
         int buildingID = kbUnitQueryGetResult(enemyBuildingQuery, j);
         dist = distance(kbUnitGetPosition(buildingID), tempLoc);
         if (maxDist > dist)
            maxDist = dist;
      }
      if (bestDist < maxDist)
      {
         bestLoc = tempLoc;
         bestDist = maxDist;
      }
   }

   if (bestLoc != cInvalidVector)
   {
      retVal = bestLoc;
      // Now, make sure it's on the same areagroup, back up if it isn't.
      dist = distance(mainBaseVec, retVal);
      int mainAreaGroup = kbAreaGroupGetIDByPosition(mainBaseVec);
      vector delta = mainBaseVec - retVal;
      int step = 0;
      bool siteFound = false;

      delta *= 30.0 / xsVectorLength(delta);

      if (dist > 0.0)
      {
         for (step = 0; < 9)
         {
            debugBuildings("    " + retVal + " is in area group " + kbAreaGroupGetIDByPosition(retVal));
            siteFound = true;
            /*if (getUnitByLocation(cUnitTypeBuilding, cPlayerRelationEnemyNotGaia, cUnitStateABQ, retVal, 60.0) >= 0)
               continue; // DO NOT build too close to enemy buildings.
            if (getUnitByLocation(cUnitTypeTownCenter, cPlayerRelationEnemyNotGaia, cUnitStateABQ, retVal, 60.0) >= 0)
               continue; // Ditto enemy TCs.*/
            // don't build too close to any enemy building.
            if (getUnitByLocation(cUnitTypeBuilding, cPlayerRelationEnemyNotGaia, cUnitStateABQ, retVal, 60.0) >= 0)
               siteFound = false;
            else if (mainAreaGroup != kbAreaGroupGetIDByPosition(retVal))
               siteFound = false;
            else
            { // DONE!
               debugBuildings("        Good location found.");
               break;
            }
            retVal = retVal + delta; // Move 1/10 of way back to main base, try again.
         }
      }
   }

   if (aiGetWorldDifficulty() < cDifficultyModerate || siteFound == false)
      retVal = cInvalidVector; // Easy and Sandbox will never forward build.
   debugBuildings("    New forward base location will be " + retVal);
   return (retVal);
}

//==============================================================================
/*
   Forward base manager
   Handles the planning, construction, defense and maintenance of a forward military base.

   The steps involved:
   1)  Choose a location.
   2)  Defend it and send a fort wagon to build a fort.
   3)  Define it as the military base, move defend plans there, move military production there.
   4)  Undo those settings if it needs to be abandoned.
*/
//==============================================================================
rule forwardBaseManager
inactive
group tcComplete
minInterval 30
{
   if ((cvOkToBuild == false) || (cvOkToBuildForts == false) || (aiTreatyActive() == true))
      return;
   int fortUnitID = -1;
   int buildingQuery = -1;
   int numberFound = 0;
   int numberMilitaryBuildings = 0;
   int buildingID = -1;
   int numFortresses = kbUnitCount(cMyID, cUnitTypeFortFrontier, cUnitStateABQ);
   int numStronghold = kbUnitCount(cMyID, cUnitTypedeIncaStronghold, cUnitStateABQ);
         vector location = cInvalidVector;
         //if (btOffenseDefense >= 0.0)
            location = selectForwardBaseLocation();
   int planID = -1;
   planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeFortFrontier);
	  if (cMyCiv == cCivDEInca)
   planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypedeIncaStronghold);
   switch (gForwardBaseState)
   {
   case cForwardBaseStateNone:
   {
      // Check if we should go to state Building
      if (kbUnitCount(cMyID, cUnitTypeFortWagon, cUnitStateAlive) > 0)
		  //if (numFortresses < kbGetBuildLimit(cMyID, cUnitTypeFortFrontier))
      { // Yes.
         // get the fort wagon, start a build plan, keep it defended
         if (location == cInvalidVector)
         {
            createSimpleBuildPlan(cUnitTypeFortFrontier, 1, 99, true, cMilitaryEscrowID, kbBaseGetMainID(cMyID), 1);
            return;
         }
         gForwardBaseLocation = location;
         gForwardBaseBuildPlan = aiPlanCreate("Fort build plan ", cPlanBuild);
         aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanBuildingTypeID, 0, cUnitTypeFortFrontier);
         aiPlanSetDesiredPriority(gForwardBaseBuildPlan, 99);
         // Military
         aiPlanSetMilitary(gForwardBaseBuildPlan, true);
         aiPlanSetEconomy(gForwardBaseBuildPlan, false);
         aiPlanSetEscrowID(gForwardBaseBuildPlan, cMilitaryEscrowID);
		 //if (kbUnitCount(cMyID, cUnitTypeFortWagon, cUnitStateAlive) > 0)
         aiPlanAddUnitType(gForwardBaseBuildPlan, cUnitTypeFortWagon, 1, 1, 1);
		 // Instead of base ID or areas, use a center position
         aiPlanSetVariableVector(gForwardBaseBuildPlan, cBuildPlanCenterPosition, 0, location);
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanCenterPositionDistance, 0, 50.0);
         // Weight it to stay very close to center point.
         aiPlanSetVariableVector(gForwardBaseBuildPlan, cBuildPlanInfluencePosition, 0,
                                 location); // Position influence for center
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluencePositionDistance, 0, 100.0); // 100m range.
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluencePositionValue, 0,
                                100.0); // 100 points for center
         aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluencePositionFalloff, 0,
                              cBPIFalloffLinear); // Linear slope falloff
         // Add position influence for nearby towers
            aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypeFortFrontier);   // Don't build anywhere near another fort.
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitDistance, 0, 32.0);
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitValue, 0, 300.0);        // -20 points per fort
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffLinear);  // Cliff falloff// Add position influence for nearby towers
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypeFortFrontier);   // Don't build anywhere near another fort.
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitDistance, 0, 18.0);
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitValue, 0, -200.0);        // -20 points per fort
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffNone);
         aiPlanSetActive(gForwardBaseBuildPlan);
         // Chat to my allies
         sendStatement(cPlayerRelationAlly, cAICommPromptToAllyIWillBuildMilitaryBase, gForwardBaseLocation);
         gForwardBaseState = cForwardBaseStateBuilding;
         aiEcho(" ");
         aiEcho("    BUILDING FORWARD BASE, MOVING DEFEND PLANS TO COVER.");
         aiEcho("    PLANNED LOCATION IS " + gForwardBaseLocation);
         aiEcho(" ");
         if (gDefenseReflex == false)
            endDefenseReflex(); // Causes it to move to the new location
      }
	  else
		  if (numFortresses < kbGetBuildLimit(cMyID, cUnitTypeFortFrontier))
		  {
	  if ((cMyCiv == cCivDEAmericans) && (kbGetAge() >= cAge3) && (aiGetFallenExplorerID() < 1))
	  {
		   if (location == cInvalidVector)
         {
            createSimpleBuildPlan(cUnitTypeFortFrontier, 1, 99, true, cMilitaryEscrowID, kbBaseGetMainID(cMyID), 1);
            return;
         }
         gForwardBaseLocation = location;
         gForwardBaseBuildPlan = aiPlanCreate("Fort build plan ", cPlanBuild);
         aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanBuildingTypeID, 0, cUnitTypeFortFrontier);
         if ((kbGetAge() >= cvMaxAge) || (gRevolutionType != 0))
		 {
         aiPlanSetDesiredPriority(gForwardBaseBuildPlan, 95);
		 }
		 else
		 {
         aiPlanSetDesiredPriority(gForwardBaseBuildPlan, 25);
		 }
         // Military
         aiPlanSetMilitary(gForwardBaseBuildPlan, true);
         aiPlanSetEconomy(gForwardBaseBuildPlan, false);
         aiPlanSetEscrowID(gForwardBaseBuildPlan, cMilitaryEscrowID);
		 if (aiGetFallenExplorerID() < 1)
         aiPlanAddUnitType(gForwardBaseBuildPlan, cUnitTypedeGeneral, 1, 1, 1);
			 else
      {
         aiPlanDestroy(gForwardBaseBuildPlan);
         gForwardBaseBuildPlan = -1;
         return;
      }
         // Instead of base ID or areas, use a center position
         aiPlanSetVariableVector(gForwardBaseBuildPlan, cBuildPlanCenterPosition, 0, location);
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanCenterPositionDistance, 0, 50.0);
         // Weight it to stay very close to center point.
         aiPlanSetVariableVector(gForwardBaseBuildPlan, cBuildPlanInfluencePosition, 0,
                                 location); // Position influence for center
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluencePositionDistance, 0, 100.0); // 100m range.
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluencePositionValue, 0,
                                100.0); // 100 points for center
         aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluencePositionFalloff, 0,
                              cBPIFalloffLinear); // Linear slope falloff
         // Add position influence for nearby towers
            aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypeFortFrontier);   // Don't build anywhere near another fort.
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitDistance, 0, 32.0);
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitValue, 0, 300.0);        // -20 points per fort
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffLinear);  // Cliff falloff// Add position influence for nearby towers
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypeFortFrontier);   // Don't build anywhere near another fort.
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitDistance, 0, 18.0);
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitValue, 0, -200.0);        // -20 points per fort
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffNone);
         aiPlanSetActive(gForwardBaseBuildPlan);
         // Chat to my allies
         sendStatement(cPlayerRelationAlly, cAICommPromptToAllyIWillBuildMilitaryBase, gForwardBaseLocation);
         gForwardBaseState = cForwardBaseStateBuilding;
         aiEcho(" ");
         aiEcho("    BUILDING FORWARD BASE, MOVING DEFEND PLANS TO COVER.");
         aiEcho("    PLANNED LOCATION IS " + gForwardBaseLocation);
         aiEcho(" ");
         if (gDefenseReflex == false)
            endDefenseReflex(); // Causes it to move to the new location
      }
	  else
	  if (kbTechGetStatus(cTechHCXPNationalRedoubt) == cTechStatusActive)
	  {
		   if (location == cInvalidVector)
         {
            createSimpleBuildPlan(cUnitTypeFortFrontier, 1, 99, true, cMilitaryEscrowID, kbBaseGetMainID(cMyID), 1);
            return;
         }
         gForwardBaseLocation = location;
         gForwardBaseBuildPlan = aiPlanCreate("Fort build plan ", cPlanBuild);
         aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanBuildingTypeID, 0, cUnitTypeFortFrontier);
         if ((kbGetAge() >= cvMaxAge) || (gRevolutionType != 0))
		 {
         aiPlanSetDesiredPriority(gForwardBaseBuildPlan, 95);
		 }
		 else
		 {
         aiPlanSetDesiredPriority(gForwardBaseBuildPlan, 25);
		 }
         // Military
         aiPlanSetMilitary(gForwardBaseBuildPlan, true);
         aiPlanSetEconomy(gForwardBaseBuildPlan, false);
         aiPlanSetEscrowID(gForwardBaseBuildPlan, cMilitaryEscrowID);
         aiPlanAddUnitType(gForwardBaseBuildPlan, cUnitTypeMusketeer, 8, 8, 8);
		 // Instead of base ID or areas, use a center position
         aiPlanSetVariableVector(gForwardBaseBuildPlan, cBuildPlanCenterPosition, 0, location);
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanCenterPositionDistance, 0, 50.0);
         // Weight it to stay very close to center point.
         aiPlanSetVariableVector(gForwardBaseBuildPlan, cBuildPlanInfluencePosition, 0,
                                 location); // Position influence for center
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluencePositionDistance, 0, 100.0); // 100m range.
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluencePositionValue, 0,
                                100.0); // 100 points for center
         aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluencePositionFalloff, 0,
                              cBPIFalloffLinear); // Linear slope falloff
         // Add position influence for nearby towers
            aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypeFortFrontier);   // Don't build anywhere near another fort.
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitDistance, 0, 32.0);
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitValue, 0, 300.0);        // -20 points per fort
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffLinear);  // Cliff falloff// Add position influence for nearby towers
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypeFortFrontier);   // Don't build anywhere near another fort.
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitDistance, 0, 18.0);
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitValue, 0, -200.0);        // -20 points per fort
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffNone);
         aiPlanSetActive(gForwardBaseBuildPlan);
         // Chat to my allies
         sendStatement(cPlayerRelationAlly, cAICommPromptToAllyIWillBuildMilitaryBase, gForwardBaseLocation);
         gForwardBaseState = cForwardBaseStateBuilding;
         aiEcho(" ");
         aiEcho("    BUILDING FORWARD BASE, MOVING DEFEND PLANS TO COVER.");
         aiEcho("    PLANNED LOCATION IS " + gForwardBaseLocation);
         aiEcho(" ");
         if (gDefenseReflex == false)
            endDefenseReflex();
      }
	  else
	  if (((kbTechGetStatus(cTechHCXPUnlockFort2) == cTechStatusActive) || (kbTechGetStatus(cTechHCXPUnlockFort2German) == cTechStatusActive)) && (aiGetFallenExplorerID() < 1))
	  {
		  if (location == cInvalidVector)
         {
            createSimpleBuildPlan(cUnitTypeFortFrontier, 1, 99, true, cMilitaryEscrowID, kbBaseGetMainID(cMyID), 1);
            return;
         }
         gForwardBaseLocation = location;
         gForwardBaseBuildPlan = aiPlanCreate("Fort build plan ", cPlanBuild);
         aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanBuildingTypeID, 0, cUnitTypeFortFrontier);
         if ((kbGetAge() >= cvMaxAge) || (gRevolutionType != 0))
		 {
         aiPlanSetDesiredPriority(gForwardBaseBuildPlan, 95);
		 }
		 else
		 {
         aiPlanSetDesiredPriority(gForwardBaseBuildPlan, 25);
		 }
         // Military
         aiPlanSetMilitary(gForwardBaseBuildPlan, true);
         aiPlanSetEconomy(gForwardBaseBuildPlan, false);
         aiPlanSetEscrowID(gForwardBaseBuildPlan, cMilitaryEscrowID);
		 if (aiGetFallenExplorerID() < 1)
         aiPlanAddUnitType(gForwardBaseBuildPlan, cUnitTypeExplorer, 1, 1, 1);
			 else
      {
         aiPlanDestroy(gForwardBaseBuildPlan);
         gForwardBaseBuildPlan = -1;
         return;
      }
         // Instead of base ID or areas, use a center position
         aiPlanSetVariableVector(gForwardBaseBuildPlan, cBuildPlanCenterPosition, 0, location);
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanCenterPositionDistance, 0, 50.0);
         // Weight it to stay very close to center point.
         aiPlanSetVariableVector(gForwardBaseBuildPlan, cBuildPlanInfluencePosition, 0,
                                 location); // Position influence for center
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluencePositionDistance, 0, 100.0); // 100m range.
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluencePositionValue, 0,
                                100.0); // 100 points for center
         aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluencePositionFalloff, 0,
                              cBPIFalloffLinear); // Linear slope falloff
         // Add position influence for nearby towers
            aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypeFortFrontier);   // Don't build anywhere near another fort.
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitDistance, 0, 32.0);
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitValue, 0, 300.0);        // -20 points per fort
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffLinear);  // Cliff falloff// Add position influence for nearby towers
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypeFortFrontier);   // Don't build anywhere near another fort.
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitDistance, 0, 18.0);
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitValue, 0, -200.0);        // -20 points per fort
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffNone);
         aiPlanSetActive(gForwardBaseBuildPlan);
         // Chat to my allies
         sendStatement(cPlayerRelationAlly, cAICommPromptToAllyIWillBuildMilitaryBase, gForwardBaseLocation);
         gForwardBaseState = cForwardBaseStateBuilding;
         aiEcho(" ");
         aiEcho("    BUILDING FORWARD BASE, MOVING DEFEND PLANS TO COVER.");
         aiEcho("    PLANNED LOCATION IS " + gForwardBaseLocation);
         aiEcho(" ");
         if (gDefenseReflex == false)
            endDefenseReflex(); // Causes it to move to the new location
      }
   }
   else
	  if (cMyCiv == cCivDEInca)
	  {
   if (kbUnitCount(cMyID, cUnitTypedeIncaStrongholdTravois, cUnitStateAlive) > 0)
      { // Yes.
         // get the fort wagon, start a build plan, keep it defended
         if (location == cInvalidVector)
         {
            createSimpleBuildPlan(cUnitTypedeIncaStronghold, 1, 99, true, cMilitaryEscrowID, kbBaseGetMainID(cMyID), 1);
            return;
         }
         gForwardBaseLocation = location;
         gForwardBaseBuildPlan = aiPlanCreate("Fort build plan ", cPlanBuild);
         aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanBuildingTypeID, 0, cUnitTypedeIncaStronghold);
         aiPlanSetDesiredPriority(gForwardBaseBuildPlan, 99);
         // Military
         aiPlanSetMilitary(gForwardBaseBuildPlan, true);
         aiPlanSetEconomy(gForwardBaseBuildPlan, false);
         aiPlanSetEscrowID(gForwardBaseBuildPlan, cMilitaryEscrowID);
		 //if (kbUnitCount(cMyID, cUnitTypeFortWagon, cUnitStateAlive) > 0)
         aiPlanAddUnitType(gForwardBaseBuildPlan, cUnitTypedeIncaStrongholdTravois, 1, 1, 1);
		 // Instead of base ID or areas, use a center position
        aiPlanSetVariableVector(gForwardBaseBuildPlan, cBuildPlanCenterPosition, 0, location);
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanCenterPositionDistance, 0, 50.0);
         // Weight it to stay very close to center point.
         aiPlanSetVariableVector(gForwardBaseBuildPlan, cBuildPlanInfluencePosition, 0,
                                 location); // Position influence for center
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluencePositionDistance, 0, 100.0); // 100m range.
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluencePositionValue, 0,
                                100.0); // 100 points for center
         aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluencePositionFalloff, 0,
                              cBPIFalloffLinear); // Linear slope falloff
         // Add position influence for nearby towers
            aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypeFortFrontier);   // Don't build anywhere near another fort.
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitDistance, 0, 32.0);
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitValue, 0, 300.0);        // -20 points per fort
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffLinear);  // Cliff falloff// Add position influence for nearby towers
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypeFortFrontier);   // Don't build anywhere near another fort.
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitDistance, 0, 18.0);
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitValue, 0, -200.0);        // -20 points per fort
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffNone);
         aiPlanSetActive(gForwardBaseBuildPlan);
         // Chat to my allies
         sendStatement(cPlayerRelationAlly, cAICommPromptToAllyIWillBuildMilitaryBase, gForwardBaseLocation);
         gForwardBaseState = cForwardBaseStateBuilding;
         aiEcho(" ");
         aiEcho("    BUILDING FORWARD BASE, MOVING DEFEND PLANS TO COVER.");
         aiEcho("    PLANNED LOCATION IS " + gForwardBaseLocation);
         aiEcho(" ");
         if (gDefenseReflex == false)
            endDefenseReflex(); // Causes it to move to the new location
      }
	  else
		  if (numFortresses < kbGetBuildLimit(cMyID, cUnitTypedeIncaStronghold) && (kbGetAge() >= cAge3) &&(aiGetFallenExplorerID() < 1))
      { // Yes.
         // get the fort wagon, start a build plan, keep it defended
         if (location == cInvalidVector)
         {
            createSimpleBuildPlan(cUnitTypedeIncaStronghold, 1, 99, true, cMilitaryEscrowID, kbBaseGetMainID(cMyID), 1);
            return;
         }
         gForwardBaseLocation = location;
         gForwardBaseBuildPlan = aiPlanCreate("Fort build plan ", cPlanBuild);
         aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanBuildingTypeID, 0, cUnitTypedeIncaStronghold);
         if ((kbGetAge() >= cvMaxAge) || (gRevolutionType != 0))
		 {
         aiPlanSetDesiredPriority(gForwardBaseBuildPlan, 95);
		 }
		 else
		 {
         aiPlanSetDesiredPriority(gForwardBaseBuildPlan, 50);
		 }
         // Military
         aiPlanSetMilitary(gForwardBaseBuildPlan, true);
         aiPlanSetEconomy(gForwardBaseBuildPlan, false);
         aiPlanSetEscrowID(gForwardBaseBuildPlan, cMilitaryEscrowID);
		 //if (kbUnitCount(cMyID, cUnitTypeFortWagon, cUnitStateAlive) > 0)
		 if (aiGetFallenExplorerID() < 1)
         aiPlanAddUnitType(gForwardBaseBuildPlan, cUnitTypedeIncaWarChief, 1, 1, 1);
			 else
      {
         aiPlanDestroy(gForwardBaseBuildPlan);
         gForwardBaseBuildPlan = -1;
         return;
      }
		 // Instead of base ID or areas, use a center position
         aiPlanSetVariableVector(gForwardBaseBuildPlan, cBuildPlanCenterPosition, 0, location);
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanCenterPositionDistance, 0, 50.0);
         // Weight it to stay very close to center point.
         aiPlanSetVariableVector(gForwardBaseBuildPlan, cBuildPlanInfluencePosition, 0,
                                 location); // Position influence for center
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluencePositionDistance, 0, 100.0); // 100m range.
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluencePositionValue, 0,
                                100.0); // 100 points for center
         aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluencePositionFalloff, 0,
                              cBPIFalloffLinear); // Linear slope falloff
         // Add position influence for nearby towers
            aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypeFortFrontier);   // Don't build anywhere near another fort.
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitDistance, 0, 32.0);
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitValue, 0, 300.0);        // -20 points per fort
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffLinear);  // Cliff falloff// Add position influence for nearby towers
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypeFortFrontier);   // Don't build anywhere near another fort.
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitDistance, 0, 18.0);
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitValue, 0, -200.0);        // -20 points per fort
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffNone);
         aiPlanSetActive(gForwardBaseBuildPlan);
         // Chat to my allies
         sendStatement(cPlayerRelationAlly, cAICommPromptToAllyIWillBuildMilitaryBase, gForwardBaseLocation);
         gForwardBaseState = cForwardBaseStateBuilding;
         aiEcho(" ");
         aiEcho("    BUILDING FORWARD BASE, MOVING DEFEND PLANS TO COVER.");
         aiEcho("    PLANNED LOCATION IS " + gForwardBaseLocation);
         aiEcho(" ");
         if (gDefenseReflex == false)
            endDefenseReflex(); // Causes it to move to the new location
      }
	  }
      break;
   }
   case cForwardBaseStateBuilding:
   {
      fortUnitID = getUnitByLocation(cUnitTypeFortFrontier, cMyID, cUnitStateAlive, gForwardBaseLocation, 100.0);
	  if (cMyCiv == cCivDEInca)
      fortUnitID = getUnitByLocation(cUnitTypedeIncaStronghold, cMyID, cUnitStateAlive, gForwardBaseLocation, 100.0);
      if (fortUnitID < 0)
      {
         // check for other military buildings.
         buildingQuery =
             createSimpleUnitQuery(cUnitTypeMilitaryBuilding, cMyID, cUnitStateAlive, gForwardBaseLocation, 100.0);
         numberFound = kbUnitQueryExecute(buildingQuery);
         numberMilitaryBuildings = xsArrayGetSize(gMilitaryBuildings);
         for (i = 0; < numberFound)
         {
            buildingID = kbUnitQueryGetResult(buildingQuery, i);
            for (j = 0; < numberMilitaryBuildings)
            {
               if (kbUnitIsType(buildingID, xsArrayGetInt(gMilitaryBuildings, j)) == true)
               {
                  fortUnitID = buildingID;
                  break;
               }
            }
            if (fortUnitID >= 0)
               break;
         }
      }
      if (fortUnitID >= 0)
      { // Building exists and is complete, go to state Active
         if (kbUnitGetBaseID(fortUnitID) >= 0)
         { // Base has been created for it.
            gForwardBaseState = cForwardBaseStateActive;
            gForwardBaseID = kbUnitGetBaseID(fortUnitID);
            gForwardBaseLocation = kbUnitGetPosition(fortUnitID);
            gForwardBaseUpTime = xsGetTime();
            gForwardBaseShouldDefend = kbUnitIsType(fortUnitID, cUnitTypeFortFrontier);
	        if (cMyCiv == cCivDEInca)
            gForwardBaseShouldDefend = kbUnitIsType(fortUnitID, cUnitTypedeIncaStronghold);
            aiEcho("Forward base location is " + gForwardBaseLocation + ", Base ID is " + gForwardBaseID +
                   ", Unit ID is " + fortUnitID);
            // Tell the attack goal where to go.
             //aiPlanSetBaseID(gMainAttackGoal, gForwardBaseID);
            aiEcho(" ");
            aiEcho("    FORWARD BASE COMPLETED, GOING TO STATE ACTIVE, MOVING ATTACK GOAL.");
            aiEcho(" ");
         }
         else
         {
            aiEcho(" ");
            aiEcho("    FORT COMPLETE, WAITING FOR FORWARD BASE ID.");
            aiEcho(" ");
         }
      }
      else // Check if plan still exists. If not, go back to state 'none'.
      {
         if (aiPlanGetState(gForwardBaseBuildPlan) < 0)
         { // It failed?
            gForwardBaseState = cForwardBaseStateNone;
            gForwardBaseLocation = cInvalidVector;
            gForwardBaseID = -1;
            gForwardBaseBuildPlan = -1;
            gForwardBaseShouldDefend = false;
            aiEcho(" ");
            aiEcho("    FORWARD BASE PLAN FAILED, RETURNING TO STATE NONE.");
            aiEcho(" ");
         }
      }
      break;
   }
   case cForwardBaseStateActive:
   { // Normal state.  If fort is destroyed and base overrun, bail.
      fortUnitID = getUnitByLocation(cUnitTypeFortFrontier, cMyID, cUnitStateAlive, gForwardBaseLocation, 50.0);
	  if (cMyCiv == cCivDEInca)
      fortUnitID = getUnitByLocation(cUnitTypedeIncaStronghold, cMyID, cUnitStateAlive, gForwardBaseLocation, 50.0);
      if (fortUnitID < 0)
      {
         // check for other military buildings.
         buildingQuery =
             createSimpleUnitQuery(cUnitTypeMilitaryBuilding, cMyID, cUnitStateAlive, gForwardBaseLocation, 100.0);
         numberFound = kbUnitQueryExecute(buildingQuery);
         numberMilitaryBuildings = xsArrayGetSize(gMilitaryBuildings);
         for (i = 0; < numberFound)
         {
            buildingID = kbUnitQueryGetResult(buildingQuery, i);
            for (j = 0; < numberMilitaryBuildings)
            {
               if (kbUnitIsType(buildingID, xsArrayGetInt(gMilitaryBuildings, j)) == true)
               {
                  fortUnitID = buildingID;
                  break;
               }
            }
            if (fortUnitID >= 0)
               break;
         }
      }
      if (fortUnitID < 0)
      {
         // Fort is missing, is base still OK?
         if (((gDefenseReflexBaseID == gForwardBaseID) && (gDefenseReflexPaused == true)) ||
             (kbBaseGetNumberUnits(cMyID, gForwardBaseID, cPlayerRelationSelf, cUnitTypeBuilding) <
              1)) // Forward base under attack and overwhelmed, or gone.
         {        // No, not OK.  Get outa Dodge.
            gForwardBaseState = cForwardBaseStateNone;
            gForwardBaseID = -1;
            gForwardBaseLocation = cInvalidVector;
            gForwardBaseShouldDefend = false;
            // Tell the attack goal to go back to the main base.
             //aiPlanSetBaseID(gMainAttackGoal, kbBaseGetMainID(cMyID));
            //endDefenseReflex();
            aiEcho(" ");
            aiEcho("    ABANDONING FORWARD BASE, RETREATING TO MAIN BASE.");
            aiEcho(" ");
         }
      }
      break;
   }
   }
	  if (((gForwardBaseState == cForwardBaseStateActive) || (gForwardBaseState == cForwardBaseStateBuilding))) //&& (numFortresses < kbGetBuildLimit(cMyID, cUnitTypeFortFrontier)))
		  {
			  if (kbUnitCount(cMyID, cUnitTypeFortWagon, cUnitStateAlive) > 0)
      { // Yes.
         // get the fort wagon, start a build plan, keep it defended
         if (location == cInvalidVector)
         {
            createSimpleBuildPlan(cUnitTypeFortFrontier, 1, 99, true, cMilitaryEscrowID, kbBaseGetMainID(cMyID), 1);
            return;
         }
         gForwardBaseLocation = location;
         gForwardBaseBuildPlan = aiPlanCreate("Fort build plan ", cPlanBuild);
         aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanBuildingTypeID, 0, cUnitTypeFortFrontier);
         aiPlanSetDesiredPriority(gForwardBaseBuildPlan, 99);
         // Military
         aiPlanSetMilitary(gForwardBaseBuildPlan, true);
         aiPlanSetEconomy(gForwardBaseBuildPlan, false);
         aiPlanSetEscrowID(gForwardBaseBuildPlan, cMilitaryEscrowID);
         aiPlanAddUnitType(gForwardBaseBuildPlan, cUnitTypeFortWagon, 1, 1, 1);
         // Instead of base ID or areas, use a center position
         aiPlanSetVariableVector(gForwardBaseBuildPlan, cBuildPlanCenterPosition, 0, location);
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanCenterPositionDistance, 0, 50.0);
         // Weight it to stay very close to center point.
         aiPlanSetVariableVector(gForwardBaseBuildPlan, cBuildPlanInfluencePosition, 0,
                                 location); // Position influence for center
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluencePositionDistance, 0, 100.0); // 100m range.
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluencePositionValue, 0,
                                100.0); // 100 points for center
         aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluencePositionFalloff, 0,
                              cBPIFalloffLinear); // Linear slope falloff
         // Add position influence for nearby towers
            aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypeFortFrontier);   // Don't build anywhere near another fort.
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitDistance, 0, 32.0);
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitValue, 0, 300.0);        // -20 points per fort
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffLinear);  // Cliff falloff// Add position influence for nearby towers
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypeFortFrontier);   // Don't build anywhere near another fort.
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitDistance, 0, 18.0);
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitValue, 0, -200.0);        // -20 points per fort
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffNone);
         aiPlanSetActive(gForwardBaseBuildPlan);
         gForwardBaseState = cForwardBaseStateBuilding;
         aiEcho(" ");
         aiEcho("    BUILDING FORWARD BASE, MOVING DEFEND PLANS TO COVER.");
         aiEcho("    PLANNED LOCATION IS " + gForwardBaseLocation);
         aiEcho(" ");
         if (gDefenseReflex == false)
            endDefenseReflex(); // Causes it to move to the new location
      }
	  else
		  if (numFortresses < kbGetBuildLimit(cMyID, cUnitTypeFortFrontier))
		  {
	  if ((cMyCiv == cCivDEAmericans) && (kbGetAge() >= cAge3))
	  {
		   if (location == cInvalidVector)
         {
            createSimpleBuildPlan(cUnitTypeFortFrontier, 1, 99, true, cMilitaryEscrowID, kbBaseGetMainID(cMyID), 1);
            return;
         }
         gForwardBaseLocation = location;
         gForwardBaseBuildPlan = aiPlanCreate("Fort build plan ", cPlanBuild);
         aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanBuildingTypeID, 0, cUnitTypeFortFrontier);
         if ((kbGetAge() >= cvMaxAge) || (gRevolutionType != 0))
		 {
         aiPlanSetDesiredPriority(gForwardBaseBuildPlan, 95);
		 }
		 else
		 {
         aiPlanSetDesiredPriority(gForwardBaseBuildPlan, 25);
		 }
         // Military
         aiPlanSetMilitary(gForwardBaseBuildPlan, true);
         aiPlanSetEconomy(gForwardBaseBuildPlan, false);
         aiPlanSetEscrowID(gForwardBaseBuildPlan, cMilitaryEscrowID);
		 if (aiGetFallenExplorerID() < 1)
         aiPlanAddUnitType(gForwardBaseBuildPlan, cUnitTypedeGeneral, 1, 1, 1);
			 else
      {
         aiPlanDestroy(gForwardBaseBuildPlan);
         gForwardBaseBuildPlan = -1;
         return;
      }
         // Instead of base ID or areas, use a center position
         aiPlanSetVariableVector(gForwardBaseBuildPlan, cBuildPlanCenterPosition, 0, location);
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanCenterPositionDistance, 0, 50.0);
         // Weight it to stay very close to center point.
         aiPlanSetVariableVector(gForwardBaseBuildPlan, cBuildPlanInfluencePosition, 0,
                                 location); // Position influence for center
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluencePositionDistance, 0, 100.0); // 100m range.
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluencePositionValue, 0,
                                100.0); // 100 points for center
         aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluencePositionFalloff, 0,
                              cBPIFalloffLinear); // Linear slope falloff
         // Add position influence for nearby towers
            aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypeFortFrontier);   // Don't build anywhere near another fort.
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitDistance, 0, 32.0);
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitValue, 0, 300.0);        // -20 points per fort
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffLinear);  // Cliff falloff// Add position influence for nearby towers
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypeFortFrontier);   // Don't build anywhere near another fort.
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitDistance, 0, 18.0);
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitValue, 0, -200.0);        // -20 points per fort
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffNone);
         aiPlanSetActive(gForwardBaseBuildPlan);
      }
	  else
	  if ((kbTechGetStatus(cTechHCXPNationalRedoubt) == cTechStatusActive))
	  {
		   if (location == cInvalidVector)
         {
            createSimpleBuildPlan(cUnitTypeFortFrontier, 1, 99, true, cMilitaryEscrowID, kbBaseGetMainID(cMyID), 1);
            return;
         }
         gForwardBaseLocation = location;
         gForwardBaseBuildPlan = aiPlanCreate("Fort build plan ", cPlanBuild);
         aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanBuildingTypeID, 0, cUnitTypeFortFrontier);
         if ((kbGetAge() >= cvMaxAge) || (gRevolutionType != 0))
		 {
         aiPlanSetDesiredPriority(gForwardBaseBuildPlan, 95);
		 }
		 else
		 {
         aiPlanSetDesiredPriority(gForwardBaseBuildPlan, 25);
		 }
         // Military
         aiPlanSetMilitary(gForwardBaseBuildPlan, true);
         aiPlanSetEconomy(gForwardBaseBuildPlan, false);
         aiPlanSetEscrowID(gForwardBaseBuildPlan, cMilitaryEscrowID);
         aiPlanAddUnitType(gForwardBaseBuildPlan, cUnitTypeMusketeer, 8, 8, 8);
		 // Instead of base ID or areas, use a center position
         aiPlanSetVariableVector(gForwardBaseBuildPlan, cBuildPlanCenterPosition, 0, location);
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanCenterPositionDistance, 0, 50.0);
         // Weight it to stay very close to center point.
         aiPlanSetVariableVector(gForwardBaseBuildPlan, cBuildPlanInfluencePosition, 0,
                                 location); // Position influence for center
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluencePositionDistance, 0, 100.0); // 100m range.
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluencePositionValue, 0,
                                100.0); // 100 points for center
         aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluencePositionFalloff, 0,
                              cBPIFalloffLinear); // Linear slope falloff
         // Add position influence for nearby towers
            aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypeFortFrontier);   // Don't build anywhere near another fort.
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitDistance, 0, 32.0);
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitValue, 0, 300.0);        // -20 points per fort
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffLinear);  // Cliff falloff// Add position influence for nearby towers
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypeFortFrontier);   // Don't build anywhere near another fort.
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitDistance, 0, 18.0);
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitValue, 0, -200.0);        // -20 points per fort
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffNone);
         aiPlanSetActive(gForwardBaseBuildPlan);
      }
	  else
		  //if (planID < 0)
		  //{
	  if ((kbTechGetStatus(cTechHCXPUnlockFort2) == cTechStatusActive) || (kbTechGetStatus(cTechHCXPUnlockFort2German) == cTechStatusActive))
	  {
		  if (location == cInvalidVector)
         {
            createSimpleBuildPlan(cUnitTypeFortFrontier, 1, 99, true, cMilitaryEscrowID, kbBaseGetMainID(cMyID), 1);
            return;
         }
         gForwardBaseLocation = location;
         gForwardBaseBuildPlan = aiPlanCreate("Fort build plan ", cPlanBuild);
         aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanBuildingTypeID, 0, cUnitTypeFortFrontier);
         if ((kbGetAge() >= cvMaxAge) || (gRevolutionType != 0))
		 {
         aiPlanSetDesiredPriority(gForwardBaseBuildPlan, 95);
		 }
		 else
		 {
         aiPlanSetDesiredPriority(gForwardBaseBuildPlan, 25);
		 }
         // Military
         aiPlanSetMilitary(gForwardBaseBuildPlan, true);
         aiPlanSetEconomy(gForwardBaseBuildPlan, false);
         aiPlanSetEscrowID(gForwardBaseBuildPlan, cMilitaryEscrowID);
		 if (aiGetFallenExplorerID() < 1)
         aiPlanAddUnitType(gForwardBaseBuildPlan, cUnitTypeExplorer, 1, 1, 1);
			 else
      {
         aiPlanDestroy(gForwardBaseBuildPlan);
         gForwardBaseBuildPlan = -1;
         return;
      }
         // Instead of base ID or areas, use a center position
         aiPlanSetVariableVector(gForwardBaseBuildPlan, cBuildPlanCenterPosition, 0, location);
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanCenterPositionDistance, 0, 50.0);
         // Weight it to stay very close to center point.
         aiPlanSetVariableVector(gForwardBaseBuildPlan, cBuildPlanInfluencePosition, 0,
                                 location); // Position influence for center
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluencePositionDistance, 0, 100.0); // 100m range.
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluencePositionValue, 0,
                                100.0); // 100 points for center
         aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluencePositionFalloff, 0,
                              cBPIFalloffLinear); // Linear slope falloff
         // Add position influence for nearby towers
            aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypeFortFrontier);   // Don't build anywhere near another fort.
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitDistance, 0, 32.0);
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitValue, 0, 300.0);        // -20 points per fort
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffLinear);  // Cliff falloff// Add position influence for nearby towers
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypeFortFrontier);   // Don't build anywhere near another fort.
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitDistance, 0, 18.0);
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitValue, 0, -200.0);        // -20 points per fort
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffNone);
         aiPlanSetActive(gForwardBaseBuildPlan);
      }
		  }
   }
		  //}
		  if (cMyCiv == cCivDEInca)
	  {
   if (kbUnitCount(cMyID, cUnitTypedeIncaStrongholdTravois, cUnitStateAlive) > 0)
      { // Yes.
         // get the fort wagon, start a build plan, keep it defended
         if (location == cInvalidVector)
         {
            createSimpleBuildPlan(cUnitTypedeIncaStronghold, 1, 99, true, cMilitaryEscrowID, kbBaseGetMainID(cMyID), 1);
            return;
         }
         gForwardBaseLocation = location;
         gForwardBaseBuildPlan = aiPlanCreate("Fort build plan ", cPlanBuild);
         aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanBuildingTypeID, 0, cUnitTypedeIncaStronghold);
         aiPlanSetDesiredPriority(gForwardBaseBuildPlan, 99);
         // Military
         aiPlanSetMilitary(gForwardBaseBuildPlan, true);
         aiPlanSetEconomy(gForwardBaseBuildPlan, false);
         aiPlanSetEscrowID(gForwardBaseBuildPlan, cMilitaryEscrowID);
		 //if (kbUnitCount(cMyID, cUnitTypeFortWagon, cUnitStateAlive) > 0)
         aiPlanAddUnitType(gForwardBaseBuildPlan, cUnitTypedeIncaStrongholdTravois, 1, 1, 1);
		 // Instead of base ID or areas, use a center position
         aiPlanSetVariableVector(gForwardBaseBuildPlan, cBuildPlanCenterPosition, 0, location);
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanCenterPositionDistance, 0, 50.0);
         // Weight it to stay very close to center point.
         aiPlanSetVariableVector(gForwardBaseBuildPlan, cBuildPlanInfluencePosition, 0,
                                 location); // Position influence for center
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluencePositionDistance, 0, 100.0); // 100m range.
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluencePositionValue, 0,
                                100.0); // 100 points for center
         aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluencePositionFalloff, 0,
                              cBPIFalloffLinear); // Linear slope falloff
         // Add position influence for nearby towers
            aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypeFortFrontier);   // Don't build anywhere near another fort.
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitDistance, 0, 32.0);
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitValue, 0, 300.0);        // -20 points per fort
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffLinear);  // Cliff falloff// Add position influence for nearby towers
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypeFortFrontier);   // Don't build anywhere near another fort.
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitDistance, 0, 18.0);
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitValue, 0, -200.0);        // -20 points per fort
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffNone);
         aiPlanSetActive(gForwardBaseBuildPlan);
      }
	  else
		  if (numFortresses < kbGetBuildLimit(cMyID, cUnitTypedeIncaStronghold) && (kbGetAge() >= cAge3) &&(aiGetFallenExplorerID() < 1))
      { // Yes.
         // get the fort wagon, start a build plan, keep it defended
         if (location == cInvalidVector)
         {
            createSimpleBuildPlan(cUnitTypedeIncaStronghold, 1, 99, true, cMilitaryEscrowID, kbBaseGetMainID(cMyID), 1);
            return;
         }
         gForwardBaseLocation = location;
         gForwardBaseBuildPlan = aiPlanCreate("Fort build plan ", cPlanBuild);
         aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanBuildingTypeID, 0, cUnitTypedeIncaStronghold);
         if ((kbGetAge() >= cvMaxAge) || (gRevolutionType != 0))
		 {
         aiPlanSetDesiredPriority(gForwardBaseBuildPlan, 95);
		 }
		 else
		 {
         aiPlanSetDesiredPriority(gForwardBaseBuildPlan, 50);
		 }
         // Military
         aiPlanSetMilitary(gForwardBaseBuildPlan, true);
         aiPlanSetEconomy(gForwardBaseBuildPlan, false);
         aiPlanSetEscrowID(gForwardBaseBuildPlan, cMilitaryEscrowID);
		 //if (kbUnitCount(cMyID, cUnitTypeFortWagon, cUnitStateAlive) > 0)
		 if (aiGetFallenExplorerID() < 1)
         aiPlanAddUnitType(gForwardBaseBuildPlan, cUnitTypedeIncaWarChief, 1, 1, 1);
			 else
      {
         aiPlanDestroy(gForwardBaseBuildPlan);
         gForwardBaseBuildPlan = -1;
         return;
      }
		 // Instead of base ID or areas, use a center position
         aiPlanSetVariableVector(gForwardBaseBuildPlan, cBuildPlanCenterPosition, 0, location);
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanCenterPositionDistance, 0, 50.0);
         // Weight it to stay very close to center point.
         aiPlanSetVariableVector(gForwardBaseBuildPlan, cBuildPlanInfluencePosition, 0,
                                 location); // Position influence for center
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluencePositionDistance, 0, 100.0); // 100m range.
         aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluencePositionValue, 0,
                                100.0); // 100 points for center
         aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluencePositionFalloff, 0,
                              cBPIFalloffLinear); // Linear slope falloff
         // Add position influence for nearby towers
            aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypeFortFrontier);   // Don't build anywhere near another fort.
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitDistance, 0, 32.0);
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitValue, 0, 300.0);        // -20 points per fort
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffLinear);  // Cliff falloff// Add position influence for nearby towers
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypeFortFrontier);   // Don't build anywhere near another fort.
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitDistance, 0, 18.0);
			aiPlanSetVariableFloat(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitValue, 0, -200.0);        // -20 points per fort
			aiPlanSetVariableInt(gForwardBaseBuildPlan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffNone);
         aiPlanSetActive(gForwardBaseBuildPlan);
      }
	  }
}

//==============================================================================
// rule wagonMonitor
//==============================================================================
rule wagonMonitor
inactive
minInterval 10
{
   int wagonQueryID = createSimpleUnitQuery(cUnitTypeAbstractWagon, cMyID, cUnitStateAlive);
   int numberFound = kbUnitQueryExecute(wagonQueryID);
   if (numberFound == 0)
   {
      debugBuildings("We didn't find any idle Wagons without a Build Plan");
      return;
   }
   
   int planID = -1;
   int numPlans = aiPlanGetActiveCount();
   int wagonType = -1;
   int wagon = -1;
   int age = kbGetAge();
   int mainBaseID = kbBaseGetMainID(cMyID);
   int buildLimit = -1;
   int buildingCount = -1;
   int buildingType = -1;

   // First check existing Build Plans and find if we have Wagons to build.
   for (i = 0; < numPlans)
   {
      planID = aiPlanGetIDByActiveIndex(i);
      if (aiPlanGetType(planID) != cPlanBuild)
      {
         continue;
      }
      if (aiPlanGetState(planID) == cPlanStateBuild)
      {
         continue;
      }

      buildingType = aiPlanGetVariableInt(planID, cBuildPlanBuildingTypeID, 0);
      wagonType = findWagonToBuild(buildingType);
      if (wagonType >= 0)
      {
         for (j = 0; < numberFound)
         {
            wagon = kbUnitQueryGetResult(wagonQueryID, j);
            if (kbUnitGetPlanID(wagon) >= 0)
            {
               continue;
            }
            if (kbUnitIsType(wagon, wagonType) == false)
            {
               continue;
            }
            // Remove Villagers from the plan if there are some.
            if (aiPlanGetNumberUnits(planID, gEconUnit) > 0)
            {
               aiPlanAddUnitType(planID, gEconUnit, 0, 0, 0);
            }

            // If this is a farm, the plan should be done when building is fully built.
            if (buildingType == gFarmUnit || buildingType == gPlantationUnit || buildingType == cUnitTypedeFurTrade)
               aiPlanSetVariableBool(planID, cBuildPlanDoneWhenFoundationPlaced, 0, false);

            aiPlanAddUnitType(planID, wagonType, 1, 1, 1);
            aiPlanAddUnit(planID, wagon);
            debugBuildings("Added an idle " + kbGetProtoUnitName(kbUnitGetProtoUnitID(wagon)) + " with ID: " 
               + wagon + " to the existing Build Plan ID: " + planID);
            break;
         }
      }
   }

   // Pick up idle Wagons and let them train something on their own without existing Build Plans.
   for (i = 0; < numberFound)
   {
      wagon = kbUnitQueryGetResult(wagonQueryID, i);
      if (kbUnitGetPlanID(wagon) >= 0)
      {
         continue;
      }
      wagonType = kbUnitGetProtoUnitID(wagon);
      buildingType = -1;

      debugBuildings("Idle Wagon's name is: " + kbGetProtoUnitName(wagonType) + " with ID: " + wagon);

      if ((aiGetGameMode() == cGameModeEmpireWars) && (wagonType == cUnitTypedeImperialWagon))
      {
         if (cMyCiv == cCivXPAztec)
         {
            if ((age >= cAge3) &&
                ((kbUnitCount(cMyID, cUnitTypeNoblesHut, cUnitStateAlive) +
                  aiPlanGetNumberByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeNoblesHut, true)) <
                 kbGetBuildLimit(cMyID, cUnitTypeNoblesHut)))
            {
               buildingType = cUnitTypeNoblesHut;
            }
            else if (
                (kbUnitCount(cMyID, cUnitTypeWarHut, cUnitStateAlive) +
                 aiPlanGetNumberByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeWarHut, true)) <
                kbGetBuildLimit(cMyID, cUnitTypeWarHut))
            {
               buildingType = cUnitTypeWarHut;
            }
         }
         else if (
             (civIsAfrican() == true) &&
             ((kbUnitCount(cMyID, cUnitTypedePalace, cUnitStateAlive) +
               aiPlanGetNumberByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypedePalace, true)) <
              kbGetBuildLimit(cMyID, cUnitTypedePalace)))
         {
            buildingType = cUnitTypedePalace;
         }
         else if (
             (cMyCiv != cCivXPSioux) &&
             ((kbUnitCount(cMyID, gTowerUnit, cUnitStateABQ) +
               aiPlanGetNumberByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, gTowerUnit, true)) <
              kbGetBuildLimit(cMyID, gTowerUnit)))
         {
            buildingType = gTowerUnit;
         }
         else if (
             (cMyCiv == cCivXPSioux) &&
             ((kbUnitCount(cMyID, cUnitTypeWarHut, cUnitStateABQ) +
               aiPlanGetNumberByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeWarHut, true)) <
              kbGetBuildLimit(cMyID, cUnitTypeWarHut)))
         {
            buildingType = cUnitTypeWarHut;
         }

         if (buildingType == -1) // All of the buildings above are probably at their build limit so do something else.
         {
            int arraySize = xsArrayGetSize(gMilitaryBuildings);
            int lowestCount = 1000;
            int buildingPUID = -1;

            for (j = 0; < arraySize)
            {
               buildingPUID = xsArrayGetInt(gMilitaryBuildings, j);
               buildingCount = kbUnitCount(cMyID, buildingPUID, cUnitStateABQ) +
                               aiPlanGetNumberByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, buildingPUID, true);
               if (buildingCount < lowestCount)
               {
                  buildLimit = kbGetBuildLimit(cMyID, buildingPUID);
                  if ((buildingCount < buildLimit) || (buildLimit == -1))
                  {
                     lowestCount = buildingCount;
                     buildingType = buildingPUID;
                  }
               }
            }
         }

         if (buildingType != -1)
         {
            // Make the actual Build Plan and go to next iteration.
            planID = createSimpleBuildPlan(buildingType, 1, 75, true, cEconomyEscrowID, mainBaseID, 0);
            aiPlanAddUnitType(planID, wagonType, 1, 1, 1);
            aiPlanAddUnit(planID, wagon);
            debugBuildings("FAILSAFE: Added an idle " + kbGetProtoUnitName(cUnitTypedeImperialWagon) + 
               " with ID: " + wagon + " to a new Build Plan ID: " + planID);
            continue;
         }
      }

      switch (wagonType)
      {
      // Vanilla.
      case cUnitTypeBankWagon:
      {
         if (cMyCiv == cCivDutch)
         {
            buildingType = cUnitTypeBank;
         }
         else
         {
            buildingType = cUnitTypeypBankAsian;
         }
         break;
      }
      case cUnitTypeCoveredWagon:
      {
         buildingType = cUnitTypeTownCenter;
         break;
      }
      case cUnitTypeOutpostWagon:
      {
         if (civIsAfrican() == true)
         {
            buildingType = cUnitTypedeTower;
         }
         else
         {
            buildingType = cUnitTypeOutpost;
         }
         break;
      }
      // FortWagon is handled by forwardBaseManager.
      case cUnitTypeFactoryWagon:
      {
         buildingType = cUnitTypeFactory;
         break;
      }

      // The War Chiefs.
      case cUnitTypeWarHutTravois:
      {
         buildingType = cUnitTypeWarHut;
         break;
      }
      case cUnitTypeFarmTravois:
      {
         buildingType = cUnitTypeFarm;
         break;
      }
      case cUnitTypeNoblesHutTravois:
      {
         buildingType = cUnitTypeNoblesHut;
         break;
      }
      // xpBuilder is handled by xpBuilderMonitor.

      // The Asian Dynasties.
      // TradingPostTravois is handled by tradingPostMonitor.
      case cUnitTypeYPVillageWagon:
      {
         buildingType = cUnitTypeypVillage;
         break;
      }
      case cUnitTypeYPRicePaddyWagon:
      {
         buildingType = cUnitTypeypRicePaddy;
         break;
      }
      case cUnitTypeypArsenalWagon:
      {
         if ((cMyCiv == cCivJapanese) || (cMyCiv == cCivSPCJapanese) || (cMyCiv == cCivSPCJapaneseEnemy))
         {
            buildingType = cUnitTypeypArsenalAsian;
         }
         else
         {
            buildingType = cUnitTypeArsenal;
         }
         break;
      }
      case cUnitTypeYPCastleWagon:
      {
         buildingType = cUnitTypeypCastle;
         break;
      }
      case cUnitTypeYPDojoWagon:
      {
         buildingType = cUnitTypeypDojo;
         break;
      }
      case cUnitTypeypShrineWagon:
      {
         buildingType = cUnitTypeypShrineJapanese;
         break;
      }
      case cUnitTypeYPBerryWagon1:
      {
         buildingType = cUnitTypeypBerryBuilding;
         break;
      }
      case cUnitTypeYPDockWagon:
      {
         buildingType = gDockUnit;
         break;
      }
      case cUnitTypeYPGroveWagon:
      {
         buildingType = cUnitTypeypGroveBuilding;
         break;
      }
      case cUnitTypeypMarketWagon:
      {
         buildingType = cUnitTypeypTradeMarketAsian;
         break;
      }
      case cUnitTypeypTradingPostWagon:
      {
         if (cMyCiv == cCivDEAmericans)
         {
            if (kbTechGetStatus(cTechDEHCArkansasPost) == cTechStatusActive)
            {
               if (kbUnitCount(cMyID, cUnitTypeMarket, cUnitStateABQ) +
                       aiPlanGetNumberByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeMarket) <
                   1)
               {
                  buildingType = cUnitTypeMarket;
               }
               else if (
                   kbUnitCount(cMyID, cUnitTypeChurch, cUnitStateABQ) +
                       aiPlanGetNumberByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeChurch) <
                   1)
               {
                  buildingType = cUnitTypeChurch;
               }
               else if (
                   kbUnitCount(cMyID, cUnitTypeSaloon, cUnitStateABQ) +
                       aiPlanGetNumberByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeSaloon) <
                   1)
               {
                  buildingType = cUnitTypeSaloon;
               }
            }
         }
         break;
      }
      case cUnitTypeypChurchWagon:
      {
         if (civIsAsian())
         {
            buildingType = cUnitTypeypChurch;
         }
         else if (cMyCiv == cCivDEMexicans)
         {
            buildingType = cUnitTypedeCathedral;
         }
         else
         {
            buildingType = cUnitTypeChurch;
         }
         break;
      }
      case cUnitTypeYPMonasteryWagon:
      {
         buildingType = cUnitTypeypMonastery;
         break;
      }
      case cUnitTypeYPMilitaryRickshaw:
      {
         if (kbUnitCount(cMyID, cUnitTypeypBarracksJapanese, cUnitStateABQ) <
             kbUnitCount(cMyID, cUnitTypeypStableJapanese, cUnitStateABQ))
         {
            buildingType = cUnitTypeypBarracksJapanese;
         }
         else
         {
            buildingType = cUnitTypeypStableJapanese;
         }
         break;
      }
      case cUnitTypeypBankWagon:
      {
         buildingType = cUnitTypeypBankAsian;
         break;
      }
      // xpBuilderStart is handled by xpBuilderMonitor.
      case cUnitTypeYPSacredFieldWagon:
      {
         buildingType = cUnitTypeypSacredField;
         break;
      }
      case cUnitTypeypBlockhouseWagon:
      {
         buildingType = cUnitTypeBlockhouse;
         break;
      }

      // Definitive Edition.
      case cUnitTypedeIncaStrongholdTravois:
      {
         buildingType = cUnitTypedeIncaStronghold;
         break;
      }
      case cUnitTypedeBuilderInca:
      {
         if ((age >= cAge3) &&
             (kbUnitCount(cMyID, cUnitTypedeKallanka, cUnitStateABQ) +
                  aiPlanGetNumberByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypedeKallanka) <
              kbGetBuildLimit(cMyID, cUnitTypedeKallanka)))
         {
            buildingType = cUnitTypedeKallanka;
         }
         else if (
             kbUnitCount(cMyID, cUnitTypeWarHut, cUnitStateABQ) +
                 aiPlanGetNumberByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeWarHut) <
             kbGetBuildLimit(cMyID, cUnitTypeWarHut))
         {
            buildingType = cUnitTypeWarHut;
         }
         else // Farms have no build limit.
         {
            buildingType = cUnitTypeFarm;
         }
         break;
      }
      case cUnitTypedeEmbassyTravois:
      {
         buildingType = cUnitTypeNativeEmbassy;
         break;
      }
      case cUnitTypedeMilitaryWagon:
      {
         if (civIsEuropean() == true)
         {
            int barracks = cUnitTypeBarracks;
            if (cMyCiv == cCivRussians)
            {
               barracks = cUnitTypeBlockhouse;
            }
            int barracksCount = kbUnitCount(cMyID, barracks, cUnitStateABQ);
            int stableCount = kbUnitCount(cMyID, cUnitTypeStable, cUnitStateABQ);
            int artilleryDepotCount = kbUnitCount(cMyID, cUnitTypeArtilleryDepot, cUnitStateABQ);
            if ((barracksCount < stableCount) || (barracksCount < artilleryDepotCount) || (barracksCount == 0))
            {
               buildingType = barracks;
            }
            else if ((stableCount < artilleryDepotCount) || (stableCount == 0))
            {
               buildingType = cUnitTypeStable;
            }
            else
            {
               buildingType = cUnitTypeArtilleryDepot;
            }
            break;
         }
         // The logic below only happens once during EW when you get this wagon after reaching the Commerce age.
         else if (civIsNative() == true)
         {
            buildingType = cUnitTypeWarHut;
            break;
         }
         else if (civIsAfrican() == true)
         {
            buildingType = cUnitTypedePalace;
            break;
         }
         else // Asian.
         {
            buildingType = cUnitTypeypCastle;
            break;
         }
      }
      // deHomesteadWagon has no defaults and will only be taken by farm/plantation plans.
      case cUnitTypedeProspectorWagon:
      {
         buildingType = cUnitTypedeMineCopperBuildable;
         break;
      }
      case cUnitTypedeTorpWagon:
      {
         if (cMyCiv == cCivDESwedish)
         {
            buildingType = cUnitTypedeTorp;
         }
         else
         {
            buildingType = cUnitTypedeTorpGeneric;
         }
         break;
      }
      // deREVStarTrekWagon we never get these since we don't know how to handle them (also they don't build anything).
      case cUnitTypedeREVProspectorWagon:
      {
         buildingType = cUnitTypedeREVMineDiamondBuildable;
         break;
      }
      case cUnitTypedeFurTradeTravois:
      {
         buildingType = cUnitTypedeFurTrade;
         break;
      }
      case cUnitTypeDEMillWagon:
      {
         buildingType = cUnitTypeMill;
         break;
      }
      case cUnitTypedeLivestockPenWagonJapanese:
      {
         buildingType = cUnitTypeYPLivestockPenAsian;
         break;
      }
      case cUnitTypedeTradingPostWagon:
      {
         if (cMyCiv == cCivDEAmericans)
         {
            if (kbTechGetStatus(cTechDEHCArkansasPost) == cTechStatusActive)
            {
               if (kbUnitCount(cMyID, cUnitTypeMarket, cUnitStateABQ) +
                       aiPlanGetNumberByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeMarket) <
                   1)
               {
                  buildingType = cUnitTypeMarket;
               }
               else if (
                   kbUnitCount(cMyID, cUnitTypeChurch, cUnitStateABQ) +
                       aiPlanGetNumberByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeChurch) <
                   1)
               {
                  buildingType = cUnitTypeChurch;
               }
               else
               {
                  buildingType = cUnitTypeSaloon;
               }
            }
         }
         break;
      }
      case cUnitTypedeStateCapitolWagon:
      {
         buildingType = cUnitTypedeStateCapitol;
         break;
      }
      case cUnitTypedeProspectorWagonCoal:
      {
         buildingType = cUnitTypedeMineCoalBuildable;
         break;
      }
      case cUnitTypedeProspectorWagonGold:
      {
         buildingType = cUnitTypedeMineGoldBuildable;
         break;
      }
      case cUnitTypedeProspectorWagonSilver:
      {
         buildingType = cUnitTypedeMineSilverBuildable;
         break;
      }
      case cUnitTypedePlantationWagon:
      {
         buildingType = cUnitTypePlantation;
         break;
      }
      case cUnitTypedeCampWagon:
      {
         buildingType = gTowerUnit;
         break;
      }
      case cUnitTypedeLivestockMarketWagon:
      {
         buildingType = cUnitTypedeLivestockMarket;
         break;
      }
      // deImperialWagon is the Empire Wars wagon and is handled at the top of this Rule.
      case cUnitTypedeBuilderAfrican:
      {
         if (kbUnitCount(cMyID, cUnitTypedeLivestockMarket, cUnitStateABQ) +
                 aiPlanGetNumberByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypedeLivestockMarket) <
             1)
         {
            buildingType = cUnitTypedeLivestockMarket;
         }
         else
         {
            buildingType = cUnitTypedeHouseAfrican;
         }
         break;
      }
      case cUnitTypedeNatSaltCamel:
      {
         buildingType = cUnitTypedeMineSaltBuildable;
         break;
      }
      case cUnitTypedeRedSeaWagon:
      {
         buildingType = gTowerUnit;
         break;
      }
      case cUnitTypedeArtilleryFoundryWagon:
      {
         buildingType = cUnitTypeArtilleryDepot;
         break;
      }
      case cUnitTypedeBuilderHausa:
      {
         if (kbUnitCount(cMyID, cUnitTypedeLivestockMarket, cUnitStateABQ) +
                 aiPlanGetNumberByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypedeLivestockMarket) <
             1)
         {
            buildingType = cUnitTypedeLivestockMarket;
         }
         else if (
             kbUnitCount(cMyID, cUnitTypedeWarCamp, cUnitStateABQ) +
                 aiPlanGetNumberByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypedeWarCamp) <
             3)
         {
            buildingType = cUnitTypedeWarCamp;
         }
         else if (
             (kbTechGetStatus(cTechDEAllegianceHausaArewa) == cTechStatusActive) &&
             (kbUnitCount(cMyID, cUnitTypedeTower, cUnitStateABQ) +
                  aiPlanGetNumberByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypedeTower) <
              kbGetBuildLimit(cMyID, cUnitTypedeTower)))
         {
            buildingType = cUnitTypedeTower;
         }
         else
         {
            buildingType = cUnitTypedeHouseAfrican;
         }
         break;
      }
      case cUnitTypedeBuilderKingdom:
      {
         if (kbUnitCount(cMyID, cUnitTypeTownCenter, cUnitStateABQ) +
                 aiPlanGetNumberByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeTownCenter) <
             1)
         {
            buildingType = cUnitTypeTownCenter;
         }
         else if (
             kbUnitCount(cMyID, cUnitTypedeUniversity, cUnitStateABQ) +
                 aiPlanGetNumberByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypedeUniversity) <
             1)
         {
            buildingType = cUnitTypedeUniversity;
         }
         else
         {
            buildingType = cUnitTypedePalace;
         }
         break;
      }
      case cUnitTypedeTowerBuilder:
      {
         buildingType = cUnitTypedeTower;
         break;
      }
      case cUnitTypedeMountainMonasteryBuilder:
      {
         buildingType = cUnitTypedeMountainMonastery;
         break;
      }
      case cUnitTypedePalaceBuilder:
      {
         buildingType = cUnitTypedePalace;
         break;
      }
      case cUnitTypedeIndianMarketRickshaw: // We never age up with the Indian alliance but just put it here anyway.
      {
         buildingType = cUnitTypeypTradeMarketAsian;
         break;
      }
      case cUnitTypedeUniversityBuilder:
      {
         buildingType = cUnitTypedeUniversity;
         break;
      }
      case cUnitTypedeUSOutpostWagon:
      {
         buildingType = cUnitTypeOutpost;
         break;
      }
      case cUnitTypedeUniqueTowerBuilder:
      {
         buildingType = cUnitTypedeUniqueTower;
         break;
      }
      case cUnitTypedeKallankaTravois:
      {
         buildingType = cUnitTypedeKallanka;
         break;
      }
      case cUnitTypedeHaciendaWagon:
      {
         buildingType = cUnitTypedeHacienda;
         break;
      }
      case cUnitTypedeDockWagon:
      {
         buildingType = gDockUnit;
         break;
      }
      case cUnitTypedeFrontierWagon:
      {
         buildingType = gTowerUnit;
         break;
      }
      }

      if (buildingType < 0) // Didn't find a building so go to the next iteration.
      {
         continue;
      }

      // Are we on build limit?
      buildLimit = kbGetBuildLimit(cMyID, buildingType);
      if (buildLimit >= 1)
      {
         buildingCount = kbUnitCount(cMyID, buildingType, cUnitStateABQ) +
                         aiPlanGetNumberByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, buildingType, true);
         if (buildingCount >= buildLimit)
         {
            continue; // We can't make this building anymore so go to the next iteration.
         }
      }

      planID = createSimpleBuildPlan(buildingType, 1, 75, true, cEconomyEscrowID, mainBaseID, 0);
      aiPlanAddUnitType(planID, wagonType, 1, 1, 1);
      aiPlanAddUnit(planID, wagon);

      debugBuildings("FAILSAFE: Added an idle " + kbGetProtoUnitName(kbUnitGetProtoUnitID(wagon)) + 
         " with ID: " + wagon + " to a new Build Plan ID: " + planID);
   }
}

//==============================================================================
/* Building monitor

   Make sure we have the right number of buildings, or at least a build plan,
   for each required building type.

*/
//==============================================================================
rule buildingMonitor
inactive
minInterval 5
{
   int planID = -1;
   int numberBuildings = 0;
   int numberMilitaryBuildings = 0;
   int numberBuildingsWanted = 0;
   int numberTotalBuildingsWanted = 0;
   int numberFound = 0;
   int buildingQuery = -1;
   int buildingID = -1;
   int puid = -1;
   int buildingPUID = -1;
   int buildLimit = 0;
   int maintainPlanID = -1;
   vector location = cInvalidVector;
   bool buildForward = false;
   static int lastForwardBaseCheckTime = 0;
   int baseID = -1;
   float maxDistance = 0.0;
   int existingPlanID = -1;
   float handicap = 1.0;
   int mainBaseID = kbBaseGetMainID(cMyID);

   if (gDefenseReflexBaseID == mainBaseID)
   {
      return;
   }
   
   int age = kbGetAge();
   int transitionAge = age;
   int time = xsGetTime();

   if (agingUp() == true)
   {
      transitionAge += 1;
   }

   // Go through building queue.
   numberFound = xsArrayGetSize(gQueuedBuildPlans);
   for (i = 0; < numberFound)
   {
      planID = xsArrayGetInt(gQueuedBuildPlans, i);
      if (planID < 0)
      {
         continue;
      }
      puid = aiPlanGetVariableInt(planID, cBuildPlanBuildingTypeID, 0);
      existingPlanID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, puid);
      if (existingPlanID >= 0 && aiPlanGetState(existingPlanID) != cPlanStateBuild)
         continue;
      // No active build plans with the same puid left, activate this plan.
      baseID = aiPlanGetBaseID(planID);
      aiPlanSetBaseID(planID, -1);
      // If we fail to select a location, queue it again.
      if (selectBuildPlanPosition(planID, puid, baseID) == false)
      {
         aiPlanSetBaseID(planID, baseID);
         continue;
      }
      aiPlanSetActive(planID);
      xsArraySetInt(gQueuedBuildPlans, i, -1);
   }

   // If Dutch, add banks to the build limit.
   if (cMyCiv == cCivDutch)
   {
	  if ((kbGetAge() > cAge1) || (agingUp() == true))
	  {
	  planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeBank);
		if ((planID < 0) && (kbUnitCount(cMyID, cUnitTypeBank, cUnitStateABQ) < kbGetBuildLimit(cMyID, cUnitTypeBank)))  // If I'm not building one and I could be, do it.
		{     
		planID = createSimpleBuildPlan(cUnitTypeBank, 1, 95, true, cEconomyEscrowID, kbBaseGetMainID(cMyID), 1); // Very high pri, just above houses
		aiEcho("Starting a new bank build plan.");
		aiPlanSetDesiredResourcePriority(planID, 65);
		}
	  }
   }

   // At least one market
   planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, gMarketUnit);
   if ((planID < 0) && (kbUnitCount(cMyID, gMarketUnit, cUnitStateAlive) < 1) &&
       ((gRevolutionType & cRevolutionFinland) == 0) &&
       (((needMoreHouses() == false) || (kbResourceGet(cResourceWood) >= 500)) &&
            ((btRushBoom < 0.0 && (transitionAge >= cAge2)) ||
             ((transitionAge >= cAge3) || (kbUnitCount(cMyID, gEconUnit, cUnitStateAlive) >= 18))) ||
        civIsAfrican() == true || gDisableWoods == true))
   { // If we're OK on houses...
      planID = createSimpleBuildPlan(gMarketUnit, 1, 96, true, cEconomyEscrowID, mainBaseID, 1); 
      if (gDisableWoods == false)
         aiPlanSetDesiredResourcePriority(planID, 45);
      else // extremely high as we cannot gather wood anymore.
         aiPlanSetDesiredResourcePriority(planID, 99);
   }

   // If native and have potential dancers, one community plaza
   if (civIsNative() == true)
   {
      planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeCommunityPlaza);
      if ((planID < 0) &&
          ((kbResourceGet(cResourceWood) >= 900) || (kbUnitCount(cMyID, cUnitTypexpMedicineManAztec, cUnitStateAlive) >= 2) ||
           (kbUnitCount(cMyID, cUnitTypedePriestess, cUnitStateAlive) >= 1) ||
           (kbUnitCount(cMyID, gEconUnit, cUnitStateAlive) >= 18)))
      {
         if ((kbUnitCount(cMyID, cUnitTypeCommunityPlaza, cUnitStateAlive) < 1) &&
             (kbUnitCount(cMyID, gHouseUnit, cUnitStateAlive) >= 1))
         { // Start a new one if we have at least one house.
            planID = createSimpleBuildPlan(cUnitTypeCommunityPlaza, 1, 92, true, cEconomyEscrowID, mainBaseID, 1);
            aiPlanSetDesiredResourcePriority(planID, 40);
         }
         else if (cMyCiv == cCivXPSioux && kbUnitCount(cMyID, cUnitTypeCommunityPlaza, cUnitStateAlive) < 1)
         { // Start a new one.
            planID = createSimpleBuildPlan(cUnitTypeCommunityPlaza, 1, 92, true, cEconomyEscrowID, mainBaseID, 1);
            aiPlanSetDesiredResourcePriority(planID, 40);
         }
      }
   }

   // At least a town center
   planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeTownCenter);
   if ((planID < 0) && (kbUnitCount(cMyID, cUnitTypeTownCenter, cUnitStateAlive) < 1) &&
       ((gRevolutionType & cRevolutionFinland) == 0))
   { // Start a new one
      planID = createSimpleBuildPlan(cUnitTypeTownCenter, 1, 99, false, cEconomyEscrowID, mainBaseID, 1);
      aiPlanSetDesiredResourcePriority(planID, 99);
   }

   // We always want Granaries, either for early hunting or later farming.
   if (civIsAfrican() == true)
   {
      planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypedeGranary);
      if ((planID < 0) && (kbUnitCount(cMyID, cUnitTypedeGranary, cUnitStateAlive) < 1))
      { // Start a new one
         planID = createSimpleBuildPlan(cUnitTypedeGranary, 1, 70, false, cEconomyEscrowID, mainBaseID, 1);
         aiPlanSetDesiredResourcePriority(planID, 60);
      }
   }

   // That's it for age 1
   if (transitionAge < cAge2)
      return;
   // ***************************************************

   // Build enough military buildings for military production.
   numberMilitaryBuildings = xsArrayGetSize(gMilitaryBuildings);

   for (i = 0; < numberMilitaryBuildings)
   {
      buildingPUID = xsArrayGetInt(gMilitaryBuildings, i);
      numberTotalBuildingsWanted = 0;

      for (j = 0; < gNumArmyUnitTypes)
      {
         if (buildingPUID != xsArrayGetInt(gArmyUnitBuildings, j))
            continue;

         maintainPlanID = xsArrayGetInt(gArmyUnitMaintainPlans, j);

         // how many buildings do we want?
         puid = kbUnitPickGetResult(gLandUnitPicker, j);

         if (kbUnitIsType(puid, cUnitTypeAbstractBannerArmy) == false)
            numberBuildingsWanted = 10 * kbGetProtoUnitPopCount(puid);
         else // need more buildings for banner army because only 1 can be queued at a time.
            numberBuildingsWanted = 5 * kbGetProtoUnitPopCount(puid);
         numberBuildingsWanted = aiPlanGetVariableInt(maintainPlanID, cTrainPlanNumberToMaintain, 0) / numberBuildingsWanted;
         if (numberBuildingsWanted < 1 &&
             (aiTreatyGetEnd() <= xsGetTime() + 10 * 60 * 1000 || (gExcessResources == true && age >= cvMaxAge)))
            numberBuildingsWanted = 1;

         numberTotalBuildingsWanted = numberTotalBuildingsWanted + numberBuildingsWanted;
      }

      buildLimit = kbGetBuildLimit(cMyID, buildingPUID);
      if (buildLimit >= 0 && numberTotalBuildingsWanted > buildLimit)
         numberTotalBuildingsWanted = buildLimit;
      // don't build too many if we can't train units simultaneously at each building
      buildLimit = kbGetPlayerHandicap(cMyID);
      handicap = kbGetPlayerHandicap(cMyID);
      if (handicap >= 1.0)
         handicap = 1.0;
      buildLimit = round((handicap * kbUnitCount(cMyID, cUnitTypeAbstractVillager, cUnitStateAlive)) / 20.0);
      if (buildLimit > 0 && numberTotalBuildingsWanted > buildLimit)
         numberTotalBuildingsWanted = buildLimit;
      planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, buildingPUID);
      if (numberTotalBuildingsWanted > 0)
      {
         if (planID >= 0)
            continue;
      }
      else
      {
         if (planID >= 0 && aiPlanGetState(planID) != cPlanStateBuild)
            aiPlanDestroy(planID);
         continue;
      }
      for (j = 0; < gNumArmyUnitTypes)
      {
         if (buildingPUID != xsArrayGetInt(gArmyUnitBuildings, j))
            continue;

         maintainPlanID = xsArrayGetInt(gArmyUnitMaintainPlans, j);
         puid = kbUnitPickGetResult(gLandUnitPicker, j);

         buildingQuery = createSimpleUnitQuery(cUnitTypeMilitaryBuilding, cMyID, cUnitStateAlive);
         numberFound = kbUnitQueryExecute(buildingQuery);
         numberBuildings = 0;
         for (k = 0; < numberFound)
         {
            buildingID = kbUnitQueryGetResult(buildingQuery, k);
            if (kbProtoUnitCanTrain(kbUnitGetProtoUnitID(buildingID), puid) == true)
               numberBuildings = numberBuildings + 1;
         }

         buildForward = (gForwardBaseID >= 0 && getUnitCountByLocation(
                                                    cUnitTypeLogicalTypeLandMilitary,
                                                    cPlayerRelationEnemyNotGaia,
                                                    cUnitStateAlive,
                                                    gForwardBaseLocation,
                                                    50.0) <= 2) ||
                        (xsGetTime() - lastForwardBaseCheckTime >= 30000 && aiGetWorldDifficulty() >= gDifficultyExpert &&
                         aiTreatyActive() == false && gForwardBaseState == cForwardBaseStateNone &&
                         (xsGetTime() - gForwardBaseUpTime) >= 600000) &&
                            (/*(btRushBoom >= 0.5 && btOffenseDefense > 0.0) ||
                            (btOffenseDefense > 0.0 && xsGetTime() >= 900000) ||*/
                             xsGetTime() >= 1200000);

         // We need at least a building to research upgrades.
         if (numberBuildings >= numberTotalBuildingsWanted &&
             (kbUnitCount(cMyID, buildingPUID, cUnitStateABQ) >= 1 ||
              aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanBuildingTypeID, buildingPUID) < 0))
         {
            // If we have a forward base, ensure that we have at least 1 building there for the army unit.
            if (buildForward == true)
            {
               if (gForwardBaseID >= 0)
               {
                  buildingQuery = createSimpleUnitQuery(
                      cUnitTypeMilitaryBuilding,
                      cMyID,
                      cUnitStateAlive,
                      kbBaseGetLocation(cMyID, gForwardBaseID),
                      kbBaseGetDistance(cMyID, gForwardBaseID));
                  numberFound = kbUnitQueryExecute(buildingQuery);
                  numberBuildings = 0;
                  for (k = 0; < numberFound)
                  {
                     buildingID = kbUnitQueryGetResult(buildingQuery, k);
                     if (kbProtoUnitCanTrain(kbUnitGetProtoUnitID(buildingID), puid) == true)
                     {
                        numberBuildings = numberBuildings + 1;
                        break;
                     }
                  }
                  if (numberBuildings > 0)
                     continue;
               }
            }
            else
            {
               continue;
            }
         }

         // Build a new forward base?
         if (buildForward == true && gForwardBaseID < 0)
         {
            location = selectForwardBaseLocation();
            if (location != cInvalidVector)
            {
               planID = aiPlanCreate("Forward " + kbGetUnitTypeName(buildingPUID) + " build plan ", cPlanBuild);
               aiPlanSetVariableInt(planID, cBuildPlanBuildingTypeID, 0, buildingPUID);
               aiPlanSetDesiredPriority(planID, 87);
               if (addBuilderToPlan(planID, buildingPUID, 1) == true)
               {
                  // Instead of base ID or areas, use a center position
                  aiPlanSetVariableVector(planID, cBuildPlanCenterPosition, 0, location);
                  aiPlanSetVariableFloat(planID, cBuildPlanCenterPositionDistance, 0, 50.0);

                  // Weight it to stay very close to center point.
                  aiPlanSetVariableVector(planID, cBuildPlanInfluencePosition, 0,
                                          location);                                            // Position influence for center
                  aiPlanSetVariableFloat(planID, cBuildPlanInfluencePositionDistance, 0, 50.0); // 100m range.
                  aiPlanSetVariableFloat(planID, cBuildPlanInfluencePositionValue, 0, 100.0);   // 100 points for center
                  aiPlanSetVariableInt(
                      planID,
                      cBuildPlanInfluencePositionFalloff,
                      0,
                      cBPIFalloffLinear); // Linear slope falloff

                  // Add position influence for nearby towers
                  aiPlanSetVariableInt(
                      planID,
                      cBuildPlanInfluenceUnitTypeID,
                      0,
                      cUnitTypeFortFrontier); // Don't build anywhere near another fort.
                  aiPlanSetVariableFloat(planID, cBuildPlanInfluenceUnitDistance, 0, 50.0);
                  aiPlanSetVariableFloat(planID, cBuildPlanInfluenceUnitValue, 0, -200.0);          // -20 points per fort
                  aiPlanSetVariableInt(planID, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffNone); // Cliff falloff

                  aiPlanSetActive(planID);

                  gForwardBaseLocation = location;
                  gForwardBaseBuildPlan = planID;

                  // Chat to my allies
                  sendStatement(cPlayerRelationAlly, cAICommPromptToAllyIWillBuildMilitaryBase, gForwardBaseLocation);

                  gForwardBaseState = cForwardBaseStateBuilding;

                  debugBuildings(" ");
                  debugBuildings("    BUILDING FORWARD BASE, MOVING DEFEND PLANS TO COVER.");
                  debugBuildings("    PLANNED LOCATION IS " + gForwardBaseLocation);
                  debugBuildings(" ");

                  // if (gDefenseReflex == false)
                  //   endDefenseReflex();
               }
               else
               {
                  aiPlanDestroy(planID);
                  planID = -1;
                  buildForward = false;
               }
            }
            else
            {
               buildForward = false;
            }
            lastForwardBaseCheckTime = xsGetTime();
         }

         if (planID < 0)
         {
            if (buildForward == true && gForwardBaseID >= 0)
            { // If we have forward base, build there.
               planID = createSimpleBuildPlan(buildingPUID, 1, 70, false, cMilitaryEscrowID, gForwardBaseID, 1);
            }
            else
            {
               planID = createSimpleBuildPlan(buildingPUID, 1, 70, false, cMilitaryEscrowID, mainBaseID, 1);
            }
         }

         // If we don't have any, set priority to slightly above default.
         if (numberBuildings < 1)
            aiPlanSetDesiredResourcePriority(planID, 60);
         else
            aiPlanSetDesiredResourcePriority(planID, 41 - numberBuildings);
         break;
      }
   }

   if (gTimeToFish == true && (kbUnitCount(cMyID, gDockUnit, cUnitStateABQ) < 1) &&
       (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, gDockUnit) < 0) &&
       ((gRevolutionType & cRevolutionFinland) == 0))
   { // No dock and not making any, let's start a plan.
      planID = createSimpleBuildPlan(gDockUnit, 1, 70, false, cEconomyEscrowID, mainBaseID, 1);
      aiPlanSetDesiredResourcePriority(planID, 70);
   }
   
   if ((civIsEuropean() == true) || (cMyCiv == cCivDEAmericans))/* && ((kbTechGetStatus(cTechHCRoyalDecreeBritish) == cTechStatusActive) ||
                                     (kbTechGetStatus(cTechHCRoyalDecreeDutch) == cTechStatusActive) ||
                                     (kbTechGetStatus(cTechHCRoyalDecreeFrench) == cTechStatusActive) ||
                                     (kbTechGetStatus(cTechHCRoyalDecreeGerman) == cTechStatusActive) ||
                                     (kbTechGetStatus(cTechHCRoyalDecreeOttoman) == cTechStatusActive) ||
                                     (kbTechGetStatus(cTechHCRoyalDecreePortuguese) == cTechStatusActive) ||
                                     (kbTechGetStatus(cTechHCRoyalDecreeRussian) == cTechStatusActive) ||
                                     (kbTechGetStatus(cTechDEHCRoyalDecreeSwedish) == cTechStatusActive) ||
                                     (kbTechGetStatus(cTechHCRoyalDecreeSpanish) == cTechStatusActive)))*/
   {
      planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeChurch);
      if ((planID < 0) && (kbUnitCount(cMyID, cUnitTypeChurch, cUnitStateAlive) < 1))
      { // Start a new one
         planID = createSimpleBuildPlan(cUnitTypeChurch, 1, 60, true, cEconomyEscrowID, kbBaseGetMainID(cMyID), 1);
         aiPlanSetDesiredResourcePriority(planID, 50);
         aiEcho("Starting a new church build plan.");
      }
   }
   
   if (kbUnitCount(cMyID, cUnitTypeypChurchWagon, cUnitStateAlive) > 0)
   {
      planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeypChurch);
      if ((planID < 0) && (kbUnitCount(cMyID, cUnitTypeypChurch, cUnitStateAlive) < 1))
      { // Start a new one
         planID = createSimpleBuildPlan(cUnitTypeypChurch, 1, 95, true, cEconomyEscrowID, kbBaseGetMainID(cMyID), 1);
         aiPlanSetDesiredResourcePriority(planID, 95);
         aiEcho("Starting a new church build plan.");
      }
   }
   if ((kbTechGetStatus(cTechypConsulateDutchLivestockPenWagon) != cTechStatusObtainable) 
	   && (kbUnitCount(cMyID, cUnitTypeYPLivestockPenAsian, cUnitStateABQ) < 1))
   {
      planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeYPLivestockPenAsian);
      if ((planID < 0) && (kbUnitCount(cMyID, cUnitTypeYPLivestockPenAsian, cUnitStateABQ) < 1))
      { // Start a new one
         planID = createSimpleBuildPlan(cUnitTypeYPLivestockPenAsian, 1, 60, true, cEconomyEscrowID, kbBaseGetMainID(cMyID), 1);
         aiPlanSetDesiredResourcePriority(planID, 40);
         aiEcho("Starting a new church build plan.");
      }
   }

   // If we are Ottoman build a Mosque, higher prio if we're close to our Settler Build Limit.
   if ((cMyCiv == cCivOttomans) &&
       (kbUnitCount(cMyID, cUnitTypeChurch, cUnitStateAlive) < 1))
   {
      planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeChurch);
      if (planID < 0)
      {
         planID = createSimpleBuildPlan(cUnitTypeChurch, 1, 50, true, cEconomyEscrowID, mainBaseID, 1);
         // If we're close to our build limit bump up the priority so we can potentially research the BL increasing techs.
         if (kbGetBuildLimit(cMyID, cUnitTypeSettler) - kbUnitCount(cMyID, cUnitTypeSettler, cUnitStateABQ) <= 5)
         {
            aiPlanSetDesiredResourcePriority(planID, 70);
         }
      }
   }

   // Build a native embassy if we allied with natives
   if (xsArrayGetSize(kbVPSiteQuery(cVPNative, cMyID, cVPStateCompleted)) > 0 && ((gRevolutionType & cRevolutionFinland) == 0))
   {
      planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeNativeEmbassy);
      if ((planID < 0) && (kbUnitCount(cMyID, cUnitTypeNativeEmbassy, cUnitStateAlive) < 1))
      { // Start a new one
         planID = createSimpleBuildPlan(cUnitTypeNativeEmbassy, 1, 60, true, cMilitaryEscrowID, mainBaseID, 1);
         aiPlanSetDesiredResourcePriority(planID, 40);
      }
   }

   // At least one mountain monastery
   if (cMyCiv == cCivDEEthiopians && age >= cAge2)
   {
      planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypedeMountainMonastery);
      location = kbBaseGetLocation(cMyID, mainBaseID);
      maxDistance = kbBaseGetDistance(cMyID, mainBaseID) + 10.0;
      numberBuildingsWanted = getUnitCountByLocation(cUnitTypeAbstractMine, 0, cUnitStateAlive, location, maxDistance);
      buildLimit = kbGetBuildLimit(cMyID, cUnitTypedeMountainMonastery);
      if (numberBuildingsWanted > buildLimit)
         numberBuildingsWanted = buildLimit;
      if (numberBuildingsWanted < 1)
         numberBuildingsWanted = 1;
      if ((planID < 0) && (kbUnitCount(cMyID, cUnitTypedeMountainMonastery, cUnitStateABQ) < numberBuildingsWanted) &&
          (aiGetWorldDifficulty() >= cDifficultyHard))
      { // Start a new one
         planID = createSimpleBuildPlan(cUnitTypedeMountainMonastery, 1, 60, true, cEconomyEscrowID, mainBaseID, 1);
      }
   }

   // We build 1 University in our main base, we want this University to be close to our starting Town Center and the in base
   // Palace for the influence bonus. This University will only be built if we sent the 1 Palace Builder card in
   // Exploration/Commerce (otherwise we won't have a Palace in this age, it will be built in Fortress).
   if (cMyCiv == cCivDEHausa)
   {
      planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypedeUniversity);
      if (planID >= 0 && (kbUnitCount(cMyID, cUnitTypedePalace, cUnitStateABQ) == 0 ||
                          kbUnitCount(cMyID, cUnitTypeTownCenter, cUnitStateABQ) == 0))
      {
         aiPlanDestroy(planID); // We have either no TC or no Palace or neither, so we destroy the University build plan.
      }
      else if ( planID < 0 && kbUnitCount(cMyID, cUnitTypedeUniversity, cUnitStateABQ) < 1 &&
         kbUnitCount(cMyID, cUnitTypedePalace, cUnitStateABQ) >= 1 &&
         kbUnitCount(cMyID, cUnitTypeTownCenter, cUnitStateABQ) >= 1)
      { // We have a Palace and a Town Center so we can calculate the position for the University.
         vector townCenterLocation = getStartingLocation();
         vector palaceLocation = kbUnitGetPosition(getUnit(cUnitTypedePalace, cMyID, cUnitStateABQ));
         vector placeUniversityHere = townCenterLocation + (palaceLocation - townCenterLocation) * 0.5;
         planID = createLocationBuildPlan(cUnitTypedeUniversity, 1, 50, true, cEconomyEscrowID, placeUniversityHere, 1);
      }
   }

   // Build a consulate if there is none
   if (civIsAsian() == true && cvOkToBuildConsulate == true)
   {
      planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeypConsulate);
      if ((planID < 0) && (kbUnitCount(cMyID, cUnitTypeypConsulate, cUnitStateAlive) < 1))
      { // Start a new one
         createSimpleBuildPlan(cUnitTypeypConsulate, 1, 60, true, cEconomyEscrowID, mainBaseID, 1);
      }
   }

   // That's it for age 2
   if (transitionAge < cAge3)
      return;
   // **********************************************************

   if (transitionAge > cAge2)
   {
   static int WagonMaintainPlan = -1;  
   planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeTownCenter);
   if ((planID < 0) && (1 > kbUnitCount(cMyID, cUnitTypeTownCenter, cUnitStateABQ)))
		{     // Start a new one
   planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeTownCenter);
			aiPlanSetDesiredResourcePriority(planID, 99);
			aiEcho("Starting a new town center build plan.");
		}
        else
	// Incas need to build more town centers to reach maximum pop
   if ((planID < 0) && (kbUnitCount(cMyID, cUnitTypeTownCenter, cUnitStateABQ) < kbGetBuildLimit(cMyID, cUnitTypeTownCenter)))
		{     // Start a new one
			planID = createSimpleBuildPlan(cUnitTypeTownCenter, 1, 99, false, cEconomyEscrowID, kbBaseGetMainID(cMyID), 1);
			aiPlanSetDesiredResourcePriority(planID, 55);
			aiEcho("Starting a new town center build plan.");
		}
		
		if ((WagonMaintainPlan < 0) && (kbUnitCount(cMyID, cUnitTypeypBankWagon, cUnitStateABQ) < kbGetBuildLimit(cMyID, cUnitTypeypBankWagon)))
		{     // Start a new one
			WagonMaintainPlan = createSimpleMaintainPlan(cUnitTypedeStateCapitolTrainBankWagon, 1, false, kbBaseGetMainID(cMyID), 1);
			aiPlanSetDesiredResourcePriority(planID, 55);
		}
		if ((WagonMaintainPlan < 0) && (kbUnitCount(cMyID, cUnitTypeypBlockhouseWagon, cUnitStateABQ) < kbGetBuildLimit(cMyID, cUnitTypeypBlockhouseWagon)))
		{     // Start a new one
			WagonMaintainPlan = createSimpleMaintainPlan(cUnitTypedeStateCapitolTrainBankWagon, 1, false, kbBaseGetMainID(cMyID), 1);
			aiPlanSetDesiredResourcePriority(planID, 55);
		}
   }

   // random chance to build a saloon
    if ((civIsEuropean() == true) && ((gRevolutionType & cRevolutionFinland) == 0))
   {
      int saloonUnitType = cUnitTypeSaloon;
      if (cMyCiv != cCivDEAmericans && cMyCiv != cCivDEMexicans)
         saloonUnitType = cUnitTypedeTavern;
      planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, saloonUnitType);
      static int saloonRandomizer = -1;
      if (saloonRandomizer < 0)
         saloonRandomizer = aiRandInt(10);
      if ((saloonRandomizer < 2 || xsArrayGetFloat(gResourceNeeds, cResourceWood) < -1000.0) && planID < 0 &&
          kbUnitCount(cMyID, saloonUnitType, cUnitStateAlive) < 1)
      {
         planID = createSimpleBuildPlan(saloonUnitType, 1, 50, false, cMilitaryEscrowID, kbBaseGetMainID(cMyID), 1);
      }
   }

   // At least one Palace for Africans.
   // We don't need a Palace early for Ethiopians in treaty but we do need one for Hausa for the influence combination with
   // Universities.
   if (cMyCiv == cCivDEEthiopians && (aiTreatyGetEnd() <= xsGetTime() + 10 * 60 * 1000))
   {
      planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypedePalace);
      if ((planID < 0) && (kbUnitCount(cMyID, cUnitTypedePalace, cUnitStateAlive) < 1))
      { // Start a new one
         planID = createSimpleBuildPlan(cUnitTypedePalace, 1, 60, true, cMilitaryEscrowID, mainBaseID, 1);
         aiPlanSetDesiredResourcePriority(planID, 60);
      }
   }

   if (cMyCiv == cCivDEHausa)
   {
      planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypedePalace);
      if ((planID < 0) && (kbUnitCount(cMyID, cUnitTypedePalace, cUnitStateAlive) < 1) &&
          (kbUnitCount(cMyID, cUnitTypedeUniversity, cUnitStateAlive) < 1))
      { // Start a new one at a random spot in the base.
         planID = createSimpleBuildPlan(cUnitTypedePalace, 1, 60, true, cMilitaryEscrowID, mainBaseID, 1);
         aiPlanSetDesiredResourcePriority(planID, 60);
      }
      else if (
          (planID < 0) && (kbUnitCount(cMyID, cUnitTypedePalace, cUnitStateAlive) < 1) &&
          (kbUnitCount(cMyID, cUnitTypedeUniversity, cUnitStateAlive) >= 1))
      { // We have a University so we try to build the Palace next to it for the bonus.
         vector universityLocation = kbUnitGetPosition(getUnit(cUnitTypedeUniversity, cMyID, cUnitStateABQ));
         planID = createLocationBuildPlan(cUnitTypedePalace, 1, 60, true, cEconomyEscrowID, universityLocation, 1);
      }
   }

   // If Mexicans, at least one Cathedral.
   if (cMyCiv == cCivDEMexicans)
   {
      planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypedeCathedral);
      if ((planID < 0) && (kbUnitCount(cMyID, cUnitTypedeCathedral, cUnitStateAlive) < 1))
      { // Start a new one
         planID = createSimpleBuildPlan(cUnitTypedeCathedral, 1, 50, true, cEconomyEscrowID, mainBaseID, 1);
      }
   }
      if ((civIsEuropean() == true) && (cMyCiv != cCivDEMexicans) && ((gRevolutionType & cRevolutionFinland) == 0))
   {
      planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeChurch);
      if ((planID < 0) && (kbUnitCount(cMyID, cUnitTypeChurch, cUnitStateAlive) < 1) &&
          (aiGetWorldDifficulty() >= cDifficultyModerate))
      { // Start a new one
         planID = createSimpleBuildPlan(cUnitTypeChurch, 1, 60, true, cEconomyEscrowID, kbBaseGetMainID(cMyID), 1);
         aiPlanSetDesiredResourcePriority(planID, 35);
      }
   }

   // That's it for age 3
   if (transitionAge < cAge4)
      return;
   // **********************************************************

   // At least one church if we don't have one yet
   /*if ((civIsEuropean() == true) && (cMyCiv != cCivDEMexicans) && ((gRevolutionType & cRevolutionFinland) == 0))
   {
      planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeChurch);
      if ((planID < 0) && (kbUnitCount(cMyID, cUnitTypeChurch, cUnitStateAlive) < 1) &&
          (aiGetWorldDifficulty() >= cDifficultyHard))
      { // Start a new one
         planID = createSimpleBuildPlan(cUnitTypeChurch, 1, 60, true, cEconomyEscrowID, mainBaseID, 1);
         aiPlanSetDesiredResourcePriority(planID, 35);
      }
   }*/

   // That's it for age 4
   if (age < cAge5)
      return;
   // **********************************************************
   // And how 'bout a capitol, as long as we're here
   if ((civIsEuropean() == true))
   {
      planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeCapitol);
      if ((planID < 0) && (kbUnitCount(cMyID, cUnitTypeCapitol, cUnitStateAlive) < 1))
      { // Start a new one
         createSimpleBuildPlan(cUnitTypeCapitol, 1, 60, true, cEconomyEscrowID, kbBaseGetMainID(cMyID), 1);
      }
   }
      if ((civIsEuropean() == true) || (cMyCiv == cCivDEMexicans) || (cMyCiv == cCivDEAmericans))
        xsEnableRule("spiesMonitor");
	else
        xsEnableRule("spiesNativeMonitor");  					  
}

rule spiesMonitor
inactive
minInterval 30
{
   //If we can afford it, then get it.
   float goldCost=kbTechCostPerResource(cTechSpies, cResourceGold);
   float currentGold=kbResourceGet(cResourceGold);
   if(goldCost>currentGold)
      return;
   //Get Omniscience
   int spiesPID=aiPlanCreate("Get_Spies", cPlanProgression);
   if (spiesPID != 0)
   {
      aiPlanSetVariableInt(spiesPID, cProgressionPlanGoalTechID, 0, cTechSpies);
      aiPlanSetDesiredPriority(spiesPID, 51);
      aiPlanSetEscrowID(spiesPID, cMilitaryEscrowID);
      aiPlanSetActive(spiesPID);
   }  
   xsDisableSelf();
}
rule spiesNativeMonitor
inactive
minInterval 30
{
   //If we can afford it, then get it.
   float goldCost=kbTechCostPerResource(cTechSpiesNative, cResourceGold);
   float currentGold=kbResourceGet(cResourceGold);
   if(goldCost>currentGold)
      return;
   //Get Omniscience
   int spiesPID=aiPlanCreate("Get_Spies", cPlanProgression);
   if (spiesPID != 0)
   {
      aiPlanSetVariableInt(spiesPID, cProgressionPlanGoalTechID, 0, cTechSpiesNative);
      aiPlanSetDesiredPriority(spiesPID, 51);
      aiPlanSetEscrowID(spiesPID, cMilitaryEscrowID);
      aiPlanSetActive(spiesPID);
   }  
   xsDisableSelf();
}
//==============================================================================
// rule repairManager
//==============================================================================
rule repairManager
inactive
group tcComplete
minInterval 20
{
   if (aiGetWorldDifficulty() < cDifficultyModerate)
   {
      xsDisableSelf();
      return;
   }

   if (aiPlanGetIDByIndex(cPlanRepair, -1, true, 0) < 0)
      createRepairPlan(50);
}

//==============================================================================
// towerManager
// Tries to maintain as many gTowerUnit as gNumTowers / gCommandNumTowers / cvMaxTowers says.
// updateWantedTowers() takes care of setting gNumTowers.
//==============================================================================
rule towerManager
inactive
minInterval 40
{
   if (cvOkToFortify == false)
   {
      return; // Oops. I shouldn't be running.
   }

   int towersWanted = 0;
   if (cvMaxTowers >= 0) // The control variable takes precendence over everything.
   {
      towersWanted = cvMaxTowers;
   }
   else
   {
      // Has a command been set by the commHandler? Use that amount then.
      towersWanted = gTowerCommandActive == true ? gCommandNumTowers : gNumTowers;
   }

   int buildLimit = kbGetBuildLimit(cMyID, gTowerUnit);
   // Safety check, this should only fire in custom scenarios and using the commHandler.
   if (towersWanted > buildLimit)
   {
      towersWanted = buildLimit;
   }
   debugBuildings("We want " + towersWanted + " " + kbGetProtoUnitName(gTowerUnit) + "s");

   // Don't make any more Tower build plans if we're already at our calculated limit.
   if (kbUnitCount(cMyID, gTowerUnit, cUnitStateABQ) >= towersWanted)
   {
      return;
   }

   // We're still missing 1 or more Towers and we don't have a build plan active so create one.
   if (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, gTowerUnit) < 0)
   {
      createSimpleBuildPlan(gTowerUnit, 1, 50, false, cMilitaryEscrowID, kbBaseGetMainID(cMyID));
   }
}

//==============================================================================
/* updateWantedTowers
   Calculate how many Towers (using the word Towers for Castles here too)
   we want for this age using the btOffenseDefense variable to set up the initial values.
   Some gTowerUnit are also military production buildings like War Huts so the
   values below aren't a guaranteed maximum for those kinds of civs.
   And shipments of Towers can push us above these limits too of course. */
//==============================================================================
void updateWantedTowers()
{
   int age = kbGetAge();
   int buildLimit = kbGetBuildLimit(cMyID, gTowerUnit);

   if (age == cvMaxAge)
   {
      gNumTowers = buildLimit; // Just max out on Towers in Imperial/max allowed age.
                               // We will reduce this on lower difficulties of course.
   }
   else if (age == cAge2) // Set up our begin values when we're in the Commerce Age.
   {
      if (btOffenseDefense >= 0.0)
      {
         gNumTowers = 0; // We remain at 0 Towers in Commerce if we're not defensively orientated.
      }
      else if (btOffenseDefense >= -0.5) // Between -0.5 and 0.0
      {
         gNumTowers = civIsAsian() == true ? 1 : 2;
      }
      else // btOffenseDefense between -0.5 and -1.0
      {
         gNumTowers = civIsAsian() == true ? 2 : 3;
      }
   }
   else // Fortress / Industrial.
   {
      gNumTowers += civIsAsian() == true ? 1 : 2; // Add 1/2 Towers to our previous value.
   }

   // Impose some limits based on difficulty, Hardest and Extreme just go full out.
   if (cDifficultyCurrent <= cDifficultyEasy) // Easy / Standard.
   {
      if (gNumTowers > 2)
      {
         gNumTowers = 2;
      }
   }
   else if (cDifficultyCurrent <= cDifficultyHard) // Moderate / Hard.
   {
      if (gNumTowers > 4)
      {
         gNumTowers = 4;
      }
   }
   int towerBuildPlanID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, gTowerUnit);
   if ((towerBuildPlanID < 0) && (kbUnitCount(cMyID, gTowerUnit, cUnitStateABQ) < gNumTowers) && (cvOkToFortify == true))
   {                                            
	  if ((kbGetAge() >= cvMaxAge) || (gRevolutionType != 0))
	  {
	  gNumTowers = kbGetBuildLimit(cMyID, gTowerUnit);
      //TowerBuildPlanID = createSimpleBuildPlan(gTowerUnit, 1, 95, true, cEconomyEscrowID, kbBaseGetMainID(cMyID), 1);
      //aiEcho("Starting a new house build plan.");
      //aiPlanSetDesiredResourcePriority(TowerBuildPlanID, 40);
	  }
   }	

   // Safety check.
   if (gNumTowers > buildLimit)
   {
      gNumTowers = buildLimit;
   }
}

//==============================================================================
/* tradingPostMonitor
   Decide if we need to build a Trading Post. The minInterval instantly gets 
   set to a higher value, we just want to run this once ASAP.
*/
//==============================================================================
rule tradingPostMonitor
inactive
minInterval 1
{
   if (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeTradingPost) >= 0)
   {
      return;
   }
 
   int numberEnemiesFound = -1;
   int unitID = -1;
   int puid = -1;
   int mainBaseID = kbBaseGetMainID(cMyID);
   vector mainBaseLocation = kbBaseGetLocation(cMyID, mainBaseID);
   int mainAreaGroup = kbAreaGroupGetIDByPosition(mainBaseLocation);
   int socketAreaGroup = -1;
   int socketID = -1;
   int time = xsGetTime();
   vector socketPosition = cInvalidVector;
   float militaryPower = 0.0;
   float distancePenalty = 0.0;
   int bestTradeSocketID = -1;
   int bestTradeDistancePenalty = 99.99;
   int bestNativeSocketID = -1;
   int bestNativeDistancePenalty = 99.99;
   bool earlyTrade = false;

   int wagonPUID = findWagonToBuild(cUnitTypeTradingPost);
   int wagonID = -1;
   // We found that we have an idle wagon with this PUID, but we still need to get the Wagon's ID.
   if (wagonPUID >= 0)
   {
      int wagonQuery = createSimpleUnitQuery(wagonPUID, cMyID, cUnitStateAlive);
      int wagonsFound = kbUnitQueryExecute(wagonQuery);
      
      for (int k = 0; k < wagonsFound; k++)
      {
         wagonID = kbUnitQueryGetResult(wagonQuery, k);
         if (kbUnitGetPlanID(wagonID) < 0)
         {
            break; // We've found the Wagon we also found inside of findWagonToBuild, this should always hit.
         }
      }
   }

   static int enemyQuery = -1;
   if (enemyQuery < 0)
   {
      enemyQuery = kbUnitQueryCreate("tradingPostEnemyQuery");
      kbUnitQuerySetIgnoreKnockedOutUnits(enemyQuery, true);
      kbUnitQuerySetPlayerRelation(enemyQuery, cPlayerRelationEnemyNotGaia);
      kbUnitQuerySetState(enemyQuery, cUnitStateABQ);
      kbUnitQuerySetMaximumDistance(enemyQuery, 50.0);
      kbUnitQuerySetUnitType(enemyQuery, cUnitTypeHasBountyValue);
      // Run before house monitor to claim a trading post at the start of the game and then slow it down.
      xsSetRuleMinIntervalSelf(60);
   }
   
   int socketQuery = createSimpleUnitQuery(cUnitTypeSocket, 0, cUnitStateAlive);
   int numberSocketsFound = kbUnitQueryExecute(socketQuery);

   for (i = 0; < numberSocketsFound)
   {
      socketID = kbUnitQueryGetResult(socketQuery, i);
      socketPosition = kbUnitGetPosition(socketID);

      // Already claimed, skipping.
      if (getUnitByLocation(cUnitTypeTradingPost, cPlayerRelationAny, cUnitStateABQ, socketPosition, 10.0) >= 0)
      {
         continue;
      }

      kbUnitQuerySetPosition(enemyQuery, socketPosition);
      kbUnitQueryResetResults(enemyQuery);
      numberEnemiesFound = kbUnitQueryExecute(enemyQuery);

      for (j = 0; < numberEnemiesFound)
      {
         unitID = kbUnitQueryGetResult(enemyQuery, j);
         puid = kbUnitGetProtoUnitID(unitID);

         switch (puid)
         {
         case cUnitTypeFortFrontier:
         {
            militaryPower += 10.0;
            break;
         }
         case cUnitTypeTownCenter:
         case cUnitTypeNoblesHut:
         case cUnitTypeWarHut:
         case cUnitTypeypWIAgraFort2:
         case cUnitTypeypWIAgraFort3:
         case cUnitTypeypWIAgraFort4:
         case cUnitTypeypWIAgraFort5:
         case cUnitTypeOutpost:
         case cUnitTypedeTower:
         case cUnitTypeypCastle:
         case cUnitTypeBlockhouse:
         case cUnitTypeYPOutpostAsian:
         case cUnitTypedeIncaStronghold:
         case cUnitTypedeUniqueTower:
         case cUnitTypedePalace:
         {
            militaryPower += 4.0;
            break;
         }
         }

         if (kbProtoUnitIsType(cMyID, puid, cUnitTypeLogicalTypeLandMilitary) == true)
         {
            militaryPower += getMilitaryUnitStrength(puid);
         }
      }

      // Skip when there are too many military units around.
      if (militaryPower >= 5.0)
      {
         continue;
      }

      // Adjust for distance. If < 100m, leave as is. Over 100m to 400m, penalize 10% per 100m.
      distancePenalty = distance(mainBaseLocation, socketPosition) / 1000.0;
      if (distancePenalty > 0.4)
      {
         distancePenalty = 0.4;
      }
      // Increase penalty by 40% if transporting is required.
      socketAreaGroup = kbAreaGroupGetIDByPosition(socketPosition);
      if (mainAreaGroup != socketAreaGroup)
      {
         distancePenalty += 0.4;
      }

      if (kbUnitIsType(socketID, cUnitTypeNativeSocket) == true)
      {
         if (cvOkToAllyNatives == false)
         {
            return;
         }
         else if (distancePenalty < bestNativeDistancePenalty)
         {
            bestNativeSocketID = socketID;
            bestNativeDistancePenalty = distancePenalty;
         }
      }
      else // Trade Route.
      {
         if (cvOkToClaimTrade == false)
         {
            return;
         }
         else if (distancePenalty < bestTradeDistancePenalty)
         {
            bestTradeSocketID = socketID;
            bestTradeDistancePenalty = distancePenalty;
         }
      }
   }

   if ((bestNativeSocketID >= 0) || (bestTradeSocketID >= 0))
   {
      socketID = -1;

      if (bestNativeSocketID >= 0)
      {
         if ((time - gLastClaimNativeMissionTime >= (1.0 - btBiasNative) * gClaimNativeMissionInterval) ||
             (wagonID >= 0))
         {
            socketID = bestNativeSocketID;
         }
      }

      if (bestTradeSocketID >= 0)
      {
         if ((kbGetAge() == cAge1) && (agingUp() == false))
         {
            // Build an early TP if we have enough wood at start.
            // Exclude Indians because we need wood to continue Villager production.
            if (((cMyCiv != cCivIndians) && (cMyCiv != cCivSPCIndians) && 
                 (isProtoUnitAffordable(cUnitTypeTradingPost) == true)) ||
               (wagonID >= 0))
            {
               earlyTrade = true;
            }
            else
            {
               return;
            }
            if (((cMyCiv == cCivBritish) || (cMyCiv == cCivChinese) || (cMyCiv == cCivSPCChinese) ||
                (cMyCiv == cCivDESwedish) || (cMyCiv == cCivDEInca)) &&
                (kbUnitCount(cMyID, gHouseUnit, cUnitStateAlive) +
                 aiPlanGetNumberByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, gHouseUnit) > 1 ))
            {
               return;
            }
         }
         
         if ((time - gLastClaimTradeMissionTime >= (1.0 - btBiasTrade) * gClaimTradeMissionInterval) ||
             (wagonID >= 0))
         {
            socketID = bestTradeSocketID;
         }
      }

      if (socketID < 0)
      {
         return;
      }
      
      int planID = aiPlanCreate("Trading Post Build Plan", cPlanBuild);
      aiPlanSetVariableInt(planID, cBuildPlanBuildingTypeID, 0, cUnitTypeTradingPost);
      aiPlanSetVariableInt(planID, cBuildPlanSocketID, 0, socketID);
      
      int heroID = -1;
      
      if (wagonID >= 0) // We found a Wagon that can construct this Trading Post.
      {
         debugBuildings("Adding 1 " + kbGetProtoUnitName(wagonPUID) + " with ID: " + wagonID + 
            " to our Trading Post build plan");
         aiPlanAddUnitType(planID, wagonPUID, 1, 1, 1);
         aiPlanAddUnit(planID, wagonID);
      }
      else // Check for Heroes if we didn't manage to find a Wagon.
      {
         int heroQuery = createSimpleUnitQuery(cUnitTypeHero, cMyID, cUnitStateAlive);
         int numberHeroesFound = kbUnitQueryExecute(heroQuery);
         int heroPlanID = -1;
         
         for (int n = 0; n < numberHeroesFound; n++)
         {
            unitID = kbUnitQueryGetResult(heroQuery, n);
            if (unitID < 0)
            {
               continue;
            }
            if (kbProtoUnitCanTrain(kbUnitGetProtoUnitID(unitID), cUnitTypeTradingPost) == false)
            {
               continue;
            }
            heroPlanID = kbUnitGetPlanID(heroID);
            if ((heroPlanID < 0) || (aiPlanGetType(heroPlanID) == cPlanDefend) || (aiPlanGetType(heroPlanID) == cPlanExplore))
            {
               heroID = unitID;
               break;
            }
         }
         
         if (heroID != -1) // We'v found a suitable Hero so add him to the plan.
         {
            debugBuildings("Adding 1 " + kbGetProtoUnitName(kbUnitGetProtoUnitID(heroID)) + " with ID: " +
               heroID + " to our Trading Post build plan");
            aiPlanAddUnitType(planID, cUnitTypeHero, 1, 1, 1);
            aiPlanAddUnit(planID, heroID);
         }
      }
      
      if ((wagonID < 0) && (heroID < 0)) // We didn't find either so we must add a Villager. 
      {
         if (((gRevolutionType & cRevolutionMilitary) == 0) || ((gRevolutionType & cRevolutionFinland) == cRevolutionFinland))
         {
            debugBuildings("Adding 1 gEconUnit to our Trading Post build plan");
            aiPlanAddUnitType(planID, gEconUnit, 1, 1, 1);
         }
         else // We didn't manage to add a Wagon or a Hero to our plan and can't use Villagers either, destroy.
         {
            aiPlanDestroy(planID);
            return;
         }   
      }

      // Priority.
      aiPlanSetDesiredPriority(planID, 97);
      // Very high priority so we claim a trading post right after start up.
      if (earlyTrade == true)
      {
         aiPlanSetDesiredResourcePriority(planID, 70);
      }
      else
      {
         aiPlanSetDesiredResourcePriority(planID, 55);
      }

      // Go.
      aiPlanSetActive(planID);

      if (socketID == bestNativeSocketID)
      {
         gLastClaimNativeMissionTime = time;
      }
      else
      {
         gLastClaimTradeMissionTime = time;
      }
   }
}

void tcPlacedEventHandler(int planID = -1)
{
   // Check the state of the TC build plan.
   // Fire an ally chat if the state is "build"
   if (aiPlanGetState(planID) == cPlanStateBuild)
   {
      vector loc = kbBuildingPlacementGetResultPosition(aiPlanGetVariableInt(planID, cBuildPlanBuildingPlacementID, 0));
      sendStatement(cPlayerRelationAlly, cAICommPromptToAllyIWillBuildTC, loc);
      debugBuildings("Sending TC placement chat at location " + loc);
      gTCBuildPlanID = -1;
   }
}

//==============================================================================
/* xpBuilder monitor

   Use an idle xpBuilder to build as needed.

*/
//==============================================================================
rule xpBuilderMonitor
inactive
minInterval 20
{
   static int activePlan = -1;

   if (activePlan != -1) // We already have something active?
   {
      if ((aiPlanGetState(activePlan) < 0) || (aiPlanGetState(activePlan) == cPlanStateNone))
      {
         aiPlanDestroy(activePlan);
         activePlan = -1; // Plan is bad, but didn't die.  It's dead now, so continue below.
      }
      else
      {
         return; // Something is active, let it run.
      }
   }

   // If we get this far, there is no active plan.  See if we have a xpBuilder to use.
   int xpBuilderID = -1;
   int buildingToMake = -1;
   int buildertype = -1;
   if (kbUnitCount(cMyID, cUnitTypexpBuilderStart, cUnitStateAlive) > 0)
   {
      xpBuilderID = getUnit(cUnitTypexpBuilderStart);
      buildingToMake = gHouseUnit; // If all else fails, make a house since we can't make warhuts.
      buildertype = cUnitTypexpBuilderStart;
   }
   else
   {
      xpBuilderID = getUnit(cUnitTypexpBuilder);
      buildingToMake = cUnitTypeWarHut; // If all else fails, make a war hut.
      buildertype = cUnitTypexpBuilder;
   }
   if (xpBuilderID < 0)
      return;

   // We have a xpBuilder, and no plan to use it.  Find something to do with it.
   // Simple logic.  Farm if less than 3.  War hut if less than 2.  Corral if < 2.  House if below pop limit.
   // One override....avoid farms in age 1, they're too slow.
   if ((kbUnitCount(cMyID, gFarmUnit, cUnitStateABQ) < 3) && (kbGetAge() > cAge1) && (gTimeToFarm == true))
      buildingToMake = gFarmUnit;
   else if (
       kbUnitCount(cMyID, cUnitTypeWarHut, cUnitStateABQ) < 2 && (kbGetAge() > cAge1) && (buildertype == cUnitTypexpBuilder))
      buildingToMake = cUnitTypeWarHut;
   else if (kbUnitCount(cMyID, cUnitTypeCorral, cUnitStateABQ) < 2 && (kbGetAge() > cAge1))
      buildingToMake = cUnitTypeCorral;
   else if (kbGetBuildLimit(cMyID, gHouseUnit) <= kbUnitCount(cMyID, gHouseUnit, cUnitStateAlive))
      buildingToMake = gHouseUnit;

   activePlan = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, buildingToMake);
   if (buildingToMake >= 0 && activePlan < 0)
   {
      activePlan = aiPlanCreate("Use an xpBuilder", cPlanBuild);
      // What to build
      aiPlanSetVariableInt(activePlan, cBuildPlanBuildingTypeID, 0, buildingToMake);

      // 3 meter separation
      aiPlanSetVariableFloat(activePlan, cBuildPlanBuildingBufferSpace, 0, 3.0);
      if (buildingToMake == gFarmUnit)
         aiPlanSetVariableFloat(activePlan, cBuildPlanBuildingBufferSpace, 0, 8.0);

      // Priority.
      aiPlanSetDesiredPriority(activePlan, 95);
      // Mil vs. Econ.
      if ((buildingToMake == cUnitTypeWarHut) || (buildingToMake == cUnitTypeCorral))
      {
         aiPlanSetMilitary(activePlan, true);
         aiPlanSetEconomy(activePlan, false);
      }
      else
      {
         aiPlanSetMilitary(activePlan, false);
         aiPlanSetEconomy(activePlan, true);
      }
      aiPlanSetEscrowID(activePlan, cEconomyEscrowID);

      aiPlanAddUnitType(activePlan, buildertype, 1, 1, 1);

      aiPlanSetBaseID(activePlan, kbBaseGetMainID(cMyID));

      // Go.
      aiPlanSetActive(activePlan);
   }
   else
   {
      aiPlanAddUnitType(activePlan, buildertype, 1, 1, 1);
   }
}

rule forwardShrineManager
inactive
minInterval 3
{
   static int monkQuery = -1;
   static int huntQuery = -1;
   static int shrineQuery = -1;
   static int tcQuery = -1;
   static int shrinePlanID = -1;
   int planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeypShrineJapanese);

   if (gLandExplorePlan < 0 || kbCanAffordUnit(cUnitTypeypShrineJapanese, cEconomyEscrowID) == false || planID >= 0)
   {
      if (gExplorerControlPlan >= 0)
      {
         if (aiPlanGetState(shrinePlanID) >= 0)
            aiPlanDestroy(shrinePlanID);
         xsDisableSelf();
      }
      return;
   }

   if (monkQuery < 0)
   {
      monkQuery = kbUnitQueryCreate("Monk query for shrine placement");
      kbUnitQuerySetPlayerID(monkQuery, cMyID);
      kbUnitQuerySetUnitType(monkQuery, cUnitTypeAbstractJapaneseMonk);
      kbUnitQuerySetIgnoreKnockedOutUnits(monkQuery, true);

      huntQuery = kbUnitQueryCreate("Huntable query for shrine placement");
      kbUnitQuerySetPlayerID(huntQuery, 0);
      kbUnitQuerySetUnitType(huntQuery, cUnitTypeHuntable);
      kbUnitQuerySetMaximumDistance(huntQuery, 30.0);

      shrineQuery = kbUnitQueryCreate("Shrine query for shrine placement");
      kbUnitQuerySetPlayerID(shrineQuery, -1);
      kbUnitQuerySetPlayerRelation(shrineQuery, cPlayerRelationAny);
      kbUnitQuerySetUnitType(shrineQuery, cUnitTypeypShrineJapanese);
      kbUnitQuerySetMaximumDistance(shrineQuery, 30.0);

      tcQuery = kbUnitQueryCreate("TC query for shrine placement");
      kbUnitQuerySetPlayerID(tcQuery, -1);
      kbUnitQuerySetPlayerRelation(tcQuery, cPlayerRelationAny);
      kbUnitQuerySetUnitType(tcQuery, cUnitTypeTownCenter);
      kbUnitQuerySetMaximumDistance(tcQuery, 50.0);
   }

   kbUnitQueryResetResults(monkQuery);
   int numberMonks = kbUnitQueryExecute(monkQuery);
   int numberHunts = 0;
   int numberShrines = 0;
   vector position = cInvalidVector;
   int builderID = -1;

   if (numberMonks == 0)
      return;

   // search for huntables nearby monks
   for (i = 0; < numberMonks)
   {
      builderID = kbUnitQueryGetResult(monkQuery, i);
      if (aiPlanGetType(kbUnitGetPlanID(builderID)) != cPlanExplore)
         continue;
      kbUnitQuerySetPosition(huntQuery, kbUnitGetPosition(builderID));
      kbUnitQueryResetResults(huntQuery);
      numberHunts = kbUnitQueryExecute(huntQuery);
      if (numberHunts < 3)
         continue;
      position = kbUnitGetPosition(kbUnitQueryGetResult(huntQuery, aiRandInt(numberHunts)));
      kbUnitQuerySetPosition(shrineQuery, position);
      kbUnitQueryResetResults(shrineQuery);
      numberShrines = kbUnitQueryExecute(shrineQuery);
      if (numberHunts < (4 * (numberShrines + 1) - 1))
         continue;
      kbUnitQuerySetPosition(tcQuery, position);
      kbUnitQueryResetResults(tcQuery);
      if (kbUnitQueryExecute(tcQuery) > 0)
         continue;
      planID = aiPlanCreate("Forward Shrine Build Plan", cPlanBuild);
      if (planID < 0)
         continue;
      // What to build
      aiPlanSetVariableInt(planID, cBuildPlanBuildingTypeID, 0, cUnitTypeypShrineJapanese);

      aiPlanSetVariableVector(planID, cBuildPlanCenterPosition, 0, position);
      aiPlanSetVariableFloat(planID, cBuildPlanCenterPositionDistance, 0, 30.0);

      // 3 meter separation
      aiPlanSetVariableFloat(planID, cBuildPlanBuildingBufferSpace, 0, 3.0);

      // Priority.
      aiPlanSetDesiredPriority(planID, 90);
      aiPlanSetDesiredResourcePriority(planID, 90);

      // Builders.
      aiPlanAddUnitType(planID, cUnitTypeAbstractJapaneseMonk, numberMonks, numberMonks, numberMonks);
      for (j = 0; < numberMonks)
         aiPlanAddUnit(planID, kbUnitQueryGetResult(monkQuery, j));

      aiPlanSetVariableVector(planID, cBuildPlanInfluencePosition, 0, position);              // Influence toward position
      aiPlanSetVariableFloat(planID, cBuildPlanInfluencePositionDistance, 0, 50.0);           // 50m range.
      aiPlanSetVariableFloat(planID, cBuildPlanInfluencePositionValue, 0, 200.0);             // 200 points max
      aiPlanSetVariableInt(planID, cBuildPlanInfluencePositionFalloff, 0, cBPIFalloffLinear); // Linear slope falloff

      aiPlanSetVariableInt(planID, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypeypShrineJapanese);
      aiPlanSetVariableFloat(planID, cBuildPlanInfluenceUnitDistance, 0, 10.0);
      aiPlanSetVariableFloat(planID, cBuildPlanInfluenceUnitValue, 0, -20.0);
      aiPlanSetVariableInt(planID, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffLinear);

      // Go.
      aiPlanSetActive(planID);
      debugBuildings("    Building a forward shrine at " + position);
      shrinePlanID = planID;
      break;
   }
}

rule strongholdConstructionMonitors
inactive
minInterval 75
{
   // We have no builder so making a plan is useless.
   // OR
   // We only have 1 War Chief who can build these Strongholds, so if we already have a plan it's senseless to create another.
   if ((aiGetFallenExplorerID() >= 0) ||
       (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypedeIncaStronghold, true) >= 0))
   {
      debugBuildings(
          "We have either no alive War Chief or already have a Stronghold build plan, quiting strongholdConstructionMonitor");
      return;
   }

   // The total amount may get higher when we get a Stronghold Travois after already having the max built.
   int amountToBeBuilt = -1;
   // Only 1 on Moderate since it's a pretty strong building.
   if (cDifficultyCurrent <= cDifficultyModerate)
   {
      amountToBeBuilt = 1;
   }
   else // Hard / Hardest / Extreme.
   {
      if (kbGetAge() == cAge3)
      {
         amountToBeBuilt = 2;
      }
      else // Industrial / Imperial.
      {
         amountToBeBuilt = 3;
      }
   }

   if (kbUnitCount(cMyID, cUnitTypedeIncaStronghold, cUnitStateABQ) +
           aiPlanGetNumberByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypedeIncaStronghold, true) <
       amountToBeBuilt)
   {
      createSimpleBuildPlan(cUnitTypedeIncaStronghold, 1, 50, false, -1, kbBaseGetMainID(cMyID));
   }
   else
   {
      debugBuildings("We already have the amount of Strongholds we want, don't create another plan");
   }
}

rule capitolConstructionMonitor
inactive
minInterval 60
{
   int capitolPUID = cUnitTypeCapitol; // Europeans and Mexico.
   if (cMyCiv == cCivDEAmericans)
   {
      capitolPUID = cUnitTypedeStateCapitol;
   }
   
   // We only get the 3 economic upgrades from the Capitol, after that we don't build it anymore.
   // And there is no point in getting Deforestation when there is no more wood on the map.
   bool canDisableSelf = false;
   int planID = -1;
   if (cMyCiv == cCivDEAmericans)
   {
      if ((kbTechGetStatus(cTechImpLargeScaleAgricultureAmericans) == cTechStatusActive) &&
          (kbTechGetStatus(cTechDECapitolGoldRush) == cTechStatusActive) &&
          ((kbTechGetStatus(cTechImpDeforestationAmericans) == cTechStatusActive) || (gGoldPercentageToBuyForWood > 0.0)))
      {
         canDisableSelf = true;
      }
   }
   else
   {
      if ((kbTechGetStatus(cTechImpLargeScaleAgriculture) == cTechStatusActive) &&
          (kbTechGetStatus(cTechImpExcessiveTaxation) == cTechStatusActive) &&
          ((kbTechGetStatus(cTechImpDeforestation) == cTechStatusActive) || (gGoldPercentageToBuyForWood > 0.0)))
      {
         canDisableSelf = true;
      }
   }
   
   if (canDisableSelf == true)
   {
      planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, capitolPUID);
      if (planID >= 0)
      {
         aiPlanDestroy(planID);
      }
      xsDisableSelf();
      return;
   }
   
   // We don't have all the economic upgrades we can get yet, build a Capitol.
   planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, capitolPUID);
   if ((planID < 0) && (kbUnitCount(cMyID, capitolPUID, cUnitStateAlive) < 1))
   {
      createSimpleBuildPlan(capitolPUID, 1, 50, true, cEconomyEscrowID, kbBaseGetMainID(cMyID), 1);
   }
}

/*
rule findNewBase
inactive
minInterval 10
{
   int numberBases = kbBaseGetNumber(cMyID);
   int mainBaseID = kbBaseGetMainID(cMyID);
   int baseID = -1;
   vector location = cInvalidVector;
   int newBaseID = -1;
   int numberPlans = 0;
   int planID = -1;

   // first go through existing bases.
   for (i = 0; < numberBases)
   {
      baseID = kbBaseGetIDByIndex(cMyID, i);
      location = kbBaseGetLocation(cMyID, baseID);
      if ((baseID == mainBaseID) || (kbBaseGetSettlement(cMyID, baseID) == false) ||
          (getAreaGroupNumberTiles(kbAreaGroupGetIDByPosition(location)) < 2000))
         continue;
      newBaseID = baseID;
      break;
   }

   if (newBaseID >= 0)
   {
      aiSwitchMainBase(newBaseID);
      // kill all existing build plans.
      numberPlans = aiPlanGetActiveCount();
      for (i = 0; < numberPlans)
      {
         planID = aiPlanGetIDByActiveIndex(i);
         if (aiPlanGetType(planID) == cPlanBuild && aiPlanGetState(planID) != cPlanStateBuild)
         {
            aiPlanDestroy(planID);
         }
      }
      xsDisableSelf();
   }
}
*/
rule delayWalls
inactive
minInterval 60
{
   //if ((kbGetPopCap() - kbGetPop()) < 100)
   //   return; // Don't start walls until we have pop room
  //if (xsGetTime() < 20 * 60 * 1000)
  //    return;
  
  //if ((kbGetAge() >= cvMaxAge) || (gRevolutionType != 0))
  //    return;
  
  gBuildWalls = true;
	  
  //xsEnableRule("delayWallsMonitor");
  xsDisableSelf();	
}

rule delayWallsMonitor
inactive
minInterval 10
{
         xsEnableRule("delayWalls1");  
         //xsEnableRule("delayWalls2");
         //xsEnableRule("delayWalls3");
         xsDisableSelf();	
}
   
rule delayWalls1
inactive
minInterval 10
{
   int wallPlanID = aiPlanCreate("WallInBase1", cPlanBuildWall);
   if (wallPlanID != -1)
   {
      aiPlanSetVariableInt(wallPlanID, cBuildWallPlanWallType, 0, cBuildWallPlanWallTypeRing);
      aiPlanAddUnitType(wallPlanID, gEconUnit, 0, 1, 1);
      aiPlanSetVariableVector(
          wallPlanID, cBuildWallPlanWallRingCenterPoint, 0, kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)));
      aiPlanSetVariableFloat(wallPlanID, cBuildWallPlanWallRingRadius, 0, 60.0);
      aiPlanSetVariableInt(wallPlanID, cBuildWallPlanNumberOfGates, 0, 4);
      aiPlanSetBaseID(wallPlanID, kbBaseGetMainID(cMyID));
      aiPlanSetEscrowID(wallPlanID, cEconomyEscrowID);
      aiPlanSetDesiredPriority(wallPlanID, 90);
      aiPlanSetActive(wallPlanID, true);
      sendStatement(cPlayerRelationAlly, cAICommPromptToAllyWhenIWallIn);
      // Enable our wall gap rule, too.
      xsEnableRule("fillInWallGaps1");
      debugBuildings("Enabling Wall Plan for Base ID: " + kbBaseGetMainID(cMyID));
   }
   xsDisableSelf();
}

rule delayWalls2
inactive
minInterval 10
{
	int WallConnector = getUnit(cUnitTypeWallConnector, cMyID, cUnitStateAlive);
    createSimpleResearchPlan(cTechBastion, WallConnector, cEconomyEscrowID, 80);
   int wallPlanID = aiPlanCreate("WallInBase2", cPlanBuildWall);
   if (wallPlanID != -1)
   {
      aiPlanSetVariableInt(wallPlanID, cBuildWallPlanWallType, 0, cBuildWallPlanWallTypeRing);
      aiPlanAddUnitType(wallPlanID, gEconUnit, 0, 1, 1);
      aiPlanSetVariableVector(
          wallPlanID, cBuildWallPlanWallRingCenterPoint, 0, kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)));
      aiPlanSetVariableFloat(wallPlanID, cBuildWallPlanWallRingRadius, 0, 80.0);
      aiPlanSetVariableInt(wallPlanID, cBuildWallPlanNumberOfGates, 0, 6);
      aiPlanSetBaseID(wallPlanID, kbBaseGetMainID(cMyID));
      aiPlanSetEscrowID(wallPlanID, cEconomyEscrowID);
      aiPlanSetDesiredPriority(wallPlanID, 80);
      aiPlanSetActive(wallPlanID, true);
      sendStatement(cPlayerRelationAlly, cAICommPromptToAllyWhenIWallIn);
      // Enable our wall gap rule, too.
      xsEnableRule("fillInWallGaps2");
      debugBuildings("Enabling Wall Plan for Base ID: " + kbBaseGetMainID(cMyID));
   }
   xsDisableSelf();
}

rule delayWalls3
inactive
minInterval 10
{
	int WallConnector = getUnit(cUnitTypeWallConnector, cMyID, cUnitStateAlive);
    createSimpleResearchPlan(cTechBastion, WallConnector, cEconomyEscrowID, 80);
   int wallPlanID = aiPlanCreate("WallInBase3", cPlanBuildWall);
   if (wallPlanID != -1)
   {
      aiPlanSetVariableInt(wallPlanID, cBuildWallPlanWallType, 0, cBuildWallPlanWallTypeRing);
      aiPlanAddUnitType(wallPlanID, gEconUnit, 0, 1, 1);
      aiPlanSetVariableVector(
          wallPlanID, cBuildWallPlanWallRingCenterPoint, 0, kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)));
      aiPlanSetVariableFloat(wallPlanID, cBuildWallPlanWallRingRadius, 0, 60.0);
      aiPlanSetVariableInt(wallPlanID, cBuildWallPlanNumberOfGates, 0, 4);
      aiPlanSetBaseID(wallPlanID, kbBaseGetMainID(cMyID));
      aiPlanSetEscrowID(wallPlanID, cEconomyEscrowID);
      aiPlanSetDesiredPriority(wallPlanID, 80);
      aiPlanSetActive(wallPlanID, true);
      sendStatement(cPlayerRelationAlly, cAICommPromptToAllyWhenIWallIn);
      // Enable our wall gap rule, too.
      xsEnableRule("fillInWallGaps3");
      debugBuildings("Enabling Wall Plan for Base ID: " + kbBaseGetMainID(cMyID));
   }
   xsDisableSelf();
}

//==============================================================================
// RULE fillInWallGaps
//==============================================================================
rule fillInWallGaps1
minInterval 10
inactive
{
   // If we're not building walls, go away.
   if (gBuildWalls == false)
   {
      xsDisableSelf();
      return;
   }
   
   	int WallConnector = getUnit(cUnitTypeWallConnector, cMyID, cUnitStateAlive);
    createSimpleResearchPlan(cTechBastion, WallConnector, cEconomyEscrowID, 90);

   // If we already have a build wall plan, don't make another one.
   if (aiPlanGetIDByTypeAndVariableType(cPlanBuildWall, cBuildWallPlanWallType, cBuildWallPlanWallTypeRing, true) >= 0)
      return;

   int wallPlanID = aiPlanCreate("FillInWallGaps1", cPlanBuildWall);
   if (wallPlanID != -1)
   {
      aiPlanSetVariableInt(wallPlanID, cBuildWallPlanWallType, 0, cBuildWallPlanWallTypeRing);
      aiPlanAddUnitType(wallPlanID, cUnitTypeSettler, 1, 1, 1);
      aiPlanSetVariableVector(
          wallPlanID, cBuildWallPlanWallRingCenterPoint, 0, kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)));
      aiPlanSetVariableFloat(wallPlanID, cBuildWallPlanWallRingRadius, 0, 60.0);
      aiPlanSetVariableInt(wallPlanID, cBuildWallPlanNumberOfGates, 0, 4);
      aiPlanSetBaseID(wallPlanID, kbBaseGetMainID(cMyID));
      aiPlanSetEscrowID(wallPlanID, cEconomyEscrowID);
      aiPlanSetDesiredPriority(wallPlanID, 90);
      aiPlanSetActive(wallPlanID, true);
   }
}

rule fillInWallGaps2
minInterval 10
inactive
{
   // If we're not building walls, go away.
   if (gBuildWalls == false)
   {
      xsDisableSelf();
      return;
   }

   // If we already have a build wall plan, don't make another one.
   if (aiPlanGetIDByTypeAndVariableType(cPlanBuildWall, cBuildWallPlanWallType, cBuildWallPlanWallTypeRing, true) >= 0)
      return;

   int wallPlanID = aiPlanCreate("FillInWallGaps2", cPlanBuildWall);
   if (wallPlanID != -1)
   {
      aiPlanSetVariableInt(wallPlanID, cBuildWallPlanWallType, 0, cBuildWallPlanWallTypeRing);
      aiPlanAddUnitType(wallPlanID, cUnitTypeSettler, 1, 1, 1);
      aiPlanSetVariableVector(
          wallPlanID, cBuildWallPlanWallRingCenterPoint, 0, kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)));
      aiPlanSetVariableFloat(wallPlanID, cBuildWallPlanWallRingRadius, 0, 80.0);
      aiPlanSetVariableInt(wallPlanID, cBuildWallPlanNumberOfGates, 0, 6);
      aiPlanSetBaseID(wallPlanID, kbBaseGetMainID(cMyID));
      aiPlanSetEscrowID(wallPlanID, cEconomyEscrowID);
      aiPlanSetDesiredPriority(wallPlanID, 80);
      aiPlanSetActive(wallPlanID, true);
   }
}

rule fillInWallGaps3
minInterval 10
inactive
{
   // If we're not building walls, go away.
   if (gBuildWalls == false)
   {
      xsDisableSelf();
      return;
   }

   // If we already have a build wall plan, don't make another one.
   if (aiPlanGetIDByTypeAndVariableType(cPlanBuildWall, cBuildWallPlanWallType, cBuildWallPlanWallTypeRing, true) >= 0)
      return;

   int wallPlanID = aiPlanCreate("FillInWallGaps3", cPlanBuildWall);
   if (wallPlanID != -1)
   {
      aiPlanSetVariableInt(wallPlanID, cBuildWallPlanWallType, 0, cBuildWallPlanWallTypeRing);
      aiPlanAddUnitType(wallPlanID, cUnitTypeSettler, 1, 1, 1);
      aiPlanSetVariableVector(
          wallPlanID, cBuildWallPlanWallRingCenterPoint, 0, kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)));
      aiPlanSetVariableFloat(wallPlanID, cBuildWallPlanWallRingRadius, 0, 60.0);
      aiPlanSetVariableInt(wallPlanID, cBuildWallPlanNumberOfGates, 0, 4);
      aiPlanSetBaseID(wallPlanID, kbBaseGetMainID(cMyID));
      aiPlanSetEscrowID(wallPlanID, cEconomyEscrowID);
      aiPlanSetDesiredPriority(wallPlanID, 80);
      aiPlanSetActive(wallPlanID, true);
   }
}
