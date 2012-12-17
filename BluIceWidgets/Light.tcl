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

package provide BLUICELightControl 1.0

# load standard packages
package require Iwidgets

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent

package require DCSProtocol
package require DCSOperationManager
package require DCSDeviceView
package require DCSDeviceFactory

class LightControlWidget {
    inherit ::itk::Widget

    #options
    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""

    public method handleStatusEvent
    public method handleClick { } {
        set text [$itk_component(back_light) cget -text]
        if {$text == "Turn On"} {
            set value 0
        } else {
            set value 1
        }
        $m_objBackLight startOperation \
        $BACK_LIGHT_BOARD_NO $BACK_LIGHT_CHANNEL_NO $value
    }

    private variable m_deviceFactory
    private variable m_objSideLight
    private variable m_objBackLight
    private variable m_objDOStatus

    private variable m_available 0
    private variable m_lightSite

    #### which bit controls back light
    private variable BACK_LIGHT_CHANNEL_NO -1
    private variable BACK_LIGHT_BOARD_NO -1
    private variable SIDE_LIGHT_CHANNEL_NO -1
    private variable SIDE_LIGHT_BOARD_NO -1

    #contructor/destructor
    constructor { args  } {
        set cfgBackLight [::config getStr light.back]
        if {[llength $cfgBackLight] == 2} {
            foreach {BACK_LIGHT_BOARD_NO BACK_LIGHT_CHANNEL_NO} \
            $cfgBackLight break
            puts "backlight: $cfgBackLight"
        } else {
            log_error find cannot light.back in config file
        }
        set cfgSideLight [::config getStr light.side]
        if {[llength $cfgSideLight] == 2} {
            foreach {SIDE_LIGHT_BOARD_NO SIDE_LIGHT_CHANNEL_NO} \
            $cfgSideLight break
            puts "sidelight: $cfgSideLight"
        } else {
            log_error cannot find light.side in config file
        }

        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_objSideLight [$m_deviceFactory getObjectName \
        aoDaq$SIDE_LIGHT_BOARD_NO$SIDE_LIGHT_CHANNEL_NO]
        set m_objBackLight [$m_deviceFactory createOperation setDigOutBit]
        set m_objDOStatus  [$m_deviceFactory createString \
        digitalOutStatus$BACK_LIGHT_BOARD_NO]

        itk_component add lightFrame {
            iwidgets::labeledframe $itk_interior.ring \
            -labelpos nw \
            -labeltext "Sample Lights Control"
        } {
        }
        set m_lightSite [$itk_component(lightFrame) childsite]

        itk_component add not_available {
            label $m_lightSite.not \
            -text "not available on this beamline"
        } {
        }

        itk_component add back_label {
            label $m_lightSite.blabel \
            -text "Back Light"
        } {
        }
        itk_component add side_label {
            label $m_lightSite.slabel \
            -text "Side Light Intensity"
        } {
        }

        itk_component add side_light {
            DCS::MotorScale $m_lightSite.l0 \
            -device $m_objSideLight \
            -resolution -0.1 \
            -showvalue 0 \
            -orient horizontal
        } {
        }
        itk_component add back_light {
            DCS::Button $m_lightSite.l1 \
            -text "not ready" \
            -width 10 \
            -command "$this handleClick"
        } {
        }

    
        grid $itk_component(not_available)

        pack $itk_component(lightFrame) -fill x

        eval itk_initialize $args
        $m_objDOStatus register $this contents handleStatusEvent
    }
    destructor {
        $m_objDOStatus unregister $this contents handleStatusEvent
    }
}

body LightControlWidget::handleStatusEvent { stringName_ targetReady_ alias_ contents_ - } {
    set available 1
    if {!$targetReady_} {
        set m_ready 0
        set text "not ready"
    }

    set value [lindex $contents_ $BACK_LIGHT_CHANNEL_NO]
    if {$value == ""} {
        set available 0
        set text "not ready"
    } elseif {$value} {
        set text "Turn On"
    } else {
        set text "Turn Off"
    }
    
    $itk_component(back_light) config -text $text
    if {$available != $m_available} {
        set m_available $available

        #pack forget $itk_component(lightFrame)
        set all [grid slaves $m_lightSite]
        if {[llength $all] > 0} {
            eval grid forget $all
        }

        if {$m_available} {
            grid $itk_component(back_label) $itk_component(side_label) -sticky news
            grid $itk_component(back_light) $itk_component(side_light) -sticky news
            grid columnconfig $m_lightSite 1 -weight 10
        } else {
            grid $itk_component(not_available)
        }
        #pack $itk_component(lightFrame) -fill x
    }
}

class ComboLightControlWidget {
    inherit ::itk::Widget

    #options
    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""

    itk_option define -switchWrap switchWrap SwitchWrap "" {
        if {$m_switchWrap != ""} {
            $m_switchWrap unregister $this value handleSwitch
            set m_switchWrap ""
        }
        set m_switchWrap $itk_option(-switchWrap)
        if {$m_switchWrap != ""} {
            $m_switchWrap register $this value handleSwitch
        }
    }

    public method handleStatusEvent
    public method handleInlineStatusEvent
    private method update_display

    public method handleZoomSwitchEvent { - ready_ - pos - } {
        if {!$ready_ || ![$m_deviceFactory motorExists zoomSwitch] || \
        [$m_mtZoomSwitch cget -scaledPosition] == 0.0} {
            set m_displayingInlineLight 0
        } else {
            set m_displayingInlineLight 1
        }
        update_display
    }
    public method handleSwitch { - ready_ - pos - } {
        if {!$ready_ || $pos != 1} {
            set m_displayingInlineLight 0
        } else {
            set m_displayingInlineLight 1
        }
        update_display
    }


    public method handleClick { } {
        if {!$m_displayingInlineLight} {
            set text [$itk_component(back_light) cget -text]
            if {$text == "Turn On"} {
                set value 0
            } else {
                set value 1
            }
            $m_objBackLight startOperation \
            $BACK_LIGHT_BOARD_NO $BACK_LIGHT_CHANNEL_NO $value
        } else {
            set text [$itk_component(back_light) cget -text]
            if {$text == "Insert"} {
                $m_objInlineLightControl startOperation insert
            } else {
                $m_objInlineLightControl startOperation remove
            }
        }
    }

    private variable m_deviceFactory
    private variable m_objSideLight
    private variable m_objInlineLight
    private variable m_objBackLight
    private variable m_objDOStatus
    private variable m_mtZoomSwitch 
    private variable m_objInlineLightControl
    private variable m_objInlineLightStatus

    private variable m_ready 0
    private variable m_inlineReady 0
    private variable m_text "Not Available"
    private variable m_inlineText "Not Available"

    private variable m_available 0
    private variable m_lightSite

    private variable m_displayingInlineLight 0

    private variable m_switchWrap ""

    #### which bit controls back light
    private variable BACK_LIGHT_CHANNEL_NO -1
    private variable BACK_LIGHT_BOARD_NO -1
    private variable SIDE_LIGHT_CHANNEL_NO -1
    private variable SIDE_LIGHT_BOARD_NO -1
    ### inline light insert is done vis operation on galil not PC DIO
    ### it is part of hardware interlock with beam stop
    private variable INLINE_LIGHT_DIMMER_CHANNEL_NO -1
    private variable INLINE_LIGHT_DIMMER_BOARD_NO -1

    #contructor/destructor
    constructor { args  } {
        set cfgBackLight [::config getStr light.back]
        if {[llength $cfgBackLight] == 2} {
            foreach {BACK_LIGHT_BOARD_NO BACK_LIGHT_CHANNEL_NO} \
            $cfgBackLight break
            puts "backlight: $cfgBackLight"
        } else {
            log_error find cannot light.back in config file
        }
        set cfgSideLight [::config getStr light.side]
        if {[llength $cfgSideLight] == 2} {
            foreach {SIDE_LIGHT_BOARD_NO SIDE_LIGHT_CHANNEL_NO} \
            $cfgSideLight break
            puts "sidelight: $cfgSideLight"
        } else {
            log_error cannot find light.side in config file
        }
        set cfgInlineLight [::config getStr light.inline_dim]
        if {[llength $cfgInlineLight] == 2} {
            foreach \
            {INLINE_LIGHT_DIMMER_BOARD_NO INLINE_LIGHT_DIMMER_CHANNEL_NO} \
            $cfgInlineLight break
            puts "inlinelight: $cfgInlineLight"
        } else {
            log_error cannot find light.inline_dim in config file
        }

        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_objSideLight [$m_deviceFactory getObjectName \
        aoDaq$SIDE_LIGHT_BOARD_NO$SIDE_LIGHT_CHANNEL_NO]
        set m_objInlineLight [$m_deviceFactory getObjectName \
        aoDaq$INLINE_LIGHT_DIMMER_BOARD_NO$INLINE_LIGHT_DIMMER_CHANNEL_NO]
        set m_objBackLight [$m_deviceFactory createOperation setDigOutBit]
        set m_objDOStatus  [$m_deviceFactory createString \
        digitalOutStatus$BACK_LIGHT_BOARD_NO]

        set m_mtZoomSwitch [$m_deviceFactory getObjectName zoomSwitch]

        set m_objInlineLightControl \
        [$m_deviceFactory createOperation inlineLightControl]

        set m_objInlineLightStatus \
        [$m_deviceFactory getObjectName inlineLightStatus]

        itk_component add lightFrame {
            iwidgets::labeledframe $itk_interior.ring \
            -labelpos nw \
            -labeltext "Sample Lights Control"
        } {
        }
        set m_lightSite [$itk_component(lightFrame) childsite]

        itk_component add not_available {
            label $m_lightSite.not \
            -text "not available on this beamline"
        } {
        }

        itk_component add back_label {
            label $m_lightSite.blabel \
            -text "Back Light"
        } {
        }
        itk_component add side_label {
            label $m_lightSite.slabel \
            -text "Side Light Intensity"
        } {
        }

        itk_component add side_light {
            DCS::MotorScale $m_lightSite.l0 \
            -device $m_objSideLight \
            -resolution -0.1 \
            -showvalue 0 \
            -orient horizontal
        } {
        }
        itk_component add back_light {
            DCS::Button $m_lightSite.l1 \
            -text "not ready" \
            -width 10 \
            -command "$this handleClick"
        } {
        }

        $itk_component(back_light) addInput \
        "$m_objBackLight status inactive {Supporing Device}"
        $itk_component(back_light) addInput \
        "$m_objInlineLightControl status inactive {Supporing Device}"
    
        grid $itk_component(not_available)

        pack $itk_component(lightFrame) -fill x

        eval itk_initialize $args
        $m_objDOStatus register $this contents handleStatusEvent
        $m_objInlineLightStatus register $this contents handleInlineStatusEvent
		#$m_mtZoomSwitch register $this scaledPosition handleZoomSwitchEvent
    }
    destructor {
        if {$m_switchWrap != ""} {
            $m_switchWrap unregister $this value handleSwitch
            set m_switchWrap ""
        }
		#$m_mtZoomSwitch unregister $this scaledPosition handleZoomSwitchEvent

        $m_objInlineLightStatus unregister $this contents \
        handleInlineStatusEvent

        $m_objDOStatus unregister $this contents handleStatusEvent
    }
}

body ComboLightControlWidget::handleStatusEvent { stringName_ targetReady_ alias_ contents_ - } {
    set m_ready 1
    set m_ready $targetReady_
    if {!$targetReady_} {
        set m_text "not ready"
    }

    set value [lindex $contents_ $BACK_LIGHT_CHANNEL_NO]
    if {$value == ""} {
        set m_ready 0
        set m_text "not ready"
    } elseif {$value} {
        set m_text "Turn On"
    } else {
        set m_text "Turn Off"
    }

    update_display
}
body ComboLightControlWidget::handleInlineStatusEvent { - targetReady_ alias_ contents_ - } {
    set m_inlineReady $targetReady_
    if {!$targetReady_} {
        update_display
        return
    }

    set idxInserted [lsearch -exact $contents_ INSERTED]
    set idxRemoved  [lsearch -exact $contents_ REMOVED]

    set m_inlineText "Remove"
    ###only allow insert if it is out
    if {$idxInserted >= 0 && $idxRemoved >= 0} {
        incr idxInserted
        incr idxRemoved
        set inserted [lindex $contents_ $idxInserted]
        set removed  [lindex $contents_ $idxRemoved]

        if {$inserted == "no" && $removed == "yes"} {
            set m_inlineText "Insert"
        }
    } else {
        puts "DEBUG: INSERTED or REMOVED field not found in inlineLightStatus: $contents_"
    }
    update_display
}
    
body ComboLightControlWidget::update_display { } {
    if {$m_displayingInlineLight} {
        set available $m_inlineReady
        set text $m_inlineText

        #set side_label_text "Light Intensity"
        #set side_device $m_objInlineLight
    } else {
        set available $m_ready
        set text $m_text

        #set side_label_text "Side Light Intensity"
        #set side_device $m_objSideLight
    }

    #$itk_component(side_label) configure -text $side_label_text
    #$itk_component(side_light) configure -device $side_device
    $itk_component(back_light) configure -text $text

    if {$available != $m_available} {
        set m_available $available

        #pack forget $itk_component(lightFrame)
        set all [grid slaves $m_lightSite]
        if {[llength $all] > 0} {
            eval grid forget $all
        }

        if {$m_available} {
            grid $itk_component(back_label) $itk_component(side_label) -sticky news
            grid $itk_component(back_light) $itk_component(side_light) -sticky news
            grid columnconfig $m_lightSite 1 -weight 10
        } else {
            grid $itk_component(not_available)
        }
        #pack $itk_component(lightFrame) -fill x
    }
}
