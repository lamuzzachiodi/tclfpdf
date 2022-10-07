;# *******************************************************************************
;# *******************************************************************************
;# * Utility to parse TTF font files
;#    Version 1.1 (2020)
;# * Ported to TCL by L.A. Muzzachiodi
;# * Credit:
;#  	Version: 1.1 (2019) by Olivier PLATHEY
;# *******************************************************************************

	variable f;
	variable tables;
	variable numberOfHMetrics;
	variable numGlyphs;
	variable glyphNames;
	variable indexToLocFormat;
	variable subsettedChars {};
	variable subsettedGlyphs {};
	variable chars;
	variable glyphs;
	variable unitsPerEm;
	variable xMin;
	variable yMin;
	variable xMax
	variable yMax;
	variable postScriptName;
	variable embeddable;
	variable bold;
	variable typoAscender;
	variable typoDescender;
	variable capHeight;
	variable italicAngle;
	variable underlinePosition;
	variable underlineThickness;
	variable isFixedPitch;


proc ParseInit { file} {
	variable f; 

	if {[catch {open $file "rb"} f ]} {
		Error "Can't open file: $file ";
	}
}


proc ParseEnd {  } {
	variable f; 

	close $f;
}


proc Parse { } {
	ParseOffsetTable;
	ParseHead;
	ParseHhea;
	ParseMaxp;
	ParseHmtx;
	ParseLoca;
	ParseGlyf;
	ParseCmap;
	ParseName;
	ParseOS2;
	ParsePost;

}

proc ParseOffsetTable {} {
	variable tables;

	set version [ Read 4 ]; 
	if { $version == "OTTO" } {
		Error "OpenType fonts based on PostScript outlines are not supported" ;
	}	
	if { $version != "\x00\x01\x00\x00" } {
		Error "Unrecognized file format" ;
	}	
	set numTables [ ReadUShort ];
	Skip 6 ;# 3*2 : searchRange, entrySelector, rangeShift
	array unset tables *;
	for {set i 0 } {$i<$numTables } { incr i } {
		set tag  [ Read 4 ]; # LAM: cvt add an empty space
		set checkSum [ Read 4 ];
		set offset  [ ReadULong ];
		set length [ ReadULong ]; # LAM: there is 4 in the original. It's an error
		set tables($tag,offset) $offset;
		set tables($tag,length) $length;
		set tables($tag,checkSum) $checkSum;
	}
}

proc ParseHead { } {
	variable unitsPerEm; 
	variable xMin; variable xMax; variable yMax; variable yMin;
	variable indexToLocFormat;	
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
	Skip 6 ;#(3*2) macStyle, lowestRecPPEM, fontDirectionHint
	set indexToLocFormat  [ ReadShort ];
	}

proc ParseHhea { } {
	variable numberOfHMetrics;
	
	Seek "hhea";
	Skip  34 ;# 4+15*2 
	set numberOfHMetrics [ ReadUShort ];
}

proc ParseMaxp { } {
	variable numGlyphs;
	
	Seek "maxp";
	Skip 4;
	set numGlyphs [ ReadUShort ];
}

proc ParseHmtx { } {
	variable numberOfHMetrics; 
	variable widths; 
	variable numGlyphs;
	variable glyphs;
	
	Seek "hmtx";
	array unset glyphs *;
	for { set i 0 } { $i < $numberOfHMetrics } { incr i } {
		set advanceWidth  [ ReadUShort ];
		set lsb [ ReadShort ];
		set glyphs($i,w) $advanceWidth;
		set glyphs($i,lsb) $lsb;
	}
	for {set i $numberOfHMetrics} {$i < $numGlyphs} { incr i } {
		set lsb [ ReadShort ];
		set glyphs($i,w) $advanceWidth;
		set glyphs($i,lsb) $lsb;
	}
}

proc ParseLoca {} {

       variable indexToLocFormat;
       variable numGlyphs;
       variable glyphs;

	Seek "loca";
	array set offsets {};
	set idx -1
	if {$indexToLocFormat==0 } {
		#Short format
		for {set i 0} { $i<=$numGlyphs} { incr i } {
			incr idx;
			set offsets($idx) [expr 2* [ ReadUShort]];
		}	
	} else {
		# Long format
		for { set i 0} { $i<=$numGlyphs} { incr i } {
			incr idx;
			set offsets($idx) [ReadULong ];
		}
	}
	for {set i 0} { $i<$numGlyphs} { incr i } {
		set glyphs($i,offset)  $offsets($i);
		set _i [ expr $i+1]
		set glyphs($i,length)  [expr $offsets($_i) - $offsets($i)];
	}
}
	

proc ParseGlyf {} {

	variable tables;
	variable glyphs;
	variable f;
	
	set tableOffset $tables(glyf,offset);
	set l_glyph [array2list [array get glyphs]];
	foreach {k_glyph v_glyph} $l_glyph    { ;# &glyph in php
		array unset glyph *;
		array set glyph $v_glyph;
		if {$glyph(length) >0 } {
			seek $f [expr $tableOffset+$glyph(offset)] start;
			if { [ ReadShort ] < 0 } {
				# Composite glyph
				Skip 8 ;#(4*2) xMin yMin  xMax yMax
				set offset 10 ;# 5*2; 
				array unset a *;
				while 1 {
					set flags  [ReadUShort];
					set index [ReadUShort];
					set o2 [expr $offset+2];
					set a($o2) $index;
					if {$flags & 1 }  {
						# ARG_1_AND_2_ARE_WORDS
						set skip 4;# 2*2;
					} else {
						set skip 2;
					}	
					if {$flags & 8} {
					        # WE_HAVE_A_SCALE
						incr skip 2;
					} elseif {$flags & 64} {
						#WE_HAVE_AN_X_AND_Y_SCALE
						set skip [expr $skip + 2*2];
					} elseif {$flags & 128} {
						#WE_HAVE_A_TWO_BY_TWO
						set skip [expr $skip + 4*2];
					}	
					Skip $skip;
					set offset [expr $offset + 2*2 + $skip];
					if {!($flags & 32)} break; # MORE_COMPONENTS
				}
				set glyphs($k_glyph,components) [array get a];
			}
		}
	}
}

proc ParseCmap { } {
	variable chars; 
	variable f; 
	variable tables;
	
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
	array unset startCount *;
	array unset endCount *;
	array unset idDelta *;
	array unset idRangeOffset *;
	array unset chars *;
	seek $f [expr $tables(cmap,offset) +$offset31] ;
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
	variable f; 
	variable postScriptName;
	variable tables;
	
	Seek "name";
	set tableOffset $tables(name,offset);
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
			#~ regsub -all "[format %c 0]|\\s" $s "" s
			set s [string map [list \x00 "" \[ "" \] "" \( "" \) "" \{ "" \} "" \< "" \> "" \/ "" \% "" " " ""]  $s ]
			set postScriptName $s;
			break;
		}
	}
	if { $postScriptName == "" } {
		Error "PostScript name not found";
	}	
}

proc ParseOS2 { } {
	variable typoAscender;variable typoDescender; variable embeddable;	
	variable bold; variable capHeight;
	
		Seek "OS/2";
		set version [ ReadUShort ];
		Skip 6 ;# 3*2 ; xAvgCharWidth, usWeightClass, usWidthClass
		set fsType [ ReadUShort ];
		set embeddable [ expr $fsType!=2 &&  ($fsType & 0x200) ==0] ;
		Skip 52 ; # 11*2+10+4*4+4 ;
		set fsSelection [ ReadUShort ];
		set bold [ expr $fsSelection & 32!=0 ];
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

proc ParsePost { } {
	variable underlinePosition; variable underlineThickness; 
	variable isFixedPitch; variable italicAngle;
	variable numGlyphs; variable glyphs;
	variable glyphNames;
	
	Seek "post";
	set version [ ReadULong ];
	set italicAngle [ ReadShort ];
	Skip 2 ;# Skip decimal part
	set underlinePosition [ ReadShort ];
	set underlineThickness [ ReadShort ];
	set isFixedPitch [ expr [ReadULong] !=0 ];
	if {$version==0x20000} {
		# Extract glyph names
		Skip 16;# (4*4) min/max usage
		Skip 2;# numberOfGlyphs
		array unset glyphNameIndex *;
		set gni_idx -1;
		array set names {};
		set numNames 0;
		for {set i 0} {$i<$numGlyphs} { incr i} {
			set index [ReadUShort];
			incr gni_idx;
			set glyphNameIndex($gni_idx) $index;
			if {$index>=258 && $index-257>$numNames } {
				set numNames [expr $index-257];
			}
		}
		set n_idx -1;
		for {set i 0} { $i<$numNames} {incr i } {
			set len [scan [Read 1] %c];
			incr n_idx;
			set names($n_idx) [Read $len];
		}
		foreach { i index } [_ordarray glyphNameIndex]  {
			if {$index>=258 } {
				set glyphs($i,name) $names([expr $index-258]);
			}  else {
				set glyphs($i,name) $index;
			}	
		}
		set glyphNames 1;
	} else {
		set glyphNames 0;
	}		
}

proc Subset { _chars } {
	variable subsettedChars;
	variable chars;
	variable subsettedGlyphs;

	set numc 0
	AddGlyph 0;
	set subsettedChars {};
	foreach  {k char} $_chars {		
		if { [isset chars($char)] } {		
			lappend subsettedChars $char;
			AddGlyph $chars($char);
		} 
	}
}

proc AddGlyph { id } {
	variable glyphs;
	variable subsettedGlyphs;

	if {![ isset glyphs($id,ssid)]} {
		set glyphs($id,ssid) [llength $subsettedGlyphs];
		lappend subsettedGlyphs $id;
		if {[isset glyphs($id,components)]} {
			foreach { idx cid } $glyphs($id,components) {
				AddGlyph $cid ;
			}
		}
	}
}

proc Build { } {

	BuildCmap;
	BuildHhea;
	BuildHmtx;
	BuildLoca;
	BuildGlyf;
	BuildMaxp;
	BuildPost;
	return [BuildFont];
}

proc BuildCmap {} {
	variable subsettedChars;
	variable chars;
	variable glyphs;
		
	if {! [isset subsettedChars]} {
		return;
	}	
	# Divide charset in contiguous segments
	set _chars [lsort -integer $subsettedChars] ;
	array set segments {};
	set s_idx -1;
	set lchars_0 [lindex $_chars 0];
	array set segment " 0 $lchars_0 1 $lchars_0 ";
	for {set i 1} { $i< [llength $_chars] } {  incr i } {
		set lchars_i [lindex $_chars $i];
		if { $lchars_i > [expr $segment(1)+1] } { 
			set segments([incr s_idx]) [array get segment];
			array set segment  "0 $lchars_i 1 $lchars_i ";
		} else { 
				incr segment(1);
		}
	}	
	set segments([incr s_idx]) [array get segment];
	set segments([incr s_idx]) " 0 [expr 0xFFFF] 1 [expr 0xFFFF]";
	set segCount [array size segments];

	# Build a Format 4 subtable
	array set startCount {};
	set sc_idx -1;
	array set endCount {};
	set ec_idx -1;
	array set idDelta {};
	set id_idx -1;
	array set idRangeOffset {};
	set iro_idx -1;
	set glyphIdArray {};
	set start {};
	set end {};
	for {set i 0} {$i<$segCount} { incr i } {
		array set _segments $segments($i);
		set start  $_segments(0);
		set end  $_segments(1);
		set startCount([ incr sc_idx]) $start;
		set endCount([incr ec_idx]) $end;
		if {$start!=$end } { 
			# Segment with multiple chars
			set idDelta([incr id_idx]) 0;
			set idRangeOffset([incr iro_idx]) [expr [string len $glyphIdArray] + ($segCount-$i)*2];
			for {set c $start} {$c<=$end} {incr c} {			
				set ssid $glyphs($chars($c),ssid);
				append glyphIdArray [ binary format "Su" $ssid ];
			}
		} else {
			# Segment with a single char
			if {$start< 0xFFFF} {
				set ssid $glyphs($chars($start),ssid);
			} else {
				set ssid 0;
			}	
			set idDelta([incr id_idx])  [expr $ssid - $start];
			set idRangeOffset([incr iro_idx]) 0;
		}
	}
	set entrySelector 0;
	set n $segCount;
	while {$n!=1} {
		set n [expr $n>>1];
		incr entrySelector;
	}
	set searchRange  [expr (1<<$entrySelector)*2];
	set rangeShift [expr 2*$segCount - $searchRange];
	set cmap [binary format "SuSuSuSu" [expr 2*$segCount] $searchRange $entrySelector $rangeShift];
	foreach {_k val} [_ordarray endCount]  {
		append cmap [binary format "Su" $val];
	}	
	append cmap [binary format "Su" 0]; # reservedPad
	foreach { _k val } [_ordarray startCount] {
		append cmap [binary format "Su" $val];
	}	
	foreach { _k val} [_ordarray idDelta] {
		append cmap [binary format "Su" $val];

	}	
	foreach { _k val}  [_ordarray idRangeOffset] {
		append cmap [binary format "Su" $val];
	}
	append cmap $glyphIdArray;
	set data  [binary format "SuSu" 0 1];; # version, numTables
	append data [binary format "SuSuI" 3 1 12]; # platformID, encodingID, offset
	append data [binary format "SuSuSu" 4 [expr 6+[string len $cmap]] 0]; # format, length, language
	append data $cmap;
	SetTable cmap $data;
}

proc BuildHhea {} {

	variable subsettedGlyphs;
	variable tables;

	LoadTable hhea;
	set numberOfHMetrics  [llength $subsettedGlyphs];
	set data  [_substr_replace $tables(hhea,data) [binary format Su $numberOfHMetrics] 34 2 ]; 
	SetTable hhea $data;
}

proc BuildHmtx {} { 
	variable subsettedGlyphs;
	variable glyphs;

	array set l_glyph [array2list [array get glyphs]];
	set data {};
	foreach  id $subsettedGlyphs {
		array unset glyph *;
		array set glyph $l_glyph($id);
		append data [binary format "SuSu" $glyph(w) $glyph(lsb)];
	}
	SetTable hmtx $data;
}

proc BuildLoca {} {
	variable subsettedGlyphs;
	variable indexToLocFormat;
	variable glyphs;

	set data {};
	set offset 0;
	foreach id $subsettedGlyphs {
		if {$indexToLocFormat==0} {
			append data [binary format "Su" [expr $offset/2]];
		} else {
			append data [binary format "I" $offset];		
		}
		set offset [expr $offset + $glyphs($id,length)];
	}
	if {$indexToLocFormat==0 } {
		append data [binary format "Su" [expr $offset/2]];
	 } else {
		append data [binary format "I" $offset];
	}	
	SetTable loca $data;
}

proc BuildGlyf {} {
	variable tables;
	variable subsettedGlyphs;
	variable glyphs;
	variable f;

	set tableOffset $tables(glyf,offset);
	set data {};

	array set lglyphs [array2list [array get glyphs]];

	foreach  id $subsettedGlyphs {
		array unset glyph *; 
		array set glyph $lglyphs($id);
		seek $f [expr $tableOffset+$glyph(offset)] ;
		set glyph_data [ Read $glyph(length) ];
		if { [isset glyph(components) 0]} {
			# Composite glyph
			foreach { offset cid } [lsort -index 0 -integer -stride 2 $glyph(components)] {
				set ssid $glyphs($cid,ssid);
				set glyph_data [ _substr_replace $glyph_data [binary format "Su" $ssid] $offset 2 ];
			}
		}
		append data $glyph_data;		
	}
	SetTable glyf $data;
}

proc BuildMaxp {} {
	variable subsettedGlyphs;
	variable tables;

	LoadTable maxp;
	set numGlyphs  [llength $subsettedGlyphs];
	set data [ _substr_replace $tables(maxp,data) [binary format "Su" $numGlyphs] 4 2];
	SetTable maxp $data;
}

proc BuildPost {} {
	variable glyphNames;
	variable subsettedGlyphs;
	variable glyphs;

	Seek post;	
	if {$glyphNames} {
		# Version 2.0
		set numberOfGlyphs  [llength $subsettedGlyphs];
		set numNames 0;
		set names {};
		set data [ Read [expr 2*4+2*2+5*4]];
		append data [binary format "Su" $numberOfGlyphs];
		foreach  id $subsettedGlyphs {
		 	set name $glyphs($id,name);
			if { ![string is integer $name] } {
				append data [binary format "Su" [expr 258+$numNames]];
				append names "[format %c [string len $name]]$name";
				incr numNames;
			} else {
				append data [binary format "Su" $name];
			}
		}
		append data $names;
	} else {
		# Version 3.0
		Skip 4;
		set data "\x00\x03\x00\x00";
		append data  [ Read [expr 4+2*2+5*4]];
	}
	SetTable post $data;
}

proc BuildFont {} {
	variable tables;

	array set tags {};
	set t_idx -1;
	set ltags [list cmap "cvt " fpgm glyf head hhea hmtx loca maxp name post prep];
	foreach  tag $ltags {
		if {[isset tables($tag,* ]} {
			set tags([incr t_idx]) $tag;
		}
	}
	set numTables [array size tags];
	set offset [expr 12 + 16*$numTables];
	foreach  {k tag } [array get tags]  {
		if { ! [isset tables($tag,data)] } {
			LoadTable $tag;
		}
		set tables($tag,offset) $offset;
		set offset  [expr $offset + [ string len $tables($tag,data)]];
	}
#	$this->tables['head']['data'] = substr_replace($this->tables['head']['data'], "\x00\x00\x00\x00", 8, 4);

	# Build offset table
	set entrySelector 0;
	set n $numTables;
	while {$n!=1 } {
		set n [expr  $n>>1];
		incr entrySelector;
	}
	set searchRange  [expr 16*(1<<$entrySelector)];
	set rangeShift [expr 16*$numTables - $searchRange];
	set offsetTable [binary format "SuSuSuSuSuSu" 1 0 $numTables $searchRange $entrySelector $rangeShift];
	array set _tables [array2list [array get tables] "," 1]
	foreach {k tag } [array get tags] {
		array unset _table *;
		array set _table $_tables($tag);
		unescapearr _table;
		append offsetTable "$tag$_table(checkSum)[binary format II $_table(offset) $_table(length)]";
		set offsetTable2 "[binary format II $_table(offset) $_table(length)]";
	}
	# Compute checkSumAdjustment (0xB1B0AFBA - font checkSum)
	set s [CheckSum $offsetTable];
	foreach {k tag}  [array get tags] {
		append s $tables($tag,checkSum);
	}	
	binary scan [CheckSum $s] "SuSu" a1 a2 ;
	set high [expr 0xB1B0 + ($a1^0xFFFF)];
	set low [expr  0xAFBA + ($a2^0xFFFF) + 1];
	set checkSumAdjustment [binary format "SuSu" [expr $high+($low>>16)] $low];
	set tables(head,data) [_substr_replace $tables(head,data) $checkSumAdjustment 8 4 ];
	set font $offsetTable;
	foreach {k tag} [array get tags] {
		append font $tables($tag,data);
	}
	return $font;
}

proc LoadTable { tag } {
	variable tables;

	Seek $tag;
	set length $tables($tag,length);
	set n [expr $length % 4];
	if {$n>0} {
		set length [expr $length+ 4 - $n];
	}	
	set tables($tag,data)  [ Read $length ];
}

proc SetTable {tag data} {
	variable tables;

	set length [string len $data];
	binary scan $data H* hex;
	set n [expr $length % 4];
	if { $n>0 } {
		append data [string repeat \x00 [expr ($length+4-$n)-$length]];# string pad
	}
	set tables($tag,data) $data;
	set tables($tag,length) $length;
	set tables($tag,checkSum)  [ CheckSum $data];
}


proc Seek { tag } {
	variable f; 
	variable tables;
	
	if {! [isset tables($tag,*) ] } {
		Error "Table not found: $tag" ;
	}	
	seek $f $tables($tag,offset);
}

proc Skip { n } {
	variable f;
	
	seek $f $n current;
}

proc Read { n } {
	variable f;
	
	set d "";
	if { $n>0 } {
		set d [ read $f $n ];
	}
	return $d;
}

proc  ReadUShort { } {
	variable f;
	
	binary scan [read $f 2] Su a ;
	return $a;
}

proc ReadShort { } {
	variable f;
	
	binary scan [read $f 2] S a;
	#~ if {$a >=0x8000 } {
		#~ set a [expr $a - 65536];
	#~ }
	return $a;
}

proc ReadULong { } {
	variable f;
	
	binary scan [read $f 4] IuIu a b;
	return $a;
}

proc CheckSum { s } {

	set n [ string len $s];
	binary scan $s H* hex;
	set high 0;
	set low 0;
	for { set i 0} {$i<$n} {incr i 4} {
		set si [_getchar $s $i]:
		set si2 [_getchar $s [expr $i+2]]:
		set si1 [_getchar $s [expr $i+1]]:
		set si3 [_getchar $s [expr $i+3]]:
		set high [expr $high+  [ expr [scan $si %c] <<8 ] + [scan $si1 %c ]];
		set low [expr $low + [ expr [scan $si2 %c]<<8 ]  + [scan $si3 %c ]];
	}
	return [binary format "SuSu" [expr $high+($low>>16)] $low];
}