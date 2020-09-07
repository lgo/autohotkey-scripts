# DeviceEventListener

Device event listener is a set of AutoHotkey scripts for triggering scripts on device attach or detach events.

For example, one use-case is triggering a script when connecting a USB mouse.

JPV (Oldman) is the author of this fine work, which was originally shared at https://autohotkey.com/board/topic/113924-register-device-for-notifications/#entry664788.

A minor fix was required to get it to work on modern 64-bit Windows (tested on Windows 10 64-bit).

## Usage

This script is a _tad_ complicated by the fact that Windows devices are insane. Here's a brief set of instructions on how to use it (from my attempt), but do not expect it to go smoothly! The scripts also have some instructions in them for advanced usage.

Preferably, you can use Window's Device Manager to find your device. A script `List Device Interfaces` is also provided to enumerate all devices.

1. Find the Device Interface ID for the AutoHotkey script to listen to.
    - Open Device Manager
    - Find the device of interest
    - Navigate to to Details and then Device Instance Path. Copy the ID. In my case, I wanted a "Razer DeathAddr Chroma" mouse which has the ID `HID\VID_1532&PID_0043&MI_00\9&32D8952&0&0000`.

2. Run `Config Register Device.ahk`. When asked for a file provide `Register Device.ahk`. Select the appropriate device class (for a mouse, `GUID_DEVINTERFACE_MOUSE`) and then provide the Device Interface ID from (2).

3. Run `Register Device.ahk`. :tada:, you should now have an AutoHotkey script that listens for attach and detach events. You can go ahead and modify commented code at the bottom of the script to customize it.