::objRes <- Entities.FindByClassname(null, "tf_objective_resource")

InputFireUser1 <- function() { //this essentially only fires once, then the callbacks should do everything else
	__CollectGameEventCallbacks(hardCallbacks)
	EntFire("pop_interface", "ChangeDefaultEventAttributes", "HardMode", -1)
	hardCallbacks.updateHardModeWavebar(1)
	difficultyNamespace = hardCallbacks
	objRes.AcceptInput("$SetClientProp$m_iszMvMPopfileName", "(exp) forget", null, null)
	return true
}

::normalNamespace <- {
	finaleWaveInit = function() {
		EntFire("spawnbot_roof", "Disable")
		EntFire("spawnbot", "Disable")
		EntFire("spawnbot_invasion", "Disable")
		EntFire("spawnbot_right", "Disable")
		EntFire("altmode_init_reviveonly_relay", "Trigger")
	}
	
	finaleWaveStart = function() {
		const BOTCOUNT = 18
		IncludeScript("villa_waves.nut", getroottable())
		winCondCallbacks.setBotCount(BOTCOUNT)
		IncludeScript("diseasebots.nut", getroottable())
		IncludeScript("villa_boss_callbacks.nut", getroottable())

		EntFire("altmode_arena2_wave_start_reviveonly_relay", "Trigger")
		EntFire("sniper_*", "Disable")
		EntFire("roof_sniper_*", "Enable")
	}
	
	//icon stuff
	if(waveNumber == null) {
			waveNumber = NetProps.GetPropInt(objRes, "m_nMannVsMachineWaveCount")
		}
		local function setIcon(name, index) {
			NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", name, index)
		}
		local function setFlag(flag, index) {
			NetProps.SetPropIntArray(objRes, "m_iszMannVsMachineWaveClassFlags", flag, index)
		}
		local function setActive(isActive, index) {
			NetProps.SetPropBoolArray(objRes, "m_iszMannVsMachineWaveClassActive", isActive, index)
		}
		local function setCount(count, index) {
			NetProps.SetPropIntArray(objRes, "m_iszMannVsMachineWaveClassCounts", count, index)
		}
		
		switch(waveNumber) {
			case 4:
				//Index 0 to support pathogen
				//Index 1 to 5 dyspnea
				//Index 2 to 2 sarcoma
				//Index 3 to 8 tachycardia
				//Index 4 to 32 tumors
				//Index 5 to 2 pneumonia
				setIcon("blackdead", 0)
				setFlag(2, 0)
				setActive(true, 0)
				setIcon("dyspnea_bp", 1)
				setFlag(1, 1)
				setActive(true, 1)
				setCount(5, 1)
				setIcon("sarcoma_bp", 2)
				setFlag(1, 2)
				setActive(true, 2)
				setCount(2, 2)
				setIcon("tachycardia_bp", 3)
				setFlag(1, 3)
				setActive(true, 3)
				setCount(8, 3)
				setIcon("malignant_tumor_bp", 4)
				setFlag(1, 4)
				setActive(true, 4)
				setCount(32, 4)
				setIcon("pneumonia_bp", 5)
				setFlag(1, 5)
				setActive(true, 5)
				setCount(2, 5)
				break
			case 7:
				setIcon("ukgr", 0)
				setFlag(9, 0)
				setActive(true, 0)
				setCount(1, 0)
				setIcon("scout", 1)
				setFlag(18, 0)
				setActive(true, 0)
				setCount(1, 0)
				setIcon("sniper_sydney", 1)
				setFlag(20, 0)
				setActive(true, 0)
				setCount(1, 0)
				setIcon("spy", 1)
				setFlag(20, 0)
				setActive(true, 0)
				setCount(1, 0)
				break
			default:
				break
		}
}
::difficultyNamespace <- normalNamespace

::hardCallbacks <- {
	Cleanup = function() {
		delete ::hardCallbacks
	}
	
	OnGameEvent_recalculate_holidays = function(_) {
		if(GetRoundState() == 3) {
			local objRes = Entities.FindByClassname(null, "tf_objective_resource")
			local wave = NetProps.GetPropInt(objRes, "m_nMannVsMachineWaveCount")
		
			if(wave == 1) {
				Cleanup()
			}
			else {
				EntFire("pop_interface", "ChangeDefaultEventAttributes", "HardMode", -1)
				updateHardModeWavebar(wave)
			}
		}
	}
	
	OnGameEvent_player_spawn = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		if(player == null) return
		if(!IsPlayerABot(player)) return
		
		EntFireByHandle(player, "hardCallbacks.checkTags()", null, -1, player, null)
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
	
	updateHardModeWavebar = function(waveNumber = null) {
		if(!isHardmode) return
		if(waveNumber == null) {
			waveNumber = NetProps.GetPropInt(objRes, "m_nMannVsMachineWaveCount")
		}
		local function setIcon(name, index) {
			NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", name, index)
		}
		local function setFlag(flag, index) {
			NetProps.SetPropIntArray(objRes, "m_iszMannVsMachineWaveClassFlags", flag, index)
		}
		local function setActive(isActive, index) {
			NetProps.SetPropBoolArray(objRes, "m_iszMannVsMachineWaveClassActive", isActive, index)
		}
		local function setCount(count, index) {
			NetProps.SetPropIntArray(objRes, "m_iszMannVsMachineWaveClassCounts", count, index)
		}
		
		switch(waveNumber) {
			case 1:
				//Index 2 Gsoldier to soldier_spammer
				//Index 3 Samurai to crits (16 crits + 1 main wave)
				//Index 5 Gscout to scout_fast
				setIcon("soldier_spammer", 2)
				setFlag(17, 3)
				setIcon("scout_fast", 5)
				break
			case 2:
				//Index 2 to spies, active support (2)
				setIcon("spy", 2)
				setFlag(2, 2)
				setActive(true, 2)
				break
			case 3:
				//Index 1 burst demos to crits (16 crits + 1 main wave)
				//Index 4 medics to medic_uber_shield_lite
				//Index 7 gbows to sniper_bow_multi_bleed
				setFlag(17, 1)
				setIcon("medic_uber_shield_lite", 4)
				setIcon("sniper_bow_multi_bleed", 7)
				break
			case 4:
				//Index 0 to support pathogen
				//Index 1 to 5 dyspnea
				//Index 2 to 2 sarcoma
				//Index 3 to 8 tachycardia
				//Index 4 to 32 tumors
				//Index 5 to 2 pneumonia
				setIcon("blackdead", 0)
				setFlag(2, 0)
				setActive(true, 0)
				setIcon("dyspnea_bp", 1)
				setFlag(1, 1)
				setActive(true, 1)
				setCount(5, 1)
				setIcon("sarcoma_bp", 2)
				setFlag(1, 2)
				setActive(true, 2)
				setCount(2, 2)
				setIcon("tachycardia_bp", 3)
				setFlag(1, 3)
				setActive(true, 3)
				setCount(8, 3)
				setIcon("malignant_tumor_bp", 4)
				setFlag(1, 4)
				setActive(true, 4)
				setCount(32, 4)
				setIcon("pneumonia_bp", 5)
				setFlag(1, 5)
				setActive(true, 5)
				setCount(2, 5)
				break
			case 5:
				//Index 3 furies to crits (16 crits + 1 main wave)
				//Index 5 gheavies to crits (16 crits + 1 main wave)
				setFlag(25, 3)
				setFlag(25, 5)
				break
			default:
				break	
		}

		//Add pentagram icon
		NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames2", "pentagram", 11)
		NetProps.SetPropIntArray(objRes, "m_iszMannVsMachineWaveClassFlags2", 2, 11)
		NetProps.SetPropBoolArray(objRes, "m_iszMannVsMachineWaveClassActive2", true, 11)
	}
	
	finaleWaveInit = function() {
		EntFire("spawnbot_roof", "Disable")
		EntFire("pop_interface", "ChangeDefaultEventAttributes", "HardMode", -1)
		EntFire("spawnbot_arena2", "Disable")
		EntFire("intel", "Enable", null, 0.5)
		EntFire("bombpath_choose_relay", "Trigger")
	}

	finaleWaveStart = function() {
		const BOTCOUNT = 37
		IncludeScript("villa_waves.nut", getroottable())
		winCondCallbacks.setBotCount(BOTCOUNT)
		IncludeScript("diseasebots.nut", getroottable())
		IncludeScript("villa_boss_callbacks.nut", getroottable())

		EntFire("wave_start_relay", "Trigger")
	}
}