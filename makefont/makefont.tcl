;# *******************************************************************************
;# * Utility to generate font definition files
;#    Version 0.12 (2014)
;# * Ported to TCL by L.A. Muzzachiodi
;# * Credit:
;#  	Version: 1.2 (2011) by  Olivier PLATHEY
;# *******************************************************************************

source ttfparser.tcl;

proc  Message { txt {severity ""} } {
		puts "$severity $txt";
}

proc  Notice { txt } {
	Message  $txt "Notice:";
}

proc  Warning { txt } {
	Message $txt  "Warning:" ;
}

proc  Error { txt } {
	Message $txt "Error:";
	exit;
}

proc  LoadMap { enc } {
	set file [file nativename "[file join [pwd] [file dirname [info script]]]/[string tolower $enc].map"];
	if { [catch {open $file "rb"} fl]} {
		Error "Encoding not found:  $enc";
	}	
	set a [read $fl]
	close $fl
	set lines [split $a \n]
	array set map {}
	for {set i 0} {$i<= 255 } {incr i} {
		set map($i,uv) -1
		set map($i,name)  ".notdef"
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

proc  GetInfoFromTrueType { file embed _map } { 
	#Return informations from a TrueType font
	variable Embeddable; variable unitsPerEm; variable postScriptName; variable Bold; variable italicAngle;
	variable isFixedPitch; variable typoAscender; variable typoDescender; variable underlineThickness;
	variable underlinePosition; variable capHeight; variable widths; variable chars;
	variable xMin; variable yMin; variable xMax; variable yMax; 
	
	array set map $_map;
	Parse $file;
	if { $embed } {
		if {!$Embeddable} {
			Error "Font license does not allow embedding";
		}
		if { [catch {open $file "rb"} f ] } {
			Error "Can't open font file $file";
		}
		set info(Data) [read $f];
		set info(OriginalSize) [file size $file];
	}
	set k [ expr 1000.00/$unitsPerEm];
	set info(FontName) $postScriptName;
	set info(Bold) $Bold;
	set info(ItalicAngle) $italicAngle;
	set info(IsFixedPitch) $isFixedPitch;
	set info(Ascender)  [expr round($k*$typoAscender)];
	set info(Descender) [ expr round($k*$typoDescender)];
	set info(UnderlineThickness) [expr round($k*$underlineThickness)];
	set info(UnderlinePosition) [expr round($k*$underlinePosition)];
	set info(FontBBox) "\\\[[expr round($k*$xMin)] [expr round($k*$yMin)] [expr round($k*$xMax)] [expr round($k*$yMax)]\\\]";
	set info(CapHeight)  [expr round($k*$capHeight)];
	set info(MissingWidth) [expr round($k*$widths(0))];
	for {set j 0 } {$j <=255 } {incr j } {
		set _widths($j) $info(MissingWidth) ;
	}
	for {set c 0} {$c <= 255 } {incr c} {
		if {$map($c,name) != ".notdef" } {
			set uv $map($c,uv);
			if { [array get chars $uv]!=""} {
				set w $widths($chars($uv));
				set _widths($c) [expr round($k*$w)];
			} else {
				Warning "Character $map($c,name) is missing";
			}	
		}
	}
	set info(Widths) [array get _widths];
	return [array get info];
}

proc  GetInfoFromType1 { file embed _map } { 
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
	set b [read $f2]
	close $f2
	set lines [split $b \n]
	foreach line  $lines {
		set k 0
		array set e {}
		foreach e_ [split [string trimright $line]] {
			set e($k) $e_
			incr k
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
			set info(FontBBox)  "\\\[ $e(1) $e(2) $e(3) $e(4)\\\]";
		} elseif {$entry=="CapHeight"} {
			set info(CapHeight) $e(1); 
		} elseif {$entry=="StdVW"} {
			set info(StdVW) $e(1);
		}	
	}

	if { [array get info FontName]==""} {
		Error "FontName missing in AFM file";
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
	array set map $_map
	for {set c 0 } {$c<=255} {incr c} {
		set name $map($c,name);
		if { $name!= ".notdef" } {
			if { [array get cw $name]!=""} {
				set widths($c) $cw($name);
			} else {
				Warning "Character $name is missing";
			}
		}
	}
	set info(Widths) [array get widths];
	return [array get info];
}

proc  MakeFontDescriptor { _info } {
	array set info $_info
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
	append fd "set desc(FontBBox) \"$info(FontBBox)\";\n";
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

proc  MakeFontEncoding { _map } {
	array set map $_map
	# Build differences from reference encoding
	array set ref [LoadMap cp1252];
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

proc  SaveToFile {file s mode} {
	if {[catch {open  $file w} f] } {
		Error "Can't write to file $file";
	}
	if {$mode == "b"} {
		fconfigure $f -translation binary
	}	
	puts $f  $s;
	close $f;
}

proc  MakeDefinitionFile {file type enc embed map _info } {
	array set info $_info;
	append s "set type \"$type\";\n";
	append s "set name \"$info(FontName)\";\n";
	append s "[MakeFontDescriptor $_info];\n";
	append s "set up $info(UnderlinePosition);\n";
	append s "set ut $info(UnderlineThickness);\n";
	append s "array set cw [MakeWidthArray $info(Widths)];\n";
	append s "set enc $enc;\n" 
	set diff [MakeFontEncoding $map];
	if {$diff !=""} {
		append s "set diff $diff;\n";
	}	
	if {$embed } {
		append s "set file $info(File);\n";
	}	
	if {$type=="Type1"} {
			append s "set size1 $info(Size1);\n"; 
			append s "set size2 $info(Size2);\n";
	} else {
			append s "set originalsize $info(OriginalSize);\n";
	}
	SaveToFile $file $s "t"
}

proc  MakeFont {fontfile {enc "cp1252"} {embed 1} } {
	# Generate a font definition file
	if {![file exists $fontfile] } {
		Error "Font file not found: $fontfile";
	}	
	set ext [file extension $fontfile]
	if {$ext==".ttf" || $ext==".otf" } {
		set type "TrueType";
	}  elseif {$ext==".pfb"} {
		set type "Type1";
	} else {
		Error "Unrecognized font file extension: $ext";
	}
	set map [LoadMap $enc];
	if {$type=="TrueType"} {
		array set info [GetInfoFromTrueType $fontfile $embed $map];
	} else {
		array set info [GetInfoFromType1 $fontfile $embed $map];
	}	
	set basename [file rootname $fontfile]
	if {$embed} {
		set file  "$basename.z";
		SaveToFile $file [zlib compress $info(Data)] b;
		set info(File) $file;
		Message "Font file compressed: $file";
	}	
	set _info [array get info]
	MakeDefinitionFile $basename.tcl $type $enc $embed $map $_info;
	Message "Font definition file generated: $basename.tcl";
}