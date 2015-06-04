;# *******************************************************************************
;# tclfpdf.tcl 
;# Version: 0.17.2 (2015)
;# Ported to TCL by L. A. Muzzachiodi
;# Credits:
;# Main code based on fpdf.php 1.7 by Olivier Plathey 
;# Parse of JPEG based on pdf4tcl 0.8 by Peter Spjuth
;# *******************************************************************************

package provide tclfpdf 0.17.2
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

	set FPDF_VERSION "0.17"
	set FPDF_FONTPATH "[file join [pwd] [file dirname [info script]]]\\font\\"

	variable page                      	;# current page number
	variable n                           	;# current object number
	variable offsets                   	;# array of object offsets
	variable buffer                    	;# buffer holding in-memory PDF
	variable pages                    	;# array containing pages
	variable state                     	;# current document state
	variable compress              		;# compression flag
	variable k                          	;# scale factor (number of points in user unit)
	variable DefOrientation       		;# default orientation
	variable CurOrientation       		;# current orientation
	variable StdPageSizes         	;# standard page sizes
	variable DefPageSize           	;# default page size
	variable CurPageSize           	;# current page size
	variable PageSizes         		;# used for pages with non default sizes or orientations
	variable wPt 
	variable hPt                       	;# dimensions of current page in points
	variable w 
	variable h                        		;# dimensions of current page in user unit
	variable lMargin                		;# left margin
	variable tMargin                		;# top margin
	variable rMargin                		;# right margin
	variable bMargin                     	;# page break margin
	variable cMargin                    	;# cell margin
	variable x
	variable y                         		;# current position in user unit
	variable lasth                        	;# height of last printed cell
	variable LineWidth                  	;# line width in user unit
	variable fontpath                	;# path containing fonts
	variable CoreFonts                  	;# array of core font names
	variable fonts                         	;# array of used fonts
	variable FontFiles                    	;# array of font files
	variable diffs                        	;# array of encoding differences
	variable FontFamily                 	;# current font family
	variable FontStyle                   	;# current font style
	variable underline                    	;# underlining flag
	variable CurrentFont               	;# current font info
	variable FontSizePt           		;# current font size in points
	variable FontSize                      	;# current font size in user unit
	variable DrawColor                 	;# commands for drawing color
	variable FillColor                		;# commands for filling color
	variable TextColor                	;# commands for text color
	variable ColorFlag                	;# indicates whether fill and text colors are different
	variable ws                        	;# word spacing
	variable images                		;# array of used images
	variable PageLinks                  	;# array of links in pages
	variable links                        	;# array of internal links
	variable AutoPageBreak        	;# automatic page breaking
	variable PageBreakTrigger        	;# threshold used to trigger page breaks
	variable InHeader                	;# flag set when processing header
	variable InFooter                	;# flag set when processing footer
	variable ZoomMode                	;# zoom display mode
	variable LayoutMode                	;# layout display mode
	variable title ""                        	;# title
	variable subject ""                    	;# subject
	variable author ""                    	;# author
	variable keywords ""                	;# keywords
	variable creator ""                	;# creator
	variable AliasNbPages   ""    		;# alias for total number of pages
	variable PDFVersion                	;# PDF version number
}        

proc ::tclfpdf::Init { { orientation P } { unit mm } { size A4 } } {
	variable w; variable h;variable StdPageSizes;
	;# Initialization of properties 
	variable page 0;
	variable n 2;
	variable buffer "";
	variable pages ;
	variable PageSizes;
	variable state  0;
	variable fonts ;
	variable FontFiles; 
	variable diffs {};
	variable images ;
	variable links ;
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
	variable ws  0;
	;# Font files
	array set FontFiles {};
	;# Links
	array set links {};
	;# Custom page sizes
	array set PageSizes {};
	;# Font path
	variable fontpath;
	variable FPDF_FONTPATH;
	set fontpath $FPDF_FONTPATH;
	;# Core fonts
	variable CoreFonts [list courier helvetica times symbol zapfdingbats];
	array set fonts {};
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
	;# Page margins (1 cm)
	set margin [expr 28.35/$k];
	SetMargins $margin $margin;
	;# Interior cell margin (1 mm)
	variable cMargin  [expr $margin/10];
	;# Line width (0.2 mm)
	variable LineWidth [expr .567/$k];
	;# Automatic page break
	SetAutoPageBreak 1 [expr 2*$margin];
	;# Default display mode
	SetDisplayMode "default" ;
	;# Enable compression
	SetCompression 1;
	;# Set default PDF version number
	variable PDFVersion  "1.3";
	if {[namespace which -command Header]== "::Header"} {
		rename ::Header ::tclfpdf::Header
	} else {
		rename ::tclfpdf::Header_ ::tclfpdf::Header
	}
	if {[namespace which -command Footer]== "::Footer"} {
		rename ::Footer ::tclfpdf::Footer
	} else {
		rename ::tclfpdf::Footer_ ::tclfpdf::Footer
	}
	array set images {};
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
	if {$zoom=="fullpage" || $zoom=="fullwidth" || $zoom=="real" || $zoom=="default" || [strins is integer $zoom]} {
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

proc ::tclfpdf::SetTitle { title1 { isUTF8 0 } } {
	variable title;
	;# Title of document
	if {$isUTF8} {
		set title1 [ _UTF8toUTF16 $title1];
	}	
	set title $title1;
}

proc ::tclfpdf::SetSubject { subject1  { isUTF8 0 } } {
	;# Subject of document
	variable subject;
	if {$isUTF8} {
		set subject1 [ _UTF8toUTF16  $subject1];
	}	
	set subject  $subject1;
}

proc ::tclfpdf::SetAuthor { author1 { isUTF8 0 } } {
	;# Author of document
	variable author;
	if {$isUTF8} {
		set author1  [ _UTF8toUTF16 $author1];
	}	
	set author  $author1;
}

proc ::tclfpdf::SetKeywords { keywords1 { isUTF8 0 } } {
	;# Keywords of document
	variable keywords;
	if {$isUTF8} {
		set keywords1   [ _UTF8toUTF16  $keywords1];
	}	
	set keywords  $keywords1;
}

proc ::tclfpdf::SetCreator { creator1 { isUTF8 0 } } {
	;# Creator of document
	variable creator;
	if {$isUTF8} {
		set  creator1 [ _UTF8toUTF16 $creator1] ;
	}	
	set creator $creator1;
}

proc ::tclfpdf::AliasNbPages { {alias "\{nb\}"} } {
	;# Define an alias for total number of pages
	variable AliasNbPages;	
	set AliasNbPages  $alias;
}

proc ::tclfpdf::Error { msg } {
	;# Fatal error
	puts "FPDF error: $msg";
	exit
}

proc ::tclfpdf::Open { } {
	variable state;
	;# Begin document
	set state  1;
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
	Footer;
	set InFooter  0;
	;# Close page
	 _endpage ;
	;# Close document
	_enddoc ;
}

proc ::tclfpdf::AddPage { {orientation ""} {size ""}  } {
	;# Start a new page
	variable state; variable FontFamily; variable underline; variable FontSizePt;
	variable LineWidth; variable DrawColor; variable FillColor; variable TextColor;
	variable ColorFlag; variable page;variable k;variable FontStyle; variable InHeader;
	variable InFooter;
	if { $state==0} Open;
	set family $FontFamily;
	if {$underline} {
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
		Footer;
		set InFooter  0;
		;# Close page
		_endpage;
	}
	;# Start new page
	_beginpage $orientation $size;
	;# Set line cap style to square
	_out "2 J";
	;# Set line width
	set LineWidth  $lw;
	_out [format "%.2f w" [expr $lw*$k]];
	;# Set font
	if {$family!=""} {
		SetFont $family $style $fontsize;
	}        
	;# Set colors
	set DrawColor  $dc;
	if {$dc!="0 G"} {
		_out $dc;
	}        
	set FillColor  $fc;
	if {$fc!="0 g"} {
		 _out $fc;
	}
	set TextColor  $tc;
	set ColorFlag  $cf;
	;# Page header
	set InHeader  1;
	Header;
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

proc ::tclfpdf::Header_ { } {
	;# To be implemented in your own proc
}

proc ::tclfpdf::Footer_ { } {
	;# To be implemented in your own proc
}

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
	variable page; variable CurrentFont; variable FontSize;
	;# Get width of a string in the current font
	array set cw [lindex [list $CurrentFont(cw)] 0];
	set w  0;
	set l  [string  length  $s];
	for { set i 0} {$i<$l} {incr i} {
		set idx [string index $s $i]
		set w [expr $w + $cw($idx)];
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

proc ::tclfpdf::AddFont { family {style ""} {file ""}} {
	variable fonts; variable FontFiles;	
	;# Add a TrueType, OpenType or Type1 font
	set family [string tolower $family];
	if {$file==""} {
		set family [string map {" " ""} $family]
		set file  "$family[string tolower $style].tcl";
	}        
	set style [string toupper $style];
	if {$style=="IB"} {
		set style "BI";
	}        
	set fontkey  "$family$style";
	if {[lsearch [array names fonts] $fontkey ] !=-1 && $fonts($fontkey)!="" } {
		return;
	}        
	array set info [ _loadfont $file];
	set i [expr [array size fonts]+1];
	set info(i) $i;
	if {[lsearch [array names info] "diff" ]!=-1 && $info(diff) != ""} {
		;# Search existing encodings
		set n [array get $info(diff) $diffs];
		if {!$n} {
		        set n [expr [array size ($diffs)] +1];
		        array set diffs { $n  $info(diff) };
		}
		set info(diffn) $n;
	}
	if {[lsearch [array names info] "file" ]!=-1 && $info(file) != ""} {
		;# Embedded font
		if {$info(type)=="TrueType"} {
		        set FontFiles($info(file)) [list length1 $info(originalsize)];
		} else {
		        set FontFiles($info(file)) [list length1 $info(size1) length2 $info(size2)];
		}        
	}
	array set fonts "$fontkey [list [array get info]]";
}

proc ::tclfpdf::SetFont { family {style ""} {size 0} } { 
	variable FontFamily; variable underline;variable fonts; variable k; variable CurrentFont;
	variable CoreFonts;variable page; variable FontSize; variable FontSizePt; variable FontStyle;
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
	array set CurrentFont  $fonts($fontkey);
	if {$page>0} {
		_out [format "BT /F%d %.2f Tf ET" $CurrentFont(i) $FontSizePt];
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
		_out [format "BT /F%d %.2f Tf ET" $CurrentFont(i) $FontSizePt];
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
	array set PageLinks [list $page  [list  [expr $x*$k] [expr $hPt-$y*$k]  [expr $w*$k] [expr $h*$k] $link]];
}

proc ::tclfpdf::Text {x  y txt } {
	;# Output a string
	variable k; variable h; variable underline; variable ColorFlag;
	set s  [format "BT %.2f %.2f Td (%s) Tj ET" [expr $x*$k] [expr ($h-$y)*$k] [_escape $txt]];
	if { $underline && $txt!="" } {
		set s "$s [_dounderline $x $y $txt]";
	}	
	if { $ColorFlag} {
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
		AddPage $CurOrientation $CurPageSize;
		set $x  x1;
		if {$ws1>0} {
		        set ws  $ws1; 
		        _out [format "%.3f Tw" [expr $ws1*$k1]];
		}
	}
	if {$w1==0} {
		set w1  [expr  $w-$rMargin-$x];
	}	
	set s  "";
	if {$fill || $border==1} {
		if {$fill} {
		        set op [expr {$border==1 ? "B" : "f"}];
		} else {
		        set op  "S";
		}	
		set s  [format "%.2f %.2f %.2f %.2f re %s " [expr $x*$k1] [expr ($h-$y)*$k1] [expr $w1*$k1] [ expr -$h1*$k1] $op];
	}
	if {[string is alpha $border]} {
		set $x1  $x;
		set $y1  $y;
		if {[string first "L" $border]!==0} {
		        set s  "$s[format  \"%.2f %.2f m %.2f %.2f l S \" [expr $x1*$k1][expr ($h-$y1)*$k1][ expr $x1*$k1][expr ($h-($y1+$h1))*$k1)]]";
		}	
		if {[string first "T" $border]!==0} {
		        set s  "$s[format \"%.2f %.2f m %.2f %.2f l S \" [expr $x1*$k1][expr ($h-$y1)*$k1][ expr ($x1+$w1)*$k1][ expr ($h-$y1)*$k1)]]";
		}	
		if {[string first "R" $border]!==0} {
		        set  s "$s[format \"%.2f %.2f m %.2f %.2f l S \" [expr ($x1+$w1)*$k1][ expr ($h-$y1)*$k1][ expr ($x1+$w1)*$k1][ expr ($h-($y1+$h1))*$k1)]]";
		}	
		if {[string first "B" $border]!==0} {
		        set s "$s[format \"%.2f %.2f m %.2f %.2f l S \" [expr $x1*$k1][expr ($h-($y1+$h1))*$k1][expr ($x1+$w1)*$k1][expr ($h-($y1+$h1))*$k1)]]";
		}	
	}
	if {$txt!=""} {
		if {$align=="R"} {
		        set dx  [expr $w1-$cMargin- [GetStringWidth $txt]];
		} elseif {$align=="C"} {
		        set dx  [expr ($w1-[GetStringWidth $txt ])/2.00];
		} else {
		        set dx $cMargin;
		}	
		if {$ColorFlag} {
			set s0 "q $TextColor "; 
		        set s "$s$s0";
		}	
		set txt2 [ string map {"\\" "\\\\" "(" "\\(" ")" "\\)"} $txt];
		set s2 [format "BT %.2f %.2f Td (%s) Tj ET" [expr ($x+$dx)*$k1] [expr ($h-($y+0.5*$h1+0.3*$FontSize))*$k1] $txt2];
		set s "$s$s2";
		if {$underline} {
		        set s "$s [_dounderline [expr $x+$dx] [ expr $y+0.5*$h1+0.3*$FontSize] $txt]";
		}	
		if {$ColorFlag} {
		        set s "$s Q";
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
	variable CurrentFont; variable v; variable rMargin; variable x; variable w;
	variable FontSize;variable cMargin; variable ws; variable h; variable lMargin;
	;# Output text with automatic or explicit line breaks
	array set cw  $CurrentFont(cw);
	if {$w1==0} {
		set w1  [expr $w-$rMargin-$x];
	}	
	set wmax  [expr ($w1-2*$cMargin)*1000/$FontSize];
	set s  [string map {\r ""} $txt];
	set nb [string length $s];
	set idx [expr $nb-1]
	if {$nb>0 && [string index $s $idx] =="\n"} {
		decr nb;
	}	
	set b 0;
	if {$border} {
		if {$border==1} {
		        set border "LTRB";
		        set b "LRT";
		        set b2 "LR";
		} else {
		        set b2  "";
		        if {[string first "L" $border]!=0} {
		                set b2  "$b2L";
			}	
		        if {[string first "R" $border]!=0} {
		                set b2 "$b2R";
			}	
		        if {[string first "T" $border]!=0} {
		                set b  "$b2T" 
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
		set c [string index $s $i];
		if {$c=="\n"} {
		        ;# Explicit line break
		        if { $ws>0} {
		                set ws  0;
		                _out "0 Tw";
		        }
		        Cell $w1 $h1 [string range $s $j [expr $i-1]] $b 2 $align $fill;
		        incr i;
		        set sep -1;
		        set j  $i;
		        set l  0;
		        set ns  0;
		        incr nl;
		        if {$border && $nl==2} {
		                set b $b2;
			}	
		        continue;
		}
		if {$c==" "} {
		        set sep $i;
		        set ls $l;
		        incr ns;
		}
		set l [expr $l+$cw($c)];
		if {$l>$wmax } {
		        ;# Automatic line break
		        if {$sep==-1} {
		                if {$i==$j} incr i;
		                if { $ws>0} {
		                        set ws  0;
		                        _out "0 Tw";
		                }
		                Cell $w1 $h1 [string range $s $j $i] $b 2 $align $fill;
		        } else {
		                if {$align=="J"} {
		                        set ws  [expr {($ns>1) ? ($wmax-$ls)/1000.00*$FontSize/($ns-1) : 0}];
		                        _out [format "%.3f Tw" [expr $ws*$k]];
		                }
		                Cell $w1 $h [string range $s $j $sep] $b 2 $align $fill;
		                set i  [expr $sep + 1];
		        }
		        set sep  -1;
		        set j  $i;
		        set l  0;
		        set ns  0;
		        incr $nl;
		        if {$border && $nl==2} {
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
	if {$border && [string first "B" $border]!=0} {
		set b "$bB";
	}	
	Cell $w1 $h1 [string range $s $j $i] $b 2 $align $fill;
	set x $lMargin;
}

proc ::tclfpdf::Write { h1 txt {link "" }} {
	;# Output text in flowing mode
	variable CurrentFont; variable w; variable rMargin; variable lMargin;
	variable x; variable FontSize; variable cMargin; variable y;
	array set cw  $CurrentFont(cw);
	set w1  [expr $w-$rMargin-$x];
	set wmax  [expr ($w1-2*$cMargin)*1000/$FontSize];
	set s  [string map {"\r" ""} $txt];
	set nb  [ string length $s ];
	set sep  -1;
	set i  0;
	set j  0;
	set l  0;
	set nl  1;
	while {$i<$nb} {
		;# Get next character
		set c  [string index $s $i];
		if {$c=="\n"} {
		        ;# Explicit line break
		        Cell $w1 $h1 [ string range $s $j [expr $i-$j] ] 0 2 "" 0 $link;
		        incr i;
		        set sep  -1;
		        set j  $i;
		        set l  0;
		        if {$nl==1} {
		                set x  $lMargin;
		                set w1  [expr $w-$rMargin-$x];
		                set wmax [expr ($w1-2*$cMargin)*1000/$FontSize];
		        }
		        incr nl;
		        continue;
		}
		if {$c==" "} {
		        set sep  $i;
		}	
		set l [expr $l + $cw($c)];
		if {$l>$wmax} {
		        ;# Automatic line break
		        if {$sep==-1} {
		                if { $x>$lMargin} {
		                        ;# Move to next line
		                        set x  $lMargin;
		                        set y [expr $y+ $h1];
		                        set w1 [expr $w-$rMargin-$x];
		                        set wmax  [expr ($w-2*$cMargin)*1000/$FontSize];
		                        incr i;
		                        incr nl;
		                        continue;
		                }
		                if {$i==$j} {
		                        incr i;
				}	
		                Cell $w1 $h1 [string range  $s $j [ expr $i-$j ]] 0 2 "" 0 $link;
		        } else {
		                Cell $w1 $h1 [string range $s $j [expr $sep-$j ]] 0 2 "" 0 $link;
		                set i [expr $sep+1];
		        }
		        set sep  -1;
		        set j  $i;
		        set l  0;
		        if {$nl==1} {
		                set x  $lMargin;
		                set w1  [expr $w-$rMargin-$x];
		                set wmax [expr ($w1-2*$cMargin)*1000/$FontSize];
		        }
		        incr nl;
		} else {
		        incr i;
		}	
	}
	;# Last chunk
	if {$i !=$j} {
		Cell [expr $l/1000.00*$FontSize] $h1 [ string range $s $j end ] 0 0 "" 0 $link;
	}	
}

proc ::tclfpdf::Ln { {h ""} } {
	variable lMargin;variable y; variable lasth;variable x;	
	;# Line feed; default value is last cell height
	set x $lMargin;
	if {$h==""} {
		set y [ expr $y+ $lasth];
	} else {
		set y [expr $y+$h];
	}	
}

proc ::tclfpdf::Image { file { x1 "" } { y1 "" } { w1 0 } { h1  0 }  { type1 "" } { link1 "" } } {
	variable images; variable k; variable y; variable x; variable Link;variable h;
	variable PageBreakTrigger; variable InHeader; variable InFooter;
	variable CurOrientation; variable CurPageSize;
	;# Put an image on the page
	if {[lsearch [array names images] $file ] ==-1}	{
		;# First use of this image, get info
		if {$type1==""} {
		        set pos [string first "." $file];
		        if {!$pos} {
		                Error "Image file has no extension and no type was specified: $file";
			}	
		        set type1 [string range $file [expr $pos+1] end];
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
		array set images "$file $imagesl";
	} else {
		array set info $images($file);
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
		if { [expr $y+$h]>$PageBreakTrigger && !$InHeader && !$InFooter && [AcceptPageBreak] } {
		        ;# Automatic page break
		        set x2  $x;
		        AddPage $CurOrientation $CurPageSize;
		        set x  $x2;
		}
		set y1  $y;
		set y [expr $y+$h];
	}
	if {$x1==""} {
		set x1 $x;
	}	
	_out [format "q %.2f 0 0 %.2f %.2f %.2f cm /I%d Do Q" [expr $w1*$k] [expr $h1*$k] [expr $x1*$k] [expr ($h-($y1+$h1))*$k] $info(i) ];
	if {$link1!=""} {
		Link $x1 $y1 $w1 $h1 $link1;
	}	
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

proc ::tclfpdf::SetY { y1 } {
	;# Set y position and reset x
	variable lMargin; variable y; variable x; variable h;	
	set x $lMargin;
	if {$y1 >=0} {
		set y $y1;
	} else {
		set y [expr $h+$y1];
	}	
}

proc ::tclfpdf::SetXY { x1 y1 } {
	;# Set x and y positions
	SetY $y1;
	SetX $x1;
}

proc ::tclfpdf::Output { {name "" } { dest "" } } {
	variable state; variable buffer;
	;# Output PDF to some destination
	if { $state<3} {
		Close;
	}	
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
				Error "Can't save file $dest"
			};
		        puts $f $buffer;
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
	
	if { [llength $size]==2 } {        
		set a [lindex $size 0]
		set b [lindex $size 1]
		if { $a > $b } {
		        set lreturn [list $b $a ]
		} else {
		        set lreturn [list $a $b ]
		}	
	} else {
		set size [string tolower $size ];
		if { [lsearch [array names StdPageSizes] $size] == -1} {
		        Error "Unknown page size: $size";
		}
		set s $StdPageSizes($size);
		set a  [expr [lindex $s 0]/$k];
		set b [expr [lindex $s 1]/$k];
		set lreturn  [list $a $b]
	}
	return $lreturn;
}

proc ::tclfpdf::_beginpage { orientation size} {
	variable page; variable pages;variable state;
	variable lMargin; variable tMargin; variable bMargin;
	variable FontFamily; variable PageSizes;
	variable DefOrientation; variable DefPageSize;variable CurOrientation;
	variable CurPageSize; variable x;variable y;variable w; variable h; variable k;
	variable wPt; variable hPt; variable PageBreakTrigger;
	
	incr page;
	array set pages "$page {}";
	set state  2;
	set x  $lMargin;
	set y  $tMargin;
	set FontFamily  "";
	;# Check page size and orientation
	if {$orientation==""} {
		set orientation  $DefOrientation;
	} else {
		set orientation  [string toupper [string index $orientation 0]];
	}        
	if {$size==""} {
		set size  $DefPageSize;
	} else {
		set size  [_getpagesize $size];
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
		set wPt  [expr $w*$k];
		set hPt   [expr $h*$k];
		set PageBreakTrigger  [ expr $h-$bMargin];
		set CurOrientation  $orientation;
		set CurPageSize  $size;
	}
	if {$orientation!=$DefOrientation || [lindex $size 0]!=[lindex $DefPageSize 0] || [lindex $size 1]!= [lindex $DefPageSize 1]} {
		array set PageSizes [list $page [list $wPt  $hPt]];
	}        
}

proc ::tclfpdf::_endpage { } {
	variable state;
	
	set state  1;
}

proc ::tclfpdf::_loadfont {font} {
	variable fontpath;
	
	;# Load a font definition file from the font directory
	source "$fontpath$font";
	if {$name==""} {
		Error "Could not include font definition file";
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
	set s  [string map {"\\" "\\\\"} $s];
	set s  [string map {"(" "\\("}  $s];
	set s  [string map {")" "\\)"}  $s];
	set s  [string map {"\r" "\\r"} $s];
	return $s;
}

proc ::tclfpdf::_textstring { s } {
	;# Format a text string
	return "([_escape $s])";
}

proc ::tclfpdf::_UTF8toUTF16 {$s} {
	;# Convert UTF-8 to UTF-16BE with BOM
	set res  "\xFE\xFF";
	set nb  [string length $s];
	set i  0;
	while {$i<$nb}
	{
		incr $i;
		set c1  [scan $s($i) %c];
		if {$c1>=224}
		{
		        ;# 3-byte character
		        set c2  [scan $s($i) %c];
		        set c3  [scan $s($i) %c];
		        set res "$res[format %c [expr ((($c1 & 0x0F)<<4) + (($c2 & 0x3C)>>2))]]";
		        set res "$res[format %c [expr((($c2 & 0x03)<<6) + ($c3 & 0x3F))]]";
		}
		elseif {$c1>=192}
		{
		        ;# 2-byte character
		        set c2 [ scan $s($i) %c];
		        set res "$res[format %c [expr (($c1 & 0x1C)>>2)]]";
		        set res  "$res[format %c [expr ((($c1 & 0x03)<<6) + ($c2 & 0x3F))]]";
		}
		else
		{
		        ;# Single-byte character
		        set res "$res\0[format %c $c1]"];
		}
	}
	return $res;
}

proc ::tclfpdf::_dounderline { x1 y1 txt } {
	;# Underline text
	variable CurrentFont; variable ws; variable k; variable h; variable FontSize; variable FontSizePt;
	set up  $CurrentFont(up);
	set ut   $CurrentFont(ut);
	set w1  [expr [GetStringWidth $txt]+$ws*[expr {[llength [split $txt " "]] - 1}]];
	return  [format "%.2f %.2f %.2f %.2f re f" [expr $x1*$k] [expr ($h-($y1-$up/1000.00*$FontSize))*$k] [expr $w1*$k] [expr -$ut/1000.00*$FontSizePt] ];
}

proc ::tclfpdf::_parsejpg { file } {
	;# Based on the method addJpeg of pdf4tcl 
        set imgOK false
        if {[catch {open $file "rb"} fr] } {
            Error "Can't open file $filename"
        }
        set img [read $fr]
        close $fr
        binary scan $img "H4" h
        if {$h != "ffd8"} {
            Error "File $filename doesn't contain JPEG data."
        }
        set pos 2
        set img_length [string length $img]
        while {$pos < $img_length} {
            set endpos [expr {$pos+4}]
            binary scan [string range $img $pos $endpos] "H4S" h length
            set length [expr {$length & 0xffff}]
            if {$h == "ffc0"} {
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
            return Error "Something is wrong with jpeg data in file $filename"
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
	variable PDFVersion;
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
		                array set trns  0 [scan [string range $t 1 1 ] %c]
			} elseif {$ct==2} {
		                array set trns array [list [scan [string range $t 1 1] %c] [scan [string range $t 3 1] %c]  [scan [string range $t 5 1] %c] ];
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
		                set line  [string range $data [expr $pos+1] $len];
		                set color "$color[regexp("/(.)./s","$1",$line)]";
		                set alpha "$alpha[regexp("/.(.)/s","$1",$line)]";
		        }
		} else  {
		        ;# RGB image
		        set len [expr 4*$w];
		        for {set i 0} {$i<$h} { incr i} {
		                set pos  [expr (1+$len)*$i];
		                set color "$color[string index $data $pos]";
		                set alpha "$alpha[string index $data $pos]";
		                set line [string range $data [expr $pos+1] [expr $pos+$len]];
				set color1 [regsub -all "(.{3})." $line {\1}];
		                set color "$color$color1";
				set alpha1 [regsub -all ".{3}(.)" $line {\1}];
		                set alpha "$alpha$alpha1";				
		        }
		}
		unset data;
		set data [zlib compress $color];
		array set info "smask [list [zlib compress $alpha]]";
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
		set res "$res$s";
	}
	if {$n>0} {
		Error "Unexpected end of stream";
	}	
	return $res;
}

proc ::tclfpdf::_readint { f } {
	;# Read a 4-byte integer from stream
	set dummy [_readstream $f 4];
	binary scan $dummy In a b;
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

proc ::tclfpdf::_newobj { } {
	variable n; variable buffer; variable offsets;
	;# Begin a new object
	incr n;
	array set offsets "$n  [string length $buffer]";
	_out "$n 0 obj";
}

proc ::tclfpdf::_putstream { s }  {
	_out "stream";
	_out $s;
	_out "endstream";
}

proc ::tclfpdf::_out { s } {
	;# Add a line to the document
	variable state;variable page; variable pages;
	variable buffer; variable n;
	if { $state==2} {		
		array set pages "$page [list "$pages($page)$s\n"]";
	} else {
		set buffer "$buffer$s\n";
	}        
}

proc ::tclfpdf::_putpages { } {
	variable page; variable AliasNbPages; variable pages;
	variable DefOrientation; variable k; variable DefPageSize;
	variable compress;variable PageSizes; variable PDFVersion;
	variable n; variable buffer; variable fonts; variable offsets;
	variable PageLinks; variable links;
	set nb  $page;
	if {$AliasNbPages!=""} {
		;# Replace number of pages
		for {set n1 1} {$n1<=$nb } {incr n1} {
			set map "$AliasNbPages $nb";
			set pagina [string map $map $pages($n1)];
			set pages($n1) $pagina;
		}	
	}
	if { $DefOrientation=="P"} {
		set wPt  [expr [lindex $DefPageSize 0]*$k];
		set hPt  [expr [lindex $DefPageSize 1]*$k];
	} else {
		set wPt  [expr [lindex $DefPageSize 1]*$k];
		set hPt   [expr [lindex $DefPageSize 0]*$k];
	}
	if {$compress} {
		set filter "/Filter /FlateDecode ";
	} else {
		set filter "";
	}
	for {set n1 1} {$n1 <= $nb} {incr n1} {
		;# Page
		_newobj;
		_out "<</Type /Page";
		_out "/Parent 1 0 R";
		if {[lsearch [array names PageSizes] $n1 ] !=-1 && $PageSizes($n1)!="" } {
			foreach {PS(0)  PS(1)} $PageSizes($n1) {};
		        _out [format "/MediaBox \[0 0 %.2f %.2f\]" $PS(0) $PS(1)];
		}	
		_out "/Resources 2 0 R" ;
		if {[lsearch [array names PageLinks] $n1 ] !=-1 && $PageLinks($n1)!="" } {
		        ;# Links
		        set annots "/Annots \[";
		        foreach {pl(0) pl(1) pl(2) pl(3) pl(4)} $PageLinks($n1) {
		                set rect  [format "%.2f %.2f %.2f %.2f" $pl(0) $pl(1) [expr $pl(0)+$pl(2)] [expr $pl(1)-$pl(3)]];
		                append annots "<</Type /Annot /Subtype /Link /Rect \[$rect\] /Border \[0 0 0\] ";
		                if {![string is integer $pl(4)]} {
		                        append annots "/A <</S /URI /URI [_textstring $pl(4)]>>>>";
				} else {
		                        foreach {l(0)  l(1)} $links($pl(4)) {};
					if {[lsearch [array names PageSizes] $l(0) ] !=-1 && $PageSizes($l(0))!="" } {
						foreach {PS(0) PS(1)} $PageSizes($l(0)) {};
						set h1 $PS(1)
					} else {
						set h1 $hPt
					}	
		                        append annots [format "/Dest \[%d 0 R /XYZ 0 %.2f null\]>>" [expr 1+2*$l(0)] [expr $h1-$l(1)*$k]];
		                }
		        }
		        _out "$annots\]";
		}
		if { $PDFVersion >"1.3"} {
		        _out "/Group <</Type /Group /S /Transparency /CS /DeviceRGB>>";
		}	
		_out "/Contents [expr $n+1] 0 R>>";
		_out "endobj";
		;# Page content
		if {$compress} {
		        set p  [zlib compress $pages($n1)]			
		} else {        
		        set p $pages($n1);
		}	
		_newobj ;
		_out "<<$filter/Length [string length $p]>>";
		_putstream $p;
		_out "endobj";
	}
	;# Pages root
	array set offsets "1  [string length $buffer ]";
	_out "1 0 obj";
	_out "<</Type /Pages";
	set kids  "/Kids \[";
	for {set i 0} {$i<$nb} {incr i} {
		set kids "$kids[expr (3+2*$i)] 0 R ";
	}	
	_out "$kids\]";
	_out "/Count $nb";
	_out [format "/MediaBox \[0 0 %.2f %.2f\]" $wPt $hPt ];
	_out ">>";
	_out "endobj";
}

proc ::tclfpdf::_putfonts { } {
	variable n; variable diffs;variable FontFiles; variable fonts;variable fontpath;
	set nf $n;
	foreach diff $diffs {
		;# Encodings
		_newobj ;
		_out "<</Type /Encoding /BaseEncoding /WinAnsiEncoding /Differences \[$diff\]>>";
		_out "endobj";
	}
	foreach  {file info0} [array get FontFiles]  {
		;# Font file embedding
		_newobj;
		set FontFiles($file,n) $n
		array set info $info0
		if { [catch [open $fontpath$file "rb" ] fp } {
		       Error "Font file not found: $fontpath$file $fp";
		}
		set font [read $fp];
		close $fp;
		set compressed  [string equal [file extension $file] ".z"];
		if {!$compressed && ![string equal [array get info length2] ""]} {
		        set font [string range $font  6 [expr $info(length1)+6] [ string range $font [expr 6 + $info(length1)+6] $info(length2)]];
		}	
		_out "<</Length [string length $font]";
		if {$compressed} {
		        _out "/Filter /FlateDecode";
		}	
		_out "/Length1 $info(length1)";
		if {[array get info length2]!="" }  {
		        _out "/Length2 $info(length2) /Length3 0";
		}	
		_out ">>";
		_putstream $font;
		_out "endobj";
	}
	foreach {k1 font11} [array get fonts] {		
		;# Font objects
		array set font1 $font11;
		set fonts($k1) "$font11 n [expr $n+1]";
		set type  $font1(type);
		set name $font1(name);
		if {$type=="Core"} {
		        ;# Core font
		        _newobj;
		        _out "<</Type /Font";
		        _out "/BaseFont /$name";
		        _out "/Subtype /Type1";
		        if {$name!="Symbol" && $name!="ZapfDingbats"} {
		                _out "/Encoding /WinAnsiEncoding";
			}	
		        _out ">>";
		        _out "endobj";
		} elseif {$type=="Type1" || $type=="TrueType"} {
		        ;# Additional Type1 or TrueType/OpenType font
		        _newobj ;
		        _out "<</Type /Font";
		        _out "/BaseFont /$name";
		        _out "/Subtype /$type";
		        _out "/FirstChar 32 /LastChar 255";
		        _out "/Widths [expr ($n+1)] 0 R";
		        _out "/FontDescriptor [expr ($n+2)] 0 R";
		        if {[info exists font(diffn)] && $font(diffn) !="" } {
		                _out "/Encoding [expr ($nf+$font(diffn)] 0 R";
			} else {
		                _out "/Encoding /WinAnsiEncoding";
			}	
		        _out ">>";
		        _out "endobj";
		        ;# Widths
		        _newobj;
		        array set cw  $font1(cw);
		        set s  "\[";
		        for {set i 32} {$i<=255 } {incr i} {
				set chr [format %c $i]
		                append s " $cw($chr)";
			}	
		        _out "$s \]";
		        _out "endobj";
		        ;# Descriptor
		        _newobj;
		        set s  "<</Type /FontDescriptor /FontName /$name";
		        foreach {k v}  $font1(desc) {
		                append s  " /$k $v";
			}	
		        if {$font1(file)!=""} {
		                if {$type=="Type1"} { 
		                        set tipo ""
				} else {
		                        set tipo "2"
				}	
		                append s " /FontFile$tipo $FontFiles($font1(file),n) 0 R";
			}	
		        _out "$s>>";
		        _out "endobj";
		} else {
		        ;# Allow for additional types
		        set mtd  "_put[string tolower $type]";
		        if {[info procs $mtd]==0} {
		                Error "Unsupported font type: $type";
			}	
		        [eval $mtd $font1];
		}
	}
}

proc ::tclfpdf::_putimages { } {
	variable images;
	foreach file [array names images] {
		set imagen [list [_putimage $images($file)]]
		array set images "$file $imagen";
		array unset $images($file) data;
		array unset $images($file) smak;
	}
}

proc ::tclfpdf::_putimage { info1 } {
	variable n; variable compress;
	_newobj ;
	array set info $info1;
	array set info "n $n";
	_out "<</Type /XObject";
	_out "/Subtype /Image";
	_out "/Width $info(w)";
	_out "/Height $info(h)";
	if {$info(cs)=="Indexed"} {
		_out "/ColorSpace \[/Indexed /DeviceRGB [expr [string length $info(pal)]/3.00-1] [expr $n+1] 0 R\]";
	} else {
		_out "/ColorSpace /$info(cs)";
		if {$info(cs)=="DeviceCMYK"} {
		        _out "/Decode \[1 0 1 0 1 0 1 0\]";
		}	
	}
	_out "/BitsPerComponent $info(bpc)";
	if {$info(f)!=""} {
		_out "/Filter /$info(f)";
	}
	if {[info exists info(dp)] && $info(dp)!=""} {
		_out "/DecodeParms <<$info(dp)>>";
	}	
	if {[lsearch [array names info] trns]!=-1 && $info(trns)!="" } {
		set trns "";
		for {set i 0} { $i < [array size $info(trns)]} {incr i} {
			append trns "$info(trns)(i) $info(trns)($i)";
		}	
		_out "/Mask \[$trns\]";
	}
	if {[lsearch [array names info] smask]!=-1} {
		_out "/SMask [expr $n+1] 0 R";
	}	
	_out "/Length [string length $info(data)]>>";
	_putstream $info(data);
	_out "endobj";
	;# Soft mask
	if {[lsearch [array names info] smask]!=-1} {
		set dp  "/Predictor 15 /Colors 1 /BitsPerComponent 8 /Columns $info(w)";
		array set smask  [list w $info(w)  h $info(h) cs DeviceGray bpc 8 f $info(f) dp $dp data $info(smask)];
		array set smask [_putimage [array get smask]];
	}
	;# Palette
	if {$info(cs)=="Indexed"} {
		if {($compress)} {
		        set filter "/Filter /FlateDecode ";
		        set pal [zlib compress $info(pal)];
		} else  {      
		        set filter "";
		        set pal $info(pal);
		}	
		_newobj ;
		_out "<<$filter/Length [string length $pal]>>";
		_putstream $pal;
		_out "endobj";
	}
	return [array get info];
}

proc ::tclfpdf::_putxobjectdict { } {
	variable images;
	foreach {k v} [array get images] {
		array set image $v;
		_out "/I$image(i) $image(n) 0 R";
	}	
}

proc ::tclfpdf::_putresourcedict { } {
	variable fonts;
	_out "/ProcSet \[/PDF /Text /ImageB /ImageC /ImageI\]";
	_out "/Font <<";
	foreach {k1 font1} [array get fonts] {
		array set font11 $font1;
		_out "/F$font11(i) $font11(n) 0 R";
	}
	_out ">>";
	_out "/XObject <<" ;
	_putxobjectdict ;
	_out ">>" ;
}

proc ::tclfpdf::_putresources { } {
	variable buffer; variable offsets;
	_putfonts ;
	_putimages ;
	;# Resource dictionary
	array set offsets "2 [string length $buffer]";
	_out "2 0 obj" ;
	_out "<<";
	_putresourcedict ;
	_out ">>";
	_out "endobj";
}

proc ::tclfpdf::_putinfo { } {
	variable FPDF_VERSION; variable title; variable subject; variable author; variable keywords;
	variable creator;
	set version "FPDF $FPDF_VERSION"
	_out "/Producer [_textstring $version]";
	if {$title!=""} {
		_out "/Title [_textstring $title]";
	}	
	if {$subject!=""} {
		_out "/Subject [_textstring $subject]";
	}	
	if {$author!=""} {
		_out "/Author [_textstring $author]";
	}	
	if {$keywords!=""} {
		_out "/Keywords [_textstring $keywords]";
	}	
	if {$creator!=""} {
		_out "/Creator [_textstring $creator]";
	}
	set creationdate [_textstring "D:[clock format [clock seconds] -format %Y%m%d%H%M%S]"]
	_out "/CreationDate $creationdate";
}

proc ::tclfpdf::_putcatalog { } {
	variable ZoomMode; variable LayoutMode;
	_out "/Type /Catalog";
	_out "/Pages 1 0 R";
	if { $ZoomMode=="fullpage"} {
		_out "/OpenAction \[3 0 R /Fit\]";
	} elseif { $ZoomMode=="fullwidth"} {
		_out "/OpenAction \[3 0 R /FitH null\]";
	} elseif { $ZoomMode=="real"} {
		_out "/OpenAction \[3 0 R /XYZ null null 1\]";
	} elseif { [string is int $ZoomMode] } {
		_out "/OpenAction \[3 0 R /XYZ null null [format \"%.2f\" [expr $ZoomMode/100)]]\]";
	}	
	if { $LayoutMode=="single"} {
		_out "/PageLayout /SinglePage" ;
	} elseif { $LayoutMode=="continuous"} {
		_out "/PageLayout /OneColumn" ;
	} elseif { $LayoutMode=="two"} {
		_out "/PageLayout /TwoColumnLeft" ;
	}	
}

proc ::tclfpdf::_putheader { } {
	variable PDFVersion;
	_out "%PDF-$PDFVersion";
}

proc ::tclfpdf::_puttrailer { } {
	variable n;
	_out "/Size [expr $n+1]";
	_out "/Root $n 0 R";
	_out "/Info [expr $n-1] 0 R";
}

proc ::tclfpdf::_enddoc { } {
	variable buffer; variable n; variable offsets;
	_putheader ;
	_putpages ;
	_putresources ;
	;# Info
	_newobj ;
	_out "<<";
	_putinfo ;
	_out ">>";
	_out "endobj";
	;# Catalog
	_newobj ;
	_out "<<";
	_putcatalog ;
	_out ">>";
	_out "endobj" ;
	;# Cross-ref
	set o  [string len $buffer];
	_out "xref";
	_out "0 [expr $n+1]";
	_out "0000000000 65535 f ";
	for {set i 1} {$i<=$n} {incr i} {
		_out [format "%010d 00000 n " $offsets($i)];
	}	
	;# Trailer
	_out "trailer";
	_out "<<";
	_puttrailer ;
	_out ">>";
	_out "startxref";
	_out $o;
	_out "%%EOF";
	set state  3;
}