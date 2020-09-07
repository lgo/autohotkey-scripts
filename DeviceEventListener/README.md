# DeviceEventListener

Device event listener is a set of AutoHotkey scripts for triggering scripts on device attach or detach events.

For example, one use-case is triggering a script when connecting a USB mouse.

JPV (Oldman) is the author of this fine work, which was originally shared at https://autohotkey.com/board/topic/113924-register-device-for-notifications/#entry664788.

A minor fix was required to get it to work on modern 64-bit Windows (tested on Windows 10 64-bit).

## Usage

This script is a _tad_ complicated by the fact that Windows devices are insane. Here's a brief set of instructions on how to use it (from my attempt), but do not expect it to go smoothly! The scripts also have some instructions in them for advanced usage.

1. Run `List Device Interfaces.ahk`. It will create `List Device Interfaces.txt` which has a full list of devices.

2. Find the device you are interested in. In my case, I am using a "Razer DeathAddr Chroma" mouse. It has multiple entries as different device types, so I chose the "Mice" entry (`HID\VID_1532&PID_0043&MI_00\9&32D8952&0&0000`).

3. Run `Config Register Device.ahk`. When asked for a file provide `Register Device.ahk`. Select the appropriate device class (for a mouse, `GUID_DEVINTERFACE_MOUSE`) and then provide the Device Interface ID from (2).

4. Run `Register Device.ahk`. :tada:, you should now have an AutoHotkey script that listens for attach and detach events. You can go ahead and modify commented code at the bottom of the script to customize it.