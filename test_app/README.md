# Bell-ringing feedback app

This application is designed to work with hardware connected to a full-circle bell's wheel.

## Getting Started

Using Visual Studio Code as an IDE, pressing F5 will begin debugging - you will need to change permissions on your phone through settings to allow "developer mode". This app won't work on an emulator due to the use of BLE.

## Layout

The code itself can be found in the `lib` directory.

Device selection is handled through the `FindDevicesScreen` and widgets found in `widgets.dart`. The main function of the app is split amongst the `Model`, `View` and `Controller` classes, each with their own respective files.

### `Model`

Handles the mathematical model. The `runStream()` method is what gets updated and returns the salient outputs.

### `View`

This class exclusively deals with drawing to the screen by returning objects extended from `CustomPainter`.

### `Controller`

Responsible for interfacing with the `BluetoothCharacteristic`, as well as the main event loop.
