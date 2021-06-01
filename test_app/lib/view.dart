import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'package:test_app/model.dart';
import 'package:test_app/controller.dart';

class DeviceScreenView extends StatefulWidget {
  final BluetoothDevice device;
  const DeviceScreenView({Key key, this.device}) : super(key: key);

  @override
  View createState() => View(device);
}

class View extends State<DeviceScreenView> {
  // BluetoothCharacteristic char;

  Controller controller;
  Model model;

  bool isCalibrating = false;
  bool isSetup = false;

  View(device) {
    controller = Controller(device, this);
  }

  void setControllerModel(controller, model) {
    this.controller = controller;
    this.model = model;
  }

  void setController(controller) {
    this.controller = controller;
  }

  void setModel(model) {
    this.model = model;
  }

  void update() {
    // Called by controller
    setState(() {});
  }

  void notifyCalibrate(bool isCalibrating) {
    setState(() {
      this.isCalibrating = isCalibrating;
    });
  }

  Future<void> setup() async {
    await controller.setupDevice();
    setState(() {
      isSetup = true;
    });
  }

  Widget _streamBuilder(c, snapshot) {
    MeasuredVals values = snapshot.data;
    return CustomPaint(
      foregroundPainter: Painter(values),
      painter: BgPainter(),
      child: Container(),
    );
  }

  cont() {
    setState(() {
      isSetup = true;
    });
  }

  Widget build(BuildContext context) {
    if (isSetup) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: SafeArea(
              child: StreamBuilder<MeasuredVals>(
                stream: model.runStream(controller.readCharacteristic()),
                builder: (c, snapshot) => _streamBuilder(c, snapshot),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
          ),
          Card(
            child: ButtonBar(
              children: [
                RaisedButton(
                  child: Text("Reset angle"),
                  onPressed: () => model.zeroSet(),
                ),
                RaisedButton(
                  child: Text("Calibrate"),
                  onPressed: () {
                    model.calibrate();
                    setState(() {
                      isCalibrating = true;
                    });
                  },
                  color: isCalibrating ? Colors.red : Colors.blue,
                ),
              ],
            ),
          ),
        ],
      );
    } else if (controller.characteristic == null) {
      // setup();
      return RaisedButton(
        child: Text("Set up (no char)"),
        onPressed: () => setup(),
      );
    } else {
      return RaisedButton(
        child: Text("Set up done!"),
        onPressed: cont(),
      );
    }
  }
}

class BgPainter extends CustomPainter {
  static const double radius = 100;

  @override
  void paint(Canvas canvas, Size size) {
    Offset center = Offset(size.width / 2, size.height / 2);
    var circlePaint = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, 100, circlePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

class Painter extends CustomPainter {
  static const double radius = 100;
  static const double rightAngle = pi / 2;
  final MeasuredVals values;
  Painter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    Offset center = Offset(size.width / 2, size.height / 2);

    Offset pointOnCircle = Offset(
      radius * -sin(values.theta) + center.dx,
      radius * cos(values.theta) + center.dy,
    );

    var heightPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    var linePaint = Paint()
      ..color = Colors.teal
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    var pointPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 1
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    var ddotPaint = Paint()
      ..color = Colors.tealAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (values.predHeight != null) {
      Path heightPath = Path()
        ..moveTo(
          center.dx - radius,
          center.dy + radius * values.predHeight,
        )
        ..lineTo(
          center.dx + radius,
          center.dy + radius * values.predHeight,
        );

      canvas.drawPath(heightPath, heightPaint);
    }

    Path linePath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(pointOnCircle.dx, pointOnCircle.dy);

    Rect ddotRect = Rect.fromCircle(
      center: center,
      radius: 0.9 * radius,
    );

    // Rect torqueRect = Rect.fromCircle(
    //   center: center,
    //   radius: 0.8 * radius,
    // );

    canvas.drawPath(linePath, linePaint);

    canvas.drawArc(
      ddotRect,
      values.theta + rightAngle,
      (values.thetaDdot / 5),
      false,
      ddotPaint,
    );

    // For showing the point moving on the circle
    canvas.drawCircle(pointOnCircle, 10, pointPaint);
    // canvas.drawArc(
    //   torqueRect,
    //   values.theta + rightAngle,
    //   (torque / 5),
    //   false,
    //   ddotPaint,
    // );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
