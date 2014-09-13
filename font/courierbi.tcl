set type "Core";
set name  "Courier-BoldOblique";
set up  -100;
set ut  50;
for {set i 0} {$i<=255} {incr i} {	
	set char [format %c $i];
	array set cw [list $char 600];
}	
