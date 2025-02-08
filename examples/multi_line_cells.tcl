package require tclfpdf
namespace import  ::tclfpdf::*

proc GenWord { }  {

	set len [random 50 100]
	for {set x 0} { $x < $len } { incr x } {
		append w [format %c [random 32 $len] ]
	}	
	return $w
}

set col1 "(1) Здравствулте мир Здравствулте мир Γειά σου κόσμος Γειά σου κόσμος Xin chào thế giới Xin chào thế giới "
set col2 "(2) Xin chào thế giới Xin chào thế giới Xin chào thế giới Здравствулте мир Здравствулте мир Γειά σου κόσμος Γειά σου κόσμος"

proc ::tclfpdf::MCT_SetColumns {} {
	global col1 col2
	return [list $col1 $col2 [GenWord] [GenWord] ]
}

Init;
AddPage;
AddFont "DejaVu" "" "DejaVuSansCondensed.ttf" 1;
SetFont "DejaVu" "" 14;
# Table with 20 rows and 4 columns
MCT_SetWidths  { 30 50 30 40 }
MCT_PrintRows 7

Output "multicell.pdf" ;