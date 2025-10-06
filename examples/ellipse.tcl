package require tclfpdf
namespace import  ::tclfpdf::*

AddPage;
Ellipse 100 50 30 20;
SetFillColor 255 255 0;
Circle 110 47 7 "F";
Output "ellipse.pdf";

