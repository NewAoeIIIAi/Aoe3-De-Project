//==============================================================================
/* aiTechs.xs

   This file contains stuffs for managing techs including age upgrades.

*/
//==============================================================================

//==============================================================================
// chooseEuropeanPolitician()
// Chooses age-up politicians or revolutions for European civilizations
//==============================================================================
int chooseEuropeanPolitician()
{
   int position = 0;
   int randomizer = -1;
   int numChoices = -1;
   int politician = -1;
   int bestChoice = 0;
   int bestScore = 0;
   int puid = -1;
   // Reset score array
   for (i=0; < 10)
      xsArraySetInt(gPoliticianScores, i, 0);
   // Choose politician
   switch (kbGetAge())
   {
      case cAge1:
      {  // Governor for turtler, resources or settlers for rusher
         randomizer = aiRandInt(10); // 0-9
         // Create array of politicians to choose from
         for (i=0; <xsArrayGetSize(gAge2PoliticianList))											  
         {
             politician = xsArrayGetInt(gAge2PoliticianList, i);
             if (kbTechGetStatus(politician) == cTechStatusObtainable)
             {
                xsArraySetInt(gAgeUpPoliticians, position, politician);
                position = position + 1;
             }
         }
         // Weight politicians as appropriate
         numChoices = position;
         for (i=0; <numChoices)						
         {
            politician = xsArrayGetInt(gAgeUpPoliticians, i);
			if (politician == cTechDEPoliticianFederalPennsylvania)
				{
					xsArraySetInt(gPoliticianScores, i, xsArrayGetInt(gPoliticianScores, i) + 100);
				}
            if (politician == cTechDEPoliticianInventor && (kbUnitCount(cMyID, cUnitTypeHomeCityWaterSpawnFlag) > 0))
            {
               xsArraySetInt(gPoliticianScores, i, xsArrayGetInt(gPoliticianScores, i) + 10);
            }
            else if (btOffenseDefense < 0.0)																							  
            {
               if (politician == cTechPoliticianGovernor)
               {
                  xsArraySetInt(gPoliticianScores, i, xsArrayGetInt(gPoliticianScores, i) + 0);
               }
            }
            //else
            //{
               if ((politician == cTechDEPoliticianLogisticianSwedish) || (politician == cTechDEPoliticianLogisticianPortuguese))
               {
                  xsArraySetInt(gPoliticianScores, i, xsArrayGetInt(gPoliticianScores, i) + 100);
               }
               else			   
               if (politician == cTechPoliticianQuartermaster)
               {
                  xsArraySetInt(gPoliticianScores, i, xsArrayGetInt(gPoliticianScores, i) + 100);
               }
               else			   
               if (politician == cTechPoliticianPhilosopherPrince)
               {
                  xsArraySetInt(gPoliticianScores, i, xsArrayGetInt(gPoliticianScores, i) + 100);
               }	   
            //}
            if (btRushBoom > 0.0)
            {
               if ((politician == cTechPoliticianGovernor) ||
                   (politician == cTechPoliticianNaturalist))
               {
                  xsArraySetInt(gPoliticianScores, i, xsArrayGetInt(gPoliticianScores, i) - 100);
               }
            }
         }
         // Add random bonus
         randomizer = aiRandInt(numChoices);
         xsArraySetInt(gPoliticianScores, randomizer, xsArrayGetInt(gPoliticianScores, randomizer) + 5);
         // Choose politician with best score
         for (i=0; <numChoices)									  
         {
            if (xsArrayGetInt(gPoliticianScores, i) >= bestScore)
            {
               bestScore = xsArrayGetInt(gPoliticianScores, i);
               bestChoice = i;
            }
         }
         politician = xsArrayGetInt(gAgeUpPoliticians, bestChoice);
         break;
      }
      case cAge2:
      {  // Randomized, but heavily biased towards Admiral or Pirate for water maps
         randomizer = aiRandInt(10); // 0-9
         // Create array of politicians to choose from
         for (i=0; <xsArrayGetSize(gAge3PoliticianList))												  
         {
             politician = xsArrayGetInt(gAge3PoliticianList, i);
             if (kbTechGetStatus(politician) == cTechStatusObtainable)
             {
                xsArraySetInt(gAgeUpPoliticians, position, politician);
                position = position + 1;
             }
         }
         // Weight politicians as appropriate
         numChoices = position;
         for (i=0; <numChoices)																				 
         {
            politician = xsArrayGetInt(gAgeUpPoliticians, i);
            if ((kbUnitCount(cMyID, cUnitTypeHomeCityWaterSpawnFlag) > 0) ||
                ((randomizer < 5) && (kbUnitCount(cMyID, cUnitTypeHomeCityWaterSpawnFlag) > 0)))
            {
               if ((politician == cTechPoliticianAdmiral) ||
                   (politician == cTechPoliticianAdmiralOttoman) ||
                   (politician == cTechPoliticianPirate))
               {
                  xsArraySetInt(gPoliticianScores, i, xsArrayGetInt(gPoliticianScores, i) + 10);
               }
            }
			if (politician == cTechDEPoliticianFederalNewHampshire)
				{
					xsArraySetInt(gPoliticianScores, i, xsArrayGetInt(gPoliticianScores, i) + 5);
				}
            if (kbUnitCount(cMyID, cUnitTypeHomeCityWaterSpawnFlag) == 0)
            {
               if ((politician == cTechPoliticianAdmiral) ||
                   (politician == cTechPoliticianAdmiralOttoman) ||
                   (politician == cTechPoliticianPirate))
               {
                  xsArraySetInt(gPoliticianScores, i, xsArrayGetInt(gPoliticianScores, i) - 10);
               }
            }
			if ((politician == cTechDEPoliticianMercContractorFortressOttoman) && (kbGetCiv() == cCivOttomans))
			{
				xsArraySetInt(gPoliticianScores, i, xsArrayGetInt(gPoliticianScores, i) + 200);																			
            }
            if (politician == cTechPoliticianBishopFortress && btRushBoom < 0.0)
				xsArraySetInt(gPoliticianScores, i, xsArrayGetInt(gPoliticianScores, i) + 10);  
            if (randomizer < 7)																  
            {
               puid = kbTechGetProtoUnitID(politician);
               if (politician == cTechDEPoliticianPapalGuardBritish &&
                  (kbUnitPickGetResult(gLandUnitPicker, 0) == cUnitTypePikeman ||
                   kbUnitPickGetResult(gLandUnitPicker, 1) == cUnitTypePikeman ||
                   kbUnitPickGetResult(gLandUnitPicker, 0) == cUnitTypeLongbowman ||
                   kbUnitPickGetResult(gLandUnitPicker, 1) == cUnitTypeLongbowman))
                  xsArraySetInt(gPoliticianScores, i, xsArrayGetInt(gPoliticianScores, i) + 5);
               else if (puid == kbUnitPickGetResult(gLandUnitPicker, 0) ||
                        puid == kbUnitPickGetResult(gLandUnitPicker, 1))
                  xsArraySetInt(gPoliticianScores, i, xsArrayGetInt(gPoliticianScores, i) + 5);      
            }
            if (politician == cTechDEPoliticianInventorFortress &&
                (kbTechGetStatus(cTechdeEnableBalloonPower) == cTechStatusActive ||
                aiGetFallenExplorerID() >= 0))
               xsArraySetInt(gPoliticianScores, i, xsArrayGetInt(gPoliticianScores, i) - 10);  
         }
         // Add random bonus
         randomizer = aiRandInt(numChoices);
         xsArraySetInt(gPoliticianScores, randomizer, xsArrayGetInt(gPoliticianScores, randomizer) + 5);
         // Choose politician with best score
         for (i=0; <numChoices)												  
         {
            if (xsArrayGetInt(gPoliticianScores, i) >= bestScore)
            {
               bestScore = xsArrayGetInt(gPoliticianScores, i);
               bestChoice = i;
            }
         }
         politician = xsArrayGetInt(gAgeUpPoliticians, bestChoice);
         break;
      }
      case cAge3:
      {  // Randomized, but slightly biased towards the Engineer and Papal Guard
         randomizer = aiRandInt(10); // 0-9
         // Create array of politicians to choose from
         for (i=0; <xsArrayGetSize(gAge4PoliticianList))
         {
             politician = xsArrayGetInt(gAge4PoliticianList, i);
             if (kbTechGetStatus(politician) == cTechStatusObtainable)
             {
                xsArraySetInt(gAgeUpPoliticians, position, politician);
                position = position + 1;
             }
         }
         // Weight politicians as appropriate
         numChoices = position;
         for (i=0; <numChoices)				
         {
            politician = xsArrayGetInt(gAgeUpPoliticians, i);
            if (randomizer < 3)																							   
            {
               puid = kbTechGetProtoUnitID(politician);
               if (puid == kbUnitPickGetResult(gLandUnitPicker, 0) ||
                   puid == kbUnitPickGetResult(gLandUnitPicker, 1))
                  xsArraySetInt(gPoliticianScores, i, xsArrayGetInt(gPoliticianScores, i) + 5);   
            }
            else
            {
               if ((politician == cTechDEPoliticianPapalGuard ||
                    politician == cTechDEPoliticianPapalGuardPortuguese ||
                    politician == cTechDEPoliticianPapalGuardSwedish) &&
                   (kbUnitPickGetResult(gLandUnitPicker, 0) == cUnitTypePikeman ||
                    kbUnitPickGetResult(gLandUnitPicker, 1) == cUnitTypePikeman ||
                    kbUnitPickGetResult(gLandUnitPicker, 0) == cUnitTypeCrossbowman ||
                    kbUnitPickGetResult(gLandUnitPicker, 1) == cUnitTypeCrossbowman))
               {
                  xsArraySetInt(gPoliticianScores, i, xsArrayGetInt(gPoliticianScores, i) + 5);
               }               
            }
            if (politician == cTechDEPoliticianFederalNewJersey || politician == cTechDEPoliticianFederalCalifornia)
				{
					xsArraySetInt(gPoliticianScores, i, xsArrayGetInt(gPoliticianScores, i) + 10);
				}
               if ((politician == cTechDEPoliticianLogisticianOttoman) || 
			   (politician == cTechDEPoliticianLogisticianRussian) ||
			   (politician == cTechDEPoliticianLogistician))
               {
                  xsArraySetInt(gPoliticianScores, i, xsArrayGetInt(gPoliticianScores, i) + 300);
               }  
         }
         // Add random bonus
         randomizer = aiRandInt(numChoices);
         xsArraySetInt(gPoliticianScores, randomizer, xsArrayGetInt(gPoliticianScores, randomizer) + 5);
         // Choose politician with best score
         for (i=0; <numChoices)
         {
            if (xsArrayGetInt(gPoliticianScores, i) >= bestScore)
            {
               bestScore = xsArrayGetInt(gPoliticianScores, i);
               bestChoice = i;
            }
         }
         politician = xsArrayGetInt(gAgeUpPoliticians, bestChoice);
         break;
      }
      case cAge4:
	{  // Randomized, but slightly biased towards the General and Mercenary Contractor
		randomizer = aiRandInt(10); // 0-9
		// Create array of politicians to choose from
		for (i = 0; < xsArrayGetSize(gAge5PoliticianList))
		{
			politician = xsArrayGetInt(gAge5PoliticianList, i);
			if (kbTechGetStatus(politician) == cTechStatusObtainable)
			{
				xsArraySetInt(gAgeUpPoliticians, position, politician);
				position = position + 1;
			}
		}
		// Weight politicians as appropriate
		numChoices = position;
		for (i = 0; < numChoices)
		{
			politician = xsArrayGetInt(gAgeUpPoliticians, i);
			if (aiGetWorldDifficulty() >= gDifficultyExpert)
			{
				if ((politician == cTechDEPoliticianMercContractor) && (xsGetTime() > 1440000))
				{
					xsArraySetInt(gPoliticianScores, i, xsArrayGetInt(gPoliticianScores, i) + 300);
				}
				if ((politician == cTechDEPoliticianMercContractor) && (xsGetTime() < 1440000))
				{
					xsArraySetInt(gPoliticianScores, i, xsArrayGetInt(gPoliticianScores, i) + 20);
				}
			}
			else
				if (politician == cTechDEPoliticianMercContractor)
				{
					xsArraySetInt(gPoliticianScores, i, xsArrayGetInt(gPoliticianScores, i) + 20);
				}
		}
            if (politician == cTechDEPoliticianFederalNewYork || politician == cTechDEPoliticianFederalFlorida || politician == cTechDEPoliticianFederalIllinois)
				{
					xsArraySetInt(gPoliticianScores, i, xsArrayGetInt(gPoliticianScores, i) + 5);
				}
		if (gSPC == false)
		{
			// Create array of revolutions to choose from
			for (i = 0; < xsArrayGetSize(gRevolutionList))
			{
				politician = xsArrayGetInt(gRevolutionList, i);
				if (kbTechGetStatus(politician) == cTechStatusObtainable)
				{
					xsArraySetInt(gAgeUpPoliticians, position, politician);
					position = position + 1;
				}
			}
			// Weight revolutions as appropriate
			for (i = numChoices; < position)
			{
				politician = xsArrayGetInt(gAgeUpPoliticians, i);
				// Avoid revolting when we played more than 30 minutes or started to farm
					if (aiTreatyActive() == true)
					xsArraySetInt(gPoliticianScores, i, xsArrayGetInt(gPoliticianScores, i) - 900);
					else
						if ((gRevolutionType & cRevolutionEconomic) == cRevolutionEconomic)
					xsArraySetInt(gPoliticianScores, i, xsArrayGetInt(gPoliticianScores, i) - 900);
				else
						if (aiGetWorldDifficulty() >= gDifficultyExpert)
			{
				if (xsGetTime() < 1440000)
					xsArraySetInt(gPoliticianScores, i, xsArrayGetInt(gPoliticianScores, i) + 10);
					else
					xsArraySetInt(gPoliticianScores, i, xsArrayGetInt(gPoliticianScores, i) + 5);
					if ((politician == cTechDERevolutionEgypt) && (kbGetCiv() == cCivOttomans))
					xsArraySetInt(gPoliticianScores, i, xsArrayGetInt(gPoliticianScores, i) + 5);
			}
			else
				xsArraySetInt(gPoliticianScores, i, xsArrayGetInt(gPoliticianScores, i) + 15);
			}
			numChoices = position;
		}
		// Add random bonus
		randomizer = aiRandInt(numChoices);
		xsArraySetInt(gPoliticianScores, randomizer, xsArrayGetInt(gPoliticianScores, randomizer) + 5);
		// Choose politician with best score
		for (i = 0; < numChoices)
		{
			if (xsArrayGetInt(gPoliticianScores, i) >= bestScore)
			{
				bestScore = xsArrayGetInt(gPoliticianScores, i);
				bestChoice = i;
			}
		}
		politician = xsArrayGetInt(gAgeUpPoliticians, bestChoice);
		break;
	}
	}
	if (gAgeUpResearchPlan < 0 || aiPlanGetVariableInt(gAgeUpResearchPlan, cResearchPlanTechID, 0) != politician)
		aiEcho("Chosen age-up politician: " + kbGetTechName(politician));
	return(politician);
}
//==============================================================================
// chooseNativeCouncilMember()
// Chooses age-up council members for native civilizations
//==============================================================================
int chooseNativeCouncilMember()
{
   int randomizer = -1;
   int numChoices = -1;
   int politician = -1;
   int bestChoice = 0;
   int bestScore = 0;

   for (i = 0; < 6)
      xsArraySetInt(gNatCouncilScores, i, 0); // reset array

   switch (kbGetAge())
   {
   case cAge1:
   { // Aztec and Inca wise woman to be avoided
      numChoices = aiGetPoliticianListCount(cAge2);
      for (i = 0; < numChoices)
      {
         politician = aiGetPoliticianListByIndex(cAge2, i);
         if ((aiGetWorldDifficulty() >= cDifficultyModerate) &&
             ((politician == cTechTribalAztecWisewoman2) || (politician == cTechTribalIncaWisewoman2)))
         {
            xsArraySetInt(gNatCouncilScores, i, xsArrayGetInt(gNatCouncilScores, i) - 10);
         }
      }
      randomizer = aiRandInt(numChoices);
      xsArraySetInt(gNatCouncilScores, randomizer, xsArrayGetInt(gNatCouncilScores, randomizer) + 5);
      for (i = 0; < numChoices)
      {
         if (xsArrayGetInt(gNatCouncilScores, i) >= bestScore)
         {
            bestScore = xsArrayGetInt(gNatCouncilScores, i);
            bestChoice = i;
         }
      }
      politician = aiGetPoliticianListByIndex(cAge2, bestChoice);
      break;
   }
   case cAge2:
   { // Aztec chief to be avoided
      numChoices = aiGetPoliticianListCount(cAge3);
      for (i = 0; < numChoices)
      {
         politician = aiGetPoliticianListByIndex(cAge3, i);
         if ((aiGetWorldDifficulty() >= cDifficultyModerate) && (politician == cTechTribalAztecChief3))
         {
            xsArraySetInt(gNatCouncilScores, i, xsArrayGetInt(gNatCouncilScores, i) - 10);
         }
         if (kbTechGetStatus(politician) != cTechStatusObtainable)
         {
            xsArraySetInt(gNatCouncilScores, i, xsArrayGetInt(gNatCouncilScores, i) - 50);
         }
         xsArraySetInt(gNatCouncilScores, i, xsArrayGetInt(gNatCouncilScores, i) + aiRandInt(10));
      }
      for (i = 0; < numChoices)
      {
         if (xsArrayGetInt(gNatCouncilScores, i) >= bestScore)
         {
            bestScore = xsArrayGetInt(gNatCouncilScores, i);
            bestChoice = i;
         }
      }
      politician = aiGetPoliticianListByIndex(cAge3, bestChoice);
      break;
   }
   case cAge3:
   { // Aztec chief, Iroquois shaman, Sioux wise woman and all messengers to be avoided if possible
      numChoices = aiGetPoliticianListCount(cAge4);
      for (i = 0; < numChoices)
      {
         politician = aiGetPoliticianListByIndex(cAge4, i);
         if ((aiGetWorldDifficulty() >= cDifficultyModerate) &&
             ((politician == cTechTribalAztecChief4) || (politician == cTechTribalIroquoisShaman4) ||
              (politician == cTechTribalSiouxWisewoman4) || (politician == cTechTribalAztecYouth4) ||
              (politician == cTechTribalIncaYouth4) || (politician == cTechTribalIroquoisYouth4) ||
              (politician == cTechTribalSiouxYouth4)))
         {
            xsArraySetInt(gNatCouncilScores, i, xsArrayGetInt(gNatCouncilScores, i) - 10);
         }
         if (kbTechGetStatus(politician) != cTechStatusObtainable)
         {
            xsArraySetInt(gNatCouncilScores, i, xsArrayGetInt(gNatCouncilScores, i) - 50);
         }
         xsArraySetInt(gNatCouncilScores, i, xsArrayGetInt(gNatCouncilScores, i) + aiRandInt(10));
      }
      for (i = 0; < numChoices)
      {
         if (xsArrayGetInt(gNatCouncilScores, i) >= bestScore)
         {
            bestScore = xsArrayGetInt(gNatCouncilScores, i);
            bestChoice = i;
         }
      }
      politician = aiGetPoliticianListByIndex(cAge4, bestChoice);
      break;
   }
   case cAge4:
   { // Aztec chief, Iroquois shaman, Sioux wise woman and all messengers to be avoided if possible
      numChoices = aiGetPoliticianListCount(cAge5);
      for (i = 0; < numChoices)
      {
         politician = aiGetPoliticianListByIndex(cAge5, i);
         if ((aiGetWorldDifficulty() >= cDifficultyModerate) &&
             ((politician == cTechTribalAztecChief5) || (politician == cTechTribalIroquoisShaman5) ||
              (politician == cTechTribalSiouxWisewoman5) || (politician == cTechTribalAztecYouth5) ||
              (politician == cTechTribalIncaYouth5) || (politician == cTechTribalIroquoisYouth5) ||
              (politician == cTechTribalSiouxYouth5)))
         {
            xsArraySetInt(gNatCouncilScores, i, xsArrayGetInt(gNatCouncilScores, i) - 10);
         }
         if (kbTechGetStatus(politician) != cTechStatusObtainable)
         {
            xsArraySetInt(gNatCouncilScores, i, xsArrayGetInt(gNatCouncilScores, i) - 50);
         }
         xsArraySetInt(gNatCouncilScores, i, xsArrayGetInt(gNatCouncilScores, i) + aiRandInt(10));
      }
      for (i = 0; < numChoices)
      {
         if (xsArrayGetInt(gNatCouncilScores, i) >= bestScore)
         {
            bestScore = xsArrayGetInt(gNatCouncilScores, i);
            bestChoice = i;
         }
      }
      politician = aiGetPoliticianListByIndex(cAge5, bestChoice);
      break;
   }
   }

   return (politician);
}

//==============================================================================
/* chooseAsianWonder()
   Chooses age-up Wonders for Asian civilizations.
   
   Chinese:
   1: Summer Palace or Porcelain Tower
   2: The one we didn't pick at 1
   3: Confucian or Temple of Heaven
   4: The one we didn't pick at 3
   Ignore White Pagoda completely.
   
   India:
   1: Agra Fort
   2: Taj Mahal or Tower of Victory
   3: Karni Mata or Charminar Gate
   4: The one we didn't pick at 2 or 3.
   
   Japanese:
   1: Torii Gates or Toshogu Shrine
   2: Golden Pavilion
   3: Shogunate
   4: Giant Buddha or the one we didn't pick at 1.
*/
//==============================================================================
int chooseAsianWonder()
{
   int numChoices = -1;
   int politician = -1;
   int ageUpWonder = -1;
   int bestChoice = 0;
   int bestScore = 0;
   for (i=0; <6)
      xsArraySetInt(gAsianWonderScores, i, 0);   // reset array
   switch (kbGetAge())
   {
      case cAge1:
      {
         numChoices = aiGetPoliticianListCount(cAge2);
         for (i=0; <numChoices)
         {
            politician = aiGetPoliticianListByIndex(cAge2, i);
            if (politician == cTechYPWonderIndianAgra2) // bias towards agra fort
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + 5);
            }
            else if (politician == cTechYPWonderJapaneseToshoguShrine2) // bias towards toshogu shrine
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + 500);
            }
            else if (politician == cTechYPWonderChineseSummerPalace2) // bias towards summer palace
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + 5);
            }
            else if (politician == cTechYPWonderChinesePorcelainTower2) // bias against porcelain tower
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) - 5);
            }
            else if (politician == cTechYPWonderIndianTajMahal2) // bias against taj mahal
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) - 5);
            }
            else if (politician == cTechYPWonderJapaneseGiantBuddha2) // bias against giant buddha
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) - 5);
            }
            else if (politician == cTechYPWonderJapaneseShogunate2) // bias against shogunate
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) - 5);
            }
            xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + aiRandInt(10));
         }
         for (i=0; <numChoices)
         {
            if (xsArrayGetInt(gAsianWonderScores, i) >= bestScore)
            {
               bestScore = xsArrayGetInt(gAsianWonderScores, i);
               bestChoice = i;
            }
         }
         politician = aiGetPoliticianListByIndex(cAge2, bestChoice);
         aiEcho("Chosen age-up wonder: "+kbGetTechName(politician));
         // Find building corresponding to chosen tech (i.e. "politician")
         for (i=0; <15)
         {
            if (xsArrayGetInt(gAge2WonderTechList, i) == politician)
            {
               ageUpWonder = xsArrayGetInt(gAge2WonderList, i);
            }
         }
         break;
      }
      case cAge2:
      {
         numChoices = aiGetPoliticianListCount(cAge3);
         for (i=0; <numChoices)
         {
            politician = aiGetPoliticianListByIndex(cAge3, i);
            if (kbTechGetStatus(politician) != cTechStatusObtainable)
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) - 50);
            }
            else if (politician == cTechYPWonderIndianKarniMata3) // bias towards karni mata
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + 5);
            }
            else if (politician == cTechYPWonderIndianCharminar3) // bias towards charminar gate
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + 5);
            }
            else if (politician == cTechYPWonderJapaneseToshoguShrine3) // bias towards toshogu shrine
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + 5);
            }
            else if (politician == cTechYPWonderJapaneseToriiGates3) // bias towards golden pavillion
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + 500);
            }
            else if (politician == cTechYPWonderJapaneseShogunate3) // slight bias towards shogunate
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + 2);
            }
            else if (politician == cTechYPWonderChineseSummerPalace3) // strong bias towards summer palace
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + 10);
            }
            else if (politician == cTechYPWonderChineseConfucianAcademy3) // slight bias towards confucian academy
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + 2);
            }
            else if (politician == cTechYPWonderChinesePorcelainTower3) // slight bias towards porcelain tower
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + 2);
            }
            else if (politician == cTechYPWonderChineseWhitePagoda3) // slight bias against white pagoda
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) - 2);
            }
            xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + aiRandInt(10));
         }
         for (i=0; <numChoices)
         {
            if (xsArrayGetInt(gAsianWonderScores, i) >= bestScore)
            {
               bestScore = xsArrayGetInt(gAsianWonderScores, i);
               bestChoice = i;
            }
         }
         politician = aiGetPoliticianListByIndex(cAge3, bestChoice);
         aiEcho("Chosen age-up wonder: "+kbGetTechName(politician));
         // Find building corresponding to chosen tech (i.e. "politician")
         for (i=0; <15)
         {
            if (xsArrayGetInt(gAge3WonderTechList, i) == politician)
            {
               ageUpWonder = xsArrayGetInt(gAge3WonderList, i);
            }
         }
         break;
      }
      case cAge3:
      {
         numChoices = aiGetPoliticianListCount(cAge4);
         for (i=0; <numChoices)
         {
            politician = aiGetPoliticianListByIndex(cAge4, i);
            if (kbTechGetStatus(politician) != cTechStatusObtainable)
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) - 50);
            }
            else if (politician == cTechYPWonderIndianKarniMata4) // bias towards karni mata
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + 5);
            }
            else if (politician == cTechYPWonderIndianCharminar4) // bias towards charminar gate
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + 5);
            }
            else if (politician == cTechYPWonderJapaneseGoldenPavillion4) // strong bias towards toshogu shrine
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + 500);
            }
            else if (politician == cTechYPWonderJapaneseGoldenPavillion4) // strong bias towards golden pavillion
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + 10);
            }
            else if (politician == cTechYPWonderJapaneseShogunate4) // bias towards shogunate
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + 5);
            }
            else if (politician == cTechYPWonderChineseSummerPalace4) // bias towards summer palace
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + 5);
            }
            else if (politician == cTechYPWonderChinesePorcelainTower4) // strong bias towards porcelain tower
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + 10);
            }
            else if (politician == cTechYPWonderChineseConfucianAcademy4) // bias towards confucian academy
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + 5);
            }
            else if (politician == cTechYPWonderChineseTempleOfHeaven4) // slight bias against temple of heaven
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) - 2);
            }
            else if (politician == cTechYPWonderChineseWhitePagoda4) // slight bias against white pagoda
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) - 2);
            }
            xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + aiRandInt(10));
         }
         for (i=0; <numChoices)
         {
            if (xsArrayGetInt(gAsianWonderScores, i) >= bestScore)
            {
               bestScore = xsArrayGetInt(gAsianWonderScores, i);
               bestChoice = i;
            }
         }
         politician = aiGetPoliticianListByIndex(cAge4, bestChoice);
         aiEcho("Chosen age-up wonder: "+kbGetTechName(politician));
         // Find building corresponding to chosen tech (i.e. "politician")
         for (i=0; <15)
         {
            if (xsArrayGetInt(gAge4WonderTechList, i) == politician)
            {
               ageUpWonder = xsArrayGetInt(gAge4WonderList, i);
            }
         }
         break;
      }
      case cAge4:
      {
         numChoices = aiGetPoliticianListCount(cAge5);
         for (i=0; <numChoices)
         {
            politician = aiGetPoliticianListByIndex(cAge5, i);
            if (kbTechGetStatus(politician) != cTechStatusObtainable)
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) - 50);
            }
            else if (politician == cTechYPWonderIndianKarniMata5) // bias towards karni mata
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + 5);
            }
            else if (politician == cTechYPWonderIndianCharminar5) // bias towards charminar gate
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + 5);
            }
            else if (politician == cTechYPWonderJapaneseToshoguShrine5) // strong bias towards toshogu shrine
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + 10);
            }
            else if (politician == cTechYPWonderJapaneseGoldenPavillion5) // strong bias towards golden pavillion
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + 10);
            }
            else if (politician == cTechYPWonderJapaneseShogunate5) // strong bias towards shogunate
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + 500);
            }
            else if (politician == cTechYPWonderChineseSummerPalace5) // bias towards summer palace
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + 5);
            }
            else if (politician == cTechYPWonderChinesePorcelainTower5) // strong bias towards porcelain tower
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + 10);
            }
            else if (politician == cTechYPWonderChineseConfucianAcademy5) // bias towards confucian academy
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + 5);
            }
            else if (politician == cTechYPWonderChineseTempleOfHeaven5) // slight bias against temple of heaven
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) - 2);
            }
            else if (politician == cTechYPWonderChineseWhitePagoda5) // slight bias against white pagoda
            {
               xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) - 2);
            }
            xsArraySetInt(gAsianWonderScores, i, xsArrayGetInt(gAsianWonderScores, i) + aiRandInt(10));
         }
         for (i=0; <numChoices)
         {
            if (xsArrayGetInt(gAsianWonderScores, i) >= bestScore)
            {
               bestScore = xsArrayGetInt(gAsianWonderScores, i);
               bestChoice = i;
            }
         }
         politician = aiGetPoliticianListByIndex(cAge5, bestChoice);
         aiEcho("Chosen age-up wonder: "+kbGetTechName(politician));
         // Find building corresponding to chosen tech (i.e. "politician")
         for (i=0; <15)
         {
            if (xsArrayGetInt(gAge5WonderTechList, i) == politician)
            {
               ageUpWonder = xsArrayGetInt(gAge5WonderList, i);
            }
         }
         break;
      }
   }
   if (gAgeUpResearchPlan < 0 || aiPlanGetVariableInt(gAgeUpResearchPlan, cBuildPlanBuildingTypeID, 0) != ageUpWonder)
      aiEcho("Chosen age-up wonder: "+kbGetProtoUnitName(ageUpWonder));
   return(ageUpWonder);
}
//==============================================================================
// chooseAfricanAlliance()
// Chooses age-up alliance for African civilizations
//==============================================================================
int chooseAfricanAlliance()
{
   int age = kbGetAge();
   int numAllianceChoices = aiGetPoliticianListCount(age + 1);
   int numValidAlliances = 0;
   int alliance = -1;

   for (i = 0; < 8)
   {
      xsArraySetInt(gAfricanAlliances, i, -1); // Reset array.
   }

   // Fill the array with Alliances that are deemed suitable to chose from.
   // Exclude the ones we don't want is what's done below.
   switch (age)
   {
   case cAge1:
   {
      for (i = 0; < numAllianceChoices)
      {
         alliance = aiGetPoliticianListByIndex(cAge2, i);
         if ((alliance != cTechDEAllegianceJesuit2) && (alliance != cTechDEAllegianceHabesha2) &&
             (alliance != cTechDEAllegianceMoroccan2) && (alliance != cTechDEAllegianceAkan2))
         {
            xsArraySetInt(gAfricanAlliances, numValidAlliances, alliance);
            numValidAlliances++;
         }
      }
      break;
   }
   case cAge2:
   {
      for (i = 0; < numAllianceChoices)
      {
         alliance = aiGetPoliticianListByIndex(cAge3, i);
         if ((alliance != cTechDEAllegianceHabesha3) && (alliance != cTechDEAllegianceIndian3) &&
             (alliance != cTechDEAllegianceMoroccan3) && (alliance != cTechDEAllegianceFulani3))
         {
            xsArraySetInt(gAfricanAlliances, numValidAlliances, alliance);
            numValidAlliances++;
         }
      }
      break;
   }
   case cAge3:
   {
      for (i = 0; < numAllianceChoices)
      {
         alliance = aiGetPoliticianListByIndex(cAge4, i);
         if ((alliance != cTechDEAllegianceHabesha4) && (alliance != cTechDEAllegianceIndian4) &&
             (alliance != cTechDEAllegianceFulani4) && (alliance != cTechDEAllegianceMoroccan4) &&
             (alliance != cTechDEAllegianceYoruba4))
         {
            xsArraySetInt(gAfricanAlliances, numValidAlliances, alliance);
            numValidAlliances++;
         }
      }
      break;
   }
   case cAge4:
   {
      for (i = 0; < numAllianceChoices)
      {
         alliance = aiGetPoliticianListByIndex(cAge5, i);
         if ((alliance != cTechDEAllegianceHabesha5) && (alliance != cTechDEAllegianceIndian5) &&
             (alliance != cTechDEAllegianceArab5) && (alliance != cTechDEAllegianceFulani5) &&
             (alliance != cTechDEAllegianceMoroccan5) && (alliance != cTechDEAllegianceYoruba5))
         {
            xsArraySetInt(gAfricanAlliances, numValidAlliances, alliance);
            numValidAlliances++;
         }
      }
      break;
   }
   }

   alliance = xsArrayGetInt(gAfricanAlliances, aiRandInt(numValidAlliances));

   debugTechs("Alliances to chose from:");
   for (i = 0; < numValidAlliances)
   {
      debugTechs(kbGetTechName(xsArrayGetInt(gAfricanAlliances, i)));
   }

   return (alliance);
}

//==============================================================================
// chooseAmericanFederalState
// Chooses age-up Federal States for the United States civilization.
//==============================================================================
int chooseAmericanFederalState()
{
   int age = kbGetAge();
   int numFederalStateChoices = aiGetPoliticianListCount(age + 1);
   int numValidFederalStates = 0;
   int federalState = -1;

   for (int i = 0; i < numValidFederalStates; i++)
   {
      xsArraySetInt(gAmericanFederalStates, i, -1); // Reset array.
   }

   // Fill the array with Alliances that are deemed suitable to chose from.
   // Exclude the ones we don't want is what's done below.
   switch (age)
   {
   case cAge1:
   {
      for (i = 0; i < numFederalStateChoices; i++)
      {
         federalState = aiGetPoliticianListByIndex(cAge2, i);
         if ((federalState != cTechDEPoliticianFederalMassachusetts) &&
             (federalState != cTechDEPoliticianFederalVirginia) &&
             (federalState != cTechDEPoliticianFederalPennsylvania) &&
             (federalState != cTechDEPoliticianFederalRhodeIsland))
         {  // Basically we always age up with Delaware.
            xsArraySetInt(gAmericanFederalStates, numValidFederalStates, federalState);
            numValidFederalStates++;
         }
      }
      break;
   }
   case cAge2:
   {
      for (i = 0; i < numFederalStateChoices; i++)
      {
         federalState = aiGetPoliticianListByIndex(cAge3, i);
         if ((federalState != cTechDEPoliticianFederalIndiana) &&
             (federalState != cTechDEPoliticianFederalMaryland))
         {
            xsArraySetInt(gAmericanFederalStates, numValidFederalStates, federalState);
            numValidFederalStates++;
         }
      }
      break;
   }
   case cAge3:
   {
      for (i = 0; i < numFederalStateChoices; i++)
      {
         federalState = aiGetPoliticianListByIndex(cAge4, i);
         if ((federalState != cTechDEPoliticianFederalVermont) &&
             (federalState != cTechDEPoliticianFederalCalifornia))
         {
            xsArraySetInt(gAmericanFederalStates, numValidFederalStates, federalState);
            numValidFederalStates++;
         }
      }
      break;
   }
   case cAge4:
   {
      for (i = 0; i < numFederalStateChoices; i++)
      {  
         federalState = aiGetPoliticianListByIndex(cAge5, i);
         if (federalState != cTechDEPoliticianFederalNewYork)
         {
            xsArraySetInt(gAmericanFederalStates, numValidFederalStates, federalState);
            numValidFederalStates++;
         }
      }
      break;
   }
   }

   federalState = xsArrayGetInt(gAmericanFederalStates, aiRandInt(numValidFederalStates));

   debugTechs("Federal States to chose from:");
   for (i = 0; i < numValidFederalStates; i++)
   {
      debugTechs(kbGetTechName(xsArrayGetInt(gAmericanFederalStates, i)));
   }

   return (federalState);
}

//==============================================================================
// chooseMexicanFederalState
// Chooses age-up Federal States for the Mexican civilization.
//==============================================================================
int chooseMexicanFederalState()
{
   int age = kbGetAge();
   int numFederalStateChoices = aiGetPoliticianListCount(age + 1);
   int numValidFederalStates = 0;
   int federalState = -1;

   for (i = 0; < numFederalStateChoices)
   {
      xsArraySetInt(gMexicanFederalStates, i, -1); // Reset array.
   }

   // Fill the array with Alliances that are deemed suitable to chose from.
   // Exclude the ones we don't want is what's done below.
   switch (age)
   {
   case cAge1:
   {
      for (i = 0; < numFederalStateChoices)
      {
         federalState = aiGetPoliticianListByIndex(cAge2, i);
         if ((federalState != cTechDEPoliticianFederalMXDurango) &&
             ((federalState != cTechDEPoliticianFederalMXMichoacan) || (gNavyMap == true)))
         {
            xsArraySetInt(gMexicanFederalStates, numValidFederalStates, federalState);
            numValidFederalStates++;
         }
      }
      break;
   }
   case cAge2:
   {
      for (i = 0; < numFederalStateChoices)
      {
         federalState = aiGetPoliticianListByIndex(cAge3, i);
         if ((federalState != cTechDEPoliticianFederalMXSinaloa) ||
             (gNavyMap == true) && (federalState != cTechDEPoliticianFederalMXSonora) ||
             ((gTimeForPlantations == false) && (gTimeToFarm == false)))
         {
            xsArraySetInt(gMexicanFederalStates, numValidFederalStates, federalState);
            numValidFederalStates++;
         }
      }
      break;
   }
   case cAge3:
   {
      for (i = 0; < numFederalStateChoices)
      {
         federalState = aiGetPoliticianListByIndex(cAge4, i);
         if ((federalState != cTechDEPoliticianFederalMXTamaulipas) || (gNavyMap == true))
         {
            xsArraySetInt(gMexicanFederalStates, numValidFederalStates, federalState);
            numValidFederalStates++;
         }
      }
      break;
   }
   case cAge4:
   {
      for (i = 0; < numFederalStateChoices)
      {
         federalState = aiGetPoliticianListByIndex(cAge5, i);
         xsArraySetInt(gMexicanFederalStates, numValidFederalStates, federalState);
         numValidFederalStates++;
      }
      break;
   }
   }

   federalState = xsArrayGetInt(gMexicanFederalStates, aiRandInt(numValidFederalStates));

   debugTechs("Federal States to chose from:");
   for (i = 0; < numValidFederalStates)
   {
      debugTechs(kbGetTechName(xsArrayGetInt(gMexicanFederalStates, i)));
   }

   return (federalState);
}

//==============================================================================
/* ageUpgradeMonitor
   In this rule we decide what age up option we must go for,
   and what resource priority we must give it.
   If we don't have an age up plan we create one.
   If we already have a plan we see if we must update it.
*/
//==============================================================================
rule ageUpgradeMonitor
inactive
group tcComplete
minInterval 10
{
   int wonderToBuild = -1; // Used for Asian logic.
	int politician = -1;    // Used for non Asian logic.
   gAgeUpPriority = 49;
   float ageUpBias = 0.0;
   // Disable after revolting as well.
   if (kbGetAge() >= cAge5) // || gRevolutionType != 0)
   {
	  gAgeUpPriority = 0;
      xsDisableSelf();
      return;
   }
   if ((kbGetAge() >= cvMaxAge) || (gRevolutionType & cRevolutionMilitary) == cRevolutionMilitary)
      return; // Don't disable, this var could change later...
   // If we already have a plan let's see if we need to adjust it to account for the new situation in game.
   if (gAgeUpResearchPlan >= 0)
   {
      if (aiPlanGetState(gAgeUpResearchPlan) >= 0)
      {
   if (aiTreatyActive() == true)
   {
		      if ((xsGetTime() > 6 * 60 * 1000) && (kbGetAge() == cAge2))
		      {
			         gAgeUpPriority = 70;
		      }
		      if ((xsGetTime() > 10 * 60 * 1000) && (kbGetAge() == cAge3))
		      {
			         gAgeUpPriority = 60;
		      }
		      if ((xsGetTime() > 12 * 60 * 1000) && (kbGetAge() == cAge3))
		      {
			         gAgeUpPriority = 70;
		      }
		      if (kbGetAge() == cAge4)
		      {
			         gAgeUpPriority = 60;
		      }
		      if ((xsGetTime() > 16 * 60 * 1000) && (kbGetAge() == cAge4))
		      {
			         gAgeUpPriority = 70;
		      }
	}
	else 
	if (aiGetWorldDifficulty() >= cDifficultyExpert)
	{
		      if ((xsGetTime() > 8 * 60 * 1000) && (kbGetAge() == cAge2))
		      {
			         gAgeUpPriority = 60;
		      }
		      if ((xsGetTime() > 10 * 60 * 1000) && (kbGetAge() == cAge2))
		      {
			         gAgeUpPriority = 65;
		      }
		      if ((xsGetTime() > 14 * 60 * 1000) && (kbGetAge() == cAge3))
		      {
			         gAgeUpPriority = 60;
		      }
		      if ((xsGetTime() > 16 * 60 * 1000) && (kbGetAge() == cAge3))
		      {
			         gAgeUpPriority = 65;
		      }
			  if (gRevolutionType == 0 || (gRevolutionType & cRevolutionEconomic) == cRevolutionEconomic)
	  {
		      if ((kbGetAge() == cAge4) && (xsGetTime() < 20 * 60 * 1000))
		      {
			         gAgeUpPriority = 55;
		      }
			  else
		      if (kbGetAge() == cAge4)
		      {
			         gAgeUpPriority = 60;
		      }
		      if ((xsGetTime() > 1440000) && (kbGetAge() == cAge4))
		      {
			         gAgeUpPriority = 65;
		      }
	  }
	}
	else
	{
		      if ((xsGetTime() > 12 * 60 * 1000) && (kbGetAge() == cAge2))
		      {
			         gAgeUpPriority = 60;
		      }
		      if ((xsGetTime() > 16 * 60 * 1000) && (kbGetAge() == cAge2))
		      {
			         gAgeUpPriority = 65;
		      }
		      if ((xsGetTime() > 20 * 60 * 1000) && (kbGetAge() == cAge3))
		      {
			         gAgeUpPriority = 60;
		      }
		      if ((xsGetTime() > 1440000) && (kbGetAge() == cAge3))
		      {
			         gAgeUpPriority = 65;
		      }
			  if (gRevolutionType == 0 || (gRevolutionType & cRevolutionEconomic) == cRevolutionEconomic)
	  {
		      if ((kbGetAge() == cAge4) && (xsGetTime() < 26 * 60 * 1000))
		      {
			         gAgeUpPriority = 55;
		      }
			  else
		      if (kbGetAge() == cAge4)
		      {
			         gAgeUpPriority = 60;
		      }
		      if ((xsGetTime() > 30 * 60 * 1000) && (kbGetAge() == cAge4))
		      {
			         gAgeUpPriority = 65;
		      }
	  }
	}
         // Update age up choices, we don't do this for Africa because that logic requires no update.
         if ((aiPlanGetState(gAgeUpResearchPlan) != cPlanStateResearch) && (civIsAfrican() == false) &&
             (cMyCiv != cCivDEMexicans))							
         {
            if (civIsAsian() == false)
            {
               if (civIsNative() == true)
                  politician = chooseNativeCouncilMember();
               else if (cMyCiv == cCivDEMexicans)
                  politician = chooseMexicanFederalState();
               else if (civIsEuropean() == true)
                  politician = chooseEuropeanPolitician();
               if (politician < 0)  // We somehow failed to get a valid politician so chose the one at index 0.
					{
						aiEcho("We failed to get a valid politician while updating our choice so try index 0");
                  politician = aiGetPoliticianListByIndex(kbGetAge() + 1, 0);
					}
               if (politician >= 0)  // Adjust the plan with the newly found politician.
					{	
						aiEcho("Adjusting age up plan to this: " + politician);
                  aiPlanSetVariableInt(gAgeUpResearchPlan, cResearchPlanTechID, 0, politician);
					}
					else
						aiEcho("We failed to pick a politician to adjust our age up plan with, how could this happen?");
            }
            else
            {
               wonderToBuild = chooseAsianWonder();
               if (wonderToBuild >= 0)
					{
						aiEcho("Adjusting age up plan to this: " + wonderToBuild);
                  aiPlanSetVariableInt(gAgeUpResearchPlan, cBuildPlanBuildingTypeID, 0, wonderToBuild);
					}
					else
						aiEcho("We failed to pick a wonder to update our age up plan with, how could this happen?");	
            }
         }
         aiPlanSetDesiredResourcePriority(gAgeUpResearchPlan, gAgeUpPriority);
         aiPlanSetEventHandler(gAgeUpResearchPlan, cPlanEventStateChange, "ageUpEventHandler");
         return;
      }
      else
      { // Plan variable is set, but plan is dead.
         aiPlanDestroy(gAgeUpResearchPlan);
         gAgeUpResearchPlan = -1;
         // OK to continue, as we don't have an active plan so we need to create one again.
      }
   }
	// We have no plan yet so create one.
	if (gAgeUpResearchPlan < 0)
	{
		// If we're not yet planning to go up and have no excess resources anyway we don't bother with the plan and return.
		if (gAgeUpPriority < 60)
		{
		if ((xsGetTime() < gAgeUpPlanTime) && (gExcessResources == false))
			return;
		}
		// Asians build Wonders so they don't use this logic.
		if (civIsAsian() == false)
		{
			// Try to research the preferred politician / council member / alliance.
			if (civIsNative() == true)
				politician = chooseNativeCouncilMember();
			else if (civIsAfrican() == true)
				politician = chooseAfricanAlliance();
         else if (cMyCiv == cCivDEMexicans)
            politician = chooseMexicanFederalState();
			else
				politician = chooseEuropeanPolitician();
			if (politician < 0)                                            // We somehow failed to get a valid politician so chose the one at index 0.
				politician = aiGetPoliticianListByIndex(kbGetAge() + 1, 0); 
			// We have managed to pick a politician / council member / alliance (or got defaulted to index 0) so let's create the research plan. 
			// If we somehow still don't have one we just don't make a plan.
			if (politician >= 0)
			{
				// Sanity check.
				if (kbTechGetStatus(politician) == cTechStatusObtainable)
				{
					gAgeUpResearchPlan = createSimpleResearchPlan(politician, -1, cEmergencyEscrowID, 99);
					aiPlanSetDesiredResourcePriority(gAgeUpResearchPlan, gAgeUpPriority);
					aiPlanSetEventHandler(gAgeUpResearchPlan, cPlanEventStateChange, "ageUpEventHandler");
					aiEcho("Creating plan #" + gAgeUpResearchPlan + " to get age upgrade with tech " + kbGetTechName(politician));
					return;
				}
         }
			else
				aiEcho("We failed to pick a politician to make an age up plan for, how could this happen?");
		}
		else
		{  // We are Asian, time to build a Wonder.
			wonderToBuild = chooseAsianWonder();
			if (wonderToBuild >= 0)
			{
				gAgeUpResearchPlan = createSimpleBuildPlan(wonderToBuild, 1, 100, true, cEmergencyEscrowID, kbBaseGetMainID(cMyID), 4);
				aiPlanSetDesiredResourcePriority(gAgeUpResearchPlan, gAgeUpPriority);
				aiPlanSetEventHandler(gAgeUpResearchPlan, cPlanEventStateChange, "ageUpEventHandler");
				aiEcho("Wonder to build: " + kbGetProtoUnitName(wonderToBuild));
				aiEcho("Creating plan #" + gAgeUpResearchPlan + " to get age upgrade with wonder " + kbGetProtoUnitName(wonderToBuild));	
			}
			else
				aiEcho("We failed to pick a wonder to make an age up plan for, how could this happen?");
		}
	}
}

rule settlerUpgradeMonitor
inactive
minInterval 180 // Research to be started 3 minutes into the Commerce Age.
{
   // Quit if there is no Market.
   if (kbUnitCount(cMyID, gMarketUnit, cUnitStateAlive) < 1)
   {
      return;
   }

   int villagerHPTechID = -1;

   if (civIsNative() == true)
   {
      villagerHPTechID = cTechSpiritMedicine;
   }
   else if (civIsAsian() == true)
   {
      villagerHPTechID = cTechypMarketSpiritMedicine;
   }
   else if ((cMyCiv == cCivDEAmericans) || (cMyCiv == cCivDEMexicans))
   {
      villagerHPTechID = cTechDEFrontiersmen;
   }
   else if (civIsAfrican() == true)
   {
      villagerHPTechID = cTechDEAfricanVillagerHitpoints;
   }
   else // European.
   {
      villagerHPTechID = cTechGreatCoat;
   }

   bool canDisableSelf = researchSimpleTech(villagerHPTechID, gMarketUnit);

   if (canDisableSelf == true)
   {
      xsDisableSelf();
   }
}

//==============================================================================
/* rule econUpgrades

   Make sure we always have an econ upgrade plan running.  Go cheapest first.
*/
//==============================================================================
rule econUpgrades
inactive
group tcComplete
minInterval 30
{
   int planState = -1;
   int techToGet = -1;
   float lowestCost = 1000000.0;
   static int gatherTargets = -1;     // Array to hold the list of things we gather from, i.e. mill, tree, etc.
   static int gatherTargetTypes = -1; // Array.  If gatherTargets(x) == mill, then gatherTargetTypes(x) = cResourceFood.
   int target = -1;                   // Index used to step through arrays
   static int startTime = -1;         // Time last plan was started, to make sure we're not waiting on an obsolete tech.

   if (gatherTargets < 0) // Array not initialized
   {                      // Set up our list of target units (what we gather from) and their resource categories.
      gatherTargets = xsArrayCreateInt(8, -1, "Gather Targets");
      gatherTargetTypes = xsArrayCreateInt(8, -1, "Gather Target Types");

      xsArraySetInt(gatherTargets, 0, gFarmUnit); // Mills generate food
      xsArraySetInt(gatherTargetTypes, 0, cResourceFood);

      xsArraySetInt(gatherTargets, 1, cUnitTypeTree); // Trees generate wood
      xsArraySetInt(gatherTargetTypes, 1, cResourceWood);

      xsArraySetInt(gatherTargets, 2, cUnitTypeAbstractMine); // Mines generate gold
      xsArraySetInt(gatherTargetTypes, 2, cResourceGold);

      if ((cMyCiv != cCivJapanese) && (cMyCiv != cCivSPCJapanese) && (cMyCiv != cCivSPCJapaneseEnemy))
      {
         xsArraySetInt(gatherTargets, 3, cUnitTypeHuntable); // Huntables generate food, BHG: not for the japanese!
      }
      else
      {
         xsArraySetInt(gatherTargets, 3, cUnitTypeypBerryBuilding); // Berry bushes and cherry orchards
      }
      xsArraySetInt(gatherTargetTypes, 3, cResourceFood);

      xsArraySetInt(gatherTargets, 4, cUnitTypeBerryBush);
      xsArraySetInt(gatherTargetTypes, 4, cResourceFood);

      xsArraySetInt(gatherTargets, 5, gPlantationUnit); // Plantations generate gold
      xsArraySetInt(gatherTargetTypes, 5, cResourceGold);

      xsArraySetInt(gatherTargets, 6, cUnitTypeFish); // Fish generate food
      xsArraySetInt(gatherTargetTypes, 6, cResourceFood);

      xsArraySetInt(gatherTargets, 7, cUnitTypeAbstractWhale); // Whale generates gold
      xsArraySetInt(gatherTargetTypes, 7, cResourceGold);
   }

   planState = aiPlanGetState(gEconUpgradePlan);

   if (planState < 0)
   {                                   // Plan is done or doesn't exist
      aiPlanDestroy(gEconUpgradePlan); // Nuke the old one, if it exists
      startTime = -1;

      int techID = -1;           // The cheapest tech for the current target unit type
      float rawCost = -1.0;      // The cost of the upgrade
      float relCost = -1.0;      // The cost, relative to some estimate of the number of gatherers
      float numGatherers = -1.0; // Number of gatherers assigned to the resource type (i.e food)

      /*
         Step through the array of gather targets.  For each, calculate the cost of the upgrade
         relative to the number of gatherers that would benefit.  Choose the one with the best
         payoff.
      */
      for (target = 0; < 8)
      {
         // if (xsArrayGetInt(gatherTargets, target) < 0)   // No target specified
         //   continue;
         techID = kbTechTreeGetCheapestEconUpgrade(
             xsArrayGetInt(gatherTargets, target), xsArrayGetInt(gatherTargetTypes, target));
         if (techID < 0) // No tech available for this target type
            continue;
         rawCost = kbGetTechAICost(techID);
         // Disable this check because it prevents us from researching techs made free through HC cards.
         // if (rawCost == 0.0)
         //   rawCost = -1.0;

         numGatherers = aiGetNumberGatherers(
             cUnitTypeAbstractVillager, xsArrayGetInt(gatherTargetTypes, target), -1, xsArrayGetInt(gatherTargets, target));

         // Calculate the relative cost
         switch (xsArrayGetInt(gatherTargets, target))
         {
         case cUnitTypeHuntable:
         {
            // Assume all food gatherers are hunting unless we have a mill.
            relCost = rawCost / numGatherers;
            if (kbUnitCount(cMyID, gFarmUnit, cUnitStateAlive) > 0)
               relCost = -1.0; // Do NOT get hunting dogs once we're farming
            break;
         }
         case cUnitTypeFish:
         {
            numGatherers = kbUnitCount(cMyID, gFishingUnit, cUnitStateAlive);
            if (numGatherers > 0.0)
               relCost = rawCost / numGatherers;
            else
               relCost = -1.0;
            break;
         }
         default: // All other resources
         {
            if (numGatherers > 0.0)
               relCost = rawCost / numGatherers;
            else
               relCost = -1.0;
            break;
         }
         }

         // We now have the relative cost for the cheapest tech that gathers from this target type.
         // See if it's > 0, and the cheapest so far.  If so, save the stats, as long as it's obtainable.

         if ((techID >= 0) && (relCost < lowestCost) && (relCost >= 0.0) && (kbTechGetStatus(techID) == cTechStatusObtainable))
         {
            lowestCost = relCost;
            techToGet = techID;
         }
      }

      if ((techToGet >= 0) &&
          ((lowestCost < 40.0) ||                              // We have a tech, and it doesn't cost more than 40 per gatherer
           (aiTreatyGetEnd() > xsGetTime() + 10 * 60 * 1000))) // Keep researching economy upgrades during treaty.
      {

         // If a plan has been running for 3 minutes...
         if ((startTime > 0) && (xsGetTime() > (startTime + 180000)))
         {
            // If it's still the tech we want, reset the start time counter and quit out.  Otherwise, kill it.
            if (aiPlanGetVariableInt(gEconUpgradePlan, cProgressionPlanGoalTechID, 0) == techToGet)
            {
               startTime = xsGetTime();
               return;
            }
            else
            {
               debugTechs(
                  "***** Destroying econ upgrade plan # " + gEconUpgradePlan +
                  " because it has been running more than 3 minutes.");
               aiPlanDestroy(gEconUpgradePlan);
            }
         }

         // research market upgrades in age1 immediately if we can afford without tasking villagers
         if (kbGetAge() == cAge1 && kbUnitCount(cMyID, gMarketUnit, cUnitStateAlive) > 0 &&
             kbCanAffordTech(techToGet, cEconomyEscrowID) == true)
         {
            aiTaskUnitResearch(getUnit(gMarketUnit), techToGet);
            return;
         }

         // Plan doesn't exist, or we just killed it due to timeout....
         gEconUpgradePlan = aiPlanCreate("Econ upgrade tech: " + kbGetTechName(techToGet), cPlanResearch);
         aiPlanSetVariableInt(gEconUpgradePlan, cResearchPlanTechID, 0, techToGet);
         aiPlanSetDesiredPriority(gEconUpgradePlan, 92);
         aiPlanSetEscrowID(gEconUpgradePlan, cEconomyEscrowID);
         aiPlanSetBaseID(gEconUpgradePlan, kbBaseGetMainID(cMyID));
         if ((xsGetTime() > 12 * 60 * 1000) || (btRushBoom < 0.0) || (agingUp() == true) || (kbGetAge() >= cAge3))
            aiPlanSetDesiredResourcePriority(gEconUpgradePlan, 55); // Above average
         aiPlanSetActive(gEconUpgradePlan);
         startTime = xsGetTime();

         debugTechs("                **** Creating upgrade plan for " + kbGetTechName(techToGet) + " is " + gEconUpgradePlan);
         // debugTechs("                **** Status for tech "+kbGetTechName(techToGet)+" is "+kbTechGetStatus(techToGet));
         // debugTechs("                **** Relative cost (score) was lowest at "+lowestCost);
      }
   }
   // Otherwise, if a plan already existed, let it run...
}

//==============================================================================
/* towerUpgradeMonitor
   Research the two upgrades for our Towers.
   The Aztecs have 2 types of Tower buildings and we can only research upgrades for one of them here.
   This forces us to have a separate rule for the War Hut upgrades
   that the Lakota also use instead of this one.
*/
//==============================================================================
rule towerUpgradeMonitor
inactive
mininterval 60
{
   // Defaults are the nonspecial European upgrades.
   int towerUpgrade1 = cTechFrontierOutpost;
   int towerUpgrade2 = cTechFortifiedOutpost;
   if (cMyCiv == cCivRussians)
   {
      towerUpgrade1 = cTechFrontierBlockhouse;
      towerUpgrade2 = cTechFortifiedBlockhouse;
   }
   if ((cMyCiv == cCivXPIroquois) || (cMyCiv == cCivDEInca))
   {
      towerUpgrade1 = cTechStrongWarHut;
      towerUpgrade2 = cTechMightyWarHut;
   }
   if (cMyCiv == cCivXPAztec)
   {
      towerUpgrade1 = cTechStrongNoblesHut;
      towerUpgrade2 = cTechMightyNoblesHut;
   }
   if (civIsAsian() == true)
   {
      towerUpgrade1 = cTechypFrontierCastle;
      towerUpgrade2 = cTechypFortifiedCastle;
   }
   if (civIsAfrican() == true)
   {
      towerUpgrade1 = cTechDESentryTower;
      towerUpgrade2 = cTechDEGuardTower;
   }

   bool canDisableSelf = researchSimpleTechByCondition(
      towerUpgrade1, []() -> bool { return (kbUnitCount(cMyID, gTowerUnit, cUnitStateABQ) >= 3); }, gTowerUnit);

   canDisableSelf &= ((researchSimpleTechByCondition(towerUpgrade2,
      []() -> bool { return (kbUnitCount(cMyID, gTowerUnit, cUnitStateABQ) >= 4); },
      gTowerUnit)) ||
      cvMaxAge < cAge4);

   if (canDisableSelf == true)
   {
      xsDisableSelf();
   }
}

void SufiShariaEventHandler(int planID = -1)
{
   if (aiPlanGetState(planID) == -1)
   {
      if (kbTechGetStatus(cTechYPNatSufiSharia) == cTechStatusActive)
      {
         int settlerIncrease = gEconUnit == cUnitTypeCoureur ? 8 : 10;
         for (i = cAge1; <= cAge5)
         {
            xsArraySetInt(gTargetSettlerCounts, i, xsArrayGetInt(gTargetSettlerCounts, i) + settlerIncrease);
         }
         updateSettlersAndPopManager();
      }
   }
}

//==============================================================================
// nativeTribeUpgradeMonitor
// We have enough monitors to handle 3 different native tribes on a map.
// These rules repeatedly call the lambda to research the associated upgrades.
//==============================================================================
rule nativeTribeUpgradeMonitor1
inactive
minInterval 60
{
   int tradingPostID = checkAliveSuitableTradingPost(gNativeTribeCiv1);
   if (tradingPostID == -1)
   {
      return;
   }
   if (gNativeTribeResearchTechs1(tradingPostID) == true)
   {
      xsDisableSelf();
   }
}

rule nativeTribeUpgradeMonitor2
inactive
minInterval 60
{
   int tradingPostID = checkAliveSuitableTradingPost(gNativeTribeCiv2);
   if (tradingPostID == -1)
   {
      return;
   }
   if (gNativeTribeResearchTechs2(tradingPostID) == true)
   {
      xsDisableSelf();
   }
}

rule nativeTribeUpgradeMonitor3
inactive
minInterval 60
{
   int tradingPostID = checkAliveSuitableTradingPost(gNativeTribeCiv3);
   if (tradingPostID == -1)
   {
      return;
   }
   if (gNativeTribeResearchTechs3(tradingPostID) == true)
   {
      xsDisableSelf();
   }
}

//==============================================================================
// setupNativeUpgrades
// Scan the map for minor native sockets and assign/activate the appropriate upgrade lambdas for them.
//==============================================================================
void setupNativeUpgrades()
{
   bool(int) tempLambdaStorage = nativeResearchTechsEmpty; // We need to store the lambda somewhere don't we!
   int nativeSocketType = -1;                              // Here we save the ID of the socket we found in the query.
   int amountOfUniqueNatives = 0; // We use this as a counter to determine what function pointer to assign the lambda to.
   int nativeCivFound = -1; // Every iteration we find a native socket and we assign the civ constant it belongs to to this
                            // variable. If it's not a duplicate we copy this to one of the gNativeTribeCiv variables.
   xsSetContextPlayer(0);
   int queryID = createSimpleGaiaUnitQuery(cUnitTypeNativeSocket);
   int numberResults = kbUnitQueryExecute(queryID);
   xsSetContextPlayer(cMyID);
   debugTechs("We found this many native sockets on the map: " + numberResults);
   xsSetContextPlayer(0);

   for (i = 0; < numberResults)
   {
      nativeSocketType = kbUnitGetProtoUnitID(kbUnitQueryGetResult(queryID, i)); // Get the proto constant of the socket.
      switch (nativeSocketType)
      {
      // Vanilla minor natives.
      case cUnitTypeSocketCaribs:
      {
         tempLambdaStorage = [](int tradingPostID = -1) -> bool {
            bool canDisableSelf = researchSimpleTechByCondition(cTechNatKasiriBeer,
               []() -> bool {return (kbUnitCount(cMyID, cUnitTypeAbstractArcher, cUnitStateABQ) +
               kbUnitCount(cMyID, cUnitTypeAbstractHandInfantry, cUnitStateABQ) >= 12); },
               -1, tradingPostID);

            canDisableSelf &= researchSimpleTechByCondition(cTechNatGarifunaDrums,
               []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractArcher, cUnitStateABQ) >= 12); },
               -1, tradingPostID);

            // This upgrade is locked behind all the line upgrades for the Carib Blowgun Warriors.
            canDisableSelf &= researchSimpleTechByCondition(cTechNatCeremonialFeast,
               []() -> bool { return (kbUnitCount(cMyID, cUnitTypeNatBlowgunWarrior, cUnitStateABQ) >= 12); },
               -1, tradingPostID);

            return (canDisableSelf);
         };
         nativeCivFound = cCivCaribs;
         break;
      }
      case cUnitTypeSocketCherokee:
      {
         tempLambdaStorage = [](int tradingPostID = -1) -> bool {
            bool canDisableSelf = researchSimpleTech(cTechNatBasketweaving, -1, tradingPostID);

            return (canDisableSelf);
         };
         nativeCivFound = cCivCherokee;
         break;
      }
      case cUnitTypeSocketComanche:
      {
         tempLambdaStorage = [](int tradingPostID = -1) -> bool {
            bool canDisableSelf = researchSimpleTech(cTechNatTradeLanguage, -1, tradingPostID);

            canDisableSelf &= researchSimpleTechByCondition(cTechNatHorseBreeding,
               []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractCavalry, cUnitStateABQ) >= 12); },
               -1, tradingPostID);

            // Only get the Mustangs upgrade when we're the Lakota since only they we can really use it.
            if (cMyCiv == cCivXPSioux)
            {
               canDisableSelf &= (researchSimpleTechByCondition(cTechNatMustangs,
                  []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractCavalry, cUnitStateABQ) >= 12); },
                  -1, tradingPostID));
            }

            return (canDisableSelf);
         };
         nativeCivFound = cCivComanche;
         break;
      }
      case cUnitTypeSocketCree:
      {
         tempLambdaStorage = [](int tradingPostID = -1) -> bool {
            bool canDisableSelf = researchSimpleTechByCondition(cTechNatTanning,
               []() -> bool {return (kbUnitCount(cMyID, cUnitTypeAbstractInfantry, cUnitStateABQ) +
               kbUnitCount(cMyID, cUnitTypeAbstractCavalry, cUnitStateABQ) +
               kbUnitCount(cMyID, cUnitTypeAbstractLightInfantry, cUnitStateABQ) >= 12); },
               -1, tradingPostID);

            canDisableSelf &= researchSimpleTech(cTechNatTextileCraftsmanship, -1, tradingPostID);

            return (canDisableSelf);
         };
         nativeCivFound = cCivCree;
         break;
      }
      case cUnitTypeSocketMaya:
      {
         tempLambdaStorage = [](int tradingPostID = -1) -> bool {
            bool canDisableSelf = researchSimpleTech(cTechNatCalendar, -1, tradingPostID);

            canDisableSelf &= researchSimpleTechByCondition(cTechNatCottonArmor,
               []() -> bool {return (kbUnitCount(cMyID, cUnitTypeAbstractHandInfantry, cUnitStateABQ) >= 12); },
               -1, tradingPostID);

            return (canDisableSelf);
         };
         nativeCivFound = cCivMaya;
         break;
      }
      case cUnitTypeSocketNootka:
      {
         tempLambdaStorage = [](int tradingPostID = -1) -> bool {
            bool canDisableSelf = (researchSimpleTechByCondition(cTechNatBarkClothing,
               []() -> bool {return (kbUnitCount(cMyID, cUnitTypeAbstractVillager, cUnitStateABQ) >= 30); },
               -1, tradingPostID)) ||
               (xsArrayGetInt(gTargetSettlerCounts, cvMaxAge) < 30);

            return (canDisableSelf);
         };
         nativeCivFound = cCivNootka;
         break;
      }
      case cUnitTypeSocketSeminole:
      {
         tempLambdaStorage = [](int tradingPostID = -1) -> bool {
            bool canDisableSelf = researchSimpleTechByCondition(cTechNatBowyery,
               []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractArcher, cUnitStateABQ) >= 12); },
               -1, tradingPostID);

            return (canDisableSelf);
         };
         nativeCivFound = cCivSeminoles;
         break;
      }
      case cUnitTypeSocketTupi:
      {
         tempLambdaStorage = [](int tradingPostID = -1) -> bool {
            bool canDisableSelf = researchSimpleTech(cTechNatForestBurning, -1, tradingPostID);

            canDisableSelf &= researchSimpleTechByCondition(cTechNatPoisonArrowFrogs,
               []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractArcher, cUnitStateABQ) >= 12); },
               -1, tradingPostID);

            return (canDisableSelf);
         };
         nativeCivFound = cCivTupi;
         break;
      }
      // The War Chiefs minor natives.
      case cUnitTypeSocketApache:
      {
         tempLambdaStorage = [](int tradingPostID = -1) -> bool {
            bool canDisableSelf = (researchSimpleTechByCondition(cTechNatXPApacheCactus,
               []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractVillager, cUnitStateABQ) >= 30); },
               -1, tradingPostID)) ||
               (xsArrayGetInt(gTargetSettlerCounts, cvMaxAge) < 30);

            return (canDisableSelf);
         };
         nativeCivFound = cCivApache;
         break;
      }
      case cUnitTypeSocketHuron:
      {
         tempLambdaStorage = [](int tradingPostID = -1) -> bool {
            // Get after 30 minutes have passed.
            bool canDisableSelf = researchSimpleTechByCondition(cTechNatXPHuronTradeMonopoly,
               []() -> bool { return (xsGetTime() >= 30 * 60 * 1000); }, -1, tradingPostID);

            canDisableSelf &= ((researchSimpleTechByCondition(cTechNatXPHuronFishWedding,
               []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractFishingBoat, cUnitStateABQ) >= 5); },
               -1, tradingPostID)) ||
               (gGoodFishingMap == false));

            return (canDisableSelf);
         };
         nativeCivFound = cCivHuron;
         break;
      }
      case cUnitTypeSocketCheyenne:
      {
         tempLambdaStorage = [](int tradingPostID = -1) -> bool {
            bool canDisableSelf = researchSimpleTechByCondition(cTechNatXPCheyenneHorseTrading,
               []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractCavalry, cUnitStateABQ) >= 15); },
               -1, tradingPostID);

            canDisableSelf &= ((researchSimpleTechByCondition(cTechNatXPCheyenneHuntingGrounds, 
               []() -> bool { return (gTimeToFarm == false); }, -1, tradingPostID)) ||
               (gTimeToFarm == true)); // Only get this when we're not yet farming.

            return (canDisableSelf);
         };
         nativeCivFound = cCivCheyenne;
         break;
      }
      case cUnitTypeSocketKlamath:
      {
         tempLambdaStorage = [](int tradingPostID = -1) -> bool {
            // Get after 30 minutes have passed.
            bool canDisableSelf = researchSimpleTechByCondition(cTechNatXPKlamathHuckleberryFeast,
               []() -> bool { return (xsGetTime() >= 30 * 60 * 100); }, -1, tradingPostID);

            canDisableSelf &= ((researchSimpleTechByCondition(cTechNatXPKlamathWorkEthos,
               []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractVillager, cUnitStateABQ) >= 30); },
               -1, tradingPostID)) ||
               (xsArrayGetInt(gTargetSettlerCounts, cvMaxAge) < 30));

            canDisableSelf &= researchSimpleTechByCondition(cTechNatXPKlamathStrategy,
               []() -> bool { return (kbUnitCount(cMyID, cUnitTypeNatKlamathRifleman, cUnitStateABQ) >= 8); },
               -1, tradingPostID);

            return (canDisableSelf);
         };
         nativeCivFound = cCivKlamath;
         break;
      }
      case cUnitTypeSocketMapuche:
      {
         tempLambdaStorage = [](int tradingPostID = -1) -> bool {
            bool canDisableSelf = researchSimpleTechByCondition(cTechNatXPMapucheTactics,
               []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractHandInfantry, cUnitStateABQ) >= 12); },
               -1, tradingPostID);

            // Get after 30 minutes have passed.
            canDisableSelf &= researchSimpleTechByCondition(cTechNatXPMapucheTreatyOfQuillin,
               []() -> bool { return (xsGetTime() >= 30 * 60 * 100); },
               -1, tradingPostID);

            // Only get it relatively late in the game, aka when we have 60% of our maxPop.
            canDisableSelf &= researchSimpleTechByCondition(cTechNatXPMapucheAdMapu,
               []() -> bool { return (kbGetPop() >= gMaxPop * 0.6); },
               -1, tradingPostID);

            return (canDisableSelf);
         };
         nativeCivFound = cCivMapuche;
         break;
      }
      case cUnitTypeSocketNavajo:
      {
         tempLambdaStorage = [](int tradingPostID = -1) -> bool {
            bool canDisableSelf = researchSimpleTechByCondition(cTechNatXPNavajoWeaving,
               []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractInfantry, cUnitStateABQ) +
               kbUnitCount(cMyID, cUnitTypeAbstractCavalry, cUnitStateABQ) +
               kbUnitCount(cMyID, cUnitTypeAbstractLightInfantry, cUnitStateABQ) >= 12); },
               -1, tradingPostID);

            canDisableSelf &= ((researchSimpleTechByCondition(cTechNatXPNavajoCraftsmanship,
               []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractVillager, cUnitStateABQ) >= 30); },
               -1, tradingPostID)) ||
               (xsArrayGetInt(gTargetSettlerCounts, cvMaxAge) < 30));

            return (canDisableSelf);
         };
         nativeCivFound = cCivNavajo;
         break;
      }
      case cUnitTypeSocketZapotec:
      {
         tempLambdaStorage = [](int tradingPostID = -1) -> bool {
            bool canDisableSelf = researchSimpleTechByCondition(cTechNatXPZapotecCultOfTheDead,
               []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractHandInfantry, cUnitStateABQ) >= 12); },
               -1, tradingPostID);

            // Get after 30 minutes have passed.
            canDisableSelf &= researchSimpleTechByCondition(cTechNatXPZapotecCloudPeople,
               []() -> bool { return (xsGetTime() >= 30 * 60 * 100); },
               -1, tradingPostID);

            // Only get this when we're either farming or on Plantations.
            canDisableSelf &= researchSimpleTechByCondition(cTechNatXPZapotecFoodOfTheGods,
               []() -> bool { return ((gTimeToFarm || gTimeForPlantations)); },
               -1, tradingPostID);

            return (canDisableSelf);
         };
         nativeCivFound = cCivZapotec;
         break;
      }
      // The Asian Dynasties minor natives.
      case cUnitTypeypSocketBhakti:
      {
         tempLambdaStorage = [](int tradingPostID = -1) -> bool {
            bool canDisableSelf = researchSimpleTechByCondition(cTechYPNatBhaktiYoga,
               []() -> bool {return (kbUnitCount(cMyID, cUnitTypeAbstractInfantry, cUnitStateABQ) +
               kbUnitCount(cMyID, cUnitTypeAbstractCavalry, cUnitStateABQ) +
               kbUnitCount(cMyID, cUnitTypeAbstractLightInfantry, cUnitStateABQ) >= 12); },
               -1, tradingPostID);

            canDisableSelf &= researchSimpleTechByCondition(cTechYPNatBhaktiReinforcedGuantlets,
               []() -> bool { return (kbUnitCount(cMyID, cUnitTypeypNatTigerClaw, cUnitStateABQ) +
               kbUnitCount(cMyID, cUnitTypeypNatMercTigerClaw, cUnitStateABQ) >= 12); },
               -1, tradingPostID);

            return (canDisableSelf);
         };
         nativeCivFound = cCivBhakti;
         break;
      }
      case cUnitTypeypSocketJesuit:
      {
         tempLambdaStorage = [](int tradingPostID = -1) -> bool {
            bool canDisableSelf = researchSimpleTechByCondition(cTechYPNatJesuitSmokelessPowder,
               []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractGunpowderTrooper, cUnitStateABQ) +
               kbUnitCount(cMyID, cUnitTypeAbstractGunpowderCavalry, cUnitStateABQ) +
               kbUnitCount(cMyID, cUnitTypeAbstractArtillery, cUnitStateABQ) >= 15); },
               -1, tradingPostID);

            canDisableSelf &= researchSimpleTechByCondition(cTechYPNatJesuitFlyingButtress,
               []() -> bool { return (kbUnitCount(cMyID, cUnitTypeBuilding, cUnitStateABQ) >= 15); },
               -1, tradingPostID);

            canDisableSelf &= researchSimpleTech(cTechYPNatJesuitSchools, -1, tradingPostID);

            return (canDisableSelf);
         };
         nativeCivFound = cCivJesuit;
         break;
      }
      case cUnitTypeypSocketShaolin:
      {
         tempLambdaStorage = [](int tradingPostID = -1) -> bool {
            bool canDisableSelf = researchSimpleTechByCondition(cTechYPNatShaolinClenchedFist,
               []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractRangedInfantry, cUnitStateABQ) >= 20); },
               -1, tradingPostID);

            canDisableSelf &= ((researchSimpleTechByCondition(cTechYPNatShaolinWoodClearing,
               []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractVillager, cUnitStateABQ) >= 30); },
               -1, tradingPostID)) ||
               (xsArrayGetInt(gTargetSettlerCounts, cvMaxAge) < 30));

            canDisableSelf &= researchSimpleTechByCondition(cTechYPNatShaolinDimMak,
               []() -> bool { return (kbUnitCount(cMyID, cUnitTypeypNatRattanShield, cUnitStateABQ) +
               kbUnitCount(cMyID, cUnitTypeypNatMercRattanShield, cUnitStateABQ) >= 12); },
               -1, tradingPostID);

            return (canDisableSelf);
         };
         nativeCivFound = cCivShaolin;
         break;
      }
      case cUnitTypeypSocketSufi:
      {
         tempLambdaStorage = [](int tradingPostID = -1) -> bool {
            // Get after 30 minutes have passed.
            bool canDisableSelf = researchSimpleTechByCondition(cTechYPNatSufiPilgramage, 
               []() -> bool { return (xsGetTime() >= 30 * 60 * 100); }, 
               -1, tradingPostID);

            int techStatus = kbTechGetStatus(cTechYPNatSufiSharia);

            if ((techStatus == cTechStatusActive) || (cDifficultyCurrent < cDifficultyHard))
            {
            }
            else if (techStatus == cTechStatusUnobtainable)
            {
               canDisableSelf = false;
            }
            else // Obtainable
            {
               if (kbGetAge() >= cAge3 && (cvMaxCivPop == -1) &&
                   ((gRevolutionType & cRevolutionMilitary) ==
                    0)) // We only get this upgrade on difficulties where we max out our Villagers.
                        // And don't get it when we have a cvMaxCivPop set since that can mess with what the designer intended.
                        // And don't get it when we're a military revolt, don't disable the rule though we may re-enable
                        // Settlers.
               {
                  int settlerShortfall = getSettlerShortfall();
                  int planID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechYPNatSufiSharia);
                  if (planID < 0)
                  {
                     if (settlerShortfall < 10) // We're approaching our maximum Villagers so we can get this upgrade.
                     {
                        planID = createSimpleResearchPlanSpecificBuilding(cTechYPNatSufiSharia, tradingPostID);
                        aiPlanSetEventHandler(planID, cPlanEventStateChange, "SufiShariaEventHandler");
                     }
                  }
                  else if (settlerShortfall > 10) // We've lost Villagers again, first rebuild them then try this upgrade again.
                  {
                     aiPlanDestroy(planID);
                  }
               }
               canDisableSelf = false;
            }

            return (canDisableSelf);
         };
         nativeCivFound = cCivSufi;
         break;
      }
      case cUnitTypeypSocketUdasi:
      {
         tempLambdaStorage = [](int tradingPostID = -1) -> bool {
               bool canDisableSelf = researchSimpleTechByCondition(cTechYPNatUdasiArmyOfThePure,
               []() -> bool {return (kbUnitCount(cMyID, cUnitTypeypNatChakram, cUnitStateABQ) +
               kbUnitCount(cMyID, cUnitTypeypNatMercChakram, cUnitStateABQ) >= 10); },
               -1, tradingPostID);

            // Only get this when we're either farming or on Plantations.
            canDisableSelf &= researchSimpleTechByCondition(cTechYPNatUdasiNewYear,
               []() -> bool { return ((gTimeToFarm || gTimeForPlantations)); },
               -1, tradingPostID);

            return (canDisableSelf);
         };
         nativeCivFound = cCivUdasi;
         break;
      }
      case cUnitTypeypSocketZen:
      {
         tempLambdaStorage = [](int tradingPostID = -1) -> bool {
            bool canDisableSelf = researchSimpleTechByCondition(cTechYPNatZenMasterLessons,
               []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractHandInfantry, cUnitStateABQ) >= 12); },
               -1, tradingPostID);

            // Have at least some units before we want to reduce their upgrade costs.
            canDisableSelf &= researchSimpleTechByCondition(cTechYPNatZenMeritocracy,
               []() -> bool { return (kbUnitCount(cMyID, cUnitTypeUnit, cUnitStateABQ) >= 20); },
               -1, tradingPostID);

            return (canDisableSelf);
         };
         nativeCivFound = cCivZen;
         break;
      }
      // The African Royals minor natives.
      case cUnitTypedeSocketAkan:
      {
         tempLambdaStorage = [](int tradingPostID = -1) -> bool {
            bool canDisableSelf = (researchSimpleTechByCondition(cTechDENatAkanHeroSpawn,
               []() -> bool { return (kbGetAge() >= cAge3); }, -1, tradingPostID)) ||
               (cvMaxAge < cAge3);

            canDisableSelf &= researchSimpleTechByCondition(cTechDENatAkanDrums,
               []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractInfantry, cUnitStateABQ) >= 20); },
               -1, tradingPostID);

            canDisableSelf &= ((researchSimpleTechByCondition(cTechDENatAkanGoldEconomy,
               []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractVillager, cUnitStateABQ) >= 30); },
               -1, tradingPostID)) ||
               (xsArrayGetInt(gTargetSettlerCounts, cvMaxAge) < 30) || (gTimeForPlantations == true));

            // Only get this when we're either farming or on Plantations.
            canDisableSelf &= researchSimpleTechByCondition(cTechDENatAkanCocoaBeans,
               []() -> bool { return ((gTimeToFarm || gTimeForPlantations)); },
               -1, tradingPostID);

            return (canDisableSelf);
         };
         nativeCivFound = cCivAkan;
         break;
      }
      case cUnitTypedeSocketBerbers:
      {
         tempLambdaStorage = [](int tradingPostID = -1) -> bool {
            bool canDisableSelf = (researchSimpleTechByCondition(cTechDENatBerberDynasties, 
               []() -> bool { return (kbGetAge() >= cAge3); }, -1, tradingPostID)) ||
               (cvMaxAge < cAge3);

            canDisableSelf = canDisableSelf &&((researchSimpleTechByCondition(cTechDENatBerberDesertKings,
               []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractVillager, cUnitStateABQ) >= 30); },
               -1, tradingPostID)) ||
               (xsArrayGetInt(gTargetSettlerCounts, cvMaxAge) < 30));

            canDisableSelf &= ((researchSimpleTechByCondition(cTechDENatBerberSaltCaravans, 
               []() -> bool { return (kbGetAge() >= cAge3); }, -1, tradingPostID)) ||
               (cvMaxAge < cAge3));

            return (canDisableSelf);
         };
         nativeCivFound = cCivBerbers;
         break;
      }
      case cUnitTypedeSocketSomali:
      {
         tempLambdaStorage = [](int tradingPostID = -1) -> bool {
            // Expect we start farming/plantations somewhere in age 3.
            bool canDisableSelf = (researchSimpleTechByCondition(cTechDENatSudaneseHakura, 
               []() -> bool { return (kbGetAge() >= cAge3); }, -1, tradingPostID) ||
               (cvMaxAge < cAge3));

            canDisableSelf &= (researchSimpleTechByCondition(cTechDENatSomaliCoinage,
               []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractVillager, cUnitStateABQ) >= 30); },
               -1, tradingPostID) ||
               (xsArrayGetInt(gTargetSettlerCounts, cvMaxAge) < 30) || (gTimeForPlantations == true));

            canDisableSelf &= (researchSimpleTechByCondition(cTechDENatSomaliOryxShields,
               []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractInfantry, cUnitStateABQ) >= 15); },
               -1, tradingPostID));

            canDisableSelf &= (researchSimpleTechByCondition(cTechDENatSomaliJileDaggers,
               []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractFootArcher, cUnitStateABQ) +
               kbUnitCount(cMyID, cUnitTypeAbstractRifleman, cUnitStateABQ) +
               kbUnitCount(cMyID, cUnitTypeAbstractMeleeSkirmisher, cUnitStateABQ) +
               kbUnitCount(cMyID, cUnitTypeAbstractUrumi, cUnitStateABQ) >= 20); },
               -1, tradingPostID));

            // We as the AI can't really use the information we gain via the Lightouse effect so get it for our human friends.
            if (getHumanAllyCount() >= 1)
            {
               canDisableSelf &= (researchSimpleTechByCondition(cTechDENatSomaliLighthouses,
                  []() -> bool { return ((kbGetAge() >= cAge4) && (getHumanAllyCount() >= 1)); }, 
                  -1, tradingPostID) ||
                  (cvMaxAge < cAge4));
            }

            return (canDisableSelf);
         };
         nativeCivFound = cCivSomali;
         break;
      }
      case cUnitTypedeSocketSudanese:
      {
         tempLambdaStorage = [](int tradingPostID = -1) -> bool {
            // Expect we start farming/plantations somewhere in age 3 so get the price reduction then.
            bool canDisableSelf = researchSimpleTechByCondition(cTechDENatSudaneseHakura,
               []() -> bool { return (kbGetAge() >= cAge3); },
               -1, tradingPostID) ||
               (cvMaxAge < cAge3);

            canDisableSelf &= researchSimpleTechByCondition(cTechDENatSudaneseQuiltedArmor,
               []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractCavalry, cUnitStateABQ) +
               kbUnitCount(cMyID, cUnitTypeAbstractLightInfantry, cUnitStateABQ) >= 10); },
               -1, tradingPostID);

            canDisableSelf &= ((researchSimpleTechByCondition(cTechDENatSudaneseRedSeaTrade,
               []() -> bool { return (kbGetAge() >= cAge3); }, -1, tradingPostID)) ||
               (cvMaxAge < cAge3));

            return (canDisableSelf);
         };
         nativeCivFound = cCivSudanese;
         break;
      }
      case cUnitTypedeSocketYoruba:
      {
         tempLambdaStorage = [](int tradingPostID = -1) -> bool {
            bool canDisableSelf = (researchSimpleTechByCondition(cTechDENatYorubaHerbalism,
               []() -> bool { return (kbGetAge() >= cAge3); }, -1, tradingPostID)) ||
               (cvMaxAge < cAge3);

            return (canDisableSelf);
         };
         nativeCivFound = cCivYoruba;
         break;
      }
      // Definitive Edition (no DLC) minor natives.
      case cUnitTypeSocketInca: // Rebranded as Quechuas.
      {
         tempLambdaStorage = [](int tradingPostID = -1) -> bool {
            bool canDisableSelf = (researchSimpleTechByCondition(cTechNatChasquisMessengers,
               []() -> bool { return (kbGetAge() >= cAge3); }, -1, tradingPostID)) ||
               (cvMaxAge < cAge3);

            canDisableSelf &= ((researchSimpleTechByCondition(cTechNatMetalworking,
               []() -> bool { return (gTimeForPlantations == false &&
               (kbUnitCount(cMyID, cUnitTypeAbstractVillager, cUnitStateABQ) > 30)); },
               -1, tradingPostID)) ||
               (gTimeForPlantations == true) || (xsArrayGetInt(gTargetSettlerCounts, cvMaxAge) < 30));

            return (canDisableSelf);
         };
         nativeCivFound = cCivIncas;
         break;
      }
      }

      // We have found a native now let's see if we have already processed the ID before and it's a duplicate or if it's new and
      // assign it to an upgrade rule. There are sockets in the game which we don't handle here so guard for assigining -1.
      if ((amountOfUniqueNatives == 0) && (nativeCivFound != -1))
      {
         xsSetContextPlayer(cMyID);
         gNativeTribeCiv1 = nativeCivFound;
         gNativeTribeResearchTechs1 = tempLambdaStorage;
         xsEnableRule("nativeTribeUpgradeMonitor1");
         amountOfUniqueNatives++;
         debugTechs("gNativeTribeCiv1 is: " + kbGetCivName(gNativeTribeCiv1));
         xsSetContextPlayer(0);
      }
      else if ((amountOfUniqueNatives == 1) && (gNativeTribeCiv1 != nativeCivFound) && (nativeCivFound != -1))
      {
         xsSetContextPlayer(cMyID);
         gNativeTribeCiv2 = nativeCivFound;
         gNativeTribeResearchTechs2 = tempLambdaStorage;
         xsEnableRule("nativeTribeUpgradeMonitor2");
         amountOfUniqueNatives++;
         debugTechs("gNativeTribeCiv2 is: " + kbGetCivName(gNativeTribeCiv2));
         xsSetContextPlayer(0);
      }
      else if ((amountOfUniqueNatives == 2) && (gNativeTribeCiv1 != nativeCivFound) && 
               (gNativeTribeCiv2 != nativeCivFound) && (nativeCivFound != -1))
      {
         xsSetContextPlayer(cMyID);
         gNativeTribeCiv3 = nativeCivFound;
         gNativeTribeResearchTechs3 = tempLambdaStorage;
         xsEnableRule("nativeTribeUpgradeMonitor3");
         amountOfUniqueNatives++;
         debugTechs("gNativeTribeCiv3 is: " + kbGetCivName(gNativeTribeCiv3));
         return; // We have hit the maximum of natives possible that we can handle, we can safely quit now.
      }
   }
   xsSetContextPlayer(cMyID);
}

rule tradeRouteUpgradeMonitor
inactive
minInterval 90
{
   // Start with updating our bool array by looking at what the first unit on the TR is, 
   // if it's the last tier set the bool to true.
   int firstMovingUnit = -1;
   int firstMovingUnitProtoID = -1;
   for (i = 0; < gNumberTradeRoutes)
   {
      firstMovingUnit = kbTradeRouteGetUnit(i, 0);
      firstMovingUnitProtoID = kbUnitGetProtoUnitID(firstMovingUnit);
      if ((firstMovingUnitProtoID == cUnitTypedeTradingFluyt) || (firstMovingUnitProtoID == cUnitTypeTrainEngine) ||
          (firstMovingUnitProtoID == cUnitTypedeCaravanGuide))
      {
         xsArraySetBool(gTradeRouteIndexMaxUpgraded, i, true);
      }
   }

   // If all the values in the bool array are set to true it means we can disable this rule since we have all the upgrades
   // across all TRs on the map.
   bool canDisableSelf = true;
   for (i = 0; < gNumberTradeRoutes)
   {
      if (xsArrayGetBool(gTradeRouteIndexMaxUpgraded, i) == false)
      {
         canDisableSelf = false;
      }
   }
   if (canDisableSelf == true)
   {
      xsDisableSelf();
   }

   int numberTradingPostsOnRoute = 0;
   int tradingPostID = -1;
   int playerID = -1;
   int ownedTradingPostID = -1;
   int numberAllyTradingPosts = 0;
   int numberEnemyTradingPosts = 0;
   int tradeRoutePrio = 47 + (btBiasTrade * 5.0);

   for (routeIndex = 0; < gNumberTradeRoutes)
   {
      if (xsArrayGetBool(gTradeRouteIndexMaxUpgraded, routeIndex) == true)
      {
         continue;
      }

      numberTradingPostsOnRoute = kbTradeRouteGetNumberTradingPosts(routeIndex);
      ownedTradingPostID = -1;
      numberAllyTradingPosts = 0;
      numberEnemyTradingPosts = 0;
      for (postIndex = 0; < numberTradingPostsOnRoute)
      {
         // This syscall needs no LOS and finds all IDs of (built / foundation) TPs currently on that route, 
         // so no empty sockets are found.
         tradingPostID = kbTradeRouteGetTradingPostID(routeIndex, postIndex); 
         playerID = kbUnitGetPlayerID(tradingPostID);
         if (playerID == cMyID)
         {
            ownedTradingPostID = tradingPostID;
            numberAllyTradingPosts++;
            continue;
         }
         if (kbIsPlayerAlly(playerID) == true)
         {
            numberAllyTradingPosts++;
            continue;
         }
         if (kbIsPlayerAlly(playerID) == false)
            numberEnemyTradingPosts++;
      }
      if (ownedTradingPostID >= 0) // If we actually found a TR on this route that is ours, do the upgrade logic.
      {
         if (kbBuildingTechGetStatus(xsArrayGetInt(gTradeRouteUpgrades, cTradeRouteFirstUpgrade + (routeIndex * 2)), 
               ownedTradingPostID) == cTechStatusObtainable)
         {
            // We have 1 or more TPs on this route than the enemy, doesn't work for upgrade all special maps.
            if (numberAllyTradingPosts - numberEnemyTradingPosts >= 1) 
            {
               createTradeRouteUpgrade(
                   xsArrayGetInt(gTradeRouteUpgrades, cTradeRouteFirstUpgrade + (routeIndex * 2)),
                   ownedTradingPostID,
                   tradeRoutePrio);
               return;
            }
         }
         else if (
             (kbBuildingTechGetStatus(
                  xsArrayGetInt(gTradeRouteUpgrades, cTradeRouteSecondUpgrade + (routeIndex * 2)), ownedTradingPostID) ==
              cTechStatusObtainable) &&
             (kbGetAge() >= cAge4))
         {
            if (numberAllyTradingPosts - numberEnemyTradingPosts >= 2) 
            {
               createTradeRouteUpgrade(
                   xsArrayGetInt(gTradeRouteUpgrades, cTradeRouteSecondUpgrade + (routeIndex * 2)),
                   ownedTradingPostID,
                   tradeRoutePrio);
               return;
            }
         }
      }
   }
}

//==============================================================================
// navyUpgradeMonitor
//==============================================================================
rule navyUpgradeMonitor
inactive
minInterval 90
{
   // Disable rule if we're not on a water map.
   if (gNavyMap == false)
   {
      xsDisableSelf();
      return;
   }

   // Disable rule once we got all relevant upgrades.
   if ((kbTechGetStatus(cTechCarronade) == cTechStatusActive) && (kbTechGetStatus(cTechArmorPlating) == cTechStatusActive) &&
       (kbTechGetStatus(cTechShipHowitzers) == cTechStatusActive) && (kbTechGetStatus(cTechGillNets) == cTechStatusActive) &&
       (kbTechGetStatus(cTechLongLines) == cTechStatusActive))
   {
      xsDisableSelf();
      return;
   }

   int upgradePlanID = -1;

   // Research and destroy fishing improvement plans when appropriate.
   // After 7 Fishing Boats getting Gill Nets becomes efficient.
   if (kbTechGetStatus(cTechGillNets) == cTechStatusObtainable)
   {
      upgradePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechGillNets);
      if ((upgradePlanID >= 0) && (kbUnitCount(cMyID, gFishingUnit, cUnitStateAlive) < 7))
         aiPlanDestroy(upgradePlanID);
      if ((upgradePlanID < 0) && (kbUnitCount(cMyID, gFishingUnit, cUnitStateAlive) >= 7))
      {
         createSimpleResearchPlan(cTechGillNets, gDockUnit, cEconomyEscrowID, 45);
         return;
      }
   }
   // Research Long Lines after 9 Fishing Boats, it has great % improvement but is quite expensive too so we wait a little.
   if (kbTechGetStatus(cTechLongLines) == cTechStatusObtainable)
   {
      upgradePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechLongLines);
      if ((upgradePlanID >= 0) && (kbUnitCount(cMyID, gFishingUnit, cUnitStateAlive) < 9))
         aiPlanDestroy(upgradePlanID);
      if ((upgradePlanID < 0) && (kbUnitCount(cMyID, gFishingUnit, cUnitStateAlive) >= 9))
      {
         createSimpleResearchPlan(cTechLongLines, gDockUnit, cEconomyEscrowID, 45);
         return;
      }
   }

   int navySize = kbUnitCount(cMyID, cUnitTypeLogicalTypeNavalMilitary, cUnitStateAlive);

   // Research and destroy navy improvement plans when appropriate.
   if (kbTechGetStatus(cTechCarronade) == cTechStatusObtainable)
   {
      upgradePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechCarronade);
      if ((upgradePlanID >= 0) && (navySize < 3))
         aiPlanDestroy(upgradePlanID);
      if ((upgradePlanID < 0) && (navySize >= 3))
      {
         createSimpleResearchPlan(cTechCarronade, gDockUnit, cMilitaryEscrowID, 50);
         return;
      }
   }
   if (kbTechGetStatus(cTechArmorPlating) == cTechStatusObtainable)
   {
      upgradePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechArmorPlating);
      if ((upgradePlanID >= 0) && (navySize < 3))
         aiPlanDestroy(upgradePlanID);
      if ((upgradePlanID < 0) && (navySize >= 3))
      {
         createSimpleResearchPlan(cTechArmorPlating, gDockUnit, cMilitaryEscrowID, 50);
         return;
      }
   }
   if (kbTechGetStatus(cTechShipHowitzers) == cTechStatusObtainable)
   {
      upgradePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechShipHowitzers);
      if ((upgradePlanID >= 0) && (kbUnitCount(cMyID, gMonitorUnit, cUnitStateAlive) < 1))
         aiPlanDestroy(upgradePlanID);
      if ((upgradePlanID < 0) && (kbUnitCount(cMyID, gMonitorUnit, cUnitStateAlive) >= 1))
      {
         createSimpleResearchPlan(cTechShipHowitzers, gDockUnit, cMilitaryEscrowID, 50);
         return;
      }
   }
}

rule arsenalUpgradeMonitor
inactive
minInterval 60
{
   int researchBuildingPUID = -1;

   // New Ways cards.
   if ((cMyCiv == cCivXPIroquois) || (cMyCiv == cCivXPSioux))
   {
      researchBuildingPUID = cMyCiv == cCivXPIroquois ? cUnitTypeLonghouse : cUnitTypeTeepee;
   }
   // Dutch Consulate Arsenal.
   else if ((cMyCiv == cCivJapanese) || (cMyCiv == cCivSPCJapanese) || (cMyCiv == cCivSPCJapaneseEnemy))
   {
      researchBuildingPUID = cUnitTypeypArsenalAsian;
   }
   // This means we're either European or African (Portuguese/British Alliance).
   else
   {
      static int africanWagonMaintainPlan = -1;
      researchBuildingPUID = cUnitTypeArsenal;
   }

   if (kbUnitCount(cMyID, researchBuildingPUID, cUnitStateABQ) < 1)
   {
      if ((cMyCiv == cCivJapanese) || (cMyCiv == cCivSPCJapanese) || (cMyCiv == cCivSPCJapaneseEnemy))
      {
         if (kbUnitCount(cMyID, cUnitTypeypArsenalWagon, cUnitStateAlive) < 1)
         { // We can't remake this so disable the Rule.
            xsDisableSelf();
         }
      }
      else if (civIsAfrican() == true)
      {
         if (africanWagonMaintainPlan < 0)
         {
            africanWagonMaintainPlan = createSimpleMaintainPlan(cUnitTypedeTrainArsenalWagon,
               1, true, kbBaseGetMainID(cMyID), 1);
         }
         else // Set the maintain plan to 1.
         {
            aiPlanSetVariableInt(africanWagonMaintainPlan, cTrainPlanNumberToMaintain, 0, 1);
         }
      }
      else
      {
         // See if we already have a build plan and otherwise create one.
         if (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeArsenal) < 0)
         {
            createSimpleBuildPlan(cUnitTypeArsenal, 1, 50, false, cMilitaryEscrowID, kbBaseGetMainID(cMyID), 1);
         }
      }
      return;
   }
   else if (civIsAfrican() == true)
   {
      if (africanWagonMaintainPlan >= 0) // We have an Arsenal and a plan so null out the maintain plan.
      {
         aiPlanSetVariableInt(africanWagonMaintainPlan, cTrainPlanNumberToMaintain, 0, 0);
      }
   }

   // Shared upgrades.
   bool canDisableSelf = researchSimpleTechByCondition(cTechCavalryCuirass,
      []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractHeavyCavalry, cUnitStateABQ) >= 12); },
      researchBuildingPUID);

   canDisableSelf &= researchSimpleTechByCondition(cTechInfantryBreastplate,
      []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractHandInfantry, cUnitStateABQ) +
      kbUnitCount(cMyID, cUnitTypeAbstractFootArcher, cUnitStateABQ) >= 12); },
      researchBuildingPUID);

   // The Lakota don't have this upgrade.
   // Only get 'Heated Shot' upgrade on water maps.
   if ((cMyCiv != cCivXPSioux) && (gNavyMap == true))
   {
      canDisableSelf &= researchSimpleTechByCondition(cTechHeatedShot,
         []() -> bool { return ((kbUnitCount(cMyID, cUnitTypeAbstractArtillery, cUnitStateABQ) >= 2) &&
         (getUnitCountByLocation(cUnitTypeAbstractWarShip, cPlayerRelationEnemyNotGaia, cUnitStateAlive) >= 2)); }, 
         researchBuildingPUID);
   }

   // The Haudenosaunee and Lakota don't have these 2 upgrades.
   if ((cMyCiv != cCivXPIroquois) && (cMyCiv != cCivXPSioux))
   {
      canDisableSelf &= researchSimpleTechByCondition(cTechGunnersQuadrant,
         []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractArtillery, cUnitStateABQ) >= 4); },
         researchBuildingPUID);

      canDisableSelf &= researchSimpleTechByCondition(cTechBayonet,
         []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractMusketeer, cUnitStateABQ) >= 12); },
         researchBuildingPUID);
   }

   // The Japanese Arsenal doesn't have these 2 upgrades.
   if ((cMyCiv != cCivJapanese) && (cMyCiv != cCivSPCJapanese) && (cMyCiv != cCivSPCJapaneseEnemy))
   {
      canDisableSelf &= researchSimpleTechByCondition(cTechRifling,
         []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractRifleman, cUnitStateABQ) >= 12); },
         researchBuildingPUID);

      canDisableSelf &= researchSimpleTechByCondition(cTechCaracole,
         []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractLightCavalry, cUnitStateABQ) >= 12); },
         researchBuildingPUID);
   }

   // Other civs can only get this upgrade in the advanced Arsenal but for simplicity for the Lakota it's checked here just for
   // them.
   if (cMyCiv == cCivXPSioux)
   {
      canDisableSelf &= researchSimpleTechByCondition(cTechPillage,
         []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractHandCavalry, cUnitStateABQ) >= 8); },
         researchBuildingPUID);
   }

   if (canDisableSelf == true)
   {
      if (civIsAfrican() == true)
      {
         aiPlanDestroy(africanWagonMaintainPlan);
      }
      xsDisableSelf();
   }
}

rule advancedArsenalUpgradeMonitor
inactive
minInterval 60
{
   int researchBuildingID = -1;

   // We are Japanese and have a Golden Pavilion.
   if ((cMyCiv == cCivJapanese) || (cMyCiv == cCivSPCJapanese) || (cMyCiv == cCivSPCJapaneseEnemy))
   {
      researchBuildingID = getUnit(gGoldenPavilionPUID, cMyID, cUnitStateAlive);
   }
   // We are European and have sent the Advanced Arsenal card.
   else
   {
      researchBuildingID = getUnit(cUnitTypeArsenal, cMyID, cUnitStateAlive);
   }

   if (researchBuildingID < 0)
   {
      // We've lost our Golden Pavilion, so disable this Rule.
      if ((cMyCiv == cCivJapanese) || (cMyCiv == cCivSPCJapanese) || (cMyCiv == cCivSPCJapaneseEnemy))
      {
         xsDisableSelf();
      }
      else
      {
         // See if we already have a build plan and otherwise create one.
         if (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeArsenal) < 0)
         {
            createSimpleBuildPlan(cUnitTypeArsenal, 1, 50, false, cMilitaryEscrowID, kbBaseGetMainID(cMyID), 1);
         }
      }
      return;
   }

   // Shared Upgrades.
   bool canDisableSelf = researchSimpleTechByCondition(cTechPaperCartridge,
      []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractGunpowderTrooper, cUnitStateABQ) >= 12); },
      -1, researchBuildingID);

   canDisableSelf &= researchSimpleTechByCondition(cTechFlintlock,
      []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractGunpowderTrooper, cUnitStateABQ) >= 12); },
      -1, researchBuildingID);

   canDisableSelf &= researchSimpleTechByCondition(cTechProfessionalGunners,
      []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractArtillery, cUnitStateABQ) >= 6); },
      -1, researchBuildingID);

   canDisableSelf &= researchSimpleTechByCondition(cTechPillage,
      []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractHandCavalry, cUnitStateABQ) >= 8); },
      -1, researchBuildingID);

   // The Golden Pavilion doesn't have the following 2 upgrades so don't check.
   if ((cMyCiv != cCivJapanese) || (cMyCiv != cCivSPCJapanese) || (cMyCiv != cCivSPCJapaneseEnemy))
   {
      canDisableSelf &= researchSimpleTechByCondition(cTechTrunion,
         []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractArtillery, cUnitStateABQ) >= 6); },
         -1, researchBuildingID);

      // Only these civs have access to this upgrade from all the European civs.
      if ((cMyCiv == cCivBritish) || (cMyCiv == cCivDutch) || (cMyCiv == cCivOttomans) || (cMyCiv == cCivRussians) ||
          (cMyCiv == cCivDESwedish))
      {
         canDisableSelf &= researchSimpleTechByCondition(cTechIncendiaryGrenades,
            []() -> bool { return (kbUnitCount(cMyID, cUnitTypeGrenadier, cUnitStateABQ) >= 12); },
            -1, researchBuildingID);
      }
   }

   if (canDisableSelf == true)
   {
      xsDisableSelf();
   }
}

//==============================================================================
/* churchUpgradeMonitor
   We don't get Bastion because the AI doesn't build Walls at this moment.
   We don't get Marcantilism because the AI isn't very good with shipments.
   We don't get Mission Fervor because the AI has no proper healing system.
   This monitor is also used for the specific Mexican Cathedral upgrades.
   We don't get the Padre specific technologies since the AI doesn't know how to use their effects.
   We don't get Holy Mass because the AI isn't very good with shipments.
   We don't get State Religion because we can't plan for this and it costs Gold here.
*/
//==============================================================================
rule churchUpgradeMonitor
inactive
minInterval 60
{
   int researchBuildingPUID = -1;

   if (civIsAsian() == true)
   {
      researchBuildingPUID = cUnitTypeypChurch;
   }
   else if (cMyCiv == cCivDEMexicans)
   {
      researchBuildingPUID = cUnitTypedeCathedral;
   }
   else // We're European or Ethiopians with Jesuit alliance.
   {
      researchBuildingPUID = cUnitTypeChurch;
   }

   // Quit if there is no Church / Cathedral.
   if (kbUnitCount(cMyID, researchBuildingPUID, cUnitStateAlive) < 1)
   {
      return;
   }

   // Just get the 2 LOS upgrades, still low priority upgrades.
   bool canDisableSelf = researchSimpleTech(cTechChurchTownWatch, researchBuildingPUID, -1, 49);

   canDisableSelf &= researchSimpleTech(cTechChurchGasLighting, researchBuildingPUID, -1, 49);

   // Get the 2 training time reduction upgrades once we already have 60% of our gMaxPop.
   canDisableSelf &= ((researchSimpleTechByCondition(cTechChurchMassCavalry,
      []() -> bool { return (kbGetPop() >= gMaxPop * 0.6); },
      researchBuildingPUID)) ||
      (cvMaxAge < cAge4));

   canDisableSelf &= ((researchSimpleTechByCondition(cTechChurchStandingArmy,
      []() -> bool { return (kbGetPop() >= gMaxPop * 0.6); },
      researchBuildingPUID)) ||
      (cvMaxAge < cAge4));

   if (cMyCiv == cCivDEMexicans)
   {
      // Only get this upgrade when we're at max Houses. We will make less Houses on lower difficulties so account for that.
      canDisableSelf &= researchSimpleTechByCondition(cTechDEChurchSevenHouses,
         []() -> bool { return (kbUnitCount(cMyID, cUnitTypeHouseMed, cUnitStateAlive) == gMaxPop / 10); },
         researchBuildingPUID);

      // Get at 500xp.
      canDisableSelf &= researchSimpleTechByCondition(cTechDEChurchDiaDeLosMuertos,
         []() -> bool { return (kbTechGetHCCardValuePerResource(cTechDEChurchDiaDeLosMuertos, cResourceXP) >= 500); },
         researchBuildingPUID);
   }

   if (canDisableSelf == true)
   {
      xsDisableSelf();
   }
}

rule royalDecreeMonitor
inactive
minInterval 60
{
   int decreePlanID = -1;
   int consulateID = getUnit(cUnitTypeAbstractChurch, cMyID, cUnitStateAlive);
   static bool allTechsActive = false;
   
	  
	  
   // Quit if we didn't ship the required card yet
   if ((kbTechGetStatus(cTechHCRoyalDecreeBritish) != cTechStatusActive) ||
       (kbTechGetStatus(cTechHCRoyalDecreeDutch) != cTechStatusActive) ||
       (kbTechGetStatus(cTechHCRoyalDecreeFrench) != cTechStatusActive) ||
       (kbTechGetStatus(cTechHCRoyalDecreeGerman) != cTechStatusActive) ||
       (kbTechGetStatus(cTechHCRoyalDecreeOttoman) != cTechStatusActive) ||
       (kbTechGetStatus(cTechHCRoyalDecreePortuguese) != cTechStatusActive) ||
       (kbTechGetStatus(cTechHCRoyalDecreeRussian) != cTechStatusActive) ||
       (kbTechGetStatus(cTechDEHCRoyalDecreeSwedish) != cTechStatusActive) ||
       (kbTechGetStatus(cTechHCRoyalDecreeSpanish) != cTechStatusActive))
      return;
   // Quit if there is no church
   if (kbUnitCount(cMyID, cUnitTypeChurch, cUnitStateAlive) < 1)
      return;
   switch(cMyCiv)
   {
      case cCivBritish:
      {
         // Disable rule once all upgrades are available
         if ((kbTechGetStatus(cTechChurchThinRedLine) == cTechStatusActive) &&
             (kbTechGetStatus(cTechChurchBlackWatch) == cTechStatusActive) &&
             (kbTechGetStatus(cTechChurchRogersRangers) == cTechStatusActive))
         {
            xsDisableSelf();
            return;
         }
		 allTechsActive = researchSimpleTech(cTechChurchThinRedLine, -1, consulateID);
		 allTechsActive = researchSimpleTech(cTechChurchBlackWatch, -1, consulateID);
		 allTechsActive = researchSimpleTech(cTechChurchRogersRangers, -1, consulateID);
         // Get upgrades/troops as they become available
         if (kbTechGetStatus(cTechChurchThinRedLine) == cTechStatusObtainable)
   {
      decreePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechChurchThinRedLine);
      if (decreePlanID >= 0)
         aiPlanDestroy(decreePlanID);
      createSimpleResearchPlan(cTechChurchThinRedLine, getUnit(cUnitTypeAbstractChurch), cMilitaryEscrowID, 95);
	  aiPlanSetDesiredPriority(decreePlanID, 95);// 95);
	  aiPlanSetDesiredResourcePriority(decreePlanID, 95);
      return;
   }
         if (kbTechGetStatus(cTechChurchBlackWatch) == cTechStatusObtainable)
         {
      decreePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechChurchBlackWatch);
      if (decreePlanID >= 0)
         aiPlanDestroy(decreePlanID);
      createSimpleResearchPlan(cTechChurchBlackWatch, getUnit(cUnitTypeAbstractChurch), cMilitaryEscrowID, 65);
	  aiPlanSetDesiredPriority(decreePlanID, 95);// 65);
	  aiPlanSetDesiredResourcePriority(decreePlanID, 65);
      return;
         }
         if (kbTechGetStatus(cTechChurchRogersRangers) == cTechStatusObtainable)
         {
      decreePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechChurchRogersRangers);
      if (decreePlanID >= 0)
         aiPlanDestroy(decreePlanID);
      createSimpleResearchPlan(cTechChurchRogersRangers, getUnit(cUnitTypeAbstractChurch), cMilitaryEscrowID, 65);
	  aiPlanSetDesiredPriority(decreePlanID, 95);// 65);
	  aiPlanSetDesiredResourcePriority(decreePlanID, 65);
      return;
         }
         break;
      }
      case cCivDutch:
      {
		 allTechsActive = researchSimpleTech(cTechChurchCoffeeTrade, -1, consulateID);
		 allTechsActive = researchSimpleTech(cTechChurchWaardgelders, -1, consulateID);
		 allTechsActive = researchSimpleTech(cTechChurchStadholders, -1, consulateID);
         // Disable rule once all upgrades are available
         if ((kbTechGetStatus(cTechChurchCoffeeTrade) == cTechStatusActive) &&
             (kbTechGetStatus(cTechChurchWaardgelders) == cTechStatusActive) &&
             (kbTechGetStatus(cTechChurchStadholders) == cTechStatusActive))
         {
            xsDisableSelf();
            return;
         }
         // Get upgrades/troops as they become available
         if (kbTechGetStatus(cTechChurchCoffeeTrade) == cTechStatusObtainable)
         {
      decreePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechChurchCoffeeTrade);
      if (decreePlanID >= 0)
         aiPlanDestroy(decreePlanID);
      createSimpleResearchPlan(cTechChurchCoffeeTrade, getUnit(cUnitTypeAbstractChurch), cMilitaryEscrowID, 95);
	  aiPlanSetDesiredPriority(decreePlanID, 95);// 95);
	  aiPlanSetDesiredResourcePriority(decreePlanID, 95);
      return;
         }
         if (kbTechGetStatus(cTechChurchWaardgelders) == cTechStatusObtainable)
         {
      decreePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechChurchWaardgelders);
      if (decreePlanID >= 0)
         aiPlanDestroy(decreePlanID);
      createSimpleResearchPlan(cTechChurchWaardgelders, getUnit(cUnitTypeAbstractChurch), cMilitaryEscrowID, 65);
	  aiPlanSetDesiredPriority(decreePlanID, 95);// 65);
	  aiPlanSetDesiredResourcePriority(decreePlanID, 65);
      return;
         }
         if (kbTechGetStatus(cTechChurchStadholders) == cTechStatusObtainable)
         {
      decreePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechChurchStadholders);
      if (decreePlanID >= 0)
         aiPlanDestroy(decreePlanID);
      createSimpleResearchPlan(cTechChurchStadholders, getUnit(cUnitTypeAbstractChurch), cMilitaryEscrowID, 65);
	  aiPlanSetDesiredPriority(decreePlanID, 95);// 65);
	  aiPlanSetDesiredResourcePriority(decreePlanID, 65);
      return;
         }
         break;
      }
      case cCivFrench:
      {
		 allTechsActive = researchSimpleTech(cTechChurchCodeNapoleon, -1, consulateID);
		 allTechsActive = researchSimpleTech(cTechChurchGardeImperial1, -1, consulateID);
		 allTechsActive = researchSimpleTech(cTechChurchGardeImperial2, -1, consulateID);
		 allTechsActive = researchSimpleTech(cTechChurchGardeImperial3, -1, consulateID);
         // Disable rule once all upgrades are available
         if ((kbTechGetStatus(cTechChurchCodeNapoleon) == cTechStatusActive) &&
             (kbTechGetStatus(cTechChurchGardeImperial1) == cTechStatusActive) &&
             (kbTechGetStatus(cTechChurchGardeImperial2) == cTechStatusActive) &&
             (kbTechGetStatus(cTechChurchGardeImperial3) == cTechStatusActive))
         {
            xsDisableSelf();
            return;
         }
         // Get upgrades/troops as they become available
         if ((kbTechGetStatus(cTechChurchCodeNapoleon) == cTechStatusObtainable) && (kbGetAge() >= cAge4))
         {
      decreePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechChurchCodeNapoleon);
      if (decreePlanID >= 0)
         aiPlanDestroy(decreePlanID);
      createSimpleResearchPlan(cTechChurchCodeNapoleon, getUnit(cUnitTypeAbstractChurch), cMilitaryEscrowID, 65);
	  aiPlanSetDesiredPriority(decreePlanID, 95);// 65);
	  aiPlanSetDesiredResourcePriority(decreePlanID, 65);
      return;
         }
         if (kbTechGetStatus(cTechChurchGardeImperial1) == cTechStatusObtainable)
         {
      decreePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechChurchGardeImperial1);
      if (decreePlanID >= 0)
         aiPlanDestroy(decreePlanID);
      createSimpleResearchPlan(cTechChurchGardeImperial1, getUnit(cUnitTypeAbstractChurch), cMilitaryEscrowID, 50);
	  aiPlanSetDesiredPriority(decreePlanID, 95);// 50);
	  aiPlanSetDesiredResourcePriority(decreePlanID, 50);
      return;
         }
         if (kbTechGetStatus(cTechChurchGardeImperial2) == cTechStatusObtainable)
         {
      decreePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechChurchGardeImperial2);
      if (decreePlanID >= 0)
         aiPlanDestroy(decreePlanID);
      createSimpleResearchPlan(cTechChurchGardeImperial2, getUnit(cUnitTypeAbstractChurch), cMilitaryEscrowID, 50);
	  aiPlanSetDesiredPriority(decreePlanID, 95);// 50);
	  aiPlanSetDesiredResourcePriority(decreePlanID, 50);
      return;
         }
         if (kbTechGetStatus(cTechChurchGardeImperial3) == cTechStatusObtainable)
         {
      decreePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechChurchGardeImperial3);
      if (decreePlanID >= 0)
         aiPlanDestroy(decreePlanID);
      createSimpleResearchPlan(cTechChurchGardeImperial3, getUnit(cUnitTypeAbstractChurch), cMilitaryEscrowID, 50);
	  aiPlanSetDesiredPriority(decreePlanID, 95);// 50);
	  aiPlanSetDesiredResourcePriority(decreePlanID, 50);
      return;
         }
         break;
      }
      case cCivGermans:
      {
		 allTechsActive = researchSimpleTech(cTechChurchTillysDiscipline, -1, consulateID);
		 //allTechsActive = researchSimpleTech(cTechChurchWallensteinsContracts, -1, consulateID);
		 allTechsActive = researchSimpleTech(cTechChurchZweihander, -1, consulateID);
         // Disable rule once all upgrades are available
         if ((kbTechGetStatus(cTechChurchTillysDiscipline) == cTechStatusActive) &&
             //(kbTechGetStatus(cTechChurchWallensteinsContracts) == cTechStatusActive) &&
             (kbTechGetStatus(cTechChurchZweihander) == cTechStatusActive))
         {
            xsDisableSelf();
            return;
         }
         // Get upgrades/troops as they become available
         if (kbTechGetStatus(cTechChurchTillysDiscipline) == cTechStatusObtainable)
         {
      decreePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechChurchTillysDiscipline);
      if (decreePlanID >= 0)
         aiPlanDestroy(decreePlanID);
      createSimpleResearchPlan(cTechChurchTillysDiscipline, getUnit(cUnitTypeAbstractChurch), cMilitaryEscrowID, 95);
	  aiPlanSetDesiredPriority(decreePlanID, 95);// 95);
	  aiPlanSetDesiredResourcePriority(decreePlanID, 95);
      return;
         }/*
         if (kbTechGetStatus(cTechChurchWallensteinsContracts) == cTechStatusObtainable)
         {
            if (aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechChurchWallensteinsContracts) >= 0)
               return;
            decreePlanID = createSimpleResearchPlan(cTechChurchWallensteinsContracts, getUnit(cUnitTypeChurch), cMilitaryEscrowID, 50);
	        aiPlanSetDesiredResourcePriority(decreePlanID, 56);
         }*/
         if (kbTechGetStatus(cTechChurchZweihander) == cTechStatusObtainable)
         {
      decreePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechChurchZweihander);
      if (decreePlanID >= 0)
         aiPlanDestroy(decreePlanID);
      createSimpleResearchPlan(cTechChurchZweihander, getUnit(cUnitTypeAbstractChurch), cMilitaryEscrowID, 65);
	  aiPlanSetDesiredPriority(decreePlanID, 95);// 65);
	  aiPlanSetDesiredResourcePriority(decreePlanID, 65);
      return;
         }
         break;
      }
      case cCivOttomans:
      {
		 allTechsActive = researchSimpleTech(cTechChurchTufanciCorps, -1, consulateID);
		 allTechsActive = researchSimpleTech(cTechChurchTopcuCorps, -1, consulateID);
         // Disable rule once all upgrades are available
         if ((kbTechGetStatus(cTechChurchTufanciCorps) == cTechStatusActive) &&
             (kbTechGetStatus(cTechChurchTopcuCorps) == cTechStatusActive))
         {
            xsDisableSelf();
            return;
         }
         // Get upgrades/troops as they become available
         if (kbTechGetStatus(cTechChurchTufanciCorps) == cTechStatusObtainable)
         {
      decreePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechChurchTufanciCorps);
      if (decreePlanID >= 0)
         aiPlanDestroy(decreePlanID);
      createSimpleResearchPlan(cTechChurchTufanciCorps, getUnit(cUnitTypeAbstractChurch), cMilitaryEscrowID, 65);
	  aiPlanSetDesiredPriority(decreePlanID, 95);// 65);
	  aiPlanSetDesiredResourcePriority(decreePlanID, 65);
      return;
         }
         if (kbTechGetStatus(cTechChurchTopcuCorps) == cTechStatusObtainable)
         {
      decreePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechChurchTopcuCorps);
      if (decreePlanID >= 0)
         aiPlanDestroy(decreePlanID);
      createSimpleResearchPlan(cTechChurchTopcuCorps, getUnit(cUnitTypeAbstractChurch), cMilitaryEscrowID, 65);
	  aiPlanSetDesiredPriority(decreePlanID, 95);// 65);
	  aiPlanSetDesiredResourcePriority(decreePlanID, 65);
      return;
         }
         break;
      }
      case cCivPortuguese:
      {
		 allTechsActive = researchSimpleTech(cTechChurchEconmediaManor, -1, consulateID);
		 allTechsActive = researchSimpleTech(cTechChurchBestieros, -1, consulateID);
		 allTechsActive = researchSimpleTech(cTechChurchTowerAndSword, -1, consulateID);
         // Disable rule once all upgrades are available
         if ((kbTechGetStatus(cTechChurchEconmediaManor) == cTechStatusActive) &&
		     (kbTechGetStatus(cTechChurchBestieros) == cTechStatusActive) &&
             (kbTechGetStatus(cTechChurchTowerAndSword) == cTechStatusActive))
         {
            xsDisableSelf();
            return;
         }
         // Get upgrades/troops as they become available
         if ((kbTechGetStatus(cTechChurchEconmediaManor) == cTechStatusObtainable) && (kbUnitCount(cMyID, cUnitTypeMill, cUnitStateAlive) >= 4) && (gTimeToFarm == true))
         {  // Only get this when we're really focusing on mills
      decreePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechChurchEconmediaManor);
      if (decreePlanID >= 0)
         aiPlanDestroy(decreePlanID);
      createSimpleResearchPlan(cTechChurchEconmediaManor, getUnit(cUnitTypeAbstractChurch), cMilitaryEscrowID, 95);
	  aiPlanSetDesiredPriority(decreePlanID, 95);// 95);
	  aiPlanSetDesiredResourcePriority(decreePlanID, 95);
      return;
         }
         if (kbTechGetStatus(cTechChurchBestieros) == cTechStatusObtainable)
         {
      decreePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechChurchBestieros);
      if (decreePlanID >= 0)
         aiPlanDestroy(decreePlanID);
      createSimpleResearchPlan(cTechChurchBestieros, getUnit(cUnitTypeAbstractChurch), cMilitaryEscrowID, 65);
	  aiPlanSetDesiredPriority(decreePlanID, 95);// 65);
	  aiPlanSetDesiredResourcePriority(decreePlanID, 65);
      return;
         }
         if (kbTechGetStatus(cTechChurchTowerAndSword) == cTechStatusObtainable)
         {
      decreePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechChurchTowerAndSword);
      if (decreePlanID >= 0)
         aiPlanDestroy(decreePlanID);
      createSimpleResearchPlan(cTechChurchTowerAndSword, getUnit(cUnitTypeAbstractChurch), cMilitaryEscrowID, 65);
	  aiPlanSetDesiredPriority(decreePlanID, 95);// 65);
	  aiPlanSetDesiredResourcePriority(decreePlanID, 65);
      return;
         }
         break;
      }
      case cCivRussians:
      {
		  
		 allTechsActive = researchSimpleTech(cTechChurchWesternization, -1, consulateID);
		 allTechsActive = researchSimpleTech(cTechChurchPetrineReforms, -1, consulateID);
		 allTechsActive = researchSimpleTech(cTechChurchKalmucks, -1, consulateID);
		 allTechsActive = researchSimpleTech(cTechChurchBashkirPonies, -1, consulateID);
         // Disable rule once all upgrades are available
         if ((kbTechGetStatus(cTechChurchWesternization) == cTechStatusActive) &&
             (kbTechGetStatus(cTechChurchPetrineReforms) == cTechStatusActive) &&
             (kbTechGetStatus(cTechChurchKalmucks) == cTechStatusActive) &&
             (kbTechGetStatus(cTechChurchBashkirPonies) == cTechStatusActive))
         {
            xsDisableSelf();
            return;
         }
         // Get upgrades/troops as they become available
         if (kbTechGetStatus(cTechChurchWesternization) == cTechStatusObtainable)
         {
      decreePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechChurchWesternization);
      if (decreePlanID >= 0)
         aiPlanDestroy(decreePlanID);
      createSimpleResearchPlan(cTechChurchWesternization, getUnit(cUnitTypeAbstractChurch), cMilitaryEscrowID, 95);
	  aiPlanSetDesiredPriority(decreePlanID, 95);// 95);
	  aiPlanSetDesiredResourcePriority(decreePlanID, 95);
      return;
         }
         if (kbTechGetStatus(cTechChurchPetrineReforms) == cTechStatusObtainable)
         {
      decreePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechChurchPetrineReforms);
      if (decreePlanID >= 0)
         aiPlanDestroy(decreePlanID);
      createSimpleResearchPlan(cTechChurchPetrineReforms, getUnit(cUnitTypeAbstractChurch), cMilitaryEscrowID, 95);
	  aiPlanSetDesiredPriority(decreePlanID, 95);// 95);
	  aiPlanSetDesiredResourcePriority(decreePlanID, 95);
      return;
         }
         if (kbTechGetStatus(cTechChurchKalmucks) == cTechStatusObtainable)
         {
      decreePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechChurchKalmucks);
      if (decreePlanID >= 0)
         aiPlanDestroy(decreePlanID);
      createSimpleResearchPlan(cTechChurchKalmucks, getUnit(cUnitTypeAbstractChurch), cMilitaryEscrowID, 65);
	  aiPlanSetDesiredPriority(decreePlanID, 95);// 65);
	  aiPlanSetDesiredResourcePriority(decreePlanID, 65);
      return;
         }
         if (kbTechGetStatus(cTechChurchBashkirPonies) == cTechStatusObtainable)
         {
      decreePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechChurchBashkirPonies);
      if (decreePlanID >= 0)
         aiPlanDestroy(decreePlanID);
      createSimpleResearchPlan(cTechChurchBashkirPonies, getUnit(cUnitTypeAbstractChurch), cMilitaryEscrowID, 65);
	  aiPlanSetDesiredPriority(decreePlanID, 95);// 65);
	  aiPlanSetDesiredResourcePriority(decreePlanID, 65);
      return;
         }
         break;
      }
      case cCivSpanish:
      {
		 allTechsActive = researchSimpleTech(cTechChurchCorsolet, -1, consulateID);
		 allTechsActive = researchSimpleTech(cTechChurchQuatrefage, -1, consulateID);
		 allTechsActive = researchSimpleTech(cTechChurchWildGeeseSpanish, -1, consulateID);
         // Disable rule once all upgrades are available
         if ((kbTechGetStatus(cTechChurchCorsolet) == cTechStatusActive) &&
             (kbTechGetStatus(cTechChurchQuatrefage) == cTechStatusActive) &&
             (kbTechGetStatus(cTechChurchWildGeeseSpanish) == cTechStatusActive))
         {
            xsDisableSelf();
            return;
         }
         // Get upgrades/troops as they become available
         if (kbTechGetStatus(cTechChurchCorsolet) == cTechStatusObtainable)
         {
      decreePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechChurchCorsolet);
      if (decreePlanID >= 0)
         aiPlanDestroy(decreePlanID);
      createSimpleResearchPlan(cTechChurchCorsolet, getUnit(cUnitTypeAbstractChurch), cMilitaryEscrowID, 95);
	  aiPlanSetDesiredPriority(decreePlanID, 95);// 95);
	  aiPlanSetDesiredResourcePriority(decreePlanID, 95);
      return;
         }
         if (kbTechGetStatus(cTechChurchQuatrefage) == cTechStatusObtainable)
         {
      decreePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechChurchQuatrefage);
      if (decreePlanID >= 0)
         aiPlanDestroy(decreePlanID);
      createSimpleResearchPlan(cTechChurchQuatrefage, getUnit(cUnitTypeAbstractChurch), cMilitaryEscrowID, 65);
	  aiPlanSetDesiredPriority(decreePlanID, 95);// 65);
	  aiPlanSetDesiredResourcePriority(decreePlanID, 65);
      return;
         }
         if (kbTechGetStatus(cTechChurchWildGeeseSpanish) == cTechStatusObtainable)
         {
      decreePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechChurchWildGeeseSpanish);
      if (decreePlanID >= 0)
         aiPlanDestroy(decreePlanID);
      createSimpleResearchPlan(cTechChurchWildGeeseSpanish, getUnit(cUnitTypeAbstractChurch), cMilitaryEscrowID, 65);
	  aiPlanSetDesiredPriority(decreePlanID, 95);// 65);
	  aiPlanSetDesiredResourcePriority(decreePlanID, 65);
      return;
         }
         break;
      }
      case cCivDESwedish:
      {
		 allTechsActive = researchSimpleTech(cTechDEChurchPikePush, -1, consulateID);
		 allTechsActive = researchSimpleTech(cTechDEChurchSavolaxJaegers, -1, consulateID);
		 allTechsActive = researchSimpleTech(cTechDEChurchGustavianGuards, -1, consulateID);
         // Disable rule once all upgrades are available
         if ((kbTechGetStatus(cTechDEChurchPikePush) == cTechStatusActive) &&
             (kbTechGetStatus(cTechDEChurchSavolaxJaegers) == cTechStatusActive) &&
             (kbTechGetStatus(cTechDEChurchGustavianGuards) == cTechStatusActive))
         {
            xsDisableSelf();
            return;
         }
         // Get upgrades/troops as they become available
         if (kbTechGetStatus(cTechDEChurchPikePush) == cTechStatusObtainable)
         {
      decreePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechDEChurchPikePush);
      if (decreePlanID >= 0)
         aiPlanDestroy(decreePlanID);
      createSimpleResearchPlan(cTechDEChurchPikePush, getUnit(cUnitTypeAbstractChurch), cMilitaryEscrowID, 65);
	  aiPlanSetDesiredPriority(decreePlanID, 95);// 65);
	  aiPlanSetDesiredResourcePriority(decreePlanID, 65);
      return;
         }
         if (kbTechGetStatus(cTechDEChurchSavolaxJaegers) == cTechStatusObtainable)
         {
      decreePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechDEChurchSavolaxJaegers);
      if (decreePlanID >= 0)
         aiPlanDestroy(decreePlanID);
      createSimpleResearchPlan(cTechDEChurchSavolaxJaegers, getUnit(cUnitTypeAbstractChurch), cMilitaryEscrowID, 65);
	  aiPlanSetDesiredPriority(decreePlanID, 95);// 65);
	  aiPlanSetDesiredResourcePriority(decreePlanID, 65);
      return;
         }
         if (kbTechGetStatus(cTechDEChurchGustavianGuards) == cTechStatusObtainable)
         {
      decreePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechDEChurchGustavianGuards);
      if (decreePlanID >= 0)
         aiPlanDestroy(decreePlanID);
      createSimpleResearchPlan(cTechDEChurchGustavianGuards, getUnit(cUnitTypeAbstractChurch), cMilitaryEscrowID, 65);
	  aiPlanSetDesiredPriority(decreePlanID, 95);// 65);
	  aiPlanSetDesiredResourcePriority(decreePlanID, 65);
      return;
         }
         break;
      }
   }
}

rule factoryUpgradeMonitor
inactive
minInterval 45
{
   if ((kbUnitCount(cMyID, cUnitTypeFactory, cUnitStateABQ) < 1) &&
       (kbUnitCount(cMyID, cUnitTypeFactoryWagon, cUnitStateAlive) < 1))
   {
      xsDisableSelf();
      return;
   }
   
   bool canDisableSelf = researchSimpleTechByCondition(cTechFactoryCannery,
      []() -> bool { return (getUnitCountByTactic(cUnitTypeFactory, cMyID, cUnitStateAlive, cTacticFood) >= 1); },
      cUnitTypeFactory);
   
   canDisableSelf &= researchSimpleTechByCondition(cTechFactoryWaterPower,
      []() -> bool { return (getUnitCountByTactic(cUnitTypeFactory, cMyID, cUnitStateAlive, cTacticWood) >= 1); },
      cUnitTypeFactory);
   
   canDisableSelf &= researchSimpleTechByCondition(cTechFactorySteamPower,
      []() -> bool { return (getUnitCountByTactic(cUnitTypeFactory, cMyID, cUnitStateAlive, cTacticNormal) >= 1); },
      cUnitTypeFactory);
   
   canDisableSelf &= researchSimpleTechByCondition(cTechFactoryMassProduction,
      []() -> bool { return (getUnitCountByTactic(cUnitTypeFactory, cMyID, cUnitStateAlive, cTechFactoryMassProduction) >= 1); },
      cUnitTypeFactory);
   
   if (cvMaxAge == cAge5)
   {
      if (cMyCiv == cCivOttomans)
      {
         canDisableSelf &= researchSimpleTechByCondition(cTechImperialBombard,
            []() -> bool { return (kbUnitCount(cMyID, cUnitTypeGreatBombard, cUnitStateAlive) >= 4); },
            cUnitTypeFactory);
      }
      else if (cMyCiv == cCivBritish)
      {
         canDisableSelf &= researchSimpleTechByCondition(cTechImperialRocket,
            []() -> bool { return (kbUnitCount(cMyID, cUnitTypeRocket, cUnitStateAlive) >= 4); },
            cUnitTypeFactory);
      }
      else
      {
         canDisableSelf &= researchSimpleTechByCondition(cTechImperialCannon,
            []() -> bool { return (kbUnitCount(cMyID, cUnitTypeCannon, cUnitStateAlive) >= 4); },
            cUnitTypeFactory);
      }
   }
   
   if (canDisableSelf == true)
   {
      xsDisableSelf();
   }
}

void GalataTowerDistrictEventHandler(int planID = -1)
{
   if (aiPlanGetState(planID) == -1)
   {
      if (kbTechGetStatus(cTechChurchGalataTowerDistrict) == cTechStatusActive)
      {
         updateSettlersAndPopManager();
      }
   }
}

void TopkapiEventHandler(int planID = -1)
{
   if (aiPlanGetState(planID) == -1)
   {
      if (kbTechGetStatus(cTechChurchTopkapi) == cTechStatusActive)
      {
         updateSettlersAndPopManager();
      }
   }
}

void TanzimatEventHandler(int planID = -1)
{
   if (aiPlanGetState(planID) == -1)
   {
      if (kbTechGetStatus(cTechChurchTanzimat) == cTechStatusActive)
      {
         updateSettlersAndPopManager();
      }
   }
}

//==============================================================================
/* ottomanMonitor
   This Rule is a little bit more complex since we don't want to get Settler BL increases
   when that would put our BL above our own Settler limits.
   But our Settler limits change when we're playing SPC so we must take all that into account.
*/
//==============================================================================
rule ottomanMonitor
inactive
minInterval 25
{
   int planID = -1;
   // If we have no Mosque we're done.
   int mosqueID = getUnit(cUnitTypeChurch, cMyID, cUnitStateAlive);
   if (mosqueID < 0)
   {
      return;
   }
   
   bool canDisableSelf = researchSimpleTech(cTechChurchMilletSystem, -1, mosqueID, 70);
   
   if (cDifficultyCurrent >= cDifficultyModerate)
   {
      canDisableSelf &= researchSimpleTech(cTechChurchKopruluViziers, -1, mosqueID);
      
      canDisableSelf &= researchSimpleTech(cTechChurchAbbassidMarket, -1, mosqueID);
      
      // 25 Settler limit to 45.
      canDisableSelf &= researchSimpleTechByConditionEventHandler(cTechChurchGalataTowerDistrict,
         []() -> bool { return (kbGetBuildLimit(cMyID, cUnitTypeSettler) - 
         kbUnitCount(cMyID, cUnitTypeSettler, cUnitStateABQ) <= 5); },
         "GalataTowerDistrictEventHandler", -1, mosqueID, 70);

      if ((cDifficultyCurrent >= cDifficultyHard) || 
          ((cDifficultyCurrent == cDifficultyModerate) && (gSPC == false)))
      {
         // 45 Settler limit to 70.
         canDisableSelf &= researchSimpleTechByConditionEventHandler(cTechChurchTopkapi,
            []() -> bool { return (kbGetBuildLimit(cMyID, cUnitTypeSettler) - 
            kbUnitCount(cMyID, cUnitTypeSettler, cUnitStateABQ) <= 7); },
            "TopkapiEventHandler", -1, mosqueID, 70);
         
         if ((cDifficultyCurrent >= cDifficultyExpert) || 
             ((cDifficultyCurrent == cDifficultyHard) && (gSPC == false)))
         {
            // 70 Settler limit to 99.
            canDisableSelf &= researchSimpleTechByConditionEventHandler(cTechChurchTanzimat,
               []() -> bool { return (kbGetBuildLimit(cMyID, cUnitTypeSettler) - 
               kbUnitCount(cMyID, cUnitTypeSettler, cUnitStateABQ) < 10); },
               "TanzimatEventHandler", -1, mosqueID, 70);
         }
      }
   }

   if (canDisableSelf == true)
   {
      xsDisableSelf();
      return;
   }
}

rule warHutUpgradeMonitor
inactive
minInterval 60
{
   bool canDisableSelf = researchSimpleTechByCondition(cTechStrongWarHut, 
      []() -> bool { return (kbUnitCount(cMyID, cUnitTypeWarHut, cUnitStateABQ) >= 3); },
      cUnitTypeWarHut);

   canDisableSelf &= ((researchSimpleTechByCondition(cTechMightyWarHut,
      []() -> bool { return (kbUnitCount(cMyID, cUnitTypeWarHut, cUnitStateABQ) >= 4); },
      cUnitTypeWarHut)) ||
      cvMaxAge < cAge4);

   if (canDisableSelf == true)
   {
      xsDisableSelf();
   }
}

//==============================================================================
// bigButtonAztecMonitor
// This rule researches all the big button upgrades for the Aztecs.
// Excluding the raiding parties, those are used as minutemen in useWarParties.
// TO DO add cTechBigDockCipactli after naval rework.
//==============================================================================
rule bigButtonAztecMonitor
inactive
minInterval 60
{
   if (kbUnitCount(cMyID, cUnitTypeAbstractVillager, cUnitStateAlive) < 20)
   {
      return; // Avoid getting upgrades here with a weak economy.
   }

   // Cheap upgrade, just get it and hope our War Chief stays alive.
   bool canDisableSelf = researchSimpleTechByCondition(cTechBigFirepitFounder,
      []() -> bool { return (kbUnitCount(cMyID, cUnitTypeCommunityPlaza, cUnitStateABQ) >= 1); },
      cUnitTypeCommunityPlaza);

   // Get at least 8 Otontin Slingers.
   canDisableSelf &= researchSimpleTechByCondition(cTechBigHouseCoatlicue,
      []() -> bool { return ( (xsGetTime() >= 16 * 60 * 1000) &&
      (kbUnitCount(cMyID, cUnitTypeHouseAztec, cUnitStateABQ) >= 1) &&
      (indexProtoUnitInUnitPicker(cUnitTypexpMacehualtin) > -1)); },
      cUnitTypeHouseAztec);

   // Get at least 12 Puma Spearmen.
   canDisableSelf &= researchSimpleTechByCondition(cTechBigWarHutBarometz,
      []() -> bool { return ((xsGetTime() >= 24 * 60 * 1000) && 
      (kbUnitCount(cMyID, cUnitTypeWarHut, cUnitStateABQ) >= 1) &&
      (indexProtoUnitInUnitPicker(cUnitTypexpPumaMan) > -1)); },
      cUnitTypeWarHut);

   // Get at least 10 Eagle Runner Knights.
   canDisableSelf &= ((researchSimpleTechByCondition(cTechBigFarmCinteotl,
      []() -> bool {return ((xsGetTime() >= 20 * 60 * 1000) && 
      (kbUnitCount(cMyID, cUnitTypeFarm, cUnitStateABQ) >= 1) &&
      (indexProtoUnitInUnitPicker(cUnitTypexpMacehualtin) > -1)); },
      cUnitTypeFarm)) ||
      (cvMaxAge < cAge3));

   // Get at least 10 Arrow Knights.
   canDisableSelf &= ((researchSimpleTechByCondition(cTechBigNoblesHutWarSong,
      []() -> bool {return ((xsGetTime() >= 20 * 60 * 1000) &&
      (kbUnitCount(cMyID, cUnitTypeNoblesHut, cUnitStateABQ) >= 1) &&
      (indexProtoUnitInUnitPicker(cUnitTypexpArrowKnight) > -1)); },
      cUnitTypeNoblesHut)) ||
      (cvMaxAge < cAge3));

   // Get at least 7 Skull Knights.
   canDisableSelf &= ((researchSimpleTechByCondition(cTechBigPlantationTezcatlipoca,
      []() -> bool { return ((xsGetTime() >= 28 * 60 * 1000) &&
      (kbUnitCount(cMyID, cUnitTypePlantation, cUnitStateABQ) >= 1)); },
      cUnitTypePlantation)) ||
      (cvMaxAge < cAge3));

   if (canDisableSelf == true)
   {
      xsDisableSelf();
   }
}

//==============================================================================
// bigButtonIncaMonitor
// This rule researches all the big button upgrades for the Incas.
// Excluding the raiding parties, those are used as minutemen in useWarParties.
// We don't get Queen's Festival since it's just underpowered right now.
// We don't get Inti Festival since the AI isn't particularly good at using shipments anyway.
// We don't get Viracocha Worship since we don't have a specific strategy on what to do with those 2 builders.
// We don't get Urcuchillay Worship since we don't have a resource strategy to base this upgrade on.
//==============================================================================
rule bigButtonIncaMonitor
inactive
minInterval 60
{
   if (kbUnitCount(cMyID, cUnitTypeAbstractVillager, cUnitStateAlive) < 20)
   {
      return; // Avoid getting upgrades here with a weak economy.
   }

   // Get at least 4 Fishing Boats & Chincha Rafts.
   bool canDisableSelf = ((researchSimpleTechByCondition(cTechdeBigDockTotora,
      []() -> bool { return ((xsGetTime() >= 20 * 60 * 1000) && 
      (kbUnitCount(cMyID, cUnitTypeDock, cUnitStateABQ) >= 1)); },
      cUnitTypeDock)) ||
      (cvMaxAge < cAge3) || 
      (gNavyMap == false));

   // Have at least 20 Infantry before we get this upgrade.
   canDisableSelf &= ((researchSimpleTechByCondition(cTechdeBigWarHutHualcana,
      []() -> bool { return ((kbUnitCount(cMyID, cUnitTypeAbstractInfantry, cUnitStateABQ) +
      kbUnitCount(cMyID, cUnitTypeAbstractLightInfantry, cUnitStateABQ) >= 20) &&
      (kbUnitCount(cMyID, cUnitTypeWarHut, cUnitStateABQ) >= 1)); },
      cUnitTypeWarHut)) ||
      (cvMaxAge < cAge3));

   // Get at least 6 Macemen.
   canDisableSelf &= ((researchSimpleTechByCondition(cTechdeBigFirePitRoyalFestival,
      []() -> bool { return ((xsGetTime() >= 24 * 60 * 1000) &&
      (kbUnitCount(cMyID, cUnitTypeCommunityPlaza, cUnitStateABQ) >= 1) &&
      (indexProtoUnitInUnitPicker(cUnitTypedeMaceman) > -1)); },
      cUnitTypeCommunityPlaza)) ||
      (cvMaxAge < cAge3));

   // We're already in Industrial and have 2+ Estates, still a low priority upgrade.
   canDisableSelf &= ((researchSimpleTechByCondition(cTechdeBigPlantationCoca,
      []() -> bool { return (kbUnitCount(cMyID, cUnitTypePlantation, cUnitStateABQ) >= 2); },
      cUnitTypePlantation, -1, 45)) ||
      (cvMaxAge < cAge4));

   // Expensive upgrade so make sure we're already progressed pretty far in the game.
   canDisableSelf &= ((researchSimpleTechByCondition(cTechdeBigStrongholdThunderbolts,
      []() -> bool {return ((kbGetAge() >= cAge4) && 
      (kbUnitCount(cMyID, cUnitTypedeIncaStronghold, cUnitStateABQ) >= 1) &&
      (kbGetPop() >= gMaxPop * 0.6)); },
      cUnitTypedeIncaStronghold)) ||
      (cvMaxAge < cAge4));

   if (canDisableSelf == true)
   {
      xsDisableSelf();
   }
}

//==============================================================================
// bigButtonLakotaMonitor
// This rule researches all the big button upgrades for the Lakota.
// Excluding the raiding parties, those are used as minutemen in useWarParties.
// We don't get Battle Anger since it's pretty expensive and our War Chief micro/macro isn't good enough.
//==============================================================================
rule bigButtonLakotaMonitor
inactive
mininterval 60
{
   if (kbUnitCount(cMyID, cUnitTypeAbstractVillager, cUnitStateAlive) < 20)
   {
      return; // Avoid getting upgrades here with a weak economy.
   }

   // Get the upgrade if we have 12 or more cavalry units.
   bool canDisableSelf = researchSimpleTechByCondition(cTechBigFarmHorsemanship,
      []() -> bool {return ((kbUnitCount(cMyID, cUnitTypeFarm, cUnitStateABQ) >= 1) &&
      (kbUnitCount(cMyID, cUnitTypeAbstractCavalry, cUnitStateABQ) >= 12)); },
      cUnitTypeFarm);

   // Get the upgrade if we see at least 2 enemy artillery, since we're Lakota we can assume we will train cavalry to counter
   // the artillery.
   canDisableSelf &= researchSimpleTechByCondition(cTechBigCorralBonepipeArmor,
      []() -> bool { return ((kbUnitCount(cMyID, cUnitTypeCorral, cUnitStateABQ) >= 1) &&
      (getUnitCountByLocation(cUnitTypeAbstractArtillery, cPlayerRelationEnemyNotGaia, cUnitStateAlive) >= 2)); },
      cUnitTypeCorral);

   // Get the upgrade if we have atleast 30 Villagers, still a low priority upgrade.
   canDisableSelf &= ((researchSimpleTechByCondition(cTechDEBigTribalMarketplaceCoopLakota,
      []() -> bool { return ((kbUnitCount(cMyID, cUnitTypedeFurTrade, cUnitStateABQ) >= 1) &&
      (kbUnitCount(cMyID, cUnitTypeAbstractVillager, cUnitStateABQ) >= 30)); },
      cUnitTypedeFurTrade, -1, 45)) ||
      (cvMaxAge < cAge3) || 
      (xsArrayGetInt(gTargetSettlerCounts, cvMaxAge) < 30));

   // Get the upgrade if we have atleast 3 War ships, lower priority upgrade just because it's naval.
   canDisableSelf &= ((researchSimpleTechByCondition(cTechBigDockFlamingArrows,
      []() -> bool { return ((kbUnitCount(cMyID, cUnitTypeDock, cUnitStateABQ) >= 1) &&
      (kbUnitCount(cMyID, cUnitTypeAbstractWarShip, cUnitStateABQ) >= 3)); },
      cUnitTypeDock, -1, 45)) ||
      (cvMaxAge < cAge3) || 
      (gNavyMap == false));

   // Just get the upgrade when in Fortress age, still a low priority upgrade.
   canDisableSelf &= ((researchSimpleTech(cTechBigWarHutWarDrums, cUnitTypeWarHut, -1, 45)) ||
      (cvMaxAge < cAge3));

   // Get the upgrade if we have at least 10 Rifle units.
   canDisableSelf &= ((researchSimpleTechByCondition(cTechBigPlantationGunTrade,
      []() -> bool { return ((kbUnitCount(cMyID, cUnitTypePlantation, cUnitStateABQ) >= 1) &&
      ((kbUnitCount(cMyID, cUnitTypexpWarRifle, cUnitStateABQ) +
      kbUnitCount(cMyID, cUnitTypexpRifleRider, cUnitStateABQ) >= 10))); },
      cUnitTypePlantation)) ||
      (cvMaxAge < cAge3));

   if (canDisableSelf == true)
   {
      xsDisableSelf();
   }
}

//==============================================================================
// bigButtonHaudenosauneeMonitor
// This rule researches all the big button upgrades for the Haudenosaunee.
// Excluding the raiding parties, those are used as minutemen in useWarParties.
// We don't get Secret Society since the AI has no real strategy for healing units and it will
// 	just lose its War Chief anyway and not retreat it to use it as a healer.
// We don't get Woodland Dwellers since we don't have a resource strategy to base this upgrade on.
// We don't get New Year Festival since the AI isn't particularly good at using shipments anyway.
// We don't get Strawberry Festival since we don't have a resource strategy to base this upgrade on.
// We don't get Maple Festival since we don't have a resource strategy to base this upgrade on.
//==============================================================================
rule bigButtonHaudenosauneeMonitor
inactive
mininterval 60
{
   if (kbUnitCount(cMyID, cUnitTypeAbstractVillager, cUnitStateAlive) < 20)
   {
      return; // Avoid getting upgrades here with a weak economy.
   }

   // Get the upgrade if we have 12 or more cavalry units.
   bool canDisableSelf = researchSimpleTechByCondition(cTechBigCorralHorseSecrets,
      []() -> bool { return ((kbUnitCount(cMyID, cUnitTypeCorral, cUnitStateABQ) >= 1) &&
      (kbUnitCount(cMyID, cUnitTypeAbstractCavalry, cUnitStateABQ) >= 12)); },
      cUnitTypeCorral);

   // Get the upgrade if we have 25 or more affected units or if 20 minutes have passed and we have 10 or more affected units,
   // it's a great upgrade so we kinda need it.
   int techStatus = kbTechGetStatus(cTechBigWarHutLacrosse);
   if (techStatus == cTechStatusObtainable)
   {
      int planID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechBigWarHutLacrosse);
      bool buildingAlive = kbUnitCount(cMyID, cUnitTypeWarHut, cUnitStateAlive) >= 1;
      int unitCount = kbUnitCount(cMyID, cUnitTypexpAenna, cUnitStateAlive) +
                      kbUnitCount(cMyID, cUnitTypexpTomahawk, cUnitStateAlive) +
                      kbUnitCount(cMyID, cUnitTypexpMusketWarrior, cUnitStateAlive);
      if (planID >= 0)
      {
         if ((buildingAlive == false) || (unitCount < 10))
         {
            aiPlanDestroy(planID);
         }
      }
      else if ((buildingAlive == true) && ((unitCount >= 25) || ((xsGetTime() >= 20 * 60 * 1000) && (unitCount >= 10))))
      {
         createSimpleResearchPlan(cTechBigWarHutLacrosse, cUnitTypeWarHut);
      }
   }
   canDisableSelf &= techStatus == cTechStatusActive;

   // Get the upgrade if we have atleast 30 Villagers, still a low priority upgrade.
   canDisableSelf &= ((researchSimpleTechByCondition(cTechDEBigTribalMarketplaceCoopHaudenosaunee,
      []() -> bool { return ((kbUnitCount(cMyID, cUnitTypedeFurTrade, cUnitStateABQ) >= 1) &&
      (kbUnitCount(cMyID, cUnitTypeAbstractVillager, cUnitStateABQ) >= 30)); },
      cUnitTypedeFurTrade, -1, 45)) ||
      (cvMaxAge < cAge3) || 
      (xsArrayGetInt(gTargetSettlerCounts, cvMaxAge) < 30));

   // Get the upgrade if we have atleast 3 War ships, lower priority upgrade just because it's naval.
   canDisableSelf &= ((researchSimpleTechByCondition(cTechBigDockRawhideCovers,
      []() -> bool { return ((kbUnitCount(cMyID, cUnitTypeDock, cUnitStateABQ) >= 1) &&
      (kbUnitCount(cMyID, cUnitTypeAbstractWarShip, cUnitStateABQ) >= 3)); },
      cUnitTypeDock, -1, 45)) ||
      (cvMaxAge < cAge3) ||
      (gNavyMap == false));

   // Get this upgrade later in the game since it's not that good.
   canDisableSelf &= ((researchSimpleTechByCondition(cTechBigSiegeshopSiegeDrill,
      []() -> bool { return ((kbUnitCount(cMyID, cUnitTypeArtilleryDepot, cUnitStateABQ) >= 1) &&
      (kbUnitCount(cMyID, cUnitTypexpRam, cUnitStateABQ) +
      kbUnitCount(cMyID, cUnitTypexpMantlet, cUnitStateABQ) +
      kbUnitCount(cMyID, cUnitTypexpLightCannon, cUnitStateABQ) >= 8)); },
      cUnitTypeArtilleryDepot)) ||
      (cvMaxAge < cAge4));

   if (canDisableSelf == true)
   {
      xsDisableSelf();
   }
}

rule tamboUpgradeMonitor
inactive
minInterval 90
{
   bool canDisableSelf = researchSimpleTechByCondition(cTechdeMightyTambos,
      []() -> bool { return (kbUnitCount(cMyID, cUnitTypeTradingPost, cUnitStateABQ) >= 2); },
      cUnitTypeTradingPost);
   
   if (canDisableSelf == true)
   {
      xsDisableSelf();
   }
}

rule strongholdUpgradeMonitor
inactive
minInterval 75
{
   bool canDisableSelf = researchSimpleTechByCondition(cTechdePukaras,
      []() -> bool { return (kbUnitCount(cMyID, cUnitTypedeIncaStronghold, cUnitStateAlive) +
      kbUnitCount(cMyID, cUnitTypeWarHut, cUnitStateABQ) +
      kbUnitCount(cMyID, cUnitTypeTradingPost, cUnitStateABQ) >= 3); },
      cUnitTypedeIncaStronghold);

   if (cDifficultyCurrent >= cDifficultyHard)
   {
      canDisableSelf &= researchSimpleTechByCondition(cTechdeSacsayhuaman,
         []() -> bool { return (kbUnitCount(cMyID, cUnitTypedeIncaStronghold, cUnitStateAlive) >= 3); },
         cUnitTypedeIncaStronghold);
   }

   if (canDisableSelf == true)
   {
      xsDisableSelf();
   }
}

//==============================================================================
// monasteryUpgradeMonitor
//==============================================================================
rule monasteryUpgradeMonitor
inactive
minInterval 60
{
   // If we don't have a Monastery alive we are done here.
   int monasteryID = getUnit(cUnitTypeypMonastery, cMyID);
   if (monasteryID < 0)
   {
      return;
   }

   bool canDisableSelf = true;

   // We don't get the 2 upgrades to increase the strength of the Monk because we have no micro for him.
   if ((cMyCiv == cCivChinese) || (cMyCiv == cCivSPCChinese))
   {
      canDisableSelf = researchSimpleTechByCondition(cTechypMonasteryDiscipleAura,
         []() -> bool { return (kbUnitCount(cMyID, cUnitTypeypMonkDisciple, cUnitStateABQ) >= 8); },
         -1, monasteryID);

      canDisableSelf &= researchSimpleTechByCondition(cTechypMonasteryShaolinWarrior,
         []() -> bool { return (kbUnitCount(cMyID, cUnitTypeypMonkDisciple, cUnitStateABQ) >= 8); },
         -1, monasteryID);
   }

   // We don't get the Tiger because that is just wasting resources for us.
   // We don't get the healing upgrade because we have no logic to use the Monks as healers and not lose them.
   // We don't get Crushing Force because we don't micro the Monks and will probably lose them.
   else if ((cMyCiv == cCivIndians) || (cMyCiv == cCivSPCIndians))
   {
      canDisableSelf = researchSimpleTechByCondition(cTechypMonasteryIndianSpeed,
         []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractCavalry, cUnitStateABQ) >= 15); },
         -1, monasteryID);
   }

   // else // We are Japanese.
   //{
   // We don't get anything from the Japanese because all their upgrades are about improving the Monks.
   //}

   if (canDisableSelf == true)
   {
      xsDisableSelf();
   }
}

//==============================================================================
// chooseConsulateFlag
//==============================================================================
void chooseConsulateFlag(int consulateID = -1)
{
   int consulatePlanID = -1;
   int randomizer = aiRandInt(100); // 0-99
   int flag_button_id = -1;
   int upgradePlanID = -1;
   int sequesterPlanID = -1;
   // Chinese options: British, Russians, French (HC level >= 25) & Germans (HC level >= 40)
   // Choice biased towards Russians
      if (kbGetAge() >= cAge1)
   {
   if ((cMyCiv == cCivChinese) || (cMyCiv == cCivSPCChinese))
   {
	   flag_button_id = cTechypBigConsulateFrench;
			if (kbTechGetStatus(cTechypBigConsulateFrench) == cTechStatusActive)
	   {
       if ((kbTechGetStatus(cTechypConsulateFrenchWoodCrates) == cTechStatusObtainable) ||
	   (kbTechGetStatus(cTechypConsulateFrenchCoinCrates) == cTechStatusObtainable) ||
       (kbTechGetStatus(cTechypConsulateFrenchFoodCrates) == cTechStatusObtainable))
	   return;
	   else
	   {
      createSimpleResearchPlan(cTechypBigSequester, getUnit(cUnitTypeypConsulate), cEconomyEscrowID, 50);
      upgradePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechypBigSequesterFrench);
      if (upgradePlanID >= 0)
         aiPlanDestroy(upgradePlanID);
      createSimpleResearchPlan(cTechypBigSequesterFrench, getUnit(cUnitTypeypConsulate), cEconomyEscrowID, 50);
	  sequesterPlanID = researchSimpleTech(cTechypBigSequester, -1, consulateID);
	  sequesterPlanID = researchSimpleTech(cTechypBigSequesterFrench, -1, consulateID);
	  flag_button_id = cTechypBigConsulateGermans;
		}
	   }
			if (kbTechGetStatus(cTechypBigConsulateGermans) == cTechStatusActive)
	   {
		if ((kbTechGetStatus(cTechypConsulateGermansFoodTrickle) == cTechStatusObtainable) ||
	   (kbTechGetStatus(cTechypConsulateGermansWoodTrickle) == cTechStatusObtainable) ||
       (kbTechGetStatus(cTechypConsulateGermansCoinTrickle) == cTechStatusObtainable))
	   return;
	   else
	   {
      createSimpleResearchPlan(cTechypBigSequester, getUnit(cUnitTypeypConsulate), cEconomyEscrowID, 50);
      upgradePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechypBigSequesterGermans);
      if (upgradePlanID >= 0)
         aiPlanDestroy(upgradePlanID);
      createSimpleResearchPlan(cTechypBigSequesterGermans, getUnit(cUnitTypeypConsulate), cEconomyEscrowID, 50);
	  sequesterPlanID = researchSimpleTech(cTechypBigSequester, -1, consulateID);
	  sequesterPlanID = researchSimpleTech(cTechypBigSequesterGermans, -1, consulateID);
	   flag_button_id = cTechypBigConsulateRussians;
		}
	   }
			if (kbTechGetStatus(cTechypBigConsulateRussians) == cTechStatusActive)
	   {
	   if ((kbTechGetStatus(cTechypConsulateRussianFortWagon) == cTechStatusObtainable) ||
	   (kbTechGetStatus(cTechypConsulateRussianFactoryWagon) == cTechStatusObtainable) ||
       (kbTechGetStatus(cTechypConsulateRussianOutpostWagon) == cTechStatusObtainable))
	   return;
       else
		{
      createSimpleResearchPlan(cTechypBigSequester, getUnit(cUnitTypeypConsulate), cEconomyEscrowID, 50);
      upgradePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechypBigSequesterRussians);
      if (upgradePlanID >= 0)
         aiPlanDestroy(upgradePlanID);
      createSimpleResearchPlan(cTechypBigSequesterRussians, getUnit(cUnitTypeypConsulate), cEconomyEscrowID, 50);
	  sequesterPlanID = researchSimpleTech(cTechypBigSequester, -1, consulateID);
	  sequesterPlanID = researchSimpleTech(cTechypBigSequesterRussians, -1, consulateID);
       flag_button_id = cTechypBigConsulateBritish;
		}
	   }
   }
   if ((cMyCiv == cCivIndians) || (cMyCiv == cCivSPCIndians))
   {
	   /*
	   if (kbUnitCount(cMyID, cUnitTypeHomeCityWaterSpawnFlag) > 0)
      {
       flag_button_id = cTechypBigConsulatePortuguese;
			if (kbTechGetStatus(cTechypBigConsulatePortuguese) == cTechStatusActive)
	   {
	   if (kbTechGetStatus(cTechypConsulatePortugueseFishingFleet) == cTechStatusObtainable)
       return;
	   else
	   {
      createSimpleResearchPlan(cTechypBigSequester, getUnit(cUnitTypeypConsulate), cEconomyEscrowID, 50);
      upgradePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechypBigSequesterPortuguese);
      if (upgradePlanID >= 0)
         aiPlanDestroy(upgradePlanID);
      createSimpleResearchPlan(cTechypBigSequesterPortuguese, getUnit(cUnitTypeypConsulate), cEconomyEscrowID, 50);
	  flag_button_id = cTechypBigConsulateOttomans;
		}
	  }
	  }
	  else
		  */
	   flag_button_id = cTechypBigConsulateOttomans;
			if (kbTechGetStatus(cTechypBigConsulateOttomans) == cTechStatusActive)
	   {
       if (kbTechGetStatus(cTechypConsulateOttomansInfantrySpeed) == cTechStatusObtainable)
	   return;
	   else
	   {
      createSimpleResearchPlan(cTechypBigSequester, getUnit(cUnitTypeypConsulate), cEconomyEscrowID, 50);
      upgradePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechypBigSequesterOttomans);
      if (upgradePlanID >= 0)
         aiPlanDestroy(upgradePlanID);
      createSimpleResearchPlan(cTechypBigSequesterOttomans, getUnit(cUnitTypeypConsulate), cEconomyEscrowID, 50);
	  sequesterPlanID = researchSimpleTech(cTechypBigSequester, -1, consulateID);
	  sequesterPlanID = researchSimpleTech(cTechypBigSequesterOttomans, -1, consulateID);
	  flag_button_id = cTechypBigConsulateFrench;
		}
	   }
			if (kbTechGetStatus(cTechypBigConsulateFrench) == cTechStatusActive)
	   {
       if ((kbTechGetStatus(cTechypConsulateFrenchWoodCrates) == cTechStatusObtainable) ||
	   (kbTechGetStatus(cTechypConsulateFrenchCoinCrates) == cTechStatusObtainable) ||
       (kbTechGetStatus(cTechypConsulateFrenchFoodCrates) == cTechStatusObtainable))
	   return;
	   else
	   {
      createSimpleResearchPlan(cTechypBigSequester, getUnit(cUnitTypeypConsulate), cEconomyEscrowID, 50);
      upgradePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechypBigSequesterFrench);
      if (upgradePlanID >= 0)
         aiPlanDestroy(upgradePlanID);
      createSimpleResearchPlan(cTechypBigSequesterFrench, getUnit(cUnitTypeypConsulate), cEconomyEscrowID, 50);
	  sequesterPlanID = researchSimpleTech(cTechypBigSequester, -1, consulateID);
	  sequesterPlanID = researchSimpleTech(cTechypBigSequesterFrench, -1, consulateID);
	  flag_button_id = cTechypBigConsulateBritish;
		}
	   }
   }
   if ((cMyCiv == cCivJapanese) || (cMyCiv == cCivSPCJapanese))
   {
	   /*
	  if (kbUnitCount(cMyID, cUnitTypeHomeCityWaterSpawnFlag) > 0)
      {
       flag_button_id = cTechypBigConsulatePortuguese;
			if (kbTechGetStatus(cTechypBigConsulatePortuguese) == cTechStatusActive)
	   {
	   if (kbTechGetStatus(cTechypConsulatePortugueseFishingFleet) == cTechStatusObtainable)
       return;
	   else
	   {
      createSimpleResearchPlan(cTechypBigSequester, getUnit(cUnitTypeypConsulate), cEconomyEscrowID, 50);
      upgradePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechypBigSequesterPortuguese);
      if (upgradePlanID >= 0)
         aiPlanDestroy(upgradePlanID);
      createSimpleResearchPlan(cTechypBigSequesterPortuguese, getUnit(cUnitTypeypConsulate), cEconomyEscrowID, 50);
	  flag_button_id = cTechypBigConsulateSpanish;
		}
	  }
	  }
	  else
		  */
	   flag_button_id = cTechypBigConsulateSpanish;
			if (kbTechGetStatus(cTechypBigConsulateSpanish) == cTechStatusActive)
	   {
			if ((kbTechGetStatus(cTechypConsulateSpanishFasterShipments) == cTechStatusObtainable) ||
	   (kbTechGetStatus(cTechypConsulateSpanishMercantilism) == cTechStatusObtainable) ||
       (kbTechGetStatus(cTechypConsulateSpanishEnhancedProfits) == cTechStatusObtainable))
	   return;
	   else
	   {
      createSimpleResearchPlan(cTechypBigSequester, getUnit(cUnitTypeypConsulate), cEconomyEscrowID, 50);
      upgradePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechypBigSequesterSpanish);
      if (upgradePlanID >= 0)
         aiPlanDestroy(upgradePlanID);
      createSimpleResearchPlan(cTechypBigSequesterSpanish, getUnit(cUnitTypeypConsulate), cEconomyEscrowID, 50);
	  sequesterPlanID = researchSimpleTech(cTechypBigSequester, -1, consulateID);
	  sequesterPlanID = researchSimpleTech(cTechypBigSequesterSpanish, -1, consulateID);
	  flag_button_id = cTechypBigConsulateDutch;
		}
	   }
			if (kbTechGetStatus(cTechypBigConsulateDutch) == cTechStatusActive)
	   {
	   if ((kbTechGetStatus(cTechypConsulateDutchArsenalWagon) == cTechStatusObtainable) ||
	   (kbTechGetStatus(cTechypConsulateDutchSaloonWagon) == cTechStatusObtainable) ||
	   (kbTechGetStatus(cTechypConsulateDutchLivestockPenWagon) == cTechStatusObtainable) ||
       (kbTechGetStatus(cTechypConsulateDutchChurchWagon) == cTechStatusObtainable))
	   return;
	   else
	   {
      createSimpleResearchPlan(cTechypBigSequester, getUnit(cUnitTypeypConsulate), cEconomyEscrowID, 50);
      upgradePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechypBigSequesterDutch);
      if (upgradePlanID >= 0)
         aiPlanDestroy(upgradePlanID);
      createSimpleResearchPlan(cTechypBigSequesterDutch, getUnit(cUnitTypeypConsulate), cEconomyEscrowID, 50);
	  sequesterPlanID = researchSimpleTech(cTechypBigSequester, -1, consulateID);
	  sequesterPlanID = researchSimpleTech(cTechypBigSequesterDutch, -1, consulateID);
	  flag_button_id = cTechypBigConsulateJapanese;
		}
	   }
   }
      gConsulateFlagTechID = flag_button_id;
   }
   if (kbTechGetStatus(gConsulateFlagTechID) == cTechStatusObtainable)
   {
      consulatePlanID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, gConsulateFlagTechID);
      if (consulatePlanID < 0)
      {
         aiEcho("************Consulate Flag************");
         aiEcho("Our Consulate flag is: " + kbGetTechName(gConsulateFlagTechID));
         aiEcho("Randomizer value: " + randomizer);
         consulatePlanID = createSimpleResearchPlanSpecificBuilding(gConsulateFlagTechID, consulateID, cEconomyEscrowID, 40);
         aiPlanSetEventHandler(consulatePlanID, cPlanEventStateChange, "consulateFlagHandler");
      }
   }
}

void consulateFlagHandler(int planID = -1)
{
   if (aiPlanGetState(planID) == -1)
   {
      // Done.
      if (kbTechGetStatus(gConsulateFlagTechID) == cTechStatusActive)
      {
         gConsulateFlagChosen = true;
      }
   }
}

void russianFortHandler(int planID = -1)
{
   if (aiPlanGetState(planID) == -1)
   {
      // Done.
      if (kbTechGetStatus(cTechypConsulateRussianFortWagon) == cTechStatusActive)
      {
         forwardBaseManager(); // Handle the Fort Wagon.
      }
   }
}

//==============================================================================
/* BHG Consulate monitor

   Make sure we have a Consulate around.
   Research Consulate Techs as appropriate.

*/
//==============================================================================
rule consulateMonitor
inactive
minInterval 15
{
   int consulateID = getUnit(cUnitTypeypConsulate, cMyID, cUnitStateAlive);
   //if (consulateID < 0)
   //{
   //   return;
   //}
   // If no option has been chosen already, choose one now
   
   if (civIsAsian() == false)
   {
      xsDisableSelf();
      return;
   }

   // Quit if consulate is not allowed and not already built
   if ((cvOkToBuildConsulate == false) && (kbUnitCount(cMyID, cUnitTypeypConsulate, cUnitStateABQ) == 0))
   {
      return;
   }
   
   if ((kbTechGetStatus(cTechypBigConsulateBritish) != cTechStatusActive) ||
   (kbTechGetStatus(cTechypBigConsulateJapanese) != cTechStatusActive))
   {
      chooseConsulateFlag(consulateID);
   }
   // Maximize export generation in Age 4 and above
   if (kbGetAge() >= cAge4 && aiUnitGetTactic(consulateID) != cTacticTax10)
   {
      // Set export gathering rate to +60 %
      aiUnitSetTactic(consulateID, cTacticTax10);
   }
   static bool allTechsActive = false;
   bool isTechActive = false;
   if (allTechsActive == false)
   {
      switch(gConsulateFlagTechID)
      {
      case cTechypBigConsulateBritish:
      {
         // TODO: settlers.
         allTechsActive = researchSimpleTech(cTechypConsulateBritishRedcoats, -1, consulateID);
		 allTechsActive = researchSimpleTech(cTechypConsulateBritishRogersRangers, -1, consulateID);
         allTechsActive = researchSimpleTech(cTechypConsulateBritishLifeGuards, -1, consulateID);
		 allTechsActive = researchSimpleTech(cTechypConsulateBritishBrigade, -1, consulateID);
         break;
      }
      case cTechypBigConsulateDutch:
      {
         allTechsActive = researchSimpleTech(cTechypConsulateDutchSaloonWagon, -1, consulateID);
         allTechsActive = researchSimpleTech(cTechypConsulateDutchArsenalWagon, -1, consulateID);
         allTechsActive = researchSimpleTech(cTechypConsulateDutchChurchWagon, -1, consulateID);
         allTechsActive = researchSimpleTech(cTechypConsulateDutchLivestockPenWagon, -1, consulateID);
         //allTechsActive = researchSimpleTech(cTechypConsulateDutchBrigade, -1, consulateID);
		 if (researchSimpleTech(cTechypConsulateDutchArsenalWagon, -1, consulateID) == true)
         {
			 xsEnableRule("ShrineGoatMonitor");
         }
         if (researchSimpleTech(cTechypConsulateDutchArsenalWagon, -1, consulateID) == true)
         {
            xsEnableRule("arsenalUpgradeMonitor");
			xsEnableRule("arsenalUpgradeAsianMonitor");
         }/*
         else
         {
            allTechsActive = false;
         }
		 */
         if (researchSimpleTech(cTechypConsulateDutchChurchWagon, -1, consulateID) == true)
         {
            xsEnableRule("churchUpgradeMonitor");
			xsEnableRule("churchUpgradeAsianMonitor");
         }/*
         else
         {
            allTechsActive = false;
         }*/
         break;
      }
      case cTechypBigConsulateFrench:
      {
         // TODO: resource crates.
         allTechsActive = researchSimpleTech(cTechypConsulateFrenchWoodCrates, -1, consulateID);
		 allTechsActive = researchSimpleTech(cTechypConsulateFrenchCoinCrates, -1, consulateID);
         allTechsActive = researchSimpleTech(cTechypConsulateFrenchFoodCrates, -1, consulateID);
		 //allTechsActive = researchSimpleTech(cTechypConsulateFrenchBrigade, -1, consulateID);
         break;
      }
      case cTechypBigConsulateGermans:
      {
         // TODO: trickles.
         allTechsActive = researchSimpleTech(cTechypConsulateGermansFoodTrickle, -1, consulateID);
		 allTechsActive = researchSimpleTech(cTechypConsulateGermansWoodTrickle, -1, consulateID);
         allTechsActive = researchSimpleTech(cTechypConsulateGermansCoinTrickle, -1, consulateID);
		 //allTechsActive = researchSimpleTech(cTechypConsulateGermansBrigade, -1, consulateID);
         break;
      }
      case cTechypBigConsulateJapanese:
      {
         // (Clan offerings)
         // ypConsulateJapaneseKoujou - spawn samurai at each castle, pretty useless most of the time.
         // Allow training units in a batch of 10.
         allTechsActive = researchSimpleTech(cTechypConsulateJapaneseMasterTraining, -1, consulateID);
         allTechsActive = researchSimpleTech(cTechypConsulateJapaneseMilitaryRickshaw, -1, consulateID);
         break;
      }
      case cTechypBigConsulateOttomans:
      {
         // (Great bombards)
         allTechsActive = researchSimpleTech(cTechypConsulateOttomansGunpowderSiege, -1, consulateID);
		 allTechsActive = researchSimpleTech(cTechypConsulateOttomansInfantrySpeed, -1, consulateID);
		 //allTechsActive = researchSimpleTech(cTechypConsulateOttomansBrigade, -1, consulateID);
         break;
      }
      case cTechypBigConsulatePortuguese:
      {
         // (Ironclad)
         if (gHaveWaterSpawnFlag == true)
         {
            allTechsActive = researchSimpleTech(cTechypConsulatePortugueseExpeditionaryFleet, -1, consulateID);
            allTechsActive = researchSimpleTech(cTechypConsulatePortugueseFishingFleet, -1, consulateID);
            //allTechsActive = researchSimpleTech(cTechypConsulatePortugueseBrigade, -1, consulateID);
         }
         else
         {
            allTechsActive = true;
         }
         break;
      }
      /*case cTechypBigConsulateOttomans:
      {
         // (Great bombards)
         allTechsActive = researchSimpleTech(cTechypConsulateOttomansGunpowderSiege, -1, consulateID);
         break;
      }*/
      case cTechypBigConsulateRussians:
      {
         // (blockhouse wagon)
         allTechsActive = researchSimpleTech(cTechypConsulateRussianOutpostWagon, -1, consulateID);
		 allTechsActive = researchSimpleTech(cTechypConsulateRussianFortWagon, -1, consulateID);
         allTechsActive = researchSimpleTech(cTechypConsulateRussianFactoryWagon, -1, consulateID);
		 //allTechsActive = researchSimpleTech(cTechypConsulateRussianBrigade, -1, consulateID);
         break;
      }
      case cTechypBigConsulateSpanish:
      {
         allTechsActive = researchSimpleTech(cTechypConsulateSpanishMercantilism, -1, consulateID);
		 allTechsActive = researchSimpleTech(cTechypConsulateSpanishFasterShipments, -1, consulateID);
         allTechsActive = researchSimpleTech(cTechypConsulateSpanishEnhancedProfits, -1, consulateID);
		 //allTechsActive = researchSimpleTech(cTechypConsulateSpanishBrigade, -1, consulateID);
         break;
      }
      }
   }
   if (cvOkToTrainArmy == false)
      return;
   // Maintain plans
   static int consulateUPID = -1;
   static int consulateMaintainPlans = -1;
   if (consulateUPID < 0)
   {
      // Create it.
      consulateUPID = kbUnitPickCreate("Consulate army");
      if (consulateUPID < 0)
         return;
      consulateMaintainPlans = xsArrayCreateInt(4, -1, "Consulate maintain plans");
   }
   bool homeBaseUnderAttack = false;
   if (gDefenseReflexBaseID == kbBaseGetMainID(cMyID))
      homeBaseUnderAttack = true;
  if ((homeBaseUnderAttack == true) || (kbGetAge() > cAge3))
  {
   int numberResults = 0;
   int trainUnitID = -1;
   int planID = -1;
   int numberToMaintain = 0;
   int mainBaseID = kbBaseGetMainID(cMyID);
   // Default init.
   kbUnitPickResetAll(consulateUPID);
   // Desired number units types, buildings.
   kbUnitPickSetDesiredNumberUnitTypes(consulateUPID, 2, 1, true);
   //setUnitPickerCommon(consulateUPID);
   kbUnitPickSetMinimumCounterModePop(consulateUPID, 15);
   //kbUnitPickSetPreferenceFactor(consulateUPID, cUnitTypeAbstractConsulateSiegeFortress, 0.50);
   //kbUnitPickSetPreferenceFactor(consulateUPID, cUnitTypeAbstractConsulateSiegeIndustrial, 2.0);
   kbUnitPickSetPreferenceFactor(consulateUPID, cUnitTypeAbstractConsulateUnit, 1.0);
   if (kbGetAge() == cAge2)
   kbUnitPickSetPreferenceFactor(consulateUPID, cUnitTypeAbstractConsulateUnitColonial, 1.0);
   else
   kbUnitPickSetPreferenceFactor(consulateUPID, cUnitTypeAbstractConsulateUnitColonial, 0.0);
   if (kbGetAge() == cAge3)
   kbUnitPickSetPreferenceFactor(consulateUPID, cUnitTypeAbstractConsulateSiegeFortress, 1.0);
   else
   kbUnitPickSetPreferenceFactor(consulateUPID, cUnitTypeAbstractConsulateSiegeFortress, 0.0);
   if (kbGetAge() >= cAge4)
   kbUnitPickSetPreferenceFactor(consulateUPID, cUnitTypeAbstractConsulateSiegeIndustrial, 1.0);
   // Banner armies are calculated with a weighed average of unit types the banner army contains
   kbUnitPickRemovePreferenceFactor(consulateUPID, cUnitTypeAbstractBannerArmy);
   kbUnitPickRun(consulateUPID);
   for (i = 0; < 2)
   {
      trainUnitID = kbUnitPickGetResult(consulateUPID, i);
      planID = xsArrayGetInt(consulateMaintainPlans, i);
      if (planID >= 0)
      {
         if (trainUnitID == aiPlanGetVariableInt(planID, cTrainPlanUnitType, 0))
         {
            numberToMaintain = kbResourceGet(cResourceTrade) / kbUnitCostPerResource(trainUnitID, cResourceTrade);
            aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, numberToMaintain);
            continue;
         }
         aiPlanDestroy(planID);
      }
      if (trainUnitID < 0)
         continue;
      numberToMaintain = kbResourceGet(cResourceTrade) / kbUnitCostPerResource(trainUnitID, cResourceTrade);
      planID = createSimpleMaintainPlan(trainUnitID, numberToMaintain, false, mainBaseID, 1);
      aiPlanSetDesiredResourcePriority(planID, 50 - i); // below research plans
      xsArraySetInt(consulateMaintainPlans, i, planID);
   }
  }
}

rule agraFortUpgradeMonitor
inactive
minInterval 90
{
   // Check for the Agra Fort, if we don't find one we've lost it and we can disable this Rule.
   int agraFortID = getUnit(gAgraFortPUID);
   if (agraFortID < 0)
   {
      xsDisableSelf();
      return;
   }

   bool canDisableSelf = researchSimpleTech(cTechypFrontierAgra, -1, agraFortID);
   
   if (cDifficultyCurrent >= cDifficultyModerate)
   {
      canDisableSelf &= researchSimpleTech(cTechypFortifiedAgra, -1, agraFortID);
   }
   
   if (canDisableSelf == true)
   {
      xsDisableSelf();
   }
}

rule shrineUpgradeMonitor
inactive
minInterval 60
{
   // Disable Rule once the upgrade is active.
   if (kbTechGetStatus(cTechypShrineFortressUpgrade) == cTechStatusActive)
   {
      xsDisableSelf();
      return;
   }
   int treshold = 15;
   int toshoguShrineID = getUnit(gToshoguShrinePUID);
   // Check for the Toshogu Shrine, this building boosts our Shrines so can have a lower treshold.
   if (toshoguShrineID >= 0)
   {
      treshold = 10;
   }
   
   int shrineCount = kbUnitCount(cMyID, cUnitTypeypShrineJapanese, cUnitStateABQ);

   int planID = aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechypShrineFortressUpgrade);
   if (planID >= 0)
   {
      if (shrineCount < treshold)
      {
         aiPlanDestroy(planID);
      }
   }
   else
   {
      if (shrineCount >= treshold)
      {
         researchSimpleTech(cTechypShrineFortressUpgrade, cUnitTypeypShrineJapanese);
      }
   }
}

//==============================================================================
// allianceUpgradeMonitor
//
// Researches upgrades gained via alliances for the African civilizations.
// Also researches 2 upgrades which are baseline inside the University / Mountain Monastery.
//
//==============================================================================
rule allianceUpgradeMonitor
inactive
minInterval 45
{
   int age = kbGetAge();
   // If all the values in the bool array are set to true it means we can disable this rule, but first make sure we actually
   // can't research any more Alliances.
   if (age == cvMaxAge)
   {
      bool canDisableSelf = true;
      for (i = cAge1; < cvMaxAge + 1)
      {
         if (xsArrayGetBool(gAfricanAlliancesUpgrades, i) == false)
         {
            canDisableSelf = false;
         }
      }
      if ((cMyCiv == cCivDEEthiopians) &&
          ((kbTechGetStatus(cTechDESolomonicDynasty) != cTechStatusActive) && (cvMaxAge >= cAge4)))
      {
         canDisableSelf = false;
      }
      if (canDisableSelf == true)
      {
         xsDisableSelf();
      }
   }
   
   bool bothTechsActive = false;
   if (cMyCiv == cCivDEHausa)
   {
      // Quit if we have no University.
      int universityID = getUnit(cUnitTypedeUniversity, cMyID);
      if (universityID < 0)
      {
         return;
      }
      
      if (age != cvMaxAge)
      {
         // Give the AI some space to get it in time.
         researchSimpleTechByCondition(cTechDETimbuktuManuscripts,
            []() -> bool { return (kbGetTechPercentComplete(gAgeUpResearchPlan) < 5); },
            -1, universityID, 99);
      }

      if (xsArrayGetBool(gAfricanAlliancesUpgrades, cAllianceBerbersIndex) == false)
      {
         if ((researchSimpleTechByCondition(cTechDENatBerberDesertKings,
            []() -> bool { return (kbUnitCount(cMyID, gEconUnit, cUnitStateABQ) >= 30); },
            -1, universityID) || 
            (xsArrayGetInt(gTargetSettlerCounts, cvMaxAge) < 30)) == true)
         {
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceBerbersIndex, true);
         }
      }

      if (xsArrayGetBool(gAfricanAlliancesUpgrades, cAllianceHausaIndex) == false)
      {
         bothTechsActive = researchSimpleTech(cTechDEAllegianceHausaKanoChronicle, -1, universityID);
         
         bothTechsActive &= researchSimpleTech(cTechDEAllegianceHausaArewa, -1, universityID);

         if (bothTechsActive == true)
         {
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceHausaIndex, true);
         }
      }

      if (xsArrayGetBool(gAfricanAlliancesUpgrades, cAllianceSonghaiIndex) == false)
      {
         bothTechsActive = researchSimpleTech(cTechDEAllegianceSonghaiTimbuktuChronicle, -1, universityID);
         
         bothTechsActive &= researchSimpleTechByCondition(cTechDEAllegianceSonghaiMansaMusaEpic,
            []() -> bool { return (kbTechGetHCCardValuePerResource(cTechDEAllegianceSonghaiMansaMusaEpic, cResourceGold)
            >= 1000); }, -1, universityID);
            
         if (bothTechsActive == true)
         {
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceHausaIndex, true);
         }
      }

      if (xsArrayGetBool(gAfricanAlliancesUpgrades, cAllianceAkanIndex) == false)
      {
         if (researchSimpleTech(cTechDENatAkanGoldEconomy, -1, universityID) == true)
         {
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceAkanIndex, true);
         }
      }
   }
   else // Ethiopia.
   {
      int mountainMonasteryID = getUnit(cUnitTypedeMountainMonastery, cMyID);
      if (mountainMonasteryID < 0)
      {
         return;
      }
      
      if (age != cvMaxAge)
      {
         // Give the AI some space to get it in time.
         researchSimpleTechByCondition(cTechDEAxumChronicle,
            []() -> bool { return (kbGetTechPercentComplete(gAgeUpResearchPlan) < 5); },
            -1, mountainMonasteryID, 99);
      }
      
      researchSimpleTech(cTechDESolomonicDynasty, -1, mountainMonasteryID);

      if (xsArrayGetBool(gAfricanAlliancesUpgrades, cAllianceSomalisIndex) == false)
      {
         bothTechsActive = researchSimpleTechByCondition(cTechDENatSomaliCoinage,
            []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractVillager, cUnitStateABQ) >= 30); },
            -1, mountainMonasteryID) ||
            (xsArrayGetInt(gTargetSettlerCounts, cvMaxAge) < 30) || (gTimeForPlantations == true);
         
         if (gHaveWaterSpawnFlag == true)
         {
            bothTechsActive &= researchSimpleTech(cTechDENatSomaliBerberaSeaport, -1, mountainMonasteryID);
         }
          
         if (bothTechsActive == true)
         {
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceSomalisIndex, true);
         }  
      }

      if (xsArrayGetBool(gAfricanAlliancesUpgrades, cAlliancePortugueseIndex) == false)
      {
         bothTechsActive = researchSimpleTech(cTechDEAllegiancePortugueseCrusaders, -1, mountainMonasteryID);
         
         bothTechsActive &= researchSimpleTechByCondition(cTechDEAllegiancePortugueseOrgans,
            []() -> bool { return (kbUnitCount(cMyID, cUnitTypedeMountainMonastery, cUnitStateAlive) >= 3); },
            -1, mountainMonasteryID);
         
         if (bothTechsActive == true)
         {
            xsArraySetBool(gAfricanAlliancesUpgrades, cAlliancePortugueseIndex, true);
         }  
      }
      
      if (xsArrayGetBool(gAfricanAlliancesUpgrades, cAllianceSudaneseIndex) == false)
      {
         bothTechsActive = researchSimpleTech(cTechDENatSudaneseRedSeaTrade, -1, mountainMonasteryID);
         
         bothTechsActive &= researchSimpleTechByCondition(cTechDENatSudaneseQuiltedArmor,
            []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractCavalry, cUnitStateAlive) +
            kbUnitCount(cMyID, cUnitTypeAbstractLightInfantry, cUnitStateAlive) >= 12); },
            -1, mountainMonasteryID);
         
         if (bothTechsActive == true)
         {
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceSudaneseIndex, true);
         } 
      }
      
      if (xsArrayGetBool(gAfricanAlliancesUpgrades, cAllianceJesuitIndex) == false)
      {
         bothTechsActive = researchSimpleTech(cTechYPNatJesuitSchools, -1, mountainMonasteryID);
         
         bothTechsActive &= researchSimpleTechByCondition(cTechYPNatJesuitSmokelessPowder,
            []() -> bool { return (kbUnitCount(cMyID, cUnitTypeAbstractGunpowderTrooper, cUnitStateAlive) +
            kbUnitCount(cMyID, cUnitTypeAbstractArtillery, cUnitStateAlive) >= 15); },
            -1, mountainMonasteryID);
         
         if (bothTechsActive == true)
         {
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceJesuitIndex, true);
         }  
      }

      if (xsArrayGetBool(gAfricanAlliancesUpgrades, cAllianceOromoIndex) == false)
      {
         if (researchSimpleTech(cTechDEAllegianceOromoUnits, -1, mountainMonasteryID) == true)
         {
            xsArraySetBool(gAfricanAlliancesUpgrades, cAllianceOromoIndex, true);
         }  
      }
   }
}

/*

rule fortUpgradeMonitor
inactive
minInterval 90
{
   // Quit if there is no alive Fort.
   if (kbUnitCount(cMyID, cUnitTypeFortFrontier, cUnitStateAlive) < 1)
   {
      return;
   }
   
   bool canDisableSelf = researchSimpleTech(cTechRevetment, cUnitTypeFortFrontier);
   
   canDisableSelf &= researchSimpleTech(cTechStarFort, cUnitTypeFortFrontier);
   
   if (canDisableSelf == true)
   {
      xsDisableSelf();
   }
}

rule dojoUpgradeMonitor
inactive
minInterval 60
{
   int upgradePlanID = -1;

   // Disable rule once the upgrade is available
   if (kbTechGetStatus(cTechypDojoUpgrade1) == cTechStatusActive)
   {
      xsDisableSelf();
      return;
   }

   // Quit if there is no dojo
   if (kbUnitCount(cMyID, cUnitTypeypDojo, cUnitStateAlive) < 1)
   {
      return;
   }

   // Get upgrade
   if (kbTechGetStatus(cTechypDojoUpgrade1) == cTechStatusObtainable)
   {
      if (aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, cTechypDojoUpgrade1) >= 0)
         return;
      createSimpleResearchPlan(cTechypDojoUpgrade1, cUnitTypeypDojo, cMilitaryEscrowID, 50);
      return;
   }
}

*/