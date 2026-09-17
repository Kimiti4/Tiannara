#version 310 es
layout(local_size_x = 16, local_size_y = 16) in;

layout(rgba32f, binding = 0) uniform readonly highp image2D u_knowledge;
layout(rgba32f, binding = 1) uniform writeonly highp image2D u_output;

void main() {
    ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
    vec4 knowledge = imageLoad(u_knowledge, coord);
    
    // Compute local semantic entropy based on knowledge density gradient
    float entropy = length(knowledge.rgb) * 0.5; // Simplified
    
    imageStore(u_output, coord, vec4(entropy, entropy, entropy, 1.0));
}
