package require tclfpdf
namespace import  ::tclfpdf::*


Init;
AddPage;
SetLineWidth 0.1;
SetDash 5 5; #5mm on, 5mm off
Line 20 20 190 20;
SetLineWidth 0.5 ;
Line 20 25 190 25;
SetLineWidth 0.8;
SetDash 4 2; #4mm on, 2mm off
Rect 20 30 170 20;
SetDash; #restores no dash
Line 20 55 190 55;
Output "dash.tcl";