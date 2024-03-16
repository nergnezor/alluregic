import 'dart:math';
// import 'dart:nativewrappers/_internal/vm/lib/core_patch.dart';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
// import 'package:flame/experimental.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flame/text.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadergame/nose.dart';
import 'flipper.dart';

import 'ball.dart';
import 'boundaries.dart';

void main() {
  runApp(const GameWidget.controlled(gameFactory: MouseJointExample.new));
}

class MouseJointExample extends Forge2DGame {
  MouseJointExample()
      : super(world: MouseJointWorld(), gravity: Vector2(0, 60));
}

class MouseJointWorld extends Forge2DWorld
    with DragCallbacks, HasGameReference<Forge2DGame> {
  late final FragmentProgram program;
  late final FragmentShader shader;
  double time = 0;
  double lastCreateBallTime = 0;
  double noseRadius = 2;
  Ball? ball;
  final Nose nose = Nose();

  List<Flipper> flippers = List.generate(2, (index) => Flipper(index));
  List<Flipper> activeFlippers = [];
  PositionComponent camera = PositionComponent();
  TextComponent lifeText =
      TextComponent(text: "100", position: Vector2(30, 20));
  TextComponent debugText =
      TextComponent(text: "debug", position: Vector2(0, 40));

  Shape get noseShape => CircleShape();

  static const double gameSize = 18;

  @override
  void onGameResize(Vector2 gameSize) {
    // Reset game

    super.onGameResize(gameSize);
    flippers.forEach((flipper) => flipper.reset());
  }

  @override
  Future<void> onLoad() async {
    // ..setFloat(0, time)
    game.camera.viewfinder.visibleGameSize = Vector2.all(gameSize);
    super.onLoad();
    final boundaries = createBoundaries(game);
    addAll(boundaries);

    final noseHoleLeft =
        Ball(isNoseHole: true, isLeft: true, offset: Vector2(-1.5, 1));
    add(noseHoleLeft);
    final noseHoleRight = Ball(isNoseHole: true, offset: Vector2(1.5, 1));
    add(noseHoleRight);

    // add(nose);
    addAll(flippers);

    // final noseComponent = NoseComponent(Vector2(5, 5), 10 * noseRadius);
    // add(noseComponent);
    // final nose = Nose(Vector2(5, 5), Vector2(5, 5), strokeWidth: 10 * noseRadius);

    game.camera.viewport.add(FpsTextComponent());
    final style = TextStyle(color: Colors.red, fontSize: 24);
    final regular = TextPaint(style: style);

    game.camera.viewport.add(TextComponent(
        text: "💛", position: Vector2(0, 20), textRenderer: regular));
    game.camera.viewport.add(lifeText);
    game.camera.viewport.add(debugText);
    program = await FragmentProgram.fromAsset('shaders/bg.frag');
    shader = program.fragmentShader();

    final keyboardDetector =
        HardwareKeyboardDetector(onKeyEvent: checkKeyEvent);
    add(keyboardDetector);
    game.camera.follow(camera, verticalOnly: true, snap: false, maxSpeed: 300);
  }

  @override
  void onDragStart(DragStartEvent info) {
    super.onDragStart(info);

    // Choose flipper by side of the screen touched
    final left = info.localPosition.x < 0;
    final flipper = flippers[left ? 0 : 1];
    flipper.activate();
    activeFlippers.add(flipper);
  }

  @override
  void onDragUpdate(DragUpdateEvent info) {}

  @override
  void onDragEnd(DragEndEvent info) {
    super.onDragEnd(info);
    if (activeFlippers.length == 2) {
      final id = info.pointerId % 2;
      activeFlippers[id].returnFlipper();
      activeFlippers.removeAt(id);
      return;
    }
    activeFlippers.first.returnFlipper();
    activeFlippers.clear();
  }

  @override
  void render(Canvas canvas) {
    final canvasSize = game.size;
    var rect = Rect.fromLTWH(
        -canvasSize.x, -canvasSize.y, canvasSize.x * 2, canvasSize.y * 2);

    if (rect.hasNaN) {
      rect = game.camera.visibleWorldRect;
    }

    shader
      ..setFloat(0, rect.width)
      ..setFloat(1, rect.height)
      ..setFloat(2, time)
      ..setFloat(3, noseRadius);

    canvas.drawRect(rect, Paint()..shader = shader);
    super.render(canvas);
    // Draw a nose with the help of circles
    // final nose = Paint()
    //   ..color = Colors.white
    //   ..style = PaintingStyle.stroke;
    // canvas.drawCircle(Offset(0, 0), noseRadius, nose);
    // canvas.drawCircle(Offset(noseRadius, noseRadius / 2), noseRadius / 2, nose);
    // canvas.drawCircle(
    //     Offset(-noseRadius, noseRadius / 2), noseRadius / 2, nose);
  }

  @override
  void update(double dt) {
    super.update(dt);
    time += dt;
    debugText.text = game.world.children.length.toString();
    if (time - lastCreateBallTime > 2.0) {
      lastCreateBallTime = time;
      // Add new if not too many balls
      if (game.world.children.length < 10) {
        add(Ball());
      }
    }
    if (ball == null) {
      lifeText.text = "null";
      return;
    }
    lifeText.text = ball!.life.toString();

// // Move the camera up if the ball is at the top of the screen
//     final screenYOffset =
//         -ball.body.position.y - game.camera.visibleWorldRect.height / 2;

//     if (screenYOffset > 0) {
//       camera.y -= screenYOffset * 2;
//       camera.y = max(camera.y,
//           ball.body.position.y + game.camera.visibleWorldRect.height / 2);
//     } else if (camera.y < 0) {
//       camera.y = 0;
//     }
  }

  void checkKeyEvent(KeyEvent event) {
    Flipper? flipper;
    // Check left/right arrow keys
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      flipper = flippers[0];
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      flipper = flippers[1];
    }
    if (flipper == null) {
      return;
    }
    if (event is KeyDownEvent) {
      flipper.activate();
    } else if (event is KeyUpEvent) {
      flipper.returnFlipper();
    }
  }
}
