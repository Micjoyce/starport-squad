shader_type spatial;
vec3 hue(float h){return clamp(abs(fract(h+vec3(0.0,0.6667,0.3333))*6.0-3.0)-1.0,0.0,1.0);}
void fragment(){
 vec3 c=hue(fract(UV.y*0.75+UV.x*0.2+TIME*0.11));
 ALBEDO=mix(c,vec3(1.0),0.12);
 METALLIC=0.35;
 ROUGHNESS=0.32;
 EMISSION=c*0.25;
}
