#include <GUIConstantsEx.au3>
#include <GuiButton.au3>
#include <WindowsConstants.au3>
#include <StructureConstants.au3>
#include <GuiEdit.au3>
#include <WinAPI.au3>

#RequireAdmin

Global $iMemo
;Global $WM_TOUCH = 0x240
Local $hGUI

Global Const $tagTOUCHINPUT = "LONG x; LONG y; HANDLE hSource; DWORD dwID; DWORD dwFlags; DWORD dwMask; DWORD dwTime; ULONG_PTR dwExtraInfo; DWORD cxContact; DWORD cyContact"

_Main()

Func _Main()

    $hGUI = GUICreate("WM_TOUCH", 1080, 640)

    $iMemo = GUICtrlCreateEdit("", 10, 10, 300, 600, $WS_VSCROLL)
    _GUICtrlEdit_SetLimitText($iMemo, 0x80000000)
    GUICtrlSetFont($iMemo, 9, 400, 0, "Courier New")

    DllCall("User32.dll", "BOOL", "RegisterTouchWindow", "HWND", $hGUI, "ULONG", 2)

    GUIRegisterMsg($WM_TOUCH, "WM_TOUCH")

    GUISetState()

    While 1
        Switch GUIGetMsg()
            Case $GUI_EVENT_CLOSE
                ExitLoop
        EndSwitch
    WEnd

    Exit

EndFunc   ;==>_Main

Func WM_TOUCH($hWnd, $Msg, $wParam, $lParam)

    Dim $arrayTouchInput[Int($wParam)]
    $Buffer = DllStructCreate("BYTE buffer[" & (Int($wParam)*40) & "]")
    ;GUICtrlSetData($iMemo, "BYTE buffer[" & (Int($wParam)*40) & "]" & @CRLF, 1)

    $TouchInfo = DllStructCreate($tagTOUCHINPUT, DllStructGetPtr($Buffer))
    $pTouchInfo = DllStructGetPtr($TouchInfo)

    For $i = 0 To (Int($wParam)-1) Step 1
        $arrayTouchInput[$i] = DllStructCreate($tagTOUCHINPUT, ($pTouchInfo+($i*40)))
    Next

    $aRet0 = DllCall("User32.dll", "BOOL", "GetTouchInputInfo", "HANDLE", $lParam, "UINT", $wParam, "ULONG_PTR", $pTouchInfo, "int", DllStructGetSize($TouchInfo))
    ;GUICtrlSetData($iMemo, "@error: " & @error & @CRLF, 1)
    ;GUICtrlSetData($iMemo, "_WinAPI_GetLastError(): " & _WinAPI_GetLastError() & @CRLF, 1)
    ;GUICtrlSetData($iMemo, "Func0 Ret: " & $aRet0[0] & @CRLF, 1)

    GUICtrlSetData($iMemo, "************************************" & @CRLF, 1)
    GUICtrlSetData($iMemo, "Finger Numbers: " & Int($wParam) & @CRLF, 1)
    For $j = 0 To (Int($wParam)-1) Step 1
        GUICtrlSetData($iMemo, "Points " & $j & " dwID: " & DllStructGetData($arrayTouchInput[$j], "dwID") & " ", 1)
        GUICtrlSetData($iMemo, " x: " & DllStructGetData($arrayTouchInput[$j], "x")/100 & " ", 1)
        GUICtrlSetData($iMemo, " y: " & DllStructGetData($arrayTouchInput[$j], "y")/100 & @CRLF, 1)
    Next

    ;GUICtrlSetData($iMemo, "TouchInfo Size: " & DllStructGetSize($TouchInfo) & @CRLF, 1)
    ;$aRet1 = DllCall("User32.dll", "BOOL", "CloseTouchInputHandle", "HANDLE", $lParam)
    ;GUICtrlSetData($iMemo, "Func1 Ret: " & $aRet1[0] & @CRLF, 1)
    ;$TouchInfo = 0
    Return $GUI_RUNDEFMSG
 EndFunc   ;==>WM_NOTIFY