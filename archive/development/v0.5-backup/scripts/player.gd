extends CharacterBody3D
const F = preload("res://scripts/factory.gd")
const Gear = preload("res://scripts/gear.gd")
const Operative = preload("res://scripts/operative.gd")
var overcharged := false
var armor_big := false
var weapon_models := [0,1]
var weapon_big := [false,false]
var third_person := false
var body_model: Node3D
var rainbow_material: Material
var game: Node3D
var camera: Camera3D
var gun: Node3D
var flash: Node3D
var weapons: Array[Node3D] = []
var armor_tier := 0
var weapon_tiers := [0,0]
var armor_material: StandardMaterial3D
var weapon := 0
var ammo := [30, 8]
var capacity := [30, 8]
var reload_left := 0.0
var cooldown := 0.0
var recoil := 0.0
var bob := 0.0
var shield := 100.0
var hurt_cooldown := 0.0
var shield_delay := 0.0
var ads := false
var sensitivity := 0.0022
var muzzle_light: OmniLight3D
var walking := false
var feet_timer := 0.0
var pants: Node3D
var pants_green: ShaderMaterial
var pants_plain: Material

func _ready() -> void:
 collision_layer = 2
 collision_mask = 1
 var capsule = CapsuleShape3D.new()
 capsule.radius = 0.34
 capsule.height = 1.8
 var shape = CollisionShape3D.new()
 shape.shape = capsule
 shape.position.y = 0.9
 add_child(shape)
 camera = Camera3D.new()
 add_child(camera)
 camera.position.y = 1.58
 camera.fov = 82
 camera.near = 0.04
 gun = Node3D.new()
 camera.add_child(gun)
 gun.position = Vector3(0.28, -0.25, -0.46)
 build_weapons()
 build_pants()
 rainbow_material = Gear.armor_surface(5)
 body_model = Operative.make_body(self,armor_material,pants_green,weapon,weapon_tiers,true,false)
 body_model.visible = false
 refresh_body()

func build_weapons() -> void:
 armor_material = F.mat(Gear.COLORS[armor_tier])
 var glove = F.mat(Color("111c29"))
 for i in range(2):
  var w = Gear.make_weapon(gun,weapon_models[i],weapon_tiers[i])
  weapons.append(w)
  F.box(w,Vector3(.04,-.17,.18),Vector3(.13,.15,.17),glove).rotation.x = -.3
  F.box(w,Vector3(.09,-.24,.32),Vector3(.17,.15,.32),armor_material).set_meta("armor",true)
  w.get_child(w.get_child_count()-1).rotation.x = -.35
  F.box(w,Vector3(-.05,-.10,-.20),Vector3(.14,.12,.16),glove)
  F.box(w,Vector3(-.10,-.20,-.03),Vector3(.16,.16,.30),armor_material).set_meta("armor",true)
  w.get_child(w.get_child_count()-1).rotation.x = .6
  w.visible = i == weapon
 flash = Node3D.new()
 gun.add_child(flash)
 flash.position = Vector3(0,0,-.69)
 F.sphere(flash,Vector3.ZERO,.065,F.mat(Color("ffe9a5"),3.0))
 flash.visible = false
 muzzle_light = OmniLight3D.new()
 muzzle_light.light_color = Color("ffd59b")
 muzzle_light.omni_range = 4
 muzzle_light.light_energy = 0
 flash.add_child(muzzle_light)

func _unhandled_input(event: InputEvent) -> void:
 if not game.active:
  return
 if event is InputEventMouseMotion:
  if game.capture_delay > 0 or game.smoke_mode:
   return
  rotate_y(-event.relative.x * sensitivity)
  camera.rotation.x = clamp(camera.rotation.x-event.relative.y*sensitivity, -1.35,1.35)
 if event.is_action_pressed("overcharge"):
  activate_overcharge()
 if event.is_action_pressed("player_grenade"):
  throw_player_grenade()
 if event.is_action_pressed("view_toggle"):
  set_view(not third_person)
 if event.is_action_pressed("coat_heal"):
  coat_heal()
 for i in range(3):
  if event.is_action_pressed(["skill_dash","skill_heal","skill_pulse"][i]):
   use_skill(i)
 if event.is_action_pressed("reload"):
  reload_weapon()
 if event.is_action_pressed("weapon1"):
  switch_weapon(0)
 if event.is_action_pressed("weapon2"):
  switch_weapon(1)
 if event is InputEventMouseButton and event.pressed:
  if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
   switch_weapon(1-weapon)

func switch_weapon(index: int) -> void:
 if index == weapon:
  return
 reload_left = 0
 weapon = index
 for i in range(2):
  weapons[i].visible = i == weapon
 recoil = .10
 refresh_body()
 game.sound("switch",0.75)

func reload_weapon() -> void:
 if reload_left > 0 or ammo[weapon] == capacity[weapon]:
  return
 reload_left = 1.55 if weapon == 0 else 1.9
 game.sound("reload")

func _physics_process(dt: float) -> void:
 if not game.active:
  return
 cooldown = maxf(0, cooldown-dt)
 hurt_cooldown = maxf(0,hurt_cooldown-dt)
 shield_delay = maxf(0,shield_delay-dt)
 if shield_delay == 0:
  shield = minf(max_shield(),shield+dt*10)
 if reload_left > 0:
  reload_left = maxf(0,reload_left-dt)
  if reload_left == 0:
   ammo[weapon] = capacity[weapon]
   game.sound("switch",0.7)
 ads = Input.is_action_pressed("aim") and reload_left == 0
 var axis = Input.get_vector("left","right","forward","back")
 var direction = transform.basis * Vector3(axis.x,0,axis.y)
 var speed = 7.4 if Input.is_action_pressed("sprint") and not ads else 5.0
 if ads:
  speed = 3.0
 velocity.x = move_toward(velocity.x,direction.x*speed,dt*35)
 velocity.z = move_toward(velocity.z,direction.z*speed,dt*35)
 if not is_on_floor():
  velocity.y -= 20*dt
 elif Input.is_action_just_pressed("jump"):
  velocity.y = 7.2
 move_and_slide()
 update_view()
 walking = axis.length() > .1 and is_on_floor()
 if walking:
  bob += dt*speed*1.8
  feet_timer -= dt
  if feet_timer <= 0:
   game.sound("step",.35)
   feet_timer = .43 if speed < 7 else .31
 camera.fov = lerpf(camera.fov,60.0 if ads else 82.0,dt*12)
 recoil = move_toward(recoil,0,dt*.9)
 var target = Vector3(.055,-.19,-.48) if ads else Vector3(.28,-.25,-.46)
 target.y += (sin(bob)*.009 if walking else sin(game.elapsed*1.7)*.002) if not game.low_motion else 0.0
 target.z += recoil*.45
 gun.position = gun.position.lerp(target,minf(1,dt*15))
 gun.rotation.x = recoil*.8 + (sin(reload_left*6)*.35 if reload_left > 0 else 0.0)
 gun.rotation.z = -.45 if reload_left > 0 else 0.0
 flash.visible = cooldown > Gear.interval(weapon_models[weapon],weapon_tiers[weapon])-.035
 muzzle_light.light_energy = 1.5 if flash.visible else 0
 if Input.is_action_pressed("fire"):
  shoot()
 if Input.is_action_just_pressed("interact"):
  game.interact()
 if position.y < -8:
  rescue()

func shoot() -> void:
 if cooldown > 0 or reload_left > 0:
  return
 if ammo[weapon] <= 0:
  reload_weapon()
  return
 ammo[weapon] -= 1
 cooldown = Gear.interval(weapon_models[weapon],weapon_tiers[weapon])
 recoil = .065 if weapon == 0 else .16
 game.shots += 1
 game.sound("shotgun" if weapon_models[weapon]==1 else "ak")
 var origin = camera.global_position
 var forward = -camera.global_transform.basis.z
 var assist_target: Node3D = null
 var best_dot = .994 if game.assist else 1.0
 for enemy in game.enemies:
  if is_instance_valid(enemy) and enemy.hp > 0:
   var dir = (enemy.global_position+Vector3.UP*1.1-origin).normalized()
   var dot = forward.dot(dir)
   if dot > best_dot and game.clear_line(origin,enemy.global_position+Vector3.UP*1.1,enemy):
    best_dot = dot
    assist_target = enemy
 if assist_target:
  forward = (assist_target.global_position+Vector3.UP*1.1-origin).normalized()
 var hit_any = false
 for i in range(9 if weapon_models[weapon]==1 else 1):
  var spread = (.003 if ads else .012) if weapon_models[weapon] != 1 else (.045 if ads else .065)
  var dir = (forward+camera.global_basis.x*game.rng.randf_range(-spread,spread)+camera.global_basis.y*game.rng.randf_range(-spread,spread)).normalized()
  var query = PhysicsRayQueryParameters3D.create(origin,origin+dir*85,5)
  var hit = get_world_3d().direct_space_state.intersect_ray(query)
  var end = hit.position if not hit.is_empty() else origin+dir*65
  if third_person:
   var obstruction = PhysicsRayQueryParameters3D.create(muzzle_position(),end,5)
   var blocked = get_world_3d().direct_space_state.intersect_ray(obstruction)
   if not blocked.is_empty():
    hit = blocked
  if not hit.is_empty():
   end = hit.position
   game.spark(end,Color("ffdc9b"),3)
   if hit.collider.has_method("take_hit"):
    var distance = origin.distance_to(end)
    hit.collider.take_hit(Gear.damage(weapon_models[weapon],weapon_tiers[weapon],distance)*(1.25 if weapon_big[weapon] else 1.0))
    hit_any = true
  game.tracer(muzzle_position(),end,Color("ffdc9b"),.045)
 if hit_any:
  game.hits += 1
  game.hit_marker = .15
  game.sound("hit",.65)
 camera.rotation.x = clampf(camera.rotation.x+(.008 if ads else .014),-1.35,1.35)

func damage(amount: float) -> void:
 if hurt_cooldown > 0 or not game.active:
  return
 shield -= amount*(1.0-total_reduction())
 shield_delay = 4.0
 hurt_cooldown = .45
 game.hurt_flash = .3
 game.sound("hurt",.6)
 if shield <= 0:
  rescue()

func rescue() -> void:
 shield = max_shield()
 position = game.extraction_position+Vector3.UP*.2
 velocity = Vector3.ZERO
 hurt_cooldown = 4
 game.rescues += 1
 game.message("护盾已修复 · 已返回出发点，能源保留",4)

func max_shield() -> float:
 if armor_tier==5 and overcharged:
  return 9999.0
 return Gear.SHIELD[armor_tier]*(1.2 if armor_big and armor_tier!=5 else 1.0)

func equip_armor(tier: int) -> void:
 armor_tier = clampi(tier,0,5)
 overcharged = false
 shield = max_shield()
 Gear.color_material(armor_material,armor_tier)
 refresh_body()

func upgrade_weapon(tier: int) -> void:
 weapon_tiers[weapon] = maxi(weapon_tiers[weapon],clampi(tier,0,5))
 Gear.paint_weapon(weapons[weapon],weapon_tiers[weapon])
 ammo[weapon] = capacity[weapon]
 refresh_body()

func build_pants() -> void:
 pants = Node3D.new()
 add_child(pants)
 var material = ShaderMaterial.new()
 material.shader = load("res://scripts/pants.gdshader")
 pants_green = material
 pants_plain = F.mat(Color("485567"))
 var boots = F.mat(Color("142b26"))
 for side in [-1,1]:
  F.box(pants,Vector3(side*.18,.62,-.02),Vector3(.24,.44,.27),material).set_meta("trousers",true)
  F.box(pants,Vector3(side*.18,.27,-.04),Vector3(.21,.36,.23),material).set_meta("trousers",true)
  F.box(pants,Vector3(side*.18,.07,-.13),Vector3(.25,.13,.39),boots)

func use_skill(index: int) -> bool:
 if not game.active or index<0 or index>2 or not game.career.skills[index]:
  if game.active:
   game.message("技能尚未解锁 · 按 B 打开背包的技能页",2)
  return false
 if index==0:
  var direction = -global_basis.z
  direction.y = 0
  move_and_collide(direction.normalized()*7)
  game.spark(global_position+Vector3.UP,Color("6fffe1"),5)
 elif index==1:
  shield = max_shield()
  shield_delay = 0
  game.spark(global_position+Vector3.UP,Color("64eaa1"),6)
 else:
  for enemy in game.enemies:
   if is_instance_valid(enemy) and enemy.hp>0 and enemy.position.distance_to(position)<8 and game.clear_line(camera.global_position,enemy.position+Vector3.UP,enemy):
    enemy.take_hit(65)
  var ring = F.sphere(game,global_position+Vector3.UP,.7,F.mat(Color("64ead5"),1))
  game.effects.append({"node":ring,"life":.12})
 game.sound("pickup",.3)
 return true

func set_pants_style(green: bool) -> void:
 for part in pants.get_children():
  if part.has_meta("trousers"):
   part.material_override = pants_green if green else pants_plain
 update_pants_equipment()

func refresh_body() -> void:
 if not is_instance_valid(body_model):
  return
 var material: Material = rainbow_material if armor_tier==5 else armor_material
 for part in body_model.get_meta("armor_parts"):
  part.material_override = material
 for i in range(2):
  var model_gun = body_model.get_meta("guns")[i]
  model_gun.visible = i==weapon
  model_gun.scale = model_gun.get_meta("base_scale")*.85*(1.1 if weapon_big[i] else 1.0)
  weapons[i].scale = weapons[i].get_meta("base_scale")*(1.1 if weapon_big[i] else 1.0)
  Gear.paint_weapon(model_gun,weapon_tiers[i])
 body_model.get_meta("coat").visible = game.career.operator_coat
 for w in weapons:
  for part in w.get_children():
   if part.has_meta("armor"):
    part.material_override = material

func set_view(enabled: bool, persist: bool = true) -> bool:
 if persist and not game.career.set_view(enabled):
  return false
 third_person = enabled
 gun.visible = not third_person
 update_view()
 return true

func update_view() -> void:
 if not third_person:
  camera.position = Vector3(0,1.58,0)
  if is_instance_valid(body_model):
   body_model.visible = false
  return
 var eye = global_transform*Vector3(0,1.58,0)
 var offset = camera.basis.z*3.6+camera.basis.x*.55+Vector3.UP*.18
 var motion = global_basis*offset
 var query = PhysicsShapeQueryParameters3D.new()
 var shape = SphereShape3D.new()
 shape.radius = .20
 query.shape = shape
 query.transform = Transform3D(Basis.IDENTITY,eye)
 query.motion = motion
 query.collision_mask = 1
 var fractions = get_world_3d().direct_space_state.cast_motion(query)
 var fraction = fractions[0] if fractions.size()>0 else 1.0
 camera.position = Vector3(0,1.58,0)+offset*maxf(0,fraction-.015)
 body_model.visible = camera.position.distance_to(Vector3(0,1.58,0))>.65
 for w in body_model.get_meta("guns"):
  w.rotation.x = camera.rotation.x

func muzzle_position() -> Vector3:
 if third_person:
  return body_model.get_meta("guns")[weapon].to_global(Vector3(0,0,-.7))
 return flash.global_position

func coat_heal() -> bool:
 if not game.active or not game.career.operator_coat:
  return false
 shield = max_shield()
 shield_delay = 0
 game.spark(global_position+Vector3.UP,Color("6affb3"),5)
 game.sound("pickup",.25)
 return true

func total_reduction() -> float:
 var pants_bonus = 0.0
 if game.career.pants_style>0:
  pants_bonus = game.career.equipped.pants*.02
 return minf(.65,Gear.REDUCTION[armor_tier]+pants_bonus+(.03 if armor_big else 0.0))

func activate_overcharge() -> bool:
 if not game.active or armor_tier!=5:
  if game.active:
   game.message("需要先穿上彩虹甲，才能开启 Q · 9999 护盾",3)
  return false
 overcharged = true
 shield = 9999.0
 game.message("彩虹超载开启 · 护盾上限 9999",3)
 return true

func throw_player_grenade() -> bool:
 if not game.active or game.career.grenades<=0:
  return false
 var before = game.career.snapshot()
 game.career.grenades -= 1
 if not game.career.commit(before):
  return false
 var origin = global_position+Vector3.UP*1.4-global_basis.z*.5
 var target = global_position-global_basis.z*12
 var q = PhysicsRayQueryParameters3D.create(camera.global_position,camera.global_position-camera.global_basis.z*18,1)
 var hit = get_world_3d().direct_space_state.intersect_ray(q)
 if not hit.is_empty():
  target = hit.position
 game.throw_grenade(origin,target,true)
 return true

func update_pants_equipment() -> void:
 if not is_instance_valid(pants):
  return
 var material: Material = pants_green if game.career.green_pants else pants_plain
 if game.career.pants_style>0:
  material = Gear.armor_surface(game.career.equipped.pants)
 for part in pants.get_children():
  if part.has_meta("trousers"):
   part.material_override = material
   part.visible = true
   if game.career.pants_style==2:
    if part.position.y<.4:
     part.material_override = F.mat(Color("a48368"))
    else:
     part.scale.y = .55
   else:
    part.scale.y = 1.0

func set_weapon_models(values: Array) -> void:
 if weapon_models==values:
  return
 weapon_models = values.duplicate()
 for i in range(2):
  var old = weapons[i]
  gun.remove_child(old)
  old.queue_free()
  var w = Gear.make_weapon(gun,weapon_models[i],weapon_tiers[i])
  weapons[i] = w
  var glove = F.mat(Color("111c29"))
  F.box(w,Vector3(.04,-.17,.18),Vector3(.13,.15,.17),glove)
  F.box(w,Vector3(.09,-.24,.32),Vector3(.17,.15,.32),armor_material).set_meta("armor",true)
  F.box(w,Vector3(-.05,-.10,-.20),Vector3(.14,.12,.16),glove)
  F.box(w,Vector3(-.10,-.20,-.03),Vector3(.16,.16,.30),armor_material).set_meta("armor",true)
  w.visible = i==weapon
  capacity[i] = Gear.CAPACITY[weapon_models[i]]
  ammo[i] = capacity[i]
 var old_body = body_model
 remove_child(old_body)
 old_body.queue_free()
 body_model = Operative.make_body(self,armor_material,pants_green,weapon,weapon_tiers,game.career.operator_coat,false,weapon_models)
 refresh_body()
 update_view()
