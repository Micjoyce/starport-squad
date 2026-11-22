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
   F.box(world,Vector3(side*5.4,5.4,z),Vector3(.53,10.3,.64),frame)
   F.box(world,Vector3(side*5.4,10.33,z),Vector3(1.3,.42,1.05),plate)
   F.box(world,Vector3(side*5.4,10.09,z+.24),Vector3(.9,.06,.38),ice)
   for y in [1.4,3.0,4.6]:
    F.box(world,Vector3(side*5.08,y,z),Vector3(.075,.34,.48),black)
  for z in range(6,30,3):
   F.box(world,Vector3(side*2.6,.038,z),Vector3(.08,.026,.7),amber)
 for z in [13,21,29]:
  F.box(world,Vector3(0,10.55,z),Vector3(11.4,.68,.74),frame)
  for x in [-4,-2,0,2,4]:
   F.box(world,Vector3(x,10.17,z),Vector3(1.5,.055,.29),ice)
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


static func bulkhead(color: Color) -> ShaderMaterial:
 var material = ShaderMaterial.new()
 material.shader = preload("res://scripts/bulkhead.gdshader")
 material.set_shader_parameter("panel_color",Vector3(color.r,color.g,color.b))
 return material

static func campaign_palette(game: Node3D) -> void:
 var blue = bulkhead(Color("415764"))
 var red = bulkhead(Color("61443d"))
 for wall in game.command.walls:
  wall.material_override = blue
  wall.scale.y = 1
 for wall in game.command.enemy_walls:
  wall.material_override = red
 game.command.crown.hide()
 game.command.label.hide()
 game.command.enemy_core.rotation = Vector3.ZERO
 game.command.home_core.hide()
 if is_instance_valid(game.pad): game.pad.hide()
 for node in game.world.find_children("*","Label3D",true,false):
  node.hide()


static func finish_weapon(weapon: Node3D, scoped: bool) -> void:
 var grip = F.mat(Color("273641"))
 var titanium = F.mat(Color("81949b"))
 var amber = F.mat(Color("f5ab6c"),.18)
 var receiver = F.box(weapon,Vector3(.069,.027,-.035),Vector3(.019,.084,.36),grip)
 receiver.rotation.z = -.2
 F.box(weapon,Vector3(.081,.04,-.035),Vector3(.009,.016,.21),titanium)
 F.box(weapon,Vector3(.083,.021,.093),Vector3(.011,.013,.064),amber)
 for i in range(6):
  var z = -.16-i*.046
  for side in [-1,1]:
   F.box(weapon,Vector3(side*.065,.026,z),Vector3(.02,.024,.018),titanium)
 if not scoped:
  var shroud = F.cylinder(weapon,Vector3(0,.122,-.14),.039,.16,grip,12)
  shroud.rotation.x = PI/2
  var glass = F.cylinder(weapon,Vector3(0,.122,-.055),.025,.009,amber,12)
  glass.rotation.x = PI/2
 F.batch_meshes(weapon)


static func field_helmet(model: Node3D, shell: Material, inset: Material, indicator: Material) -> MeshInstance3D:
 var dome = F.sphere(model,Vector3(0,1.67,0),.26,shell)
 dome.scale = Vector3(1,.94,.92)
 F.box(model,Vector3(0,1.53,-.153),Vector3(.33,.115,.18),inset)
 F.box(model,Vector3(0,1.69,-.211),Vector3(.35,.11,.085),inset)
 for side in [-1,1]:
  var hinge = F.cylinder(model,Vector3(side*.248,1.66,.015),.081,.045,inset,12)
  hinge.rotation.z = PI/2
  F.box(model,Vector3(side*.34,1.34,-.022),Vector3(.18,.16,.34),shell).rotation.z = -side*.27
  F.box(model,Vector3(side*.225,.53,-.118),Vector3(.15,.17,.09),shell)
  F.box(model,Vector3(side*.11,.87,-.22),Vector3(.12,.15,.12),inset)
 F.box(model,Vector3(0,1.22,.23),Vector3(.43,.47,.19),inset)
 F.box(model,Vector3(.16,1.27,.338),Vector3(.044,.24,.012),indicator)
 return F.box(model,Vector3(0,1.70,-.26),Vector3(.28,.027,.013),indicator)
