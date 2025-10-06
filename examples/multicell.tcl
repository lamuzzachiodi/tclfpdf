package require tclfpdf
namespace import  ::tclfpdf::*

AddPage;
AddFont DejaVu "" DejaVuSansCondensed.ttf 1;
SetFont DejaVu "" 14;
SetFillColor 255 255 110;
SetTextColor 255 20 20;
set txt "Đây là một cột trong một bảng có nhiều hàng.";
MultiCell 70 5 $txt 1 "J" 1;
SetXY 50 90;
SetTextColor 0 0 0;
SetFillColor 0 255 255;
set txt "Γειά σου κόσμος \n Xin chào thế giới";
MultiCell 60 5 $txt 1 "C" 1;
SetXY 120 50;
SetTextColor 255 0 190;
set txt "ამ უჯრედს არ აქვს საზღვარი \n და არ არის შევსებული";
MultiCell 50 5 $txt 0 "J" 0;
Output "multicell.pdf";