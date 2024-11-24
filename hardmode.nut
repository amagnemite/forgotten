InputFireUser1 <- function() { //this essentially only fires once, then the callbacks should do everything else
	__CollectGameEventCallbacks(hardWaveCallbacks)
	EntFire("pop_interface", "ChangeDefaultEventAttributes", "HardMode", -1)
	//update w1 icons here
	return true
}

::hardWaveCallbacks <- {
	Cleanup = function() {
		local objRes = Entities.FindByClassname(null, "tf_objective_resource")
		local wave = NetProps.GetPropInt(objRes, "m_nMannVsMachineWaveCount")
		if(wave == 1) {
			delete ::hardWaveCallbacks
		}
	}
	
	OnGameEvent_recalculate_holidays = function(_) {
		if(GetRoundState() == 3) {
			Cleanup()
		}
	}
	
	OnGameEvent_player_spawn = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		if(player == null) return
		if(!IsPlayerABot(player)) return
		
		EntFireByHandle(player, "hardWaveCallbacks.checkTags()", null, -1, player, null)
	}
	
	checkTags = function() {
		local tags = {}
		activator.GetAllBotTags(tags)
		
		foreach(k, tag in tags) {
			tag = tag.tolower()
			
			if(startswith(tag, "name_")) {
				local chunks = split(tag.slice(5), "_")
				local final = ""
				for(local i = 0; i < chunks.len(); i++) {
					local chunk = chunks[i]
					local titlecase = chunk.splice(0, 1).toupper() + chunk.splice(1)
					final = final + titlecase
					if(i + 1 < chunks.len()) {
						final = final + " "
					}
				}
				SetFakeClientConVarValue(activator, "name", final)
			}
			else if(startswith(tag, "icon_")) {
				local icon = tag.slice(5)
				NetProps.SetPropString(activator, "m_PlayerClass.m_iszClassIcon", icon)
			}
		}
	}
	
	//do icon stuff here
}

::finaleCallbacks <- {
	normalKill = null
	hardKill = null
	//TOTALCOUNT = 37
	botCount = 37

	Cleanup = function() {
		delete ::finaleCallbacks
	}

	OnGameEvent_recalculate_holidays = function(_) {
		if(GetRoundState() == 3) {
			Cleanup()
		}
	}

	OnGameEvent_mvm_wave_complete = function(_) {
		Cleanup()
	}

	OnGameEvent_player_spawn = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		if(player == null) return
		if(!IsPlayerABot(player)) return
		
		EntFireByHandle(player, "finaleCallbacks.checkTags()", null, -1, player, null)
	}
	
	checkTags = function() {
		if(activator.HasBotTag("theendnormal")) {
			normalKill = activator
			if(hardmode) {
				normalKill.TakeDamage(1000, 0, null)
			}
		}
		else if(activator.HasBotTag("theendhard")) {
			hardKill = activator
			if(!hardmode) {
				hardKill.TakeDamage(1000, 0, null)
			}
		}
	}
	
	OnGameEvent_player_death = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		if(player == null) return
		if(!IsPlayerABot(player)) return
		if(player.HasBotTag("ignoredeath")) return
		
		if(player.HasBotTag("ukgr") && !hardmode) {
			normalKill.TakeDamage(1000, 0, null)
			return //the end
		}
		
		botCount--
		
		if(botCount == 0) {
			hardKill.TakeDamage(1000, 0, null)
		}
	}
}

finaleWaveInit <- function() {
	EntFire("spawnbot_roof", "Disable")

	if(hardmode) {
		EntFire("pop_interface", "ChangeDefaultEventAttributes", "HardMode", -1)
		EntFire("spawnbot_arena2", "Disable")
		
		EntFire("intel", "Enable", null, 0.5)
		
		EntFire("bombpath_choose_relay", "Trigger")
	}
	else {
		EntFire("spawnbot", "Disable")
		EntFire("spawnbot_invasion", "Disable")
		EntFire("spawnbot_right", "Disable")
		
		EntFire("altmode_init_reviveonly_relay", "Trigger")
	}
}

finaleWaveStart <- function() {
	__CollectGameEventCallbacks(finaleCallbacks)
	IncludeScript("diseasebots.nut", getroottable())
	IncludeScript("villa_boss_callbacks.nut", getroottable())

	if(hardmode) {
		EntFire("wave_start_relay", "Trigger")
	}
	else {
		EntFire("altmode_arena2_wave_start_reviveonly_relay", "Trigger")
		EntFire("sniper_*", "Disable")
		EntFire("roof_sniper_*", "Enable")
	}
}