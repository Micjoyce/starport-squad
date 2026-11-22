extends RefCounted
const F = preload("res://scripts/factory.gd")

static func dress(world: Node3D) -> void:
 var frame = F.mat(Color("253745"))
 var plate = F.mat(Color("617482"))
 var black = F.mat(Color("19232c"))
 var amber = F.mat(Color("ffc082"),.55)
 var ice = F.mat(Color("a0e3f0"),.4)
 # A large orbital gate visible from the deployment deck.
 for i in range(14):
  var a = PI*float(i)/13
  var point = Vector3(cos(a)*18,1+sin(a)*18,-36)
  var segment = F.box(world,point,Vector3(4.6,1.9,3.4),frame)
  segment.rotation.z = a-PI/2
  var edge = F.box(world,point+Vector3(0,0,1.75),Vector3(3.3,.13,.10),amber)
  edge.rotation.z = a-PI/2
  if i%2==0:
   var fin = F.box(world,point+Vector3(cos(a)*1.1,sin(a)*1.1,0),Vector3(1.1,.75,3.7),plate)
   fin.rotation.z = a-PI/2
 for side in [-1,1]:
  for z in [13,21,29]:
   F.box(world,Vector3(side*5.4,4.9,z),Vector3(.53,8.5,.64),frame)
   F.box(world,Vector3(side*5.4,7.9,z),Vector3(1.3,.42,1.05),plate)
   F.box(world,Vector3(side*5.4,7.65,z+.24),Vector3(.9,.06,.38),ice)
   for y in [1.4,3.0,4.6]:
    F.box(world,Vector3(side*5.08,y,z),Vector3(.075,.34,.48),black)
  for z in range(6,30,3):
   F.box(world,Vector3(side*2.6,.038,z),Vector3(.08,.026,.7),amber)
 for z in [13,21,29]:
  F.box(world,Vector3(0,8.1,z),Vector3(11.4,.68,.74),frame)
  for x in [-4,-2,0,2,4]:
   F.box(world,Vector3(x,7.73,z),Vector3(1.5,.055,.29),ice)
  var pool = OmniLight3D.new()
  pool.light_color = Color("ffcd9b") if z==21 else Color("a3d4fa")
  pool.light_energy = 1.4
  pool.omni_range = 11.0
  world.add_child(pool)
  pool.position = Vector3(0,6.5,z)
 for side in [-1,1]:
  for i in range(6):
   var x = side*(30+i*4.0)
   var z = -42-i*2.0
   var height = 9.0+float((i*7)%11)
   F.box(world,Vector3(x,height*.5,z),Vector3(3.6,height,5.5),frame)
   F.box(world,Vector3(x,height-.2,z),Vector3(4.1,.55,5.9),black)
   for y in range(3,int(height),3):
    F.box(world,Vector3(x,y,z+2.77),Vector3(2.2,.10,.05),amber)
