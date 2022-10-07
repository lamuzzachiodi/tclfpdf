# Author: Olivier Plathey
# This script allows to draw circles and ellipses.
#
#Circle x y r [style]
# where
# x: abscissa of center.
# y: ordinate of center.
# r:  radius.
# style: style of rendering, like for Rect (D, F or FD). Default value: D. 

# Ellipse x  y rx ry [style]
# where
# x: abscissa of center.
# y: ordinate of center.
# rx: horizontal radius.
# ry: vertical radius.
# style: style of rendering, like for Rect (D, F or FD). Default value: D. 

proc ::tclfpdf::Circle { x y r { style D } } {
    Ellipse  $x  $y $r $r $style;
}

proc ::tclfpdf::Ellipse { x y rx ry { style D } } {
    variable k; variable h;
    if {$style == "F" } {
        set op "f";
   } elseif { $style=="FD" || $style=="DF" } {
        set op "B";
    } else {
        set op "S";
    }	
    set lx [expr 4.0/3.0*(sqrt(2.0)-1.0)*$rx];
    set ly [expr 4.0/3.0*(sqrt(2.0)-1.0)*$ry];
    _out [ format "%.2f %.2f m %.2f %.2f %.2f %.2f %.2f %.2f c" \
        [expr ($x+$rx)*$k] [expr ($h-$y)*$k] \
        [expr ($x+$rx)*$k] [expr ($h-($y-$ly))*$k] \
        [expr ($x+$lx)*$k] [expr ($h-($y-$ry))*$k] \
        [expr $x*$k] [expr ($h-($y-$ry))*$k ]];
    _out [ format "%.2f %.2f %.2f %.2f %.2f %.2f c" \
        [expr ($x-$lx)*$k] [expr ($h-($y-$ry))*$k] \
        [expr ($x-$rx)*$k] [expr ($h-($y-$ly))*$k] \
        [expr ($x-$rx)*$k] [expr ($h-$y)*$k] ];
    _out [format "%.2f %.2f %.2f %.2f %.2f %.2f c" \
        [expr ($x-$rx)*$k] [expr ($h-($y+$ly))*$k] \
        [expr ($x-$lx)*$k] [expr ($h-($y+$ry))*$k] \
        [expr $x*$k] [expr ($h-($y+$ry))*$k] ];
    _out [ format "%.2f %.2f %.2f %.2f %.2f %.2f c %s" \
        [expr ($x+$lx)*$k] [expr ($h-($y+$ry))*$k] \
        [expr ($x+$rx)*$k] [expr ($h-($y+$ly))*$k] \
        [expr ($x+$rx)*$k] [expr ($h-$y)*$k] \
        $op];
}

namespace eval ::tclfpdf:: {
	namespace export \
	Ellipse \
	Circle
}