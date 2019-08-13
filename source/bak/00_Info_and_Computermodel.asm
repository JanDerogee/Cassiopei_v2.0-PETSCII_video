;This program was written by Jan Derogee as a menu program for the Cassiopei
;The Cassiopei is a device that connects to the cassetteport of the CBM computer.
;The casetteport is the only interface that exists on all 8-bit CBM models, and
;is mostly supported by them all, although exceptions exist like the CBM600 series.
;
;If spread (and or modified) please always refer to the original designer/programmer.
;
;---------------------------------------------------------------------------------------------------------
;
; ATTENTION: This code has been developed to be used with the CBM Program Studio compiler V3.10.0
; ==========
; make sure that the build order is exactly according the numbers of the individual filenames
;(this can be set using: project -> properties)
;example:
; 00_......
; 01_0_....
; 01_1_....
; 01_2_....
; 01_3_....
; 02_0_....
; 02_1_....
; etc.
;---------------------------------------------------------------------------------------------------------

;When using CBM prog studio to compile this program, make sure that you
;compile the entire project (Build -> Project -> And Run (CTRL+F5) )

;All files in this program begin with a number, it is important that the files
;are build in the order as indicated by these numbers.
;The numbering consists of a 2 digit value followed by a third value.
;The first 2 digits indicate the type of file and it's intended function which
;is described by the name directly after the third number. The third number
;indicates a variation of the file caused by a different implementation of the
;code for certain computer model(s).


;regarding the CBM program studio assembler mind the following settings:
;disable the option : optimize absolute modes to zero page

;                           BUILD RELATED SETTINGS
;-------------------------------------------------------------------------------
;to compile this program for a specific computer model, just uncomment the
;model from the list below and compile the project. Make sure that only one
;of the items below is uncommented!

;COMMODOREPET20XX
;COMMODOREPET30XX = 1
;COMMODOREPET40XX
;COMMODOREPET80XX = 1
;COMMODOREVIC20 = 1
;COMMODORE64 = 1
;COMMODORE128 = 1
COMMODORE16PLUS4 = 1

VERSION_STRING_00 = 1 ;tens of year
VERSION_STRING_01 = 8 ;ones of year
VERSION_STRING_02 = 1 ;tens of month
VERSION_STRING_03 = 0 ;ones of month
VERSION_STRING_04 = 2 ;tens of day
VERSION_STRING_05 = 5 ;ones of day

;-------------------------------------------------------------------------------
;File name convention:
;=====================
;the files in this project are named in the following fashion:
;
;0X_0_name      <- this is the file that holds all generic functionality
;0X_1_name      <- this is the file holding the computer specific code (PET series)
;0X_2_name      <- this is the file holding the computer specific code (VIC20)
;0X_3_name      <- this is the file holding the computer specific code (C64)
;0X_4_name      <- this is the file holding the computer specific code (C128)
;0X_5_name      <- this is the file holding the computer specific code (C16/plus4)

;ATTENTION regarding screen editor:
;all screen are to be editted in the C64 mode (because allmost all screens are 40col)
;except the VIC20 screen must be done in VIC20 mode (because of the 20col)
;except the CBM/PET8000 screen must be done in PET 4000/9000 mode (because of the 80col)

;ATTENION regarding ifdef
;do not use nested ifdef constructions
