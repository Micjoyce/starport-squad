extends RefCounted
const F = preload("res://scripts/factory.gd")
const Gear = preload("res://scripts/gear.gd")

static func make_body(parent: Node3D, armor: Material, trousers: Material, kind: int, tiers: Array, coat_enabled: bool, legs: bool = true, models: Array = [0,1], shorts: bool = false) -> Node3D:
 var root = Node3D.new()
 parent.add_child(root)
 var dark = F.mat(Color("1b3040"))
 var armor_parts: Array = []
 armor_parts.append(F.box(root,Vector3(0,1.22,0),Vector3(.66,.61,.38),armor))
 armor_parts.append(F.box(root,Vector3(0,1.74,0),Vector3(.46,.38,.42),armor))
 var face = F.face(root,Vector3(0,1.74,-.23))
 root.set_meta("face",face)
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
