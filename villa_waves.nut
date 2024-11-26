::winCondCallbacks <- {
	livingBot = null
	botCount = null

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
	}
	
	OnGameEvent_player_death = function(params) {
		if(botCount == null) return //don't do anything if botcount isn't set
		local player = GetPlayerFromUserID(params.userid)
		if(player == null) return
		if(!IsPlayerABot(player)) return
		if(player.HasBotTag("ignoredeath")) return
		
		botCount--
		
		if(botCount == 0) {
			livingBot.TakeDamage(1000, 0, null)
		}
	}
	
	setBotCount = function(count) {
		botCount = count
	}
}
__CollectGameEventCallbacks(winCondCallbacks)