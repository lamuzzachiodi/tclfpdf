package require tclfpdf
namespace import  ::tclfpdf::*

set col1 "Это столбец в таблице со многими строками.\n זוהי עמודה בטבלה עם שורות רבות. \nĐây là một cột trong một bảng có nhiều hàng.\nهذا عمود في جدول يحتوي على العديد من الصفوف."
set col2 "This is a table \n with cells that\n span several rows \n(including newline's)."

proc ::tclfpdf::MCT_SetColumns {} {
	global col1 col2
	return [list "i'm justified aligned \n $col1" "i'm rigth aligned \n $col1" "i'm left aligned \n $col1" "i'm centered\n $col1" "i'm default align\n $col2" ]
}

Init;
AddPage L ;
AddFont "DejaVu" "" "DejaVuSansCondensed.ttf" 1;
SetFont "DejaVu" "" 12;
# Table with 20 rows and 4 columns
MCT_SetWidths  { 50 50 50 50 50};
MCT_SetAligns { J R L C};
MCT_PrintRows 3;
Output "multicell-table.pdf";