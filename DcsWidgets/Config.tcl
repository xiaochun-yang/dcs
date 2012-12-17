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
# DcsConfig.tcl
#
# Loads config from files
#
# ===================================================

# ===================================================
#
# DcsConfig.tcl --
#
# Config API that allows a client application to load 
# dcs config from files.
#	
#			
#
# Rough version history:
# V0_1	Boom
#
# ===================================================

package provide DCSConfig 1.0
package require Itcl
#namespace import ::itcl::*

# ===================================================
#
# class AuthClient
#
# ===================================================
class DCS::Config {

# public


	# Constructor
	constructor { } {}

	# Methods
	
	# Setup 
	public method setConfigDir { dir } {}
	public method setConfigRootName { root_name } {}
	public method getConfigRootName {} {return $m_name}
	public method setConfigFile { file } {}
	public method setDefaultConfigFile { file } {}
	public method getConfigFile { } {}
	public method getDefaultConfigFile { } {}
	public method setUseDefaultConfig { b } {}
	public method isUseDefault { } {}
	public method load { } {}

    public method getUserLogDir { }
    public method getUserChatDir { }
	
	# Dcss config
	public method getDcssCertificate { } {}
	public method getDcssHost { } {}
    public method getDcssHostIPNum { } { }
	public method getDcssGuiPort { } {}
	public method getDcssScriptPort { } {}
	public method getDcssHardwarePort { } {}
	public method getDcssUseSSL { } {}
	public method getDcssAuthProtocol
	public method getDcssForcedDoor 
	public method getDcssDisplays   { } {}
	public method getBeamlineViewList 
    public method getBluIceTabOrder {} {}
   public method getDeviceDefinitionFilename 
	
	# Authentication server config
	public method getAuthHost { } { return [getStr "$auth.host"] }
	public method getAuthPort { } { return [getInt "$auth.port" 80] }
	public method getAuthSecureHost { } { return [getStr "$auth.secureHost"] }
	public method getAuthSecurePort { } { return [getInt "$auth.securePort" 443] }

	# Impersonation server config
	public method getImpersonHost { } {}
	public method getImpersonPort { } {}

    public method getImpDhsImpHost { }
    public method getImpDhsImpPort { }

	# Image server config
	public method getImgsrvHost { } {}
	public method getImgsrvWebPort { } {}
	public method getImgsrvGuiPort { } {}
	public method getImgsrvHttpPort { } {}
	public method getImgsrvTmpDir { } {}
	public method getImgsrvMaxIdleTime { } {}

   # screening information
   public method getAddCassetteUrl
   public method getBeamlineListUrl
   public method getCassetteDataUrl
   public method getCassetteInfoUrl
   public method getCassetteIDUrl
   public method getCassetteChangeUrl
   public method getCrystalDataUrl 
   public method getCrystalUpdateDataUrl
   public method getDefaultDataHome

    ####new spreadsheet information server
    public method getDefaultSILUrl
    public method getUploadSILUrl
    public method getDownloadSILUrl
    public method getLockSILUrl
    public method getUnassignSILUrl
    public method getDeleteSILUrl
    public method getCrystalEditUrl
    public method getSaveCrystalAttributeUrl
    public method getRetrieveCrystalPropertyUrl
    public method getSaveCrystalPropertyUrl
    public method getCrystalChangesUrl
    public method getCrystalClearImagesUrl
    public method getCrystalClearResultsUrl
    public method getCrystalClearAllUrl
    public method getCrystalAddImageUrl
    public method getCrystalAnalyzeImageUrl
    public method getCrystalAutoindexUrl
    public method getCrystalPrepareReOrientUrl
    public method getCrystalReOrientUrl
    public method getSILRowUrl
    public method getCenterAnalyzeImageUrl
    public method getViewScreeningStrategyUrl
    public method getViewCollectStrategyUrl
    public method getCollectStrategyNewRunUrl
    public method getStrategyDir
    public method getStrategyStatusUrl
    public method getMoveCrystalUrl
    public method getSilAndEventListUrl
    public method getPreCheckMotorList
    public method getBeamGoodSignal
    public method getQueueAddRunUrl
    public method getQueueDeleteRunUrl
    public method getQueueGetRunUrl
    public method getQueueSetRunUrl
    public method getQueueGetRepositionUrl
    public method getQueueAddDefaultRepositionUrl
    public method getQueueAddNormalRepositionUrl
    public method getWebIceShowRunStrategyUrl
    public method getVideoScalingEnabled

	#video urls
	public method getImageUrl { stream_ } {return [getStr "video${stream_}.imageUrl"]}
	public method getPresetUrl { stream_ } {return [getStr "video${stream_}.presetRequestUrl"]}
	public method getMoveRequestUrl { stream_ } {return [getStr "video${stream_}.moveRequestUrl"]}
	public method getVideoArgs { stream_ } {return [getStr "video${stream_}.args"]}
	public method getTextUrl { stream_ } {return [getStr "video${stream_}.textUrl"]}

    public method getSnapshotUrl { } { return [getStr "video.snapshotUrl" ] }
    public method getSnapshotDirectUrl { } { return [getStr "video.snapshotDirectUrl" ] }
    public method getSnapshotDirectInlineUrl { } { return [getStr "video.snapshotDirectInlineUrl" ] }

	public method getPeriodicFilename

   #get specific beamine views	
	public method getHutchView {} {return [getStr "bluice.hutchView"]}
	public method getMirrorView {} {return [getStr "bluice.mirrorView"]}
	public method getMirrorApertureView {} {return [getStr "bluice.mirrorApertureView"]}
	public method getFrontEndApertureView {} {return [getStr "bluice.frontEndApertures"]}
	public method getMonoView {} {return [getStr "bluice.monoView"]}
	public method getMonoApertureView {} {return [getStr "bluice.monoApertureView"]}
	public method getToroidView {} {return [getStr "bluice.toroidView"]}
	public method getBluIceUseSsl {} {return [getInt "bluice.useSsl" 1]}
	public method getBluIceUseRobot {} {return [getInt "bluice.useRobot" 1]}
	public method getBluIceDefaultHost {} {return [getStr "bluice.defaultHost"]}
	public method getBluIceScanTabType {} {return [getStr "bluice.scanTabType"]}
	public method getBluIceScanMotorList {} {return [getStr "bluice.scanMotorList"]}
	public method getBluIceUseOneTimeTicket {} {return [getInt "bluice.useOneTimeTicket" 1]}

    #### for all users to see current excitation scan
    public method getExcitationScanDirectory {} {
        return [getStr "excitationScan.directory"]
    }

    ##### for simulation mode to skip optimizing table ###
    public method getSimulatorMode { } {return [getInt "dcss.simulator" 0]}

    #### for beamsize: may be removed after all beamlines implement
    #### beam_size_sample_x/y
    public method getMotorRunBeamWidth { } {
        set m [getStr run.beam_width]
        if {$m == ""} {
            set m beam_size_x
        }
        return $m
    }
    public method getMotorRunBeamHeight { } {
        set m [getStr run.beam_height]
        if {$m == ""} {
            set m beam_size_y
        }
        return $m
    }
    public method getMotorRunEnergy { } {
        set m [getStr run.energy]
        if {$m == ""} {
            set m energy
        }
        return $m
    }
    public method getMotorRunDistance { } {
        set m [getStr run.distance]
        if {$m == ""} {
            set m detector_z
        }
        return $m
    }
    public method getMotorRunVert { } {
        set m [getStr run.vert]
        if {$m == ""} {
            set m detector_vert
        }
        return $m
    }
    public method getMotorRunHorz { } {
        set m [getStr run.horz]
        if {$m == ""} {
            set m detector_horz
        }
        return $m
    }
    public method getMotorRunBeamStop { } {
        set m [getStr run.beam_stop]
        if {$m == ""} {
            set m beamstop_z
        }
        return $m
    }
    public method getMotorRunBeamStopHorz { } {
        set m [getStr run.beam_stop_horz]
        if {$m == ""} {
            set m beamstop_horz
        }
        return $m
    }
    public method getMotorRunBeamStopVert { } {
        set m [getStr run.beam_stop_vert]
        if {$m == ""} {
            set m beamstop_vert
        }
        return $m
    }

    public method getMotorRunPhi { } {
        set m [getStr run.phi]
        if {$m == ""} {
            set m gonio_phi
        }
        return $m
    }
    public method getMotorRunOmega { } {
        set m [getStr run.omega]
        if {$m == ""} {
            set m gonio_omega
        }
        return $m
    }

    public method getFrameCounterFormat { } {
        set f [getStr collect.counterFormat]
        if {$f == ""} {
            puts "no collect.counterFormat defined in config file, using %04d"
            set f %04d
        }
        return $f
    }


	# Generic get method
	public method get { key valueName } {}
	public method getRange { key listName } {}
	public method getStr { key } {}
	public method getInt { key def } {}
	public method getList { key } {}

# Private 

	# Internal variables
	private variable m_useDefault 1
	private variable m_configDir "../../dcsconfig/data"
	private variable m_name "default"
	
	private variable m_configFile
	private variable m_defConfigFile
	
	private variable m_config
	private variable m_defConfig

    ## for config per user per beamline
	private variable m_userConfig 
    ### per user
	private variable m_userDefConfig
	
	# constant
	private variable imgsrv "imgsrv"
	private variable auth "auth"
	private variable imperson "imperson"
	private variable video "video"


	# Methods
	private method getConfig { key arrName valueName }
	private method getConfigRange { key arrName listName }
	private method loadFile { file arrName } {}
	
	private method updateConfigFiles { } {}

}


# ===================================================
#
# DCS::Config::constructor --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::constructor { } {

	# Initialize arrays
	set m_config(dummy) dummy
	set m_defConfig(dummy) dummy
	set m_userConfig(dummy) dummy
	set m_userDefConfig(dummy) dummy

	updateConfigFiles

}


# ===================================================
#
# DCS::Config::setConfigDir --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::setConfigDir { dir } {

	set m_configDir $dir
	
	updateConfigFiles
	
}

# ===================================================
#
# DCS::Config::setConfigDir --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::setConfigRootName { root_name } {

	set m_name $root_name
	
	updateConfigFiles
}

# ===================================================
#
# DCS::Config::setConfigDir --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::setConfigFile { file } {

	set m_configFile $file
}

# ===================================================
#
# DCS::Config::setDefaultConfigFile --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::setDefaultConfigFile { file } {

	set m_defConfigFile $file
}

# ===================================================
#
# DCS::Config::getConfigFile --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::getConfigFile { } {

	return $m_configFile
}

# ===================================================
#
# DCS::Config::getDefaultConfigFile --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::getDefaultConfigFile { } {

	return $m_defConfigFile
}

# ===================================================
#
# DCS::Config::setUseDefaultConfig --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::setUseDefaultConfig { b } {

	set m_useDefault $b
}

# ===================================================
#
# DCS::Config::isUseDefault --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::isUseDefault { } {

	return $m_useDefault
}

# ===================================================
#
# DCS::Config::updateConfigFiles --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::updateConfigFiles { } {

	set m_configFile "$m_configDir/$m_name.config"
	set m_defConfigFile "$m_configDir/default.config"
}


# ===================================================
#
# DCS::Config::load--
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::load { } {

	# Passing m_config array variable by name.
	if { [loadFile $m_configFile "m_config"] == 0 } {
		return 0
	}
	
	# Passing m_defConfig array variable by name.
	loadFile $m_defConfigFile "m_defConfig"

    set allowUserConfig [getInt "allowUserConfig" 0]

    if {!$allowUserConfig} {
        return 1
    }
    puts "try loading user config"

    set userConfigFile [file join ~ .bluice config ${m_name}.config]
    if {[file readable $userConfigFile]} {
        if {[catch {
            loadFile $userConfigFile m_userConfig
        } errMsg]} {
            puts "load user beamline config failed: $errMsg"
        } else {
            puts "load user beamline config successful"
        }
    }
    set userDefaultConfigFile [file join ~ .bluice config default.config]
    puts "trying user default config: $userDefaultConfigFile"
    if {[file readable $userDefaultConfigFile]} {
        if {[catch {
            loadFile $userDefaultConfigFile m_userDefConfig
        } errMsg]} {
            puts "load user default config failed: $errMsg"
        } else {
            puts "load user default config successful"
        }
    }
	
	return 1
}

# ===================================================
#
# DCS::Config::load --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::loadFile { file arrName } {

	upvar $arrName config

	# try to open serverPorts.txt 
	if { [catch {set fileHandle [open $file r ] } ] } {
		return -code error "Failed to open config file $file"
	}
		
	# read file
	while { [eof $fileHandle] != 1 } {
		gets $fileHandle buffer

		set firstEqual [string first = $buffer]
		if {$firstEqual < 1 } continue

		set name [string range $buffer 0 [expr $firstEqual -1] ]
		set value [string range $buffer [expr $firstEqual +1] end]

		#get rid of any trailing whitespace
		set value [string trimright $value]

		#puts "in load: key = $name, value = $value"
		if { ![info exists config($name)] } {
			set config($name) "\{$value\}"
			#puts "config name=$name value=[lindex $config($name) 0]"
		} else {	
			set config($name) "$config($name) \{$value\}"
			#puts "config name=$name value=$config($name)"
		}
	}
	close $fileHandle
	
	return 1
}


# ===================================================
#
# DCS::Config::getStr --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::getStr { key } {

	set value ""
	if { [get $key value] == 1} {
		return $value
	}
	
	return ""

}

# ===================================================
#
# DCS::Config::getInt --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::getInt { key def } {

	set value $def
	if { [get $key value] == 1} {
		return $value
	}
	
	return $def

}

# ===================================================
#
# DCS::Config::getList --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::getList { key } {

	set aList {}
	if { [getRange $key aList] == 1} {
		return $aList
	}
		
	return {}

}


# ===================================================
#
# DCS::Config::get --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::get { key valueName } {

	upvar $valueName value

    if { [getConfig $key "m_userConfig" value] == 1} {
        puts "using user config for $key=$value"
        return 1
    }
    if {$m_useDefault} {
        if { [getConfig $key "m_userDefConfig" value] == 1} {
        puts "using user default config for $key=$value"
            return 1
        }
    }

	# Return true if we found the config
	if { [getConfig $key "m_config" value] == 1 } {
		return 1
	}
	
	# Did not find the config and did not want to use
	# the value of default config.
	if { $m_useDefault == 0 } {
		return 0
	}
	
	# Will return true if we can find it in default config.
	# Otherwise return false.
	return [getConfig $key "m_defConfig" value]
}


# ===================================================
#
# DCS::Config::get --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::getRange { key listName } {

	upvar $listName aList

	# Return true if we found the config
	if { [getConfigRange $key "m_config" aList] == 1 } {
		return 1
	}
	
	# Did not find the config and did not want to use
	# the value of default config.
	if { $m_useDefault == 0 } {
		return 0
	}
	
	# Will return true if we can find it in default config.
	# Otherwise return false.
	return [getConfigRange $key "m_defConfig" aList]
}



# ===================================================
#
# DCS::Config::getConfig --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::getConfig { key arrName valueName } {

	upvar $arrName arr
	upvar $valueName value
	
	if { ![info exists arr($key)] } {
		return 0
	}
		
	
	set value [lindex $arr($key) 0]
		
	return 1
}


# ===================================================
#
# DCS::Config::getConfigRange --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::getConfigRange { key arrName listName } {

	upvar $arrName arr
	upvar $listName aList
	
	if { ![info exists arr($key)] } {
		return 0
	}
					
	set aList $arr($key)
			
	return 1
}


body DCS::Config::getUserLogDir { } {

	return [getStr "userLog.directory"]
}

body DCS::Config::getUserChatDir { } {

	return [getStr "userChat.directory"]
}

# ===================================================
#
# DCS::Config::getDcssHost --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::getDcssHost { } {

	return [getStr "dcss.host"]
}

body DCS::Config::getDcssCertificate { } {

	return [getStr "dcss.certificate"]
}

body DCS::Config::getDcssHostIPNum { } {
    set dcssName [getDcssHost]
    set ip [lindex [exec host $dcssName] end]
    set numList [split $ip .]
    if {[llength $numList != 4} {
        return 0
    }
    ####cannot use integer, it is signed not unsigned
    set result 0.0
    foreach num $numList {
        set result [expr $result * 256.0 + $num]
    }
    return [format "%.0f" $result]
}

# ===================================================
#
# DCS::Config::getDcssGuiPort --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::getDcssGuiPort { } {

	return [getInt "dcss.guiPort" 0]
}

# ===================================================
body DCS::Config::getDcssAuthProtocol { } {

	return [getInt "dcss.authProtocol" 0]
}

# ===================================================
body DCS::Config::getDcssForcedDoor { } {

	return [getStr "dcss.forcedDoor"]
}


# ===================================================
#
# DCS::Config::getDcssScriptPort --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::getDcssScriptPort { } {

	return [getInt "dcss.scriptPort" 0]
}

body DCS::Config::getDcssUseSSL { } {

	return [getInt "dcss.ssl" 0]
}

# ===================================================
#
# DCS::Config::getDcssHardwarePort --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::getDcssHardwarePort { } {

	return [getInt "dcss.hardwarePort" 0]
}


# ===================================================
#
# DCS::Config::getDcssHardwarePort --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::getDcssDisplays { } {

	return [getList "dcss.display"]
}

body DCS::Config::getBeamlineViewList { } {

	return [getList "bluice.beamlineView"]
}

# ===================================================
#
# DCS::Config::getImpersonHost --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::getImpersonHost { } {

	return [getStr "$imperson.host"]
}

# ===================================================
#
# DCS::Config::getImpersonPort --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::getImpersonPort { } {

	return [getInt "$imperson.port" 0]
}


# ===================================================
#
# DCS::Config::getImgsrvHost --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::getImgsrvHost { } {

	return [getStr "$imgsrv.host"]
}

# ===================================================
#
# DCS::Config::getImgsrvWebPort --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::getImgsrvWebPort { } {

	return [getInt "$imgsrv.webPort" 0]
}

# ===================================================
#
# DCS::Config::getImgsrvGuiPort --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::getImgsrvGuiPort { } {

	return [getInt "$imgsrv.guiPort" 0]
}

# ===================================================
#
# DCS::Config::getImgsrvHttpPort --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::getImgsrvHttpPort { } {

	return [getInt "$imgsrv.httpPort" 0]
}

# ===================================================
#
# DCS::Config::getImgsrvTmpDir --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::getImgsrvTmpDir { } {

	return [getStr "$imgsrv.tmpDir"]
}

# ===================================================
#
# DCS::Config::getImgsrvMaxIdleTime --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
body DCS::Config::getImgsrvMaxIdleTime { } {

	return [getInt "$imgsrv.maxIdleTime" 0]
}





# ===================================================

body DCS::Config::getPeriodicFilename { } {
	return [getStr "periodic.filename"]
}


body DCS::Config::getBluIceTabOrder { } {
	return [getStr "bluice.tabOrder"]
}

body DCS::Config::getDeviceDefinitionFilename { } {
   global DCS_DIR

   set fullPath [getStr "bluice.deviceDefinitionFilename"]  

	if { $fullPath == "" } {
      set filename [getConfigRootName].dat
      set fullPath [file join $DCS_DIR dcsconfig data $filename ]
   }

   return $fullPath
}

body DCS::Config::getCrystalDataUrl {} {
   return [getStr "screening.crystalDataUrl"]
}

body DCS::Config::getCassetteDataUrl {} {
   return [getStr "screening.cassetteDataUrl"]
}

body DCS::Config::getAddCassetteUrl {} {
   return [getStr "screening.addCassetteUrl"]
}
body DCS::Config::getBeamlineListUrl {} {
   return [getStr "screening.beamlineListUrl"]
}
body DCS::Config::getCassetteInfoUrl {} {
   return [getStr "screening.cassetteInfoUrl"]
}
body DCS::Config::getCrystalUpdateDataUrl {} {
   return [getStr "screening.crystalUpdateUrl"]
}

body DCS::Config::getCassetteIDUrl {} {
   return [getStr "screening.cassetteIDUrl"]
}

body DCS::Config::getCassetteChangeUrl {} {
   return [getStr "screening.cassetteChangeUrl"]
}

body DCS::Config::getDefaultDataHome { } {
    puts "calling getDefaultDataHome"
   set dir [getStr "screening.defaultDataHome"]
    set dir [replaceDirectoryTags $dir]
    return $dir
}

body DCS::Config::getImpDhsImpHost { } {
    if {[get "impdhs.impHost" result] && $result != ""} {
        return $result
    }
    return [getImpersonHost]
}

body DCS::Config::getImpDhsImpPort { } {
    if {[get "impdhs.impPort" result] && $result != ""} {
        return $result
    }
    return [getImpersonPort]
}
body DCS::Config::getCrystalEditUrl {} {
   return [getStr "screening.crystalEditUrl"]
}
body DCS::Config::getSaveCrystalAttributeUrl {} {
   return [getStr "screening.crystalSetAttributeUrl"]
}
body DCS::Config::getRetrieveCrystalPropertyUrl {} {
   return [getStr "screening.crystalGetPropertyUrl"]
}
body DCS::Config::getSaveCrystalPropertyUrl {} {
   return [getStr "screening.crystalSetPropertyUrl"]
}
body DCS::Config::getCrystalChangesUrl {} {
   return [getStr "screening.crystalGetChangesUrl"]
}
body DCS::Config::getCrystalClearImagesUrl {} {
   return [getStr "screening.crystalClearImagesUrl"]
}
body DCS::Config::getCrystalClearResultsUrl {} {
   return [getStr "screening.crystalClearResultsUrl"]
}
body DCS::Config::getCrystalClearAllUrl {} {
   return [getStr "screening.crystalClearAllCrystalsUrl"]
}
body DCS::Config::getCrystalAddImageUrl {} {
   return [getStr "screening.crystalAddImageUrl"]
}
body DCS::Config::getCrystalAnalyzeImageUrl {} {
   return [getStr "screening.crystalAnalyzeImageUrl"]
}
body DCS::Config::getCenterAnalyzeImageUrl {} {
   return [getStr "screening.centerAnalyzeImageUrl"]
}
body DCS::Config::getCrystalAutoindexUrl {} {
   return [getStr "screening.crystalAutoindexUrl"]
}
body DCS::Config::getCrystalPrepareReOrientUrl {} {
   #return [getStr "screening.prepareReOrientUrl"]
    return [getCrystalAutoindexUrl]
}
body DCS::Config::getCrystalReOrientUrl {} {
   return [getStr "screening.reOrientUrl"]
}
body DCS::Config::getDefaultSILUrl { } {
   return [getStr "screening.defaultSILUrl"]
}
body DCS::Config::getUploadSILUrl { } {
   return [getStr "screening.uploadSILUrl"]
}
body DCS::Config::getDownloadSILUrl { } {
   return [getStr "screening.downloadSILUrl"]
}
body DCS::Config::getLockSILUrl { } {
   return [getStr "screening.lockSILUrl"]
}
body DCS::Config::getUnassignSILUrl { } {
   return [getStr "screening.unassignSILUrl"]
}
body DCS::Config::getDeleteSILUrl { } {
   return [getStr "screening.deleteSILUrl"]
}
body DCS::Config::getSILRowUrl { } {
   return [getStr "screening.SILRowDataUrl"]
}

body DCS::Config::getViewScreeningStrategyUrl {} {
return [getStr "screening.viewStrategyUrl"]
}

body DCS::Config::getViewCollectStrategyUrl {} {
return [getStr "collect.viewStrategyUrl"]
}

body DCS::Config::getCollectStrategyNewRunUrl {} {
return [getStr "collect.strategyNewRunUrl"]
}
body DCS::Config::getStrategyDir {} {
return [getStr "screening.strategyDir"]
}

body DCS::Config::getStrategyStatusUrl {} {
return [getStr "strategy.statusUrl"]
}

body DCS::Config::getMoveCrystalUrl {} {
return [getStr "screening.moveCrystalUrl"]
}
body DCS::Config::getSilAndEventListUrl { } {
    return [getStr "screening.silIdAndEventIdUrl"]
}

body DCS::Config::getPreCheckMotorList { } {
    return [getStr "dcss.preCheckMotorList"]
}

body DCS::Config::getBeamGoodSignal { } {
    set s [getStr "beamGood.signal"]
    if {$s == ""} {
        set s i0
    }
    return $s
}
body DCS::Config::getQueueAddRunUrl { } {
    return [getStr "queuing.addRunUrl"]
}
body DCS::Config::getQueueDeleteRunUrl { } {
    return [getStr "queuing.deleteRunUrl"]
}
body DCS::Config::getQueueGetRunUrl { } {
    return [getStr "queuing.getRunUrl"]
}
body DCS::Config::getQueueSetRunUrl { } {
    return [getStr "queuing.setRunUrl"]
}
body DCS::Config::getVideoScalingEnabled { } {
	return [getInt "video.scaling" 1]
}
body DCS::Config::getQueueAddDefaultRepositionUrl { } {
    return [getStr "queuing.addDefaultRepositionUrl"]
}
body DCS::Config::getQueueAddNormalRepositionUrl { } {
    return [getStr "queuing.addNormalRepositionUrl"]
}

body DCS::Config::getWebIceShowRunStrategyUrl { } {
    return [getStr "webice.viewRunDefStrategy"]
}
body DCS::Config::getQueueGetRepositionUrl { } {
    return [getStr "queuing.getRepositionUrl"]
}