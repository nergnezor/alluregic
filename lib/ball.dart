import 'dart:math';
import 'dart:ui';
import 'package:flame/extensions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
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
    final shaderName = isNoseHole ? 'enemy' : 'player';

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
    final bodyDef = BodyDef(
      userData: this,
      position: offset ?? Vector2(Random().nextDouble() * size / 2, -size / 2),
      type: isStatic ? BodyType.static : BodyType.dynamic,
    );

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void renderCircle(Canvas canvas, Offset center, double radius) {
    // print(sin(game.currentTime()));
    shader
      ..setFloat(0, time)
      ..setFloat(1, radius)
      ..setFloat(2, body.linearVelocity.x)
      ..setFloat(3, body.linearVelocity.y)
      ..setFloat(4, life / 100.0);
    ;

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
    time += dt;
    moveNoseHoles();
    pushTowardNoseHoles();
    if (body.position.y > game.camera.visibleWorldRect.height / 2) {
// Add some delay before resetting the ball
      Future.delayed(Duration(milliseconds: 1), () {
        if (isNoseHole) {
          life -= 10;
          reset();
        } else {
          world.remove(this);
        }
      });
    }
    if (life <= 0) {
      body.setActive(false);
    }
    super.update(dt);
  }

  @override
  void beginContact(Object other, Contact contact) {
// Calculate impulse (force) on the ball
    final speeds = [contact.bodyA.linearVelocity, contact.bodyB.linearVelocity];
    final masses = [contact.bodyA.mass, contact.bodyB.mass];
    final force = speeds[0] * masses[0] + speeds[1] * masses[1];
    if (other is Wall) {
      other.paint.color = Colors.red;
      return;
    }

    if (!isNoseHole && other is Ball && other.isNoseHole) {
      const dieImpulseThreshold = 2;
      if (force.length < dieImpulseThreshold) {
        die();
      }
      // grow(lifeDrain / 100);
    }

    // Enemy - Flipper collision
    if (!isNoseHole && other is Flipper) {}
    if (isNoseHole) {
      // print(other);
    }
  }

  void grow(double amount) {
    final shape = body.fixtures.first.shape as CircleShape;
    final scale = 1 + amount;
    shape.radius = shape.radius * scale;
    // if (isFirstBall && radius > PinballDiameter / 2) {
    //   radius = PinballDiameter / 2;
    //   shape.radius = radius;
    // }
    radius = shape.radius;
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

    final amount = pow(sin(time), 2.0);
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
