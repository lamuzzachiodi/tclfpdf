# **TCLFPDF** #
## *Port of FPDF (PHP) by Olivier Plathey to TCL* ##

----------


## Objective/Objetivo ##

#### English #####

This work aims to port the latest version of FPDF (1.7) from PHP to TCL.
I have tried to be as faithful as possible to the original, keeping the names and structure of programs.
This could possibly mean that the code is not fully optimized according to the capabilities of TCL.
I have also left out the original OO implementation in favor of a more traditional procedural way (although since version 8.6 TCL has already incorporated OOP).

#### Spanish ####

Este trabajo pretende portar la última versión de FPDF (1.7) del PHP a TCL. 
He tratado de ser lo más fiel posible al original, manteniendo los nombres y la estructura de los programas.
Esto puede significar que posiblemente el código no esté completamente optimizado de acuerdo a las posibilidades del TCL.
También he dejado de lado la implementación OO original en favor de una forma procedural más tradicional (aún cuando TCL desde la versión 8.6 ya ha incorporado la POO).

__*Luis Alejandro Muzzachiodi (2014)*__


----------
### Notes ###
- TCLFPDF uses the *procedure* **Init** where FPDF uses the *class constructor* **FPDF** (the parameters are the same).