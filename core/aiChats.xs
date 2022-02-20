//==============================================================================
/* aiChats.xs

   This file is intended for any communication related stuffs, including
   request handling from the chat panel.

*/
//==============================================================================

//==============================================================================
/* sendStatement(player, commPromptID, vector)

  Sends a chat statement, but first checks the control variables and updates the
  "ok to chat" state.   This is a gateway for routine "ambience" personality chats.

  If vector is not cInvalidVector, it will be added as a flare
*/
//==============================================================================
void sendStatement(int playerIDorRelation = -1, int commPromptID = -1, vector vec = cInvalidVector)
{
   if (cvOkToTaunt == true)
   {
      // It's a player ID, not a relation.
      if (playerIDorRelation < 100)
      {
         int playerID = playerIDorRelation;
         debugChats("Sending AI Chat to player: " + playerID + ", commPromptID: " + commPromptID + ", vector: " + vec); 
         if (vec == cInvalidVector)
         {
            aiCommsSendStatement(playerID, commPromptID);
         }
         else
         {
            aiCommsSendStatementWithVector(playerID, commPromptID, vec);
         }
      }
      else // It's a player relation.
      {
         debugChats("Sending the following chat to all players that are my: " + playerIDorRelation);
         debugChats("PlayerRelationAny = 99999, PlayerRelationSelf = 100000, PlayerRelationEnemy = 100002, " +
            "PlayerRelationAlly = 100001, PlayerRelationEnemyNotGaia = 100004");
         for (int player = 1; player < cNumberPlayers; player++)
         {
            bool send = false;
            
            switch (playerIDorRelation)
            {
               case cPlayerRelationAny:
               {
                  send = true;
                  break;
               }
               case cPlayerRelationSelf:
               {
                  if (player == cMyID)
                  {
                     send = true;
                  }
                  break;
               }
               case cPlayerRelationAlly:
               {
                  send = kbIsPlayerAlly(player);
      
                  // Don't talk to myself, even though I am my ally.
                  if (player == cMyID)
                  {
                     send = false;
                  }
                  break;
               }
               case cPlayerRelationEnemy:
               case cPlayerRelationEnemyNotGaia:
               {
                  send = kbIsPlayerEnemy(player);
                  break;
               }
            }
            if (send == true)
            {
               debugChats("Sending AI Chat to player: " + player + ", commPromptID: " + commPromptID + ", vector: " + vec); 
               if (vec == cInvalidVector)
               {
                  aiCommsSendStatement(player, commPromptID);
               }
               else
               {
                  aiCommsSendStatementWithVector(player, commPromptID, vec);
               }
            }
         }
      }
   }
}

rule IKnowWhereYouLive // Send a menacing chat when we discover the enemy player's location
inactive 
minInterval 5
{
   static int targetPlayer = -1;

   if (targetPlayer < 0)
   {
      targetPlayer = getEnemyPlayerByTeamPosition(getTeamPosition(cMyID)); // Corresponding player on other team
      if (targetPlayer < 0)
      {
         xsDisableSelf();
         debugChats("No corresponding player on other team, IKnowWhereYouLive is deactivating.");
         debugChats("    My team position is " + getTeamPosition(cMyID));
         return;
      }
      debugChats("Rule IKnowWhereYouLive will threaten player #" + targetPlayer);
   }

   if (kbUnitCount(targetPlayer, cUnitTypeTownCenter, cUnitStateAlive) > 0)
   { // We see his TC for the first time
      int tc = getUnit(cUnitTypeTownCenter, targetPlayer, cUnitStateAlive);
      if (tc >= 0)
      {
         if (getUnitByLocation(cUnitTypeUnit, cMyID, cUnitStateAlive, kbUnitGetPosition(tc), 50.0) >= 0)
         { // I have a unit nearby, presumably I have LOS.
            sendStatement(targetPlayer, cAICommPromptToEnemyISpotHisTC, kbUnitGetPosition(tc));
            debugChats("Rule IKnowWhereYouLive is threatening player #" + targetPlayer);
         }
      }
      xsDisableSelf();
   }
}

rule tcChats
inactive
minInterval 10
{                          // Send chats about enemy TC placement
   static int tcID1 = -1;  // First enemy TC
   static int tcID2 = -1;  // Second
   static int enemy1 = -1; // ID of owner of first enemy TC.
   static int enemy2 = -1; // Second.
   static int secondTCQuery = -1;

   if (tcID1 < 0)
   { // Look for first enemy TC
      tcID1 = getUnit(cUnitTypeTownCenter, cPlayerRelationEnemy, cUnitStateAlive);
      if (tcID1 >= 0)
         enemy1 = kbUnitGetPlayerID(tcID1);
      return; // Done for now
   }

   // If we get here, we already know about one enemy TC.  Now, find the next closest enemy TC.
   if (secondTCQuery < 0)
   { // init - find all enemy TC's within 200 meters of first one.
      secondTCQuery = kbUnitQueryCreate("Second enemy TC");
   }
   kbUnitQuerySetPlayerRelation(secondTCQuery, cPlayerRelationEnemy);
   kbUnitQuerySetUnitType(secondTCQuery, cUnitTypeTownCenter);
   kbUnitQuerySetState(secondTCQuery, cUnitStateAlive);
   kbUnitQuerySetPosition(secondTCQuery, kbUnitGetPosition(tcID1));
   kbUnitQuerySetMaximumDistance(secondTCQuery, 500.0);

   kbUnitQueryResetResults(secondTCQuery);
   int tcCount = kbUnitQueryExecute(secondTCQuery);
   if (tcCount > 1) // Found another enemy TC
   {
      tcID2 = kbUnitQueryGetResult(secondTCQuery, 1); // Second unit in list
      enemy2 = kbUnitGetPlayerID(tcID2);
   }

   if (tcID2 < 0)
      return;

   // We have two TCs.  See if we have a unit in range.  If so, send a taunt if appropriate.  Either way, shut the rule
   // off.
   xsDisableSelf();

   if (enemy1 == enemy2)
      return; // Makes no sense to taunt if the same player owns both...

   bool haveLOS = false;
   if (getUnitByLocation(cUnitTypeUnit, cMyID, cUnitStateAlive, kbUnitGetPosition(tcID1), 50.0) >= 0)
      haveLOS = true;
   if (getUnitByLocation(cUnitTypeUnit, cMyID, cUnitStateAlive, kbUnitGetPosition(tcID2), 50.0) >= 0)
      haveLOS = true;

   if (haveLOS == true)
   {
      float d = distance(kbUnitGetPosition(tcID1), kbUnitGetPosition(tcID2));
      if (d < 100.0)
      { // Close together.  Taunt the two, flaring the other's bases.
         debugChats("Enemy TCs are " + d + " meters apart.  Taunting for closeness.");
         sendStatement(enemy1, cAICommPromptToEnemyHisTCNearAlly,
                       kbUnitGetPosition(tcID2)); // Taunt enemy 1 about enemy 2's TC
         sendStatement(enemy2, cAICommPromptToEnemyHisTCNearAlly,
                       kbUnitGetPosition(tcID1)); // Taunt enemy 2 about enemy 1's TC
      }
      if (d > 200.0)
      { // Far apart.  Taunt.
         debugChats("Enemy TCs are " + d + " meters apart.  Taunting for isolation.");
         sendStatement(enemy1, cAICommPromptToEnemyHisTCIsolated,
                       kbUnitGetPosition(tcID2)); // Taunt enemy 1 about enemy 2's TC
         sendStatement(enemy2, cAICommPromptToEnemyHisTCIsolated,
                       kbUnitGetPosition(tcID1)); // Taunt enemy 2 about enemy 1's TC
      }
      debugChats("Enemy TCs are " + d + " meters apart.");
   } // Otherwise, rule is turned off, we missed our chance.
   else
   {
      debugChats("Had no LOS to enemy TCs");
   }
}

//==============================================================================
// rule lateInAge
//==============================================================================
extern int gLateInAgePlayerID = -1;
extern int gLateInAgeAge = -1;
rule lateInAge
minInterval 120
inactive
{
   // This rule is used to taunt a player who is behind in the age race, but only if
   // he is still in the previous age some time (see minInterval) after the other
   // players have all advanced.  Before activating this rule, the calling function
   // (ageUpHandler) must set the global variables for playerID and age,
   // gLateInAgePlayerID and gLateInAgeAge.  When the rule finally fires minInterval
   // seconds later, it checks to see if that player is still behind, and taunts accordingly.
   if (gLateInAgePlayerID < 0)
      return;

   if (kbGetAgeForPlayer(gLateInAgePlayerID) == gLateInAgeAge)
   {
      if (gLateInAgeAge == cAge1)
      {
         if ((kbIsPlayerAlly(gLateInAgePlayerID) == true) && (gLateInAgePlayerID != cMyID))
            sendStatement(gLateInAgePlayerID, cAICommPromptToAllyHeIsAge1Late);
         if ((kbIsPlayerEnemy(gLateInAgePlayerID) == true))
            sendStatement(gLateInAgePlayerID, cAICommPromptToEnemyHeIsAge1Late);
      }
      else
      {
         if ((kbIsPlayerAlly(gLateInAgePlayerID) == true) && (gLateInAgePlayerID != cMyID))
            sendStatement(gLateInAgePlayerID, cAICommPromptToAllyHeIsStillAgeBehind);
         if ((kbIsPlayerEnemy(gLateInAgePlayerID) == true))
            sendStatement(gLateInAgePlayerID, cAICommPromptToEnemyHeIsStillAgeBehind);
      }
   }
   gLateInAgePlayerID = -1;
   gLateInAgeAge = -1;
   xsDisableSelf();
}

rule monitorScores
inactive
minInterval 60
group tcComplete
{
   static int startingScores = -1; // Array holding initial scores for each player
   static int highScores = -1;     // Array, each player's high-score mark
   static int teamScores = -1;
   int player = -1;
   int teamSize = 0;
   int myTeam = kbGetPlayerTeam(cMyID);
   int enemyTeam = -1;
   int highAllyScore = -1;
   int highAllyPlayer = -1;
   int highEnemyScore = -1;
   int highEnemyPlayer = -1;
   int score = -1;
   int firstHumanAlly = -1;

   if (aiGetGameType() != cGameTypeRandom) // TODO:  Check for DM if/when we have a DM type.
   {
      xsDisableSelf();
      return;
   }

   if (highScores < 0)
   {
      highScores = xsArrayCreateInt(cNumberPlayers, 1, "High Scores"); // create array, init below.
   }
   if (startingScores < 0)
   {
      if (aiGetNumberTeams() != 3) // Gaia, plus two
      {
         // Only do this if there are two teams with the same number of players on each team.
         xsDisableSelf();
         return;
      }
      startingScores = xsArrayCreateInt(cNumberPlayers, 1, "Starting Scores"); // init array
      for (player = 1; < cNumberPlayers)
      {
         score = aiGetScore(player);
         debugChats("Starting score for player " + player + " is " + score);
         xsArraySetInt(startingScores, player, score);
         xsArraySetInt(
             highScores,
             player,
             0); // High scores will track score actual - starting score, to handle deathmatch better.
      }
   }

   teamSize = 0;
   for (player = 1; < cNumberPlayers)
   {
      if (kbGetPlayerTeam(player) == myTeam)
      {
         teamSize = teamSize + 1;
         if ((kbIsPlayerHuman(player) == true) && (firstHumanAlly < 1))
            firstHumanAlly = player;
      }
      else
         enemyTeam = kbGetPlayerTeam(player); // Don't know if team numbers are 0..1 or 1..2, this works either way.
   }

   if ((2 * teamSize) != (cNumberPlayers - 1)) // Teams aren't equal size
   {
      xsDisableSelf();
      return;
   }

   // If we got this far, there are two teams and each has 'teamSize' players.  Otherwise, rule turns off.
   if (teamScores < 0)
   {
      teamScores = xsArrayCreateInt(3, 0, "Team total scores");
   }

   if (firstHumanAlly < 0) // No point if we don't have a human ally.
   {
      xsDisableSelf();
      return;
   }

   // Update team totals, check for new high scores
   xsArraySetInt(teamScores, myTeam, 0);
   xsArraySetInt(teamScores, enemyTeam, 0);
   highAllyScore = -1;
   highEnemyScore = -1;
   highAllyPlayer = -1;
   highEnemyPlayer = -1;
   int lowestRemainingScore = 100000; // Very high, will be reset by first real score
   int lowestRemainingPlayer = -1;
   int highestScore = -1;
   int highestPlayer = -1;

   for (player = 1; < cNumberPlayers)
   {
      score = aiGetScore(player) - xsArrayGetInt(startingScores, player); // Actual score relative to initial score
      if (kbHasPlayerLost(player) == true)
         continue;
      if (score < lowestRemainingScore)
      {
         lowestRemainingScore = score;
         lowestRemainingPlayer = player;
      }
      if (score > highestScore)
      {
         highestScore = score;
         highestPlayer = player;
      }
      if (score > xsArrayGetInt(highScores, player))
         xsArraySetInt(highScores, player, score); // Set personal high score
      if (kbGetPlayerTeam(player) == myTeam)       // Update team scores, check for highs
      {
         xsArraySetInt(teamScores, myTeam, xsArrayGetInt(teamScores, myTeam) + score);
         if (score > highAllyScore)
         {
            highAllyScore = score;
            highAllyPlayer = player;
         }
      }
      else
      {
         xsArraySetInt(teamScores, enemyTeam, xsArrayGetInt(teamScores, enemyTeam) + score);
         if (score > highEnemyScore)
         {
            highEnemyScore = score;
            highEnemyPlayer = player;
         }
      }
   }

   // Bools used to indicate chat usage, prevent re-use.
   static bool enemyNearlyDead = false;
   static bool enemyStrong = false;
   static bool losingEnemyStrong = false;
   static bool losingEnemyWeak = false;
   static bool losingAllyStrong = false;
   static bool losingAllyWeak = false;
   static bool winningNormal = false;
   static bool winningAllyStrong = false;
   static bool winningAllyWeak = false;

   static int shouldResignCount = 0;         // Set to 1, 2 and 3 as chats are used.
   static int shouldResignLastTime = 420000; // When did I last suggest resigning?  Consider it again 3 min later.
                                             // Defaults to 7 min, so first suggestion won't be until 10 minutes.

   // Attempt to fire chats, from most specific to most general.
   // When we chat, mark that one used and exit for now, i.e no more than one chat per rule execution.

   // First, check the winning / losing / tie situations.
   // Bail if earlier than 12 minutes
   if (xsGetTime() < 60 * 1000 * 12)
      return;

   if (aiTreatyActive() == true)
      return;

   bool winning = false;
   bool losing = false;
   float ourAverageScore = (aiGetScore(cMyID) + aiGetScore(firstHumanAlly)) / 2.0;

   if (xsArrayGetInt(teamScores, myTeam) > (1.20 * xsArrayGetInt(teamScores, enemyTeam)))
   { // We are winning
      winning = true;

      // Are we winning because my ally rocks?
      if ((winningAllyStrong == false) && (firstHumanAlly == highestPlayer))
      {
         winningAllyStrong = true;
         sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreWinningHeIsStronger);
         return;
      }

      // Are we winning in spite of my weak ally?
      if ((winningAllyWeak == false) && (cMyID == highestPlayer))
      {
         winningAllyWeak = true;
         sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreWinningHeIsWeaker);
         return;
      }

      // OK, we're winning, but neither of us has high score.
      if (winningNormal == false)
      {
         winningNormal = true;
         sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreWinning);
         return;
      }
   } // End chats while we're winning.

   if (xsArrayGetInt(teamScores, myTeam) < (0.70 * xsArrayGetInt(teamScores, enemyTeam)))
   { // We are losing
      losing = true;

      // Talk about resigning?
      if ((shouldResignCount < 3) &&
          ((xsGetTime() - shouldResignLastTime) > 3 * 60 * 1000)) // Haven't done it 3 times or within 3 minutes
      {
         switch (shouldResignCount)
         {
         case 0:
         {
            sendStatement(firstHumanAlly, cAICommPromptToAllyWeShouldResign1);
            break;
         }
         case 1:
         {
            sendStatement(firstHumanAlly, cAICommPromptToAllyWeShouldResign2);
            break;
         }
         case 2:
         {
            sendStatement(firstHumanAlly, cAICommPromptToAllyWeShouldResign3);
            break;
         }
         }
         shouldResignCount = shouldResignCount + 1;
         shouldResignLastTime = xsGetTime();
         return;
      } // End resign

      // Check for "we are losing but let's kill the weakling"
      if ((losingEnemyWeak == false) && (kbIsPlayerEnemy(lowestRemainingPlayer) == true))
      {
         switch (kbGetCivForPlayer(lowestRemainingPlayer))
         {
         case cCivRussians:
         {
            losingEnemyWeak = true; // chat used.
            sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyWeakRussian);
            return;
            break;
         }
         case cCivFrench:
         {
            losingEnemyWeak = true; // chat used.
            sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyWeakFrench);
            return;
            break;
         }
         case cCivGermans:
         {
            losingEnemyWeak = true; // chat used.
            sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyWeakGerman);
            return;
            break;
         }
         case cCivBritish:
         {
            losingEnemyWeak = true; // chat used.
            sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyWeakBritish);
            return;
            break;
         }
         case cCivSpanish:
         {
            losingEnemyWeak = true; // chat used.
            sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyWeakSpanish);
            return;
            break;
         }
         case cCivDESwedish:
         {
            losingEnemyWeak = true; // chat used.
            sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyWeakSwedes);
            return;
            break;
         }
         case cCivDutch:
         {
            losingEnemyWeak = true; // chat used.
            sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyWeakDutch);
            return;
            break;
         }
         case cCivPortuguese:
         {
            losingEnemyWeak = true; // chat used.
            sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyWeakPortuguese);
            return;
            break;
         }
         case cCivOttomans:
         {
            losingEnemyWeak = true; // chat used.
            sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyWeakOttoman);
            return;
            break;
         }
         case cCivDEInca:
         {
            losingEnemyWeak = true; // chat used.
            sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyWeakInca);
            return;
            break;
         }
         case cCivDEAmericans:
         {
            losingEnemyWeak = true; // chat used.
            sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyWeakAmerican);
            return;
            break;
         }
         case cCivDEEthiopians:
         {
            losingEnemyWeak = true; // chat used.
            sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyWeakEthiopian);
            return;
            break;
         }
         case cCivDEHausa:
         {
            losingEnemyWeak = true; // chat used.
            sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyWeakHausa);
            return;
            break;
         }
         case cCivJapanese:
         {
            if (civIsAsian() == true || civIsDEciv() == true)
            {
               losingEnemyWeak = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyWeakJapanese);
               return;
               break;
            }
         }
         case cCivChinese:
         {
            if (civIsAsian() == true || civIsDEciv() == true)
            {
               losingEnemyWeak = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyWeakChinese);
               return;
               break;
            }
         }
         case cCivIndians:
         {
            if (civIsAsian() == true || civIsDEciv() == true)
            {
               losingEnemyWeak = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyWeakIndian);
               return;
               break;
            }
         }
         }
      }

      // Check for losing while enemy player has high score.
      if ((losingEnemyStrong == false) && (kbIsPlayerEnemy(highestPlayer) == true))
      {
         switch (kbGetCivForPlayer(highestPlayer))
         {
         case cCivRussians:
         {
            losingEnemyStrong = true; // chat used.
            sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyStrongRussian);
            return;
            break;
         }
         case cCivFrench:
         {
            losingEnemyStrong = true; // chat used.
            sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyStrongFrench);
            return;
            break;
         }
         case cCivGermans:
         {
            losingEnemyStrong = true; // chat used.
            sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyStrongGerman);
            return;
            break;
         }
         case cCivBritish:
         {
            losingEnemyStrong = true; // chat used.
            sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyStrongBritish);
            return;
            break;
         }
         case cCivSpanish:
         {
            losingEnemyStrong = true; // chat used.
            sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyStrongSpanish);
            return;
            break;
         }
         case cCivDESwedish:
         {
            losingEnemyStrong = true; // chat used.
            sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyStrongSwedes);
            return;
            break;
         }
         case cCivDutch:
         {
            losingEnemyStrong = true; // chat used.
            sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyStrongDutch);
            return;
            break;
         }
         case cCivPortuguese:
         {
            losingEnemyStrong = true; // chat used.
            sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyStrongPortuguese);
            return;
            break;
         }
         case cCivOttomans:
         {
            losingEnemyStrong = true; // chat used.
            sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyStrongOttoman);
            return;
            break;
         }
         case cCivDEInca:
         {
            losingEnemyStrong = true; // chat used.
            sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyStrongInca);
            return;
            break;
         }
         case cCivDEAmericans:
         {
            losingEnemyStrong = true; // chat used.
            sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyStrongAmerican);
            return;
            break;
         }
         case cCivDEEthiopians:
         {
            losingEnemyStrong = true; // chat used.
            sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyStrongEthiopian);
            return;
            break;
         }
         case cCivDEHausa:
         {
            losingEnemyStrong = true; // chat used.
            sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyStrongHausa);
            return;
            break;
         }
         case cCivJapanese:
         {
            if (civIsAsian() == true || civIsDEciv() == true)
            {
               losingEnemyStrong = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyStrongJapanese);
               return;
               break;
            }
         }
         case cCivChinese:
         {
            if (civIsAsian() == true || civIsDEciv() == true)
            {
               losingEnemyStrong = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyStrongChinese);
               return;
               break;
            }
         }
         case cCivIndians:
         {
            if (civIsAsian() == true || civIsDEciv() == true)
            {
               losingEnemyStrong = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingEnemyStrongIndian);
               return;
               break;
            }
         }
         }
      }

      // If we're here, we're losing but our team has the high score.  If it's my ally, we're losing because I suck.
      if ((losingAllyStrong == false) && (firstHumanAlly == highestPlayer))
      {
         losingAllyStrong = true;
         sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingHeIsStronger);
         return;
      }
      if ((losingAllyWeak == false) && (cMyID == highestPlayer))
      {
         losingAllyWeak = true;
         sendStatement(firstHumanAlly, cAICommPromptToAllyWeAreLosingHeIsWeaker);
         return;
      }
   } // End chats while we're losing.

   if ((winning == false) && (losing == false))
   { // Close game

      // Check for a near-death enemy
      if ((enemyNearlyDead == false) && (kbIsPlayerEnemy(lowestRemainingPlayer) == true)) // Haven't used this chat yet
      {
         if ((lowestRemainingScore * 2) < xsArrayGetInt(highScores, lowestRemainingPlayer)) // He's down to half his high score.
         {
            switch (kbGetCivForPlayer(lowestRemainingPlayer))
            {
            case cCivRussians:
            {
               enemyNearlyDead = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyNearlyDeadRussian);
               return;
               break;
            }
            case cCivFrench:
            {
               enemyNearlyDead = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyNearlyDeadFrench);
               return;
               break;
            }
            case cCivBritish:
            {
               enemyNearlyDead = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyNearlyDeadBritish);
               return;
               break;
            }
            case cCivSpanish:
            {
               enemyNearlyDead = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyNearlyDeadSpanish);
               return;
               break;
            }
            case cCivDESwedish:
            {
               enemyNearlyDead = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyNearlyDeadSwedes);
               return;
               break;
            }
            case cCivGermans:
            {
               enemyNearlyDead = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyNearlyDeadGerman);
               return;
               break;
            }
            case cCivOttomans:
            {
               enemyNearlyDead = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyNearlyDeadOttoman);
               return;
               break;
            }
            case cCivDutch:
            {
               enemyNearlyDead = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyNearlyDeadDutch);
               return;
               break;
            }
            case cCivPortuguese:
            {
               enemyNearlyDead = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyNearlyDeadPortuguese);
               return;
               break;
            }
            case cCivDEInca:
            {
               enemyNearlyDead = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyNearlyDeadInca);
               return;
               break;
            }
            case cCivDEAmericans:
            {
               enemyNearlyDead = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyNearlyDeadAmerican);
               return;
               break;
            }
            case cCivDEEthiopians:
            {
               enemyNearlyDead = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyNearlyDeadEthiopian);
               return;
               break;
            }
            case cCivDEHausa:
            {
               enemyNearlyDead = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyNearlyDeadHausa);
               return;
               break;
            }
            case cCivJapanese:
            {
               if (civIsAsian() == true || civIsDEciv() == true)
               {
                  enemyNearlyDead = true; // chat used.
                  sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyNearlyDeadJapanese);
                  return;
                  break;
               }
            }
            case cCivChinese:
            {
               if (civIsAsian() == true || civIsDEciv() == true)
               {
                  enemyNearlyDead = true; // chat used.
                  sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyNearlyDeadChinese);
                  return;
                  break;
               }
            }
            case cCivIndians:
            {
               if (civIsAsian() == true || civIsDEciv() == true)
               {
                  enemyNearlyDead = true; // chat used.
                  sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyNearlyDeadIndian);
                  return;
                  break;
               }
            }
            }
         }
      }

      // Check for very strong enemy
      if ((enemyStrong == false) && (kbIsPlayerEnemy(highestPlayer) == true))
      {
         if ((ourAverageScore * 1.5) < highestScore)
         { // Enemy has high score, it's at least 50% above our average.
            switch (kbGetCivForPlayer(highestPlayer))
            {
            case cCivRussians:
            {
               enemyStrong = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyStrongRussian);
               return;
               break;
            }
            case cCivFrench:
            {
               enemyStrong = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyStrongFrench);
               return;
               break;
            }
            case cCivBritish:
            {
               enemyStrong = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyStrongBritish);
               return;
               break;
            }
            case cCivSpanish:
            {
               enemyStrong = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyStrongSpanish);
               return;
               break;
            }
            case cCivDESwedish:
            {
               enemyNearlyDead = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyStrongSwedes);
               return;
               break;
            }
            case cCivGermans:
            {
               enemyStrong = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyStrongGerman);
               return;
               break;
            }
            case cCivOttomans:
            {
               enemyStrong = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyStrongOttoman);
               return;
               break;
            }
            case cCivDutch:
            {
               enemyStrong = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyStrongDutch);
               return;
               break;
            }
            case cCivPortuguese:
            {
               enemyStrong = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyStrongPortuguese);
               return;
               break;
            }
            case cCivDEInca:
            {
               enemyNearlyDead = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyStrongInca);
               return;
               break;
            }
            case cCivDEAmericans:
            {
               enemyNearlyDead = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyStrongAmerican);
               return;
               break;
            }
            case cCivDEEthiopians:
            {
               enemyNearlyDead = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyStrongEthiopian);
               return;
               break;
            }
            case cCivDEHausa:
            {
               enemyNearlyDead = true; // chat used.
               sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyStrongHausa);
               return;
               break;
            }
            case cCivJapanese:
            {
               if (civIsAsian() == true || civIsDEciv() == true)
               {
                  enemyStrong = true; // chat used.
                  sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyStrongJapanese);
                  return;
                  break;
               }
            }
            case cCivChinese:
            {
               if (civIsAsian() == true || civIsDEciv() == true)
               {
                  enemyStrong = true; // chat used.
                  sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyStrongChinese);
                  return;
                  break;
               }
            }
            case cCivIndians:
            {
               if (civIsAsian() == true || civIsDEciv() == true)
               {
                  enemyStrong = true; // chat used.
                  sendStatement(firstHumanAlly, cAICommPromptToAllyEnemyStrongIndian);
                  return;
                  break;
               }
            }
            }
         }
      }
   } // End chats for close game
}

rule firstEnemyUnitSpotted
inactive
group startup
minInterval 5
{
   static int targetPlayer = -1;

   if (targetPlayer < 0)
   {
      targetPlayer = getEnemyPlayerByTeamPosition(getTeamPosition(cMyID)); // Corresponding player on other team
      if (targetPlayer < 0)
      {
         xsDisableSelf();
         debugChats("No corresponding player on other team, firstEnemyUnitSpotted is deactivating.");
         debugChats("    My team position is " + getTeamPosition(cMyID));
         return;
      }
      debugChats("Rule firstEnemyUnitSpotted will watch for player #" + targetPlayer);
   }

   if (kbUnitCount(targetPlayer, cUnitTypeLogicalTypeLandMilitary, cUnitStateAlive) > 0)
   { // We see one of this player's units for the first time...let's do some analysis on it
      int unitID = getUnit(
          cUnitTypeLogicalTypeLandMilitary,
          targetPlayer,
          cUnitStateAlive); // Get the (or one of the) enemy units
      if (unitID < 0)
      {
         debugChats("kbUnitCount said there are enemies, but getUnit finds nothing.");
         return;
      }

      debugChats("Enemy unit spotted at " + kbUnitGetPosition(unitID));
      debugChats("My base is at " + kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)));
      debugChats("Distance is " + distance(kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)), kbUnitGetPosition(unitID)));
      debugChats("Unit ID is " + unitID);
      // Three tests in priority order....anything near my town, an explorer anywhere, or default.
      // In my town?
      if (distance(kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)), kbUnitGetPosition(unitID)) < 60.0)
      {
         sendStatement(targetPlayer, cAICommPromptToEnemyISeeHisFirstMilitaryMyTown, kbUnitGetPosition(unitID));
         debugChats("Spotted a unit near my town, so I'm threatening player #" + targetPlayer);
         xsDisableSelf();
         return;
      }
      // Is it an explorer?
      if (kbUnitIsType(unitID, cUnitTypeExplorer) == true)
      {
         sendStatement(targetPlayer, cAICommPromptToEnemyISeeHisExplorerFirstTime, kbUnitGetPosition(unitID));
         debugChats("Spotted an enemy explorer, so I'm threatening player #" + targetPlayer);
         xsDisableSelf();
         return;
      }
      // Generic
      if (getUnitByLocation(cUnitTypeTownCenter, cPlayerRelationAny, cUnitStateAlive, kbUnitGetPosition(unitID), 70.0) < 0)
      { // No TCs nearby
         sendStatement(targetPlayer, cAICommPromptToEnemyISeeHisFirstMilitary, kbUnitGetPosition(unitID));
         debugChats("Spotted an enemy military unit for the first time, so I'm threatening player #" + targetPlayer);
      }
      xsDisableSelf();
      return;
   }
}

void monopolyStartHandler(int teamID = -1)
{
   debugChats("     ");
   debugChats("     ");
   debugChats("     ");
   debugChats("MonopolyStartHandler:  Team " + teamID);
   if (teamID < 0)
      return;

   // If this is my team, congratulate teammates and taunt enemies
   if (kbGetPlayerTeam(cMyID) == teamID)
   {
      sendStatement(cPlayerRelationAlly, cAICommPromptToAllyWhenWeGetMonopoly, cInvalidVector);
      sendStatement(cPlayerRelationEnemyNotGaia, cAICommPromptToEnemyWhenWeGetMonopoly, cInvalidVector);
   }
   else // Otherwise, snide comment to enemies and condolences to partners
   {
      sendStatement(cPlayerRelationAlly, cAICommPromptToAllyWhenEnemiesGetMonopoly, cInvalidVector);
      sendStatement(cPlayerRelationEnemyNotGaia, cAICommPromptToEnemyWhenTheyGetMonopoly, cInvalidVector);
   }
   gIsMonopolyRunning = true;
   gMonopolyTeam = teamID;
   gMonopolyEndTime = xsGetTime() + 5 * 60 * 1000;
   xsEnableRule("monopolyTimer");
}

void monopolyEndHandler(int teamID = -1)
{
   debugChats("     ");
   debugChats("     ");
   debugChats("     ");
   debugChats("MonopolyEndHandler:  Team " + teamID);
   if (teamID < 0)
      return;
   // If this is my team, console partners, and send defiant message to enemies
   if (kbGetPlayerTeam(cMyID) == teamID)
   {
      sendStatement(cPlayerRelationAlly, cAICommPromptToAllyEnemyDestroyedMonopoly, cInvalidVector);
      sendStatement(cPlayerRelationEnemyNotGaia, cAICommPromptToEnemyTheyDestroyedMonopoly, cInvalidVector);
   }
   else // Otherwise, gloat at enemies
   {
      sendStatement(cPlayerRelationEnemyNotGaia, cAICommPromptToEnemyIDestroyedMonopoly, cInvalidVector);
   }
   gIsMonopolyRunning = false;
   gMonopolyTeam = -1;
   gMonopolyEndTime = -1;
   xsDisableRule("monopolyTimer");
}

rule monopolyTimer
inactive
minInterval 5
{
   if ((gIsMonopolyRunning == false) || (gMonopolyEndTime < 0))
   {
      xsDisableSelf();
      return;
   }
   if (xsGetTime() > gMonopolyEndTime)
   {
      // If this is my team, congratulate teammates and taunt enemies
      if (kbGetPlayerTeam(cMyID) == gMonopolyTeam)
      {
         sendStatement(cPlayerRelationAlly, cAICommPromptToAlly1MinuteLeftOurMonopoly, cInvalidVector);
         sendStatement(cPlayerRelationEnemyNotGaia, cAICommPromptToEnemy1MinuteLeftOurMonopoly, cInvalidVector);
      }
      else // Otherwise, snide comment to enemies and panic to partners
      {
         sendStatement(cPlayerRelationAlly, cAICommPromptToAlly1MinuteLeftEnemyMonopoly, cInvalidVector);
         sendStatement(cPlayerRelationEnemyNotGaia, cAICommPromptToEnemy1MinuteLeftEnemyMonopoly, cInvalidVector);
      }
      xsDisableSelf();
      return;
   }
}

/*
   getNuggetChatID()

   Called from the nugget event handler.  Given the player ID, determine what
   type of nugget was just claimed, and return a specific appropriate chat ID, if any.

   If none apply, return the general 'got nugget' chat ID.
*/
int getNuggetChatID(int playerID = -1)
{
   int retVal = cAICommPromptToEnemyWhenHeGathersNugget;
   int type = aiGetLastCollectedNuggetType(playerID);
   int effect = aiGetLastCollectedNuggetEffect(playerID);

   switch (type)
   {
   case cNuggetTypeAdjustResource:
   {
      switch (effect)
      {
      case cResourceGold:
      {
         retVal = cAICommPromptToEnemyWhenHeGathersNuggetCoin;
         break;
      }
      case cResourceFood:
      {
         retVal = cAICommPromptToEnemyWhenHeGathersNuggetFood;
         break;
      }
      case cResourceWood:
      {
         retVal = cAICommPromptToEnemyWhenHeGathersNuggetWood;
         break;
      }
      }
      break;
   }
   case cNuggetTypeSpawnUnit:
   {
      if ((effect == cUnitTypeNatMedicineMan) || (effect == cUnitTypeNatClubman) || (effect == cUnitTypeNatRifleman) ||
          (effect == cUnitTypeNatHuaminca) || (effect == cUnitTypeNatTomahawk) || (effect == cUnitTypeNativeScout) ||
          (effect == cUnitTypeNatEagleWarrior))
      {
         retVal = cAICommPromptToEnemyWhenHeGathersNuggetNatives;
      }
      if ((effect == cUnitTypeSettler) || (effect == cUnitTypeCoureur) || (effect == cUnitTypeSettlerNative) ||
          (effect == cUnitTypeypSettlerAsian) || (effect == cUnitTypeypSettlerIndian))
         retVal = cAICommPromptToEnemyWhenHeGathersNuggetSettlers;
      break;
   }
   case cNuggetTypeGiveLOS:
   {
      break;
   }
   case cNuggetTypeAdjustSpeed:
   {
      break;
   }
   case cNuggetTypeAdjustHP:
   {
      break;
   }
   case cNuggetTypeConvertUnit:
   {
      if ((effect == cUnitTypeNatMedicineMan) || (effect == cUnitTypeNatClubman) || (effect == cUnitTypeNatRifleman) ||
          (effect == cUnitTypeNatHuaminca) || (effect == cUnitTypeNatTomahawk) || (effect == cUnitTypeNativeScout) ||
          (effect == cUnitTypeNatEagleWarrior))
      {
         retVal = cAICommPromptToEnemyWhenHeGathersNuggetNatives;
      }
      if ((effect == cUnitTypeSettler) || (effect == cUnitTypeCoureur) || (effect == cUnitTypeSettlerNative) ||
          (effect == cUnitTypeypSettlerAsian) || (effect == cUnitTypeypSettlerIndian))
         retVal = cAICommPromptToEnemyWhenHeGathersNuggetSettlers;
      break;
   }
   }

   return (retVal);
}

//==============================================================================
// nuggetHandler
//==============================================================================
void nuggetHandler(int playerID = -1)
{
   if (kbGetAge() > cAge2)
      return; // Do not send these chats (or even bother keeping count) after age 2 ends.
   // debugChats("***************** Nugget handler running with playerID"+playerID);
   static int nuggetCounts = -1; // Array handle.  nuggetCounts[i] will track how many nuggets each player has claimed
   static int totalNuggets = 0;
   const int cNuggetRange = 100; // Nuggets within this many meters of a TC are "owned".
   int defaultChatID = getNuggetChatID(playerID);

   if ((playerID < 1) || (playerID > cNumberPlayers))
      return;

   // Initialize the array if we haven't done this before.
   if (nuggetCounts < 0)
   {
      nuggetCounts = xsArrayCreateInt(cNumberPlayers, 0, "Nugget Counts");
   }

   // Score this nugget
   totalNuggets = totalNuggets + 1;
   xsArraySetInt(nuggetCounts, playerID, xsArrayGetInt(nuggetCounts, playerID) + 1);

   // Check to see if one of the special-case chats might be appropriate.
   // If so, use it, otherwise, fall through to the generic ones.
   // First, some bookkeeping
   int i = 0;
   int count = 0;
   int lowestPlayer = -1;
   int lowestCount = 100000; // Insanely high start value, first pass will reset it.
   int totalCount = 0;
   int averageCount = 0;
   int highestPlayer = -1;
   int highestCount = 0;
   for (i = 1; < cNumberPlayers)
   {
      count = xsArrayGetInt(nuggetCounts, i, ); // How many nuggets has player i gathered?
      if (count < lowestCount)
      {
         lowestCount = count;
         lowestPlayer = i;
      }
      if (count > highestCount)
      {
         highestCount = count;
         highestPlayer = i;
      }
      totalCount = totalCount + count;
   }
   averageCount = totalCount / (cNumberPlayers - 1);

   if (totalCount == 1) // This is the first nugget in the game
   {
      if (playerID != cMyID)
      {
         if (kbIsPlayerAlly(playerID) == true)
         {
            sendStatement(playerID, cAICommPromptToAllyWhenHeGathersFirstNugget);
            return;
         }
         else
         {
            sendStatement(playerID, cAICommPromptToEnemyWhenHeGathersFirstNugget);
            return;
         }
      }
   }

   int playersCount = 0;
   int myCount = 0;
   myCount = xsArrayGetInt(nuggetCounts, cMyID);
   playersCount = xsArrayGetInt(nuggetCounts, playerID);
   // Check if this player is way ahead of me, i.e. 2x my total and ahead by at least 2
   if (((playersCount - myCount) >= 2) && (playersCount >= (myCount * 2)))
   {
      if (kbIsPlayerAlly(playerID) == true)
      {
         sendStatement(playerID, cAICommPromptToAllyWhenHeGathersNuggetHeIsAhead);
         return;
      }
      else
      {
         sendStatement(playerID, cAICommPromptToEnemyWhenHeGathersNuggetHeIsAhead);
         return;
      }
   }

   // Check if I'm way ahead of any other players
   int player = 0; // Loop counter...who might I send a message to
   bool messageSent = false;
   if (playerID == cMyID)
   {
      for (player = 1; < cNumberPlayers)
      {
         playersCount = xsArrayGetInt(nuggetCounts, player);
         if (((myCount - playersCount) >= 2) && (myCount >= (playersCount * 2)))
         {
            if (kbIsPlayerAlly(player) == true)
            {
               sendStatement(player, cAICommPromptToAllyWhenIGatherNuggetIAmAhead);
               messageSent = true;
            }
            else
            {
               sendStatement(player, cAICommPromptToEnemyWhenIGatherNuggetIAmAhead);
               messageSent = true;
            }
         }
      }
   }
   if (messageSent == true)
      return;

   // Check to see if the nugget was gathered near a main base.
   // For now, check playerID's explorer location, assume nugget was gathered there.
   // Later, we may add location info to the event handler.
   vector explorerPos = cInvalidVector;
   int explorerID = -1;
   int tcID = -1;

   explorerID = getUnit(cUnitTypeExplorer, playerID, cUnitStateAlive);
   if (explorerID >= 0) // We know of an explorer for this player
   {
      if (kbUnitVisible(explorerID) == true)
      { // And we can see him.
         explorerPos = kbUnitGetPosition(explorerID);
         if (playerID == cMyID)
         { // I gathered the nugget
            // Get nearest ally TC distance
            tcID = getUnitByLocation(cUnitTypeTownCenter, cPlayerRelationAlly, cUnitStateAlive, explorerPos, cNuggetRange);
            if ((tcID > 0) && (kbUnitGetPlayerID(tcID) != cMyID))
            { // A TC is near, owned by an ally, and it's not mine...
               sendStatement(
                   kbUnitGetPlayerID(tcID),
                   cAICommPromptToAllyWhenIGatherNuggetHisBase); // I got a nugget near his TC
               return;
            }
            // Get nearest enemy TC distance
            tcID = getUnitByLocation(cUnitTypeTownCenter, cPlayerRelationEnemy, cUnitStateAlive, explorerPos, cNuggetRange);
            if (tcID > 0)
            { // A TC is near, owned by an enemy...
               sendStatement(
                   kbUnitGetPlayerID(tcID),
                   cAICommPromptToEnemyWhenIGatherNuggetHisBase); // I got a nugget near his TC
               return;
            }
         }
         else
         {
            if (kbIsPlayerAlly(playerID) == true)
            { // An ally has found a nugget, see if it's close to my TC
               tcID = getUnitByLocation(cUnitTypeTownCenter, cMyID, cUnitStateAlive, explorerPos, cNuggetRange);
               if (tcID > 0)
               {                                                                         // That jerk took my nugget!
                  sendStatement(playerID, cAICommPromptToAllyWhenHeGathersNuggetMyBase); // He got one in my zone
                  return;
               }
            }
            else
            { // An enemy has found a nugget, see if it's in my zone
               tcID = getUnitByLocation(cUnitTypeTownCenter, cMyID, cUnitStateAlive, explorerPos, cNuggetRange);
               if (tcID > 0)
               {                                                                          // That jerk took my nugget!
                  sendStatement(playerID, cAICommPromptToEnemyWhenHeGathersNuggetMyBase); // He got one in my zone
                  return;
               }
            }
         } // if me else
      }    // If explorer is visible to me
   }       // If explorer known

   // No special events fired, so go with generic messages
   // defaultChatID has the appropriate chat if an enemy gathered the nugget...send it.
   // Otherwise, convert to the appropriate case.
   if (playerID != cMyID)
   {
      if (kbIsPlayerEnemy(playerID) == true)
      {
         sendStatement(playerID, defaultChatID);
      }
      else
      { // Find out what was returned, send the equivalent ally version
         switch (defaultChatID)
         {
         case cAICommPromptToEnemyWhenHeGathersNugget:
         {
            sendStatement(playerID, cAICommPromptToAllyWhenHeGathersNugget);
            break;
         }
         case cAICommPromptToEnemyWhenHeGathersNuggetCoin:
         {
            sendStatement(playerID, cAICommPromptToAllyWhenHeGathersNuggetCoin);
            break;
         }
         case cAICommPromptToEnemyWhenHeGathersNuggetFood:
         {
            sendStatement(playerID, cAICommPromptToAllyWhenHeGathersNuggetFood);
            break;
         }
         case cAICommPromptToEnemyWhenHeGathersNuggetWood:
         {
            sendStatement(playerID, cAICommPromptToAllyWhenHeGathersNuggetWood);
            break;
         }
         case cAICommPromptToEnemyWhenHeGathersNuggetNatives:
         {
            sendStatement(playerID, cAICommPromptToAllyWhenHeGathersNuggetNatives);
            break;
         }
         case cAICommPromptToEnemyWhenHeGathersNuggetSettlers:
         {
            sendStatement(playerID, cAICommPromptToAllyWhenHeGathersNuggetSettlers);
            break;
         }
         }
      }
   }
   else
   {
      //-- I gathered the nugget.  Figure out what kind it is based on the defaultChatID enemy version.
      // Substitute appropriate ally and enemy chats.
      switch (defaultChatID)
      {
      case cAICommPromptToEnemyWhenHeGathersNugget:
      {
         sendStatement(cPlayerRelationAlly, cAICommPromptToAllyWhenIGatherNugget);
         sendStatement(cPlayerRelationEnemy, cAICommPromptToEnemyWhenIGatherNugget);
         break;
      }
      case cAICommPromptToEnemyWhenHeGathersNuggetCoin:
      {
         sendStatement(cPlayerRelationAlly, cAICommPromptToAllyWhenIGatherNuggetCoin);
         sendStatement(cPlayerRelationEnemy, cAICommPromptToEnemyWhenIGatherNuggetCoin);
         break;
      }
      case cAICommPromptToEnemyWhenHeGathersNuggetFood:
      {
         sendStatement(cPlayerRelationAlly, cAICommPromptToAllyWhenIGatherNuggetFood);
         sendStatement(cPlayerRelationEnemy, cAICommPromptToEnemyWhenIGatherNuggetFood);
         break;
      }
      case cAICommPromptToEnemyWhenHeGathersNuggetWood:
      {
         sendStatement(cPlayerRelationAlly, cAICommPromptToAllyWhenIGatherNuggetWood);
         sendStatement(cPlayerRelationEnemy, cAICommPromptToEnemyWhenIGatherNuggetWood);
         break;
      }
      case cAICommPromptToEnemyWhenHeGathersNuggetNatives:
      {
         sendStatement(cPlayerRelationAlly, cAICommPromptToAllyWhenIGatherNuggetNatives);
         sendStatement(cPlayerRelationEnemy, cAICommPromptToEnemyWhenIGatherNuggetNatives);
         break;
      }
      case cAICommPromptToEnemyWhenHeGathersNuggetSettlers:
      {
         sendStatement(cPlayerRelationAlly, cAICommPromptToAllyWhenIGatherNuggetSettlers);
         sendStatement(cPlayerRelationEnemy, cAICommPromptToEnemyWhenIGatherNuggetSettlers);
         break;
      }
      }
   }

   return;
}

//==============================================================================
// commHandler
// This event handler is called whenever a human player requests something via the Diplomacy menu.
// Or a scenario uses the aiComm triggers.
//==============================================================================
void commHandler(int chatID = -1)
{
   int fromID = aiCommsGetSendingPlayer(chatID); // Which player sent this?
   // DO NOT react to my own commands/requests.
   // DO NOT accept commands/requests from enemies.
   if ((fromID == cMyID) || ((kbIsPlayerEnemy(fromID) == true) && (fromID != 0)))
   {
      return;
   }

   // The campaign team has indicated this menu shouldn't function inside of SP content.
   // Because it could mess with their design of the allied AIs.
   // But trigger requests we of course do take!
   if ((gSPC == true) && (fromID != 0))
   {
      sendStatement(fromID, cAICommPromptToAllyDeclineProhibited);
      return;
   }

   int age = kbGetAge();
   if (age == cAge1)
   {  // Don't do anything in Exploration since it often makes no sense or would mess up our start.
      sendStatement(fromID, cAICommPromptToAllyDeclineProhibited);
      return;
   }
   
   int verb = aiCommsGetChatVerb(chatID); // Like cPlayerChatVerbAttack or cPlayerChatVerbDefend.
   int targetType = aiCommsGetChatTargetType(chatID); // Like cPlayerChatTargetTypePlayers or cPlayerChatTargetTypeLocation.
   int target = aiCommsGetTargetListItem(chatID, 0); // Like cResourceFood or cUnitTypeAbstractArtillery.
   vector location = aiCommsGetTargetLocation(chatID); // Target location
   
   static float initialbtRushBoom = -2.0;
   static float initialbtOffenseDefense = -2.0;
   static float initialbtBiasCav = -2.0;
   static float initialbtBiasInf = -2.0;
   static float initialbtBiasArt = -2.0;
   if (initialbtRushBoom == -2.0) // First run.
   {
      initialbtRushBoom = btRushBoom;
      initialbtOffenseDefense = btOffenseDefense;
      initialbtBiasCav = btBiasCav;
      initialbtBiasInf = btBiasInf;
      initialbtBiasArt = btBiasArt;
   }

   // Assume it's from a player unless we find out it's player 0, Gaia, indicating a trigger.
   // We currently do nothing with this information since we haven't implemented most of the trigger stuff.
   //int opportunitySource = cOpportunitySourceAllyRequest; 
   //if (fromID == 0)                                       
   //{
   //   opportunitySource = cOpportunitySourceTrigger;
   //}

   debugChats("***** Incoming Communication *****");
   debugChats("From player: " + fromID + ", verb: " + verb + ", targetType: " + targetType + ", target: " + target);

   switch (verb) // Parse this message starting with the verb.
   {
      case cPlayerChatVerbAttack:
      {
         if (aiTreatyActive() == true)
         {
            sendStatement(fromID, cAICommPromptToAllyDeclineProhibited);
            debugChats("Deny attack/defend request because treaty is active");
            break;
         }

         int numUnits = aiPlanGetNumberUnits(gLandReservePlan, cUnitTypeLogicalTypeLandMilitary);
         int currentFreeMilitaryPop = 0;
         for (int i = 0; i < numUnits; i++)
         {
            int unitID = aiPlanGetUnitByIndex(gLandReservePlan, i);
            currentFreeMilitaryPop += kbGetPopSlots(cMyID, kbUnitGetProtoUnitID(unitID));
         }
         if (currentFreeMilitaryPop < 5)
         {
            sendStatement(fromID, cAICommPromptToAllyDeclineNoArmy);
            debugChats("Deny attack/defend request because no army");
            break;
         }
         if (currentFreeMilitaryPop < 15)
         {
            sendStatement(fromID, cAICommPromptToAllyDeclineSmallArmy);
            debugChats("Deny attack/defend request because small army");
            break;
         }
         
         if (isDefendingOrAttacking() == true)
         {
            sendStatement(fromID, cAICommPromptToAllyDeclineGeneral);
            break;
         }
         
         debugChats("Location(vector) of the requested attack / defend: " + location);
         switch (targetType)
         {
            case cPlayerChatTargetTypeLocation:
            {
               // This means our human ally has requested we "attack" this location.
               // Attack here can mean either of 2 things: "attack" or "defend".
               // We get how many buildings there are at the provided location and decide what to do based off that.
               
               int mainBaseID = kbBaseGetMainID(cMyID);
               // Always defend ourselves first.
               if (gDefenseReflexBaseID == mainBaseID)
               {
                  sendStatement(fromID, cAICommPromptToAllyDeclineGeneral);
                  debugChats("Deny attack/defend request because we're under attack ourselves");
                  break;
               }
               
               int numEnemyBuildings = getUnitCountByLocation(cUnitTypeBuilding, cPlayerRelationEnemyNotGaia, cUnitStateAlive,
                  location, 50.0);
               int numAlliedBuildings = getUnitCountByLocation(cUnitTypeBuilding, cPlayerRelationAlly, cUnitStateAlive,
                  location, 50.0);
               
               // We do not defend or attack in an open space, there must be buildings present.
               if ((numEnemyBuildings == 0) && (numAlliedBuildings == 0))
               {
                  sendStatement(fromID, cAICommPromptToAllyDeclineGeneral);
                  debugChats("Deny attack/defend request because no buildings found");
                  break;
               }
               
               int combatPlanID = -1;

               // Attack plan.
               if (numEnemyBuildings >= numAlliedBuildings)
               {  
                  int enemyBuildingID = getClosestUnitByLocation(cUnitTypeBuilding, cPlayerRelationEnemyNotGaia, cUnitStateAlive,
                     location, 50.0);
                  int playerToAttack = kbUnitGetPlayerID(enemyBuildingID);
                  vector gatherPoint = kbBaseGetMilitaryGatherPoint(cMyID, mainBaseID);
                  
                  combatPlanID = aiPlanCreate("commHandler Attack Player " + playerToAttack, cPlanCombat);

                  aiPlanSetVariableInt(combatPlanID, cCombatPlanCombatType, 0, cCombatPlanCombatTypeAttack);
                  aiPlanSetVariableInt(combatPlanID, cCombatPlanTargetPlayerID, 0, playerToAttack);
                  aiPlanSetVariableInt(combatPlanID, cCombatPlanTargetBaseID, 0, kbUnitGetBaseID(enemyBuildingID));
                  aiPlanSetVariableVector(combatPlanID, cCombatPlanTargetPoint, 0, location);
                  aiPlanSetVariableVector(combatPlanID, cCombatPlanGatherPoint, 0, gatherPoint);
                  aiPlanSetVariableFloat(combatPlanID, cCombatPlanGatherDistance, 0, 40.0);
                  aiPlanSetVariableInt(combatPlanID, cCombatPlanAttackRoutePattern, 0, cCombatPlanAttackRoutePatternRandom);
            
                  if (cDifficultyCurrent >= cDifficultyHard)
                  {
                     aiPlanSetVariableInt(combatPlanID, cCombatPlanRefreshFrequency, 0, 300);
                     aiPlanSetVariableInt(combatPlanID, cCombatPlanDoneMode, 0, cCombatPlanDoneModeRetreat | cCombatPlanDoneModeBaseGone);
                     aiPlanSetVariableInt(combatPlanID, cCombatPlanRetreatMode, 0, cCombatPlanRetreatModeOutnumbered);
                     updateMilitaryTrainPlanBuildings(gForwardBaseID);
                     if (cDifficultyCurrent >= cDifficultyExpert)
                     {
                        aiPlanSetVariableBool(combatPlanID, cCombatPlanAllowMoreUnitsDuringAttack, 0, true);
                     }
                  }
                  else
                  {
                     aiPlanSetVariableInt(combatPlanID, cCombatPlanRefreshFrequency, 0, 1000);
                     aiPlanSetVariableInt(combatPlanID, cCombatPlanDoneMode, 0, cCombatPlanDoneModeBaseGone);
                  }
                  aiPlanSetBaseID(combatPlanID, mainBaseID);
                  aiPlanSetInitialPosition(combatPlanID, gatherPoint);
            
                  addUnitsToMilitaryPlan(combatPlanID);
            
                  aiPlanSetActive(combatPlanID);
            
                  gLastAttackMissionTime = xsGetTime();
                  
                  sendStatement(fromID, cAICommPromptToAllyIWillAttackWithYou, location);
                  debugChats("Confirming attack request");
               }
               else // Defend plan.
               {
                  int alliedBuildingID = getClosestUnitByLocation(cUnitTypeBuilding, cPlayerRelationAlly, cUnitStateAlive,
                     location, 50.0);
                  int playerToDefend = kbUnitGetPlayerID(alliedBuildingID);
                  combatPlanID = aiPlanCreate("commHandler Defend Player " + playerToDefend, cPlanCombat);
                  
                  aiPlanSetVariableInt(combatPlanID, cCombatPlanCombatType, 0, cCombatPlanCombatTypeDefend);
                  aiPlanSetVariableInt(combatPlanID, cCombatPlanTargetPlayerID, 0, playerToDefend);
                  aiPlanSetVariableInt(combatPlanID, cCombatPlanTargetBaseID, 0, kbUnitGetBaseID(alliedBuildingID));
                  aiPlanSetVariableVector(combatPlanID, cCombatPlanTargetPoint, 0, location);
                  aiPlanSetVariableInt(combatPlanID, cCombatPlanRefreshFrequency, 0, cDifficultyCurrent >= cDifficultyHard ? 300 : 1000);
                  aiPlanSetVariableInt(combatPlanID, cCombatPlanDoneMode, 0, cCombatPlanDoneModeNoTarget);
                  aiPlanSetVariableInt(combatPlanID, cCombatPlanNoTargetTimeout, 0, 30000);
                  aiPlanSetVariableInt(combatPlanID, cCombatPlanRetreatMode, 0, cCombatPlanRetreatModeNone);
                  aiPlanSetOrphan(combatPlanID, true);

                  addUnitsToMilitaryPlan(combatPlanID);
                  aiPlanSetActive(combatPlanID);
                  sendStatement(fromID, cAICommPromptToAllyIWillHelpDefend, location);
                  debugChats("Confirming defend request");
               }
               break;
            }
            case cPlayerChatTargetTypeUnits:
            {
               // This is only available via triggers.
               // You must provide a premade army inside of the editor which the AI will then attack.
               // This doesn't work yet, just deny.
               sendStatement(fromID, cAICommPromptToAllyDeclineGeneral);
               break;
            }
         }
         break;
      } // End attack.
   
      case cPlayerChatVerbTribute:
      {
         if (fromID == 0) // This was a trigger command.
         {
            debugChats("Trigger tribute command");
            fromID = 1; // We always tribute to player 1 when a trigger asks us to tribute.
         }
         debugChats("Command was to tribute to player " + fromID);
         debugChats("Requested resource is: " + kbGetResourceName(target));
         
         switch (target)
         {
            case cResourceGold:
            {
               if (handleTributeRequest(cResourceGold, fromID) == true)
               {
                  sendStatement(fromID, cAICommPromptToAllyITributedCoin);
               }
               else
               {
                  sendStatement(fromID, cAICommPromptToAllyDeclineCantAfford);
               }
               break;
            }
            case cResourceWood:
            {
               if (handleTributeRequest(cResourceWood, fromID) == true)
               {
                  sendStatement(fromID, cAICommPromptToAllyITributedWood);
               }
               else
               {
                  sendStatement(fromID, cAICommPromptToAllyDeclineCantAfford);
               }
               break;
            }
           case cResourceFood:
            {
               if (handleTributeRequest(cResourceFood, fromID) == true)
               {
                  sendStatement(fromID, cAICommPromptToAllyITributedFood);
               }
               else
               {
                  sendStatement(fromID, cAICommPromptToAllyDeclineCantAfford);
               }
               break;
            }
         }
         break;
      } // End tribute.
   
      case cPlayerChatVerbFeed: // monitorFeeding will tribute to the player if we have enough resources once a minute.
      {
         debugChats("Command was to feed resources to player: " + fromID);
         debugChats("Requested resource is: " + kbGetResourceName(target));
         switch (target)
         {
            case cResourceGold:
            {
               debugChats("We accept and will feed some Gold");
               gFeedGoldTo = fromID;
               if (xsIsRuleEnabled("monitorFeeding") == false)
               {
                  xsEnableRule("monitorFeeding");
                  monitorFeeding();
               }
               sendStatement(fromID, cAICommPromptToAllyIWillFeedCoin);
               break;
            }
            case cResourceWood:
            {
               debugChats("We accept and will feed some Wood");
               gFeedWoodTo = fromID;
               if (xsIsRuleEnabled("monitorFeeding") == false)
               {
                  xsEnableRule("monitorFeeding");
                  monitorFeeding();
               }
               sendStatement(fromID, cAICommPromptToAllyIWillFeedWood);
               break;
            }
            case cResourceFood:
            {
               debugChats("We accept and will feed some Food");
               gFeedFoodTo = fromID;
               if (xsIsRuleEnabled("monitorFeeding") == false)
               {
                  xsEnableRule("monitorFeeding");
                  monitorFeeding();
               }
               sendStatement(fromID, cAICommPromptToAllyIWillFeedFood);
               break;
            }
         }
         break;
      } // End feed.
   
      case cPlayerChatVerbTrain:
      {
         // You can ask the AI to focus on 3 different unit types without needing to cancel first, guard for that.
         switch (target)
         {
            case cUnitTypeAbstractInfantry:
            {
               btBiasCav = initialbtBiasCav;
               btBiasArt = initialbtBiasArt;
               btBiasInf += 0.5;
               if (btBiasInf > 1.0)
               {
                  btBiasInf = 1.0;
               }
               sendStatement(fromID, cAICommPromptToAllyConfirmInf);
               break;
            }
            case cUnitTypeAbstractCavalry:
            {
               btBiasInf = initialbtBiasInf;
               btBiasArt = initialbtBiasArt;
               btBiasCav += 0.5;
               if (btBiasCav > 1.0)
               {
                  btBiasCav = 1.0;
               }
               sendStatement(fromID, cAICommPromptToAllyConfirmCav);
               break;
            }
            case cUnitTypeAbstractArtillery:
            {
               // These civs only get artillery when they're in the Imperial Age.
               if (((cMyCiv == cCivXPSioux) ||
                    (cMyCiv == cCivXPAztec) ||
                    (cMyCiv == cCivDEInca)) &&
                    (age != cAge5))
               {
                  sendStatement(fromID, cAICommPromptToAllyDeclineProhibited);
                  break;
               }
               // Only Swedes get artillery in Commerce Age, the rest must wait until Fortress Age.
               if ((cMyCiv != cCivDESwedish) &&
                   (age == cAge2))
               {
                  sendStatement(fromID, cAICommPromptToAllyDeclineProhibited);
                  break;
               }
               btBiasCav = initialbtBiasCav;
               btBiasInf = initialbtBiasInf;
               btBiasArt += 0.5;
               if (btBiasArt > 1.0)
               {
                  btBiasArt = 1.0;
               }
               sendStatement(fromID, cAICommPromptToAllyConfirmArt);
               break;
            }
         }
         break;
      } // End train.
      
      case cPlayerChatVerbDefend:
      {
         // This is only available via triggers, you must provide a location in the trigger.
         // We should then create a combat plan on defend mode on that location.
         // Doesn't work yet, just deny.
         sendStatement(fromID, cAICommPromptToAllyDeclineGeneral);
         break;
      } // End defend.
      
      case cPlayerChatVerbClaim:
      {  
         // This is only available via triggers, you must provide a location in the trigger.
         // We should then scan the location for a Trading Post socket and make a build plan for it.
         // Doesn't work yet, just deny.
         sendStatement(fromID, cAICommPromptToAllyDeclineGeneral);
         break;
      } // End Claim.
      
      case cPlayerChatVerbStrategy:
      {
         // You can ask the AI to do the 3 different strategies without needing to cancel first, guard for that.
         if (target == cPlayerChatTargetStrategyRush)
         {
            gTowerCommandActive = true;
            btRushBoom = 1.0;
            gCommandNumTowers = 0;
            btOffenseDefense = initialbtOffenseDefense;
         }
         else if (target == cPlayerChatTargetStrategyBoom)
         {
            btRushBoom = -1.0;
            btOffenseDefense = initialbtOffenseDefense;
            gTowerCommandActive = false;
         }
         else if (target == cPlayerChatTargetStrategyTurtle)
         {
            gTowerCommandActive = true;
            btOffenseDefense = -1.0;
            btRushBoom = initialbtRushBoom;
   
            if (cDifficultyCurrent <= cDifficultyEasy) // Easy / Standard.
            {
               gCommandNumTowers = 3; // 1 More than the default maximum.
            }
            else if (cDifficultyCurrent <= cDifficultyHard) // Moderate / Hard.
            {
               gCommandNumTowers = 5; // 1 More than the default maximum.
            }
            else // Hardest / Extreme.
            {    // We just max out on Towers where we normally would only do that in the cvMaxAge.
               gCommandNumTowers = kbGetBuildLimit(cMyID, gTowerUnit);
            }
         }
         // We just always accept this request.
         sendStatement(fromID, cAICommPromptToAllyConfirm);
         break;
      } // End strategy.
      
      case cPlayerChatVerbCancel:
      {
         // We do not destroy the ongoing defend/attack plans because
         // that would be very bad if the units are currently in combat.
         
         // Clear Feeding (ongoing tribute) settings.
         gFeedGoldTo = 0;
         gFeedWoodTo = 0;
         gFeedFoodTo = 0;
   
         // No longer use the custom Tower limits.
         gTowerCommandActive = false;
   
         // Reset the sliders.
         btRushBoom = initialbtRushBoom;
         btOffenseDefense = initialbtOffenseDefense;
         btBiasCav = initialbtBiasCav;
         btBiasInf = initialbtBiasInf;
         btBiasArt = initialbtBiasArt;
   
         // We always allow cancellation.
         sendStatement(fromID, cAICommPromptToAllyConfirm);
         break;
      } // End cancel.
      
      default:
      {
         debugChats("WARNING: Command verb not found, verb value is: " + verb);
         break;
      }
   }
   debugChats("***** End of communication *****");
}