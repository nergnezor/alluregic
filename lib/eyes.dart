import 'dart:ui';

import 'package:flame/components.dart';
import 'package:shadergame/ball.dart';

class Eye extends Ball {
  static const MaxRadius = 5.0;
  Eye(Vector2? offset) : super(isStatic: true, offset: offset) {
    radius = 2.0;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
  }

  // @override
  // void renderCircle(Canvas canvas, Offset position, double radius) {
  //   // super.render(canvas);
  //   final iResolution = this.height;
  //   shader
  //     ..setFloat(0, time)
  //     ..setFloat(1, radius);

  //   canvas.drawCircle(Offset(0, 0), height, Paint()..shader = shader);
  // }
}
