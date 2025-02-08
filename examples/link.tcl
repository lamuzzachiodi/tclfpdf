package require tclfpdf
namespace import  ::tclfpdf::*

# First page
Init
AddPage
# Add a Unicode font (uses UTF-8)
AddFont "DejaVu" "" "DejaVuSansCondensed.ttf" 1
SetFont "DejaVu" "" 14
Write 5 "To find out what's cool in this example, click "
set link [AddLink]
SetFont "DejaVu" "U" 14;
Write 5 "Здравствулте мир" $link
# Second page
AddPage
SetLink $link
Image "logo.gif" 10 12 30 0 "" "http://www.fpdf.org"
Output "link.pdf"