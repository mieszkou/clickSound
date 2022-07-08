#include <GUIConstantsEx.au3>
#include "MouseOnEvent.au3"

HotKeySet("{ESC}", "_Quit")

_Example_Intro()
_Example_Limit_Window()

Func _Example_Intro()
    MsgBox(64, "Attention!", "Let's set event function for mouse wheel *scrolling* up and down", 5)
    
    ;Set event function for mouse wheel *scrolling* up/down and primary button *down* action (call our function when the events recieved)
    _MouseSetOnEvent($MOUSE_WHEELSCROLLDOWN_EVENT, "_MouseWheel_Events")
    _MouseSetOnEvent($MOUSE_WHEELSCROLLUP_EVENT, "_MouseWheel_Events")
    _MouseSetOnEvent($MOUSE_PRIMARYDOWN_EVENT, "_MousePrimaryDown_Event")
    
    Sleep(3000)
    
    ;UnSet the events
    _MouseSetOnEvent($MOUSE_WHEELSCROLLDOWN_EVENT)
    _MouseSetOnEvent($MOUSE_WHEELSCROLLUP_EVENT)
    _MouseSetOnEvent($MOUSE_PRIMARYDOWN_EVENT)
    
    ToolTip("")
    
    MsgBox(64, "Attention!", "Now let's disable Secondary mouse button up action, and call our event function.", 5)
    
    _MouseSetOnEvent($MOUSE_SECONDARYUP_EVENT, "_MouseSecondaryUp_Event", 0, 1)
    Sleep(5000)
    _MouseSetOnEvent($MOUSE_SECONDARYUP_EVENT)
    
    ToolTip("")
EndFunc

Func _Example_Limit_Window()
    Local $hGUI = GUICreate("MouseOnEvent UDF Example - Restrict events on specific window")
    
    GUICtrlCreateLabel("Try to click on that specific GUI window", 40, 40, 300, 30)
    GUICtrlSetFont(-1, 12, 800)
    GUICtrlCreateLabel("Press <ESC> to exit", 10, 10)
    GUISetState()
    
    _MouseSetOnEvent($MOUSE_PRIMARYDOWN_EVENT, "_MousePrimaryDown_Event", $hGUI)
    ;A little(?) bugie when you mix different events :(
    ;_MouseSetOnEvent($MOUSE_SECONDARYUP_EVENT, "_MouseSecondaryUp_Event", $hGUI)
    
    While 1
        Switch GUIGetMsg()
            Case $GUI_EVENT_CLOSE
                ExitLoop
            Case $GUI_EVENT_PRIMARYDOWN
                MsgBox(0, "", "Should not be shown ;)")
        EndSwitch
    WEnd
    
    _MouseSetOnEvent($MOUSE_PRIMARYDOWN_EVENT)
    ;_MouseSetOnEvent($MOUSE_SECONDARYUP_EVENT)
EndFunc

Func _MouseWheel_Events($iEvent)
    Switch $iEvent
        Case $MOUSE_WHEELSCROLLDOWN_EVENT
            ToolTip("Wheel Mouse Button (scrolling) DOWN Blocked")
        Case $MOUSE_WHEELSCROLLUP_EVENT
            ToolTip("Wheel Mouse Button (scrolling) UP Blocked")
    EndSwitch
    
    Return $MOE_BLOCKDEFPROC ;Block
EndFunc

Func _MousePrimaryDown_Event()
    ToolTip("Primary Mouse Button Down Blocked")
    Return $MOE_BLOCKDEFPROC ;Block
EndFunc

Func _MouseSecondaryUp_Event()
    ToolTip("Secondary Mouse Button Up Blocked")
EndFunc

Func _Quit()
    Exit
EndFunc