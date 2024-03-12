import 'dart:ui';

import 'package:flame/extensions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:shadergame/ball.dart';

const eyeRadius = 2.0;
const eyeDistance = eyeRadius * 3;
const pupilRadius = eyeRadius / 6;
const irisRadius = pupilRadius * 1.5;

class Nose extends BodyComponent {
  // Two balls for the nose holes
  late Ball leftNose;
  late Ball rightNose;
  Nose() {
    // leftNose = Ball(null, isNoseHole: true);
    // // rightNose = Ball(null, isNoseHole: true);
    // for (var nose in [leftNose, rightNose]) {
    //   nose.radius = 3;
    //   nose.createBody();
    // }
    ;
  }
}
