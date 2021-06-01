import 'dart:async';

import 'package:flutter_blue/flutter_blue.dart';

import 'package:test_app/view.dart';
import 'package:test_app/model.dart';

class Controller {
  View view;
  Model model;
  BluetoothDevice device;
  BluetoothCharacteristic characteristic;

  Controller(this.device, this.view) {
    model = new Model();
    view.setModel(model);
  }

  // Future<BluetoothCharacteristic> setupDeviceOld() async {
  //   // this is almsot certainly not going to work
  //   await device.discoverServices();
  //   Stream<List<BluetoothService>> serviceStream = device.services;
  //   await for (List<BluetoothService> services in serviceStream) {
  //     for (BluetoothService service in services) {
  //       var serviceId = service.uuid.toString().toUpperCase().substring(4, 8);
  //       if (serviceId == "FFE0") {
  //         for (BluetoothCharacteristic char in service.characteristics) {
  //           this.characteristic = char;
  //           _enableNotify();
  //           //...
  //           return characteristic;
  //         }
  //       }
  //     }
  //   }
  //   return null;
  // }

  //TODO: Try making this Future<void>
  Future<BluetoothCharacteristic> setupDevice() async {
    // this is almsot certainly not going to work
    await device.discoverServices();
    await device.services.first.then((services) {
      for (BluetoothService service in services) {
        var serviceId = service.uuid.toString().toUpperCase().substring(4, 8);
        if (serviceId == "FFE0") {
          for (BluetoothCharacteristic char in service.characteristics) {
            this.characteristic = char;
            _enableNotify();
            return this.characteristic;
          }
        }
      }
    });
  }

  Stream<RawVals> readCharacteristic() async* {
    await for (List<int> value in characteristic.value) {
      yield _fromIntList(value);
    }
  }

  Future<void> _enableNotify() async {
    if (!characteristic.isNotifying) {
      await characteristic.setNotifyValue(true);
    }
  }

  RawVals _fromIntList(List<int> outputList) {
    //TODO: Update arduino to send x accel
    if (outputList.length == 13) {
      int acc = outputList[4] | outputList[5] << 8;
      int gyr = outputList[6] | outputList[7] << 8;
      List<int> imu = [
        outputList[8] | outputList[9] << 8,
        outputList[10] | outputList[11] << 8
      ];

      if (acc >= 0x8000) {
        acc -= 0x10000;
      }
      if (gyr >= 0x8000) {
        gyr -= 0x10000;
      }
      if (imu[0] >= 0x8000) {
        imu[0] -= 0x10000;
      }
      if (imu[1] >= 0x8000) {
        imu[1] -= 0x10000;
      }
      return RawVals(imu[0], imu[1], gyr, 0, acc);
    } else {
      print("Incorrect length of outputList");
      return RawVals(0, 0, 0, 0, 0);
    }
  }

  void calibrate() {}
  void resetAngle() {}
}
