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

  // TODO: Move this to happen on the device selection button,
  //       and only pass the characteristic to the controller.
  //       This will let you get rid of that big blue button.
  Future<BluetoothCharacteristic> setupDevice() async {
    // this is almost certainly not going to work
    // wait for services to be visible
    await device.discoverServices();
    // get the first services list from the stream, then do{}
    await device.services.first.then((services) {
      for (BluetoothService service in services) {
        // get service id, check if it's FFE0
        var serviceId = service.uuid.toString().toUpperCase().substring(4, 8);
        if (serviceId == "FFE0") {
          // get first (and only) characteristic
          for (BluetoothCharacteristic char in service.characteristics) {
            this.characteristic = char;
            // enable notifications and return
            _enableNotify();
            return this.characteristic;
          }
        }
      }
    });
  }

  Stream<RawVals> readCharacteristic() async* {
    await for (List<int> value in characteristic.value) {
      if (!value.isEmpty) {
        // checksum
        int listLength = value.length;
        if (listLength != 15) {
          print("Length: $listLength\n List: $value");
        } else {
          int checksum =
              value.sublist(0, listLength - 1).fold(0, (p, c) => p + c) &
                  0xFF; //sum list
          if (checksum == value[listLength - 1]) {
            yield _fromIntList(value);
          } else {
            print("CHECKSUM FAILED! $checksum : ${value[listLength - 1]}");
          }
        }
      } else {
        print("VALUE EMPTY!");
      }
    }
  }

  Future<void> _enableNotify() async {
    // only do if it won't cause an error
    if (!characteristic.isNotifying) {
      await characteristic.setNotifyValue(true);
    }
  }

  RawVals _fromIntList(List<int> outputList) {
    //TODO: Update arduino to send x accel
    if (outputList.length == 15) {
      // first 4 bytes are timestamp
      //print(outputList.sublist(4));
      int accX = outputList[4] | outputList[5] << 8;
      int accY = outputList[6] | outputList[7] << 8;
      int gyr = outputList[8] | outputList[9] << 8;
      int imuX = outputList[10] | outputList[11] << 8;
      int imuY = outputList[12] | outputList[13] << 8;

      // convert to signed
      if (outputList[5] >> 7 == 1) {
        // accX = ~accX;
        accX -= 0x10000;
      }
      if (outputList[7] >> 7 == 1) {
        // accY = ~accY;
        accY -= 0x10000;
      }
      if (outputList[9] >> 7 == 1) {
        print(gyr.toRadixString(16));
        gyr -= 0x10000;
        // gyr = ~gyr;
      }
      if (outputList[11] >> 7 == 1) {
        // imuX = ~imuX;
        imuX -= 0x10000;
      }
      if (outputList[13] >> 7 == 1) {
        // imuY = ~imuY;
        imuY -= 0x10000;
      }

      return RawVals(imuX, imuY, gyr, accX, accY);
    } else {
      print("Incorrect length of outputList");
      return RawVals(0, 0, 0, 0, 0);
    }
  }

  void calibrate() {}
  void resetAngle() {}
}
