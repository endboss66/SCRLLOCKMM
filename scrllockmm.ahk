;  SCRLLOCKMM / SCRLLOCKMICMUTE

#noenv
#singleinstance force
sendmode input
setworkingdir %A_ScriptDir%

;@Ahk2Exe-ExeName SCRLLOCKMM
;@Ahk2Exe-SetName SCRLLOCKMM
;@Ahk2Exe-SetProductName SCRLLOCKMM
;@Ahk2Exe-SetDescription SCRLLOCKMICMUTE
;@Ahk2Exe-SetMainIcon ico\icon.ico
;@Ahk2Exe-SetLanguage 0x0809
;@Ahk2Exe-SetFileversion 1.0
;@Ahk2Exe-SetProductversion 1.0

menu, tray, icon, ico\red.ico

filedelete, restart.bat

parameternames:=[]
parametervalues:=[]
global tempdisable:=0
startadmin:=0
devicetomute:="Microphone"
global devicetomutecl:=""
beep:=0
global amountofdevices:=0
global mutefreq:=360
global unmutefreq:=240
global firstrun:=1
sl:=getkeystate("scrolllock", "T")

menu, tray, tip, SCRLLOCKMICMUTE
menu, tray, nostandard
menu, tray, add, SCRLLOCKMM
menu, tray, disable, SCRLLOCKMM
menu, tray, default, SCRLLOCKMM
menu, tray, click, 1
menu, configurations, add, wizard
menu, configurations, add, manualedit
menu, configurations, add, controlpanel
menu, configurations, add, help
menu, tray, add, settings, :configurations
menu, tray, add, close

gui, helppanel: New, -DPIScale -Maximizebox -Minimizebox, SCRLLOCKMM - help
gui, helppanel: add, text, x5 y5, The concept of this piece of software is simple: 
gui, helppanel: add, text, x5 y25, You can toggle your microphone mute state by pressing SCRLLOCK. In other words:
gui, helppanel: add, text, x5 y45, SCRLLOCK=ON will mean that your microphone of choice is muted`, and
gui, helppanel: add, text, x5 y65, SCRLLOCK=OFF will mean that your microphone of choice is unmuted.
gui, helppanel: add, text, x5 y95, The configuration wizard should guide you through selecting the microphone to be muted, among some other options.
gui, helppanel: add, text, x5 y115, This configuration wizard launches automatically on the first run, after closing this window.
gui, helppanel: add, text, x5 y135, You can also find it later by right-clicking the task tray `<S`> icon.
gui, helppanel: add, text, x5 y165, Tip: ALT+SCRLLOCK will open the recording tab of the control panel.
gui, helppanel: add, text, x5 y195, This software uses two utilities by NirSoft (www.nirsoft.net): GetNir and SoundVolumeView.
gui, helppanel: add, text, x5 y215, Files of these utilities are fully included in the SCRLLOCKMM package without any modifications.

if fileexist("scrllockmm.ini") {
	firstrun:=0
	fileread, slmmini, scrllockmm.ini
	loop, parse, slmmini, `n, `r 
	{
		if (substr(A_LoopField, 1, 1)!="/") {
			parameterdefinition := strsplit(A_LoopField, "=")
			parameternames[A_Index] := parameterdefinition[1]
			parametervalues[A_Index] := trim(trim(parameterdefinition[2]),"""")
			if (parameternames[A_Index]="startadmin" && parametervalues[A_Index]="1") {
				full_cl := DllCall("GetCommandLine", "str")
				if not (A_IsAdmin or RegExMatch(full_cl, " /restart(?!\S)")) {
					try {
						if A_IsCompiled
							Run *RunAs "%A_ScriptFullPath%" /restart
						else
							Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%"
					}
					ExitApp
				}
			}
		}
	}
}

flash(1,100,100,200,200,400)

for k in parameternames {
	if (parameternames[k]="devicetomute") 
		devicetomute:=parametervalues[k]
	else if (parameternames[k]="startadmin")
		startadmin:=parametervalues[k]
	else if (parameternames[k]="beep")
		beep:=parametervalues[k]
	else if (parameternames[k]="mutefreq")
		mutefreq:=parametervalues[k]
	else if (parameternames[k]="unmutefreq")
		unmutefreq:=parametervalues[k]
}

if (devicetomute="default")
	devicetomutecl:="DefaultCaptureDevice"
else if (devicetomute="defaultcomm")
	devicetomutecl:="DefaultCaptureDeviceComm"
else if (devicetomute="defaultmulti")
	devicetomutecl:="DefaultCaptureDeviceMulti"
else
	devicetomutecl:=% devicetomute

if (firstrun="1") {
	gosub help
}

if (sl) {
	run, soundvolumeview\soundvolumeview /Mute "%devicetomutecl%", , hide
	if (beep="1")
		beep1()
	menu, tray, icon, ico\on.ico
}
else {
	run, soundvolumeview\soundvolumeview /Unmute "%devicetomutecl%", , hide
	if (beep="1")
		beep0()
	menu, tray, icon, ico\off.ico
}

return

close:
	tempdisable := 1
	menu, tray, icon, ico\red.ico
	sleep 1000
	exitapp
	return

manualedit:
	tempdisable := 1
	menu, tray, icon, ico\red.ico
	run, notepad scrllockmm.ini
	winwait, scrllockmm.ini - Notepad
	winwaitclose
	fileappend, timeout /t 2 /nobreak >nul, restart.bat
	filesetattrib, +H, restart.bat
	process, exist, SCRLLOCKMM.exe
	if (!Errorlevel=0)
		fileappend, `nstart SCRLLOCKMM.exe, restart.bat
	else
		fileappend, `nstart scrllockmm.ahk, restart.bat
	fileappend, `nexit, restart.bat
	run, restart.bat, , hide
	exitapp
	return

controlpanel:
	run %comspec% /c "control.exe mmsys.cpl`,`,1", , hide
	return

wizard:
	fullconfig()
	return

help:
	gui, helppanel: show, w640 h240
	return

helppanelguiclose:
	gui, helppanel: hide
	if (firstrun="1")
		fullconfig()
	return

*scrolllock::
SCRLLOCKMM:
	if(getkeystate("alt")) {
		gosub controlpanel
	}
	else {
		if (tempdisable=0) {
			tempdisable := 1
			if (sl)
			{
				menu, tray, icon, ico\red.ico
				runwait, soundvolumeview\soundvolumeview /Unmute "%devicetomutecl%", , hide
				if (beep="1") {
					beep0()
				}
				setscrolllockstate, off
				menu, tray, icon, ico\off.ico
				sl := false
			}
			else
			{
				menu, tray, icon, ico\red.ico
				runwait, soundvolumeview\soundvolumeview /Mute "%devicetomutecl%", , hide
				if (beep="1") {
					beep1()
				}
				setscrolllockstate, on
				menu, tray, icon, ico\on.ico
				sl := true
			}
			tempdisable := 0
		}
	}
	return

fullconfig() {
	tempdisable:=1
	menu, tray, icon, ico\red.ico
	runwait, %comspec% /c soundvolumeview\soundvolumeview /stab "" | getnir\getnir "Name" "Type=Device && Direction=Capture" > devicelist.dat,, hide
	filesetattrib, +H, devicelist.dat
	fileread, devicelist, devicelist.dat
	loop, parse, devicelist, `n, `r
	{
		capturedevices%A_Index%:=A_LoopField
		amountofdevices+=1
	}
	filedelete, devicelist.dat
	filedelete, wizard.bat
	
	fileappend, `n@ECHO OFF`n:start`n@CLS`nECHO.`nECHO   SCRLLOCKMICMUTE Configuration Wizard`nECHO., wizard.bat
	filesetattrib, +H, wizard.bat
	fileappend, `nECHO     1 - Start the configuration wizard [recommended], wizard.bat
	fileappend, `nECHO     2 - Generate the default scrllockmm.ini, wizard.bat
	fileappend, `nECHO         This default configuration will use the search tag `"Microphone`"., wizard.bat
	fileappend, `nECHO         Will work only if you have one microphone`, named `"(something) microphone (something)`"., wizard.bat
	fileappend, `nECHO         For example when your one and only microphone is called `"Headset Microphone`"., wizard.bat
	if (firstrun="0")
		fileappend, `nECHO     0 - Exit and restart, wizard.bat
	fileappend, `nECHO., wizard.bat
	fileappend, `nSET useroption="", wizard.bat
	if (firstrun="1")
		fileappend, `nSET /P useroption="... Enter option [1/2]: ", wizard.bat
	else
		fileappend, `nSET /P useroption="... Enter option [1/2/0]: ", wizard.bat
	fileappend, `nIF "`%useroption`%"=="1" goto startwizard, wizard.bat
	fileappend, `nIF "`%useroption`%"=="2" goto startdefault, wizard.bat
	if (firstrun="0")
		fileappend, `nIF "`%useroption`%"=="0" goto x, wizard.bat
	fileappend, `nECHO     Unvalid input, wizard.bat
	fileappend, `ntimeout /t 2 /nobreak >nul, wizard.bat
	fileappend, `nGOTO start, wizard.bat
	
	fileappend, `n:startwizard, wizard.bat
	fileappend, `n@ECHO `/ > scrllockmm.ini, wizard.bat
	fileappend, `n@ECHO `/ configuration file for SCRLLOCKMM >> scrllockmm.ini, wizard.bat
	fileappend, `n@ECHO `/ If you opened this file by clicking manualedit in the task tray menu`, >> scrllockmm.ini, wizard.bat
	fileappend, `n@ECHO `/ then closing this notepad instance will automatically restart SCRLLOCKMM. >> scrllockmm.ini, wizard.bat
	fileappend, `n@ECHO `/ Don`'t forget to save before you close! >> scrllockmm.ini, wizard.bat
	fileappend, `n@ECHO `/ >> scrllockmm.ini, wizard.bat
	fileappend, `n@CLS, wizard.bat
	fileappend, `nECHO., wizard.bat
	fileappend, `nECHO     [1/5] List of available capture devices, wizard.bat
	fileappend, `nECHO., wizard.bat
	loop % amountofdevices
	{
		fileappend, % "`nECHO     " . A_Index . "/  " . capturedevices%A_Index%, wizard.bat
	}
	amountplus1 := % (amountofdevices+1)
	amountplus2 := % (amountofdevices+2)
	amountplus3 := % (amountofdevices+3)
	fileappend, `nECHO., wizard.bat
	fileappend, % "`nECHO     " . amountplus1 . "/  " . "Default capture device", wizard.bat
	fileappend, % "`nECHO     " . amountplus2 . "/  " . "Default communications capture device", wizard.bat
	fileappend, % "`nECHO     " . amountplus3 . "/  " . "Default multimedia capture device", wizard.bat
	fileappend, `nECHO., wizard.bat

	fileappend, `nSET deviceoption="", wizard.bat
	fileappend, `nSET /P deviceoption="... Enter device number to mute with SCRLLOCK: ", wizard.bat
	loop % amountofdevices
	{
		fileappend, `nIF "`%deviceoption`%"=="%A_Index%" goto wizard%A_Index%, wizard.bat
	}
	fileappend, `nIF "`%deviceoption`%"=="%amountplus1%" goto wizard%amountplus1%, wizard.bat
	fileappend, `nIF "`%deviceoption`%"=="%amountplus2%" goto wizard%amountplus2%, wizard.bat
	fileappend, `nIF "`%deviceoption`%"=="%amountplus3%" goto wizard%amountplus3%, wizard.bat
	fileappend, `nECHO., wizard.bat
	fileappend, `nECHO     Unvalid input, wizard.bat
	fileappend, `ntimeout /t 2 /nobreak >nul, wizard.bat
	fileappend, `nGOTO startwizard, wizard.bat
	
	loop % amountofdevices
	{
		fileappend, `n:wizard%A_Index%, wizard.bat
		fileappend, % "`n@ECHO devicetomute=" . capturedevices%A_Index% . " >> scrllockmm.ini", wizard.bat
		fileappend, `nECHO., wizard.bat
		fileappend, `nGOTO wizardx2, wizard.bat
	}
	fileappend, `n:wizard%amountplus1%, wizard.bat
	fileappend, % "`n@ECHO devicetomute=default >> scrllockmm.ini", wizard.bat
	fileappend, `nECHO., wizard.bat
	fileappend, `nGOTO wizardx2, wizard.bat
	fileappend, `n:wizard%amountplus2%, wizard.bat
	fileappend, % "`n@ECHO devicetomute=defaultcomm >> scrllockmm.ini", wizard.bat
	fileappend, `nECHO., wizard.bat
	fileappend, `nGOTO wizardx2, wizard.bat
	fileappend, `n:wizard%amountplus3%, wizard.bat
	fileappend, % "`n@ECHO devicetomute=defaultmulti >> scrllockmm.ini", wizard.bat
	fileappend, `nECHO., wizard.bat

	fileappend, `n:wizardx2, wizard.bat
	fileappend, `nCLS, wizard.bat
	fileappend, `nECHO., wizard.bat
	fileappend, `nECHO     [2/5] Launch as admin?, wizard.bat
	fileappend, `nECHO           Strongly advised to launch as admin ([y])., wizard.bat
	fileappend, `nECHO., wizard.bat
	fileappend, `nSET answer1="", wizard.bat
	fileappend, `nSET /P answer1="... Enter [y/n]: ", wizard.bat
	fileappend, `nIF "`%answer1`%"=="y" goto wizardp2y, wizard.bat
	fileappend, `nIF "`%answer1`%"=="n" goto wizardp2n, wizard.bat
	fileappend, `nECHO Unvalid input., wizard.bat
	fileappend, `ntimeout /t 2 /nobreak >nul, wizard.bat
	fileappend, `nGOTO wizardx2, wizard.bat
	fileappend, `n:wizardp2y, wizard.bat
	fileappend, `n@ECHO startadmin=1 >> scrllockmm.ini, wizard.bat
	fileappend, `nECHO., wizard.bat
	fileappend, `nGOTO wizardp3, wizard.bat
	fileappend, `n:wizardp2n, wizard.bat
	fileappend, `n@ECHO startadmin=0 >> scrllockmm.ini, wizard.bat
	fileappend, `nECHO., wizard.bat

	fileappend, `n:wizardp3, wizard.bat
	fileappend, `nCLS, wizard.bat
	fileappend, `nECHO., wizard.bat
	fileappend, `nECHO     [3/5] Beep sounds?, wizard.bat
	fileappend, `nECHO., wizard.bat
	fileappend, `nSET answer3="", wizard.bat
	fileappend, `nSET /P answer3="... Enter [y/n]: ", wizard.bat
	fileappend, `nIF "`%answer3`%"=="y" goto wizardp3y, wizard.bat
	fileappend, `nIF "`%answer3`%"=="n" goto wizardp3n, wizard.bat
	fileappend, `nECHO Unvalid input., wizard.bat
	fileappend, `ntimeout /t 2 /nobreak >nul, wizard.bat
	fileappend, `nGOTO wizardp3, wizard.bat
	fileappend, `n:wizardp3y, wizard.bat
	fileappend, `n@ECHO beep=1 >> scrllockmm.ini, wizard.bat
	fileappend, `nGOTO wizardp4, wizard.bat
	fileappend, `n:wizardp3n, wizard.bat
	fileappend, `n@ECHO beep=0 >> scrllockmm.ini, wizard.bat
	fileappend, `nGOTO x, wizard.bat
		
	fileappend, `n:wizardp4, wizard.bat
	fileappend, `nCLS, wizard.bat
	fileappend, `nECHO., wizard.bat
	fileappend, `nECHO     [4/5] Frequency of mute beep?, wizard.bat
	fileappend, `nECHO., wizard.bat
	fileappend, `nSET answer4=360, wizard.bat
	fileappend, `nSET /P answer4="... Enter frequency [default 360]: ", wizard.bat
	fileappend, `nIF "`%answer4`%"=="" SET answer4=360, wizard.bat
	fileappend, `n@ECHO mutefreq=`%answer4`% >> scrllockmm.ini, wizard.bat
	fileappend, `n:wizardp5, wizard.bat
	fileappend, `nCLS, wizard.bat
	fileappend, `nECHO., wizard.bat
	fileappend, `nECHO     [5/5] Frequency of unmute beep?, wizard.bat
	fileappend, `nECHO., wizard.bat
	fileappend, `nSET answer5=240, wizard.bat
	fileappend, `nSET /P answer5="... Enter frequency [default 240]: ", wizard.bat
	fileappend, `nIF "`%answer5`%"=="" SET answer5=240, wizard.bat
	fileappend, `n@ECHO unmutefreq=`%answer5`% >> scrllockmm.ini, wizard.bat
	fileappend, `nGOTO x, wizard.bat
	
	fileappend, `n:startdefault, wizard.bat
	fileappend, `nCLS, wizard.bat
	fileappend, `n@ECHO `/ > scrllockmm.ini, wizard.bat
	fileappend, `n@ECHO `/ configuration file for SCRLLOCKMM >> scrllockmm.ini, wizard.bat
	fileappend, `n@ECHO `/ if you opened this file by clicking manualedit in the task tray menu`, >> scrllockmm.ini, wizard.bat
	fileappend, `n@ECHO `/ then closing this notepad instance will automatically restart SCRLLOCKMM >> scrllockmm.ini, wizard.bat
	fileappend, `n@ECHO `/ but don`'t forget to save before you close! >> scrllockmm.ini, wizard.bat
	fileappend, `n@ECHO `/ >> scrllockmm.ini, wizard.bat
	fileappend, `nECHO., wizard.bat
	fileappend, `n@ECHO devicetomute=Microphone>> scrllockmm.ini, wizard.bat
	fileappend, `n@ECHO startadmin=1 >> scrllockmm.ini, wizard.bat
	fileappend, `n@ECHO beep=0 >> scrllockmm.ini, wizard.bat
	fileappend, `nECHO., wizard.bat
	fileappend, `nECHO     Default scrllockmm.ini generated., wizard.bat
	fileappend, `nECHO., wizard.bat
	fileappend, `ntimeout /t 2 /nobreak >nul, wizard.bat
	
	fileappend, `n:x, wizard.bat
	fileappend, `nCLS, wizard.bat
	fileappend, `nECHO., wizard.bat
	fileappend, `nECHO     All set! Be sure to check out the configuration menu, wizard.bat
	fileappend, `nECHO     by right-clicking the "S" in task tray (bottom right)., wizard.bat 
	fileappend, `nECHO., wizard.bat
	fileappend, `nECHO     But first`, press any key to close this window and restart SCRLLOCKMM!, wizard.bat
	fileappend, `nECHO., wizard.bat
	fileappend, `n@pause>nul, wizard.bat
	fileappend, `ntimeout /t 2 /nobreak >nul, wizard.bat
	
	fileappend, `n:xx, wizard.bat
	fileappend, `n, wizard.bat
	runwait, wizard.bat
	filedelete, wizard.bat
	fileappend, timeout /t 2 /nobreak >nul, restart.bat
	filesetattrib, +H, restart.bat
	process, exist, SCRLLOCKMM.exe
	if (!Errorlevel=0)
		fileappend, `nstart SCRLLOCKMM.exe, restart.bat
	else
		fileappend, `nstart scrllockmm.ahk, restart.bat
	fileappend, `nexit, restart.bat
	run, restart.bat, , hide
	exitapp
}

beep1() {
	soundbeep, %mutefreq%, 66
	return
}

beep0() {
	soundbeep, %unmutefreq%, 66
	return
}

flash(amount, duration, holdl, holdr, marginl, marginr) {
	setstorecapslockmode off
	nummemory:=getkeystate("numlock","T")
	capsmemory:=getkeystate("capslock","T")
	scrollmemory:=getkeystate("scrolllock", "T")
	setnumlockstate off
	setcapslockstate off
	setscrolllockstate off
	sleep marginl
	send {scrolllock}
	sleep duration
	send {capslock}
	sleep duration
	send {numlock}
	sleep holdl
	send {numlock}
	sleep duration
	send {capslock}
	sleep duration
	send {scrolllock}
	enplus:=amount-1
	loop %enplus%
	{
		sleep holdr
		send {scrolllock}
		sleep duration
		send {capslock}
		sleep duration
		send {numlock}
		sleep holdl
		send {numlock}
		sleep duration
		send {capslock}
		sleep duration
		send {scrolllock}
	}
	if (nummemory=1 or capsmemory=1 or scrollmemory=1)
		sleep, marginr
	if (nummemory=1)
		setnumlockstate, on
	if (capsmemory=1)
		setcapslockstate, on
	if (scrollmemory=1)
		setscrolllockstate, on
	setstorecapslockmode, on
}