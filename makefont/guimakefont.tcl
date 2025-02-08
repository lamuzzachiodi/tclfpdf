package require Tk
source makefont.tcl

encoding system utf-8

set _initialdir [pwd]
set _typedialog tk
set _file {}
set _typencode "int"
set _encode {}
set _encodeint "cp1252 (Western Europe)"
set _encodeext {}
set _embed 1
set _subset 1

wm title . "Makefont Gui Wrapper"
wm resizable . 0 0

# toplevel for search fonts
set w .treew
toplevel $w
wm title $w "Directory Browser"
wm iconname $w "tree"
wm resizable $w 0 0
wm protocol $w WM_DELETE_WINDOW "Close_findfonts"
wm withdraw $w
#-----------------------------------


	ttk::labelframe .f -text "Parameters" -width 300
	
	ttk::labelframe .f.fo -text "Font:"; 
	
	ttk::label .f.fo.lid -text "Search in ";
	ttk::combobox .f.fo.cid -width 40 -textvariable _initialdir -state normal -values [list {*}$::makefont::MF_FONTS $makefont::MF_USERPATH];

	ttk::label .f.fo.lsw -text "Search with";
	ttk::radiobutton .f.fo.cbtk -text "Tk dialog" -variable _typedialog -value tk -command "";
	ttk::radiobutton .f.fo.cbint -text "Built-in" -variable _typedialog -value int -command "";

	ttk::label .f.fo.lfil -text "Font file:";
	ttk::entry .f.fo.efil -width 50 -textvariable _file
	ttk::button .f.fo.bfil -text "..." -command OpenFileFont -width 5
	
	ttk::labelframe .f.fe -text "Encode:"; 
	ttk::radiobutton .f.fe.cbint -text "Buit-in" -variable _typencode -value int -command "toggle_encode int";
	ttk::radiobutton .f.fe.cbext -text "Other" -variable _typencode -value ext -command "toggle_encode ext";
	ttk::combobox .f.fe.denc -width 30 -textvariable _encodeint -state readonly -values [list  \
	{ cp1250 (Central Europe) } \
	{ cp1251 (Cyrillic)  } \
	{ cp1252 (Western Europe) } \
	{ cp1253 (Greek) } \
	{ cp1254 (Turkish) } \
	{ cp1255 (Hebrew) } \
	{ cp1257 (Baltic) } \
	{ cp1258 (Vietnamese) } \
	{ cp874 (Thai) } \
	{ ISO-8859-1 (Western Europe) } \
	{ ISO-8859-2 (Central Europe) } \
	{ ISO-8859-4 (Baltic) } \
	{ ISO-8859-5 (Cyrillic) } \
	{ ISO-8859-7 (Greek) } \
	{ ISO-8859-9 (Turkish) } \
	{ ISO-8859-11 (Thai) } \
	{ ISO-8859-15 (Western Europe) } \
	{ ISO-8859-16 (Central Europe) } \
	{ KOI8-R (Russian) } \
	{ KOI8-U (Ukrainian) } ]
	ttk::entry .f.fe.eenc -width 50 -textvariable _encodeext -state disabled
	ttk::button .f.fe.benc -text "..." -command OpenFileEncode -width 5 -state disabled
	
	checkbutton .f.cemb -text "Embed ?" -variable _embed -relief flat 
	checkbutton .f.csub -text "Subset ?" -variable _subset -relief flat
	
	ttk::label .f.lupath -text "Save in (path) ?:"
	ttk::entry .f.eupath -width 50 -textvariable ::makefont::MF_USERPATH
	ttk::button .f.bupath -text "..." -command OpenDirUser -width 5

	grid .f.fo.lid -row 0 -column 0 -sticky ne -padx 5 -pady 5;
	grid .f.fo.cid -row 0 -column 1 -sticky nw -padx 5 -pady 5 -columnspan 2;
	grid .f.fo.lsw -row 1 -column 0 -padx 5 -pady 5; 
	grid .f.fo.cbtk -row 1 -column 1 -padx 5 -pady 5 -sticky w; 
	grid .f.fo.cbint -row 1 -column 2 -padx 5 -pady 5 -sticky w; 

	grid .f.fo.lfil -row 2 -column 0 -sticky ne -padx 5 -pady 5;
	grid .f.fo.efil -row 2 -column 1 -sticky nw -padx 5 -pady 5 -columnspan 2;
	grid .f.fo.bfil -row 2 -column 3 -sticky nw -padx 5 -pady 5;
	grid .f.fo -row 0 -column 0 -sticky new -padx 5 -pady 5 -columnspan 3;
	# encode
	grid .f.fe.cbint -row 0 -column 0 -padx 5 -pady 5; 
	grid .f.fe.denc -row 0 -column 1 -sticky w -padx 5 -pady 5 ;
	grid .f.fe.cbext -row 1 -column 0 -padx 5 -pady 5;
	grid .f.fe.eenc -row 1 -column 1 -sticky e -padx 5 -pady 5 ;
	grid .f.fe.benc -row 1 -column 2 -sticky e -padx 5 -pady 5 ;	
	grid .f.fe -row 2 -column 0 -sticky new -padx 5 -pady 5 -columnspan 3
	# ---
	grid .f.cemb -row 3 -column 1 -sticky nw -padx 5 -pady 5
	grid .f.csub -row 4 -column 1 -sticky nw -padx 5 -pady 5
	
	grid .f.lupath -row 5 -column 0 -sticky new -padx 5 -pady 5;
	grid .f.eupath -row 5 -column 1 -sticky new -padx 5 -pady 5;
	grid .f.bupath -row 5 -column 2 -sticky new -padx 5 -pady 5;
	
	pack .f 

	frame .t
	ttk::button .t.bmake -command makefont -text "Make Font" -width 10
	ttk::button .t.bhelp -command help -text "Help" -width 8
	ttk::button .t.babout -command about -text "About" -width 8
	ttk::button .t.bexit -command exit -text "Exit" -width 8 
	
	grid .t.bmake -row 0 -column 0 -sticky ne -pady 5 -padx 5
	grid .t.bhelp -row 0 -column 1 -sticky nw -pady 5 -padx 5
	grid .t.babout -row 0 -column 2 -sticky nw -pady 5 -padx 5
	grid .t.bexit -row 0 -column 3 -sticky nw -pady 5 -padx 5
	pack .t


proc help { } {
	switch -- $::tcl_platform(platform) {
		windows 	{  set command [ list {*}[auto_execok start] {} ]}
		unix 		{  set command  [ auto_execok xdg-open ]  }
		macintosh {  set command  [ auto_execok open ]  }
		default 	{  ::makefont::Error "The platform: $::tc_platform(platform) isn't defined."; focus -force .f.efil  }
	}
	if {[catch {exec {*}$command  "../manual/makefont.html"  } err]} {
		# ends exec with & to be executed in background
		::makefont::Error "$err.\nPlease open manually «/manual/makefont.html»" 
		focus -force .f.efil
	}
}

proc OpenFileFont {} {

	global _file _initialdir _typedialog;
	
	if { $_typedialog eq "tk" } {
		set types {
				{ {TrueType fonts} {.ttf} }
				{{ OpenType fonts } {.otf} }
				{ { Type1 binary fonts } {.pfb} }
		}
		set fileopened [tk_getOpenFile -filetypes $types -initialdir $_initialdir -title "Open font file"]
		if {$fileopened ne ""} {
			set _file $fileopened
		}
	} else {
			Open_findfonts
			searchTree $_initialdir
	}
}

proc OpenFileEncode {} {

	global _encodeext;
	set types { { {map files} {.map} } }
	set fileopened [tk_getOpenFile -filetypes $types -initialdir "." -title "Open encode file" ]
	if {$fileopened ne ""} {
		set _encodeext $fileopened
	}
}

proc OpenDirUser {} {

	variable $::makefont::MF_USERPATH;
	set dir [tk_chooseDirectory  -initialdir $::makefont::MF_USERPATH -title "Choose where save new definition..."]
	if {$dir ne ""} {
		set $::makefont::MF_USERPATH $dir
	}
}

proc about {} {

	tk_messageBox -parent . -title "About this..." -message "Makefont wrapper 1.0 (2025) \n \
	A simple gui of makefont utility \n \
	for generate new definitions files \n \
	to be used in TCLFPDF. \n \
	\t \t by L.A. Muzzachiodi" -icon info -type ok
	focus -force .
}

proc toggle_encode { type } {

	if {$type == "int" } {	
		.f.fe.denc configure -state readonly
		.f.fe.eenc configure -state disabled
		.f.fe.benc configure -state disabled
		focus .f.fe.denc
	} else {
		.f.fe.denc configure -state disabled
		.f.fe.eenc configure -state normal
		.f.fe.benc configure -state normal
		focus .f.fe.eenc 
	}
}

proc makefont {} {

	global _file _typencode _encode _encodeint _encodeext _embed _subset
	variable ::makefont::MF_PATH
	
	if {$_typencode == "int" } {
		set _encode [lindex $_encodeint 0]
	} else {
		set _encode $_encodeext
	}
	if {[catch { ::makefont::MakeFont $_file $_encode $_embed $_subset } err]} {
			puts "Makefont error: $err"
			focus -force .f.fo.efil
	}
}

proc Open_findfonts { } {
	global w
	wm deiconify $w
	raise $w
	grab set $w
	focus -force $w
	
}

proc Close_findfonts {} {
	global w _file
	grab release $w
	wm withdraw $w	
}

## Code to populate the roots of the tree
proc populateRoots {tree} {
    foreach dir [lsort -dictionary [file volumes]] {
	populateTree $tree [$tree insert {} end -text $dir -values [list $dir directory]]
    }
}

## Code to populate a node of the tree
proc populateTree {tree node} {

    if {[$tree set $node type] ne "directory"} {
	return
    }
    set path [$tree set $node fullpath]
    $tree delete [$tree children $node]
    foreach f [lsort -dictionary [list {*}[glob -nocomplain -dir $path * ] {*}[glob -nocomplain -type hidden -dir $path * ]]] {
	set type [file type $f]
	if {$type eq "directory"} {
	    ## Make it so that this node is openable
	    set id [$tree insert $node end -text [file tail $f] -values [list $f $type]]
	    $tree insert $id 0 -text dummy ;# a dummy
	    $tree item $id -text [file tail $f]/
	} elseif {$type eq "file"} {
		set fe [file extension $f]
		if {$fe in {.ttf .otf .pfb} } {
			set id [$tree insert $node end -text [file tail $f] -values [list $f $type]]
			}
		}	
	}
    # Stop this code from rerunning on the current node
    $tree set $node type processedDirectory
}

## Create the tree and set it up
ttk::treeview $w.tree -columns {fullpath type}  -displaycolumns { }  -yscroll "$w.vsb set" -xscroll "$w.hsb set"
ttk::scrollbar $w.vsb -orient vertical -command "$w.tree yview"
ttk::scrollbar $w.hsb -orient horizontal -command "$w.tree xview"
$w.tree heading \#0 -text "Directory Structure"
populateRoots $w.tree
bind $w.tree <<TreeviewOpen>> {populateTree %W [%W focus]}


proc searchTree { path { level 0} {xid {}} } {

    global w
    set listpath [file split $path]    
    set lenlp [llength $listpath ]
     if {$level > 1 } { 
	populateTree $w.tree $xid
    } 
    if {$level > $lenlp } return
    set children [$w.tree children $xid ]
    foreach id $children {
	set text [string tolower [$w.tree item $id -text]]
	if {$level > 0 } {
		set text [string map {/ ""} $text]
	}
	set leveltxt  [string tolower [lindex $listpath $level]]
	if {$text eq  $leveltxt } {
		incr level
		if { $level <  $lenlp } {
			searchTree $path $level $id
			return
		} else {
			$w.tree selection set $id
			$w.tree focus $id
			$w.tree see $id
			populateTree $w.tree [ $w.tree focus ]
			$w.tree item $id -open yes
			return
		}
	}
    }
}

proc _selectTree {} {
    global w _file
    
    set _file {}
    set id [$w.tree focus]
    while 1 {
	set parent [$w.tree parent $id]
	set _file "[$w.tree item $id -text]$_file"
	if {$parent eq {} } {
		break
	} else {	
		set id $parent
	}	
     }
    Close_findfonts
}

## Create a menu
set m [menu $w.popupMenu -tearoff 0]
$m add command -label "Select" -command _selectTree
$m add command -label "Back" -command Close_findfonts

# Arrange for the menu to pop up when the label is clicked
bind $w.tree <ButtonRelease-3> {tk_popup $w.popupMenu %X %Y}


## Arrange the tree and its scrollbars in the toplevel
lower [ttk::frame $w.dummy]
pack $w.dummy -fill both -expand 1
grid $w.tree $w.vsb -sticky nsew -in $w.dummy
grid $w.hsb -sticky nsew -in $w.dummy
grid columnconfigure $w.dummy 0 -weight 1
grid rowconfigure $w.dummy 0 -weight 
ttk::button $w.sel  -text Select -width 10 -command _selectTree
ttk::button  $w.esc -text Cancel -width 10 -command Close_findfonts
pack $w.sel $w.esc -side left -expand 1 -fill both -padx 5 -pady 5	


#------------------------------------------------------------------------------------------
# Lets begin ...

	::makefont::SetExitOnError 0
	focus -force .f.fo.efil
