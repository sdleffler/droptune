uniform mat4 MVPTransform;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
    return MVPTransform * vertex_position;
}