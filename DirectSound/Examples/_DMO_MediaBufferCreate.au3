#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6
;#AutoIt3Wrapper_UseX64 = y
#include "..\DirectSound.au3"


; -------------------------------------------------------------------------------------------
; | Decode MP3
; -------------------------------------------------------------------------------------------


_Example()


Func _Example()
	Local $sFile = FileOpenDialog("Select MP3", "..\AudioFiles", "MP3 (*.mp3)", 1)
	Local $hFile = FileOpen($sFile, 16)
	Local $bMP3 = FileRead($hFile)
	If @error Then Return MsgBox(16, "Error", "could not open: " & $sFile)
	FileClose($hFile)

	Local $aWav = _DSnd_MP3Decode($bMP3)
	If @error Then Return MsgBox(16, "", "_DSnd_MP3Decode error: " & @CRLF & _DSnd_ErrorMessage(@error))


	Local $oDS = _DSnd_Create()
	Local $oDS_Buffer = _DSnd_CreateSoundBuffer($oDS, $DSBCAPS_GLOBALFOCUS, BinaryLen($aWav[0]), $aWav[1].Channels, $aWav[1].SamplesPerSec, $aWav[1].BitsPerSample, $aWav[1].FormatTag)

	Local $aLock = _DSnd_BufferLock($oDS_Buffer)
	Local $tLock = DllStructCreate("byte[" & $aLock[1] & "];", $aLock[0])
	DllStructSetData($tLock, 1, $aWav[0])
	_DSnd_BufferUnLock($oDS_Buffer, $aLock)

	_DSnd_BufferPlay($oDS_Buffer, $DSBPLAY_LOOPING)

	MsgBox(0, "", "click OK to stop")
	$oDS_Buffer.Stop()

	$oDS_Buffer = 0
	$oDS = 0
EndFunc   ;==>_Example
