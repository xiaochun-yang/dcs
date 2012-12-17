proc inlineLightControl_initialize { } {
}

proc inlineLightControl_start { position } {
	# global variables
	variable beamstop_z
    variable beamstop_z_auto
    variable beamstop_z_auto_moving


    if {$position == "insert"} {
        set result [inlineLightAlreadyIn]
        if {$result} {
            return [lightsControl_start setup inline_insert]
        }

        foreach {lowerLimit upperLimit} [getGoodLimits beamstop_z] break;
        #move beamstop_z to 65.0
        move beamstop_z to $upperLimit
        wait_for_devices beamstop_z
        if {abs($beamstop_z - $upperLimit) > 1.0} {
            log_severe failed to move away beamstop for inline light
            return -code error failed_to_move_away_beamstop
        }

        insertInlineCamera 

        return 1
    } else {
        removeInlineCamera

        move beamstop_z to $beamstop_z_auto
        wait_for_devices beamstop_z
    }
}

proc inlineLightAlreadyIn { } {
    variable inlineLightStatus

    ##assume the position will not change during wait
    set index [expr [lsearch $inlineLightStatus INSERTED] +1]
    if {$index <= 0} {
        ### it will fail else where.
        return 0
    }
    set state [lindex $inlineLightStatus $index]
    if {$state == "yes"} {
        return 1
    }

    return 0
}
proc inlineLightAlreadyOut { } {
    variable inlineLightStatus

    ##assume the position will not change during wait
    set index [expr [lsearch $inlineLightStatus INSERTED] +1]
    if {$index <= 0} {
        ### it will fail else where.
        return 0
    }
    set state [lindex $inlineLightStatus $index]
    if {$state == "yes"} {
        return 0
    }

    return 1
}