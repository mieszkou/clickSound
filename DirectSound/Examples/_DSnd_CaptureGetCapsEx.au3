#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6
;#AutoIt3Wrapper_UseX64=y
#include "..\DirectSound.au3"

; -------------------------------------------------------------------------------------------
; | Record SoundcardInput und playback
; -------------------------------------------------------------------------------------------


_Example(2)



Func _Example($iSeconds)
	Local $iBytes = _DSnd_Seconds2Bytes($iSeconds)

	Local $oDSC = _DSnd_CaptureCreate()
	If @error Then Return MsgBox(16, "Error", _DSnd_ErrorMessage(@error))

	Local $aCaps = _DSnd_CaptureGetCaps($oDSC)
	If Not BitAND($aCaps[1], $WAVE_FORMAT_4S16) Then Return MsgBox(16, "Error", "Stereo 44100Hz 16Bit not supported")

	Local $oDSC_Buffer = _DSnd_CaptureCreateCaptureBuffer($oDSC, $iBytes)
	If @error Then Return MsgBox(16, "Error", _DSnd_ErrorMessage(@error))


	$oDSC_Buffer.Start(0)
	Local $iTimer = TimerInit()
	Local $iPos, $iRead
	ProgressOn("Recording", "Recording " & $iSeconds & " seconds")
	While TimerDiff($iTimer) < $iSeconds * 1000 + 1000 ;Timeout
		$oDSC_Buffer.GetCurrentPosition($iPos, $iRead)
		ProgressSet($iPos * 100 / $iBytes)
		Sleep(10)
	WEnd
	ProgressOff()

	Local $aLock = _DSnd_CaptureBufferLock($oDSC_Buffer)
	If @error Then Return MsgBox(16, "Error", _DSnd_ErrorMessage(@error))
	Local $tLock = DllStructCreate("byte[" & $aLock[1] & "];", $aLock[0])
	Local $bPCM = DllStructGetData($tLock, 1)
	_DSnd_CaptureBufferUnlock($oDSC_Buffer, $aLock)

	$oDSC_Buffer = 0
	$oDSC = 0






	Local $oDS = _DSnd_Create()
	Local $oDS_Buffer = _DSnd_CreateSoundBuffer($oDS, $DSBCAPS_GLOBALFOCUS, $iBytes)

	$aLock = _DSnd_BufferLock($oDS_Buffer)
	If @error Then Return MsgBox(16, "Error", _DSnd_ErrorMessage(@error))
	$tLock = DllStructCreate("byte[" & $aLock[1] & "];", $aLock[0])
	DllStructSetData($tLock, 1, $bPCM)
	_DSnd_BufferUnLock($oDS_Buffer, $aLock)


	_DSnd_BufferPlay($oDS_Buffer, $DSBPLAY_LOOPING)
	MsgBox(0, "", "click OK to stop")
	$oDS_Buffer.Stop()

	$oDS_Buffer = 0
	$oDS = 0

EndFunc   ;==>_Example
