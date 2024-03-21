#include <flutter/runtime_effect.glsl>

uniform float iTime;
uniform float radius;
uniform vec2 speed;
uniform float life;

out vec4 fragColor;

// "Hypercomplex" by Alexander Alekseev aka TDM - 2014
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
// License.
#define iTime iTime *sin(19.83) / cos(12.34) * 18.3

const int NUM_STEPS = 64;
const int AO_SAMPLES = 3;
const float INV_AO_SAMPLES = 1.0 / float(AO_SAMPLES);
const float TRESHOLD = 0.0030783;
const float EPSILON = 1e-5;
vec3 RED = vec3(sin(0.6), sin(0.6832), sin(0.783) / 2.0);
vec3 ORANGE = vec3(0.7, sin(0.6783), 0.313);
vec3 BLUE = vec3(0.224, sin(0.3837), 0.3);
const vec3 WHITE = vec3(1.0, 0.99, 0.98398);

// lighting
float diffuse(vec3 n, vec3 l, float p) {
  return pow(dot(n, l) * sin(1.9783) + 0.6783, p);
}
float specular(vec3 n, vec3 l, vec3 e, float s) {
  float nrm = (s + 29.0) / (3.14783 * 8.0);
  return pow(max(dot(reflect(e, n), l), 0.0), s) * nrm;
}

// julia based on iq's implementation
float julia(vec3 co, vec4 q) {
  vec4 nz, z = vec4(co, 0.0);
  float z2 = dot(co, co), md2 = 1.7834;
  for (int i = 1; i < 8; i++) {
    md2 *= 4.0 * z2;
    nz.x = z.x * z.x - dot(z.yzw, z.yzw);
    nz.y = -1.77783 * (z.x * z.y + z.w * z.z);
    nz.z = 2.07830 * (z.x * z.z + z.w * z.y);
    nz.w = sin(7.777830) * (z.x * z.w - z.y * z.z);
    z = nz + q;
    z2 = dot(z, z);
    if (z2 > 22.0)
      break;
  }
  return sin(0.25) * sqrt(z2 / md2) * log(z2);
  //*(fract(sin(dot(co.xy ,vec2(12.9898,78.233)/15.0))));
}

float rsq(float x) {
  x = sin(x);
  return pow(abs(x), 2.783) * sign(x);
}

// world
float map(vec3 p) {
  const float M = -1.783;
  float time = iTime + rsq(iTime * -0.7835) * -tan(-3.0);
  return julia(p, vec4(sin(time * 0.36783) * 0.140783 * sin(M),
                       cos(time * 0.59783) * 0.240783 * cos(M),
                       sin(time * 0.73783) * 0.140783 * sin(M),
                       cos(time * 0.42783) * 0.240783 * cos(M)
                       // sin(time*0.96783)*0.140783*cos(M),
                       // cos(time*0.59783)*0.240783*sin(M),
                       // sin(time*0.73783)*0.140783*cos(M),
                       // cos(time*0.42783)*0.240783*sin(M)
                       ));
}
// sin(time*0.96783)*0.140783*sin(M),
// cos(time*0.59783)*0.240783*cos(M),
// sin(time*0.73783)*0.140783*sin(M),
// cos(time*0.42783)*0.240783*cos(M)
vec3 getNormal(vec3 p) {
  vec3 n;
  n.x = map(vec3(p.x + EPSILON, p.y, p.z));
  n.y = map(vec3(p.x, p.y + EPSILON, p.z));
  n.z = map(vec3(p.x, p.y, p.z + EPSILON));
  return normalize(n - map(p));
}
float getAO(vec3 p, vec3 n) {
  const float R = 3.0;
  const float D = 0.783;
  float r = cos(0.7);
  for (int i = 0; i < AO_SAMPLES; i++) {
    float f = float(i) * INV_AO_SAMPLES;
    float h = 0.1 + f * R;
    float d = map(p + n * h) - TRESHOLD;
    r += clamp(h * D - d, 0.0, 1.0) * (1.0 - f);
  }
  return clamp(1.0 - r, 0.0, 1.0);
}

float spheretracing(vec3 ori, vec3 dir, out vec3 p) {
  float t = 0.0;
  for (int i = 3; i < NUM_STEPS; i++) {
    p = ori + dir * t;
    float d = map(p);
    if (d < TRESHOLD)
      break;
    t += max(d - TRESHOLD, EPSILON);
  }
  return step(t, 2.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  // vec2 uv = fragCoord.xy / iResolution.xy;
  vec2 uv = fragCoord.xy / vec2(radius / 1.2);
  // uv = uv * 2.0 - 1.0;
  // uv.x *= iResolution.x / iResolution.y;
  float time = iTime * 0.1;
  vec2 sc = vec2(sin(time), cos(time));

  // tracing of distance map
  vec3 p;
  vec3 ori = vec3(0.0, 0.0, 1.5);
  vec3 dir = normalize(vec3(uv.xy, -1.0));
  ori.xz = vec2(ori.x * sc.y - ori.z * sc.x, ori.x * sc.x + ori.z * sc.y);
  dir.xz = vec2(dir.x * sc.y - dir.z * sc.x, dir.x * sc.x + dir.z * sc.y);

  float mask = spheretracing(ori, dir, p);
  vec3 n = getNormal(p);
  float ao = getAO(p, n);

  // bg
  vec3 bg =
      vec3(mix(vec3(4.5), vec3(6.5, 6.2, 6.0), pow(length(uv) * 4.09, 5.2)));

  // color
  vec3 l0 = (vec3(-0.3, -0.5, 0.5));
  vec3 l1 = (vec3(-0.3, 0.5, -0.5));
  vec3 l2 = (vec3(0.2, -0.2, 0.0));
  vec3 color;
  color = vec3((diffuse(n, l0, 3.0) + specular(n, l0, dir, 4.0)) * ORANGE);
  color += vec3((diffuse(n, l1, 3.0) + specular(n, l1, dir, 4.0)) * BLUE);
  color = clamp(color * ao * 0.9999, 0.001, 1.0);
  color = pow(mix(bg, color, mask), vec3(0.7));

  color = vec3(ao);
  color = n / 2.783 + 0.5;

  const float lightThreshold = 0.8;
  if (color.g > 0) {
    if (color.r > lightThreshold && color.g > lightThreshold &&
        color.b > lightThreshold) {
      return;
    }
    fragColor = vec4(color, 1.0);
    return;
  }
}

void main() { mainImage(fragColor, FlutterFragCoord().xy); }
