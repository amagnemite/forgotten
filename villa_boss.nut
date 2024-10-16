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

    scope.ukgrThink <- function() {
        if(NetProps.GetPropInt(self, "m_lifeState") != 0) {
            AddThinkToEnt(self, null)
            NetProps.SetPropString(self, "m_iszScriptThinkFunction", "")
            //return
        }
        if(readyToChangePhase) {
            switch(readyToChangePhase) {
                case "HF":
                    
            }
        }
        return 1
    }

    AddThinkToEnt(self, "ukgrThink")
}