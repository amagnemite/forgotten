IncludeScript("customweaponsvillaedit.nut", getroottable())

PrecacheSound("misc/halloween/spell_fireball_impact.wav")
PrecacheEntityFromTable({classname = "info_particle_system", effect_name = "ukgr_tachycardia_intro"})
PrecacheEntityFromTable({classname = "info_particle_system", effect_name = "ukgr_teleport_spellwheel"})
PrecacheEntityFromTable({classname = "info_particle_system", effect_name = "boss_halo"})

::bossCallbacks <- {
	ukgr = null

	Cleanup = function() {
		EntFire("boss_halo_*","SetParent","")
		EntFire("boss_halo_*","AddOutput","origin 0 0 0")
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

	/*
	OnGameEvent_mvm_wave_failed = function(_) {
		EntFire("boss_halo_*","SetParent","")
		EntFire("boss_halo_*","AddOutput","origin 0 0 0")
	}
	*/

    OnGameEvent_player_spawn = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		if(player == null) return
		if(!IsPlayerABot(player)) return

        EntFireByHandle(player, "RunScriptCode", "bossCallbacks.checkTags()", -1, player, null)
	}

	checkTags = function() {
		if(!activator.HasBotTag("UKGR")) return
		activator.ValidateScriptScope()
		activator.AcceptInput("RunScriptFile", "villa_boss.nut", null, null)
		
		//IncludeScript("villa_boss.nut", activator.GetScriptScope())
		ukgr = activator
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

	cleanupPhase1Support = function() {
		local support = ukgr.GetScriptScope().support
		foreach(bot in support) {
			if(NetProps.GetPropInt(bot, "m_iLifeState") == 0) {
				bot.TakeDamage(1000, 0, self)
			}
		}
	}

	OnScriptHook_OnTakeDamage = function(params) {
		if(params.const_entity != ukgr) return
		if(ukgr.GetHealth() <= params.damage * 3.1) {
			local scope = ukgr.GetScriptScope()
			scope.mainPhase++

			switch(scope.mainPhase) {
				case 2:
					delete phase1Callbacks
					if("offensiveThink" in scope.thinkTable) {
						delete scope.thinkTable.offensiveThink
					}
					else {
						delete scope.thinkTable.defensiveThink
					}
					EntFire("pop_interface", "ChangeBotAttributes", "ShootPlayers", -1)
					EntFire("gamerules", "runscriptcode", "cleanupPhase1Support",  5)
					//self.AddCondEx((TF_COND_PREVENT_DEATH) , -1, null)
				case 3:
					ukgr.AddCustomAttribute("max health additive bonus", 25000,  -1)
					teleportToSpawn() //maybe add sound effect
					scope.thinkTable.finaleThink <- scope.finaleThink
					//Disable altmode spawns to block tumors
					EntFire("spawnbot_altmode", "Disable", null, 5)
					delete bossCallbacks.OnScriptHook_OnTakeDamage
					break
			}
		}
		params.early_out = true
	}

	OnGameEvent_player_death = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		if(player == null) return
		if(!IsPlayerABot(player)) return
        if(!player.HasBotTag("UKGR_Tumor")) return
        for (local i = 1; i <= MaxPlayers ; i++)
        {
            ukgr.GetScriptScope().deadTumorCounter++
			ukgr.TakeDamageEx(ukgr, ukgr, null, Vector(1, 0, 0), ukgr.GetCenter(), 125, DMG_BLAST)
        }
    }
}
__CollectGameEventCallbacks(bossCallbacks)

/*
::addPneumoniaStickyThink <- function() {
	//ClientPrint(null, 3, "STICKY THINK ADDED!!")
	self.SetModelSimple("models/villa/stickybomb_pneumonia.mdl")
	stickyTimer <- 0
	stickyThink <- function() {
		if(stickyTimer == 1.5) {
			DispatchParticleEffect("pneumonia_stickybomb_aura", self.GetCenter(), Vector())
		}

		if(!pneumoniaSpawner.IsValid()) return //mostly for wave reset
		else if(stickyTimer >= 4) {
			//Explode and create pneumonia clouds
			pneumoniaSpawner.SpawnEntityAtLocation(self.GetOrigin() + Vector(-192, 0, 0), Vector(0,0,0))
			NetProps.GetPropEntity(self, "m_hThrower").PressAltFireButton(0.1)
		}
		stickyTimer += 0.5
		return 0.5
	}
	AddThinkToEnt(self, "stickyThink")
}
*/
