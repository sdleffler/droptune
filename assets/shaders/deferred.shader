uniform mat4 MVPTransform;

uniform float Exposure;

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position) {
    return MVPTransform * vertex_position;
}
#endif

#ifdef PIXEL
vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    const float gamma = 2.2;
    vec3 hdrColor = Texel(tex, tc).rgb;
  
    // exposure tone mapping
    vec3 mapped = vec3(1.0) - exp(-hdrColor * Exposure);
    // gamma correction
    mapped = pow(mapped, vec3(1.0 / gamma));
  
    return vec4(mapped, 1.0);
}
#endif