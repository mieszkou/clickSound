#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6
;#AutoIt3Wrapper_UseX64 = y
#include "..\DirectSound.au3"

; -------------------------------------------------------------------------------------------
; | Generate and play a 600Hz SineWave
; -------------------------------------------------------------------------------------------

Global $fSineFreq = 600 ;Frequency of SineWave
Global $iSampleRate = 44100 ;Samples per Second

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

_DSnd_BufferPlay($oDS_Buffer) ;Loop Buffer

MsgBox(0, "", "click OK to stop")
$oDS_Buffer.Stop()

$oDS_Buffer = 0
$oDS = 0