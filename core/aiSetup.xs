//==============================================================================
/* aiSetup.xs

   This file contains all functions and rules for initialization.

*/

//==============================================================================
/* initCivUnitTypes
   Initialize all global civilisation specific unit types.
*/
//==============================================================================
void initCivUnitTypes()
{
   debugSetup("         Initialising civilisation specific unit types");
   if (civIsEuropean() == true)
   {
      if (cMyCiv == cCivDutch)
      {
         gGalleonUnit = cUnitTypeFluyt;
      }
      
      if (cMyCiv == cCivFrench)
      {
         gEconUnit = cUnitTypeCoureur;
      }
      
      if (cMyCiv == cCivRussians)
      {
         gTowerUnit = cUnitTypeBlockhouse;
      }
   
      if (cMyCiv == cCivOttomans)
      {
         gCaravelUnit = cUnitTypeGalley;
      }
         
      if ((cMyCiv == cCivBritish) || (cMyCiv == cCivTheCircle) || (cMyCiv == cCivPirate) || (cMyCiv == cCivSPCAct3))
      {
         gHouseUnit = cUnitTypeManor;
      }
      
      if ((cMyCiv == cCivFrench) || (cMyCiv == cCivDutch) || (cMyCiv == cCivDEAmericans))
      {
         gHouseUnit = cUnitTypeHouse;
      }
      
      if ((cMyCiv == cCivGermans) || (cMyCiv == cCivRussians))
      {
         gHouseUnit = cUnitTypeHouseEast;
      }
   
      if ((cMyCiv == cCivSpanish) || (cMyCiv == cCivPortuguese) || (cMyCiv == cCivOttomans) || (cMyCiv == cCivDEMexicans))
      {
         gHouseUnit = cUnitTypeHouseMed;
      }
      
      if (cMyCiv == cCivDESwedish)
      {
         gHouseUnit = cUnitTypedeTorp;
      }
      
      if (cMyCiv == cCivDEAmericans || cMyCiv == cCivDEMexicans)
      {
         gCaravelUnit = cUnitTypedeSloop;
         gGalleonUnit = cUnitTypedeSteamer;
         gMonitorUnit = cUnitTypexpIronclad;
      }
   
      if (cMyCiv == cCivDEMexicans)
      {
         gFarmUnit = cUnitTypedeHacienda;
         gPlantationUnit = cUnitTypedeHacienda;
   
         cMaxSettlersPerFarm = 20;
         cMaxSettlersPerPlantation = 20;
   
         gFarmFoodTactic = cTacticHaciendaFood;
         gFarmGoldTactic = cTacticHaciendaCoin;
      }
   }
   
   if (civIsNative() == true)
   {
      gEconUnit = cUnitTypeSettlerNative;
      gCaravelUnit = cMyCiv == cCivDEInca ? cUnitTypedeChinchaRaft : cUnitTypexpWarCanoe;
      gTowerUnit = cUnitTypeWarHut;
      gFarmUnit = cUnitTypeFarm;
      
      if (cMyCiv == cCivXPIroquois)
      {
         gHouseUnit = cUnitTypeLonghouse;
      }
    
      if (cMyCiv == cCivXPAztec)
      {
         gHouseUnit = cUnitTypeHouseAztec;
         gFrigateUnit = cUnitTypexpTlalocCanoe;
      }
    
      if (cMyCiv == cCivDEInca)
      {
         gHouseUnit = cUnitTypedeHouseInca;
      }
      
      if (cMyCiv == cCivXPAztec || cMyCiv == cCivXPIroquois || cMyCiv == cCivXPSioux)
      {
         gGalleonUnit = cUnitTypeCanoe;
      }
   }
   
   if (civIsAsian() == true)
   {
      gTowerUnit = cUnitTypeypCastle;
      gFarmUnit = cUnitTypeypRicePaddy;
      gPlantationUnit = cUnitTypeypRicePaddy;
      gMarketUnit = cUnitTypeypTradeMarketAsian;
      gDockUnit = cUnitTypeYPDockAsian;
      cvOkToBuildForts = false;
      gFishingUnit = cUnitTypeypFishingBoatAsian;
      gFarmFoodTactic = cTacticPaddyFood;
      gFarmGoldTactic = cTacticPaddyCoin;
      
      if ((cMyCiv == cCivChinese) || (cMyCiv == cCivSPCChinese))
      {
         gEconUnit = cUnitTypeypSettlerAsian;
         gHouseUnit = cUnitTypeypVillage;
         gCaravelUnit = cUnitTypeypWarJunk;
         gFrigateUnit = cUnitTypeypFuchuan;
         gLivestockPenUnit = cUnitTypeypVillage;
      }
   
      if ((cMyCiv == cCivJapanese) || (cMyCiv == cCivSPCJapanese) || (cMyCiv == cCivSPCJapaneseEnemy))
      {
         gEconUnit = cUnitTypeypSettlerJapanese;
         gHouseUnit = cUnitTypeypShrineJapanese;
         gCaravelUnit = cUnitTypeypFune;
         gGalleonUnit = cUnitTypeypAtakabune;
         gFrigateUnit = cUnitTypeypTekkousen;
         gLivestockPenUnit = cUnitTypeypShrineJapanese;
      }
   
      if ((cMyCiv == cCivIndians) || (cMyCiv == cCivSPCIndians))
      {
         gHouseUnit = cUnitTypeypHouseIndian;
         gLivestockPenUnit = cUnitTypeypSacredField;
         gEconUnit = cUnitTypeypSettlerIndian;
      }
   }
   
   if (civIsAfrican() == true)
   {
      gEconUnit = cUnitTypedeSettlerAfrican;
      gHouseUnit = cUnitTypedeHouseAfrican;

      gTowerUnit = cUnitTypedeTower;
      gFarmUnit = cUnitTypedeField;
      gPlantationUnit = cUnitTypedeField;

      gMarketUnit = cUnitTypedeLivestockMarket;
      gDockUnit = cUnitTypedePort;
      gLivestockPenUnit = cUnitTypedeLivestockMarket;

      gFishingUnit = cUnitTypedeFishingBoatAfrican;
      gCaravelUnit = cUnitTypedeBattleCanoe;
      if (cMyCiv == cCivDEEthiopians)
      {
         gFrigateUnit = cUnitTypedeMercDhow;
      }
      else // Hausa
      {
         gFrigateUnit = cUnitTypedeMercXebec;
      }
      gMonitorUnit = cUnitTypedeCannonBoat;

      cMaxSettlersPerFarm = 3;
      cMaxSettlersPerPlantation = 3;

      gFarmFoodTactic = cTacticFieldFood;
      gFarmGoldTactic = cTacticFieldCoin;
   }
}

//==============================================================================
/* initArrays
   Initialize all global arrays here, to make it easy to find var type and size.
*/
//==============================================================================

void initArrays(void)
{
   debugSetup("         Initialising global arrays");
   //==============================================================================
   // Core.
   //==============================================================================

   gTargetSettlerCounts = xsArrayCreateInt(cAge5 + 1, 0, "Target Settler Counts");

   switch (cDifficultyCurrent)
   {
   case cDifficultySandbox: // Easy
   {
      xsArraySetInt(gTargetSettlerCounts, cAge1, 99);
      xsArraySetInt(gTargetSettlerCounts, cAge2, 99);
      xsArraySetInt(gTargetSettlerCounts, cAge3, 99);
      xsArraySetInt(gTargetSettlerCounts, cAge4, 99);
      xsArraySetInt(gTargetSettlerCounts, cAge5, 99);
      break;
   }
   case cDifficultyEasy: // Standard
   {
      xsArraySetInt(gTargetSettlerCounts, cAge1, 99);
      xsArraySetInt(gTargetSettlerCounts, cAge2, 99);
      if (gSPC == true)
      {
         xsArraySetInt(gTargetSettlerCounts, cAge3, 99);
         xsArraySetInt(gTargetSettlerCounts, cAge4, 99);
         xsArraySetInt(gTargetSettlerCounts, cAge5, 99);
      }
      else
      {
         xsArraySetInt(gTargetSettlerCounts, cAge3, 99);
         xsArraySetInt(gTargetSettlerCounts, cAge4, 99);
         xsArraySetInt(gTargetSettlerCounts, cAge5, 99);
      }
      break;
   }
   case cDifficultyModerate: // Moderate
   {
      xsArraySetInt(gTargetSettlerCounts, cAge1, 99);
      xsArraySetInt(gTargetSettlerCounts, cAge2, 99);
      if (gSPC == true)
      {
         xsArraySetInt(gTargetSettlerCounts, cAge3, 99);
         xsArraySetInt(gTargetSettlerCounts, cAge4, 99);
         xsArraySetInt(gTargetSettlerCounts, cAge5, 99);
      }
      else
      {
         xsArraySetInt(gTargetSettlerCounts, cAge3, 99);
         xsArraySetInt(gTargetSettlerCounts, cAge4, 99);
         xsArraySetInt(gTargetSettlerCounts, cAge5, 99);
      }
      break;
   }
   case cDifficultyHard: // Hard
   {
      xsArraySetInt(gTargetSettlerCounts, cAge1, 99);
      xsArraySetInt(gTargetSettlerCounts, cAge2, 99);
      if (gSPC == true)
      {
         xsArraySetInt(gTargetSettlerCounts, cAge3, 99);
         xsArraySetInt(gTargetSettlerCounts, cAge4, 99);
         xsArraySetInt(gTargetSettlerCounts, cAge5, 99);
      }
      else
      {
         xsArraySetInt(gTargetSettlerCounts, cAge3, 99);
         xsArraySetInt(gTargetSettlerCounts, cAge4, 99);
         xsArraySetInt(gTargetSettlerCounts, cAge5, 99);
      }
      break;
   }
   default: // Hardest and Extreme
   {
      xsArraySetInt(gTargetSettlerCounts, cAge1, 99);
      xsArraySetInt(gTargetSettlerCounts, cAge2, 99);
      xsArraySetInt(gTargetSettlerCounts, cAge3, 99);
      xsArraySetInt(gTargetSettlerCounts, cAge4, 99);
      xsArraySetInt(gTargetSettlerCounts, cAge5, 99);
      break;
   }
   }

   gTargetSettlerCountsDefault = xsArrayCreateInt(cAge5 + 1, 0, "Default Target Settler Counts");
   for (i = cAge1; <= cAge5) // Fill the gTargetSettlerCountsDefault array with the default values for regular civs.
   {
      xsArraySetInt(gTargetSettlerCountsDefault, i, xsArrayGetInt(gTargetSettlerCounts, i));
   }

   // Start overriding the gTargetSettlerCounts depending on if we're a civ that has some custom Settler limit logic.
   if (cMyCiv == cCivFrench)
   {
      for (i = cAge1; <= cAge5) // Need fewer Coureur de Bois.
      {
         xsArraySetInt(gTargetSettlerCounts, i, xsArrayGetInt(gTargetSettlerCounts, i) * 0.9);
      }
      // And correct to our build limit on higher limits.
      //if (cDifficultyCurrent == cDifficultyHard)
      //{
         if (gSPC == false) // Otherwise just leave the defaults which will function fine.
         {
            xsArraySetInt(gTargetSettlerCounts, cAge1, 80);
            xsArraySetInt(gTargetSettlerCounts, cAge2, 80);
            xsArraySetInt(gTargetSettlerCounts, cAge3, 80);
            xsArraySetInt(gTargetSettlerCounts, cAge4, 80);
            xsArraySetInt(gTargetSettlerCounts, cAge5, 80);
         }
      //}
      else// if (cDifficultyCurrent >= cDifficultyExpert)
      {
         xsArraySetInt(gTargetSettlerCounts, cAge1, 80);
         xsArraySetInt(gTargetSettlerCounts, cAge2, 80);
         xsArraySetInt(gTargetSettlerCounts, cAge3, 80);
         xsArraySetInt(gTargetSettlerCounts, cAge4, 80);
         xsArraySetInt(gTargetSettlerCounts, cAge5, 80);
      }
   }
   if (cMyCiv == cCivDutch)
   {
      switch (cDifficultyCurrent)
      {
      case cDifficultySandbox: // Easy
      {
         xsArraySetInt(gTargetSettlerCounts, cAge1, 50);
         xsArraySetInt(gTargetSettlerCounts, cAge2, 50);
         xsArraySetInt(gTargetSettlerCounts, cAge3, 60);
         xsArraySetInt(gTargetSettlerCounts, cAge4, 60);
         xsArraySetInt(gTargetSettlerCounts, cAge5, 60);
         break;
      }
      case cDifficultyEasy: // Standard
      {
         xsArraySetInt(gTargetSettlerCounts, cAge1, 50);
         xsArraySetInt(gTargetSettlerCounts, cAge2, 50);
         xsArraySetInt(gTargetSettlerCounts, cAge3, 60);
         xsArraySetInt(gTargetSettlerCounts, cAge4, 60);
         xsArraySetInt(gTargetSettlerCounts, cAge5, 60);
         break;
      }
      case cDifficultyModerate: // Moderate
      {
         xsArraySetInt(gTargetSettlerCounts, cAge1, 50);
         xsArraySetInt(gTargetSettlerCounts, cAge2, 50);
         xsArraySetInt(gTargetSettlerCounts, cAge3, 60);
         xsArraySetInt(gTargetSettlerCounts, cAge4, 60);
         xsArraySetInt(gTargetSettlerCounts, cAge5, 60);
         break;
      }
      default: // Hard / Hardest / Extreme
      {
         xsArraySetInt(gTargetSettlerCounts, cAge1, 50);
         xsArraySetInt(gTargetSettlerCounts, cAge2, 50);
         xsArraySetInt(gTargetSettlerCounts, cAge3, 60);
         xsArraySetInt(gTargetSettlerCounts, cAge4, 60);
         xsArraySetInt(gTargetSettlerCounts, cAge5, 60);
         break;
      }
      }
   }
	  if (cMyCiv == cCivJapanese)
   {
      switch (cDifficultyCurrent)
      {
      case cDifficultySandbox: // Easy
      {
         xsArraySetInt(gTargetSettlerCounts, cAge1, 75);
         xsArraySetInt(gTargetSettlerCounts, cAge2, 75);
         xsArraySetInt(gTargetSettlerCounts, cAge3, 75);
         xsArraySetInt(gTargetSettlerCounts, cAge4, 75);
         xsArraySetInt(gTargetSettlerCounts, cAge5, 75);
         break;
      }
      case cDifficultyEasy: // Standard
      {
         xsArraySetInt(gTargetSettlerCounts, cAge1, 75);
         xsArraySetInt(gTargetSettlerCounts, cAge2, 75);
         xsArraySetInt(gTargetSettlerCounts, cAge3, 75);
         xsArraySetInt(gTargetSettlerCounts, cAge4, 75);
         xsArraySetInt(gTargetSettlerCounts, cAge5, 75);
         break;
      }
      case cDifficultyModerate: // Moderate
      {
         xsArraySetInt(gTargetSettlerCounts, cAge1, 75);
         xsArraySetInt(gTargetSettlerCounts, cAge2, 75);
         xsArraySetInt(gTargetSettlerCounts, cAge3, 75);
         xsArraySetInt(gTargetSettlerCounts, cAge4, 75);
         xsArraySetInt(gTargetSettlerCounts, cAge5, 75);
         break;
      }
      default: // Hard / Hardest / Extreme
      {
         xsArraySetInt(gTargetSettlerCounts, cAge1, 75);
         xsArraySetInt(gTargetSettlerCounts, cAge2, 75);
         xsArraySetInt(gTargetSettlerCounts, cAge3, 75);
         xsArraySetInt(gTargetSettlerCounts, cAge4, 75);
         xsArraySetInt(gTargetSettlerCounts, cAge5, 75);
         break;
      }
      }
   }
	  if (cMyCiv == cCivDEMexicans)
   {
      switch (cDifficultyCurrent)
      {
      case cDifficultySandbox: // Easy
      {
         xsArraySetInt(gTargetSettlerCounts, cAge1, 80);
         xsArraySetInt(gTargetSettlerCounts, cAge2, 80);
         xsArraySetInt(gTargetSettlerCounts, cAge3, 80);
         xsArraySetInt(gTargetSettlerCounts, cAge4, 80);
         xsArraySetInt(gTargetSettlerCounts, cAge5, 80);
         break;
      }
      case cDifficultyEasy: // Standard
      {
         xsArraySetInt(gTargetSettlerCounts, cAge1, 80);
         xsArraySetInt(gTargetSettlerCounts, cAge2, 80);
         xsArraySetInt(gTargetSettlerCounts, cAge3, 80);
         xsArraySetInt(gTargetSettlerCounts, cAge4, 80);
         xsArraySetInt(gTargetSettlerCounts, cAge5, 80);
         break;
      }
      case cDifficultyModerate: // Moderate
      {
         xsArraySetInt(gTargetSettlerCounts, cAge1, 80);
         xsArraySetInt(gTargetSettlerCounts, cAge2, 80);
         xsArraySetInt(gTargetSettlerCounts, cAge3, 80);
         xsArraySetInt(gTargetSettlerCounts, cAge4, 80);
         xsArraySetInt(gTargetSettlerCounts, cAge5, 80);
         break;
      }
      default: // Hard / Hardest / Extreme
      {
         xsArraySetInt(gTargetSettlerCounts, cAge1, 80);
         xsArraySetInt(gTargetSettlerCounts, cAge2, 80);
         xsArraySetInt(gTargetSettlerCounts, cAge3, 80);
         xsArraySetInt(gTargetSettlerCounts, cAge4, 80);
         xsArraySetInt(gTargetSettlerCounts, cAge5, 80);
         break;
      }
      }
   }

   //==============================================================================
   // Buildings.
   //==============================================================================

   if (cMyCiv == cCivDESwedish)
   {
      gTorpPositionsToAvoid = xsArrayCreateVector(1, cInvalidVector, "Torp Positions To Avoid");
   }

   if (cMyCiv == cCivXPAztec)
   {
      gMilitaryBuildings = xsArrayCreateInt(3, -1, "Military Buildings");
      xsArraySetInt(gMilitaryBuildings, 0, cUnitTypeWarHut);
      xsArraySetInt(gMilitaryBuildings, 1, cUnitTypeNoblesHut);
      xsArraySetInt(gMilitaryBuildings, 2, cUnitTypeNativeEmbassy);
   }
   else if (cMyCiv == cCivXPIroquois)
   {
      gMilitaryBuildings = xsArrayCreateInt(3, -1, "Military Buildings");
      xsArraySetInt(gMilitaryBuildings, 0, cUnitTypeWarHut);
      xsArraySetInt(gMilitaryBuildings, 1, cUnitTypeCorral);
      xsArraySetInt(gMilitaryBuildings, 2, cUnitTypeArtilleryDepot);
      xsArraySetInt(gMilitaryBuildings, 3, cUnitTypeNativeEmbassy);
   }
   else if (cMyCiv == cCivXPSioux)
   {
      gMilitaryBuildings = xsArrayCreateInt(2, -1, "Military Buildings");
      xsArraySetInt(gMilitaryBuildings, 0, cUnitTypeWarHut);
      xsArraySetInt(gMilitaryBuildings, 1, cUnitTypeCorral);
      xsArraySetInt(gMilitaryBuildings, 2, cUnitTypeNativeEmbassy);
   }
   else if (cMyCiv == cCivDEInca)
   {
      gMilitaryBuildings = xsArrayCreateInt(2, -1, "Military Buildings");
      xsArraySetInt(gMilitaryBuildings, 0, cUnitTypeWarHut);
      xsArraySetInt(gMilitaryBuildings, 1, cUnitTypedeKallanka);
      xsArraySetInt(gMilitaryBuildings, 2, cUnitTypeNativeEmbassy);
   }
   else if (cMyCiv == cCivChinese || cMyCiv == cCivSPCChinese)
   {
      gMilitaryBuildings = xsArrayCreateInt(3, -1, "Military Buildings");
      xsArraySetInt(gMilitaryBuildings, 0, cUnitTypeypWarAcademy);
      xsArraySetInt(gMilitaryBuildings, 1, cUnitTypeypCastle);
      xsArraySetInt(gMilitaryBuildings, 2, cUnitTypeypMonastery);
   }
   else if (cMyCiv == cCivIndians || cMyCiv == cCivSPCIndians)
   {
      gMilitaryBuildings = xsArrayCreateInt(4, -1, "Military Buildings");
      xsArraySetInt(gMilitaryBuildings, 0, cUnitTypeYPBarracksIndian);
      xsArraySetInt(gMilitaryBuildings, 1, cUnitTypeypCaravanserai);
      xsArraySetInt(gMilitaryBuildings, 2, cUnitTypeypCastle);
      xsArraySetInt(gMilitaryBuildings, 3, cUnitTypeypMonastery);
   }
   else if (cMyCiv == cCivJapanese || cMyCiv == cCivSPCJapanese || cMyCiv == cCivSPCJapaneseEnemy)
   {
      gMilitaryBuildings = xsArrayCreateInt(5, -1, "Military Buildings");
      xsArraySetInt(gMilitaryBuildings, 0, cUnitTypeypBarracksJapanese);
      xsArraySetInt(gMilitaryBuildings, 1, cUnitTypeypStableJapanese);
      xsArraySetInt(gMilitaryBuildings, 2, cUnitTypeypCastle);
      xsArraySetInt(gMilitaryBuildings, 3, cUnitTypeypMonastery);
      xsArraySetInt(gMilitaryBuildings, 4, cUnitTypeypChurch);
   }
   else if (cMyCiv == cCivDEHausa || cMyCiv == cCivDEEthiopians)
   {
      gMilitaryBuildings = xsArrayCreateInt(2, -1, "Military Buildings");
      xsArraySetInt(gMilitaryBuildings, 0, cUnitTypedeWarCamp);
      xsArraySetInt(gMilitaryBuildings, 1, cUnitTypedeTower);
   }
   else if (cMyCiv == cCivRussians)
   {
      gMilitaryBuildings = xsArrayCreateInt(5, -1, "Military Buildings");
      xsArraySetInt(gMilitaryBuildings, 0, cUnitTypeBlockhouse);
      xsArraySetInt(gMilitaryBuildings, 1, cUnitTypeStable);
      xsArraySetInt(gMilitaryBuildings, 2, cUnitTypeArtilleryDepot);
      xsArraySetInt(gMilitaryBuildings, 3, cUnitTypedeTavern);
      xsArraySetInt(gMilitaryBuildings, 4, cUnitTypeChurch);
   }
   else
   {
      gMilitaryBuildings = xsArrayCreateInt(5, -1, "Military Buildings");
      xsArraySetInt(gMilitaryBuildings, 0, cUnitTypeBarracks);
      xsArraySetInt(gMilitaryBuildings, 1, cUnitTypeStable);
      xsArraySetInt(gMilitaryBuildings, 2, cUnitTypeArtilleryDepot);
      if (cMyCiv == cCivDEAmericans || cMyCiv == cCivDEMexicans)
         xsArraySetInt(gMilitaryBuildings, 3, cUnitTypeSaloon);
      else
         xsArraySetInt(gMilitaryBuildings, 3, cUnitTypedeTavern);
      xsArraySetInt(gMilitaryBuildings, 4, cUnitTypeChurch);
   }
   gArmyUnitBuildings = xsArrayCreateInt(gNumArmyUnitTypes, -1, "Army Unit Buildings");
   gQueuedBuildPlans = xsArrayCreateInt(5, -1, "Queued build plans");
   gFullGranaries = xsArrayCreateInt(20, -1, "Full Granaries");

   //==============================================================================
   // Techs, TR part is also for Economy.
   //==============================================================================

   gNumberTradeRoutes = kbGetNumberTradeRoutes();
   if (gNumberTradeRoutes > 0)
   {
      debugSetup("Amount of Trading Routes found: " + gNumberTradeRoutes);
      gTradeRouteIndexAndType = xsArrayCreateInt(gNumberTradeRoutes, -1, "Trade Route Types");
      gTradeRouteIndexMaxUpgraded = xsArrayCreateBool(gNumberTradeRoutes, false, "Trade Route Max Upgraded");
      // We have to save 4 crates per route. Infuence is always the same but it must be saved for the logic to work.
      gTradeRouteCrates = xsArrayCreateInt(gNumberTradeRoutes * 4, -1, "Trade Route Crates"); 
      // Always 2 upgrades per route.
      gTradeRouteUpgrades = xsArrayCreateInt(gNumberTradeRoutes * 2, -1, "Trade Route Upgrades");

      int firstMovingUnit = -1;
      int firstMovingUnitProtoID = -1;
      for (i = 0; < gNumberTradeRoutes)
      {
         xsSetContextPlayer(0);
         if (kbUnitGetPlayerID(kbTradeRouteGetTradingPostID(i, 0)) == 0)
         {
            xsSetContextPlayer(cMyID);
            xsArraySetBool(gTradeRouteIndexMaxUpgraded, i, true);
            if (kbTechGetStatus(cTechdeMapAfrican) == cTechStatusActive)
            {
               debugSetup("Route: " + i + " is an African capturable Trading Route which can't be upgraded");
               xsArraySetInt(gTradeRouteIndexAndType, i, cTradeRouteCapturableAfrica);
               xsArraySetInt(gTradeRouteCrates, 0 + (i * 4), cUnitTypedeCrateofCoinAfrican1);
               xsArraySetInt(gTradeRouteCrates, 1 + (i * 4), cUnitTypedeCrateofWoodAfrican1);
               xsArraySetInt(gTradeRouteCrates, 2 + (i * 4), cUnitTypedeCrateofFoodAfrican1);
               xsArraySetInt(gTradeRouteCrates, 3 + (i * 4), cUnitTypedeTradeCrateofInfluence);
            }
            else
            {
               debugSetup("Route: " + i + " is an Asian capturable Trading Route which can't be upgraded");
               xsArraySetInt(gTradeRouteIndexAndType, i, cTradeRouteCapturableAsia);
               xsArraySetInt(gTradeRouteCrates, 0 + (i * 4), cUnitTypeypTradeCrateofCoin);
               xsArraySetInt(gTradeRouteCrates, 1 + (i * 4), cUnitTypeypTradeCrateofWood);
               xsArraySetInt(gTradeRouteCrates, 2 + (i * 4), cUnitTypeypTradeCrateofFood);
               xsArraySetInt(gTradeRouteCrates, 3 + (i * 4), cUnitTypedeTradeCrateofInfluence);
            }
            continue;
         }
         xsSetContextPlayer(cMyID);
         firstMovingUnit = kbTradeRouteGetUnit(i, 0);
         firstMovingUnitProtoID = kbUnitGetProtoUnitID(firstMovingUnit);
         if ((firstMovingUnitProtoID == cUnitTypedeTradingShip) || (firstMovingUnitProtoID == cUnitTypedeTradingGalleon) ||
             (firstMovingUnitProtoID == cUnitTypedeTradingFluyt))
         {
            debugSetup("Route: " + i + " is a Naval Trading Route");
            xsArraySetInt(gTradeRouteIndexAndType, i, cTradeRouteNaval);
            xsArraySetInt(gTradeRouteUpgrades, cTradeRouteFirstUpgrade + (i * 2), cTechDETradeRouteUpgradeWater1);
            xsArraySetInt(gTradeRouteUpgrades, cTradeRouteSecondUpgrade + (i * 2), cTechDETradeRouteUpgradeWater2);
            xsArraySetInt(gTradeRouteCrates, 0 + (i * 4), cUnitTypedeCrateofCoinWater);
            xsArraySetInt(gTradeRouteCrates, 1 + (i * 4), cUnitTypedeCrateofWoodWater);
            xsArraySetInt(gTradeRouteCrates, 2 + (i * 4), cUnitTypedeCrateofFoodWater);
            xsArraySetInt(gTradeRouteCrates, 3 + (i * 4), cUnitTypedeTradeCrateofInfluence);
         }
         else if (kbTechGetStatus(cTechDEEnableTradeRouteNativeAmerican) == cTechStatusActive)
         {
            debugSetup("Route: " + i + " is a South American Trading Route");
            xsArraySetInt(gTradeRouteIndexAndType, i, cTradeRouteSouthAmerica);
            xsArraySetInt(gTradeRouteUpgrades, cTradeRouteFirstUpgrade + (i * 2), cTechdeTradeRouteUpgradeAmerica1);
            xsArraySetInt(gTradeRouteUpgrades, cTradeRouteSecondUpgrade + (i * 2), cTechdeTradeRouteUpgradeAmerica2);
            xsArraySetInt(gTradeRouteCrates, 0 + (i * 4), cUnitTypedeCrateofCoinAmerican);
            xsArraySetInt(gTradeRouteCrates, 1 + (i * 4), cUnitTypedeCrateofWoodAmerican);
            xsArraySetInt(gTradeRouteCrates, 2 + (i * 4), cUnitTypedeCrateofFoodAmerican);
            xsArraySetInt(gTradeRouteCrates, 3 + (i * 4), cUnitTypedeTradeCrateofInfluence);
         }
         else if (kbTechGetStatus(cTechYPEnableAsianNativeOutpost) == cTechStatusActive)
         {
            debugSetup("Route: " + i + " is an Asian Trading Route");
            xsArraySetInt(gTradeRouteIndexAndType, i, cTradeRouteAsia);
            xsArraySetInt(gTradeRouteUpgrades, cTradeRouteFirstUpgrade + (i * 2), cTechypTradeRouteUpgrade1);
            xsArraySetInt(gTradeRouteUpgrades, cTradeRouteSecondUpgrade + (i * 2), cTechypTradeRouteUpgrade2);
            xsArraySetInt(gTradeRouteCrates, 0 + (i * 4), cUnitTypeypCrateofCoin1);
            xsArraySetInt(gTradeRouteCrates, 1 + (i * 4), cUnitTypeypCrateofWood1);
            xsArraySetInt(gTradeRouteCrates, 2 + (i * 4), cUnitTypeypCrateofFood1);
            xsArraySetInt(gTradeRouteCrates, 3 + (i * 4), cUnitTypedeTradeCrateofInfluence);
         }
         else if (kbTechGetStatus(cTechDEEnableTradeRouteAfrican) == cTechStatusActive)
         {
            debugSetup("Route: " + i + " is an African Trading Route");
            xsArraySetInt(gTradeRouteIndexAndType, i, cTradeRouteAfrica);
            xsArraySetInt(gTradeRouteUpgrades, cTradeRouteFirstUpgrade + (i * 2), cTechDETradeRouteUpgradeAfrica1);
            xsArraySetInt(gTradeRouteUpgrades, cTradeRouteSecondUpgrade + (i * 2), cTechDETradeRouteUpgradeAfrica2);
            xsArraySetInt(gTradeRouteCrates, 0 + (i * 4), cUnitTypedeCrateofCoinAfrican);
            xsArraySetInt(gTradeRouteCrates, 1 + (i * 4), cUnitTypedeCrateofWoodAfrican);
            xsArraySetInt(gTradeRouteCrates, 2 + (i * 4), cUnitTypedeCrateofFoodAfrican);
            xsArraySetInt(gTradeRouteCrates, 3 + (i * 4), cUnitTypedeTradeCrateofInfluence);
         }
         else if (kbTechGetStatus(cTechDEEnableTradeRouteUpgradeAll) == cTechStatusActive)
         {
            debugSetup("Route: " + i + " is a special North American Trading Route where upgrading " +
               "one route also upgrades all the others, we can't play smart with this");
            xsArraySetInt(gTradeRouteIndexAndType, i, cTradeRouteAll);
            xsArraySetInt(gTradeRouteUpgrades, cTradeRouteFirstUpgrade + (i * 2), cTechDETradeRouteUpgradeAll1);
            xsArraySetInt(gTradeRouteUpgrades, cTradeRouteSecondUpgrade + (i * 2), cTechDETradeRouteUpgradeAll2);
            xsArraySetInt(gTradeRouteCrates, 0 + (i * 4), cUnitTypedeCrateofCoin);
            xsArraySetInt(gTradeRouteCrates, 1 + (i * 4), cUnitTypedeCrateofWood);
            xsArraySetInt(gTradeRouteCrates, 2 + (i * 4), cUnitTypedeCrateofFood);
            xsArraySetInt(gTradeRouteCrates, 3 + (i * 4), cUnitTypedeTradeCrateofInfluence);
         }
         else // It all defaults to North America.
         {
            debugSetup("Route: " + i + " is a North American Trading Route");
            xsArraySetInt(gTradeRouteIndexAndType, i, cTradeRouteNorthAmerica);
            xsArraySetInt(gTradeRouteUpgrades, cTradeRouteFirstUpgrade + (i * 2), cTechTradeRouteUpgrade1);
            xsArraySetInt(gTradeRouteUpgrades, cTradeRouteSecondUpgrade + (i * 2), cTechTradeRouteUpgrade2);
            xsArraySetInt(gTradeRouteCrates, 0 + (i * 4), cUnitTypeTradeCrateofCoin);
            xsArraySetInt(gTradeRouteCrates, 1 + (i * 4), cUnitTypeTradeCrateofWood);
            xsArraySetInt(gTradeRouteCrates, 2 + (i * 4), cUnitTypeTradeCrateofFood);
            xsArraySetInt(gTradeRouteCrates, 3 + (i * 4), cUnitTypedeTradeCrateofInfluence);
         }
      }
   }
   else
   {
      debugSetup("We found no Trading Routes on this map");
   }

   gFirstAgeTime = xsArrayCreateInt(5, 60 * 60 * 1000, "Time age was reached");
   xsArraySetInt(gFirstAgeTime, cAge2, -10 * 60 * 1000); // So we always bump the priority for getting Commerce.

   gAge2PoliticianList = xsArrayCreateInt(14, 0, "Age 2 Politician List");
   xsArraySetInt(gAge2PoliticianList, 0, cTechPoliticianGovernor);
   xsArraySetInt(gAge2PoliticianList, 1, cTechPoliticianQuartermaster);
   xsArraySetInt(gAge2PoliticianList, 2, cTechPoliticianNaturalist);
   xsArraySetInt(gAge2PoliticianList, 3, cTechPoliticianBishop);
   xsArraySetInt(gAge2PoliticianList, 4, cTechPoliticianPhilosopherPrince);
   // xsArraySetInt(gAge2PoliticianList, 5, cTechPoliticianBishopGerman);
   xsArraySetInt(gAge2PoliticianList, 5, cTechDEPoliticianLogisticianColonialBritish);
   xsArraySetInt(gAge2PoliticianList, 6, cTechDEPoliticianKnightColonial);
   xsArraySetInt(gAge2PoliticianList, 7, cTechDEPoliticianLogisticianColonialDutch);
   xsArraySetInt(gAge2PoliticianList, 8, cTechDEPoliticianLogisticianFrench);
   xsArraySetInt(gAge2PoliticianList, 9, cTechDEPoliticianLogisticianGerman);
   xsArraySetInt(gAge2PoliticianList, 10, cTechDEPoliticianLogisticianPortuguese);
   xsArraySetInt(gAge2PoliticianList, 11, cTechDEPoliticianLogisticianColonialRussian);
   xsArraySetInt(gAge2PoliticianList, 12, cTechDEPoliticianLogisticianSpanish);
   xsArraySetInt(gAge2PoliticianList, 13, cTechDEPoliticianLogisticianSwedish);

   gAge3PoliticianList = xsArrayCreateInt(24, 0, "Age 3 Politician List");
   xsArraySetInt(gAge3PoliticianList, 0, cTechPoliticianSergeantSpanish);
   xsArraySetInt(gAge3PoliticianList, 1, cTechPoliticianMohawk);
   xsArraySetInt(gAge3PoliticianList, 2, cTechPoliticianPirate);
   xsArraySetInt(gAge3PoliticianList, 3, cTechPoliticianAdventurerSpanish);
   xsArraySetInt(gAge3PoliticianList, 4, cTechPoliticianAdmiral);
   xsArraySetInt(gAge3PoliticianList, 5, cTechPoliticianExiledPrince);
   xsArraySetInt(gAge3PoliticianList, 6, cTechPoliticianMarksman);
   xsArraySetInt(gAge3PoliticianList, 7, cTechPoliticianAdmiralOttoman);
   xsArraySetInt(gAge3PoliticianList, 8, cTechPoliticianAdventurerBritish);
   xsArraySetInt(gAge3PoliticianList, 9, cTechPoliticianScout);
   xsArraySetInt(gAge3PoliticianList, 10, cTechPoliticianScoutRussian);
   xsArraySetInt(gAge3PoliticianList, 11, cTechPoliticianAdventurerRussian);
   xsArraySetInt(gAge3PoliticianList, 12, cTechPoliticianSergeantGerman);
   xsArraySetInt(gAge3PoliticianList, 13, cTechPoliticianMarksmanPortuguese);
   xsArraySetInt(gAge3PoliticianList, 14, cTechPoliticianMarksmanOttoman);
   xsArraySetInt(gAge3PoliticianList, 15, cTechPoliticianSergeantDutch);
   xsArraySetInt(gAge3PoliticianList, 16, cTechPoliticianBishopFortress);
   xsArraySetInt(gAge3PoliticianList, 17, cTechDEPoliticianInventorFortress);
   xsArraySetInt(gAge3PoliticianList, 18, cTechDEPoliticianPapalGuardBritish);
   xsArraySetInt(gAge3PoliticianList, 19, cTechDEPoliticianMercContractorFortressDutch);
   xsArraySetInt(gAge3PoliticianList, 20, cTechDEPoliticianMercContractorFortressOttoman);
   xsArraySetInt(gAge3PoliticianList, 21, cTechDEPoliticianMercContractorFortressPortuguese);
   xsArraySetInt(gAge3PoliticianList, 22, cTechDEPoliticianMarksmanSwedish);
   xsArraySetInt(gAge3PoliticianList, 23, cTechDEPoliticianInventorFortress);

   gAge4PoliticianList = xsArrayCreateInt(33, 0, "Age 4 Politician List");
   xsArraySetInt(gAge4PoliticianList, 0, cTechPoliticianEngineer);
   xsArraySetInt(gAge4PoliticianList, 1, cTechPoliticianTycoon);
   xsArraySetInt(gAge4PoliticianList, 2, cTechPoliticianMusketeerSpanish);
   xsArraySetInt(gAge4PoliticianList, 3, cTechPoliticianCavalierSpanish);
   xsArraySetInt(gAge4PoliticianList, 4, cTechPoliticianGrandVizier);
   xsArraySetInt(gAge4PoliticianList, 5, cTechPoliticianWarMinisterSpanish);
   xsArraySetInt(gAge4PoliticianList, 6, cTechPoliticianViceroyBritish);
   xsArraySetInt(gAge4PoliticianList, 7, cTechPoliticianMusketeerBritish);
   xsArraySetInt(gAge4PoliticianList, 8, cTechPoliticianCavalierFrench);
   xsArraySetInt(gAge4PoliticianList, 9, cTechPoliticianMusketeerFrench);
   xsArraySetInt(gAge4PoliticianList, 10, cTechPoliticianWarMinisterRussian);
   xsArraySetInt(gAge4PoliticianList, 11, cTechPoliticianCavalierRussian);
   xsArraySetInt(gAge4PoliticianList, 12, cTechPoliticianMusketeerRussian);
   xsArraySetInt(gAge4PoliticianList, 13, cTechPoliticianCavalierGerman);
   xsArraySetInt(gAge4PoliticianList, 14, cTechPoliticianViceroyGerman);
   xsArraySetInt(gAge4PoliticianList, 15, cTechPoliticianEngineerPortuguese);
   xsArraySetInt(gAge4PoliticianList, 16, cTechPoliticianViceroyPortuguese);
   xsArraySetInt(gAge4PoliticianList, 17, cTechPoliticianMusketeerPortuguese);
   xsArraySetInt(gAge4PoliticianList, 18, cTechPoliticianCavalierDutch);
   xsArraySetInt(gAge4PoliticianList, 19, cTechPoliticianCavalierOttoman);
   xsArraySetInt(gAge4PoliticianList, 20, cTechPoliticianMusketeerDutch);
   xsArraySetInt(gAge4PoliticianList, 21, cTechPoliticianViceroyDutch);
   xsArraySetInt(gAge4PoliticianList, 22, cTechPoliticianTycoonAct3);
   xsArraySetInt(gAge4PoliticianList, 23, cTechPoliticianWarMinisterAct3);
   xsArraySetInt(gAge4PoliticianList, 24, cTechDEPoliticianLogistician);
   xsArraySetInt(gAge4PoliticianList, 25, cTechDEPoliticianPapalGuard);
   xsArraySetInt(gAge4PoliticianList, 26, cTechDEPoliticianLogisticianOttoman);
   xsArraySetInt(gAge4PoliticianList, 27, cTechDEPoliticianPapalGuardPortuguese);
   xsArraySetInt(gAge4PoliticianList, 28, cTechDEPoliticianLogisticianRussian);
   xsArraySetInt(gAge4PoliticianList, 29, cTechDEPoliticianPapalGuardSpanish);
   xsArraySetInt(gAge4PoliticianList, 30, cTechDEPoliticianMusketeerSwedish);
   xsArraySetInt(gAge4PoliticianList, 31, cTechDEPoliticianCavalierSwedish);
   xsArraySetInt(gAge4PoliticianList, 32, cTechDEPoliticianPapalGuardSwedish);

   gAge5PoliticianList = xsArrayCreateInt(13, 0, "Age 5 Politician List");
   xsArraySetInt(gAge5PoliticianList, 0, cTechPoliticianPresidente);
   xsArraySetInt(gAge5PoliticianList, 1, cTechPoliticianGeneral);
   xsArraySetInt(gAge5PoliticianList, 2, cTechPoliticianGeneralBritish);
   xsArraySetInt(gAge5PoliticianList, 3, cTechPoliticianGeneralOttoman);
   xsArraySetInt(gAge5PoliticianList, 4, cTechPoliticianGeneralSkirmisher);
   xsArraySetInt(gAge5PoliticianList, 5, cTechDEPoliticianMercContractor);
   xsArraySetInt(gAge5PoliticianList, 6, cTechDEPoliticianInventor);
   xsArraySetInt(gAge5PoliticianList, 7, cTechDEPoliticianKnight);
   xsArraySetInt(gAge5PoliticianList, 8, cTechDEPoliticianFederalFlorida);
   xsArraySetInt(gAge5PoliticianList, 9, cTechDEPoliticianFederalConnecticut);
   xsArraySetInt(gAge5PoliticianList, 10, cTechDEPoliticianFederalIllinois);
   xsArraySetInt(gAge5PoliticianList, 11, cTechDEPoliticianFederalNewYork);
   xsArraySetInt(gAge5PoliticianList, 12, cTechDEPoliticianFederalTexas);
   
   gRevolutionList = xsArrayCreateInt(20, 0, "Revolution List");
   xsArraySetInt(gRevolutionList, 0, cTechDERevolutionHaiti);
   xsArraySetInt(gRevolutionList, 1, cTechDERevolutionEgypt);
   xsArraySetInt(gRevolutionList, 2, cTechDERevolutionFinland);
   xsArraySetInt(gRevolutionList, 3, cTechDERevolutionRomania);
   xsArraySetInt(gRevolutionList, 4, cTechDERevolutionPeru);
   xsArraySetInt(gRevolutionList, 5, cTechDERevolutionBrazil);
   xsArraySetInt(gRevolutionList, 6, cTechDERevolutionArgentina);
   xsArraySetInt(gRevolutionList, 7, cTechDERevolutionUSA);
   xsArraySetInt(gRevolutionList, 8, cTechDERevolutionCanadaFrench);
   xsArraySetInt(gRevolutionList, 9, cTechDERevolutionCanadaBritish);
   xsArraySetInt(gRevolutionList, 10, cTechDERevolutionIndonesia);
   xsArraySetInt(gRevolutionList, 11, cTechDERevolutionBarbaryStates);
   xsArraySetInt(gRevolutionList, 12, cTechDERevolutionHungaryRussian);
   xsArraySetInt(gRevolutionList, 13, cTechDERevolutionHungaryOttoman);
   xsArraySetInt(gRevolutionList, 14, cTechDERevolutionHungaryGerman);
   xsArraySetInt(gRevolutionList, 15, cTechDERevolutionMexico);
   xsArraySetInt(gRevolutionList, 16, cTechDERevolutionColombia);
   xsArraySetInt(gRevolutionList, 17, cTechDERevolutionColombiaPortuguese);
   xsArraySetInt(gRevolutionList, 18, cTechDERevolutionChile);
   xsArraySetInt(gRevolutionList, 19, cTechDERevolutionSouthAfrica);

   gAgeUpPoliticians = xsArrayCreateInt(10, 0, "Ageup Politicians");
   gPoliticianScores = xsArrayCreateInt(10, 0, "European Politicians");
   gNatCouncilScores = xsArrayCreateInt(6, 0, "Native Council");
   gAfricanAlliances = xsArrayCreateInt(8, 0, "African Alliances");
   gAfricanAlliancesAgedUpWith = xsArrayCreateBool(5, false, "African Alliances Aged Up With");
   // Default to true and set to false when we actually age-up with the Alliance.
   gAfricanAlliancesUpgrades = xsArrayCreateBool(5, true, "African Alliances Upgrades");
   gMexicanFederalStates = xsArrayCreateInt(5, 0, "Mexican Federal States");
   gAmericanFederalStates = xsArrayCreateInt(5, 0, "United States Federal States");
   
   gAsianWonders = xsArrayCreateInt(5, 0, "Wonder Age IDs");
   int wonderchoice = aiRandInt(4);
   if ((cMyCiv == cCivJapanese) || (cMyCiv == cCivSPCJapanese) || (cMyCiv == cCivSPCJapaneseEnemy))
   {
	xsArraySetInt(gAsianWonders, 0, cUnitTypeypWJToshoguShrine2);
	xsArraySetInt(gAsianWonders, 1, cUnitTypeypWJToriiGates3);
	xsArraySetInt(gAsianWonders, 2, cUnitTypeypWJGoldenPavillion4);
    xsArraySetInt(gAsianWonders, 3, cUnitTypeypWJShogunate5);
   }
   if ((cMyCiv == cCivChinese) || (cMyCiv == cCivSPCChinese))
   {
      // Confucian Academy, Porcelain Tower, Summer Palace, Temple of Heaven, White Pagoda
      if (btRushBoom > 0)
      {
         if (wonderchoice == 0)
         {
            xsArraySetInt(gAsianWonders, 0, cUnitTypeypWCSummerPalace2);
            xsArraySetInt(gAsianWonders, 1, cUnitTypeypWCPorcelainTower3);
            xsArraySetInt(gAsianWonders, 2, cUnitTypeypWCConfucianAcademy4);
            xsArraySetInt(gAsianWonders, 3, cUnitTypeypWCTempleOfHeaven5);
         }
         else if (wonderchoice == 1)
         {
            xsArraySetInt(gAsianWonders, 0, cUnitTypeypWCSummerPalace2);
            xsArraySetInt(gAsianWonders, 1, cUnitTypeypWCConfucianAcademy3);
            xsArraySetInt(gAsianWonders, 2, cUnitTypeypWCPorcelainTower4);
            xsArraySetInt(gAsianWonders, 3, cUnitTypeypWCTempleOfHeaven5);
         }
         else if (wonderchoice == 2)
         {
            xsArraySetInt(gAsianWonders, 0, cUnitTypeypWCConfucianAcademy2);
            xsArraySetInt(gAsianWonders, 1, cUnitTypeypWCSummerPalace3);
            xsArraySetInt(gAsianWonders, 2, cUnitTypeypWCPorcelainTower4);
            xsArraySetInt(gAsianWonders, 3, cUnitTypeypWCWhitePagoda5);
         }
         else
         {
            xsArraySetInt(gAsianWonders, 0, cUnitTypeypWCSummerPalace2);
            xsArraySetInt(gAsianWonders, 1, cUnitTypeypWCConfucianAcademy3);
            xsArraySetInt(gAsianWonders, 2, cUnitTypeypWCWhitePagoda4);
            xsArraySetInt(gAsianWonders, 3, cUnitTypeypWCPorcelainTower5);
         }
      }
      else
      {
         if (wonderchoice == 0)
         {
            xsArraySetInt(gAsianWonders, 0, cUnitTypeypWCSummerPalace2);
            xsArraySetInt(gAsianWonders, 1, cUnitTypeypWCConfucianAcademy3);
            xsArraySetInt(gAsianWonders, 2, cUnitTypeypWCPorcelainTower4);
            xsArraySetInt(gAsianWonders, 3, cUnitTypeypWCTempleOfHeaven5);
         }
         else if (wonderchoice == 1)
         {
            xsArraySetInt(gAsianWonders, 0, cUnitTypeypWCSummerPalace2);
            xsArraySetInt(gAsianWonders, 1, cUnitTypeypWCConfucianAcademy3);
            xsArraySetInt(gAsianWonders, 2, cUnitTypeypWCPorcelainTower4);
            xsArraySetInt(gAsianWonders, 3, cUnitTypeypWCWhitePagoda5);
         }
         else if (wonderchoice == 2)
         {
            xsArraySetInt(gAsianWonders, 0, cUnitTypeypWCSummerPalace2);
            xsArraySetInt(gAsianWonders, 1, cUnitTypeypWCConfucianAcademy3);
            xsArraySetInt(gAsianWonders, 2, cUnitTypeypWCTempleOfHeaven4);
            xsArraySetInt(gAsianWonders, 3, cUnitTypeypWCPorcelainTower5);
         }
         else
         {
            xsArraySetInt(gAsianWonders, 0, cUnitTypeypWCSummerPalace2);
            xsArraySetInt(gAsianWonders, 1, cUnitTypeypWCPorcelainTower3);
            xsArraySetInt(gAsianWonders, 2, cUnitTypeypWCConfucianAcademy4);
            xsArraySetInt(gAsianWonders, 3, cUnitTypeypWCWhitePagoda5);
         }
      }
   }
   if ((cMyCiv == cCivIndians) || (cMyCiv == cCivSPCIndians))
   {
      // Agra Fort, Charminar Gate, Karni Mata, Taj Mahal, Tower of Victory
      if (btRushBoom > 0)
      {
         if (wonderchoice == 0)
         {
            xsArraySetInt(gAsianWonders, 0, cUnitTypeypWIAgraFort2);
            xsArraySetInt(gAsianWonders, 1, cUnitTypeypWICharminarGate3);
            xsArraySetInt(gAsianWonders, 2, cUnitTypeypWIKarniMata4);
            xsArraySetInt(gAsianWonders, 3, cUnitTypeypWITajMahal5);
         }
         else if (wonderchoice == 1)
         {
            xsArraySetInt(gAsianWonders, 0, cUnitTypeypWIAgraFort2);
            xsArraySetInt(gAsianWonders, 1, cUnitTypeypWIKarniMata3);
            xsArraySetInt(gAsianWonders, 2, cUnitTypeypWICharminarGate4);
            xsArraySetInt(gAsianWonders, 3, cUnitTypeypWITajMahal5);
         }
         else if (wonderchoice == 2)
         {
            xsArraySetInt(gAsianWonders, 0, cUnitTypeypWIAgraFort2);
            xsArraySetInt(gAsianWonders, 1, cUnitTypeypWIKarniMata3);
            xsArraySetInt(gAsianWonders, 2, cUnitTypeypWICharminarGate4);
            xsArraySetInt(gAsianWonders, 3, cUnitTypeypWITajMahal5);
         }
         else
         {
            xsArraySetInt(gAsianWonders, 0, cUnitTypeypWIKarniMata2);
            xsArraySetInt(gAsianWonders, 1, cUnitTypeypWICharminarGate3);
            xsArraySetInt(gAsianWonders, 2, cUnitTypeypWITowerOfVictory4);
            xsArraySetInt(gAsianWonders, 3, cUnitTypeypWITajMahal5);
         }
      }
      else
      {
         if (wonderchoice == 0)
         {
            xsArraySetInt(gAsianWonders, 0, cUnitTypeypWIAgraFort2);
            xsArraySetInt(gAsianWonders, 1, cUnitTypeypWIKarniMata3);
            xsArraySetInt(gAsianWonders, 2, cUnitTypeypWICharminarGate4);
            xsArraySetInt(gAsianWonders, 3, cUnitTypeypWITowerOfVictory5);
         }
         else if (wonderchoice == 1)
         {
            xsArraySetInt(gAsianWonders, 0, cUnitTypeypWIAgraFort2);
            xsArraySetInt(gAsianWonders, 1, cUnitTypeypWIKarniMata3);
            xsArraySetInt(gAsianWonders, 2, cUnitTypeypWITajMahal4);
            xsArraySetInt(gAsianWonders, 3, cUnitTypeypWITowerOfVictory5);
         }
         else if (wonderchoice == 2)
         {
            xsArraySetInt(gAsianWonders, 0, cUnitTypeypWIAgraFort2);
            xsArraySetInt(gAsianWonders, 1, cUnitTypeypWIKarniMata3);
            xsArraySetInt(gAsianWonders, 2, cUnitTypeypWICharminarGate4);
            xsArraySetInt(gAsianWonders, 3, cUnitTypeypWITajMahal5);
         }
         else
         {
            xsArraySetInt(gAsianWonders, 0, cUnitTypeypWIKarniMata2);
            xsArraySetInt(gAsianWonders, 1, cUnitTypeypWICharminarGate3);
            xsArraySetInt(gAsianWonders, 2, cUnitTypeypWITajMahal4);
            xsArraySetInt(gAsianWonders, 3, cUnitTypeypWITowerOfVictory5);
         }
      }
   }
   gAge2WonderList = xsArrayCreateInt(15, 0, "Age 2 Wonder List");
   xsArraySetInt(gAge2WonderList, 0, cUnitTypeypWCConfucianAcademy2);
   xsArraySetInt(gAge2WonderList, 1, cUnitTypeypWCPorcelainTower2);
   xsArraySetInt(gAge2WonderList, 2, cUnitTypeypWCSummerPalace2);
   xsArraySetInt(gAge2WonderList, 3, cUnitTypeypWCTempleOfHeaven2);
   xsArraySetInt(gAge2WonderList, 4, cUnitTypeypWCWhitePagoda2);
   xsArraySetInt(gAge2WonderList, 5, cUnitTypeypWIAgraFort2);
   xsArraySetInt(gAge2WonderList, 6, cUnitTypeypWICharminarGate2);
   xsArraySetInt(gAge2WonderList, 7, cUnitTypeypWIKarniMata2);
   xsArraySetInt(gAge2WonderList, 8, cUnitTypeypWITajMahal2);
   xsArraySetInt(gAge2WonderList, 9, cUnitTypeypWITowerOfVictory2);
   xsArraySetInt(gAge2WonderList, 10, cUnitTypeypWJGiantBuddha2);
   xsArraySetInt(gAge2WonderList, 11, cUnitTypeypWJGoldenPavillion2);
   xsArraySetInt(gAge2WonderList, 12, cUnitTypeypWJShogunate2);
   xsArraySetInt(gAge2WonderList, 13, cUnitTypeypWJToriiGates2);
   xsArraySetInt(gAge2WonderList, 14, cUnitTypeypWJToshoguShrine2);
   gAge3WonderList = xsArrayCreateInt(15, 0, "Age 3 Wonder List");
   xsArraySetInt(gAge3WonderList, 0, cUnitTypeypWCConfucianAcademy3);
   xsArraySetInt(gAge3WonderList, 1, cUnitTypeypWCPorcelainTower3);
   xsArraySetInt(gAge3WonderList, 2, cUnitTypeypWCSummerPalace3);
   xsArraySetInt(gAge3WonderList, 3, cUnitTypeypWCTempleOfHeaven3);
   xsArraySetInt(gAge3WonderList, 4, cUnitTypeypWCWhitePagoda3);
   xsArraySetInt(gAge3WonderList, 5, cUnitTypeypWIAgraFort3);
   xsArraySetInt(gAge3WonderList, 6, cUnitTypeypWICharminarGate3);
   xsArraySetInt(gAge3WonderList, 7, cUnitTypeypWIKarniMata3);
   xsArraySetInt(gAge3WonderList, 8, cUnitTypeypWITajMahal3);
   xsArraySetInt(gAge3WonderList, 9, cUnitTypeypWITowerOfVictory3);
   xsArraySetInt(gAge3WonderList, 10, cUnitTypeypWJGiantBuddha3);
   xsArraySetInt(gAge3WonderList, 11, cUnitTypeypWJGoldenPavillion3);
   xsArraySetInt(gAge3WonderList, 12, cUnitTypeypWJShogunate3);
   xsArraySetInt(gAge3WonderList, 13, cUnitTypeypWJToriiGates3);
   xsArraySetInt(gAge3WonderList, 14, cUnitTypeypWJToshoguShrine3);
   gAge4WonderList = xsArrayCreateInt(15, 0, "Age 4 Wonder List");
   xsArraySetInt(gAge4WonderList, 0, cUnitTypeypWCConfucianAcademy4);
   xsArraySetInt(gAge4WonderList, 1, cUnitTypeypWCPorcelainTower4);
   xsArraySetInt(gAge4WonderList, 2, cUnitTypeypWCSummerPalace4);
   xsArraySetInt(gAge4WonderList, 3, cUnitTypeypWCTempleOfHeaven4);
   xsArraySetInt(gAge4WonderList, 4, cUnitTypeypWCWhitePagoda4);
   xsArraySetInt(gAge4WonderList, 5, cUnitTypeypWIAgraFort4);
   xsArraySetInt(gAge4WonderList, 6, cUnitTypeypWICharminarGate4);
   xsArraySetInt(gAge4WonderList, 7, cUnitTypeypWIKarniMata4);
   xsArraySetInt(gAge4WonderList, 8, cUnitTypeypWITajMahal4);
   xsArraySetInt(gAge4WonderList, 9, cUnitTypeypWITowerOfVictory4);
   xsArraySetInt(gAge4WonderList, 10, cUnitTypeypWJGiantBuddha4);
   xsArraySetInt(gAge4WonderList, 11, cUnitTypeypWJGoldenPavillion4);
   xsArraySetInt(gAge4WonderList, 12, cUnitTypeypWJShogunate4);
   xsArraySetInt(gAge4WonderList, 13, cUnitTypeypWJToriiGates4);
   xsArraySetInt(gAge4WonderList, 14, cUnitTypeypWJToshoguShrine4);
   gAge5WonderList = xsArrayCreateInt(15, 0, "Age 5 Wonder List");
   xsArraySetInt(gAge5WonderList, 0, cUnitTypeypWCConfucianAcademy5);
   xsArraySetInt(gAge5WonderList, 1, cUnitTypeypWCPorcelainTower5);
   xsArraySetInt(gAge5WonderList, 2, cUnitTypeypWCSummerPalace5);
   xsArraySetInt(gAge5WonderList, 3, cUnitTypeypWCTempleOfHeaven5);
   xsArraySetInt(gAge5WonderList, 4, cUnitTypeypWCWhitePagoda5);
   xsArraySetInt(gAge5WonderList, 5, cUnitTypeypWIAgraFort5);
   xsArraySetInt(gAge5WonderList, 6, cUnitTypeypWICharminarGate5);
   xsArraySetInt(gAge5WonderList, 7, cUnitTypeypWIKarniMata5);
   xsArraySetInt(gAge5WonderList, 8, cUnitTypeypWITajMahal5);
   xsArraySetInt(gAge5WonderList, 9, cUnitTypeypWITowerOfVictory5);
   xsArraySetInt(gAge5WonderList, 10, cUnitTypeypWJGiantBuddha5);
   xsArraySetInt(gAge5WonderList, 11, cUnitTypeypWJGoldenPavillion5);
   xsArraySetInt(gAge5WonderList, 12, cUnitTypeypWJShogunate5);
   xsArraySetInt(gAge5WonderList, 13, cUnitTypeypWJToriiGates5);
   xsArraySetInt(gAge5WonderList, 14, cUnitTypeypWJToshoguShrine5);
   gAge2WonderTechList = xsArrayCreateInt(15, 0, "Age 2 WonderTech List");
   xsArraySetInt(gAge2WonderTechList, 0, cTechYPWonderChineseConfucianAcademy2);
   xsArraySetInt(gAge2WonderTechList, 1, cTechYPWonderChinesePorcelainTower2);
   xsArraySetInt(gAge2WonderTechList, 2, cTechYPWonderChineseSummerPalace2);
   xsArraySetInt(gAge2WonderTechList, 3, cTechYPWonderChineseTempleOfHeaven2);
   xsArraySetInt(gAge2WonderTechList, 4, cTechYPWonderChineseWhitePagoda2);
   xsArraySetInt(gAge2WonderTechList, 5, cTechYPWonderIndianAgra2);
   xsArraySetInt(gAge2WonderTechList, 6, cTechYPWonderIndianCharminar2);
   xsArraySetInt(gAge2WonderTechList, 7, cTechYPWonderIndianKarniMata2);
   xsArraySetInt(gAge2WonderTechList, 8, cTechYPWonderIndianTajMahal2);
   xsArraySetInt(gAge2WonderTechList, 9, cTechYPWonderIndianTowerOfVictory2);
   xsArraySetInt(gAge2WonderTechList, 10, cTechYPWonderJapaneseGiantBuddha2);
   xsArraySetInt(gAge2WonderTechList, 11, cTechYPWonderJapaneseGoldenPavillion2);
   xsArraySetInt(gAge2WonderTechList, 12, cTechYPWonderJapaneseShogunate2);
   xsArraySetInt(gAge2WonderTechList, 13, cTechYPWonderJapaneseToriiGates2);
   xsArraySetInt(gAge2WonderTechList, 14, cTechYPWonderJapaneseToshoguShrine2);
   gAge3WonderTechList = xsArrayCreateInt(15, 0, "Age 3 WonderTech List");
   xsArraySetInt(gAge3WonderTechList, 0, cTechYPWonderChineseConfucianAcademy3);
   xsArraySetInt(gAge3WonderTechList, 1, cTechYPWonderChinesePorcelainTower3);
   xsArraySetInt(gAge3WonderTechList, 2, cTechYPWonderChineseSummerPalace3);
   xsArraySetInt(gAge3WonderTechList, 3, cTechYPWonderChineseTempleOfHeaven3);
   xsArraySetInt(gAge3WonderTechList, 4, cTechYPWonderChineseWhitePagoda3);
   xsArraySetInt(gAge3WonderTechList, 5, cTechYPWonderIndianAgra3);
   xsArraySetInt(gAge3WonderTechList, 6, cTechYPWonderIndianCharminar3);
   xsArraySetInt(gAge3WonderTechList, 7, cTechYPWonderIndianKarniMata3);
   xsArraySetInt(gAge3WonderTechList, 8, cTechYPWonderIndianTajMahal3);
   xsArraySetInt(gAge3WonderTechList, 9, cTechYPWonderIndianTowerOfVictory3);
   xsArraySetInt(gAge3WonderTechList, 10, cTechYPWonderJapaneseGiantBuddha3);
   xsArraySetInt(gAge3WonderTechList, 11, cTechYPWonderJapaneseGoldenPavillion3);
   xsArraySetInt(gAge3WonderTechList, 12, cTechYPWonderJapaneseShogunate3);
   xsArraySetInt(gAge3WonderTechList, 13, cTechYPWonderJapaneseToriiGates3);
   xsArraySetInt(gAge3WonderTechList, 14, cTechYPWonderJapaneseToshoguShrine3);
   gAge4WonderTechList = xsArrayCreateInt(15, 0, "Age 4 WonderTech List");
   xsArraySetInt(gAge4WonderTechList, 0, cTechYPWonderChineseConfucianAcademy4);
   xsArraySetInt(gAge4WonderTechList, 1, cTechYPWonderChinesePorcelainTower4);
   xsArraySetInt(gAge4WonderTechList, 2, cTechYPWonderChineseSummerPalace4);
   xsArraySetInt(gAge4WonderTechList, 3, cTechYPWonderChineseTempleOfHeaven4);
   xsArraySetInt(gAge4WonderTechList, 4, cTechYPWonderChineseWhitePagoda4);
   xsArraySetInt(gAge4WonderTechList, 5, cTechYPWonderIndianAgra4);
   xsArraySetInt(gAge4WonderTechList, 6, cTechYPWonderIndianCharminar4);
   xsArraySetInt(gAge4WonderTechList, 7, cTechYPWonderIndianKarniMata4);
   xsArraySetInt(gAge4WonderTechList, 8, cTechYPWonderIndianTajMahal4);
   xsArraySetInt(gAge4WonderTechList, 9, cTechYPWonderIndianTowerOfVictory4);
   xsArraySetInt(gAge4WonderTechList, 10, cTechYPWonderJapaneseGiantBuddha4);
   xsArraySetInt(gAge4WonderTechList, 11, cTechYPWonderJapaneseGoldenPavillion4);
   xsArraySetInt(gAge4WonderTechList, 12, cTechYPWonderJapaneseShogunate4);
   xsArraySetInt(gAge4WonderTechList, 13, cTechYPWonderJapaneseToriiGates4);
   xsArraySetInt(gAge4WonderTechList, 14, cTechYPWonderJapaneseToshoguShrine4);
   gAge5WonderTechList = xsArrayCreateInt(15, 0, "Age 5 WonderTech List");
   xsArraySetInt(gAge5WonderTechList, 0, cTechYPWonderChineseConfucianAcademy5);
   xsArraySetInt(gAge5WonderTechList, 1, cTechYPWonderChinesePorcelainTower5);
   xsArraySetInt(gAge5WonderTechList, 2, cTechYPWonderChineseSummerPalace5);
   xsArraySetInt(gAge5WonderTechList, 3, cTechYPWonderChineseTempleOfHeaven5);
   xsArraySetInt(gAge5WonderTechList, 4, cTechYPWonderChineseWhitePagoda5);
   xsArraySetInt(gAge5WonderTechList, 5, cTechYPWonderIndianAgra5);
   xsArraySetInt(gAge5WonderTechList, 6, cTechYPWonderIndianCharminar5);
   xsArraySetInt(gAge5WonderTechList, 7, cTechYPWonderIndianKarniMata5);
   xsArraySetInt(gAge5WonderTechList, 8, cTechYPWonderIndianTajMahal5);
   xsArraySetInt(gAge5WonderTechList, 9, cTechYPWonderIndianTowerOfVictory5);
   xsArraySetInt(gAge5WonderTechList, 10, cTechYPWonderJapaneseGiantBuddha5);
   xsArraySetInt(gAge5WonderTechList, 11, cTechYPWonderJapaneseGoldenPavillion5);
   xsArraySetInt(gAge5WonderTechList, 12, cTechYPWonderJapaneseShogunate5);
   xsArraySetInt(gAge5WonderTechList, 13, cTechYPWonderJapaneseToriiGates5);
   xsArraySetInt(gAge5WonderTechList, 14, cTechYPWonderJapaneseToshoguShrine5);

   //==============================================================================
   // Economy.
   //==============================================================================

   gResourceNeeds = xsArrayCreateFloat(3, 0.0, "Resource Needs");
   gExtraResourceNeeds = xsArrayCreateFloat(3, 0.0, "Extra Resource Needs");
   gAdjustBreakdownAttempts = xsArrayCreateInt(3, 1, "Resource Breakdown Adjust Attempts");

   //==============================================================================
   // Military.
   //==============================================================================

   gArrayEnemyPlayerIDs = xsArrayCreateInt(cNumberPlayers - 2, -1, "Enemy Player IDs");
   gStartingPosDistances = xsArrayCreateFloat(cNumberPlayers, 0.0, "Player Starting Position Distances");
   vector startLoc = kbGetPlayerStartingPosition(cMyID);

   for (i = 1; < cNumberPlayers)
   {
      xsArraySetFloat(gStartingPosDistances, i, xsVectorLength(startLoc - kbGetPlayerStartingPosition(i)));
   }

   gArmyUnitMaintainPlans = xsArrayCreateInt(gNumArmyUnitTypes, -1, "Army Unit Maintain Plans");

   //==============================================================================
   // Chats.
   //==============================================================================

   gMapNames = xsArrayCreateString(177, "", "Map names");
   xsArraySetString(gMapNames, 0, "afatlas");
   xsArraySetString(gMapNames, 1, "afatlaslarge");
   xsArraySetString(gMapNames, 2, "afdarfur");
   xsArraySetString(gMapNames, 3, "afdarfurlarge");
   xsArraySetString(gMapNames, 4, "afdunes");
   xsArraySetString(gMapNames, 5, "afduneslarge");
   xsArraySetString(gMapNames, 6, "afgold coast");
   xsArraySetString(gMapNames, 7, "afgold coastlarge");
   xsArraySetString(gMapNames, 8, "afgreat rift");
   xsArraySetString(gMapNames, 9, "afgreat riftlarge");
   xsArraySetString(gMapNames, 10, "afhighlands");
   xsArraySetString(gMapNames, 11, "afhighlandslarge");
   xsArraySetString(gMapNames, 12, "afhorn");
   xsArraySetString(gMapNames, 13, "afhornlarge");
   xsArraySetString(gMapNames, 14, "afivorycoast");
   xsArraySetString(gMapNames, 15, "afivorycoastlarge");
   xsArraySetString(gMapNames, 16, "aflakechad");
   xsArraySetString(gMapNames, 17, "aflakechadlarge");
   xsArraySetString(gMapNames, 18, "afnigerdelta");
   xsArraySetString(gMapNames, 19, "afnigerdeltalarge");
   xsArraySetString(gMapNames, 20, "afniger river");
   xsArraySetString(gMapNames, 21, "afniger riverlarge");
   xsArraySetString(gMapNames, 22, "afnile valley");
   xsArraySetString(gMapNames, 23, "afnile valleylarge");
   xsArraySetString(gMapNames, 24, "afpeppercoast");
   xsArraySetString(gMapNames, 25, "afpeppercoastlarge");
   xsArraySetString(gMapNames, 26, "afsahel");
   xsArraySetString(gMapNames, 27, "afsahellarge");
   xsArraySetString(gMapNames, 28, "afsavanna");
   xsArraySetString(gMapNames, 29, "afsavannalarge");
   xsArraySetString(gMapNames, 30, "afsiwaoasis");
   xsArraySetString(gMapNames, 31, "afsiwaoasislarge");
   xsArraySetString(gMapNames, 32, "afsudd");
   xsArraySetString(gMapNames, 33, "afsuddlarge");
   xsArraySetString(gMapNames, 34, "afswahilicoast");
   xsArraySetString(gMapNames, 35, "afswahilicoastlarge");
   xsArraySetString(gMapNames, 36, "aftassili");
   xsArraySetString(gMapNames, 37, "aftassililarge");
   xsArraySetString(gMapNames, 38, "aftripolitania");
   xsArraySetString(gMapNames, 39, "aftripolitanialarge");
   xsArraySetString(gMapNames, 40, "alaska");
   xsArraySetString(gMapNames, 41, "alaskalarge");
   xsArraySetString(gMapNames, 42, "amazonia");
   xsArraySetString(gMapNames, 43, "amazonialarge");
   xsArraySetString(gMapNames, 44, "andes upper");
   xsArraySetString(gMapNames, 45, "andes upperlarge");
   xsArraySetString(gMapNames, 46, "andes");
   xsArraySetString(gMapNames, 47, "andeslarge");
   xsArraySetString(gMapNames, 48, "araucania");
   xsArraySetString(gMapNames, 49, "araucanialarge");
   xsArraySetString(gMapNames, 50, "arctic territories");
   xsArraySetString(gMapNames, 51, "arctic territorieslarge");
   xsArraySetString(gMapNames, 52, "bahia");
   xsArraySetString(gMapNames, 53, "bahialarge");
   xsArraySetString(gMapNames, 54, "baja california");
   xsArraySetString(gMapNames, 55, "baja californialarge");
   xsArraySetString(gMapNames, 56, "bayou");
   xsArraySetString(gMapNames, 57, "bayoularge");
   xsArraySetString(gMapNames, 58, "bengal");
   xsArraySetString(gMapNames, 59, "bengallarge");
   xsArraySetString(gMapNames, 60, "borneo");
   xsArraySetString(gMapNames, 61, "borneolarge");
   xsArraySetString(gMapNames, 62, "california");
   xsArraySetString(gMapNames, 63, "californialarge");
   xsArraySetString(gMapNames, 64, "caribbean");
   xsArraySetString(gMapNames, 65, "caribbeanlarge");
   xsArraySetString(gMapNames, 66, "carolina");
   xsArraySetString(gMapNames, 67, "carolinalarge");
   xsArraySetString(gMapNames, 68, "cascade range");
   xsArraySetString(gMapNames, 69, "cascade rangelarge");
   xsArraySetString(gMapNames, 70, "central plain");
   xsArraySetString(gMapNames, 71, "central plainlarge");
   xsArraySetString(gMapNames, 72, "ceylon");
   xsArraySetString(gMapNames, 73, "ceylonlarge");
   xsArraySetString(gMapNames, 74, "colorado");
   xsArraySetString(gMapNames, 75, "coloradolarge");
   xsArraySetString(gMapNames, 76, "dakota");
   xsArraySetString(gMapNames, 77, "dakotalarge");
   xsArraySetString(gMapNames, 78, "deccan");
   xsArraySetString(gMapNames, 79, "deccanLarge");
   xsArraySetString(gMapNames, 80, "fertile crescent");
   xsArraySetString(gMapNames, 81, "fertile crescentlarge");
   xsArraySetString(gMapNames, 82, "florida");
   xsArraySetString(gMapNames, 83, "floridalarge");
   xsArraySetString(gMapNames, 84, "gran chaco");
   xsArraySetString(gMapNames, 85, "gran chacolarge");
   xsArraySetString(gMapNames, 86, "great lakes");
   xsArraySetString(gMapNames, 87, "greak lakesLarge");
   xsArraySetString(gMapNames, 88, "great plains");
   xsArraySetString(gMapNames, 89, "great plainslarge");
   xsArraySetString(gMapNames, 90, "himalayas");
   xsArraySetString(gMapNames, 91, "himalayaslarge");
   xsArraySetString(gMapNames, 92, "himalayasupper");
   xsArraySetString(gMapNames, 93, "himalayasupperlarge");
   xsArraySetString(gMapNames, 94, "hispaniola");
   xsArraySetString(gMapNames, 95, "hispaniolalarge");
   xsArraySetString(gMapNames, 96, "hokkaido");
   xsArraySetString(gMapNames, 97, "hokkaidolarge");
   xsArraySetString(gMapNames, 98, "honshu");
   xsArraySetString(gMapNames, 99, "honshularge");
   xsArraySetString(gMapNames, 100, "honshuregicide");
   xsArraySetString(gMapNames, 101, "honshuregicidelarge");
   xsArraySetString(gMapNames, 102, "indochina");
   xsArraySetString(gMapNames, 103, "indochinalarge");
   xsArraySetString(gMapNames, 104, "indonesia");
   xsArraySetString(gMapNames, 105, "indonesialarge");
   xsArraySetString(gMapNames, 106, "kamchatka");
   xsArraySetString(gMapNames, 107, "kamchatkalarge");
   xsArraySetString(gMapNames, 108, "korea");
   xsArraySetString(gMapNames, 109, "korealarge");
   xsArraySetString(gMapNames, 110, "malaysia");
   xsArraySetString(gMapNames, 111, "malaysialarge");
   xsArraySetString(gMapNames, 112, "manchuria");
   xsArraySetString(gMapNames, 113, "manchurialarge");
   xsArraySetString(gMapNames, 114, "mexico");
   xsArraySetString(gMapNames, 115, "mexicolarge");
   xsArraySetString(gMapNames, 116, "minasgerais");
   xsArraySetString(gMapNames, 117, "minasgeraislarge");
   xsArraySetString(gMapNames, 118, "mongolia");
   xsArraySetString(gMapNames, 119, "mongolialarge");
   xsArraySetString(gMapNames, 120, "new england");
   xsArraySetString(gMapNames, 121, "new englandlarge");
   xsArraySetString(gMapNames, 122, "northwest territory");
   xsArraySetString(gMapNames, 123, "northwest territorylarge");
   xsArraySetString(gMapNames, 124, "orinoco");
   xsArraySetString(gMapNames, 125, "orinocolarge");
   xsArraySetString(gMapNames, 126, "ozarks");
   xsArraySetString(gMapNames, 127, "ozarkslarge");
   xsArraySetString(gMapNames, 128, "painted desert");
   xsArraySetString(gMapNames, 129, "painted desertlarge");
   xsArraySetString(gMapNames, 130, "pampas sierras");
   xsArraySetString(gMapNames, 131, "pampas sierraslarge");
   xsArraySetString(gMapNames, 132, "pampas");
   xsArraySetString(gMapNames, 133, "pampas large");
   xsArraySetString(gMapNames, 134, "parallel rivers");
   xsArraySetString(gMapNames, 135, "parallel riverslarge");
   xsArraySetString(gMapNames, 136, "patagonia");
   xsArraySetString(gMapNames, 137, "patagonialarge");
   xsArraySetString(gMapNames, 138, "plymouth");
   xsArraySetString(gMapNames, 139, "plymouthlarge");
   xsArraySetString(gMapNames, 140, "punjab");
   xsArraySetString(gMapNames, 141, "punjablarge");
   xsArraySetString(gMapNames, 142, "rockies");
   xsArraySetString(gMapNames, 143, "rockieslarge");
   xsArraySetString(gMapNames, 144, "saguenay");
   xsArraySetString(gMapNames, 145, "saguenaylarge");
   xsArraySetString(gMapNames, 146, "siberia");
   xsArraySetString(gMapNames, 147, "siberialarge");
   xsArraySetString(gMapNames, 148, "silkroad");
   xsArraySetString(gMapNames, 149, "silkroadlarge");
   xsArraySetString(gMapNames, 150, "sonora");
   xsArraySetString(gMapNames, 151, "sonoralarge");
   xsArraySetString(gMapNames, 152, "texas");
   xsArraySetString(gMapNames, 153, "texaslarge");
   xsArraySetString(gMapNames, 154, "unknown");
   xsArraySetString(gMapNames, 155, "unknownlarge");
   xsArraySetString(gMapNames, 156, "yellow riverdry");
   xsArraySetString(gMapNames, 157, "yellow riverdrylarge");
   xsArraySetString(gMapNames, 158, "yucatan");
   xsArraySetString(gMapNames, 159, "yucatanlarge");
   xsArraySetString(gMapNames, 160, "yukon");
   xsArraySetString(gMapNames, 161, "yukonlarge");
   xsArraySetString(gMapNames, 162, "aftranssahara");
   xsArraySetString(gMapNames, 163, "aftranssaharalarge");
   xsArraySetString(gMapNames, 164, "aflostsahara");
   xsArraySetString(gMapNames, 165, "aflostsaharalarge");
   xsArraySetString(gMapNames, 166, "guianas");
   xsArraySetString(gMapNames, 167, "guianaslarge");
   xsArraySetString(gMapNames, 168, "panama");
   xsArraySetString(gMapNames, 169, "panamalarge");
   xsArraySetString(gMapNames, 170, "texasfrontier");
   xsArraySetString(gMapNames, 171, "texasfrontierlarge");
   xsArraySetString(gMapNames, 172, "aflakevictoria");
   xsArraySetString(gMapNames, 173, "aflakevictorialarge");
   // List above is up to date for the first 2022 patch.
}

//==============================================================================
/* analyzeGameSettingsAndType
   Set up all variables related to game settings and type.
*/
//==============================================================================
void analyzeGameSettingsAndType()
{
   debugSetup("         Analyzing Game Settings And Type");
   // cGameTypeCurrent hasn't been initialized yet at this point so must use the syscall.
   int gameType = aiGetGameType();
   if ((gameType == cGameTypeCampaign) || (gameType == cGameTypeScenario))
   {
      gSPC = true;
      cvOkToResign = false; // Default is to not allow resignation in SPC.
   }
   // Taunt defaults to true, but needs to be false in gSPC games.
   if (gSPC == true)
   {
      cvOkToTaunt = false;
   }
   //else // Deck building defaults to false like how it was in legacy, but we do make decks in non-SPC now.
   //{
      cvOkToBuildDeck = true;
   //}

   debugSetup("Game type is: " + gameType + ", 0=Scenario, 2=Random Map, 4=Campaign");
   debugSetup("gSPC is: " + gSPC);
   
   // Set the max age here - this can be overridden in preInit.
   cvMaxAge = aiGetMaxAge();
   
   // Setup the handicaps.
   // BaseLineHandicap is a global multiplier that we can use to adjust all up or down. Probably will remain at 1.0.
   // StartingHandicap is the handicap set at game launch in the UI, i.e. boost this player 10% == 1.10.  That needs to
   // be multiplied by the appropriate difficulty for each level.
   float startingHandicap = kbGetPlayerHandicap(cMyID);
   int maxPop = kbGetMaxPop();

   switch (cDifficultyCurrent)
   {
   case cDifficultySandbox: // Easy
   {
      // Set handicap to a small fraction of baseline, i.e. minus 70%.
      kbSetPlayerHandicap(cMyID, startingHandicap * baselineHandicap * 0.3); 
      cvOkToBuildForts = false;
      gMaxPop = 40;
      break;
   }
   case cDifficultyEasy: // Standard
   {
      if (gSPC == true)
      {
         kbSetPlayerHandicap(cMyID, startingHandicap * baselineHandicap * 0.5); // minus 50 percent for scenarios
         gMaxPop = maxPop;
      }
      else
      {
         kbSetPlayerHandicap(cMyID, startingHandicap * baselineHandicap * 0.4); // minus 60 percent
         gMaxPop = maxPop;
      }

      gAttackMissionInterval = 240000; // 8 minutes.
      cvOkToBuildForts = false;
      gDelayAttacks = true;
      break;
   }
   case cDifficultyModerate: // Moderate
   {
      gAttackMissionInterval = 150000; // 5 minutes.
      if (gSPC == true)
      {
         kbSetPlayerHandicap(cMyID, startingHandicap * baselineHandicap * 1.0); // minus 25% for scenarios
         gMaxPop = maxPop;
         aiSetMicroFlags(cMicroLevelNormal);
      }
      else
      {
         kbSetPlayerHandicap(cMyID, startingHandicap * baselineHandicap * 0.65); // minus 35%
         gMaxPop = maxPop;
      }
      break;
   }
   case cDifficultyHard: // Hard
   {
      kbSetPlayerHandicap(cMyID, startingHandicap * baselineHandicap * 1.0); // 1.0 handicap at hard, i.e. no bonus
      if (gSPC == true)
      {
         aiSetMicroFlags(cMicroLevelHigh);
		 kbSetPlayerHandicap(cMyID, startingHandicap * baselineHandicap * 1.5);
         gAttackMissionInterval = 120000; // 3 minutes.
         gMaxPop = maxPop;
         // Playing on hard in the campaign is a little bit different than Random Map hard.
         // We enable some stuff for the SPC Hard AI that RM Hard AI doesn't have.
         gDifficultyExpert = cDifficultyHard;
      }
      else
      {
         gMaxPop = maxPop;
         aiSetMicroFlags(cMicroLevelNormal);
         gAttackMissionInterval = 90000; // 2.5 minutes.
      }
      break;
   }
   case cDifficultyExpert: // Hardest
   {
      gMaxPop = maxPop;
      gAttackMissionInterval = 60000;                                       // 2 minutes.
      kbSetPlayerHandicap(cMyID, startingHandicap * baselineHandicap * 1.2); // +20% boost.
      aiSetMicroFlags(cMicroLevelHigh);
	  if (gSPC == true)
      {
		 kbSetPlayerHandicap(cMyID, startingHandicap * baselineHandicap * 2);
	  }
      break;
   }
   case cDifficultyExtreme: // Extreme
   {
      gMaxPop = maxPop;
      gAttackMissionInterval = 60000;                                       // 2 minutes.
      kbSetPlayerHandicap(cMyID, startingHandicap * baselineHandicap * 1.4); // +40% boost.
      aiSetMicroFlags(cMicroLevelHigh);
	  if (gSPC == true)
      {
		 kbSetPlayerHandicap(cMyID, startingHandicap * baselineHandicap * 2.5);
	  }
      break;
   }
   }
   // We can overwrite gMaxPop on one more occasion after we've initialized the cv variables.
   // We must safeguard against lower population custom settings.
   if (gMaxPop > maxPop)
   {
      gMaxPop = maxPop;
   }
   
   // We don't have a Settler maintain plan yet but that doesn't matter, call this to set a proper military pop.
   updateSettlersAndPopManager();

   debugSetup("Handicap is " + kbGetPlayerHandicap(cMyID));
   debugSetup("Difficulty is " + cDifficultyCurrent + ", 0=Easy, 1=Standard, 2=Moderate, 3=Hard, 4=Hardest, 5=Extreme");
}

//==============================================================================
/* analyzeMap
   Set up all variables related to the map layout, excluding our starting units.
*/
//==============================================================================
void analyzeMap()
{
   debugSetup("         Analyzing Map");
   debugSetup("Map name is: " + cRandomMapName);

   // Disable any LOST maps.
   if ((cRandomMapName == "afLOSTSahara") || (cRandomMapName == "afLOSTSaharaLarge"))
   {
      aiErrorMessageId(111386); // "This map cannot be played by the AI."
      cvInactiveAI = true;
   }
   
   // Initialize all the global water variables so we know what we're dealing with on this map.
   gWaterSpawnFlagID = getUnit(cUnitTypeHomeCityWaterSpawnFlag, cMyID);
   if (gWaterSpawnFlagID >= 0)
   {
      gWaterSpawnFlagPosition = kbUnitGetPosition(gWaterSpawnFlagID);
      gHaveWaterSpawnFlag = true;
      gNavyVec = gWaterSpawnFlagPosition;
      gNavyMap = true;
      debugSetup("We have a Water Spawn Flag with ID: " + gWaterSpawnFlagID + ", at position: " + gWaterSpawnFlagPosition);
      debugSetup("Setting gHaveWaterSpawnFlag/gNavyMap to true and setting gNavyVec to this Position");
   }
   else
   {
      debugSetup("We have no Water Spawn Flag, leaving all navy related variables on false/invalid");
   }
   
   if (gSPC == true)
   {
      // This map type has to be set inside of the scenario itself via the editor.
      if (aiIsMapType("AIFishingUseful") == true)
      {
         gGoodFishingMap = true;
      }
      else
      {
         gGoodFishingMap = false;
      }
   }
   else
   {
      // Basically if we find any fish on the map we decide it's a good fishing map.
      if (getGaiaUnitCount(cUnitTypeFish) > 0)
      {
         gGoodFishingMap = true;
      }
   }
   debugSetup("gGoodFishingMap = " + gGoodFishingMap);
   
   // This will create an interim main base at the location of any unit we do posses, since we lack a Town Center.
   // Only done if there is no TC, otherwise we rely on the auto-created base.
   int townCenterID = getUnit(cUnitTypeTownCenter, cMyID, cUnitStateAlive);
   vector baseVec = cInvalidVector;
   if (townCenterID < 0)
   {
      vector tempBaseVec = cInvalidVector;
      int unitID = getUnit(cUnitTypeAIStart, cMyID, cUnitStateAlive);
      if (unitID < 0)
      {
         unitID = getUnit(cUnitTypeCoveredWagon, cMyID, cUnitStateAlive);
      }
      if (unitID < 0)
      {
         unitID = getUnit(cUnitTypeHero, cMyID, cUnitStateAlive);
      }
      if (unitID < 0)
      {
         unitID = getUnit(cUnitTypeAbstractVillager, cMyID, cUnitStateAlive);
      }
      if (unitID < 0)
      {
         unitID = getUnit(cUnitTypeUnit, cMyID, cUnitStateAlive);
      }
   
      if (unitID < 0)
      {
         debugSetup("**** I give up... I can't find an aiStart object, Covered Wagon, Explorer, Settler or any unit."
            + " How do you expect me to play?!");
      }
      else
      {
         baseVec = kbUnitGetPosition(unitID);
         gMainBase = createMainBase(baseVec);
         kbBaseSetMain(cMyID, gMainBase, true);
         debugSetup("Temporary main base ID is: " + kbBaseGetMainID(cMyID));
      }
   }
   else 
   {
      baseVec = kbUnitGetPosition(townCenterID);
   }
   
   // Check for island map and starting on different islands.
   vector tempPlayerVec = cInvalidVector;
   int tempBaseVecAreaGroupID = kbAreaGroupGetIDByPosition(baseVec);
   gIslandMap = kbGetIslandMap();
   for (player = 1; < cNumberPlayers)
   {
      if (player == cMyID)
      {
         continue;
      }
      tempPlayerVec = kbGetPlayerStartingPosition(player);
      if (tempPlayerVec == cInvalidVector)
      {
         continue;
      }
      if (kbAreAreaGroupsPassableByLand(tempBaseVecAreaGroupID, kbAreaGroupGetIDByPosition(tempPlayerVec)) == false)
      {
         gStartOnDifferentIslands = true;
         break;
      }
   }
   debugSetup("Island map is " + gIslandMap + ", players start on different islands is " + gStartOnDifferentIslands);
   
   // On these maps we want to transport, which is what aiSetWaterMap is used for.
   if (gStartOnDifferentIslands == true)
   {
      aiSetWaterMap(true);
   }
}

//==============================================================================
/* initXSHandlers
   Set up all XS handlers that don't depend on control variables.
*/
//==============================================================================
void initXSHandlers()
{
   // Set up the age-up handler, this is used for chats and saving fastest age up times.
   aiSetHandler("ageUpHandler", cXSPlayerAgeHandler);

   // Set up the communication handler, this is the menu where you can ask your allied AI to do something.
   // Even though this menu won't function in gSPC we still set up the handler so the AI can constantly refuse.
   aiCommsSetEventHandler("commHandler");

   // Game ending handler, to save game-to-game data before game ends.
   aiSetHandler("gameOverHandler", cXSGameOverHandler);

   if (civIsEuropean() == true)
   {
      // Called when we've revolted.
      aiSetHandler("revoltedHandler", cXSRevoltedHandler);
   }
   
   // Called when the engine couldn't find a proper placement for our building.
   aiSetHandler("buildingPlacementFailedHandler", cXSBuildingPlacementFailedHandler);
}

//==============================================================================
/* initPersonality
   A function to set defaults that need to be in place before the loader file's
   preInit() function is called.
*/
//==============================================================================
void initPersonality(void)
{
   debugSetup("         Initializing personality");

   // Set behavior traits.
   debugSetup("My civ is " + kbGetCivName(cMyCiv));
   switch (cMyCiv)
   {
   case cCivBritish: // Elizabeth: Infantry oriented.
   case cCivTheCircle:
   case cCivPirate:
   case cCivSPCAct3:
   {
        btRushBoom = 0.9;
        btRushBoom = 0.9;    
		btOffenseDefense = 0.9;
		btBiasCav = 0.0;
		btBiasInf = 0.0;
		btBiasArt = 0.0;
		btBiasNative = 0.0;
		btBiasTrade = 0.9;
      break;
   }
   case cCivFrench: // Napoleon: Cav oriented, balanced
   {
        btRushBoom = 0.9;
        btRushBoom = 0.9;    
		btOffenseDefense = 0.9;
		btBiasCav = 0.0;
		btBiasInf = 0.0;
		btBiasArt = 0.0;
		btBiasNative = 0.0;
		btBiasTrade = 0.9;
      break;
   }
   case cCivSpanish: // Isabella: Bias against natives.
   {
        btRushBoom = 0.9;
        btRushBoom = 0.9;    
		btOffenseDefense = 0.9;
		btBiasCav = 0.0;
		btBiasInf = 0.0;
		btBiasArt = 0.0;
		btBiasNative = 0.0;
		btBiasTrade = 0.9;
      break;
   }
   case cCivRussians: // Ivan: Infantry oriented rusher
   {
        btRushBoom = 0.9;
        btRushBoom = 0.9;    
		btOffenseDefense = 0.9;
		btBiasCav = 0.0;
		btBiasInf = 0.0;
		btBiasArt = 0.0;
		btBiasNative = 0.0;
		btBiasTrade = 0.9;
      break;
   }
   case cCivGermans: // Fast fortress, cavalry oriented
   {
        btRushBoom = 0.9;
        btRushBoom = 0.9;    
		btOffenseDefense = 0.9;
		btBiasCav = 0.0;
		btBiasInf = 0.0;
		btBiasArt = 0.0;
		btBiasNative = 0.0;
		btBiasTrade = 0.9;
      break;
   }
   case cCivDutch: // Fast fortress, ignore trade routes.
   {
        btRushBoom = 0.9;
        btRushBoom = 0.9;    
		btOffenseDefense = 0.9;
		btBiasCav = 0.0;
		btBiasInf = 0.0;
		btBiasArt = 0.0;
		btBiasNative = 0.0;
		btBiasTrade = 0.9;
      break;
   }
   case cCivPortuguese: // Fast fortress, artillery oriented
   {
        btRushBoom = 0.9;
        btRushBoom = 0.9;    
		btOffenseDefense = 0.9;
		btBiasCav = 0.0;
		btBiasInf = 0.0;
		btBiasArt = 0.0;
		btBiasNative = 0.0;
		btBiasTrade = 0.9;
      break;
   }
   case cCivOttomans: // Artillery oriented, rusher
   {
        btRushBoom = 0.9;
        btRushBoom = 0.9;    
		btOffenseDefense = 0.9;
		btBiasCav = 0.0;
		btBiasInf = 0.0;
		btBiasArt = 0.0;
		btBiasNative = 0.0;
		btBiasTrade = 0.9;
      break;
   }
   case cCivXPSioux: // Extreme rush
   {
        btRushBoom = 0.9;
        btRushBoom = 0.9;    
		btOffenseDefense = 0.9;
		btBiasCav = 0.0;
		btBiasInf = 0.0;
		btBiasArt = 0.0;
		btBiasNative = 0.0;
		btBiasTrade = 0.9;
      break;
   }
   case cCivXPIroquois: // Fast fortress, trade and native bias.
   {
        btRushBoom = 0.9;
        btRushBoom = 0.9;    
		btOffenseDefense = 0.9;
		btBiasCav = 0.0;
		btBiasInf = 0.0;
		btBiasArt = 0.0;
		btBiasNative = 0.0;
		btBiasTrade = 0.9;
      break;
   }
   case cCivXPAztec: // Rusher.
   {
        btRushBoom = 0.9;
        btRushBoom = 0.9;    
		btOffenseDefense = 0.9;
		btBiasCav = 0.0;
		btBiasInf = 0.0;
		btBiasArt = 0.0;
		btBiasNative = 0.0;
		btBiasTrade = 0.9;
      break;
   }
   case cCivChinese: // Kangxi:  Fast fortress, infantry oriented
   {
        btRushBoom = 0.9;
        btRushBoom = 0.9;    
		btOffenseDefense = 0.9;
		btBiasCav = 0.0;
		btBiasInf = 0.0;
		btBiasArt = 0.0;
		btBiasNative = 0.0;
		btBiasTrade = 0.9;
      break;
   }
   case cCivJapanese: // Shogun Tokugawa Ieyasu: Rusher, ignores trade routes
   {
        btRushBoom = 0.9;
        btRushBoom = 0.9;    
		btOffenseDefense = 0.9;
		btBiasCav = 0.0;
		btBiasInf = 0.0;
		btBiasArt = 0.0;
		btBiasNative = 0.0;
		btBiasTrade = 0.9;
      break;
   }
   case cCivIndians: // Rusher, balanced
   {
        btRushBoom = 0.9;
        btRushBoom = 0.9;    
		btOffenseDefense = 0.9;
		btBiasCav = 0.0;
		btBiasInf = 0.0;
		btBiasArt = 0.0;
		btBiasNative = 0.0;
		btBiasTrade = 0.9;
      break;
   }
   case cCivDEInca: // Huayna Capac: Rusher, trade and strong native bias.
   {
        btRushBoom = 0.9;
        btRushBoom = 0.9;    
		btOffenseDefense = 0.9;
		btBiasCav = 0.0;
		btBiasInf = 0.0;
		btBiasArt = 0.0;
		btBiasNative = 0.0;
		btBiasTrade = 0.9;
      break;
   }
   case cCivDESwedish: // Gustav the Great: Rusher, small artillery focus.
   {
        btRushBoom = 0.9;
        btRushBoom = 0.9;    
		btOffenseDefense = 0.9;
		btBiasCav = 0.0;
		btBiasInf = 0.0;
		btBiasArt = 0.0;
		btBiasNative = 0.0;
		btBiasTrade = 0.9;
      break;
   }
   case cCivDEAmericans: // George Washington: Balanced.
   {
        btRushBoom = 0.9;
        btRushBoom = 0.9;    
		btOffenseDefense = 0.9;
		btBiasCav = 0.0;
		btBiasInf = 0.0;
		btBiasArt = 0.0;
		btBiasNative = 0.0;
		btBiasTrade = 0.9;
      break;
   }
   case cCivDEEthiopians: // Emperor Tewodros: Bias towards building TPs.
   {
        btRushBoom = 0.9;
        btRushBoom = 0.9;    
		btOffenseDefense = 0.9;
		btBiasCav = 0.0;
		btBiasInf = 0.0;
		btBiasArt = 0.0;
		btBiasNative = 0.0;
		btBiasTrade = 0.9;
      break;
   }
   case cCivDEHausa: // Queen Amina: Bias towards building TPs.
   {
        btRushBoom = 0.9;
        btRushBoom = 0.9;    
		btOffenseDefense = 0.9;
		btBiasCav = 0.0;
		btBiasInf = 0.0;
		btBiasArt = 0.0;
		btBiasNative = 0.0;
		btBiasTrade = 0.9;
      break;
   }
   case cCivDEMexicans: // Miguel Hidalgo: Balanced.
   {
        btRushBoom = 0.9;
        btRushBoom = 0.9;    
		btOffenseDefense = 0.9;
		btBiasCav = 0.0;
		btBiasInf = 0.0;
		btBiasArt = 0.0;
		btBiasNative = 0.0;
		btBiasTrade = 0.9;
      break;
   }
   }

   /*if (gSPC == false)
   { // Occasionally adjust AI preferences for more replayability without going overboard.
      int strategyRandomizer = aiRandInt(16);
      if (strategyRandomizer == 0)
      {
         btBiasCav += 0.2;
      }
      else if (strategyRandomizer == 1)
      {
         btBiasCav += 0.1;
      }
      else if (strategyRandomizer == 2)
      {
         btBiasCav -= 0.1;
      }
      else if (strategyRandomizer == 3)
      {
         btBiasCav -= 0.2;
      }
      else if (strategyRandomizer == 4)
      {
         btBiasInf += 0.2;
      }
      else if (strategyRandomizer == 5)
      {
         btBiasInf += 0.1;
      }
      else if (strategyRandomizer == 6)
      {
         btBiasInf -= 0.1;
      }
      else if (strategyRandomizer == 7)
      {
         btBiasInf -= 0.2;
      }  
   }
   */

   if (((aiTreatyActive() == true) || (aiGetGameMode() == cGameModeDeathmatch)) && 
       (btRushBoom > 0.0))
   {
      btRushBoom = 0.0; // Don't attempt to rush in treaty or deathmatch games.
   }
   
   // We don't allow these variables to go over 1.0 or under -1.0, 
   // and they could via the randomizer so safeguard against this.
   if (btBiasCav > 1.0)
   {
      btBiasCav = 1.0;
   }
   if (btBiasCav < -1.0)
   {
      btBiasCav = -1.0;
   }
      
   if (btBiasInf > 1.0)
   {
      btBiasInf = 1.0;
   }
   if (btBiasInf < -1.0)
   {
      btBiasInf = -1.0;
   } 
}

//==============================================================================
/* startUpChats
   Analyze our history with the players in the game and sent them an appropriate message.
*/
//==============================================================================
void startUpChats()
{
   debugSetup("         Sending start up chats");
   //-- See who we are playing against.  If we have played against these players before, seed out unitpicker data, and
   // then chat some. XS_HELP("float aiPersonalityGetGameResource(int playerHistoryIndex, int gameIndex, int
   // resourceID):
   // Returns the given resource from the gameIndex game. If gameIndex is -1, this will return the avg of all games
   // played.") XS_HELP("int aiPersonalityGetGameUnitCount(int playerHistoryIndex, int gameIndex, int unitType): Returns
   // the unit count from the gameIndex game. If gameIndex is -1, this will return the avg of all games played.")
   // TODO:  To understand my opponent's unit biases, I'll have to do the following:
   //          1)  Store the opponents civ each game
   //          2)  On game start, look up his civ from last game
   //          3)  Based on his civ, look up how many units he made of each class (inf, cav, art), compare to 'normal'.
   //          4)  Set unitPicker biases to counter what he's likely to send.

   int numPlayerHistories = aiPersonalityGetNumberPlayerHistories();
   debugSetup("PlayerHistories: " + numPlayerHistories);
   for (pid = 1; < cNumberPlayers)
   {
      //-- Skip ourself.
      if (pid == cMyID)
         continue;

      //-- get player name
      string playerName = kbGetPlayerName(pid);
      debugSetup("PlayerName: " + playerName);

      //-- have we played against them before.
      int playerHistoryID = aiPersonalityGetPlayerHistoryIndex(playerName);
      if (playerHistoryID == -1)
      {
         debugSetup("PlayerName: Never played against");
         //-- Lets make a new player history.
         playerHistoryID = aiPersonalityCreatePlayerHistory(playerName);
         if (kbIsPlayerAlly(pid) == true)
            sendStatement(pid, cAICommPromptToAllyIntro);
         else
            sendStatement(pid, cAICommPromptToEnemyIntro);
         if (playerHistoryID == -1)
         {
            debugSetup("PlayerName: Failed to create player history for " + playerName);
            continue;
         }
         debugSetup("PlayerName: Created new history for " + playerName);
      }
      else
      {
         //-- get how many times we have played against them.
         float totalGames = aiPersonalityGetPlayerGamesPlayed(playerHistoryID, cPlayerRelationAny);
         float numberGamePlayedAgainst = aiPersonalityGetPlayerGamesPlayed(playerHistoryID, cPlayerRelationEnemy);
         float numberGamesTheyWon = aiPersonalityGetTotalGameWins(playerHistoryID, cPlayerRelationEnemy);
         float myWinLossRatio = 1.0 - (numberGamesTheyWon / numberGamePlayedAgainst);
         debugSetup("PlayedAgainst: " + numberGamePlayedAgainst);
         debugSetup("TimesTheyWon: " + numberGamesTheyWon);
         debugSetup("MyWinLossRatio: " + myWinLossRatio);

         bool iWonOurLastGameAgainstEachOther = aiPersonalityGetDidIWinLastGameVS(playerHistoryID);
         // bool weWonOurLastGameTogether; <-- cant do yet.

         //-- get how fast they like to attack
         // Minus one game index gives an average.
         int avgFirstAttackTime = aiPersonalityGetGameFirstAttackTime(playerHistoryID, -1);
         debugSetup("Player's Avg first Attack time: " + avgFirstAttackTime);

         int lastFirstAttackTime = aiPersonalityGetGameFirstAttackTime(playerHistoryID, totalGames - 1);
         debugSetup("Player's Last game first Attack time: " + lastFirstAttackTime);

         //-- save some info.
         aiPersonalitySetPlayerUserVar(playerHistoryID, "myWinLossPercentage", myWinLossRatio);
         //-- test, get the value back out
         float tempFloat = aiPersonalityGetPlayerUserVar(playerHistoryID, "myWinLossPercentage");

         // Consider chats based on player history...
         // First, combinations of "was ally last time" and "am ally this time"
         bool wasAllyLastTime = true;
         bool isAllyThisTime = true;
         if (aiPersonalityGetPlayerUserVar(playerHistoryID, "wasMyAllyLastGame") == 0.0)
            wasAllyLastTime = false;
         if (kbIsPlayerAlly(pid) == false)
            isAllyThisTime = false;
         bool difficultyIsHigher = false;
         bool difficultyIsLower = false;
         float lastDifficulty = aiPersonalityGetPlayerUserVar(playerHistoryID, "lastGameDifficulty");
         if (lastDifficulty >= 0.0)
         {
            if (lastDifficulty > cDifficultyCurrent)
               difficultyIsLower = true;
            if (lastDifficulty < cDifficultyCurrent)
               difficultyIsHigher = true;
         }
         bool iBeatHimLastTime = false;
         bool heBeatMeLastTime = false;
         bool iCarriedHimLastTime = false;
         bool heCarriedMeLastTime = false;

         if (aiPersonalityGetPlayerUserVar(playerHistoryID, "heBeatMeLastTime") == 1.0) // STORE ME
            heBeatMeLastTime = true;
         if (aiPersonalityGetPlayerUserVar(playerHistoryID, "iBeatHimLastTime") == 1.0) // STORE ME
            iBeatHimLastTime = true;
         if (aiPersonalityGetPlayerUserVar(playerHistoryID, "iCarriedHimLastTime") == 1.0) // STORE ME
            iCarriedHimLastTime = true;
         if (aiPersonalityGetPlayerUserVar(playerHistoryID, "heCarriedMeLastTime") == 1.0) // STORE ME
            heCarriedMeLastTime = true;

         if (wasAllyLastTime == false)
         {
            if (aiPersonalityGetPlayerUserVar(playerHistoryID, "iBeatHimLastTime") == 1.0) // STORE ME
               iBeatHimLastTime = true;
            if (aiPersonalityGetPlayerUserVar(playerHistoryID, "heBeatMeLastTime") == 1.0) // STORE ME
               heBeatMeLastTime = true;
         }

         bool iWonLastGame = false;
         if (aiPersonalityGetPlayerUserVar(playerHistoryID, "iWonLastGame") == 1.0) // STORE ME
            iWonLastGame = true;

         if (isAllyThisTime)
         { // We are allies
            if (difficultyIsHigher == true)
               sendStatement(pid, cAICommPromptToAllyIntroWhenDifficultyHigher);
            if (difficultyIsLower == true)
               sendStatement(pid, cAICommPromptToAllyIntroWhenDifficultyLower);
            if (iCarriedHimLastTime == true)
               sendStatement(pid, cAICommPromptToAllyIntroWhenICarriedHimLastGame);
            if (heCarriedMeLastTime == true)
               sendStatement(pid, cAICommPromptToAllyIntroWhenHeCarriedMeLastGame);
            if (iBeatHimLastTime == true)
               sendStatement(pid, cAICommPromptToAllyIntroWhenIBeatHimLastGame);
            if (heBeatMeLastTime == true)
               sendStatement(pid, cAICommPromptToAllyIntroWhenHeBeatMeLastGame);

            debugSetup("Last map ID was " + aiPersonalityGetPlayerUserVar(playerHistoryID, "lastMapID"));
            if ((getMapID() >= 0) && (getMapID() == aiPersonalityGetPlayerUserVar(playerHistoryID, "lastMapID")))
            {
               sendStatement(pid, cAICommPromptToAllyIntroWhenMapRepeats);
               debugSetup("We're playing on the same map as the previous game");
            }
            if (wasAllyLastTime)
            {
               debugSetup(playerName + " was my ally last game and is my ally this game.");
               if (iWonLastGame == false)
                  sendStatement(pid, cAICommPromptToAllyIntroWhenWeLostLastGame);
               else
                  sendStatement(pid, cAICommPromptToAllyIntroWhenWeWonLastGame);
            }
            else
            {
               debugSetup(playerName + " was my enemy last game and is my ally this game.");
            }
         }
         else
         { // We are enemies
            if (difficultyIsHigher == true)
               sendStatement(pid, cAICommPromptToEnemyIntroWhenDifficultyHigher);
            if (difficultyIsLower == true)
               sendStatement(pid, cAICommPromptToEnemyIntroWhenDifficultyLower);
            if ((getMapID() >= 0) && (getMapID() == aiPersonalityGetPlayerUserVar(playerHistoryID, "lastMapID")))
               sendStatement(pid, cAICommPromptToEnemyIntroWhenMapRepeats);
            if (wasAllyLastTime)
            {
               debugSetup(playerName + " was my ally last game and is my enemy this game.");
            }
            else
            {
               debugSetup(playerName + " was my enemy last game and is my enemy this game.");
               // Check if he changed the odds
               int enemyCount = aiPersonalityGetPlayerUserVar(playerHistoryID, "myEnemyCount");
               int allyCount = aiPersonalityGetPlayerUserVar(playerHistoryID, "myAllyCount");
               if (enemyCount == getEnemyCount())
               {                                  // Check if enemyCount is the same, but ally count is down
                  if (allyCount > getAllyCount()) // I have fewer allies now
                     sendStatement(pid, cAICommPromptToEnemyIntroWhenTeamOddsEasier); // He wimped out
                  if (allyCount < getAllyCount())                                     // I have more allies now
                     sendStatement(pid, cAICommPromptToEnemyIntroWhenTeamOddsHarder); // He upped the difficulty
               }
               else if (allyCount == getAllyCount())
               {                                    // Else, check if allyCount is the same, but enemyCount is smaller
                  if (enemyCount > getEnemyCount()) // I have fewer enemies now
                     sendStatement(pid, cAICommPromptToEnemyIntroWhenTeamOddsHarder); // He upped the difficulty
                  if (enemyCount < getEnemyCount())                                   // I have more enemies now
                     sendStatement(pid, cAICommPromptToEnemyIntroWhenTeamOddsEasier); // He wimped out
               }
            }
         }
      }

      // Save info about this game
      aiPersonalitySetPlayerUserVar(playerHistoryID, "lastGameDifficulty", cDifficultyCurrent);
      int wasAlly = 0;
      if (kbIsPlayerAlly(pid) == true)
         wasAlly = 1;
      else
      { // He is an enemy, remember the odds (i.e. 1v3, 2v2, etc.)
         aiPersonalitySetPlayerUserVar(playerHistoryID, "myAllyCount", getAllyCount());
         aiPersonalitySetPlayerUserVar(playerHistoryID, "myEnemyCount", getEnemyCount());
      }
      aiPersonalitySetPlayerUserVar(playerHistoryID, "wasMyAllyLastGame", wasAlly);
      aiPersonalitySetPlayerUserVar(playerHistoryID, "lastMapID", getMapID());
   }
}

//==============================================================================
/* preInitFinal
   Our bt/cv variables have been set to their final values.
   See if we must adjust anything we did before this point to account for this.
*/
//==============================================================================
void preInitFinal()
{
   debugSetup("         Finalizing everything related to setting cv / bt");
   if (cvInactiveAI == true)
   {
      cvOkToTrainArmy = false;
      cvOkToAllyNatives = false;
      cvOkToClaimTrade = false;
      cvOkToGatherFood = false;
      cvOkToGatherGold = false;
      cvOkToGatherWood = false;
      cvOkToExplore = false;
      cvOkToResign = false;
      cvOkToAttack = false;
      // Nothing else we do in Main matters anymore, just quit and let the AI completely idle.
      // We also prevent it from ever getting past the waitForStartup check.
      return;
   }
   
   // We disable gathering for now so we can focus on building, it is enabled again after the DM start.
   if (aiGetGameMode() == cGameModeDeathmatch)
   {
      cvOkToGatherFood = false;
      cvOkToGatherGold = false;
      cvOkToGatherWood = false;
   }
   
   if (cvMaxCivPop > -1) // We must override the Settler targets we set previously if they're too high to
   {                     // account for this variable.
      for (index = cAge1; <= cAge5)
      {
         if (xsArrayGetInt(gTargetSettlerCounts, index) > cvMaxCivPop)
         {
            xsArraySetInt(gTargetSettlerCounts, index, cvMaxCivPop);
         }
      }
   }
   
   if ((cvMaxCivPop >= 0) && (cvMaxArmyPop >= 0)) // Both are defined so set an implied pop limit.
   {
      gMaxPop = cvMaxCivPop + cvMaxArmyPop;
      debugSetup("Both cvMaxCivPop and cvMaxArmyPop are defined, changing gMaxPop to: " + gMaxPop);
   }
   
   debugSetup("INITIAL BEHAVIOR SETTINGS");
   debugSetup("Rush / Boom: " + btRushBoom);
   debugSetup("Offense / Defense: " + btOffenseDefense);
   debugSetup("Cavalry: " + btBiasCav);
   debugSetup("Infantry: " + btBiasInf);
   debugSetup("Artillery: " + btBiasArt);
   debugSetup("Natives: " + btBiasNative);
   debugSetup("Trade: " + btBiasTrade);
   
   debugSetup("Our max age is set to: " + cvMaxAge + ", 0=Exploration, 1=Commerce, 2=Fortress, 3=Industrial, 4=Imperial");
}

//==============================================================================
/* prepareForInit
   Figure out our starting conditions, and deal with them.
*/
//==============================================================================
void prepareForInit()
{
   debugSetup("         Analyzing what type of start we have in preparation of activating AI");
   if (gSPC == true)
   {
      // Wait for the aiStart object to appear, then figure out what to do.
      xsEnableRule("waitForStartup");
   }
   else // Random Map game.
   {
      aiSetRandomMap(true);
      // Now let's figure out if we're dealing with a regular Town Center start or with Nomad.
      if (kbUnitCount(cMyID, cUnitTypeTownCenter, cUnitStateAlive) > 0)
      {
         debugSetup("Start mode: Land Town Center");
         gStartMode = cStartModeLandTC;
         init(); // Call init directly and thus start the AI without delay.
      }
      else // This must be a Nomad start.
      {
         debugSetup("Start mode: Land Wagon (Nomad)");
         gStartMode = cStartModeLandWagon;
         if (cRandomMapName == "Ceylon")
         {
            initCeylonNomadStart(); // Transport our Covered Wagon to the mainland on Ceylon.
         }
         else
         {
            xsEnableRule("initRule"); // This will call init() after 3 seconds of delay.
         }
      }
   }
}

//==============================================================================
/* waitForStartup
   During Campaigns and Scenarios the AI doesn't automatically start working for real.
   It will wait until an AIStart object has been found, thus we query for it a lot.
   After we find it we figure out our starting conditions, and deal with them.
*/
//==============================================================================
rule waitForStartup
inactive
minInterval 1
{
   if (cvInactiveAI == true)
   {
      xsDisableSelf();
      return;
   }
   
   if (kbUnitCount(cMyID, cUnitTypeAIStart, cUnitStateAny) < 1)
   {
      return;
   }

   if (kbUnitCount(cMyID, cUnitTypeTownCenter, cUnitStateAlive) > 0)
   {
      debugSetup("Start mode: Scenario / Campaign with Town Center");
      gStartMode = cStartModeScenarioTC;
      init(); // Call init directly and thus start the AI without delay.
   }
   else
   {
      if (kbUnitCount(cMyID, cUnitTypeCoveredWagon, cUnitStateAlive) > 0)
      {
         debugSetup("Start mode: Scenario / Campaign with Covered Wagon");
         gStartMode = cStartModeScenarioWagon;
         xsEnableRule("initRule"); // This will call init() after 3 seconds of delay.
      }
      else
      {
         debugSetup("Start mode: Scenario / Campaign, without Town Center");
         gStartMode = cStartModeScenarioNoTC;
         init(); // Call init directly and thus start the AI without delay.
      }
   }
   xsDisableSelf();
}

//==============================================================================
// initRule
// Add a brief delay to make sure the build plan with the Covered Wagon doesn't bug out.
//==============================================================================
rule initRule
inactive
minInterval 3
{
   debugSetup("         Delayed calling of init()");
   init(); // Actually enable the entire AI.
   xsDisableSelf();
}

//==============================================================================
/* initEcon
   Set up our initial economy so we're ready to start gathering.
*/
//==============================================================================
void initEcon(void)
{
   debugSetup("         Initialising economy");
   
   // Adjust target Settler counts based on train limit, to take some custom rules into account.
   // Civs with dynamically increasing BLs need to be handled differently so we don't limit this array to low values at the
   // start of the game.
   if (cMyCiv != cCivOttomans)
   {
      int settlerLimit = kbGetBuildLimit(cMyID, gEconUnit);
      for (index = cAge1; <= cAge5)
      {
         if (xsArrayGetInt(gTargetSettlerCounts, index) > settlerLimit)
         {
            xsArraySetInt(gTargetSettlerCounts, index, settlerLimit);
         }
      }
   }
   
   // Create a herd plan to gather all herdables that we encounter.
   gHerdPlanID = aiPlanCreate("Gather Herdable Plan", cPlanHerd);
   if (gHerdPlanID >= 0)
   {
      aiPlanAddUnitType(gHerdPlanID, cUnitTypeHerdable, 0, 100, 100);
      aiPlanSetVariableInt(gHerdPlanID, cHerdPlanBuildingTypeID, 0, cUnitTypeTownCenter);
      aiPlanSetVariableFloat(gHerdPlanID, cHerdPlanDistance, 0, 5.0);
      aiPlanSetActive(gHerdPlanID);
   }
   
   // These numbers belonged to the now deprecated eco system
   // They're just used by other eco plans not being the main gathering.
   kbSetTargetSelectorFactor(cTSFactorDistance, -200.0); // negative is good
   kbSetTargetSelectorFactor(cTSFactorPoint, 5.0);       // positive is good
   kbSetTargetSelectorFactor(cTSFactorTimeToDone, 0.0);  // positive is good
   kbSetTargetSelectorFactor(cTSFactorBase, 100.0);      // positive is good
   kbSetTargetSelectorFactor(cTSFactorDanger, -10.0);    // negative is good

   // The AI no longer uses the legacy system of gathering and spending resources.
   // The 5 commands below basically turn off the old system and enable the new one.
   
   // let the engine decide which farm to set on food or gold.
   aiSetTacticFarm(gFarmFoodTactic >= 0);
   
   // By turning on we let the engine automatically handle unit gather rate differences 
   // when allocating gatherers among resources.
   aiSetDistributeGatherersByResourcePercentage(true);
   
   // Instead of creating a fixed amount of gather plans, create a new gather plan for each resource that
   // is closest to the resource type gatherers being asked to gather.
   aiSetDistributeGatherersByClosestResource(true);
   
   // Disable escrows so we can have full control of our resources, even though you sometimes still
   // have to provide escrows for certain syscalls they are completely ignored.
   aiSetEscrowsDisabled(true);             
   
   // Enable resource priority for plans.
   aiSetPlanResourcePriorityEnabled(true); 

   if ((cMyCiv != cCivJapanese) && (cMyCiv != cCivSPCJapanese) && (cMyCiv != cCivSPCJapaneseEnemy))
   {
      if (cDifficultyCurrent >= gDifficultyExpert)
      {
         xsEnableRule("backHerdMonitor");
      }
   }
   
   // The Cows only spawn when you have your first Town Center.
   if ((civIsAfrican() == true) && 
       (kbUnitCount(cMyID, cUnitTypeTownCenter, cUnitStateAlive) > 0))
   {
      xsEnableRule("earlySlaughterMonitor");
      earlySlaughterMonitor();
   }

   if ((cMyCiv == cCivJapanese) || (cMyCiv == cCivSPCJapanese) || (cMyCiv == cCivSPCJapaneseEnemy))
   {  
      vector mainBaseLocation = kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID));
      // We are Japanese and we only want to continue if we have a valid food source.
      if ((getUnitCountByLocation(cUnitTypeBerryBush, cMyID, cUnitStateAny, mainBaseLocation, 30.0) > 0) ||
          (getUnitCountByLocation(cUnitTypeypBerryBuilding, 0, cUnitStateAny, mainBaseLocation, 30.0) > 0))
      {
         initResourceBreakdowns();
      }
      else // Wait until the first Cherry Orchard is built if we have no Berry Bushes.
      {
         xsEnableRule("initResourceBreakdownsDelay");
      }
   }
   else
   {
      initResourceBreakdowns();
   }
   
   xsEnableRuleGroup("startup");
   
   // Lastly, force an update on the economy by calling the function directly.
   econMaster();
}

//==============================================================================
/* initMil
   Set up our initial military so we're ready to start fighting.
*/
//==============================================================================
void initMil(void)
{
   aiSetAttackResponseDistance(65.0);
   aiSetAutoGatherMilitaryUnits(true);
   // Set the Explore Danger Threshold.
   aiSetExploreDangerThreshold(110.0);
   // Allow the AI to use its abilities, we do this here so that inactive AI don't activate it.
   xsEnableRule("abilityManager");
      // Immediately select a target.
   mostHatedEnemy();
   if (kbGetCiv() == cCivBritish)
   {      
      gLandPrimaryArmyUnit = cUnitTypeMusketeer;
      gLandTertiaryArmyUnit = cUnitTypeMusketeer;
      gLandSecondaryArmyUnit = cUnitTypeHussar;
      //gLandPrimaryArmyUnit = cUnitTypeLongbowman;
      //gLandPrimaryArmyUnit = cUnitTypeHussar;
      //gLandPrimaryArmyUnit = cUnitTypeDragoon;
      //gLandSecondaryArmyUnit = cUnitTypeMusketeer;
      //gLandSecondaryArmyUnit = cUnitTypeLongbowman;
      //gLandSecondaryArmyUnit = cUnitTypeHussar;
      //gLandSecondaryArmyUnit = cUnitTypeDragoon;
      //gLandTertiaryArmyUnit = cUnitTypeMusketeer;
      //gLandTertiaryArmyUnit = cUnitTypeLongbowman;
      //gLandTertiaryArmyUnit = cUnitTypeHussar;
      //gLandTertiaryArmyUnit = cUnitTypeDragoon;
      //gLandPrimaryArmyUnit = cUnitTypeMusketeer;//  cUnitTypeHussar + cUnitTypeMusketeer + cUnitTypeDragoon + cUnitTypeLongbowman;
      //gLandSecondaryArmyUnit = cUnitTypeLongbowman;//  + cUnitTypeMusketeer + cUnitTypeDragoon + cUnitTypeLongbowman;
      //gLandTertiaryArmyUnit = cUnitTypeHussar;//  + cUnitTypeMusketeer + cUnitTypeDragoon + cUnitTypeLongbowman;
   	  if (kbGetAge() >= cAge4)
	  gAbstractArtilleryUnit = cUnitTypexpHorseArtillery;
	  else
	  gAbstractArtilleryUnit = cUnitTypeFalconet;
   } 
   if (kbGetCiv() == cCivFrench)
   {  
      gLandPrimaryArmyUnit = cUnitTypeMusketeer;
      gLandSecondaryArmyUnit = cUnitTypeMusketeer;
      gLandTertiaryArmyUnit = cUnitTypeHussar;
      //gLandPrimaryArmyUnit = cUnitTypeSkirmisher;
      //gLandPrimaryArmyUnit = cUnitTypeCuirassier;
      //gLandPrimaryArmyUnit = cUnitTypeDragoon;
      //gLandSecondaryArmyUnit = cUnitTypeMusketeer;
      //gLandSecondaryArmyUnit = cUnitTypeSkirmisher;
      //gLandSecondaryArmyUnit = cUnitTypeCuirassier;
      //gLandSecondaryArmyUnit = cUnitTypeDragoon;
      //gLandTertiaryArmyUnit = cUnitTypeMusketeer;
      //gLandTertiaryArmyUnit = cUnitTypeSkirmisher;
      //gLandTertiaryArmyUnit = cUnitTypeCuirassier;
      //gLandTertiaryArmyUnit = cUnitTypeDragoon;
      //gLandPrimaryArmyUnit = cUnitTypeMusketeer;//  cUnitTypeSkirmisher + cUnitTypeCuirassier + cUnitTypeMusketeer + cUnitTypeDragoon + cUnitTypeHussar;
      //gLandSecondaryArmyUnit = cUnitTypeSkirmisher;//  + cUnitTypeCuirassier + cUnitTypeMusketeer + cUnitTypeDragoon + cUnitTypeHussar;
      //gLandTertiaryArmyUnit = cUnitTypeCuirassier;//  + cUnitTypeCuirassier + cUnitTypeMusketeer + cUnitTypeDragoon + cUnitTypeHussar;
   	  if (kbGetAge() >= cAge4)
	  gAbstractArtilleryUnit = cUnitTypexpHorseArtillery;
	  else
	  gAbstractArtilleryUnit = cUnitTypeFalconet;
   }
   if (kbGetCiv() == cCivGermans)
   {
      gLandPrimaryArmyUnit = cUnitTypeUhlan;
      gLandSecondaryArmyUnit = cUnitTypeUhlan;
      gLandTertiaryArmyUnit = cUnitTypeUhlan;
      //gLandPrimaryArmyUnit = cUnitTypeDopplesoldner;
      //gLandPrimaryArmyUnit = cUnitTypeSkirmisher;
      //gLandPrimaryArmyUnit = cUnitTypeWarWagon;
      //gLandSecondaryArmyUnit = cUnitTypeDopplesoldner;
      //gLandSecondaryArmyUnit = cUnitTypeUhlan;
      //gLandSecondaryArmyUnit = cUnitTypeSkirmisher;
      //gLandSecondaryArmyUnit = cUnitTypeWarWagon;
      //gLandTertiaryArmyUnit = cUnitTypeDopplesoldner;
      //gLandTertiaryArmyUnit = cUnitTypeUhlan;
      //gLandTertiaryArmyUnit = cUnitTypeSkirmisher;
      //gLandTertiaryArmyUnit = cUnitTypeWarWagon;
      //gLandPrimaryArmyUnit = cUnitTypeDopplesoldner;//  + cUnitTypeWarWagon + cUnitTypeSkirmisher + cUnitTypeUhlan;
      //gLandSecondaryArmyUnit = cUnitTypeSkirmisher;//  + cUnitTypeWarWagon + cUnitTypeSkirmisher + cUnitTypeUhlan;
      //gLandTertiaryArmyUnit = cUnitTypeWarWagon;//  + cUnitTypeWarWagon + cUnitTypeSkirmisher + cUnitTypeUhlan;
   	  if (kbGetAge() >= cAge4)
	  gAbstractArtilleryUnit = cUnitTypexpHorseArtillery;
	  else
	  gAbstractArtilleryUnit = cUnitTypeFalconet;
   }
   if (kbGetCiv() == cCivSpanish)
   {
      gLandPrimaryArmyUnit = cUnitTypeMusketeer;
      gLandSecondaryArmyUnit = cUnitTypeMusketeer;
      gLandTertiaryArmyUnit = cUnitTypeHussar;
      //gLandPrimaryArmyUnit = cUnitTypeLancer;
      //gLandPrimaryArmyUnit = cUnitTypeRodelero;
      //gLandPrimaryArmyUnit = cUnitTypePikeman;
      //gLandPrimaryArmyUnit = cUnitTypeWarDog;
      //gLandPrimaryArmyUnit = cUnitTypeMusketeer;
      //gLandPrimaryArmyUnit = cUnitTypeSkirmisher;
      //gLandPrimaryArmyUnit = cUnitTypeDragoon;
      //gLandSecondaryArmyUnit = cUnitTypeLancer;
      //gLandSecondaryArmyUnit = cUnitTypeRodelero;
      //gLandSecondaryArmyUnit = cUnitTypePikeman;
      //gLandSecondaryArmyUnit = cUnitTypeWarDog;
      //gLandSecondaryArmyUnit = cUnitTypeMusketeer;
      //gLandSecondaryArmyUnit = cUnitTypeSkirmisher;
      //gLandSecondaryArmyUnit = cUnitTypeDragoon;
      //gLandTertiaryArmyUnit = cUnitTypeLancer;
      //gLandTertiaryArmyUnit = cUnitTypeRodelero;
      //gLandTertiaryArmyUnit = cUnitTypePikeman;
      //gLandTertiaryArmyUnit = cUnitTypeWarDog;
      //gLandTertiaryArmyUnit = cUnitTypeMusketeer;
      //gLandTertiaryArmyUnit = cUnitTypeSkirmisher;
      //gLandTertiaryArmyUnit = cUnitTypeDragoon;
      //gLandPrimaryArmyUnit = cUnitTypeRodelero;//  + cUnitTypePikeman + cUnitTypeLancer + cUnitTypeHussar;
      //gLandSecondaryArmyUnit = cUnitTypeLancer;//  + cUnitTypePikeman + cUnitTypeLancer + cUnitTypeHussar;
      //gLandTertiaryArmyUnit = cUnitTypePikeman;//  + cUnitTypePikeman + cUnitTypeLancer + cUnitTypeHussar;
   	  if (kbGetAge() >= cAge4)
	  gAbstractArtilleryUnit = cUnitTypexpHorseArtillery;
	  else
	  gAbstractArtilleryUnit = cUnitTypeFalconet;
   }
   if (kbGetCiv() == cCivPortuguese)
   {
      gLandPrimaryArmyUnit = cUnitTypeMusketeer;
      gLandSecondaryArmyUnit = cUnitTypeMusketeer;
      gLandTertiaryArmyUnit = cUnitTypeHussar;
      //gLandPrimaryArmyUnit = cUnitTypeCacadore;
      //gLandPrimaryArmyUnit = cUnitTypeDragoon;
      //gLandPrimaryArmyUnit = cUnitTypeHussar;
      //gLandPrimaryArmyUnit = cUnitTypeOrganGun;
      //gLandSecondaryArmyUnit = cUnitTypeMusketeer;
      //gLandSecondaryArmyUnit = cUnitTypeCacadore;
      //gLandSecondaryArmyUnit = cUnitTypeDragoon;
      //gLandSecondaryArmyUnit = cUnitTypeHussar;
      //gLandSecondaryArmyUnit = cUnitTypeOrganGun;
      //gLandTertiaryArmyUnit = cUnitTypeMusketeer;
      //gLandTertiaryArmyUnit = cUnitTypeCacadore;
      //gLandTertiaryArmyUnit = cUnitTypeDragoon;
      //gLandTertiaryArmyUnit = cUnitTypeHussar;
      //gLandTertiaryArmyUnit = cUnitTypeOrganGun;
      //gLandPrimaryArmyUnit = cUnitTypeMusketeer; // + cUnitTypeCacadore + cUnitTypeDragoon + cUnitTypeOrganGun + cUnitTypeHussar;
      //gLandSecondaryArmyUnit = cUnitTypeCacadore; // + cUnitTypeCacadore + cUnitTypeDragoon + cUnitTypeOrganGun + cUnitTypeHussar;
      //gLandTertiaryArmyUnit = cUnitTypeDragoon; // + cUnitTypeCacadore + cUnitTypeDragoon + cUnitTypeOrganGun + cUnitTypeHussar;
	  if (kbGetAge() >= cAge4)
	  gAbstractArtilleryUnit = cUnitTypexpHorseArtillery;
	  else
	  gAbstractArtilleryUnit = cUnitTypeOrganGun;
   }
   if (kbGetCiv() == cCivDutch)
   {
      gLandPrimaryArmyUnit = cUnitTypeSkirmisher;
      gLandSecondaryArmyUnit = cUnitTypeSkirmisher;
      gLandTertiaryArmyUnit = cUnitTypeHussar;
      //gLandPrimaryArmyUnit = cUnitTypeHussar;
      //gLandPrimaryArmyUnit = cUnitTypeRuyter;
      //gLandPrimaryArmyUnit = cUnitTypeHalberdier;
      //gLandPrimaryArmyUnit = cUnitTypexpHorseArtillery;
      //gLandPrimaryArmyUnit = cUnitTypeFalconet;
      //gLandPrimaryArmyUnit = cUnitTypeGrenadier;
      //gLandSecondaryArmyUnit = cUnitTypeSkirmisher;
      //gLandSecondaryArmyUnit = cUnitTypeHussar;
      //gLandSecondaryArmyUnit = cUnitTypeRuyter;
      //gLandSecondaryArmyUnit = cUnitTypeHalberdier;
      //gLandSecondaryArmyUnit = cUnitTypexpHorseArtillery;
      //gLandSecondaryArmyUnit = cUnitTypeFalconet;
      //gLandSecondaryArmyUnit = cUnitTypeGrenadier;
      //gLandTertiaryArmyUnit = cUnitTypeSkirmisher;
      //gLandTertiaryArmyUnit = cUnitTypeHussar;
      //gLandTertiaryArmyUnit = cUnitTypeRuyter;
      //gLandTertiaryArmyUnit = cUnitTypeHalberdier;
      //gLandTertiaryArmyUnit = cUnitTypexpHorseArtillery;
      //gLandTertiaryArmyUnit = cUnitTypeFalconet;
      //gLandTertiaryArmyUnit = cUnitTypeGrenadier;
      //gLandPrimaryArmyUnit = cUnitTypeSkirmisher;//  + cUnitTypeRuyter + cUnitTypeHussar;
      //gLandSecondaryArmyUnit = cUnitTypeRuyter;//  + cUnitTypeRuyter + cUnitTypeHussar;
      //gLandTertiaryArmyUnit = cUnitTypeHussar;//  + cUnitTypeRuyter + cUnitTypeHussar;
      gGalleonUnit = cUnitTypeFluyt;
   	  if (kbGetAge() >= cAge4)
	  gAbstractArtilleryUnit = cUnitTypexpHorseArtillery;
	  else
	  gAbstractArtilleryUnit = cUnitTypeFalconet;
   }
   if (kbGetCiv() == cCivRussians)
   {
      gLandPrimaryArmyUnit = cUnitTypeMusketeer;
      gLandSecondaryArmyUnit = cUnitTypeStrelet;
      gLandTertiaryArmyUnit = cUnitTypeCossack;
      //gLandPrimaryArmyUnit = cUnitTypeStrelet;
      //gLandPrimaryArmyUnit = cUnitTypeCossack;
      //gLandPrimaryArmyUnit = cUnitTypeMusketeer;
      //gLandPrimaryArmyUnit = cUnitTypeGrenadier;
      //gLandPrimaryArmyUnit = cUnitTypeCavalryArcher;
      //gLandSecondaryArmyUnit = cUnitTypeStrelet;
      //gLandSecondaryArmyUnit = cUnitTypeCossack;
      //gLandSecondaryArmyUnit = cUnitTypeMusketeer;
      //gLandSecondaryArmyUnit = cUnitTypeGrenadier;
      //gLandSecondaryArmyUnit = cUnitTypeCavalryArcher;
      //gLandTertiaryArmyUnit = cUnitTypeStrelet;
      //gLandTertiaryArmyUnit = cUnitTypeCossack;
      //gLandTertiaryArmyUnit = cUnitTypeMusketeer;
      //gLandTertiaryArmyUnit = cUnitTypeGrenadier;
      //gLandTertiaryArmyUnit = cUnitTypeCavalryArcher;
      //gLandPrimaryArmyUnit = cUnitTypeStrelet;//  + cUnitTypeCossack + cUnitTypeMusketeer;
      //gLandSecondaryArmyUnit = cUnitTypeCossack;//  + cUnitTypeCossack + cUnitTypeMusketeer;
      //gLandTertiaryArmyUnit = cUnitTypeMusketeer;//  + cUnitTypeCossack + cUnitTypeMusketeer;
      gTowerUnit = cUnitTypeBlockhouse;
      gBarracksUnit = gTowerUnit;
   	  if (kbGetAge() >= cAge4)
	  gAbstractArtilleryUnit = cUnitTypexpHorseArtillery;
	  else
	  gAbstractArtilleryUnit = cUnitTypeFalconet;
   }
   if (kbGetCiv() == cCivOttomans)
   {
      gLandPrimaryArmyUnit = cUnitTypeHussar;
      gLandSecondaryArmyUnit = cUnitTypeHussar;
      gLandTertiaryArmyUnit = cUnitTypeHussar;
      //gLandPrimaryArmyUnit = cUnitTypeAbusGun;
      //gLandPrimaryArmyUnit = cUnitTypeHussar;
      //gLandPrimaryArmyUnit = cUnitTypeCavalryArcher;
      //gLandPrimaryArmyUnit = cUnitTypeGrenadier;
      //gLandSecondaryArmyUnit = cUnitTypeJanissary;
      //gLandSecondaryArmyUnit = cUnitTypeAbusGun;
      //gLandSecondaryArmyUnit = cUnitTypeHussar;
      //gLandSecondaryArmyUnit = cUnitTypeCavalryArcher;
      //gLandSecondaryArmyUnit = cUnitTypeGrenadier;
      //gLandTertiaryArmyUnit = cUnitTypeJanissary;
      //gLandTertiaryArmyUnit = cUnitTypeAbusGun;
      //gLandTertiaryArmyUnit = cUnitTypeHussar;
      //gLandTertiaryArmyUnit = cUnitTypeCavalryArcher;
      //gLandTertiaryArmyUnit = cUnitTypeGrenadier;
      //gLandPrimaryArmyUnit = cUnitTypeJanissary;//  + cUnitTypeAbusGun + cUnitTypeHussar;
      //gLandSecondaryArmyUnit = cUnitTypeAbusGun;//  + cUnitTypeAbusGun + cUnitTypeHussar;
      //gLandTertiaryArmyUnit = cUnitTypeHussar;//  + cUnitTypeAbusGun + cUnitTypeHussar; 
      gCaravelUnit = cUnitTypeGalley;
   	  if (kbGetAge() >= cAge4)
	  gAbstractArtilleryUnit = cUnitTypexpHorseArtillery;
	  else
	  gAbstractArtilleryUnit = cUnitTypeFalconet;
   }
   if (kbGetCiv() == cCivXPAztec)   
   {
      gLandPrimaryArmyUnit = cUnitTypexpMacehualtin;
      gLandSecondaryArmyUnit = cUnitTypexpMacehualtin;
      gLandTertiaryArmyUnit = cUnitTypexpMacehualtin;
      //gLandPrimaryArmyUnit = cUnitTypexpJaguarKnight;
      //gLandPrimaryArmyUnit = cUnitTypexpCoyoteMan;
      //gLandPrimaryArmyUnit = cUnitTypexpMacehualtin;
      //gLandPrimaryArmyUnit = cUnitTypexpPumaMan;
      //gLandPrimaryArmyUnit = cUnitTypexpEagleKnight;
      //gLandSecondaryArmyUnit = cUnitTypexpJaguarKnight;
      //gLandSecondaryArmyUnit = cUnitTypexpCoyoteMan;
      //gLandSecondaryArmyUnit = cUnitTypexpMacehualtin;
      //gLandSecondaryArmyUnit = cUnitTypexpPumaMan;
      //gLandSecondaryArmyUnit = cUnitTypexpEagleKnight;
      //gLandTertiaryArmyUnit = cUnitTypexpJaguarKnight;
      //gLandTertiaryArmyUnit = cUnitTypexpCoyoteMan;
      //gLandTertiaryArmyUnit = cUnitTypexpMacehualtin;
      //gLandTertiaryArmyUnit = cUnitTypexpPumaMan;
      //gLandTertiaryArmyUnit = cUnitTypexpEagleKnight;
      //gLandPrimaryArmyUnit = cUnitTypexpJaguarKnight;//  + cUnitTypexpCoyoteMan + cUnitTypexpMacehualtin;
      //gLandSecondaryArmyUnit = cUnitTypexpCoyoteMan;//  + cUnitTypexpCoyoteMan + cUnitTypexpMacehualtin;
      //gLandTertiaryArmyUnit = cUnitTypexpMacehualtin;//  + cUnitTypexpCoyoteMan + cUnitTypexpMacehualtin;
      gAbstractArtilleryUnit = cUnitTypexpArrowKnight;
	  gAbstractCounterArtilleryUnit = cUnitTypexpArrowKnight;
      gSiegeWeaponUnit = -1;
      gBarracksUnit = cUnitTypeWarHut;
      gTowerUnit = cUnitTypeWarHut;
      gTowerWagonUnit = cUnitTypeWarHutTravois;
      //gTowerUnit = cUnitTypeNoblesHut; 
      gExplorerUnit = cUnitTypexpAztecWarchief;
      //gCaravelUnit = cUnitTypeCanoe;      
      gGalleonUnit = cUnitTypexpWarCanoe;
      gFrigateUnit = cUnitTypexpTlalocCanoe;
	  gAbstractAssassinUnit = -1;
   }   
   if (kbGetCiv() == cCivXPSioux)
   {  
      //gLandPrimaryArmyUnit = cUnitTypexpAxeRider;
      //gLandSecondaryArmyUnit = cUnitTypexpAxeRider;
      //gLandTertiaryArmyUnit = cUnitTypexpAxeRider;
      gLandPrimaryArmyUnit = cUnitTypexpBowRider;
      //gLandPrimaryArmyUnit = cUnitTypexpRifleRider;
      //gLandPrimaryArmyUnit = cUnitTypexpCoupRider;
      //gLandPrimaryArmyUnit = cUnitTypexpWarRifle;
      //gLandSecondaryArmyUnit = cUnitTypexpAxeRider;
      gLandSecondaryArmyUnit = cUnitTypexpBowRider;
      //gLandSecondaryArmyUnit = cUnitTypexpRifleRider;
      //gLandSecondaryArmyUnit = cUnitTypexpCoupRider;
      //gLandSecondaryArmyUnit = cUnitTypexpWarRifle;
      //gLandTertiaryArmyUnit = cUnitTypexpAxeRider;
      gLandTertiaryArmyUnit = cUnitTypexpBowRider;
      //gLandTertiaryArmyUnit = cUnitTypexpRifleRider;
      //gLandTertiaryArmyUnit = cUnitTypexpCoupRider;
      //gLandTertiaryArmyUnit = cUnitTypexpWarRifle;
      //gLandPrimaryArmyUnit = cUnitTypexpAxeRider;//  + cUnitTypexpBowRider + cUnitTypexpRifleRider;
      //gLandSecondaryArmyUnit = cUnitTypexpBowRider;//  + cUnitTypexpBowRider + cUnitTypexpRifleRider;
      //gLandTertiaryArmyUnit = cUnitTypexpRifleRider;//  + cUnitTypexpBowRider + cUnitTypexpRifleRider;
      gAbstractArtilleryUnit = -1;
	  gAbstractCounterArtilleryUnit = -1;
      gSiegeWeaponUnit = -1;
      //gTowerUnit = cUnitTypeTeepee;
      gStableUnit = cUnitTypeCorral;
      gBarracksUnit = cUnitTypeWarHut;
      gTowerUnit = cUnitTypeWarHut;
      gTowerWagonUnit = cUnitTypeWarHutTravois;
      gExplorerUnit = cUnitTypexpLakotaWarchief;
	  gAbstractAssassinUnit = -1;
      //gCaravelUnit = cUnitTypeCanoe;      
      gGalleonUnit = cUnitTypexpWarCanoe;
   }
   if ( kbGetCiv() == cCivXPIroquois )
   {  
      gLandPrimaryArmyUnit = cUnitTypexpTomahawk;
      gLandSecondaryArmyUnit = cUnitTypexpTomahawk;
      gLandTertiaryArmyUnit = cUnitTypexpTomahawk;
      //gLandPrimaryArmyUnit = cUnitTypexpMusketWarrior;
      //gLandPrimaryArmyUnit = cUnitTypexpMusketRider;
      //gLandPrimaryArmyUnit = cUnitTypexpMantlet;
      //gLandPrimaryArmyUnit = cUnitTypexpHorseman;
      //gLandSecondaryArmyUnit = cUnitTypexpTomahawk;
      //gLandSecondaryArmyUnit = cUnitTypexpMusketWarrior;
      //gLandSecondaryArmyUnit = cUnitTypexpMusketRider;
      //gLandSecondaryArmyUnit = cUnitTypexpMantlet;
      //gLandSecondaryArmyUnit = cUnitTypexpHorseman;
      //gLandTertiaryArmyUnit = cUnitTypexpTomahawk;
      //gLandTertiaryArmyUnit = cUnitTypexpMusketWarrior;
      //gLandTertiaryArmyUnit = cUnitTypexpMusketRider;
      //gLandTertiaryArmyUnit = cUnitTypexpMantlet;
      //gLandTertiaryArmyUnit = cUnitTypexpHorseman;
      //gLandPrimaryArmyUnit = cUnitTypexpTomahawk;//  + cUnitTypexpAenna + cUnitTypexpWarRifle + cUnitTypexpMantlet;
      //gLandSecondaryArmyUnit = cUnitTypexpMantlet;//  + cUnitTypexpAenna + cUnitTypexpWarRifle + cUnitTypexpMantlet;
      //gLandTertiaryArmyUnit = cUnitTypexpMusketWarrior;//  + cUnitTypexpAenna + cUnitTypexpWarRifle + cUnitTypexpMantlet; 
      gAbstractArtilleryUnit = cUnitTypexpLightCannon;
	  gAbstractCounterArtilleryUnit = cUnitTypexpLightCannon;
      //gSiegeWeaponUnit = cUnitTypexpLightCannon;
      gStableUnit = cUnitTypeCorral;
      gBarracksUnit = cUnitTypeWarHut;    
      gTowerUnit = cUnitTypeWarHut;            
      gTowerWagonUnit = cUnitTypeWarHutTravois;
      gExplorerUnit = cUnitTypexpIroquoisWarChief;
      gSiegeWeaponUnit = cUnitTypexpRam;
      //gCaravelUnit = cUnitTypeCanoe;      
      gGalleonUnit = cUnitTypexpWarCanoe;
	  gAbstractAssassinUnit = -1;
   }
   if ( (kbGetCiv() == cCivChinese) || (kbGetCiv() == cCivSPCChinese) )
   {
      gLandPrimaryArmyUnit = cUnitTypeypStandardArmy; // + cUnitTypeypTerritorialArmy + cUnitTypeypForbiddenArmy;
      gLandSecondaryArmyUnit = cUnitTypeypStandardArmy; // + cUnitTypeypOldHanArmy + cUnitTypeypForbiddenArmy;
      gLandTertiaryArmyUnit = cUnitTypeypStandardArmy; // + cUnitTypeypTerritorialArmy + cUnitTypeypOldHanArmy;
      //gLandPrimaryArmyUnit = cUnitTypeypTerritorialArmy;
      //gLandSecondaryArmyUnit = cUnitTypeypTerritorialArmy;
      //gLandTertiaryArmyUnit = cUnitTypeypTerritorialArmy; 
      //gLandSecondaryArmyUnit = cUnitTypeypTerritorialArmy; // + cUnitTypeypOldHanArmy + cUnitTypeypForbiddenArmy;
      //gLandTertiaryArmyUnit = cUnitTypeypForbiddenArmy; // + cUnitTypeypTerritorialArmy + cUnitTypeypOldHanArmy;
      gAbstractArtilleryUnit = cUnitTypeypFlameThrower;
      gBarracksUnit = cUnitTypeypWarAcademy;      
      gStableUnit = -1;
      gTowerUnit = cUnitTypeypCastle;
      gTowerWagonUnit = cUnitTypeYPCastleWagon;  
      gExplorerUnit = cUnitTypeAbstractChineseMonk; 
	  gAbstractCounterArtilleryUnit = cUnitTypeypHandMortar;
      //gSiegeWeaponUnit = cUnitTypeypHandMortar;
      gCaravelUnit = cUnitTypeypFireship;
      gGalleonUnit = cUnitTypeypFuchuan;
      gFrigateUnit = cUnitTypeypWarJunk;     
	  gAbstractAssassinUnit = -1;
   }
   if ( (kbGetCiv() == cCivJapanese) || (kbGetCiv() == cCivSPCJapanese) || (kbGetCiv() == cCivSPCJapaneseEnemy) )
   {
      gLandPrimaryArmyUnit = cUnitTypeypAshigaru;
      gLandSecondaryArmyUnit = cUnitTypeypAshigaru;
      gLandTertiaryArmyUnit = cUnitTypeypAshigaru;
      //gLandPrimaryArmyUnit = cUnitTypeypKensei;
      //gLandPrimaryArmyUnit = cUnitTypeypAshigaru;
      //gLandPrimaryArmyUnit = cUnitTypeypYumi;
      //gLandPrimaryArmyUnit = cUnitTypeypYabusame;
      //gLandPrimaryArmyUnit = cUnitTypeypNaginataRider;
      //gLandSecondaryArmyUnit = cUnitTypeypKensei;
      //gLandSecondaryArmyUnit = cUnitTypeypAshigaru;
      //gLandSecondaryArmyUnit = cUnitTypeypYumi;
      //gLandSecondaryArmyUnit = cUnitTypeypYabusame;
      //gLandSecondaryArmyUnit = cUnitTypeypNaginataRider;
      //gLandTertiaryArmyUnit = cUnitTypeypKensei;
      //gLandTertiaryArmyUnit = cUnitTypeypAshigaru;
      //gLandTertiaryArmyUnit = cUnitTypeypYumi;
      //gLandTertiaryArmyUnit = cUnitTypeypYabusame;
      //gLandTertiaryArmyUnit = cUnitTypeypNaginataRider;
      //gLandPrimaryArmyUnit = cUnitTypeypAshigaru;//  + cUnitTypeypKensei + cUnitTypeypYumi;
      //gLandSecondaryArmyUnit = cUnitTypeypNaginataRider;//  + cUnitTypeypKensei + cUnitTypeypYumi;
      //gLandTertiaryArmyUnit = cUnitTypeypYumi;//  + cUnitTypeypKensei + cUnitTypeypYumi; 
      gAbstractArtilleryUnit = cUnitTypeypFlamingArrow;
	  gAbstractCounterArtilleryUnit = cUnitTypeypFlamingArrow;
      gBarracksUnit = cUnitTypeypBarracksJapanese;
      gStableUnit = cUnitTypeypStableJapanese;
      gTowerUnit = cUnitTypeypCastle;
      gTowerWagonUnit = cUnitTypeYPCastleWagon;      
      gExplorerUnit = cUnitTypeAbstractJapaneseMonk;
      gSiegeWeaponUnit = cUnitTypeypMorutaru;
      gCaravelUnit = cUnitTypeypFune;
      gGalleonUnit = cUnitTypeypAtakabune;
      gFrigateUnit = cUnitTypeypTekkousen;  
   }
   if ( (kbGetCiv() == cCivIndians) || (kbGetCiv() == cCivSPCIndians) )
   {
      gLandPrimaryArmyUnit = cUnitTypeypSepoy;
      gLandSecondaryArmyUnit = cUnitTypeypSepoy;
      gLandTertiaryArmyUnit = cUnitTypeypSepoy;
      //gLandPrimaryArmyUnit = cUnitTypeAbstractGurkha;
      //gLandPrimaryArmyUnit = cUnitTypeAbstractRajput;
      //gLandPrimaryArmyUnit = cUnitTypeAbstractSowar;
      //gLandPrimaryArmyUnit = cUnitTypeAbstractZamburak;
      //gLandPrimaryArmyUnit = cUnitTypeAbstractHowdah;
      //gLandPrimaryArmyUnit = cUnitTypeAbstractMahout;
      //gLandSecondaryArmyUnit = cUnitTypeypSepoy;
      //gLandSecondaryArmyUnit = cUnitTypeypNatMercGurkha;
      //gLandSecondaryArmyUnit = cUnitTypeAbstractRajput;
      //gLandSecondaryArmyUnit = cUnitTypeAbstractSowar;
      //gLandSecondaryArmyUnit = cUnitTypeAbstractZamburak;
      //gLandSecondaryArmyUnit = cUnitTypeAbstractHowdah;
      //gLandSecondaryArmyUnit = cUnitTypeAbstractMahout;
      //gLandTertiaryArmyUnit = cUnitTypeypSepoy;
      //gLandTertiaryArmyUnit = cUnitTypeAbstractGurkha;
      //gLandTertiaryArmyUnit = cUnitTypeAbstractRajput;
      //gLandTertiaryArmyUnit = cUnitTypeAbstractSowar;
      //gLandTertiaryArmyUnit = cUnitTypeAbstractZamburak;
      //gLandTertiaryArmyUnit = cUnitTypeAbstractHowdah;
      //gLandTertiaryArmyUnit = cUnitTypeAbstractMahout;
      //gLandPrimaryArmyUnit = cUnitTypeAbstractSepoy;//  + cUnitTypeAbstractGurkha + cUnitTypeAbstractSowar;
      //gLandSecondaryArmyUnit = cUnitTypeAbstractGurkha;//  + cUnitTypeAbstractGurkha + cUnitTypeAbstractSowar;
      //gLandTertiaryArmyUnit = cUnitTypeAbstractSowar;//  + cUnitTypeAbstractGurkha + cUnitTypeAbstractSowar; 
      gAbstractArtilleryUnit = -1;
      gBarracksUnit = cUnitTypeYPBarracksIndian;
      gStableUnit = cUnitTypeypCaravanserai;
      gTowerUnit = cUnitTypeypCastle;
      gTowerWagonUnit = cUnitTypeYPCastleWagon;
      gExplorerUnit = cUnitTypeAbstractIndianMonk;
	  gAbstractCounterArtilleryUnit = cUnitTypeypSiegeElephant;
      //gSiegeWeaponUnit = cUnitTypeypSiegeElephant;     
	  gAbstractAssassinUnit = -1; 
   }
   if (kbGetCiv() == cCivDESwedish)
   {
      gLandPrimaryArmyUnit = cUnitTypedeCarolean;
      gLandSecondaryArmyUnit = cUnitTypedeCarolean;
      gLandTertiaryArmyUnit =  cUnitTypeHussar;
	  //gAbstractArtilleryUnit = cUnitTypedeLeatherCannon;
   }
   if (kbGetCiv() == cCivDEInca)
   {
    /*if ((kbGetAge() > cAge2) || (kbTechGetStatus(cTechDEHCEarlyKallanka) == cTechStatusActive))
	  {      
	  gLandPrimaryArmyUnit = cUnitTypedeSlinger; 
      gLandSecondaryArmyUnit = cUnitTypedeSlinger;
      gLandTertiaryArmyUnit = cUnitTypedeSlinger;
	  }
	  else
	  {
      gLandPrimaryArmyUnit = cUnitTypedeJungleBowman;
      gLandSecondaryArmyUnit = cUnitTypedeJungleBowman;
      gLandTertiaryArmyUnit = cUnitTypedeJungleBowman;
	  }*/
      gLandPrimaryArmyUnit = cUnitTypedeJungleBowman;
      gLandSecondaryArmyUnit = cUnitTypedeJungleBowman;
      gLandTertiaryArmyUnit = cUnitTypedeIncaRunner;
	  gAbstractCounterArtilleryUnit = cUnitTypedeSlinger;
	  //gSiegeWeaponUnit = cUnitTypedeSlinger;
	  gSiegeWeaponUnit = -1;
	  gAbstractArtilleryUnit = -1;
	  gAbstractAssassinUnit = -1;
      gStableUnit = -1;
      gBarracksUnit = cUnitTypeWarHut;
      gTowerUnit = cUnitTypeWarHut;
   }
   if (kbGetCiv() == cCivDEAmericans)
   {
      gLandPrimaryArmyUnit = cUnitTypedeRegular;
      gLandSecondaryArmyUnit = cUnitTypedeRegular;
      gLandTertiaryArmyUnit =  cUnitTypeHussar;
      gAbstractArtilleryUnit = cUnitTypexpGatlingGun;
	  //gAbstractArtilleryUnit = cUnitTypedeLeatherCannon;
   }
   if (kbGetCiv() == cCivDEMexicans)
   {
      gLandPrimaryArmyUnit = cUnitTypedeEmboscador;
      gLandSecondaryArmyUnit = cUnitTypedeChinaco;
      gLandTertiaryArmyUnit =  cUnitTypedeSoldado;
      //gAbstractArtilleryUnit = cUnitTypexpGatlingGun;
	  //gAbstractArtilleryUnit = cUnitTypedeLeatherCannon;
   }
   if (kbGetCiv() == cCivDEEthiopians)
   {
      gLandPrimaryArmyUnit = cUnitTypedeJavelinRider;
      gLandSecondaryArmyUnit = cUnitTypedeJavelinRider;
      gLandTertiaryArmyUnit =  cUnitTypedeJavelinRider;
	  gAbstractArtilleryUnit = cUnitTypeFalconet;
   }
   if (kbGetCiv() == cCivDEHausa)
   {
      gLandPrimaryArmyUnit = cUnitTypedeJavelinRider;
      gLandSecondaryArmyUnit = cUnitTypedeJavelinRider;
      gLandTertiaryArmyUnit =  cUnitTypedeJavelinRider;
	  gAbstractArtilleryUnit = cUnitTypeFalconet;
   }
}

//==============================================================================
// init...Called once we have units in the new world.
//==============================================================================
void init(void)
{
   // init Econ and Military stuff.
   initEcon();
   initMil();
   
   // When economy or military is set on plans, the plan's desired priority will be multiplied by either 
   // of the percentage which is the actual priority used for plan update order and unit assignment.
   // Us setting this to 1.0 basically means we do not use the aiPlanSetMilitary mechanic at all.
   aiSetEconomyPercentage(1.0);
   aiSetMilitaryPercentage(1.0);

   if ((gStartMode == cStartModeScenarioWagon) || (gStartMode == cStartModeLandWagon))
   {
      // If this is a scenario we should use the AIStart object's position for the gTCSearchVector.
      if (gSPC == true)
      {
         int aiStart = getUnit(cUnitTypeAIStart, cMyID, cUnitStateAny);
         if (aiStart >= 0)
         {
            gTCSearchVector = kbUnitGetPosition(aiStart);
            debugSetup("Using aiStart object at " + gTCSearchVector + " to start TC placement search");
         }
      }
      else
      {
         // Use the Covered Wagon position for the gTCSearchVector.
         vector coveredWagonPos = kbUnitGetPosition(getUnit(cUnitTypeCoveredWagon, cMyID, cUnitStateAlive));
         vector normalVec = xsVectorNormalize(kbGetMapCenter() - coveredWagonPos);
         int offset = 40;
         gTCSearchVector = coveredWagonPos + (normalVec * offset);
     
         while (kbAreaGroupGetIDByPosition(gTCSearchVector) != kbAreaGroupGetIDByPosition(coveredWagonPos))
         {
            // Try for a goto point 40 meters toward center.  Fall back 5m at a time if that's on another continent/ocean.
            // If under 5, we'll take it.
            offset = offset - 5;
            gTCSearchVector = coveredWagonPos + (normalVec * offset);
            if (offset < 5)
            {
               break;
            }
         }
      }
      
      debugSetup("Creating startup Town Center build plan");
      // Make a town center, pri 100, econ, main base, 1 builder.
      int buildPlan = aiPlanCreate("Startup TC Build plan", cPlanBuild);
      // What to build
      aiPlanSetVariableInt(buildPlan, cBuildPlanBuildingTypeID, 0, cUnitTypeTownCenter);
      // Priority.
      aiPlanSetDesiredPriority(buildPlan, 100);
      // Builders.
      aiPlanAddUnitType(buildPlan, cUnitTypeCoveredWagon, 1, 1, 1);

      // Instead of base ID or areas, use a center position and falloff.
      aiPlanSetVariableVector(buildPlan, cBuildPlanCenterPosition, 0, gTCSearchVector);
      aiPlanSetVariableFloat(buildPlan, cBuildPlanCenterPositionDistance, 0, 40.00);

      // Add position influences for trees, gold
      aiPlanSetNumberVariableValues(buildPlan, cBuildPlanInfluenceUnitTypeID, 3, true);
      aiPlanSetNumberVariableValues(buildPlan, cBuildPlanInfluenceUnitDistance, 3, true);
      aiPlanSetNumberVariableValues(buildPlan, cBuildPlanInfluenceUnitValue, 3, true);
      aiPlanSetNumberVariableValues(buildPlan, cBuildPlanInfluenceUnitFalloff, 3, true);
      aiPlanSetVariableInt(buildPlan, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypeWood);
      aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluenceUnitDistance, 0, 30.0);           // 30m range.
      aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluenceUnitValue, 0, 10.0);              // 10 points per tree
      aiPlanSetVariableInt(buildPlan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffLinear); // Linear slope falloff
      aiPlanSetVariableInt(buildPlan, cBuildPlanInfluenceUnitTypeID, 1, cUnitTypeMine);
      aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluenceUnitDistance, 1, 50.0);           // 50 meter range for gold
      aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluenceUnitValue, 1, 300.0);             // 300 points each
      aiPlanSetVariableInt(buildPlan, cBuildPlanInfluenceUnitFalloff, 1, cBPIFalloffLinear); // Linear slope falloff
      aiPlanSetVariableInt(buildPlan, cBuildPlanInfluenceUnitTypeID, 2, cUnitTypeMine);
      aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluenceUnitDistance, 2, 20.0);  // 20 meter inhibition to keep some space                                             
      aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluenceUnitValue, 2, -300.0); // -300 points each
      aiPlanSetVariableInt(buildPlan, cBuildPlanInfluenceUnitFalloff, 2, cBPIFalloffNone); // Cliff falloff

      // Two position weights
      aiPlanSetNumberVariableValues(buildPlan, cBuildPlanInfluencePosition, 2, true);
      aiPlanSetNumberVariableValues(buildPlan, cBuildPlanInfluencePositionDistance, 2, true);
      aiPlanSetNumberVariableValues(buildPlan, cBuildPlanInfluencePositionValue, 2, true);
      aiPlanSetNumberVariableValues(buildPlan, cBuildPlanInfluencePositionFalloff, 2, true);

      // Give it a positive but wide-range prefernce for the search area, and a more intense but smaller negative to
      // avoid the landing area. Weight it to prefer the general starting neighborhood
      aiPlanSetVariableVector(buildPlan, cBuildPlanInfluencePosition, 0, gTCSearchVector);       // Focus on vec.
      aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluencePositionDistance, 0, 200.0);          // 200m range.
      aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluencePositionValue, 0, 300.0);             // 300 points max
      aiPlanSetVariableInt(buildPlan, cBuildPlanInfluencePositionFalloff, 0, cBPIFalloffLinear); // Linear slope falloff

      // Add negative weight to avoid initial drop-off beach area
      aiPlanSetVariableVector(buildPlan, cBuildPlanInfluencePosition, 1,
         kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID))); // Position influence for landing position
      aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluencePositionDistance, 1, 50.0);           // Smaller, 50m range.
      aiPlanSetVariableFloat(buildPlan, cBuildPlanInfluencePositionValue, 1, -400.0);            // -400 points max
      aiPlanSetVariableInt(buildPlan, cBuildPlanInfluencePositionFalloff, 1, cBPIFalloffLinear); // Linear slope falloff
      // This combo will make it dislike the immediate landing (-100), score +25 at 50m, score +150 at 100m, then
      // gradually fade to +0 at 200m.

      // Wait to activate TC build plan, to allow adequate exploration
      gTCBuildPlanID = buildPlan; // Save in a global var so the rule can access it.
      if (cvOkToTaunt == true)
      {
         aiPlanSetEventHandler(buildPlan, cPlanEventStateChange, "tcPlacedEventHandler");
      }
      xsEnableRule("tcBuildPlanDelay");
   }
   
   // Due to a bug (or perhaps hack) in the Legacy game code, aiHCDeckAddCardToDeck() fails to add cards to the
   // AI's deck in SPC games. As a consequence, the game always reports 0 cards in the deck, and the AI does not
   // play any HC cards in Campaigns or Scenarios. The same behaviour was carried forward to the TWC and TAD expansions.
   // This bug was fixed in the DE version, so the AI can and will play cards in SPC games. Obviously this has a
   // huge impact on the behaviour and difficulty. Therefore, in order to preserve the legacy AI behaviour, we
   // default cvOkToBuildDeck to false in SPC games. This can be overwritten by the loader though.
   if (cvOkToBuildDeck == true)
   {
      // Shipment arrive handler, called when we've successfully sent a shipment.
      aiSetHandler("transportShipmentArrive", cXSHomeCityTransportArriveHandler);
      // This handler runs when you have a shipment available in the home city, decide which card to send.
      aiSetHandler("shipGrantedHandler", cXSShipResourceGranted);
      
      xsEnableRule("buyCards");
      xsEnableRule("extraShipMonitor");
   }
   
   if (cvOkToTaunt == true)
   {
      aiCommsAllowChat(true);
      // Send a greeting to allies and enemies
      sendStatement(cPlayerRelationAlly, cAICommPromptToAllyIntro);
      sendStatement(cPlayerRelationEnemy, cAICommPromptToEnemyIntro);
      xsEnableRule("IKnowWhereYouLive");
      xsEnableRule("tcChats");
      xsEnableRule("monitorScores");
      
      // Set up the nugget handler, this is used to send chats when nuggets are collected.
      aiSetHandler("nuggetHandler", cXSNuggetHandler);
   }
   
   if (cvOkToBuild == true)
   {
      xsEnableRule("wagonMonitor");
   }
   
   if (cvOkToResign == true)
   {
      xsEnableRule("ShouldIResign");
      // Set up the resign handler.
      aiSetHandler("resignHandler", cXSResignHandler);
   }

   if (cvOkToExplore == true)
   {
      xsEnableRule("exploreMonitor");
      exploreMonitor(); // Call it once directly so we instantly start with exploring instead of waiting 10 seconds.
      
      if (cMyCiv == cCivDutch)
      {
         xsEnableRule("envoyMonitor");
      }
      if (cMyCiv == cCivDEInca)
      {
         xsEnableRule("chasquiMonitor");
      }
      xsEnableRule("nativeScoutMonitor");
      xsEnableRule("mongolScoutMonitor");
   }
   
   xsEnableRule("townCenterComplete");
   
   postInit(); // All loading screen initialization is done, let loader file change what it wants to.
}

//==============================================================================
/* tcBuildPlanDelay

   Allows delayed activation of the TC build plan, so that the explorer has
   uncovered a good bit of the map before a placement is selected.

   The int gTCBuildPlanID is used to simplify passing of the build plan ID from
   init().
*/
//==============================================================================

rule tcBuildPlanDelay
inactive
minInterval 1
{
   if (xsGetTime() < gTCStartTime)
   {
      return; // Do nothing until game time is beyond 10 seconds
   }

   aiPlanSetActive(gTCBuildPlanID);
   debugBuildings("Activating startup Town Center build plan " + gTCBuildPlanID);
   xsDisableSelf();
}

//==============================================================================
/* townCenterComplete

   Wait until the Town Center is completed, then start basically everything else the AI does.
   In a start with a TC, this will fire very quickly.
   In a scenario without a TC, we do the best we can.
*/
//==============================================================================
rule townCenterComplete
inactive
minInterval 2
{
   // Let's see if we have a Town Center.
   int townCenterID = getUnit(cUnitTypeTownCenter);

   // If we have no Town Center and it isn't a special scenario where we don't start with a Covered Wagon either
   if ((townCenterID < 0) && (gStartMode != cStartModeScenarioNoTC))
      return;

   debugSetup("New TC is " + townCenterID + " at " + kbUnitGetPosition(townCenterID));

   if (townCenterID >= 0)
   {
      int tcBase = kbUnitGetBaseID(townCenterID);
      gMainBase = kbBaseGetMainID(cMyID);
      debugSetup("TC base is " + tcBase + ", main base is " + gMainBase);
      // We have a TC.  Make sure that the main base exists, and it includes the TC
      if (gMainBase < 0)
      { // We have no main base, create one
         gMainBase = createMainBase(kbUnitGetPosition(townCenterID));
         debugSetup("We had no main base, so we created one: " + gMainBase);
      }
      debugSetup(
          "TC base area group has " + getAreaGroupNumberTiles(kbAreaGroupGetIDByPosition(kbUnitGetPosition(townCenterID))) +
          " number of tiles");
      tcBase = kbUnitGetBaseID(townCenterID); // in case base ID just changed
      if (tcBase != gMainBase)
      {
         debugSetup(" TC " + townCenterID + " is not in the main base (" + gMainBase + ".");
         debugSetup(" Setting base " + gMainBase + " to non-main, setting base " + tcBase + " to main");
         kbBaseSetMain(cMyID, gMainBase, false);
         aiRemoveResourceBreakdown(cResourceFood, cAIResourceSubTypeEasy, gMainBase);
         aiRemoveResourceBreakdown(cResourceFood, cAIResourceSubTypeHunt, gMainBase);
         aiRemoveResourceBreakdown(cResourceFood, cAIResourceSubTypeHerdable, gMainBase);
         aiRemoveResourceBreakdown(cResourceFood, cAIResourceSubTypeHuntAggressive, gMainBase);
         aiRemoveResourceBreakdown(cResourceFood, cAIResourceSubTypeFish, gMainBase);
         aiRemoveResourceBreakdown(cResourceFood, cAIResourceSubTypeFarm, gMainBase);
         aiRemoveResourceBreakdown(cResourceWood, cAIResourceSubTypeEasy, gMainBase);
         aiRemoveResourceBreakdown(cResourceGold, cAIResourceSubTypeEasy, gMainBase);
         kbBaseSetMain(cMyID, tcBase, true);
         gMainBase = tcBase;
      }
      // Setup initial base distance.
      kbBaseSetPositionAndDistance(cMyID, gMainBase, kbBaseGetLocation(cMyID, gMainBase), 40.0);
   }
   else
   {
      debugSetup("No TC, leaving main base as it is");
   }

   kbBaseSetMaximumResourceDistance(cMyID, kbBaseGetMainID(cMyID), 80.0); // down from 150.

   // Town center found, start doing a bunch of activations.
   
   xsEnableRuleGroup("tcComplete");
   /*
      repairManager
      age2Monitor
      crateMonitor
      updateResourceBreakdowns
      reInitGatherers
      ageUpgradeMonitor
      econUpgrades
   */
   
   // Start exploring on water.
   if (gStartOnDifferentIslands == true)
   {
      createWaterExplorePlan();
   }

   if ((cvOkToFish == true) &&
       (gGoodFishingMap == true))
   {
      xsEnableRule("startFishing");
   }
   
   if (aiIsMonopolyAllowed() == true)
   {
      xsEnableRule("monopolyManager");
      
      // Handler when a player starts the monopoly victory timer.
      aiSetHandler("monopolyStartHandler", cXSMonopolyStartHandler);
   
      // And when a monopoly timer prematurely ends.
      aiSetHandler("monopolyEndHandler", cXSMonopolyEndHandler);
   }
   
   if (aiIsKOTHAllowed() == true)
   {
      // Handler when a player starts the KOTH victory timer.
      aiSetHandler("KOTHVictoryStartHandler", cXSKOTHVictoryStartHandler);
   
      // And when a KOTH timer prematurely ends.
      aiSetHandler("KOTHVictoryEndHandler", cXSKOTHVictoryEndHandler);
   }
   
   // Create the Settler maintain plan with the right amount of Settlers that we want.
   gSettlerMaintainPlan = createSimpleMaintainPlan(gEconUnit,
      cMyCiv == cCivOttomans ? 0 : xsArrayGetInt(gTargetSettlerCounts, kbGetAge()), true, 
      kbBaseGetMainID(cMyID), 1);
   aiPlanSetDesiredResourcePriority(gSettlerMaintainPlan, 70);
   
   if (cvOkToBuild == true)
   {
      xsEnableRule("buildingMonitor");
      xsEnableRule("houseMonitor");
      
      if (((cMyCiv == cCivBritish) || (cMyCiv == cCivJapanese) ||
		  //|| (cMyCiv == cCivChinese) || (cMyCiv == cCivSPCChinese) ||
          (cMyCiv == cCivDESwedish) || (cMyCiv== cCivDEInca)) &&
          (kbGetAge() == cAge1))
      {
         xsEnableRule("extraHouseMonitor");
      }

      wagonMonitor();
      
      if ((cvOkToAllyNatives == true) ||
          (cvOkToClaimTrade == true))
      {
         xsEnableRule("tradingPostMonitor");
      }
      if (cMyCiv == cCivXPIroquois)
      {
         xsEnableRule("xpBuilderMonitor");
      }
   }
   
   if (civIsEuropean() == true)
   {
      xsEnableRule("useLevy");
   }
   
   if (cMyCiv == cCivOttomans)
   {
      xsEnableRule("ottomanMonitor");
      xsEnableRule("toggleAutomaticSettlerSpawning");
   }

   if (civIsNative() == true)
   {
      xsEnableRule("danceMonitor");
      xsEnableRule("useWarParties");
   }
   
   if (civIsAsian() == true)
   {
      xsEnableRule("useAsianLevy");
   }

   if ((cMyCiv != cCivIndians) && (cMyCiv != cCivSPCIndians) &&
       (cMyCiv != cCivJapanese) && (cMyCiv != cCivSPCJapanese) && (cMyCiv == cCivSPCJapaneseEnemy))
   {
      xsEnableRule("slaughterMonitor");
   }

   if ((cMyCiv == cCivJapanese) || (cMyCiv == cCivSPCJapanese) || (cMyCiv == cCivSPCJapaneseEnemy))
   {
      xsEnableRule("shrineTacticMonitor");
      xsEnableRule("forwardShrineManager");
   }

   if (civIsAfrican() == true)
   {
      xsEnableRule("useAfricanLevy");
      xsEnableRule("livestockMarketMonitor");
      if (xsIsRuleEnabled("earlySlaughterMonitor") == false)
      {
         xsEnableRule("earlySlaughterMonitor");
      }
      // Enable house monitor after we sold the first livestock for wood.
      if (gSPC == false)
      {
         xsDisableRule("houseMonitor");
      }
   }

   if (cMyCiv == cCivDEMexicans)
   {
      xsEnableRule("haciendaMonitor");
   }

   if (aiGetGameMode() == cGameModeDeathmatch)
      deathMatchStartupBegin(); // Add a bunch of custom stuff for a DM jump-start.

   if (aiGetGameMode() == cGameModeEconomyMode)
      economyModeMatchStartupBegin(); // Add custom startup settings

   if (kbUnitCount(cMyID, cUnitTypeypDaimyoRegicide, cUnitStateAlive) > 0)
      xsEnableRule("regicideMonitor");

   if (aiTreatyActive() == true)
   {
      int treatyEndTime = aiTreatyGetEnd();
      if (treatyEndTime > 10 * 60 * 1000) // Only do something if the treaty is set to longer than 10 minutes.
      {
         xsEnableRule("treatyCheckStartMakingArmy");
         // Intervals work on whole seconds not on ms.
         xsSetRuleMinInterval("treatyCheckStartMakingArmy", (treatyEndTime - 10 * 60 * 1000) / 1000); 
      }
   }

   if (gStartOnDifferentIslands == true)
   {
      xsEnableRule("navyManager");
      gNavyMode = cNavyModeActive;
      navyManager();
   }
   
   // If we have a negative bias, don't claim trade route TPs until 10 minutes.
   if (btBiasTrade < 0.0)
   {
      gLastClaimTradeMissionTime = xsGetTime() + 600000;
   }
   else
   {
      gLastClaimTradeMissionTime = xsGetTime() - (1.0 - btBiasTrade) * gClaimTradeMissionInterval;
   }
   // Don't claim native TPs until 15 minutes in general.
   gLastClaimNativeMissionTime = xsGetTime() + 900000;
   
   xsDisableSelf();
}

//==============================================================================
// deathMatchStartupBegin, deathMatchStartupMiddle, deathMatchStartupEnd, startup of the Deathmatch Game Mode.
// Make a bunch of changes to get a deathmatch start.
//==============================================================================
void deathMatchStartupBegin(void)
{
   int mainBaseID = kbBaseGetMainID(cMyID);

   // Get houses so we can start training military.
   if (cMyCiv != cCivXPSioux)
      createSimpleBuildPlan(gHouseUnit, 5, 99, true, cEconomyEscrowID, mainBaseID, 1, -1, true);

   // xpBuilder will be assigned to all these houses and ruin the plans, assign villagers manually.
   if (cMyCiv == cCivXPIroquois)
   {
      int planID = -1;
      for (i = 1; < 5)
      {
         planID = aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, gHouseUnit, true, i);
         if (planID != 1)
         {
            aiPlanAddUnitType(planID, cUnitTypeAbstractVillager, 1, 1, 1);
         }
      }
   }

   // Get 1 of each of the main military buildings.
   if (civIsEuropean() == true)
   {
      if (cMyCiv != cCivRussians)
         createSimpleBuildPlan(cUnitTypeBarracks, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
      else
         createSimpleBuildPlan(cUnitTypeBlockhouse, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
      createSimpleBuildPlan(cUnitTypeStable, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
      createSimpleBuildPlan(cUnitTypeArtilleryDepot, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
   }
   else if (civIsNative() == true)
   {
      createSimpleBuildPlan(cUnitTypeWarHut, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
      if (cMyCiv == cCivXPAztec)
         createSimpleBuildPlan(cUnitTypeNoblesHut, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
      if (cMyCiv == cCivDEInca)
         createSimpleBuildPlan(cUnitTypedeKallanka, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
      if (cMyCiv == cCivXPIroquois || cMyCiv == cCivXPSioux)
         createSimpleBuildPlan(cUnitTypeCorral, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
      if (cMyCiv == cCivXPIroquois)
         createSimpleBuildPlan(cUnitTypeArtilleryDepot, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
   }
   else if (civIsAsian() == true)
   {
      if ((cMyCiv == cCivJapanese) || (cMyCiv == cCivSPCJapanese) || (cMyCiv == cCivSPCJapaneseEnemy))
      {
         createSimpleBuildPlan(cUnitTypeypBarracksJapanese, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
         createSimpleBuildPlan(cUnitTypeypStableJapanese, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
      }
      else if ((cMyCiv == cCivChinese) || (cMyCiv == cCivSPCChinese))
      {
         createSimpleBuildPlan(cUnitTypeypWarAcademy, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
      }
      else // We're Indian.
      {
         createSimpleBuildPlan(cUnitTypeYPBarracksIndian, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
         createSimpleBuildPlan(cUnitTypeypCaravanserai, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
      }
      // And 1 Castle shared for all of them.
      createSimpleBuildPlan(cUnitTypeypCastle, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
   }
   else // We're African.
   {
      createSimpleBuildPlan(cUnitTypedeWarCamp, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
      createSimpleBuildPlan(cUnitTypedePalace, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
   }

   if (civIsAsian() == false)
   {
      gNumTowers = 7; // Load up on Towers.
   }
   else
   {
      gNumTowers = 5; // Load up on Castles.
   }

   // We want tight control over what we build so we disable these rules.
   xsDisableRule("buildingMonitor");
   xsDisableRule("houseMonitor");
   xsDisableRule("extraHouseMonitor");

   xsEnableRule("deathMatchStartupMiddle");
}

rule deathMatchStartupMiddle
inactive
minInterval 45
{
   debugSetup("RUNNING deathMatchStartupMiddle");

   int mainBaseID = kbBaseGetMainID(cMyID);

   // Get more houses so we can start training more military.
   if (cMyCiv != cCivXPSioux)
      createSimpleBuildPlan(gHouseUnit, 5, 99, true, cEconomyEscrowID, mainBaseID, 1, -1, true);

   // Get 1 more of each of the main military buildings (2 total now).
   if (civIsEuropean() == true)
   {
      if (cMyCiv != cCivRussians)
         createSimpleBuildPlan(cUnitTypeBarracks, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
      else
         createSimpleBuildPlan(cUnitTypeBlockhouse, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
      createSimpleBuildPlan(cUnitTypeStable, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
      createSimpleBuildPlan(cUnitTypeArtilleryDepot, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
   }
   else if (civIsNative() == true)
   {
      createSimpleBuildPlan(cUnitTypeWarHut, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
      if (cMyCiv == cCivXPAztec)
         createSimpleBuildPlan(cUnitTypeNoblesHut, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
      if (cMyCiv == cCivDEInca)
         createSimpleBuildPlan(cUnitTypedeKallanka, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
      if (cMyCiv == cCivXPIroquois || cMyCiv == cCivXPSioux)
         createSimpleBuildPlan(cUnitTypeCorral, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
      if (cMyCiv == cCivXPIroquois)
         createSimpleBuildPlan(cUnitTypeArtilleryDepot, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
   }
   else if (civIsAsian() == true)
   {
      if ((cMyCiv == cCivJapanese) || (cMyCiv == cCivSPCJapanese) || (cMyCiv == cCivSPCJapaneseEnemy))
      {
         createSimpleBuildPlan(cUnitTypeypBarracksJapanese, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
         createSimpleBuildPlan(cUnitTypeypStableJapanese, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
      }
      else if ((cMyCiv == cCivChinese) || (cMyCiv == cCivSPCChinese))
      {
         createSimpleBuildPlan(cUnitTypeypWarAcademy, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
      }
      else // We're Indian.
      {
         createSimpleBuildPlan(cUnitTypeYPBarracksIndian, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
         createSimpleBuildPlan(cUnitTypeypCaravanserai, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
      }
      // And 1 Castle shared for all of them.
      createSimpleBuildPlan(cUnitTypeypCastle, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
   }
   else // We're African.
   {
      createSimpleBuildPlan(cUnitTypedeWarCamp, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
      createSimpleBuildPlan(cUnitTypedePalace, 1, 98, false, cMilitaryEscrowID, mainBaseID, 2);
   }

   xsEnableRule("deathMatchStartupEnd");
   xsDisableSelf();
}

rule deathMatchStartupEnd
inactive
minInterval 30
{
   debugSetup("RUNNING deathMatchStartupEnd");

   int mainBaseID = kbBaseGetMainID(cMyID);

   // Get the maximum amount of houses via build limit calculations.
   if (cMyCiv != cCivXPSioux)
   {
      int houseCount = kbUnitCount(cMyID, gHouseUnit, cUnitStateABQ) +
                       aiPlanGetNumberByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, gHouseUnit, true) +
                       aiPlanGetNumberByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, gHouseUnit, false);
      int houseBL = kbGetBuildLimit(cMyID, gHouseUnit);
      int housesToBuild = houseBL - houseCount;
      if (housesToBuild > 0)
         createSimpleBuildPlan(gHouseUnit, housesToBuild, 99, true, cEconomyEscrowID, mainBaseID, 1);
   }

   // Get 1 more of each of the main military buildings (3 total now, sometimes 4).
   if (civIsEuropean() == true)
   {
      if (cMyCiv != cCivRussians)
         createSimpleBuildPlan(cUnitTypeBarracks, 1, 98, false, cMilitaryEscrowID, mainBaseID, 1);
      else
         createSimpleBuildPlan(cUnitTypeBlockhouse, 1, 98, false, cMilitaryEscrowID, mainBaseID, 1);
      createSimpleBuildPlan(cUnitTypeStable, 1, 98, false, cMilitaryEscrowID, mainBaseID, 1);
      createSimpleBuildPlan(cUnitTypeArtilleryDepot, 1, 98, false, cMilitaryEscrowID, mainBaseID, 1);
   }
   else if (civIsNative() == true)
   {
      createSimpleBuildPlan(cUnitTypeWarHut, 1, 98, false, cMilitaryEscrowID, mainBaseID, 1);
      if (cMyCiv == cCivXPAztec)
         createSimpleBuildPlan(cUnitTypeNoblesHut, 1, 98, false, cMilitaryEscrowID, mainBaseID, 1);
      if (cMyCiv == cCivDEInca)
         createSimpleBuildPlan(cUnitTypedeKallanka, 1, 98, false, cMilitaryEscrowID, mainBaseID, 1);
      if (cMyCiv == cCivXPIroquois || cMyCiv == cCivXPSioux)
         createSimpleBuildPlan(cUnitTypeCorral, 1, 98, false, cMilitaryEscrowID, mainBaseID, 1);
      if (cMyCiv == cCivXPIroquois)
         createSimpleBuildPlan(cUnitTypeArtilleryDepot, 1, 98, false, cMilitaryEscrowID, mainBaseID, 1);
   }
   else if (civIsAsian() == true)
   {
      if ((cMyCiv == cCivJapanese) || (cMyCiv == cCivSPCJapanese) || (cMyCiv == cCivSPCJapaneseEnemy))
      {
         createSimpleBuildPlan(cUnitTypeypBarracksJapanese, 1, 98, false, cMilitaryEscrowID, mainBaseID, 1);
         createSimpleBuildPlan(cUnitTypeypStableJapanese, 1, 98, false, cMilitaryEscrowID, mainBaseID, 1);
      }
      else if ((cMyCiv == cCivChinese) || (cMyCiv == cCivSPCChinese))
      {
         createSimpleBuildPlan(cUnitTypeypWarAcademy, 2, 98, false, cMilitaryEscrowID, mainBaseID, 1);
      }
      else // We're Indian.
      {
         createSimpleBuildPlan(cUnitTypeYPBarracksIndian, 1, 98, false, cMilitaryEscrowID, mainBaseID, 1);
         createSimpleBuildPlan(cUnitTypeypCaravanserai, 1, 98, false, cMilitaryEscrowID, mainBaseID, 1);
      }
      // And 1 Castle shared for all of them.
      createSimpleBuildPlan(cUnitTypeypCastle, 1, 98, false, cMilitaryEscrowID, mainBaseID, 1);
   }
   else // We're African.
   {
      createSimpleBuildPlan(cUnitTypedeWarCamp, 2, 98, false, cMilitaryEscrowID, mainBaseID, 1);
      createSimpleBuildPlan(cUnitTypedePalace, 1, 98, false, cMilitaryEscrowID, mainBaseID, 1);
   }

   // Enable everything again that we disabled before so the AI can play on like it's a regular game.
   cvOkToGatherFood = true;
   cvOkToGatherWood = true;
   cvOkToGatherGold = true;

   xsEnableRule("buildingMonitor");
   xsEnableRule("houseMonitor");
   xsEnableRule("extraHouseMonitor");
   xsDisableSelf();
}

//==============================================================================
// economyModeMatchStartupBegin
// Make a bunch of changes to get a economy mode start.
//==============================================================================
void economyModeMatchStartupBegin()
{
   debugSetup("RUNNING economyModeMatchStartupBegin");

   btOffenseDefense = -1.0;
   btRushBoom = -1.0;
   gNumTowers = 7;
}

//==============================================================================
// initCeylonNomadStart
//
// If we are doing a nomad start, migrate to the main island no matter what.
//==============================================================================
int gCeylonStartingTargetArea = -1;

void initCeylonNomadStart(void)
{
   int areaCount = 0;
   vector myLocation = cInvalidVector;
   int myAreaGroup = -1;

   int area = 0;
   int areaGroup = -1;
   int i = 0;
   int unit = getUnit(cUnitTypeCoveredWagon, cMyID, cUnitStateAlive);

   areaCount = kbAreaGetNumber();
   myLocation = kbUnitGetPosition(unit);
   myAreaGroup = kbAreaGroupGetIDByPosition(myLocation);

   int closestArea = -1;
   float closestAreaDistance = kbGetMapXSize();

   for (area = 0; < areaCount)
   {
      if (kbAreaGetType(area) == cAreaTypeWater)
         continue;

      areaGroup = kbAreaGroupGetIDByPosition(kbAreaGetCenter(area));
      if (kbAreaGroupGetNumberAreas(areaGroup) - kbAreaGroupGetNumberAreas(myAreaGroup) <= 10)
         continue;

      bool bordersWater = false;
      int borderAreaCount = kbAreaGetNumberBorderAreas(area);
      for (i = 0; < borderAreaCount)
      {
         if (kbAreaGetType(kbAreaGetBorderAreaID(area, i)) == cAreaTypeWater)
         {
            bordersWater = true;
            break;
         }
      }

      if (bordersWater == false)
         continue;

      float dist = xsVectorLength(kbAreaGetCenter(area) - myLocation);
      if (dist < closestAreaDistance)
      {
         closestAreaDistance = dist;
         closestArea = area;
      }
   }

   aiTaskUnitMove(getUnit(cUnitTypeypMarathanCatamaran, cMyID, cUnitStateAlive), kbAreaGetCenter(closestArea));
   gCeylonStartingTargetArea = closestArea;
   xsEnableRule("initCeylonWaitForExplore");
   xsDisableRule("waterAttackDefend");
}

rule initCeylonWaitForExplore
inactive
minInterval 3
{
   if (kbAreaGetNumberFogTiles(gCeylonStartingTargetArea) + kbAreaGetNumberVisibleTiles(gCeylonStartingTargetArea) == 0)
   {
      aiTaskUnitMove(getUnit(cUnitTypeypMarathanCatamaran, cMyID, cUnitStateAlive), kbAreaGetCenter(gCeylonStartingTargetArea));
      return;
   }

   int unit = getUnit(cUnitTypeCoveredWagon, cMyID, cUnitStateAlive);
   vector location = kbUnitGetPosition(unit);

   int baseID = kbBaseCreate(cMyID, "Transport gather base", location, 10.0);
   kbBaseAddUnit(cMyID, baseID, unit);

   int transportPlan = createTransportPlan(location, kbAreaGetCenter(gCeylonStartingTargetArea), 100);

   aiPlanSetEventHandler(transportPlan, cPlanEventStateChange, "initCeylonTransportHandler");

   int numberNeeded = kbUnitCount(cMyID, cUnitTypeAbstractWagon, cUnitStateAlive);
   aiPlanAddUnitType(transportPlan, cUnitTypeAbstractWagon, numberNeeded, numberNeeded, numberNeeded);

   numberNeeded = kbUnitCount(cMyID, cUnitTypeLogicalTypeScout, cUnitStateAlive);
   aiPlanAddUnitType(transportPlan, cUnitTypeLogicalTypeScout, numberNeeded, numberNeeded, numberNeeded);

   xsEnableRule("initCeylonFailsafe");

   xsDisableSelf();
}

void initCeylonTransportHandler(int planID = -1)
{
   static bool transporting = false;
   vector centerPoint = kbGetMapCenter();

   switch (aiPlanGetState(planID))
   {
   case -1:
   {
      if (transporting == true)
      {
         // transport done.

         // build a TC on the main island in the direction of the map center to our starting position.
         vector vec = xsVectorNormalize(kbGetPlayerStartingPosition(cMyID) - centerPoint);
         int wagon = getUnit(cUnitTypeCoveredWagon, cMyID, cUnitStateAlive);
         vector wagonLoc = kbUnitGetPosition(wagon);
         float dist = xsVectorLength(wagonLoc - centerPoint);

         // not too close to the shore.
         if (dist >= 80.0)
            dist -= 40.0;

         gTCSearchVector = centerPoint + vec * dist;
         gStartingLocationOverride = gTCSearchVector;
         aiTaskUnitMove(wagon, gTCSearchVector);

         xsEnableRule("initRule");
         xsEnableRule("waterAttackDefend");
      }
      break;
   }
   case cPlanStateGather:
   {
      // hack drop-off point
      vector targetPoint = aiPlanGetVariableVector(planID, cTransportPlanTargetPoint, 0);
      aiPlanSetVariableVector(
          planID,
          cTransportPlanDropOffPoint,
          0,
          xsVectorSet(
              0.2 * xsVectorGetX(centerPoint) + 0.8 * xsVectorGetX(targetPoint),
              0.0,
              0.2 * xsVectorGetZ(centerPoint) + 0.8 * xsVectorGetZ(targetPoint)));
      break;
   }
   case cPlanStateGoto:
   {
      transporting = true;
      break;
   }
   }
}

rule initCeylonFailsafe
inactive
minInterval 10
{
   int transportPlan = aiPlanGetIDByTypeAndVariableType(
       cPlanTransport, cTransportPlanTransportTypeID, cUnitTypeypMarathanCatamaran);
   switch (aiPlanGetState(transportPlan))
   {
   case -1:
   {
      xsDisableSelf();
      break;
   }
   case cPlanStateEnter:
   {
      aiTaskUnitMove(
          aiPlanGetVariableInt(transportPlan, cTransportPlanTransportID, 0),
          aiPlanGetVariableVector(transportPlan, cTransportPlanGatherPoint, 0));
      break;
   }
   }
}