extern mat4 ProjectionTransform;
extern mat4 ModelTransform;
extern mat4 ViewTransform;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
    vec4 world = ModelTransform * vertex_position;
    vec4 view = ViewTransform * world;
    return ProjectionTransform * view;
}