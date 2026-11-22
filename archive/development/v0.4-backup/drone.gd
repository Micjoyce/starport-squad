extends CharacterBody3D
const F = preload("res://scripts/factory.gd")
const Gear = preload("res://scripts/gear.gd")
var game: Node3D
var hp := 100.0
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
 collision_layer = 4
 collision_mask = 1 | 2 | 4
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
 armor = Gear.SHIELD[armor_tier]
 ammo = 30 if weapon_kind==0 else 8
 grenade_timer = game.rng.randf_range(6,12)
 var dark = F.mat(Color("1c2b3d"))
 var accent = F.mat(Color("ff7962"),1.5)
 var steel = F.mat(Color("91a8b5"))
 F.box(model,Vector3(0,1.1,0),Vector3(.72,.64,.42),body_material)
 F.box(model,Vector3(0,.79,0),Vector3(.42,.14,.30),dark)
 F.box(model,Vector3(0,1.65,0),Vector3(.55,.35,.40),body_material)
 eye = F.box(model,Vector3(0,1.65,-.215),Vector3(.39,.09,.035),accent)
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
 badge = F.text3d(model,Gear.SHORT[armor_tier]+" / "+("AK47" if weapon_kind==0 else "SG"),Vector3(0,2.2,0),23,Gear.COLORS[armor_tier])
 badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 health_bar = F.box(model,Vector3(0,2.0,0),Vector3(.65,.04,.04),F.mat(Color("ffb169"),1))
 health_bar.visible = false
 home = position
 phase = game.rng.randf()*TAU
 fire_timer = game.rng.randf_range(1.3,3)

func _physics_process(dt: float) -> void:
 if not game.active or hp <= 0:
  return
 phase += dt*4
 hit_time = maxf(0,hit_time-dt)
 Gear.color_material(body_material,armor_tier)
 if hit_time > 0:
  body_material.albedo_color = Color("fff3cf")
 var target = game.player.position
 var distance = position.distance_to(target)
 var visible_target = game.clear_line(global_position+Vector3.UP*1.4,(game.player.global_position+Vector3.UP*1.3),game.player)
 var destination = target if distance < 28 else home+Vector3(sin(phase*.12)*3,0,cos(phase*.12)*3)
 path_timer -= dt
 if path_timer <= 0:
  path_timer = .65+game.rng.randf()*.4
  path = game.find_path(position,destination)
 var motion = Vector3.ZERO
 if distance > 8 or not visible_target:
  if path.size() > 1:
   var wp = Vector3(path[1].x,0,path[1].y)
   if Vector2(position.x-wp.x,position.z-wp.z).length() < .55:
    path.remove_at(0)
    if path.size() > 1:
     wp = Vector3(path[1].x,0,path[1].y)
   motion = (wp-position).normalized()
   motion.y = 0
 velocity.x = motion.x*(2.2+game.difficulty*.45)
 velocity.z = motion.z*(2.2+game.difficulty*.45)
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
  ammo = 30 if weapon_kind==0 else 8
 if windup >= 0:
  windup -= dt
  eye.scale.y = 2.0
  if windup <= 0:
   windup = -1
   eye.scale.y = 1.0
   fire_weapon()
 if distance < 24 and visible_target and fire_timer <= 0 and reload_left == 0 and windup < 0:
  var scatter = .7 if game.difficulty==0 else (.48 if game.difficulty==1 else .28)
  planned_aim = (game.player.global_position+Vector3.UP*1.3)+Vector3(game.rng.randf_range(-scatter,scatter),-.20,game.rng.randf_range(-scatter,scatter))
  if game.difficulty == 0:
   fire_weapon()
  else:
   # Aim is locked before firing; moving during this visible windup dodges the shot.
   windup = .30 if game.difficulty==1 else .20
   fire_timer = .5
 if game.difficulty>0 and distance>4 and distance<21 and visible_target and grenade_timer<=0:
  grenade_timer = game.rng.randf_range(9,14) if game.difficulty==1 else game.rng.randf_range(7,11)
  game.throw_grenade(global_position+Vector3.UP*1.3,game.player.position)

func fire_weapon() -> void:
 if hp<=0:
  return
 var origin = gun.to_global(Vector3(0,0,-.70))
 ammo -= 1
 if game.difficulty == 0:
  fire_timer = game.rng.randf_range(1.6,2.6)
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
 health_bar.scale.x = maxf(.01,(hp+armor)/(100+Gear.SHIELD[armor_tier]))
 if hp <= 0:
  game.kills += 1
  collision_layer = 0
  collision_mask = 0
  game.spark(global_position+Vector3.UP,Color("5fe8dd"),12)
  game.sound("break",.75)
  var tween = create_tween()
  tween.tween_property(model,"scale",Vector3.ZERO,.25)
  tween.tween_callback(queue_free)
  game.player.shield = minf(game.player.max_shield(),game.player.shield+8)
  game.drop_equipment(global_position,armor_tier,weapon_tier,weapon_kind)
  game.drop_resources(global_position,40+game.difficulty*30)
