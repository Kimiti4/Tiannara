#version 310 es
layout(local_size_x = 16, local_size_y = 16) in;

layout(rgba32f, binding = 0) uniform highp image2D u_input;
layout(rgba32f, binding = 1) uniform highp image2D u_output;

uniform float u_mutation_rate;
uniform float u_time;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898,78.233))) * 43758.5453);
}

void main() {
    ivec2 coord = ivec2(gl_GlobalInvocationID.xy);

    vec4 state = imageLoad(u_input, coord);

    float noise = hash(vec2(coord) * u_time);

    if(noise < u_mutation_rate) {
        state.rgb *= 0.95 + noise * 0.1;
    }

    imageStore(u_output, coord, state);
}
