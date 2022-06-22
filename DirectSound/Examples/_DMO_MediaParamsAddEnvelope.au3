#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6
;#AutoIt3Wrapper_UseX64 = y
#include "..\DirectSound.au3"


; -------------------------------------------------------------------------------------------
; | FadeIn and FadeOut
; -------------------------------------------------------------------------------------------


Global Const $MSEC = 10000 ;One millisecond (in 100 nanosec units)

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

	Local $tBuffer = DllStructCreate("byte[" & BinaryLen($aWav[0]) & "];")
	DllStructSetData($tBuffer, 1, $aWav[0])


	;Create DirectX-MediaObject Effect
	Local $oDMO = _DMO_CreateInstance($sGUID_DSFX_STANDARD_COMPRESSOR, $sIID_IMediaObject, $tagIMediaObject)

	_DMO_MediaObjectSetInputType($oDMO, $aWav[1].Channels, $aWav[1].SamplesPerSec, $aWav[1].BitsPerSample, $aWav[1].FormatTag)
	If @error Then Return MsgBox(16, "Error", _DSnd_ErrorMessage(@error) & @CRLF & @CRLF & "DMOs can process 8-bit or 16-bit PCM data, as well as 32-bit floating-point formats.")
	_DMO_MediaObjectSetOutputType($oDMO, $aWav[1].Channels, $aWav[1].SamplesPerSec, $aWav[1].BitsPerSample, $aWav[1].FormatTag)

	;Enable ObjectInPlace (direct processing of $tBuffer)
	Local $oDMO_OIP = _DMO_QueryInterface($oDMO, $sIID_IMediaObjectInPlace, $tagIMediaObjectInPlace)





	;Create MediaParams Object
	Local $oMParams = _DMO_QueryInterface($oDMO_OIP, $sIID_IMediaParams, $tagIMediaParams)
	$oMParams.SetParam(3, 0) ;Set Compressor Threshold to 0dB
	$oMParams.SetParam(4, 1) ;Set Compressor Ratio to 1


	Local $aEnv[3][6] = [[2]]
	$aEnv[1][0] = 0                   ;Envelope Start
	$aEnv[1][1] = 1000 * $MSEC        ;Envelope End (1 Sec)
	$aEnv[1][2] = -60                 ;Start at -60dB
	$aEnv[1][3] = 0                   ;End at 0dB
	$aEnv[1][4] = $MP_CURVE_INVSQUARE ;CurveType

	$aEnv[2][0] = 2000 * $MSEC        ;Start FadeOut at 5 Seconds
	$aEnv[2][1] = 5000 * $MSEC        ;FadeOut-Time = 3 Sec
	$aEnv[2][2] = 0
	$aEnv[2][3] = -60
	$aEnv[2][4] = $MP_CURVE_SQUARE

	_DMO_MediaParamsAddEnvelope($oMParams, $aEnv, 0) ;Set Envelope to Gain Parameter


	;apply FX to Audiodata
	$oDMO_OIP.Process(DllStructGetSize($tBuffer), $tBuffer, 0, 0)

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

	_DSnd_BufferPlay($oDS_Buffer)

	MsgBox(0, "", "click OK to stop", 6)
	$oDS_Buffer.Stop()

	$oDS_Buffer = 0
	$oDS = 0
EndFunc   ;==>_Example
