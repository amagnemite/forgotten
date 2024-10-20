IncludeScript("customweaponsvillaedit.nut", getroottable())

::bossCallbacks <- {
	Cleanup = function() {
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

    OnGameEvent_player_spawn = function(params) {
		local player = GetPlayerFromUserID(params.userid)

		if(player == null) return
		if(player.GetTeam() != TF_TEAM_RED && player.GetTeam() != TF_TEAM_BLUE) return
		if(!IsPlayerABot(player)) return

        EntFireByHandle(player, "RunScriptCode", "bossCallbacks.checkTags()", -1, player, null)
	}

	checkTags = function() {
		if(!activator.HasBotTag("UKGR")) return
		activator.AcceptInput("RunScriptCode", "bossSpawnFunction()", null, null)
	}

	OnGameEvent_player_hurt = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		if(player == null) return
		if(!IsPlayerABot(player)) return
        if(!player.HasBotTag("UKGR")) return
        player.damageTakenThisPhase = player.damageTakenThisPhase + params.damageamount 
    }

	OnGameEvent_player_death = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		if(player == null) return
		if(!IsPlayerABot(player)) return
        if(!player.HasBotTag("UKGR_Tumor")) return
        for (local i = 1; i <= MaxPlayers ; i++)
        {
            local ukgr = PlayerInstanceFromIndex(i)
            if(ukgr == null) continue
            if(!IsPlayerABot(ukgr)) continue
            if(!ukgr.HasBotTag("UKGR")) continue
            ukgr.GetScriptScope().deadTumorCounter = ukgr.GetScriptScope().deadTumorCounter + 1
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

//todo: figure out how to clean this scope up
::bossSpawnFunction <- function() {
	thinkTable <- {}
    self.SetCustomModelWithClassAnimations("models/bots/forgotten/disease_bot_medic.mdl")
	local objRes = Entities.FindByClassname(null, "tf_objective_resource")

    //==MIMIC ORDER==
    //Hemorrhagic Fever
    //Dyspnea
    //Malignant Tumor
    //Cardiomyopathy
    //Tachycardia
    //Sarcoma
    //Pneumonia
    //Cardiac Arrest

	HEMORRHAGIC_FEVER <- 0
	DYSPNEA <- 1
	MALIGNANT_TUMOR <- 2
	CARDIOMYOPATHY <- 3
	TACHYCARDIA <- 4
	SARCOMA <- 5
	PNEUMONIA <- 6
	CARDIAC_ARREST <- 7

	WAVEBAR_SLOT_NO <- 1

	currentPhase <- HEMORRHAGIC_FEVER
    readyToChangePhase <- true
    phaseTimer <- 0
    pausePhaseTimerActions <- false
    spinAngle <- 0
    deadTumorCounter <- 0
	lastPosition <- Vector(0, 0, 0)
    damageTakenThisPhase <- 0
	// isUsingMeleeTachycardia <- false
    currentWeapon <- null
	stickyList <- []

    //Disable altmode spawns to block tumors
    EntFire("spawnbot_altmode", "Disable", null, 5)

    //Prep cardiac arrest particles
    caParticle <- SpawnEntityFromTable("trigger_particle", {
        particle_name = "cardiac_arrest_buffed"
        attachment_type = 1
        spawnflags = 64
    })

	//don't forget to precache particle
	teleportParticle <- SpawnEntityFromTable("info_particle_system", {
		effect_name = "particle name"
		start_active = false
	})

	playerPush <- SpawnEntityFromTable("trigger_push", {
		origin = self.GetCenter()
		pushdir = QAngle(0, 0, 0)
		speed = 125
		startdisabled = true
		spawnflags = 1
		filtername = "team_red"
	})
	selfPush <- SpawnEntityFromTable("trigger_push", {
		origin = self.GetCenter()
		pushdir = QAngle(0, 0, 0)
		speed = 500
		startdisabled = true
		spawnflags = 1
		filtername = "team_blu"
	})
	playerPush.SetSolid(2)
	playerPush.SetSize(Vector(-100, -100, -104), Vector(100, 100, 104))
	playerPush.AcceptInput("SetParent", "!activator", self, self)
	selfPush.SetSolid(2)
	selfPush.SetSize(Vector(-100, -100, -104), Vector(100, 100, 104))
	selfPush.AcceptInput("SetParent", "!activator", self, self)

	hemorrhagicFeverAttrs <- {
		"damage penalty": 2
		"bleed duration": 3
	}

	dyspneaAttrs <- { //json syntax because string literals get weird
		"damage bonus": 0.1,
		"fire rate bonus": 0.1,
		"projectile spread angle penalty": 60,
		"faster reload rate": -1,
		"projectile speed increased": 0.6,

		"mod projectile heat seek power": 360,
		"mod projectile heat aim error": 360,
		"mod projectile heat aim time": 0.6,
		"mod projectile heat no predict target speed": 1,

		//self.AddCustomAttribute("projectile trail particle", "dyspnea_rockettrail", -1)
		"add cond on hit": 12,
		"add cond on hit duration": 4
	}

	cardiomyopathyAttrs <- {
		"damage bonus": 0.5,
		"fire rate bonus": 0.05,
		"projectile spread angle penalty": 10,
		"clip size upgrade atomic": 16,
		"faster reload rate": 0.075
	}

	tachycardiaAttrs <- {
		"damage bonus": 3,
		"move speed bonus": 3,
		"faster reload rate": 0.5
	}

	pneumoniaAttrs <- {
		"damage bonus": 1,
		"move speed bonus": 1.1,
		"projectile spread angle penalty": 60,
		"fire rate bonus": 0.1,
		"faster reload rate": 30,
		"clip size upgrade atomic": -4
		"stickybomb charge rate": 0.001
		"projectile range increased": 0.8
	}

	cardiacAttrs <- {
		"fire rate bonus": 0.3
		"faster reload rate": -0.8,
		"damage bonus": 3
	}

	changePhase <- function() {
		phaseTimer = 0
		pausePhaseTimerActions = false
		damageTakenThisPhase = 0
		ClientPrint(null, 3, "Phase changed!")
		DispatchParticleEffect("ukgr_phase_change_flames", self.GetCenter(), Vector())
		EmitSoundEx({
			sound_name = "misc/halloween/spell_fireball_impact.wav",
			channel = 6,
			origin = self.GetCenter(),
			filter_type = RECIPIENT_FILTER_GLOBAL
		})
		switch(currentPhase) {
			case HEMORRHAGIC_FEVER:
				NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", "ukgr_fever", WAVEBAR_SLOT_NO)
				NetProps.SetPropString(self, "m_iszClassIcon", "ukgr_fever")
				self.AddWeaponRestriction(PRIMARY_ONLY)
				self.AddBotAttribute(ALWAYS_FIRE_WEAPON) //Carries over to Dyspnea phase! Removed by the think later

				foreach(attr, val in cardiacAttrs) { //Reset stat changes from Cardiac Arrest mimic
					self.RemoveCustomAttribute(attr)
				}
				foreach(attr, val in hemorrhagicFeverAttrs) {
					self.AddCustomAttribute(attr, val, -1)
				}
				::CustomWeapons.GiveItem("Upgradeable TF_WEAPON_FLAMETHROWER", self)

				self.AcceptInput("DispatchEffect", "ParticleEffectStop", null, null)
				caParticle.AcceptInput("EndTouch", "!activator", self, self)

				// scope.feverFireParticles <- SpawnEntityFromTable("info_particle_system", {
				//     targetname = "ukgr_hf_particles"
				//     effect_name = "hemorrhagic_fever_flamethrower"
				//     start_active = 1
				//     origin = self.GetOrigin()
				// })

				// EntFireByHandle(scope.feverFireParticles, "SetParent", "!activator", -1, scope.flamethrower, scope.flamethrower)
				// EntFireByHandle(scope.feverFireParticles, "AddOutput", "angles " + self.EyeAngles().x + " " + self.EyeAngles().y + " " + self.EyeAngles().z, 0.02, null, null)
				// EntFireByHandle(scope.feverFireParticles, "RunScriptCode", "self.SetAbsOrigin(self.GetMoveParent().GetAttachmentOrigin(0) + Vector())", 0.02, null, null)
				// EntFireByHandle(scope.feverFireParticles, "SetParentAttachmentMaintainOffset", "muzzle", 0.02, null, null)
				break
			case DYSPNEA:
				NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", "ukgr_dyspnea", WAVEBAR_SLOT_NO)
				NetProps.SetPropString(self, "m_iszClassIcon", "ukgr_dyspnea")
				foreach(attr, val in hemorrhagicFeverAttrs) {
					self.RemoveCustomAttribute(attr)
				}
				foreach(attr, val in dyspneaAttrs) {
					self.AddCustomAttribute(attr, val, -1)
				}
				// EntFire("ukgr_hf_particles", Kill)
				::CustomWeapons.GiveItem("Upgradeable TF_WEAPON_ROCKETLAUNCHER", self)
				break
			case MALIGNANT_TUMOR:
				NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", "ukgr_tumor", WAVEBAR_SLOT_NO)
				NetProps.SetPropString(self, "m_iszClassIcon", "ukgr_tumor")
				::CustomWeapons.GiveItem("The Crusader's Crossbow", self)
				foreach(attr, val in dyspneaAttrs) {
					self.RemoveCustomAttribute(attr)
				}

				self.RemoveBotAttribute(SUPPRESS_FIRE)

				deadTumorCounter = 0
				//Teleports offscreen and then 20 mini versions spawn
				for (local i = 1; i <= MaxPlayers ; i++)
				{
					local player = PlayerInstanceFromIndex(i)
					if(player == null) continue
					if(!IsPlayerABot(player)) continue
					if(!player.HasBotTag("UKGR_Tumor")) continue
					player.Teleport(true, lastPosition, false, QAngle(), false, Vector())
				}
				self.Teleport(true, Vector(-2600, -871, 1493), false, QAngle(), false, Vector()) //Teleports to spawnbot_altmode
				teleportParticle.SetOrigin(Vector(-2600, -871, 1493))
				teleportParticle.AcceptInput("Start", null, null, null)
				//Remember to make tumors explode on death and deal 125 dmg to boss
				break
			case CARDIOMYOPATHY:
				NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", "ukgr_burstdemo", WAVEBAR_SLOT_NO)
				NetProps.SetPropString(self, "m_iszClassIcon", "ukgr_burstdemo")
				::CustomWeapons.GiveItem("The Iron Bomber", self)
				self.AddBotAttribute(HOLD_FIRE_UNTIL_FULL_RELOAD)
				foreach(attr, val in cardiomyopathyAttrs) {
					self.AddCustomAttribute(attr, val, -1)
				}
				break
			case TACHYCARDIA:
				NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", "ukgr_tachycardia", WAVEBAR_SLOT_NO)
				NetProps.SetPropString(self, "m_iszClassIcon", "ukgr_tachycardia")
				foreach(attr, val in cardiomyopathyAttrs) {
					self.RemoveCustomAttribute(attr)
				}
				foreach(attr, val in tachycardiaAttrs) {
					self.AddCustomAttribute(attr, val, -1)
				}
				// CustomWeapons.GiveItem("The Amputator", self)
				// //CustomWeapons.EquipItem("The Amputator", self)
				// "Paintkit_proto_def_index" 3.16693e-43n
				// "Set_item_texture_wear" 0
				self.RemoveBotAttribute(HOLD_FIRE_UNTIL_FULL_RELOAD)
				// self.AddWeaponRestriction(PRIMARY_ONLY)
				self.AddWeaponRestriction(MELEE_ONLY)

				//He's taking your damn legs
				for (local i = 1; i <= MaxPlayers ; i++)
				{
					local player = PlayerInstanceFromIndex(i)
					if(player == null) continue
					if(IsPlayerABot(player)) continue
					if(player.GetTeam() != 2) continue
					player.AddCustomAttribute("SET BONUS: move speed set bonus", 0.5, -1)
				}

				//Taunts to forcefully apply Tachycardia debuff on everyone
				//Debuff function below
				self.Taunt(TAUNT_BASE_WEAPON, 11) //may want to delay this so it doesn't use demo voiceline?
				break
			case SARCOMA:
				NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", "ukgr_sarcoma", WAVEBAR_SLOT_NO)
				NetProps.SetPropString(self, "m_iszClassIcon", "ukgr_sarcoma")
				foreach(attr, val in tachycardiaAttrs) {
					self.RemoveCustomAttribute(attr)
				}
				//He's giving back your damn legs
				for (local i = 1; i <= MaxPlayers ; i++)
				{
					local player = PlayerInstanceFromIndex(i)
					if(player == null) continue
					if(IsPlayerABot(player)) continue
					if(player.GetTeam() != 2) continue
					player.RemoveCustomAttribute("SET BONUS: move speed set bonus")
				}
				//Oh no I'm unarmed!
				self.RemoveWeaponRestriction(MELEE_ONLY)
				self.RemoveWeaponRestriction(PRIMARY_ONLY)
				self.AddWeaponRestriction(SECONDARY_ONLY)
				self.SetScaleOverride(0.8)
				::CustomWeapons.GiveItem("The Quick-Fix", self)
				self.AddCustomAttribute("move speed bonus", 2, -1)
				break
			case PNEUMONIA:
				NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", "ukgr_pneumonia", WAVEBAR_SLOT_NO)
				NetProps.SetPropString(self, "m_iszClassIcon", "ukgr_pneumonia")
				self.SetScaleOverride(1.9)
				self.RemoveWeaponRestriction(PRIMARY_ONLY)
				self.AddWeaponRestriction(SECONDARY_ONLY)
				foreach(attr, val in pneumoniaAttrs) {
					self.AddCustomAttribute(attr, val, -1)
				}
				diseaseCallbacks.pneumoniaBot = self
				stickyList = [] //wipe the old list
				currentWeapon = ::CustomWeapons.GiveItem("Upgradeable TF_WEAPON_PIPEBOMBLAUNCHER", self)

				//Attach think to stickies and have them do the rest
				break
			case CARDIAC_ARREST:
				NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", "ukgr_cardiac", WAVEBAR_SLOT_NO)
				NetProps.SetPropString(self, "ukgr_cardiac", "ukgr_pneumonia")
				self.AddWeaponRestriction(PRIMARY_ONLY)
				self.AddCondEx(71, 6, null)

				local caAudioEntity = null
				while(caAudioEntity = Entities.FindByName(caAudioEntity, "heartbeat2")) {
					caAudioEntity.AcceptInput("PlaySound", null, null, null)
				}

				foreach(attr, val in pneumoniaAttrs) {
					self.RemoveCustomAttribute(attr)
				}
				foreach(attr, val in cardiacAttrs) {
					self.AddCustomAttribute(attr, val, -1)
				}

				self.AddCondEx(TF_COND_SODAPOPPER_HYPE, 11, null)
				::CustomWeapons.GiveItem("The Direct Hit", self)

				caParticle.AcceptInput("StartTouch", "!activator", self, self)

				//Might be a bit too ass or smth - Apply Cardiac Arrest's fog
				// for (local i = 1; i <= MaxPlayers ; i++)
				// {
				//     local player = PlayerInstanceFromIndex(i)
				//     if(player == null) continue
				//     if(IsPlayerABot(player)) continue

				//     player.AcceptInput("SetFogController", "fog_heartbeater", null, null)
				// }
				break
			default:
				break;
		}
		readyToChangePhase = false
	}

    ukgrThink <- function() {
        phaseTimer++

        if(readyToChangePhase) {
            changePhase()
        }
        if(currentPhase == HEMORRHAGIC_FEVER) {
			local currentEyeAngles = self.EyeAngles()
            spinAngle = spinAngle + 12
			self.SnapEyeAngles(QAngle(currentEyeAngles.x, spinAngle, currentEyeAngles.z))
            if(phaseTimer > 1000) {
                readyToChangePhase = true
                currentPhase = DYSPNEA
            }
        }
        else if(currentPhase == DYSPNEA) {
            //LOOK UP actually nvm he keeps missing for some reasons
            // local currentEyeAngles = self.EyeAngles()
			// self.SnapEyeAngles(QAngle(-90, currentEyeAngles.y, currentEyeAngles.z))

            if(phaseTimer > 275 && !pausePhaseTimerActions) {
                self.AddBotAttribute(SUPPRESS_FIRE)
                self.RemoveBotAttribute(ALWAYS_FIRE_WEAPON)
                pausePhaseTimerActions = true
            }

			else if (phaseTimer == 520) { //enables spawnbot_altmode for tumors
				local spawnbot = Entities.FindByName(null, "spawnbot_altmode")
                spawnbot.AcceptInput("enable", null, null, null)
                EntFireByHandle(spawnbot, "Disable", null, 0.5, null, null)
			}

			else if (phaseTimer == 599) {
				lastPosition = self.GetOrigin()
				ClientPrint(null, 3, "Last position set! " + lastPosition.x + " " + lastPosition.y + " " + lastPosition.z)
			}

            else if(phaseTimer > 600) {
                readyToChangePhase = true
                currentPhase = MALIGNANT_TUMOR
            }
        }
        else if(currentPhase == MALIGNANT_TUMOR && (deadTumorCounter >= 20 || phaseTimer > 1000)) {
            readyToChangePhase = true
			self.Teleport(true, lastPosition, false, QAngle(), false, Vector())
			teleportParticle.AcceptInput("Stop", null, null, null)
			//It's set to 0 twice but yknow just to be safe
            deadTumorCounter = 0
            currentPhase = CARDIOMYOPATHY
        }
        else if(currentPhase == CARDIOMYOPATHY && phaseTimer > 666) {
            readyToChangePhase = true
            currentPhase = TACHYCARDIA
        }
        else if(currentPhase == TACHYCARDIA) {
            if(phaseTimer > 133 && !pausePhaseTimerActions) {
                for (local i = 1; i <= MaxPlayers ; i++)
                {
                    local player = PlayerInstanceFromIndex(i)
                    if(player == null) continue
                    if(IsPlayerABot(player)) continue
                    player.AddCondEx(32, 18, null)
                }
                pausePhaseTimerActions = true
            }
			// local playerInVicinity = null
			// isUsingMeleeTachycardia = false
			// while(playerInVicinity = Entities.FindByClassnameWithin(playerInVicinity, "player", self.GetCenter(), 256)) {
			// 	ClientPrint(null, 3, "NEARBy RED PLAYER FOUND")
			// 	if(playerInVicinity.GetTeam() == 2) isUsingMeleeTachycardia = true
			// }
			// if(isUsingMeleeTachycardia) {
			// 	self.RemoveWeaponRestriction(PRIMARY_ONLY)
			// 	self.AddWeaponRestriction(MELEE_ONLY)
			// }
			// else {
			// 	self.RemoveWeaponRestriction(MELEE_ONLY)
			// 	self.AddWeaponRestriction(PRIMARY_ONLY)
			// }
            if(phaseTimer > 1333) {
                readyToChangePhase = true
                currentPhase = SARCOMA
            }
        }
        else if(currentPhase == SARCOMA) {
            if(damageTakenThisPhase > 5000 && !pausePhaseTimerActions) {
                self.AddCondEx(71, (14.8 - (phaseTimer / 66.6)), null)
                self.SetScaleOverride(1.9)
                pausePhaseTimerActions = true
            }

            if(phaseTimer > 666 && !pausePhaseTimerActions) {
				self.RemoveWeaponRestriction(SECONDARY_ONLY)
                self.AddWeaponRestriction(PRIMARY_ONLY)
                ::CustomWeapons.GiveItem("Upgradeable TF_WEAPON_SYRINGEGUN_MEDIC", self)
                self.AddCondEx(33, 10, null)
                self.AddCustomAttribute("damage bonus", 3, -1)
                self.SetScaleOverride(2.5)
                pausePhaseTimerActions = true
				local audioEntity = null
				while(audioEntity = Entities.FindByName(audioEntity, "sarcoma_evolution_sound")) {
					audioEntity.AcceptInput("PlaySound", null, null, null)
				}
				EntFire("sarcoma_evolution_shake", "StartShake")
				DispatchParticleEffect("sarcoma_explode", self.GetOrigin(), Vector())
            }
            else if(phaseTimer > 1000) {
                readyToChangePhase = true
				ClientPrint(null, 3, "Switching to Pneumonia!")
                currentPhase = PNEUMONIA
            }
        }
        else if(currentPhase == PNEUMONIA) {
            if(!pausePhaseTimerActions) {
				if((Time() - NetProps.GetPropFloat(currentWeapon, "m_flNextPrimaryAttack")) <= 1) {
					local sticky = null;
					while(sticky = Entities.FindByClassname(sticky, "tf_projectile_pipe_remote")) {
						if(stickyList.find(sticky) == null) {
							stickyList.append(sticky)
							sticky.SetModelSimple("models/villa/stickybomb_pneumonia.mdl")
						}
					}
				}
            }

			if(phaseTimer == 100) { //1.5s
				foreach(sticky in stickyList) {
					DispatchParticleEffect("pneumonia_stickybomb_aura", sticky.GetCenter(), Vector())
				}
				pausePhaseTimerActions = true //stop collecting stickies
			}

			if(phaseTimer == 267) { //approx 4s
				if(!pneumoniaSpawner.IsValid()) return //mostly for wave reset
				foreach(sticky in stickyList) {
					printl("spawned a pneumonia at sticky")
					pneumoniaSpawner.SpawnEntityAtLocation(sticky.GetOrigin() + Vector(0, 0, 0), Vector())
				}
				self.PressAltFireButton(0.1)
			}

            if(phaseTimer > 530) {
                readyToChangePhase = true
                currentPhase = CARDIAC_ARREST
            }
        }
        //It all loops back
        else if(currentPhase == CARDIAC_ARREST) {
			
			if(phaseTimer == 400) {
				EntFire("wakeup_sound*", "PlaySound")
				EntFire("wakeup_shake*", "StartShake")
			}

			else if(phaseTimer > 734) {
				readyToChangePhase = true
            	currentPhase = HEMORRHAGIC_FEVER
			}
            
        }
       // return -1
    }

	waitForAllDeadThink <- function() {
		local allBotsAreDead = true
		for(local i = 1; i <= MaxPlayers ; i++) {
			local player = PlayerInstanceFromIndex(i)
			if(player == null) continue
			if(!IsPlayerABot(player)) continue
			if(player == self) continue
			if(player == timer) continue
			//if(player.HasBotTag("UKGR_tumor")) continue
			if(NetProps.GetPropInt(player, "m_lifeState") == 0) {
				allBotsAreDead = false
				break
			}
		}
		if(allBotsAreDead) {
			if(timer != null) {
				timer.TakeDamage(1000, 0, null)
			}
			local spawnbot = Entities.FindByName(null, "spawnbot")
			self.Teleport(true, spawnbot.GetOrigin(), false, QAngle(), false, Vector())
			self.RemoveCond(TF_COND_HALLOWEEN_SPEED_BOOST)
			delete thinkTable.waitForAllDeadThink
			thinkTable.ukgrThink <- ukgrThink
		}
	}
	thinkTable.waitForAllDeadThink <- waitForAllDeadThink

	mainThink <- function() { //this is mostly to make the customattributes think works
		if(NetProps.GetPropInt(self, "m_lifeState") != 0) {
			delete thinkTable
			AddThinkToEnt(self, null)
			NetProps.SetPropString(self, "m_iszScriptThinkFunction", "")
			return
		}

		foreach(name, func in thinkTable) {
			func()
		}
        return -1
	}
    AddThinkToEnt(self, "mainThink")
}