#this operation is for scripted ion chamber
proc ion_chamber4_op_initialize {} {
}

proc ion_chamber4_op_start { time_in_second } {
    #variable ion_chamber_offset
        
    get_encoder ion_chamber4
    set encoderValue [wait_for_encoder ion_chamber4]
    return [expr $encoderValue]
#    return [expr $encoderValue + $ion_chamber_offset]
}