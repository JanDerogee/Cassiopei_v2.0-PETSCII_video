; CPIO related constants
;------------------------


CPIO_DATAFILE_OPEN      = %10000000     ;open file*/
CPIO_DATAFILE_SEEKPOS   = %10000001     ;set datapointer to new location in the file*/
CPIO_DATAFILE_READ      = %10000010     ;read from file*/
CPIO_DATAFILE_WRITE     = %10000011     ;write to file*/
CPIO_DATAFILE_CLOSE     = %10000100     ;close the file*/


CPIO_PARAMETER          = %11111111     ;a general purpose command to parse filename (and all sorts of parameters that might be required for the next following CPIO command)


CPIO_BROWSE             = %00000101     ;CPIO command 0x05:  all file selection related actions
CPIO_BROWSE_REFRESH     = $00           ;                    refresh (the menu itself is not altered, the menu screen data is returned)
CPIO_BROWSE_PREVIOUS    = $01           ;                    previous (navigate through the menu)
CPIO_BROWSE_SELECT      = $02           ;                    select (select current item from the menu)
CPIO_BROWSE_NEXT        = $03           ;                    next (navigate through the menu)
CPIO_BROWSE_RESET       = $FF           ;                    reset menu


; menu related constants (values parsed by the keyboard and joystick reading routines)
;-----------------------
USER_INPUT_IDLE         = 0
USER_INPUT_SELECT       = 1
USER_INPUT_PREVIOUS     = 2
USER_INPUT_NEXT         = 3

BROWSE_BUSY             = 0
BROWSE_EXIT             = 1