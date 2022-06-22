#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6
;#AutoIt3Wrapper_UseX64 = y
#include "..\DirectSound.au3"


; -------------------------------------------------------------------------------------------
; | SpVoice
; -------------------------------------------------------------------------------------------


_Example()


Func _Example()
	Local $oVoice = ObjCreate("Sapi.SpVoice")
	If @error Or Not IsObj($oVoice) Then Return MsgBox(16, "Error", "error creating SpVoice object")

	Local $oMemStream = ObjCreate("SAPI.SpMemoryStream.1")
	If @error Or Not IsObj($oMemStream) Then Return MsgBox(16, "Error", "error creating SpMemoryStream object")

	Local $oSpAudioFormat = $oMemStream.Format
	$oSpAudioFormat.Type = 0x00000023

	$oVoice.AudioOutputStream = $oMemStream
	$oVoice.Rate = -5
	$oVoice.Volume = 100

	$oVoice.Speak("Direct Sound Example")

	Local $bPCM = $oMemStream.GetData()

	$oSpAudioFormat = 0
	$oMemStream = 0
	$oVoice = 0


	Local $oDS = _DSnd_Create()
	Local $oDS_Buffer = _DSnd_CreateSoundBuffer($oDS, $DSBCAPS_GLOBALFOCUS, BinaryLen($bPCM))
	If @error Then Return MsgBox(16, "Error", "_DSnd_CreateSoundBuffer error")

	Local $aLock = _DSnd_BufferLock($oDS_Buffer)
	Local $tBuffer = DllStructCreate("byte[" & $aLock[1] & "];", $aLock[0])
	DllStructSetData($tBuffer, 1, $bPCM)
	_DSnd_BufferUnLock($oDS_Buffer, $aLock)

	_DSnd_BufferPlay($oDS_Buffer, $DSBPLAY_LOOPING)

	MsgBox(0, "", "click OK to stop")
	$oDS_Buffer.Stop()

	$oDS_Buffer = 0
	$oDS = 0
EndFunc   ;==>_Example
