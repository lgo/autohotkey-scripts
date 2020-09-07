/*
Title: List Device Interfaces (v0.0 August 18, 2014)

Introduction
------------

	The 'List Device Interfaces' script allows you to generate a list (.txt file) of 'Devices' with some of
	their characteristics.
	
	You can request the full list with or without a 'Device Reference', such as the Device Name, the Device
	Interface ID or the Hardware ID.
	
	The 'Device Name' can be chosen from the Windows Device Manager. This is either the 'Friendly Name' or
	the 'Device Description'. The 'Friendly Name' takes precedence over the 'Device Description'.
	
	The 'Device Instance ID' can be chosen from the Windows Device Manager.
	- Right-click on the 'Device Name' and select "Properties".
	- Click on the 'Detail' tab.
	  You should see the 'Device Instance ID'.
	
	The 'Hardware ID' can be chosen from the Windows Device Manager.
	- Right-click on the 'Device Name' and select "Properties".
	- Click on the 'Detail' tab and press the Down key, once.
	  You should see the 'Hardware IDs'. This is a multi-string value.
	  The script uses the first string (line) as the Hardware ID.
	
	You can request a list for a specific 'Device Interface Class' with or without a 'Device Reference'.
	In this case, you select the 'Device Interface Class' from the dropdown list.
	
	The 'Device Interface Class' refers to the 'Device Interface Class GUID'.
	You can find a list of the 'Device Interface Classes' with their 'Device Interface Class GUID' in the
	'EnumDeviceInterfaceClasses' module, located in the 'Lib' folder.
	
	You can choose additional criteria such as, the 'Devices that are currently present in the system' and/or
	the 'Devices that are part of the current hardware profile'. If you choose the 'Device currently present
	in the system', the Devices have to be plugged to be listed.
	
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
	
	If you know the 'Device Interface Class', but you don't know none of the 'Device Reference', select the
	'Device Interface Class' in the dropdownlist and leave empty the 'Device Reference'.
	
	If you know one of the 'Device Reference', but you don't know the 'Device Interface Class', leave the
	'Device Interface Class' empty and enter the 'Device Reference'.
	
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

DropDownListIdentifier=
for Identifier, InterfaceGUID in EnumDeviceInterfaceClasses
	DropDownListIdentifier .= "|" Identifier

Gui, Main:New, -MaximizeBox, % A_ScriptName
Gui, Add, Text,, Please, make your selection ?
Gui, Add, Text, w160, Device Interface Class (optional) :
Gui, Add, DropDownList, x+5 w320 r15 vIdentifier, %DropDownListIdentifier%
Gui, Add, CheckBox, x175  vIsPresent Checked, Present
Gui, Add, CheckBox, x+5  vIsProfile, Profile
Gui, Add, Text, x10 w160, Device ref. (optional) :
Gui, Add, Edit, x+5 w320 vDeviceRef
Gui, Add, Button, x10  w50 vButtonOK, OK
Gui, Add, Button, x+10 w50 vButtonCancel, Cancel
Gui, Show
return

MainGuiClose:
MainGuiEscape:
MainButtonCancel:
	ExitApp

MainButtonOK:
	Gui, Submit
	
	Flags=0
	
	if IsPresent
		Flags |= DIGCF_PRESENT
	
	if IsProfile
		Flags |= DIGCF_PROFILE
	
	ListDeviceInterfaces(DeviceRef, Identifier,, Flags)
	MsgBox, 64, % A_ScriptName, List done !, 2
	ExitApp
