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

    scope.phases = ["HF", "Dy", "MT", "Ca", "Ta", "Sa", "Pn", "CA"]
    scope.currentPhase = phases[0]
    scope.readyToChangePhase = true
    scope.spinAngle = 0

    scope.ukgrThink <- function() {
        if(NetProps.GetPropInt(self, "m_lifeState") != 0) {
            AddThinkToEnt(self, null)
            NetProps.SetPropString(self, "m_iszScriptThinkFunction", "")
            //return
        }
        if(readyToChangePhase) {
            switch(currentPhase) {
                case "HF":
                    self.GenerateAndWearItem("Upgradeable TF_WEAPON_FLAMETHROWER")
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
                    break;
                case "Dy":
                    EntFire("ukgr_hf_particles", Kill)
                    self.GenerateAndWearItem("Upgradeable TF_WEAPON_ROCKETLAUNCHER")
                    self.AddCustomAttribute("damage bonus", 0.25, -1)
                    self.AddCustomAttribute("fire rate bonus", 0.1, -1)
                    self.AddCustomAttribute("projectile spread angle penalty", 6, -1)
                    self.AddCustomAttribute("faster reload rate", -1, -1)
                    //Make him look up
                    
            }
            readyToChangePhase = false
        }
        if(currentPhase == "HF") {
            spinAngle = spinAngle + 12
			self.SnapEyeAngles(QAngle(0, spinAngle, 0))
        }

        return -1
    }

    AddThinkToEnt(self, "ukgrThink")
}