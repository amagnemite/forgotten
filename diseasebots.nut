::pneumoniaSpawner <- Entities.FindByName(null, "pneumonia_spawn_maker")
::uberFlaskNormalSpawner <- Entities.FindByName(null, "uber_flask_normal_maker")
::uberFlaskShortSpawner <- Entities.FindByName(null, "uber_flask_short_maker")
::containmentBreachActive <- false

PrecacheSound("vo/halloween_haunted1.mp3")
PrecacheSound("misc/halloween/spell_mirv_explode_secondary.wav")
PrecacheSound("ambient/grinder/grinderbot_03.wav")
PrecacheScriptSound("Weapon_DragonsFury.BonusDamageHit")
PrecacheScriptSound("Halloween.spell_overheal")
PrecacheScriptSound("Halloween.spell_lightning_cast")
PrecacheEntityFromTable({classname = "info_particle_system", effect_name = "hemorrhagic_fever_flamethrower"})
PrecacheEntityFromTable({classname = "info_particle_system", effect_name = "rd_robot_explosion"})
PrecacheEntityFromTable({classname = "info_particle_system", effect_name = "soldierbuff_blue_buffed"})
PrecacheEntityFromTable({classname = "info_particle_system", effect_name = "eyeboss_tp_vortex"})

::diseaseCallbacks <- {
	pneumoniaBot = null
	
	Cleanup = function() {
		for (local i = 1; i <= MaxPlayers ; i++)
		{
			local player = PlayerInstanceFromIndex(i)
			if(player == null) continue
			if(IsPlayerABot(player)) continue
			if(player.GetTeam() != TF_TEAM_RED) continue

			player.SetScriptOverlayMaterial(null)
			player.RemoveCustomAttribute("move speed penalty")
			player.RemoveCustomAttribute("halloween increased jump height")
			player.RemoveCustomAttribute("damage force reduction")
			if("playerDebuffThink" in player.GetScriptScope().thinkTable) {
				delete player.GetScriptScope().thinkTable.playerDebuffThink
			}
		}
		EntFire("uber_flask_normal_prop*", "Kill", -1)
		EntFire("uber_flask_normal_trigger*", "Kill", -1)
		EntFire("uber_flask_short_prop*", "Kill", -1)
		EntFire("uber_flask_short_trigger*", "Kill", -1)

		delete ::diseaseCallbacks
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

	OnGameEvent_player_death = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		if (player == null) return
		if(!IsPlayerABot(player)) return

		if(player.HasBotTag("special_disease") && !player.HasBotTag("Malignant_Tumor") && !player.HasBotTag("UKGR_Tumor")) {
			local center = player.GetCenter() //spawnentityatlocation is dumb
			uberFlaskNormalSpawner.SpawnEntityAtLocation(center, Vector())
			//EntFire("uber_flask_normal_prop*", "AddOutput", "renderfx 10", 12)
			EntFire("uber_flask_normal_prop*", "RunScriptCode", "diseaseCallbacks.killInTime(self, 3, 12)", -1)
			EntFire("uber_flask_normal_trigger*", "RunScriptCode", "diseaseCallbacks.killInTime(self, 3, 12)", -1)
			return
		}

		if(player.HasBotTag("Hemorrhagic_Fever")) {
			EntFire("hemorrhagic_fever_trigger", "Disable")
			local hemorrhagicFeverParticle = null
			while(hemorrhagicFeverParticle = Entities.FindByName(hemorrhagicFeverParticle, "hemorrhagic_fever_fire_particles")) {
				hemorrhagicFeverParticle.AcceptInput("Stop", null, null, null)
			}
			EntFire("hemorrhagic_fever_weapon_particles", "Stop")
			if(player.GetScriptScope().rageParticle.IsValid()) {
				player.GetScriptScope().rageParticle.Kill()
			}
			delete player.GetScriptScope().rageParticle
		}
		if(!player.HasBotTag("Malignant_Tumor") && !player.HasBotTag("UKGR_Tumor")) return

		local victim = null

		DispatchParticleEffect("malignant_tumor_explode", player.GetCenter(), Vector())

		//check if this channel is correct
		EmitSoundEx({
			sound_name = "misc/halloween/spell_mirv_explode_secondary.wav",
			channel = 6,
			origin = player.GetCenter(),
			filter_type = RECIPIENT_FILTER_GLOBAL
		})

		while(victim = Entities.FindByClassnameWithin(victim, "player", player.GetCenter(), 180)) {
			if(victim.GetTeam() == TF_TEAM_RED) {
				local distance = (victim.GetCenter() - player.GetCenter()).Length()

				local shouldDamage = true
				//printl("distance " + distance)
				//DebugDrawCircle(player.GetCenter(), Vector(255, 0, 0), 127, 146, true, 1)

				local traceTable = {
					start = player.GetCenter()
					end = victim.GetCenter()
				}
				TraceLineEx(traceTable)

				if(traceTable.hit && traceTable.enthit != victim) {
					//not los, don't damage them
					shouldDamage = false
				}

				if(shouldDamage) {
					local splash = distance / 2.88
					local damage = 125 * (1 - splash / 125)
					//printl("damage " + damage)

					victim.TakeDamageEx(player, player, null, Vector(1, 0, 0), player.GetCenter(), damage, DMG_BLAST)
					//diseaseCallbacks.playSound("mvm/dragons_fury_impact_bonus_damage_hit.wav", victim)
					diseaseCallbacks.playSound("Weapon_DragonsFury.BonusDamageHit", victim)
				}
			}
		}

		local center = player.GetCenter() + Vector(0, 0, 20)
		uberFlaskShortSpawner.SpawnEntityAtLocation(center, Vector())
		//EntFire("uber_flask_short_prop*", "AddOutput", "renderfx 10", 1)
		EntFire("uber_flask_short_prop*", "RunScriptCode", "diseaseCallbacks.killInTime(self, 2, 1)", -1)
		EntFire("uber_flask_short_trigger*", "RunScriptCode", "diseaseCallbacks.killInTime(self, 2, 1)", -1)
	}

	OnGameEvent_player_spawn = function(params) {
		local player = GetPlayerFromUserID(params.userid)

		if(player == null) return
		if(player.GetTeam() != TF_TEAM_RED && player.GetTeam() != TF_TEAM_BLUE) return

		if(!IsPlayerABot(player)) {
			EntFireByHandle(player, "RunScriptCode", "diseaseCallbacks.addPlayerDebuffThink()", -1, player, null)
		}
		else {
			EntFireByHandle(player, "RunScriptCode", "diseaseCallbacks.specialDiseaseCheck()", -1, player, null)
			if(containmentBreachActive) EntFireByHandle(player, "RunScriptCode", "diseaseCallbacks.applyContainmentBreachBuffs()", -1, player, null)
		}
	}
	
	setupPneumoniaSpawner = function() {
		local template = Entities.FindByName(null, "pneumonia_spawn_template")
		template.ValidateScriptScope()
		local scope = template.GetScriptScope()
		
		scope.PreSpawnInstance <- function(classname, targetname) { //this needs to be present
			//printl(classname + " " + targetname)
		}
	
		scope.PostSpawn <- function(entities) {
			foreach(targetname, handle in entities) {
				if(targetname == "pneumonia_spawn_e_hurt") {
					handle.ValidateScriptScope()
					handle.GetScriptScope().owner <- diseaseCallbacks.pneumoniaBot
					handle.GetScriptScope().takePneumoniaDamage <- function() {
						activator.TakeDamage(50, DMG_POISON, owner)
					}
				}
				EntFireByHandle(handle, "Kill", null, 2, null, null)
				//printl(targetname + " " + handle)
			}
		}
	}
	
	applyContainmentBreachBuffs = function () {
		if(!activator.HasBotTag("UKGR") && !activator.HasBotTag("UKGR_TUMOR")) return
		activator.AddCondEx(72, -1, null)
	}

	specialDiseaseCheck = function() {
		local tags = {}
		activator.GetAllBotTags(tags)

		foreach(i, tag in tags) {
			switch(tag) {
				case "Pneumonia":
					activator.SetCustomModelWithClassAnimations("models/bots/forgotten/disease_bot_medic.mdl")
					activator.AcceptInput("RunScriptCode", "diseaseCallbacks.addPneumoniaThink()", activator, null)
					break
				case "Sarcoma_w6":
					activator.SetCustomModelWithClassAnimations("models/bots/forgotten/disease_bot_heavy_boss.mdl")
					break
				case "Sarcoma":
					activator.SetCustomModelWithClassAnimations("models/bots/forgotten/disease_bot_heavy_boss.mdl")
					activator.AcceptInput("RunScriptCode", "diseaseCallbacks.addSarcomaThink()", activator, null)
					break
				case "Dyspnea":
					activator.SetCustomModelWithClassAnimations("models/bots/forgotten/disease_bot_soldier_boss.mdl")
					break
				case "Tachycardia":
					activator.SetCustomModelWithClassAnimations("models/bots/forgotten/disease_bot_scout_boss.mdl")
					break
				case "UKGR_Tumor":
					activator.SetCustomModelWithClassAnimations("models/bots/forgotten/disease_bot_medic.mdl")
					break
				case "Malignant_Tumor":
					activator.SetCustomModelWithClassAnimations("models/bots/forgotten/disease_bot_heavy.mdl")
					break
				case "Cardiomyopathy":
					activator.SetCustomModelWithClassAnimations("models/bots/forgotten/disease_bot_demo_boss.mdl")
					break
				case "Hemorrhagic_Fever":
					activator.SetCustomModelWithClassAnimations("models/bots/forgotten/disease_bot_pyro_boss.mdl")
					break
				case "gmed":
					activator.AcceptInput("runscriptcode", "diseaseCallbacks.addMedBotThink()", activator, null)
					break
				default:
					break
			}
		}
	}

	addPneumoniaThink = function() {
		pneumoniaBot = activator
		activator.GetScriptScope().pneumoniaThink <- function() {
			if(NetProps.GetPropInt(self, "m_lifeState") != 0) {
				AddThinkToEnt(self, null)
				NetProps.SetPropString(self, "m_iszScriptThinkFunction", "")
				if("pneumoniaBot" in diseaseCallbacks) {
					pneumoniaBot = null
				}
			}
			if(!pneumoniaSpawner.IsValid()) return //mostly for wave reset
			
			pneumoniaSpawner.SpawnEntityAtEntityOrigin(self)
			
			return 1
		}
		AddThinkToEnt(activator, "pneumoniaThink")
	}
	
	addSarcomaThink = function() {
		//Stage 0 = Unarmed bot (Has SuppressFire) 0.8 scale 1.5 speed
		//Stage 1 = Melee bot 1.25 scale 1 speed
		//Stage 2 = Stock shotgun bot 1.5 scale 0.75 speed
		//Stage 3 = Strong shotgun bot 1.75 scale 0.66 speed
		//Stage 4 = Minigun bot 2.15 scale 0.5 speed
		//Stage 5 = Crit minigun 2.5 scale 0 speed

		local scope = activator.GetScriptScope()
		scope.sarcomaProgress <- 0
		scope.sarcomaStage <- 0
		scope.sarcomaThresholds <- [12, 24, 36, 48, 70, 999999] //Time to reach each stage, in seconds
		scope.sarcomaNextStage <- scope.sarcomaThresholds[0]

		scope.sarcomaPush <- SpawnEntityFromTable("trigger_push", {
			origin = activator.GetCenter()
			pushdir = QAngle(0, 0, 0)
			speed = 125
			startdisabled = true
			spawnflags = 1
			filtername = "team_red"
		})
		scope.selfPush <- SpawnEntityFromTable("trigger_push", {
			origin = activator.GetCenter()
			pushdir = QAngle(0, 0, 0)
			speed = 500
			startdisabled = true
			spawnflags = 1
			filtername = "team_blu"
		})
		scope.sarcomaPush.SetSolid(2)
		scope.sarcomaPush.SetSize(Vector(-100, -100, -104), Vector(100, 100, 104))
		scope.sarcomaPush.AcceptInput("SetParent", "!activator", activator, activator)
		scope.selfPush.SetSolid(2)
		scope.selfPush.SetSize(Vector(-100, -100, -104), Vector(100, 100, 104))
		scope.selfPush.AcceptInput("SetParent", "!activator", activator, activator)

		activator.GetScriptScope().sarcomaThink <- function() {
			if(NetProps.GetPropInt(self, "m_lifeState") != 0) {
				AddThinkToEnt(self, null)
				NetProps.SetPropString(self, "m_iszScriptThinkFunction", "")
				if(sarcomaPush.IsValid()) {
					sarcomaPush.Kill()
				}
				if(selfPush.IsValid()) {
					selfPush.Kill()
				}
				delete sarcomaPush
				delete selfPush
				return
			}

			if(self.GetLocomotionInterface().IsStuck()) { //safety for altmode, since he tends to hump walls and get stuck
				printl("sarcoma triggered antistuck")
				NetProps.SetPropVector(selfPush, "m_vecPushDir", self.EyeAngles() + Vector())
				EntFireByHandle(selfPush, "Enable", null, -1, null, null)
				EntFireByHandle(selfPush, "Disable", null, 0.5, null, null)
			}

			sarcomaProgress++
			if(sarcomaProgress < sarcomaNextStage) return 1

			sarcomaStage++
			sarcomaNextStage = sarcomaThresholds[sarcomaStage]
			NetProps.SetPropVector(sarcomaPush, "m_vecPushDir", self.EyeAngles() + Vector())
			EntFireByHandle(sarcomaPush, "Enable", null, -1, null, null)
			switch(sarcomaStage) {
				case 1:
					self.RemoveBotAttribute(SUPPRESS_FIRE)
					self.ClearAllWeaponRestrictions()
					self.AddWeaponRestriction(1)
					self.GenerateAndWearItem("The Killing Gloves of Boxing")
					// self.AddCustomAttribute("damage bonus", 1, -1)
					self.AddCustomAttribute("move speed bonus", 1, -1)
					self.SetScaleOverride(1.25)
					break
				case 2:
					self.ClearAllWeaponRestrictions()
					self.AddWeaponRestriction(4)
					// self.AddCustomAttribute("damage bonus", 18, -1)
					self.AddCustomAttribute("move speed bonus", 0.75, -1)
					self.SetScaleOverride(1.5)
					break
				case 3:
					self.AddCond(TF_COND_OFFENSEBUFF)
					// self.AddCustomAttribute("damage bonus", 18, -1)
					self.AddCustomAttribute("move speed bonus", 0.66, -1)
					self.SetScaleOverride(1.75)
					break
				case 4:
					self.ClearAllWeaponRestrictions()
					self.AddWeaponRestriction(2)
					self.RemoveCond(TF_COND_OFFENSEBUFF)
					// self.AddCustomAttribute("damage bonus", 1, -1)
					self.AddCustomAttribute("move speed bonus", containmentBreachActive ? 0.6 : 0.5, -1)
					self.SetScaleOverride(2.15)
					break
				case 5:
					self.AddCond(TF_COND_CRITBOOSTED_USER_BUFF)
					self.AddCustomAttribute("move speed bonus", containmentBreachActive ? 0.6 : 0.0001, -1)
					self.AddCustomAttribute("health drain", -40, -1)
					self.AddCustomAttribute("dmg taken increased", 2.5, -1)
					self.SetScaleOverride(2.5)
					break
				default:
					break
			}
			local audioEntity = null
			while(audioEntity = Entities.FindByName(audioEntity, "sarcoma_evolution_sound")) {
				audioEntity.AcceptInput("PlaySound", null, null, null)
			}
			EntFire("sarcoma_evolution_shake", "StartShake")
			DispatchParticleEffect("sarcoma_explode", self.GetOrigin(), Vector())
			EntFireByHandle(sarcomaPush, "Disable", null, 0.5, null, null)
			return 1
		}
		AddThinkToEnt(activator, "sarcomaThink")
	}

	//placeholder name
	addMedBotThink = function() {
		::medbot <- activator
		NetProps.SetPropString(activator, "m_iName", "medbot") //needed for particle nonsense
		activator.ValidateScriptScope()
		local scope = activator.GetScriptScope()
		scope.MOVESPEEDBASE <- 0.5
		scope.HEALTHBONUS <- 200
		scope.playersEaten <- 0
		scope.medigun <- null
		scope.deadSupport <- 0
		scope.support <- []
		scope.supportTimer <- Timer()
		for(local i = 0; i < NetProps.GetPropArraySize(activator, "m_hMyWeapons"); i++) {
			local wep = NetProps.GetPropEntityArray(activator, "m_hMyWeapons", i)

			if(wep && wep.GetClassname() == "tf_weapon_medigun") {
				scope.medigun = NetProps.GetPropEntityArray(activator, "m_hMyWeapons", i);
				break;
			}
		}

		for(local i = 1; i <= MaxPlayers; i++) {
			local player = PlayerInstanceFromIndex(i)
			if(player == null) continue
			if(!IsPlayerABot(player)) continue
			if(NetProps.GetPropInt(player, "m_lifeState") != LIFE_ALIVE) continue
			if(!player.HasBotTag("gmedsupport")) continue

			scope.support.append(player)
		}

		scope.offensiveThink <- function() {
			if(NetProps.GetPropInt(self, "m_lifeState") != 0) {
				cleanup()
				return
			}

			//printl("dead support " + deadSupport)
			if(deadSupport >= 5 && supportTimer.Expired()) {
				local LOCATION = Vector(-3122, 2817, 800)
				local particle = SpawnEntityFromTable("info_particle_system", {
					effect_name = "eyeboss_tp_vortex"
					start_active = true
					origin = LOCATION
				})
				EntFireByHandle(particle, "kill", null, 2, null, null)
				foreach(supporter in support) {
					supporter.Teleport(true, LOCATION, false, QAngle(), false, Vector())
				}
				deadSupport = 0
			}

			if(self.GetHealth() < self.GetMaxHealth() && deadSupport < 5) {
				printl("entering defense")
				EntFire("pop_interface", "ChangeBotAttributes", "EatBots", -1)
				AddThinkToEnt(self, "defensiveThink")
			}
		}

		scope.defensiveThink <- function() {
			if(NetProps.GetPropInt(self, "m_lifeState") != 0) {
				cleanup()
				return
			}
			if(deadSupport >= 5) {
				printl("entering offense")
				EntFire("pop_interface", "ChangeBotAttributes", "ShootPlayers", -1)
				supportTimer.Start(10)
				AddThinkToEnt(self, "offensiveThink")
				return
			}

			local target = self.GetHealTarget()
			if(target != null) {
				DispatchParticleEffect("rd_robot_explosion", target.GetOrigin(), Vector())
				target.TakeDamageCustom(self, target, medigun, Vector(0, 0, 1), target.GetCenter(),
					1000, DMG_BLAST, TF_DMG_CUSTOM_MERASMUS_ZAP);
				EmitSoundEx({
					sound_name = "ambient/grinder/grinderbot_03.wav",
					channel = 6,
					origin = target.GetCenter(),
					filter_type = RECIPIENT_FILTER_PAS
				})
				strengthen()
			}
		}

		scope.cleanup <- function() {
			//foreac(bot in support) {
			
			//}
			AddThinkToEnt(self, null)
			NetProps.SetPropString(self, "m_iszScriptThinkFunction", "")
			delete MOVESPEEDBASE
			delete HEALTHBONUS
			delete playersEaten
			delete ::medbot
			delete ::medBotCallbacks
			NetProps.SetPropString(self, "m_iName", null)
		}

		scope.strengthen <- function() {
			playersEaten++
			self.AddCustomAttribute("max health additive bonus", HEALTHBONUS * playersEaten, -1)
			self.SetHealth(self.GetHealth() + HEALTHBONUS)
			self.AddCustomAttribute("damage bonus", 1 + 0.25 * playersEaten, -1)
			self.AddCustomAttribute("move speed bonus", MOVESPEEDBASE + 0.1 * playersEaten, -1)
			local particle = SpawnEntityFromTable("info_particle_system", {
				origin = self.GetOrigin()
				effect_name = "soldierbuff_blue_buffed"
				start_active = true
			})
			particle.AcceptInput("SetParent", "medbot", null, null)
			EntFireByHandle(particle, "Kill", null, 0.3, null, null)
		}

		::medBotCallbacks <- {
			OnGameEvent_player_death = function(params) {
				local victim = GetPlayerFromUserID(params.userid)
				local inflictor = EntIndexToHScript(params.inflictor_entindex)
				if(IsPlayerABot(victim)) {
					if(victim.HasBotTag("gmedsupport")) {
						medbot.GetScriptScope().deadSupport++
						//printl("team " + victim.GetTeam())
						EntFireByHandle(victim, "runscriptcode", "self.ForceChangeTeam(TF_TEAM_BLUE, true)", -1, null, null)
						EntFireByHandle(victim, "runscriptcode", "self.ForceRespawn()", -1, null, null)
						EntFireByHandle(victim, "runscriptcode", "self.AddBotTag(\"gmedsupport\")", -1, null, null)
						//this doesn't clean up the bots, which probably isn't a problem
					}
				}
				else {
					if(IsPlayerABot(inflictor) && inflictor.HasBotTag("gmed")) {
						medbot.AcceptInput("CallScriptFunction", "strengthen", null, null)
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
		__CollectGameEventCallbacks(medBotCallbacks)
		AddThinkToEnt(activator, "offensiveThink")
	}

	addPlayerDebuffThink = function() {
		//printl("Player Debuff Check is thonking...")
		local scope = activator.GetScriptScope()

		if(!("medigun" in scope) || !scope.medigun.IsValid()) {
			scope.medigun <- null
			for(local i = 0; i < NetProps.GetPropArraySize(activator, "m_hMyWeapons"); i++) {
				local wep = NetProps.GetPropEntityArray(activator, "m_hMyWeapons", i)

				if(wep && wep.GetClassname() == "tf_weapon_medigun") {
					scope.medigun = NetProps.GetPropEntityArray(activator, "m_hMyWeapons", i);
					break;
				}
			}
		}

		scope.dyspneaDebuffed <- false
		scope.tachycardiaDebuffed <- false
		scope.playerDebuffThink <- function() {
			if(NetProps.GetPropInt(self, "m_lifeState") != 0) {
				delete self.GetScriptScope().thinkTable.playerDebuffThink
				return
			}
			if(timeCounter < DEFAULTTIME) {
				return
			}

			//Check for Dyspnea's debuff cond, apply screen overlay
			if(self.InCond(12) && !dyspneaDebuffed) {
				dyspneaDebuffed = true
				self.SetScriptOverlayMaterial("effects/forgotten_dyspnea_debuff")
				diseaseCallbacks.playSound("vo/halloween_haunted1.mp3", self)
			}
			else if(!self.InCond(12) && dyspneaDebuffed) {
				dyspneaDebuffed = false
				self.SetScriptOverlayMaterial(null)
			}

			//Check for Dyspnea's debuff cond
			if(self.InCond(12)) {
				local rageMeter = NetProps.GetPropFloat(self, "m_Shared.m_flRageMeter")
				local newRageMeter = rageMeter - 1.2 > 0 ? rageMeter - 1.2 : 0
				//printl("Rage: " + rageMeter)
				NetProps.SetPropFloat(self, "m_Shared.m_flRageMeter", newRageMeter)

				local uberMeter = NetProps.GetPropFloat(medigun, "m_flChargeLevel")
				local newUberMeter = uberMeter - 0.01 > 0 ? uberMeter - 0.01 : 0
				//printl("uber: " + uberMeter + " " + Time())
				NetProps.SetPropFloat(medigun, "m_flChargeLevel", newUberMeter)
			}

			//Check for tachycardia's debuff cond, apply screen overlay and attributes
			if(self.InCond(32) && !tachycardiaDebuffed) {
				tachycardiaDebuffed = true
				self.SetScriptOverlayMaterial("effects/forgotten_tachycardia_debuff")
				diseaseCallbacks.playSound("Halloween.spell_lightning_cast", self)
				self.AddCustomAttribute("move speed penalty", 2, -1)
				self.AddCustomAttribute("halloween increased jump height", 15, -1)
				self.AddCustomAttribute("damage force reduction", 2.5, -1)
			}
			else if(!self.InCond(32) && tachycardiaDebuffed) {
				tachycardiaDebuffed = false
				self.SetScriptOverlayMaterial(null)
				self.RemoveCustomAttribute("move speed penalty")
				self.RemoveCustomAttribute("halloween increased jump height")
				self.RemoveCustomAttribute("damage force reduction")
			}
		}
		scope.thinkTable.playerDebuffThink <- scope.playerDebuffThink
	}

	killInTime = function(ent, seconds, flashSeconds) {
		if(ent.GetScriptThinkFunc() == "killThink") {
			return
		}
		ent.ValidateScriptScope()
		ent.GetScriptScope().shouldFlash <- false
		ent.GetScriptScope().shouldKill <- false
		ent.GetScriptScope().seconds <- seconds
		ent.GetScriptScope().flashSeconds <- flashSeconds
		ent.GetScriptScope().killThink <- function() {
			if(!shouldFlash) {
				shouldFlash = true
				return flashSeconds
			}
			if(!shouldKill) {
				self.AcceptInput("AddOutput", "renderfx 10", null, null)
				shouldKill = true
				return seconds
			}
			else {
				self.Kill()
			}
		}
		AddThinkToEnt(ent, "killThink")
	}

	activateHemorrhagicFever = function() {
		local scope = activator.GetScriptScope()
		scope.flamethrower <- null

		for(local i = 0; i < NetProps.GetPropArraySize(activator, "m_hMyWeapons"); i++) {
			local wep = NetProps.GetPropEntityArray(activator, "m_hMyWeapons", i)

            if(wep && wep.GetClassname() == "tf_weapon_flamethrower") {
                scope.flamethrower = NetProps.GetPropEntityArray(activator, "m_hMyWeapons", i);
                break;
            }
        }
		
		
		scope.feverFireParticles <- SpawnEntityFromTable("info_particle_system", {
			targetname = "hemorrhagic_fever_weapon_particles"
			effect_name = "hemorrhagic_fever_flamethrower"
			//effect_name = "teleporter_mvm_bot_persist"
			//effect_name = "flamethrower_halloween"
			start_active = 1
			origin = activator.GetOrigin()
		})
		
		/*
		scope.feverFireParticles <- SpawnEntityFromTable("trigger_particle", {
			particle_name = "hemorrhagic_fever_flamethrower"
			attachment_type = 4
			attachment_name = "muzzle"
			spawnflags = 64
		})
		*/
		printl(scope.flamethrower)
		EntFireByHandle(scope.feverFireParticles, "StartTouch", "!activator", -1, scope.flamethrower, scope.flamethrower)

		EntFireByHandle(scope.feverFireParticles, "SetParent", "!activator", -1, scope.flamethrower, scope.flamethrower)
		EntFireByHandle(scope.feverFireParticles, "AddOutput", "angles " + activator.EyeAngles().x + " " + activator.EyeAngles().y + " " + activator.EyeAngles().z, 0.02, null, null)
		EntFireByHandle(scope.feverFireParticles, "RunScriptCode", "self.SetAbsOrigin(self.GetMoveParent().GetAttachmentOrigin(0) + Vector())", 0.02, null, null)
		EntFireByHandle(scope.feverFireParticles, "SetParentAttachmentMaintainOffset", "muzzle", 0.02, null, null)
		EntFireByHandle(scope.feverFireParticles, "runscriptcode", "printl(self.GetMoveParent())", 0.2, null, null)

		scope.rageParticle <- SpawnEntityFromTable("trigger_particle", {
			particle_name = "cardiac_arrest_buffed"
			attachment_type = 1
			spawnflags = 64
		})

		if(containmentBreachActive) {
			player.AddCustomAttribute("move speed bonus", 0.6, -1)
			player.AddCustomAttribute("damage bonus", 5, -1)
			player.AddCustomAttribute("bleeding duration", 5, -1)
			player.AddCustomAttribute("dmg taken increased", 2, -1)
			return
		}

		local hemorrhagicFeverTrigger = Entities.FindByName(null, "hemorrhagic_fever_trigger")
		// while(hemorrhagicFeverTrigger = Entities.FindByName(hemorrhagicFeverTrigger, "hemorrhagic_fever_trigger")) {
		hemorrhagicFeverTrigger.AcceptInput("Enable", null, null, null)
		hemorrhagicFeverTrigger.ValidateScriptScope()
		hemorrhagicFeverTrigger.GetScriptScope().owner <- activator
		hemorrhagicFeverTrigger.GetScriptScope().tickHemorrhagicFever <- function(ticksToAdd) {
			if(!("feverTicks" in activator.GetScriptScope())) {
				activator.GetScriptScope().feverTicks <- 0
				return
			}
			local newTicks = activator.GetScriptScope().feverTicks + ticksToAdd
			if(newTicks > 5) {
				newTicks = 5
			}
			else if(newTicks < 0) {
				newTicks = 0
			}
			activator.GetScriptScope().feverTicks = newTicks

			if(newTicks >= 5) {
				activator.TakeDamage(20, DMG_BURN, owner)
				diseaseCallbacks.playSound("Fire.Engulf", self)
			}
		}
		// }

		local hemorrhagicFeverParticle = null
		while(hemorrhagicFeverParticle = Entities.FindByName(hemorrhagicFeverParticle, "hemorrhagic_fever_fire_particles")) {
			hemorrhagicFeverParticle.AcceptInput("Start", null, null, null)
		}
	}

	containmentBreachBuffs = function() {
		for (local i = 1; i <= MaxPlayers ; i++)
		{
			local player = PlayerInstanceFromIndex(i)
			if(player == null) continue
			if(!IsPlayerABot(player)) continue

			player.AddCondEx(72, -1, null)
			if(player.HasBotTag("Sarcoma_w6")) {
				player.AddCustomAttribute("move speed bonus", 0.6, -1)
				player.AddCustomAttribute("health drain", -2, -1)
			}
			else if(player.HasBotTag("Hemorrhagic_Fever")) {
				player.AddCustomAttribute("move speed bonus", 0.6, -1)
				player.AddCustomAttribute("damage bonus", 5, -1)
				player.AddCustomAttribute("bleeding duration", 5, -1)
				player.AddCustomAttribute("dmg taken increased", 2, -1)

				EntFire("hemorrhagic_fever_trigger", "Disable")
				player.GetScriptScope().rageParticle.AcceptInput("StartTouch", "!activator", player, player)
				local hemorrhagicFeverParticle = null
				while(hemorrhagicFeverParticle = Entities.FindByName(hemorrhagicFeverParticle, "hemorrhagic_fever_fire_particles")) {
					hemorrhagicFeverParticle.AcceptInput("Stop", null, null, null)
				}

			}
			else if(player.HasBotTag("gmed")) {
				EntFire("pop_interface", "ChangeBotAttributes", "ShootPlayers", -1)
				player.GetScriptScope().cleanup()
				//this deletes the death callback, so for now he'll just have the buffs he gained before containmentbreaker
			}
		}
	}
}
__CollectGameEventCallbacks(diseaseCallbacks)
diseaseCallbacks.setupPneumoniaSpawner()
for (local i = 1; i <= MaxPlayers ; i++)
{
	local player = PlayerInstanceFromIndex(i)
	if(player == null) continue
	if(player.GetTeam() != TF_TEAM_RED) continue
	if(!IsPlayerABot(player)) {
		player.AcceptInput("RunScriptCode", "diseaseCallbacks.addPlayerDebuffThink()", player, null)
	}
}

::applyFlaskBoost <- function() {
	local selfHealth = self.GetHealth()
	self.SetHealth(selfHealth + 40)

	local scope = self.GetScriptScope()
	if(!("medigun" in scope) || !medigun.IsValid()) {
		scope.medigun <- null
		for(local i = 0; i < NetProps.GetPropArraySize(self, "m_hMyWeapons"); i++) {
			local wep = NetProps.GetPropEntityArray(self, "m_hMyWeapons", i)

			if(wep && wep.GetClassname() == "tf_weapon_medigun") {
				scope.medigun = NetProps.GetPropEntityArray(self, "m_hMyWeapons", i);
				break;
			}
		}
	}

	if(medigun == null) {
		return
	}

	local uberMeter = NetProps.GetPropFloat(medigun, "m_flChargeLevel")
	//printl("uber meter " + uberMeter)
	local newUberMeter = uberMeter + 0.12 < 1 ? uberMeter + 0.12 : 1
	NetProps.SetPropFloat(medigun, "m_flChargeLevel", newUberMeter)

	local rageMeter = NetProps.GetPropFloat(self, "m_Shared.m_flRageMeter")
	local newRageMeter = rageMeter + 12 < 100 ? rageMeter + 12 : 100
	NetProps.SetPropFloat(self, "m_Shared.m_flRageMeter", newRageMeter)

	diseaseCallbacks.playSound("Halloween.spell_overheal", self)
}