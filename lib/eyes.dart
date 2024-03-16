import 'dart:ui';

import 'package:flame/components.dart';
import 'package:shadergame/ball.dart';

class Eye extends Ball {
  // late final FragmentProgram _program;
  // late final FragmentShader shader;
  // double width = 10;
  double height = 2;

  Eye(Vector2? offset) : super(isStatic: true, offset: offset) {
    // height = 5.0;
  }

  @override
  Future<void> onLoad() async {
    // _program = await FragmentProgram.fromAsset('shaders/eyes.frag');
    // shader = _program.fragmentShader();
    super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    shader
        // ..setFloat(0, gameRef.currentTime())
        // ..setFloat(1, width)
        // ..setFloat(2, height);
        ;

    canvas.drawCircle(Offset(0, 0), height, Paint()..shader = shader);
  }
}
