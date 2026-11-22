extends CharacterBody3D
const F = preload("res://scripts/factory.gd")
const RAINBOW_HITS = [25,199,10000]
const GRENADE_HITS = [28,49,199]
const NAMES = ["旧漆灰白","蓝色战术","深绿黑纹"]
var game: Node3D
var tier := 0
var armored_car := false
var friendly := true
var durability := 1.0
var destroyed := false
var turret: Node3D
var label: Label3D
var driver: Node3D
var gunner: Node3D
var passengers: Array = []
var cooldown := 0.0
var ai_timer := 0.0
var shot_count := 0
var burn: Node3D

func _ready() -> void:
 collision_layer = 1
 collision_mask = 1
 var shape = CollisionShape3D.new()
 var box = BoxShape3D.new()
 box.size = Vector3(2.7,1.5,4.2)
 shape.shape = box
 shape.position.y = 1.0
 add_child(shape)
 var color = [Color("85898a"),Color("356289"),Color("233f2d")][tier]
 var plate = F.mat(color)
 var ink = F.mat(Color("131e1c"))
 var worn = F.mat(Color("b1b0a2"))
 F.box(self,Vector3(0,.85,0),Vector3(2.6,1.05,4),plate)
 F.box(self,Vector3(0,1.35,.25),Vector3(2.25,.45,2.9),plate)
 for side in [-1,1]:
  if not armored_car:
   F.box(self,Vector3(side*1.35,.5,0),Vector3(.55,.8,4.4),ink)
  for z in [-1.5,-.5,.5,1.5]:
   var wheel = F.cylinder(self,Vector3(side*1.4,.5,z),.43,.30,ink)
   wheel.rotation.z = PI/2
   var hub = F.cylinder(self,Vector3(side*1.57,.5,z),.23,.04,worn)
   hub.rotation.z = PI/2
  for z in [-1.6,-.65,.4,1.4]:
   var mark = F.box(self,Vector3(side*1.315,1.03,z),Vector3(.025,.30,.7),worn if tier==0 else ink)
   mark.rotation.x = .45*side
  F.box(self,Vector3(side*.86,1.18,-2.04),Vector3(.34,.18,.05),F.mat(Color("99f8e8"),1))
  F.box(self,Vector3(side*.9,1.4,.75),Vector3(.4,.1,.8),ink)
 turret = Node3D.new()
 add_child(turret)
 turret.position = Vector3(0,1.72,0)
 F.cylinder(turret,Vector3.ZERO,.78,.55,plate)
 F.box(turret,Vector3(0,.15,-1.1),Vector3(.65,.45,1.25),plate)
 F.box(turret,Vector3(0,.18,-2.1),Vector3(.18,.18,2.0 if not armored_car else 1.15),ink)
 F.box(turret,Vector3(.35,.5,-.2),Vector3(.12,.12,.85),ink)
 F.cylinder(turret,Vector3(0,.37,.15),.30,.08,ink)
 driver = crew(Vector3(0,1.5,-1))
 gunner = crew(Vector3(.4,2.0,.25))
 label = F.text3d(self,"",Vector3(0,3.5,0),24,Color("70efce") if friendly else Color("ffb56b"))
 label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 burn = F.sphere(self,Vector3(0,2,0),.65,F.mat(Color("e9954c"),1.8))
 burn.visible = false
 burn.set_meta("dynamic",true)
 F.batch_meshes(self)
 refresh()

func crew(pos: Vector3) -> Node3D:
 var root = Node3D.new()
 add_child(root)
 root.position = pos
 F.box(root,Vector3.ZERO,Vector3(.4,.5,.3),F.mat(Color("405a53")))
 F.sphere(root,Vector3(0,.38,0),.23,F.mat(Color("c8ab88")))
 F.face(root,Vector3(0,.38,-.2))
 F.box(root,Vector3(0,.55,0),Vector3(.5,.14,.45),F.mat(Color("263e37")))
 return root

func title() -> String:
 return NAMES[tier]+("装甲车" if armored_car else "坦克")

func seats_used() -> int:
 return 2+passengers.size()

func refresh() -> void:
 if is_instance_valid(label):
  label.text = title()+" / "+("已报废" if destroyed else "%d%% · %d/8 人" % [ceili(durability*100),seats_used()])
 driver.visible = not destroyed
 gunner.visible = not destroyed

func receive_rounds(count: int = 1, rainbow: bool = true) -> void:
 if destroyed or count<=0: return
 durability = maxf(0,durability-float(count)/(RAINBOW_HITS[tier]*(1 if rainbow else 12)))
 finish_damage()

func take_hit(_amount: float) -> void:
 receive_rounds(1,false)

func take_grenade() -> void:
 if destroyed: return
 durability = maxf(0,durability-1.0/GRENADE_HITS[tier])
 finish_damage()

func finish_damage() -> void:
 if durability<.00000001:
  durability = 0
  destroyed = true
  burn.visible = true
  game.spark(global_position+Vector3.UP,Color("ffb467"),20)
  if game.vehicles.current==self: game.vehicles.exit_vehicle(true)
  for unit in passengers:
   if is_instance_valid(unit) and unit!=game.player:
    unit.visible = true
    unit.collision_layer = 8
    unit.set_meta("aboard",false)
    unit.process_mode = Node.PROCESS_MODE_INHERIT
    unit.global_position = global_position+Vector3(3,.2,0)
  passengers.clear()
 refresh()

func _physics_process(dt: float) -> void:
 if not game.active or destroyed: return
 cooldown = maxf(0,cooldown-dt)
 var occupied = game.vehicles.current==self
 label.visible = not occupied
 if occupied:
  turret.global_rotation.y = game.player.global_rotation.y
  var axis = Input.get_vector("left","right","forward","back") if game.vehicles.role==0 else Vector2.ZERO
  if axis.length()>.05:
   rotation.y -= axis.x*dt*.8
  var direction = -global_basis.z*(-axis.y)
  velocity.x = move_toward(velocity.x,direction.x*(11 if armored_car else 7),dt*8)
  velocity.z = move_toward(velocity.z,direction.z*(11 if armored_car else 7),dt*8)
  if game.vehicles.role==1 and Input.is_action_pressed("fire"):
   fire(-game.player.camera.global_basis.z)
 else:
  velocity.x = move_toward(velocity.x,0,dt*10)
  velocity.z = move_toward(velocity.z,0,dt*10)
 velocity.y -= 20*dt
 move_and_slide()
 if occupied:
  game.player.global_position = global_position+Vector3(0,2.5,0)
  var eye = global_position+Vector3.UP*3.8
  var destination: Vector3 = game.player.to_global(Vector3(0,2,5.5))
  var query = PhysicsRayQueryParameters3D.create(eye,destination,1,[get_rid()])
  var obstruction = get_world_3d().direct_space_state.intersect_ray(query)
  if not obstruction.is_empty(): destination = obstruction.position.lerp(eye,.1)
  game.player.camera.global_position = destination
  game.player.gun.visible = false
  game.player.body_model.visible = false
  game.player.pants.visible = false
  for unit in passengers:
   if is_instance_valid(unit) and unit!=game.player: unit.global_position = global_position
 ai_timer -= dt
 if ai_timer<=0 and (occupied and game.vehicles.role==0 or not friendly):
  ai_timer = .5
  var candidates: Array = game.enemies if friendly else [game.player]+game.allies
  for target in candidates:
   if is_instance_valid(target) and target.hp>0 and not target.get_meta("aboard",false) and global_position.distance_to(target.global_position)<45:
    var aim: Vector3 = target.global_position+Vector3.UP
    var from = turret.global_position+Vector3.UP*.6
    var q = PhysicsRayQueryParameters3D.create(from,aim,7,[get_rid()])
    var hit = get_world_3d().direct_space_state.intersect_ray(q)
    if not hit.is_empty() and hit.collider==target:
     turret.look_at(Vector3(aim.x,turret.global_position.y,aim.z))
     fire((aim-from).normalized())
     break

func fire(direction: Vector3) -> void:
 if cooldown>0 or destroyed: return
 cooldown = .12 if armored_car else .3
 shot_count += 1
 var from = turret.global_position+Vector3.UP*.6
 var q = PhysicsRayQueryParameters3D.create(from,from+direction*160,7,[get_rid()])
 var hit = get_world_3d().direct_space_state.intersect_ray(q)
 var end = from+direction*160
 if not hit.is_empty():
  end = hit.position
  if hit.collider is CharacterBody3D:
   if hit.collider==game.player:
    if not friendly: game.player.damage(15)
   elif hit.collider.has_method("receive_rounds"):
    if hit.collider.friendly!=friendly: hit.collider.receive_rounds(1,true)
   elif hit.collider.has_method("take_hit") and hit.collider.friendly!=friendly:
    hit.collider.take_hit(45 if armored_car else 100)
 game.tracer(from,end,Color("ffd67c"),.08)
 game.sound("ak",.4)

func take_laser(_amount: float) -> void:
 receive_rounds(1,true)
