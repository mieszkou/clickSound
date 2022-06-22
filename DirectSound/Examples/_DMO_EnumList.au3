#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6
;#AutoIt3Wrapper_UseX64=y
#include "..\DirectSound.au3"
#include <Array.au3>

Global $aDecoder = _DMO_Enum($sDMOCATEGORY_AUDIO_DECODER)
_ArrayDisplay($aDecoder, "Audio Decoder")

Global $aEncoder = _DMO_Enum($sDMOCATEGORY_AUDIO_ENCODER)
_ArrayDisplay($aEncoder, "Audio Encoder")

Global $aEffect = _DMO_Enum($sDMOCATEGORY_AUDIO_EFFECT)
_ArrayDisplay($aEffect, "Effect")
