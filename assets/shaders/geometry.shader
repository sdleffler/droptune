uniform mat4 ModelTransform;
uniform mat4 MVPTransform;

uniform sampler2D MainTex;

varying vec3 FragPos;

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position) {
    FragPos = (ModelTransform * vertex_position).xyz;
    return MVPTransform * vertex_position;
}
#endif

#ifdef PIXEL
void effect() {
    vec4 diffuse = Texel(MainTex, VaryingTexCoord.xy);

    if (diffuse.a == 0) {
        discard;
    }

    love_Canvases[0] = vec4(FragPos, 1); // position
    love_Canvases[1] = diffuse; // diffuse
}
#endif