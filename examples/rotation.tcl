package require tclfpdf
namespace import  ::tclfpdf::*

AddPage;
SetFont "Arial" "" 40;
TextWithRotation 50 65 "Hello" 45 -45;
SetFontSize 30;
TextWithDirection 110 50 "world!" L;
TextWithDirection 110 50 "world!" U;
TextWithDirection 110 50 "world!" R;
TextWithDirection 110 50 "world!" D;
Output "rotation.pdf";