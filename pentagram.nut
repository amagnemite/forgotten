::playersInPentagram <- 0

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