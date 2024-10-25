//todo: figure out how to clean this scope up
thinkTable <- {}

unusualParticle <- SpawnEntityFromTable("info_particle_system", {
	targetname = "boss_halo_particle"
	effect_name = "boss_halo"
	start_active = true
})

unusualParticle.AcceptInput("SetParent", "!activator", self, null)
unusualParticle.AcceptInput("SetParentAttachment", "head", null, null)

sarcomaMimicParticle <- SpawnEntityFromTable("info_particle_system", {
	effect_name = "sarcoma_chargeparticle"
	start_active = false
})

sarcomaMimicParticle.AcceptInput("SetParent", "!activator", self, null)
sarcomaMimicParticle.AcceptInput("SetParentAttachment", "center_attachment", null, null)

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

WAVEBAR_SLOT_NO <- 0

mainPhase <- 1
currentFinalePhase <- HEMORRHAGIC_FEVER
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

//Prep cardiac arrest particles
caParticle <- SpawnEntityFromTable("trigger_particle", {
	particle_name = "cardiac_arrest_buffed"
	attachment_type = 1
	spawnflags = 64
})

//Prep tachycardia particles
taParticle <- SpawnEntityFromTable("trigger_particle", {
	particle_name = "ukgr_tachycardia_intro"
	attachment_type = 1
	spawnflags = 64
})

//don't forget to precache particle
teleportParticle <- SpawnEntityFromTable("info_particle_system", {
	effect_name = "ukgr_teleport_spellwheel"
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
	"damage penalty": 4.5
	// "bleed duration": 3
}

dyspneaAttrs <- { //json syntax because string literals get weird
	"damage bonus": 0.4,
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
	"damage bonus": 1,
	"fire rate bonus": 0.05,
	"projectile spread angle penalty": 10,
	"clip size upgrade atomic": 16,
	"faster reload rate": 0.075
}

tachycardiaAttrs <- {
	"damage bonus": 2,
	"move speed bonus": 3
}

buffSarcomaAttrs <- {
	"damage bonus": 3,
	"projectile spread angle penalty": 10,
	"fire rate bonus": 0.6,
	"faster reload rate": 0.8,
	"clip size bonus": 4
}

pneumoniaAttrs <- {
	"damage bonus": 0.5,
	"move speed bonus": 1.1,
	"projectile spread angle penalty": 60,
	"fire rate bonus": 0.01,
	"faster reload rate": 30,
	"clip size upgrade atomic": -4
	"stickybomb charge rate": 0.001
	"projectile range increased": 0.8
}

cardiacAttrs <- {
	"fire rate bonus": 0.12
	"faster reload rate": -0.8,
	"damage bonus": 3
}

//START OF PHASE 1 STUFF
::ukgr <- self
NetProps.SetPropString(self, "m_iName", "ukgr") //needed for particle nonsense
MOVESPEEDBASE <- 0.5
HEALTHBONUS <- 100
playersEaten <- 0
medigun <- null
deadSupport <- 0
support <- []
supportTimer <- Timer()
for(local i = 0; i < NetProps.GetPropArraySize(self, "m_hMyWeapons"); i++) {
	local wep = NetProps.GetPropEntityArray(self, "m_hMyWeapons", i)

	if(wep && wep.GetClassname() == "tf_weapon_medigun") {
		medigun = NetProps.GetPropEntityArray(self, "m_hMyWeapons", i);
		break;
	}
}

startPhase1 <-  function() {
	//self.GenerateAndWearItem("The Crusader's Crossbow")
	//self.GetActiveWeapon().AddAttribute("reload speed", 0.5, -1)
	local arena2Origin = Entities.FindByName(null, "spawnbot_arena2").GetOrigin()
	for(local i = 1; i <= MaxPlayers; i++) {
		local player = PlayerInstanceFromIndex(i)
		if(player == null) continue
		if(!IsPlayerABot(player)) continue
		if(NetProps.GetPropInt(player, "m_lifeState") != LIFE_ALIVE) continue
		if(!player.HasBotTag("gmedsupport")) continue

		support.append(player)
		player.Teleport(true, arena2Origin, false, QAngle(), false, Vector())
	}
}

offensiveThink <- function() {
	//printl("dead support " + deadSupport)
	if(deadSupport >= 5 && supportTimer.Expired()) {
		local spawnbot = Entities.FindByName(null,  "spawnbot_arena2")
		foreach(supporter in support) {
			supporter.Teleport(true, spawnbot.GetOrigin(), false, QAngle(), false, Vector())
		}
		deadSupport = 0
	}

	if(self.GetHealth() < self.GetMaxHealth() && deadSupport < 5) {
		printl("entering defense")
		EntFire("pop_interface", "ChangeBotAttributes", "EatBots", 3) //delay to let support walk out
		delete thinkTable.offensiveThink
		thinkTable.defensiveThink <- defensiveThink
	}
}

defensiveThink <- function() {
	if(deadSupport >= 5) {
		printl("entering offense")
		EntFire("pop_interface", "ChangeBotAttributes", "ShootPlayers", -1)
		supportTimer.Start(2.5)
		delete thinkTable.defensiveThink
		thinkTable.offensiveThink <- offensiveThink
		return
	}

	local target = self.GetHealTarget()
	if(target != null) {
		target.TakeDamageCustom(self, self, null, Vector(0, 0, 1), target.GetCenter(),
			3, DMG_BLAST, TF_DMG_CUSTOM_MERASMUS_ZAP); //kills in approx a second
	}
}

strengthen <- function() {
	playersEaten++
	//self.AddCustomAttribute("max health additive bonus", HEALTHBONUS * playersEaten, -1)
	self.SetHealth(self.GetHealth() + HEALTHBONUS)
	self.AddCustomAttribute("damage bonus", 1 + 0.25 * playersEaten, -1)
	self.AddCustomAttribute("move speed bonus", MOVESPEEDBASE + 0.1 * playersEaten, -1)
	self.AddCondEx(TF_COND_CRITBOOSTED_USER_BUFF, 1 * playersEaten, null)
	self.AddCondEx(TF_COND_HALLOWEEN_SPEED_BOOST, 1 * playersEaten, null)
	local particle = SpawnEntityFromTable("info_particle_system", {
		origin = self.GetOrigin()
		effect_name = "soldierbuff_blue_buffed"
		start_active = true
	})
	particle.AcceptInput("SetParent", "ukgr", null, null)
	EntFireByHandle(particle, "Kill", null, 0.3, null, null)
}

::phase1Callbacks <- {
	OnGameEvent_player_death = function(params) {
		local victim = GetPlayerFromUserID(params.userid)
		local inflictor = EntIndexToHScript(params.inflictor_entindex)
		local isKillerUKGR = IsPlayerABot(inflictor) && inflictor.HasBotTag("ukgr") ? true : false
		if(IsPlayerABot(victim)) {
			if(victim.HasBotTag("gmedsupport")) {
				ukgr.GetScriptScope().deadSupport++
				//printl("team " + victim.GetTeam())
				victim.ValidateScriptScope()
				EntFireByHandle(victim, "runscriptcode", "self.ForceChangeTeam(TF_TEAM_BLUE, true)", -1, null, null)
				EntFireByHandle(victim, "runscriptcode", "self.ForceRespawn()", -1, null, null)
				EntFireByHandle(victim, "runscriptcode", "self.AddBotTag(\"gmedsupport\")", -1, null, null)

				if(isKillerUKGR) {
					DispatchParticleEffect("rd_robot_explosion", victim.GetOrigin(), Vector())

					EmitSoundEx({
						sound_name = "ambient/grinder/grinderbot_03.wav",
						channel = 6,
						origin = victim.GetCenter(),
						filter_type = RECIPIENT_FILTER_PAS
					})
					ukgr.AcceptInput("CallScriptFunction", "strengthen", null, null)
				}

			}
		}
		else {
			if(isKillerUKGR) {
				ukgr.AcceptInput("CallScriptFunction", "strengthen", null, null)
			}
		}
	}
	OnScriptHook_OnTakeDamage = function(params) {
		local victim = params.const_entity
		local inflictor = params.inflictor
		if(!IsPlayerABot(victim)) return
		if(IsPlayerABot(victim) && !victim.HasBotTag("gmedsupport")) return
		if(inflictor == null || !IsPlayerABot(inflictor)) return
		params.force_friendly_fire = true
	}
}
__CollectGameEventCallbacks(phase1Callbacks)

//START OF PHASE 3 STUFF
changePhase <- function() {
	phaseTimer = 0
	pausePhaseTimerActions = false
	damageTakenThisPhase = 0
	//ClientPrint(null, 3, "Phase changed!")
	DispatchParticleEffect("ukgr_phase_change_flames", self.GetCenter(), Vector())
	EmitSoundEx({
		sound_name = "misc/halloween/spell_fireball_impact.wav",
		channel = 6,
		origin = self.GetCenter(),
		filter_type = RECIPIENT_FILTER_GLOBAL
	})
	switch(currentFinalePhase) {
		case HEMORRHAGIC_FEVER:
			NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", "ukgr_fever", WAVEBAR_SLOT_NO)
			NetProps.SetPropString(self, "m_PlayerClass.m_iszClassIcon", "ukgr_fever")
			self.AddWeaponRestriction(PRIMARY_ONLY)
			self.RemoveWeaponRestriction(MELEE_ONLY)
			self.AddBotAttribute(ALWAYS_FIRE_WEAPON) //Carries over to Dyspnea phase! Removed by the think later

			foreach(attr, val in cardiacAttrs) { //Reset stat changes from Cardiac Arrest mimic
				self.RemoveCustomAttribute(attr)
			}
			foreach(attr, val in hemorrhagicFeverAttrs) {
				self.AddCustomAttribute(attr, val, -1)
			}
			::CustomWeapons.GiveItem("Upgradeable TF_WEAPON_FLAMETHROWER", self)

			self.AcceptInput("DispatchEffect", "ParticleEffectStop", null, null)
			caParticle.AcceptInput("EndTouch", "!self", self, self)

			// scope.feverFireParticles <- SpawnEntityFromTable("info_particle_system", {
			//     targetname = "ukgr_hf_particles"
			//     effect_name = "hemorrhagic_fever_flamethrower"
			//     start_active = 1
			//     origin = self.GetOrigin()
			// })

			// EntFireByHandle(scope.feverFireParticles, "SetParent", "!self", -1, scope.flamethrower, scope.flamethrower)
			// EntFireByHandle(scope.feverFireParticles, "AddOutput", "angles " + self.EyeAngles().x + " " + self.EyeAngles().y + " " + self.EyeAngles().z, 0.02, null, null)
			// EntFireByHandle(scope.feverFireParticles, "RunScriptCode", "self.SetAbsOrigin(self.GetMoveParent().GetAttachmentOrigin(0) + Vector())", 0.02, null, null)
			// EntFireByHandle(scope.feverFireParticles, "SetParentAttachmentMaintainOffset", "muzzle", 0.02, null, null)
			break
		case DYSPNEA:
			NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", "ukgr_dyspnea", WAVEBAR_SLOT_NO)
			NetProps.SetPropString(self, "m_PlayerClass.m_iszClassIcon", "ukgr_dyspnea")
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
			NetProps.SetPropString(self, "m_PlayerClass.m_iszClassIcon", "ukgr_tumor")
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
			teleportParticle.SetOrigin(lastPosition)
			teleportParticle.AcceptInput("Start", null, null, null)
			//Remember to make tumors explode on death and deal 125 dmg to boss
			break
		case CARDIOMYOPATHY:
			NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", "ukgr_burstdemo", WAVEBAR_SLOT_NO)
			NetProps.SetPropString(self, "m_PlayerClass.m_iszClassIcon", "ukgr_burstdemo")
			::CustomWeapons.GiveItem("The Iron Bomber", self)
			self.AddBotAttribute(HOLD_FIRE_UNTIL_FULL_RELOAD)
			foreach(attr, val in cardiomyopathyAttrs) {
				self.AddCustomAttribute(attr, val, -1)
			}
			break
		case TACHYCARDIA:
			NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", "ukgr_tachycardia", WAVEBAR_SLOT_NO)
			NetProps.SetPropString(self, "m_PlayerClass.m_iszClassIcon", "ukgr_tachycardia")
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

			taParticle.AcceptInput("StartTouch", "!self", self, self)
			EntFireByHandle(taParticle, "EndTouch", "!self", 2, self, self)
			EntFireByHandle(self, "DispatchEffect", "ParticleEffectStop", 2, self, self)

			//Taunts to forcefully apply Tachycardia debuff on everyone
			//Debuff function below
			self.Taunt(TAUNT_BASE_WEAPON, 11) //may want to delay this so it doesn't use demo voiceline?
			break
		case SARCOMA:
			NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", "ukgr_sarcoma", WAVEBAR_SLOT_NO)
			NetProps.SetPropString(self, "m_PlayerClass.m_iszClassIcon", "ukgr_sarcoma")
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
			foreach(attr, val in buffSarcomaAttrs) {
				self.RemoveCustomAttribute(attr)
			}
			NetProps.SetPropStringArray(objRes, "m_iszMannVsMachineWaveClassNames", "pneumonia_bp", WAVEBAR_SLOT_NO)
			NetProps.SetPropString(self, "m_PlayerClass.m_iszClassIcon", "pneumonia_bp")
			self.SetScaleOverride(1.9)
			self.RemoveWeaponRestriction(PRIMARY_ONLY)
			self.AddWeaponRestriction(SECONDARY_ONLY)
			self.AddBotAttribute(ALWAYS_FIRE_WEAPON)
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
			NetProps.SetPropString(self, "m_PlayerClass.m_iszClassIcon", "ukgr_cardiac")
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

			caParticle.AcceptInput("StartTouch", "!self", self, self)

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

finaleThink <- function() {
	phaseTimer++

	if(readyToChangePhase) {
		changePhase()
	}
	if(currentFinalePhase == HEMORRHAGIC_FEVER) {
		local currentEyeAngles = self.EyeAngles()
		spinAngle = spinAngle + 12
		self.SnapEyeAngles(QAngle(currentEyeAngles.x, spinAngle, currentEyeAngles.z))
		if(phaseTimer > 1000) {
			readyToChangePhase = true
			currentFinalePhase = DYSPNEA
		}
	}
	else if(currentFinalePhase == DYSPNEA) {
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
			//ClientPrint(null, 3, "Last position set! " + lastPosition.x + " " + lastPosition.y + " " + lastPosition.z)
		}

		else if(phaseTimer > 600) {
			readyToChangePhase = true
			currentFinalePhase = MALIGNANT_TUMOR
		}
	}
	else if(currentFinalePhase == MALIGNANT_TUMOR && (deadTumorCounter >= 15 || phaseTimer > 1000)) {
		readyToChangePhase = true
		self.Teleport(true, lastPosition, false, QAngle(), false, Vector())
		teleportParticle.AcceptInput("Stop", null, null, null)
		//It's set to 0 twice but yknow just to be safe
		deadTumorCounter = 0
		currentFinalePhase = CARDIOMYOPATHY
	}
	else if(currentFinalePhase == CARDIOMYOPATHY && phaseTimer > 666) {
		readyToChangePhase = true
		currentFinalePhase = TACHYCARDIA
	}
	else if(currentFinalePhase == TACHYCARDIA) {
		if(phaseTimer > 133 && !pausePhaseTimerActions) {
			for (local i = 1; i <= MaxPlayers ; i++)
			{
				local player = PlayerInstanceFromIndex(i)
				if(player == null) continue
				if(IsPlayerABot(player)) continue
				//He's taking your damn legs
				player.AddCustomAttribute("SET BONUS: move speed set bonus", 0.5, -1)
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
			currentFinalePhase = SARCOMA
		}
	}
	else if(currentFinalePhase == SARCOMA) {
		//unused
		if(damageTakenThisPhase > 5000 && !pausePhaseTimerActions) {
			self.AddCondEx(71, (14.8 - (phaseTimer / 66.6)), null)
			self.SetScaleOverride(1.9)
			pausePhaseTimerActions = true
		}

		if(phaseTimer == 200) {
			sarcomaMimicParticle.AcceptInput("Start", null, null, null)
			EmitSoundEx({
				sound_name = "ambient/levels/labs/teleport_mechanism_windup1.wav",
				channel = 6,
				origin = self.GetCenter(),
				filter_type = RECIPIENT_FILTER_GLOBAL
			})
		}

		if(phaseTimer > 333 && !pausePhaseTimerActions) {
			EntFireByHandle(sarcomaMimicParticle, "Stop", null, -1, null, null)
			self.RemoveWeaponRestriction(SECONDARY_ONLY)
			self.AddWeaponRestriction(PRIMARY_ONLY)
			::CustomWeapons.GiveItem("Upgradeable TF_WEAPON_SYRINGEGUN_MEDIC", self)
			self.AddCondEx(33, 10, null)
			foreach(attr, val in buffSarcomaAttrs) {
				self.AddCustomAttribute(attr, val, -1)
			}
			self.SetScaleOverride(2.5)
			pausePhaseTimerActions = true
			EntFire("sarcoma_evolution_sound",  "PlaySound")
			EntFire("sarcoma_evolution_shake", "StartShake")
			DispatchParticleEffect("sarcoma_explode", self.GetOrigin(), Vector())
		}
		else if(phaseTimer > 1000) {
			readyToChangePhase = true
			//ClientPrint(null, 3, "Switching to Pneumonia!")
			currentFinalePhase = PNEUMONIA
		}
	}
	else if(currentFinalePhase == PNEUMONIA) {
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
				if(sticky.IsValid()) {
					DispatchParticleEffect("pneumonia_stickybomb_aura", sticky.GetCenter(), Vector())
				}
			}
			self.RemoveBotAttribute(ALWAYS_FIRE_WEAPON)
			pausePhaseTimerActions = true //stop collecting stickies
		}

		if(phaseTimer == 267) { //approx 4s
			if(!pneumoniaSpawner.IsValid()) return //mostly for wave reset
			foreach(sticky in stickyList) {
				if(sticky.IsValid()) { //in case they get det
					pneumoniaSpawner.SpawnEntityAtLocation(sticky.GetOrigin() + Vector(0, 0, 0), Vector())
				}
			}
			self.PressAltFireButton(0.1)
		}

		if(phaseTimer > 530) {
			readyToChangePhase = true
			currentFinalePhase = CARDIAC_ARREST
		}
	}
	//It all loops back
	else if(currentFinalePhase == CARDIAC_ARREST) {

		if(phaseTimer == 400) {
			EntFire("wakeup_sound*", "PlaySound")
			EntFire("wakeup_shake*", "StartShake")
		}

		else if(phaseTimer > 734) {
			readyToChangePhase = true
			currentFinalePhase = HEMORRHAGIC_FEVER
		}

	}
}

cleanup <- function() {
	AddThinkToEnt(self, null)
	NetProps.SetPropString(self, "m_iszScriptThinkFunction", "")
	delete ::ukgr
	if("phase1Callbacks" in getroottable()) {
		delete ::phase1Callbacks
	}
	NetProps.SetPropString(self, "m_iName", null)
	local preserved = {
		"self" : null
		"__vname" : null
		"__vrefs" : null
	}
	local scope = self.GetScriptScope()
	foreach(key, val in scope) { //doesn't kill ents, but map reset gets them eventually
		if(!(key in preserved)) { //why can you delete self
			delete scope[key]
		}
	}
}

self.SetCustomModelWithClassAnimations("models/bots/forgotten/disease_bot_medic_ukgr.mdl")
self.AddCondEx((TF_COND_PREVENT_DEATH) , -1, null)
thinkTable.offensiveThink <- offensiveThink
mainThink <- function() { //this is mostly to make the customweapons think works
	if(NetProps.GetPropInt(self, "m_lifeState") != 0) {
		cleanup()
		return
	}

	if(self.GetLocomotionInterface().IsStuck()) {
		EntFireByHandle(playerPush, "Enable", null, -1, null, null)
		EntFireByHandle(playerPush, "Disable", null, 0.5, null, null)
	}

	foreach(name, func in thinkTable) {
		func()
	}
	return -1
}
AddThinkToEnt(self, "mainThink")