IncludeScript("customweaponsvillaedit.nut", getroottable())

PrecacheSound("misc/halloween/spell_fireball_impact.wav")
PrecacheSound("ambient/explosions/explode_1.wav")
PrecacheSound("ambient/explosions/explode_4.wav")
PrecacheSound("ambient/explosions/explode_5.wav")
PrecacheSound("ambient/explosions/explode_7.wav")
PrecacheSound("ambient/explosions/explode_8.wav")
PrecacheSound("ambient/levels/labs/electric_explosion1.wav")
PrecacheSound("ambient/levels/labs/electric_explosion2.wav")
PrecacheSound("ambient/levels/labs/electric_explosion3.wav")
PrecacheSound("ambient/levels/labs/electric_explosion4.wav")
PrecacheSound("ambient/levels/labs/electric_explosion5.wav")
PrecacheSound("misc/doomsday_missile_explosion.wav")
PrecacheSound("mvm/mvm_tank_explode.wav")
PrecacheSound("vo/mvm/norm/medic_mvm_laughevil03.mp3") //Whenever eating bots
PrecacheSound("vo/mvm/norm/medic_mvm_negativevocalization05.mp3") //When losing bot eat buff
PrecacheSound("vo/mvm/norm/medic_mvm_negativevocalization06.mp3") //Whenever going to defensive mode
PrecacheSound("vo/mvm/norm/medic_mvm_battlecry01.mp3") //Whenever going to offensive mode
PrecacheSound("vo/mvm/norm/medic_mvm_laughevil05.mp3") //Transitioning to phase 2 /  HF mimic
PrecacheSound("vo/mvm/norm/medic_mvm_laughevil01.mp3") //Whenever killing player
PrecacheSound("vo/mvm/norm/medic_mvm_laughshort01.mp3") //Whenever killing player
PrecacheSound("vo/mvm/norm/medic_mvm_laughshort02.mp3") //Whenever killing player
PrecacheSound("vo/mvm/norm/medic_mvm_negativevocalization01.mp3") //Transitioning to Dyspnea mimic
PrecacheSound("vo/mvm/norm/medic_mvm_specialcompleted05.mp3") //Transitioning to Tumor mimic
PrecacheSound("vo/mvm/norm/medic_mvm_specialcompleted07.mp3") //Transitioning to Cardiomyopathy mimic
PrecacheSound("vo/mvm/norm/medic_mvm_negativevocalization04.mp3") //Transitioning to Sarcoma mimic
PrecacheSound("vo/mvm/norm/medic_mvm_laughhappy02.mp3") //Transitioning to Tachycardia mimic
PrecacheSound("vo/mvm/norm/medic_mvm_battlecry03.mp3") //Transitioning to Pneumonia mimic
PrecacheSound("vo/mvm/norm/medic_mvm_jeers06.mp3") //Transitioning to Cardiac Arrest mimic
PrecacheSound("vo/mvm/norm/medic_mvm_paincrticialdeath03.mp3") //Death

PrecacheEntityFromTable({classname = "info_particle_system", effect_name = "ukgr_tachycardia_intro"})
PrecacheEntityFromTable({classname = "info_particle_system", effect_name = "ukgr_teleport_spellwheel"})
PrecacheEntityFromTable({classname = "info_particle_system", effect_name = "boss_halo"})
PrecacheEntityFromTable({classname = "ukgr_death_explosion", effect_name = "boss_halo"})

::bossCallbacks <- {
	ukgr = null

	Cleanup = function() {
		delete ::bossCallbacks
    }

	OnGameEvent_recalculate_holidays = function(_) {
		if(GetRoundState() == 3) {
			Cleanup()
		}
	}

	OnGameEvent_mvm_wave_complete = function(_) {
		Cleanup()
	}

	// OnGameEvent_mvm_wave_failed = function(_) {
	// 	for (local i = 1; i <= MaxPlayers ; i++)
	// 	{
	// 		local player = PlayerInstanceFromIndex(i)
	// 		if(player == null) continue
	// 		if(!IsPlayerABot(player)) continue
	// 		if(!player.HasBotTag("UKGR")) continue
	// 		ClientPrint(null,3,"Uh Oh Stinky")
	// 		player.Teleport(true, Vector(-2600, -871, 1493), false, QAngle(), false, Vector())
	// 		DispatchParticleEffect("ukgr_phase_change_flames", player.GetCenter(), Vector())
	// 		EmitSoundEx({
	// 			sound_name = "misc/halloween/spell_fireball_impact.wav",
	// 			channel = 6,
	// 			origin = player.GetCenter(),
	// 			filter_type = RECIPIENT_FILTER_GLOBAL
	// 		})
	// 	}
	// }

    OnGameEvent_player_spawn = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		if(player == null) return
		if(!IsPlayerABot(player)) return

        EntFireByHandle(player, "RunScriptCode", "bossCallbacks.checkTags()", -1, player, null)
	}

	checkTags = function() {
		if(!activator.HasBotTag("UKGR")) return
		ukgr = activator
		activator.ValidateScriptScope()
		IncludeScript("villa_boss.nut", activator.GetScriptScope())
	}

	/*
	OnGameEvent_player_hurt = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		if(player == null) return
		if(!IsPlayerABot(player)) return
        if(!player.HasBotTag("UKGR")) return
        player.GetScriptScope().damageTakenThisPhase = player.GetScriptScope().damageTakenThisPhase + params.damageamount
    }
	*/

	cleanupPhase1Support = function() { //if some of the phase 1 soldiers are still floating around
		local support = ukgr.GetScriptScope().support
		foreach(bot in support) {
			printl(bot)
			if(NetProps.GetPropInt(bot, "m_lifeState") == 0) {
				bot.TakeDamage(1000, 0, bot)
			}
		}
	}

	OnScriptHook_OnTakeDamage = function(params) { //may just put this in a separate namespace to throw out early
		if(params.const_entity != ukgr) return
		local scope = ukgr.GetScriptScope()
		//ClientPrint(null,3,"mainPhase: " + scope.mainPhase)
		if(scope.mainPhase == 3) return
		if(ukgr.GetHealth() <= params.damage) {
			scope.mainPhase++

			switch(scope.mainPhase) {
				case 2:
					foreach(player, datatable in losecond.players) {
						if(player.InCond(TF_COND_HALLOWEEN_GHOST_MODE)) {
							player.ForceRespawn()
							if(datatable.reanimEntity && datatable.reanimEntity.IsValid()) {
								datatable.reanimEntity.Kill();		
								datatable.reanimCount++;
							}
						}
					}
					delete ::phase1Callbacks
					if("offensiveThink" in scope.thinkTable) {
						delete scope.thinkTable.offensiveThink
					}
					else {
						delete scope.thinkTable.defensiveThink
					}
					if("phase1skinBuffThink" in scope.thinkTable) delete scope.thinkTable.phase1skinBuffThink
					//EntFire("pop_interface", "ChangeBotAttributes", "ShootPlayers", -1)
					Entities.FindByName(null, "pop_interface").AcceptInput("ChangeBotAttributes", "ShootPlayers", null, null)
					EntFire("gamerules", "runscriptcode", "bossCallbacks.cleanupPhase1Support()",  5)
					//self.AddCondEx(TF_COND_PREVENT_DEATH, -1, null)
					ukgr.RemoveWeaponRestriction(SECONDARY_ONLY)
					ukgr.RemoveCustomAttribute("damage bonus")
					ukgr.RemoveCustomAttribute("move speed bonus")
					ukgr.RemoveCondEx(TF_COND_CRITBOOSTED_USER_BUFF, true)
					ukgr.RemoveCondEx(TF_COND_HALLOWEEN_SPEED_BOOST, true)
					ukgr.RemoveBotAttribute(HOLD_FIRE_UNTIL_FULL_RELOAD)
				// case 3:
				// 	ClientPrint(null,3,"AWWW")
					local spawnbotOrigin = Entities.FindByName(null, "spawnbot_boss").GetOrigin()
					//local playerTeleportLocation = Vector(-2252, 2209, 579)

					EntFire("teleport_relay", "CancelPending")
					EntFire("teleport_player_to_arena" "AddOutput", "target roof_player_destination") //change this to roof for 2
					//EntFire("door_red_*", "Unlock", null, -1)

					ukgr.AddBotAttribute(SUPPRESS_FIRE)
					ukgr.AddCondEx((TF_COND_PREVENT_DEATH), -1, null)
					ukgr.GenerateAndWearItem("TF_WEAPON_SYRINGE_GUN_MEDIC")
					ukgr.AddCustomAttribute("max health additive bonus", 40000,  -1)
					ukgr.SetHealth(ukgr.GetMaxHealth())
					ukgr.Teleport(true, spawnbotOrigin, false, QAngle(), false, Vector())
					scope.thinkTable.finaleThink <- scope.finaleThink
					ukgr.RemoveBotAttribute(SUPPRESS_FIRE)
					//Disable altmode spawns to block tumors
					EntFire("spawnbot_altmode", "Disable", null, 5)
					EntFire("spawnbot_roof", "Enable", null, 10)
					//delete bossCallbacks.OnScriptHook_OnTakeDamage

					ScreenFade(null, 0, 0, 0, 255, 0.75, 1.5, 2) //fix timing
					for(local i = 1; i <= MaxPlayers ; i++) {
						local player = PlayerInstanceFromIndex(i)
						if(player == null) continue
						if(IsPlayerABot(player)) continue

						//player.Teleport(true, playerTeleportLocation, true, QAngle(0, -115, 0), false, Vector())
						EntFireByHandle(player, "runscriptcode", "self.Teleport(true, Vector(-2909, 3766, 2251), true, QAngle(2, -42.31, 0), false, Vector())",
							1, null, null)
					}
					break
				case 3:
					DispatchParticleEffect("ukgr_death_explosion", ukgr.GetCenter(), Vector())
					ukgr.AddCustomAttribute("dmg taken increased", 0.00001, -1)
					ukgr.AddCustomAttribute("move speed penalty", 0.000001, -1)
					ukgr.AddCustomAttribute("increased jump height", 0.000001, -1)
					ukgr.AddBotAttribute(SUPPRESS_FIRE)
					//prevent phase from advancing or smth
					for(local i = 1; i <= MaxPlayers ; i++) {
						local player = PlayerInstanceFromIndex(i)
						if(player == null) continue
						if(IsPlayerABot(player)) continue

						player.AddCustomAttribute("dmg taken increased", -0.01, -1)
					}
					scope.isExploding = true
					ukgr.RemoveCond(TF_COND_PREVENT_DEATH)
					EntFireByHandle(ukgr, "RunScriptCode", "playEmitSoundEx(`vo/mvm/norm/medic_mvm_paincrticialdeath03.mp3`, true)", 0, ukgr, ukgr)
					EntFireByHandle(ukgr, "RunScriptCode", "playEmitSoundEx(`ambient/explosions/explode_1.wav`)", 0, ukgr, ukgr)
					EntFireByHandle(ukgr, "RunScriptCode", "playEmitSoundEx(`ambient/levels/labs/electric_explosion1.wav`)", 0.4, ukgr, ukgr)
					EntFireByHandle(ukgr, "RunScriptCode", "playEmitSoundEx(`ambient/explosions/explode_4.wav`)", 0.8, ukgr, ukgr)
					EntFireByHandle(ukgr, "RunScriptCode", "playEmitSoundEx(`ambient/levels/labs/electric_explosion2.wav`)", 1.2, ukgr, ukgr)
					EntFireByHandle(ukgr, "RunScriptCode", "playEmitSoundEx(`ambient/explosions/explode_5.wav`)", 1.6, ukgr, ukgr)
					EntFireByHandle(ukgr, "RunScriptCode", "playEmitSoundEx(`ambient/levels/labs/electric_explosion3.wav`)", 2.0, ukgr, ukgr)
					EntFireByHandle(ukgr, "RunScriptCode", "playEmitSoundEx(`ambient/explosions/explode_7.wav`)", 2.4, ukgr, ukgr)
					EntFireByHandle(ukgr, "RunScriptCode", "playEmitSoundEx(`ambient/levels/labs/electric_explosion4.wav`)", 2.8, ukgr, ukgr)
					EntFireByHandle(ukgr, "RunScriptCode", "playEmitSoundEx(`ambient/explosions/explode_8.wav`)", 3.2, ukgr, ukgr)
					EntFireByHandle(ukgr, "RunScriptCode", "playEmitSoundEx(`ambient/levels/labs/electric_explosion5.wav`)", 3.6, ukgr, ukgr)
					EntFireByHandle(ukgr, "RunScriptCode", "playEmitSoundEx(`misc/doomsday_missile_explosion.wav`, true)", 4.0, ukgr, ukgr)
					EntFireByHandle(ukgr, "RunScriptCode", "playEmitSoundEx(`mvm/mvm_tank_explode.wav`, true)", 4.0, ukgr, ukgr)
					EntFireByHandle(ukgr, "RunScriptCode", "ScreenFade(null, 230, 230, 230, 255, 1, 4.5, 2)", 4, ukgr, ukgr)
					// EntFireByHandle(ukgr, "RunScriptCode", "bossSuicide()", 5.1, ukgr, ukgr)
					EntFireByHandle(ukgr, "RunScriptCode", "self.Teleport(true, Vector(-2600, -871, 1493), false, QAngle(), false, Vector())", 5.0, ukgr, ukgr)
					EntFireByHandle(ukgr, "RunScriptCode", "self.AddCustomAttribute(`health drain`, -9999, -1)", 5.1, ukgr, ukgr)
					EntFireByHandle(ukgr, "RunScriptCode", "self.AddCustomAttribute(`dmg taken increased`, 10, -1)", 5.1, ukgr, ukgr)
					EntFireByHandle(ukgr, "RunScriptCode", "self.TakeDamage(990000,0,self)", 5.1, ukgr, ukgr)
					break
			}
			params.early_out = true
		}
	}

	OnGameEvent_player_death = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		if(player == null) return
		if(!IsPlayerABot(player)) {
			local randomVoice = RandomInt(0,2)
			switch(randomVoice) {
				case 0:
					playEmitSoundEx("vo/mvm/norm/medic_mvm_laughevil01.mp3", true)
					break
				case 1:
					playEmitSoundEx("vo/mvm/norm/medic_mvm_laughshort01.mp3", true)
					break
				case 2:
					playEmitSoundEx("vo/mvm/norm/medic_mvm_laughshort02.mp3", true)
					break
				default:
					break
			}
			return
		}
        if(!player.HasBotTag("UKGR_Tumor")) return
		ukgr.GetScriptScope().deadTumorCounter++
		if(ukgr.GetHealth() >= 500) ukgr.TakeDamageEx(ukgr, ukgr, null, Vector(1, 0, 0), ukgr.GetCenter(), 150, DMG_BLAST)
    }
}
__CollectGameEventCallbacks(bossCallbacks)

::reduceToOneHP <- function() {
	if(ukgr == null) return
	if(IsPlayerABot(self)) return
	if(self.GetHealth() <= 5) return
	self.SetHealth(1)
}

::playEmitSoundEx <- function(soundName, dontRepeat=false) {
	EmitSoundEx({
		sound_name = soundName,
		channel = 6,
		origin = self.GetCenter(),
		filter_type = RECIPIENT_FILTER_GLOBAL
	})

	if(dontRepeat) return

	EmitSoundEx({
		sound_name = soundName,
		channel = 6,
		origin = self.GetCenter(),
		filter_type = RECIPIENT_FILTER_GLOBAL
	})
}

// ::bossSuicide <- function() {
// 	for(local i = 1; i <= MaxPlayers ; i++) {
// 		local player = PlayerInstanceFromIndex(i)
// 		if(player == null) continue
// 		if(!IsPlayerABot(player)) continue
// 		if(!player.HasBotTag("UKGR")) continue

// 		player.AddCustomAttribute("health drain", -9999, -1)
// 		player.AddCustomAttribute("dmg taken increased", 10, -1)
// 		player.TakeDamage(990000000, 0, player)
// 	}
// }

::bossDisappear <- function() {
	for (local i = 1; i <= MaxPlayers ; i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if(player == null) continue
		if(!IsPlayerABot(player)) continue
		if(!player.HasBotTag("UKGR")) continue
		player.Teleport(true, Vector(-2600, -871, 1493), false, QAngle(), false, Vector())
		DispatchParticleEffect("ukgr_phase_change_flames", player.GetCenter(), Vector())
		EmitSoundEx({
			sound_name = "misc/halloween/spell_fireball_impact.wav",
			channel = 6,
			origin = player.GetCenter(),
			filter_type = RECIPIENT_FILTER_GLOBAL
		})
	}
}