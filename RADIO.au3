#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <GuiSlider.au3>
#include <ButtonConstants.au3>
#include <TrayConstants.au3>
#include <InetConstants.au3>

; --- UPDATE SETTINGS ---
Global Const $CURRENT_VERSION = "1.0" 
; Direct link to the raw version.txt file on GitHub:
Global Const $UPDATE_VERSION_URL = "https://raw.githubusercontent.com/pkajan/radio/main/version.txt"
; Direct link to the latest compiled .exe release on GitHub:
Global Const $UPDATE_EXE_URL = "https://github.com/pkajan/radio/releases/latest/download/RADIO.exe"
; -----------------------

Opt("TrayAutoPause", 0)
TraySetToolTip("Radio player...")

TrayCreateItem("Show/Hide UI")
TraySetClick(16)

Global $hGUI
Global $Group_1, $Button_1, $Button_2, $Button_3, $Button_4, $Button_5, $Button_6, $Button_7, $Button_8, $Button_9, $volumeSlider, $Progress, $Stop
Global $volumeValue, $volumeLabel, $volume
Global $lastPlayUrl = ""
Global $reconnectAttempts = 0
Global $maxReconnectAttempts = 5
Global $reconnectDelay = 2000

; Registry constants
Global Const $REGISTRY_KEY = "HKEY_CURRENT_USER\Software\RadioPlayer"
Global Const $VOLUME_VALUE_NAME = "Volume"

; Load volume setting from registry or fall back to default
$volumeValue = _loadVolumeFromRegistry()

Func _loadVolumeFromRegistry()
    Local $savedVolume = RegRead($REGISTRY_KEY, $VOLUME_VALUE_NAME)
    If @error Then
        ; If no value exists, return default volume (10%)
        Return 10
    Else
        ; Ensure the loaded value stays within valid range (0-100)
        If $savedVolume < 0 Then Return 0
        If $savedVolume > 100 Then Return 100
        Return Number($savedVolume)
    EndIf
EndFunc   ;==>_loadVolumeFromRegistry

Func _saveVolumeToRegistry($volume)
    ; Create registry key structure if it doesn't exist
    RegWrite($REGISTRY_KEY, "", "REG_SZ", "Radio Player Settings")
    ; Store current volume level
    RegWrite($REGISTRY_KEY, $VOLUME_VALUE_NAME, "REG_DWORD", $volume)
EndFunc   ;==>_saveVolumeToRegistry

; --- AUTO-UPDATE CHECK & INSTALLATION ---
Func _CheckForUpdates()
    Local $sTempVersionFile = @TempDir & "\version.txt"

    ; Download remote version.txt (flag 1 = overwrite local, 0 = synchronous download)
    Local $iDownload = InetGet($UPDATE_VERSION_URL, $sTempVersionFile, 1, 0)
    If $iDownload Then
        InetClose($iDownload)
        Local $sRemoteVersion = StringStripWS(FileRead($sTempVersionFile), 3)
        FileDelete($sTempVersionFile)

        ; Compare remote version against local constant
        If $sRemoteVersion <> "" And $sRemoteVersion > $CURRENT_VERSION Then
            Local $iMsg = MsgBox(64 + 4, "Update Available", "A new version (" & $sRemoteVersion & ") is available. Would you like to update now?")
            If $iMsg = 6 Then ; 6 = Yes
                Local $sNewExePath = @TempDir & "\RADIO_v2_new.exe"
                SplashTextOn("Updating", "Downloading latest version...", 300, 60, -1, -1, 16, "", 10)

                Local $iDownloadExe = InetGet($UPDATE_EXE_URL, $sNewExePath, 1, 0)
                If $iDownloadExe Then
                    InetClose($iDownloadExe)
                    SplashOff()

                    ; Create a batch script to replace the executable after process termination
                    Local $sBatchPath = @TempDir & "\update.bat"
                    Local $sBatContent = '@echo off' & @CRLF & _
                            'timeout /t 2 /nobreak > nul' & @CRLF & _
                            'move /y "' & $sNewExePath & '" "' & @ScriptFullPath & '"' & @CRLF & _
                            'start "" "' & @ScriptFullPath & '"' & @CRLF & _
                            'del "%~f0"'
                    FileWrite($sBatchPath, $sBatContent)

                    ; Execute updater script silently and close current application instance
                    Run($sBatchPath, "", @SW_HIDE)
                    _onExitMain()
                Else
                    SplashOff()
                    MsgBox(16, "Error", "Failed to download update file.")
                EndIf
            EndIf
        EndIf
    EndIf
EndFunc   ;==>_CheckForUpdates

Func _guiCreate()
    $hGUI = GUICreate("Online Radio Player", 325, 200, -1, -1)

    GUISetOnEvent($GUI_EVENT_CLOSE, "_onExitMain")
    $Group_1 = GUICtrlCreateGroup("", 5, 70, 315, 125)
    $Button_1 = GUICtrlCreateButton("EXPRES", 15, 85, 95, 30)
    $Button_2 = GUICtrlCreateButton("VLNA", 115, 85, 95, 30)
    $Button_3 = GUICtrlCreateButton("FUN", 215, 85, 95, 30)
    $Button_4 = GUICtrlCreateButton("MELODY", 15, 120, 95, 30)
    $Button_5 = GUICtrlCreateButton("SLOVENSKO", 115, 120, 95, 30)
    $Button_6 = GUICtrlCreateButton("REGINA", 215, 120, 95, 30)

    $Button_7 = GUICtrlCreateButton("ROCK", 15, 155, 95, 30)
    $Button_8 = GUICtrlCreateButton("EUROPA 2", 115, 155, 95, 30)
    $Button_9 = GUICtrlCreateButton("FUN MILEN", 215, 155, 95, 30)

    $volumeSlider = GUICtrlCreateSlider(15, 20, 245, 40)
    $Progress = GUICtrlCreateProgress(15, 55, 245, 15)
    $Stop = GUICtrlCreateButton("⏹️", 270, 10, 50, 55, BitOR($BS_CENTER, $BS_VCENTER))

    $volumeLabel = GUICtrlCreateLabel("Volume: " & $volumeValue & "%", 10, 5, 70, 15)
    GUICtrlSetColor($volumeLabel, 0xFFFFFF)
EndFunc   ;==>_guiCreate

Func _guiStyle()
    GUISetBkColor(0x000000)
    GUICtrlSetBkColor($volumeSlider, 0x000000)
    GUICtrlSetFont($Button_1, 10, 0)
    GUICtrlSetFont($Button_2, 10, 0)
    GUICtrlSetFont($Button_3, 10, 0)
    GUICtrlSetFont($Button_4, 10, 0)
    GUICtrlSetFont($Button_5, 10, 0)
    GUICtrlSetFont($Button_6, 10, 0)
    GUICtrlSetFont($Button_7, 10, 0)
    GUICtrlSetFont($Button_8, 10, 0)
    GUICtrlSetFont($Button_9, 10, 0)
    GUICtrlSetFont($Stop, 30, 900, $GUI_FONTNORMAL, "Arial")
    GUICtrlSetState($Stop, $GUI_SHOW)
EndFunc   ;==>_guiStyle

Func buttonsStyler($button)
    _guiStyle()
    GUICtrlSetFont($button, 11, 800)
EndFunc   ;==>buttonsStyler

Func buttonsHider($button)
    _guiStyle()
    GUICtrlSetState($button, $GUI_HIDE)
EndFunc   ;==>buttonsHider

Func _trayThings()
    TraySetToolTip("Radio player...")
EndFunc   ;==>_trayThings

Func ToggleControlVisibility()
    $hGUI = Not $hGUI
    If $hGUI Then
        GUISetState(@SW_SHOW, $hGUI)
    Else
        GUISetState(@SW_HIDE, $hGUI)
    EndIf
EndFunc   ;==>ToggleControlVisibility

Func _hasInternetConnection()
    Local $ping = Ping("8.8.8.8", 2000)
    Return $ping > 0
EndFunc   ;==>_hasInternetConnection

Func _playStation($url)
    $WMP.URL = $url
    $WMP.controls.play()
    GUICtrlSetState($Stop, $GUI_SHOW)
EndFunc   ;==>_playStation

Func _main()
    ; Check for online updates immediately at startup
    If _hasInternetConnection() Then
        _CheckForUpdates()
    EndIf

    _guiCreate()
    _guiStyle()
    _trayThings()

    ; Initialize Windows Media Player COM Object
    Global $WMP = ObjCreate("WMPlayer.OCX")
    $WMP.settings.volume = $volumeValue
    GUISetState(@SW_SHOWNORMAL)
    GUICtrlSetState($Stop, $GUI_HIDE)

    Local $hTimer = TimerInit()
    Local $hTimer2 = TimerInit()
    Local $playing = False
    Local $stopped = False
    Local $volume = $volumeValue
    Local $prevVolume = -1

    GUICtrlSetData($volumeSlider, $volumeValue)

    While 1
        If TrayGetMsg() = $TRAY_EVENT_PRIMARYUP Then
            ToggleControlVisibility()
        EndIf

        $fDiff = TimerDiff($hTimer)
        $fDiff2 = TimerDiff($hTimer2)

        Switch GUIGetMsg()
            Case $GUI_EVENT_CLOSE
                _onExitMain()

            Case $GUI_EVENT_MINIMIZE
                ToggleControlVisibility()

            Case $Button_1
                $lastPlayUrl = "https://stream.bauermedia.sk/expres-hi.mp3"
                _playStation($lastPlayUrl)
                $playing = True
                $stopped = False
                buttonsStyler($Button_1)

            Case $Button_2
                $lastPlayUrl = "https://stream.radiovlna.sk/vlna-hi.mp3"
                _playStation($lastPlayUrl)
                $playing = True
                $stopped = False
                buttonsStyler($Button_2)

            Case $Button_3
                $lastPlayUrl = "https://stream.funradio.sk/fun128.mp3"
                _playStation($lastPlayUrl)
                $playing = True
                $stopped = False
                buttonsStyler($Button_3)

            Case $Button_4
                $lastPlayUrl = "https://stream.bauermedia.sk/melody-hi.mp3"
                _playStation($lastPlayUrl)
                $playing = True
                $stopped = False
                buttonsStyler($Button_4)

            Case $Button_5
                $lastPlayUrl = "https://icecast.stv.livebox.sk/slovensko_128.mp3"
                _playStation($lastPlayUrl)
                $playing = True
                $stopped = False
                buttonsStyler($Button_5)

            Case $Button_6
                $lastPlayUrl = "https://icecast.stv.livebox.sk/regina-ba_128.mp3"
                _playStation($lastPlayUrl)
                $playing = True
                $stopped = False
                buttonsStyler($Button_6)

            Case $Button_7
                $lastPlayUrl = "https://stream.bauermedia.sk/rock-hi.mp3"
                _playStation($lastPlayUrl)
                $playing = True
                $stopped = False
                buttonsStyler($Button_7)

            Case $Button_8
                $lastPlayUrl = "https://stream.bauermedia.sk/europa2-hi.mp3"
                _playStation($lastPlayUrl)
                $playing = True
                $stopped = False
                buttonsStyler($Button_8)

            Case $Button_9
                $lastPlayUrl = "https://stream.bauermedia.sk/europa2-hi.mp3"
                _playStation($lastPlayUrl)
                $playing = True
                $stopped = False
                buttonsStyler($Button_9)

            Case $Stop
                $playing = False
                $WMP.controls.stop()
                $stopped = True
                $lastPlayUrl = ""
                buttonsHider($Stop)

            Case $volumeSlider
                $volume = GUICtrlRead($volumeSlider)
                $WMP.settings.volume = $volume
                _saveVolumeToRegistry($volume)
        EndSwitch

        ; Handle volume updates via slider
        $volume = GUICtrlRead($volumeSlider)
        If $volume <> $prevVolume Then
            $WMP.settings.volume = $volume
            GUICtrlSetData($volumeLabel, "Volume: " & $volume & "%")
            _saveVolumeToRegistry($volume)
            $prevVolume = $volume
        EndIf

        ; Reconnection logic loop
        If ($fDiff >= 1005) And Not $stopped Then
            If $WMP.playState <> 3 And $lastPlayUrl <> "" Then
                If _hasInternetConnection() Then
                    If $reconnectAttempts < $maxReconnectAttempts Then
                        ConsoleWrite("Attempting reconnection #" & $reconnectAttempts + 1 & @CRLF)
                        _playStation($lastPlayUrl)
                        $reconnectAttempts += 1
                        Sleep($reconnectDelay)
                    EndIf
                Else
                    $reconnectAttempts = 0
                    GUICtrlSetData($Progress, 0)
                EndIf
            ElseIf $WMP.playState = 3 Then
                $reconnectAttempts = 0
            EndIf
            $hTimer = TimerInit()
        EndIf

        ; Visual playback indicator (fake spectrum effect)
        If $fDiff2 >= 15 And Not $stopped Then
            If $WMP.playState = 3 Then
                GUICtrlSetData($Progress, Random(40, 90))
            Else
                GUICtrlSetData($Progress, 0)
            EndIf
            $hTimer2 = TimerInit()
        EndIf
    WEnd
EndFunc   ;==>_main

Func _onExitMain()
    ; Save volume setting before exiting
    _saveVolumeToRegistry(GUICtrlRead($volumeSlider))
    GUIDelete()
    Exit
EndFunc   ;==>_onExitMain

_main()