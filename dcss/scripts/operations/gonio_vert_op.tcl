#this operation is for scripted ion chamber
proc gonio_vert_encoder_op_initialize {} {
}

proc gonio_vert_encoder_op_start { time_in_second } {
    variable gonio_vert_offset
        
    get_encoder gonio_vert_encoder
    set encoderValue [wait_for_encoder gonio_vert_encoder]

    return [expr $encoderValue + $gonio_vert_offset]
}