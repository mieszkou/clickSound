#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6
;#AutoIt3Wrapper_UseX64 = y
#include "..\DirectSound.au3"


; -------------------------------------------------------------------------------------------
; | Buffer Effect
; -------------------------------------------------------------------------------------------


_Example()


Func _Example()

	;Load WAV / MP3
	Local $sFile = FileOpenDialog("Select MP3/WAV", "..\AudioFiles", "(*.mp3;*.wav;*.bwf)", 1)
	If @error Or Not FileExists($sFile) Then Return MsgBox(16, "Error", $sFile & " not exists")
	Local $aWav
	Switch StringRegExp($sFile, "(?mi)mp3$")
		Case True
			Local $hFile = FileOpen($sFile, 16)
			Local $bMP3 = FileRead($hFile)
			FileClose($hFile)
			$aWav = _DSnd_MP3Decode($bMP3)
			If @error Then Return MsgBox(16, "Error", "Error decoding mp3: " & _DSnd_ErrorMessage(@error))
		Case Else
			$aWav = _DSnd_WaveLoadFromFile($sFile)
			If @error Then Return MsgBox(16, "Error", "Error loading wav: " & _DSnd_ErrorMessage(@error))
			If @extended Then ;WAV is not WAVE_FORMAT_PCM
				Switch $aWav[1].FormatTag
					Case $WAVE_FORMAT_IEEE_FLOAT
					Case $WAVE_FORMAT_MPEG, $WAVE_FORMAT_MPEGLAYER3
						$aWav = _DSnd_MP3Decode($aWav[0])
						If @error Then Return MsgBox(16, "", "_DSnd_MP3Decode error: " & @CRLF & _DSnd_ErrorMessage(@error))
					Case Else
						Return MsgBox(16, "Error", "Some special FormatTag: " & $aWav[1].FormatTag)
				EndSwitch
			EndIf
	EndSwitch


	;Create DirectSound resources
	Local $oDS = _DSnd_Create()
	Local $oDS_Buffer = _DSnd_CreateSoundBuffer($oDS, BitOR($DSBCAPS_GLOBALFOCUS, $DSBCAPS_CTRLFX), BinaryLen($aWav[0]), $aWav[1].Channels, $aWav[1].SamplesPerSec, $aWav[1].BitsPerSample, $aWav[1].FormatTag)
	If @error Then Return MsgBox(16, "Error", _DSnd_ErrorMessage(@error) & @CRLF & @CRLF & "DirectSound-FX can process 8-bit or 16-bit PCM data, as well as 32-bit floating-point formats.")

	Local $aLock = _DSnd_BufferLock($oDS_Buffer)
	Local $tLock = DllStructCreate("byte[" & $aLock[1] & "];", $aLock[0])
	DllStructSetData($tLock, 1, $aWav[0])
	_DSnd_BufferUnLock($oDS_Buffer, $aLock)



	Local $aFX[3]
	$aFX[0] = 2
	$aFX[1] = $sGUID_DSFX_STANDARD_ECHO
	$aFX[2] = $sGUID_DSFX_STANDARD_GARGLE
	_DSnd_BufferSetFX($oDS_Buffer, $aFX)



	Local $oFX_Echo = _DSnd_BufferGetObjectInPath($oDS_Buffer, 0, $sIID_IDirectSoundFXEcho, $tagIDirectSoundFXEcho)

	Local $tFX_EchoParams = DllStructCreate($tagDSFXEcho)
	$oFX_Echo.GetAllParameters($tFX_EchoParams)
	ConsoleWrite("> WetDryMix:  " & $tFX_EchoParams.WetDryMix & @CRLF)
	ConsoleWrite("> Feedback:   " & $tFX_EchoParams.Feedback & @CRLF)
	ConsoleWrite("> LeftDelay:  " & $tFX_EchoParams.LeftDelay & @CRLF)
	ConsoleWrite("> RightDelay: " & $tFX_EchoParams.RightDelay & @CRLF)
	ConsoleWrite("> PanDelay:   " & $tFX_EchoParams.PanDelay & @CRLF)

	$tFX_EchoParams.LeftDelay = 180
	$tFX_EchoParams.RightDelay = 240
	$oFX_Echo.SetAllParameters($tFX_EchoParams)


	_DSnd_BufferPlay($oDS_Buffer, $DSBPLAY_LOOPING)

	MsgBox(0, "", "click OK to stop")

	$oFX_Echo = 0

	$oDS_Buffer.Stop()
	$oDS_Buffer = 0
	$oDS = 0
EndFunc   ;==>_Example