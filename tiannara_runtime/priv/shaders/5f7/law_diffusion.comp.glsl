#version 310 es
layout(local_size_x = 16, local_size_y = 16) in;

layout(rgba32f, binding = 0) uniform highp image2D u_laws;
layout(rgba32f, binding = 1) uniform highp image2D u_output;

void main() {
    ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
    
    // Simple diffusion kernel
    vec4 sum = vec4(0.0);
    for(int i = -1; i <= 1; i++) {
        for(int j = -1; j <= 1; j++) {
            sum += imageLoad(u_laws, coord + ivec2(i, j));
        }
    }
    
    imageStore(u_output, coord, sum / 9.0);
}
