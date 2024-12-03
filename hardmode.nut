::objRes <- Entities.FindByClassname(null, "tf_objective_resource")

InputFireUser1 <- function() { //this essentially only fires once, then the callbacks should do everything else
	local names = ["under the bonesaw", "oblivion"]
	::expName <- names[RandomInt(0, 1)]
	__CollectGameEventCallbacks(hardCallbacks)
	EntFire("pop_interface", "ChangeDefaultEventAttributes", "HardMode", -1)
	hardCallbacks.updateWavebar()
	difficultyNamespace = hardCallbacks
	objRes.AcceptInput("$SetClientProp$m_iszMvMPopfileName", "(exp) " + expName, null, null)
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

	updateWavebar = function() {
		local waveNumber = NetProps.GetPropInt(objRes, "m_nMannVsMachineWaveCount")
		local function setWavebar(wave) {
			foreach(name, data in normalNamespace[wave]) {
				NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", name, data.index)
				NetProps.SetPropIntArray(objRes, "m_nMannVsMachineWaveClassFlags", data.flag, data.index)
				if(data.totalCount != null) {
					NetProps.SetPropIntArray(objRes, "m_nMannVsMachineWaveClassCounts", data.totalCount, data.index)
				}
			}
		}

		switch(waveNumber) {
			case 4:
				//Index 0 to support pathogen
				//Index 1 to 5 dyspnea
				//Index 2 to 2 sarcoma
				//Index 3 to 8 tachycardia
				//Index 4 to 42 tumors
				//Index 5 to 2 pneumonia
				//Index 6 to 5 cardiomyopathy (demo_burst)
				NetProps.SetPropInt(objRes, "m_nMannVsMachineWaveEnemyCount", 64)
				setWavebar(4)
				break
			case 7:
				NetProps.SetPropInt(objRes, "m_nMannVsMachineWaveEnemyCount", 18)
				setWavebar(7)
				break
			default:
				break
		}
	}
}
normalNamespace[4] <- {
	blackdead = {index = 0, flag = 2, totalCount = null}
	dyspnea_bp = {index = 1, flag = 8, totalCount = 5}
	sarcoma_bp = {index = 2, flag = 8, totalCount = 2}
	tachycardia_bp = {index = 3, flag = 8, totalCount = 8}
	malignant_tumor_bp = {index = 4, flag = 1, totalCount = 42}
	pneumonia_bp = {index = 5, flag = 8, totalCount = 2}
	demo_burst = {index = 6, flag = 8, totalCount = 5}
}
normalNamespace[7] <- {
	blackdead = {index = 1, flag = 1, totalCount = 17}
	scout = {index = 2, flag = 18, totalCount = null}
	sniper_sydneysleeper = {index = 3, flag = 20, totalCount = null}
	spy = {index = 4, flag = 20, totalCount = null}
}

::difficultyNamespace <- normalNamespace

::hardCallbacks <- {
	OnGameEvent_recalculate_holidays = function(_) {
		if(GetRoundState() == 3) {
			local objRes = Entities.FindByClassname(null, "tf_objective_resource")
			local wave = NetProps.GetPropInt(objRes, "m_nMannVsMachineWaveCount")

			if(wave == 1) {
				objRes.AcceptInput("$ResetClientProp$m_iszMvMPopfileName", null, null, null)
				EntFire("pentagram_sky_prop", "Disable")
				delete ::hardCallbacks
			}
			else {
				EntFire("pop_interface", "ChangeDefaultEventAttributes", "HardMode", -1)
				EntFire("pentagram_env_init", "Trigger")
			}
		}
	}

	OnGameEvent_player_spawn = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		if(player == null) return
		if(!IsPlayerABot(player)) return

		EntFireByHandle(player, "RunScriptCode", "hardCallbacks.checkTags()", -1, player, null)
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
					local titlecase = chunk.slice(0, 1).toupper() + chunk.slice(1)
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
			else if(startswith(tag, "health_")) {
				local newHealth = tag.slice(7).tointeger()
				activator.AddCustomAttribute("max health additive bonus", newHealth - activator.GetMaxHealth(), -1)
				activator.SetHealth(activator.GetMaxHealth())
			}
		}
		local wave = NetProps.GetPropInt(Entities.FindByClassname(null, "tf_objective_resource"), "m_nMannVsMachineWaveCount")
		if(wave != 4 && wave != 7) {
			updateWavebar()
		}
	}

	updateWavebar = function() {
		local waveNumber = NetProps.GetPropInt(objRes, "m_nMannVsMachineWaveCount")
		local function setWavebar(wave) {
			foreach(name, data in hardCallbacks[wave]) {
				NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", name, data.index)
				NetProps.SetPropIntArray(objRes, "m_nMannVsMachineWaveClassFlags", data.flag, data.index)
				if(data.totalCount != null) {
					NetProps.SetPropIntArray(objRes, "m_nMannVsMachineWaveClassCounts", data.totalCount, data.index)
				}
			}
		}
		local function setIcon(name, index) { //these are split
			NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", name, index)
		}
		local function setFlag(flag, index) {
			NetProps.SetPropIntArray(objRes, "m_nMannVsMachineWaveClassFlags", flag, index)
		}
		local function setCount(count, index) {
			NetProps.SetPropIntArray(objRes, "m_nMannVsMachineWaveClassCounts", count, index)
		}

		switch(waveNumber) {
			case 1:
				//Index 2 Gsoldier to soldier_spammer
				//Index 3 Samurai to crits (16 crits)
				//Index 5 Gscout to scout_fast
				setIcon("soldier_spammer", 2)
				setFlag(17, 3)
				setIcon("scout_fast", 5)
				break
			case 2:
				//Index 2 to spies, active support (2)
				setIcon("spy", 2)
				setFlag(2, 2)
				setIcon("timer_pink", 3)
				setFlag(2, 3)
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
				NetProps.SetPropInt(objRes, "m_nMannVsMachineWaveEnemyCount", 54)
				//Index 0 to support pathogen
				//Index 1 to 5 dyspnea
				//Index 2 to 2 sarcoma
				//Index 3 to 8 tachycardia
				//Index 4 to 32 tumors
				//Index 5 to 2 pneumonia
				//Index 6 to 5 cardiomyopathy
				setWavebar(4)
				break
			case 5:
				//Index 3 furies to crits (16 crits + 8 giant)
				//Index 5 gheavies to crits (16 crits + 8 giant)
				//Index 6/7 medics to crits (16 crits + 2 support)
				setFlag(24, 3)
				setFlag(24, 5)
				setFlag(18, 6)
				setFlag(18, 7)
				break
			case 7:
				NetProps.SetPropInt(objRes, "m_nMannVsMachineWaveEnemyCount", 55)
				setWavebar(7)
				break
			default:
				break
		}

		//Add pentagram icon
		NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames2", "pentagram", 11)
		NetProps.SetPropIntArray(objRes, "m_nMannVsMachineWaveClassFlags2", 2, 11)
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
		const BOTCOUNT = 55
		IncludeScript("villa_waves.nut", getroottable())
		winCondCallbacks.setBotCount(BOTCOUNT)
		IncludeScript("diseasebots.nut", getroottable())
		IncludeScript("villa_boss_callbacks.nut", getroottable())

		EntFire("wave_start_relay", "Trigger")
	}
}
hardCallbacks[4] <- {
	blackdead = {index = 0, flag = 2, totalCount = null}
	dyspnea_bp = {index = 1, flag = 8, totalCount = 5}
	sarcoma_bp = {index = 2, flag = 8, totalCount = 2}
	tachycardia_bp = {index = 3, flag = 8, totalCount = 8}
	malignant_tumor_bp = {index = 4, flag = 1, totalCount = 32}
	pneumonia_bp = {index = 5, flag = 8, totalCount = 2}
	demo_burst = {index = 6, flag = 8, totalCount = 5}
}
hardCallbacks[7] <- {
	dyspnea_bp = {index = 1, flag = 24, totalCount = 12}
	hemorrhagic_fever_bp = {index = 2, flag = 24, totalCount = 6}
	demo_burst = {index = 3, flag = 8, totalCount = 12}
	tachycardia_bp = {index = 4, flag = 8, totalCount = 8}
	sarcoma_bp = {index = 5, flag = 8, totalCount = 4}
	pneumonia_bp = {index = 6, flag = 8, totalCount = 4}
	malignant_tumor_bp = {index = 7, flag = 2, totalCount = null}
	engineer = {index = 8, flag = 2, totalCount = null}
	spy = {index = 9, flag = 4, totalCount = null}
	sniper_sydneysleeper = {index = 10, flag = 4, totalCount = null}
}