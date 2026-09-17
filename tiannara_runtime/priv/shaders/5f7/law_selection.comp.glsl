#version 310 es
layout(local_size_x = 16, local_size_y = 16) in;

layout(rgba32f, binding = 0) uniform readonly highp image2D u_fitness;
layout(rgba32f, binding = 1) uniform writeonly highp image2D u_output;

uniform float u_threshold;

void main() {
    ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
    vec4 fitness = imageLoad(u_fitness, coord);
    
    // Select laws based on fitness threshold
    float selected = (fitness.r > u_threshold) ? 1.0 : 0.0;
    
    imageStore(u_output, coord, vec4(selected, selected, selected, 1.0));
}
