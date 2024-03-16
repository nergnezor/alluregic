#include <flutter/runtime_effect.glsl>

uniform float time;
uniform float radius;
uniform vec2 speed;
uniform float life;
out vec4 fragColor;

const vec4 holeColor = vec4(0,0,0,1);

vec4 calculateColor(float center_distance, float radius, float time)
{
  return holeColor;
}

void main()
{
  float center_distance = length(FlutterFragCoord().xy) / radius;
  float velocity = length(speed);
  fragColor = calculateColor(center_distance, radius, time);
}
