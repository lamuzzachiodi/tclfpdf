;# *******************************************************************************
;# tclfpdf.tcl 
;# Version: 1.7 (2024)
;# Ported to TCL by L. A. Muzzachiodi
;# Credits:
;# Based on tFPDF 1.33 by Ian Back <ianb@bpm1.com>
;# and Tycho Veltmeijer <tfpdf@tychoveltmeijer.nl> (versions 1.30+)
;# wich is based on fpdf.php 1.8.2 by Olivier Plathey 
;# Parse of JPEG based on pdf4tcl 0.8 by Peter Spjuth
;# *******************************************************************************
;# Note: 
;# the definition of core fonts have a diference: the uv index in FPDF, not tfpdf, cause a bigger file (?)

set version 1.7
package provide tclfpdf $version
package require Tk
namespace eval ::tclfpdf:: {
	namespace export \
		        Init \
		        SetMargins \
		        SetLeftMargin \
		        SetTopMargin \
		        SetRightMargin \
		        SetAutoPageBreak \
		        SetDisplayMode \
		        SetCompression \
		        SetTitle \
		        SetSubject \
		        SetAuthor \
		        SetKeywords \
		        SetCreator \
		        AliasNbPages \
		        Error \
		        Open \
		        Close \
		        AddPage \
		        Header \
		        Footer \
		        PageNo \
		        SetDrawColor \
		        SetFillColor \
		        SetTextColor \
		        GetStringWidth \
		        SetLineWidth \
		        Line \
		        Rect \
		        AddFont \
		        SetFont \
		        SetFontSize \
		        AddLink \
		        SetLink \
		        Link \
		        Text \
		        AcceptPageBreak \
		        Cell \
		        MultiCell \
		        Write \
		        Ln \
		        Image \
		        GetX \
		        SetX \
		        GetY \
		        SetY \
		        SetXY \
		        Output \
			ShowMoreInfoError  \
			SetSystemFonts \
			SetUserPath;
	;# ShowMoreInfoError , SetSystemFonts and SetUserPath only in TCLFPDF

	;#These will be set at the end
	variable TCLFPDF_USERPATH		;# path of writeable folder for cache
	variable TCLFPDF_COREFONTPATH 		;# path of core fonts definitions and ttfont source
	variable TCLFPDF_SYSTEMFONTPATH		;# list of path for load fonts


	variable VERSION $version
	variable unifontSubset		;#
	variable page                      	;# current page number
	variable n                           	;# current object number
	variable offsets                   	;# array of object offsets
	variable buffer                    	;# buffer holding in-memory PDF
	variable pages                    	;# array containing pages
	variable state                     	;# current document state
	variable compress              	;# compression flag
	variable k                          	;# scale factor (number of points in user unit)
	variable DefOrientation       	;# default orientation
	variable CurOrientation       	;# current orientation
	variable StdPageSizes         	;# standard page sizes
	variable DefPageSize           	;# default page size
	variable CurPageSize           	;# current page size
	variable CurRotation			;#current page rotation
	variable PageInfo			;#page-related data
	variable wPt 
	variable hPt                       	;# dimensions of current page in points
	variable w 
	variable h                        	;# dimensions of current page in user unit
	variable lMargin                	;# left margin
	variable tMargin                	;# top margin
	variable rMargin                	;# right margin
	variable bMargin                     	;# page break margin
	variable cMargin                    	;# cell margin
	variable x
	variable y                         	;# current position in user unit
	variable lasth                        	;# height of last printed cell
	variable LineWidth                  	;# line width in user unit
	variable CoreFonts                  	;# array of core font names
	variable fonts                         	;# array of used fonts
	variable FontFiles                    	;# array of font files
	variable encodings			;#array of encodings
	variable cmaps				;#array of ToUnicode CMaps
	variable FontFamily                 	;# current font family
	variable FontStyle                   	;# current font style
	variable underline                    	;# underlining flag
	variable CurrentFont               	;# current font info
	variable FontSizePt           	;# current font size in points
	variable FontSize                      ;# current font size in user unit
	variable DrawColor                 	;# commands for drawing color
	variable FillColor                	;# commands for filling color
	variable TextColor                	;# commands for text color
	variable ColorFlag                	;# indicates whether fill and text colors are different
	variable WithAlpha			;# indicates whether alpha channel is used
	variable ws                        	;# word spacing
	variable images                	;# array of used images
	variable PageLinks                  	;# array of links in pages
	variable links                        	;# array of internal links
	variable AutoPageBreak        	;# automatic page breaking
	variable PageBreakTrigger        	;# threshold used to trigger page breaks
	variable InHeader                	;# flag set when processing header
	variable InFooter                	;# flag set when processing footer
	variable AliasNbPages       	;# alias for total number of pages
	variable ZoomMode                	;# zoom display mode
	variable LayoutMode                	;# layout display mode
	variable metadata			;# document properties
	variable CreationDate		;#document creation date
	variable PDFVersion                	;# PDF version number
	variable Spaces4Tab			;#How spaces are a Tab ?
	variable TAB				;# Constant with spaces according Space4Tab
	
	variable TraceAfterError		;#Show more info after error
	
proc ::tclfpdf::Init { { orientation P } { unit mm } { size A4 } } {
	variable w; variable h; variable StdPageSizes;
	;# Initialization of properties 
	variable state 0;
	variable page 0;
	variable n 2;
	variable buffer "";
	variable pages ; array unset pages *;
	variable PageInfo; array unset PageInfo *;
	variable fonts ;	array unset fonts *;
	variable FontFiles; array unset FontFiles *;
	variable encodings; array unset encodings *;
	variable cmaps; array unset cmaps *;
	variable images ; array unset images *;
	variable links ; array unset links *;
	variable InHeader  0;
	variable InFooter  0;
	variable lasth  0;
	variable FontFamily  "";
	variable FontStyle  "";
	variable FontSizePt  12;
	variable underline  0;
	variable DrawColor  "0 G";
	variable FillColor  "0 g";
	variable TextColor  "0 g";
	variable ColorFlag  0;
	variable WithAlpha 0;
	variable ws  0;
	;# Added because tab is showed as square
	variable Spaces4Tab 4;
	variable TAB [string repeat " " $Spaces4Tab];
	variable x -1; # In PHP could be null not in tcl, i.e. if no there are page added
	variable y -1; # Idem
	;# Core fonts
	variable CoreFonts [list courier helvetica times symbol zapfdingbats];
	;# Scale factor
	variable k; 
	if {$unit == "pt"} {
		set k 1;
	} elseif {$unit=="mm"} {
		set k  [expr 72/25.4];
	} elseif {$unit=="cm"} {
		set k  [expr 72/2.54];
	} elseif {$unit=="in"} {
		set k  72;
	} else {
		Error "Incorrect unit: $unit";
	}        
	;# Page sizes
	array set StdPageSizes { a3 {841.89 1190.55 }  a4 {595.28 841.89} a5 {420.94 595.28} letter {612 792} legal {612 1008} };
	set size [ _getpagesize $size];
	variable DefPageSize  $size;
	variable CurPageSize  $size;
	;# Page orientation
	variable DefOrientation;
	set orientation [ string tolower $orientation];
	if {$orientation=="p" || $orientation=="portrait"} {
		set DefOrientation  "P";
		set w  [lindex $size 0];
		set h  [lindex  $size 1];
	} elseif {$orientation=="l" || $orientation=="landscape"} {
		set DefOrientation  "L";
		set w  [lindex $size 1] ;
		set h  [lindex $size 0];
	} else {
		Error "Incorrect orientation: $orientation";
	}        
	variable CurOrientation  $DefOrientation;
	variable wPt  [expr $w*$k];
	variable hPt   [expr $h*$k];
	;#Page rotation
	variable CurRotation 0;
	;# Page margins (1 cm)
	set margin [expr 28.35/$k];
	SetMargins $margin $margin;
	;# Interior cell margin (1 mm)
	variable cMargin  [expr $margin/10.0];
	;# Line width (0.2 mm)
	variable LineWidth [expr .567/$k];
	;# Automatic page break
	SetAutoPageBreak 1 [expr 2*$margin];
	;# Default display mode
	SetDisplayMode "default" ;
	;# Enable compression
	SetCompression 1;
	;#Metadata
	variable VERSION;
	variable metadata; 
	array set metadata "Producer TCLFPDF$VERSION";
	
	;# Set default PDF version number
	variable PDFVersion  "1.3";
	if {[namespace which -command Header]== "::Header"} {
		if {[namespace which -command Header]  =="::tclfpf::Header"} {
			rename ::tclfpdf::Header ""; 
		}
		rename Header ::tclfpdf::Header;
	}
	if {[namespace which -command Footer]== "::Footer"} {
		if {[namespace which -command Footer] == "::tclfpf::Footer"} {
			rename ::tclfpdf::Footer "" ;
		}
		rename Footer ::tclfpdf::Footer;
	};
	variable unifontSubset 0;
	variable AliasNbPages "";
	
	;#Set action after Fatal Error, default is just exit 
	variable TraceAfterError 0;
	
}

proc ::tclfpdf::SetMargins { left top {right ""} } {
	variable lMargin; variable tMargin; variable rMargin; 
	;# Set left, top and right margins
	set lMargin  $left;
	set tMargin  $top;
	if {$right==""} {
		set right  $left;
	}        
	set rMargin  $right;
}

proc ::tclfpdf::SetLeftMargin { margin } {
	variable page; variable lMargin;variable x;
	;# Set left margin
	set lMargin  $margin;
	if {$page>0 &&  $x<$margin} {
		set x  $margin;
	}	
}

proc ::tclfpdf::SetTopMargin { margin } {
	variable tMargin;
	;# Set top margin
	set tMargin  $margin;
}

proc ::tclfpdf::SetRightMargin { margin } {
	variable rMargin;
	;# Set right margin
	set rMargin  $margin;
}

proc ::tclfpdf::SetAutoPageBreak { auto { margin 0} } {
	variable bMargin; variable h; variable AutoPageBreak; variable PageBreakTrigger;
	;# Set auto page break mode and triggering margin
	set AutoPageBreak  $auto;
	set bMargin  $margin;
	set PageBreakTrigger  [expr $h-$margin];
}

proc ::tclfpdf::SetDisplayMode { zoom  { layout default }} {
	variable ZoomMode; variable LayoutMode;
	;# Set display mode in viewer
	if {$zoom=="fullpage" || $zoom=="fullwidth" || $zoom=="real" || $zoom=="default" || [string is integer $zoom]} {
		set ZoomMode  $zoom;
	} else {
		Error "Incorrect zoom display mode: $zoom" ;
	}        
	if {$layout=="single" || $layout=="continuous" || $layout=="two" || $layout=="default"} {
		set LayoutMode  $layout;
	} else {
		Error "Incorrect layout display mode:  $layout" ;
	}        
}

proc ::tclfpdf::SetCompression { compress1 } {
	variable compress;
	;# Set page compression
	set compress $compress1;        
}

proc ::tclfpdf::SetTitle { title1 } {
	variable metadata;
	;# Title of document
	set metadat(title) $title1;
}

proc ::tclfpdf::SetSubject { subject1 } {
	;# Subject of document
	variable metadata;
	set metadata(subject) $subject1;
}

proc ::tclfpdf::SetAuthor { author1 } {
	;# Author of document
	variable metadata;
	set metadata(author) $author1;
}

proc ::tclfpdf::SetKeywords { keywords1 } {
	;# Keywords of document
	variable metadata;
	set metadata(keywords) $keywords1;
}

proc ::tclfpdf::SetCreator { creator1 } {
	;# Creator of document
	variable metadata;
	set  metadata(creator) $creator1;
}

proc ::tclfpdf::AliasNbPages { {alias "%nb%"} } {
	;# Define an alias for total number of pages
	variable AliasNbPages;	
	set AliasNbPages  $alias;
}

proc ::tclfpdf::Error { msg } {
	;# Fatal error	
	variable TraceAfterError;
	set mode "std"; 
	;#Disable if necessary and set mode according
	if {[string match *wish* [file tail [info nameofexecutable] ]]}  {
		set mode "gui";
	}
	switch -- $mode {
		gui {			
		        tk_messageBox -icon error -message $msg -title "TCLFPDF error";
		}
		std  {
		        puts "TCLFPDF error: $msg";
		}
	}
	if { [info exists ::tclfpdf::TraceAfterError] ==0  || $TraceAfterError == 0 } {
		exit
	} else {
		return -code error $msg
	}	
}

proc ::tclfpdf::Close { } {
	variable page; variable state;variable InFooter;
	;# Terminate document
	if {$state==3} {
		return;
	}	
	if {$page==0} {
		AddPage;
	}	
	;# Page footer
	set InFooter  1;
	if {[namespace which -command Footer] ne "" } {
		Footer;
	}	
	set InFooter  0;
	;# Close page
	 _endpage ;
	;# Close document
	_enddoc ;
}

proc ::tclfpdf::AddPage { {orientation ""} {size ""}  {rotation 0}} {
	variable state; variable FontFamily; variable underline; variable FontSizePt;
	variable LineWidth; variable DrawColor; variable FillColor; variable TextColor;
	variable ColorFlag; variable page;variable k;variable FontStyle; variable InHeader;
	variable InFooter;
	;# Start a new page
	if { $state==3}  {
		Error "The document is closed";
	}	
	set family $FontFamily;
	if {$underline == 1} {
		set underlined "U"
	} else {
		set underlined "";
	}
	set style  "$FontStyle$underlined";
	set fontsize $FontSizePt;
	set lw  $LineWidth;
	set dc  $DrawColor;
	set fc  $FillColor;
	set tc  $TextColor;
	set cf  $ColorFlag;
	if { $page>0} {
		;# Page footer
		set InFooter  1;
		if {[namespace which -command Footer] ne "" } {
			Footer;
		}	
		set InFooter  0;
		;# Close page
		_endpage;
	}
	;# Start new page
	_beginpage $orientation $size $rotation;
	;# Set line cap style to square
	_out "2 J";
	;# Set line width
	set LineWidth  $lw;
	_out [format "%.2f w" [expr $lw*$k]];
	;# Set font
	if {$family !=""} {
		SetFont $family $style $fontsize;
	}        
	;# Set colors
	set DrawColor  $dc;
	if {$dc !="0 G"} {
		_out $dc;
	}        
	set FillColor  $fc;
	if {$fc !="0 g"} {
		 _out $fc;
	}
	set TextColor  $tc;
	set ColorFlag  $cf;
	;# Page header
	set InHeader  1;
	if {[namespace which -command Header] ne "" } {
		Header;
	}	
	set InHeader  0;
	;# Restore line width
	if { $LineWidth!=$lw} {
		set LineWidth $lw;
		_out [format "%.2f w" [expr $lw*$k]];
	}
	;# Restore font
	if {$family!=""} {
		SetFont $family $style $fontsize;
	}        
	;# Restore colors
	if { $DrawColor!=$dc} {
		set DrawColor  $dc;                
		_out  $dc;
	}
	if { $FillColor!=$fc} {
		set FillColor  $fc;
		_out $fc;
	}
	set TextColor  $tc;
	set ColorFlag  $cf;
}

;# proc ::tclfpdf::Header { } {
	;# To be implemented in your own proc
;# }

;# proc ::tclfpdf::Footer { } {
	;# To be implemented in your own proc
;# }

proc ::tclfpdf::PageNo { } {
	;# Get current page number
	variable page;
	return $page;
}

proc ::tclfpdf::SetDrawColor { r {g ""} {b ""}  } {
	variable page; variable DrawColor;
	;# Set color for all stroking operations
	if {($r==0 && $g==0 && $b==0) || $g==""} {
		set DrawColor [format "%.3f G" [expr $r/255.00]];
	} else {
		set DrawColor [format "%.3f %.3f %.3f RG" [expr $r/255.00] [expr $g/255.00] [expr $b/255.00]];
	}	
	if { $page>0} {
		_out $DrawColor;
	}
}

proc ::tclfpdf::SetFillColor { r  {g ""} {b ""} } {
	variable FillColor; variable page; variable TextColor;variable ColorFlag;
	;# Set color for all filling operations
	if { ($r==0 && $g==0 && $b==0) || $g==""} {
		set FillColor  [format "%.3f g" [expr $r/255.00]];
	} else {
		set FillColor  [format "%.3f %.3f %.3f rg" [expr $r/255.00] [ expr $g/255.00] [ expr $b/255.00]];
	}	
	set ColorFlag [ expr {$FillColor !=$TextColor} ];
	if { $page >0 } {
		_out $FillColor;
	}	
}

proc ::tclfpdf::SetTextColor { r  {g ""} {b ""} } {
	variable TextColor; variable ColorFlag;variable FillColor;
	;# Set color for text
	if { ($r==0 && $g==0 && $b==0) || $g==""} {
		set TextColor  [format "%.3f g" [expr $r/255.00]];
	} else {
		set TextColor  [format "%.3f %.3f %.3f rg" [expr $r/255.00] [expr $g/255.00] [expr $b/255.00]];
	}	
	set ColorFlag [expr {$FillColor!=$TextColor} ]
}

proc ::tclfpdf::GetStringWidth { s } {
	variable page; variable CurrentFont; variable FontSize; variable unifontSubset;
	;# Get width of a string in the current font
	set cw [ _getList2Arr $CurrentFont cw];
	set CurrentFont_desc [_getList2Arr $CurrentFont desc]
	set CurrentFont_MW [_getList2Arr $CurrentFont MissingWidth]
	set w  0;
	if  { $unifontSubset == 1 } {
		set unicode [_UTF8StringToArray $s];
		foreach char $unicode {
			if { [_getchar $cw [expr 2*$char]] ne "" } {
				set w [expr $w+ ([scan [_getchar $cw [expr 2*$char]] %c] << 8) + [scan [_getchar $cw [expr 2*$char+1]] %c ]]; 
			} elseif { $char>0 && $char<128 && [ _getchar $cw [format %c $char]] ne "" } { 
				set w [expr $w + [_getchar $cw [format %c $char]]];
			} elseif { [isset CurrentFont_desc)] && [MissingWidth in $CurrentFont_desc]} {
				set mw  [lindex $CurrentFont_desc [lsearch $CurrentFont_desc MissingWidth ] ];
				set w [expr $w+ $mw];
			} elseif  { [isset CurrentFont_MW)]}  { 
				set w [expr $w+ $CurrentFont_MW]; 
			} else { 
				set w [expr $w+ 500];
			}
		}
	} else {
		set l  [string  length  $s];
		for { set i 0} {$i<$l} {incr i} {
			set w [expr $w + [_findchar $cw [_getchar $s $i]]];
		}
	}	
	return  [expr $w*$FontSize/1000.00];
}
proc ::tclfpdf::SetLineWidth { width } {
	variable page; variable LineWidth;variable k;
	;# Set line width
	set LineWidth $width;
	if { $page>0 } {
		_out [format "%.2f w" [expr $width*$k]];
	}	
}

proc ::tclfpdf::Line { x1 y1 x2 y2 } {
	variable k; variable h;
	;# Draw a line
	_out [format "%.2f %.2f m %.2f %.2f l S" [expr $x1*$k] [expr ($h-$y1)*$k] [expr $x2*$k] [expr ($h-$y2)*$k]];
}

proc ::tclfpdf::Rect { x1 y1 w1 h1 {style "" } } {
	variable k; variable h;
	;# Draw a rectangle
	if {$style=="F"} {
		set op  "f";
	} elseif {$style=="FD" || $style=="DF"} {
		set op  "B";
	} else {
		set op  "S";
	}
	_out [format "%.2f %.2f %.2f %.2f re %s" [expr $x1*$k] [expr ($h-$y1)*$k] [expr $w1*$k] [expr -$h1*$k] $op ];
}

proc ::tclfpdf::AddFont { family {style ""} {file ""} {uni 0}} {
	variable fonts; variable FontFiles; variable AliasNbPages; variable TCLFPDF_USERPATH; variable TCLFPDF_COREFONTPATH;
	;# Add a TrueType, OpenType or Type1 font
	set family [string tolower $family];
	set style [string toupper $style];
	if {$style=="IB"} {
		set style "BI";
	} 
	if {$file==""} {
		set ffamily [string map {" " ""} $family];
		set fstyle [string tolower $style];
		if {$uni} {
			set file  "$ffamily$fstyle.ttf";
		} else {
			set file  "$ffamily$fstyle.tcl";
		}
	} else {
		set ext [file extension $file]
		if {$uni } {
			if {$ext ne ".ttf"} {
				Error "Expecting .tff file but got \"$ext\" extension"
			} 
		} else {
			if {$ext ne ".tcl"} {
				Error "Expecting .tcl (font definition) but got \"$ext\" file"
			} 
		}
	}
	set fontkey  "$family$style";
	if {[isset fonts($fontkey)]} {
		return;
	}
	if  {$uni } {	
		set ttffilename [_SearchPathFile $file];
		set unifilename "$TCLFPDF_USERPATH/[string tolower [file rootname $file]]";
		set name "";
		set originalsize 0;
		file stat $ttffilename ttfstat;
		if { [file exists $unifilename.mtx.tcl]} {
			source -encoding utf-8 $unifilename.mtx.tcl;
		}
		if {! [isset type] ||  ![isset name] || $originalsize != $ttfstat(size)} {
			set ttffile $ttffilename;
			source -encoding utf-8 "$TCLFPDF_COREFONTPATH/ttf_font.tcl";
			ttf_Init;
			ttf_getMetrics $ttffile;
			set long [array size ttf_charWidths];
			for {set x 0}  {$x <  $long} {incr x} {
				append cw $ttf_charWidths($x);
			}
			set name [ string map { \[ {} \( {} \) {} \] {} } $ttf_fullName];
			array set desc [list "Ascent" [expr round($ttf_ascent)] "Descent" [expr round($ttf_descent)] "CapHeight" [expr round($ttf_capHeight)] "Flags" $ttf_flags "FontBBox" "\[ [expr round($ttf_bbox(0))] [expr round($ttf_bbox(1))] [expr round($ttf_bbox(2))] [expr round($ttf_bbox(3))] \]" "ItalicAngle" $ttf_italicAngle "StemV" [expr round($ttf_stemV)] "MissingWidth" [expr round($ttf_defaultWidth)]];
			set up [expr round($ttf_underlinePosition)];
			set ut [expr round($ttf_underlineThickness)];
			set originalsize  [expr $ttfstat(size)+0 ];# 0? sic
			set type  "TTF";
			;#Generate metrics .tcl file
			append s "set name \"$name\" ;\n";
			append s "set type \"$type\";\n";
			append s "array set desc {[array get desc]};\n";
			append s "set up $up;\n";
			append s "set ut $ut;\n";
			append s "set ttffile \"$ttffile\";\n";
			append s "set originalsize $originalsize;\n";
			append s "set fontkey \"$fontkey\";\n";
			if {[catch {open "$unifilename.mtx.tcl" "wb" } fh ]} {
				Error "Can't open file: $unifilename.mtx.tcl";
			}
			puts  -nonewline $fh $s ;#[string length $s];
			close $fh;
			if {[catch {open "$unifilename.cw.dat" "wb" } fh ]} {
				Error "Can't open file: $unifilename.cw.dat";
			}
			puts  -nonewline $fh $cw;#[string length $cw];
			close $fh;
		} else {
			if {[catch {open "$unifilename.cw.dat" "rb" } fcw ]} {
				Error "Can't open file: $unifilename.cw.dat";
			}
			set cw [read $fcw [file size $unifilename.cw.dat]];
			close $fcw;
		}
		set i [expr [array size fonts] +1];
		set j -1;
		if { $AliasNbPages != ""} {
			;#range(0,57)
			while (1) {
				lappend sbarr [incr j] ;
				if {$j==57} break;
			}	
		} else {
			;#range(0,32);
			while (1) {
				lappend sbarr [incr j] ;
				if {$j==32} break;
			}
		}
		set fonts($fontkey) [list "i" $i  "type" $type  "name" $name  "desc" [array get desc]  "up" $up  "ut" $ut  "cw" $cw "ttffile" $ttffile  "fontkey" $fontkey  "subset" $sbarr  "unifilename" $unifilename];
			
		set FontFiles($fontkey) [list "length1" $originalsize "type" "TTF" "ttffile" $ttffile];
		set FontFiles($file)  "type TTF";
		unset cw;		
	} else {
		array set info [ _loadfont $file];
		set i [expr [array size fonts]+1];
		set info(i) $i;
		if {[isset info(file) 0]} {
			;# Embedded font
			if {$info(type)=="TrueType"} {
				set FontFiles($info(file)) [list length1 $info(originalsize)];
			} else {
				set FontFiles($info(file)) [list length1 $info(size1) length2 $info(size2)];
			}
		}
		set fonts($fontkey) [array get info];
	}
}

proc ::tclfpdf::SetFont { family {style ""} {size 0} } { 
	variable FontFamily; variable underline;variable fonts; variable k; variable CurrentFont;
	variable CoreFonts;variable page; variable FontSize; variable FontSizePt; variable FontStyle;
	variable unifontSubset;
	;# Select a font; size given in points
	if {$family==""} {
		set family  $FontFamily;
	} else {
		set family [string tolower $family];
	}        
	set style  [string toupper $style];
	if {[string first "U" $style] !=-1} {
		set underline  1;
		set style [string map {"U" ""} $style];
	} else {
		set underline  0;
	}        
	if {$style=="IB"} {
		set style  "BI";
	}        
	if {$size==0} {
		set size  $FontSizePt;
	}        
	;# Test if font is already selected
	if { $FontFamily==$family && $FontStyle==$style && $FontSizePt==$size} {
		return;
	}        
	;# Test if font is already loaded
	set fontkey  "$family$style";
	if {[lsearch [array names fonts]  $fontkey ] ==-1} {
		;# Test if one of the core fonts
		if {$family=="arial"} {
		        set family "helvetica";
		}        
		if {[lsearch $CoreFonts $family]!=-1} {
		        if {$family=="symbol" || $family=="zapfdingbats"} {
		                set style  "";
		        }        
		        set fontkey  "$family$style";
		        if {[lsearch [array names fonts]  $fontkey ] ==-1} {
			
		                 AddFont $family $style;
		        }        
		} else {
		        Error "Undefined font: $family $style";
		}        
	}
	;# Select it
	set FontFamily  $family;
	set FontStyle  $style;
	set FontSizePt  $size;
	set FontSize  [expr $size/$k];
	upvar 0 fonts($fontkey) ::tclfpdf::CurrentFont;
	
	if {[ _getList2Arr $fonts($fontkey) type]=="TTF"} { 
		set unifontSubset  1;
	} else { 
		set unifontSubset 0;
	}
	if {$page>0} {
		_out [format "BT /F%d %.2f Tf ET" [_getList2Arr $::tclfpdf::CurrentFont i] $FontSizePt];
	}        
}

proc ::tclfpdf::SetFontSize {size} {
	;# Set font size in points
	variable FontSize;variable page;variable k;variable FontSizePt; variable CurrentFont;	
	if { $FontSizePt==$size} {
		return;
	}	
	set FontSizePt  $size;
	set FontSize  [expr $size/$k];
	if { $page>0} {
		_out [format "BT /F%d %.2f Tf ET" [_getList2Arr $CurrentFont i ]  $FontSizePt];
	}	
}

proc ::tclfpdf::AddLink { } {
	;# Create a new internal link
	variable links;
	set n [expr [array size links] +1];
	array set links [list $n {}];
	return $n;
}

proc ::tclfpdf::SetLink { link  {y1 {0}} {page1 {-1}}} {
	;# Set destination of internal link
	variable links; variable y; variable page;
	if {$y1 == -1} {
		set y1 $y;
	}	
	if {$page1 == -1} {
		set page1 $page;
	}	
	array set links [list $link  [list $page1 $y1]];
}

proc ::tclfpdf::Link { x y w h link} {
	;# Put a link on the page
	variable PageLinks; variable page; variable k; variable hPt;
	set nl 0
	set i 0
	while (1) {
	      	if {[array names PageLinks -exact $page,$i ] eq {}} {
		    set nl $i;
		    break;	
		} else {
		   incr i;
		}
	}
	set PageLinks($page,$nl)  [list  [expr $x*$k] [expr $hPt-$y*$k]  [expr $w*$k] [expr $h*$k] $link];
}

proc ::tclfpdf::Text {x  y txt } {
	;# Output a string
	variable k; variable h; variable underline; variable ColorFlag;
	variable unifontSubset; variable CurrentFont; variable fonts;
	if {![isset CurrentFont]} {
		Error "No font has been set";
	}		
	if {$unifontSubset == 1} {
		set txt2 "([_escape [_UTF8toUTF16BE $txt 0]])";
		foreach  uni [_UTF8StringToArray $txt] {
			if {$uni ni [_getList2Arr $CurrentFont subset]} {
				_setSubList CurrentFont subset $uni;
			}
		}
	} else { 
		set txt2 "([_escape $txt])";
	}	
	set s  [format "BT %.2f %.2f Td %s Tj ET" [expr $x*$k] [expr ($h-$y)*$k] $txt2];
	if { $underline == 1 && $txt!="" } {
		append s " [_dounderline $x $y $txt]";
	}	
	if { $ColorFlag == 1 } {
		set s  "$q $TextColor $s $Q";
	}	
	_out $s;
}

proc ::tclfpdf::AcceptPageBreak { } {
	variable AutoPageBreak;	
	;# Accept automatic page break or not
	return $AutoPageBreak;
}

proc ::tclfpdf::Cell {w1 {h1 0} {txt ""} {border 0} {ln 0} {align ""} {fill 0} {link ""}} {
	variable k;variable y;variable InFooter;variable InHeader;variable h;
	variable x; variable ws; variable rMargin; variable cMargin; variable PageBreakTrigger;
	variable ColorFlag;variable TextColor;variable lasth; variable w; variable FontSize;
	variable underline;variable lMargin;variable CurOrientation; variable CurPageSize;
	variable CurRotation; variable unifontSubset; variable CurrentFont; variable fonts;
	;# Output a cell
	set k1  $k;
	if { [expr $y+$h1] >$PageBreakTrigger && !$InHeader && !$InFooter && [AcceptPageBreak] } {
		;# Automatic page break
		set x1 $x;
		set ws1 $ws;
		if {$ws1>0} {
		        set ws  0; 
		        _out "0 Tw";
		}
		AddPage $CurOrientation $CurPageSize $CurRotation;
		set x  $x1;
		if {$ws1>0} {
		        set ws  $ws1; 
		        _out [format "%.3f Tw" [expr $ws1*$k1]];
		}
	}
	if {$w1==0} {
		set w1  [expr  $w-$rMargin-$x];
	}	
	set s  "";
	if {$fill !=0  || $border==1} {
		if {$fill !=0} {
		        set op [expr {$border==1 ? "B" : "f"}];
		} else {
		        set op  "S";
		}
		set s  [format "%.2f %.2f %.2f %.2f re %s " [expr $x*$k1] [expr ($h-$y)*$k1] [expr $w1*$k1] [expr -$h1*$k1] $op];
	}
	if {[string is alpha $border]} {
		set x1  $x;
		set y1  $y;
		if {[string first "L" $border]!=-1} {
		        append s [format  "%.2f %.2f m %.2f %.2f l S " [expr $x1*$k1] [expr ($h-$y1)*$k1] [ expr $x1*$k1] [expr ($h-($y1+$h1))*$k1]];
		}	
		if {[string first "T" $border]!=-1} {
			append s [format "%.2f %.2f m %.2f %.2f l S " [expr $x1*$k1] [expr ($h-$y1)*$k1] [expr ($x1+$w1)*$k1] [expr ($h-$y1)*$k1] ];
		}	
		if {[string first "R" $border]!=-1} {
		        append s [format "%.2f %.2f m %.2f %.2f l S " [expr ($x1+$w1)*$k1] [ expr ($h-$y1)*$k1] [ expr ($x1+$w1)*$k1] [ expr ($h-($y1+$h1))*$k1]];
		}	
		if {[string first "B" $border]!=-1} {
		        append s [format  "%.2f %.2f m %.2f %.2f l S " [expr $x1*$k1] [expr ($h-($y1+$h1))*$k1] [expr ($x1+$w1)*$k1] [expr ($h-($y1+$h1))*$k1]];
		}	
	}
	if {$txt != ""} {
		if {![isset CurrentFont]} {
			Error " No font has been set";
		}
		if {$align=="R"} {
		        set dx [expr $w1-$cMargin- [GetStringWidth $txt]];
		} elseif {$align=="C"} {
		        set dx [expr ($w1-[GetStringWidth $txt ])/2.00];
		} else {
		        set dx $cMargin;
		}	
		if {$ColorFlag ==1 } {
		        append s " q $TextColor ";
		}
		#If multibyte, Tw has no effect - do word spacing using an adjustment before each space
		if {$ws !=0 && $unifontSubset ==1} {
			foreach uni [_UTF8StringToArray $txt] {
				if {$uni ni [_getList2Arr $CurrentFont subset]} {
					_setSubList CurrentFont subset $uni;
				}
			}
			set space [_escape [_UTF8toUTF16BE " " 0]];
			append s [format "BT 0 Tw %.2f %.2f Td \[" [expr ($x+$dx)*$k] [expr $h-($y+.5*$h1+.3*$FontSize)*$k]];
			set t [split $txt ];
			set numt [llength $t];
			for {set i 0} {$i<$numt} {incr i} {
				set tx [lindex $t $];
				set tx  "([_escape [_UTF8toUTF16BE $tx 0]])";
				append s [format "%s" $tx];
				if { ($i+1)<$numt} {
					set adj [expr  -($w*$k)*1000.00/$FontSizePt];
					append s [format "%d(%s) " $adj $space];
				}
			}
			append s "\] TJ";
			append s  " ET";
		} else {
			if {$unifontSubset==1} {
				set txt2 "([_escape [_UTF8toUTF16BE $txt 0]])";
				foreach uni [_UTF8StringToArray $txt] {
					if {$uni ni [_getList2Arr $CurrentFont subset]} {
						_setSubList CurrentFont subset $uni;
					}	
				}
			} else {
				set txt2 "([ _escape $txt])";
			}
			append s [format "BT %.2f %.2f Td %s Tj ET" [expr ($x+$dx)*$k] [expr ($h-($y+.5*$h1+.3*$FontSize))*$k] $txt2];
		}
		if {$underline == 1} {
		        append  s " [_dounderline [expr $x+$dx] [ expr $y+0.5*$h1+0.3*$FontSize] $txt]";
		}	
		if {$ColorFlag == 1} {
		        append s " Q";
		}	
		if {$link!=""} {
		        Link [expr $x+$dx] [expr $y+0.5*$h1-0.5*$FontSize] [GetStringWidth $txt ] $FontSize $link;
		}	
	}
	if {$s!=""} {
		_out $s;
	}	
	set lasth $h1;
	if {$ln>0} {
		;# Go to next line
		set y [expr $y+$h1];
		if {$ln==1} {
		        set x $lMargin;
		}	
	} else {
		set x [expr $x+$w1];
	}
}

proc ::tclfpdf::MultiCell {w1 h1 txt {border 0} {align "J"} {fill 0}} {
	variable CurrentFont; variable v; variable rMargin; variable x; variable w; variable unifontSubset;
	variable FontSize;variable cMargin; variable ws; variable h; variable lMargin; variable k; variable TAB;
	;# Output text with automatic or explicit line breaks
	if {![isset CurrentFont]} {
		Error "No font has been set";
	}
	set cw  [_getList2Arr $CurrentFont cw];
	if {$w1==0} {
		set w1  [expr $w-$rMargin-$x];
	}	
	set wmax  [expr ($w1-2*$cMargin)];
	set s  [string map [list \r "" \t $TAB] $txt];
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
	set b 0;
	if {$border!=0} {
		if {$border==1} {
		        set border "LTRB";
		        set b "LRT";
		        set b2 "LR";
		} else {
		        set b2  "";
		        if {[string first "L" $border]!=-1} {
		                append b2  L;
			}	
		        if {[string first "R" $border]!=-1} {
		                append b2 R;
			}	
		        if {[string first "T" $border]!=-1} {
		                append b  T; 
			} else {
		                set b $b2;
			}	
		}
	}
	set sep -1;
	set i  0;
	set j  0;
	set l  0;
	set ns  0;
	set nl  1;
	while {$i<$nb} {
		;# Get next character
		if {$unifontSubset==1} {
			set c [utf8substr $s $i 1 ];
		} else {	
			set c [string index $s $i];
		}	
		if {$c=="\n"} {
		        ;# Explicit line break
		        if { $ws>0} {
		                set ws  0;
		                _out "0 Tw";
		        }
			Cell $w1 $h1 [ utf8substr $s $j [expr $i-$j]] $b 2 $align $fill;
		        incr i;
		        set sep -1;
		        set j  $i;
		        set l  0;
		        set ns  0;
		        incr nl;
		        if {$border !=0 && $nl==2} {
		                set b $b2;
			}	
		        continue;
		}
		if {$c==" "} {
		        set sep $i;
		        set ls $l;
		        incr ns;
		}
		if {$unifontSubset==1} { 
			set l [expr $l + [GetStringWidth $c]];
		} else {
			set l [expr $l + ([_findchar $cw $c]*$FontSize/1000)];
		}
		if {$l>$wmax } {
		        ;# Automatic line break
		        if {$sep==-1} {			
		                if {$i==$j} {
					incr i;
				}	
		                if { $ws>0} {
		                        set ws  0;
		                        _out "0 Tw";
		                }
		                Cell $w1 $h1 [utf8substr $s $j [expr $i-$j]] $b 2 $align $fill;
		        } else {			
		                if {$align=="J"} {
		                        set ws  [expr {($ns>1) ? ($wmax-$ls)/($ns-1) : 0}];
		                        _out [format "%.3f Tw" [expr $ws*$k]];
		                }
		                Cell $w1 $h1 [utf8substr $s $j [expr $sep-$j]] $b 2 $align $fill;
		                set i  [expr $sep + 1];
		        }			
		        set sep  -1;
		        set j  $i;
		        set l  0;
		        set ns  0;
		        incr nl;
		        if {$border!=0 && $nl==2} {
		                set b $b2;
			}	
		} else {
		        incr i;
		}	
	}
	;# Last chunk
	if { $ws>0} {
		set ws  0;
		_out "0 Tw";
	}
	if {$border!=0 && [string first "B" $border]!=-1} {
		append b "B";
	}
	Cell $w1 $h1 [utf8substr $s $j [expr $i-$j]] $b 2 $align $fill;
	set x $lMargin;
}

proc ::tclfpdf::Write { h1 txt {link "" }} {
	variable CurrentFont; variable w; variable rMargin; variable lMargin;
	variable x; variable FontSize; variable cMargin; variable y; variable unifontSubset;
	variable TAB;
	;# Output text in flowing mode
	if {![isset CurrentFont]} {
		Error "No font has been set";
	}
	set cw  [_getList2Arr $CurrentFont cw];
	set w1  [expr $w-$rMargin-$x];
	set wmax  [expr ($w1-2*$cMargin)];
	set s  [string map [list \r "" \t $TAB] $txt];
	if {$unifontSubset==1} {
		set nb [utf8len $s];
		if {$nb==1 && $s==" "} {
			set x [expr $x + [GetStringWidth $s]];
			return;
		}
	} else {
		set nb  [ string length $s ];
	}
	set sep  -1;
	set i  0;
	set j  0;
	set l  0;
	set nl  1;
	while {$i<$nb} {
		;# Get next character
		set c [utf8substr $s $i 1];
		if {$c=="\n"} {
		        ;# Explicit line break
		        Cell $w1 $h1 [ utf8substr $s $j [expr $i-$j] ] 0 2 "" 0 $link;
		        incr i;
		        set sep  -1;
		        set j  $i;
		        set l  0;
		        if {$nl==1} {
		                set x  $lMargin;
		                set w1  [expr $w-$rMargin-$x];
		                set wmax [expr ($w1-2*$cMargin)];
		        }
		        incr nl;
		        continue;
		}
		if {$c==" "} {
		        set sep  $i;
		}
		if {$unifontSubset==1} { 
			set l [expr $l + [GetStringWidth $c]];
		} else {
			set l [expr $l + ([_findchar $cw $c]*$FontSize/1000)];
		}
		if {$l>$wmax} {
		        ;# Automatic line break
		        if {$sep==-1} {
		                if { $x>$lMargin} {
		                        ;# Move to next line
		                        set x  $lMargin;
		                        set y [expr $y+ $h1];
		                        set w1 [expr $w-$rMargin-$x];
		                        set wmax  [expr ($w-2*$cMargin)];
		                        incr i;
		                        incr nl;
		                        continue;
		                }
		                if {$i==$j} {
		                        incr i;
				}	
		                Cell $w1 $h1 [utf8substr $s $j [expr $i-$j ]] 0 2 "" 0 $link;
		        } else {
		                Cell $w1 $h1 [utf8substr $s $j [expr $sep-$j ]] 0 2 "" 0 $link;
		                set i [expr $sep+1];
		        }
		        set sep  -1;
		        set j  $i;
		        set l  0;
		        if {$nl==1} {
		                set x  $lMargin;
		                set w1  [expr $w-$rMargin-$x];
		                set wmax [expr ($w1-2*$cMargin)];
		        }
		        incr nl;
		} else {
		        incr i;
		}	
	}
	;# Last chunk
	if {$i !=$j} {
		Cell $l $h1 [ utf8substr $s $j ] 0 0 "" 0 $link;
	}
}

proc ::tclfpdf::Ln { {h ""} } {
	variable lMargin;variable y; variable lasth;variable x;	
	;# Line feed; default value is the last cell height
	set x $lMargin;
	if {$h==""} {
		set y [ expr $y+ $lasth];
	} else {
		set y [expr $y+$h];
	}	
}

proc ::tclfpdf::Image { file { x1 "" } { y1 "" } { w1 "" } { h1  "" }  { type1 "" } { link1 "" } } {
	variable images; variable k; variable y; variable x; variable Link;variable h;
	variable PageBreakTrigger; variable InHeader; variable InFooter;
	variable CurOrientation; variable CurPageSize; variable CurRotation

	if {$w1 eq {}} {
		set w1 0
	}
	if {$h1 eq {}} {
		set h1 0
	}
	
	;# Put an image on the page
	set file1 [file tail $file];
	if {$file1 == ""} {
		Error "Image file name is empty";
	}
	if {[lsearch [array names images] $file1 ] ==-1}	{
		;# First use of this image, get info
		if {$type1==""} {
		        set pos [string last "." $file1];
		        if {$pos==-1} {
		                Error "Image file has no extension and no type was specified: $file";
			}	
		        set type1 [_substr $file1 [expr $pos+1] ];
		}
		set type1 [string tolower $type1];
		if {$type1=="jpeg"} {
		        set type1 "jpg";
		}	
		set mtd  "_parse$type1";
		if {[lsearch [info procs] $mtd] == -1} {
		        Error "Unsupported image type: $type1";
		}
		array set info [$mtd $file];
		array set info "i  [expr [array size images]+1]";
		set imagesl [ list [array get info]];
		array set images "$file1 $imagesl";
	} else {
		array set info $images($file1);
	}	
	;# Automatic width and height calculation if needed
	if {$w1==0 && $h1==0}	{
		;# Put image at 96 dpi
		set w1  -96;
		set h1  -96;
	}
	if {$w1<0} {
		set w1 [expr -$info(w)*72/$w1/$k];
	}	
	if {$h1<0} {
		set h1 [expr -$info(h)*72/$h1/$k];
	}	
	if {$w1==0} {
		set w1  [expr $h1*$info(w)/$info(h)];
	}	
	if {$h1==0} {
		set h1  [expr $w1*$info(h)/$info(w)];
	}	
	;# Flowing mode
	if {$y1==""} {
		if { [expr $y+$h1]>$PageBreakTrigger && !$InHeader && !$InFooter && [AcceptPageBreak] } {
		        ;# Automatic page break
		        set x2  $x;
		        AddPage $CurOrientation $CurPageSize $CurRotation;
		        set x  $x2;
		}
		set y1  $y;
		set y [expr $y+$h1];
	}
	if {$x1==""} {
		set x1 $x;
	}	
	_out [format "q %.2f 0 0 %.2f %.2f %.2f cm /I%d Do Q" [expr $w1*$k] [expr $h1*$k] [expr $x1*$k] [expr ($h-($y1+$h1))*$k] $info(i) ];
	if {$link1!=""} {
		Link $x1 $y1 $w1 $h1 $link1;
	}	
}

proc ::tclfpdf::GetPageWidth {} {
	variable w;
	return $w;
}

proc ::tclfpdf::GetPageHeight {} {
	variable h;
	return $h;
}

proc ::tclfpdf::GetX { } {
	;# Get x position
	variable x;
	return $x;
}

proc ::tclfpdf::SetX { x1 } {
	;# Set x position
	variable x; variable w;
	if {$x1 >=0} {
		set x  $x1;
	} else {
		set x  [expr $w+$x1];
	}	
}

proc ::tclfpdf::GetY { } {
	;# Get y position
	variable y;
	return $y;
}

proc ::tclfpdf::SetY { y1 {resetX 1 }} {
	;# Set y position and optionally reset x
	variable lMargin; variable y; variable x; variable h;	
	if {$y1 >=0} {
		set y $y1;
	} else {	
		set y [expr $h+$y1];
	}
	if {$resetX } {
		set x $lMargin;
	}
}

proc ::tclfpdf::SetXY { x1 y1 } {
	;# Set x and y positions
	SetX $x1;
	SetY $y1 0;

}

proc ::tclfpdf::Output { {name "" } { dest "" } } {
	variable state; variable buffer;
	;# Output PDF to some destination
	Close;
	set dest  [string toupper $dest];
	if {$dest==""}	{
		if {$name==""} {
			set name "doc.pdf";
		}	
	        set dest  "F";
	}
	switch $dest {
		"F"	{
			;# Save to local file
		        if { [catch {open $name "wb"} f] } {
				Error "Can't save file $name"
			};
		        puts -nonewline $f $buffer;
		        close $f ;
			}
		"S"
			{
		        ;# Return as a string
		        return $buffer;
			}
		default
			{
		        Error "Incorrect output destination: $dest";
			}
	}
	return "";
}

proc ::tclfpdf::_getpagesize {size} {
	variable StdPageSizes; variable k;

	if {[string is wordchar $size]} {
		set size [string tolower $size ];
		if { [lsearch [array names StdPageSizes] $size] == -1} {
		        Error "Unknown page size: $size";
		}	
		set s $StdPageSizes($size);
		set a  [expr [lindex $s 0]/$k];
		set b [expr [lindex $s 1]/$k];
		set lreturn [list $a $b];
	} else {
		set a [lindex $size 0];
		set b [lindex $size 1];
		if { $a > $b } {
			set lreturn [list $b $a ];
		} else {
			set lreturn [list $a $b ];
		}
	}	
	return $lreturn;
}

proc ::tclfpdf::_beginpage { orientation size rotation} {
	variable page; variable pages;variable PageLinks; variable state;
	variable lMargin; variable tMargin; variable bMargin;
	variable FontFamily; variable PageSizes;
	variable DefOrientation; variable DefPageSize;variable CurOrientation;
	variable CurPageSize; variable x;variable y;variable w; variable h; variable k;
	variable wPt; variable hPt; variable PageBreakTrigger;
	variable CurRotation;
	
	incr page;
	set pages($page) {};
	set PageLinks($page) {};
	set state  2;
	set x $lMargin;
	set y $tMargin;
	set FontFamily  "";
	;# Check page size and orientation
	if {$orientation==""} {
		set orientation $DefOrientation;
	} else {
		set orientation [string toupper [string index $orientation 0]];
	}        
	if {$size==""} {
		set size $DefPageSize;
	} else {
		set size [_getpagesize $size];
	}        
	if {$orientation!=$CurOrientation || [lindex $size 0]!=[lindex $CurPageSize 0] || [lindex $size 1]!=[lindex $CurPageSize 1]} {
		;# New size or orientation
		if {$orientation=="P"} {
		        set w  [lindex $size 0];
		        set h   [lindex $size 1];
		} else {
		        set w  [lindex $size 1];
		        set h  [lindex $size 0];
		}
		set wPt [expr $w*$k];
		set hPt [expr $h*$k];
		set PageBreakTrigger [expr $h-$bMargin];
		set CurOrientation  $orientation;
		set CurPageSize  $size;
	}
	if {$orientation!=$DefOrientation || [lindex $size 0]!=[lindex $DefPageSize 0] || [lindex $size 1]!= [lindex $DefPageSize 1]} {
		set PageInfo($page,size) [list $wPt  $hPt];
	}
	if {$rotation!=0} {
		if {$rotation%90!=0} {
			Error "Incorrect rotation value: $rotation";
		}
		set PageInfo($page,rotation) $rotation;		
	}
	set CurRotation $rotation;
}

proc ::tclfpdf::_endpage { } {
	variable state;
	
	set state  1;
}

proc ::tclfpdf::_loadfont { font } {

	;# Load a font definition file from the font directory
	source -encoding utf-8 [_SearchPathFile $font];
	if {![isset name]} {
		Error "Could not include font definition file: $font";
	}
	if  {[isset enc] } {
		set enc [string tolower $enc];
	}
	if  {![isset subsetted] } {
		set subsetted 0;
	}
	foreach v [info locals] {
		if {$v=="font"} continue;
		if {[array exists $v] } {
			lappend l $v [array get $v];
		} else {
			lappend l $v [set $v];
		}
	}
	return $l;
}

proc ::tclfpdf::_escape { s } {
	;# Escape special characters in strings
	return [string map {
				"\\" "\\\\"
				"(" "\\("
				")" "\\)"
				"\r" "\\r"
				"\t" "\\t"
				} $s]
}

proc ::tclfpdf::_textstring { s } {
	;# Format a text string
	if {![string is ascii -strict $s] } {
		set s [_UTF8toUTF16BE $s 1];
	}
	return "([_escape $s])";
}

proc ::tclfpdf::_dounderline { x1 y1 txt } {
	;# Underline text
	variable CurrentFont; variable ws; variable k; variable h; variable FontSize; variable FontSizePt;
	set up  [_getList2Arr $CurrentFont up];
	set ut   [_getList2Arr $CurrentFont ut];
	set w1  [expr [GetStringWidth $txt]+$ws*[expr {[llength [split $txt " "]] - 1}]];
	return  [format "%.2f %.2f %.2f %.2f re f" [expr $x1*$k] [expr ($h-($y1-$up/1000.00*$FontSize))*$k] [expr $w1*$k] [expr -$ut/1000.00*$FontSizePt] ];
}

proc ::tclfpdf::_parsejpg { file } {
	;# Based on the method addJpeg of pdf4tcl 
        set imgOK false
        if {[catch {open $file "rb"} fr] } {
            Error "Can't open file $file"
        }
        set img [read $fr]
        close $fr
        binary scan $img "H4" h
        if {$h != "ffd8"} {
            Error "File $file doesn't contain JPEG data."
        }
        set pos 2
        set img_length [string length $img]
        while {$pos < $img_length} {
            set endpos [expr {$pos+4}]
            binary scan [string range $img $pos $endpos] "H4S" h length
            set length [expr {$length & 0xffff}]
            if {$h == "ffc0" || $h == "ffc2"} {
                incr pos 4
                set endpos [expr {$pos+6}]
                binary scan [string range $img $pos $endpos] "cSSc" bits height width channels
                set height [expr {$height & 0xffff}]
                set width [expr {$width & 0xffff}]
                set imgOK true
                break
            } else {
                incr pos 2
                incr pos $length
            }
        }
        if {!$imgOK} {
            Error "Something is wrong with jpeg data in file $file"
        } 	
	if {$channels ==3} {
		set colspace  "DeviceRGB"
	}  elseif {$channels==4} {
		set colspace "DeviceCMYK"
	} else {
		set colspace  "DeviceGray"
	}	
	if {$bits !=""} {
		set bpc  $bits
	} else { 
		set bpc 8
	}
	array set jpeg [ list w $width h $height cs $colspace bpc $bpc f DCTDecode data $img]
	return [array get jpeg]	
}

proc ::tclfpdf::_parsepng { file} {
	;# Extract info from a PNG file
	if {[catch {open $file "rb"} f]} {
		Error "Can't open image file: $file";
	}	
	set info [ _parsepngstream $f $file];
	close $f;
	return $info;
}

proc ::tclfpdf::_parsepngstream { f file } {
	variable PDFVersion; variable WithAlpha;
	;# Check signature
	if { [_readstream $f 8]!="[format %c 137]PNG[format %c 13][format %c 10][format %c 26][format %c 10]"} {
		Error "Not a PNG file: $file";
	}	
	;# Read header chunk
	_readstream $f 4;
	if { [_readstream $f 4] !="IHDR"} {
		Error "Incorrect PNG file: $file";
	}	
	set w [ _readint $f];
	set h  [ _readint $f];
	set bpc [scan [_readstream $f 1] %c];
	if {$bpc>8} {
		Error "16-bit depth not supported: $file";
	}	
	set ct [scan [_readstream $f 1] %c];
	if {$ct==0 || $ct==4} {
		set colspace  "DeviceGray";
	} elseif {$ct==2 || $ct==6} {
		set colspace  "DeviceRGB";
	} elseif {$ct==3} {
		set colspace  "Indexed";
	} else {
		Error "Unknown color type: $file";
	}	
	if {[scan [_readstream $f 1] %c] != 0} {
		Error "Unknown compression method: $file";
	}	
	if {[scan [_readstream $f 1] %c] != 0} {
		Error "Unknown filter method: $file";
	}	
	if {[scan [_readstream $f 1] %c] != 0} {
		Error "Interlacing not supported: $file";
	}	
	_readstream $f 4;
	if {$colspace=="DeviceRGB"} {
		set colspace1 3;
	} else {
		set colspace1 1;
	}	
	set dp  "/Predictor 15 /Colors $colspace1 /BitsPerComponent $bpc /Columns $w";
	;# Scan chunks looking for palette, transparency and image data
	set pal  "";
	set trns  "";
	set data  "";
	while {1} {
		set n  [_readint $f];
		set type  [_readstream $f 4];
		if {$type=="PLTE"} {
		        ;# Read palette
		        set pal [_readstream $f $n];
		        _readstream $f 4;
		} elseif {$type=="tRNS"} {
		        ;# Read transparency info
		        set t  [ _readstream $f $n];
		        if {$ct==0} {
		                array set trns  0 [scan [_substr $t 1 1 ] %c]
			} elseif {$ct==2} {
		                array set trns array [list [scan [_substr $t 1 1] %c] [scan [_substr $t 3 1] %c]  [scan [_substr $t 5 1] %c] ];
			} else {
		                set pos [ string first [format %c 0] $t];
		                if {$pos!=0} {
		                        set trns  array($pos);
				}	
		        }
		        _readstream $f 4;
		} elseif {$type=="IDAT"} {
		        ;# Read image data block
		        set data "$data[_readstream $f $n]";
		        _readstream $f 4;
		} elseif {$type=="IEND"} {
		        break;
		} else {
		        _readstream $f [expr $n+4];
		}
		if {!$n} break;
	} 
	if {$colspace=="Indexed" && $pal==""} {
		Error "Missing palette in  $file";
	}
	array set info [list w $w h $h cs $colspace bpc $bpc f FlateDecode dp $dp pal $pal trns $trns];
	if {$ct>=4} {
		;# Extract alpha channel
		set data  [zlib decompress $data];
		set color  "";
		set alpha  "";
		if {$ct==4} {
		        ;# Gray image
		        set len [expr 2*$w];
		        for {set i 0} {$i<$h} {incr i} {
		                set pos  [expr (1+$len)*$i];
		                set color "$color[string index $data $pos]";
		                set alpha "$alpha[string index $data $pos]";
		                set line  [_substr $data [expr $pos+1] $len];
		                append color [regexp "/(.)./s" $1 $line];
		                append alpha [regexp "/.(.)/s" $1 $line];
		        }
		} else  {
		        ;# RGB image
		        set len [expr 4*$w];
		        for {set i 0} {$i<$h} { incr i} {
		                set pos  [expr (1+$len)*$i];
		                set color "$color[string index $data $pos]";
		                set alpha "$alpha[string index $data $pos]";
		                set line [_substr $data [expr $pos+1] $len];
				set color1 [regsub -all "(.{3})." $line {\1}];
		                set color "$color$color1";
				set alpha1 [regsub -all ".{3}(.)" $line {\1}];
		                set alpha "$alpha$alpha1";				
		        }
		}
		unset data;
		set data [zlib compress $color];
		array set info "smask [list [zlib compress $alpha]]";
		set WithAlpha 1;
		if { $PDFVersion < "1.4" } {
			set PDFVersion  "1.4";
		}	
	}
	array set info [list data $data];
	return [array get info];
}

proc ::tclfpdf::_readstream {f n} {
	;# Read n bytes from stream
	set res  "";
	while {$n>0 && ![eof $f]} {
		set s [read $f $n];
		if {$s==0} {
		        Error "Error while reading stream";
		}	
		set n [expr $n-[string length $s]];
		append res $s;
	}
	if {$n>0} {
		Error "Unexpected end of stream";
	}	
	return $res;
}

proc ::tclfpdf::_readint { f } {
	;# Read a 4-byte integer from stream
	set dummy [_readstream $f 4];
	binary scan $dummy I a;
	return $a;
}

proc ::tclfpdf::_parsegif { file } {
;#Note: sometimes there are some problems converting GIF to PNG
;# using img. One alternative is use the utility gif2png an then load the file as PNG
	set img "_$file"
	image create photo $img 
	;#first frame in case of animated GIF
	$img read $file -format "gif -index 0"
	set tmp $file.png
	$img write $tmp
	set info [_parsepng $tmp]
	file delete $tmp
	return $info
}

proc ::tclfpdf::_out { s } {
	variable state;variable page; variable pages;
	; variable n;
	;# Add a line to the document
	if { $state==2} {		
		array set pages "$page [list "$pages($page)$s\n"]";
	} elseif { $state == 1} {
		_put $s;
	} elseif { $state == 0} {
		Error "No page han been added yet";
	} elseif { $state == 3} {
		Error "The document is closed";
	}
}

proc ::tclfpdf::_put { s } {
	variable buffer;
	append  buffer "$s\n";	
}

proc ::tclfpdf::_getoffset { } {
	variable buffer;
	return [string length $buffer];
}

proc ::tclfpdf::_newobj { { _n {} } } {
	variable n; variable offsets;
	;# Begin a new object
	if {$_n=={}} {
		set _n [ incr n ];
	}	
	set offsets($_n) [_getoffset];
	_put "$_n 0 obj";
}

proc ::tclfpdf::_putstream { data }  {
	_put "stream";
	_put $data;
	_put "endstream";
}

proc ::tclfpdf::_putstreamobject { data }  {
	variable compress;
	if {$compress==1} {
		set entries "/Filter /FlateDecode ";
		set data [zlib compress $data];
	} else {
		set entries "";
	}
	append entries "/Length [string length $data]";
	_newobj;
	_put "<<$entries>>";
	_putstream $data;
	_put "endobj";
}

proc ::tclfpdf::_putlinks { n } {
	variable PageLinks; variable links; variable PageSizes; variable PageInfo; variable DefPageSize;
	variable k; variable DefOrientation;

	set lpl [array get PageLinks $n,* ]
	foreach {kpl vpl} $lpl {
		lassign $vpl pl(0) pl(1) pl(2) pl(3) pl(4) pl(5)
		_newobj;
		set rect  [format "%.2f %.2f %.2f %.2f" $pl(0) $pl(1) [expr $pl(0)+$pl(2)] [expr $pl(1)-$pl(3)]];
		set s "<</Type /Annot /Subtype /Link /Rect \[$rect\] /Border \[0 0 0\] ";
		if {![string is integer $pl(4)]} {
			append s "/A <</S /URI /URI [_textstring $pl(4)]>>>>"; # URI need parenthesis but it come from _textstring
		} else {
			lassign $links($pl(4)) l(0) l(1);
			if {[isset PageInfo($l(0),size)] } {
				lassign $PageSizes($l(0)) PS(0) PS(1);
				set h1 $PS(1);
			} else {
				set h1 [ expr  { $DefOrientation == "P" } ?[ lindex $DefPageSize 1]*$k : [lindex $DefPageSize 0]*$k];
			}	
	                append s [format "/Dest \[%d 0 R /XYZ 0 %.2f null\]>>" $PageInfo($l(0),n) [expr $h1-$l(1)*$k]];
	        }
		_put $s;
		_put "endobj";
	}
}

proc ::tclfpdf::_putpage { n0 } {
	variable PageInfo; variable WithAlpha;
	variable n; variable AliasNbPages; variable pages; variable page;
	variable PageLinks; 
	
	_newobj;
	_put "<</Type /Page";
	_put "/Parent 1 0 R";
	if {[isset PageInfo($n0,size)] } {
		lassign $PageSizes($n0,size) PS(0)  PS(1);
	        _put [format "/MediaBox \[0 0 %.2f %.2f\]" $PS(0) $PS(1)];
	}
	if {[isset PageInfo($n0,rotation)] } {
		_put "/Rotate PageInfo($n,rotation)";
	}
	_put "/Resources 2 0 R" ;
	if {[isset PageLinks($n0,* ] } {
		set s "/Annots \[";
		set lpl [array get PageLinks $n0,* ]
		foreach {ipl pl} $lpl  {
			append s "[lindex $pl 5] 0 R ";
		}
		append s "\]";
	        _put "$s";
	}
	if {$WithAlpha} {
		_put "/Group <</Type /Group /S /Transparency /CS /DeviceRGB>>";	
	}
	_put "/Contents [expr $n+1] 0 R>>";
	_put "endobj";
	# Page content
	if {$AliasNbPages!=""} {
		set alias [_UTF8toUTF16BE $AliasNbPages 0];
		set r [_UTF8toUTF16BE $page 0];
		set pages($n0)  [string map "$alias $r" $pages($n0)];
		 # Now repeat for no pages in non-subset fonts
		 set pages($n0)  [string map "$AliasNbPages $page" $pages($n0)];
	}
	_putstreamobject $pages($n0);
	;#Link annotations
	_putlinks $n0;
}

proc ::tclfpdf::_putpages { } {
	 variable page; variable PageInfo; variable DefOrientation; 
	 variable DefPageSize; variable k; variable n; variable PageLinks;

	set nb  $page;
	set nn $n;
	for {set n1 1} {$n1<=$nb } {incr n1} {
		set PageInfo($n1,n)  [ incr nn ];
		incr nn ;
		set lpl [array get PageLinks $n1,* ]
		foreach {ipl pl} $lpl  {
			lappend pl [incr nn]
			set PageLinks($ipl) $pl
		}
	}
	for {set n2 1} {$n2<=$nb } {incr n2} {
		_putpage $n2		
	}
	# Pages root
	_newobj 1;
	_put "<</Type /Pages";
	set kids  "/Kids \[";
	for {set n3 1} {$n3<=$nb} {incr n3} {
		append kids "$PageInfo($n3,n) 0 R ";
	}
	_put "$kids\]";
	_put "/Count $nb";
	if { $DefOrientation=="P"} {
		set w1  [lindex $DefPageSize 0];
		set h1  [lindex $DefPageSize 1];
	} else {
		set w1  [lindex $DefPageSize 1];
		set h1   [lindex $DefPageSize 0];
	}
	_put [format "/MediaBox \[0 0 %.2f %.2f\]" [expr $w1*$k] [expr $h1 * $k]];
	_put ">>";
	_put "endobj";
}

proc ::tclfpdf::_putfonts { } {
	variable n; variable diffs;variable FontFiles; variable fonts; 
	variable TCLFPDF_COREFONTPATH; variable CurrentFont;

	foreach  {file info0} [array get FontFiles]  {
		array set _info $info0 ;
		if {![isset _info(type)]  || $_info(type)!="TTF" } {
			# Font file embedding
			_newobj;
			set FontFiles($file,n) $n;
			set file [_SearchPathFile $file];
			if { [catch {open $file "rb" } fp ] } {
				Error "Couldn't to open file : $file - $fp";
			}
			set font [read $fp];
			close $fp;
			set compressed  [string equal [file extension $file] ".z"];
			if {!$compressed && [isset _info(length2)] } {
				set font [_substr $font  6 $_info(length1)][ _substr $font [expr 6 + $_info(length1)+6] $_info(length2)];
			}
			_put "<</Length [string length $font]";
			if {$compressed} {
				_put "/Filter /FlateDecode";
			}
			_put "/Length1 $_info(length1)";
			if {[isset  _info(length2)] }  {
				_put "/Length2 $_info(length2) /Length3 0";
			}
			_put ">>";
			_putstream $font;
			_put "endobj";
		}	
	}
	foreach {k1 _font11} [_ordarray fonts ascii] {
		array set font11 $_font11;
		#Encodings
		if {[isset font11(diff)] } {
			if {![isset encodings($font11(enc))]} {
				_newobj;
				_put "<</Type /Encoding /BaseEncoding /WinAnsiEncoding /Differences \[$font11(diff)\]>>";
				_put "endobj";
				set $encodings($font11(enc)) $n;
			}
		}
		#ToUnicode CMap
		if {[isset font11(uv)]} {
			if { [isset font11(enc)] } {
				set cmapkey $font11(enc);
			} else {
				set cmapkey $font11(name);
			}	
			if {![isset cmaps($cmapkey)] } {
				set cmap [_tounicodecmap $font11(uv)];
				_putstreamobject $cmap;
				set cmaps($cmapkey) $n;
			}
		}
		;# Font objects
		set type $font11(type);
		set name $font11(name);
		if {$type=="Core"} {
		        ;#Core font
			set fonts($k1) "$fonts($k1) n [expr $n+1]";
		        _newobj;
		        _put "<</Type /Font";
		        _put "/BaseFont /$name";
		        _put "/Subtype /Type1";
		        if {$name!="Symbol" && $name!="ZapfDingbats"} {
		                _put "/Encoding /WinAnsiEncoding";
			}
			if { [isset font11(uv)] } {
				_put "/ToUnicode $cmaps($cmapkey) 0 R";
			}	
		        _put ">>";
		        _put "endobj";
		} elseif {$type=="Type1" || $type=="TrueType"} {
		        ;# Additional Type1 or TrueType/OpenType font
			if { [isset font11(subsetted)] && $font11(subsetted)} {
				set name  "AAAAAA+$name";
			}
			set fonts($k1) "$fonts($k1) n [expr $n+1]";
		        _newobj ;
		        _put "<</Type /Font";
		        _put "/BaseFont /$name";
		        _put "/Subtype /$type";
		        _put "/FirstChar 32 /LastChar 255";
		        _put "/Widths [expr ($n+1)] 0 R";
		        _put "/FontDescriptor [expr ($n+2)] 0 R";
			if { $font11(enc) != ""} {
				if {[isset font11(diff)] } {
					_put "/Encoding  $encoding($font1(enc)) 0 R";
				} else {
					_put "/Encoding /WinAnsiEncoding";
				}
			}
			if {[isset font11(uv)]} {
				_put "/ToUnicode $cmaps($cmapkey) 0 R";
			}
		        _put ">>";
		        _put "endobj";
		        ;# Widths
		        _newobj;
		        array set cw $font11(cw);
		        set s  "\[";
		        for {set i 32} {$i<=255 } {incr i} {
				set chr [format %c $i]
		                append s "$cw($chr) ";				
			}
		        _put "$s\]";
		        _put "endobj";
		        ;# Descriptor
		        _newobj;
		        set s  "<</Type /FontDescriptor /FontName /$name";
		        foreach {k v}  $font11(desc) {
		                append s  " /$k $v";
			}	
		        if {$font11(file)!=""} {
		                if {$type=="Type1"} { 
		                        set tipo ""
				} else {
		                        set tipo "2"
				}
				append s " /FontFile$tipo $FontFiles($font11(file),n) 0 R";
			}	
		        _put "$s>>";
		        _put "endobj";
		} elseif {$type=="TTF"} {
			;# TrueType embedded SUBSETS or FULL
			set fonts($k1) "$fonts($k1) n [expr $n+1]";
			source -encoding utf-8 "$TCLFPDF_COREFONTPATH/ttf_font.tcl";
			ttf_Init;
			set fontname  "MPDFAA+$font11(name)";
			set subset $font11(subset);
			_lremove subset 0;
			set ttfontstream [ttf_makeSubset $font11(ttffile) $subset];
			set ttfontsize [string length $ttfontstream];
			set fontstream [zlib compress $ttfontstream];
			array set codeToGlyph [array get ttf_codeToGlyph];
			if {[info exists codeToGlyph(0)] } {
				unset codeToGlyph(0);
			}
			;#Typeo Font
			;#A composite font - a font composed of other fonts, organized hierarchically
			_newobj;
			_put "<</Type /Font";
			_put "/Subtype /Type0";
			_put "/BaseFont /$fontname";
			_put  "/Encoding /Identity-H"; 
			_put "/DescendantFonts \[[expr $n + 1] 0 R\]";
			_put "/ToUnicode [expr $n + 2] 0 R";
			_put ">>";
			_put "endobj" ;

			;#CIDFontType2
			;#A CIDFont whose glyph descriptions are based on TrueType font technology
			_newobj;
			_put "<</Type /Font" ;
			_put "/Subtype /CIDFontType2" ;
			_put "/BaseFont /$fontname" ;
			_put "/CIDSystemInfo [expr $n + 2] 0 R" ; 
			_put 	"/FontDescriptor [expr $n + 3] 0 R" ;
			array unset font111 *;
			array set font111 $font11(desc);
			if { [isset font111(MissingWidth) 0]} {
				_out "/DW $font111(MissingWidth) " ;
			}

			_putTTfontwidths [array get font11] $ttf_maxUni;

			_put "/CIDToGIDMap [expr $n + 4] 0 R" ;
			_put ">>" ;
			_put "endobj" ;

			;#ToUnicode
			_newobj;
			set toUni "/CIDInit /ProcSet findresource begin\n";
			append toUni "12 dict begin\n";
			append toUni "begincmap\n";
			append toUni  "/CIDSystemInfo\n";
			append toUni  "<</Registry (Adobe)\n";
			append toUni  "/Ordering (UCS)\n";
			append toUni  "/Supplement 0\n";
			append toUni  ">> def\n";
			append toUni  "/CMapName /Adobe-Identity-UCS def\n";
			append toUni  "/CMapType 2 def\n";
			append toUni  "1 begincodespacerange\n";
			append toUni  "<0000> <FFFF>\n";
			append toUni  "endcodespacerange\n";
			append toUni  "1 beginbfrange\n";
			append toUni  "<0000> <FFFF> <0000>\n";
			append toUni  "endbfrange\n";
			append toUni  "endcmap\n";
			append toUni  "CMapName currentdict /CMap defineresource pop\n";
			append toUni  "end\n";
			append toUni  "end";
			_put "<</Length [string length $toUni]>>" ;
			_putstream $toUni;
			_put "endobj" ;

			;#CIDSystemInfo dictionary
			_newobj;
			_put "<</Registry (Adobe)" ; 
			_put "/Ordering (UCS)" ;
			_put "/Supplement 0" ;
			_put ">>" ;
			_put "endobj" ;

			;#Font descriptor
			_newobj;
			_put "<</Type /FontDescriptor" ;
			_put "/FontName /$fontname";
			foreach { kd v } $font11(desc)  {
				if {$kd == "Flags"}  { 
					set v [expr $v | 4]; 
					set v [expr $v & ~32];
				}	;#SYMBOLIC font flag
				_out " /$kd $v";
			}
			_put "/FontFile2 [expr $n + 2] 0 R" ;
			_put ">>" ;
			_put "endobj" ;

			;#Embed CIDToGIDMap
			;#A specification of the mapping from CIDs to glyph indices
			set cidtogidmap [string repeat "\x00" [expr 256*256*2]];
			foreach {cc glyph} [array get codeToGlyph]  {
				_setchar cidtogidmap [expr $cc*2] [format %c [expr $glyph >> 8]];
				_setchar cidtogidmap [expr $cc*2 + 1] [format %c [expr $glyph & 0xFF]];
			}
			set cidtogidmap [zlib compress $cidtogidmap];
			_newobj;
			_put "<</Length [string length $cidtogidmap]" ;
			_put "/Filter /FlateDecode" ;
			_put ">>" ;
			_putstream $cidtogidmap;
			_put "endobj" ;

			;#Font file 
			_newobj;
			_put "<</Length [string length $fontstream]";
			_put "/Filter /FlateDecode" ;
			_put "/Length1 $ttfontsize";
			_put ">>" ;
			_putstream $fontstream;
			_put "endobj" ;
		} else {
		        ;# Allow for additional types
			set fonts($k1) "$fonts($k1) n  [expr $n+1]";
		        set mtd  "_put[string tolower $type]";
		        if {[info procs $mtd]==0} {
		                Error "Unsupported font type: $type";
			}	
		        [eval $mtd $font1];
		}
	}	
}

proc ::tclfpdf::_putTTfontwidths { font0 maxUni} {

	array set font $font0;
	if {[file exists $font(unifilename).cw127.tcl]} {
		source -encoding utf-8 $font(unifilename).cw127.tcl;
		set startcid 128;
	} else {
		set rangeid 0;
		array set range {};
		set prevcid -2;
		set prevwidth -1;
		set interval 0;#false
		set startcid 1;
	}
	set cwlen [expr $maxUni + 1]; 

	#for each character
	for {set cid $startcid} {$cid<$cwlen} {incr cid} {
		if {$cid==128 && ![file exists $font(unifilename).cw127.tcl]} {
			if {[catch {open "$font(unifilename).cw127.tcl" "wb" } fh ]} {
				Error "Can't open file: $font(unifilename).cw127.tcl";
			}			
			set cw127 "#-------\n";
			append cw127 "set rangeid $rangeid;\n";
			append cw127 "set prevcid $prevcid;\n";
			append cw127 "set prevwidth $prevwidth;\n";
			if {$interval} { 
				append cw127 "set interval 1;\n";#true
			} else { 
				append cw127 "set interval 0;\n";#false
			}
			append cw127 "array set range \[list [_ordarray range]\];\n";
			append cw127 "#------";
			puts -nonewline $fh $cw127; 
			close $fh;
		}
		set cid2 [_getchar $font(cw) [expr $cid*2]];
		set cid3 [_getchar $font(cw) [expr $cid*2+1]];

		if { $cid2 == "" || $cid3 == "" || $cid2 == "\00" && $cid3 == "\00" } {
			continue;
		}
		set width [expr ([scan [_getchar $font(cw) [expr $cid*2]] %c] << 8) + [scan [_getchar $font(cw) [expr $cid*2+1]] %c] ];
		if {$width == 65535} { 
			set width 0;
		}
		set f_s [lsearch $font(subset) $cid]
		if {$cid > 255 && ($f_s ==-1 || !$f_s)} {
			continue;
		}
		if { ![isset font(dw)] || [isset font(dw)] && $width != $font(dw) } {
			if {$cid == [expr $prevcid + 1]} {
				if {$width == $prevwidth} {
					if {$width == [lindex $range($rangeid) 0]} {
						lappend range($rangeid) $width;
					} else {
						_lremove range($rangeid) end;
						#new range
						set rangeid $prevcid;
						lappend range($rangeid)  $prevwidth;
						lappend range($rangeid)  $width;
					}
					set interval 1;#true
					if {[lsearch $range($rangeid) "interval 1"]==-1} {
						lappend range($rangeid) "interval 1" ;#true
					}
				} else {
					if {$interval} {
						;#new range
						set rangeid $cid;
						lappend range($rangeid) $width;
					} else {
						lappend range($rangeid) $width;
					}
					set interval 0;#false
				}
			} else {
				set rangeid $cid;
				lappend range($rangeid) $width;
				set interval 0;#false
			}
			set prevcid $cid;
			set prevwidth $width;
		}
	}
	set prevk -1;
	set nextk -1;
	set prevint 0;#false
	foreach {k ws} [_ordarray range] {
		set cws [llength $ws];
		if {($k == $nextk) && (!$prevint) && ([lsearch $range($k) "interval 1"] ==-1 || ($cws < 4))} {
			if { [lsearch $range($k) "interval 1"] !=-1 } { 
				_lremove range($k) "interval 1"
			}
			set range($prevk) [concat $range($prevk)  $range($k)];			
			unset range($k);
		} else {
			set prevk $k;
		}
		set nextk [expr $k + $cws];
		if { [lsearch $ws "interval 1"] != -1 } {
			if {$cws > 3} {
				set prevint 1;#true
			} else {
				set prevint 0;# false
			}
			if {[isset range($k) 0] } { ;# not in the original, in PHP dont throw error
				_lremove range($k) "interval 1"
			}	
			incr nextk -1;
		} else {
			set prevint 0;# false
		}
	}
	set w "";
	foreach { k ws} [_ordarray range] {
		if {[ _countVal $ws] == 1} {
			append w " $k [expr $k + [llength ($ws)] - 1] [lindex $ws 0]";
		} else {
			append w " $k \[ [split $ws] \] \n";
		}
	}
	_out "/W \[$w\]";
}

proc _tounicodecmap { uv } {
	set ranges {};
	set nbr 0;
	set chars {};
	set nbc 0;
	foreach {c v}  [lsort -stride 2 -integer $uv] {
		if { [llength $v] > 1 } {
			append ranges [format "<%02X> <%02X> <%04X>\n" $c [expr $c+[lindex $v 1]-1] [lindex $v 0] ];
			incr nbr;
		} else {
			append chars  [format "<%02X> <%04X>\n" $c $v];
			incr nbc;
		}
	}
	append s "/CIDInit /ProcSet findresource begin\n";
	append s "12 dict begin\n";
	append s "begincmap\n";
	append s "/CIDSystemInfo\n";
	append s "<</Registry (Adobe)\n";
	append s "/Ordering (UCS)\n";
	append s "/Supplement 0\n";
	append s ">> def\n";
	append s "/CMapName /Adobe-Identity-UCS def\n";
	append s "/CMapType 2 def\n";
	append s "1 begincodespacerange\n";
	append s "<00> <FF>\n";
	append s "endcodespacerange\n";
	if {$nbr>0} {
		append s "$nbr beginbfrange\n";
		append s $ranges;
		append s "endbfrange\n";
	}
	if {$nbc>0} {
		append s "$nbc beginbfchar\n";
		append s $chars;
		append s "endbfchar\n";
	}
	append s "endcmap\n";
	append s "CMapName currentdict /CMap defineresource pop\n";
	append s "end\n";
	append s "end";
	return $s;
}

proc ::tclfpdf::_putimages { } {
	variable images;
	foreach file [array names images] {
		set images($file) [_putimage $images($file)];
		;# note: this doesn't works if used many times without close it
		;# _lunsetsubarr images $file data;
		;# _lunsetsubarr images $file smask;
	}
}

proc ::tclfpdf::_putimage { info1 } {
	variable n; variable compress;
	_newobj ;
	array set info $info1;
	array set info "n $n";
	_put "<</Type /XObject";
	_put "/Subtype /Image";
	_put "/Width $info(w)";
	_put "/Height $info(h)";
	if {$info(cs)=="Indexed"} {
		_put "/ColorSpace \[/Indexed /DeviceRGB [expr [string length $info(pal)]/3.00-1] [expr $n+1] 0 R\]";
	} else {
		_put "/ColorSpace /$info(cs)";
		if {$info(cs)=="DeviceCMYK"} {
		        _put "/Decode \[1 0 1 0 1 0 1 0\]";
		}	
	}
	_put "/BitsPerComponent $info(bpc)";
	if { [isset info(f) 0]} {
		_put "/Filter /$info(f)";
	}
	if {[isset info(dp) 0]} {
		_put "/DecodeParms <<$info(dp)>>";
	}	
	if {[isset info(trns) 0]} {
		set trns "";
		for {set i 0} { $i < [array size $info(trns)]} {incr i} {
			append trns "$info(trns,$i) $info(trns,$i) ";
		}	
		_put "/Mask \[$trns\]";
	}
	if {[isset info(smask) 0]} {
		_put "/SMask [expr $n+1] 0 R";
	}
	_put "/Length [string length $info(data)]>>";
	_putstream $info(data);
	_put "endobj";
	;# Soft mask
	if {[isset info(smask) 0]} {
		set dp  "/Predictor 15 /Colors 1 /BitsPerComponent 8 /Columns $info(w)";
		_putimage [list w $info(w)  h $info(h) cs DeviceGray bpc 8 f $info(f) dp $dp data $info(smask)];
	}
	;# Palette
	if {$info(cs)=="Indexed"} {
		_putstreamobjest info(pal);
	}
	return [array get info];
}

proc ::tclfpdf::_putxobjectdict { } {
	variable images;
	foreach {k v} [array get images] {
		array set image $v;
		_put "/I$image(i) $image(n) 0 R";
	}	
}

proc ::tclfpdf::_putresourcedict { } {
	variable fonts;
	_put "/ProcSet \[/PDF /Text /ImageB /ImageC /ImageI\]";
	_put "/Font <<";
	foreach {k1 font1} [array get fonts] {
		array set font11 $font1;
		_put "/F$font11(i) $font11(n) 0 R";
	}
	_put ">>";
	_put "/XObject <<" ;
	_putxobjectdict ;
	_put ">>" ;
}

proc ::tclfpdf::_putresources { } {
	_putfonts ;
	_putimages ;
	;# Resource dictionary
	_newobj 2;
	_put "<<";
	_putresourcedict ;
	_put ">>";
	_put "endobj";
}

proc ::tclfpdf::_putinfo { } {
	variable metadata; variable CreationDate;
	
	set metadata(CreationDate) $CreationDate;
	foreach { k1 v1 } [array get metadata]  {
		_put "/$k1 [_textstring $v1]";
	}
}

proc ::tclfpdf::_putcatalog { } {
	variable ZoomMode; variable LayoutMode; variable PageInfo;
	set n1 PageInfo(1,n)
	_put "/Type /Catalog";
	_put "/Pages 1 0 R";
	if { $ZoomMode=="fullpage"} {
		_put "/OpenAction \[3 0 R /Fit\]";
	} elseif { $ZoomMode=="fullwidth"} {
		_put "/OpenAction \[3 0 R /FitH null\]";
	} elseif { $ZoomMode=="real"} {
		_put "/OpenAction \[3 0 R /XYZ null null 1\]";
	} elseif { [string is int $ZoomMode] } {
		_put "/OpenAction \[3 0 R /XYZ null null [format \"%.2f\" [expr $ZoomMode/100)]]\]";
	}	
	if { $LayoutMode=="single"} {
		_put "/PageLayout /SinglePage" ;
	} elseif { $LayoutMode=="continuous"} {
		_put "/PageLayout /OneColumn" ;
	} elseif { $LayoutMode=="two"} {
		_put "/PageLayout /TwoColumnLeft" ;
	}	
}

proc ::tclfpdf::_putheader { } {
	variable PDFVersion;
	_put "%PDF-$PDFVersion";
}

proc ::tclfpdf::_puttrailer { } {
	variable n;
	_put "/Size [expr $n+1]";
	_put "/Root $n 0 R";
	_put "/Info [expr $n-1] 0 R";
}

proc ::tclfpdf::_enddoc { } {
	variable offsets; variable state;
	variable n; variable CreationDate;	
	
	set CreationDate "D:[clock format [clock seconds] -format %Y%m%d%H%M%S]";
	_putheader ;
	_putpages ;
	_putresources ;
	;# Info
	_newobj ;
	_put "<<";
	_putinfo ;
	_put ">>";
	_put "endobj";
	;# Catalog
	_newobj ;
	_put "<<";
	_putcatalog ;
	_put ">>";
	_put "endobj" ;
	;# Cross-ref
	set offset  [_getoffset];
	_put "xref";
	_put "0 [expr $n+1]";
	_put "0000000000 65535 f ";
	for {set i 1} {$i<=$n} {incr i} {
		_put [format "%010d 00000 n " $offsets($i)];
	}	
	;# Trailer
	_put "trailer";
	_put "<<";
	_puttrailer ;
	_put ">>";
	_put "startxref";
	_put $offset;
	_put "%%EOF";
	set state  3;
}

proc ::tclfpdf::_UTF8toUTF16BE { s setbom } {
	;# Convert UTF-8 to UTF-16BE with BOM if need
	set s [encoding convertto [encoding system] $s] 
	set res "";
	if { $setbom == 1}  {
		set res  "\xFE\xFF"; #Byte Order Mark (BOM)
	}	
	set nb [string length $s];
	set i  -1;
	while {$i<$nb-1} {
		set c1 [scan  [string index $s [incr i]] %c];
		if {$c1>=224} {
		        ;# 3-byte character
		        set c2 [scan [string index $s [incr i]] %c];
		        set c3 [scan [string index $s [incr i]] %c];
		        set res "$res[format %c [expr ((($c1 & 0x0F)<<4) + (($c2 & 0x3C)>>2))]]";
		        set res "$res[format %c [expr ((($c2 & 0x03)<<6) + ($c3 & 0x3F))]]";
		} elseif {$c1>=192} {
		        ;# 2-byte character
		        set c2 [scan [string index $s [incr i]] %c];
		        set res "$res[format %c [expr (($c1 & 0x1C)>>2)]]";
		        set res  "$res[format %c [expr ((($c1 & 0x03)<<6) + ($c2 & 0x3F))]]";
		} else {
		        ;# Single-byte character
		        set res "$res\0[format %c $c1]";
		}
	}
	return $res;
}

proc ::tclfpdf::_UTF8StringToArray { str } {
	set str [encoding convertto [encoding system] $str];
	set out {};
	set len [string len $str];
	for {set i 0} { $i < $len} {incr i} {
		set uni -1;
		set h [ scan [string index $str $i] %c];
		if {$h <= 0x7F } {
			set uni $h;
		} elseif { $h >= 0xC2 } {
			if { ($h <= 0xDF) && ($i < $len -1) } {
				set uni [expr ($h & 0x1F) << 6 | ([scan [string index $str [incr i]] %c] & 0x3F) ];
			} elseif { ($h <= 0xEF) && ($i < $len -2) } {
				set uni [expr ($h & 0x0F) << 12 | ( [scan [string index $str [incr i]] %c] & 0x3F) << 6 | ( [scan [string index $str [incr i]] %c] & 0x3F) ];
			} elseif { ($h <= 0xF4) && ($i < $len -3) } {
				set uni [expr ($h & 0x0F) << 18 | ( [scan [string index $str [incr i]] %c] & 0x3F) << 12 | ( [scan [string index $str [incr i]] %c] & 0x3F) << 6 | ( [scan [ string index $str [incr i]] %c] & 0x3F)];
			}
		}
		if {$uni >= 0} {
			lappend out $uni;
		}
	}
	return $out;
}

proc ::tclfpdf::ShowMoreInfoError { {bool 1}} {

	variable TraceAfterError;
	switch -- $bool  {
		0   { set TraceAfterError  0 }
		1   { set TraceAfterError 1 }
		default { Error "Parameter no valid calling ShowMoreInfoError" }
	}
}

proc ::tclfpdf::SetSystemFonts { listofpaths } {

	variable TCLFPDF_SYSTEMFONTPATH;
	;#to check existence of directory
	foreach p $listofpaths {
		if { [file isdirectory $p ]== 1 } {
			lappend TCLFPDF_SYSTEMFONTPATH [ file normalize $p ];
		} else {
			Error "Path not valid setting System Fonts: $p";
		}
	}
}

proc ::tclfpdf::SetUserPath { path } {

	variable TCLFPDF_USERPATH;
	;#to check existence of directory
	if {[file exists $path ] ==1 } {
		if { [file writable $path ]== 1  } {
			set TCLFPDF_USERPATH [ file normalize $path ];
		} else {
			Error "Folder isn't writable, setting User Path: $path";
		}
	} else {
	;# folder doesn't exist
		if { [catch [file mkdir [file normalize $path]] err]} {
			Error "Can't create folder $path : $err";
		} else {
			set TCLFPDF_USERPATH [ file normalize $path ];		
		}
	}
}

proc ::tclfpdf::_SearchPathFile { file } {

	variable TCLFPDF_SYSTEMFONTPATH;
	variable TCLFPDF_COREFONTPATH;
	variable TCLFPDF_USERPATH;
	
	set declaredpaths $TCLFPDF_SYSTEMFONTPATH
	lappend  declaredpaths $TCLFPDF_COREFONTPATH
	lappend  declaredpaths $TCLFPDF_USERPATH


	foreach p $declaredpaths {
		if { [file exists "$p/$file"]} {
			return "$p/$file";
		}
	}
	Error "Could not find file font $file"
}

	;# Import utilities
	source -encoding utf-8 [file join [file dirname [info script]]/misc/util.tcl]
	
	;#Import addons
	foreach addon [glob [file join [file dirname [info script]]/addons/*.tcl]] {
		source -encoding utf-8 $addon
	}

	;# Script fonts path
	variable TCLFPDF_COREFONTPATH [list [file normalize "[file dirname [info script]]/font"]]; # path of TCLPDF + font
	;#Setting system and user fonts path
	switch -- $::tcl_platform(platform) {
			windows 	{ 	set _systemfonts [list "$::env(SystemRoot)/fonts"] 
						set	_userpath "$::env(LOCALAPPDATA)/tclfpdf/fonts"
					}
			unix 		{ 	set _systemfonts [list "/usr/share/fonts" "/usr/local/share/fonts" "~/.fonts"]
						set _userpath "$::env(HOME)/.local/share/tclfpdf/fonts"
					}
			macintosh { 	set  _systemfonts [list "/System/Library/Fonts" "/Libray/Fonts"] 
						set _userpath "$::env(HOME)/tclfpdf/fonts"
					} 
			default { Error "Missing system path font.\n The platform: $::tcl_platform(platform) isn't defined."}
	}	
	SetSystemFonts $_systemfonts;
	SetUserPath $_userpath;

} ;# END eval namespace TCLFPDF