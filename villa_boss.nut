::bossSpawnFunction <- function() {

    

    self.GetScriptScope().ukgrThink <- function() {
        if(NetProps.GetPropInt(self, "m_lifeState") != 0) {
            AddThinkToEnt(self, null)
            NetProps.SetPropString(self, "m_iszScriptThinkFunction", "")
            //return
        }
        return 1
    }

    AddThinkToEnt(self, "ukgrThink")
}