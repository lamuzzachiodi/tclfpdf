# Author: Pivkin Vladimir
# Description: This extension allows to print rotated and sheared (i.e. distorted like in italic) text.

# TextWithDirection x y txt [direction]
# where
# 	x: abscissa
#	y: ordinate
# 	txt: text string
# 	direction: one of the following values (R by default):
#		R (Right): Left to Right
#	 	U (Up): Bottom to Top
#	 	D (Down): Top To Bottom
#	 	L (Left): Right to Left

# TextWithRotation x y txt txt_angle [font_angle]
#where
# 	x: abscissa
# 	y: ordinate
# 	txt: text string
# 	txt_angle: angle of the text
# 	font_angle: shear angle (0 by default)


proc ::tclfpdf::TextWithDirection {x y txt {direction "R" }} {
    variable ColorFlag; variable k; variable h;variable TextColor;
    if { $direction eq "R" } {
        set s [format "BT %.2f %.2f %.2f %.2f %.2f %.2f Tm (%s) Tj ET" 1 0 0 1 [expr $x*$k] [expr ($h-$y)*$k] [_escape $txt]];
    } elseif { $direction eq "L" } {
        set s [format "BT %.2f %.2f %.2f %.2f %.2f %.2f Tm (%s) Tj ET" -1 0 0 -1 [expr $x*$k] [expr ($h-$y)*$k] [_escape $txt]];
    } elseif { $direction eq "U" } {
        set s [format "BT %.2f %.2f %.2f %.2f %.2f %.2f Tm (%s) Tj ET" 0 1 -1 0 [expr $x*$k] [expr ($h-$y)*$k] [_escape $txt]];
    } elseif { $direction eq "D" } {
        set s [format "BT %.2f %.2f %.2f %.2f %.2f %.2f Tm (%s) Tj ET" 0 -1 1 0 [expr $x*$k] [expr ($h-$y)*$k] [_escape $txt]];
    } else {
        set s [format "BT %.2f %.2f Td (%s) Tj ET" [expr $x*$k] [ expr ($h-$y)*$k] [_escape $txt]];
    }		
    if {$ColorFlag} {
        set s "q $TextColor $s  Q";
    }	
    _out $s;
}

proc ::tclfpdf::TextWithRotation {x y txt txt_angle {font_angle 0}} {
    variable ColorFlag; variable k; variable h; variable TextColor;
    
    set M_PI 3.1415926535897931;
    set font_angle [expr $font_angle + 90+ $txt_angle] ;
    set txt_angle [expr $txt_angle*$M_PI/180];
    set font_angle [expr $font_angle*$M_PI/180];

    set txt_dx [expr cos ($txt_angle)];
    set txt_dy [expr sin ($txt_angle)];
    set font_dx [expr cos ($font_angle)];
    set font_dy [expr sin ($font_angle)];

    set s [format "BT %.2f %.2f %.2f %.2f %.2f %.2f Tm (%s) Tj ET" $txt_dx $txt_dy $font_dx $font_dy [expr $x*$k] [expr ($h-$y)*$k] [ _escape $txt]];
    if {$ColorFlag} {
        set s  "q $TextColor $s Q";
   }	
    _out $s;
}

namespace eval ::tclfpdf:: {
	namespace export \
	TextWithDirection \
	TextWithRotation
}