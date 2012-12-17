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
##########################################################################
#
#                       Permission Notice
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTA-
# BILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
# EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
# THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
##########################################################################


# provide the DCSDevice package
package provide DCSLVDTForBL122 1.0  

# load standard packages
package require Iwidgets
package require DCSAttribute


class DCS::LVDTViewForBL122 {
	# inheritance
	inherit AttributeDisplay

	public method handleAttributeUpdate
	public method handleComponentStatus

    	private variable m_nameList [list \
    	"Ion Chamber 1"      "Ion Chamber 2"     "Ion Chamber 3"    "Ion Chamber 4" \
    	"Ion Chamber 5"      "Ion Chamber 6"     "Ion Chamber 7"    "Ion Chamber 8"]
    #	"M0 SSRL SLIT"    "M0 SPEAR SLIT"  "M0 HORZ"       "M0 YAW" \
    #	"MONO SPEAR SLIT" "MONO SSRL SLIT" "MONO TOP SLIT" "MONO BOT SLIT"]

	# call base class constructor
	constructor { args } {} {
        itk_component add ring {
            frame $itk_interior.ring
        } {
            keep -background
        }
        for {set i 0} {$i < 8} {incr i} {
            set row [expr $i / 4]
            set col [expr $i % 4]

            set name_row  [expr $row * 2]
            set name_col  [expr $col * 2 + 1]

            set value_row [expr $row * 2 + 1]
            set value_col [expr $col * 2 + 1]

            set ch_row    [expr $row * 2 + 1]
            set ch_col    [expr $col * 2]

            itk_component add ch$i {
                label $itk_component(ring).c$i \
                -text "CH[expr $i % 8 + 1]" \
                -foreground white
            } {
                keep -background
            }

            itk_component add name$i {
                label $itk_component(ring).n$i \
                -text [lindex $m_nameList $i] \
                -foreground white
            } {
                keep -background
            }

            itk_component add value$i {
                label $itk_component(ring).v$i \
                -text "0000" \
                -width 6 \
                -justify right
            } {
                rename -foreground -valueForeground valueForeground Foreground
                rename -background -valueBackground valueBackground Background
			    keep -font -height -state
			    keep -relief
			    ignore -text -textvariable
            }
            grid $itk_component(name$i) -row $name_row -column $name_col
            grid $itk_component(value$i) -row $value_row -column $value_col -sticky we
            grid $itk_component(ch$i) -row $ch_row -column $ch_col -sticky e
        }
        for {set i 0} {$i < 8} {incr i} {
            set row [expr $i / 4]
            set col [expr $i % 4]

            set name_row  [expr $row * 2]
            set name_col  [expr $col * 2 + 1]

            set value_row [expr $row * 2 + 1]
            set value_col [expr $col * 2 + 1]

            set ch_row    [expr $row * 2 + 1]
            set ch_col    [expr $row * 2]
        }

		pack $itk_component(ring) -expand 1 -fill both
		eval itk_initialize $args
	}
	
	destructor {
	}
}

body DCS::LVDTViewForBL122::handleAttributeUpdate { component_ targetReady_ alias_ contents_ - } {
#	puts "lvdt view handle contents $contents_"
	if { ! $targetReady_} return

    	for {set i 0} {$i < 8} {incr i} {
        	set value [lindex $contents_ $i]
        	$itk_component(value$i) configure \
        	-text [format "%.3f" $value] \
        	-state normal
    	}
}

body DCS::LVDTViewForBL122::handleComponentStatus { component_ targetReady_ alias_ status_ - } {
	#puts "handle status $status_"
	if { ! $targetReady_} return
	
	if { $status_ != "inactive" } {
		configure -state disabled
	} else {
		configure -state normal
	}
}