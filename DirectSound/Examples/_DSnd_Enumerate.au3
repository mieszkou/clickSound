#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6
;#AutoIt3Wrapper_UseX64=y
#include "..\DirectSound.au3"
#include <Array.au3>

Global $aDeviceOut = _DSnd_Enumerate()
_ArrayDisplay($aDeviceOut)

Global $aDeviceIn = _DSnd_CaptureEnumerate()
_ArrayDisplay($aDeviceIn)
