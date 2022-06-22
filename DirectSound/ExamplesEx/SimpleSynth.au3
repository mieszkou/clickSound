#include "..\DirectSound.au3"
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <WinAPIProc.au3> ;needed for _WinAPI_ResetEvent
#include <GDIPlus.au3>
Opt("GUIOnEventMode", 1)



Global $aKeys = _CreateKeyMatrix("y|s|x|d|c|v|g|b|h|n|j|m|q|2|w|3|e|r|5|t|6|z|7|u|i|9|o|0|p") ;german keyboard layout
;Global $aKeys = _CreateKeyMatrix("z|s|x|d|c|v|g|b|h|n|j|m|q|2|w|3|e|r|5|t|6|y|7|u|i|9|o|0|p") ;english keyboard layout



Global Const $cMSEC = 10000 ;One millisecond (in 100 nanosec units)

Global Const $cfBaseFreq = 68.90625 ;To get exact integer Lambda(44100/Freq) for each octave: 640, 320, 160, 80, 40, 20, 10, 5
Global Const $ciSampleRate = 44100
Global Const $ciMaxPolyPhony = 16
Global Const $ciADRMax = 500 ;Attack=Max Decay=Max Release=Max*2


Global $iOctave = 3 ;[0..5]
Global $iWaveForm = 1

Global $iAttack = $ciADRMax * 0.05
Global $iDecay = $ciADRMax * 0.1
Global $iSustain = -12
Global $iRelease = $ciADRMax * 1.5



Global $bFX_Echo = False
Global $bFX_Chorus = False
Global $bFX_Flanger = False
Global $bFX_Gargle = False

Global $fFX_EchoFB = 50
Global $fFX_EchoLD = 500
Global $fFX_EchoRD = 500

Global $fFX_ChorusDP = 10
Global $fFX_ChorusFB = 25
Global $fFX_ChorusFR = 1.1

Global $fFX_FlangerDP = 100
Global $fFX_FlangerFB = -50
Global $fFX_FlangerFR = 0.25

Global $fFX_Gargle = 20




Global $fPhaseShift = 0
Global $fPulseWidth = 0



Global $aNotifyEvents = _NotifyEventsCreate($ciMaxPolyPhony)

Global $tBaseOSC = _BaseOSC_CalcAliasFree($iOctave, $iWaveForm, $fPhaseShift, $fPulseWidth)
Global $tBaseSample = _BaseSample_Create($tBaseOSC)

Global $oDS = _DSnd_Create()
Global $aPolySample = _PolySampleCreate($oDS, $ciMaxPolyPhony, $tBaseSample.Cnt * 2 * 4)




Global $iGui_W = 800
Global $iGui_H = 390
Global $hGui = GUICreate("SimpleSynth by Eukalyptus", $iGui_W, $iGui_H)
GUISetOnEvent($GUI_EVENT_CLOSE, "_Exit")

GUICtrlCreateGroup("WaveForm", 20, 10, 200, 205)
GUICtrlCreateLabel("Octave", 30, 30, 50, 20, BitOR(0x0200, 0x0002))
Global $cIP_Octave = GUICtrlCreateInput($iOctave, 90, 30, 40, 20, 0x0800)
GUICtrlSetOnEvent(-1, "_SetOctave")
GUICtrlCreateUpdown(-1)
GUICtrlSetLimit(-1, 5, 0)
Global $cRB_Sine = GUICtrlCreateRadio("Sine", 40, 55, 80, 20)
GUICtrlSetState(-1, 1)
GUICtrlSetOnEvent(-1, "_SetWaveForm")
Global $cRB_Square = GUICtrlCreateRadio("Square", 40, 75, 80, 20)
GUICtrlSetOnEvent(-1, "_SetWaveForm")
Global $cRB_Saw = GUICtrlCreateRadio("SawTooth", 40, 95, 80, 20)
GUICtrlSetOnEvent(-1, "_SetWaveForm")
Global $cRB_Triangle = GUICtrlCreateRadio("Triangle", 40, 115, 80, 20)
GUICtrlSetOnEvent(-1, "_SetWaveForm")
Global $cRB_Pulse = GUICtrlCreateRadio("PulseWidth:", 40, 135, 80, 20)
GUICtrlSetOnEvent(-1, "_SetWaveForm")
Global $cSL_Pulse = GUICtrlCreateSlider(130, 135, 80, 20, BitOR(0x0008, 0x0010))
GUICtrlSetOnEvent(-1, "_SetPulseWidth")
GUICtrlCreateLabel("PhaseShift Right:", 40, 165, 85, 20, BitOR(0x0200, 0))
Global $cSL_Phase = GUICtrlCreateSlider(130, 165, 80, 20, BitOR(0x0008, 0x0010))
GUICtrlSetOnEvent(-1, "_SetPhaseShift")
Global $cCB_Alias = GUICtrlCreateCheckbox("AliasFree", 40, 185, 100, 20)
GUICtrlSetState(-1, $GUI_CHECKED)
GUICtrlSetOnEvent(-1, "_SetPhaseShift")
Global $cCB_View = GUICtrlCreateCheckbox("View", 150, 185, 50, 20)
GUICtrlSetOnEvent(-1, "_ShowOSC")


GUICtrlCreateGroup("ADSR", 240, 10, 120, 205)
Global $cSL_Attack = GUICtrlCreateSlider(257, 80, 20, 130, BitOR(0x0002, 0x0010, 0x0008))
GUICtrlSetData(-1, 100 - ($iAttack / $ciADRMax * 200))
GUICtrlSetOnEvent(-1, "_SetEnv")
Global $cSL_Decay = GUICtrlCreateSlider(280, 80, 20, 130, BitOR(0x0002, 0x0010, 0x0008))
GUICtrlSetData(-1, 100 - ($iDecay / $ciADRMax * 200))
GUICtrlSetOnEvent(-1, "_SetEnv")
Global $cSL_Sustain = GUICtrlCreateSlider(303, 80, 20, 130, BitOR(0x0002, 0x0010, 0x0008))
GUICtrlSetLimit(-1, 40, 0)
GUICtrlSetData(-1, -$iSustain)
GUICtrlSetOnEvent(-1, "_SetEnv")
Global $cSL_Release = GUICtrlCreateSlider(326, 80, 20, 130, BitOR(0x0002, 0x0010, 0x0008))
GUICtrlSetData(-1, 100 - ($iRelease / $ciADRMax * 50))
GUICtrlSetOnEvent(-1, "_SetEnv")


GUICtrlCreateGroup("FX", 380, 10, 400, 135)

Global $cCB_Echo = GUICtrlCreateCheckbox("Echo", 400, 26, 60, 20)
GUICtrlSetOnEvent(-1, "_SetFX")
GUICtrlCreateLabel("FeedBack:", 400, 50, 80, 10)
GUICtrlSetFont(-1, 6)
Global $cSL_EchoFB = GUICtrlCreateSlider(395, 60, 80, 20, BitOR(0x0010, 0x0008))
GUICtrlSetOnEvent(-1, "_SetFXParam")
GUICtrlSetLimit(-1, 100, 0);Feedback: 50 [0..100]
GUICtrlSetData(-1, 50)
GUICtrlCreateLabel("Left Delay:", 400, 80, 80, 10)
GUICtrlSetFont(-1, 6)
Global $cSL_EchoLD = GUICtrlCreateSlider(395, 90, 80, 20, BitOR(0x0010, 0x0008))
GUICtrlSetOnEvent(-1, "_SetFXParam")
GUICtrlSetLimit(-1, 300, 10);LeftDelay: 500 [1..2000]
GUICtrlSetData(-1, 180)
GUICtrlCreateLabel("Right Delay:", 400, 110, 80, 10)
GUICtrlSetFont(-1, 6)
Global $cSL_EchoRD = GUICtrlCreateSlider(395, 120, 80, 20, BitOR(0x0010, 0x0008))
GUICtrlSetOnEvent(-1, "_SetFXParam")
GUICtrlSetLimit(-1, 300, 10);RightDelay: 500 [1..2000]
GUICtrlSetData(-1, 240)

Global $cCB_Chorus = GUICtrlCreateCheckbox("Chorus", 495, 26, 60, 20)
GUICtrlSetOnEvent(-1, "_SetFX")
GUICtrlCreateLabel("Depth:", 495, 50, 80, 10)
GUICtrlSetFont(-1, 6)
Global $cSL_ChorusDP = GUICtrlCreateSlider(490, 60, 80, 20, BitOR(0x0010, 0x0008))
GUICtrlSetOnEvent(-1, "_SetFXParam")
GUICtrlSetLimit(-1, 100, 0);Depth: 10 [0..100]
GUICtrlSetData(-1, 10)
GUICtrlCreateLabel("Feedback:", 495, 80, 80, 10)
GUICtrlSetFont(-1, 6)
Global $cSL_ChorusFB = GUICtrlCreateSlider(490, 90, 80, 20, BitOR(0x0010, 0x0008))
GUICtrlSetOnEvent(-1, "_SetFXParam")
GUICtrlSetLimit(-1, 99, -99);Feedback: 25 [-99..99]
GUICtrlSetData(-1, 25)
GUICtrlCreateLabel("Frequency:", 495, 110, 80, 10)
GUICtrlSetFont(-1, 6)
Global $cSL_ChorusFR = GUICtrlCreateSlider(490, 120, 80, 20, BitOR(0x0010, 0x0008))
GUICtrlSetOnEvent(-1, "_SetFXParam")
GUICtrlSetLimit(-1, 100, 0);Frequency: 1.1 [0..10]
GUICtrlSetData(-1, 11)

Global $cCB_Flanger = GUICtrlCreateCheckbox("Flanger", 590, 26, 60, 20)
GUICtrlSetOnEvent(-1, "_SetFX")
GUICtrlCreateLabel("Depth:", 590, 50, 80, 10)
GUICtrlSetFont(-1, 6)
Global $cSL_FlangerDP = GUICtrlCreateSlider(585, 60, 80, 20, BitOR(0x0010, 0x0008))
GUICtrlSetOnEvent(-1, "_SetFXParam")
GUICtrlSetLimit(-1, 100, 0);Depth: 100 [0..100]
GUICtrlSetData(-1, 100)
GUICtrlCreateLabel("Feedback:", 590, 80, 80, 10)
GUICtrlSetFont(-1, 6)
Global $cSL_FlangerFB = GUICtrlCreateSlider(585, 90, 80, 20, BitOR(0x0010, 0x0008))
GUICtrlSetOnEvent(-1, "_SetFXParam")
GUICtrlSetLimit(-1, 99, -99);Feedback: -50 [-99..99]
GUICtrlSetData(-1, -50)
GUICtrlCreateLabel("Frequency:", 590, 110, 80, 10)
GUICtrlSetFont(-1, 6)
Global $cSL_FlangerFR = GUICtrlCreateSlider(585, 120, 80, 20, BitOR(0x0010, 0x0008))
GUICtrlSetOnEvent(-1, "_SetFXParam")
GUICtrlSetLimit(-1, 100, 0);Frequency: 0.25 [0..10]
GUICtrlSetData(-1, 2)

Global $cCB_Gargle = GUICtrlCreateCheckbox("Gargle", 685, 26, 60, 20)
GUICtrlSetOnEvent(-1, "_SetFX")
GUICtrlCreateLabel("Rate:", 685, 50, 80, 10)
GUICtrlSetFont(-1, 6)
Global $cSL_Gargle = GUICtrlCreateSlider(680, 60, 80, 20, BitOR(0x0010, 0x0008))
GUICtrlSetOnEvent(-1, "_SetFXParam")
GUICtrlSetLimit(-1, 1000, 1);RateHz: 20 [1..1000]
GUICtrlSetData(-1, 20)
GUICtrlCreateGroup("Polyphony", 380, 160, 400, 55)
Global $cIP_Poly = GUICtrlCreateInput($ciMaxPolyPhony, 400, 182, 40, 20, 0x0800)
GUICtrlCreateUpdown(-1)
GUICtrlSetLimit(-1, $ciMaxPolyPhony, 1)
GUICtrlSetOnEvent(-1, "_SetPolyPhony")



_GDIPlus_Startup()
Global $hGraphics = _GDIPlus_GraphicsCreateFromHWND($hGui)
Global $hBmpBuffer = _GDIPlus_BitmapCreateFromScan0($iGui_W, $iGui_H)
Global $hGfxBuffer = _GDIPlus_ImageGetGraphicsContext($hBmpBuffer)
_GDIPlus_GraphicsSetSmoothingMode($hGfxBuffer, 2)
Global $hBrushKey = _GDIPlus_BrushCreateSolid(0x80FF00FF)
Global $aKeyboard = _KeyBoard_Create($iGui_W - 20, $iGui_H - 240, 10, 230)

Global $hBmpOSC = _GDIPlus_BitmapCreateFromScan0(64, 64)
Global $hGfxOSC = _GDIPlus_ImageGetGraphicsContext($hBmpOSC)
_GDIPlus_GraphicsSetSmoothingMode($hGfxOSC, 2)

Global $hPenOSC_L = _GDIPlus_PenCreate(0xFF00FF00, 2)
_GDIPlus_PenSetLineJoin($hPenOSC_L, 2)
Global $hPenOSC_R = _GDIPlus_PenCreate(0xFFCC0000, 2)
_GDIPlus_PenSetLineJoin($hPenOSC_R, 2)

Global $hBmpPoly = _GDIPlus_BitmapCreateFromScan0(320, 24)
Global $hGfxPoly = _GDIPlus_ImageGetGraphicsContext($hBmpPoly)
_GDIPlus_GraphicsSetSmoothingMode($hGfxPoly, 2)
Global $hPenPoly = _GDIPlus_PenCreate(0x88666666, 2)
Global $hBrushPoly_Play = _GDIPlus_BrushCreateSolid(0xFF00FF00)
Global $hBrushPoly_Stop = _GDIPlus_BrushCreateSolid(0xFF0000FF)
Global $hBrushPoly_Release = _GDIPlus_BrushCreateSolid(0xFFFFAA00)
Global $hBrushPoly_Dis = _GDIPlus_BrushCreateSolid(0xFFFF0000)

Global $hBmpADSR = _GDIPlus_BitmapCreateFromScan0(100, 42)
Global $hGfxADSR = _GDIPlus_ImageGetGraphicsContext($hBmpADSR)
_GDIPlus_GraphicsSetSmoothingMode($hGfxADSR, 2)

Global $hPenADSR = _GDIPlus_PenCreate(0xFF00FF00, 2)
_GDIPlus_PenSetLineJoin($hPenADSR, 2)

Global $cIP_Key = GUICtrlCreateInput("", 10, -40, 100, 20, 0x0800) ;workaround

GUIRegisterMsg($WM_PAINT, "WM_PAINT")
GUISetState()


Global $hGui_OSCView = GUICreate("OSC", 500, 500)
GUISetOnEvent($GUI_EVENT_CLOSE, "_HideOSC")
GUISetState(@SW_HIDE, $hGui_OSCView)
Global $hGraphics_OSC = _GDIPlus_GraphicsCreateFromHWND($hGui_OSCView)
Global $hBmpBuffer_OSC = _GDIPlus_BitmapCreateFromScan0(500, 500)
Global $hGfxBuffer_OSC = _GDIPlus_ImageGetGraphicsContext($hBmpBuffer_OSC)
_GDIPlus_GraphicsSetSmoothingMode($hGfxBuffer_OSC, 2)
_GDIPlus_GraphicsScaleTransform($hGfxBuffer_OSC, 500 / 64, 500 / 64)

_SetFXParam()
_DrawKeyBoard()
_DrawOSC()
_DrawADSR()
_DrawPoly()



Global $tKeys = DllStructCreate("byte[256];")
Global $iEvent, $iPolyIndex, $iPolySubIndex, $aInfo
While 1
	$iEvent = _WinAPI_WaitForMultipleObjects($aNotifyEvents[0][0], DllStructGetPtr($aNotifyEvents[0][1]), False, 10) ;wait for events; TimeOut = 10ms (like a Sleep(10) if no Event)
	Switch $iEvent
		Case 0 To $aNotifyEvents[0][0]
			$iPolyIndex = Floor($iEvent / 3) + 1
			$iPolySubIndex = Mod($iEvent, 3)

			Switch $iPolySubIndex
				Case 0 ;Begin
					_PolySampleAddSamples($aPolySample, $iPolyIndex, 2)
				Case 1 ;Middle
					_PolySampleAddSamples($aPolySample, $iPolyIndex, 1)
				Case 2 ;Stop
					If $aPolySample[$iPolyIndex][0] <> 1 Then
						$aPolySample[$iPolyIndex][0] = 0
						_DrawPoly()
					EndIf
			EndSwitch

			_WinAPI_ResetEvent(DllStructGetData($aNotifyEvents[0][1], 1, $iEvent + 1))

		Case -1 ;Error
			_Exit()
		Case 0x00000102 ;Timeout
	EndSwitch


	$aInfo = GUIGetCursorInfo($hGui)
	If IsArray($aInfo) Then
		If Not $aInfo[2] Then
			If Not BitAND(GUICtrlGetState($cIP_Key), $GUI_FOCUS) Then GUICtrlSetState($cIP_Key, $GUI_FOCUS) ;workaround
		EndIf
	EndIf


	DllCall("user32.dll", "uint", "GetKeyboardState", "struct*", $tKeys)
	For $i = 1 To $aKeys[0][0]
		If BitAND(DllStructGetData($tKeys, 1, $aKeys[$i][0]), 0xF0) Then
			_SynthNoteOn($i, BitAND(DllStructGetData($tKeys, 1, $aKeys[$i][0]), 0x0F))
		Else
			_SynthNoteOff($i)
		EndIf
	Next
WEnd





Func _SetFXParam()
	$fFX_EchoFB = GUICtrlRead($cSL_EchoFB)
	$fFX_EchoLD = GUICtrlRead($cSL_EchoLD)
	$fFX_EchoRD = GUICtrlRead($cSL_EchoRD)

	$fFX_ChorusDP = GUICtrlRead($cSL_ChorusDP)
	$fFX_ChorusFB = GUICtrlRead($cSL_ChorusFB)
	$fFX_ChorusFR = GUICtrlRead($cSL_ChorusFR) / 10

	$fFX_FlangerDP = GUICtrlRead($cSL_FlangerDP)
	$fFX_FlangerFB = GUICtrlRead($cSL_FlangerFB)
	$fFX_FlangerFR = GUICtrlRead($cSL_FlangerFR) / 10

	$fFX_Gargle = GUICtrlRead($cSL_Gargle)
EndFunc   ;==>_SetFXParam



Func _SetFX()
	$bFX_Echo = GUICtrlRead($cCB_Echo) = 1
	$bFX_Chorus = GUICtrlRead($cCB_Chorus) = 1
	$bFX_Flanger = GUICtrlRead($cCB_Flanger) = 1
	$bFX_Gargle = GUICtrlRead($cCB_Gargle) = 1
EndFunc   ;==>_SetFX



Func _SetOctave()
	$iOctave = GUICtrlRead($cIP_Octave)
	_SetPhaseShift()
EndFunc   ;==>_SetOctave



Func _SetPolyPhony()
	$aPolySample[0][0] = GUICtrlRead($cIP_Poly)
	_DrawPoly()
EndFunc   ;==>_SetPolyPhony



Func _HideOSC()
	GUICtrlSetState($cCB_View, $GUI_UNCHECKED)
	GUISetState(@SW_HIDE, $hGui_OSCView)
EndFunc



Func _ShowOSC()
	If GUICtrlRead($cCB_View) = 1 Then
		GUISetState(@SW_SHOWNOACTIVATE, $hGui_OSCView)
		_DrawOSC()
	Else
		GUISetState(@SW_HIDE, $hGui_OSCView)
	EndIf
EndFunc   ;==>_ShowOSC



Func _SetEnv()
	Switch @GUI_CtrlId
		Case $cSL_Attack
			$iAttack = ((101 - GUICtrlRead($cSL_Attack)) / 200) * $ciADRMax
		Case $cSL_Decay
			$iDecay = ((101 - GUICtrlRead($cSL_Decay)) / 200) * $ciADRMax
		Case $cSL_Release
			$iRelease = ((101 - GUICtrlRead($cSL_Release)) / 50) * $ciADRMax
		Case $cSL_Sustain
			$iSustain = -GUICtrlRead($cSL_Sustain)
		Case Else
			Return
	EndSwitch

	_DrawADSR()
EndFunc   ;==>_SetEnv



Func _SetPhaseShift()
	$fPhaseShift = GUICtrlRead($cSL_Phase) / 200
	If GUICtrlRead($cCB_Alias) = 1 Then
		$tBaseOSC = _BaseOSC_CalcAliasFree($iOctave, $iWaveForm, $fPhaseShift, $fPulseWidth)
	Else
		$tBaseOSC = _BaseOSC_CalcAlias($iOctave, $iWaveForm, $fPhaseShift, $fPulseWidth)
	EndIf

	$tBaseSample = _BaseSample_Create($tBaseOSC)

	_DrawOSC()
EndFunc   ;==>_SetPhaseShift



Func _SetPulseWidth()
	If $iWaveForm <> 5 Then Return

	$fPulseWidth = GUICtrlRead($cSL_Pulse) / 100
	If GUICtrlRead($cCB_Alias) = 1 Then
		$tBaseOSC = _BaseOSC_CalcAliasFree($iOctave, $iWaveForm, $fPhaseShift, $fPulseWidth)
	Else
		$tBaseOSC = _BaseOSC_CalcAlias($iOctave, $iWaveForm, $fPhaseShift, $fPulseWidth)
	EndIf
	$tBaseSample = _BaseSample_Create($tBaseOSC)

	_DrawOSC()
EndFunc   ;==>_SetPulseWidth



Func _SetWaveForm()
	Select
		Case GUICtrlRead($cRB_Sine) = 1
			If $iWaveForm = 1 Then Return
			$iWaveForm = 1
		Case GUICtrlRead($cRB_Square) = 1
			If $iWaveForm = 2 Then Return
			$iWaveForm = 2
		Case GUICtrlRead($cRB_Saw) = 1
			If $iWaveForm = 3 Then Return
			$iWaveForm = 3
		Case GUICtrlRead($cRB_Triangle) = 1
			If $iWaveForm = 4 Then Return
			$iWaveForm = 4
		Case GUICtrlRead($cRB_Pulse) = 1
			If $iWaveForm = 5 Then Return
			$iWaveForm = 5
		Case Else
			Return
	EndSelect

	If GUICtrlRead($cCB_Alias) = 1 Then
		$tBaseOSC = _BaseOSC_CalcAliasFree($iOctave, $iWaveForm, $fPhaseShift, $fPulseWidth)
	Else
		$tBaseOSC = _BaseOSC_CalcAlias($iOctave, $iWaveForm, $fPhaseShift, $fPulseWidth)
	EndIf

	$tBaseSample = _BaseSample_Create($tBaseOSC)

	_DrawOSC()
EndFunc   ;==>_SetWaveForm



Func _SynthNoteOff($iNote)
	If $aKeys[$iNote][2] > 0 Then
		If $aPolySample[$aKeys[$iNote][2]][0] = 1 Then
			_PolySampleNoteOff($aPolySample, $aKeys[$iNote][2])
			_DrawKeyBoard()
		EndIf
		$aKeys[$iNote][2] = 0
	EndIf
EndFunc   ;==>_SynthNoteOff



Func _SynthNoteOn($iNote, $bToogle)
	If $aKeys[$iNote][1] = $bToogle Then Return
	$aKeys[$iNote][1] = $bToogle

	$aKeys[$iNote][2] = _PolySampleNoteOn($aPolySample, $tBaseSample, $iNote)
	_DrawKeyBoard()
EndFunc   ;==>_SynthNoteOn



Func _PolySampleAddSamples(ByRef $aPolySample, $iIdx, $iMode = 1)
	Switch $iMode
		Case 1 ;Begin
			_MemMoveMemory($tBaseSample, $aPolySample[$iIdx][1], $aPolySample[$iIdx][2]) ;Copy SampleData to PolySampleBuffer
			$aPolySample[$iIdx][9].Process($aPolySample[$iIdx][2], $aPolySample[$iIdx][1], $aPolySample[$iIdx][5], 0) ;Calc AD[S]R

			$aPolySample[$iIdx][5] += $aPolySample[$iIdx][7]
			If $aPolySample[$iIdx][5] >= $aPolySample[$iIdx][6] Then _DSnd_BufferPlay($aPolySample[$iIdx][3]) ;UnLoop Buffer

			Local $aLock = _DSnd_BufferLock($aPolySample[$iIdx][3])
			$aLock[1] = $aPolySample[$iIdx][2]
			_MemMoveMemory($aPolySample[$iIdx][1], $aLock[0], $aLock[1])
			_DSnd_BufferUnLock($aPolySample[$iIdx][3], $aLock)


		Case 2 ;Middle
			_MemMoveMemory($tBaseSample, $aPolySample[$iIdx][1], $aPolySample[$iIdx][2]) ;Copy SampleData to PolySampleBuffer

			$aPolySample[$iIdx][9].Process($aPolySample[$iIdx][2], $aPolySample[$iIdx][1], $aPolySample[$iIdx][5], 0) ;Calc AD[S]R

			$aPolySample[$iIdx][5] += $aPolySample[$iIdx][7]
			If $aPolySample[$iIdx][5] >= $aPolySample[$iIdx][6] Then _DSnd_BufferPlay($aPolySample[$iIdx][3]) ;UnLoop Buffer

			Local $aLock = _DSnd_BufferLock($aPolySample[$iIdx][3], 0, $DSBLOCK_ENTIREBUFFER, $aPolySample[$iIdx][2])
			$aLock[1] = $aPolySample[$iIdx][2]
			$aLock[3] = 0
			_MemMoveMemory($aPolySample[$iIdx][1], $aLock[0], $aLock[1])
			_DSnd_BufferUnLock($aPolySample[$iIdx][3], $aLock)


		Case 3 ;Release
			Local $tRelease = DllStructCreate("byte[" & $aPolySample[$iIdx][2] * 2 & "]; byte[" & $tBaseOSC.Cnt * 8 & "];")
			_MemMoveMemory($tBaseSample, $tRelease, $aPolySample[$iIdx][2]) ;Copy SampleData to PolySampleBuffer
			_MemMoveMemory($tBaseSample, DllStructGetPtr($tRelease) + $aPolySample[$iIdx][2], $aPolySample[$iIdx][2]) ;Copy SampleData to PolySampleBuffer

			$aPolySample[$iIdx][5] = _DSnd_Bytes2Seconds($aPolySample[$iIdx][2], 2, $ciSampleRate, 32) * 1000 * $cMSEC * 10000

			$aPolySample[$iIdx][9].Process($aPolySample[$iIdx][2] * 2, $tRelease, $aPolySample[$iIdx][5], 0) ;Calc ADS[R]

			Local $iPlayCursor, $iWriteCursor
			$aPolySample[$iIdx][3].GetCurrentPosition($iPlayCursor, $iWriteCursor)
			Local $iMod = Mod($iWriteCursor, $tBaseOSC.Cnt * 8)

			Local $aLock = _DSnd_BufferLock($aPolySample[$iIdx][3], 0, $DSBLOCK_ENTIREBUFFER, $iWriteCursor)
			_MemMoveMemory(DllStructGetPtr($tRelease) + $iMod, $aLock[0], $aLock[1])
			If $aLock[3] > 0 Then
				_MemMoveMemory(DllStructGetPtr($tRelease) + $iMod + $aLock[1], $aLock[2], $aLock[3])
			EndIf
			_DSnd_BufferUnLock($aPolySample[$iIdx][3], $aLock)


			$aPolySample[$iIdx][5] += $aPolySample[$iIdx][7] * 2
			If $iWriteCursor <= $aPolySample[$iIdx][2] Then
				$aPolySample[$iIdx][5] -= _DSnd_Bytes2Seconds($iWriteCursor, 2, $ciSampleRate, 32) * 1000 * $cMSEC
			Else
				$aPolySample[$iIdx][5] -= _DSnd_Bytes2Seconds($iWriteCursor - $aPolySample[$iIdx][2], 2, $ciSampleRate, 32) * 1000 * $cMSEC
			EndIf

	EndSwitch
EndFunc   ;==>_PolySampleAddSamples




Func _PolySampleNoteOn(ByRef $aPolySample, $tBaseSample, $iNote)
	Local $iIdx = 0
	For $i = 1 To $aPolySample[0][0] ;Find NonPlaying
		If $aPolySample[$i][0] = 0 Then
			$iIdx = $i
			ExitLoop
		EndIf
	Next
	If $iIdx = 0 Then
		For $i = 1 To $aPolySample[0][0] ;Find active Release
			If $aPolySample[$i][0] <> 1 Then
				$iIdx = $i
				ExitLoop
			EndIf
		Next
	EndIf
	If $iIdx = 0 Then
		Local $iMax = 0
		For $i = 1 To $aPolySample[0][0] ;Take first triggered
			If $aPolySample[$i][5] > $iMax Then $iMax = $aPolySample[$i][5]
		Next
		For $i = 1 To $aPolySample[0][0]
			If $aPolySample[$i][5] >= $iMax Then
				$iIdx = $i
				ExitLoop
			EndIf
		Next
	EndIf

	If $iIdx = 0 Then $iIdx = 1 ;Take first


	$aPolySample[$iIdx][3].Stop()
	$aPolySample[$iIdx][3].SetCurrentPosition(0)

	Local $iPlayNote = $iNote + 24 + 12 * $iOctave
	Local $fFreq = 440 * 2 ^ (($iPlayNote - 69) / 12)

	Local $fTimeFactor = ($fFreq / $tBaseSample.Freq)
	Local $fSetFrequency = ($ciSampleRate * $fTimeFactor)
	$aPolySample[$iIdx][3].SetFrequency($fSetFrequency)



	Local $fAttack = $iAttack * $fTimeFactor
	Local $fDecay = $iDecay * $fTimeFactor
	Local $fRelease = $iRelease * $fTimeFactor

	Local $aEnv[4][6] = [[3]]
	$aEnv[1][0] = 0 ;AttackStart
	$aEnv[1][1] = $fAttack * $cMSEC ;AttackEnd
	$aEnv[1][2] = -50 ;Start at -50dB
	$aEnv[1][3] = 0 ;End at 0dB
	$aEnv[1][4] = $MP_CURVE_INVSQUARE

	$aEnv[2][0] = $aEnv[1][1] ;DecayStart = AttackEnd
	$aEnv[2][1] = ($fAttack + $fDecay) * $cMSEC
	$aEnv[2][2] = 0
	$aEnv[2][3] = $iSustain
	$aEnv[2][4] = $MP_CURVE_SQUARE

	$aEnv[3][0] = _DSnd_Bytes2Seconds($aPolySample[$iIdx][2], 2, $ciSampleRate, 32) * 1000 * $cMSEC * 10000
	$aEnv[3][1] = $aEnv[3][0] + $fRelease * $cMSEC ;Release-Time
	$aEnv[3][2] = $iSustain
	$aEnv[3][3] = -60
	$aEnv[3][4] = $MP_CURVE_SINE

	_DMO_MediaParamsAddEnvelope($aPolySample[$iIdx][10], $aEnv, 0) ;Set Envelope to Gain Parameter
	$aPolySample[$iIdx][5] = 0
	$aPolySample[$iIdx][6] = $aEnv[3][1]


	$aPolySample[$iIdx][0] = 1 ;Playing
	_PolySampleAddSamples($aPolySample, $iIdx, 1)


	Local $aPositions[4][2]
	$aPositions[0][0] = 3
	$aPositions[1][0] = 0
	$aPositions[1][1] = $aNotifyEvents[$iIdx][0]
	$aPositions[2][0] = $aPolySample[$iIdx][2] ;Middle (DSBuffer = PolyBuffer * 2)
	$aPositions[2][1] = $aNotifyEvents[$iIdx][1]
	$aPositions[3][0] = $DSBPN_OFFSETSTOP
	$aPositions[3][1] = $aNotifyEvents[$iIdx][2]
	_DSnd_NotifySetPositions($aPolySample[$iIdx][4], $aPositions)



	Local $aFX[5], $iFX_Echo, $iFX_Chorus, $iFX_Flanger, $iFX_Gargle
	If $bFX_Gargle Then
		$aFX[0] += 1
		$iFX_Gargle = $aFX[0]
		$aFX[$aFX[0]] = $sGUID_DSFX_STANDARD_GARGLE
	EndIf
	If $bFX_Chorus Then
		$aFX[0] += 1
		$iFX_Chorus = $aFX[0]
		$aFX[$aFX[0]] = $sGUID_DSFX_STANDARD_CHORUS
	EndIf
	If $bFX_Flanger Then
		$aFX[0] += 1
		$iFX_Flanger = $aFX[0]
		$aFX[$aFX[0]] = $sGUID_DSFX_STANDARD_FLANGER
	EndIf
	If $bFX_Echo Then
		$aFX[0] += 1
		$iFX_Echo = $aFX[0]
		$aFX[$aFX[0]] = $sGUID_DSFX_STANDARD_ECHO
	EndIf
	_DSnd_BufferSetFX($aPolySample[$iIdx][3], $aFX)


	Local $oFX, $tFX
	If $bFX_Gargle Then
		$tFX = DllStructCreate($tagDSFXGargle)
		$oFX = _DSnd_BufferGetObjectInPath($aPolySample[$iIdx][3], $iFX_Gargle - 1, $sIID_IDirectSoundFXGargle, $tagIDirectSoundFXGargle)
		$tFX.RateHz = $fFX_Gargle
		$tFX.WaveShape = 0
		$oFX.SetAllParameters($tFX)
	EndIf

	If $bFX_Chorus Then
		$tFX = DllStructCreate($tagDSFXChorus)
		$oFX = _DSnd_BufferGetObjectInPath($aPolySample[$iIdx][3], $iFX_Chorus - 1, $sIID_IDirectSoundFXChorus, $tagIDirectSoundFXChorus)
		$tFX.WetDryMix = 50
		$tFX.Depth = $fFX_ChorusDP
		$tFX.Feedback = $fFX_ChorusFB
		$tFX.Frequency = $fFX_ChorusFR
		$tFX.Waveform = 1
		$tFX.Delay = 16
		$tFX.Phase = 3
		$oFX.SetAllParameters($tFX)
	EndIf

	If $bFX_Flanger Then
		$tFX = DllStructCreate($tagDSFXFlanger)
		$oFX = _DSnd_BufferGetObjectInPath($aPolySample[$iIdx][3], $iFX_Flanger - 1, $sIID_IDirectSoundFXFlanger, $tagIDirectSoundFXFlanger)
		$tFX.WetDryMix = 50
		$tFX.Depth = $fFX_FlangerDP
		$tFX.Feedback = $fFX_FlangerFB
		$tFX.Frequency = $fFX_FlangerFR
		$tFX.Waveform = 1
		$tFX.Delay = 2
		$tFX.Phase = 2
		$oFX.SetAllParameters($tFX)
	EndIf

	If $bFX_Echo Then
		$tFX = DllStructCreate($tagDSFXEcho)
		$oFX = _DSnd_BufferGetObjectInPath($aPolySample[$iIdx][3], $iFX_Echo - 1, $sIID_IDirectSoundFXEcho, $tagIDirectSoundFXEcho)
		$tFX.WetDryMix = 50
		$tFX.Feedback = $fFX_EchoFB
		$tFX.LeftDelay = $fFX_EchoLD * $fTimeFactor
		$tFX.RightDelay = $fFX_EchoRD * $fTimeFactor
		$tFX.PanDelay = 0
		$oFX.SetAllParameters($tFX)
	EndIf

	_DSnd_BufferPlay($aPolySample[$iIdx][3], $DSBPLAY_LOOPING) ;Loop Buffer

	_DrawPoly()
	Return $iIdx
EndFunc   ;==>_PolySampleNoteOn



Func _PolySampleNoteOff(ByRef $aPolySample, $iIdx)
	$aPolySample[$iIdx][0] = 2 ;NoteOff
	_PolySampleAddSamples($aPolySample, $iIdx, 3)
	_DrawPoly()
EndFunc   ;==>_PolySampleNoteOff



Func _PolySampleCreate($oDS, $iPolyPhony, $iBufferLen)
	Local $aPolySample[$iPolyPhony + 1][11] ;0=PlayStatus 1=SampleBuffer 2=BufferLen 3=DSBuffer 4=Notify 5=EnvCurPos 6=EnvEndPos 7=EnvSegLen [8=ADSR_DMO 9=ADSR_OIP 10=ADSR_MP]
	$aPolySample[0][0] = $iPolyPhony
	For $i = 1 To $iPolyPhony
		$aPolySample[$i][0] = False

		$aPolySample[$i][1] = DllStructCreate("byte[" & $iBufferLen & "];")
		$aPolySample[$i][2] = $iBufferLen
		$aPolySample[$i][3] = _DSnd_CreateSoundBuffer($oDS, BitOR($DSBCAPS_GLOBALFOCUS, $DSBCAPS_CTRLPOSITIONNOTIFY, $DSBCAPS_CTRLFREQUENCY, $DSBCAPS_CTRLFX), $iBufferLen * 2, 2, $ciSampleRate, 32, $WAVE_FORMAT_IEEE_FLOAT)
		$aPolySample[$i][4] = _DSnd_NotifyCreate($aPolySample[$i][3])

		$aPolySample[$i][5] = 0
		$aPolySample[$i][7] = _DSnd_Bytes2Seconds($iBufferLen * 1000, 2, $ciSampleRate, 32) * $cMSEC

		$aPolySample[$i][8] = _DMO_CreateInstance($sGUID_DSFX_STANDARD_COMPRESSOR, $sIID_IMediaObject, $tagIMediaObject)
		_DMO_MediaObjectSetInputType($aPolySample[$i][8], 2, $ciSampleRate, 32, $WAVE_FORMAT_IEEE_FLOAT)
		_DMO_MediaObjectSetOutputType($aPolySample[$i][8], 2, $ciSampleRate, 32, $WAVE_FORMAT_IEEE_FLOAT)
		$aPolySample[$i][9] = _DMO_QueryInterface($aPolySample[$i][8], $sIID_IMediaObjectInPlace, $tagIMediaObjectInPlace);Enable ObjectInPlace (direct processing of $tBuffer)
		$aPolySample[$i][10] = _DMO_QueryInterface($aPolySample[$i][9], $sIID_IMediaParams, $tagIMediaParams);Create MediaParams Object
		$aPolySample[$i][10].SetParam(3, 0) ;Set Compressor Threshold to 0dB
		$aPolySample[$i][10].SetParam(4, 1) ;Set Compressor Ratio to 1
	Next
	Return $aPolySample
EndFunc   ;==>_PolySampleCreate




Func _PolySampleDispose(ByRef $aPolySample)
	For $i = 1 To $ciMaxPolyPhony
		If IsObj($aPolySample[$i][3]) Then $aPolySample[$i][3].Stop()
		For $j = UBound($aPolySample, 2) - 1 To 1 Step -1
			$aPolySample[$i][$j] = 0
		Next
	Next
	$aPolySample = Null
EndFunc   ;==>_PolySampleDispose




Func _BaseSample_Create($tBaseOSC)
	Local $iSamples = $ciSampleRate * 2.7 * 0.1

	Local $iRepeat = Ceiling($iSamples / $tBaseOSC.Cnt)
	Local $iRepeatLoop = Ceiling(Log($iRepeat) / Log(2))
	Local $iBufferLen = Ceiling($tBaseOSC.Cnt * 2 ^ $iRepeatLoop) * 2

	Local $tBaseSample = DllStructCreate("float[" & $iBufferLen & "]; uint Cnt; float Freq;")
	$tBaseSample.Cnt = Ceiling($tBaseOSC.Cnt * 2 ^ $iRepeatLoop)
	$tBaseSample.Freq = $tBaseOSC.Freq

	Local $pBaseSample = DllStructGetPtr($tBaseSample)
	_MemMoveMemory($tBaseOSC, $tBaseSample, $tBaseOSC.Cnt * 8)

	Local $iOffset
	For $i = 0 To $iRepeatLoop - 1
		$iOffset = ($tBaseOSC.Cnt * 2 ^ $i) * 8
		_MemMoveMemory($tBaseSample, $pBaseSample + $iOffset, $iOffset)
	Next

	Return $tBaseSample
EndFunc   ;==>_BaseSample_Create




Func _BaseOSC_CalcAlias($iOctave, $iType = 1, $fPhaseShift = 0, $fPulseWidth = 0)
	If $iType = 1 Then Return _BaseOSC_CalcAliasFree($iOctave, $iType, $fPhaseShift, $fPulseWidth)

	Local $fFreq = $cfBaseFreq * 2 ^ $iOctave ;Calc Base Frequency of current Octave
	Local $fLambda = $ciSampleRate / $fFreq ;WaveLength
	Local $iSamples = $fLambda
	While Mod($iSamples, 1)
		$iSamples += $iSamples
		If $iSamples > 100 Then ExitLoop
	WEnd
	$iSamples = Ceiling($iSamples)

	$fPhaseShift *= 2

	Local $fPhaseL = 0;ACos(-1)
	Local $fPhaseR = $fPhaseL + $fPhaseShift
	Local $fPhaseInc

	Local $aLeft[$iSamples]
	Local $aRight[$iSamples]


	Switch $iType
		Case 2 ;Square
			$fPhaseInc = 2 / $ciSampleRate * $fFreq
			If $fPhaseR > 1 Then $fPhaseR -= 2

			For $i = 0 To $iSamples - 1
				If $fPhaseL < 0 Then
					$aLeft[$i] = -1
				Else
					$aLeft[$i] = 1
				EndIf

				If $fPhaseR < 0 Then
					$aRight[$i] = -1
				Else
					$aRight[$i] = 1
				EndIf

				$fPhaseL += $fPhaseInc
				$fPhaseR += $fPhaseInc
				If $fPhaseL > 1 Then $fPhaseL -= 2
				If $fPhaseR > 1 Then $fPhaseR -= 2
			Next

		Case 3 ;SawTooth
			$fPhaseInc = 2 / $ciSampleRate * $fFreq

			If $fPhaseR > 1 Then $fPhaseR -= 2
			For $i = 0 To $iSamples - 1
				$aLeft[$i] = $fPhaseL
				$aRight[$i] = $fPhaseR

				$fPhaseL += $fPhaseInc
				$fPhaseR += $fPhaseInc
				If $fPhaseL > 1 Then $fPhaseL -= 2
				If $fPhaseR > 1 Then $fPhaseR -= 2
			Next

		Case 4 ;Triangle
			$fPhaseInc = 4 / $ciSampleRate * $fFreq
			Local $iML = 0, $iMR = 0

			If $fPhaseR > 1 Then
				$fPhaseR -= 2
				$iMR += 1
			EndIf

			For $i = 0 To $iSamples - 1
				$aLeft[$i] = $fPhaseL
				If Mod($iML, 2) Then $aLeft[$i] = -$aLeft[$i]

				$aRight[$i] = $fPhaseR
				If Mod($iMR, 2) Then $aRight[$i] = -$aRight[$i]

				$fPhaseL += $fPhaseInc
				$fPhaseR += $fPhaseInc
				If $fPhaseL > 1 Then
					$fPhaseL -= 2
					$iML += 1
				EndIf
				If $fPhaseR > 1 Then
					$fPhaseR -= 2
					$iMR += 1
				EndIf
			Next

		Case 5 ;PulseWidth
			Local $fPW = (1 + $fPulseWidth * 0.9)

			Local $fPhaseLS = $fPhaseL + $fPW
			Local $fPhaseRS = $fPhaseR + $fPW

			If $fPhaseL > 1 Then $fPhaseL -= 2
			If $fPhaseR > 1 Then $fPhaseR -= 2
			If $fPhaseLS > 1 Then $fPhaseLS -= 2
			If $fPhaseRS > 1 Then $fPhaseRS -= 2

			Local $aLeftS[$iSamples]
			Local $aRightS[$iSamples]


			$fPhaseInc = 2 / $ciSampleRate * $fFreq

			For $i = 0 To $iSamples - 1
				$aLeft[$i] = $fPhaseL
				$aRight[$i] = $fPhaseR
				$aLeftS[$i] = -$fPhaseLS
				$aRightS[$i] = -$fPhaseRS

				$fPhaseL += $fPhaseInc
				$fPhaseR += $fPhaseInc
				$fPhaseLS += $fPhaseInc
				$fPhaseRS += $fPhaseInc
				If $fPhaseL > 1 Then $fPhaseL -= 2
				If $fPhaseR > 1 Then $fPhaseR -= 2
				If $fPhaseLS > 1 Then $fPhaseLS -= 2
				If $fPhaseRS > 1 Then $fPhaseRS -= 2
			Next

			For $i = 0 To $iSamples - 1
				$aLeft[$i] = $aLeft[$i] * 0.5 + $aLeftS[$i] * 0.5
				$aRight[$i] = $aRight[$i] * 0.5 + $aRightS[$i] * 0.5
			Next

	EndSwitch

	Local $tBaseOSC = DllStructCreate("float Smp[" & $iSamples * 2 & "]; uint Cnt; float Freq;")
	$tBaseOSC.Cnt = $iSamples
	$tBaseOSC.Freq = $fFreq

	Local $fPeak = 0
	For $i = 0 To $iSamples - 1
		If Abs($aLeft[$i]) > $fPeak Then $fPeak = Abs($aLeft[$i])
	Next
	Local $fAmp = 1 / $fPeak

	For $i = 0 To $iSamples - 1
		If Abs($aLeft[$i] * $fAmp) > $fPeak Then $fPeak = Abs($aLeft[$i] * $fAmp)
		DllStructSetData($tBaseOSC, 1, $aLeft[$i] * $fAmp, $i * 2 + 1)
		DllStructSetData($tBaseOSC, 1, $aRight[$i] * $fAmp, $i * 2 + 2)
	Next

	Return $tBaseOSC
EndFunc   ;==>_BaseOSC_CalcAlias



Func _BaseOSC_CalcAliasFree($iOctave, $iType = 1, $fPhaseShift = 0, $fPulseWidth = 0)
	Local $fFreq = $cfBaseFreq * 2 ^ $iOctave ;Calc Base Frequency of current Octave
	Local $fLambda = $ciSampleRate / $fFreq ;WaveLength
	Local $iSamples = $fLambda
	While Mod($iSamples, 1)
		$iSamples += $iSamples
		If $iSamples > 100 Then ExitLoop
	WEnd
	$iSamples = Ceiling($iSamples)

	Local $fPhase = 0;ACos(-1)
	Local $fPhaseInc = (ACos(-1) * 2) / $ciSampleRate * $fFreq

	$fPhaseShift *= ACos(-1) * 2

	;Calc Phase for each Sample and create SineWave
	Local $aPhaseL[$iSamples], $aPhaseR[$iSamples], $aLeft[$iSamples], $aRight[$iSamples]
	For $i = 0 To $iSamples - 1
		$aPhaseL[$i] = $fPhase
		$aPhaseR[$i] = $fPhase + $fPhaseShift
		$fPhase += $fPhaseInc
	Next


	;Add Harmonics
	Local $fZ, $iMaxNyquist = Floor(($ciSampleRate * 0.5) / $fFreq)

	Switch $iType
		Case 1 ;Sine
			For $i = 0 To $iSamples - 1
				$aLeft[$i] = Sin($aPhaseL[$i])
				$aRight[$i] = Sin($aPhaseR[$i])
			Next

		Case 2 ;Square
			For $z = 1 To $iMaxNyquist Step 2
				$fZ = 1 / $z
				For $i = 0 To $iSamples - 1
					$aLeft[$i] += Sin($aPhaseL[$i] * $z) * $fZ
					$aRight[$i] += Sin($aPhaseR[$i] * $z) * $fZ
				Next

			Next

		Case 3 ;SawTooth
			For $z = 1 To $iMaxNyquist
				$fZ = 1 / $z
				Switch Mod($z, 2)
					Case 0
						For $i = 0 To $iSamples - 1
							$aLeft[$i] -= Sin($aPhaseL[$i] * $z) * $fZ
							$aRight[$i] -= Sin($aPhaseR[$i] * $z) * $fZ
						Next
					Case Else
						For $i = 0 To $iSamples - 1
							$aLeft[$i] += Sin($aPhaseL[$i] * $z) * $fZ
							$aRight[$i] += Sin($aPhaseR[$i] * $z) * $fZ
						Next
				EndSwitch

			Next

		Case 4 ;Triangle
			Local $iM = 1
			For $z = 1 To $iMaxNyquist Step 2
				$iM += 1
				$fZ = 1 / ($z ^ 2)
				Switch Mod($iM, 2)
					Case 1
						For $i = 0 To $iSamples - 1
							$aLeft[$i] -= Sin($aPhaseL[$i] * $z) * $fZ
							$aRight[$i] -= Sin($aPhaseR[$i] * $z) * $fZ
						Next
					Case Else
						For $i = 0 To $iSamples - 1
							$aLeft[$i] += Sin($aPhaseL[$i] * $z) * $fZ
							$aRight[$i] += Sin($aPhaseR[$i] * $z) * $fZ
						Next
				EndSwitch

			Next



		Case 5 ;PulseWidth
			Local $fPW = ACos(-1) * (1 + $fPulseWidth * 0.9)
			Local $aPhaseSL[$iSamples]
			Local $aPhaseSR[$iSamples]
			For $i = 0 To $iSamples - 1
				$aPhaseSL[$i] = $aPhaseL[$i] + $fPW
				$aPhaseSR[$i] = $aPhaseR[$i] + $fPW
			Next
			Local $aLeftS[$iSamples]
			Local $aRightS[$iSamples]

			For $z = 1 To $iMaxNyquist
				$fZ = 1 / $z
				Switch Mod($z, 2)
					Case 0
						For $i = 0 To $iSamples - 1
							$aLeft[$i] -= Sin($aPhaseL[$i] * $z) * $fZ
							$aLeftS[$i] += Sin($aPhaseSL[$i] * $z) * $fZ
							$aRight[$i] -= Sin($aPhaseR[$i] * $z) * $fZ
							$aRightS[$i] += Sin($aPhaseSR[$i] * $z) * $fZ
						Next
					Case Else
						For $i = 0 To $iSamples - 1
							$aLeft[$i] += Sin($aPhaseL[$i] * $z) * $fZ
							$aLeftS[$i] -= Sin($aPhaseSL[$i] * $z) * $fZ
							$aRight[$i] += Sin($aPhaseR[$i] * $z) * $fZ
							$aRightS[$i] -= Sin($aPhaseSR[$i] * $z) * $fZ
						Next
				EndSwitch
			Next

			For $i = 0 To $iSamples - 1
				$aLeft[$i] = $aLeft[$i] * 0.5 + $aLeftS[$i] * 0.5
				$aRight[$i] = $aRight[$i] * 0.5 + $aRightS[$i] * 0.5
			Next
	EndSwitch

	Local $tBaseOSC = DllStructCreate("float Smp[" & $iSamples * 2 & "]; uint Cnt; float Freq;")
	$tBaseOSC.Cnt = $iSamples
	$tBaseOSC.Freq = $fFreq

	Local $fPeak = 0
	For $i = 0 To $iSamples - 1
		If Abs($aLeft[$i]) > $fPeak Then $fPeak = Abs($aLeft[$i])
	Next
	Local $fAmp = 1 / $fPeak

	For $i = 0 To $iSamples - 1
		If Abs($aLeft[$i] * $fAmp) > $fPeak Then $fPeak = Abs($aLeft[$i] * $fAmp)
		DllStructSetData($tBaseOSC, 1, $aLeft[$i] * $fAmp, $i * 2 + 1)
		DllStructSetData($tBaseOSC, 1, $aRight[$i] * $fAmp, $i * 2 + 2)
	Next

	ConsoleWrite("! AMP: " & $fAmp & @CRLF)

	Return $tBaseOSC
EndFunc   ;==>_BaseOSC_CalcAliasFree



Func _CreateKeyMatrix($sKeys)
	Local $aSplit = StringSplit($sKeys, "|")
	Local $aKeys[$aSplit[0] + 1][3]
	$aKeys[0][0] = $aSplit[0]

	Local $tKeys = DllStructCreate("byte[256];")
	DllCall("user32.dll", "uint", "GetKeyboardState", "struct*", $tKeys)

	For $i = 1 To $aSplit[0]
		$aKeys[$i][0] = Asc(StringUpper($aSplit[$i])) + 1
		$aKeys[$i][1] = BitAND(DllStructGetData($tKeys, 1, $aKeys[$i][0]), 0x0F)
	Next

	Return $aKeys
EndFunc   ;==>_CreateKeyMatrix


Func _NotifyEventsDispose(ByRef $aNotifyEvents)
	For $i = 1 To $aNotifyEvents[0][0] / 3
		_WinAPI_CloseHandle($aNotifyEvents[$i][0])
		_WinAPI_CloseHandle($aNotifyEvents[$i][1])
		_WinAPI_CloseHandle($aNotifyEvents[$i][2])
	Next
	$aNotifyEvents = Null
EndFunc   ;==>_NotifyEventsDispose



Func _NotifyEventsCreate($iMaxPolyPhony)
	Local $aNotifyEvents[$ciMaxPolyPhony + 1][3]
	$aNotifyEvents[0][1] = DllStructCreate("handle[" & $ciMaxPolyPhony * 3 & "];")
	For $i = 1 To $ciMaxPolyPhony
		$aNotifyEvents[$i][0] = _WinAPI_CreateEvent(0, True, False)
		$aNotifyEvents[$i][1] = _WinAPI_CreateEvent(0, True, False)
		$aNotifyEvents[$i][2] = _WinAPI_CreateEvent(0, True, False)
		DllStructSetData($aNotifyEvents[0][1], 1, $aNotifyEvents[$i][0], ($i - 1) * 3 + 1)
		DllStructSetData($aNotifyEvents[0][1], 1, $aNotifyEvents[$i][1], ($i - 1) * 3 + 2)
		DllStructSetData($aNotifyEvents[0][1], 1, $aNotifyEvents[$i][2], ($i - 1) * 3 + 3)
		$aNotifyEvents[0][0] += 3
	Next
	Return $aNotifyEvents
EndFunc   ;==>_NotifyEventsCreate



Func _DrawPoly()
	_GDIPlus_GraphicsClear($hGfxPoly, 0)
	Local $fX, $fR = 6
	For $i = 1 To $ciMaxPolyPhony
		$fX = ($i - 1) / ($ciMaxPolyPhony - 1) * 300 + 10
		Switch $aPolySample[$i][0]
			Case 1 ;Play
				_GDIPlus_GraphicsFillEllipse($hGfxPoly, $fX - $fR, 12 - $fR, $fR * 2, $fR * 2, $hBrushPoly_Play)
			Case 2 ;Release
				_GDIPlus_GraphicsFillEllipse($hGfxPoly, $fX - $fR, 12 - $fR, $fR * 2, $fR * 2, $hBrushPoly_Release)
			Case Else
				If $i > $aPolySample[0][0] Then
					_GDIPlus_GraphicsFillEllipse($hGfxPoly, $fX - $fR, 12 - $fR, $fR * 2, $fR * 2, $hBrushPoly_Dis)
				Else
					_GDIPlus_GraphicsFillEllipse($hGfxPoly, $fX - $fR, 12 - $fR, $fR * 2, $fR * 2, $hBrushPoly_Stop)
				EndIf
		EndSwitch
		_GDIPlus_GraphicsDrawEllipse($hGfxPoly, $fX - $fR, 12 - $fR, $fR * 2, $fR * 2, $hPenPoly)
	Next

	_GDIPlus_GraphicsSetClipRect($hGfxBuffer, 450, 180, 320, 24)
	_GDIPlus_GraphicsClear($hGfxBuffer, 0)
	_GDIPlus_GraphicsResetClip($hGfxBuffer)

	_GDIPlus_GraphicsDrawImage($hGfxBuffer, $hBmpPoly, 450, 180)
	_GDIPlus_GraphicsDrawImage($hGraphics, $hBmpBuffer, 0, 0)
EndFunc   ;==>_DrawPoly



Func _DrawADSR()
	_GDIPlus_GraphicsClear($hGfxADSR, 0xFF000000)

	Local $aCurve[6][2] = [[5]]
	$aCurve[1][0] = 0
	$aCurve[1][1] = 42
	$aCurve[2][0] = $iAttack / ($ciADRMax * 0.5) * 0.12 * 100
	$aCurve[2][1] = 0
	$aCurve[3][0] = $aCurve[2][0] + ($iDecay / ($ciADRMax * 0.5) * 0.12 * 100)
	$aCurve[3][1] = Abs($iSustain) * 0.9
	$aCurve[4][0] = 0.52 * 100
	$aCurve[4][1] = $aCurve[3][1]
	$aCurve[5][0] = $aCurve[4][0] + $iRelease / ($ciADRMax * 2) * 0.48 * 100
	$aCurve[5][1] = 42

	_GDIPlus_GraphicsDrawCurve2($hGfxADSR, $aCurve, 0, $hPenADSR)

	_GDIPlus_GraphicsDrawImage($hGfxBuffer, $hBmpADSR, 250, 30)
	_GDIPlus_GraphicsDrawImage($hGraphics, $hBmpBuffer, 0, 0)
EndFunc   ;==>_DrawADSR




Func _DrawOSC()
	_GDIPlus_GraphicsClear($hGfxOSC, 0xFF000000)

	Local $iCnt = $tBaseOSC.Cnt * 2
	Local $aCurveL[$iCnt + 1][2] = [[$iCnt]]
	Local $aCurveR[$iCnt + 1][2] = [[$iCnt]]

	For $i = 1 To $iCnt
		$aCurveL[$i][0] = ($i - 1) / ($iCnt - 1) * 64
		$aCurveR[$i][0] = $aCurveL[$i][0]
		$aCurveL[$i][1] = 32 + DllStructGetData($tBaseSample, 1, ($i - 1) * 2 + 1) * 24
		$aCurveR[$i][1] = 32 + DllStructGetData($tBaseSample, 1, ($i - 1) * 2 + 2) * 24
	Next

	_GDIPlus_GraphicsDrawCurve2($hGfxOSC, $aCurveR, 0, $hPenOSC_R)
	_GDIPlus_GraphicsDrawCurve2($hGfxOSC, $aCurveL, 0, $hPenOSC_L)

	_GDIPlus_GraphicsDrawImage($hGfxBuffer, $hBmpOSC, 140, 55)
	_GDIPlus_GraphicsDrawImage($hGraphics, $hBmpBuffer, 0, 0)

	If GUICtrlRead($cCB_View) = 1 Then
		_GDIPlus_GraphicsClear($hGfxBuffer_OSC, 0xFF000000)
		_GDIPlus_GraphicsDrawCurve2($hGfxBuffer_OSC, $aCurveR, 0, $hPenOSC_R)
		_GDIPlus_GraphicsDrawCurve2($hGfxBuffer_OSC, $aCurveL, 0, $hPenOSC_L)
		_GDIPlus_GraphicsDrawImage($hGraphics_OSC, $hBmpBuffer_OSC, 0, 0)
	EndIf
EndFunc   ;==>_DrawOSC




Func _DrawKeyBoard()
	_GDIPlus_GraphicsDrawImage($hGfxBuffer, $aKeyboard[0], 10, 230)
	For $i = 1 To $aKeys[0][0]
		If $aKeys[$i][2] > 0 Then
			If $aPolySample[$aKeys[$i][2]][0] = 1 Then _GDIPlus_GraphicsFillRegion($hGfxBuffer, $aKeyboard[$i], $hBrushKey)
		EndIf
	Next
	_GDIPlus_GraphicsDrawImage($hGraphics, $hBmpBuffer, 0, 0)
EndFunc   ;==>_DrawKeyBoard



Func WM_PAINT($hWnd, $iMsg, $wParam, $lParam)
	#forceref $hWnd, $iMsg, $wParam, $lParam
	Switch $hWnd
		Case $hGui
			_GDIPlus_GraphicsDrawImage($hGraphics, $hBmpBuffer, 0, 0)
		Case $hGui_OSCView
			_GDIPlus_GraphicsDrawImage($hGraphics_OSC, $hBmpBuffer_OSC, 0, 0)
	EndSwitch
	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_PAINT



Func _KeyBoard_Create($iW, $iH, $iXOff, $iYOff)
	Local $aKeyboard[$aKeys[0][0] + 1]
	Local $hRegion

	Local $fX = 0, $fW = ($iW - 4) / ($aKeys[0][0] / 12 * 7)
	For $i = 1 To $aKeys[0][0]
		Switch Mod($i, 12)
			Case 2, 4, 7, 9, 11
				$hRegion = _GDIPlus_RegionCreateFromRect($fX - $fW * 0.3 + 1, 2, $fW * 0.6 - 2, $iH * 0.65)
			Case Else
				$hRegion = _GDIPlus_RegionCreateFromRect($fX + 2, 2, $fW - 4, $iH - 4)
				Switch Mod($i, 12)
					Case 1, 6
						_GDIPlus_RegionCombineRect($hRegion, $fX + $fW * 0.68, 2, $fW, $iH * 0.67, 4)
					Case 5, 0
						_GDIPlus_RegionCombineRect($hRegion, $fX, 2, $fW * 0.32, $iH * 0.67, 4)
					Case Else
						_GDIPlus_RegionCombineRect($hRegion, $fX + $fW * 0.68, 2, $fW, $iH * 0.67, 4)
						_GDIPlus_RegionCombineRect($hRegion, $fX, 2, $fW * 0.32, $iH * 0.67, 4)
				EndSwitch
				$fX += $fW
		EndSwitch
		$aKeyboard[$i] = $hRegion
	Next

	Local $hBitmap = _GDIPlus_BitmapCreateFromScan0($iW, $iH)
	Local $hContext = _GDIPlus_ImageGetGraphicsContext($hBitmap)
	_GDIPlus_GraphicsSetSmoothingMode($hContext, 2)
	_GDIPlus_GraphicsClear($hContext, 0xFF000000)

	Local $hBrush = _GDIPlus_BrushCreateSolid(0xFF555555)
	$hRegion = _GDIPlus_RegionCreate()
	For $i = 1 To $aKeys[0][0]
		Switch Mod($i, 12)
			Case 2, 4, 7, 9, 11
				_GDIPlus_GraphicsFillRegion($hContext, $aKeyboard[$i], $hBrush)
				_GDIPlus_RegionCombineRegion($hRegion, $aKeyboard[$i], 3)
		EndSwitch
	Next
	_GDIPlus_BrushSetSolidColor($hBrush, 0x4FFFFFFF)
	_GDIPlus_GraphicsSetClipRegion($hContext, $hRegion, 3)
	_GDIPlus_GraphicsFillRect($hContext, 0, $iH * 0.62, $iW, 8, $hBrush)
	_GDIPlus_RegionDispose($hRegion)
	_GDIPlus_GraphicsResetClip($hContext)

	_GDIPlus_BrushSetSolidColor($hBrush, 0xFFFFEEFF)
	For $i = 1 To $aKeys[0][0]
		Switch Mod($i, 12)
			Case 2, 4, 7, 9, 11
			Case Else
				_GDIPlus_GraphicsFillRegion($hContext, $aKeyboard[$i], $hBrush)
		EndSwitch
	Next
	_GDIPlus_BrushSetSolidColor($hBrush, 0x4F000000)
	_GDIPlus_GraphicsFillRect($hContext, 0, 0, $iW, 8, $hBrush)


	Local $sChar, $tLayout
	Local $hFormat = _GDIPlus_StringFormatCreate()
	_GDIPlus_StringFormatSetAlign($hFormat, 1)
	_GDIPlus_StringFormatSetLineAlign($hFormat, 1)
	Local $hFamily = _GDIPlus_FontFamilyCreate("Arial")
	Local $hFont = _GDIPlus_FontCreate($hFamily, 11, 2)

	$fX = 0
	For $i = 1 To $aKeys[0][0]
		$sChar = Chr($aKeys[$i][0] - 1)
		Switch Mod($i, 12)
			Case 2, 4, 7, 9, 11
				_GDIPlus_BrushSetSolidColor($hBrush, 0xAFFFFFFF)
				$tLayout = _GDIPlus_RectFCreate($fX - $fW * 0.4, $iH * 0.48, $fW * 0.8, 20)
				_GDIPlus_GraphicsDrawStringEx($hContext, $sChar, $hFont, $tLayout, $hFormat, $hBrush)
			Case Else
				_GDIPlus_BrushSetSolidColor($hBrush, 0xAF000000)
				$tLayout = _GDIPlus_RectFCreate($fX, $iH * 0.8, $fW, 20)
				_GDIPlus_GraphicsDrawStringEx($hContext, $sChar, $hFont, $tLayout, $hFormat, $hBrush)
				$fX += $fW
		EndSwitch
	Next
	_GDIPlus_BrushDispose($hBrush)

	_GDIPlus_GraphicsDispose($hContext)
	$aKeyboard[0] = $hBitmap

	For $i = 1 To $aKeys[0][0]
		_GDIPlus_RegionTranslate($aKeyboard[$i], $iXOff, $iYOff)
	Next

	Return $aKeyboard
EndFunc   ;==>_KeyBoard_Create



Func _Exit()
	_PolySampleDispose($aPolySample)
	_NotifyEventsDispose($aNotifyEvents)
	$oDS = 0

	_GDIPlus_BitmapDispose($aKeyboard[0])
	For $i = 1 To UBound($aKeyboard) - 1
		_GDIPlus_RegionDispose($aKeyboard[$i])
	Next
	_GDIPlus_BrushDispose($hBrushKey)

	_GDIPlus_PenDispose($hPenADSR)
	_GDIPlus_GraphicsDispose($hGfxADSR)
	_GDIPlus_BitmapDispose($hBmpADSR)

	_GDIPlus_PenDispose($hPenOSC_L)
	_GDIPlus_PenDispose($hPenOSC_R)
	_GDIPlus_GraphicsDispose($hGfxOSC)
	_GDIPlus_BitmapDispose($hBmpOSC)

	_GDIPlus_BrushDispose($hBrushPoly_Play)
	_GDIPlus_BrushDispose($hBrushPoly_Stop)
	_GDIPlus_BrushDispose($hBrushPoly_Release)
	_GDIPlus_BrushDispose($hBrushPoly_Dis)
	_GDIPlus_PenDispose($hPenPoly)
	_GDIPlus_GraphicsDispose($hGfxPoly)
	_GDIPlus_BitmapDispose($hBmpPoly)

	_GDIPlus_GraphicsDispose($hGfxBuffer_OSC)
	_GDIPlus_BitmapDispose($hBmpBuffer_OSC)
	_GDIPlus_GraphicsDispose($hGraphics_OSC)

	_GDIPlus_GraphicsDispose($hGfxBuffer)
	_GDIPlus_BitmapDispose($hBmpBuffer)
	_GDIPlus_GraphicsDispose($hGraphics)
	_GDIPlus_Shutdown()

	GUIDelete($hGui)
	Exit
EndFunc   ;==>_Exit
