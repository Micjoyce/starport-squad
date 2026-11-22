extends CharacterBody3D
const F = preload("res://scripts/factory.gd")
var game: Node3D
var kind := 0
var bite_timer := 0.0
var path_timer := 0.0
var path := PackedVector2Array()
var phase := 0.0
var legs: Array = []
func _ready() -> void:
 collision_layer = 0
 collision_mask = 1
 var collider = CollisionShape3D.new()
 var shape = CapsuleShape3D.new()
 shape.radius = .25
 shape.height = .7
 collider.shape = shape
 collider.position.y = .4
 add_child(collider)
 var fur = F.mat(Color("9a7051") if kind==0 else Color("dee2e9"))
 var dark = F.mat(Color("263548"))
 var root = Node3D.new()
 add_child(root)
 if kind==1: root.scale = Vector3(1.25,1.25,1.25)
 F.box(root,Vector3(0,.60,0),Vector3(.5,.4,1.25 if kind==1 else .9),fur)
 if kind==1:
  F.box(root,Vector3(0,1.05,-.4),Vector3(.30,.75,.35),fur)
  F.box(root,Vector3(0,1.05,-.23),Vector3(.13,.70,.13),dark)
 F.box(root,Vector3(0,1.45 if kind==1 else .85,-.5),Vector3(.35,.35,.52) if kind==1 else Vector3(.4,.4,.4),fur)
 F.box(root,Vector3(0,1.36 if kind==1 else .78,-.83 if kind==1 else -.73),Vector3(.25,.20,.22),dark)
 for side in [-1,1]:
  F.box(root,Vector3(side*.16,1.76 if kind==1 else 1.12,-.45),Vector3(.10,.22,.12),fur)
  F.sphere(root,Vector3(side*.18,1.51 if kind==1 else .94,-.65),.04,F.mat(Color("58ffdc"),1))
  for z in [-.3,.3]:
   legs.append(F.box(root,Vector3(side*.18,.26,z),Vector3(.13,.48,.15),fur))
 var tail = F.box(root,Vector3(0,.70,.60),Vector3(.10,.12,.45),fur)
 tail.rotation.x = -.5
 F.box(root,Vector3(0,.7,-.28),Vector3(.53,.08,.09),F.mat(Color("58ffdc"),1))
 F.batch_meshes(root)
 var label = F.text3d(self,"伙伴犬" if kind==0 else "破甲战马",Vector3(0,1.8 if kind==1 else 1.4,0),20,Color("7affce"))
 label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
func step(dt: float) -> void:
 if not game.active: return
 bite_timer = maxf(0,bite_timer-dt)
 var target: Node3D = null
 var limit = 16.0
 for enemy in game.enemies:
  if is_instance_valid(enemy) and enemy.hp>0 and enemy.position.distance_to(game.player.position)<18:
   var distance = position.distance_to(enemy.position)
   if distance<limit:
    limit = distance
    target = enemy
 var goal = game.player.position+game.player.global_basis*Vector3(-1.5,0,2)
 if target!=null: goal = target.position
 if position.distance_to(game.player.position)>35:
  position = game.player.position+Vector3(1,0,1)
 path_timer -= dt
 if path_timer<=0:
  path_timer = .4
  path = game.find_path(position,goal)
 var direction = Vector3.ZERO
 if position.distance_to(goal)>1.5 and path.size()>1:
  var point = Vector3(path[1].x,position.y,path[1].y)
  if point.distance_to(position)<.5: path.remove_at(0)
  direction = (point-position).normalized()
 velocity.x = direction.x*8
 velocity.z = direction.z*8
 velocity.y -= 20*dt
 move_and_slide()
 if Vector2(goal.x-position.x,goal.z-position.z).length()>.05:
  look_at(Vector3(goal.x,position.y,goal.z))
 if target!=null and position.distance_to(target.position)<2.2 and bite_timer==0 and game.clear_line(position+Vector3.UP*.7,target.position+Vector3.UP,target):
  bite_timer = 1.0 if kind==0 else 2.4
  if kind==1 and target.armor>0:
   target.break_armor()
  else:
   target.take_hit(45+mini(100,game.career.pet_xp/5))
  game.spark(target.position+Vector3.UP,Color("78ffbd"),4)
