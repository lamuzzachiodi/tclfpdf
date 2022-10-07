# Author: yukihiro_o
# This extension allows to set a dash pattern and draw dashed lines or rectangles.
#
# SetDash [ black white ]
# where 
# 	black: length of dashes
# 	white: length of gaps
# Call the function without parameter to restore normal drawing.

proc ::tclfpdf::SetDash { {black 0}  {white 0} } {
    variable k;

    if { $black } {
            set s [ format "\[%.3f %.3f\] 0 d" [expr $black*$k] [expr $white*$k ]]
	} else {
            set s "\[\] 0 d";
	}    
        _out $s;
}

namespace eval ::tclfpdf:: {
	namespace export \
	SetDash
}	