the PET/CBM style computers have many different keyboard layouts and mappings.
Because of the way the keyboard operates *during video playback) it is difficult
to do a proper keyboard scan in one single porgram that works on all PET/CBM models from 2001 to 8032.

During file selecting of the PETCSII video file all keys works as shown on the screen.
Therefore the menu works on all CBM's in the same way.
But during PETSCII video playback these routines cannot be used, because of interrupt related issues.
Therefor on stoppping the video there might be a different key required for each PET/CBM computer model.
On my CBM3032 I must press "<-" or "RUN STOP" to stop the video playback.
However when I wrote the program and tested it in VICE I could press space to stop the video.
So the easiest way to find out is just by trying all keys, just try them untill you've found a key that stops video playback.
This is the reason why the menu program says "key" instead of the actual name of the key you need to press.

Have fun in playing back PETSCII videos.