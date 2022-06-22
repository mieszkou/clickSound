#include <Misc.au3>
#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6
;#AutoIt3Wrapper_UseX64 = y
#include "DirectSound.au3"
#include <MsgBoxConstants.au3>
#include <StringConstants.au3>
#include <TrayConstants.au3> ; Required for the $TRAY_ICONSTATE_SHOW constant.


; Tray menu

Opt("TrayMenuMode",3)

Local $id1 = 		 TrayCreateItem("clickSound 0.0.2")
Local $idSep1 =	 TrayCreateItem("") ; Create a separator line.
Local $idAbout = TrayCreateItem("O clickSound ...")
Local $idWww =  TrayCreateItem("Otwórz pajcomp.pl")
Local $idSep2 =	 TrayCreateItem("") ; Create a separator line.
Local $idExit =    TrayCreateItem("Wyjście")

TrayItemSetState($id1, $TRAY_DISABLE)
TraySetToolTip ( "clickSound" )
TraySetState($TRAY_ICONSTATE_SHOW) ; Show the tray menu.

; Ustawienie generowanego dzwieku

Global $aKeyStillPressed[255] ;used to keep track of keystate
Global $u32dll = DllOpen("user32.dll") ;I strongly suggest using DllOpen for speed when running _Ispressed in such a tight loop

Global $fSineFreq = 500 ;Frequency of SineWave
Global $iSampleRate = 22050 ;Samples per Second

Global $fLambda = $iSampleRate / $fSineFreq ;WaveLength
Global $iSamples = Ceiling($fLambda * 20) ;1000 SineWaves

Global $oDS = _DSnd_Create()
Global $oDS_Buffer = _DSnd_CreateSoundBuffer($oDS, $DSBCAPS_GLOBALFOCUS, $iSamples * 2, 1, $iSampleRate) ;16Bit Mono

Global $aLock = _DSnd_BufferLock($oDS_Buffer) ;Lock Buffer for Writing - $aLock[0] is the Pointer of the first Sample
Global $tBuffer = DllStructCreate("short Smp[" & $aLock[1] / 2 & "];", $aLock[0]) ;$aLock[1] is the number of bytes(=8Bit) - we use 16 Bits per Sample
Global $fPhase = 0, $fPhaseInc = (ATan(1) * 8) / $iSampleRate * $fSineFreq
For $i = 1 To $iSamples
	$tBuffer.Smp(($i)) = Sin($fPhase) * 12000 ;Amplitude 12000 (16Bit Range = -2^15..2^15-1)
	$fPhase += $fPhaseInc
Next
_DSnd_BufferUnLock($oDS_Buffer, $aLock)

;  Ustawienie generowanego dzwieku - END


; Main loop

While True
    ; 01 - left mouse click
	If _IsPressedEx('01') Then
		_DSnd_BufferPlay($oDS_Buffer) ;Loop Buffer
		Sleep(100)
	EndIf
	
	Switch TrayGetMsg()
			Case $idAbout ; Display a message box about the AutoIt version and installation path of the AutoIt executable.
					MsgBox($MB_SYSTEMMODAL, "", "clickSound - www.pajcomp.pl." & @CRLF & _
									"Dzwięk przy dotyku" & @CRLF & @CRLF & _
									"Katalog: " & StringLeft(@AutoItExe, StringInStr(@AutoItExe, "\", $STR_NOCASESENSEBASIC, -1) - 1)) ; Find the folder of a full path.
			Case $idWww ;
									ShellExecute("http://www.pajcomp.pl")
		 
			Case $idExit ; Exit the loop.
					_Exit()
		EndSwitch
WEnd

Func _IsPressedEx($hexKey)
    Local $iKey = Dec($hexKey)
    If $iKey > 255 Or $iKey < 0 Then Return SetError(1,0,0)
    Local $aR = DllCall($u32dll, "int", "GetAsyncKeyState", "int",'0x' & $hexKey)
    If @error Then Return SetError(2,0,0)
    If $aKeyStillPressed[$iKey] Then ;If the key was already registered as pressed
        If BitAND($aR[0], 0x8000) <> 0x8000 Then $aKeyStillPressed[$iKey] = False ;Check if it is still pressed and update if needed
        Return 0 ;do nothing
    ElseIf BitAND($aR[0], 0x8000) = 0x8000 Then ;If the key wasn't registered as pressed, but is pressed now it must be a new keypress
        $aKeyStillPressed[$iKey] = True ;Update the pressed status
        Return 1
    EndIf
    Return 0
EndFunc

Func _Exit()
    DllClose($u32dll)
    Exit
EndFunc

Func OnAutoItExit()
    ;Free Resources
	$oDS_Buffer.Stop()
$oDS_Buffer = 0
$oDS = 0
EndFunc   ;==>OnAutoItExit









