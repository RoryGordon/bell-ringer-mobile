import 'dart:math';

class DataStruct {
  int _swingCount = 0;
  int _samples = 0;

  double _acc = 0;
  double _angle = 0;
  double _vel = 0;

  double _accOld = 0;
  double _angleOld = 0;
  double _velOld = 0;

  double _angleOffset = 0;
  double _cosThetaMax = 0;
  double _thetaDotSq = 0;
  double _constant = 0;
  double _radius = 0;

  int _countSwings() {
    if (angleSignChange() && _angle > 0) {
      _swingCount++;
    }
    return _swingCount;
  }

  double _setAcc(int acc, int grav) {
    _acc = (acc - grav) / 100;
    return _acc;
  }

  double _setAngle(int imuX, int imuY) {
    double angle = asin(imuY / sqrt(imuX * imuX + imuY * imuY));

    if (imuX < 0) {
      if (imuY < 0) {
        angle = -pi - angle;
      } else {
        angle = pi - angle;
      }
    }
    _angle = angle + _angleOffset;
    return _angle;
  }

  double _setVel(int gyr) {
    _vel = gyr / 900;
    return _vel;
  }

  double _updateConstant() {
    double constant = 0;
    constant = 2 * (1 - _cosThetaMax) / _thetaDotSq;
    _constant = (_samples * _constant + constant) / (_samples + 1);
    _samples++;
    return _constant;
  }

  double _updateRadius() {
    _radius = -(_constant * _acc) / sin(_angle);
    return _radius;
  }

  bool accSignChange() {
    if (_acc * _accOld < 0) {
      return true;
    } else {
      return false;
    }
  }

  bool angleSignChange() {
    if (_angle * _angleOld < 0) {
      return true;
    } else {
      return false;
    }
  }

  bool velSignChange() {
    if (_vel * _velOld < 0) {
      return true;
    } else {
      return false;
    }
  }

  int calibrate() {
    if (velSignChange()) {
      _cosThetaMax = cos(_angle);
      if (_thetaDotSq != 0) {
        _updateConstant();
        _updateRadius();
      }
    } else if (angleSignChange()) {
      _thetaDotSq = _vel * _vel;
      if (_samples > 0) {
        _updateConstant();
      }
    }
    return _samples;
  }

  int getSwingCount() {
    return _swingCount;
  }

  int resetAngle() {
    _angleOffset += -_angle;
    _angle = 0;
    _angleOld = 0;
    _swingCount = 0;
    return 0;
  }

  int setVals(List<int> outputList) {
    if (outputList.length == 13) {
      _angleOld = _angle;
      _velOld = _vel;
      _accOld = _acc;

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

      _setAngle(imu[0], imu[1]);
      _setVel(gyr);
      _setAcc(acc, imu[1]);
      _countSwings();
      return 0;
    } else {
      return -1;
    }
  }

  double getAcc() {
    return _acc;
  }

  double getAngle() {
    return _angle;
  }

  double getConstant() {
    if (_constant != null) {
      return _constant;
    } else {
      return -999.0;
    }
  }

  double getCosThetaMax() {
    if (_cosThetaMax != null) {
      return _cosThetaMax;
    } else {
      return 0;
    }
  }

  double getDdot() {
    if (_radius != 0) {
      return _acc / _radius;
    } else {
      return 0;
    }
  }

  double getRadius() {
    return _radius;
  }

  double getThetaDotSq() {
    if (_thetaDotSq != null) {
      return _thetaDotSq;
    } else {
      return 0;
    }
  }

  double getTorque() {
    //WARNING: Not the actual torque
    //    More like acceleration due to torque
    if ((_constant != null) & (_constant != 0) & (_radius != 0)) {
      double predDdot = -sin(_angle) / _constant;
      double ddot = getDdot();
      return ddot - predDdot;
    } else {
      return 0;
    }
  }

  double getVel() {
    return _vel;
  }

  double predAngle() {
    if (_constant != null) {
      double cosTheta = cos(_angle) - 0.5 * _constant * _vel * _vel;
      /*
      if (_vel > 0) {
        return acos(cosTheta);
      } else {
        return -acos(cosTheta);
      }
      */
      return cosTheta;
    } else {
      return -999;
    }
  }

  void unCalibrate() {
    _constant = 0;
    _cosThetaMax = 0;
    _thetaDotSq = 0;
    _samples = 0;
  }
}
