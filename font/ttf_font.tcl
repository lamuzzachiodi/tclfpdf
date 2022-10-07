;# *******************************************************************************
;# * TTFontFile class                                                             *
;# *                                                                              *
;# * This class is based on The ReportLab Open Source PDF library                 *
;# * written in Python - http:;#www.reportlab.com/software/opensource/            *
;# * together with ideas from the OpenOffice source code and others.              *
;# *                                                                              *
;# * Version:  1.05                                                              *
;# * Date:     2018-03-19                                                         *
;# * Author:   Ian Back <ianb@bpm1.com>                                           *
;# * License:  LGPL                                                               *
;# * Copyright (c) Ian Back, 2010                                                 *
;# * This header must be retained in any redistribution or                        *
;# * modification of the file.                                                    *
;# *                                                                              *
;# *******************************************************************************
;# Ported to TCL by L. A. Muzzachiodi (2022)

;# Define the value used in the "head" table of a created TTF file
;# 0x74727565 "true" for Mac
;# 0x00010000 for Windows
;# Either seems to work for a font embedded in a PDF file
;# when read by Adobe Reader on a Windows PC(!)
set ::tclfpdf::ttf_MAC_HEADER  0;

;# TrueType Font Glyph operators
set ::tclfpdf::ttf_GF_WORDS "(1 << 0)";
set ::tclfpdf::ttf_GF_SCALE "(1 << 3)";
set ::tclfpdf::ttf_GF_MORE "(1 << 5)";
set ::tclfpdf::ttf_GF_XYSCALE "(1 << 6)";
set ::tclfpdf::ttf_GF_TWOBYTWO "(1 << 7)";

variable ::tclfpdf::ttf_maxUni;
variable ::tclfpdf::ttf_pos;
variable ::tclfpdf::ttf_numTables;
variable ::tclfpdf::ttf_searchRange;
variable ::tclfpdf::ttf_entrySelector;
variable ::tclfpdf::ttf_rangeShift;
variable ::tclfpdf::ttf_tables;
variable ::tclfpdf::ttf_otables;
variable ::tclfpdf::ttf_filename;
variable ::tclfpdf::ttf_fh;
variable ::tclfpdf::ttf_hmetrics;
variable ::tclfpdf::ttf_glyphPos;
variable ::tclfpdf::ttf_charToGlyph;
variable ::tclfpdf::ttf_ascent;
variable ::tclfpdf::ttf_descent;
variable ::tclfpdf::ttf_name;
variable ::tclfpdf::ttf_familyName;
variable ::tclfpdf::ttf_styleName;
variable ::tclfpdf::ttf_fullName;
variable ::tclfpdf::ttf_uniqueFontID;
variable ::tclfpdf::ttf_unitsPerEm;
variable ::tclfpdf::ttf_bbox;
variable ::tclfpdf::ttf_capHeight;
variable ::tclfpdf::ttf_stemV;
variable ::tclfpdf::ttf_italicAngle;
variable ::tclfpdf::ttf_flags;
variable ::tclfpdf::ttf_underlinePosition;
variable ::tclfpdf::ttf_underlineThickness;
variable ::tclfpdf::ttf_charWidths;
variable ::tclfpdf::ttf_defaultWidth;
variable ::tclfpdf::ttf_maxStrLenRead;
variable ::tclfpdf::ttf_codeToGlyph;

variable glyphToChar;
variable charToGlyph;
variable glyphSet;
variable subsetglyphs;
variable subsetglyphs_bool {};
proc ::tclfpdf::ttf_Init {} {
	variable ::tclfpdf::ttf_maxStrLenRead 200000;	# Maximum size of glyf table to read in as string (otherwise reads each glyph from file)
}


proc ::tclfpdf::ttf_getMetrics {file} {
	set ::tclfpdf::ttf_filename $file;
	if { [catch {open $file "rb"} ::tclfpdf::ttf_fh] } {
		Error "Can't open file $file"
	};
	set ::tclfpdf::ttf_pos 0;
	array unset ::tclfpdf::ttf_charWidths *;
	array unset ::tclfpdf::ttf_glyphPos *;
	array unset ::tclfpdf::ttf_charToGlyph *;
	array unset ::tclfpdf::ttf_tables *;
	array unset ::tclfpdf::ttf_otables *;
	set ::tclfpdf::ttf_ascent 0;
	set ::tclfpdf::ttf_descent 0;
	array unset ::tclfpdf::ttf_TTCFonts *;
	set version [ ::tclfpdf::ttf_read_ulong ];
	set ::tclfpdf::ttf_version $version;
	if {$version==0x4F54544F} {
		Error "Postscript outlines are not supported";
	}	
	if {$version==0x74746366} {
		Error "TrueType Fonts Collections not supported";
	}	
	if {$version in {0x00010000 0x74727565}} {
		Error "Not a TrueType font, version: $version";
	}	
	::tclfpdf::ttf_readTableDirectory;
	::tclfpdf::ttf_extractInfo;
	close $::tclfpdf::ttf_fh;
}

proc ::tclfpdf::ttf_readTableDirectory {} {
	set ::tclfpdf::ttf_numTables [::tclfpdf::ttf_read_ushort];
        set ::tclfpdf::ttf_searchRange [::tclfpdf::ttf_read_ushort];
        set ::tclfpdf::ttf_entrySelector [::tclfpdf::ttf_read_ushort];
        set ::tclfpdf::ttf_rangeShift [::tclfpdf::ttf_read_ushort];
        array unset ::tclfpdf::ttf_tables  *;
        for {set i 0} {$i<$::tclfpdf::ttf_numTables} {incr i} {
		array unset record *;
                set record(tag) [::tclfpdf::ttf_read_tag];
                set record(checksum) [list 0 [::tclfpdf::ttf_read_ushort] 1 [::tclfpdf::ttf_read_ushort]];
                set record(offset) [::tclfpdf::ttf_read_ulong];
                set record(length) [::tclfpdf::ttf_read_ulong];
		foreach {k v} [array get record] {
			set ::tclfpdf::ttf_tables($record(tag),$k) $v;
		}	
	}
}

proc ::tclfpdf::ttf_sub32 { x y} {

	set xlo  [lindex $x 1];
	set xhi  [lindex $x 0];
	set ylo  [lindex $y 1];
	set yhi  [lindex $y 0];
	if {$ylo > $xlo} {
		set $xlo [expr $xlo + (1 << 16) ];
		incr yhi;
	}
	set reslo [expr $xlo-$ylo];
	if {$yhi > $xhi} {
		set xhi [expr $xhi + (1 << 16)];
	}
	set reshi [expr $xhi-$yhi];
	set reshi [expr $reshi & 0xFFFF ];
	return [list $reshi $reslo];
}

proc ::tclfpdf::ttf_calcChecksum { data }  {
	set sl [expr [string length $data] % 4 ];
	if {$sl} {
		append data [string repeat "\0" [expr 4-$sl]];
	}
	set hi 0x0000;
	set lo 0x0000;
	set len_data [string length $data];
	for {set i 0} {$i< $len_data} {incr i 4} {
		incr hi [expr ([scan [string index $data $i] %c ]<< 8) + [scan [string index $data [expr $i+1]] %c]];
		incr lo [ expr ([scan [string index $data [expr $i+2]] %c] <<8) + [scan [string index $data [expr $i+3]] %c ]];
		incr hi [expr $lo >> 16];
		set lo [expr $lo & 0xFFFF];
		set hi [expr $hi & 0xFFFF];
	}
	return [list $hi $lo];
}

proc ::tclfpdf::ttf_get_table_pos { tag } {
	set offset  $::tclfpdf::ttf_tables($tag,offset);
	set length  $::tclfpdf::ttf_tables($tag,length);
	return [list $offset $length];
}

proc ::tclfpdf::ttf_seek { pos } {
	set ::tclfpdf::ttf_pos $pos;
	seek $::tclfpdf::ttf_fh $::tclfpdf::ttf_pos;
}

proc ::tclfpdf::ttf_skip { delta } {
	set ::tclfpdf::ttf_pos [expr $::tclfpdf::ttf_pos + $delta];
	seek $::tclfpdf::ttf_fh $::tclfpdf::ttf_pos;
}

proc ::tclfpdf::ttf_seek_table {tag  {offset_in_table 0}} {
	set tpos  [::tclfpdf::ttf_get_table_pos $tag ];
	set ::tclfpdf::ttf_pos [expr [lindex $tpos 0] + $offset_in_table];
	seek $::tclfpdf::ttf_fh $::tclfpdf::ttf_pos;
	return $::tclfpdf::ttf_pos;
}

proc ::tclfpdf::ttf_read_tag {}  {
	incr ::tclfpdf::ttf_pos 4;
	return [read $::tclfpdf::ttf_fh 4];
}

proc ::tclfpdf::ttf_read_short {} {
	incr ::tclfpdf::ttf_pos 2;
	set s [read $::tclfpdf::ttf_fh 2];
	binary scan $s S short;
	return $short;
}

proc ::tclfpdf::ttf_unpack_short { s } {
	set a [expr [scan [expr $s(0) <<8] %c] + [scan $s(1) %c]];
	if {[expr $a & (1 << 15) ]} { 
		set a  [expr $a - (1 << 16)] ;
	}
	return $a;
}

proc ::tclfpdf::ttf_read_ushort {}  {
	incr ::tclfpdf::ttf_pos 2;
	set s [read $::tclfpdf::ttf_fh 2];
	binary scan $s Su ushort;
	return $ushort;

}

proc ::tclfpdf::ttf_read_ulong {} {
	incr ::tclfpdf::ttf_pos 4;
	set s [read $::tclfpdf::ttf_fh 4];
	set s1 0;
	binary scan $s IuIu s0 s1;
	return [expr $s0+$s1]
}

proc ::tclfpdf::ttf_get_ushort { pos } {
	seek $::tclfpdf::ttf_fh $pos;
	set s [read $::tclfpdf::ttf_fh 2];
	binary scan $s Su ushort;
	return $ushort;
}

proc ::tclfpdf::ttf_get_ulong { pos } {
	seek $::tclfpdf::ttf_fh $pos;
	set s [read $::tclfpdf::ttf_fh 4];
	;# if large uInt32 as an integer, PHP converts it to -ve
	set s1 0;
	binary scan $s IuIu s0 s1;
	return [expr $s0+$s1]
}

proc ::tclfpdf::ttf_pack_short { val } {
	if {$val<0} { 
		set val  [expr abs($val)];
		set val  [expr ~$val];
		incr val ;
	}
	return [binary format "Su" $val]; 
}

proc ::tclfpdf::ttf_splice {stream offset value} {
	return "[_substr $stream 0 $offset]$value[_substr $stream [expr $offset+[string length $value]] ]";
}

proc ::tclfpdf::ttf_set_ushort {stream offset value} {
	set up [ binary format "Su" $value ];
	return  [ ::tclfpdf::ttf_splice $stream $offset $up ];
}

proc ::tclfpdf::ttf_set_short {stream offset val} {
	if {$val<0} { 
		set val  [expr abs($val)];
		set val  [expr ~$val];
		incr val;
	}
	set up [ binary format "Su" $val ]; 
	return [ ::tclfpdf::ttf_splice $stream $offset $up ];
}

proc ::tclfpdf::ttf_get_chunk {pos length} {
	seek $::tclfpdf::ttf_fh $pos;
	if {$length <1} { 
		return "";
	}
	return [read $::tclfpdf::ttf_fh $length];
}

proc ::tclfpdf::ttf_get_table {tag} {
	lassign [ ::tclfpdf::ttf_get_table_pos $tag] pos length;
	if {$length == 0} { 
		Error "Truetype font $::tclfpdf::ttf_filename: error reading table: $tag";
	}
	seek $::tclfpdf::ttf_fh $pos;
	return [read $::tclfpdf::ttf_fh $length];
}

proc ::tclfpdf::ttf_add {tag data} {
	if {$tag == "head"} {
		set data [::tclfpdf::ttf_splice $data 8 "\0\0\0\0"];
	}
	set ::tclfpdf::ttf_otables($tag) $data;
}

proc ::tclfpdf::ttf_extractInfo {} {
;# name - Naming table
	variable glyphToChar; variable charToGlyph;

	set ::tclfpdf::ttf_sFamilyClass 0;
	set ::tclfpdf::ttf_sFamilySubClass 0;	
	set name_offset [::tclfpdf::ttf_seek_table "name"];
	set format [ ::tclfpdf::ttf_read_ushort ];
	if {$format != 0} {
		Error "Unknown name table format $format";
	}
	set numRecords [ ::tclfpdf::ttf_read_ushort ];
	set string_data_offset [expr $name_offset + [::tclfpdf::ttf_read_ushort]];
	array set names [list 1 {} 2 {} 3 {} 4 {} 6 {} ];
	set K  [ array names names];
	set nameCount [array size names];
	for {set i 0} {$i<$numRecords} {incr i} {
		set platformId [ ::tclfpdf::ttf_read_ushort];
		set encodingId [ ::tclfpdf::ttf_read_ushort];
		set languageId [ ::tclfpdf::ttf_read_ushort];
		set nameId [ ::tclfpdf::ttf_read_ushort];
		set length [ ::tclfpdf::ttf_read_ushort];
		set offset [ ::tclfpdf::ttf_read_ushort];
		if {$nameId ni $K} {
			continue;
		}
		set N "";
		if {$platformId == 3 && $encodingId == 1 && $languageId == 0x409} { ;# Microsoft, Unicode, US English, PS Name
			set opos [::tclfpdf::ttf_pos];
			::tclfpdf::ttf_seek [expr $string_data_offset + $offset];
			if {[expr $length % 2] != 0} {
				Error "PostScript name is UTF-16BE string of odd length";
			}
			set length [expr $length/2];
			set N "";
			while {$length > 0} {
				set char [::tclfpdf::ttf_read_ushort];
				append N [format %c $char];
				incr length -1;
			}
			set ::tclfpdf::ttf_pos $opos;
			::tclfpdf::ttf_seek $opos;
		} elseif {$platformId == 1 && $encodingId == 0 && $languageId == 0} { ;# Macintosh, Roman, English, PS Name
			set opos  $::tclfpdf::ttf_pos;
			set N [ ::tclfpdf::ttf_get_chunk [expr $string_data_offset + $offset] $length];
			set ::tclfpdf::ttf_pos $opos;
			::tclfpdf::ttf_seek $opos;
		}
		if {$N != "" && $names($nameId)==""} {
			set names($nameId) $N;
			incr nameCount -1;
			if {$nameCount==0} break;
		}
	}
	if {$names(6)!=""} {
		set psName $names(6);
	} elseif {$names(4)!=""} {
		set psName [ string map {"/ /" "'-"} $names(4) ];
	} elseif {$names(1)!=""} {
		set psName [ string map  {"/ /" "-" } $names(1)];
	} else {
		set psName "";
	}
	if {$psName==""} {
		Error "Could not find PostScript font name";
	}	
	set ::tclfpdf::ttf_name $psName;
	if {$names(1)!=""} { 
		set ::tclfpdf::ttf_familyName $names(1);
	} else { 
		set ::tclfpdf::ttf_familyName $psName;
	}
	if {$names(2)!=""} { 
		set ::tclfpdf::ttf_styleName $names(2);
	} else { 
		set ::tclfpdf::ttf_styleName  "Regular";
	}
	if {$names(4)!=""} {
		set ::tclfpdf::ttf_fullName $names(4);
	} else {
		set ::tclfpdf::ttf_fullName  $psName;
	}
	if {$names(3)!=""} {
		set ::tclfpdf::ttf_uniqueFontID $names(3);
	} else {
		::tclfpdf::ttf_uniqueFontID  $psName;
	}
	if {$names(6)!=""} {
		set ::tclfpdf::ttf_fullName $names(6);
	}
	;# head - Font header table
	::tclfpdf::ttf_seek_table "head";
	::tclfpdf::ttf_skip 18;
	set unitsPerEm [::tclfpdf::ttf_read_ushort];
	set ::tclfpdf::ttf_unitsPerEm $unitsPerEm;
	set scale [expr 1000.00 / $unitsPerEm];
	::tclfpdf::ttf_skip 16;
	set xMin [::tclfpdf::ttf_read_short];
	set yMin [ ::tclfpdf::ttf_read_short];
	set xMax [ ::tclfpdf::ttf_read_short];
	set yMax [::tclfpdf::ttf_read_short];
	array set ::tclfpdf::ttf_bbox [list 0 [expr $xMin*$scale] 1 [expr $yMin*$scale] 2 [expr $xMax*$scale] 3 [expr $yMax*$scale] ];
	::tclfpdf::ttf_skip [expr 3*2];
	set indexToLocFormat [ ::tclfpdf::ttf_read_ushort];
	set glyphDataFormat [::tclfpdf::ttf_read_ushort ];
	if {$glyphDataFormat != 0} {
		Error "Unknown glyph data format $glyphDataFormat";
	}
	;#;
	;# hhea metrics table
	;#;
	;# ttf2t1 seems to use this value rather than the one in OS/2 - so put in for compatibility
	if {[isset ::tclfpdf::ttf_tables(hhea* ]} {
		::tclfpdf::ttf_seek_table "hhea";
		::tclfpdf::ttf_skip 4;
		set hheaAscender [ ::tclfpdf::ttf_read_short];
		set hheaDescender [ ::tclfpdf::ttf_read_short ];
		set ::tclfpdf::ttf_ascent  [expr $hheaAscender *$scale];
		set ::tclfpdf::ttf_descent [expr $hheaDescender *$scale];
	}
	
	;#;
	;# OS/2 - OS/2 and Windows metrics table
	;#;
	if { [isset ::tclfpdf::ttf_tables(OS/2* ]} {
		::tclfpdf::ttf_seek_table "OS/2";
		set version [::tclfpdf::ttf_read_ushort];
		::tclfpdf::ttf_skip 2;
		set usWeightClass [::tclfpdf::ttf_read_ushort];
		::tclfpdf::ttf_skip 2;
		set fsType [::tclfpdf::ttf_read_ushort];
		if {$fsType == 0x0002 || ($fsType & 0x0300) != 0} {
			Error "ERROR - Font file $::tclfpdf::ttf_filename cannot be embedded due to copyright restrictions.";
			set ::tclfpdf::ttf_restrictedUse true;#true
		}
		::tclfpdf::ttf_skip 20;
		set sF [ ::tclfpdf::ttf_read_short];
		set ::tclfpdf::ttf_sFamilyClass [expr $sF >> 8];
		set ::tclfpdf::ttf_sFamilySubClass [expr $sF & 0xFF];
		incr ::tclfpdf::ttf_pos 10;  ;#PANOSE = 10 byte length
		set panose [read $::tclfpdf::ttf_fh 10];
		::tclfpdf::ttf_skip 26;
		set sTypoAscender [::tclfpdf::ttf_read_short ];
		set sTypoDescender [::tclfpdf::ttf_read_short];
		if {!$::tclfpdf::ttf_ascent} {
			set ::tclfpdf::ttf_ascent [expr $sTypoAscender*$scale];
		}	
		if {!$::tclfpdf::ttf_descent} {
			set ::tclfpdf::ttf_descent [expr $sTypoDescender*$scale];
		}	
		if {$version > 1} {
			::tclfpdf::ttf_skip 16;
			set sCapHeight [ ::tclfpdf::ttf_read_short];
			set ::tclfpdf::ttf_capHeight [expr $sCapHeight*$scale];
		} else {
			set ::tclfpdf::ttf_capHeight $::tclfpdf::ttf_ascent;
		}
	} else {
		set usWeightClass 500;
		if {!$::tclfpdf::ttf_ascent}  {
			set ::tclfpdf::ttf_ascent [expr $yMax*$scale];
		}	
		if {!$::tclfpdf::ttf_descent} {
			set ::tclfpdf::ttf_descent [expr $yMin*$scale];
		}	
		set ::tclfpdf::ttf_capHeight $::tclfpdf::ttf_ascent;
	}
	set ::tclfpdf::ttf_stemV [expr 50 + int(pow(($usWeightClass / 65.0),2))];

	;#;
	;# post - PostScript table
	;#;
	::tclfpdf::ttf_seek_table "post";
	::tclfpdf::ttf_skip 4; 
	set ::tclfpdf::ttf_italicAngle [expr [::tclfpdf::ttf_read_short] + [::tclfpdf::ttf_read_ushort] / 65536.0];
	set ::tclfpdf::ttf_underlinePosition [ expr [::tclfpdf::ttf_read_short] * $scale];
	set ::tclfpdf::ttf_underlineThickness [expr [::tclfpdf::ttf_read_short] * $scale];
	set isFixedPitch [::tclfpdf::ttf_read_ulong];

	set ::tclfpdf::ttf_flags 4;

	if {$::tclfpdf::ttf_italicAngle!= 0} { 
		set ::tclfpdf::ttf_flags [expr $::tclfpdf::ttf_flags | 64];
	}	
	if {$usWeightClass >= 600} {
		set ::tclfpdf::ttf_flags [expr $::tclfpdf::ttf_flags | 262144];
	}	
	if {$isFixedPitch} {
		set ::tclfpdf::ttf_flags [expr $::tclfpdf::ttf_flags | 1];
	}	
		
	;#;
	;# hhea - Horizontal header table
	;#;
	::tclfpdf::ttf_seek_table "hhea";
	::tclfpdf::ttf_skip 32; 
	set metricDataFormat [::tclfpdf::ttf_read_ushort];
	if {$metricDataFormat != 0} {
		Error "Unknown horizontal metric data format $metricDataFormat";
	}	
	set numberOfHMetrics [::tclfpdf::ttf_read_ushort];
	if {$numberOfHMetrics == 0} { 
		Error "Number of horizontal metrics is 0";
	}
		
	;#
	;# maxp - Maximum profile table
	;#
	::tclfpdf::ttf_seek_table "maxp";
	::tclfpdf::ttf_skip 4; 
	set numGlyphs [::tclfpdf::ttf_read_ushort];


	;#;
	;# cmap - Character to glyph index mapping table
	;#;
	set cmap_offset [::tclfpdf::ttf_seek_table "cmap"];
	::tclfpdf::ttf_skip 2;
	set cmapTableCount [::tclfpdf::ttf_read_ushort];
	set unicode_cmap_offset 0;
	for {set i 0} {$i<$cmapTableCount} {incr i} {
		set platformID [::tclfpdf::ttf_read_ushort];
		set encodingID [::tclfpdf::ttf_read_ushort];
		set offset  [::tclfpdf::ttf_read_ulong];
		set save_pos $::tclfpdf::ttf_pos;
		if {($platformID == 3 && $encodingID == 1) || $platformID == 0} { ;# Microsoft, Unicode
			set format [ ::tclfpdf::ttf_get_ushort [expr $cmap_offset + $offset]];
			if {$format == 4} {
				if {!$unicode_cmap_offset} {
					set unicode_cmap_offset [expr $cmap_offset + $offset];
				}
				break;
			}
		}
		::tclfpdf::ttf_seek $save_pos;
	}
	if {!$unicode_cmap_offset } {
		Error "Font $::tclfpdf::ttf_filename does not have cmap for Unicode (platform 3, encoding 1, format 4, or platform 0, any encoding, format 4)";
	}
	array unset glyphToChar *;
	array unset charToGlyph *;
	::tclfpdf::ttf_getCMAP4 $unicode_cmap_offset; #glyphToChar charToGlyph;
	;#;
	;# hmtx - Horizontal metrics table
	;#;
	::tclfpdf::ttf_getHMTX $numberOfHMetrics $numGlyphs $scale; #glyphToChar
}

proc ::tclfpdf::ttf_makeSubset { file subset } {
	variable glyphToChar; variable charToGlyph; variable glyphSet; variable subsetglyphs; variable subsetglyphs_bool;
	set ::tclfpdf::ttf_filename $file;
	if { [catch { open $file rb } ::tclfpdf::ttf_fh] } {
		Error "Can't open file $file"
	};
	set ::tclfpdf::ttf_pos 0;
	array unset ::tclfpdf::ttf_charWidths *;
	array unset ::tclfpdf::ttf_glyphPos *;
	array unset ::tclfpdf::ttf_charToGlyph *; 
	array unset ::tclfpdf::ttf_tables *;
	array unset ::tclfpdf::ttf_otables *;
	set ::tclfpdf::ttf_ascent 0;
	set ::tclfpdf::ttf_descent 0;
	::tclfpdf::ttf_skip 4;
	set ::tclfpdf::ttf_maxUni 0;
	::tclfpdf::ttf_readTableDirectory;
	;#
	;# head - Font header table
	;#
	::tclfpdf::ttf_seek_table "head";
	::tclfpdf::ttf_skip 50; 
	set indexToLocFormat [::tclfpdf::ttf_read_ushort];
	set glyphDataFormat [::tclfpdf::ttf_read_ushort];
	;#
	;# hhea - Horizontal header table
	;#
	::tclfpdf::ttf_seek_table "hhea";
	::tclfpdf::ttf_skip 32; 
	set metricDataFormat  [::tclfpdf::ttf_read_ushort];
	set numberOfHMetrics [::tclfpdf::ttf_read_ushort];
	set orignHmetrics $numberOfHMetrics;
	;#
	;# maxp - Maximum profile table
	;#
	::tclfpdf::ttf_seek_table "maxp";
	::tclfpdf::ttf_skip 4;
	set numGlyphs [ ::tclfpdf::ttf_read_ushort];
	;#
	;# cmap - Character to glyph index mapping table
	;#
	set cmap_offset [ ::tclfpdf::ttf_seek_table "cmap"];
	::tclfpdf::ttf_skip 2;
	set cmapTableCount [ ::tclfpdf::ttf_read_ushort ];
	set unicode_cmap_offset 0;
	for {set i 0} {$i<$cmapTableCount} {incr i} {
		set platformID [ ::tclfpdf::ttf_read_ushort];
		set encodingID [ ::tclfpdf::ttf_read_ushort];
		set offset [ ::tclfpdf::ttf_read_ulong];
		set save_pos $::tclfpdf::ttf_pos;
		if {($platformID == 3 && $encodingID == 1) || $platformID == 0} { ;# Microsoft, Unicode
			set format [ ::tclfpdf::ttf_get_ushort [expr $cmap_offset + $offset]];
			if {$format == 4} {
				set unicode_cmap_offset [expr $cmap_offset + $offset];
				break;
			}
		}
		::tclfpdf::ttf_seek $save_pos;
	}
	if {!$unicode_cmap_offset} {
		Error "Font $::tclfpdf::ttf_filename does not have cmap for Unicode (platform 3, encoding 1, format 4, or platform 0, any encoding, format 4)";
	}
	array unset glyphToChar *;
	array unset charToGlyph *;
	::tclfpdf::ttf_getCMAP4 $unicode_cmap_offset;# glyphToChar charToGlyph;
	array unset ::tclfpdf::ttf_charToGlyph *;
	array set ::tclfpdf::ttf_charToGlyph [array get charToGlyph];
	;#
	;# hmtx - Horizontal metrics table
	;#
	set scale 1;	;# not used
	::tclfpdf::ttf_getHMTX $numberOfHMetrics $numGlyphs $scale; #glyphToChar

	;#;
	;# loca - Index to location
	;#;
	::tclfpdf::ttf_getLOCA $indexToLocFormat $numGlyphs;

	array unset subsetglyphs *;
	set subsetglyphs(0) 0;
	
	array unset subsetCharToGlyph *;
	foreach code $subset  {
		if {[isset ::tclfpdf::ttf_charToGlyph($code)]} {
			set subsetglyphs($::tclfpdf::ttf_charToGlyph($code)) $code;		;# Old Glyph ID => Unicode
			set subsetCharToGlyph($code) $::tclfpdf::ttf_charToGlyph($code);	;# Unicode to old GlyphID
		}
		
		set ::tclfpdf::ttf_maxUni [expr max($::tclfpdf::ttf_maxUni,$code)];
	}
	lassign [ ::tclfpdf::ttf_get_table_pos "glyf"] start dummy;

	array unset glyphSet *;
	set n 0;
	set fsLastCharIndex 0;	;# maximum Unicode index (character code) in this font, according to the cmap subtable for platform ID 3 and platform- specific encoding ID 0 or 1.
	foreach {originalGlyphIdx uni} [_ordarray subsetglyphs]  {
		set fsLastCharIndex  [expr max($fsLastCharIndex ,$uni)];
		set glyphSet($originalGlyphIdx) $n;	;# old glyphID to new glyphID
		incr n;
	}

	array unset codeToGlyph *;
	foreach {uni originalGlyphIdx} [_ordarray subsetCharToGlyph] {
		set codeToGlyph($uni)  $glyphSet($originalGlyphIdx);
	}
	
	array unset ::tclfpdf::ttf_codeToGlyph *;	
	array set ::tclfpdf::ttf_codeToGlyph [array get codeToGlyph];

	foreach {originalGlyphIdx uni} [_ordarray subsetglyphs] {
		::tclfpdf::ttf_getGlyphs $originalGlyphIdx $start ;#$glyphSet $subsetglyphs;
	}
	set numberOfHMetrics [expr [array size subsetglyphs] + [_lenbool $subsetglyphs_bool]];
	set numGlyphs $numberOfHMetrics ;

	;#tables copied from the original
	set tags  "name";
	foreach tag $tags {
		::tclfpdf::ttf_add $tag [::tclfpdf::ttf_get_table $tag];
	}
	set tags { "cvt " fpgm prep gasp };	
	foreach tag $tags {
		if {[isset ::tclfpdf::ttf_tables($tag)]} { 
			::tclfpdf::ttf_add $tag [::tclfpdf::ttf_get_table $tag]; 
		}
	}

	;# post - PostScript
	set opost [ ::tclfpdf::ttf_get_table "post" ];
	set post "\x00\x03\x00\x00[_substr $opost 4 12]\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00";
	::tclfpdf::ttf_add "post" $post;

	;# Sort CID2GID map into segments of contiguous codes
	if {[info exists codeToGlyph(0)]} {
		unset codeToGlyph(0);
	}	
	;#unset($codeToGlyph[65535]);
	set rangeid 0;
	array unset range *;
	set prevcid -2;
	set prevglidx -1;
	set idx_rangeid 0;
	;# for each character
	foreach {cid  glidx} [_ordarray codeToGlyph] {
		if {$cid == [expr $prevcid +1 ] && $glidx == [expr $prevglidx +1 ]} {
			set range($rangeid) "$range($rangeid) $glidx"
		} else {
			;# new range
			set rangeid $cid;
			set range($rangeid) $glidx
		}
		set prevcid $cid;
		set prevglidx $glidx;
	}
	;# cmap - Character to glyph mapping - Format 4 (MS / )
	set segCount [expr [array size range] + 1];# + 1 Last segment has missing character 0xFFFF
	set searchRange 1;
	set entrySelector 0;
	while {$searchRange * 2 <= $segCount } {
		set searchRange [expr $searchRange * 2];
		set entrySelector [expr $entrySelector + 1];
	}
	set searchRange [expr $searchRange * 2];
	set rangeShift [expr $segCount * 2 - $searchRange];
	set length [ expr 16 + (8*$segCount ) + ($numGlyphs+1)];
	array set cmap [list 0 0 1 1 2 3 3 1 4 0 5 12 6 4 7 $length 8 0 9 [expr $segCount*2] 10 $searchRange 11 $entrySelector 12 $rangeShift];
		;# Index : version, number of encoding subtables
		;# Encoding Subtable : platform (MS=3), encoding (Unicode)
		;# Encoding Subtable : offset (hi,lo)
		;# Format 4 Mapping subtable: format, length, language
	;# endCode(s)
	set cmapidx 12;
	
	foreach {start subrange} [_ordarray range] {
		set endCode [expr $start + ([llength $subrange]-1)];
		set cmap([incr cmapidx]) $endCode;	;# endCode(s)
	}
	set cmap([incr cmapidx]) 0xFFFF;# endCode of last Segment
	set cmap([incr cmapidx]) 0;# reservedPad
	;# startCode(s)
	foreach {start subrange} [_ordarray range] {
		set cmap([incr cmapidx]) $start;# startCode(s)
	}
	set cmap([incr cmapidx]) 0xFFFF;# startCode of last Segment
	;# idDelta(s) 
	foreach {start subrange} [_ordarray range] {
		set idDelta [expr -($start - [lindex $subrange 0] )];
		incr n [llength $subrange];
		set cmap([incr cmapidx]) $idDelta;# idDelta(s)
	}
	set cmap([incr cmapidx]) 1;# idDelta of last Segment
	;# idRangeOffset(s) 
	foreach {dummy subrange} [_ordarray range] {
			set cmap([incr cmapidx]) 0;# idRangeOffset[segCount]  	Offset in bytes to glyph indexArray, or 0
	}
	set cmap([incr cmapidx]) 0;# idRangeOffset of last Segment
	foreach {dummy subrange} [_ordarray range] {
		foreach glidx $subrange {
			set cmap([incr cmapidx]) $glidx;
		}
	}
	set cmap([incr cmapidx]) 0;# Mapping for last character
	set cmapstr "";
	foreach {dummy cm} [_ordarray cmap] { 
		append cmapstr [binary format "Su" $cm]; 
	}

	::tclfpdf::ttf_add "cmap" $cmapstr;


	;# glyf - Glyph data
	lassign [::tclfpdf::ttf_get_table_pos "glyf"] glyfOffset glyfLength;
	
	if {$glyfLength < $::tclfpdf::ttf_maxStrLenRead } {
		set glyphData [ ::tclfpdf::ttf_get_table "glyf"];
	}

	array unset offsets *;
	set autoidx_offsets -1;
	set glyf "";
	set pos  0;

	set hmtxstr  "";
	set xMinT  0;
	set yMinT  0;
	set xMaxT  0;
	set yMaxT  0;
	set advanceWidthMax  0;
	set minLeftSideBearing  0;
	set minRightSideBearing  0;
	set xMaxExtent  0;
	set maxPoints  0;# points in non-compound glyph
	set maxContours  0;# contours in non-compound glyph
	set maxComponentPoints  0;# points in compound glyph
	set maxComponentContours  0;# contours in compound glyph
	set maxComponentElements  0;# number of glyphs referenced at top level
	set maxComponentDepth  0;# levels of recursion, set to 0 if font has only simple glyphs
	array unset ::tclfpdf::ttf_glyphdata *;
	set autoidx_glyphdata -1;
	set lsubsetglyphs [concat [_ordarray subsetglyphs] $subsetglyphs_bool ];#Adding subset of glyph with boolean value
	foreach {originalGlyphIdx uni} $lsubsetglyphs {
		if {$originalGlyphIdx == false } {set originalGlyphIdx 0}
		if {$originalGlyphIdx == true  } {set originalGlyphIdx 1}
		;# hmtx - Horizontal Metrics
		set hm [ ::tclfpdf::ttf_getHMetric $orignHmetrics $originalGlyphIdx];
		append hmtxstr $hm;
		set offsets([incr autoidx_offsets]) $pos;
		set glyphPos $::tclfpdf::ttf_glyphPos($originalGlyphIdx);
		set ogidx [expr $originalGlyphIdx + 1]
		set glyphLen [expr $::tclfpdf::ttf_glyphPos($ogidx) - $glyphPos];
		if {$glyfLength < $::tclfpdf::ttf_maxStrLenRead} {
			set data [ _substr $glyphData $glyphPos $glyphLen];
		} else {
			if {$glyphLen > 0} {
				set data [::tclfpdf::ttf_get_chunk [expr $glyfOffset+$glyphPos] $glyphLen];
			} else {
				set data "";
			}	
		}
		if {$glyphLen > 0} {
			binary scan [_substr $data 0 2] "Su" up;
		}
		if {$glyphLen > 2 && ($up & (1 << 15)) } {	;# If number of contours <= -1 i.e. composiste glyph
			set pos_in_glyph 10;
			set flags $::tclfpdf::ttf_GF_MORE;
			set nComponentElements 0;
			while {[expr $flags & $::tclfpdf::ttf_GF_MORE]} {
				incr nComponentElements;# number of glyphs referenced at top level
				binary scan [_substr $data $pos_in_glyph 2] "Su" up;
				set flags $up;
				binary scan [_substr $data [expr $pos_in_glyph+2] 2] "Su" up;
				set glyphIdx $up;
				set ::tclfpdf::ttf_glyphdata($originalGlyphIdx,compGlyphs,[incr autoidx_glyphdata]) $glyphIdx;							
				set data [ ::tclfpdf::ttf_set_ushort $data [expr $pos_in_glyph + 2] $glyphSet($glyphIdx)];
				incr pos_in_glyph 4;
				if {[expr $flags & $::tclfpdf::ttf_GF_WORDS]} {
					incr pos_in_glyph 4;
				} else {
					incr pos_in_glyph 2;
				}
				if {[expr $flags & $::tclfpdf::ttf_GF_SCALE]} { 
					incr pos_in_glyph 2; 
				} elseif {[expr $flags & $::tclfpdf::ttf_GF_XYSCALE]} { 
					incr pos_in_glyph 4;
				} elseif {[expr $flags & $::tclfpdf::ttf_GF_TWOBYTWO]} {
					incr pos_in_glyph 8;
				}
			}
			set maxComponentElements [ expr max($maxComponentElements, $nComponentElements)];
		}
		append glyf $data;
		incr pos $glyphLen;
		if {$pos % 4 != 0} {
			set padding [expr 4 - ($pos % 4)];
			append glyf [string repeat "\0" $padding];
			incr pos $padding;
		}
	}
	set offsets([incr autoidx_offsets]) $pos;
	::tclfpdf::ttf_add "glyf" $glyf;
	;# hmtx - Horizontal Metrics
	::tclfpdf::ttf_add "hmtx" $hmtxstr;
	;# loca - Index to location
	set locastr "";
	if {[expr (($pos + 1) >> 1) > 0xFFFF]} {
		set indexToLocFormat 1;# long format
		foreach {key offset} [_ordarray offsets]  {
			append locastr [binary format "Iu" $offset];
		}	
	} else {
		set indexToLocFormat 0;# short format
		foreach {key offset} [_ordarray offsets] {
			append locastr [binary format "Su" [expr $offset/2]];
		}
	}
	::tclfpdf::ttf_add "loca" $locastr;

	;# head - Font header
	set head [ ::tclfpdf::ttf_get_table "head" ];
	set head [ ::tclfpdf::ttf_set_ushort $head 50 $indexToLocFormat];
	::tclfpdf::ttf_add "head" $head;

	;# hhea - Horizontal Header
	set hhea [ ::tclfpdf::ttf_get_table "hhea"];
	set hhea [ ::tclfpdf::ttf_set_ushort $hhea 34 $numberOfHMetrics];
	::tclfpdf::ttf_add "hhea" $hhea;

	;# maxp - Maximum Profile
	set maxp [ ::tclfpdf::ttf_get_table "maxp" ];
	set maxp [ ::tclfpdf::ttf_set_ushort $maxp 4 $numGlyphs ];
	::tclfpdf::ttf_add "maxp" $maxp;

	;# OS/2 - OS/2
	set os2 [::tclfpdf::ttf_get_table "OS/2"];
	::tclfpdf::ttf_add "OS/2" $os2;

	close $::tclfpdf::ttf_fh;

	;# Put the TTF file together
	set stm [::tclfpdf::ttf_endTTFile ];
	return $stm;
	
}

;#;
;# Recursively get composite glyph data
proc ::tclfpdf::ttf_getGlyphData {originalGlyphIdx maxdepth depth points contours} {
	incr depth;
	set maxdepth [ expr max($maxdepth, $depth) ];
	if {[array size ::tclfpdf::ttf_glyphdata($originalGlyphIdx,compGlyphs)]} {
		foreach glyphIdx $::tclfpdf::ttf_glyphdata($originalGlyphIdx,compGlyphs)  {
			::tclfpdf::ttf_getGlyphData $glyphIdx $maxdepth $depth $points $contours;
		}
	} elseif { ($::tclfpdf::ttf_glyphdata($originalGlyphIdx,nContours) > 0) && $depth > 0} {	;# simple
		incr contours $::tclfpdf::ttf_glyphdata($originalGlyphIdx,nContours);
		incr points $::tclfpdf::ttf_glyphdata($originalGlyphIdx,nPoints);
	}
	incr depth -1;
}


;#
;# Recursively get composite glyphs
proc ::tclfpdf::ttf_getGlyphs {originalGlyphIdx start} {
	variable glyphSet; variable subsetglyphs; variable subsetglyphs_bool;

	set glyphPos  $::tclfpdf::ttf_glyphPos($originalGlyphIdx);
	set glyphLen [expr $::tclfpdf::ttf_glyphPos([expr $originalGlyphIdx + 1]) - $glyphPos];
	if {!$glyphLen} { 
		return;
	}
	::tclfpdf::ttf_seek [expr $start + $glyphPos];
	set numberOfContours [ ::tclfpdf::ttf_read_short];
	if {$numberOfContours < 0} {
		::tclfpdf::ttf_skip 8;
		set flags $::tclfpdf::ttf_GF_MORE;
		while {[expr $flags & $::tclfpdf::ttf_GF_MORE]} {
			set flags [ ::tclfpdf::ttf_read_ushort];
			set glyphIdx [ ::tclfpdf::ttf_read_ushort];
			if {![isset glyphSet($glyphIdx)]} {
				set glyphSet($glyphIdx) [expr [array size subsetglyphs] + [_lenbool $subsetglyphs_bool]] ;# old glyphID to new glyphID
				lappend subsetglyphs_bool $glyphIdx true;#true
			}
			set savepos [ tell $::tclfpdf::ttf_fh];
			::tclfpdf::ttf_getGlyphs $glyphIdx $start;# $glyphSet $subsetglyphs
			::tclfpdf::ttf_seek $savepos;
			if {[expr $flags & $::tclfpdf::ttf_GF_WORDS]} {
				::tclfpdf::ttf_skip 4;
			} else {
				::tclfpdf::ttf_skip 2;
			}	
			if {[expr $flags & $::tclfpdf::ttf_GF_SCALE]} {
				::tclfpdf::ttf_skip 2;
			} elseif {[expr $flags & $::tclfpdf::ttf_GF_XYSCALE]} {
				::tclfpdf::ttf_skip 4;
			} elseif {[expr $flags & $::tclfpdf::ttf_GF_TWOBYTWO]} {
				::tclfpdf::ttf_skip 8;
			}
		}
	}
}

;#
proc ::tclfpdf::ttf_getHMTX {numberOfHMetrics numGlyphs scale} {
		variable glyphToChar;
		set start [ ::tclfpdf::ttf_seek_table "hmtx" ];
		set aw 0;
		
		set limit [expr 256*256*2];
		for {set x 0} {$x < $limit} {incr x} {
			set ::tclfpdf::ttf_charWidths($x) "\x00";
		}
		set nCharWidths 0;
		if {($numberOfHMetrics*4) < $::tclfpdf::ttf_maxStrLenRead} {
			set data [ ::tclfpdf::ttf_get_chunk $start [expr $numberOfHMetrics*4] ];
			binary scan $data "Su*" arr;
		} else { 
			::tclfpdf::ttf_seek $start; 
		}
		for {set glyph 0} {$glyph<$numberOfHMetrics} {incr glyph} {
			if {($numberOfHMetrics*4) < $::tclfpdf::ttf_maxStrLenRead} {
				set aw  [lindex $arr [expr ($glyph*2)] ];# take off  "+1"
			} else {
				set aw [ ::tclfpdf::ttf_read_ushort];
				set lsb [  ::tclfpdf::ttf_read_ushort];
			}
			if { [isset glyphToChar($glyph) ] || $glyph == 0} {

				if {$aw >= (1 << 15) } { 
					set aw 0; 
				}	;# 1.03 Some (arabic) fonts have -ve values for width
					;# although should be unsigned value - comes out as e.g. 65108 (intended -50)
				if {$glyph == 0} {
					set ::tclfpdf::ttf_defaultWidth [expr $scale*$aw];
					continue;
				}
				lassign [ array get glyphToChar $glyph] k lchar
				foreach char $lchar {
					if {$char != 0 && $char != 65535} {
 						set w [ expr int(round($scale*$aw))];
						if {$w == 0} { 
							set w 65535;
						}
						if {$char < 196608} {
							set ::tclfpdf::ttf_charWidths([expr $char*2]) [ format %c [expr $w >> 8]];
							set ::tclfpdf::ttf_charWidths([expr $char*2 + 1]) [format %c [expr $w & 0xFF]];
							incr nCharWidths;
						}
					}
				}
			}
		}
		set data [ ::tclfpdf::ttf_get_chunk [expr $start+$numberOfHMetrics*4] [expr $numGlyphs*2] ];
		binary scan $data "Su*" arr;
		set diff [expr $numGlyphs-$numberOfHMetrics];
		for {set pos 0} {$pos<$diff} {incr pos} {
			set glyph [expr $pos + $numberOfHMetrics];
			if {[isset glyphToChar($glyph)]} {
				lassign [ array get glyphToChar $glyph] k lchar
				foreach char $lchar  {
					if {$char != 0 && $char != 65535} {
						set w [ expr int(round($scale*$aw))];
						if {$w == 0} {
							set w 65535;
						}
						if {$char < 196608} {
							set ::tclfpdf::ttf_charWidths([expr $char*2]) [ format %c [expr $w >> 8]];
							set ::tclfpdf::ttf_charWidths([expr $char*2 + 1]) [format %c [expr $w & 0xFF]];
							incr nCharWidths;
						}
					}
				}
			}
		}
		;# NB 65535 is a set width of 0
		;# First bytes define number of chars in font
		set ::tclfpdf::ttf_charWidths(0) [ format %c [expr $nCharWidths >> 8]];
		set ::tclfpdf::ttf_charWidths(1) [ format %c [expr $nCharWidths & 0xFF]];
}

proc ::tclfpdf::ttf_getHMetric {numberOfHMetrics gid} {
	set start [ ::tclfpdf::ttf_seek_table "hmtx" ];
	if {$gid < $numberOfHMetrics} {
		::tclfpdf::ttf_seek [expr $start+($gid*4)];
		set hm [ read $::tclfpdf::ttf_fh 4];
	} else {
		::tclfpdf::ttf_seek [expr $start+(($numberOfHMetrics-1)*4)];
		set hm [ read $::tclfpdf::ttf_fh 2];
		::tclfpdf::ttf_seek [expr $start+($numberOfHMetrics*2)+($gid*2)];
		append hm [ read $::tclfpdf::ttf_fh 2];
	}
	return $hm;
}

proc ::tclfpdf::ttf_getLOCA {indexToLocFormat numGlyphs} {
	set start [::tclfpdf::ttf_seek_table "loca"];
	array unset ::tclfpdf::ttf_glyphPos *;
	set idx_glyphPos -1;
	if {$indexToLocFormat == 0} {
		set data [ ::tclfpdf::ttf_get_chunk $start [expr ($numGlyphs*2)+2]];
		binary scan $data "Su*" arr;
		for {set n 0} {$n<=$numGlyphs} { incr n} {
			set ::tclfpdf::ttf_glyphPos([incr idx_glyphPos]) [lindex $arr [expr $n* 2]]; # NT: It was n+1
		} 
	} elseif {$indexToLocFormat == 1} {
		set data [ ::tclfpdf::ttf_get_chunk $start [expr ($numGlyphs*4)+4]];
		binary scan $data "Iu*" arr;
		for {set n 0} {$n<=$numGlyphs} { incr n} {
			set ::tclfpdf::ttf_glyphPos([incr idx_glyphPos]) [lindex $arr $n];# NT: It was n+1
		}
	} else {
		Error "Unknown location table format $indexToLocFormat)";
	}
}

;# CMAP Format 4
proc ::tclfpdf::ttf_getCMAP4 {unicode_cmap_offset } {

	variable glyphToChar; variable charToGlyph;
	
	set ::tclfpdf::ttf_maxUniChar 0;
	::tclfpdf::ttf_seek [expr $unicode_cmap_offset + 2];
	set length [::tclfpdf::ttf_read_ushort ];
	set limit [expr $unicode_cmap_offset + $length];
	::tclfpdf::ttf_skip 2;
	set segCount [expr [::tclfpdf::ttf_read_ushort] / 2];
	::tclfpdf::ttf_skip 6;
	array unset endCount *;
	for {set i 0} {$i<$segCount} { incr i} { 
		set us  [::tclfpdf::ttf_read_ushort]
		set endCount($i) $us ;
	}
	::tclfpdf::ttf_skip 2;
	array unset startCount *;
	for {set i 0} {$i<$segCount} {incr i} {
		set us  [::tclfpdf::ttf_read_ushort]
		set startCount($i) $us;		
	}
	
	array unset idDelta *;
	for {set i 0} {$i<$segCount } {incr i} { 
		set us  [::tclfpdf::ttf_read_ushort]
		set idDelta($i)  $us;
	};# ???? was unsigned short
	set idRangeOffset_start  $::tclfpdf::ttf_pos;
	array unset idRangeOffset *;
	for {set i 0} {$i<$segCount} {incr i} {
		set idRangeOffset($i) [::tclfpdf::ttf_read_ushort];
	}
	for {set n 0} {$n<$segCount} {incr n} {
		set endpoint [expr $endCount($n) + 1];
		for {set unichar $startCount($n)} {$unichar<$endpoint} {incr unichar} {
			if {$idRangeOffset($n) == 0} {
				set glyph [expr ($unichar + $idDelta($n)) & 0xFFFF];
			} else {
				set $offset [expr ($unichar - $startCount($n)) * 2 + $idRangeOffset($n)];
				set $offset [ expr $idRangeOffset_start + 2 * $n + $offset];
				if {$offset >= $limit} {
					set glyph 0;
				} else {
					set glyph [::tclfpdf::ttf_get_ushort $offset];
					if {$glyph != 0} {
					   set glyph [expr ($glyph + $idDelta($n)) & 0xFFFF];
					}
				}
			}
			set charToGlyph($unichar) $glyph;
			if {$unichar < 196608} { 
				set ::tclfpdf::ttf_maxUniChar [expr max($unichar,$::tclfpdf::ttf_maxUniChar)]; 
			}
			lassign [array get glyphToChar $glyph] key val ;
			set lunichar [lappend val $unichar];
			set glyphToChar($glyph) $lunichar;
		}
	}
}

;# Put the TTF file together
proc ::tclfpdf::ttf_endTTFile { } {
	set stm "";
	set numTables [array size ::tclfpdf::ttf_otables];
	set searchRange 1;
	set entrySelector 0;
	while {$searchRange * 2 <= $numTables} {
		set searchRange [expr $searchRange * 2];
		set entrySelector [expr $entrySelector + 1];
	}
	set searchRange [expr $searchRange * 16];
	set rangeShift [expr $numTables * 16 - $searchRange];
	;# Header
	if {$::tclfpdf::ttf_MAC_HEADER} {
		append stm  [binary format "IuSuSuSuSu" 0x74727565 $numTables $searchRange $entrySelector $rangeShift];# Mac
	} else {
		append stm  [binary format "IuSuSuSuSu" 0x00010000  $numTables $searchRange $entrySelector $rangeShift];# Windows
	}
	;# Table directory
	set offset [expr 12 + $numTables * 16];
	set head_start 0;
	foreach {tag data} [_ordarray ::tclfpdf::ttf_otables ascii] {
		if {$tag == "head"} {
			set head_start $offset;
		}
		append stm $tag;
		set checksum [ ::tclfpdf::ttf_calcChecksum $data];		
		append stm [ binary format "SuSu" [lindex $checksum 0] [lindex $checksum 1]];
		append stm [ binary format "IuIu" $offset [string length $data]];
		set paddedLength [expr  ([string length $data]+3)&~3];
		set offset [expr $offset + $paddedLength];
	}
	;# Table data
	foreach {tag data} [_ordarray ::tclfpdf::ttf_otables ascii]  {
		append data "\0\0\0";
		append stm [_substr $data 0 [expr [string length $data]&~3]];
	}
	set checksum [ ::tclfpdf::ttf_calcChecksum $stm];
	set checksum [ ::tclfpdf::ttf_sub32 {0xB1B0 0xAFBA}  $checksum];
	set chk [ binary format "SuSu" [lindex $checksum 0] [lindex $checksum 1]];
	set stm [ ::tclfpdf::ttf_splice $stm [expr $head_start + 8] $chk];
	return $stm;
}