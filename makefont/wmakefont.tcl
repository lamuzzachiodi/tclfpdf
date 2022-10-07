# Wrapper for makefont

# 1 - Copy the file to font folder
# 2- Change NFont to name of file
# 3- Run this script

source "makefont.tcl";
source "../misc/util.tcl";

namespace import makefont::*;

set Nfont "DejaVuSansCondensed.ttf"; # Change here the font file
#~ set Nfont "simhei.ttf"; # Change here the font file

makefont::MakeFont "../font/$Nfont";
