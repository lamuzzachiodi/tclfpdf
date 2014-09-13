;# *******************************************************************************
;# * Utility to parse TTF font files
;#    Version 0.1 (2014)
;# * Ported to TCL by L.A. Muzzachiodi
;# * Credit:
;#  	Version: 1.0 (2011) by Olivier PLATHEY
;# *******************************************************************************

	variable f;
	variable tables;
	variable unitsPerEm;
	variable xMin;
	variable yMin;
	variable xMax
	variable yMax;
	variable numberOfHMetrics;
	variable numGlyphs;
	variable widths;
	variable chars;
	variable postScriptName;
	variable Embeddable;
	variable Bold;
	variable typoAscender;
	variable typoDescender;
	variable capHeight;
	variable italicAngle;
	variable underlinePosition;
	variable underlineThickness;
	variable isFixedPitch;

proc  Parse { file } {
	variable f; variable tables;
	
		if {[catch {open $file "rb"} f ]} {
			Error "Can't open file: $file ";
		}
		set version [ Read 4 ]; 
		if { $version == "OTTO" } {
			Error "OpenType fonts based on PostScript outlines are not supported" ;
		}	
		if { $version != "\x00\x01\x00\x00" } {
			Error "Unrecognized file format" ;
		}	
		set numTables [ ReadUShort ];
		Skip 6 ;# 3*2 : searchRange, entrySelector, rangeShift
		array set tables { };
		for {set i 0 } {$i<$numTables } { incr i } {
			set tag  [ Read 4 ];
			Skip 4 ;# checkSum
			set offset  [ ReadULong ];
			Skip 4 ;# length
			set tables($tag) $offset;
		}
		ParseHead;
		ParseHhea;
		ParseMaxp;
		ParseHmtx;
		ParseCmap;
		ParseName;
		ParseOS2;
		ParsePost;
		close $f;
}

proc ParseHead { } {
	variable unitsPerEm; variable xMin; variable xMax; variable yMax; variable yMin;	
		Seek "head";
		Skip 12 ;# 3*4  : version, fontRevision, checkSumAdjustment
		set magicNumber [ ReadULong ];
		if { $magicNumber != 0x5F0F3CF5 } {
			Error "Incorrect magic number";
		}	
		Skip 2 ;# flags
		set unitsPerEm [ ReadUShort ];
		Skip 16 ;# 2*8  : created, modified
		set xMin  [ ReadShort ];
		set yMin  [ ReadShort ];
		set xMax [ ReadShort ];
		set yMax [ ReadShort ];
	}

proc ParseHhea { } {
	variable numberOfHMetrics;
	
		Seek "hhea";
		Skip  34 ;# 4+15*2 
		set numberOfHMetrics [ ReadUShort ];
}

proc  ParseMaxp { } {
	variable numGlyphs;
	
		Seek "maxp";
		Skip 4;
		set numGlyphs [ ReadUShort ];
}

proc  ParseHmtx { } {
	variable numberOfHMetrics; variable widths; variable numGlyphs;
	
		Seek "hmtx";
		array set widths { };
		for { set i 0 } { $i < $numberOfHMetrics } { incr i } {
			set advanceWidth  [ ReadUShort ];
			Skip 2 ;# lsb
			set widths($i) $advanceWidth;
		}
		if { $numberOfHMetrics < $numGlyphs } {
			set lastWidth [ array get widths  [expr $numberOfHMetrics-1] ];
			set lwidths [array get widths]
			array set widths [ array_pad $lwidths $numGlyphs $lastWidth ];
		}
}

proc array_pad { _arr size value} {
	foreach {a b} $_arr {
		lappend arr "$a $b"
	}
	set orig_len [llength $arr]
	set diff [expr abs($size) - $orig_len];
	if { $diff <= 0 } {
		return $_arr	
	}
	if {$size < 0 } {
		set  idx 0
		set sign -1
	} else {    
		set idx [expr $orig_len-1];
		set sign 1
	}	
	set pointer [ lindex [lsort -integer -index 0 $arr]  "$idx 0"] 	
	for {set j 0 } {$j < $diff} {incr j} {
		set pointer [expr $pointer+$sign]
		lappend _arr $pointer $value
	}
	return  $_arr
}	

proc  ParseCmap { } {
	variable chars; variable f; variable tables;
	
		Seek "cmap";
		Skip 2 ;# version
		set numTables  [ ReadUShort ];
		set offset31 0;
		for { set i 0 } {$i<$numTables } {incr i } {
			set platformID [ ReadUShort ] ;
			set encodingID  [ ReadUShort ] ;
			set offset [ ReadULong ];
			if { $platformID==3 && $encodingID==1} {
				set offset31 $offset;
			}	
		}
		if { $offset31==0 } {
			Error "No Unicode encoding found" ;
		}	
		array set startCount { };
		array set endCount { };
		array set idDelta { };
		array set idRangeOffset { };
		array set chars { };
		seek $f [expr $tables(cmap)+$offset31] ;
		set format [ ReadUShort ];
		if { $format!=4 } {
			Error "Unexpected subtable format: $format" ;
		}	
		Skip 4 ;#2*2 ; length, language
		set segCount [expr double([ReadUShort] /2)];
		Skip 6 ;# 3*2  ; searchRange, entrySelector, rangeShift
		for { set i 0} {$i<$segCount} {incr i } {
			set endCount($i) [ ReadUShort ];
		}	
		Skip 2 ;# reservedPad
		for {set i 0 } { $i<$segCount } { incr i } {
			set startCount($i) [ ReadUShort ];
		}	
		for {set i 0} {$i<$segCount} {incr i } {
			set idDelta($i)  [ ReadShort ];
		}	
		set offset [ tell $f ];
		for {set i 0} {$i<$segCount} { incr i } {
			set idRangeOffset($i) [ ReadUShort ];
		}
		for { set i 0} {$i<$segCount} { incr i } {
			set c1 $startCount($i);
			set c2 $endCount($i);
			set d $idDelta($i);
			set ro $idRangeOffset($i);
			if { $ro>0 } {
				seek $f [expr $offset+2*$i+$ro];
			}	
			for {set c $c1} {$c <= $c2 } { incr c} {
				if { $c==0xFFFF } {
					break;
				}	
				if { $ro>0 } {
					set gid  [ ReadUShort ];
					if { $gid>0 } {
						set gid [expr $gid + $d];
					}
				} else {
						set gid [expr $c+$d];
				}	
				if { $gid >= 65536 } {
					set gid [expr $gid - 65536];
				}	
				if { $gid>0 } {
					set chars($c) $gid;
				}	
			}
		}
}

proc  ParseName { } {
	variable f; variable postScriptName;
	
		Seek "name";
		set tableOffset [tell $f];
		set postScriptName "";
		Skip 2 ;# format
		set count [ ReadUShort ];
		set stringOffset [ ReadUShort ];
		for { set i 0 } { $i < $count } {incr i } {
			Skip 6 ;#3*2; platformID, encodingID, languageID
			set nameID [ ReadUShort ];
			set length [ ReadUShort ];
			set offset [ ReadUShort ];
			if { $nameID == 6 }	{
				;# PostScript name
				seek $f [expr $tableOffset+$stringOffset+$offset] ;
				set s  [Read $length ];
				regsub -all "[format %c 0]|\\s" $s "" s
				set postScriptName $s;
				break;
			}
		}
		if { $postScriptName == "" } {
			Error "PostScript name not found";
		}	
}

proc  ParseOS2 { } {
	variable typoAscender;variable typoDescender; variable Embeddable;	
	variable Bold; variable capHeight;
	
		Seek "OS/2";
		set version [ ReadUShort ];
		Skip 6 ;# 3*2 ; xAvgCharWidth, usWeightClass, usWidthClass
		set fsType [ ReadUShort ];
		set Embeddable [ expr $fsType!=2 &&  ($fsType & 0x200) ==0] ;
		Skip 52 ; # 11*2+10+4*4+4 ;
		set fsSelection [ ReadUShort ];
		set Bold [ expr $fsSelection & 32!=0 ];
		Skip 4 ;#  2*2  ;# usFirstCharIndex, usLastCharIndex
		set typoAscender  [ ReadShort ];
		set typoDescender  [ ReadShort ];
		if { $version>=2 } {
			Skip 34;# 3*2+2*4+2 ;
			set capHeight [ ReadShort ];
		} else {
			set capHeight 0;
		}	
}

proc  ParsePost { } {
	variable underlinePosition; variable underlineThickness; 
	variable isFixedPitch; variable italicAngle;
	
		Seek "post";
		Skip 4 ;# version
		set italicAngle [ ReadShort ];
		Skip 2 ;# Skip decimal part
		set underlinePosition [ ReadShort ];
		set underlineThickness [ ReadShort ];
		set isFixedPitch [ expr [ReadULong] !=0 ];
}

proc  Seek { tag } {
	variable f; variable tables;
	
		if { [array get tables $tag] == -1 } {
			Error "Table not found: $tag" ;
		}	
		seek $f $tables($tag);
}

proc  Skip { n } {
	variable f;
	
		seek $f $n current;
}

proc  Read { n } {
	variable f;
	
		return [ read $f $n ];
}

proc  ReadUShort { } {
	variable f;
	
		binary scan [read $f 2] Su a ;
		return $a;
}

proc  ReadShort { } {
	variable f;
	
		binary scan [read $f 2] S a;
		return $a;
}

proc  ReadULong { } {
	variable f;
	
		binary scan [read $f 4] IuIu a b;
		return $a;
}