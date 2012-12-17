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

package provide BLUICECollectView 1.0

# load standard packages
package require Iwidgets
package require BWidget

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent
package require DCSDeviceFactory

package require DCSDeviceView
package require DCSProtocol
package require DCSOperationManager
package require DCSHardwareManager
package require DCSPrompt
package require DCSMotorControlPanel
package require DCSCheckbutton
package require DCSCheckbox
package require DCSAttribute
package require BLUICEDoseMode
package require BLUICERunSequenceView
package require DCSStrategyStatus
package require BLUICESimpleRobot
package require BLUICESamplePosition
package require BLUICECollimatorCheckbutton

class DCS::RunOnlineCalculator {
    inherit ::itk::Widget DCS::Component

    #options
    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -runDefinition runDefinition RunDefinition "" {
        if {$itk_option(-runDefinition) == ""} {
            $itk_component(update) configure \
            -state disabled
        } else {
            $itk_component(update) configure \
            -state normal
        }
    }
    itk_option define -runInfo runInfo RunInfo {1.0 0 1.0} {
        recalculate
    }

    ## overrided by default parameters
    private variable m_minT 1.0
    private variable m_defT 2.0
    private variable m_maxT 600.0
    private variable m_minA 0.0
    private variable m_defA 0.0
    private variable m_maxA 99.8

	private variable blue  #a0a0c0

    ### will be overrided by config file
    private variable m_targetTime 0.2
    
    private method getLimits { } {
        if {[$m_deviceFactory stringExists collect_default]} {
            set obj [$m_deviceFactory getObjectName collect_default]
            set defContents [$obj getContents]
            if {[llength $defContents] >= 7} {
                foreach {defD m_defT m_defA m_minT m_maxT m_minA m_maxA} \
                $defContents break
            }
        }
    }
    private method getTargetTime { } {
        set cfg [::config getStr attenuation_calculator.target_time]
        if {$cfg == "min"} {
            set m_targetTime $m_minT
            return
        } elseif {$cfg == "default"} {
            set m_targetTime $m_defT
            return
        }
        if {[string is double -strict $cfg]} {
            set m_targetTime $cfg
        } else {
            log_warning wrong attenuation_calculator.target_time in config file
        }
        ### check range:
        if {$m_targetTime < $m_minT} {
            log_warning target time adjusted to mininum $m_minT
            set m_targetTime $m_minT
        }
        if {$m_targetTime > $m_maxT} {
            log_warning target time adjusted to maxinum $m_maxT
            set m_targetTime $m_maxT
        }
    }
    public method setDelta { v } {
        $itk_component(desired_delta) setValue $v
    }
    ### 03/12/10:
    ### Mike Soltis wants following logic:
    ### Try to use the target_time and adjust attenuation.
    ### Increase time if attenuation 0.
    public method calculateByDelta { } {
        foreach {curD curA curT} $itk_option(-runInfo) break
        if {$curD <= 0} {
            log_error cannot handle current delta <= 0

            $itk_component(result) configure \
            -text "current delta <= 0" \
            -foreground red

            return
        }

        set desD [lindex [$itk_component(desired_delta) get] 0]
        if {$desD <= 0} {
            log_error cannot handle desired delta <= 0

            $itk_component(result) configure \
            -text "desired delta <= 0" \
            -foreground red

            return
        }
        set warning ""

        getLimits
        getTargetTime
        if {$m_targetTime <= 0} {
            $itk_component(result) configure \
            -text "target time <= 0" \
            -foreground red
            return
        }

        set curEPerAngle [expr (100.0 - $curA) * $curT / $curD]
        puts "cur E per angle: $curEPerAngle"

        set desT $m_targetTime
        set desA [expr 100.0 - $curEPerAngle * $desD / $desT]
        puts "calculateByDelta direct attenuation=$desA"

        if {$desA < 0.0} {
            #### try to increase time
            set desA $m_minA
            if {$desA >= 100.0} {
                $itk_component(result) configure \
                -text "min attenuation = 100%" \
                -foreground red
                return
            }
            set desT [expr $curEPerAngle * $desD / (100.0 - $desA)]
            if {$desT > $m_maxT} {
                set warning "cannot keep the same exposure even with max time and min attenuation"
                log_warning cannot keep the same exposure even with max time and min attenuation
                set desT $m_maxT
            }
        }

        $itk_component(desired_attenuation) setValue $desA 1
        $itk_component(desired_time) setValue $desT 1

        if {$warning != ""} {
            $itk_component(result) configure \
            -text $warning \
            -foreground brown
        } else {
            $itk_component(result) configure \
            -text "" \
            -foreground black
        }
    }

    public method recalculate { } {
        calculateByDelta
    }

    public method setDesired { } {
        if {$itk_option(-runDefinition) == ""} {
            log_error no run linked
            return
        }

        set desD [lindex [$itk_component(desired_delta) get] 0]
        set desT [lindex [$itk_component(desired_time) get] 0]
        set desA [lindex [$itk_component(desired_attenuation) get] 0]

        $itk_option(-runDefinition) setList \
        delta $desD attenuation $desA exposure_time $desT
    }

    private variable m_deviceFactory

    constructor { args  } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]

        set defD 1.0
        set defT 1.0
        set defA 0

        set WIDTH_PROMPT 14
        set WIDTH_ENTRY 12

        itk_component add desired_frame {
            ::iwidgets::labeledframe $itk_interior.df \
            -labeltext "Constant Run Exposure"
        } {
            keep -background
        }
        set desiredSite [$itk_component(desired_frame) childsite]

        itk_component add update {
            DCS::Button $desiredSite.copy \
            -text "Write to Run" \
            -command "$this setDesired"
        } {
        }

        itk_component add desired_delta {
            DCS::Entry $desiredSite.delta \
            -promptText "Delta: " \
            -leaveSubmit 1 \
            -promptWidth $WIDTH_PROMPT \
            -entryWidth $WIDTH_ENTRY \
            -entryType positiveFloat \
            -entryJustify right \
            -decimalPlaces 2 \
            -units "deg" \
            -shadowReference 0 \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -onSubmit "$this calculateByDelta" \
        } {
            keep -background
        }

        itk_component add desired_attenuation {
            DCS::Entry $desiredSite.attenuation \
            -state disabled \
            -disabledbackground $blue \
            -entryRelief flat \
            -leaveSubmit 1 \
            -promptText "Attenuation: " \
            -promptWidth $WIDTH_PROMPT \
            -entryWidth $WIDTH_ENTRY \
            -units "%" \
            -unitsList "%" \
            -entryType positiveFloat \
            -entryJustify right \
            -escapeToDefault 0 \
            -shadowReference 0 \
            -activeClientOnly 0 \
            -systemIdleOnly 0 \
            -autoConversion 0 \
        } {
            keep -background
        }

        itk_component add desired_time {
            DCS::Entry $desiredSite.time \
            -state disabled \
            -disabledbackground $blue \
            -entryRelief flat \
            -leaveSubmit 1 \
            -shadowReference 0 \
            -promptText "Time: " \
            -promptWidth $WIDTH_PROMPT \
            -entryWidth $WIDTH_ENTRY \
            -units "s" \
            -entryType positiveFloat \
            -entryJustify right \
            -decimalPlaces 2 \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
        } {
            keep -background
        }
        pack $itk_component(desired_delta) -side top -anchor w
#yang        pack $itk_component(desired_attenuation)    -anchor w
        pack $itk_component(desired_time)           -anchor w
        pack $itk_component(update)

        itk_component add result {
            label $itk_interior.result
        } {
            keep -background
        }

        pack $itk_component(desired_frame) -side top -expand 1 -fill both
        pack $itk_component(result) -expand 1 -fill x

        $itk_component(desired_attenuation) setValue $defA 1
        $itk_component(desired_time) setValue $defT 1
        $itk_component(desired_delta) setValue $defD 1

	    configure -background $blue

        eval itk_initialize $args

        announceExist
    }
    destructor {
        if {$m_runView != ""} {
            ::mediator unregister $this $m_runView runDefinition
        }
    }
}


class DCS::RunView {
     inherit ::itk::Widget DCS::Component
    
    itk_option define -controlSystem controlsytem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""
    itk_option define -runDefinition runDefinition RunDefinition ::device::run1 
    itk_option define -runListDefinition runListDefinition RunListDefinition ::device::runs 
    
    public method updateEnergyList
   public method updateDoseExposureTime
    public method handleRunDefinitionChange
   public method handleAxisMotorLocked 
   public method handleDoseModeChange 
   public method handleDoseFactorChange
   public method handleDetectorTypeChange

    public method handleSlitMoveCompleted

   public method deleteThisRun
   public method setToDefaultDefinition 
   public method updateDefinition 
   public method resetRun
   public method getReuseDarkSelection {} {return [$itk_component(reuseDark) get]}
   public method getRunDefinition {} {return $itk_option(-runDefinition)}
   public method getDeleteEnabled { } { return [expr ($m_runIndex != 0)?1:0] }
    
   public method updateStartAngleChoices
   #public method updateEndAngleChoices

    public method showCalculator { } {
        if {$m_float_y == 0} {
            set cc [winfo geometry $itk_component(delta)]
            puts "cc=$cc"
            set geo [split $cc "x+"]
            set m_float_x [lindex $geo 2]
            set m_float_y [lindex $geo 3]
        }

        place $itk_component(float_calculator) \
        -x $m_float_x -y $m_float_y -anchor sw

        raise $itk_component(float_calculator)
        set cfg [::config getStr attenuation_calculator.target_delta]
        if {![string is double -strict $cfg]} {
            set cfg 0.1
        }
        if {$cfg < 0.01 || $cfg > 179.99} {
            log_warning target_delta from config is out of range
            log_warning use default 0.1 degree
            set cfg 0.1
        }
        $itk_component(float_calculator) setDelta $cfg
    }

    public method hideCalculator { } {
        place forget $itk_component(float_calculator)
    }

    private variable m_float_x 0
    private variable m_float_y 0

    protected method setDevice
    private method setAxis
   private method repack
   private method repackEnergyList 
   private method repackExposureTime 
   private method setEntryComponentDirectly 

    private variable _ready 0
    private variable m_lastRunDef ""
   private variable m_runIndex 1
   private variable m_doseMode 0 
   private variable m_reuseDark 1
    
   private variable m_deviceFactory
   private variable m_detectorObj

    private variable m_slitWidth
    private variable m_slitHeight

    private variable m_runDefList ""

    private variable m_showCalculator 0

    constructor { args} {
         ::DCS::Component::constructor { runDefinition getRunDefinition \
                                         enableDelete  getDeleteEnabled }
      }  {

        global gMotorPhi
        global gMotorOmega
        global gMotorDistance
        global gMotorBeamStop
        global gMotorEnergy
        global gMotorVert
        global gMotorHorz

        set m_showCalculator [::config getInt attenuation_calculator.show 0]

      set m_deviceFactory [DCS::DeviceFactory::getObject]
      set m_detectorObj [DCS::Detector::getObject]
        
        set m_slitWidth  [$m_deviceFactory getObjectName beam_size_x]
        set m_slitHeight [$m_deviceFactory getObjectName beam_size_y]

        set ring $itk_interior
        
        itk_component add summary {
            DCS::Label $ring.s \
            -attribute summary
        } {}

        # make a frame of control buttons
        itk_component add buttonsFrame {
            frame $ring.bf 
        } {}

        itk_component add defaultButton {
            DCS::Button $itk_component(buttonsFrame).def -text "Default" \
                 -width 5 -pady 0 -activeClientOnly 1 \
                 -systemIdleOnly 0 \
                 -command "$this setToDefaultDefinition" 
        } {}
        
        itk_component add updateButton {
            DCS::Button $itk_component(buttonsFrame).u -text "Update" \
                 -width 5 -pady 0 -activeClientOnly 1 \
                 -systemIdleOnly 0 \
                 -command "$this updateDefinition" 
        } {}
        
        itk_component add deleteButton {
            DCS::Button $itk_component(buttonsFrame).del -text "Delete" \
                 -width 5 -pady 0  -activeClientOnly 1 \
                 -systemIdleOnly 0 \
                 -command "$this deleteThisRun"
        } {
         #rename -command -deleteCommand deleteCommand DeleteCommand
      }
        
        itk_component add resetButton {
            DCS::Button $itk_component(buttonsFrame).r -text "Reset" \
                 -width 5 -pady 0  -activeClientOnly 1 \
                 -systemIdleOnly 0 \
                 -command "$this resetRun" 
        } {}

        itk_component add inverse {
            DCS::Checkbutton $ring.inv -text "Inverse Beam"
        }

        # make the filename root entry
        itk_component add fileRoot {
            DCS::Entry $ring.fileroot \
                 -leaveSubmit 1 \
                 -entryType field \
                 -entryWidth 24 \
                 -entryJustify center \
             -entryMaxLength 128 \
             -promptText "Prefix: " \
                 -promptWidth 12 \
                 -shadowReference 0 \
                 -systemIdleOnly 0 \
                 -activeClientOnly 1
        } {}

        # make the data directory entry
        itk_component add directory {
            DCS::DirectoryEntry $ring.dir \
                 -leaveSubmit 1 \
                 -entryType rootDirectory \
                 -entryWidth 24 \
                 -entryJustify left \
             -entryMaxLength 128 \
             -promptText "Directory: " \
                 -promptWidth 12 \
                 -shadowReference 0 \
                 -systemIdleOnly 0 \
                 -activeClientOnly 1
        } {}

        # make the detector mode entry
        itk_component add detectorMode {
            DCS::DetectorModeMenu $ring.dm -entryWidth 19 \
                 -promptText "Detector: " \
                 -promptWidth 12 \
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

      itk_component add spacer1 {
         frame $ring.spacer1
      } {}
   
      itk_component add spacer2 {
         frame $ring.spacer2
      } {}
    
        # make the energy entry
        itk_component add distance {
            DCS::MotorViewEntry $ring.distance \
                -checkLimits -1 \
                -menuChoiceDelta 50 \
                 -device ::device::$gMotorDistance \
                 -showPrompt 1 \
                 -leaveSubmit 1 \
                 -promptText "Distance: " \
                 -promptWidth 12 \
                 -entryWidth 10 -units "mm" -unitsList "mm" \
                 -entryType positiveFloat \
                 -entryJustify right \
                 -escapeToDefault 0 \
                 -shadowReference 0 \
                 -activeClientOnly 1 \
                 -systemIdleOnly 0 \
                 -autoConversion 1
        } {}
        
        itk_component add beam_stop {
            DCS::MotorViewEntry $ring.beam_stop \
                -checkLimits -1 \
                -menuChoiceDelta 5 \
                 -device ::device::$gMotorBeamStop \
                 -showPrompt 1 \
                 -leaveSubmit 1 \
                 -promptText "Beam Stop: " \
                 -promptWidth 12 \
                 -entryWidth 10 -units "mm" -unitsList "mm" \
                 -entryType positiveFloat \
                 -entryJustify right \
                 -escapeToDefault 0 \
                 -shadowReference 0 \
                 -activeClientOnly 1 \
                 -systemIdleOnly 0 \
                 -autoConversion 1
        } {}

        itk_component add att_frame {
            frame $ring.att_frame
        } {
        }
        set attSite $itk_component(att_frame)

        itk_component add attenuation {
            DCS::MotorViewEntry $attSite.attenuation \
                -checkLimits -1 \
                -menuChoiceDelta 10 \
                 -device ::device::attenuation \
                 -showPrompt 1 \
                 -leaveSubmit 1 \
                 -promptText "Attenuation: " \
                 -promptWidth 12 \
                 -entryWidth 10 -units "%" -unitsList "%" \
                 -entryType positiveFloat \
                 -entryJustify right \
                 -escapeToDefault 0 \
                 -shadowReference 0 \
                 -activeClientOnly 1 \
                 -systemIdleOnly 0 \
                 -autoConversion 1
        } {}
#yang        pack $itk_component(attenuation) -side left

        if {$m_showCalculator} {
            itk_component add top {
                DCS::DropdownMenu $attSite.cal \
                -systemIdleOnly 0 \
                -activeClientOnly 0 \
                -text "Calc" \
                -state normal
            } {
            }

            $itk_component(top) add command \
            -label "Attenuation Calculator" \
            -command "$this showCalculator"

            pack $itk_component(top)
        }

        itk_component add axis {
            DCS::MenuEntry $ring.axis \
                 -leaveSubmit 1 \
                 -entryWidth 9 \
                 -entryType string \
                 -entryJustify center \
                 -promptText "Axis: " \
                 -promptWidth 12 \
                 -shadowReference 0 \
                 -showEntry 0 \
                 -systemIdleOnly 0 \
                 -activeClientOnly 1
        } {
        }

        # make the width entry
        itk_component add delta {
            DCS::Entry $ring.delta -promptText "Delta: " \
                 -leaveSubmit 1 \
                 -promptWidth 12 \
                 -entryWidth 10     \
                 -entryType positiveFloat \
                 -entryJustify right \
                 -decimalPlaces 2 \
                 -units "deg" \
                 -shadowReference 0 \
                 -systemIdleOnly 0 \
                 -activeClientOnly 1
        } {}

        # make the exposure time frame
        itk_component add exposureTimeFrame {
            frame $ring.et
        } {}

        itk_component add exposureTime {
            DCS::Entry $itk_component(exposureTimeFrame).time \
                 -leaveSubmit 1 \
                 -promptText "Time: " -promptWidth 2 -units "s" \
                 -entryType positiveFloat \
                 -entryJustify right \
                 -decimalPlaces 2 \
                 -systemIdleOnly 0 \
                 -activeClientOnly 1 -onChange [list $this updateDoseExposureTime]
        } {}
        

      itk_component add multiply {
         label $itk_component(exposureTimeFrame).m -text "*" -width 2 -justify left -anchor e
      } {}

      itk_component add doseFactor {
         label $itk_component(exposureTimeFrame).df
      } {}

      itk_component add equals {
         label $itk_component(exposureTimeFrame).eq -text "=" -width 2 -justify left -anchor e
      } {}

      itk_component add doseExposureTime {
         label $itk_component(exposureTimeFrame).dt 
      } {}

        # make the exposures frame
        itk_component add exposureFrame {
            frame $ring.ef
        } {}

        itk_component add frameHeader {
            label $itk_component(exposureFrame).f -text "Frame" -anchor e
        } {}
        
        itk_component add angleHeader {
            DCS::Label $itk_component(exposureFrame).a -attribute -value -component $itk_component(axis)
        } {}

        itk_component add startFrame {
            DCS::Entry $itk_component(exposureFrame).sf \
                 -leaveSubmit 1 \
                 -promptText "Start: " \
                 -promptWidth 7 \
                 -entryWidth 6     \
                 -entryType positiveInt \
                 -entryJustify right \
                 -systemIdleOnly 0 \
                 -activeClientOnly 1
        } {}
    
        itk_component add startAngleRun0 {
            DCS::MenuEntry $itk_component(exposureFrame).sar0 \
                 -leaveSubmit 1 \
                 -entryWidth 9 \
                 -entryType float \
                 -entryJustify right \
                 -units "deg" -unitsList "deg" \
                 -unitsWidth 4 \
                 -shadowReference 0 \
                 -decimalPlaces 2 \
                 -reference "::device::$gMotorPhi scaledPosition" \
                 -escapeToDefault 0 \
                 -systemIdleOnly 0 \
                 -activeClientOnly 1 \
                 -autoConversion 1
        } {}
    
        itk_component add startAngle {
            DCS::Entry $itk_component(exposureFrame).sa \
                 -leaveSubmit 1 \
                 -entryWidth 9 \
                 -entryType float \
                 -entryJustify right \
                 -units "deg" -unitsList "deg" \
                 -unitsWidth 4 \
                 -shadowReference 0 \
                 -decimalPlaces 2 \
                 -reference "::device::$gMotorPhi scaledPosition" \
                 -escapeToDefault 0 \
                 -systemIdleOnly 0 \
                 -activeClientOnly 1 \
                 -autoConversion 1
        } {}


        itk_component add endFrame {
            DCS::Entry $itk_component(exposureFrame).ef \
                 -leaveSubmit 1 \
                 -promptText "End: " \
                 -promptWidth 7 \
                 -entryWidth 6     \
                 -entryType positiveInt \
                 -entryJustify right \
                 -decimalPlaces 2 \
                 -systemIdleOnly 0 \
                 -activeClientOnly 1
        #         -zeroPadDigits 3
        } {}
        
        itk_component add endAngle {
            DCS::Entry $itk_component(exposureFrame).ea \
                 -leaveSubmit 1 \
                 -shadowReference 0 \
                 -entryWidth 9 \
                 -entryType float \
                 -entryJustify right \
                 -units "deg" -unitsList "deg" \
                 -unitsWidth 4 \
                 -shadowReference 0 \
                 -decimalPlaces 2 \
                 -reference "::device::$gMotorPhi scaledPosition" \
                 -escapeToDefault 0 \
                 -systemIdleOnly 0 \
                 -activeClientOnly 1 \
                 -autoConversion 1
        } {}

        itk_component add wedgeSize {
            DCS::MenuEntry $ring.wedge \
                 -leaveSubmit 1 \
                 -promptText "Wedge: " -units "deg" \
                 -entryType positiveFloat \
                 -showEntry 1 \
                 -menuChoices  {30.0 45.0 60.0 90.0 180.0} \
                 -entryJustify right \
                 -promptWidth 12 \
                 -entryWidth 12 \
                 -menuColumnBreak 9 \
                 -decimalPlaces 2 \
                 -systemIdleOnly 0 \
                 -activeClientOnly 1
             } {}
        
    
      itk_component add energyFrame {
         frame $ring.eframe
      } {}

        set energyPrompt "Energy: "

        for { set cnt 0 } { $cnt < 5 } {incr cnt} {
            
            itk_component add energy$cnt {
                DCS::MotorViewEntry $itk_component(energyFrame).e$cnt \
                        -checkLimits -1 \
                        -menuChoiceDelta 1000 \
                        -device ::device::energy \
                        -showPrompt 1 \
                     -leaveSubmit 1 \
                     -promptText $energyPrompt \
                     -promptWidth 12 \
                     -unitsList eV -units eV \
                     -shadowReference 0 \
                     -onSubmit "$this updateEnergyList" \
                     -entryType positiveFloat \
                     -entryJustify right \
                     -entryWidth 12 \
                     -escapeToDefault 0 \
                     -autoConversion 1 \
                     -systemIdleOnly 0 \
                     -activeClientOnly 1 \
                     -nullAllowed 1
            } {}
            
            set energyPrompt " "
        }

      itk_component add reuseDark {    
         DCS::Checkbutton $ring.forcedark -text "Use Last Dark" 
        }

	$itk_component(reuseDark) setValue $m_reuseDark

      # create resolution predictor
      itk_component add resolution {
         DCS::ResolutionWidget $ring.res \
            -detectorBackground #c0c0ff \
            -detectorForeground white
      } {
         keep -detectorHorzDevice -detectorVertDevice
      }

        if {$m_showCalculator} {
            itk_component add float_calculator {
                DCS::RunOnlineCalculator $ring.calculator
            } {
                keep -runDefinition
            }
            bind $itk_component(float_calculator) <Leave> "$this hideCalculator"
        }

      #let the resolution widget know the names of the motor widgets
      $itk_component(resolution) configure -detectorXWidget [$m_deviceFactory getObjectName $gMotorHorz]
      $itk_component(resolution) configure -detectorYWidget [$m_deviceFactory getObjectName $gMotorVert]
      $itk_component(resolution) configure -detectorZWidget $itk_component(distance)
      $itk_component(resolution) configure -beamstopZWidget $itk_component(beam_stop)
      $itk_component(resolution) configure -energyWidget $itk_component(energy0)
      $itk_component(resolution) configure -externalModeWidget $itk_component(detectorMode)

        eval itk_initialize $args

      ::mediator register $this [$m_deviceFactory getObjectName $gMotorOmega] lockOn handleAxisMotorLocked
      ::mediator register $this $itk_option(-runListDefinition) doseMode handleDoseModeChange 
      ::mediator register $this $m_detectorObj type handleDetectorTypeChange 
      ::mediator register $this $m_slitWidth  inMotion handleSlitMoveCompleted
      ::mediator register $this $m_slitHeight inMotion handleSlitMoveCompleted

      #handleDetectorTypeChange will call repack
      #repack

        $itk_component(deleteButton) addInput "$this enableDelete 1 {Cannot delete snapshot}"
        #### disable delete while collect data is running.
        #### because it the dcss only remembers which run it is running
        #### and remove of a run with smaller run number will cause
        #### Bluice to display wrong information.
        $itk_component(deleteButton) addInput "::device::collectRuns status inactive {Collecting Data}"
        $itk_component(inverse) addInput "::$itk_component(axis) -value Phi {Inverse can only be used with phi axis.}"

     set doseFactorObject [DCS::DoseFactor::getObject] 
      ::mediator register $this $doseFactorObject doseFactor handleDoseFactorChange

      announceExist

        set _ready 1
    }
    
    destructor {
      ::mediator announceDestruction $this
    }
}

body DCS::RunView::handleDetectorTypeChange { detector_ targetReady_ alias_ type_ - } {
    #puts "RunView handleDetectorTypeChange $detector_ $targetReady_ $alias_ $type_"
    if {!$targetReady_} return
    repack
}
body DCS::RunView::repack { } {
    set ring $itk_interior
    
    pack $itk_component(summary) -pady 5 
    pack $itk_component(buttonsFrame) -pady 5
    pack $itk_component(defaultButton) -side left -padx 3
    pack $itk_component(updateButton) -side left -padx 3
    pack $itk_component(deleteButton) -side left -padx 3
    pack $itk_component(resetButton) -side left -padx 3

    pack $itk_component(fileRoot) -pady 4 -padx 5 -anchor w
    pack $itk_component(directory) -pady 4 -padx 5 -anchor w
    pack $itk_component(detectorMode) -pady 4 -padx 3 -anchor w

    pack $itk_component(spacer1) -pady 5

    pack $itk_component(distance) -padx 4 -pady 4 -anchor w
#yang    pack $itk_component(beam_stop) -padx 4 -pady 4 -anchor w
   
   pack $itk_component(axis) -pady 4 -padx 4 -anchor w
    pack $itk_component(delta) -padx 5 -pady 4 -anchor w
    pack $itk_component(att_frame) -padx 4 -pady 4 -anchor w
    pack $itk_component(exposureTimeFrame) -pady 2 -side top -anchor w
   
   repackExposureTime

    pack $itk_component(spacer2) -pady 5

    pack $itk_component(exposureFrame) -ipadx 5
    grid $itk_component(frameHeader) -column 0 -row 0 -sticky e
    grid $itk_component(angleHeader) -column 1 -row 0
    grid $itk_component(startFrame) -column 0 -row 1

    #puts "DEBUG: m_runIndex=$m_runIndex"
   if {$m_runIndex == 0 } {
      grid forget $itk_component(startAngle)
       grid $itk_component(startAngleRun0) -column 1 -row 1
      grid forget $itk_component(endFrame)
      grid forget $itk_component(endAngle)
      pack forget $itk_component(inverse)
      pack forget $itk_component(wedgeSize)

      set detector [$m_detectorObj getType]
       #puts "DEBUG detector type: $detector"
       if { $detector == "Q4CCD" || $detector == "Q315CCD" || $detector == "MAR165" || $detector == "MAR325" } {
        #puts "DEBUG pack the reuseDark"
         pack $itk_component(reuseDark)
      } else {
         pack forget $itk_component(reuseDark)
      }
   } else {
      grid forget $itk_component(startAngleRun0)
       grid $itk_component(startAngle) -column 1 -row 1

      pack forget $itk_component(reuseDark)
       grid $itk_component(endFrame) -column 0 -row 2
       grid $itk_component(endAngle) -column 1 -row 2
       pack $itk_component(inverse) -after $itk_component(exposureFrame) -pady 2 -side top -anchor n
       pack $itk_component(wedgeSize) -after $itk_component(inverse) -side top -anchor w
   }

   pack $itk_component(energyFrame) -anchor w -pady 2
    pack $itk_component(energy0) -anchor w -pady 2

   if { $m_runIndex == 0 } {
      pack $itk_component(resolution)
   } else {
      pack forget $itk_component(resolution)
   }




   #repackEnergyList

}


body DCS::RunView::repackExposureTime { } {
   if { $m_doseMode } {
        #pack forget $itk_component(attenuation)
        #pack $itk_component(attenuation_motor) -padx 4 -pady 4 -anchor w \
        -after $itk_component(beam_stop)

      $itk_component(exposureTime) configure -promptWidth 6 -entryWidth 7 
       pack $itk_component(exposureTime) -anchor w -side left
      pack $itk_component(multiply) -side left -after $itk_component(exposureTime)
      pack $itk_component(doseFactor) -side left -after $itk_component(multiply)
      pack $itk_component(equals) -side left -after $itk_component(doseFactor)
      pack $itk_component(doseExposureTime) -side left -after $itk_component(equals)
   } else {
        #pack forget $itk_component(attenuation_motor)
        #pack $itk_component(attenuation) -padx 4 -pady 4 -anchor w \
        -after $itk_component(beam_stop)

      $itk_component(exposureTime) configure -promptWidth 12 -entryWidth 10
      pack forget $itk_component(multiply)
      pack forget $itk_component(doseFactor)
      pack forget $itk_component(equals)
      pack forget $itk_component(doseExposureTime)
       pack $itk_component(exposureTime) -anchor w -padx 5
   }
}

body DCS::RunView::updateDoseExposureTime { } {
    set exposureTime [lindex [$itk_component(exposureTime) get] 0]

    if { ! [isFloat $exposureTime] } return

    set fg black

    if {$m_doseMode} {
        set runSituation [clock seconds]
        lappend runSituation [lindex [$itk_component(energy0) get] 0]
        lappend runSituation [lindex [$m_slitWidth getScaledPosition] 0]
        lappend runSituation [lindex [$m_slitHeight getScaledPosition] 0]
        lappend runSituation [lindex [$itk_component(attenuation) get] 0]

        set doseFactor \
        [[DCS::DoseFactor::getObject] estimateNewDoseFactor $runSituation]

        if {[string first * $doseFactor] >= 0} {
            set fg red
        }

        $itk_component(doseFactor) configure \
        -foreground $fg \
        -text $doseFactor

        set doseTime [expr $exposureTime * $doseFactor]
    } else {
        set doseTime $exposureTime
    }

    $itk_component(doseExposureTime) configure \
    -foreground $fg \
    -text [format "%.2f" $doseTime]
}

body DCS::RunView::setAxis { axis_  } {
    global gMotorPhi
    global gMotorOmega
    
    if { $axis_ == "Omega" } {
        $itk_component(startAngle) configure -reference "::device::$gMotorOmega scaledPosition"
        $itk_component(startAngleRun0) configure -reference "::device::$gMotorOmega scaledPosition"
        $itk_component(endAngle) configure -reference "::device::$gMotorOmega scaledPosition"
    }

    if { $axis_ == "Phi" } {
        $itk_component(startAngle) configure -reference "::device::$gMotorPhi scaledPosition"
        $itk_component(startAngleRun0) configure -reference "::device::$gMotorPhi scaledPosition"
        $itk_component(endAngle) configure -reference "::device::$gMotorPhi scaledPosition"
    }
    
    $itk_component(axis) setValue $axis_ 1
}

body DCS::RunView::handleRunDefinitionChange { run_ targetReady_ alias_ runDefinition_ -  } {

    if { ! $targetReady_} return

    ### get run index
    set indexFromEvent [string range [namespace tail $run_] 3 end]

    if {$indexFromEvent != $m_runIndex} {
        puts "got update from $run_ while we are handling $m_runIndex"
        return
    }


    foreach { runStatus nextFrame runLabel \
                      fileRoot directory startFrame axis \
                      startAngle endAngle delta wedgeSize exposureTime distance beamStop attenuation \
                      numEnergy energy(0) energy(1) energy(2) energy(3) energy(4) \
                      detectorMode inverse } $runDefinition_ break
    #puts "rundef for $run_: $runDefinition_"
    #puts "distance=$distance beamStop=$beamStop"

    set endFrame [$run_ cget -endFrame]

    #set directly
    setEntryComponentDirectly fileRoot $fileRoot
    setEntryComponentDirectly directory $directory
    $itk_component(detectorMode) setValueByIndex $detectorMode 1
    setEntryComponentDirectly distance $distance
    setEntryComponentDirectly beam_stop $beamStop
    setEntryComponentDirectly attenuation $attenuation
    $this setAxis $axis
    setEntryComponentDirectly delta $delta
    $itk_component(inverse) setValue $inverse
    setEntryComponentDirectly exposureTime $exposureTime 
    setEntryComponentDirectly startFrame $startFrame
    setEntryComponentDirectly startAngle $startAngle
    setEntryComponentDirectly startAngleRun0 $startAngle
    setEntryComponentDirectly endAngle $endAngle
    setEntryComponentDirectly endFrame $endFrame
 setEntryComponentDirectly wedgeSize $wedgeSize

    if {$m_showCalculator} {
        $itk_component(float_calculator) configure \
        -runInfo [list $delta $attenuation $exposureTime]
    }

   #fill in the entries with the new energies
    if {$numEnergy > 5} {
        set numEnergy 5
        puts "wrong numEnergy: $numEnergy"
    }
    for { set cnt 0 } { $cnt < $numEnergy} { incr cnt} {
        setEntryComponentDirectly energy$cnt [list $energy($cnt) eV] 
    }

   #set remaining energy entries to blank    
    for { set cnt $numEnergy } { $cnt < 5} { incr cnt} {
        $itk_component(energy$cnt) setValue "" 1
    }

   repackEnergyList $numEnergy
   updateDoseExposureTime 
   updateStartAngleChoices
   #updateEndAngleChoices
}

body DCS::RunView::setEntryComponentDirectly { component_ value_ } {
   $itk_component($component_) setValue $value_ 1
}

body DCS::RunView::repackEnergyList { numEnergy_ } {

   #if it is the snapshot run, display only one energy entry
   if {$m_runIndex == 0} {
      pack $itk_component(energy0) -anchor w -pady 2
      pack forget $itk_component(energy1)
      pack forget $itk_component(energy2)
      pack forget $itk_component(energy3)
      pack forget $itk_component(energy4)
      return
   }

   #pack all entries with values and one with blank value, but no more than 5
    for { set cnt 0 } { $cnt < [expr $numEnergy_ + 1] && $cnt < 5} { incr cnt} {
        pack $itk_component(energy$cnt) -anchor w -pady 2
    }
    
   #unpack any remaining entries
    for { set cnt [expr $numEnergy_ + 1] } { $cnt < 5} { incr cnt} {
        pack forget $itk_component(energy$cnt)
    }
}

body DCS::RunView::updateEnergyList {} {
    global gMotorEnergy

    if { ! $_ready } return
    
    set energyList ""
    
    for { set cnt 0 } { $cnt < 5} { incr cnt} {
        set energy($cnt) [$itk_component(energy$cnt) get]
        
        if { [lindex $energy($cnt) 0] != "" } { 
            
            if { $energy($cnt) != 0.0 } {
                lappend energyList [lindex [::units convertUnitValue $energy($cnt) eV] 0]
            }
        }
    }

    if { $energyList == "" } {set energyList [::device::$gMotorEnergy cget -scaledPosition]}

    $itk_option(-runDefinition) setEnergyList $energyList
}


body DCS::RunView::updateStartAngleChoices { } {
    global gMotorOmega

   set axis [$itk_component(axis) get]
   set startAngle [lindex [$itk_component(startAngle) get] 0]

    #add +90 & -90 for angle selection for run 0
    if { $axis == "Phi"} {
        set angle_plus90 [expr $startAngle + 90 +360 ]
        set angle_plus90 [expr $angle_plus90 - 360.0 * ( int($angle_plus90 / 360))]
        set angle_minus90 [expr $startAngle - 90 +360 ]
        set angle_minus90 [expr $angle_minus90 - 360.0 * ( int($angle_minus90 / 360))]
        set startAngleChoices [list $angle_minus90 $angle_plus90 ]
    } else {
        set angle_plus90 [expr $startAngle + 90 ]
        set angle_minus90 [expr $startAngle - 90 ]

      set upperLimit [lindex [::device::$gMotorOmega getUpperLimit] 0]
      set lowerLimit [lindex [::device::$gMotorOmega getLowerLimit] 0]

        if { $angle_plus90 <= $upperLimit && $angle_plus90 >= $lowerLimit } {
            set startAngleChoices [list $angle_plus90]
        } elseif { $angle_minus90 <= $upperLimit && $angle_minus90 >= $lowerLimit } {
            set startAngleChoices [list $angle_minus90]
        } else {
            set startAngleChoices $startAngle
        }
    }

   $itk_component(startAngleRun0) configure -menuChoices $startAngleChoices
}

#body DCS::RunView::updateEndAngleChoices { } {
#   set endAngle [lindex [$itk_component(endAngle) get] 0]
#   $itk_component(endAngle) configure -menuChoices $endAngle
#
#}



configbody DCS::RunView::runDefinition {
    global gMotorDistance
    global gMotorBeamStop

    if {$itk_option(-runDefinition) == ""} {
        return
    }

   set m_runIndex [$itk_option(-runDefinition) getRunIndex]

   $itk_component(summary) configure -component $itk_option(-runDefinition)

   $itk_component(fileRoot) configure \
    -onSubmit "$itk_option(-runDefinition) setFileRoot %s" \
    -reference "$itk_option(-runDefinition) fileRoot" 

   $itk_component(directory) configure \
    -onSubmit "$itk_option(-runDefinition) setDirectory %s" \
    -reference "$itk_option(-runDefinition) directory"
                 
    $itk_component(detectorMode) configure \
    -onSubmit "$itk_option(-runDefinition) setDetectorMode %s"

   $itk_component(distance) configure \
   -onSubmit "$itk_option(-runDefinition) setDistance %s"

   $itk_component(beam_stop) configure \
   -onSubmit "$itk_option(-runDefinition) setBeamStop %s"

   $itk_component(attenuation) configure \
   -onSubmit "$itk_option(-runDefinition) setAttenuation %s" \

   #$itk_component(attenuation_motor) configure \
   -onSubmit "" \
   -reference "::device::attenuation scaledPosition"

   $itk_component(axis) configure \
    -menuChoices [$itk_option(-runDefinition) getAxisChoices] \
    -onSubmit "$itk_option(-runDefinition) setAxis %s" \
    -reference "$itk_option(-runDefinition) axis"

    $itk_component(delta) configure \
      -onSubmit "$itk_option(-runDefinition) setDelta %s" \
      -reference "$itk_option(-runDefinition) delta"

   $itk_component(exposureTime) configure \
      -onSubmit "$itk_option(-runDefinition) setExposureTime %s" \
      -reference "$itk_option(-runDefinition) exposureTime"

   $itk_component(startFrame) configure \
      -onSubmit "$itk_option(-runDefinition) setStartFrame %s" \
      -reference "$itk_option(-runDefinition) startFrame"

   $itk_component(startAngle) configure \
      -onSubmit "$itk_option(-runDefinition) setStartAngle %s"
   
   $itk_component(startAngleRun0) configure \
      -onSubmit "$itk_option(-runDefinition) setStartAngle %s"

    $itk_component(endFrame) configure \
       -reference "$itk_option(-runDefinition) endFrame" \
        -onSubmit "$itk_option(-runDefinition) setEndFrame %s"

   $itk_component(endAngle) configure \
      -onSubmit "$itk_option(-runDefinition) setEndAngle %s"

    $itk_component(inverse) configure \
      -command "$itk_option(-runDefinition) setInverse %s" \
      -reference "$itk_option(-runDefinition) inverse"

   $itk_component(wedgeSize) configure \
      -onSubmit "$itk_option(-runDefinition) setWedgeSize %s" \
      -reference "$itk_option(-runDefinition) wedgeSize"

    if { $m_lastRunDef != "" && $m_lastRunDef != $itk_option(-runDefinition) } {
       ::mediator unregister $this $m_lastRunDef contents
      $itk_component(resetButton) deleteInput [list $m_lastRunDef needsReset 1]
      $itk_component(defaultButton) deleteInput [list $m_lastRunDef state "inactive"]
      $itk_component(updateButton) deleteInput [list $m_lastRunDef state "inactive"]
      $itk_component(deleteButton) deleteInput [list $m_lastRunDef state "inactive"]
      $itk_component(fileRoot) deleteInput [list $m_lastRunDef state "inactive"]
      $itk_component(directory) deleteInput [list $m_lastRunDef state "inactive"]
      $itk_component(detectorMode) deleteInput [list $m_lastRunDef state "inactive"]
      $itk_component(distance) deleteInput [list $m_lastRunDef state "inactive"]
      $itk_component(beam_stop) deleteInput [list $m_lastRunDef state "inactive"]
      $itk_component(attenuation) deleteInput [list $m_lastRunDef state "inactive"]
      $itk_component(axis) deleteInput [list $m_lastRunDef state "inactive"]
      $itk_component(delta) deleteInput [list $m_lastRunDef state "inactive"]
      $itk_component(exposureTime) deleteInput [list $m_lastRunDef state "inactive"]
      $itk_component(startFrame) deleteInput [list $m_lastRunDef state "inactive"]
      $itk_component(endFrame) deleteInput [list $m_lastRunDef state "inactive"]
      $itk_component(startAngle) deleteInput [list $m_lastRunDef state "inactive"]
      $itk_component(startAngleRun0) deleteInput [list $m_lastRunDef state "inactive"]
      $itk_component(endAngle) deleteInput [list $m_lastRunDef state "inactive"]
      $itk_component(wedgeSize) deleteInput [list $m_lastRunDef state "inactive"]
      $itk_component(inverse) deleteInput [list $m_lastRunDef state "inactive"]
      $itk_component(energy0) deleteInput [list $m_lastRunDef state "inactive"]
      $itk_component(energy1) deleteInput [list $m_lastRunDef state "inactive"]
      $itk_component(energy2) deleteInput [list $m_lastRunDef state "inactive"]
      $itk_component(energy3) deleteInput [list $m_lastRunDef state "inactive"]
      $itk_component(energy4) deleteInput [list $m_lastRunDef state "inactive"]
   }
    
   ::mediator register $this $itk_option(-runDefinition) contents handleRunDefinitionChange
   
   $itk_component(resetButton) addInput [list $itk_option(-runDefinition) needsReset 1 "Reset 'Paused' or 'Completed' runs only."]
   $itk_component(defaultButton) addInput [list $itk_option(-runDefinition) state "inactive" "Run must be reset before using."]
   $itk_component(updateButton) addInput [list $itk_option(-runDefinition) state "inactive" "Run must be reset before using."]
   $itk_component(deleteButton) addInput [list $itk_option(-runDefinition) state "inactive" "Run must be reset before using."]
   $itk_component(fileRoot) addInput [list $itk_option(-runDefinition) state "inactive" "Run must be reset before using."]
   $itk_component(directory) addInput [list $itk_option(-runDefinition) state "inactive" "Run must be reset before using."]
   $itk_component(detectorMode) addInput [list $itk_option(-runDefinition) state "inactive" "Run must be reset before using."]
   $itk_component(distance) addInput [list $itk_option(-runDefinition) state "inactive" "Run must be reset before using."]
   $itk_component(beam_stop) addInput [list $itk_option(-runDefinition) state "inactive" "Run must be reset before using."]
   $itk_component(attenuation) addInput [list $itk_option(-runDefinition) state "inactive" "Run must be reset before using."]
   $itk_component(axis) addInput [list $itk_option(-runDefinition) state "inactive" "Run must be reset before using."]
   $itk_component(delta) addInput [list $itk_option(-runDefinition) state "inactive" "Run must be reset before using."]
   $itk_component(exposureTime) addInput [list $itk_option(-runDefinition) state "inactive" "Run must be reset before using."]
   $itk_component(startFrame) addInput [list $itk_option(-runDefinition) state "inactive" "Run must be reset before using."]
   $itk_component(endFrame) addInput [list $itk_option(-runDefinition) state "inactive" "Run must be reset before using."]
   $itk_component(startAngle) addInput [list $itk_option(-runDefinition) state "inactive" "Run must be reset before using."]
   $itk_component(startAngleRun0) addInput [list $itk_option(-runDefinition) state "inactive" "Run must be reset before using."]
   $itk_component(endAngle) addInput [list $itk_option(-runDefinition) state "inactive" "Run must be reset before using."]
   $itk_component(wedgeSize) addInput [list $itk_option(-runDefinition) state "inactive" "Run must be reset before using."]
   $itk_component(inverse) addInput [list $itk_option(-runDefinition) state "inactive" "Run must be reset before using."]
   $itk_component(energy0) addInput [list $itk_option(-runDefinition) state "inactive" "Run must be reset before using."]
   $itk_component(energy1) addInput [list $itk_option(-runDefinition) state "inactive" "Run must be reset before using."]
   $itk_component(energy2) addInput [list $itk_option(-runDefinition) state "inactive" "Run must be reset before using."]
   $itk_component(energy3) addInput [list $itk_option(-runDefinition) state "inactive" "Run must be reset before using."]
   $itk_component(energy4) addInput [list $itk_option(-runDefinition) state "inactive" "Run must be reset before using."]

   #if the string for table optimization exists then require energy tracking to be enabled to enable energy definition
   if { [$m_deviceFactory stringExists optimizedEnergyParameters] } {
      set m_optimizeEnergyParamsObj [DCS::OptimizedEnergyParams::getObject]
      $itk_component(energy0) addInput [list $m_optimizeEnergyParamsObj trackingEnable "1" "Energy tracking is disabled."]
      $itk_component(energy1) addInput [list $m_optimizeEnergyParamsObj trackingEnable "1" "Energy tracking is disabled."]
      $itk_component(energy2) addInput [list $m_optimizeEnergyParamsObj trackingEnable "1" "Energy tracking is disabled."]
      $itk_component(energy3) addInput [list $m_optimizeEnergyParamsObj trackingEnable "1" "Energy tracking is disabled."]
      $itk_component(energy4) addInput [list $m_optimizeEnergyParamsObj trackingEnable "1" "Energy tracking is disabled."]
   }

   set m_lastRunDef $itk_option(-runDefinition)

   repack

   #inform interested widgets that we are looking at a different run definition
   updateRegisteredComponents runDefinition
   updateRegisteredComponents enableDelete
}
    


body DCS::RunView::deleteThisRun {} {

   $itk_option(-runListDefinition) deleteRun $m_runIndex

}

body DCS::RunView::resetRun {} {
   $itk_option(-runDefinition) reset 
}

body DCS::RunView::setToDefaultDefinition { } {
    puts "set to default run"
    $itk_option(-runDefinition) resetRun
}

body DCS::RunView::handleDoseFactorChange { object_ targetReady_ alias_ doseFactor_ - } {
   if { !$targetReady_} return
   
   updateDoseExposureTime

}
body DCS::RunView::handleSlitMoveCompleted { - targetReady_ - - - } {
   if { !$targetReady_} return

    if {[$m_slitWidth cget -inMotion] || [$m_slitHeight cget -inMotion]} {
        puts "DEBUG still moving"
        return
    }
    puts "DEBUG done moving. update"
    updateDoseExposureTime
}


body DCS::RunView::updateDefinition { } {
    global gMotorPhi
    global gMotorOmega
    global gMotorDistance
    global gMotorBeamStop
    global gMotorEnergy

   set attenuation [lindex [::device::attenuation getScaledPosition] 0]

    foreach motor [list $gMotorBeamStop $gMotorDistance] \
    setName [list beamstop_setting distance_setting] {
        set curP [lindex [::device::$motor getScaledPosition] 0]
        if {![::device::$motor limits_ok curP]} {
            log_warning $motor current position out of limits, using $curP
        }
        set $setName $curP
    }

    if { [$itk_component(axis) get]  == "Phi" } {
      set startAngle [lindex [::device::$gMotorPhi getScaledPosition] 0]
    } else {
      set startAngle [lindex [::device::$gMotorOmega getScaledPosition] 0]
    }
    set endFrame    [$itk_component(endFrame) get]
    set startFrame  [$itk_component(startFrame) get]
    set delta [lindex [$itk_component(delta) get] 0]
    set endAngle [expr ($endFrame - $startFrame + 1) * $delta + $startAngle]

   set numEnergy 0
   set energy(1) ""
   set energy(2) ""
   set energy(3) ""
   set energy(4) ""
   set energy(5) ""

   set peakEnergy 0.0
   set remoteEnergy 0.0

   set userScanWindow [[InflectPeakRemExporter::getObject] getExporter] 
   if { [info commands $userScanWindow] != "" } {

       set peakEnergy [lindex [$userScanWindow getMadEnergy Peak] 0]
      if {$peakEnergy != "" } {
         incr numEnergy
         set energy($numEnergy) $peakEnergy
      }

       set remoteEnergy [lindex [$userScanWindow getMadEnergy Remote] 0]
      if {$remoteEnergy != "" } {
         incr numEnergy
         set energy($numEnergy) $remoteEnergy
      }

      set inflectionEnergy  [lindex [$userScanWindow getMadEnergy Inflection] 0]
      if {$inflectionEnergy != "" } {
         incr numEnergy
         set energy($numEnergy) $inflectionEnergy
      }

   }

   #if it is the snapshot run, display only one energy entry
   if {$numEnergy == 0 || $m_runIndex == 0} {
      set numEnergy 1
      set energy(1) [lindex [::device::$gMotorEnergy getScaledPosition] 0]
      set energy(2) ""
      set energy(3) ""
      set energy(4) ""
      set energy(5) ""
   }

   #try to get the filename prefix from the screening tab...
    set object [$m_deviceFactory createString crystalStatus]
    #$object createAttributeFromField current 0
    #$object createAttributeFromField subdir 4
   set fileRoot [$object getFieldByIndex 0] 

   if { $fileRoot == "" } {
      #nothing is mounted now...leave the entry alone
      set fileRoot [$itk_component(fileRoot) get]
      set directory [$itk_component(directory) get]
   } else {
      #something is mounted...get the directory from screening 
      set dirObj [$m_deviceFactory createString screeningParameters]
      set rootDir [$dirObj getFieldByIndex 2]
      set subDir [$object getFieldByIndex 4]
      set directory [file join $rootDir $subDir]
   }

    $itk_option(-runDefinition) setList \
    status inactive \
    file_root $fileRoot \
    directory  $directory \
    start_angle $startAngle \
    end_angle $endAngle \
    distance $distance_setting \
    beam_stop $beamstop_setting \
    attenuation $attenuation \
    num_energy $numEnergy \
    energy1 $energy(1) \
    energy2 $energy(2) \
    energy3 $energy(3) \
    energy4 $energy(4) \
    energy5 $energy(5)
}

body DCS::RunView::handleDoseModeChange { runList_ targetReady_ alias_ doseMode_ -  } {
   if { !$targetReady_ } return
   
   set m_doseMode $doseMode_
   updateDoseExposureTime
   repackExposureTime
}

body DCS::RunView::handleAxisMotorLocked { device_ targetReady_ alias_ lockedOn_ -  } {
   if { !$targetReady_ } return
    if {$itk_option(-runDefinition) == ""} {
        return
    }
   $itk_component(axis) configure -menuChoices [$itk_option(-runDefinition) getAxisChoices]
}

class DCS::RunListView {
     inherit ::itk::Widget ::DCS::Component
    
    itk_option define -device device Device ""
    itk_option define -mdiHelper mdiHelper MdiHelper ""
    itk_option define -runListDefinition runListDefinition RunListDefinition ::device::runs
    itk_option define -controlSystem controlsytem ControlSystem "::dcss"

   private variable BROWNRED #a0352a
   private variable ACTIVEBLUE #2465be
   private variable DARK #777

    public proc getFirstObject { } {
        return $s_object
    }
   
   public method handleRunLabelChange
   public method handleRunStateChange
   public method handleRunCountChange
   public method handleClientStatusChange
   public method addNewRun
   public method collect
   private method addMissingTabs
   private method deleteExtraTabs
   private method updateNewRunCommand 
   
    private common s_object ""

    private variable _ready 0
   private variable m_clientState "offline"
   private variable m_runCount 0 
   private variable m_tabs 0
   private variable m_runLabel  
   private variable m_runStateColor  
    
   private variable m_deviceFactory

    constructor { args } {

      set m_deviceFactory [DCS::DeviceFactory::getObject]

      set ring $itk_interior
      
      # make a folder frame for holding runs
      itk_component add notebook {
         iwidgets::tabnotebook $ring.n \
               -tabpos e -gap 4 -angle 20 -width 330 -height 800 \
               -raiseselect 1 -bevelamount 4 -padx 5 \
      } {}

      #add the tab
      $itk_component(notebook) add -label " * "
         
      #pack the single runView widget into the first childsite 
      set childsite [$itk_component(notebook) childsite 0]
      pack $childsite
      #select the first tab to see the runView and then turn off the auto configuring
      $itk_component(notebook) select 0
      $itk_component(notebook) configure -auto off
      
      itk_component add runView {
         DCS::RunView $childsite.rv 
      } {}


      eval itk_initialize $args   
      
      
      #pack $itk_component(runView) -fill x
      pack $itk_component(runView)
      pack $itk_component(notebook) -side top -anchor n -pady 0 \
        -expand 1 -fill both


      for { set run 0 } { $run < [$itk_option(-runListDefinition) getMaxRunCount] } { incr run } {
         set m_runLabel($run) "X"
         set m_runStateColor($run) $ACTIVEBLUE 
         ::mediator register $this ::device::run$run state handleRunStateChange
         ::mediator register $this ::device::run$run runLabel handleRunLabelChange
      }

      #fill in the missing run tabs
      addMissingTabs [lindex [$itk_option(-runListDefinition) getContents] 0  ]

      #register for interest in the number of defined runs
      ::mediator register $this $itk_option(-runListDefinition) runCount handleRunCountChange 
    
      ::mediator register $this ::$itk_option(-controlSystem) clientState handleClientStatusChange   

      #allow observers to know what the embedded runViewer is looking at.
      exportSubComponent runDefinition ::$itk_component(runView) 

      announceExist

        if {$s_object == ""} {
            set s_object $this
        }
   }

    destructor {
    }
}


body DCS::RunListView::addNewRun {} {
    if { $m_clientState != "active"} return
    $itk_option(-runListDefinition) addNewRun

    #foreach {runNumber runLabel} \
    #[$itk_option(-runListDefinition) addNewRun] break
    #puts "$runNumber $runLabel" 

    #if {$runNumber != -1 } {
        #store what we expect will be the next label.
    #    incr runNumber
    #    set m_runLabel($runNumber) $runLabel 
    #}

}

body DCS::RunListView::deleteExtraTabs { systemRunCount_ } {
   set maxCount     [$itk_option(-runListDefinition) getMaxRunCount]
    puts "delete: count: $m_tabs max: $maxCount"

   #while deleting tabs don't select the last tab, which is the *.
   set currentSelection [$itk_component(notebook) index select]


   if {$m_tabs <= [expr $systemRunCount_ + 1]} return

   for {set tab $m_tabs} { $tab > [expr $systemRunCount_ + 1] } {incr tab -1} {
      if {$tab < $maxCount} {
         $itk_component(notebook) delete [expr $tab - 1]
      }
   }

   
   puts "$currentSelection , $m_tabs"


   set m_tabs $tab
   set m_runCount $systemRunCount_

   if { $currentSelection >= $m_tabs } {
      $itk_component(notebook) select [expr $m_tabs - 1]
   }

   updateNewRunCommand
}

body DCS::RunListView::addMissingTabs { systemRunCount_ } {
   set maxCount     [$itk_option(-runListDefinition) getMaxRunCount]
   incr maxCount -1
    puts "add: count: $m_tabs max: $maxCount"

   if { $m_tabs > $systemRunCount_ } return
   
   for { set tab $m_tabs } { $tab <= $systemRunCount_ } {incr tab} {
      if {$tab < $maxCount} {
         $itk_component(notebook) insert $tab 
      }
      $itk_component(notebook) pageconfigure $tab \
         -state normal \
         -command "$itk_component(runView) configure -runDefinition ::device::run$tab" \
         -label $m_runLabel($tab) \
         -foreground $m_runStateColor($tab) -selectforeground $m_runStateColor($tab)
   }
   
   set m_tabs $tab
   set m_runCount $systemRunCount_

   set current [$itk_component(notebook) index select]
   set desired [expr $m_tabs - 1]
   if {$current != $desired} {
      $itk_component(notebook) select [expr $m_tabs - 1]
   } else {
      $itk_component(runView) configure -runDefinition ::device::run$current
   }

   updateNewRunCommand
}

body DCS::RunListView::handleClientStatusChange { control_ targetReady_ alias_ clientStatus_ -  } {
   if { !$targetReady_ } return

   set maxCount     [$itk_option(-runListDefinition) getMaxRunCount]
   puts "client status change count: $m_tabs max: $maxCount"


   if {$clientStatus_ != "active" && $m_tabs < $maxCount} {
      $itk_component(notebook) pageconfigure end -state disabled
   } else {
      $itk_component(notebook) pageconfigure end -state normal 
   }

   set m_clientState $clientStatus_
}

body DCS::RunListView::handleRunCountChange { run_ targetReady_ alias_ systemRunCount_ -  } {
   if { !$targetReady_ } return

   #puts "RunListView::handleRunCountChange: $systemRunCount_"
   
   deleteExtraTabs $systemRunCount_
   addMissingTabs $systemRunCount_

   #$itk_component(notebook) select $systemRunCount_
}

body DCS::RunListView::handleRunLabelChange { run_ targetReady_ alias_ runLabel_ -  } {
   if { !$targetReady_ } return
  
   set run [$run_ getRunIndex]

   #puts "Setting $run label to $runLabel_"
   set m_runLabel($run) $runLabel_
 
   if { $run > $m_runCount } {
      return
   }

   $itk_component(notebook) pageconfigure $run -label $runLabel_
}


body DCS::RunListView::updateNewRunCommand {} {
   set maxCount     [$itk_option(-runListDefinition) getMaxRunCount]

    puts "update: count: $m_tabs max: $maxCount"

   if {$m_tabs < $maxCount} {
      #configure the 'add run' star
      $itk_component(notebook) pageconfigure end \
      -label " * " \
      -command [list $this addNewRun ] 

      if {$m_clientState != "active"} {
         $itk_component(notebook) pageconfigure end -state disabled
      }
   }
}

body DCS::RunListView::collect {} {

   #puts COLLECT

    global env

    #focus .

    # set currently selected run as current run
    set currentRun [$itk_component(notebook) index select]
    if { $currentRun < 1 } {
        set currentRun 0
    }

    # if doing snapshot set end frame to next frame
    set user [$itk_option(-controlSystem) getUser]
    global gEncryptSID
    if {$gEncryptSID} {
        set SID SID
    } else {
        set SID PRIVATE[$itk_option(-controlSystem) getSessionId]
    }
    
    if { ($currentRun == 0)} {
      set collectOperation [$m_deviceFactory createOperation collectRun]
        $collectOperation startOperation 0 $user [$itk_component(runView) getReuseDarkSelection] $SID
    } else {
      set collectOperation [$m_deviceFactory createOperation collectRuns]
        # send the start message to the server
        $collectOperation startOperation $currentRun $SID
    }

}



#Updates the colors of the run tabs based on the status of the run.
body DCS::RunListView::handleRunStateChange { run_ targetReady_ alias_ runState_ -  } {
   if { !$targetReady_ } return

   set run [$run_ getRunIndex]
  
    #pick the color based on the status of the run
   switch $runState_ {
        paused { set color $BROWNRED }
        collecting {set color red }
        inactive {set color $ACTIVEBLUE }
        complete {
            #Always force the first run to be the same color.
            if {$run != 0 } {
                set color $DARK
            } else {
                set color black
            }
        }
      default { set color red }
   }
   
   set m_runStateColor($run) $color

    #return if the run is not defined
   if { $run > $m_runCount } return

   #configure the tab's color
   $itk_component(notebook) pageconfigure $run \
         -foreground $color -selectforeground $color
}


class DCS::CollectView {
     inherit ::itk::Widget

    itk_option define -controlSystem controlSystem ControlSystem "::dcss"

    private variable m_deviceFactory
    private variable m_strCenterCrystalConst
    private variable m_strUserAlignBeamStatus
    private variable m_strRobotStatus
    private variable m_opCenterCrystal
    private variable m_opUserAlignBeam
    private variable m_centerCrystalEnabled 0
    private variable m_centerMicroCrystalEnabled 0
    private variable m_showCenterMicro 0

    public method handleUserAlignBeam { } {
        $m_opUserAlignBeam startOperation forced
    }

    public method centerCrystal { use_collimator } {
        set user [$itk_option(-controlSystem) getUser]
        global gEncryptSID
        if {$gEncryptSID} {
            set SID SID
        } else {
            set SID PRIVATE[$itk_option(-controlSystem) getSessionId]
        }
        set dir  /data/$user/centerCrystal
        set fileRoot [::config getConfigRootName]

        if {$use_collimator} {
            $m_opCenterCrystal startOperation $user $SID $dir $fileRoot \
            use_collimator_constant
        } else {
            $m_opCenterCrystal startOperation $user $SID $dir $fileRoot
        }
    }
    public method handleCrystalEnabledEvent { stringName_ ready_ alias_ contents_ - } {
        if {!$ready_} return

        if {$contents_ == ""} {
            set contents_ 0
        }
        if {$m_centerCrystalEnabled == $contents_} return
        set m_centerCrystalEnabled $contents_

        #puts "center enabled: $m_centerCrystalEnabled"

        if {$m_centerCrystalEnabled} {
            grid $itk_component(crystal)       -row 4 -column 0
        } else {
            grid forget $itk_component(crystal)
        }
    }
    
    public method handleMicroCrystalEnabledEvent { stringName_ ready_ alias_ contents_ - } {
        if {!$ready_} return

        if {$contents_ == ""} {
            set contents_ 0
        }
        if {$m_centerMicroCrystalEnabled == $contents_} return
        set m_centerMicroCrystalEnabled $contents_

        #puts "center enabled: $m_centerCrystalEnabled"

        if {$m_centerMicroCrystalEnabled} {
            if {$m_showCenterMicro} {
                grid $itk_component(micro_crystal) -row 5 -column 0
            }
        } else {
            grid forget $itk_component(micro_crystal)
        }
    }
    
    constructor { args } {
        global gMotorPhi
        global gMotorOmega
        global gMotorDistance
     
        set m_deviceFactory [DCS::DeviceFactory::getObject]

        set m_strUserAlignBeamStatus \
        [$m_deviceFactory createUserAlignBeamStatusString \
        user_align_beam_status]

        set m_strRobotStatus \
        [$m_deviceFactory createString robot_status]

      set ring $itk_interior 

      itk_component add runView {
         DCS::RunListView $ring.rv
      } {}

      itk_component add control {
         DCS::CollectControl $ring.cc
       } {}
      itk_component add positionFrame {
         ::iwidgets::labeledframe $itk_interior.lf -labeltext "Current Position"
      } {}

      set pos [$itk_component(positionFrame) childsite]

      itk_component add Phi {
         DCS::MotorView $pos.phi -promptText "Phi: " -promptWidth 9 -positionWidth 8 -decimalPlaces 2
       } {}

        $itk_component(Phi) configure -device ::device::$gMotorPhi

      itk_component add Omega {
         DCS::MotorView $pos.o -promptText "Omega: " -promptWidth 9 -positionWidth 8 -decimalPlaces 2
       } {}

        $itk_component(Omega) configure -device ::device::$gMotorOmega


      itk_component add distance {
         DCS::MotorView $pos.dist -promptText "Distance: " -promptWidth 9 -positionWidth 8 -decimalPlaces 2
       } {}

        $itk_component(distance) configure -device ::device::$gMotorDistance
      pack $itk_component(Phi)
#yang      pack $itk_component(Omega)
      pack $itk_component(distance)

        itk_component add optimize {
            OptimizeButton $ring.optimize \
             -text "Optimize Beam" \
             -width 10
        } {
        }

        itk_component add userAlignBeam {
            DCS::Button $ring.uab \
            -command "$this handleUserAlignBeam" \
            -text "Optimize Beam" \
            -width 10
        } {
        }
        $itk_component(userAlignBeam) addInput \
        "$m_strUserAlignBeamStatus anyEnabled 1 {Opmization Disabled}"
        $itk_component(userAlignBeam) addInput \
        "$m_strRobotStatus OKToAlignBeam 1 {Dismount First}"
        $itk_component(userAlignBeam) addInput \
        "$m_strRobotStatus status_num 0 {Robot Not Ready}"


        itk_component add collimator {
		    CollimatorDropdown $ring.collimator
        } {
        }

        itk_component add crystal {
            ::DCS::Button $ring.crystal \
                 -text "Center Crystal" \
                 -width 15
        } {
        }

        itk_component add micro_crystal {
            ::DCS::Button $ring.micro_crystal \
                 -text "Center MicroCrystal" \
                 -width 15
        } {
        }

      itk_component add doseControl {
         DCS::DoseControlView $ring.doseControl
       } {}

      itk_component add preview {
         DCS::RunSequenceView $ring.rp -runViewWidget $itk_component(runView) 
       } {}

      eval itk_initialize $args

      $itk_component(control) configure -command [list $itk_component(runView) collect]

        set m_opUserAlignBeam  [$m_deviceFactory createOperation userAlignBeam]
        set m_opCenterCrystal  [$m_deviceFactory getObjectName centerCrystal]
        set m_strCenterCrystalConst [$m_deviceFactory createString center_crystal_const]
        $m_strCenterCrystalConst createAttributeFromField system_on 0
        $m_strCenterCrystalConst register $this system_on handleCrystalEnabledEvent

        set objCenterMicroCrystalConst [$m_deviceFactory createString collimator_center_crystal_const]
        $objCenterMicroCrystalConst createAttributeFromField system_on 0
        $objCenterMicroCrystalConst register $this system_on handleMicroCrystalEnabledEvent

        set cfgShowCollimator [::config getInt bluice.showCollimator 1]
        if {$cfgShowCollimator \
        && [$m_deviceFactory motorExists collimator_horz]} {
            set m_showCenterMicro 1
        }
        $itk_component(crystal) configure -command "$this centerCrystal 0"
        $itk_component(micro_crystal) configure -command "$this centerCrystal 1"
      grid rowconfigure $ring 0 -weight 0
      grid rowconfigure $ring 1 -weight 0
      grid rowconfigure $ring 2 -weight 0
      grid rowconfigure $ring 3 -weight 0
      grid rowconfigure $ring 4 -weight 0
      grid rowconfigure $ring 5 -weight 0
      grid rowconfigure $ring 6 -weight 0
      grid rowconfigure $ring 7 -weight 5

        set showingCollimator 0
        if {$cfgShowCollimator \
        && [$m_deviceFactory motorExists collimator_horz]} {
            set showingCollimator 1
            grid $itk_component(collimator) -row 0 -column 0 -sticky n
        }
      grid $itk_component(control)        -row 1 -column 0 -sticky n
      grid $itk_component(positionFrame)  -row 2  -column 0 -sticky ew
        if {!$showingCollimator} {
            if { [$m_deviceFactory motorExists optimized_energy]} {
                grid $itk_component(optimize) -row 3 -column 0 -sticky n
            }
        } else {
                grid $itk_component(userAlignBeam) -row 3 -column 0 -sticky n
        }
      grid $itk_component(doseControl)    -row 4 -column 0 -sticky ew
      if {$m_centerCrystalEnabled} {
        grid $itk_component(crystal)       -row 5 -column 0 -sticky n
      }
      if {$m_centerMicroCrystalEnabled} {
        if {$m_showCenterMicro} {
            grid $itk_component(micro_crystal) -row 6 -column 0 -sticky n
        }
      }
      grid $itk_component(preview) -row 7 -column 0 -rowspan 2 -sticky news

      grid $itk_component(runView) -row 0 -column 1 -rowspan 8 -sticky new
      grid columnconfigure $ring 1 -weight 5
   }
    destructor {
        $m_strCenterCrystalConst unregister $this system_on handleCrystalEnabledEvent
        set objCenterMicroCrystalConst [$m_deviceFactory createString collimator_center_crystal_const]
        $objCenterMicroCrystalConst unregister $this system_on handleMicroCrystalEnabledEvent
    }
}


class DCS::CollectControl {
     inherit ::itk::Widget
    
    itk_option define -controlSystem controlSystem ControlSystem "::dcss"

    private variable m_deviceFactory

    public method openWebIceStrategy { } {
        set SID [$itk_option(-controlSystem) getSessionId]
        set user [$itk_option(-controlSystem) getUser]
        set beamline [::config getConfigRootName]
        set url [::config getCollectStrategyNewRunUrl]

        if {[string first ? $url] >= 0 } {
            append url "&SMBSessionID=$SID"
        } else {
            append url "?SMBSessionID=$SID"
        }
        append url "&userName=$user"
        append url "&beamline=$beamline"

        puts "newRun url: $url"

        if {[catch "openWebWithBrowser $url" result]} {
            log_error "open webice failed: $result"
        } else {
            $itk_component(strategyNewRun) configure -state disabled
            after 10000 [list $itk_component(strategyNewRun) configure -state normal]
        }
    }

    constructor { args } {
    global gMotorPhi
    global gMotorEnergy

    set m_deviceFactory [DCS::DeviceFactory::getObject]

    set ring $itk_interior

    ##### here we use individaul checkbox so that
    ##### we can hide or show them individually according to
    ##### to string collect_config
    itk_component add config {
        DCS::Checkbox $ring.config \
        -stringName collect_config
    } {
    }

    itk_component add strategyNewRun {
        button $ring.newRun -text "WebIce Strategy" -width 15 \
        -foreground blue \
	-state disabled \
        -command "$this openWebIceStrategy"
    } {
    }

    itk_component add collect {
       # make the data collection button
        DCS::Button $ring.start -text "Collect" -width 15
    } {
       keep -command
    }

    itk_component add stop {
       DCS::Button $ring.stop -text "Pause" -width 15 -systemIdleOnly 0
    } {}
 
    # create the stop button
    itk_component add abort {
        ::DCS::Button $ring.abort \
         -text "Abort" \
         -background \#ffaaaa \
         -activebackground \#ffaaaa \
         -activeClientOnly 0 -width 15 -systemIdleOnly 0
    } {
        keep -font -height -state
        keep -activeforeground -foreground -relief 
    }

    eval itk_initialize $args

    #bind the abort command
    $itk_component(abort) configure -command "$itk_option(-controlSystem) abort"

    set pauseOperation [$m_deviceFactory createOperation pauseDataCollection]
    $itk_component(stop) configure -command [list $pauseOperation startOperation] 


    set object [$m_deviceFactory createString collect_msg]
    $object createAttributeFromField runStatus 0

    ### we use string to lock, not operation status because a BluIice
    ### may start while the operation is already running.
    ### that will miss the operation started message
    ### and not lock up the component.

    $itk_component(collect) addInput "::device::collectRuns permission GRANTED {PERMISSION}"
    $itk_component(collect) addInput "::device::detector_reset_run status inactive {supporting device}"
    $itk_component(collect) addInput [list $object runStatus 0 "Data collection is active."]
    $itk_component(collect) addInput "::device::$gMotorEnergy status inactive {supporting device}"
    $itk_component(collect) addInput "::device::$gMotorPhi status inactive {supporting device}"
    ## auto fix in dcss
    #$itk_component(collect) addInput "::device::run0 dirOK 1 {set directory first}"
    $itk_component(stop) addInput [list $object runStatus 1 "Data collection is inactive."]

    pack $itk_component(strategyNewRun)
    pack $itk_component(collect)
    pack $itk_component(stop)
    pack $itk_component(abort)

}

    destructor {
    }
}