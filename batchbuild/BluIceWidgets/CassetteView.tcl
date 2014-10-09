package provide BLUICECassetteView 1.0
package require Iwidgets
package require DCSUtil
package require DCSSet
package require DCSComponent
package require DCSDeviceFactory

class BaseSampleHolderView {
    inherit ::itk::Widget 

    #### offset will be added to the port index for convenient
    itk_option define -offset offset Offset 0
    ### onClick will be called with port index and port name if defined
    itk_option define -onClick onClick OnClick ""
    ### onClickAll will be called with 1/0 start_index end_index
    itk_option define -onClickAll onClickAll OnClickAll ""
    ### onRightClick will be called with port index if defined
    itk_option define -onRightClick onRightClick OnRightClick ""
    ### onRightClickAll will be called with start_index and length if defined
    itk_option define -onRightClickAll onRightClickAll OnRightClickAll ""

    #### forProbe forMount forForce
    itk_option define -purpose purpose Purpose "forProbe"

    itk_option define -probeContents probeContents ProbeContents "" { updateProbeDisplay }

    itk_option define -statusContents statusContents StatusContents "" { updateStatusDisplay }
    itk_option define -forceContents forceContents ForceContents "" { updateForceDisplay }

    itk_option define -portNamePrefix portNamePrefix PortNamePrefix ""

    itk_option define -moveContents moveContents MoveContents "" { updateMoveDisplay }

    protected common RADIUS_HOLE 5.4

    public    common COLOR_SELECTED           #a0a0ff
    public    common COLOR_UNSELECTED         #404080

    #public    common COLOR_MOVE_ORIGIN        cyan
    public    common COLOR_MOVE_ORIGIN        black
    public    common COLOR_MOVE_DESTINATION   #00ff00
    public    common COLOR_MOVE_BOTH          #ff0000

    protected common COLOR_PORT_UNKNOWN       #ffffff
    protected common COLOR_NUM_UNKNOWN        #ffffff

    protected common COLOR_PORT_EMPTY         #000000
    protected common COLOR_NUM_EMPTY          #ffffff

    protected common COLOR_PORT_SAMPLE        #008000
    protected common COLOR_NUM_SAMPLE         #ffffff
    
    protected common COLOR_PORT_TROUBLE       #a01010
    protected common COLOR_NUM_TROUBLE        #ffffff

    protected common COLOR_PORT_MOUNTED       #c04080
    protected common COLOR_NUM_MOUNTED        #ffffff


    private common MIN_GRAYSCALE 40
    private common colorScale [expr (100.0 - $MIN_GRAYSCALE) / (0.899+0.999)]


    ##### need override #######
    protected variable m_canvas
    protected variable m_numPort                0
    protected variable m_radiusPort             0

    protected variable m_forceScaled            0

    ##### may be override #######
    protected method handlePurpose { } { }


    public method handleClick { index }
    public method handleAllClick { index start end }

    public method handleRightClick { index }
    public method handleAllRightClick { start length }

    public method displayMark { x y index }
    public method removeMark { }

    ###### need override #####
    protected method index2name { index } {
        
        return "$itk_option(-portNamePrefix)$index"
    }

    ####### may be overrided to make display changes
    public method onProbeUpdate { } { }
    public method onMoveUpdate { } { }

    protected method updateDisplay { }
    protected method updateStatusDisplay { }
    protected method updateProbeDisplay { }
    protected method updateForceDisplay { }
    protected method updateMoveDisplay { }


    ### help functions
    private method checkPortStatus { index }


    constructor { args  } {
        if {![::config get "robot.probeScaled" m_forceScaled]} {
            set m_forceScaled 0
        }

        eval itk_initialize $args
    }

    destructor {
    }
}
body BaseSampleHolderView::updateStatusDisplay { } {
    #### no need to update status if forForce
    if {$itk_option(-purpose) == "forForce"} return

    for {set i 0} {$i < $m_numPort} {incr i} {
        set status [lindex $itk_option(-statusContents) $i]

        switch -exact -- $status {
            m {
                set port_color  $COLOR_PORT_MOUNTED
                set num_color   $COLOR_NUM_MOUNTED
                set port_stipple ""
            }
            0 {
                set port_color  $COLOR_PORT_EMPTY
                set num_color   $COLOR_NUM_EMPTY
                set port_stipple ""
            }
            1 {
                set port_color  $COLOR_PORT_SAMPLE
                set num_color   $COLOR_NUM_SAMPLE
                set port_stipple ""
            }
            u {
                set port_color  $COLOR_PORT_UNKNOWN
                set num_color   $COLOR_NUM_UNKNOWN
                set port_stipple gray12
            }
            default {
                set port_color  $COLOR_PORT_TROUBLE
                set num_color   $COLOR_NUM_TROUBLE
                set port_stipple ""
                if {$itk_option(-purpose) != "forProbe"} {
                    set state disabled
                    ##### add binding for help messages
                }
            }
        }
        $m_canvas itemconfig port$i \
        -fill $port_color \
        -stipple $port_stipple

        if {$itk_option(-purpose) != "forProbe" && \
        $itk_option(-purpose) != "forMoveOrigin" && \
        $itk_option(-purpose) != "forMoveDestination"} {
            $m_canvas itemconfig port$i \
            -width 1 \
            -outline black
        }

        $m_canvas itemconfig num$i \
        -fill $num_color
    }
}
body BaseSampleHolderView::updateProbeDisplay { } {
    if {$itk_option(-purpose) != "forProbe"} return

    set outline_width [expr $m_radiusPort / 2.0]
    if {$outline_width < 2.0} {
        set outline_width 2.0
    }
    for {set i 0} {$i < $m_numPort} {incr i} {
        set selected [lindex $itk_option(-probeContents) $i]
        if {$selected == "1"} {
            $m_canvas itemconfig port$i \
            -width $outline_width \
            -outline $COLOR_SELECTED
        } else {
            $m_canvas itemconfig port$i \
            -width 1 \
            -outline black
        }
    }

    ### give sub class a chance to do something
    onProbeUpdate
}
body BaseSampleHolderView::updateForceDisplay { } {
    if {$itk_option(-purpose) != "forForce"} return

    for {set i 0 } {$i < $m_numPort} {incr i} {
        set value [lindex $itk_option(-forceContents) $i]

        if {[string is double -strict $value]} {
            set pattern ""
            set abs_value [expr abs($value)]

            if {$m_forceScaled} {
                if {$value >= 1.0} {
                    set port_color red
                    set text_color white
                } elseif {$value >= 0.9} {
                    set port_color yellow 
                    set text_color black
                } else {
                    #set gray_scale [expr int(($value + 1.0)*26.3) + 50 ]
                    set gray_scale [expr int(($value + 1.0)*$colorScale) + $MIN_GRAYSCALE ]
                    if {$gray_scale < 0} {
                        set gray_scale 0
                    }
                    if {$gray_scale > 100} {
                        set gray_scale 100
                    }
                    set port_color gray$gray_scale
                    if {$gray_scale >= 50} {
                        set text_color black
                    } else {
                        set text_color white
                    }
                    #puts "$value port_color: $port_color"
                }
            } else {
                if {$abs_value >= 9.0} {
                    set port_color red
                    set text_color white
                } elseif {$abs_value >= 8} {
                    set port_color yellow 
                    set text_color black
                } else {
                    set gray_scale [expr int($abs_value / 8.0 * 100.0)]
                    set port_color gray$gray_scale
                    #puts "old port_color: $port_color"
                    if {$gray_scale >= 50} {
                        set text_color black
                    } else {
                        set text_color white
                    }
                }
            }
        } elseif {$value == "EEEE"} {
            set pattern ""
            set port_color black
            set text_color white
            set value ""
        } else {
            set pattern gray12
            set port_color white
            set text_color white
        }

        $m_canvas itemconfig num$i -text $value -fill $text_color
        $m_canvas itemconfig port$i -fill $port_color -stipple $pattern

    }
}
body BaseSampleHolderView::updateMoveDisplay { } {
    if {$itk_option(-purpose) != "forMoveOrigin" && \
    $itk_option(-purpose) != "forMoveDestination"} {
        return
    }

    set outline_width [expr $m_radiusPort / 2.0]
    if {$outline_width < 2.0} {
        set outline_width 2.0
    }
    for {set i 0} {$i < $m_numPort} {incr i} {
        switch -exact -- [lindex $itk_option(-moveContents) $i] {
            1 {
                $m_canvas itemconfig port$i \
                -width $outline_width \
                -outline $COLOR_MOVE_ORIGIN
            }
            2 {
                $m_canvas itemconfig port$i \
                -width $outline_width \
                -outline $COLOR_MOVE_DESTINATION
            }
            3 {
                $m_canvas itemconfig port$i \
                -width $outline_width \
                -outline $COLOR_MOVE_BOTH
            }
            default {
                $m_canvas itemconfig port$i \
                -width 1 \
                -outline black
            }
        }
    }

    ### give sub class a chance to do something
    onMoveUpdate
}
body BaseSampleHolderView::updateDisplay { } {
    updateStatusDisplay
    updateProbeDisplay
    updateMoveDisplay
}
body BaseSampleHolderView::handleClick { index } {
    if {$itk_option(-purpose) == "forForce"} return

    if {![string is integer -strict $index] || $index < 0 || $index >= $m_numPort } {
        puts "bad index $index in handleClick for BaseSampleHolderView"
        return
    }

    set port_index [expr $index + $itk_option(-offset)]

    set cmd $itk_option(-onClick)
    if {$cmd != ""} {
        set port_name [index2name $index]
        lappend cmd $port_index $port_name
        eval $cmd
    }
}

body BaseSampleHolderView::handleRightClick { index } {
    if {$itk_option(-purpose) != "forProbe"} return

    if {![string is integer -strict $index] || $index < 0 || $index >= $m_numPort } {
        puts "bad index $index in handleRightClick for BaseSampleHolderView"
        return
    }

    set port_index [expr $index + $itk_option(-offset)]

    set cmd $itk_option(-onRightClick)
    if {$cmd != ""} {
        set current_status [lindex $itk_option(-statusContents) $index]
        switch -exact -- $current_status {
            j -
            b { set state u }
            default { set state b }
        }

        lappend cmd $port_index $state
        eval $cmd
    }
}

body BaseSampleHolderView::handleAllClick { index start end } {
    #### only used for probe ###
    if {$itk_option(-purpose) != "forProbe"} return
    if {$start >= $end} return

    set width [$m_canvas itemcget pall$index -width]

    if {$width > 1} {
        ########### change own display #################
        $m_canvas itemconfig pall$index -width 1 -outline $COLOR_UNSELECTED -fill $COLOR_UNSELECTED
        $m_canvas itemconfig lall$index -fill white

        set value_to_send 0

    } else {
        ########### change own display #################
        $m_canvas itemconfig pall$index -width 2 -outline $COLOR_SELECTED -fill $COLOR_SELECTED
        $m_canvas itemconfig lall$index -fill black

        set value_to_send 1
    }
    set cmd $itk_option(-onClickAll)
    if {$cmd != ""} {
        set start [expr $start + $itk_option(-offset)]
        set end [expr $end + $itk_option(-offset)]

        lappend cmd $value_to_send $start $end
        eval $cmd
    }
}

body BaseSampleHolderView::handleAllRightClick { start length } {
    #### only used for probe ###
    if {$itk_option(-purpose) != "forProbe"} return
    if {$start < 0 || $length <= 0} return

    set cmd $itk_option(-onRightClickAll)
    if {$cmd != ""} {
        set current_status [lindex $itk_option(-statusContents) $start]
        switch -exact -- $current_status {
            j -
            b { set state u }
            default { set state b }
        }

        set start [expr $start + $itk_option(-offset)]
        lappend cmd $start $length $state
        eval $cmd
    }
}

body BaseSampleHolderView::removeMark { } {
    $m_canvas delete mark
}

body BaseSampleHolderView::checkPortStatus { index } {
    set result ""
    ## if it is for move, check the move list first
    switch -exact -- $itk_option(-purpose) {
        forMoveOrigin -
        forMoveDestination {
            set moveStatus [lindex $itk_option(-moveContents) $index]
            switch -exact -- $moveStatus {
                1 -
                2 -
                3 {
                    return " already selected"
                }
            }
        }
    }

    ## now we check the port status
    set port_status [lindex $itk_option(-statusContents) $index]
    switch -exact -- $port_status {
        u {
            return ""
        }
        - {
            return " not exist"
        }
        j {
            return " jam"
        }
        m {
            return " mounted"
        }
        default {
            return " bad"
        }
        1 {
            if {$itk_option(-purpose) == "forMoveDestination"} {
                return " occupied"
            } else {
                return ""
            }
        }
        0 {
            switch -exact -- $itk_option(-purpose) {
                forMoveOrigin -
                forMount {
                    return " empty"
                }
                default {
                    return ""
                }
            }
        }
    }
    return ""
}

body BaseSampleHolderView::displayMark { x y index } {
    removeMark

    ### prepare new one
    set contents [$m_canvas itemcget num$index -text]
    if {$contents == ""} return

    set fore_color black
    set back_color white
    set warning_fore_color black
    set warning_back_color yellow

    set itIsNormal 0

    switch -exact -- $itk_option(-purpose) {
        forMoveOrigin -
        forMoveDestination -
        forMount {
            set contents "port: $itk_option(-portNamePrefix)$contents"
            set warningMsg [checkPortStatus $index]
            if {$warningMsg != ""} {
                append contents $warningMsg
                set fore_color $warning_fore_color
                set back_color $warning_back_color
            }
        }
        forProbe {
            set port_selected [lindex $itk_option(-probeContents) $index]
            if {$port_selected == "1"} {
                set contents "selected: $itk_option(-portNamePrefix)$contents"
            } else {
                set contents "port: $itk_option(-portNamePrefix)$contents"
            }
        }
        forForce {
            if {$m_forceScaled} {
                set contents "diff: $contents mm"
            } else {
                set contents "force: $contents"
            }
        }
    }


    set port_box [$m_canvas bbox port$index]
    foreach {x0 y0 x1 y1} $port_box break

    set width [$m_canvas cget -width]
    set height [$m_canvas cget -height]

    ######## we divide canvas into 6 areas ######
    #######    nw           n              ne
    #######    sw           s              se

    if {$y0 < [expr $height / 2.0]} {
        set text_y [expr $y1 + 4]
        set anchor1 n
    } else {
        set text_y [expr $y0 - 4]
        set anchor1 s
    }

    if {$x0 < [expr $width / 3.0]} {
        set text_x [expr $x0 + 4]
        set anchor2 w
    } elseif {$x0 < [expr $width * 0.666]} {
        set text_x [expr ($x0 + $x1) / 2.0]
        set anchor2 ""
    } else {
        set text_x [expr $x1 - 4]
        set anchor2 e
    }

    set text_id [$m_canvas create text $text_x $text_y \
    -tags mark \
    -fill $fore_color \
    -anchor $anchor1$anchor2 \
    -justify center \
    -text $contents]

    set coords [$m_canvas bbox $text_id]
    $m_canvas create rectangle $coords \
    -tags mark \
    -outline white \
    -fill $back_color

    $m_canvas raise $text_id
}

configbody BaseSampleHolderView::purpose {
    if {$itk_option(-purpose) == "forProbe"} {
        set state ""
    } else {
        set state hidden
    }
    $m_canvas itemconfig button_all \
    -state $state

        for {set i 0} {$i < $m_numPort} {incr i} {
            $m_canvas bind port$i <Enter> "$this displayMark %x %y $i"
            $m_canvas bind port$i <Leave> "$this removeMark"
            $m_canvas bind num$i <Enter> "$this displayMark %x %y $i"
            $m_canvas bind num$i <Leave> "$this removeMark"
        }

    handlePurpose

    updateDisplay
}

class PuckView {
    inherit BaseSampleHolderView 

    itk_option define -angleOffset angleOffset AngleOffset 90
    itk_option define -size size Size 1

    #### one letter name will be display at the center ####
    itk_option define -name name Name " " {
        $m_canvas itemconfig puck_name -text $itk_option(-name)
    }

    #############real size in mm
    private common RADIUS_1_5  12.12
    private common RADIUS_6_16 26.31
    private common RADIUS_PUCK 33.55
    private common PI

    public  common NUM_PORT    16

    private variable m_previous_size 1

    public method onProbeUpdate { }
    ############# colors ######
    protected common COLOR_PUCK               #404080

    protected method index2name { index } {
        return "$itk_option(-portNamePrefix)[expr $index + 1]"
    }

    private method rescale { }

    constructor { args  } {
        set m_numPort $NUM_PORT

        set PI [expr acos(-1)]

        itk_component add myCanvas {
            canvas $itk_interior.cc \
            -width  $m_previous_size \
            -height $m_previous_size
        } {
            keep -state
            rename -width -size size Size
            rename -height -size size Size
            keep -background
        }

        set m_canvas $itk_component(myCanvas)

        #### assume canvas size 1X1 and will be scaled later

        #puts "create puck circle"
        $itk_component(myCanvas) create oval \
        0 0 $m_previous_size $m_previous_size \
        -fill $COLOR_PUCK

        #puts "create name at center"
        set name_xy [expr $m_previous_size / 2.0]
        $itk_component(myCanvas) create text $name_xy $name_xy \
        -text " " \
        -fill white \
        -tags [list puck_name]

        #puts "prepare data for holes"
        set scale [expr $m_previous_size / 2.0 / $RADIUS_PUCK]
        set m_radiusPort [expr $RADIUS_HOLE * $scale]
        set radius_1_5  [expr $RADIUS_1_5  * $scale]
        set radius_6_16 [expr $RADIUS_6_16 * $scale]
        set offset [expr $PI / 2.0]

        #puts "create all button"
        set hole_size [expr $m_radiusPort * 2.0]
        $itk_component(myCanvas) create oval \
        0 0 $hole_size $hole_size \
        -fill $COLOR_SELECTED \
        -outline $COLOR_SELECTED \
        -width 2 \
        -tags [list pall button_all]

        $itk_component(myCanvas) create text $m_radiusPort $m_radiusPort \
        -text all \
        -fill black \
        -tags [list labels lall button_all]

        $itk_component(myCanvas) bind pall <Button-1> \
        "$this handleAllClick {} 0 $m_numPort"
        $itk_component(myCanvas) bind lall <Button-1> \
        "$this handleAllClick {} 0 $m_numPort"

        $itk_component(myCanvas) bind pall <Button-3> \
        "$this handleAllRightClick 0 $m_numPort"
        $itk_component(myCanvas) bind lall <Button-3> \
        "$this handleAllRightClick 0 $m_numPort"

        set puck_center_x [expr $m_previous_size / 2.0]
        set puck_center_y $puck_center_x

        #puts "holes 1-5"
        set delta [expr 2.0 * $PI / 5.0 ]
        for {set i 0} {$i < 5} {incr i} {
            set ll [expr $i + 1]

            set angle [expr $offset + $i * $delta]
            set hole_x [expr $puck_center_x + $radius_1_5 * cos($angle)]
            set hole_y [expr $puck_center_y - $radius_1_5 * sin($angle)]

            set x0 [expr $hole_x - $m_radiusPort]
            set y0 [expr $hole_y - $m_radiusPort]
            set x1 [expr $hole_x + $m_radiusPort]
            set y1 [expr $hole_y + $m_radiusPort]

            $itk_component(myCanvas) create oval $x0 $y0 $x1 $y1 \
            -fill $COLOR_PORT_UNKNOWN \
            -stipple gray12 \
            -tags [list ports port$i]

            $itk_component(myCanvas) create text $hole_x $hole_y \
            -text $ll \
            -fill $COLOR_NUM_UNKNOWN \
            -tags [list labels num$i]

            $itk_component(myCanvas) bind port$i <Button-1> "$this handleClick $i"
            $itk_component(myCanvas) bind num$i <Button-1> "$this handleClick $i"
            $itk_component(myCanvas) bind port$i <Button-3> "$this handleRightClick $i"
            $itk_component(myCanvas) bind num$i <Button-3> "$this handleRightClick $i"

        }
        #puts "holes 6-16"
        set delta [expr 2.0 * $PI / 11.0 ]
        for {set i 0} {$i < 11} {incr i} {
            set ll [expr $i + 6]
            set index [expr $i + 5]

            set angle [expr $offset + $i * $delta]
            set hole_x [expr $puck_center_x + $radius_6_16 * cos($angle)]
            set hole_y [expr $puck_center_y - $radius_6_16 * sin($angle)]

            set x0 [expr $hole_x - $m_radiusPort]
            set y0 [expr $hole_y - $m_radiusPort]
            set x1 [expr $hole_x + $m_radiusPort]
            set y1 [expr $hole_y + $m_radiusPort]

            $itk_component(myCanvas) create oval $x0 $y0 $x1 $y1 \
            -fill $COLOR_PORT_UNKNOWN \
            -stipple gray12 \
            -tags [list ports port$index]
            
            $itk_component(myCanvas) create text $hole_x $hole_y \
            -text $ll \
            -fill $COLOR_NUM_UNKNOWN \
            -tags [list labels num$index]
            $itk_component(myCanvas) bind port$index <Button-1> "$this handleClick $index"
            $itk_component(myCanvas) bind num$index <Button-1> "$this handleClick $index"
            $itk_component(myCanvas) bind port$index <Button-3> "$this handleRightClick $index"
            $itk_component(myCanvas) bind num$index <Button-3> "$this handleRightClick $index"
        }

        pack $itk_component(myCanvas) -expand 1 -fill both -padx 0 -pady 0

        eval itk_initialize $args
    }

    destructor {
    }
}
body PuckView::onProbeUpdate { } {
    set all_on 1
    foreach port_on $itk_option(-probeContents) {
        if {$port_on != "1"} {
            set all_on 0
            break
        }
    }
    if {$all_on} {
        $m_canvas itemconfig pall -width 2 -outline $COLOR_SELECTED -fill $COLOR_SELECTED
        $m_canvas itemconfig lall -fill black
    } else {
        $m_canvas itemconfig pall -width 1 -outline $COLOR_UNSELECTED -fill $COLOR_UNSELECTED
        $m_canvas itemconfig lall -fill white
    }
}
body PuckView::rescale { } {
    if {![string is double -strict $itk_option(-size)]} {
        return
    }
    set scaleXY [expr double($itk_option(-size)) / $m_previous_size]

    #puts "scale: $scaleXY"
    set m_radiusPort [expr $RADIUS_HOLE * $itk_option(-size) / $RADIUS_PUCK / 2.0]

    if {$itk_option(-purpose) == "forForce"} {
        set font_size [expr int($m_radiusPort * 0.7)]
    } else {
        set font_size [expr int($m_radiusPort)]
    }
    set name_font_size [expr int(2 * $m_radiusPort)]

    $itk_component(myCanvas) scale all 0.0 0.0 $scaleXY $scaleXY
    $itk_component(myCanvas) itemconfig labels \
    -font "-family courier -size $font_size"
    $itk_component(myCanvas) itemconfig puck_name \
    -font "-family times -size $name_font_size"
    #puts "rescale done"

    set m_previous_size $itk_option(-size)

    updateDisplay
}

configbody PuckView::size {
    #puts "new size: $itk_option(-size)"
    rescale
}
class MARCSCView {
    inherit BaseSampleHolderView 

    itk_option define -angleOffset angleOffset AngleOffset 0
    itk_option define -size size Size 1

    #############real size in mm
    private common RADIUS_ROW  50.0
    private common RADIUS_OUT  57.0
    private common RADIUS_IN   43.0
    private common PI

    public  common NUM_PORT    19

    private variable m_previous_size 1

    ############# colors ######
    protected common COLOR_CSC              #404080

    protected method index2name { index } {
        return "$itk_option(-portNamePrefix)[expr $index + 1]"
    }

    private method rescale { }

    constructor { args  } {
        set m_numPort $NUM_PORT

        set PI [expr acos(-1)]

        itk_component add myCanvas {
            canvas $itk_interior.cc \
            -width  $m_previous_size \
            -height $m_previous_size
        } {
            keep -state
            rename -width -size size Size
            rename -height -size size Size
            keep -background
        }

        set m_canvas $itk_component(myCanvas)

        #### assume canvas size 1X1 and will be scaled later
        set scale [expr $m_previous_size / 2.0 / $RADIUS_OUT]
        set radius_in   [expr $RADIUS_IN  * $scale]
        set row_center_x [expr $m_previous_size / 2.0]
        set row_center_y $row_center_x
        set m_radiusPort [expr $RADIUS_HOLE * $scale]
        set radius_row  [expr $RADIUS_ROW  * $scale]
        set offset [expr $PI / 2.0]

        set x0 [expr $row_center_x - $radius_in]
        set y0 [expr $row_center_y - $radius_in]
        set x1 [expr $row_center_x + $radius_in]
        set y1 [expr $row_center_y + $radius_in]

        #puts "create csc circle"
        $itk_component(myCanvas) create oval \
        0 0 $m_previous_size $m_previous_size \
        -fill $COLOR_CSC

        $itk_component(myCanvas) create oval \
        $x0 $y0 $x1 $y1 \
        -fill $itk_option(-background)

        set x0 [expr $row_center_x - $m_radiusPort]
        set y0 0
        set x1 [expr $row_center_x + $m_radiusPort]
        set y1 $row_center_y

        $itk_component(myCanvas) create rectangle \
        $x0 $y0 $x1 $y1 \
        -fill $itk_option(-background) \
        -outline $itk_option(-background) \


        #puts "create name at center"
        set name_xy [expr $m_previous_size / 2.0]
        $itk_component(myCanvas) create text $name_xy $name_xy \
        -text "CSC" \
        -fill black

        #puts "create all button"
        set hole_size [expr $m_radiusPort * 2.0]
        $itk_component(myCanvas) create oval \
        0 0 $hole_size $hole_size \
        -fill $COLOR_SELECTED \
        -outline $COLOR_SELECTED \
        -width 2 \
        -tags [list pall button_all]

        $itk_component(myCanvas) create text $m_radiusPort $m_radiusPort \
        -text all \
        -fill black \
        -tags [list labels lall button_all]

        $itk_component(myCanvas) bind pall <Button-1> \
        "$this handleAllClick {} 0 $m_numPort"
        $itk_component(myCanvas) bind lall <Button-1> \
        "$this handleAllClick {} 0 $m_numPort"

        $itk_component(myCanvas) bind pall <Button-3> \
        "$this handleAllRightClick 0 $m_numPort"
        $itk_component(myCanvas) bind lall <Button-3> \
        "$this handleAllRightClick 0 $m_numPort"

        #puts "holes 1-5"
        set delta [expr 2.0 * $PI / ($NUM_PORT + 1) ]
        for {set i 0} {$i < $m_numPort} {incr i} {
            set ll [expr $i + 1]

            set angle [expr $offset + $ll * $delta]
            set hole_x [expr $row_center_x + $radius_row * cos($angle)]
            set hole_y [expr $row_center_y - $radius_row * sin($angle)]

            set x0 [expr $hole_x - $m_radiusPort]
            set y0 [expr $hole_y - $m_radiusPort]
            set x1 [expr $hole_x + $m_radiusPort]
            set y1 [expr $hole_y + $m_radiusPort]

            $itk_component(myCanvas) create oval $x0 $y0 $x1 $y1 \
            -fill $COLOR_PORT_UNKNOWN \
            -stipple gray12 \
            -tags [list ports port$i]

            $itk_component(myCanvas) create text $hole_x $hole_y \
            -text $ll \
            -fill $COLOR_NUM_UNKNOWN \
            -tags [list labels num$i]

            $itk_component(myCanvas) bind port$i <Button-1> "$this handleClick $i"
            $itk_component(myCanvas) bind num$i <Button-1> "$this handleClick $i"
            $itk_component(myCanvas) bind port$i <Button-3> "$this handleRightClick $i"
            $itk_component(myCanvas) bind num$i <Button-3> "$this handleRightClick $i"

        }
        pack $itk_component(myCanvas) -expand 1 -fill both -padx 0 -pady 0

        eval itk_initialize $args
    }

    destructor {
    }
}
body MARCSCView::rescale { } {
    if {![string is double -strict $itk_option(-size)]} {
        return
    }
    set scaleXY [expr double($itk_option(-size)) / $m_previous_size]

    #puts "scale: $scaleXY"
    set m_radiusPort [expr $RADIUS_HOLE * $itk_option(-size) / $RADIUS_OUT / 2.0]

    if {$itk_option(-purpose) == "forForce"} {
        set font_size [expr int($m_radiusPort * 0.7)]
    } else {
        set font_size [expr int($m_radiusPort)]
    }
    set name_font_size [expr int(2 * $m_radiusPort)]

    $itk_component(myCanvas) scale all 0.0 0.0 $scaleXY $scaleXY
    $itk_component(myCanvas) itemconfig labels \
    -font "-family courier -size $font_size"
    $itk_component(myCanvas) itemconfig puck_name \
    -font "-family times -size $name_font_size"
    #puts "rescale done"

    set m_previous_size $itk_option(-size)

    updateDisplay
}

configbody MARCSCView::size {
    #puts "new size: $itk_option(-size)"
    rescale
}
class CylinderView {
    inherit BaseSampleHolderView 

    ##### 12 column 11 row
    private common RATIO_PROBE     0.916666666
    ##### 12 column 10 row
    private common RATIO_MOUNT     0.833333333

    private variable m_ratio       $RATIO_PROBE

    itk_option define -size size Size 1.0 { rescale }

    itk_option define -calibrationCassette calibrationCassette CalibrationCassette 0

    #############real size in mm
    ###### 32 X 2 X PI
    #private variable REAL_SIZE 201.06
    private common REAL_SIZE 160.0
    #### ratio is 11/12 as height/width

    private variable m_previous_size 1.0
    private common m_columnNames [list A B C D E F G H I J K L]

    ############# colors ######
    protected common COLOR_CASSETTE               #404080

    public common NUM_PORT             96

    private variable m_previous_purpose "forProbe"

    public method getRatio { } { return $m_ratio }

    private method rescale { }

    protected method index2name { index } {
        set columnIndex [expr $index / 8]
        set rowIndex [expr $index % 8]

        set column [lindex $m_columnNames $columnIndex]
        set row [expr $rowIndex + 1]

        return "$itk_option(-portNamePrefix)$column$row"
    }

    protected method handlePurpose { }

    public method onProbeUpdate { }

    constructor { args  } {
        set m_numPort $NUM_PORT

        itk_component add myCanvas {
            canvas $itk_interior.cc
        } {
            keep -state
            keep -background
        }
        set m_canvas $itk_component(myCanvas)

        #### assume canvas size 1X1 and will be scaled later
        #puts "prepare data for holes"
        set scale [expr $m_previous_size / $REAL_SIZE]
        set m_radiusPort [expr $RADIUS_HOLE * $scale]
        set dx [expr $m_previous_size / 12.0]
        set dy $dx

        set y0 [expr 1.3 * $dy]
        set y1 [expr 10.7 * $dy]

        $itk_component(myCanvas) create rectangle \
        0.0 $y0 $m_previous_size $y1 \
        -fill $COLOR_CASSETTE \
        -outline black
        #-outline $COLOR_CASSETTE


        ##### center white line ####
        set y0 [expr 6.0 * $dx]
        $itk_component(myCanvas) create line 0.0 $y0 $m_previous_size $y0 \
        -fill white
        
        #puts "create all buttons and top bottom labels"
        set hole_size [expr $m_radiusPort * 2.0]
        set hole_y [expr $dy * 0.8]
        set label1_y [expr 1.7 * $dy]
        set label8_y [expr 10.3 * $dy]
        for {set i 0 } {$i < 12} {incr i} {
            set hole_x [expr $dx * (0.5 + $i)]
            set x0 [expr $hole_x - $m_radiusPort]
            set y0 [expr $hole_y - $m_radiusPort]
            set x1 [expr $hole_x + $m_radiusPort]
            set y1 [expr $hole_y + $m_radiusPort]

            set name [lindex $m_columnNames $i]

            set tagName pall$name

            $itk_component(myCanvas) create oval $x0 $y0 $x1 $y1 \
            -fill $COLOR_SELECTED \
            -outline $COLOR_SELECTED \
            -width 2 \
            -tags [list $tagName button_all]

            set labelTagName lall$name

            $itk_component(myCanvas) create text $hole_x $hole_y \
            -text $name \
            -fill black \
            -tags [list labels $labelTagName button_all]

            set start [expr 8 * $i]
            set end [expr $start + 8]

            $itk_component(myCanvas) bind  $tagName <Button-1> \
            "$this handleAllClick $name $start $end"
            $itk_component(myCanvas) bind $labelTagName <Button-1> \
            "$this handleAllClick $name $start $end"

            $itk_component(myCanvas) bind  $tagName <Button-3> \
            "$this handleAllRightClick $start 8"
            $itk_component(myCanvas) bind $labelTagName <Button-3> \
            "$this handleAllRightClick $start 8"

            ######### top and bottom labels
            for {set row 0} {$row < 2} {incr row} {
                switch $row {
                    0 {
                        set contents ${name}1
                        set label_y $label1_y
                    }
                    1 {
                        set contents ${name}8
                        set label_y $label8_y
                    }

                }
                $itk_component(myCanvas) create text $hole_x $label_y \
                -text $contents \
                -fill white \
                -tags [list labels]
            }
        }


        #puts "create all ports"
        ############# real ports ############
        for {set i 0} {$i < 12} {incr i} {
            set hole_x [expr $dx * (0.5 + $i)]
            set column_name [lindex $m_columnNames $i]
            for {set j 0} {$j < 8} {incr j} {
                set hole_y [expr $dy * (2.5 + $j)]

                set x0 [expr $hole_x - $m_radiusPort]
                set y0 [expr $hole_y - $m_radiusPort]
                set x1 [expr $hole_x + $m_radiusPort]
                set y1 [expr $hole_y + $m_radiusPort]

                set row_name [expr $j + 1]
                set ll [expr $i * 8 + $j]

                $itk_component(myCanvas) create oval $x0 $y0 $x1 $y1 \
                -fill $COLOR_PORT_UNKNOWN \
                -stipple gray12 \
                -tags [list ports port$ll]

                $itk_component(myCanvas) create text $hole_x $hole_y \
                -text $column_name$row_name \
                -fill $COLOR_NUM_UNKNOWN \
                -tags [list small_labels num$ll] \
                -state hidden

                $itk_component(myCanvas) bind port$ll <Button-1> "$this handleClick $ll"
                $itk_component(myCanvas) bind num$ll <Button-1> "$this handleClick $ll"
                $itk_component(myCanvas) bind port$ll <Button-3> "$this handleRightClick $ll"
                $itk_component(myCanvas) bind num$ll <Button-3> "$this handleRightClick $ll"
            }
        }

        pack $itk_component(myCanvas) -expand 1 -fill both -padx 0 -pady 0

        eval itk_initialize $args
    }

    destructor {
    }
}
body CylinderView::onProbeUpdate { } {
    set all_on [list 1 1 1 1 1 1 1 1 1 1 1 1]

    set p_i 0
    foreach port_on $itk_option(-probeContents) {
        if {!$port_on == "1"} {
            set col_index [expr int($p_i / 8)]
            set all_on [lreplace $all_on $col_index $col_index 0]
        }
    
        incr p_i
    }

    for {set i 0} {$i < 12} {incr i} {
        set index [lindex $m_columnNames $i]
        
        if {![lindex $all_on $i]} {
            $m_canvas itemconfig pall$index -width 1 -outline $COLOR_UNSELECTED -fill $COLOR_UNSELECTED
            $m_canvas itemconfig lall$index -fill white
        } else {
            $m_canvas itemconfig pall$index -width 2 -outline $COLOR_SELECTED -fill $COLOR_SELECTED
            $m_canvas itemconfig lall$index -fill black
        }
    }
}
body CylinderView::handlePurpose { } {
    if {$itk_option(-purpose) == $m_previous_purpose} return

    set width [$m_canvas cget -width]

    #puts "handle purpose $itk_option(-purpose) for $this"
    #puts "width $width"

    switch -exact -- $itk_option(-purpose) {
        forProbe {
            if {$m_previous_purpose != "forForce"} {
                set dy [expr $width / 12.0]
            } else {
                set dy 0
            }
            set m_ratio $RATIO_PROBE
            $m_canvas itemconfig small_labels -state hidden
        }
        forForce {
            if {$m_previous_purpose != "forProbe"} {
                set dy [expr $width / 12.0]
            } else {
                set dy 0
            }
            set m_ratio $RATIO_PROBE
            $m_canvas itemconfig small_labels -state ""
        }
        forMoveOrigin -
        forMoveDestination -
        forMount {
            set dy [expr $width / -12.0]
            set m_ratio $RATIO_MOUNT
            $m_canvas itemconfig small_labels -state hidden
        }
        default {
            return
        }
    }
    #puts "dy: $dy"
    $m_canvas move all 0 $dy

    rescale
    set m_previous_purpose $itk_option(-purpose)
}
body CylinderView::rescale { } {
    if {![string is double -strict $itk_option(-size)]} {
        return
    }

    $m_canvas config \
    -width $itk_option(-size) \
    -height [expr $m_ratio * $itk_option(-size)]

    set scaleXY [expr double($itk_option(-size)) / $m_previous_size]

    #puts "scale: $scaleXY"
    set m_radiusPort [expr $RADIUS_HOLE * $scaleXY * $m_previous_size / $REAL_SIZE]
    set font_size [expr int($m_radiusPort * 1.5)]
    #puts "font size: $font_size"
    set small_font_size [expr int($m_radiusPort * 0.7)]

    $itk_component(myCanvas) scale all 0.0 0.0 $scaleXY $scaleXY
    $itk_component(myCanvas) itemconfig labels \
    -font "-family courier -size $font_size"

    $itk_component(myCanvas) itemconfig small_labels \
    -font "-family courier -size $small_font_size"
    set m_previous_size $itk_option(-size)

    updateDisplay
}

configbody CylinderView::calibrationCassette {
    #puts "option calibrationCassette $itk_option(-calibrationCassette)"
    if {$itk_option(-calibrationCassette)} {
        set port_state hidden
        set num_state hidden
        #puts "calibration cassette, hide some rows"
    } else {
        set port_state ""
        if {$itk_option(-purpose) == "forForce"} {
            set num_state ""
        } else {
            set num_state hidden
        }
    }

    for {set i 0} {$i < 12} {incr i} {
        for {set j 1} {$j < 7} {incr j} {
            set ll [expr $i * 8 + $j]
            $m_canvas itemconfig port$ll \
            -state $port_state
            $m_canvas itemconfig num$ll \
            -state $num_state
        }
    }
}
class ITKCassetteView {
    inherit ::itk::Widget 

    itk_option define -mdiHelper mdiHelper MdiHelper ""

    itk_option define -type type Type 1 { repack }
    itk_option define -status status Status u
    itk_option define -offset offset Offset 0

    itk_option define -purpose purpose Purpose forProbe

    itk_option define -probeContents probeContents ProbeContents "" { updateProbeDisplay }

    itk_option define -statusContents statusContents StatusContents "" { updateStatusDisplay }
    itk_option define -forceContents forceContents ForcedContents "" { updateForceDisplay }
    itk_option define -cylinderMoveContents cylinderMoveContents MoveContents "" { updateCylinderMoveDisplay }
    itk_option define -puckMoveContents puckMoveContents MoveContents "" { updatePuckMoveDisplay }

    itk_option define -owner owner Owner ""
    itk_option define -onReset onReset OnReset ""
    itk_option define -onRestore onRestore OnRestore ""

    itk_option define -onScanId onScanId OnScanId ""

    itk_option define -scanIdReference scanIdReference ScanIdReference "" {
        $itk_component(scanId) configure \
        -reference $itk_option(-scanIdReference)
    }

    public method hideScanId { } {
        set m_hideScanId 1
        pack forget $itk_component(scanId)
    }

    public method handleClickAll { }
    public method handleRightClickAll { }

    public method handleResize { win_id width height }

    public method handleOpenOwner { } {
        if {[catch {
            if {$itk_option(-mdiHelper) != ""} {
                $itk_option(-mdiHelper) openToolChest barcode_view
            }
        } errMsg]} {
            log_error $errMsg
        }
    }
    public method handleReset { } {
        set cmd $itk_option(-onReset)
        if {$cmd != ""} {
            eval $cmd
        }
    }

    public method handleRestore { } {
        set cmd $itk_option(-onRestore)
        if {$cmd != ""} {
            eval $cmd
        }
    }

    public method handleScanId { } {
        set cmd $itk_option(-onScanId)
        if {$cmd != ""} {
            eval $cmd
        }
    }

    protected method repack { }
    protected method updateDisplay { }
    protected method updateStatusDisplay { }
    protected method updateProbeDisplay { }
    protected method updateForceDisplay { }
    protected method updateCylinderMoveDisplay { }
    protected method updatePuckMoveDisplay { }

    private method createForceDisplay { } {
        if {$m_forceDisplayCreated} return

        set puckForceSite $itk_component(puck_force_frame)
        set cylinderForceSite $itk_component(cylinder_force_frame)

        #puts "create force display for $this"

        itk_component add cylinder_force {
            #CylinderView $cylinderForceSite.#auto -purpose forForce
            CylinderView $cylinderForceSite.cyl -purpose forForce
        } {
            keep -background
        }
        grid $itk_component(cylinder_force)

        itk_component add puckA_force {
            #PuckView $puckForceSite.#auto -name A -purpose forForce
            PuckView $puckForceSite.puckA -name A -purpose forForce
        } {
            keep -background
        }
        itk_component add puckB_force {
            #PuckView $puckForceSite.#auto -name B -purpose forForce
            PuckView $puckForceSite.puckB -name B -purpose forForce
        } {
            keep -background
        }
        itk_component add puckC_force {
            #PuckView $puckForceSite.#auto -name C -purpose forForce
            PuckView $puckForceSite.puckC -name C -purpose forForce
        } {
            keep -background
        }
        itk_component add puckD_force {
            #PuckView $puckForceSite.#auto -name D -purpose forForce
            PuckView $puckForceSite.puckD -name D -purpose forForce
        } {
            keep -background
        }
        grid $itk_component(puckA_force) $itk_component(puckC_force)
        grid $itk_component(puckB_force) $itk_component(puckD_force)

        set m_forceDisplayCreated 1
    }
    private method removeForceDisplay { } {
        if {!$m_forceDisplayCreated} return
        #puts "remove force display for $this"
        itk_component delete cylinder_force
        itk_component delete puckA_force
        itk_component delete puckB_force
        itk_component delete puckC_force
        itk_component delete puckD_force
        set m_forceDisplayCreated 0
    }

    protected variable m_normalBackground   #008000
    protected variable m_unknownBackground  gray
    protected variable m_troubleBackground  #ffff00
    protected variable m_origBackground     gray 

    protected variable m_parent_width 0
    protected variable m_parent_height 0
    protected variable m_parent_id 0

    protected variable m_previous_purpose forProbe
    protected variable m_forceDisplayCreated 0

    protected variable m_cassetteName u

    private variable m_hideScanId 0

    constructor { args } {
        set ring $itk_interior

        ######### 2 sites, upper and lower
        itk_component add upper {
            frame $ring.upper
        } {
            keep -background
        }
        set m_origBackground [$itk_component(upper) cget -background]
        itk_component add big_lower {
            frame $ring.big_lower \
            -borderwidth 0
        } {
            keep -background
        }
        itk_component add lower {
            frame $itk_component(big_lower).lower \
            -borderwidth 0
        } {
            keep -background
        }
        itk_component add lower_force {
            frame $itk_component(big_lower).lower_force \
            -borderwidth 0
        } {
            keep -background
        }
        itk_component add puck_frame {
            #frame $itk_component(lower).puck -borderwidth 5 -relief sunken
            frame $itk_component(lower).puck -borderwidth 0
        } {
            keep -background
        }
        itk_component add cylinder_frame {
            frame $itk_component(lower).cylinder -borderwidth 0
        } {
            keep -background
        }
        itk_component add csc_frame {
            frame $itk_component(lower).csc -borderwidth 0
        } {
            keep -background
        }
        itk_component add puck_force_frame {
            #frame $itk_component(lower_force).puck -borderwidth 5 -relief sunken
            frame $itk_component(lower_force).puck -borderwidth 0
        } {
            keep -background
        }
        itk_component add cylinder_force_frame {
            #frame $itk_component(lower_force).cylinder -borderwidth 5 -relief raised
            frame $itk_component(lower_force).cylinder -borderwidth 0
        } {
            keep -background
        }
        set upperSite $itk_component(upper)
        set puckSite $itk_component(puck_frame)
        set cylinderSite $itk_component(cylinder_frame)
        set cscSite $itk_component(csc_frame)

        ##### upper site is for "all" button and cassette status menu
        itk_component add all {
            button $upperSite.all \
            -background $BaseSampleHolderView::COLOR_SELECTED \
            -disabledforeground black \
            -relief sunken \
            -text all \
            -command "$this handleClickAll"
        } {
            keep -state
        }
        bind $itk_component(all) <Button-3> "$this handleRightClickAll"

        itk_component add slabel {
            label $upperSite.slabel \
            -text "Status: "
        } {
            keep -background
        }
        itk_component add sbutton {
            menubutton $upperSite.sbutton \
            -text "unknown" \
            -menu $upperSite.sbutton.menu \
            -anchor w \
            -relief raised\
            -width 15 \
            -disabledforeground black
        } {
            keep -font
        }
        set m_unknownBackground [$itk_component(sbutton) cget -background]

        itk_component add smenu {
            menu $upperSite.sbutton.menu \
            -tearoff 0
        } { 
            keep -background -foreground -font
            rename -disabledforeground -foreground foreground Foreground
        }
        $itk_component(smenu) add command \
        -label "normal cassette" \
        -command "$this config -type 1"

        $itk_component(smenu) add command \
        -label "calibration cassette" \
        -command "$this config -type 2"

        $itk_component(smenu) add command \
        -label "puck adaptor" \
        -command "$this config -type 3"

        #$itk_component(smenu) add command \
        #-label "MAR sample changer" \
        #-command "$this config -type 4"

        itk_component add owner_label {
            label $upperSite.olabel \
            -text "Owner: "
        } {
            keep -background
        }
        itk_component add owner_contents {
            button $upperSite.owner \
            -text "" \
            -background red \
            -command "$this handleOpenOwner"
        } {
        }

        itk_component add reset {
            DCS::Button $upperSite.reset \
            -text "reset cassette status to unknown" \
            -command "$this handleReset"
        } {
        }

        itk_component add restore {
            DCS::Button $upperSite.restore \
            -background yellow \
            -text "restore" \
            -command "$this handleRestore"
        } {
        }

        itk_component add scanId {
            DCS::Checkbutton $upperSite.scanId \
            -shadowReference 1 \
            -text "Scan Barcode ID" \
            -selectcolor blue \
            -command "$this handleScanId"
        } {
            keep -state
        }

        pack $itk_component(all) -side left      -pady 0
        pack $itk_component(slabel) -side left   -pady 0
        pack $itk_component(sbutton) -side left  -pady 0
        pack $itk_component(owner_label) -side left
        pack $itk_component(owner_contents) -side left
        pack $itk_component(scanId) -side left
        pack $itk_component(reset) -side right
        pack $itk_component(restore) -side right

        ########## lower site is for the graphic port display
        itk_component add cylinder {
            CylinderView $cylinderSite.cyl
        } {
            keep -background
            keep -state
            keep -onClick -onClickAll
            keep -onRightClick -onRightClickAll
            keep -purpose
        }
        grid $itk_component(cylinder)

        itk_component add puckA {
            PuckView $puckSite.puckA -name A
        } {
            keep -background
            keep -state
            keep -onClick -onClickAll
            keep -onRightClick -onRightClickAll
            keep -purpose
        }
        itk_component add puckB {
            PuckView $puckSite.puckB -name B
        } {
            keep -background
            keep -state
            keep -onClick -onClickAll
            keep -onRightClick -onRightClickAll
            keep -purpose
        }
        itk_component add puckC {
            PuckView $puckSite.puckC -name C
        } {
            keep -background
            keep -state
            keep -onClick -onClickAll
            keep -onRightClick -onRightClickAll
            keep -purpose
        }
        itk_component add puckD {
            PuckView $puckSite.puckD -name D
        } {
            keep -background
            keep -state
            keep -onClick -onClickAll
            keep -onRightClick -onRightClickAll
            keep -purpose
        }
        grid $itk_component(puckA) $itk_component(puckC)
        grid $itk_component(puckB) $itk_component(puckD)

        itk_component add csc {
            MARCSCView $cscSite.changer
        } {
            keep -background
            keep -state
            keep -onClick -onClickAll
            keep -onRightClick -onRightClickAll
            keep -purpose
        }
        grid $itk_component(csc)

        createForceDisplay

        pack $itk_component(upper) -expand 1 -fill x -pady 0
        pack $itk_component(big_lower) -expand 1 -fill both -padx 0 -pady 0

        pack $itk_component(lower) -expand 1 -fill both -padx 0 -pady 0 -side left
        pack $itk_component(lower_force) -expand 1 -fill both -padx 0 -pady 0 -side left

        pack $itk_interior -expand 1 -fill both -padx 0 -pady 0

        eval itk_initialize $args

        #### hook resize ###
        set m_parent_id $itk_component(big_lower)
        bind $m_parent_id <Configure> "$this handleResize %W %w %h"
    }
}
configbody ITKCassetteView::purpose {
    if {$itk_option(-purpose) != $m_previous_purpose} {
        set m_previous_purpose $itk_option(-purpose)
        if {$itk_option(-purpose) == "forProbe"} {
            createForceDisplay
        } else {
            removeForceDisplay
        }
        #set purpose $itk_option(-purpose)
        #$itk_component(cylinder) config -purpose $purpose
        #$itk_component(puckA) config -purpose $purpose
        #$itk_component(puckB) config -purpose $purpose
        #$itk_component(puckC) config -purpose $purpose
        #$itk_component(puckD) config -purpose $purpose
        #puts "purpose changed to $purpose"

        pack forget $itk_component(all)
        pack forget $itk_component(slabel)
        pack forget $itk_component(sbutton)
        pack forget $itk_component(owner_label)
        pack forget $itk_component(owner_contents)
        pack forget $itk_component(scanId)
        pack forget $itk_component(lower) $itk_component(lower_force)
        pack forget $itk_component(reset)
        pack forget $itk_component(restore)
        if {$itk_option(-purpose) == "forProbe"} {
            pack $itk_component(all) -side left
            pack $itk_component(slabel) -side left
            pack $itk_component(sbutton) -side left
            pack $itk_component(owner_label) -side left
            pack $itk_component(owner_contents) -side left
            if {!$m_hideScanId} {
                pack $itk_component(scanId) -side left
            }
            pack $itk_component(reset) -side right
            pack $itk_component(restore) -side right

            #puts "pack lower force frame"
            pack $itk_component(lower) $itk_component(lower_force) -expand 1 -fill both -padx 0 -pady 0 -side left
        } else {
            pack $itk_component(slabel) -side left
            pack $itk_component(sbutton) -side left
            pack $itk_component(lower) -expand 1 -fill both -padx 0 -pady 0 -side left
        }

        updateDisplay
    }
}
configbody ITKCassetteView::status {
    set bg $m_origBackground
    set help_message "status is not unknown"

    switch -exact -- $itk_option(-status) {
        u {
            $itk_component(sbutton) config \
            -background $m_unknownBackground \
            -state normal \
            -relief raised \
            -text "unknown"

            if {$itk_option(-type) == "0"} {
                config -type 1
            }

            set help_message ""
        }
        0 {
            $itk_component(sbutton) config \
            -background $m_normalBackground \
            -state disabled \
            -relief flat \
            -text "no cassette"

            config -type $itk_option(-status)
        }
        1 {
            $itk_component(sbutton) config \
            -background $m_normalBackground \
            -state disabled \
            -relief flat \
            -text "normal cassette"

            config -type $itk_option(-status)
        }
        2 {
            $itk_component(sbutton) config \
            -background $m_normalBackground \
            -state disabled \
            -relief flat \
            -text "calib. cassette"

            config -type $itk_option(-status)
        }
        3 {
            $itk_component(sbutton) config \
            -background $m_normalBackground \
            -state disabled \
            -relief flat \
            -text "puck adaptor"

            config -type $itk_option(-status)
        }
        4 {
            $itk_component(sbutton) config \
            -background $m_normalBackground \
            -state disabled \
            -relief flat \
            -text "MAR sample changer"

            config -type $itk_option(-status)
        }
        - {
            $itk_component(sbutton) config \
            -background $m_troubleBackground \
            -state normal \
            -relief raised \
            -text "not_exist"

            set bg red
        }
        default {
            $itk_component(sbutton) config \
            -background $m_troubleBackground \
            -state normal \
            -relief raised \
            -text "trouble"

            set bg red
        }
    }
    config -background $bg
	DynamicHelp::register $itk_component(sbutton) balloon $help_message
}
configbody ITKCassetteView::owner {
    set newOwner $itk_option(-owner)

    if {$newOwner == ""} {
        $itk_component(owner_contents) configure \
        -text none \
        -background $m_normalBackground
    } else {
        if {[llength $newOwner] > 1} {
            set newOwner [lindex $newOwner 0]...
        }
        $itk_component(owner_contents) configure \
        -text $newOwner \
        -background red
    }
}
configbody ITKCassetteView::offset {
    switch -exact -- $itk_option(-offset) {
        0 {
            set m_cassetteName l
        }
        97 {
            set m_cassetteName m
        }
        194 {
            set m_cassetteName r
        }
        default {
            set m_cassetteName u
        }   
    }

    set offsetCylinder [expr $itk_option(-offset) + 1]
    set offsetPuckA $offsetCylinder
    set offsetPuckB [expr $offsetPuckA + $PuckView::NUM_PORT]
    set offsetPuckC [expr $offsetPuckB + $PuckView::NUM_PORT]
    set offsetPuckD [expr $offsetPuckC + $PuckView::NUM_PORT]

    $itk_component(cylinder) config \
    -portNamePrefix $m_cassetteName \
    -offset $offsetCylinder

    $itk_component(puckA) config \
    -portNamePrefix ${m_cassetteName}A \
    -offset $offsetPuckA

    $itk_component(puckB) config \
    -portNamePrefix ${m_cassetteName}B \
    -offset $offsetPuckB

    $itk_component(puckC) config \
    -portNamePrefix ${m_cassetteName}C \
    -offset $offsetPuckC

    $itk_component(puckD) config \
    -portNamePrefix ${m_cassetteName}D \
    -offset $offsetPuckD

    $itk_component(csc) config \
    -portNamePrefix ${m_cassetteName}A \
    -offset $offsetCylinder

}
body ITKCassetteView::handleResize { winID width height } {
    if {$winID != $m_parent_id} return

    if {$itk_option(-purpose) == "forProbe"} {
        set width [expr $width / 2.0]
    }

    #puts "resize: $width $height"

    if {($width == $m_parent_width) && \
        ($height == $m_parent_height) } return
    set m_parent_width $width
    set m_parent_height $height

    set csc_size $width
    if {$csc_size > $height} {
        set csc_size $height
    }
    set puck_size [expr $csc_size / 2.0]

    ##### cylinder size needs to consider ratio
    #set cy_width [$itk_component(cylinder) component myCanvas cget -width]
    #set cy_height [$itk_component(cylinder) component myCanvas cget -height]
    #set cy_ratio [expr double($cy_height) / $cy_width]
    #puts "current cylinder size: $cy_width $cy_height ratio: $cy_ratio"
    #set cy_size [$itk_component(cylinder) cget -size]
    #puts "current cylinder -size $cy_size"
    set ratio [$itk_component(cylinder) getRatio]
    #puts "ratio from call: $ratio"
    set cylinder_size $width
    set cylinder_size_from_height [expr $height / $ratio]
    if {$cylinder_size > $cylinder_size_from_height} {
        #puts "use height as size"
        set cylinder_size $cylinder_size_from_height
    }
    #puts "cy size: $cylinder_size"

    $itk_component(cylinder) config \
    -size $cylinder_size

    $itk_component(puckA) config -size $puck_size
    $itk_component(puckB) config -size $puck_size
    $itk_component(puckC) config -size $puck_size
    $itk_component(puckD) config -size $puck_size

    $itk_component(csc) config \
    -size $csc_size

    if {$itk_option(-purpose) == "forProbe"} {
        $itk_component(cylinder_force) config -size $cylinder_size
        $itk_component(puckA_force) config -size $puck_size
        $itk_component(puckB_force) config -size $puck_size
        $itk_component(puckC_force) config -size $puck_size
        $itk_component(puckD_force) config -size $puck_size
    }

    updateDisplay
}
body ITKCassetteView::repack { } {
    switch -exact -- $itk_option(-type) {
        1 {
            pack forget $itk_component(puck_frame)
            pack forget $itk_component(csc_frame)
            pack $itk_component(cylinder_frame) -expand 1 -fill both -padx 0 -pady 0
            $itk_component(cylinder) config \
            -calibrationCassette 0
            pack forget $itk_component(puck_force_frame)
            pack $itk_component(cylinder_force_frame) -expand 1 -fill both -padx 0 -pady 0

            if {$itk_option(-purpose) == "forProbe"} {
                $itk_component(cylinder_force) config \
                -calibrationCassette 0
            }
        }
        2 {
            pack forget $itk_component(puck_frame)
            pack forget $itk_component(csc_frame)
            pack $itk_component(cylinder_frame) -expand 1 -fill both -padx 0 -pady 0
            $itk_component(cylinder) config \
            -calibrationCassette 1
            pack forget $itk_component(puck_force_frame)
            pack $itk_component(cylinder_force_frame) -expand 1 -fill both -padx 0 -pady 0
            if {$itk_option(-purpose) == "forProbe"} {
                $itk_component(cylinder_force) config \
                -calibrationCassette 1
            }
        }
        3 {
            pack forget $itk_component(cylinder_frame)
            pack forget $itk_component(csc_frame)
            pack $itk_component(puck_frame) -expand 1 -fill both -padx 0 -pady 0
            pack forget $itk_component(cylinder_force_frame)
            pack $itk_component(puck_force_frame) -expand 1 -fill both -padx 0 -pady 0
        }
        4 {
            pack forget $itk_component(cylinder_frame)
            pack forget $itk_component(puck_frame)
            pack $itk_component(csc_frame) -expand 1 -fill both -padx 0 -pady 0
            pack forget $itk_component(cylinder_force_frame)
            pack forget $itk_component(puck_force_frame)
        }
        default {
            pack forget $itk_component(cylinder_frame)
            pack forget $itk_component(puck_frame)
            pack forget $itk_component(cylinder_force_frame)
            pack forget $itk_component(puck_force_frame)
        }
    }
}
body ITKCassetteView::handleClickAll { } {
    set current [$itk_component(all) cget -relief]

    if {$current == "sunken"} {
        $itk_component(all) config \
        -background $BaseSampleHolderView::COLOR_UNSELECTED \
        -foreground white \
        -disabledforeground white \
        -relief raised

        set value 0
    } else {
        $itk_component(all) config \
        -background $BaseSampleHolderView::COLOR_SELECTED \
        -foreground black \
        -disabledforeground black \
        -relief sunken

        set value 1
    }
    set cmd $itk_option(-onClickAll)

    #set start [expr $itk_option(-offset) + 1]
    #set end [expr $start + 96]
    #include the cassette itself
    set start $itk_option(-offset)
    set end [expr $start + 97]


    if {$cmd != ""} {
        lappend cmd $value $start $end
        eval $cmd
    }
}
body ITKCassetteView::handleRightClickAll { } {
    set cmd $itk_option(-onRightClickAll)
    if {$cmd != ""} {
        set current_status [lindex $itk_option(-statusContents) 1]
        switch -exact -- $current_status {
            j -
            b { set state u }
            default { set state b }
        }

        ### use index of the cassette status will cause whole cassette change
        set start $itk_option(-offset)
        #### length is ignored for the whole cassettte
        set length 96
        lappend cmd $start $length $state
        eval $cmd
    }

}
body ITKCassetteView::updateStatusDisplay { } {
    set cassette_status [lindex $itk_option(-statusContents) 0]
    config -status $cassette_status

    set cylinder_status [lrange $itk_option(-statusContents) 1 96]
    $itk_component(cylinder) config -statusContents $cylinder_status

    set puckA_status [lrange $itk_option(-statusContents) 1 16]
    $itk_component(puckA) config -statusContents $puckA_status

    set puckB_status [lrange $itk_option(-statusContents) 17 32]
    $itk_component(puckB) config -statusContents $puckB_status

    set puckC_status [lrange $itk_option(-statusContents) 33 48]
    $itk_component(puckC) config -statusContents $puckC_status

    set puckD_status [lrange $itk_option(-statusContents) 49 64]
    $itk_component(puckD) config -statusContents $puckD_status

    set csc_status [lrange $itk_option(-statusContents) 1 96]
    $itk_component(csc) config -statusContents $csc_status
}
body ITKCassetteView::updateProbeDisplay { } {
    ###turn on/off all according to all ports
    set all_on 1
    foreach port_selected [lrange $itk_option(-probeContents) 1 end] {
        if {!$port_selected} {
            set all_on 0
            break
        }
    }
    if {!$all_on} {
        $itk_component(all) config \
        -background $BaseSampleHolderView::COLOR_UNSELECTED \
        -foreground white \
        -disabledforeground white \
        -relief raised
    } else {
        $itk_component(all) config \
        -background $BaseSampleHolderView::COLOR_SELECTED \
        -foreground black \
        -disabledforeground black \
        -relief sunken
    }

    set cylinder_probe [lrange $itk_option(-probeContents) 1 96]
    $itk_component(cylinder) config -probeContents $cylinder_probe

    set puckA_probe [lrange $itk_option(-probeContents) 1 16]
    $itk_component(puckA) config -probeContents $puckA_probe

    set puckB_probe [lrange $itk_option(-probeContents) 17 32]
    $itk_component(puckB) config -probeContents $puckB_probe

    set puckC_probe [lrange $itk_option(-probeContents) 33 48]
    $itk_component(puckC) config -probeContents $puckC_probe

    set puckD_probe [lrange $itk_option(-probeContents) 49 64]
    $itk_component(puckD) config -probeContents $puckD_probe

    $itk_component(csc) config -probeContents $cylinder_probe
}
body ITKCassetteView::updateForceDisplay { } {

    if {$itk_option(-purpose) != "forProbe"} return
    #puts "updateForceDisplay"

    set cylinder_force [lrange $itk_option(-forceContents) 1 96]
    $itk_component(cylinder_force) config -forceContents $cylinder_force

    set puckA_force [lrange $itk_option(-forceContents) 1 16]
    $itk_component(puckA_force) config -forceContents $puckA_force

    set puckB_force [lrange $itk_option(-forceContents) 17 32]
    $itk_component(puckB_force) config -forceContents $puckB_force

    set puckC_force [lrange $itk_option(-forceContents) 33 48]
    $itk_component(puckC_force) config -forceContents $puckC_force

    set puckD_force [lrange $itk_option(-forceContents) 49 64]
    $itk_component(puckD_force) config -forceContents $puckD_force
}
body ITKCassetteView::updateCylinderMoveDisplay { } {
    if {$itk_option(-purpose) != "forMoveOrigin" && \
    $itk_option(-purpose) != "forMoveDestination"} {
        return
    }
    #puts "updateCylinderMoveDisplay for $this"
    set cylinder_move [lrange $itk_option(-cylinderMoveContents) 1 96]
    #puts "contents: $cylinder_move"
    $itk_component(cylinder) config -moveContents $cylinder_move
}
body ITKCassetteView::updatePuckMoveDisplay { } {
    if {$itk_option(-purpose) != "forMoveOrigin" && \
    $itk_option(-purpose) != "forMoveDestination"} {
        return
    }
    set puckA_move [lrange $itk_option(-puckMoveContents) 1 16]
    $itk_component(puckA) config -moveContents $puckA_move

    set puckB_move [lrange $itk_option(-puckMoveContents) 17 32]
    $itk_component(puckB) config -moveContents $puckB_move

    set puckC_move [lrange $itk_option(-puckMoveContents) 33 48]
    $itk_component(puckC) config -moveContents $puckC_move

    set puckD_move [lrange $itk_option(-puckMoveContents) 49 64]
    $itk_component(puckD) config -moveContents $puckD_move
}
body ITKCassetteView::updateDisplay { } {
    updateStatusDisplay
    updateProbeDisplay
}
class DCSCassetteView {
    inherit ITKCassetteView ::DCS::ComponentGate

	itk_option define -controlSystem controlsytem ControlSystem "dcss"
    itk_option define -activeClientOnly activeClientOnly ActiveClientOnly 1
	itk_option define -systemIdleOnly systemIdleOnly SystemIdleOnly 1

    itk_option define -probeString probeString ProbeString robot_probe
    itk_option define -statusString statusString StatusString robot_cassette
    itk_option define -forceString forceString ForceString ""
    itk_option define -moveString moveString MoveString robot_move
    itk_option define -moveStatusString moveStatusString MoveStatusString  \
    robotMoveStatus
    itk_option define -ownerString ownerString OwnerString cassette_owner

    itk_option define -scanIdString scanIdString ScanIdString scanId_config {
        setupScanIdReference
    }

    public method handleStringStatusEvent
    public method handleStringProbeEvent
    public method handleStringForceEvent
    public method handleStringOwnerEvent
    public method handleStringMoveEvent
    public method handleStringMoveStatusEvent

    ##### test method
    public method testClick { index name }
    public method testClickAll { value start end }

    protected method unregisterLastStatus
    protected method registerNewStatus
    protected method unregisterLastProbe
    protected method registerNewProbe
    protected method unregisterLastForce
    protected method registerNewForce
    protected method unregisterLastOwner
    protected method registerNewOwner
    protected method unregisterLastRobotMove
    protected method registerNewRobotMove
    protected method unregisterLastRobotMoveStatus
    protected method registerNewRobotMoveStatus

    private method setupScanIdReference

    protected variable m_deviceFactory
    protected variable m_currentStatusString ""
    protected variable m_currentProbeString ""
    protected variable m_currentForceString ""
    protected variable m_currentOwnerString ""
    protected variable m_currentMoveString ""
    protected variable m_currentMoveStatusString ""

    protected method handleNewOutput
    protected method updateBubble { }

    constructor { args } {
        #eval ITKCassetteView::constructor $args
    } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        eval itk_initialize $args

        announceExist
    }
    destructor {
        unregisterLastStatus
        unregisterLastProbe
        unregisterLastForce
        unregisterLastOwner
        unregisterLastRobotMove
        unregisterLastRobotMoveStatus
    }
}
body DCSCassetteView::unregisterLastStatus { } {
    if {$m_currentStatusString == "" } return

    set statusObj [$m_deviceFactory createString $m_currentStatusString]
    
    $statusObj unregister $this contents handleStringStatusEvent
    
    set m_currentStatusString ""
}

body DCSCassetteView::registerNewStatus { } {
    set newStatusString $itk_option(-statusString)

    if {$newStatusString == ""} return

    set statusObj [$m_deviceFactory createString $newStatusString]
    
    $statusObj register $this contents handleStringStatusEvent
    
    set m_currentStatusString $newStatusString
}

body DCSCassetteView::handleStringStatusEvent { stringName_ targetReady_ alias_ contents_ - } {
    if {!$targetReady_} return

    #puts "handle status:$contents_"
    set start $itk_option(-offset)
    set end [expr $start + 96]

    configure -statusContents [lrange $contents_ $start $end]
}

body DCSCassetteView::unregisterLastProbe { } {
    if {$m_currentProbeString == "" } return

    set probeObj [$m_deviceFactory createString $m_currentProbeString]
    
    $probeObj unregister $this contents handleStringProbeEvent
    
    set m_currentProbeString ""
}

body DCSCassetteView::registerNewProbe { } {
    set newProbeString $itk_option(-probeString)

    if {$newProbeString == ""} return

    set probeObj [$m_deviceFactory createString $newProbeString]
    
    $probeObj register $this contents handleStringProbeEvent
    
    set m_currentProbeString $newProbeString
}
body DCSCassetteView::handleStringProbeEvent { stringName_ targetReady_ alias_ contents_ - } {

    if {!$targetReady_} return
    #puts "handle probe:$contents_"

    set ll [llength $contents_]

    # 3 * (96+1) = 291
    if {$ll < 291} {
        set num [expr "291 - $ll"]
        for {set i 0} {$i < $num} {incr i} {
            lappend $contents_ 0
        }
        if {$m_currentProbeString != ""} {
            set probeObj [$m_deviceFactory createString $m_currentProbeString]
            $probeObj sendContentsToServer $contents_
        }
        return
    }

    set start $itk_option(-offset)
    set end [expr $start + 96]
    config -probeContents [lrange $contents_ $start $end]
    updateDisplay
}
body DCSCassetteView::unregisterLastForce { } {
    if {$m_currentForceString == "" } return

    set forceObj [$m_deviceFactory createString $m_currentForceString]
    
    $forceObj unregister $this contents handleStringForceEvent
    
    set m_currentForceString ""
}

body DCSCassetteView::registerNewForce { } {
    set newForceString $itk_option(-forceString)

    if {$newForceString == ""} return

    set forceObj [$m_deviceFactory createString $newForceString]
    
    $forceObj register $this contents handleStringForceEvent
    
    set m_currentForceString $newForceString
}
body DCSCassetteView::handleStringForceEvent { stringName_ targetReady_ alias_ contents_ - } {

    if {!$targetReady_} return
    #puts "handle force:$contents_"

    config -forceContents $contents_
    updateForceDisplay
}
configbody DCSCassetteView::statusString {
    #puts "option statusString $itk_option(-statusString)"

    set newString $itk_option(-statusString)

    if {$newString != $m_currentStatusString} {
        unregisterLastStatus
        registerNewStatus
    }
}

configbody DCSCassetteView::probeString {
    #puts "option probeString $itk_option(-probeString)"
    set newString $itk_option(-probeString)

    if {$newString != $m_currentProbeString} {
        unregisterLastProbe
        registerNewProbe
    }
}
configbody DCSCassetteView::forceString {
    #puts "option forceString $itk_option(-forceString)"
    set newString $itk_option(-forceString)

    if {$newString != $m_currentForceString} {
        unregisterLastForce
        registerNewForce
    }
}
configbody DCSCassetteView::ownerString {
    set newString $itk_option(-ownerString)

    if {$newString != $m_currentOwnerString} {
        unregisterLastOwner
        registerNewOwner
    }
}
body DCSCassetteView::setupScanIdReference { } {
    if {$itk_option(-scanIdString) != ""} {
        set obj \
        [$m_deviceFactory createString $itk_option(-scanIdString)]

        $obj createAttributeFromField scanId_left   0
        $obj createAttributeFromField scanId_middle 1
        $obj createAttributeFromField scanId_right  2
        switch -exact -- $itk_option(-offset) {
            0   { set ref [list $obj scanId_left]}
            97  { set ref [list $obj scanId_middle]}
            194 { set ref [list $obj scanId_right]}
            default { set ref "" }
        }
    } else {
        set ref ""
    }

    configure -scanIdReference $ref
}
body DCSCassetteView::unregisterLastOwner { } {
    if {$m_currentOwnerString == "" } return

    set ownerObj \
    [$m_deviceFactory createCassetteOwnerString $m_currentOwnerString]
    
    $ownerObj unregister $this contents handleStringOwnerEvent
    
    set m_currentOwnerString ""
}

body DCSCassetteView::registerNewOwner { } {
    set newOwnerString $itk_option(-ownerString)

    if {$newOwnerString == ""} return

    set ownerObj \
    [$m_deviceFactory createCassetteOwnerString $newOwnerString]
    
    $ownerObj register $this contents handleStringOwnerEvent
    
    set m_currentOwnerString $newOwnerString
}
body DCSCassetteView::handleStringOwnerEvent { stringName_ targetReady_ alias_ contents_ - } {

    if {!$targetReady_} return

    #puts "cassetteView owner: $contents_"

    ##retrieve owner
    switch -exact -- $itk_option(-offset) {
        0   { set owner [lindex $contents_ 1] }
        97  { set owner [lindex $contents_ 2] }
        194 { set owner [lindex $contents_ 3] }
        default { set owner error }
    }
    #puts "$this owner $owner"
    
    configure -owner $owner
}
configbody DCSCassetteView::moveString {
    set newString $itk_option(-moveString)

    if {$newString != $m_currentMoveString} {
        unregisterLastRobotMove
        registerNewRobotMove
    }
}
body DCSCassetteView::unregisterLastRobotMove { } {
    if {$m_currentMoveString == "" } return

    set moveObj \
    [$m_deviceFactory createRobotMoveListString $m_currentMoveString]
    
    $moveObj unregister $this  contents handleStringMoveEvent
    
    set m_currentMoveString ""
}

body DCSCassetteView::registerNewRobotMove { } {
    set newMoveString $itk_option(-moveString)

    if {$newMoveString == ""} return

    set moveObj \
    [$m_deviceFactory createRobotMoveListString $newMoveString]
    
    $moveObj register $this contents handleStringMoveEvent
    
    set m_currentMoveString $newMoveString
}
body DCSCassetteView::handleStringMoveEvent { stringName_ targetReady_ alias_ contents_ - } {

    if {!$targetReady_} return
    #puts "DCSCassetteView::handleStringAMoveEvent: $contents_"

    set cylinderMoveContents [$stringName_ getCylinderMoveContents]
    set puckMoveContents     [$stringName_ getPuckMoveContents]
    #puts "get cylinder $cylinderMoveContents"
    #puts "get puck $puckMoveContents"

    set start $itk_option(-offset)
    set end [expr $start + 96]

    config -cylinderMoveContents [lrange $cylinderMoveContents $start $end]
    config -puckMoveContents     [lrange $puckMoveContents     $start $end]
    #updateForceDisplay
}
configbody DCSCassetteView::moveStatusString {
    set newString $itk_option(-moveStatusString)

    if {$newString != $m_currentMoveStatusString} {
        unregisterLastRobotMoveStatus
        registerNewRobotMoveStatus
    }
}
body DCSCassetteView::unregisterLastRobotMoveStatus { } {
    if {$m_currentMoveStatusString == "" } return

    set obj \
    [$m_deviceFactory createString $m_currentMoveStatusString]
    
    $obj unregister $this  contents handleStringMoveStatusEvent
    
    set m_currentMoveStatusString ""
}

body DCSCassetteView::registerNewRobotMoveStatus { } {
    set newString $itk_option(-moveStatusString)

    if {$newString == ""} return

    set obj \
    [$m_deviceFactory createString $newString]
    
    $obj register $this contents handleStringMoveStatusEvent
    
    set m_currentMoveStatusString $newString
}
body DCSCassetteView::handleStringMoveStatusEvent {- targetReady_ - contents_ -} {
    if {!$targetReady_} return

    if {$contents_ == ""} return

    set startIndex [lindex $contents_ 2]
    if {![string is integer -strict $startIndex] || $startIndex < 0} {
        log_error wrong startIndex $startIndex in robotMoveStatus
        return
    }

    if {$m_currentMoveString != ""} {
        set obj \
        [$m_deviceFactory createRobotMoveListString $m_currentMoveString]

        puts "handleStringMoveStatusEvent: new startIndex $startIndex"
        $obj setStartIndex $startIndex
    }
}
body DCSCassetteView::testClick { index name } {
    #puts "testClick: $index $name"

    if {$m_currentProbeString != ""} {
        set probeObj [$m_deviceFactory createString $m_currentProbeString]
        set old_contents [$probeObj getContents]
        set old_value [lindex $old_contents $index]

        ### flip
        if {$old_value} {
            set new_value 0
        } else {
            set new_value 1
        }
        set new_contents [lreplace $old_contents $index $index $new_value]
        $probeObj sendContentsToServer $new_contents
    }
}
body DCSCassetteView::testClickAll { value start end } {
    #puts "testClickAll $value $start $end"
    if {$m_currentProbeString != ""} {
        set probeObj [$m_deviceFactory createString $m_currentProbeString]
        set contents [$probeObj getContents]

        for {set i $start} {$i < $end} {incr i} {
            set contents [lreplace $contents $i $i $value]
        }

        $probeObj sendContentsToServer $contents
    }
}
body DCSCassetteView::handleNewOutput { } {
    #puts "handle new output"
	#disable the button based on summation of triggers
	if { $_gateOutput == 1 } {
	    configure -state normal
        #puts "set state to normal"
	} else {
	    configure -state disabled
        #puts "set state to disabled"
	}
    updateBubble
}

configbody DCSCassetteView::activeClientOnly {
	if {$itk_option(-activeClientOnly) } {
        #puts "add input of control system"
		addInput "::$itk_option(-controlSystem) clientState active {This Blu-Ice is passive. Become active.}"
	} else {
		deleteInput "::$itk_option(-controlSystem) clientState"
	}
}

configbody DCSCassetteView::systemIdleOnly {
    set systemIdle [$m_deviceFactory createString system_idle]
	if {$itk_option(-systemIdleOnly) } {
		addInput "$systemIdle contents {} {supporting device}"
	} else {
		deleteInput "$systemIdle contents"
	}
}
body DCSCassetteView::updateBubble { } {
	#delete the help balloon
	catch {wm withdraw .help_shell}
	set message "this blu-ice has a bug"
	
	set outputMessage [getOutputMessage]
	
	foreach {output blocker status reason} $outputMessage {break}

	foreach {object attribute} [split $blocker ~] break
	
	if { ! $_onlineStatus } {
		set message $reason
		#the button has bad inputs and is not ready
		#if { [info commands $object] == "" } {
		#	set message "$object does not exist: $blocker."
		#} else {
		#	set message "Internal errors in $blocker"
		#}
	} elseif { $output } {
		#the widget is enabled
		set message ""
	} else {
		#set deviceStatus $itk_option(-device).status
		#the widget is disabled
		if {$reason == "supporting device" } {

			#something is happening with the device we are interested in.
			switch $status {
				inactive {
			#		configure -labelBackground lightgrey
			#		configure -labelForeground	black
					set message "Device is ready to move."
				}
				moving   {
			#		configure -labelBackground \#ff4040
			#		configure -labelForeground white
					set message "[namespace tail $object] is moving."
				}
				offline  {
			#		configure -labelBackground black
			#		configure -labelForeground white
					set message "DHS '[$object cget -controller]' is offline (needed for [namespace tail $object])."
				}
				default {
			#		configure -labelBackground black
			#		configure -labelForeground white
					set message "[namespace tail $object] is not ready: $status"
				}
			} 
		} else {
			#unhandled reason, use default reason specified with addInput
			set message "$reason"
		}
	}

	DynamicHelp::register $itk_component(all) balloon $message
	DynamicHelp::register $itk_component(scanId) balloon $message
	DynamicHelp::register $itk_component(cylinder) balloon $message
	DynamicHelp::register $itk_component(puckA) balloon $message
	DynamicHelp::register $itk_component(puckB) balloon $message
	DynamicHelp::register $itk_component(puckC) balloon $message
	DynamicHelp::register $itk_component(puckD) balloon $message
}