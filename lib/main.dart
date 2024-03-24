import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:shadergame/eyes.dart';
import 'flipper.dart';

import 'ball.dart';
import 'boundaries.dart';

void main() {
  runApp(const GameWidget.controlled(gameFactory: MouseJointExample.new));
}

class MouseJointExample extends Forge2DGame {
  MouseJointExample()
      : super(world: MouseJointWorld(), gravity: Vector2(0, 80));
}

class MouseJointWorld extends Forge2DWorld
    with DragCallbacks, HasGameReference<Forge2DGame> {
  late final FragmentProgram program;
  late final FragmentShader shader;
  late final FragmentShader faceShader;
  late final FragmentProgram program2;
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
  static double timeFactor = 1;

  var noseOffset = Vector2(1.5, 1);

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

    final noseHoleLeft = Ball(isNoseHole: true, isStatic: true, isLeft: true);
    add(noseHoleLeft);
    final noseHoleRight = Ball(isNoseHole: true, isStatic: true);
    add(noseHoleRight);

    addAll(eyes);

    addAll(flippers);

    game.camera.viewport.add(FpsTextComponent());

    program = await FragmentProgram.fromAsset('shaders/bg.frag');
    shader = program.fragmentShader();
    program2 = await FragmentProgram.fromAsset('shaders/pollen.frag');
    faceShader = program2.fragmentShader();

    final keyboardDetector =
        HardwareKeyboardDetector(onKeyEvent: checkKeyEvent);
    add(keyboardDetector);
    game.camera.follow(camera, verticalOnly: true, snap: false, maxSpeed: 300);

    // await FlameAudio.audioCache.load('megalergik.mp3');
    FlameAudio.bgm.play('megalergik.mp3');
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
    // Draw background gradient
    canvas.drawColor(Color.fromARGB(255, 20, 24, 30), BlendMode.srcOver);
    shader
      ..setFloat(0, time * 0.1)
      ..setFloat(1, game.size.x / 100000)
      ..setFloat(2, game.size.y / 150);
    final canvasRect = canvas.getLocalClipBounds();
    canvas.drawRect(canvasRect, Paint()..shader = shader);
    var pos = Offset(0, -3);
    final offset = sin(time * 0.5) * 0.5;
    pos += Offset(offset, offset);

    // faceShader
    //   ..setFloat(0, time / 10)
    //   ..setFloat(1, 4)
    //   ..setFloat(2, 3);
    canvas.drawCircle(
        pos, 10, Paint()..color = Color.fromARGB(220, 72, 44, 130));
    // pos,
    // 10,
    // Paint()..shader = faceShader);
    super.render(canvas);
  }

  @override
  void update(double dt) {
    time += dt;
    debugText.text = game.world.children.length.toString();
    if (time - lastCreateBallTime > 1.0) {
      if (timeFactor == 0) {
        return;
      }
      lastCreateBallTime = time;
      // Add new if not too many balls
      if (game.world.children.length < 20) {
        add(Ball());
      }
    }

    // End if out of eyes
    final eyes = game.world.children.whereType<Eye>();
    if (eyes.isEmpty && timeFactor > 0) {
      winGame();
    }
    super.update(dt);
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

  void winGame() {
    final style = TextStyle(color: Colors.yellow[300], fontSize: 50);
    final regular = TextPaint(style: style);
    final text = TextComponent(
        text: "You win!",
        // Put text in the middle of the screen
        // position: Vector2(gameSize / 2, game.size.y / 2 - 100),
        position: game.camera.viewport.size / 2 - Vector2(100, 100),
        textRenderer: regular);
    game.camera.viewport.add(text);
    timeFactor = 0;
    time = 0;
    lastCreateBallTime = 0;
    Future.delayed(const Duration(seconds: 10), () {
      game.camera.viewport.remove(text);
      timeFactor = 1;
      reset();
    });
  }

  void reset() {
    final eyes = [
      Eye(Vector2(-eyeDistance, eyeYOffset)),
      Eye(Vector2(eyeDistance, eyeYOffset))
    ];
    addAll(eyes);
  }
}
