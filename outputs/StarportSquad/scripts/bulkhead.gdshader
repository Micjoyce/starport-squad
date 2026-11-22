shader_type spatial;

uniform vec3 panel_color : source_color = vec3(.29,.38,.43);
uniform vec3 seam_color : source_color = vec3(.09,.13,.17);
varying vec3 world_point;
varying vec3 world_normal;

void vertex() {
 world_point = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
 world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

float hash(vec2 p) {
 return fract(sin(dot(p,vec2(127.1,311.7))) * 43758.5453);
}

void fragment() {
 vec2 p = vec2(abs(world_normal.x)>0.6 ? world_point.z : world_point.x,world_point.y);
 if(abs(world_normal.y)>0.6) { p = world_point.xz; }
 vec2 uv = fract(p / vec2(1.42,1.08));
 vec2 edge = min(uv,1.0-uv);
 float seam = 1.0 - smoothstep(.008,.022,min(edge.x,edge.y));
 float bevel = smoothstep(.018,.033,min(edge.x,edge.y))*(1.0-smoothstep(.033,.052,min(edge.x,edge.y)));
 float bolt = 1.0-smoothstep(.014,.025,length(edge-vec2(.058,.068)));
 float shade = .86+hash(floor(p/vec2(1.42,1.08)))*.22;
 float grain = .94+hash(floor(p*116.0))*.12;
 float grime = smoothstep(.05,.42,uv.y);
 ALBEDO = mix(panel_color*shade*grain*(.80+.20*grime),seam_color,seam) + bevel*.035 + bolt*.08;
 METALLIC = .27;
 ROUGHNESS = .55+seam*.2;
}
