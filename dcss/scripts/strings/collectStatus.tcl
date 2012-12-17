#
#                        Copyright 2001
#                              by
#                 The Board of Trustees of the 
#               Leland Stanford Junior University
#                      All rights reserved.
#
#                       Disclaimer Notice
#
#     The items furnished herewith were developed under the sponsorship
# of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
# Leland Stanford Junior University, nor their employees, makes any war-
# ranty, express or implied, or assumes any liability or responsibility
# for accuracy, completeness or usefulness of any information, apparatus,
# product or process disclosed, or represents that its use will not in-
# fringe privately-owned rights.  Mention of any product, its manufactur-
# er, or suppliers shall not, nor is it intended to, imply approval, dis-
# approval, or fitness for any particular use.  The U.S. and the Univer-
# sity at all times retain the right to use and disseminate the furnished
# items for any purpose whatsoever.                       Notice 91 02 01
#
#   Work supported by the U.S. Department of Energy under contract
#   DE-AC03-76SF00515; and the National Institutes of Health, National
#   Center for Research Resources, grant 2P41RR01209. 
#

proc STRING_initialize { {reuse 0} } {
    variable ::nScripts::STRING
	#reset the string to 0 on startup
	set STRING "0 {DCSS was reset.} 0 {} {} {} {}"

    if {!$reuse} {
        registerAbortCallback STRING_abort
    }
}


proc STRING_configure { args } {
	#simply return whatever is given us without any error checking
    set message [lindex $args 1]

    set map [list \{ " " \} " "]

    set newMsg [string map $map $message]

    set result [lreplace $args 1 1 $newMsg]

	return $result
}

proc STRING_abort { } {
    STRING_initialize 1
}