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

#
# ScreeningSequenceConfig.tcl
#
# part of Screening UI
# used by Sequence.tcl
#

# ===================================================
package provide BLUICESequenceActions 1.0

package require Itcl

package require DCSDeviceFactory
package require DCSMessageBoard

package require BLUICEDetectorMenu
package require BLUICEDoseMode

::itcl::class ScreeningSequenceConfig {
	inherit ::itk::Widget DCS::Component

   public method selectNewAction 
   private variable m_scrollRegion {0 0 200 400}

   public method setCondensed { condensed_ } {
      set m_condensed $condensed_
      $itk_component(actions) setCondensed $condensed_
      $itk_component(parameters) setCondensed $condensed_
   }

   private variable m_condensed 0

	# contructor / destructor
	constructor { args } {}
   destructor {
   }

	private variable m_font "*-helvetica-bold-r-normal--15-*-*-*-*-*-*-*"

	private variable m_actionListStringObject
   private variable m_deviceFactory

}

# ===================================================

::itcl::body ScreeningSequenceConfig::constructor { args } {

   set m_deviceFactory [DCS::DeviceFactory::getObject]

    itk_component add s_canvas {
       ::iwidgets::scrolledframe $itk_interior.sc \
            -hscrollmode dynamic -vscrollmode dynamic
    } {}

   set actionSite [$itk_component(s_canvas) childsite]

   itk_component add actions {
	   ScreeningActionList $actionSite.sa  -font $m_font
	} {}

	itk_component add parameters {
		ScreeningParameters $actionSite.param \
        -enableWashBeforeMount [$itk_component(actions) isWashBeforeMountEnabled]
	} {
	}
	 
   # itk_component add condenseButton {
   #     button $itk_interior.cb -text "Condense: " -command [list $this setCondensed 1]
   # } {
   # }
   # itk_component add expandButton {
   #     button $itk_interior.eb -text "Expand: " -command [list $this setCondensed 0]
   # } {
   # }

   #pack $itk_component(condenseButton)
   #pack $itk_component(expandButton)
 
	itk_component add actionMsg {
		DCS::MessageBoard $itk_interior.msg -width 20
	} {}
    $itk_component(actionMsg) addStrings scn_action_msg
	
    #itk_component add robotMessage {
    #    DCS::Label $itk_interior.robotmsg \
    #    -anchor w \
    #    -relief sunken \
    #    -promptText "Robot" \
    #    -promptWidth 5 \
    #    -width 25
    #} {
    #}

    itk_component add screeningMessage {
        DCS::MessageBoard $itk_interior.screenmsg \
        -width 50
    } {
    }

	set m_actionListStringObject [$m_deviceFactory getObjectName screeningActionList]

	pack $itk_component(screeningMessage)
   pack $itk_component(s_canvas) -expand 1 -fill both
   pack $itk_component(actions)
   #place $itk_component(parameters) -x 180 -y 40

	#pack $itk_component(actionLabel)
	#pack $itk_component(scrolledActionFrame) -expand 1 -fill both
	#pack $itk_component(actionList) -expand 1 -fill both

	#grid $itk_component(actionSequenceFrame) -row 0 -column 0 -sticky news -rowspan 2
	#grid $itk_component(actionMsg) -row 2 -column 0 -sticky news
	#grid $itk_component(screeningParameters) -row 0 -column 1 -sticky new
	#pack $itk_component(robotMessage)
	#grid rowconfigure $itk_interior 0 -weight 1

	#grid columnconfigure $itk_interior 0 -weight 1
	#grid columnconfigure $itk_interior 1 -weight 1

    #link action list cell click to parameters
   $itk_component(actions) configure -selectActionCommand [list $this selectNewAction]

	eval itk_initialize $args

    setCondensed 0
    
	$itk_component(screeningMessage) addStrings screening_msg

    #set deviceFactory [DCS::DeviceFactory::getObject]
    #set obj2 [$deviceFactory createString robot_sample]
	#$itk_component(robotMessage) configure -component $obj2 -attribute contents
	announceExist
}

body ScreeningSequenceConfig::selectNewAction { index_} {
    if {0} {

    $itk_component(parameters) selectNewAction $index_

    foreach {x y w h} [$itk_component(actions) getOverlayCoord $index_] {break}
    set paramHeight [$itk_component(parameters) getParamFrameHeight $index_]

    set px [expr $x + 55]
    set py [expr $y +$h - $paramHeight]
    place $itk_component(parameters) -x $px -y $py

    } else {

   #first find out where the parameters should go if the scrolled region was completely stretched open
   foreach {x y} [$itk_component(actions) getOverlayCoord $index_] {break}

   #$itk_component(parameters) selectNewAction $index_
	#place $itk_component(parameters) -x $x -y $y
   

   #now find out how much our view is clipped in percent
   foreach {pClipY1 pClipY2} [$itk_component(s_canvas) yview] {break}
   #need height to convert percent into real pixel values
   set totalHeight [$itk_component(actions) getTotalHeight]
   #set totalHeight [$itk_component(actions) cget -height]
   set minViewable_y [expr $pClipY1 * $totalHeight]
   set maxViewable_y [expr $pClipY2 * $totalHeight]
   set paramHeight [$itk_component(parameters) getParamFrameHeight $index_]

   #center the parameter
   set y [expr $y - $paramHeight /2 +10]

   set maxViewable_y [expr $maxViewable_y -$paramHeight - 10]

   if {$y > $maxViewable_y } {set y $maxViewable_y } 
   if {$y < $minViewable_y } {set y $minViewable_y} 

   $itk_component(parameters) selectNewAction $index_
    set x [expr $x + 55]
	place $itk_component(parameters) -x $x -y $y

    }

}
::itcl::class ScreeningActionList {
	inherit ::itk::Widget DCS::Component

	itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -selectActionCommand selectActionCommand SelectActionCommand ""

	# contructor / destructor
	constructor { args } {}
	public method destructor

	public method setCellColor

    public method isWashBeforeMountEnabled { } {
        set mountNextDef [lindex $S_ACTION_STRUCTURE 0]
        foreach {a_index a_name a_configurable a_viewableCondensed a_condensedMandatory  a_condensedSelectIndex a_condensedCurrent } $mountNextDef break

        return $a_configurable
    }
	
	private method restoreBackgroundColor
	
	private variable blue  #a0a0c0
	private variable gray ""
	private variable red #c04080
	private variable green #00a040
	private variable yellow  #d0d000
   private common midhighlight #e0e0f0
	
	private variable m_sequenceOperation ""
	private variable m_actionListStringObject
	private variable m_crystalStatusStringObject
	private variable m_isRunning 1
   private variable m_currentAction -1
   private variable m_nextAction -1
   private variable m_currentCrystalName ""
   private variable m_nextCrystalName ""


	private method bindEventHandlers
	public method handleNextActionClick
	public method handleCellClick
	public method handleCheckboxClick
	public method sendCheckBoxStatesToServer
	public method sendNextActionToServer	
   public method configureActionPromptList 
   public method configureActionTextList 
	
	public method handleActionListChange
   public method handleCrystalStatusChange 

	public method setAllSelectionStates
   private variable m_deviceFactory
    private variable m_numActions 0

    private variable m_actionBboxArray


   private method displayRows 

   public method setCondensed 
   private variable m_condensed 0

    public method getOverlayCoord 
    public method handleActionMap { index }
    public method getTotalHeight 

    #MUST match screeningActionParameters
    # "Stop" is used as a Mark in ScreeningTask 
    #index textName configurable viewableCondensed condensedMandatory condensedSelectIndexMapping condensedCurrent 
    #yangx change Loop Aligment from 0 1 1 1 1 to 0 1 0 1 (from darkgree to blue) so that it can be selected

	public common S_ACTION_STRUCTURE {
		{0 "Mount Next Crystal     " 0 1 1 0  0         }
		{1 "Loop Alignment         " 0 1 0 1  1         }
		{2 "Stop                   " 0 1 0 2  2         }
		{3 "Video Snapshot         " 1 0 1 3  -         }
		{4 "Collect Image          " 1 1 1 3  {3 4}     }
		{5 "Rotate                 " 1 0 0 5  -         }
		{6 "Video Snapshot         " 1 0 0 5  -         }
		{7 "Collect Image          " 1 1 0 5  {5 6 7}   }
		{8 "Stop                   " 0 0 0 8  -         }
		{9 "Rotate                 " 1 0 0 9  -         }
		{10 "Video Snapshot        " 1 0 0 9  -         }
		{11 "Collect Image         " 1 1 0 9  {9 10 11 } }
		{12 "Excitation Scan       " 1 0 0 12 -        }
		{13 "ReOrient Sample       " 0 0 0 13 -        }
		{14 "Collect For Queue     " 0 0 0 14 -        }
		{15 "Stop                  " 0 1 0 15 15       }
		{16 "Warm Grabber Cycle    " 1 1 0 16 16 {5}   }
	}

    public proc setStopMandatory { yes_no } {
        set old [lindex $S_ACTION_STRUCTURE 2]
        if {$yes_no} {
            set new [lreplace $old 4 4 1]
        } else {
            set new [lreplace $old 4 4 0]
        }
        set S_ACTION_STRUCTURE [lreplace $S_ACTION_STRUCTURE 2 2 $new]
    }
}

::itcl::body ScreeningActionList::constructor { args } {
    array set m_actionBboxArray [list]

    set m_deviceFactory [DCS::DeviceFactory::getObject]
    set m_numActions [llength $S_ACTION_STRUCTURE]

	set f $itk_interior
	
	# Create and grid the action entries
	foreach actionDef $S_ACTION_STRUCTURE {
      foreach {a_index a_name a_configurable a_viewableCondensed a_condensedMandatory  a_condensedSelectIndex a_condensedCurrent } $actionDef break
	
		itk_component add actionPrompt$a_index {
			DCS::Button $f.state$a_index -relief flat -width 10 -padx 0 -pady 0 -systemIdleOnly 0
		} {
			keep -font
		}
#yangx change from blue to yellow
		itk_component add actionCheck$a_index {
			DCS::Checkbutton $f.check$a_index -selectcolor yellow -systemIdleOnly 0
		} {}

		
		itk_component add actionText$a_index {
			entry $f.cellA$a_index -relief flat -width 20
			#label $f.cellA$a_index -relief flat
		} {
			keep -font
		}
        bind $itk_component(actionText$a_index) <Map> "$this handleActionMap $a_index"

      #add spacer but not through component system for speed reasons
		label $f.space$a_index -relief flat -width 14

		#set the action text description
		$itk_component(actionText$a_index) insert 0 $a_name
		#$itk_component(actionText$a_index) configure -text $a_name
		$itk_component(actionText$a_index) configure -state disabled 
	}

   displayRows

	eval itk_initialize $args 

	set gray [cget -background]

	setCellColor 0

	bindEventHandlers

	set m_sequenceOperation [$m_deviceFactory getObjectName sequenceSetConfig]
	set m_actionListStringObject [$m_deviceFactory getObjectName screeningActionList]
	set m_crystalStatusStringObject [$m_deviceFactory getObjectName crystalStatus]

	::mediator register $this ::$m_actionListStringObject contents handleActionListChange
	::mediator register $this ::$m_crystalStatusStringObject contents handleCrystalStatusChange

	announceExist
}

::itcl::body ScreeningActionList::setCondensed { condensed_ } {
   set m_condensed $condensed_
   displayRows
   configureActionPromptList 
   configureActionTextList 
}

body ScreeningActionList::destructor {} {
	::mediator unregister $this $m_actionListStringObject contents
	::mediator unregister $this $m_crystalStatusStringObject contents
}

::itcl::body ScreeningActionList::displayRows { } {
	foreach actionDef $S_ACTION_STRUCTURE {
      foreach {a_index a_name a_configurable a_viewableCondensed a_condensedMandatory  a_condensedSelectIndex a_condensedCurrent } $actionDef break
      
      if { $m_condensed } {

         if { ! $a_viewableCondensed } {
            grid forget $itk_component(actionPrompt$a_index)
		      grid forget $itk_component(actionCheck$a_index)
		      grid forget $itk_component(actionText$a_index)
		      grid forget $itk_interior.space$a_index
         }
      } else {
         grid $itk_component(actionPrompt$a_index)  -column 0 -row $a_index -sticky we
		   grid $itk_component(actionCheck$a_index) -column 1  -row $a_index -sticky w
		   grid $itk_component(actionText$a_index) -column 2 -row $a_index -sticky w
		   grid $itk_interior.space$a_index -column 3 -row $a_index -sticky w
      }
   }
}

::itcl::body ScreeningActionList::getOverlayCoord {index_} {
    return $m_actionBboxArray($index_)
}
::itcl::body ScreeningActionList::handleActionMap {index_} {
    array set gridOptions [grid info $itk_component(actionText$index_)]
    set m_actionBboxArray($index_) [grid bbox $itk_interior $gridOptions(-column) $gridOptions(-row)]
}

::itcl::body ScreeningActionList::getTotalHeight {} {
   foreach {x_org y_org b_width b_height } [grid bbox $itk_interior ] {break}

   return $b_height

}

::itcl::body ScreeningActionList::bindEventHandlers {} {

	foreach actionDef $S_ACTION_STRUCTURE {
      foreach {a_index a_name a_configurable a_viewableCondensed a_condensedMandatory  a_condensedSelectIndex a_condensedCurrent } $actionDef break
		   bind $itk_component(actionPrompt$a_index) <Button-1>
		   $itk_component(actionCheck$a_index) config -command [list $this handleCheckboxClick $a_index]

      if { $a_configurable } {
		   bind $itk_component(actionText$a_index) <Enter> [list $this handleCellClick $a_index]
		   $itk_component(actionText$a_index) configure -relief sunken 
      }

	}
}


::itcl::body ScreeningActionList::setCellColor { selectIndex_ } {
		
	restoreBackgroundColor
	
	# set selected row to darkblue
	$itk_component(actionText$selectIndex_) config -background #c0c0ff 
}

::itcl::body ScreeningActionList::restoreBackgroundColor { } {
	# reset all cells to gray
	foreach actionDef $S_ACTION_STRUCTURE {
      foreach {a_index a_name a_configurable a_viewableCondensed a_condensedMandatory  a_condensedSelectIndex a_condensedCurrent } $actionDef break
      if { $a_configurable } {
		   $itk_component(actionText$a_index) config -background $midhighlight -foreground black
      } else {
		   $itk_component(actionText$a_index) config -background $gray -foreground black
      }
	}
}

::itcl::body ScreeningActionList::configureActionPromptList { } {
	foreach actionDef $S_ACTION_STRUCTURE {
      foreach {a_index a_name a_configurable a_viewableCondensed a_condensedMandatory  a_condensedSelectIndex a_condensedCurrent } $actionDef break
		set prompt $itk_component(actionPrompt$a_index)

      #forget binding by default
      bind forget $prompt <Enter>
		bind forget $prompt <Leave>
   
      $prompt configure -command ""

      if { $m_condensed &&  ! $a_viewableCondensed } continue


      #check if we should display the current arrow
      set exactMatch [expr $a_index == $m_currentAction]
      set condensedMatch [expr [lsearch $a_condensedCurrent $m_currentAction] != -1]

      if { (!$m_condensed && $exactMatch) || ($m_condensed && $condensedMatch) } {
         bind $prompt <Enter> ""
		   bind $prompt <Leave> ""
         $prompt configure -background $red -foreground black -activebackground $red  -disabledforeground black

         $prompt configure -text "Current->"
         continue
      }


      #check if we should display the next arrow. Don't display in condensed mode if running
      set exactMatch [expr $a_index == $m_nextAction]
      set condensedMatch [expr [lsearch $a_condensedCurrent $m_nextAction] != -1]
      if { (!$m_condensed && $exactMatch) || ($m_condensed && $condensedMatch && !$m_isRunning) } {
         bind $prompt <Enter> ""
		   bind $prompt <Leave> ""
	      $prompt configure -background $green -activebackground $green -disabledforeground black
         if { $m_isRunning } { 
            $prompt configure -text "Next->"
         } else {
            $prompt configure -text "Begin->"
         }
         continue
      }


      #configure the normal text
      $prompt configure -text "" -background #c0c0ff -foreground black \
         -activebackground #c0c0ff -disabledforeground gray50 

      if { $m_isRunning } { 
         if { $m_condensed } {
            bind $itk_component(actionPrompt$a_index) <Enter> "" 
		      bind $itk_component(actionPrompt$a_index) <Leave> ""
            $prompt configure -command "" 
         } else {
            bind $itk_component(actionPrompt$a_index) <Enter> [list $itk_component(actionPrompt$a_index) configure -text "Do Next->"]
		      bind $itk_component(actionPrompt$a_index) <Leave> [list $this configureActionPromptList]
            $prompt configure -command [list $this handleNextActionClick $a_index] 
         }
      } else {

         if { $m_currentCrystalName == "" } {
            if {$a_index != 0} {
               bind $itk_component(actionPrompt$a_index) <Enter> "" 
		         bind $itk_component(actionPrompt$a_index) <Leave> "" 
               continue
            }
         } 

         if { $a_name != "Stop" } {
            bind $itk_component(actionPrompt$a_index) <Enter> [list $prompt configure -text "Start Here->"]
		      bind $itk_component(actionPrompt$a_index) <Leave> [list $this configureActionPromptList]
            $prompt configure -command [list $this handleNextActionClick $a_index] 
         } else {
            bind $itk_component(actionPrompt$a_index) <Enter> "" 
		      bind $itk_component(actionPrompt$a_index) <Leave> "" 
         } 
      }
	}
}

::itcl::body ScreeningActionList::configureActionTextList { } {
}

::itcl::body ScreeningActionList::handleCellClick { index_ } {
	setCellColor $index_
    if {$itk_option(-selectActionCommand) != "" } {
        eval $itk_option(-selectActionCommand) $index_
    }
}

::itcl::body ScreeningActionList::handleNextActionClick { index_ } {
	$itk_component(actionCheck$index_) setValue 1
	handleCellClick $index_

   if { $m_condensed} {
      set actionDef [lindex $S_ACTION_STRUCTURE $index_]   
      foreach {a_index a_name a_configurable a_viewableCondensed a_condensedMandatory  a_condensedSelectIndex a_condensedCurrent } $actionDef break
	   sendNextActionToServer $a_condensedSelectIndex
   } else {
	   sendNextActionToServer $index_
   }

	#sendCheckBoxStatesToServer
   #handleCheckboxClick $index_
}

::itcl::body ScreeningActionList::handleCheckboxClick { index_ } {

   if {$m_condensed} {
      
      foreach actionDef $S_ACTION_STRUCTURE {
         foreach {a_index a_name a_configurable a_viewableCondensed a_condensedMandatory  a_condensedSelectIndex a_condensedCurrent } $actionDef break
         if {$a_condensedMandatory} {
   	      $itk_component(actionCheck$a_index) setValue 1
         }
      }

      #force the stop off
   	$itk_component(actionCheck8) setValue 0
      #force the excitation off
   	$itk_component(actionCheck12) setValue 0 
      #force the re_orient off
   	$itk_component(actionCheck13) setValue 0 
      #force the queue task off
   	$itk_component(actionCheck14) setValue 0 

      set state [$itk_component(actionCheck$index_) get]
      set actionDef [lindex $S_ACTION_STRUCTURE $index_]   
      foreach {a_index a_name a_configurable a_viewableCondensed a_condensedMandatory  a_condensedSelectIndex a_condensedCurrent } $actionDef break
      foreach actionIndex $a_condensedCurrent {
   	   $itk_component(actionCheck$actionIndex) setValue $state
      }
   }

	sendCheckBoxStatesToServer
}


::itcl::body ScreeningActionList::sendNextActionToServer { index_ } {
    if {[$itk_option(-controlSystem) cget -clientState] != "active"} {
        return
    }

    global gEncryptSID
    if {$gEncryptSID} {
        set SID SID
    } else {
        set SID PRIVATE[$itk_option(-controlSystem) getSessionId]
    }
	set _operationId [eval $m_sequenceOperation startOperation setConfig nextAction $index_ $SID]
}

::itcl::body ScreeningActionList::sendCheckBoxStatesToServer {} {
    if {[$itk_option(-controlSystem) cget -clientState] != "active"} {
        return
    }

    global gEncryptSID
    if {$gEncryptSID} {
        set SID SID
    } else {
        set SID PRIVATE[$itk_option(-controlSystem) getSessionId]
    }
	set actionListStates {}
	
	foreach actionDef $S_ACTION_STRUCTURE {
      foreach {a_index a_name a_configurable a_viewableCondensed a_condensedMandatory  a_condensedSelectIndex a_condensedCurrent } $actionDef break
		lappend actionListStates [$itk_component(actionCheck$a_index) get]
	}
	
    if {$m_condensed} {
	   set _operationId [eval $m_sequenceOperation startOperation setConfig simpleActionListStates [list $actionListStates] $SID]
    } else {
	   set _operationId [eval $m_sequenceOperation startOperation setConfig actionListStates [list $actionListStates] $SID]
    }
}

#this is the handler for the string change
::itcl::body ScreeningActionList::handleActionListChange { stringName_ targetReady_ alias_ actionList_ - } {

	if { ! $targetReady_} return
	if {$actionList_ == ""} return

	set m_isRunning [lindex $actionList_ 0]
	set m_currentAction [lindex $actionList_ 1]
	set m_nextAction [lindex $actionList_ 2]
	set _actionList [lindex $actionList_ 3]

   configureActionPromptList 
   configureActionTextList 

	setAllSelectionStates $_actionList
}


#this is the handler for the string change
::itcl::body ScreeningActionList::handleCrystalStatusChange { stringName_ targetReady_ alias_ crystalStatus_ - } {

	if { ! $targetReady_} return
	if {$crystalStatus_ == ""} return

	set m_currentCrystalName [lindex $crystalStatus_ 0]
	set m_nextCrystalName [lindex $crystalStatus_ 1]

   configureActionPromptList 
}



::itcl::body ScreeningActionList::setAllSelectionStates { actionList_ } {	
	set i 0
	foreach selectState $actionList_ {
		$itk_component(actionCheck$i) setValue $selectState

      set actionDef [lindex $S_ACTION_STRUCTURE $i]
      foreach {a_index a_name a_configurable a_viewableCondensed a_condensedMandatory a_condensedSelectIndex a_condensedCurrent } $actionDef break
      if {$a_condensedMandatory} {
		   $itk_component(actionCheck$i) configure -selectcolor darkgreen 
      } else {
		   $itk_component(actionCheck$i) configure -selectcolor yellow
      }
		incr i
	}

   #turn mismatched sub-states to red.
   if {! $m_condensed } return
	foreach actionDef $S_ACTION_STRUCTURE {
      foreach {a_index a_name a_configurable a_viewableCondensed a_condensedMandatory  a_condensedSelectIndex a_condensedCurrent } $actionDef break
      if {! $a_viewableCondensed} continue 

		set state [$itk_component(actionCheck$a_index) get]
      foreach actionIndex $a_condensedCurrent {
   	   if {$state != [$itk_component(actionCheck$actionIndex) get] } {
		      $itk_component(actionCheck$a_index) setValue 1 
		      $itk_component(actionCheck$a_index) configure -selectcolor red 
         }
      }
	}
}

::itcl::class ScreeningParameters {
	inherit ::itk::Widget DCS::Component
	
	itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -enableWashBeforeMount enableWashBeforeMount EnableWashBeforeMount 1 {
        if {!$itk_option(-enableWashBeforeMount)} {
            grid forget $itk_component(wash0)
        } else {
	        grid $itk_component(wash0) -row 0 -column 0
        }
    }
	
	private variable blue #a0a0c0

	private method createParameterTabFrame
	public method selectNewAction

	private variable _lastParameterFrameIndex 0
   public method setCondensed { condensed_ } {
      set m_condensed $condensed_
   }

   private variable m_condensed 0

    private common gCheckButtonVar

	private method getActionListParameters
	public method sendActionListParametersToServer
   public method getParamFrameHeight
   
	private method setActionListParameters 
	public method handleScreeningParametersChange

	private method getMountNextCrystalParameters
	private method getLoopAlignmentParameters
	private method getPauseParameters
	private method getVideoSnapshotParameters
	private method getRotateParameters
	private method getGrabberWarmCycleParameters
	private method getCollectImageParameters
	private method getExcitationScanParameters
	private method getReOrientParameters
	private method getRunQueueTaskParameters

	private method setMountNextCrystalParameters
	private method setVideoSnapshotParameters
	private method setRotateParameters
	private method setGrabberWarmCycleParameters
	private method setCollectImageParameters
	private method setExcitationScanParameters
   public method setGlobalCollectionParameters 

    public method handleLeaveParameters

	private method createMountNextParameters
	private method createVideoSnapshotParameters
	private method createCollectImageParameters
	private method createRotateParameters
	private method createFluorescenceScanParameters
   private method createExcitationParameters 
	private method createGrabberWarmCycleParameters

	private variable m_sequenceOperation ""

	private variable m_actionNames {
		{MountNextCrystal}
		{LoopAlignment}
		{Stop}
		{VideoSnapshot}
		{CollectImage}
		{Rotate}
		{VideoSnapshot}
		{CollectImage}
		{Stop}
		{Rotate}
		{VideoSnapshot}
		{CollectImage}
		{ExcitationScan}
        {ReQueue}
        {RunQueueTask}
		{Stop}
		{GrabberWarmCycle}
	}



   private variable m_deviceFactory
   private variable m_ring

	# contructor / destructor
	constructor { args } {}
	public method destructor
}


::itcl::body ScreeningParameters::constructor { args } {
   set m_deviceFactory [DCS::DeviceFactory::getObject]

   set m_ring $itk_interior

	createParameterTabFrame $m_actionNames

	grid configure $itk_component(paramTop) -row 0 -column 0

	selectNewAction 0

	eval itk_initialize $args

	set m_sequenceOperation [$m_deviceFactory getObjectName sequenceSetConfig]

	$itk_component(delta4) addInput "::$itk_option(-controlSystem) clientState active {Must be 'Active' to configure screening parameters}"



	::mediator register $this ::device::screeningParameters contents handleScreeningParametersChange
	::mediator announceExistence $this
	

}

::itcl::body ScreeningParameters::getParamFrameHeight { index_ } {
    foreach {- - - h} [grid bbox $itk_component(parameterFrame$index_) ] {break}

    incr h 10

    if {$m_condensed && ($index_ == 7 || $index_ == 11)} {
        set angle_index [expr $index_ - 2]
        foreach {- - - ah} [grid bbox $itk_component(parameterFrame$angle_index) ] {break}

        set h [expr $h + $ah]
    }
    return $h
}

::itcl::body ScreeningParameters::createParameterTabFrame { actions_ } {

	set tabWidth 25

	itk_component add paramTop {
		frame $m_ring.pt -borderwidth 1 -relief groove -background $blue
	} {
	}
    bind $itk_component(paramTop) <Leave> [list $this handleLeaveParameters]

	# for each action create a tab-frame for the parameter caption and the parameter entries
	set i 0
	foreach action $actions_ {
		#create the tab-frame
        #puts "parameterFrame$i"
		itk_component add parameterFrame$i {
			frame $itk_component(paramTop).parameterTab$i -bd 4 -background $blue
		} {
		}
      incr i
   }


	set i 0
	foreach action $actions_ {
		# add parameter controls for this action
		switch -exact -- $action {
			MountNextCrystal {createMountNextParameters $i }
			LoopAlignment {}
			Rotate {createRotateParameters $i}
			VideoSnapshot { createVideoSnapshotParameters $i }
			CollectImage {  createCollectImageParameters $i  }
			ExcitationScan {createExcitationParameters $i}
			Pause {}
			GrabberWarmCycle {createGrabberWarmCycleParameters $i}
		}
		
		incr i
	}
}

body ScreeningParameters::destructor {} {
}

::itcl::body ScreeningParameters::selectNewAction { index_ } {

    #unpack existing
    set all [pack slaves $itk_component(paramTop)]
    if {$all != ""} {
        eval pack forget $all
    }

    #pack the frame for that action
    switch -exact -- $index_ {
        7 -
        11 {
            if {$m_condensed} {
                set angle_index [expr $index_ - 2]
                pack $itk_component(parameterFrame$angle_index) -side top
            }
            pack $itk_component(parameterFrame$index_) -side top
        }
        default {
            pack $itk_component(parameterFrame$index_) -side top
        }
    }

	set _lastParameterFrameIndex $index_
}




# gtos_start_operation sequenceSetConfig 185.6 setConfig actionListParameters {{MountNextCrystal {}} {LoopAlignment {}} {Pause {}} {VideoSnapshot {1.0 0deg}} {CollectImage {0.25 30.0 1 {}}} {Rotate 90} {VideoSnapshot {0.3 90deg}} {CollectImage {0.25 30.0 1 {}}} {Pause {}} {Rotate -45} {VideoSnapshot {1.0 45deg}} {CollectImage {0.25 30.0 1 {}}} {Pause {}}}

::itcl::body ScreeningParameters::getMountNextCrystalParameters { index_ } {
    if {$itk_option(-enableWashBeforeMount)} {
        set num_cycle_to_wash [$itk_component(wash$index_) get]
	    return "MountNextCrystal [list $num_cycle_to_wash]"
    } else {
	    return "MountNextCrystal {}"
    }
}
::itcl::body ScreeningParameters::setMountNextCrystalParameters { index_ value_ } {
    set num_cycle [lindex $value_ 0]
    $itk_component(wash$index_) setValue $num_cycle 1
}

::itcl::body ScreeningParameters::getLoopAlignmentParameters {} {
	return "LoopAlignment {}"
}

::itcl::body ScreeningParameters::getPauseParameters {} {
	return "Pause {}"
}

::itcl::body ScreeningParameters::getRotateParameters { index_ } {
	set angle [$itk_component(angle$index_) get]
	return "Rotate [list $angle]"
}

::itcl::body ScreeningParameters::setRotateParameters { index_ value_ } {
	set angle [lindex $value_ 0]
	$itk_component(angle$index_) setValue $angle 1
}

::itcl::body ScreeningParameters::getGrabberWarmCycleParameters { index_ } {
        set wcycle [$itk_component(warming$index_) get]
        return "GrabberWarmCycle [list $wcycle]"
}

::itcl::body ScreeningParameters::setGrabberWarmCycleParameters { index_ value_ } {
        set wcycle [lindex $value_ 0]
        $itk_component(warming$index_) setValue $wcycle 1
}

::itcl::body ScreeningParameters::getVideoSnapshotParameters { index_ } {
	set zoomValue [$itk_component(zoom$index_) get]
	set nameTag [$itk_component(nameTag$index_) get]
	
	return [list VideoSnapshot [list $zoomValue $nameTag]]
}

::itcl::body ScreeningParameters::setVideoSnapshotParameters { index_ value_ } {
	set zoomValue [lindex $value_ 0]
	set nameTag [lindex $value_ 1]
	
	$itk_component(zoom$index_) setValue $zoomValue 1
	$itk_component(nameTag$index_) setValue $nameTag 1
}


::itcl::body ScreeningParameters::getCollectImageParameters { index_ } {
	set delta [$itk_component(delta$index_) get]
	set time [$itk_component(time$index_) get]
	set num [$itk_component(numImages$index_) get] 
	set nameTag [$itk_component(nameTag$index_) get]
	
	return "[list CollectImage [list $delta $time $num $nameTag]]"
}

::itcl::body ScreeningParameters::setCollectImageParameters { index_ value_ } {
	set delta [lindex $value_ 0]
	set time [lindex $value_ 1]
	set num [lindex $value_ 2]
	set nameTag [lindex $value_ 3]

	$itk_component(delta$index_) setValue $delta 1
	$itk_component(time$index_) setValue $time 1
	$itk_component(numImages$index_) setValue $num 1
	$itk_component(nameTag$index_) setValue $nameTag 1
}

::itcl::body ScreeningParameters::getExcitationScanParameters { index_ } {
	set time [$itk_component(time$index_) get]
	set nameTag [$itk_component(nameTag$index_) get]
	
	return "[list ExcitationScan [list $time $nameTag]]"
}

::itcl::body ScreeningParameters::setExcitationScanParameters { index_ value_ } {
	set time [lindex $value_ 0]
	set nameTag [lindex $value_ 1]
	$itk_component(time$index_) setValue $time 1
	$itk_component(nameTag$index_) setValue $nameTag 1
}

::itcl::body ScreeningParameters::getReOrientParameters {} {
	return "ReOrient {}"
}

::itcl::body ScreeningParameters::getRunQueueTaskParameters {} {
	return "RunQueueTask {}"
}

::itcl::body ScreeningParameters::createMountNextParameters {index_ } {
	itk_component add wash$index_ {
		DCS::Entry $itk_component(parameterFrame$index_).num_cycle \
			 -entryWidth 3 \
			 -promptWidth 12 \
			 -background #a0a0c0  -disabledbackground #a0a0c0 \
             -systemIdleOnly 0 \
			 -promptText "#Wash Cycle:" -entryType int -activeClientOnly 1
	} {
		keep -font
	}
	
	$itk_component(wash$index_) configure -onSubmit "$this sendActionListParametersToServer"

	grid $itk_component(wash$index_) -row 0 -column 0
}

::itcl::body ScreeningParameters::createVideoSnapshotParameters { index_ } {

	itk_component add zoom$index_ {
		DCS::Entry $itk_component(parameterFrame$index_).zoom  \
			 -entryWidth 10  -disabledbackground #a0a0c0 \
			 -promptText "Zoom" -promptWidth 12 \
			 -background #a0a0c0 \
             -systemIdleOnly 0 \
			 -entryType positiveFloat -activeClientOnly 1
	} {
		keep -font
	}
	
	itk_component add nameTag$index_ {
		DCS::Entry $itk_component(parameterFrame$index_).nameTag \
			 -entryWidth 10 -disabledbackground #a0a0c0 \
			 -promptText "Name Tag"  -promptWidth 12 \
			 -background #a0a0c0 \
             -systemIdleOnly 0 \
			 -entryType string  -activeClientOnly 1
	} {
		keep -font
	}

	$itk_component(zoom$index_) configure -onSubmit "$this sendActionListParametersToServer"
	$itk_component(nameTag$index_) configure -onSubmit "$this sendActionListParametersToServer"
	
	grid $itk_component(zoom$index_) -row 0 -column 0
	grid $itk_component(nameTag$index_) -row 1 -column 0
}


::itcl::body ScreeningParameters::createCollectImageParameters {index_} {
    itk_component add sync$index_ {
        checkbutton $itk_component(parameterFrame$index_).sync \
        -text "sync all collect" \
        -anchor w \
        -background #a0a0c0 \
        -variable [list [scope gCheckButtonVar($this,sync)]]
    } {
    }
    set gCheckButtonVar($this,sync) 1

	itk_component add delta$index_ {
		DCS::Entry $itk_component(parameterFrame$index_).delta \
			 -entryWidth 10  -disabledbackground #a0a0c0 \
			 -promptText "Delta: " -promptWidth 12 \
			 -background #a0a0c0 \
             -systemIdleOnly 0 \
			 -entryType positiveFloat -activeClientOnly 1
	} {
		keep -font
	}
	
	itk_component add time$index_ {
		DCS::Entry $itk_component(parameterFrame$index_).time \
			 -entryWidth 10 \
			 -promptText "Time:"  -promptWidth 12 \
			 -background #a0a0c0  -disabledbackground #a0a0c0 \
             -systemIdleOnly 0 \
			 -entryType positiveFloat -activeClientOnly 1
	} {
		keep -font
	}

	itk_component add numImages$index_ {
		DCS::Entry $itk_component(parameterFrame$index_).numImages \
			 -entryWidth 10 \
			 -promptWidth 12 \
			 -background #a0a0c0  -disabledbackground #a0a0c0 \
             -systemIdleOnly 0 \
			 -promptText "# of Images" -entryType int  -activeClientOnly 1
	} {
		keep -font
	}

	itk_component add nameTag$index_ {
		DCS::Entry $itk_component(parameterFrame$index_).nameTag \
			 -entryWidth 10 \
			 -promptText "Name Tag"  -promptWidth 12 \
			 -background #a0a0c0  -disabledbackground #a0a0c0 \
             -systemIdleOnly 0 \
			 -entryType string -activeClientOnly 1
	} {
		keep -font
	}

	$itk_component(delta$index_) configure -onSubmit [list $this setGlobalCollectionParameters $index_]
	$itk_component(time$index_) configure -onSubmit [list $this setGlobalCollectionParameters $index_]
	$itk_component(numImages$index_) configure -onSubmit [list $this setGlobalCollectionParameters $index_]
	$itk_component(nameTag$index_) configure -onSubmit [list $this setGlobalCollectionParameters $index_]

	grid $itk_component(delta$index_) -row 1 -column 0
	grid $itk_component(time$index_) -row 2 -column 0
	grid $itk_component(numImages$index_) -row 3 -column 0
	#grid $itk_component(nameTag$index_) -row 4 -column 0
	#grid $itk_component(sync$index_) -row 4 -column 0 -sticky w
	
	return
}


::itcl::body ScreeningParameters::createRotateParameters {index_ } {
	itk_component add angle$index_ {
		DCS::Entry $itk_component(parameterFrame$index_).angle \
			 -entryWidth 10 \
			 -promptWidth 12 \
			 -background #a0a0c0  -disabledbackground #a0a0c0 \
             -systemIdleOnly 0 \
			 -promptText "Rotate by: " -entryType float -activeClientOnly 1
	} {
		keep -font
	}
	
	$itk_component(angle$index_) configure -onSubmit "$this sendActionListParametersToServer"

	grid $itk_component(angle$index_) -row 0 -column 0
}

::itcl::body ScreeningParameters::createGrabberWarmCycleParameters {index_ } {
        itk_component add warming$index_ {
                DCS::Entry $itk_component(parameterFrame$index_).warming \
                         -entryWidth 4 \
                         -promptWidth 18 \
                         -background #a0a0c0  -disabledbackground #a0a0c0 \
                         -systemIdleOnly 0 \
                         -promptText "Warm Cycle(M/DM): " -entryType int -activeClientOnly 1
        } {
                keep -font
        }

        $itk_component(warming$index_) configure -onSubmit "$this sendActionListParametersToServer"

        grid $itk_component(warming$index_) -row 0 -column 0
}

::itcl::body ScreeningParameters::createExcitationParameters {index_ } {
	itk_component add time$index_ {
		DCS::Entry $itk_component(parameterFrame$index_).time$index_ \
			 -entryWidth 10 \
			 -promptWidth 12 \
			 -background #a0a0c0  -disabledbackground #a0a0c0 \
             -systemIdleOnly 0 \
			 -promptText "Time: " -entryType float -activeClientOnly 1
	} {
		keep -font
	}

	itk_component add nameTag$index_ {
		DCS::Entry $itk_component(parameterFrame$index_).nameTag \
			 -entryWidth 10 \
			 -promptText "Name Tag"  -promptWidth 12 \
			 -background #a0a0c0  -disabledbackground #a0a0c0 \
             -systemIdleOnly 0 \
			 -entryType string -activeClientOnly 1
	} {
		keep -font
	}	

	$itk_component(time$index_) configure -onSubmit "$this sendActionListParametersToServer"
	$itk_component(nameTag$index_) configure -onSubmit "$this sendActionListParametersToServer"

	grid $itk_component(time$index_) -row 0 -column 0
	grid $itk_component(nameTag$index_) -row 1 -column 0
}

::itcl::body ScreeningParameters::createFluorescenceScanParameters {index_ } {
}


::itcl::body ScreeningParameters::getActionListParameters {} {
	set data "[list [getMountNextCrystalParameters 0] [getLoopAlignmentParameters] [getPauseParameters] [getVideoSnapshotParameters 3] [getCollectImageParameters 4] [getRotateParameters 5] [getVideoSnapshotParameters 6] [getCollectImageParameters 7] [getPauseParameters] [getRotateParameters 9] [getVideoSnapshotParameters 10] [getCollectImageParameters 11] [getExcitationScanParameters 12] [getReOrientParameters] [getRunQueueTaskParameters] [getPauseParameters] [getGrabberWarmCycleParameters 16]]"
	
	return $data
}

::itcl::body ScreeningParameters::handleLeaveParameters { } {
    place forget $itk_interior

    if {!$gCheckButtonVar($this,sync)} {
        return
    }

    switch -exact -- $_lastParameterFrameIndex {
        4 -
        7 -
        11 {
            setGlobalCollectionParameters $_lastParameterFrameIndex
        }
    }
}
::itcl::body ScreeningParameters::setGlobalCollectionParameters {index_ } {
	set delta [$itk_component(delta$index_) get]
	set time  [$itk_component(time$index_) get]
	set num [$itk_component(numImages$index_) get]
	set nameTag [$itk_component(nameTag$index_) get]

   set i 0
	foreach actionDefinition $m_actionNames {
		set action [lindex $actionDefinition 0]
      if {$action == "CollectImage"} {
         setCollectImageParameters $i [list $delta $time $num $nameTag]
      }
      incr i
   }
   sendActionListParametersToServer
}

::itcl::body ScreeningParameters::sendActionListParametersToServer { } {

	set parameters [getActionListParameters]
    #puts $parameters

    if {[$itk_option(-controlSystem) cget -clientState] == "active"} {
        global gEncryptSID
        if {$gEncryptSID} {
            set SID SID
        } else {
            set SID PRIVATE[$itk_option(-controlSystem) getSessionId]
        }
	    set _operationId [eval $m_sequenceOperation startOperation setConfig actionListParameters [list $parameters] $SID]
    #} else {
    #    puts "not active, ignore send parameter"
    }
	
}


::itcl::body ScreeningParameters::setActionListParameters { data_ } {

	set actions [lindex $data_ 0]
	set detectorModeIndex [lindex $data_ 1]
	set directory [lindex $data_ 2]

	set i 0
	foreach actionDefinition $actions {
		
		set action [lindex $actionDefinition 0]
		set parameters [lindex $actionDefinition 1]
		
		# add parameter controls for this action
		switch -exact -- $action {
			MountNextCrystal {setMountNextCrystalParameters $i $parameters }
			LoopAlignment {}
			Rotate {setRotateParameters $i $parameters}
			VideoSnapshot { setVideoSnapshotParameters $i $parameters }
			CollectImage { setCollectImageParameters $i $parameters }
			ExcitationScan { setExcitationScanParameters $i $parameters }
			Pause {}
			GrabberWarmCycle {setGrabberWarmCycleParameters $i $parameters}
		}
		
		incr i
	}
}

#this is the handler for the string change
::itcl::body ScreeningParameters::handleScreeningParametersChange {  stringName_ targetReady_ alias_ parameters_ - } {
	
	if { ! $targetReady_} return
	
	if {$parameters_ == ""} return
	
	setActionListParameters $parameters_

}


::itcl::class ScreeningGlobalParameters {
	inherit ::itk::Widget DCS::Component

	itk_option define -controlSystem controlSystem ControlSystem "::dcss"

   public method setActionListParameters 

	public method handleDirectorySubmitChange
	public method handleDefault
	public method handleDistanceUpdate
	public method handleScreeningParametersChange

    public method sendDetectorModeChange { mode } {
        if {[$itk_option(-controlSystem) cget -clientState] != "active"} {
            return
        }

        global gEncryptSID
        if {$gEncryptSID} {
            set SID SID
        } else {
            set SID PRIVATE[$itk_option(-controlSystem) getSessionId]
        }
	    $m_sequenceOperation startOperation setConfig detectorMode $mode $SID
    }

    public method sendDistanceChange { distance } {
        if {[$itk_option(-controlSystem) cget -clientState] != "active"} {
            return
        }

        global gEncryptSID
        if {$gEncryptSID} {
            set SID SID
        } else {
            set SID PRIVATE[$itk_option(-controlSystem) getSessionId]
        }
	    $m_sequenceOperation startOperation setConfig distance $distance $SID
    }
    public method sendBeamStopChange { distance } {
        if {[$itk_option(-controlSystem) cget -clientState] != "active"} {
            return
        }

        global gEncryptSID
        if {$gEncryptSID} {
            set SID SID
        } else {
            set SID PRIVATE[$itk_option(-controlSystem) getSessionId]
        }
	    $m_sequenceOperation startOperation setConfig beamstop $distance $SID
    }
    public method sendAttenuationChange { distance } {
        if {[$itk_option(-controlSystem) cget -clientState] != "active"} {
            return
        }

        global gEncryptSID
        if {$gEncryptSID} {
            set SID SID
        } else {
            set SID PRIVATE[$itk_option(-controlSystem) getSessionId]
        }
	    $m_sequenceOperation startOperation setConfig attenuation $distance $SID
    }

	private variable m_sequenceOperation ""
	private variable m_defaultDataHome "/data"
	private variable m_deviceFactory

	constructor { args } {}
}

::itcl::body ScreeningGlobalParameters::constructor { args } {
    global gMotorDistance
    global gMotorBeamStop


   set m_deviceFactory [DCS::DeviceFactory::getObject]

    set defaultDataHome [::config getDefaultDataHome]
    #puts "default data home from config: {$defaultDataHome}"
    if {$defaultDataHome != ""} {
        set m_defaultDataHome $defaultDataHome
    }

	set f $itk_interior

	itk_component add directory {
		DCS::DirectoryEntry $f.labelDirectory \
        -promptText "Directory:" \
        -leaveSubmit 1 \
        -entryType rootDirectory \
        -entryJustify left \
	    -entryWidth 30 \
        -promptWidth 10 \
        -activeClientOnly 1 \
        -entryMaxLength 128 \
        -systemIdleOnly 0
	} {
		keep -font
	}
	::device::screeningActionList createAttributeFromField screeningActive 0

	$itk_component(directory) addInput "::device::screeningActionList screeningActive 0 {Screening in progress.}"

    itk_component add def {
        DCS::Button $f.update_dir -text "Default" -command "$this handleDefault"
    } {
    }
	$itk_component(def) addInput "::device::screeningActionList screeningActive 0 {Screening in progress.}"

	# make the detector mode entry
	itk_component add detectorMode {
		DCS::DetectorModeMenu $itk_interior.dm -entryWidth 17 \
			 -promptText "Detector: " \
			 -promptWidth 10 \
			 -showEntry 0 \
			 -entryType string \
			 -entryJustify center \
			 -promptText "Detector: " \
			 -shadowReference 0 \
             -systemIdleOnly 0 \
			 -activeClientOnly 1
	} {
		keep -font
	}

    itk_component add distance {
        DCS::Entry $itk_interior.distance \
        -leaveSubmit 1 \
        -promptText "Distance: " \
        -promptWidth 11 \
        -entryWidth 8 \
        -units "mm" \
        -unitsList "mm" \
        -entryType positiveFloat \
        -entryJustify right \
        -escapeToDefault 0\
        -shadowReference 0 \
        -activeClientOnly 1 \
        -systemIdleOnly 0 \
        -reference "::device::$gMotorDistance scaledPosition" \
        -onSubmit "$this sendDistanceChange %s" \
        -autoConversion 1
    } {
    }
    itk_component add beamstop {
        DCS::Entry $itk_interior.beamstop \
        -leaveSubmit 1 \
        -promptText "Beamstop: " \
        -promptWidth 11 \
        -entryWidth 8 \
        -units "mm" \
        -unitsList "mm" \
        -entryType positiveFloat \
        -entryJustify right \
        -escapeToDefault 0\
        -shadowReference 0 \
        -activeClientOnly 1 \
        -systemIdleOnly 0 \
        -reference "::device::$gMotorBeamStop scaledPosition" \
        -onSubmit "$this sendBeamStopChange %s" \
        -autoConversion 1
    } {
    }
    itk_component add attenuation {
        DCS::Entry $itk_interior.attenuation \
        -leaveSubmit 1 \
        -promptText "Attenuation: " \
        -promptWidth 11 \
        -entryWidth 8 \
        -units "%" \
        -unitsList "%" \
        -entryType positiveFloat \
        -entryJustify right \
        -escapeToDefault 0\
        -shadowReference 0 \
        -activeClientOnly 1 \
        -systemIdleOnly 0 \
        -reference "::device::attenuation scaledPosition" \
        -onSubmit "$this sendAttenuationChange %s" \
        -autoConversion 1
    } {
    }
    itk_component add update {
        DCS::Button $f.update_dis -text "Update" -command "$this handleDistanceUpdate"
    } {
    }
	$itk_component(update) addInput "::device::screeningActionList screeningActive 0 {Screening in progress.}"

	$itk_component(distance) addInput "::device::screeningActionList screeningActive 0 {Screening in progress.}"
	$itk_component(beamstop) addInput "::device::screeningActionList screeningActive 0 {Screening in progress.}"
	$itk_component(attenuation) addInput "::device::screeningActionList screeningActive 0 {Screening in progress.}"

	# dose mode
	itk_component add doseControl {
        DCS::DoseControlView $f.doseControl
	} {}

	grid columnconfigure $itk_interior 0 -weight 0
	grid columnconfigure $itk_interior 1 -weight 0 
	grid columnconfigure $itk_interior 2 -weight 1 


	grid $itk_component(directory)  -sticky w -column 0 -row 0 -columnspan 3
	grid $itk_component(def) -column 2 -row 0

	grid $itk_component(detectorMode) \
    -pady 2 -stick w -column 0 -row 1 -columnspan 3
	grid $itk_component(distance) -pady 2 -stick ws -column 1 -row 2
	grid $itk_component(update) -pady 2 -stick ws -column 2 -row 2
	grid $itk_component(beamstop) -pady 2 -stick wn -column 1 -row 3
	grid $itk_component(attenuation) -pady 2 -stick wn -column 1 -row 4

	grid configure $itk_component(doseControl) -stick w -column 0 -row 2 -rowspan 3

	eval itk_initialize $args

	set m_sequenceOperation [$m_deviceFactory getObjectName sequenceSetConfig]

	$itk_component(detectorMode) configure -onSubmit "$this sendDetectorModeChange %s"
	$itk_component(detectorMode) setValueByIndex 0 1

	::mediator register $this ::device::screeningParameters contents handleScreeningParametersChange
	::mediator announceExistence $this
	
	$itk_component(directory) configure -onSubmit "$this handleDirectorySubmitChange"

}

#this is the handler for the string change
::itcl::body ScreeningGlobalParameters::handleScreeningParametersChange {  stringName_ targetReady_ alias_ parameters_ - } {
	
	if { ! $targetReady_} return
	
	if {$parameters_ == ""} return

	set actions [lindex $parameters_ 0]
	set detectorModeIndex [lindex $parameters_ 1]
	set directory [lindex $parameters_ 2]
	$itk_component(detectorMode) setValueByIndex $detectorModeIndex 1
	$itk_component(directory) setValue $directory 1

    if {[llength $parameters_] >= 5} {
	    grid $itk_component(distance) \
        -pady 2 -stick ws -column 1 -row 2
	    grid $itk_component(update) \
        -pady 2 -stick ws -column 2 -row 2
	    grid $itk_component(beamstop) \
        -pady 2 -stick wn -column 1 -row 3

        set distance [lindex $parameters_ 3]
        set beamstop [lindex $parameters_ 4]
        set att      [lindex $parameters_ 5]
        $itk_component(distance) setValue $distance 1
        $itk_component(beamstop) setValue $beamstop 1
        $itk_component(attenuation) setValue $att 1
    } else {
	    grid forget $itk_component(distance) \
	    $itk_component(update) \
	    $itk_component(beamstop) \
        $itk_component(attenuation)
    }

	

}


::itcl::body ScreeningGlobalParameters::handleDirectorySubmitChange {} {
    if {[$itk_option(-controlSystem) cget -clientState] != "active"} {
        return
    }

	set directory [$itk_component(directory) get]
    global gEncryptSID
    if {$gEncryptSID} {
        set SID SID
    } else {
        set SID PRIVATE[$itk_option(-controlSystem) getSessionId]
    }
	$m_sequenceOperation startOperation setConfig directory $directory $SID
}

::itcl::body ScreeningGlobalParameters::handleDefault {} {
    set username [$itk_option(-controlSystem) getUser]
    set beamlineName [::config getConfigRootName]

    ###rollback to /data/user
    #set date [clock format [clock seconds] -format "%Y%m%d"]
	#set new_directory \
    #[file join $m_defaultDataHome $username SSRL $beamlineName $date]
    if {[string first $username $m_defaultDataHome] < 0} {
	    set new_directory [file join $m_defaultDataHome $username]
    } else {
	    set new_directory $m_defaultDataHome
    }
    
    $itk_component(directory) setValue $new_directory

    set objCollectDefault [$m_deviceFactory getObjectName collect_default]
    if {[catch {
        set strCollectDefault [$objCollectDefault getContents]
    } errMsg]} {
        return
    }
    if {[llength $strCollectDefault] > 2} {
        set defAtt [lindex $strCollectDefault 2]
        $itk_component(attenuation) setValue $defAtt
    }
}
::itcl::body ScreeningGlobalParameters::handleDistanceUpdate {} {
    global gMotorDistance
    global gMotorBeamStop

    set distance [lindex [::device::$gMotorDistance getScaledPosition] 0]
    $itk_component(distance) setValue $distance

    set beamstop [lindex [::device::$gMotorBeamStop getScaledPosition] 0]
    $itk_component(beamstop) setValue $beamstop

    set value [lindex [::device::attenuation getScaledPosition] 0]
    $itk_component(attenuation) setValue $value
}



