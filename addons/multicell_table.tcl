# Author: Olivier Plathey
# Description: The goal of this script is to show how to build a table from MultiCells.
#As MultiCells go to the next line after being output, the base idea consists in saving the
#current position, printing the MultiCell and resetting the position to its right.
#There is a difficulty, however, if the table is too long: page breaks. Before outputting a row,
#it is necessary to know whether it will cause a break or not. If it does overflow, a manual page break must be done first.
#To do so, the height of the row must be known in advance; it is the maximum of the heights of
#the MultiCells it is made up of. To know the height of a MultiCell, the NbLines() procedure is used: it returns the number
#of lines a MultiCell will occupy.

variable MCT_widths {};
variable MCT_aligns  {};

namespace export \
	MCT_SetWidths \
	MCT_SetAligns \
	MCT_PrintRows \
	MCT_Row \
	MCT_CheckPageBreak \
	MCT_NbLines ;

proc ::tclfpdf::MCT_SetWidths { w } {
	variable MCT_widths
	#Set the array of column widths
        set MCT_widths $w
}

proc ::tclfpdf::MCT_SetAligns { a } {
	variable MCT_aligns	
        # Set the array of column alignments
        set MCT_aligns $a
}

proc ::tclfpdf::MCT_PrintRows { nrows {fila {}} } {
	variable MCT_widths
	if  {$MCT_widths eq {} } {
		Error "No widths has been set"
	}
	if { $fila eq {} } {
		if { [ _procexists MCT_SetColumns] } {
			for { set i 0} { $i< $nrows } { incr i} {
				set fila [MCT_SetColumns]
				if   { [llength $MCT_widths] != [llength $fila] }  { Error "Numbers of widths <> numbers of columns" };
				MCT_Row $fila
			}
		} else {
			Error "Proc ::tclfpdf::MCT_SetColumns must be defined"
		}
	} else {
		if   { [llength $MCT_widths] != [llength $fila] } { Error "Numbers of widths <> numbers of columns" };
		for { set i 0} { $i< $nrows } { incr i} {
			MCT_Row $fila
		}
	}
}	

proc ::tclfpdf::MCT_Row { data } {
	variable MCT_widths ; variable MCT_aligns ;
	
        # Calculate the height of the row
        set nb 0
        for {set i 0} { $i <  [llength $data] } { incr i } {
		set NB [ MCT_NbLines [lindex $MCT_widths $i] [lindex $data $i] ]  
		if {$nb < $NB} {
			set nb $NB
		}	
	}
        set h1 [expr 5*$nb ]
        # Issue a page break first if needed
        MCT_CheckPageBreak $h1
        # Draw the cells of the row
        for {set i 0} { $i< [llength $data] } {incr i} {
            set w1 [lindex $MCT_widths $i]
	    set a [lindex $MCT_aligns $i ]
	    if {$a == {} } {
		set a "L"
	    }
            # Save the current position
            set x1 [GetX]
            set y1 [GetY]
            # Draw the border
            Rect $x1 $y1 $w1 $h1
            # Print the text
            MultiCell $w1 5 [lindex $data $i ] 0 $a 0;
            # Put the position to the right of the cell
            SetXY [expr $x1+$w1] $y1
        }
        # Go to the next line
        Ln $h1
}

proc  ::tclfpdf::MCT_CheckPageBreak  { h1 } {
	variable CurOrientation ; variable PageBreakTrigger;
        # If the height h would cause an overflow, add a new page immediately
        if { [expr [GetY] +$h1 > $PageBreakTrigger ]} {
            AddPage $CurOrientation
	}	
}

proc  ::tclfpdf::MCT_NbLines { w1 txt } {
	variable CurrentFont; variable cMargin; variable FontSize; variable rMargin;
	variable x ; variable w; variable TAB; variable unifontSubset;
        # Compute the number of lines a MultiCell of width w will take
        if { ![ isset CurrentFont]} {
             Error "No font has been set"
	}
	set cw [ _getList2Arr $CurrentFont cw];
        if { $w1 ==0 } {
            set w1 [expr $w- $rMargin-$x]
	}
        set wmax  [expr ($w1-2*$cMargin)]
        set s [ string map [list \r {} \t $TAB ] $txt]
	if {$unifontSubset == 1} {
		set nb [utf8len $s];
		while {$nb >0 && [utf8substr $s [expr $nb -1] 1]  == "\n" } {
			incr nb -1;
		} 
	}  else {
		set nb [string length $s];
		set idx [expr $nb-1]
		if {$nb>0 && [string index $s $idx] =="\n"} {
			incr nb -1;
		}
	}
        set sep -1
        set i 0
        set j 0
        set l 0
        set nl 1
        while { $i < $nb } {
		;# Get next character
		if {$unifontSubset==1} {
			set c [utf8substr $s $i 1 ];
		} else {	
			set c [string index $s $i];
		}	
            if { $c == "\n" } {
                incr i
                set sep -1
                set j $i
                set l 0
                incr nl
                continue;
            }
            if { $c == " " } {
                set sep $i
	    }	
	    if {$unifontSubset==1} { 
			set l [expr $l + [GetStringWidth $c]];
	    } else {
			set l [expr $l + ([_findchar $cw $c]*$FontSize/1000)];
	    }
            if {$l>$wmax } {
                if {$sep ==-1 } {
			if { $i == $j } {
				incr i
			}
                } else {
			set i [incr sep]
		}    
                set sep  -1
                set j  $i
                set l  0
                incr nl
            } else {
                incr i
	    } 	
        }
        return $nl
}