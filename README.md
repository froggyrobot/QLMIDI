# QLMIDI

QLMIDI is a Quick Look extension program for macOS. Its purpose is to extend the Quick Look function of macOS to generate audio previews of MIDI files *that automatically play* in the Quick Look pop-up window (the window that pops up when you press the space bar while a file is selected in Finder). This is useful for anyone with large libraries of MIDI files on their computer.

<p align="center">
  <img src="https://github.com/user-attachments/assets/5842c538-c4f7-4c19-b4dc-360a98b33520" width="80%" height="80%"/>
</p>

QLMIDI allows you to audition MIDI files in Finder without opening an external application, with as little friction as possible. This works in exactly the same way as Apple's own native audio Quick Look previews.

This extension was designed to be as lightweight and simple as possible &ndash; I wanted it to feel as though macOS supports MIDI playback in Quick Look natively (it did so prior to OSX 10.9). It uses AVMIDIPlayer, a MIDI player that comes included with AVfoundation and macOS, so QLMIDI doesn't have any external dependencies. The design of the UI should fit in with other audio Quick Look previews shown in Finder.

## Application

For now, the QLMIDI application is just a placeholder. It's necessary because it is the only way to install an extension of this kind in any macOS version higher than 10.15. In the future, the application will be expanded into a small preferences panel with a few options for the user to control. This code is kept in the "QLMIDI" folder.

## Extension

This is the main function of QLMIDI. This code is kept in the "QLMIDIExtension" folder. It contains the code that initializes the preview and its content, the various elements of the UI, and all of their logic and variables. Extensions of classes for UI elements used by QLMIDI are also kept in this folder.

## Installation

1. Double click on 'QLMIDI'
2. On the pop-up window, click 'Ok'
3. Go to System Preferences > Privacy & Security > Security settings and under '"QLMIDI.app" was blocked from use because it is not from an identified developer' click 'Open anyway'
4. In the pop up window, enter your password
5. Click 'Open'
