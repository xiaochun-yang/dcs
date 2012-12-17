### look at reposition_phi.tcl for document
proc reposition_x_initialize { } {
    set_children sample_x sample_y
    ### gonio_phi will NOT affect reposition_xy

    set_triggers reposition_origin
    set_siblings reposition_y
}
proc reposition_x_move { new_x } {
    global gDevice

    #### change here, MUST also change repositionMove
    set new_sample_x \
    [reposition_calculate_sample_x $new_x $gDevice(reposition_y,target)]
    set new_sample_y \
    [reposition_calculate_sample_y $new_x $gDevice(reposition_y,target)]

    set xOrigin [getRepositionOrigin sample_x]
    set yOrigin [getRepositionOrigin sample_y]
    set newSx [expr $new_sample_x + $xOrigin]
    set newSy [expr $new_sample_y + $yOrigin]

    if {![limits_ok sample_x $newSx] || \
    ![limits_ok sample_y $newSy]} {
        return -code error "will exceed children motor limits"
    }

    move sample_x to $newSx
    move sample_y to $newSy
    wait_for_devices sample_x sample_y
}
proc reposition_x_set { new_x } {
    global gDevice
    variable sample_x
    variable sample_y

    set new_sample_x \
    [reposition_calculate_sample_x $new_x $gDevice(reposition_y,target)]
    set new_sample_y \
    [reposition_calculate_sample_y $new_x $gDevice(reposition_y,target)]

    set xOrigin [expr $sample_x - $new_sample_x]
    set yOrigin [expr $sample_y - $new_sample_y]

    setRepositionOrigin sample_x $xOrigin
    setRepositionOrigin sample_y $yOrigin
}
proc reposition_x_update { } {
    variable sample_x
    variable sample_y

    return [reposition_x_calculate $sample_x $sample_y]
}
proc getRepositionAngle { } {
    set phiOriginDegree   [getRepositionOrigin gonio_phi]
    set omegaOriginDegree [getRepositionOrigin gonio_omega]

    set angleDegree [expr $phiOriginDegree + $omegaOriginDegree]
    set angle [expr $angleDegree * 3.1415926 / 180.0]

    return $angle
}
proc reposition_x_calculate { x y } {
    variable sample_x
    variable sample_y

    set angle   [getRepositionAngle]
    set xOrigin [getRepositionOrigin sample_x]
    set yOrigin [getRepositionOrigin sample_y]

    set x [expr $sample_x - $xOrigin]
    set y [expr $sample_y - $yOrigin]

    set result [expr $x * cos($angle) + $y * sin($angle)]

    return $result
}
proc reposition_x_trigger { triggerDevice } {
    update_motor_position reposition_x [reposition_x_update] 1
}

proc reposition_calculate_sample_x { rp_x rp_y } {
    set angle [getRepositionAngle]
    set result [expr $rp_x * cos($angle) - $rp_y * sin($angle)]

    return $result
}
proc reposition_calculate_sample_y { rp_x rp_y } {
    set angle [getRepositionAngle]
    set result [expr $rp_x * sin($angle) + $rp_y * cos($angle)]

    return $result
}
