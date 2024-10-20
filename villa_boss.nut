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

	playSound = function(soundName, player) { //scope moment
		EmitSoundEx({
			sound_name = soundName
			origin = player.GetOrigin()
			filter_type = RECIPIENT_FILTER_SINGLE_PLAYER
			entity = player
			channel = 6
		})
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

	OnGameEvent_player_death = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		if(player == null) return
		if(!IsPlayerABot(player)) return
        if(!player.HasBotTag("UKGR_Tumor")) return
        for (local i = 1; i <= MaxPlayers ; i++)
        {
            local player = PlayerInstanceFromIndex(i)
            if(player == null) continue
            if(!IsPlayerABot(player)) continue
            if(!player.HasBotTag("UKGR")) continue
            player.GetScriptScope().deadTumorCounter = player.GetScriptScope().deadTumorCounter + 1
        }
    }
}
__CollectGameEventCallbacks(bossCallbacks)

::addPneumoniaStickyThink <- function() {
	stickyTimer <- 0
	stickyThink <- function() {
		if(stickyTimer == 1.5) {
			DispatchParticleEffect("pneumonia_stickybomb_aura", self.GetCenter(), Vector())
		}
		
		if(!pneumoniaSpawner.IsValid()) return //mostly for wave reset
		else if(stickyTimer >= 4) {
			//Explode and create pneumonia clouds
			pneumoniaSpawner.SpawnEntityAtEntityOrigin(self)
			self.GetOwner().SecondaryAttack()
		}
		stickyTimer += 0.5
		return 0.5
	}
	AddThinkToEnt(self, "stickyThink")
}

::bossSpawnFunction <- function() {
	thinkTable <- {}
    self.SetCustomModelWithClassAnimations("models/bots/forgotten/disease_bot_medic.mdl")

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

    //Is this even necessary??
    //scope.phases = [HEMORRHAGIC_FEVER, DYSPNEA, MALIGNANT_TUMOR, CARDIOMYOPATHY, TACHYCARDIA, SARCOMA, PNEUMONIA, CARDIAC_ARREST]
	currentPhase <- HEMORRHAGIC_FEVER
    readyToChangePhase <- true
    phaseTimer <- 0
    pausePhaseTimerActions <- false
    spinAngle <- 0
    deadTumorCounter <- 0
	lastPosition <- Vector(0, 0, 0)
    damageTakenThisPhase <- 0
    currentWeapon <- null

    //Disable altmode spawns to block tumors
    EntFire("spawnbot_altmode", "Disable", null, 5)

    //Prep cardiac arrest particles
    caParticle <- SpawnEntityFromTable("trigger_particle", {
        particle_name = "cardiac_arrest_buffed"
        attachment_type = 1
        spawnflags = 64
    })
	
	dyspneaAttrs <- { //json syntax because string literals get weird
		"damage bonus": 0.3,
		"fire rate bonus": 0.1,
		"projectile spread angle penalty": 6,
		"faster reload rate": -1,

		"mod projectile heat seek power": 90,
		"mod projectile heat aim error": 180,
		"mod projectile heat aim time": 0.6,
		"mod projectile heat no predict target speed": 1,

		//self.AddCustomAttribute("projectile trail particle", "dyspnea_rockettrail", -1)
		"add cond on hit": 12,
		"add cond on hit duration": 4
	}
	
	cardiomyopathyAttrs <- {
		"damage bonus": 0.5,
		"fire rate bonus", 0.05,
		"projectile spread angle penalty": 10,
		"clip size upgrade atomic": 76,
		"faster reload rate", 10
	}
	
	pneumoniaAttrs <- {
		"move speed bonus": 1.1,
		"projectile spread angle penalty": 60,
		"fire rate bonus": 0.1,
		"faster reload rate": 30,
		"clip size upgrade atomic": -4
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
		DispatchParticleEffect("ukgr_phase_change_flames", self.GetCenter(), Vector())
		switch(currentPhase) {
			case HEMORRHAGIC_FEVER:
				//Reset stat changes from Cardiac Arrest mimic
				foreach(attr, val in cardiacAttrs) {
					self.RemoveCustomAttribute(attr)
				}
				::CustomWeapons.GiveItem("Upgradeable TF_WEAPON_FLAMETHROWER", self)
				//CustomWeapons.EquipItem("Upgradeable TF_WEAPON_FLAMETHROWER", self)

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
				self.AddCustomAttribute("damage bonus", 2, -1)
				self.AddBotAttribute(ALWAYS_FIRE_WEAPON) //Carries over to Dyspnea phase! Removed by the think later
				break
			case DYSPNEA:
				// EntFire("ukgr_hf_particles", Kill)
				//CustomWeapons.UnequipItem("Upgradeable TF_WEAPON_FLAMETHROWER", self)
				::CustomWeapons.GiveItem("Upgradeable TF_WEAPON_ROCKETLAUNCHER", self)
				//CustomWeapons.EquipItem("Upgradeable TF_WEAPON_ROCKETLAUNCHER", self)
				foreach(attr, val in dyspneaAttrs) {
					self.AddCustomAttribute(attr, val, -1)
				}
				break
			case MALIGNANT_TUMOR:
				::CustomWeapons.GiveItem("The Crusader's Crossbow", self)
				//CustomWeapons.EquipItem("The Crusader's Crossbow", self)
				foreach(attr, val in dyspneaAttrs) {
					self.RemoveCustomAttribute(attr)
				}
				//Teleports offscreen and then 20 mini versions spawn
				self.RemoveBotAttribute(SUPPRESS_FIRE)
				//Teleports to spawnbot_altmode
				lastPosition = self.GetOrigin()
				self.Teleport(true, Vector(-3296, 640, 1424), false, QAngle(0,0,0), false, Vector(0,0,0))
				deadTumorCounter = 0
				EntFire("spawnbot_altmode", "Enable")
				EntFire("spawnbot_altmode", "Disable", null, 0.3)
				for (local i = 1; i <= MaxPlayers ; i++)
				{
					local player = PlayerInstanceFromIndex(i)
					if(player == null) continue
					if(!IsPlayerABot(player)) continue
					if(!player.HasBotTag("UKGR_Tumor")) continue
					player.Teleport(true, lastPosition, false, QAngle(), false, Vector())
				}
				//Remember to make tumors explode on death and deal 125 dmg to boss
				break
			case CARDIOMYOPATHY:
				::CustomWeapons.GiveItem("The Iron Bomber", self)
				//CustomWeapons.EquipItem("The Iron Bomber", self)
				self.AddBotAttribute(HOLD_FIRE_UNTIL_FULL_RELOAD)
				foreach(attr, val in cardiomyopathyAttrs) {
					self.AddCustomAttribute(attr, val, -1)
				}
				break
			case TACHYCARDIA:
				foreach(attr, val in cardiomyopathyAttrs) {
					self.RemoveCustomAttribute(attr)
				}
				// CustomWeapons.GiveItem("The Amputator", self)
				// //CustomWeapons.EquipItem("The Amputator", self)
				// "Paintkit_proto_def_index" 3.16693e-43n
				// "Set_item_texture_wear" 0
				self.RemoveBotAttribute(HOLD_FIRE_UNTIL_FULL_RELOAD)
				self.AddWeaponRestriction(MELEE_ONLY)

				//Taunts to forcefully apply Tachycardia debuff on everyone
				//Debuff function below
				self.Taunt(TAUNT_BASE_WEAPON, 11)
				break
			case SARCOMA:
				//Oh no I'm unarmed!
				self.AddWeaponRestriction(SECONDARY_ONLY)
				self.SetScaleOverride(0.8)
				self.AddCustomAttribute("move speed bonus", 2, -1)
				break
			case PNEUMONIA:
				self.SetScaleOverride(1.9)
				self.AddWeaponRestriction(SECONDARY_ONLY)
				foreach(attr, val in pneumoniaAttrs) {
					self.AddCustomAttribute(attr, val, -1)
				}
				//self.AddCustomAttribute("custom projectile model", "models/villa/stickybomb_pneumonia.mdl", -1)
				::CustomWeapons.GiveItem("Upgradeable TF_WEAPON_PIPEBOMBLAUNCHER", self)
				//CustomWeapons.EquipItem("Upgradeable TF_WEAPON_PIPEBOMBLAUNCHER", self)
				
				//Attach think to stickies and have them do the rest
				break
			case CARDIAC_ARREST:
				self.AddWeaponRestriction(PRIMARY_ONLY)
				self.AddCondEx(71, 6, null)

				local caAudioEntity = null
				while(caAudioEntity = Entities.FindByName(caAudioEntity, "heartbeat2")) {
					caAudioEntity.AcceptInput("PlaySound", null, null, null)
				}
				
				foreach(attr, val in pneumoniaAttrs) {
					self.RemoveCustomAttribute(attr)
				}
				

				self.AddCondEx(TF_COND_SODAPOPPER_HYPE, 11, null)
				::CustomWeapons.GiveItem("The Direct Hit", self)
				//CustomWeapons.EquipItem("The Direct Hit", self)
				
				foreach(attr, val in cardiacAttrs) {
					self.AddCustomAttribute(attr, val, -1)
				}

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
            spinAngle = spinAngle + 12
			self.SnapEyeAngles(QAngle(0, spinAngle, 0))
            if(phaseTimer > 550) {
                readyToChangePhase = true
                currentPhase = DYSPNEA
            }
        }
        else if(currentPhase == DYSPNEA) {
            //LOOK UP
            local currentEyeAngles = self.EyeAngles()
			self.SnapEyeAngles(QAngle(-90, currentEyeAngles.y, currentEyeAngles.z))

            if(phaseTimer > 275 && !pausePhaseTimerActions) {
                self.AddBotAttribute(SUPPRESS_FIRE)
                self.RemoveBotAttribute(ALWAYS_FIRE_WEAPON)
                pausePhaseTimerActions = true
            }

            else if(phaseTimer > 600) {
                readyToChangePhase = true
                currentPhase = MALIGNANT_TUMOR
            }
        }
        else if(currentPhase == MALIGNANT_TUMOR && deadTumorCounter >= 20) {
            readyToChangePhase = true
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
                    player.AddCondEx(32, 20, null)
                }
                pausePhaseTimerActions = true
            }
            else if(phaseTimer > 1333) {
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
                self.AddWeaponRestriction(PRIMARY_ONLY)
                ::CustomWeapons.GiveItem("The Brass Beast", self)
                //CustomWeapons.EquipItem("The Brass Beast", self)
                self.AddCondEx(33, 10, null)
                self.AddCustomAttribute("damage bonus", 2, -1)
                self.SetScaleOverride(2.5)
                pausePhaseTimerActions = true
            }
            else if(phaseTimer > 1000) {
                readyToChangePhase = true
                currentPhase = PNEUMONIA
            }
        }
        else if(currentPhase == PNEUMONIA) {
            if(!pausePhaseTimerActions) {
                local pneumoniaSticky = null
                while(pneumoniaSticky = Entities.FindByClassname(pneumoniaSticky, "tf_projectile_pipe_remote")) {
                    pneumoniaSticky.ValidateScriptScope()
                    if(!("isPneumoniaSet" in pneumoniaSticky.GetScriptScope())) {
                        pneumoniaSticky.GetScriptScope().isPneumoniaSet <- true
						pneumoniaSticky.AcceptInput("RunScriptCode", "addPneumoniaStickyThink", null, null)
                    }
                }
                if(phaseTimer > 40) {
                    pausePhaseTimerActions = true
                }
            }

            if(phaseTimer > 530) {
                readyToChangePhase = true
                currentPhase = CARDIAC_ARREST
            }

        }
        //It all loops back
        else if(currentPhase == CARDIAC_ARREST && phaseTimer > 734) {
            readyToChangePhase = true
            currentPhase = HEMORRHAGIC_FEVER
        }
       // return -1
    }
	thinkTable.ukgrThink <- ukgrThink

	scope.mainThink <- function() { //this is mostly to make the customattributes think works
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