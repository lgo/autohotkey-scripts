/*
Title: Register Device (v0.0 August 18, 2014)

Introduction
------------

	The 'Register Device' script allows you to register a device for notifications.
	
	When the device is plugged or unplugged you may wish to perform different actions.
	When the device is plugged, you can launch an application.
	When the device is unpluged, you can close that application.
	
	The script requires 2 parameters, the 'Identifier' and the 'Device Path'.
	
	The 'Identifier' is the 'Device Interface Class' which refers to the 'Device Interface Class GUID'.
	You can find a list of the 'Device Interface Classes' in the 'EnumDeviceInterfaceClasses' module,
	located in the 'Lib' folder.
	
	The 'Device Path' is gathered from the system by the 'Config Register Device' script.
	
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
	
	Launch the script, before plugging the device.
	The script is persistent.
	
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

#Include <EnumDeviceInterfaceClasses>

; Message numbers
global WM_DEVICECHANGE       = 0x219
global WM_APPLY_DEVICECHANGE = 0x8001

; Device Broadcast Header - device type
global DBT_DEVTYP_DEVICEINTERFACE = 0x5
global DBT_DEVTYP_HANDLE          = 0x6
global DBT_DEVTYP_OEM             = 0x0
global DBT_DEVTYP_PORT            = 0x3
global DBT_DEVTYP_VOLUME          = 0x2

gosub, ReadSettings

if !hDevice := RegisterDeviceNotification(Identifier, DevicePath)
	ExitApp

OnMessage(WM_DEVICECHANGE, "DeviceChange")
OnMessage(WM_APPLY_DEVICECHANGE, "ApplyDeviceChange")
OnExit, EndScript
return

^Esc::ExitApp

ReadSettings:
	ScriptName := SubStr(A_ScriptName, 1, InStr(A_ScriptName, ".") - 1)
	CfgFile    := ScriptName ".ini"
	
	IfNotExist, %CfgFile%
	{
		MsgBox, 16, % A_ScriptName, The settings file is missing.`nPlease, configure !
		ExitApp
	}
	
	IniRead, Identifier, %CfgFile%, Settings, Identifier
	
	if (Identifier = "ERROR")
	{
		MsgBox, 16, % A_ScriptName, The Identifier is missing.`nPlease, configure !
		ExitApp
	}
	
	IniRead, DevicePath, %CfgFile%, Settings, DevicePath
	
	if (DevicePath = "ERROR")
	{
		MsgBox, 16, % A_ScriptName, The Device Path is missing.`nPlease, configure !
		ExitApp
	}
	
	return

EndScript:
	UnregisterDeviceNotification(hDevice)
	ExitApp

/*
==============================================================================================
	RegisterDeviceNotification(Identifier, DevicePath)
	
	Identifier : Device Interface Class (in)
	DevicePath : String identifying the Device Driver (in optional)
	
	Register a Device for which a window will receive notifications.
==============================================================================================
*/
RegisterDeviceNotification(ByRef _identifier, ByRef _devicePath="")
{
	; Register Device Notification Flags
	static DEVICE_NOTIFY_WINDOW_HANDLE         = 0x0
	static DEVICE_NOTIFY_SERVICE_HANDLE        = 0x1
	static DEVICE_NOTIFY_ALL_INTERFACE_CLASSES = 0x4
	
	static TCHAR_SIZE = A_IsUnicode ? 2 : 1
	
	;-----------------------
	; Verify the parameters
	;-----------------------
	if !EnumDeviceInterfaceClasses.HasKey(_identifier)
	{
		MsgBox, 16, % A_ScriptName, % "The identifier (" _identifier
						. ") does not exist in the EnumDeviceInterfaceClasses array"
		return false
	}
	
	;--------------------------------
	; Register a Device Notification
	;--------------------------------
	; ClassGUID
	;----------
	lGUID := EnumDeviceInterfaceClasses[_identifier]
	VarSetCapacity(lClassGUID, 16, 0)
	ClassGuidFromString(lClassGUID, lGUID)
	
	; DEV_BROADCAST_DEVICEINTERFACE
	;------------------------------
	; DWORD + DWORD + DWORD + GUID + (TCHAR[1] or PTR) --> PTR (weird)
	lLen := 12 + 16 + A_PtrSize
	VarSetCapacity(NotificationFilter, lLen+(StrLen(_devicePath)*TCHAR_SIZE), 0)
	
	Numput(lLen, NotificationFilter, 0, "UInt")								; dbcc_size
	Numput(DBT_DEVTYP_DEVICEINTERFACE, NotificationFilter, 4, "UInt")	; dbcc_devicetype
	StructPut(lClassGUID, NotificationFilter, 16, 12)						; dbcc_classguid
	
	if _devicePath
		StrPut(_devicePath, &NotificationFilter+28)							; dbcc_name[1]
	
	if !lDevHwnd := DllCall("user32.dll\RegisterDeviceNotification"
												, "Ptr" , A_ScriptHwnd
												, "Ptr" , &NotificationFilter
												, "UInt", DEVICE_NOTIFY_WINDOW_HANDLE
												, "Ptr")
	{
		MsgBox, 16, % A_ScriptName, % "RegisterDeviceNotification() failed " A_LastError
		return false
	}
	
	return lDevHwnd
}

/*
==============================================================================================
	ClassGuidFromString(ClassGUID, GUID)
	
	ClassGUID : Class GUID structure (out)
	GUID      : Class GUID string (in)
	
	Convert the GUID string into a GUID structure
==============================================================================================
*/
ClassGuidFromString(ByRef _classGUID, ByRef _GUID)
{
	NumPut("0x" SubStr(_GUID,  2, 8), _classGUID,  0, "UInt")		; DWORD Data1
	NumPut("0x" SubStr(_GUID, 11, 4), _classGUID,  4, "UShort")		; WORD  Data2
	NumPut("0x" SubStr(_GUID, 16, 4), _classGUID,  6, "UShort")		; WORD  Data3
	NumPut("0x" SubStr(_GUID, 21, 2), _classGUID,  8, "UChar")		; BYTE  Data4[1]
	NumPut("0x" SubStr(_GUID, 23, 2), _classGUID,  9, "UChar")		; BYTE  Data4[2]
	NumPut("0x" SubStr(_GUID, 26, 2), _classGUID, 10, "UChar")		; BYTE  Data4[3]
	NumPut("0x" SubStr(_GUID, 28, 2), _classGUID, 11, "UChar")		; BYTE  Data4[4]
	NumPut("0x" SubStr(_GUID, 30, 2), _classGUID, 12, "UChar")		; BYTE  Data4[5]
	NumPut("0x" SubStr(_GUID, 32, 2), _classGUID, 13, "UChar")		; BYTE  Data4[6]
	NumPut("0x" SubStr(_GUID, 34, 2), _classGUID, 14, "UChar")		; BYTE  Data4[7]
	NumPut("0x" SubStr(_GUID, 36, 2), _classGUID, 15, "UChar")		; BYTE  Data4[8]
	return
}

/*
==============================================================================================
	StructPut(Data, Struct, Length, Offset)
	
	Data   : an elementary field name (in)
	Struct : a structure name (out)
	Length : the length to be copied (in)
	Offset : the starting position of the structure to be copied to (in optional)
	
	Copy an elementary field as a structure content
==============================================================================================
*/
StructPut(ByRef _data, ByRef _struct, _len, _offset=0)
{
	Loop, %_len%
		NumPut(NumGet(_data, A_Index-1, "UChar"), _struct, _offset++, "UChar")
	
	return
}

/*
==============================================================================================
	UnregisterDeviceNotification(hDevice)
	
	hDevice : Device Handle (in)
	
	Close the specified device notification handle.
==============================================================================================
*/
UnregisterDeviceNotification(_hDevice)
{
	if !_hDevice
	{
		MsgBox, 16, % A_ScriptName, The device handle is missing
		return false
	}
	
	;------------------------------------
	; Unregister the Device Notification
	;------------------------------------
	if !DllCall("user32.dll\UnregisterDeviceNotification", "Ptr", _hDevice)
		return false
	
	return true
}

/*
==============================================================================================
	Receive Notifications of the Device changes.
==============================================================================================
*/
DeviceChange(wParam, lParam, msg, hWnd)
{
	; WM_DEVICECHANGE events
	static DBT_CONFIGCHANGECANCELED    = 0x0019
	static DBT_CONFIGCHANGED           = 0x0018
	static DBT_CUSTOMEVENT             = 0x8006
	static DBT_DEVICEARRIVAL           = 0x8000
	static DBT_DEVICEQUERYREMOVE       = 0x8001
	static DBT_DEVICEQUERYREMOVEFAILED = 0x8002
	static DBT_DEVICEREMOVECOMPLETE    = 0x8004
	static DBT_DEVICEREMOVEPENDING     = 0x8003
	static DBT_DEVICETYPESPECIFIC      = 0x8005
	static DBT_DEVNODES_CHANGED        = 0x0007
	static DBT_QUERYCHANGECONFIG       = 0x0017
	static DBT_USERDEFINED             = 0xFFFF
	
	; return value to deny the request
	static BROADCAST_QUERY_DENY        = 0x424D5144
	
	if (hWnd <> A_ScriptHwnd)
		return
	
	if (wParam <> DBT_DEVICEARRIVAL and wParam <> DBT_DEVICEREMOVECOMPLETE)
		return
	
	lDeviceType := NumGet(lParam+0, 4, "UInt")
	
	if (lDeviceType <> DBT_DEVTYP_DEVICEINTERFACE)
		return
	
	; From http://msdn.microsoft.com/en-us/library/windows/desktop/aa363431%28v=vs.85%29.aspx
	; Be sure to handle Plug and Play device events as quickly as possible. Otherwise, the
	; system may become unresponsive. If your event handler is to perform an operation that may
	; block execution (such as I/O), it is best to start another thread to perform the operation
	; asynchronously.
	DetectHiddenWindows, On
	PostMessage, WM_APPLY_DEVICECHANGE, wParam, 0,, % "ahk_id " A_ScriptHwnd
	DetectHiddenWindows, Off
	return
}

/*
==============================================================================================
	Receive Notifications to apply the Device changes.
==============================================================================================
*/
ApplyDeviceChange(wParam, lParam, msg, hWnd)
{
	; WM_DEVICECHANGE events
	static DBT_DEVICEARRIVAL        = 0x8000
	static DBT_DEVICEREMOVECOMPLETE = 0x8004
	
	if (hWnd <> A_ScriptHwnd)
		return
	
	if (wParam = DBT_DEVICEARRIVAL)
	{
		ToolTip, % "Device connected"
;		Run, D:\Programs\Utilities\HIDMacros\HIDMacros.exe
	}
	
	else if (wParam = DBT_DEVICEREMOVECOMPLETE)
	{
		ToolTip, % " Device removed"
;		DetectHiddenWindows, On
;		WinClose, HID macros
;		DetectHiddenWindows, Off
	}
	
	return
}
