extends RefCounted
const F = preload("res://scripts/factory.gd")
const Gear = preload("res://scripts/gear.gd")

static func make_body(parent: Node3D, armor: Material, trousers: Material, kind: int, tiers: Array, coat_enabled: bool, legs: bool = true, models: Array = [0,1], shorts: bool = false, helmet_index: int = 0) -> Node3D:
 var root = Node3D.new()
 parent.add_child(root)
 var dark = F.mat(Color("1b3040"))
 var armor_parts: Array = []
 armor_parts.append(F.box(root,Vector3(0,1.22,0),Vector3(.66,.61,.38),armor))
 armor_parts.append(F.box(root,Vector3(0,1.74,0),Vector3(.46,.38,.42),armor))
 var face = F.face(root,Vector3(0,1.74,-.23))
 root.set_meta("face",face)
 if helmet_index>0:
  var shell_color = [Color.WHITE,Color("718895"),Color("688791"),Color("e8bd53")][helmet_index]
  var shell = F.mat(shell_color)
  shell.metallic = .62 if helmet_index==3 else .32
  shell.roughness = .37
  var dome = F.sphere(face,Vector3(0,.092,.217),.273,shell)
  dome.scale = Vector3(1.02,.71,.93)
  F.box(face,Vector3(0,.095,.02),Vector3(.39,.063,.092),shell)
  for side in [-1,1]:
   F.box(face,Vector3(side*.232,-.012,.18),Vector3(.075,.178,.16),shell)
 for side in [-1,1]:
  armor_parts.append(F.box(root,Vector3(side*.43,1.15,-.07),Vector3(.23,.47,.24),armor))
  F.box(root,Vector3(side*.43,.94,-.15),Vector3(.20,.17,.24),dark)
  if legs:
   F.box(root,Vector3(side*.18,.68 if shorts else .62,-.02),Vector3(.24,.24 if shorts else .44,.27),trousers)
   F.box(root,Vector3(side*.18,.27,-.04),Vector3(.21,.36,.23),F.mat(Color("a48368")) if shorts else trousers)
   F.box(root,Vector3(side*.18,.07,-.13),Vector3(.25,.13,.39),dark)
 F.box(root,Vector3(0,1.23,.31),Vector3(.49,.58,.25),dark)
 var coat = make_coat(root)
 coat.visible = coat_enabled
 var guns: Array = []
 for i in range(2):
  var gun = Gear.make_weapon(root,models[i],tiers[i])
  gun.position = Vector3(.37,1.05,-.28)
  gun.scale *= .85
  gun.visible = kind==i
  guns.append(gun)
 root.set_meta("armor_parts",armor_parts)
 root.set_meta("guns",guns)
 var knife = Gear.make_knife(root)
 knife.position = Vector3(.46,1.05,-.4)
 knife.visible = false
 root.set_meta("knife",knife)
 root.set_meta("coat",coat)
 return root

static func make_coat(parent: Node3D) -> Node3D:
 var coat = Node3D.new()
 parent.add_child(coat)
 var fabric = F.mat(Color("163741"))
 var trim = F.mat(Color("5be5c2"),.45)
 F.box(coat,Vector3(0,.94,.25),Vector3(.77,1.12,.09),fabric)
 for side in [-1,1]:
  F.box(coat,Vector3(side*.35,.93,.025),Vector3(.09,1.10,.49),fabric)
  F.box(coat,Vector3(side*.23,1.26,-.245),Vector3(.20,.57,.07),fabric)
  F.box(coat,Vector3(side*.32,1.04,-.27),Vector3(.035,.90,.025),trim)
  F.box(coat,Vector3(side*.44,1.17,-.075),Vector3(.25,.51,.25),fabric)
 F.box(coat,Vector3(-.20,1.38,-.29),Vector3(.12,.035,.025),trim)
 F.box(coat,Vector3(-.20,1.38,-.29),Vector3(.035,.12,.026),trim)
 return coat
