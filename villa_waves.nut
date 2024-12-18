::winCondCallbacks <- {
	livingBot = null
	currentBotCount = null
	totalBotCount = null
	hasWavebar = false
	waveTable = {}

	Cleanup = function() {
		delete ::winCondCallbacks
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

		EntFireByHandle(player, "runscriptcode", "winCondCallbacks.checkTags()", -1, player, null)
		if(hasWavebar) {
			NetProps.SetPropInt(objRes, "m_nMannVsMachineWaveEnemyCount", totalBotCount)
		}
	}

	checkTags = function() {
		if(activator.HasBotTag("theendnormal")) {
			if(isHardmode) {
				activator.TakeDamage(1000, 0, null)
			}
			else {
				livingBot = activator
			}
		}
		else if(activator.HasBotTag("theendhard")) {
			if(!isHardmode) {
				activator.TakeDamage(1000, 0, null)
			}
			else {
				livingBot = activator
			}
		}
		if(hasWavebar) {
			setWavebar()
		}
	}

	OnGameEvent_player_death = function(params) {
		if(currentBotCount == null) return //don't do anything if currentBotCount isn't set
		local player = GetPlayerFromUserID(params.userid)
		if(!IsPlayerABot(player)) return

		NetProps.SetPropInt(objRes, "m_nMannVsMachineWaveEnemyCount", totalBotCount)

		if(!player.HasBotTag("ignoredeath")) {
			currentBotCount--

			if(currentBotCount == 0) {
				livingBot.TakeDamage(1000, 0, null)
			}
			local iconName = NetProps.GetPropString(player, "m_PlayerClass.m_iszClassIcon")
			if(!startswith(iconName, "ukgr_")) {
				waveTable[iconName].currentCount -= 1
			}
		}
	}

	setBotCount = function(count) {
		currentBotCount = count
		totalBotCount = count
	}

	setWavebar = function() {
		foreach(name, data in waveTable) {
			NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", name, data.index)
			NetProps.SetPropIntArray(objRes, "m_nMannVsMachineWaveClassFlags", data.flag, data.index)
			if(data.currentCount != null && data.currentCount > 0) {
				NetProps.SetPropIntArray(objRes, "m_nMannVsMachineWaveClassCounts", data.currentCount, data.index)
			}
		}
	}
}
local wave = NetProps.GetPropInt(Entities.FindByClassname(null, "tf_objective_resource"), "m_nMannVsMachineWaveCount")
if(wave in difficultyNamespace) {
	winCondCallbacks.hasWavebar = true
	local waveTable = winCondCallbacks.waveTable
	foreach(k, v in difficultyNamespace[wave]) {
		waveTable[k] <- v
		waveTable[k].currentCount <- waveTable[k].totalCount
	}
}
__CollectGameEventCallbacks(winCondCallbacks)