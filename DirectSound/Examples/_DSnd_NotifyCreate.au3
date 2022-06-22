#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6
;#AutoIt3Wrapper_UseX64 = y
#include "..\DirectSound.au3"
#include <WinAPIProc.au3> ;needed for _WinAPI_ResetEvent


; -------------------------------------------------------------------------------------------
; | Notification Points
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
	Local $oDS_Buffer = _DSnd_CreateSoundBuffer($oDS, BitOR($DSBCAPS_GLOBALFOCUS, $DSBCAPS_CTRLPOSITIONNOTIFY), BinaryLen($aWav[0]), $aWav[1].Channels, $aWav[1].SamplesPerSec, $aWav[1].BitsPerSample, $aWav[1].FormatTag)

	Local $aLock = _DSnd_BufferLock($oDS_Buffer)
	Local $tLock = DllStructCreate("byte[" & $aLock[1] & "];", $aLock[0])
	DllStructSetData($tLock, 1, $aWav[0])
	_DSnd_BufferUnLock($oDS_Buffer, $aLock)



	;Set NotificationPoints
	Local $oNotify = _DSnd_NotifyCreate($oDS_Buffer)

	Local $aPositions[4][2]
	$aPositions[0][0] = 3
	;Set first NotificationPoint to 1 second (in bytes)
	$aPositions[1][0] = _DSnd_Seconds2Bytes(1, $aWav[1].Channels, $aWav[1].SamplesPerSec, $aWav[1].BitsPerSample)
	$aPositions[1][1] = _WinAPI_CreateEvent(0, True, False)
	;Set second NotificationPoint to middle of AudioTrack
	$aPositions[2][0] = BinaryLen($aWav[0]) * 0.5
	$aPositions[2][1] = _WinAPI_CreateEvent(0, True, False)
	;Set third NotificationPoint to end of AudioTrack
	$aPositions[3][0] = $DSBPN_OFFSETSTOP
	$aPositions[3][1] = _WinAPI_CreateEvent(0, True, False)


	Local $tNotify = _DSnd_NotifySetPositions($oNotify, $aPositions)




	;Start
	_DSnd_BufferPlay($oDS_Buffer)


	Local $iEvent
	While 1
		$iEvent = _WinAPI_WaitForMultipleObjects($tNotify.Cnt, $tNotify.Events, False, 100) ;wait for events; TimeOut = 100ms
		Switch $iEvent
			Case 0
				ConsoleWrite("> Position: 1 Second" & @CRLF)
				_WinAPI_ResetEvent($tNotify.hEvent(1))
			Case 1
				ConsoleWrite("> Position: Middle" & @CRLF)
				_WinAPI_ResetEvent($tNotify.hEvent(2))
			Case 2
				ConsoleWrite("> Position: End" & @CRLF)
				_WinAPI_ResetEvent($tNotify.hEvent(2))
				ExitLoop
			Case -1 ;Error
				ExitLoop
			Case Else ;Timeout
				;Do something else; _WinAPI_WaitForMultipleObjects is like a Sleep(100) in this Loop
		EndSwitch
	WEnd


	For $i = 1 To $tNotify.Cnt
		_WinAPI_CloseHandle($tNotify.hEvent(($i)))
	Next

	$oNotify = 0
	$oDS_Buffer = 0
	$oDS = 0
EndFunc   ;==>_Example