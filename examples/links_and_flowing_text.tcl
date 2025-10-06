package require tclfpdf
namespace import  ::tclfpdf::*

set B 0
set I 0
set U 0
set HREF ""

proc WriteHTML { html } {
    global HREF
    #  HTML parser
    set html [ string map {\n "" } $html ]
    set a0 {}
    regsub  -all "<(.*?)>" $html "^&^" a0
    set a1 [split $a0 ^]
    foreach i0 $a1 {
	lappend a [string map { < "" > "" } $i0 ]
    }
    set i -1
    foreach e $a {
	incr i
        if { [expr $i%2] == 0 } {
            # Text
            if  {$HREF ne ""} {
                 PutLink $HREF $e
	    } else {
                Write 5 $e
	     }	
        } else {
            # Tag
            if { [string index $e 0] eq "/" } {
                CloseTag [string toupper [string range $e 1 end]];
	    }  else {
                # Extract attributes
                set a2 [split $e " " ]
		set tag {}
		set tag [string toupper [lindex $a2 0]]
		set a2 [lreplace $a2 0 0]
                array set attr {}
		set a3 ""
                foreach v $a2 {
		    set a3 [regexp -inline {([^=]*)=["\']?([^"\']*)} $v ]
                    if { $a3 ne ""} {
                        set attr([string toupper [lindex $a3 1]])  [lindex $a3 2]
		    }	
                }
                OpenTag $tag [array get attr]
            }
        }
    }
}

proc OpenTag { tag attr0 } {
    global HREF
    array set attr $attr0
    # Opening tag
    if  {$tag=="B" || $tag=="I" || $tag=="U" } { 
	SetStyle $tag 1 
    }
    if {$tag=="A" } {
	set HREF $attr(HREF)
    }
    if { $tag=="BR" } { 
	Ln 5 
    }
}

proc CloseTag { tag } {
	global HREF
    # Closing tag
    if { $tag=="B" || $tag=="I" || $tag=="U" } {
        SetStyle $tag 0
    }
    if { $tag == "A" } { 
	set HREF ""
    }
}

proc SetStyle { tag enable } {
    # Modify style and select corresponding font
     global B I U
    set $tag [expr [set $tag] + ($enable ? 1 : -1)]
    set style ""
    set lis_tag [list B I U]
    foreach s $lis_tag {
        if { [set $s] >0 } {
            set style $style$s;
	}
    }
    SetFont "" $style
}

proc PutLink { URL txt } {
    #Put a hyperlink
    SetTextColor 0 0 255
    SetStyle U 1
    Write 5 $txt $URL
    SetStyle U 0 
    SetTextColor 0
}

set html "You can now easily print text mixing different styles: <b>bold</b>, <i>italic</i>,
<u>underlined</u>, or <b><i><u>all at once</u></i></b>!<br><br>You can also insert links on
text, such as <a href=\"http://www.fpdf.org\">www.fpdf.org</a>, or on an image: click on the logo."

# First page
AddPage
SetFont "Arial" "" 20
Write 5 "To find out what's cool in this example, click "
SetFont "" "U"
set link [AddLink]
Write 5 "here" $link
SetFont ""
# Second page
AddPage
SetLink $link
Image "logo.gif" 10 12 30 0 "" "http://www.fpdf.org"
SetLeftMargin 45
SetFontSize 14
WriteHTML $html
Output "flow.pdf"