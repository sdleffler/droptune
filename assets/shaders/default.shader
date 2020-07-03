extern mat4 ModelMatrix;
extern mat4 ViewMatrix;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
    vec4 world = ModelMatrix * vertex_position;
    vec4 view = ViewMatrix * world;
    return ProjectionMatrix * view;
}