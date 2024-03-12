// ignore-line
#include <flutter/runtime_effect.glsl>

uniform vec2 iResolution;
uniform float iTime;
uniform float radius;
uniform vec2 speed;
uniform float life;
out vec4 fragColor;

const vec4 backgroundColor = vec4(0.1, 0.1, 0.1, 0.1);
const vec4 holeColor = vec4(0.3, 0.1, 0.0, 0.5);
const vec3 skinColor = vec3(0.9, 0.7, 0.6);

bool isHole(vec2 fragCoord, vec2 noseCenter, vec2 noseSideOffset,
            float noseSideRadius, vec3 skinColor, out vec4 fragColor) {
  // Nose holes
  float holeToSideRatio = 0.5 + 0.3 * pow(sin(iTime), 2.0);
  float holeRadius = noseSideRadius * holeToSideRatio;
  vec2 holeOffsetR = vec2(noseSideOffset.x * holeToSideRatio,
                          noseSideOffset.y / holeToSideRatio);
  vec2 holeOffsetL = vec2(-noseSideOffset.x * holeToSideRatio,
                          noseSideOffset.y / holeToSideRatio);
  if (length(fragCoord - noseCenter - holeOffsetR) < holeRadius ||
      length(fragCoord - noseCenter - holeOffsetL) < holeRadius) {
    fragColor = holeColor;
    return true;
  }
  return false;
}

bool drawEyes(out vec4 fragColor, in vec2 fragCoord) {
  // const float eyeRadius = 0.1;
  // const float eyeDistance = 0.3;
  // const vec2 eyeCenter = vec2(-0.3, 0.3);
  // vec2 eyeCoord = fragCoord - eyeCenter;
  // float eyeDistanceFromCenter = length(eyeCoord);
  // if (eyeDistanceFromCenter < eyeRadius)
  // {
  //     fragColor = vec4(0.8);
  // }
  const float eyeRadius = 2.0;
  const float eyeDistance = eyeRadius * 3;
  const float pupilRadius = eyeRadius / 6;
  const float irisRadius = pupilRadius * 1.5;
  // const float leftEyeX = -5;
  for (int i = 0; i < 2; i++) {
    // vec2 eyeCenter = vec2(-0.3 + i * eyeDistance - i * eyeRadius, 0.3);
    vec2 eyeCenter = vec2(eyeDistance / 2, -5);
    if (i == 1) {
      eyeCenter.x *= -1;
    }

    vec2 eyeCoord = fragCoord - eyeCenter;
    float eyeDistanceFromCenter = length(eyeCoord);
    if (eyeDistanceFromCenter < eyeRadius) {
      if (eyeDistanceFromCenter > eyeRadius - 0.02) {
        fragColor *= 0.3;
        return true;
      }
      if (eyeDistanceFromCenter < pupilRadius) {
        fragColor = vec4(0, 0, 0, 1);
        return true;
      }
      if (eyeDistanceFromCenter < irisRadius) {
        fragColor = vec4(0.9, 0.2, 0.4, 1);
        return true;
      }
      fragColor = vec4(1, 1, 1, 1);
      return true;
    }
  }
  return false;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  float distance = length(fragCoord);
  // Draw a nose using three circles
  vec2 noseCenter = vec2(0.0, 0.0);
  // Nose sides
  float noseSideRadius = radius / 2.0;
  vec2 noseSideOffsetR = vec2(radius, radius / 2.0);
  vec2 noseSideOffsetL = vec2(-radius, radius / 2.0);

  // Nose center
  if (distance < radius) {
    if (isHole(fragCoord, noseCenter, noseSideOffsetL, noseSideRadius,
               skinColor, fragColor)) {
      return;
    }
    fragColor = vec4(skinColor, 1.0);
    return;
  }
  bool isNoseSide =
      length(fragCoord - noseCenter - noseSideOffsetL) < noseSideRadius ||
      length(fragCoord - noseCenter - noseSideOffsetR) < noseSideRadius;
  if (isNoseSide) {
    if (isHole(fragCoord, noseCenter, noseSideOffsetL, noseSideRadius,
               skinColor, fragColor)) {
      return;
    }
    fragColor = vec4(skinColor, 1.0);
    return;
  }

  if (drawEyes(fragColor, fragCoord))
    return;

  fragColor = backgroundColor;

  // vec3 finalColor = mix(stripeColorFinal, fogColor, smoothstep(0.0, 1.0,
  // distance));

  // fragColor = vec4((finalColor * stripeColor + backgroundColor) / m, 1.0);
}

void main() { mainImage(fragColor, FlutterFragCoord().xy); }
