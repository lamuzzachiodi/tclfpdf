package require tclfpdf
namespace import  ::tclfpdf::*

Init;
AddPage;
# Add a Unicode font (uses UTF-8)
AddFont "DejaVu" "" "DejaVuSansCondensed.ttf" 1;
SetFont "DejaVu" "" 14;
Write 8 "		-----
English: Hello World
Greek: \u0393\u03B5\u03B9\u03AC \u03C3\u03BF\u03C5 \u03BA\u03CC\u03C3\u03BC\u03BF\u03C2
Polish: Witaj \u015Bwiecie
Portuguese: Ol\u00E1 mundo
Spanish: Hola mundo
Russian: \u0417\u0434\u0440\u0430\u0432\u0441\u0442\u0432\u0443\u043B\u0442\u0435 \u043C\u0438\u0440
Vietnamese: Xin ch\u00E0o th\u1EBF gi\u1EDBi
		------";
Ln 10;		
AddFont "simhei" "" "simhei.ttf" 1;
SetFont "simhei" "" 20;		
Write 10 "Chinese: \u4F60\u597D\u4E16\u754C";
#Select a standard font (uses windows-1252)
SetFont  "Arial" "" 14;
Ln 10;
Write 5 "The file size of this PDF is only 16 KB.";
Output "utf8.pdf";
