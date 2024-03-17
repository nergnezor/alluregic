import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadergame/eyes.dart';
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
  static const eyeYOffset = -5.0;
  static const eyeDistance = 3.0;
  final eyes = [
    Eye(Vector2(-eyeDistance, eyeYOffset)),
    Eye(Vector2(eyeDistance, eyeYOffset))
  ];

  List<Flipper> flippers = List.generate(2, (index) => Flipper(index));
  List<Flipper> activeFlippers = [];
  PositionComponent camera = PositionComponent();
  TextComponent lifeText =
      TextComponent(text: "100", position: Vector2(30, 20));
  TextComponent debugText =
      TextComponent(text: "debug", position: Vector2(0, 40));


  static const double gameSize = 18;

  @override
  void onGameResize(Vector2 gameSize) {
    // Reset game

    super.onGameResize(gameSize);
    flippers.forEach((flipper) => flipper.reset());
  }

  @override
  Future<void> onLoad() async {
    game.camera.viewfinder.visibleGameSize = Vector2.all(gameSize);
    super.onLoad();
    final boundaries = createBoundaries(game);
    addAll(boundaries);

    final noseHoleLeft = Ball(
        isNoseHole: true,
        isStatic: true,
        isLeft: true,
        offset: Vector2(-1.5, 1));
    add(noseHoleLeft);
    final noseHoleRight =
        Ball(isNoseHole: true, isStatic: true, offset: Vector2(1.5, 1));
    add(noseHoleRight);

    addAll(eyes);

    addAll(flippers);

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
  }

  @override
  void update(double dt) {
    super.update(dt);
    time += dt;
    debugText.text = game.world.children.length.toString();
    if (time - lastCreateBallTime > 1.0) {
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
