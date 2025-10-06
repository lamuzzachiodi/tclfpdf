;# *******************************************************************************
;# * Utility to generate font definition files
;#    Version 1.3.4 (2025)
;# * Ported to TCL by L.A. Muzzachiodi
;# * Credit:
;#  	Version: 1.31 (2019) by  Olivier PLATHEY
;# *******************************************************************************

namespace eval ::makefont:: {


variable MF_USERPATH {}; # path of writable folder for save new definitions
variable MF_PATH [file normalize [file dirname [info script]]];#path of Makefont
variable MF_FONTS [list [file normalize [file join $MF_PATH "../fonts"]]];

source -encoding utf-8 "../misc/util.tcl";
source -encoding utf-8 ttfparser.tcl;

proc  Message { txt {severity ""} } {
	set mode "std";
	;#Disable if necessary and set mode according
	if {[string match *wish* [file tail [info nameofexecutable] ]]}  {
		set mode "gui";
	}
	switch -- $mode {
		gui {			
		        tk_messageBox -icon error -message $txt -title "$severity";
		}
		std  {
		        puts "$severity $txt";
		}
	}
}

proc  Warning { txt } {
	Message $txt  "Warning:" ;
}

proc  Error { txt } {

	Message $txt "Error:";
	return -code error $txt
}

proc  LoadMap { enc } {
	if { [catch {open $enc "rb"} fl]} {
		Error "Can't open Encoding :  $enc";
	}
	set a [read $fl];
	close $fl;
	set lines [split $a \n];
	array unset map * ;
	for {set i 0} {$i<= 255 } {incr i} {
		set map($i,uv) -1 ;
		set map($i,name)  ".notdef" ;
	}
	foreach line $lines {
		if {$line == ""} continue;
		set c  [expr 0x[string range [lindex $line 0] 1 end]];
		set uv [expr 0x[string range [lindex $line 1] 2 end]];
		set name [lindex $line 2];
		set map($c,uv) $uv;
		set map($c,name) $name;
	}
	return [array get map];
}

proc  GetInfoFromTrueType { file embed subset map } { 
	#Return informations from a TrueType font
	variable embeddable; 
	variable unitsPerEm; 
	variable postScriptName; 
	variable bold; 
	variable italicAngle;
	variable isFixedPitch; 
	variable typoAscender; 
	variable typoDescender; 
	variable underlineThickness;
	variable underlinePosition; 
	variable capHeight; 
	variable xMin; 
	variable yMin; 
	variable xMax; 
	variable yMax;
	variable glyphs;
	variable chars;
	
	array set _map [array2list $map]; 
	ParseInit $file;
	Parse ;

	if { $embed } {
		if {!$embeddable} {
			Error "Font license does not allow embedding";
		}
		if {$subset} {
			set idx_chr -1;
			array unset _chars;
			foreach  { c _v } [_ordarray _map] {
				array unset v *;
				array set v $_v;
				if { $v(name) ne ".notdef" } {				
						set _chars([incr idx_chr]) $v(uv);
				}
			}
			Subset [_ordarray _chars];
			set info(Data) [ Build ];
		} else  {
			if { [catch {open $file "rb"} f ] } {
				Error "Can't open font file $file";
			}
			set info(Data) [read $f];
		}
		set info(OriginalSize) [string length $info(Data)];
	}
	set k [ expr 1000.00/$unitsPerEm];
	set info(FontName) $postScriptName;
	set info(Bold) $bold;
	set info(ItalicAngle) $italicAngle;
	set info(IsFixedPitch) $isFixedPitch;
	set info(Ascender)  [expr round($k*$typoAscender)];
	set info(Descender) [ expr round($k*$typoDescender)];
	set info(UnderlineThickness) [expr round($k*$underlineThickness)];
	set info(UnderlinePosition) [expr round($k*$underlinePosition)];
	set info(FontBBox) "[expr round($k*$xMin)] [expr round($k*$yMin)] [expr round($k*$xMax)] [expr round($k*$yMax)]";
	set info(CapHeight)  [expr round($k*$capHeight)];
	set info(MissingWidth) [expr round($k*$glyphs(0,w))];
	for {set j 0 } {$j <=255 } {incr j } {
			set widths($j) $info(MissingWidth) ;
	}
	set charmissing {}
	foreach { c  _v } [array get _map] {
		array unset v *;
		array set v $_v;
		if {$v(name) != ".notdef" } {
			if [ isset chars($v(uv)] {
				set id $chars($v(uv));
				set w $glyphs($id,w);
				set widths($c) [expr round($k*$w)];
			} else {
				append charmissing " $v(name) ,";
			}
		}
	}
	if {$charmissing ne {}} {
		Warning "Character(s) missing: $charmissing";
	}
	ParseEnd;
	set info(Widths) [array get widths];
	return [array get info];
}

proc GetInfoFromType1 { file embed _map } { 
	;#  Return informations from a Type1 font
	if {$embed } {
		if { [catch {open $file "rb"} f1] } {;
			Error "Can't open font file";
		}	
		;# Read first segment
		binary scan [read $f1 6]  cucuiu a(marker) a(type) a(size);
		if {$a(marker) !=128} {
			Error "Font file is not a valid binary Type1";
		}	
		set size1 $a(size);
		set data [read $f1 $size1];
		;#  Read second segment
		binary scan [read $f1 6] cucuiu a(marker) a(type) a(size);
		if {$a(marker) !=128} {
			Error "Font file is not a valid binary Type1";
		}	
		set size2 $a(size);
		set data  "$data[ read $f1 $size2]";
		close $f1;
		set info(Data) $data;
		set info(Size1) $size1;
		set info(Size2) $size2;
	}
	set afm "[file rootname $file].afm";
	if {![file exists $afm] } {
		Error "AFM font file not found: $afm";
	}	
	if { [catch {open $afm "rb"} f2] } {
		Error "AFM file empty or not readable";
	}
	set b [read $f2];
	close $f2 ;
	set lines [split $b \n] ;
	foreach line  $lines {
		set k 0 ;
		array unset e *;
		foreach e_ [split [string trimright $line]] {
			set e($k) $e_ ;
			incr k ;
		}
		if {[array size e] <2 } {
			continue;
		}
		set entry $e(0);
		if {$entry == "C" } {
			set w $e(4);
			set name $e(7);
			set cw($name) $w;
		} elseif {$entry=="FontName" } {
			set info(FontName)  $e(1);
		} elseif {$entry=="Weight"} {
			set info(Weight) $e(1);
		} elseif {$entry=="ItalicAngle" } {
			set info(ItalicAngle) $e(1);
		} elseif  {$entry=="Ascender" } {
			set info(Ascender) $e(1);
		} elseif {$entry=="Descender"} {
			set info(Descender) $e(1);
		} elseif {$entry=="UnderlineThickness"} {
			set info(UnderlineThickness) $e(1);
		} elseif {$entry=="UnderlinePosition"} {
			set info(UnderlinePosition) $e(1);
		} elseif {$entry=="IsFixedPitch"} {
			set info(IsFixedPitch) [expr $e(1)=="true"];
		} elseif {$entry=="FontBBox"} {
			#~ set info(FontBBox)  "\\\[ $e(1) $e(2) $e(3) $e(4)\\\]";
			set info(FontBBox)  "$e(1) $e(2) $e(3) $e(4)";
		} elseif {$entry=="CapHeight"} {
			set info(CapHeight) $e(1); 
		} elseif {$entry=="StdVW"} {
			set info(StdVW) $e(1);
		}	
	}

	if { [array get info FontName]==""} {
		Error "FontName missing in AFM file";
	}
	if {![isset info(Ascender)] } {
		set info(Ascender)   [lindex $info(FontBBox) 3];
	}	
	if {![isset info(Descender]} {
		set info(Descender) [lindex $info(FontBBox) 1];
	}
	set info(Bold) [expr ![string equal [array get info Weight] ""] && [regexp "bold|black" $info(Weight)]];
	if { [array get cw .notdef] !="" } {
		set info(MissingWidth) $cw(.notdef);
	} else {
		set info(MissingWidth) 0;
	}	
	for {set j 0 } {$j <=255 } {incr j } {
		set widths($j) $info(MissingWidth) ;
	}
	array set map  [array2list $_map];
	set charmissing {};
	foreach {c _v} [array get map] { 
		array unset v *;
		array set v $_v;
		if { $v(name) ne ".notdef" } {
			if {[isset cw($v(name))] } {			
				set widths($c) $cw($v(name));
			} else {
				append charmissing " $name ,";
			}
		}
	}
	if {$charmissing ne {} } {
		Warning "Character(s) missing: $charmissing";
	}
	set info(Widths) [array get widths];
	return [array get info];
}

proc MakeFontDescriptor { _info } {
	array set info $_info ;
	# Ascent
	append fd "set desc(Ascent) $info(Ascender);\n";
	# Descent
	append fd "set desc(Descent) $info(Descender);\n";
	# CapHeight
	if {$info(CapHeight)!= 0} {
		append fd "set desc(CapHeight) $info(CapHeight);\n";
	} else {
		append fd "set desc(CapHeight) $info(Ascender);\n";
	}	
	# Flags
	set flags 0;
	if {$info(IsFixedPitch)} {
		set flags [expr $flags+ (1<<0)];
	}	
	set flags  [expr $flags + (1<<5)];
	if {$info(ItalicAngle)!=0} {
		set flags [expr $flags + (1<<6)];
	}	
	append fd "set desc(Flags) $flags;\n";
	# FontBBox
	append fd "set desc(FontBBox) \"\\\[$info(FontBBox)\\\]\" ;\n";
	# ItalicAngle
	append fd "set desc(ItalicAngle) $info(ItalicAngle);\n";
	# StemV
	if {[array get info StdVW] != "" } {
		set stemv $info(StdVW);
	} elseif {$info(Bold)}  {
		set stemv 120;
	} else {
		set stemv 70;
	}
	append fd "set desc(StemV) $stemv;\n";
	# MissingWidth
	append fd "set desc(MissingWidth) $info(MissingWidth);\n";
	return  $fd;	
}
	
proc  MakeWidthArray { _widths } {
	array set widths $_widths
	append s "\[ list ";
	for {set c 0} {$c<=255} {incr c} {
		if {$c>=32 & $c<=126} {
			if  { [format %c $c] in { \[ \] \" \\ \{ \} \( \) } } {
				append s "\"\\[format %c $c]\" " ;
			} else {
				append s "\"[format %c $c]\" " ;
			}
		} else {
				append s "\[format %c $c\] ";
		}
		append s "$widths($c) ";
	}
	append s " \]";
	return $s;
}

proc MakeFontEncoding { _map } {
	variable MF_PATH
	array set map $_map;
	# Build differences from reference encoding
	array set ref [LoadMap [file normalize [file join $MF_PATH cp1252.map]]];
	set s "";
	set last 0;
	for {set c 32} {$c<=255} {incr  c} {
		if {$map($c,name) !=$ref($c,name)} {
			if {$c!=$last+1} {
				set s "$s$c ";
				set last $c;
				set s "$s//$map($c,name) ";
			}
		}
	}	
	return [string trimright $s];
}

proc MakeUnicodeArray { _map } {
	# Build mapping to Unicode values
	
	array unset ranges *;
	set idx_rgs -1;
	foreach  { c _v } [lsort -index 0 -integer -stride 2 [array2list $_map]] {
		array unset v *;
		array set v $_v;
		set uv $v(uv);		
		if {$uv!=-1} {
			if {[isset range 0]} {
				if {$c==[ expr $range(1)+1] && $uv== [expr $range(3)+1]} {
					incr range(1);
					incr range(3);
				} else {
					set ranges([incr idx_rgs]) [array get range];
					array set range "0 $c 1 $c 2 $uv 3 $uv";
				}
			} else {
				array set range "0 $c 1 $c 2 $uv 3 $uv";
			}
		}
	}
	set ranges([incr idx_rgs]) [array get range];
	foreach {_c _v} [array get ranges] {
		array unset range *; 
		array set range $_v;
		append s " $range(0) ";
		set nb [expr $range(1)-$range(0)+1];
		if {$nb>1} {
			append s " \{ $range(2) $nb \} ";
		} else {
			append s $range(2);
		}
	}
	return $s;
}

proc  SaveToFile {file s mode} {

	variable MF_USERPATH;
	
	if {[catch {open $MF_USERPATH/$file w} f] } {
		Error "Can't write to file $file";
	}
	if {$mode == "b"} {
		fconfigure $f -translation binary ;
	}	
	puts -nonewline $f  $s;
	close $f;
}

proc MakeDefinitionFile {file type enc embed subset map _info } {
	
	array set info $_info;
	append s "set type \"$type\";\n";
	append s "set name \"$info(FontName)\";\n";
	append s [ MakeFontDescriptor $_info];# bring \n from proc
	append s "set up $info(UnderlinePosition);\n";
	append s "set ut $info(UnderlineThickness);\n";
	append s "array set cw [MakeWidthArray $info(Widths)];\n";
	append s "set enc \"$enc\";\n" 
	set diff [MakeFontEncoding $map];
	if {$diff !=""} {
		append s "set diff \"$diff\";\n";
	}	
	append s "array set uv \[list [MakeUnicodeArray $map]\];\n";
	if {$embed } {
		append s "set file \"$info(File)\";\n";
		if {$type=="Type1"} {
			append s "set size1 $info(Size1);\n"; 
			append s "set size2 $info(Size2);\n";
		} else {
			append s "set originalsize $info(OriginalSize);\n";
			if {$subset} {
				append s "set subsetted 1;\n";
			}
		}	
	}
	SaveToFile $file $s "t";
}

proc MakeFont {fontfile {enc "cp1252"} {embed 1}  {subset 1}} {
	variable MF_PATH
	variable MF_USERPATH
	# Generate a font definition
	CheckFile $fontfile font
	set ext [file extension $fontfile];
	if {$ext==".ttf" || $ext==".otf" } {
		set type "TrueType";
	}  elseif {$ext==".pfb"} {
		set type "Type1";
	} else {
		Error "Unrecognized font file extension: $ext";
	}
	if {$enc eq {} } {
		Error "encode file couldn't be empty";
	}
	if { [file extension $enc] eq {} } {
		set enc [file normalize [file join $MF_PATH $enc.map]]
	}
	CheckFile $enc encode
	if {$embed ni {0 1} } {
		Error "embed must be boolean";
	}
	if {$subset ni {0 1} } {
		Error "subset must be boolean";
	}
	set map [LoadMap $enc];
	if {$type=="TrueType"} {
		array set info [GetInfoFromTrueType $fontfile $embed $subset $map];
	} else {
		array set info [GetInfoFromType1 $fontfile $embed $map];
	}
	SetUserPath $MF_USERPATH
	set basename [file rootname [file tail $fontfile]]
	set encodename [file rootname [file tail $enc]]
	if {$embed} {		
		set file  "$basename\_$encodename.z";
		SaveToFile $file [zlib compress $info(Data)] b;
		set info(File) $file;
		Message "Font file compressed: $file";
	}
	set _info [array get info];
	MakeDefinitionFile $basename\_$encodename.tcl $type $enc $embed $subset $map $_info;
	Message "Font definition file generated: $basename.tcl";
}

proc SetUserPath { path } {

	variable  MF_USERPATH;
	#to check existence of path
	# path exists
	set path [ file normalize $path ];
	if {[file exists $path ] ==1 } {
		if {[file isdirectory $path ] ==1 } {
			if { [file writable $path ]== 1  } {
				set MF_USERPATH $path;
			} else {
				Error "Folder isn't writable, setting User Path: $path";
			}
		} else {
				Error "Path is not a folder(is a File),\n setting User Path: $path";
		}
	} else {
	# folder doesn't exists
		if { [catch [file mkdir $path] err]} {
			Error "Can't create folder $path : $err";
		} else {
			set MF_USERPATH $path;		
		}
	}
}

proc CheckFile { file desc } {

	if {$file eq {} } {
		Error "$desc couldn't be empty"
	}
	if { ![file exist $file]} {
		Error "Could not find $desc\n $file"
	}
	if { ![file isfile $file]} {
		Error "$desc must be a file"
	}
}

# set default value of user and fonts path
	switch -- $::tcl_platform(platform) {
			windows 	{	
						set _systemfonts [list "$::env(SystemRoot)/fonts"];
						set _userpath "$::env(LOCALAPPDATA)/tclfpdf" ;
					}
			unix 		{
						if { $::tcl_platform(os) eq "Darwin" } {
							set  _systemfonts [list "/System/Library/Fonts" "/Libray/Fonts"];
							set _userpath "$::env(HOME)/tclfpdf";
						} else {			
							set _systemfonts [list "/usr/share/fonts" "/usr/local/share/fonts" "$::env(HOME)/.fonts"];
							set _userpath "$::env(HOME)/.local/share/tclfpdf";
						}
					}
	}
	foreach p $_systemfonts {
		if { [file isdirectory $p ]== 1 } {
			lappend MF_FONTS [ file normalize $p ];
		}
	}
	SetUserPath $_userpath
#--- End of Namespace definition
}