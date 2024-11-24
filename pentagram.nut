::playersInPentagram <- 0
::pentagramBuffedParticles <- SpawnEntityFromTable("trigger_particle", {
    particle_name = "pentagram_enemy"
    attachment_type = 1
    spawnflags = 64
})

::isHardmode <- false //this will be overwritten every time script is loaded, which will clear state
printl("hardmode is false")

::IncrementPentagram <- function() {
    playersInPentagram++
    switch(playersInPentagram) {
        case 0:
            break
        case 1:
            EntFire("pentagram_particle_1", "start")
            break
        case 2:
            EntFire("pentagram_particle_2", "start")
            break
        case 3:
            EntFire("pentagram_particle_3", "start")
            break
        case 4:
            EntFire("pentagram_particle_4", "start")
            break
        case 5:
            EntFire("pentagram_boom", "trigger")
			isHardmode = true
			EntFire("logic_script", "FireUser1")
            break
        default:
			break
    }
}

::DecrementPentagram <- function() {
    playersInPentagram--
    switch(playersInPentagram) {
        case 0:
            EntFire("pentagram_particle_1", "stop")
            break
        case 1:
            EntFire("pentagram_particle_2", "stop")
            break
        case 2:
            EntFire("pentagram_particle_3", "stop")
            break
        case 3:
            EntFire("pentagram_particle_4", "stop")
            break
        default:
			break
    }
}

::pentagramCallbacks <- {
	Cleanup = function() {
		delete ::pentagramCallbacks
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
		if(player.GetTeam() != TF_TEAM_RED && player.GetTeam() != TF_TEAM_BLUE) return

		if(!IsPlayerABot(player)) {
			EntFireByHandle(player, "RunScriptCode", "pentagramCallbacks.checkForPentagramBuff()", -1, player, null)
		}
	}

    checkForPentagramBuff = function() {
        if(!(activator.HasBotTag("pentagram_buffable"))) return
        pentagramBuffedParticles.AcceptInput("StartTouch", "!activator", activator, activator)
    }
}