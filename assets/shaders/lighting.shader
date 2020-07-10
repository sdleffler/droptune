uniform vec3 LightPos;
uniform float LightRange[2];
uniform float LightExponent;
uniform float LightIlluminance;

uniform sampler2D PositionTex;

uniform mat4 MVPTransform;

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position) {
    return MVPTransform * vertex_position;
}
#endif

#ifdef PIXEL
vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    // retrieve data from G-buffer
    vec3 FragPos = Texel(PositionTex, tc).rgb;
    vec3 Diffuse = Texel(tex, tc).rgb;
    
    float dist = distance(LightPos, FragPos);
    float frac = (clamp(dist, LightRange[0], LightRange[1]) -
        LightRange[0]) / (LightRange[1] - LightRange[0]);
    float coeff = pow(2 / (1 + frac) - 1, LightExponent) *
        normalize(LightPos - FragPos).z * LightIlluminance;
    
    return vec4(Diffuse * color.xyz * coeff, 1.0);
}
#endif