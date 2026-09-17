#version 310 es
layout(local_size_x = 16, local_size_y = 16) in;

layout(rgba32f, binding = 0) uniform readonly highp image2D u_pressure;
layout(rgba32f, binding = 1) uniform writeonly highp image2D u_output;

void main() {
    ivec2 coord = ivec2(gl_GlobalInvocationID.xy);

    vec4 p = imageLoad(u_pressure, coord);

    float pressure = length(p.rgb);

    vec3 color =
        mix(vec3(0.0,0.0,1.0),
            vec3(1.0,0.0,0.0),
            pressure);

    imageStore(u_output, coord, vec4(color, 1.0));
}
