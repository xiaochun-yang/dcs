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
# SequenceDevice.tcl
#
# called by scripted operations
#  sequence.tcl
#  sequenceGetConfig.tcl
#  sequenceSetConfig.tcl
#
#
#
# config in database.dat:
#
# sequenceDeviceState
# 13
# self standardString
# gwolf 0 {undefined undefined undefined undefined}
#
# sequence
# 11
# self sequence 1
#
# sequenceSetConfig
# 11
# self sequenceSetConfig 1
#
# sequenceGetConfig
# 11
# self sequenceGetConfig 0
#
# Note, the operation sequenceGetConfig is defined as operation.masterOnly = 0,
# i.e. it can also be called in passive mode
#
#
# beamlineID
# 13
# self standardString
# 11-1
#
package require Itcl
package require http
package require DCSSpreadsheet
#

# =======================================================================

proc create_sequenceDevice { instanceName} {
    set dev [SequenceDevice $instanceName]
    return $dev
}

# =======================================================================

::itcl::class SequenceDevice {
    private common ADD_BEAM_INFO_TO_JPEG 1
    private common SAVE_DEBUG_SNAPSHOT 1
    private common DEBUG_SNAPSHOT_PHI [list 0 45 90 135 180 225 270 315]
    private common REORIENT_SNAPSHOT_ZOOM 1.0

    # action states that will be broadcasted
    private variable m_directory "/data/UserName"
    private variable m_actionListParameters "{mountNext {}} {Pause {}}"
    private variable m_actionListStates
    private variable m_nextAction 0
    private variable m_currentAction -1
    private variable m_detectorMode 0
    private variable m_distance 300.0
    private variable m_beamstop 40.0
    private variable m_attenuation 0.0
    private variable m_isRunning 0

# crystal states that will be broadcasted
private variable m_cassetteInfo "gwolf 0 {undefined undefined undefined undefined}"
private variable m_crystalListStates "1 1 1 1 1"
private variable m_nextCrystal 0
private variable m_currentCrystal -1
private variable m_mountingCrystal -1

# added for manual mode, to avoid changing screening selections
private variable m_manualMode 0
private variable m_currentCassette n
private variable m_currentColumn N
private variable m_currentRow 0
private variable m_currentBarcode ""

# state for robot configuration
private variable m_robotState 1
private variable m_useRobot 0

private variable m_reOrientSample 0
private variable m_sampleReOriented 0

# internal device states
private variable m_isInitialized 0
private variable m_keepRunning 0
private variable m_dismountRequested 0
private variable m_crystalPortList "A2 A3 A4 A5 A6"
private variable m_crystalIDList "c1 c2 c3 c4 c5"
private variable m_crystalDirList "null null null null null"
private variable m_reOrientableList "0 0 0 0 0"
private variable m_reOrientInfoList "{} {} {} {} {}"
private variable m_reOrientPhiList "{} {} {} {} {}"
private variable m_uniqueIDList "{} {} {} {} {}"
private variable m_gridSampleLocationList "{} {} {} {} {}"

##### if current cassette status change, we need to re-map the
### spreadsheet rows to position in robot_cassette
private variable m_currentCassetteStatus "u"
private variable m_indexMap {}

private variable a_fileCounterInfo
private variable m_phiZero 0
#
# the following parameters are defined in initBeamlineParameters
private variable m_crystalDataUrl
private variable m_beamlineName
private variable m_strategyDir

private variable m_fileReOrient
private variable m_channelReOrient ""
#
#
private variable m_isSyncedWithRobot no

#change this to 1 if you want to force sync with robot after mount next call
private variable TRY_SYNC_WITH_ROBOT 1

#skip all other actions is nothing is mounted
private variable m_skipThisSample 0

#lock next crystal
private variable m_lockNextCrystal 0

private variable m_lastSessionID ""
private variable m_lastUserName ""

private variable m_SILID -1
private variable m_SILEventID -1
private variable m_numRowParsed 0
    #this is a hardcoded header for old service
    private variable m_defaultHeader {
        {Port 4 readonly}
        {CrystalID 8 readonly}
        {Protein 8 readonly}
        {Comment 35}
        {Directory 22 readonly}
        {FreezingCond 12 readonly}
        {CrystalCond 72 readonly}
        {Metal 5 readonly}
        {Priority 8 readonly}
        {Person 8 readonly}
        {CrystalURL 25 readonly}
        {ProteinURL 25 readonly}
    }

    private variable m_currentHeader ""
    private variable m_currentHeaderNameOnly ""
    ##where are the Port and ID in the columns
    private variable m_PortIndex         -1
    private variable m_IDIndex           -1
    private variable m_DirectoryIndex    -1
    private variable m_SelectedIndex     -1
    private variable m_ReOrientableIndex -1
    private variable m_ReOrientInfoIndex -1
    private variable m_ReOrientPhiIndex  -1
    private variable m_UniqueIDIndex     -1
    private variable m_BarcodeScannedIndex -1
    private variable m_GridSampleLocationIndex -1

    ##to save jpeg images and send them to SIL server later with detector iamge
    private variable m_jpeg1 ""
    private variable m_jpeg2 ""
    private variable m_jpeg3 ""
    private variable m_img1 ""
    private variable m_img2 ""
    private variable m_img3 ""

    private variable m_info1 ""
    private variable m_info2 ""
    private variable m_info3 ""

    private variable m_jpeg_reorient_0 ""
    private variable m_jpeg_reorient_1 ""
    private variable m_jpeg_info_0 ""
    private variable m_jpeg_info_1 ""

    ######to convert img to jpg only for screening
    private variable m_imageWaitingList ""

    private variable m_imgFileExtension "img"

    ##if get spreadsheet failed, it will keep retrying until get it
    ##during that time, no screening will be allowed to run
    private variable m_spreadsheetStatus 0
    ##### 0: not initialized
    ##### 1: OK
    ##### <0: retrying

    private variable m_tsNextSevereMsg 0
    private variable m_cntSevereMsg 0
    ### send out sever message at 1, 2, 4, 8, 16, 32, 60, 60, 60 minutes
    private common INIT_SEVERE_MSG_INTERVAL 60
    private common MAX_SEVERE_MSG_INTERVAL 3600

    private variable m_afterID ""

    ############ to skip loop centering error or stop#######
    private variable m_numLoopCenteringError 0

    private variable m_motorForVideo [list \
    sample_x \
    sample_y \
    sample_z \
    gonio_phi \
    gonio_kappa \
    camera_zoom \
    ]

    ### will be overrided by config file
    private variable m_counterFormat "%04d"

    #### options from config
    private variable m_enableAddImage 0
    private variable m_enableAnalyzeImage 0
    private variable m_enableAutoindex 0
    private variable m_enableReOrient 0

    private variable m_reorient_info_array

    private common s_reorient_info_map

    private common s_position2reorient_map [list \
    [list fileVSnapshot1        REORIENT_VIDEO_FILENAME_0] \
    [list fileVSnapshot2        REORIENT_VIDEO_FILENAME_1] \
    [list fileVSnapshotBox1     REORIENT_BOX_FILENAME_0] \
    [list fileVSnapshotBox2     REORIENT_BOX_FILENAME_1] \
    [list fileDiffImage1        REORIENT_DIFF_FILENAME_0] \
    [list fileDiffImage2        REORIENT_DIFF_FILENAME_1] \
    [list beam_width            REORIENT_BEAM_WIDTH] \
    [list beam_height           REORIENT_BEAM_HEIGHT] \
    [list beamline              REORIENT_BEAMLINE] \
    [list energy                REORIENT_ENERGY] \
    [list distance              REORIENT_DISTANCE] \
    [list beam_stop             REORIENT_BEAM_STOP] \
    [list attenuation           REORIENT_ATTENUATION] \
    [list camera_zoom           REORIENT_CAMERA_ZOOM] \
    [list scaling_factory       REORIENT_SCALE_FACTOR] \
    [list delta                 REORIENT_DIFF_DELTA_0] \
    [list exposure_time         REORIENT_DIFF_EXPOSURE_TIME_0] \
    [list detector_mode         REORIENT_DIFF_MODE_0] \
    [list flux                  REORIENT_DIFF_FLUX_0] \
    [list i2                    REORIENT_DIFF_ION_CHAMBER_0] \
    ]

private method refreshConfigOptions { } {
    variable ::nScripts::sil_config

    set m_enableAddImage 0
    set m_enableAnalyzeImage 0
    set m_enableAutoindex 0
    set m_enableReOrient 0

    if {[info exists sil_config]} {
        set add_image       [lindex $sil_config 0]
        set analyze_image   [lindex $sil_config 1]
        set autoindex       [lindex $sil_config 2]
        set reorient        [lindex $sil_config 3]

        if {$add_image == "1"} {
            set m_enableAddImage 1
        } 
        if {$analyze_image == "1"} {
            set m_enableAnalyzeImage 1
        }
        if {$autoindex == "1"} {
            set m_enableAutoindex 1
        }
        ### the old strategy is "1"
        ### will change here to "1" after all beamlins disabled on default
        if {$reorient == "2"} {
            set m_enableReOrient 1
        }
    }
}

private method clearImages { {newMount 1} } {
    set m_jpeg1 ""
    set m_jpeg2 ""
    set m_jpeg3 ""
    set m_img1 ""
    set m_img2 ""
    set m_img3 ""
    set m_info1 ""
    set m_info2 ""
    set m_info3 ""

    if {$newMount} {
        set m_jpeg_reorient_0 ""
        set m_jpeg_reorient_1 ""
        set m_jpeg_info_0 ""
        set m_jpeg_info_1 ""
    }
}

private proc angleSpan { angle } {
    while {$angle < 0.0} {
        set angle [expr $angle + 360.0]
    }
    while {$angle >= 360.0} {
        set angle [expr $angle - 360.0]
    }
    if {$angle > 180.0} {
        set angle [expr 360.0 - $angle]
    }
    return $angle
}
public proc getPortIndexInCassette { cassette row column } {}
public proc getPortStatus { cassette row column } {}

# public methods
public method operation { args } {}
public method setConfig { args } {}
public method getConfig { args } {}
public method syncWithRobot { { try_sync 0 } args } {}
public method reset { args } { }

public method constructor

####for manual mode: single action per operation
public method manual_operation { op args }

public method portJamUserAction { args }

public method onNewMaster { user clientId } {
    if {$m_isInitialized != 0} {
        ###ignore
        return
    }
    set m_lastUserName $user
    set m_lastSessionID [get_user_session_id $clientId]
    log_warning using user $user to init screening
    initialization
}

public method retryLoadingSpreadsheet { } {
    log_warning retrying load spreadsheet
    set m_afterID ""

    updateCassetteInfo
}

# private methods
private method initialization {} {}
private method checkInitialization {} {}
private method initBeamlineParameters {} {}
private method initActionStates {} {}
private method loadStateFromDatabaseString {} {}
private method saveStateToDatabaseString {} {}
private method stop { args } {}
private method dismount { args } {}
private method run {} {}
private method run_internal {} {}
private method runAction { index } {}
private method spinMsgLoop {} {}
private method sleep { msec } {}
private method getNextAction { current } {}
private method getNextCrystal { current } {}
private method getCrystalName {} {}
private method getCrystalNameForLog {} {}
private method getImgFileName { nameTag fileCounter } {}
private method getImgFileExt { }
private method getFileCounter { subdir fileExtension } {}
private method createDirectory { subdir } {}
private method loadCrystalList { } {}
private method refreshWholeSpreadsheet { data }
private method updateRows { data }
private method parseOneRow { contents }

private method clearMounted { args } {}
private method updateAfterDismount { }

private method setPhiZero {} {}

private method checkActionSelection { value }

#update the strings
private method updateCrystalSelectionListString
private method updateScreeningActionListString
private method updateScreeningParametersString
private method updateCrystalStatusString

private method loadCrystalSelectionListString
private method loadCrystalStatusString
#
# these functions call the hardware
# added for manual mode, doMountNextCrystall will also call this method
private method mountCrystal { cassette column row wash_cycle } {}

private method doManualMountCrystal { args } {}

private method doMountNextCrystal { {num_cycle_to_wash 0} } {}
private method doDismount {} {}
private method doPause {} {}
private method doOptimizeTable {} {}
private method doLoopAlignment { } {}
private method doReOrient { } {}
private method doVideoSnapshot { zoom nameTag} {}
private method doCollectImage { deltaPhi time nImages nameTag} {}
private method doExcitation
private method doRotate { angle } {}
private method checkIfRobotResetIsRequired {} {}
#
private method sendResultUpdate { operation subdir fileName } {}

private method saveRawSnapshot { path }
private method saveBoxSnapshot { pathBox {pathRaw ""}}
private method checkFirstSnapshotForReOrient { } {}
private method checkSecondSnapshotForReOrient { } {}
private method doubleCheckSnapshotForReOrient { } {}

private method saveReOrientInfo { dir a1 a2 s1 s2 }
private method readReOrientInfo { }
private method fillDefaultRunForAdjust { }
private method generateDefaultPositionData { reorient_info_contents }
private method warningDiffForReOrient { }
private method setupForReOrient { }
private method saveDebugSnapshots { dir prefix }
private method reorientPhi { dir }
private method reorientXYZ { dir }
private method runMatchup { snapshot1 snapshot2 }
private method take2ImageForReOrient { dir }
private method waitForPhiCalculation { }
private method logReOrientResult { success contents }

#sync with robot
private method getCrystalStatus { index } {}
private method getCrystalIndex { row column } {}

private method actionSelectionOK {} {}
private method crystalSelectionOK {} {}
private method checkCrystalList { varName } {}
private method listIsUnique { list_to_check }
private method actionParametersOK { varName fixIt }
private method getCurrentPortID { }
private method getNextPortID { }
private method getCurrentRawPort { }
private method getNextRawPort { }

private method drawInfoOnVideoSnapshot

private method updateCassetteInfo { }

#it will check if at least 2 images are available and
#the angle is more than 5 degrees.
private method doAutoindex { }

### get from config and unique
private method getStrategyFileName { }
### this set is to set the file field of the string "strategy_field"
private method setStrategyFileName { full_path {runName ""} }

public method handleSpreadsheetUpdateEvent { args }

#####the roadmap is using more strings
public method handlePortStatusChangeEvent { args }

#### call image convert to create thumbnail
public method handleLastImageChangeEvent { args }

public method handleCassetteListChangeEvent { args }

public method takeSnapshotWithBeamBox { pathBox user SID } {
    set mySID $SID
    if {[string equal -length 7 $mySID "PRIVATE"]} {
        set mySID [string range $mySID 7 end]
    }

    set urlSOURCE [::config getSnapshotUrl]

    set urlTarget "http://[::config getImpDhsImpHost]"
    append urlTarget ":[::config getImpDhsImpPort]"
    append urlTarget "/writeFile?impUser=$user"
    append urlTarget "&impSessionID=$mySID"
    append urlTarget "&impWriteBinary=true"
    append urlTarget "&impBackupExist=true"
    append urlTarget "&impAppend=false"

    set urlTargetBox $urlTarget
    append urlTargetBox "&impFilePath=$pathBox"
    set cmd "java -Djava.awt.headless=true url $urlSOURCE [drawInfoOnVideoSnapshot] -o $urlTargetBox"

    #log_note cmd: $cmd
    set mm [eval exec $cmd]
    puts "saveRawAndBox result: $mm"
}

private method checkCassettePermit { cassette }

private method moveMotorsToDesiredPosition { } {
    global gMotorDistance
    global gMotorBeamStop
    variable ::nScripts::screeningParameters

    if {[llength $screeningParameters] >= 5} {
        move $gMotorDistance to $m_distance
        move $gMotorBeamStop to $m_beamstop
        move attenuation to $m_attenuation
        wait_for_devices $gMotorBeamStop $gMotorDistance attenuation
    }
}

private method waitForMotorsForVideo { }
private method waitForMotorsForCollect { }

private method getSubDirectory { } {
    if {!$m_manualMode} {
        set subdir [lindex $m_crystalDirList $m_currentCrystal]
    } else {
        set subdir .
    }
    return $subdir
}
private method getDirectory { } {
    set subdir [getSubDirectory]
    set dir [file join $m_directory $subdir]
    return $dir
}

private method updateBarcodeScanned { barcode } {
    puts "updateBarcode: $barcode"

    if {$barcode == ""} {
        ###DEBUG: later we should update empty too
        puts "empty barcode"
        return
    }

    if {$m_BarcodeScannedIndex < 0} {
        puts "no BarcodeScanned field found"
        return
    }

    if {$m_currentCrystal < 0} {
        puts "no current crystal"
        return
    }
    if {![string is integer -strict $m_SILID]} {
        puts "no sil"
        return
    }
    if {[catch {
        regsub -all {[[:blank:]]} $barcode _ barcode
        set data [list BarcodeScanned $barcode]
        set data [eval http::formatQuery $data]

        set uniqueID [lindex $m_uniqueIDList $m_currentCrystal]

        puts "updating the SIL field"

        editSpreadsheet $m_lastUserName $m_lastSessionID \
        $m_SILID $m_currentCrystal $data $uniqueID
    } errmsg]} {
        log_error updateBarcode $errmsg
    }
}

}

# =======================================================================
# =======================================================================

::itcl::body SequenceDevice::constructor { args } {
    set m_counterFormat [::config getFrameCounterFormat]
    puts "counter format: $m_counterFormat"

    global gMotorEnergy
    global gMotorBeamWidth
    global gMotorBeamHeight
    global gMotorDistance
    global gMotorBeamStop
    ###              tag               device             restore_or_not
    set s_reorient_info_map [list \
        [list REORIENT_BEAMLINE         beamlineID           0] \
        [list REORIENT_DETECTOR         detectorType        0] \
        [list REORIENT_ENERGY           $gMotorEnergy       1] \
        [list REORIENT_BEAM_WIDTH       $gMotorBeamWidth    1] \
        [list REORIENT_BEAM_HEIGHT      $gMotorBeamHeight   1] \
        [list REORIENT_ATTENUATION      attenuation         1] \
        [list REORIENT_DISTANCE         $gMotorDistance     1] \
        [list REORIENT_BEAM_STOP        $gMotorBeamStop     1] \
        [list REORIENT_CAMERA_ZOOM      camera_zoom         1] \
        [list REORIENT_SCALE_FACTOR     sampleScaleFactor   0] \
    ]

    eval configure $args
set a_fileCounterInfo(jpg) 0
set a_fileCounterInfo(dir_jpg) 0
set a_fileCounterInfo(subdir_jpg) 0
set a_fileCounterInfo(crystalName_jpg) 0

set a_fileCounterInfo(img) 0
set a_fileCounterInfo(dir_img) 0
set a_fileCounterInfo(subdir_img) 0
set a_fileCounterInfo(crystalName_img) 0

set a_fileCounterInfo(bip) 0
set a_fileCounterInfo(dir_bip) 0
set a_fileCounterInfo(subdir_bip) 0
set a_fileCounterInfo(crystalName_bip) 0

set m_imgFileExtension [getImgFileExt]

registerEventListener sil_event_id [list $this handleSpreadsheetUpdateEvent]
registerEventListener robot_cassette [list $this handlePortStatusChangeEvent]
registerEventListener lastImageCollected [list $this handleLastImageChangeEvent]
registerEventListener cassette_list [list $this handleCassetteListChangeEvent]
registerMasterCallback [list $this onNewMaster]
}

# =======================================================================

::itcl::body SequenceDevice::operation { op args } {
variable ::nScripts::screening_msg
variable ::nScripts::auto_sample_msg
set auto_sample_msg ""
 
puts "SequenceDevice::operation $op $args"

set screening_msg ""

set m_lastUserName [get_operation_user]

set sessionID [lindex $args end]
if {$sessionID != ""} {
    if {$sessionID == "SID"} {
        set sessionID PRIVATE[get_operation_SID]
        puts "sequence use operation SID: [SIDFilter $sessionID]"
    }

    set m_lastSessionID $sessionID
    puts "operation sessionID [SIDFilter $m_lastSessionID]"

    variable ::nScripts::screening_user
    set screening_user $m_lastUserName
}

set m_manualMode 0

checkInitialization

### in fact, not need
checkCassettePermit $m_currentCassette

set m_reOrientSample 0

switch -exact -- $op {
    start {
        if {$m_spreadsheetStatus <= 0} {
            log_error cannot start before success of getting spreadsheet
            return -code error "cannot start before success of getting spreadsheet"
        }
        if {[llength $args] > 1} {
            set v [lindex $args 0]
            if {$v == "1"} {
                set m_reOrientSample 1
            }
        }
        set m_keepRunning 1
        run
    }
    dismount {
        ###only called internally by setConfig dismount
        #set m_dismountRequested 1
        #set m_keepRunning 0
        #run
        log_error should not be here anymore
    }
    clear_mounted {
        clearMounted
    }
    takeSnapshotWithBeamBox {
        eval takeSnapshotWithBeamBox $args
    }
    default {
        log_error "Screening unknown operation $op"
        return -code error "SequenceDevice::operation unknown operation $op"
    }
}
puts "SequenceDevice::operation OK"
::nScripts::cleanupAfterAll
return [list sequence $op OK]
}

# =======================================================================

::itcl::body SequenceDevice::setConfig { attribute value args } {
variable ::nScripts::screening_msg
variable ::nScripts::scn_crystal_msg
variable ::nScripts::scn_action_msg
variable ::nScripts::crystalStatus
puts "SequenceDevice::setConfig $attribute $value args: $args"

set screening_msg ""
set scn_crystal_msg ""
set scn_action_msg ""

####### if running, keep the starter's session id
if {!$m_isRunning} {
    set m_lastUserName [get_operation_user]
    set sessionID [lindex $args end]
    if {$sessionID != ""} {
        if {$sessionID == "SID"} {
            set sessionID PRIVATE[get_operation_SID]
            puts "sequence use operation SID: [SIDFilter $sessionID]"
        }

        set m_lastSessionID $sessionID
        puts "setConfig sessionID [SIDFilter $m_lastSessionID]"

        variable ::nScripts::screening_user
        set screening_user $m_lastUserName
    }
}

set m_manualMode 0

checkInitialization

if { $attribute=="stop" } {
    set result [list [stop $value $args]]
    return $result
}
if { $attribute=="dismount" } {
    set result [list [dismount $value $args]]
    return $result
}
if { $attribute=="currentCrystal" } {
    return -code error "SequenceDevice::setConfig m_currentCrystal is readonly"
}

##############################################################################
# put special cases here if they need to change or check input value       ###
##############################################################################
if { $attribute=="directory" || \
$attribute=="attenuation" || \
$attribute=="distance" || \
$attribute=="beamstop" } {
    if {$m_isRunning} {
        set screening_msg "error: $attribute is readonly during run"
        return -code error "SequenceDevice::setConfig $attribute is readonly during a run"
    }

    switch -exact -- $attribute {
        directory {
            set value [TrimStringForRootDirectoryName $value]
        }
        distance {
            global gMotorDistance
            adjustPositionToLimit $gMotorDistance value 1
        }
        beamstop {
            global gMotorBeamStop
            adjustPositionToLimit $gMotorBeamStop value 1
        }
        attenuation {
            variable ::nScripts::collect_default
            if {[llength $collect_default] >= 7} {
                set attDef [lindex $collect_default 2]
                set attMin [lindex $collect_default 5]
                set attMax [lindex $collect_default 6]
            
                if {![string is double -strict $value]} {
                    log_error attenuation setting wrong
                    log_error forced to default $attDef
                    set value $attDef
                } else {
                    if {$value < $attMin} {
                        log_error attenuation setting forced to minumum $attMin
                        set value $attMin
                    }
                    if {$value > $attMax} {
                        log_error attenuation setting forced to maximum $attMax
                        set value $attMax
                    }
                }
            } else {
                adjustPositionToLimit attenuation value 1
            }
        }
    }
} elseif { $attribute=="nextAction" } {
    if {$m_currentCrystal < 0 && $value != 0} {
        set value 0
        log_error "must mount first when there is no current crystal"
    }
} elseif { $attribute=="actionListStates" || $attribute=="simpleActionListStates" } {
    if {[lindex $value 0] != 1} {
        log_error "Mount Next Crystal must be always selected"
        set value [lreplace $value 0 0 1]
    }
    checkActionSelection value
} elseif { $attribute=="cassetteInfo" } {
    if {[lindex $crystalStatus 3] == "1"} {
        set screening_msg "error: cannot switch cassette while sample mounted"
        return -code error "cannot switch spreadsheet while sample is mounted"
    }
    if {[catch {
        checkCassettePermit [lindex $value 1]
    } errMsg]} {
        log_error $errMsg
        set value $m_cassetteInfo
    }
} elseif { $attribute=="nextCrystal" } {
    if {$m_isRunning && $m_lockNextCrystal} {
        log_error "too late to change, already sent to robot"
        set scrn_crystal_msg "error: too late to change"
        updateCrystalStatusString 
        updateCrystalSelectionListString
        return -code error "nextCrystal locked"
    }
        
    set n [llength $m_crystalListStates]
    if {$value < 0 || $value >= $n} {
        set scn_crystal_msg "error: out of range"
        return -code error "SequenceDevice::setConfig nextCrystal value out of range"
    }
    set m_crystalListStates [lreplace $m_crystalListStates $value $value 1]
    checkCrystalList m_crystalListStates
    #above function may turn off the bit we just turned on
    set value [getNextCrystal $value]
} elseif { $attribute=="crystalListStates" } {
    if {$m_isRunning && $m_lockNextCrystal} {
        if {$m_nextCrystal < 0} {
            set scn_crystal_msg "error: too late to change"
            log_warning "too late to change, already sent to robot, will take effect next time"
        } else {
            if {[lindex $value $m_nextCrystal] != "1"} {
                set scn_crystal_msg "error: too late to change"
                log_error "too late to unselect, already sent to robot"
                set value [lreplace $value $m_nextCrystal $m_nextCrystal 1]
            }
        }
    }
    checkCrystalList value
} elseif { $attribute=="useRobot" } {
    #no crystal selection OK will be put out
    if {$m_isRunning} {
        set screening_msg "error: cannot change during run"
        return -code error "SequenceDevice::setConfig useRobot readonly during a run"
    }
} elseif { $attribute=="actionListParameters" } {
    #only warning
    actionParametersOK value 1
}
# set the corresponding variable to the new state
if {$attribute != "simpleActionListStates"} {
    set paramName m_$attribute
} else {
    set paramName m_actionListStates
}
set val [list $value]

if {![info exists $paramName]} {
    set screening_msg "error: no $paramName"
    return -code error "no such attribute"
}

if { [catch "set $paramName $val" error] } {
    set screening_msg "failed to set $paramName"
    log_error "Screening setConfig $error"
    return -code error "setConfig $error"
}

# additionally, handle special cases 
if { $attribute=="nextAction" } {
    # set the corresponding checkbox to 1
    set i [set $paramName]
    set new_value [lreplace $m_actionListStates $i $i 1]
    checkActionSelection new_value
    set m_actionListStates $new_value
    set m_nextAction [getNextAction $m_nextAction]

    # if the system is not running ...
    if { $m_isRunning != 1 } {
        set m_currentAction -1
    }
    updateScreeningActionListString
} elseif { $attribute=="nextCrystal" } {
    updateCrystalSelectionListString
    updateCrystalStatusString 
} elseif { $attribute=="actionListStates" } {
    # update nextAction
    set m_nextAction [getNextAction $m_nextAction]
    #send_operation_update "setConfig nextAction $m_nextAction"
    actionParametersOK m_actionListParameters 1
    updateScreeningParametersString
    updateScreeningActionListString
} elseif { $attribute=="simpleActionListStates" } {
    # update nextAction
    if {$m_isRunning} {
        set m_nextAction [getNextAction [expr $m_currentAction + 1]]
    } else {
        set m_nextAction [getNextAction $m_nextAction]
    }
    #send_operation_update "setConfig nextAction $m_nextAction"
    actionParametersOK m_actionListParameters 1
    updateScreeningParametersString
    updateScreeningActionListString
} elseif { $attribute=="directory" || \
$attribute=="attenuation" || \
$attribute=="distance" || \
$attribute=="beamstop" } {
    updateScreeningParametersString
} elseif { $attribute=="detectorMode" } {
    set m_imgFileExtension [getImgFileExt]
    updateScreeningParametersString
} elseif { $attribute=="crystalListStates" } {
    # update nextCrystal
    set m_nextCrystal [getNextCrystal $m_nextCrystal]
    #send_operation_update "setConfig nextCrystal $m_nextCrystal"
    updateCrystalSelectionListString
    updateCrystalStatusString 
} elseif { $attribute=="cassetteInfo" } {
    updateCassetteInfo
} elseif { $attribute=="actionListParameters" } {
    updateScreeningParametersString
    getConfig all
} elseif { $attribute=="useRobot" } {
    if {$value} {
        #update m_isSyncedWithRobot
        syncWithRobot $TRY_SYNC_WITH_ROBOT
        checkCrystalList m_crystalListStates
        set m_nextCrystal [getNextCrystal $m_nextCrystal]
        updateCrystalSelectionListString
        updateCrystalStatusString 
        #check whether we need to reset next action because we may cleared
        #current crystal
        if {$m_currentCrystal < 0 && $m_nextAction != 0} {
            set m_nextAction 0
            set m_actionListStates [lreplace $m_actionListStates 0 0 1]
            updateScreeningActionListString
            log_warning Action Begin moved to Mount Next Crystal
        }
    } else {
        set m_isSyncedWithRobot no
        updateCrystalStatusString 
    }
}

return [list setConfig $attribute $value]
}

# =======================================================================

::itcl::body SequenceDevice::getConfig { attribute args } {
puts "SequenceDevice::getConfig $attribute $args"

checkInitialization

if { $attribute=="robotState" } {
    checkIfRobotResetIsRequired 
}

if { $attribute!="all" } {
    set paramName m_$attribute
    if { [catch "set val [list [set $paramName]]" error] } {
        log_error "Screening getConfig $error"
        return -code error "getConfig $error"
    }
    # puts "send_operation_update $attribute $val"
    # send_operation_update "getConfig $attribute $val"
    return [list getConfig $attribute $val]
}

puts "SequenceDevice::getConfig all OK"

updateScreeningActionListString
updateCrystalSelectionListString
updateScreeningParametersString
updateCrystalStatusString 
return [list getConfig all OK]
}

::itcl::body SequenceDevice::manual_operation { op args } {
    puts "SequenceDevice::manual_operation $op $args"
    variable ::nScripts::screening_msg
    variable ::nScripts::auto_sample_msg
    set auto_sample_msg ""
    set screening_msg ""
 
    set m_lastUserName [get_operation_user]
    set sessionID [lindex $args end]
    if {$sessionID != ""} {
        if {$sessionID == "SID"} {
            set sessionID PRIVATE[get_operation_SID]
            puts "manual_sequence use operation SID: [SIDFilter $sessionID]"
        }

        set m_lastSessionID $sessionID
        puts "manual sessionID [SIDFilter $m_lastSessionID]"

        variable ::nScripts::screening_user
        set screening_user $m_lastUserName
    }

    set m_manualMode 1

    checkInitialization

    switch -exact -- $op {
        mount {
            eval doManualMountCrystal $args
        }
        default {
            return -code error "did not support manual $op"
        }
    }
    ::nScripts::cleanupAfterAll
}
# =======================================================================
# =======================================================================
# private methods

::itcl::body SequenceDevice::checkInitialization {} {
    if {$m_isInitialized == 0} {
        initialization 
    }

    #always check spreadsheet update
    #handleSpreadsheetUpdateEvent
}
::itcl::body SequenceDevice::initialization {} {
    variable ::nScripts::screening_user
    puts "init SequenceDevice from database"
    set m_isInitialized 1

    refreshConfigOptions

    global gSessionID

    if {$m_lastUserName == "" || $m_lastSessionID == ""} {
        set m_lastUserName blctl
        set m_lastSessionID $gSessionID
    }

    set screening_user $m_lastUserName
    
    initBeamlineParameters
    initActionStates
    loadStateFromDatabaseString
    loadCrystalStatusString
    loadCrystalSelectionListString
    loadCrystalList
    syncWithRobot $TRY_SYNC_WITH_ROBOT
}

# =======================================================================

::itcl::body SequenceDevice::initBeamlineParameters {} {
puts "SequenceDevice::initBeamlineParameters"

#set m_crystalDataUrl "http://smb.slac.stanford.edu:8084/crystals/getCrystalData.jsp"
set m_crystalDataUrl [::config getCrystalDataUrl] 

# read string "beamlineID" from database.dat
variable ::nScripts::beamlineID
set m_beamlineName $beamlineID
set m_fileReOrient ${m_beamlineName}_reOrientStat.txt

set rootDir [::config getStrategyDir]
#set rootDir "/home/webserverroot/servlets/webice/data/strategy"
set m_strategyDir [file join $rootDir $m_beamlineName]
puts "strategyDir: $m_strategyDir"


puts "SequenceDevice::initBeamlineParameters OK"
}

# =======================================================================

::itcl::body SequenceDevice::initActionStates {} {
    global gMotorDistance
    global gMotorBeamStop

    puts "SequenceDevice::initActionStates"
    
    variable ::nScripts::screeningParameters
    set m_actionListParameters [lindex $screeningParameters 0]
    set m_detectorMode [lindex $screeningParameters 1]
    set m_directory [lindex $screeningParameters 2]
    set m_distance [lindex $screeningParameters 3]
    set m_beamstop [lindex $screeningParameters 4]
    set m_attenuation [lindex $screeningParameters 5]

    #####remote in next version
    if {$m_distance == ""} {
        variable ::nScripts::$gMotorDistance
        set m_distance [set $gMotorDistance]
    }
    if {$m_beamstop == ""} {
        variable ::nScripts::$gMotorBeamStop
        set m_beamstop [set $gMotorBeamStop]
    }
    if {$m_attenuation == ""} {
        variable ::nScripts::attenuation
        set m_attenuation $attenuation
    }

    #set m_actionListStates ""
    variable ::nScripts::screeningActionList
    set m_currentAction [lindex $screeningActionList 1]    
    set m_nextAction [lindex $screeningActionList 2]    
    set m_actionListStates [lindex $screeningActionList 3]    
    set m_nextAction [getNextAction $m_nextAction]

    #### detector mode changed ###
    set m_imgFileExtension [getImgFileExt]
puts "SequenceDevice::initActionStates OK"
}

# =======================================================================

::itcl::body SequenceDevice::loadStateFromDatabaseString {} {
puts "SequenceDevice::loadStateFromDatabaseString"

catch {
variable ::nScripts::sequenceDeviceState
variable ::nScripts::cassette_list
puts "sequenceDeviceState=$sequenceDeviceState"
set m_cassetteInfo $sequenceDeviceState
if {[info exists cassette_list]} {
    set local_copy [lindex $cassette_list 0]
    set m_cassetteInfo [lreplace $m_cassetteInfo 2 2 $local_copy]
    saveStateToDatabaseString
}
} error

puts "SequenceDevice::loadStateFromDatabaseString done $error"
}

# =======================================================================

::itcl::body SequenceDevice::saveStateToDatabaseString {} {
puts "SequenceDevice::saveStateToDatabaseString"
variable ::nScripts::sequenceDeviceState
set sequenceDeviceState $m_cassetteInfo
puts "sequenceDeviceState=$sequenceDeviceState"
puts "SequenceDevice::saveStateToDatabaseString OK"
}

# =======================================================================
# =======================================================================

::itcl::body SequenceDevice::stop { args } {
variable ::nScripts::screening_msg


puts "SequenceDevice::stop $args"
# call this method with: gtos_start_operation sequenceSetConfig setConfig stop args
set m_keepRunning 0

if {$m_isRunning} {
    set screening_msg "stopping"
}
return [list setConfig stop OK]
}

# =======================================================================

::itcl::body SequenceDevice::dismount { args } {
puts "SequenceDevice::dismount $args"
# call this method with: gtos_start_operation sequenceSetConfig setConfig dismount args
set m_dismountRequested 1
set m_keepRunning 0
if { $m_isRunning==1 } {
    # dismount will be done in run {}
    return [list setConfig dismount OK]
}
run
return [list setConfig dismount OK]
}

# =======================================================================

::itcl::body SequenceDevice::run {} {
variable ::nScripts::screening_msg

puts "SequenceDevice::run"

if {$m_isRunning} {
    puts "PANIC: more than one start messages"
    set screening_msg "error: already running"
    log_severe "PANIC: more than one start messages"
    return "PANIC: more than one start messages"
}

refreshConfigOptions

puts "Checking motor moving..."
if [catch {block_all_motors;unblock_all_motors} errMsg] {
    puts "MUST wait all motors stop moving to start screening"
    log_error "MUST wait all motors stop moving to start screening"
    set screening_msg "error: motor still moving"
    return "MUST wait all motors stop moving to start screening"
}

if {!$m_dismountRequested} {
    if {[catch {
        ::nScripts::correctPreCheckMotors
    } errMsg]} {
        log_error failed to correct motors $errMsg
        set screening_msg "failed to correct motors before run: $errMsg"
        return -code error $errMsg
    }
}

puts "lock sil"
set index [lindex $m_cassetteInfo 1]
if [catch "lockSil $m_lastUserName $m_lastSessionID $index" errMsg] {
    puts "lock sil failed: $errMsg"
}

set m_isRunning 1
set m_lockNextCrystal 0

set result ""
if {[catch run_internal result]} {
    log_error screening run failed: $result
}
puts "unlock sil"
if [catch "unlockAllSil $m_lastUserName $m_lastSessionID" errMsg] {
    puts "unlock sil failed: $errMsg"
}
    
set m_isRunning 0
updateScreeningActionListString

return $result
}
::itcl::body SequenceDevice::run_internal {} {

if {![syncWithRobot] && $m_useRobot} {
    puts "not sync with robot"
    set screening_msg "error: not synched with robot"
    log_error "screening: not synchronized with robot, abort"
    set m_isRunning 0
    return -code error "not synchronized with robot, abort"
}
#want to make dismount available even setup is wrong
if { $m_dismountRequested==1 } {
    updateScreeningActionListString
    set m_lockNextCrystal 1
    doDismount
    set m_lockNextCrystal 0
    setStrategyFileName disMnted
    puts "SequenceDevice::run OK"
    return
}

if {![actionParametersOK m_actionListParameters 0]} {
    puts "parameters bad"
    log_error "screening: bad parameters"
    set m_isRunning 0
    set screening_msg "error: action parameter wrong"
    return -code error "bad action parameters"
}


if {![crystalSelectionOK]} {
    puts "crystal selection bad"
    log_error "screening aborted: bad crystal selection, select at least one crystal"
    set screening_msg "error: crystal selection"
    set m_isRunning 0
    return -code error "bad crystal selection, abort"
}

if {![actionSelectionOK]} {
    puts "action selection bad"
    set screening_msg "error: action selection"
    set m_isRunning 0
    return -code error "bad action selection: abort"
}

################# check directory #####################

#### auto fix instead of failure
if {[checkUsernameInDirectory m_directory $m_lastUserName]} {
    updateScreeningParametersString
}

impDirectoryWritable $m_lastUserName $m_lastSessionID $m_directory

set m_dismountRequested 0

set m_isRunning 1
updateCrystalSelectionListString
updateCrystalStatusString 

spinMsgLoop

############## user log ###########
set index [lindex $m_cassetteInfo 1]
set cassetteList [lindex $m_cassetteInfo 2]
set cassette [lindex $cassetteList $index]
user_log_note screening "========$m_lastUserName start ${m_directory}========="
if {$cassette != "undefined"} {
    user_log_note screening "cassette: $cassette"
}

user_log_system_status screening

# here is the loop that performs all the selected actions
set m_numLoopCenteringError 0

set isAborted 0

while { $m_keepRunning==1 } {
    set m_currentAction [getNextAction $m_nextAction]
    if { $m_currentAction<0 } {
        ########### all done #############
        set m_nextAction 0
        set screening_msg "All done"
        break
    }
    set m_nextAction [getNextAction [expr $m_currentAction + 1]]
    updateScreeningActionListString

    if { [catch "runAction $m_currentAction" error] } {
        puts "ERROR in SequenceDevice::runAction $m_currentAction: $error"
        log_error "Screening $m_currentAction $error"

        if {[string first aborted $error] >= 0} {
            set isAborted 1
        }

        #### user log ##
        set action [lindex $m_actionListParameters $m_currentAction]
        set actionClass [lindex $action 0]
        user_log_error screening "[getCrystalNameForLog] $actionClass $error"

        set m_keepRunning 0
    }
    spinMsgLoop
}

if { $m_dismountRequested==1 } {
    set m_lockNextCrystal 1
    doDismount
    set m_lockNextCrystal 0
    setStrategyFileName disMnted
    puts "SequenceDevice::run OK"
    ##### doDismount will update the strings, so we can return here
    user_log_note  screening "=================all done================"
    return
}
set m_isRunning 0
if {$isAborted && $m_currentAction >= 0} {
    switch -exact -- $m_currentAction {
        0 -
        3 -
        4 -
        5 -
        6 -
        7 -
        9 -
        10 -
        11 -
        12 -
        13 -
        14 {
            ##these are no advance
            set m_nextAction [getNextAction $m_currentAction]
        }
        1 {
            ### here is for next is "STOP", so advance 2 steps
            #set m_nextAction [getNextAction [expr $m_nextAction + 1]]
            set m_nextAction [getNextAction [expr $m_currentAction + 2]]
        }
        default {
            set m_nextAction [getNextAction $m_nextAction]
        }
    }
} else {
    set m_nextAction [getNextAction $m_nextAction]
}
set m_currentAction -1

updateScreeningActionListString
updateCrystalSelectionListString

updateCrystalStatusString 

puts "SequenceDevice::run OK"
user_log_note  screening "=================stopped================"

return 
}

# =======================================================================

::itcl::body SequenceDevice::runAction { index} {
puts "==========="
puts "SequenceDevice::runAction $index"
set action [lindex $m_actionListParameters $index]
puts "action=$action"
set actionClass [lindex $action 0]
set params [lindex $action 1]

spinMsgLoop

if {!$m_skipThisSample} {
    switch -exact -- $actionClass {
        MountNextCrystal {
            set m_lockNextCrystal 1
            eval doMountNextCrystal $params
            set m_lockNextCrystal 0
            clearImages
            setStrategyFileName disMnted
        }
        Pause { doPause }
        OptimizeTable { doOptimizeTable }
        LoopAlignment { eval doLoopAlignment }
        VideoSnapshot { eval doVideoSnapshot $params }
        CollectImage { eval doCollectImage $params }
        ExcitationScan { eval doExcitation $params }
        Rotate { eval doRotate $params }
        ReOrient { doReOrient }
        RunQueueTask { sleep 2000 }
        test { sleep 5000 }
        default { puts "ERROR SequenceDevice::runAction actionClass $actionClass not supported" }
    }
} else {
    switch -exact -- $actionClass {
        MountNextCrystal {
            set m_lockNextCrystal 1
            eval doMountNextCrystal $params
            set m_lockNextCrystal 0
            clearImages
            setStrategyFileName disMnted
        }
        Pause { doPause }
        OptimizeTable -
        LoopAlignment -
        VideoSnapshot -
        CollectImage -
        ExcitationScan -
        ReOrient -
        RunQueueTask -
        Rotate { log_warning "skipped $actionClass for not mounted sample [getCurrentPortID]" }
        test { sleep 5000 }
        default { puts "ERROR SequenceDevice::runAction actionClass $actionClass not supported" }
    }
}
return
}

# =======================================================================

::itcl::body SequenceDevice::spinMsgLoop {} {
# we have to give other operations a chance to receive new config information
# I couldn't find a tcl function that does this
# so here is my ugly version of it:
puts "SequenceDevice::spinMsgLoop"

global spinMsgLoopFlag
set spinMsgLoopFlag 0
after idle {set spinMsgLoopFlag 1}
after 500 {set spinMsgLoopFlag 1}
vwait spinMsgLoopFlag

puts "SequenceDevice::spinMsgLoop OK"

}


# =======================================================================

::itcl::body SequenceDevice::sleep { msec} {
# non blocking wait (give other operations a chance to receive new config information)
# I couldn't find a tcl function that does this
# so here is my ugly version of it:
puts "SequenceDevice::sleep"

global sleepFlag
set sleepFlag 0
after $msec {set sleepFlag 1}
vwait sleepFlag

puts "SequenceDevice::sleep OK"

}

# =======================================================================

::itcl::body SequenceDevice::getNextAction { current} {
puts "SequenceDevice::getNextAction $current"

if {![actionSelectionOK]} {
    if {$m_currentCrystal < 0} {
        return 0
    }
    return "-1"
}
set n [llength $m_actionListStates]

if {$current < 0} {
    set $current 0
}

for {set i $current} {$i<$n} {incr i} {
    set state [lindex $m_actionListStates $i]
    if { $state==1 } {
        puts "nextAction=$i"
        return $i
    }
}
for {set i 0} {$i<$current} {incr i} {
    set state [lindex $m_actionListStates $i]
    if { $state==1 } {
        puts "nextAction=$i"
        return $i
    }
}
return "-1"
}

# =======================================================================

::itcl::body SequenceDevice::getNextCrystal { current} {
puts "SequenceDevice::getNextCrystal $current"

if {![crystalSelectionOK]} {
    return "-1"
}

if { $current < 0 } {
    set current 0
}
set n [llength $m_crystalListStates]
if { $current >= $n } {
    set current 0
}
for {set i $current} {$i<$n} {incr i} {
    if { $i==$m_currentCrystal } {
        continue
    }
    set state [lindex $m_crystalListStates $i]
    if { $state==1 } {
        puts "nextCrystal=$i"
        return $i
    }
}
for {set i 0} {$i<$current} {incr i} {
    if { $i==$m_currentCrystal } {
        continue
    }
    set state [lindex $m_crystalListStates $i]
    if { $state==1 } {
        puts "nextCrystal=$i"
        return $i
    }
}
puts "nextCrystal=-1"
return "-1"
}

# =======================================================================

::itcl::body SequenceDevice::getCrystalName  {} {
    puts "SequenceDevice::getCrystalName"

    if {$m_manualMode} {
        return $m_currentCassette$m_currentColumn$m_currentRow
    }

    if {$m_currentCrystal < 0} {
        return NotMounted
    }

    set crystalName [lindex $m_crystalIDList $m_currentCrystal]

    if {[string equal -nocase $crystalName "null"]} {
        set crystalName [lindex $m_crystalPortList $m_currentCrystal]
    }

    if { [string length $crystalName]<=0 } {
        if { $m_currentCrystal<0 } {
            set crystalName NotMounted
        } else {
            set crystalName crystal${m_currentCrystal}
        }
    }

    return $crystalName
}

#### this will always has port name in it
::itcl::body SequenceDevice::getCrystalNameForLog  {} {
    return $m_currentCassette$m_currentColumn$m_currentRow
}


# =======================================================================

::itcl::body SequenceDevice::getImgFileName { nameTag fileCounter } {
puts "SequenceDevice::getImgFileName $nameTag $fileCounter"

set crystalName [getCrystalName]

set counter [format $m_counterFormat $fileCounter]

if { [string length $nameTag]<=0 || $nameTag=="\"\"" || $nameTag=="{}" } {
    set fname "${crystalName}_${counter}"
} else {
    set fname "${crystalName}_${nameTag}_${counter}"
}
puts "fileName=$fname"
return $fname
}

::itcl::body SequenceDevice::getImgFileExt { } {
    return [getDetectorFileExt $m_detectorMode]
}

# =======================================================================

::itcl::body SequenceDevice::getFileCounter { subdir fileExtension } {
puts "SequenceDevice::getFileCounter $subdir $fileExtension"

set counter 0

set arr [array get a_fileCounterInfo]
puts "a_fileCounterInfo=$arr"

set crystalName [getCrystalName]

if { [info exists a_fileCounterInfo(dir_$fileExtension)]
    && [info exists a_fileCounterInfo(subdir_$fileExtension)]
    && [info exists a_fileCounterInfo(crystalName_$fileExtension)]
    &&    $a_fileCounterInfo(dir_$fileExtension)==$m_directory
    &&    $a_fileCounterInfo(subdir_$fileExtension)==$subdir
    &&    $a_fileCounterInfo(crystalName_$fileExtension)==$crystalName
    } {
    catch {set counter $a_fileCounterInfo($fileExtension)}
    puts "oldcounter=$counter"
    if { $counter>0 } {
        incr counter
        set a_fileCounterInfo($fileExtension) $counter
        puts "newcounter=$counter"
        return $counter
    }
} 
# new crystal -> reset file counters
set a_fileCounterInfo(dir_$fileExtension) 0
set a_fileCounterInfo(subdir_$fileExtension) 0
set a_fileCounterInfo(crystalName_$fileExtension) 0
set a_fileCounterInfo($fileExtension) 0
# make sure that the directory exists
set path [file join $m_directory $subdir]
set counter [impDirectoryWritable $m_lastUserName $m_lastSessionID $path \
$crystalName $fileExtension]

set a_fileCounterInfo(dir_$fileExtension) $m_directory
set a_fileCounterInfo(subdir_$fileExtension) $subdir
set a_fileCounterInfo(crystalName_$fileExtension) $crystalName
set a_fileCounterInfo($fileExtension) $counter

puts "counter=$counter"
return $counter
}
# =======================================================================

::itcl::body SequenceDevice::loadCrystalList { } {
    variable ::nScripts::scn_crystal_msg

    if {$m_afterID != ""} {
        log_warning cancel pending retry $m_afterID
        after cancel $m_afterID
        set m_afterID ""
    }

    #### m_cassetteInfo may changed by other messages
    puts "SequenceDevice::loadCrystalList"
    puts "cassetteinfo: $m_cassetteInfo"

    set user [lindex $m_cassetteInfo 0]
    set index [lindex $m_cassetteInfo 1]
    set cassetteList [lindex $m_cassetteInfo 2]
    set cassette [lindex $cassetteList $index]

    set m_spreadsheetStatus 0
    if {[catch {
        set data [string map {\n { }} [getSpreadsheetFromWeb $m_beamlineName \
        $m_lastUserName $m_lastSessionID $index $cassetteList]]
    } err_msg]} {
        log_error "$err_msg"
        set data {}
    }
    if {[llength $data] > 3} {
        if {$m_spreadsheetStatus < 0} {
            log_note Success in getting spreadsheet
        }
        set m_spreadsheetStatus 1
        set m_tsNextSevereMsg 0
        set m_cntSevereMsg 0
    } else {
        set m_spreadsheetStatus -1;#mark in retrying
        log_warning get spreadsheet failed.  will retry after 10 second
        set m_afterID [after 10000 "$this retryLoadingSpreadsheet"]
    }
    #log_note "spreadsheet: $data"
    refreshWholeSpreadsheet $data
}
::itcl::body SequenceDevice::handleSpreadsheetUpdateEvent { args } {
    log_note "spreadsheet update called"
    if { $m_isInitialized==0 } {
        log_warning postpone spreadsheet update to initializaion
        return
    }

    if {![string is integer -strict $m_SILID]} {
        log_error old spreadsheet, skip update
        return
    }

    if {$m_SILID < 0} {
        log_error no spreadsheet has been loaded yet, skip update
        return
    }

    if {$m_spreadsheetStatus <= 0} {
        log_error skip update while retrying get spreadsheet in process
        return
    }
    
    if {![info exists m_SILEventID]} {
        set eventID 0
    } else {
        log_note current event id $m_SILEventID
        set eventID [expr $m_SILEventID + 1]
    }

    set data [getSpreadsheetChangesSince $m_lastUserName $m_lastSessionID $m_SILID $eventID]
    puts "row update data: $data"
    set silID [lindex $data 0]
    set eventID [lindex $data 1]
    set cmd [lindex $data 2]
    if {$silID == $m_SILID && $eventID <= $m_SILEventID} {
        puts "no change"
        return
    }
    if {$silID != $m_SILID} {
        puts "silid changed from $m_SILID to $silID"
        if {$cmd != "load"} {
            puts "but command != load, skip"
            return
        }
    }
    if {$cmd == "load"} {
        refreshWholeSpreadsheet $data
    } else {
        set rowData [lrange $data 3 end]
        updateRows $rowData
        set m_SILEventID $eventID
        log_note SIL $m_SILID $m_SILEventID
    }
}
::itcl::body SequenceDevice::refreshWholeSpreadsheet { data } {
    variable ::nScripts::sil_id
    variable ::nScripts::robot_cassette

    set index [lindex $m_cassetteInfo 1]
    set cassette_index [expr "97 * ($index - 1)"]
    set cassette_status [lindex $robot_cassette $cassette_index]

    set m_currentCassetteStatus $cassette_status
    set first [lindex $data 0]
    puts "first: $first"
    if {[llength $first] == 1} {
        puts "new SIL service"
        ##### new service
        set m_SILID $first
        set m_SILEventID [lindex $data 1]
        set cmd [lindex $data 2]
        set header [lindex $data 3]
        set crystalList [lrange $data 4 end]
        puts "SIL ID: $m_SILID Event ID: $m_SILEventID"
        log_note SIL $m_SILID $m_SILEventID
    } else {
        #### old service, using default header
        puts "old use default header"
        set m_SILID "old"
        set header $m_defaultHeader
        set crystalList $data

        #####send note to client
        set contents_to_send [lindex $crystalList 0]
        log_note SIL $m_SILID $contents_to_send
    }
    
    if {[string is integer -strict $m_SILID]} {
        if {$sil_id != $m_SILID} {
            puts "set sil_id to $m_SILID"
            set sil_id $m_SILID
        }
    } else {
        ##### set sil_id to 0 so impDHS will not poll
        if {$sil_id != 0} {
            set sil_id 0
        }
    }

    if {$m_currentHeader != $header} {
        set foundPort 0
        set m_currentHeaderNameOnly ""
        foreach column $header {
            set name [lindex $column 0]
            if {[string equal -nocase $name "Port"]} {
                set foundPort 1
            }
            lappend m_currentHeaderNameOnly $name
        }
        if {!$foundPort} {
            log_error "bad spreadsheet header: no Port column defined"
            return
        }
        set m_currentHeader $header
        set m_PortIndex [lsearch -exact $m_currentHeaderNameOnly "Port"]
        set m_IDIndex   [lsearch -exact $m_currentHeaderNameOnly "CrystalID"]
        if {$m_IDIndex < 0} {
            set m_IDIndex $m_PortIndex
        }
        set m_DirectoryIndex [lsearch -exact $m_currentHeaderNameOnly "Directory"]
        set m_SelectedIndex [lsearch -exact $m_currentHeaderNameOnly "Selected"]

        set m_ReOrientableIndex \
        [lsearch -exact $m_currentHeaderNameOnly "ReOrientable"]

        set m_ReOrientInfoIndex \
        [lsearch -exact $m_currentHeaderNameOnly "ReOrientInfo"]

        set m_ReOrientPhiIndex \
        [lsearch -exact $m_currentHeaderNameOnly "ReOrientPhi"]

        set m_UniqueIDIndex \
        [lsearch -exact $m_currentHeaderNameOnly "UniqueID"]

        set m_BarcodeScannedIndex \
        [lsearch -exact $m_currentHeaderNameOnly "BarcodeScanned"]

        set m_GridSampleLocationIndex \
        [lsearch -exact $m_currentHeaderNameOnly "GridSampleLocation"]

        puts "index: port $m_PortIndex ID $m_IDIndex dir $m_DirectoryIndex selected: $m_SelectedIndex reorient: $m_ReOrientableIndex $m_ReOrientInfoIndex $m_ReOrientPhiIndex uniqueID: $m_UniqueIDIndex BarcodeScanned: $m_BarcodeScannedIndex GridSampleLocation: $m_GridSampleLocationIndex"
    }

    # extract from $data the lists m_crystalPortList, m_crystalIDList, m_crystalDirList, m_crystalListStates
    set crystalPortList {}
    set crystalIDList {}
    set crystalDirList {}
    set crystalListStates {}
    set reorientableList {}
    set reorientinfoList {}
    set reorientphiList {}
    set uniqueIDList {}
    set gridSampleLocationList {}
    set m_numRowParsed 0
    foreach row $crystalList {
        foreach {port id dir reorientable reorientinfo reorientphi uniqueID \
        gridSampleLocation} [parseOneRow $row] break

        lappend crystalPortList $port
        lappend crystalIDList $id
        lappend crystalDirList $dir
        lappend reorientableList $reorientable
        lappend reorientinfoList $reorientinfo
        lappend reorientphiList $reorientphi
        lappend uniqueIDList $uniqueID
        lappend gridSampleLocationList $gridSampleLocation
        lappend crystalListStates 1

        incr m_numRowParsed
        if {$m_numRowParsed > 300} {
            log_error too many rows > 300 on the spreadsheet
            break
        }
    }

    set m_indexMap [generateIndexMap $index $m_PortIndex crystalList \
    $m_currentCassetteStatus]
    puts "indexmap: $m_indexMap"

    #########honor "Selected" column if found
    if {$m_SelectedIndex >= 0} {
        set crystalListStates {}
        for {set i 0} {$i < $m_numRowParsed} {incr i} {
            set row [lindex $crystalList $i]
            set value [lindex $row $m_SelectedIndex]
            if {!$value} {
                log_warning [lindex $crystalIDList $i]([lindex $crystalPortList $i])  deselected by spreadsheet
            }
            lappend crystalListStates $value
        }
        log_warning Checkbox reloaded from spreadsheet, please check them
    }

    set m_crystalPortList $crystalPortList
    set m_crystalIDList $crystalIDList
    set m_crystalDirList $crystalDirList
    set m_reOrientableList $reorientableList
    set m_reOrientInfoList $reorientinfoList
    set m_reOrientPhiList $reorientphiList
    set m_uniqueIDList $uniqueIDList
    set m_gridSampleLocationList $gridSampleLocationList
    set m_crystalListStates $crystalListStates
    checkCrystalList m_crystalListStates
    set m_nextCrystal [getNextCrystal 0]

    set m_numRowParsed [llength $crystalList]


    puts "DEBUG REORIENTTABLELIST: $m_reOrientableList"
    puts "DEBUG REORIENTINFOLIST: $m_reOrientInfoList"
    puts "DEBUG REORIENTPHILIST: $m_reOrientPhiList"

    ######### check lists and give warnings if not unique #####
    if {![listIsUnique $crystalIDList]} {
        log_warning "crystal IDs are not unique"
        set scn_crystal_msg "warning: crystal IDs not unique"
    }
    if {![listIsUnique $crystalPortList]} {
        log_warning "crystal Ports are not unique"
        set scn_crystal_msg "warning: PORTS NOT UNIQUE!!!"
    }
    
    #update m_isSyncedWithRobot
    syncWithRobot
    updateCrystalSelectionListString

    puts "SequenceDevice::loadCrystalList OK"
    return
}
::itcl::body SequenceDevice::updateRows { data } {
    foreach row_data $data {
        set row_index [lindex $row_data 0]
        set row_contents [lindex $row_data 1]

        if {$row_index < 0 || $row_index >= $m_numRowParsed} {
            puts "row index $row_index is out of range \[0,$m_numRowParsed) for update"
            continue
        }
        foreach {port id dir reorientable reorientinfo reorientphi uniqueID} \
        [parseOneRow $row_contents] break

        set old_port [lindex $m_crystalPortList $row_index]
        if {$old_port != $port} {
            log_error "row $row_index new port {$port} does not match old {$old_port}"
            continue
        }
        puts "updating row: $row_index new ID: $id new DIR: $dir"
        set m_crystalIDList \
        [lreplace $m_crystalIDList $row_index $row_index $id]

        set m_crystalDirList \
        [lreplace $m_crystalDirList $row_index $row_index $dir]

        set m_reOrientableList \
        [lreplace $m_reOrientableList $row_index $row_index $reorientable]

        set m_reOrientInfoList \
        [lreplace $m_reOrientInfoList $row_index $row_index $reorientinfo]

        set m_reOrientPhiList \
        [lreplace $m_reOrientPhiList $row_index $row_index $reorientphi]

        set m_uniqueIDList \
        [lreplace $m_uniqueIDList $row_index $row_index $uniqueID]

        if {$m_currentCrystal == $row_index || $m_nextCrystal == $row_index} {
            updateCrystalStatusString 
        }
    }
}

::itcl::body SequenceDevice::parseOneRow { contents } {
    set port [lindex $contents $m_PortIndex]
    set id [lindex $contents $m_IDIndex]
    if {$m_DirectoryIndex < 0} {
        set dir .
    } else {
        set dir [lindex $contents $m_DirectoryIndex]
    }
    while { [string index $dir 0]=="/" && [string length $dir]>1} {
        set dir [string range $dir 1 end]
    }
    if { $dir=="0" || $dir=="null" || $dir=="/" || [string length $dir]==0 } {
        set dir {}
    }
    set id  [TrimStringForCrystalID $id]
    set dir [TrimStringForSubDirectoryName $dir]

    if {$m_ReOrientableIndex < 0 || \
    $m_ReOrientInfoIndex < 0 || \
    $m_ReOrientPhiIndex < 0} {
        set re_orientable 0
        set re_orient_info ""
        set re_orient_phi ""
    } else {
        set re_orientable  [lindex $contents $m_ReOrientableIndex]
        set re_orient_info [lindex $contents $m_ReOrientInfoIndex]
        set re_orient_phi  [lindex $contents $m_ReOrientPhiIndex]

        if {$re_orient_info == ""} {
            set re_orientable 0
            set re_orient_phi ""
        }
    }

    if {$m_UniqueIDIndex < 0} {
        set uniqueID ""
    } else {
        set uniqueID [lindex $contents $m_UniqueIDIndex]
    }

    if {$m_GridSampleLocationIndex < 0} {
        set gridSampleLocation ""
    } else {
        set gridSampleLocation [lindex $contents $m_GridSampleLocationIndex]
    }

    return [list \
    $port $id $dir $re_orientable $re_orient_info $re_orient_phi $uniqueID \
    $gridSampleLocation \
    ]
}

# =======================================================================

::itcl::body SequenceDevice::setPhiZero {} {
global gMotorPhi
puts "SequenceDevice::setPhiZero"

global gDevice
set m_phiZero $gDevice($gMotorPhi,scaled)
puts "m_phiZero=$m_phiZero"

puts "SequenceDevice::setPhiZero OK"
}


# =======================================================================
# =======================================================================
# here are the hardware calls

# =======================================================================

::itcl::body SequenceDevice::doMountNextCrystal { {num_cycle_to_wash_ 0} } {
variable ::nScripts::screening_msg
puts "SequenceDevice::doMountNextCrystal m_currentCrystal=$m_currentCrystal m_nextCrystal=$m_nextCrystal"

#prepare to call mountCrystal
set index [lindex $m_cassetteInfo 1]
set next_cassette [lindex {0 l m r} $index]
if {$next_cassette == 0} {
    # no cassette
    if {$m_useRobot} {
        log_error "Screening mountNextCrystal wrong dewar position (No cassette)"
        set screening_msg "error: wrong cassette"
        set m_keepRunning 0
        return
    }
}

set next [getNextCrystal $m_nextCrystal]
puts "doMountNext: next=$next"

if { $next>=0 } { 
    set next_port [lindex $m_crystalPortList $next]
    if { [string length $next_port]>1 } {
        set next_column [string index $next_port 0]
        set next_row [string range $next_port 1 end]
    } else {
        set msg "ERROR SequenceDevice::doMountNextCrystal wrong next_port=$next_port"
        puts $msg
        if { $useRobotFlag!=0 } {
            log_error "Screening mountNextCrystal wrong next_port=$next_port"
            set screening_msg "error: wrong port"
            set m_keepRunning 0
            return
        }
    }
} else {
    #mark of no mount
    set next_cassette n
    set next_column N
    set next_row 0
}

moveMotorsToDesiredPosition 

#### do mount next crystal
set m_mountingCrystal $next
mountCrystal $next_cassette $next_column $next_row $num_cycle_to_wash_
set m_mountingCrystal -1

########## move pointers of current and next crystal #########
if {$m_currentCassette == $next_cassette && \
$m_currentColumn == $next_column && \
$m_currentRow == $next_row} {
    if {$m_currentCrystal >= 0} {
        # uncheck the current crystal
        set m_crystalListStates \
        [lreplace $m_crystalListStates $m_currentCrystal $m_currentCrystal 0]
    }
    set m_currentCrystal $next
} else {
    set m_currentCrystal -1
}
if { $m_currentCrystal<0 } {
    # m_currentCrystal==-1 means no crystal mounted
    puts "all crystals are unchecked"
    # stop since there are no more crystals to analyze
    # request all system resets as if a dismount was pressed
    set m_dismountRequested 1
    set m_keepRunning 0
} else {
    set reOrientSelected  [lindex $m_actionListStates 13]
    set re_orientable [lindex $m_reOrientableList $m_currentCrystal]
    if {$re_orientable != "1"} {
        set re_orientable 0
    }

    ### skip clear results if it is mounged for reOrient
    if {!$m_enableReOrient || !$re_orientable || !$reOrientSelected} {
        if {[string is integer -strict $m_SILID] && \
        ($m_enableAddImage || $m_enableAnalyzeImage)} {
            if {[catch {
                #### clear all fields
                set uniqueID [lindex $m_uniqueIDList $m_currentCrystal]
                clearCrystalResults $m_lastUserName $m_lastSessionID \
                $m_SILID $m_currentCrystal $uniqueID
            } errmsg]} {
                log_error clearCrystalResults $errmsg
            }
        }
    }
    updateBarcodeScanned $m_currentBarcode
}

set m_nextCrystal [getNextCrystal [expr $m_currentCrystal + 1]]

updateCrystalSelectionListString

######################## check sync with robot again #############
if {!$m_useRobot}  {
    syncWithRobot
} else {
    if {![syncWithRobot $TRY_SYNC_WITH_ROBOT]}  {
        set m_keepRunning 0
        set screening_msg "error: lost sync with robot"
        log_error "screening aborted: lost sync with robot"
    }
}

if {!$m_useRobot} {
    set m_keepRunning 0
    if {$m_currentCrystal < 0} {
        set screening_msg "manual dismount"
        log_warning "If a sample is mounted, dismount it now"
    } else {
        set cur_port [lindex $m_crystalIDList $m_currentCrystal]
        set screening_msg "manual mount $cur_port"
        log_warning "Please make sure $cur_port is mounted"
    }
}
puts "SequenceDevice::doMountNextCrystal OK"
}

::itcl::body SequenceDevice::mountCrystal { cassette column row wash_cycle_ } {
variable ::nScripts::screening_msg

set m_currentBarcode ""
set m_skipThisSample 0
set m_sampleReOriented 0
fillDefaultRunForAdjust

if {[isOperation scan3DSetup]} {
    if {[catch {
        ### now we need the scan3DSetup operation.  BluIce needs it.
        set h [start_waitable_operation scan3DSetup clear]
        wait_for_operation_to_finish $h
    } errMsg]} {
        puts "rastering clear failed: $errMsg"
    }
}
if {[isOperation rasterRunsConfig]} {
    if {[catch {
        set h [start_waitable_operation rasterRunsConfig deleteAllRasters]
        wait_for_operation_to_finish $h
    } errMsg]} {
        puts "rasterRun clear failed: $errMsg"
    }
}
if {[isOperation spectrometerWrap]} {
    if {[catch {
        set h [start_waitable_operation spectrometerWrap clear_result_files]
        wait_for_operation_to_finish $h
    } errMsg]} {
        puts "microspec clear failed: $errMsg"
    }
}
if {[isOperation gridGroupConfig]} {
    if {[catch {
        set h [start_waitable_operation gridGroupConfig cleanup_for_dismount]
        wait_for_operation_to_finish $h
    } errMsg]} {
        puts "gridGroup clear failed: $errMsg"
    }
}

puts "mountCrystal $cassette $column $row $wash_cycle_"

checkCassettePermit $m_currentCassette
checkCassettePermit $cassette

#### check cryojet temperature for mounting a crystal
if {$cassette != "n"} {
    global gDevice

    if {[isMotor temperature] && \
    ($gDevice(temperature,lowerLimitOn) || $gDevice(temperature,upperLimitOn)) \
    } {
        puts "checking cryojetDhs online"

        #### check if cryojetDhs is offline
        if {[catch {
            check_device_controller_online temperature
        } errMsg]} {
            log_severe cannot mount crystal, \
            cryojetDhs not online and temperature limits on.
            set screening_msg "error: cryojet offline"
            return -code error $errMsg
        }
        puts "checking temperature"
        #### check temperature
        variable ::nScripts::temperature
        if {![limits_ok_quiet temperature $temperature]} {
            log_severe cannot mount crystal, cryojet temperature out of limits
            set screening_msg "error: cryojet temperature off limit"
            return -code error "cryojet temperature out of limits"
        }
        puts "temperature checking OK"
    }
}

set useRobotFlag $m_useRobot

##### deal with beamline tool pin #####
##### we do not plan to support mount beamline tool pin
##### from the sample interface
##### we only support dismount it
if {$m_currentCassette == "b" && \
$m_currentColumn == "T" && \
$m_currentRow == 0} {
    if {[catch {
        namespace eval ::nScripts ISampleMountingDevice_start dismountBeamLineTool
    } errorText]} {
        puts "ERROR SequenceDevice::doMountNextCrystal() $errorText"
        log_error "Screening mountNextCrystal $errorText"
        set screening_msg "error: $errorText"
        set m_keepRunning 0
        syncWithRobot $TRY_SYNC_WITH_ROBOT
        return -code error $errorText
    }
    set m_currentCassette n
    set m_currentColumn N
    set m_currentRow 0
}

if {$m_currentCassette != "n" && \
$m_currentColumn != "N" && \
$m_currentRow != 0} {
    puts "current port OK"
    set currentPortOK 1
} else {
    set currentPortOK 0
}
if {$cassette != "n" && \
$column != "N" && \
$row != 0} {
    puts "next port OK"
    set nextPortOK 1
} else {
    set nextPortOK 0
}

# decide if we have to call mountNextCrystal, dismountCrystal or mountCrystal
if { $currentPortOK && $nextPortOK } {

    set screening_msg "dismount $m_currentCassette$m_currentColumn$m_currentRow mount $cassette$column$row"
    set errorFlag 0
    set errorText ""
    if { $useRobotFlag==1 } {
        puts "doMountNextCrystal() start_operation ISampleMountingDevice mountNextCrystal $m_currentCassette $m_currentColumn $m_currentRow $cassette $column $row"
        set errorFlag [catch {
        namespace eval ::nScripts ISampleMountingDevice_start mountNextCrystal $m_currentCassette $m_currentRow $m_currentColumn $cassette $row $column $wash_cycle_
        } errorText]
        set op_status [lindex $errorText 0]
        set op_result_l [llength $errorText]
        puts "SequenceDevice::doMountNextCrystal() done $errorText"
        if { $errorFlag || $op_status != "normal" || $op_result_l < 5 } {
            puts "ERROR SequenceDevice::doMountNextCrystal() $errorText"
            log_error "Screening mountNextCrystal $errorText"
            set screening_msg "error: $errorText"
            set m_keepRunning 0
            syncWithRobot $TRY_SYNC_WITH_ROBOT
            return -code error $errorText
        }
        set mt_status [lindex $errorText 4]

        ######### check wether the job is partially done ######
        if {$mt_status == "normal"} {
            set m_currentCassette $cassette
            set m_currentColumn $column
            set m_currentRow $row
            ####check skipped empty port
            if {[lindex $errorText 5] == "n" && \
            [lindex $errorText 6] == "0" && \
            [lindex $errorText 7] == "N"} {
                set m_skipThisSample 1
                set screening_msg "skip empty port"
            } else {
                set screening_msg "$cassette$column$row mounted"
                if {[llength $errorText] > 8} {
                    set barcode [lindex $errorText 8]
                    puts "barcode: $barcode"
                    set m_currentBarcode $barcode
                }
            }
        } else {
            set m_currentCassette n
            set m_currentColumn N
            set m_currentRow 0
            set screening_msg "mount failed"
        }
        checkIfRobotResetIsRequired
    } else {
        puts "ROBOT simulation"
        sleep 800
        set m_currentCassette $cassette
        set m_currentColumn $column
        set m_currentRow $row
    }
    spinMsgLoop
} elseif { $currentPortOK && !$nextPortOK} {
    # there is no next crystal -> dismount only
    puts "ROBOT dismountCrystal $m_currentCassette$m_currentColumn$m_currentRow"
    set screening_msg "dismount $m_currentCassette$m_currentColumn$m_currentRow"
    set errorFlag 0
    set errorText ""
    if { $useRobotFlag==1 } {
        puts "call  ISampleMountingDevice_start dismountCrystal $m_currentCassette $m_currentRow $m_currentColumn"
        set errorFlag [catch {
        namespace eval ::nScripts ISampleMountingDevice_start dismountCrystal $m_currentCassette $m_currentRow $m_currentColumn
        } errorText]
        set op_status [lindex $errorText 0]
        set op_result_l [llength $errorText]
        puts "SequenceDevice::doMountNextCrystal() done $errorText"
        if { $errorFlag || $op_status != "normal" || $op_result_l < 4 } {
            puts "ERROR SequenceDevice::doMountNextCrystal() $errorText"
            log_error "Screening mountNextCrystal $errorText"
            set screening_msg "error: $errorText"
            set m_keepRunning 0
            syncWithRobot $TRY_SYNC_WITH_ROBOT
            return -code error $errorText
        }
        set screening_msg "$m_currentCassette$m_currentColumn$m_currentRow dismounted"
        checkIfRobotResetIsRequired
    } else {
        puts "ROBOT simulation"
        sleep 800
    }
    set m_currentCassette n
    set m_currentColumn N
    set m_currentRow 0
    spinMsgLoop
} elseif {!$currentPortOK && $nextPortOK} {
    # there is no current crystal -> mount only
    puts "ROBOT mountCrystal $cassette $column $row" 
    set screening_msg "mount $cassette$column$row"
    set errorFlag 0
    set errorText ""
    if { $useRobotFlag==1 } {
        puts "call ISampleMountingDevice_start mountCrystal $cassette $row $column"
        set errorFlag [catch {
        namespace eval ::nScripts ISampleMountingDevice_start mountCrystal $cassette $row $column $wash_cycle_
        } errorText]
        set op_status [lindex $errorText 0]
        set op_result_l [llength $errorText]
        puts "SequenceDevice::doMountNextCrystal() done $errorText"
        if { $errorFlag || $op_status != "normal" || $op_result_l < 4 } {
            puts "ERROR SequenceDevice::doMountNextCrystal() $errorText"
            log_error "Screening mountNextCrystal $errorText"
            set screening_msg "error: $errorText"
            set m_keepRunning 0
            syncWithRobot $TRY_SYNC_WITH_ROBOT
            return -code error $errorText
        }
        if {[lindex $errorText 1] == "n" && \
        [lindex $errorText 2] == "0" && \
        [lindex $errorText 3] == "N"} {
            set m_skipThisSample 1
            set screening_msg "skip empty port"
        } else {
            set screening_msg "$cassette$column$row mounted"
            if {[llength $errorText] > 4} {
                set barcode [lindex $errorText 4]
                puts "barcode $barcode"
                set m_currentBarcode $barcode
            }
        }
        checkIfRobotResetIsRequired
    } else {
        puts "ROBOT simulation"
        sleep 800
    }
    set m_currentCassette $cassette
    set m_currentColumn $column
    set m_currentRow $row
    spinMsgLoop
} else {
    puts "bad situation: current: $m_currentCassette $m_currentColumn $m_currentRow"
    puts "currentCrystal=$m_currentCrystal next=$m_nextCrystal"
}

setPhiZero

if {!$m_useRobot && $m_manualMode} {
    if {$m_currentCassette == "n" || \
    $m_currentColumn == "N" || \
    $m_currentRow == 0} {
        set screening_msg "manual dismount"
        log_warning "If a sample is mounted, dismount it now"
    } else {
        set screening_msg "manual mount $cassette$column$row"
        log_warning "Please make sure $cassette$column$row is mounted"
    }
}
return
}

# =======================================================================

::itcl::body SequenceDevice::doDismount {} {
puts "SequenceDevice::doDismount"

#tell clients that we are running dismount
set m_currentAction -1
set m_actionListStates [lreplace $m_actionListStates 0 0 1]
set m_nextAction 0
updateScreeningActionListString

set m_dismountRequested 0

mountCrystal n N 0 0

set m_isRunning 0
updateAfterDismount
return
}

# =======================================================================

::itcl::body SequenceDevice::doPause {} {
variable ::nScripts::screening_msg
puts "SequenceDevice::doPause"
set m_keepRunning 0
}

# =======================================================================

::itcl::body SequenceDevice::doOptimizeTable {} {
variable ::nScripts::screening_msg
puts "SequenceDevice::doOptimizeTable"

variable ::nScripts::optimized_energy

if {![info exists optimized_energy]} {
    log_warning skip optimizing table, no optimized_energy motor
    return
}

set screening_msg "optimizing table"
move optimized_energy to $optimized_energy

wait_for_devices optimized_energy
set screening_msg "table optimized"

puts "SequenceDevice::doOptimizeTable OK"
}

# =======================================================================

::itcl::body SequenceDevice::doLoopAlignment {} {
variable ::nScripts::screening_msg
variable ::nScripts::lc_error_threshold
set screening_msg "loop alignment"
puts "SequenceDevice::doLoopAlignment"

    waitForMotorsForVideo

# call scripted operation "centerLoop"
if {[catch {namespace eval ::nScripts centerLoop_start} errorMsg]} {
    user_log_error screening "[getCrystalNameForLog] loopCenter $errorMsg"

    #### if abort, do not try to take the snapshot
    if {[string first aborted $errorMsg] >= 0} {
        set screening_msg "error: $errorMsg"
        return -code error $errorMsg
    }

    #### if stop is selected, just return error
    set stop_selected [expr [lindex $m_actionListStates 2] ? 1 : 0]
    if {$stop_selected} {
        set screening_msg "error: $errorMsg"
        return -code error $errorMsg
    }

    #### decide whether stop screening
    #### if not stop, decide whether skip collect images.
    incr m_numLoopCenteringError

    ##### get threshold ###
    set threshold 2
    set skip_all 1
    if {[info exists lc_error_threshold]} {
        set thd_set [lindex $lc_error_threshold 0]
        if {[string is integer -strict $thd_set] && $thd_set > 0} {
            set threshold $thd_set
        }

        set skip_set [lindex $lc_error_threshold 1]
        if {[string is integer -strict $skip_set]} {
            set skip_all $skip_set
        }
    }
    ###### check ######
    if {$m_numLoopCenteringError >= $threshold} {
        set screening_msg "error: $errorMsg"
        return -code error $errorMsg
    }

    set warning_contents "loopCenter_$errorMsg"

    ######## skip ######
    if {$skip_all} {
        #### take a picture and skip all other actions
        doVideoSnapshot 0 failed
        set m_skipThisSample 1
        set screening_msg "warning: skip this sample"

        append warning_contents " skipped diffraction image"
    }

    ######## append to system warnings 
    if {[string is integer -strict $m_SILID]} {
        if {[catch {
            regsub -all {[[:blank:]]} $warning_contents _ warning_contents
            set data [list SystemWarning $warning_contents]
            set data [eval http::formatQuery $data]

            set uniqueID [lindex $m_uniqueIDList $m_currentCrystal]
            editSpreadsheet $m_lastUserName $m_lastSessionID \
            $m_SILID $m_currentCrystal $data $uniqueID
        } secondErr]} {
            log_warning failed to append warning message to spreadsheet
        }
    }
} else {
    ##### this number is for consecutive
    set m_numLoopCenteringError 0
set screening_msg "loop alignment OK"
}

setPhiZero

    if {[catch checkFirstSnapshotForReOrient errMsg]} {
        log_warning failed to save video snapshot for reorient
    }

puts "SequenceDevice::doLoopAlignment OK"
}

# =======================================================================
# generate "-x 0.5 -y 0.5 -w 0.2 -h 0.1"
::itcl::body SequenceDevice::drawInfoOnVideoSnapshot { } {
    global gMotorBeamWidth
    global gMotorBeamHeight

    variable ::nScripts::$gMotorBeamWidth
    variable ::nScripts::$gMotorBeamHeight

    set sampleImageWidth  [::nScripts::getSampleCameraConstant sampleImageWidth]
    set sampleImageHeight [::nScripts::getSampleCameraConstant sampleImageHeight]
    set zoomMaxXAxis      [::nScripts::getSampleCameraConstant zoomMaxXAxis]
    set zoomMaxYAxis      [::nScripts::getSampleCameraConstant zoomMaxYAxis]

    set result "-x $zoomMaxXAxis -y $zoomMaxYAxis"
    set umPerPixelH 1
    set umPerPixelV 1
    ::nScripts::getSampleScaleFactor umPerPixelH umPerPixelV NULL

    set w [expr 1000.0 * [set $gMotorBeamWidth] / ($umPerPixelH * $sampleImageWidth)]
    set h [expr 1000.0 * [set $gMotorBeamHeight] / ($umPerPixelV * $sampleImageHeight)]

    append result " -w $w -h $h"

    log_note scale: $result
    return $result
}
# =======================================================================

::itcl::body SequenceDevice::doVideoSnapshot {zoom nameTag} {
variable ::nScripts::screening_msg
puts "SequenceDevice::doVideoSnapshot zoom=$zoom nameTag=$nameTag"

    waitForMotorsForVideo

set subdir [getSubDirectory]
set fileCounter [getFileCounter $subdir "jpg"]
set fileName [getImgFileName $nameTag $fileCounter]
set filePath [file join $m_directory $subdir "${fileName}.jpg"]

set screening_msg "snapshot $fileName"

	if {[motor_exists camera_zoom]} {
    	move camera_zoom to $zoom
    	wait_for_devices camera_zoom
	}

    set saveRawJPEG 1
    if {$ADD_BEAM_INFO_TO_JPEG} {
        set mySID $m_lastSessionID
        if {[string equal -length 7 $mySID "PRIVATE"]} {
            set mySID [string range $mySID 7 end]
        }

        set urlSOURCE [::config getSnapshotUrl]

        set urlTARGET "http://[::config getImpDhsImpHost]"
        append urlTARGET ":[::config getImpDhsImpPort]"
        append urlTARGET "/writeFile?impUser=$m_lastUserName"
        append urlTARGET "&impSessionID=$mySID"
        append urlTARGET "&impFilePath=$filePath"
        append urlTARGET "&impWriteBinary=true"
        append urlTARGET "&impBackupExist=true"
        append urlTARGET "&impAppend=false"

        #log_note cmd: $cmd
        if { [catch {
            saveBoxSnapshot $filePath
            user_log_note screening "[getCrystalNameForLog] videosnap $filePath"
            set saveRawJPEG 0
        } errMsg]} {
            #set status "ERROR $errMsg"
            #set ncode 0
            #set code_msg "get url failed for snapshot"
            catch {
                user_log_error screening \
                "videoSnapshot with beam info error: $errMsg"

                log_error screening "videoSnapshot with beam info error: $errMsg"
            }
        }
    }

    if {$saveRawJPEG} {
        if {[catch {
            saveRawSnapshot $filePath

            user_log_note screening \
            "[getCrystalNameForLog] videosnap $filePath"
        } errMsg]} {
            log_error "failed to save video snapshot: $errMsg"
            set screening_msg "error: snapshot failed"
            user_log_error screening \
            "[getCrystalNameForLog] videosnap $errMsg"
        }
    }

    ###save jpeg filename to be sent to SIL server later
switch -exact -- $m_currentAction {
    1 {
        ###### this is called in loopcenter when it is failed.
        ###### after this the sample will be dismount,
        ###### so no action needed.
    }
    3 {
        set m_jpeg1 $filePath
        checkFirstSnapshotForReOrient
    }
    6 {
        set m_jpeg2 $filePath
        doubleCheckSnapshotForReOrient
    }
    10 {
        set m_jpeg3 $filePath
        doubleCheckSnapshotForReOrient
    }
    default {
        log_severe NEED TO ADJUST CODE if screening parameter list changes
    }
}

sendResultUpdate videoSnapshot $subdir "${fileName}.jpg"

puts "SequenceDevice::doVideoSnapshot OK $filePath "
set screening_msg "snapshot OK"
}

# =======================================================================

::itcl::body SequenceDevice::doCollectImage { deltaPhi time nImages nameTag} {
global gMotorPhi
global gMotorEnergy
variable ::nScripts::screening_msg
variable ::nScripts::detectorType
puts "SequenceDevice::doCollectImage $deltaPhi $time $nImages $nameTag"

global gWaitForGoodBeamMsg

variable ::nScripts::runs

waitForMotorsForCollect

moveMotorsToDesiredPosition 

switch -exact -- $m_currentAction {
    4 {
        set group 1
    }
    7 {
        set group 2
    }
    11 {
        set group 3
    }
    default {
        set group -1
        log_severe NEED TO ADJUST CODE if screening parameter list changes
    }
}
if {$group > 0 && $group < 4 && \
[string is integer -strict $m_SILID] && \
($m_enableAddImage || $m_enableAnalyzeImage)} {
    if {[catch {
        #### only clear this image group
        set uniqueID [lindex $m_uniqueIDList $m_currentCrystal]
        clearCrystalImages $m_lastUserName $m_lastSessionID \
        $m_SILID $m_currentCrystal $group $uniqueID
    } errmsg]} {
        log_error clearCrystalImages $errmsg
    }
}

set runNumber 16
#set userName "gwolf"
set userName [get_operation_user]
set axisMotor $gMotorPhi
variable ::nScripts::$axisMotor

set subdir [getSubDirectory]
set directory [file join $m_directory $subdir]
set exposureTime $time
set delta $deltaPhi
set modeIndex $m_detectorMode
set useDose [lindex $runs 2]
set reuseDark 0

#### may not be necessary
set m_imgFileExtension [getImgFileExt]

set nFrames $nImages

    #loop over all remaining frames until this run is complete
    if { [catch {
        for { set iFrame 0} { $iFrame<$nFrames } { incr iFrame } {
            spinMsgLoop

            #Stop data collection now if we have been paused
            if { $m_keepRunning==0 } {
                puts "WARNING SequenceDevice::doCollectImage was stoped"
                return
            }

            #get the motor positions for this frame

            # get file name for the next image
            set fileCounter [getFileCounter $subdir $m_imgFileExtension]
            set filename [getImgFileName $nameTag $fileCounter]
            
            # wait for the detector to get into position if it was moving
            error_if_moving detector_z
            
            set gWaitForGoodBeamMsg screening_msg
            #If we lost beam then wait
            if { ![::nScripts::beamGood] } { 
                ::nScripts::wait_for_good_beam
            }
            doOptimizeTable

            #gw
            set expTime [namespace eval ::nScripts requestExposureTime_start $exposureTime $useDose]
            set gWaitForGoodBeamMsg ""
 
            set fullpath [file join $directory "${filename}.$m_imgFileExtension"]
            if {$group > 0 && $group < 4 && \
            [string is integer -strict $m_SILID] && \
            ($m_enableAddImage || $m_enableAnalyzeImage)} {
                lappend m_imageWaitingList $fullpath
            }

            ## refresh i2 and flux if possible
            if {[isIonChamber i2]} {
                read_ion_chambers i2
                wait_for_devices i2
                set i2_reading [get_ion_chamber_counts i2]
            } else {
                set i2_reading 0
            }

            if {[isMotor flux]} {
                variable ::nScripts::flux
                set flux_reading $flux
            } else {
                set flux_reading 0
            }

            set current_phi [user_log_get_motor_position $gMotorPhi]
            set current_energy [user_log_get_motor_position $gMotorEnergy]

            set screening_msg "collect $filename"
            set operationHandle [start_waitable_operation collectFrame \
                                             $runNumber \
                                             $filename \
                                             $directory \
                                             $m_lastUserName \
                                             $axisMotor \
                                             shutter \
                                             $delta \
                                             $expTime \
                                             $modeIndex \
                                             0 \
                                             $reuseDark \
                                             $m_lastSessionID \
                                             ]
            
            ######## info for collect ####
            ## Dose_mode may need change 
            ## once we move dose_move to non-global for screening.
            set situation [list \
                REORIENT_DIFF_FILENAME=$fullpath \
                REORIENT_DIFF_START_PHI=[set $axisMotor] \
                REORIENT_DIFF_DELTA=$delta \
                REORIENT_DIFF_EXPOSURE_TIME=$expTime \
                REORIENT_DIFF_ION_CHAMBER=$i2_reading \
                REORIENT_DIFF_FLUX=$flux_reading \
                REORIENT_DIFF_MODE=$modeIndex \
                REORIENT_DIFF_DOSE_MODE=$useDose \
            ]

            wait_for_operation $operationHandle
            set screening_msg "collected $filename"

            user_log_note screening "[getCrystalNameForLog] collect   $fullpath $current_phi deg"

            #gw
            sendResultUpdate collectImage $subdir "${filename}.$m_imgFileExtension"


            if {[string is integer -strict $m_SILID] && ($m_enableAddImage || $m_enableAnalyzeImage)} {
                ####### add image to SIL server           
                switch -exact -- $group {
                    1 {
                        set jpgPath $m_jpeg1
                        set m_img1 $fullpath
                        set m_info1 $situation
                        checkFirstSnapshotForReOrient
                    }
                    2 {
                        set jpgPath $m_jpeg2
                        set m_img2 $fullpath
                        set m_info2 $situation
                        doubleCheckSnapshotForReOrient
                    }
                    3 {
                        set jpgPath $m_jpeg3
                        set m_img3 $fullpath
                        set m_info3 $situation
                        doubleCheckSnapshotForReOrient
                    }
                }
                if {$group > 0 && $group < 4} {
                    if {[catch {
                        set uniqueID [lindex $m_uniqueIDList $m_currentCrystal]
                        addCrystalImage $m_lastUserName $m_lastSessionID $m_SILID $m_currentCrystal $group $fullpath $jpgPath $uniqueID
                    } errmsg]} {
                        log_error addCrystalImage $errmsg
                    }
                    if {$m_enableAnalyzeImage} {
                        if {[catch {
                            set uniqueID [lindex $m_uniqueIDList $m_currentCrystal]
                            analyzeCrystalImage $m_lastUserName $m_lastSessionID $m_SILID $m_currentCrystal $group $fullpath $m_beamlineName [getCrystalName] $uniqueID
                        } errmsg]} {
                            log_error analyzeCrystalImage $errmsg
                        }
                    }
                }
            };#if {$m_SILID != "old"}

        } ;# loop over all remaining frames until this run is complete

        spinMsgLoop
        #run is complete
        start_operation detector_stop

        if {[string is integer -strict $m_SILID] && $m_enableAutoindex} {
            if {[catch { doAutoindex } errmsg]} {
                log_error autoindex $errmsg
            }
        }

    } errorResult ] } {
        #handle every error that could be raised during data collection
        start_recovery_operation detector_stop
        #gw update_run $runNumber $nextFrame "paused"
        #gw return -code error $errorResult
        puts "ERROR SequenceDevice::doCollectImage $errorResult"
        log_error CollectImage $errorResult
        set screening_msg [list error: $errorResult]

        #if { [lsearch $errorResult aborted] >= 0 } {
        #    return -code error $errorResult
        #}
        #return
        return -code error $errorResult
    } ;# if error exception

puts "SequenceDevice::doCollectImage OK"
}
::itcl::body SequenceDevice::doExcitation { time_ nameTag_} {
    variable ::nScripts::screening_msg
   puts "SequenceDevice::doExcitation"
   variable ::nScripts::energy

    waitForMotorsForCollect

    set subdir [getSubDirectory]
   set directory [file join $m_directory $subdir]

   if { [catch {
      #check if we have been paused
      if { $m_keepRunning==0 } {
         puts "WARNING SequenceDevice::doExcitation was stopped"
         return
      }

    # get file name for the next image
    set fileCounter [getFileCounter $subdir "bip"]
    set filename [getImgFileName $nameTag_ $fileCounter]

    set screening_msg "excitation $filename"
    set exciteId [start_waitable_operation optimalExcitation \
    $m_lastUserName $m_lastSessionID $directory $filename \
    screening $energy $time_]

    wait_for_operation $exciteId
  
    wait_for_time 2000
    } errorResult ] } {
        set screening_msg "error: $errorResult"
        puts "ERROR SequenceDevice::doExcitationCollect $errorResult"
        return -code error $errorResult
    }
    set screening_msg "done excitation"

puts "SequenceDevice::doCollectImage OK"
}


# =======================================================================

::itcl::body SequenceDevice::doRotate { angle } {
global gMotorPhi
variable ::nScripts::screening_msg
puts "SequenceDevice::doRotate $angle"

error_if_moving $gMotorPhi

#move gonio_phi to $absAngle
set screening_msg "rotate sample"
move $gMotorPhi by $angle
wait_for_devices $gMotorPhi
set screening_msg "sample rotated"

global gDevice
set phi $gDevice($gMotorPhi,scaled)
puts "phi=$phi"

puts "SequenceDevice::doRotate OK"
}

# =======================================================================
### so user can access the ISampleMountingDevice
::itcl::body SequenceDevice::portJamUserAction { args } {
    puts "SequenceDevice::portJamUserAction $args"

    return [namespace eval ::nScripts ISampleMountingDevice_start portJamUserAction $args]
}

::itcl::body SequenceDevice::checkIfRobotResetIsRequired { } {
variable ::nScripts::screening_msg
puts "SequenceDevice::checkIfRobotResetIsRequired"

set oldRobotState $m_robotState

set errorFlag [catch {
    set m_robotState [namespace eval ::nScripts ISampleMountingDevice_start getRobotState]
} errorText]
puts "SequenceDevice::checkIfRobotResetIsRequired() done $errorText"
if { $errorFlag } {
    puts "ERROR SequenceDevice::checkIfRobotResetIsRequired() $errorText"
    log_error "Screening ISampleMountingDevice error: $errorText"
    set m_robotState "1"
}
if { [string length $m_robotState]>6 } {
    puts "ERROR SequenceDevice::checkIfRobotResetIsRequired() ISampleMountingDevice returned robotState=$m_robotState"
    set m_robotState "1"
}

if { $oldRobotState==$m_robotState } {
    puts "SequenceDevice::checkIfRobotResetIsRequired OK $m_robotState"
    return $m_robotState
}
#send_operation_update "setConfig robotState $m_robotState"
if { $m_robotState>0 } {
    set m_keepRunning 0
    log_error "screening aborted: robot not ready check robot status"
    set screening_msg "error: robot status"
}
puts "SequenceDevice::checkIfRobotResetIsRequired OK $m_robotState"
return $m_robotState
}


# =======================================================================

::itcl::body SequenceDevice::sendResultUpdate { operation subdir fileName } {
puts "SequenceDevice::sendResultUpdate $operation $subdir $fileName "

send_operation_update [list result $operation $subdir $fileName]
}

# =======================================================================
# =======================================================================
# =======================================================================
# =======================================================================

puts "SequenceDevice.tcl loaded successfully"

#this updates the system string so that all clients can see the new state
::itcl::body SequenceDevice::updateCrystalSelectionListString {} {
    variable ::nScripts::crystalSelectionList
    
    set crystalSelectionList [list $m_currentCrystal $m_nextCrystal $m_crystalListStates]

    set lockKey ""
    if {[catch {
        if {[isOperation moveCrystal] && [operation_running moveCrystal]} {
            variable ::nScripts::moveCrystal_lastKey

            set lockKey $moveCrystal_lastKey

            puts "using moveCrystal lockKey: $lockKey"
        }
    } errMsg]} {
        puts "update select: try to get lockKey failed: $errMsg"
    }


    if {[string is integer -strict $m_SILID] && $m_SILID > 0} {
        set data [list attrName selected attrValues $m_crystalListStates]
        set data [eval http::formatQuery $data]
        if [catch {
            setSpreadsheetAttribute $m_lastUserName $m_lastSessionID $m_SILID $data $lockKey
        } errMsg] {
            log_error save selected to spreadsheet failed: $errMsg
        }
    }
}
::itcl::body SequenceDevice::loadCrystalSelectionListString {} {
    variable ::nScripts::crystalSelectionList
    variable ::nScripts::robot_status

    set m_currentCrystal [lindex $crystalSelectionList 0]
    set m_nextCrystal [lindex $crystalSelectionList 1]
    set m_crystalListStates [lindex $crystalSelectionList 2]

    set sample_on_gonio [lindex $robot_status 15]
    if {$sample_on_gonio != ""} {
        set m_currentCassette [lindex $sample_on_gonio 0]
        set m_currentRow [lindex $sample_on_gonio 1]
        set m_currentColumn [lindex $sample_on_gonio 2]
    } else {
        set m_currentCassette n
        set m_currentRow 0
        set m_currentColumn N
    }
}
#this updates the system string so that all clients can see the new state
::itcl::body SequenceDevice::updateScreeningActionListString {} {
    variable ::nScripts::screeningActionList
    set screeningActionList [list $m_isRunning $m_currentAction $m_nextAction $m_actionListStates]
}

#this updates the system string so that all clients can see the new state
::itcl::body SequenceDevice::updateScreeningParametersString { } {
    variable ::nScripts::screeningParameters
    if {[llength $screeningParameters] >= 5} {
        set screeningParameters [list $m_actionListParameters $m_detectorMode $m_directory $m_distance $m_beamstop $m_attenuation]
    } else {
        set screeningParameters [list $m_actionListParameters $m_detectorMode $m_directory]
    }
}

#fields: mounted, next, robot flag
::itcl::body SequenceDevice::updateCrystalStatusString { } {
    variable ::nScripts::crystalStatus

    if { $m_currentCrystal >= 0 } {
        set cur_port [getCurrentPortID]
        set enable_dismount 1
        set cur_sub_dir [lindex $m_crystalDirList $m_currentCrystal]
        set cur_gridSampleLocation \
        [lindex $m_gridSampleLocationList $m_currentCrystal]
    } elseif {$m_currentCassette != "n" && \
    $m_currentColumn != "N" && \
    $m_currentRow != "0"} {
        ### must be manual mode
        set cur_port $m_currentCassette$m_currentColumn$m_currentRow
        set enable_dismount 1
        set cur_sub_dir .
        set cur_gridSampleLocation ""
    } else {
        set cur_port {}
        set enable_dismount 0
        set cur_sub_dir {}
        set cur_gridSampleLocation ""
    }

    if { $m_nextCrystal < 0 } {
        set next_port {}
    } else {
        set next_port [getNextPortID]
    }
    if { $m_useRobot } {
        set robotFlag robot
    } else {
        set robotFlag manual 
    }
    set crystalStatus [list $cur_port $next_port $robotFlag $enable_dismount $cur_sub_dir $m_isSyncedWithRobot $m_sampleReOriented $cur_gridSampleLocation]
}
::itcl::body SequenceDevice::loadCrystalStatusString { } {
    variable ::nScripts::crystalStatus

    #log_note "string: $crystalStatus"
    
    if {[lindex $crystalStatus 2] == "robot"} {
        #log_note "set to use robot from string"
        set m_useRobot 1
    } else {
        #log_note "set to use mamual from string"
        set m_useRobot 0
    }

    if {[lindex $crystalStatus 6] == "1"} {
        #log_note "set to use robot from string"
        set m_sampleReOriented 1
    } else {
        #log_note "set to use mamual from string"
        set m_sampleReOriented 0
    }
}
::itcl::body SequenceDevice::reset { args } {
    variable ::nScripts::collect_default
    if {[llength $collect_default] < 2} {
        set collect_parameters [list 1.0 2.0]
    } else {
        set collect_parameters [lrange $collect_default 0 1]
    }

    setConfig useRobot 1

    setConfig detectorMode [::nScripts::getDetectorDefaultModeIndex] $args
    setConfig actionListParameters [list \
    {MountNextCrystal {}} \
    {LoopAlignment 0} \
    {Pause {}} \
    {VideoSnapshot {1.0 0deg}} \
    "CollectImage {$collect_parameters 1 {}}" \
    {Rotate 90} \
    {VideoSnapshot {1.0 90deg}} \
    "CollectImage {$collect_parameters 1 {}}" \
    {Pause {}} \
    {Rotate -45} \
    {VideoSnapshot {1.0 45deg}} \
    "CollectImage {$collect_parameters 1 {}}" \
    {ExcitationScan {10.0 test}} \
    {ReOrient {}} \
    {RunQueueTask {}} \
    {Pause {}}] $args

    setConfig actionListStates [list 1 1 0 1 1 1 1 1 0 0 0 0 0 0 0 0]

    if {[llength $collect_default] > 2} {
        set att [lindex $collect_default 2]
        setConfig attenuation $att $args
    }
    set m_lastUserName [get_operation_user]
    if {[string first $m_lastUserName $m_directory] < 0} {
        setConfig directory /data/$m_lastUserName $args
    }
}

#this compares current crystal with what is mounted on goniometer
::itcl::body SequenceDevice::syncWithRobot { { try_to_sync 0 } args } {
    variable ::nScripts::robot_cassette
    variable ::nScripts::robot_status
    variable ::nScripts::screening_msg
    variable ::nScripts::scn_crystal_msg

    checkInitialization

    set sessionID [lindex $args end]
    if {$sessionID != ""} {
        set m_lastSessionID $sessionID
        puts "syncWithRobot sessionID [SIDFilter $m_lastSessionID]"
        set m_lastUserName [get_operation_user]

        variable ::nScripts::screening_user
        set screening_user $m_lastUserName
    }

    if {$try_to_sync == ""} {
        set try_to_sync 0
    }

    #get what's on the goniometer
    set sample_on_gonio [lindex $robot_status 15]

    ################## check cassette  ##################
    set index [lindex $m_cassetteInfo 1]
    #if not l m r  cassette, we ignore robot
    if {$index <= 0 || $index > 3} {
        if {$sample_on_gonio != ""} {
            if {$try_to_sync} {
                set screening_msg "error: not robot cassette"
                set scn_crystal_msg "error: not robot cassette"
                log_error "try to sync with robot failed, not robot cassette"
            }
            set m_isSyncedWithRobot no
            updateCrystalStatusString 
            return 0
        } else {
            if {$m_currentCrystal < 0} {
                set m_isSyncedWithRobot yes
                updateCrystalStatusString 
                return 1
            }
            if {!$try_to_sync} {
                set m_isSyncedWithRobot no
                updateCrystalStatusString 
                return 0
            }
            set m_currentCrystal -1
            set m_currentCassette n
            set m_currentColumn N
            set m_currentRow 0
            set m_isSyncedWithRobot yes
            updateCrystalSelectionListString
            updateCrystalStatusString 
            set screening_msg "sync: current cleared"
            set scn_crystal_msg "sync warning: current cleared"
            log_warning "sync with robot: current crystal cleared"
            return 1
        }
    }
    #check if cassette is absent
    set cur_cassette [lindex {0 l m r} $index]
    set cassette_index [expr "97 * ($index - 1)"]
    set cassette_status [lindex $robot_cassette $cassette_index]
    if {$cassette_status == "0"} {
        if {$try_to_sync} {
            set screening_msg "error: cassette $cur_cassette absent"
            set scn_crystal_msg "error: cassette $cur_cassette absent"
            log_error "try to sync with robot failed: cassette $cur_cassette absent"
        }
        set m_isSyncedWithRobot no
        updateCrystalStatusString 
        return 0
    }

    if {$sample_on_gonio != ""} {
        set gonio_cassette [lindex $sample_on_gonio 0]
        set gonio_row [lindex $sample_on_gonio 1]
        set gonio_column [lindex $sample_on_gonio 2]
    } else {
        set gonio_cassette $cur_cassette
        set gonio_row 0
        set gonio_column N
    }
    ######### compare current crystal with sample on goniometer ####
    #gether information
    if {$m_currentCrystal >= 0} {
        #get current port ID
        set cur_port [lindex $m_crystalPortList $m_currentCrystal]
        if { [string length $cur_port]>1 } {
            set cur_column [string index $cur_port 0]
            set cur_row [string range $cur_port 1 end]
        } else {
            if {!$try_to_sync} {
                set m_isSyncedWithRobot no
                updateCrystalStatusString 
                return 0
            }
            if {$sample_on_gonio == ""} {
                set port_status -
            } else {
       	        set screening_msg "error: currentt=$cur_port"
       	        set scn_crystal_msg "error: bad currentt=$cur_port"
                log_error "try to sync with robot failed: current_port=$cur_port"
                return 0
            }
        }
        set port_status [getCrystalStatus $m_currentCrystal]
    } else {
        set cur_row 0
        set cur_column N
        set port_status -
    }

    #compare
    if {$sample_on_gonio == ""} {
        #nothing on goniometer, always return 1
        if {$m_currentCrystal >= 0 && $port_status != "0"} {
            # not caused by empty port
            if { !$try_to_sync } {
                set m_isSyncedWithRobot no
                updateCrystalStatusString 
                return 0
            }

            #try to sync with robot: clear current sample
            set screening_msg "sync: current cleared"
            set scn_crystal_msg "sync warning: current cleared"
            log_warning "sync with robot: m_currentCrystal cleared"
        }
        set m_currentCrystal -1
        set m_currentCassette n
        set m_currentColumn N
        set m_currentRow 0
        set m_nextCrystal [getNextCrystal $m_nextCrystal]
        set m_isSyncedWithRobot yes
        updateCrystalSelectionListString
        updateCrystalStatusString 
        return 1
    } else {
        if {$cur_cassette == $gonio_cassette && $cur_row == $gonio_row && $cur_column == $gonio_column} {
            set m_isSyncedWithRobot yes
            updateCrystalStatusString 
            return 1
        } else {
            if { !$try_to_sync } { 
                set m_isSyncedWithRobot no
                updateCrystalStatusString 
                return 0 
            }
            set m_currentCassette $gonio_cassette
            set m_currentColumn $gonio_column
            set m_currentRow $gonio_row
            #try to sync with robot: change current and next crystal
            #must have the same cassette, otherwise panic
            if {$cur_cassette != $gonio_cassette} {
                set screening_msg "error: cassettes mismatch"
                set scn_crystal_msg "error: cassettes mismatch"
                log_error "try to sync with robot failed: cassettes mismatch between selection and the sample on goniometer"
                log_error "current cassette in screening: $cur_cassette"
                log_error "cassette of sample on goniometer: $gonio_cassette"
                set m_isSyncedWithRobot no
                updateCrystalStatusString 
                return 0
            }
            #try to find whether the sample on goniometer is on the list
            set sampleIndex [getCrystalIndex $gonio_row $gonio_column]
            if {$sampleIndex < 0} {
                set screening_msg "error: sample not on the list"
                set scn_crystal_msg "error: sample not on the list"
                log_error "try to sync with robot failed: sample on goniometer is not on the crystal list"
                log_error "sample on goniometer: $sample_on_gonio"
                set m_isSyncedWithRobot no
                updateCrystalStatusString 
                return 0
            }
            #set current and next crystal according to what's on the gonio
            set old_current $m_currentCrystal
            set old_next $m_nextCrystal
            set oldCurrentID [getCurrentPortID]
            set oldNextID [getNextPortID]

            set m_currentCrystal $sampleIndex
            set m_crystalListStates [lreplace $m_crystalListStates \
            $m_currentCrystal $m_currentCrystal 1]
            set m_nextCrystal [getNextCrystal [expr $m_currentCrystal + 1]]
            set m_isSyncedWithRobot yes

            updateCrystalSelectionListString
            updateCrystalStatusString 

            #generate warning message
            set newCurrentID [getCurrentPortID]
            set newNextID [getNextPortID]

            set warning_msg "sync warning: current: $oldCurrentID => $newCurrentID"
            if {$old_next != $m_nextCrystal} {
                append warning_msg " next: $oldNextID => $newNextID"
            }
            set screening_msg $warning_msg
            set scn_crystal_msg $warning_msg
            log_warning $warning_msg
            puts "sync: current: $old_current => $m_currentCrystal next: $old_next => $m_nextCrystal"
            return 1
        }
    }
}

::itcl::body SequenceDevice::getCrystalStatus { spreadsheet_index } {
    variable ::nScripts::robot_cassette

    set portIndex [lindex $m_indexMap $spreadsheet_index]

    if {![string is digit $portIndex]} {
        puts "portIndex $portIndex is not digit in getCrytalStatus $spreadsheet_index"
        puts "indexmap: $m_indexMap"
        return -
    }
    
    if {$portIndex < 0} {
        puts "portIndex $portIndex < 0"
        puts "indexmap: $m_indexMap"
        return -
    }

    set portStatus [lindex $robot_cassette $portIndex]

    if {$portStatus == ""} {
        puts "port status return empty"
        puts "portindex: $portIndex"
        puts "status: $robot_cassette"
        set portStatus -
    }
    return $portStatus
}
::itcl::body SequenceDevice::getPortIndexInCassette { cassette row column } {
    variable ::nScripts::robot_cassette

    set casIndex [lsearch -exact {l m r} $cassette]
    set CIndex [lsearch -exact {A B C D E F G H I J K L} $column]
    set RIndex $row
    if { $casIndex < 0 || $CIndex < 0 } { return -1 }

    set cassette_index [expr 97 * $casIndex]
    set cassette_status [lindex $robot_cassette $cassette_index]
    switch -exact -- $cassette_status {
        3 {
            return [expr "97 * $casIndex + 16 * $CIndex + $RIndex"]
        }
        default {
            return [expr "97 * $casIndex + 8 * $CIndex + $RIndex"]
        }
    }
}
::itcl::body SequenceDevice::getPortStatus { cassette row column } {
    variable ::nScripts::robot_cassette

    set portIndex [getPortIndexInCassette $cassette $row $column]
    
    if {$portIndex < 0} { return - }

    set portStatus [lindex $robot_cassette $portIndex]

    if {$portStatus == ""} {
        set portStatus -
    }
    return $portStatus
}
#search the crystal list and try to find the port.
#return -1 if the crystal is not on the list
::itcl::body SequenceDevice::getCrystalIndex { row column } {
    set port_name $column$row
    return [lsearch -exact $m_crystalPortList $port_name]
}

#check whether action selection is OK
#must have at least one of "stop" or "mountnext"
::itcl::body SequenceDevice::actionSelectionOK {} {
    variable ::nScripts::scn_action_msg
    variable ::nScripts::lc_error_threshold

    #mount must be first if no current sample
    if {$m_currentCrystal < 0 && $m_currentAction != 0} {
        set mountNextSelected [lindex $m_actionListStates 0]
        if {$m_nextAction != 0 || !$mountNextSelected} {
            log_error "must mount a sample first"
            set scn_action_msg "error: must mount a sample first"

            #####do it for the user
            if {!$mountNextSelected} {
                set m_actionListStates [lreplace $m_actionListStates 0 0 1]
                #send_operation_update "setConfig actionListStates $m_actionListStates"
                log_error selected Mount Next Crystal
            }
            if {$m_nextAction != 0} {
                set m_nextAction 0
                #send_operation_update "setConfig nextAction $m_nextAction"
                log_error moved Begin-> to Mount Next Crystal
            }

            log_warning Please check the Action Selection and start again
            return 0
        }
    }

    if {![info exists lc_error_threshold] \
    || [lindex $lc_error_threshold 0] != "0"} {
        ##### if loopCenter unselected, the Stop after it will
        ##### be selected automatically.
        set selectedLoopCenter   [lindex $m_actionListStates 1]
        set selectedStop         [lindex $m_actionListStates 2]
        if {!$selectedLoopCenter && !$selectedStop} {
            set m_actionListStates [lreplace $m_actionListStates 2 2 1]
            log_error Stop automatically selected \
            because Loop Alignment is not selected
        }
    }

    
    ##### may be TEMP
    set selectedReOrient     [lindex $m_actionListStates 13]
    set selectedRunQueueTask [lindex $m_actionListStates 14]
    if {!$m_enableReOrient} {
        if {$selectedReOrient == "1" || $selectedRunQueueTask == "1"} {
            log_error should not select ReOrient or RunQueueTask, not enabled
            return 0
        }
    } else {
        if {$selectedReOrient == "1" || $selectedRunQueueTask == "1"} {
            set selected1 [lindex $m_actionListStates 4]
            set selected2 [lindex $m_actionListStates 7]
            set selected3 [lindex $m_actionListStates 11]
            set selected4 [lindex $m_actionListStates 12]
            if {$selected1 || $selected2 || $selected3 || $selected4} {
                log_error Please deselect other actions first \
                before selecte ReOrient or RunQueueTask.
                return 0
            }

            if {$selectedReOrient != "1"} {
                log_error must select ReOrient to RunQueueTask
                return 0
            }

            if {$m_ReOrientableIndex < 0 || \
            $m_ReOrientInfoIndex < 0 || \
            $m_ReOrientPhiIndex  < 0} {
                log_error old spreadsheet, not surpporting sample queuing
                return 0
            }
        }
    }

    set move_OK 0
    set record_OK 0
        
    set n [llength $m_actionListStates]
    for {set i 0} {$i<$n} {incr i} {
        set state [lindex $m_actionListStates $i]
        if { $state==1 } {
            set action [lindex $m_actionListParameters $i]
            set actionClass [lindex $action 0]
            switch -exact -- $actionClass {
                MountNextCrystal {
                    set move_OK 1
                }
                Pause {
                    set move_OK 1
                    set record_OK 1
                }
                VideoSnapshot {
                    set record_OK 1
                }
                CollectImage {
                    set record_OK 1
                }
                ExcitationScan {
                    set record_OK 1
                }
                ReOrient {
                    ### remove after DEBUG TESTING
                    set record_OK 1
                }
                RunQueueTask {
                    set record_OK 1
                }
            }
        }
    }

    if { $move_OK && $record_OK } {
        set scn_action_msg "action selection OK"
        return 1
    } else {
        log_error "screening error: must have stop or mount+image"
        set scn_action_msg "error: must have stop or mount+image"
        return 0
    }
}
::itcl::body SequenceDevice::crystalSelectionOK {} {
    variable ::nScripts::scn_crystal_msg

    if {![checkCrystalList m_crystalListStates]} {
        return 0
    }
    if {$m_currentCrystal < 0 && [lsearch -exact $m_crystalListStates 1] < 0} {
        set scn_crystal_msg "error: must select at least one crystal"
        return 0
    }

    return 1
}
::itcl::body SequenceDevice::checkActionSelection { varName } {
    variable ::nScripts::lc_error_threshold

    upvar $varName result

    puts "checkActionSelection $result"

    set anyChange 0

    if {![info exists lc_error_threshold] \
    || [lindex $lc_error_threshold 0] != "0"} {
        set selectedLoopAlignment [lindex $result 1]
        set selectedStop           [lindex $result 2]
        set currentLoopAlignment    [lindex $m_actionListStates 1]
        set currentStop            [lindex $m_actionListStates 2]
        if {!$selectedLoopAlignment && $currentLoopAlignment && !$currentStop} {
            set result [lreplace $result 2 2 1]
            incr anyChange
        }
        if {!$selectedStop && $currentStop && !$currentLoopAlignment} {
            set result [lreplace $result 1 1 1]
            incr anyChange
        }
    }

    set ll [llength $result]
    if {$ll < 15} {
        return $anyChange
    }

    set selectedReOrient     [lindex $result 13]
    set selectedRunQueueTask [lindex $result 14]
    set currentReOrient      [lindex $m_actionListStates 13]
    set currentRunQueueTask  [lindex $m_actionListStates 14]
    if {!$m_enableReOrient} {
        if {$selectedReOrient == "1" || $selectedRunQueueTask == "1"} {
            log_error cannot select ReOrient or RunQueueTask, not enabled
            set result [lreplace $result 13 14 0 0]
            return 1
        }
        return 0
    }

    ## OK, reorient enabled
    set selectedNormal [lrange $result 3 12]

    set currentNormal  [lrange $m_actionListStates 3 12]

    if {$selectedNormal != $currentNormal} {
        if {$selectedReOrient == "1" || $selectedRunQueueTask == "1"} {
            log_warning deselected Crystal Queue Actions
            set result [lreplace $result 13 14 0 0]
            return 1
        }
        return 0
    }

    set anyChange 0

    if {(!$currentReOrient && $selectedReOrient) || \
    (!$currentRunQueueTask && $selectedRunQueueTask)} {
        if {$selectedNormal != "0 0 0 0 0 0 0 0 0 0"} {
            log_warning deselected Normal Actions for Queue Actions
            set result [lreplace $result 3 12 0 0 0 0 0 0 0 0 0 0]
            set anyChange 1
        }
    }

    if {$selectedRunQueueTask && !$selectedReOrient} {
        log_warning must select ReOrient for RunQueueTask
        set result [lreplace $result 13 14 1 1]
        set anyChange 1
    }

    return $anyChange
}

::itcl::body SequenceDevice::checkCrystalList { varName } {
    variable ::nScripts::scn_crystal_msg

    set noChange 1

    upvar $varName result

    ################## check cassette  ##################
    set index [lindex $m_cassetteInfo 1]
    if {$index == 0 || $index > 3} {
        puts "checkCrystalList no change index 0 or >3"
        set scn_crystal_msg "warning: no check for no-robot cassette"
        return 1
    }
    set cur_cassette [lindex "0 l m r" $index]

    set n [llength $result]

    if {$m_spreadsheetStatus <= 0} {
        set tsNow [clock seconds]

        if {$tsNow >= $m_tsNextSevereMsg} {
            log_severe dcss still trying to load spreadsheet

            set delay [expr pow(2, $m_cntSevereMsg) * $INIT_SEVERE_MSG_INTERVAL]
            if {$delay > $MAX_SEVERE_MSG_INTERVAL} {
                set delay $MAX_SEVERE_MSG_INTERVAL
            }
            set m_tsNextSevereMsg [expr $tsNow + int($delay)]
            incr m_cntSevereMsg
        } else {
            log_error dcss still trying to load spreadsheet
        }
        return -code error "dcss spreadsheet not ready"
    }
    if {$n != $m_numRowParsed} {
        log_severe user selecting sample from a failed spreadsheet
        return -code error "BluIce using failed spreadsheet"
    }

    set currentPort ""
    set mountingPort ""
    if {$m_currentCrystal >= 0} {
        set currentPort [lindex $m_crystalPortList $m_currentCrystal]
    }
    if {$m_mountingCrystal >= 0} {
        set mountingPort [lindex $m_crystalPortList $m_mountingCrystal]
    }
    set reOrientSelected  [lindex $m_actionListStates 13]
    ################## check spreadsheet crystals ############
    for {set i 0} {$i<$n} {incr i} {
        set state [lindex $result $i]
        if {$state == 1} {
            set port [lindex $m_crystalPortList $i]
            set portID [lindex $m_crystalIDList $i]
            set ll_port [string length $port]
            if {$ll_port != 2 && $ll_port != 3} {
                set scn_crystal_msg "warning: $portID has bad name $port"
                set result [lreplace $result $i $i 0]
                puts "checkCrystalList turn off $i: bad port length"
                log_warning "screening: crystal $portID disabled because of bad port name $port"
                set noChange 0
                continue
            }
            set column [string index $port 0]
            set row [string range $port 1 end]
            if {[lsearch -exact {A B C D E F G H I J K L} $column] < 0} {
                set scn_crystal_msg "warning: $portID has bad column $column"
                set result [lreplace $result $i $i 0]
                puts "checkCrystalList turn off $i: bad column"
                log_warning "screening: crystal $portID disabled because of bad column $column"
                set noChange 0
                continue
            }
            if {[lsearch -exact {1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19} $row] < 0} {
                set scn_crystal_msg "warning: $portID has bad row $row"
                set result [lreplace $result $i $i 0]
                puts "checkCrystalList turn off $i: bad row"
                log_note "screening: crystal $portID disabled because of bad row $row"
                set noChange 0
                continue
            }
            ### deselect if not reorientable
            if {$m_enableReOrient && $reOrientSelected} {
                set re_orientable [lindex $m_reOrientableList $i]
                if {$re_orientable != "1"} {
                    set scn_crystal_msg "warning: $portID not re-orientable"
                    set result [lreplace $result $i $i 0]
                    puts "checkCrystalList turn off $i: not re-orientable"
                    log_error "screening: crystal $portID disabled because of not reorientable"
                    set noChange 0
                    continue
                }
            }
            #check port status if using robot
            if {!$m_useRobot} continue

            set port_status [getCrystalStatus $i]
            switch -exact -- $port_status {
                j {
                    set scn_crystal_msg "warning: $portID port jam"
                    set result [lreplace $result $i $i 0]
                    puts "checkCrystalList turn off $i: port jam"
                    log_error "screening: crystal $portID disabled because of port jam"
                    set noChange 0
                    continue
                }
                b {
                    set scn_crystal_msg "warning: $portID bad port"
                    set result [lreplace $result $i $i 0]
                    puts "checkCrystalList turn off $i: bad port"
                    log_error "screening: crystal $portID disabled because of bad port"
                    set noChange 0
                    continue
                }
                - {
                    set scn_crystal_msg "warning: $portID port $port not exist"
                    set result [lreplace $result $i $i 0]
                    puts "checkCrystalList turn off $i: port not exist"
                    log_error "screening: crystal $portID disabled because of port not exist"
                    set noChange 0
                    continue
                }
                0 {
                    ### this assumed no repeat port
                    if {$i != $m_currentCrystal && $i != $m_mountingCrystal} {
                        if {$port != $currentPort && $port != $mountingPort} {
                            set scn_crystal_msg "warning: $portID empty port"
                            set result [lreplace $result $i $i 0]
                            puts "checkCrystalList turn off $i: empty port"
                            log_error "screening: crystal $portID disabled because of empty port"
                            set noChange 0
                        }
                        continue
                    }
                }
                m -
                1 -
                u -
                default {
                }
            }
        }
    }




    return $noChange
}

::itcl::body SequenceDevice::listIsUnique { list_to_check } {
    set raw_l [llength $list_to_check]
    if {$raw_l < 2} {
        return 1
    }

    set unique_l [llength [lsort -unique $list_to_check]]
    if {$unique_l >= $raw_l} {
        return 1
    } else {
        return 0
    }
}

#go through selected actions and check their parameters
::itcl::body SequenceDevice::actionParametersOK { varName fixIt} {
    upvar $varName action_parameters 
    variable ::nScripts::scn_action_msg
    variable ::nScripts::collect_default

    set checkOK 1
    set index -1
    foreach action $action_parameters {
        incr index
        set selected [lindex $m_actionListStates $index]
        #puts "action $action selected: $selected"

        if {!$selected} {
            continue
        }
        set actionClass [lindex $action 0]
        set params [lindex $action 1]
        #puts "actionClass {$actionClass}"
        #puts "param: $params"
        switch -exact -- $actionClass {
            MountNextCrystal {
                set num_cycle $params
                if {![string is integer $num_cycle]} {
                    if {!$fixIt} {
                        log_error "wash cycle must be an integer"
                        set scn_action_msg \
                        "error: wash cycle must be an integer"
                    } else {
                        set num_cycle 0
                        log_warning "wash cycle changed to $num_cycle"
                    }
                    set checkOK 0
                }
                if {!$checkOK && $fixIt} {
                    set params $num_cycle
                }
            }
            VideoSnapshot {
                foreach {zoom nameTag} $params break
				if {[motor_exists camera_zoom]} {
                    puts "motor camera_zoom exists"
                	if {$zoom == ""} {
                        if {!$fixIt} {
                    	    log_error \
                            "must have a zoom value for $index $actionClass"
                    	    set scn_action_msg "error: no zoom value"
                        } else {
                    	    log_warning \
                            "must have a zoom value for $index $actionClass"
                            foreach {lowerLimit upperLimit} \
                            [getGoodLimits camera_zoom] break

                            set zoom $upperLimit
                            log_warning zoom changed to $zoom 
                        }
                    	set checkOK 0
                	} elseif {[catch {
                        assertMotorLimit camera_zoom $zoom
                    } dummy]} {
                        if {!$fixIt} {
                    	    log_error \
                            "zoom out of soft limit for $index $actionClass"
                    	    set scn_action_msg "error: bad zoom value"
                        } else {
                    	    log_warning \
                            "zoom out of soft limit for $index $actionClass"
                            foreach {lowerLimit upperLimit} \
                            [getGoodLimits camera_zoom] break

                            set zoom $upperLimit
                            log_warning zoom changed to $zoom
                        }
                    	set checkOK 0
                	}
				}
                #if {$nameTag == ""} {
                #    set scn_action_msg "error: no name tag"
                #    log_error "must have a nameTag for $index $actionClass"
                #    set checkOK 0
                #}
                if {!$checkOK && $fixIt} {
                    set params [list $zoom $nameTag]
                }
            }
            CollectImage {
                if {[isString collect_default]} {
                    foreach {defDelta defTime defAtt tMin tMax} $collect_default break
                } else {
                    set defDelta 0.01
                    set defTime 1.00
                    set defAtt 0
                    set tMin 1
                    set tMax 2000
                }

                foreach {deltaPhi time nImages nameTag} $params break
                puts "collectImage: $deltaPhi $time"
                if {$deltaPhi == ""} {
                    if {!$fixIt} {
                        set scn_action_msg "error: no deltaPhi"
                        log_error "must have a deltaPhi for $index $actionClass"
                    } else {
                        log_warning \
                        "must have a deltaPhi for $index $actionClass"
                        set deltaPhi $defDelta
                        log_warning "deltaPhi changed to $deltaPhi"
                    }
                    set checkOK 0
                } elseif {$deltaPhi <= 0.0} {
                    if {!$fixIt} {
                        set scn_action_msg "error: deltaPhi must be bigger than 0"
                        log_error "deltaPhi must be bigger than 0 for $index $actionClass"
                    } else {
                        log_warning \
                        "deltaPhi must be bigger than 0 for $index $actionClass"
                        set deltaPhi 0.01
                        log_warning "deltaPhi changed to $deltaPhi"
                    }
                    set checkOK 0
                } elseif {$deltaPhi > 179.99} {
                    if {!$fixIt} {
                        set scn_action_msg "error: deltaPhi must be smaller than 180"
                        log_error "deltaPhi must be  smaller than 180 for $index $actionClass"
                    } else {
                        log_warning \
                        "deltaPhi must be  smaller than 180 for $index $actionClass"
                        set deltaPhi 179.99
                        log_warning "deltaPhi changed to $deltaPhi"
                    }
                    set checkOK 0
                }

                if {$time == ""} {
                    if {!$fixIt} {
                        set scn_action_msg "error: no time input"
                        log_error "must have a time for $index $actionClass"
                    } else {
                        log_warning "must have a time for $index $actionClass"
                        set time $defTime
                        log_warning time changed to $time
                    }
                    set checkOK 0
                } elseif {$time < $tMin} {
                    if {!$fixIt} {
                        set scn_action_msg "error: time must >= $tMin"
                        log_error "time must >= $tMin  for $index $actionClass"
                    } else {
                        set time $tMin
                        log_warning time changed to $time
                    }
                    set checkOK 0
                } elseif {$time > $tMax} {
                    if {!$fixIt} {
                        set scn_action_msg "error: time must <= $tMax"
                        log_error "time must <= $tMax  for $index $actionClass"
                    } else {
                        set time $tMax
                        log_warning time changed to $time
                    }
                    set checkOK 0
                }

                if {$nImages == ""} {
                    if {!$fixIt} {
                        set scn_action_msg "error: no nImages"
                        log_error "must have a nImages for $index $actionClass"
                    } else {
                        log_warning \
                        "must have a nImages for $index $actionClass"
                        set nImages 1
                        log_warning nImages changed to $nImages
                    }
                    set checkOK 0
                } elseif {$nImages <= 0} {
                    if {!$fixIt} {
                        set scn_action_msg "error: nImages must > 0"
                        log_error "nImages must > 0 for $index $actionClass"
                    } else {
                        log_warning "nImages must > 0 for $index $actionClass"
                        set nImages 1
                        log_warning nImages changed to $nImages
                    }
                    set checkOK 0
                }
                #if {$nameTag == ""} {
                #    set scn_action_msg "error: no name tag"
                #    log_error "must have a nameTag for $index $actionClass"
                #    set checkOK 0
                #}
                if {!$checkOK && $fixIt} {
                    set params [list $deltaPhi $time $nImages $nameTag]
                }
            }

            ExcitationScan {
                foreach {time nameTag} $params break

                if {$time == ""} {
                    if {!$fixIt} {
                        set scn_action_msg "error: no time input"
                        log_error "must have a time for $index $actionClass"
                    } else {
                        log_warning "must have a time for $index $actionClass"
                        set time 1.0
                        log_warning time changed to $time
                    }
                    set checkOK 0
                } elseif {$time <= 0.0} {
                    if {!$fixIt} {
                        set scn_action_msg "error: time must > 0"
                        log_error "time must > 0 for $index $actionClass"
                    } else {
                        log_warning "time must > 0 for $index $actionClass"
                        set time 1.0
                        log_warning time changed to $time
                    }
                    set checkOK 0
                }
                if {!$checkOK && $fixIt} {
                    set params [list $time $nameTag]
                }
            }

            Rotate {
                puts "Rotate: $params"
                set angle $params
                if {$angle == "" || $angle == 0} {
                    if {!$fixIt} {
                        set scn_action_msg "error: bad angle"
                        log_error "angle must not 0 for $index $actionClass"
                    } else {
                        log_warning "angle must not 0 for $index $actionClass"
                        set angle 45.0
                        log_warning angle changed to $angle
                    }
                    set checkOK 0
                }
                if {!$checkOK && $fixIt} {
                    set params $angle
                }
            }
        }
        if {!$checkOK && $fixIt} {
            set action [list $actionClass $params]
            set action_parameters \
            [lreplace $action_parameters $index $index $action]
        }
    }
    return $checkOK
}
::itcl::body SequenceDevice::getCurrentPortID { } {
    if {$m_currentCrystal < 0} {
        return ""
    }
    set cur_port [lindex $m_crystalIDList $m_currentCrystal]
    if {$cur_port == "" ||$cur_port == "null" || $cur_port == "NULL" || $cur_port == "0"} {
        append cur_port ([getCurrentRawPort])
    }
    return $cur_port
}
::itcl::body SequenceDevice::getNextPortID { } {
    if {$m_nextCrystal < 0} {
        return ""
    }
    set next_port [lindex $m_crystalIDList $m_nextCrystal]
    if {$next_port == "" ||$next_port == "null" || $next_port == "NULL" || $next_port == "0"} {
        append next_port ([getNextRawPort])
    }
    return $next_port
}
::itcl::body SequenceDevice::getCurrentRawPort { } {
    if {$m_currentCrystal < 0} return ""
        
    #get cassette name
    set current_index [lindex $m_cassetteInfo 1]
    set current_cassette [lindex {0 l m r} $current_index]

    set current_port [lindex $m_crystalPortList $m_currentCrystal]
    return "${current_cassette}$current_port"
}
::itcl::body SequenceDevice::getNextRawPort { } {
    if {$m_nextCrystal < 0} return ""
    #get cassette name
    set current_index [lindex $m_cassetteInfo 1]
    set current_cassette [lindex {0 l m r} $current_index]

    set next_port [lindex $m_crystalPortList $m_nextCrystal]
    return "${current_cassette}$next_port"
}
::itcl::body SequenceDevice::doManualMountCrystal { args } {
    variable ::nScripts::robot_status

    set m_reOrientSample 0
    if {[llength $args] > 2} {
        set v [lindex $args 1]
        if {$v == "1"} {
            set m_reOrientSample 1
        }
    }

    set port [lindex $args 0]
    set cassette [string index $port 0]
    set column [string index $port 1]
    set row [string range $port 2 end]

    ### in fact, not need
    checkCassettePermit $cassette

    ########## force use robot
    if {!$m_useRobot} {
        set m_useRobot 1
    }

    #want to make sure it will work even not synced with robot
    if {![syncWithRobot 1]} {
        set sample_on_gonio [lindex $robot_status 15]
        if {$sample_on_gonio != ""} {
            set m_currentCassette [lindex $sample_on_gonio 0]
            set m_currentRow [lindex $sample_on_gonio 1]
            set m_currentColumn [lindex $sample_on_gonio 2]
        } else {
            set m_currentCassette n
            set m_currentRow 0
            set m_currentColumn N
        }
        set m_currentCrystal -1
        updateCrystalStatusString
        #send_operation_update "setConfig currentCrystal $m_currentCrystal"
    }
    
    set spreadsheet_index [lindex $m_cassetteInfo 1]
    set spreadsheet_cassette [lindex {0 l m r} $spreadsheet_index]
    if {$cassette == "n" || \
    $column == "N" || \
    $row == 0 || \
    $spreadsheet_cassette != $cassette} {
        set m_mountingCrystal -1
    } else {
        set m_mountingCrystal [getCrystalIndex $row $column]
    }
    # call mountCrystal first, the ajdust m_currentCrystal
    mountCrystal $cassette $column $row 0
    set m_mountingCrystal -1

    if {($m_currentCassette == "n" && \
    $m_currentColumn == "N" && \
    $m_currentRow == 0) || $spreadsheet_cassette != $m_currentCassette} {
            set m_currentCrystal -1
    } else {
        set m_currentCrystal [getCrystalIndex $m_currentRow $m_currentColumn]
        updateBarcodeScanned $m_currentBarcode
    }
    #send_operation_update "setConfig currentCrystal $m_currentCrystal"
    syncWithRobot
    updateCrystalSelectionListString
    setStrategyFileName disMnted
}
::itcl::body SequenceDevice::doAutoindex { } {
    ##### collect image selection check ######
    set c1_selected [expr [lindex $m_actionListStates 4] ? 1 : 0]
    set c2_selected [expr [lindex $m_actionListStates 7] ? 1 : 0]
    set c3_selected [expr [lindex $m_actionListStates 11] ? 1 : 0]
    set is_stopped [expr [lindex $m_actionListStates 15] ? 1 : 0]

    set total [expr $c1_selected + $c2_selected +$c3_selected]
    if {$total < 2} {
        puts "only one collect image selected"
        return;# only one collect image selected
    }
    
    ##### images available check ##########
    set img1_available 0
    set img2_available 0
    set img3_available 0
    if {$c1_selected && $m_img1 != ""} {
        set img1_available 1
    }
    if {$c2_selected && $m_img2 != ""} {
        set img2_available 1
    }
    if {$c3_selected && $m_img3 != ""} {
        set img3_available 1
    }
    set total [expr $img1_available + $img2_available + $img3_available]
    if {$total < 2} {
        puts "not enough images available"
        return;# only one collect image selected
    }

    ###### angle check ##############
    set action [lindex $m_actionListParameters 5]
    set angle2 [lindex $action 1]
    set action [lindex $m_actionListParameters 9]
    set angle3 [lindex $action 1]

    #find max angle diff
    set diff12 0
    set diff13 0
    set diff23 0
    if {$img1_available && $img2_available} {
        set diff12 [angleSpan $angle2]
    }
    if {$img1_available && $img3_available} {
        set diff13 [angleSpan [expr $angle2 + $angle3]]
    }
    if {$img2_available && $img3_available} {
        set diff23 [angleSpan $angle3]
    }

    set max_diff $diff12
    set autoindexPair [list 1 2]
    if {$diff13 > $max_diff} {
        set max_diff $diff13
        set autoindexPair [list 1 3]
    }
    if {$diff23 > $max_diff} {
        set max_diff $diff23
        set autoindexPair [list 2 3]
    }
    if {$max_diff <= 5.0} {
        puts "angle diff < 5.0"
        return;# angle separation too small
    }
    puts "we using $autoindexPair to do autoindex"

    ################### Do it #######################################
    set index1 [lindex $autoindexPair 0]
    set index2 [lindex $autoindexPair 1]
    set image1 [set m_img$index1]
    set image2 [set m_img$index2]

    set autoindexInfo1 [string map {= _0=} [set m_info$index1]]
    set autoindexInfo2 [string map {= _1=} [set m_info$index2]]
	 
    set doStrategy "true"
    set strategyFileName [getStrategyFileName]
    set runName [getCrystalName]
    setStrategyFileName $strategyFileName $runName

    set re_orientable [lindex $m_reOrientableList $m_currentCrystal]
    if {$re_orientable != "1"} {
        set re_orientable 0
    }

    set uniqueID [lindex $m_uniqueIDList $m_currentCrystal]

    if {$m_enableReOrient && !$re_orientable} {
        doubleCheckSnapshotForReOrient

        set dir [getDirectory]

        saveReOrientInfo $dir \
        $autoindexInfo1 \
        $autoindexInfo2 \
        $m_jpeg_info_0 \
        $m_jpeg_info_1

        if {$SAVE_DEBUG_SNAPSHOT} {
            saveDebugSnapshots $dir profile_first
        }
        autoindexForPrepareReOrient $m_lastUserName $m_lastSessionID \
        $m_SILID $m_currentCrystal $uniqueID $image1 $image2 $m_beamlineName \
        $runName
    } else {
        autoindexCrystal $m_lastUserName $m_lastSessionID \
        $m_SILID $m_currentCrystal $uniqueID $image1 $image2 $m_beamlineName \
        $runName $doStrategy $strategyFileName
    }
    ####allow re autoindex for new images
    clearImages 0
}
::itcl::body SequenceDevice::handlePortStatusChangeEvent { args } {
    variable ::nScripts::robot_cassette

    log_note "port status change event called"
    if { $m_isInitialized==0 } {
        log_warning postpone port status update to initializaion
        return
    }

    ### if cassette status changed, we need to regenerate the map
    ### between spreadsheet row and robot_cassette
    set index [lindex $m_cassetteInfo 1]
    set cassette_index [expr "97 * ($index - 1)"]
    set cassette_status [lindex $robot_cassette $cassette_index]

    if {$m_currentCassetteStatus != $cassette_status} {
        set m_currentCassetteStatus $cassette_status
        #### here we only supply port list so the port_index is 0
        set m_indexMap [generateIndexMap $index 0 m_crystalPortList \
        $m_currentCassetteStatus]

        puts "re-map index: $m_indexMap"
    }

    if {![checkCrystalList m_crystalListStates]} {
        set m_nextCrystal [getNextCrystal $m_nextCrystal]
        updateCrystalSelectionListString
        updateCrystalStatusString 
    }
}
::itcl::body SequenceDevice::handleLastImageChangeEvent { args } {
    log_note "last image event called: waiting list {$m_imageWaitingList}"

    if {[llength $m_imageWaitingList] <= 0} {
        return
    }
    variable ::nScripts::lastImageCollected

    set index [lsearch -exact $m_imageWaitingList $lastImageCollected]
    if {$index < 0} {
        puts "last image: {$lastImageCollected} not found in waiting list: {$m_imageWaitingList}"
        return
    }
    if {$index != 0} {
        puts "last image: {$lastImageCollected} is not the first on in waiting list: {$m_imageWaitingList}"
        puts "all images before it skipped"
    }
    incr index
    set m_imageWaitingList [lrange $m_imageWaitingList $index end]

    start_operation image_convert $m_lastUserName $m_lastSessionID $lastImageCollected
    ##log_note start_operation image_convert $m_lastUserName $m_lastSessionID $lastImageCollected
}
::itcl::body SequenceDevice::handleCassetteListChangeEvent { args } {
    if {[::config getLockSILUrl] == ""} {
        ###### old server ######
        return
    }
    log_note "cassetteList called"

    variable ::nScripts::cassette_list

    if {![info exists cassette_list]} {
        log_error cassette_list not found in database
        return
    }

    if { $m_isInitialized==0 } {
        log_warning new cassette_list: $cassette_list
        log_warning postpone cassette list update to initializaion
        return
    }

    set local_copy [lindex $cassette_list 0]

    set m_cassetteInfo [lreplace $m_cassetteInfo 2 2 $local_copy]
    updateCassetteInfo
}
::itcl::body SequenceDevice::updateCassetteInfo { } {
    catch loadCrystalList

    saveStateToDatabaseString
    getConfig all
}
::itcl::body SequenceDevice::clearMounted { args } {
    puts "SequenceDevice::clearMounted $args"
    if { $m_isRunning==1 } {
        return -code error "SAM still running"
    }

    set sessionID [lindex $args end]
    if {$sessionID != ""} {
        set m_lastSessionID $sessionID
        puts "clearMounted sessionID [SIDFilter $m_lastSessionID]"
        set m_lastUserName [get_operation_user]

        variable ::nScripts::screening_user
        set screening_user $m_lastUserName
    }

    #### tell robot to clear mounted first
    set handle [start_waitable_operation robot_config clear_mounted]
    set result [wait_for_operation_to_finish $handle]

    #### clear 
    set m_currentCassette n
    set m_currentColumn N
    set m_currentRow 0
    updateAfterDismount
}
::itcl::body SequenceDevice::updateAfterDismount { } {
    if {$m_currentCrystal >= 0} {
        set m_crystalListStates \
        [lreplace $m_crystalListStates $m_currentCrystal $m_currentCrystal 0]

        if {!$m_useRobot} {
            set screening_msg "manual dismount"
            log_warning "If a sample is mounted, dismount it now"
        }
    }
    set m_currentCrystal -1
    set m_currentBarcode ""
    set m_sampleReOriented 0
    fillDefaultRunForAdjust
    updateCrystalSelectionListString
    updateCrystalStatusString 
    updateScreeningActionListString
    if {!$m_useRobot} {
        syncWithRobot
    } else {
        syncWithRobot $TRY_SYNC_WITH_ROBOT
    }

    if {[isOperation scan3DSetup]} {
        if {[catch {
            ### now we need the scan3DSetup operation.  BluIce needs it.
            set h [start_waitable_operation scan3DSetup clear]
            wait_for_operation_to_finish $h
        } errMsg]} {
            puts "rastering clear failed: $errMsg"
        }
    }
    if {[isOperation rasterRunsConfig]} {
        if {[catch {
            set h [start_waitable_operation rasterRunsConfig deleteAllRasters]
            wait_for_operation_to_finish $h
        } errMsg]} {
            puts "rasterRun clear failed: $errMsg"
        }
    }
    if {[isOperation spectrometerWrap]} {
        if {[catch {
            set h [start_waitable_operation spectrometerWrap clear_result_files]
            wait_for_operation_to_finish $h
        } errMsg]} {
            puts "microspec clear failed: $errMsg"
        }
    }
    if {[isOperation gridGroupConfig]} {
        if {[catch {
            set h [start_waitable_operation gridGroupConfig cleanup_for_dismount]
            wait_for_operation_to_finish $h
        } errMsg]} {
            puts "gridGroup clear failed: $errMsg"
        }
    }
}
::itcl::body SequenceDevice::getStrategyFileName { } {
    set timestamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
    set fileName "${m_SILID}_[getCrystalName]_${timestamp}.tcl"

    if {[catch {
        file mkdir $m_strategyDir
    } errMsg]} {
        log_error "failed to create the common strategy file directory $m_strategyDir: $errMsg"
    }
    if {[catch {
        file attributes $m_strategyDir -permissions 0777
    } errMsg]} {
        puts "failed to change permitssion of $m_strategyDir: $errMsg"
    }
    return [file join $m_strategyDir $fileName]
}
::itcl::body SequenceDevice::setStrategyFileName { fullPath {runName ""} } {
    variable ::nScripts::strategy_file

    if {![info exists strategy_file]} {
        puts "string strategy_file not exists"
        return
    }

    set ll [llength $strategy_file]
    switch -exact -- $ll {
        0 -
        1 {
            set strategy_file [list $fullPath $runName]
        }
        default {
            set strategy_file [lreplace $strategy_file 0 1 $fullPath $runName]
        }
    }
}
::itcl::body SequenceDevice::checkCassettePermit { cassette } {
    global gClientInfo
    variable ::nScripts::cassette_owner

    puts "checkCassettePermit $cassette"

    set operationHandle [lindex [get_operation_info] 1]
    set clientId [expr int($operationHandle)]
    set isStaff [set gClientInfo($clientId,staff)]

    puts "clientID: $clientId"
    puts "isStaff: $isStaff"

    if {$isStaff} return

    if {$cassette == ""} {
        return
    }

    switch -exact $cassette {
        0 -
        1 -
        2 -
        3 {
            set owner [lindex $cassette_owner $cassette]
        }
        l {
            set owner [lindex $cassette_owner 1]
        }
        m {
            set owner [lindex $cassette_owner 2]
        }
        r {
            set owner [lindex $cassette_owner 3]
        }
        b -
        n {
            ### dismount is allowed
            return
        }
        default {
            set owner [lindex $cassette_owner 0]
        }
    }
    puts "owner=$owner"
    puts "lastuser=$m_lastUserName"

    if {$owner == ""} {
        return
    }

    if {[lsearch -exact $owner $m_lastUserName] < 0} {
        log_error "cassette access denied: not owner"
        return -code error "cassette access denied, not owner"
    }
}
::itcl::body SequenceDevice::waitForMotorsForVideo { } {
    if {[catch {
        ####here we can also use the all moving motor list from system
        set movingMotors [namespace eval \
        ::nScripts ISampleMountingDevice_start getMovingBackMotorList]

        set waitingMotors {}
        foreach motor $m_motorForVideo {
            if {[lsearch -exact $movingMotors $motor] >= 0} {
                lappend waitingMotors $motor
            }
        }
        if {[llength $waitingMotors] > 0} {
            log_note waiting for $waitingMotors to complete moving
            eval wait_for_devices $waitingMotors
        }
    } errMsg]} {
        log_error $errMsg
    }
}
::itcl::body SequenceDevice::waitForMotorsForCollect { } {
    if {[catch {
        ####here we can also use the all moving motor list from system
        set movingMotors [namespace eval \
        ::nScripts ISampleMountingDevice_start getMovingBackMotorList]

        if {[llength $movingMotors] > 0} {
            log_note waiting for $movingMotors to complete moving
            eval wait_for_devices $movingMotors
        }
    } errMsg]} {
        log_error $errMsg
    }
}
::itcl::body SequenceDevice::doubleCheckSnapshotForReOrient { } {
        checkFirstSnapshotForReOrient
        checkSecondSnapshotForReOrient
}
::itcl::body SequenceDevice::saveBoxSnapshot { pathBox {pathRaw ""}} {
    set mySID $m_lastSessionID
    if {[string equal -length 7 $mySID "PRIVATE"]} {
        set mySID [string range $mySID 7 end]
    }

    set urlSOURCE [::config getSnapshotUrl]

    set urlTarget "http://[::config getImpDhsImpHost]"
    append urlTarget ":[::config getImpDhsImpPort]"
    append urlTarget "/writeFile?impUser=$m_lastUserName"
    append urlTarget "&impSessionID=$mySID"
    append urlTarget "&impWriteBinary=true"
    append urlTarget "&impBackupExist=true"
    append urlTarget "&impAppend=false"

    set urlTargetBox $urlTarget
    append urlTargetBox "&impFilePath=$pathBox"
    set cmd "java -Djava.awt.headless=true url $urlSOURCE [drawInfoOnVideoSnapshot] -o $urlTargetBox"

    if {$pathRaw != ""} {
        set urlTargetRaw $urlTarget
        append urlTargetRaw "&impFilePath=$pathRaw"

        append cmd " -oRaw $urlTargetRaw"
    }

    log_note cmd: $cmd
    set mm [eval exec $cmd]
    puts "saveRawAndBox result: $mm"
}
::itcl::body SequenceDevice::saveRawSnapshot { path } {
    set url [::config getSnapshotUrl]
    if { [catch {
        set token [http::geturl $url -timeout 12000]
    } err] } {
        set status "ERROR $err $url"
        set ncode 0
        set code_msg "get url failed for snapshot"
        set result ""
    } else {
        upvar #0 $token state
        set status $state(status)
        set ncode [http::ncode $token]
        set code_msg [http::code $token]
        set result [http::data $token]
        http::cleanup $token
    }

    if { $status!="ok" || $ncode != 200 } {
        set msg \
        "ERROR SequenceDevice::doVideoSnapshot http::geturl status=$status"
        puts $msg
        log_error "Screening saveRawSnapshot Web error: $status $code_msg"

        return -code error "web error: $status $code_msg"
    }

    if {[catch {
        impWriteFileWithBackup $m_lastUserName $m_lastSessionID $path $result
    } errMsg]} {
        log_error "Screening saveRawSnapshot failed $path: $errMsg"
        return -code error "error: writefile filed: $path: $errMsg"
    }
}
::itcl::body SequenceDevice::saveReOrientInfo { dir a1 a2 s1 s2 } {
    #global gMotorEnergy
    #global gMotorBeamWidth
    #global gMotorBeamHeight
    #global gMotorDistance
    #global gMotorBeamStop
    #variable ::nScripts::attenuation
    #variable ::nScripts::camera_zoom
    #variable ::nScripts::sampleScaleFactor
    #variable ::nScripts::detectorType
    
    ## we do not want to use counter for reorient
    set crystalName [getCrystalName]
    set fn [file join $dir ${crystalName}_reorient_info]

    ### save system snapshot first
    set contents [brief_dump_database]

    ### too bad we still need these because motor names are configurable
    #append contents "\nREORIENT_BEAMLINE=$m_beamlineName"
    #append contents "\nREORIENT_DETECTOR=$detectorType"
    #append contents "\nREORIENT_ENERGY=[set $gMotorEnergy]"
    #append contents "\nREORIENT_BEAM_WIDTH=[set $gMotorBeamWidth]"
    #append contents "\nREORIENT_BEAM_HEIGHT=[set $gMotorBeamHeight]"
    #append contents "\nREORIENT_DISTANCE=[set $gMotorDistance]"
    #append contents "\nREORIENT_BEAM_STOP=[set $gMotorBeamStop]"
    #append contents "\nREORIENT_ATTENUATION=$attenuation"
    #append contents "\nREORIENT_CAMERA_ZOOM=$camera_zoom"
    #append contents "\nREORIENT_SCALE_FACTOR=$sampleScaleFactor"
    foreach item $s_reorient_info_map {
        foreach {tag device} $item break
        variable ::nScripts::$device
        append contents "\n$tag=[set $device]"
    }

    ### need to save beam center position on the video
    ### so we can adjust if the new center moved
    set zoomMaxXAxis [::nScripts::getSampleCameraConstant zoomMaxXAxis]
    set zoomMaxYAxis [::nScripts::getSampleCameraConstant zoomMaxYAxis]
    append contents "\nBEAM_CENTER_ON_VIDEO_X=$zoomMaxXAxis"
    append contents "\nBEAM_CENTER_ON_VIDEO_Y=$zoomMaxYAxis"

    set c1 [join $a1 \n]
    set c2 [join $a2 \n]
    set c3 [join $s1 \n]
    set c4 [join $s2 \n]

    append contents "\n$c1\n$c2\n$c3\n$c4"
    impWriteFile $m_lastUserName $m_lastSessionID $fn $contents

    ################### tell sil to save default position info
    set data [generateDefaultPositionData $contents]
    ### save the path to SIL and clear the reorientable flag
    ### ReOrientable should always be 0 in adding
    lappend data ReOrientInfo $fn label default
    set data [eval http::formatQuery $data]

    if {[catch {
        set uniqueID [lindex $m_uniqueIDList $m_currentCrystal]
        addDefaultRepositionForQueue $m_lastUserName $m_lastSessionID \
        $m_SILID $m_currentCrystal $uniqueID $data
    } errMsg]} {
        log_error failed to save ReOrientInfo and defaultPosition: $errMsg
    }
}
::itcl::body SequenceDevice::readReOrientInfo { } {
    array unset m_reorient_info_array

    set fn [lindex $m_reOrientInfoList $m_currentCrystal]
    if {$fn == ""} {
        log_error no re-orient infomation available for this sample
        return -code error not_avaialble 
    }

    set contents [impReadFile $m_lastUserName $m_lastSessionID $fn]
    parseReOrientInfo $contents m_reorient_info_array
}
::itcl::body SequenceDevice::generateDefaultPositionData { contents_ } {
    array set local_array [list]

    parseReOrientInfo $contents_ local_array

    set result [list]
    foreach item $s_position2reorient_map {
        set name [lindex $item 0]
        set tag  [lindex $item 1]
        set value $local_array($tag)
        lappend result $name $value
    }
    return $result
}
::itcl::body SequenceDevice::fillDefaultRunForAdjust { } {
    if {!$m_enableReOrient} {
        return
    }
    variable ::nScripts::run_for_adjust_default
    variable ::nScripts::run_for_adjust

    ### run_id must be -1 so that BluIce will not try to access sil

    if {$m_SILID < 0} {
        puts "cleared run_for_adjust by silid"
        set contents $run_for_adjust_default
        ::DCS::RunFieldForQueue::setList contents \
        sil_id -1 \
        row_id -1 \
        run_id -1 \
        status no_sil

        set run_for_adjust_default $contents
        set run_for_adjust         $contents
        return
    }
    if {$m_currentCrystal < 0} {
        puts "cleared run_for_adjust by current crystal"
        set contents $run_for_adjust_default
        ::DCS::RunFieldForQueue::setList contents \
        sil_id -1 \
        row_id -1 \
        run_id -1 \
        status no_sample_mounted

        set run_for_adjust_default $contents
        set run_for_adjust         $contents
        return
    }
    if {!$m_sampleReOriented} {
        puts "cleared run_for_adjust by not reoriented"

        set contents $run_for_adjust_default
        ::DCS::RunFieldForQueue::setList contents \
        sil_id -1 \
        row_id -1 \
        run_id -1 \
        status sample_not_reoriented

        set run_for_adjust_default $contents
        set run_for_adjust         $contents
        return
    }

    set uniqueID [lindex $m_uniqueIDList $m_currentCrystal]

    puts "setting up run for new position"

    set contents $run_for_adjust_default
    ::DCS::RunFieldForQueue::setList contents \
    sil_id $m_SILID \
    row_id $m_currentCrystal \
    unique_id $uniqueID \
    run_id -1 \
    status inactive \
    run_label $m_currentCrystal \
    delta $m_reorient_info_array(REORIENT_DIFF_DELTA_0) \
    attenuation $m_reorient_info_array(REORIENT_ATTENUATION) \
    exposure_time $m_reorient_info_array(REORIENT_DIFF_EXPOSURE_TIME_0) \
    distance $m_reorient_info_array(REORIENT_DISTANCE) \
    beam_stop $m_reorient_info_array(REORIENT_BEAM_STOP) \
    energy1 $m_reorient_info_array(REORIENT_ENERGY) \
    detector_mode $m_reorient_info_array(REORIENT_DIFF_MODE_0) \
    beam_width $m_reorient_info_array(REORIENT_BEAM_WIDTH) \
    beam_height $m_reorient_info_array(REORIENT_BEAM_HEIGHT)

    set run_for_adjust_default $contents
    set run_for_adjust         $contents
}
::itcl::body SequenceDevice::saveDebugSnapshots { dir prefix } {
    global gMotorPhi

    if {[catch {
        foreach phi $DEBUG_SNAPSHOT_PHI {
            set pos [expr $m_phiZero + $phi]
            move $gMotorPhi to $pos
            wait_for_devices $gMotorPhi
            saveRawSnapshot [file join $dir ${prefix}_${phi}.jpg]
        }
    } errMsg]} {
        log_warning save DEBUG snapshot failed for $prefix
    }
}
::itcl::body SequenceDevice::doReOrient { } {
    variable ::nScripts::screening_msg

    if {$m_currentCrystal < 0} {
        log_error sample not mounted yet
        return -code error "no sample"
    }
    set re_orientable [lindex $m_reOrientableList $m_currentCrystal]
    if {$re_orientable != "1"} {
        log_error sample not reorientable
        set m_skipThisSample 1
        return
    }
    if {!$m_enableReOrient} {
        log_error ReOrient disabled on this beamline
        set m_skipThisSample 1
        return
    }

    set restoreMotorList ""

    if {[catch {
        ### clear phi calculation done flag
        set m_reOrientPhiList \
        [lreplace $m_reOrientPhiList $m_currentCrystal $m_currentCrystal ""]
        ### clear sil too
        set data [list ReOrientPhi ""]
        set data [eval http::formatQuery $data]
        set uniqueID [lindex $m_uniqueIDList $m_currentCrystal]
        editSpreadsheet $m_lastUserName $m_lastSessionID \
        $m_SILID $m_currentCrystal $data $uniqueID

        readReOrientInfo
        warningDiffForReOrient
        set restoreMotorList [setupForReOrient]

        set dir [getDirectory]

        set phi_diff [reorientPhi $dir]
        puts "REORIENT phi: $phi_diff"

        foreach {f_h f_v e_h e_v} [reorientXYZ $dir] break

        #### TODO:save statisics
        ##puts "time stamp SUCCESS phi_diff f_h f_v e_h e_f"
        logReOrientResult 1 "$phi_diff $f_h $f_v $e_h $e_v"

        if {$SAVE_DEBUG_SNAPSHOT} {
            saveDebugSnapshots $dir profile_second
        }

        set m_sampleReOriented 1
        fillDefaultRunForAdjust
        updateCrystalStatusString 
    } errMsg]} {
        log_error ReOrient failed: $errMsg
        set screening_msg "sample reorient failed: $errMsg"
        user_log_error screening "[getCrystalNameForLog] reorient $errMsg"
        set m_skipThisSample 1
        logReOrientResult 0 $errMsg
    } else {
        if {$restoreMotorList != ""} {
            set screening_msg "sample reoriented, moving back motors "
        }
    }

    ### no catch here, abort if fail
    foreach {motor pos} $restoreMotorList {
        log_warning restoring $motor
        move $motor to $pos
        wait_for_devices $motor
    }
}
::itcl::body SequenceDevice::warningDiffForReOrient { } {
    foreach item $s_reorient_info_map {
        foreach {tag device restore} $item break
        if {$restore} {
            ##these we will move so no need to warn
            continue
        }

        variable ::nScripts::$device
        set current_value [set $device]
        set reorient_value $m_reorient_info_array($tag)

        set print_tag [string range $tag 9 end]

        set needWarn 0

        switch -exact -- $tag {
        REORIENT_BEAMLINE -
        REORIENT_DETECTOR {
            if {$current_value != $reorient_value} {
                set needWarn 1
            }
        }
        REORIENT_ENERGY {
            if {abs($current_value - $reorient_value) > 10.0} {
                set needWarn 1
            }
        }
        REORIENT_BEAM_WIDTH -
        REORIENT_BEAM_HEIGHT {
            if {abs($current_value - $reorient_value) > 0.001} {
                set needWarn 1
            }
        }
        REORIENT_ATTENUATION {
            if {abs($current_value - $reorient_value) > 10} {
                set needWarn 1
            }
        }
        REORIENT_DISTANCE -
        REORIENT_BEAM_STOP {
            if {abs($current_value - $reorient_value) > 1} {
                set needWarn 1
            }
        }
        REORIENT_CAMERA_ZOOM {
            ##skip this, just check scale factor
        }
        REORIENT_SCALE_FACTOR {
            ### 10%
            if {abs($current_value / $reorient_value -1 ) > 0.1} {
                set needWarn 1
            }
        }
        }
        if {$needWarn} {
            log_warning $print_tag=$current_value not match $reorient_value
        }
    }

}
::itcl::body SequenceDevice::setupForReOrient { } {
    variable ::nScripts::screening_msg

    set screening_msg "move motors for sample reorientation"

    set moveBackList ""

    foreach item $s_reorient_info_map {
        foreach {tag device restore} $item break
        if {!$restore} {
            continue
        }
        variable ::nScripts::$device
        lappend moveBackList $device [set $device]
        move $device to $m_reorient_info_array($tag)
        wait_for_devices $device
    }
    return $moveBackList
}
::itcl::body SequenceDevice::reorientPhi { dir } {
    global gMotorPhi
    variable ::nScripts::$gMotorPhi

    set directory [file join $dir reorient]
    foreach {img1 img2} [take2ImageForReOrient $directory] break

    set runName [getCrystalName]

    #### correct phi
    set uniqueID [lindex $m_uniqueIDList $m_currentCrystal]
    autoindexForReOrient $m_lastUserName $m_lastSessionID \
    $m_SILID $m_currentCrystal $uniqueID $img1 $img2 $m_beamlineName $runName

    set phi_diff [waitForPhiCalculation]
    set current_phi [set $gMotorPhi]
    set reorient_phi [expr $current_phi - $phi_diff]
    set reposition_phi $reorient_phi

    return $phi_diff
}
::itcl::body SequenceDevice::waitForPhiCalculation { } {
    variable ::nScripts::screening_msg

    set screening_msg "wait for phi difference calculation"

    set phi_result [lindex $m_reOrientPhiList $m_currentCrystal]

    while {$phi_result == ""} {
        wait_for_strings sil_event_id
        set phi_result [lindex $m_reOrientPhiList $m_currentCrystal]
    }
    if {![string is double -strict $phi_result]} {
        log_error phi_offset calculation failed: $phi_result
        set screening_msg "error: phi calculation failed"
        return -code error $phi_result
    }
    log_warning DEBUG got phi diff=$phi_result
    return $phi_result
}
::itcl::body SequenceDevice::logReOrientResult { success contents } {

    set timestamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
    if {[isString reorient_data]} {
        variable ::nScripts::reorient_data

        set current_success [lindex $reorient_data 1]
        set current_failure [lindex $reorient_data 2]

        if {![string is integer -strict $current_success] || \
        $current_success < 0} {
            set current_success 0
        }
        if {![string is integer -strict $current_failure] || \
        $current_failure < 0} {
            set current_failure 0
        }
        if {$success} {
            incr current_success
        } else {
            incr current_failure
        }

        set reorient_data [list $timestamp $current_success $current_failure]
    }

    if {[catch {
        if {$m_channelReOrient != ""} {
            close $m_channelReOrient
            set m_channelReOrient ""
        }
        set m_channelReOrient [open $m_fileReOrient a]

        set id "SILID=${m_SILID}CRYSTAL_ID=[getCrystalName]"
        set status [expr $success?"SUCCESS":"FAILURE"]

        puts  $m_channelReOrient "$timestamp $status $id $contents"
        close $m_channelReOrient
        set m_channelReOrient ""
    } errMsg]} {
        puts "log reorient result failed: $errMsg"
    }
}
::itcl::body SequenceDevice::take2ImageForReOrient { dir } {
    global gWaitForGoodBeamMsg
    global gMotorPhi

    variable ::nScripts::$gMotorPhi
    variable ::nScripts::screening_msg

    set runNumber 16

    set phi_rotate [expr \
    $m_reorient_info_array(REORIENT_DIFF_START_PHI_1) - \
    $m_reorient_info_array(REORIENT_DIFF_START_PHI_0) \
    ]

    set m_imgFileExtension [getImgFileExt]

    if {[catch {
        ::nScripts::correctPreCheckMotors
    } errMsg]} {
        log_error failed to correct motors $errMsg
        return -code error $errMsg
    }

    set gWaitForGoodBeamMsg screening_msg
    if {![::nScripts::beamGood]} {
        wait_for_good_beam
    }

    set crystalName [getCrystalName]
    set fileroot "${crystalName}_reorient"
    if {[catch {
        impGetNextFileIndex \
        $m_lastUserName \
        $m_lastSessionSID \
        $dir \
        $fileroot $m_imgFileExtension} \
    counter]} \
    {
        set counter 1
    }

    ##we do not use "for" here, so that we can retry if !beamGood at the end
    set imgNum 0
    while {$imgNum < 2} {
        set filename ${fileroot}_[format $m_counterFormat $counter]
        set flush $imgNum
        set imgFile$imgNum [file join $dir ${filename}.${m_imgFileExtension}]
        set delta   $m_reorient_info_array(REORIENT_DIFF_DELTA_$imgNum)
        set expTime $m_reorient_info_array(REORIENT_DIFF_EXPOSURE_TIME_$imgNum)
        ### need a map if detetorType is different
        set mode    $m_reorient_info_array(REORIENT_DIFF_MODE_$imgNum)

        set phiPosition [expr $m_phiZero + $imgNum * $phi_rotate]
        move $gMotorPhi to $phiPosition
        wait_for_devices $gMotorPhi
        set phiPosition [set $gMotorPhi]

        set screening_msg "collect $filename"
        set handle [eval start_waitable_operation collectFrame \
        $runNumber \
        $filename \
        $dir \
        $m_lastUserName \
        $gMotorPhi \
        shutter \
        $delta \
        $expTime \
        $mode \
        $flush \
        0 \
        $m_lastSessionID]
        if {[catch {
            wait_for_operation_to_finish $handle
            set logAngle [format "%.3f" $phiPosition]
            set    log_contents "[user_log_get_current_crystal]"
            append log_contents " reorient image"
            append log_contents " $dir/$filename.$m_imgFileExtension"
            append log_contents " $logAngle deg"
            user_log_note screening $log_contents
        } errMsg]} {
            set fill_run_msg "error: $errMsg"
            log_error autoindex $errMsg
            return -code error $errMsg
        }
        if {![::nScripts::beamGood]} {
            wait_for_good_beam
            set screening_msg "retaking image for autoindex"
        } else {
            incr counter
            incr imgNum
        }
    }
    set gWaitForGoodBeamMsg ""

    return [list $imgFile0 $imgFile1]
}
::itcl::body SequenceDevice::reorientXYZ { dir } {
    global gMotorPhi
    variable ::nScripts::$gMotorPhi
    variable ::nScripts::screening_msg

    ### deal with change of beam center.
    ### normally, it should at (0.5, 0.5).
    set old_beam_x $m_reorient_info_array(BEAM_CENTER_ON_VIDEO_X)
    set old_beam_y $m_reorient_info_array(BEAM_CENTER_ON_VIDEO_Y)
    set cur_beam_x [::nScripts::getSampleCameraConstant zoomMaxXAxis]
    set cur_beam_y [::nScripts::getSampleCameraConstant zoomMaxYAxis]
    ### the sample needs to be shifted after image match
    set shift_x [expr $cur_beam_x - $old_beam_x]
    set shift_y [expr $cur_beam_y - $old_beam_y]
    if {$shift_x != 0.0 || $shift_y != 0.0} {
        puts "REORIENT: beam center shifted: $shift_x $shift_y"
    }

    set screening_msg "reorienting face position"

    #### move to old face on
    set old_face_on_phi $m_reorient_info_array(REORIENT_VIDEO_PHI_0)
    move reposition_phi to $old_face_on_phi
    wait_for_devices reposition_phi

    ############# DEBUG double check #################
    set current_phi [set $gMotorPhi]
    set error_phi [angleSpan [expr $current_phi - $m_phiZero]]
    log_warning DEBUG face_on phi current $m_phiZero
    log_warning DEBUG face_on phi from reorient $current_phi
    log_warning DEBUG face_on phi error $error_phi

    set m_phiZero $current_phi

    set directory [file join $dir reorient]
    set crystalName [getCrystalName]

    set faceFile [file join $directory ${crystalName}_reorient_face.jpg]
    set edgeFile [file join $directory ${crystalName}_reorient_edge.jpg]

    set image_width  704
    set image_height 480
    ### will change the matchup scripts to return fraction %.

    saveRawSnapshot $faceFile
    set resultFace \
    [runMatchup $faceFile $m_reorient_info_array(REORIENT_VIDEO_FILENAME_0)]
    foreach {pix_h pix_v} $resultFace break

    if {[llength $resultFace] >= 5} {
        ### new matchup will return:
        ### pix_h pix_v cc rel_x rel_y
        set offset_face_h [lindex $resultFace 3]
        set offset_face_v [lindex $resultFace 4]
    } else {
        set offset_face_h [expr double($pix_h) / $image_width]
        set offset_face_v [expr double($pix_v) / $image_height]
    }
    puts "REORIENT face: $offset_face_h $offset_face_v"

    set offset_face_h [expr $offset_face_h + $shift_x]
    set offset_face_v [expr $offset_face_v + $shift_y]
    namespace eval ::nScripts moveSample_start $offset_face_h $offset_face_v
    
    set screening_msg "reorienting edge position"
    #### move to old edge on
    #### you can do direct rotate 90, too
    set old_edge_on_phi $m_reorient_info_array(REORIENT_VIDEO_PHI_1)
    move reposition_phi to $old_edge_on_phi
    wait_for_devices reposition_phi

    saveRawSnapshot $edgeFile
    set resultEdge \
    [runMatchup $edgeFile $m_reorient_info_array(REORIENT_VIDEO_FILENAME_1)]
    foreach {pix_h pix_v} $resultEdge break

    if {[llength $resultEdge] >= 5} {
        set offset_edge_h [lindex $resultEdge 3]
        set offset_edge_v [lindex $resultEdge 4]
    } else {
        set offset_edge_h [expr double($pix_h) / $image_width]
        set offset_edge_v [expr double($pix_v) / $image_height]
    }

    ### here offset_h should be very small, it should be already corrected
    ### in face view
    if {abs($offset_edge_h + $shift_x) > 0.01} {
        log_warning strange in edge view, horz still off $offset_edge_h \
        with shift_x=$shift_x relative
    }

    puts "REORIENT edge: $offset_edge_h $offset_edge_v"

    set offset_edge_h [expr $offset_edge_h + $shift_x]
    set offset_edge_v [expr $offset_edge_v + $shift_y]
    namespace eval ::nScripts moveSample_start $offset_edge_h $offset_edge_v

    ##now we set repostion motors to 0
    ## we may decide to set them to the old values too.
    ::nScripts::setRepositionIndividualCurrent sample_x sample_y sample_z

    return [list $offset_face_h $offset_face_v $offset_edge_h $offset_edge_v]
}
::itcl::body SequenceDevice::runMatchup { snapshot1 snapshot2 } {
    set mySID $m_lastSessionID
    if {[string equal -length 7 $mySID "PRIVATE"]} {
        set mySID [string range $mySID 7 end]
    }
    set cmd "/data/penjitk/sw/matchup/run_matchup.com%20${snapshot1}%20${snapshot2}"
    set url "http://localhost:61001"
    append url "/runScript?impUser=$m_lastUserName"
    append url "&impSessionID=$mySID"
    append url "&impCommandLine=$cmd"
    append url "&impUseFork=false"
    append url "&impEnv=HOME=/home/${m_lastUserName}"

    puts "matchup url: [SIDFilter $url]"

    set token [http::geturl $url -timeout 8000]
    checkHttpStatus $token
    set result [http::data $token]
    upvar #0 $token state
    array set meta $state(meta)
    http::cleanup $token
     
    set tokens [split $result "\n"]
    set lastLine ""
    set line ""
    foreach {line} $tokens {
        if {$line != ""} {
            puts "matchup result line = $line"
            set lastLine $line
        }
     }

    return $lastLine
}
::itcl::body SequenceDevice::checkFirstSnapshotForReOrient { } {
    global gMotorPhi
    variable ::nScripts::$gMotorPhi

    if {!$m_enableReOrient} {
        return
    }
    if {$m_jpeg_reorient_0 != ""} {
        return
    }

    set re_orientable [lindex $m_reOrientableList $m_currentCrystal]
    if {$re_orientable == "1"} {
        return
    }

    puts "+checkFirstSnapshotForReOrient"

    set save_phi [set $gMotorPhi]

    move camera_zoom to $REORIENT_SNAPSHOT_ZOOM
    move $gMotorPhi to $m_phiZero
    wait_for_devices camera_zoom $gMotorPhi

    set crystalName [getCrystalName]
    set dir [getDirectory]
    set filename [file join $dir ${crystalName}_orient_0.jpg]
    set boxname  [file join $dir ${crystalName}_box_0.jpg]
    saveBoxSnapshot $boxname $filename

    set m_jpeg_reorient_0 $filename

    set m_jpeg_info_0 [list \
    REORIENT_VIDEO_FILENAME_0=$filename \
    REORIENT_BOX_FILENAME_0=$boxname \
    REORIENT_VIDEO_PHI_0=$m_phiZero \
    ]

    move $gMotorPhi to $save_phi
    wait_for_devices $gMotorPhi
    puts "-checkFirstSnapshotForReOrient"
}
::itcl::body SequenceDevice::checkSecondSnapshotForReOrient { } {
    global gMotorPhi
    variable ::nScripts::$gMotorPhi

    if {!$m_enableReOrient} {
        return
    }
    if {$m_jpeg_reorient_1 != ""} {
        return
    }

    set re_orientable [lindex $m_reOrientableList $m_currentCrystal]
    if {$re_orientable == "1"} {
        return
    }

    puts "+checkSecondSnapshotForReOrient"
    set save_phi [set $gMotorPhi]

    move camera_zoom to $REORIENT_SNAPSHOT_ZOOM
    set angle [expr $m_phiZero + 90.0]
    move $gMotorPhi to $angle
    wait_for_devices camera_zoom $gMotorPhi

    set crystalName [getCrystalName]
    set dir [getDirectory]
    set filename [file join $dir ${crystalName}_orient_1.jpg]
    set boxname  [file join $dir ${crystalName}_box_1.jpg]
    saveBoxSnapshot $boxname $filename

    set m_jpeg_reorient_1 $filename

    set m_jpeg_info_1 [list \
    REORIENT_VIDEO_FILENAME_1=$filename \
    REORIENT_BOX_FILENAME_1=$boxname \
    REORIENT_VIDEO_PHI_1=$angle \
    ]

    move $gMotorPhi to $save_phi
    wait_for_devices $gMotorPhi
    puts "-checkSecondSnapshotForReOrient"
}