package require tclfpdf
namespace import  ::tclfpdf::*

#Page header
proc Header {} {
    # Logo
    Image "logo.gif" 10 6 30;
    # Times bold 25
    SetFont Times B 25;
    # Move to the right
    Cell 80;
    # Title
    Cell 60 10 "This is the Title" 1 0 "C";
    # Line break
    Ln 20;
    
}

# Page footer
proc Footer { } {

    # Position at 1.5 cm from bottom
    SetY -15;
    # Arial italic 8
    SetFont Arial I 8;
    # Page number
    Cell 0 10 "Page [PageNo] of %nb%" 0 0 "C";
}

# Fancy table
proc FancyTable { header  data } {
	SetFont Arial "I" 16;
	# Header
	SetFillColor 255 0 0;
	SetTextColor 255;
	SetDrawColor 128 0 0;
	SetLineWidth .3;
	#~ SetFont Arial
	foreach col $header {
		Cell 40 7 $col 1 0 C 1;
	}
	Ln;
	SetFillColor 224 235 255;
	SetTextColor 0;
	SetFont "";
	#~ SetFont Courier "" 14;
	# Data
	set fill 0
	foreach row $data {
		foreach col $row {
			Cell 40 7 $col LR 0 L $fill			
		}		
		Ln;
		set fill [expr !$fill]
	}
	Cell [expr 40*6] 0 "" T;
}

SetPageOrientation L;
AliasNbPages;
AddPage;
set header "Head_1 Head_2 Head_3 Head_4 Head_5 Head_6";
set row "field_1 field_22 field_333 field_4444 field_55555 field_666666";
set nrow 0;
set data {};
while { $nrow  <  50 } {
	lappend data "$nrow)$row"
	incr nrow
} 
FancyTable $header $data
Output "fancy_table.pdf";