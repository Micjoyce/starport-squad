shader_type spatial;
render_mode diffuse_burley;
void fragment(){
 float sheen=0.5+0.5*sin(UV.y*16.0+TIME*1.6+UV.x*8.0);
 vec3 green=mix(vec3(0.015,0.22,0.045),vec3(0.12,0.95,0.36),sheen);
 ALBEDO=green;
 METALLIC=0.35;
 ROUGHNESS=0.28;
 EMISSION=green*0.22;
}
