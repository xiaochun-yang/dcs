#this operation is for scripted ion chamber
proc detector_vert_encoder_op_initialize {} {
}

proc detector_vert_encoder_op_start { time_in_second } {
    get_encoder detector_vert_encoder
    set encoderValue [wait_for_encoder detector_vert_encoder]

    return $encoderValue
}