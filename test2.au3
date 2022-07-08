#include <Misc.au3>
 
$dll = DllOpen("user32.dll")
 
While 1
    Sleep(250)
    For $iX = 1 To 254
        If _IsPressed(Hex($iX), $dll) Then
            MsgBox($MB_SYSTEMMODAL, "", "0x" & Hex($iX, 2) & @LF)
        EndIf
    Next
WEnd
DllClose($dll)