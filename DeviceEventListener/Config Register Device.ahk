/*
Title: Config Register Device (v0.0 August 18, 2014)

Introduction
------------

	The 'Config Register Device' script allows you to generate the settings required by the 'Register Device'
	script. That is, the 'Device Interface Class' and the 'Device Path'.
	
	The 'Device Interface Class' refers to the 'Device Interface Class GUID'.
	You can find a list of the 'Device Interface Classes' with their 'Device Interface Class GUID' in the
	'EnumDeviceInterfaceClasses' module, located in the 'Lib' folder.
	
	The 'Device Path' is known as the 'SymbolicLink' in the Base Registry.
	
	Before launching the script, you have to know the 'Device Interface Class' you want to operate on. If
	you don't know the 'Device Interface Class', you can use the 'List Device Interfaces' script to list the
	device characteristics in a .txt file. Then, you can make your choice from the list.
	
	You can, if you wish, enter a 'Device Reference'. The 'Device Reference' can be either the Device Name,
	the Device Interface ID or the Hardware ID. They can be gathered from the 'List Device Interfaces' .txt
	file.
	
Compatibility
-------------

	This script is designed to run on AutoHotkey v1.1.12.00+ (32 and 64-bit), on Windows XP+.

Links
-----

	Device Management Reference
	http://msdn.microsoft.com/en-us/library/windows/desktop/aa363239%28v=vs.85%29.aspx

Credit
------

How to used it
--------------
	
	Launch the script.
	The script prompts you to select the target script for which you have to generate the settings.
	It is the 'Register Device' script or a copy of it.
	In the Gui, you have to select the 'Device Interface Class'.
	You can enter a 'Device Reference' or leave it empty.
	The script prompts you :
	- to plug the device
	- to unplug the device
	- to report a success or a failure
	
Changes
-------

Author
------

	JPV alias Oldman
*/

#Warn
#SingleInstance force
#NoEnv            ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input    ; Recommended for new scripts due to its superior speed and reliability.
SetBatchLines, -1
SetFormat, IntegerFast, D
SetWorkingDir, %A_ScriptDir%  ; Ensures a consistent starting directory.

#Include <__SetupapiLib>

gosub, SelectTargetScript
gosub, ReadSettings

DropDownListIdentifier=
for IdentifierClass, InterfaceGUID in EnumDeviceInterfaceClasses
	DropDownListIdentifier .= (A_Index = 1 ? "" : "|") IdentifierClass

if Identifier
	StringReplace, DropDownListIdentifier, DropDownListIdentifier, % Identifier, % Identifier "|"

Gui, Main:New, -MaximizeBox, % A_ScriptName
Gui, Add, Text,, Please, make your selection ?
Gui, Add, Text, w115, Device Interface Class :
Gui, Add, DropDownList, x+5 w320 r10 vIdentifier, %DropDownListIdentifier%
Gui, Add, Text, x10 w115, Device ref. (optional) :
Gui, Add, Edit, x+5 w320 vDeviceRef, %DeviceRef%
Gui, Add, Button, x10  w50 vButtonOK, OK
Gui, Add, Button, x+10 w50 vButtonCancel, Cancel
Gui, Show
return

MainGuiClose:
MainGuiEscape:
MainButtonCancel:
	ExitApp

MainButtonOK:
	Gui, Submit, NoHide
	
	if !Identifier
	{
		MsgBox, 48, % A_ScriptName, You must select an Identifier
		GuiControl, Focus, Identifier
		return
	}
	
	MsgBox, 32, % A_ScriptName, Could you plug the device ?
	Sleep, 1000
	
	if !ArrDevicePlug := GetDeviceInterfaces(DeviceRef, Identifier,, DIGCF_PRESENT)
		ExitApp
	
	if !ArrDevicePlug[1].MaxIndex()
	{
		MsgBox, 16, % A_ScriptName, % "Device (" DeviceRef ") is not found in identifier class (" Identifier ")"
		ExitApp
	}
	
	MsgBox, 32, % A_ScriptName, Could you unplug the device ?
	Sleep, 1000
	
	if !ArrDeviceUnplug := GetDeviceInterfaces(DeviceRef, Identifier,, DIGCF_PRESENT)
		ExitApp
	
	DevicePath=
	for IndexPlug, PathPlug in ArrDevicePlug[8]
	{
		for IndexUnplug, PathUnplug in ArrDeviceUnplug[8]
			if (PathUnplug = PathPlug)
				continue 2
		
		DeviceName=
		DeviceInstanceID=
		HardwareID=
		
		if DeviceRef
		{
			if (ArrDevicePlug[4, IndexPlug] = DeviceRef)				; Friendly Name
				DeviceName := DeviceRef
			
			else if (ArrDevicePlug[5, IndexPlug] = DeviceRef)		; Device Description
				DeviceName := DeviceRef
			
			else if (ArrDevicePlug[6, IndexPlug] = DeviceRef)		; Device Instance ID
				DeviceInstanceID := DeviceRef
			
			else if (ArrDevicePlug[7, IndexPlug] = DeviceRef)		; Hardware ID
				HardwareID := DeviceRef
		}
		
		DevicePath := PathPlug
		break
	}
	
	if !DevicePath
	{
		MsgBox, 16, % A_ScriptName, % "No plugged Device (" DeviceRef
						. ") has been detected for the identifier (" Identifier ")"
		ExitApp
	}
	
	Gui, Destroy
	
	MsgBox, 64, % A_ScriptName, % "The Device (" DeviceRef ") is correctly identified", 2
	
	gosub, UpdateSettings
	ExitApp

SelectTargetScript:
	;--------------------------
	; Select the target script
	;--------------------------
	FileSelectFile, ScriptPath, 3,, Select the target script, *.ahk
	
	if ErrorLevel
	{
		MsgBox, 16, % A_ScriptName, No file has been selected
		ExitApp
	}
	
	return

ReadSettings:
	;----------------------------------
	; Determine the Configuration file
	;----------------------------------
	SplitPath, ScriptPath, ScriptName, ScriptDir
	ScriptName := SubStr(ScriptName, 1, InStr(ScriptName, ".ahk") - 1)
	CfgFile := ScriptDir "\" ScriptName ".ini"
	
	IfNotExist, %CfgFile%
	{
		Identifier=
		DeviceName=
		DeviceInstanceID=
		HardwareID=
		DeviceRef=
		return
	}
	
	;-------------------
	; Read the Settings
	;-------------------
	IniRead, Identifier, %CfgFile%, Settings, Identifier
	
	if (Identifier = "ERROR")
		Identifier=
	
	IniRead, DeviceName, %CfgFile%, Settings, DeviceName
	
	if (DeviceName = "ERROR")
		DeviceName=
	
	IniRead, DeviceInstanceID, %CfgFile%, Settings, DeviceInstanceID
	
	if (DeviceInstanceID = "ERROR")
		DeviceInstanceID=
	
	IniRead, HardwareID, %CfgFile%, Settings, HardwareID
	
	if (HardwareID = "ERROR")
		HardwareID=
	
	;--------------------------
	; Set the Device Reference
	;--------------------------
	if DeviceName
		DeviceRef := DeviceName
	
	else if DeviceInstanceID
		DeviceRef := DeviceInstanceID
	
	else if HardwareID
		DeviceRef := HardwareID
	
	else
		DeviceRef=
	
	return

UpdateSettings:
	IniWrite, %Identifier%, %CfgFile%, Settings, Identifier
	
	if ErrorLevel
	{
		MsgBox, 16, % A_ScriptName, % "IniWrite failed for Identifier (" Identifier ")"
		ExitApp
	}
	
	IniWrite, %DeviceName%, %CfgFile%, Settings, DeviceName
	
	if ErrorLevel
	{
		MsgBox, 16, % A_ScriptName, % "IniWrite failed for Device Name (" DeviceName ")"
		ExitApp
	}
	
	IniWrite, %DeviceInstanceID%, %CfgFile%, Settings, DeviceInstanceID
	
	if ErrorLevel
	{
		MsgBox, 16, % A_ScriptName, % "IniWrite failed for Device Instance ID (" DeviceInstanceID ")"
		ExitApp
	}
	
	IniWrite, %HardwareID%, %CfgFile%, Settings, HardwareID
	
	if ErrorLevel
	{
		MsgBox, 16, % A_ScriptName, % "IniWrite failed for Hardware ID (" HardwareID ")"
		ExitApp
	}
	
	IniWrite, %DevicePath%, %CfgFile%, Settings, DevicePath
	
	if ErrorLevel
	{
		MsgBox, 16, % A_ScriptName, % "IniWrite failed for Device Path (" DevicePath ")"
		ExitApp
	}
	
	return
