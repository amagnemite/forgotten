::playersInPentagram <- 0
::isHardmode <- false //this will be overwritten every time script is loaded, which will clear state

::IncrementPentagram <- function() {
    playersInPentagram++
    switch(playersInPentagram) {
        case 0:
            break
        case 1:
            EntFire("pentagram_particle_1", "start")
						EntFire("pentagram_boom", "trigger")
			isHardmode = true
			EntFire("logic_script", "FireUser1")
			__CollectGameEventCallbacks(pentagramCallbacks)
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
            //EntFire("pentagram_boom", "trigger")
			//isHardmode = true
			//EntFire("logic_script", "FireUser1")
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
		local objRes = Entities.FindByClassname(null, "tf_objective_resource")
		local wave = NetProps.GetPropInt(objRes, "m_nMannVsMachineWaveCount")
		if(wave == 1) {
			delete ::pentagramCallbacks
		}
    }

	OnGameEvent_recalculate_holidays = function(_) {
		if(GetRoundState() == 3) {
			Cleanup()
		}
		if(!("pentagramBuffedParticles" in getroottable()) || !pentagramBuffedParticles.IsValid()) { //put this here since overall script essentially only runs once a mission
			::pentagramBuffedParticles <- SpawnEntityFromTable("trigger_particle", {
				particle_name = "pentagram_enemy"
				attachment_type = 1
				spawnflags = 64
			})
		}
	}

    OnGameEvent_player_spawn = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		if(player == null) return
		
		if(IsPlayerABot(player)) {
			EntFireByHandle(player, "RunScriptCode", "pentagramCallbacks.checkForPentagramBuff()", -1, player, null)
		}
	}

    checkForPentagramBuff = function() {
        if(!activator.HasBotTag("pentagram_buffable")) return
        pentagramBuffedParticles.AcceptInput("StartTouch", "!activator", activator, activator)
    }
}