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

package require DCSRunSequenceCalculator
package require DCSImperson

source $OPERATION_DIR/collect_procedures.tcl

global gSingleRunCalculator
if { ![info exists gSingleRunCalculator] } {
    ::DCS::RunSequenceCalculator gSingleRunCalculator
}

#for now, depend on collectRun instantiating the run Calculator
#::DCS::RunSequenceCalculator gSingleRunCalculator

proc collectRun_initialize {} {
	# global variables 
    global gCurrentRunNumber
    set gCurrentRunNumber -1
}
proc collectRun_cleanup {} {
    variable collect_msg
    set collect_msg [lreplace $collect_msg 0 0 0]
}

proc collectRun_start { runNumber userName reuseDark sessionID args } {
    fix_run_directory $runNumber $userName

    if {$runNumber == 0 } {
        eval collectRunWithShutter $runNumber $userName $reuseDark $sessionID $args
        return
    }

	# global variables 
	global gPauseDataCollection
    global gWaitForGoodBeamMsg
    global gSingleRunCalculator
    global gCurrentRunNumber
    global gMotorBeamWidth
    global gMotorBeamHeight
    global gMotorBeamStop
    global gDevice
    
    global gMotorEnergy
    global gMotorDistance
    global gMotorVert
    global gMotorHorz
    global gMotorPhi
    global gMotorOmega
	
	variable $gMotorDistance
	variable $gMotorPhi
	variable $gMotorOmega
	variable $gMotorEnergy
	variable $gMotorVert
	variable $gMotorHorz

    variable detectorStatus
    variable runs
    variable collect_msg
    variable beamlineID
    variable attenuation

    set flagSaveSystemSnapshotForEachRun 1
    set flagSaveSystemSnapshotForEachFrame 0

    if [catch {block_all_motors;unblock_all_motors} errMsg] {
        log_error $errMsg
        puts "MUST wait all motors stop moving to start collecting"
        log_error "MUST wait all motors stop moving to start collecting"
        return -code error "MUST wait all motors stop moving to start"
    }

    if {$sessionID == "SID"} {
        set sessionID PRIVATE[get_operation_SID]
        puts "use operation SID: [SIDFilter $sessionID]"
    }

    set gCurrentRunNumber $runNumber

    ####check and clear all run status
    #checkRunStatus -1
    ####check and clear all run status skip this runNumber
    checkRunStatus $runNumber

    set origAttenuation $attenuation
    puts "orig attenuation $origAttenuation"


    set runName [lindex $args 0]
    set selectedStop [lindex $args 1]
    set selectedMadScan [lindex $args 2]

    puts "populate the calculator"
    variable run$runNumber
    puts "rundef: [set run$runNumber]"
    gSingleRunCalculator updateRunDefinition [set run$runNumber]
    puts "after populate"


    set needUserLog 0
    if {![checkForRun $runNumber $userName $sessionID needUserLog]} {
        ### just to make sure
        set collect_msg [lreplace $collect_msg 0 0 0]
        return $runNumber
    }
    puts "after checkForRun"

    if {$needUserLog} {
        ### not called by collectRuns, but directy by BluIce
        correctPreCheckMotors
    }

    clearMessageForRun
    set collect_msg [lreplace $collect_msg 0 6 \
    1 Starting 0 $beamlineID $userName $runName $runNumber]

    if { $runNumber != 0 } {
        puts "prepareForRun"
        if {![prepareForRun $runNumber $userName $sessionID $runName \
        $selectedStop $selectedMadScan]} {
		    update_run $runNumber "" "inactive"
            if {$needUserLog} {
                user_log_error collecting [lindex $collect_msg 1]
                user_log_note collecting "=======end collectRun $runNumber====="
            } else {
                log_warning skip run$runNumber
            }
	        return $runNumber
        }
        if {$selectedStop == "1"} {
            log_warning prepareForRun fill only, no real collection
		    update_run $runNumber "" "inactive"
            set collect_msg [lreplace $collect_msg 0 1 0 completed]
            if {$needUserLog} {
                user_log_note collecting "=======end collectRun $runNumber========"
            }
	        return $runNumber
        }
    }

    moveMotorsForRun $runNumber

	#get all the data that is stored in this class, so
    #we can update the run later when the frame changes.
    foreach { \
	directory       \
	exposureTime    \
	axisMotorName   \
    attenuationSetting \
	modeIndex       \
	nextFrame       \
	runLabel        \
	delta           \
	startAngle      \
	endAngle        \
	startFrameLabel \
	fileroot        \
	wedgeSize       \
	inverseOn       \
    } [gSingleRunCalculator getList \
	directory       \
	exposure_time   \
	axis_motor      \
    attenuation     \
	detector_mode   \
	next_frame      \
	run_label        \
	delta           \
	start_angle      \
	end_angle        \
	start_frame \
	file_root        \
	wedge_size       \
	inverse_on       \
    ] break

    ##### decode the axis motor names here
    switch -exact -- $axisMotorName {
        Omega {
            set axisMotor $gMotorOmega
        }
        default {
            set axisMotor $gMotorPhi
        }
    }
    puts "axisMotor: $axisMotor"

	set useDose [lindex $runs 2]

	set energyList [gSingleRunCalculator getEnergies]
    puts "e list; $energyList"
	#find out how many frames are in this run
	set totalFrames [gSingleRunCalculator getTotalFrames]

    if {$runNumber == 0} {
		set nextFrame 0
		set totalFrames 1
    }

    puts "total frames: $totalFrames"
		

	#inform the guis that we are collecting
	update_run $runNumber $nextFrame "collecting"

    ########################### user log ##################
    if {$needUserLog} {
        user_log_note collecting "======$userName start collectShutterless $runNumber======"
    } else {
        user_log_note collecting "=========run $runNumber========"
    }

    set fileExt [getDetectorFileExt $modeIndex]

    ### this way, collect_msg will be set by wait_for_good_beam and
    ### requestExposureTime which also call wait_for_good_beam inside
    set gWaitForGoodBeamMsg [list collect_msg 1]

    set collect_msg [lreplace $collect_msg 0 2 \
    1 {collecting} 6]

	#loop over all remaining frames until this run is complete
	if { [catch {
		while { $nextFrame < $totalFrames } {

			if { $gPauseDataCollection } {
                abort
            }

			#get the motor positions for this frame
			set thisFrame \
            [gSingleRunCalculator getMotorPositionsAtIndex $nextFrame]
			#extract the motor positions from the result
			set filename [lindex $thisFrame 0]
			set phiPosition [lindex $thisFrame 1]
			set energyPosition [lindex $thisFrame 2]
			set fileNameNoIndex [lindex $thisFrame 3]
			set frameLabel [lindex $thisFrame 4]
			set numImages [lindex $thisFrame 5]
            if {$runNumber == 0} {
		        set numImages 1
            }
            set sub_dir   [lindex $thisFrame 6]

            #set directoryNew [file join $directory $sub_dir]
            set directoryNew $directory

            set maxImagesOnDisk [lindex $detectorStatus [expr [lsearch $detectorStatus FREE_IMAGE_SPACE] +1]]
            if {$maxImagesOnDisk < $numImages } {
                #don't ask for more images than can fit on the pilatus ram disk
                set numImages $maxImagesOnDisk
            }

			move $axisMotor to $phiPosition
			move $gMotorEnergy to $energyPosition
			
			wait_for_devices \
            $axisMotor \
            $gMotorEnergy \
			$gMotorDistance \
			$gMotorBeamStop

            move attenuation to $attenuationSetting
            wait_for_devices attenuation
            
            set needSaveSystemSnapshot 0

            ### this will also write out user_log, so do not merge with other
            ### conditions.
            if {[user_log_system_status collecting]} {
                set needSaveSystemSnapshot 1
            }
            if {$flagSaveSystemSnapshotForEachFrame} {
                set needSaveSystemSnapshot 1
            }
            if {$flagSaveSystemSnapshotForEachRun} {
                set flagSaveSystemSnapshotForEachRun 0
                set needSaveSystemSnapshot 1
            }

            if {$needSaveSystemSnapshot} {
                set snapshotPath [file join $directoryNew $filename.txt]
                saveSystemSnapshot $userName $sessionID $snapshotPath
            }


	        ###set wavelength [expr 12398.0 / $energy ]
            set eu $gDevice($gMotorEnergy,scaledUnits)
            log_note $gMotorEnergy units $eu

            if {$eu != "eV" && $eu != "keV" && $eu != "A"} {
                log_error $gMotorEnergy has wrong units: $eu
                return -code error "energy has wrong units: $eu"
            }
    
	        set wavelength [::units convertUnits [set $gMotorEnergy] $gDevice($gMotorEnergy,scaledUnits) A]

			
            variable detector_z
            variable detector_horz
            variable detector_vert
            variable energy

            set numCollected 0
            set startFrame $nextFrame
            set endFrame [expr $startFrame + $numImages - 1]

            set displayStart [expr $startFrame + 1]
            set displayEnd   [expr $endFrame + 1]
            if {$displayStart == $displayEnd} {
                set collect_msg [lreplace $collect_msg 0 1 1 \
                "collecting run $runNumber frames $displayStart of $totalFrames"]
            } else {
                set collect_msg [lreplace $collect_msg 0 1 1 \
                "collecting run $runNumber frames $displayStart - $displayEnd of $totalFrames"]
            }

            set calcExposureTime [requestExposureTime_start $exposureTime $useDose]
		    set operationHandle [start_waitable_operation detectorCollectShutterless \
										$runNumber \
										$fileNameNoIndex \
										$directoryNew \
										$userName \
										$axisMotor \
										$calcExposureTime \
										$phiPosition \
										$delta \
										[set $gMotorDistance] \
										$wavelength \
										[set $gMotorHorz] \
										[set $gMotorVert] \
										0 \
										0 \
                                        $sessionID \
                                        $numImages \
                                        $frameLabel ]

		    set status "update"
		    #loop over all intermediate messages from the detector
		    while { $status == "update" } {
			    set result [wait_for_operation $operationHandle]
			
			    set status [lindex $result 0]
			    set result [lindex $result 1]
			    if { $status == "update" } {
				    set request [lindex $result 0]
				    puts $request
				    if { $request == "start_oscillation" } {
					
                        set detector_status "Exposing [lindex $result 3]..."
			
                        # start an oscillation
			            start_oscillation gonio_phi shutter [expr $delta * $numImages] [expr $calcExposureTime * $numImages]
					
				    }
				    if { $request == "exposed" } {
			            set imageNum [lindex $result 1]
                        if { $imageNum > $numCollected } {
                            set numCollected $imageNum
                            set nextFrame [expr $startFrame + $numCollected] 
		                    update_run $runNumber $nextFrame "complete"
                        }
                    }
			    }
		    }
			print "Wait for exposure"
			wait_for_devices gonio_phi
			print "Exposure Completed"
			#inform the detector that the exposure is done
			#start_operation detector_transfer_image
            #set detector_status "Reading Out Detector..."
            
		    set nextFrame [expr $startFrame + $numImages]
		    update_run $runNumber $nextFrame "complete"
		}

		if { $runNumber == 0 } {
			#add one to the start frame index	
			update_run $runNumber $nextFrame "complete" 1
		} else {
			update_run $runNumber $nextFrame "complete"
		}

		update_run $runNumber $nextFrame "complete"
		
	} errorResult ] } {
		#handle every error that could be raised during data collection
        set gWaitForGoodBeamMsg ""
		start_recovery_operation detector_stop
		update_run $runNumber $nextFrame "paused"
        set collect_msg [lreplace $collect_msg 0 1 0 $errorResult]

        abort

        if {$needUserLog} {
            user_log_error collecting "run$runNumber $errorResult"
            user_log_note collecting "=======end collectRun $runNumber========"
        }
        log_error collect failed for run$runNumber $errorResult

		return -code error $errorResult
	}

    set collect_msg [lreplace $collect_msg 0 1 0 "completed"]
	return $runNumber
}


