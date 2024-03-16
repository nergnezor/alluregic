#include <flutter/runtime_effect.glsl>

uniform vec2 iResolution;
uniform float iTime;
out vec4 fragColor;

void mainImage(out vec4 O, vec2 u) {
  vec2 U = u + u - iResolution.xy;
  float T = 6.2832, l = length(U) / 30., L = ceil(l) * 6.,
        a = atan(U.x, U.y) - iTime * 2. * (fract(1e4 * sin(L)) - .5);
  O = .6 + .4 * cos(floor(fract(a / T) * L) + vec4(0, 23, 21, 0)) -
      max(0., 9. * max(cos(T * l), cos(a * L)) - 8.);
}

void main() {
  // vec4 fragColor;
  mainImage(fragColor, FlutterFragCoord().xy);
  // fragColor = vec4(0.0, 0.0, 0.2, 1.0);
}
