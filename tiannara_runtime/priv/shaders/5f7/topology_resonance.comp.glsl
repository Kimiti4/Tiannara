#version 310 es
layout(local_size_x = 16, local_size_y = 16) in;

layout(rgba32f, binding = 0) uniform readonly highp image2D u_manifold;
layout(rgba32f, binding = 1) uniform writeonly highp image2D u_output;

uniform float u_resonance_freq;

void main() {
    ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
    vec4 manifold = imageLoad(u_manifold, coord);
    
    // Calculate resonance based on manifold frequency alignment
    float resonance = sin(manifold.r * u_resonance_freq);
    
    imageStore(u_output, coord, vec4(resonance, resonance, resonance, 1.0));
}
