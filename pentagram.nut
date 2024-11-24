::playersInPentagram <- 0
::isHardmode <- false //this will be overwritten every time script is loaded, which will clear state
printl("hardmode is false")

::IncrementPentagram <- function() {
    playersInPentagram++
    switch(playersInPentagram) {
        case 0:
            break
        case 1:
            EntFire("pentagram_particle_1", "start")
            break
        case 2:
            EntFire("pentagram_particle_2", "start")
            break
        case 3:
            EntFire("pentagram_particle_3", "start")
            break
        case 4:
            EntFire("pentagram_particle_4", "start")
            break
        case 5:
            EntFire("pentagram_boom", "trigger")
			isHardmode = true
			EntFire("logic_script", "FireUser1")
            break
        default:
			break
    }
}

::DecrementPentagram <- function() {
    playersInPentagram--
    switch(playersInPentagram) {
        case 0:
            EntFire("pentagram_particle_1", "stop")
            break
        case 1:
            EntFire("pentagram_particle_2", "stop")
            break
        case 2:
            EntFire("pentagram_particle_3", "stop")
            break
        case 3:
            EntFire("pentagram_particle_4", "stop")
            break
        default:
			break
    }
}