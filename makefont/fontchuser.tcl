 # Extracted from https://www.tcl-lang.org/man/tcl/TkCmd/fontchooser.htm

proc fontchooserDemo {} {
    wm title . "Font Chooser Demo"
    tk fontchooser configure -parent .
    button .b -command fontchooserToggle -takefocus 0
    fontchooserVisibility .b
    bind . <<TkFontchooserVisibility>> \
            [list fontchooserVisibility .b]
    foreach w {.t1 .t2} {
        text $w -width 20 -height 4 -borderwidth 1 -relief solid
        bind $w <FocusIn> [list fontchooserFocus $w]
        $w insert end "Text Widget $w"
    }
    .t1 configure -font {Courier 14}
    .t2 configure -font {Times 16}
    pack .b .t1 .t2; focus .t1
}
proc fontchooserToggle {} {
    tk fontchooser [expr {
            [tk fontchooser configure -visible] ?
            "hide" : "show"}]
}
proc fontchooserVisibility {w} {
    $w configure -text [expr {
            [tk fontchooser configure -visible] ?
            "Hide Font Dialog" : "Show Font Dialog"}]
}
proc fontchooserFocus {w} {
    tk fontchooser configure -font [$w cget -font] \
            -command [list fontchooserFontSelection $w]
}
proc fontchooserFontSelection {w font args} {
    $w configure -font [font actual $font]
}
fontchooserDemo