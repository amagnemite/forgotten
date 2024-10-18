IncludeScript("popextensions/customweapons.nut", getroottable())



::bossSpawnFunction <- function() {

    scope = self.GetScriptScope()
    
    //==MIMIC ORDER==
    //Hemorrhagic Fever
    //Dyspnea
    //Malignant Tumor
    //Cardiomyopathy
    //Tachycardia
    //Sarcoma
    //Pneumonia
    //Cardiac Arrest

    //Is this even necessary??
    //scope.phases = ["HF", "Dy", "MT", "Ca", "Ta", "Sa", "Pn", "CA"]
    scope.currentPhase = "HF"
    scope.readyToChangePhase = true
    scope.phaseTimer = 0
    scope.pausePhaseTimerActions = false
    scope.spinAngle = 0
    scope.deadTumorCounter = 0
    scope.lastPosition = Vector(0, 0, 0)
    scope.damageTakenThisPhase = 0

    //Disable altmode spawns to block tumors
    EntFire("spawnbot_altmode", "Disable", null, 1)

    scope.ukgrThink <- function() {
        if(NetProps.GetPropInt(self, "m_lifeState") != 0) {
            AddThinkToEnt(self, null)
            NetProps.SetPropString(self, "m_iszScriptThinkFunction", "")
            //return
        }

        phaseTimer++

        if(readyToChangePhase) {
            phaseTimer = 0
            pausePhaseTimerActions = false
            damageTakenThisPhase = 0
            switch(currentPhase) {
                case "HF":
                    GiveItem("Upgradeable TF_WEAPON_FLAMETHROWER", self)
                    EquipItem("Upgradeable TF_WEAPON_FLAMETHROWER", self)
                    // scope.feverFireParticles <- SpawnEntityFromTable("info_particle_system", {
                    //     targetname = "ukgr_hf_particles"
                    //     effect_name = "hemorrhagic_fever_flamethrower"
                    //     start_active = 1
                    //     origin = activator.GetOrigin()  
                    // })

                    // EntFireByHandle(scope.feverFireParticles, "SetParent", "!activator", -1, scope.flamethrower, scope.flamethrower)
                    // EntFireByHandle(scope.feverFireParticles, "AddOutput", "angles " + activator.EyeAngles().x + " " + activator.EyeAngles().y + " " + activator.EyeAngles().z, 0.02, null, null)
                    // EntFireByHandle(scope.feverFireParticles, "RunScriptCode", "self.SetAbsOrigin(self.GetMoveParent().GetAttachmentOrigin(0) + Vector())", 0.02, null, null)
                    // EntFireByHandle(scope.feverFireParticles, "SetParentAttachmentMaintainOffset", "muzzle", 0.02, null, null)
                    self.AddCustomAttribute("damage bonus", 2, -1)
                    self.AddBotAttribute(ALWAYS_FIRE_WEAPON) //Carries over to Dyspnea phase! Removed by the think later
                    break;
                case "Dy":
                    EntFire("ukgr_hf_particles", Kill)
                    GiveItem("Upgradeable TF_WEAPON_ROCKETLAUNCHER", self)
                    EquipItem("Upgradeable TF_WEAPON_ROCKETLAUNCHER", self)
                    self.AddCustomAttribute("damage bonus", 0.25, -1)
                    self.AddCustomAttribute("fire rate bonus", 0.1, -1)
                    self.AddCustomAttribute("projectile spread angle penalty", 6, -1)
                    self.AddCustomAttribute("faster reload rate", -1, -1)

                    self.AddCustomAttribute("mod projectile heat seek power", 90, -1)
                    self.AddCustomAttribute("mod projectile heat aim error", 180, -1)
                    self.AddCustomAttribute("mod projectile heat aim time", 0.6, -1)
                    self.AddCustomAttribute("mod projectile heat no predict target speed", 1, -1)

                    self.AddCustomAttribute("projectile trail particle", "dyspnea_rockettrail", -1)
                    self.AddCustomAttribute("add cond on hit", 12, -1)
                    self.AddCustomAttribute("add cond on hit duration", 4, -1)
                    break;
                case "MT":
                    GiveItem("The Crusader's Crossbow", self)
                    EquipItem("The Crusader's Crossbow", self)
                    self.RemoveCustomAttribute("fire rate bonus")
                    self.RemoveCustomAttribute("projectile spread angle penalty")
                    self.RemoveCustomAttribute("faster reload rate")
                    self.RemoveCustomAttribute("mod projectile heat seek power")
                    self.RemoveCustomAttribute("mod projectile heat aim error")
                    self.RemoveCustomAttribute("mod projectile heat aim time")
                    self.RemoveCustomAttribute("mod projectile heat no predict target speed")
                    self.RemoveCustomAttribute("projectile trail particle")
                    self.RemoveCustomAttribute("add cond on hit")
                    self.RemoveCustomAttribute("add cond on hit duration")
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
                        player.Teleport(true, lastPosition, false, QAngle(0,0,0), false, Vector(0,0,0))
                    }
                    //Remember to make tumors explode on death and deal 125 dmg to boss
                    break;
                case "Ca":
                    GiveItem("The Iron Bomber", self)
                    EquipItem("The Iron Bomber", self)
                    self.AddBotAttribute(HOLD_FIRE_UNTIL_FULL_RELOAD)
                    self.AddCustomAttribute("damage bonus", 0.5, -1)
                    self.AddCustomAttribute("fire rate bonus", 0.05, -1)
                    self.AddCustomAttribute("projectile spread angle penalty", 10, -1)
                    self.AddCustomAttribute("clip size upgrade atomic", 20, -1)
                    self.AddCustomAttribute("faster reload rate", 0.1, -1)
                    break;
                case "Ta":
                    self.RemoveCustomAttribute("damage bonus")
                    self.RemoveCustomAttribute("fire rate bonus")
                    self.RemoveCustomAttribute("projectile spread angle penalty")
                    self.RemoveCustomAttribute("clip size upgrade atomic")
                    self.RemoveCustomAttribute("faster reload rate")
                    // GiveItem("The Amputator", self)
                    // EquipItem("The Amputator", self)
                    // "Paintkit_proto_def_index" 3.16693e-43n
				    // "Set_item_texture_wear" 0
                    self.RemoveBotAttribute(HOLD_FIRE_UNTIL_FULL_RELOAD)
                    self.AddWeaponRestriction(MELEE_ONLY)

                    //Taunts to forcefully apply Tachycardia debuff on everyone
                    //Debuff function below
                    self.Taunt(TAUNT_BASE_WEAPON, 11)
                case "Sa":
                    //Oh no I'm unarmed!
                    self.AddWeaponRestriction(SECONDARY_ONLY)
                    self.SetScaleOverride(0.8)
                    self.AddCustomAttribute("move speed bonus", 2, -1)
                case "Pn":
                    self.SetScaleOverride(1.9)
                    self.AddWeaponRestriction(SECONDARY_ONLY)
                    GiveItem("Upgradeable TF_WEAPON_PIPEBOMBLAUNCHER", self)
                    EquipItem("Upgradeable TF_WEAPON_PIPEBOMBLAUNCHER", self)
                default:
                    break;
            }
            readyToChangePhase = false
        }
        if(currentPhase == "HF") {
            spinAngle = spinAngle + 12
			self.SnapEyeAngles(QAngle(0, spinAngle, 0))
            if(phaseTimer > 550) {
                readyToChangePhase = true
                currentPhase = "Dy"
            }
        }
        if(currentPhase == "Dy") {
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
                currentPhase = "MT"
            }
        }
        if(currentPhase == "MT" && deadTumorCounter >= 20) {
            readyToChangePhase = true
            //It's set to 0 twice but yknow just to be safe
            deadTumorCounter = 0
            currentPhase = "Ca"
        }
        if(currentPhase == "Ca" && phaseTimer > 666) {
            readyToChangePhase = true
            currentPhase = "Ta"
        }
        if(currentPhase == "Ta") {
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
                currentPhase = "Sa"
            }
        }
        if(currentPhase == "Sa") {

            if(damageTakenThisPhase > 5000 && !pausePhaseTimerActions) {
                self.AddCondEx(71, (14.8 - (phaseTimer / 66.6)), null)
                self.SetScaleOverride(1.9)
                pausePhaseTimerActions = true
            }

            if(phaseTimer > 666 && !pausePhaseTimerActions) {
                self.AddWeaponRestriction(PRIMARY_ONLY)
                GiveItem("The Brass Beast", self)
                EquipItem("The Brass Beast", self)
                self.AddCondEx(33, 10, null)
                self.AddCustomAttribute("damage bonus", 2, -1)
                self.SetScaleOverride(2.5)
                pausePhaseTimerActions = true
            }
            else if(phaseTimer > 1000) {
                readyToChangePhase = true
                currentPhase = "Pn"
            }
        }


        return -1
    }

    AddThinkToEnt(self, "ukgrThink")
}