//==============================================================================
/* aiHCCards.xs

   This file manages home city deck building, and choosing the card to send
   when shipment arrives.

*/
//==============================================================================

int findBestHCGatherUnit(int baseID = -1)
{
   vector loc = kbBaseGetLocation(cMyID, baseID);
   float dist = kbBaseGetDistance(cMyID, baseID);
   int unitID = getUnitByLocation(cUnitTypeAbstractTownCenter, cMyID, cUnitStateAlive, loc, dist);
   if (unitID < 0)
      unitID = getUnitByLocation(cUnitTypeHCGatherPointPri1, cMyID, cUnitStateAlive, loc, dist);
   if (unitID < 0)
      unitID = getUnitByLocation(cUnitTypeHCGatherPointPri2, cMyID, cUnitStateAlive, loc, dist);
   if (unitID < 0)
      unitID = getUnitByLocation(cUnitTypeHCGatherPointPri3, cMyID, cUnitStateAlive, loc, dist);
   return (unitID);
}

int gCardNames = -1;          // Array of strings, handy name for this card.
int gCardStates = -1;         // Array of chars (strings), A = avail, N = Not avail, P = Purchased, D = in deck (and purchased)
int gCardPriorities = -1;     // Array of ints, used for selecting cards into deck.
int gPremadeDeckTechIDs = -1; // Array of ints, used for storing tech IDs from a premade deck.

bool addCardToDeck(int deckIndex = -1, int cardIndex = -1)
{
   debugHCCards("Adding card " + xsArrayGetString(gCardNames, cardIndex));
   return (aiHCDeckAddCardToDeck(deckIndex, cardIndex));
}

rule buyCards
inactive
highFrequency
{
   static int pass = 0; // Pass 0, init arrays.  Pass 1, buy cards.  Pass 2, create deck.
   static int startingSP = -1;

   const int maxCards = 150;
   if (startingSP < 0)
      startingSP = kbResourceGet(cResourceSkillPoints) -
                   15; // XS won't allow float initialization of const ints, also subtract first 15 free cards.
   int remainingSP = kbResourceGet(cResourceSkillPoints) - 15;
   int SPSpent = startingSP - remainingSP;
   int myLevel = 0;
   if (SPSpent >= 10)
      myLevel = 10;
   if (SPSpent >= 25)
      myLevel = 25;
   int totalCardCount = aiHCCardsGetTotal();
   static int numCardsProcessed = 0;
   static int numCardsPremadeDeck = 0;

   if (numCardsProcessed == 0)
      debugHCCards("My starting level is " + myLevel + ", my SP remaining is " + remainingSP);

   switch (pass) // Break processing load into 3 passes:  init, buy, deck.
   {
   case 0: // Init arrays
   {
      if (numCardsProcessed == 0)
      {
         int premadeDeckID = -1;
         int premadeCardTechID = -1;
         int numPremadeDecks = aiHCPreMadeDeckGetNumber();

         gCardNames = xsArrayCreateString(maxCards, " ", "Card names");
         gCardStates = xsArrayCreateString(maxCards, "P", "Card states");
         gCardPriorities = xsArrayCreateInt(maxCards, 0, "Card priorities");

         // Get appropriate premade deck
         if ((gNavyMap == false) && (numPremadeDecks >= 1))
         {
            premadeDeckID = aiHCPreMadeDeckGetIndex("Land");
         }
         else if ((gNavyMap == true) && (numPremadeDecks >= 1))
         {
            premadeDeckID = aiHCPreMadeDeckGetIndex("Naval");
         }
         if (premadeDeckID >= 0)
         {
            numCardsPremadeDeck = aiHCPreMadeDeckGetNumberCards(premadeDeckID);
            gPremadeDeckTechIDs = xsArrayCreateInt(numCardsPremadeDeck, 0, "Premade deck tech IDs");
            for (premadeCardID = 0; < numCardsPremadeDeck)
            {
               premadeCardTechID = aiHCPreMadeDeckGetCardTechID(premadeDeckID, premadeCardID);
               xsArraySetInt(gPremadeDeckTechIDs, premadeCardID, premadeCardTechID);
            }
         }
      }

      int startingCardIndex = numCardsProcessed;

      for (i = startingCardIndex; < totalCardCount)
      { // Set priorities for the cards based on unit type.
         string tempString = "";
         int cardPriority = 0;
         int flags = aiHCCardsGetCardFlags(i);
         int unit = aiHCCardsGetCardUnitType(i);
         int tech = aiHCCardsGetCardTechID(i);
         string techName = kbGetTechName(aiHCCardsGetCardTechID(i));

         if (((flags & cHCCardFlagVillager) == cHCCardFlagVillager) || (unit == cUnitTypeSettler) ||
             (unit == cUnitTypeCoureur) || (unit == cUnitTypeSettlerWagon) || (unit == cUnitTypeSettlerNative) ||
             (unit == cUnitTypeypSettlerAsian))
         {
            cardPriority = 8 - aiHCCardsGetCardAgePrereq(i);
            if (cardPriority < 5)
               cardPriority = 5;
            xsArraySetInt(gCardPriorities, i, cardPriority); // Settler card, pri 5-8 depending on age req
         }
         if (xsArrayGetInt(gCardPriorities, i) == 0)
         {
            // Prefer kalmar castle over ship fort wagon card
            if ((unit == cUnitTypeFortWagon) || (unit == cUnitTypeFactoryWagon) || (unit == cUnitTypeypArsenalWagon) ||
                (unit == cUnitTypeYPDojoWagon))
               xsArraySetInt(gCardPriorities, i, 10); // Fort, Factory, Arsenal and Dojo Wagons, pri 7
            if (unit == cUnitTypeBankWagon)
               xsArraySetInt(gCardPriorities, i, 5); // Bank Wagon, pri 6
            if ((unit == cUnitTypeOutpostWagon) || (unit == cUnitTypeYPCastleWagon) ||
                ((xsArrayGetInt(gCardPriorities, i) == 0) && ((flags & cHCCardFlagWagon) == cHCCardFlagWagon)))
            {
               if (btRushBoom <= 0) // Outpost and castle wagon, pri 1 for rushers, pri 5 otherwise
                  xsArraySetInt(gCardPriorities, i, 5);
               else
                  xsArraySetInt(gCardPriorities, i, 1);
            }
         }
         if ((xsArrayGetInt(gCardPriorities, i) == 0) && (unit >= 0))
         { // Some type of unit, pri 6 for resources, 5 for others
            if (((flags & cHCCardFlagResourceCrate) == cHCCardFlagResourceCrate) ||
                (kbProtoUnitIsType(cMyID, unit, cUnitTypeAbstractResourceCrate) == true))
            {
               if ((cMyCiv == cCivPortuguese) && /*(tech == cTechHCShipFoodCrates3) ||*/ (tech == cTechHCShipWoodCrates3) ||
                   (tech == cTechHCShipCoinCrates3))
                  xsArraySetInt(gCardPriorities, i, 6); // Resource crates, 7 for 700 res shipments for portuguese
               else if (aiHCCardsGetCardAgePrereq(i) == cAge1)
                  xsArraySetInt(gCardPriorities, i,
                                4); // Only pick age1 resources crates when there isn't anything else better
               else
                  xsArraySetInt(gCardPriorities, i, 5); // Resource crates, 6 otherwise
               if ((aiHCCardsGetCardAgePrereq(i) >= cAge3) && (aiHCCardsGetCardCount(i) >= 1))
               { // Demote finite age 3+ resource crate shipments to prio 5-6
                  cardPriority = xsArrayGetInt(gCardPriorities, i);
                  cardPriority = cardPriority - 1;
                  xsArraySetInt(gCardPriorities, i, cardPriority);
               }
            }
            else
               xsArraySetInt(gCardPriorities, i, 3); // Generic unit
         }
         if ((xsArrayGetInt(gCardPriorities, i) == 0) && ((flags & cHCCardFlagUnitUpgrade) == cHCCardFlagUnitUpgrade))
            xsArraySetInt(gCardPriorities, i, 4); // Some type of unit upgrade, prio 4.
         if ((xsArrayGetInt(gCardPriorities, i) == 0) && (flags == 0))
            xsArraySetInt(gCardPriorities, i, 4); // Some type of other upgrade, prio 4.
         if (xsArrayGetInt(gCardPriorities, i) == 0)
            xsArraySetInt(gCardPriorities, i, 3); // ???, prio 3.
         if ((xsArrayGetInt(gCardPriorities, i) == 5) && (unit >= 0) &&
             ((flags & cHCCardFlagResourceCrate) != cHCCardFlagResourceCrate))
         { // Demote shipments of non-mil units to 4; cows, sheep and surgeons to 0.
            if (((flags & cHCCardFlagMilitary) != cHCCardFlagMilitary) &&
                (kbProtoUnitIsType(cMyID, unit, cUnitTypeLogicalTypeLandMilitary) == false))
               xsArraySetInt(gCardPriorities, i, 4);
            if ((kbProtoUnitIsType(cMyID, unit, cUnitTypeHerdable) == true) ||
                (kbProtoUnitIsType(cMyID, unit, cUnitTypeMissionary) == true) ||
                (kbProtoUnitIsType(cMyID, unit, cUnitTypeSurgeon) == true))
               xsArraySetInt(gCardPriorities, i, 0);
         }
         if (unit == cUnitTypeCoveredWagon)
            xsArraySetInt(gCardPriorities, i, 5); // Covered Wagon, pri 5
         // Set priority to 0 for Recruit Wokou Cards
         if ((aiGetWorldDifficulty() >= cDifficultyModerate) &&
             ((xsArrayGetInt(gCardPriorities, i) >= 1) &&
              ((tech == cTechYPHCWokouChinese1) || (tech == cTechYPHCWokouChinese2) || (tech == cTechYPHCWokouChinese3) ||
               (tech == cTechYPHCWokouJapanese1) || (tech == cTechYPHCWokouJapanese2) || (tech == cTechYPHCWokouJapanese3) ||
               (tech == cTechYPHCWokouIndians1) || (tech == cTechYPHCWokouIndians2) || (tech == cTechYPHCWokouIndians3Double))))
            xsArraySetInt(gCardPriorities, i, 0);

         if ((xsArrayGetInt(gCardPriorities, i) == 0) && (xsArrayGetString(gCardStates, i) == "P"))
         { // We own this card, but it's not in the categories above, and won't be flagged when we do our purchases.
            // So, give it a P1 just to distinguish it from others.
            xsArraySetInt(gCardPriorities, i, 1);
         }

         // Raise priority of water related cards and upgrades on water maps.
         if ((xsArrayGetInt(gCardPriorities, i) < 10) &&
             ((gNavyMap == true) &&
              (((flags & cHCCardFlagWater) == cHCCardFlagWater) || (tech == cTechHCCoastalDefensesTeam) ||
               (tech == cTechHCNavalCombat) || (tech == cTechHCNavalCombatGerman) || (tech == cTechYPHCNavalCombatTeam) ||
               //(tech == cTechYPHCNavalCombatIndians) || (tech == cTechHCAdmirality) || (tech == cTechHCAdmiralityGerman) ||
               /*(tech == cTechYPHCAdmiralityIndians) ||*/ (tech == cTechHCFishMarket) || (tech == cTechHCFishMarketTeam) ||
               (tech == cTechHCFishMarketGerman) || (tech == cTechYPHCFishMarketIndians) || (tech == cTechypHCFishMarket) ||
               (tech == cTechHCRenderingPlant) || (tech == cTechHCRenderingPlantGerman) ||
               (tech == cTechYPHCRenderingPlantIndians) || (tech == cTechHCCoastalDefensesTeam) ||
               (kbProtoUnitIsType(cMyID, unit, cUnitTypeAbstractWarShip) == true) ||
               (kbProtoUnitIsType(cMyID, unit, cUnitTypeAbstractFishingBoat) == true))))
         {
            cardPriority = xsArrayGetInt(gCardPriorities, i);
            if (cardPriority < 3)
               cardPriority = 3;
            cardPriority = cardPriority + 1;
            if (cardPriority > 10)
               cardPriority = 10;
            xsArraySetInt(gCardPriorities, i, cardPriority);
         }

         if (premadeDeckID >= 0)
         { // Raise priority of cards in premade decks.
            for (premadeCardID = 0; < numCardsPremadeDeck)
            {
               if ((xsArrayGetInt(gCardPriorities, i) < 10) && (xsArrayGetInt(gPremadeDeckTechIDs, premadeCardID) == tech))
               {
                  cardPriority = xsArrayGetInt(gCardPriorities, i);
                  if (cardPriority < 4)
                     cardPriority = 4;
                  int randInt = -1;
                  if (aiGetWorldDifficulty() >= cDifficultyModerate)
                     randInt = aiRandInt(2);
                  if (((flags & cHCCardFlagTeam) == cHCCardFlagTeam) && (getAllyCount() <= 0))
                     cardPriority = cardPriority + 1 + randInt;
                  else
                     cardPriority = cardPriority + 2 + randInt;
                  if (cardPriority > 10)
                     cardPriority = 10;
                  xsArraySetInt(gCardPriorities, i, cardPriority);
               }
            }
         }

         // Raise priority of cards with infinite use when priority still < 7.
         /*if ((aiGetWorldDifficulty() >= cDifficultyModerate) &&
             ((xsArrayGetInt(gCardPriorities, i) < 7) && (aiHCCardsGetCardCount(i) < 0)))
         {
            cardPriority = xsArrayGetInt(gCardPriorities, i);
            cardPriority = cardPriority + 1;
            if (cardPriority > 10)
               cardPriority = 10;
            xsArraySetInt(gCardPriorities, i, cardPriority);
         }
*/
		 if ((cMyCiv == cCivOttomans) && (tech == cTechHCShipCoveredWagons2))
                  xsArraySetInt(gCardPriorities, i, 7);
			 if ((techName == "HCRoyalDecreeDutch") ||
                (techName == "HCRoyalDecreeBritish") ||
                (techName == "HCRoyalDecreeFrench") ||
                (techName == "HCRoyalDecreeGerman") ||
                (techName == "HCRoyalDecreeOttoman") ||
                (techName == "HCRoyalDecreePortuguese") ||
                //(techName == "HCShipJanissaries1") ||
                (techName == "HCRoyalDecreeSpanish") ||
                (techName == "DEHCRoyalDecreeSwedish") ||
                (techName == "DEHCPlatoonFire") ||
                (techName == "DEHCSnaplocks") ||
                (techName == "DEHCCronstedtReforms") ||
                (techName == "DEHCBlueberries") ||
                (techName == "DEHCBlackberries") ||
                (techName == "DEHCSveaLifeguard") ||
                (techName == "YPHCMercsRattanShield3") ||
                (techName == "YPHCMercsRattanShield3") ||
                (techName == "DEHCBeekeepers") ||
                (techName == "DEHCFazogli") ||
                (techName == "DEHCJesuitInfluence") ||
                //(techName == "DEHCLalibelaRockChurch") ||
                (techName == "DEHCChewaWarriors") ||
                (techName == "DEHCZebenyas") ||
                //(techName == "DEHCCartridgeCurrency") ||
                (techName == "DEHCTigrayMekonnen") ||
                (techName == "DEHCGascenyaDamage") ||
                (techName == "DEHCGascenyaHitpoints") ||
                (techName == "DEHCShewaRiders") ||
                (techName == "DEHCFasterTrainingUnitsAfrican") ||
                (techName == "DEHCBalambaras") ||
                (techName == "DEHCFirearmsBritish") ||
                (techName == "DEHCFirearmsItalian") ||
                (techName == "DEHCGondarineArchitecture") ||
                (techName == "DEHCJesuitSpirituality") ||
                (techName == "DEHCAdvancedLivestockMarket") ||
                (techName == "DEHCRoofAfrica") ||
                (techName == "DEHCMercsGatlingCamels") ||
                (techName == "DEHCFulaniPulaakuCode") ||
                (techName == "DEHCFodioTactics") ||
                //(techName == "DEHCDaneGuns") ||
                //(techName == "DEHCSarkinDogarai") ||
                (techName == "DEHCDurbarParade") ||
                (techName == "DEHCSahelianKingdoms") ||
                (techName == "DEHCKolaNutCultivation") ||
                (techName == "DEHCFulaniCattleFertilizer") ||
                (techName == "DEHCRanoIndigoProduction") ||
                (techName == "DEHCTextileWorkshops") ||
                (techName == "DEHCKoose") ||
                (techName == "DEHCHabbanaya") ||
                (techName == "DEHCCounterCavalry") ||
                (techName == "DEHCHandCavalryDamageHausa") ||
                (techName == "DEHCHandCavalryHitpointsHausa") ||
                (techName == "DEHCFulaniArcherCombat") ||
                (techName == "DEHCFirearmsBritish") ||
                (techName == "DEHCFirearmsItalian") ||
                (techName == "DEHCKingslayer") ||
                (techName == "DEHCSveaLifeguard") ||
                (techName == "DEHCSveaLifeguard") ||
                (techName == "DEHCSveaLifeguard") ||
                //(techName == "DEHCLoyalWarriors") ||
                //(techName == "DEHCKingKings") ||
                (techName == "DEHCTemenyas") ||
                (techName == "DEHCTerraceFarming") ||
                //(techName == "DEHCEarlyKallanka") ||
                (techName == "DEHCAutarky") ||
                (techName == "DEHCCaseShot") ||
                //(techName == "YPHCShipUrumi1") ||
                //(techName == "YPHCShipUrumi2") ||
                (techName == "YPHCShipUrumiRegiment") ||
                (techName == "HCAdvancedArsenal") ||
                (techName == "HCShipSettlers3") ||
                (techName == "HCShipCoureurs3") ||
                (techName == "HCXPShipVillagers3") ||
                (techName == "HCShipSettlerWagons3") ||
                (techName == "HCShipSettlerWagons4") ||
                (techName == "HCRoyalDecreeFrench") ||
                (techName == "HCXPNewWaysIroquois") ||
                (techName == "HCXPNewWaysSioux") ||
                (techName == "HCGermantownFarmers") ||
                (techName == "YPHCShipShogunate") ||
                (techName == "YPHCShipDaimyoAizu") ||
                (techName == "HCImprovedLongbows") ||
                (techName == "YPHCShipDaimyoSatsuma")||
                (techName == "HCDuelingSchoolTeam") ||
                (techName == "HCFencingSchool")||
                (techName == "YPHCBannerSchool") ||
                (techName == "YPHCAccupuncture")||
                   (techName == "HCXPOnikare") ||
                   (techName == "HCXPSiouxNakotaSupport") ||
                (techName == "HCRidingSchool") ||
                (techName == "YPHCFencingSchoolIndians") ||
                (techName == "YPHCRidingSchoolIndians") ||
                (techName == "HCFencingSchoolGerman") ||
                (techName == "HCRidingSchoolGerman") ||
                (techName == "HCRidingSchoolGerman2") ||
				//(techName == "YPHCArtilleryCombatChinese") ||
		        //(techName == "YPHCArtilleryDamageChinese") ||
                (techName == "YPHCAdvancedConsulate") ||
                (techName == "YPHCAdvancedConsulateIndians") ||
                (techName == "YPHCIncreasedTribute") ||
                //(techName == "YPHCOldHanArmyReforms") ||
                (techName == "HCMercenaryCombatGerman") ||
                (techName == "YPHCWesternReforms") ||
                (techName == "HCRoyalDecreeDutch") ||
                (techName == "HCRoyalDecreeFrench") ||
                (techName == "HCUnlockFactory") ||
                (techName == "HCRobberBarons") ||
                (techName == "HCUnlockFactoryGerman") ||
                (techName == "HCRobberBaronsGerman") ||
                (techName == "HCImprovedLongbows") ||
				(techName == "HCGuildArtisans") ||
                (techName == "HCBanks2") ||
				(techName == "HCBanks1") ||                 
                (techName == "HCXPThoroughbreds") ||
                (techName == "HCCavalryCombatFrench") ||
                (techName == "HCHandCavalryHitpointsFrench") ||
                (techName == "HCHandCavalryDamageFrenchTeam") ||
                (techName == "HCXPKnightCombat") ||
                (techName == "HCXPKnightDamage") ||
                (techName == "HCXPKnightHitpoints") ||
                (techName == "HCXPWarHutTraining") ||
                (techName == "HCXPCavalryDamageIroquois") ||
                (techName == "HCXPInfantryCombatIroquois") ||
                (techName == "HCXPInfantryHitpointsIroquois") ||
                (techName == "HCXPInfantryDamageIroquoisIroquois") ||
                (techName == "HCInfantryCombatDutch") ||
                (techName == "HCInfantryHitpointsDutchTeam") ||
                (techName == "HCInfantryDamageDutch") ||
                (techName == "HCXPSiegeDiscipline") ||
                (techName == "HCXPConservativeTactics") ||         
                (techName == "YPHCTerritorialArmyCombat") ||
                (techName == "YPHCHanAntiCavalryBonus") ||
                (techName == "YPHCForbiddenArmyArmor") ||
                (techName == "YPHCManchuCombat") ||
				(techName == "YPHCYumiDamage") ||
				(techName == "YPHCAshigaruDamage") ||
				//(techName == "YPHCShipAshigaru2") ||
				(techName == "YPHCAshigaruAntiCavalryDamage") ||
				(techName == "YPHCYumiRange") ||
				(techName == "YPHCNaginataAntiInfantryDamage") ||
				(techName == "YPHCNaginataHitpoints") ||
                (techName == "YPHCGurkhaAid") ||                
                (techName == "YPHCEastIndiaCompany") ||
                (techName == "YPHCCamelFrightening") ||
                (techName == "YPHCInfantrySpeedHitpointsTeam") ||
                (techName == "YPHCElephantLimit") ||
				(techName == "YPHCElephantCombatIndians") ||
				(techName == "YPHCElephantTrampling") ||
			    (techName == "YPHCCamelDamageIndians") ||
				(techName == "YPHCMeleeDamageIndians") ||
                (techName == "HCXPCommandSkill") ||	
				(techName == "HCXPCavalryDamageSioux") ||
				(techName == "HCXPCavalryHitpointsSioux") ||
				(techName == "HCXPCavalryCombatSioux") ||
				(techName == "HCXPMustangs") ||
                (techName == "HCXPSiouxYanktonSupport") ||
                (techName == "HCXPSiouxSanteeSupport") ||
				(techName == "HCXPInfantryDamageIroquois") ||
				(techName == "HCXPInfantryHitpointsIroquois") ||		 		
				(techName == "HCXPCavalryHitpointsIroquois") ||
				(techName == "HCXPSiegeCombat") ||		
				(techName == "HCXPKnightDamage") ||		
				(techName == "HCImprovedBuildings") ||
				(techName == "ypHCImprovedBuildings") ||
				(techName == "YPHCImprovedBuildingsTeam") ||		
				(techName == "HCImprovedBuildingsGerman") ||		 
				(techName == "HCXPKnightHitpoints") ||
				//(techName == "HCXPScorchedEarth") ||
				(techName == "HCXPTempleCenteotl") ||
				(techName == "HCXPTempleCenteotl") || 
				(techName == "HCXPTempleXipeTotec") || 
				(techName == "HCXPTempleTlaloc") || 
				(techName == "HCXPGreatTempleQuetzalcoatl") || 
                (techName == "HCMusketeerGrenadierHitpointsBritishTeam") ||                 
				(techName == "HCCavalryCombatBritish") ||
				(techName == "HCMusketeerGrenadierDamageBritish") ||
				(techName == "HCMusketeerGrenadierCombatBritish") ||
				(techName == "HCCavalryDamageBritish") ||
				(techName == "HCCavalryHitpointsBritish") ||
				(techName == "HCRangedInfantryDamageFrenchTeam") ||
                (techName == "HCWildernessWarfare") ||		 
				(techName == "HCHandCavalryHitpointsFrench") ||		                  
                (techName == "HCJanissaryCost") ||
				(techName == "HCJanissaryCombatOttoman") ||
				(techName == "HCCavalryCombatOttoman") ||
				(techName == "HCArtilleryDamageOttoman") ||
                (techName == "HCRangedInfantryHitpointsPortugueseTeam") ||
                (techName == "HCRangedInfantryDamagePortuguese") ||
				(techName == "HCRangedInfantryCombatPortuguese") ||
				(techName == "HCDragoonCombatPortuguese") ||
				(techName == "HCXPGenitours") ||
                (techName == "HCRoyalDecreeDutch") ||
                //(techName == "HCDutchEastIndiaCompany") ||
				(techName == "HCInfantryDamageDutch") ||
				(techName == "HCInfantryCombatDutch") ||
				(techName == "HCCavalryCombatDutch") ||	 
				(techName == "HCBetterBanks") ||
                (techName == "HCStreletsCombatRussian") ||
				(techName == "HCRansack") ||
				(techName == "HCCavalryCombatRussian") ||
				(techName == "HCUniqueCombatRussian") ||
                (techName == "HCXPIndustrialRevolution") ||
				//(techName == "HCHandInfantryHitpointsSpanish") || 
                //(techName == "HCHandInfantryDamageSpanishTeam") ||
                //(techName == "HCHandInfantryCombatSpanish") ||
				(techName == "HCHandCavalryCombatSpanish") ||
				(techName == "HCCaballeros") ||
				(techName == "HCHandCavalryDamageSpanish") ||
				(techName == "HCHandCavalryHitpointsSpanish") ||  
				(techName == "HCCavalryCombatGerman") ||
				(techName == "HCCavalryHitpointsGerman") ||
				(techName == "HCUhlanCombatGerman") ||
                (techName == "HCCavalryDamageGermanTeam")||   
                (techName == "YPHCAdvancedConsulate") ||      
		 (techName == "YPHCAccupuncture") ||
		 (techName == "YPHCBannerSchool") ||
                 (techName == "YPHCAgrarianism") ||
                 (techName == "YPHCIncreasedTribute") ||
                 (techName == "YPHCFencingSchoolIndians") ||
                 (techName == "YPHCRidingSchoolIndians") ||
                 (techName == "HCRidingSchool") ||
                 (techName == "HCFencingSchool") ||
                 (techName == "HCXPMustangs") ||
                 (techName == "HCFencingSchoolGerman") ||
                 (techName == "HCRidingSchoolGerman") ||
                 //(gNavyMap == true) && ((techName == "YPHCAdmiralityIndians") ||
                 //(gNavyMap == true) && (techName == "HCAdmirality")) ||
                 //(techName == "YPHCOldHanArmyReforms") ||
                 (techName == "YPHCWesternReforms") ||
                 (techName == "HCRoyalDecreeDutch") ||
                 (techName == "HCRoyalDecreeFrench") ||
                 (techName == "HCUnlockFactory") ||
                 (techName == "HCRobberBarons") ||
                 (techName == "HCUnlockFactoryGerman") ||
                 (techName == "HCRobberBaronsGerman") ||
                 (techName == "HCImprovedLongbows") ||
                 (techName == "DEHCImmigrantsGerman") ||
                 (techName == "HCGermantownFarmers") ||
		 (techName == "HCGuildArtisans") ||
                 //((civIsAsian() == false) && (techName == "HCXPLandGrab")) ||
                 (techName == "HCBanks2") ||
		 (techName == "HCBanks1") ||                 
                 (techName == "HCXPThoroughbreds") ||
                 (techName == "HCCavalryCombatFrench") ||
                 (techName == "HCHandCavalryDamageFrenchTeam") ||
                 //(techName == "HCXPChinampa2") ||
		 (techName == "DEHCLlamaLifestyle") ||
                 (techName == "HCXPKnightCombat") ||
                 (techName == "HCXPWarHutTraining") ||
                 (techName == "HCXPCavalryDamageIroquois") ||
                 (techName == "HCXPInfantryCombatIroquois") ||
                 (techName == "HCXPSiegeDiscipline") ||
                 //(techName == "HCXPGreatHouse") ||
                 (techName == "HCXPConservativeTactics") ||     
                 (techName == "YPHCTerritorialArmyCombat") ||
                 (techName == "YPHCHanAntiCavalryBonus") ||
                 (techName == "YPHCForbiddenArmyArmor") ||
                 (techName == "YPHCManchuCombat") ||
                 ((getAllyCount() > 0) && (techName == "YPHCChonindoTeam")) ||
		 (techName == "YPHCYumiDamage") ||
		 (techName == "YPHCAshigaruDamage") ||
		 (techName == "YPHCAshigaruAntiCavalryDamage") ||
		 (techName == "YPHCYumiRange") ||
		 (techName == "YPHCNaginataAntiInfantryDamage") ||
		 (techName == "DEHCMonumentalArchitecture") ||
		 (techName == "YPHCAdvancedConsulateIndians") ||
		 (techName == "YPHCShipUrumiRegiment") ||
		 //(techName == "YPHCYabusameDamage") ||
                 (techName == "YPHCGurkhaAid") ||                
                 (techName == "YPHCEastIndiaCompany") ||
                 (techName == "YPHCCamelFrightening") ||
                 //(getAllyCount() > 0) && ((techName == "YPHCRainbowTrickleTeam") ||
         (techName == "YPHCInfantrySpeedHitpointsTeam") ||
		 (techName == "YPHCElephantCombatIndians") ||
		 (techName == "YPHCElephantTrampling") ||
		 (techName == "YPHCCamelDamageIndians") ||
		 (techName == "YPHCMeleeDamageIndians") ||
                 //(techName == "HCXPEarthBounty") ||
                 (techName == "HCXPCommandSkill") ||
		 (techName == "HCXPWarChiefSioux1") ||		 
		 (techName == "HCXPNewWaysSioux") ||
		 //(techName == "HCXPShipWarHutTravois1") ||
		 (techName == "HCXPCavalryDamageSioux") ||
		 (techName == "HCXPCavalryHitpointsSioux") ||
		 (techName == "HCXPCavalryCombatSioux") ||
                 (techName == "HCXPSiouxYanktonSupport") ||
                 (techName == "HCXPSiouxSanteeSupport") ||
                 (techName == "HCXPWarChiefIroquois2") ||
		 (techName == "HCXPWarChiefIroquois1") ||
		 (techName == "HCXPNewWaysIroquois") ||		 
		 (techName == "HCXPInfantryDamageIroquois") ||
		 (techName == "HCXPInfantryHitpointsIroquois") ||		 		
		 (techName == "HCXPCavalryHitpointsIroquois") ||
		 (techName == "HCXPSiegeCombat") ||		 
		 //(techName == "HCXPStoneTowers") ||
                 (techName == "HCXPWarChiefAztec1") ||
		 (techName == "HCXPKnightDamage") ||		 
		 (techName == "HCXPKnightHitpoints") ||
		 //(techName == "HCXPScorchedEarth") ||
		 //(techName == "HCXPRuthlessness") ||
		 (techName == "HCXPTempleXolotl") || 
                 ((getAllyCount() > 0) && (gNavyMap == true) && (techName == "HCCheapDocksTeam")) ||
                 ((getAllyCount() > 0) && (gNavyMap == true) && (techName == "HCFishMarketTeam")) ||
                 ((getAllyCount() > 0) && (techName == "HCMusketeerGrenadierHitpointsBritishTeam")) ||                 
		 (techName == "HCCavalryCombatBritish") ||
		 (techName == "HCMusketeerGrenadierDamageBritish") ||
		 (techName == "HCMusketeerGrenadierCombatBritish") ||
		 (techName == "HCCavalryDamageBritish") ||
		 (techName == "HCCavalryHitpointsBritish") ||
                 ((getAllyCount() > 0) && (techName == "HCRangedInfantryDamageFrenchTeam")) ||
                 (techName == "HCWildernessWarfare") ||		 
		 (techName == "HCHandCavalryHitpointsFrench") ||		                  
                 (techName == "HCJanissaryCost") ||
		 (techName == "HCJanissaryCombatOttoman") ||
		 (techName == "HCCavalryCombatOttoman") ||
		 (techName == "HCArtilleryDamageOttoman") ||
                 (techName == "HCRangedInfantryDamagePortuguese") ||
		 (techName == "HCRangedInfantryCombatPortuguese") ||
		 (techName == "HCDragoonCombatPortuguese") ||
		 (techName == "HCXPGenitours") ||
                 ((gNavyMap == true) && (techName == "HCNavigationSchool")) ||
                 (techName == "HCRoyalDecreeDutch") ||
                 //(techName == "HCDutchEastIndiaCompany") ||
		 (techName == "HCInfantryDamageDutch") ||
		 (techName == "HCInfantryCombatDutch") ||
		 (techName == "HCCavalryCombatDutch") ||
		 //((gNavyMap == false) && (techName == "HCXPMilitaryReforms")) ||		 
		 (techName == "HCBetterBanks") ||
                 (techName == "HCStreletsCombatRussian") ||
		 //(techName == "HCRansack") ||
                 ((gNavyMap == true) && (getAllyCount() > 0) && (techName == "HCColdWaterPortTeam")) ||
		 (techName == "HCSpawnStrelet") ||
		 (techName == "HCCavalryCombatRussian") ||
		 (techName == "HCUniqueCombatRussian") ||
                 (techName == "HCXPIndustrialRevolution") ||
                 //((gNavyMap == false) && (techName == "HCXPSevastopol")) ||
                 (techName == "HCDuelingSchoolTeam") ||
                 ((getAllyCount() > 0) && (techName == "HCArchaicTrainingTeam")) ||
		 (techName == "HCDuelingSchoolTeam") ||   
		 //(techName == "HCHandInfantryHitpointsSpanish")) ||   
                 //(techName == "HCHandInfantryDamageSpanishTeam")) ||
                 //(techName == "HCHandInfantryCombatSpanish") ||
                 ((gNavyMap == true) && (techName == "HCArmada")) ||
		 (techName == "HCHandCavalryCombatSpanish") ||
		 (techName == "HCCaballeros") ||
		 (techName == "HCHandCavalryDamageSpanish") ||
		 (techName == "DEHCTeaExport") ||
		 (techName == "HCHandCavalryHitpointsSpanish") ||              
		 (techName == "HCTextileMillsGerman") || 
		       (techName == "DEHCPlanTuxtepec") ||
		       (techName == "DEHCPresidialLancers") ||
		       (techName == "DEHCRefurbishedFirearms") ||
		       (techName == "DEHCMariachiTeam") ||
		       (techName == "DEHCMexicanMint") ||
		       (techName == "DEHCJalapenoPeppers") ||
		       (techName == "DEHCHabaneroPeppers") ||
		 (techName == "HCCavalryCombatGerman") ||
		 (techName == "HCCavalryHitpointsGerman") ||
		 (techName == "DEHCChasquisMessengers") ||
		 (techName == "HCXPExtensiveFortificationsAztec") ||
		 (techName == "YPHCMongolianScourge") ||
         ((getAllyCount() > 0) && (techName == "HCShipSpahisTeam")) ||
         ((getAllyCount() > 0) && (techName == "DEHCFalunMineTeam")) ||
		 //(techName == "HCSilkRoadTeam") ||
		 (techName == "HCXPAztecMining") ||
		       //(techName == "YPHCShipBerryWagon2") ||
		       //(techName == "YPHCShipGroveWagonIndians2") ||
		       (techName == "DEHCKosciuszkoFortifications") ||
		       (techName == "DEHCShipCapturedRockets") ||
		       (techName == "DEHCImmigrantsDutch") ||
			   (techName == "DEHCBuffaloSoldiers") ||
			   (techName == "DEHCKnoxArtilleryTrain") ||
		       (techName == "DEHCGermanMercenaryContracts") ||
		       (techName == "DEHCFinnhorses") ||
			   //(techName == "DEHCHandUnitDamage") ||
		       //(techName == "DEHCHandUnitHitpoints") ||
		       (techName == "DEHCHeavyInfHitpointsTeam") ||
		       (techName == "DEHCRangedCavalryCombat") ||
		       (techName == "DEHCContinentalRangers") ||
		       (techName == "DEHCSpringfieldArmory") ||
		       (techName == "DEHCLegionHungarian") ||
		       (techName == "DEHCRegularCombat") ||
     		       (techName == "DEHCTrainTimeUS") ||
     		       (techName == "DEHCCurare") ||
     		       //(techName == "DEHCChachapoyaSupport") ||
     		       (techName == "DEHCChimuSupport") ||
     		       //(techName == "DEHCCanariSupport") ||
     		       //(techName == "DEHCAymaraSupport") ||
     		       (techName == "DEHCCajamarcaSupport") ||
     		       (techName == "DEHCCollaSupport") ||
     		       (techName == "DEHCWarChiefInca1") ||
     		       (techName == "DEHCWarChiefInca2") ||
                   (techName == "HCXPNationalRedoubt") ||
                   (techName == "DEHCShipJanissariesRepeat") ||
                (techName == "HCUnlockFactory") ||
                (techName == "HCRobberBarons") ||
		       (techName == "DEHCChapultepecCastle") ||
		       (techName == "DEHCManOfDestiny") ||
		       (techName == "DEHCGuerillaTactics") ||
		       (techName == "DEHCPresidios") ||
		       (techName == "DEHCSPCLiberationMarch") ||
				//(techName == "DEHCShipLeatherCannons1") ||
                 ((gNavyMap == true) && (techName == "HCSchooners")) ||
                 ((gNavyMap == true) && (techName == "YPHCSchoonersIndians")) ||
                 ((gNavyMap == true) && (techName == "YPHCSchoonersJapanese")) ||
                 ((gNavyMap == true) && (getAllyCount() > 0) && (techName == "HCXPCheapFishingBoatTeam")) ||
                 ((getAllyCount() > 0) && (techName == "HCCavalryDamageGermanTeam")) ||                 
                 ((gNavyMap == true) && (techName == "HCCavalryDamageGermanTeam")))  
            xsArraySetInt(gCardPriorities, i, 10);
			
			/*
			// Raise priority of specific cards important to the AI. Rush version
         if (((xsArrayGetInt(gCardPriorities, i) < 5) &&
		      ((techName == "YPHCShipQiangPikeman2") ||
			   (techName == "HCXPShipTomahawk1") ||
		       (techName == "HCXPShipAennas2") ||
		       (techName == "HCXPShipAennas5") ||
		       (techName == "HCShipCrossbowmen3German") ||
               (techName == "HCXPShipMacehualtins1") ||
               (techName == "HCXPShipMacehualtins3") ||
			   (techName == "DEHCShipLeatherCannons1") ||
		       (techName == "HCExtensiveFortifications") ||
		       (techName == "HCXPExtensiveFortifications2") ||
		       (techName == "YPHCShipChuKoNu1") ||
		       (techName == "YPHCShipMandarinDuckSquad") ||
		       (techName == "HCShipCrossbowmen1") ||
		       //(techName == "HCShipPikemen1") ||
		       (techName == "YPHCShipSepoy1") ||
               //(techName == "DEHCSveaLifeguard") ||
               (techName == "DEHCShipSudaneseAllies1") ||
               (techName == "DEHCShipSudaneseAllies2") ||
               (techName == "DEHCShipSebastopolMortarTeam") ||
               (techName == "DEHCShipSebastopolMortar1") ||
               (techName == "DEHCShipSebastopolMortar2") ||
               (techName == "DEHCMercsSennarHorsemen") ||
               (techName == "DEHCMercsDahomeyAmazons") ||
               (techName == "DEHCMercsCannoneers") ||
               (techName == "YPHCShipYumi1") ||
		       (techName == "YPHCShipAshigaru2") ||
		       (techName == "HCShipCossacks4") ||
		       (techName == "HCShipStrelets1") ||
		       (techName == "HCShipUhlans1") ||
		 (techName == "HCShipSpahis3") ||
		 (techName == "HCXPShipMixedCrates2") ||
		 (techName == "YPHCShipWoodCrates2Indians") ||
                 (techName == "HCXPCapitalism") ||
				(techName == "HCShipFalconets3") ||
                   (techName == "HCShipWoodCrates3") ||
                   (techName == "ypHCShipWoodCrates2") ||
                   (techName == "ypHCShipWoodCrates4") ||
                (techName == "YPHCShipUrumiTeam") ||
                (techName == "HCShipWoodCrates3") ||
                (techName == "HCShipWoodCrates3German") ||
                //(techName == "HCShipCoinCrates3") ||
                //(techName == "HCShipCoinCrates3German") ||
                //(techName == "HCShipCoinCrates4") ||
                //(techName == "HCShipCoinCrates4German") ||
               (techName == "YPHCShipSettlersAsian2") ||
		       (techName == "YPHCShipSettlersAsian1") ||
		       (techName == "HCShipCoureurs2") ||
		       (techName == "DEHCShipVillagers4") ||
		       (techName == "HCXPShipVillagers2") ||
                (techName == "HCShipSettlers2") ||
               (techName == "HCShipSettlers4") ||
		       (techName == "HCXPShipVillagers4") ||
		       (techName == "DEHCShipVillagers2") ||
		       (techName == "DEHCShipVillagers4") ||
		       (techName == "HCXPShipVillagers2") ||
		       (techName == "HCShipCossacks4") ||
		       (techName == "HCShipStrelets1") ||
                (techName == "HCXPShipVillagers4") ||
                (techName == "HCXPShipVillagers4") ||
		       (techName == "HCXPShipVillagers4"))))
		 {
		    cardPriority = xsArrayGetInt(gCardPriorities, i);
		    if (cardPriority < 5)
		       cardPriority = 5;
		    if (cardPriority > 5)
		       cardPriority = 5;
		    xsArraySetInt(gCardPriorities, i, cardPriority);
		 }
		 */
			if (getAllyCount() > 0)
         { // Raise priority of TEAM cards when we have an ally.
            if ((xsArrayGetInt(gCardPriorities, i) < 10) && ((flags & cHCCardFlagTeam) == cHCCardFlagTeam))
            {
               cardPriority = xsArrayGetInt(gCardPriorities, i);
               if (getAllyCount() > 1)
                  cardPriority = cardPriority + 1; // +2 for 2+ allies
               else
                  cardPriority = cardPriority + 0; // +1 for 1 ally
               if (cardPriority > 10)
                  cardPriority = 10;
               xsArraySetInt(gCardPriorities, i, cardPriority);
            }
         }
         else
         { // Decrease priority of TEAM cards without ally.
            if ((xsArrayGetInt(gCardPriorities, i) > 0) && ((flags & cHCCardFlagTeam) == cHCCardFlagTeam))
            {
               cardPriority = xsArrayGetInt(gCardPriorities, i);
               cardPriority = cardPriority - 2;
               if (cardPriority < 0)
                  cardPriority = 0;
               xsArraySetInt(gCardPriorities, i, cardPriority);
            }
         }
		 
		     if (aiTreatyActive() == false)
			 {
			 if ((techName == "YPHCShipQiangPikeman2") ||
			   (techName == "HCXPShipTomahawk1") ||
		       //(techName == "HCXPShipAennas2") ||
		       (techName == "HCXPShipAennas5") ||
		       //(techName == "HCShipCrossbowmen3German") ||
               //(techName == "HCXPShipMacehualtins1") ||
               (techName == "HCXPShipMacehualtins3") ||
			   (techName == "DEHCShipLeatherCannons1") ||
		       //(techName == "HCExtensiveFortifications") ||
		       //(techName == "HCXPExtensiveFortifications2") ||
		       //(techName == "YPHCShipChuKoNu1") ||
		       (techName == "YPHCShipMandarinDuckSquad") ||
		       //(techName == "HCShipCrossbowmen1") ||
		       //(techName == "HCShipPikemen1") ||
		       (techName == "YPHCShipSepoy1") ||
               (techName == "HCXPShipLightCannon2") ||
               (techName == "DEHCShipSudaneseAllies1") ||
               (techName == "DEHCShipSudaneseAllies2") ||
               (techName == "DEHCShipSebastopolMortarTeam") ||
               //(techName == "DEHCShipSebastopolMortar1") ||
               (techName == "DEHCShipSebastopolMortar2") ||
               (techName == "DEHCMercsSennarHorsemen") ||
               (techName == "DEHCMercsDahomeyAmazons") ||
               (techName == "DEHCMercsCannoneers") ||
               (techName == "YPHCShipYumi1") ||
		       (techName == "YPHCShipAshigaru2") ||
		       (techName == "HCShipCossacks4") ||
		       (techName == "HCShipStrelets1") ||
		       (techName == "HCShipUhlans1") ||
		 (techName == "HCShipSpahis3") ||
		 (techName == "HCXPShipMixedCrates2") ||
		 (techName == "YPHCShipWoodCrates2Indians") ||
                 (techName == "HCXPCapitalism") ||
				(techName == "HCShipFalconets3") ||
                   (techName == "HCShipWoodCrates3") ||
                   (techName == "ypHCShipWoodCrates2") ||
                   (techName == "ypHCShipWoodCrates4") ||
                (techName == "YPHCShipUrumiTeam") ||
                (techName == "HCShipWoodCrates3") ||
                (techName == "HCShipWoodCrates3German") ||
                //(techName == "HCShipCoinCrates3") ||
                //(techName == "HCShipCoinCrates3German") ||
                //(techName == "HCShipCoinCrates4") ||
                //(techName == "HCShipCoinCrates4German") ||
               (techName == "YPHCShipSettlersAsian2") ||
		       (techName == "YPHCShipSettlersAsian1") ||
		       (techName == "HCShipCoureurs2") ||
		       (techName == "DEHCShipVillagers4") ||
		       (techName == "HCXPShipVillagers2") ||
                (techName == "HCShipSettlers2") ||
               (techName == "HCShipSettlers4") ||
		       (techName == "HCXPShipVillagers4") ||
		       (techName == "DEHCShipVillagers2") ||
		       (techName == "DEHCShipVillagers4") ||
		       (techName == "HCXPShipVillagers2") ||
		       (techName == "HCShipCossacks4") ||
		       (techName == "HCShipStrelets1") ||
                (techName == "HCXPShipVillagers4") ||
                (techName == "HCXPShipVillagers4") ||
		       (techName == "HCXPShipVillagers4"))
		 {
		    cardPriority = xsArrayGetInt(gCardPriorities, i);
		    if (cardPriority < 10)
		       cardPriority = 10;
		    //if (cardPriority > 5)
		    //   cardPriority = 5;
		    xsArraySetInt(gCardPriorities, i, cardPriority);
		 }
			 }
			 
			 if (aiTreatyActive() == true)
			 {
			 if /*((techName == "YPHCShipQiangPikeman2") ||
			   (techName == "HCXPShipTomahawk1") ||
		       (techName == "HCXPShipAennas2") ||
		       (techName == "HCXPShipAennas5") ||
		       (techName == "HCShipCrossbowmen3German") ||
               (techName == "HCXPShipMacehualtins1") ||
               (techName == "HCXPShipMacehualtins3") ||
			   (techName == "DEHCShipLeatherCannons1") ||
		       //(techName == "HCExtensiveFortifications") ||
		       //(techName == "HCXPExtensiveFortifications2") ||
		       (techName == "YPHCShipChuKoNu1") ||
		       (techName == "YPHCShipMandarinDuckSquad") ||
		       (techName == "HCShipCrossbowmen1") ||
		       //(techName == "HCShipPikemen1") ||
		       (techName == "YPHCShipSepoy1") ||*/
               //(techName == "DEHCSveaLifeguard") ||
               //(techName == "DEHCShipSudaneseAllies1") ||
               //(techName == "DEHCShipSudaneseAllies2") ||
               //(techName == "DEHCShipSebastopolMortarTeam") ||
               //(techName == "DEHCShipSebastopolMortar1") ||
               //(techName == "DEHCShipSebastopolMortar2") ||
               //(techName == "DEHCMercsSennarHorsemen") ||
               //(techName == "DEHCMercsDahomeyAmazons") ||
               //(techName == "DEHCMercsCannoneers") ||
               //(techName == "YPHCShipYumi1") ||
		       //(techName == "YPHCShipAshigaru2") ||
		       //(techName == "HCShipCossacks4") ||
		       //(techName == "HCShipStrelets1") ||
		       //(techName == "HCShipUhlans1") ||
		 //((techName == "HCShipSpahis3") ||
		 //((techName == "HCXPShipMixedCrates2") ||
		 //((techName == "YPHCShipWoodCrates2Indians") ||
                 ((techName == "HCXPCapitalism") ||
				//(techName == "HCXPShipLightCannon2") ||
                   //(techName == "HCShipWoodCrates3") ||
                   //(techName == "ypHCShipWoodCrates2") ||
                   //(techName == "ypHCShipWoodCrates4") ||
                //(techName == "YPHCShipUrumiTeam") ||
                //(techName == "HCShipWoodCrates3") ||
                //(techName == "HCShipWoodCrates3German") ||
                //(techName == "HCShipCoinCrates3") ||
                //(techName == "HCShipCoinCrates3German") ||
                //(techName == "HCShipCoinCrates4") ||
                //(techName == "HCShipCoinCrates4German") ||
               (techName == "YPHCShipSettlersAsian2") ||
		       (techName == "YPHCShipSettlersAsian1") ||
		       (techName == "HCShipCoureurs2") ||
		       (techName == "DEHCShipVillagers4") ||
		       (techName == "HCXPShipVillagers2") ||
                (techName == "HCShipSettlers2") ||
               (techName == "HCShipSettlers4") ||
		       (techName == "HCXPShipVillagers4") ||
		       (techName == "DEHCShipVillagers2") ||
		       (techName == "DEHCShipVillagers4") ||
		       (techName == "HCXPShipVillagers2") ||
		       //(techName == "HCShipCossacks4") ||
		       //(techName == "HCShipStrelets1") ||
                (techName == "HCXPShipVillagers4") ||
                (techName == "HCXPShipVillagers4") ||
		       (techName == "HCXPShipVillagers4"))
		 {
		    cardPriority = xsArrayGetInt(gCardPriorities, i);
		    if (cardPriority < 7)
		       cardPriority = 7;
		    if (cardPriority > 7)
		       cardPriority = 7;
		    xsArraySetInt(gCardPriorities, i, cardPriority);
		 }
			 }
			 
			 if (aiTreatyActive() == true)
			 {
			 if ((techName == "YPHCShipQiangPikeman2") ||
			   (techName == "HCXPShipTomahawk1") ||
		       (techName == "HCXPShipAennas2") ||
		       (techName == "HCXPShipAennas5") ||
		       (techName == "HCShipCrossbowmen3German") ||
               (techName == "HCXPShipMacehualtins1") ||
               (techName == "HCXPShipMacehualtins3") ||
			   (techName == "DEHCShipLeatherCannons1") ||
		       //(techName == "HCExtensiveFortifications") ||
		       //(techName == "HCXPExtensiveFortifications2") ||
		       (techName == "YPHCShipChuKoNu1") ||
		       (techName == "YPHCShipMandarinDuckSquad") ||
		       (techName == "HCShipCrossbowmen1") ||
		       (techName == "HCShipPikemen1") ||
		       (techName == "YPHCShipSepoy1") ||
               //(techName == "DEHCSveaLifeguard") ||
               //(techName == "DEHCShipSudaneseAllies1") ||
               //(techName == "DEHCShipSudaneseAllies2") ||
               //(techName == "DEHCShipSebastopolMortarTeam") ||
               //(techName == "DEHCShipSebastopolMortar1") ||
               //(techName == "DEHCShipSebastopolMortar2") ||
               //(techName == "DEHCMercsSennarHorsemen") ||
               //(techName == "DEHCMercsDahomeyAmazons") ||
               //(techName == "DEHCMercsCannoneers") ||
               (techName == "YPHCShipYumi1") ||
		       (techName == "YPHCShipAshigaru2") ||
		       (techName == "HCShipCossacks4") ||
			   (techName == "HCShipFalconets3") ||
                (techName == "HCShipCoinCrates3") ||
                (techName == "HCShipCoinCrates3German") ||
                (techName == "HCShipCoinCrates4") ||
                (techName == "HCShipCoinCrates4German") ||
		       (techName == "HCShipStrelets1") ||
		       (techName == "HCShipUhlans1") ||
		       (techName == "HCShipSpahis3"))
		 {
		    cardPriority = xsArrayGetInt(gCardPriorities, i);
		    //if (cardPriority < 4)
		    //   cardPriority = 4;
		    if (cardPriority > 4)
		       cardPriority = 4;
		    xsArraySetInt(gCardPriorities, i, cardPriority);
		 }
			 }
		 
		 if (aiTreatyActive() == true)
			 {
			 if ((techName == "HCRoyalMint") ||
		       (techName == "HCRoyalMintGerman") ||
		       (techName == "YPHCRoyalMintIndians") ||
		       (techName == "HCXPChinampa1") ||
		       (techName == "HCXPChinampa2") ||
		       (techName == "HCFoodSilos") ||
		       (techName == "HCFoodSilosTeam") ||
		       (techName == "YPHCFoodSilosIndians") ||
		       (techName == "HCSustainableAgriculture") ||
		       (techName == "HCSustainableAgricultureGerman") ||
		       (techName == "YPHCSustainableAgricultureIndians") ||
		       (techName == "HCGrainMarket") ||
		       (techName == "HCRumDistillery") ||
		       (techName == "HCRumDistilleryTeam") ||
		       (techName == "HCRumDistilleryGerman") ||
		       (techName == "YPHCRumDistilleryIndians") ||
		       (techName == "HCTextileMills") ||
		       (techName == "HCTextileMillsGerman") ||
		       (techName == "HCCigarRoller") ||
		       (techName == "HCCigarRollerGerman") ||
		       (techName == "DEHCKilishiJerky") ||
		       (techName == "DEHCHegemony") ||
		       (techName == "DEHCShipInfluenceInfinite2") ||
		       (techName == "cTechDEHCCequeSystem") ||
		       (techName == "YPHCShipRicePaddyWagon1") ||
		       (techName == "YPHCShipRicePaddyWagon2") ||
		       (techName == "YPHCShipRicePaddyWagon3") ||
		       (techName == "DEHCMinneapolisMills") ||
		       (techName == "DEHCLumberMills") ||
		       (techName == "HCSustainableAgriculture") ||
		       (techName == "HCSustainableAgriculture") ||
		       (techName == "HCSustainableAgriculture") ||
		       (techName == "YPHCMercsRattanShield3") ||
		       (techName == "YPHCAdvancedWonders") ||
		       (techName == "HCXPZapotecAlliesRepeat") ||
		       (techName == "HCXPCherokeeAlliesRepeat") ||
		       (techName == "DEHCCaribAlliesRepeat") ||
		       (techName == "HCXPHuronAlliesRepeat") ||
		       (techName == "DEHCSPCShipSebastopolMortarRepeat1") ||
		       (techName == "HCMercenaryCombatGerman") ||
		       (techName == "HCXPShipCannonsRepeat") ||
		       (techName == "DEHCShipSebastopolMortarRepeat") ||
		       (techName == "HCXPTupiAlliesRepeat") ||
		       (techName == "YPHCMercsWarElephant1") ||
		       (techName == "YPHCShipUrumi2") ||
		       (techName == "YPHCEngineeringSchoolTeam") ||
		       (techName == "YPHCShipNaginataRider1") ||
		       (techName == "DEHCComancheAlliesRepeat") ||
		       (techName == "DEHCCreeAlliesRepeat") ||
		       (techName == "HCXPBuffalo2") ||
		       (techName == "HCXPNootkaAlliesRepeat") ||
		       (techName == "HCXPMayanAlliesRepeat") ||
		       (techName == "DEHCCaribAlliesRepeat") ||
		       (techName == "DEHCPoker") ||
		       (techName == "YPHCMercsRattanShield3") ||
               (techName == "DEHCSveaLifeguard") ||
		       (techName == "HCXPEconomicTheory") ||
		       (techName == "DEHCCoffeeConsumption") ||
		       (techName == "HCXPExtensiveFortifications2") ||
               (techName == "DEHCSveaLifeguard") ||
		       (techName == "HCRefrigeration") ||
		       (techName == "DEHCAltaCalifornia") ||
		       //(techName == "DEHCHidalgoLand") ||
		       (techName == "HCRefrigerationGerman"))
		 {
		    cardPriority = xsArrayGetInt(gCardPriorities, i);
		    if (cardPriority < 10)
		       cardPriority = 10;
		    //if (cardPriority > 5)
		    //   cardPriority = 5;
		    xsArraySetInt(gCardPriorities, i, cardPriority);
		 }
			 }
			 
			 if (aiTreatyActive() == false)
			 {
			 if ((techName == "HCRoyalMint") ||
		       (techName == "HCRoyalMintGerman") ||
		       (techName == "YPHCRoyalMintIndians") ||
		       (techName == "HCXPChinampa1") ||
		       (techName == "HCXPChinampa2") ||
		       (techName == "HCFoodSilos") ||
		       (techName == "HCFoodSilosTeam") ||
		       (techName == "YPHCFoodSilosIndians") ||
		       (techName == "HCSustainableAgriculture") ||
		       (techName == "HCSustainableAgricultureGerman") ||
		       (techName == "YPHCSustainableAgricultureIndians") ||
		       (techName == "HCGrainMarket") ||
		       (techName == "HCRumDistillery") ||
		       (techName == "HCRumDistilleryTeam") ||
		       (techName == "HCRumDistilleryGerman") ||
		       (techName == "YPHCRumDistilleryIndians") ||
		       (techName == "HCTextileMills") ||
		       (techName == "HCTextileMillsGerman") ||
		       (techName == "HCCigarRoller") ||
		       (techName == "HCCigarRollerGerman") ||
		       (techName == "DEHCKilishiJerky") ||
		       (techName == "DEHCHegemony") ||
		       (techName == "DEHCShipInfluenceInfinite2") ||
		       (techName == "cTechDEHCCequeSystem") ||
		       (techName == "YPHCShipRicePaddyWagon1") ||
		       (techName == "YPHCShipRicePaddyWagon2") ||
		       (techName == "YPHCShipRicePaddyWagon3") ||
		       (techName == "DEHCMinneapolisMills") ||
		       (techName == "DEHCLumberMills") ||
		       (techName == "HCSustainableAgriculture") ||
		       (techName == "HCSustainableAgriculture") ||
		       (techName == "HCSustainableAgriculture") ||
		       //(techName == "YPHCMercsRattanShield3") ||
		       (techName == "YPHCAdvancedWonders") ||
		       (techName == "HCXPZapotecAlliesRepeat") ||
		       (techName == "HCXPCherokeeAlliesRepeat") ||
		       (techName == "DEHCCaribAlliesRepeat") ||
		       (techName == "HCXPHuronAlliesRepeat") ||
		       (techName == "DEHCSPCShipSebastopolMortarRepeat1") ||
		       (techName == "HCMercenaryCombatGerman") ||
		       (techName == "HCXPShipCannonsRepeat") ||
		       (techName == "DEHCShipSebastopolMortarRepeat") ||
		       (techName == "HCXPTupiAlliesRepeat") ||
		       (techName == "YPHCMercsWarElephant1") ||
		       (techName == "YPHCShipUrumi2") ||
		       (techName == "YPHCEngineeringSchoolTeam") ||
		       (techName == "YPHCShipNaginataRider1") ||
		       (techName == "DEHCComancheAlliesRepeat") ||
		       (techName == "DEHCCreeAlliesRepeat") ||
		       (techName == "HCXPBuffalo2") ||
		       (techName == "HCXPNootkaAlliesRepeat") ||
		       (techName == "HCXPMayanAlliesRepeat") ||
		       (techName == "DEHCCaribAlliesRepeat") ||
		       (techName == "DEHCPoker") ||
		       //(techName == "YPHCMercsRattanShield3") ||
               //(techName == "DEHCSveaLifeguard") ||
		       (techName == "HCXPEconomicTheory") ||
		       (techName == "DEHCCoffeeConsumption") ||
		       (techName == "HCXPExtensiveFortifications2") ||
               //(techName == "DEHCSveaLifeguard") ||
		       (techName == "HCRefrigeration") ||
		       (techName == "DEHCAltaCalifornia") ||
		       //(techName == "DEHCHidalgoLand") ||
		       (techName == "HCRefrigerationGerman"))
		 {
		    cardPriority = xsArrayGetInt(gCardPriorities, i);
		    if (cardPriority < 8)
		       cardPriority = 8;
		    if (cardPriority > 8)
		       cardPriority = 8;
		    xsArraySetInt(gCardPriorities, i, cardPriority);
		 }
		 }
		 
         if ((aiGetWorldDifficulty() >= cDifficultySandbox) &&
		     ((xsArrayGetInt(gCardPriorities, i) >= 1) &&
		      ((techName == "HCFrontierDefenses2") ||
	           (techName == "HCShipCoveredWagons2") ||
	           (techName == "HCConestogaWagonsTeam") ||
	           (techName == "HCBastionsTeam") ||
	           (techName == "HCShipHussars1") ||
	           //(techName == "HCUnlockFortVauban") ||
	           //(techName == "HCXPUnlockFort2") ||
	           //(techName == "HCXPUnlockFort2German") ||
	           (techName == "HCShipFalconets1German") ||
	           (techName == "HCShipMortars1") ||
	           (techName == "HCShipPikemen1") ||
	           (techName == "HCMosqueConstruction") ||
	           (techName == "DEHCShipBolasWarriorsRepeat") ||
	           (techName == "DEHCShipIncaRunnersRepeat") ||
	           (techName == "HCShipMortars2") ||
				(techName == "HCHandInfantryHitpointsSpanish") || 
                (techName == "HCHandInfantryDamageSpanishTeam") ||
                (techName == "HCHandInfantryCombatSpanish") ||
	           (techName == "HCXPSuvorovReforms") ||
	           (techName == "YPHCBannerReforms") ||
	           (techName == "DEHCShipFatLlamas1") ||
	           (techName == "YPHCSpawnSaigaHerd") ||
	           (techName == "HCXPWarChiefSioux2") ||
	           (techName == "HCNativeCombat") ||
	           (techName == "HCNativeTreaties") ||
	           (techName == "DEHCImmigrantsIrish") ||
		       (techName == "DEHCLongRifles") ||
	           (techName == "HCNativeTreatiesGerman") ||
	           (techName == "DEHCShipDragoonsRepeat") ||
	           (techName == "HCShipMortars1German") ||
	           (techName == "HCShipMortars2German") ||
	           (techName == "HCShipMortarsTeam") ||
	           (techName == "HCXPShipPetards1") ||
	           (techName == "HCXPShipDemolitionSquadGerman") ||
	           (techName == "HCXPShipRams1") ||
	           (techName == "HCXPIroquoisMohawkSupport") ||
	           (techName == "HCXPShipSiege") ||
	           (techName == "HCXPShipSpies1") ||
	           (techName == "HCXPShipSpies2") ||
	           (techName == "HCXPShipSpies3") ||
	           (techName == "HCXPShipSpies1German") ||
	           (techName == "HCXPShipSpiesTeam") ||
	           (techName == "HCXPGreatTempleTezcatlipoca") ||
	           (techName == "HCXPShipBears") ||
	           (techName == "HCXPShipBearsTeam") ||
	           (techName == "HCHouseEstates") ||
	           (techName == "HCXPShipCougars") ||
	           (techName == "HCXPShipCoyotes") ||
	           (techName == "HCXPShipCoyotesTeam") ||
	           (techName == "HCXPShipGrizzlies") ||
	           (techName == "HCXPShipJaguars1") ||
	           (techName == "HCXPShipJaguars2") ||
	           (techName == "HCXPShipJaguars3") ||
	           (techName == "HCXPShipJaguarsTeam") ||
	           (techName == "HCXPShipWolves") ||
	           (techName == "HCXPWarChiefIroquois2") ||
	           (techName == "HCXPCoinCratesAztec1") ||
	           (techName == "HCXPCoinCratesAztec2") ||
	           (techName == "HCXPCoinCratesAztec3") ||
	           (techName == "HCXPCoinCratesAztec4") ||
	           (techName == "HCXPCoinCratesAztec5") ||
	           (techName == "HCXPShipMixedCrates4") ||
               (techName == "YPHCShipMonitorLizard1") ||
               (techName == "YPHCShipMonitorLizard2") ||
	           (techName == "YPHCShipWoodCratesInf1Indians") ||
	           (techName == "YPHCShipWoodCratesInf2Indians") ||
	           (techName == "YPHCShipWoodCratesInf3Indians") ||
	           (techName == "YPHCShipWoodCratesInf4Indians") ||
	           (techName == "YPHCShipCoveredWagonsChina") ||
	           (techName == "YPHCShipCoveredWagons2Indians") ||
	           (techName == "YPHCSacredFieldHealing") ||
	           (techName == "YPHCBazaar") ||
	           (techName == "YPHCExpandedMarket") ||
	           (techName == "YPHCCommoditiesMarket") ||
	           (techName == "YPHCAdvancedMonastery") ||
	           (techName == "YPHCAdvancedMonasteryIndians") ||
		  	   (techName == "YPHCShipRhino1") ||
	           (techName == "HCXPSilentStrike") ||
	           (techName == "HCXPDanceHall") ||
	           (techName == "DEHCShipWoodCratesInfInca") ||
	           //(techName == "DEHCMachuPicchu") ||
	           (techName == "HCXPDanceHallGerman") ||
			   (techName == "HCEarlyDragoonsTeam") ||
	           //(techName == "YPHCShipBerryWagon1") ||
	           //(techName == "YPHCShipBerryWagon2") ||
			   (techName == "YPHCShipSettlersAsian1") ||
	           (techName == "YPHCShipMongolScoutTeam") ||
	           //(techName == "YPHCShipRicePaddyWagon1") ||
	           //(techName == "YPHCShipRicePaddyWagon2") ||
	           //(techName == "YPHCShipRicePaddyWagon3") ||
	           (techName == "YPHCShipMorutaru1") ||
			   (techName == "HCFatterSheepTeam") ||
			   (techName == "HCShipFoodCrates1") ||
			   (techName == "HCShipCoinCrates1") ||
			   (techName == "HCXPBuffaloTeam") ||
			   (techName == "HCXPAdoption") ||
			   //(techName == "DEHCSeasonalLaborTeam") ||
			   (techName == "YPHCSpawnRefugees1") ||
			   (techName == "YPHCSpawnRefugees2") ||
			   (techName == "YPHCSpawnMigrants1") ||
			   (techName == "HCXPShipTradingPostTravois") ||
			   (techName == "HCXPShipDogsoldiers3") ||
		       (techName == "HCXPTownDance") ||
		       (techName == "HCXPShipAxeRidersRepeat") ||
			   (techName == "HCXPScorchedEarth") ||
			   (techName == "HCXPImprovedGrenades") ||
			   (techName == "HCShipSurgeons") ||
			   (techName == "HCXPRuthlessness") ||
			   (techName == "HCShipBandeirantes") ||
		       (techName == "HCXPGreatHunter") ||
	           (techName == "YPHCShipMorutaru2"))))
         { // Decrease priority of specific cards to be avoided.
            cardPriority = xsArrayGetInt(gCardPriorities, i);
            cardPriority = cardPriority - 4;
            if (cardPriority < 0)
               cardPriority = 0;
            xsArraySetInt(gCardPriorities, i, cardPriority);
         }
         else if ((aiGetWorldDifficulty() >= cDifficultyModerate) &&
                  ((xsArrayGetInt(gCardPriorities, i) >= 6) && (tech == cTechHCXPCoinCratesAztec2)))
         { // Slightly decrease priority of other specific cards if rated too highly.
            cardPriority = xsArrayGetInt(gCardPriorities, i);
            cardPriority = cardPriority - 1;
            xsArraySetInt(gCardPriorities, i, cardPriority);
         }
         else if ((aiGetWorldDifficulty() >= cDifficultyModerate) && (aiHCCardsGetCardAgePrereq(i) >= cAge3))
         { // Decrease priority of archaic soldier cards from age 3 and up.
            if ((xsArrayGetInt(gCardPriorities, i) >= 1) && ((aiHCCardsGetCardUnitType(i) == cUnitTypePikeman) ||
            (aiHCCardsGetCardUnitType(i) == cUnitTypeCrossbowman) ||
            (aiHCCardsGetCardUnitType(i) == cUnitTypeLongbowman) ||
            (aiHCCardsGetCardUnitType(i) == cUnitTypeStrelet) ||
            (aiHCCardsGetCardUnitType(i) == cUnitTypeypYumi) ||
            (aiHCCardsGetCardUnitType(i) == cUnitTypeypQiangPikeman) ||
            (aiHCCardsGetCardUnitType(i) == cUnitTypeAbstractHealer) ||
            (aiHCCardsGetCardUnitType(i) == cUnitTypeAbstractPet) ||
            (aiHCCardsGetCardUnitType(i) == cUnitTypeypChuKoNu)))
            {
               cardPriority = xsArrayGetInt(gCardPriorities, i);
               cardPriority = cardPriority - 3;
               if (cardPriority < 0)
                  cardPriority = 0;
               xsArraySetInt(gCardPriorities, i, cardPriority);
            }
         }
			if ((xsArrayGetInt(gCardPriorities, i) >= 1) && ((aiHCCardsGetCardUnitType(i) == cUnitTypeAbstractHealer) ||
                                                             (aiHCCardsGetCardUnitType(i) == cUnitTypeAbstractPet)))
            {
               cardPriority = xsArrayGetInt(gCardPriorities, i);
               cardPriority = cardPriority - 4;
               if (cardPriority < 0)
                  cardPriority = 0;
               xsArraySetInt(gCardPriorities, i, cardPriority);
            }
		 if (aiHCCardsGetCardAgePrereq(i) >= cAge3)
		 {  // Decrease priority of archaic soldier cards from age 3 and up.
		    if ((xsArrayGetInt(gCardPriorities, i) >= 1) &&
			    ((aiHCCardsGetCardUnitType(i) == cUnitTypePikeman) ||
		         (aiHCCardsGetCardUnitType(i) == cUnitTypeCrossbowman) ||
		         (aiHCCardsGetCardUnitType(i) == cUnitTypeLongbowman) ||
		         (aiHCCardsGetCardUnitType(i) == cUnitTypeStrelet) ||
		         (aiHCCardsGetCardUnitType(i) == cUnitTypeypYumi) ||
		         (aiHCCardsGetCardUnitType(i) == cUnitTypeDragoon) ||
		         (aiHCCardsGetCardUnitType(i) == cUnitTypeypSiegeElephant) ||
		         (aiHCCardsGetCardUnitType(i) == cUnitTypeypQiangPikeman) ||
		         (aiHCCardsGetCardUnitType(i) == cUnitTypeypChuKoNu)))
			{
		    cardPriority = xsArrayGetInt(gCardPriorities, i);
		    cardPriority = cardPriority - 3;
		    if (cardPriority < 0)
		       cardPriority = 0;
		    xsArraySetInt(gCardPriorities, i, cardPriority);
			}
		 }
		 if ((xsArrayGetInt(gCardPriorities, i) >= 1) &&
			    ((aiHCCardsGetCardUnitType(i) == cUnitTypeAbstractHealer) ||
		         (aiHCCardsGetCardUnitType(i) == cUnitTypeAbstractPet) ||
		         (aiHCCardsGetCardUnitType(i) == cUnitTypedeMaceman) ||
		         (aiHCCardsGetCardUnitType(i) == cUnitTypexpSkullKnight) ||
		         (aiHCCardsGetCardUnitType(i) == cUnitTypedeShotelWarrior) ||
		         (aiHCCardsGetCardUnitType(i) == cUnitTypedeOromoWarrior) ||
		         (aiHCCardsGetCardUnitType(i) == cUnitTypeypRajput) ||
		         (aiHCCardsGetCardUnitType(i) == cUnitTypedeRifleman) ||
		         (aiHCCardsGetCardUnitType(i) == cUnitTypeSurgeon)))
			{
		    cardPriority = xsArrayGetInt(gCardPriorities, i);
		    cardPriority = cardPriority - 6;
		    if (cardPriority < 0)
		       cardPriority = 0;
		    xsArraySetInt(gCardPriorities, i, cardPriority);
			}
			/*
			if (((xsArrayGetInt(gCardPriorities, i) < 10) &&
		      ((techName == "HCRoyalMint") ||
		       (techName == "HCRoyalMintGerman") ||
		       (techName == "YPHCRoyalMintIndians") ||
		       (techName == "HCXPChinampa1") ||
		       (techName == "HCXPChinampa2") ||
		       (techName == "HCFoodSilos") ||
		       (techName == "HCFoodSilosTeam") ||
		       (techName == "YPHCFoodSilosIndians") ||
		       (techName == "HCSustainableAgriculture") ||
		       (techName == "HCSustainableAgricultureGerman") ||
		       (techName == "YPHCSustainableAgricultureIndians") ||
		       (techName == "HCGrainMarket") ||
		       (techName == "HCRumDistillery") ||
		       (techName == "HCRumDistilleryTeam") ||
		       (techName == "HCRumDistilleryGerman") ||
		       (techName == "YPHCRumDistilleryIndians") ||
		       (techName == "HCTextileMills") ||
		       (techName == "HCTextileMillsGerman") ||
		       (techName == "HCCigarRoller") ||
		       (techName == "HCCigarRollerGerman") ||
		       (techName == "DEHCKilishiJerky") ||
		       (techName == "DEHCHegemony") ||
		       (techName == "DEHCShipInfluenceInfinite") ||
		       (techName == "cTechDEHCCequeSystem") ||
		       (techName == "YPHCShipRicePaddyWagon1") ||
		       (techName == "YPHCShipRicePaddyWagon2") ||
		       (techName == "YPHCShipRicePaddyWagon3") ||
		       (techName == "DEHCMinneapolisMills") ||
		       (techName == "DEHCLumberMills") ||
		       (techName == "HCSustainableAgriculture") ||
		       (techName == "HCSustainableAgriculture") ||
		       (techName == "HCSustainableAgriculture") ||
		       (techName == "YPHCMercsRattanShield3") ||
		       (techName == "YPHCAdvancedWonders") ||
		       (techName == "HCXPZapotecAlliesRepeat") ||
		       (techName == "HCXPCherokeeAlliesRepeat") ||
		       (techName == "DEHCCaribAlliesRepeat") ||
		       (techName == "HCXPHuronAlliesRepeat") ||
		       (techName == "DEHCSPCShipSebastopolMortarRepeat1") ||
		       (techName == "HCMercenaryCombatGerman") ||
		       (techName == "HCXPShipCannonsRepeat") ||
		       (techName == "HCXPAdvancedScouts") ||
		       (techName == "HCXPTupiAlliesRepeat") ||
		       (techName == "YPHCMercsWarElephant1") ||
		       (techName == "YPHCShipUrumi2") ||
		       (techName == "YPHCShipNaginataRider1") ||
		       (techName == "DEHCComancheAlliesRepeat") ||
		       (techName == "DEHCCreeAlliesRepeat") ||
		       (techName == "HCXPBuffalo2") ||
		       (techName == "HCXPNootkaAlliesRepeat") ||
		       (techName == "HCXPMayanAlliesRepeat") ||
		       (techName == "DEHCCaribAlliesRepeat") ||
		       (techName == "DEHCPoker") ||
		       (techName == "YPHCMercsRattanShield3") ||
               (techName == "DEHCSveaLifeguard") ||
		       (techName == "HCXPEconomicTheory") ||
		       (techName == "DEHCCoffeeConsumption") ||
		       (techName == "HCXPExtensiveFortifications2") ||
               (techName == "DEHCSveaLifeguard") ||
		       (techName == "HCRefrigeration") ||
		       (techName == "HCRefrigerationGerman"))))
		 {
		    cardPriority = xsArrayGetInt(gCardPriorities, i);
		    if (cardPriority < 7)
		       cardPriority = 7;
		    cardPriority = cardPriority + 1;
		    if (cardPriority > 10)
		       cardPriority = 10;
		    xsArraySetInt(gCardPriorities, i, cardPriority);
		 }
		 /*
		/*
         if (btBiasNative >= 0.5)
         { // Raise priority of native related cards when we have a native bias.
            if ((xsArrayGetInt(gCardPriorities, i) < 10) && (tech == cTechHCXPBloodBrothers) ||
                (tech == cTechHCXPBloodBrothersGerman) || (tech == cTechHCNativeLore) ||
                (tech == cTechHCNativeLoreGerman) || (tech == cTechHCNativeTreaties) ||
                (tech == cTechHCNativeTreatiesGerman) || (tech == cTechHCNativeWarriors) ||
                (tech == cTechHCNativeWarriorsGerman) || (tech == cTechHCNativeCombat) ||
                (tech == cTechHCNativeCombatTeam) ||
                //(tech == cTechYPHCNativeTradeTax) ||
                //(tech == cTechYPHCNativeTradeTaxIndians) ||
                (tech == cTechYPHCNativeLearning) || (tech == cTechYPHCNativeLearningIndians) ||
                (tech == cTechYPHCNativeDamage) || (tech == cTechYPHCNativeDamageIndians) ||
                (tech == cTechYPHCNativeHitpoints) || (tech == cTechYPHCNativeHitpointsIndians) ||
                (tech == cTechYPHCNativeIncorporation) || (tech == cTechYPHCNativeIncorporationIndians) ||
                (tech == cTechHCWildernessWarfare) || (tech == cTechHCXPBlackArrow) ||
                (tech == cTechHCNativeChampionsDutchTeam))
            {
               cardPriority = xsArrayGetInt(gCardPriorities, i);
               cardPriority = cardPriority + 1;
               if (cardPriority > 10)
                  cardPriority = 10;
               xsArraySetInt(gCardPriorities, i, cardPriority);
            }
         }
         else if (btBiasNative <= -0.5)
         { // Decrease priority of native related cards when we have a native aversion.
            if ((xsArrayGetInt(gCardPriorities, i) > 0) && (tech == cTechHCXPBloodBrothers) ||
                (tech == cTechHCXPBloodBrothersGerman) || (tech == cTechHCNativeLore) ||
                (tech == cTechHCNativeLoreGerman) || (tech == cTechHCNativeTreaties) ||
                (tech == cTechHCNativeTreatiesGerman) || (tech == cTechHCNativeWarriors) ||
                (tech == cTechHCNativeWarriorsGerman) || (tech == cTechHCNativeCombat) ||
                (tech == cTechHCNativeCombatTeam) || (tech == cTechYPHCNativeTradeTax) ||
                (tech == cTechYPHCNativeTradeTaxIndians) || (tech == cTechYPHCNativeLearning) ||
                (tech == cTechYPHCNativeLearningIndians) || (tech == cTechYPHCNativeDamage) ||
                (tech == cTechYPHCNativeDamageIndians) || (tech == cTechYPHCNativeHitpoints) ||
                (tech == cTechYPHCNativeHitpointsIndians) || (tech == cTechYPHCNativeIncorporation) ||
                (tech == cTechYPHCNativeIncorporationIndians) ||
                //(tech == cTechHCWildernessWarfare) ||
                (tech == cTechHCXPBlackArrow) || (tech == cTechHCNativeChampionsDutchTeam))
            {
               cardPriority = xsArrayGetInt(gCardPriorities, i);
               cardPriority = cardPriority - 1;
               if (cardPriority < 0)
                  cardPriority = 0;
               xsArraySetInt(gCardPriorities, i, cardPriority);
            }
         }
		*/
         /*if (btBiasTrade >= 0.5)
          {  // Raise priority of trade related cards when we have a trade bias.
              if ((xsArrayGetInt(gCardPriorities, i) < 10) &&
               //(unit == cUnitTypeypTradingPostWagon) ||
               //(unit == cUnitTypeTradingPostTravois) ||
                 //(tech == cTechYPHCExpandedTradingPost) ||
                 //(tech == cTechYPHCExpandedTradingPostIndians) ||
                 //(tech == cTechHCXPShipTradingPostTravois) ||
                 //(tech == cTechDEHCShipTamboTravois) ||
                 (tech == cTechDEHCAdvancedTambos) ||
                 (tech == cTechHCAdvancedTradingPost) ||
                 (tech == cTechHCCheapTradingPostTeam))
            {
               cardPriority = xsArrayGetInt(gCardPriorities, i);
               cardPriority = cardPriority + 1;
               if (cardPriority > 10)
                  cardPriority = 10;
               xsArraySetInt(gCardPriorities, i, cardPriority);
            }
          }
         else if (btBiasTrade <= -0.5)
         { // Decrease priority of trade related cards when we have a trade aversion.
            if ((xsArrayGetInt(gCardPriorities, i) > 0) && (unit == cUnitTypeypTradingPostWagon) ||
                (unit == cUnitTypeTradingPostTravois) || (tech == cTechYPHCExpandedTradingPost) ||
                (tech == cTechYPHCExpandedTradingPostIndians) ||
                //(tech == cTechHCXPShipTradingPostTravois) ||
                (tech == cTechDEHCShipTamboTravois) || (tech == cTechDEHCAdvancedTambos) ||
                (tech == cTechHCAdvancedTradingPost) || (tech == cTechHCCheapTradingPostTeam))
            {
               cardPriority = xsArrayGetInt(gCardPriorities, i);
               cardPriority = cardPriority - 1;
               if (cardPriority < 0)
                  cardPriority = 0;
               xsArraySetInt(gCardPriorities, i, cardPriority);
            }
         }
		 */
         // Raise priority of specific important cards.
         if ((aiGetWorldDifficulty() >= cDifficultyModerate) &&
             ((xsArrayGetInt(gCardPriorities, i) < 10) &&
              ((tech == cTechHCXPEconomicTheory) || (tech == cTechYPHCEconomicTheoryAsia) ||
               (tech == cTechHCAdvancedArsenal) || (tech == cTechHCAdvancedArsenalGerman) ||
               (tech == cTechHCXPNewWaysIroquois) || (tech == cTechHCXPNewWaysSioux) ||
               /*(tech == cTechYPHCSpawnRefugees1) || (tech == cTechYPHCShipBerryWagon2) ||
               (tech == cTechYPHCShipGroveWagonIndians2) ||*/ (tech == cTechYPHCShipShogunate))))
         {
            cardPriority = xsArrayGetInt(gCardPriorities, i);
            if (cardPriority < 5)
               cardPriority = 5;
            cardPriority = cardPriority + 2;
            if (cardPriority > 10)
               cardPriority = 10;
            xsArraySetInt(gCardPriorities, i, cardPriority);
         }
         // Raise priority of specific cards important to the AI.
         if ((aiGetWorldDifficulty() >= cDifficultyModerate) &&
             ((xsArrayGetInt(gCardPriorities, i) < 10) &&
              ((tech == cTechHCRobberBarons) || (tech == cTechHCRobberBaronsGerman) ||
               (tech == cTechHCXPIndustrialRevolution) || (tech == cTechHCXPIndustrialRevolutionGerman) ||
               (tech == cTechHCUnlockFactory) || (tech == cTechHCUnlockFactoryGerman) || //(tech == cTechHCXPBankWagon) ||
               (tech == cTechHCBanks1) || (tech == cTechHCBanks2) || (tech == cTechHCBetterBanks) ||
               (tech == cTechDEHCChichaBrewing) || ((flags & cHCCardFlagTrickleGold) == cHCCardFlagTrickleGold) ||
               ((flags & cHCCardFlagTrickleWood) == cHCCardFlagTrickleWood) ||
               ((flags & cHCCardFlagTrickleFood) == cHCCardFlagTrickleFood) ||
               //((flags & cHCCardFlagGatherRate) == cHCCardFlagGatherRate) ||
               //(tech == cTechHCXPEarthBounty) || //(tech == cTechYPHCRainbowTrickle) ||
               //(tech == cTechYPHCRainbowTrickleIndians) || (tech == cTechYPHCRainbowTrickleTeam) ||
               (tech == cTechHCXPCapitalism) || (tech == cTechHCXPDistributivism) || (tech == cTechYPHCAgrarianism) ||
               (tech == cTechYPHCForeignLogging) || (tech == cTechDEHCGidanSarkin))))
         {
            cardPriority = xsArrayGetInt(gCardPriorities, i);
            if (cardPriority < 6)
               cardPriority = 6;
            cardPriority = cardPriority + 1;
            if (cardPriority > 10)
               cardPriority = 10;
            xsArraySetInt(gCardPriorities, i, cardPriority);
         }
         // Slightly raise priority of specific cards when not rated highly.
         else if ((aiGetWorldDifficulty() >= cDifficultyModerate) &&
                  ((xsArrayGetInt(gCardPriorities, i) < 7) &&
                   ((tech == cTechHCRoyalDecreeBritish) || (tech == cTechHCRoyalDecreeDutch) ||
                    (tech == cTechHCRoyalDecreeFrench) || (tech == cTechHCRoyalDecreeGerman) ||
                    (tech == cTechHCRoyalDecreeOttoman) || (tech == cTechHCRoyalDecreePortuguese) ||
                    (tech == cTechHCRoyalDecreeRussian) || (tech == cTechHCRoyalDecreeSpanish) ||
                    (tech == cTechDEHCCequeSystem) || (tech == cTechDEHCCurare) || (tech == cTechDEHCRoadBuilding) ||
                    (tech == cTechDEHCHuankaSupport) || (tech == cTechDEHCMonumentalArchitecture) ||
                    (tech == cTechDEHCResettlements) || (tech == cTechDEHCMeleeInfCombatInca) ||
                    (tech == cTechDEHCRangedInfDamageInca) || (tech == cTechDEHCRangedInfHitpointsInca) ||
                    /*(tech == cTechDEHCMachuPicchu) ||*/ (tech == cTechDEHCTerraceFarming) ||
                    //(tech == cTechHCXPWaterDance) ||
                    (tech == cTechDEHCFloatingIslands) || (tech == cTechDEHCChinchaSupport) ||
                    (tech == cTechDEHCTupiAllies1) || (tech == cTechDEHCShipWoodCratesInfInca) ||
                    (tech == cTechYPHCIncreasedTribute))))
         {
            cardPriority = xsArrayGetInt(gCardPriorities, i);
            if (cardPriority < 5)
               cardPriority = 5;
            cardPriority = cardPriority + 1;
            if (cardPriority > 10)
               cardPriority = 10;
            xsArraySetInt(gCardPriorities, i, cardPriority);
         }
         if (kbGetAge() > aiHCCardsGetCardAgePrereq(i))
         { // Decrease priority of cards with lower required age than us (higher starting age).
            if (xsArrayGetInt(gCardPriorities, i) > 0)
            {
               cardPriority = xsArrayGetInt(gCardPriorities, i);
               cardPriority = cardPriority - 1;
               if (cardPriority < 0)
                  cardPriority = 0;
               xsArraySetInt(gCardPriorities, i, cardPriority);
            }
         }
         // Set priority for water map related units and upgrades to 0 on land maps.
         if ((gNavyMap == false) &&
             (((flags & cHCCardFlagWater) == cHCCardFlagWater) || (tech == cTechHCCoastalDefensesTeam) ||
              (tech == cTechHCNavalCombat) || (tech == cTechHCNavalCombatGerman) ||
              (tech == cTechYPHCNavalCombatTeam) || (tech == cTechYPHCNavalCombatIndians) ||
              //(tech == cTechHCAdmirality) || (tech == cTechHCAdmiralityGerman) ||
              /*(tech == cTechYPHCAdmiralityIndians) ||*/ (tech == cTechHCFishMarket) || (tech == cTechHCFishMarketTeam) ||
              (tech == cTechHCFishMarketGerman) || (tech == cTechYPHCFishMarketIndians) ||
              (tech == cTechypHCFishMarket) || (tech == cTechHCRenderingPlant) ||
              (tech == cTechHCRenderingPlantGerman) || (tech == cTechYPHCRenderingPlantIndians) ||
              (tech == cTechHCCoastalDefensesTeam) ||
              (kbProtoUnitIsType(cMyID, unit, cUnitTypeAbstractWarShip) == true) ||
              (kbProtoUnitIsType(cMyID, unit, cUnitTypeAbstractFishingBoat) == true)))
            xsArraySetInt(gCardPriorities, i, 0);
         if ((cMyCiv == cCivSPCJapanese) || (cMyCiv == cCivSPCJapaneseEnemy))
         {
            if ((tech == cTechYPHCShipDaimyoAizu) || (tech == cTechYPHCShipDaimyoSatsuma) ||
                (tech == cTechYPSPCHCShipDaimyoKiyomasa) || (tech == cTechYPSPCHCShipDaimyoMasamune) ||
                (tech == cTechYPSPCHCShipDaimyoTadaoki))
            {
               xsArraySetInt(gCardPriorities, i, 0); // BHG: don't want spcjapanese sending in unapproved daimyos
            }
         }
         if (cMyCiv == cCivSPCIndians)
         {
            if ((tech == cTechYPHCShipSepoy1) || (tech == cTechYPHCShipSepoy2) || (tech == cTechYPHCShipSepoy3) ||
                (tech == cTechYPHCShipSepoy4))
            {
               xsArraySetInt(gCardPriorities, i, 0); // BHG: don't want spcindians sending in unapproved sepoys
            }
         }
		 
         if (aiHCCardsIsCardBought(i) == true)
            xsArraySetString(gCardStates, i, "P"); // Purchased
         else
         {
            if (aiHCCardsCanIBuyThisCard(-1, i) == true)
               xsArraySetString(gCardStates, i, "A"); // Available
            else
               xsArraySetString(gCardStates, i, "N"); // Not available
         }
         if (cMyCiv == cCivSPCIndians)
         {
            if ((tech == cTechYPHCShipSepoy1) || (tech == cTechYPHCShipSepoy2) || (tech == cTechYPHCShipSepoy3) ||
                (tech == cTechYPHCShipSepoy4))
            {
               xsArraySetString(gCardStates, i, "N"); // BHG: don't want spcindians sending in unapproved sepoys
            }
         }

         if (aiHCCardsGetCardCount(i) < 0)
            tempString = " Infinite";
         else
            tempString = "   " + aiHCCardsGetCardCount(i) + " use";
         tempString = tempString + " Pri " + xsArrayGetInt(gCardPriorities, i) + " ";
         tempString = tempString + " " + xsArrayGetString(gCardStates, i);
         tempString = tempString + "  L" + aiHCCardsGetCardLevel(i);
         tempString = tempString + "  A" + aiHCCardsGetCardAgePrereq(i);
         tempString = tempString + " (" + tech + ") " + kbGetTechName(tech);
         if (unit >= 0)
         {
            tempString = tempString + " " + aiHCCardsGetCardUnitCount(i) + " " + kbGetProtoUnitName(unit);
         }

         xsArraySetString(gCardNames, i, tempString);
         debugHCCards(i + " " + tempString);
         // don't process too many cards at a time.
         numCardsProcessed++;
         if (i >= startingCardIndex + 7)
         {
            break;
         }
      }
      if (numCardsProcessed >= totalCardCount)
         pass = 1; // Buy cards next time
      break;
   }
   case 1: // Buy cards
   {
      for (attempt = 0; < 10)
      {
         aiEcho("Purchase attempt " + attempt);
         if (remainingSP <= 0) // Have no points to spend...
            break;
         bool result = false;
         int boughtCardIndex = -1;
         int highestPriority = 0; // Priority higher than this will be bought.
         // First, scan for the high-priority cards.
         for (index = 0; < totalCardCount)
         { // Scan the list, looking for the highest-priority card still available
            if ((aiHCCardsGetCardLevel(index) > myLevel) || (aiHCCardsCanIBuyThisCard(-1, index) == false) ||
                (xsArrayGetString(gCardStates, index) == "P"))
               continue; // Skip it.  Note...I use the "P" (purchased) flag to indicate ones that are purchased, AND
                         // ones that have failed in a buy attempt.
            // It is legal and available
            if (xsArrayGetInt(gCardPriorities, index) > highestPriority)
            {
               boughtCardIndex = index;
               highestPriority = xsArrayGetInt(gCardPriorities, index);
            }
         }
         if (boughtCardIndex >= 0)
         {
            result = aiHCCardsBuyCard(boughtCardIndex);
            aiEcho("Buying priority " + highestPriority + " card " + xsArrayGetString(gCardNames, boughtCardIndex));
         }
         int cardIndex = -1;
         if (boughtCardIndex < 0)
         { // No special cards remain, look for best one in each category.
            cardIndex = aiHCCardsFindBestCard(cHCCardTypeEcon, myLevel);
            if (cardIndex >= 0)
            { // Any econ card
               result = aiHCCardsBuyCard(cardIndex);
               aiEcho("Buying econ card " + xsArrayGetString(gCardNames, cardIndex));
               boughtCardIndex = cardIndex;
               // xsArraySetInt(gCardPriorities, cardIndex, 3);   // Pri 3, econ card
               break;
            }
            cardIndex = aiHCCardsFindBestCard(cHCCardTypeMilitary, myLevel);
            if (cardIndex >= 0)
            { // Any military card
               result = aiHCCardsBuyCard(cardIndex);
               aiEcho("Buying econ card " + xsArrayGetString(gCardNames, cardIndex));
               boughtCardIndex = cardIndex;
               // xsArraySetInt(gCardPriorities, cardIndex, 2);   // Pri 2, military card
               break;
            }
            cardIndex = aiHCCardsFindBestCard(cHCCardTypeWagon, myLevel);
            if (cardIndex >= 0)
            { // Any wagon card
               result = aiHCCardsBuyCard(cardIndex);
               aiEcho("Buying econ card " + xsArrayGetString(gCardNames, cardIndex));
               boughtCardIndex = cardIndex;
               // xsArraySetInt(gCardPriorities, cardIndex, 7);   // Pri 7, wagon card...shouldn't get any hits here.
               break;
            }
            cardIndex = aiHCCardsFindBestCard(cHCCardTypeTeam, myLevel);
            if (cardIndex >= 0)
            { // Any team card
               result = aiHCCardsBuyCard(cardIndex);
               aiEcho("Buying econ card " + xsArrayGetString(gCardNames, cardIndex));
               boughtCardIndex = cardIndex;
               // xsArraySetInt(gCardPriorities, cardIndex, 1);   // Pri 1, team card
               break;
            }
         }
         // If we're here, we've either selected a card, or exhausted the list.
         if (boughtCardIndex < 0)
         { // Nothing to buy?!
            aiEcho("  ERROR!  We have points to spend, but no cards to buy.");
            pass = 2; // go on to deck picking
            return;
         }
         // We've selected a card.  Did the purchase work?
         if (result == false)
         { // It failed, blacklist this card by marking it owned in the array.
            aiEcho("  ERROR!  Failed to buy card " + xsArrayGetString(gCardNames, boughtCardIndex));
         }
         xsArraySetString(gCardStates, boughtCardIndex, "P"); // Even if purchase failed, mark it purchased so we don't get stuck on it.
         remainingSP = remainingSP - 1;
         SPSpent = SPSpent + 1;
         if (SPSpent >= 10)
            myLevel = 10;
         if (SPSpent >= 25)
            myLevel = 25;
      } // For attempt 0..9
      if (remainingSP <= 0)
         pass = 2;
   }       // case 1
   case 2: // Make deck
   {
      aiEcho("Making deck");
      /*if (gSPC == true)
      {
         if (gDefaultDeck < 0)
         {
            gDefaultDeck = aiHCDeckCreate("The AI Deck");
            aiEcho("Creating new deck at index " + gDefaultDeck);
         }
      }
      else
      {*/
         //-- In non spc games, the game will make an empty deck for AI's at index 0.
         gDefaultDeck = 0;
         aiEcho("Using deck at index " + gDefaultDeck);
      //}
      aiEcho("Building Deck");
      int cardsRemaining = 25;
      int cardsAge1 = 0;
      int cardsAge2 = 0;
      int cardsAge3 = 0;
      int cardsAge4 = 0;
      float totalValueCurrent = 0.0;
      float totalValueBest = 0.0;
      float totalCost = 0.0;
      int cardsPicked = 0;
      bool addedVillager = false;
      bool addedInfUnit = false;
      int toPick = 4;
      if (aiGetWorldDifficulty() >= cDifficultyModerate)
         toPick = 1;
      // First, 1-4 age 1 cards.
      for (i = 0; < toPick)
      {
         int bestCard = -1;
         int bestCardPri = -1;
         int currentCardFlags = 0;
         int bestCardFlags = -1;
         totalValueCurrent = 0.0;
         totalValueBest = 0.0;
         totalCost = 0.0;
         for (card = 0; < maxCards)
         {
            if (xsArrayGetString(gCardStates, card) != "P")
               continue; // Only consider purchased cards not already in deck.
            if (aiHCCardsGetCardAgePrereq(card) != cAge1)
               continue;
            currentCardFlags = aiHCCardsGetCardFlags(card);
            if ((addedVillager == true) && ((currentCardFlags & cHCCardFlagVillager) == cHCCardFlagVillager))
               continue; // Don't add more than one villager card in age 1 for now
            if (((currentCardFlags & cHCCardFlagResourceCrate) == cHCCardFlagResourceCrate) &&
                (xsArrayGetInt(gCardPriorities, card) < 10))
               continue; // Avoid resource crates in age 1
            if ((aiTreatyActive() == true) && ((currentCardFlags & cHCCardFlagMilitary) == cHCCardFlagMilitary) &&
                ((currentCardFlags & cHCCardFlagUnit) == cHCCardFlagUnit))
               continue; // Avoid military units in age 1 when a treaty is active.
            if ((addedInfUnit == true) && (aiHCCardsGetCardCount(card) < 0) &&
                (xsArrayGetInt(gCardPriorities, card) < 10))
               continue; // Don't add more than 1 infinite military card for now.
            if ((xsArrayGetInt(gCardPriorities, card) == bestCardPri) &&
                ((currentCardFlags & cHCCardFlagMilitary) == cHCCardFlagMilitary) &&
                ((currentCardFlags & cHCCardFlagUnit) == cHCCardFlagUnit))
            { // If it's a military unit calculate a value for this card.
               totalValueCurrent = aiHCCardsGetCardValuePerResource(card, cResourceWood) +
                                   aiHCCardsGetCardValuePerResource(card, cResourceFood) +
                                   aiHCCardsGetCardValuePerResource(card, cResourceGold);
               totalCost = kbTechCostPerResource(aiHCCardsGetCardTechID(card), cResourceWood) +
                           kbTechCostPerResource(aiHCCardsGetCardTechID(card), cResourceFood) +
                           kbTechCostPerResource(aiHCCardsGetCardTechID(card), cResourceGold);
               totalValueCurrent = totalValueCurrent - totalCost;
               if (totalValueCurrent < 0.0)
                  totalValueCurrent = 0.0;
            }
            if (xsArrayGetInt(gCardPriorities, card) > bestCardPri)
            {
               bestCardPri = xsArrayGetInt(gCardPriorities, card);
               bestCard = card;
               bestCardFlags = currentCardFlags;
            }
            else if ((((currentCardFlags & cHCCardFlagVillager) == cHCCardFlagVillager) &&
                      ((bestCardFlags & cHCCardFlagVillager) == cHCCardFlagVillager) &&
                      (xsArrayGetInt(gCardPriorities, card) >= bestCardPri)) &&
                     (((aiHCCardsGetCardValuePerResource(bestCard, cResourceWood) > 0.0) &&
                       (aiHCCardsGetCardValuePerResource(card, cResourceWood) >
                        aiHCCardsGetCardValuePerResource(bestCard, cResourceWood))) ||
                      ((aiHCCardsGetCardValuePerResource(bestCard, cResourceFood) > 0.0) &&
                       (aiHCCardsGetCardValuePerResource(card, cResourceFood) >
                        aiHCCardsGetCardValuePerResource(bestCard, cResourceFood))) ||
                      ((aiHCCardsGetCardValuePerResource(bestCard, cResourceGold) > 0.0) &&
                       (aiHCCardsGetCardValuePerResource(card, cResourceGold) >
                        aiHCCardsGetCardValuePerResource(bestCard, cResourceGold)))))
            { // make sure more valuable villager cards win
               bestCardPri = xsArrayGetInt(gCardPriorities, card);
               bestCard = card;
               bestCardFlags = currentCardFlags;
            }
            else if ((xsArrayGetInt(gCardPriorities, card) == bestCardPri) &&
                     ((currentCardFlags & cHCCardFlagMilitary) == cHCCardFlagMilitary) &&
                     ((currentCardFlags & cHCCardFlagUnit) == cHCCardFlagUnit) && (totalValueCurrent > totalValueBest))
            { // If it's the same priority of a military unit card, take the one with the better value.
               bestCardPri = xsArrayGetInt(gCardPriorities, card);
               bestCard = card;
               totalValueBest = totalValueCurrent;
            }
         }
         if (bestCard >= 0)
         {
            if ((aiGetWorldDifficulty() >= cDifficultyModerate) &&
                (((xsArrayGetInt(gCardPriorities, bestCard) < 6) && (cardsAge1 >= 1)) ||
                 ((xsArrayGetInt(gCardPriorities, bestCard) < 7) && (cardsAge1 >= 2))))
               continue; // After the first card, only pick more if they're good.
            addCardToDeck(gDefaultDeck, bestCard);
            cardsRemaining = cardsRemaining - 1;
            xsArraySetString(gCardStates, bestCard, "D");
            // aiEcho("  0Adding card "+xsArrayGetString(gCardNames, bestCard));
            cardsPicked = cardsPicked + 1;
            cardsAge1 = cardsAge1 + 1;
            if (((bestCardFlags & cHCCardFlagVillager) == cHCCardFlagVillager) && (addedVillager == false))
               addedVillager = true;
            if (((bestCardFlags & cHCCardFlagUnit) == cHCCardFlagUnit) && (aiHCCardsGetCardCount(bestCard) < 0) &&
                (addedInfUnit == false))
               addedInfUnit = true;
         }
      } //  21-24 remaining.
      addedInfUnit = false;
      cardsPicked = 0;
      toPick = 0; // 1 + ((btRushBoom + 1.0) * 1.51);
      // Next, age 2 military cards.  1 for a boomer, up to 4 for a rusher.
      for (i = 0; < toPick)
      {
         bestCard = -1;
         bestCardPri = -1;
         currentCardFlags = 0;
         totalValueCurrent = 0.0;
         totalValueBest = 0.0;
         totalCost = 0.0;
         for (card = 0; < maxCards)
         {
            if (xsArrayGetString(gCardStates, card) != "P")
               continue; // Only consider purchased cards not already in deck.
            if (aiHCCardsGetCardAgePrereq(card) != cAge2)
               continue;
            currentCardFlags = aiHCCardsGetCardFlags(card);
            if ((currentCardFlags & cHCCardFlagMilitary) != cHCCardFlagMilitary)
               continue; // Only look at military units and upgrades
            if (((currentCardFlags & cHCCardFlagUnit) != cHCCardFlagUnit) && (cardsPicked <= 0))
               continue; // Pick at least 1 unit
            if ((addedInfUnit == true) && (aiHCCardsGetCardCount(card) < 0) &&
                (xsArrayGetInt(gCardPriorities, card) < 10))
               continue; // Don't add more than 1 infinite military card for now.
            if ((aiTreatyActive() == true) && ((currentCardFlags & cHCCardFlagMilitary) == cHCCardFlagMilitary) &&
                ((currentCardFlags & cHCCardFlagUnit) == cHCCardFlagUnit))
               continue; // Avoid military units in age 2 when a treaty is active.
            if ((xsArrayGetInt(gCardPriorities, card) == bestCardPri) &&
                ((currentCardFlags & cHCCardFlagUnit) == cHCCardFlagUnit))
            { // If it's a military unit calculate a value for this card.
               totalValueCurrent = aiHCCardsGetCardValuePerResource(card, cResourceWood) +
                                   aiHCCardsGetCardValuePerResource(card, cResourceFood) +
                                   aiHCCardsGetCardValuePerResource(card, cResourceGold);
               totalCost = kbTechCostPerResource(aiHCCardsGetCardTechID(card), cResourceWood) +
                           kbTechCostPerResource(aiHCCardsGetCardTechID(card), cResourceFood) +
                           kbTechCostPerResource(aiHCCardsGetCardTechID(card), cResourceGold);
               totalValueCurrent = totalValueCurrent - totalCost;
               if (totalValueCurrent < 0.0)
                  totalValueCurrent = 0.0;
            }
            if (xsArrayGetInt(gCardPriorities, card) > bestCardPri)
            {
               bestCardPri = xsArrayGetInt(gCardPriorities, card);
               bestCard = card;
            }
            else if ((xsArrayGetInt(gCardPriorities, card) == bestCardPri) &&
                     ((currentCardFlags & cHCCardFlagUnit) == cHCCardFlagUnit) && (totalValueCurrent > totalValueBest))
            { // If it's the same priority of a military unit card, take the one with the better value.
               bestCardPri = xsArrayGetInt(gCardPriorities, card);
               bestCard = card;
               totalValueBest = totalValueCurrent;
            }
         }
         if (bestCard >= 0)
         {
            if ((xsArrayGetInt(gCardPriorities, bestCard) < 6) && (cardsPicked >= 2))
               continue; // After the first two cards, only pick more if they're good.
            addCardToDeck(gDefaultDeck, bestCard);
            cardsRemaining = cardsRemaining - 1;
            xsArraySetString(gCardStates, bestCard, "D");
            // aiEcho("  1Adding card "+xsArrayGetString(gCardNames, bestCard));
            cardsPicked = cardsPicked + 1;
            cardsAge2 = cardsAge2 + 1;
            if (((bestCardFlags & cHCCardFlagUnit) == cHCCardFlagUnit) && (aiHCCardsGetCardCount(bestCard) < 0) &&
                (addedInfUnit == false))
               addedInfUnit = true;
         }
      } // 17-23 remaining.
      cardsPicked = 0;
      addedVillager = false;
      int addedCrates = 0;
      toPick = 0; // + ((btRushBoom + 1.0) * 1.51);
      // Next, age 2 non-military cards.  1 for a rusher, up to 4 for a boomer.
      for (i = 0; < toPick)
      {
         bestCard = -1;
         bestCardPri = -1;
         currentCardFlags = 0;
         bestCardFlags = -1;
         for (card = 0; < maxCards)
         {
            if (xsArrayGetString(gCardStates, card) != "P")
               continue; // Only consider purchased cards not already in deck.
            if (aiHCCardsGetCardAgePrereq(card) != cAge2)
               continue;
            currentCardFlags = aiHCCardsGetCardFlags(card);
            if ((currentCardFlags & cHCCardFlagMilitary) == cHCCardFlagMilitary)
               continue; // Don't look at military units (and upgrades)
            if ((addedVillager == true) && ((currentCardFlags & cHCCardFlagVillager) == cHCCardFlagVillager))
               continue; // Don't add more than 1 villager card in age 2 for now
            if ((addedCrates >= 3) && ((currentCardFlags & cHCCardFlagResourceCrate) == cHCCardFlagResourceCrate) &&
                (xsArrayGetInt(gCardPriorities, card) < 10))
               continue; // Don't add more than 3 resource crates in age 2
            if ((addedInfUnit == true) && (aiHCCardsGetCardCount(card) < 0) &&
                (xsArrayGetInt(gCardPriorities, card) < 10))
               continue; // Don't add more than 1 infinite military card for now.
            if (xsArrayGetInt(gCardPriorities, card) > bestCardPri)
            {
               bestCardPri = xsArrayGetInt(gCardPriorities, card);
               bestCard = card;
               bestCardFlags = currentCardFlags;
            }
            else if ((((currentCardFlags & cHCCardFlagVillager) == cHCCardFlagVillager) &&
                      ((bestCardFlags & cHCCardFlagVillager) == cHCCardFlagVillager) &&
                      (xsArrayGetInt(gCardPriorities, card) >= bestCardPri)) &&
                     (((aiHCCardsGetCardValuePerResource(bestCard, cResourceWood) > 0.0) &&
                       (aiHCCardsGetCardValuePerResource(card, cResourceWood) >
                        aiHCCardsGetCardValuePerResource(bestCard, cResourceWood))) ||
                      ((aiHCCardsGetCardValuePerResource(bestCard, cResourceFood) > 0.0) &&
                       (aiHCCardsGetCardValuePerResource(card, cResourceFood) >
                        aiHCCardsGetCardValuePerResource(bestCard, cResourceFood))) ||
                      ((aiHCCardsGetCardValuePerResource(bestCard, cResourceGold) > 0.0) &&
                       (aiHCCardsGetCardValuePerResource(card, cResourceGold) >
                        aiHCCardsGetCardValuePerResource(bestCard, cResourceGold)))))
            { // make sure more valuable villager cards win
               bestCardPri = xsArrayGetInt(gCardPriorities, card);
               bestCard = card;
               bestCardFlags = currentCardFlags;
            }
            else if ((((currentCardFlags & cHCCardFlagResourceCrate) == cHCCardFlagResourceCrate) &&
                      ((bestCardFlags & cHCCardFlagResourceCrate) == cHCCardFlagResourceCrate)) &&
                     (((aiHCCardsGetCardValuePerResource(bestCard, cResourceWood) > 0.0) &&
                       (aiHCCardsGetCardValuePerResource(card, cResourceWood) >
                        aiHCCardsGetCardValuePerResource(bestCard, cResourceWood))) ||
                      ((aiHCCardsGetCardValuePerResource(bestCard, cResourceFood) > 0.0) &&
                       (aiHCCardsGetCardValuePerResource(card, cResourceFood) >
                        aiHCCardsGetCardValuePerResource(bestCard, cResourceFood))) ||
                      ((aiHCCardsGetCardValuePerResource(bestCard, cResourceGold) > 0.0) &&
                       (aiHCCardsGetCardValuePerResource(card, cResourceGold) >
                        aiHCCardsGetCardValuePerResource(bestCard, cResourceGold)))))
            { // make sure more valuable resource cards for the same resource win
               bestCardPri = xsArrayGetInt(gCardPriorities, card);
               bestCard = card;
               bestCardFlags = currentCardFlags;
            }
            else if (((((currentCardFlags & cHCCardFlagResourceCrate) == cHCCardFlagResourceCrate) &&
                       ((bestCardFlags & cHCCardFlagResourceCrate) == cHCCardFlagResourceCrate)) &&
                      (xsArrayGetInt(gCardPriorities, card) >= bestCardPri)) &&
                     (((aiHCCardsGetCardValuePerResource(card, cResourceWood) > 0.0) &&
                       (aiHCCardsGetCardValuePerResource(card, cResourceWood) >=
                        aiHCCardsGetCardValuePerResource(bestCard, cResourceFood))) ||
                      ((aiHCCardsGetCardValuePerResource(card, cResourceGold) > 0.0) &&
                       (aiHCCardsGetCardValuePerResource(card, cResourceGold) >=
                        aiHCCardsGetCardValuePerResource(bestCard, cResourceFood)))))
            { // prioritize coin & wood, food
               bestCardPri = xsArrayGetInt(gCardPriorities, card);
               bestCard = card;
               bestCardFlags = currentCardFlags;
            }
         }
         if (bestCard >= 0)
         {
            if ((xsArrayGetInt(gCardPriorities, bestCard) < 6) && (cardsPicked >= 2))
               continue; // After the first two cards, only pick more if they're good.
            addCardToDeck(gDefaultDeck, bestCard);
            cardsRemaining = cardsRemaining - 1;
            xsArraySetString(gCardStates, bestCard, "D");
            // aiEcho("  2Adding card "+xsArrayGetString(gCardNames, bestCard));
            cardsPicked = cardsPicked + 1;
            cardsAge2 = cardsAge2 + 1;
            if (((bestCardFlags & cHCCardFlagVillager) == cHCCardFlagVillager) && (addedVillager == false))
               addedVillager = true;
            if (((bestCardFlags & cHCCardFlagResourceCrate) == cHCCardFlagResourceCrate) && (addedCrates < 4))
               addedCrates = addedCrates + 1;
            if (((bestCardFlags & cHCCardFlagUnit) == cHCCardFlagUnit) && (aiHCCardsGetCardCount(bestCard) < 0) &&
                (addedInfUnit == false))
               addedInfUnit = true;
         }
      } // 16-22 remaining.
      cardsPicked = 0;
      toPick = 0;
      // Next, 1-2 more possible age 2 cards.
      for (i = 0; < toPick)
      {
         bestCardPri = -1;
         currentCardFlags = 0;
         bestCardFlags = -1;
         totalValueCurrent = 0.0;
         totalValueBest = 0.0;
         totalCost = 0.0;
         for (card = 0; < maxCards)
         {
            if (xsArrayGetString(gCardStates, card) != "P")
               continue; // Only consider purchased cards not already in deck.
            if (aiHCCardsGetCardAgePrereq(card) != cAge2)
               continue;
            if (xsArrayGetInt(gCardPriorities, card) < 7)
               continue; // Only pick one if it's really good.
            currentCardFlags = aiHCCardsGetCardFlags(card);
            if ((currentCardFlags & cHCCardFlagVillager) == cHCCardFlagVillager)
               continue; // Ignore villager cards here
            if ((currentCardFlags & cHCCardFlagResourceCrate) == cHCCardFlagResourceCrate)
               continue; // Ignore resource crate cards here
            if ((addedInfUnit == true) && (aiHCCardsGetCardCount(card) < 0) &&
                (xsArrayGetInt(gCardPriorities, card) < 10))
               continue; // Don't add more than 1 infinite military card for now.
            if ((aiTreatyActive() == true) && ((currentCardFlags & cHCCardFlagMilitary) == cHCCardFlagMilitary) &&
                ((currentCardFlags & cHCCardFlagUnit) == cHCCardFlagUnit))
               continue; // Avoid military units in age 2 when a treaty is active.
            if ((xsArrayGetInt(gCardPriorities, card) == bestCardPri) &&
                ((currentCardFlags & cHCCardFlagMilitary) == cHCCardFlagMilitary) &&
                ((currentCardFlags & cHCCardFlagUnit) == cHCCardFlagUnit))
            { // If it's a military unit calculate a value for this card.
               totalValueCurrent = aiHCCardsGetCardValuePerResource(card, cResourceWood) +
                                   aiHCCardsGetCardValuePerResource(card, cResourceFood) +
                                   aiHCCardsGetCardValuePerResource(card, cResourceGold);
               totalCost = kbTechCostPerResource(aiHCCardsGetCardTechID(card), cResourceWood) +
                           kbTechCostPerResource(aiHCCardsGetCardTechID(card), cResourceFood) +
                           kbTechCostPerResource(aiHCCardsGetCardTechID(card), cResourceGold);
               totalValueCurrent = totalValueCurrent - totalCost;
               if (totalValueCurrent < 0.0)
                  totalValueCurrent = 0.0;
            }
            if (xsArrayGetInt(gCardPriorities, card) > bestCardPri)
            {
               bestCardPri = xsArrayGetInt(gCardPriorities, card);
               bestCard = card;
               bestCardFlags = currentCardFlags;
            }
            else if ((xsArrayGetInt(gCardPriorities, card) == bestCardPri) &&
                     ((currentCardFlags & cHCCardFlagMilitary) == cHCCardFlagMilitary) &&
                     ((currentCardFlags & cHCCardFlagUnit) == cHCCardFlagUnit) && (totalValueCurrent > totalValueBest))
            { // If it's the same priority of a military unit card, take the one with the better value.
               bestCardPri = xsArrayGetInt(gCardPriorities, card);
               bestCard = card;
               totalValueBest = totalValueCurrent;
            }
         }
         if (bestCard >= 0)
         {
            if ((xsArrayGetInt(gCardPriorities, bestCard) < 6) && (cardsPicked >= 1))
               continue; // After the first card, only pick another if it's good.
            addCardToDeck(gDefaultDeck, bestCard);
            cardsRemaining = cardsRemaining - 1;
            xsArraySetString(gCardStates, bestCard, "D");
            // aiEcho("  3Adding card "+xsArrayGetString(gCardNames, bestCard));
            cardsPicked = cardsPicked + 1;
            cardsAge2 = cardsAge2 + 1;
            if (((bestCardFlags & cHCCardFlagUnit) == cHCCardFlagUnit) && (aiHCCardsGetCardCount(bestCard) < 0) &&
                (addedInfUnit == false))
               addedInfUnit = true;
         }
      } // 14-22 remaining.
      addedInfUnit = false;
      toPick = 0;
      // 1-2 age-3 military cards
      for (i = 0; < toPick)
      {
         bestCard = -1;
         bestCardPri = -1;
         currentCardFlags = 0;
         totalValueCurrent = 0.0;
         totalValueBest = 0.0;
         totalCost = 0.0;
         for (card = 0; < maxCards)
         {
            if (xsArrayGetString(gCardStates, card) != "P")
               continue; // Only consider purchased cards not already in deck.
            if (aiHCCardsGetCardAgePrereq(card) != cAge3)
               continue;
            currentCardFlags = aiHCCardsGetCardFlags(card);
            if ((currentCardFlags & cHCCardFlagMilitary) != cHCCardFlagMilitary)
               continue; // Only look at military units (and upgrades).
            if ((addedInfUnit == true) && (aiHCCardsGetCardCount(card) < 0) &&
                (xsArrayGetInt(gCardPriorities, card) < 10))
               continue; // Don't add more than 1 infinite military card for now.
            if ((xsArrayGetInt(gCardPriorities, card) == bestCardPri) &&
                ((currentCardFlags & cHCCardFlagUnit) == cHCCardFlagUnit))
            { // If it's a military unit calculate a value for this card.
               totalValueCurrent = aiHCCardsGetCardValuePerResource(card, cResourceWood) +
                                   aiHCCardsGetCardValuePerResource(card, cResourceFood) +
                                   aiHCCardsGetCardValuePerResource(card, cResourceGold);
               totalCost = kbTechCostPerResource(aiHCCardsGetCardTechID(card), cResourceWood) +
                           kbTechCostPerResource(aiHCCardsGetCardTechID(card), cResourceFood) +
                           kbTechCostPerResource(aiHCCardsGetCardTechID(card), cResourceGold);
               totalValueCurrent = totalValueCurrent - totalCost;
               if (totalValueCurrent < 0.0)
                  totalValueCurrent = 0.0;
            }
            if (xsArrayGetInt(gCardPriorities, card) > bestCardPri)
            {
               bestCardPri = xsArrayGetInt(gCardPriorities, card);
               bestCard = card;
            }
            else if ((xsArrayGetInt(gCardPriorities, card) == bestCardPri) &&
                     ((currentCardFlags & cHCCardFlagUnit) == cHCCardFlagUnit) && (totalValueCurrent > totalValueBest))
            { // If it's the same priority of a military unit card, take the one with the better value.
               bestCardPri = xsArrayGetInt(gCardPriorities, card);
               bestCard = card;
               totalValueBest = totalValueCurrent;
            }
         }
         if (bestCard >= 0)
         {
            if ((xsArrayGetInt(gCardPriorities, bestCard) < 6) && (cardsPicked >= 1))
               continue; // After the first card, only pick another if it's good.
            addCardToDeck(gDefaultDeck, bestCard);
            cardsRemaining = cardsRemaining - 1;
            xsArraySetString(gCardStates, bestCard, "D");
            // aiEcho("  4Adding card "+xsArrayGetString(gCardNames, bestCard));
            cardsPicked = cardsPicked + 1;
            cardsAge3 = cardsAge3 + 1;
            if (((bestCardFlags & cHCCardFlagUnit) == cHCCardFlagUnit) && (aiHCCardsGetCardCount(bestCard) < 0) &&
                (addedInfUnit == false))
               addedInfUnit = true;
         }
      } // 12-21 remaining.
      addedVillager = false;
      addedCrates = 0;
      toPick = 2;
      // Next, 5-6 age 3 cards.
      for (i = 0; < toPick)
      {
         bestCard = -1;
         bestCardPri = -1;
         currentCardFlags = 0;
         bestCardFlags = -1;
         totalValueCurrent = 0.0;
         totalValueBest = 0.0;
         totalCost = 0.0;
         for (card = 0; < maxCards)
         {
            if (xsArrayGetString(gCardStates, card) != "P")
               continue; // Only consider purchased cards not already in deck.
            if (aiHCCardsGetCardAgePrereq(card) != cAge3)
               continue;
            currentCardFlags = aiHCCardsGetCardFlags(card);
            if ((addedVillager == true) && ((currentCardFlags & cHCCardFlagVillager) == cHCCardFlagVillager))
               continue; // Don't add more than 1 villager card in age 3 for now
            if ((addedCrates >= 2) && ((currentCardFlags & cHCCardFlagResourceCrate) == cHCCardFlagResourceCrate) &&
                (xsArrayGetInt(gCardPriorities, card) < 10))
               continue; // Don't add more than 2 resource crates in age 3
            if ((addedInfUnit == true) && (aiHCCardsGetCardCount(card) < 0) &&
                (xsArrayGetInt(gCardPriorities, card) < 10))
               continue; // Don't add more than 1 infinite military card for now.
            if ((xsArrayGetInt(gCardPriorities, card) == bestCardPri) &&
                ((currentCardFlags & cHCCardFlagMilitary) == cHCCardFlagMilitary) &&
                ((currentCardFlags & cHCCardFlagUnit) == cHCCardFlagUnit))
            { // If it's a military unit calculate a value for this card.
               totalValueCurrent = aiHCCardsGetCardValuePerResource(card, cResourceWood) +
                                   aiHCCardsGetCardValuePerResource(card, cResourceFood) +
                                   aiHCCardsGetCardValuePerResource(card, cResourceGold);
               totalCost = kbTechCostPerResource(aiHCCardsGetCardTechID(card), cResourceWood) +
                           kbTechCostPerResource(aiHCCardsGetCardTechID(card), cResourceFood) +
                           kbTechCostPerResource(aiHCCardsGetCardTechID(card), cResourceGold);
               totalValueCurrent = totalValueCurrent - totalCost;
               if (totalValueCurrent < 0.0)
                  totalValueCurrent = 0.0;
            }
            if (xsArrayGetInt(gCardPriorities, card) > bestCardPri)
            {
               bestCardPri = xsArrayGetInt(gCardPriorities, card);
               bestCard = card;
               bestCardFlags = currentCardFlags;
            }
            else if ((((currentCardFlags & cHCCardFlagVillager) == cHCCardFlagVillager) &&
                      ((bestCardFlags & cHCCardFlagVillager) == cHCCardFlagVillager) &&
                      (xsArrayGetInt(gCardPriorities, card) >= bestCardPri)) &&
                     (((aiHCCardsGetCardValuePerResource(bestCard, cResourceWood) > 0.0) &&
                       (aiHCCardsGetCardValuePerResource(card, cResourceWood) >
                        aiHCCardsGetCardValuePerResource(bestCard, cResourceWood))) ||
                      ((aiHCCardsGetCardValuePerResource(bestCard, cResourceFood) > 0.0) &&
                       (aiHCCardsGetCardValuePerResource(card, cResourceFood) >
                        aiHCCardsGetCardValuePerResource(bestCard, cResourceFood))) ||
                      ((aiHCCardsGetCardValuePerResource(bestCard, cResourceGold) > 0.0) &&
                       (aiHCCardsGetCardValuePerResource(card, cResourceGold) >
                        aiHCCardsGetCardValuePerResource(bestCard, cResourceGold)))))
            { // make sure more valuable villager cards win
               bestCardPri = xsArrayGetInt(gCardPriorities, card);
               bestCard = card;
               bestCardFlags = currentCardFlags;
            }
            else if ((((currentCardFlags & cHCCardFlagResourceCrate) == cHCCardFlagResourceCrate) &&
                      ((bestCardFlags & cHCCardFlagResourceCrate) == cHCCardFlagResourceCrate)) &&
                     (((aiHCCardsGetCardValuePerResource(bestCard, cResourceWood) > 0.0) &&
                       (aiHCCardsGetCardValuePerResource(card, cResourceWood) >
                        aiHCCardsGetCardValuePerResource(bestCard, cResourceWood))) ||
                      ((aiHCCardsGetCardValuePerResource(bestCard, cResourceFood) > 0.0) &&
                       (aiHCCardsGetCardValuePerResource(card, cResourceFood) >
                        aiHCCardsGetCardValuePerResource(bestCard, cResourceFood))) ||
                      ((aiHCCardsGetCardValuePerResource(bestCard, cResourceGold) > 0.0) &&
                       (aiHCCardsGetCardValuePerResource(card, cResourceGold) >
                        aiHCCardsGetCardValuePerResource(bestCard, cResourceGold)))))
            { // make sure more valuable resource cards for the same resource win
               bestCardPri = xsArrayGetInt(gCardPriorities, card);
               bestCard = card;
               bestCardFlags = currentCardFlags;
            }
            else if (((((currentCardFlags & cHCCardFlagResourceCrate) == cHCCardFlagResourceCrate) &&
                       ((bestCardFlags & cHCCardFlagResourceCrate) == cHCCardFlagResourceCrate)) &&
                      (xsArrayGetInt(gCardPriorities, card) >= bestCardPri)) &&
                     (((aiHCCardsGetCardValuePerResource(card, cResourceWood) > 0.0) &&
                       (aiHCCardsGetCardValuePerResource(card, cResourceWood) >=
                        aiHCCardsGetCardValuePerResource(bestCard, cResourceFood))) ||
                      ((aiHCCardsGetCardValuePerResource(card, cResourceGold) > 0.0) &&
                       (aiHCCardsGetCardValuePerResource(card, cResourceGold) >=
                        aiHCCardsGetCardValuePerResource(bestCard, cResourceFood)))))
            { // prioritize coin & wood, food
               bestCardPri = xsArrayGetInt(gCardPriorities, card);
               bestCard = card;
               bestCardFlags = currentCardFlags;
            }
            else if ((xsArrayGetInt(gCardPriorities, card) == bestCardPri) &&
                     ((currentCardFlags & cHCCardFlagMilitary) == cHCCardFlagMilitary) &&
                     ((currentCardFlags & cHCCardFlagUnit) == cHCCardFlagUnit) && (totalValueCurrent > totalValueBest))
            { // If it's the same priority of a military unit card, take the one with the better value.
               bestCardPri = xsArrayGetInt(gCardPriorities, card);
               bestCard = card;
               totalValueBest = totalValueCurrent;
            }
         }
         if (bestCard >= 0)
         {
            if ((xsArrayGetInt(gCardPriorities, bestCard) < 6) && (cardsPicked >= 5))
               continue; // After the first five cards, only pick another if it's good.
            addCardToDeck(gDefaultDeck, bestCard);
            cardsRemaining = cardsRemaining - 1;
            xsArraySetString(gCardStates, bestCard, "D");
            // aiEcho("  5Adding card "+xsArrayGetString(gCardNames, bestCard));
            cardsPicked = cardsPicked + 1;
            cardsAge3 = cardsAge3 + 1;
            if (((bestCardFlags & cHCCardFlagVillager) == cHCCardFlagVillager) && (addedVillager == false))
               addedVillager = true;
            if (((bestCardFlags & cHCCardFlagResourceCrate) == cHCCardFlagResourceCrate) && (addedCrates < 2))
               addedCrates = addedCrates + 1;
            if (((bestCardFlags & cHCCardFlagUnit) == cHCCardFlagUnit) && (aiHCCardsGetCardCount(bestCard) < 0) &&
                (addedInfUnit == false))
               addedInfUnit = true;
         }
      } // 6-15 remaining.
      addedInfUnit = false;
      toPick = 0;
      // 1-2 age-4 military cards
      for (i = 0; < toPick)
      {
         bestCard = -1;
         bestCardPri = -1;
         currentCardFlags = 0;
         totalValueCurrent = 0.0;
         totalValueBest = 0.0;
         totalCost = 0.0;
         for (card = 0; < maxCards)
         {
            if (xsArrayGetString(gCardStates, card) != "P")
               continue; // Only consider purchased cards not already in deck.
            if (aiHCCardsGetCardAgePrereq(card) != cAge4)
               continue;
            currentCardFlags = aiHCCardsGetCardFlags(card);
            if ((currentCardFlags & cHCCardFlagMilitary) != cHCCardFlagMilitary)
               continue; // Only look at military units (and upgrades).
            if ((addedInfUnit == true) && (aiHCCardsGetCardCount(card) < 0) &&
                (xsArrayGetInt(gCardPriorities, card) < 10))
               continue; // Don't add more than 1 infinite military card for now.
            if ((xsArrayGetInt(gCardPriorities, card) == bestCardPri) &&
                ((currentCardFlags & cHCCardFlagUnit) == cHCCardFlagUnit))
            { // If it's a military unit calculate a value for this card.
               totalValueCurrent = aiHCCardsGetCardValuePerResource(card, cResourceWood) +
                                   aiHCCardsGetCardValuePerResource(card, cResourceFood) +
                                   aiHCCardsGetCardValuePerResource(card, cResourceGold);
               totalCost = kbTechCostPerResource(aiHCCardsGetCardTechID(card), cResourceWood) +
                           kbTechCostPerResource(aiHCCardsGetCardTechID(card), cResourceFood) +
                           kbTechCostPerResource(aiHCCardsGetCardTechID(card), cResourceGold);
               totalValueCurrent = totalValueCurrent - totalCost;
               if (totalValueCurrent < 0.0)
                  totalValueCurrent = 0.0;
            }
            if (xsArrayGetInt(gCardPriorities, card) > bestCardPri)
            {
               bestCardPri = xsArrayGetInt(gCardPriorities, card);
               bestCard = card;
            }
            else if ((xsArrayGetInt(gCardPriorities, card) == bestCardPri) &&
                     ((currentCardFlags & cHCCardFlagUnit) == cHCCardFlagUnit) && (totalValueCurrent > totalValueBest))
            { // If it's the same priority of a military unit card, take the one with the better value.
               bestCardPri = xsArrayGetInt(gCardPriorities, card);
               bestCard = card;
               totalValueBest = totalValueCurrent;
            }
         }
         if (bestCard >= 0)
         {
            if ((xsArrayGetInt(gCardPriorities, bestCard) < 6) && (cardsPicked >= 1))
               continue; // After the first card, only pick another if it's good.
            addCardToDeck(gDefaultDeck, bestCard);
            cardsRemaining = cardsRemaining - 1;
            xsArraySetString(gCardStates, bestCard, "D");
            // aiEcho("  6Adding card "+xsArrayGetString(gCardNames, bestCard));
            cardsPicked = cardsPicked + 1;
            cardsAge4 = cardsAge4 + 1;
            if ((aiHCCardsGetCardCount(bestCard) < 0) && (addedInfUnit == false))
               addedInfUnit = true;
         }
      } // 4-13 remaining.
      addedVillager = false;
      addedCrates = 0;
      toPick = 0;
      // Next, 2-3 age 4 cards.
      for (i = 0; < toPick)
      {
         bestCard = -1;
         bestCardPri = -1;
         currentCardFlags = 0;
         bestCardFlags = -1;
         totalValueCurrent = 0.0;
         totalValueBest = 0.0;
         totalCost = 0.0;
         for (card = 0; < maxCards)
         {
            if (xsArrayGetString(gCardStates, card) != "P")
               continue; // Only consider purchased cards not already in deck.
            if (aiHCCardsGetCardAgePrereq(card) != cAge4)
               continue;
            currentCardFlags = aiHCCardsGetCardFlags(card);
            if ((addedVillager == true) && ((currentCardFlags & cHCCardFlagVillager) == cHCCardFlagVillager))
               continue; // Don't add more than 1 villager card in age 4 for now
            if ((addedCrates >= 1) && ((currentCardFlags & cHCCardFlagResourceCrate) == cHCCardFlagResourceCrate) &&
                (xsArrayGetInt(gCardPriorities, card) < 10))
               continue; // Don't add more than 1 resource crate in age 4
            if (((currentCardFlags & cHCCardFlagUnit) == cHCCardFlagUnit) && (addedInfUnit == true) &&
                (aiHCCardsGetCardCount(card) < 0) && (xsArrayGetInt(gCardPriorities, card) < 10))
               continue; // Don't add more than 1 infinite military card for now.
            if ((xsArrayGetInt(gCardPriorities, card) == bestCardPri) &&
                ((currentCardFlags & cHCCardFlagMilitary) == cHCCardFlagMilitary) &&
                ((currentCardFlags & cHCCardFlagUnit) == cHCCardFlagUnit))
            { // If it's a military unit calculate a value for this card.
               totalValueCurrent = aiHCCardsGetCardValuePerResource(card, cResourceWood) +
                                   aiHCCardsGetCardValuePerResource(card, cResourceFood) +
                                   aiHCCardsGetCardValuePerResource(card, cResourceGold);
               totalCost = kbTechCostPerResource(aiHCCardsGetCardTechID(card), cResourceWood) +
                           kbTechCostPerResource(aiHCCardsGetCardTechID(card), cResourceFood) +
                           kbTechCostPerResource(aiHCCardsGetCardTechID(card), cResourceGold);
               totalValueCurrent = totalValueCurrent - totalCost;
               if (totalValueCurrent < 0.0)
                  totalValueCurrent = 0.0;
            }
            if (xsArrayGetInt(gCardPriorities, card) > bestCardPri)
            {
               bestCardPri = xsArrayGetInt(gCardPriorities, card);
               bestCard = card;
               bestCardFlags = currentCardFlags;
            }
            else if ((((currentCardFlags & cHCCardFlagVillager) == cHCCardFlagVillager) &&
                      ((bestCardFlags & cHCCardFlagVillager) == cHCCardFlagVillager) &&
                      (xsArrayGetInt(gCardPriorities, card) >= bestCardPri)) &&
                     (((aiHCCardsGetCardValuePerResource(bestCard, cResourceWood) > 0.0) &&
                       (aiHCCardsGetCardValuePerResource(card, cResourceWood) >
                        aiHCCardsGetCardValuePerResource(bestCard, cResourceWood))) ||
                      ((aiHCCardsGetCardValuePerResource(bestCard, cResourceFood) > 0.0) &&
                       (aiHCCardsGetCardValuePerResource(card, cResourceFood) >
                        aiHCCardsGetCardValuePerResource(bestCard, cResourceFood))) ||
                      ((aiHCCardsGetCardValuePerResource(bestCard, cResourceGold) > 0.0) &&
                       (aiHCCardsGetCardValuePerResource(card, cResourceGold) >
                        aiHCCardsGetCardValuePerResource(bestCard, cResourceGold)))))
            { // make sure more valuable villager cards win
               bestCardPri = xsArrayGetInt(gCardPriorities, card);
               bestCard = card;
               bestCardFlags = currentCardFlags;
            }
            else if ((((currentCardFlags & cHCCardFlagResourceCrate) == cHCCardFlagResourceCrate) &&
                      ((bestCardFlags & cHCCardFlagResourceCrate) == cHCCardFlagResourceCrate)) &&
                     (((aiHCCardsGetCardValuePerResource(bestCard, cResourceWood) > 0.0) &&
                       (aiHCCardsGetCardValuePerResource(card, cResourceWood) >
                        aiHCCardsGetCardValuePerResource(bestCard, cResourceWood))) ||
                      ((aiHCCardsGetCardValuePerResource(bestCard, cResourceFood) > 0.0) &&
                       (aiHCCardsGetCardValuePerResource(card, cResourceFood) >
                        aiHCCardsGetCardValuePerResource(bestCard, cResourceFood))) ||
                      ((aiHCCardsGetCardValuePerResource(bestCard, cResourceGold) > 0.0) &&
                       (aiHCCardsGetCardValuePerResource(card, cResourceGold) >
                        aiHCCardsGetCardValuePerResource(bestCard, cResourceGold)))))
            { // make sure more valuable resource cards for the same resource win
               bestCardPri = xsArrayGetInt(gCardPriorities, card);
               bestCard = card;
               bestCardFlags = currentCardFlags;
            }
            else if (((((currentCardFlags & cHCCardFlagResourceCrate) == cHCCardFlagResourceCrate) &&
                       ((bestCardFlags & cHCCardFlagResourceCrate) == cHCCardFlagResourceCrate)) &&
                      (xsArrayGetInt(gCardPriorities, card) >= bestCardPri)) &&
                     (((aiHCCardsGetCardValuePerResource(card, cResourceWood) > 0.0) &&
                       (aiHCCardsGetCardValuePerResource(card, cResourceWood) >=
                        aiHCCardsGetCardValuePerResource(bestCard, cResourceFood))) ||
                      ((aiHCCardsGetCardValuePerResource(card, cResourceGold) > 0.0) &&
                       (aiHCCardsGetCardValuePerResource(card, cResourceGold) >=
                        aiHCCardsGetCardValuePerResource(bestCard, cResourceFood)))))
            { // prioritize coin & wood, food
               bestCardPri = xsArrayGetInt(gCardPriorities, card);
               bestCard = card;
               bestCardFlags = currentCardFlags;
            }
            else if ((xsArrayGetInt(gCardPriorities, card) == bestCardPri) &&
                     ((currentCardFlags & cHCCardFlagMilitary) == cHCCardFlagMilitary) &&
                     ((currentCardFlags & cHCCardFlagUnit) == cHCCardFlagUnit) && (totalValueCurrent > totalValueBest))
            { // If it's the same priority of a military unit card, take the one with the better value.
               bestCardPri = xsArrayGetInt(gCardPriorities, card);
               bestCard = card;
               totalValueBest = totalValueCurrent;
            }
         }
         if (bestCard >= 0)
         {
            if ((xsArrayGetInt(gCardPriorities, bestCard) < 6) && (cardsPicked >= 2))
               continue; // After the first two cards, only pick another if it's good.
            addCardToDeck(gDefaultDeck, bestCard);
            cardsRemaining = cardsRemaining - 1;
            xsArraySetString(gCardStates, bestCard, "D");
            // aiEcho("  7Adding card "+xsArrayGetString(gCardNames, bestCard));
            cardsPicked = cardsPicked + 1;
            cardsAge4 = cardsAge4 + 1;
            if (((bestCardFlags & cHCCardFlagVillager) == cHCCardFlagVillager) && (addedVillager == false))
               addedVillager = true;
            if (((bestCardFlags & cHCCardFlagResourceCrate) == cHCCardFlagResourceCrate) && (addedCrates < 2))
               addedCrates = addedCrates + 1;
            if (((bestCardFlags & cHCCardFlagUnit) == cHCCardFlagUnit) && (aiHCCardsGetCardCount(bestCard) < 0) &&
                (addedInfUnit == false))
               addedInfUnit = true;
         }
      } // 1-10 remaining.
      totalValueCurrent = 0.0;
      totalValueBest = 0.0;
      totalCost = 0.0;
      // Finally, remaining cards from any age, usually military units
      // Villagers, Resource Crates, Mercenaries and Allies will be ignored here
      for (i = 0; < cardsRemaining)
      {
         bestCard = -1;
         bestCardPri = -1;
         currentCardFlags = 0;
         totalValueCurrent = 0.0;
         totalValueBest = 0.0;
         totalCost = 0.0;
         for (card = 0; < maxCards)
         {
            if (xsArrayGetString(gCardStates, card) != "P")
               continue; // Only consider purchased cards not already in deck.
            currentCardFlags = aiHCCardsGetCardFlags(card);
            if (((currentCardFlags & cHCCardFlagMercenary) == cHCCardFlagMercenary) ||
                (kbProtoUnitIsType(cMyID, aiHCCardsGetCardUnitType(card), cUnitTypeMercenary) == true))
               continue; // Ignore any mercenary cards
            if ((currentCardFlags & cHCCardFlagVillager) == cHCCardFlagVillager)
               continue; // Ignore villager cards
            if ((currentCardFlags & cHCCardFlagResourceCrate) == cHCCardFlagResourceCrate &&
                (btRushBoom <= 0.0 || aiHCCardsGetCardAgePrereq(card) != cAge2))
               continue; // Ignore resource crate cards
            if (kbProtoUnitIsType(cMyID, aiHCCardsGetCardUnitType(card), cUnitTypeypMercArsonist) == true)
               continue; // Ignore any arsonist cards (wrongly not classified as mercenary)
            if (((civIsNative() == true) || (civIsAsian() == true)) &&
                (kbProtoUnitIsType(cMyID, aiHCCardsGetCardUnitType(card), cUnitTypeMercType1) == true) &&
                (kbProtoUnitIsType(cMyID, aiHCCardsGetCardUnitType(card), cUnitTypexpSkullKnight) == false) &&
                (kbProtoUnitIsType(cMyID, aiHCCardsGetCardUnitType(card), cUnitTypexpDogSoldier) == false))
               continue; // For natives and Asians, ignore any native allies cards (excluding skull knights and dog
                         // soldiers, both wrongly classified as MercType1)
            if ((civIsNative() == true) &&
                ((kbProtoUnitIsType(cMyID, aiHCCardsGetCardUnitType(card), cUnitTypeRodelero) == true) ||
                 (kbProtoUnitIsType(cMyID, aiHCCardsGetCardUnitType(card), cUnitTypeCuirassier) == true) ||
                 (kbProtoUnitIsType(cMyID, aiHCCardsGetCardUnitType(card), cUnitTypeHalberdier) == true)))
               continue; // For natives, ignore any renegade cards
            if ((kbProtoUnitIsType(cMyID, aiHCCardsGetCardUnitType(card), cUnitTypeSaloonOutlawPistol) == true) ||
                (kbProtoUnitIsType(cMyID, aiHCCardsGetCardUnitType(card), cUnitTypeSaloonOutlawRider) == true) ||
                (kbProtoUnitIsType(cMyID, aiHCCardsGetCardUnitType(card), cUnitTypeSaloonOutlawRifleman) == true))
               continue; // Ignore any outlaw cards
            if (((currentCardFlags & cHCCardFlagUnit) == cHCCardFlagUnit) && (addedInfUnit == true) &&
                (aiHCCardsGetCardCount(card) < 0) && (xsArrayGetInt(gCardPriorities, card) < 10))
               continue; // Don't add more than one infinite military card for now.
            if (((aiHCCardsGetCardAgePrereq(card) == cAge1) && (cardsAge1 >= 10)) ||
                ((aiHCCardsGetCardAgePrereq(card) == cAge2) && (cardsAge2 >= 10)) ||
                ((aiHCCardsGetCardAgePrereq(card) == cAge3) && (cardsAge3 >= 10)) ||
                ((aiHCCardsGetCardAgePrereq(card) == cAge4) && (cardsAge4 >= 10)))
               continue; // Continue as we're already at our card limit for this age.
            if ((xsArrayGetInt(gCardPriorities, card) == bestCardPri) &&
                ((currentCardFlags & cHCCardFlagUnit) == cHCCardFlagUnit))
            { // If it's a unit calculate a value for this card.
               totalValueCurrent = aiHCCardsGetCardValuePerResource(card, cResourceWood) +
                                   aiHCCardsGetCardValuePerResource(card, cResourceFood) +
                                   aiHCCardsGetCardValuePerResource(card, cResourceGold);
               totalCost = kbTechCostPerResource(aiHCCardsGetCardTechID(card), cResourceWood) +
                           kbTechCostPerResource(aiHCCardsGetCardTechID(card), cResourceFood) +
                           kbTechCostPerResource(aiHCCardsGetCardTechID(card), cResourceGold);
               totalValueCurrent = totalValueCurrent - (totalCost / 2);
               if (totalValueCurrent < 0.0)
                  totalValueCurrent = 0.0;
            }
            if (xsArrayGetInt(gCardPriorities, card) > bestCardPri)
            {
               bestCardPri = xsArrayGetInt(gCardPriorities, card);
               bestCard = card;
               totalValueBest = totalValueCurrent;
            }
            else if ((xsArrayGetInt(gCardPriorities, card) == bestCardPri) &&
                     ((currentCardFlags & cHCCardFlagUnit) == cHCCardFlagUnit) && (totalValueCurrent > totalValueBest))
            { // If it's the same priority of a unit card, take the one with the better value.
               bestCardPri = xsArrayGetInt(gCardPriorities, card);
               bestCard = card;
               totalValueBest = totalValueCurrent;
            }
            else if ((xsArrayGetInt(gCardPriorities, card) == bestCardPri) &&
                     (aiHCCardsGetCardAgePrereq(bestCard) <= cAge2) &&
                     ((aiHCCardsGetCardAgePrereq(card) == cAge3) ||
                      ((cardsAge3 >= 10) && (aiHCCardsGetCardAgePrereq(card) >= cAge4) && (cardsAge4 < 10))))
            { // Prefer age 3 cards over 1 and 2.
               bestCardPri = xsArrayGetInt(gCardPriorities, card);
               bestCard = card;
               totalValueBest = totalValueCurrent;
            }
         }
         if (bestCard >= 0)
         {
            addCardToDeck(gDefaultDeck, bestCard);
            // cardsRemaining = cardsRemaining - 1;
            xsArraySetString(gCardStates, bestCard, "D");
            // aiEcho("  8Adding card "+xsArrayGetString(gCardNames, bestCard));
            if (aiHCCardsGetCardAgePrereq(bestCard) == cAge1)
               cardsAge1 = cardsAge1 + 1;
            if (aiHCCardsGetCardAgePrereq(bestCard) == cAge2)
               cardsAge2 = cardsAge2 + 1;
            if (aiHCCardsGetCardAgePrereq(bestCard) == cAge3)
               cardsAge3 = cardsAge3 + 1;
            if (aiHCCardsGetCardAgePrereq(bestCard) == cAge4)
               cardsAge4 = cardsAge4 + 1;
            if (((bestCardFlags & cHCCardFlagUnit) == cHCCardFlagUnit) && (aiHCCardsGetCardCount(bestCard) < 0) &&
                (addedInfUnit == false))
               addedInfUnit = true;
         }
      } // All done, no cards remaining.
      aiEcho("Activating deck");
      aiHCDeckActivate(gDefaultDeck);
      xsDisableSelf();
      break;
   }
   }
}

//==============================================================================
/* shipGrantedHandler()



   Update 02/10/2004:  New algorithm.
   1)  Clear the list
   2)  Get all the settlers you can.
   3)  If space remains, get the resource you're lowest on.

   Update on 04/22/2004:  New algorithm:
   1)  First year, get wood
   2)  Later years, get the resource that gives the largest bucket.
   3)  In a tie, coin > food > wood
   Note, in the early years, the resourceManager will sell food and buy wood as needed
   to drive early housing growth.

   Update on 4/27/2004:  Get wood for first TWO years.

   Scrapped on 5/12/2004.  Now, settlers have to be imported.  New logic:
   1)  Get settlers always, except:
   2)  If I can afford governor and I don't have him yet, get him
   3)  If I can afford viceroy and I don't have him yet and he's available, get him.
   4)  If settlers aren't available or less than 10 are available, get most needed resource.

   August:  Always get an age upgrade if you can.  Otherwise, compute the value for each bucket,
   and choose the best buy.

   November:  Adding multiplier for econ/mil units based on rush/boom emphasis
*/
//==============================================================================
void shipGrantedHandler(int parm = -1) // Event handler
{
   debugHCCards(" ");
   debugHCCards("SHIP GRANTED:");


   if (kbResourceGet(cResourceShips) < 1.0)
      return; // Early out if we don't have a ship...no point even checking.

   bool homeBaseUnderAttack = false;
   if (gDefenseReflexBaseID == kbBaseGetMainID(cMyID))
      homeBaseUnderAttack = true; // So don't send resources or settlers....

   debugHCCards("Choosing contents for next transport");

   bool result = false;

   // Adjust for rush or boominess
   float econBias = 0.0; // How much to boost econ units or penalize mil units
   // Flip rushboom sign so boomer is +1 and rusher is -1.
   econBias = (btRushBoom * -1.0);
   // Set econBias as a percentage boost or penalty for resources and settlers
   econBias = (econBias / 4.0) + 1.0; // +/- up to 25%

   int bestCard = -1;
   float bestUnitScore = -1.0;
   bool bestCardIsExtended = false;
   int unitType = -1;       // The current unit's ID.
   int unitCount = -1;      // How many unit types are available?
   int qtyAvail = -1;       // How many of each are available
   int ageReq = -1;         // What age do you need to use this card.
   int tech = -1;           // The techID for this card.
   string techName = "";    // The techName for this card.
   int flags = 0;           // The flags for this card.
   float totalValue = -1.0; // What is this bucket worth to me?
   float woodValue = -1.0;
   float foodValue = -1.0;
   float goldValue = -1.0;
   float influenceValue = -1.0;
   bool isMilitaryUnit = false;
   float totalResources = kbResourceGet(cResourceFood) + kbResourceGet(cResourceWood) + kbResourceGet(cResourceGold);
   int landUnitPickPrimary = kbUnitPickGetResult(gLandUnitPicker, 0);
   int landUnitPickSecondary = kbUnitPickGetResult(gLandUnitPicker, 1);
   int planID = -1;

   for (deckIndex = 0; < 2)
   {
      int deck = -1;
      bool extended = false;

      if (deckIndex == 0)
      {
         deck = gDefaultDeck;
         extended = false;
      }
      else
      {
         deck = aiHCGetExtendedDeck();
         extended = true;
      }

      if (deck < 0)
         continue;

      int totalCards = aiHCDeckGetNumberCards(deck);
      debugHCCards("**** Picking HC card to play, " + totalCards + " cards in deck");
      for (i = 0; < totalCards)
      {
         //-- Skip card if we can't play it.
         if (aiHCDeckCanPlayCard(i, extended) == false)
            continue;

         unitType = aiHCDeckGetCardUnitType(deck, i); // What is this unit?
         qtyAvail = aiHCDeckGetCardUnitCount(deck, i);
         ageReq = aiHCDeckGetCardAgePrereq(deck, i);
         tech = aiHCDeckGetCardTechID(deck, i);
         techName = kbGetTechName(tech);
         flags = aiHCDeckGetCardFlags(deck, i);
         totalValue = 0.0;

         // Calculate a value for this unit.  If not found, use its aiCost.
         switch (unitType)
         {
         case gGalleonUnit:
         {
            if ((gNavyMode == cNavyModeActive) && (gHaveWaterSpawnFlag == true) &&
                (gGalleonMaintain >= 0 && aiPlanGetVariableInt(gGalleonMaintain, cTrainPlanNumberToMaintain, 0) >
                                              kbUnitCount(cMyID, gGalleonUnit, cUnitStateABQ)))
            {
               woodValue = aiHCDeckGetCardValuePerResource(deck, i, cResourceWood);
               foodValue = aiHCDeckGetCardValuePerResource(deck, i, cResourceFood);
               goldValue = aiHCDeckGetCardValuePerResource(deck, i, cResourceGold);
               totalValue = woodValue + foodValue + goldValue;
            }
            break;
         }
         case gCaravelUnit:
         {
            if ((gNavyMode == cNavyModeActive) && (gHaveWaterSpawnFlag == true) &&
                (gCaravelMaintain >= 0 && aiPlanGetVariableInt(gCaravelMaintain, cTrainPlanNumberToMaintain, 0) >
                                              kbUnitCount(cMyID, gCaravelUnit, cUnitStateABQ)))
            {
               woodValue = aiHCDeckGetCardValuePerResource(deck, i, cResourceWood);
               foodValue = aiHCDeckGetCardValuePerResource(deck, i, cResourceFood);
               goldValue = aiHCDeckGetCardValuePerResource(deck, i, cResourceGold);
               totalValue = woodValue + foodValue + goldValue;
            }
            break;
         }
         case gFrigateUnit:
         {
            if ((gNavyMode == cNavyModeActive) && (gHaveWaterSpawnFlag == true) &&
                (gFrigateMaintain >= 0 && aiPlanGetVariableInt(gFrigateMaintain, cTrainPlanNumberToMaintain, 0) >
                                              kbUnitCount(cMyID, gFrigateUnit, cUnitStateABQ)))
            {
               woodValue = aiHCDeckGetCardValuePerResource(deck, i, cResourceWood);
               foodValue = aiHCDeckGetCardValuePerResource(deck, i, cResourceFood);
               goldValue = aiHCDeckGetCardValuePerResource(deck, i, cResourceGold);
               totalValue = woodValue + foodValue + goldValue;
            }
            break;
         }
         case gMonitorUnit:
         {
            if ((gNavyMode == cNavyModeActive) && (gHaveWaterSpawnFlag == true) &&
                (gMonitorMaintain >= 0 && aiPlanGetVariableInt(gMonitorMaintain, cTrainPlanNumberToMaintain, 0) >
                                              kbUnitCount(cMyID, gMonitorUnit, cUnitStateABQ)))
            {
               woodValue = aiHCDeckGetCardValuePerResource(deck, i, cResourceWood);
               foodValue = aiHCDeckGetCardValuePerResource(deck, i, cResourceFood);
               goldValue = aiHCDeckGetCardValuePerResource(deck, i, cResourceGold);
               totalValue = woodValue + foodValue + goldValue;
            }
            break;
         }
         case gFishingUnit:
         {
            if (gTimeToFish == false)
               totalValue = 0.0;
            else if ((cvOkToFish == true) && (gHaveWaterSpawnFlag == true))
            {
               woodValue = aiHCDeckGetCardValuePerResource(deck, i, cResourceWood);
               foodValue = aiHCDeckGetCardValuePerResource(deck, i, cResourceFood);
               goldValue = aiHCDeckGetCardValuePerResource(deck, i, cResourceGold);
               totalValue = woodValue + foodValue + goldValue;
            }
            break;
         }
         case cUnitTypeCoveredWagon:
         {
            int numberTCs = kbUnitCount(cMyID, cUnitTypeTownCenter, cUnitStateAlive);
            if (numberTCs < 1)
            {
               totalValue = 100000.0; // Trumps everything
            }
            else if (kbTechGetStatus(cTechDERevolutionBrazil) == cTechStatusActive)
            {
               if (numberTCs < 5)
                  totalValue = 2000.0;
            }
            else
            {
               int tcTarget = 1;
               if (kbGetAge() >= cAge3)
               {
                  tcTarget = 3;
                  if (cMyCiv == cCivOttomans)
                  {
                     tcTarget = 3;
                  }
               }
               if (tech == cTechDEHCHuankaSupport)
               {
                  tcTarget = tcTarget + 1;
                  qtyAvail = 1;
               }
               else if (tech == cTechDEHCResettlements)
                  qtyAvail = 1;
               // if (btRushBoom < 0.5)
               //   tcTarget = (-1.0 * btRushBoom) + 2.5;
               if ((kbUnitCount(cMyID, cUnitTypeTownCenter, cUnitStateAlive) < tcTarget) && (homeBaseUnderAttack == false))
                  totalValue = 1600.0 * qtyAvail;
               else if (
                   (kbUnitCount(cMyID, cUnitTypeTownCenter, cUnitStateAlive) < kbGetBuildLimit(cMyID, cUnitTypeTownCenter)) &&
                   (homeBaseUnderAttack == false))
                  totalValue = 400.0 * qtyAvail;
            }
            break;
         }
         case cUnitTypeOutpostWagon:
         {
            if ((kbUnitCount(cMyID, cUnitTypeOutpostWagon, cUnitStateABQ) +
                 kbUnitCount(cMyID, cUnitTypeOutpost, cUnitStateAlive)) < gNumTowers)
               totalValue = 600.0 * qtyAvail;
            if (homeBaseUnderAttack == true)
               totalValue = 0.0;
            break;
         }
         case cUnitTypeYPCastleWagon:
         {
            if ((kbUnitCount(cMyID, cUnitTypeYPCastleWagon, cUnitStateABQ) +
                 kbUnitCount(cMyID, cUnitTypeypCastle, cUnitStateAlive)) < gNumTowers)
               totalValue = 900.0 * qtyAvail;
            if (homeBaseUnderAttack == true)
               totalValue = 0.0;
            break;
         }
         case cUnitTypeFortWagon:
         {
            if ((cvOkToBuild == true) && (cvOkToBuildForts == true) && (homeBaseUnderAttack == false) &&
                (kbUnitCount(cMyID, cUnitTypeFortFrontier, cUnitStateABQ) +
                     kbUnitCount(cMyID, cUnitTypeFortWagon, cUnitStateAlive) <
                 1))
               totalValue = 5000.0; // Big, but smaller than TC wagon.
            break;
         }
         case cUnitTypeFactoryWagon:
         {
            if ((cvOkToBuild == true) && (homeBaseUnderAttack == false))
               totalValue = 2000.0 * qtyAvail; // Big, but smaller than TC wagon.
            break;
         }
         case cUnitTypeYPDojoWagon:
         {
           if ((cvOkToBuild == true) && (homeBaseUnderAttack == false))
               totalValue = 1500.0; // Big, but smaller than TC wagon.
            break;
         }
         case cUnitTypedeREVStarTrekWagon:
         {
            // Disable South Africa trek wagons, the AI doesn't know to handle them.
            totalValue = 1.0;
            break;
         }
         case cUnitTypexpMedicineManAztec:
         {
            // 3 warrior priests card should be lower than resource crates and villagers.
            totalValue = 200.0 * qtyAvail;
            if (homeBaseUnderAttack == true)
               totalValue = 1.0;
            break;
         }
         default:
         {
            woodValue = aiHCDeckGetCardValuePerResource(deck, i, cResourceWood) - kbTechCostPerResource(tech, cResourceWood);
            foodValue = aiHCDeckGetCardValuePerResource(deck, i, cResourceFood) - kbTechCostPerResource(tech, cResourceFood);
            goldValue = aiHCDeckGetCardValuePerResource(deck, i, cResourceGold) - kbTechCostPerResource(tech, cResourceGold);
            influenceValue = aiHCDeckGetCardValuePerResource(deck, i, cResourceInfluence) -
                             kbTechCostPerResource(tech, cResourceInfluence);
            totalValue = woodValue + foodValue + goldValue + influenceValue;

            if ((tech == cTechYPHCSpawnRefugees1) || (tech == cTechYPHCSpawnRefugees2) || (tech == cTechYPHCSpawnMigrants1))
            { // Handle 'Northern Refugees' (Chinese).
               if ((homeBaseUnderAttack == false) && ((kbUnitCount(cMyID, cUnitTypeypVillage, cUnitStateAlive) >= 1) ||
                                                      (kbUnitCount(cMyID, cUnitTypeTownCenter, cUnitStateAlive) >= 1)))
               {
                  qtyAvail =
                      (kbUnitCount(cMyID, cUnitTypeypVillage, cUnitStateAlive) +
                       kbUnitCount(cMyID, cUnitTypeTownCenter, cUnitStateAlive));
                  if (qtyAvail >= 2)
                     totalValue = 165 * qtyAvail;
                  if ((kbGetAge() >= cAge2) || (econBias > 1.0))
                     totalValue = totalValue * econBias; // Boomers prefer this, rushers rather skip.
                  if (homeBaseUnderAttack == true)
                     totalValue = 1.0;                  // Tiny...ANYTHING else is better
                  if (getSettlerShortfall() < qtyAvail) // We have enough settlers
                     totalValue = 190.0;
               }
               else
                  totalValue = 1.0; // Tiny...ANYTHING else is better
            }
            else if (
                ((unitType == cUnitTypeypSettlerIndian) || (unitType == cUnitTypedeChasqui)) && (qtyAvail == 1) &&
                (totalValue < 200.0))
               totalValue = 0.0; // Avoid rating upgrades too low because it'd base the value on the free unit instead.
            else if (
                ((flags & cHCCardFlagVillager) == cHCCardFlagVillager) || (unitType == cUnitTypeSettler) ||
                (unitType == cUnitTypeCoureur) || (unitType == cUnitTypeSettlerWagon) || (unitType == cUnitTypeSettlerNative) ||
                (unitType == cUnitTypeypSettlerAsian))
            {                                  // Handle villagers.
               totalValue = totalValue * 1.65; // Make sure we send villagers early to get the most value out of them.
               if ((kbGetAge() >= cAge2) || (econBias > 1.0))
                  totalValue = totalValue * econBias; // Boomers prefer this, rushers rather skip (except in age 1).
               if (homeBaseUnderAttack == true)
                  totalValue = 1.0;                  // Tiny...ANYTHING else is better
               if (getSettlerShortfall() < qtyAvail) // We have enough settlers
                  totalValue = 190.0;
            }
            /*else if (tech == cTechDEHCFedPlymouthSettlers)
            {
               // food crates + 3 piligrims per TC.
               totalValue = 300.0 + 100.0 * 1.65 * 3.0 * kbUnitCount(cMyID, cUnitTypeTownCenter, cUnitStateAlive);
               if (homeBaseUnderAttack == true)
                  totalValue = 1.0;
            }
            else if (tech == cTechDEHCImmigrantsIrish)
            {
               totalValue = 165 * (2 + xsGetTime() / 300000);
               if (totalValue > 2310.0)
                  totalValue = 2310.0;
               if (homeBaseUnderAttack == true)
                  totalValue = 1.0;
            }
            else if (tech == cTechDEHCFedMXTlaxcalaTextiles)
            {
               if (homeBaseUnderAttack == false)
                  totalValue = 165.0 * 3.0 * kbUnitCount(cMyID, cUnitTypedeHacienda, cUnitStateAlive);
               else
                  totalValue = 1.0;
            }*/
            if ((flags & cHCCardFlagResourceCrate) == cHCCardFlagResourceCrate)
            { // Handle resource crates.
               if ((foodValue > 0.0) && (kbGetAge() == cAge1) && (econBias <= 1.0) && (kbResourceGet(cResourceFood) < 800))
                  totalValue = totalValue / econBias; // Increase value for rusher in age 1 to age up faster.
               else if ((kbGetAge() == cAge1) || (totalResources >= 10000))
                  totalValue = totalValue / 2.0;
               /*if (woodValue > 0.0)
                  totalValue = totalValue * kbGetAICostWeight(cResourceWood);
               if (foodValue > 0.0)
                  totalValue = totalValue * kbGetAICostWeight(cResourceFood);
               if (goldValue > 0.0)
                  totalValue = totalValue * kbGetAICostWeight(cResourceGold);*/
               int mostResource = cResourceWood;
               if (influenceValue > 0.0)
               {
                  if (kbUnitCount(cMyID, cUnitTypeNativeEmbassy, cUnitStateAlive) +
                          kbUnitCount(cMyID, cUnitTypedePalace, cUnitStateAlive) >
                      0)
                     totalValue = totalValue - 0.2;
                  else
                     totalValue = 1.0;
               }
               else
               {
                  if (woodValue < foodValue || woodValue < goldValue)
                  {
                     if (foodValue < goldValue)
                        mostResource = cResourceGold;
                     else
                        mostResource = cResourceFood;
                  }
                  for (j = cResourceGold; <= cResourceFood)
                  {
                     // prioritize resources as appropriate
                     if (getCorrectedResourcePercentage(mostResource) < getCorrectedResourcePercentage(j))
                        totalValue = totalValue - 0.1;
                  }

                  if (gRevolutionType != 0)
                  {
                     if (xsArrayGetFloat(gResourceNeeds, mostResource) > 0.0)
                        totalValue = totalValue * 1.1;
                  }
               }
               if (homeBaseUnderAttack == true)
                  totalValue = 1.0; // Tiny...ANYTHING else is better
            }

            if ((homeBaseUnderAttack == false) &&
                ((tech == cTechHCXPAgrarianWays) || (tech == cTechDEHCTerraceFarming) ||
                 (tech == cTechHCSustainableAgriculture) || (tech == cTechHCSustainableAgricultureGerman) ||
                 (tech == cTechYPHCSustainableAgricultureIndians) || (tech == cTechHCXPLandGrab) ||
                 (tech == cTechYPHCLandGrabIndians)))
            { // Handle Farm/Plantation/Paddy upgrades.
               if ((aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, gPlantationUnit) >= 1) ||
                   (kbUnitCount(cMyID, gPlantationUnit, cUnitStateAlive) >= 1) || (gTimeToFarm == true) ||
                   (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, gFarmUnit) >= 1) ||
                   (kbUnitCount(cMyID, gFarmUnit, cUnitStateAlive) >= 1))
                  totalValue = 1120.0;
            }
            else if (
                (homeBaseUnderAttack == false) &&
                ((tech == cTechHCRumDistillery) || (tech == cTechHCRumDistilleryTeam) || (tech == cTechHCRumDistilleryGerman) ||
                 (tech == cTechYPHCRumDistilleryIndians)))
            { // Handle other Plantation/Paddy upgrades.
               if ((aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, gPlantationUnit) >= 1) ||
                   (kbUnitCount(cMyID, gPlantationUnit, cUnitStateAlive) >= 1))
                  totalValue = 1110.0;
               else if ((tech != cTechHCRumDistilleryTeam) || (getAllyCount() <= 0))
                  totalValue = 1.1;
            }

            /*if ((tech == cTechHCAdvancedTradingPost) ||
                (tech == cTechDEHCAdvancedTambos))
            {  // Handle 'Advanced Trading Post' and 'Advanced Tambos'.
               if ((homeBaseUnderAttack == false) && (kbUnitCount(cMyID, cUnitTypeTradingPost, cUnitStateAlive) >= 1))
                  totalValue = 1500.0;
               //else
               //   totalValue = 1.0;
            }*/
            if (((tech == cTechHCNativeTreaties) || (tech == cTechHCNativeTreatiesGerman) || (tech == cTechHCNativeWarriors) ||
                 (tech == cTechHCNativeWarriorsGerman) || (tech == cTechHCNativeCombat) || (tech == cTechHCNativeCombatTeam) ||
                 (tech == cTechYPHCNativeLearning) || (tech == cTechYPHCNativeLearningIndians) ||
                 (tech == cTechYPHCNativeDamage) || (tech == cTechYPHCNativeDamageIndians) ||
                 (tech == cTechYPHCNativeHitpoints) || (tech == cTechYPHCNativeHitpointsIndians) ||
                 (tech == cTechYPHCNativeIncorporation) || (tech == cTechYPHCNativeIncorporationIndians) ||
                 (tech == cTechHCWildernessWarfare) || (tech == cTechHCXPBlackArrow) ||
                 (tech == cTechHCNativeChampionsDutchTeam) || (tech == cTechHCNativeLore) ||
                 (tech == cTechHCNativeLoreGerman)) &&
                (xsArrayGetSize(kbVPSiteQuery(cVPNative, cMyID, cVPStateCompleted)) < 1))
               totalValue = 1.0; // Handle other shipments which rely on a Trading Post.
            if (((tech == cTechDEHCCequeSystem)) && (kbUnitCount(cMyID, cUnitTypeTradingPost, cUnitStateAlive) < 1))
               totalValue = 1.0;
            if (((tech == cTechYPHCNativeTradeTax) || (tech == cTechYPHCNativeTradeTaxIndians)) &&
                ((xsArrayGetSize(kbVPSiteQuery(cVPNative, cMyID, cVPStateCompleted)) < 1) ||
                 (kbUnitCount(cMyID, cUnitTypeypConsulate, cUnitStateAlive) < 1)))
               totalValue = 1.0; // Handle other shipments which rely on a Trading Post or Consulate.

            if (((tech == cTechHCSchooners) || (tech == cTechYPHCSchoonersIndians) || (tech == cTechYPHCSchoonersJapanese) ||
                 (tech == cTechHCRenderingPlant) || (tech == cTechHCRenderingPlantGerman) ||
                 (tech == cTechYPHCRenderingPlantIndians) || (tech == cTechHCFishMarket) || (tech == cTechHCFishMarketGerman) ||
                 (tech == cTechYPHCFishMarketIndians) || (tech == cTechypHCFishMarket) || (tech == cTechHCArmada) ||
                 (tech == cTechHCSpanishGalleons)) &&
                (kbUnitCount(cMyID, cUnitTypeDock, cUnitStateAlive) < 1))
               totalValue = 1.0; // Handle shipments which rely on a Dock.
			   
               totalValue = 1.0; // Handle shipments which rely on a Dock.
            if ((tech == cTechHCRoyalDecreeBritish) || (tech == cTechHCRoyalDecreeDutch) ||
                (tech == cTechHCRoyalDecreeFrench) || (tech == cTechHCRoyalDecreeGerman) ||
                (tech == cTechHCRoyalDecreeOttoman) || (tech == cTechHCRoyalDecreePortuguese) ||
                (tech == cTechHCRoyalDecreeRussian) || (tech == cTechHCRoyalDecreeSpanish))
            { // Handle 'Royal Decree'.
               if ((homeBaseUnderAttack == true) || (kbUnitCount(cMyID, cUnitTypeChurch, cUnitStateAlive) < 1) ||
                   (kbGetAge() < cAge3))
               {
                  totalValue = 100.0;
               }
               else if (kbGetAge() == cAge3)
               {
                  totalValue = 1000.0; // High priority in age4, default otherwise.
                  if (cMyCiv == cCivGermans)
                     totalValue = 1450.0; // Necessary to cope with uhlans being included in calculation
               }
               else if (kbGetAge() > cAge3)
               {
                  totalValue = 2500.0; // High priority in age4, default otherwise.
                  if (cMyCiv == cCivGermans)
                     totalValue = 3100.0; // Necessary to cope with uhlans being included in calculation
               }
            }

            if ((tech == cTechHCAdvancedArsenal) || (tech == cTechHCAdvancedArsenalGerman))
            { // Handle 'Advanced Arsenal'.
               if ((homeBaseUnderAttack == true) || (kbGetAge() == cAge1))
                  totalValue = 1.0;
               else if (kbUnitCount(cMyID, cUnitTypeArsenal, cUnitStateAlive) < 1)
                  totalValue = 0.0;
               else if (kbGetAge() >= cAge4)
               {
                  totalValue = 1505.0; // High priority in age4, default otherwise.
                  if (cMyCiv == cCivGermans)
                     totalValue = 4515.0; // Necessary to cope with uhlans being included in calculation
               }
            }

            if (tech == cTechHCXPNewWaysIroquois)
            { // Handle 'New Ways' (Iroquois).
               if ((homeBaseUnderAttack == true) || (kbUnitCount(cMyID, cUnitTypeLonghouse, cUnitStateAlive) < 1) ||
                   (kbGetAge() < cAge2))
                  totalValue = 1.0;
               else if (kbGetAge() >= cAge4)
                  totalValue = 1500.0; // High priority in age4, default otherwise.
            }
            if (tech == cTechHCXPNewWaysSioux)
            { // Handle 'New Ways' (Sioux).
               if ((homeBaseUnderAttack == true) || (kbUnitCount(cMyID, cUnitTypeTeepee, cUnitStateAlive) < 1) ||
                   (kbGetAge() < cAge2))
                  totalValue = 1.0;
               else if (kbGetAge() >= cAge4)
                  totalValue = 1500.0; // High priority in age4, default otherwise.
            }

            if ((tech == cTechDEHCMachuPicchu) && (cvOkToBuild == true) && (cvOkToBuildForts == true) &&
                (homeBaseUnderAttack == false))
               totalValue = 2500.0; // Big, but smaller than fort wagon.

            if ((tech == cTechHCMosqueConstruction) && (cMyCiv == cCivOttomans) &&
                (kbUnitCount(cMyID, cUnitTypeChurch, cUnitStateABQ) >= 1))
               totalValue = 1500.0; // High priority

            if (((tech == cTechHCBanks1) || (tech == cTechHCBanks2)) &&
                (kbUnitCount(cMyID, cUnitTypeBank, cUnitStateAlive) >= kbGetBuildLimit(cMyID, cUnitTypeBank)))
               totalValue = 1600.0;
            else if (
                ((tech == cTechHCBanks1) || (tech == cTechHCBanks2)) &&
                ((kbUnitCount(cMyID, cUnitTypeBank, cUnitStateAlive) < kbGetBuildLimit(cMyID, cUnitTypeBank)) &&
                 (kbUnitCount(cMyID, cUnitTypeBank, cUnitStateAlive) < 1)))
               totalValue = 800.0;

            if ((tech == cTechHCGermantownFarmers || tech == cTechDEHCImmigrantsGerman) && gTimeToFarm == false)
               totalValue = 1.0;

            if (tech == cTechHCShipBalloons && aiGetFallenExplorerID() >= 0)
               totalValue = 1.0;

            if (tech == cTechDEHCEngelsbergIronworks)
            {
               int torpQuery = createSimpleUnitQuery(cUnitTypedeTorp, cMyID, cUnitStateABQ);
               int numberTorps = kbUnitQueryExecute(torpQuery);
               int numberTorpsOnMine = 0;
               for (j = 0; < numberTorps)
               {
                  int torpID = kbUnitQueryGetResult(torpQuery, j);
                  if (getUnitCountByLocation(cUnitTypeAbstractMine, 0, cUnitStateAny, kbUnitGetPosition(torpID), 10.0) > 0)
                     numberTorpsOnMine = numberTorpsOnMine + 1;
               }
               totalValue = 90.0 * numberTorpsOnMine;
            }

            if (tech == cTechDEHCFedCulpeperMinutemen)
            {
               if (homeBaseUnderAttack == true)
                  totalValue = 80.0 * 1.5 * kbUnitCount(cMyID, cUnitTypeTownCenter, cUnitStateAlive);
               else
                  totalValue = 1.0;
            }

            if (tech == cTechDEHCGidanSarkin)
            {
               if (homeBaseUnderAttack == true)
                  totalValue = 1.0;
               else if (aiGetWorldDifficulty() < cDifficultyHard)
                  totalValue = 650.0;
               else
                  totalValue = 1400.0;
            }

            if (tech == cTechDEHCFedBostonTeaParty)
               totalValue = 1.0;

            // Revolution cards.
            if (gRevolutionType != 0)
            {
               if ((gRevolutionType & cRevolutionMilitary) == cRevolutionMilitary)
               {
                  if (tech == cTechDEHCREVDhimma || tech == cTechDEHCREVCitizenship || tech == cTechDEHCREVCitizenshipOutpost ||
                      tech == cTechDEHCREVAcehExports || tech == cTechDEHCREVMinasGerais || tech == cTechDEHCREVSalitrera)
                  {
                     // we are running out of resources, send the citizenship shipment to restore our economy.
                     //if (xsArrayGetFloat(gResourceNeeds, cResourceFood) > -1000.0 ||
                     //    xsArrayGetFloat(gResourceNeeds, cResourceWood) > -1000.0 ||
                     //   xsArrayGetFloat(gResourceNeeds, cResourceGold) > -1000.0)
                        totalValue = 3000.0;
                     //else
                     //   totalValue = 1.0;
                  }
               }
               if (tech == cTechDEHCREVNothernWilderness)
               {
                  // we are running out of resources, send the citizenship shipment to restore our economy.
                  if (xsArrayGetFloat(gResourceNeeds, cResourceFood) > -1000.0 ||
                      xsArrayGetFloat(gResourceNeeds, cResourceGold) > -1000.0)
                     totalValue = 3000.0;
                  else
                     totalValue = 1.0;
               }
               if (tech == cTechDEHCREVBlackberries)
                  totalValue = 115.0 * kbUnitCount(cMyID, gHouseUnit, cUnitStateAlive);
               if (tech == cTechDEHCREVShipXhosaFoods)
                  totalValue = 900.0; // exclude the herdables
               //if (tech == cTechDEHCREVHuguenots)
                //  totalValue = 1.0; // Allow coureurs to be trained
               if (tech == cTechDEHCREVShipHomesteadWagons)
               {
                  if ((aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, gFarmUnit) >= 0 ||
                       aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, gPlantationUnit) >= 0) &&
                      xsArrayGetFloat(gResourceNeeds, cResourceWood) >= 600.0)
                     totalValue = 2000.0;
               }
            }

            if ((totalValue < 1.0) && (ageReq >= cAge1))
            { // Set a min value based on age
               if (gRevolutionType == 0)
               {
                  switch (ageReq)
                  {
                  case cAge1:
                  {
                     totalValue = 200.0;
                     break;
                  }
                  case cAge2:
                  {
                     totalValue = 450.0;
                     break;
                  }
                  case cAge3:
                  {
                     totalValue = 750.0;
                     break;
                  }
                  case cAge4:
                  {
                     totalValue = 1100.0;
                     break;
                  }
                  case cAge5:
                  {
                     totalValue = 1100.0;
                     break;
                  }
                  }
               }
               else
               {
                  totalValue = 1500.0;
               }
            }

            break;
         }
         }

         if (((tech == cTechHCXPLandGrab) || (tech == cTechYPHCLandGrabIndians)) &&
                 (((cMyCiv == cCivChinese) || (cMyCiv == cCivSPCChinese)) &&
                  (kbUnitCount(cMyID, cUnitTypeypVillage, cUnitStateAlive) < kbGetBuildLimit(cMyID, cUnitTypeypVillage))) ||
             (((cMyCiv == cCivIndians) || (cMyCiv == cCivSPCIndians)) &&
              (kbUnitCount(cMyID, cUnitTypeypSacredField, cUnitStateAlive) < kbGetBuildLimit(cMyID, cUnitTypeypSacredField))))
            totalValue = totalValue * 1.1;

         int mainBaseID = kbBaseGetMainID(cMyID);
         float maxDistance = kbBaseGetMaximumResourceDistance(cMyID, mainBaseID);
         // Handle cards which ships resources to delay our time to start farming
         if ((gTimeToFarm == false) &&
             (kbProtoUnitIsType(cMyID, unitType, cUnitTypeHuntable) == true || unitType == cUnitTypeYPBerryWagon1))
         {
            int foodAmount = 0;
            if (cMyCiv == cCivJapanese || cMyCiv == cCivSPCJapanese || cMyCiv == cCivSPCJapaneseEnemy)
            {
               foodAmount = kbGetAmountValidResources(mainBaseID, cResourceFood, cAIResourceSubTypeEasy, maxDistance);
               foodAmount = foodAmount + (kbUnitCount(cMyID, cUnitTypeYPBerryWagon1, cUnitStateAlive) +
                                          kbUnitCount(cMyID, cUnitTypeypBerryBuilding, cUnitStateBuilding)) *
                                             5000.0;
            }
            else
               foodAmount = kbGetAmountValidResources(mainBaseID, cResourceFood, cAIResourceSubTypeHunt, maxDistance);
            float percentOnFood = getCorrectedResourcePercentage(cResourceFood);
            int numFoodGatherers = percentOnFood * kbUnitCount(cMyID, gEconUnit, cUnitStateAlive);
            if (numFoodGatherers < 1)
               numFoodGatherers = 1;
            int foodPerGatherer = foodAmount / numFoodGatherers;
            if (foodPerGatherer < 300)
               totalValue = totalValue * 1.2;
         }
         if ((gTimeForPlantations == false) &&
             (unitType == cUnitTypedeProspectorWagon || unitType == cUnitTypedeProspectorWagonGold ||
              unitType == cUnitTypedeProspectorWagonSilver || unitType == cUnitTypedeProspectorWagonCoal ||
              unitType == cUnitTypedeREVProspectorWagon))
         {
            int goldAmount = kbGetAmountValidResources(mainBaseID, cResourceGold, cAIResourceSubTypeEasy, maxDistance);
            float percentOnGold = getCorrectedResourcePercentage(cResourceGold);
            int numGoldGatherers = percentOnGold * kbUnitCount(cMyID, gEconUnit, cUnitStateAlive);

            goldAmount = goldAmount + (kbUnitCount(cMyID, cUnitTypedeProspectorWagon, cUnitStateAlive) +
                                       kbUnitCount(cMyID, cUnitTypedeProspectorWagonGold, cUnitStateAlive) +
                                       kbUnitCount(cMyID, cUnitTypedeProspectorWagonSilver, cUnitStateAlive) +
                                       kbUnitCount(cMyID, cUnitTypedeProspectorWagonCoal, cUnitStateAlive)) *
                                          2000.0;
            goldAmount = goldAmount + kbUnitCount(cMyID, cUnitTypedeREVProspectorWagon, cUnitStateAlive) * 100000.0;

            if (numGoldGatherers < 1)
               numGoldGatherers = 1;
            int goldPerGatherer = goldAmount / numGoldGatherers;
            if (goldPerGatherer < 300)
               totalValue = totalValue * 1.2;
         }
         if ((unitType == cUnitTypeYPGroveWagon) ||
             (tech == cTechDEHCREVTreeSpawn &&
              (kbUnitCount(cMyID, cUnitTypeHouseEast, cUnitStateAlive) + kbUnitCount(cMyID, gHouseUnit, cUnitStateAlive) +
               kbUnitCount(cMyID, cUnitTypeBlockhouse, cUnitStateAlive)) > 15))
         {
            int woodAmount = kbGetAmountValidResources(mainBaseID, cResourceWood, cAIResourceSubTypeEasy, maxDistance);
            float percentOnWood = getCorrectedResourcePercentage(cResourceWood);
            int numWoodGatherers = percentOnWood * kbUnitCount(cMyID, gEconUnit, cUnitStateAlive);
            woodAmount = woodAmount + (kbUnitCount(cMyID, cUnitTypeYPGroveWagon, cUnitStateAlive) +
                                       kbUnitCount(cMyID, cUnitTypeypGroveBuilding, cUnitStateBuilding)) *
                                          5000.0;
            if (numWoodGatherers < 1)
               numWoodGatherers = 1;
            int woodPerGatherer = woodAmount / numWoodGatherers;
            if (woodPerGatherer < 300)
               totalValue = totalValue * 1.2;
         }

         if (tech == cTechDEHCDominions && (needMoreHouses() == true))
            totalValue = totalValue * 1.1;

         isMilitaryUnit = (((flags & cHCCardFlagMilitary) == cHCCardFlagMilitary) &&
                           ((flags & cHCCardFlagUnit) == cHCCardFlagUnit) && ((flags & cHCCardFlagWater) == 0)) ||
                          (kbProtoUnitIsType(cMyID, unitType, cUnitTypeLogicalTypeLandMilitary));
         if ((kbGetAge() < cAge3) && (isMilitaryUnit == true) && (homeBaseUnderAttack == false))
            totalValue = totalValue / econBias; // Decrease value of military unit for boomer.
         if ((kbGetAge() < cAge2) && (isMilitaryUnit == true) && (homeBaseUnderAttack == false) &&
             (cvOkToGatherNuggets == false))
            totalValue = 0.1; // No military units before age 2, except if we're allowed to gather nuggets or are under attack.
         if ((aiTreatyGetEnd() > xsGetTime() + 10 * 60 * 1000) && (isMilitaryUnit == true))
            totalValue = 0.1;
         if ((landUnitPickPrimary >= 0) && (((unitType >= 0) && (unitType == landUnitPickPrimary)) ||
                                            (kbTechAffectsUnit(tech, landUnitPickPrimary) == true &&
                                             ((kbUnitCount(cMyID, landUnitPickPrimary, cUnitStateABQ) *
                                               (kbUnitCostPerResource(landUnitPickPrimary, cResourceGold) +
                                                kbUnitCostPerResource(landUnitPickPrimary, cResourceWood) +
                                                kbUnitCostPerResource(landUnitPickPrimary, cResourceFood))) > 1000.0) &&
                                             (flags & cHCCardFlagTrainPoints) == 0)))
            totalValue = totalValue * 1.4; // It's affecting what we're trying to train with highest priority
         else if (
             (landUnitPickSecondary >= 0) && (((unitType >= 0) && (unitType == landUnitPickSecondary)) ||
                                              (kbTechAffectsUnit(tech, landUnitPickSecondary) == true &&
                                               ((kbUnitCount(cMyID, landUnitPickSecondary, cUnitStateABQ) *
                                                 (kbUnitCostPerResource(landUnitPickSecondary, cResourceGold) +
                                                  kbUnitCostPerResource(landUnitPickSecondary, cResourceWood) +
                                                  kbUnitCostPerResource(landUnitPickSecondary, cResourceFood))) > 1000.0) &&
                                               (flags & cHCCardFlagTrainPoints) == 0)))
            totalValue = totalValue * 1.2; // It's affecting what we're trying to train with 2nd highest priority
         if (((flags & cHCCardFlagTrickleGold) == cHCCardFlagTrickleGold) ||
             ((flags & cHCCardFlagTrickleWood) == cHCCardFlagTrickleWood) ||
             ((flags & cHCCardFlagTrickleFood) == cHCCardFlagTrickleFood) ||
             ((flags & cHCCardFlagTrickleXP) == cHCCardFlagTrickleXP) ||
             ((flags & cHCCardFlagTrickleTrade) == cHCCardFlagTrickleTrade) || (tech == cTechYPHCIncreasedTribute) ||
             (tech == cTechDEHCCequeSystem) || (tech == cTechDEHCChichaBrewing) || (tech == cTechHCXPBankWagon) ||
             (tech == cTechHCBetterBanks) || (tech == cTechHCCheaperManors) || (tech == cTechHCXPAdoption) ||
             //(tech == cTechHCSilkRoadTeam) ||
             (tech == cTechHCXPSpanishGold) || (tech == cTechHCXPOldWaysIroquois) || (tech == cTechHCXPOldWaysSioux) ||
             (tech == cTechHCXPOldWaysAztec) ||
             (tech == cTechDEHCOldWaysInca)) // Cards which should be sent early for best value
            totalValue = totalValue * 2.3;   // Priority slightly lower than 3 villagers (age1) but higher than most cards
                                             // of the next higher age
         // Handle cards which changes gather rate, slightly lower than age1 villagers card
         if (((flags & cHCCardFlagGatherRate) == cHCCardFlagGatherRate) &&
             (kbTechAffectsUnit(tech, cUnitTypeAbstractVillager) == true))
         {
            static int resourceTypes = -1;
            static int resourceSubTypes = -1;
            if (resourceTypes < 0)
            {
               resourceTypes = xsArrayCreateInt(9, 0, "Resource Types");
               resourceSubTypes = xsArrayCreateInt(9, 0, "Resource Sub Types");

               xsArraySetInt(resourceTypes, 0, cResourceFood);
               xsArraySetInt(resourceSubTypes, 0, cAIResourceSubTypeEasy);
               xsArraySetInt(resourceTypes, 1, cResourceFood);
               xsArraySetInt(resourceSubTypes, 1, cAIResourceSubTypeHunt);
               xsArraySetInt(resourceTypes, 2, cResourceFood);
               xsArraySetInt(resourceSubTypes, 2, cAIResourceSubTypeHerdable);
               xsArraySetInt(resourceTypes, 3, cResourceFood);
               xsArraySetInt(resourceSubTypes, 3, cAIResourceSubTypeFarm);
               xsArraySetInt(resourceTypes, 4, cResourceFood);
               xsArraySetInt(resourceSubTypes, 4, cAIResourceSubTypeFish);
               xsArraySetInt(resourceTypes, 5, cResourceWood);
               xsArraySetInt(resourceSubTypes, 5, cAIResourceSubTypeEasy);
               xsArraySetInt(resourceTypes, 6, cResourceGold);
               xsArraySetInt(resourceSubTypes, 6, cAIResourceSubTypeEasy);
               xsArraySetInt(resourceTypes, 7, cResourceGold);
               xsArraySetInt(resourceSubTypes, 7, cAIResourceSubTypeFarm);
               xsArraySetInt(resourceTypes, 8, cResourceGold);
               xsArraySetInt(resourceSubTypes, 8, cAIResourceSubTypeFish);
            }

            int resourceType = -1;
            int resourceSubType = -1;
            float numResourceGatherers = 0;
            float numGatherers = kbUnitCount(cMyID, cUnitTypeAbstractVillager, cUnitStateAlive);
            for (j = 0; < 9)
            {
               resourceType = xsArrayGetInt(resourceTypes, j);
               resourceSubType = xsArrayGetInt(resourceSubTypes, j);
               numResourceGatherers = aiGetNumberGatherers(cUnitTypeAbstractVillager, resourceType, resourceSubType);
               if (kbTechAffectsWorkRate(tech, resourceType, resourceSubType) == true)
               {
                  if ((numResourceGatherers / numGatherers) >= 0.35)
                     totalValue = totalValue * 2.3;
                  else
                     totalValue = totalValue * 1.1;
                  break;
               }
            }
         }

         // Don't send navy shipments when navy mode isn't active.
         if (((flags & cHCCardFlagTeam) == cHCCardFlagMilitary) && ((flags & cHCCardFlagTeam) == cHCCardFlagWater) &&
             gNavyMode != cNavyModeActive)
            totalValue = 0.1;
         if ((flags & cHCCardFlagTeam) == cHCCardFlagTeam)
            totalValue = totalValue *
                         (1.0 + 0.1 * getAllyCount()); // Slight prefererence for team cards when we have at least one ally

         // Don't send cards we can't recognize in age1.
         if (((flags & (cHCCardFlagVillager | cHCCardFlagResourceCrate | cHCCardFlagTrickleGold | cHCCardFlagTrickleWood |
                        cHCCardFlagTrickleFood | cHCCardFlagTrickleXP | cHCCardFlagGatherRate)) == 0) &&
             (kbGetAge() == cAge1))
            totalValue = 0.1;

         if ((homeBaseUnderAttack == true) && (isMilitaryUnit == true))
            totalValue = totalValue * 1.5; // Prioritize military units when under attack.
         else if ((isMilitaryUnit == true) && (aiHCDeckGetCardCount(deck, i) >= 0) && (aiTreatyActive() == false))
            totalValue = totalValue * 1.1; // Higher preference on limited military unit shipments when fighting is possible.
         else if ((aiHCDeckGetCardCount(deck, i) < 0) && (totalValue >= 200.0) && (gRevolutionType == 0))
         { // Otherwise prefer to get limited shipments before infinite ones.
            totalValue = 2.0 + ageReq;
            if ((flags & cHCCardFlagResourceCrate) == cHCCardFlagResourceCrate)
            { // Prioritize inf resource crates vs inf unit shipments.
               if ((totalResources >= 1600.0) && ((econBias < 1.0) || (totalResources >= 3200.0)))
                  totalValue = totalValue - 3.5;
               else
                  totalValue = totalValue + 3.5;
            }
         }
         debugHCCards(
            "    " + i + " " + kbGetProtoUnitName(unitType) + " (" + kbGetTechName(tech) + "): " + qtyAvail +
            " total value: " + totalValue);

         if (totalValue > bestUnitScore)
         {
            bestUnitScore = totalValue;
            bestCard = i;
            bestCardIsExtended = extended;
         }
      }
   }

   if ((agingUp() == true) && (homeBaseUnderAttack == false) && (bestUnitScore <= 450.0))
   { // We're aging up, are not under attack and are not missing any important shipment. Save this shipment for next
     // age.
      debugHCCards("We're aging up, delaying this shipment until then.");
      return;
   }

   // Don't send more than 1 cards in age 1 on harder difficulties.
   if (aiGetWorldDifficulty() >= cDifficultyHard)
   {
      static int numberCardsSentDuringAge1 = 0;
      if (kbGetAge() == cAge1)
      {
         if (numberCardsSentDuringAge1 >= 1)
         {
            debugHCCards("We only want 1 cards at most during the first age.");
            return;
         }
         numberCardsSentDuringAge1 = numberCardsSentDuringAge1 + 1;
      }
   }

   if (bestCard >= 0)
   {
      // Where to drop shipment.
      if (aiGetWorldDifficulty() >= cDifficultyExpert)
      {
         int gatherUnitID = -1;

         if (bestCardIsExtended == false)
            deck = gDefaultDeck;
         else
            deck = aiHCGetExtendedDeck();
         flags = aiHCDeckGetCardFlags(deck, bestCard);

         isMilitaryUnit = (((flags & cHCCardFlagMilitary) == cHCCardFlagMilitary) &&
                           ((flags & cHCCardFlagUnit) == cHCCardFlagUnit) && ((flags & cHCCardFlagWater) == 0)) ||
                          (kbProtoUnitIsType(cMyID, unitType, cUnitTypeLogicalTypeLandMilitary));

         if (isMilitaryUnit == true)
         {
            planID = aiPlanGetIDByTypeAndVariableType(cPlanCombat, cCombatPlanCombatType, cCombatPlanCombatTypeAttack);
            if (planID >= 0 && aiPlanGetVariableBool(planID, cCombatPlanAllowMoreUnitsDuringAttack, 0) == true)
            {
               if (cMyCiv == cCivJapanese)
               {
                  int daimyoQuery = createSimpleUnitQuery(cUnitTypeAbstractDaimyo, cMyID, cUnitStateAlive);
                  int numDaimyos = kbUnitQueryExecute(daimyoQuery);
                  for (i = 0; < numDaimyos)
                  {
                     int daimyoID = kbUnitQueryGetResult(daimyoQuery, i);
                     if (kbUnitGetPlanID(daimyoID) != planID)
                        continue;
                     gatherUnitID = daimyoID;
                  }
               }
               if (gatherUnitID < 0 && gForwardBaseID >= 0)
               {
                  gatherUnitID = findBestHCGatherUnit(gForwardBaseID);
               }
            }
         }

         if (gatherUnitID < 0)
            gatherUnitID = findBestHCGatherUnit(kbBaseGetMainID(cMyID));

         aiSetHCGatherUnit(gatherUnitID);
      }
      debugHCCards("  Choosing card " + bestCard);
      aiHCDeckPlayCard(bestCard, bestCardIsExtended);
   }
   if (aiHCDeckGetCardCount(deck, i) >= 0)
            totalValue = 1 + (totalValue * 0.1);
		else
            totalValue = 1 + (totalValue * 10.0);
}

//==============================================================================
// extraShipMonitor
// Watches for extra ships...granted in bulk via scenario, or
// due to oversight in shipGrantedHandler()?
//==============================================================================
rule extraShipMonitor
inactive
group tcComplete
minInterval 20
{
   if (kbResourceGet(cResourceShips) > 0)
      shipGrantedHandler(); // Spend the surplus
}