#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6
;#AutoIt3Wrapper_UseX64=y
#include "..\DirectSound.au3"

Global $hGui = GUICreate("DirectSound", 400, 180)
GUICtrlCreateLabel("Channels", 20, 20, 100, 20)
Global $cCB_Channels = GUICtrlCreateCombo("", 20, 40, 100, 20)
GUICtrlSetData(-1, "1|2", "2")
GUICtrlCreateLabel("SampleRate", 150, 20, 100, 20)
Global $cCB_SampleRate = GUICtrlCreateCombo("", 150, 40, 100, 20)
GUICtrlSetData(-1, "8000|11025|16000|22050|24000|32000|44100|48000", "44100")
GUICtrlCreateLabel("BitsPerSample", 280, 20, 100, 20)
Global $cCB_BitsPerSample = GUICtrlCreateCombo("", 280, 40, 100, 20)
GUICtrlSetData(-1, "8|16|24|32", "16")

GUICtrlCreateLabel("Length in Milliseconds", 10, 80, 130, 20, BitOR(0x0200, 0x0002))
Global $cIP_Seconds = GUICtrlCreateInput("1000", 150, 80, 170, 20)
Global $cBT_Seconds = GUICtrlCreateButton("Calc", 330, 80, 50, 20)

GUICtrlCreateLabel("Length in HH:MM:SS.MS", 10, 110, 130, 20, BitOR(0x0200, 0x0002))
Global $cIP_Time = GUICtrlCreateInput("", 150, 110, 170, 20)
Global $cBT_Time = GUICtrlCreateButton("Calc", 330, 110, 50, 20)

GUICtrlCreateLabel("Length in Bytes", 10, 140, 130, 20, BitOR(0x0200, 0x0002))
Global $cIP_Bytes = GUICtrlCreateInput("", 150, 140, 170, 20)
Global $cBT_Bytes = GUICtrlCreateButton("Calc", 330, 140, 50, 20)
GUISetState()


Global $iMsg
While 1
	$iMsg = GUIGetMsg()
	Switch $iMsg
		Case -3
			Exit
		Case $cBT_Seconds
			GUICtrlSetData($cIP_Time, _DSnd_Seconds2Time(GUICtrlRead($cIP_Seconds) / 1000))
			GUICtrlSetData($cIP_Bytes, _DSnd_Seconds2Bytes(GUICtrlRead($cIP_Seconds) / 1000, GUICtrlRead($cCB_Channels), GUICtrlRead($cCB_SampleRate), GUICtrlRead($cCB_BitsPerSample)))
		Case $cBT_Time
			GUICtrlSetData($cIP_Seconds, _DSnd_Time2Seconds(GUICtrlRead($cIP_Time)) * 1000)
			GUICtrlSetData($cIP_Bytes, _DSnd_Seconds2Bytes(_DSnd_Time2Seconds(GUICtrlRead($cIP_Time)), GUICtrlRead($cCB_Channels), GUICtrlRead($cCB_SampleRate), GUICtrlRead($cCB_BitsPerSample)))
		Case $cBT_Bytes
			GUICtrlSetData($cIP_Seconds, _DSnd_Bytes2Seconds(GUICtrlRead($cIP_Bytes), GUICtrlRead($cCB_Channels), GUICtrlRead($cCB_SampleRate), GUICtrlRead($cCB_BitsPerSample)) * 1000)
			GUICtrlSetData($cIP_Time, _DSnd_Seconds2Time(_DSnd_Bytes2Seconds(GUICtrlRead($cIP_Bytes), GUICtrlRead($cCB_Channels), GUICtrlRead($cCB_SampleRate), GUICtrlRead($cCB_BitsPerSample))))
	EndSwitch
WEnd
