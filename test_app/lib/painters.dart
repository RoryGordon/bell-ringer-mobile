import 'dart:math';

import 'package:flutter/material.dart';
import 'package:test_app/structures.dart';

class PaintWidget extends StatefulWidget {
  final DataStruct data;
  PaintWidget({Key key, this.data}) : super(key: key);

  @override
  _PaintWidgetState createState() => _PaintWidgetState();
}

class _PaintWidgetState extends State<PaintWidget> {
  bool _isCalibrated = false;

  int _calibrateState() {
    setState(() {
      _isCalibrated = false;
    });
    widget.data.unCalibrate();
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCalibrated) {
      if (widget.data.calibrate() >= 6) {
        setState(() {
          _isCalibrated = true;
        });
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text("Swing: ${widget.data.getSwingCount()} " +
            "| C: ${widget.data.getConstant().toStringAsPrecision(4)} " +
            "| acc: ${widget.data.getAcc().toStringAsPrecision(4)}\n" +
            "angle: ${widget.data.getAngle().toStringAsPrecision(4)}" +
            "| cos: ${widget.data.getCosThetaMax().toStringAsPrecision(4)}" +
            "| vel2: ${widget.data.getThetaDotSq().toStringAsPrecision(4)}\n" +
            "radius: ${widget.data.getRadius().toStringAsPrecision(4)}"),
        Expanded(
          child: CustomPaint(
            foregroundPainter: PointPainter(widget.data),
            painter: LinePainter(widget.data.predAngle()),
            child: Container(),
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
                onPressed: () => widget.data.resetAngle(),
              ),
              RaisedButton(
                child: Text("Calibrate"),
                onPressed: () => _calibrateState(),
                color: _isCalibrated ? Colors.blue : Colors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LinePainter extends CustomPainter {
  final double radius = 100;
  final double cosTheta;
  LinePainter(this.cosTheta);

  @override
  void paint(Canvas canvas, Size size) {
    Offset center = Offset(size.width / 2, size.height / 2);

    var circlePaint = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (cosTheta != null) {
      var paint = Paint()
        ..color = Colors.red
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      var path = Path();

      path.moveTo(
        center.dx - radius,
        center.dy + radius * cosTheta,
      );
      path.lineTo(
        center.dx + radius,
        center.dy + radius * cosTheta,
      );

      canvas.drawPath(path, paint);
    }
    canvas.drawCircle(center, 100, circlePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

// FOR PAINTING THE TRACKING POINT
class PointPainter extends CustomPainter {
  final double radius = 100;
  final double radOffset = pi / 2;
  final DataStruct data;
  PointPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    double radians = data.getAngle();
    double ddot = data.getDdot();
    double torque = data.getTorque();

    var paint = Paint()
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

    final textSpan = TextSpan(
      text:
          "(${(radius * -sin(radians)).round()}, ${(radius * -cos(radians)).round()})",
      style: TextStyle(color: Colors.white, fontSize: 16),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      minWidth: 0,
      maxWidth: 100,
    );

    var path = Path();

    Offset center = Offset(size.width / 2, size.height / 2);

    Rect ddotRect = Rect.fromCircle(
      center: center,
      radius: 0.9 * radius,
    );

    Rect torqueRect = Rect.fromCircle(
      center: center,
      radius: 0.8 * radius,
    );

    canvas.drawArc(
      ddotRect,
      radians + radOffset,
      (ddot / 5),
      false,
      ddotPaint,
    );

    canvas.drawArc(
      torqueRect,
      radians + radOffset,
      (torque / 5),
      false,
      ddotPaint,
    );

    path.moveTo(center.dx, center.dy);

    Offset pointOnCircle = Offset(
      radius * -sin(radians) + center.dx,
      radius * cos(radians) + center.dy,
    );

    // For showing the point moving on the circle
    canvas.drawCircle(pointOnCircle, 10, pointPaint);

    if (sin(radians) < 0.0) {
      //canvas.drawCircle(center, -radius * sin(radians), innerCirclePaint);
      textPainter.paint(
        canvas,
        pointOnCircle + Offset(-100, 10),
      );
    } else {
      //canvas.drawCircle(center, radius * sin(radians), innerCirclePaint);
      textPainter.paint(
        canvas,
        pointOnCircle + Offset(10, 10),
      );
    }

    path.lineTo(pointOnCircle.dx, pointOnCircle.dy);
    //path.lineTo(pointOnCircle.dx, center.dy);

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
