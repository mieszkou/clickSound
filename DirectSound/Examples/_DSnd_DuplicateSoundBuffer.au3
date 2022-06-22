#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6
;#AutoIt3Wrapper_UseX64 = y
#include "..\DirectSound.au3"


; -------------------------------------------------------------------------------------------
; | DuplicateBuffer
; -------------------------------------------------------------------------------------------


_Example()


Func _Example()
	Local $fFreq = 261.6
	Local $iSampleRate = 44100

	Local $fLambda = $iSampleRate / $fFreq
	Local $iSamples = Ceiling($fLambda * 10)

	Local $fPhase = 0, $fPhaseInc = (ATan(1) * 8) / $iSampleRate * $fFreq
	Local $aPhase[$iSamples + 1], $aSample[$iSamples + 1]
	For $i = 1 To $iSamples
		$aPhase[$i] = $fPhase
		$aSample[$i] = Sin($fPhase)
		$fPhase += $fPhaseInc
	Next

	Local $fZ, $iMaxNyquist = Floor(($iSampleRate / 2) / $fFreq)
	For $z = 3 To $iMaxNyquist Step 2
		$fZ = 1 / $z
		For $i = 1 To $iSamples
			$aSample[$i] += Sin($aPhase[$i] * $z) * $fZ
		Next
	Next


	Local $oDS = _DSnd_Create()
	Local $oDS_Buffer = _DSnd_CreateSoundBuffer($oDS, BitOR($DSBCAPS_GLOBALFOCUS, $DSBCAPS_CTRLFREQUENCY, $DSBCAPS_CTRLVOLUME), $iSamples * 2, 1, $iSampleRate)

	Local $aLock = _DSnd_BufferLock($oDS_Buffer)
	Local $tBuffer = DllStructCreate("short Smp[" & $aLock[1] / 2 & "];", $aLock[0])
	For $i = 1 To $iSamples
		$tBuffer.Smp(($i)) = $aSample[$i] * 8000
	Next
	_DSnd_BufferUnLock($oDS_Buffer, $aLock)


	Local $oDS_Dup1 = _DSnd_DuplicateSoundBuffer($oDS, $oDS_Buffer)
	Local $oDS_Dup2 = _DSnd_DuplicateSoundBuffer($oDS, $oDS_Buffer)
	Local $oDS_Dup3 = _DSnd_DuplicateSoundBuffer($oDS, $oDS_Buffer)
	Local $oDS_Dup4 = _DSnd_DuplicateSoundBuffer($oDS, $oDS_Buffer)

	$oDS_Dup2.SetFrequency($iSampleRate * 1.26)
	$oDS_Dup3.SetFrequency($iSampleRate * 1.5)
	$oDS_Dup4.SetFrequency($iSampleRate * 2)


	_DSnd_BufferPlay($oDS_Dup1, $DSBPLAY_LOOPING)
	Sleep(800)
	_DSnd_BufferPlay($oDS_Dup2, $DSBPLAY_LOOPING)
	Sleep(800)
	_DSnd_BufferPlay($oDS_Dup3, $DSBPLAY_LOOPING)
	Sleep(800)
	_DSnd_BufferPlay($oDS_Dup4, $DSBPLAY_LOOPING)
	Sleep(800)

	For $i = 0 To 100
		$oDS_Dup4.SetFrequency($iSampleRate * (2 + Sin($i / 31.83) * 0.24))
		Sleep(10)
	Next
	Sleep(800)

	For $i = 0 To -60 Step -1 ;0dB to -60dB
		$oDS_Dup1.SetVolume($i * 100)
		$oDS_Dup2.SetVolume($i * 100)
		$oDS_Dup3.SetVolume($i * 100)
		$oDS_Dup4.SetVolume($i * 100)
		Sleep(50)
	Next

	$oDS_Dup1.Stop()
	$oDS_Dup2.Stop()
	$oDS_Dup3.Stop()
	$oDS_Dup4.Stop()

	$oDS_Dup1 = 0
	$oDS_Dup2 = 0
	$oDS_Dup3 = 0
	$oDS_Dup4 = 0
	$oDS_Buffer = 0
	$oDS = 0
EndFunc   ;==>_Example
