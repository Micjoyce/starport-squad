extends CharacterBody3D
const F = preload("res://scripts/factory.gd")
const Gear = preload("res://scripts/gear.gd")
var game: Node3D
var role := 0
var is_stickman := false
var friendly := false
var slot := 0
var target_unit: Node3D
var knife: Node3D
const Operative = preload("res://scripts/operative.gd")
const Tactics = preload("res://scripts/tactics.gd")
var brain: RefCounted
var laser_frame := -1
var laser_health_damage := 0.0
var generation := 0
var summon_left := 18.0
var q_used := false
var shell_material: Material
var is_elite := false
var armor_big := false
var pants_tier := 0
var pants_big := false
var pants_style := 0
var green_pants := true
var coat_enabled := false
var costume_key := ""
var coat: Node3D
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
var armor_bar: MeshInstance3D
var launcher: Node3D
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
 brain = Tactics.new()
 brain.game = game
 summon_left += float(slot%10)*.3
 game.wardrobe.configure(self)
 max_hp = hp
 armor = max_armor()
 ammo = Gear.CAPACITY[weapon_kind]
 grenade_timer = game.rng.randf_range(6,12)
 home = position
 phase = game.rng.randf()*TAU
 fire_timer = game.rng.randf_range(1.3,3)
 rebuild_model()

func max_armor() -> float:
 if get_meta("armor_route",-1)>=0: return float(game.career.ARMOR_ROUTE_HP[get_meta("armor_route")])
 return Gear.SHIELD[armor_tier]*(1.2 if armor_big and armor_tier!=5 else 1.0)

func rebuild_model() -> void:
 if is_instance_valid(model):
  remove_child(model)
  model.queue_free()
 model = Node3D.new()
 add_child(model)
 body_material = F.mat(game.career.ARMOR_ROUTE_COLORS[get_meta("armor_route")] if get_meta("armor_route",-1)>=0 else Gear.COLORS[armor_tier])
 var dark = F.mat(Color("1c2b3d"))
 var accent = F.mat(Color("51ffe0") if friendly else Color("ff7962"),1.5)
 var trouser: Material = Gear.armor_surface(pants_tier)
 if pants_style==0:
  if green_pants:
   var green = ShaderMaterial.new()
   green.shader = load("res://scripts/pants.gdshader")
   trouser = green
  else:
   trouser = F.mat(Color("485567"))
 F.box(model,Vector3(0,1.1,0),Vector3(.72,.64,.42),body_material)
 F.box(model,Vector3(0,.79,0),Vector3(.42,.14,.30),dark)
 F.box(model,Vector3(0,1.65,0),Vector3(.55,.35,.40),body_material)
 F.face(model,Vector3(0,1.65,-.23))
 eye = F.box(model,Vector3(0,1.83,-.215),Vector3(.39,.035,.035),accent)
 eye.set_meta("dynamic",true)
 F.box(model,Vector3(0,1.18,-.23),Vector3(.22,.22,.04),dark)
 F.box(model,Vector3(0,1.18,-.26),Vector3(.12,.12,.03),accent)
 for side in [-1,1]:
  F.sphere(model,Vector3(side*.46,1.30,0),.14,dark)
  F.box(model,Vector3(side*.50,1.08,0),Vector3(.22,.4,.25),body_material)
  F.box(model,Vector3(side*.50,.91,-.15),Vector3(.19,.18,.28),dark)
  F.box(model,Vector3(side*.22,.62 if pants_style==2 else .5,0),Vector3(.23 if pants_big else .20,.24 if pants_style==2 else .48,.26 if pants_big else .23),trouser)
  if pants_style==2:
   F.box(model,Vector3(side*.22,.32,0),Vector3(.18,.35,.20),F.mat(Color("a48368")))
  F.sphere(model,Vector3(side*.22,.42,-.03),.14,dark)
  F.box(model,Vector3(side*.22,.16,-.08),Vector3(.27,.20,.39),dark)
 coat = Operative.make_coat(model)
 coat.visible = coat_enabled
 F.batch_meshes(coat)
 model.scale = Vector3(1.08,1.0,1.08) if armor_big else Vector3.ONE
 gun = Gear.make_weapon(model,weapon_kind,weapon_tier)
 gun.position = Vector3(.39,1.5 if role==1 else 1.02,-.35)
 launcher = Node3D.new()
 model.add_child(launcher)
 launcher.position = Vector3(.55,1.35,-.1)
 var launch_tube = F.cylinder(launcher,Vector3.ZERO,.13,.9,dark,10)
 launch_tube.rotation.x = PI/2
 launcher.visible = is_elite or (role==0 and slot%5==0)
 knife = Gear.make_knife(model)
 knife.position = Vector3(.4,1.05,-.4)
 knife.visible = false
 badge = F.text3d(model,("友军 %02d" % (slot+1) if friendly else ("精英指挥官 / 无限重生" if is_elite else ("首领 / 彩虹全套" if is_boss else ("大" if armor_big else "小")+Gear.SHORT[armor_tier])))+" "+game.regiments.NAMES[role]+" / "+Gear.MODEL_NAMES[weapon_kind],Vector3(0,2.2,0),23,Gear.COLORS[armor_tier])
 badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 badge.pixel_size = .005
 badge.font_size = 18
 health_bar = F.box(model,Vector3(0,2.0,0),Vector3(.65,.04,.04),F.mat(Color("ffb169"),1))
 armor_bar = F.box(model,Vector3(0,2.09,0),Vector3(.65,.04,.04),F.mat(Color("5bbfff"),1))
 armor_bar.set_meta("dynamic",true)
 armor_bar.visible = false
 health_bar.set_meta("dynamic",true)
 health_bar.visible = hp<max_hp or armor<max_armor()
 health_bar.scale.x = maxf(.01,hp/max_hp)
 armor_bar.scale.x = maxf(.01,armor/max_armor())
 armor_bar.visible = health_bar.visible
 if armor_tier==5 and get_meta("armor_route",-1)<0:
  var rainbow = Gear.armor_surface(5)
  for part in model.get_children():
   if part is MeshInstance3D and part.material_override==body_material:
    part.material_override = rainbow
 F.batch_meshes(model)
 if is_stickman: build_stick_figure()
 if armor<=0:
  paint_broken_shell()

func _physics_process(dt: float) -> void:
 if not game.active or hp <= 0:
  return
 if game.forts.step_unit(self,dt): return
 if friendly:
  badge.visible = global_position.distance_to(game.player.camera.global_position)>2.5
 summon_left -= dt
 if summon_left<=0:
  game.companions.summon(self)
  summon_left = 18
 if not q_used and (is_elite or slot%10==0) and hp<max_hp*.35:
  q_used = true
  max_hp = 999
  hp = 999
  game.spark(position+Vector3.UP,Color("7affdf"),8)
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
 var rooftop = friendly and role==1 and game.forts.is_rooftop(self)
 var climbing_guard = friendly and role==1 and game.command.order=="defend" and not rooftop
 var destination = brain.destination(self,target_unit,target,dt)
 if climbing_guard: destination = game.forts.base()
 if is_elite: game.rival.decision = brain.state
 var tactical_movement = destination.distance_to(position)>1.0 and target_unit!=null
 path_timer -= dt
 if path_timer <= 0:
  path_timer = .65+game.rng.randf()*.4
  path = game.find_path(position,destination)
 var motion = Vector3.ZERO
 if climbing_guard or tactical_movement or distance > (1.0 if following else 7.0) or (not visible_target and not following):
  if path.size() > 1:
   var wp = Vector3(path[1].x,0,path[1].y)
   if Vector2(position.x-wp.x,position.z-wp.z).length() < .55:
    path.remove_at(0)
    if path.size() > 1:
     wp = Vector3(path[1].x,0,path[1].y)
   motion = (wp-position).normalized()
   motion.y = 0
 if rooftop:
  var station = game.forts.sniper_point(self)
  motion = (station-position).normalized() if Vector2(station.x-position.x,station.z-position.z).length()>.3 else Vector3.ZERO
  motion.y = 0
 var speed = 7.8 if friendly else (5.8 if is_elite else 2.2+game.difficulty*.45)
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
 gun.visible = not melee and not (is_elite or (role==0 and slot%5==0))
 launcher.visible = not melee and (is_elite or (role==0 and slot%5==0))
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
 if distance < (80 if role==1 else 24) and visible_target and fire_timer <= 0 and reload_left == 0 and windup < 0:
  var scatter = .7 if game.difficulty==0 else (.48 if game.difficulty==1 else .28)
  var prediction = target_unit.velocity*.18 if target_unit is CharacterBody3D else Vector3.ZERO
  planned_aim = (target_unit.global_position+Vector3.UP*1.3+prediction)+Vector3(game.rng.randf_range(-scatter,scatter),-.20,game.rng.randf_range(-scatter,scatter))
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
 if is_elite or (role==0 and slot%5==0):
  game.arsenal.rocket(launcher.to_global(Vector3(0,0,-.55)),planned_aim,friendly)
  fire_timer = 3.0
  return
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
 if armor>0:
  armor = maxf(0,armor-mitigated)
  if armor==0:
   game.arsenal.shatter(global_position+Vector3.UP,armor_tier)
   paint_broken_shell()
 else:
  hp -= mitigated
 hit_time = .09
 health_bar.visible = true
 health_bar.scale.x = maxf(.01,hp/max_hp)
 armor_bar.scale.x = maxf(.01,armor/max_armor())
 armor_bar.visible = health_bar.visible
 if hp <= 0:
  game.regiments.died(self)
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
  if is_elite:
   game.rival.defeated(self)
  game.player.shield = minf(game.player.max_shield(),game.player.shield+8)
  game.expedition.make_chest(global_position,armor_tier,weapon_tier,weapon_kind,big,is_boss,{"armor_large":armor_big,"pants_tier":pants_tier,"pants_large":pants_big})

func formation_offset() -> Vector3:
 return game.player.global_basis*Vector3((slot%5-2)*1.8,0,2.5+float(slot/5)*2.0)

func select_target() -> Node3D:
 var closest: Node3D = null
 var anchor = game.command.anchor(self)
 var leash = 80.0 if friendly and role==1 and game.forts.is_rooftop(self) else (12.0 if friendly and game.command.order=="defend" else (22.0 if friendly else 16.0))
 var limit = leash
 if not friendly and position.distance_to(game.player.position)<limit and (not is_boss or game.player.position.distance_to(anchor)<12):
  closest = game.player
  limit = position.distance_to(game.player.position)
 var candidates = game.enemies if friendly else game.allies
 for unit in candidates:
  if is_instance_valid(unit) and unit.hp>0 and not unit.get_meta("aboard",false):
   var distance = position.distance_to(unit.position)
   if (not friendly or unit.position.distance_to(anchor)<leash) and distance<limit and game.clear_line(position+Vector3.UP*1.3,unit.position+Vector3.UP*1.3,unit):
    closest = unit
    limit = distance
 return closest

func break_armor() -> void:
 if hp<=0 or armor<=0: return
 armor = 0
 game.arsenal.shatter(global_position+Vector3.UP,armor_tier)
 paint_broken_shell()
 health_bar.visible = true

func paint_broken_shell() -> void:
 var broken = F.mat(Color("394854"))
 for part in model.get_children():
  if part is MeshInstance3D and (part.material_override==body_material or part.material_override is ShaderMaterial and part.material_override.shader==load("res://scripts/rainbow.gdshader")):
   part.material_override = broken

func take_laser(amount: float) -> void:
 var frame = Engine.get_physics_frames()
 if laser_frame!=frame:
  laser_frame = frame
  laser_health_damage = 0
 if armor>0:
  take_hit(amount)
  return
 var allowed = maxf(0,max_hp*.025-laser_health_damage)
 if allowed<=0: return
 var core_damage = minf(amount*(1.0-Gear.REDUCTION[armor_tier]),allowed)
 laser_health_damage += core_damage
 take_hit(core_damage/(1.0-Gear.REDUCTION[armor_tier]))

func build_stick_figure() -> void:
 for part in model.get_children():
  if part is MeshInstance3D and part!=health_bar and part!=armor_bar: part.visible = false
  if part.has_meta("human_face"): part.visible = false
 coat.visible = false
 var stick = Node3D.new()
 model.add_child(stick)
 var ink = F.mat(Color("273d48"))
 var color = Gear.armor_surface(armor_tier)
 F.sphere(stick,Vector3(0,1.65,0),.18,color)
 F.box(stick,Vector3(0,1.05,0),Vector3(.07,.85,.07),color)
 for side in [-1,1]:
  F.box(stick,Vector3(side*.17,.35,0),Vector3(.055,.7,.055),ink).rotation.z = side*.22
  F.box(stick,Vector3(side*.23,1.13,0),Vector3(.055,.55,.055),ink).rotation.z = side*.7
 F.batch_meshes(stick)
 badge.text = "火柴人 / "+("我方" if friendly else "敌方")+" / 沙漠之鹰"
