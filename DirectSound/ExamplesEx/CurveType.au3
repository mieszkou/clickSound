#include <GDIPlus.au3>

Global $iSize = 600

_GDIPlus_Startup()
Global $hGui = GUICreate("CurveType", $iSize, $iSize)
Global $hGraphics = _GDIPlus_GraphicsCreateFromHWND($hGui)
Global $hBmp_Buffer = _GDIPlus_BitmapCreateFromScan0($iSize, $iSize)
Global $hGfx_Buffer = _GDIPlus_ImageGetGraphicsContext($hBmp_Buffer)
_GDIPlus_GraphicsSetSmoothingMode($hGfx_Buffer, 2)
_GDIPlus_GraphicsClear($hGfx_Buffer, 0xFFFFFFFF)
Global $hPen = _GDIPlus_PenCreate(0xFF000000, 2)
Global $hBrush = _GDIPlus_BrushCreateSolid(0xFF624200)
Global $hFormat = _GDIPlus_StringFormatCreate()
Global $hFamily = _GDIPlus_FontFamilyCreate("Arial")
Global $hFont = _GDIPlus_FontCreate($hFamily, 12, 1)
GUISetState()

_GDIPlus_GraphicsDrawLine($hGfx_Buffer, 20, 0, 20, $iSize, $hPen)
_GDIPlus_GraphicsDrawLine($hGfx_Buffer, 0, $iSize - 20, $iSize, $iSize - 20, $hPen)

Global $tLayout = _GDIPlus_RectFCreate(40, 10, $iSize, $iSize)
_GDIPlus_GraphicsDrawStringEx($hGfx_Buffer, "IMediaParams Envelope CurveTypes", $hFont, $tLayout, $hFormat, $hBrush)

Global $iPoints = 100
Global $aCurve_Linear[$iPoints + 1][2] = [[$iPoints]]
Global $aCurve_Square[$iPoints + 1][2] = [[$iPoints]]
Global $aCurve_InvSquare[$iPoints + 1][2] = [[$iPoints]]
Global $aCurve_Sine[$iPoints + 1][2] = [[$iPoints]]

Global $fX, $fY, $fPI = ACos(-1)
For $x = 0 To $iPoints - 1
	$fX = $x / ($iPoints - 1)

	;$MP_CURVE_LINEAR
	$fY = $fX
	$aCurve_Linear[$x + 1][0] = 20 + $fX * ($iSize * 0.9)
	$aCurve_Linear[$x + 1][1] = ($iSize - 20) - $fY * ($iSize * 0.9)

	;$MP_CURVE_SQUARE
	$fY = $fX ^ 2
	$aCurve_Square[$x + 1][0] = 20 + $fX * ($iSize * 0.9)
	$aCurve_Square[$x + 1][1] = ($iSize - 20) - $fY * ($iSize * 0.9)

	;$MP_CURVE_INVSQUARE
	$fY = Sqrt($fX)
	$aCurve_InvSquare[$x + 1][0] = 20 + $fX * ($iSize * 0.9)
	$aCurve_InvSquare[$x + 1][1] = ($iSize - 20) - $fY * ($iSize * 0.9)

	;$MP_CURVE_SINE
	$fY = (Sin($fX * $fPI - ($fPI / 2)) + 1) / 2
	$aCurve_Sine[$x + 1][0] = 20 + $fX * ($iSize * 0.9)
	$aCurve_Sine[$x + 1][1] = ($iSize - 20) - $fY * ($iSize * 0.9)
Next


Global $iIdx = Floor($iPoints * 0.34)

_GDIPlus_PenSetColor($hPen, 0xFFAA0000)
_GDIPlus_BrushSetSolidColor($hBrush, 0xFFAA0000)
_GDIPlus_GraphicsDrawCurve2($hGfx_Buffer, $aCurve_Linear, 0.5, $hPen)
$tLayout = _GDIPlus_RectFCreate($aCurve_Linear[$iIdx][0], $aCurve_Linear[$iIdx][1], 100, 100)
_GDIPlus_GraphicsDrawStringEx($hGfx_Buffer, "Linear", $hFont, $tLayout, $hFormat, $hBrush)
For $i = 0 To 10
	$fX = $aCurve_Linear[Int($i / 10 * ($iPoints - 1) + 1)][0]
	$fY = $aCurve_Linear[Int($i / 10 * ($iPoints - 1) + 1)][1]
	_GDIPlus_GraphicsDrawEllipse($hGfx_Buffer, $fX - 2, $fY - 2, 4, 4, $hPen)
Next


_GDIPlus_PenSetColor($hPen, 0xFFAA00AA)
_GDIPlus_BrushSetSolidColor($hBrush, 0xFFAA00AA)
_GDIPlus_GraphicsDrawCurve2($hGfx_Buffer, $aCurve_Square, 0.5, $hPen)
$tLayout = _GDIPlus_RectFCreate($aCurve_Square[$iIdx][0], $aCurve_Square[$iIdx][1], 100, 100)
_GDIPlus_GraphicsDrawStringEx($hGfx_Buffer, "Square", $hFont, $tLayout, $hFormat, $hBrush)
For $i = 0 To 10
	$fX = $aCurve_Square[Int($i / 10 * ($iPoints - 1) + 1)][0]
	$fY = $aCurve_Square[Int($i / 10 * ($iPoints - 1) + 1)][1]
	_GDIPlus_GraphicsDrawEllipse($hGfx_Buffer, $fX - 2, $fY - 2, 4, 4, $hPen)
Next


_GDIPlus_PenSetColor($hPen, 0xFF0000AA)
_GDIPlus_BrushSetSolidColor($hBrush, 0xFF0000AA)
_GDIPlus_GraphicsDrawCurve2($hGfx_Buffer, $aCurve_InvSquare, 0.5, $hPen)
$tLayout = _GDIPlus_RectFCreate($aCurve_InvSquare[$iIdx][0], $aCurve_InvSquare[$iIdx][1], 100, 100)
_GDIPlus_GraphicsDrawStringEx($hGfx_Buffer, "InvSquare", $hFont, $tLayout, $hFormat, $hBrush)
For $i = 0 To 10
	$fX = $aCurve_InvSquare[Int($i / 10 * ($iPoints - 1) + 1)][0]
	$fY = $aCurve_InvSquare[Int($i / 10 * ($iPoints - 1) + 1)][1]
	_GDIPlus_GraphicsDrawEllipse($hGfx_Buffer, $fX - 2, $fY - 2, 4, 4, $hPen)
Next


_GDIPlus_PenSetColor($hPen, 0xFF008800)
_GDIPlus_BrushSetSolidColor($hBrush, 0xFF008800)
_GDIPlus_GraphicsDrawCurve2($hGfx_Buffer, $aCurve_Sine, 0.5, $hPen)
$tLayout = _GDIPlus_RectFCreate($aCurve_Sine[$iIdx][0], $aCurve_Sine[$iIdx][1], 100, 100)
_GDIPlus_GraphicsDrawStringEx($hGfx_Buffer, "Sine", $hFont, $tLayout, $hFormat, $hBrush)
For $i = 0 To 10
	$fX = $aCurve_Sine[Int($i / 10 * ($iPoints - 1) + 1)][0]
	$fY = $aCurve_Sine[Int($i / 10 * ($iPoints - 1) + 1)][1]
	_GDIPlus_GraphicsDrawEllipse($hGfx_Buffer, $fX - 2, $fY - 2, 4, 4, $hPen)
Next


_GDIPlus_GraphicsDrawImage($hGraphics, $hBmp_Buffer, 0, 0)


While GUIGetMsg() <> -3
WEnd


_GDIPlus_FontDispose($hFont)
_GDIPlus_FontFamilyDispose($hFamily)
_GDIPlus_StringFormatDispose($hFormat)
_GDIPlus_BrushDispose($hBrush)

_GDIPlus_PenDispose($hPen)

_GDIPlus_GraphicsDispose($hGfx_Buffer)
_GDIPlus_BitmapDispose($hBmp_Buffer)
_GDIPlus_GraphicsDispose($hGraphics)
_GDIPlus_Shutdown()
GUIDelete($hGui)
