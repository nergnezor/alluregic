import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:shadergame/eyes.dart';
import 'package:shadergame/main.dart';
import 'boundaries.dart';
import 'flipper.dart';

class Ball extends BodyComponent with ContactCallbacks {
  late final FragmentProgram _program;
  late final FragmentShader shader;
  static const PinballDiameter = 2.7; // (cm) = 27mm
  static const EnemyBallDiameter = 6.0;
  Vector2? offset;
  double radius = 1;
  final bool isNoseHole;
  final bool isStatic;
  final bool isLeft;
  // static late final Ball first;
  int life = 100;
  double time = 0;
  Ball(
      {this.isNoseHole = false,
      this.isLeft = false,
      this.isStatic = false,
      Vector2? offset}) {
    // radius = isNoseHole ? 1.1 : 1;
    // body = createBody();
    if (offset != null) {
      this.offset = offset;
    }
  }

  void reset() {
    world.destroyBody(body);
    body = createBody();
  }

  @override
  Future<void> onLoad() async {
    var shaderName = isNoseHole ? 'nose' : 'pollen';
    if (this is Eye) {
      shaderName = 'eye';
    }

    _program = await FragmentProgram.fromAsset('shaders/$shaderName.frag');
    shader = _program.fragmentShader();

    super.onLoad();
  }

  @override
  Body createBody() {
    final shape = CircleShape();
    shape.radius = radius;
    final fixtureDef = FixtureDef(shape, friction: 1, isSensor: isStatic);

    const size = MouseJointWorld.gameSize;
    var x = size * (Random().nextDouble() - 0.5) / 4;
    var y = -size;

    if (x < 0) {
      x += size / 2;
    } else {
      x -= size / 2;
    }
    final o = Vector2(x, y);
    final bodyDef = BodyDef(
      userData: this,
      position: offset ?? o,
      type: isStatic ? BodyType.static : BodyType.dynamic,
    );

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void renderCircle(Canvas canvas, Offset center, double radius) {
    if (isNoseHole) {
      canvas.drawCircle(
        center,
        radius * 1.4,
        Paint()..color = Color.fromARGB(255, 188, 87, 147),
      );
      canvas.drawCircle(
        center,
        radius * 1.2,
        Paint()..color = Color.fromARGB(255, 64, 0, 147),
      );
      // Draw lines to the nose holes
      final start = -position / 2 + Vector2(0, -2);
      final end = position / 1.0 + Vector2(0, -2);
      canvas.drawLine(
        start.toOffset(),
        end.toOffset(),
        Paint()
          ..color = Color.fromARGB(255, 103, 63, 169)
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round,
      );

      // draw a soft shaped nose half
      // final nosePath = Path()
      //   ..moveTo(start.x, start.y)
      //   ..quadraticBezierTo(start.x, start.y - 1, end.x, end.y)
      //   ..quadraticBezierTo(end.x, end.y + 1, start.x, start.y)
      //   ..quadraticBezierTo(0, 0, 0, 0)
      //   // ..quadraticBezierTo(start.x, start.y + 1, start.x, end.y)
      //   // ..quadraticBezierTo(0, start.y + 1, start.x, end.y)
      //   ..quadraticBezierTo(start.x, start.y - 1, end.x, end.y);

      // Draw nose side spline
      final nosePath = Path()
        ..moveTo(start.x, start.y)
        ..quadraticBezierTo(start.x, start.y, start.x, start.y)
        ..quadraticBezierTo(end.x, end.y, end.x, end.y)
        ..quadraticBezierTo(start.x, end.y, start.x, end.y);

      canvas.drawPath(
        nosePath,
        Paint()
          ..color = Color.fromARGB(255, 63, 98, 163)
          ..style = PaintingStyle.fill,
      );
    }
    // print(sin(game.currentTime()));
    shader
      ..setFloat(0, time)
      ..setFloat(1, radius);

    canvas
      ..drawCircle(
        Offset.zero,
        radius,
        Paint()..shader = shader,
      );
  }

  @override
  @mustCallSuper
  void update(double dt) {
    time += dt * MouseJointWorld.timeFactor;

    moveNoseHoles();
    // Move around eyes and nose holes
    if (isStatic) {
      final t = time * MouseJointWorld.timeFactor * 10;
      if (isNoseHole) {
        body.position.xy += Vector2(sin(t), cos(t)) * 0.5;
      } else {
        body.position.xy += Vector2(sin(t), cos(t)) / 100;
      }
    }

    pushTowardNoseHoles();
    if (body.position.y > game.camera.visibleWorldRect.height / 2) {
      world.remove(this);

// Decrease the size of the largest eye
      final eyes = world.children.whereType<Eye>();
      if (eyes.isEmpty) {
        return;
      }
      final largestEye = eyes.reduce((a, b) => a.radius > b.radius ? a : b);
      if (largestEye.radius > Eye.MinRadius) {
        largestEye.grow(-0.1);
        MouseJointWorld.timeFactor -= 0.1;
      }
    }
    super.update(dt);
  }

  @override
  void beginContact(Object other, Contact contact) {
// Calculate impulse (force) on the ball
  }

  void grow(double amount) {
    final shape = body.fixtures.first.shape as CircleShape;
    final scale = 1 + amount;
    radius = shape.radius * scale;
    shape.radius = shape.radius * scale;
  }

  void die() {
    // Shrink the ball until it disappears
    final shrink = 0.1;
    if (radius <= shrink) {
      if (this.parent != null) {
        this.parent!.remove(this);
      }

      return;
    }
    Future.delayed(Duration(milliseconds: 10), () {
      grow(-shrink);
      die();

      // Grow the eye balls
      final eyes = world.children.whereType<Eye>();
      if (eyes.isEmpty) {
        return;
      }
      final closestEye = eyes.reduce((a, b) =>
          (a.position - body.position).length <
                  (b.position - body.position).length
              ? a
              : b);

      if (closestEye.radius > Eye.MaxRadius) {
        closestEye.die();
        return;
      }
      closestEye.grow(0.005);
      MouseJointWorld.timeFactor += 0.002;
    });
  }

  void pushTowardNoseHoles() {
    if (isNoseHole) {
      return;
    }
    // final noseHoles = world.components.whereType<Ball>().where((ball) => ball.isNoseHole);
    final noseHoles =
        world.children.whereType<Ball>().where((ball) => ball.isNoseHole);
    for (final hole in noseHoles) {
      final direction = hole.body.position - body.position;
      final distance = direction.length;
      if (distance < 0.5) {
        die();
        continue;
      }
      if (distance > 3) {
        continue;
      }
      final force = direction.normalized() * 800 / (distance);
      body.applyForce(force);

      final speedFactor = min(1.0, distance / 2);
      body.linearVelocity *= speedFactor;
    }
  }

  void moveNoseHoles() {
    if (!isNoseHole) {
      return;
    }

    final amount = 2 * pow(sin(time), 2.0) + MouseJointWorld.timeFactor / 100;
    radius = 0.7 + 0.2 * amount;
    final xOffsetDistance = 1.0 + amount * 0.8;
    final yOffset = 2.0 - amount;
    final xOffset = isLeft ? xOffsetDistance : -xOffsetDistance;
    final pos = Vector2(xOffset, yOffset);

// update body
    final shape = body.fixtures.first.shape as CircleShape;
    shape.radius = radius;
    position.xy = pos;
  }
}
