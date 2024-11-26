::objRes <- Entities.FindByClassname(null, "tf_objective_resource")

InputFireUser1 <- function() { //this essentially only fires once, then the callbacks should do everything else
	__CollectGameEventCallbacks(hardCallbacks)
	EntFire("pop_interface", "ChangeDefaultEventAttributes", "HardMode", -1)
	hardCallbacks.updateWavebar()
	difficultyNamespace = hardCallbacks
	objRes.AcceptInput("$SetClientProp$m_iszMvMPopfileName", "(exp) under the bonesaw", null, null)
	return true
}

::normalNamespace <- {
	finaleWaveInit = function() {
		EntFire("spawnbot_roof", "Disable")
		EntFire("spawnbot", "Disable")
		EntFire("spawnbot_invasion", "Disable")
		EntFire("spawnbot_right", "Disable")
		EntFire("altmode_init_reviveonly_relay", "Trigger")
		updateWavebar()
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
	updateWavebar = function() {
		local waveNumber = NetProps.GetPropInt(objRes, "m_nMannVsMachineWaveCount")
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
				//Index 6 to 5 cardiomyopathy (demo_burst)
				setIcon("blackdead", 0)
				setFlag(2, 0)
				setActive(true, 0)
				setIcon("dyspnea_bp", 1)
				setFlag(9, 1)
				setActive(true, 1)
				setCount(5, 1)
				setIcon("sarcoma_bp", 2)
				setFlag(9, 2)
				setActive(true, 2)
				setCount(2, 2)
				setIcon("tachycardia_bp", 3)
				setFlag(9, 3)
				setActive(true, 3)
				setCount(8, 3)
				setIcon("malignant_tumor_bp", 4)
				setFlag(1, 4)
				setActive(true, 4)
				setCount(32, 4)
				setIcon("pneumonia_bp", 5)
				setFlag(9, 5)
				setActive(true, 5)
				setCount(2, 5)
				setIcon("demo_burst", 6)
				setFlag(9, 6)
				setActive(true, 6)
				setCount(5, 6)
				break
			case 7:
				//setIcon("ukgr", 0)
				//setFlag(9, 0)
				//setActive(true, 0)
				//setCount(1, 0)
				setIcon("blackdead", 1)
				setFlag(1, 1)
				setActive(true, 1)
				setCount(17, 1)
				setIcon("scout", 2)
				setFlag(18, 2)
				setActive(true, 2)
				setCount(1, 2)
				setIcon("sniper_sydney", 3)
				setFlag(20, 3)
				setActive(true, 3)
				setCount(1, 3)
				setIcon("spy", 4)
				setFlag(20, 4)
				setActive(true, 4)
				setCount(1, 4)
				break
			default:
				break
		}
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
				objRes.AcceptInput("$SetClientProp$m_iszMvMPopfileName", "(exp) under the bonesaw", null, null)
				EntFire("pop_interface", "ChangeDefaultEventAttributes", "HardMode", -1)
				updateWavebar()
			}
		}
	}
	
	OnGameEvent_player_spawn = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		if(player == null) return
		if(!IsPlayerABot(player)) return
		
		EntFireByHandle(player, "RunScriptFile", "hardCallbacks.checkTags()", -1, player, null)
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
	
	updateWavebar = function() {
		local waveNumber = NetProps.GetPropInt(objRes, "m_nMannVsMachineWaveCount")
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
				setIcon("timer_pink", 3)
				setFlag(2, 3)
				setActive(true, 3)
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
				//Index 6 to 5 cardiomyopathy
				setIcon("blackdead", 0)
				setFlag(2, 0)
				setActive(true, 0)
				setIcon("dyspnea_bp", 1)
				setFlag(9, 1)
				setActive(true, 1)
				setCount(5, 1)
				setIcon("sarcoma_bp", 2)
				setFlag(9, 2)
				setActive(true, 2)
				setCount(2, 2)
				setIcon("tachycardia_bp", 3)
				setFlag(9, 3)
				setActive(true, 3)
				setCount(8, 3)
				setIcon("malignant_tumor_bp", 4)
				setFlag(1, 4)
				setActive(true, 4)
				setCount(32, 4)
				setIcon("pneumonia_bp", 5)
				setFlag(9, 5)
				setActive(true, 5)
				setCount(2, 5)
				setIcon("demo_burst", 6)
				setFlag(9, 6)
				setActive(true, 6)
				setCount(5, 6)
				break
			case 5:
				//Index 3 furies to crits (16 crits + 1 main wave)
				//Index 5 gheavies to crits (16 crits + 1 main wave)
				setFlag(25, 3)
				setFlag(25, 5)
				break
			case 7:
				//setIcon("ukgr", 0)
				//setFlag(9, 0)
				//setActive(true, 0)
				//setCount(1, 0)
				/*
				setIcon("dyspnea_bp", 1)
				setFlag(25, 1)
				setActive(true, 1)
				setCount(16, 1)
				
				setIcon("hemorrhagic_fever_bp", 2)
				setFlag(25, 2)
				setActive(true, 2)
				setCount(9, 2)
				setIcon("tank", 3)
				setFlag(9, 3)
				setActive(true, 3)
				setCount(1, 3)
				setIcon("demo_burst", 4)
				setFlag(9, 4)
				setActive(true, 4)
				setCount(12, 4)
				setIcon("tachycardia_bp", 5)
				setFlag(9, 5)
				setActive(true, 5)
				setCount(8, 5)
				setIcon("sarcoma_bp", 6)
				setFlag(9, 6)
				setActive(true, 6)
				setCount(4, 6)
				setIcon("pneumonia_bp", 7)
				setFlag(9, 7)
				setActive(true, 7)
				setCount(4, 7)
				setIcon("malignant_tumor_bp", 8)
				setFlag(2, 8)
				setActive(true, 8)
				setCount(1, 8)
				setIcon("engineer", 9)
				setFlag(2, 9)
				setActive(true, 9)
				setCount(1, 9)
				setIcon("spy", 10)
				setFlag(4, 10)
				setActive(true, 10)
				setCount(1, 10)
				setIcon("sniper_sydney", 11)
				setFlag(4, 11)
				setActive(true, 11)
				setCount(1, 11)
				*/
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
		updateWavebar()
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