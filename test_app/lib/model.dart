import 'dart:math';

import 'package:test_app/view.dart';

class Model {
  View view;

  double theta = 0;
  double thetaDot = 0;
  double thetaDdot = 0;
  double predHeight = 0;
  double torque = 0;

  double oldThetaSign = 1;
  double oldThetaDotSign = 1;

  double axisOffset = 0;
  double thetaOffset = 0;
  double deviceRadius = 1; // 0 would break everything
  double bigC = 0;

  bool isCalibrating = false;
  double _samples = 0;
  double _apexSamples = 0;
  double _baseSamples = 0;
  double _cTMaxSum = 0;
  double _tDSqMaxSum = 1;

  double _thetaSignChange() {
    // +ve if no change, -ve if change
    return oldThetaSign * theta.sign;
  }

  double _thetaDotSignChange() {
    // +ve if no change, -ve if change
    return oldThetaDotSign * thetaDot.sign;
  }

  double _torque() {
    if (bigC != null) {
      return 0.5 * thetaDdot - sin(theta);
    } else {
      return 0;
    }
  }

  void setView(View view) {
    this.view = view;
  }

  bool getCalibState() {
    return isCalibrating;
  }

  List<double> getState() {
    return [theta, thetaDot, thetaDdot, predHeight];
  }

  // void update() {}

  void zeroSet() {
    thetaOffset = theta + thetaOffset;
  }

  Future<void> _notifyCalibrate(bool isCalibrating) {
    // doesn't work, unsure why
    view.notifyCalibrate(isCalibrating);
    return null;
  }

  Future<void> calibrate() async {
    isCalibrating = true;
    // _notifyCalibrate(true);
    _cTMaxSum = 0;
    _tDSqMaxSum = 0;
    _apexSamples = 0;
    _baseSamples = 0;
    _samples = 0;
    bigC = null;
    while (_samples <= 10) {
      await Future.delayed(Duration(seconds: 5));
    }
    isCalibrating = false;
    bigC = _bigC();
    // _notifyCalibrate(false);
  }

  double _setTheta(RawVals vals) {
    double _theta = -asin(vals.gY / vals.gMagnitude());

    if (vals.gX < 0) {
      _theta = pi - _theta;
    }
    return _theta - thetaOffset;
  }

  double _bigC() {
    double _bigCNew;
    if (_tDSqMaxSum != 0 && _apexSamples != 0) {
      _bigCNew =
          (_baseSamples / _tDSqMaxSum) * (1 - (_cTMaxSum) / _apexSamples);
    } else {
      _bigCNew = 0;
    }
    print("bigCnew: $_bigCNew");
    print("samples: $_samples");
    return _bigCNew;
  }

  Stream<MeasuredVals> runStream(Stream<RawVals> valStream) async* {
    await for (RawVals vals in valStream) {
      oldThetaSign = theta.sign;
      oldThetaDotSign = thetaDot.sign;

      theta = _setTheta(vals);
      thetaDot = vals.vXY;
      thetaDdot = (-vals.aX * sin(axisOffset) + vals.aY * cos(axisOffset)) /
          deviceRadius;
      if (bigC != null) {
        predHeight = cos(theta) - bigC * vals.vXYSq(); // 1 is low, -1 high
      } else {
        predHeight = null;
      }
      torque = _torque();
      if (isCalibrating) {
        //TODO: Calibrate bigC
        if (_thetaDotSignChange() <= 0) {
          // at apex
          axisOffset = asin(vals.aY / vals.aMagnitude());
          if (vals.aX < 0) {
            axisOffset = pi - axisOffset;
          }
          _cTMaxSum += cos(theta);
          _apexSamples++;
          _samples++;
          // bigC = _bigC();
        } else if (_thetaSignChange() <= 0) {
          // at base
          deviceRadius =
              -(vals.aX * cos(axisOffset) + vals.aY * sin(axisOffset)) /
                  (vals.vXYSq());
          _tDSqMaxSum += vals.vXYSq();
          _baseSamples++;
          _samples++;
          // bigC = _bigC();
        }
      }
      yield MeasuredVals(theta, thetaDot, thetaDdot, predHeight, torque);
    }
  }
}

class RawVals {
  double gX;
  double gY;
  double vXY;
  double aX;
  double aY;

  RawVals(int gXInt, int gYInt, int vXYInt, int aXInt, int aYInt) {
    gX = gXInt / 100;
    gY = gYInt / 100;
    vXY = vXYInt / 900;
    aX = (aXInt - gXInt) / 100;
    aY = (aYInt - gYInt) / 100;
  }

  double gMagnitude() {
    return sqrt(gX * gX + gY * gY);
  }

  double aMagnitude() {
    return sqrt(aX * aX + aY * aY);
  }

  double vXYSq() {
    return vXY * vXY;
  }
}

class MeasuredVals {
  final double theta;
  final double thetaDot;
  final double thetaDdot;
  final double predHeight;
  final double torque;

  const MeasuredVals(
      this.theta, this.thetaDot, this.thetaDdot, this.predHeight, this.torque);
}
