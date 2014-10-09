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

package provide BLUICEHutchOverview 1.0

# load standard packages
package require Iwidgets
package require BWidget

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent

package require DCSDeviceView
package require DCSProtocol
package require DCSOperationManager
package require DCSHardwareManager
package require DCSPrompt
package require DCSMotorControlPanel
package require BLUICECanvasShapes



class OptimizeButton {
    inherit DCS::Button

    public method handleStart
   
    public variable m_optimizeEnergyParamsObj 
 
   	constructor { args} {
 
        eval itk_initialize $args

        configure -command "$this handleStart"
         set m_deviceFactory [DCS::DeviceFactory::getObject]

         if { [$m_deviceFactory stringExists optimizedEnergyParameters] } {
            set m_optimizeEnergyParamsObj [DCS::OptimizedEnergyParams::getObject]
            addInput "$m_optimizeEnergyParamsObj optimizeEnable 1 {Table optimizations are disabled.}"
         }

         announceExist
    }
}

body OptimizeButton::handleStart {} {

    $m_optimizeEnergyParamsObj setLastOptimizedTime 0

    ::device::optimized_energy move by 0 eV
}


class DCS::HutchOverview {
 	inherit ::itk::Widget
	
	itk_option define -detectorType detectorType DetectorType Q315CCD
	itk_option define -mdiHelper mdiHelper MdiHelper ""
	itk_option define -attenuationDevice attenuationDevice AttenuationDevice ""

    public proc getMotorList { } {
        global gMotorBeamWidth
        global gMotorBeamHeight
        global gMotorBeamStop

        return [list \
        $gMotorBeamWidth \
        $gMotorBeamHeight \
        $gMotorBeamStop \
        ]
    }
	
	public variable withSampleVideo 0
	public variable withHutchVideo 0

	# protected variables
	protected variable canvas

	# protected methods
	protected method constructGoniometer
	protected method constructDetector
	protected method constructFrontend
	protected method constructBeamstop
	protected method constructAttenuation
	protected method constructAutomation

	public method handleUpdateFromShutter
	public method handleDetectorTypeChange

	private variable _detectorObject

   public method getDetectorHorzWidget {} {return $itk_component(detector_horz)}
	public method getDetectorVertWidget {} {return $itk_component(detector_vert)} 
	public method getDetectorZWidget {} {return $itk_component(detector_z)}
	public method getBeamstopZWidget {} {return $itk_component(beamstop)}
	public method getEnergyWidget {} {return $itk_component(energy)}
	public method getBeamWidthWidget {} {return $itk_component(beamWidth)}
	public method getBeamHeightWidget {} {return $itk_component(beamHeight)}
   
   private variable m_deviceFactory

	constructor { args} {
		# call base class constructor
		::DCS::Component::constructor {}
	} {
      set m_deviceFactory [DCS::DeviceFactory::getObject]

		itk_component add canvas {
			canvas $itk_interior.c -width 1000 -height 285
		}

		# construct the panel of control buttons
		itk_component add control {
			::DCS::MotorControlPanel $itk_component(canvas).control \
				 -width 7 -orientation "horizontal" \
				 -ipadx 0 -ipady 0  -buttonBackground #c0c0ff \
				 -activeButtonBackground #c0c0ff  -font "helvetica -14 bold"
		} {
		}
			 
		place $itk_component(control) -x 30 -y 10

		# construct the goniometer widgets
		constructGoniometer 440 250

		# construct the detector widgets
		itk_component add detector_vert {
			::DCS::TitledMotorEntry $itk_component(canvas).detector_vert \
				 -unitsList default \
				 -menuChoiceDelta 25  -units mm -unitsWidth 4 \
				 -entryWidth 10 \
				 -labelText "Vertical" \
                -activeClientOnly 0 \
                -systemIdleOnly 0 \
                -honorStatus 0
		} {
		   keep -mdiHelper
		   rename -device detectorVertDevice detectorVertDevice DetectorVertDevice
		}
		
		itk_component add detector_z {
			# create motor view for detector_z
			::DCS::TitledMotorEntry $itk_component(canvas).detector_z \
                -checkLimits -1 \
				 -labelText "Distance" -unitsList default \
             -menuChoiceDelta 50 \
				 -entryType positiveFloat -units mm -unitsWidth 3 \
				 -entryWidth 8 \
                -activeClientOnly 0 \
                -systemIdleOnly 0 \
                -honorStatus 0
		} {
			keep -mdiHelper
			rename -device detectorZDevice detectorZDevice DetectorZDevice
		}

		itk_component add detector_horz {
			# create motor view for detector_horiz
			::DCS::TitledMotorEntry $itk_component(canvas).detector_horz \
				 -unitsList default \
				 -menuChoiceDelta 25  -units mm -unitsWidth 4 \
				 -entryWidth 10 \
				 -labelText "Horizontal" \
                -activeClientOnly 0 \
                -systemIdleOnly 0 \
                -honorStatus 0
		} {
			keep -mdiHelper
			rename -device detectorHorzDevice detectorHorzDevice DetectorHorzDevice
		}
		
		itk_component add energy {
			# create motor view for detector_horiz
			::DCS::TitledMotorEntry $itk_component(canvas).energy \
				 -labelText "Energy" \
                 -checkLimits -1 \
				 -entryWidth 10 \
				 -autoGenerateUnitsList 0 \
            -unitsList {A {-decimalPlaces 5 -menuChoiceDelta 0.1} eV {-decimalPlaces 3 -menuChoiceDelta 1000} keV {-decimalPlaces 6 -menuChoiceDelta 1.0}} \
				 -unitsWidth 4 \
                -activeClientOnly 0 \
                -systemIdleOnly 0 \
                -honorStatus 0
		} {
			keep -mdiHelper
			rename -device energyDevice energyDevice EnergyDevice
		}

		place $itk_component(canvas).energy -x 15 -y 200

      #only add optimize button if the optimized_energy motor exists on this beam line.
      if { [$m_deviceFactory motorExists optimized_energy]} {

		   itk_component add optimize {
			   # make the optimize beam button
			   OptimizeButton $itk_component(canvas).optimize \
				 -text "Optimize Beam" \
				 -width 10
		   } {
			   keep -foreground
		   }

		place $itk_component(optimize) -x 15 -y 255
      }

		$itk_component(control) registerMotorWidget ::$itk_component(detector_vert)
		$itk_component(control) registerMotorWidget ::$itk_component(detector_horz)
		$itk_component(control) registerMotorWidget ::$itk_component(detector_z)
		$itk_component(control) registerMotorWidget ::$itk_component(energy)


		# construct the frontend widgets
		constructFrontend 0 0

		# construct the beamstop widgets
		constructBeamstop 0 0

		#create on object for watching the detector
		set _detectorObject [DCS::Detector::getObject]

		pack $itk_component(canvas)
        eval itk_initialize $args

		::mediator register $this ::$_detectorObject type handleDetectorTypeChange

		::mediator announceExistence $this

      set m_deviceFactory [DCS::DeviceFactory::getObject]
		set shutterObject [$m_deviceFactory createShutter shutter]
		::mediator register $this $shutterObject state handleUpdateFromShutter
		
		return
	}
    
    destructor { }
}

body DCS::HutchOverview::destructor {} {
	mediator announceDestruction $this
}


#draw the postshutter view of the beam
body DCS::HutchOverview::handleUpdateFromShutter { shutter_ targetReady_ - state_ -} {

	if { ! $targetReady_ } return

	switch $state_ {
		
		open {
			$itk_component(canvas) itemconfigure postShutterBeam -fill magenta
			$itk_component(canvas) raise postShutterBeam
		}
		
		closed {
			$itk_component(canvas) itemconfigure postShutterBeam -fill lightgrey
			$itk_component(canvas) lower postShutterBeam
		}
	}
}



body DCS::HutchOverview::constructGoniometer { x y } {

	# draw and label the goniometer
	global BLC_IMAGES

	set goniometerImage [ image create photo -file "$BLC_IMAGES/gonio.gif" -palette "8/8/8"]
	
#	itk_component add goniometerImage {
		$itk_component(canvas) create image $x [expr $y - 190] -anchor nw -image $goniometerImage
#	}

	itk_component add phi {
		# create motor view for gonio_phi
		::DCS::TitledMotorEntry $itk_component(canvas).phi \
			 -labelText "Phi" \
			 -autoMenuChoices 0 \
			 -shadowReference 1 \
			 -units "deg" -menuChoices {0.000 45.000 90.000 135.000 180.000 \
												 225.000 270.000 315.000 360.000}  \
          -activeClientOnly 1
	}  {
        keep -systemIdleOnly
		keep -mdiHelper
		rename -device gonioPhiDevice gonioPhiDevice GonioPhiDevice
	}

	place $itk_component(phi) -x [expr $x + 20]  -y [expr $y - 245]
	
	
	# create motor view for gonio_omega
	itk_component add omega {
		::DCS::TitledMotorEntry $itk_component(canvas).omega \
			 -labelText "Omega"  -autoGenerateUnitsList 0 \
			 -unitsWidth 4 -unitsList {deg {-menuChoiceDelta 15}} -activeClientOnly 1
	} {
        keep -systemIdleOnly
		keep -mdiHelper
		rename -device gonioOmegaDevice gonioOmegaDevice GonioOmegaDevice
	}

	place $itk_component(omega) -x [expr $x - 110] -y [expr $y -185]
	
	# create motor view for gonio_kappa
	itk_component add kappa {
		::DCS::TitledMotorEntry $itk_component(canvas).kappa \
			 -labelText "Kappa"  -autoGenerateUnitsList 0 \
          -unitsWidth 4 -unitsList {deg {-menuChoiceDelta 5 -precision .001}} -activeClientOnly 1
	} {
        keep -systemIdleOnly
		keep -mdiHelper
		rename -device gonioKappaDevice gonioKappaDevice GonioKappaDevice
	}

	place $itk_component(kappa) -x [expr $x + 140] -y [expr $y - 185]

	$itk_component(control) registerMotorWidget ::$itk_component(phi)
	$itk_component(control) registerMotorWidget ::$itk_component(omega)
	$itk_component(control) registerMotorWidget ::$itk_component(kappa)

}

body DCS::HutchOverview::constructFrontend { x y } {

	# create the image of the frontend
	global BLC_IMAGES
	set frontendImage [ image create photo \
									-file "$BLC_IMAGES/frontend.gif" \
									-palette "8/8/8"]
	$itk_component(canvas) create image 50 72 -anchor nw -image $frontendImage

	# draw the label for the frontend
	label $itk_component(canvas).frontendLabel \
		 -font "helvetica -18 bold" \
		 -text "Beam Collimator"

	#	place $itk_component(canvas).frontendLabel -x 130 -y 265

	# draw the X-ray beam entering the collimator
	$itk_component(canvas) create line 0 161 58 161 -fill magenta -width 4

	# draw the beam after the shutter
	$itk_component(canvas) create line 383 163 620 163 -fill magenta -width 2 -tag postShutterBeam
	
	#$energyWidget addInput "${deviceNamespace}::mono_theta status inactive {supporting device}"

	#$itk_component(control) registerMotorWidget ::$energyWidget

	# create motor view for detector_horiz
	itk_component add beamWidth {
		::DCS::TitledMotorEntry $itk_component(canvas).beam_width \
            -updateValueOnMatch 1 \
			 -labelText "Beam Width" \
			 -entryWidth 5  -autoGenerateUnitsList 0 \
         -unitsList {mm {-entryType positiveFloat -menuChoiceDelta 0.05}} -activeClientOnly 1
	} {
        keep -systemIdleOnly
		keep -mdiHelper
		rename -device beamWidthDevice beamWidthDevice BeamWidthDevice
	}

	# create motor view for detector_horiz
	itk_component add beamHeight {
		::DCS::TitledMotorEntry $itk_component(canvas).beam_height \
            -updateValueOnMatch 1 \
            -precision 0.001 \
			 -labelText "Beam Height" \
			 -entryWidth 5 -autoGenerateUnitsList 0 \
         -unitsList {mm {-entryType positiveFloat -menuChoiceDelta 0.05} } -activeClientOnly 1
	} {
        keep -systemIdleOnly
		keep -mdiHelper
		rename -device beamHeightDevice beamHeightDevice BeamHeightDevice
	}

	$itk_component(canvas) create text 320 233 -text "x" -font "helvetica -14 bold"


	place $itk_component(beamWidth) -x 211 -y 200
	place $itk_component(beamHeight) -x 330 -y 200
	
	$itk_component(control) registerMotorWidget ::$itk_component(beamWidth)
	$itk_component(control) registerMotorWidget ::$itk_component(beamHeight)	

   constructAttenuation

}

body DCS::HutchOverview::constructAttenuation { } {

   if { ![$m_deviceFactory motorExists attenuation]} return

    set deci [::config getInt decimal.attenuation 1]

	# create motor view for beam attenuation
	itk_component add attenuation {
		::DCS::TitledMotorEntry $itk_component(canvas).attenuation \
			 -labelText "Attenuation" \
			 -entryType positiveFloat \
			 -menuChoiceDelta 10 -units "%"  -autoGenerateUnitsList 0 \
			 -decimalPlaces $deci \
         -activeClientOnly 0
	} {
        keep -systemIdleOnly
		keep -mdiHelper
		rename -device attenuationDevice attenuationDevice AttenuationDevice
	}


	place $itk_component(attenuation) -x 80 -y 90
	$itk_component(control) registerMotorWidget ::$itk_component(attenuation)
}

body DCS::HutchOverview::constructBeamstop { x y } {

	# create the image of the frontend
	global BLC_IMAGES
	set beamstopImage [ image create photo -file "$BLC_IMAGES/beamstop.gif" -palette "8/8/8"]
	$itk_component(canvas) create image 570 159 -anchor nw -image $beamstopImage

	# draw the label for the frontend
	label $itk_component(canvas).beamstopLabel \
		 -font "helvetica -18 bold" \
		 -text "Beamstop"
	#	place $itk_component(canvas).beamstopLabel -x 530 -y 265
	
	# create motor view for beamstop_z
	itk_component add beamstop {
		::DCS::TitledMotorEntry $itk_component(canvas).beamstop \
			 -labelText "Beamstop" \
			 -menuChoiceDelta 5 \
			 -entryType positiveFloat \
			 -decimalPlaces 3 -units mm \
             -activeClientOnly 0 \
             -systemIdleOnly 0 \
             -honorStatus 0
	} {
		keep -mdiHelper
		rename -device beamstopDevice beamstopDevice BeamstopDevice
	}


	place $itk_component(beamstop) -x 530 -y 225
	$itk_component(control) registerMotorWidget ::$itk_component(beamstop)

	# draw arrow for beam stop motion
	$itk_component(canvas) create line 580 190 620 190 -arrow both -width 3 -fill black	
	$itk_component(canvas) create text 613 180 -text "+" -font "courier -10 bold"
	$itk_component(canvas) create text 584 180 -text "-" -font "courier -10 bold"
}

body DCS::HutchOverview::handleDetectorTypeChange { detector_ targetReady_ alias_ type_ -  } {
	
	if { ! $targetReady_} return
	configure -detectorType $type_
}


configbody DCS::HutchOverview::detectorType {

	# draw and label the detector
	global BLC_IMAGES

	set x 0
	set y 0

	#delete any old graphic items from a previous detector configuration
	$itk_component(canvas) delete detectorItems

	#draw the detector items
	switch $itk_option(-detectorType) {

		Q4CCD {

			place $itk_component(detector_vert) -x 835 -y 0
			place $itk_component(detector_z) -x 660 -y 125
			place $itk_component(detector_horz) -x 855 -y 212

			set detectorImage [ image create photo \
											-file "$BLC_IMAGES/q4_small.gif" \
											-palette "8/8/8"]
			$itk_component(canvas) create image 820 90 \
				 -anchor nw \
				 -image $detectorImage -tag detectorItems
			
			$itk_component(canvas) create line 900 55 900 95 -arrow both -width 3 -fill black -tag detectorItems	
			$itk_component(canvas) create text 910 61 -text "+" -font "courier -10 bold" -tag detectorItems
			$itk_component(canvas) create text 910 88 -text "-" -font "courier -10 bold" -tag detectorItems
			
			$itk_component(canvas) create line 796 157 821 157 -arrow first -width 3 -fill black -tag detectorItems
			$itk_component(canvas) create line 821 157 836 157 -arrow last  -width 3 -fill white -tag detectorItems
			$itk_component(canvas) create text 800 148 -text "-" -font "courier -10 bold" -tag detectorItems
			$itk_component(canvas) create text 835 148 -text "+" -font "courier -10 bold" -fill white -tag detectorItems
			
			$itk_component(canvas) create line 913 185 942 212 -arrow both -width 3 -fill black	 -tag detectorItems
			$itk_component(canvas) create text 927 188 -text "+" -font "courier -10 bold" -tag detectorItems
			$itk_component(canvas) create text 948 207 -text "-" -font "courier -10 bold"	-tag detectorItems
		}
		
		Q315CCD {
			place $itk_component(detector_vert) -x 835 -y 0 
			place $itk_component(detector_z) -x 660 -y 125
			place $itk_component(detector_horz) -x 855 -y 212

			set detectorImage [ image create photo \
											-file "$BLC_IMAGES/q4_small.gif" \
											-palette "8/8/8" ]

			$itk_component(canvas) create image 820 90 \
				 -anchor nw \
				 -image $detectorImage 	-tag detectorItems
			
			$itk_component(canvas) create line 900 55 900 95 -arrow both -width 3 -fill black -tag detectorItems	
			$itk_component(canvas) create text 910 61 -text "+" -font "courier -10 bold"	-tag detectorItems
			$itk_component(canvas) create text 910 88 -text "-" -font "courier -10 bold"	-tag detectorItems
			
			$itk_component(canvas) create line 796 157 821 157 -arrow first -width 3 -fill black -tag detectorItems
			$itk_component(canvas) create line 821 157 836 157 -arrow last  -width 3 -fill white -tag detectorItems
			$itk_component(canvas) create text 800 148 -text "-" -font "courier -10 bold"	-tag detectorItems
			$itk_component(canvas) create text 835 148 -text "+" -font "courier -10 bold" -fill white	-tag detectorItems
			
			$itk_component(canvas) create line 913 185 942 212 -arrow both -width 3 -fill black	-tag detectorItems
			$itk_component(canvas) create text 927 188 -text "+" -font "courier -10 bold"	-tag detectorItems
			$itk_component(canvas) create text 948 207 -text "-" -font "courier -10 bold"	-tag detectorItems
		}

		MAR345 {
			place $itk_component(detector_vert) -x 835 -y 0
			place $itk_component(detector_z) -x 657 -y 125
			place $itk_component(detector_horz) -x 855 -y 235

			set detectorImage [ image create photo \
											-file "$BLC_IMAGES/mar_small.gif" \
											-palette "8/8/8"]

			$itk_component(canvas) create image 815 53 \
				 -anchor nw \
				 -image $detectorImage 	-tag detectorItems

			$itk_component(canvas) create line 900 55 900 95 -arrow both -width 3 -fill black 	-tag detectorItems	
			$itk_component(canvas) create text 910 61 -text "+" -font "courier -10 bold" 	-tag detectorItems
			$itk_component(canvas) create text 910 88 -text "-" -font "courier -10 bold" 	-tag detectorItems
			
			$itk_component(canvas) create line 791 157 821 157 -arrow both -width 3 -fill black 	-tag detectorItems
			$itk_component(canvas) create text 796 148 -text "-" -font "courier -10 bold" 	-tag detectorItems
			$itk_component(canvas) create text 817 148 -text "+" -font "courier -10 bold" 	-tag detectorItems
		
			$itk_component(canvas) create line 903 210 915 222 -arrow first -width 3 -fill white	-tag detectorItems
			$itk_component(canvas) create line 915 222 927 234 -arrow last -width 3 -fill black	-tag detectorItems
			$itk_component(canvas) create text 898 215 -text "+" -font "courier -10 bold" -fill white	-tag detectorItems
			$itk_component(canvas) create text 911 232 -text "-" -font "courier -10 bold"		-tag detectorItems
		}

		MAR165 {

			place $itk_component(detector_vert) -x 835 -y 30
			place $itk_component(detector_z) -x 657 -y 125
			place $itk_component(detector_horz) -x 855 -y 203

			set detectorImage [ image create photo \
											-file "$BLC_IMAGES/mar165.gif" \
											-palette "8/8/8"]
			$itk_component(canvas) create image 817 107 \
				 -anchor nw \
				 -image $detectorImage -tag detectorItems

			$itk_component(canvas) create line 900 85 900 125 -arrow both -width 3 -fill black -tag detectorItems	
			$itk_component(canvas) create text 910 91 -text "+" -font "courier -10 bold" -tag detectorItems
			$itk_component(canvas) create text 910 1288 -text "-" -font "courier -10 bold" -tag detectorItems
			
			$itk_component(canvas) create line 791 157 821 157 -arrow both -width 3 -fill black -tag detectorItems
			$itk_component(canvas) create text 796 148 -text "-" -font "courier -10 bold" -tag detectorItems
			$itk_component(canvas) create text 817 148 -text "+" -font "courier -10 bold" -tag detectorItems
			
			$itk_component(canvas) create line 903 178 915 190 -arrow first -width 3 -fill white -tag detectorItems
			$itk_component(canvas) create line 915 190 927 202 -arrow last -width 3 -fill black -tag detectorItems
			$itk_component(canvas) create text 898 183 -text "+" -font "courier -10 bold" -fill white -tag detectorItems
			$itk_component(canvas) create text 911 200 -text "-" -font "courier -10 bold"	-tag detectorItems
		}
		MAR325 {
			place $itk_component(detector_vert) -x 835 -y 0 
			place $itk_component(detector_z) -x 660 -y 125
			place $itk_component(detector_horz) -x 855 -y 212

			set detectorImage [ image create photo \
											-file "$BLC_IMAGES/mar325.gif" \
											-palette "8/8/8" ]

			$itk_component(canvas) create image 820 90 \
				 -anchor nw \
				 -image $detectorImage 	-tag detectorItems
			
			$itk_component(canvas) create line 900 55 900 95 -arrow both -width 3 -fill black -tag detectorItems	
			$itk_component(canvas) create text 910 61 -text "+" -font "courier -10 bold"	-tag detectorItems
			$itk_component(canvas) create text 910 88 -text "-" -font "courier -10 bold"	-tag detectorItems
			
			$itk_component(canvas) create line 796 157 821 157 -arrow first -width 3 -fill black -tag detectorItems
			$itk_component(canvas) create line 821 157 836 157 -arrow last  -width 3 -fill white -tag detectorItems
			$itk_component(canvas) create text 800 148 -text "-" -font "courier -10 bold"	-tag detectorItems
			$itk_component(canvas) create text 835 148 -text "+" -font "courier -10 bold" -fill white	-tag detectorItems
			
			$itk_component(canvas) create line 913 185 942 212 -arrow both -width 3 -fill black	-tag detectorItems
			$itk_component(canvas) create text 927 188 -text "+" -font "courier -10 bold"	-tag detectorItems
			$itk_component(canvas) create text 948 207 -text "-" -font "courier -10 bold"	-tag detectorItems
		}


		PILATUS6 {
			place $itk_component(detector_vert) -x 835 -y 0 
			place $itk_component(detector_z) -x 660 -y 125
			place $itk_component(detector_horz) -x 855 -y 212

			set detectorImage [ image create photo \
											-file "$BLC_IMAGES/pilatus6.gif" \
											-palette "8/8/8" ]

			$itk_component(canvas) create image 820 90 \
				 -anchor nw \
				 -image $detectorImage 	-tag detectorItems
			
			$itk_component(canvas) create line 900 55 900 95 -arrow both -width 3 -fill black -tag detectorItems	
			$itk_component(canvas) create text 910 61 -text "+" -font "courier -10 bold"	-tag detectorItems
			$itk_component(canvas) create text 910 88 -text "-" -font "courier -10 bold"	-tag detectorItems
			
			$itk_component(canvas) create line 796 157 821 157 -arrow first -width 3 -fill black -tag detectorItems
			$itk_component(canvas) create line 821 157 836 157 -arrow last  -width 3 -fill white -tag detectorItems
			$itk_component(canvas) create text 800 148 -text "-" -font "courier -10 bold"	-tag detectorItems
			$itk_component(canvas) create text 835 148 -text "+" -font "courier -10 bold" -fill white	-tag detectorItems
			
			$itk_component(canvas) create line 913 185 942 212 -arrow both -width 3 -fill black	-tag detectorItems
			$itk_component(canvas) create text 927 188 -text "+" -font "courier -10 bold"	-tag detectorItems
			$itk_component(canvas) create text 948 207 -text "-" -font "courier -10 bold"	-tag detectorItems
		}




		default {
			place $itk_component(detector_vert) -x 835 -y 30
			place $itk_component(detector_z) -x 657 -y 125
			place $itk_component(detector_horz) -x 855 -y 203

			$itk_component(canvas) create line 900 85 900 125 -arrow both -width 3 -fill black -tag detectorItems	
			$itk_component(canvas) create text 910 91 -text "+" -font "courier -10 bold" -tag detectorItems
			$itk_component(canvas) create text 910 1288 -text "-" -font "courier -10 bold" -tag detectorItems
			
			$itk_component(canvas) create line 791 157 821 157 -arrow both -width 3 -fill black -tag detectorItems
			$itk_component(canvas) create text 796 148 -text "-" -font "courier -10 bold" -tag detectorItems
			$itk_component(canvas) create text 817 148 -text "+" -font "courier -10 bold" -tag detectorItems
			
			$itk_component(canvas) create line 903 178 927 202 -arrow both -width 3 -fill black -tag detectorItems
			$itk_component(canvas) create text 898 183 -text "+" -font "courier -10 bold" -fill white -tag detectorItems
			$itk_component(canvas) create text 911 200 -text "-" -font "courier -10 bold"	-tag detectorItems

		}
	}
}







class DCS::DetectorPositionView {
 	inherit ::DCS::CanvasShapes

	itk_option define -mdiHelper mdiHelper MdiHelper ""

    public proc getMotorList { } {
        return [list \
        detector_z_corr \
        detector_z \
        gonio_z \
        detector_vert \
        detector_horz \
        ]
    }

	constructor { args} {

		place $itk_component(control) -x 30 -y 80

      set m_deviceFactory [DCS::DeviceFactory::getObject]
      if { [$m_deviceFactory motorExists detector_z_corr]} {
        set detectorZ detector_z_corr

        #only add encoder button if the detector_z_corr motor exists on this beam line.
		   itk_component add setEncoder {
			   # make the optimize beam button
			    DetectorDistanceEncoderSetButton $itk_component(canvas).des
		   } {
		   }

		   place $itk_component(setEncoder) -x 470 -y 300 
      } else {
        set detectorZ detector_z
      }


      if { [$m_deviceFactory motorExists gonio_z]} {
         motorView gonio_z 135 203 e
		   motorArrow gonio_z 180 230 {} 134 230 176 216 140 216
      }

		# construct the slit 0 widgets
		motorView $detectorZ 590 235 w
      motorView detector_vert 417 209 se
      motorView detector_horz 400 314 n

		# draw the table
		rect_solid 80 220 430 20 60 85 65

      if { [$m_deviceFactory motorExists gonio_z]} {

		# draw the goniometer trolley
		rect_solid 130 190 50 20 80 100 95

        }

		# draw the gantry trolley
		rect_solid 410 190 60 20 80 95 90

		# draw the back vertical beam
		rect_solid 482 61 35 150 8 10 9
	
		# draw the detector
		rect_solid 423 90 120 60 20 30 27
		
		# draw the front vertical beam
		rect_solid 443 82 40 160 8 10 9
		
		# draw the gantry top bar
		rect_solid 443 50 40 20 30 50 43
		
		motorArrow $detectorZ 590 230 {} 525 230 584 219 535 219
		motorArrow detector_horz 440 280 {} 400 313 447 284 419 310
		motorArrow detector_vert 432 170 {} 432 240 420 176 420 234

		#place $itk_component(detectorPitchDevice) 620 120 w 125 45 9
		#motorArrow $itk_component(canvas) $itk_component(detectorPitch)  580 95 {610 105 610 145} 580 155 594 88 593 161
	
		eval itk_initialize $args
		$itk_component(canvas) configure -width 750 -height 420
	}
}



class DetectorDistanceEncoderSetButton {
    inherit ::itk::Widget

    public method handleConfigure
    public method handleEditValue
    
   	constructor { args } {} {
 
        set yellow #d0d000

        itk_component add frame {
           iwidgets::labeledframe $itk_interior.f -labeltext "Configure detector_z encoder:" 
        } {}

        set ring [$itk_component(frame) childsite]

        itk_component add value {
           DCS::Entry $ring.e -promptText "Enter detector_z position:" \
				 -entryWidth 10 -unitsWidth 3 -units "mm" \
				 -entryType positiveFloat -decimalPlaces 4 \
				 -activeClientOnly 0 -systemIdleOnly 0
        } {}

        itk_component add apply {
           DCS::Button $ring.b -text "Set detector_z encoder" \
				 -width 25 -activebackground $yellow -background $yellow -activeClientOnly 1
        } {}

        $itk_component(apply) configure -command "$this handleConfigure"
        set m_deviceFactory [DCS::DeviceFactory::getObject]

        $itk_component(apply) addInput "::device::detector_z_corr status inactive {supporting device}"

       pack $itk_component(frame)
       pack $itk_component(value)
       pack $itk_component(apply)

        eval itk_initialize $args
      ::mediator announceExistence $this
      ::mediator register $this ::$itk_component(value) -value handleEditValue
    }

   destructor {
      ::mediator announceDestruction $this
   }

}

body DetectorDistanceEncoderSetButton::handleConfigure {} {

    set position [lindex [$itk_component(value) get] 0]
    if {$position == "" } return

    #set position [::device::detector_z_corr getScaledPosition]
    set upperLimit [lindex [::device::detector_z_corr getUpperLimit] 0]
    set lowerLimit [lindex [::device::detector_z_corr getLowerLimit] 0]
    set lowerLimitOn [::device::detector_z_corr getLowerLimitOn]
    set upperLimitOn [::device::detector_z_corr getUpperLimitOn]
    set locked [::device::detector_z_corr getLockOn]

    set position [lindex [$itk_component(value) get] 0]

    ::device::detector_z_corr changeMotorConfiguration $position $upperLimit $lowerLimit $lowerLimitOn $upperLimitOn $locked
}


body DetectorDistanceEncoderSetButton::handleEditValue {objName_ targetReady_ alias_ value_ -} {

   if {!$targetReady_} return

   if { $value_ == "{} mm" || [lindex $value_ 0] == 0.0 } {
      $itk_component(apply) configure -state disabled
   } else {
      $itk_component(apply) configure -state normal
   }
}
