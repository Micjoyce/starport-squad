extends CharacterBody3D
const F = preload("res://scripts/factory.gd")
const Gear = preload("res://scripts/gear.gd")
var game: Node3D
var friendly := false
var slot := 0
var target_unit: Node3D
var knife: Node3D
var is_boss := false
var big := false
var hp := 100.0
var max_hp := 100.0
var armor_tier := 0
var weapon_tier := 0
var weapon_kind := 0
var armor := 100.0
var gun: Node3D
var ammo := 30
var reload_left := 0.0
var grenade_timer := 7.0
var windup := -1.0
var planned_aim := Vector3.ZERO
var badge: Label3D
var fire_timer := 2.0
var path_timer := 0.0
var path := PackedVector2Array()
var model: Node3D
var eye: MeshInstance3D
var home := Vector3.ZERO
var phase := 0.0
var hit_time := 0.0
var health_bar: MeshInstance3D
var body_material: StandardMaterial3D

func _ready() -> void:
 collision_layer = 8 if friendly else 4
 collision_mask = 1
 var s = CollisionShape3D.new()
 var c = CapsuleShape3D.new()
 c.radius = .43
 c.height = 1.65
 s.shape = c
 s.position.y = .9
 add_child(s)
 model = Node3D.new()
 add_child(model)
 body_material = F.mat(Gear.COLORS[armor_tier])
 max_hp = hp
 armor = Gear.SHIELD[armor_tier]
 ammo = Gear.CAPACITY[weapon_kind]
 grenade_timer = game.rng.randf_range(6,12)
 var dark = F.mat(Color("1c2b3d"))
 var accent = F.mat(Color("51ffe0") if friendly else Color("ff7962"),1.5)
 var steel = F.mat(Color("91a8b5"))
 F.box(model,Vector3(0,1.1,0),Vector3(.72,.64,.42),body_material)
 F.box(model,Vector3(0,.79,0),Vector3(.42,.14,.30),dark)
 F.box(model,Vector3(0,1.65,0),Vector3(.55,.35,.40),body_material)
 eye = F.box(model,Vector3(0,1.65,-.215),Vector3(.39,.09,.035),accent)
 eye.set_meta("dynamic",true)
 F.box(model,Vector3(0,1.18,-.23),Vector3(.22,.22,.04),dark)
 F.box(model,Vector3(0,1.18,-.26),Vector3(.12,.12,.03),accent)
 for side in [-1,1]:
  F.sphere(model,Vector3(side*.46,1.30,0),.14,dark)
  F.box(model,Vector3(side*.50,1.08,0),Vector3(.22,.4,.25),body_material)
  F.box(model,Vector3(side*.50,.91,-.15),Vector3(.19,.18,.28),dark)
  F.box(model,Vector3(side*.22,.5,0),Vector3(.20,.48,.23),body_material)
  F.sphere(model,Vector3(side*.22,.42,-.03),.14,dark)
  F.box(model,Vector3(side*.22,.16,-.08),Vector3(.27,.20,.39),dark)
 gun = Gear.make_weapon(model,weapon_kind,weapon_tier)
 gun.position = Vector3(.39,1.02,-.35)
 knife = Gear.make_knife(model)
 knife.position = Vector3(.4,1.05,-.4)
 knife.visible = false
 badge = F.text3d(model,("友军 %02d" % (slot+1) if friendly else ("首领 / 彩虹全套" if is_boss else Gear.SHORT[armor_tier]))+" / "+Gear.MODEL_NAMES[weapon_kind],Vector3(0,2.2,0),23,Gear.COLORS[armor_tier])
 badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 if friendly:
  badge.pixel_size = .005
  badge.font_size = 18
 health_bar = F.box(model,Vector3(0,2.0,0),Vector3(.65,.04,.04),F.mat(Color("ffb169"),1))
 health_bar.set_meta("dynamic",true)
 health_bar.visible = false
 if armor_tier==5:
  var rainbow = Gear.armor_surface(5)
  for part in model.get_children():
   if part is MeshInstance3D and part.material_override==body_material:
    part.material_override = rainbow
 home = position
 phase = game.rng.randf()*TAU
 fire_timer = game.rng.randf_range(1.3,3)
 F.batch_meshes(model)

func _physics_process(dt: float) -> void:
 if not game.active or hp <= 0:
  return
 if friendly:
  badge.visible = global_position.distance_to(game.player.camera.global_position)>2.5
 phase += dt*4
 hit_time = maxf(0,hit_time-dt)
 Gear.color_material(body_material,armor_tier)
 if hit_time > 0:
  body_material.albedo_color = Color("fff3cf")
 target_unit = select_target()
 var target = target_unit.position if target_unit!=null else game.player.position
 var anchor = game.command.anchor(self)
 var leash = 10.0 if friendly and game.command.order=="defend" else (14.0 if friendly else 16.0)
 var following = target_unit==null or (friendly and position.distance_to(anchor)>leash) or (is_boss and position.distance_to(anchor)>12)
 if following:
  target_unit = null
  target = game.command.rally_point(self)
 var distance = position.distance_to(target)
 var visible_target = target_unit!=null and game.clear_line(global_position+Vector3.UP*1.4,target_unit.global_position+Vector3.UP*1.3,target_unit)
 var destination = target
 path_timer -= dt
 if path_timer <= 0:
  path_timer = .65+game.rng.randf()*.4
  path = game.find_path(position,destination)
 var motion = Vector3.ZERO
 if distance > (1.0 if following else 7.0) or (not visible_target and not following):
  if path.size() > 1:
   var wp = Vector3(path[1].x,0,path[1].y)
   if Vector2(position.x-wp.x,position.z-wp.z).length() < .55:
    path.remove_at(0)
    if path.size() > 1:
     wp = Vector3(path[1].x,0,path[1].y)
   motion = (wp-position).normalized()
   motion.y = 0
 var speed = 7.8 if friendly else 2.2+game.difficulty*.45
 velocity.x = motion.x*speed
 velocity.z = motion.z*speed
 velocity.y -= 20*dt
 move_and_slide()
 if distance < 28:
  var flat = Vector3(target.x,global_position.y,target.z)
  if flat.distance_squared_to(global_position) > .01:
   look_at(flat,Vector3.UP)
 model.position.y = sin(phase)*.035 if motion.length() > .1 else 0.0
 fire_timer -= dt
 grenade_timer -= dt
 reload_left = maxf(0,reload_left-dt)
 if reload_left == 0 and ammo <= 0:
  ammo = Gear.CAPACITY[weapon_kind]
 var melee = target_unit!=null and distance<2.4 and visible_target
 knife.visible = melee
 gun.visible = not melee
 knife.rotation.z = sin(fire_timer*18)*.6
 if melee:
  windup = -1
  eye.scale.y = 1
  if fire_timer<=0:
   fire_timer = .6
   if target_unit==game.player:
    game.player.damage(35*(2.0 if game.difficulty==3 else 1.0))
   else:
    target_unit.take_hit(80)
  return
 if target_unit==null:
  return
 if windup >= 0:
  windup -= dt
  eye.scale.y = 2.0
  if windup <= 0:
   windup = -1
   eye.scale.y = 1.0
   fire_weapon()
 if distance < 24 and visible_target and fire_timer <= 0 and reload_left == 0 and windup < 0:
  var scatter = .7 if game.difficulty==0 else (.48 if game.difficulty==1 else .28)
  planned_aim = (target_unit.global_position+Vector3.UP*1.3)+Vector3(game.rng.randf_range(-scatter,scatter),-.20,game.rng.randf_range(-scatter,scatter))
  if game.difficulty == 0:
   fire_weapon()
  else:
   # Aim is locked before firing; moving during this visible windup dodges the shot.
   windup = .30 if game.difficulty==1 else .20
   fire_timer = .5
 if not friendly and game.difficulty>0 and distance>4 and distance<21 and visible_target and grenade_timer<=0:
  grenade_timer = game.rng.randf_range(9,14) if game.difficulty==1 else game.rng.randf_range(7,11)
  game.throw_grenade(global_position+Vector3.UP*1.3,target_unit.position)

func fire_weapon() -> void:
 if hp<=0:
  return
 var origin = gun.to_global(Vector3(0,0,-.70))
 ammo -= 1
 if friendly:
  fire_timer = Gear.interval(weapon_kind,weapon_tier)*2.0
  game.command.ally_shot(self,origin,planned_aim)
  if ammo<=0:
   reload_left = 1.55
   fire_timer = reload_left
 elif game.difficulty == 0:
  fire_timer = game.rng.randf_range(1.2,1.9)
  game.launch_bolt(origin,(planned_aim-origin).normalized())
 else:
  fire_timer = Gear.interval(weapon_kind,weapon_tier)*(2.4 if game.difficulty==1 else 1.8)
  game.enemy_shot(self,origin,planned_aim)
  if ammo<=0:
   reload_left = 1.55 if weapon_kind==0 else 1.9
   fire_timer = reload_left


func take_hit(amount: float) -> void:
 if hp <= 0:
  return
 var mitigated = amount*(1.0-Gear.REDUCTION[armor_tier])
 var absorbed = minf(armor,mitigated)
 armor -= absorbed
 hp -= mitigated-absorbed
 hit_time = .09
 health_bar.visible = true
 health_bar.scale.x = maxf(.01,(hp+armor)/(max_hp+Gear.SHIELD[armor_tier]))
 if hp <= 0:
  if not friendly:
   game.kills += 1
  collision_layer = 0
  collision_mask = 0
  game.spark(global_position+Vector3.UP,Color("5fe8dd"),12)
  game.sound("break",.75)
  var tween = create_tween()
  tween.tween_property(model,"scale",Vector3.ZERO,.25)
  tween.tween_callback(queue_free)
  if friendly:
   return
  game.player.shield = minf(game.player.max_shield(),game.player.shield+8)
  game.expedition.make_chest(global_position,armor_tier,weapon_tier,weapon_kind,big,is_boss)

func formation_offset() -> Vector3:
 return game.player.global_basis*Vector3((slot%5-2)*1.8,0,2.5+float(slot/5)*2.0)

func select_target() -> Node3D:
 var closest: Node3D = null
 var anchor = game.command.anchor(self)
 var leash = 12.0 if friendly and game.command.order=="defend" else (22.0 if friendly else 16.0)
 var limit = leash
 if not friendly and position.distance_to(game.player.position)<limit and (not is_boss or game.player.position.distance_to(anchor)<12):
  closest = game.player
  limit = position.distance_to(game.player.position)
 var candidates = game.enemies if friendly else game.allies
 for unit in candidates:
  if is_instance_valid(unit) and unit.hp>0:
   var distance = position.distance_to(unit.position)
   if (not friendly or unit.position.distance_to(anchor)<leash) and distance<limit and game.clear_line(position+Vector3.UP*1.3,unit.position+Vector3.UP*1.3,unit):
    closest = unit
    limit = distance
 return closest
