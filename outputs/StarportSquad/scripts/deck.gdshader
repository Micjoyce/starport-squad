shader_type spatial;
render_mode diffuse_burley;

varying vec3 world_point;
void vertex() {
 world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float noise_hash(vec2 p) {
 return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453);
}

void fragment() {
 vec2 p = world_point.xz;
 vec2 tile = floor(p / 2.0);
 vec2 local = abs(fract(p / 2.0) - 0.5);
 float seam = smoothstep(0.478,0.499,max(local.x,local.y));
 float panel = noise_hash(tile);
 float rivet = 1.0 - smoothstep(0.012,0.022,length(local-vec2(0.437,0.437)));
 float grain = noise_hash(floor(p * 105.0));
 float scratches = smoothstep(0.91,0.99,noise_hash(floor(p*vec2(34.0,180.0))));
 vec3 steel = mix(vec3(0.15,0.195,0.235),vec3(0.23,0.29,0.33),panel);
 ALBEDO = mix(steel * (0.94+grain*0.1)+scratches*0.014,vec3(0.052,0.071,0.09),seam) + rivet*0.12;
 METALLIC = 0.38;
 ROUGHNESS = mix(0.42,0.72,panel) + seam*0.08;
}
