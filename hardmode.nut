::objRes = Entities.FindByClassname(null, "tf_objective_resource")

::updateHardModeWavebar <- function() {
	if(!isHardmode) return
	local waveNumber = NetProps.GetPropInt(objRes, "m_nMannVsMachineWaveCount")
	switch(waveNumber) {
		case 1:
			//Index 2 Gsoldier to soldier_spammer
			//Index 3 Samurai to crits (16 crits + 1 main wave)
			//Index 5 Gscout to scout_fast
			NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", "soldier_spammer", 2)
			NetProps.SetPropIntArray(objRes, "m_iszMannVsMachineWaveClassFlags", 17, 3)
			NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", "scout_fast", 5)
			break
		case 2:
			//Index 2 to spies, active support (2)
			NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", "spy", 2)
			NetProps.SetPropIntArray(objRes, "m_iszMannVsMachineWaveClassFlags", 2, 2)
			NetProps.SetPropBoolArray(objRes, "m_iszMannVsMachineWaveClassActive", true, 2)
			break
		case 3:
			//Index 1 burst demos to crits (16 crits + 1 main wave)
			//Index 4 medics to medic_uber_shield_lite
			//Index 7 gbows to sniper_bow_multi_bleed
			NetProps.SetPropIntArray(objRes, "m_iszMannVsMachineWaveClassFlags", 17, 1)
			NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", "medic_uber_shield_lite", 4)
			NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", "sniper_bow_multi_bleed", 7)
			break
		case 4:
			//Index 0 to support pathogen
			//Index 1 to 5 dyspnea
			//Index 2 to 2 sarcoma
			//Index 3 to 8 tachycardia
			//Index 4 to 32 tumors
			//Index 5 to 2 pneumonia
			NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", "blackdead", 0)
			NetProps.SetPropIntArray(objRes, "m_iszMannVsMachineWaveClassFlags", 2, 0)
			NetProps.SetPropBoolArray(objRes, "m_iszMannVsMachineWaveClassActive", true, 0)
			NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", "dyspnea_bp", 1)
			NetProps.SetPropIntArray(objRes, "m_iszMannVsMachineWaveClassFlags", 1, 1)
			NetProps.SetPropBoolArray(objRes, "m_iszMannVsMachineWaveClassActive", true, 1)
			NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", "sarcoma_bp", 2)
			NetProps.SetPropIntArray(objRes, "m_iszMannVsMachineWaveClassFlags", 1, 2)
			NetProps.SetPropBoolArray(objRes, "m_iszMannVsMachineWaveClassActive", true, 2)
			NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", "tachycardia_bp", 3)
			NetProps.SetPropIntArray(objRes, "m_iszMannVsMachineWaveClassFlags", 1, 3)
			NetProps.SetPropBoolArray(objRes, "m_iszMannVsMachineWaveClassActive", true, 3)
			NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", "malignant_tumor_bp", 4)
			NetProps.SetPropIntArray(objRes, "m_iszMannVsMachineWaveClassFlags", 1, 4)
			NetProps.SetPropBoolArray(objRes, "m_iszMannVsMachineWaveClassActive", true, 4)
			NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", "pneumonia_bp", 5)
			NetProps.SetPropIntArray(objRes, "m_iszMannVsMachineWaveClassFlags", 1, 5)
			NetProps.SetPropBoolArray(objRes, "m_iszMannVsMachineWaveClassActive", true, 5)
			break
		case 5:
			//Index 3 furies to crits (16 crits + 1 main wave)
			//Index 5 gheavies to crits (16 crits + 1 main wave)
			NetProps.SetPropIntArray(objRes, "m_iszMannVsMachineWaveClassFlags", 17, 3)
			NetProps.SetPropIntArray(objRes, "m_iszMannVsMachineWaveClassFlags", 17, 5)
			break
		default:
			break	
	}

	//Add pentagram icon
	NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames2", "pentagram", 11)
	NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassFlags2", 2, 11)
	NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassActive2", true, 11)
}

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