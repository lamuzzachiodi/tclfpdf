package require tclfpdf
namespace import  ::tclfpdf::*

Init;
AddPage;
# Add a Unicode font (uses UTF-8)
AddFont "DejaVu" "" "DejaVuSansCondensed.ttf" 1;
SetFont "DejaVu" "" 14;
Write 8 "		-----
English: Hello World
Greek: Γειά σου κόσμος
Polish: Witaj świecie
Portuguese: Olá mundo
Spanish: Hola mundo
Russian: Здравствулте мир
Vietnamese: Xin chào thế giới
		------";
Ln 10;		
AddFont "simhei" "" "simhei.ttf" 1;
SetFont "simhei" "" 20;		
Write 10 "Chinese: 你好世界";
#Select a standard font (uses windows-1252)
SetFont  "Arial" "" 14;
Ln 10;
Write 5 "The file size of this PDF is only 16 KB.";
Output "utf8.pdf";
