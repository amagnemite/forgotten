IncludeScript("popextensions/customweapons.nut", )

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

    scope.ukgrThink <- function() {
        if(NetProps.GetPropInt(self, "m_lifeState") != 0) {
            AddThinkToEnt(self, null)
            NetProps.SetPropString(self, "m_iszScriptThinkFunction", "")
            //return
        }

        phaseTimer++

        if(readyToChangePhase) {
            phaseTimer = 0
            switch(currentPhase) {
                case "HF":
                    GiveItem("Upgradeable TF_WEAPON_FLAMETHROWER", self)
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
                    self.AddBotAttribute(ALWAYS_FIRE_WEAPON) //Carries over to Dyspnea phase!
                    break;
                case "Dy":
                    EntFire("ukgr_hf_particles", Kill)
                    GiveItem("Upgradeable TF_WEAPON_ROCKETLAUNCHER", self)
                    self.AddCustomAttribute("damage bonus", 0.25, -1)
                    self.AddCustomAttribute("fire rate bonus", 0.1, -1)
                    self.AddCustomAttribute("projectile spread angle penalty", 6, -1)
                    self.AddCustomAttribute("faster reload rate", -1, -1)

                    self.AddCustomAttribute("mod projectile heat seek power", 90, -1)
                    self.AddCustomAttribute("mod projectile heat aim error", 90, -1)
                    self.AddCustomAttribute("mod projectile heat aim time", 0.6, -1)
                    self.AddCustomAttribute("mod projectile heat no predict target speed", 1, -1)

                    self.AddCustomAttribute("projectile trail particle", "dyspnea_rockettrail", -1)
                    self.AddCustomAttribute("add cond on hit", 12, -1)
                    self.AddCustomAttribute("add cond on hit duration", 4, -1)
                    break;
                case "MT":
                    //Teleports offscreen and then 20 mini versions spawn
                    self.RemoveBotAttribute(SUPPRESS_FIRE)
                    //Teleport teleport woop woop
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


        return -1
    }

    AddThinkToEnt(self, "ukgrThink")
}