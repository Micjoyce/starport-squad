from pathlib import Path
p=Path('outputs/StarportSquad')
(p/'project.godot').write_text('''; Starport Squad — Godot 4.5
config_version=5
[application]
config/name="星港小队 · STARPORT SQUAD"
run/main_scene="res://main.tscn"
config/features=PackedStringArray("4.5", "GL Compatibility")
config/icon="res://assets/icon.svg"
[display]
window/size/viewport_width=1440
window/size/viewport_height=900
window/size/window_width_override=1280
window/size/window_height_override=800
window/stretch/mode="canvas_items"
window/size/resizable=true
[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
textures/default_filters/use_nearest_mipmap_filter=false
environment/defaults/default_clear_color=Color(0.012,0.021,0.045,1)
[physics]
common/physics_ticks_per_second=60
[audio]
default_bus_layout="res://default_bus_layout.tres"
''')
(p/'main.tscn').write_text('''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/game.gd" id="1"]
[node name="StarportSquad" type="Node3D"]
script = ExtResource("1")
''')
(p/'default_bus_layout.tres').write_text('''[gd_resource type="AudioBusLayout" format=3]
[resource]
bus/0/name = &"Master"
bus/0/volume_db = -3.0
bus/1/name = &"Music"
bus/1/send = &"Master"
bus/1/volume_db = -12.0
bus/2/name = &"SFX"
bus/2/send = &"Master"
bus/2/volume_db = -5.0
''')
(p/'assets/icon.svg').write_text('''<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256"><rect width="256" height="256" rx="52" fill="#0d1d32"/><path d="M128 24 218 76v104l-90 52-90-52V76Z" fill="none" stroke="#5fe8dd" stroke-width="8"/><path d="m142 55-55 86h37l-12 60 58-94h-38Z" fill="#ffad55"/></svg>''')
(p/'scripts/space.gdshader').write_text('''shader_type sky;
float hash(vec3 p) {p=fract(p*vec3(443.897,441.423,437.195)); p+=dot(p,p.yzx+19.19);return fract((p.x+p.y)*p.z);}
void sky(){
 vec3 d=normalize(EYEDIR);
 float haze=pow(max(0.0,1.0-abs(d.y+0.13)),8.0);
 vec3 c=mix(vec3(0.006,0.01,0.026),vec3(0.04,0.085,0.15),haze);
 vec3 cell=floor(d*550.0);
 float h=hash(cell); float stars=step(0.998,h);
 c+=vec3(0.6,0.78,1.0)*stars*(0.4+0.6*hash(cell+2.0));
 vec3 center=normalize(vec3(-0.6,0.30,-0.9));
 float dist=length(d-center);
 if(dist<0.26){
 float x=dist/0.26; float shade=sqrt(max(0.,1.-x*x));
 float bands=sin(d.y*150.0+sin(d.x*54.0)*0.6)*0.5+0.5;
 c=mix(vec3(0.08,0.22,0.34),vec3(0.25,0.62,0.70),bands)*(.18+.82*shade);
 c+=vec3(0.2,0.65,0.8)*pow(x,18.)*.5;
 }
 float ring=abs((d.y-center.y)+(d.x-center.x)*0.25);
 if(dist>0.285 && dist<0.46 && ring<0.016){c=mix(c,vec3(.30,.46,.54),0.65);}
 COLOR=c;
}
''')
