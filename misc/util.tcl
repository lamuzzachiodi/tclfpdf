;# Here are some proc mimicking php functions and other functions
;# --- Encoded in utf-8 (if you see vocals with accent -> áéíóú) ---

;# --- isset ----
proc isset { var {indeep 1} } {
# $var exists and $var != ""
	set par {};
	set arepar [string first ( [string trim $var]];#are there parentheses ?
	set nom $var;
	if { $arepar !=-1} {
		set long [string length $var];#
		if {$long > [expr $arepar+1] } {
			set nom [string range $var 0 [expr $arepar-1]]
			set prepar [string range $var $arepar $long ]
			set par [string map { "(" "" ")" "" } $prepar]
		}
	}
	set thelevel [expr [info level] -1]
	set bak $nom
	set exists 0
	if {$indeep==1} {
		set ns [uplevel 1 {namespace current}];
		if { [string first $ns $nom] == -1 } {  
			set nom $ns\:\:$nom;
		}	
		variable $nom
		#~ set nom [namespace which -variable $nom ]
	} 	
	if {![info exist $nom] } {
		set nom $bak
		for {} {$thelevel > -1 } {set thelevel [expr $thelevel -1]} {
			if [uplevel #$thelevel "info exists $nom" ] {
				upvar #$thelevel $nom value
				if { [array exists value] } {
					array set $nom [array get value];
				} elseif { $value != "" } {
					return 1;
				}	
				set exists 1;
				break;
			}
		}
		if { !$exists } {
			return 0;
		}
	} elseif  {![array exists $nom]} { ;# the variable isn't array
		if { $nom != "" }  {return 1} ;# if the variable exists and the variable isn't empty  
		return 0;
	}	
	if {$par == "" } {
		set par "*";
	}
	set list_arr [array get $nom $par];
	if {$list_arr == ""}  { return 0}
	foreach { key val} $list_arr {
		if {$val == ""} {return 0}
	}		
	return 1;
}


proc _ordarray { arr {type integer}} {
	# Use ascii for char, really is unicode sort
	upvar $arr a;
	return [lsort -index 0 -$type -stride 2 [array get a]]
}

proc _ordarraybool { arr } {
	upvar $arr a;
	foreach {k v} [array get a] {	
		if {$v == true} {
			set l2($k) $v
		} else {
			set l1($k) $v
		}
	}
	return [concat [_ordarray l1] [array get l2]];
}

proc _getList2Arr { lista val } {
# Convert list to array and return index val
	array set arr $lista;
	if {[expr  [lsearch -exact $lista $val] % 2] !=0} {
		return {};#  even; is not index or is -1
	} else {	
		return $arr($val); # odd, is index
	}
}

proc _setSubList { lista val newitem } {
# Add new item in a list that really is an array item 
# val is really the array name and newitem must be append to it
	upvar $lista lista1
	set idx [lsearch $lista1 $val] 
	if {$idx > -1} {
		incr idx;
		set oldl [lindex $lista1 $idx]
		set lmas [lappend  oldl $newitem]
		lset lista1 $idx $lmas
	}
}


proc _lenbool { lbool } {
	return [expr [llength $lbool] /2];
}

proc _stringToLArray { str } {
	set tmp {};
	set l [string length $str];
	for {set x 0} {$x<$l} {incr x} {
		set chr "[string index $str $x]";
		append tmp " $x \{\\$chr\}";
	}
	return $tmp;
}

proc _getchar { str pos} {
	# if pos doesn't exist return ""
	return [string index $str $pos]
}

proc  _findchar { str char } {
	array set arr $str;
	return $arr($char);
}

proc  _lremove { list value } {
#remove value from list
	upvar $list l;
	if {$value eq "end" } {
		set l [lreplace $l end end];
	} else {
		set l [lsearch -all -inline -not -exact $l $value];
	}	
}

proc _countVal { lista } {
# return total of distinct values in the list
	array set counter {}
	foreach item $lista {
		incr 	counter($item)	
	}
	return [array size counter]
}

proc _setchar { str pos char} {
	upvar $str s;
	set s [string replace $s $pos $pos $char]	
}

proc _lsetarr { list idx newval } {
	upvar $list l;
	set pos [expr [lsearch $l $idx]+1];
	set l  [lreplace $l $pos $pos $newval];
}

proc _lunsetsubarr { arr idx subidx} {
#delete sub-array
	upvar $arr a;
	array set subarr $a($idx);
	if [info exists subarr($subidx)] {	
		unset subarr($subidx);
		set a($idx)  [array get subarr];
	}	
}

proc _substr { str start {length "all"}} {
	if {$length eq "all"} {
		set length [expr [string length $str] - $start] 
	}
	set last [expr $start + $length-1]
	return [string range $str $start $last];
}


proc _substr_replace {str new start length}  {
	set last [expr $start+$length-1]
	return [string replace $str $start $last $new]
}

proc utf8substr { str start {length "all"}} {
	set len [string length $str];
	if {$length == "all"} {
		set length [expr $len - $start]
	}
	if {$start >= $len || $length < 1} {
		return "";
	}
	set last [expr $start + $length -1]
	if {[utf8len $str] == $len} {
		return [string range $str $start $last]
	}
	set usado 0;
	set charn -1;
	set i  -1;
	set sub "";
	while {$i<$len-1} {
		set c [scan  [string index $str [incr i]] %c]
		set step 1;
		if {($c & 0xc0) == 0xc0 } { #start of multibyte
			if { ($c & 192) ==192 } {set step 2}
			if { ($c & 224) ==224 } {set step 3}
			if { ($c & 240) ==240 } {set step 4}
		} 
		incr charn;
		set j [expr $i + $step-1 ];
		if {$charn >=$start && $usado <$length} {
			set slice [string range $str $i $j];
			append sub $slice;
			incr usado;
		}
		if {$usado >= $length} break;
		set i $j ;
	}
	return $sub
}

proc utf8len { str } { 
	set j 0;
	set str [encoding convertto [encoding system] $str ]
	foreach char [split $str {}] {
		set code  [scan $char %c]
		if { ($code & 0xc0) != 0x80}   {
			incr j;
		}
	}
	return $j;
}

proc utf8reverse { s } {
	set s [encoding convertto [encoding system] $s ]
	set len [string length $s];
	set s [string reverse $s];
	set i  -1;
	while {$i<$len-1} {
		set c [scan  [string index $s [incr i]] %c]
		if {($c & 0xc0) == 0xc0 } { #start of multibyte
			set ret 0;
			if { ($c & 192) ==192 } {set ret 2}
			if { ($c & 224) ==224 } {set ret 3}
			if { ($c & 240) ==240 } {set ret 4}
			set f [expr $i-$ret+1];
			set s [string replace $s $f $i [string reverse [string range $s $f $i]]]
		}
	}	
	return [encoding convertfrom [encoding system] $s ];
}

proc convertirAlocal { s } {
# verify if the string have system's cod
# if compare is 1 must be converted to local cod.
	set s1 [encoding convertto $s]
	set s2 [encoding convertfrom $s1]
	return [ expr ![string compare $s $s2] ]
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


proc array2list { lis {sep "," } {esc 0} } {
# return a list expanding a bidimensional array as an array of lists
# this way can convert each item in an array 
	array set _arr {}
	foreach {k  v}   $lis {
		set subk  [ split $k $sep ] ;
		set idx [lindex $subk 0 ] ;
		set idx2 [lindex $subk 1 ] ;
		if { $esc==1   && ![string is integer $v]} {
			set v [string map [list \u005C \u005C\u005C] $v]; #
			set v [string map [list \u0022 \u005C\u0022] $v]; #
		}
		append _arr($idx) "$idx2 \"$v\" ";
	}
	return [array get _arr];
}

proc unescapearr { arr } {
	upvar $arr a;
	foreach {k v } list {
		if { ![string is integer $v]} {
			set v [string map [list \u005C\u0022 \u0022 ]  $v]; #
			set v [string map [list \u005C\u005C \u005C ] $v]; #
			set a($k) $v;
		}
	}
}

proc bin2hex { str} {
	set hex {};
	binary scan $str H* hex;
	return $hex;
}

proc random {min max} {
    return [expr {int(rand()*($max-$min+1)+$min)}]
}

proc _procexists { p } {
   return [uplevel 1 expr [llength [info procs $p]] > 0]
}