shader_type sky;

float hash(vec3 p) {
 p = fract(p * vec3(443.897,441.423,437.195));
 p += dot(p,p.yzx+19.19);
 return fract((p.x+p.y)*p.z);
}

float noise(vec3 p) {
 vec3 i = floor(p), f = fract(p);
 f = f*f*(3.0-2.0*f);
 return mix(
  mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),
  mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}

void sky() {
 vec3 d = normalize(EYEDIR);
 float haze = pow(max(0.0,1.0-abs(d.y-.05)),6.0);
 vec3 c = mix(vec3(.016,.026,.049),vec3(.067,.10,.15),haze);
 float dust = noise(d*6.0)*noise(d*21.0);
 c += vec3(.08,.12,.21)*dust*haze;
 vec3 cell = floor(d*400.0);
 float star = hash(cell);
 c += vec3(.57,.68,.83)*step(.9985,star)*smoothstep(.7,1.0,hash(cell+1.9));
 vec3 center = normalize(vec3(-.50,.43,-.94));
 vec3 right = normalize(cross(vec3(0,1,0),center));
 vec3 up = cross(center,right);
 vec2 xy = vec2(dot(d,right),dot(d,up))/.235;
 float r = length(xy);
 float disk = step(0.0,dot(d,center));
 float rim = exp(-abs(r-1.0)*24.0)*disk;
 c += vec3(.065,.17,.24)*rim;
 if(r<1.0 && disk>0.5) {
  vec3 n = vec3(xy,sqrt(1.0-r*r));
  float light = max(0.0,dot(n,normalize(vec3(.7,.68,.18))));
  float cloud = noise(n*vec3(6.0,29.0,7.0)+.3)*.66+noise(n*45.0)*.34;
  float belts = sin(n.y*24.0+noise(n*9.0)*1.5)*.5+.5;
  vec3 ground = mix(vec3(.075,.145,.21),vec3(.44,.53,.59),smoothstep(.15,.85,cloud*.8+belts*.2));
  c = ground*(.16+light*.79)+vec3(.06,.16,.22)*pow(r,12.0)*(light+.13);
 }
 vec2 rings = vec2(xy.x+xy.y*.26,(xy.y-xy.x*.20)*4.6);
 float ring_r = length(rings);
 if(disk>0.5 && ring_r>1.20 && ring_r<2.25 && (r>1.0 || rings.y<0.0)) {
  float density = (.25+.55*noise(vec3(ring_r*53.0,0,0)))*(1.0-smoothstep(1.98,2.25,ring_r));
  c = mix(c,vec3(.38,.36,.31),density);
 }
 COLOR = c;
}
