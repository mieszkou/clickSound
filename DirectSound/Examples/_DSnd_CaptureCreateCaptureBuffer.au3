#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6
;#AutoIt3Wrapper_UseX64 = y
#include "..\DirectSound.au3"
#include <WinAPIProc.au3> ;needed for _WinAPI_ResetEvent
#include <Misc.au3>

; -------------------------------------------------------------------------------------------
; | Record SoundcardInput und save as wav
; -------------------------------------------------------------------------------------------


_Example()



Func _Example()
	Local $iBytes = _DSnd_Seconds2Bytes(2)

	Local $oDSC = _DSnd_CaptureCreate()
	If @error Then Return MsgBox(16, "Error", _DSnd_ErrorMessage(@error))

	Local $aCaps = _DSnd_CaptureGetCaps($oDSC)
	If Not BitAND($aCaps[1], $WAVE_FORMAT_4S16) Then Return MsgBox(16, "Error", "Stereo 44100Hz 16Bit not supported")

	Local $oDSC_Buffer = _DSnd_CaptureCreateCaptureBuffer($oDSC, $iBytes)
	If @error Then Return MsgBox(16, "Error", _DSnd_ErrorMessage(@error))



	;Set NotificationPoints
	Local $oNotify = _DSnd_NotifyCreate($oDSC_Buffer)

	Local $aPositions[4][2]
	$aPositions[0][0] = 3
	;Set first NotificationPoint to beginning of buffer
	$aPositions[1][0] = 0
	$aPositions[1][1] = _WinAPI_CreateEvent(0, True, False)
	;Set second NotificationPoint to middle of the buffer
	$aPositions[2][0] = $iBytes * 0.5
	$aPositions[2][1] = _WinAPI_CreateEvent(0, True, False)
	;Set third NotificationPoint to end of AudioTrack
	$aPositions[3][0] = $DSBPN_OFFSETSTOP
	$aPositions[3][1] = _WinAPI_CreateEvent(0, True, False)


	Local $tNotify = _DSnd_NotifySetPositions($oNotify, $aPositions)



	$oDSC_Buffer.Start($DSCBSTART_LOOPING)

	Local $iEvent, $aLock, $tLock, $bPCM, $iRecCursor, $iReadCursor, $iDataLeft
	While 1
		$iEvent = _WinAPI_WaitForMultipleObjects($tNotify.Cnt, $tNotify.Events, False, 100) ;wait for events; TimeOut = 100ms
		Switch $iEvent
			Case 0
				;Recording Cursor
				; |>
				;[..............................##############################]
				;                               |____________________________|
				;                                           Get Data (if not the first time)

				If Not IsBinary($bPCM) Then ;if first time, reset PCM Data; (there is no recorded data in buffer)
					$bPCM = BinaryMid(0, 1, 0)
				Else
					$aLock = _DSnd_CaptureBufferLock($oDSC_Buffer, $iBytes / 2, 0, $iBytes / 2) ;Lock Buffer
					$tLock = DllStructCreate("byte[" & $aLock[1] & "];", $aLock[0])
					$bPCM &= DllStructGetData($tLock, 1)
					_DSnd_CaptureBufferUnlock($oDSC_Buffer, $aLock)
				EndIf
				_WinAPI_ResetEvent($tNotify.hEvent(1))
				ToolTip(_DSnd_Bytes2Seconds(BinaryLen($bPCM)) & "s recorded" & @CRLF & "Hit ESC to stop")


			Case 1
				;                         Recording Cursor
				;                               |>
				;[##############################..............................]
				; |____________________________|
				;          Get Data

				$aLock = _DSnd_CaptureBufferLock($oDSC_Buffer, $iBytes / 2, 0)
				$tLock = DllStructCreate("byte[" & $aLock[1] & "];", $aLock[0])
				$bPCM &= DllStructGetData($tLock, 1)
				_DSnd_CaptureBufferUnlock($oDSC_Buffer, $aLock)
				_WinAPI_ResetEvent($tNotify.hEvent(2))
				ToolTip(_DSnd_Bytes2Seconds(BinaryLen($bPCM)) & "s recorded" & @CRLF & "Hit ESC to stop")



			Case 2 ;Capture Stop -> there is still data in the buffer
				Switch Mod(BinaryLen($bPCM), $iBytes)
					Case 0
						;    Recording Cursor
						;            |>
						;[###########...................XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX]
						; |_________|                   |____________________________|
						;    Data                            (last data in $bPCM)

						$oDSC_Buffer.GetCurrentPosition($iRecCursor, $iReadCursor)
						$iDataLeft = $iRecCursor
						$aLock = _DSnd_CaptureBufferLock($oDSC_Buffer, $iDataLeft, 0)
						$tLock = DllStructCreate("byte[" & $aLock[1] & "];", $aLock[0])
						$bPCM &= DllStructGetData($tLock, 1)
						_DSnd_CaptureBufferUnlock($oDSC_Buffer, $aLock)


					Case Else
						;                                     Recording Cursor
						;                                             |>
						;[XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX##############................]
						; |____________________________||____________|
						;     (last data in $bPCM)           Data

						$oDSC_Buffer.GetCurrentPosition($iRecCursor, $iReadCursor)
						$iDataLeft = $iRecCursor - $iBytes * 0.5
						$aLock = _DSnd_CaptureBufferLock($oDSC_Buffer, $iDataLeft, 0, $iBytes * 0.5)
						$tLock = DllStructCreate("byte[" & $aLock[1] & "];", $aLock[0])
						$bPCM &= DllStructGetData($tLock, 1)
						_DSnd_CaptureBufferUnlock($oDSC_Buffer, $aLock)

				EndSwitch

				_WinAPI_ResetEvent($tNotify.hEvent(2))
				ExitLoop

			Case -1 ;Error
				ExitLoop

			Case Else ;Timeout
				;Do something else; _WinAPI_WaitForMultipleObjects is like a Sleep(100) in this Loop
		EndSwitch

		If _IsPressed("1B") Then $oDSC_Buffer.Stop()

	WEnd

	ToolTip("")

	For $i = 1 To $tNotify.Cnt
		_WinAPI_CloseHandle($tNotify.hEvent(($i)))
	Next

	$oNotify = 0
	$oDSC_Buffer = 0
	$oDSC = 0

	If MsgBox(4, "", _DSnd_Seconds2Time(_DSnd_Bytes2Seconds(BinaryLen($bPCM))) & " recorded..." & @CRLF & @CRLF & "Save to disk?") = 6 Then

		;Save $bPCM as wav
		Local $tagDSWAVEHEADER = "struct; char RIFF[4]; uint FileSize; char WAVE[4]; char FMT[4]; uint FMTLen; word Format; word Channels; uint SampleRate; uint BytesPerSec; word BlockAlign; word BitsPerSample; char DATA[4]; uint DATALen; endstruct;"

		Local $tWave = DllStructCreate($tagDSWAVEHEADER & " byte WAVDATA[" & BinaryLen($bPCM) & "];")
		DllStructSetData($tWave, "RIFF", "RIFF")
		DllStructSetData($tWave, "FileSize", BinaryLen($bPCM) + 44 - 8)
		DllStructSetData($tWave, "WAVE", "WAVE")
		DllStructSetData($tWave, "FMT", "fmt ")
		DllStructSetData($tWave, "FMTLen", 16)
		DllStructSetData($tWave, "Format", $WAVE_FORMAT_PCM)
		DllStructSetData($tWave, "Channels", 2)
		DllStructSetData($tWave, "SampleRate", 44100)
		DllStructSetData($tWave, "BytesPerSec", 44100 * 2 * 2)
		DllStructSetData($tWave, "BlockAlign", 4)
		DllStructSetData($tWave, "BitsPerSample", 16)
		DllStructSetData($tWave, "DATA", "data")
		DllStructSetData($tWave, "DATALen", BinaryLen($bPCM))

		DllStructSetData($tWave, "WAVDATA", $bPCM)

		Local $tData = DllStructCreate("byte[" & DllStructGetSize($tWave) & "];", DllStructGetPtr($tWave))
		Local $hFile = FileOpen(@MyDocumentsDir & "\DS_Recording.wav", BitOR(2, 8, 16))
		FileWrite($hFile, DllStructGetData($tData, 1))
		FileClose($hFile)

		;play
		ShellExecute(@MyDocumentsDir & "\DS_Recording.wav")

	EndIf
EndFunc   ;==>_Example