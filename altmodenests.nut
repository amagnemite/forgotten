EntFire("bot_hint_sentrygun", "Disable")
EntFire("bot_hint_engineer_nest", "Disable")
//nests 1
SpawnEntityFromTable("bot_hint_sentrygun", {
	targetname = "nest_alt_1"
	startdisabled = true
	origin = Vector(-1142, 4416, 640)
	angles = QAngle(0, 135, 0)
	teamnum = TF_TEAM_BLUE
})
SpawnEntityFromTable("bot_hint_sentrygun", {
	targetname = "nest_alt_1"
	startdisabled = true
	origin = Vector(-830, 3760, 704)
	angles = QAngle(0, 195, 0)
	teamnum = TF_TEAM_BLUE
})
SpawnEntityFromTable("bot_hint_engineer_nest", {
	targetname = "nest_alt_1"
	startdisabled = true
	origin = Vector(-1142, 4416, 640)
	angles = QAngle(0, 135, 0)
	teamnum = TF_TEAM_BLUE
})
SpawnEntityFromTable("bot_hint_engineer_nest", {
	targetname = "nest_alt_1"
	startdisabled = true
	origin = Vector(-830, 3760, 704)
	angles = QAngle(0, 195, 0)
	teamnum = TF_TEAM_BLUE
})

//nests 2
SpawnEntityFromTable("bot_hint_sentrygun", {
	targetname = "nest_alt_2"
	startdisabled = true
	origin = Vector(-2963, 2963, 640)
	angles = QAngle(0, 135, 0)
	teamnum = TF_TEAM_BLUE
})
SpawnEntityFromTable("bot_hint_sentrygun", {
	targetname = "nest_alt_2"
	startdisabled = true
	origin = Vector(-2607, 2791, 640)
	angles = QAngle(0, 90, 0)
	teamnum = TF_TEAM_BLUE
})
SpawnEntityFromTable("bot_hint_engineer_nest", {
	targetname = "nest_alt_2"
	startdisabled = true
	origin = Vector(-2963, 2963, 640)
	angles = QAngle(0, 135, 0)
	teamnum = TF_TEAM_BLUE
})
SpawnEntityFromTable("bot_hint_engineer_nest", {
	targetname = "nest_alt_2"
	startdisabled = true
	origin = Vector(-2607, 2791, 640)
	angles = QAngle(0, 90, 0)
	teamnum = TF_TEAM_BLUE
})

//nests 3
SpawnEntityFromTable("bot_hint_sentrygun", {
	targetname = "nest_alt_3"
	startdisabled = true
	origin = Vector(-2892, 2138, 576)
	angles = QAngle(0, 195, 0)
	teamnum = TF_TEAM_BLUE
})
SpawnEntityFromTable("bot_hint_engineer_nest", {
	targetname = "nest_alt_3"
	startdisabled = true
	origin = Vector(-2892, 2138, 576)
	angles = QAngle(0, 195, 0)
	teamnum = TF_TEAM_BLUE
})

//nests 4
SpawnEntityFromTable("bot_hint_sentrygun", {
	targetname = "nest_alt_4"
	startdisabled = true
	origin = Vector(-1040, 2192, 576)
	angles = QAngle(0, 240, 0)
	teamnum = TF_TEAM_BLUE
})
SpawnEntityFromTable("bot_hint_engineer_nest", {
	targetname = "nest_alt_4"
	startdisabled = true
	origin = Vector(-1040, 2192, 576)
	angles = QAngle(0, 240, 0)
	teamnum = TF_TEAM_BLUE
})

//nests 5
SpawnEntityFromTable("bot_hint_sentrygun", {
	targetname = "nest_alt_5"
	startdisabled = true
	origin = Vector(-2569, 2188, 1216)
	angles = QAngle(0, 15, 0)
	teamnum = TF_TEAM_BLUE
})
SpawnEntityFromTable("bot_hint_sentrygun", {
	targetname = "nest_alt_5"
	startdisabled = true
	origin = Vector(-2864, 1423, 1216)
	angles = QAngle(0, 120, 0)
	teamnum = TF_TEAM_BLUE
})
SpawnEntityFromTable("bot_hint_sentrygun", {
	targetname = "nest_alt_5"
	startdisabled = true
	origin = Vector(-1872, 1680, 1344)
	angles = QAngle(0, 120, 0)
	teamnum = TF_TEAM_BLUE
})
SpawnEntityFromTable("bot_hint_engineer_nest", {
	targetname = "nest_alt_5"
	startdisabled = true
	origin = Vector(-2569, 2188, 1291)
	angles = QAngle(0, 15, 0)
	teamnum = TF_TEAM_BLUE
})
SpawnEntityFromTable("bot_hint_engineer_nest", {
	targetname = "nest_alt_5"
	startdisabled = true
	origin = Vector(-2864, 1423, 1291)
	angles = QAngle(0, 120, 0)
	teamnum = TF_TEAM_BLUE
})
SpawnEntityFromTable("bot_hint_engineer_nest", {
	targetname = "nest_alt_5"
	startdisabled = true
	origin = Vector(-1872, 1680, 1344)
	angles = QAngle(0, 120, 0)
	teamnum = TF_TEAM_BLUE
})

SpawnEntityFromTable("filter_tf_bot_has_tag", {
	targetname = "engibotfilter"
	tags = "ws11"
})
local trigger = SpawnEntityFromTable("trigger_multiple", {
	origin = Vector(-2592, -864, 1424)
	filtername = "engibotfilter"
	spawnflags = 1
	"OnEndTouchAll" : "!caller,callscriptfunction,activateNests,0,-1"
})
trigger.SetSolid(2)
trigger.SetSize(Vector(-256, -256, -16), Vector(256, 256, 16))
trigger.ValidateScriptScope()
local scope = trigger.GetScriptScope()
scope.nests1 <- ["nest_leftfirst_3", "nest_alt_1"]
scope.nests2 <- ["nest_leftfirst_5", "nest_alt_2"]
scope.nests3 <- ["nest_left_1", "nest_right_1", "nest_alt_3"]
scope.nests4 <- ["nest_leftfirst_1", "nest_alt_4"]
scope.nests5 <- ["nest_alt_5"]
scope.nests6 <- ["nest_rightsecond_3", "nest_rightsecond_9"]
scope.nests7 <- ["nest_leftsecond_5", "nest_leftsecond_6"]

scope.activateNests <- function() {
	local altmodeScope = Entities.FindByName(null, "altmode_chaos_script").GetScriptScope()
	local room = altmodeScope.getRoom("ws11")
	local list = "nests" + room
	foreach(name in self.GetScriptScope()[list]) {
		EntFire(name, "Enable")
	}
}