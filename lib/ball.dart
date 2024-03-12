import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:shadergame/main.dart';
import 'boundaries.dart';
import 'flipper.dart';
import 'nose.dart';

class Ball extends BodyComponent with ContactCallbacks {
  late final FragmentProgram _program;
  late final FragmentShader shader;
  static const PinballDiameter = 2.7; // (cm) = 27mm
  static const EnemyBallDiameter = 6.0;
  Vector2? offset;
  double radius = 1;
  final bool isNoseHole;
  // static late final Ball first;
  int life = 100;
  double time = 0;
  Ball({this.isNoseHole = false, Vector2? offset}) {
    radius = isNoseHole ? 1.1 : 1;
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
    final fixtureDef = FixtureDef(shape,
        restitution: isNoseHole ? 0.1 : 0.0,
        friction: 0,
        density: 0,
        isSensor: isNoseHole);

    const size = MouseJointWorld.gameSize;
    final bodyDef = BodyDef(
      userData: this,
      position: offset ?? Vector2(Random().nextDouble() * size / 2, -size / 2),
      type: isNoseHole ? BodyType.static : BodyType.dynamic,
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
    super.update(dt);

    time += dt;
    if (body.position.y > game.camera.visibleWorldRect.height / 2) {
// Add some delay before resetting the ball
      Future.delayed(Duration(milliseconds: 1), () {
        if (isNoseHole) {
          life -= 10;
          // world.remove(lifeText);
          // world.add(lifeText);
          reset();
        } else {
          world.remove(this);
        }
      });
    }
    if (life <= 0) {
      // First spin the ball
      // body.applyAngularImpulse(100);
      body.setActive(false);
      // grow(dt * 10);
    }
    // const growTime = 10.0;
    // final balltypeRadius =
    //     isFirstBall ? PinballDiameter / 2 : EnemyBallDiameter / 2;

    // // Always grow enemies. Grow player if within growTime
    // if (!isFirstBall || radius < balltypeRadius) {
    //   grow(dt / growTime * balltypeRadius);
    // }

    // const explodeRadius = 10.0;
    // if (radius > explodeRadius) {
    //   die();
    // }
  }

  static const explodeForce = 100;
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

    if (other is Nose) {
      print('Nose hit');
      other.paint.color = Colors.red;
      // return;
    }

    if (!isNoseHole && other is Ball && other.isNoseHole) {
      final distance = (other.body.position - body.position).length;
      print('Ball hit. Distance: $distance');
      die();
      return;
      final lifeDrain = 10 * pow(force.length, 1.2) / explodeForce;
      life -= lifeDrain.round();
      // grow(lifeDrain / 100);
    }

    // Enemy - Flipper collision
    if (!isNoseHole && other is Flipper) {
      // final lifeDrain = 10 * force.length / explodeForce;
      // first.life -= max(lifeDrain.round(), 1);
      // life -= lifeDrain.round();
      // grow(lifeDrain / 100);
    }
    if (isNoseHole) {
      // print(other);
    }
  }

  // void grow(double amount) {
  //   final shape = body.fixtures.first.shape as CircleShape;
  //   final scale = 1 + amount;
  //   shape.radius = shape.radius * scale;
  //   if (isFirstBall && radius > PinballDiameter / 2) {
  //     radius = PinballDiameter / 2;
  //     shape.radius = radius;
  //   }
  //   radius = shape.radius;
  // }

  void die() {
    var t;
    if (isNoseHole) {
      t = 'You died!';
      life = 100;
      reset();
    } else {
      t = 'BOOM';
      world.remove(this);
    }

    // Display a message
    final text = TextComponent(
      text: t,
      position: Vector2(0, 0),
      anchor: Anchor.center,
      textRenderer: TextPaint(
          style: TextStyle(
        color: Colors.red,
        fontSize: 2,
      )),
    );

    world.add(text);
    // Remove the text after 2 seconds

    Future.delayed(Duration(milliseconds: 500), () {
      world.remove(text);
    });
  }
}
