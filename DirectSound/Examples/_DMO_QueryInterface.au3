#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6
;#AutoIt3Wrapper_UseX64 = y
#include "..\DirectSound.au3"


; -------------------------------------------------------------------------------------------
; | Flanger effect
; -------------------------------------------------------------------------------------------


_Example()


Func _Example()
	Local $sFile = FileOpenDialog("Select WAV", "..\AudioFiles", "WAV (*.wav;*.bwf)", 1)
	Local $aWav = _DSnd_WaveLoadFromFile($sFile)
	If @error Then Return MsgBox(16, "Error", "_DSnd_WaveLoadFromFile error:" & @CRLF & _DSnd_ErrorMessage(@error))
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

	Local $tBuffer = DllStructCreate("byte[" & BinaryLen($aWav[0]) & "];")
	DllStructSetData($tBuffer, 1, $aWav[0])



	;Create DirectX-MediaObject Effect
	Local $oDMO = _DMO_CreateInstance($sGUID_DSFX_STANDARD_FLANGER, $sIID_IMediaObject, $tagIMediaObject)

	_DMO_MediaObjectSetInputType($oDMO, $aWav[1].Channels, $aWav[1].SamplesPerSec, $aWav[1].BitsPerSample, $aWav[1].FormatTag)
	If @error Then Return MsgBox(16, "Error", "_DMO_MediaObjectSetInputType error: " & @CRLF & _DSnd_ErrorMessage(@error) & @CRLF & @CRLF & "DMOs can process 8-bit or 16-bit PCM data, as well as 32-bit floating-point formats.")
	_DMO_MediaObjectSetOutputType($oDMO, $aWav[1].Channels, $aWav[1].SamplesPerSec, $aWav[1].BitsPerSample, $aWav[1].FormatTag)

	;Enable ObjectInPlace (direct processing of $tBuffer)
	Local $oDMO_OIP = _DMO_QueryInterface($oDMO, $sIID_IMediaObjectInPlace, $tagIMediaObjectInPlace)

	;apply FX to Audiodata
	Local $iHResult = $oDMO_OIP.Process(DllStructGetSize($tBuffer), $tBuffer, 0, 0)
	If $iHResult Then Return MsgBox(16, "Error", "$oDMO_OIP.Process error:" & @CRLF & _DSnd_ErrorMessage($iHResult))

	;release resources
	$oDMO_OIP = 0
	$oDMO = 0





	Local $oDS = _DSnd_Create()

	;Create DirectSoundBuffer
	Local $oDS_Buffer = _DSnd_CreateSoundBuffer($oDS, $DSBCAPS_GLOBALFOCUS, DllStructGetSize($tBuffer), $aWav[1].Channels, $aWav[1].SamplesPerSec, $aWav[1].BitsPerSample, $aWav[1].FormatTag)

	;Copy Buffer to DirectSoundBuffer
	Local $aLock = _DSnd_BufferLock($oDS_Buffer)
	Local $tLock = DllStructCreate("byte[" & $aLock[1] & "];", $aLock[0])
	DllStructSetData($tLock, 1, DllStructGetData($tBuffer, 1))
	_DSnd_BufferUnLock($oDS_Buffer, $aLock)

	_DSnd_BufferPlay($oDS_Buffer, $DSBPLAY_LOOPING)

	MsgBox(0, "", "click OK to stop")
	$oDS_Buffer.Stop()

	$oDS_Buffer = 0
	$oDS = 0
EndFunc   ;==>_Example