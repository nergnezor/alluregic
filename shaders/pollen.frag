#include <flutter/runtime_effect.glsl>

uniform float iTime;
uniform float radius;
uniform vec2 speed;
uniform float life;
out vec4 fragColor;

// https://www.shadertoy.com/view/Md33zB
// 3D simplex noise from: https://www.shadertoy.com/view/XsX3zB
const float F3 = 0.3333333;
const float G3 = 0.1666667;

vec3 random3(vec3 c) {
  float j = 4096.0 * sin(dot(c, vec3(17.0, 59.4, 15.0)));
  vec3 r;
  r.z = fract(512.0 * j);
  j *= .125;
  r.x = fract(512.0 * j);
  j *= .125;
  r.y = fract(512.0 * j);
  return r - 0.5;
}

float simplex3d(vec3 p) {
  vec3 s = floor(p + dot(p, vec3(F3)));
  vec3 x = p - s + dot(s, vec3(G3));

  vec3 e = step(vec3(0.0), x - x.yzx);
  vec3 i1 = e * (1.0 - e.zxy);
  vec3 i2 = 1.0 - e.zxy * (1.0 - e);

  vec3 x1 = x - i1 + G3;
  vec3 x2 = x - i2 + 2.0 * G3;
  vec3 x3 = x - 1.0 + 3.0 * G3;

  vec4 w, d;

  w.x = dot(x, x);
  w.y = dot(x1, x1);
  w.z = dot(x2, x2);
  w.w = dot(x3, x3);

  w = max(0.6 - w, 0.0);

  d.x = dot(random3(s), x);
  d.y = dot(random3(s + i1), x1);
  d.z = dot(random3(s + i2), x2);
  d.w = dot(random3(s + 1.0), x3);

  w *= w;
  w *= w;
  d *= w;

  return dot(d, vec4(52.0));
}

float fbm(vec3 p) {
  float f = 0.0;
  float frequency = 1.0;
  float amplitude = 0.5;
  for (int i = 0; i < 4; i++) {
    f += simplex3d(p * frequency) * amplitude;
    amplitude *= 0.5;
    frequency *= 2.0 + float(i) / 100.0;
  }
  return min(f, 1.0);
}

float random(in vec2 st) {
  return fract(sin(dot(st.xy, vec2(12.9798, 78.323))) * 43858.5563313);
}

// -----------------------------------------------------------------------------

// Recreating the effect from After Effects
vec2 rectToPolar(vec2 p, vec2 ms) {
  p -= ms / 2.0;
  const float PI = 3.1415926534;
  float r = length(p);
  float a = ((atan(p.y, p.x) / PI) * 0.5 + 0.5) * ms.x;
  return vec2(a, r);
}

// A line as mask, with 'f' as feather
float line(float v, float from, float to, float f) {
  float d = max(from - v, v - to);
  return 1.0 - smoothstep(0.0, f, d);
}

// -----------------------------------------------------------------------------

float effect(vec2 p, float o) {

  p *= 2.0;

  // float f1 = fbm(vec3(p * vec2(13.0, 1.0) + 100.0 + vec2(0.0, o), iTime *
  // .005) ) * 0.5;
  float f1 = simplex3d(vec3(p * vec2(1.0, 5.0), iTime * 0.05)) * 0.5 + 0.5;

  float e = fbm(vec3(p * vec2(15.0, 1.0) + vec2(f1 * 0.85, o), iTime * .005));

  e = abs(e) * sqrt(p.y / 5.0);

  float c2 = simplex3d(vec3(p * vec2(6.0, 2.0), iTime * 0.05));

  c2 = (c2 * 0.5) + 0.5;
  c2 *= 0.5; // sqrt(p.y / 5.0);

  e += c2;

  return e * 0.5;
}

// ShockWave technique
float sw(vec2 p, vec2 ms) {

  p = rectToPolar(p, ms);

  // Offset it on the x
  // p.x = mod(p.x + 0.5, ms.x);

  // Create the seem mask at that offset
  const float b = 0.5;
  const float d = 0.04;
  float seem = line(p.x, -1.0, d, b) + line(p.x, ms.x - d, ms.x + 1.0, b);
  seem = min(seem, 1.0);

  float s1 = effect(p, 0.0);

  // Create another noise to fade to, but the seem has the be at a different
  // position
  p.x = mod(p.x + 0.6, ms.x);
  float s2 = effect(p, -1020.0);

  // Blend them together
  float s = s1;
  s = mix(s1, s2, seem);

  // float m = line(p.y, -0.1, 0.2 + s * 0.9, 0.2);

  float perc = radius * 2 + sin(iTime * 10) / 20;
  // float perc = radius;

  float f1 = perc * 1.8;
  float f2 = perc * 0.5;

  float m = line(p.y, -0.1, f1 + s * f2, 0.2);

  return smoothstep(0.31, 0.6, m);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  fragCoord.x += 0.13;
  fragCoord.y += 0.12;
  vec2 p = fragCoord.xy / vec2(radius / 4, radius / 4);

  float m = 1;
  // iResolution.x / iResolution.y;
  vec2 ms = vec2(m, 1.0);

  float c = 0.0;

  float s = sw(p, ms);
  c += s;

  float t = random(p * 4.0);

  float shade = fbm(vec3(p * 3.0, 100 * iTime * 0.1)) * 0.5 + 0.5;

  shade = sqrt(pow(shade * 0.8, 5.5));

  vec3 pic =
      vec3(shade); // * texture(iChannel0, fragCoord.xy / iResolution.xy).rgb;
  vec3 col = mix(vec3(0.95, 0.96, 0.8), pic, c);

  // Some grain
  col -= (1.0 - s) * t * 0.04;

  // return if pixel is light
  if (col.r + col.g + col.b > 1) {
    return;
  }

  // colorize light green
  col = mix(vec3(0.1, 0.6, 0.1), vec3(0.5, 1, 0.8), col.r + col.g + col.b);

  fragColor = vec4(col, 1.0);
}

void main() { mainImage(fragColor, FlutterFragCoord().xy); }
