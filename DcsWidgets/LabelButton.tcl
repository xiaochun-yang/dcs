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
package provide DCSLabelButton 1.0  

# load standard packages
package require Iwidgets
package require DCSAttribute
package require DCSButton


class DCS::LabelButton {
	
	# inheritance
	inherit AttributeDisplay

	public method handleAttributeUpdate
	public method handleComponentStatus
	public method addInput { args } {
        eval $itk_component(label) addInput $args
    }
	
	# call base class constructor
	constructor { args } {} {

		itk_component add ring {
			frame $itk_interior.r
		}

		itk_component add prompt {
			label $itk_component(ring).p -takefocus 0
		} {
			keep -font -width -height -state -activebackground
			keep -activeforeground -background
			keep -padx -pady
			rename -relief -promptRelief promptRelief PromptRelief
			rename -foreground -promptForeground promptForeground PromptForeground
			rename -width -promptWidth promptWidth PromptWidth
			rename -text -promptText promptText PromptText
		}
		
		itk_component add label {
			DCS::Button $itk_component(ring).l -disabledforeground black
		} {
			keep -font -width -height -state -activebackground
			keep -activeforeground -background -foreground -relief
			keep -padx -pady 
            keep -command
            keep -activeClientOnly
            keep -systemIdleOnly
			ignore -text
		}

		pack $itk_component(prompt) -side left
		pack $itk_component(label) -side left
		pack $itk_component(ring)

		eval itk_initialize $args
	}
	
	destructor {
	}
}

body DCS::LabelButton::handleAttributeUpdate { component_ targetReady_ alias_ contents_ - } {
	#puts "handle contents $contents_"
	if { ! $targetReady_} return
	
	set text $contents_
	
	$itk_component(label) configure -text $text -state normal
}

body DCS::LabelButton::handleComponentStatus { component_ targetReady_ alias_ status_ - } {
	#puts "handle status $status_"
	if { ! $targetReady_} return
	
	if { $status_ != "inactive" } {
		$itk_component(label) configure -state disabled
	} else {
		$itk_component(label) configure -state normal
	}
}