# **TCLFPDF 1.6 (2023)** #
## *Port of tFPDF (PHP) by  by Ian Back and Tycho Veltmeijer (modified version of FPDF by Olivier Plathey) to TCL* ##

----------


## Objective/Objetivo ##

#### English #####

This work aims to port [tFPDF]("http://www.fpdf.org/en/script/script92.php") (1.33) from PHP to TCL. This is a modified class of [FPDF]("http://www.fpdf.org/") (1.85) that adds support for UTF-8.
It is, therefore, a complete update of the previous version of 2014, which maintains backward compatibility, but adds full support for UTF-8.
I have tried to be as faithful as possible to the original, keeping the names and structure of programs.This way it should be possible to port the examples or addons with minimal effort.

Your comments or suggestions are always welcome.

#### Spanish ####

Este trabajo pretende portar [tFPDF]("http://www.fpdf.org/en/script/script92.php") (1.33) de PHP a TCL. tFPDF es una clase modificada de [FPDF]("http://www.fpdf.org/") (1.85) que incorpora soporte para UTF-8.
Por tanto, es una completa actualización de la versión previa de 2014 que mantiene la compatibilidad pero agrega completo soporte para UTF-8.
He tratado de ser lo más fiel posible al original en PHP, manteniendo los nombres y la estructura de los programas. De esta manera debería ser posible portar los ejemplos o extensiones con un mínimo esfuerzo.

Sus comentarios o sugerencias serán bienvenidos.



__*Luis Alejandro Muzzachiodi (2023)*__


----------
### Notes ###
- TCLFPDF uses the *procedure* **Init** where FPDF uses the *class constructor* **FPDF** (the parameters are the same).