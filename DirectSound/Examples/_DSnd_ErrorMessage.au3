#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6
;#AutoIt3Wrapper_UseX64 = y
#include "..\DirectSound.au3"

; -------------------------------------------------------------------------------------------
; | open and play WAV-File
; -------------------------------------------------------------------------------------------


_Example()


Func _Example()
	Local $sFile = FileOpenDialog("Select WAV", "..\AudioFiles", "WAV (*.wav;*.bwf)", 1)
	Local $aWav = _DSnd_WaveLoadFromFile($sFile)
	If @error Then Return MsgBox(16, "Error", _DSnd_ErrorMessage(@error))
	If @extended Then ;WAV is not WAVE_FORMAT_PCM
		Switch $aWav[1].FormatTag
			Case $WAVE_FORMAT_IEEE_FLOAT
				MsgBox(64, "Info", "WAV is IEEE_FLOAT", 2)
			Case $WAVE_FORMAT_MPEG, $WAVE_FORMAT_MPEGLAYER3
				Return MsgBox(16, "Error", "WAV is Mpeg and must be decoded first")
			Case Else
				Return MsgBox(16, "Error", "Some special FormatTag: " & $aWav[1].FormatTag)
		EndSwitch
	EndIf


	Local $oDS = _DSnd_Create()
	Local $oDS_Buffer = _DSnd_CreateSoundBuffer($oDS, $DSBCAPS_GLOBALFOCUS, BinaryLen($aWav[0]), $aWav[1].Channels, $aWav[1].SamplesPerSec, $aWav[1].BitsPerSample, $aWav[1].FormatTag)
	If @error Then
		If Mod($aWav[1].BitsPerSample, 8) Then Return MsgBox(16, "Error", "BitsPerSample(" & $aWav[1].BitsPerSample & ") is not a multible of 8")
		Switch $aWav[1].Channels
			Case 1, 2
				Return MsgBox(16, "Error", "_DSnd_CreateSoundBuffer error")
			Case Else
				Return MsgBox(16, "Error", "Unsupported number of channels: " & $aWav[1].Channels)
		EndSwitch
	EndIf

	Local $aLock = _DSnd_BufferLock($oDS_Buffer)
	Local $tBuffer = DllStructCreate("byte[" & $aLock[1] & "];", $aLock[0])
	DllStructSetData($tBuffer, 1, $aWav[0])
	_DSnd_BufferUnLock($oDS_Buffer, $aLock)

	_DSnd_BufferPlay($oDS_Buffer, $DSBPLAY_LOOPING)

	MsgBox(0, "", "click OK to stop")
	$oDS_Buffer.Stop()

	$oDS_Buffer = 0
	$oDS = 0
EndFunc   ;==>_Example
